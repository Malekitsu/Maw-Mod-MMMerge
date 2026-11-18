-- Sarcophagus

for i = 61, 63 do

	Game.MapEvtLines:RemoveEvent(i)
	evt.hint[i] = evt.str[18]
	evt.Map[i] = function()
		if not evt.Cmp{"MapVar" .. i - 52, 1} then
			local Answer = string.lower(Question(evt.str[20] .. "\n" .. evt.str[21]))
			if Answer == string.lower(evt.str[22]) or Answer == string.lower(evt.str[23]) then
				evt.Set{"MapVar" .. i - 52, 1}
				evt.GiveItem {6, i == 61 and 35 or i == 62 and 36 or i == 63 and 39 or 0, 0}
				evt.Add{"Reputation", 200}
			end
		end
	end

end
