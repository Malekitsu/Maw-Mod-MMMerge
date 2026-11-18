
local TeacherNotesTable

local function ParseTNTable()

	local TxtTable = io.open("Data/Tables/Teacher autonotes.txt", "r")

	if not TxtTable then
		return false
	end

	local Words
	local LineIt = TxtTable:lines()
	LineIt() -- skip header

	TeacherNotesTable = {}
	for line in LineIt do
		Words = string.split(line, "\9")

		local CurT = tonumber(Words[1])
		if CurT then
			TeacherNotesTable[CurT] = {}
			for i = 1, (table.maxn(Words) - 2)/2 do
				local CurNPC = tonumber(Words[i*2+1])
				local CurATN = tonumber(Words[i*2+2])
				if CurNPC and CurATN then
					TeacherNotesTable[CurT][CurNPC] = CurATN
				end
			end
		end
	end

	return true

end

local function GetTeacherNoteText(SkillId, Mastery)
	local MasteryNames = {Game.GlobalTxt[433], Game.GlobalTxt[432], Game.GlobalTxt[225]}
	return Game.SkillNames[SkillId] .. " - " .. MasteryNames[Mastery]
end

local function GenerateTeacherNoteId(SkillId, Mastery)
	local CurCont = TownPortalControls.MapOfContinent(Map)
	return CurCont * 1000 + Mastery * 100 + SkillId
end

local function SetMapNote(X, Y, Text, Id, ShowEffect)
	local Note
	for i,v in Map.Notes do
		if v.Id == Id then
			v.Active = true
			return Note
		end
	end

	for i,v in Map.Notes do
		if not v.Active and v.Id == 0 then
			Note = v
			break
		end
	end

	if not Note then
		return
	end

	Note.X = X
	Note.Y = Y
	Note.Text = Text or ""
	Note.Active = true
	Note.Id = Id or 0

	if ShowEffect then
		evt.Set{"Food", Party.Food} -- Show quest effect
	end

	return Note
end
Game.SetMapNote = SetMapNote

function events.GameInitialized2()

	if not ParseTNTable() then
		return
	end

	local CurTeacherTopicsPtr = mem.StaticAlloc(24)

	function events.EnterNPC(NPCid)
		local Counter = 0
		for i = 0, 5 do
			local CurEvent = Game.NPC[NPCid].Events[i]
			local CurNote = TeacherNotesTable[CurEvent]
			local TopicProps = Game.TeacherTopics[CurEvent]

			if CurNote then
				CurNote = CurNote[NPCid]
				if CurNote and Game.AutonoteTxt[CurNote]:len() > 1 then
					mem.u2[CurTeacherTopicsPtr+Counter*4] = CurEvent
					mem.u2[CurTeacherTopicsPtr+Counter*4 + 2] = CurNote
					Counter = Counter + 1
				end

			elseif TopicProps then
				SetMapNote(Party.X, Party.Y, GetTeacherNoteText(TopicProps.SId, TopicProps.Mas), GenerateTeacherNoteId(TopicProps.SId, TopicProps.Mas), true)
			end
		end
	end

	mem.asmpatch(0x4b1538, [[
	xor ecx, ecx
	jmp @start

	@rep:
	inc ecx
	cmp ecx, 5
	je @neq

	@start:
	cmp dx, word [ds:ecx*4+]] .. CurTeacherTopicsPtr .. [[]
	jnz @rep

	mov dx, word [ds:ecx*4+]] .. CurTeacherTopicsPtr + 2 .. [[]
	jmp absolute 0x4b153e

	@neq:
	jmp absolute 0x4b154e]])

end
