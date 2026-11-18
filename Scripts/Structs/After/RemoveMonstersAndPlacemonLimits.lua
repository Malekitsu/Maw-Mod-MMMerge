local mmver = offsets.MMVersion
local function mmv(...)
	local ret = select(mmver - 5, ...)
	assert(ret ~= nil)
	return ret
end

local OldMonCount, NewMonCount = mmv(nil, 198, 264), nil
local OldPlMCount, NewPlMCount = mmv(nil, 31, 131), nil

local function ChangeGameArray(name, p, count)
	structs.o.GameStructure[name] = p
	internal.SetArrayUpval(Game[name], "o", p)
	internal.SetArrayUpval(Game[name], "count", count)
	Game[name].count = count -- Somewhat upper function does not affect these arrays. -Rod
end

if mmver > 6 then
	mem.autohook2(mmv(nil, 0x455082, 0x45286c), function(d)

		NewMonCount = DataTables.ComputeRowCountInPChar(d.eax, 6, 6) - 4
		if NewMonCount <= OldMonCount then
			return
		end

		local ExtraSize = (NewMonCount+1)*mmv(nil, 88, 96) + 0x100
		local NewStartPos = mem.hookalloc(ExtraSize)
		for i = NewStartPos, NewStartPos + ExtraSize - 1 do
			mem.u1[i] = 0x0
		end

		local function SimpleReplacePtr(t, CmdSize, OldOrigin, NewOrigin)
			local OldAddr
			for i, v in ipairs(t) do
				OldAddr = mem.u4[v + CmdSize]
				mem.u4[v + CmdSize] = NewOrigin + OldAddr - OldOrigin
			end
		end

		mem.IgnoreProtection(true)
		if mmver == 7 then

			d.esi = NewStartPos
			d.ebx = NewStartPos
			mem.u4[d.esp+4] = NewStartPos
			mem.u4[d.esp-0x60] = NewStartPos
			mem.u4[d.esp-0x64] = NewStartPos
			mem.u4[d.esp-0x1034] = NewStartPos
			mem.u4[d.esp-0x1060] = NewStartPos
			mem.u4[d.ebp-8] = NewStartPos

			mem.i4[0x456354 + 3] = NewMonCount + 1
			mem.i4[0x4550b3 + 6] = NewMonCount + 1
			mem.i4[0x4550b3 + 2] = (NewMonCount + 1)*88 + 8
			mem.i4[0x45633f + 2] = (NewMonCount + 1)*88 + 8
			mem.i4[0x456369 + 2] = (NewMonCount + 1)*88 + 8
			mem.i4[0x456433 + 2] = (NewMonCount + 1)*88 + 8
			mem.i4[0x456459 + 2] = (NewMonCount + 1)*88 + 8

			SimpleReplacePtr(
				{0x44F81C, 0x44F82E, 0x456DD3, 0x4bc2dc, 0x459603},
				1, 0x5cccc0, NewStartPos)

			SimpleReplacePtr(
				{0x41EA25, 0x42134D, 0x439B69, 0x439BC8, 0x439C8D, 0x439D49,
				0x4B2DD9, 0x4B7A80, 0x4BBF50, 0x401baa, 0x401d6d, 0x401fcc,
				0x403620, 0x4037f7, 0x4039c0, 0x403bcc, 0x403e04, 0x4064b5,
				0x40657e, 0x439a4d, 0x439b23, 0x43a1eb, 0x43a2c8, 0x43a709,
				0x43a7e6, 0x44fb48, 0x44fe03, 0x450b7a, 0x461294},
				2, 0x5cccc0, NewStartPos)


			SimpleReplacePtr(
				{0x4bbbcb, 0x4bbc02, 0x4bd1ec, 0x4bd223, 0x40690e},
				2, 0x5cccc0, NewStartPos)


			SimpleReplacePtr(
				{0x4012f6},
				3, 0x5cccc0, NewStartPos)

			mem.u4[0x4bc316 + 2] = NewStartPos + NewMonCount * 88

		else

			d.esi = NewStartPos
			d.edi = NewStartPos
			mem.u4[d.esp+4] = NewStartPos
			mem.u4[d.esp-0x94] = NewStartPos
			mem.u4[d.esp-0x98] = NewStartPos
			mem.u4[d.ebp-8] = NewStartPos

			mem.i4[0x453bd1 + 2] = NewMonCount + 1
			mem.i4[0x45289a + 6] = NewMonCount + 1
			mem.i4[0x4ba5b8 + 1] = NewMonCount + 1
			mem.i4[0x45289a + 2] = (NewMonCount + 1)*96 + 8
			mem.i4[0x453bbe + 2] = (NewMonCount + 1)*96 + 8
			mem.i4[0x453be2 + 2] = (NewMonCount + 1)*96 + 8
			mem.i4[0x453cab + 2] = (NewMonCount + 1)*96 + 8
			mem.i4[0x453cd2 + 2] = (NewMonCount + 1)*96 + 8

			SimpleReplacePtr(
				{0x401331, 0x40702b, 0x4bae04, 0x4bae4b, 0x4b9d4f, 0x4b9d94},
				3, 0x5e9530, NewStartPos)

			SimpleReplacePtr(
				{0x401bce, 0x401d9f, 0x402008, 0x403853, 0x403a33, 0x403c02,
				0x403e17, 0x404058, 0x406bd9, 0x406c9c, 0x420779, 0x43754a,
				0x437d10, 0x4381ab, 0x44d2a1, 0x44e3e5, 0x456e89, 0x456ec3,
				0x45eba5, 0x4b16b9, 0x4b6076, 0x4ba10c},
				2, 0x5e9530, NewStartPos)

			SimpleReplacePtr(
				{0x45466a, 0x4ba522, 0x44d532, 0x44cf47, 0x44cf65},
				1, 0x5e9530, NewStartPos)

			mem.u4[0x4ba561 + 2] = NewStartPos + NewMonCount*96

			-- Fix arena random draw.
			local ArenaLevel, NewCode

			NewCode = mem.asmpatch(0x4ba5a1, [[
			nop
			nop
			nop
			nop
			nop
			sub eax, 0x55
			je absolute 0x4ba5e2]])
			mem.hook(NewCode, function(d)
				ArenaLevel = d.eax - 85
				events.call("BeforeArenaStart", ArenaLevel)
			end)

			NewCode = mem.asmpatch(0x4ba624, [[
			nop
			nop
			nop
			nop
			nop
			call absolute 0x4ba076]])

			local min, max, random = math.min, math.max, math.random
			mem.hook(NewCode, function(d)
				local t = {MonId = d.ecx, ArenaLevel = ArenaLevel, Handled = false}
				events.call("GenerateArenaMonster", t)

				d.ecx = t.MonId

				if not t.Handled then
					local cnt = 0
					local Need = d.ecx <= 0 or d.ecx >= Game.MonstersTxt.count or Game.IsMonsterOfKind(d.ecx, 6) == 1
					if Need then
						d.ecx = 41
						while cnt < 3 do
							local res = min(max(mem.u2[d.ebp - random(0x12, 0x68)*2], 1), Game.MonstersTxt.count-2)
							if res > 0 and Game.IsMonsterOfKind(res, 6) == 0 then
								d.ecx = res
								break
							end
						end
					end
				end
			end)

			-- Fix monsters-overflow crash.
			mem.asmpatch(0x44d4ac, [[
			cmp dword [ds:0x692fb0], ]] .. mem.u4[0x4ba084 + 2] .. [[;
			jge absolute 0x44d730
			; std
			cmp byte [ds:ebx+0x65], 0
			push esi
			]])

		end
		mem.IgnoreProtection(false)
		ChangeGameArray("MonstersTxt", NewStartPos, NewMonCount)

	end)
end

if mmver > 6 then
	mem.autohook2(mmv(nil, 0x454f92, 0x452779), function(d)

		NewPlMCount = DataTables.ComputeRowCountInPChar(d.eax, 2, 2) - 1
		if NewPlMCount <= OldPlMCount and NewMonCount <= OldMonCount then --PlaceMon use MonstersTxt pointers in original .exe code, it can not be left unchanged, if MonstersTxt was.
			return
		end

		local NewPlaceMonStart = mem.hookalloc(NewPlMCount*4+32)
		for i = NewPlaceMonStart, NewPlaceMonStart + NewPlMCount*4+32 - 1 do
			mem.u1[i] = 0x0
		end

		mem.IgnoreProtection(true)
		if mmver == 7 then

			d.edi = NewPlaceMonStart

			mem.i4[0x454fa8 + 2] = 0x4
			mem.i4[0x454faf + 6] = NewPlMCount
			mem.i4[0x454faf + 2] = (NewPlMCount+1)*4+4
			mem.i4[0x45503b + 2] = (NewPlMCount+1)*4+4
			mem.i4[0x454fbc + 3] = NewPlMCount - 1
			local NewCode = mem.asmproc([[nop
			cmp ecx, ]] .. NewPlMCount .. [[;
			jg absolute 0x455032
			jmp absolute 0x45502d
			nop]])
			mem.asmpatch(0x455028, "jmp " .. NewCode .. " - 0x455028")
			mem.i4[0x41ea12 + 3] = NewPlaceMonStart
			mem.i4[0x42133d + 3] = NewPlaceMonStart

		else

			d.edi = NewPlaceMonStart

			mem.i4[0x45278f + 2] = 0x4
			mem.i4[0x452796 + 6] = NewPlMCount
			mem.i4[0x452796 + 2] = NewPlMCount*4 + 4
			mem.i4[0x4527a3 + 3] = NewPlMCount - 1
			mem.i4[0x45280c + 2] = NewPlMCount
			mem.i4[0x452825 + 6] = NewPlMCount
			mem.i4[0x452825 + 2] = NewPlMCount*4 + 4
			mem.i4[0x420766 + 3] = NewPlaceMonStart
			mem.i4[0x456e77 + 3] = NewPlaceMonStart

		end
		mem.IgnoreProtection(false)

		ChangeGameArray("PlaceMonTxt", NewPlaceMonStart, NewPlMCount)

	end)
end
