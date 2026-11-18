
local function TellPassword(Text, QText, An1, An2, Door)
	local Answer = string.lower(Question(evt.str[Text] .. "\n" .. evt.str[QText]))
	if Answer == string.lower(evt.str[An1]) or Answer == string.lower(evt.str[An2]) then
		evt.SetDoorState{Door, 1}
	else
		Game.ShowStatusText(evt.str[22])
	end
end

Game.MapEvtLines:RemoveEvent(61)
evt.hint[61] = evt.str[16]
evt.Map[61] = function() TellPassword(18, 21, 19, 20, 61) end

Game.MapEvtLines:RemoveEvent(62)
evt.hint[62] = evt.str[16]
evt.Map[62] = function() TellPassword(23, 21, 24, 25, 62) end

Game.MapEvtLines:RemoveEvent(63)
evt.hint[63] = evt.str[16]
evt.Map[63] = function() TellPassword(26, 21, 27, 27, 63) end

Game.MapEvtLines:RemoveEvent(64)
evt.hint[64] = evt.str[16]
evt.Map[64] = function() TellPassword(28, 21, 29, 30, 64) end

-- Fix spike trap
Map.Facets[373].PolygonType = 5
