Multiplayer = {}
Multiplayer.VERSION = "30.09.2024/1"
Multiplayer.Path = AppPath .. "Scripts\\Modules\\Multiplayer\\"
Multiplayer.debug = {}
Multiplayer.my_id = 0
Multiplayer.players_amount_limit = 2
Multiplayer.in_game = false
Multiplayer.my_skin = 194
Multiplayer.internet_connection = false
Multiplayer.leave_map_halt = false

local MULTIPLAYER_MODULES  = {}
function Multiplayer.require(subpath)
	local filepath = Multiplayer.Path .. subpath
	local result = MULTIPLAYER_MODULES[filepath]
	if result then
		return result
	end

	result = dofile(filepath) or true
	MULTIPLAYER_MODULES[filepath] = result
	return result
end

Multiplayer.require("Utils.lua")
Multiplayer.require("SessionId.lua")
Multiplayer.require("Hooks.lua")
Multiplayer.require("Packets.lua")
Multiplayer.require("Synchronization.lua")
Multiplayer.require("UI.lua")

local LogEvent = Multiplayer.utils.LogEvent
local SetEventLogging = Multiplayer.utils.SetEventLogging

SetEventLogging("INTERNAL", true)
SetEventLogging("CONNECTION", true)
SetEventLogging("NETWORK", true)
SetEventLogging("PLAYERS_SYNC", true)
SetEventLogging("EVENTS", true)
SetEventLogging("MAP_LOAD", true)
SetEventLogging("SAVE_LOAD", true)
SetEventLogging("EVT", true)
SetEventLogging("SPELLS", false)
SetEventLogging("SYNC", false)
SetEventLogging("MONSTERS", false)
SetEventLogging("TURN_BASED", false)

LogEvent("INTERNAL", "Multiplayer modules loaded. Version '%s'", Multiplayer.VERSION)

local events = Multiplayer.events

local function receiver()
	Multiplayer.connector:receiveall()
end

local function sender()
	Multiplayer.sendall(16)
end

Multiplayer.init = function()
	Multiplayer.connector = Multiplayer.create_connector(Multiplayer.receive_handler)
	Multiplayer.enable_hooks()
	Multiplayer.in_game = true
	events.Call("MultiplayerStarted")
end

Multiplayer.close = function()
	Multiplayer.connector:receiveall()
	events.Call("MultiplayerStopped")
	Multiplayer.disable_hooks()
	Multiplayer.connector:close()
	Multiplayer.connector = nil
	Multiplayer.my_id = 0
	Multiplayer.in_game = false
end

Multiplayer.addclient = function(addrport, i)
	local addr, port = addrport:match("(%A*):(%d*)")
	return Multiplayer.connector:add_client(addr, port, i)
end

Multiplayer.remove_client = function(i)
	local client = Multiplayer.connector.clients[i]
	if client then
		events.Call("ClientLeft", client.id, client)
		Multiplayer.connector:remove_client(i)
	end
end

Multiplayer.main_player_on_map = function(mapid)
	mapid = mapid or Map.MapStatsIndex
	local main = Multiplayer.my_id
	for k, v in pairs(Multiplayer.connector.clients) do
		if v.in_game and v.map == mapid then
			main = math.min(main, k)
		end
	end
	return main
end

Multiplayer.main_player_in_game = function()
	local main = Multiplayer.my_id
	for k, v in pairs(Multiplayer.connector.clients) do
		if v.in_game and k < main then
			main = k
		end
	end
	return main
end

Multiplayer.im_host = function()
	return Multiplayer.main_player_in_game() == Multiplayer.my_id
end

Multiplayer.alone_on_map = function(mapid)
	mapid = mapid or Map.MapStatsIndex
	for k, v in pairs(Multiplayer.connector.clients) do
		if v.in_game and v.map == mapid then
			return false
		end
	end
	return true
end
