-- ==== Buff share — BY RAFIKI59

------------------------------------------------------------
-- ÉTAT / HELPERS
------------------------------------------------------------
local function ensure_state()
  vars = vars or {}
  vars.MAWSETTINGS = vars.MAWSETTINGS or {}
  if type(vars.MAWSETTINGS.buffRadius) ~= "number" then vars.MAWSETTINGS.buffRadius = 20000 end
  vars.MAWSETTINGS.blockSpells = vars.MAWSETTINGS.blockSpells or {}   -- ex: vars.MAWSETTINGS.blockSpells[IMMOLATION_ID]=true

  vars.mawbuff            = vars.mawbuff            or {}  -- [id] = true/1 (flag local) ou {s,m,l} (valeur plate)
  vars._maw_last_sent     = vars._maw_last_sent     or {}  -- [id]=true (envoyé au tick précédent)
  vars.mawbuff_remote     = vars.mawbuff_remote     or {}  -- compat: bool si id a au moins un owner réseau
  vars.maw_remote_owners  = vars.maw_remote_owners  or {}  -- [id] = { [sender]=true, ... }
  vars.maw_remote_values  = vars.maw_remote_values  or {}  -- [id] = { [sender]={s,m,l}, ... }
end

local function isReworkOn()
  local s = vars and vars.MAWSETTINGS and vars.MAWSETTINGS.buffRework
  if s == true or s == 1 then return true end
  return type(s)=="string" and s:lower()=="on"
end

local function inMulti()
  return (Multiplayer and Multiplayer.in_game) and true or false
end

local SEC  = (const and const.Second) or 1
local NOW  = function() return (Game and Game.Time) or 0 end
local BASE_RADIUS  = 20000
local SEND_PERIOD  = 4 * SEC
local START_DELAY  = 5 * SEC
local DAY          = (const and const.Day) or (24*3600)

local function maxSpellId()
  if Game and Game.Spells and type(Game.Spells.High)=="number" then return Game.Spells.High end
  return 300
end

local function dist3(px,py,pz, x,y,z)
  px,py,pz = tonumber(px) or 0, tonumber(py) or 0, tonumber(pz) or 0
  x,y,z    = tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
  local dx,dy,dz = px-x, py-y, pz-z
  return (dx*dx + dy*dy + dz*dz)^0.5
end

local function senderId() return (Multiplayer and Multiplayer.player_id) or "host" end
local function sum3(a,b,c) return (tonumber(a) or 0)+(tonumber(b) or 0)+(tonumber(c) or 0) end

local function pick_max(a,b)
  local as,am,al = a[1] or 0, a[2] or 0, a[3] or 0
  local bs,bm,bl = b[1] or 0, b[2] or 0, b[3] or 0
  if bs>as or (bs==as and (bm>am or (bm==am and bl>al))) then return b else return a end
end

local function lex_gt(a,b)
  local as,am,al = a[1] or 0, a[2] or 0, a[3] or 0
  local bs,bm,bl = b[1] or 0, b[2] or 0, b[3] or 0
  if as~=bs then return as>bs end
  if am~=bm then return am>bm end
  return al>bl
end

local function remote_effective(id)
  local per = vars.maw_remote_values[id]
  if type(per)~="table" then return {0,0,0} end
  local eff = {0,0,0}
  for _,t in pairs(per) do eff = pick_max(eff, t) end
  return eff
end

------------------------------------------------------------
-- WEAK FIX (ultra-robuste)
------------------------------------------------------------
local __MAW_WEAK_IDX = false
local function __maw_find_weak_idx()
  if __MAW_WEAK_IDX ~= false then return __MAW_WEAK_IDX end
  local idx
  if const and const.Condition then
    idx = const.Condition.Weak or idx
    if not idx then
      for k,v in pairs(const.Condition) do
        if type(k)=="string" and k:lower()=="weak" and type(v)=="number" then idx=v; break end
      end
    end
  end
  if not idx and Game and Game.ConditionTxt then
    local hi = (Game.ConditionTxt.High or 20)
    for i=0, hi do
      local t = Game.ConditionTxt[i]
      if t and type(t.Name)=="string" and t.Name:lower():find("weak") then idx=i; break end
    end
  end
  __MAW_WEAK_IDX = idx or nil
  return __MAW_WEAK_IDX
end

local function MAW_ClearWeakAll()
  local idx = __maw_find_weak_idx()
  if not (idx and Party and type(Party.High)=="number") then return end
  for i=0, Party.High do
    local p = Party[i]
    if p and p.Conditions then p.Conditions[idx] = 0 end
  end
end

local function MAW_PrimeWeakClears(n)
  ensure_state()
  n = math.max(tonumber(n) or 0, 0)
  vars._maw_clear_weak_ticks = n
end

function MAW_ClearWeakNow(times)  -- appel manuel si besoin
  MAW_PrimeWeakClears(times or 15)
  MAW_ClearWeakAll()
end

------------------------------------------------------------
-- SOLO: purge seulement les effets "réseau" (garde tes buffs locaux)
------------------------------------------------------------
local function purge_remote_buffs_keep_local()
  ensure_state()
  local changed=false
  for id, owners in pairs(vars.maw_remote_owners) do
    if owners and next(owners) ~= nil then
      if type(vars.mawbuff[id])=="table" then vars.mawbuff[id] = nil; changed = true end
      vars.mawbuff_remote[id]    = nil
      vars.maw_remote_values[id] = nil
      vars.maw_remote_owners[id] = nil
    end
  end
  for id,_ in pairs(vars._maw_last_sent or {}) do
    if vars.mawbuff[id] == nil then vars._maw_last_sent[id] = nil end
  end
  if changed and type(mawBuffApply)=="function" then pcall(mawBuffApply) end
end

------------------------------------------------------------
-- RÉCEPTION (ON / OFF) — N-players owner-aware + blockSpells
------------------------------------------------------------
function events.MAWMapvarArrived(t)
  if t.DataType == "mapvar" then mapvars[t[1]] = t[2]; return end
  if (t.DataType ~= "mawBuffs") and (t.DataType ~= "mawBuffsOff") then return end
  if not isReworkOn() then return end
  ensure_state()

  if not (t.X and t.Y and t.Z) then return end
  local dist = (getDistance and getDistance(t.X, t.Y, t.Z))
  if type(dist) ~= "number" then
    local dx,dy,dz = Party.X - t.X, Party.Y - t.Y, Party.Z - t.Z
    dist = (dx*dx + dy*dy + dz*dz)^0.5
  end
  local R = vars.MAWSETTINGS.buffRadius or BASE_RADIUS
  if dist > R then return end

  local BLOCK  = vars.MAWSETTINGS.blockSpells or {}
  local sender = tostring(t.sender or "?")
  local dtype  = t.DataType
  local changed=false

  if dtype == "mawBuffs" then
    for id, payload in pairs(t) do
      if type(id)=="number" and type(payload)=="table" and not BLOCK[id] then
        local owners = vars.maw_remote_owners[id] or {}
        owners[sender] = true
        vars.maw_remote_owners[id] = owners

        local perSender = vars.maw_remote_values[id] or {}
        perSender[sender] = { tonumber(payload[1]) or 0, tonumber(payload[2]) or 0, tonumber(payload[3]) or 0 }
        vars.maw_remote_values[id] = perSender

        local eff = remote_effective(id)
        local v = vars.mawbuff[id]
        if not (type(v)=="number" or v==true) then
          local old = vars.mawbuff[id]
          if (type(old)~="table") or (old[1]~=eff[1] or old[2]~=eff[2] or old[3]~=eff[3]) then
            vars.mawbuff[id] = { eff[1], eff[2], eff[3] }
            changed = true
          end
        end
        vars.mawbuff_remote[id] = true
      end
    end
  else -- mawBuffsOff
    for id,_ in pairs(t) do
      if type(id)=="number" then
        local owners = vars.maw_remote_owners[id]
        if owners then owners[sender] = nil end
        local perSender = vars.maw_remote_values[id]
        if perSender then perSender[sender] = nil end

        local hasOther = owners and (next(owners) ~= nil)
        if hasOther then
          local eff = remote_effective(id)
          local v = vars.mawbuff[id]
          if not (type(v)=="number" or v==true) then
            if (type(v)~="table") or (v[1]~=eff[1] or v[2]~=eff[2] or v[3]~=eff[3]) then
              vars.mawbuff[id] = { eff[1], eff[2], eff[3] }
              changed = true
            end
          end
          vars.mawbuff_remote[id] = true
        else
          if type(vars.mawbuff[id])=="table" then
            vars.mawbuff[id] = nil
            changed = true
            if type(mawRemoveBuff)=="function" then pcall(mawRemoveBuff, id) end
          end
          vars.mawbuff_remote[id]   = nil
          vars.maw_remote_values[id]= nil
          vars.maw_remote_owners[id]= nil
        end
      end
    end
  end

  if changed and type(mawBuffApply)=="function" then pcall(mawBuffApply) end
end

------------------------------------------------------------
-- ENVOI (ON + OFF) — base V1 + fallback de détection locale
------------------------------------------------------------
local function sendBuffs()
  if not inMulti() then return end
  if not isReworkOn() then return end
  ensure_state()

  local payload_on  = { DataType="mawBuffs",    X=Party.X, Y=Party.Y, Z=Party.Z, Time=NOW() + 6*SEC, sender=senderId() }
  local payload_off = { DataType="mawBuffsOff", X=Party.X, Y=Party.Y, Z=Party.Z, Time=NOW() + 6*SEC, sender=senderId() }

  local BLOCK = vars.MAWSETTINGS.blockSpells or {}
  local current = {}
  local hasOn, hasOff = false, false

  -- 1) V1 classique
  for id, v in pairs(vars.mawbuff) do
    if type(id)=="number" and not BLOCK[id] then
      local owners = vars.maw_remote_owners[id]
      local isRemote = owners and next(owners)~=nil
      local s,m,l = 0,0,0
      local localActive=false

      if (type(v)=="number" and v~=0) or v==true then
        localActive = true
        if type(getBuffSkill)=="function" then s,m,l = getBuffSkill(id) end
      elseif type(v)=="table" and not isRemote then
        localActive = true
        s = tonumber(v[1]) or 0; m = tonumber(v[2]) or 0; l = tonumber(v[3]) or 0
        if (s+m+l)==0 and type(getBuffSkill)=="function" then s,m,l = getBuffSkill(id) end
      end

      if localActive and (s+m+l)>0 then
        payload_on[id] = { s,m,l }
        current[id] = true
        hasOn = true
      end
    end
  end

  -- 2) FALLBACK: scanner les sorts actifs via getBuffSkill
  if type(getBuffSkill)=="function" then
    local maxId = maxSpellId()
    for id=1,maxId do
      if not BLOCK[id] and not current[id] then
        local s,m,l = getBuffSkill(id)
        local gs = { tonumber(s) or 0, tonumber(m) or 0, tonumber(l) or 0 }
        if (gs[1]+gs[2]+gs[3]) > 0 then
          local owners = vars.maw_remote_owners[id]
          local eff = remote_effective(id)
          if (not owners or next(owners)==nil) or lex_gt(gs, eff) then
            payload_on[id] = { gs[1], gs[2], gs[3] }
            current[id] = true
            hasOn = true
            if vars.mawbuff[id] == nil then vars.mawbuff[id] = 1 end
          end
        end
      end
    end
  end

  -- OFF = ce qu’on avait envoyé au tick-1 mais plus actif
  for id,_ in pairs(vars._maw_last_sent or {}) do
    if not current[id] and not BLOCK[id] then
      payload_off[id] = 1
      hasOff = true
    end
  end

  if hasOn  then Multiplayer.broadcast_mapdata(payload_on,  "MAWMapvarArrived") end
  if hasOff then Multiplayer.broadcast_mapdata(payload_off, "MAWMapvarArrived") end
  vars._maw_last_sent = current
end

------------------------------------------------------------
-- WEAK FIX + blocage de sorts (multi uniquement)
------------------------------------------------------------
local function block_forbidden_spells_in_multi()
  if not inMulti() or not isReworkOn() then return end
  local BLOCK = vars.MAWSETTINGS.blockSpells or {}
  if type(getBuffSkill)~="function" then return end
  for id,blocked in pairs(BLOCK) do
    if blocked then
      local s,m,l = getBuffSkill(id)
      if sum3(s,m,l) > 0 then
        if type(mawRemoveBuff)=="function" then pcall(mawRemoveBuff, id) end
        if vars.mawbuff then vars.mawbuff[id] = nil end
        vars.mawbuff_remote[id]   = nil
        vars.maw_remote_values[id]= nil
        vars.maw_remote_owners[id]= nil
      end
    end
  end
end

------------------------------------------------------------
-- TIMERS / EVENTS — base V1 + OFF sync + purges remote en solo + WEAK prime
------------------------------------------------------------
local timersArmed = false
local function armTimerIfReady()
  if inMulti() and isReworkOn() and not timersArmed then
    Timer(sendBuffs, SEND_PERIOD, true)
    timersArmed = true
  end
end

function events.Tick()
  ensure_state()

  -- weak fix après gros saut de temps
  vars._maw_last_time = vars._maw_last_time or NOW()
  local now = NOW()
  if (now - vars._maw_last_time) > (DAY*6) then
    vars._maw_last_sent = {}
    MAW_ClearWeakAll()
    MAW_PrimeWeakClears(15)
  end
  vars._maw_last_time = now

  -- rafale de clear weak au chargement / transitions
  if vars._maw_clear_weak_ticks and vars._maw_clear_weak_ticks > 0 then
    MAW_ClearWeakAll()
    vars._maw_clear_weak_ticks = vars._maw_clear_weak_ticks - 1
  end

  block_forbidden_spells_in_multi()

  if (type(now)=="number") and (type(START_DELAY)=="number") and (now < START_DELAY) then return end
  armTimerIfReady()
end

function events.LoadMap()
  timersArmed = false
  ensure_state()
  vars._maw_last_sent = {}
  if not inMulti() then purge_remote_buffs_keep_local() end
  MAW_PrimeWeakClears(15)
end

function events.GameLoaded()
  timersArmed = false
  ensure_state()
  vars._maw_last_sent = {}
  if not inMulti() then purge_remote_buffs_keep_local() end
  MAW_PrimeWeakClears(15)
end

function events.MultiplayerInitialized()
  timersArmed = false
  ensure_state()
  Multiplayer.VERSION = "MAW " .. Multiplayer.VERSION
  Multiplayer.allow_remote_event("mawBuffs")
  Multiplayer.allow_remote_event("MAWMapvarArrived")
  Multiplayer.allow_remote_event("mawMultiPlayerData")
  armTimerIfReady()
  MAW_PrimeWeakClears(15)
end

-- GameOver / DeathMenu: purge remote (garde flags locaux) + weak fix
local function purge_remote_only_and_weak()
  ensure_state()
  local changed=false
  for id,_ in pairs(vars.maw_remote_owners or {}) do
    if type(vars.mawbuff[id])=="table" then vars.mawbuff[id]=nil; changed=true end
    vars.mawbuff_remote[id]   = nil
    vars.maw_remote_values[id]= nil
    vars.maw_remote_owners[id]= nil
  end
  vars._maw_last_sent = {}
  MAW_ClearWeakAll()
  if changed and type(mawBuffApply)=="function" then pcall(mawBuffApply) end
end

function events.GameOver()
  purge_remote_only_and_weak()
  MAW_PrimeWeakClears(15)
end

function events.DeathMenu()
  purge_remote_only_and_weak()
  MAW_PrimeWeakClears(15)
end
