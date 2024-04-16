
function events.AfterLoadMap()
	Party.QBits[180] = true -- Town portal
end

----------------------------------------
-- Loretta Fleise's fix prices quest

Game.MapEvtLines:RemoveEvent(14)
evt.house[14] = 472
evt.map[14] = function() StdQuestsFunctions.CheckPrices(472, 1518) end

Game.MapEvtLines:RemoveEvent(15)
evt.house[15] = 472
evt.map[15] = function() StdQuestsFunctions.CheckPrices(472, 1518) end

Game.MapEvtLines:RemoveEvent(16)
evt.house[16] = 473
evt.map[16] = function() StdQuestsFunctions.CheckPrices(473, 1519) end

Game.MapEvtLines:RemoveEvent(17)
evt.house[17] = 473
evt.map[17] = function() StdQuestsFunctions.CheckPrices(473, 1519) end

----------------------------------------
-- Silvertongue's treason

Game.MapEvtLines:RemoveEvent(49)
Game.MapEvtLines:RemoveEvent(50)
evt.house[49] = 209
evt.house[50] = 209

local function RosterHaveAward(i)
	for _,v in Party.PlayersArray do
		if v.Awards[i] then
			return true
		end
	end
	return false
end

local function RevealSilverTongue()
	if evt.ForPlayer("All").Cmp{"Inventory", 2122} and Game.NPC[1089].House == 209 then
		evt.ShowMovie{0, 0, "citytrtr"}
		evt.MoveNPC{1089, 0}
		evt.Subtract{"Inventory", 2122}
		evt.Add{"ReputationIs", 20}
		evt.Set{"QBits", 1192}
		evt.Subtract{"QBits", 1225}
		evt.ForPlayer("All").Add{"Awards", 63}
		if RosterHaveAward(57) and RosterHaveAward(58) and RosterHaveAward(59) and RosterHaveAward(60) and RosterHaveAward(61) and RosterHaveAward(62) then
			evt.Set{"QBits", 1191}
		end
	end

	if Party.QBits[1192] then
		Party.QBits[1225] = false
		for i,v in Game.NPC[789].Events do
			if v == 1415 then
				Game.NPC[789].Events[i] = 0
			end
		end
	end

	evt.EnterHouse{209}
end

evt.map[49] = RevealSilverTongue
evt.map[50] = RevealSilverTongue

----------------------------------------
-- Dragon tower

Game.MapEvtLines:RemoveEvent(209)
if not Party.QBits[1183] then

	local function DragonTower()
		StdQuestsFunctions.DragonTower(3823, 10974, 2700, 1183)
	end
	Timer(DragonTower, 5*const.Minute)

	function events.LeaveMap()
		RemoveTimer(DragonTower)
	end

end

Game.MapEvtLines:RemoveEvent(210)
evt.map[210] = function()
	if not Party.QBits[1183] and evt.ForPlayer("All").Cmp{"Inventory", 2106} then
		evt.Set{"QBits", 1183}
		StdQuestsFunctions.SetTextureOutdoors(25, 55, "t1swbu")
	end
end

evt.map[214] = function()
	if Party.QBits[1183] then
		StdQuestsFunctions.SetTextureOutdoors(25, 55, "t1swbu")
	end
end

----------------------------------------
-- Repair Stone Temple

Game.MapEvtLines:RemoveEvent(19)
evt.house[19] = 326
evt.map[19] = function()
	if Party.QBits[1131] then
		if evt.ForPlayer("All").Cmp{"Inventory", 2054} then
			evt.ForPlayer("All").Subtract{"Inventory", 2054}
			evt.Subtract{"QBits", 1212}
			evt.Set{"QBits", 1132}
			Message(evt.str[30])
		else
			evt.EnterHouse{326}
		end
	elseif Party.QBits[1130] then
		if Party.QBits[1129] then
			evt.EnterHouse{1442}
		else
			evt.EnterHouse{326}
		end
	else
		local Carpenter, Stonecutter = NPCFollowers.HaveProfession(63), NPCFollowers.HaveProfession(64)
		if Carpenter and Stonecutter then
			Message(evt.str[29])
			evt.Set{"QBits", 1130}
			NPCFollowers.Remove(Carpenter)
			NPCFollowers.Remove(Stonecutter)
		else
			evt.EnterHouse{1442}
		end
	end
end

----------------------------------------
-- Adventurer's Inn

evt.house[140] = 1607
evt.map[140] = function() evt.EnterHouse{1607} end

Game.MapEvtLines:RemoveEvent(261)
evt.hint[261] = evt.str[11]  -- "Shrine of Accuracy"
evt.map[261] = function()
	if not evt.Cmp{"QBits", Value = 1230} then         -- NPC
		evt.Set{"QBits", Value = 1230}         -- NPC
		if evt.Cmp{"QBits", Value = 1235} then         -- NPC
			evt.ForPlayer("All")
			evt.Add{"BaseAccuracy", Value = 3}
		else
			evt.Set{"QBits", Value = 1235}         -- NPC
			evt.ForPlayer("All")
			evt.Add{"BaseAccuracy", Value = 10}
			evt.StatusText{Str = 13}         -- "+10 Accuracy permanent"
		end
		return
	end
	evt.StatusText{Str = 12}         -- "You pray at the shrine."
end

