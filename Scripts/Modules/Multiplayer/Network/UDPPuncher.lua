local Relay = Multiplayer.require("Network/Relay.lua")

local ipv4bin = Multiplayer.utils.ipv4bin
local toipv4 = Multiplayer.utils.toipv4

local PUNCH_COOKIE = 0xdeaddeed

Multiplayer.utils.SetEventLogging("UDP_PUNCHING", false)

local function pair_for_addr(my_addr, addrs)
	local fit = {}
	for _, addr in pairs(addrs) do
		fit[addr] = 0
	end

	local my_parts = {my_addr:match("(%d*).(%d*).(%d*).(%d*)")}
	for _, addr in pairs(addrs) do
		local parts = {addr:match("(%d*).(%d*).(%d*).(%d*)")}
		for i, part in ipairs(parts) do
			if part == my_parts[i] then
				fit[addr] = fit[addr] + 1
			end
		end
	end

	local best_addr = next(fit)
	local best_fit = -1
	for addr, v in pairs(fit) do
		if best_fit == v then
			Multiplayer.utils.LogEvent("INTERNAL", "Can not differentiate match for LAN address %s: %s or %s.", my_addr, best_addr, addr)
		end
		if v > best_fit then
			best_addr = addr
			best_fit = v
		end
	end
	return best_addr
end

local function udppunch_dtg(kind, extra) -- 1 -LAN, 2 - internet (NAT passthrough), 3 - relay, 4 - LAN response, 5 - internet response, 6 - relay response, 7 - LAN addr approval
	local session_id = Multiplayer.my_session_code()
	local buf = Multiplayer.utils.sendbuff
	mem.u4[buf] = PUNCH_COOKIE
	mem.u1[buf + 4] = kind
	return mem.string(buf, 5, true) .. session_id .. (extra or '')
end
Multiplayer.debug.udppunch_dtg = udppunch_dtg

local function set_connections(connector, session_ids)
	connector.connections = {}
	connector:add_connections(session_ids)
end

---- Internet

local function punch_checker(connector, dtg)
	local ptr = mem.topointer(dtg)
	local length = Multiplayer.SESSION_ID_SIZE
	if not (mem.u4[ptr] == PUNCH_COOKIE and #dtg == length + 5) then
		return false
	end

	Multiplayer.utils.LogEvent("UDP_PUNCHING", "Got udppunch: " .. dtg)

	local kind = mem.u1[ptr + 4]
	if kind <= 3 then
		local session_id = mem.string(ptr + 5, length, true)
		local conn = connector.connections[session_id]
		if not conn then
			if not connector.allow_new_connections then
				Multiplayer.utils.LogEvent("UDP_PUNCHING", "Ignoring udppunch from unregistered connection: " .. session_id)
				return true
			end
			connector:add_connections({session_id})
			conn = connector.connections[session_id]
			Multiplayer.utils.LogEvent("UDP_PUNCHING", "Added new connection: " .. session_id)
		end
		conn.local_established = conn.local_established or kind == 1
		conn.public_established = conn.public_established or kind == 2
		conn.relay_established = conn.relay_established or kind == 3

		local response = udppunch_dtg(kind + 3)
		if kind == 1 then
			connector.udp:sendto(response, conn.local_addr, conn.local_port)
		elseif kind == 2 then
			connector.udp:sendto(response, conn.public_addr, conn.public_port)
		else
			Relay.relay_punch(Relay.binaddr(conn.public_addr, conn.public_port), response)
		end

		Multiplayer.utils.LogEvent("UDP_PUNCHING", "Connection with " .. session_id .. " established. (" .. (kind == 1 and "local" or kind == 2 and "public" or "relay") .. ")")
		events.call("ConnectionTestFinished", session_id, conn)
	elseif kind <= 6 then
		-- punch response received
		local session_id = mem.string(ptr + 5, length, true)
		local conn = connector.connections[session_id]
		if conn then
			conn.local_established = conn.local_established or kind == 4
			conn.public_established = conn.public_established or kind == 5
			conn.relay_established = conn.relay_established or kind == 6
		end
	else
		Multiplayer.utils.LogEvent("UDP_PUNCHING", "Udppunch with unknown remote kind: %s", tostring(kind))
	end

	return true
end

local function add_connections(connector, session_ids)
	local addr, port
	for _, session_id in pairs(session_ids) do
		local conn = {local_established = false, public_established = false, relay_established = false}
		local priv, pub = Multiplayer.addr_from_session_code(session_id)

		addr, port = priv:match("(%A*):(%d*)")
		conn.local_addr, conn.local_port = addr, tonumber(port)

		addr, port = pub:match("(%A*):(%d*)")
		conn.public_addr, conn.public_port = addr, tonumber(port)
		connector.connections[session_id] = conn
	end
end

local function punch_connections(connector)
	for _, conn in pairs(connector.connections) do
		if conn.local_addr ~= Multiplayer.EMPTY_ADDR then
			Multiplayer.utils.LogEvent("UDP_PUNCHING", "Udppunching " .. conn.local_addr .. ":" .. tostring(conn.local_port))
			connector.udp:sendto(udppunch_dtg(1), conn.local_addr, conn.local_port)
		end
		if conn.public_addr ~= Multiplayer.EMPTY_ADDR then
			Multiplayer.utils.LogEvent("UDP_PUNCHING", "Udppunching " .. conn.public_addr .. ":" .. tostring(conn.public_port))
			connector.udp:sendto(udppunch_dtg(2), conn.public_addr, conn.public_port)

			if not conn.relay_established and connector:have_relay_access() then
				Multiplayer.utils.LogEvent("UDP_PUNCHING", "Testing relay to " .. conn.public_addr .. ":" .. tostring(conn.public_port))
				Relay.relay_punch(Relay.binaddr(conn.public_addr, conn.public_port), udppunch_dtg(3))
			end
		end
	end
end

---- LAN

local function LAN_punch_checker(connector, dtg)
	local ptr = mem.topointer(dtg)
	local length = Multiplayer.SESSION_ID_SIZE
	if not (mem.u4[ptr] == PUNCH_COOKIE and #dtg >= length + 5) then
		return false
	end

	Multiplayer.utils.LogEvent("UDP_PUNCHING", "Got udppunch: " .. dtg)

	local kind = mem.u1[ptr + 4]
	local session_id = mem.string(ptr + 5, length, true)
	local conn = connector.connections[session_id]

	if not conn then
		if not connector.allow_new_connections then
			Multiplayer.utils.LogEvent("UDP_PUNCHING", "Ignoring udppunch from unregistered connection: " .. session_id)
			return true
		end
		connector:add_connections({session_id})
		conn = connector.connections[session_id]
		Multiplayer.utils.LogEvent("UDP_PUNCHING", "Added new connection: " .. session_id)
	end

	if kind == 1 then
		local addrs_list_size = #dtg - 5 - length
		local addrsbin = mem.string(ptr + 5 + length, addrs_list_size)

		if addrs_list_size == 8 then
			if conn.local_established and conn.approve_stamp < timeGetTime() then
				-- reapprove connection
				connector.udp:sendto(udppunch_dtg(1, ipv4bin(conn.my_addr)), conn.local_addr, conn.local_port)
				conn.approve_stamp = timeGetTime() + 2000
			end

			conn.local_established = true
			conn.local_addr = toipv4(addrsbin)
			conn.my_addr = pair_for_addr(conn.local_addr, Multiplayer.connector.all_lan_addrs)

			Multiplayer.utils.LogEvent("UDP_PUNCHING", "Connection with %s established by %s:%s. (local)", session_id, conn.local_addr, conn.local_port)
			events.call("ConnectionTestFinished", session_id, conn)
		else
			local addrs = {}
			for i = 1, #addrsbin, 8 do
				table.insert(addrs, toipv4(addrsbin:sub(i, i+7)))
			end
			for i, addr in pairs(addrs) do
				local response = udppunch_dtg(7, ipv4bin(addr) .. ipv4bin(Multiplayer.connector.all_lan_addrs))
				connector.udp:sendto(response, addr, conn.local_port)
			end
		end

	elseif kind == 7 then
		local addrs_list_size = #dtg - 5 - length
		local addrsbin = mem.string(ptr + 5 + length, addrs_list_size)
		local addrs = {}
		for i = 9, #addrsbin, 8 do
			table.insert(addrs, toipv4(addrsbin:sub(i, i+7)))
		end

		conn.local_established = true
		conn.my_addr = toipv4(addrsbin)
		conn.local_addr = pair_for_addr(conn.my_addr, addrs)
		Multiplayer.utils.LogEvent("UDP_PUNCHING", "Connection with " .. session_id .. " established. (local)")
		events.call("ConnectionTestFinished", session_id, conn)

		local response = udppunch_dtg(1, ipv4bin(conn.my_addr))
		connector.udp:sendto(response, conn.local_addr, conn.local_port)
	else
		Multiplayer.utils.LogEvent("UDP_PUNCHING", "Udppunch with unknown remote kind: %s", tostring(kind))
	end

	return true
end

local function LAN_add_connections(connector, session_ids)
	local addr, port
	for _, session_id in pairs(session_ids) do
		local priv = Multiplayer.addr_from_session_code(session_id)
		local addr, port = priv:match("(%A*):(%d*)")
		local conn = {local_established = false, local_addr = addr, local_port = port, approve_stamp = 0}

		connector.connections[session_id] = conn
	end
end

local function LAN_punch_connections(connector)
	for _, conn in pairs(connector.connections) do
		Multiplayer.utils.LogEvent("UDP_PUNCHING", "Scanning LAN on port %s.", conn.local_port)
		if conn.local_established then
			connector.udp:sendto(udppunch_dtg(1, ipv4bin(conn.my_addr)), conn.local_addr, conn.local_port)
		else
			connector.udp:sendto(udppunch_dtg(1, ipv4bin(Multiplayer.connector.all_lan_addrs)), "255.255.255.255", conn.local_port)
		end
	end
end

return {
	set_connections = set_connections,
	punch_checker = punch_checker,
	add_connections = add_connections,
	punch_connections = punch_connections,
	LAN_punch_checker = LAN_punch_checker,
	LAN_add_connections = LAN_add_connections,
	LAN_punch_connections = LAN_punch_connections
}
