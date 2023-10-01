
function events.LoadMap()
	for i = 5, 8 do
		evt.SetDoorState(i, 1)
	end
	for i = 9, 10 do
		evt.SetDoorState(i, 0)
	end
end

--Game.MapEvtLines:RemoveEvent(51)

--MAW
if not mapvars.maw then
	mapvars.maw=true
	mawmapvarsend("maw",true)
	pseudoSpawnpoint{monster = 397, x = -3954, y = 5878, z = -95, count = 3, powerChances = {100, 0, 0}, radius = 64, group = 1}
	pseudoSpawnpoint{monster = 397, x = -3954, y = 5878, z = -95, count = 1, powerChances = {0, 100, 0}, radius = 64, group = 1}
end