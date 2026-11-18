local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer

local network_packet = Multiplayer.require("Network/BasePacket.lua")

local Binary = Multiplayer.require("Network/Binary.lua")
local incoming_packet

incoming_packet = {

	missing_parts = function(self)
		local result = {}
		for i = 1, self.metadata.parts_total do
			if not self.parts[i] then
				table.insert(result, i)
			end
		end
		return result
	end,
	request_missing_parts_resend = function(self, request_all)
		local hash = self.metadata.hash
		
		if request_all then
			Multiplayer.utils.LogEvent("NETWORK", "Requesting resend of packet #%s", hash)
			Multiplayer.add_to_send_queue(self.metadata.sender_id, Multiplayer.packets.request_packet_parts:prep(hash))
		else
			local request = self:missing_parts()
			assert(#request > 0)
			Multiplayer.utils.LogEvent("NETWORK", "Requesting resend of packet #%s parts (%s)", hash, table.concat(request, ","))
			Multiplayer.add_to_send_queue(self.metadata.sender_id, Multiplayer.packets.request_packet_parts:prep(hash, request))
		end
		
		self.request_timestamp = os.time()
		self.requests_count = self.requests_count + 1
	end,
	all_parts = function(self)
		local result = network_packet.all_parts(self)
		if result and self.requests_count > 0 then
			Multiplayer.utils.LogEvent("NETWORK", "Packet %s received over %s requests, took %s seconds.", 
				self.settings.name, self.requests_count, self.request_timestamp - self.timestamp)
		end
		return result
	end,
	
	-- constructor
	new = function(bin_string)
		local self = network_packet.new(bin_string)
		self.timestamp = os.time()
		self.request_timestamp = self.timestamp
		self.requests_count = 0
		self.processed = false

		self.all_parts = incoming_packet.all_parts
		self.missing_parts = incoming_packet.missing_parts
		self.request_missing_parts_resend = incoming_packet.request_missing_parts_resend
		return self
	end,
	
	dummy = function(hash)
		local sender_id, receiver_id, packet_id = Binary.split_packet_hash(hash)
		local dummy_bin = Binary.metadata_bin(sender_id, receiver_id, packet_id, 1, 0, 1, 1, 0, 0, 0)
		local self = incoming_packet.new(dummy_bin)
		self.parts[1] = nil
		return self
	end
}

return incoming_packet
