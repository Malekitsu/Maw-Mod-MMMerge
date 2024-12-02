local TileSounds = {
[6] = {[0] = 90, 	[1] = 51}
}

function events.TileSound(t)
	local Grp = TileSounds[Game.CurrentTileBin[Map.TileMap[t.X][t.Y]].TileSet]
	if Grp then
		t.Sound = Grp[t.Run]
	end
end

----------------------------------------

function events.AfterLoadMap()
	LocalHostileTxt()
	Game.HostileTxt[185][0] = 0
	Party.QBits[183] = true -- Town portal
end

----------------------------------------
-- Loretta Fleise's fix prices quest

Game.MapEvtLines:RemoveEvent(15)
evt.house[15] = 470
evt.map[15] = function() StdQuestsFunctions.CheckPrices(470, 1523) end

Game.MapEvtLines:RemoveEvent(16)
evt.house[16] = 470
evt.map[16] = function() StdQuestsFunctions.CheckPrices(470, 1523) end

----------------------------------------
-- Dragon tower

Game.MapEvtLines:RemoveEvent(230)
if not Party.QBits[1180] then

	local function DragonTower()
		StdQuestsFunctions.DragonTower(-6152, -9208, 2700, 1180)
	end
	Timer(DragonTower, 5*const.Minute)

	function events.LeaveMap()
		RemoveTimer(DragonTower)
	end

end

Game.MapEvtLines:RemoveEvent(231)
evt.map[231] = function()
	if not Party.QBits[1180] and evt.ForPlayer("All").Cmp{"Inventory", 2106} then
		evt.Set{"QBits", 1180}
		StdQuestsFunctions.SetTextureOutdoors(84, 42, "t1swbu")
	end
end

evt.map[232] = function()
	if Party.QBits[1180] then
		StdQuestsFunctions.SetTextureOutdoors(84, 42, "t1swbu")
	end
end

----------------------------------------
-- Dimension door

evt.map[140] = function()
	if not evt.Cmp{"MapVar50", 1} then
		TownPortalControls.DimDoorEvent()
	end
end

----------------------------------------
-- Volcano

Game.MapEvtLines:RemoveEvent(220)
evt.map[220] = function()
	Game.PlaySound(18090)

	local rand = math.random
	for i = 1, 6 do
		evt.CastSpell{6, 4, 10, -14074, 16106, 1250, rand(-14024, -14124), rand(16056, 16156), 1500}
	end

	evt.CastSpell{43, 4, 10, -14320, 16272, 1400, rand(-14220, -14420), rand(16172, 16372), 2400}
	evt.CastSpell{43, 4, 10, -14096, 15648, 1400, rand(-14000, -14200), rand(15548, 15748), 2400}
	evt.CastSpell{43, 4, 10, -13856, 16448, 1400, rand(-13756, -13956), rand(16348, 16548), 2400}

	Timer(function()
		for i = 1, 6 do
			local x, y = rand(-20549, -7225), rand(11879, 18122)
			evt.CastSpell{9, 4, 10, x, y, 5084, x, y, 3000}
		end
		RemoveTimer()
		end, 256)
end

evt.hint[1777]="Antagarich"
evt.map[1777] = function()
	if vars.SuvivalMode then
		evt.MoveToMap{12567, 1728, 1, 512, 0, 0, 0, 0, "7out01.odm"}
		return
	end
	if evt.Cmp{"QBits", Value = 527} then
		evt.MoveToMap{-16832, 12512, 372, 0, 0, 0, 0, 3, "7out02.odm"}
	else
		evt.MoveToMap{12552, 800, 193, 512, 0, 0, 0, 3, "7out01.odm"}
	end
end

evt.hint[1888]="Jadame"
evt.map[1888] = function()
	if evt.Cmp{"QBits", Value = 93} then
		evt.MoveToMap{10219, -15624, 265, 0, 0, 0, 0, 3, "out02.odm"}
	else
		evt.MoveToMap{3560, 7696, 544, 0, 0, 0, 0, 3, "out01.odm"}
	end
end

Game.MapEvtLines:RemoveEvent(104)
evt.map[104] = function()
	if vars.Mode~=2 then
		evt.MoveToMap{X = 12808, Y = 6832, Z = 64, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 0, Name = "outb3.odm"}
	else
		evt.MoveToMap{X = -9477, Y = -13062, Z = 129, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 0, Name = "outb3.odm"}
	end
end

Game.MapEvtLines:RemoveEvent(261)
evt.hint[261] = evt.str[23]  -- "Shrine of Luck"
evt.map[261] = function()
	if not evt.Cmp{"QBits", Value = 1230} then         -- NPC
		evt.Set{"QBits", Value = 1230}         -- NPC
		if evt.Cmp{"QBits", Value = 1237} then         -- NPC
			evt.ForPlayer("All")
			evt.Add{"BaseLuck", Value = 3}
		else
			evt.Set{"QBits", Value = 1237}         -- NPC
			evt.ForPlayer("All")
			evt.Add{"BaseLuck", Value = 10}
			evt.StatusText{Str = 25}         -- "+10 Luck permanent"
		end
		return
	end
	evt.StatusText{Str = 24}         -- "You pray at the shrine."
end

if isRedone then
	evt.HouseDoor(29, 560)  -- "Tarent Hovel"
	evt.house[30] = 560  -- "Tarent Hovel"
end
