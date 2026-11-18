
-- Allow submarine usage without key, if key was used at least once
Game.MapEvtLines:RemoveEvent(451)
evt.map[451] = function()
	evt.ForPlayer("All")
	if evt.Cmp("Inventory", 619) or Party.QBits[214] then -- "Pirate Leader's Key"
		Party.QBits[214] = true
		evt.ShowMovie{DoubleSize = 1, Name = "\"Subcut\" "}
		evt.MoveToMap{X = -2416, Y = 1850, Z = -687, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 0, Name = "D34.blv"}
	else
		evt.FaceAnimation{Player = "Current", Animation = 18}
	end
end

