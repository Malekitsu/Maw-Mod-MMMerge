local CCTimers = {}

vars.Quest_SavingGoobers = vars.Quest_SavingGoobers or {}

local QSet = vars.Quest_SavingGoobers
local QBase = vars.Quest_CrossContinents

local VerdantNPC = QBase.VerdantNPC
local Topics = string.split(Game.NPCText[2216], "#")
local TXT = {

-- Intro

Intro1 = Game.NPCText[2162],
Intro2 = Game.NPCText[2163],

-- Infused rod line:

InfusedRod	= Game.NPCText[2164],
InRodGiven	= Game.NPCText[2165],
InRodDone	= Game.NPCText[2166],
InRodQuest	= Game.NPCText[2167],

-- Guiding gem line:

GuidingGem	= Game.NPCText[2168],
GuGemGiven	= Game.NPCText[2169],
GuGemDone	= Game.NPCText[2170],
GuGemQuest	= Game.NPCText[2171],

-- Whisp wrappings line:

WhispWrappings 	= Game.NPCText[2172],
WhWraGiven 		= Game.NPCText[2173],
WhWraDone 		= Game.NPCText[2174],
WhWraQuest 		= Game.NPCText[2175],

-- Enchant the gem line:

EnchantTheGem 	= Game.NPCText[2176],
EnGemQuest 		= Game.NPCText[2177],
EnGemGiven 		= Game.NPCText[2178],
EnGemBringOne 	= Game.NPCText[2179],
EnGemDone 		= Game.NPCText[2180],

-- Enchant the rod line:

EnchantTheRod	= Game.NPCText[2181],
EnRodQuest		= Game.NPCText[2182],
EnRodGiven		= Game.NPCText[2183],
EnRodEnchant	= Game.NPCText[2184],
EnRodDone		= Game.NPCText[2185],

-- Attunement line

Attunement			= Game.NPCText[2186],
NotAttuneMight		= Game.NPCText[2187],
AttuneMight			= Game.NPCText[2188],
NotAttuneEndurance	= Game.NPCText[2189],
AttuneEndurance		= Game.NPCText[2190],
NotAttuneAccuracy	= Game.NPCText[2191],
AttuneAccuracy		= Game.NPCText[2192],
NotAttuneIntellect	= Game.NPCText[2193],
AttuneIntellect		= Game.NPCText[2194],
NotAttunePersonality= Game.NPCText[2195],
AttunePersonality	= Game.NPCText[2196],
NotAttuneLuck		= Game.NPCText[2197],
AttuneLuck			= Game.NPCText[2198],
AttuneQuest			= Game.NPCText[2199],

-- Activate the Telelocator line:

ActivateTheTele	= Game.NPCText[2200],
AcTelGiven		= Game.NPCText[2201],
AcTelLeft		= Game.NPCText[2202],
AcTelDone		= Game.NPCText[2203],
AcTelQuest		= Game.NPCText[2204],

-- Save the Goobers line:

SG_Activate			= Game.NPCText[2205],
SG_SaveTheGoobers	= Game.NPCText[2206],
SG_Given			= Game.NPCText[2207],
SG_Left				= Game.NPCText[2208],
SG_LeftAdd1			= Game.NPCText[2209],
SG_LeftAdd2			= Game.NPCText[2210],
SG_DoneSeq1			= Game.NPCText[2211],
SG_DoneSeq2			= Game.NPCText[2212],
SG_DoneSeq3			= Game.NPCText[2213],
SG_After			= Game.NPCText[2214],
SG_Quest			= Game.NPCText[2215]

}

----------------------------------

local Scenarios = {}
local function AddScenario(f)
	Scenarios[f] = false
end

local function InitScenarios()
	for f, v in pairs(Scenarios) do
		if not v then
			local r = f()
			Scenarios[f] = r == nil and true or r
		end
	end
end

----------------------------------
-- INTRO TOPICS

QSet.GotIntro = QSet.GotIntro or 0

AddScenario(function()

	if QSet.GotIntro >= 2 then
		return false
	end

	NPCTopic{
		Topic	= Topics[1], --"Other heroes"
		Name	= "SG_Intro",
		NPC		= VerdantNPC,
		Slot	= 2,
		Branch	= "",
		CanShow = function() return QBase.GotMainQuest and QSet.GotIntro < 2 and Party[0].Experience > 75000 end,
		Ungive	= function(t)
			QSet.GotIntro = QSet.GotIntro + 1
			Message(TXT["Intro" .. tostring(QSet.GotIntro)])
			t.Texts.Topic = Topics[2] --"Help the Goobers"
		end
	}

end)


----------------------------------
-- INFUSED ROD

AddScenario(function()

	if vars.Quests["SG_InfusedRod"] == "Done" then
		return false
	end

	Quest{
		Name	= "SG_InfusedRod",
		NPC		= VerdantNPC,
		Slot	= 2,
		Quest	= 460,
		Branch	= "",
		CanShow = function() return QBase.GotMainQuest and QSet.GotIntro >= 2 and vars.Quests["SG_InfusedRod"] ~= "Done" end,
		Texts = {

			Topic	= Topics[3], --"Telelocator"
			Give	= TXT.InfusedRod,

			TopicGiven = Topics[4], --"Infused metal rod"
			Undone	= TXT.InRodGiven,

			Done	= TXT.InRodDone,

			Quest	= TXT.InRodQuest
		},
		QuestItem	= 663,
		Exp			= 5000
	}

end)

----------------------------------
-- SMOOTH GEM

AddScenario(function()

	if vars.Quests["SG_SmoothGem"] == "Done" then
		return false
	end

	Quest{
		Name	= "SG_SmoothGem",
		NPC		= VerdantNPC,
		Slot	= 2,
		Quest	= 461,
		Branch	= "",
		CanShow = function() return vars.Quests["SG_InfusedRod"] == "Done" and vars.Quests["SG_SmoothGem"] ~= "Done" end,
		Texts = {

			Topic	= Topics[5], --"Guiding gem"
			Give	= TXT.GuidingGem,

			TopicGiven = Topics[5], --"Guiding gem"
			Undone	= TXT.GuGemGiven,

			Done	= TXT.GuGemDone,

			Quest	= TXT.GuGemQuest
		},
		QuestItem	= 664,
		Exp			= 5000
	}

end)

----------------------------------
-- WISP WRAPPINGS

AddScenario(function()

	if vars.Quests["SG_WispWrappings"] == "Done" then
		return false
	end

	Quest{
		Name	= "SG_WispWrappings",
		NPC		= VerdantNPC,
		Slot	= 2,
		Quest	= 462,
		Branch	= "",
		CanShow = function() return vars.Quests["SG_SmoothGem"] == "Done" and not (vars.Quests["SG_WispWrappings"] == "Done") end,
		Texts = {

			Topic	= Topics[6], --"Wisp wrappings"
			Give	= TXT.WhispWrappings,

			TopicGiven = Topics[6], --"Wisp wrappings"
			Undone	= TXT.WhWraGiven,

			Done	= TXT.WhWraDone,
			After	= TXT.WhWraDone,

			Quest	= TXT.WhWraQuest
		},
		QuestItem	= 665,
		Exp			= 5000
	}

end)

InitScenarios()

----------------------------------
-- ECNHANT THE *** BRANCH

NPCTopic{
	Name	= "SG_RodAndGems",
	NPC		= VerdantNPC,
	Slot	= 2,
	Branch	= "",
	CanShow = function() return vars.Quests["SG_WispWrappings"] == "Done" and not ((vars.Quests["SG_EnchantTheGem"] == "Done") and (vars.Quests["SG_EnchantTheRod"] == "Done")) end,
	Ungive	= function() QuestBranch("WispAndGems") end,
	Topic	= Topics[7], --"Telelocator parts"
	Text	= ""
}

NPCTopic{NPC = VerdantNPC, Branch = "WispAndGems", Slot = 0, Topic = ""}
NPCTopic{NPC = VerdantNPC, Branch = "WispAndGems", Slot = 1, Topic = ""}
NPCTopic{NPC = VerdantNPC, Branch = "WispAndGems", Slot = 2, Topic = ""}
NPCTopic{NPC = VerdantNPC, Branch = "WispAndGems", Slot = 3, Topic = ""}

----------------------------------
-- ECNHANT THE GEM

local GemsNeedStr
local GemsNeed = {	Game.ItemsTxt[177].Name, Game.ItemsTxt[178].Name, Game.ItemsTxt[179].Name, Game.ItemsTxt[180].Name, Game.ItemsTxt[181].Name,
					Game.ItemsTxt[182].Name, Game.ItemsTxt[183].Name, Game.ItemsTxt[184].Name, Game.ItemsTxt[185].Name, Game.ItemsTxt[186].Name}

TXT.EnchantTheGem	= TXT.EnchantTheGem:format(table.concat(GemsNeed, Game.NPCText[2704])) -- ", "
TXT.EnGemQuest		= TXT.EnGemQuest:format(table.concat(GemsNeed, Game.NPCText[2704])) -- ", "

QSet.GemsLeftNums = QSet.GemsLeftNums or {[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[9]=true,[10]=true}

local function CheckGems()

	local Done = table.find(QSet.GemsLeftNums, true) == nil

	if Done then
		Message(TXT.EnGemDone)
		QuestBranch("")
		return true
	end

	local function MakeGemStr()
		local tmpT = {}
		for k,v in pairs(QSet.GemsLeftNums) do
			if v then
				table.insert(tmpT, GemsNeed[k])
			end
		end
		GemsNeedStr = table.concat(tmpT, Game.NPCText[2704]) -- ", "
		return GemsNeedStr
	end

	for iP, Player in Party do
		for i,v in Player.Items do
			local ItemTxt = Game.ItemsTxt[v.Number]
			if ItemTxt.EquipStat == 19 then
				local Gem = table.find(GemsNeed, ItemTxt.Name)
				if Gem and QSet.GemsLeftNums[Gem] then
					QSet.GemsLeftNums[Gem] = false
					evt[iP].Subtract{"Inventory", v.Number}

					if table.find(QSet.GemsLeftNums, true) then
						Message(TXT.EnGemBringOne:format(ItemTxt.Name, MakeGemStr()))
					else
						Message(string.format(Game.NPCText[2707], ItemTxt.Name)) -- "Well, this is %s."
					end
					return false
				end
			end
		end
	end

	Message(TXT.EnGemGiven .. "\n" .. Game.NPCText[2705] .. MakeGemStr() .. Game.NPCText[2706]) -- "(" .. MakeGemStr() .. ")"
	return false
end

Quest{
	Name	= "SG_EnchantTheGem",
	NPC		= VerdantNPC,
	Branch	= "WispAndGems",
	Slot	= 0,
	Quest	= 463,
	CheckDone = CheckGems,
	Texts = {
		Topic	= Topics[8], --"Enchant the Gem"
		Give	= TXT.EnchantTheGem,
		After	= TXT.EnGemDone,
		Quest	= TXT.EnGemQuest
	},
	Exp = 5000
}

----------------------------------
-- ECNHANT THE ROD

QSet.EnRodMapsVisited = QSet.EnRodMapsVisited or {}

function events.AfterLoadMap()
	local MId = Map.MapStatsIndex
	if 	MId >= 9 and MId <= 12
		and vars.Quests["SG_EnchantTheRod"]
		and vars.Quests["SG_EnchantTheRod"] ~= "Done"
		and not QSet.EnRodMapsVisited[MId] then

		QSet.EnRodMapsVisited[MId] = true
		evt.Add{"Experience", 0}
		Game.ShowStatusText(TXT.EnRodEnchant:format(Game.MapStats[MId].Name))

	end
end

Quest{
	Name	= "SG_EnchantTheRod",
	NPC		= VerdantNPC,
	Branch	= "WispAndGems",
	Slot	= 1,
	Quest	= 464,
	CheckDone = function()
		for i = 9, 12 do
			local Set = QSet.EnRodMapsVisited
			if not Set[i] then
				return false
			end
		end
		QuestBranch("")
		return true
	end,
	Texts = {

		Topic	= Topics[9], --"Enchant the Rod"
		Give	= TXT.EnchantTheRod,

		TopicGiven = Topics[9], --"Enchant the Rod"
		Undone	= TXT.EnRodGiven,

		Done	= TXT.EnRodDone,

		Quest	= TXT.EnRodQuest
	},
	Exp	= 5000
}

----------------------------------
-- ATTUNEMENT BRANCH

QSet.Attuned = QSet.Attuned or {[6] = true}
local StatsToCheck	= {"Might", "Intellect", "Personality", "Endurance", "Accuracy", "Luck"}
local AttuneEffects	= {"Weak", "Insane", "Cursed", "DiseasedGreen", "Asleep", "Afraid", "Drunk"} -- Might, Intellect, Personality, Endurance, Accuracy, Speed, Luck

local function AttuneStat(Stat)
	local PlayerStat = Party[Game.CurrentPlayer].Stats[Stat]
	local CurStatName = table.find(const.Stats, Stat)

	if (PlayerStat.Base + PlayerStat.Bonus)  > 70 then
		PlayerStat.Base = PlayerStat.Base + (Stat == const.Stats.Luck and 10 or -10)
		evt[Game.CurrentPlayer].Set{AttuneEffects[Stat+1] or "Weak", 1}
		QSet.Attuned[Stat + 1] = true

		Message(TXT["Attune" .. CurStatName])

		return true
	end

	Message(TXT["NotAttune" .. CurStatName])

	QSet.Attuned[Stat + 1] = false
	return false
end

NPCTopic{NPC = VerdantNPC, Branch = "Attunement", Slot = 0, Topic = ""}
NPCTopic{NPC = VerdantNPC, Branch = "Attunement", Slot = 1, Topic = ""}
NPCTopic{NPC = VerdantNPC, Branch = "Attunement", Slot = 2, Topic = ""}

Quest{
	Name	= "SG_Attunement",
	NPC		= VerdantNPC,
	Slot	= 2,
	Quest	= 465,
	Branch	= "",
	CanShow = function() return not QSet.TeleAttuned and (vars.Quests["SG_EnchantTheGem"] == "Done") and (vars.Quests["SG_EnchantTheRod"] == "Done") end,
	CheckDone = function()
		local result = true
		for i = 1, 7 do
			local Set = QSet.Attuned
			if not Set[i] then
				result = false
				break
			end
		end
		if not result then
			QuestBranch("Attunement")
		end
		QSet.TeleAttuned = result
		return result
	end,
	Texts = {

		Topic	= Topics[10], --"Attune the Telelocator"
		Give	= TXT.Attunement,

		TopicGiven = Topics[10], --"Attune the Telelocator"
		Undone	= TXT.Attunement,

 		Done	= Game.NPCText[2708],
 		Quest	= TXT.AttuneQuest
	},
	Exp	= 10000
}

local statNameGlobalTxtNumbers = {144, 116, 163, 75, 1, 136} -- "Might", "Intellect", "Personality", "Endurance", "Accuracy", "Luck"
for i,v in ipairs(StatsToCheck) do

	NPCTopic{
		Topic	= Topics[11] .. Game.GlobalTxt[statNameGlobalTxtNumbers[i]], --"Attune "
		Name	= "SG_Attune_" .. v,
		NPC		= VerdantNPC,
		Slot	= i < 4 and i-1 or i-4,
		Branch	= "Attunement",
		CanShow = function() return not QSet.Attuned[const.Stats[v] + 1] end,
		Ungive	= function() AttuneStat(const.Stats[v]) end
	}

end
CurSlot = nil

----------------------------------
-- ACTIVATE THE TELELOCATOR

QSet.PhilStonesLeft = QSet.PhilStonesLeft or 1

Quest{
	Name	= "SG_ActivateTheTele",
	NPC		= VerdantNPC,
	Slot	= 2,
	Quest	= 466,
	CanShow = function() return vars.Quests["SG_Attunement"] == "Done" and not (vars.Quests["SG_ActivateTheTele"] == "Done") end,
	CheckDone = function()
		local Taken = false
		while TakeItemFromParty(219) or TakeItemFromParty(1021) and QSet.PhilStonesLeft > 0 do
			QSet.PhilStonesLeft = QSet.PhilStonesLeft - 1
			Taken = true
		end

		if QSet.PhilStonesLeft > 0 then
			if Taken then
				Message(TXT.AcTelLeft:format(tostring(QSet.PhilStonesLeft)))
			else
				Message(TXT.AcTelGiven)
			end
		else
			return true
		end
	end,
	Texts = {
		Topic	= Topics[12], --"Activate the Telelocator"
		Give	= TXT.ActivateTheTele,
		Done	= TXT.AcTelDone,
		Quest	= TXT.AcTelQuest
	},
	Exp	= 5000
}

----------------------------------
-- SAVE THE GOOBERS!

local TeleItemId = 666
local TeleNPCId  = 968

Quest{
	Name	= "SG_Activate!",
	NPC		= VerdantNPC,
	Slot	= 2,
	CanShow = function() return vars.Quests["SG_ActivateTheTele"] == "Done" and not QSet.GotFinalPart end,
	Ungive	= function() QSet.GotFinalPart = true end,
	Texts = {
		Topic	= Topics[13], --"Activate!"
		Ungive	= TXT.SG_Activate,
	},

}

QSet.ItemsForFinalLeft = QSet.ItemsForFinalLeft or {
[207]	= 5,
[201]	= 5,
[204]	= 1,
[1004]	= 1,
[202]	= 1,
[1006]	= 2,
[146]	= 1
}

local function CheckItemsForFinal()
	local CurM = TXT.SG_Given
	local TakenId, Taken
	local ItemsLeft
	local Done = true

	for k,v in pairs(QSet.ItemsForFinalLeft) do
		if v > 0 and TakeItemFromParty(k) then
			local res = v - 1
			QSet.ItemsForFinalLeft[k] = res
			CurM = TXT.SG_Left:format(Game.ItemsTxt[k].Name)
			if res > 0 then
				CurM = CurM .. TXT.SG_LeftAdd1:format(tostring(res))
			end
			Taken = true
			TakenId = k
			break
		end
	end

	if Taken then
		ItemsLeft = {}
	end
	for k,v in pairs(QSet.ItemsForFinalLeft) do
		if v > 0 and k ~= TakenId then
			Done = false
			if Taken then
				table.insert(ItemsLeft, Game.ItemsTxt[k].Name .. " - " .. tostring(v))
			end
		end
	end

	if not Done then
		if Taken and #ItemsLeft > 0 then
			CurM = CurM .. TXT.SG_LeftAdd2:format(table.concat(ItemsLeft, ", ")) .. "."
		end
		Message(CurM)
	end

	return Done
end

Quest{
	Name	= "SG_SaveTheGoobers",
	NPC		= VerdantNPC,
	Slot	= 2,
	Quest	= 467,
	Branch	= "",
	Done	= function(t)
		QSet.SeenDoneSeq1 = true
		t.Texts.TopicDone = Topics[15] --"Mix the potion"
	end,
	After	= function(t)
			if not QSet.SeenDoneSeq2 then
				QSet.SeenDoneSeq2 = true
				t.Texts.TopicDone = Topics[16] --"...",
				Message(TXT.SG_DoneSeq2)
			elseif not QSet.SeenDoneSeq3 then
				QSet.SeenDoneSeq3 = true
				t.Texts.TopicDone = Topics[17] --"Dimensionally displaced goobers",
				evt.All.Add{"Experience", 0}
				Message(TXT.SG_DoneSeq3)
			else
				if not QSet.GotTelelocator then
					QSet.GotTelelocator = true
					evt[0].Add{"Inventory", TeleItemId}
					vars.LostItems[TeleItemId] = math.min(TownPortalControls.GetCurrentSwitch(), 3)
				end
				Message(TXT.SG_After)
			end
	end,
	CanShow = function() return QSet.GotFinalPart end,
	CheckDone = CheckItemsForFinal,
	Texts = {

		Topic	= Topics[14], --"Save the Goobers!"
		Give	= TXT.SG_SaveTheGoobers,
		Done	= TXT.SG_DoneSeq1,

		TopicDone = Topics[17], --"Dimensionally displaced goobers"

		Quest	= TXT.SG_Quest
	},
	Exp	= 15000
}

----------------------------------
-- Reward: Telelocator

QSet.TeleCharged = QSet.TeleCharged == nil and true or QSet.TeleCharged

Game.NPC[TeleNPCId].Pic  = 34
Game.NPC[TeleNPCId].Name = "Telelocator"

local function CanShowTeleTopicsStd1()
	return not QSet.TeleCharged
end

local function CanShowTeleTopicsStd2()
	return QSet.TeleCharged
end

NPCTopic{NPC = TeleNPCId, Branch = "", Slot = 0, Topic = "", CanShow = CanShowTeleTopicsStd1}
NPCTopic{NPC = TeleNPCId, Branch = "", Slot = 2, Topic = "", CanShow = CanShowTeleTopicsStd1}
NPCTopic{
	Topic	= "Charge telelocator",
	NPC		= TeleNPCId,
	Slot	= 1,
	Branch	= "",
	Name	= "SG_Tele_Charge",
	CanShow	= CanShowTeleTopicsStd1,
	Ungive	= function()
		if TakeItemFromParty(219) or TakeItemFromParty(1021) then
			QSet.TeleCharged = true
			Message("Charged. Insert request.")
		else
			Message("*You don't have any philosopher stone to charge the telelocator.*")
		end
	end
}

vars.LastItemLocation = vars.LastItemLocation or {}

local function RecordItems()
	for _, ch in Map.Chests do
		for i, v in ch.Items do
			vars.LastItemLocation[v.Number] = Map.MapStatsIndex
		end
	end

	for _, mon in Map.Monsters do
		vars.LastItemLocation[mon.Item] = Map.MapStatsIndex
		for i, v in mon.Items do
			vars.LastItemLocation[v.Number] = Map.MapStatsIndex
		end
	end

	for i, v in Map.Objects do
		vars.LastItemLocation[v.Item.Number] = Map.MapStatsIndex
	end
end

function events.LeaveMap(t)
	RecordItems()
end

function events.AfterLoadMap()
	if Map.Refilled then
		local flush = {}
		for i, v in pairs(vars.LastItemLocation) do
			if v == Map.MapStatsIndex then
				table.insert(flush, i)
			end
		end
		for _, v in pairs(flush) do
			vars.LastItemLocation[v] = nil
		end
	end
end

function events.GotItem(i)
	local cur = vars.LastItemLocation[i]
	if cur and cur == Map.MapStatsIndex then
		vars.LastItemLocation[i] = nil
	end
end

local function TelelocateItem()

	local Answer, Found, FoundId
	Answer = Question("Enter the data.")

	if string.len(Answer) < 3 then
		Message("Re-record: enter the data.")
		return
	end

	local ItemsMatch = {}
	for i = 0, Game.ItemsTxt.count - 1 do
		local v = Game.ItemsTxt[i]
		if string.find(v.Name, Answer) then
			ItemsMatch[i] = v
		end
	end

	if not next(ItemsMatch) then
		Message("Re-record: unable to locate.")
		return
	end

	for k,v in pairs(ItemsMatch) do
		if vars.LostItems[k] and not TakeItemFromParty(k, true) then
			evt[0].Add{"Inventory", k}
			QSet.TeleCharged = false
			return
		end
	end

	local MapsExtra	= Game.Bolster.Maps
	local FString	= "%s. World: Enroth. Realm: %s. Landmark: %s. Year: %s."
	local Messages = {}
	for i, v in pairs(ItemsMatch) do
		local MapId = vars.LastItemLocation[i]
		if MapId then
			local str = FString:format(
				v.Name,
				select(MapsExtra[MapId].Continent, "Jadame", "Antagarich", "Enroth"),
				Game.MapStats[MapId].Name,
				tostring(Game.Year))

			table.insert(Messages, str)
		end
	end

	if #Messages == 0 then
		Message("Re-record: unable to locate.")
		return
	end

	CurMes = "Targets found. Realms: Attuned. Time: Attuned.\n\n" .. table.concat(Messages, "\n") .. "\n\nRealms: Detached. Time: Detached."
	QSet.TeleCharged = false
	Message(CurMes)

end

local function TelelocateNPC()

	local Answer, Found, FoundId
	Answer = Question("Enter the data.")

	if string.len(Answer) < 3 then
		Message("Re-record: enter the data.")
		return
	end

	for i,v in Game.NPC do
		if string.find(v.Name, Answer) then
			Found, FoundId = v, i
			break
		end
	end

	if not FoundId or Found.House == 0 then
		Message("Re-record: unable to locate.")
		return
	end

	local MapsExtra	= Game.Bolster.Maps
	local FString	= "%s. World: Enroth. Realm: %s. Landmark: %s. Year: %s\nTargets' status: in %s.\n"
	local HouseMap	= Game.HousesExtra[Found.House].Map
	local HouseCont	= MapsExtra[HouseMap].Continent
	local CurHouse	= Game.Houses[Found.House]

	CurMes =
		FString:format(
			Found.Name,
			select(HouseCont, "Jadame", "Antagarich", "Enroth"),
			Game.MapStats[HouseMap].Name,
			tostring(Game.Year),
			CurHouse.Name)

	CurMes = "Targets found. Realms: Attuned. Time: Attuned.\n\n" .. CurMes .. "\nRealms: Detached. Time: Detached."
	QSet.TeleCharged = false
	Message(CurMes)

end

vars.LastMonsterLocation = vars.LastMonsterLocation or {}

function events.LeaveMap()
	for i, v in Map.Monsters do
		if v.HP > 0 and v.AIState ~= const.AIState.Removed and v.AIState ~= const.AIState.Invisible then
			vars.LastMonsterLocation[v.Id] = Map.MapStatsIndex
		end
	end
end

local function TelelocateMon()

	local Answer, Found, FoundId
	Answer = Question("Enter the data.")

	if string.len(Answer) < 3 then
		Message("Re-record: enter the data.")
		return
	end

	for i,v in Game.MonstersTxt do
		if string.find(v.Name, Answer) then
			Found, FoundId = v,i
			break
		end
	end

	if not Found or not vars.LastMonsterLocation[FoundId] then
		Message("Re-record: unable to locate.")
		return
	end

	local MonMap = vars.LastMonsterLocation[FoundId]
	local MapsExtra	= Game.Bolster.Maps
	local FString	= "World: Enroth. Realm: %s. Landmark: %s. Year: %s\nTargets' status: %s, type: %s, state: %s.\n"
	local MonCont	= MapsExtra[MonMap].Continent

	CurMes =
		FString:format(
			select(MonCont, "Jadame", "Antagarich", "Enroth"),
			Game.MapStats[MonMap].Name,
			tostring(Game.Year),
			Found.Name,
			table.find(const.Bolster.MonsterType, Game.Bolster.Monsters[FoundId].Type) or "Unknown",
			select(Game.HostileTxt[math.ceil(FoundId/3)][0] + 1, "Peaceful", "Wimpy", "Rude", "Agressive",	"Berserk") or "Unknown")

	CurMes = "Targets found. Realms: Attuned. Time: Attuned.\n\n" .. CurMes .. "\nRealms: Detached. Time: Detached."
	QSet.TeleCharged = false
	Message(CurMes)

end


NPCTopic{
	Topic	= "Locate item",
	NPC		= TeleNPCId,
	Slot	= 0,
	Branch	= "",
	Name	= "SG_Tele_Item",
	CanShow	= CanShowTeleTopicsStd2,
	Ungive	= TelelocateItem
}

NPCTopic{
	Topic	= "Locate person",
	NPC		= TeleNPCId,
	Slot	= 1,
	Branch	= "",
	Name	= "SG_Tele_Person",
	CanShow	= CanShowTeleTopicsStd2,
	Ungive	= TelelocateNPC
}

NPCTopic{
	Topic	= "Locate monster",
	NPC		= TeleNPCId,
	Slot	= 2,
	Branch	= "",
	Name	= "SG_Tele_Monster",
	CanShow	= CanShowTeleTopicsStd2,
	Ungive	= TelelocateMon
}

evt.UseItemEffects[TeleItemId] = function(Target)

	if Game.CurrentScreen == 13 then
		return 3
	elseif Party.EnemyDetectorRed or Party.EnemyDetectorYellow then
		evt.PlaySound{142}
		Game.ShowStatusText(Game.GlobalTxt[480])
		return 0
	end

	while Game.CurrentScreen ~= 0 do
		ExitCurrentScreen(false, true)
	end

	evt.FaceAnimation{5, 37}
	evt.SpeakNPC{TeleNPCId}
	return 0

end
