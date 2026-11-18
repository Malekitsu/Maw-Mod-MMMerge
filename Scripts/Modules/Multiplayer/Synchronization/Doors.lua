local events = Multiplayer.events
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
local toptr = mem.topointer
local LogEvent = Multiplayer.utils.LogEvent

local END_TIMESTEP = 15632

local last_door_state, need_update = {}, {}
local indoor_handler, outdoor_handler

Multiplayer.debug.door_handler_on = false

local function set_state(door, state, timestep, bits)
	if state == 0 then
		door.State = 3
		door.TimeStep = END_TIMESTEP
	elseif state == 2 then
		door.State = 1
		door.TimeStep = END_TIMESTEP
	else
		door.State = state
		door.TimeStep = timestep or END_TIMESTEP
	end
	door.Bits = bits or door.Bits
	
	if state >= 100 then
		door.Stopped = true
	end
end

local function get_state(door)
	local state = door.State
	if state == 0 or state == 2 or door.TimeStep ~= END_TIMESTEP then
		-- do nothing
	elseif state == 3 then
		state = 0
	elseif state == 1 then
		state = 2
	end
	
	if door.Stopped then
		state = state + 100
	end
	return state
end

local packets = {
	tell_door_states = {
		bulb = function()
			local t = {}
			if Map.IsIndoor() then
				for k, v in Map.Doors do
					if need_update[k] then
						t[k] = {v.State, v.TimeStep, v.Bits}
						need_update[k] = false
					end
				end
			else
				for k, v in pairs(OutdoorAnimObjects.DoorSettings) do
					if need_update[k] then
						t[k] = {v.State, v.TimeStep}
						need_update[k] = false
					end
				end
			end

			return item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			local t = bin_to_item(toptr(bin_string))
			if Map.IsIndoor() then
				for i, v in pairs(t) do
					local door = Map.Doors[i]
					set_state(door, v[1], v[2], v[3])
					last_door_state[i] = get_state(door)
				end
			else
				for k, v in pairs(t) do
					local d = OutdoorAnimObjects.DoorSettings[k]
					d:set_state(v[1], v[2])
					last_door_state[k] = d.State
				end
			end
		end,
		check_delivery = true,
		same_map_only = true,
		compress = true,
	},
}
Multiplayer.utils.init_packets(packets)

indoor_handler = function()
	if not Map.IsIndoor() or Multiplayer.leave_map_halt then
		return
	end

	Multiplayer.debug.door_handler_on = true

	local have = false
	local state
	for i, v in Map.Doors do
		state = get_state(v)
		if state ~= last_door_state[i] then
			need_update[i] = true
			last_door_state[i] = state
			have = true
		end
	end

	if have then
		Multiplayer.broadcast(packets.tell_door_states:prep(), Multiplayer.utils.cond_same_map)
	end
end

outdoor_handler = function()
	local Doors = OutdoorAnimObjects.DoorSettings

	if not Doors or Map.IsIndoor() or Multiplayer.leave_map_halt then
		return
	end

	Multiplayer.debug.door_handler_on = true

	local have = false
	local state
	for k, v in pairs(Doors) do
		state = v.State
		if state ~= last_door_state[k] then
			need_update[k] = true
			last_door_state[k] = state
			have = true
		end
	end

	if have then
		Multiplayer.broadcast(packets.tell_door_states:prep(), Multiplayer.utils.cond_same_map)
	end
end

local function start_door_handler()
	table.clear(last_door_state)
	table.clear(need_update)

	while events.Remove("Tick", indoor_handler) do end
	while events.Remove("Tick", outdoor_handler) do end

	if Map.IsIndoor() then
		events.Tick = indoor_handler
	else
		events.Tick = outdoor_handler
	end
end

events.MapLoadingDone = start_door_handler
events.MultiplayerStarted = start_door_handler

function events.EvtCommandCall(t)
	if t.evt_id == 15 or t.evt_id == 63 then -- evt.SetDoorState, evt.StopDoor
		need_update[mem.u1[t.params]] = true
	end
end

-- Map load

function events.MultiplayerPrepMapData(t)
	if Map.IsIndoor() then
		t.MapDoors = {}
		for i, v in Map.Doors do
			t.MapDoors[i] = {v.State, v.TimeStep, v.Bits}
		end
	end
end

function events.MultiplayerProcessMapData(t)
	LogEvent("MAP_LOAD", "Processing doors info: %s.", type(t.MapDoors))
	if not t.MapDoors then
		return
	end

	if Map.IsIndoor() then
		for i, v in Map.Doors do
			local d = t.MapDoors[i]
			if d then
				set_state(v, d[1], d[2], d[3])
				need_update[i] = false
				last_door_state[i] = get_state(v)
			end
		end
	end

	start_door_handler()
end
