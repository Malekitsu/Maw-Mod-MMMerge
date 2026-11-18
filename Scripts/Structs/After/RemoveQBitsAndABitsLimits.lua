
local OldQBitsCount, NewQBitsCount	= 512, nil
local OldABitsCount, NewABitsCount	= 300, nil
local OldQBitsOrigin = 0xb2160f
local OldABitsOrigin = 0xb216a8
local NewQBitsPtr
local NewABitsPtr

local function SimpleReplacePtr(t, CmdSize, OldOrigin, NewOrigin)
	local OldAddr
	for i, v in ipairs(t) do
		OldAddr = mem.u4[v + CmdSize]
		mem.u4[v + CmdSize] = NewOrigin + OldAddr - OldOrigin
	end
end

--[[
-- Autonote.txt
mem.autohook(0x47586a, function(d)

	NewABitsCount = DataTables.ComputeRowCountInPChar(d.eax, 1) - 1

	if OldABitsCount >= NewABitsCount then
		return
	end

	NeedRemoval = true

	local NewANSpace = mem.StaticAlloc(NewABitsCount*8+0xc)
	NewANSpace = NewANSpace + 0xc

	mem.IgnoreProtection(true)

	SimpleReplacePtr(
	{0x412e67, 0x412e76, 0x448281, 0x4482a7, 0x448baf, 0x448bd2, 0x4cca3f, 0x4cca50,
	0x4cca71, 0x4ccc92, 0x4ccd5a, 0x4ccd69},
	3, 0x760ba4, NewANSpace)

	mem.u4[0x47587c + 1] = NewANSpace
	mem.u4[0x475980 + 2] = NewANSpace + NewABitsCount*8

	mem.u4[0x4cca98 + 2] = NewABitsCount
	mem.u4[0x4ccd9a + 2] = NewABitsCount

	mem.asmpatch(0x44772c, "mov edx, ebx")
	mem.asmpatch(0x449457, "mov edx, eax")

	mem.IgnoreProtection(false)

	internal.SetArrayUpval(Game.AutonoteTxt, "o", NewANSpace - 12)
	internal.SetArrayUpval(Game.AutonoteTxt, "count", NewABitsCount + 1)
	internal.SetArrayUpval(Game.AutonoteCategory, "o", NewANSpace - 8)
	internal.SetArrayUpval(Game.AutonoteCategory, "count", NewABitsCount + 1)
end)

-- Quests.txt
mem.autohook(0x4759c4, function(d)

	NewQBitsCount = DataTables.ComputeRowCountInPChar(d.eax, 1) - 1

	if OldQBitsCount >= NewQBitsCount then
		return
	end

	NeedRemoval = true

	local NewQBSpace = mem.StaticAlloc(NewQBitsCount*4 + 0xc)
	NewQBSpace = NewQBSpace + 0xc

	mem.IgnoreProtection(true)

	SimpleReplacePtr(
	{0x447eef, 0x448847, 0x4cc425, 0x4cc446, 0x4ccf09},
	3, 0x760394, NewQBSpace)

	mem.u4[0x4759d7 + 4] = NewQBSpace
	mem.u4[0x475a4f + 4] = NewQBSpace + NewQBitsCount*4

	mem.u4[0x4cc41e + 1] = NewQBitsCount

	mem.IgnoreProtection(false)

	internal.SetArrayUpval(Game.QuestsTxt, "o", NewQBSpace - 4)
	internal.SetArrayUpval(Game.QuestsTxt, "count", NewQBitsCount + 1)

end)
]]

local function RemoveBitsLimits()
	NewABitsCount = Game.AutonoteTxt.count - 1
	NewQBitsCount = Game.QuestsTxt.count - 1

	NewQBitsPtr = mem.StaticAlloc(math.floor(NewQBitsCount/8) + 1 + 0x4 + math.floor(NewABitsCount/8) + 1)
	NewABitsPtr = NewQBitsPtr + math.floor(NewQBitsCount/8) + 1 + 0x4

	mem.IgnoreProtection(true)

		-- ABits
	SimpleReplacePtr(
	{0x412e85, 0x44772f, 0x44826d, 0x448b9c, 0x44945a, 0x4cca5f, 0x4ccd74},
	1, OldABitsOrigin, NewABitsPtr)

	internal.SetArrayUpval(Party["AutonotesBits"], "o", NewABitsPtr)
	internal.SetArrayUpval(Party["AutonotesBits"], "count", NewABitsCount)

		-- QBits
	SimpleReplacePtr(
	{0x40e880, 0x421842, 0x43116c, 0x442dbd, 0x442eda, 0x447490, 0x447ed7, 0x448833,
	 0x448d81, 0x449148, 0x4616a7, 0x468a1d, 0x479a74, 0x47e2ed, 0x490781, 0x4b06cc,
	 0x4b0902, 0x4b0984, 0x4b5100, 0x4b55e2, 0x4ba767, 0x4ba7e6, 0x4c819f, 0x4cc434,
	 0x4d1038, 0x4d1059, 0x4d1077, 0x4d1095, 0x4d10b3, 0x4d10d1},
	 1, OldQBitsOrigin, NewQBitsPtr)

	mem.IgnoreProtection(false)

	mem.asmpatch(0x48c07e, "mov ecx, " .. NewQBitsPtr)

	internal.SetArrayUpval(Party["QBits"], "o", NewQBitsPtr)
	internal.SetArrayUpval(Party["QBits"], "count", NewQBitsCount)

	---- Save management

	local Ctr = math.ceil((NewQBitsCount+NewABitsCount)/32)

	events.AddFirst('NewGameMap', function()
		mem.fill(Party.QBits["?ptr"], math.ceil(Party.QBits["?size"]))
	
		for i = 0, Ctr do
			mem.u4[i * 4 + NewQBitsPtr] = 0
		end
		NewGameStarted = true
	end)

	events.AddFirst("BeforeLoadMap", function(WasInGame)
		if NewGameStarted then
			NewGameStarted = false
			return
		end
		if not WasInGame then
			if vars.ExtendedBits then
				for i = 0, Ctr do
					mem.u4[i*4+NewQBitsPtr] = vars.ExtendedBits[i] or 0
				end
				vars.ExtendedBits = nil
			else
				for i = 0, Ctr do
					mem.u4[i*4+NewQBitsPtr] = 0
				end
			end
		end
	end)

	function events.BeforeSaveGame()
		vars.ExtendedBits = vars.ExtendedBits or {}
		for i = 0, Ctr do
			vars.ExtendedBits[i] = mem.u4[NewQBitsPtr + i*4]
		end
	end

end

function events.GameInitialized2()
	--if NeedRemoval then
	if Game.AutonoteTxt.count > OldABitsCount + 1 or Game.QuestsTxt.count > OldQBitsCount + 1 then
		RemoveBitsLimits()
	end
end
