--------------------------------------------
---- Learn basic blaster (Tolberti, Robert the Wise)

Game.GlobalEvtLines:RemoveEvent(950)
Game.NPCTopic[950] = Game.GlobalTxt[278] -- Blaster
evt.Global[950] = function()
	local Noone = true
	for i, v in Party do
		if v.Skills[7] == 0 and Game.Classes.Skills[v.Class][7] > 0 then
			evt.ForPlayer(i).Set{"BlasterSkill", 1}
			Noone = false
		end
	end
end

--------------------------------------------
---- Base functions
local LichAppearance = {
[const.Race.Dwarf]		= {[0] = {Portrait = 65, Voice = 26}, [1] = {Portrait = 66, Voice = 27}},
[const.Race.Dragon]		= {[0] = {Portrait = 67, Voice = 28}, [1] = {Portrait = 67, Voice = 28}},
[const.Race.Minotaur]	= {[0] = {Portrait = 69, Voice = 67}, [1] = {Portrait = 69, Voice = 67}},
[const.Race.Troll]	= {[0] = {Portrait = 75, Voice = 72}, [1] = {Portrait = 75, Voice = 72}},
default					= {[0] = {Portrait = 26, Voice = 26}, [1] = {Portrait = 27, Voice = 27}}
}

local function SetLichAppearance()
	for i,v in Party do
		if v.Class == 45 then
			local CurPortrait = Game.CharacterPortraits[v.Face]
			local CurSex = CurPortrait.DefSex
			local Race = CurPortrait.Race

			if Race ~= const.Race.Undead then
				local NewFace = LichAppearance[Race] or LichAppearance.default
				NewFace = NewFace[CurSex]

				v.Face = NewFace.Portrait
				v.Voice = NewFace.Voice
				SetCharFace(i, NewFace.Portrait)
			end

			for i = 0, 3 do
				v.Resistances[i].Base = math.max(Party[0].Resistances[i].Base, 20)
			end
			v.Resistances[7].Base = 65000
			v.Resistances[8].Base = 65000

			local RepSkill = SplitSkill(v.Skills[26])
			if RepSkill > 0 then
				local CR = 0
				for i = 1, RepSkill do
					CR = CR + i
				end
				v.SkillPoints = v.SkillPoints + CR - 1
				v.Skills[10] = 0
			end
		end
	end
end

local function PromoteDarkMages() -- Promotion for dark Archmages.
	for i,Pl in Party do
		if Pl.Class == 47 and (evt[i].Cmp{"Inventory", 1417} or evt[i].Cmp{"Inventory", 628}) then
			if not evt[i].Subtract{"Inventory", 1417} then
				evt[i].Subtract{"Inventory", 628}
			end
			Pl.Class = 45
			evt[i].Add{"Experience", 0} -- Reward animation
		end
	end
	SetLichAppearance()
end

local function Promote(From, To, PromRewards, NonPromRewards, Gold, QBits, Awards)

	local Check

	if type(From) == "table" then
		Check = table.find
	else
		Check = function(v1, v2) return v1 == v2 end
	end

	for i,v in Party do
		if Check(From, v.Class) then
			evt.ForPlayer(i).Set{"ClassIs", To}
			if PromRewards then
				for k,v in pairs(PromRewards) do
					evt.ForPlayer(i).Add{k, v}
				end
			end
		elseif NonPromRewards then
			for k,v in pairs(NonPromRewards) do
				evt.ForPlayer(i).Add{k, v}
			end
		end
	end

	if GlobalRewards then
		for k,v in pairs(GlobalRewards) do
			evt.Add{k, v}
		end
	end

	if Gold then
		evt.Add{"Gold", Gold}
	end

	if QBits then
		for k,v in pairs(QBits) do
			evt.Add{"QBits", v}
		end
	end

	if Awards then
		for k,v in pairs(Awards) do
			evt.ForPlayer("All").Add{"Awards", v}
		end
	end

end

--[[
Promote2{
	From 	= ,
	To 		= ,
	PromRewards 	= {},
	NonPromRewards 	= {},
	Gold 	= ,
	QBits 	= {},
	Awards	= {},
	Reputation	 = ,
	TextIdFirst	 = ,
	TextIdSecond = ,
	TextIdRefuse = ,
	Condition	 = nil -- function() return true end
}
]]
local function Promote2(t)

	local Check

	if type(t.From) == "table" then
		Check = table.find
	else
		Check = function(v1, v2) return v1 == v2 end
	end

	local FirstTime = true
	for k,v in pairs(t.QBits) do
		if Party.QBits[v] then
			FirstTime = false
			break
		end
	end

	local CanPromote = not FirstTime or not t.Condition or t.Condition()

	if not CanPromote then
		Message(Game.NPCText[t.TextIdRefuse])
		return 0
	end

	if t.TextIdFirst then
		if FirstTime then
			Message(Game.NPCText[t.TextIdFirst])
		else
			Message(Game.NPCText[t.TextIdSecond or t.TextIdFirst])
		end
	end

	for i,v in Party do
		if Check(t.From, v.Class) then
			evt.ForPlayer(i).Set{"ClassIs", t.To}
			if t.PromRewards then
				for k,v in pairs(t.PromRewards) do
					evt.ForPlayer(i).Add{k, v}
				end
			end
		elseif FirstTime and t.NonPromRewards then
			for k,v in pairs(t.NonPromRewards) do
				evt.ForPlayer(i).Add{k, v}
			end
		end
	end

	if FirstTime then

		for k,v in pairs(t.QBits) do
			evt.Add{"QBits", v}
		end

		if t.Gold then
			evt.Add{"Gold", t.Gold}
		end

		if t.Reputation then
			evt.Add{"Reputation", t.Reputation}
		end

		if t.Awards then
			for k,v in pairs(t.Awards) do
				evt.ForPlayer("All").Add{"Awards", v}
			end
		end

	end

	return FirstTime and 1 or 2

end

local function CheckPromotionSide(ThisSideBit, OppSideBit, ThisText, OppText, ElseText)
	if Party.QBits[ThisSideBit] then
		Message(Game.NPCText[ThisText])
		return true
	elseif Party.QBits[OppSideBit] then
		Message(Game.NPCText[OppText])
	else
		Message(Game.NPCText[ElseText])
	end
	return false
end
--------------------------------------------
---- 		ENROTH PROMOTIONS			----
--------------------------------------------

--------------------------------------------
---- Enroth Knight promotion
-- First
Game.GlobalEvtLines:RemoveEvent(1382)
evt.Global[1382] = function()

	Message(Game.NPCText[1776])

	if Party.QBits[1643] or Party.QBits[1644] then
		Promote(16, 17, {Experience = 15000})
		if Party.QBits[1139] or Party.QBits[1645] then
			evt.SetNPCTopic{791, 2, 1384}
		end
	else
		Promote(16, 17,
				{Experience = 15000},
				{Experience = 15000},
				nil,
				{1643, 1644})

		evt.Subtract{"Reputation", 5}
		evt.Subtract{"QBits", 1138}
		evt.SetNPCTopic{791, 2, 1383}
		evt.SetNPCTopic{792, 0, 1380}
	end
end

-- Second
Game.GlobalEvtLines:RemoveEvent(1383)
evt.Global[1383] = function()
	Message(Game.NPCText[1777])
	evt.Add{"QBits", 1139}
	evt.SetNPCTopic{791, 2, 1384}
end

Game.GlobalEvtLines:RemoveEvent(1384)
evt.Global[1384] = function()

	if evt.ForPlayer("All").Cmp{"Inventory", 2128} then
		Message(Game.NPCText[1779])
		Promote(17, 19,
			{Experience = 30000},
			{Experience = 30000},
			nil,
			{1645, 1646})

		evt.Subtract{"Reputation", 10}
		evt.Subtract{"QBits", 1139}

		evt.ForPlayer("All").Subtract{"Inventory", 2128}
		evt.Subtract{"QBits", 1211}

	elseif Party.QBits[1645] or Party.QBits[1646] then
		Message(Game.NPCText[1812])
		Promote(17, 19, {Experience = 30000})

	else
		Message(Game.NPCText[1778])
	end

end

--------------------------------------------
---- Enroth Sorcerer promotion
-- First
Game.GlobalEvtLines:RemoveEvent(1371)
evt.Global[1371] = function()

	Message(Game.NPCText[1762])

	if Party.QBits[1639] or Party.QBits[1640] then
		Promote(42, 43, {Experience = 15000})
		if Party.QBits[1136] or Party.QBits[1641] then
			evt.SetNPCTopic{790, 2, 1373}
		end
	else
		Promote(42, 43,
				{Experience = 15000},
				{Experience = 15000},
				nil,
				{1639, 1640})

		evt.Subtract{"Reputation", 5}
		evt.Subtract{"QBits", 1135}
		evt.SetNPCTopic{790, 2, 1372}
	end

end

-- Second
Game.GlobalEvtLines:RemoveEvent(1372)
evt.Global[1372] = function()
	Message(Game.NPCText[1763])
	evt.Add{"QBits", 1136}
	evt.SetNPCTopic{790, 2, 1373}
end

Game.GlobalEvtLines:RemoveEvent(1373)
evt.Global[1373] = function()

	if evt.ForPlayer("All").Cmp{"Inventory", 2077} then
		Message(Game.NPCText[1765])
		Promote(43, 51,
			{Experience = 30000},
			{Experience = 30000},
			nil,
			{1641, 1642})

		evt.Subtract{"Reputation", 10}
		evt.Subtract{"QBits", 1136}

		evt.ForPlayer("All").Subtract{"Inventory", 2077}
		evt.Subtract{"QBits", 1210}

	elseif Party.QBits[1641] or Party.QBits[1642] then
		Message(Game.NPCText[1813])
		Promote(43, 51, {Experience = 30000})

	else
		Message(Game.NPCText[1764])
	end

end

--------------------------------------------
---- Enroth Archer promotion
-- First
Game.GlobalEvtLines:RemoveEvent(1405)
evt.Global[1405] = function()

	if Party.QBits[1655] or Party.QBits[1656] then
		Message(Game.NPCText[1803])
		Promote(0, 1, {Experience = 15000})
		if Party.QBits[1146] or Party.QBits[1657] then
			evt.SetNPCTopic{800, 2, 1413}
		end
	elseif evt.ForPlayer("All").Cmp{"Inventory", 2106} then
		Message(Game.NPCText[1803])
		Promote(0, 1,
			{Experience = 15000},
			{Experience = 15000},
			nil,
			{1655, 1656})

		evt.Subtract{"Reputation", 5}
		evt.Subtract{"QBits", 1145}

		evt.Subtract{"QBits", 1210}
		evt.SetNPCTopic{800, 2, 1406}

	else
		Message(Game.NPCText[1802])
	end

end

-- Second
Game.GlobalEvtLines:RemoveEvent(1406)
evt.Global[1406] = function()
	Message(Game.NPCText[1804])
	evt.Add{"QBits", 1146}
	evt.SetNPCTopic{800, 2, 1413}
end

Game.GlobalEvtLines:RemoveEvent(1413)
evt.Global[1413] = function()

	local TowerHints = {
		[1180] = Game.MapStats[151].Name,
		[1181] = Game.MapStats[150].Name,
		[1182] = Game.MapStats[146].Name,
		[1183] = Game.MapStats[144].Name,
		[1184] = Game.MapStats[141].Name,
		[1185] = Game.MapStats[143].Name
	}

	if Party.QBits[1657] or Party.QBits[1658] then
		Message(Game.NPCText[1808])
		Promote(1, 2, {Experience = 40000})

	elseif	Party.QBits[1180] and Party.QBits[1181] and Party.QBits[1182]
		and	Party.QBits[1183] and Party.QBits[1184] and Party.QBits[1185] then

		Message(Game.NPCText[1807])
		Promote(1, 2,
			{Experience = 40000},
			{Experience = 40000},
			nil,
			{1657, 1658})

		evt.Subtract{"Reputation", 10}
		evt.Subtract{"QBits", 1146}

		evt.ForPlayer("All").Subtract{"Inventory", 2077}
		evt.Subtract{"QBits", 1210}

	else

		if not evt.ForPlayer("All").Cmp{"Inventory", 2106} then
			evt.GiveItem{1, 0, 2106}
			Mouse.Item.Identified = true
			Mouse.Item.Bonus = 0
		end

		local HintLine, Hints = "", {}
		for Qbit, Line in pairs(TowerHints) do
			if not Party.QBits[Qbit] then
				table.insert(Hints, Line)
			end
			HintLine = Game.NPCText[2705] .. table.concat(Hints, Game.NPCText[2704]) .. Game.NPCText[2706] -- "(" .. ", " .. ")"
		end

		Message(Game.NPCText[1805] .. HintLine)
	end

end

--------------------------------------------
---- Enroth Cleric promotion
-- First
Game.GlobalEvtLines:RemoveEvent(1349)
evt.Global[1349] = function()

	if Party.QBits[1647] or Party.QBits[1648] then
		Message(Game.NPCText[1740])
		Promote(4, 5, {Experience = 15000})

		if Party.QBits[1131] or Party.QBits[1132] or Party.QBits[1649] or Party.QBits[1650] then
			evt.SetNPCTopic{801, 2, 1351}
		end

	elseif Party.QBits[1130] then
		Message(Game.NPCText[1740])
		Promote(4, 5,
				{Experience = 15000},
				{Experience = 15000},
				nil,
				{1647, 1648})

		evt.Subtract{"Reputation", 5}
		evt.Subtract{"QBits", 1129}

		evt.SetNPCTopic{801, 2, 1350}

	else
		Message(Game.NPCText[1739])
	end

end

-- Second
Game.GlobalEvtLines:RemoveEvent(1350)
evt.Global[1350] = function()
	Message(Game.NPCText[1741])
	evt.Add{"QBits", 1131}
	evt.SetNPCTopic{801, 2, 1351}
end

Game.GlobalEvtLines:RemoveEvent(1351)
evt.Global[1351] = function()

	if Party.QBits[1649] and Party.QBits[1650] then
		Message(Game.NPCText[1745])
		Promote(5, 50, {Experience = 30000})

	elseif Party.QBits[1132] then
		Message(Game.NPCText[1744])
		Promote(5, 50,
				{Experience = 30000},
				{Experience = 30000},
				nil,
				{1649, 1650})

		evt.Subtract{"Reputation", 10}
		evt.Subtract{"QBits", 1131}

	elseif evt.ForPlayer("All").Cmp{"Inventory", 2054} then
		Message(Game.NPCText[1743])

	else
		Message(Game.NPCText[1742])

	end

end

--------------------------------------------
---- Enroth Druid promotion
-- First
Game.GlobalEvtLines:RemoveEvent(1678)
evt.Global[1678] = function()
	Message(Game.NPCText[1792])
	if Party.QBits[1651] or Party.QBits[1652] then
		Promote(12, 13, {Experience = 15000})
		evt.Subtract{"QBits", 1142}
		if Party.QBits[1653] then
			evt.SetNPCTopic{799, 2, 1679}
		end
	else
		Promote(12, 13, {Experience = 15000}, {Experience = 15000}, nil, {1651, 1652})
		evt.Subtract{"QBits", 1142}
		evt.SetNPCTopic{799, 2, 1397}
		evt.SetNPCTopic{799, 1, 1678}
		evt.SetNPCTopic{1090, 0, 0}
	end
end

Game.GlobalEvtLines:RemoveEvent(1397)
evt.Global[1397] = function()
	Message(Game.NPCText[1793])
	evt.Add{"QBits", 1143}
	evt.SetNPCTopic{1090, 2, 1398}
end

-- Second
Game.GlobalEvtLines:RemoveEvent(1679)
evt.Global[1679] = function()
	if Party.QBits[1653] or Party.QBits[1654] then
		Message(Game.NPCText[1796])
		Promote(13, 15, {Experience = 40000})
	else
		Message(Game.NPCText[1794])
		Promote(13, 15, {Experience = 40000}, {Experience = 40000}, nil, {1653, 1654})
		evt.Add{"QBits", 1198}
		evt.Subtract{"QBits", 1143}
		evt.Subtract{"Reputation", 10}
		evt.SetNPCTopic{799, 1, 1678}
		evt.SetNPCTopic{799, 2, 1679}
		evt.SetNPCTopic{1090, 0, 0}
	end
end

--------------------------------------------
---- Enroth Paladin promotion
-- First
Game.GlobalEvtLines:RemoveEvent(1327)
evt.Global[1327] = function()

	if Party.QBits[1635] or Party.QBits[1636] then
		Message(Game.NPCText[1713])
		evt.Subtract{"QBits", 1112}
		Promote(26, 27, {Experience = 15000})
		NPCFollowers.Remove(796)
		if Party.QBits[1113] or Party.QBits[1637] then
			evt.SetNPCTopic{789, 3, 1329}
		end

	elseif Party.QBits[1699] then
		Message(Game.NPCText[1713])
		Promote(26, 27, {Experience = 15000}, {Experience = 15000}, 5000, {1635, 1636})
		evt.Subtract{"QBits", 1699}
		evt.Subtract{"QBits", 1112}
		evt.Subtract{"Reputation", 5}
		NPCFollowers.Remove(796)
		evt.SetNPCTopic{789, 3, 1328}

	else
		Message(Game.NPCText[1712])

	end
end
-- Second
Game.GlobalEvtLines:RemoveEvent(1328)
evt.Global[1328] = function()
	Message(Game.NPCText[1714])
	evt.Add{"QBits", 1113}
	evt.SetNPCTopic{789, 3, 1329}
end

Game.GlobalEvtLines:RemoveEvent(1329)
evt.Global[1329] = function()
	if Party.QBits[1637] or Party.QBits[1638] then
		Message(Game.NPCText[1717])
		Promote(27, 28, {Experience = 30000})

	elseif evt.ForPlayer("All").Cmp{"Inventory", 2075} then
		Message(Game.NPCText[1716])
		Promote(27, 28, {Experience = 30000}, {Experience = 30000}, nil, {1637, 1638})
		evt.Subtract{"Reputation", 10}
		evt.Subtract{"QBits", 1113}
		evt.Subtract{"Inventory", 2075}

	else
		Message(Game.NPCText[1715])

	end
end

--------------------------------------------
---- 		ANTAGARICH PROMOTIONS		----
--------------------------------------------

--------------------------------------------
---- Antagarich Archer promotion
-- First
Game.GlobalEvtLines:RemoveEvent(818)
evt.Global[818] = function()

	local result = Promote2{
		From 	= 0,
		To 		= 1,
		PromRewards 	= {Experience = 30000},
		NonPromRewards 	= {Experience = 15000},
		Gold 	= 7500,
		QBits 	= {1584, 1585},
		Awards	= nil,
		Reputation	 = -10,
		TextIdFirst	 = 1088,
		TextIdSecond = 1088,
		TextIdRefuse = 1089,
		Condition	 = function() return Party.QBits[570] end
	}

	if result == 1 then
		evt.Subtract{"QBits", 543}
		evt.SetNPCTopic{380, 1, 819}
	end

end

-- Second good
Game.GlobalEvtLines:RemoveEvent(819)
evt.Global[819] = function()
	if Party.QBits[612] then
		evt.SetNPCTopic{380, 1, 820}
		evt.Set{"QBits", 544}

		Message(Game.NPCText[1090])
	elseif Party.QBits[611] then
		Message(Game.NPCText[1092])
	else
		Message(Game.NPCText[1091])
	end
end
Game.GlobalEvtLines:RemoveEvent(816)
evt.Global[816] = function()

	local result = Promote2{
		From 	= 1,
		To 		= 2,
		PromRewards 	= {Experience = 80000},
		NonPromRewards 	= {Experience = 40000},
		Gold 	= nil,
		QBits 	= {1586, 1587},
		Awards	= nil,
		Reputation	 = -10,
		TextIdFirst	 = 1085,
		TextIdSecond = 1085,
		TextIdRefuse = 1086,
		Condition	 = function() return evt.ForPlayer("All").Cmp{"Inventory", 1344} end
	}

	if result == 1 then
		evt.ForPlayer(0).Add{"Inventory", 1345}
		evt.ForPlayer("All").Subtract{"Inventory", 1344}
		evt.SetNPCGreeting{379, 172}
		Party.QBits[542] = false
	end

end

-- Second evil
Game.GlobalEvtLines:RemoveEvent(820)
evt.Global[820] = function()

	local result = Promote2{
		From 	= 1,
		To 		= 3,
		PromRewards 	= {Experience = 80000},
		NonPromRewards 	= {Experience = 40000},
		Gold 	= nil,
		QBits 	= {1588, 1589},
		Awards	= nil,
		Reputation	 = 10,
		TextIdFirst	 = 1093,
		TextIdSecond = 1093,
		TextIdRefuse = 1094,
		Condition	 = function() return evt.ForPlayer("All").Cmp{"Inventory", 1344} end
	}

	if result == 1 then
		evt.ForPlayer(0).Add{"Inventory", 1345}
		evt.ForPlayer("All").Subtract{"Inventory", 1344}
		evt.SetNPCGreeting{380, 174}
		Party.QBits[544] = false
	elseif result == 0 then
		Party.QBits[544] = true
	end

end

--------------------------------------------
---- Antagarich Cleric promotion
-- First
Game.GlobalEvtLines:RemoveEvent(839)
evt.Global[839] = function()

	local result = Promote2{
		From 	= 4,
		To 		= 5,
		PromRewards 	= {Experience = 30000},
		NonPromRewards 	= {Experience = 15000},
		Gold 	= 5000,
		QBits 	= {1607, 1608},
		Awards	= nil,
		Reputation	 = -5,
		TextIdFirst	 = 1134,
		TextIdSecond = 1134,
		TextIdRefuse = 1135,
		Condition	 = function() return evt.ForPlayer("All").Cmp{"Inventory", 1485} end
	}

	if result == 1 then
		evt.ForPlayer("All").Subtract{"Inventory", 1485}
		evt.Subtract{"QBits", 730}
		evt.Set{"QBits", 576}
		evt.Subtract{"QBits", 555}
		evt.SetNPCTopic{386, 1, 840}
		evt.SetNPCTopic{386, 0, 839}
	elseif result == 2 then
		evt.Subtract{"QBits", 555}
	end

end

Game.GlobalEvtLines:RemoveEvent(836)
evt.Global[836] = function()
	if Party.QBits[1607] or Party.QBits[1608] then
		if Party.QBits[612] then
			Message(Game.NPCText[1130])
		elseif Party.QBits[611] then
			Message(Game.NPCText[1127])
			evt.Set{"QBits", 554}
			evt.SetNPCTopic{385, 0, 837}
		else
			Message(Game.NPCText[1128])
		end
	else
		Message(Game.NPCText[1129])
	end
end

Game.GlobalEvtLines:RemoveEvent(840)
evt.Global[840] = function()
	if Party.QBits[611] then
		Message(Game.NPCText[200])
	elseif Party.QBits[612] then
		Message(Game.NPCText[1136])
		evt.Set{"QBits", 556}
		evt.SetNPCTopic{386, 1, 841}
	else
		Message(Game.NPCText[1137])
	end
end

-- Second good
Game.GlobalEvtLines:RemoveEvent(837)
evt.Global[837] = function()
	if Party.QBits[1609] or Party.QBits[1610] then
		Message(Game.NPCText[1131])
		Promote(5, 6, {Experience = 80000})
		evt.Subtract{"QBits", 554}

	elseif Party.QBits[574] then
		Message(Game.NPCText[1131])
		Promote(5, 6, {Experience = 80000}, {Experience = 40000}, 10000, {1609, 1610})
		evt.ForPlayer("Current").Subtract{"Reputation", 10}
		evt.Subtract{"QBits", 554}
		evt.SetNPCGreeting{385, 188}

	else
		Message(Game.NPCText[1132])

	end
end

-- Second evil
Game.GlobalEvtLines:RemoveEvent(841)
evt.Global[841] = function()
	if Party.QBits[1611] or Party.QBits[1612] then
		Message(Game.NPCText[201])
		Promote(5, 7, {Experience = 80000})
		evt.Subtract{"QBits", 556}

	elseif Party.QBits[575] then
		Message(Game.NPCText[201])
		Promote(5, 7, {Experience = 80000}, {Experience = 40000}, 10000, {1611, 1612})
		evt.ForPlayer("All").Subtract{"Reputation", 10}
		evt.Subtract{"QBits", 556}
		evt.SetNPCGreeting{386, 190}

	else
		Message(Game.NPCText[1138])

	end
end

--------------------------------------------
---- Antagarich Druid promotion
-- First
Game.GlobalEvtLines:RemoveEvent(849)
evt.Global[849] = function()

	local result = Promote2{
		From 	= 12,
		To 		= 13,
		PromRewards 	= {Experience = 30000},
		NonPromRewards 	= {Experience = 15000},
		Gold 	= nil,
		QBits 	= {1613, 1614},
		Awards	= nil,
		Reputation	 = -5,
		TextIdFirst	 = 1155,
		TextIdSecond = 1155,
		TextIdRefuse = 1153,
		Condition	 = function() return Party.QBits[562] end
	}

	if result == 1 then
		evt.Subtract{"QBits", 561}
		evt.SetNPCTopic{389, 1, 850}
	elseif result == 0 and (Party.QBits[563] or Party.QBits[564] or Party.QBits[565]) then
		Message(Game.NPCText[1154])
	end

end

-- Second good
Game.GlobalEvtLines:RemoveEvent(850)
evt.Global[850] = function()
	if CheckPromotionSide(611, 612, 1156, 1158, 1157) then
		evt.Set{"QBits", 566}
		evt.SetNPCTopic{389, 1, 851}
	end
end

Game.GlobalEvtLines:RemoveEvent(851)
evt.Global[851] = function()

	local result = Promote2{
		From 	= 13,
		To 		= 15,
		PromRewards 	= {Experience = 80000},
		NonPromRewards 	= {Experience = 40000},
		Gold 	= nil,
		QBits 	= {1615, 1616},
		Awards	= nil,
		Reputation	 = -10,
		TextIdFirst	 = 1159,
		TextIdSecond = 1159,
		TextIdRefuse = 1160,
		Condition	 = function() return Party.QBits[577] end
	}

	if result == 1 then
		evt.Subtract{"QBits", 566}
		evt.SetNPCGreeting{389, 196}
	end

end

-- Second evil
Game.GlobalEvtLines:RemoveEvent(852)
evt.Global[852] = function()
	if Party.QBits[1613] or Party.QBits[1614] then
		if CheckPromotionSide(612, 611, 1161, 1164, 1163) then
			evt.Set{"QBits", 567}
			evt.SetNPCTopic{390, 0, 853}
		end
	else
		Message(Game.NPCText[1162])
	end
end

Game.GlobalEvtLines:RemoveEvent(853)
evt.Global[853] = function()

	local result = Promote2{
		From 	= 13,
		To 		= 14,
		PromRewards 	= {Experience = 80000},
		NonPromRewards 	= {Experience = 40000},
		Gold 	= nil,
		QBits 	= {1617, 1618},
		Awards	= nil,
		Reputation	 = -10,
		TextIdFirst	 = 1165,
		TextIdSecond = 1165,
		TextIdRefuse = 1166,
		Condition	 = function() return evt.ForPlayer("All").Cmp{"Inventory", 1449} end
	}

	if result == 1 then
		evt.Subtract{"QBits", 567}
		evt.Subtract{"QBits", 739}
		evt.SetNPCGreeting{390, 198}
		evt.Set{"QBits", 1687}
		evt.ForPlayer("All").Subtract{"Inventory", 1449}
		NPCFollowers.Add(396)
	end
end

--------------------------------------------
---- Antagarich Paladin promotion
-- First
Game.GlobalEvtLines:RemoveEvent(801)
evt.Global[801] = function()
	Message(Game.NPCText[1012])
	NPCFollowers.Add(356)

	evt.Set{"QBits", 534}
	evt.Set{"QBits", 1684}

	evt.MoveNPC{356, 0}
	evt.SetNPCTopic{356, 0, 802}
end

Game.GlobalEvtLines:RemoveEvent(802)
evt.Global[802] = function()

	if Party.QBits[1590] or Party.QBits[1591] then
		Promote(26, 27, {Experience = 30000})
		Message(Game.NPCText[1013])

	elseif Party.QBits[535] then

		Promote(26, 27,
				{Experience = 30000},
				{Experience = 15000},
				nil,
				{1590, 1591})

		Party.QBits[534] = false
		Party.QBits[1684] = false
		evt.Subtract{"Reputation", 5}

		evt.MoveNPC{356, 941}
		evt.SetNPCTopic{356, 0, 803}
		evt.SetNPCTopic{356, 1, 802}
		evt.SetNPCGreeting{356, 158}
		NPCFollowers.Remove(356)

		Message(Game.NPCText[1013])
	else
		Message(Game.NPCText[1014])
	end

end

evt.Global[805] = function()
	if (Party.QBits[611] or Party.QBits[612]) and not (Party.QBits[1592] or Party.QBits[1594]) then
		NPCFollowers.Add(393)
	end
end
-- Second good
Game.GlobalEvtLines:RemoveEvent(803)
evt.Global[803] = function()
	if Party.QBits[611] then
		Message(Game.NPCText[1015])
		evt.Set{"QBits", 536}
		evt.SetNPCTopic{356, 0, 804}
		evt.SetNPCGreeting{356, 158}
		evt.MoveNPC{393, 1158}
	elseif Party.QBits[612] then
		Message(Game.NPCText[1016])
	else
		Message(Game.NPCText[1017])
	end
end

Game.GlobalEvtLines:RemoveEvent(804)
evt.Global[804] = function()

	if Party.QBits[1592] or Party.QBits[1593] then
		NPCFollowers.Remove(393)
		Promote(27, 28, {Experience = 80000})
		Message(Game.NPCText[1018])

	elseif Party.QBits[1685] then
		NPCFollowers.Remove(393)
		Promote(27, 28,
				{Experience = 80000},
				{Experience = 40000},
				nil,
				{1592, 1593})

		Party.QBits[536] = false
		Party.QBits[1685] = false
		evt.Subtract{"Reputation", 10}
		evt.MoveNPC{393, 941}
		evt.SetNPCGreeting{356, 161}

		NPCFollowers.Remove(393)
		Message(Game.NPCText[1018])
	else
		evt.Set{"QBits", 536}
		Message(Game.NPCText[1019])
	end

end

-- Second evil
Game.GlobalEvtLines:RemoveEvent(807)
evt.Global[807] = function()

	if Party.QBits[1594] or Party.QBits[1595] then
		NPCFollowers.Remove(393)
		Promote(27, 29, {Experience = 80000})
		Message(Game.NPCText[1029])

	elseif Party.QBits[1685] then
		NPCFollowers.Remove(393)
		Promote(27, 29,
				{Experience = 80000},
				{Experience = 40000},
				nil,
				{1594, 1595})

		Party.QBits[538] = false
		Party.QBits[1685] = false
		evt.Add{"Reputation", 10}
		evt.SetNPCGreeting{357, 165}

		NPCFollowers.Remove(393)
		Message(Game.NPCText[1029])
	else
		Message(Game.NPCText[1030])
	end

end

--------------------------------------------
---- Antagarich Monk promotion
-- First
Game.GlobalEvtLines:RemoveEvent(810)
evt.Global[810] = function()

	if Party.QBits[1572] or Party.QBits[1573] then
		Promote(22, 23, {Experience = 30000})
		Party.QBits[539] = false

	else
		Promote(22, 23,
				{Experience = 30000},
				{Experience = 15000},
				nil,
				{1572, 1573})

		Party.QBits[539] = false
		Party.QBits[1685] = false

		evt.SetNPCTopic{377, 0, 810}
		evt.SetNPCTopic{377, 1, 811}
		evt.SetNPCTopic{394, 0, 810}
		evt.SetNPCTopic{394, 1, 811}

	end

	Message(Game.NPCText[1032])
end

Game.GlobalEvtLines:RemoveEvent(811)
evt.Global[811] = function()
	if Party.QBits[611] then

		evt.Set{"QBits", 540}
		Message(Game.NPCText[1034])
		evt.SetNPCTopic{377, 1, 812}
		evt.SetNPCTopic{394, 1, 812}

	elseif Party.QBits[612] then
		Message(Game.NPCText[1035])

	else
		Message(Game.NPCText[1036])

	end
end

-- Second good
Game.GlobalEvtLines:RemoveEvent(812)
evt.Global[812] = function()

	if Party.QBits[1574] or Party.QBits[1575] then
		Party.QBits[540] = false
		Promote(23, 24, {Experience = 80000})
		Message(Game.NPCText[1072])

	elseif Party.QBits[755] or evt.ForPlayer("All").Cmp{"Inventory", 1332} then

		Promote(23, 24,
				{Experience = 80000},
				{Experience = 40000},
				nil,
				{1574, 1575})

		Party.QBits[540] = false
		evt.Subtract{"Reputation", 10}
		evt.SetNPCGreeting{377, 167}

		Message(Game.NPCText[1072])
	else
		Message(Game.NPCText[1073])
	end

end

-- Second evil
Game.GlobalEvtLines:RemoveEvent(814)
evt.Global[814] = function()

	if Party.QBits[1576] or Party.QBits[1577] then
		Promote(23, 25, {Experience = 80000})
		Message(Game.NPCText[1080])
		Party.QBits[541] = false

	elseif Party.QBits[754] then

		Promote(23, 25,
				{Experience = 80000},
				{Experience = 40000},
				nil,
				{1576, 1577})

		Party.QBits[541] = false
		evt.Subtract{"Reputation", 10}
		evt.SetNPCGreeting{378, 170}

		Message(Game.NPCText[1080])

	elseif Party.QBits[569] then
		Message(Game.NPCText[1078])

	else
		Message(Game.NPCText[1079])

	end

end

--------------------------------------------
---- Antagarich Knight promotion
-- First
Game.GlobalEvtLines:RemoveEvent(824)
evt.Global[824] = function()

	local result = Promote2{
		From 	= 16,
		To 		= 17,
		PromRewards 	= {Experience = 30000},
		NonPromRewards 	= {Experience = 15000},
		Gold 	= nil,
		QBits 	= {1566, 1567},
		Awards	= nil,
		Reputation	 = -5,
		TextIdFirst	 = 1102,
		TextIdSecond = 1102,
		TextIdRefuse = 1103,
		Condition	 = function() return Party.QBits[652] end
	}

	if result == 1 then
		evt.Subtract{"QBits", 546}
		evt.SetNPCTopic{382, 1, 825}
	end

end

-- Second evil
Game.GlobalEvtLines:RemoveEvent(825)
evt.Global[825] = function()
	if CheckPromotionSide(612, 611, 1104, 1106, 1105) then
		evt.Set{"QBits", 547}
		evt.SetNPCTopic{382, 1, 826}
	end
end

Game.GlobalEvtLines:RemoveEvent(826)
evt.Global[826] = function()

	local result = Promote2{
		From 	= 17,
		To 		= 18,
		PromRewards 	= {Experience = 80000},
		NonPromRewards 	= {Experience = 40000},
		Gold 	= nil,
		QBits 	= {1570, 1571},
		Awards	= nil,
		Reputation	 = -10,
		TextIdFirst	 = 1107,
		TextIdSecond = 1107,
		TextIdRefuse = 1108,
		Condition	 = function() return Party.QBits[572] end
	}

	if result == 1 then
		evt.Subtract{"QBits", 547}
		evt.SetNPCGreeting{382, 178}
	end

end

-- Second good
Game.GlobalEvtLines:RemoveEvent(821)
evt.Global[821] = function()
	if Party.QBits[1566] or Party.QBits[1567] then
		if CheckPromotionSide(611, 612, 1095, 1097, 1096) then
			evt.Set{"QBits", 545}
			evt.SetNPCTopic{381, 0, 822}
		end
	else
		Message(Game.NPCText[1098])
	end
end

Game.GlobalEvtLines:RemoveEvent(822)
evt.Global[822] = function()

	local result = Promote2{
		From 	= 17,
		To 		= 19,
		PromRewards 	= {Experience = 80000},
		NonPromRewards 	= {Experience = 40000},
		Gold 	= nil,
		QBits 	= {1568, 1569},
		Awards	= nil,
		Reputation	 = -10,
		TextIdFirst	 = 1099,
		TextIdSecond = 1099,
		TextIdRefuse = 1100,
		Condition	 = function() return Party.ArenaWinsKnight >= 5 end
	}

	if result == 1 then
		evt.Subtract{"QBits", 545}
		evt.SetNPCGreeting{381, 176}
	end

end

--------------------------------------------
---- Antagarich Ranger promotion
-- First
Game.GlobalEvtLines:RemoveEvent(830)
evt.Global[830] = function()
	local result = Promote2{
		From 	= 30,
		To 		= 31,
		PromRewards = {Experience = 30000},
		QBits 	= {1578, 1579},
		TextIdFirst	 = 1117,
		TextIdRefuse = 1117,
		Condition	 = function()
			if Party.QBits[1578] or Party.QBits[1579] then
				Party.QBits[549] = false
				return true
			end
			Party.QBits[549] = true
			return false
		end
	}

end

Game.GlobalEvtLines:RemoveEvent(833)
evt.Global[833] = function()

	local result = Promote2{
		From 	= 30,
		To 		= 31,
		PromRewards 	= {Experience = 30000},
		NonPromRewards 	= {Experience = 15000},
		QBits 		= {1578, 1579},
		TextIdFirst	= 1123
	}

	Party.QBits[549] = false
	evt.SetNPCTopic{384, 0, 830}
	evt.SetNPCTopic{384, 1, 831}

end

-- Second evil
Game.GlobalEvtLines:RemoveEvent(831)
evt.Global[831] = function()
	if CheckPromotionSide(612, 611, 1118, 1120, 1119) then
		evt.Set{"QBits", 550}
		evt.SetNPCTopic{384, 1, 832}
	end
end

Game.GlobalEvtLines:RemoveEvent(832)
evt.Global[832] = function()

	local result = Promote2{
		From 	= 31,
		To 		= 32,
		PromRewards 	= {Experience = 80000},
		NonPromRewards 	= {Experience = 40000},
		Gold 	= nil,
		QBits 	= {1582, 1583},
		Awards	= nil,
		Reputation	 = -10,
		TextIdFirst	 = 1121,
		TextIdSecond = 1121,
		TextIdRefuse = 1122,
		Condition	 = function() return evt.Cmp{310, 10000} end
	}

	if result == 1 then
		evt.Subtract{"QBits", 550}
		evt.SetNPCGreeting{384, 182}
	end

end

-- Second good
Game.GlobalEvtLines:RemoveEvent(827)
evt.Global[827] = function()
	if Party.QBits[1578] or Party.QBits[1579] then
		if CheckPromotionSide(611, 612, 1109, 1112, 1110) then
			evt.Set{"QBits", 548}
			evt.SetNPCTopic{383, 0, 828}
		end
	else
		Message(Game.NPCText[1111])
	end
end

Game.GlobalEvtLines:RemoveEvent(828)
evt.Global[828] = function()

	local result = Promote2{
		From 	= 31,
		To 		= 33,
		PromRewards 	= {Experience = 80000},
		NonPromRewards 	= {Experience = 40000},
		Gold 	= nil,
		QBits 	= {1580, 1581},
		Awards	= nil,
		Reputation	 = -5,
		TextIdFirst	 = 1115,
		TextIdSecond = 1115,
		TextIdRefuse = 1113,
		Condition	 = function() return Party.QBits[553] end
	}

	if result == 1 then
		evt.Subtract{"QBits", 548}
		evt.SetNPCGreeting{383, 180}
	elseif result == 2 then
		Party.QBits[548] = false
	elseif result == 0 and Party.QBits[552] then
		Message(Game.NPCText[1114])
	end

end
--------------------------------------------
---- Antagarich Thief promotion
-- First
Game.GlobalEvtLines:RemoveEvent(795)
evt.Global[795] = function()

	if Party.QBits[1560] or Party.QBits[1561] then
		Promote(34, 35, {Experience = 15000})
		Message(Game.NPCText[995])

	elseif evt.ForPlayer("All").Cmp{"Inventory", 1426} then

		Promote(34, 35,
				{Experience = 30000},
				{Experience = 15000},
				5000,
				{1560, 1561})

		evt.ForPlayer("All").Subtract{"Inventory", 1426}
		evt.Subtract{"QBits", 724}
		evt.Subtract{"QBits", 530}

		evt.SetNPCTopic{354, 1, 796}
		evt.SetNPCTopic{354, 0, 795}
		Message(Game.NPCText[995])
	else
		Message(Game.NPCText[994])
	end

end

-- Second good
Game.GlobalEvtLines:RemoveEvent(796)
evt.Global[796] = function()

	if Party.QBits[611] then
		Message(Game.NPCText[998])
		evt.Set{"QBits", 531}
		evt.SetNPCTopic{354, 1, 797}
	elseif Party.QBits[612] then
		Message(Game.NPCText[996])
	else
		Message(Game.NPCText[997])
	end

end

Game.GlobalEvtLines:RemoveEvent(797)
evt.Global[797] = function()

	if Party.QBits[1562] or Party.QBits[1563] then
		Promote(35, 37, {Experience = 80000})
		Message(Game.NPCText[1002])

	elseif Party.QBits[532] then

		Promote(35, 37,
				{Experience = 80000},
				{Experience = 40000},
				15000,
				{1562, 1563})

		Party.QBits[531] = false

		evt.SetNPCGreeting{354, 154}
		Message(Game.NPCText[1002])

	elseif Party.QBits[568] then
		Message(Game.NPCText[1000])

	else
		Message(Game.NPCText[999])
	end

end

-- Second evil
Game.GlobalEvtLines:RemoveEvent(800)
evt.Global[800] = function()

	if Party.QBits[1564] or Party.QBits[1565] then
		Promote(35, 36, {Experience = 80000})
		Message(Game.NPCText[1010])

	elseif evt.ForPlayer("All").Cmp{"Inventory", 1342} then

		Promote(35, 36,
				{Experience = 80000},
				{Experience = 40000},
				15000,
				{1564, 1565})

		Party.QBits[725] = false
		Party.QBits[533] = false
		evt.Add{"Reputation", 10}

		evt.SetNPCGreeting{355, 157}
		Message(Game.NPCText[1010])

	else
		Message(Game.NPCText[1009])
	end

end

--------------------------------------------
---- Antagarich Wizard promotion
-- First
evt.Global[842] = function()
	NPCFollowers.Add(395)
end -- Golem removal part is in 7d29.lua
Game.GlobalEvtLines:RemoveEvent(843)
evt.Global[843] = function()

	local result = Promote2{
		From 	= 42,
		To 		= 43,
		PromRewards 	= {Experience = 30000},
		NonPromRewards 	= {Experience = 15000},
		Gold 	= nil,
		QBits 	= {1619, 1620},
		Awards	= nil,
		Reputation	 = -5,
		TextIdFirst	 = 1140,
		TextIdSecond = 1140,
		TextIdRefuse = 205,
		Condition	 = function() return Party.QBits[585] or Party.QBits[586] end
	}

	if result == 1 then
		evt.Subtract{"QBits", 557}
		evt.Subtract{"QBits", 731}
		evt.Subtract{"QBits", 732}
		evt.Set{"QBits", 558}
		evt.SetNPCTopic{387, 1, 844}
		evt.SetNPCGreeting{395, 199}
	end

end

-- Second good
Game.GlobalEvtLines:RemoveEvent(844)
evt.Global[844] = function()
	if CheckPromotionSide(611, 612, 1141, 1143, 1142) then
		evt.Set{"QBits", 559}
		evt.SetNPCTopic{387, 1, 845}
	end
end

Game.GlobalEvtLines:RemoveEvent(845)
evt.Global[845] = function()

	local result = Promote2{
		From 	= 43,
		To 		= 46,
		PromRewards 	= {Experience = 80000},
		NonPromRewards 	= {Experience = 40000},
		Gold 	= 10000,
		QBits 	= {1621, 1622},
		Awards	= nil,
		Reputation	 = 0,
		TextIdFirst	 = 1144,
		TextIdSecond = 1144,
		TextIdRefuse = 1145,
		Condition	 = function() return evt.ForPlayer("All").Cmp{"Inventory", 1289} end
	}

	if result == 1 then
		evt.Subtract{"QBits", 559}
		evt.Subtract{"QBits", 738}
		evt.SetNPCGreeting{387, 192}
	end

end

-- Second evil
Game.GlobalEvtLines:RemoveEvent(846)
evt.Global[846] = function()

	local Allowed = Party.QBits[1619] or Party.QBits[1620] or evt.Cmp{"ClassIs", 44} or evt.Cmp{"ClassIs", 45}

	if Allowed then
		if Party.QBits[612] then

			Message(Game.NPCText[1146])
			evt.Set{"QBits", 560}
			evt.SetNPCTopic{388, 0, 847}

		elseif Party.QBits[611] then
			Message(Game.NPCText[1149])
		else
			Message(Game.NPCText[1148])
		end
	else
		Message(Game.NPCText[1147])
	end

end

Game.GlobalEvtLines:RemoveEvent(847)
evt.Global[847] = function()

	local NooneHave = true
	local NoLiches = true
	local JarsCount = 0

	for i, v in Party do
		if evt.ForPlayer(i).Cmp{"Inventory", 1417} then

			NooneHave = false
			JarsCount = JarsCount + 1

			if v.Class == 44 or v.Class == 43 then
				local CurSex = v:GetSex()
				v.Class = 45
				evt.ForPlayer(i).Add{"Experience", 40000}

				NoLiches = false
			else
				if not Party.QBits[1624] then
					evt.ForPlayer(i).Add{"Experience", 40000}
				end
				evt.Add{"Gold", 1500}
			end

		end
	end

	for i = 1, JarsCount do
		evt.Subtract{"Inventory", 1417}
	end

	if NooneHave then

		Message(Game.NPCText[1151])

	else

		Party.QBits[1624] = true
		Party.QBits[1623] = true
		Party.QBits[560] = false
		Party.QBits[741] = false

		if NoLiches then
			Message(Game.NPCText[2698])
		else
			Message(Game.NPCText[1150])
		end

	end

	PromoteDarkMages()

end

--------------------------------------------
---- 		JADAME PROMOTIONS			----
--------------------------------------------

--------------------------------------------
---- Jadame Sorcerer promotion
Quest{
	NPC = 62, -- Lathean
	Branch = "",
	Slot = 4,
	CanShow 	= function() return evt.ForPlayer("All").Cmp{"ClassIs", 42} or evt.ForPlayer("All").Cmp{"ClassIs", 43} or evt.ForPlayer("All").Cmp{"ClassIs", 48} end,
	CheckDone 	= function(t)	Message(t.Texts.Undone)
								return evt.Subtract{"Gold", 10000}	end,
	Done		= function() Promote({42,43,48}, 44, {Experience = 15000}, {Experience = 5000}) end,
	After		= function() Promote({42,43,48}, 44, {Experience = 15000}) end,
	Texts = {	Topic 	= Game.NPCText[2699], -- "Join guild"
				Give 	= Game.NPCText[2700],
				Undone	= Game.NPCText[2701],
				Done	= Game.NPCText[2702],
				After	= Game.NPCText[2703]}
	}

--------------------------------------------
---- Jadame Necromancer promotion

evt.Global[89] 	= PromoteDarkMages

Game.GlobalEvtLines:RemoveEvent(738)
evt.Global[738] = function()

	local NoJars = true

	for i, v in Party do
		if v.Class == 44 or v.Class == 43 then
			if evt[i].Cmp{"Inventory", 628} then
				evt[i].Subtract{"Inventory", 628}
				evt[i].Add{"Experience", 0}
				v.Class = 45
				NoJars = false
			end
		end
	end
	PromoteDarkMages()

	if NoJars then
		Message(Game.NPCText[114])
	else
		Message(Game.NPCText[925])
	end

end

--------------------------------------------
---- Jadame Cleric/Priest promotion

evt.Global[81] 	= function()
	if evt.Cmp{"Inventory", 626} or Party.QBits[1546] then
		Promote({4,5}, 6, {Experience = 10000})
	end
end
evt.Global[737] = function()
	Promote({4,5}, 6, {Experience = 10000})
end

--------------------------------------------
---- Jadame Knight/Cavalier promotion

evt.Global[58] 	= function()
	if evt.Cmp{"Inventory", 539} or Party.QBits[1541] then
		Party.QBits[70] = false
		Promote(17, 19, {Experience = 10000})
	end
end
evt.Global[735] = function()
	Party.QBits[70] = false
	Promote(17, 19, {Experience = 10000})
end

--------------------------------------------
---- 		PEASANT PROMOTIONS			----
--------------------------------------------

-- SkillId = Class
-- Teachers will also promote peasants to class assigned to skill.
local TeacherPromoters = {

	[0] = 22,	-- Staff = Monk
	[1] = 16,	-- Sword = Knight
	[2] = 34,	-- Dagger = Thief
	[4] = 16,	-- Spear = Knight
	[5] = 0,	-- Bow = Archer
	[6] = 4,	-- Mace = Cleric
	[7] = nil,
	[8] = 26,	-- Shield = Paladin
	[9] = 34,	-- Leather = Thief
	[10] = 0,	-- Chain = Archer
	[11] = 26,	-- Plate = Paladin
	[12] = 42, 	-- Fire = Sorcerer
	[13] = 42,	-- Air = Sorcerer
	[14] = 12,	-- Water = Druid
	[15] = 12,	-- Earth = Druid
	[16] = 26,	-- Spirit = Paladin
	[17] = 12,	-- Mind = Druid
	[18] = 4,	-- Body = Cleric
	[19] = 4,	-- Light = Cleric
	[20] = 42,	-- Dark = Sorcerer
	[21] = 8,	-- Dark elf
	[22] = 40,	-- Vampire
	[23] = nil,
	[24] = 34,	-- ItemId = Thief
	[25] = 34,	-- Merchant = Thief
	[26] = 16,	-- Repair = Knight
	[27] = 16,	-- Bodybuilding = Knight
	[28] = 12,	-- Meditation = Druid
	[29] = 0,	-- Perception = Archer
	[30] = 38,	-- Regeneration = Troll
	[31] = 34,	-- Disarm = Thief
	[32] = 22,	-- Dodging = Monk
	[33] = 22, 	-- Unarmed = Monk
	[34] = 30,	-- Mon Id = Ranger
	[35] = 30,	-- Arms = Ranger
	[36] = nil,
	[37] = 12,	-- Alchemy = Druid
	[38] = 42	-- Learning = Sorcerer

}

local PeasantPromoteTopic = 1721
NPCFollowers.PeasantPromoteTopic = PeasantPromoteTopic

local function PromotePeasant(To)

	evt.ForPlayer("Current")
	if not evt.Cmp{"ClassIs", 48} then
		return false
	end

	evt.Set{"ClassIs", To}
	evt.Add{"Experience", 5000}

	if To == const.Class.Vampire or To == const.Class.Nosferatu then
		local cChar = Party[Game.CurrentPlayer]
		local Gender = Game.CharacterPortraits[cChar.Face].DefSex
		local NewFace = 12 + math.random(0,1)*2 + Gender

		cChar.Face = NewFace
		SetCharFace(Game.CurrentPlayer, NewFace)
		cChar.Skills[const.Skills.VampireAbility] = 1
		cChar.Spells[111] = true

	elseif To == const.Class.DarkElf then
		local cChar = Party[Game.CurrentPlayer]
		cChar.Skills[const.Skills.DarkElfAbility] = 1
		cChar.Spells[100] = true

	end

	return true

end

local function CheckRace(To)

	local cChar = Party[Game.CurrentPlayer]
	local cRace = Game.CharacterPortraits[cChar.Face].Race
	local Races = const.Race

	if To == const.Class.Vampire and
		(cRace == Races.Human or cRace == Races.Elf or cRace == Races.DarkElf or cRace == Races.Goblin) then

		return true
	end

	local T = Game.CharSelection.ClassByRace[cRace]
	if T then
		return T[To]
	end

	return false

end

local CurPeasantPromClass
local RestrictedTeachers = {427, 418}
function events.EnterNPC(i)

	local cNPC = Game.NPC[i]
	for i = 0, 4 do
		if cNPC.Events[i] == PeasantPromoteTopic then
			cNPC.Events[i] = 0
		end
	end

	if table.find(RestrictedTeachers, i) then
		return
	end

	local peasant_present = false
	for _, pl in Party do
		if pl.Class == const.Class.Peasant then
			peasant_present = true
			break
		end
	end

	if peasant_present then
		local ClassId
		local cEvent
		for Eid = 0, 5 do
			cEvent = cNPC.Events[Eid]
			local TTopic = Game.TeacherTopics[cEvent]
			if TTopic and TeacherPromoters[TTopic.SId] then
				ClassId = TeacherPromoters[TTopic.SId]
			end
		end

		if not ClassId then
			return
		end

		CurPeasantPromClass = ClassId

		for i = 0, 4 do
			if cNPC.Events[i] == 0 then
				cEvent = i
				break
			end
		end

		if not cEvent then
			return
		end

		cNPC.Events[cEvent] = PeasantPromoteTopic
		Game.NPCTopic[PeasantPromoteTopic] = string.format(Game.NPCText[1676], Game.ClassNames[ClassId])
	end

end

local PeasantLastClick = 0
evt.Global[PeasantPromoteTopic] = function()
	if Game.CurrentPlayer < 0 then
		return
	end

	local ClassId = CurPeasantPromClass

	if not CheckRace(ClassId) then
		Message(string.format(Game.NPCText[1679], Game.ClassNames[ClassId]))
		return
	end

	if PeasantLastClick + 2 > os.time() then
		PeasantLastClick = 0
		if PromotePeasant(ClassId) then
			Message(string.format(Game.NPCText[1678], Game.ClassNames[ClassId]))
		end
	else
		PeasantLastClick = os.time()
		Message(string.format(Game.NPCText[1677], Game.ClassNames[ClassId]))
	end
end

--------------------------------------------
---- 	ELF/VAMPIRE/DRAGON TEACHERS		----
--------------------------------------------

local LastLearnClick = 0
local LastTeacherSkill
local LearnSkillTopic = 1674
local SkillsToLearnFromTeachers = {21,22,23}

local function PartyCanLearn(skill)
	for _,pl in Party do
		if pl.Skills[skill] == 0 and GetMaxAvailableSkill(pl, skill) > 0 then
			return true
		end
	end
	return false
end

evt.Global[LearnSkillTopic] = function()
	if Game.CurrentPlayer < 0 then
		return
	end

	local Player = Party[Game.CurrentPlayer]
	local Skill = LastTeacherSkill
	local cNPC = Game.NPC[GetCurrentNPC()]

	if not Skill then
		return
	end

	if Player.Skills[Skill] > 0 then
		Message(string.format(Game.GlobalTxt[403], Game.SkillNames[Skill]))
	elseif GetMaxAvailableSkill(Player, Skill) == 0 then
		Message(string.format(Game.GlobalTxt[632], Game.ClassNames[Player.Class]))
	elseif Party.Gold < 500 then
		Message(Game.GlobalTxt[155])
	elseif GetMaxAvailableSkill(Player, Skill) > 0 and Player.Skills[Skill] == 0 then
		evt[Game.CurrentPlayer].Add{"Experience", 0} -- animation
		Player.Skills[Skill] = 1

		for i = 9, 11 do
			local CurS, CurM = SplitSkill(Player.Skills[i+12])
			for iL = 1 + i*11, CurM + i*11 do
				Player.Spells[iL] = true
			end
		end

		evt[Game.CurrentPlayer].Subtract{"Gold", 500}
		Message(Game.GlobalTxt[569])
	end
end

function events.EnterNPC(i)

	LastTeacherSkill = nil

	local TTopic
	local cNPC = Game.NPC[i]
	for Eid = 0, 5 do
		TTopic = Game.TeacherTopics[cNPC.Events[Eid]]
		if TTopic then
			LastTeacherSkill = TTopic.SId
			break
		end
	end

	if not table.find(SkillsToLearnFromTeachers, LastTeacherSkill) then
		return
	end

	if LastTeacherSkill and PartyCanLearn(LastTeacherSkill) then
		local str = Game.GlobalTxt[534]
		str = string.replace(str, "%lu", "500")
		str = string.format(str, Game.GlobalTxt[431], Game.SkillNames[LastTeacherSkill], "")

		Game.NPCTopic[LearnSkillTopic] = str
		cNPC.Events[NPCFollowers.FindFreeEvent(cNPC, LearnSkillTopic)] = LearnSkillTopic
	else
		NPCFollowers.ClearEvents(cNPC, {LearnSkillTopic})
	end

end
