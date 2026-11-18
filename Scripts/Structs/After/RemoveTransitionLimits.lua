local u2, u4, memstr = mem.u2, mem.u4, mem.string

-- Transition screens:
local NewTransCount, NewTransPtr, TransIndexPtr

local function GetTransPtr(Id)
	for i = 0, NewTransCount-1 do
		if u2[TransIndexPtr+i*2] == Id then
			return u4[NewTransPtr + i*4]
		end
	end
	return u4[NewTransPtr]
end

mem.autohook2(0x475798, function(d)

	NewTransCount 	= DataTables.ComputeRowCountInPChar(d.eax, 1) - 1
	NewTransPtr 	= mem.StaticAlloc(NewTransCount*4 + 4 + NewTransCount*4)
	TransIndexPtr 	= NewTransPtr + NewTransCount*4 + 4

	local Counter = 0

	mem.autohook2(0x4757ba, function(d)
		u2[TransIndexPtr + Counter*2] = tonumber(string.split(memstr(d.eax + 1), "\9")[1]) or 0xffff
		Counter = Counter + 1
	end)

	mem.autohook2(0x441b90, function(d)
		local t = {TransId = d.eax, EnterMap = memstr(u4[0x5a5454])}
		events.call("GetTransitionText", t)
		if t.TransId == 0 then
			return
		elseif t.Text then
			d.eax = mem.topointer(t.CustomText)
		else
			d.eax = GetTransPtr(t.TransId)
		end
	end)

	mem.nop(0x441bb3, 7)

	mem.hook(0x4b125f, function(d)
		d.eax = GetTransPtr(d.eax)
	end)

	mem.IgnoreProtection(true)
	u4[0x4757b0 + 4] = NewTransPtr
	u4[0x475828 + 4] = NewTransPtr + NewTransCount*4
	mem.IgnoreProtection(false)

	local NewCode = mem.asmproc([[
	nop
	nop
	nop
	nop
	nop
	test esi, esi
	je @equ

	push 0x4f41a4
	jmp @end

	@equ:
	push 0x4f4380

	@end:
	jmp absolute 0x44179b]])

	mem.hook(NewCode, function(d)
		local CurName = Game.HouseMovies[Game.Houses[u4[d.ebp - 0x14]].Picture].FileName
		if CurName == "null" or CurName == "" then
			d.esi = 0
			u4[d.ebp-0x10] = 1
		end
	end)

	mem.asmpatch(0x4418be, "jmp absolute " .. NewCode)

	if Game.TransTxt then
		structs.o.GameStructure.TransTxt = NewTransPtr
		internal.SetArrayUpval(Game.TransTxt, "o", NewTransPtr)
		internal.SetArrayUpval(Game.TransTxt, "count", NewTransCount)
	end

end)

-- Houses's other exits:

-- Disabling default mechanics and rescripting via Quest function -
-- easier, and less misty at that point.
local ExitMapPics 		-- pics for exits
local OtherExitDummy 	-- Free NPC
local OtherExitTopic	-- Free topic
local OtherExitMap
local BlvEntrances
local function ProcessExitsTable()

	local ExitsTxt = io.open("Data/Tables/House exits.txt", "r")
	if not ExitsTxt then
		ExitsTxt = io.open("Data/Tables/House exits.txt", "w")
		ExitsTxt:write([[NPC pics:	1561	1562	1563	1564	1565	1566	1567\nFree NPC:	31\nFree topic:	750\nMap name	X	Y	Z	X	Y	Z	X	Y	Z	X	Y	Z	X	Y	Z	X	Y	Z]])
		ExitsTxt:close()
		return false
	end

	if not ExitsTxt then
		return false
	end

	local LineIt = ExitsTxt:lines()
	local Line = LineIt()
	local Words
	if not Line then
		Words = {0, 1561, 1562, 1563, 1564, 1565, 1566, 1567}
	else
		Words = string.split(Line, "\9")
	end

	ExitMapPics = {}
	for i = 2, 8 do
		table.insert(ExitMapPics, tonumber(Words[i]) or 0)
	end

	Line = LineIt()
	if not Line then
		OtherExitDummy = 31
	else
		OtherExitDummy = tonumber(string.split(Line, "\9")[2]) or 1
	end
	Game.HouseExtraExitNPCDummy = OtherExitDummy

	Line = LineIt()
	if not Line then
		OtherExitTopic = 750
	else
		OtherExitTopic = tonumber(string.split(Line, "\9")[2]) or 750
	end
	Game.HouseExtraExitTopic = OtherExitTopic


	BlvEntrances = {}
	LineIt() -- skip header
	for line in LineIt do
		Words = string.split(line, "\9")
		local CurEnts = {}
		for i = 1, 6 do
			local CurShift = (i-1)*3+2
			CurEnts[i] = {	X = tonumber(Words[CurShift]) or 0,
							Y = tonumber(Words[CurShift+1]) or 0,
							Z = tonumber(Words[CurShift+2]) or 0}
		end
		BlvEntrances[Words[1]] = CurEnts
	end

	return true
end

local function InitHouseExits()

	mem.asmpatch(0x442ebd, "xor eax, eax")
	mem.asmpatch(0x442eca, "jmp 0x442eef - 0x442eca")

	local TransText
	local function ExitTopic()
		evt.MoveToMap(OtherExitMap)
	end

	function RefreshHouseMapExit(i)
		local CurHouse = Game.Houses[i]
		if CurHouse.ExitPic > 0 and CurHouse.ExitMap > 0 then
			local CurNPC = Game.NPC[OtherExitDummy]
			local X,Y,Z = 0,0,0
			local Ent = CurHouse.QuestBitRestriction
			local EntMap = Game.MapStats[CurHouse.ExitMap]
			if Ent < 0 then
				Ent = BlvEntrances and BlvEntrances[EntMap.FileName] and BlvEntrances[EntMap.FileName][math.abs(Ent)]
				if Ent then
					X,Y,Z = Ent.X, Ent.Y, Ent.Z
				end
			elseif Ent > 0 and not Party.QBits[Ent] then
				evt.MoveNPC{OtherExitDummy, 0}
				return
			end
			CurNPC.Pic = ExitMapPics[CurHouse.ExitPic] or 0
			CurNPC.Name = EntMap.Name
			Game.NPCTopic[OtherExitTopic] = CurHouse.EnterText ~= "0" and CurHouse.EnterText or EntMap.Name

			local t = {TransId = 0, EnterMap = EntMap.FileName}
			events.call("GetTransitionText", t)

			if t.Text then
				TransText = t.Text
			else
				TransText = GetTransPtr(t.TransId > 0 and t.TransId or i)
				TransText = TransText > u4[NewTransPtr] and memstr(TransText) or EntMap.Name
			end
			OtherExitMap = {X,Y,Z,0,0,0,0,0,Game.MapStats[CurHouse.ExitMap].FileName}
			evt.MoveNPC{OtherExitDummy, i}
		end
	end

	function events.DrawNPCGreeting(t)
		if t.NPC == OtherExitDummy then
			t.Text = TransText
		end
	end

	function events.EnterHouse(i)
		RefreshHouseMapExit(i)
	end

	mem.autohook2(0x44556b, function(d)
		events.call("EnterHouse", d.edi)
	end)

	mem.autohook2(0x44565c, function(d)
		events.call("AfterEnterHouse", d.edi)
	end)

	function events.LoadMapScripts(WasInGame)
		if not WasInGame then
			evt.Global[OtherExitTopic] = ExitTopic
			Game.NPC[OtherExitDummy].EventA = OtherExitTopic
		end
	end
end

function events.GameInitialized2()
	if ProcessExitsTable() then
		InitHouseExits()
		Game.BlvEntrances = BlvEntrances
	end
end
