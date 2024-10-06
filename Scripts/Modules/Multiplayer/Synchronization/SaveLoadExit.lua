local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
local binstr_to_item = Multiplayer.utils.binstr_to_item

Multiplayer.reload_count = 0

local LogEvent = Multiplayer.utils.LogEvent
local DataFilePath = "Saves/MultiplayerGames.bin"
local AutosaveFilePath = "Saves/MultiplayerAutosave.bin"

local SyncPlayers = Multiplayer.require("Synchronization/Players.lua")
local CharChoice = {}
Multiplayer.CharChoice = CharChoice

local loaded_global_data
local function GlobalData()
	if loaded_global_data then
		return loaded_global_data
	end

	LogEvent("INTERNAL", "Openning file: %s", DataFilePath)
	local file = io.open(DataFilePath, "rb")
	if file then
		local success
		local bin = file:read("*a")
		bin = assert(Multiplayer.decompress(bin))
		success, loaded_global_data = pcall(binstr_to_item, bin)
		file:close()
		LogEvent("INTERNAL", "File closed: %s", DataFilePath)
		if not success then
			LogEvent("SAVE_LOAD", "Error while loading Multiplayer Global data from file: %s", loaded_global_data)
		end
	else
		LogEvent("INTERNAL", "Could not open file: %s", DataFilePath)
	end

	if type(loaded_global_data) ~= 'table' then
		loaded_global_data = nil
	end

	loaded_global_data = loaded_global_data or {}
	loaded_global_data.Games = loaded_global_data.Games or {}
	loaded_global_data.ClientSaves = loaded_global_data.ClientSaves or {}
	loaded_global_data.Connections = loaded_global_data.Connections or {}

	return loaded_global_data
end
Multiplayer.GlobalData = GlobalData

local function SaveGlobalData()
	if not loaded_global_data then
		return GlobalData()
	end

	LogEvent("INTERNAL", "Saving multiplayer global data.")
	LogEvent("INTERNAL", "Openning file: %s", DataFilePath)
	local file = io.open(DataFilePath, "wb")
	if not file then
		LogEvent("INTERNAL", "Could not open file: %s", DataFilePath)
		return loaded_global_data
	end

	local bin = assert(Multiplayer.compress(item_to_bin(loaded_global_data)))

	local step = 128
	for i = 1, #bin, step do
		file:write(string.sub(bin, i, i + step - 1))
	end
	file:close()
	LogEvent("INTERNAL", "File closed: %s", DataFilePath)

	return loaded_global_data
end
Multiplayer.SaveGlobalData = SaveGlobalData

local function SaveGameData()
	local t = vars.MultiplayerGameData
	if not t then
		t = {RemotePlayers = {}}
		vars.MultiplayerGameData = t
	end
	return t
end
Multiplayer.SaveGameData = SaveGameData

local SAVE_VERSION_TOKEN = "SV1_"
local function GenericId()
	return SAVE_VERSION_TOKEN .. tostring(os.time()) .. tostring(Game.Time) .. tostring(Party[0].Name)
end

local function SaveIdValid(save_id)
	return save_id and save_id:sub(1, #SAVE_VERSION_TOKEN) == SAVE_VERSION_TOKEN
end
Multiplayer.debug.SaveIdValid = SaveIdValid

local function CurrentGameId(n)
	if n then
		if not SaveIdValid(n) then
			n = SAVE_VERSION_TOKEN .. n
		end
		LogEvent("SAVE_LOAD", "Game id set, old: %s, new: %s", SaveGameData().game_id, n)
		SaveGameData().game_id = n
		return
	end

	n = SaveGameData().game_id
	if not n then
		n = GenericId()
		LogEvent("SAVE_LOAD", "Game id generated: %s", n)
		SaveGameData().game_id = n
	elseif not SaveIdValid(n) then
		local new = GenericId()
		LogEvent("SAVE_LOAD", "Existing game id is invalid (%s), replacing it by new one: %s", n, new)
		n = new
		SaveGameData().game_id = n
	end
	return n
end
Multiplayer.GameId = CurrentGameId

local function CurrentSaveId()
	local last_game = Multiplayer.GlobalData().Games[CurrentGameId()]
	if not last_game then
		last_game = {}
		Multiplayer.GlobalData().Games[CurrentGameId()] = last_game
	end

	if not last_game.save_id then
		last_game.save_id = GenericId()
		LogEvent("SAVE_LOAD", "Save id generated: %s", last_game.save_id)
	elseif not SaveIdValid(last_game.save_id) then
		local new = GenericId()
		LogEvent("SAVE_LOAD", "Existing save id is invalid (%s), replacing it by new one: %s", n, new)
		last_game.save_id = new
	end

	return last_game.save_id
end
Multiplayer.SaveId = CurrentSaveId

local function party_position(t)
	t = t or {}

	t.X = Party.X
	t.Y = Party.Y
	t.Z = Party.Z
	t.Direction = Party.Direction
	t.LookAngle = Party.LookAngle
	t.at_map = Map.MapStatsIndex
	t.Gold = Party.Gold
	t.Food = Party.Food
	t.Time = Game.Time

	return t
end

local function prep_game_data()
	local mmt_dump = Multiplayer.utils.mmt_dump
	local sendbuff = Multiplayer.utils.sendbuff

	local result = {
		ABits = mstr(Party.AutonotesBits['?ptr'], Party.AutonotesBits['?size'], true),
		X = Party.X,
		Y = Party.Y,
		Z = Party.Z,
		MapName = Map.Name,
		vars = {},
		game_id = Multiplayer.GameId()
	}
	--[[
	for i, v in Game.NPC do
		u2[sendbuff + i*2] = v.House
	end
	result.npc_locs = mstr(sendbuff, Game.NPC.count*2 + 2, true)

	result.npc_topics = {}
	for i, v in Game.NPC do
		result.npc_topics[i] = mmt_dump(v.Events)
	end
	]]
	local bin_vars = {"Quests","History","MercenariesProps","BountyHunt","GotArtifact","NextArtifactsRefill","WonChallenges","Quest_DragonHatchling","Quest_SavingGoobers","Quest_CrossContinents"}
	for k, v in pairs(bin_vars) do
		result.vars[v] = vars[v]
	end

	LogEvent("EVENTS", "Gathering game data.")
	events.Call("GatherGameData", result)
	return result
end
Multiplayer.prep_game_data = prep_game_data

local function process_game_data(game_data, apply_position)
	LogEvent("SAVE_LOAD", "Received game id from server: %s", game_data.game_id)
	Multiplayer.GameId(game_data.game_id)

	mcopy(Party.AutonotesBits['?ptr'], mem.topointer(game_data.ABits), Party.AutonotesBits['?size'])

	for k,v in pairs(game_data.vars) do
		if type(v) == 'table' and type(vars[k]) == 'table' then
			local t = vars[k]
			table.clear(t)
			for a,b in pairs(v) do
				t[a] = b
			end
		else
			vars[k] = v
		end
	end
	--[[
	if apply_position then
		Party.X = game_data.X
		Party.Y = game_data.Y
		Party.Z = game_data.Z
	end
	]]
	local npc_locs = toptr(game_data.npc_locs)
	for i, v in Game.NPC do
		v.House = u2[npc_locs + i*2]
	end

	for i, v in pairs(game_data.npc_topics) do
		mcopy(Game.NPC[i].Events['?ptr'], v)
	end

	for i, v in Party do
		Game.CountItemBonuses(v)
	end

	LogEvent("EVENTS", "Processing game data.")
	events.Call("ProcessGameData", game_data)
end
Multiplayer.process_game_data = process_game_data

local function prep_party_data()
	local t = {
		player_name = Party[0].Name,
		player_class_id = Party[0].Class,
		player_pic = Game.CharacterPortraits[Party[0].Face].NPCPic,
		party_size = Party.count,
		experience = Party[0].Experience,
		level = Party[0].LevelBase,
		session_code = Multiplayer.my_session_code(),
		map_name = Map.Name,
		save_id = CurrentSaveId()
	}
	party_position(t)
	events.Call("GatherPartySaveData", t)
	return t
end
Multiplayer.prep_party_data = prep_party_data

local function client_save_party()
	local data = prep_party_data()
	Multiplayer.GlobalData().ClientSaves[Multiplayer.GameId()] = data
	SaveGlobalData()
	LogEvent("SAVE_LOAD", "Client data saved, game id: %s.", Multiplayer.GameId())
	return data
end
function events.BeforeSaveGame()
	if not Multiplayer.im_host() then
		client_save_party()
	end
end
function events.MapLoadingDone()
	if not Multiplayer.im_host() then
		client_save_party()
	end
end

local packets = {
	save_game = {
		-- clients don't use this packet
		-- host gather position/map/party data from players
		handler = function(bin_string, metadata)
			return Multiplayer.reload_count == metadata.reload_count
		end,
		response = "send_client_data",
		check_delivery = true,
		ignore_reload_count = true
	},

	send_client_data = {
		bulb = function(Allow)
			local data = false
			if Allow or Allow == nil then
				Game.ShowStatusText("Host saved the game.")
				data = client_save_party()
			end
			return item_to_bin(data)
		end,
		handler = function(bin_string, metadata)
			local data = bin_to_item(toptr(bin_string))
			if data then
				SyncPlayers.client_info(metadata.sender_id).save_id = data.save_id
				Multiplayer.SaveGameData().RemotePlayers[data.save_id] = data
			end
		end,
		compress = true,
		check_delivery = true,
		ignore_reload_count = true
	},

	load_game = {
		-- clients don't use this packet, they leave game instead
		-- host notifies clients about data to change
		bulb = item_to_bin,
		handler = function(bin_string, metadata)
			Game.Paused = true
			Game.Paused2 = true

			local host_id = Multiplayer.main_player_in_game()
			assert(metadata.sender_id == host_id and Multiplayer.my_id ~= host_id)

			CharChoice.supress_autosave = true

			local t = bin_to_item(toptr(bin_string))
			LogEvent("SAVE_LOAD", "Received load_game packet from #%s. Current game id: %s, new game id: %s", metadata.sender_id, t.Game.game_id, Multiplayer.GameId())

			if Multiplayer.OnDeathScreen() then
				Multiplayer.ExitDeathScreen(true, true)
			end

			local MoveToMapParams = {t.Party.X, t.Party.Y, t.Party.Z,t.Party.Direction,t.Party.LookAngle,0,0,0,Game.MapStats[t.Party.at_map].FileName}

			local function routine(MoveToMapParams)

				local function PB(mul)
					Game.ProgressBar.Current = math.ceil(Game.ProgressBar.Max * mul)
					Game.ProgressBar:Draw()
				end

				Multiplayer.process_game_data(t.Game, false)

				if Map.Name == MoveToMapParams[9] then
					Game.ProgressBar.Current = 0
					Game.ProgressBar:Show()
					LogEvent("SAVE_LOAD", "Map is same, requesting host data.")
					local got_response, response = Multiplayer.get_client_map_data(Multiplayer.main_player_in_game(), Map.MapStatsIndex)
					PB(0.4)
					if got_response and response.handler_result then
						LogEvent("SAVE_LOAD", "Received host map data.")
						Multiplayer.process_map_data(response.handler_result, true)
					end
					PB(0.8)
					PB(1)
					Game.ProgressBar:Hide()
					Multiplayer.reload_count = metadata.reload_count

					client_save_party()
				else
					LogEvent("SAVE_LOAD", "Map differs, changing map.")
					events.Once("MapLoadingDone", function()
						Multiplayer.reload_count = metadata.reload_count
					end)
					Multiplayer.ChangeMap(MoveToMapParams)
				end

				CharChoice.supress_autosave = false
			end

			Multiplayer.GameId(t.Game.game_id)
			CharChoice.process_character_choice(routine, 4, MoveToMapParams, t.Game.Time)
		end,
		check_delivery = true,
		compress = true,
		ignore_reload_count = true
	},

	leave_game = {
		handler = function(bin_string, metadata)
			local client = Multiplayer.connector.clients[metadata.sender_id]
			local was_main = metadata.sender_id == Multiplayer.main_player_in_game()
			events.Call("ClientLeft", metadata.sender_id, client)
			if was_main then
				events.Call("HostLeft")
			end
		end,
		ignore_reload_count = true
	},

	request_party_data = {
		bulb = function(save_id)
			return save_id
		end,
		handler = function(bin_string, metadata)
			SyncPlayers.client_info(metadata.sender_id).save_id = bin_string
			return bin_string
		end,
		response = "send_party_data",
		check_delivery = true,
		ignore_reload_count = true
	},

	send_party_data = {
		bulb = function(save_id)
			local data = Multiplayer.SaveGameData().RemotePlayers[save_id]
			LogEvent("CONNECTION", "Received saved character data query (save id: %s). %s", save_id, data and "Have data." or "No data by this id.")
			return data and item_to_bin(data) or item_to_bin(false)
		end,
		handler = function(bin_string, metadata)
			return bin_to_item(toptr(bin_string))
		end,
		check_delivery = true,
		compress = true,
		ignore_reload_count = true
	}

}
Multiplayer.utils.init_packets(packets)

function events.BeforeSaveGame()
	if not Multiplayer.im_host() or Multiplayer.connector:active_clients_count() == 0 then
		return
	end

	local hashes = {}
	Multiplayer.broadcast_keep_hash(packets.save_game, nil, hashes)
	LogEvent("SAVE_LOAD", "I'm host, saving game. Sent save data requests: %s", table.concat(hashes, ","))

	Multiplayer.wait_responses(hashes, 20)

	Multiplayer.SaveGameData().GameData = Multiplayer.prep_game_data()
end

local function host_load_game()
	LogEvent("SAVE_LOAD", "I'm host. Loading saved game.")
	local dummy_player = party_position()
	dummy_player.Gold = nil
	dummy_player.Food = nil

	local data = packets.load_game:prep({Party = dummy_player, Game = Multiplayer.prep_game_data()})
	Multiplayer.broadcast(data)
end

function events.ExitMapAction(t)
	local is_leave_game = {[1] = true, [3] = true, [4] = true, [7] = true}
	if not is_leave_game[t.Action] then
		return
	end

	if Multiplayer.my_id > 0 then -- i am/was client
		LogEvent("SAVE_LOAD", "I'm client. Leaving the game.")
		Multiplayer.close() -- triggers leave_game notification in events.MultiplayerStopped
		return
	end

	if t.Action == const.ExitMapAction.LoadGame then
		Multiplayer.reload_count = Multiplayer.reload_count + 1
		if Multiplayer.reload_count > 65000 then
			Multiplayer.reload_count = 0
		end
		events.Once("MapLoadingDone", host_load_game)
	else
		Multiplayer.close() -- triggers leave_game notification in events.MultiplayerStopped
		LogEvent("SAVE_LOAD", "I'm host. Closing the game.")
	end
end

function events.LoadMapScripts(WasInGame)
	if not WasInGame then
		-- Prevent usage of multiplayer saved map data, use ddm/dlv only
		Multiplayer.LoadMapData[Map.MapStatsIndex] = true
	end
end

-------------------------------------------------------------------
-- Saved character choice

local last_choice

local function last_character_choice()
	if last_choice then
		last_choice.Name = StrColor(46,237,218, "(last choice) ") .. StrColor(250,250,250) .. last_choice.data.player_name
		last_choice.Map = Game.MapStats[last_choice.data.at_map].Name
		return last_choice
	end
end
CharChoice.last_character_choice = last_character_choice

local function current_character_choice()
	return {
		Name = StrColor(213,70,191, "(current) ") .. StrColor(250,250,250) .. Party[0].Name,
		ClassId = Party[0].Class,
		PicId = Game.CharacterPortraits[Party[0].Face].NPCPic,
		Level = Party[0].LevelBase,
		Experience = Party[0].Experience,
		PartySize = Party.count,
		MapName = Map.Name,
		data = prep_party_data()
	}
end
CharChoice.current_character_choice = current_character_choice

local function character_choice(PartyData)
	if not PartyData then
		return
	end
	return --maw fix, as quests are messed in this save
	return {
		Name = StrColor(46,237,218, "(client save) ") .. StrColor(250,250,250) .. PartyData.player_name,
		ClassId = PartyData.player_class_id,
		PicId = PartyData.player_pic,
		Level = PartyData.level,
		Experience = PartyData.experience,
		PartySize = PartyData.party_size,
		MapName = Game.MapStats[PartyData.at_map].FileName,
		Map = Game.MapStats[PartyData.at_map].Name,
		Time = PartyData.Time,
		data = PartyData
	}
end
CharChoice.character_choice = character_choice

local function do_callback(callback, callback_delay, MoveToMapParams)
	if callback then
		LogEvent("SAVE_LOAD", "Executing MoveToMap callback.")
		if callback_delay then
			Multiplayer.utils.delayed_call(callback, callback_delay, MoveToMapParams)
		else
			callback(MoveToMapParams)
		end
	end
end

local function process_character_choice(callback, callback_delay, MoveToMapParams, HostTime)
	local choices = {}

	local function handler(i)
		LogEvent("SAVE_LOAD", "Character choice made.")

		local chosen = choices[i]
		local data = chosen.data
		last_choice = chosen

		LogEvent("EVENTS", "Calling ProcessPartySaveData event.")
		if Game.TurnBased then
			Multiplayer.StopTurnBasedMode()
		end
		events.Call("ProcessPartySaveData", data)
		LogEvent("EVENTS", "ProcessPartySaveData event handled.")

		MoveToMapParams[1] = data.X
		MoveToMapParams[2] = data.Y
		MoveToMapParams[3] = data.Z
		MoveToMapParams[4] = data.Direction
		MoveToMapParams[5] = data.LookAngle
		MoveToMapParams[9] = chosen.MapName or Map.Name

		if chosen.MapName == Map.Name then
			XYZ(Party, XYZ(data))
			Party.Direction = data.Direction
			Party.LookAngle = data.LookAngle
		end

		Party.Food = data.Food or Party.Food
		Party.Gold = data.Gold or Party.Gold

		do_callback(callback, callback_delay, MoveToMapParams)
	end

	local current = CharChoice.current_character_choice()
	current.data.X = MoveToMapParams[1]
	current.data.Y = MoveToMapParams[2]
	current.data.Z = MoveToMapParams[3]
	current.MapName = MoveToMapParams[9]
	for i, v in Game.MapStats do
		if v.FileName == current.MapName then
			current.data.at_map = i
			break
		end
	end

	local function tinsert(t, v)
		if v then table.insert(t, v) end
	end

	local autosave = Multiplayer.read_client_autosave()
	local client_save = GlobalData().ClientSaves[CurrentGameId()]
	if client_save and autosave and (math.abs(client_save.Time - HostTime) > math.abs(autosave.Time - HostTime)) then
		client_save = autosave
	end
	if client_save then
		client_save = character_choice(client_save)
		client_save.time_diff = math.abs(client_save.Time - HostTime)
	end

	local host_save = CharChoice.request_host_saved_characters()
	if host_save then
		host_save.time_diff = math.abs(host_save.Time - HostTime)
	end

	tinsert(choices, host_save)
	tinsert(choices, client_save)

	table.sort(choices, function(t1, t2) return t1.time_diff < t2.time_diff end)

	tinsert(choices, current)

	if #choices == 1 then
		handler(1)
	else
		LogEvent("SAVE_LOAD", "Received character data from server. Suggesting choice.")
		choices[1].Name = StrColor(235,235,50, "(Most relevant) ") .. choices[1].Name
		Multiplayer.SelectCharacter(choices, handler)
	end
end
CharChoice.process_character_choice = process_character_choice

local function request_host_saved_characters()
	local save_id = Multiplayer.SaveId()
	LogEvent("SAVE_LOAD", "Asking server for possibly saved character data (save id: %s).", save_id)
	local got_response, response = Multiplayer.send_wait_response(Multiplayer.main_player_in_game(), packets.request_party_data, 8, save_id)
	if not got_response or not response.handler_result then
		LogEvent("SAVE_LOAD", "Received no character data from server.")
		return
	end
	return --MAW FIX, quests are messed here
	local last_game = response.handler_result
	return {
		Name = StrColor(95,235,50, "(host save) ") .. StrColor(250,250,250) .. last_game.player_name,
		ClassId = last_game.player_class_id,
		PicId = last_game.player_pic,
		Level = last_game.level,
		Experience = last_game.experience,
		PartySize = last_game.party_size,
		MapName = Game.MapStats[last_game.at_map].FileName,
		Map = Game.MapStats[last_game.at_map].Name,
		Time = last_game.Time,
		data = last_game
	}
end
CharChoice.request_host_saved_characters = request_host_saved_characters

-------------------------------------------------------------------
-- Game init data

function events.GatherServerInitData(t)
	t.GameData = Multiplayer.prep_game_data()
	t.ReloadCount = Multiplayer.reload_count
end

function events.ProcessServerInitData(t)
	local game_id = t.GameData.game_id
	Multiplayer.reload_count = t.ReloadCount

	CharChoice.supress_autosave = true

	if not game_id then
		LogEvent("CONNECTION", "Received server's initial data without 'game_id' field set.")
		error("Missing game_id in server init data.")
		return
	end

	Multiplayer.process_game_data(t.GameData, false)
	CharChoice.process_character_choice(Multiplayer.ChangeMap, 4, {t.GameData.X,t.GameData.Y,t.GameData.Z,0,0,0,0,0,t.MapData.MapName}, t.GameData.Time)

	CharChoice.supress_autosave = false
end

-------------------------------------------------------------------
-- Remote save data

function events.GatherPartySaveData(t)
	t.PartyMembers = {}
	t.NPCFollowers = vars.NPCFollowers
	t.Skin = Multiplayer.my_skin

	for i, v in Party do
		table.insert(t.PartyMembers, {id = v:GetIndex(), bin = mstr(v['?ptr'], v['?size'], true)})
	end
end

function events.ProcessPartySaveData(t)
	if t.PartyMembers then
		while Party.count > 0 do
			DismissCharacter(0)
		end

		for i, pl in ipairs(t.PartyMembers) do
			HireCharacter(pl.id, true)
			mcopy(Party.PlayersArray[pl.id]['?ptr'], pl.bin)
			SetCharFace(i - 1, Party[i - 1].Face)
		end
	end

	if t.NPCFollowers then
		vars.NPCFollowers = t.NPCFollowers
	end

	if t.Skin then
		LogEvent("PLAYERS_SYNC", "Remote save loading: skin set to %s", t.skin)
		vars.Multiplayer.my_skin = t.Skin
		Multiplayer.my_skin = t.Skin
	end
end

-------------------------------------------------------------------
-- Connection

function events.ClientLeft(client_id, client)
	Game.ShowStatusText(string.format("Player %s left the game.", client.name))
end

function events.HostLeft()
	-- remove all clients, end game, leave to main menu, show explanation message
	Multiplayer.close()
	CustomUI.DisplayTooltip("Host have closed the game", 20, 100, 160, 440, 0)
	DoGameAction(132, 0, 0, true)
	DoGameAction(132)
end

local function notify_leave_game()
	local data = packets.leave_game:prep()
	Multiplayer.broadcast(data)
	Multiplayer.sendall()
	SaveGlobalData()
	Multiplayer.reload_count = 0
end

events.MultiplayerStopped = notify_leave_game
events.MultiplayerRoleChanged = notify_leave_game

-------------------------------------------------------------------
-- Periodic autosave on client side

CharChoice.supress_autosave = true

Multiplayer.client_autosave = function()
	LogEvent("INTERNAL", "Openning file: %s", AutosaveFilePath)
	local file = io.open(AutosaveFilePath, "wb")
	if not file then
		LogEvent("INTERNAL", "Could not open file %s", AutosaveFilePath)
		return
	end

	local data = prep_party_data()
	local bin = item_to_bin({game_id = Multiplayer.GameId(), data = data})
	bin = Multiplayer.compress(bin)

	file:write(bin)
	file:close()
	LogEvent("INTERNAL", "File closed: %s, bytes written: %s", AutosaveFilePath, #bin)
end

Multiplayer.read_client_autosave = function(game_id)
	LogEvent("INTERNAL", "Openning file: %s", AutosaveFilePath)
	local file = io.open(AutosaveFilePath, "rb")
	if not file then
		LogEvent("INTERNAL", "Could not open file %s", AutosaveFilePath)
		return
	end

	local bin = file:read("*a")
	file:close()
	LogEvent("INTERNAL", "File closed: %s", AutosaveFilePath)

	bin = Multiplayer.decompress(bin)
	local success, data = pcall(binstr_to_item, bin)
	if not success then
		LogEvent("INTERNAL", "Error while decoding %s:\n%s", AutosaveFilePath, data)
		return
	end

	if not game_id then
		return data.data
	end

	if game_id == data.game_id then
		return data.data
	end
end

Multiplayer.utils.MillisecCounter(function()
	if not CharChoice.supress_autosave and Multiplayer.my_id ~= Multiplayer.main_player_in_game() then
		Multiplayer.client_autosave()
	end
end, 30000)
