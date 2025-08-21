-- ==== Buff share — BY RAFIKI59

------------------------------------------------------------
-- ÉTAT / HELPERS
------------------------------------------------------------
local function ensure_state()
  vars = vars or {}
  vars.MAWSETTINGS = vars.MAWSETTINGS or {}
  if vars.MAWSETTINGS.buffRework == nil then vars.MAWSETTINGS.buffRework = true end
  if type(vars.MAWSETTINGS.buffRadius) ~= "number" then vars.MAWSETTINGS.buffRadius = 20000 end
  vars.MAWSETTINGS.blockSpells = vars.MAWSETTINGS.blockSpells or {}
  vars.MAWSETTINGS.blockSpells[8] = true

  vars.mawbuff            = vars.mawbuff            or {}
  vars._maw_last_sent     = vars._maw_last_sent     or {}
  vars.mawbuff_remote     = vars.mawbuff_remote     or {}
  vars.maw_remote_owners  = vars.maw_remote_owners  or {}
  vars.maw_remote_values  = vars.maw_remote_values  or {}

  -- OFF local (débuff manuel protégé)
  vars._maw_local_off     = vars._maw_local_off     or {}

  -- Horloge & cadence
  vars._maw_next_send_time     = vars._maw_next_send_time or 0
  vars._maw_clock_last         = vars._maw_clock_last or 0
  vars._maw_last_time          = vars._maw_last_time or 0
  vars._maw_resend_boost_until = vars._maw_resend_boost_until or 0

  -- Guards
  vars._maw_sync_guard_until   = vars._maw_sync_guard_until or 0
  vars._maw_hostup_guard_until = vars._maw_hostup_guard_until or 0
  vars._maw_hp_floor_abs       = vars._maw_hp_floor_abs or {}
  vars._maw_hp_floor_ratio     = vars._maw_hp_floor_ratio or {}
  vars._maw_hp_last            = vars._maw_hp_last or {}

  -- Weak
  vars._maw_weak_protect_until = vars._maw_weak_protect_until or 0
  vars._maw_clear_weak_ticks   = vars._maw_clear_weak_ticks or 0

  -- Compte morts host
  vars._maw_host_death_count   = vars._maw_host_death_count or 0

  -- Anti-fantômes : epoch et derniers epochs reçus par sender
  vars._maw_epoch              = vars._maw_epoch or 1
  vars._maw_sender_epoch       = vars._maw_sender_epoch or {}
end

local function isReworkOn()
  local s = vars and vars.MAWSETTINGS and vars.MAWSETTINGS.buffRework
  if s == true or s == 1 then return true end
  return type(s)=="string" and s:lower()=="on"
end

local function isHost()
  if not Multiplayer then return true end
  if Multiplayer.is_host ~= nil then return not not Multiplayer.is_host end
  if Multiplayer.IsHost  ~= nil then return not not Multiplayer.IsHost end
  if Multiplayer.host_id and Multiplayer.player_id then return Multiplayer.player_id == Multiplayer.host_id end
  if type(Multiplayer.player_id)=="string" then return Multiplayer.player_id == "host" end
  if type(Multiplayer.player_id)=="number" then return Multiplayer.player_id == 0 end
  return false
end

local function inMulti() return (Multiplayer and Multiplayer.in_game) and true or false end
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
-- HOTFIX RSMem: safe getBuffSkill + highs autodétectés
------------------------------------------------------------
local function safe_getBuffSkill(id)
  if type(getBuffSkill) ~= "function" then return 0,0,0 end
  local ok, s, m, l = pcall(getBuffSkill, id)
  if not ok then return 0,0,0 end
  s = tonumber(s) or 0; m = tonumber(m) or 0; l = tonumber(l) or 0
  return s, m, l
end

local function detect_partybuff_high_fallback()
  local declared = (Party and Party.SpellBuffs and type(Party.SpellBuffs.High)=="number") and Party.SpellBuffs.High
                or ((const and const.PartyBuff and type(const.PartyBuff.High)=="number") and const.PartyBuff.High)
  if type(declared)=="number" then return declared end
  local i, last = 0, -1
  while true do
    local ok = pcall(function() local _ = Party.SpellBuffs and Party.SpellBuffs[i] end)
    if not ok then break end
    last = i; i = i + 1
    if i > 256 then break end
  end
  return (last >= 0) and last or 0
end

local function detect_playerbuff_high_fallback()
  local pl = Party and Party[0]
  if pl and pl.SpellBuffs and type(pl.SpellBuffs.High)=="number" then
    return pl.SpellBuffs.High
  end
  if const and const.PlayerBuff and type(const.PlayerBuff.High)=="number" then
    return const.PlayerBuff.High
  end
  local i, last = 0, -1
  while true do
    local ok = pcall(function() local _ = pl and pl.SpellBuffs and pl.SpellBuffs[i] end)
    if not ok then break end
    last = i; i = i + 1
    if i > 256 then break end
  end
  return (last >= 0) and last or 0
end

-- Compat maps: mawmapvarsend shim
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
          X = x, Y = y, Z = z, sender = __senderId(), epoch = vars._maw_epoch or 1 },
        "MAWMapvarArrived"
      )
    end
  end
end

------------------------------------------------------------
-- SAFETY SHIMS
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

-- OFF local actif ?
local function local_off_active(id)
  local until_ = vars._maw_local_off and vars._maw_local_off[id]
  return until_ and (NOW() < until_)
end

-- Reprise propriété locale d’un buff
local function __take_local_ownership(id)
  ensure_state()
  if vars.maw_remote_owners and vars.maw_remote_owners[id] then vars.maw_remote_owners[id] = nil end
  if vars.maw_remote_values and vars.maw_remote_values[id] then vars.maw_remote_values[id] = nil end
  if vars.mawbuff_remote and vars.mawbuff_remote[id] then vars.mawbuff_remote[id] = nil end
end

-- Strip moteur des buffs purement distants (anti “fantômes”)
local function __strip_engine_remote()
  ensure_state()
  local removed = false
  local function nuke_partybuff(id)
    if Party and Party.SpellBuffs then
      local ok,b = pcall(function() return Party.SpellBuffs[id] end)
      if ok and b then
        b.ExpireTime = 0
        if b.Power  ~= nil then b.Power  = 0 end
        if b.Skill  ~= nil then b.Skill  = 0 end
        if b.Caster ~= nil then b.Caster = 0 end
        if b.Bits   ~= nil then b.Bits   = 0 end
      end
    end
  end
  local function nuke_playerbuff_allplayers(id)
    if Party and type(Party.High)=="number" then
      for i=0,Party.High do
        local pl = Party[i]
        if pl and pl.SpellBuffs then
          local ok,b = pcall(function() return pl.SpellBuffs[id] end)
          if ok and b then
            b.ExpireTime = 0
            if b.Power  ~= nil then b.Power  = 0 end
            if b.Skill  ~= nil then b.Skill  = 0 end
            if b.Caster ~= nil then b.Caster = 0 end
            if b.Bits   ~= nil then b.Bits   = 0 end
          end
        end
      end
    end
  end

  if vars.maw_remote_owners then
    for id, owners in pairs(vars.maw_remote_owners) do
      local localFlag = vars.mawbuff and (vars.mawbuff[id] ~= nil and (type(vars.mawbuff[id])=="number" or vars.mawbuff[id]==true or type(vars.mawbuff[id])=="table"))
      if not localFlag then
        if type(mawRemoveBuff)=="function" then pcall(mawRemoveBuff, id) end
        nuke_partybuff(id); nuke_playerbuff_allplayers(id)
        removed = true
      end
    end
  end
  if removed and type(mawBuffApply)=="function" then pcall(mawBuffApply) end
end

------------------------------------------------------------
-- CONDITIONS (indices Weak/Poison/Disease/Curse)
------------------------------------------------------------
local __MAW_IDX = { Weak=nil, Poison=nil, Disease=nil, Curse=nil }
local function __find_cond_idx(patterns)
  if not (Game and Game.ConditionTxt) then return nil end
  local hi = Game.ConditionTxt.High or 32
  for i=0,hi do
    local t = Game.ConditionTxt[i]
    if t and type(t.Name)=="string" then
      local name = t.Name:lower()
      for _,p in ipairs(patterns) do if name:find(p) then return i end end
    end
  end
  return nil
end
local function __refresh_condition_indices()
  if __MAW_IDX.Weak == nil then
    if const and const.Condition and type(const.Condition.Weak)=="number" then
      __MAW_IDX.Weak = const.Condition.Weak
    else
      __MAW_IDX.Weak = __find_cond_idx({"weak","faib","schwach","débil","debil"})
    end
  end
  if __MAW_IDX.Poison == nil then __MAW_IDX.Poison = __find_cond_idx({"poison","empoison"}) end
  if __MAW_IDX.Disease == nil then __MAW_IDX.Disease = __find_cond_idx({"disea","malad"}) end
  if __MAW_IDX.Curse == nil then __MAW_IDX.Curse = __find_cond_idx({"curse","maudit"}) end
end
local function __idx(name) __refresh_condition_indices(); return __MAW_IDX[name] end

------------------------------------------------------------
-- WEAK FIX
------------------------------------------------------------
local function MAW_ClearWeakAll()
  __refresh_condition_indices()
  if not Party or type(Party.High) ~= "number" then return end
  local iWeak = __idx("Weak")
  for i = 0, Party.High do
    local p = Party[i]
    if p then
      if p.Weak then p.Weak = 0 end
      if iWeak and p.Conditions then p.Conditions[iWeak] = 0 end
    end
  end
end

function MAW_StartWeakProtect(secs)
  ensure_state()
  local dur = math.max(tonumber(secs) or 18, 0)
  vars._maw_weak_protect_until = NOW() + dur
end

------------------------------------------------------------
-- HP FLOOR GUARD (respawn/resync) + anti “pas dormi”
------------------------------------------------------------
local function __begin_hp_guard(seconds)
  ensure_state()
  local dur = math.max(tonumber(seconds) or 8, 0)
  local until_ = NOW() + dur
  vars._maw_hostup_guard_until = until_
  vars._maw_sync_guard_until   = math.max(vars._maw_sync_guard_until or 0, until_)
  vars._maw_hp_floor_abs   = {}
  vars._maw_hp_floor_ratio = {}
  vars._maw_hp_last        = {}
  if Party and type(Party.High)=="number" then
    for i=0,Party.High do
      local p = Party[i]
      if p then
        vars._maw_hp_floor_abs[i]   = math.max(0, p.HP or 0)
        local r = 0
        if (p.HPMax or 0) > 0 then r = (p.HP or 0) / (p.HPMax or 1) end
        if r ~= r then r = 0 end
        vars._maw_hp_floor_ratio[i] = math.max(0, math.min(1, r))
        vars._maw_hp_last[i]        = math.max(0, p.HP or 0)
      end
    end
  end
  if Party and Party.Food ~= nil and Party.Food < 3 then Party.Food = 3 end
end

local function __guard_active()
  local now = NOW()
  return now < (vars._maw_hostup_guard_until or 0) or now < (vars._maw_sync_guard_until or 0) or now < (vars._maw_weak_protect_until or 0)
end

local function __purge_bad_conditions_during_guard()
  if not __guard_active() then return end
  __refresh_condition_indices()
  if not Party or type(Party.High)~="number" then return end
  local iW,iP,iD,iC = __idx("Weak"), __idx("Poison"), __idx("Disease"), __idx("Curse")
  for i=0,Party.High do
    local p = Party[i]
    if p and p.Conditions then
      if iW then p.Conditions[iW] = 0 end
      if iP then p.Conditions[iP] = 0 end
      if iD then p.Conditions[iD] = 0 end
      if iC then p.Conditions[iC] = 0 end
      if p.Weak then p.Weak = 0 end
    end
  end
  if Party and Party.Food ~= nil and Party.Food < 3 then Party.Food = 3 end
end

------------------------------------------------------------
-- DÉGÂTS : clamp + filet de sécu
------------------------------------------------------------
function events.CalcDamageToPlayer(t)
  if not t or not t.Player then return end
  local now = NOW()

  if vars and vars._maw_weak_protect_until and now < vars._maw_weak_protect_until then
    if t.Player.Weak and t.Player.Weak ~= 0 then t.Player.Weak = 0 end
    local iw = __idx("Weak")
    if iw and t.Player.Conditions then t.Player.Conditions[iw] = 0 end
  end

  if not __guard_active() then return end
  __purge_bad_conditions_during_guard()

  local p = t.Player
  local hpmax = p.HPMax or 0
  local idx = p.Index
  if idx == nil and Party and type(Party.High)=="number" then
    for k=0,Party.High do if Party[k]==p then idx=k; break end end
  end
  local last  = (idx~=nil and vars._maw_hp_last[idx]) or (p.HP or 0)
  local floorAbs   = (idx~=nil and vars._maw_hp_floor_abs[idx])   or (p.HP or 0)
  local ratio      = (idx~=nil and vars._maw_hp_floor_ratio[idx]) or 0
  local floorRatio = (hpmax>0) and math.floor(hpmax*ratio + 0.5) or 0
  local minHP      = math.max(floorAbs, floorRatio, last or 0)

  local dmg = (t.Damage ~= nil and t.Damage) or (t.Result ~= nil and t.Result) or 0
  if dmg and dmg>0 then
    local allowed = math.max(0, (p.HP or 0) - minHP)
    if t.Damage ~= nil then t.Damage = math.min(t.Damage, allowed) end
    if t.Result ~= nil then t.Result = math.min(t.Result, allowed) end
  end

  local predicted = (p.HP or 0) - (t.Damage or t.Result or 0)
  if predicted < minHP then p.HP = minHP end
  if idx~=nil then vars._maw_hp_last[idx] = p.HP end
end

------------------------------------------------------------
-- SOLO: purge remote-only
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
-- RÉCEPTION BUFFS (ON/OFF + HELLO + EPOCH)
------------------------------------------------------------
function events.MAWMapvarArrived(t)
  if not t or type(t) ~= "table" then return end

  -- Handshake: un joueur vient de (re)joindre → renvoyer nos buffs tout de suite
  if t.DataType == "mawHello" then
    ensure_state()
    vars._maw_resend_boost_until = NOW() + 6*SEC
    vars._maw_last_sent = {}
    pcall(sendBuffs)
    return
  end

  if t.DataType == "mapvar" then
    mapvars = mapvars or {}
    mapvars[t[1]] = t[2]
    return
  end

  if (t.DataType ~= "mawBuffs") and (t.DataType ~= "mawBuffsOff") then return end
  if not isReworkOn() then return end
  ensure_state()

  -- Anti-paquets obsolètes (epoch)
  local sender = tostring(t.sender or "?")
  local tepoch = tonumber(t.epoch or 0) or 0
  local lastEpoch = vars._maw_sender_epoch[sender] or 0
  if tepoch < lastEpoch then
    return
  elseif tepoch > lastEpoch then
    vars._maw_sender_epoch[sender] = tepoch
    for id, owners in pairs(vars.maw_remote_owners or {}) do
      if owners and owners[sender] then owners[sender] = nil end
    end
    if vars.maw_remote_values then
      for id, perSender in pairs(vars.maw_remote_values) do
        if perSender then perSender[sender] = nil end
      end
    end
  end

  if not (t.X and t.Y and t.Z) then return end
  local dx,dy,dz = (Party.X or 0)-t.X, (Party.Y or 0)-t.Y, (Party.Z or 0)-t.Z
  local dist = (dx*dx + dy*dy + dz*dz)^0.5
  if dist > (vars.MAWSETTINGS.buffRadius or BASE_RADIUS) then return end

  local BLOCK  = vars.MAWSETTINGS.blockSpells or {}
  local dtype  = t.DataType
  local changed=false

  if dtype == "mawBuffs" then
    for id, payload in pairs(t) do
      if type(id)=="number" and type(payload)=="table" and not BLOCK[id] then
        if local_off_active(id) then
          local owners = vars.maw_remote_owners[id] or {}
          owners[sender] = true
          vars.maw_remote_owners[id] = owners
          local perSender = vars.maw_remote_values[id] or {}
          perSender[sender] = { tonumber(payload[1]) or 0, tonumber(payload[2]) or 0, tonumber(payload[3]) or 0 }
          vars.maw_remote_values[id] = perSender
          vars.mawbuff_remote[id] = true
        else
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
    end
  else
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
-- ENVOI (ON/OFF) — cadence Tick
------------------------------------------------------------
local function sendBuffs()
  if not inMulti() or not isReworkOn() then return end
  ensure_state()
  if not Party then return end

  local payload_on  = { DataType="mawBuffs",    X=Party.X, Y=Party.Y, Z=Party.Z, sender=senderId(), epoch=vars._maw_epoch or 1 }
  local payload_off = { DataType="mawBuffsOff", X=Party.X, Y=Party.Y, Z=Party.Z, sender=senderId(), epoch=vars._maw_epoch or 1 }

  local BLOCK = vars.MAWSETTINGS.blockSpells or {}
  local current = {}
  local hasOn, hasOff = false, false
  local iAmHost = isHost()

  -- Phase 1 : depuis vars.mawbuff (prioritaire)
  for id, v in pairs(vars.mawbuff) do
    if type(id)=="number" and not BLOCK[id] then
      if local_off_active(id) then
        -- OFF local => pas de ON
      else
        if (type(v)=="string") and (not iAmHost) then
          -- skip spéciaux côté client
        else
          local owners = vars.maw_remote_owners[id]
          local isRemote = owners and next(owners)~=nil
          local s,m,l = 0,0,0
          local localActive=false

          if (type(v)=="number" and v~=0) or v==true then
            localActive = true
            s,m,l = safe_getBuffSkill(id)
          elseif type(v)=="table" and not isRemote then
            localActive = true
            s = tonumber(v[1]) or 0; m = tonumber(v[2]) or 0; l = tonumber(v[3]) or 0
            if (s+m+l)==0 then s,m,l = safe_getBuffSkill(id) end
          elseif type(v)=="string" and iAmHost then
            s,m,l = safe_getBuffSkill(id)
            if sum3(s,m,l) > 0 then localActive = true end
          end

          if localActive and sum3(s,m,l)>0 then
            __take_local_ownership(id)
            payload_on[id] = { s,m,l }
            current[id] = true
            hasOn = true
          end
        end
      end
    end
  end

  -- Phase 2 : scan moteur (complément)
  if type(getBuffSkill)=="function" then
    local maxId = maxSpellId()
    for id=1,maxId do
      if not BLOCK[id] and not current[id] then
        if local_off_active(id) then
          -- OFF local => ne rien envoyer
        elseif (vars.mawbuff and type(vars.mawbuff[id])=="string" and not iAmHost) then
          -- skip spéciaux côté client
        else
          local s,m,l = safe_getBuffSkill(id)
          local gs = { tonumber(s) or 0, tonumber(m) or 0, tonumber(l) or 0 }
          if sum3(gs[1],gs[2],gs[3]) > 0 then
            local owners = vars.maw_remote_owners[id]
            local eff = remote_effective(id)
            if (not owners or next(owners)==nil) or lex_gt(gs, eff) then
              payload_on[id] = { gs[1], gs[2], gs[3] }
              __take_local_ownership(id)
              current[id] = true
              hasOn = true
              if vars.mawbuff[id] == nil then vars.mawbuff[id] = 1 end
            end
          end
        end
      end
    end
  end

  -- OFF pour tout ce qu’on n’a plus (ou OFF local)
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
-- BLOCS AUX
------------------------------------------------------------
local function block_forbidden_spells_in_multi()
  if not inMulti() or not isReworkOn() then return end
  local BLOCK = vars.MAWSETTINGS.blockSpells or {}
  if type(getBuffSkill)~="function" then return end
  for id,blocked in pairs(BLOCK) do
    if blocked then
      local s,m,l = safe_getBuffSkill(id)
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
-- TICK + RESYNC DETECTION + HP FLOOR ENFORCER
------------------------------------------------------------
local function __broadcast_timesync_guard(sec)
  if Multiplayer and Multiplayer.in_game and Multiplayer.allow_remote_event then
    Multiplayer.allow_remote_event("mawTimeSync")
    Multiplayer.broadcast_mapdata({ DataType="mawTimeSync", guard=sec or 8, sender=senderId(), epoch=vars._maw_epoch or 1 }, "mawTimeSync")
  end
end

local function __bump_epoch(reason)
  ensure_state()
  vars._maw_epoch = (vars._maw_epoch or 1) + 1
  vars._maw_last_sent = {}
  vars._maw_resend_boost_until = NOW() + 6*SEC
  __strip_engine_remote()
  __broadcast_timesync_guard(8)
end

function events.Tick()
  ensure_state()
  local now = NOW()

  -- Détection resync/rewind/bond
  local lastClock = vars._maw_clock_last or now
  local delta = now - lastClock
  if delta < -0.5*SEC or delta > (12*3600) then
    __bump_epoch("rewind")
    vars._maw_next_send_time = now + SEC
    vars._maw_sync_guard_until = now + 10
    __begin_hp_guard(10)
  end
  vars._maw_clock_last = now

  -- Protect WEAK (burst)
  if vars._maw_weak_protect_until > 0 and now < vars._maw_weak_protect_until then
    MAW_ClearWeakAll()
  end

  -- Grand skip (jours) → hard refresh
  vars._maw_last_time = vars._maw_last_time or now
  if (now - vars._maw_last_time) > (DAY*6) then
    __bump_epoch("dayskip")
    vars._maw_sync_guard_until = now + 10
    vars._maw_clear_weak_ticks = math.max(vars._maw_clear_weak_ticks or 0, 14)
    __begin_hp_guard(10)
  end
  vars._maw_last_time = now

  -- Rafales clear WEAK + purge DoT + anti “no-sleep”
  if vars._maw_clear_weak_ticks and vars._maw_clear_weak_ticks > 0 then
    MAW_ClearWeakAll()
    vars._maw_clear_weak_ticks = vars._maw_clear_weak_ticks - 1
  end
  __purge_bad_conditions_during_guard()

  -- HP FLOOR ENFORCER
  if __guard_active() and Party and type(Party.High)=="number" then
    for i=0,Party.High do
      local p = Party[i]
      if p then
        local floorAbs   = vars._maw_hp_floor_abs[i] or p.HP
        local ratio      = vars._maw_hp_floor_ratio[i] or 0
        local floorRatio = (p.HPMax and p.HPMax>0) and math.floor(p.HPMax*ratio + 0.5) or 0
        local last       = vars._maw_hp_last[i] or p.HP
        local minHP      = math.max(floorAbs, floorRatio, last or 0)
        if p.HP < minHP then p.HP = minHP end
        vars._maw_hp_last[i] = p.HP
      end
    end
  end

  -- Blocage sorts interdits
  block_forbidden_spells_in_multi()

  -- Strip moteur des buffs purement distants (entretien anti-fantômes)
  __strip_engine_remote()

  -- Cadence d’envoi sans Timer
  if not inMulti() or not isReworkOn() then return end
  if now < (START_DELAY or 0) then return end
  if (vars._maw_next_send_time or 0) <= now or now < (vars._maw_resend_boost_until or 0) then
    pcall(sendBuffs)
    vars._maw_next_send_time = now + SEND_PERIOD
  end
end

------------------------------------------------------------
-- LOAD / GAMELOADED / INIT / JOIN
------------------------------------------------------------
local function __force_reshare_buffs(pulse_sec, instant)
  ensure_state()
  vars._maw_last_sent = {}
  vars._maw_next_send_time = 0
  vars._maw_resend_boost_until = NOW() + (pulse_sec or 6)*SEC
  if instant then pcall(sendBuffs) end
end

local function __send_hello()
  if Multiplayer and Multiplayer.in_game and Multiplayer.allow_remote_event then
    Multiplayer.allow_remote_event("MAWMapvarArrived")
    Multiplayer.allow_remote_event("mawHello")
    Multiplayer.broadcast_mapdata({
      DataType="mawHello",
      sender=senderId(),
      epoch=vars._maw_epoch or 1,
      X=(Party and Party.X) or 0, Y=(Party and Party.Y) or 0, Z=(Party and Party.Z) or 0
    }, "MAWMapvarArrived")
  end
end

function events.LoadMap()
  ensure_state()
  __bump_epoch("loadmap")
  if not inMulti() then purge_remote_buffs_keep_local() end
  vars._maw_clear_weak_ticks = math.max(vars._maw_clear_weak_ticks or 0, 12)
  __refresh_condition_indices()
  __begin_hp_guard(8)
  __strip_engine_remote()

  if inMulti() and isReworkOn() then
    __force_reshare_buffs(6, true)
    __send_hello()
  end
end

function events.GameLoaded()
  ensure_state()
  __bump_epoch("gameloaded")
  if not inMulti() then purge_remote_buffs_keep_local() end
  vars._maw_clear_weak_ticks = math.max(vars._maw_clear_weak_ticks or 0, 12)
  __refresh_condition_indices()
  __begin_hp_guard(8)
  __strip_engine_remote()

  if inMulti() and isReworkOn() then
    __force_reshare_buffs(6, true)
    __send_hello()
  end
end

function events.MultiplayerInitialized()
  ensure_state()
  if Multiplayer and Multiplayer.VERSION then Multiplayer.VERSION = "MAW " .. Multiplayer.VERSION end
  if Multiplayer and Multiplayer.allow_remote_event then
    Multiplayer.allow_remote_event("mawBuffs")
    Multiplayer.allow_remote_event("MAWMapvarArrived")
    Multiplayer.allow_remote_event("mawMultiPlayerData")
    Multiplayer.allow_remote_event("mawWeakEvt")
    Multiplayer.allow_remote_event("mawTimeSync")
    Multiplayer.allow_remote_event("mawHostDown")
    Multiplayer.allow_remote_event("mawClientDown")
    Multiplayer.allow_remote_event("mawHello")
  end
  __bump_epoch("mpinit")
  __strip_engine_remote()
  if inMulti() and isReworkOn() then
    __force_reshare_buffs(8, true)
    __send_hello()
  end
end

if rawget(events, "MultiplayerPlayerJoined") then
  function events.MultiplayerPlayerJoined(t)
    ensure_state()
    if inMulti() and isReworkOn() then
      __force_reshare_buffs(8, true)
      __send_hello()
      __broadcast_timesync_guard(8)
    end
  end
end

------------------------------------------------------------
-- SÉQUENCES DE MORT → guards + pulses + anti-fantômes
------------------------------------------------------------
local function __notify(which)
  if Multiplayer and Multiplayer.in_game and Multiplayer.allow_remote_event then
    Multiplayer.allow_remote_event(which)
    Multiplayer.broadcast_mapdata({ DataType=which, sender=senderId(), epoch=vars._maw_epoch or 1 }, which)
  end
end

local function __after_death_resend_pulse()
  ensure_state()
  __bump_epoch("death")
  __force_reshare_buffs(6, true)
  __begin_hp_guard(12)
  __strip_engine_remote()
end

function events.GameOver()
  ensure_state()
  if isHost() then
    vars._maw_host_death_count = (vars._maw_host_death_count or 0) + 1
    __notify("mawHostDown")
  else
    __notify("mawClientDown")
  end
  vars._maw_clear_weak_ticks = math.max(vars._maw_clear_weak_ticks or 0, 20)
  MAW_StartWeakProtect(30)
  __after_death_resend_pulse()
end

function events.DeathMenu()
  ensure_state()
  if isHost() then
    vars._maw_host_death_count = (vars._maw_host_death_count or 0) + 1
    __notify("mawHostDown")
  else
    __notify("mawClientDown")
  end
  vars._maw_clear_weak_ticks = math.max(vars._maw_clear_weak_ticks or 0, 20)
  MAW_StartWeakProtect(30)
  __after_death_resend_pulse()
end

------------------------------------------------------------
-- WEAK — canal dédié + TimeSync
------------------------------------------------------------
function events.mawWeakEvt(t)
  if not t then return end
  if t.DataType ~= "mawWeak" then return end
  local tepoch = tonumber(t.epoch or 0) or 0
  if tepoch > 0 and tepoch < (vars._maw_sender_epoch[tostring(t.sender or "?")] or 0) then return end

  if t.action == "clear" then
    MAW_ClearWeakAll()
  elseif t.action == "prime" then
    vars._maw_clear_weak_ticks = math.max(vars._maw_clear_weak_ticks or 0, tonumber(t.ticks) or 15)
    MAW_ClearWeakAll()
  elseif t.action == "protect" then
    MAW_StartWeakProtect(tonumber(t.seconds) or 30)
  end
end

function events.mawTimeSync(t)
  ensure_state()
  local tepoch = tonumber(t.epoch or 0) or 0
  local snd = tostring(t.sender or "?")
  if tepoch > 0 and tepoch < (vars._maw_sender_epoch[snd] or 0) then return end

  vars._maw_sync_guard_until = math.max(vars._maw_sync_guard_until or 0, NOW() + (tonumber(t.guard) or 8))
  vars._maw_resend_boost_until = NOW() + 6*SEC
  if Party and Party.Food ~= nil and Party.Food < 3 then Party.Food = 3 end
end

function events.mawHostDown(t) ensure_state(); vars._maw_resend_boost_until = NOW() + 6*SEC end
function events.mawClientDown(t) ensure_state(); vars._maw_resend_boost_until = NOW() + 6*SEC end

------------------------------------------------------------
-- MEGA NUKE + EPOCH (SAFE)
------------------------------------------------------------
function MAW_NUKE_ALL_BUFFS(broadcast)
  broadcast = (broadcast ~= false)

  vars = vars or {}
  ensure_state()

  __bump_epoch("nuke")

  vars.mawbuff             = vars.mawbuff or {}
  for k in pairs(vars.mawbuff) do vars.mawbuff[k] = false end
  vars.maw_special_expire  = {}
  vars._maw_local_off      = {}
  vars.mawbuff_remote      = {}
  vars.maw_remote_values   = {}
  vars.maw_remote_owners   = {}
  vars._maw_last_sent      = {}

  local function get_high_safe(arr, fallback)
    if arr and type(arr.High) == "number" then return arr.High end
    return fallback or 0
  end

  -- 2) Couper tous les PartyBuffs (bornes autodétectées)
  if Party and Party.SpellBuffs then
    local hiPB = detect_partybuff_high_fallback()
    for id = 0, hiPB do
      local ok, b = pcall(function() return Party.SpellBuffs[id] end)
      if ok and b then
        b.ExpireTime = 0
        if b.Power  ~= nil then b.Power  = 0 end
        if b.Skill  ~= nil then b.Skill  = 0 end
        if b.Caster ~= nil then b.Caster = 0 end
        if b.Bits   ~= nil then b.Bits   = 0 end
      end
    end
  end

  -- 3) Couper tous les PlayerBuffs (bornes autodétectées)
  if Party and type(Party.High) == "number" then
    for i = 0, Party.High do
      local pl = Party[i]
      if pl and pl.SpellBuffs then
        local hiSB = detect_playerbuff_high_fallback()
        for id = 0, hiSB do
          local ok, b = pcall(function() return pl.SpellBuffs[id] end)
          if ok and b then
            b.ExpireTime = 0
            if b.Power  ~= nil then b.Power  = 0 end
            if b.Skill  ~= nil then b.Skill  = 0 end
            if b.Caster ~= nil then b.Caster = 0 end
            if b.Bits   ~= nil then b.Bits   = 0 end
          end
        end
      end
    end
  end

  -- 4) Remove dédié si dispo
  if type(buffSpellList) == "table" and type(mawRemoveBuff) == "function" then
    for _, id in ipairs(buffSpellList) do pcall(mawRemoveBuff, id) end
  end

  -- 5) Ré-application propre
  if type(mawBuffApply) == "function" then pcall(mawBuffApply) end

  -- 6) Sync OFF réseau
  if broadcast and Multiplayer and Multiplayer.in_game and Multiplayer.allow_remote_event then
    local payload_off = {
      DataType = "mawBuffsOff",
      X = (Party and Party.X) or 0,
      Y = (Party and Party.Y) or 0,
      Z = (Party and Party.Z) or 0,
      sender = (Multiplayer.player_id or "host"),
      epoch = vars._maw_epoch or 1
    }
    if vars._maw_last_sent then
      for id,_ in pairs(vars._maw_last_sent) do payload_off[id] = 1 end
    end
    if type(buffSpellList)=="table" then
      for _,id in ipairs(buffSpellList) do payload_off[id] = 1 end
    end
    Multiplayer.allow_remote_event("MAWMapvarArrived")
    Multiplayer.broadcast_mapdata(payload_off, "MAWMapvarArrived")
  end

  if Game and Game.ShowStatusText then Game.ShowStatusText("MAW: ALL BUFFS NUKED (SAFE EPOCH)") end
end

-- Raccourci pratique
function NUKE() MAW_NUKE_ALL_BUFFS(true) end
