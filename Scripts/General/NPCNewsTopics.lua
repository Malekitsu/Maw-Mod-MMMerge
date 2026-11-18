
local NPCNames = {F = {}, M = {}}
local ProfNames = {}
local ContinentNews = {}
local ProfNews = {}
local MapNews = {}
local UsedPics = {}
Game.NPCNames = NPCNames
Game.NPCProfessions = ProfNames
Game.MapNews = MapNews
Game.ContinentNews = ContinentNews
Game.ProfessionNews = ProfNews

----

local FreeTopics	= {	1031, 1032, 1033}
local FreeNPCs	= {	1184, 1185, 1186, 1187, 1188, 1189, 1190, 1191, 1192, 1193, 1194, 1195, 1196, 1197, 1198, 1199, 1200, 1201, 1202, 1203,
						1204, 1205, 1206, 1207, 1208, 1209, 1210, 1211, 1212, 1213, 1214, 1215, 1216, 1217, 1218, 1219, 1220, 1221, 1222, 1223}

local TypeRaceCons = {
	[const.Bolster.MonsterType.Human]		= const.Race.Human,
	[const.Bolster.MonsterType.Undead] 		= -1,
	[const.Bolster.MonsterType.Demon] 		= -1,
	[const.Bolster.MonsterType.Dragon] 		= const.Race.Dragon,
	[const.Bolster.MonsterType.Elf]			= const.Race.Elf,
	[const.Bolster.MonsterType.Swimmer]		= -1,
	[const.Bolster.MonsterType.Immobile]	= -1,
	[const.Bolster.MonsterType.Titan] 		= -1,
	[const.Bolster.MonsterType.NoArena]		= -1,
	[const.Bolster.MonsterType.Creature]	= -1,
	[const.Bolster.MonsterType.Construct]	= -1,
	[const.Bolster.MonsterType.Elemental]	= -1,
	[const.Bolster.MonsterType.Goblin]		= const.Race.Goblin,
	[const.Bolster.MonsterType.Dwarf]		= const.Race.Dwarf,
	[const.Bolster.MonsterType.DarkElf]		= const.Race.DarkElf,
	[const.Bolster.MonsterType.Lizardman]	= -1,
	[const.Bolster.MonsterType.Ogre]		= -1,
	[const.Bolster.MonsterType.Minotaur]	= const.Race.Minotaur,
	[const.Bolster.MonsterType.Troll]	= const.Race.Troll
}

local function FindMonApp(i)
	local T = Game.Bolster.MonstersSource[i]

	if T and T.Creed == 3 then
		local Portraits = Game.MonsterPortraits[math.ceil(i/3)]
		local Pid = Portraits[math.random(1, #Portraits)]
		local Counter = 0

		while table.find(UsedPics, Pid) do
			Pid = Portraits[math.random(1, #Portraits)]
			if Counter > 4 then break end
			Counter = Counter + 1
		end

		return {Mid = i, Gender = T.Gender, Pid = Pid, Race = TypeRaceCons[T.Type] or -1}
	end

	return nil
end

NPCFollowers.GetMonAppearance = FindMonApp

local function TellMapNews()
	Message(MapNews[Map.MapStatsIndex][mapvars.MapNPCNews[GetCurrentNPC()].Text].Text)
end

local function TellProfNews()
	Message(ProfNews[Game.NPC[GetCurrentNPC()].Profession][Game.DayOfMonth - Game.WeekOfMonth*7+1].Text)
end

local function TellContinentNews()
	Message(ContinentNews[TownPortalControls.GetCurrentSwitch()][Game.NPC[GetCurrentNPC()].NewsTopic].Text)
end

-- Text tables processing

local function ProcessNamesTXT()
	local NamesTXT = io.open("Data/Tables/NPC names.txt", "r")

	if not NamesTXT then
		return
	end

	local LineIt = NamesTXT:lines()
	LineIt()

	for line in LineIt do
		local Words = string.split(line, "\9")
		if Words[1] and string.len(Words[1]) > 0 then
			table.insert(NPCNames["M"], Words[1])
		end
		if Words[2] and string.len(Words[2]) > 0 then
			table.insert(NPCNames["F"], Words[2])
		end
	end

	io.close(NamesTXT)
end

local TextRefMT = {
	__index = function(t, k)
		if k == "Text" or k == "Name" then
			local v = rawget(t, "Predef" .. k)
			if v then
				return v
			end
			return Game[rawget(t, k .. "Src")][rawget(t, k .. "Id")]
		end
		return nil
	end
}

local function NewsItemValues(TopicStr, TextStr)
	local find1, find2

	local result = {TextSrc = "NPCNews", TextId = 0, NameSrc = "NPCTopic", NameId = 0}

	local NameInLod = TopicStr
	find1 = string.find(NameInLod, "^%d+$")
	find2 = string.find(NameInLod, "^[A-Za-z]+ %d+$")
	if find1 then
		result.NameSrc = "NPCNewsTopics"
		result.NameId = tonumber(NameInLod)
	elseif find2 then
		NameInLod = string.split(NameInLod, " ")
		result.NameSrc = NameInLod[1]
		result.NameId = tonumber(NameInLod[2])
	end

	local TextInLod = TextStr
	find1 = string.find(TextInLod, "^%d+$")
	find2 = string.find(TextInLod, "^[A-Za-z]+ %d+$")
	if find1 then
		result.TextSrc = "NPCNews"
		result.TextId = tonumber(TextInLod)
	elseif find2 then
		TextInLod = string.split(TextInLod, " ")
		result.TextSrc = TextInLod[1]
		result.TextId = tonumber(TextInLod[2])
	end

	setmetatable(result, TextRefMT)
	return result
end

local function ProcessProfNewsTXT()
	local NewsTXT = io.open("Data/Tables/News topics - profession.txt", "r")

	if not NewsTXT then
		return
	end

	local LineIt = NewsTXT:lines()
	LineIt()

	local Counter = 1
	for line in LineIt do
		local Words = string.split(line, "\9")

		ProfNames[Counter] = ProfNames[Counter] or Words[2]
		ProfNews[Counter] = {}

		for i = 0, 6 do
			ProfNews[Counter][i+1] = NewsItemValues(Words[3+i*2], Words[4+i*2])
		end

		Counter = Counter + 1
	end

	io.close(NewsTXT)
end

local function ProcessMapNewsTXT()
	local NewsTXT = io.open("Data/Tables/News topics - area.txt", "r")

	if not NewsTXT then
		return
	end

	local LineIt = NewsTXT:lines()
	LineIt()

	for line in LineIt do
		local Words = string.split(line, "\9")
		local CurNum = tonumber(Words[1])

		MapNews[CurNum] = MapNews[CurNum] or {}
		table.insert(MapNews[CurNum], NewsItemValues(Words[2], Words[3]))
	end

	io.close(NewsTXT)
end

local function ProcessContinentNewsTXT()
	local NewsTXT = io.open("Data/Tables/News topics - continent.txt", "r")

	if not NewsTXT then
		return
	end

	local LineIt = NewsTXT:lines()
	LineIt()

	for line in LineIt do
		local Words = string.split(line, "\9")
		local CurNum = tonumber(Words[1])

		ContinentNews[CurNum] = ContinentNews[CurNum] or {}
		table.insert(ContinentNews[CurNum], NewsItemValues(Words[2], Words[3]))
	end

	io.close(NewsTXT)
end

-- Events
local CurGreet
local function GetRandomProf(Max)
	local tmp = {[0] = 0}
	for k,v in pairs(Game.NPCProf) do
		if v.Rarity <= Max then
			table.insert(tmp, k)
		end
	end
	return tmp[math.random(0,#tmp)]
end

local function SetNewsTopics(npc)
	local Continent = TownPortalControls.GetCurrentSwitch()
	local FrEv = {}
	local CurEvents = Game.NPC[npc].Events
	local cNPC = Game.NPC[npc]

	-- Set news topics.

	for i = 0, 2 do
		local v = CurEvents[i]
		if v == 0 or table.find(FreeTopics, v) then
			table.insert(FrEv, i)
			CurEvents[i] = 0
		end
	end

	local T
	if mapvars.MapNPCNews and MapNews[Map.MapStatsIndex] then
		T = mapvars.MapNPCNews[npc]
		if T and #FrEv > 0 and T.Text > 0 then
			CurEvents[FrEv[#FrEv]] = FreeTopics[1]
			table.remove(FrEv)
			Game.NPCTopic[FreeTopics[1]] = MapNews[Map.MapStatsIndex][T.Text].Name
		end
	end

	T = ProfNews[cNPC.Profession]
	if Game.ContinentSettings[Continent].ProfNews and T and #FrEv > 0 then
		CurEvents[FrEv[#FrEv]] = FreeTopics[2]
		table.remove(FrEv)
		Game.NPCTopic[FreeTopics[2]] = T[Game.DayOfMonth - Game.WeekOfMonth*7+1].Name
	end

	T = ContinentNews[Continent]
	if T and #FrEv > 0 and cNPC.TellsNews ~= 0 then
		local NT = cNPC.NewsTopic
		if cNPC.TellsNews ~= Game.WeekOfMonth + 2 then
			NT = math.random(1, #T)
			cNPC.TellsNews = Game.WeekOfMonth + 2
			cNPC.NewsTopic = NT
		end
		Game.NPCTopic[FreeTopics[3]] = T[NT].Name
		CurEvents[FrEv[#FrEv]] = FreeTopics[3]
		table.remove(FrEv)
	end
end
NPCFollowers.SetNewsTopics = SetNewsTopics

local function IsRandomNPC(npc)
	return table.find(FreeNPCs, npc) ~= nil
end
NPCFollowers.IsRandomNPC = IsRandomNPC

local function RandomizeNPC()

	UsedPics = {}

	local CurMapNews = MapNews[Map.MapStatsIndex]
	local MapStatsExtra = Game.Bolster.MapsSource[Map.MapStatsIndex]

	math.randomseed(os.time())
	mapvars.MapNPCNews = {}

	local RecNPCs = {}
	for i, v in Map.Monsters do
		if (v.NPC_ID == 0 or IsRandomNPC(v.NPC_ID)) and (not v.Hostile) then
			local App = FindMonApp(v.Id)
			if App then
				App.Mid = i
				table.insert(RecNPCs, App)
			end
			v.NPC_ID = 0
		end
	end

	local Continent = TownPortalControls.GetCurrentSwitch()
	local Sum		= #RecNPCs
	local SumNews	= CurMapNews and #CurMapNews or 0
	local SumProfs	= #ProfNames
	local SumNames	= {M = #NPCNames["M"], F = #NPCNames["F"]}

	local CurFreeNPCs = {}
	for i,v in pairs(FreeNPCs) do
		if not NPCFollowers.NPCInGroup(v) then
			CurFreeNPCs[i] = v
		end
	end

	for i,v in pairs(CurFreeNPCs) do

		local CurMon = table.remove(RecNPCs,1)
		if not CurMon then
			break
		end

		CurMon.Text = SumNews > 0 and math.random(1, SumNews) or 0
		CurMon.Name = math.random(1, SumNames[CurMon.Gender])
		CurMon.Profession = GetRandomProf(MapStatsExtra.ProfsMaxRarity)
		CurMon.Alignment = math.random(1,2) == 1 and "G" or "E"

		local MapMon = Map.Monsters[CurMon.Mid]

		local cNPC = Game.NPC[v]
		if not NPCFollowers.NPCInGroup(v) then
			MapMon.NPC_ID = v
			cNPC.Pic		= CurMon.Pid
			cNPC.Profession = CurMon.Profession
			cNPC.Name		= NPCNames[CurMon.Gender][CurMon.Name]
		end
		cNPC.TellsNews = 1

		cNPC.EventA = 0
		cNPC.EventB = 0
		cNPC.EventC = 0
		cNPC.EventD = 0
		cNPC.EventE = 0
		cNPC.EventF = 0

		--if not Game.NPCPersonalities[Game.NPCProf[cNPC.Profession].Personality].AcceptThreat then
		--	MapMon.AIType = 2
		--	MapMon.HostileType = 4
		--end

		mapvars.MapNPCNews[v] = CurMon

	end
end
NPCFollowers.RandomizeNPC = RandomizeNPC

function events.NewGameMap()
	local cNPC
	local mNames = NPCNames["M"]
	for k,v in pairs(FreeNPCs) do
		cNPC = Game.NPC[v]
		cNPC.Name = mNames[math.random(#mNames)]
	end
end

local function LoadRandomNPCs(MapNPCNews)
	for k,v in pairs(MapNPCNews) do
		if v.Mid >= Map.Monsters.count then
			-- skip
		elseif NPCFollowers.NPCInGroup(k) then
			Map.Monsters[v.Mid].NPC_ID = 0
		else
			local cNPC = Game.NPC[k]
			Map.Monsters[v.Mid].NPC_ID = k
			cNPC.Name = NPCNames[v.Gender][v.Name]
			cNPC.Profession = v.Profession
			cNPC.Pic = v.Pid

			cNPC.EventA = 0
			cNPC.EventB = 0
			cNPC.EventC = 0
			cNPC.EventD = 0
			cNPC.EventE = 0
			cNPC.EventF = 0
		end
	end
end
NPCFollowers.LoadRandomNPCs = LoadRandomNPCs

function events.LoadMapScripts(WasInGame)

	if not WasInGame then
		local cNPC
		Game.GlobalEvtLines:RemoveEvent(FreeTopics[1])
		Game.GlobalEvtLines:RemoveEvent(FreeTopics[2])
		Game.GlobalEvtLines:RemoveEvent(FreeTopics[3])

		evt.Global[FreeTopics[1]] = TellMapNews
		evt.Global[FreeTopics[2]] = TellProfNews
		evt.Global[FreeTopics[3]] = TellContinentNews

		if vars.RndNPCPersist then
			for k,v in pairs(vars.RndNPCPersist) do
				cNPC = Game.NPC[k]
				cNPC.Name 		= v.Name
				cNPC.Profession = v.Prof
				cNPC.Picture	= v.Pic
			end
		end
	end

	local MapId = Map.MapStatsIndex
	local CurMapNews = MapNews[MapId]
	local MapStatsExtra = Game.Bolster.MapsSource[MapId]

	if MapStatsExtra.ProfsMaxRarity == 0 then
		return
	end

	if not mapvars.NPCRefillDate or mapvars.NPCRefillDate + const.Month < Game.Time then
		RandomizeNPC()
		mapvars.NPCRefillDate = Game.Time

	elseif mapvars.MapNPCNews then
		LoadRandomNPCs(mapvars.MapNPCNews)
	end

end

function events.EnterNPC(i)

	-- Avoid reprocessing greet.
	CurGreet = nil

	if IsRandomNPC(i) then
		NPCFollowers.ClearEvents(Game.NPC[i])
	end

	if NPCFollowers.NPCWillSpeak(i) then
		NPCFollowers.SetHireTopic(i)
		SetNewsTopics(i)

	else
		NPCFollowers.SetBTBTopics(i)

	end

end

-- Game.NPCGroup have item size of 4 bytes, but game uses 2 bytes, so need to use this for now.
local function GetNPCGroupNews(Group)
	return mem.i2[Game.NPCGroup["?ptr"]+(Group-1)*2]
end
NPCFollowers.GetNPCGroupNews = GetNPCGroupNews

local function GetRepName(Rep)
	Rep = Rep or NPCFollowers.GetPartyReputation()
	if Rep > 24 then
		return Game.GlobalTxt[379]
	elseif Rep > 5 then
		return Game.GlobalTxt[392]
	elseif Rep > -6 then
		return Game.GlobalTxt[399]
	elseif Rep > -25 then
		return Game.GlobalTxt[402]
	else
		return Game.GlobalTxt[434]
	end
end
NPCFollowers.GetRepName = GetRepName

local function PrepareBTBString(npc, text)

	local cNPC = Game.NPC[npc]
	local cPlayer = Party[math.max(Game.CurrentPlayer, 0)]
	local NPCExtra = mapvars.MapNPCNews[npc]
	local PlayerGender = Game.CharacterPortraits[cPlayer.Face].DefSex
	local PersSet = Game.NPCPersonalities[Game.NPCProf[cNPC.Profession].Personality]
	local ClassName = Game.ClassNames[cPlayer.Class]

	text = string.replace(text, "%01", cNPC.Name)
	text = string.replace(text, "%02", cPlayer.Name)
	text = string.replace(text, "%03", NPCExtra.Gender == "F" and Game.GlobalTxt[384] or Game.GlobalTxt[383])
	text = string.replace(text, "%04", tostring(Game.NPCProf[cNPC.Profession].Cost))
	text = string.replace(text, "%05", select(math.max(math.ceil(Game.Hour/8),1), Game.GlobalTxt[395], Game.GlobalTxt[396], Game.GlobalTxt[397]))
	text = string.replace(text, "%06", ClassName)
	text = string.replace(text, "%07", ClassName)
	text = string.replace(text, "%08", GetRepName())
	text = string.replace(text, "%09", PlayerGender == 1 and Game.GlobalTxt[384] or Game.GlobalTxt[383])
	text = string.replace(text, "%10", PlayerGender == 1 and Game.GlobalTxt[389] or Game.GlobalTxt[388])
	text = string.replace(text, "%11", GetRepName())
	text = string.replace(text, "%12", GetRepName(NPCExtra.Alignment == "E" and PersSet.ReqRep or -PersSet.ReqRep))
	text = string.replace(text, "%13", cPlayer.Name)
	text = string.replace(text, "%14", Game.NPCProfessions[cNPC.Profession])
	text = string.replace(text, "%15", cPlayer.Name)
	text = string.replace(text, "%16", cPlayer.Name)

	return text

end
NPCFollowers.PrepareBTBString = PrepareBTBString

local function PrepareGreet(npc, std)
	-- Avoid reprocessing greet
	if CurGreet then
		return
	end

	if not NPCFollowers.IsRandomNPC(npc) then
		CurGreet = std
		return
	end

	local NPCExtra = mapvars.MapNPCNews and mapvars.MapNPCNews[npc]
	if not NPCExtra then
		CurGreet = std
		return
	end

	local MonGroup = Map.Monsters[NPCExtra.Mid].Group
	local seen = NPCExtra.SeenGreet
	NPCExtra.SeenGreet = true

	if MonGroup > 0 then
		local NewsId = NPCFollowers.GetNPCGroupNews(MonGroup)
		if not (NewsId == 0 or Game.NPCNews[NewsId] == "") then
			CurGreet = Game.NPCNews[NewsId]
			return
		end
	end

	local cNPC = Game.NPC[npc]
	local cPlayer = Party[math.max(Game.CurrentPlayer, 0)]
	local PersSet = Game.NPCPersonalities[Game.NPCProf[cNPC.Profession].Personality]
	local cRep = NPCFollowers.GetPartyReputation()

	local Will, Why = NPCFollowers.NPCWillSpeak(npc)

	local Text

	if NPCExtra.ThreatSuccess == Game.DayOfMonth then
		Text = PersSet.ThreatRet

	elseif NPCExtra.BribeSuccess == Game.DayOfMonth then
		Text = PersSet.BribeRet

	elseif NPCFollowers.NPCInGroup(npc) or Will then
		if cRep <= -25 then
			Text = PersSet["RepSaintly" .. NPCExtra.Alignment]
		elseif cRep >= 25 then
			Text = PersSet["RepNotorious" .. NPCExtra.Alignment]
		else
			Text = PersSet["RepOk" .. (seen and "2" or "1")]
		end

	elseif Why then
		if Why == "LowRep" or Why == "Rep" then
			Text = PersSet[Why .. (seen and "2" or "1") .. NPCExtra.Alignment]
		else
			Text = PersSet["NoFame"]
		end
	else
		Text = PersSet["RepOk" .. (seen and "2" or "1")]
	end

	CurGreet = PrepareBTBString(npc, Text)

end

function events.DrawNPCGreeting(t)
	if Game.CurrentScreen ~= 13 then
		PrepareGreet(t.NPC, t.Text)
		t.Text = CurGreet
	end
end

function events.BeforeSaveGame()
	vars.RndNPCPersist = {}
	for k,v in pairs(vars.NPCFollowers) do
		if IsRandomNPC(v) then
			local cNPC = Game.NPC[v]
			vars.RndNPCPersist[v] = {Name = cNPC.Name, Prof = cNPC.Profession, Pic = cNPC.Pic}
		end
	end
end

function events.GameInitialized2()
	ProcessMapNewsTXT()
	ProcessProfNewsTXT()
	ProcessContinentNewsTXT()
	ProcessNamesTXT()
end
