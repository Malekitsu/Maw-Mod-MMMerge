local events = Multiplayer.events
local u1, u2, u4, u8, mstr = mem.u1, mem.u2, mem.u4, mem.u8, mem.string
local sendbuff = Multiplayer.utils.sendbuff
local LogEvent = Multiplayer.utils.LogEvent

local DEFAULT_RELAY, ADDR, PORT
local RELAY_COOKIE = 0xdefadefa
local RELAY_COOKIE_STR = Multiplayer.utils.num_to_hexstr(RELAY_COOKIE)

local function set_relay_addrport(addr, port)
	DEFAULT_RELAY = string.format("%s:%s", addr, port)
	ADDR, PORT = addr, tonumber(port)
end

local RelayServers = {}
local function LoadRelays()
	table.clear(RelayServers)

	local path = Multiplayer.Path .. "/Lobby servers.txt"
	local list = io.open(path, "r")
	if not list then
		LogEvent("CONNECTION", "Could not open '%s' to load list of Lobby/Relay servers.", path)
		return
	end

	for line in list:lines() do
		local words = string.split(line, "\t")
		if words[2] == "1" then
			RelayServers[words[1]] = {
				Name = words[3],
				Relay = false,
				Hosts = {},
			}

			if not DEFAULT_RELAY then
				set_relay_addrport(words[1]:match("(%A*):(%d*)"))
			end
		end
	end
end
LoadRelays()

local function binaddr(addrport, inport)
	local addr, port

	if not addrport then
		local addrport = Multiplayer.myaddr()
		addr, port = addrport:match("(%A*):(%d*)")
	elseif not inport then
		addr, port = addrport:match("(%A*):(%d*)")
	else
		addr, port = addrport, inport
	end

	local a,b,c,d = addr:match("(%d*).(%d*).(%d*).(%d*)")
	u1[sendbuff] = tonumber(d)
	u1[sendbuff+1] = tonumber(c)
	u1[sendbuff+2] = tonumber(b)
	u1[sendbuff+3] = tonumber(a)
	u2[sendbuff + 4] = tonumber(port)
	return mstr(sendbuff, 6, true)
end

local my_last_binaddr
function events.MultiplayerStarted()
	my_last_binaddr = nil
end

local function my_binaddr()
	if not my_last_binaddr then
		my_last_binaddr = binaddr()
	end
	return my_last_binaddr
end

local function have_relay_access(addrport, once, cocall, timeout)
	if not once then
		return have_relay_access(addrport, true)
			or have_relay_access(addrport, true)
			or have_relay_access(addrport, true)
	end

	local addrport = addrport or DEFAULT_RELAY
	local addr, port = addrport:match("(%A*):(%d*)")
	local udp = Multiplayer.connector.udp

	local success = false
	local function token_received()
		udp:sendto(RELAY_COOKIE_STR .. "\1" .. binaddr(), addr, port)
		udp:settimeout(0.4)
		local data = udp:receive()
		if data then
			success = u4[mem.topointer(data)] == RELAY_COOKIE
			if not success then
				Multiplayer.connector:handle(data)
			end
		end
		udp:settimeout(0)
		return success
	end

	local endtest = timeGetTime() + (timeout or 2000)
	while not token_received() and timeGetTime() < endtest do
		if cocall then
			coroutine.yield()
		end
	end
	return success
end

function events.MultiplayerConnectionTypeChanged()
	if not Multiplayer.internet_connection then
		return
	end

	local co = coroutine.create(function()
		for addr, server in pairs(RelayServers) do
			server.Relay = have_relay_access(addr, true, true, 4000)
		end
	end)
	Multiplayer.utils.CoMillisecCounter(co, 200)
end

local function test_relay(echo, addrport, timeout)
	local addrport = addrport or DEFAULT_RELAY
	local addr, port = addrport:match("(%A*):(%d*)")
	local udp = Multiplayer.connector.udp

	local dtg = RELAY_COOKIE_STR .. "\3" .. my_binaddr() .. my_binaddr() .. echo

	udp:sendto(dtg, addr, port)
	udp:settimeout(timeout or 0.6)
	local data = udp:receive()
	udp:settimeout(0)

	if data then
		return data
	end
end

-- Relay.test_relay2("Message must be larger than 21 bytes, but shorter than 512 bytes")
local function test_relay2(echo, count, addrport, timeout)
	local addrport = addrport or DEFAULT_RELAY
	local addr, port = addrport:match("(%A*):(%d*)")
	local udp = Multiplayer.connector.udp
	local dtg

	count = count or 3
	for i = 1, count do
		dtg = RELAY_COOKIE_STR .. "\3" .. my_binaddr() .. my_binaddr() .. echo .. " " .. tostring(i)
		udp:sendto(dtg, addr, port)
	end

	udp:settimeout(timeout or 0.6)
	local responses = {}
	local data = udp:receive()
	while data ~= nil do
		table.insert(responses, data)
		data = udp:receive()
	end
	udp:settimeout(0)

	return responses
end

local function myaddr(udp, timeout)
	local udp = udp or Multiplayer.connector.udp
	local dtg = RELAY_COOKIE_STR .. "\4"

	local success = false
	local addrport = Multiplayer.EMPTY_ADDRPORT
	local function token_received()
		udp:sendto(dtg, ADDR, PORT)
		udp:settimeout(timeout or 0.4)
		local data = udp:receive()
		if data then
			local ptr = mem.topointer(data)
			success = u4[ptr] == RELAY_COOKIE and u1[ptr + 4] == 4
			if success then
				addrport = string.format("%s.%s.%s.%s:%s", u1[ptr+10], u1[ptr+9], u1[ptr+8], u1[ptr+7], u2[ptr+5])
			elseif Multiplayer.connector then
				Multiplayer.connector:handle(data)
			end
		end
		udp:settimeout(0)
		return success
	end

	LogEvent("CONNECTION", "Requesting my public address from relay server %s:%s.", ADDR, PORT)
	local endtest = timeGetTime() + 4000
	while not token_received() and timeGetTime() < endtest do end
	LogEvent("CONNECTION", "Result: %s, %s", success, addrport)

	return success, addrport
end

local function send_log(bin)
	local conn = socket.tcp()
	local success, err = conn:bind(Multiplayer.connector.addr, Multiplayer.connector.port)
	if err then
		LogEvent("CONNECTION", "Could not bind tcp socket to %s:%s for sending log file: %s", Multiplayer.connector.addr, Multiplayer.connector.port, err)
		return
	end
	conn:settimeout(4)

	LogEvent("CONNECTION", "Connecting %s:%s via tcp to send log file.", ADDR, PORT)
	local connected = conn:connect(ADDR, PORT)
	if connected ~= 1 then
		LogEvent("CONNECTION", "Could not connect log server.")
		return
	end

	local request =
	"POST /NewLog HTTP/1.1\r\n" ..
	"Host: %s:%s\r\n" ..
	"Connection: close\r\n" ..
	"Accept: text/plain\r\n" ..
	"Content-Type: text/plain\r\n" ..
	"Content-Length: %d\r\n" ..
	"\r\n"

	local a,b,c = conn:send(request:format(ADDR, PORT, #bin, Multiplayer.myaddr()) .. bin)
	LogEvent("CONNECTION", "Log file sent. Total size - %s, send method return: %s, %s, %s", #bin, a, b, c)

	local response = conn:receive('*a')
	conn:close()
	if response then
		LogEvent("CONNECTION", "Log server response: %s", response)
		return
	end

	LogEvent("CONNECTION", "Log file sent successfully.")
end


local function relay_punch(addrportbin, data)
	local dtg = RELAY_COOKIE_STR .. "\2" .. my_binaddr() .. addrportbin .. data
	return Multiplayer.connector.udp:sendto(dtg, ADDR, PORT)
end

local function relay_packet(addrportbin, data)
	local dtg = RELAY_COOKIE_STR .. "\3" .. my_binaddr() .. addrportbin .. data
	return Multiplayer.connector.udp:sendto(dtg, ADDR, PORT)
end

return {
	set_relay_addrport = set_relay_addrport,
	have_relay_access = have_relay_access,
	test_relay = test_relay,
	test_relay2 = test_relay2,
	binaddr = binaddr,
	myaddr = myaddr,
	relay_punch = relay_punch,
	relay_packet = relay_packet,
	send_log = send_log,

	RelayServers = RelayServers,
	LoadRelays = LoadRelays
}
