
-- Key to Gharik's Laborator

Game.MapEvtLines:RemoveEvent(16)
evt.hint[16] = evt.str[2]
evt.Map[16] = function()
	if not evt.ForPlayer("All").Cmp{"Inventory", 2107} or evt.Cmp{"MapVar4", 1} then
		evt.Set{"MapVar4", 1}
	 	evt.Set{"QBits", 1035}
	 	evt.Set{"QBits", 1223}
		evt.OpenChest{1}
	else
		evt.OpenChest{6}
	end
end
