local mmver = offsets.MMVersion
local function mmv(...)
	local ret = select(mmver - 5, ...)
	assert(ret ~= nil)
	return ret
end

local OldCount, NewCount = mmv(nil, 89, 67), nil

local function ChangeGameArray(name, p, count)
	structs.o.GameStructure[name] = p
	internal.SetArrayUpval(Game[name], "o", p)
 	internal.SetArrayUpval(Game[name], "count", count)
	internal.SetArrayUpval(Game[name], "size", count)
	for i=0, count - 1 do
		internal.SetArrayUpval(Game[name][i], "count", count)
	end
end

if mmver > 6 then

	mem.autohook2(mmv(nil, 0x454842, 0x451fad), function(d) --0x456df9, 0x454690 - 0x454842,

		NewCount = DataTables.ComputeRowCountInPChar(d.eax, 6, 6) - 1

		if NewCount <= OldCount then
			return
		end

		local ExtraSize = NewCount*NewCount + NewCount
		local NewStartPos = mem.hookalloc(ExtraSize)
		local NewCode

		for i = NewStartPos, NewStartPos + ExtraSize - 1 do
			mem.u1[i] = 0x0
		end

		mem.IgnoreProtection(true)
		if mmver == 7 then
			--mem.i4[0x4011df + 4] = NewStartPos -- corrected inside injection
			mem.i4[0x40120d + 2] = NewStartPos
			mem.i4[0x4021e8 + 4] = NewStartPos + NewCount + 1
			mem.i4[0x406927 + 4] = NewStartPos + NewCount + 1
			mem.i4[0x456dfe + 1] = NewStartPos
			--mem.i4[0x411edf + 4] = NewStartPos + 8 --history.txt pointer

			mem.u4[d.esp+24] = NewStartPos

			NewCode = mem.asmproc([[nop
			cmp ebp, ]] .. NewCount .. [[;
			jge absolute 0x40121a
			jmp absolute 0x4011d7]])
			mem.asmpatch(0x4011d2, "jmp " .. NewCode + 1 .. " - 0x4011d2")

			NewCode = mem.asmproc([[
			cmp eax, ]] .. NewCount .. [[;
			jge absolute 0x40121a
			imul ebp, ebp, ]] .. NewCount .. [[;
			movzx eax, byte [ds:eax+ebp+]] .. NewStartPos .. [[];
			jmp absolute 0x40121c]])
			mem.asmpatch(0x4011d7, "jmp " .. NewCode .. " - 0x4011d7")

			NewCode = mem.asmproc([[
			mov ecx, eax
			imul ecx, ecx, ]] .. NewCount .. [[;
			jmp absolute 0x40120d]])
			mem.asmpatch(0x401208, "jmp " .. NewCode .. " - 0x401208")

			NewCode = mem.asmproc([[
			mov edi, dword [ss:ebp-0x50]
			imul eax, eax, ]] .. NewCount .. [[;
			jmp absolute 0x4021e8]])
			mem.asmpatch(0x4021e2, "jmp " .. NewCode .. " - 0x4021e2")

			NewCode = mem.asmproc([[
			imul esi, esi, ]] .. NewCount .. [[;
			dec eax
			cdq
			jmp absolute 0x406925]])
			mem.asmpatch(0x406920, "jmp " .. NewCode .. " - 0x406920")

			NewCode = mem.asmproc([[
			mov dword [ss:esp + 0x14], ebx
			lea ebp, dword [ds:edx+ecx-]] .. NewCount .. [[];
			jmp absolute 0x45487d]])
			mem.asmpatch(0x454875, "jmp " .. NewCode .. " - 0x454875")

			NewCode = mem.asmproc([[
			cmp edi, ]] .. NewCount + 1 .. [[;
			jg absolute 0x4548c8
			jmp absolute 0x4548b4]])
			mem.asmpatch(0x4548af, "jmp " .. NewCode .. " - 0x4548af")

			NewCode = mem.asmproc([[
			add ebp, ]] .. NewCount .. [[;
			lea eax, dword [ds:esi+0x1]
			lea ecx, dword [ds:edi-0x1]
			cmp ecx, ]] .. NewCount + 1 .. [[;
			jmp absolute 0x4548d5]])
			mem.asmpatch(0x4548c9, "jmp " .. NewCode .. " - 0x4548c9")

			NewCode = mem.asmproc([[
			cmp dword [ss:esp+0x10], ]] .. NewCount .. [[;
			jmp absolute 0x4548e6
			nop]])
			mem.asmpatch(0x4548e1, "jmp " .. NewCode .. " - 0x4548e1")

		else

			--mem.i4[0x4011e4 + 4] = NewStartPos --corrected inside injection
			mem.i4[0x401212 + 2] = NewStartPos
			mem.i4[0x454695 + 1] = NewStartPos
			mem.i4[0x402242 + 4] = NewStartPos + NewCount + 1
			mem.i4[0x407053 + 4] = NewStartPos + NewCount + 1
			--mem.i4[0x4cc691 + 3] = NewStartPos + 0x8 - history.txt pointer.

			mem.u4[d.esp+12] = NewStartPos

			NewCode = mem.asmproc([[nop
			cmp dword [ss:ebp-0x4],]] .. NewCount + 1 .. [[;
			jg absolute 0x452032
			jmp absolute 0x45201d]])
			mem.asmpatch(0x452017, "jmp " .. NewCode + 1 .. " - 0x452017")

			NewCode = mem.asmproc([[
			add dword [ss:ebp-0xc],]] .. NewCount .. [[;
			mov ecx, dword [ss:ebp-0x4]
			dec ecx
			cmp ecx, ]] .. NewCount + 1 .. [[;
			jmp absolute 0x452040]])
			mem.asmpatch(0x452035, "jmp " .. NewCode .. " - 0x452035")

			NewCode = mem.asmproc([[
			lea ecx, dword [ds:ecx+edx-]] .. NewCount .. [[];
			inc eax
			jmp absolute 0x451fdc]])
			mem.asmpatch(0x451fd7, "jmp " .. NewCode .. " - 0x451fd7")

			NewCode = mem.asmproc([[mov ecx, eax
			imul ecx, ecx, ]] .. NewCount .. [[;
			jmp absolute 0x401212]])
			mem.asmpatch(0x40120d, "jmp " .. NewCode .. " - 0x40120d")

			NewCode = mem.asmproc([[
			cmp ebp, ]] .. NewCount .. [[;
			jge absolute 0x40121f
			jmp absolute 0x4011dc]])
			mem.asmpatch(0x4011d7, "jmp " .. NewCode .. " - 0x4011d7")

			NewCode = mem.asmproc([[
			cmp eax, ]] .. NewCount .. [[;
			jge absolute 0x40121f
			imul ebp, ebp, ]] .. NewCount .. [[;
			movzx eax, byte [ds:eax+ebp+]] .. NewStartPos .. [[];
			jmp absolute 0x401221]])
			mem.asmpatch(0x4011dc, "jmp " .. NewCode .. " - 0x4011dc")

			NewCode = mem.asmproc([[idiv edi
			imul eax, eax, ]] .. NewCount .. [[;
			jmp absolute 0x402238]])
			mem.asmpatch(0x402233, "jmp " .. NewCode .. " - 0x402233")

			NewCode = mem.asmproc([[
			imul ecx, ecx,]] .. NewCount .. [[;
			dec eax
			cdq
			jmp absolute 0x407047]])
			mem.asmpatch(0x407042, "jmp " .. NewCode .. " - 0x407042")

			NewCode = mem.asmproc([[
			inc dword [ss:ebp-8]
			cmp dword [ss:ebp-8], ]] .. NewCount .. [[;
			jmp absolute 0x452051
			nop]])
			mem.asmpatch(0x45204a, "jmp " .. NewCode .. " - 0x45204a")

--~ 			NewCode = mem.asmproc([[;
--~ 			push ]] .. NewCount .. [[;
--~ 			pop eax
--~ 			mov dword [ss:ebp-0x78], eax
--~ 			jmp absolute 0x4cc595]])
--~ 			mem.asmpatch(0x4cc58f, "jmp " .. NewCode .. " - 0x4cc58f")

--~ 			NewCode = mem.asmproc([[
--~ 			add eax, ]] .. NewCount-1 .. [[;
--~ 			mov dword [ss:ebp-0x6c], eax
--~ 			jmp absolute 0x4cc5d5]])
--~ 			mem.asmpatch(0x4cc5cf, "jmp " .. NewCode .. " - 0x4cc5cf")

		end

	mem.IgnoreProtection(false)
	ChangeGameArray("HostileTxt", NewStartPos, NewCount)

	end)
end
