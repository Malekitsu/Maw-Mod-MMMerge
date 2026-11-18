
-- Correct coordinates of travel to Land of giants.
Game.MapEvtLines:RemoveEvent(501)
evt.Map[501] = function()
	evt.MoveToMap{20890, -3119, 5, 896, 0, 0, 0, 3, "out12.odm"}
end
