-- Time constants for timer system
local second=256/60
local minute=256
local hour=15360
local day=368640
local week=2580480
local month=10321920
local year=123863040

function events.MultiplayerInitialized()
	local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
	local toptr = mem.topointer

	-- Make debug system globally accessible
	DEBUG_SYNC = false -- Global for console access
	syncStats = {      -- Global for console access
		healthUpdates = 0,
		mapvarsSync = 0,
		clientRequests = 0,
		burstBroadcasts = 0,
		packetsSent = 0,
		packetsReceived = 0
	}

	function DebugLog(category, message)
		if DEBUG_SYNC then
			print(string.format("[SYNC-%s] %s: %s", category, os.date("%H:%M:%S"), message))
		end
	end

	function LogSyncStats()
		if DEBUG_SYNC then
			DebugLog("STATS", string.format("Health:%d Mapvars:%d Requests:%d Bursts:%d Sent:%d Recv:%d", 
				syncStats.healthUpdates, syncStats.mapvarsSync, syncStats.clientRequests, 
				syncStats.burstBroadcasts, syncStats.packetsSent, syncStats.packetsReceived))
		end
	end

	mawPackets = {
		send_table = {
			bulb = function(tbl)
				return item_to_bin(tbl)
			end,

			handler = function(bin_string, metadata)
				local t = bin_to_item(toptr(bin_string))
				local host=Multiplayer.im_host()
				syncStats.packetsReceived = syncStats.packetsReceived + 1
				
				if t.dataType=="healthManaInfo" and host then
					vars.online.partyHealthMana.Parties[t.senderId] = t.Party
					syncStats.healthUpdates = syncStats.healthUpdates + 1
					DebugLog("HEALTH", string.format("Received health data from client %s", tostring(t.senderId)))
				else
					vars.online.partyHealthMana.Parties = t.Parties or {}
					if t.dataType=="healthManaInfo" then
						syncStats.healthUpdates = syncStats.healthUpdates + 1
						DebugLog("HEALTH", "Received health broadcast from host")
					end
				end
				
				if t.dataType=="heal" then
					local id=t.PartyId
					if id<0 or id>Party.High then
						id=0
					end
					local pl=Party[id]
					pl.HP=math.min(GetMaxHP(pl), pl.HP+t.Amount)
					mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, mem.u4[0x75CE00]), const.Spells.Heal, id)
					evt.PlaySound(16010)
					Game.ShowStatusText(t.HealerName .. " heals you for " .. t.Amount .. " Hit Points")
					DebugLog("HEAL", string.format("%s healed player %d for %d HP", t.HealerName, id, t.Amount))
				end
				
				--debug.Message(dump(t))
				
				-- ShareMapvars synchronization system
				if t.dataType=="ShareMapvarsToHost" and Multiplayer.im_host() then 
					vars.StoredMapvars = vars.StoredMapvars or {}
					if not vars.StoredMapvars[t.MapName] then
						vars.StoredMapvars[t.MapName]=t.Variables
						syncStats.mapvarsSync = syncStats.mapvarsSync + 1
						DebugLog("MAPVARS", string.format("Host received mapvars for map: %s", t.MapName))
					end
				elseif t.dataType=="ShareMapvarsToClients" and not Multiplayer.im_host() then
					vars.StoredMapvars = vars.StoredMapvars or {}
					local mapsUpdated = 0
					for mapName, variables in pairs(t.Variables) do
						if not vars.StoredMapvars[mapName] then
							vars.StoredMapvars[mapName] = variables
							mapsUpdated = mapsUpdated + 1
						else
							-- Merge with existing data, prioritizing existing values
							for key, value in pairs(variables) do
								if vars.StoredMapvars[mapName][key] == nil then
									vars.StoredMapvars[mapName][key] = value
								end
							end
							mapsUpdated = mapsUpdated + 1
						end
					end
					syncStats.mapvarsSync = syncStats.mapvarsSync + mapsUpdated
					DebugLog("MAPVARS", string.format("Client received mapvars for %d maps from host", mapsUpdated))
				elseif t.dataType=="RequestMapvarsSnapshot" and Multiplayer.im_host() then
					ShareMapvarsList()
					HostBurst_Start(4, 0.6) -- Burst broadcast for reliability
					syncStats.clientRequests = syncStats.clientRequests + 1
					DebugLog("REQUEST", "Client requested mapvars snapshot - sending burst broadcast")
				elseif t.dataType=="characterInfo" then
					vars.online.partyHealthMana.CharacterInfo = t.CharacterInfo
					DebugLog("CHAR", "Received character info update")
				end
				vars.online.party[t.Id]=t.Playerinfo
			end,
			
			check_delivery = true,
			compress = true
		}
	}

	Multiplayer.utils.init_packets(mawPackets)
	
	function SendToHost(tbl)
		if Multiplayer and Multiplayer.in_game and Multiplayer.packets then
			Multiplayer.add_to_send_queue(0, mawPackets.send_table:prep(tbl))
			syncStats.packetsSent = syncStats.packetsSent + 1
			DebugLog("SEND", string.format("Sent %s to host", tbl.dataType or "unknown"))
		end
	end

	function BroadcastToAllClients(tbl)
		if Multiplayer and Multiplayer.in_game and Multiplayer.im_host() then
			Multiplayer.broadcast(mawPackets.send_table:prep(tbl),nil)
			syncStats.packetsSent = syncStats.packetsSent + 1
			DebugLog("BROADCAST", string.format("Broadcast %s to all clients", tbl.dataType or "unknown"))
		end
	end
	
	function broadcastToClient(tbl, clientId)
		if Multiplayer and Multiplayer.in_game then
			Multiplayer.add_to_send_queue(clientId, mawPackets.send_table:prep(tbl))
		end
	end

	--maw code with robust networking from zzBossSync
	local SEC = (const and const.Second) or 1
	local function NOW() return (Game and Game.Time) or 0 end
	
	-- Burst broadcasting system for reliability
	local _burst_until, _burst_next = 0, 0
	local function HostBurst_Start(secs, period)
		_burst_until = NOW() + (secs or 4)*SEC
		_burst_next = 0
		_burst_period = math.max((period or 0.6)*SEC, 0.2*SEC)
	end
	
	function ShareMapvarsList()
		if Multiplayer and Multiplayer.in_game and Multiplayer.im_host() then
			BroadcastToAllClients({dataType="ShareMapvarsToClients", Variables=vars.StoredMapvars})
			local mapCount = vars.StoredMapvars and table.maxn(vars.StoredMapvars) or 0
			DebugLog("BROADCAST", string.format("Sharing mapvars for %d maps to all clients", mapCount))
		end
	end
	
	-- Client request system - clients can request mapvars from host
	local function requestMapvarsSnapshot()
		if not (Multiplayer and Multiplayer.in_game) or (Multiplayer and Multiplayer.im_host and Multiplayer.im_host()) then return end
		SendToHost({dataType="RequestMapvarsSnapshot", map = (Map and Map.Name) or "", sender = "client"})
	end
	
	function events.BeforeLoadMap()
		vars.StoredMapvars = vars.StoredMapvars or {}
		if not mapvars.bossGenerated and vars.StoredMapvars[Map.Name] then
			mapvars=vars.StoredMapvars[Map.Name]
			vars.StoredMapvars[Map.Name]=nil
		elseif not mapvars.bossGenerated then
			shareData=true
		end
	end
	function events.AfterLoadMap()
		vars.StoredMapvars = vars.StoredMapvars or {}
		if Multiplayer and Multiplayer.in_game and Multiplayer.im_host() then
			vars.StoredMapvars[Map.Name]=mapvars
			ShareMapvarsList()
			HostBurst_Start(4, 0.6) -- Burst broadcast for reliability
		end
		if Multiplayer and Multiplayer.in_game and not Multiplayer.im_host() then
			if shareData and mapvars and mapvars.bossGenerated then
				SendToHost({dataType="ShareMapvarsToHost", MapName=Map.Name, Variables=mapvars})
			end
			-- Clients request mapvars snapshot from host
			requestMapvarsSnapshot()
		end
		shareData=false
	end
	
	-- When a client joins, host sends mapvars with burst retry
	function events.ClientJoined(client)
		if Multiplayer and Multiplayer.im_host and Multiplayer.im_host() then
			if vars.StoredMapvars and next(vars.StoredMapvars) then
				ShareMapvarsList()
				HostBurst_Start(5, 0.6) -- Burst when client joins
			end
		end
	end
	
	function PlayersOnMap()
		local count = 1
		for k,v in pairs(Multiplayer.connector.clients) do
			if v.map == Map.MapStatsIndex then
				count = count + 1
			end
		end
		return count
	end
	
	-- Health sharing functions
	function SendHealthData()
		local myId=Multiplayer.my_id
		local data={}
		data.Party={}
		data.Party.X=Party.X
		data.Party.Y=Party.Y
		data.Party.Z=Party.Z
		data.Party.High=Party.High
		data.Party.Map=Map.Name
		for i=0,Party.High do
			local pl=Party[i]
			local FHP=GetMaxHP(pl)
			local FSP=0
			if vars.MAWSETTINGS.buffRework=="ON" and vars.currentManaPool and vars.currentManaPool[i] then
				FSP = vars.currentManaPool[i]
			else
				FSP	= pl:GetFullSP()
			end
			data.Party[i]={}
			data.Party[i].HP=pl.HP
			data.Party[i].FHP=FHP
			data.Party[i].SP=pl.SP
			data.Party[i].FSP=FSP
			data.Party[i].Dead=pl.Dead
			data.Party[i].Eradicated=pl.Eradicated
		end
		data.dataType="healthManaInfo"
		data.senderId=myId
		SendToHost(data)
	end

	function ShareHealthData()
		--clear disconnected
		for key, value in pairs(vars.online.partyHealthMana.Parties) do
			if not Multiplayer.connector.clients[key] then
				vars.online.partyHealthMana.Parties[key]=nil
			end
		end
		local hostParty={}
		hostParty.X=Party.X
		hostParty.Y=Party.Y
		hostParty.Z=Party.Z
		hostParty.High=Party.High
		hostParty.Map=Map.Name
		for i=0,Party.High do
			local pl=Party[i]
			local FHP=GetMaxHP(pl)
			local FSP=0
			if vars.MAWSETTINGS.buffRework=="ON" and vars.currentManaPool and vars.currentManaPool[i] then
				FSP = vars.currentManaPool[i]
			else
				FSP	= pl:GetFullSP()
			end
			hostParty[i]={}
			hostParty[i].HP=pl.HP
			hostParty[i].FHP=FHP
			hostParty[i].SP=pl.SP
			hostParty[i].FSP=FSP
			hostParty[i].Dead=pl.Dead
			hostParty[i].Eradicated=pl.Eradicated
		end
		vars.online.partyHealthMana.Parties[0]=hostParty
		local data=vars.online.partyHealthMana
		data.dataType="healthManaInfo"
		BroadcastToAllClients(data)
	end

	function SendHeal(clientId, partyId, amount, healerName)
		local data={}
		data.dataType="heal"
		data.PartyId=partyId
		data.Amount=amount
		data.HealerName=healerName
		broadcastToClient(data, clientId)
	end
	
	--SHARE PARTY INFO BETWEEN PLAYERS
	local healthUpdateTimer=60  -- Reduced from 10 to 60 (1 second instead of 6 times/sec)
	local hpTimer=0
	local lastHealthState = {}
	
	local function hasHealthChanged()
		local currentState = {}
		for i=0,Party.High do
			local pl=Party[i]
			currentState[i] = {
				HP = pl.HP,
				SP = pl.SP,
				Dead = pl.Dead,
				Eradicated = pl.Eradicated
			}
		end
		
		-- Compare with last state
		for i=0,Party.High do
			local last = lastHealthState[i]
			local current = currentState[i]
			if not last or 
			   last.HP ~= current.HP or 
			   last.SP ~= current.SP or 
			   last.Dead ~= current.Dead or 
			   last.Eradicated ~= current.Eradicated then
				lastHealthState = currentState
				return true
			end
		end
		return false
	end
	
	-- Consolidated tick handler
	function events.Tick()
		if not onlineQualityOfLifeFeatures then return end
		
		hpTimer=hpTimer+1
		
		-- Health data sharing (reduced frequency + change detection)
		if hpTimer>=healthUpdateTimer then
			hpTimer=0
			if Multiplayer and Multiplayer.in_game and hasHealthChanged() then
				if Multiplayer.im_host() then
					ShareHealthData()
				else
					SendHealthData()
				end
			end
		end
		
		-- Player count monitoring (reduced frequency)
		if hpTimer % 30 == 0 then -- Check every 0.5 seconds instead of every tick
			connectedPlayers=connectedPlayers or 1
			if Multiplayer and Multiplayer.in_game and Multiplayer.im_host() then
				local currentPlayers=PlayersOnMap()
				if currentPlayers>connectedPlayers then
					ShareMapvarsList()
				end
				connectedPlayers=currentPlayers
			end
		end
		
		-- Multiplayer state management
		if not isMultiplayerActive and Multiplayer and Multiplayer.in_game then
			isMultiplayerActive=true
			vars.ChallengeMode=true
			if storeTime then
				Game.Time=storeTime
				storeTime=false			
			end
			
			for i=0, Game.TransportLocations.High do
				local tran=Game.TransportLocations[i]
				tran.Monday=true
				tran.Tuesday=true
				tran.Wednesday=true
				tran.Thursday=true
				tran.Friday=true
				tran.Saturday=true
				tran.Sunday=true
			end
			for i =0,Game.Houses.High do
				Game.Houses[i].OpenHour=0
				Game.Houses[i].CloseHour=0
			end
			Game.NPC[1177].EventB=0
		end
		if isMultiplayerActive and Multiplayer and not Multiplayer.in_game then
			isMultiplayerActive=false
			vars.ChallengeMode=false
			for i=0, Game.TransportLocations.High do
				local tran=Game.TransportLocations[i]
				tran.Monday=baseTransportTable[i][1]
				tran.Tuesday=baseTransportTable[i][2]
				tran.Wednesday=baseTransportTable[i][3]
				tran.Thursday=baseTransportTable[i][4]
				tran.Friday=baseTransportTable[i][5]
				tran.Saturday=baseTransportTable[i][6]
				tran.Sunday=baseTransportTable[i][7]
			end
			for i =0,Game.Houses.High do
				Game.Houses[i].OpenHour=baseOpenTimes[i]
				Game.Houses[i].CloseHour=baseCloseTimes[i]
			end
			Game.NPC[1177].EventB=1418
		end
		
		-- Dead party health display (reduced frequency)
		if Multiplayer and Multiplayer.in_game and hpTimer % 60 == 0 then -- Every second instead of every tick
			local allDead = true
			for i=0,Party.High do
				if Party[i]:IsConscious() then
					allDead = false
					break
				end
			end
			if allDead then
				local pl=Party[0]
				local maxHP=GetMaxHP(pl)
				local FSP=0
				if vars.MAWSETTINGS.buffRework=="ON" and vars.currentManaPool and vars.currentManaPool[0] then
					FSP = vars.currentManaPool[0]
				else
					FSP	= pl:GetFullSP()
				end
				Game.ShowStatusText(StrColor(0,255,0,"Health: " .. Party[0].HP .. "/" .. round(maxHP)) .. StrColor(50,50,255,"  Mana: " .. Party[0].SP .. "/" .. round(FSP)))	
			end
		end
		
		-- Timer system
		vars.LastTime=vars.LastTime or Game.Time
		local timePassed=Game.Time-vars.LastTime
		if timePassed<0 or timePassed>hour then
			timePassed=0
		end
		local irlSeconds=timePassed/128
		MawTimer(irlSeconds)
		vars.LastTime=Game.Time
		
		-- Burst broadcasting system for reliable mapvars sync (from zzBossSync)
		local now = NOW()
		if Multiplayer and Multiplayer.in_game and Multiplayer.im_host and Multiplayer.im_host() and _burst_until and now < _burst_until then
			if now >= (_burst_next or 0) then
				_burst_next = now + (_burst_period or 0.6*SEC)
				ShareMapvarsList()
				syncStats.burstBroadcasts = syncStats.burstBroadcasts + 1
				DebugLog("BURST", string.format("Burst broadcast %d (remaining: %.1fs)", syncStats.burstBroadcasts, (_burst_until - now) / SEC))
			end
		end
		
		-- Log stats periodically (every 30 seconds)
		if hpTimer % 1800 == 0 then  -- 30 seconds at 60fps
			LogSyncStats()
		end
	end
end

-- Missing variable declarations
local isMultiplayerActive=false
local connectedPlayers=1
local shareData=false
local storeTime=false
local baseTransportTable={}
local baseOpenTimes={}  
local baseCloseTimes={}


-- Validation functions for testing
local function ValidateMapvarsSync()
	if not Multiplayer or not Multiplayer.in_game then 
		return false, "Not in multiplayer game"
	end
	
	if not vars.StoredMapvars then
		return false, "StoredMapvars not initialized"
	end
	
	if Multiplayer.im_host() and not next(vars.StoredMapvars) then
		return false, "Host has no stored mapvars"
	end
	
	return true, "Mapvars sync appears functional"
end

local function ValidateHealthSync()
	if not vars.online or not vars.online.partyHealthMana then
		return false, "Health sync not initialized"
	end
	
	local parties = vars.online.partyHealthMana.Parties
	if not parties then
		return false, "No party health data"
	end
	
	local count = 0
	for k,v in pairs(parties) do
		count = count + 1
	end
	
	return true, string.format("Health sync active with %d parties", count)
end

-- Console commands for testing and debugging
function EnableSyncDebug()
	DEBUG_SYNC = true
	print("Sync debugging enabled. Use DisableSyncDebug() to turn off.")
	LogSyncStats()
end

function DisableSyncDebug()
	DEBUG_SYNC = false
	print("Sync debugging disabled.")
end

function TestSyncSystems()
	print("=== Multiplayer Sync System Status ===")
	
	local mapOk, mapMsg = ValidateMapvarsSync()
	print("Mapvars Sync: " .. (mapOk and "✓ " or "✗ ") .. mapMsg)
	
	local healthOk, healthMsg = ValidateHealthSync()
	print("Health Sync: " .. (healthOk and "✓ " or "✗ ") .. healthMsg)
	
	if Multiplayer and Multiplayer.in_game then
		print("Multiplayer Status: ✓ In multiplayer game")
		print("Role: " .. (Multiplayer.im_host() and "Host" or "Client"))
		print("Players on map: " .. PlayersOnMap())
	else
		print("Multiplayer Status: ✗ Not in multiplayer")
	end
	
	LogSyncStats()
	print("===================================")
end

function ResetSyncStats()
	syncStats = {
		healthUpdates = 0,
		mapvarsSync = 0,
		clientRequests = 0,
		burstBroadcasts = 0,
		packetsSent = 0,
		packetsReceived = 0
	}
	print("Sync statistics reset.")
end

function events.CalcTrainingTime(t)
	if Multiplayer and Multiplayer.in_game then
		t.Time=0
	end
end

local MawTimers = {}

-- add a periodic task
function MawAddTimer(name, interval, fn)
  assert(type(fn) == "function", "MawAddTimer('"..tostring(name).."'): fn must be a function, got "..type(fn))
  MawTimers[name] = { interval = interval, acc = 0, fn = fn, enabled = true }
end

-- optional helpers
function MawEnableTimer(name, enabled)
  local t = MawTimers[name]; if t then t.enabled = (enabled ~= false) end
end

function MawRemoveTimer(name) MawTimers[name] = nil end
function MawSetInterval(name, interval) local t=MawTimers[name]; if t then t.interval = interval end end
function MawResetTimer(name) local t=MawTimers[name]; if t then t.acc = 0 end end

-- call this every frame with seconds since last frame
function MawTimer(dt)
  if not dt or dt <= 0 then return end
  for _, t in pairs(MawTimers) do
    if t.enabled then
      t.acc = t.acc + dt
      if t.acc >= t.interval then
        local fn = t.fn
        if fn then fn(t.acc) end   -- minimal guard: skip if fn is nil
        t.acc = 0
      end
    end
  end
end

-- register your timers (make sure these functions are defined BEFORE this point)
MawAddTimer("horizontalModeMasteries", 0.5, horizontalModeMasteries)
MawAddTimer("MawRegen", 0.1, function(elapsed) MawRegen(elapsed) end)
MawAddTimer("leecher", 0.5, leecher)
MawAddTimer("checkOutOfBound", 2, checkOutOfBound)
MawAddTimer("eliteRegen", 0.1, eliteRegen)
MawAddTimer("mappingRegen", 1, mappingRegen)
MawAddTimer("checkMapCompletition", 10, checkMapCompletition) -- double-check this name/spelling
MawAddTimer("nightmare", 0.5, nightmare)
MawAddTimer("elementalBuffs", 1, elementalBuffs)
MawAddTimer("mawBuffApply", 0.5, mawBuffApply)
MawAddTimer("elementalistStacksDecay", 0.1, elementalistStacksDecay)
MawAddTimer("poisonTimer", 1, poisonTimer)


function OnlineLowestHealthPercentage()
	local lowestPercentage=3
	local LPpartyId=-1
	local LPplayerId=-1
	if Multiplayer and Multiplayer.in_game then
		players={}
		for PartyId, party in pairs(vars.online.partyHealthMana.Parties) do
			if party.Map==Map.Name and getDistance(party.X, party.Y, party.Z)<4000 then
				for i=0, party.High do
					if party[i].Dead==0 and party[i].Eradicated==0 then
						local percentage=party[i].HP/party[i].FHP
						if percentage<lowestPercentage then
							lowestPercentage=percentage
							LPpartyId=PartyId
							LPplayerId=i
						end
					end
				end
			end
		end
	end
	return lowestPercentage, LPpartyId, LPplayerId
end

--[[
		mon:SetId(mon.Id)
		mon:LoadFramesAndSounds()
		]]
