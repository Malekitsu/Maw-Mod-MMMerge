----------------------------------------
-- Loretta Fleise's fix prices quest
-- used in: outb1.lua, outb2.lua, outc1.lua, outc2.lua, outc3.lua, outd1.lua, outd3.lua, oute3.lua

StdQuestsFunctions = {}

local function IsWorkTime(House)
	local CH = Game.Houses[House]
	if CH.CloseHour > CH.OpenHour then
		return Game.Hour >= CH.OpenHour and Game.Hour < CH.CloseHour
	elseif CH.CloseHour < CH.OpenHour then
		return Game.Hour >= CH.OpenHour or Game.Hour < CH.CloseHour
	else
		return true
	end
end

local function VisitedStablesHint()
	local HintLines = {
		[1515] = Game.MapStats[140].Name,
		[1516] = Game.MapStats[141].Name,
		[1517] = Game.MapStats[143].Name,
		[1518] = Game.MapStats[144].Name,
		[1519] = Game.MapStats[144].Name,
		[1520] = Game.MapStats[145].Name,
		[1521] = Game.MapStats[146].Name,
		[1522] = Game.MapStats[148].Name,
		[1523] = Game.MapStats[151].Name
	}

	local Hints = {}
	for k,v in pairs(HintLines) do
		if not Party.QBits[k] then
			table.insert(Hints, v)
		end
	end
	return Game.NPCText[2705] .. table.concat(Hints, Game.NPCText[2704]) .. Game.NPCText[2706] -- "(" .. ", " .. ")"
end

local function CheckPrices(House, Bit)
	if Party.QBits[1140] and not Party.QBits[Bit] and IsWorkTime(House) then
		Message(Game.NPCText[1828])
		Party.QBits[Bit] = true
		for i = 1515, 1523 do
			if not Party.QBits[i] then
				return
			end
		end
		evt.Add{"Experience", 1}
		Party.QBits[1141] = true
	else
		evt.EnterHouse{House}
	end
end
StdQuestsFunctions.CheckPrices = CheckPrices

evt.Global[1393] = function()
	if not Party.QBits[1141] then
		Message(Game.NPCText[1787] .. VisitedStablesHint())
	end
end

----------------------------------------
-- Silvertongue's quest
-- used in outc2.lua

evt.Global[1693] = function()
	if Party.QBits[1192] then
		evt.ShowMovie{0, 0, "citytrtr"}
		RefreshHouseMapExit(209)
		ExitCurrentScreen(true)
	end
end

----------------------------------------
-- Subtract reputation in Temples of Baa
--

function events.ClickShopTopic(t)
	local valC = Game.Houses[GetCurrentHouse()].C
	if t.Topic == const.ShopTopics.Donate and (valC == 1 or valC == 3) and NPCFollowers.GetPartyReputation() < 9 then
		evt.Add{"Reputation", 2}
	end
end

----------------------------------------
-- Dragon towers
--

local function DragonTower(x,y,z,QBit)
	if not Party.QBits[QBit] and Party.Flying
		and Party.SpellBuffs[const.PartyBuff.Invisibility].ExpireTime < Game.Time then

		evt.CastSpell{6, 2, 5, x, y, z, 0, 0, 0}
	end
end
StdQuestsFunctions.DragonTower = DragonTower

local function SetTextureOutdoors(Model, Facet, Texture)
	CurBitmap = Game.BitmapsLod:LoadBitmap(Texture)
	Game.BitmapsLod.Bitmaps[CurBitmap]:LoadBitmapPalette()
	Map.Models[Model].Facets[Facet].BitmapId = CurBitmap
end
StdQuestsFunctions.SetTextureOutdoors = SetTextureOutdoors

----------------------------------------
-- "Piligrimage" topic
--
local TmpBit = 1230
local Piligrimage = {
[0] = {Month = 415, Stat = 144,	Map = 147},
[1] = {Month = 416, Stat = 116,	Map = 150},
[2] = {Month = 417, Stat = 163,	Map = 146},
[3] = {Month = 418, Stat = 75, 	Map = 143},
[4] = {Month = 419, Stat = 1, 	Map = 144},
[5] = {Month = 420, Stat = 211, Map = 145},
[6] = {Month = 421, Stat = 136, Map = 151},
[7] = {Month = 422, Stat = 87,	Map = 140},
[8] = {Month = 423, Stat = 6,	Map = 148},
[9] = {Month = 424, Stat = 240,	Map = 140},
[10] = {Month = 425, Stat = 70,	Map = 149},
[11] = {Month = 426, Stat = 138,Map = 141}
}

local function GetPartyPiligrimage()
	if not vars.LastPiligrimage or vars.LastPiligrimage.Year ~= Game.Year then
		local LastPiligrimage = {}
		LastPiligrimage.Year = Game.Year
		LastPiligrimage.MonthlyQuestTaken = {}

		vars.LastPiligrimage = LastPiligrimage
	end

	return vars.LastPiligrimage
end

Game.GlobalEvtLines:RemoveEvent(1354)
evt.Global[1354] = function()
	local MonthlyPiligrimage = GetPartyPiligrimage().MonthlyQuestTaken
	local Set = Piligrimage[Game.Month]
	local Hint = string.format(Game.NPCText[1746], Game.GlobalTxt[Set.Month], Game.GlobalTxt[Set.Stat], Game.MapStats[Set.Map].Name)

	if Party.QBits[TmpBit] then
		Party.QBits[TmpBit] = MonthlyPiligrimage[Game.Month] or false
		if Party.QBits[TmpBit] then
			Message(Game.NPCText[1747])
		else
			Message(Hint)
			evt.Add{"Experience", 0}
		end
		MonthlyPiligrimage[Game.Month] = true
	else
		Message(Hint)
	end
end

----------------------------------------
-- MM6 "Bounty hunt" topic
--
evt.Global[1712] = function()
	Message(BountyHuntFunctions.SetCurrentHunt())
end

----------------------------------------
-- Malwick at Emerald Island
--
evt.Global[769] = function()
	Mouse.Item.Number = 947
	Mouse.Item.Identified = true
	Mouse.Item.MaxCharges = 30
	Mouse.Item.Charges = 30
end

evt.Global[513] = function()
	if not Party.QBits[761] then
		evt.SummonMonsters{3, 3, 5, Party.X, Party.Y, Party.Z + 400, 59}
		evt.SetMonGroupBit{59, const.MonsterBits.Hostile, true}
	end
end

evt.Global[514] = function()
	evt.SummonMonsters{3, 3, 5, Party.X, Party.Y, Party.Z + 400, 59}
	evt.SetMonGroupBit{59, const.MonsterBits.Hostile, true}
end

-- Cast off
Game.GlobalEvtLines:RemoveEvent(783)
evt.Global[783] = function()
	Party.QBits[528] = false
	evt.MoveNPC{340, 215}
	evt.SetNPCGreeting{340, 320}
	evt.SetNPCTopic{340, 3, 0}
	Game.Time = Game.Time + const.Week*2
	evt.MoveToMap {-17331, 12547, 465, 1024, 0, 0, 0, 0, "7out02.odm"}
end
----------------------------------------
-- Extended Arcomage wins
--
function events.ArcomageMatchEnd(t)

	local function CheckWin(Start, End, QBit)

		local ContWin = true
		for i = Start, End do
			if not vars.ArcomageWinsExtra[i] then
				ContWin = false
				break
			end
		end
		if ContWin then
			evt.Add{"QBits", QBit}
		end

	end

	if t.result == 1 then
		vars.ArcomageWinsExtra = vars.ArcomageWinsExtra or {}
		local IndexByType = Game.HousesExtra[t.House].IndexByType
		if not vars.ArcomageWinsExtra[IndexByType] then
			evt.ForPlayer(0)
			evt.Add{"Gold", Game.Houses[t.House].Val * 100}
			vars.ArcomageWinsExtra[IndexByType] = true
			if IndexByType < 12  then
				evt.Set{"AutonotesBits", 650 + IndexByType}
			elseif IndexByType > 12 and IndexByType < 26 then
				evt.Set{"AutonotesBits", 650 + IndexByType - 1}
			end
		end
		t.Handled = true

		CheckWin(1, 11, 174)
		CheckWin(13, 25, 750)

	end
end

----------------------------------------
-- Arcomage restriction at Antagarich
--
local ArcomageText = Game.NPCText[1690]
function events.ClickShopTopic(t)
	if t.Topic == const.ShopTopics.PlayArcomage
		and TownPortalControls.MapOfContinent(Map.MapStatsIndex) == 2
		and not evt.All.Cmp{"Inventory", 1453} then

		t.Handled = true
		Game.EscMessage(ArcomageText)
	end
end

----------------------------------------
-- Mercenary guilds
--
function events.DrawShopTopics(t)
	if t.HouseType == 18 then
		t.Handled = true
		t.NewTopics[1] = const.ShopTopics.Learn
	end
end

function events.DrawLearnTopics(t)
	if t.HouseType == 18 then
		t.Handled = true
		t.NewTopics[1] = const.LearnTopics.Unarmed
		t.NewTopics[2] = const.LearnTopics.Dodging
		t.NewTopics[3] = const.LearnTopics.Armsmaster
		t.NewTopics[4] = const.LearnTopics.DisarmTraps
	end
end

----------------------------------------
-- Guilds membership
--
local StdRefuse1 = Game.GlobalTxt[544]
local StdRefuse2 = Game.GlobalTxt[160]
local LastGuildJoinTopic = 0
local TextSet = false

function events.DrawLearnTopics(t)
	TownPortalControls.CheckSwitch()
	local CurCont = TownPortalControls.GetCurrentSwitch()

	if ((CurCont == 2 or CurCont == 3) and t.HouseType >= 5 and t.HouseType <= 15) and not (CurCont == 2 and (t.HouseType == 12 or t.HouseType == 13)) then

		if not vars.GuildMembership[t.HouseType] then
			t.NewTopics[1] = 0
			t.NewTopics[2] = 0
			t.NewTopics[3] = 0
			t.NewTopics[4] = 0
			t.Handled = true
		end

	end
end

function events.DrawShopTopics(t)

	TownPortalControls.CheckSwitch()
	local CurCont = TownPortalControls.GetCurrentSwitch()

	if CurCont == 2 and (t.HouseType == 12 or t.HouseType == 13) then
		return
	end

	if (CurCont == 2 or CurCont == 3) and t.HouseType >= 5 and t.HouseType <= 15 then

		vars.GuildMembership = vars.GuildMembership or {}

		if not vars.GuildMembership[t.HouseType] then
			Game.GlobalTxt[544] = Game.NPCText[122]
			Game.GlobalTxt[160] = Game.NPCText[122]
			TextSet = true

			t.NewTopics[1] = const.ShopTopics.Learn
			t.Handled = true

		else
			Game.GlobalTxt[544] = StdRefuse1
			Game.GlobalTxt[160] = StdRefuse2
			TextSet = false
		end

	elseif TextSet then
		Game.GlobalTxt[544] = StdRefuse1
		Game.GlobalTxt[160] = StdRefuse2
		TextSet = false
	end

end

function events.LeaveGame()
	Game.GlobalTxt[544] = StdRefuse1
	Game.GlobalTxt[160] = StdRefuse2
end

function events.ExitNPC()
	LastGuildJoinTopic = 0
end

local function JoinGuild(GuildType, Cost, Text, ABit, TopicId)

	if LastGuildJoinTopic ~= TopicId then
		LastGuildJoinTopic = TopicId
		Message(Game.NPCText[Text])
		return
	end

	vars.GuildMembership = vars.GuildMembership or {}

	if vars.GuildMembership[GuildType] then
		Message(Game.NPCText[124])	-- Already member of this guild.
	else
		if Party.Gold >= Cost then
			evt.Subtract{"Gold", Cost}
			evt.Add{"AutonotesBits", ABit}
			vars.GuildMembership[GuildType] = true
			Message(Game.NPCText[Text])
		else
			Message(Game.GlobalTxt[155]) -- Not enough gold.
		end
	end

	FirstClick = false

end

-- Antagarich

evt.Global[1150] = function(i) JoinGuild(14, 100, 1830, 564, i) end	-- Elements
evt.Global[1151] = function(i) JoinGuild(15, 100, 1039, 565, i) end	-- Self
evt.Global[1152] = function(i) JoinGuild(6, 50, 1040, 566, i) end		-- Air
evt.Global[1153] = function(i) JoinGuild(8, 50, 1041, 567, i) end		-- Earth
evt.Global[1154] = function(i) JoinGuild(5, 50, 1042, 568, i) end		-- Fire
evt.Global[1155] = function(i) JoinGuild(7, 50, 1043, 569, i) end		-- Water
evt.Global[1156] = function(i) JoinGuild(11, 50, 1044, 570, i) end		-- Body
evt.Global[1157] = function(i) JoinGuild(10, 50, 1045, 571, i) end		-- Mind
evt.Global[1158] = function(i) JoinGuild(9, 50, 1046, 572, i) end		-- Spirit
evt.Global[1159] = function(i) JoinGuild(12, 1000, 1047, 573, i) end	-- Light
evt.Global[1160] = function(i) JoinGuild(13, 1000, 1048, 574, i) end	-- Dark

-- Enroth

evt.Global[1694] = function(i) JoinGuild(14, 100, 1830, 564, i) end	-- Same order
evt.Global[1695] = function(i) JoinGuild(15, 100, 1039, 565, i) end
evt.Global[1702] = function(i) JoinGuild(6, 50, 1040, 566, i) end
evt.Global[1703] = function(i) JoinGuild(8, 50, 1041, 567, i) end
evt.Global[1704] = function(i) JoinGuild(5, 50, 1042, 568, i) end
evt.Global[1705] = function(i) JoinGuild(7, 50, 1043, 569, i) end
evt.Global[1706] = function(i) JoinGuild(11, 50, 1044, 570, i) end
evt.Global[1707] = function(i) JoinGuild(10, 50, 1045, 571, i) end
evt.Global[1708] = function(i) JoinGuild(9, 50, 1046, 572, i) end
evt.Global[1709] = function(i) JoinGuild(12, 1000, 1047, 573, i) end
evt.Global[1710] = function(i) JoinGuild(13, 1000, 1048, 574, i) end

if Multiplayer then
	function events.GatherPartySaveData(t)
		t.GuildMembership = vars.GuildMembership or {}
	end

	function events.ProcessPartySaveData(t)
		if t.GuildMembership then
			vars.GuildMembership = t.GuildMembership
		end
	end
end

----------------------------------------
-- Prevent divine intervention for spawn in shops before quest completed.
--

function events.GuildRefilled(Assortment)
	if Party.QBits[751] then
		return
	end

	for i,v in Assortment[7] do
		if v.Number == 487 then
			v.Number = math.random(477, 486)
		end
	end
end

----------------------------------------
-- Black potions topics
--

-- Cond = {
--[ReagentResult] = Count,
--...
--}
local function CheckReagentsConsistent(Cond, RemoveItems)

	local ItemsRemoval = {}

	for kR,vR in pairs(Cond) do

		local CurReags = {}
		for iIt,vIt in Game.ReagentSettings do
			if kR == vIt.Result then
				table.insert(CurReags, vIt.Item)
			end
		end

		local Count = 0
		for ip, Player in Party do
			for i,Item in Player.Items do
				if Count == vR then
					break
				end
				if table.find(CurReags, Item.Number) then
					Count = Count + 1
					table.insert(ItemsRemoval, Item)
				end
			end
		end

		if Count < vR then
			return false
		end

	end

	if RemoveItems then
		for k,v in pairs(ItemsRemoval) do
			v.Number = 0
		end
	end

	return true

end

local function GivePotionHuntReward(Reward, AQBit, RQBit, Experience)

	evt.ForPlayer("Current")

	if Reward then
		evt.Add{"Inventory", Reward}
	end
	if AQBit then
		evt.Add{"QBits", AQBit}
	end
	if RQBit then
		evt.Subtract{"QBits", RQBit}
	end
	if Experience then
		evt.ForPlayer("All").Add{"Experience", Experience}
	end

end

local function SetCheckPotQuestTopic(Qev, Cev)
	local cNPC = Game.NPC[GetCurrentNPC()]
	local TopicSet = false
	for i,v in cNPC.Events do
		if v == Qev then
			cNPC.Events[i] = TopicSet and 0 or Cev
			TopicSet = true
		end
	end
end

local function PotionHuntQuest(t)

	-- QuestTopic, CheckTopic, QBit, ABit, Reward, ExpReward, Requirments, NPC, DoneMsg, NotDoneMsg

	evt.Global[t.QuestTopic] = function() SetCheckPotQuestTopic(t.QuestTopic,t.CheckTopic) end

	Game.GlobalEvtLines:RemoveEvent(t.CheckTopic)
	evt.Global[t.CheckTopic] = function()
		if CheckReagentsConsistent(t.Requirments, true) then
			GivePotionHuntReward(t.Reward, t.ABit, t.QBit, t.ExpReward)
			Message(Game.NPCText[t.DoneMsg])

			local cEvents = Game.NPC[t.NPC].Events
			for i,v in cEvents do
				if v == t.QuestTopic or v == t.CheckTopic then
					cEvents[i] = 0
				end
			end
		else
			Message(Game.NPCText[t.NotDoneMsg])
		end
	end

end

PotionHuntQuest{
	QuestTopic	= 179,
	CheckTopic	= 181,
	ExpReward	= 5000,
	Requirments	= {[222] = 4, [223] = 2, [224] = 1},
	DoneMsg		= 626,
	NotDoneMsg	= 684,
	QBit	= 113,
	ABit	= 114,
	Reward	= 265,
	NPC		= 68
}

PotionHuntQuest{
	QuestTopic	= 201,
	CheckTopic	= 203,
	ExpReward	= 5000,
	Requirments	= {[222] = 2, [223] = 3, [224] = 3},
	DoneMsg		= 648,
	NotDoneMsg	= 684,
	QBit	= 115,
	ABit	= 116,
	Reward	= 264,
	NPC		= 74
}

PotionHuntQuest{
	QuestTopic	= 210,
	CheckTopic	= 212,
	ExpReward	= 5000,
	Requirments	= {[222] = 2, [223] = 4, [224] = 1},
	DoneMsg		= 626,
	NotDoneMsg	= 684,
	QBit	= 121,
	ABit	= 122,
	Reward	= 267,
	NPC		= 78
}

PotionHuntQuest{
	QuestTopic	= 232,
	CheckTopic	= 234,
	ExpReward	= 5000,
	Requirments	= {[222] = 1, [223] = 2, [224] = 4},
	DoneMsg		= 679,
	NotDoneMsg	= 684,
	QBit	= 123,
	ABit	= 124,
	Reward	= 266,
	NPC		= 83
}

PotionHuntQuest{
	QuestTopic	= 238,
	CheckTopic	= 240,
	ExpReward	= 5000,
	Requirments	= {[222] = 1, [223] = 4, [224] = 2},
	DoneMsg		= 685,
	NotDoneMsg	= 684,
	QBit	= 125,
	ABit	= 126,
	Reward	= 268,
	NPC		= 88
}

PotionHuntQuest{
	QuestTopic	= 244,
	CheckTopic	= 246,
	ExpReward	= 5000,
	Requirments	= {[222] = 2, [223] = 1, [224] = 4},
	DoneMsg		= 691,
	NotDoneMsg	= 684,
	QBit	= 133,
	ABit	= 134,
	Reward	= 269,
	NPC		= 77
}

----------------------------------------
-- Make item topics
--

-- Key - ItemId, Value - item strength
local OreItems = {
[691] = 6,
[690] = 5,
[689] = 4,
[688] = 3,
[687] = 2,
[686] = 1,
[1493] = 6,
[1492] = 5,
[1491] = 4,
[1490] = 3,
[1489] = 2,
[1488] = 1}

local function MakeOreItem(Type, MessageDone, MessageRefuse)
	if Type == 20 then
		Type = select(math.random(1,4), 1,1,2,3)
	end

	local Ore, Strength
	evt.ForPlayer("Current")

	for k,v in pairs(OreItems) do
		if evt.Cmp{"Inventory", k} then
			Ore = k
			Strength = v
			break
		end
	end

	if Ore then
		evt.Subtract{"Inventory", Ore}
		evt.GiveItem{Strength, Type, 0}

		Message(Game.NPCText[MessageDone])
	else
		Message(Game.NPCText[MessageRefuse])
	end
end

Game.GlobalEvtLines:RemoveEvent(501)
evt.Global[501] = function()	MakeOreItem(20, 1621, 1622) end

Game.GlobalEvtLines:RemoveEvent(502)
evt.Global[502] = function()	MakeOreItem(21, 1623, 1624) end

Game.GlobalEvtLines:RemoveEvent(503)
evt.Global[503] = function()	MakeOreItem(22, 1625, 1626) end

Game.GlobalEvtLines:RemoveEvent(594)
evt.Global[594] = function()	MakeOreItem(20, 534, 535) end

Game.GlobalEvtLines:RemoveEvent(595)
evt.Global[595] = function()	MakeOreItem(21, 536, 537) end

Game.GlobalEvtLines:RemoveEvent(596)
evt.Global[596] = function()	MakeOreItem(22, 538, 539) end

----------------------------------------
-- Circus topic
--
Game.GlobalEvtLines:RemoveEvent(1418)
evt.Global[1418] = function()
	local TotalPrize = 0
	local Costs = {[2090] = 1, [2091] = 3, [2097] = 5}
	for ip, Player in Party do
		for i,v in Player.Items do
			TotalPrize = TotalPrize + (Costs[v.Number] or 0)
		end
	end

	if TotalPrize >= 30 then
		evt.ForPlayer(0).Add{"Inventory", 2092}
		Message(Game.NPCText[1876])
	elseif TotalPrize >= 10 then
		evt.ForPlayer(0).Add{"Inventory", 2093}
		Message(Game.NPCText[1875])
	else
		Message(Game.NPCText[1874])
		return
	end

	evt.ForPlayer("All")
	for k,v in pairs(Costs) do
		while evt.Cmp{"Inventory", k} do
			evt.Subtract{"Inventory", k}
		end
	end

end

----------------------------------------
-- Circus prizes
--

local function TradeCircusPrize(ReqItem, RewardStrength, RewardType, YesTextId, NoTextId)
	if RewardType == 20 then
		RewardType = select(math.random(1,4), 1,1,2,3)
	end

	for i,v in Party do
		evt.ForPlayer(i)
		if evt.Cmp{"Inventory", ReqItem} then
			evt.Subtract{"Inventory", ReqItem}
			evt.GiveItem{RewardStrength, RewardType, 0}
			Message(Game.NPCText[YesTextId])
			return
		end
	end
	Message(Game.NPCText[NoTextId])
end

Game.GlobalEvtLines:RemoveEvent(1442)
evt.Global[1442] = function() TradeCircusPrize(2092, 6, 21, 2138, 2140) end

Game.GlobalEvtLines:RemoveEvent(1443)
evt.Global[1443] = function() TradeCircusPrize(2092, 6, 20, 2142, 2140) end

Game.GlobalEvtLines:RemoveEvent(1444)
evt.Global[1444] = function() TradeCircusPrize(2092, 6, 22, 2143, 2140) end

Game.GlobalEvtLines:RemoveEvent(1445)
evt.Global[1445] = function() TradeCircusPrize(2093, 4, 21, 2138, 2141) end

Game.GlobalEvtLines:RemoveEvent(1446)
evt.Global[1446] = function() TradeCircusPrize(2093, 4, 20, 2142, 2141) end

Game.GlobalEvtLines:RemoveEvent(1447)
evt.Global[1447] = function() TradeCircusPrize(2093, 4, 22, 2143, 2141) end

Game.GlobalEvtLines:RemoveEvent(1448)
evt.Global[1448] = function()
	for i,v in Party do
		evt.ForPlayer(i)
		if evt.Cmp{"Inventory", 2103} then
			evt.Subtract{"Inventory", 2103}
			evt.Add{"Inventory", select(math.random(1,6), 2056, 2065, 2064, 2063, 2059, 2062)}
			Message(Game.NPCText[2145])
			return
		end
	end
	Message(Game.NPCText[2144])
end

----------------------------------------
-- "Lost it" topic
--
vars.LostItems = vars.LostItems or {}

local LastGivenItems = {}
function events.LoadMapScripts()
	LastGivenItems = {}
end

local function IsQuestItem(i)
	if Game.ItemsTxt[i].Value > 0 then
		return false
	end
	if (i > 600 and i < 635) or i == 663 then
		return 1
	elseif (i > 1401 and i < 1488) or i == 664 then
		return 2
	elseif (i > 2066 and i < 2200) or i == 665 then
		return 3
	else
		return false
	end
end

function events.GotItem(i)
	local QuestNum = IsQuestItem(i)
	if QuestNum and not vars.LostItems[i] then
		vars.LostItems[i] = QuestNum
	end
end

local function LostItTopic()
	local CurCont = TownPortalControls.GetCurrentSwitch()
	for k,v in pairs(vars.LostItems) do
		if CurCont == v and not (LastGivenItems[k] or Mouse.Item.Number == k or evt.ForPlayer("All").Cmp{"Inventory", k}) then
			LastGivenItems[k] = true
			evt.ForPlayer(0).Add{"Inventory", k}
			Message(Game.NPCText[847])
			return
		end
	end
	Message(Game.NPCText[846])
end

evt.Global[1358]	= LostItTopic
evt.Global[889]		= LostItTopic
Game.NPC[314].EventA = 889

----------------------------------------
-- Remove MM7 endgame qbits.
--
evt.Global[920] = function()
	Party.QBits[642] = not Party.QBits[783]
end

evt.Global[922] = function()
	Party.QBits[783] = true
end

----------------------------------------
-- MM6-alike sell-item topics
--
local function RewardForItem(ItemId, RewardPerOne, HadItemText, DefaultText)
	local HadItem = false
	for i,v in Party do
		evt.ForPlayer(i)
		HadItem = evt.Cmp{"Inventory", ItemId}
		if HadItem then
			evt.Subtract{"Inventory", ItemId}
			evt.Add{"Gold", RewardPerOne}
			break
		end
	end

	if HadItem then
		Message(Game.NPCText[HadItemText])
	else
		Message(Game.NPCText[DefaultText])
	end
end

Game.GlobalEvtLines:RemoveEvent(1625)
evt.Global[1625] = function() RewardForItem(2094, 300, 2020, 2019) end

----------------------------------------
-- Make MM6 topics work with 5th character
--

local function MM6TradeItem(ABit, ItemId, Rewards, TextSold, TextNoItems)
	evt.Set{"AutonotesBits", ABit}
	for i,v in Party do
		evt.ForPlayer(i)
		if evt.Cmp{"Inventory", ItemId} then
			evt.Subtract{"Inventory", ItemId}
			for k,v in pairs(Rewards) do
				evt.Add{k, v}
			end
			Message(Game.NPCText[TextSold])
			return
		end
	end
	Message(Game.NPCText[TextNoItems])
end

Game.GlobalEvtLines:RemoveEvent(1426)
evt.Global[1426] = function()
	MM6TradeItem(461, 2082, {Gold = 2000}, 1883, 1882)
end

Game.GlobalEvtLines:RemoveEvent(1427)
evt.Global[1427] = function()
	MM6TradeItem(462, 2085, {Gold = 1000, Reputation = 5}, 1885, 1884)
end

Game.GlobalEvtLines:RemoveEvent(1428)
evt.Global[1428] = function()
	MM6TradeItem(463, 2090, {Gold = 5}, 1887, 1886)
end

Game.GlobalEvtLines:RemoveEvent(1429)
evt.Global[1429] = function()
	MM6TradeItem(464, 2091, {Gold = 10}, 1889, 1888)
end

Game.GlobalEvtLines:RemoveEvent(1430)
evt.Global[1430] = function()
	MM6TradeItem(465, 2092, {Gold = 1000}, 2085, 1890)
end

Game.GlobalEvtLines:RemoveEvent(1431)
evt.Global[1431] = function()
	MM6TradeItem(466, 2093, {Gold = 300}, 2087, 2086)
end

Game.GlobalEvtLines:RemoveEvent(1432)
evt.Global[1432] = function()
	MM6TradeItem(467, 2096, {Gold = 500}, 2089, 2088)
end

Game.GlobalEvtLines:RemoveEvent(1433)
evt.Global[1433] = function()
	MM6TradeItem(468, 2097, {Gold = 25}, 2096, 2090)
end

Game.GlobalEvtLines:RemoveEvent(1434)
evt.Global[1434] = function()
	MM6TradeItem(469, 2102, {Gold = 500}, 2098, 2097)
end

----------------------------------------
-- Make MM7 topics work with 5th character
--

local function KillParty()
	evt.All.Set{"Dead", 1}
end

evt.Global[876] = KillParty
evt.Global[879] = KillParty
evt.Global[883] = KillParty
evt.Global[886] = KillParty
