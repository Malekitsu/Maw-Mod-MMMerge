
local TileSounds = {
[6] = {[0] = 90, 	[1] = 51}
}

function events.TileSound(t)
	local Grp = TileSounds[Game.CurrentTileBin[Map.TileMap[t.X][t.Y]].TileSet]
	if Grp then
		t.Sound = Grp[t.Run]
	end
end

----------------------------------------
-- Loretta Fleise's fix prices quest

Game.MapEvtLines:RemoveEvent(8)
evt.house[8] = 477
evt.map[8] = function() StdQuestsFunctions.CheckPrices(477, 1515) end

Game.MapEvtLines:RemoveEvent(9)
evt.house[9] = 477
evt.map[9] = function() StdQuestsFunctions.CheckPrices(477, 1515) end

Game.MapEvtLines:RemoveEvent(101)
evt.hint[101] = evt.str[2]  -- "Drink from Well."
evt.map[101] = function()
	if evt.Cmp{"MapVar0", Value = 1} then
		if evt.Cmp{"Gold", Value = 5000} then
			evt.Subtract{"Gold", Value = 5000}
			evt.Add{"Experience", Value = 5000}
			evt.Subtract{"MapVar0", Value = 1}
			evt.StatusText{Str = 4}         -- "+5000 Experience, -5000 Gold."
			evt.Set{"AutonotesBits", Value = 434}         -- "5000 Experience and minus 5000 gold from the southern well in the town of Kriegspire."
			return
		end
	end
	evt.StatusText{Str = 10}         -- "Refreshing!"
end

RefillTimer(function()
	evt.Set{"MapVar0", Value = 10}
end, const.Month)

Game.MapEvtLines:RemoveEvent(261)
evt.hint[261] = evt.str[14]  -- "Shrine of Cold"
evt.map[261] = function()
	if not evt.Cmp{"QBits", Value = 1230} then         -- NPC
		evt.Set{"QBits", Value = 1230}         -- NPC
		if evt.Cmp{"QBits", Value = 1240} then         -- NPC
			evt.ForPlayer("All")
			evt.Add{"WaterResistance", Value = 3}
			evt.StatusText{Str = 17}         -- "+3 Cold resistance permanent"
		else
			evt.Set{"QBits", Value = 1240}         -- NPC
			evt.ForPlayer("All")
			evt.Add{"WaterResistance", Value = 10}
			evt.StatusText{Str = 16}         -- "+10 Cold resistance permanent"
		end
		return
	end
	evt.StatusText{Str = 15}         -- "You pray at the shrine."
end

Game.MapEvtLines:RemoveEvent(262)
evt.hint[262] = evt.str[21]  -- "Shrine of Fire"
evt.map[262] = function()
	if not evt.Cmp{"QBits", Value = 1230} then         -- NPC
		evt.Set{"QBits", Value = 1230}         -- NPC
		if evt.Cmp{"QBits", Value = 1238} then         -- NPC
			evt.ForPlayer("All")
			evt.Add{"FireResistance", Value = 3}
			evt.StatusText{Str = 24}         -- "+3 Fire permanent"
		else
			evt.Set{"QBits", Value = 1238}         -- NPC
			evt.ForPlayer("All")
			evt.Add{"FireResistance", Value = 10}
			evt.StatusText{Str = 23}         -- "+10 Fire permanent"
		end
		return
	end
	evt.StatusText{Str = 22}         -- "You pray at the shrine."
end
