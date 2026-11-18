
local mmver = offsets.MMVersion

if mmver ~= 8 then
	return
end

evt.UseItemEffects = {}
evt.PotionEffects = {}

local NewSpacePtr = 0x5efbc8
local NewCode
local OldItemsCount, NewItemsCount = 803, nil
local OldStdCount, NewStdCount = 24, nil
local OldSpcCount, NewSpcCount = 72, nil
local OldPotCount, NewPotCount = 51, nil

--Structures:

local OldGame = structs.f.GameStructure
function structs.f.GameStructure(define)
   OldGame(define)
   define
	[0].struct(structs.ArmorPicsCoords)  'ArmorPicsCoords'
	[0x5fec10].array(1, OldPotCount).array(1, OldPotCount).u2 'MixPotions'
	[0x5fec10].array(1).struct(structs.ReagentSettings) 'ReagentSettings'
	[0x5f7f10].array(81).EditPChar 'MessageScrolls'
end

function structs.f.ArmorPicsCoords(define)
	define
	[0x4f5a98].array(1, 1).array(4).struct(structs.EquipCoordinates)  'Armors'
	[0x4f5a98].array(1, 1).array(4).struct(structs.EquipCoordinates)  'Helms'
	[0x4f5a98].array(1, 1).array(4).struct(structs.EquipCoordinates)  'Belts'
	[0x4f5a98].array(1, 1).array(4).struct(structs.EquipCoordinates)  'Boots'
	[0x4f5a98].array(1, 1).array(4).struct(structs.EquipCoordsCloak)  'Cloaks'
end

function structs.f.EquipCoordinates(define)
   define
   .i2  'X'
   .i2	'Y'
end

function structs.f.EquipCoordsCloak(define)
   define
   .i2  'X'
   .i2	'Y'
   .i2  'ColX'
   .i2	'ColY'
end

function structs.f.ReagentSettings(define)
   define
   .u2  'Item'
   .u2	'Result'
end

local FindInIndex = mem.asmproc([[
	;eax - index ptr
	;ecx - limit
	;edx - thing to find
	;ebx - shift size

	test ecx, ecx
	je @neq

	jmp @start
	@rep:
	lea eax, dword [ds:eax+ebx]
	@start:
	cmp word [ds:eax], dx
	je @equ
	dec ecx
	jnz @rep

	@neq:
	mov eax, 0
	@equ:
	retn]])


local function SimpleReplacePtrs(t, CmdSize, OldOrigin, NewOrigin)
	local OldAddr
	for i, v in ipairs(t) do
		OldAddr = mem.u4[v + CmdSize]
		mem.u4[v + CmdSize] = NewOrigin + OldAddr - OldOrigin
	end
end

local function GenerateReagentsTable()

	local ReagentsTable = io.open("Data/Tables/Reagent settings.txt", "w")

	ReagentsTable:write("Reagent Id\9Item Id\9Result item id\9Notes\n")

	local Result = {222, 222, 222, 222, 222, 223, 223, 223, 223, 223, 224, 224, 224, 224, 224, 221, 221, 221, 221, 221}

	for i = 200, 219 do

		ReagentsTable:write(i-199 .. "\9" .. i .. "\9" .. Result[i-199] .. "\9" .. Game.ItemsTxt[i].Name .. "\n")

	end

	io.close(ReagentsTable)

end

local function ProcessReagentsTable()

	local ReagentsTablePtr, ReagentsCount
	local ReagentsTable = io.open("Data/Tables/Reagent settings.txt", "r")

	if not ReagentsTable then
		GenerateReagentsTable()
		ReagentsTable = io.open("Data/Tables/Reagent settings.txt", "r")
	end
	local Words, ReagentsData = {}, {}
	local LineIt = ReagentsTable:lines()

	LineIt() -- Skip header

	for line in LineIt do
		Words = string.split(line, "\9")
		table.insert(ReagentsData, {Src = tonumber(Words[2]), Res = tonumber(Words[3])})
	end

	ReagentsTablePtr = mem.StaticAlloc(table.maxn(ReagentsData)*4)
	ReagentsCount = table.maxn(ReagentsData)

	for i = 1, ReagentsCount do

		mem.u2[ReagentsTablePtr+(i-1)*4] = ReagentsData[i].Src
		mem.u2[ReagentsTablePtr+(i-1)*4+2] = ReagentsData[i].Res

	end

	io.close(ReagentsTable)

	structs.o.GameStructure["ReagentSettings"] = ReagentsTablePtr
	internal.SetArrayUpval(Game["ReagentSettings"], "o", ReagentsTablePtr)
	internal.SetArrayUpval(Game["ReagentSettings"], "count", ReagentsCount)

	ReagentsCount = ReagentsCount - 1

	-- check reagent
	NewCode = mem.asmproc([[
	push ecx
	push edx
	mov ebx, 0x4
	mov edx, ecx
	mov eax, ]] .. ReagentsTablePtr .. [[;
	mov ecx, ]] .. ReagentsCount + 1 .. [[;
	call absolute ]] .. FindInIndex .. [[;
	pop edx
	test eax, eax
	jnz @reg

	pop ecx
	xor ebx, ebx
	mov eax, dword [ss:ebp-0xc]
	jmp absolute 0x4158bb

	@reg:
	movzx ebx, word [ds:eax+0x2]
	pop ecx
	mov eax, dword [ss:ebp-0xc]
	jmp absolute 0x4157f3]])
	mem.asmpatch(0x4157d8, "jmp absolute " .. NewCode)

	-- make potion
	NewCode = mem.asmproc([[
	mov eax, dword [ss:ebp-0xc]
	imul eax, eax, 0x24
	mov dword [ds:esi+eax+0x4a8], ebx
	xor ebx, ebx
	jmp absolute 0x415885]])
	mem.asmpatch(0x415823, "jmp absolute " .. NewCode)

end

local function GeneratePotionsTable()

	local PotionsTable = io.open("Data/Tables/Potion settings.txt", "w")

	PotionsTable:write("Pot Id\9Item Id\9Required mastery\9Drinkable\9Usable\9Notes\n")

	local Drinkable, Usable, Default

	Default =  {Mastery = {0,0,0,0,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4},
				Drinkable = {},
				Usable = {233, 236, 246, 247, 248, 249, 250, 263}}

	PotionsTable:write(0 .. "\9" .. 220 .. "\9N/A\9N/A\9N/A\9Empty bottle\n")

	for i = 221, 271 do

		if table.find(Default.Usable, i) then
			Drinkable = "-"
			Usable = "x"
		else
			Drinkable = "x"
			Usable = "-"
		end

		PotionsTable:write(i-220 .. "\9" .. i .. "\9" .. Default.Mastery[i-220] .. "\9" .. Drinkable .. "\9" .. Usable .. "\9" .. Game.ItemsTxt[i].Name .. "\n")

	end

	io.close(PotionsTable)

end

local function ProcessPotionsTable()

	local PotionsTablePtr
	local PotionsTable = io.open("Data/Tables/Potion settings.txt", "r")

	if not PotionsTable then
		GeneratePotionsTable()
		PotionsTable = io.open("Data/Tables/Potion settings.txt", "r")
	end

	local Words, PotionsData = {}, {}
	local LineIt = PotionsTable:lines()
	local function ChekFlag(Flag)
		if Flag == "x" then
			return 1
		else
			return 0
		end
	end

	LineIt() -- Skip header

	Words = string.split(LineIt(), "\9") -- process empty bottle
	PotionsData[0] = {PId = tonumber(Words[2])}

	for line in LineIt do

		Words = string.split(line, "\9")
		table.insert(PotionsData, {PId = tonumber(Words[2]), ReqM = tonumber(Words[3]), Drinkable = ChekFlag(Words[4]), Usable = ChekFlag(Words[5])})

	end

	PotionsTablePtr = mem.StaticAlloc(table.maxn(PotionsData)*5+4)
	mem.u2[PotionsTablePtr] = PotionsData[0].PId

	PotionsTablePtr = PotionsTablePtr + 4

	for i = 1, table.maxn(PotionsData) do

		mem.u2[PotionsTablePtr+(i-1)*5] = PotionsData[i].PId
		mem.u2[PotionsTablePtr+(i-1)*5+2] = PotionsData[i].ReqM
		mem.u2[PotionsTablePtr+(i-1)*5+3] = PotionsData[i].Drinkable
		mem.u2[PotionsTablePtr+(i-1)*5+4] = PotionsData[i].Usable

	end

	---- Potion handler
	-- Use potion on item

	NewCode = mem.asmproc([[
	push eax
	push ecx
	test ecx, ecx
	je @def

	push edx
	push ebx
	mov ebx, 0x5
	mov edx, ecx
	mov eax, ]] .. PotionsTablePtr .. [[;
	mov ecx, ]] .. NewPotCount + 1 .. [[;
	call absolute ]] .. FindInIndex .. [[;
	pop ebx
	pop edx

	test eax, eax
	je @def
	mov al, byte [ds:eax+4]
	test al, al
	je @def

	neg ecx
	add ecx, ]] .. NewPotCount + 2 .. [[;
	mov ebx, ecx
	pop ecx
	pop eax

	push eax
	nop; memhook here
	nop
	nop
	nop
	nop
	xor ebx, ebx
	test ecx, ecx
	jnz @std
	add dword [ds:edx+0x14], eax; 00 - no, 0x1X - red, 0x2X - blue, 0x4X - green, 0x8X - purple
	pop eax
	jmp absolute 0x41616e

	@std:
	pop eax
	cmp ecx, 0xEC
	jmp absolute 0x41605c

	@def:
	pop ecx
	pop eax
	jmp absolute 0x416180]])
	mem.asmpatch(0x416056, "jmp absolute " .. NewCode)

	mem.hook(NewCode + 53, function(d)

		-- d.ecx - potion in hand item index
		-- [0xb7ca68] - potion power
		-- d.edi - targeted item id in itemstxt
		-- d.eax - targeted item id in current player's inventory
		-- d.ebx - potion index by type
		-- d.edx pointer to item in player's inventory

		local f = evt.PotionEffects[d.ebx]

		if type(f) == "function" then

			local TItem = Party.Players[Party.CurrentPlayer].Items[d.eax+1]
			local result, anim = f(false, TItem, mem.u4[0xb7ca68], d.ecx)

			if result then
				d.ecx = 0
				if anim and type(anim) == "number" and anim <= 3 then
					d.eax = 2^anim*16
				else
					d.eax = 2^math.random(0,3)*16
				end
			end

		end

	end)

	-- Drink potion
	NewCode = mem.asmproc([[
	push ecx
	push ebx
	mov ebx, 0x5
	mov eax, ]] .. PotionsTablePtr .. [[;
	mov ecx, ]] .. NewPotCount + 1 .. [[;
	call absolute ]] .. FindInIndex .. [[;
	pop ebx
	neg ecx
	add ecx, ]] .. NewPotCount + 2 .. [[;

	test eax, eax
	je @def
	mov al, byte [ds:eax+3]
	test al, al
	je @def
	mov eax, ecx
	pop ecx

	nop; memhook here
	nop
	nop
	nop
	nop
	cmp eax, -1
	je @defend

	cmp eax, 0x33
	jg absolute 0x46722e
	jmp absolute 0x466baa

	@def:
	mov eax, ecx
	pop ecx

	@defend:
	jmp absolute 0x4671a1; - default case - "Item can not be used that way."]])
	mem.asmpatch(0x466ba1, "jmp absolute " .. NewCode)

	mem.hook(NewCode + 42, function(d)

		-- [ebp+8] - drinking player
		-- eax - potion index by type
		-- edx - item index
		-- [0xb7ca68] - potion strength

		local f = evt.PotionEffects[d.eax]

		if type(f) == "function" then

			local result = f(true, Party.Players[mem.u4[d.ebp+0x8] - 1], mem.u4[0xb7ca68], d.edx)

			if result == -1 then
				d.eax = -1
				return
			elseif result then
				d.eax = 0xf000
			end

		end

		evt.FaceAnimation(mem.u4[d.ebp+0x8] - 1, 36)

	end)

	----

	NewCode = mem.asmproc([[
	test eax, eax
	je absolute 0x4150e7
	push eax
	push ecx
	push edx
	push ebx
	mov ebx, 0x5
	mov edx, eax
	mov eax, ]] .. PotionsTablePtr .. [[;
	mov ecx, ]] .. NewPotCount + 1 .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop ebx
	pop edx
	pop ecx
	pop eax
	je absolute 0x4150e7
	jmp absolute 0x4150d7]])
	mem.asmpatch(0x4150c9, "jmp absolute " .. NewCode)

	-- need to overhaul pots system at 0x41591e:
	NewCode = mem.asmproc([[
	test ecx, ecx
	je absolute 0x416056
	push eax
	push ecx
	push edx
	push ebx
	mov ebx, 0x5
	mov edx, ecx
	mov eax, ]] .. PotionsTablePtr .. [[;
	mov ecx, ]] .. NewPotCount + 1 .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop ebx
	pop edx
	pop ecx
	pop eax
	je absolute 0x416056
	jmp absolute 0x4158d3]])
	mem.asmpatch(0x4158bb, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	test edi, edi
	je absolute 0x416056
	push eax
	push ecx
	push edx
	push ebx
	mov ebx, 0x5
	mov edx, edi
	mov eax, ]] .. PotionsTablePtr .. [[;
	mov ecx, ]] .. NewPotCount + 1 .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop ebx
	pop edx
	pop ecx
	pop eax
	je absolute 0x416056
	jmp absolute 0x4158f7]])
	mem.asmpatch(0x4158df, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	test edx, edx
	je absolute 0x416056
	push eax
	push ecx
	push ebx
	mov ebx, 0x5
	mov eax, ]] .. PotionsTablePtr .. [[;
	mov ecx, ]] .. NewPotCount + 1 .. [[;
	call absolute ]] .. FindInIndex .. [[;
	pop ebx

	neg ecx
	add ecx, ]] .. NewPotCount .. [[;
	mov edx, ecx

	test eax, eax
	pop ecx
	pop eax
	je absolute 0x416056
	jmp absolute 0x415902]])
	mem.asmpatch(0x4158fc, "jmp absolute " .. NewCode)

	mem.asmpatch(0x415b1d, "cmp dword [ds:ecx], " .. mem.u2[PotionsTablePtr] .. ";") -- compare with catalyst.

	NewCode = mem.asmproc([[
	push eax
	push ecx
	push ebx
	mov ebx, 0x5
	mov edx, ecx
	mov eax, ]] .. PotionsTablePtr .. [[;
	mov ecx, ]] .. NewPotCount + 1 .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax

	neg ecx
	add ecx, ]] .. NewPotCount .. [[;
	mov edi, ecx

	pop ebx
	pop ecx
	pop eax

	movzx edx, word [ds:]] .. PotionsTablePtr .. [[];
	cmp ecx, edx
	jmp absolute 0x415912]])
	mem.asmpatch(0x415905, "jmp absolute " .. NewCode)

	-- Required mastery analyzing:
	local FindPotion = mem.asmproc([[
	; takes:
	;eax == ItemId
	; returns:
	;eax == ptr
	;ecx == index in potion table

	push ebx
	push edx

	mov ebx, 0x5
	mov edx, eax
	mov eax, ]] .. PotionsTablePtr .. [[;
	mov ecx, ]] .. NewPotCount + 1 .. [[;

	call absolute ]] .. FindInIndex .. [[;
	test eax, eax

	neg ecx
	add ecx, ]] .. NewPotCount .. [[;

	pop edx
	pop ebx
	retn]])

	NewCode = mem.asmproc([[
	push eax
	push ecx
	mov eax, ecx
	call absolute ]] .. FindPotion .. [[;
	pop ecx
	test eax, eax
	je @nor

	movzx eax, byte [ds:eax+0x2]

	cmp eax, 1
	je @nor

	cmp eax, 2
	je @exp

	cmp eax, 3
	je @mas

	cmp eax, 4
	je @Gma

	@nor:
	pop eax
	jmp absolute 0x4159e9

	@exp:
	pop eax
	cmp dword [ss:ebp-0x8], edx
	jnz absolute 0x4159e9
	jmp absolute 0x415964

	@mas:
	pop eax
	cmp dword [ss:ebp-0x8], 2
	jg absolute 0x4159e9
	jmp absolute 0x41597d

	@Gma:
	pop eax
	push 4
	pop ecx
	cmp dword [ss:ebp-0x8], ecx
	je absolute 0x4159e9
	jmp absolute 0x4159e6]])
	mem.asmpatch(0x415997, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	cmp ecx, 0x5
	jnz @std
	mov dword [ss:ebp-0x10], 1
	jmp absolute 0x415997

	@std:
	push ecx
	test ecx, ecx
	je @end

	push eax
	mov eax, ecx
	call absolute ]] .. FindPotion .. [[;
	test eax, eax
	je @equ

	movzx ecx, byte [ds:eax+0x2]
	pop eax
	jmp @end

	@equ:
	mov ecx, eax
	pop eax

	@end:
	mov dword [ss:ebp-4], ecx
	pop ecx
	jmp absolute 0x4159e9]])
	mem.asmpatch(0x41593c, "jmp absolute " .. NewCode)

	mem.IgnoreProtection(true)

	-- Potions multiplyer:
	mem.u1[0x41591e + 2] = NewPotCount
	mem.u1[0x415abf + 2] = NewPotCount
	mem.u1[0x415cc8 + 2] = NewPotCount

	-- Empty bottle usage: 0x415a9c, 0x415b3a, 0x4157c9, 0x4157f9
	mem.u4[0x415a9c + 1] = mem.u2[PotionsTablePtr-4]
	mem.u4[0x415b3a + 1] = mem.u2[PotionsTablePtr-4]
	mem.u4[0x4157c9 + 2] = mem.u2[PotionsTablePtr-4]
	mem.u4[0x4157f9 + 6] = mem.u2[PotionsTablePtr-4]

	mem.IgnoreProtection(false)

end

local function SetupSpellsHandler()

	local ItemsTxtPtr = NewSpacePtr

	local function GetItemSpell(Wid, ItemsTxtPtr)

		local Ptr, Spell
		local Limit = 0x10

		Ptr = mem.u4[ItemsTxtPtr + Wid*48 + 12]
		Ptr = Ptr - 1

		while string.sub(mem.string(Ptr), 1, 1) ~= "S" and Limit > 0 do
			Ptr = Ptr - 1
			Limit = Limit - 1
		end

		if Limit == 0 then
			return 0
		end

		Spell = tonumber(string.sub(mem.string(Ptr), 2))
		return Spell

	end

	local WandsTablePtr, SscrollsTablePtr, BooksTablePtr, WandsCount, SscrollsCount, BooksCount
	local WandsTable, SscrollsTable, BooksTable = {}, {}, {}

	-- Parse items.txt for wands, scrolls and books.
	for i = 1, Game.ItemsTxt.count - 1 do
		if Game.ItemsTxt[i].EquipStat == 12 then
			table.insert(WandsTable, {Wid = i, Sid = GetItemSpell(i, ItemsTxtPtr)})

		elseif Game.ItemsTxt[i].EquipStat == 15 then
			table.insert(SscrollsTable, {Wid = i, Sid = GetItemSpell(i, ItemsTxtPtr)})

		elseif Game.ItemsTxt[i].EquipStat == 16 then
			table.insert(BooksTable, {Wid = i, Sid = GetItemSpell(i, ItemsTxtPtr)})

		end
	end

	-- Setup wands

	WandsCount = table.maxn(WandsTable)
	WandsTablePtr = mem.StaticAlloc(WandsCount*4)

	for i = 1, WandsCount do
		mem.u2[WandsTablePtr+(i-1)*4] = WandsTable[i].Wid
		mem.u2[WandsTablePtr+(i-1)*4+2] = WandsTable[i].Sid
	end

	NewCode = mem.asmproc([[
	push ecx
	push ebx
	push edx
	mov edx, eax
	mov eax, ]] .. WandsTablePtr .. [[;
	mov ecx, ]] .. WandsCount .. [[;
	mov ebx, 0x4
	call absolute ]] .. FindInIndex .. [[;
	pop edx
	pop ebx
	pop ecx

	movzx eax, word [ds:eax+0x2]
	push eax
	jmp absolute 0x4678ff]])
	mem.asmpatch(0x4678f8, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	push eax
	push ebx
	push edx
	mov edx, eax
	mov eax, ]] .. WandsTablePtr .. [[;
	mov ecx, ]] .. WandsCount .. [[;
	mov ebx, 0x4
	call absolute ]] .. FindInIndex .. [[;

	movzx ecx, word [ds:eax+0x2]

	pop edx
	pop ebx
	pop eax

	jmp absolute 0x42dae4]])
	mem.asmpatch(0x42dadd, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	push eax
	push ebx
	push ecx
	push edx
	mov edx, edi
	mov eax, ]] .. WandsTablePtr .. [[;
	mov ecx, ]] .. WandsCount .. [[;
	mov ebx, 0x4
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop edx
	pop ecx
	pop ebx
	pop eax
	je absolute 0x41f5dc
	jmp absolute 0x41f59f]])
	mem.asmpatch(0x41f58f, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	push eax
	push ebx
	push ecx
	push edx
	mov edx, esi
	mov eax, ]] .. WandsTablePtr .. [[;
	mov ecx, ]] .. WandsCount .. [[;
	mov ebx, 0x4
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop edx
	pop ecx
	pop ebx
	pop eax
	je absolute 0x48cc93
	jmp absolute 0x48cc85]])
	mem.asmpatch(0x48cc75, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	push eax
	push ebx
	push ecx
	push edx
	mov edx, esi
	mov eax, ]] .. WandsTablePtr .. [[;
	mov ecx, ]] .. WandsCount .. [[;
	mov ebx, 0x4
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop edx
	pop ecx
	pop ebx
	pop eax
	je absolute 0x48cd48
	jmp absolute 0x48cd3a]])
	mem.asmpatch(0x48cd2a, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	push eax
	push ebx
	push ecx
	push edx
	mov edx, eax
	mov eax, ]] .. WandsTablePtr .. [[;
	mov ecx, ]] .. WandsCount .. [[;
	mov ebx, 0x4
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop edx
	pop ecx
	pop ebx
	pop eax
	je absolute 0x4488f2
	jmp absolute 0x4488c3]])
	mem.asmpatch(0x4488b5, "jmp absolute " .. NewCode)

	-- Setup sscrols

	SscrollsCount = table.maxn(SscrollsTable)
	SscrollsTablePtr = mem.StaticAlloc(SscrollsCount*4)

	for i = 1, SscrollsCount do
		mem.u2[SscrollsTablePtr+(i-1)*4] = SscrollsTable[i].Wid
		mem.u2[SscrollsTablePtr+(i-1)*4+2] = SscrollsTable[i].Sid
	end

	mem.asmpatch(0x466aed, [[
	push eax
	push ebx
	push ecx
	push edx
	mov edx, eax
	mov eax, ]] .. SscrollsTablePtr .. [[;
	mov ecx, ]] .. SscrollsCount .. [[;
	mov ebx, 4
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	jnz @sf
	xor esi, esi
	jmp @end
	@sf:
	movzx esi, word [ds:eax+2]
	@end:
	pop edx
	pop ecx
	pop ebx
	pop eax]])

	-- Setup books

	BooksCount = table.maxn(BooksTable)
	BooksTablePtr = mem.StaticAlloc(BooksCount*4)

	for i = 1, BooksCount do
		mem.u2[BooksTablePtr+(i-1)*4] = BooksTable[i].Wid
		mem.u2[BooksTablePtr+(i-1)*4+2] = BooksTable[i].Sid
	end

	mem.asmpatch(0x4669d8, [[
	push eax
	push ebx
	push ecx
	mov eax, ]] .. BooksTablePtr .. [[;
	mov ecx, ]] .. BooksCount .. [[;
	mov ebx, 4
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	jnz @sf
	xor edi, edi
	jmp @end
	@sf:
	movzx edi, word [ds:eax+2]
	dec edi
	@end:
	pop ecx
	pop ebx
	pop eax]])

end

local function RemoveItemsLimits()

	local function ChangeGameArray(name, p, count)
		structs.o.GameStructure[name] = p
		internal.SetArrayUpval(Game[name], "o", p)
		internal.SetArrayUpval(Game[name], "count", count)
	end

	local TmpAddrTable
	local OldOrigin = 0x5efbc8

	local ItemsTxtTableSize	= NewItemsCount*48
	local StdItemsTxtSize	= NewStdCount*20
	local SpcItemsTxtSize	= NewSpcCount*28
	local PotionsTxtSize	= NewPotCount*NewPotCount*2
	local PotnotesTxtSize	= NewPotCount*NewPotCount*2

	NewSpacePtr = mem.StaticAlloc(ItemsTxtTableSize + StdItemsTxtSize + SpcItemsTxtSize
					 + PotionsTxtSize + PotnotesTxtSize + 0x400)

	local StdItemsOffset = ItemsTxtTableSize + 0x4
	local SpcItemsOffset = StdItemsOffset + StdItemsTxtSize
	local PotionsOffset  = SpcItemsOffset + SpcItemsTxtSize + 0x10
	local PotnotesOffset = PotionsOffset + PotionsTxtSize + 0x10
	local PtrsStackOffset= PotnotesOffset + PotnotesTxtSize + 0x10

	mem.IgnoreProtection(true)

		-- Counters
	-- Items
	TmpAddrTable = {0x415071 + 1, 0x415369 + 1, 0x455218 + 2, 0x455375 + 2, 0x4553a0 + 3, 0x45d2b8 + 1}
	for i, v in ipairs(TmpAddrTable) do
		mem.u4[v] = NewItemsCount
	end

	mem.u4[0x454444 + 1] = NewItemsCount*4
	mem.u4[0x454028 + 1] = NewItemsCount*4

	mem.u4[0x453ecf + 2] = NewItemsCount*4 + 0x8
	TmpAddrTable = {0x45402d, 0x454046, 0x4540d5, 0x4540dd, 0x454100, 0x45444b, 0x454477, 0x454501, 0x45450a, 0x454534}
	for i, v in ipairs(TmpAddrTable) do
		mem.u4[v+2] = -(NewItemsCount*4 + 0x8)
	end

	-- SPCItems
	mem.u4[0x4548c6 + 3] = NewSpcCount
	mem.asmpatch(0x4549d1, [[
	add esp, 0xc
	push ]] .. NewSpcCount .. [[;]])

	-- Protection against division by zero, if all bonuses disabled for whole kind of item.
	NewCode = mem.asmproc([[
	call absolute 0x4d99f2
	cdq
	cmp dword [ss:ebp+0x10], 0
	je absolute 0x454571
	jmp absolute 0x4544fe]])
	mem.asmpatch(0x4544f8, "jmp absolute " .. NewCode)

	-- Stditems
	mem.u4[0x4546f2 + 3] = NewStdCount
	mem.u4[0x4547c2 + 3] = NewStdCount

	-- Potions
	mem.u1[0x4513ff + 3] = NewPotCount
	mem.u1[0x451405 + 3] = NewPotCount
	mem.u1[0x451416 + 3] = NewPotCount
	mem.u1[0x45142c + 3] = NewPotCount

	-- Potnotes
	mem.u1[0x4515a1 + 3] = NewPotCount
	mem.u1[0x4515a7 + 3] = NewPotCount
	mem.u1[0x4515b8 + 3] = NewPotCount
	mem.u1[0x4515ce + 3] = NewPotCount

	--~ Unk
	--~ mem.u4[0x402763 + 4] = NewItemsCount + 1
	--~ mem.u4[0x4724BE + 1] = NewItemsCount + 1
	--~ mem.u4[0x4724E7 + 1] = NewItemsCount + 1
	--~ mem.u4[0x472500 + 1] = NewItemsCount + 1
	--~ mem.u4[0x473BB4 + 1] = NewItemsCount + 1
	--~ mem.u4[0x474097 + 1] = NewItemsCount + 1
	--~ mem.u4[0x497BA1 + 2] = NewItemsCount + 1
	--~ mem.u4[0x497BC3 + 2] = NewItemsCount + 1
	--~ mem.u4[0x497BEB + 3] = NewItemsCount + 1

		-- Offsets - control stack
	TmpAddrTable = {0x454A1C, 0x455A87, 0x455B02, 0x455226, 0x455247, 0x4555FB, 0x455A75, 0x455AF7, 0x4546AE, 0x455A63, 0x455AEB, 0x454884, 0x455A51, 0x455ADD, 0x4541DC,
					0x455385, 0x4542E8, 0x45432A, 0x45433E, 0x4555C9, 0x455592, 0x45555B, 0x45551A, 0x4554D6, 0x455492,	0x454310, 0x454323, 0x454408, 0x4555BB, 0x455584,
					0x45554D, 0x455509, 0x4554C5, 0x455481, 0x45441E, 0x4555AD, 0x455576, 0x45553C, 0x454362, 0x4554F8,	0x4554B4, 0x455470, 0x4547A4, 0x4543B8, 0x4543C7,
					0x45279B, 0x4549C5, 0x4549d9, 0x4549fe, 0x45445d, 0x4544f2}
	SimpleReplacePtrs(TmpAddrTable, 0, 0x11758, PtrsStackOffset)

	mem.u4[0x454807 + 3] = (PtrsStackOffset + 0x8c)/4
	mem.u4[0x454877 + 3] = (PtrsStackOffset + 0x8c)/4 + 0xC

	mem.asmpatch(0x4541d9, [[
	@rep:
	cmp dword [ds:ebx*4+edi+]] .. mem.u4[0x4541DC] .. [[], 0
	jnz @end
	dec ebx
	jmp @rep

	@end:
	idiv dword [ds:ebx*4+edi+]] .. mem.u4[0x4541DC] .. [[];]])

		-- Offsets - stditems
	TmpAddrTable = {0x4546e8, 0x455109, 0x4547b5, 0x454377 + 4, 0x4543a0 + 4}
	SimpleReplacePtrs(TmpAddrTable, 0, 0x9694, StdItemsOffset)

		-- Offsets - spcitems
	TmpAddrTable = {0x4548ba + 2, 0x45514c + 2, 0x4544D0 + 4, 0x454524 + 4, 0x45455E + 4, 0x4549DD + 2, 0x45447d + 2}
	SimpleReplacePtrs(TmpAddrTable, 0, 0x9874, SpcItemsOffset)

	mem.u4[0x45446d + 3] = -(SpcItemsOffset + 0x18)--0x988c - 0x9874)

		-- Unk
	TmpAddrTable = {0x428E91, 0x428E97, 0x428EA2, 0x429124, 0x42912A, 0x429384, 0x42938A, 0x4293A0, 0x429135, 0x4295E7, 0x4295ED}
	SimpleReplacePtrs(TmpAddrTable, 2, 0x601320, NewSpacePtr + PtrsStackOffset)

	TmpAddrTable = {0x428E43, 0x4290D6, 0x429336, 0x429599}
	SimpleReplacePtrs(TmpAddrTable, 3, 0x601320, NewSpacePtr + PtrsStackOffset)

		-- StdItems - 0x5f9261
	-- CmdSize == 3
	TmpAddrTable = {0x428e5d, 0x4290f0, 0x429350, 0x4295b3, 0x41d36d, 0x453e29}
	SimpleReplacePtrs(TmpAddrTable, 3, 0x5f925c, NewSpacePtr + StdItemsOffset)

	-- CmdSize == 4
	TmpAddrTable = {0x428e7b, 0x42910e, 0x42936e, 0x4295d1}
	SimpleReplacePtrs(TmpAddrTable, 4, 0x5f925c, NewSpacePtr + StdItemsOffset)

		-- SpcItems - 0x5f9444
	-- CmdSize == 2
	TmpAddrTable = {0x428EBD, 0x429150, 0x4293BE, 0x453d25, 0x453e94, 0x453eb3, 0x41d3a0}
	SimpleReplacePtrs(TmpAddrTable, 2, 0x5f943c, NewSpacePtr + SpcItemsOffset)

	-- CmdSize == 4
	TmpAddrTable = {0x428EDA, 0x428F24, 0x428F59, 0x42916D, 0x4291B7, 0x4291F0, 0x4293DB, 0x429425, 0x42945A}
	SimpleReplacePtrs(TmpAddrTable, 4, 0x5f943c, NewSpacePtr + SpcItemsOffset)

		-- Potions
	mem.u4[0x415924 + 4] = NewSpacePtr + PotionsOffset
	mem.u4[0x451369 + 3] = PotionsOffset/2
	mem.u4[0x45141d + 3] = (PotionsOffset + PotionsTxtSize)/2

		-- Potnotes
	mem.u4[0x451512 + 3] = PotnotesOffset/2
	mem.u4[0x4515bf + 3] = (PotnotesOffset + PotnotesTxtSize)/2
	mem.u4[0x415aee + 4] = NewSpacePtr + PotnotesOffset

		-- Pointers to block and Items.txt
	-- CmdSize == 1
	TmpAddrTable = {	-- 0x5efbc8 ptrs
					0x408ef8, 0x4150ec, 0x41f582, 0x424f9f, 0x42506d, 0x4272d6, 0x42c18b, 0x42e2f5, 0x44442c, 0x445514, 0x44dafb,
					0x44dc26, 0x44dc58, 0x44dcb3, 0x44dd93, 0x453d00, 0x453e01, 0x45e86c, 0x4629d3, 0x464067, 0x47ea5c, 0x48e62c,
					0x48e647, 0x491148, 0x4940cf, 0x494da4, 0x4b7417, 0x4b75d8,
						-- 0x5efbcc ptrs
					0x427292, 0x428D29, 0x428FBC, 0x42C143, 0x48D6C9,
						-- 0x5efbe0 ptrs
					0x42e300}

	SimpleReplacePtrs(TmpAddrTable, 1, OldOrigin, NewSpacePtr)

	-- CmdSize == 2
	TmpAddrTable = {	-- 0x5efbc8 ptrs
					0x4949ca,
						-- 0x5efbcc ptrs
					0x41a39a, 0x41ce5e, 0x41f2c7, 0x41f480, 0x41f64e, 0x41ff91, 0x420094, 0x4209f6, 0x42125a, 0x42143b, 0x42921e,
					0x429496, 0x43a2b5, 0x43a53e, 0x43b5e9, 0x43b820, 0x43bbd7, 0x43bd85, 0x43bf5c, 0x467c4c, 0x468243, 0x48c1e0,
					0x48d684, 0x49021c, 0x490269, 0x490e27, 0x490f3c, 0x4911de, 0x4912a4, 0x491369, 0x4ba998, 0x4bb093, 0x4bb181,
					0x4bb32b,
						-- 0x5efbd0 ptrs
					0x453d79, 0x453d8b, 0x453ead,
						-- 0x5efbd4 ptrs
					0x421818, 0x424efa, 0x425084, 0x425112, 0x42ad9b, 0x453d51, 0x4689f3, 0x4b1608,
						-- 0x5efbdc ptrs
					0x453cf7,
						-- 0x5efbe8 ptrs,
					0x415086, 0x41cede, 0x420260, 0x4217ee, 0x424e9f, 0x424f3d, 0x424f79, 0x428ba4, 0x42a627, 0x42a683, 0x42ad7c,
					0x42d8ce, 0x43a91f, 0x43ba35, 0x453d63, 0x45cd4a, 0x45e84c, 0x467224, 0x467459, 0x4689c6, 0x47ea3b, 0x48c8de,
					0x48f229, 0x48f2ff, 0x49156f, 0x49158c,
						-- 0x5efbe9 ptrs
					0x43a928, 0x43a97c, 0x43ba3e, 0x4674db, 0x48c7b9, 0x48c883, 0x48c97b, 0x48e3b1, 0x48e508, 0x49009c, 0x4bb68b,
						-- 0x5efbfa ptrs
					0x415B6F, 0x45425e, 0x48C19B,
						-- 0x5f7f10 ptrs (Message scrolls)
					0x4664ff}

	SimpleReplacePtrs(TmpAddrTable, 2, OldOrigin, NewSpacePtr)

	-- CmdSize == 3
	TmpAddrTable = {	-- 0x5efbe0 ptrs
					0x4030fa, 0x420b00, 0x421360, 0x4444dc, 0x44d865, 0x44d8e3, 0x44dcc6, 0x47cb6d, 0x47dea3, 0x496c01, 0x497d7f,
						-- 0x5efbe4 ptrs
					0x43a509, 0x43b5a0, 0x43b868, 0x43b881,
						-- 0x5efbe6 ptrs
					0x43a52c, 0x43b5cb, 0x43b844, 0x43b894,
						-- 0x5efbe8 ptrs
					0x416095, 0x428e3b, 0x428e56, 0x428e71, 0x428ed3, 0x428f1d, 0x428f52, 0x4290ce, 0x4290e9, 0x429104, 0x429166,
					0x4291b0, 0x4291e9, 0x42932e, 0x429349, 0x429364, 0x4293d4, 0x42941e, 0x429453, 0x429591, 0x4295ac, 0x4295c7,
					0x444422, 0x4665e3, 0x467479, 0x467aea, 0x48cf01, 0x49002f, 0x49104f, 0x494d98, 0x4bb629,
						-- 0x5efbe9 ptrs
					mem.u4[0x42db92] + 5 + 0x42db91, -- MMPatch 2.5 specific
					0x43718c, 0x437b8b, 0x43b7cc, 0x467483, 0x48cf26, 0x48d73a, 0x48d797, 0x48d848, 0x48f150, 0x48f24a,
					0x48f31c, 0x48f423, 0x494db8,
						-- 0x5efbea ptrs
					0x41580f, 0x41d348, 0x48c7c0, 0x48c8eb, 0x48cb3d, 0x48e396, 0x48e409, 0x48e511, 0x48e52f, 0x48e613,	0x48ec6f,
						-- 0x5efbeb ptrs
					0x48c7d4, 0x48c8f4, 0x48cb46, 0x48e518, 0x48e528, 0x48ec68,
						-- 0x5efbec ptrs
					0x4150a8, 0x424f57, 0x4488d7, 0x4542be, 0x48c7fb, 0x48c919, 0x48cb6d, 0x48d2f9, 0x48d300, 0x48e39d, 0x48e402,
					0x48e45b, 0x48e536, 0x48e60c, 0x48ec76, 0x48eccf}

	SimpleReplacePtrs(TmpAddrTable, 3, OldOrigin, NewSpacePtr)

	----

	ChangeGameArray("ItemsTxt", NewSpacePtr + 4, NewItemsCount)
	Game.ItemsTxt.count = NewItemsCount

	ChangeGameArray("StdItemsTxt", NewSpacePtr + StdItemsOffset, NewStdCount)
	ChangeGameArray("SpcItemsTxt", NewSpacePtr + SpcItemsOffset, NewSpcCount)

	structs.o.GameStructure.MixPotions = NewSpacePtr + PotionsOffset
	internal.SetArrayUpval(Game.MixPotions, "o", NewSpacePtr + PotionsOffset)
 	internal.SetArrayUpval(Game.MixPotions, "count", NewPotCount)
	internal.SetArrayUpval(Game.MixPotions, "size", NewPotCount)
	for i=1, NewPotCount do
		internal.SetArrayUpval(Game.MixPotions[i], "count", NewPotCount)
	end

	structs.Item.Randomize = function(self, strength, type, alwaysEnchant)
		self:Clear()
		return mem.call(0x453ECC, 1, NewSpacePtr, assertnum(strength, 2), assertnum(type or 0, 2), self, alwaysEnchant and 1 or 0)
	end
	structs.Item.InitSpecial = function(self)
		mem.call(0x4545E8, 1, NewSpacePtr, self)
	end

	-----

	local GetItemMat = mem.asmproc([[
	; eax - item id
	; returns material (0 - common, 1 - artifact, 2 - relic, 3 - special)

	imul eax, eax, 0x30
	add eax, 0x21
	movsx eax, byte [ds:eax+]] .. Game.ItemsTxt["?ptr"] .. [[];
	retn]])

	NewCode = mem.asmproc([[
	push eax
	movsx eax, cx
	call absolute ]] .. GetItemMat .. [[;
	test eax, eax
	pop eax
	je absolute 0x47a256
	jmp absolute 0x47a23c]])
	mem.asmpatch(0x47a22e, "jmp absolute " .. NewCode)

	-- Enchant item.
	NewCode = mem.asmproc([[
	push eax
	call absolute ]] .. GetItemMat .. [[;
	test eax, eax
	pop eax
	jnz absolute 0x42961c
	jmp absolute 0x428cf9]])
	mem.asmpatch(0x428cee, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	push eax
	call absolute ]] .. GetItemMat .. [[;
	test eax, eax
	pop eax
	jnz absolute 0x42961c
	jmp absolute 0x428f8c]])
	mem.asmpatch(0x428f81, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	push eax
	call absolute ]] .. GetItemMat .. [[;
	test eax, eax
	pop eax
	mov dword [ss:ebp-0x30], ecx
	jnz absolute 0x42961c
	jmp absolute 0x429232]])
	mem.asmpatch(0x429224, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	push eax
	call absolute ]] .. GetItemMat .. [[;
	test eax, eax
	pop eax
	mov dword [ss:ebp-0x30], ecx
	jnz absolute 0x42961c
	jmp absolute 0x4294aa]])
	mem.asmpatch(0x42949c, "jmp absolute " .. NewCode)

	-- Harden item.
	mem.u4[0x416224 + 1] = NewItemsCount

	-- Flame aura
	mem.nop(0x4161e2, 6)

	-- No bonuses on afrtifacts
	NewCode = mem.asmproc([[
	push eax
	call absolute ]] .. GetItemMat .. [[;
	test eax, eax
	pop eax
	je absolute 0x447f64
	jmp absolute 0x448488]])
	mem.asmpatch(0x447f4c, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	push eax
	call absolute ]] .. GetItemMat .. [[;
	test eax, eax
	pop eax
	jmp absolute 0x44889f]])
	mem.asmpatch(0x44889a, "jmp absolute " .. NewCode)
	mem.asmpatch(0x4488a5, "je 0x4488b5 - 0x4488a5")

	NewCode = mem.asmproc([[
	nop
	nop
	nop
	nop
	nop
	pop edi
	pop esi
	pop ebx
	leave
	retn 0x10]])
	mem.asmpatch(0x454571, "jmp absolute " .. NewCode)

	mem.hook(NewCode, function(d)

		local Item = structs.Item:new(d.esi)

		events.call("ItemGeneratedM", Item)

		local ItemTxt = Game.ItemsTxt[Item.Number]
		if ItemTxt.Value == 0 or ItemTxt.Material > 0 then
			Item.Bonus 		= 0
			Item.Bonus2 	= 0
			Item.Charges 	= 0
			Item.MaxCharges = 0
		end

	end)

	-- Fix club's attack delay and sound
	local DelaysPtr = mem.u4[0x48D68E + 4]
	NewCode = mem.asmproc([[
	cmp eax, 0x27
	jnz @std
	mov eax, 0x4
	@std:
	movzx eax, word [ds:eax*2+]] .. DelaysPtr ..[[]
	retn]])
	for k,v in pairs({0x48D68E,0x48D70B,0x48D741}) do
		mem.asmpatch(v, "call absolute " .. NewCode)
	end

	mem.asmpatch(0x48D7A3, [[
	cmp ebx, 0x27
	jnz @std
	mov ebx, 0x4
	@std:
	movzx eax, word [ds:ebx*2+]] .. DelaysPtr ..[[];]])
	mem.asmpatch(0x48D84F, [[
	cmp eax, 0x27
	jnz @std
	mov eax, 0x4
	@std:
	movzx ecx, word [ds:eax*2+]] .. DelaysPtr ..[[];]])

	mem.asmpatch(0x42dba0, [[
	call absolute 0x4049ba
	cmp dword [ss:ebp-0x18], 0x27
	jnz @std
	push 0x53
	jmp absolute 0x42dbd3

	@std:]])

	-- evt.SummonObject correction

	mem.u4[0x444405 + 1] = NewItemsCount

	----

	mem.IgnoreProtection(false)

end

local function SetupItemPicsHandler()

	local NewCode
	local ArmorIndexTable, BeltsIndexTable, BootsIndexTable, HelmsIndexTable, CloaksIndexTable, ComplexCollarsIndexTable, HatsIndexTable, ComplexBeltsIndexTable
	local TmpArmorT, TmpHelmsT, TmpBeltsT, TmpCloaksT, TmpBootsT, ComplexCollars, Hats, ComplexBelts = {}, {}, {}, {}, {}, {}, {}, {}
	local ArmorCount, BeltsCount, BootsCount, HelmsCount, CloaksCount = 0, 0, 0, 0, 0
	local ComplexItems, ComplexCount = {}, 0
	local ItemCoordsPtr, ArmorCoordsPtr, HelmCoordsPtr, BeltCoordsPtr, CloakCoordsPtr, BootsCoordPtr, CountersPtr, LoadedPicsOffsets, ItemsInInventoryFlags

	local TypesCount = 4

	if Game.CharacterDollTypes then
		TypesCount = Game.CharacterDollTypes.count
	end

	---- Items extra
	local ItemsExtraData = mem.StaticAlloc(Game.ItemsTxt.count*4)
	local ItemTypesCnts = {}
	for i,v in Game.ItemsTxt do

		ItemTypesCnts[v.EquipStat] = (ItemTypesCnts[v.EquipStat] or 0) + 1
		mem.u2[ItemsExtraData+i*4] = ItemTypesCnts[v.EquipStat]
		mem.u2[ItemsExtraData+i*4+2] = v.EquipStat

		local EquipStat = v.EquipStat

		if EquipStat == 3 then
			ArmorCount = ArmorCount + 1
			table.insert(TmpArmorT, i)
		elseif EquipStat == 5 then
			HelmsCount = HelmsCount + 1
			table.insert(TmpHelmsT, i)
		elseif EquipStat == 6 then
			BeltsCount = BeltsCount + 1
			table.insert(TmpBeltsT, i)
		elseif EquipStat == 7 then
			CloaksCount = CloaksCount + 1
			table.insert(TmpCloaksT, i)
		elseif EquipStat == 9 then
			BootsCount = BootsCount + 1
			table.insert(TmpBootsT, i)
		end

	end

	ItemTypesCnts = nil

	ComplexCount = ArmorCount + HelmsCount + BeltsCount + CloaksCount + BootsCount

			-- ItemPicsTable:

	local function GenerateItemPicsTable()

		local ItemPicsTable = io.open("Data/Tables/Complex item pictures.txt", "w")

		local ManPicCo, WomanPicCo, MinPicCo, TrollPicCo = {0,0}, {0,0}, {0,0}, {0,0}

		local function AddLine(Id, PicId, Setting)
			ItemPicsTable:write(Id .. "\9" .. PicId .. "\9" .. Game.ItemsTxt[PicId].Name .. "\9" .. Setting ..
				"\9" .. ManPicCo[1]	.. "\9" .. ManPicCo[2]	.. "\9" .. WomanPicCo[1]	.. "\9" .. WomanPicCo[2] ..
				"\9" .. MinPicCo[1]	.. "\9" .. MinPicCo[2]	.. "\9" .. TrollPicCo[1]	.. "\9" .. TrollPicCo[2] .. "\n" )
		end

		-- Armors

		ItemPicsTable:write("\9\9Armors\9Settings\9t0\9\9t1\9\9t2\9\9t3\9\n")
		ItemPicsTable:write("Id\9Item id\9Notes\9\9X\9Y\9X\9Y\9X\9Y\9X\9Y\9X\9Y\9X\9Y\9X\9Y\9X\9Y\n")
		for i,v in ipairs(TmpArmorT) do

			if i < 20 and v > 83 then
				ManPicCo 	= {mem.i4[0x4f5a98 + (i-1)*8], mem.i4[0x4f5a9C + (i-1)*8]}
				WomanPicCo 	= {mem.i4[0x4f5b30 + (i-1)*8], mem.i4[0x4f5b34 + (i-1)*8]}
				MinPicCo 	= {mem.i4[0x4f5bc8 + (i-1)*8], mem.i4[0x4f5bcc + (i-1)*8]}
				TrollPicCo 	= {mem.i4[0x4f5c60 + (i-1)*8], mem.i4[0x4f5c64 + (i-1)*8]}
			else
				ManPicCo 	= {0,0}
				WomanPicCo 	= {0,0}
				MinPicCo 	= {0,0}
				TrollPicCo 	= {0,0}
			end

			AddLine(i, v, "")

		end

		-- Helms

		ItemPicsTable:write("\n")
		ItemPicsTable:write("\9\9Helms\9Complex\9\9\9\9\9\9\9\9\n")
		for i,v in ipairs(TmpHelmsT) do

			local Complex = ""

			if i >= 6 and i <= 8 then
				Complex = ""
			else
				Complex = "x"
			end

			if i < 12 then
				ManPicCo 	= {mem.i4[0x4f5ff8 + (i-1)*8], mem.i4[0x4f5ffc + (i-1)*8]}
				WomanPicCo 	= {mem.i4[0x4f6050 + (i-1)*8], mem.i4[0x4f6054 + (i-1)*8]}
				MinPicCo 	= {mem.i4[0x4f60a8 + (i-1)*8], mem.i4[0x4f60ac + (i-1)*8]}
				TrollPicCo 	= {mem.i4[0x4f6100 + (i-1)*8], mem.i4[0x4f6104 + (i-1)*8]}
			else
				ManPicCo 	= {0,0}
				WomanPicCo 	= {0,0}
				MinPicCo 	= {0,0}
				TrollPicCo 	= {0,0}
			end

			AddLine(i, v, Complex)

		end

		-- Belts

		ItemPicsTable:write("\n")
		ItemPicsTable:write("\9\9Belts\9Complex\9\9\9\9\9\9\9\9\n")
		for i,v in ipairs(TmpBeltsT) do

			if i < 7 then
				ManPicCo 	= {mem.i4[0x4f5f38 + (i-1)*8], mem.i4[0x4f5f3c + (i-1)*8]}
				WomanPicCo 	= {mem.i4[0x4f5f68 + (i-1)*8], mem.i4[0x4f5f6c + (i-1)*8]}
				MinPicCo 	= {mem.i4[0x4f5f98 + (i-1)*8], mem.i4[0x4f5f9c + (i-1)*8]}
				TrollPicCo 	= {mem.i4[0x4f5fc8 + (i-1)*8], mem.i4[0x4f5fcc + (i-1)*8]}
			else
				ManPicCo 	= {0,0}
				WomanPicCo 	= {0,0}
				MinPicCo 	= {0,0}
				TrollPicCo 	= {0,0}
			end

			AddLine(i, v, "")

		end

		-- Boots

		ItemPicsTable:write("\n")
		ItemPicsTable:write("\9\9Boots\9n/u\n")
		for i,v in ipairs(TmpBootsT) do

			if i < 7 then
				ManPicCo 	= {mem.i4[0x4f5cf8 + (i-1)*8], mem.i4[0x4f5cfc + (i-1)*8]}
				WomanPicCo 	= {mem.i4[0x4f5d28 + (i-1)*8], mem.i4[0x4f5d2c + (i-1)*8]}
				MinPicCo 	= {mem.i4[0x4f5d58 + (i-1)*8], mem.i4[0x4f5d5c + (i-1)*8]}
				TrollPicCo 	= {mem.i4[0x4f5d88 + (i-1)*8], mem.i4[0x4f5d8c + (i-1)*8]}
			else
				ManPicCo 	= {0,0}
				WomanPicCo 	= {0,0}
				MinPicCo 	= {0,0}
				TrollPicCo 	= {0,0}
			end

			AddLine(i, v, "")

		end

		-- Cloaks

		ItemPicsTable:write("\n")
		ItemPicsTable:write("\9\9Cloaks\9Complex\9\9\9\9\9\9\9\9\9Collars\9\9\9\9\9\9\9\n")
		local ComplexCollar = ""
		for i,v in ipairs(TmpCloaksT) do

			if i < 7 then
				ManPicCo 	= {mem.i4[0x4f5db8 + (i-1)*8], mem.i4[0x4f5dbc + (i-1)*8], mem.i4[0x4f5e78 + (i-1)*8], mem.i4[0x4f5e7c + (i-1)*8]}
				WomanPicCo 	= {mem.i4[0x4f5de8 + (i-1)*8], mem.i4[0x4f5dec + (i-1)*8], mem.i4[0x4f5ea8 + (i-1)*8], mem.i4[0x4f5eac + (i-1)*8]}
				MinPicCo 	= {mem.i4[0x4f5e18 + (i-1)*8], mem.i4[0x4f5e1c + (i-1)*8], mem.i4[0x4f5ed8 + (i-1)*8], mem.i4[0x4f5edc + (i-1)*8]}
				TrollPicCo 	= {mem.i4[0x4f5e48 + (i-1)*8], mem.i4[0x4f5e4c + (i-1)*8], mem.i4[0x4f5f08 + (i-1)*8], mem.i4[0x4f5f0c + (i-1)*8]}

				if i == 5 then
					ComplexCollar = "x"
				else
					ComplexCollar = ""
				end
			else
				ManPicCo 	= {0,0,0,0}
				WomanPicCo 	= {0,0,0,0}
				MinPicCo 	= {0,0,0,0}
				TrollPicCo 	= {0,0,0,0}
			end

			ItemPicsTable:write(i .. "\9" .. v .. "\9" .. Game.ItemsTxt[v].Name .. "\9" .. ComplexCollar ..
				"\9" .. ManPicCo[1]		.. "\9" .. ManPicCo[2]		..
				"\9" .. WomanPicCo[1]	.. "\9" .. WomanPicCo[2] 	..
				"\9" .. MinPicCo[1]		.. "\9" .. MinPicCo[2] 		..
				"\9" .. TrollPicCo[1]	.. "\9" .. TrollPicCo[2]	..

				"\9" .. ManPicCo[3]		.. "\9" .. ManPicCo[4]		..
				"\9" .. WomanPicCo[3]	.. "\9" .. WomanPicCo[4]	..
				"\9" .. MinPicCo[3]		.. "\9" .. MinPicCo[4]		..
				"\9" .. TrollPicCo[3]	.. "\9" .. TrollPicCo[4]	..

				"\n" )

		end

			io.close(ItemPicsTable)

	end

	local function LoadItemPicsTable()

		-- Setup space for coordinates
		ItemPicsTable = io.open("Data/Tables/Complex item pictures.txt", "r")

		if not ItemPicsTable then
			GenerateItemPicsTable()
			ItemPicsTable = io.open("Data/Tables/Complex item pictures.txt", "r")
		end

		ItemCoordsPtr = mem.StaticAlloc(TypesCount*4*ComplexCount + CloaksCount*4*TypesCount + 0x10)
		ArmorCoordsPtr = ItemCoordsPtr
		HelmCoordsPtr = ArmorCoordsPtr + ArmorCount*4*TypesCount
		BeltCoordsPtr = HelmCoordsPtr + HelmsCount*4*TypesCount
		BootsCoordPtr = BeltCoordsPtr + BeltsCount*4*TypesCount
		CloakCoordsPtr = BootsCoordPtr + BootsCount*4*TypesCount
		----

		local LineIt = ItemPicsTable:lines()
		local Words, CurId, Am
		local IsCloak = false
		local Counter, CloakCounter = 0, 0

		LineIt()
		LineIt()

		local NamesTable = {"Armors", "Helms", "Belts", "Boots", "Cloaks"}
		for Ri, Rv in ipairs({TmpArmorT, TmpHelmsT, TmpBeltsT, TmpBootsT, TmpCloaksT}) do

			line = LineIt()
			IsCloak = NamesTable[Ri] == "Cloaks"

			while line ~= nil do
				Words = string.split(line, "\9")
				if tonumber(Words[2]) then
					break
				else
					line = LineIt()
				end
			end

			while table.maxn(Rv) > 0 do
				local TLen = table.maxn(Rv)

				for i = 1, TLen do
					local v = Rv[i]

					if line ~= nil then
						Words = string.split(line, "\9")
						CurId = tonumber(Words[2])
					else
						CurId = nil
					end

					if CurId ~= nil then

						if not table.find(Rv, CurId) then
							error("Wrong item index (" .. CurId .. " in '" .. NamesTable[Ri] .. "' at " .. Words[1] .. ") in 'Complex item pictures.txt'.", 2)
						end

						if CurId == v then
							table.insert(ComplexItems, CurId)

							if Words[4] == "x" then
								if NamesTable[Ri] == "Helms" then
									table.insert(Hats, CurId)
								elseif NamesTable[Ri] == "Belts" then
									table.insert(ComplexBelts, CurId)
								elseif IsCloak then
									table.insert(ComplexCollars, CurId)
								end
							end

							if IsCloak then
								for Di = 0, TypesCount-1 do
									local ItemX = tonumber(Words[Di*2+5])
									local ItemY = tonumber(Words[Di*2+6])

									if not ItemX then ItemX = 0 end
									if not ItemY then ItemY = 0 end

									mem.i2[ItemCoordsPtr+Counter*4*TypesCount + 8*Di] = ItemX
									mem.i2[ItemCoordsPtr+2+Counter*4*TypesCount + 8*Di] = ItemY

									ItemX = tonumber(Words[Di*2+5+TypesCount*2])
									ItemY = tonumber(Words[Di*2+6+TypesCount*2])

									if not ItemX then ItemX = 0 end
									if not ItemY then ItemY = 0 end

									mem.i2[ItemCoordsPtr+Counter*4*TypesCount + 8*Di + 4] = ItemX
									mem.i2[ItemCoordsPtr+2+Counter*4*TypesCount + 8*Di + 4] = ItemY
								end
							else
								for Di = 0, TypesCount-1 do
									local ItemX = tonumber(Words[Di*2+5])
									local ItemY = tonumber(Words[Di*2+6])

									if not ItemX then ItemX = 0 end
									if not ItemY then ItemY = 0 end

									mem.i2[ItemCoordsPtr+Counter*4*TypesCount + 4*Di] = ItemX
									mem.i2[ItemCoordsPtr+2+Counter*4*TypesCount + 4*Di] = ItemY
								end
							end

							table.remove(Rv, i)
							i = i - 1
							TLen  = TLen - 1
							if IsCloak then
								Counter = Counter + 2
							else
								Counter = Counter + 1
							end
							line = LineIt()
						end
					else
						table.insert(ComplexItems, v)
						if IsCloak then
							Am = TypesCount*2-1
						else
							Am = TypesCount-1
						end
						for Di = 0, Am do
							mem.i2[ItemCoordsPtr+Counter*4*TypesCount + 4*Di] = 0
							mem.i2[ItemCoordsPtr+2+Counter*4*TypesCount + 4*Di] = 0
						end
						table.remove(Rv, i)
						i = i - 1
						TLen  = TLen - 1
						if IsCloak then
							Counter = Counter + 2
						else
							Counter = Counter + 1
						end
					end
				end
			end

			while line ~= nil do
				Words = string.split(line, "\9")
				if not tonumber(Words[2]) then
					break
				else
					line = LineIt()
				end
			end

		end

		io.close(ItemPicsTable)

	end

	LoadItemPicsTable()

	local function GenerateOffsetsTable()
		OffsetsTable = io.open("Data/Tables/Complex item pictures offsets.txt", "w")
		if OffsetsTable then
			OffsetsTable:write("Portrait id\9Item id\9X\9Y\n")
			OffsetsTable:write("26\t908\t4\t-3\n")
			OffsetsTable:close()
		end
	end

	local function LoadOffsetsTable()
		Game.ArmorPicsOffsets = {}
		OffsetsTable = io.open("Data/Tables/Complex item pictures offsets.txt", "r")
		if not OffsetsTable then
			GenerateOffsetsTable()
			Game.ArmorPicsOffsets = {[26] = {[908] = {X = 4, Y = -3}}}
			return
		end

		local LineIt = OffsetsTable:lines()
		LineIt() -- skip header

		local words, portrait, item, x, y
		for line in LineIt do
			words = line:split('\9')
			portrait, item, x, y = unpack(words)
			portrait = tonumber(portrait)
			item = tonumber(item)
			if portrait and item then
				local t = tget(Game.ArmorPicsOffsets, portrait)
				t[item] = {X = tonumber(x) or 0, Y = tonumber(y) or 0}
			end
		end
		OffsetsTable:close()
	end
	LoadOffsetsTable()
	-- Setup structures

	local function ChangeItemPicsArray(name, p, count)
		structs.o.ArmorPicsCoords[name] = p
		internal.SetArrayUpval(Game.ArmorPicsCoords[name], "o", p)
		internal.SetArrayUpval(Game.ArmorPicsCoords[name], "count", count)
		internal.SetArrayUpval(Game.ArmorPicsCoords[name], "size", TypesCount*(name == "Cloaks" and 8 or 4))

		for i = 1, Game.ArmorPicsCoords[name].count do
			internal.SetArrayUpval(Game.ArmorPicsCoords[name][i], "count", TypesCount)
		end
	end

	ChangeItemPicsArray("Armors", ArmorCoordsPtr, ArmorCount)
	ChangeItemPicsArray("Helms", HelmCoordsPtr, HelmsCount)
	ChangeItemPicsArray("Belts", BeltCoordsPtr, BeltsCount)
	ChangeItemPicsArray("Boots", BootsCoordPtr, BootsCount)
	ChangeItemPicsArray("Cloaks", CloakCoordsPtr, CloaksCount)

	do -- convenience map (Game.ArmorPicsCoords[ItemId] = ItemCoords)
		local Counts = {}
		local Names = {[3] = "Armors", [5] = "Helms", [6] = "Belts", [7] = "Cloaks", [9] = "Boots"}

		local es, val, name
		for i,v in Game.ItemsTxt do
			es = v.EquipStat
			name = Names[es]
			if name then
				val = Counts[es] or 1
				Game.ArmorPicsCoords[i] = Game.ArmorPicsCoords[name][val]
				Counts[es] = val + 1
			end
		end
	end

	-- Synchronize index tables with data in .txt
	local TmpTables, ItemCounts, IndexPtrs

	TmpTables 	= {TmpArmorT, TmpHelmsT, TmpBeltsT, TmpBootsT, TmpCloaksT}
	ItemCounts 	= {ArmorCount, HelmsCount, BeltsCount, BootsCount, CloaksCount}

	Counter = 1
	for i,v in ipairs(TmpTables) do
		for iT = 1, ItemCounts[i] do
			v[iT] = ComplexItems[Counter]
			Counter = Counter + 1
		end
	end
	----

	-- Setup space for index tables
	local StdOffset = math.max(BeltsCount, CloaksCount, BootsCount)
	local PicsHandlerSpacePtr	= mem.StaticAlloc(ComplexCount*3 + 0x14 + table.maxn(ComplexCollars)*2 + table.maxn(Hats)*2 + table.maxn(ComplexBelts)*2 + ArmorCount*TypesCount*12 + StdOffset*3*TypesCount*12 + CloaksCount*TypesCount*12 + 0x18)
	ItemsInInventoryFlags = PicsHandlerSpacePtr
	CountersPtr			= PicsHandlerSpacePtr + ComplexCount + 2
	ComplexIndexTable	= PicsHandlerSpacePtr + ComplexCount + 0x16
	ArmorIndexTable		= PicsHandlerSpacePtr + ComplexCount + 0x16
	HelmsIndexTable 	= ArmorIndexTable + ArmorCount*2
	BeltsIndexTable		= HelmsIndexTable + HelmsCount*2
	BootsIndexTable		= BeltsIndexTable + BeltsCount*2
	CloaksIndexTable	= BootsIndexTable + BootsCount*2
	ComplexCollarsIndexTable = CloaksIndexTable + CloaksCount*2
	HatsIndexTable = ComplexCollarsIndexTable + table.maxn(ComplexCollars)*2
	ComplexBeltsIndexTable = HatsIndexTable + table.maxn(Hats)*2
	LoadedPicsOffsets = ComplexBeltsIndexTable + table.maxn(ComplexBelts)*2

	-- Fill index
	TmpTables 	= {TmpArmorT, TmpHelmsT, TmpBeltsT, TmpBootsT, TmpCloaksT, ComplexCollars, Hats, ComplexBelts}
	ItemCounts 	= {ArmorCount, HelmsCount, BeltsCount, BootsCount, CloaksCount, table.maxn(ComplexCollars), table.maxn(Hats), table.maxn(ComplexBelts)}
	IndexPtrs	= {ArmorIndexTable, HelmsIndexTable, BeltsIndexTable, BootsIndexTable, CloaksIndexTable, ComplexCollarsIndexTable, HatsIndexTable, ComplexBeltsIndexTable}

	for iR = 1, table.maxn(TmpTables) do

		for i, v in ipairs(TmpTables[iR]) do
			mem.u2[IndexPtrs[iR] + (i-1)*2] = v
		end
		mem.u2[CountersPtr + (iR-1)*2] = 0

	end

	-- Limits:
	mem.IgnoreProtection(true)
	mem.u4[0x439ab9 + 3] = ItemsInInventoryFlags
	mem.u4[0x439ad3 + 2] = ItemsInInventoryFlags
	mem.u4[0x439aed + 2] = ItemsInInventoryFlags
	-- Corrected inside hooks:
	--mem.u4[0x439ac6 + 3] = ItemsInInventoryFlags
	--mem.u4[0x43a197 + 2] = ItemsInInventoryFlags - 0x54
	mem.IgnoreProtection(false)

	----------------------
	---- Setup code.

	-- Setup "in inventory" flags.
	NewCode = mem.asmproc([[
	movzx ecx, word [ds:]] .. ComplexIndexTable .. [[ + eax*2];
	jmp absolute 0x439acd]])
	mem.asmpatch(0x439ac6, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	cmp eax, ]] .. ComplexCount .. [[;
	mov dword [ss:ebp-0x8], eax
	jmp absolute 0x439afb]])
	mem.asmpatch(0x439af5, "jmp absolute " .. NewCode)
	----

	-- Shrink flags table - seek index by type instead of global index.
	NewCode = mem.asmproc([[
	push eax
	push ecx
	push ebx
	mov ebx, 2
	mov eax, ]] .. ComplexIndexTable .. [[;
	mov ecx, ]] .. ComplexCount .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	je @Oth

	neg ecx
	lea ecx, dword [ds:]] .. ComplexCount .. [[+ecx];
	cmp byte [ds:ecx + ]] .. ItemsInInventoryFlags .. [[], 0
	jmp @end

	@Oth:
	cmp byte [ds:edx+0x5228c4], 0

	@end:
	pop ebx
	pop ecx
	pop eax
	jmp absolute 0x43a19e]])
	mem.asmpatch(0x43a197, "jmp absolute " .. NewCode)
	----

	-- Offsets to loaded pics:


	if Game.CharacterPortraits then

		-- limit of dolls with armors to draw
		mem.asmpatch(0x43a8b2, "jnz 0x43a8c9 - 0x43a8b2")
		mem.asmpatch(0x43a8a6, [[
		mov ebx, dword [ss:esp+0x24]
		imul ebx, ebx, ]] .. Game.CharacterDollTypes[0]["?size"] .. [[;
		add ebx, ]] .. Game.CharacterDollTypes["?ptr"] .. [[;
		inc ebx
		mov ebx, dword [ds:ebx]
		test ebx, ebx
		mov ebx, 0]])

		-- limit of dolls with armors to load
		-- Very strange procedure was here.
		-- Don't load excess pictures:
		local function GetPlayer(ptr)
			local PlayerId = (ptr - Party.PlayersArray["?ptr"])/Party.PlayersArray[0]["?size"]
			return Party.PlayersArray[PlayerId], PlayerId
		end

		mem.hook(0x439c2b, function(d)
			if d.eax-1 == Game.CharacterPortraits[Game.CurrentCharPortrait].DollType then
				events.call("LoadInventoryPics", GetPlayer(d.edx))
				d.eax = 1
			else
				d.eax = 0
			end

		end)

		mem.IgnoreProtection(true)
		mem.u1[0x43a067 + 2] = TypesCount
		mem.IgnoreProtection(false)

	end

	local ArmorPicsOffset, HelmPicsOffset, BeltsPicsOffset, CloakPicsOffset, BootsPicsOffset
	ArmorPicsOffset = LoadedPicsOffsets + 0x10
	HelmPicsOffset = ArmorPicsOffset + ArmorCount*TypesCount*12
	BeltsPicsOffset = HelmPicsOffset + StdOffset*TypesCount*12
	BootsPicsOffset = BeltsPicsOffset + StdOffset*TypesCount*12
	CloakPicsOffset = BootsPicsOffset + StdOffset*TypesCount*12

	-- Belts offsets setup:
	mem.asmpatch(0x439c3b, "lea eax, dword [ds:eax+" .. BeltsPicsOffset .. "]")

	NewCode = mem.asmproc([[
	push dword [ss:ebp-0x4];
	movzx edx, word [ds:edi*2+]] .. BeltsIndexTable	.. [[];
	jmp absolute 0x439c4d]])
	mem.asmpatch(0x439c47, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	cmp edi, ]] .. BeltsCount .. [[;
	mov dword [ds:ecx], eax
	jmp absolute 0x439c71]])
	mem.asmpatch(0x439c6c, "jmp absolute " .. NewCode)

	mem.IgnoreProtection(true)
	mem.u4[0x43ae94 + 3] = BeltsPicsOffset
	mem.IgnoreProtection(false)

		-- Cut off old artifacts and relics init:
	mem.asmpatch(0x439c73, "jmp absolute 0x439c93")
	mem.nop(0x439c99, 6)
	----

	-- Helms offsets setup:
	mem.asmpatch(0x439c9f, "mov eax, edi")

	NewCode = mem.asmproc([[
	push dword [ss:ebp-4]
	movzx edx, word [ds:eax*2+]] .. HelmsIndexTable .. [[];
	jmp absolute 0x439cb2]])
	mem.asmpatch(0x439cac, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	cmp dword [ss:ebp-8], ]] .. HelmsCount .. [[;
	mov dword [ds:ecx], eax
	jmp absolute 0x439cd9]])
	mem.asmpatch(0x439cd3, "jmp absolute " .. NewCode)

	mem.IgnoreProtection(true)
	mem.u4[0x43b24c + 3] = HelmPicsOffset
	mem.u4[0x439c1e + 3] = HelmPicsOffset
	mem.IgnoreProtection(false)

		-- Cut off old artifacts and relics init:
	mem.asmpatch(0x439cdb, "jmp absolute 0x439d43")
	----

	-- Armor offsets setup:
	mem.asmpatch(0x439c17, "mov dword [ss:ebp-0x18], " .. ArmorPicsOffset)
	mem.asmpatch(0x439d46, "mov eax, edi")
	mem.asmpatch(0x439d4c, "mov dword [ss:ebp-8], " .. TmpArmorT[1])

		-- Proccess armor - end of cycle
	NewCode = mem.asmproc([[
	inc word [ds:]] .. CountersPtr .. [[];
	movzx eax, word [ds:]] .. CountersPtr .. [[]
	cmp eax, ]] .. ArmorCount .. [[;
	jge @end

	push eax
	movzx eax, word [ds:]] .. ArmorIndexTable .. [[+eax*2]
	mov dword [ss:ebp-0x8], eax
	pop eax
	jmp @rep

	@end:
	mov word [ds:]] .. CountersPtr .. [[], 0
	@rep:
	jmp absolute 0x439dd3]])
	mem.asmpatch(0x439dcd, "jmp absolute " .. NewCode)
	mem.nop(0x439dca, 3)

	mem.IgnoreProtection(true)
	mem.u4[0x43aae8 + 3] = ArmorPicsOffset
	mem.u4[0x43aaf1 + 3] = ArmorPicsOffset - 0x4
	mem.IgnoreProtection(false)

		-- Cut off old artifacts and relics init:
	mem.asmpatch(0x439dd5, "jmp absolute 0x439ef0")
	----

	-- Boots offsets setup:
	mem.asmpatch(0x439ef3, "lea eax, dword [ds:eax+" .. BootsPicsOffset .. "];")
	mem.asmpatch(0x439f06, "movzx edx, word [ds:eax*2+" .. BootsIndexTable .. "];")

	NewCode = mem.asmproc([[
	cmp dword [ss:ebp-8], ]] .. BootsCount .. [[;
	mov dword [ds:ecx], eax
	jmp absolute 0x439f33]])
	mem.asmpatch(0x439f2d, "jmp absolute " .. NewCode)

	mem.IgnoreProtection(true)
	mem.u4[0x43acb7 + 3] = BootsPicsOffset
	mem.IgnoreProtection(false)

		-- Cut off old artifacts and relics init:
	mem.asmpatch(0x439f35, "jmp absolute 0x439f55")
	mem.nop(0x439f58, 6)

	-- Cloaks offsets setup:
	mem.asmpatch(0x439f5e, "mov dword [ss:ebp-8], " .. TmpCloaksT[1])

	mem.IgnoreProtection(true)
	-- Write
	mem.u4[0x439f91 + 2] = CloakPicsOffset + CloaksCount*4*TypesCount*2
	mem.u4[0x439fb7 + 2] = CloakPicsOffset + CloaksCount*4*TypesCount
	mem.u4[0x439fde + 2] = CloakPicsOffset

	-- Read
	mem.u4[0x43a726 + 3] = CloakPicsOffset + CloaksCount*4*TypesCount*2
	mem.u4[0x43b052 + 3] = CloakPicsOffset + CloaksCount*4*TypesCount
	mem.u4[0x43b3f2 + 3] = CloakPicsOffset

	mem.IgnoreProtection(false)

	NewCode = mem.asmproc([[
	inc word [ds:]] .. CountersPtr + 2 .. [[];
	movzx eax, word [ds:]] .. CountersPtr + 2 .. [[]
	cmp eax, ]] .. CloaksCount .. [[;
	jge @end

	push eax
	movzx eax, word [ds:]] .. CloaksIndexTable .. [[+eax*2]
	mov dword [ss:ebp-0x8], eax
	pop eax
	jmp @rep

	@end:
	mov word [ds:]] .. CountersPtr + 2 .. [[], 0
	@rep:
	jmp absolute 0x439ff4]])
	mem.asmpatch(0x439fee, "jmp absolute " .. NewCode)
	mem.nop(0x439fe8, 3)

	-- Cut off old artifacts and relics init:
	mem.asmpatch(0x439ffa, "jmp absolute 0x43a04d")

	----

	-- Step shifts.
	NewCode = mem.asmproc([[
	add dword [ss:ebp-0x14], ]] .. HelmsCount*4 .. [[;
	add dword [ss:ebp-0xC], ]] .. StdOffset*4 .. [[;
	add edi, ]] ..  ArmorCount*12 .. [[;
	jmp absolute 0x43a060]])
	mem.asmpatch(0x43a052, "jmp absolute " .. NewCode)
	----

	local ItemBeingProcessed = mem.StaticAlloc(4)
	local GetItemIdByType = mem.asmproc([[
	; eax - item id
	; ecx - required EquipStat

	mov dword [ds:]] .. ItemBeingProcessed .. [[], eax

	lea eax, dword [ds:eax*4]
	add eax, ]] .. ItemsExtraData .. [[;
	cmp word [ds:eax+2], cx
	jnz @neq
	movzx eax, word [ds:eax]
	dec eax
	mov ecx, eax
	jmp @end

	@neq:
	xor ecx, ecx
	xor eax, eax
	dec eax

	@end:
	retn]])

	local function ItemPicCoords(ItemId, Collar)
		local DollType = Game.CharacterPortraits[Game.CurrentCharPortrait].DollType
		local Offsets = Game.ArmorPicsOffsets[Game.CurrentCharPortrait]
		local Set = Game.ArmorPicsCoords[ItemId][DollType]
		local oX, oY = 0, 0

		if Offsets and Offsets[ItemId] then
			Offsets = Offsets[ItemId]
			oX, oY = Offsets.X, Offsets.Y
		end

		if Collar then
			return Set.ColX + oX, Set.ColY + oY
		else
			return Set.X + oX, Set.Y + oY
		end
	end

	local ItemPicCoordsAsm = mem.asmproc([[
	;returns X in eax, Y in ecx
	call absolute 0x42edd8; memhook here
	retn]])
	mem.hook(ItemPicCoordsAsm, function(d)
		d.eax, d.ecx = ItemPicCoords(mem.u4[ItemBeingProcessed], false)
	end)

	local CollarPicCoordsAsm = mem.asmproc([[
	;returns X in eax, Y in ecx
	call absolute 0x42edd8; memhook here
	retn]])
	mem.hook(CollarPicCoordsAsm, function(d)
		d.eax, d.ecx = ItemPicCoords(mem.u4[ItemBeingProcessed], true)
	end)

	---- Use new table and new offsets
	-- Read new boots data:

	mem.nop(0x43ac71, 2)
	mem.nop(0x43ac85, 9)

	NewCode = mem.asmproc([[
	mov ecx, 9
	call absolute ]] .. GetItemIdByType .. [[;
	jmp absolute 0x43ac78]])
	mem.asmpatch(0x43ac73, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	;eax - index by type of boots
	;ecx - doll type id (0 - man, 1 - woman, 2 - minotaur, 3 - troll)

	push eax
	push ecx

	call absolute ]] .. ItemPicCoordsAsm .. [[;

	add eax, dword [ds:0x4f5890]
	mov dword [ss:esp+0x1c], eax; 0x18fcec

	add ecx, dword [ds:0x4f5894]
	mov dword [ss:esp+0x18], ecx; 0x18fce8

	pop ecx
	pop eax
	push ebx

	imul ecx, ecx, ]] .. StdOffset .. [[;
	add eax, ecx

	jmp absolute 0x43acb7]])
	mem.asmpatch(0x43ac92, "jmp absolute " .. NewCode)
	mem.nop(0x43acc5, 4)

	-- Read new belts data:
	mem.nop(0x43ae50, 2)
	mem.nop(0x43ae62, 9)

	NewCode = mem.asmproc([[
	mov ecx, 6
	call absolute ]] .. GetItemIdByType .. [[;
	jmp absolute 0x43ae5a]])
	mem.asmpatch(0x43ae52, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	;eax - index by type of belts
	;ecx - doll type id (0 - man, 1 - woman, 2 - minotaur, 3 - troll)

	push eax
	push ecx

	call absolute ]] .. ItemPicCoordsAsm .. [[;

	add eax, dword [ds:0x4f5890]
	mov dword [ss:esp+0x1c], eax; 0x18fcec

	add ecx, dword [ds:0x4f5894]
	mov dword [ss:esp+0x18], ecx; 0x18fce8

	pop ecx
	pop eax
	push ebx

	imul ecx, ecx, ]] .. StdOffset .. [[;
	add eax, ecx

	jmp absolute 0x43ae94]])

	mem.asmpatch(0x43ae6f, "jmp absolute " .. NewCode)
	mem.nop(0x43aea2, 4)

	-- Read new helms data:

	mem.nop(0x43b1f8, 10)
	mem.nop(0x43b21b, 9)

	NewCode = mem.asmproc([[
	mov ecx, 5
	call absolute ]] .. GetItemIdByType .. [[;
	jmp absolute 0x43b213]])
	mem.asmpatch(0x43b202, "jmp absolute " .. NewCode)

	if Game.CharacterPortraits then
		NewCode = mem.asmproc([[
		;eax - index by type
		;ecx - doll type id (0 - man, 1 - woman, 2 - minotaur, 3 - troll)

			; get face
			mov ebx, dword[ss:esp+0x1c]
			movzx ebx, byte[ds:ebx+0x353]

			; get portrait ptr
			imul ebx, ebx, ]] .. Game.CharacterPortraits[0]["?size"] ..[[;
			add ebx, ]] .. Game.CharacterPortraits["?ptr"] .. [[;

		push eax
		push ecx

		call absolute ]] .. ItemPicCoordsAsm .. [[;

		add eax, dword [ds:0x4f5890]
		mov dword [ss:esp+0x1c], eax; 0x18fcec

		add ecx, dword [ds:0x4f5894]
		mov dword [ss:esp+0x18], ecx; 0x18fce8

		; get helm X
		movsx ecx, word [ds:ebx + ]] .. Game.CharacterPortraits[0]["?size"] - 4 .. [[]; helm x value offset
		add dword [ss:esp+0x1c], ecx

		; get helm Y
		movsx ecx, word [ds:ebx + ]] .. Game.CharacterPortraits[0]["?size"] - 2 .. [[]; helm y value offset
		add dword [ss:esp+0x18], ecx

		pop ecx
		pop eax

		mov ebx, 0
		push ebx

		imul ecx, ecx, ]] .. HelmsCount .. [[;
		add eax, ecx

		jmp absolute 0x43b24c]])

	else
		NewCode = mem.asmproc([[
		;eax - index by type
		;ecx - doll type id (0 - man, 1 - woman, 2 - minotaur, 3 - troll)

		push eax
		push ecx

		call absolute ]] .. ItemPicCoordsAsm .. [[;

		add eax, dword [ds:0x4f5890]
		mov dword [ss:esp+0x1c], eax; 0x18fcec

		add ecx, dword [ds:0x4f5894]
		mov dword [ss:esp+0x18], ecx; 0x18fce8

		pop ecx
		pop eax
		push ebx

		imul ecx, ecx, ]] .. HelmsCount .. [[;
		add eax, ecx

		jmp absolute 0x43b24c]])

	end

	mem.asmpatch(0x43b228, "jmp absolute " .. NewCode)
	mem.nop(0x43b25a, 4)

	-- Read new armor data:

	mem.nop(0x43aa7f, 13)
	mem.nop(0x43aaa9, 9)

	NewCode = mem.asmproc([[
	mov eax, ecx
	mov ecx, 3
	call absolute ]] .. GetItemIdByType .. [[;
	jmp absolute 0x43aaa1]])
	mem.asmpatch(0x43aa8c, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	;eax - index by type
	;ecx - race id (0 - man, 1 - woman, 2 - minotaur, 3 - troll)

	push eax
	push ecx

	call absolute ]] .. ItemPicCoordsAsm .. [[;

	add eax, dword [ds:0x4f5890]
	mov dword [ss:esp+0x1c], eax; 0x18fcec

	add ecx, dword [ds:0x4f5894]
	mov dword [ss:esp+0x18], ecx; 0x18fce8

	pop ecx
	pop eax

	imul ecx, ecx, ]] .. ArmorCount .. [[;
	add eax, ecx

	jmp absolute 0x43aad9]])
	mem.asmpatch(0x43aab6, "jmp absolute " .. NewCode)
	mem.nop(0x43aadf, 4)

	-- Read new cloak data:

		-- Back:

	mem.nop(0x43a6e2, 2)
	mem.nop(0x43a6f4, 9)

	NewCode = mem.asmproc([[
	mov ecx, 7
	call absolute ]] .. GetItemIdByType .. [[;
	jmp absolute 0x43a6ec]])
	mem.asmpatch(0x43a6e4, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	;eax - index by type
	;ecx - race id (0 - man, 1 - woman, 2 - minotaur, 3 - troll)

	push eax
	push ecx

	call absolute ]] .. ItemPicCoordsAsm .. [[;

	add eax, dword [ds:0x4f5890]
	mov dword [ss:esp+0x1c], eax; 0x18fcec

	add ecx, dword [ds:0x4f5894]
	mov dword [ss:esp+0x18], ecx; 0x18fce8

	pop ecx
	pop eax
	push ebx

	imul ecx, ecx, ]] .. CloaksCount .. [[;
	add eax, ecx

	jmp absolute 0x43a726]])
	mem.asmpatch(0x43a701, "jmp absolute " .. NewCode)
	mem.nop(0x43a734, 4)

		-- Back collar:

	mem.nop(0x43b02d, 2)
	mem.nop(0x43b03f, 9)

	NewCode = mem.asmproc([[
	mov ecx, 7
	call absolute ]] .. GetItemIdByType .. [[;
	jmp absolute 0x43b037]])
	mem.asmpatch(0x43b02f, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	;eax - index by type
	;ecx - race id (0 - man, 1 - woman, 2 - minotaur, 3 - troll)

	push eax
	push ecx

	imul ecx, ecx, ]] .. CloaksCount .. [[;
	add eax, ecx

	mov edi, dword [ds:eax*4+]] .. CloakPicsOffset + CloaksCount*TypesCount*4 .. [[];

	pop ecx
	pop eax

	call absolute ]] .. CollarPicCoordsAsm .. [[;
	xchg eax, ecx
	add eax, dword [ds:0x4f5894]
	add ecx, dword [ds:0x4f5890]

	jmp absolute 0x43b074]])
	mem.asmpatch(0x43b04c, "jmp absolute " .. NewCode)

		-- Front collar:

	NewCode = mem.asmproc([[
	mov eax, dword [ss:esp+0x20]
	mov eax, dword [ds:eax]

	mov ecx, 7
	call absolute ]] .. GetItemIdByType .. [[;

	mov eax, dword [ss:esp+0x24]

	push eax
	push ecx

	imul eax, eax, ]] .. CloaksCount .. [[;
	add ecx, eax
	mov edi, dword [ds:ecx*4+]] .. CloakPicsOffset .. [[];

	pop ecx
	pop eax

	call absolute ]] .. CollarPicCoordsAsm .. [[;
	xchg eax, ecx
	add eax, dword [ds:0x4f5894]
	add ecx, dword [ds:0x4f5890]

	jmp absolute 0x43b414]])
	mem.asmpatch(0x43b3eb, "jmp absolute " .. NewCode)

	----

	-- New checkers - seek inside index tables instead of range of global indexes.
	-- Complex collars checkers
	NewCode = mem.asmproc([[
	mov ecx, dword [ss:ebp-0x10]
	push eax
	push ecx
	push ebx
	mov ebx, 2
	mov eax, ]] .. ComplexCollarsIndexTable .. [[;
	mov ecx, ]] .. table.maxn(ComplexCollars) .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop ebx
	pop ecx
	pop eax
	jmp absolute 0x439fb7]])
	mem.asmpatch(0x439fb1, "jmp absolute " .. NewCode)
	mem.asmpatch(0x439fbd, "je 0x439fe4 - 0x439fbd")

	NewCode = mem.asmproc([[
	mov dword [ss:esp+0x20], eax
	push edx
	mov edx, dword [ds:eax]
	push eax
	push ecx
	push ebx
	mov ebx, 2
	mov eax, ]] .. ComplexCollarsIndexTable .. [[;
	mov ecx, ]] .. table.maxn(ComplexCollars) .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop ebx
	pop ecx
	pop eax
	pop edx
	je absolute 0x43b566
	jmp absolute 0x43b3e7]])
	mem.asmpatch(0x43b3da, "jmp absolute " .. NewCode)

	-- Armor checker
	NewCode = mem.asmproc([[
	push eax
	push ecx
	push ebx
	mov ebx, 2
	mov eax, ]] .. ArmorIndexTable .. [[;
	mov ecx, ]] .. ArmorCount .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop ebx
	pop ecx
	pop eax
	jnz absolute 0x43a2e5; 0x43a2c2
	jmp absolute 0x43a0f6; 0x43a0d6
	]])
	mem.asmpatch(0x43a0cb, "jmp absolute " .. NewCode)
	mem.nop(0x43a0b4, 3)
	----

	-- Belts checker
	NewCode = mem.asmproc([[
	push eax
	push ecx
	push ebx
	mov ebx, 2
	mov eax, ]] .. BeltsIndexTable .. [[;
	mov ecx, ]] .. BeltsCount .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	je @end

	mov eax, ]] .. ComplexBeltsIndexTable .. [[;
	mov ecx, ]] .. table.maxn(ComplexBelts) .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax

	pop ebx
	pop ecx
	pop eax
	je absolute 0x43a114
	jmp absolute 0x43a1d8

	@end:
	pop ebx
	pop ecx
	pop eax
	jmp absolute 0x43a1b6]])
	mem.asmpatch(0x43a0fe, "jmp absolute " .. NewCode)
	mem.nop(0x43a0f6, 3)
	----

	-- Boots checker
	NewCode = mem.asmproc([[
	push eax
	push ecx
	push ebx
	mov ebx, 2
	mov eax, ]] .. BootsIndexTable .. [[;
	mov ecx, ]] .. BootsCount .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop ebx
	pop ecx
	pop eax
	jnz absolute 0x43a1d8; 0x43a1cf
	jmp absolute 0x43a1e0; 0x43a1cb
	]])
	mem.asmpatch(0x43a1c3, "jmp absolute " .. NewCode)
	mem.nop(0x43a1b6, 6)
	mem.nop(0x43a1c1, 2)
	----

	-- Helms checker
	NewCode = mem.asmproc([[
	push eax
	push ecx
	push ebx
	mov ebx, 2
	mov eax, ]] .. HelmsIndexTable .. [[;
	mov ecx, ]] .. HelmsCount .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop ebx
	pop ecx
	pop eax
	jnz absolute 0x43a294; 0x43a294
	jmp absolute 0x43a213; 0x43a1f3
	]])
	mem.asmpatch(0x43a1e8, "jmp absolute " .. NewCode)
	mem.nop(0x43a1e0, 3)
	----

	-- Hats checker
	NewCode = mem.asmproc([[
	push eax
	push ecx
	push ebx
	mov ebx, 2
	mov eax, ]] .. HatsIndexTable .. [[;
	mov ecx, ]] .. table.maxn(Hats) .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop ebx
	pop ecx
	pop eax
	jnz absolute 0x43a2ac
	jmp absolute 0x43a2a8
	]])
	mem.asmpatch(0x43a29d, "jmp absolute " .. NewCode)
	mem.nop(0x43a29a, 3)
	----

	-- Cloaks checker
	NewCode = mem.asmproc([[
	push eax
	push ecx
	push ebx
	mov ebx, 2
	mov eax, ]] .. CloaksIndexTable .. [[;
	mov ecx, ]] .. CloaksCount .. [[;
	call absolute ]] .. FindInIndex .. [[;
	test eax, eax
	pop ebx
	pop ecx
	pop eax
	jnz absolute 0x43a233; 0x43a22A
	jmp absolute 0x43a317; 0x43a222
	]])
	mem.asmpatch(0x43a21b, "jmp absolute " .. NewCode)
	mem.nop(0x43a213, 3)

	-- Minotaurs and Trolls use their own cloak icons now
	mem.nop2(0x43A236, 0x43A240)
	----

	-- Setup templates

	-- make all body armors use both vX and vXa variations.
	mem.asmpatch(0x43a2e8, "jmp absolute 0x43a2f2")

	for i = 1, string.len("%sv%da") do
		mem.u1[0x4f6470+(i-1)] = string.byte(string.sub("%sv%da", i, i))
	end
	mem.u1[0x4f6470+6] = 0
	for i = 1, string.len("%sv%db") do
		mem.u1[0x4f6498+(i-1)] = string.byte(string.sub("%sv%db", i, i))
	end
	mem.u1[0x4f6498+6] = 0
	for i = 1, string.len("%sv%dc") do
		mem.u1[0x4f6488+(i-1)] = string.byte(string.sub("%sv%dc", i, i))
	end
	mem.u1[0x4f6488+6] = 0

	local GetItemPicName = mem.asmproc([[
	; edx - item id

	imul edx, edx, 0x30
	add edx, 0x4
	add edx, dword [ds:0x408ef9]
	mov edx, dword [ds:edx]
	retn]])

	NewCode = mem.asmproc([[
	call absolute ]] .. GetItemPicName .. [[;
	push edx
	push 0x4f6480
	jmp absolute 0x43a30e]])
	mem.asmpatch(0x43a309, "jmp absolute " .. NewCode)
	mem.nop(0x43a308, 1)

	NewCode = mem.asmproc([[
	call absolute ]] .. GetItemPicName .. [[;
	push edx
	push 0x4f6470
	jmp absolute 0x43a30e]])
	mem.asmpatch(0x43a2fa, "jmp absolute " .. NewCode)
	mem.nop(0x43a2f9, 1)

	NewCode = mem.asmproc([[
	call absolute ]] .. GetItemPicName .. [[;
	push edx
	push 0x4f6498
	jmp absolute 0x43a30e]])
	mem.asmpatch(0x43a276, "jmp absolute " .. NewCode)
	mem.nop(0x43a275, 1)

	NewCode = mem.asmproc([[
	call absolute ]] .. GetItemPicName .. [[;
	push edx
	push 0x4f6488
	jmp absolute 0x43a30e]])
	mem.asmpatch(0x43a28d, "jmp absolute " .. NewCode)
	mem.nop(0x43a28c, 1)

	mem.nop(0x43a07b, 6)
	mem.asmpatch(0x43a084, "jmp absolute 0x43a197")

end

local function ExtraItemsInShops()

	NewCode = mem.asmproc([[
	push edx
	imul edx, edx, 0x30

	cmp dword [ds:]] .. NewSpacePtr + 20 .. [[+edx], 0
	je @neq

	cmp byte [ds:]] .. NewSpacePtr + 37 .. [[+edx], 3;
	je @neq

	pop edx
	jmp absolute 0x490068

	@neq:
	pop edx
	push 5
	jmp absolute 0x490096]])
	mem.asmpatch(0x49003c, "jmp absolute " .. NewCode)
	mem.asmpatch(0x49004c, "jmp absolute " .. NewCode)

	NewCode = mem.asmproc([[
	push esi
	imul esi, esi, 0x30

	cmp dword [ds:]] .. NewSpacePtr + 20 .. [[+esi], 0
	je @neq

	cmp byte [ds:]] .. NewSpacePtr + 37 .. [[+esi], 3;
	je @neq

	pop esi
	jmp absolute 0x4bb65a

	@neq:
	pop esi
	jmp absolute 0x4bb6b6]])
	mem.asmpatch(0x4bb632, "jmp absolute " .. NewCode)
	mem.asmpatch(0x4bb642, "jmp absolute " .. NewCode)

	mem.IgnoreProtection(true)
	mem.u4[0x454082 + 3] = NewItemsCount - 1
	mem.u4[0x4540ba + 3] = NewItemsCount - 1
	mem.IgnoreProtection(false)

	-- allow to sell MScrolls with value
	mem.nop(0x4bb67b, 14)

end
local function SetupUseItemHandler()

	local UsableItemsHandler = mem.asmproc([[
	nop
	nop
	nop
	nop
	nop
	retn
	]])

	mem.hook(UsableItemsHandler, function(d)

		local SwitchTable = {0x4671e0, 0x46720f, 0x4671e0, 0x4671a1}
		local f = evt.UseItemEffects[mem.u4[0xb7ca64]]

		if type(f) == "function" then
			local PlayerId = mem.u4[d.ebp+0x8]-1
			local result  = f(Party.Players[PlayerId], Mouse.Item, PlayerId)
			if result and SwitchTable[result+1] then
				if result == 2 then
					Mouse.Item.Number = 0
					evt.ForPlayer(mem.u4[d.ebp+0x8]-1).Add("Experience", 0)
				end
				d.eax = SwitchTable[result+1]
			end
		end

	end)

	mem.asmpatch(0x466597, [[
		xor eax, eax
		call absolute ]] .. UsableItemsHandler .. [[;
		cmp eax, 0xffff
		jl @std
		jmp eax;
		@std:
		mov eax, dword [ds:0x4737d8]
		jmp absolute 0x46659c]])

end
---- Load tables for count

local TablesPtrs = mem.StaticAlloc(4*6)

NewCode = mem.asmproc([[
nop; memhook here.
nop
nop
nop
nop
retn]])

local LoadTables = mem.asmproc([[

; Potions:

push 0
push 0x4f8040
mov ecx, 0x6fb828
mov dword [ds:0x602068], 0
call absolute 0x411c9b
mov dword [ds:]] .. TablesPtrs .. [[], eax

; Potnotes:

push 0
push 0x4f8088
mov ecx, 0x6fb828
mov dword [ds:0x60206c], 0
call absolute 0x411c9b
mov dword [ds:]] .. TablesPtrs + 4 .. [[], eax

; StdItems

push 0
push 0x4f8734
mov ecx, 0x6fb828
call absolute 0x411c9b
mov dword [ds:]] .. TablesPtrs + 8 .. [[], eax

; SpcItems

push 0
push 0x4f8724
mov ecx, 0x6fb828
call absolute 0x411c9b
mov dword [ds:]] .. TablesPtrs + 12 .. [[], eax

; Items

push 0
push 0x4f8718
mov ecx, 0x6fb828
call absolute 0x411c9b
mov dword [ds:]] .. TablesPtrs + 16 .. [[], eax

; RndItems

push 0
push 0x4f85ec
mov ecx, 0x6fb828
call absolute 0x411c9b
mov dword [ds:]] .. TablesPtrs + 20 .. [[], eax

;mov eax, ]] .. TablesPtrs .. [[;
call absolute ]] .. NewCode .. [[; memhook.

retn]])

mem.hook(NewCode, function(d)

	NewPotCount = DataTables.ComputeRowCountInPChar(mem.u4[TablesPtrs], 5, 40) - 23
	NewStdCount = DataTables.ComputeRowCountInPChar(mem.u4[TablesPtrs + 8], 1, 9) - 7
	NewSpcCount = DataTables.ComputeRowCountInPChar(mem.u4[TablesPtrs + 12], 1, 9) - 7
	NewItemsCount = DataTables.ComputeRowCountInPChar(mem.u4[TablesPtrs + 16], 1, 6) - 2

	mem.nop(0x4512f4, 22)
	mem.asmpatch(0x4512f4, [[mov eax, dword [ds:]] .. TablesPtrs .. [[];
							mov ecx, 0x6fb828
							mov dword [ds:0x602068], ebx]])

	mem.nop(0x45149d, 22)
	mem.asmpatch(0x45149d, [[mov eax, dword [ds:]] .. TablesPtrs+4 .. [[];
							mov ecx, 0x6fb828
							mov dword [ds:0x60206c], ebx]])

	mem.nop(0x4546ab, 1)
	mem.nop(0x4546b2, 17)
	mem.asmpatch(0x4546b2, [[mov eax, dword [ds:]] .. TablesPtrs+8 .. [[];
							mov ecx, 0x6fb828
							mov dword [ds:ebx], esi]])

	mem.nop(0x454880, 2)
	mem.nop(0x45488b, 15)
	mem.asmpatch(0x45488b, [[mov eax, dword [ds:]] .. TablesPtrs+12 .. [[];
							mov ecx, 0x6fb828]])

	mem.nop(0x454a18, 2)
	mem.nop(0x454a23, 15)
	mem.asmpatch(0x454a23, [[mov eax, dword [ds:]] .. TablesPtrs+16 .. [[];
							mov ecx, 0x6fb828]])

	mem.nop(0x45522b, 12)
	mem.nop(0x455239, 5)
	mem.asmpatch(0x45522b, [[mov eax, dword [ds:]] .. TablesPtrs+20 .. [[];
							mov ecx, 0x6fb828]])

	if NewPotCount > OldPotCount
		or NewItemsCount > OldItemsCount
		or NewStdCount > OldStdCount
		or NewSpcCount > OldSpcCount then

		RemoveItemsLimits()
		ExtraItemsInShops()

	end

end)

NewCode = mem.asmproc([[
call absolute ]] .. LoadTables .. [[;
mov ecx, dword [ds:0x464068]
call absolute 0x454655
jmp absolute 0x464071]])
mem.asmpatch(0x46406c, "jmp absolute " .. NewCode)

-- Scroll.txt (message scrolls)
mem.autohook2(0x4755d8, function(d)

	local Counter = 0
	local NewMScrollCount = DataTables.ComputeRowCountInPChar(d.eax, 1) - 1
	local NewMScrollPtr = mem.StaticAlloc(NewMScrollCount*4 + 4 + NewMScrollCount*2)
	local MScrollIndexPtr = NewMScrollPtr + NewMScrollCount*4 + 4

	mem.autohook2(0x4755fa, function(d)
		mem.u2[MScrollIndexPtr + Counter*2] = tonumber(string.split(mem.string(d.eax + 1), "\9")[1]) or 0xffff
		Counter = Counter + 1
	end)

	mem.IgnoreProtection(true)

	mem.u4[0x4755f0 + 4] = NewMScrollPtr
	mem.u4[0x475668 + 4] = NewMScrollPtr + NewMScrollCount*4
	mem.u4[0x4664ff + 2] = NewSpacePtr + 8

	mem.u4[0x46646c + 3] = NewMScrollPtr
	mem.u4[0x46654f + 3] = NewMScrollPtr

	mem.IgnoreProtection(false)

	NewCode = mem.asmproc([[
	push eax
	push ecx
	push ebx
	push edx
	mov edx, esi
	mov eax, ]] .. MScrollIndexPtr .. [[;
	mov ecx, ]] .. NewMScrollCount .. [[;
	mov ebx, 0x2
	call absolute ]] .. FindInIndex .. [[;

	neg ecx
	add ecx, ]] .. NewMScrollCount .. [[;
	mov edi, ecx
	test eax, eax

	pop edx
	pop ebx
	pop ecx
	pop eax

	je absolute 0x466422
	jmp absolute 0x4663e5]])
	mem.asmpatch(0x4663d5, "jmp absolute " .. NewCode)

	mem.asmpatch(0x4663fc, [[
	mov esi, edi
	xor edi, edi]])

	NewCode = mem.asmproc([[
	mov eax, dword [ds:0x51932c]
	mov eax, dword [ds:eax+0x1c]
	movzx eax, word [ds:]] .. MScrollIndexPtr .. [[+eax*2];
	lea eax, dword [ds:eax+eax*2]
	shl eax, 0x4
	jmp absolute 0x4664ff]])
	mem.asmpatch(0x4664f1, "jmp absolute " .. NewCode)

	structs.o.GameStructure["MessageScrolls"] = NewMScrollPtr
	internal.SetArrayUpval(Game["MessageScrolls"], "o", NewMScrollPtr)
	internal.SetArrayUpval(Game["MessageScrolls"], "count", NewMScrollCount)

end)

----

function events.GameInitialized2()

	mem.hookalloc(0x800)

	SetupItemPicsHandler()

	ProcessReagentsTable()
	ProcessPotionsTable()

	SetupSpellsHandler()
	SetupUseItemHandler()

end

-- Fix glitch upon declining item enchantment
mem.asmpatch(0x432482, [[
	mov dword [ds:0x51e0f8], ebx
	cmp dword [ds:0x51e0fc], ebx
]])


