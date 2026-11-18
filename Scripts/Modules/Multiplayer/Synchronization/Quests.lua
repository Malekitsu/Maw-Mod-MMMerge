local events = Multiplayer.events
local u1, toptr, mcopy = mem.u1, mem.topointer, mem.copy
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
local mmt_dump = Multiplayer.utils.mmt_dump

local last_qbit_state = mmt_dump(Party.QBits)
local last_awards_state = mmt_dump(Party[0].Awards)

local service_qbits = {} -- qbits that should not be synchronized
for i = 181, 185 do -- town portal
	service_qbits[i] = true
end
for i = 400, 449 do -- roster bits
	service_qbits[i] = true
end
for _, TPSet in pairs(TownPortalControls.Sets) do
	service_qbits[TPSet.SwitchBit] = true
	for _, Dest in ipairs(TPSet) do
		service_qbits[Dest.QBI] = true
	end
end
Multiplayer.debug.service_qbits = service_qbits

local function bit_array_diff(old_bin, new_bin)
	local diff = {}
	local ptr_old, ptr_new = toptr(old_bin), toptr(new_bin)
	local old, new

	for i = 0, #old_bin - 1 do
		old, new = u1[ptr_old+i], u1[ptr_new+i]
		if old ~= new then
			old, new = bit.ToTable(old), bit.ToTable(new)
			for bit = 1, 8 do
				if old[bit] ~= new[bit] then
					diff[i*8+9-bit] = new[bit] or false
				end
			end
		end
	end

	if next(diff) then
		return diff
	end
	return nil
end
Multiplayer.debug.bit_array_diff = bit_array_diff

local packets = {
	qbits_changes = {
		bulb = function(qbits_bin)
			local diff = bit_array_diff(last_qbit_state, qbits_bin)

			if diff then
				return item_to_bin(diff)
			end
			return nil
		end,
		handler = function(bin_string, metadata)
			Multiplayer.sync_qbits()
			for bit, val in pairs(bin_to_item(toptr(bin_string))) do
				if not service_qbits[bit] then
					Party.QBits[bit] = val
				end
			end
			last_qbit_state = mmt_dump(Party.QBits)
		end,
		check_delivery = true
	},

	awards_changes = {
		bulb = function(awards_bin)
			local diff = bit_array_diff(last_awards_state, awards_bin)

			if diff then
				return item_to_bin(diff)
			end
			return nil
		end,
		handler = function(bin_string, metadata)
			Multiplayer.sync_awards()
			for bit, val in pairs(bin_to_item(toptr(bin_string))) do
				if val then
					Party[0].Awards[bit] = val
				end
			end
			last_awards_state = mmt_dump(Party[0].Awards)
		end,
		check_delivery = true
	},
}
Multiplayer.utils.init_packets(packets)

local function sync_qbits()
	local qbits = mmt_dump(Party.QBits)
	local data = packets.qbits_changes:prep(qbits)
	if data then
		Multiplayer.broadcast(data)
		last_qbit_state = qbits
	end
end
Multiplayer.sync_qbits = sync_qbits

local function sync_awards()
	local awards_bin = mmt_dump(Party[0].Awards)
	local data = packets.awards_changes:prep(awards_bin)
	if data then
		Multiplayer.broadcast(data)
		last_awards_state = awards_bin
	end
end
Multiplayer.sync_awards = sync_awards

local function sync_bits()
	sync_qbits()
	sync_awards()
end

function events.EvtMap(i)
	Multiplayer.utils.delayed_call(sync_bits, 4)
end

function events.EvtGlobal(i)
	Multiplayer.utils.delayed_call(sync_bits, 4)
end

function events.ExitNPC(i)
	Multiplayer.utils.delayed_call(sync_bits, 4)
end

function events.GatherGameData(t)
	t.QBits = mmt_dump(Party.QBits)
	t.Awards = mmt_dump(Party[0].Awards)
end

function events.ProcessGameData(t)
	mcopy(Party.QBits['?ptr'], mem.topointer(t.QBits), Party.QBits['?size'])
	mcopy(Party[0].Awards['?ptr'], mem.topointer(t.Awards), Party[0].Awards['?size'])

	last_qbit_state = t.QBits
	last_awards_state = t.Awards
end
