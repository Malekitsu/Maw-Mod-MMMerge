local events = Multiplayer.events

local packets = {
	arcomage_win = {
		bulb = function(tavern_id)
			return Multiplayer.utils.num_to_hexstr(tavern_id, 4)
		end,
		handler = function(bin_string, metadata)
			local tavern_id = mem.u4[mem.topointer(bin_string)]
			vars.ArcomageWinsExtra = vars.ArcomageWinsExtra or {}
			vars.ArcomageWinsExtra[tavern_id] = true
		end,
		check_delivery = true
	}
}
Multiplayer.utils.init_packets(packets)

function events.ArcomageMatchEnd(t)
	if t.result == 1 then
		local tavern_id = Game.HousesExtra[t.House].IndexByType
		Multiplayer.broadcast(packets.arcomage_win:prep(tavern_id), nil)
	end
end

function events.GatherGameData(t)
	t.ArcomageWins = vars.ArcomageWinsExtra
end

function events.ProcessGameData(t)
	vars.ArcomageWinsExtra = t.ArcomageWins
end