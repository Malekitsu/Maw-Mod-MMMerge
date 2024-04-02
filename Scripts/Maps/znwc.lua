Game.MapEvtLines:RemoveEvent(61)
evt.hint[61] = evt.str[7]  -- "Potions for sale"
evt.map[61] = function()
	local i
	mapvars.reagentsLooted=mapvars.reagentsLooted or 0
	if mapvars.reagentsLooted>=50 then
		Game.ShowStatusText("empty")
	end
	if not evt.Cmp{"Gold", Value = 100} then
		evt.StatusText{Str = 6}         -- "Not enough gold"
	else
		evt.StatusText{Str = 4}         -- "You found something!"
		i = Game.Rand() % 6
		if i == 1 then
			evt.Add{"Inventory", Value = 220}         -- "Potion Bottle"
			evt.Subtract{"Gold", Value = 50}
		elseif i == 2 then
			evt.Add{"Inventory", Value = 221}         -- "Catalyst"
			evt.Subtract{"Gold", Value = 20}
		elseif i == 3 then
			evt.Add{"Inventory", Value = 221}         -- "Catalyst"
			evt.Subtract{"Gold", Value = 100}
		elseif i == 4 then
			evt.Add{"Inventory", Value = 222}         -- "Cure Wounds"
			evt.Subtract{"Gold", Value = 50}
		elseif i == 5 then
			evt.Add{"Inventory", Value = 223}         -- "Magic Potion"
			evt.Subtract{"Gold", Value = 20}
		else
			evt.Add{"Inventory", Value = 224}         -- "Cure Weakness"
			evt.Subtract{"Gold", Value = 50}
		end
		mapvars.reagentsLooted=mapvars.reagentsLooted+1
	end
end