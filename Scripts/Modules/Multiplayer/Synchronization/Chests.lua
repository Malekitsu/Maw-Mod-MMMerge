local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
local cond_same_map = Multiplayer.utils.cond_same_map
local LogEvent = Multiplayer.utils.LogEvent
local Claims = Multiplayer.Claims

local CHEST_ITEM_SIZE = 36

local last_chest
local ServiceTrapTrigger = false
local confirmed_chest -- opened through evt.OpenChest once the arbiter said yes

local packets = {
	chest_items = {
		bulb = function(chest_id)
			if not chest_id then
				LogEvent("SYNC", "Attempt to export data of nil chest.")
				return nil
			end

			local bulb = {chest = chest_id, items = {}}
			local chest = Map.Chests[chest_id]
			for i, item in chest.Items do
				if item.Number > 0 then
					bulb.items[i] = mstr(item['?ptr'], CHEST_ITEM_SIZE, true)
				end
			end
			return item_to_bin(bulb)
		end,
		handler = function(bin_string, metadata)
			local data = bin_to_item(toptr(bin_string))
			local chest_id = data.chest
			local chest = Map.Chests[chest_id]

			chest.Trapped = false

			for i,v in chest.Items do
				v.Number = 0
			end
			for i,v in pairs(data.items) do
				mcopy(chest.Items[i]['?ptr'], toptr(v), CHEST_ITEM_SIZE)
			end
			chest.ItemsPlaced = false
			mem.fill(chest.Inventory['?ptr'], chest.Inventory['?size'], 0)
		end,
		same_map_only = true,
		check_delivery = true,
		compress = true,
	},

	all_chests_items = {
		bulb = function()
			if Map.Chests.count == 0 then
				return nil
			end

			local bulb = {}
			local t
			for chest_id, chest in Map.Chests do
				t = {items = {}, bits = chest.Bits}
				bulb[chest_id] = t

				for i, item in chest.Items do
					if item.Number > 0 then
						t.items[i] = mstr(item['?ptr'], CHEST_ITEM_SIZE, true)
					end
				end
			end
			return item_to_bin(bulb)
		end,
		handler = function(bin_string, metadata)
			local data = bin_to_item(toptr(bin_string))

			for chest_id, chest in Map.Chests do
				for i,v in chest.Items do
					v.Number = 0
				end
			end

			local chest
			for chest_id, chest_info in pairs(data) do
				chest = Map.Chests[chest_id]
				for i, item in pairs(chest_info.items) do
					mcopy(chest.Items[i]['?ptr'], toptr(item), CHEST_ITEM_SIZE)
				end
				chest.Bits = chest_info.bits
				chest.ItemsPlaced = false
				mem.fill(chest.Inventory['?ptr'], chest.Inventory['?size'], 0)
			end
		end,
		same_map_only = true,
		check_delivery = true,
		compress = true,
	},

	remove_trap = {
		bulb = item_to_bin,
		handler = function(bin_string, metadata)
			local chest_id = bin_to_item(toptr(bin_string))
			Map.Chests[chest_id].Trapped = false
		end,
		same_map_only = true
	},

	trigger_trap = {
		bulb = function(chest_id, sprite_facet_ref)
			return item_to_bin{chest_id, sprite_facet_ref}
		end,
		handler = function(bin_string, metadata)
			local t = bin_to_item(toptr(bin_string))
			local kind, id = Multiplayer.utils.split_ref(t[2])
			local dist = 20000

			local function facet_pos(facet)
				return {X = facet.MinX, Y = facet.MinY, Z = facet.MinZ}
			end

			if kind == const.ObjectRefKind.Facet then
				if Map.IsIndoor() then
					if id < Map.Facets.count then
						dist = Multiplayer.utils.distance(Party, facet_pos(Map.Facets[id]))
					end
				else
					local model_id, facet_id = (id / 64):floor(), id % 64
					if model_id < Map.Models.count and facet_id < Map.Models[model_id].Facets.count then
						dist = Multiplayer.utils.distance(Party, facet_pos(Map.Models[model_id].Facets[facet_id]))
					end
				end
			elseif kind == const.ObjectRefKind.Sprite then
				if id < Map.Sprites.count then
					dist = Multiplayer.utils.distance(Party, Map.Sprites[id])
				end
			end

			LogEvent("SYNC", "Received chest #%s trap trigger notification, source: kind - %s, id - %s, distance - %d.", t[1], kind, id, dist)
			if dist < 764 then
				ServiceTrapTrigger = true
				Multiplayer.TriggerChestTrap(t[1], t[2])
				ServiceTrapTrigger = false
			end
		end,
		check_delivery = true,
		same_map_only = true
	}
}
Multiplayer.utils.init_packets(packets)

-- Init data events

function events.MultiplayerPrepMapData(t)
	t.ChestsInfo = packets.all_chests_items.bulb()
end

function events.MultiplayerProcessMapData(t)
	LogEvent("MAP_LOAD", "Processing chests info: %s.", type(t.ChestsInfo))
	if t.ChestsInfo then
		packets.all_chests_items.handler(t.ChestsInfo)
	end
end

-- Handlers

local function locked_anim()
	local cur_player = math.max(Game.CurrentPlayer, 0)
	Party[cur_player]:ShowFaceAnimation(const.FaceAnimation.DoorLocked)
end

-- one player in a chest at a time; the answer opens it when it comes
Claims.define("chest", {
	scope = "map",
	on_granted = function(chest_id)
		if Game.CurrentScreen == 0 then
			confirmed_chest = chest_id
			evt.OpenChest{chest_id}
		else
			Claims.release("chest", chest_id)
		end
	end,
	on_lost = function(chest_id)
		locked_anim()
	end,
})

function events.CanOpenChest(t)
	if confirmed_chest == t.ChestId then
		confirmed_chest = nil
		t.CanOpen = true
	else
		local verdict = Claims.try("chest", t.ChestId)
		if verdict == "pending" then
			t.CanOpen = false
			return
		end
		t.CanOpen = verdict == "granted"
	end

	if not t.CanOpen then
		locked_anim()
	else
		Multiplayer.utils.delayed_call(function()
			-- in case chest was not actually open, but interrupted by trap activation
			Multiplayer.broadcast(packets.remove_trap:prep(t.ChestId), cond_same_map)
			if Game.CurrentScreen ~= const.Screens.Chest and Game.CurrentScreen ~= const.Screens.InventoryInChest then
				Claims.release("chest", t.ChestId)
			end
		end, 16)
	end
end

function events.LeaveMap()
	confirmed_chest = nil
end

function events.OpenChest(i)
	last_chest = i
	Multiplayer.utils.delayed_call(Multiplayer.broadcast, 4, packets.chest_items:prep(last_chest), cond_same_map)
end

function events.ChestTrapTriggered(i, trap_ref)
	if ServiceTrapTrigger then
		return
	end
	Multiplayer.broadcast(packets.trigger_trap:prep(i, trap_ref), cond_same_map)
end

local update_queue = {}
local function push_queue()
	local data = packets.chest_items:prep(last_chest)
	table.insert(update_queue, data)
end

local function update_chest()
	local info = table.remove(update_queue)
	if info then
		Multiplayer.broadcast(info, cond_same_map)
		update_queue = {}
	end
end

-- take item from chest
function events.GotItem(i)
	if Game.CurrentScreen == 10 then
		Multiplayer.utils.delayed_call(push_queue, 4)
		Multiplayer.utils.delayed_call(update_chest, 10)
	end
end

-- take gold from chest
function events.BeforeGotGold()
	if Game.CurrentScreen == 10 then
		Multiplayer.utils.delayed_call(push_queue, 4)
		Multiplayer.utils.delayed_call(update_chest, 10)
	end
end

function events.Action(t)
	if Game.CurrentScreen == 10 then
		if t.Action == 12 and Mouse.Item.Number ~= 0 then
			-- put item in chest
			Multiplayer.utils.delayed_call(push_queue, 4)
			Multiplayer.utils.delayed_call(update_chest, 10)
		elseif t.Action == 11 then
			-- exit chest screen
			if last_chest then
				Claims.release("chest", last_chest)
			end
			Multiplayer.utils.delayed_call(Multiplayer.broadcast, 1, packets.chest_items:prep(last_chest), cond_same_map)
		end
	end
end
