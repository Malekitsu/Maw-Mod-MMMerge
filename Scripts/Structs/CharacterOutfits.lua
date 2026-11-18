local u2 = mem.u2
local random, sqrt = math.random, math.sqrt

local OldVoiceCount, NewVoiceCount = 30, nil
local ItemSize = 2
local VoiceSetSize = 100
local VoiceTypes = 6

local OldGame = structs.f.GameStructure
function structs.f.GameStructure(define)
   OldGame(define)
   define
	[0].struct(structs.CharacterVoices)  'CharacterVoices'
	[0x4fcb78].array(1).struct(structs.CharacterPortrait) 'CharacterPortraits'
	[0x4fcb78].array(1).struct(structs.CharacterDollType) 'CharacterDollTypes'
end

function structs.f.CharacterVoices(define)
	define
	[0x4fcb78].array(0).array(100).u2 'Sounds'
	[0x4fcb78].array(0).array(VoiceTypes).u1 'Avail'
end

function structs.f.CharacterPortrait(define)

	define
	.u1 'DollType'
	.u1 'DefClass'
	.u1 'DefVoice'
	.u1 'DefSex'
	.u1 'AvailableAtStart'
	.i2 'BodyX'
	.i2 'BodyY'
	.EditPChar 'Background'
	.EditPChar 'Body'
	.EditPChar 'Head'
	.EditPChar 'LHd'
	.EditPChar 'LHu'
	.EditPChar 'LHo'
	.EditPChar 'RHb'
	.EditPChar 'unk1'
	.EditPChar 'unk2'
	.EditPChar 'RHd'
	.EditPChar 'RHu'
	.EditPChar 'FacePrefix'
	.u2 'DefAttackM'
	.u2 'DefAttackR'
	.u2	'NPCPic'
	.u1	'Race'
	.i2 'HelmX'
	.i2 'HelmY'

end

function structs.f.CharacterDollType(define)

	define
	.b1 'Bow'
	.b1 'Armor'
	.b1 'Helm'
	.b1 'Belt'
	.b1 'Boots'
	.b1 'Cloak'
	.b1 'Weapon'
	.i2 'RHoX'
	.i2 'RHoY'
	.i2 'RHcX'
	.i2 'RHcY'
	.i2 'RHfX'
	.i2 'RHfY'
	.i2 'LHoX'
	.i2 'LHoY'
	.i2 'LHcX'
	.i2 'LHcY'
	.i2 'LHfX'
	.i2 'LHfY'
	.i2 'OHOffsetX'
	.i2 'OHOffsetY'
	.i2 'MHOffsetX'
	.i2 'MHOffsetY'
	.i2 'BowX'
	.i2 'BowY'
	.i2 'ShieldX'
	.i2 'ShieldY'

end

function GetRace(Player, PlayerIndex)
	return Game.CharacterPortraits[Player.Face].Race
end

local function GetPlayer(ptr)
	local PlayerId = (ptr - Party.PlayersArray["?ptr"])/Party.PlayersArray[0]["?size"]
	return Party.PlayersArray[PlayerId], PlayerId
end

local function GetMon(ptr)
	local MapMonP = Map.Monsters["?ptr"]
	if ptr > MapMonP then
		local i = (ptr-MapMonP)/Map.Monsters[0]["?size"]
		return Map.Monsters[i], i
	end
end

local function ProcessVoicesTable()

	local function GenerateVoicesTable()

		local StartIndex = 5000

		local RowHeaders = 		{"Clear1", "Clear2", "Closed1", "Closed2", "Oops1", "Oops2", "Ready1", "Ready2", "BadItem1", "BadItem2",
								"GoodItem1", "GoodItem2", "CantIdent1", "CantIdent2", "Repaired1", "Repaired2", "CantRep1", "CantRep2", "EasyFight1", "EasyFight2",
								"HardFight1", "HardFight2", "CantIdMon1", "CantIdMon2", "Ha!1", "Ha!2", "Hungry1", "Hungry2", "Ouch1", "Ouch2",
								"Injured1", "Injured2", "HardInjured1", "HardInjured2", "Mad1", "Mad2", "Mad3", "Mad4", "Misc1", "Misc2",
								"Misc3", "Misc4", "Misc5", "Misc6", "CantRestHere1", "CantRestHere2", "NeedMoreGold1", "NeedMoreGold2", "InventoryFull1", "InventoryFull2",
								"Yes!1", "Yes!2", "Nah1", "Nah2", "ClosedB1", "ClosedB2", "LearnSpell1", "LearnSpell2", "CantLearn1", "CantLearn2",
								"No1", "No2", "Hello1", "Hello2", "Hello3", "Hello4", "Hello5", "Hello6", "n/u", "n/u",
								"n/u", "n/u", "Win!1", "Win!2",	"Heh1", "Heh2", "LastStanding1", "LastStanding2", "HardFightEnd", "Enter1",
								"Enter2", "Enter3", "Yes1", "Yes2",	"Thanks1", "Thanks2", "GoodFight1", "GoodFight2","n/u", "n/u",
								"n/u", "n/u", "Move!1", "Move!2", "n/u", "n/u", "n/u", "n/u", "n/u", "n/u"}


		local VoiceTxtTable = io.open("Data/Tables/Character voices.txt", "w")

		VoiceTxtTable:write("Sound type/Voice set id\9")
		for i = 0, OldVoiceCount - 1 do
			VoiceTxtTable:write(i .. "\9")
		end
		VoiceTxtTable:write("\n")

		for iR = 0, VoiceSetSize-1 do

			local CurStr = RowHeaders[iR+1]

			for iL = 0, OldVoiceCount-1 do

				CurStr = CurStr .. "\9" .. iR + iL*VoiceSetSize + StartIndex

			end

			VoiceTxtTable:write(CurStr .. "\n")

		end

		---- Availability table

		VoiceTxtTable:write("\n")
		VoiceTxtTable:write("Man\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9x\9x\9x\9-\9-\9-\9-\9-\9-\n")
		VoiceTxtTable:write("Woman\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9x\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\n")
		VoiceTxtTable:write("Dragon\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9-\9x\9-\9-\9-\9-\9-\n")

		io.close(VoiceTxtTable)

	end

	local VoiceTxtTable = io.open("Data/Tables/Character voices.txt", "r")

	if not VoiceTxtTable then
		GenerateVoicesTable()
		VoiceTxtTable = io.open("Data/Tables/Character voices.txt", "r")
	end

	---- Load table

	local LineIt = VoiceTxtTable:lines()
	local Header = string.split(LineIt(), "\9")
	local NewVoiceCount

	NewVoiceCount = tonumber(table.remove(Header))
	while table.maxn(Header) > 0 and not NewVoiceCount do
		NewVoiceCount = tonumber(table.remove(Header))
	end

	if not NewVoiceCount then
		return
	end

	local VoiceTableSize = VoiceSetSize*(NewVoiceCount+1)*ItemSize
	local VoiceTablePtr = mem.StaticAlloc(VoiceTableSize + (NewVoiceCount+1)*VoiceTypes)
	local CurSoundType = 0

	-- Voice sets

	for i = 1, VoiceSetSize do

		local line = LineIt()
		local RowSet = string.split(line, "\9")

		for i = 0, NewVoiceCount do
			mem["u".. ItemSize][VoiceTablePtr + CurSoundType*ItemSize + VoiceSetSize*i*ItemSize] = tonumber(RowSet[i+2])
		end

		CurSoundType = CurSoundType + 1

	end

	-- Voice availability

	CurSoundType = 0
	for line in LineIt do
		local RowSet = string.split(line, "\9")
		local flag

		if table.maxn(RowSet) > NewVoiceCount and RowSet[1] ~= "" and RowSet[1] ~= "Notes" then
			for i = 0, NewVoiceCount do
				mem.u1[VoiceTablePtr+VoiceTableSize+i*VoiceTypes+CurSoundType] = RowSet[i+2] == "x" and 1 or 0
			end
			CurSoundType = CurSoundType + 1
		end

	end

	----

	local function ChangeCharacterVoicesArray(name, p, count)
		structs.o.CharacterVoices[name] = p
		internal.SetArrayUpval(Game.CharacterVoices[name], "o", p)
		internal.SetArrayUpval(Game.CharacterVoices[name], "count", count)
	end

	ChangeCharacterVoicesArray("Sounds", VoiceTablePtr, NewVoiceCount+1)
	ChangeCharacterVoicesArray("Avail", VoiceTablePtr+VoiceTableSize, NewVoiceCount+1)

 	-- table handler

	local function VoiceAvailable(Voice, Player)

		local Sex	= Player:GetSex()
		local Class	= Player.Class
		local Portrait = Game.CharacterPortraits[Player.Face]

		if Voice < 0 or Voice >= Game.CharacterVoices.Avail.count then
			Player.Voice = Portrait.DefVoice
			return false
		end

		if Player.Face == 67 or Player.Face == 68 then
			return Game.CharacterVoices.Avail[Voice][5]
		elseif Portrait.Race == 5 then
			return Game.CharacterVoices.Avail[Voice][2]
		elseif Portrait.Race == 6 or Portrait.Race == 10 then
			return Game.CharacterVoices.Avail[Voice][Sex + 3]
		else
			return Game.CharacterVoices.Avail[Voice][Sex]
		end

	end

	-- Set def voice
	mem.hook(0x433a8e, function(d)
		local Player = GetPlayer(d.ebp)
		Player.Voice = Game.CharacterPortraits[Player.Face].DefVoice
	end)

	mem.nop(0x43379c, 2)
	mem.asmpatch(0x4337a5, "cmp eax, 1")
	mem.hook(0x4337a0, function(d)
		d.eax = VoiceAvailable(mem.i4[d.ecx+0x1be4], Party.Players[0])
		d.ecx = d.eax
	end)

	mem.nop(0x4337f3, 2)
	mem.asmpatch(0x4337fc, "cmp eax, 1")
	mem.hook(0x4337f7, function(d)
		d.eax = VoiceAvailable(mem.i4[d.ecx+0x1be4], Party.Players[0])
		d.ecx = d.eax
	end)

	mem.asmpatch(0x492c6f, "xor edi, edi")
	mem.asmpatch(0x492c71, "inc edi")

	local CurPtr = mem.asmpatch(0x492c8c, [[
	mov eax, dword [ds:ebp-0x8]
	mov eax, dword [ds:eax+0x1be4]
	imul eax, eax, ]] .. VoiceSetSize .. [[;
	lea eax, dword [ds:eax+esi*2]
	lea eax, dword [ds:eax-2]
	imul eax, eax, ]] .. ItemSize .. [[;
	nop
	nop
	nop
	nop
	nop
	movzx esi, word [ds:eax+]] .. VoiceTablePtr .. [[];]])

	mem.hook(CurPtr + 19 + (VoiceSetSize < 128 and 3 or 6), function(d)
		if d.edx < 2 then
			d.edx = random(0,1)
			if u2[VoiceTablePtr + d.eax + d.edx * ItemSize] == 0 then
				d.edx = 1 - d.edx
			end
		end
		d.eax = d.eax + d.edx * ItemSize
	end)

	mem.asmpatch(0x490a71, [[
	dec ecx
	imul ecx, ecx, ]] .. ItemSize .. [[;
	movzx ecx, word [ds:ecx*2+]] .. VoiceTablePtr .. [[];]])

	mem.IgnoreProtection(true)
	mem.u1[0x43378d+6] = NewVoiceCount
	mem.u1[0x4337e9+6] = NewVoiceCount
	mem.u1[0x490a64 + 2] = VoiceSetSize/2
	mem.IgnoreProtection(false)


end


local function ChangeGameArray(name, p, count)
	structs.o.GameStructure[name] = p
	internal.SetArrayUpval(Game[name], "o", p)
	internal.SetArrayUpval(Game[name], "count", count)
end

----------- Portraits
local function SetResistancesHook()

	local ResOffset = {0,1,2,3,7,8,6}

	local NewCode = mem.asmpatch(0x48dbb0, [[
	nop
	nop
	nop
	nop
	nop
	cmp eax, 0xfde8
	jge absolute 0x48dd65
	jmp absolute 0x48dd4a]])

	mem.hook(NewCode, function(d)
		d.ebx = ResOffset[d.eax+1]
		local t = {Resistance = d.ebx, Player = GetPlayer(d.ecx), Result = 0}
		events.call("ResistanceByClass", t)

		d.edi = t.Result
		d.eax = t.Result
	end)

	NewCode = mem.asmpatch(0x48df7a, [[
	nop
	nop
	nop
	nop
	nop
	pop edi
	pop esi
	pop ebp
	pop ebx
	retn 0x4]])

	mem.hook(NewCode, function(d)
		local res = ResOffset[d.edi-9]
		if res then
			local t = {Resistance = res, Player = GetPlayer(d.esi), Result = d.eax}
			events.call("ResistanceByClass", t)
			d.eax = t.Result
		end
	end)

	--mem.asmpatch(0x48debd, "jmp absolute 0x48df50")
	--mem.asmpatch(0x48df2f, "jmp absolute 0x48df50")
	--mem.asmpatch(0x48df2a, "jmp absolute 0x48df50")
	--mem.asmpatch(0x48def5, "jmp absolute 0x48df50")
	--mem.asmpatch(0x48de6b, "jmp absolute 0x48df50")
	--mem.asmpatch(0x48ddf9, "jmp absolute 0x48df50")
	mem.nop(0x48ded8, 3)
	mem.nop(0x48dee2, 5)
	mem.nop(0x48deee, 5)
	mem.nop(0x48df0a, 8)
	mem.nop(0x48df19, 5)
	mem.nop(0x48df25, 3)
	mem.nop(0x48df48, 8)
	mem.nop(0x48de80, 8)
	mem.nop(0x48de8f, 5)
	mem.nop(0x48de9b, 8)
	mem.nop(0x48de03, 5)
	mem.nop(0x48de0f, 8)
	mem.nop(0x48de1e, 5)
	mem.nop(0x48de2a, 8)
	mem.nop(0x48de44, 8)
	mem.nop(0x48de53, 9)
	mem.nop(0x48de63, 3)
	mem.asmpatch(0x48dead, "jmp absolute 0x48df50")

	-- Resistances. If < 65000 - print number, else - "Immune"
	mem.asmpatch(0x48dca9, "jmp absolute 0x48dd4a")

	mem.asmpatch(0x418550, "jl 0x418576 - 0x418550")
	mem.asmpatch(0x41861a, "jl 0x418640 - 0x41861a")
	mem.asmpatch(0x4186e4, "jl 0x41870a - 0x4186e4")
	mem.asmpatch(0x4187ae, "jl 0x4187d4 - 0x4187ae")
	mem.asmpatch(0x418878, "jl 0x41889e - 0x418878")
	mem.asmpatch(0x418939, "jl 0x41895f - 0x418939")

end

local function SetChooseCharHook()
	mem.autohook2(0x48e0fa, function(d)
		events.call("CharacterChosen")
	end)
end
local function ProcessPortraitsTable()

	local function GeneratePortraitsTable()

		local OldPicCount = 30
		local OldPicsPtrBlocks 	= 	{0x4fcb00, 0x4fcdd0, 0x4fcd58, 0x4fcbf0, 0x4fcc68, 0x4fcce0, 0x4fce48, 0x4fcfb0, 0x4fd028, 0x4fcec0, 0x4fcf38, 0x4fcb78}
		local DefaultBodyTypes 	= 	{0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,2,2,3,3,4,4,0,1,0,0,0,0}
		local DefaultClasses 	=	{4,4,4,4,2,2,2,2,0,0,0,0,12,12,12,12,10,10,10,10,8,8,6,6,14,14,1,1,0,0,0}
		local DefaultSex		= 	{0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,1,0,0,0}
		local DefaultAttack		= 	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,137,137,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
		local DefaultAvFlags	=	{"x","x","x","x","x","x","x","x","x","x","x","x","x","x","x","x","x","x","x","x","x","x","x","x","-","-","-","-","-","-","-"}
		local DefaultRaces		=	{0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,4,4,5,5,0,0,0,0,0,0}

		local PicsTxtTable = io.open("Data/Tables/Character portraits.txt", "w")
		PicsTxtTable:write("#	Paperdoll type	Def class	Def voice	Def sex	Available at start	Body X	Body Y	Helm X	Helm Y	Background	bod	head	LHd	LHu	LHo	RHb	Unk	Unk	RHd	RHu	Face pics prefix	Def Attack (melee)	Def Attack (range)	NPCPic	Race\n")

		for iR = 0, OldPicCount - 1 do

			local CurStr = 		iR .. "\9" .. DefaultBodyTypes[iR+1] .. "\9" .. DefaultClasses[iR+1] .. "\9" .. iR .. "\9" .. DefaultSex[iR+1] .. "\9"
								   .. DefaultAvFlags[iR+1] .. "\9" .. mem.i4[0x4f6158+iR*8] .. "\9" .. mem.i4[0x4f615c+iR*8] .. "\9" .. "0" .. "\9" .. "0" .. "\9"

			for i, v in ipairs(OldPicsPtrBlocks) do
				CurStr = CurStr .. mem.string(mem.u4[v+iR*4]) .. "\9"
			end

			CurStr = CurStr .. DefaultAttack[iR+1] .. "\9" .. DefaultAttack[iR+1] .. "\9" .. iR + 2901 .. "\9" .. DefaultRaces[iR+1] .. "\n"

			PicsTxtTable:write(CurStr)

		end

		io.close(PicsTxtTable)

	end

	local PicsTxtTable = io.open("Data/Tables/Character portraits.txt", "r")
	local PortraitsTablePtr, PictureNamesPtr
	local Counter, LineSize, PortraitsCount = 0, 68, 0
	local Words, LineIt

	if not PicsTxtTable then
		GeneratePortraitsTable()
		PicsTxtTable = io.open("Data/Tables/Character portraits.txt", "r")
	end

	LineIt = PicsTxtTable:lines()

	LineIt() -- skip header

	for line in LineIt do
		PortraitsCount = PortraitsCount + 1
	end

	PortraitsTablePtr = mem.StaticAlloc(PortraitsCount*LineSize + 0x4 + PortraitsCount*12*12)
	PictureNamesPtr = PortraitsTablePtr + PortraitsCount*LineSize + 0x4

	PicsTxtTable:seek("set")
	LineIt() -- skip header

	Counter = 0
	for line in LineIt do

 		Words = string.split(line, "\9")

		for i = 2, 5 do
			mem.u1[PortraitsTablePtr + i-2 + Counter*LineSize] = tonumber(Words[i]) or 0
		end

		if Words[6] == "x" then
			mem.u1[PortraitsTablePtr + 4 + Counter*LineSize] = 1
		end

		mem.i2[PortraitsTablePtr + 5 + Counter*LineSize] = tonumber(Words[7]) or 0
		mem.i2[PortraitsTablePtr + 7 + Counter*LineSize] = tonumber(Words[8]) or 0

		mem.i2[PortraitsTablePtr + LineSize - 4 + Counter*LineSize] = tonumber(Words[9]) or 0
		mem.i2[PortraitsTablePtr + LineSize - 2 + Counter*LineSize] = tonumber(Words[10]) or 0

		for i = 0, 11 do

			local Word = Words[11 + i]
			local NamePtr = PictureNamesPtr + i*12 + Counter*12*12
			local TPtr = PortraitsTablePtr + 9 + i*4 + Counter*LineSize

			mem.u4[TPtr] = NamePtr

			for iL = 1, string.len(Word) do
				mem.u1[NamePtr + (iL-1)] = string.byte(Word, iL)
			end

		end

		mem.u2[PortraitsTablePtr + 57 + Counter*LineSize] = tonumber(Words[23]) or 0
		mem.u2[PortraitsTablePtr + 59 + Counter*LineSize] = tonumber(Words[24]) or 0
		mem.u2[PortraitsTablePtr + 61 + Counter*LineSize] = tonumber(Words[25]) or 0
		mem.u1[PortraitsTablePtr + 63 + Counter*LineSize] = tonumber(Words[26]) or 0

		Counter = Counter + 1
	end

	ChangeGameArray("CharacterPortraits", PortraitsTablePtr, PortraitsCount)

	---- Pictures

	-- Player:GetSex() correction

	mem.hook(0x48f5e5, function(d)

		Game.CurrentCharPortrait = d.ecx
		d.eax = Game.CharacterPortraits[d.ecx].DefSex
		d.ecx = d.eax

	end)
	mem.asmpatch(0x48f5ea, "jmp 0x48f5fb - 0x48f5ea")

	--

	local TmpTable = 	{{0x439971, 0x4c4eee},				-- Background
						{0x43998f, 0x4c4f17}, 				-- Body
						{0x4399ad}, 						-- Head
						{0x4399cb, 0x4c5021, 0x4c5021}, 	-- LHd
						{0x4399e9}, 						-- LHu
						{0x439a07}, 						-- LHo
						{0x439a25}, 						-- RHb
						{0x439a43}, 						-- Unk
						{0x439a61}, 						-- Unk
						{0x439a7f, 0x4c5094, 0x4c5094}, 	-- RHd
						{0x439a9d}}							-- RHu

	for iR,vR in ipairs(TmpTable) do
		for i, v in ipairs(vR) do
			mem.asmpatch(v, [[
			imul ecx, eax, ]] .. LineSize .. [[;
			add ecx, ]] .. 0x5 + iR*4 .. [[;
			push dword [ds:ecx+]] .. PortraitsTablePtr .. [[];]])
		end
	end

 	-- face
	mem.asmpatch(0x4908f1, [[
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, 0x35
	push dword [ds:eax+]] .. PortraitsTablePtr .. [[];]])

	mem.asmpatch(0x4909c3, [[
	imul ebx, edx, ]] .. LineSize .. [[;
	add ebx, 0x35
	lea ebp, dword [ds:ebx+]] .. PortraitsTablePtr .. [[];]])

	-- jump over old face pictures loading
	mem.asmpatch(0x4c5563, [[jmp absolute 0x4c55a6]])

	-- load them on the fly
	mem.asmpatch(0x4c4e91, [[
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, 0x35
	push dword [ds:eax+]] .. PortraitsTablePtr .. [[]
	push 0x4fedb4
	push 0x5df0e0
	call absolute 0x4d9f10

	add esp, 0xc

	push 0
	push 0
	push 2
	push 0x5df0e0
	mov ecx, 0x70d3e8
	call absolute 0x410d70

	lea eax, dword [ds:eax+eax*8]
	lea eax, dword [ds:eax*8+0x70d624]
	mov dword [ds:0x518e40], eax

	push dword [ds:0x518e40];]])

 	---- Complexion

	mem.asmpatch(0x43a42c, [[
	movzx eax, al
	imul ecx, eax, ]] .. LineSize .. [[;
	movzx ecx, byte [ds:ecx+]] .. PortraitsTablePtr .. [[];
	mov dword [ss:esp+0x24], ecx
	jmp absolute 0x43a46b]])

	mem.asmpatch(0x4c4f5c, [[
	movzx eax, al
	imul ecx, eax, ]] .. LineSize .. [[;
	movzx ecx, byte [ds:ecx+]] .. PortraitsTablePtr .. [[];
	mov dword [ss:ebp-0x8], ecx
	jmp absolute 0x4c4f9a]])

 	---- Character selection

	mem.nop(0x433859, 5)
	mem.nop(0x433864, 2)
	mem.asmpatch(0x43385e, [[
	@rep:
	cmp byte [ds:eax], ]] .. PortraitsCount - 1 .. [[;
	jge @cle

	inc byte [ds:eax]
	jmp @nex

	@cle:
	mov byte [ds:eax], bl

	@nex:
	movzx ecx, byte [ds:eax]
	imul ecx, ecx, ]] .. LineSize .. [[;
	add ecx, 0x4
	cmp byte [ds:ecx+]] .. PortraitsTablePtr .. [[], 1
	jnz @rep]])

	mem.nop(0x433924, 2)
	mem.asmpatch(0x433926, [[
	jmp @rep
	@cle:
	mov byte [ds:eax], ]] .. PortraitsCount .. [[;

	@rep:
	dec byte [ds:eax]
	js @cle

	movzx ecx, byte [ds:eax]
	imul ecx, ecx, ]] .. LineSize .. [[;
	add ecx, 0x4
	cmp byte [ds:ecx+]] .. PortraitsTablePtr .. [[], 1
	jnz @rep]])

	mem.asmpatch(0x433930, [[
	mov ecx, eax
	imul ecx, ecx, ]] .. LineSize .. [[;
	add ecx, 0x2
	movzx ecx, byte [ds:ecx+]] .. PortraitsTablePtr .. [[]
	mov dword [ss:ebp+0x1be4], ecx]])

	-- Class
	mem.asmpatch(0x433936, [[
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, 0x1
	movzx eax, byte [ds:eax+]] .. PortraitsTablePtr .. [[];]])

	-- Default Character
	mem.asmpatch(0x490479, [[
	@rep:
	imul ecx, eax, ]] .. LineSize .. [[;
	add ecx, ]] .. PortraitsTablePtr .. [[;
	cmp byte [ds:ecx+0x4], 0x1;
	je @equ
	inc eax
	jmp @rep

	@equ:
	mov byte [ds:esi+0x353], al
	mov al, byte [ds:ecx+1]
	mov byte [ds:esi+0x352], al
	movzx eax, byte [ds:ecx+2]
	mov dword [ds:esi+0x1be4], eax
	mov dword [ds:esi+0x1be8], 0x1
	mov dword [ds:esi+0x1bec], 0x1
	jmp absolute 0x490498]])

	-- Body coordinates
	mem.nop(0x43a885, 3)
	mem.asmpatch(0x43a888, [[
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, ]] .. PortraitsTablePtr .. [[;
	movsx ecx, word [ds:eax+0x5]
	movsx eax, word [ds:eax+0x7]
	jmp absolute 0x43a894]])

	mem.nop(0x4c4fa5, 3)
	mem.asmpatch(0x4c4fb9, [[
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, ]] .. PortraitsTablePtr .. [[;
	movsx ecx, word [ds:eax+0x7]
	movsx eax, word [ds:eax+0x5]
	jmp absolute 0x4c4fc5]])

	-- NPC pictures in Adventurer's Inn
	mem.u4[0x501daf] = 0x64343025 -- %04d
	mem.u1[0x501db3] = 0
	mem.nop(0x4c82eb, 1)
	mem.asmpatch(0x4c82e4, [[
	movsx eax, byte [ds:eax+0x353]
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, ]] .. PortraitsTablePtr .. [[;
	movsx eax, word [ds:eax+0x3d];]])

	-- Custom attacks

	local GetCAttack = mem.asmproc([[
	; ptr to character structure in ecx

	movzx eax, byte [ds:ecx+0x353]
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, 0x3b
	cmp word [ds:eax+]] .. PortraitsTablePtr .. [[], 0
	jnz @end
	sub eax, 0x2
	@end:
	movzx eax, word [ds:eax+]] .. PortraitsTablePtr .. [[];
	retn]])

	mem.asmpatch(0x42d884, "call absolute " .. GetCAttack)
	mem.asmpatch(0x42d889, "test eax, eax")
	mem.asmpatch(0x42d88c, "jnz 0x42d89d - 0x42d88c")

	mem.asmpatch(0x42d890, "call absolute " .. GetCAttack)
	mem.asmpatch(0x42d895, "test eax, eax")
	mem.asmpatch(0x42d89b, "je 0x42d8a4 - 0x42d89b")

	local CurAttack = mem.StaticAlloc(4)
	mem.u4[CurAttack] = -1

	mem.asmpatch(0x42dab0, [[
	mov ecx, esi
	mov eax, dword [ds:]] .. CurAttack .. [[]

	cmp eax, -1
	je @find

	cmp dword [ss:ebp-0x10], 0
	je @end2

	cmp eax, 0
	je @find
	jmp @end

	@end2:
	xor ecx, ecx
	jmp @exit

	@find:
	call absolute ]] .. GetCAttack .. [[;

	@end:
	mov dword [ds:]] .. CurAttack .. [[], -1
	mov ecx, eax

	@exit:
	]])

	local function GetDist(mon)
		local x, y, z  = XYZ(Party)
		local mx,my,mz = XYZ(mon)
		return sqrt((x-mx)^2 + (y-my)^2 + (z-mz)^2)
	end

	local BLASTER = const.Skills.Blaster
	local function HasBlaster(pl)
		local slot = pl.ItemMainHand
		local it = (slot ~= 0 and pl.Items[slot])
		return it and it.Condition:And(2) == 0 and Game.ItemsTxt[it.Number].Skill == BLASTER
	end

	local function SpecialAttackHook(d, pl, mon)
		local t = {Player = GetPlayer(pl), IsRanged = true, mon = GetMon(mon), Attack = mem.u4[CurAttack]}

		if HasBlaster(t.Player) then
			t.IsRanged =  true
			t.Attack = 135
		elseif t.mon then
			t.IsRanged = GetDist(t.mon) > 350
			t.Attack = Game.CharacterPortraits[t.Player.Face][t.IsRanged and "DefAttackR" or "DefAttackM"]
		else
			t.Attack = Game.CharacterPortraits[t.Player.Face].DefAttackR
		end
		events.call("GetSpecialAttack", t)

		local def = mem.u4[d.ebp-0x10]
		mem.u4[CurAttack] = t.Attack
		mem.u4[d.ebp-0x10] = t.Attack > 0 and def or 0
	end

	mem.autohook(0x42d91d, function(d) SpecialAttackHook(d, d.esi, d.ecx) end)
	mem.autohook2(0x42d966, function(d) SpecialAttackHook(d, d.esi, d.edi) end)

	-- Remove SP requirements from custom attacks:

	mem.asmpatch(0x425b47, [[
	cmp dword [ss:ebp-0x24], 1
	je @fre
	mov dword [ds:ecx+0x1bfc], eax
	@fre:]])

	mem.asmpatch(0x425b1a, [[
	mov eax, dword [ds:ecx+0x1bfc]
	cmp dword [ss:ebp-0x24], 1
	je absolute 0x425b43]])

	mem.asmpatch(0x4262ce, [[
	mov edx, dword [ds:eax+0x1bfc]
	cmp dword [ss:ebp-0x24], 1
	je absolute 0x4262ec]])

	-- Load actual attack's sound:

	mem.asmpatch(0x42db69, [[
	mov ecx, dword [ss:esp-0xc]
	cmp ecx, 0x89
	je @std
	movsx ecx, word [ds:0x4fe128+ecx*2]
	push ecx
	jmp @end
	@std:
	push 0x46a0
	@end:]])

	-- Use race to define starting stats
	TmpTable = {0x4c6a17, 0x4c6a55, 0x4c6ab3, 0x4c6aea, 0x48fa84, 0x4903cf, 0x4903e6,
				0x4903fd, 0x490414, 0x49042b, 0x490442, 0x490459, 0x48f87d, 0x48f6eb}

	local NewCode = mem.asmproc([[
	movsx eax, byte [ds:ecx+0x353]
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, ]] .. PortraitsTablePtr .. [[;
	movsx eax, byte [ds:eax+0x3f];
	retn]])

	for k,v in pairs(TmpTable) do
		mem.asmpatch(v, "call absolute " .. NewCode)
	end

end

local function ProcessDollTypesTable()

	local function GenerateDollTypesTable()

		local AvItemsPatterns	=	{"x	x	x	x	x	x	x",
									 "x	x	x	x	x	x	x",
									 "x	x	-	x	-	x	x",
									 "x	x	x	x	x	x	x",
									 "-	-	-	-	-	-	-"}

		local DollsTxtTable = io.open("Data/Tables/Character doll types.txt", "w")

		DollsTxtTable:write("#	Bow	Armor	Helm	Belt	Boots	Cloak	Weapon	RHo X	RHo Y	RHc X	RHc Y	RHf X	RHf Y	LHo X	LHo Y	LHc X	LHc Y	LHf X	LHf Y	OH Offset X	OH Offset Y	MH Offset X	MH Offset Y	Bow Offset X	Bow Offset Y	Shield X	Shield Y\n")

		for i = 0, 4 do

			local CurStr = i .. "\9" .. AvItemsPatterns[i+1] .. "\9"
							.. mem.i4[0x4f63d8+i*16] .. "\9" .. mem.i4[0x4f63dc+i*16] .. "\9"
							.. mem.i4[0x4f63e0+i*16] .. "\9" .. mem.i4[0x4f63e4+i*16] .. "\9"
							.. mem.i4[0x4f6398+i*8] .. "\9" .. mem.i4[0x4f639c+i*8] .. "\9"
							.. mem.i4[0x4f6338+i*8] .. "\9" .. mem.i4[0x4f633c+i*8] .. "\9"
							.. mem.i4[0x4f6378+i*8] .. "\9" .. mem.i4[0x4f637c+i*8] .. "\9"
							.. mem.i4[0x4f6358+i*8] .. "\9" .. mem.i4[0x4f635c+i*8] .. "\9"
							.. mem.i4[0x4f63b8+i*8] .. "\9" .. mem.i4[0x4f63bc+i*8] .. "\9"
							.. mem.i4[0x4f58a0+i*128] .. "\9" .. mem.i4[0x4f58a4+i*128] .. "\9"
							.. mem.i4[0x4f58a8+i*128] .. "\9" .. mem.i4[0x4f58ac+i*128] .. "\9"
							.. mem.i4[0x4f5898+i*128] .. "\9" .. mem.i4[0x4f589c+i*128] .. "\n"

			DollsTxtTable:write(CurStr)

		end

		io.close(DollsTxtTable)

	end


	local Counter, TypesCount, LineSize = 0, 0, 47
	local DollsTxtTable = io.open("Data/Tables/Character doll types.txt", "r")

	if not DollsTxtTable then
		GenerateDollTypesTable()
		DollsTxtTable = io.open("Data/Tables/Character doll types.txt", "r")
	end

	local LineIt = DollsTxtTable:lines()

	LineIt() -- Skip header
	for line in LineIt do
		TypesCount = TypesCount + 1
	end

	local DollsTablePtr = mem.StaticAlloc(TypesCount*LineSize)

	DollsTxtTable:seek("set")

	LineIt()
	for line in LineIt do
		local Words = string.split(line, "\9")

		for i = 0, 6 do
			if Words[i+2] == "x" then
				mem.u1[DollsTablePtr + Counter*LineSize + i] = 1
			end
		end

		for i = 0, 19 do
			mem.i2[DollsTablePtr + Counter*LineSize + 7 + i*2] = tonumber(Words[i+9])
		end

		Counter = Counter + 1
	end

	ChangeGameArray("CharacterDollTypes", DollsTablePtr, TypesCount)

	----

	local CheckItem = mem.asmproc([[
	movsx eax, byte [ds:ebx+0x353]; Portrait, ecx - item
	nop;memhook here
	nop
	nop
	nop
	nop
	retn]])

	local ItemTypes = {
		Bow 	= {3, 27},
		Weapon 	= {0,1,2,4,12,19,23,24,25,26,27,28,29,30,33,41},
		Armor 	= {3,20,30,31,32},
		Belt 	= {6,35},
		Helm 	= {5,34},
		Cloak 	= {7,36},
		Boots 	= {9,38}}

	local function CheckItemAvailability(TypeId, ItemId)

		local result = 1

		if TypeId > Game.CharacterDollTypes.count - 1 then
			return result
		end

		local EquipStat = Game.ItemsTxt[ItemId].EquipStat
		for k,v in pairs(ItemTypes) do
			if table.find(v, EquipStat) then
				result = Game.CharacterDollTypes[TypeId][k] and 1 or 0
				break
			end
		end

		if Game.CurrentPlayer >= 0 and Game.CurrentPlayer < Party.count then
			local t = {ItemId = ItemId, PlayerId = Game.CurrentPlayer, Available = result == 1}
			events.cocall("CanWearItem", t)
			result = t.Available and 1 or 0
		end

		return result
	end

	mem.hook(CheckItem + 7, function(d)
		d.eax = CheckItemAvailability(Game.CharacterPortraits[d.eax].DollType, d.ecx)
	end)

	mem.nop(0x49103a, 4)
 	mem.asmpatch(0x49103e, [[
	mov ecx, dword [ds:esi]
	call absolute ]] .. CheckItem)

	mem.nop(0x4674ec, 3)
 	mem.asmpatch(0x4674ef, [[call absolute ]] .. CheckItem)

	-- ? Check: 0x43b7e6 (0x4f63b8)

	-- . 0x4f5894 - y anchor point - static for all portraits
	-- + 0x4f5898, 0x4f589c + i*4 - offhand offsets???

	-- + 0x4f58a8, 0x4f58ac - bow offsets
	-- + 0x4f58a0, 0x4f58a4 - main hand offsets

	-- + 0x4f635c, 0x4f6358 - corrected in Items.lua

	-- 0x4f6418, 0x4f6430 - ??

	-- + 0x43a9e0 - setup pointer.

	-- + 0x4f5a98, 0x4f5a9c - corrected in Items.lua


	mem.asmpatch(0x43a9e0, [[
	mov eax, dword [ss:esp+0x38];]])

	-- Unk

	mem.asmpatch(0x43b83c, [[
	mov edx, eax
	shr edx, 7
	imul edx, edx, ]] .. LineSize .. [[;
	add edx, ]] .. DollsTablePtr .. [[;
	movsx edx, word [ds:edx+0x2b]
	cmp byte [ss:esp+0x28], bl;]])

	mem.asmpatch(0x43b875, [[
	mov ebx, eax
	shr ebx, 7
	imul ebx, ebx, ]] .. LineSize .. [[;
	add ebx, ]] .. DollsTablePtr .. [[;
	movsx ebx, word [ds:ebx+0x2d]
	add edx, ebx
	xor ebx, ebx;]])

	mem.asmpatch(0x43b888, [[
	shr eax, 7
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, ]] .. DollsTablePtr .. [[;
	movsx eax, word [ds:eax+0x2d];]])

	-- Bow offsets

	mem.nop(0x43a510, 3)
	mem.asmpatch(0x43a513, [[
	imul ecx, ecx, ]] .. LineSize .. [[;
	add ecx, ]] .. DollsTablePtr .. [[;
	movsx edx, word [ds:ecx+0x27];]])

	mem.asmpatch(0x43a519, [[
	movsx ecx, word [ds:ecx+0x29];]])

	-- MH Offsets

	mem.asmpatch(0x43b5b2, [[
	mov ecx, dword [ss:esp+0x38]
	movsx ebx, word [ds:ecx+0x23]
	add edi, ebx
	xor ebx, ebx]])

	mem.asmpatch(0x43b5d4, [[
	movsx ebx, word [ds:ecx+0x25]
	add edi, ebx
	xor ebx, ebx]])

	-- LHc
	mem.asmpatch(0x43a99e, [[
	movsx ecx, word [ds:eax+0x19]
	movsx eax, word [ds:eax+0x17]
	jmp absolute 0x43a9aa]])

	mem.asmpatch(0x43ba97, [[
	mov eax, dword [ds:esp+0x24]
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, ]] .. DollsTablePtr .. [[;
	movsx ecx, word [ds:eax+0x19]
	movsx eax, word [ds:eax+0x17]
	jmp absolute 0x43baa3]])

	-- LHo

	mem.nop(0x43a8e2, 3)
	mem.asmpatch(0x43a8e5, [[
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, ]] .. DollsTablePtr .. [[;
	movsx edx, word [ds:eax+0x15];]])

	mem.asmpatch(0x43a8f1, [[
	movsx ecx, word [ds:eax+0x13];]])
	-- pointer stored at 0x43a909

	mem.asmpatch(0x43b7ea, [[
	movsx eax, word [ds:ecx+0x13];]])

	mem.asmpatch(0x43b7f0, [[
	movsx ebx, word [ds:ecx+0x1f]
	add eax, ebx
	xor ebx, ebx]])

	mem.asmpatch(0x43b802, [[
	movsx eax, word [ds:ecx+0x15];]])

	mem.asmpatch(0x43b808, [[
	movsx ebx, word [ds:ecx+0x21]
	add eax, ebx
	xor ebx, ebx]])

	mem.asmpatch(0x43ba03, [[
	movsx ecx, word [ds:eax+0x13]
	movsx eax, word [ds:eax+0x15]
	jmp absolute 0x43ba0f]])

	mem.nop(0x4c4fee, 3)
	mem.asmpatch(0x4c4ff1, [[
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, ]] .. DollsTablePtr .. [[;
	movsx ecx, word [ds:eax+0x13]
	movsx eax, word [ds:eax+0x15]
	jmp absolute 0x4c4ffd]])

	-- LHf

	mem.asmpatch(0x43a952, [[
	movsx ecx, word [ds:eax+0x1d];]])

	mem.asmpatch(0x43a958, [[
	movsx eax, word [ds:eax+0x1b];]])

	mem.asmpatch(0x43ba68, [[
	movsx ecx, word [ds:eax+0x1d]
	movsx eax, word [ds:eax+0x1b]
	jmp absolute 0x43ba74]])

	-- RHo

	mem.nop(0x4c5061, 3)
	mem.asmpatch(0x4c5064, [[
	imul eax, eax, ]] .. LineSize .. [[;
	add eax, ]] .. DollsTablePtr .. [[;
	movsx ecx, word [ds:eax+0x7]
	movsx eax, word [ds:eax+0x9]
	jmp absolute 0x4c5070]])

	mem.asmpatch(0x43aa34, [[
	movsx ecx, word [ds:eax+0x9]
	movsx eax, word [ds:eax+0x7]
	jmp absolute 0x43aa40]])

	-- RHc

	mem.nop(0x43a9e4, 3)
	mem.asmpatch(0x43aa0d, [[
	movsx ecx, word [ds:eax+0xd]
	movsx eax, word [ds:eax+0xb]
	jmp absolute 0x43aa19]])

	mem.asmpatch(0x43b57c, [[
	movsx edi, word [ds:edi+0xb];]])

	mem.asmpatch(0x43b5c1, [[
	movsx edi, word [ds:edi+0xd];]])

	-- RHf

	mem.asmpatch(0x43b77b, [[
	movsx ecx, word [ds:eax+0x11];]])

	mem.asmpatch(0x43b787, [[
	movsx eax, word [ds:eax+0xf];]])


end


function events.GameInitialized1()

	ProcessVoicesTable()
	ProcessDollTypesTable()
	ProcessPortraitsTable()
	SetResistancesHook()
	SetChooseCharHook()

end

