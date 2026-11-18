local events = Multiplayer.events
local LogEvent = Multiplayer.utils.LogEvent

local msgs = Multiplayer.require("Network/Lobby/Messages.lua")
local lobbies = Multiplayer.require("Network/Lobby/HostsLists.lua")
local conn = Multiplayer.require("Network/Lobby/Connection.lua")
local handlers = Multiplayer.require("Network/Lobby/Handlers.lua")

Multiplayer.utils.SetEventLogging("LOBBY", true)

-- Helper functions

local function BroadcastMyHost(LAN)
	return conn.BroadcastHost(handlers.MyHostInfo(), LAN)
end

local function BroadcastMyHostDisabled(LAN)
	local Host = handlers.MyHostInfo()
	Host.Active = false
	return conn.BroadcastHost(Host, LAN)
end

local Selection = msgs.NewHostSelection()
local function BroadcastHostsListRequest()
	return conn.BroadcastHostsListRequest(Selection)
end

-- Notify remote lobby server when host shuts down

function events.LobbyHostingDisabled(LANOff, InternetOff)
	if LANOff and not Multiplayer.internet_connection then
		BroadcastMyHostDisabled(true)
	end

	if InternetOff and Multiplayer.internet_connection then
		BroadcastMyHostDisabled(false)
	end
end

-- Ticker to keep remote lobby server host entry active

local LastPublishTime = 0
local function PeriodicBroadcast()
	LastPublishTime = os.time()
	local success, err = BroadcastMyHost(false)
	if not success then
		LogEvent("LOBBY", "Periodic publish call failed: %s", err)
	end
end

function events.LobbyHostingEnabled()
	if Multiplayer.internet_connection then
		PeriodicBroadcast()
	end
end

function events.NetworkCycle()
	if conn.LobbyLookupState() and conn.ImHost() and Multiplayer.internet_connection and os.time() - LastPublishTime >= 30 then
		PeriodicBroadcast()
	end
end

function events.BeforeSaveGame()
	Multiplayer.SaveGameData().MyHostGlobals = handlers.MyHostGlobals
end

function events.MultiplayerStarted()
	local t = Multiplayer.SaveGameData().MyHostGlobals
	if not t then
		t = handlers.DefaultMyHostGlobals()
		t.Name = string.format("%s's server", Party[0].Name)
	end
	for k, v in pairs(t) do
		handlers.MyHostGlobals[k] = v
	end
end

return {
	LobbyLookupState = conn.LobbyLookupState,
	EnableLobbyLookup = conn.EnableLobbyLookup,
	DisableLobbyLookup = conn.DisableLobbyLookup,
	Lobbies = lobbies.Lobbies,
	LANHosts = lobbies.LanHosts,
	Selection = Selection,
	MyHostGlobals = handlers.MyHostGlobals,
	CurrentJoinRequest = conn.CurrentJoinRequest,
	ClearPendingRequests = conn.ClearPendingRequests,
	PurgeInactive = lobbies.PurgeInactive,

	BroadcastMyHost = BroadcastMyHost,
	BroadcastHostsListRequest = BroadcastHostsListRequest,
	Join = conn.RequestJoinLobby,
	ImHost = conn.ImHost,

	debug = {
		GetUDP = conn.debug.GetUDP
	}
}

--[[
TEST = Multiplayer.require("Network/Lobby.lua")
print(TEST.EnableLobbyLookup())
print(TEST.debug.GetUDP() == Multiplayer.connector.udp)
print(TEST.BroadcastMyHost())
Sleep(1000,1000)
print(TEST.BroadcastHostsListRequest())
Sleep(1000,1000)
]]--


--[[
-- Host
TEST = Multiplayer.require("Network/Lobby.lua")
print(TEST.EnableLobbyLookup())
print(TEST.debug.GetUDP() == Multiplayer.connector.udp)

-- Client 1st step
TEST = Multiplayer.require("Network/Lobby.lua")
print(TEST.EnableLobbyLookup())
print(TEST.debug.GetUDP() == Multiplayer.connector.udp)
print(TEST.BroadcastHostsListRequest())
Sleep(1000,1000)
print(dump(TEST.LANHosts))
print(dump(TEST.Lobbies))

-- Client 2nd step
req = {
		HostSessionCode = "ac1b0001cc53000000000000",
		SessionCode = Multiplayer.my_session_code(),
		Password = ""
	}
print(TEST.Join("255.255.255.255:4445", req))
Sleep(4000,4000)
]]--
