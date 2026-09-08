local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer

local binstr_to_item = Multiplayer.utils.binstr_to_item
local tkeys = Multiplayer.utils.tkeys
local item_to_bin = Multiplayer.utils.item_to_bin
local bin_to_item = Multiplayer.utils.bin_to_item
local nums_to_bin = Multiplayer.utils.nums_to_bin
local mmt_dump = Multiplayer.utils.mmt_dump
local fill_from_bin = Multiplayer.utils.fill_from_bin
local num_to_hexstr = Multiplayer.utils.num_to_hexstr
local num_from_hexstr = Multiplayer.utils.num_from_hexstr

local LogEvent = Multiplayer.utils.LogEvent

----------------------------------------------------------
-- ddm / blv

local read_ddm_dlv, save_ddm_dlv, name_ddm_dlv

do
	local fread = offsets.fread
	local fclose = 0x4da20b
	local NewLod = 0x6ce5f8

	function read_ddm_dlv(name)
		local file_handle = mem.call(0x45efff, 1, NewLod, mem.topointer(name), 1)
		if file_handle == 0 then
			return
		end

		local file_header = mem.malloc(0x10)
		mem.call(fread, 0, file_header, 0x10, 1, file_handle)
		local FileSize = mem.u4[file_header + 0x8]

		local content
		local MapBuff = mem.malloc(FileSize)
		local Read = mem.call(fread, 0, MapBuff, FileSize, 1, file_handle)
		if Read == 1 then
			content = mem.string(file_header, 0x10, true) .. mem.string(MapBuff, FileSize, true)
		end
		mem.free(MapBuff)
		mem.free(file_header)

		-- MM uses one handle for new.lod and repositions it every time find performed, fclose is unnecessary
		--mem.call(fclose, 0, file_handle)
		return content
	end

	function save_ddm_dlv(name, binstr)
		local save_header = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
		local save_header_ptr = mem.topointer(save_header)
		mem.copy(save_header_ptr, name, #name)
		mem.u4[save_header_ptr + 0x14] = #binstr
		return mem.call(offsets.SaveFileToLod, 1, NewLod, save_header_ptr, mem.topointer(binstr), 0)
	end

	function name_ddm_dlv(map_id)
		local FileName = Game.MapStats[map_id].FileName
		if FileName:find("odm") then
			return FileName:replace("odm", "ddm")
		elseif FileName:find("blv") then
			return FileName:replace("blv", "dlv")
		end
		return nil
	end
end

----------------------------------------------------------

local MAP_DATA_VERSION = 4
Multiplayer.LoadMapData = {}

local bin_export, bin_import

local function mdata_storage(mapid, data)
	local t = vars.MultiplayerMapData
	if not t then
		t = {}
		vars.MultiplayerMapData = t
	end

	if not mapid then
		return t
	end

	if data then
		t[mapid] = Multiplayer.compress(item_to_bin(data))
	elseif t[mapid] then
		local data = t[mapid]
		if type(data) == "string" then
			local f = function()
				return binstr_to_item(Multiplayer.decompress(t[mapid]))
			end
			local success, result = pcall(f)
			if success then
				return result
			else
				LogEvent("MAP_LOAD", "[ERROR] Could not fetch saved data of map %s", mapid)
				t[mapid] = nil
			end
		else
			return data
		end
	end
end
Multiplayer.SavedMapData = mdata_storage

bin_export = {

	map_facet_bits = function()
		local fbits = {}

		if Map.IsIndoor() then
			for i, v in Map.Facets do
				if v.Invisible or v.Untouchable then
					fbits[i] = v.Bits
				end
			end
		else
			for mi, m in Map.Models do
				for fi, f in m.Facets do
					if f.Invisible or f.Untouchable then
						fbits[fi + bit.lshift(mi, 16)] = f.Bits
					end
				end
			end
		end

		return fbits
	end,

	map_data = function()
		local parts = {}
		local tinsert, tmp = table.insert, nil

		parts.fbits = bin_export.map_facet_bits()
		if Map.IsOutdoor() then
			parts.mbits = {}
			for i, m in Map.Models do
				parts.mbits[i] = m.Bits
			end
		end

		return item_to_bin(parts)
	end,

}

bin_import = {

	map_facet_bits = function(fbits)
		if not fbits then
			return
		end

		if Map.IsIndoor() then
			for i, v in Map.Facets do
				v.Invisible = false
				v.Untouchable = false
			end

			for i, v in pairs(fbits) do
				Map.Facets[i].Bits = v
			end
		else
			for mi, m in Map.Models do
				for fi, f in m.Facets do
					f.Invisible = false
					f.Untouchable = false
				end
			end

			local m, f
			for i, v in pairs(fbits) do
				m, f = bit.rshift(i, 16), bit.And(i, 0xFFFF)
				Map.Models[m].Facets[f].Bits = v
			end
		end

		return fbits
	end,

	map_data = function(data)
		local map_data = bin_to_item(data)

		bin_import.map_facet_bits(map_data.fbits)
		if Map.IsOutdoor() and map_data.mbits then
			for i, v in pairs(map_data.mbits) do
				Map.Models[i].Bits = v
			end
		end
	end,

}

local function prep_map_data(t)
	t = t or {}
	t._VERSION = MAP_DATA_VERSION
	t.GameTime = Game.Time
	t.DataMapStatsIndex = Map.MapStatsIndex
	t.MapName = Map.Name
	t.LastRefillDay = Map.LastRefillDay
	if Map.IsOutdoor() and Map.LoadedSkyBitmap < Game.BitmapsLod.Bitmaps.count then
		t.LoadedSkyBitmap = Game.BitmapsLod.Bitmaps[Map.LoadedSkyBitmap].Name
	end
	t.map = bin_export.map_data()

	events.call("MultiplayerPrepMapData", t)
	return t
end
Multiplayer.prep_map_data = prep_map_data

local function process_map_data(data, actual)
	LogEvent("MAP_LOAD", "Processing map data: %s", data.MapName)

	if data._VERSION ~= MAP_DATA_VERSION then
		LogEvent("MAP_LOAD", "Wrong version of received map data: %s, supported version: %s. Generating map data myself.", data._VERSION, MAP_DATA_VERSION)
		return
	end

	if data.DataMapStatsIndex ~= Map.MapStatsIndex then
		LogEvent("MAP_LOAD", "Received wrong map data: received id - %s, mine - %s !!!", data.DataMapStatsIndex, Map.MapStatsIndex)
		return
	end

	if data.ddmdlv then
		LogEvent("MAP_LOAD", "Received raw %s, loading it.", data.name)
		save_ddm_dlv(data.name, data.bin)
		return
	end

	bin_import.map_data(toptr(data.map))
	if Map.IsOutdoor() and data.LoadedSkyBitmap then
		LogEvent("MAP_LOAD", "Setting sky bitmap: %s", data.LoadedSkyBitmap)
		SetSkyTexture(data.LoadedSkyBitmap)
	end

	if actual then
		if data.GameTime then
			LogEvent("MAP_LOAD", "Received data is actual, setting GameTime.")
			Game.Time = data.GameTime
		end
		if data.LastRefillDay then
			LogEvent("MAP_LOAD", "LastRefillDay field set to %s.", data.LastRefillDay)
			Map.LastRefillDay = data.LastRefillDay
		end
	end

	data.Actual = actual
	LogEvent("EVENTS", "Calling MultiplayerProcessMapData event.")
	events.call("MultiplayerProcessMapData", data, actual)
	LogEvent("MAP_LOAD", "Map data processed.")
end
Multiplayer.process_map_data = process_map_data

local packets = {

	request_map_data = {
		bulb = function(map_stats_index, accept_ddm_dlv)
			return item_to_bin({map_stats_index, accept_ddm_dlv})
		end,
		handler = function(bin_string, metadata)
			local data = binstr_to_item(bin_string)
			local map_id, accept_ddm_dlv = data[1], data[2]
			data = false

			LogEvent("MAP_LOAD", "Received map data %s request (my map - %s).", map_id, Map.MapStatsIndex)

			if Map.MapStatsIndex == map_id then
				if Multiplayer.leave_map_halt then
					if Multiplayer.my_id > metadata.sender_id then
						return false
					else
						LogEvent("MAP_LOAD", "Queueing delayed response.")
						events.Once("MapLoadingDone", function()
							LogEvent("MAP_LOAD", "Sending response after delay: map data %s.", map_id)
							Multiplayer.send_response(Multiplayer.packet_by_code[metadata.packet_code], metadata, prep_map_data())
						end)
						return nil -- delayed response
					end
				else
					LogEvent("MAP_LOAD", "I am at requested map, will generate and send data.")
					data = prep_map_data()
				end
			elseif Multiplayer.im_host() then
				data = mdata_storage(map_id)
				if data and data._VERSION == MAP_DATA_VERSION then
					LogEvent("MAP_LOAD", "I am host and i have previously generated map data, will send it.")
				else
					data = false
					if accept_ddm_dlv then
						local FileName = name_ddm_dlv(map_id)
						if FileName then
							data = read_ddm_dlv(FileName) or false
							if data then
								LogEvent("MAP_LOAD", "I am host sending raw ddm / dlv.")
								data = {
									_VERSION = MAP_DATA_VERSION,
									MapName = Game.MapStats[map_id].FileName,
									ddmdlv = true,
									name = FileName,
									bin = data,
									DataMapStatsIndex = map_id}
							end
						end
					end
				end
			end

			LogEvent("MAP_LOAD", "Responding with %s.", tostring(data))
			return data
		end,
		response = 'send_map_data',
		check_delivery = true,
		ignore_reload_count = true
	},

	send_map_data = {
		bulb = function(handler_result)
			return item_to_bin(handler_result)
		end,
		handler = function(bin_string, metadata)
			local data = binstr_to_item(bin_string)
			LogEvent("MAP_LOAD", "Received response to map data request: %s", tostring(data))
			if data then
				return data
			end
			return false
		end,
		check_delivery = true,
		compress = true,
		ignore_reload_count = true
	},

	notify_host_about_map_changes = {
		bulb = function()
			return item_to_bin(prep_map_data())
		end,
		handler = function(bin_string, metadata)
			local data = bin_to_item(toptr(bin_string))
			local map_id = data.DataMapStatsIndex
			LogEvent("MAP_LOAD", "Received map #%s (%s) data from client #%s", map_id, Game.MapStats[map_id].FileName, metadata.sender_id)
			mdata_storage(map_id, data)
		end,
		check_delivery = true,
		compress = true
	},

	notify_map_change = {
		bulb = function()
			return num_to_hexstr(Map.MapStatsIndex)
		end,
		handler = function(bin_string, metadata)
			Multiplayer.client_info(metadata.sender_id).map = num_from_hexstr(bin_string)
			return ""
		end,
		response = "approve_map_change",
		check_delivery = true,
		ignore_reload_count = true,
	},

	approve_map_change = {
		ignore_reload_count = true
	}
}
Multiplayer.utils.init_packets(packets)

-- Init data events

local function ClearLoadMapData()
	table.clear(Multiplayer.LoadMapData)
end

events.MultiplayerStarted = ClearLoadMapData
events.GatherClientInitData = ClearLoadMapData
events.MultiplayerRoleChanged = ClearLoadMapData

function events.GatherServerInitData(t)
	t.MapData = prep_map_data()
end

function events.ProcessServerInitData(t)
	vars.MultiplayerMapData = {}

	local data = t.MapData
	if Map.Name == data.MapName then
		LogEvent("CONNECTION", "Received initial map data from server. Same map.")
		process_map_data(data)
	else
		LogEvent("CONNECTION", "Received initial map data from server. Map differs (%s, %s). Will process data after map load.", Map.Name, data.MapName)
		Multiplayer.LoadMapData[data.DataMapStatsIndex] = data

		-- Map change upon joining game handled by SaveLoadExit.lua
	end
end

-- Handlers

local function get_client_map_data(client_id, map_id, accept_ddm_dlv)
	LogEvent("MAP_LOAD", "%s: asking player #%s.", Game.MapStats[map_id].FileName, client_id)
	return Multiplayer.send_wait_response(client_id, packets.request_map_data, 12, map_id, accept_ddm_dlv)
end
Multiplayer.get_client_map_data = get_client_map_data

local function get_remote_map_data(map_id)
	local got_response, response
	local filename = Game.MapStats[map_id].FileName

	LogEvent("MAP_LOAD", "%s: asking players for map data.", filename)
	for client_id, client in pairs(Multiplayer.connector.clients) do
		if client.map == map_id then
			got_response, response = get_client_map_data(client_id, map_id)
			if got_response and response.handler_result then
				LogEvent("MAP_LOAD", "%s: got data from player #%s.", filename, client_id)
				return got_response, response, true
			end
		end
	end

	-- if no clients on selected map or noone responded, ask host for previously saved data
	LogEvent("MAP_LOAD", "%s: could not get map data from players, asking host.", filename)
	local main_player = Multiplayer.main_player_in_game()
	if main_player == Multiplayer.my_id then
		local data = mdata_storage(map_id)
		if data then
			LogEvent("MAP_LOAD", "%s: I am host. Have previously saved data, using it.", filename)
			return true, {handler_result = data}, false
		else
			LogEvent("MAP_LOAD", "%s: I am host. Generating map data myself.", filename)
			return
		end
	end

	got_response, response = get_client_map_data(main_player, map_id, true)
	if got_response and response.handler_result then
		LogEvent("MAP_LOAD", "%s: got mapdata from host.", Map.Name)
		return got_response, response, false
	end

	LogEvent("MAP_LOAD", "%s: could not receive map data from host, generating it myself.", filename)
end
Multiplayer.get_remote_map_data = get_remote_map_data

local function allow_refill(data, map_id)
	local MStats = Game.MapStats[map_id]
	local CurrentDay = math.floor(Game.Time / const.Day)
	local DataLastRefill = (data.LastRefillDay or 0)

	return CurrentDay >= DataLastRefill + MStats.RefillDays
end

local RemoteMapData, RemoteMapDataActual

function events.BeforeLoadMap()
	-- ensure all remote players notified of map change, before processing any map data
	local hashes = Multiplayer.broadcast(packets.notify_map_change:prep(), nil)
	Multiplayer.wait_responses(hashes, 3)

	-- if map data overriden, process it
	local bake = Multiplayer.LoadMapData[Map.MapStatsIndex]
	if bake and type(bake) == "table" and bake.LastRefillDay then
		Map.IndoorLastRefillDay = bake.LastRefillDay
		Map.OutdoorLastRefillDay = bake.LastRefillDay
	end

	-- if multiplayer map data is not overriden, request it
	if not bake then
		LogEvent("MAP_LOAD", "Requesting map data from remote players.")
		local got_response, response, actual = get_remote_map_data(Map.MapStatsIndex)
		if got_response then
			cData, cActual = response.handler_result, actual
			if cData.ddmdlv then
				process_map_data(cData, false)
				Multiplayer.LoadMapData[Map.MapStatsIndex] = true
				LogEvent("MAP_LOAD", "Raw %s loaded, overriding Multiplayer.LoadMapData.", cData.name)
			else
				RemoteMapData, RemoteMapDataActual = cData, cActual
			end

			if cData.LastRefillDay then
				Map.IndoorLastRefillDay = cData.LastRefillDay
				Map.OutdoorLastRefillDay = cData.LastRefillDay
			end
		end
	end
end

function events.BeforeMapHandlersStarted()
	LogEvent("MAP_LOAD", "Entering map %s (%s).", Map.Name, Map.MapStatsIndex)
	local cData, cActual

	cData = Multiplayer.LoadMapData[Map.MapStatsIndex]
	if cData then
		if type(cData) == "table" then
			LogEvent("MAP_LOAD", "Have special map data in Multiplayer.LoadMapData, loading it.")
			cActual = true
			process_map_data(cData, cActual)
		else
			LogEvent("MAP_LOAD", "Multiplayer.LoadMapData overriden, skipping multiplayer map data loading.")
		end
	else
		LogEvent("MAP_LOAD", "Requesting map data from remote players.")
		if RemoteMapData then
			cData, cActual = RemoteMapData, RemoteMapDataActual
			if not cActual and Map.Refilled and allow_refill(cData, Map.MapStatsIndex) then
				LogEvent("MAP_LOAD", "Map refill day approached, received data is obsolete, generating map data myself.")
			else
				process_map_data(cData, cActual)
				Map.LastRefillDay = cData.LastRefillDay
			end
			RemoteMapData, RemoteMapDataActual = nil, nil
		end
	end

	Multiplayer.LoadMapData[Map.MapStatsIndex] = nil
	events.Call("MultiplayerMapDataProcessed")
end

local skip_map_update = false
local function ChangeMap(MoveToMapParams)
	LogEvent("MAP_LOAD", "Changing map (current map state neither will be saved nor sent to host, autosave supressed).")
	local function after(MoveToMapParams)
		if MoveToMapParams[9] ~= Map.Name and MoveToMapParams.MapName ~= Map.Name then
			skip_map_update = true
			Multiplayer.hide_client_monsters()
			evt.MoveToMap(MoveToMapParams)
			events.Once("CanSaveGame", function(t)
				if t.SaveKind == 1 then
					t.IsArena = true
				end
			end)
		else
			local function getc(c,n)
				return MoveToMapParams[c] or MoveToMapParams[n] or Party[c]
			end
			XYZ(Party, getc("X",1), getc("Y",2), getc("Z",3))

			local got_response, response, actual = get_remote_map_data(Map.MapStatsIndex)
			if got_response then
				process_map_data(response.handler_result, actual)
			end
		end
	end
	Multiplayer.utils.ExitToScreen0(after, MoveToMapParams)
end
Multiplayer.ChangeMap = ChangeMap

function events.LeaveMap()
	LogEvent("MAP_LOAD", "Leaving map %s (%s), exit code: %s.", Map.Name, Map.MapStatsIndex, table.find(const.ExitMapAction, Game.ExitMapAction) or Game.ExitMapAction)
	if skip_map_update then
		LogEvent("MAP_LOAD", "Leaving map, skipping changes saving.")
		skip_map_update = false
		return
	end

	local main_player = Multiplayer.main_player_in_game()
	if main_player == Multiplayer.my_id then
		mdata_storage(Map.MapStatsIndex, prep_map_data())
	elseif Multiplayer.connector.clients[main_player].map ~= Map.MapStatsIndex then
		Multiplayer.add_to_send_queue(main_player, packets.notify_host_about_map_changes:prep())
	end
end

-- Leave map halt

function events.LeaveMap()
	Multiplayer.leave_map_halt = true
end

function events.BeforeLoadMap()
	Multiplayer.leave_map_halt = true
end

function events.AfterLoadMap()
	events.Call("BeforeMapHandlersStarted")
	Multiplayer.utils.delayed_call(function()
		Multiplayer.leave_map_halt = false
		events.Call("MapLoadingDone")
	end, 16)
end

-- Save / Load

function events.GatherPartySaveData(t)
	local host = Multiplayer.connector.clients[Multiplayer.main_player_in_game()]
	if host and Map.MapStatsIndex ~= host.map then
		t.MapData = Multiplayer.prep_map_data()
		t.MapStatsIndex = Map.MapStatsIndex
	end
end

function events.ProcessPartySaveData(t)
	if t.MapData and t.MapStatsIndex then
		mdata_storage(t.MapStatsIndex, t.MapData)
	end
end

function Multiplayer.std_events.BeforeSaveGame()
	if not Multiplayer.in_game then
		mdata_storage()[Map.MapStatsIndex] = nil
	end
end
