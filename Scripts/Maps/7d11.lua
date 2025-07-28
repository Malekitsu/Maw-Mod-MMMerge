if evt.Cmp{"MapVar15", Value = 1} and evt.Cmp{"MapVar16", Value = 1} and evt.Cmp{"MapVar17", Value = 1} then
	evt.SetDoorState{Id = 1, State = 0}
	evt.SetDoorState{Id = 2, State = 0}
end