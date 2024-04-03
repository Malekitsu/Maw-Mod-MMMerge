
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