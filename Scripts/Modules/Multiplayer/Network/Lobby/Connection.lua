local events = Multiplayer.events
local LogEvent = Multiplayer.utils.LogEvent

local msgs = Multiplayer.require("Network/Lobby/Messages.lua")
local lobbies = Multiplayer.require("Network/Lobby/HostsLists.lua")

local UdpConn
local ImHost = false
local SeparateUDP = false
local LobbyLookupEnabled = false
local CurrentJoinRequest

local function NeedSeparateUDP()
	return ImHost and not Multiplayer.internet_connection and tonumber(Multiplayer.connector.port) ~= msgs.LAN_LOBBY_PORT
end

local function OpenUDP()
	if UdpConn then
		return UdpConn
	end

	if not Multiplayer.connector then
		LogEvent("LOBBY", "Attempt to open lobby udp connection with multiplayer disabled")
		return nil
	end

	if not NeedSeparateUDP() then
		UdpConn = Multiplayer.connector.udp
		return UdpConn
	end

	SeparateUDP = true
	UdpConn = assert(socket.udp())
	assert(UdpConn:setsockname("0.0.0.0", msgs.LAN_LOBBY_PORT))
	assert(UdpConn:setoption("broadcast", true) == 1)
	UdpConn:settimeout(0)
	return UdpConn
end

local function CloseUDP()
	if UdpConn and SeparateUDP then
		UdpConn:close()
	end
	UdpConn = nil
	SeparateUDP = false
end

local function CheckConnector()
	if not LobbyLookupEnabled then
		return
	elseif not UdpConn then
		OpenUDP()
	else
		local NeedSeparate = NeedSeparateUDP()
		if NeedSeparate and not SeparateUDP or not NeedSeparate and SeparateUDP then
			CloseUDP()
			OpenUDP()
		end
	end
end

local function ServeIncoming(handler)
	if UdpConn and SeparateUDP then
		local data, addr, port = UdpConn:receivefrom()
		while data do
			--LogEvent("LOBBY", "Separate UDP received message: %s", data)
			handler(nil, data, addr, port)
			data, addr, port = UdpConn:receivefrom()
		end
	end
end


------------------------------------
-- Host publishing

local function PublishHostBin(LobbyAddr, Bin)
	if not UdpConn then
		local err = "Attempt to send MsgHostInfo message with multiplayer disabled."
		LogEvent("LOBBY", err)
		return false, err
	end

	if not ImHost then
		local err = "Attempt to send MsgHostInfo message as client."
		LogEvent("LOBBY", err)
		return false, err
	end

	local bin = msgs.Header(msgs.Types.MsgHostInfo) .. Bin
	if #bin > 512 then
		return false, "Name and description exceed total availalble length"
	end

	return UdpConn:sendto(Bin, LobbyAddr:match("(%A*):(%d*)"))
end

local function PublishHost(LobbyAddr, Host)
	return PublishHostBin(LobbyAddr, msgs.Header(msgs.Types.MsgHostInfo) .. msgs.HostInfoToBin(Host))
end

local function BroadcastHost(Host, LAN)
	if LAN == nil then
		LAN = not Multiplayer.internet_connection
	end
	if LAN then
		return PublishHost(msgs.LAN_LOBBY, Host)
	end

	local bin = msgs.Header(msgs.Types.MsgHostInfo) .. msgs.HostInfoToBin(Host)
	if #bin > 512 then
		return false, "Name and description exceed total maximum availalble length"
	end

	local success, err
	local errors = {}
	for addr, v in pairs(lobbies.Lobbies) do
		if v.Active then
			success, err = PublishHostBin(addr, bin)
			if not success then
				table.insert(errors, "Could not publish host at lobby " .. addr .. ": " .. err)
			end
		end
	end

	if #errors > 0 then
		return false, table.concat(errors, "; ")
	end

	return true, ""
end

------------------------------------
-- Hosts list

local function RequestHostsListBin(LobbyAddr, Bin)
	if not UdpConn then
		local err = "Attempt to send MsgHostsListRequest message with multiplayer disabled."
		LogEvent("LOBBY", err)
		return false, err
	end
	return UdpConn:sendto(Bin, LobbyAddr:match("(%A*):(%d*)"))
end

local function RequestHostsList(LobbyAddr, Selection)
	local bin = msgs.Header(msgs.Types.MsgHostsListRequest) .. msgs.HostSelectionBin(Selection or msgs.NewHostSelection())
	return RequestHostsListBin(LobbyAddr, bin)
end

local function BroadcastHostsListRequest(Selection)
	Selection = Selection or msgs.NewHostSelection()
	if not UdpConn then
		local err = "Attempt to send MsgHostsListRequest message with multiplayer disabled."
		LogEvent("LOBBY", err)
		return false, err
	end

	if not Multiplayer.internet_connection then
		return RequestHostsList(msgs.LAN_LOBBY)
	end

	local bin = msgs.Header(msgs.Types.MsgHostsListRequest) .. msgs.HostSelectionBin(Selection)
	local success, err
	local errors = {}
	for LobbyAddr, v in pairs(lobbies.Lobbies) do
		if v.Active then
			local addr, port = LobbyAddr:match("(%A*):(%d*)")
			if not tonumber(port) then
				debug.Message("Invalid lobby addr: " .. LobbyAddr)
			end
			success, err = UdpConn:sendto(bin, addr, port)
			if not success then
				table.insert(errors, "Failed to request hosts list from lobby server " .. LobbyAddr .. ": " .. err)
			end
		end
	end

	if #errors > 0 then
		return false, table.concat(errors, "; ")
	end

	return true, ""
end

------------------------------------
-- Join request

local function RequestJoinLobby(LobbyAddr, Request)
	assert(Request)

	if not UdpConn then
		local err = "Attempt to send MsgJoinLobby message with multiplayer disabled."
		LogEvent("LOBBY", err)
		return false, err
	end

	if ImHost then
		local err = "Attempt to send MsgJoinLobby message as host."
		LogEvent("LOBBY", err)
		return false, err
	end

	CurrentJoinRequest = Request

	local bin = msgs.Header(msgs.Types.MsgJoinLobby) .. msgs.JoinLobbyRequestBin(Request)
	return UdpConn:sendto(bin, LobbyAddr:match("(%A*):(%d*)"))
end

------------------------------------
-- Join response

local function RespondJoinLobby(Addr, Port, Response)
	if not UdpConn then
		local err = "Attempt to send MsgHostJoinResponse message with multiplayer disabled."
		LogEvent("LOBBY", err)
		return false, err
	end

	local bin = msgs.Header(msgs.Types.MsgHostJoinResponse) .. msgs.JoinResponseBin(Response)
	return UdpConn:sendto(bin, Addr, Port)
end

------------------------------------
-- Enable/disable active lobby connection

local function LobbyLookupState()
	return LobbyLookupEnabled
end

local function EnableLobbyLookup()
	LobbyLookupEnabled = true
	CheckConnector()
	if ImHost then
		events.Call("LobbyHostingEnabled")
	end
end

local function DisableLobbyLookup()
	if ImHost then
		events.Call("LobbyHostingDisabled", not Multiplayer.internet_connection, Multiplayer.internet_connection) -- LAN disabled, Internet disabled
	end
	LobbyLookupEnabled = false
	CloseUDP()
end

------------------------------------
-- Events

function events.MultiplayerBeforeConnectionTypeChanged(JustEnabled, IsInternet)
	if LobbyLookupEnabled and ImHost and not JustEnabled then
		events.Call("LobbyHostingDisabled", not Multiplayer.internet_connection and IsInternet, Multiplayer.internet_connection and not IsInternet) -- LAN disabled, Internet disabled
		LobbyLookupEnabled = false
		CloseUDP()
	end
	CheckConnector()
end

function events.MultiplayerRoleChanged(role)
	if LobbyLookupEnabled and ImHost and role ~= "host" then
		events.Call("LobbyHostingDisabled", not Multiplayer.internet_connection, Multiplayer.internet_connection) -- LAN disabled, Internet disabled
		LobbyLookupEnabled = false
		CloseUDP()
	end
	ImHost = role == "host"
	CheckConnector()
end

function events.MultiplayerStopped()
	if LobbyLookupEnabled then
		DisableLobbyLookup()
	end
end


return {
	CurrentJoinRequest = function() return CurrentJoinRequest end,
	ClearPendingRequests = function() CurrentJoinRequest = nil end,
	CheckConnector = CheckConnector,
	Close = CloseUDP,

	PublishHost = PublishHost,
	BroadcastHost = BroadcastHost,

	RequestHostsList = RequestHostsList,
	BroadcastHostsListRequest = BroadcastHostsListRequest,

	RequestJoinLobby = RequestJoinLobby,

	RespondJoinLobby = RespondJoinLobby,

	ImHost = function() return ImHost end,
	LobbyLookupState = LobbyLookupState,
	EnableLobbyLookup = EnableLobbyLookup,
	DisableLobbyLookup = DisableLobbyLookup,

	ServeIncoming = ServeIncoming,

	debug = {
		GetUDP = function()
			return UdpConn
		end
	}

}
