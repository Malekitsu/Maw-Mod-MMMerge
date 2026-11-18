Game.MapEvtLines:RemoveEvent(69)
evt.hint[69] = ""
evt.Map[69] = function()
	if not evt.Cmp{"MapVar6", 1} then
		local Answer = Question(evt.str[21] .. "\n" .. evt.str[14])
		if string.lower(Answer) == evt.str[16] then
			evt.Set{"MapVar6", 1}
			Game.ShowStatusText(evt.str[19])
		else
			evt.MoveToMap {-3136, 2240, 224, 1024, 0, 0, 0, 0, "0"}
			Game.ShowStatusText(evt.str[17])
		end
	end
end
