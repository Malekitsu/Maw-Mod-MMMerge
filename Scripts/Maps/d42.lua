
Game.MapEvtLines:RemoveEvent(501)
evt.map[501] = function()
	local CurCont = TownPortalControls.GetCurrentSwitch()

	if CurCont == 2 then
		evt.MoveToMap{-5692, 11137, 1, 1024, 0, 0, 0, 8, "7out02.odm"}
	elseif CurCont == 3 then
		evt.MoveToMap{14305, 2696, 96, 1432, 0, 0, 0, 8, "outd3.odm"}
	else
		evt.MoveToMap{17091, -12524, 1, 1024, 0, 0, 0, 8, "out02.odm"}
	end

end
