local function ProcessTxt()

	if not const.Race then
		return
	end

	local SkillsCount = 39
	local RaceCount = 0

	for k,v in pairs(const.Race) do
		RaceCount = RaceCount + 1
	end

	local TxtTable = io.open("Data/Tables/Race Skills.txt", "r")
	if not TxtTable then
		TxtTable = io.open("Data/Tables/Race Skills.txt", "w")
		local line = ""
		local RaceCount = 0

		local RaceNames = {}
		for k,v in pairs(const.Race) do
			RaceNames[v] = k
		end

		for k,v in pairs(RaceNames) do
			line = line .. "\9" .. v .. "(" .. k .. ")"
			RaceCount = RaceCount + 1
		end

		local KindNames = {}
		if Game.ClassesExtra then
			for i,v in pairs(Game.ClassesExtra) do
				if v.Kind > 0 then
					KindNames[v.Kind] = KindNames[v.Kind] or i
				end
			end

			for i,v in pairs(KindNames) do
				for _,R in pairs(RaceNames) do
					line = line .. "\9" .. R .. " - " .. Game.ClassNames[v]
				end
			end
		end

		TxtTable:write(line .. "\n")

		for k,v in pairs(const.Skills) do
			line = k
			for i = 0, RaceCount + #KindNames*RaceCount do
				line = line .. "\9-"
			end
			TxtTable:write(line .. "\n")
		end

		io.close(TxtTable)
		TxtTable = io.open("Data/Tables/Race Skills.txt", "r")
	end

	local LineIt = TxtTable:lines()
	LineIt() -- skip header

	local SkillConns = {B = 1, E = 2, M = 3, G = 4}
	local ExeptionConns = {I = -1, P = -2, IP = -3, S = -4, W = -5, } -- S = spellcasters only, W = warriors only (classes with no SP)
	local RaceSkills = {}

	local function GetPool(line)
		local Pool = {}
		Pool.Min, Pool.Add, Pool.Exc = (line or ""):match("^([BEMG]?)/?([^/]*)/?([^/]*)")

		for k,v in pairs(Pool) do
			Pool[k] = tonumber(v) or SkillConns[v] or ExeptionConns[v] or 0
		end
		return Pool
	end

	for line in LineIt do
		local Words = string.split(line, "\9")
		if string.len(Words[1]) == 0 then
			break
		end

		local Skill, Race, Kind = const.Skills[Words[1]], nil, nil
		for i = 2, #Words do
			Race, Kind = (i-2)%RaceCount, math.floor((i-2)/RaceCount)
			RaceSkills[Race] = RaceSkills[Race] or {}
			RaceSkills[Race][Kind] = RaceSkills[Race][Kind] or {}
			RaceSkills[Race][Kind][Skill] = GetPool(Words[i])
		end
	end

	io.close(TxtTable)

	Game.RaceSkills = RaceSkills

	return true

end

local function SetHooks()

	local min, max = math.min, math.max
	local ClassSkillsPtr = Game.Classes.Skills["?ptr"]
	local ClassTypes = {}

	if Game.ClassesExtra then
		for k,v in pairs(Game.ClassesExtra) do
			ClassTypes[k] = v.Kind
		end
	end

	local function GetPlayer(ptr)
		local PlayerId = (ptr - Party.PlayersArray["?ptr"])/Party.PlayersArray[0]["?size"]
		return Party.PlayersArray[PlayerId], PlayerId
	end

	local function GetMaxSkill(a, b, c) -- a - Race or Player structure, b - Class or skill id, c - skill id

		local Race, Class, Skill
		if type(a) == "number" then
			Race, Class, Skill = a, b, c
		else
			Race, Class, Skill = Game.CharacterPortraits[a.Face].Race, a.Class, b
		end

		if Skill < 0 then return 4 end --Yuji Sakai
		if Skill >= 39 then return 4 end --Yuji Sakai

		local SPStat 		= Game.Classes.SPStats[Class]
		local GeneralBonus	= Game.RaceSkills[Race][0][Skill]
		local ClassBonus	= Game.RaceSkills[Race][ClassTypes[Class]][Skill]
		local Bonus			= {Min = 0, Add = 0}
		local Exc 			= GeneralBonus.Exc

		if Exc == 0 or not (ClassTypes[Class] == Exc or Exc == -4 and SPStat == 0 or Exc == -5 and SPStat >  0 or -Exc == SPStat) then
			Bonus.Min, Bonus.Add = GeneralBonus.Min, GeneralBonus.Add
		end
		Bonus.Min = max(Bonus.Min, ClassBonus.Min)
		Bonus.Add = max(Bonus.Add, ClassBonus.Add)

		local DefSkill	= Game.Classes.Skills[Class][Skill]
		local Result	= DefSkill

		Result = max(DefSkill, Bonus.Min)
		if DefSkill > 0 then
			Result = Result + Bonus.Add
		end

		return max(min(Result, 4), 0), Result - DefSkill

	end

	GetMaxSkillLevel	 = GetMaxSkill
	GetMaxAvailableSkill = GetMaxSkill

	-- Base functions

	local GetRaceSkill = mem.asmproc([[
	; start:
	; eax - player ptr
	; ecx - skill

	nop
	nop
	nop
	nop
	nop
	retn]])

	local function eventGetMaxSkill(Player, PlayerIndex, Skill)
		local t = {Player = Player, PlayerIndex = PlayerIndex, Skill = Skill, Result = 0, Bonus = 0}
		t.Result, t.Bonus = GetMaxSkill(t.Player, t.Skill)
		events.call("GetMaxSkillLevel", t)
		return t.Result, t.Bonus
	end

	mem.hook(GetRaceSkill, function(d)
		local p, pid = GetPlayer(d.eax)
		d.eax = eventGetMaxSkill(p, pid, d.ecx)
	end)

	-- 0x4171a0, 0x4171ba, 0x4171c6
	function events.ShowSkillDescr(t)
		local cMax, Bonus = eventGetMaxSkill(t.Player, t.PlayerIndex, t.Skill)
		t.MaxLevel = t.MaxLevel + Bonus
	end

	-- Can get new tier

	-- 0x4b0e6b
	mem.asmpatch(0x4b0e6b, [[
	movzx eax, byte [ds:ecx+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ebx
	call absolute ]] .. GetRaceSkill .. [[;]])

	-- 0x4b0e99
--~ 	mem.asmpatch(0x4b0e99, [[
--~ 	lea eax, dword [ds:ecx+edx+]] .. ClassSkillsPtr .. [[]
--~ 	mov edx, eax
--~ 	mov eax, ebx
--~ 	call absolute ]] .. GetRaceSkill .. [[;
--~ 	mov ecx, eax
--~ 	mov eax, edi]])

	-- Can learn in shop

	-- 0x4b32ee
	mem.asmpatch(0x4b32ee, [[
	push eax
	push ecx
	movzx eax, byte[ds:edi+eax+]] .. ClassSkillsPtr .. [[]
	mov eax, ecx
	mov ecx, edi
	call absolute ]] .. GetRaceSkill .. [[;
	test eax, eax
	pop ecx
	pop eax]])

	-- 0x4b33ea
	mem.asmpatch(0x4b33ea, [[
	movzx eax, byte[ds:ebx+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, esi
	mov ecx, ebx
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, esi
	test eax, eax]])

	-- 0x4b4bb0
	mem.asmpatch(0x4b4bb0, [[
	movzx eax, byte [ds:esi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, esi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x14]
	test eax, eax]])

	-- 0x4b4ca7
	mem.asmpatch(0x4b4ca7, [[
	movzx eax, byte [ds:edi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, edi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x14]
	test eax, eax]])

	-- 0x4b9382
	mem.asmpatch(0x4b9382, [[
	movzx eax, byte [ds:esi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, esi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x10]
	test eax, eax]])

	-- 0x4b9477
	mem.asmpatch(0x4b9477, [[
	movzx eax, byte [ds:edi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, edi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x10]
	test eax, eax]])

	-- 0x4b7bee
	mem.asmpatch(0x4b7bee, [[
	movzx eax, byte [ds:esi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, esi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x14]
	test eax, eax]])

	-- 0x4b7ce3
	mem.asmpatch(0x4b7ce3, [[
	movzx eax, byte [ds:edi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, edi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x14]
	test eax, eax]])

	-- 0x4b590d -- temple -- mistake
	mem.asmpatch(0x4b590d, [[
	movzx eax, byte [ds:esi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, esi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0xc]
	test eax, eax]])

	-- 0x4b5a07 -- temple
	mem.asmpatch(0x4b5a07, [[
	movzx eax, byte [ds:edi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, edi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0xc]
	test eax, eax]])

	-- 0x4b3f64 -- magic shop
	mem.asmpatch(0x4b3f64, [[
	movzx eax, byte [ds:esi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, esi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x14]
	test eax, eax]])

	-- 0x4b4059 -- magic shop
	mem.asmpatch(0x4b4059, [[
	movzx eax, byte [ds:edi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, edi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x14]
	test eax, eax]])

	-- 0x4b82b2 -- alchemist
	mem.asmpatch(0x4b82b2, [[
	movzx eax, byte [ds:esi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, esi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x18]
	test eax, eax]])

	-- 0x4b83a7 -- alchemist
	mem.asmpatch(0x4b83a7, [[
	movzx eax, byte [ds:edi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, edi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x18]
	test eax, eax]])

	-- 0x4b6948 -- tavern
	mem.asmpatch(0x4b6948, [[
	movzx eax, byte [ds:esi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, esi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x18]
	test eax, eax]])

	-- 0x4b6a43 -- tavern
	mem.asmpatch(0x4b6a43, [[
	movzx eax, byte [ds:edi+eax+]] .. ClassSkillsPtr .. [[]
	mov edx, eax
	mov eax, ecx
	mov ecx, edi
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, dword [ss:ebp-0x18]
	test eax, eax]])

	-- 0x4baf6c -- Can learn 1
	mem.asmpatch(0x4baf6c, [[
	movzx eax, byte [ds:ebp+eax+]] .. ClassSkillsPtr - 0x24 .. [[]
	mov edx, eax
	mov eax, ecx
	lea ecx, dword [ss:ebp-0x24]
	call absolute ]] .. GetRaceSkill .. [[;
	mov ecx, edi
	test eax, eax]])

	-- 0x4bbcf1, 0x4b4df5, 0x4b4f8c

end

function events.GameInitialized2()
	GetMaxSkillLevel	 = function() return 0 end
	GetMaxAvailableSkill = function() return 0 end
	if ProcessTxt() then
		SetHooks()
	end
end
