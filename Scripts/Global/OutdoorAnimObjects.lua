OutdoorAnimObjects = {}

local DoorTimers = {}
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, abs
local rad, sqrt, sin, acos = math.rad, math.sqrt, math.sin, math.acos

-- Doors setup
local DoorSettings = {}
OutdoorAnimObjects.DoorSettings = DoorSettings

local function calc_door_shift(t, TimeStep)
	local X, Y, Z
	local m = t.Model

	if TimeStep <= 0 then
		X, Y, Z = t.sx - m.X, t.sy - m.Y, t.sz - m.Z
	elseif TimeStep >= t.Time then
		X, Y, Z = t.sx - t.dx, t.sy - t.dy, t.sz - t.dz
		X, Y, Z = X - m.X, Y - m.Y, Z - m.Z
	else
		local k = TimeStep / t.Time
		X, Y, Z = t.dx * k, t.dy * k, t.dz * k
		X, Y, Z = t.sx - X, t.sy - Y, t.sz - Z
		X, Y, Z = floor(X - m.X), floor(Y - m.Y), floor(Z - m.Z)
	end

	return X, Y, Z
end

local function pos_door(t, TimeStep)
	TimeStep = TimeStep or t.TimeStep
	local X, Y, Z = calc_door_shift(t, TimeStep)
	t.TimeStep = min(max(TimeStep, 0), t.Time)
	MoveModel(t.Model, X, Y, Z, t.MoveParty)
end
OutdoorAnimObjects.SetDoorPosition = pos_door

--m, dx, dy, dz, Time, Period, MoveParty, Normal, NFacetId, StopSound
local function MoveModelOverTime(t)

	local EndTime = Game.Time + t.Time - (t.State == 3 and t.Time - t.TimeStep or t.TimeStep)
	--t.TimeStep = t.State == 3 and 0 or t.Time

	local f = function()
		local TimeStep = t.State == 3 and (EndTime - Game.Time) or (t.Time - EndTime + Game.Time)
		local Last = TimeStep <= 0 or TimeStep >= t.Time
		t.LastMove = Game.Time
		pos_door(t, TimeStep)

		if Last then
			RemoveTimer(DoorTimers[t.Model.Name])
			t.State = t.State == 3 and 0 or 2
			t.InMove = false
			if t.StopSound then
				Game.PlaySound(t.StopSound)
			end
		end
	end

	DoorTimers[t.Model.Name] = f
	Timer(f, t.Period)

end
OutdoorAnimObjects.MoveModelOverTime = MoveModelOverTime

local function FindModel(Name)
	for i,v in Map.Models do
		if v.Name == Name then
			return v
		end
	end
end
OutdoorAnimObjects.FindModel = FindModel

local function SwitchDoor2(t, To)
	if not t then
		return false
	end

	if DoorTimers[t.Model.Name] then
		RemoveTimer(DoorTimers[t.Model.Name])
	end

	if To == t.Closed then
		return true
	end

	t.InMove = true
	if t.StartSound then
		Game.PlaySound(t.StartSound)
	end

	t.State = t.Closed and 3 or 1
	t.Closed = not t.Closed
	MoveModelOverTime(t)

	return true
end

local function SwitchDoor(Model, To)
	local t

	if type(Model) == "string" then
		t = DoorSettings[Model]
	else
		t = DoorSettings[Model.Name]
	end

	return SwitchDoor2(t, To)
end
OutdoorAnimObjects.SwitchDoor = SwitchDoor

local function set_state(t, State, TimeStep)
	if State == 0 then
		t:pos(0)
		t.Closed = false
	elseif State == 2 then
		t:pos(t.Time)
		t.Closed = true
	elseif State == 1 then
		t:pos(TimeStep or 0)
		t.Closed = false
		t:switch()
	elseif State == 3 then
		t:pos(TimeStep or t.Time)
		t.Closed = true
		t:switch()
	end
end

-- Model, EvtId, DefState, ApplyEvt, Closed, dx, dy, dz,
-- Time, Period, MoveParty, Normal, Fid, Condition, StartSound, StopSound
local function SetDoor(t)

	if type(t.Model) == "string" then
		t.Model = FindModel(t.Model)
	end

	if not t.Model then
		return
	end

	if t.EvtId then
		for i,v in t.Model.Facets do
			v.Event = t.EvtId
			v.TriggerByClick = true
		end
	end

	t.sx = t.Model.X
	t.sy = t.Model.Y
	t.sz = t.Model.Z
	if t.Closed then
		t.sx = t.sx + t.dx
		t.sy = t.sy + t.dy
		t.sz = t.sz + t.dz
	end

	-- 0 - open
	-- 1 - closing
	-- 2 - closed
	-- 3 - opening
	t.State = t.Closed and 2 or 0
	t.TimeStep = t.Closed and t.Time or 0

	t.pos = pos_door
	t.calc_shift = calc_door_shift
	t.set_state = set_state
	t.switch = SwitchDoor2

	t.InMove = false
	DoorSettings[t.Model.Name] = t

end
OutdoorAnimObjects.SetDoor = SetDoor

function events.LeaveMap()
	table.clear(DoorSettings)
end

