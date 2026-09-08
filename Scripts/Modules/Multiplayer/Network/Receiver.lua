local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local LogEvent = Multiplayer.utils.LogEvent

local PRESERVE_INCOMING_SECONDS = 30
local RESEND_REQUESTS_LIMIT = 10
local RESEND_REQUEST_PERIOD = 2 -- seconds
local TRACK_LIMIT = 400

local Statistics = Multiplayer.require("Network/Statistics.lua")
local Binary = Multiplayer.require("Network/Binary.lua")
local IncomingPacket = Multiplayer.require("Network/IncomingPacket.lua")

local incoming_packets = {}
function Multiplayer.incoming_packets()
	return incoming_packets
end

local incoming_queues = {}
Multiplayer.debug.incoming_queues = incoming_queues

function add_incoming(client_id, hash)
	local list = incoming_queues[client_id]
	if not list then
		list = Multiplayer.utils.NewCycleList(TRACK_LIMIT)
		incoming_queues[client_id] = list
	end

	local last = list:last()
	if last then
		local packet, missed_hash
		local _,_, last_id = Binary.split_packet_hash(last)
		local sender, receiver, new_id = Binary.split_packet_hash(hash)

		if math.abs(new_id - last_id) > TRACK_LIMIT then -- either packet counter resetted, which is fine, or desynq is just beyond fixable
			LogEvent("NETWORK", "Gap in the queue of #%s detected, range is larger than %s, resetting queue.", client_id, TRACK_LIMIT)
			list = Multiplayer.utils.NewCycleList(TRACK_LIMIT)
			incoming_queues[client_id] = list
			list:add(hash)
			return
		elseif new_id - last_id > 1 then
			LogEvent("NETWORK", "Gap in the queue detected, requesting resend of packets from %s to %s from #%s", last_id, new_id, client_id)
			for i = last_id + 1, new_id - 1 do
				missed_hash = Binary.make_packet_hash(sender, receiver, i)
				list:add(missed_hash)
				packet = IncomingPacket.dummy(missed_hash)
				if not incoming_packets[missed_hash] then
					incoming_packets[missed_hash] = packet
					packet:request_missing_parts_resend(true)
				end
			end
		end
	end
	list:add(hash)
end

function events.ClientLeft(client_id)
	incoming_queues[client_id] = nil
end

local HEADER_SIZE = Binary.HEADER_SIZE
local read_metadata = Binary.read_metadata

local packet_by_code = Multiplayer.packet_by_code
local log_packets = Multiplayer.debug.log_packets
local ignore_packets = Multiplayer.debug.ignore_packets
local last_received_packet = Multiplayer.debug.last_received_packet

local last_received_packet = {bin_string = 0, handler_result = 0, metadata = 0}
local function get_last_received_packet()
	return last_received_packet
end
Multiplayer.get_last_received_packet = get_last_received_packet

-- handles packets data
local function send_response(packet, metadata, handler_result)
	local response_packet = packet_by_code[packet.response]
	local need_logging = log_packets[response_packet.name]

	if need_logging then
		LogEvent("NETWORK", "Generating bulb of %s (response to %s from client #%s)", response_packet.name, packet.name, metadata.sender_id)
	end
	local response_data = Binary.prep_response(response_packet, metadata.hash, handler_result)
	if response_data then
		Multiplayer.add_to_send_queue(metadata.sender_id, response_data) -- send bulb, using response packet metadata
	elseif need_logging then
		LogEvent("NETWORK", "Resulting bulb of %s is nil, won't send response to %s.", response_packet.name, packet.name)
	end
end
Multiplayer.send_response = send_response

local function packets_handler(connector, meta, bin_string)
	local timestamp = os.time()
	local bulb_size = meta.bulb_size

	local client = connector.clients[meta.sender_id]
	local packet = packet_by_code[meta.packet_code]
	if log_packets[packet.name] then
		LogEvent("NETWORK", "%s received: s %s, r %s, id %s, hash %s.", packet_by_code[meta.packet_code].name, meta.sender_id, meta.receiver_id, meta.packet_id, meta.hash)
	end

	if client then
		client.last_packet_timestamp = timestamp
	end

	if packet.same_map_only then
		if meta.map_id ~= Map.MapStatsIndex then
			LogEvent("NETWORK", "Skipping '%s': came from other map.", packet.name)
			return
		elseif Multiplayer.leave_map_halt then
			-- delay packet handler past map loading
			events.Once("MapLoadingDone", function() packets_handler(connector, meta, bin_string) end)
			return
		end
	end

	local bulb_data
	if packet.handler and not ignore_packets[packet.name] then
		local bin_data = packet.compress and assert(Multiplayer.decompress(bin_string)) or bin_string
		local success, ret_val = pcall(packet.handler, bin_data, meta)
		if not success then
			LogEvent("NETWORK", "Error, while handling %s:\n%s", packet.name, ret_val)
			return
		end
		bulb_data = ret_val
	end

	last_received_packet.bin_string = bin_string
	last_received_packet.handler_result = bulb_data
	last_received_packet.metadata = meta

	if meta.response_to > 0 and Multiplayer.answer_ask then
		Multiplayer.answer_ask(meta.response_to, {bin_string = bin_string, metadata = meta, handler_result = bulb_data})
	end

	-- send response, if necessary
	if packet.response and bulb_data ~= nil then
		send_response(packet, meta, bulb_data)
	end

	Statistics.CountReceivedPacket(meta.packet_code, meta.bulb_size)
	Statistics.LogStatistic()
end

-- removes processed incoming packets
local function incoming_remover()
	if not Multiplayer.in_game then
		return
	end

	local timestamp = os.time()
	local to_remove = {}
	for hash, packet in pairs(incoming_packets) do
		if timestamp - packet.timestamp > PRESERVE_INCOMING_SECONDS then
			table.insert(to_remove, hash)
		end
	end

	for _, hash in pairs(to_remove) do
		incoming_packets[hash] = nil
	end
end
Multiplayer.utils.MillisecCounter(incoming_remover, 60000)

-- sends resend requests
local function request_resends()
	local timestamp = os.time()
	local requests_made = 0

	for hash, packet in pairs(incoming_packets) do
		if packet.processed then
			-- skip
		elseif packet:all_parts() then
			packet.processed = true
			packets_handler(Multiplayer.connector, packet.metadata, packet:full_bulb())
			packet.handler_result = last_received_packet.handler_result

		elseif packet.requests_count > RESEND_REQUESTS_LIMIT then
			packet.processed = true
			LogEvent("NETWORK", "!!! Could not get requested data of message #%s %s after %s resend calls !!!", packet.metadata.hash, packet.settings.name, RESEND_REQUESTS_LIMIT)

		elseif packet.request_timestamp + RESEND_REQUEST_PERIOD < timestamp then
			packet:request_missing_parts_resend()
			requests_made = requests_made + 1
		end
	end

	return requests_made
end
Multiplayer.request_resends = request_resends
Multiplayer.utils.MillisecCounter(request_resends, RESEND_REQUEST_PERIOD * 1000)

-- emulate packet loss for debug purposes
--~ Multiplayer.debug.SkipPacketsRate = 6

-- handles received packets
local function receive_handler(connector, bin_string)
	if #bin_string < HEADER_SIZE then
		LogEvent("NETWORK", "Message '%s' discarded.", bin_string)
		return
	end

	-- packet loss emulation
--~ 	if math.random(1, Multiplayer.debug.SkipPacketsRate) == 1 then
--~ 		return
--~ 	end

	-- check packet code
	local meta = read_metadata(toptr(bin_string))
	--LogEvent("NETWORK", "%s incoming: s %s, r %s, id %s, hash %s.", packet_by_code[meta.packet_code].name, meta.sender_id, meta.receiver_id, meta.packet_id, meta.hash)

	local packet_info = packet_by_code[meta.packet_code]
	if not packet_info then
		LogEvent("NETWORK", "Got unknown packet: client id - %s, size - %s, cookie: %x", meta.sender_id, meta.bulb_size, mem.u4[toptr(bin_string)])
		return
	end

	-- process parts independently, if bin_string is sequence of messages
	local shift = meta.bulb_size + Binary.HEADER_SIZE
	local total = #bin_string
	if total > shift then
		receive_handler(connector, mstr(toptr(bin_string), shift, true))
		while total > shift do
			local slice_meta = read_metadata(toptr(bin_string) + shift)
			local size = Binary.HEADER_SIZE + slice_meta.bulb_size
			receive_handler(connector, mstr(toptr(bin_string) + shift, size, true))
			shift = shift + size
		end
		return
	end

	-- check client
	local client = connector.clients[meta.sender_id]
	if not client and not (packet_info.allow_anonymous or meta.sender_id == Multiplayer.my_id) then
		LogEvent("NETWORK", "Got packet from unknown client: client id - %s, size - %s, type - %s.", meta.sender_id, meta.bulb_size, packet_info.name)
		return
	end

	-- check reload count (whether packet is from previous game)
	if Multiplayer.reload_count ~= meta.reload_count and not packet_info.ignore_reload_count then
		LogEvent("NETWORK", "Got packet from previous game: client id - %s, size - %s, type - %s.", meta.sender_id, meta.bulb_size, packet_info.name)
		return
	end

	local packet = incoming_packets[meta.hash]
	if packet then
		packet:add_part(bin_string)
		packet.metadata = meta
	else
		packet = IncomingPacket.new(bin_string)
		if meta.packet_id > 0 then
			incoming_packets[meta.hash] = packet
			add_incoming(meta.sender_id, meta.hash)
		end
	end

	local response_to = packet.metadata.response_to
	if response_to > 0 then
		local initial = Multiplayer.outgoing_packets()[response_to]
		if initial then
			initial.response = packet
		else
			LogEvent("NETWORK", "Received packet (#%s) claimed to be response to packet that does not exist (#%s)!.", meta.hash, response_to)
			packet.processed = true -- do not process wrong packet
			return
		end
	end

	if packet.processed then
		LogEvent("NETWORK", "Already processed packet received: hash: %s, name: %s.", meta.hash, packet.settings.name)
		if packet.handler_result and packet.settings.response then
			-- find previously sent packet
			local found = false
			for _, opacket in pairs(Multiplayer.outgoing_packets()) do
				if opacket.metadata.response_to == packet.metadata.hash then
					LogEvent("NETWORK", "Resending response to already processed packet.")
					found = true
					opacket:send(true)
				end
			end
			if not found then
				LogEvent("NETWORK", "Could not find previously sent packet, rebuilding response.")
				Multiplayer.send_response(packet.settings, meta, packet.handler_result)
			end
		end
	elseif packet:all_parts() then
		packet.processed = true
		packets_handler(connector, packet.metadata, packet:full_bulb())
		packet.handler_result = last_received_packet.handler_result
	end
end
Multiplayer.receive_handler = receive_handler
