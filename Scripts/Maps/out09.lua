
-- Show obelisk treasure

local Treasure
for i,v in Map.Sprites do
	if v.Event == 170 then
		Treasure = v
		break
	end
end

local Av = true
for i = 676, 689 do
	Av = Av and Party.QBits[i]
end

if Av and Treasure then

	local function SetTrViz()
		Treasure.Invisible = Game.Hour ~= 0
	end

	Timer(SetTrViz, const.Hour/2, true)

end

-- Dimension door

evt.map[6] = TownPortalControls.DimDoorEvent

function events.AfterLoadMap()

	local function DimDoor()
		if 1500 > math.sqrt((-5121-Party.X)^2 + (98-Party.Y)^2) then
			TownPortalControls.DimDoorEvent()
		end
	end
	Timer(DimDoor, false, const.Minute*3)

end
