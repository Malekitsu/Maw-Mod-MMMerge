
-- Rescue dwarfs quest (mm7)

for i = 0, 5 do
	evt.Map[376+i] = function()
		if evt.ForPlayer("All").Cmp{"Inventory", Value = 1431} then
			NPCFollowers.Add(400+i)
		end
	end
end

evt.Map[382] = function()
	if evt.ForPlayer("All").Cmp{"Inventory", Value = 1431} then
		NPCFollowers.Add(399)
	end
end

Game.MapEvtLines:RemoveEvent(151)
evt.map[151] = function()
	evt.SetDoorState{Id = 1, State = 2}         -- switch state
	evt.SetDoorState{Id = 2, State = 2}         -- switch state
end