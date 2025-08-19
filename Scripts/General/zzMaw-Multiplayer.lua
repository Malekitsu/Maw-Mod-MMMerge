-- ==== Buff share — BY RAFIKI59

------------------------------------------------------------
-- ÉTAT / HELPERS
------------------------------------------------------------
local function ensure_state()
  vars = vars or {}
  vars.MAWSETTINGS = vars.MAWSETTINGS or {}
  -- Activer la refonte par défaut (sinon pas d'ON/OFF)
  if vars.MAWSETTINGS.buffRework == nil then vars.MAWSETTINGS.buffRework = true end
  if type(vars.MAWSETTINGS.buffRadius) ~= "number" then vars.MAWSETTINGS.buffRadius = 20000 end
  vars.MAWSETTINGS.blockSpells = vars.MAWSETTINGS.blockSpells or {}   -- ex: vars.MAWSETTINGS.blockSpells[IMMOLATION_ID]=true
  vars.MAWSETTINGS.blockSpells[8] = true

  vars.mawbuff            = vars.mawbuff            or {}  -- [id] = true/1 (flag local) ou {s,m,l} (valeur plate)
  vars._maw_last_sent     = vars._maw_last_sent     or {}  -- [id]=true (envoyé au tick précédent)
  vars.mawbuff_remote     = vars.mawbuff_remote     or {}  -- compat: bool si id a au moins un owner réseau
  vars.maw_remote_owners  = vars.maw_remote_owners  or {}  -- [id] = { [sender]=true, ... }
  vars.maw_remote_values  = vars.maw_remote_values  or {}  -- [id] = { [sender]={s,m,l}, ... }

  -- WEAK
  vars._maw_weak_protect_until = vars._maw_weak_protect_until or 0
  vars._maw_clear_weak_ticks   = vars._maw_clear_weak_ticks   or 0
  vars._maw_last_rescue        = vars._maw_last_rescue        or 0

  -- NO-TIMER scheduler (anti-rewind / time-sync)
  vars._maw_prev_time      = vars._maw_prev_time      or 0
  vars._maw_next_send_at   = vars._maw_next_send_at   or 0
  vars._maw_last_send_time = vars._maw_last_send_time or 0
  vars._maw_burst_ticks    = vars._maw_burst_ticks    or 0
end

-- === Compat maps: mawmapvarsend shim ===
if not rawget(_G, "mawmapvarsend") then
  local function __senderId()
    return (Multiplayer and Multiplayer.player_id) or "host"
  end
  function mawmapvarsend(key, val)
    mapvars = mapvars or {}
    mapvars[key] = val
    if Multiplayer and Multiplayer.in_game then
      if Multiplayer.allow_remote_event then
        Multiplayer.allow_remote_event("MAWMapvarArrived")
      end
      local x = (Party and Party.X) or 0
      local y = (Party and Party.Y) or 0
      local z = (Party and Party.Z) or 0
      Multiplayer.broadcast_mapdata(
        { DataType = "mapvar", [1] = key, [2] = val,
          X = x, Y = y, Z = z, sender = __senderId() },
        "MAWMapvarArrived"
      )
    end
  end
end

local function isReworkOn()
  local s = vars and vars.MAWSETTINGS and vars.MAWSETTINGS.buffRework
  if s == true or s == 1 then return true end
  return type(s)=="string" and s:lower()=="on"
end

local function ensure_remote_events_allowed()
  if Multiplayer and Multiplayer.allow_remote_event then
    Multiplayer.allow_remote_event("mawBuffs")
    Multiplayer.allow_remote_event("MAWMapvarArrived")
    Multiplayer.allow_remote_event("mawMultiPlayerData")
    Multiplayer.allow_remote_event("mawWeakEvt")
  end
end

------------------------------------------------------------
-- SAFETY SHIMS (anti-crash globaux)
------------------------------------------------------------
do
  if type(rawget(_G, "mawBuffApply")) == "function" and not _G.__MAW_WRAP_APPLY then
    local __orig_mawBuffApply = mawBuffApply
    _G.__MAW_WRAP_APPLY = true
    function mawBuffApply(...)
      local ok, res = pcall(__orig_mawBuffApply, ...)
      if not ok then
        if Game and Game.ShowStatusText then Game.ShowStatusText("MAW: apply (safe)") end
        return nil
      end
      return res
    end
  end
end

local function inMulti() return (Multiplayer and Multiplayer.in_game) and true or false end
local SEC  = (const and const.Second) or 1
local NOW  = function() return (Game and Game.Time) or 0 end
local BASE_RADIUS  = 20000
local SEND_PERIOD  = 4 * SEC
local MAX_GAP      = 8 * SEC          -- rattrapage si pas d’envoi depuis trop longtemps
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
-- WEAK FIX (robuste) — canal dédié uniquement
------------------------------------------------------------
local __MAW_WEAK_IDX = nil

local function __maw_try_detect_weak_idx()
  if const and const.Condition then
    if type(const.Condition.Weak) == "number" then return const.Condition.Weak end
    for k, v in pairs(const.Condition) do
      if type(k) == "string" and type(v) == "number" and k:lower() == "weak" then
        return v
      end
    end
  end
  if Game and Game.ConditionTxt then
    local hi = Game.ConditionTxt.High or 32
    for i = 0, hi do
      local t = Game.ConditionTxt[i]
      if t and type(t.Name) == "string" then
        local name = t.Name:lower()
        if name:find("weak") or name:find("faib") or name:find("schwach")
           or name:find("débil") or name:find("debil") then
          return i
        end
      end
    end
  end
  return nil
end

local function __maw_refresh_weak_index()
  if not __MAW_WEAK_IDX then
    local idx = __maw_try_detect_weak_idx()
    if idx then __MAW_WEAK_IDX = idx end
  end
  return __MAW_WEAK_IDX
end

local function __maw_find_weak_idx()
  return __maw_refresh_weak_index()
end

local function MAW_ClearWeakAll()
  local idx = __maw_find_weak_idx()
  if not Party or type(Party.High) ~= "number" then return end
  for i = 0, Party.High do
    local p = Party[i]
    if p then
      if p.Weak then p.Weak = 0 end
      if idx and p.Conditions then p.Conditions[idx] = 0 end
      if (not idx) and p.Conditions and Game and Game.ConditionTxt then
        local hi = Game.ConditionTxt.High or 32
        for j = 0, hi do
          local t = Game.ConditionTxt[j]
          if t and type(t.Name) == "string" then
            local name = t.Name:lower()
            if name:find("weak") or name:find("faib") or name:find("schwach")
               or name:find("débil") or name:find("debil") then
              p.Conditions[j] = 0
            end
          end
        end
      end
    end
  end
end

function MAW_StartWeakProtect(secs)
  ensure_state()
  local dur = math.max(tonumber(secs) or 18, 0)
  vars._maw_weak_protect_until = NOW() + dur
end

local function __maw_now() return (Game and Game.Time) or 0 end

function events.CalcDamageToPlayer(t)
  if vars and vars._maw_weak_protect_until and ((Game and Game.Time) or 0) < vars._maw_weak_protect_until then
    if t and t.Player then
      if t.Player.Weak and t.Player.Weak ~= 0 then t.Player.Weak = 0 end
      local idx = __maw_find_weak_idx()
      if idx and t.Player.Conditions then t.Player.Conditions[idx] = 0 end
    end
  end
end

local function MAW_PrimeWeakClears(n)
  ensure_state()
  n = math.max(tonumber(n) or 0, 0)
  vars._maw_clear_weak_ticks = n
end

function MAW_ClearWeakNow(times)
  MAW_PrimeWeakClears(times or 15)
  MAW_ClearWeakAll()
end

-- Envoi WEAK sur canal dédié (plus de piggyback sur MAWMapvarArrived)
local function __maw_broadcast_weak(msg)
  if not (Multiplayer and Multiplayer.in_game) then return end
  ensure_remote_events_allowed()
  local payload = {
    DataType = "mawWeak",
    action   = msg.action,     -- "prime", "clear", "protect"
    ticks    = msg.ticks,
    seconds  = msg.seconds,
    X = (Party and Party.X) or 0,
    Y = (Party and Party.Y) or 0,
    Z = (Party and Party.Z) or 0,
    sender = (Multiplayer and Multiplayer.player_id) or "host"
  }
  Multiplayer.broadcast_mapdata(payload, "mawWeakEvt")
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
-- RÉCEPTION (ON / OFF) — buffs (plus de WEAK ici)
------------------------------------------------------------
function events.MAWMapvarArrived(t)
  if not t or type(t) ~= "table" then return end

  -- mapvar passthrough
  if t.DataType == "mapvar" then
    mapvars = mapvars or {}
    mapvars[t[1]] = t[2]
    return
  end

  -- Buffs uniquement
  if (t.DataType ~= "mawBuffs") and (t.DataType ~= "mawBuffsOff") then return end
  if not isReworkOn() then return end
  ensure_state()

  if not (t.X and t.Y and t.Z) then return end
  local px,py,pz = (Party and Party.X) or 0, (Party and Party.Y) or 0, (Party and Party.Z) or 0
  local dist = dist3(px,py,pz, t.X,t.Y,t.Z)
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

-- Réception WEAK — canal dédié
function events.mawWeakEvt(t)
  if not t or t.DataType ~= "mawWeak" then return end
  if t.action == "clear" then
    MAW_ClearWeakAll()
  elseif t.action == "prime" then
    MAW_PrimeWeakClears(tonumber(t.ticks) or 15); MAW_ClearWeakAll()
  elseif t.action == "protect" then
    MAW_StartWeakProtect(tonumber(t.seconds) or 30)
  end
end

------------------------------------------------------------
-- ENVOI (ON + OFF) — base V1 + fallback
------------------------------------------------------------
local function sendBuffs()
  if not inMulti() then return end
  if not isReworkOn() then return end
  ensure_state()
  ensure_remote_events_allowed()

  local px,py,pz = 0,0,0
  if Party then px,py,pz = Party.X or 0, Party.Y or 0, Party.Z or 0 end

  local payload_on  = { DataType="mawBuffs",    X=px, Y=py, Z=pz, Time=NOW() + 6*SEC, sender=senderId() }
  local payload_off = { DataType="mawBuffsOff", X=px, Y=py, Z=pz, Time=NOW() + 6*SEC, sender=senderId() }

  local BLOCK = vars.MAWSETTINGS.blockSpells or {}
  local current = {}
  local hasOn, hasOff = false, false

  -- cas local
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

  -- fallback: scanner les sorts actifs
  if type(getBuffSkill)=="function" then
    local maxId = maxSpellId()
    for id=1,maxId do
      if not BLOCK[id] and not current[id] then
        local s,m,l = getBuffSkill(id)
        local gs = { tonumber(s) or 0, tonumber(m) or 0, tonumber(l) or 0 }
        if (gs[1]+gs[2]+gs[3]) > 0 then
          local eff = remote_effective(id)
          if lex_gt(gs, eff) or (eff[1]+eff[2]+eff[3])==0 then
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
  vars._maw_last_send_time = NOW()
end

-- Envoi OFF forcé de tout ce qui était “ON” au tick-1 (utile à la mort / sync)
local function __maw_force_send_off_all()
  if not inMulti() or not isReworkOn() then return end
  ensure_state()
  ensure_remote_events_allowed()
  local px,py,pz = (Party and Party.X) or 0, (Party and Party.Y) or 0, (Party and Party.Z) or 0
  local payload_off = { DataType="mawBuffsOff", X=px, Y=py, Z=pz, Time=NOW()+6*SEC, sender=senderId() }
  local BLOCK = vars.MAWSETTINGS.blockSpells or {}
  local has = false
  for id,_ in pairs(vars._maw_last_sent or {}) do
    if not BLOCK[id] then payload_off[id] = 1; has = true end
  end
  if has then Multiplayer.broadcast_mapdata(payload_off, "MAWMapvarArrived") end
end

------------------------------------------------------------
-- WEAK + blocage de sorts (multi uniquement)
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
-- NO TIMER: SCHEDULER via TICK + détection time-sync
------------------------------------------------------------
local function __maw_on_time_sync()
  -- reset léger et reprise agressive de l’émetteur
  vars._maw_next_send_at = 0
  vars._maw_burst_ticks  = 6      -- quelques pulses rapprochés
  -- On émet tout de suite pour casser les “collages”
  pcall(sendBuffs)
end

local function scheduler_tick(now)
  -- Détection time-sync: temps qui recule ou saut brutal (avant = freeze timers côté moteur)
  local prev = vars._maw_prev_time or now
  local dt = now - prev
  if dt < -0.1 or dt > (DAY*2) then
    __maw_on_time_sync()
  end

  -- Burst d’envoi après load/respawn/sync
  if vars._maw_burst_ticks and vars._maw_burst_ticks > 0 then
    pcall(sendBuffs)
    vars._maw_burst_ticks = vars._maw_burst_ticks - 1
    vars._maw_next_send_at = now + SEND_PERIOD
    vars._maw_prev_time = now
    return
  end

  -- Cadence normale + rattrapage si pas d’envoi depuis trop longtemps
  local nextAt = vars._maw_next_send_at or 0
  local last   = vars._maw_last_send_time or 0
  if now >= nextAt or (now - last) > MAX_GAP then
    pcall(sendBuffs)
    vars._maw_next_send_at = now + SEND_PERIOD
  end

  vars._maw_prev_time = now
end

------------------------------------------------------------
-- EVENTS
------------------------------------------------------------
-- weak local?
local function __maw_has_weak_local()
  if not Party or type(Party.High) ~= "number" then return false end
  local idx = __maw_find_weak_idx()
  for i = 0, Party.High do
    local p = Party[i]
    if p then
      if p.Weak and p.Weak ~= 0 then return true end
      if idx and p.Conditions and (p.Conditions[idx] or 0) ~= 0 then return true end
    end
  end
  return false
end

function events.Tick()
  ensure_state()
  ensure_remote_events_allowed()

  local now = NOW()

  -- protection post-mort: force-clear tant que la fenêtre est ouverte
  if vars._maw_weak_protect_until and now < vars._maw_weak_protect_until then
    MAW_ClearWeakAll()
  end

  -- weak fix après gros saut de temps (jours)
  vars._maw_last_time = vars._maw_last_time or now
  if (now - vars._maw_last_time) > (DAY*6) then
    -- reset doux
    MAW_ClearWeakAll()
    MAW_PrimeWeakClears(15)
  end
  vars._maw_last_time = now

  -- rafale de clear weak au chargement / transitions
  if vars._maw_clear_weak_ticks and vars._maw_clear_weak_ticks > 0 then
    MAW_ClearWeakAll()
    vars._maw_clear_weak_ticks = vars._maw_clear_weak_ticks - 1
  end

  -- AUTO-RESCUE Weak (TEAM B respawn) avec cooldown pour éviter clignotement
  do
    local RESCUE_COOLDOWN = 8 * SEC
    local weakNow = __maw_has_weak_local()
    local protect = vars._maw_weak_protect_until and now < vars._maw_weak_protect_until
    if weakNow and not protect and (now - (vars._maw_last_rescue or 0) > RESCUE_COOLDOWN) then
      MAW_PrimeWeakClears(16)
      MAW_StartWeakProtect(18)
      __maw_broadcast_weak{ action="prime", ticks=16 }
      __maw_broadcast_weak{ action="protect", seconds=18 }
      vars._maw_last_rescue = now
    end
  end

  block_forbidden_spells_in_multi()

  if (type(now)=="number") and (type(START_DELAY)=="number") and (now < START_DELAY) then return end

  -- NO-TIMER scheduler
  if inMulti() and isReworkOn() then
    scheduler_tick(now)
  end
end

local function reset_scheduler_for_resume(burst)
  vars._maw_last_sent = vars._maw_last_sent or {}
  vars._maw_prev_time    = NOW()
  vars._maw_next_send_at = 0
  vars._maw_burst_ticks  = burst or 4
end

function events.LoadMap()
  ensure_state(); ensure_remote_events_allowed()
  if not inMulti() then purge_remote_buffs_keep_local() end
  MAW_PrimeWeakClears(12)
  __maw_refresh_weak_index()
  reset_scheduler_for_resume(4)
  pcall(sendBuffs)  -- pulse immédiat
end

function events.GameLoaded()
  ensure_state(); ensure_remote_events_allowed()
  if not inMulti() then purge_remote_buffs_keep_local() end
  MAW_PrimeWeakClears(12)
  __maw_refresh_weak_index()
  reset_scheduler_for_resume(4)
  pcall(sendBuffs)
end

function events.MultiplayerInitialized()
  ensure_state(); ensure_remote_events_allowed()
  if Multiplayer and Multiplayer.VERSION then Multiplayer.VERSION = "MAW " .. Multiplayer.VERSION end
  MAW_PrimeWeakClears(12)
  __maw_refresh_weak_index()
  reset_scheduler_for_resume(2)
  pcall(sendBuffs)
end

-- purge remote + weak (ne touche pas _maw_last_sent avant OFF forcé)
local function purge_remote_only_and_weak()
  ensure_state()
  local changed=false
  for id,_ in pairs(vars.maw_remote_owners or {}) do
    if type(vars.mawbuff[id])=="table" then vars.mawbuff[id]=nil; changed=true end
    vars.mawbuff_remote[id]   = nil
    vars.maw_remote_values[id]= nil
    vars.maw_remote_owners[id]= nil
  end
  MAW_ClearWeakAll()
  if changed and type(mawBuffApply)=="function" then pcall(mawBuffApply) end
end

-- À la mort: envoyer OFF pour tout ce qui était ON, puis purge + reprise scheduler
function events.GameOver()
  ensure_state(); ensure_remote_events_allowed()
  __maw_force_send_off_all()   -- enlève les buffs “collés” côté A
  purge_remote_only_and_weak()
  vars._maw_last_sent = {}     -- seulement après OFF forcé
  MAW_PrimeWeakClears(20)
  MAW_StartWeakProtect(30)
  __maw_broadcast_weak{ action="prime", ticks=20 }
  __maw_broadcast_weak{ action="protect", seconds=30 }
  reset_scheduler_for_resume(6)
  pcall(sendBuffs)
end

function events.DeathMenu()
  ensure_state(); ensure_remote_events_allowed()
  __maw_force_send_off_all()
  purge_remote_only_and_weak()
  vars._maw_last_sent = {}
  MAW_PrimeWeakClears(20)
  MAW_StartWeakProtect(30)
  __maw_broadcast_weak{ action="prime", ticks=20 }
  __maw_broadcast_weak{ action="protect", seconds=30 }
  reset_scheduler_for_resume(6)
  pcall(sendBuffs)
end
