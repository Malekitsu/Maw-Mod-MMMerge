
function events.LoadMap()
	for i,v in Party do
		SetCharFace(i, 30)
	end
end

function events.LeaveMap()
	for i,v in Party do
		SetCharFace(i, v.Face)
	end
end

function events.Action(t)
	if t.Action == 133 or Mouse.Item.Number == 1406 and not (t.Action == 120 or t.Action == 12) or t.Action == 105 then
		t.Handled = true
		evt.PlaySound{27}
		Game.ShowStatusText(Game.GlobalTxt[652])
	end
end

local LastAt = true
function events.Tick()
	if Party.Z > 3900 then
		if LastAt and Game.CurrentScreen == 0 then
			LastAt = false
			evt.MoveToMap{-18584, -16562, 1, 290, 0, 0, 0, 8, "out14.odm"}
		end
	else
		LastAt = true
	end
end
