function events.MultiplayerInitialized()
	local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
	local toptr = mem.topointer

	mawPackets = {
		send_table = {
			bulb = function(tbl)
				return item_to_bin(tbl)
			end,

			handler = function(bin_string, metadata)
				local t = bin_to_item(toptr(bin_string))
				return --[[
				if t.dataType=="ShareMapvarsToHost" and Multiplayer.im_host() then 
					if not vars.StoredMapvars[t.MapName] then
						vars.StoredMapvars[t.MapName]=t.Variables
					end
				elseif t.dataType=="ShareMapvarsToClients" and not Multiplayer.im_host() then
					vars.StoredMapvars=t.Variables
				elseif t.dataType=="characterInfo" then
					vars.online.party[t.Id]=t.Playerinfo
				end
				
				]]
			end,
			
			check_delivery = true,
			compress = true
		}
	}

	Multiplayer.utils.init_packets(mawPackets)
	
	function SendToHost(tbl)
		if Multiplayer and Multiplayer.in_game and Multiplayer.packets and mawPackets.send_table then
			Multiplayer.add_to_send_queue(0, mawPackets.send_table:prep(tbl))
		end
	end

	function BroadcastToClients(tbl)
		if Multiplayer and Multiplayer.in_game and Multiplayer.im_host() then
			Multiplayer.broadcast(mawPackets.send_table:prep(tbl),nil)
		end
	end


	--maw code
	function ShareMapvarsList()
		if Multiplayer and Multiplayer.in_game and Multiplayer.im_host() then
			BroadcastToClients({dataType="ShareMapvarsToClients", Variables=vars.StoredMapvars}) 	
		end
	end
	
	function events.BeforeLoadMap()
		if not mapvars.bossGenerated and vars.StoredMapvars[Map.Name] then
			mapvars=vars.StoredMapvars[Map.Name]
			vars.StoredMapvars[Map.Name]=nil
		elseif not mapvars.bossGenerated then
			shareData=true
		end
	end
	function events.AfterLoadMap()
		if Multiplayer and Multiplayer.in_game and Multiplayer.im_host() then
			vars.StoredMapvars[Map.Name]=mapvars
			ShareMapvarsList()
		end
		if Multiplayer and Multiplayer.in_game and not Multiplayer.im_host() and shareData and mapvars.bossGenerated then
			SendToHost({dataType="ShareMapvarsToHost", MapName=Map.Name, Variables=mapvars})
		end
		shareData=false
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
	
	function events.Tick()
		connectedPlayers=connectedPlayers or 1
		if Multiplayer and Multiplayer.in_game and Multiplayer.im_host() then
			local currentPlayers=PlayersOnMap()
			if currentPlayers>connectedPlayers then
				ShareMapvarsList()
			end
			connectedPlayers=currentPlayers
		end
	end
	local healthUpdateTimer=10
	local playerUpdateTimer=300
	local hpTimer=0
	local plTimer=0
	function events.Tick()
		hpTimer=hpTimer+1
		plTimer=plTimer+1
		
		if hpTimer>=healthUpdateTimer then
			hpTimer=0
			if Multiplayer and Multiplayer.in_game then
				if Multiplayer.im_host() then
					--ShareHealthData()
				else
					--ShareHealthData()
				end
			end
		end
		if plTimer>=playerUpdateTimer then
			plTimer=0
			if Multiplayer and Multiplayer.in_game then
				if Multiplayer.im_host() then
					--SendPartyData()
				else
					--SendPartyData()
				end
			end
		end
	end
end

local isMultiplayerActive=false
function events.Tick()
	if not onlineQualityOfLifeFeatures then return end
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
end
function events.CalcTrainingTime(t)
	if Multiplayer and Multiplayer.in_game then
		t.Time=0
	end
end
function events.BeforeLoadMap()
	vars.StoredMapvars=vars.StoredMapvars or {}
	
	vars.online=vars.online or {}
	vars.online.party=vars.online.party or {}
end

--fix for timer events, specially online
local second=256/60
local minute=256
local hour=15360
local day=368640
local week=2580480
local month=10321920
local year=123863040

function events.Tick()
	vars.LastTime=vars.LastTime or Game.Time
	local timePassed=Game.Time-vars.LastTime
	if timePassed<0 or timePassed>hour then
		timePassed=0
	end
	local irlSeconds=timePassed/128
	MawTimer(irlSeconds)
	vars.LastTime=Game.Time
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
