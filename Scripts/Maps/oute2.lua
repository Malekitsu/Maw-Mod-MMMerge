
function events.AfterLoadMap()
	LocalHostileTxt()
	Game.HostileTxt[211][0] = 0
	Game.HostileTxt[204][0] = 0

	Game.HostileTxt[211][205] = 2
	Game.HostileTxt[205][211] = 1

	Game.HostileTxt[211][201] = 2
	Game.HostileTxt[201][211] = 1

	Game.HostileTxt[211][202] = 2
	Game.HostileTxt[202][211] = 1

	Party.QBits[184] = true -- Town portal
end

----------------------------------------
-- Dragon tower

Game.MapEvtLines:RemoveEvent(210)
if not Party.QBits[1181] then

	local function DragonTower()
		StdQuestsFunctions.DragonTower(3039, -9201, 2818, 1181)
	end
	Timer(DragonTower, 5*const.Minute)

	function events.LeaveMap()
		RemoveTimer(DragonTower)
	end

end

Game.MapEvtLines:RemoveEvent(211)
evt.map[211] = function()
	if not Party.QBits[1181] and evt.ForPlayer("All").Cmp{"Inventory", 2106} then
		evt.Set{"QBits", 1181}
		StdQuestsFunctions.SetTextureOutdoors(53, 42, "t1swbu")
	end
end

evt.map[213] = function()
	if Party.QBits[1181] then
		StdQuestsFunctions.SetTextureOutdoors(53, 42, "t1swbu")
	end
end

Game.MapEvtLines:RemoveEvent(261)
evt.hint[261] = evt.str[15]  -- "Shrine of Intellect"
evt.map[261] = function()
	if not evt.Cmp{"QBits", Value = 1230} then         -- NPC
		evt.Set{"QBits", Value = 1230}         -- NPC
		if evt.Cmp{"QBits", Value = 1232} then         -- NPC
			evt.ForPlayer("All")
			evt.Add{"BaseIntellect", Value = 3}
		else
			evt.Set{"QBits", Value = 1232}         -- NPC
			evt.ForPlayer("All")
			evt.Add{"BaseIntellect", Value = 10}
			evt.StatusText{Str = 17}         -- "+10 Intellect permanent"
		end
		return
	end
	evt.StatusText{Str = 16}         -- "You pray at the shrine."
end

