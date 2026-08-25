-- SkillsUI.lua -- Skillz.dll port, stage 2: the character screen.
--
-- Makes extended skills (39..127) appear and behave on the skill screen the
-- way the DLL did it, by the DLL's own mechanism:
--   1. The four skill-category tables (weapon/armor/misc/magic) that the
--      engine's list builders iterate are RELOCATED to our 128-entry arrays;
--      the instruction immediates that reference table start/end are
--      rewritten (same sites the DLL rewrote).
--   2. The list builders' skill-VALUE reads, skill-NAME pushes and
--      MASTERY-name pushes are patched to read our storage (asm only, no
--      Lua in the draw path).
--   3. The skill hint (clicking a row) is rebuilt in Lua at the two tail
--      hooks the DLL used, since it only runs on click.
--   4. Spending skill points on a row goes through pointer/value shims so
--      extended skills train exactly like base ones.
--
-- Every patch is a register-faithful translation of a Skillz.dll naked
-- function; patch sizes come from the DLL's own return addresses. Do not
-- adjust registers or sizes without re-reading the DLL source.
--
-- Deliberately NOT ported (see SKILLZ_PORT.md): char-creation hooks (no
-- extended starting skills exist -- engine originals are correct), the
-- 0x41714E color function (colors are computed in the Lua hint), desc-array
-- relocations (hints are Lua-built).

local SkillsUI = {}
MawCore.SkillsUI = SkillsUI

local OLD_COUNT = 39
local NEW_COUNT = 128

-- The four category tables were ALREADY relocated by MMMerge itself:
-- RemovePartyLimits.lua runs mem.ExtendGameStructure on Game.DialogLogic's
-- WeaponSkills/ArmorSkills/MiscSkills/MagicSkills, managing the same
-- instruction immediates the DLL used to fight over (delta-adjusted on every
-- Resize). So the port does NOT plant its own tables -- it grows Merge's.
local dlgArrays = {weapon = "WeaponSkills", armor = "ArmorSkills",
	misc = "MiscSkills", magic = "MagicSkills"}
local uiActive = false

local function arrCount(arr)
	local ok, n = pcall(function()
		return arr.Count
	end)
	if ok and type(n) == "number" then
		return n
	end
	ok, n = pcall(function()
		return #arr
	end)
	if ok and type(n) == "number" then
		return n
	end
	return nil
end

-- appends a skill id to one of Merge's DialogLogic skill arrays (the mod's
-- GameInitialized2 handlers call Skillz.new_armor etc. every session)
function SkillsUI.append(catName, id)
	if not uiActive then
		return
	end
	local arrName = dlgArrays[catName]
	if not arrName then
		return
	end
	local arr = Game.DialogLogic[arrName]
	local n = arrCount(arr)
	if not n then
		print("[SkillsUI] cannot read count of Game.DialogLogic." .. arrName)
		return
	end
	for i = 0, n - 1 do
		if arr[i] == id then
			return
		end
	end
	arr.Resize(n + 1)
	Game.DialogLogic[arrName][n] = id	-- re-fetch: Resize may relocate
end

function SkillsUI.describe()
	local out = {"skills UI (stage 2):"}
	if not uiActive then
		out[#out + 1] = "  INERT (DLL mode or Skills module inactive)"
	else
		for name, arrName in pairs(dlgArrays) do
			local arr = Game.DialogLogic[arrName]
			local n = arrCount(arr) or 0
			local ids = {}
			for i = 0, n - 1 do
				ids[#ids + 1] = arr[i]
			end
			out[#out + 1] = ("  %-8s %s"):format(name, table.concat(ids, ","))
		end
	end
	return table.concat(out, "\n")
end

function SkillsUI.start()
	local Skills = MawCore.Skills
	if not Skills.isActive() then
		return
	end
	local Engine = MawCore.Engine
	local A = Engine.Addr
	local I = Skills.internal
	local getRaw = I.getRaw
	local OFFSET = 0x7F000000	-- the DLL's "menu_skill_offset" topic encoding

	---------------------------------------------------------------- helpers

	-- pointer to a skill slot: base -> player struct, extended -> our block.
	-- in: ecx = player ptr, eax = skill id; out: eax = pointer (0 if bad)
	-- (label names must not collide with x86 mnemonics -- "pext" is one)
	local getPtr = Engine.asmproc(string.format([[
		cmp eax, %d
		jge gp_ext
		lea eax, [ecx + eax*2 + 0x%X]
		retn
	gp_ext:
		cmp eax, %d
		jae gp_bad0
		push ecx
		push edx
		push ebx
		mov ebx, eax
		mov eax, ecx
		sub eax, 0x%X
		js gp_bad
		xor edx, edx
		mov ecx, 0x%X
		div ecx
		test edx, edx
		jnz gp_bad
		cmp eax, %d
		jae gp_bad
		imul eax, eax, %d
		lea edx, [ebx - %d]
		lea eax, [eax + edx*2 + 0x%X]
		jmp gp_done
	gp_bad:
		xor eax, eax
	gp_done:
		pop ebx
		pop edx
		pop ecx
		retn
	gp_bad0:
		xor eax, eax
		retn
	]], OLD_COUNT, A.PlayerSkillsOffset, NEW_COUNT, A.PlayerBase,
		A.PlayerStride, 128, (NEW_COUNT - OLD_COUNT) * 2, OLD_COUNT, I.block))

	-- mastery of a skill: raw value -> engine mastery decode at 0x455B09.
	-- in: ecx = player ptr, esi = skill id; out: eax = mastery 0..4
	-- (beyond-Grand extra mastery intentionally omitted: nothing sets it yet)
	local masteryOf = Engine.asmproc(string.format([[
		push ecx
		push edx
		mov eax, 0x%X
		call eax
		mov ecx, eax
		mov eax, 0x455B09
		call eax
		pop edx
		pop ecx
		retn
	]], getRaw))

	-- mastery names (source: SkillTooltip.masteryNames) -- the engine's own
	-- four name slots redirected, exactly as the DLL's refresh_mastery_names did
	local mNames = MawCore.SkillTooltip.masteryNames
	local mNameArr = Engine.alloc(9 * 4)
	for i = 0, 8 do
		local s = mNames[i + 1]
		local buf = Engine.alloc(#s + 1)
		for j = 1, #s do
			mem.u1[buf + j - 1] = s:byte(j)
		end
		mem.u1[buf + #s] = 0
		mem.u4[mNameArr + i * 4] = buf
	end
	Engine.writePtr(0x601B04, mem.u4[mNameArr + 1 * 4])	-- Novice
	Engine.writePtr(0x601B08, mem.u4[mNameArr + 3 * 4])	-- Master
	Engine.writePtr(0x601B0C, mem.u4[mNameArr + 2 * 4])	-- Expert
	Engine.writePtr(0x6015C8, mem.u4[mNameArr + 4 * 4])	-- Grand

	local function mkcstr(s)
		local p = Engine.alloc(#s + 1)
		for j = 1, #s do
			mem.u1[p + j - 1] = s:byte(j)
		end
		return p
	end
	local unnamed = mkcstr("Unnamed Skill")

	------------------------------------------------- category tables

	uiActive = true

	-- replay category registrations recorded before UI start, then live-wire.
	-- Deferred to GameInitialized2: ExtendGameStructure's arrays are fully
	-- set up by then, and the mod's own new_* calls fire in the same event.
	function events.GameInitialized2()
		for name, t in pairs(Skills.Categories) do
			for _, id in ipairs(t) do
				SkillsUI.append(name, id)
			end
		end
	end

	------------------------------------------------- list builder value reads
	-- original 8 bytes: movzx edx, word [edi + edx*2 + 0x378]
	-- (player = edi, skill = edx, result -> edx; eax/ecx live)

	local valueShim = string.format([[
		push eax
		push ecx
		push esi
		mov ecx, edi
		mov esi, edx
		mov eax, 0x%X
		call eax
		movzx edx, ax
		pop esi
		pop ecx
		pop eax
	]], getRaw)
	Engine.asmpatch("SkillzUIValWeapon", "Skillz port: weapon list value read",
		0x418D82, valueShim, 8)
	Engine.asmpatch("SkillzUIValMagic", "Skillz port: magic list value read",
		0x419125, valueShim, 8)
	Engine.asmpatch("SkillzUIValArmor", "Skillz port: armor list value read",
		0x4194CF, valueShim, 8)
	Engine.asmpatch("SkillzUIValMisc", "Skillz port: misc list value read",
		0x419872, valueShim, 8)

	------------------------------------------------- list row name pushes
	-- original 7 bytes: push dword [esi*4 + name array] (skill = esi)

	-- our pointer array first; for base skills fall back to the engine's own
	-- name array (populated after General/ load, and kept fresh by setName)
	local nameShim = string.format([[
		mov eax, [0x%X + esi*4]
		test eax, eax
		jnz nm_ok
		cmp esi, %d
		jae nm_un
		mov eax, [0x%X + esi*4]
		test eax, eax
		jnz nm_ok
	nm_un:
		mov eax, 0x%X
	nm_ok:
		push eax
	]], I.namePtrs, OLD_COUNT, A.SkillNamePtrArray, unnamed)
	for n, addr in ipairs({0x418E07, 0x418E41, 0x4191B4, 0x4191EE,
			0x419554, 0x41958E, 0x4198F7, 0x419931}) do
		Engine.asmpatch("SkillzUIName" .. n, "Skillz port: skill name push",
			addr, nameShim, 7)
	end

	------------------------------------------------- list row mastery pushes
	-- original: push of the engine mastery name, 6 bytes (player local at
	-- [ebp-0x48], skill at [ebp-0x20]). Patch EXACTLY those 6 bytes: the
	-- engine's mov esi,[ebp-0x20] at +6 is a jump target (the other mastery
	-- branches of each list jump straight to it). The shim loads esi itself;
	-- the engine's reload after the trampoline is redundant but harmless.

	local masteryShim = string.format([[
		mov esi, [ss:ebp - 0x20]
		push ecx
		push edx
		mov ecx, [ss:ebp - 0x48]
		mov eax, 0x%X
		call eax
		pop edx
		pop ecx
		push dword [eax*4 + 0x%X]
	]], masteryOf, mNameArr)
	for n, addr in ipairs({0x418DFE, 0x4191AB, 0x41954B, 0x4198EE}) do
		Engine.asmpatch("SkillzUIMastery" .. n, "Skillz port: mastery name push",
			addr, masteryShim, 6)
	end

	------------------------------------------------- skill point spending
	-- 0x43233F: pointer to the clicked skill slot (player=ecx, skill=eax -> esi)
	Engine.asmpatch("SkillzUISpendPtr", "Skillz port: skill slot pointer on spend",
		0x43233F, string.format([[
		push edx
		push ecx
		mov esi, 0x%X
		call esi
		mov esi, eax
		pop ecx
		pop edx
		xor eax, eax
	]], getPtr), 9)

	-- 0x43236B: value read on spend (player=ecx, skill=eax -> eax)
	Engine.asmpatch("SkillzUISpendVal", "Skillz port: skill value read on spend",
		0x43236B, string.format([[
		push ecx
		push esi
		mov esi, eax
		mov eax, 0x%X
		call eax
		pop esi
		pop ecx
	]], getRaw), 8)

	-- 0x4C9EB1: value read (player=edi, skill=eax -> eax)
	Engine.asmpatch("SkillzUIRead4C9EB1", "Skillz port: skill value read",
		0x4C9EB1, string.format([[
		push ecx
		push esi
		mov ecx, edi
		mov esi, eax
		mov eax, 0x%X
		call eax
		pop esi
		pop ecx
	]], getRaw), 8)

	------------------------------------------------- hint window (click a row)
	-- pre-tail control flow reads (extended values must flow so the right
	-- branch is taken); registers per the DLL source

	-- 0x41728C, 29 bytes (player=esi, skill=ebx, result -> ecx; eax compared)
	Engine.asmpatch("SkillzUIHintCmp", "Skillz port: hint branch skill compare",
		0x41728C, string.format([[
		and byte [ss:ebp - 0x84], 0
		push eax
		push edx
		push esi
		mov ecx, esi
		mov esi, ebx
		mov eax, 0x%X
		call eax
		pop esi
		movzx ecx, ax
		pop edx
		pop eax
		and eax, 0x3FF
		push 0x4F3BB8
		and ecx, 0x3FF
		xor eax, ecx
	]], getRaw), 29)

	-- 0x417295, 7 bytes (player=esi, skill=ebx -> ecx; eax live)
	Engine.asmpatch("SkillzUIHintRead1", "Skillz port: hint value read",
		0x417295, string.format([[
		push eax
		push esi
		mov ecx, esi
		mov esi, ebx
		mov eax, 0x%X
		call eax
		pop esi
		mov ecx, eax
		pop eax
	]], getRaw), 7)

	-- 0x417417, 7 bytes (player=edi, skill=ebx -> eax; ecx live)
	Engine.asmpatch("SkillzUIHintRead2", "Skillz port: hint value read 2",
		0x417417, string.format([[
		push ecx
		push esi
		mov ecx, edi
		mov esi, ebx
		mov eax, 0x%X
		call eax
		pop esi
		pop ecx
	]], getRaw), 7)

	-- 0x41745C, 15 bytes: buffed via engine call (arg pre-pushed by engine),
	-- then raw read (player=edi, skill=ebx); both masked to 10 bits
	Engine.asmpatch("SkillzUIHintBuffed", "Skillz port: hint buffed/raw compare",
		0x41745C, string.format([[
		mov eax, 0x%X
		call eax
		push eax
		push esi
		mov ecx, edi
		mov esi, ebx
		mov eax, 0x%X
		call eax
		mov ecx, eax
		pop esi
		pop eax
		and eax, 0x3FF
		and ecx, 0x3FF
	]], A.GetSkillFunction, getRaw), 15)

	-- the two tails: hint text is rebuilt in Lua (click-time, no perf cost)
	local HINT_CAP = 4096
	local hintBuf = Engine.alloc(HINT_CAP)

	local function writeHint(playerPtr, skillId, withBonus)
		local pl = Party[math.max(Game.CurrentPlayer, 0)]
		local text = MawCore.SkillTooltip.getTooltipText(pl, skillId, withBonus)
		if #text > HINT_CAP - 1 then
			text = text:sub(1, HINT_CAP - 1)
		end
		for j = 1, #text do
			mem.u1[hintBuf + j - 1] = text:byte(j)
		end
		mem.u1[hintBuf + #text] = 0
	end

	local function hintTail(addr, withBonus, ledgerName)
		-- We cut the builder short MID-BODY, so this stub is its epilogue --
		-- but esp here is NOT where it is at the real exit (0x417653), because
		-- the body has call arguments and temporaries below the saved regs.
		-- So we cannot pop: any pop order grabs whatever is on top right now.
		-- Restore from fixed frame offsets instead and let leave reset esp.
		--   0x4171E0: push ebp / mov ebp,esp / sub esp,0x534 / push ebx / push esi
		--   => saved ebx at [ebp-0x538], saved esi at [ebp-0x53C]
		-- ebp is a true frame pointer here and is never reloaded in the body,
		-- so this is correct at any cut point. (0x417653 pops esi then ebx,
		-- confirming both the registers and that the exit is a plain retn.)
		local code = Engine.asmproc(string.format([[
			nop
			nop
			nop
			nop
			nop
			mov eax, 0x%X
			mov esi, [ebp - 0x53C]
			mov ebx, [ebp - 0x538]
			leave
			retn
		]], hintBuf))
		Engine.asmpatch(ledgerName, "Skillz port: hint text built in Lua",
			addr, ("jmp absolute 0x%X"):format(code), 6)
		mem.hook(code, function(d)
			local ok, err = pcall(writeHint, d.esi, bit.band(d.ebx, 0xFF), withBonus)
			if not ok then
				-- never let a Lua error escape into the asm path: show it
				local msg = "hint error: " .. tostring(err)
				for j = 1, math.min(#msg, HINT_CAP - 1) do
					mem.u1[hintBuf + j - 1] = msg:byte(j)
				end
				mem.u1[hintBuf + math.min(#msg, HINT_CAP - 1)] = 0
			end
		end)
	end
	hintTail(0x4172C1, true, "SkillzUIHintTailBonus")
	hintTail(0x4174DD, false, "SkillzUIHintTail")

	-- 0x417708, 12 bytes: the hover-hint title. This guarded the skill id
	-- across the call to the hint builder (0x4171E0) because the tail stub
	-- used to leave esi clobbered with the player pointer. The stub now
	-- restores esi properly, so the guard is redundant -- kept because it is
	-- also what the DLL did, and it is harmless.
	Engine.asmpatch("SkillzUIHintName1",
		"Skillz port: hover hint title, skill id guarded across text build",
		0x417708, string.format([[
		push edx
		push esi
		mov eax, 0x4171E0
		call eax
		pop esi
		mov ecx, [0x%X + esi*4]
		test ecx, ecx
		jnz hv_ok
		cmp esi, %d
		jae hv_un
		mov ecx, [0x%X + esi*4]
		test ecx, ecx
		jnz hv_ok
	hv_un:
		mov ecx, 0x%X
	hv_ok:
		pop edx
	]], I.namePtrs, OLD_COUNT, A.SkillNamePtrArray, unnamed), 12)

	-- 0x416B8A: mov edi, [eax*4+names] -- the right-click hint WINDOW title
	-- (skill id from [ebp-4]; the sibling read at 0x416B3F is the
	-- char-creation picker branch, base skills only, left untouched)
	Engine.asmpatch("SkillzUIHintName2", "Skillz port: right-click hint title",
		0x416B8A, string.format([[
		mov edi, [0x%X + eax*4]
		test edi, edi
		jnz hw_ok
		cmp eax, %d
		jae hw_un
		mov edi, [0x%X + eax*4]
		test edi, edi
		jnz hw_ok
	hw_un:
		mov edi, 0x%X
	hw_ok:
	]], I.namePtrs, OLD_COUNT, A.SkillNamePtrArray, unnamed), 7)

	------------------------------------------------- house Learn-Skills dialog
	-- The Instructor/shop "learn skill" list. Topic encoding follows the
	-- DLL: 0x7F000000 + skill id ("menu_skill_offset"), because 36+id (the
	-- engine's scheme) collides with real house commands for ids >= 39.
	-- Extended topics are OFFSET-encoded; base topics keep the engine's 36+id
	-- (mixed encoding, tolerant decode in the gates).

	local function playerByPtr(ptr)
		for i = 0, Party.High do
			if Party[i]["?ptr"] == ptr then
				return Party[i]
			end
		end
		return Party[math.max(Game.CurrentPlayer, 0)]
	end

	-- a class/mastery gate that must consult the Lua-parsed tables: asm stub
	-- with a mem.hook that sets eax = MasteryLimit (dialog-time, no perf cost).
	-- Topic encoding is MIXED: base skills keep the engine's 36+id, only the
	-- extended extras use OFFSET+id -- so the decode is tolerant of both.
	-- prefix/prefixSize: optional asm replayed before the decode, for sites
	-- where the replaced range itself loads the player or the topic param.
	local function luaGate(name, why, addr, size, jmpBack, subReg, skillReg, playerReg, prefix, prefixSize)
		local code = Engine.asmproc((prefix or "") .. string.format([[
			cmp %s, 0x%X
			jge lg_ext
			sub %s, 0x24
			jmp lg_id
		lg_ext:
			sub %s, 0x%X
		lg_id:
			nop
			nop
			nop
			nop
			nop
			cmp eax, 0
			jmp absolute 0x%X
		]], subReg, OFFSET, subReg, subReg, OFFSET, jmpBack))
		Engine.asmpatch(name, why, addr, ("jmp absolute 0x%X"):format(code), size)
		-- decode block above is 19 bytes: cmp(6) jge(2) sub(3) jmp(2) sub(6)
		mem.hook(code + 19 + (prefixSize or 0), function(d)
			local ok, lim = pcall(function()
				return MawCore.Skills.API.MasteryLimit(
					playerByPtr(d[playerReg]), d[skillReg])
			end)
			d.eax = ok and lim or 0
		end)
	end

	-- display list, first variant (player=esi, topic=edi)
	luaGate("SkillzUILearnGate1", "Skillz port: learn list class gate",
		0x4B32E3, 19, 0x4B32F6, "edi", "edi", "esi")
	-- display list, second variant (player=esi, topic=ebx)
	luaGate("SkillzUILearnGate2", "Skillz port: learn list class gate 2",
		0x4B33DF, 19, 0x4B33F2, "ebx", "ebx", "esi")
	-- click-time gate (player=ecx, topic=ebp); ebp stays = skill id after
	luaGate("SkillzUILearnGate3", "Skillz port: learn click class gate",
		0x4BAF64, 15, 0x4BAF73, "ebp", "ebp", "ecx")

	-- known-skill checks: value via storage, ZF drives the skip branch
	Engine.asmpatch("SkillzUILearnKnown1", "Skillz port: learn list known check",
		0x4B32FA, string.format([[
		push eax
		push ecx
		push esi
		mov ecx, esi
		mov esi, edi
		mov eax, 0x%X
		call eax
		pop esi
		pop ecx
		test eax, eax
		pop eax
	]], getRaw), 8)
	Engine.asmpatch("SkillzUILearnKnown2", "Skillz port: learn list known check 2",
		0x4B33F6, string.format([[
		push eax
		push ecx
		push esi
		mov ecx, esi
		mov esi, ebx
		mov eax, 0x%X
		call eax
		pop esi
		pop ecx
		test eax, eax
		pop eax
	]], getRaw), 8)

	-- topic names in the learn list
	Engine.asmpatch("SkillzUILearnName1", "Skillz port: learn topic name",
		0x4B3304, string.format([[
		mov edx, [0x%X + edi*4]
		test edx, edx
		jnz ln1_ok
		cmp edi, %d
		jae ln1_un
		mov edx, [0x%X + edi*4]
		test edx, edx
		jnz ln1_ok
	ln1_un:
		mov edx, 0x%X
	ln1_ok:
	]], I.namePtrs, OLD_COUNT, A.SkillNamePtrArray, unnamed), 7)
	Engine.asmpatch("SkillzUILearnName2", "Skillz port: learn topic name 2",
		0x4B3406, string.format([[
		push eax
		mov eax, ebx
		mov ebx, [0x%X + eax*4]
		test ebx, ebx
		jnz ln2_ok
		cmp eax, %d
		jae ln2_un
		mov ebx, [0x%X + eax*4]
		test ebx, ebx
		jnz ln2_ok
	ln2_un:
		mov ebx, 0x%X
	ln2_ok:
		pop eax
	]], I.namePtrs, OLD_COUNT, A.SkillNamePtrArray, unnamed), 7)

	-- SHOP learn-skill list: weapon/armor/magic/alchemy shops draw their learn
	-- topics in a separate engine function from the training hall one above.
	-- Same three patterns as the training hall: class gate, known check, name.

	-- first variant: topic already in esi (loaded at 0x4B3F53); the replaced
	-- range starts with the engine's own player load, replayed as the prefix
	luaGate("SkillzUIShopGate1", "Skillz port: shop learn list class gate",
		0x4B3F56, 21, 0x4B3F6B, "esi", "esi", "ecx",
		"mov ecx, [ebp-0x14]\n", 3)
	-- second variant: the topic read [esi+0x24] is inside the replaced range;
	-- ecx already holds the player (loaded at 0x4B4046)
	luaGate("SkillzUIShopGate2", "Skillz port: shop learn list class gate 2",
		0x4B404B, 21, 0x4B4060, "edi", "edi", "ecx",
		"mov edi, [esi+0x24]\n", 3)

	-- known checks (player=eax; skill already in esi / moved from edi)
	Engine.asmpatch("SkillzUIShopKnown1", "Skillz port: shop learn known check",
		0x4B3F70, string.format([[
		push eax
		push ecx
		push esi
		mov ecx, eax
		mov eax, 0x%X
		call eax
		pop esi
		pop ecx
		test eax, eax
		pop eax
	]], getRaw), 8)
	Engine.asmpatch("SkillzUIShopKnown2", "Skillz port: shop learn known check 2",
		0x4B4065, string.format([[
		push eax
		push ecx
		push esi
		mov ecx, eax
		mov esi, edi
		mov eax, 0x%X
		call eax
		pop esi
		pop ecx
		test eax, eax
		pop eax
	]], getRaw), 8)

	-- topic names
	Engine.asmpatch("SkillzUIShopName1", "Skillz port: shop learn topic name",
		0x4B3F7A, string.format([[
		mov edx, [0x%X + esi*4]
		test edx, edx
		jnz sh1_ok
		cmp esi, %d
		jae sh1_un
		mov edx, [0x%X + esi*4]
		test edx, edx
		jnz sh1_ok
	sh1_un:
		mov edx, 0x%X
	sh1_ok:
	]], I.namePtrs, OLD_COUNT, A.SkillNamePtrArray, unnamed), 7)
	Engine.asmpatch("SkillzUIShopName2", "Skillz port: shop learn topic name 2",
		0x4B4075, string.format([[
		push eax
		mov eax, edi
		mov edi, [0x%X + eax*4]
		test edi, edi
		jnz sh2_ok
		cmp eax, %d
		jae sh2_un
		mov edi, [0x%X + eax*4]
		test edi, edi
		jnz sh2_ok
	sh2_un:
		mov edi, 0x%X
	sh2_ok:
		pop eax
	]], I.namePtrs, OLD_COUNT, A.SkillNamePtrArray, unnamed), 7)

	-- click routing ranges: extended topics take the skill path, per the DLL
	-- (which also deliberately dropped the engine's ==0x5E special case)
	Engine.asmpatch("SkillzUILearnRange1", "Skillz port: learn click range",
		0x4BAE92, string.format([[
		cmp ebp, 0x%X
		jge lr1_done
		cmp ebp, 0x5F
		jle lr1_ne
		jmp absolute 0x4BB249
	lr1_ne:
		jne lr1_done
		jmp absolute 0x4BAFD8
	lr1_done:
	]], OFFSET), 15)
	Engine.asmpatch("SkillzUILearnRange2", "Skillz port: learn click range 2",
		0x4BAEE8, string.format([[
		cmp ebp, 0x%X
		jl lr2_a
		jmp absolute 0x4BAF2E
	lr2_a:
		cmp ebp, 0x24
		jge lr2_b
		jmp absolute 0x4BB3F0
	lr2_b:
		cmp ebp, 0x38
		jg lr2_c
		jmp absolute 0x4BAF2E
	lr2_c:
		cmp ebp, 0x3B
		jg lr2_d
		jmp absolute 0x4BB3F0
	lr2_d:
		cmp ebp, 0x4A
		jg lr2_e
		jmp absolute 0x4BAF2E
	lr2_e:
	]], OFFSET), 37)
	Engine.asmpatch("SkillzUILearnRange3", "Skillz port: learn click range 3",
		0x4BB6F7, string.format([[
		mov eax, [0xFFD408]
		cmp eax, 0x%X
		jl lr3_std
		jmp absolute 0x4BBCBE
	lr3_std:
		cmp eax, 0x38
	]], OFFSET), 8)

	-- the learn write target: pointer into our storage for extended skills
	-- (player=edi, skill=ebp -> ebp = slot pointer)
	Engine.asmpatch("SkillzUILearnPtr", "Skillz port: learn write pointer",
		0x4BAF79, string.format([[
		push eax
		push ecx
		mov ecx, edi
		mov eax, ebp
		mov ebp, 0x%X
		call ebp
		mov ebp, eax
		pop ecx
		pop eax
	]], getPtr), 7)

	-- topic injection: base entries stay engine-encoded; only the extras
	-- recorded by Skillz.learn_at are appended, OFFSET-encoded (the event's
	-- core adds 36 to every entry, hence the -36 here). zzMAW-Skills data:
	-- Cover at Training halls, Mana Shield/Enlightenment at Magic shops.
	function events.PopulateLearnSkillsDialog(t)
		local r = t.Result
		for _, id in ipairs(Skills.ShopSkills[t.PicType] or {}) do
			if id >= OLD_COUNT then
				r[#r + 1] = OFFSET - 36 + id
			end
		end
	end
end
