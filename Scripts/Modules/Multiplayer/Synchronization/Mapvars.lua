local events = Multiplayer.events
local LogEvent = Multiplayer.utils.LogEvent

-- Only manually specified mapvars will be tracked and sent
local watches = {
	["pbp.odm"] = {"AirPrisonOpen", "FirePrisonOpen", "WaterPrisonOpen", "EarthPrisonOpen"},
	["out02.odm"] = {"CrystalOpened"},
}

-- Manually specified indicies from Map.Vars, that should not be syncronized
local nosync = {}

function Multiplayer.mapvar_watch(varname, mapname)
	mapname = mapname or Map.Name

	if type(varname) == 'table' then
		for _, v in pairs(varname) do
			Multiplayer.mapvar_watch(v, mapname)
		end
		return
	end

	local t = watches[mapname]
	if not t then
		t = {}
		watches[mapname] = t
	end

	if not table.find(t, varname) then
		table.insert(t, varname)
	end
end

function Multiplayer.mm_mapvar_nosync(id, mapname)
	mapname = mapname or Map.Name

	if type(id) == 'table' then
		for _, v in pairs(id) do
			Multiplayer.mm_mapvar_nosync(v, mapname)
		end
		return
	end

	local t = nosync[mapname]
	if not t then
		t = {}
		nosync[mapname] = t
	end

	t[id] = true
end

local last_state = {}
local last_state_mm = {} -- Map.Vars

local packets = {
	mapvars_changes = {
		bulb = Multiplayer.utils.item_to_bin,
		handler = function(bin_string, metadata)
			local changes = Multiplayer.utils.binstr_to_item(bin_string)
			for k, v in pairs(changes) do
				mapvars[k] = v
				last_state[k] = v
				LogEvent("SYNC", "Received remote value of mapvar %s: %s", k, v)
			end
		end,
		compress = true,
		same_map_only = true,
		check_delivery = true
	},

	mm_mapvars_changes = {
		bulb = Multiplayer.utils.item_to_bin,
		handler = function(bin_string, metadata)
			local changes = Multiplayer.utils.binstr_to_item(bin_string)
			for k, v in pairs(changes) do
				Map.Vars[k] = v
				last_state_mm[k] = v
				LogEvent("EVENTS", "Received remote value of MM mapvar %s: %s", k, v)
			end
		end,
		compress = true,
		same_map_only = true,
		check_delivery = true
	},
}
Multiplayer.utils.init_packets(packets)

local function OnLoad()
	local mm_nosync = nosync[Map.Name]
	if mm_nosync then
		for i, v in Map.Vars do
			if not mm_nosync[i] then
				last_state_mm[i] = v
			end
		end
	else
		for i, v in Map.Vars do
			last_state_mm[i] = v
		end
	end

	table.clear(last_state)
	local t = watches[Map.Name:lower()]
	if t then
		for _, v in pairs(t) do
			last_state[v] = mapvars[v] or false
		end
	end
end

events.MapLoadingDone = OnLoad
events.MultiplayerStarted = OnLoad

function events.LeaveMap()
	table.clear(last_state)
	table.clear(last_state_mm)
end

function events.EvtMap(i)
	local function checker()
		--LogEvent("SYNC", "Checking mapvars after map event %s", i)

		local diff = {}
		for k, v in pairs(last_state) do
			if mapvars[k] ~= v then
				local val = mapvars[k] or false -- nil won't be sent
				diff[k] = val
				last_state[k] = val
				mapvars[k] = val
			end
		end
		if next(diff) then
			Multiplayer.broadcast(packets.mapvars_changes:prep(diff), Multiplayer.utils.cond_same_map)
		end

		local diff = {}
		for i, v in pairs(last_state_mm) do
			local new = Map.Vars[i]
			if v ~= new then
				diff[i] = new
				last_state_mm[i] = new
			end
		end
		if next(diff) then
			Multiplayer.broadcast(packets.mm_mapvars_changes:prep(diff), Multiplayer.utils.cond_same_map)
		end
	end

	Multiplayer.utils.delayed_call(checker, 1)
end

function events.MultiplayerPrepMapData(t)
	t.map_vars = Multiplayer.utils.mmt_dump(Map.Vars)
	t.mapvars = mapvars
end

function events.MultiplayerProcessMapData(t)
	LogEvent("MAP_LOAD", "Processing binary mapvars: %s.", type(t.monsters))
	if t.map_vars then
		mem.copy(Map.Vars['?ptr'], t.map_vars)
	end

	LogEvent("MAP_LOAD", "Processing lua mapvars: %s.", type(t.monsters))
	if t.mapvars then
		for k,v in pairs(t.mapvars) do
			mapvars[k] = v
		end

		if mapvars.MapNPCNews then
			NPCFollowers.LoadRandomNPCs(mapvars.MapNPCNews)
			for client_id, mon_id in pairs(Multiplayer.client_monsters()) do
				local mon = Multiplayer.get_client_mon(client_id)
				if mon then
					mon.NPC_ID = 0
				end
			end
		end
	end
end
