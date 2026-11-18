Multiplayer.debug.LogStatisticPeriod = 0 -- seconds, if 0 - don't log.

local send_calls, send_statistic, receive_statistic, resend_statistic

local function Init()
	send_calls = {
		timestamp = os.time(),
		this_sec = 0,
		per_sec_avg = 0,
		per_sec_max = 0,
		packets_sent = 0,
		total = 0}

	send_statistic = {
		timestamp = os.time(),
		this_sec = 0,
		per_sec_avg = 0,
		per_sec_max = 0,
		total_by_type = {},
		size_by_type = {}}

	receive_statistic = {
		timestamp = os.time(),
		this_sec = 0,
		per_sec_avg = 0,
		per_sec_max = 0,
		total_by_type = {},
		size_by_type = {}}

	resend_statistic = {
		timestamp = os.time(),
		this_sec = 0,
		per_sec_avg = 0,
		per_sec_max = 0,
		total_by_type = {},
		size_by_type = {}}
end

local function CountSendCalls(packets_sent)
	local timestamp = os.time()
	local t = send_calls
	if t.timestamp ~= timestamp then
		t.per_sec_avg = (t.per_sec_avg + t.this_sec) / 2
		t.per_sec_max = math.max(t.this_sec, t.per_sec_max)
		t.timestamp = timestamp
		t.this_sec = 0
	end
	t.packets_sent = t.packets_sent + packets_sent
	t.this_sec = t.this_sec + 1
	t.total = t.total + 1
end

local function SendCallsThisSecond()
	local timestamp = os.time()
	local t = send_calls
	if t.timestamp ~= timestamp then
		t.per_sec_avg = (t.per_sec_avg + t.this_sec) / 2
		t.per_sec_max = math.max(t.this_sec, t.per_sec_max)
		t.timestamp = timestamp
		t.this_sec = 0
	end
	return t.this_sec
end

local function CountPacket(t, packet_code, size)
	local timestamp = os.time()
	if t.timestamp ~= timestamp then
		t.per_sec_avg = (t.per_sec_avg + t.this_sec) / 2
		t.per_sec_max = math.max(t.this_sec, t.per_sec_max)
		t.timestamp = timestamp
		t.this_sec = 0
	end
	t.this_sec = t.this_sec + 1
	t.total_by_type[packet_code] = (t.total_by_type[packet_code] or 0) + 1
	t.size_by_type[packet_code] = (t.size_by_type[packet_code] or 0) + size
end

local function CountSentPacket(packet_code, size)
	CountPacket(send_statistic, packet_code, size)
end

local function CountResentPacket(packet_code, size)
	CountPacket(resend_statistic, packet_code, size)
end

local function CountReceivedPacket(packet_code, size)
	CountPacket(receive_statistic, packet_code, size)
end

local LastLogTimeStamp = 0
local function LogStatistic(Force)
	if not Force then
		local timestamp = os.time()
		local period = Multiplayer.debug.LogStatisticPeriod

		if (period <= 0) or (timestamp - LastLogTimeStamp < period) then
			return
		end

		LastLogTimeStamp = timestamp
	end

	local lines = {"\n\nVERSION: " .. Multiplayer.VERSION}

	table.insert(lines, "Network statistic:")
	table.insert(lines, ("Send calls: packet per call: %.2f; this second: %s; total: %s; avg: %.2f; max: %.2f;"):format(
		send_calls.packets_sent / send_calls.total,
		send_calls.this_sec, send_calls.total, send_calls.per_sec_avg, send_calls.per_sec_max))

	table.insert(lines, "Packets sent/received:")
	table.insert(lines, ("This second: %s / %s"):format(send_statistic.this_sec, receive_statistic.this_sec))
	table.insert(lines, ("Avg per second: %.2f / %.2f"):format(send_statistic.per_sec_avg, receive_statistic.per_sec_avg))
	table.insert(lines, ("Max per second: %s / %s"):format(send_statistic.per_sec_max, receive_statistic.per_sec_max))

	table.insert(lines, "Total  sent amount / size // received amount / size:")

	local packets_stats = {}
	for code, packet in pairs(Multiplayer.packet_by_code) do
		table.insert(packets_stats, string.format("%s (%s)\t\t\t %s / %s // %s / %s // %s / %s",
			packet.name, code,
			send_statistic.total_by_type[code] or 0,
			send_statistic.size_by_type[code] or 0,
			receive_statistic.total_by_type[code] or 0,
			receive_statistic.size_by_type[code] or 0,
			resend_statistic.total_by_type[code] or 0,
			resend_statistic.size_by_type[code] or 0
			))
	end

	table.sort(packets_stats)
	table.insert(lines, table.concat(packets_stats, "\n"))
	Multiplayer.utils.LogEvent("NETWORK", table.concat(lines, "\n"))
end

function events.MultiplayerStarted()
	Init()
end

function events.MultiplayerStopped()
	LogStatistic(true)
end

local function LogQueueSizes()
	local function count(q)
		local n = 0
		for _, __ in pairs(q) do
			n = n + 1
		end
		return n
	end
	Multiplayer.utils.LogEvent("INTERNAL", "Queue sizes: incoming - %s, outgoing - %s, approval - %s",
		count(Multiplayer.incoming_packets()),
		count(Multiplayer.outgoing_packets()),
		count(Multiplayer.approval_queue()))
end
--Multiplayer.utils.MillisecCounter(LogQueueSizes, 10000)

return {
	LogStatistic = LogStatistic,
	CountSentPacket = CountSentPacket,
	CountReceivedPacket = CountReceivedPacket,
	CountSendCalls = CountSendCalls,
	CountResentPacket = CountResentPacket,
	SendCallsThisSecond = SendCallsThisSecond,
}
