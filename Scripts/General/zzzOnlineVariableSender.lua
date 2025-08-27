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
				local host=Multiplayer.im_host()
				
				if t.dataType=="healthManaInfo" and host then
					vars.online.partyHealthMana.Parties[t.senderId]=t.Parties
				elseif t.dataType=="healthManaInfo" then
					vars.online.partyHealthMana.Parties=t.Parties
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
				end
				
				--debug.Message(dump(t))
				
				
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
		if Multiplayer and Multiplayer.in_game and Multiplayer.packets then
			Multiplayer.add_to_send_queue(0, mawPackets.send_table:prep(tbl))
		end
	end

	function BroadcastToAllClients(tbl)
		if Multiplayer and Multiplayer.in_game and Multiplayer.im_host() then
			Multiplayer.broadcast(mawPackets.send_table:prep(tbl),nil)
		end
	end
	
	function broadcastToClient(tbl, clientId)
		if Multiplayer and Multiplayer.in_game then
			Multiplayer.add_to_send_queue(clientId, mawPackets.send_table:prep(tbl))
		end
	end

	--maw code
	function ShareMapvarsList()
		if Multiplayer and Multiplayer.in_game and Multiplayer.im_host() then
			BroadcastToAllClients({dataType="ShareMapvarsToClients", Variables=vars.StoredMapvars}) 	
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
	
	--SHARE PARTY INFO BETWEEN PLAYERS
	local healthUpdateTimer=10
	local hpTimer=0
	function events.Tick()
		hpTimer=hpTimer+1
		
		if hpTimer>=healthUpdateTimer then
			hpTimer=0
			if Multiplayer and Multiplayer.in_game then
				if Multiplayer.im_host() then
					ShareHealthData()
				else
					SendHealthData()
				end
			end
		end
	end
	function SendHealthData()
		local myId=Multiplayer.my_id
		local data={}
		data.Party={}
		data.Party.X=Party.X
		data.Party.Y=Party.Y
		data.Party.Z=Party.Z
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
			data.Party[i].High=Party.High
		end
		data.dataType="healthManaInfo"
		data.senderId=myId
		SendToHost(data)
	end
	function ShareHealthData()
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

--show health when dead
function events.Tick()
	if not Multiplayer or not Multiplayer.in_game then return end
	for i=0,Party.High do
		if Party[i]:IsConscious() then
			return
		end
	end
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

function events.CalcTrainingTime(t)
	if Multiplayer and Multiplayer.in_game then
		t.Time=0
	end
end
function events.BeforeLoadMap()
	vars.StoredMapvars=vars.StoredMapvars or {}
	
	vars.online=vars.online or {}
	
	vars.online.partyHealthMana={}
	vars.online.partyHealthMana.Parties={}
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


function OnlineLowestHealthPercentage()
	local lowestPercentage=3
	local LPpartyId=-1
	local LPplayerId=-1
	if Multiplayer and Multiplayer.in_game then
		players={}
		for PartyId, party in pairs(vars.online.partyHealthMana.Parties) do
			if party.Map==Map.Name and getDistance(party.X, party.Y, party.Z)<4000 then
				for i=0, party.High do
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
	return lowestPercentage, LPpartyId, LPplayerId
end
