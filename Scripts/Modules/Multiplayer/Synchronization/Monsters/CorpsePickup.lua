local events = Multiplayer.events
local cond_same_map = Multiplayer.utils.cond_same_map

local ACCESS_CHECK_DISTANCE = 400
local LOOT_CORPSE_FUNC = 0x424E3D -- the routine Core/events.lua hooks for PickCorpse (mm8)
local CONFIRM_TIMEOUT_MS = 5000

-- corpses hidden while the main player is asked: request hash -> monster index
local pending_corpses = {}
local pending_by_index = {}
local confirmed = {}

local packets = {
	can_pickup_corpse = {
		bulb = function(mon_id)
			return Multiplayer.utils.num_to_hexstr(mon_id, 2)
		end,
		handler = function(bin_string, metadata)
			local mon_id = Multiplayer.utils.num_from_hexstr(bin_string, 2)
			if mon_id < 0 or mon_id >= Map.Monsters.count then
				return true
			end

			local mon = Map.Monsters[mon_id]
			local can_pickup = mon.AIState == const.AIState.Dead
			if can_pickup then
				mon.AIState = const.AIState.Removed
			end
			return can_pickup
		end,
		response = 'can_pickup_corpse_response',
		check_delivery = true,
		same_map_only = true
	},

	can_pickup_corpse_response = {
		bulb = function(handler_result)
			return handler_result and '\1' or '\0'
		end,
		handler = function(bin_string, metadata)
			local allowed = bin_string == '\1'
			local index = pending_corpses[metadata.response_to]
			pending_corpses[metadata.response_to] = nil
			if index then
				pending_by_index[index] = nil
				if allowed then
					Multiplayer.utils.delayed_call(Multiplayer.loot_corpse_now, 1, index)
				end
			end
			return allowed
		end,
		check_delivery = true,
		same_map_only = true
	},

	pickup_corpse = {
		bulb = function(mon_id)
			return Multiplayer.utils.num_to_hexstr(mon_id, 2)
		end,
		handler = function(bin_string, metadata)
			local mon_id = Multiplayer.utils.num_from_hexstr(bin_string, 2)
			if mon_id > 0 and mon_id < Map.Monsters.count then
				Map.Monsters[mon_id].AIState = const.AIState.Removed
				Multiplayer.SyncPlayers.play_puppet_sound2(133, metadata.sender_id)
			end
		end,
		check_delivery = true,
		same_map_only = true
	},
}
Multiplayer.utils.init_packets(packets)

-- the deferred loot: the corpse comes back for one call of the engine routine,
-- which fires PickCorpse again with our approval already given
local function loot_corpse_now(index)
	if index >= Map.Monsters.count then
		return
	end
	local mon = Map.Monsters[index]
	if mon.AIState ~= const.AIState.Removed then
		return
	end

	confirmed[index] = true
	mon.AIState = const.AIState.Dead
	mem.call(LOOT_CORPSE_FUNC, 0, mon["?ptr"])
	confirmed[index] = nil

	if mon.AIState == const.AIState.Dead then
		mon.AIState = const.AIState.Removed
	end
end
Multiplayer.loot_corpse_now = loot_corpse_now

local function can_pick_corpse(t)
	if Multiplayer.posessed_by_player(t.MonsterIndex) then
		return false
	end

	if confirmed[t.MonsterIndex] then
		return true
	end

	local main_player = Multiplayer.main_player_on_map()
	if Multiplayer.my_id == main_player then
		return true -- i am host, no checks necessary
	end

	if pending_by_index[t.MonsterIndex] then
		return false -- already asked about this one
	end

	-- if other players are in range of the corpse, the main player decides who gets it
	local mon, need_check = t.Monster, false
	for i, v in pairs(Multiplayer.client_monsters()) do
		if v < Map.Monsters.count and Multiplayer.utils.distance(Map.Monsters[v], mon) < ACCESS_CHECK_DISTANCE then
			need_check = true
			break
		end
	end

	if not need_check then
		return true -- no potential concurrents in range.
	end

	-- the corpse disappears now; the loot comes when the answer does, or after the timeout
	mon.AIState = const.AIState.Removed
	local hash = Multiplayer.add_to_send_queue(main_player, packets.can_pickup_corpse:prep(t.MonsterIndex))
	pending_corpses[hash] = t.MonsterIndex
	pending_by_index[t.MonsterIndex] = hash
	Multiplayer.utils.LogEvent("SYNC", "Asking host whether monster corpse #%s is pickable", t.MonsterIndex)

	local index = t.MonsterIndex
	Multiplayer.utils.delayed_call2(function()
		if pending_corpses[hash] then
			pending_corpses[hash] = nil
			pending_by_index[index] = nil
			Multiplayer.utils.LogEvent("SYNC", "No answer about corpse #%s, looting it anyway", index)
			loot_corpse_now(index)
		end
	end, CONFIRM_TIMEOUT_MS)
	return false
end

function events.PickCorpse(t)
	if t.Allow then
		t.Allow = can_pick_corpse(t)
		if t.Allow then
			Multiplayer.broadcast(packets.pickup_corpse:prep(t.MonsterIndex), cond_same_map)
		end
	end
end

function events.LeaveMap()
	table.clear(pending_corpses)
	table.clear(pending_by_index)
	table.clear(confirmed)
end
