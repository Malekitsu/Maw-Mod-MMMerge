Game.MapEvtLines:RemoveEvent(196)
evt.hint[196] = "Wine Rack"
evt.map[196] = function()
	local i
	if evt.Cmp{"MapVar4", Value = 2} then
		return
	end
	i = Game.Rand() % 6
	if i == 2 then
		return
	elseif i == 3 or i == 4 then
		goto _12
	elseif i == 5 then
		goto _13
	end
	i = Game.Rand() % 6
	if i == 1 then
		evt.Add{"Inventory", Value = 225}         -- "_potion/reagent"
	elseif i == 2 then
		evt.Add{"Inventory", Value = 229}         -- "_potion/reagent"
	elseif i == 3 then
		evt.Add{"Inventory", Value = 230}         -- "_potion/reagent"
	elseif i == 4 then
		evt.Add{"Inventory", Value = 224}         -- "_potion/reagent"
	elseif i == 5 then
		evt.Add{"Inventory", Value = 240}         -- "_potion/reagent"
	end
::_12::
	i = Game.Rand() % 6
	if i == 4 or i == 5 then
		return
	end
::_13::
	evt.Add{"MapVar4", Value = 1}
end