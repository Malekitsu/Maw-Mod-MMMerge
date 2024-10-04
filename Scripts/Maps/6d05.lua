--snergle door fix
Game.MapEvtLines:RemoveEvent(9)
evt.hint[9] = evt.str[2]  -- "Door"
evt.map[9] = function()
	if evt.Cmp{"Inventory", Value = 2108} then         -- "Key to Snergle's Chambers"
		evt.SetDoorState{Id = 9, State = 1}
		evt.Subtract{"Inventory", Value = 2108}         -- "Key to Snergle's Chambers"
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 2, Count = 3, X = 387, Y = 8721, Z = 257, NPCGroup = 0, unk = 0}
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 3, Count = 3, X = 420, Y = 8538, Z = 257, NPCGroup = 0, unk = 0}
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 2, Count = 3, X = 44, Y = 8517, Z = 247, NPCGroup = 0, unk = 0}
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 3, Count = 3, X = -208, Y = 8507, Z = 257, NPCGroup = 0, unk = 0}
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 2, Count = 3, X = -455, Y = 8588, Z = 247, NPCGroup = 0, unk = 0}
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 3, Count = 3, X = -556, Y = 8573, Z = 257, NPCGroup = 0, unk = 0}
	else
		evt.StatusText{Str = 28}         -- "The door is locked"
	end
end

