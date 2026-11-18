local events = Multiplayer.events
local LogEvent = Multiplayer.utils.LogEvent

local InitialMapBolster = false
local NeedStatsResync = false
local BolsteredMonstersTxt
local PreparedTxtMons

----------------------------------
-- Consider average level of all clients, when calculating bolstering factor

function events.CalcBolsterLevel(t)
	local total, count = t.Result, 1
	for i, client in pairs(Multiplayer.connector.clients) do
		if client.in_game then
			count = count + 1
			total = total + (client.level or t.Result)
		end
	end
	t.Result = math.ceil(total / count)
end

----------------------------------
-- Let only first entered player process bolster

function events.BeforeMapBolster(t)
	if Multiplayer.alone_on_map() then
		InitialMapBolster = true
		LogEvent("MONSTERS", "I'm alone at map %s, allowing monster bolstering.", Map.Name)
	elseif BolsteredMonstersTxt and PreparedTxtMons then
		LogEvent("MONSTERS", "Received bolster data from player on map.")

		Game.Bolster.LoadMonstersTxt(BolsteredMonstersTxt)
		local Ready = Game.Bolster.PreparedTxtMons()
		for k, v in pairs(PreparedTxtMons) do
			Ready[k] = v
		end

		t.Handled = true
	elseif Multiplayer.im_host() then
		-- allow rebolster, send updated stats to all players
		LogEvent("MONSTERS", "I'm host, allowing map %s bolstering, new stats will be broadcasted afterwards.", Map.Name)
		NeedStatsResync = true
	else
		t.Handled = true
	end

	BolsteredMonstersTxt = nil
	PreparedTxtMons = nil
end

function events.AfterMapBolster(t)
	InitialMapBolster = false
	if NeedStatsResync then
		Multiplayer.SyncMonsters.sync_all_monsters()
		NeedStatsResync = false
	end
end

----------------------------------
-- Let only main player boost summons

function events.BeforeMonsterBolster(t)
	if InitialMapBolster then
		return
	end

	if Multiplayer.main_player_on_map() == Multiplayer.my_id then
		--LogEvent("MONSTERS", "Bolstering monster: txt id - %s, id - %s.", t.TxtId, t.Id)
		return
	end

	t.Handled = true
end

----------------------------------
-- Remap bolstering to timepoint, where all multiplayer data processed

function events.BolsterOnLoadMap(t)
	t.Handled = true
end

function events.MultiplayerMapDataProcessed()
	Game.Bolster.OnLoadMap()
end

----------------------------------
-- Map data

function events.MultiplayerPrepMapData(t)
	t.PreparedTxtMons = Game.Bolster.PreparedTxtMons()
	t.BolsteredMonstersTxt = Game.Bolster.DumpMonstersTxt()
end

function events.MultiplayerProcessMapData(t)
	BolsteredMonstersTxt = nil
	PreparedTxtMons = nil
	if t.BolsteredMonstersTxt and t.PreparedTxtMons then
		BolsteredMonstersTxt = t.BolsteredMonstersTxt
		PreparedTxtMons = t.PreparedTxtMons
	end
end
