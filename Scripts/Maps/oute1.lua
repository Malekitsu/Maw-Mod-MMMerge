Game.MapEvtLines:RemoveEvent(261)
evt.hint[261] = evt.str[7]  -- "Shrine of Poison"
evt.map[261] = function()
	if not evt.Cmp{"QBits", Value = 1230} then         -- NPC
		evt.Set{"QBits", Value = 1230}         -- NPC
		if evt.Cmp{"QBits", Value = 1241} then         -- NPC
			evt.ForPlayer("All")
			evt.Add{"EarthResistance", Value = 3}
		else
			evt.Set{"QBits", Value = 1241}         -- NPC
			evt.ForPlayer("All")
			evt.Add{"EarthResistance", Value = 10}
			evt.StatusText{Str = 9}         -- "+10 Poison resistance permanent"
		end
		return
	end
	evt.StatusText{Str = 8}         -- "You pray at the shrine."
end

