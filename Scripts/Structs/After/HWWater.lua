
local HWWaterTexPtr, WtrTexPtr, LavTexPtr, OilTexPtr, CurPrefix, TileTypes, ConnTable, TileBySets, FastConns
local CurW1, CurW2, CurW3

function LoadHWWater()

	local ConnTxtTable = io.open("Data/Tables/HW water textures.txt", "r")

	if not ConnTxtTable then
		return false
	end

	ConnTable = {}
	local Counter = 0
	local LineIt = ConnTxtTable:lines()
	LineIt() -- skip header

	for line in LineIt do
		local Words = string.split(line, "\9")
		ConnTable[Words[1]] = {Tex = Words[2]  .. "%03u", Id = Counter, Bitmap = 0}
		Counter = Counter + 1
	end

	local FramesCount = Game.PatchOptions.HDWTRCount

	HWWaterTexPtr = mem.StaticAlloc(Counter*FramesCount*4 + 26 + 28)
	CurPrefix = HWWaterTexPtr
	WtrTexPtr = HWWaterTexPtr + 4
	LavTexPtr = HWWaterTexPtr + 8
	OilTexPtr = HWWaterTexPtr + 12
	CurW1 = HWWaterTexPtr + 16
	CurW2 = HWWaterTexPtr + 17
	CurW3 = HWWaterTexPtr + 18
	TileTypes = HWWaterTexPtr + 19
	HWWaterTexPtr	= HWWaterTexPtr + 26
	LoadWSet = mem.asmproc([[

		pushfd
		pushad

		xor esi, esi
		xor edi, edi

		@rep:

		push esi
		mov eax, dword [ds:]].. CurPrefix .. [[]; -- HW texture prefix
		push eax
		lea eax, dword [ss:ebp-0x10]
		push eax
		call absolute 0x4d9f10

		add esp, 0xc
		push edi
		push edi
		push edi
		lea eax, dword [ss:ebp-0x10]
		push eax
		mov ecx, 0x72dc60;		-- Bitmaps filepath
		call absolute 0x410d70

		mov edi, dword [ds:]] .. WtrTexPtr .. [[];
		mov dword [ds:edi], eax; -- Index in loaded pics
		add dword [ds:]] .. WtrTexPtr .. [[], 0x4
		inc esi
		cmp esi, ]] .. FramesCount .. [[;
		jl @rep

		popad
		popfd

		retn

	]])

	mem.u4[WtrTexPtr] = HWWaterTexPtr

	Counter = 0
	for k, v in pairs(ConnTable) do
		ConnTable[k] = mem.u4[WtrTexPtr]
		mem.u4[CurPrefix] = mem.topointer(v.Tex)
		events.call("BeforeLoadWater", k, v)
		mem.call(LoadWSet)
		Counter = Counter + 1
	end

	return true

end

local NewCode = mem.asmproc([[
	je absolute 0x46426a
	nop
	nop
	nop
	nop
	nop
	test eax, eax
	je absolute 0x4641d4
	jmp absolute 0x46426a]])

mem.asmpatch(0x4641ce, "jmp absolute " .. NewCode)

mem.hook(NewCode + 6, function(d)

	if LoadHWWater() then
		d.eax = 1

		function events.AfterLoadMap()
			mem.u4[WtrTexPtr] = 0
			mem.u4[LavTexPtr] = 0
			mem.u4[OilTexPtr] = 0

			mem.u1[CurW1] = 0
			mem.u1[CurW2] = 0
			mem.u1[CurW3] = 0

			CurPrefix = TileTypes
			FastConns = {}

			mem.u4[0xfc50a4] = 0
			mem.u4[0xfc50a8] = 0
			mem.u4[0xfc50ac] = 0

		end

		mem.asmpatch(0x477401, [[
		mov edx, dword [ds:]] .. WtrTexPtr .. [[];
		test edx, edx
		jnz @neq

		mov edx, ]] .. HWWaterTexPtr .. [[;

		@neq:
		mov eax, dword [ds:edx+eax*4]
		xor edx, edx]])

		mem.asmpatch(0x47740a, [[
		mov eax, dword [ds:]] .. WtrTexPtr .. [[];
		test eax, eax
		jnz @end

		mov eax, ]] .. HWWaterTexPtr .. [[;
		@end:
		mov eax, dword [ds:eax];]])

		local NewCode = mem.asmproc([[
		call absolute 0x47e33c

		mov esi, ]] .. CurW1 .. [[;
		mov edi, ]] .. WtrTexPtr .. [[;
		cmp byte [ds:esi], 0
		je @find
		cmp al, byte [ds:esi]
		je @hav

		mov esi, ]] .. CurW2 .. [[;
		mov edi, ]] .. LavTexPtr .. [[;
		cmp byte [ds:esi], 0
		je @find
		cmp al, byte [ds:esi]
		je @hav

		mov esi, ]] .. CurW3 .. [[;
		mov edi, ]] .. OilTexPtr .. [[;
		cmp byte [ds:esi], 0
		je @find
		cmp al, byte [ds:esi]
		je @hav
		jmp @def

		@find:
		nop
		nop
		nop
		nop
		nop

		@hav:
		mov eax, dword [ds:edi]
		jmp absolute 0x480a19

		@def:
		mov eax, ]] .. HWWaterTexPtr .. [[;
		jmp absolute 0x480a19]])

		mem.hook(NewCode + 64, function(d)

			local CurPtr = ConnTable[Game.CurrentTileBin[d.eax].Name]

			mem.u1[d.esi] = d.eax

			if CurPtr then
				mem.u4[d.edi] = CurPtr

				for i,v in ipairs({0xfc50a4, 0xfc50a8, 0xfc50ac}) do
					if mem.u4[v] == 0 then
						mem.u4[v] = Game.CurrentTileBin[d.eax].Bitmap
						break
					end
				end

			else
				mem.u4[d.edi] = HWWaterTexPtr
			end

		end)
		mem.asmpatch(0x4809cd, "jmp absolute " .. NewCode)

		mem.hook(0x4af076, function(d)
			local CurPtr = FastConns[d.edx]
			if not CurPtr then
				CurPtr = ConnTable[string.lower(mem.string(mem.u4[d.esp+0x10]))] or HWWaterTexPtr
				FastConns[d.edx] = CurPtr
			end
			d.eax = mem.u4[d.eax*4 + CurPtr]
		end)

	else
		d.eax = 0

	end

end)

