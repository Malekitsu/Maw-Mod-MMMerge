local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local LogEvent = Multiplayer.utils.LogEvent

local packet_by_code = Multiplayer.packet_by_code
local log_packets = Multiplayer.debug.log_packets
local network_cycle = Multiplayer.network_cycle

local PRESERVE_OUTGOING_SECONDS = 30
local RESEND_PERIOD = 2 -- seconds
local MAX_RESENDS = 8
local MAX_SENDCALLS_PER_SEC = 96

local Statistics = Multiplayer.require("Network/Statistics.lua")
local Binary = Multiplayer.require("Network/Binary.lua")
local OutgoingPacket = Multiplayer.require("Network/OutgoingPacket.lua")

local read_metadata = Binary.read_metadata

local send_queue = {}
Multiplayer.send_queue = send_queue

local outgoing_packets = {}
function Multiplayer.outgoing_packets()
	return outgoing_packets
end

local function response_received(hash)
	local packet = Multiplayer.outgoing_packets()[hash]
	local response = packet and packet.response
	if response and response:all_parts() then
		return response
	end
	return false
end

local function wait_responses(hashes, timeout)
	assert(hashes)
	LogEvent("NETWORK", "Waiting responses for messages (hashes): %s", table.concat(hashes, ", "))

	local endtime = os.time() + timeout
	local responses = {}

	repeat
		if not Multiplayer.connector then
			-- Multiplayer stopped, in progress
			return responses
		end
	
		network_cycle()
		local all = true
		for i, hash in pairs(hashes) do
			if not responses[i] then
				responses[i] = response_received(hash)
				all = responses[i] and all
			end
		end
		if all then
			break
		end
		socket.sleep(0.02)

	until os.time() > endtime

	local logstr = {}
	for i, hash in pairs(hashes) do
		table.insert(logstr, ("%s - %s"):format(hash, responses[i]))
	end

	LogEvent("NETWORK", "Responses received: %s", table.concat(logstr, ", "))
	return responses
end
Multiplayer.wait_responses = wait_responses

local function wait_response(hash, timeout)
	assert(hash)
	LogEvent("NETWORK", "Waiting response for message %s", hash)

	local endtime = os.time() + timeout
	local response

	repeat
		network_cycle()
		response = response_received(hash)
		if response then
			break
		end
		socket.sleep(0.02)

	until os.time() > endtime

	LogEvent("NETWORK", "Got response for message %s: %s", hash, response)
	return response
end
Multiplayer.wait_response = wait_response

-- several questions out, first acceptable answer back; nil when nobody
-- answered in time or every answer was refused by `accept`
local function wait_first_response(hashes, timeout, accept)
	local endtime = os.time() + timeout
	local pending = {}
	for _, hash in pairs(hashes) do
		pending[hash] = true
	end

	repeat
		if not Multiplayer.connector then
			return nil
		end

		network_cycle()
		for hash in pairs(pending) do
			local response = response_received(hash)
			if response then
				pending[hash] = nil
				local result = {bin_string = response:full_bulb(), metadata = response.metadata, handler_result = response.handler_result}
				if not accept or accept(result) then
					return result
				end
			end
		end
		if next(pending) == nil then
			return nil
		end
		socket.sleep(0.02)

	until os.time() > endtime
	return nil
end
Multiplayer.wait_first_response = wait_first_response

local function send_wait_response(client_id, packet, timeout, ...)
	assert(packet.check_delivery and packet.response, "Cannot wait response for packet without 'check_delivery' flag and 'response' field set.")

	local result = nil
	local hash = Multiplayer.add_to_send_queue(client_id, packet:prep(...))
	local response = wait_response(hash, timeout)
	if response then
		result = {bin_string = response:full_bulb(), metadata = response.metadata, handler_result = response.handler_result}
	end
	return result ~= nil, result
end
Multiplayer.send_wait_response = send_wait_response

-- the non-blocking form: on_reply(true, {bin_string, metadata, handler_result})
-- when the answer is processed, on_reply(false) when the timeout runs out
local pending_asks = {}

local function ask(client_id, packet, timeout, on_reply, ...)
	assert(packet.check_delivery and packet.response, "Cannot ask with a packet without 'check_delivery' flag and 'response' field set.")
	local data = packet:prep(...)
	if not data then
		return nil
	end
	local hash = Multiplayer.add_to_send_queue(client_id, data)
	pending_asks[hash] = {on_reply = on_reply, deadline = os.time() + (timeout or 4)}
	return hash
end
Multiplayer.ask = ask

-- one question to every client passing the condition; on_done(results) with
-- results[client_id] = answer or false, once all answered or timed out
local function ask_all(condition, packet, timeout, on_done, ...)
	local results, waiting = {}, 0
	for client_id, client in pairs(Multiplayer.connector.clients) do
		if client.in_game and (not condition or condition(client, client_id)) then
			waiting = waiting + 1
			local hash = ask(client_id, packet, timeout, function(ok, response)
				results[client_id] = ok and response or false
				waiting = waiting - 1
				if waiting == 0 then
					on_done(results)
				end
			end, ...)
			if not hash then
				waiting = waiting - 1
			end
		end
	end
	if waiting == 0 then
		on_done(results)
	end
end
Multiplayer.ask_all = ask_all

-- called by the receiver once a response packet has been handled
local function answer_ask(hash, response)
	local pending = pending_asks[hash]
	if not pending then
		return
	end
	pending_asks[hash] = nil
	pending.on_reply(true, response)
end
Multiplayer.answer_ask = answer_ask

local function expire_asks()
	local now = os.time()
	for hash, pending in pairs(pending_asks) do
		if now > pending.deadline then
			pending_asks[hash] = nil
			pending.on_reply(false)
		end
	end
end
Multiplayer.utils.MillisecCounter(expire_asks, 500)

Multiplayer.events.MultiplayerStopped = function()
	table.clear(pending_asks)
end

-- resends outgoing packets if necessary
local function response_requester()
	local to_remove = {}
	for hash, packet in pairs(outgoing_packets) do
		if packet.settings.check_delivery
			and packet.settings.response
			and packet.response == nil
			and os.time() - packet.request_timestamp > RESEND_PERIOD then

			if packet.requests_count < MAX_RESENDS then
				packet:send()
			else
				LogEvent("NETWORK", "Could not receive response to packet '%s' #%s after %s resends.", packet.settings.name, hash, packet.requests_count)
				table.insert(to_remove, hash)
			end
		end
	end

	for _, hash in pairs(to_remove) do
		outgoing_packets[hash] = nil
	end
end
Multiplayer.utils.MillisecCounter(response_requester, RESEND_PERIOD * 2000)

-- removes aged outgoing packets
local function outgoing_remover()
	if not Multiplayer.in_game then
		return
	end

	local timestamp = os.time()
	local to_remove = {}
	for hash, packet in pairs(outgoing_packets) do
		if timestamp - packet.timestamp > PRESERVE_OUTGOING_SECONDS then
			table.insert(to_remove, hash)
		end
	end

	for _, hash in pairs(to_remove) do
		outgoing_packets[hash] = nil
	end
end
Multiplayer.utils.MillisecCounter(outgoing_remover, 60000)

local function log_packet(meta, receiver_id)
	local packet = packet_by_code[meta.packet_code]
	if log_packets[packet.name] then
		LogEvent("NETWORK", "%s added to queue: s %s, r %s, id %s, hash %s.", packet_by_code[meta.packet_code].name, meta.sender_id, meta.receiver_id, meta.packet_id, meta.hash)
	end
	Statistics.CountSentPacket(meta.packet_code, meta.bulb_size)
end

local function _add_to_send_queue(client_id, data, fill_hash)
	send_queue[client_id] = send_queue[client_id] or {}
	local queue = send_queue[client_id]
	
	local sample
	local tinsert = table.insert
	if not data then
		LogEvent("NETWORK", "add_to_send_queue call with empty data!")
		return
	elseif type(data) == 'table' then
		sample = next(data)
		if not sample then
			LogEvent("NETWORK", "add_to_send_queue call with empty data!")
			return
		end
		
		if fill_hash then
			Binary.fill_parts_hash(data, client_id)
		end
		
		sample = data[sample]
		for _, v in pairs(data) do
			tinsert(queue, v)
		end
	else
		if fill_hash then
			Binary.fill_hash(data, client_id)
		end
		tinsert(queue, data)
		sample = data
	end
	return read_metadata(toptr(sample))
end

local function add_to_send_queue(client_id, data)
	local meta = _add_to_send_queue(client_id, data, true)
	log_packet(meta, client_id)

	if not outgoing_packets[meta.hash] then
		outgoing_packets[meta.hash] = OutgoingPacket.new(data, client_id)
	end
	return meta.hash
end
Multiplayer.add_to_send_queue = add_to_send_queue

local function add_to_send_queue_hashed(client_id, data)
	local meta = _add_to_send_queue(client_id, data, false)
	log_packet(meta, client_id)

	if not outgoing_packets[meta.hash] then
		outgoing_packets[meta.hash] = OutgoingPacket.new(data, client_id)
	end
	return meta.hash
end

local function resend(client_id, data)
	if not data then
		LogEvent("NETWORK", "resend call with empty data!")
		return
	end

	send_queue[client_id] = send_queue[client_id] or {}
	local queue = send_queue[client_id]
	local tinsert = table.insert

	if type(data) == 'table' then
		for _, v in pairs(data) do
			tinsert(queue, v)
		end
	else
		tinsert(queue, data)
	end
end
Multiplayer.resend = resend

local function send_chunks(client, slices)
	local function send(chunk)
		local bin = table.concat(chunk, '')
		--LogEvent("NETWORK", "sending chunk of %s packets, total size: %s bytes", #chunk, #bin)
		Multiplayer.connector:sendto(client, bin)
		Statistics.CountSendCalls(#chunk)
	end

	local max_size = Binary.MAX_PACKET_SIZE + Binary.HEADER_SIZE
	local cur_size = 0
	local chunk = {}
	for _, slice in pairs(slices) do
		if cur_size + #slice > max_size then
			if cur_size == 0 then
				LogEvent("CONNECTION", "Size of the slice exceeds maximum allowed packet size (%s : %s)! Sending it anyway.", #slice, max_size)
				Multiplayer.connector:sendto(client, slice)
				Statistics.CountSendCalls(1)
			else
				send(chunk)
				table.clear(chunk)
				table.insert(chunk, slice)
				cur_size = #slice
			end
		else
			table.insert(chunk, slice)
			cur_size = cur_size + #slice
		end
	end

	if cur_size > 0 then
		send(chunk)
	end
end

local function sendall(amount)
	amount = amount or 64

	if Statistics.SendCallsThisSecond() >= MAX_SENDCALLS_PER_SEC then
		return -- avoid network overheat
	end

	local send_queue = Multiplayer.send_queue
	local clients = Multiplayer.connector.clients
	local client
	for client_id, messages in pairs(send_queue) do
		client = clients[client_id]
		if client then
			local sent = {}
			local to_send = {}
			for k, message in pairs(messages) do
				table.insert(sent, k)
				table.insert(to_send, message)
				amount = amount - 1
				if amount <= 0 then break end
			end
			for _, k in pairs(sent) do
				messages[k] = nil
			end
			send_chunks(client, to_send)

			if amount <= 0 then return end
		elseif client_id == Multiplayer.my_id then
			local count = 0
			for k, message in pairs(messages) do
				Multiplayer.connector:handle(message)
				count = count + 1
			end
			table.clear(messages)
			if count > 0 then
				LogEvent("NETWORK", "%s packets sent to myself.", count)
			end
		else
			LogEvent("NETWORK", "Attempt to send message to non-existing client #%s!", client_id)
			send_queue[client_id] = nil
			return
		end
	end
end
Multiplayer.sendall = sendall

local function broadcast(data, condition)
	if not data then
		return
	end

	local hashes = {}
	for client_id, client in pairs(Multiplayer.connector.clients) do
		if client.in_game and (not condition or condition(client, client_id)) then
			table.insert(hashes, add_to_send_queue_hashed(client_id, Binary.set_new_hash(data, client_id)))
		end
	end
	return hashes
end
Multiplayer.broadcast = broadcast

local function broadcast_keep_hash(packet, condition, hash_acceptor, ...)
	for client_id, client in pairs(Multiplayer.connector.clients) do
		if client.in_game and (not condition or condition(client, client_id)) then
			table.insert(hash_acceptor, add_to_send_queue(client_id, packet:prep(...)))
		end
	end
end
Multiplayer.broadcast_keep_hash = broadcast_keep_hash
