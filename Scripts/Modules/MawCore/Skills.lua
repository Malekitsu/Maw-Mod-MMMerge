-- Skills.lua -- Lua port of Skillz.dll, stage 1 of the plan in SKILLZ_PORT.md.
--
-- MODE SWITCH: if ExeMods\Skillz.dll exists, no patches are applied and the
-- global Skillz table becomes a bridge to the DLL (the legacy wrapper
-- absorbed from the removed Scripts/Structs/00Skillz.lua) -- so a lingering
-- DLL still yields a working game. Without the DLL, the port owns
-- everything. Both may never patch at once.
--
-- This file also absorbed, from the removed 00Skillz.lua / ZZZZ_Last.lua:
-- the GetMaxSkillLevel/GetMaxAvailableSkill globals (called by base MMMerge
-- scripts: PromotionTopics, NPCMercenaries, MiscTweaks, ZombiePlayers),
-- JoinSkill2/SplitSkill2, the new-game mastery-refund flow, and the
-- new_misc(127) glitch workaround (SKILLZ_PORT.md Q2).
--
-- Stage 1 scope (see SKILLZ_PORT.md "Status"):
--   * extended skill storage, IDs 39..127, engine-visible (K1, K3)
--   * skill+item-bonus clamp raised from the engine's 60 to 1023 (K12)
--   * persistence in vars instead of the DLL's skillz.bin (K2)
--   * names/descriptions stored; base-skill (<39) writes reach the engine's
--     own pointer arrays, extended ones are Lua-side only until the UI
--     hooks arrive in stage 2 (K4, K5 partial)
--   * mastery-limit tables parsed from Data\Tables (K6 data side; the
--     teacher/UI hooks that consume them engine-side are stage 3)
--   * category/shop registrations recorded for stage 3 (K8, K9 data side)
--   * CleanMastery is a NO-OP for now: it zeroes player skills when it acts,
--     so it stays disabled until MasteryLimit values are verified in-game
--
-- Storage layout mirrors the DLL exactly, so the asm reads translate 1:1:
--   block+0      int16 skills[128 players][89]   (skill IDs 39..127)
--   block+22784  uint8 extraMastery[128][128]    (beyond-Grand, D1)
--
-- The asm patches are literal translations of the DLL's naked hooks,
-- validated instruction-by-instruction against mm8.exe AND the shipped
-- Skillz.dll bytes. Their plain-retn exits look wrong against the engine's
-- "ret 4" epilogue but are correct: MMExtension's GetSkill hookfunction
-- wraps the whole function and manages the stack around the body
-- (see Engine.Addr comments). Do not "fix" them.

local Skills = {}
MawCore.Skills = Skills

local OLD_COUNT = 39
local NEW_COUNT = 128
local PLAYERS = 128
local SKILL_ROW = (NEW_COUNT - OLD_COUNT) * 2	-- 178 bytes per player
local MASTERY_OFF = PLAYERS * SKILL_ROW			-- 22784

local block            -- StaticAlloc'd storage, set in start()
local active = false

local names = {}       -- [id] = string (authoritative for >=39; mirror for <39)
local descs = {}       -- [id] = {[part] = string}, parts 1..20
local nameBufs = {}    -- engine-side string buffers we allocated, [key] = ptr
local namePtrs         -- char*[128] array read by the SkillsUI asm shims

-- category/shop registrations, preloaded with the DLL's presets in start()
Skills.Categories = {weapon = {}, armor = {}, misc = {}, magic = {}}
Skills.ShopSkills = {}		-- [houseType] = array of skill ids

-- mastery tables (parsed from Data\Tables in start())
local classNames, skillNames, raceNames = {}, {}, {}
local classM = {}      -- [class][skill] = 0..8
local raceM = {}       -- [race][skill] = modifier {min,max,mod}
local extraM = {}      -- [race][class][skill] = modifier
local classExtra = {}  -- [class] = {kind, step}

local function dllPresent()
	local f = io.open(AppPath .. "ExeMods\\Skillz.dll", "rb")
	if f then
		f:close()
		return true
	end
	return false
end
Skills.dllPresent = dllPresent

---------------------------------------------------------------- storage

local function playerPtr(pl)
	return type(pl) == "number" and pl or pl["?ptr"]
end

-- roster index from a player pointer; -1 if not a roster player.
-- Same math as the DLL's PlayerID.
local function playerId(pl)
	local A = MawCore.Engine.Addr
	local d = playerPtr(pl) - A.PlayerBase
	if d < 0 or d % A.PlayerStride ~= 0 then
		return -1
	end
	return d / A.PlayerStride
end

local function rawGet(pl, id)
	if id < 0 or id >= NEW_COUNT then
		return 0
	end
	if id < OLD_COUNT then
		return pl.Skills[id]
	end
	local p = playerId(pl)
	if p < 0 or p >= PLAYERS then
		return 0
	end
	return mem.u2[block + p * SKILL_ROW + (id - OLD_COUNT) * 2]
end

local function rawSet(pl, id, v)
	if id < 0 or id >= NEW_COUNT then
		return
	end
	if id < OLD_COUNT then
		pl.Skills[id] = v
		return
	end
	local p = playerId(pl)
	if p < 0 or p >= PLAYERS then
		return
	end
	mem.u2[block + p * SKILL_ROW + (id - OLD_COUNT) * 2] = v
end

-- engine mastery encoding of a raw skill value (bits 10..12)
local function valueMastery(v)
	if v == 0 then
		return 0
	end
	local f = bit.band(v, 0x1C00)
	if f >= 0x1000 then
		return 4
	elseif f >= 0x800 then
		return 3
	elseif f >= 0x400 then
		return 2
	end
	return 1
end

---------------------------------------------------------------- persistence

local function syncToVars()
	local sk, ms = {}, {}
	for p = 0, PLAYERS - 1 do
		local rowS, rowM
		for id = OLD_COUNT, NEW_COUNT - 1 do
			local v = mem.u2[block + p * SKILL_ROW + (id - OLD_COUNT) * 2]
			if v ~= 0 then
				rowS = rowS or {}
				rowS[id] = v
			end
		end
		for id = 0, NEW_COUNT - 1 do
			local m = mem.u1[block + MASTERY_OFF + p * NEW_COUNT + id]
			if m ~= 0 then
				rowM = rowM or {}
				rowM[id] = m
			end
		end
		sk[p], ms[p] = rowS, rowM
	end
	MawCore.Save.data().skillz = {skills = sk, mastery = ms}
end

local function loadFromVars()
	for i = 0, MASTERY_OFF + PLAYERS * NEW_COUNT - 4, 4 do
		mem.u4[block + i] = 0
	end
	local d = vars.MawCore
	local z = d and d.skillz
	if not z then
		return
	end
	for p, row in pairs(z.skills or {}) do
		for id, v in pairs(row) do
			mem.u2[block + p * SKILL_ROW + (id - OLD_COUNT) * 2] = v
		end
	end
	for p, row in pairs(z.mastery or {}) do
		for id, m in pairs(row) do
			mem.u1[block + MASTERY_OFF + p * NEW_COUNT + id] = m
		end
	end
end

---------------------------------------------------------------- mastery tables

local LETTER = {B = 1, N = 1, E = 2, M = 3, G = 4, S = 5, U = 6, A = 7, D = 8}
local MODMIN = {N = 1, E = 2, M = 3, G = 4, S = 5, U = 6, A = 7, D = 8}
local MODMAX = {["0"] = 0, n = 1, e = 2, m = 3, g = 4, s = 5, u = 6, a = 7, d = 8}

local function readLines(name)
	local f = io.open(AppPath .. "Data\\Tables\\" .. name, "r")
	if not f then
		return nil
	end
	local t = {}
	for l in f:lines() do
		t[#t + 1] = (l:gsub("\r", ""))
	end
	f:close()
	return t
end

local function cells(line)
	local out = {}
	for s in (line .. "\t"):gmatch("([^\t]*)\t") do
		out[#out + 1] = s
	end
	return out
end

-- DLL 'modifier': min/max/shift parsed from a token like "E", "g+", "M-"
local function parseModifier(tok)
	local m = {min = 0, max = 8, mod = 0}
	for ch in tok:gmatch(".") do
		if MODMIN[ch] then
			m.min = MODMIN[ch]
		elseif MODMAX[ch] then
			m.max = MODMAX[ch]
		elseif ch == "+" then
			m.mod = m.mod + 1
		elseif ch == "-" then
			m.mod = m.mod - 1
		end
	end
	return m
end

local function isDefaultMod(m)
	return m.min == 0 and m.max == 8 and m.mod == 0
end

-- DLL apply order: add, clamp to max, clamp to min
local function applyMod(m, v)
	v = v + m.mod
	if v > m.max then
		v = m.max
	end
	if v < m.min then
		v = m.min
	end
	return v
end

local function idByName(list, tok)
	if tok == "" then
		return -1
	end
	if tok:match("^%d") then
		return tonumber(tok:match("^%d+"))
	end
	for i, n in pairs(list) do
		if n == tok then
			return i
		end
	end
	return -1
end

local function parseTables()
	local t = readLines("Class Skillz.txt")
	if t then
		local hdr = cells(t[1])
		for c = 2, #hdr do
			classNames[c - 2] = hdr[c]
			classM[c - 2] = {}
		end
		for r = 2, #t do
			local row = cells(t[r])
			local skill = r - 2
			if skill >= NEW_COUNT then
				break
			end
			skillNames[skill] = row[1]
			for c = 2, #row do
				if classM[c - 2] then
					classM[c - 2][skill] = LETTER[row[c]] or 0
				end
			end
		end
	end

	-- the DLL reads only the 39 base-skill rows of the race table
	t = readLines("Race Skillz.txt")
	if t then
		local hdr = cells(t[1])
		for c = 2, #hdr do
			raceNames[c - 2] = hdr[c]
			raceM[c - 2] = {}
		end
		for r = 2, math.min(#t, 1 + OLD_COUNT) do
			local row = cells(t[r])
			for c = 2, #row do
				if raceM[c - 2] then
					raceM[c - 2][r - 2] = parseModifier(row[c])
				end
			end
		end
	end

	t = readLines("Class Extra.txt")
	if t then
		for r = 2, #t do
			local row = cells(t[r])
			local id = tonumber(row[1])
			if id then
				classExtra[id] = {kind = tonumber(row[2]) or 0, step = tonumber(row[3]) or 0}
			end
		end
	end

	t = readLines("Extra Skillz.txt")
	if t and t[1] == "Race\tClass\tSkill\tmodifier" then
		for r = 2, #t do
			local row = cells(t[r])
			if #row >= 4 then
				local race = idByName(raceNames, row[1])
				local clas = idByName(classNames, row[2])
				local skill = idByName(skillNames, row[3])
				if race >= 0 and clas >= 0 and skill >= 0 then
					extraM[race] = extraM[race] or {}
					extraM[race][clas] = extraM[race][clas] or {}
					extraM[race][clas][skill] = parseModifier(row[4])
				end
			end
		end
	end
end

local DEFAULT_MOD = {min = 0, max = 8, mod = 0}

local function masteryLimitRaw(race, clas, skill)
	local base = classM[clas] and classM[clas][skill] or 0
	if race and race >= 0 then
		local e = extraM[race] and extraM[race][clas] and extraM[race][clas][skill]
		if e and not isDefaultMod(e) then
			return applyMod(e, base)
		end
		return applyMod(raceM[race] and raceM[race][skill] or DEFAULT_MOD, base)
	end
	return base
end

-- DLL next_class: last consecutive entry sharing the current class's kind
function Skills.nextClass(clas)
	local e = classExtra[clas]
	if not e then
		return clas
	end
	local i = clas
	while classExtra[i + 1] and classExtra[i + 1].kind == e.kind do
		i = i + 1
	end
	return i
end

---------------------------------------------------------------- names/descs

-- copy a Lua string into an allocated engine-side buffer, reusing it
local function stringBuf(key, s, cap)
	local p = nameBufs[key]
	if not p then
		p = MawCore.Engine.alloc(cap)
		nameBufs[key] = p
	end
	if #s > cap - 1 then
		s = s:sub(1, cap - 1)
	end
	for i = 1, #s do
		mem.u1[p + i - 1] = s:byte(i)
	end
	mem.u1[p + #s] = 0
	return p
end

local function getName(id)
	if id < 0 or id >= NEW_COUNT then
		return "Wrong Skill ID"
	end
	if names[id] then
		return names[id]
	end
	if id < OLD_COUNT then
		local p = mem.u4[MawCore.Engine.Addr.SkillNamePtrArray + id * 4]
		if p ~= 0 then
			return mem.string(p)
		end
	end
	return "Unnamed Skill"
end

local function setName(id, s)
	if id < 0 or id >= NEW_COUNT then
		return
	end
	names[id] = s
	local buf = stringBuf("n" .. id, s, 256)
	if namePtrs then
		mem.u4[namePtrs + id * 4] = buf
	end
	if id < OLD_COUNT then
		-- point the engine's own name slot at our buffer, as the DLL did;
		-- makes base-skill renames visible everywhere with no hooks
		local A = MawCore.Engine.Addr
		MawCore.Engine.writePtr(A.SkillNamePtrArray + id * 4, buf)
	end
end

local function getDesc(id, part)
	if part < 0 or part > 20 then
		return ""
	end
	local d = descs[id]
	if d and d[part] then
		return d[part]
	end
	if id >= 0 and id < OLD_COUNT and part >= 1 and part <= 5 then
		local arr = MawCore.Engine.Addr.SkillDescPtrArrays[part]
		local p = mem.u4[arr + id * 4]
		if p ~= 0 then
			return mem.string(p)
		end
	end
	return ""
end

local function setDesc(id, part, s)
	if part < 0 or part > 20 or id < 0 or id >= NEW_COUNT then
		return
	end
	descs[id] = descs[id] or {}
	descs[id][part] = s
	if id < OLD_COUNT and part >= 1 and part <= 5 then
		local arr = MawCore.Engine.Addr.SkillDescPtrArrays[part]
		MawCore.Engine.writePtr(arr + id * 4, stringBuf("d" .. part .. "_" .. id, s, 4096))
	end
end

---------------------------------------------------------------- public API
-- Signatures identical to the 00Skillz.lua wrapper, so no call site changes.

Skills.API = {
	get = function(pl, id)
		return rawGet(pl, id)
	end,
	set = function(pl, id, v)
		rawSet(pl, id, v)
	end,
	-- packed (mastery << 16) + level; masteries past Grand live in the
	-- extraMastery block, exactly per the DLL's get2/set2
	get2 = function(pl, id)
		local p = playerId(pl)
		if p < 0 then
			return 0
		end
		local v = rawGet(pl, id)
		local m = valueMastery(v)
		if m >= 4 then
			m = m + bit.band(mem.u1[block + MASTERY_OFF + p * NEW_COUNT + id], 0xF)
		end
		return m * 65536 + bit.band(v, 0x3FF)
	end,
	set2 = function(pl, id, value)
		local p = playerId(pl)
		if p < 0 or id < 0 or id >= NEW_COUNT then
			return
		end
		local raw = bit.band(value, 0x3FF)
		local m = math.floor(value / 65536)
		mem.u1[block + MASTERY_OFF + p * NEW_COUNT + id] = m < 4 and 0 or m - 4
		local flags = {[0] = 0, [1] = 0, [2] = 1024, [3] = 2048, [4] = 4096}
		rawSet(pl, id, raw + (m > 4 and 4096 or flags[m] or 0))
	end,
	getName = getName,
	setName = setName,
	getDesc = getDesc,
	setDesc = setDesc,
	-- stage 2 will route this through the engine's buffed-value function;
	-- until then it returns the raw value (only used by the hint builder)
	get_buffed = function(pl, id)
		return rawGet(pl, id)
	end,
	new_misc = function(id)
		table.insert(Skills.Categories.misc, id)
		if MawCore.SkillsUI then
			MawCore.SkillsUI.append("misc", id)
		end
	end,
	new_weapon = function(id)
		table.insert(Skills.Categories.weapon, id)
		if MawCore.SkillsUI then
			MawCore.SkillsUI.append("weapon", id)
		end
	end,
	new_armor = function(id)
		table.insert(Skills.Categories.armor, id)
		if MawCore.SkillsUI then
			MawCore.SkillsUI.append("armor", id)
		end
	end,
	new_magic = function(id)
		table.insert(Skills.Categories.magic, id)
		if MawCore.SkillsUI then
			MawCore.SkillsUI.append("magic", id)
		end
	end,
	learn_at = function(id, house)
		if id < 0 or not house or house < 0 or house >= 36 then
			return false
		end
		Skills.ShopSkills[house] = Skills.ShopSkills[house] or {}
		for _, v in ipairs(Skills.ShopSkills[house]) do
			if v == id then
				return false
			end
		end
		table.insert(Skills.ShopSkills[house], id)
		return true
	end,
	MasteryLimit = function(pl, id)
		if id < 0 or id >= NEW_COUNT or playerId(pl) < 0 then
			return 0
		end
		local race = Game.CharacterPortraits[pl.Face].Race
		return masteryLimitRaw(race, pl.Class, id)
	end,
	MasteryTable_get = function(race, clas, skill)
		return masteryLimitRaw(race, clas, skill)
	end,
	-- NOTE: the legacy 00Skillz wrapper called MasteryLimit_raw here, which
	-- ignored the 4th argument -- MasteryTable_set never worked. This is the
	-- DLL's real MasteryLimit_set semantics (never called anywhere today).
	MasteryTable_set = function(race, clas, skill, token)
		if not skill or skill < 0 or skill >= NEW_COUNT then
			return false
		end
		if race < 0 and clas < 0 then
			return false
		end
		if race < 0 then
			-- DLL class branch accepts only 0/-, B, E, M, G (either case)
			local up = token:upper()
			local v
			if up == "0" or up == "-" then
				v = 0
			else
				v = LETTER[up]
				if not v or v > 4 then
					return false
				end
			end
			classM[clas] = classM[clas] or {}
			classM[clas][skill] = v
			return true
		end
		local m = parseModifier(token)
		if clas < 0 then
			raceM[race] = raceM[race] or {}
			raceM[race][skill] = m
		else
			extraM[race] = extraM[race] or {}
			extraM[race][clas] = extraM[race][clas] or {}
			extraM[race][clas][skill] = m
		end
		return true
	end,
	-- STAGE 1: deliberately inert. The real CleanMastery ZEROES every skill
	-- whose MasteryLimit is 0 -- destructive, so it stays off until the
	-- parsed MasteryLimit values are verified in-game against the DLL's.
	CleanMastery = function(pl)
		return 0
	end,
}

---------------------------------------------------------------- legacy bridge

-- The 00Skillz.lua wrapper, kept alive for the case where Skillz.dll is
-- still present (e.g. a player updated by unzipping over an old install).
-- The only file in MawCore besides Engine allowed to touch mem.* -- it is
-- quarantined legacy code that dies when the DLLs are gone everywhere.
local function dllWrapper()
	local function hlp(pl)
		if mem.dll.skillz.PlayerID(pl) < 0 then
			Message("Invalid player call for Skillz.dll")
		end
	end
	return {
		get = function(pl, id)
			hlp(pl)
			return mem.dll.skillz.get(pl, id)
		end,
		set = function(pl, id, v)
			hlp(pl)
			mem.dll.skillz.set(pl, id, v)
		end,
		get2 = function(pl, id)
			hlp(pl)
			return mem.dll.skillz.get2(pl, id)
		end,
		set2 = function(pl, id, v)
			hlp(pl)
			mem.dll.skillz.set2(pl, id, v)
		end,
		getName = function(id)
			return mem.string(mem.dll.skillz.getName(id))
		end,
		setName = function(id, s)
			mem.dll.skillz.setName(id, s)
		end,
		getDesc = function(id, part)
			return mem.string(mem.dll.skillz.getDesc(id, part))
		end,
		setDesc = function(id, part, s)
			mem.dll.skillz.setDesc(id, part, s)
		end,
		get_buffed = function(pl, id)
			hlp(pl)
			return mem.dll.skillz.get_buffed(pl, id)
		end,
		new_misc = function(id)
			mem.dll.skillz.new_misc(id)
		end,
		new_weapon = function(id)
			mem.dll.skillz.new_weapon(id)
		end,
		new_armor = function(id)
			mem.dll.skillz.new_armor(id)
		end,
		new_magic = function(id)
			mem.dll.skillz.new_magic(id)
		end,
		learn_at = function(id, house)
			mem.dll.skillz.learn_at(id, house)
		end,
		MasteryLimit = function(pl, id)
			hlp(pl)
			return mem.dll.skillz.MasteryLimit(pl, id)
		end,
		MasteryTable_get = function(race, clas, skill)
			return mem.dll.skillz.MasteryLimit_raw(race, clas, skill)
		end,
		MasteryTable_set = function(race, clas, skill, token)
			return mem.dll.skillz.MasteryLimit_set(race, clas, skill, token)
		end,
		CleanMastery = function(pl)
			return mem.dll.skillz.CleanMastery(pl)
		end,
	}
end

---------------------------------------------------------------- compat globals

-- (Race, Class, Skill) or (Player, Skill) -- called by base MMMerge scripts
local function GetMaxSkill(a, b, c)
	local race, clas, skill
	if type(a) == "number" then
		race, clas, skill = a, b, c
	else
		race, clas, skill = Game.CharacterPortraits[a.Face].Race, a.Class, b
	end
	return Skillz.MasteryTable_get(race, clas, skill)
end

---------------------------------------------------------------- activation

local startShared	-- assigned below Skills.start; runs in both modes

-- true when the Lua port owns the skill system (no Skillz.dll present)
function Skills.isActive()
	return active
end

function Skills.describe()
	local out = {"skills port:"}
	if not active then
		out[#out + 1] = "  INERT -- ExeMods\\Skillz.dll present, the DLL owns the skill system"
	else
		out[#out + 1] = ("  ACTIVE -- storage block at 0x%X"):format(block)
		out[#out + 1] = ("  tables: %d classes, %d races, %d skill rows"):format(
			#classNames + 1, #raceNames + 1, #skillNames + 1)
		out[#out + 1] = "  spot-check: print(Skillz.MasteryLimit(Party[0], 5))"
	end
	return table.concat(out, "\n")
end

function Skills.start()
	if dllPresent() then
		Skillz = dllWrapper()
		startShared(true)
		return
	end
	active = true
	local Engine = MawCore.Engine
	local A = Engine.Addr

	block = Engine.alloc(MASTERY_OFF + PLAYERS * NEW_COUNT)
	parseTables()

	-- the DLL's built-in category/shop presets (preset_shops + the four
	-- DialogLogic tables), recorded for the stage-3 UI hooks
	Skills.Categories.misc = {37, 35, 27, 24, 34, 38, 31, 28, 25, 29, 30, 26}
	Skills.Categories.weapon = {3, 5, 2, 6, 4, 0, 1, 33, 7}
	Skills.Categories.armor = {9, 10, 11, 8, 32}
	Skills.Categories.magic = {12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
	Skills.ShopSkills = {
		[1] = {1, 5, 3, 6, 0, 2, 4},
		[2] = {9, 10, 11, 8},
		[3] = {24, 26},
		[4] = {37, 34},
		[5] = {12}, [6] = {13}, [7] = {14}, [8] = {15}, [9] = {16},
		[10] = {17}, [11] = {18}, [12] = {19}, [13] = {20},
		[14] = {12, 13, 14, 15},
		[15] = {16, 17, 18},
		[21] = {36, 31, 29},
		[23] = {33, 32, 30, 25, 28},
		[30] = {35, 27, 38},
	}

	-- shared asm: raw skill for (ecx = player ptr, esi = skill id) -> eax.
	-- Base skills from the player struct, extended from our block.
	local getRaw = Engine.asmproc(string.format([[
		cmp esi, %d
		jge ext1
		movzx eax, word [ecx + esi*2 + 0x%X]
		retn
	ext1:
		cmp esi, %d
		jae bad1
		push ecx
		push edx
		mov eax, ecx
		sub eax, 0x%X
		js bad2
		xor edx, edx
		mov ecx, 0x%X
		div ecx
		test edx, edx
		jnz bad2
		cmp eax, %d
		jae bad2
		imul eax, eax, %d
		lea edx, [esi - %d]
		movzx eax, word [eax + edx*2 + 0x%X]
		jmp done1
	bad2:
		xor eax, eax
	done1:
		pop edx
		pop ecx
		retn
	bad1:
		xor eax, eax
		retn
	]], OLD_COUNT, A.PlayerSkillsOffset, NEW_COUNT, A.PlayerBase,
		A.PlayerStride, PLAYERS, SKILL_ROW, OLD_COUNT, block))

	-- name pointer array for all 128 skills, read by the SkillsUI asm shims.
	-- Base-skill entries stay NULL on purpose: the shims then fall back to
	-- the engine's LIVE name array (Merge re-points those per save load, so a
	-- snapshot would go stale). setName fills an entry when a skill is
	-- renamed, which overrides the fallback.
	namePtrs = Engine.alloc(NEW_COUNT * 4)

	-- internals for the SkillsUI module (stage 2)
	Skills.internal = {getRaw = getRaw, block = block, namePtrs = namePtrs}

	-- Skillz.dll hook 1 of stage 1: extended IDs answered from the block.
	-- Replaces the 8 bytes at 0x48EF55; base path replays them and falls
	-- through (asmpatch jumps back to 0x48EF5D).
	Engine.asmpatch("SkillzGetSkillBody",
		"Skillz port: GetSkill body answers extended skill IDs",
		A.GetSkillBodyHook, string.format([[
		cmp esi, %d
		jl std1
		mov eax, 0x%X
		call eax
		pop esi
		pop ebx
		retn
	std1:
		xor ebx, ebx
		cmp esi, 0x19
		push edi
		mov edi, ecx
	]], OLD_COUNT, getRaw), 8)

	-- Skillz.dll hook 2: the skill+item-bonus clamp. The engine caps the
	-- combined value at 60 within 6 bits; the DLL (and the mod's balance)
	-- needs 1023 within 10 bits. Structure mirrors the engine's original
	-- clamp exactly, 0x3FF for 0x3F. All paths retn (see header note).
	Engine.asmpatch("SkillzBonusClamp",
		"Skillz port: skill+bonus clamp raised from 60 to 1023",
		A.SkillBonusClampHook, string.format([[
		mov ecx, edi
		mov eax, 0x%X
		call eax
		mov ecx, eax
		and ecx, 0x3FF
		add ecx, ebx
		cmp ecx, 0x3FF
		jl low1
		and eax, 0xFFFFFC00
		add eax, 0x3FF
		jmp out1
	low1:
		test ecx, ecx
		jge pos1
		and eax, 0xFFFFFC00
		inc eax
	pos1:
		add eax, ebx
	out1:
		pop edi
		pop esi
		pop ebx
		retn
	]], getRaw), 8)

	-- persistence: vars is the save format; the block is the runtime copy
	function events.BeforeSaveGame()
		syncToVars()
	end
	function events.BeforeLoadMap(wasInGame)
		if not wasInGame then
			loadFromVars()
		end
	end

	-- take over the public API; from here every Skillz.* call runs in Lua
	Skillz = Skills.API
	startShared(false)
end

-- registrations that exist in both modes (absorbed from the removed
-- 00Skillz.lua / ZZZZ_Last.lua)
startShared = function(dllMode)
	GetMaxSkillLevel = GetMaxSkill
	GetMaxAvailableSkill = GetMaxSkill
	JoinSkill2 = function(sk, mas)
		return mas * 65536 + sk
	end
	SplitSkill2 = function(arg)
		local sk = arg % 65536
		return sk, (arg - sk) / 65536
	end

	if dllMode then
		function events.GameInitialized2()
			mem.dll.skillz.initPortraits(Game.CharacterPortraits)
		end
	end

	-- "workaround for a glitch" (ZZZZ_Last.lua; SKILLZ_PORT.md Q2). In Lua
	-- mode it only records 127 in the misc category for stage 3.
	function events.GameInitialized2()
		Skillz.new_misc(127)
	end

	-- mastery refund on the first load after a new game. In Lua mode
	-- CleanMastery is inert until stage 2, so this refunds nothing yet.
	function events.BeforeNewGameAutosave()
		vars.needToThankSkillz = true
	end
	function events.BeforeLoadMap(wasInGame)
		if wasInGame or vars.needToThankSkillz == nil then
			return
		end
		vars.needToThankSkillz = nil
		local refund = 0
		for _, pl in Party do
			refund = refund + Skillz.CleanMastery(pl)
		end
		refund = refund * 500
		if refund > 0 then
			Party.AddGold(refund)
		end
	end
end
