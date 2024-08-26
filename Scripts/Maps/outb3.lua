local TileSounds = {[6] = {[0] = 91, 	[1] = 52}}

function events.TileSound(t)
	local Grp = TileSounds[Game.CurrentTileBin[Map.TileMap[t.X][t.Y]].TileSet]
	if Grp then
		t.Sound = Grp[t.Run]
	end

	-- Dimension door
	if t.X == 89 and t.Y == 47 then
		TownPortalControls.DimDoorEvent()
	end

end

-- Dimension door

evt.Map[105] = TownPortalControls.DimDoorEvent

-- Shrine of the Gods

mapvars.GotBless = mapvars.GotBless or (Map.Refilled and Map.Refilled.GotBless) or {}

Game.MapEvtLines:RemoveEvent(103)
evt.Hint[103] = evt.str[16]
evt.Map[103] = function()

	if Game.CurrentPlayer == -1 then
		return
	end

	local CurrentChar = Party.PlayersIndexes[Game.CurrentPlayer]

	if mapvars.GotBless[CurrentChar] then
		evt.Set{"MainCondition", 0}
	else
		mapvars.GotBless[CurrentChar] = true
		evt.Add{"FireResistance",	20}
		evt.Add{"AirResistance",	20}
		evt.Add{"WaterResistance",	20}
		evt.Add{"EarthResistance",	20}
		evt.Add{"SpiritResistance",	20}
		evt.Add{"MindResistance",	20}
		evt.Add{"BodyResistance",	20}
		evt.Add{"BaseMight",		20}
		evt.Add{"BaseIntellect",  	20}
		evt.Add{"BasePersonality",  20}
		evt.Add{"BaseEndurance",	20}
		evt.Add{"BaseSpeed", 		20}
		evt.Add{"BaseAccuracy", 	20}
		evt.Add{"BaseLuck",  		20}
		evt.PlaySound{42797}
		Game.ShowStatusText(evt.str[7])
	end
end

Game.MapEvtLines:RemoveEvent(92)
evt.map[92] = function()
	if vars.Mode==2 then
		Game.ShowStatusText("Access have been destroyed")
		return
	end
	if Party[0].LevelBase>=255 or Game.BolsterAmount<=100 then
		evt.MoveToMap{X = -640, Y = 512, Z = -416, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 0, Name = "znwc.blv"}
	else
		Game.ShowStatusText("You must prove your worth first")
	end
end
