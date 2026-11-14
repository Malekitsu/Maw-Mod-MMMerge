
do
	-- Hook registers come back as SIGNED i4 (RSMem: i4 returns n-0x100000000
	-- for n >= 0x80000000) while ["?ptr"] is an unsigned address. Subtracting
	-- them mixes the two conventions, so any pointer past 2GB makes the
	-- difference wrap by 2^32 and the index lands wildly out of bounds.
	local function asPointer(v)
		if v < 0 then
			return v + 0x100000000
		end
		return v
	end

	local function getSFTItem(p)
		local i = (asPointer(p) - Game.SFTBin.Frames["?ptr"]) / Game.SFTBin.Frames[0]["?size"]
		return Game.SFTBin.Frames[i]
	end

	-- cosmetic change: some monsters (mainly bosses) can be larger
	local scaleHook = function(indoor)
		return function(d)
			local t = {Scale = d.eax, Frame = getSFTItem(d.ebx)}
			t.MonsterIndex, t.Monster = internal.GetMonster(asPointer(indoor and d.edi or (d.edi - 0x9A)))
			events.call("MonsterSpriteScale", t)
			d.eax = t.Scale
		end
	end

	-- outdoor
	mem.autohook2(0x47AC26, scaleHook())
	mem.autohook2(0x47AC46, scaleHook())

	-- indoor
	mem.autohook2(0x43D02E, scaleHook(true))
	mem.autohook2(0x43D04D, scaleHook(true))
end


-- make strafe speed always half of forward speed
--   currently strafe speed is always half of forward walking speed
--   this doubles running strafe speed
--   this quadruples flying running strafe speed
do
	local hooks = HookManager()
	do
		local function asmpatch(p, code, size)
			-- workaround for the fact that mem.asmpatch doesn't currently handle
			-- the case when GetInstructionSize(p) < GetHookSize(p) correctly
			local size1 = mem.GetInstructionSize(p)
			local size2 = size or mem.GetHookSize(p)
			if size1 < size2 then
				mem.nop(p, size1)
			end
			return mem.asmhook(p, code, size2)
		end
		local function patch(p, code)
			return hooks.AddEx(true, asmpatch, p, code)
		end



		local code = [[
			test byte ptr [0xb21730], 0x2
			jnz @f
			sar eax, 0x1
		@@:
		]]

		patch(0x471a15, code)
		patch(0x471a45, code)
		patch(0x471a84, code)
		patch(0x471ab4, code)

		code = [[
			test byte ptr [0xb21730], 0x2
			jnz @running
			sar eax, 0x1
			jmp @f
		@running:
			cmp dword ptr [0xb215a4], 0x0
			jz @f
			shl eax, 0x1
		@@:
		]]

		patch(0x472cea, code)
		patch(0x472d18, code)
		patch(0x472d59, code)
		patch(0x472d87, code)
	end

	function events.GameInitialized1()
		hooks.Switch(fasterStrafing)
	end
end


-- make moving backwards always the same speed as moving forwards
--   this was aready the case when walking and flying, so this only adjusts running while on the ground
if false then
	local hooks = HookManager()
	do
		local code = [[
			shl eax, 0x1
		]]
		hooks.asmhook(0x471c2f, code)
		hooks.asmhook(0x471c64, code)

		code = [[
			cmp dword ptr [ebp - 0x38], 0x0
			jz @shift
			cmp dword ptr [ebp - 0x60], 0x0
			jz @f
		@shift:
			shl eax, 0x1
		@@:
		]]
		hooks.asmhook(0x473044, code)
		hooks.asmhook(0x473078, code)
	end

	function events.GameInitialized1()
		hooks.Switch(fasterBackpedaling)
	end
end

do
	local hooks = HookManager()
	do
		local code = [[
			sar eax, 0x1
		]]
		hooks.asmhook(0x471ae9, code)
		hooks.asmhook(0x471b86, code)

		hooks.asmhook(0x472e1f, code)
		hooks.asmhook(0x472e53, code)

		code = [[
			cmp dword ptr [ebp - 0x38], 0x0
			jz @f
			cmp dword ptr [ebp - 0x60], 0x0
			jnz @f
			sar eax, 0x1
		@@:
		]]

		hooks.asmhook(0x473044, code)
		hooks.asmhook(0x473078, code)

		-- handle flying
		hooks.AddMem(0x472ffa, 1)
		hooks.AddMem(0x473031, 1)
		mem.IgnoreProtection(true)
		mem.u1[0x472ffa] = 0x1
		mem.u1[0x473031] = 0x1
		mem.IgnoreProtection(false)
	end

	function events.GameInitialized1()
		hooks.Switch(slowerBackpedaling)
	end
end

local function safeGet(get, p)
	if type(p) ~= "number" or p == 0 then
		return nil, nil
	end
	local ok, index, obj = pcall(get, p)
	if ok then
		return index, obj
	end
	return nil, nil
end

mem.hookfunction(0x4256DB, 0, 4, function(d, def, this, mon, range, bonus)
	local t = {
		Range = range,
		Bonus = bonus,
		Result = def(this, mon, range, bonus) ~= 0,
	}
	t.PlayerIndex, t.Player = safeGet(internal.GetPlayer, this)
	t.MonsterIndex, t.Monster = safeGet(internal.GetMonster, mon)
	local engineResult = t.Result
	--your own formula gets first refusal; returning nil keeps the engine roll
	local customChance
	if t.Player and t.Monster and MawCore and MawCore.Formulas
			and MawCore.Formulas.mawPlayerHitChance then
		customChance = MawCore.Formulas.mawPlayerHitChance(t.Player, t.Monster, range, bonus)
		if customChance then
			t.Result = customChance >= math.random()
		end
	end
	--event handlers still have the final say
	events.cocalls("PlayerHitOrMiss", t)
	return t.Result and 1 or 0
end)

-- temple main screen: the engine splits the free space by the number of
-- visible topics with no zero check (idiv edi at 0x4b5d85)
mem.asmhook(0x4b5d84, [[
test edi, edi
jnz @ok
inc edi
@ok:
]])

-- UI message loop (0x43318b): ebx, esi and edi are constants for the whole
-- function. Something run while handling a message can hand them back
-- changed and the next message then reads Party through garbage (crash at
-- 0x4026F8). Put them back at every loop head and log the message that did it.
MawRegisterGuardHits = 0
local GUARD_LOG_LIMIT = 20
mem.autohook(0x4331aa, function(d)
	if d.edi == 0xB20E90 and d.esi == 0xFEB360 and d.ebx == 0 then
		return
	end
	MawRegisterGuardHits = MawRegisterGuardHits + 1
	if MawRegisterGuardHits <= GUARD_LOG_LIMIT then
		local f = io.open("MawRegisterGuard.log", "a")
		if f then
			f:write(string.format("%s action %s: ebx=%s esi=%s edi=%s map=%s\n",
				os.date("%Y-%m-%d %H:%M:%S"), tostring(mem.i4[d.esp + 0x1c]),
				tostring(d.ebx), tostring(d.esi), tostring(d.edi), tostring(Map and Map.Name)))
			f:close()
		end
	end
	d.edi, d.esi, d.ebx = 0xB20E90, 0xFEB360, 0
end)

--items and corpses dropped into liquid no longer disappear (rescueLiquidDrops setting).
--items: the object sweep destroys them over liquid at three sites -- indoor delete tail
--(call at 0x470755), outdoor rest-on-burn (0x470806) and liquid contact (0x471047).
--splash + delete must be suppressed together: delete-only suppression re-enters the
--branch every frame and spawns a splash per frame. survivors come to rest at the liquid
--surface, visible and clickable.
--corpses are MapMonsters records (Z +0x9a, VelocityZ +0xa0, AIState +0xb8; +0x92 is
--BodyHeight). the monster pass dissolves them over liquid at the splash tail (four
--AIState je's at 0x46f882/8c/96/a0 -> 0x46fe7a) and three bare Removed writes guarded
--by liquid-tile tests (0x46e7bf, 0x46ea6a, 0x46f2ce).
--an autohook skip branch must d:push its resume address (MM8 Blaster idiom) or it
--returns through stack garbage (eip = 0xa when first tried).
--missiles and attached objects stay vanilla. multiplayer installs the set on every
--peer and the host's ini value governs: LoadMap seeds it into vars.MAWSETTINGS, which
--MawCore.Sync mirrors to clients. the set is released and reinstalled when the flag
--flips rather than gated per callback, because Switch off nils the autohook dispatch
--entries and frees their copycode blocks (off bytes cannot be rearmed).

do
	--keep only plain ground items: everything the party loses to water is ground loot;
	--missiles also carry an Item.Number (the launching weapon), hence the Missile gate.
	local function tryPreserve(idx)
		local obj = Map.Objects[idx]
		if obj.Removed then
			return false
		end
		if obj.Item.Number == 0 then
			return false
		end
		return not (obj.Missile or obj.AttachToHead)
	end

	--sites 2-4: skip each bare Removed write and resume at its flag-failed continuation.
	local function holdCorpse(d, resume)
		d:push(resume)
		return true
	end

	local function install()
		local hooks = HookManager()

		--indoor delete tail (ecx = slot); shared with the out-of-map deletes, which the
		--coordinate gate leaves vanilla.
		hooks.autohook(0x470755, function(d)
			local obj = Map.Objects[d.ecx]
			local x, y, z = obj.X, obj.Y, obj.Z
			if x < -32767 or x > 32767 or y < -32767 or y > 32767 or z < -20000 or z > 20000 then
				return false
			end
			if not tryPreserve(d.ecx) then
				return false
			end
			d:push(0x47075a)
			return true
		end)

		--rest-on-burn: splash push/call + delete together (0xe bytes), slot at [ebp-0x20].
		hooks.autohook(0x470806, function(d)
			if not tryPreserve(mem.u4[d.ebp - 0x20]) then
				return false
			end
			d:push(0x470814)
			return true
		end, 0xe)

		--liquid contact: same block (0xd bytes), slot in edi.
		hooks.autohook(0x471047, function(d)
			if not tryPreserve(d.edi) then
				return false
			end
			d:push(0x471054)
			return true
		end, 0xd)

		--site 1: the tail computes the liquid plane into eax (groundZ + 0x3c water, +0x1e lava)
		--right before splash + Removed. pin Z = max(Z, plane), zero VelocityZ, and skip the rest
		--of the tail by resuming at 0x46f920, just past this iteration's X/Y/Z move block; the
		--branch re-enters every frame the corpse stays over liquid, so it is re-pinned at the
		--waterline instead of settling on the lakebed. no ai gate: the je's above admit only the
		--dead-ish states, and only Dying(4)/Dead(5) can actually reach them.
		hooks.autohook(0x46fe8a, function(d)
			local plane = d.eax
			if mem.i2[d.esi + 0x9a] < plane then
				mem.i2[d.esi + 0x9a] = plane
			end
			mem.i2[d.esi + 0xa0] = 0
			d:push(0x46f920)
			return true
		end, 0xf)

		hooks.autohook(0x46e7bf, function(d)
			return holdCorpse(d, 0x46efbd)
		end, 9)
		hooks.autohook(0x46ea6a, function(d)
			return holdCorpse(d, 0x46ea78)
		end, 9)
		hooks.autohook(0x46f2ce, function(d)
			return holdCorpse(d, 0x46f2dc)
		end, 9)
		return hooks
	end

	--the set exists while the flag is on: ini for singleplayer and the host, the host's
	--mirrored copy for clients (nil -> off until MawCore.Sync delivers it).
	local function effective()
		if MawCore.Sync.inGame() and not MawCore.Sync.isHost() then
			return vars.MAWSETTINGS and vars.MAWSETTINGS.rescueLiquidDrops
		end
		return rescueLiquidDrops
	end

	local hooks
	local function sync()
		local on = effective()
		if (hooks == nil) == (not on) then
			return
		end
		if on then
			hooks = install()
		else
			hooks.Clear()
			hooks = nil
		end
	end

	function events.GameInitialized1()
		sync()
	end

	--host/SP only: clients must not overwrite the mirrored value with their own ini.
	function events.LoadMap()
		if vars and (not MawCore.Sync.inGame() or MawCore.Sync.isHost()) then
			vars.MAWSETTINGS = vars.MAWSETTINGS or {}
			vars.MAWSETTINGS.rescueLiquidDrops = rescueLiquidDrops
		end
	end

	--multiplayer starts and ends without a script reload (as in the online module);
	--a joining client drops any stale local value until the host's copy arrives.
	function events.MultiplayerInitialized()
		if vars and not MawCore.Sync.isHost() then
			vars.MAWSETTINGS = vars.MAWSETTINGS or {}
			vars.MAWSETTINGS.rescueLiquidDrops = nil
		end
		sync()
	end

	function events.Tick()
		sync()
	end
end
