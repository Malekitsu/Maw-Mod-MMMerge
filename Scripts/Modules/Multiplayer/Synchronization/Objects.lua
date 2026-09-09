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
Multiplayer.REMOTE_OWNER_BIT = REMOTE_OWNER_BIT -- object belongs to another player

local last_object_state = {}
local last_object_postime = {}

---- object versions ----
-- every state broadcast of an object carries a version: whoever sends bases it
-- on the highest one seen plus one, so a late packet can never undo a newer
-- state. Equal versions from two senders settle on the lower client id.
-- Position updates do not bump: they apply only on the version they were made on.

local versions = {} -- sync ID -> {v = n, sender = client id}
Multiplayer.debug.object_versions = versions

local function version_of(ID)
	local e = versions[ID]
	if e then
		return e.v, e.sender
	end
	return 0, -1
end

local function bump_version(ID)
	local v = version_of(ID) + 1
	versions[ID] = {v = v, sender = Multiplayer.my_id}
	return v
end

local function accept_version(ID, v, sender)
	local cur, cur_sender = version_of(ID)
	if v > cur or (v == cur and sender < cur_sender) then
		versions[ID] = {v = v, sender = sender}
		return true
	end
	return false
end

local gold_pile_ids = {[187] = true, [188] = true, [189] = true, [999] = true, [1000] = true, [1001] = true, [1799] = true, [1800] = true, [1801] = true}
local PICKED_BY_OTHER_TEXT = "Another player picked that up first."

---- object ID setup -----

local current_ID = 0
local ObjectByID = {}
Multiplayer.debug.ObjectByID = ObjectByID
Multiplayer.debug.object_current_ID = function()
	return current_ID
end

local function nextID()
	current_ID = current_ID + 1
	if current_ID >= 0xFFFF then
		current_ID = 1
	end
	return current_ID + bit.lshift(Multiplayer.my_id + 1, 16)
end

local function getID(obj)
	if obj.SpellType == 0 then
		return obj.SpellSkill
	else
		return obj.Item.Charges
	end
end

local function setID(obj, i, ID)
	if obj.SpellType == 0 then
		obj.SpellSkill = ID
	else
		obj.Item.Charges = ID
	end
	if ID > 0 then
		ObjectByID[ID] = i
	end
end

local function getsetID(object, i)
	local ID = getID(object)
	if ID <= 0xFFFF then -- object was overwritten or created by engine
		ID = nextID()
		setID(object, i, ID)
	end
	return ID
end

local function free_object()
	for i, v in Map.Objects do
		if v.TypeIndex == 0 then
			return v, i
		end
	end
	
	local i = Map.Objects.count
	if i >= Map.Objects.limit then
		i = Map.Objects.count - 1
	else
		Map.Objects.count = i + 1
	end
	
	return Map.Objects[i], i
end

local function find_obj_by_ID(ID)
	local id = ObjectByID[ID]
	if id then
		if id < Map.Objects.count and getID(Map.Objects[id]) == ID then
			return Map.Objects[id], id
		else
			ObjectByID[ID] = nil
		end
	end

	for i, obj in Map.Objects do
		if getID(obj) == ID then
			ObjectByID[ID] = i
			return obj, i
		end
	end
	return nil
end

local function get_obj_by_ID(ID)
	local obj, i = find_obj_by_ID(ID)
	if not obj then
		obj, i = free_object()
		setID(obj, i, ID)
	end
	return obj, i
end

-- happens, when child objects are spawned: death blossom explodes, creating child projectiles
local function remove_ID_doubles()
	local ids_count = {}
	local doubles = {}
	local function ids_inc(i, obj)
		local ID = getID(obj)
		if ID > 0xFFFF then
			local count = (ids_count[ID] or 0) + 1
			ids_count[ID] = count
			if count > 1 then
				doubles[ID] = doubles[ID] or {}
				table.insert(doubles[ID], i)
			end
		end
	end
	
	for i, v in Map.Objects do
		ids_inc(i, v)
	end
	
	for _, list in pairs(doubles) do
		for _, i in pairs(list) do
			setID(Map.Objects[i], i, 0)
		end
	end
end

function events.BeforeLoadMap()
	table.clear(ObjectByID)
end

function events.MultiplayerStarted()
	table.clear(ObjectByID)
	current_ID = 0
end

-- versions live with the map: the player already there hands them over with the map data
function events.LeaveMap()
	table.clear(versions)
end

function events.MultiplayerPrepMapData(t)
	t.ObjectVersions = versions
end

function events.MultiplayerProcessMapData(t)
	if t.ObjectVersions then
		table.clear(versions)
		for ID, e in pairs(t.ObjectVersions) do
			versions[ID] = e
		end
	end
end

function Multiplayer.debug.list_obj_IDs()
	for i, v in Map.Objects do
		print(i, getID(v))
	end
end

---- synchronization checks ----

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
		return object.TypeIndex > 0
	end

	return state_changed(state, object)
end

local function fill_all_states()
	for i, v in Map.Objects do
		fill_state(i, v)
	end
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

----

local function object_bin(i)
	local first = Map.Objects[i]['?ptr']
	local last = first + MAP_OBJECT_SIZE
	return mstr(first, last - first, true)
end

local waiting_for_send = {}

local packets = {
	objects_info = {
		bulb = function(object_ids)
			local t = {}
			local object, old_owner, ID
			for _, i in pairs(object_ids) do
				object = Map.Objects[i]
				ID = getsetID(object, i)

				if bit.And(object.Owner, 7) == 4 then
					old_owner = object.Owner
					object.Owner = REMOTE_PLAYER_REF + bit.lshift(Multiplayer.my_id, 3) -- mark object as owned by remote player
					t[ID] = {bump_version(ID), object_bin(i)}
					object.Owner = old_owner
				else
					t[ID] = {bump_version(ID), object_bin(i)}
				end
			end

			return item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			local function import(i, object, bin)
				mcopy(object['?ptr'], bin)
				fill_state(i, object)

				if object.SpellType > 0 then
					object.Bits = bit.Or(object.Bits, NO_SYNC_OBJECT_BIT)

					if bit.And(object.Owner, 7) == REMOTE_PLAYER_REF then
						object.Owner = 3 -- Party
						object.AttackType = 2
						object.Bits = bit.Or(object.Bits, REMOTE_OWNER_BIT)
					end
				end
			end

			local t = binstr_to_item(bin_string)
			local i, object, new, str
			for ID, entry in pairs(t) do
				str = entry[2]
				if accept_version(ID, entry[1], metadata.sender_id) then
					object, i = get_obj_by_ID(ID)
					new = structs.MapObject:new(toptr(str))
					if new.SpellType > 0 and object.Item.Number > 0 then
						-- Prevent overwriting items with spells.
						-- Happens on short frame after simultaneous map load.
						-- Cannot find root issue at the moment.
						Multiplayer.utils.LogEvent("SYNC", "Attempt to overwrite object-item with object-spell: id %d, hash %d, from #%d", i, ID, metadata.sender_id)
					else
						import(i, object, str)
					end
				end
			end
		end,
		same_map_only = true,
		compress = true
	},

	objects_position = {
		bulb = function(object_ids)
			local fields = {"TypeIndex","X","Y","Z","VelocityX","VelocityY","VelocityZ"}
			local t = {}
			local obj, ID
			for _, id in pairs(object_ids) do
				obj = Map.Objects[id]
				ID = getsetID(obj, id)
				t[ID] = {(version_of(ID)), nums_to_bin(obj, fields, 2)}
			end
			return item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			local fields = {"TypeIndex","X","Y","Z","VelocityX","VelocityY","VelocityZ"}
			local t = {X = 0, Y = 0, Z = 0, TypeIndex = 0}
			local obj, cur
			for ID, entry in pairs(binstr_to_item(bin_string)) do
				cur = version_of(ID)
				if entry[1] == cur then
					obj = find_obj_by_ID(ID)
					if obj then
						XYZ(t, XYZ(obj))
						fill_from_bin(obj, toptr(entry[2]), fields, 2, true)
						if distance(obj, t) < 256 then
							XYZ(obj, XYZ(t))
						end
					end
				elseif entry[1] > cur then
					-- we missed a state packet: ask the sender for the whole object
					Multiplayer.add_to_send_queue(metadata.sender_id, packets.request_object_info:prep(ID))
				end
			end
		end,
		same_map_only = true,
		compress = true
	},

	request_object_info = {
		bulb = function(ID)
			return Multiplayer.utils.num_to_hexstr(ID, 4)
		end,
		handler = function(bin_string, metadata)
			local ID = Multiplayer.utils.num_from_hexstr(bin_string, 4)
			local obj, i = find_obj_by_ID(ID)
			if obj then
				table.insert(waiting_for_send, i)
			end
		end,
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

local function sync_objects()
	if Multiplayer.leave_map_halt or Multiplayer.OnDeathScreen() then
		return
	end

	remove_ID_doubles()
	
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
Multiplayer.utils.TickCounter(sync_objects, 4)

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

function events.MapLoadingDone()
	fill_all_states()
end

function events.MultiplayerStarted()
	fill_all_states()
end

----

local function broadcast_pick_object_sound()
	Multiplayer.broadcast(packets.pick_object_sound:prep(), cond_same_map)
end
Multiplayer.utils.broadcast_pick_object_sound = broadcast_pick_object_sound

local function notify_object_picked(i)
	local obj = Map.Objects[i]
	obj.Owner = REMOTE_PLAYER_REF + bit.lshift(Multiplayer.my_id, 3)
	obj.Bits = bit.Or(obj.Bits, PICKED_BY_PLAYER_BIT)
	fill_state(i, obj)
	table.insert(waiting_for_send, i)
	Multiplayer.utils.LogEvent("SYNC", "Object %s have been picked up. Owner and Bits changed.", i)
	broadcast_pick_object_sound()

	-- process all data now, before object is cleared by engine
	local oType, oTypeIndex = obj.Type, obj.TypeIndex
	obj.Type, obj.TypeIndex = 0, 0

	Multiplayer.broadcast(packets.objects_info:prep(waiting_for_send), cond_same_map)
	waiting_for_send = {}
	obj.Bits = bit.Or(obj.Bits, NO_SYNC_OBJECT_BIT)
	obj.Type, obj.TypeIndex = oType, oTypeIndex
end

-- the pickup happens at once under a claim on the object's sync id; a lost
-- claim gives back what the engine already handed us
Multiplayer.Claims.define("object", {
	scope = "map",
	announce = false,
	on_lost = function(id, taken)
		if taken.Gold then
			evt.Subtract("Gold", taken.Gold)
		else
			evt.Subtract("Items", taken.Number)
		end
		Game.ShowStatusText(PICKED_BY_OTHER_TEXT)
	end,
})

local function can_pick_object(t)
	local object = Map.Objects[t.ObjectId]
	local item = object.Item
	local verdict = Multiplayer.Claims.try("object", getsetID(object, t.ObjectId),
		{Number = item.Number, Gold = gold_pile_ids[item.Number] and item.Bonus2 or nil})
	if verdict == "taken" then
		t.Handled = true
		return
	end

	notify_object_picked(t.ObjectId)
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

local OverrideGoldTaken

function events.BeforeGotGold(t)
	if OverrideGoldTaken then
		t.Amount = OverrideGoldTaken
		NPCFollowers.LastGoldTaken = 0
		OverrideGoldTaken = nil
	end
end

function events.PickObject(t)
	if Game.CurrentScreen == 0 or Game.CurrentScreen == 20 then
		local Object = Map.Objects[t.ObjectId]
		local Item = Object.Item
		local Gold, Owner = Item.Bonus2, bit.And(Object.Owner, 7)
		if (Owner == REMOTE_PLAYER_REF or Owner == 4) and Item.Number >= 187 and Item.Number <= 189 then
			OverrideGoldTaken = Gold
		end
	end
end

---- Map data

function events.MultiplayerPrepMapData(t)
	for i, obj in Map.Objects do
		getsetID(obj, i)
	end

	t.MapObjects = {
		bin = Multiplayer.utils.mmt_dump(Map.Objects),
		count = Map.Objects.count
	}
end

function events.MultiplayerProcessMapData(t)
	if t.MapObjects then
		mcopy(Map.Objects['?ptr'], t.MapObjects.bin)
		Map.Objects.count = t.MapObjects.count
	end
end
