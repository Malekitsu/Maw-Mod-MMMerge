Game.MapEvtLines:RemoveEvent(261)
evt.hint[261] = evt.str[14]  -- "Shrine of Might"
evt.map[261] = function()
	if not evt.Cmp{"QBits", Value = 1230} then         -- NPC
		evt.Set{"QBits", Value = 1230}         -- NPC
		if evt.Cmp{"QBits", Value = 1231} then         -- NPC
			evt.ForPlayer("All")
			evt.Add{"BaseMight", Value = 3}
			evt.StatusText{Str = 17}         -- "+3 Might permanent"
		else
			evt.Set{"QBits", Value = 1231}         -- NPC
			evt.ForPlayer("All")
			evt.Add{"BaseMight", Value = 10}
			evt.StatusText{Str = 16}         -- "+10 Might permanent"
		end
		return
	end
	evt.StatusText{Str = 15}         -- "You pray at the shrine."
end