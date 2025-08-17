-- ==== Buff share — BY RAFIKI59
-- ==== + mawmapvarsend compat + N-players owner-aware + OFF sync
-- ==== + multi-only blockSpells + SOLO: purge remote-only
-- ==== + WEAK fix béton (burst) + fenêtre de protection post-death synchronisée

------------------------------------------------------------
-- ÉTAT / HELPERS
------------------------------------------------------------
local function ensure_state()
  vars = vars or {}
  vars.MAWSETTINGS = vars.MAWSETTINGS or {}
  if type(vars.MAWSETTINGS.buffRadius) ~= "number" then vars.MAWSETTINGS.buffRadius = 20000 end
  vars.MAWSETTINGS.blockSpells = vars.MAWSETTINGS.blockSpells or {}   -- ex: vars.MAWSETTINGS.blockSpells[IMMOLATION_ID]=true
  vars.MAWSETTINGS.blockSpells[8] = true

  vars.mawbuff            = vars.mawbuff            or {}  -- [id] = true/1 (flag local) ou {s,m,l} (valeur plate)
  vars._maw_last_sent     = vars._maw_last_sent     or {}  -- [id]=true (envoyé au tick précédent)
  vars.mawbuff_remote     = vars.mawbuff_remote     or {}  -- compat: bool si id a au moins un owner réseau
  vars.maw_remote_owners  = vars.maw_remote_owners  or {}  -- [id] = { [sender]=true, ... }
  vars.maw_remote_values  = vars.maw_remote_values  or {}  -- [id] = { [sender]={s,m,l}, ... }
end

-- === Compat maps: mawmapvarsend shim ===
if not rawget(_G, "mawmapvarsend") then
  local function __senderId()
    return (Multiplayer and Multiplayer.player_id) or "host"
  end
  function mawmapvarsend(key, val)
    -- maj locale immédiate (solo & host)
    mapvars = mapvars or {}
    mapvars[key] = val
    -- diffusion réseau si en multi
    if Multiplayer and Multiplayer.in_game then
      -- on s'assure que l'event est autorisé (idempotent)
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

------------------------------------------------------------
-- SAFETY SHIMS (anti-crash globaux) - FOR DOOM MODE
------------------------------------------------------------
do
  -- Wrapper global de mawBuffApply: évite que l'event loop meure
  if type(rawget(_G, "mawBuffApply")) == "function" and not _G.__MAW_WRAP_APPLY then
    local __orig_mawBuffApply = mawBuffApply
    _G.__MAW_WRAP_APPLY = true
    function mawBuffApply(...)
      local ok, res = pcall(__orig_mawBuffApply, ...)
      if not ok then
        -- journalisation douce; évite la tempête de logs
        if Game and Game.ShowStatusText then Game.ShowStatusText("MAW: apply (safe)") end
        -- on n'échoue pas: on laisse les timers/handlers continuer
        return nil
      end
      return res
    end
  end
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
-- WEAK FIX (ultra-robuste) + résout le cache 'nil' trop tôt
------------------------------------------------------------
-- Ne JAMAIS cacher 'nil' : on ne retient que les index valides.
local __MAW_WEAK_IDX = nil

local function __maw_try_detect_weak_idx()
  -- 1) Const si dispo
  if const and const.Condition then
    if type(const.Condition.Weak) == "number" then return const.Condition.Weak end
    for k, v in pairs(const.Condition) do
      if type(k) == "string" and type(v) == "number" and k:lower() == "weak" then
        return v
      end
    end
  end
  -- 2) Table texte (localisée) si dispo
  if Game and Game.ConditionTxt then
    local hi = Game.ConditionTxt.High or 32
    for i = 0, hi do
      local t = Game.ConditionTxt[i]
      if t and type(t.Name) == "string" then
        local name = t.Name:lower()
        -- mots-clés multi-langues (FR/EN/DE/ES…)
        if name:find("weak") or name:find("faib") or name:find("schwach")
           or name:find("débil") or name:find("debil") then
          return i
        end
      end
    end
  end
  -- 3) Rien trouvé (encore trop tôt)
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
  -- Recalcule tant qu’on n’a pas une valeur valide
  return __maw_refresh_weak_index()
end

local function MAW_ClearWeakAll()
  local idx = __maw_find_weak_idx()
  if not Party or type(Party.High) ~= "number" then return end

  for i = 0, Party.High do
    local p = Party[i]
    if p then
      -- timestamp Weak (beaucoup de scripts font p.Weak = Game.Time)
      if p.Weak then p.Weak = 0 end
      -- drapeau condition si on a l’index
      if idx and p.Conditions then p.Conditions[idx] = 0 end
      -- Filet de secours : si idx inconnu, on tente un sweep conditionnel localisé
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


-- --- fenêtre temps: protège contre les ré-applies "spammy"
local function __maw_now() return (Game and Game.Time) or 0 end

local function __maw_protect_active()
  return vars and vars._maw_weak_protect_until and ((Game and Game.Time) or 0) < vars._maw_weak_protect_until
end

-- Neutralise les re-applies Weak pendant la fenêtre de protection
function events.CalcDamageToPlayer(t)
  if vars and vars._maw_weak_protect_until and ((Game and Game.Time) or 0) < vars._maw_weak_protect_until then
    if t and t.Player then
      if t.Player.Weak and t.Player.Weak ~= 0 then t.Player.Weak = 0 end
      local idx = __maw_find_weak_idx()
      if idx and t.Player.Conditions then t.Player.Conditions[idx] = 0 end
    end
  end
end


-- --- burst + protect combinés
local function MAW_PrimeWeakClears(n)
  ensure_state()
  n = math.max(tonumber(n) or 0, 0)
  vars._maw_clear_weak_ticks = n
end

function MAW_ClearWeakNow(times)
  MAW_PrimeWeakClears(times or 15)
  MAW_ClearWeakAll()
end

-- --- réseau: broadcast d’un ordre weak (prime/clear/protect)
local function __maw_broadcast_weak(msg)
  if not (Multiplayer and Multiplayer.in_game) then return end
  if Multiplayer.allow_remote_event then Multiplayer.allow_remote_event("MAWMapvarArrived") end
  local payload = {
    DataType = "mawWeak",
    action   = msg.action,     -- "prime", "clear", "protect"
    ticks    = msg.ticks,      -- nb de ticks pour prime
    seconds  = msg.seconds,    -- durée fenêtre protect
    X = (Party and Party.X) or 0,
    Y = (Party and Party.Y) or 0,
    Z = (Party and Party.Z) or 0,
    sender = (Multiplayer and Multiplayer.player_id) or "host"
  }
  Multiplayer.broadcast_mapdata(payload, "MAWMapvarArrived")
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
-- RÉCEPTION (ON / OFF) — N-players owner-aware + blockSpells + WEAK net
------------------------------------------------------------
function events.MAWMapvarArrived(t)
  if not t or type(t) ~= "table" then return end

  -- 0) mapvar passthrough
  if t.DataType == "mapvar" then
    mapvars = mapvars or {}
    mapvars[t[1]] = t[2]
    return
  end

-- 0bis) WEAK network control
if t.DataType == "mawWeak" then
  if t.action == "clear" then
    MAW_ClearWeakAll()
    return
  elseif t.action == "prime" then
    MAW_PrimeWeakClears(tonumber(t.ticks) or 15)
    MAW_ClearWeakAll()
    return
  elseif t.action == "protect" then
    local secs = tonumber(t.seconds) or 30
    MAW_StartWeakProtect(secs)   -- démarre aussi le micro-timer
    return
  end
end

  -- 1) Buffs
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
-- TIMERS / EVENTS — OFF sync + solo purge + WEAK prime + protect réseau
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

  -- protection post-mort: force-clear tant que la fenêtre est ouverte
  if vars._maw_weak_protect_until and __maw_now() < vars._maw_weak_protect_until then
    MAW_ClearWeakAll()
  end

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
  __maw_refresh_weak_index()
end

function events.GameLoaded()
  timersArmed = false
  ensure_state()
  vars._maw_last_sent = {}
  if not inMulti() then purge_remote_buffs_keep_local() end
  MAW_PrimeWeakClears(15)
  __maw_refresh_weak_index()
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
  __maw_refresh_weak_index()
end

-- GameOver / DeathMenu: purge remote (garde flags locaux) + weak fix + protect réseau
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
  MAW_PrimeWeakClears(20)
  MAW_StartWeakProtect(30)
  __maw_broadcast_weak{ action="prime", ticks=20 }
  __maw_broadcast_weak{ action="protect", seconds=30 }
end

function events.DeathMenu()
  purge_remote_only_and_weak()
  MAW_PrimeWeakClears(20)
  MAW_StartWeakProtect(30)
  __maw_broadcast_weak{ action="prime", ticks=20 }
  __maw_broadcast_weak{ action="protect", seconds=30 }
end
