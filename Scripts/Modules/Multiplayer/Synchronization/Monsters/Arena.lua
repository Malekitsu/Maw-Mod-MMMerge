local events = Multiplayer.events

local last_status

local packets = {
	arena_status = {
		bulb = Multiplayer.utils.num_to_hexstr,
		handler = function(bin_string, metadata)
			local status = mem.i4[mem.topointer(bin_string)]
			Party.InArenaQuest = status
			last_status = status
		end,
		check_delivery = true,
		same_map_only = true
	}
}
Multiplayer.utils.init_packets(packets)

local function checker()
	while(TownPortalControls.IsArena()) do
		Multiplayer.debug.ArenaCheckerOn = true

		if Party.InArenaQuest ~= last_status then
			last_status = Party.InArenaQuest
			Multiplayer.broadcast(packets.arena_status:prep(last_status), Multiplayer.utils.cond_same_map)
		end
		coroutine.yield()
	end
	Multiplayer.debug.ArenaCheckerOn = false
end

local function start_checker()
	if TownPortalControls.IsArena() then
		Multiplayer.utils.CoTickCounter(coroutine.create(checker), 16)
	end
end
events.MapLoadingDone = start_checker
events.MultiplayerStarted = start_checker

function events.MultiplayerPrepMapData(t)
	if TownPortalControls.IsArena() then
		t.ArenaStatus = Party.InArenaQuest
	end
end

function events.MultiplayerProcessMapData(t)
	if t.Actual and t.ArenaStatus then
		Multiplayer.utils.LogEvent("MAP_LOAD", "Processing arena info: %s.", type(t.ArenaStatus))
		Party.InArenaQuest = t.ArenaStatus
		last_status = t.ArenaStatus
	end
end

function events.ArenaWinConditionsCheck(t)
	local Won = true
	for i,v in Map.Monsters do
		if v.AIState ~= const.AIState.Removed and v.AIState ~= const.AIState.Dead and v.HP > 0 and not Multiplayer.posessed_by_player(i) then
			Won = false
			break
		end
	end
	t.Won = Won
end
