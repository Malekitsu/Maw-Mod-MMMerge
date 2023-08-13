local events = Multiplayer.events
local toptr, mstr, mcopy, mfill, u1, u2 = mem.topointer, mem.string, mem.copy, mem.fill, mem.u1, mem.u2
local item_to_bin, binstr_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.binstr_to_item
local cond_same_map = Multiplayer.utils.cond_same_map
local nums_to_bin, fill_from_bin = Multiplayer.utils.nums_to_bin, Multiplayer.utils.fill_from_bin
local distance = Multiplayer.utils.distance
local LogEvent = Multiplayer.utils.LogEvent

local SyncPlayers = Multiplayer.require("Synchronization/Players.lua")

local MAP_OBJECT_SIZE = 112
local REMOTE_PLAYER_REF = 6
local REMOTE_OWNER_BIT = 0x800
local NO_SYNC_OBJECT_BIT = 0x1000
local PICKED_BY_PLAYER_BIT = 0x2000

Multiplayer.NO_SYNC_OBJECT_BIT = NO_SYNC_OBJECT_BIT -- no synchronization if bit set

local last_object_state = {}
local last_object_postime = {}

local compare_fields = {'TypeIndex', 'Type', 'Bits'}
local function fill_state(i, object)
	local state = last_object_state[i]
	if not state then
		state = {}
		last_object_state[i] = state
	end
	for _, v in pairs(compare_fields) do
		state[v] = object[v]
	end
end

local function state_changed(state, object)
	for _, v in pairs(compare_fields) do
		if state[v] ~= object[v] then
			return true
		end
	end
	return false
end

local function need_send(i, object)
	if bit.And(object.Bits, NO_SYNC_OBJECT_BIT) > 0 then
		return false
	end

	local state = last_object_state[i]
	if not state then
		fill_state(i, object)
		return false
	end

	return state_changed(state, object)
end

local function need_pos_update(i, object)
	if bit.And(object.Bits, NO_SYNC_OBJECT_BIT) > 0 then
		return false
	end

	local timestamp = last_object_postime[i]
	if not timestamp then
		last_object_postime[i] = os.time()
		return false
	end

	local result = object.TypeIndex > 0
		and object.Item.Number > 0
		and (bit.And(object.Owner, 7) == 4 or bit.And(object.Owner, 7) == REMOTE_PLAYER_REF and bit.rshift(object.Owner, 3) == Multiplayer.my_id)
		and os.time() - timestamp > 2

	if result then
		last_object_postime[i] = os.time()
	end
	return result
end

local function object_bin(i)
	local first = Map.Objects[i]['?ptr']
	local last = first + MAP_OBJECT_SIZE
	return mstr(first, last - first, true)
end

local packets = {
	objects_info = {
		bulb = function(object_ids)
			local t = {}
			local object, old_owner
			for _, i in pairs(object_ids) do
				object = Map.Objects[i]
				if bit.And(object.Owner, 7) == 4 then--and object.SpellType > 0 then
					old_owner = object.Owner
					object.Owner = REMOTE_PLAYER_REF + bit.lshift(Multiplayer.my_id, 3) -- mark object as owned by remote player
					t[i] = object_bin(i)
					object.Owner = old_owner
				else
					t[i] = object_bin(i)
				end
			end
			return item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			local im_main = Multiplayer.main_player_on_map() == Multiplayer.my_id

			local function import(i, object, bin)
				mcopy(object['?ptr'], bin)
				fill_state(i, object)

				if object.SpellType > 0 then
					object.Bits = bit.Or(object.Bits, NO_SYNC_OBJECT_BIT)

					if bit.And(object.Owner, 7) == REMOTE_PLAYER_REF then
						object.Owner = 3
						object.AttackType = 2
						object.Bits = bit.Or(object.Bits, REMOTE_OWNER_BIT)
					end
				end
			end

			local function key_fields_equal(old, new)
				return old.SpellType == new.SpellType
					and bit.And(old.Owner, 7) == bit.And(new.Owner, 7)
					and old.Item.Number == new.Item.Number
			end

			local function obj_col_repr(old, new)
				return table.concat({
				"TypeIndex, OwnerKind, Item.Number, SpellType, Bits",
				("old: %s, %s, %s, %s, %s"):format(old.TypeIndex, bit.And(old.Owner, 7), old.Item.Number, old.SpellType, old.Bits),
				("new: %s, %s, %s, %s, %s"):format(new.TypeIndex, bit.And(new.Owner, 7), new.Item.Number, new.SpellType, new.Bits),
				}, "\n")
			end

			local function solve_collision(old, new)
				if new.TypeIndex == 0 and old.Item.Number ~= 0 and new.Owner == REMOTE_PLAYER_REF then
					return true
				elseif old.Item.Number ~= 0 and old.Item.Number ~= new.Item.Number then
					LogEvent("SYNC", "Objects: items sync collision detected:\n%s", obj_col_repr(old, new))
					return false
				elseif new.DroppedByPlayer then
					return true
				elseif bit.And(old.Owner, 7) == 4 and old.SpellType > 0 then
					return false
				elseif bit.And(new.Owner, 7) == REMOTE_PLAYER_REF then
					return true
				elseif bit.And(new.Owner, 2) == 2 and not im_main then
					return true
				elseif key_fields_equal(old, new) then
					return true
				end

				LogEvent("SYNC", "Objects collision detected:\n%s", obj_col_repr(old, new))
				return false
			end

			local t = binstr_to_item(bin_string)
			local object
			for i, str in pairs(t) do
				if i >= Map.Objects.count then
					Map.Objects.count = i + 1
				end

				object = Map.Objects[i]

				if object.TypeIndex == 0 or object.Removed then
					import(i, object, str)
				else
					local new = structs.MapObject:new(toptr(str))
					local accept = solve_collision(object, new)
					if accept then
						import(i, object, str)
					end
				end
			end
		end,
		check_delivery = true,
		same_map_only = true,
		compress = true
	},

	objects_position = {
		bulb = function(object_ids)
			local fields = {"TypeIndex","X","Y","Z","VelocityX","VelocityY","VelocityZ"}
			local t = {}
			for _, id in pairs(object_ids) do
				t[id] = nums_to_bin(Map.Objects[id], fields, 2)
			end
			return item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			local fields = {"TypeIndex","X","Y","Z","VelocityX","VelocityY","VelocityZ"}
			local t = {X = 0, Y = 0, Z = 0, TypeIndex = 0}
			local obj
			for i, bin in pairs(binstr_to_item(bin_string)) do
				if i < Map.Objects.count and u2[toptr(bin)] == Map.Objects[i].TypeIndex then
					obj = Map.Objects[i]
					XYZ(t, XYZ(obj))
					fill_from_bin(obj, toptr(bin), fields, 2, true)
					if distance(obj, t) < 256 then
						XYZ(obj, XYZ(t))
					end
				end
			end
		end,
		same_map_only = true,
		compress = true
	},

	can_pickup_object = {
		bulb = function(object_id)
			return Multiplayer.utils.num_to_hexstr(object_id, 2)
		end,
		handler = function(bin_string, metadata)
			local object_id = mem.u2[toptr(bin_string)]
			if object_id >= Map.Objects.count then
				return true
			end

			local object = Map.Objects[object_id]
			local can_pickup = not object.Removed
			if can_pickup then
				object.TypeIndex = 0
				object.Removed = true
				fill_state(object_id, object)
			end
			return can_pickup
		end,
		response = 'can_pickup_object_response',
		check_delivery = true,
		same_map_only = true
	},

	can_pickup_object_response = {
		bulb = function(handler_result)
			return handler_result and '\1' or '\0'
		end,
		handler = function(bin_string, metadata)
			return bin_string == '\1'
		end,
		check_delivery = true,
		same_map_only = true
	},

	pick_object_sound = {
		handler = function(bin_string, metadata)
			Multiplayer.SyncPlayers.play_puppet_sound2(133, metadata.sender_id)
		end,
		same_map_only = true
	}
}
Multiplayer.utils.init_packets(packets)

local waiting_for_send = {}
function events.Tick()
	if Multiplayer.leave_map_halt then
		return
	end

	local pos_update = {}
	for i, v in Map.Objects do
		if need_send(i, v) then
			fill_state(i, v)
			table.insert(waiting_for_send, i)
		elseif need_pos_update(i, v) then
			table.insert(pos_update, i)
		end
	end
	if next(waiting_for_send) then
		Multiplayer.broadcast(packets.objects_info:prep(waiting_for_send), cond_same_map)
		waiting_for_send = {}
	end
	if next(pos_update) then
		Multiplayer.broadcast(packets.objects_position:prep(pos_update), cond_same_map)
	end
end

function events.CanRepairItem(t)
	if t.Object and t.CanRepair then
		table.insert(waiting_for_send, t.ObjectIndex)
	end
end

function events.CanIdentifyItem(t)
	if t.Object and t.CanIdentify then
		table.insert(waiting_for_send, t.ObjectIndex)
	end
end

function events.LoadMapScripts()
	last_object_state = {}
	waiting_for_send = {}
end

----

local function notify_object_picked(i)
	local obj = Map.Objects[i]
	obj.Owner = REMOTE_PLAYER_REF
	obj.Bits = bit.Or(obj.Bits, PICKED_BY_PLAYER_BIT)
	fill_state(i, obj)
	table.insert(waiting_for_send, i)
	Multiplayer.utils.LogEvent("SYNC", "Object %s have been picked up. Owner and Bits changed.", i)
	Multiplayer.broadcast(packets.pick_object_sound:prep(), cond_same_map)
end

local function can_pick_object(t)
	if Multiplayer.my_id == Multiplayer.main_player_on_map() then
		notify_object_picked(t.ObjectId)
		return -- i am host, no checks necessary
	end

	-- if other players are in range of object, ask host if object can be picked up, to prevent duplications.
	local object, need_check = Map.Objects[t.ObjectId], false
	for i, v in pairs(SyncPlayers.client_monsters()) do
		if v < Map.Monsters.count and Multiplayer.utils.distance(Map.Monsters[v], object) < 1000 then
			need_check = true
			break
		end
	end

	if need_check then
		-- potential concurrents in range.
		LogEvent("SYNC", "Asking host whether object #%s is pickable", t.ObjectId)
		local got_response, response = Multiplayer.send_wait_response(Multiplayer.main_player_on_map(), packets.can_pickup_object, 4, t.ObjectId)
		if not got_response then
			-- forbid pickup, but keep object for new attempt
			t.Handled = true
			LogEvent("SYNC", "No response, keeping object for future attempt")
		elseif not response.handler_result then
			-- host forbids pickup, happens when object was picked up by other player, but was not syncronized in time.
			-- forbid pickup, remove object
			LogEvent("SYNC", "Host forbids picking up, removing object")
			Map.Objects[t.ObjectId].TypeIndex = 0
			t.Handled = true
		else
			LogEvent("SYNC", "Host allows picking up")
		end
	end

	if not t.Handled then
		notify_object_picked(t.ObjectId)
	end
end
events.PickObject = can_pick_object

---- Friendly fire

function events.CalcDamageToMonster(t)
	local source = WhoHitMonster()
	if source then
		local obj = source.Object
		if obj and bit.And(obj.Bits, REMOTE_OWNER_BIT) > 0 then
			t.Result = 0 -- let owner calculate damage
		end
	end
end

function events.PlayerAttacked(t)
	local obj = t.Attacker.Object
	if obj and bit.And(obj.Bits, REMOTE_OWNER_BIT) > 0 then
		if Multiplayer.friendly_fire_factor == 0 then
			t.Handled = true
			return
		end

		obj.Owner = bit.lshift(49,3) + 4
		obj.AttackType = 2
	end
end

function events.CalcDamageToPlayer(t)
	local source = WhoHitPlayer()
	if source then
		local obj = source.Object
		if obj and bit.And(obj.Bits, REMOTE_OWNER_BIT) > 0 then
			local r, ft = t.Result, Multiplayer.friendly_fire_factor
			local out = math.floor(t.Result * Multiplayer.friendly_fire_factor)
			LogEvent("SYNC", "Incoming damage corrected by friendly fire factor: %d * %.2f = %d.", r, ft, out)
			t.Result = out
		end
	end
end

---- Bypass NPC followers gold penalty / bonus, when picking up gold piles, dropped by players

function events.BeforeGotGold(t)	
	if Game.CurrentScreen == 0 or Game.CurrentScreen == 20 then
		if t.ObjectId>Map.Objects.High then
			t.ObjectId=Map.Objects.High+1
		end
		local Object = Map.Objects[t.ObjectId]
		local Item = Object.Item
		local Gold, Owner = Item.Bonus2, bit.And(Object.Owner, 7)
		if (Owner == REMOTE_PLAYER_REF or Owner == 4) and Item.Number >= 187 and Item.Number <= 189 then
			t.Amount = Gold
			NPCFollowers.LastGoldTaken = 0
		end
	end
end
