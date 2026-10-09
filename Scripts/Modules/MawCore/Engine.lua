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

	-- paper-doll item glow countdown, i4 (Modules/PaperDoll.lua ~507 names
	-- the same address EffectTime): decremented by Game.TimeDelta per doll
	-- draw, and at 0 that code clears the item's Condition 0xF0 nibble
	ItemEffectTime     = 0x51E100,

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

	-- shop item filter (see SpecialItems.lua). Validated against the merge,
	-- which jumps out of exactly these four sites in RemoveItemsLimits.lua
	-- to refuse items with Value 0 or Material 3.
	-- "does this shop take the item" (ecx = item, edx = house); one routine
	-- for repair, identify and sell, told apart by its three callers
	ShopItemCheck       = 0x4BB612,
	ShopRepairCall      = 0x4BB7ED,	-- call ShopItemCheck, dialog 5 (repair price, broken bit)
	ShopIdentifyCall    = 0x4BB913,	-- call ShopItemCheck, dialog 4 (identify price, identified bit)
	ShopSellCall        = 0x4BBA13,	-- call ShopItemCheck, dialog 3
	ShopCheckSites      = {0x4BB632, 0x4BB642},	-- item-number range tests; esi = number
	ShopCheckPass       = 0x4BB65A,
	ShopCheckRefuse     = 0x4BB6B6,	-- xor eax, eax: refused
	-- merchant sentence (ebx = item, [ebp+0x14] = action 3 sell / 4 identify /
	-- 5 repair); returns the MerchantTxt row, 5 = "Unnecessary"
	MerchantRowSites    = {0x49003C, 0x49004C},
	MerchantRowPass     = 0x490068,
	MerchantRowReturn   = 0x490096,	-- pop eax / return: jump here after a push

	-- free item record search (see Fixes.lua): thiscall on a player, returns
	-- the 0-based index of the first record with Number 0 among the first
	-- 126 of Items[138], or -1. Callers: pick up, evt.Add Items, shops,
	-- chests (0x46638E, 0x490EF6, 0x49102A, 0x4911B7 and others).
	FindFreeItemRecord  = 0x490ED3,
	PlayerItemsOffset   = 0x4A8,	-- Items[138] inside Player
	ItemSize            = 0x24,
	ItemBodyLocation    = 0x18,	-- i1: 0 = backpack, 1..16 = equipped slot
	PlayerItemRecords   = 138,
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

-- Starts the paper-doll glow on an item. `sprite` is Condition's 0xF0 nibble
-- (0x10 sptext01, 0x20 sp28a, 0x40 sp30a, 0x80 sp91a); PaperDoll.lua clears
-- it when the timer runs out, so callers never have to undo this.
function Engine.showItemEffect(it, sprite, time)
	mem.u4[Engine.Addr.ItemEffectTime] = time or 0x100
	it.Condition = it.Condition:Or(sprite or 0x10)
end

-- Replaces the merge's shop item test (refuse Value 0 or Material 3, i.e.
-- every "special" item for every service) with refuses(item, action, forText):
-- action 3 = sell, 4 = identify, 5 = repair; true refuses. forText is set when
-- the merchant's sentence is being chosen, which happens separately from the
-- click and must agree with it. The rest of the engine's test (stolen items,
-- shop type) still runs after a pass. onSold(item), if given, runs when the
-- whole test passed for a sale -- the engine then sells unconditionally
-- (ShopSellCall is followed by the sale itself), with the item still in place.
function Engine.setShopItemFilter(refuses, onSold)
	local A = Engine.Addr
	local action = Engine.alloc(4)	-- set by each caller of ShopItemCheck
	local function luaProc(f)
		local p = Engine.asmproc([[
			nop
			nop
			nop
			nop
			nop
			retn]])
		mem.hook(p, function(d)
			local ok, err = pcall(f, d)
			if not ok then
				print("shop item filter: " .. tostring(err))
				d.eax = 1
			end
		end)
		return p
	end
	local check = luaProc(function(d)
		d.eax = refuses(structs.Item:new(d.eax), d.edx, d.ecx ~= 0) and 1 or 0
	end)
	local sold = luaProc(function(d)
		if onSold then
			onSold(structs.Item:new(d.eax))
		end
	end)

	local callers = {[4] = A.ShopIdentifyCall, [5] = A.ShopRepairCall}
	for act, addr in pairs(callers) do
		local wrap = Engine.asmproc(string.format([[
			mov dword [0x%X], %d
			jmp absolute 0x%X]], action, act, A.ShopItemCheck))
		Engine.asmpatch("ShopItemCheckCaller" .. act, "shop filter: tell the check which service asks",
			addr, string.format("call absolute 0x%X", wrap), 5)
	end
	-- the sell caller also reports a passed test (eax kept for the caller)
	local wrap = Engine.asmproc(string.format([[
		mov dword [0x%X], 3
		push ecx
		call absolute 0x%X
		pop ecx
		test eax, eax
		jz sw_done
		push eax
		mov eax, ecx
		call absolute 0x%X
		pop eax
	sw_done:
		retn]], action, A.ShopItemCheck, sold))
	Engine.asmpatch("ShopItemCheckCaller3", "shop filter: sell test, and report the sale",
		A.ShopSellCall, string.format("call absolute 0x%X", wrap), 5)

	for i, addr in ipairs(A.ShopCheckSites) do
		Engine.asmpatch("ShopItemCheck" .. i, "shop filter: repair/identify/sell test",
			addr, string.format([[
			push eax
			push ecx
			push edx
			mov eax, ecx
			mov edx, [0x%X]
			xor ecx, ecx
			call absolute 0x%X
			test eax, eax
			pop edx
			pop ecx
			pop eax
			jnz absolute 0x%X
			jmp absolute 0x%X]], action, check, A.ShopCheckRefuse, A.ShopCheckPass), 5)
	end

	for i, addr in ipairs(A.MerchantRowSites) do
		Engine.asmpatch("MerchantRow" .. i, "shop filter: merchant sentence agrees with the click",
			addr, string.format([[
			push eax
			push ecx
			push edx
			mov eax, ebx
			mov edx, [ebp + 0x14]
			mov ecx, 1
			call absolute 0x%X
			test eax, eax
			pop edx
			pop ecx
			pop eax
			jz mr_pass
			push 5
			jmp absolute 0x%X
		mr_pass:
			jmp absolute 0x%X]], check, A.MerchantRowReturn, A.MerchantRowPass), 5)
	end
end

-- Lets the free item record search use all of a player's records, while
-- fewer than backpackCap(player) records hold backpack items (BodyLocation 0).
-- backpackCap gets the roster player; a pointer outside the roster gets
-- `fallback`.
function Engine.setBackpackItemCap(backpackCap, fallback)
	local A = Engine.Addr
	table.insert(Engine.Patches, {name = "FreeItemRecord",
		why = ("free item record search: all %d records, backpack items capped per player"):format(
			A.PlayerItemRecords)})
	mem.hookfunction(A.FindFreeItemRecord, 1, 0, function(d, def, pl)
		local index, cap = (pl - A.PlayerBase) / A.PlayerStride, fallback
		if index % 1 == 0 and index >= 0 and index < Party.PlayersArray.count then
			cap = backpackCap(Party.PlayersArray[index])
		end
		local free, inBackpack = -1, 0
		for i = 0, A.PlayerItemRecords - 1 do
			local p = pl + A.PlayerItemsOffset + i*A.ItemSize
			if mem.i4[p] == 0 then
				if free < 0 then
					free = i
				end
			elseif mem.u1[p + A.ItemBodyLocation] == 0 then
				inBackpack = inBackpack + 1
			end
		end
		if inBackpack >= cap then
			return -1
		end
		return free
	end)
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
