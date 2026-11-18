local events = Multiplayer.events
local LogEvent = Multiplayer.utils.LogEvent

local msgs = Multiplayer.require("Network/Lobby/Messages.lua")
local lobbies = Multiplayer.require("Network/Lobby/HostsLists.lua")
local conn = Multiplayer.require("Network/Lobby/Connection.lua")

local function DefaultMyHostGlobals()
	return {
		Name = "Enter your server name",
		Description = "",
		Password = ""
	}
end
local MyHostGlobals = DefaultMyHostGlobals()

local function MyHostInfo()
	local info = msgs.NewHostInfo()
	info.Players = #Multiplayer.connector.clients + 1
	info.MaxPlayers = Multiplayer.players_amount_limit + 1
	info.PasswordUsed = #MyHostGlobals.Password > 0
	info.Active = true
	info.Name = MyHostGlobals.Name
	info.Version = Multiplayer.VERSION
	info.Description = MyHostGlobals.Description
	info.SessionCode = Multiplayer.my_session_code()
	info.LAN = not Multiplayer.internet_connection
	return info
end

local function HandleIncomingList(bin_string, addr, port)
	local MySessionCode = Multiplayer.my_session_code()
	local SenderAddr = ("%s:%s"):format(addr, port)

	local shift = 1
	local valid = false
	local count = 0
	local host, n, err = msgs.ReadHostInfo(bin_string)
	while host do
		valid = true
		if #host.SessionCode ~= Multiplayer.SESSION_ID_SIZE then
			LogEvent("LOBBY", "received host entry with invalid session code: %s", host.SessionCode)
			valid = false
		elseif host.SessionCode == MySessionCode then
			LogEvent("LOBBY", "received my own host info")
			valid = false -- skip mine lobby, if entry still persist on remote server
		end

		if valid then
			local list = host.LAN and lobbies.LanHosts or lobbies.GetLobbyHosts(SenderAddr)
			if list then
				host.Timestamp = os.time()
				list[host.SessionCode] = host
				LogEvent("LOBBY", "host %s added to lobby '%s' list", host.SessionCode, priv == SenderAddr and msgs.LAN_LOBBY or SenderAddr)
			else
				LogEvent("LOBBY", "no host list found for entry: '%s': {%s, %s, %s}", SenderAddr, host.SessionCode, host.Name, host.Description)
			end
		end
		shift = shift + n
		count = count + 1
		host, n, err = msgs.ReadHostInfo(bin_string:sub(shift))
	end

	LogEvent("LOBBY", "Received %d host entries from %s out of %d bytes of data.", count, SenderAddr, #bin_string)
	if err then
		LogEvent("LOBBY", err)
	end
end

local function HandleJoinRequest(dtg, addr, port)
	if not conn.ImHost() then
		LogEvent("LOBBY", "Received MsgJoinLobby message from %s:%s, being a client", addr, port)
		return
	end

	local req, _, err = msgs.ReadJoinRequest(dtg)
	if err then
		LogEvent("LOBBY", "Received invalid MsgJoinLobby message from %s:%s: %s", addr, port, err)
		return
	end

	if req.HostSessionCode ~= Multiplayer.my_session_code() then
		LogEvent("LOBBY", "Received MsgJoinLobby message from %s:%s, designated for other host: %s", addr, port, req.HostSessionCode)
		return
	end

	-- Password check
	if #MyHostGlobals.Password > 0 and req.Password ~= MyHostGlobals.Password then
		local success, err = conn.RespondJoinLobby(addr, port, msgs.NewJoinResponse(false, req.SessionCode, "Invalid password."))
		if not success then
			LogEvent("LOBBY", "MsgJoinLobby handler: %s", err)
		end
		return
	end

	-- Check amount of players
	if Multiplayer.connector:active_clients_count() >= Multiplayer.players_amount_limit then
		local success, err = conn.RespondJoinLobby(addr, port, msgs.NewJoinResponse(false, req.SessionCode, "Server full."))
		if not success then
			LogEvent("LOBBY", "MsgJoinLobby handler: %s", err)
		end
		return
	end

	-- Enable connection listening, if necessary
	if not Multiplayer.connection_listening_on() then
		Multiplayer.listen_connections(nil, true)
		LogEvent("LOBBY", "Enabling connection listenning to establish communication with new client.")
	end
	Multiplayer.connector:add_connections{req.SessionCode}

	local success, err = conn.RespondJoinLobby(addr, port, msgs.NewJoinResponse(true, req.SessionCode, ""))
	if not success then
		LogEvent("LOBBY", "MsgJoinLobby handler: %s", err)
	end
end

local function HandleJoinResponse(dtg, addr, port)
	if conn.ImHost() then
		return
	end

	local lastReq = conn.CurrentJoinRequest()
	if not lastReq then
		return -- drop response, no join requests in process
	end

	local resp, _, err = msgs.ReadJoinResponse(dtg)
	if err then
		LogEvent("LOBBY", "Received invalid MsgHostJoinResponse message from %s:%s: %s", addr, port, err)
		return
	end

	if lastReq.SessionCode ~= resp.SessionCode then
		LogEvent("LOBBY", "Received MsgHostJoinResponse that have not been requested from %s:%s: %s (%s) - %s", addr, port, Multiplayer.my_session_code(), lastReq.SessionCode, resp.SessionCode)
		return
	end

	if not resp.Result then
		LogEvent("LOBBY", "Host %s:%s declined join request: %s", addr, port, resp.Reason)
		conn.ClearPendingRequests()
		events.Call("JoinLobbyRejected", resp.Reason)
		return
	end

	events.Call("JoiningLobby", lastReq)
	conn.ClearPendingRequests()
	Multiplayer.connect_session(lastReq.HostSessionCode)
end

local msg_handlers = {
	[msgs.Types.MsgHostInfo] = function(dtg, addr, port)
		-- Used to register host at dedicated lobby server, MM-side should only receive this message, when LAN host stops
		LogEvent("LOBBY", "Received MsgHostInfo message.")
		HandleIncomingList(dtg, addr, port)
	end,

	[msgs.Types.MsgHostsListRequest] = function(dtg, addr, port)
		-- When received by MM-side, should return list with only one entry - self description
		-- used to request hosts list from dedicated lobby server and to detect open LAN host
		if not conn.ImHost() then
			return nil
		end

		return conn.PublishHost(("%s:%s"):format(addr, port), MyHostInfo())
	end,

	[msgs.Types.MsgHostsListResponse] = function(dtg, addr, port)
		-- Received by MM client, contains HostInfo entries
		LogEvent("LOBBY", "Received MsgHostsListResponse message from %s:%s.", addr, port)
		HandleIncomingList(dtg, addr, port)
	end,

	-- contains client session code and password if used
	-- received from lobby and LAN clients
	[msgs.Types.MsgJoinLobby] = HandleJoinRequest,

	-- contains host's response to join requests - accept or decline with reason
	-- received from lobby and LAN hosts
	[msgs.Types.MsgHostJoinResponse] = HandleJoinResponse,

	[msgs.Types.MsgErrorResponse] = function(dtg, addr, port)
		-- Received by MM client, contains description of errors during request processing
		local err = msgs.ReadErrorResponse(dtg)
		if err then
			LogEvent("LOBBY", err)
		end
	end,
}

-- Checker to use within connector for datagrams handling

local function lobby_checker(connector, dtg, addr, port)
	local ptr = mem.topointer(dtg)
	if mem.u4[ptr] ~= msgs.LOBBY_COOKIE or #dtg < 5 then
		--LogEvent("LOBBY", "Received invalid message: length %d, cookie %d, type: %d", #dtg, mem.u4[ptr], mem.u1[ptr + 4])
		return false
	end

	local msg_type = mem.u1[ptr + 4]
	local handler = msg_handlers[msg_type]

	if not handler then
		LogEvent("LOBBY", "Message of unknown type %d received", msg_type)
		return false
	end

	LogEvent("LOBBY", "Received message: length %d, cookie %d, type: %d", #dtg, mem.u4[ptr], mem.u1[ptr + 4])
	handler(string.sub(dtg, 6), addr, port)
	return true
end

function Multiplayer.std_events.MultiplayerConnectorCreated(connector)
	connector:add_dtg_checker(lobby_checker)
end

function events.NetworkCycle()
	conn.ServeIncoming(lobby_checker)
end

return {
	MyHostInfo = MyHostInfo,
	MyHostGlobals = MyHostGlobals,
	DefaultMyHostGlobals = DefaultMyHostGlobals,
}
