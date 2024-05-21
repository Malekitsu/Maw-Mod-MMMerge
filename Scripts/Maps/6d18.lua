
-- Make lava damage multiplayer-friendly

if Multiplayer then
	Multiplayer.mm_mapvar_nosync(0)
end

Game.MapEvtLines:RemoveEvent(35)

evt.hint[35] = evt.str[2]  -- "Lever"
evt.map[35] = function()
	evt.SetDoorState{Id = 43, State = 2}         -- switch state
	evt.SetDoorState{Id = 53, State = 2}         -- switch state
	if Map.Facets[2255].Invisible==false then
		Map.Facets[2255].Invisible=true
		Map.Facets[2255].Untouchable=true
	else
		Map.Facets[2255].Invisible=false
		Map.Facets[2255].Untouchable=false
	end
end