local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer

local Binary = Multiplayer.require("Network/Binary.lua")
local read_metadata = Binary.read_metadata
local change_meta = Binary.change_metadata_bin
local fetch_bulb = Binary.fetch_bulb

local network_packet

network_packet = {
	split_hash = Binary.split_packet_hash,
	make_hash = Binary.make_packet_hash,

	hash = function(self)
		return self.metadata.hash
	end,

	all_parts = function(self)
		for i = 1, self.metadata.parts_total do
			if not self.parts[i] then
				return false
			end
		end
		return true
	end,

	full_bulb = function(self)
		return table.concat(self.parts, '')
	end,

	full_bin = function(self)
		local bulb = self:full_bulb()
		local meta_bin = change_meta(self.metadata, {bulb_size = #bulb, part_id = 1, parts_total = 1})
		return meta_bin .. bulb
	end,

	single_part = function(self)
		local part_id = self.metadata.part_id
		return self.parts[part_id], part_id
	end,

	single_bin = function(self)
		local meta = self.metadata
		return change_meta(meta, {bulb_size = #self.parts[meta.part_id]}) .. self.parts[meta.part_id]
	end,

	add_part = function(self, bin_string, part_id)
		if part_id then
			self.parts[part_id] = bin_string
		else
			local meta = read_metadata(toptr(bin_string))
			self.parts[meta.part_id] = fetch_bulb(toptr(bin_string))
		end
	end,

	-- constructor
	new = function(bin_string)
		local bin_data = toptr(bin_string)
		local meta = read_metadata(bin_data)
		local self = {
			settings = Multiplayer.packet_by_code[meta.packet_code],
			metadata = meta,
			parts = {[meta.part_id] = fetch_bulb(bin_data)},

			hash = network_packet.hash,
			single_part = network_packet.single_part,
			single_bin = network_packet.single_bin,
			all_parts = network_packet.all_parts,
			full_bulb = network_packet.full_bulb,
			full_bin = network_packet.full_bin,
			add_part = network_packet.add_part,
		}
		return self
	end
}

return network_packet
