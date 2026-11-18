local events = Multiplayer.events
local item_to_bin, binstr_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.binstr_to_item
local cond_same_map = Multiplayer.utils.cond_same_map
local LogEvent = Multiplayer.utils.LogEvent

local LastWeatherState = {}

local Remote = false
local function ApplyRemoteWeather(t)
	Remote = true
	Game.SetWeather(t.WeatherState,  t.CurrentEffect)
	Remote = false
end

local packets = {
	weather_state = {
		bulb =  function(t)
			t.GameWeatherFog = Game.Weather.Fog
			t.FogRange1 = Game.Weather.FogRange1
			t.FogRange2 = Game.Weather.FogRange2
			return item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			local t = binstr_to_item(bin_string)
			LastWeatherState[metadata.map_id] = t
			Game.Weather.Fog = t.GameWeatherFog
			if Game.Weather.Fog then
				Game.Weather.SetFog(t.FogRange1, t.FogRange2)
			end

			if Map.MapStatsIndex == metadata.map_id then
				ApplyRemoteWeather(t)
			end
		end,
		check_delivery = true,
		compress = true
	}
}
Multiplayer.utils.init_packets(packets)

function events.WeatherChanged(t)
	if Multiplayer.leave_map_halt then
		return
	end

	if not Remote then
		if Multiplayer.my_id == Multiplayer.main_player_on_map() then
			Multiplayer.broadcast(packets.weather_state:prep(t), cond_same_map)
		else
			t.Handled = true
		end
	end

	if not t.Handled then
		LastWeatherState[Map.MapStatsIndex] = t
	end
end

function events.MultiplayerPrepMapData(t)
	t.WeatherState = LastWeatherState[Map.MapStatesIndex]
end

function events.MultiplayerProcessMapData(t)
	LogEvent("MAP_LOAD", "Processing weather info: %s.", type(t.WeatherState))
	if t.WeatherState then
		ApplyRemoteWeather(t.WeatherState)
	end
end
