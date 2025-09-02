local u1, u2, u4, i1, i2, i4 = mem.u1, mem.u2, mem.u4, mem.i1, mem.i2, mem.i4
local hook, autohook, autohook2, asmpatch = mem.hook, mem.autohook, mem.autohook2, mem.asmpatch
local max, min, round, random = math.max, math.min, math.round, math.random
local format = string.format

local function getSFTItem(p)
	local i = (p - Game.SFTBin.Frames["?ptr"]) / Game.SFTBin.Frames[0]["?size"]
	return Game.SFTBin.Frames[i]
end

-- cosmetic change: some monsters (mainly bosses) can be larger
local scaleHook = function(indoor)
	return function(d)
		local t = {Scale = d.eax, Frame = getSFTItem(d.ebx)}
		t.MonsterIndex, t.Monster = internal.GetMonster(indoor and d.edi or (d.edi - 0x9A))
		events.call("MonsterSpriteScale", t)
		d.eax = t.Scale
	end
end

-- outdoor
autohook2(0x47AC26, scaleHook())
autohook2(0x47AC46, scaleHook())

-- indoor
autohook2(0x43D02E, scaleHook(true))
autohook2(0x43D04D, scaleHook(true))

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
do
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

-- Faster strafing speed
fasterStrafing=true
