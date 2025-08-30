
do
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
	local function patch(p, code)
		-- workaround for the fact that asmpatch doesn't currently handle
		-- the case when GetInstructionSize(p) < GetHookSize(p) correctly
		mem.nop(p)
		mem.asmhook(p, code)
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

-- make moving backwards always the same speed as moving forwards
--   this was aready the case when walking and flying, so this only adjusts running while on the ground
do
	local code = [[
		shl eax, 0x1
	]]
	mem.asmhook(0x471c2f, code)
	mem.asmhook(0x471c64, code)

	code = [[
        cmp dword ptr [ebp - 0x38], 0x0
		jz @shift
		cmp dword ptr [ebp - 0x60], 0x0
		jz @f
	@shift:
		shl eax, 0x1
	@@:
	]]
	mem.asmhook(0x473044, code)
	mem.asmhook(0x473078, code)
end
