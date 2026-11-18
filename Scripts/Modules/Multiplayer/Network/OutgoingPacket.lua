local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer

local Binary = Multiplayer.require("Network/Binary.lua")
local Statistics = Multiplayer.require("Network/Statistics.lua")
local network_packet = Multiplayer.require("Network/BasePacket.lua")
local outgoing_packet

local change_t = {part_id = 0, bulb_size = 0}
local function part_meta(src_meta, part_id, part_size)
	change_t.part_id = part_id
	change_t.bulb_size = part_size
	return Binary.change_metadata_bin(src_meta, change_t)
end

outgoing_packet = {
	split_hash = network_packet.split_hash,

	make_hash = network_packet.make_hash,

	send_parts = function(self, parts)
		local data = {}
		local meta = self.metadata
		local parts_total = self.metadata.parts_total
		for _, i in pairs(parts) do
			if not self.parts[i] then
				Multiplayer.utils.LogEvent("NETWORK", "Wrong or missing packet part requested: part id %s, message id %s, packet name '%s'", i, meta.packet_id, self.settings.name)
				return
			end
			table.insert(data, part_meta(meta, i, #self.parts[i]) .. self.parts[i])
		end
		if #data == 1 then
			data = data[1]
		end
		Multiplayer.add_to_send_queue(self.delivery_to, data)
	end,

	send = function(self, resend)
		local data = {}
		local meta = self.metadata
		local parts_total = self.metadata.parts_total
		for i = 1, parts_total do
			table.insert(data, part_meta(meta, i, #self.parts[i]) .. self.parts[i])
		end
		self.request_timestamp = os.time()
		self.requests_count = self.requests_count + 1
		if resend then
			Multiplayer.resend(self.delivery_to, data)
		else
			Multiplayer.add_to_send_queue(self.delivery_to, data)
		end
		Statistics.CountResentPacket(meta.packet_code, meta.bulb_size)
	end,

	send_next_part = function(self)
		self:send_parts({1})
	end,

	-- constructor
	new = function(data, reciever_client_id)
		local self
		if type(data) == 'table' then
			self = network_packet.new(data[1])
			for i = self.metadata.part_id + 1, self.metadata.parts_total do
				self:add_part(Binary.fetch_bulb(toptr(data[i])), i)
			end
		else
			self = network_packet.new(data)
		end

		self.delivery_to = reciever_client_id
		self.request_timestamp = os.time()
		self.requests_count = 0
		self.timestamp = os.time()

		self.send = outgoing_packet.send
		self.send_parts = outgoing_packet.send_parts
		self.send_next_part = outgoing_packet.send_next_part
		return self
	end
}

return outgoing_packet
