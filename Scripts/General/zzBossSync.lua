-- zzBossSync.lua — synchro “boss” via mapvars (host -> clients)
-- Safe en solo. Empêche la génération client. Gère l’ordre bossNames/bossSet et force un refresh court après réception.

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
local function isHost()  return Multiplayer and Multiplayer.im_host and Multiplayer.im_host() end
local SEC = (const and const.Second) or 1
local function NOW() return (Game and Game.Time) or 0 end

-- Fenêtre de “rattrapage” côté client pour forcer l’affichage correct
local _boss_refresh_until = 0
local function schedule_refresh(secs)
  _boss_refresh_until = math.max(_boss_refresh_until or 0, NOW() + (secs or 2)*SEC)
end

------------------------------------------------------------
-- APPLY HELPERS
------------------------------------------------------------
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
  mapvars.bossSet = list
  if Map and Map.Monsters then
    for _, pair in ipairs(list) do
      local idx, nid = pair[1], pair[2]
      local mon = Map.Monsters[idx]
      if mon and type(nid) == "number" then
        mon.NameId = nid
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
    apply_boss_names(val)
    refresh_all_boss_labels()
    if not isHost() then schedule_refresh(2.0) end
    return
  elseif key == "bossSet" then
    local have_names = mapvars and mapvars.bossNames and next(mapvars.bossNames) ~= nil
    apply_boss_set(val, have_names)
    if not have_names then
      -- noms pas encore reçus : on se donne une fenêtre pour “rattraper” dès qu’ils arrivent
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

-- Host -> répond à la requête (envoie d’abord les noms, puis les affectations)
function events.mawBossNamesReq(t)
  if not inMulti() or not isHost() then return end
  if mawmapvarsend and mapvars and (mapvars.bossNames or mapvars.bossSet) then
    if mapvars.bossNames then mawmapvarsend("bossNames", mapvars.bossNames) end
    if mapvars.bossSet   then mawmapvarsend("bossSet",   mapvars.bossSet)   end
  end
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
  if Multiplayer and Multiplayer.im_host and Multiplayer.im_host() then
    if mapvars and (mapvars.bossNames or mapvars.bossSet) then
      BossSync_BroadcastSnapshot()
    end
  end
end

------------------------------------------------------------
-- MAP LOAD ORDER GUARDS
------------------------------------------------------------
-- Sur CLIENTS: empêcher toute génération locale avant les AfterLoadMap
function events.BeforeLoadMap()
  if inMulti() and not isHost() then
    mapvars = mapvars or {}
    mapvars.bossGenerated = true
    mapvars.bossNames = mapvars.bossNames or {}
    mapvars.bossSet   = mapvars.bossSet   or {}
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
  end
end

-- Pendant la fenêtre de “rattrapage”, on force la resynch des labels
function events.Tick()
  if _boss_refresh_until and NOW() < _boss_refresh_until then
    if mapvars and mapvars.bossNames then apply_boss_names(mapvars.bossNames) end
    refresh_all_boss_labels()
  end
end
