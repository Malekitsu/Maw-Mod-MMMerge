-- Based on:
-- https://github.com/tempbottle/lua_stun/blob/master/stun.lua
-- https://datatracker.ietf.org/doc/html/rfc8489
--
-- Note: STUN protocol uses big-endian byte order, thus mem.u2, mem.u4 etc mmext methods are not used here.

local LogEvent = Multiplayer.utils.LogEvent

local sbyte = function(s, o) return s:byte(o) or 0 end
local schar = string.char
local tinsert, tconcat = table.insert, table.concat

local STUN_PORT = 3478
local MAGIC_COOKIE = schar(0x21, 0x12, 0xA4, 0x42)

local STUN_SERVERS = {}
local function LoadSTUNServers()
	table.clear(STUN_SERVERS)
	local path = Multiplayer.Path .. "/STUN servers.txt"
	local list = io.open(path, "r")
	if not list then
		LogEvent("CONNECTION", "Could not open '%s' to load list of STUN servers.", path)
		return
	end

	for line in list:lines() do
		table.insert(STUN_SERVERS, line)
	end
	list:close()
end
Multiplayer.debug.STUN_SERVERS = STUN_SERVERS
Multiplayer.debug.LoadSTUNServers = LoadSTUNServers
LoadSTUNServers()

local function strxor(str1, str2)
	local chars, b1, b2, bR = {}
	for i = 1, #str1 do
		b1 = sbyte(str1, i)
		b2 = sbyte(str2, i)
		bR = bit.Xor(b1, b2)
		chars[i] = schar(bR)
	end
	return tconcat(chars)
end

local function getshort(str, offset)
	return sbyte(str, offset) * 256 + sbyte(str, offset + 1)
end

local function getip (str, offset)
	return ("%d.%d.%d.%d"):format(
		sbyte(str, offset + 0),
		sbyte(str, offset + 1),
		sbyte(str, offset + 2),
		sbyte(str, offset + 3))
end

local function new_transaction_id()
	local random = math.random
	local t = {}
	for i = 1, 12 do
		tinsert(t, schar(random(0, 255)))
	end
	return MAGIC_COOKIE .. tconcat(t, '') -- "Magic Cookie" + actual id
end

local function parse_stun_response(response, stun_header_size)
	local header = string.sub(response, 1, stun_header_size)
	local data_length = getshort(header, 3)
	local data = string.sub(response, stun_header_size + 1, stun_header_size + data_length)

	-- Get attributes, parse them and store them in array
	local offset = 1
	local attributes = {}
	while offset < data_length do
		local attr = {}
		attr.offset = offset
		attr.type = getshort(data, offset)
		attr.length = getshort(data, offset + 2)
		attr.body = string.sub(data, offset + 4, offset + 4 + attr.length)
		attr.data = attr.body

		-- attribute type is "MAPPED-ADDRESS"
		if attr.type == 1 then
			attr.descr = "MAPPED-ADDRESS"
			attr.ip_version = sbyte(attr.data, 2) * 2 + 2
			attr.port = getshort(attr.data, 3)
			attr.ip = getip(attr.data, 5)
		end

		-- attribute type is "SOURCE-ADDRESS"
		if attr.type == 4 then
			attr.descr = "SOURCE-ADDRESS"
			attr.ip_version = sbyte(attr.data, 2) * 2 + 2
			attr.port = getshort(attr.data, 3)
			attr.ip = getip(attr.data, 5)
		end

		-- attribute type is "CHANGED-ADDRESS"
		if attr.type == 5 then
			attr.descr = "CHANGED-ADDRESS"
			attr.ip_version = sbyte(attr.data, 2) * 2 + 2
			attr.port = getshort(attr.data, 3)
			attr.ip = getip(attr.data, 5)
		end

		-- attribute type is "XOR-MAPPED-ADDRESS"
		if attr.type == 0x8020 then
			attr.descr = "XOR-MAPPED-ADDRESS"
			attr.ip_version = sbyte(attr.data, 2) * 2 + 2
			local xor_port_string = string.sub(attr.data, 3, 4)
			local xor_ip_string = string.sub(attr.data, 5, 8)
			local normal_port_string = strxor(xor_port_string, MAGIC_COOKIE)
			local normal_ip_string = strxor(xor_ip_string, MAGIC_COOKIE)
			attr.port = getshort(normal_port_string, 1)
			attr.ip = getip(normal_ip_string, 1)
		end

		table.insert(attributes, attr)
		if attr.descr then
			attributes[attr.descr] = attr
		end
		offset = offset + 4 + attr.length
	end

	return attributes
end

local function binding_request(usock, stun_addr, stun_port)
	local stun_ip = socket.dns.toip(stun_addr)
	if not stun_ip then
		return nil, "cannot resolve address to ip"
	end

	stun_port = tonumber(stun_port) or STUN_PORT

	local id = new_transaction_id()
	local hdr = {
		schar(0x00, 0x01), -- message type - binding request
		schar(0x00, 0x00), -- data length
		id
	}

	local stun_req = tconcat(hdr, '')
	local stun_header_size = #stun_req
	local response

	usock:settimeout(1)
	for i = 1, 3 do
		usock:sendto(stun_req, stun_ip, stun_port)

		response = usock:receive()
		if not response then
			-- do nothing
		elseif #response >= 20 and response:sub(5, 20) == id then
			break
		elseif Multiplayer.connector then
			-- pass to main handler, because received data can be message from existing client/host
			LogEvent("CONNECTION", "Received unknown message upon interacting with STUN server, redirecting to default handler.")
			Multiplayer.connector:handle(response)
		end
	end
	usock:settimeout(0)

	if not response then
		return nil, "response timeout"
	end

	return parse_stun_response(response, stun_header_size)
end
Multiplayer.debug.stun_request = binding_request

local function binding_requests(usock, addrports)
	local results = {}
	local id = new_transaction_id()
	local hdr = {
		schar(0x00, 0x01), -- message type - binding request
		schar(0x00, 0x00), -- data length
		id
	}
	local stun_req = tconcat(hdr, '')
	local stun_header_size = #stun_req
	local conns = {}

	for _, hostname in pairs(addrports) do
		local stun_addr, stun_port = hostname:match("(.*):(%d*)")
		local stun_ip = socket.dns.toip(stun_addr)
		if stun_ip then
			conns[("%s:%s"):format(stun_ip, stun_port)] = hostname
			stun_port = tonumber(stun_port) or STUN_PORT
			usock:sendto(stun_req, stun_ip, stun_port)
			socket.sleep(0.02)
		end
	end

	local response, addr, port

	local timeout = os.time() + 8
	usock:settimeout(2)
	while true do
		response, addr, port = usock:receivefrom()
		if response and #response >= 20 and response:sub(5, 20) == id then
			local hostname = ("%s:%s"):format(addr, port)
			results[conns[hostname] or hostname] = parse_stun_response(response, stun_header_size)
		elseif not response or os.time() > timeout then
			break
		end
	end
	usock:settimeout(0)

	return results
end
Multiplayer.debug.stun_requests = binding_requests

local function have_internet_access()
	local result = false
	local connection = socket.tcp()
	connection:settimeout(4)

	for _, host in pairs{"google.com", "wikipedia.org", "example.com"} do
		LogEvent("CONNECTION", "Testing internet access to %s.", host)
		result = connection:connect(host, 80) == 1
		LogEvent("CONNECTION", "Result: %s.", result)
		if result then
			break
		end
	end
	connection:close()

	return result
end
Multiplayer.debug.have_internet_access = have_internet_access

local last_valid_server
local function STUN_public_addr(udp)
	last_valid_server = Multiplayer.GlobalData().LastSTUNServer
	if last_valid_server == nil then
		last_valid_server = "stun.connecteddata.com:3478"
		Multiplayer.GlobalData().LastSTUNServer = last_valid_server
	end

	local ip, resp, reason
	local host, port = last_valid_server:match("(.*):(%d*)")

	LogEvent("CONNECTION", "Requesting my public address from %s : %s.", host, port)
	resp = binding_request(udp, host, port)
	if resp then
		local addr = resp["XOR-MAPPED-ADDRESS"] or resp["MAPPED-ADDRESS"]
		if addr and addr.ip_version == 4 then
			LogEvent("CONNECTION", "Received my public address from %s: %s:%s.", last_valid_server, addr.ip, addr.port)
			return string.format("%s:%s", addr.ip, addr.port)
		end
	end

	local responses = binding_requests(udp, STUN_SERVERS)
	for server, resp in pairs(responses) do
		local addr = resp["XOR-MAPPED-ADDRESS"] or resp["MAPPED-ADDRESS"]
		if addr and addr.ip_version == 4 then
			LogEvent("CONNECTION", "Valid STUN server changed from %s to %s.", last_valid_server, server)
			last_valid_server = server
			Multiplayer.GlobalData().LastSTUNServer = server
			LogEvent("CONNECTION", "Received my public address from %s: %s:%s.", last_valid_server, addr.ip, addr.port)
			return string.format("%s:%s", addr.ip, addr.port)
		end
	end

	LogEvent("CONNECTION", "Could not fetch my public address from listed STUN servers!")
	return nil
end
Multiplayer.STUN_public_addr = STUN_public_addr

Multiplayer.debug.test_stun = function()
	local servers = string.split(Multiplayer.debug.STUN_SERVERS, '\n')
	return Multiplayer.debug.stun_requests(Multiplayer.connector.udp, servers)
end

Multiplayer.debug.print_received_public_addrs = function()
	local test = Multiplayer.debug.test_stun()
	for srv,v in pairs(test) do
	    for src, t in pairs(v) do
		if (src == "MAPPED-ADDRESS" or src == "XOR-MAPPED-ADDRESS") and t.ip and t.port then
		    print(srv, src, t.ip, t.port)
		end
	    end
	end
end
