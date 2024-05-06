
-- Make floor trap multiplayer-friendly

local FloorTrapLights = {}
function events.AfterLoadMap()
	for i, v in Map.Lights do
		if v.Id >= 1 and v.Id <= 8 then
			table.insert(FloorTrapLights, i)
		end
	end
end

local function TrapLightsOff()
	for _,i in pairs(FloorTrapLights) do
		if not Map.Lights[i].Off then
			return false
		end
	end
	return true
end

local function DoorTrapTimer()
	if TrapLightsOff() then
		evt.StopDoor{110}
		evt.StopDoor{111}
		evt.StopDoor{112}
		evt.StopDoor{113}
		evt.SetDoorState{108, 0}
		evt.SetDoorState{109, 0}
		Map.Vars[10] = 15
		RemoveTimer()
	end
end

evt.map[63] = function()
	Timer(DoorTrapTimer, const.Minute)
end

Game.MapEvtLines:RemoveEvent(110)

Game.MapEvtLines:RemoveEvent(45)
evt.hint[45] = evt.str[5]  -- "Button"
evt.map[45] = function()
	evt.SetDoorState{Id = 32, State = 1}
	evt.SetDoorState{Id = 33, State = 1}
	evt.SetDoorState{Id = 34, State = 1}
	evt.SetDoorState{Id = 35, State = 0}
	evt.SetDoorState{Id = 74, State = 1}
	evt.SetDoorState{Id = 75, State = 1}
	evt.SetDoorState{Id = 76, State = 1}
	evt.SetDoorState{Id = 77, State = 0}
end