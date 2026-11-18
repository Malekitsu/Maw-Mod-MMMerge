
-- Allow submarine usage without key
Game.MapEvtLines:RemoveEvent(451)
evt.map[451] = function()
	evt.MoveToMap{X = 7097, Y = -1117, Z = -639, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "D06.blv"}
end

