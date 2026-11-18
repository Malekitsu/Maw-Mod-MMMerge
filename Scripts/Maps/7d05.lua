
Game.NPC[639].EventA = 704
Game.NPC[639].EventC = 0

for i,v in Map.Doors do
	v.NoSound = true
	v.SilentMove = true
end

function events.CanSaveGame(t)
	t.IsArena = true
	t.Result = false
end

function events.CanCastLloyd(t)
	t.Result = false
end