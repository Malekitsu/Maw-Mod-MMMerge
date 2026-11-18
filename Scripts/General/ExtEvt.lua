local MO, MV = Merge.Offsets, Merge.Vars
local asmpatch, hook, u4, u8 = mem.asmpatch, mem.hook, mem.u4, mem.u8

local function ExtendEvtVars()
	MO.DaysCounters = mem.StaticAlloc(6 * 8)

	------ evt.Cmp ------

	-- Add NPCs, ReputationIs, HasNPCProfession and DaysCounter support
	local NewCode = asmpatch(0x4477F7, [[
	cmp eax, 0xEA
	jnz @rep
	nop
	nop
	nop
	nop
	nop
	jmp absolute 0x447AC8
	@rep:
	cmp eax, 0xEB
	jnz @prof
	neg dword [ebp+0xC]
	cmp dword ptr [0x6F39A0], 2
	mov eax, 0x6CF09C
	jz @outdoor
	mov eax, 0x6F3CCC
	@outdoor:
	mov eax, [eax+8]
	xor ecx, ecx
	cmp eax, dword [ebp+0xC]
	setng cl
	mov eax, ecx
	jmp absolute 0x447ACF
	@prof:
	cmp eax, 0xF3
	jnz @days
	nop
	nop
	nop
	nop
	nop
	jmp absolute 0x447AC8
	@days:
	cmp eax, 0xEC
	jl @none
	cmp eax, 0xF1
	jg @none
	sub eax, 0xEC
	mov esi, dword ptr []] .. MO.DaysCounters .. [[ + eax * 8]
	mov edi, dword ptr []] .. (MO.DaysCounters + 4) .. [[ + eax * 8]
	mov eax, esi
	or eax, edi
	jz absolute 0x4479A7
	mov eax, dword ptr [ebp + 0xC]
	imul eax, 0xA8C000
	jmp absolute 0x4479B7
	@none:
	sub eax, 0xE7
	]])

	hook(NewCode + 7, function(d)
		local npc_id = d.ebx
		d.edi = NPCFollowers.NPCInGroup(npc_id) and npc_id or 0
	end)

	hook(NewCode + 0x47, function(d)
		d.edi = NPCFollowers.HaveProfession(d.ebx) and d.ebx or 0
	end)

	-- Adjust TotalCircusPrize first item id
	mem.IgnoreProtection(true)
	u4[0x447852] = 2090	-- Lodestone
	mem.IgnoreProtection(false)

	------ evt.Set ------

	-- Add NPCs, ReputationIs and DaysCounter support
	NewCode = asmpatch(0x44824A, [[
	cmp eax, 0xEA
	jl @none
	jnz @rep
	mov ecx, dword ptr [ebp+0xC]
	nop
	nop
	nop
	nop
	nop
	jmp absolute 0x448488
	@rep:
	cmp eax, 0xEB
	jnz @days
	neg dword [ebp+0xC]
	jmp absolute 0x448324
	@days:
	cmp eax, 0xEC
	jl @none
	cmp eax, 0xF1
	jg @none
	sub eax, 0xEC
	mov ecx, dword ptr [0xB20EBC]
	mov dword ptr []] .. MO.DaysCounters .. [[ + eax * 8], ecx
	mov ecx, dword ptr [0xB20EC0]
	mov dword ptr []] .. (MO.DaysCounters + 4) .. [[ + eax * 8], ecx
	jmp absolute 0x448462
	@none:
	cmp eax, 0xE9]])

	hook(NewCode + 0xC, function(d)
		local result = NPCFollowers.Add(d.ecx)
		if not result then
			-- Log error message
		end
	end)

	------ evt.Add ------

	-- Add ReputationIs, NPCs and DaysCounter support
	NewCode = asmpatch(0x448B80, [[
	cmp eax, 0xEA
	jl @none
	jnz @rep
	mov ecx, dword ptr [ebp+0xC]
	nop
	nop
	nop
	nop
	nop
	jmp absolute 0x448E29
	@rep:
	cmp eax, 0xEB
	jnz @days
	neg dword [ebp+0xC]
	jmp absolute 0x448CCF
	@days:
	cmp eax, 0xEC
	jl @none
	cmp eax, 0xF1
	jg @none
	sub eax, 0xEC
	mov ecx, dword ptr [0xB20EBC]
	mov dword ptr []] .. MO.DaysCounters .. [[ + eax * 8], ecx
	mov ecx, dword ptr [0xB20EC0]
	mov dword ptr []] .. (MO.DaysCounters + 4) .. [[ + eax * 8], ecx
	jmp absolute 0x
	@none:
	cmp eax, 0xE9]])

	hook(NewCode + 0xC, function(d)
		local result = NPCFollowers.Add(d.ecx)
		if not result then
			-- Log error message
		end
	end)

	-- Reputation lower bound check
	asmpatch(0x448CF2, [[
	jg absolute 0x448CF8
	neg ecx
	cmp edx, ecx
	jge absolute 0x448E29
	mov [eax+8], ecx
	jmp absolute 0x448E29]])

	------ evt.Subtract ------

	-- Add ReputationIs, NPCs and HasNPCProfession support
	NewCode = asmpatch(0x44943E, [[
	cmp eax, 0xEA
	jnz @first
	mov ecx, dword ptr [ebp+0xC]
	nop
	nop
	nop
	nop
	nop
	jmp absolute 0x4490C3
	@first:
	cmp eax, 0xEB
	jnz @prof
	neg dword [ebp+0xC]
	jmp absolute 0x4494DE
	@prof:
	cmp eax, 0xF3
	jnz @none
	mov ecx, dword ptr [ebp+0xC]
	nop
	nop
	nop
	nop
	nop
	jmp absolute 0x4490C3
	@none:
	cmp eax, 0xE9]])

	hook(NewCode + 10, function(d)
		local result = NPCFollowers.Remove(d.ecx)
		if not result then
			-- Log error message
		end
	end)

	hook(NewCode + 0x2D, function(d)
		NPCFollowers.RemoveProfession(d.ecx)
	end)

	-- Reputation upper bound check
	asmpatch(0x449501, [[
	jl absolute 0x449507
	neg ecx
	cmp edx, ecx
	jle absolute 0x4490C3
	mov [eax+8], ecx
	jmp absolute 0x4490C3]])
end

function events.GameInitialized1()
	ExtendEvtVars()
end

function events.ContinentChange1()
	vars.ContData = vars.ContData or {}
	vars.ContData.Counters = vars.ContData.Counters or {}
	vars.ContData.DaysCounters = vars.ContData.DaysCounters or {}
	--[=[
	-- Save evt Counters of previous continent - not needed, saved in BeforeSaveGame
	if MV.PrevContinent and MV.PrevContinent > 0 then
		vars.ContData.Counters[MV.PrevContinent] = vars.ContData.Counters[MV.PrevContinent] or {}
		vars.ContData.DaysCounters[MV.PrevContinent] = vars.ContData.DaysCounters[MV.PrevContinent] or {}
		for i = 1, 10 do
			vars.ContData.Counters[MV.PrevContinent][i] = u8[0xB2137C + (i - 1) * 8]
		end
		for i = 1, 6 do
			vars.ContData.DaysCounters[MV.PrevContinent][i] = u8[MO.DaysCounters + (i - 1) * 8]
		end
	end
	]=]
	-- Load evt Counters for current continent
	if MV.Continent and MV.Continent > 0 then
		vars.ContData.Counters[MV.Continent] = vars.ContData.Counters[MV.Continent] or {}
		vars.ContData.DaysCounters[MV.Continent] = vars.ContData.DaysCounters[MV.Continent] or {}
		for i = 1, 10 do
			vars.ContData.Counters[MV.Continent][i] = vars.ContData.Counters[MV.Continent][i] or 0
			u8[0xB2137C + (i - 1) * 8] = vars.ContData.Counters[MV.Continent][i]
		end
		for i = 1, 6 do
			vars.ContData.DaysCounters[MV.Continent][i] = vars.ContData.DaysCounters[MV.Continent][i] or 0
			u8[MO.DaysCounters + (i - 1) * 8] = vars.ContData.DaysCounters[MV.Continent][i]
		end
	end
end

function events.BeforeSaveGame()
	vars.ContData = vars.ContData or {}
	vars.ContData.Counters = vars.ContData.Counters or {}
	vars.ContData.DaysCounters = vars.ContData.DaysCounters or {}
	if MV.Continent and MV.Continent > 0 then
		vars.ContData.Counters[MV.Continent] = vars.ContData.Counters[MV.Continent] or {}
		vars.ContData.DaysCounters[MV.Continent] = vars.ContData.DaysCounters[MV.Continent] or {}
		for i = 1, 10 do
			vars.ContData.Counters[MV.Continent][i] = u8[0xB2137C + (i - 1) * 8]
		end
		for i = 1, 6 do
			vars.ContData.DaysCounters[MV.Continent][i] = u8[MO.DaysCounters + (i - 1) * 8]
		end
	end
end
