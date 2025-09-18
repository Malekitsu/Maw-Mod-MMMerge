-- zzzOnline_HealthMana_Consolidated.lua

----------------------------------------------------------------
-- ONE-TIME GUARD
----------------------------------------------------------------
if __ONLINE_CONSOLIDATED_LOADED__ then return end
__ONLINE_CONSOLIDATED_LOADED__ = true

----------------------------------------------------------------
-- GLOBAL STATE / DEFAULTS
----------------------------------------------------------------
vars    = vars    or {}
mapvars = mapvars or {}

onlineQualityOfLifeFeatures = (onlineQualityOfLifeFeatures ~= false)

vars.StoredMapvars = vars.StoredMapvars or {}
vars.MAWSETTINGS   = vars.MAWSETTINGS   or {}
vars.online        = vars.online        or {}
vars.online.partyHealthMana = vars.online.partyHealthMana or { Parties = {} }

-- Snapshots pour la logique diff
vars._lastHealthSnap = vars._lastHealthSnap or { _mine = nil, _host = nil }
vars._lastPos        = vars._lastPos        or { X = nil, Y = nil, Z = nil }

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function round(x) return math.floor((tonumber(x) or 0) + 0.5) end
local function clamp(v, a, b) v=tonumber(v) or 0; return (v<a and a) or (v>b and b) or v end

if not _G.StrColor then
  function StrColor(r,g,b,s)
    return string.format("\x1B%c%c%c%s", clamp(r,0,255),clamp(g,0,255),clamp(b,0,255), s or "")
  end
end
--[[
function GetMaxHP(pl)
  if not pl then return 1 end
  if pl.GetFullHP then return math.max(1, pl:GetFullHP()) end
  return math.max(1, pl.HP or 1)
end
]]

local function getDistance(x, y, z)
  local dx, dy, dz = (Party.X - (x or 0)), (Party.Y - (y or 0)), (Party.Z - (z or 0))
  return math.sqrt(dx*dx + dy*dy + dz*dz)
end
_G.getDistance = _G.getDistance or getDistance

local SEC = (const and const.Second) or 1
local function NOW() return (Game and Game.Time) or 0 end
local _net_quiet_until = 0
local function NetQuiet(secs) _net_quiet_until = math.max(_net_quiet_until, NOW() + (secs or 2.5)*SEC) end

local function ensure_online_state()
  vars                   = vars or {}
  vars.MAWSETTINGS       = vars.MAWSETTINGS or {}
  vars.online            = vars.online or {}
  vars.online.partyHealthMana = vars.online.partyHealthMana or { Parties = {} }
  vars._lastHealthSnap   = vars._lastHealthSnap or { _mine = nil, _host = nil }
  vars._lastPos          = vars._lastPos or { X = nil, Y = nil, Z = nil }
end


----------------------------------------------------------------
-- PACKETS & MULTIPLAYER INITIALIZATION
----------------------------------------------------------------
function events.MultiplayerInitialized()
  ensure_online_state()

  local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
  local toptr = mem.topointer

  mawPackets = {
    send_table = {
      bulb = function(tbl) return item_to_bin(tbl) end,
      handler = function(bin_string, metadata)
        local t    = bin_to_item(toptr(bin_string))
        local host = Multiplayer.im_host()

        if t and t.dataType == "healthManaInfo" then
          if host then
            -- côté host : ranger la party du client par senderId
            vars.online.partyHealthMana.Parties[t.senderId] = t.Party
          else
            -- côté client : ne jamais écraser par {} si t.Parties est absent
            if t.Parties and next(t.Parties) ~= nil then
              vars.online.partyHealthMana.Parties = t.Parties
            end
          end
        end

        if t and t.dataType=="heal" then
          local id = tonumber(t.PartyId) or 0
          if id < 0 or id > Party.High then id = 0 end
          local pl = Party[id]
          pl.HP = math.min(GetMaxHP(pl), (pl.HP or 0) + (t.Amount or 0))
          mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, mem.u4[0x75CE00]), const.Spells.Heal, id)
          evt.PlaySound(16010)
          Game.ShowStatusText((t.HealerName or "Ally") .. " heals you for " .. tostring(t.Amount or 0) .. " Hit Points")
        end

        return
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
      Multiplayer.broadcast(mawPackets.send_table:prep(tbl), nil)
    end
  end

  function broadcastToClient(tbl, clientId)
    if Multiplayer and Multiplayer.in_game then
      Multiplayer.add_to_send_queue(clientId, mawPackets.send_table:prep(tbl))
    end
  end
end

----------------------------------------------------------------
-- HEALTH/MANA DIFF SYNC (anti-spam)
----------------------------------------------------------------
local function packPartySnapshot()
  local snap = { High = Party.High, Map = Map.Name, X = Party.X, Y = Party.Y, Z = Party.Z }
  for i = 0, Party.High do
    local pl   = Party[i]
    local FHP  = GetMaxHP(pl)
    local FSP
    if vars.MAWSETTINGS.buffRework=="ON" and vars.currentManaPool and vars.currentManaPool[i] then
      FSP = vars.currentManaPool[i]
    else
      FSP = pl:GetFullSP()
    end
    snap[i] = {
      HP = pl.HP, FHP = FHP,
      SP = pl.SP, FSP = FSP,
      Dead = pl.Dead, Eradicated = pl.Eradicated
    }
  end
  return snap
end

local function changedParty(a, b)
  if not a or not b then return true end
  if a.High ~= b.High then return true end
  for i = 0, a.High do
    local pa, pb = a[i], b[i]
    if not pa or not pb then return true end
    local hp_th = math.max(10, math.floor((pa.FHP or 1)*0.02 + 0.5))
    local sp_th = math.max(10, math.floor((pa.FSP or 1)*0.02 + 0.5))
    if math.abs((pa.HP or 0) - (pb.HP or 0)) >= hp_th then return true end
    if math.abs((pa.SP or 0) - (pb.SP or 0)) >= sp_th then return true end
    if pa.Dead ~= pb.Dead or pa.Eradicated ~= pb.Eradicated then return true end
  end
  return false
end

local function posChanged(threshold)
  threshold = threshold or 768
  local lx,ly,lz = vars._lastPos.X, vars._lastPos.Y, vars._lastPos.Z
  local dx = (lx and math.abs(Party.X - lx) or threshold+1)
  local dy = (ly and math.abs(Party.Y - ly) or threshold+1)
  local dz = (lz and math.abs(Party.Z - lz) or threshold+1)
  return (dx > threshold) or (dy > threshold) or (dz > threshold)
end

local function rememberPos()
  vars._lastPos.X, vars._lastPos.Y, vars._lastPos.Z = Party.X, Party.Y, Party.Z
end

local function SendHealthData_Diff()
  ensure_online_state()
  if not (Multiplayer and Multiplayer.in_game) then return end
  if Multiplayer.im_host() then return end
  if NOW() < _net_quiet_until then return end

  local nowSnap = packPartySnapshot()
  local last    = vars._lastHealthSnap._mine

  local need = changedParty(nowSnap, last) or posChanged(768)
  if not need then return end

  vars._lastHealthSnap._mine = nowSnap
  rememberPos()

  SendToHost({ dataType = "healthManaInfo", senderId = Multiplayer.my_id, Party = nowSnap })
end

local function ShareHealthData_Diff()
  ensure_online_state()
  if not (Multiplayer and Multiplayer.in_game and Multiplayer.im_host()) then return end
  if NOW() < _net_quiet_until then return end

  local parties = vars.online.partyHealthMana.Parties
  -- purge des déconnectés
  for key,_ in pairs(parties) do
    if key ~= 0 and (not Multiplayer.connector or not Multiplayer.connector.clients or not Multiplayer.connector.clients[key]) then
      parties[key] = nil
    end
  end

  local hostSnap = packPartySnapshot()
  local lastHost = vars._lastHealthSnap._host
  local anyChange = changedParty(hostSnap, lastHost) or posChanged(768)

  if anyChange then vars._lastHealthSnap._host = hostSnap; rememberPos() end
  parties[0] = hostSnap

  if anyChange then
    BroadcastToAllClients({ dataType = "healthManaInfo", Parties = parties })
  end
end

-- Health sync timer - needs to be here due to function scope
MawAddTimer("healthSync", 0.6, function()
  if not (Multiplayer and Multiplayer.in_game) then return end
  if Multiplayer.im_host() then
    ShareHealthData_Diff()
  else
    SendHealthData_Diff()
  end
end)

----------------------------------------------------------------
-- HEAL API
----------------------------------------------------------------
function SendHeal(clientId, partyId, amount, healerName)
  if not (Multiplayer and Multiplayer.in_game) then return end
  local data = { dataType="heal", PartyId=partyId, Amount=amount, HealerName=healerName }
  broadcastToClient(data, clientId)
end

----------------------------------------------------------------
-- QoL ALWAYS-OPEN + SINGLE TICK DRIVER (fix dt)
----------------------------------------------------------------
local baseTransportTable, baseOpenTimes
local isMultiplayerActive = false

local function snapshotTransportAndShops()
  if baseTransportTable and baseOpenTimes then return end
  baseTransportTable = {}
  for i=0, Game.TransportLocations.High do
    local t = Game.TransportLocations[i]
    baseTransportTable[i] = {t.Monday,t.Tuesday,t.Wednesday,t.Thursday,t.Friday,t.Saturday,t.Sunday}
  end
  baseOpenTimes = {}
  for i=0, Game.Houses.High do
    baseOpenTimes[i] = { Game.Houses[i].OpenHour, Game.Houses[i].CloseHour }
  end
end

local function enableAlwaysOpen()
  for i=0, Game.TransportLocations.High do
    local tran = Game.TransportLocations[i]
    tran.Monday,tran.Tuesday,tran.Wednesday,tran.Thursday,tran.Friday,tran.Saturday,tran.Sunday =
      true,true,true,true,true,true,true
  end
  for i=0, Game.Houses.High do
    Game.Houses[i].OpenHour, Game.Houses[i].CloseHour = 0, 0
  end
end

local function restoreSchedules()
  if not (baseTransportTable and baseOpenTimes) then return end
  for i=0, Game.TransportLocations.High do
    local t = baseTransportTable[i]
    if t then
      local tran = Game.TransportLocations[i]
      tran.Monday,tran.Tuesday,tran.Wednesday,tran.Thursday,tran.Friday,tran.Saturday,tran.Sunday =
        t[1],t[2],t[3],t[4],t[5],t[6],t[7]
    end
  end
  for i=0, Game.Houses.High do
    local t = baseOpenTimes[i]
    if t then
      Game.Houses[i].OpenHour, Game.Houses[i].CloseHour = t[1], t[2]
    end
  end
end

-- Timer system is handled by zzMaw-Timers.lua
-- This events.Tick only handles multiplayer-specific logic
function events.Tick()
  ensure_online_state()

    -- QoL: toggle Always-Open pendant le multi
    if onlineQualityOfLifeFeatures and Multiplayer then
      if Multiplayer.in_game then
        if not isMultiplayerActive then
          isMultiplayerActive = true
          vars.ChallengeMode = true
          snapshotTransportAndShops()
          enableAlwaysOpen()
          Game.NPC[1177].EventB = 0
        end
      else
        if isMultiplayerActive then
          isMultiplayerActive = false
          vars.ChallengeMode = false
          restoreSchedules()
          Game.NPC[1177].EventB = 1418
        end
      end
    end

    
    if Multiplayer and Multiplayer.in_game then
      local allDown = true
      for i=0, Party.High do
        if Party[i]:IsConscious() then allDown = false; break end
      end
      if allDown then
        local pl   = Party[0]
        local maxHP= GetMaxHP(pl)
        local FSP  = (vars.MAWSETTINGS.buffRework=="ON" and vars.currentManaPool and vars.currentManaPool[0]) and vars.currentManaPool[0] or pl:GetFullSP()
        Game.ShowStatusText(
          StrColor(0,255,0,  "Health: " .. tostring(Party[0].HP) .. "/" .. tostring(round(maxHP))) ..
          StrColor(50,50,255,"  Mana: "   .. tostring(Party[0].SP) .. "/" .. tostring(round(FSP)))
        )
      end
    end
end

----------------------------------------------------------------
-- MAP / TRAINING HOOKS
----------------------------------------------------------------
function events.CalcTrainingTime(t)
  if Multiplayer and Multiplayer.in_game then t.Time = 0 end
end

function events.BeforeLoadMap()
  ensure_online_state()
end

function events.AfterLoadMap()
  ensure_online_state()
  NetQuiet(2.5)  -- ✅ évite rafales à l'entrée
  vars._lastHealthSnap._mine = nil
  vars._lastHealthSnap._host = nil
  vars._lastPos.X, vars._lastPos.Y, vars._lastPos.Z = nil, nil, nil
  MawResetTimer("healthSync")
end

----------------------------------------------------------------
-- PUBLIC: OnlineLowestHealthPercentage
----------------------------------------------------------------
function OnlineLowestHealthPercentage()
  local lowestPercentage, LPpartyId, LPplayerId = 3, -1, -1
  if Multiplayer and Multiplayer.in_game then
    for PartyId, party in pairs(vars.online.partyHealthMana.Parties) do
      if party.Map == Map.Name and getDistance(party.X, party.Y, party.Z) < 4000 then
        for i=0, (party.High or -1) do
          local p = party[i]
          if p and p.Dead==0 and p.Eradicated==0 and (p.FHP or 0) > 0 then
            local percentage = (p.HP or 0) / (p.FHP or 1)
            if percentage < lowestPercentage then
              lowestPercentage, LPpartyId, LPplayerId = percentage, PartyId, i
            end
          end
        end
      end
    end
  end
  return lowestPercentage, LPpartyId, LPplayerId
end

----------------------------------------------------------------
-- OLD MAPVARS SHARING CODE (commented for reference)
----------------------------------------------------------------
--[[
-- Original mapvars sharing system from zzzOnlineVar.lua
-- This was the older implementation before the consolidated version

-- In packet handler:
if t.dataType=="ShareMapvarsToHost" and Multiplayer.im_host() then 
	if not vars.StoredMapvars[t.MapName] then
		vars.StoredMapvars[t.MapName]=t.Variables
	end
elseif t.dataType=="ShareMapvarsToClients" and not Multiplayer.im_host() then
	vars.StoredMapvars=t.Variables
elseif t.dataType=="characterInfo" then
	vars.online.party[t.Id]=t.Playerinfo
end

-- Original ShareMapvarsList function:
function ShareMapvarsList()
	if Multiplayer and Multiplayer.in_game and Multiplayer.im_host() then
		BroadcastToAllClients({dataType="ShareMapvarsToClients", Variables=vars.StoredMapvars}) 	
	end
end

-- Original BeforeLoadMap:
function events.BeforeLoadMap()
	if not mapvars.bossGenerated and vars.StoredMapvars[Map.Name] then
		mapvars=vars.StoredMapvars[Map.Name]
		vars.StoredMapvars[Map.Name]=nil
	elseif not mapvars.bossGenerated then
		shareData=true
	end
end

-- Original AfterLoadMap:
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

-- Original PlayersOnMap function:
function PlayersOnMap()
	local count = 1
	for k,v in pairs(Multiplayer.connector.clients) do
		if v.map == Map.MapStatsIndex then
			count = count + 1
		end
	end
	return count
end

-- Original player count monitoring in Tick:
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
--]]

