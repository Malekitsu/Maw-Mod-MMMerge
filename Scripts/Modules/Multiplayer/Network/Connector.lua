local LogEvent = Multiplayer.utils.LogEvent
local Relay = Multiplayer.require("Network/Relay.lua")
local UDPPuncher = Multiplayer.require("Network/UDPPuncher.lua")

Multiplayer.UDP_PORT = 0
Multiplayer.UDP_PUNCH_PERIOD = 512 -- milliseconds

------------------------------------------------------------------
-- connection testing

local RELAY_COOKIE = 0xfadec0de

local function relay_checker(connector, dtg)
	local ptr = mem.topointer(dtg)
	if not (mem.u4[ptr] == RELAY_COOKIE and #dtg >= 5) then
		return false
	end

	local client_id = mem.u1[ptr + 4]
	local client = connector.clients[client_id]
	if client then
		connector:sendto(client, string.sub(dtg, 6))
	else
		Multiplayer.utils.LogEvent("NETWORK", "Host relay request to unknown client: %s", client_id)
	end
	return true
end

------------------------------------------------------------------
-- Connector

local function udp_internet_test(udp)
	local addr, port = udp:getsockname()
	local t = {udp = udp, addr = addr, port = port}

	Multiplayer.utils.LogEvent("NETWORK", "Testing udp %s:%s...", t.addr, t.port)
	local relay_access, relay_addr = Relay.myaddr(udp)
	local stun_addr = Multiplayer.STUN_public_addr(udp)

	if relay_access then
		t.relay_addr = relay_addr
		t.public_addr, t.public_port = relay_addr:match("(.*):(%d*)")
	end
	if stun_addr then
		t.stun_addr = stun_addr
		t.public_addr, t.public_port = stun_addr:match("(.*):(%d*)")
	end
	return t
end

local function choose_internet_udp(variants)
	local result

	for k, t in pairs(variants) do
		if t.stun_addr and t.relay_addr then
			result = t
			break
		elseif t.stun_addr or t.relay_addr then
			result = t
		end
	end

	return result or variants[1]
end

local function open_udp()
	local hostname = socket.dns.gethostname()
	local ip, iplist = socket.dns.toip(hostname)

	local have_list = type(iplist) == 'table' and type(iplist.ip) == 'table' and #iplist.ip > 1
	local iplist = have_list and iplist.ip or {ip}

	if Multiplayer.internet_connection then
		local variants = {}
		for k,v in pairs(iplist) do
			local udp = assert(socket.udp())
			if udp:setsockname(v, Multiplayer.UDP_PORT) then
				udp:settimeout(0)
				table.insert(variants, udp_internet_test(udp))
			end
		end

		local result = choose_internet_udp(variants)
		for k, t in pairs(variants) do
			if t ~= result then
				t.udp:close()
			end
		end

		Multiplayer.utils.LogEvent("NETWORK", "Selected udp %s:%s.", result.addr, result.port)
		return {udp = result.udp, addr = result.addr, port = result.port, public_addr = result.public_addr, public_port = result.public_port, addrs = {addr}}

	else -- LAN
		local udp = assert(socket.udp())
		assert(udp:setsockname("0.0.0.0", Multiplayer.UDP_PORT))
		assert(udp:setoption("broadcast", true) == 1)
		udp:settimeout(0)

		local addr, port = udp:getsockname()
		return {udp = udp, addr = iplist[1], port = port, public_addr = Multiplayer.EMPTY_ADDR, public_port = 0, addrs = iplist}
	end
end

local function sendto(connector, client, data)
	local result, err

	if client.remote_relay then
		result, err = Relay.relay_packet(client.addrportbin, data)
	elseif client.host_relay then
		local buf = Multiplayer.utils.sendbuff
		local host = connector.clients[0]
		if host then
			mem.u4[buf] = RELAY_COOKIE
			mem.u1[buf + 4] = client.id
			result, err = connector.udp:sendto(mem.string(buf, 5, true) .. data, host.addr, host.port)
		else
			result, err = false, "Host does not exist."
		end
	else
		result, err = connector.udp:sendto(data, client.addr, client.port)
	end

	if not result then
		Multiplayer.utils.LogEvent("CONNECTION", err)
	end

	return result
end

local function broadcast(connector, data)
	for _, client in pairs(connector.clients) do
		connector:sendto(client, data)
	end
end

local function receiveall(connector)
	local data, addr, port = connector.udp:receivefrom()
	while data do
		connector:handle(data, addr, port)
		data, addr, port = connector.udp:receivefrom()
	end
end

local function flush_incoming(connector)
	while connector.udp:receive() do
		-- flush udp buffer
	end
end

local function receive_next(connector, amount)
	amount = amount or 1
	local data, addr, port
	repeat
		data, addr, port = connector.udp:receivefrom()
		if not data then
			return false
		end
		connector:handle(data, addr, port)
		amount = amount - 1
	until amount <= 0
	return true
end

local function receive_timeout(connector, val)
	connector.udp:settimeout(val or 0)
end

local function create_client(addr, port)
	assert(addr)
	assert(port)

	local client = {}
	client.id = 0
	client.addr = addr
	client.port = port
	client.addrportbin = Relay.binaddr(addr, port)
	client.map = 1
	client.skin = 1
	client.in_game = false
	client.host_relay = false
	client.remote_relay = false
	client.last_packet_timestamp = os.time()
	client.name = ""
	client.session_code = ""
	return client
end

local function add_client(connector, addr, port, i)
	for id, client in pairs(connector.clients) do
		if client.addr == addr and client.port == port then
			LogEvent("CONNECTION", "add_client call with aready registered IP and port (%s:%s), returning existing entry #%s.", addr, port, id)
			return id, client
		end
	end

	local id, client = i or (#connector.clients + 1), create_client(addr, port)
	client.id = id
	connector.clients[id] = client
	return id, client
end

local function active_clients_count(connector)
	local count = 0
	for i, v in pairs(connector.clients) do
		if v.in_game then
			count = count + 1
		end
	end
	return count
end

local function remove_client(connector, i)
	connector.clients[i] = nil
end

local function close_connector(connector)
	connector.udp:close()
end

local function create_connector(message_handler)
	assert(message_handler)

	local connector = {}
	local udp = open_udp()

	connector.udp = udp.udp
	connector.addr = udp.addr
	connector.port = udp.port
	connector.public_addr = udp.public_addr
	connector.public_port = udp.public_port
	connector.all_lan_addrs = udp.addrs

	connector.clients = {}
	connector.connections = {}
	connector.allow_new_connections = false

	connector.sendto = sendto
	connector.receive_next = receive_next
	connector.add_client = add_client
	connector.remove_client = remove_client
	connector.active_clients_count = active_clients_count
	connector.receiveall = receiveall
	connector.receive_timeout = receive_timeout
	connector.broadcast = broadcast
	connector.close = close_connector
	connector.identifier = tostring(connector.udp)
	connector.flush = flush_incoming

	connector.relay_checker = relay_checker
	connector.set_connections = UDPPuncher.set_connections

	if Multiplayer.internet_connection then
		connector.punch_checker = UDPPuncher.punch_checker
		connector.add_connections = UDPPuncher.add_connections
		connector.punch_connections = UDPPuncher.punch_connections
	else
		connector.punch_checker = UDPPuncher.LAN_punch_checker
		connector.add_connections = UDPPuncher.LAN_add_connections
		connector.punch_connections = UDPPuncher.LAN_punch_connections
	end

	connector.dtg_checkers = {}
	connector.add_dtg_checker = function(con, checker)
		if not table.find(con.dtg_checkers, checker) then
			table.insert(con.dtg_checkers, checker)
		end
	end
	connector.remove_dtg_checker = function(con, checker)
		local n = table.find(con.dtg_checkers, checker)
		if n then
			table.remove(con.dtg_checkers, n)
		end
	end
	connector:add_dtg_checker(connector.punch_checker)
	connector:add_dtg_checker(connector.relay_checker)

	connector.relay_tested = false
	connector.relay_present = false
	connector.public_addr_from_relay = Relay.myaddr
	connector.have_relay_access = function(con, force)
		if not Multiplayer.internet_connection then
			return false
		end
		if force or not con.relay_tested then
			con.relay_present = Relay.have_relay_access()
			con.relay_tested = true
		end
		return con.relay_present
	end

	connector.relayto = function(con, dtg, addr, port)
		if con:have_relay_access() then
			return Relay.relay_packet(Relay.binaddr(addr, port), dtg)
		end
		return nil, "no access to relay"
	end

	connector.message_handler = message_handler
	connector.handle = function(con, data, addr, port)
		for _, f in pairs(connector.dtg_checkers) do
			if f(con, data, addr, port) then
				return
			end
		end
		con:message_handler(data)
	end

	events.Call("MultiplayerConnectorCreated", connector)
	return connector
end
Multiplayer.create_connector = create_connector

------------------------------------------------------------------
-- Connection routines

local listening_connections = false
Multiplayer.connection_listening_on = function()
	return listening_connections
end

local listening_routine
Multiplayer.listener = function()
	while listening_connections do
		Multiplayer.connector:punch_connections(true)
		for session_id, conn in pairs(Multiplayer.connector.connections) do
			if conn.local_established or conn.public_established or conn.relay_established then
				events.call("ConnectionTestFinished", session_id, conn)
			else
				events.call("ConnectionTestStarted", session_id)
			end
		end
		coroutine.yield()
	end
	listening_connections = false
end

Multiplayer.listen_connections = function(session_ids, allow_new)
	Multiplayer.stop_listening()
	if session_ids then
		Multiplayer.connector:set_connections(session_ids)
	end
	Multiplayer.connector.allow_new_connections = allow_new

	listening_connections = true
	listening_routine = coroutine.create(Multiplayer.listener)
	Multiplayer.utils.CoMillisecCounter(listening_routine, Multiplayer.UDP_PUNCH_PERIOD)
end

Multiplayer.stop_listening = function()
	if not listening_routine then
		listening_connections = false
		return
	end

	listening_connections = false
	while coroutine.status(listening_routine) ~= "dead" do
		coroutine.resume(listening_routine)
	end
	listening_routine = nil

	if not Multiplayer.connector then
		return
	end

	Multiplayer.connector.allow_new_connections = false
	for session_id, conn in pairs(Multiplayer.connector.connections) do
		events.call("ConnectionTestFinished", session_id, conn)
	end
end

Multiplayer.connect_session = function(session_id)
	if #session_id < Multiplayer.SESSION_ID_SIZE then
		LogEvent("CONNECTION", "Attempt to connect to session by invalid id: %s, size is %s, expected %s.",
			session_id, #session_id, Multiplayer.SESSION_ID_SIZE)
		return
	elseif session_id == Multiplayer.my_session_code() then
		return
	elseif #session_id > Multiplayer.SESSION_ID_SIZE then
		session_id = session_id:sub(1, 24)
	end

	local connection = Multiplayer.connector.connections[session_id]
	LogEvent("CONNECTION", "Trying to connect to %s", session_id)

	LogEvent("CONNECTION", "Starting to punch connection, calling 'ConnectionTestStarted' event.")
	events.call("ConnectionTestStarted", session_id)
	Multiplayer.connector:set_connections{session_id}
	connection = Multiplayer.connector.connections[session_id]
	local timeout = os.time() + 8

	while os.time() < timeout do
		Multiplayer.connector:punch_connections(true)
		socket.sleep(Multiplayer.UDP_PUNCH_PERIOD / 1000)
		Multiplayer.connector:receiveall()
		if connection.local_established or connection.public_established then
			LogEvent("CONNECTION", "Connection established in %s seconds", os.time() - timeout + 8)
			break
		end
	end
	events.call("ConnectionTestFinished", session_id, connection)

	local function send_handshake(my_addr, network_type, host_session_code, host_addr, host_port, use_relay, response_timeout)
		local dtg = Multiplayer.packets.handshake_client:prep(my_addr, network_type, host_session_code, host_addr, host_port, use_relay)
		local hash = Multiplayer.add_to_send_queue(0, dtg)
		local response = Multiplayer.wait_response(hash, response_timeout)

		if response then
			return true
		else
			LogEvent("CONNECTION", "Could not receive server's handshake after %s seconds.", response_timeout)
			return false
		end
	end

	if connection.local_established then
		LogEvent("CONNECTION", "Connection to local address established. Sending handshake.")
		local my_addr = Multiplayer.internet_connection and Multiplayer.my_private_addr() or ("%s:%s"):format(connection.my_addr, Multiplayer.connector.port)
		local result = send_handshake(my_addr, 1, session_id, connection.local_addr, connection.local_port, false, 8)
		if result then return true end
	end

	if connection.public_established then
		LogEvent("CONNECTION", "Connection to public address established. Sending handshake.")
		local result = send_handshake(Multiplayer.my_public_addr(), 2, session_id, connection.public_addr, connection.public_port, false, 8)
		if result then return true end
	end

	if connection.relay_established then
		LogEvent("CONNECTION", "Connection through relay established. Sending handshake.")
		local result = send_handshake(Multiplayer.my_public_addr(), 3, session_id, connection.public_addr, connection.public_port, true, 8)
		if result then return true end
	end

	LogEvent("CONNECTION", "Could not connect session %s.", session_id)
	return false
end

Multiplayer.my_private_addr = function(for_session)
	if not Multiplayer.in_game then
		return Multiplayer.EMPTY_ADDRPORT
	end

	if not Multiplayer.internet_connection and for_session then
		local conn = Multiplayer.connector.connections[for_session]
		if conn then
			return ("%s:%s"):format(conn.my_addr, Multiplayer.connector.port)
		end
	end

	return ("%s:%s"):format(Multiplayer.connector.addr, Multiplayer.connector.port)
end

Multiplayer.my_public_addr = function()
	if not Multiplayer.in_game then
		return Multiplayer.EMPTY_ADDRPORT
	end
	if Multiplayer.connector.public_addr and Multiplayer.connector.public_port then
		return ("%s:%s"):format(Multiplayer.connector.public_addr, Multiplayer.connector.public_port)
	end
	return Multiplayer.EMPTY_ADDRPORT
end

Multiplayer.myaddr = function()
	if not Multiplayer.in_game then
		return Multiplayer.EMPTY_ADDRPORT
	end
	return Multiplayer.internet_connection and Multiplayer.my_public_addr() or Multiplayer.my_private_addr()
end
