
----------------------------------------
-- Loretta Fleise's fix prices quest

Game.MapEvtLines:RemoveEvent(8)
evt.house[8] = 474
evt.map[8] = function() StdQuestsFunctions.CheckPrices(474, 1520) end

Game.MapEvtLines:RemoveEvent(9)
evt.house[9] = 474
evt.map[9] = function() StdQuestsFunctions.CheckPrices(474, 1520) end


Game.MapEvtLines:RemoveEvent(261)
evt.hint[261] = evt.str[8]  -- "Shrine of Speed"
evt.map[261] = function()
	if not evt.Cmp{"QBits", Value = 1230} then         -- NPC
		evt.Set{"QBits", Value = 1230}         -- NPC
		if evt.Cmp{"QBits", Value = 1236} then         -- NPC
			evt.ForPlayer("All")
			evt.Add{"BaseSpeed", Value = 3}
			evt.StatusText{Str = 11}         -- "+3 Speed permanent"
		else
			evt.Set{"QBits", Value = 1236}         -- NPC
			evt.ForPlayer("All")
			evt.Add{"BaseSpeed", Value = 10}
			evt.StatusText{Str = 10}         -- "+10 Speed permanent"
		end
		return
	end
	evt.StatusText{Str = 9}         -- "You pray at the shrine."
end