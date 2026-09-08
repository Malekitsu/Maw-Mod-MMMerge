local events = Multiplayer.events
local cond_same_map = Multiplayer.utils.cond_same_map
local Claims = Multiplayer.Claims

local LOOT_CORPSE_FUNC = 0x424E3D -- the routine Core/events.lua hooks for PickCorpse (mm8)

local confirmed = {}

local packets = {
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

-- the corpse disappears on the click; the loot comes with the arbiter's yes,
-- or after the timeout, and stays gone when somebody else got it first
Claims.define("corpse", {
	scope = "map",
	announce = false,
	on_granted = function(index)
		Multiplayer.utils.delayed_call(loot_corpse_now, 1, index)
	end,
	on_timeout = function(index)
		loot_corpse_now(index)
	end,
})

local function can_pick_corpse(t)
	if Multiplayer.posessed_by_player(t.MonsterIndex) then
		return false
	end

	if confirmed[t.MonsterIndex] then
		return true
	end

	local verdict = Claims.try("corpse", t.MonsterIndex)
	if verdict == "granted" then
		return true
	end
	if verdict == "pending" then
		t.Monster.AIState = const.AIState.Removed
	end
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
	table.clear(confirmed)
end
