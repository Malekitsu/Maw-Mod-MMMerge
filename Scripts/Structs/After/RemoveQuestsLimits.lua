local abs, floor, ceil, round, max, min = math.abs, math.floor, math.ceil, math.round, math.max, math.min
local i4, i2, i1, u4, u2, u1, pchar, call = mem.i4, mem.i2, mem.i1, mem.u4, mem.u2, mem.u1, mem.pchar, mem.call
local mmver = offsets.MMVersion

local mmv = |...| (select(mmver - 5, ...))
local mm78 = |...| mmv(nil, ...)

-- extend Game.QuestsTxt

mem.ExtendGameStructure{'QuestsTxt', Size = 4, StartBefore = 4*Game.QuestsTxt.low,
	Refs = mmv(
		{0x40D3C9, 0x40E300, 0x46858B;  0x4685FF},
		{0x412805, 0x41333E, 0x44A8EC, 0x44B2B7, 0x4768F5;  0x47696E},
		{0x447EF2, 0x44884A, 0x4759DB, 0x4CC428, 0x4CC449, 0x4CCF0C;  0x475A53}
	),
}

if Merge then
	mem.autohook(0x4759C4, function(d)
		local n = DataTables.ComputeRowCountInPChar(d.eax, 1) - 1
		if n > 512 then
			mem.prot(true)
			u4[0x475A4F + 4] = u4[0x4759DB] + n * 4
			u4[0x4CC41E + 1] = n + 1
			mem.prot(false)
			Game.QuestsTxt.SetHigh(n)
		end
	end)
end

-- extend Party.QBits? (mm8 - 4759D0)
