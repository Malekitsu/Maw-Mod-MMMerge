-- zzBossSync.lua — synchro “boss” via mapvars (host -> clients)
-- Safe solo. Empêche la génération client. Gère l’ordre bossNames/bossSet,
-- purges côté client avant application (plus d’anciens boss résiduels),
-- et le HOST pousse le snapshot en rafales quelques secondes (anti race).

------------------------------------------------------------
-- SHIMS & HELPERS
------------------------------------------------------------
-- mawmapvarsend: envoie une clé/valeur mapvars à tous les clients autour (via MAWMapvarArrived)
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
        { DataType = "mapvar", [1] = key, [2] = val, X = x, Y = y, Z = z, sender = __senderId() },
        "MAWMapvarArrived"
      )
    end
  end
end

local function inMulti() return Multiplayer and Multiplayer.in_game end

local function isHost()
  if not Multiplayer then return true end
  if type(Multiplayer.im_host) == "function" then
    local ok,res = pcall(Multiplayer.im_host, Multiplayer)
    if ok and res ~= nil then return not not res end
  end
  if Multiplayer.is_host ~= nil then return not not Multiplayer.is_host end
  if Multiplayer.IsHost  ~= nil then return not not Multiplayer.IsHost  end
  if Multiplayer.host_id and Multiplayer.player_id then return Multiplayer.player_id == Multiplayer.host_id end
  if type(Multiplayer.player_id)=="number" then return Multiplayer.player_id == 0 end
  if type(Multiplayer.player_id)=="string" then return Multiplayer.player_id == "host" end
  return false
end

local SEC = (const and const.Second) or 1
local function NOW() return (Game and Game.Time) or 0 end

-- Fenêtre de “rattrapage” UI côté client (force relecture des labels)
local _boss_refresh_until = 0
local function schedule_refresh(secs)
  _boss_refresh_until = math.max(_boss_refresh_until or 0, NOW() + (secs or 2)*SEC)
end

-- Rafales de snapshot côté HOST (re-broadcast périodique pendant quelques secondes)
local _burst_until, _burst_next = 0, 0
local function HostBurst_Start(secs, period)
  _burst_until = NOW() + (secs or 4)*SEC
  _burst_next  = 0
  _burst_period = math.max((period or 0.6)*SEC, 0.2*SEC)
end

------------------------------------------------------------
-- APPLY HELPERS (client)
------------------------------------------------------------
local function client_purge_all_boss_marks()
  if not (Map and Map.Monsters) then return end
  for i = 0, Map.Monsters.High do
    local mon = Map.Monsters[i]
    if mon and (mon.NameId or 0) >= 221 and mon.NameId<=300 then
      mon.NameId = 0
    end
  end
end

local function client_purge_except_set(list)
  if not (Map and Map.Monsters) then return end
  local keep = {}
  for _, pair in ipairs(list) do
    local idx = pair[1]
    if type(idx)=="number" then keep[idx] = true end
  end
  for i = 0, Map.Monsters.High do
    local mon = Map.Monsters[i]
    if mon and (mon.NameId or 0) >= 221 and mon.NameId<=300 and not keep[i] then
      mon.NameId = 0
    end
  end
end

local function apply_boss_names(tbl)
  if not tbl or type(tbl) ~= "table" then return end
  mapvars = mapvars or {}
  mapvars.bossNames = tbl
  if Game and Game.PlaceMonTxt then
    -- réinitialise 221..299
    for i = 1, 79 do Game.PlaceMonTxt[i + 220] = i + 220 end
    -- applique les libellés
    for k, v in pairs(tbl) do
      if type(k) == "number" and type(v) == "string" then
        Game.PlaceMonTxt[k] = v
      end
    end
  end
end

local function apply_boss_set(list, do_refresh_after)
  if not list or type(list) ~= "table" then return end
  mapvars = mapvars or {}
  -- purge ciblée (on garde uniquement les indices présents dans la nouvelle liste)
  client_purge_except_set(list)

  mapvars.bossSet = list
  if Map and Map.Monsters then
    for _, pair in ipairs(list) do
      local idx, nid, mid = pair[1], pair[2], pair[3]   -- mid = monster.Id (tier)
      local mon = Map.Monsters[idx]
      if mon then
        if type(mid) == "number" then mon.Id = mid end   -- aligne le tier côté clients
        if type(nid) == "number" then mon.NameId = nid end
      end
    end
  end
  -- Empêche toute génération client
  mapvars.bossGenerated = true

  -- Toggle optionnel pour forcer l’UI à relire PlaceMonTxt
  if do_refresh_after and Map and Map.Monsters then
    for _, pair in ipairs(list) do
      local idx, nid = pair[1], pair[2]
      local mon = Map.Monsters[idx]
      if mon and type(nid) == "number" then
        mon.NameId = 0
        mon.NameId = nid
      end
    end
  end
end

local function refresh_all_boss_labels()
  if not (mapvars and mapvars.bossSet) then return end
  if not (Map and Map.Monsters) then return end
  local have_names = mapvars.bossNames and next(mapvars.bossNames) ~= nil
  if not have_names then return end
  for _, pair in ipairs(mapvars.bossSet) do
    local idx, nid = pair[1], pair[2]
    local mon = Map.Monsters[idx]
    if mon and type(nid) == "number" then
      mon.NameId = 0
      mon.NameId = nid
    end
  end
end

------------------------------------------------------------
-- NETWORK SNAPSHOT HANDLING
------------------------------------------------------------
-- Réception (transite via MAWMapvarArrived / DataType "mapvar")
function events.MAWMapvarArrived(t)
  if not t or t.DataType ~= "mapvar" then return end
  local key, val = t[1], t[2]

  if key == "bossNames" then
    -- On écrase toujours localement avec le HOST
    apply_boss_names(val)
    -- si on a déjà un set, on force la relecture des labels
    refresh_all_boss_labels()
    if not isHost() then schedule_refresh(2.0) end
    return

  elseif key == "bossSet" then
    -- On ÉCRASE & on purge tout ce qui n'est pas dans la nouvelle liste
    local have_names = mapvars and mapvars.bossNames and next(mapvars.bossNames) ~= nil
    apply_boss_set(val, have_names)
    if not have_names then
      -- noms pas encore reçus : fenêtre de rattrapage
      if not isHost() then schedule_refresh(2.0) end
    end
    return
  end
end

-- Client -> Host : demande le snapshot (bossNames puis bossSet)
local function request_boss_snapshot()
  if not inMulti() or isHost() then return end
  if Multiplayer and Multiplayer.allow_remote_event then
    Multiplayer.allow_remote_event("mawBossNamesReq")
    Multiplayer.broadcast_mapdata(
      { DataType = "mawBossNamesReq", map = (Map and Map.Name) or "", sender = (Multiplayer.player_id or "client") },
      "mawBossNamesReq"
    )
  end
end

-- Host -> répond à la requête (envoie bossNames puis bossSet)
function events.mawBossNamesReq(t)
  if not inMulti() or not isHost() then return end
  if mawmapvarsend and mapvars and (mapvars.bossNames or mapvars.bossSet) then
    if mapvars.bossNames then mawmapvarsend("bossNames", mapvars.bossNames) end
    if mapvars.bossSet   then mawmapvarsend("bossSet",   mapvars.bossSet)   end
  end
  -- lance une courte rafale pour fiabiliser
  HostBurst_Start(4, 0.6)
end

-- Autorisations réseau
function events.MultiplayerInitialized()
  if Multiplayer and Multiplayer.allow_remote_event then
    Multiplayer.allow_remote_event("mawBossNamesReq")
    Multiplayer.allow_remote_event("MAWMapvarArrived")
  end
end

------------------------------------------------------------
-- API côté host : broadcast immédiat du snapshot
------------------------------------------------------------
function BossSync_BroadcastSnapshot()
  if not inMulti() or not isHost() then return end
  if mawmapvarsend and mapvars then
    if mapvars.bossNames then mawmapvarsend("bossNames", mapvars.bossNames) end
    if mapvars.bossSet   then mawmapvarsend("bossSet",   mapvars.bossSet)   end
  end
end

-- Quand un client rejoint la partie alors que le host est déjà sur la map
function events.ClientJoined(client)
  if not isHost() then return end
  if mapvars and (mapvars.bossNames or mapvars.bossSet) then
    BossSync_BroadcastSnapshot()
    HostBurst_Start(5, 0.6) -- petite rafale à l’arrivée d’un client
  end
end

------------------------------------------------------------
-- MAP LOAD ORDER GUARDS
------------------------------------------------------------
-- Sur CLIENTS: empêcher toute génération locale avant les AfterLoadMap
function events.BeforeLoadMap()
  if inMulti() and not isHost() then
    mapvars = mapvars or {}
    mapvars.bossGenerated = true        -- empêche toute génération locale
    client_purge_all_boss_marks()       -- nettoie les NameId >=221 visibles
    -- NE PAS faire: mapvars.bossNames = {} / mapvars.bossSet = {}
    -- on attend le snapshot du host qui écrasera proprement
  end
end


-- Après chargement : applique ce qu’on a et redemande le snapshot si besoin
function events.AfterLoadMap()
  if mapvars and mapvars.bossNames then apply_boss_names(mapvars.bossNames) end
  if mapvars and mapvars.bossSet   then
    local have_names = mapvars and mapvars.bossNames and next(mapvars.bossNames) ~= nil
    apply_boss_set(mapvars.bossSet, have_names)
  end
  if inMulti() and not isHost() then
    request_boss_snapshot()
    schedule_refresh(2.0)
  else
    -- host : petite rafale au chargement pour stabiliser les clients déjà présents
    if inMulti() and isHost() then
      HostBurst_Start(4, 0.6)
    end
  end
end

-- Tick : 1) fenêtre de “rattrapage” UI côté client  2) rafales host
function events.Tick()
  local now = NOW()

  -- client: forcer la relecture des labels pendant la fenêtre
  if _boss_refresh_until and now < _boss_refresh_until then
    if mapvars and mapvars.bossNames then apply_boss_names(mapvars.bossNames) end
    refresh_all_boss_labels()
  end

  -- host: rafales snapshot
  if inMulti() and isHost() and _burst_until and now < _burst_until then
    if now >= (_burst_next or 0) then
      _burst_next = now + (_burst_period or 0.6*SEC)
      BossSync_BroadcastSnapshot()
    end
  end
end

-- zzBossDebug.lua — Affichage debug des boss présents (HOST/CLIENT/solo)
-- F9: dump écran (tous, lent ~5s/ligne) • Shift+F9: très lent (~12s/ligne)
-- Ctrl+F9: auto-dump on AfterLoadMap (toggle) • Alt+F9: écrit boss_dump.txt
-- Non-invasif : ne modifie ni la génération ni la synchro, lit seulement mapvars/Map.

local SEC = (const and const.Second) or 1
local function NOW() return (Game and Game.Time) or 0 end

-- File-scoped state
local _queue, _q_i, _next_time = nil, 1, 0
local _interval      = 5.0*SEC      -- vitesse par défaut (F9) — AVANT: 1.8s
local _slow_interval = 12.0*SEC     -- vitesse très lente (Shift+F9) — AVANT: 4.5s
local _auto_due = 0
local _last_dump_lines = {}
local _last_dump_hdr = ""

local function whoAmI()
  if Multiplayer and Multiplayer.in_game then
    local isHost = false
    if type(Multiplayer.im_host) == "function" then
      local ok,res = pcall(Multiplayer.im_host, Multiplayer)
      isHost = ok and res and true or false
    elseif Multiplayer.is_host ~= nil then
      isHost = not not Multiplayer.is_host
    end
    return isHost and "HOST" or "CLIENT"
  end
  return "SOLO"
end

local function tierName(mid)
  if type(mid) ~= "number" then return "?" end
  local r = mid % 3
  if r == 0 then return "RED"
  elseif r == 1 then return "GREEN"
  else return "BLUE" end
end

local function buildBossList()
  local lines = {}
  local used = {}

  if mapvars and type(mapvars.bossSet)=="table" and #mapvars.bossSet > 0 then
    for _, p in ipairs(mapvars.bossSet) do
      local idx, nid, mid = p[1], p[2], p[3]
      local name = (Game and Game.PlaceMonTxt and nid and Game.PlaceMonTxt[nid]) or ("#"..tostring(nid))
      table.insert(lines, string.format("[%03d] %s  (nid=%d, id=%d %s)", idx or -1, tostring(name), nid or -1, mid or -1, tierName(mid)))
      used[idx or -1] = true
    end
  end

  -- Fallback / compléments : scan direct si pas de bossSet
  if Map and Map.Monsters and Game and Game.PlaceMonTxt then
    for i=0, Map.Monsters.High do
      if not used[i] then
        local mon = Map.Monsters[i]
        if mon and mon.NameId and mon.NameId >= 221 and mon.NameId < 300 then
          local name = Game.PlaceMonTxt[mon.NameId] or ("#"..tostring(mon.NameId))
          table.insert(lines, string.format("[%03d] %s  (nid=%d, id=%d %s)%s",
            i, tostring(name), mon.NameId, mon.Id or -1, tierName(mon.Id),
            (mapvars and mapvars.bossSet) and "  *local-scan*" or ""))
        end
      end
    end
  end

  table.sort(lines)
  return lines
end

local function checksumBosses()
  local sum = 0
  local function mix(str)
    for i=1,#str do
      sum = (sum*131 + string.byte(str,i)) % 1000000007
    end
  end
  if mapvars and type(mapvars.bossSet)=="table" and Game and Game.PlaceMonTxt then
    for _, p in ipairs(mapvars.bossSet) do
      local idx, nid, mid = p[1], p[2], p[3]
      local name = Game.PlaceMonTxt[nid] or ""
      mix(tostring(idx) .. "|" .. tostring(nid) .. "|" .. name .. "|" .. tostring(mid))
    end
  else
    if Map and Map.Monsters and Game and Game.PlaceMonTxt then
      for i=0, Map.Monsters.High do
        local mon = Map.Monsters[i]
        if mon and mon.NameId and mon.NameId >= 221 and mon.NameId < 300 then
          local name = Game.PlaceMonTxt[mon.NameId] or ""
          mix(tostring(i) .. "|" .. tostring(mon.NameId) .. "|" .. name .. "|" .. tostring(mon.Id))
        end
      end
    end
  end
  return sum
end

local function enqueueAll(lines, header, interval)
  _queue, _q_i, _next_time = {}, 1, 0
  local N = #lines
  if header then table.insert(_queue, header) end
  if N == 0 then
    table.insert(_queue, "Aucun boss détecté.")
  else
    for i, L in ipairs(lines) do
      table.insert(_queue, string.format("BOSS %d/%d — %s", i, N, L))
    end
  end
  _interval = interval or _interval
end

local function writeFileAll(path, text)
  local ok, fh = pcall(io.open, path, "w")
  if ok and fh then
    fh:write(text or "")
    fh:close()
    return true
  end
  return false
end

local function dumpBosses(opts)
  opts = opts or {}
  local slow   = opts.slow and true or false
  local toFile = opts.toFile and true or false

  local who = whoAmI()
  local mapname = (Map and Map.Name) or "?"
  local lines = buildBossList()
  local n = #lines
  local chksum = checksumBosses()

  -- Log console complet
  print(string.format("[BossDebug] %s @ %s — count=%d checksum=%d", who, mapname, n, chksum))
  for _,L in ipairs(lines) do print("[BossDebug] "..L) end

  _last_dump_lines = lines
  _last_dump_hdr = string.format("[%s] %s — %d boss | checksum=%d", who, mapname, n, chksum)

  if toFile then
    local txt = _last_dump_hdr .. "\n" .. table.concat(lines, "\n") .. "\n"
    if writeFileAll("boss_dump.txt", txt) then
      if Game and Game.ShowStatusText then Game.ShowStatusText("BossDebug: écrit dans boss_dump.txt") end
    else
      if Game and Game.ShowStatusText then Game.ShowStatusText("BossDebug: impossible d’écrire boss_dump.txt") end
    end
  end

  -- Écran: TOUTES les lignes, séquencées lentement
  local head = "BOSS DEBUG " .. _last_dump_hdr .. "  (Shift=très lent • Alt=fichier • Ctrl=auto on/off)"
  enqueueAll(lines, head, slow and _slow_interval or _interval)
end

-- === Handlers ================================================================

local function onTick()
  local now = NOW()

  if _auto_due ~= 0 and now >= _auto_due then
    _auto_due = 0
    dumpBosses()
  end

  if not _queue then return end
  if now >= _next_time then
    local L = _queue[_q_i]
    if not L then
      _queue = nil
      return
    end
    if Game and Game.ShowStatusText then Game.ShowStatusText(L) end
    _q_i = _q_i + 1
    _next_time = now + _interval
  end
end

local function onKeyDown(t)
  if t.Key ~= const.Keys.F9 then return end
  t.Key = 0
  if Keys.IsPressed(const.Keys.CTRL) then
    mapvars = mapvars or {}
    mapvars.bossDebugAuto = not mapvars.bossDebugAuto
    if Game and Game.ShowStatusText then
      Game.ShowStatusText(mapvars.bossDebugAuto and "BossDebug AUTO: ON" or "BossDebug AUTO: OFF")
    end
  elseif Keys.IsPressed(const.Keys.ALT) then
    dumpBosses({ toFile = true })
  else
    local slow = Keys.IsPressed(const.Keys.SHIFT)
    dumpBosses({ slow = slow })
  end
end

local function onAfterLoadMap()
  if mapvars and mapvars.bossDebugAuto then
    _auto_due = NOW() + 1.0*SEC
  end
end

events.AddFirst("KeyDown", onKeyDown)
events.Add("Tick", onTick)
events.Add("AfterLoadMap", onAfterLoadMap)
