local events = Multiplayer.events
local DEFAULT_FACTOR = 0.5
local last_host_factor = DEFAULT_FACTOR

Multiplayer.friendly_fire_factor = DEFAULT_FACTOR

Multiplayer.utils.UI.CustomSettings.Numeric("Friendly fire factor: ", Multiplayer, "friendly_fire_factor", 0.05, 0, 1)

local packets = {
	upd_factor = {
		bulb = function()
			return Multiplayer.utils.num_to_hexstr((Multiplayer.friendly_fire_factor * 100):round())
		end,
		handler = function(bin_string, metadata)
			if metadata.sender_id ~= Multiplayer.main_player_in_game() then
				return
			end
			Multiplayer.friendly_fire_factor = Multiplayer.utils.num_from_hexstr(bin_string) / 100
			last_host_factor = Multiplayer.friendly_fire_factor

			if Game.CurrentScreen == Multiplayer.UI_SCREEN then
				Multiplayer.utils.UI.CustomSettings.Update()
			end
		end,
		check_delivery = true,
		ignore_reload_count = true
	}
}
Multiplayer.utils.init_packets(packets)

function events.MultiplayerExtraSettingsClosed()
	if Multiplayer.im_host() then
		Multiplayer.broadcast(packets.upd_factor:prep(), nil)
	else
		Multiplayer.friendly_fire_factor = last_host_factor
	end
end

function events.MultiplayerStarted()
	Multiplayer.friendly_fire_factor = Multiplayer.SaveGameData().friendly_fire_factor or DEFAULT_FACTOR
end

function events.LoadMapScripts(WasInGame)
	if not WasInGame then
		Multiplayer.friendly_fire_factor = Multiplayer.SaveGameData().friendly_fire_factor or DEFAULT_FACTOR
	end
end

function events.BeforeSaveGame()
	Multiplayer.SaveGameData().friendly_fire_factor = Multiplayer.friendly_fire_factor
end

function events.GatherGameData(t)
	t.friendly_fire_factor = (Multiplayer.friendly_fire_factor * 100):round()
end

function events.ProcessGameData(t)
	Multiplayer.friendly_fire_factor = (t.friendly_fire_factor or 10) / 100
end
