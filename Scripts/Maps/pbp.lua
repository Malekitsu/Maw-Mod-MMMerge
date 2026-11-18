
-- Allow entering prison, if one was opened at least once

Game.MapEvtLines:RemoveEvent(502)
evt.hint[502] = evt.str[51]  -- "Enter the Prison of the Air Lord"
evt.map[502] = function()
	evt.ForPlayer("All")
	if mapvars.AirPrisonOpen or evt.Cmp("Inventory", 629) then         -- "Ring of Keys"
		mapvars.AirPrisonOpen = true
		evt.MoveToMap{X = -733, Y = -2563, Z = -1051, Direction = 960, LookAngle = 0, SpeedZ = 0, HouseId = 341, Icon = 1, Name = "d36.blv"}         -- "Prison of the Lord of Air"
	else
		evt.FaceAnimation{Player = "Current", Animation = 18}
	end
end

Game.MapEvtLines:RemoveEvent(503)
evt.hint[503] = evt.str[52]  -- "Enter the Prison of the Fire Lord"
evt.map[503] = function()
	evt.ForPlayer("All")
	if mapvars.FirePrisonOpen or evt.Cmp("Inventory", 629) then         -- "Ring of Keys"
		mapvars.FirePrisonOpen = true
		evt.MoveToMap{X = -128, Y = 896, Z = 1, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 343, Icon = 1, Name = "d37.blv"}         -- "Prison of the Lord of Fire"
	else
		evt.FaceAnimation{Player = "Current", Animation = 18}
	end
end

Game.MapEvtLines:RemoveEvent(504)
evt.hint[504] = evt.str[53]  -- "Enter the Prison of the Water Lord"
evt.map[504] = function()
	evt.ForPlayer("All")
	if mapvars.WaterPrisonOpen or evt.Cmp("Inventory", 629) then         -- "Ring of Keys"
		mapvars.WaterPrisonOpen = true
		evt.MoveToMap{X = 2393, Y = -10664, Z = 1, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 342, Icon = 1, Name = "d38.blv"}         -- "Prison of the Lord of Water"
	else
		evt.FaceAnimation{Player = "Current", Animation = 18}
	end
end

Game.MapEvtLines:RemoveEvent(505)
evt.hint[505] = evt.str[54]  -- "Enter the Prison of the Earth Lord"
evt.map[505] = function()
	evt.ForPlayer("All")
	if mapvars.EarthPrisonOpen or evt.Cmp("Inventory", 629) then         -- "Ring of Keys"
		mapvars.EarthPrisonOpen = true
		evt.MoveToMap{X = -2, Y = 118, Z = 1, Direction = 2047, LookAngle = 0, SpeedZ = 0, HouseId = 379, Icon = 1, Name = "d39.blv"}         -- "Prison of the Lord of Earth"
	else
		evt.FaceAnimation{Player = "Current", Animation = 18}
	end
end

