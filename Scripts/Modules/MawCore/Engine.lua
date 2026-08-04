-- Engine.lua -- the Tier-4 boundary (GREENFIELD.md par.7).
--
-- THE ONLY FILE IN MawCore ALLOWED TO TOUCH mem.*, raw addresses or struct
-- offsets. If another module needs something from the engine, it gets a named
-- function here. Keeping this file small is what would make any future
-- platform move a port instead of a rewrite.
--
-- Binary facts (GREENFIELD.md par.6 -- hard-won, do not re-derive):
--   * mm8.exe is the binary the game runs. MM8-Rel.exe is NOT -- its
--     addresses do not match. MM8.ICD is encrypted.
--   * Validate any new binary analysis against a known-good landmark before
--     trusting it. The check that works: the legacy mod hooks 0x42A171
--     inside SharedLife (spell 54); a correct derivation must reproduce that.

local Engine = {}
MawCore.Engine = Engine

-- Named addresses in mm8.exe. Every raw address used anywhere in MawCore
-- must be listed here, with how it was validated.
Engine.Addr = {
	-- spell dispatch (validated by the Sunray patch, commit 342f34ed):
	-- slot = byte[SpellSlotIndex + spellId - 1]
	-- handler = dword[SpellSlotTable + slot*4]
	SpellSlotIndex     = 0x42D679,
	SpellSlotTable     = 0x42D525,
	SpellCastSucceeded = 0x42C200,	-- shared continuation; d:push() it from a hook

	-- world state
	IndoorOrOutdoor    = 0x6F39A0,	-- 1 = indoor, 2 = outdoor (= Game.Map.IndoorOrOutdoor)

	-- party-hits-monster resolution: (attackerID, monIndex, speed, action).
	-- Statically confirmed as a real routine: 0x42DA44 in the player-attack
	-- path is a direct "call 0x436E26". The calling convention is still
	-- INFERRED from the Core/events.lua hookfunction registration; verify
	-- with the Cleave spike before relying on it.
	HitMonsterResolution = 0x436E26,

	-- MAW_Fixes.dll patch sites (see Fixes.lua):
	SkillHintRowFormat = 0x4F3BF8,	-- .data format string "%s\12%05u\t110%d\12..."
	RecoveryFloorPush  = 0x42DA51,	-- "push 30" clamping attack recovery; +1 = the immediate

	-- Skillz.dll port sites (see Skills.lua). The buffed-skill function at
	-- GetSkillFunction is wrapped by MMExtension's GetSkill event
	-- (Core/events.lua ~1901, hookfunction), whose dispatcher manages the
	-- stack around the body -- which is why patches INSIDE the body may exit
	-- with a plain retn, exactly as Skillz.dll has always done.
	GetSkillFunction    = 0x48EF4F,	-- entry: push ebx / push esi / mov esi,[esp+0xC]
	GetSkillBodyHook    = 0x48EF55,	-- 8 bytes: xor ebx,ebx / cmp esi,0x19 / push edi / mov edi,ecx
	SkillBonusClampHook = 0x48F056,	-- 8 bytes: movzx eax, word [edi+esi*2+0x378]
	PlayerBase          = 0xB2187C,	-- roster player 0 (from Skillz.dll, production-proven)
	PlayerStride        = 0x1D28,	-- sizeof(Player)
	PlayerSkillsOffset  = 0x378,	-- word array of 39 base skills inside Player
	SkillNamePtrArray   = 0xBB3060,	-- char* [39], base skill names
	-- char* [39] per description part (1=base text, 2..5 = N/E/M/G lines)
	SkillDescPtrArrays  = {0x5E4CB0, 0x5E4C10, 0x5E4B70, 0x5E4AD0, 0x5E4A30},
}

-- Ledger of every binary patch MawCore applies. Nothing in the core may
-- modify the exe without going through Engine.patch, so this list IS the
-- answer to "what have we changed in the binary".
Engine.Patches = {}

function Engine.patch(name, why, apply)
	table.insert(Engine.Patches, {name = name, why = why})
	apply()
end

-- Ledgered wrapper over mem.asmpatch: replaces `size` bytes at addr with a
-- jump to `code` (FASM), auto-returning to addr+size unless every path rets.
function Engine.asmpatch(name, why, addr, code, size)
	table.insert(Engine.Patches, {name = name, why = why})
	return mem.asmpatch(addr, code, size)
end

-- Standalone FASM routine in allocated memory; returns its address.
function Engine.asmproc(code)
	return mem.asmproc(code)
end

-- Permanently allocated zeroed-by-us buffer (mem.StaticAlloc).
function Engine.alloc(size)
	local p = mem.StaticAlloc(size)
	for i = 0, size - 4, 4 do
		mem.u4[p + i] = 0
	end
	return p
end

-- Single protected dword write (for pointer slots in engine data tables).
function Engine.writePtr(addr, value)
	mem.IgnoreProtection(true)
	mem.u4[addr] = value
	mem.IgnoreProtection(false)
end

function Engine.describe()
	local out = {"engine patches applied:"}
	for i, p in ipairs(Engine.Patches) do
		out[#out+1] = ("  %d. %s -- %s"):format(i, p.name, p.why)
	end
	if #Engine.Patches == 0 then
		out[#out+1] = "  (none)"
	end
	return table.concat(out, "\n")
end
