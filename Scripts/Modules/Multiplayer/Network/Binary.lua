local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local sendbuff = Multiplayer.utils.sendbuff
local num_to_hexstr = Multiplayer.utils.num_to_hexstr

local Compressor = Multiplayer.require("Network/MMCompressor.lua")

Multiplayer.compress = Compressor.compress
Multiplayer.decompress = Compressor.decompress

local HEADER_SIZE = 22
local MAX_PACKET_SIZE = 512 - HEADER_SIZE

---- Packet metadata

local metadata_offsets = {
	["sender_id"] = {0, u1},
	["receiver_id"] = {1, u1},
	["packet_id"] = {2, u2},
	["packet_code"] = {4, u2},
	["part_id"] = {6, u2},
	["parts_total"] = {8, u2},
	["response_to"] = {10, u4},
	["map_id"] = {14, u2},
	["reload_count"] = {16, u2},
	["bulb_size"] = {18, u4},
}

local function metadata_bin(sender_id, receiver_id, packet_id, packet_code, bulb_size, part_id, parts_total, map_id, response_to, reload_count)
	u1[sendbuff] = sender_id
	u1[sendbuff+1] = receiver_id
	u2[sendbuff+2] = packet_id
	u2[sendbuff+4] = packet_code
	u2[sendbuff+6] = part_id
	u2[sendbuff+8] = parts_total
	u4[sendbuff+10] = response_to or 0
	u2[sendbuff+14] = map_id or Map.MapStatsIndex
	u2[sendbuff+16] = reload_count or Multiplayer.reload_count
	u4[sendbuff+18] = bulb_size
	return mstr(sendbuff, HEADER_SIZE, true)
end

local function read_metadata(bin_data)
	return {
		hash			= u4[bin_data],
		sender_id		= u1[bin_data],
		receiver_id	= u1[bin_data+1],
		packet_id		= u2[bin_data+2],
		packet_code	= u2[bin_data+4],
		part_id		= u2[bin_data+6],
		parts_total	= u2[bin_data+8],
		response_to	= u4[bin_data+10],
		map_id		= u2[bin_data+14],
		reload_count	= u2[bin_data+16],
		bulb_size		= u4[bin_data+18],
	}
end

local function change_metadata_bin(src, dict)
	for k, m in pairs(metadata_offsets) do
		m[2][sendbuff + m[1]] = dict[k] or src[k]
	end
	return mstr(sendbuff, HEADER_SIZE, true)
end

---- Packet hash

local function make_packet_hash(sender_id, receiver_id, packet_id)
	return sender_id + bit.lshift(receiver_id, 8) + bit.lshift(packet_id, 16)
end

local function split_packet_hash(hash)
	local sender_id = bit.And(hash, 0xFF)
	local receiver_id = bit.And(bit.rshift(hash, 8), 0xFF)
	local packet_id = bit.rshift(hash, 16)

	return sender_id, receiver_id, packet_id
end

---- Packets numeration

local packets_counters = {}
Multiplayer.debug.packets_counters = packets_counters

function events.ClientJoin(client)
	packets_counters[client.id] = 0
end

function events.ClientLeft(client_id)
	packets_counters[client_id] = nil
end

local function next_message_id(receiver_id)
	packets_counters[receiver_id] = (packets_counters[receiver_id] or 0) + 1
	local id = packets_counters[receiver_id]
	if id > 65535 then
		packets_counters[receiver_id] = 1
		return 1
	end
	return id
end

-----

local function fetch_bulb(bin_data)
	return mstr(bin_data + HEADER_SIZE, u4[bin_data + HEADER_SIZE - 4], true)
end

local function split_data(bin_string, part_size)
	part_size = part_size or MAX_PACKET_SIZE

	local parts_count = math.ceil(#bin_string / part_size)
	local parts = {}
	for i = 0, parts_count-1 do
		table.insert(parts, bin_string:sub(i*part_size + 1, i*part_size + part_size))
	end
	return parts
end

local function prep_response(packet, response_to, ...)
	local bin_string = packet.bulb(...)
	if not bin_string then
		return nil
	end

	if packet.compress then
		bin_string = assert(Multiplayer.compress(bin_string))
	end

	local N = packet.check_delivery and 0 or 0xFF
	local result, metadata
	if #bin_string <= MAX_PACKET_SIZE then
		metadata = metadata_bin(N, N, 0, packet.code, #bin_string, 1, 1, Map.MapStatsIndex, response_to)
		result = metadata .. bin_string
	else
		local parts = split_data(bin_string)
		for i, v in ipairs(parts) do
			metadata = metadata_bin(N, N, 0, packet.code, #v, i, #parts, Map.MapStatsIndex, response_to)
			parts[i] = metadata .. v
		end
		result = parts
	end
	return result, bin_string, metadata
end

local function prep_packet(packet, ...)
	return prep_response(packet, 0, ...)
end

local function set_new_hash(data, receiver_id)
	local sample
	if type(data) == 'table' then
		assert(data[1])
		sample = data[1]
	else
		sample = data
	end

	local hash
	if u4[toptr(sample)] == 0x0000FFFF then
		hash = make_packet_hash(Multiplayer.my_id, receiver_id, 0) -- do not enumerate packets, that do not require guranteed delivery
	else
		hash = make_packet_hash(Multiplayer.my_id, receiver_id, next_message_id(receiver_id))
	end
	hash = num_to_hexstr(hash, 4)

	local result
	if type(data) == 'table' then
		result = {}
		for k, v in pairs(data) do
			result[k] = hash .. v:sub(5)
		end
	else
		result = hash .. data:sub(5)
	end
	return result
end

local function fill_hash(bin_string, receiver_id)
	local ptr = toptr(bin_string)
	if u4[ptr] == 0 then
		u4[ptr] = make_packet_hash(Multiplayer.my_id, receiver_id, next_message_id(receiver_id))
	elseif u4[ptr] == 0x0000FFFF then
		u4[ptr] = make_packet_hash(Multiplayer.my_id, receiver_id, 0) -- do not enumerate packets, that do not require guranteed delivery
	end
end

local function fill_parts_hash(parts, receiver_id)
	local hash, sample = next(parts)
	assert(sample)

	local ptr = toptr(sample)
	if u2[ptr + 2] ~= 0 then
		return
	end

	hash = make_packet_hash(Multiplayer.my_id, receiver_id, next_message_id(receiver_id))
	for k, v in pairs(parts) do
		u4[toptr(v)] = hash
	end
end

return {
	HEADER_SIZE = HEADER_SIZE,
	MAX_PACKET_SIZE = MAX_PACKET_SIZE,
	make_packet_hash = make_packet_hash,
	split_packet_hash = split_packet_hash,
	metadata_bin = metadata_bin,
	read_metadata = read_metadata,
	change_metadata_bin = change_metadata_bin,
	fetch_bulb = fetch_bulb,
	prep_response = prep_response,
	prep_packet = prep_packet,
	set_new_hash = set_new_hash,
	fill_hash = fill_hash,
	fill_parts_hash = fill_parts_hash,
	split_data = split_data
}
