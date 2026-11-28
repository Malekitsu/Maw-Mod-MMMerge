local ok_json, json = pcall(require, "json")

-- 1. Get the current script's file path
local script_path = debug.getinfo(1, "S").source:sub(2)

-- 2. Extract the script's directory (".../Scripts/General/")
local script_dir = script_path:match("^(.*[/\\])")

-- Automatically register the Pure Lua Overlay module (OFF by default; enable it in MAW SETTINGS or with F12)
if not _G.MAW_LuaOverlay and dofile then
    local lua_loader_path = (AppPath and (AppPath .. "MAW LUA OVERLAY\\MAW_Lua_Overlay_Loader.lua"))
        or (script_dir .. "..\\..\\MAW LUA OVERLAY\\MAW_Lua_Overlay_Loader.lua")
    pcall(dofile, lua_loader_path)
end

-- Fallback to built-in JSON codec inside MAW LUA OVERLAY/win32_gdiplus.lua if Scripts/Modules/json.lua is not present
if (not ok_json or not json) and _G._MAW_WIN32_GDIPLUS_MOD then
    json = {
        decode = _G._MAW_WIN32_GDIPLUS_MOD.json_decode,
        encode = _G._MAW_WIN32_GDIPLUS_MOD.json_encode,
    }
end

-- 3. Build the relative path to visible_monsters.json and overlay_settings.json
local file_path = script_dir .. ".." .. "\\" .. ".." .. "\\" .. "_Python Overlay" .. "\\" .. "visible_monsters.json"
local settings_path = script_dir .. ".." .. "\\" .. ".." .. "\\" .. "_Python Overlay" .. "\\" .. "overlay_settings.json"
local lua_settings_path = script_dir .. ".." .. "\\" .. ".." .. "\\" .. "MAW LUA OVERLAY" .. "\\" .. "overlay_settings.json"

-- 4. Grab screen res and FOV calibration from settings app (reloaded periodically)
local fovIndoorMultiplier = 1.205
local fovOutdoorMultiplier = 1.0

local function loadOverlaySettings(path)
    local file = io.open(lua_settings_path, "r") or io.open(path, "r")
    if not file then
        return 1920.0, 1080.0, 1.205, 1.0, 5.0
    end

    local content = file:read("*a")
    file:close()

    local w, h = 1920.0, 1080.0
    local fovIn, fovOut = 1.205, 1.0
    local hideAfter = 5.0

    local ok, data = pcall(json.decode, content)
    if ok and data then
        if data.screen_resolution then
            local sw, sh = data.screen_resolution:match("(%d+)x(%d+)")
            if sw and sh then
                w, h = tonumber(sw) or 1920.0, tonumber(sh) or 1080.0
            end
        end
        if data.fov_scale_indoor then
            fovIn = tonumber(data.fov_scale_indoor) or 1.205
        end
        if data.fov_scale_outdoor then
            fovOut = tonumber(data.fov_scale_outdoor) or 1.0
        end
        if data.hide_bar_after_seconds then
            hideAfter = tonumber(data.hide_bar_after_seconds) or 5.0
        end
    end

    return w, h, fovIn, fovOut, hideAfter
end

local screenWidth, screenHeight, fovIndoorMultiplier, fovOutdoorMultiplier, hideBarAfter = loadOverlaySettings(settings_path)
local screenCenterX = screenWidth / 2.0
local screenCenterY = screenHeight / 2.0
local lastSettingsCheck = 0
local lastEncodedOutput = ""
local lastWriteTime = 0

local function refreshResolutionIfNeeded(now)
    if now - lastSettingsCheck >= 2.0 then
        lastSettingsCheck = now
        local w, h, fovIn, fovOut, hideAfter = loadOverlaySettings(settings_path)
        if w ~= screenWidth or h ~= screenHeight then
            screenWidth, screenHeight = w, h
            screenCenterX = screenWidth / 2.0
            screenCenterY = screenHeight / 2.0
        end
        fovIndoorMultiplier = fovIn
        fovOutdoorMultiplier = fovOut
        hideBarAfter = hideAfter
    end
end

-- Distance utility
local function getDistance(p, m)
    return math.sqrt((p.X - m.X)^2 + (p.Y - m.Y)^2 + (p.Z - m.Z)^2)
end

-- Real monster HP helper using MawCore.MonsterHP ledger when available
local function getRealHP(mon)
    if MawCore and MawCore.MonsterHP then
        local hp = math.floor(MawCore.MonsterHP.current(mon) + 0.5)
        local fullHP = math.floor(MawCore.MonsterHP.max(mon) + 0.5)
        return math.max(0, hp), math.max(1, fullHP)
    end
    local res0 = mon.Resistances and mon.Resistances[0] or 0
    local exponent = (res0 >= 0 and res0 < 60000) and math.floor(res0 / 1000) or 0
    local mult = 2 ^ exponent
    return math.max(0, mon.HP * mult), math.max(1, mon.FullHP * mult)
end

-- Visual sprite height & radius helper (accounts for monster dimensions, boss scale & Shrinking Ray)
-- Monster visual height master table calibrated relative to Bootleg Bay Cannibals (Height 168)
local MonsterVisualHeights = _G.MonsterVisualHeights
if not MonsterVisualHeights and dofile and AppPath then
    pcall(function()
        MonsterVisualHeights = dofile(AppPath .. "Scripts/General/__monster_visual_heights.lua")
    end)
end

local SPRITE_HEIGHT_FACTOR = 1.05

local function getMonsterVisualDimensions(mon)
    local bin = Game.MonListBin[mon.Id]
    local baseHeight = (MonsterVisualHeights and MonsterVisualHeights[mon.Id]) or (bin and bin.Height) or mon.BodyHeight or 160
    local height = baseHeight * SPRITE_HEIGHT_FACTOR
    local radius = (bin and bin.Radius) or mon.BodyRadius or 40
    local scale = 1.0
    if mon.NameId >= 220 and mon.NameId < 300 then
        scale = (Map.IndoorOrOutdoor == 1) and 1.4 or 2.0
        local nameStr = Game.PlaceMonTxt[mon.NameId] or ""
        local monsterSkill = string.match(nameStr, "([^%s]+)")
        if monsterSkill == "Omnipotent" then
            scale = (scale - 1) * 1.5 + scale
        end
    end
    if const and const.MonsterBuff and const.MonsterBuff.ShrinkingRay then
        local shrinkBuff = mon.SpellBuffs[const.MonsterBuff.ShrinkingRay]
        if shrinkBuff and shrinkBuff.ExpireTime > Game.Time and shrinkBuff.Power > 0 then
            scale = scale / shrinkBuff.Power
        end
    end
    return height * scale, radius * scale
end

-- Active debuffs helper (tracks duration ratios and stack counts)
local DEBUFF_BUFF_DEFS = nil
local debuff_duration_tracker = {}
local nextHitSeq = 0
local lastMonstersOutput = {}

local function getDebuffDefs()
    if DEBUFF_BUFF_DEFS then
        return DEBUFF_BUFF_DEFS
    end
    if not (const and const.MonsterBuff) then
        return {}
    end
    local mb = const.MonsterBuff
    DEBUFF_BUFF_DEFS = {
        { id = mb.Paralyze,     name = "Paralyze" },
        { id = mb.Stoned,       name = "Stoned" },
        { id = mb.Slow,         name = "Slow" },
        { id = mb.ArmorHalved,  name = "ArmorHalved" },
        { id = mb.DamageHalved, name = "DamageHalved" },
        { id = mb.MeleeOnly,    name = "MeleeOnly" },
        { id = mb.ShrinkingRay, name = "ShrinkingRay" },
        { id = mb.Fear,         name = "Fear" },
        { id = mb.Charm,        name = "Charm" },
        { id = mb.Berserk,      name = "Berserk" },
        { id = mb.Enslave,      name = "Enslave" },
        { id = mb.Wander,       name = "Wander" },
    }
    return DEBUFF_BUFF_DEFS
end

local function getActiveDebuffs(mon, monIndex)
    local active = {}
    local gameTime = Game.Time
    local minuteTicks = (const and const.Minute) or 256
    local monTracker = debuff_duration_tracker[monIndex]

    for _, def in ipairs(getDebuffDefs()) do
        if def.id then
            local buff = mon.SpellBuffs[def.id]
            if buff and buff.ExpireTime > gameTime then
                local remTicks = buff.ExpireTime - gameTime
                if not monTracker then
                    monTracker = {}
                    debuff_duration_tracker[monIndex] = monTracker
                end
                local bState = monTracker[def.name]
                if not bState or remTicks > bState.prevTicks or bState.maxTicks <= 0 then
                    bState = { maxTicks = remTicks, prevTicks = remTicks }
                    monTracker[def.name] = bState
                else
                    bState.prevTicks = remTicks
                end
                local ratio = math.max(0.0, math.min(1.0, remTicks / math.max(1, bState.maxTicks)))
                local remSec = math.floor(((remTicks / minuteTicks) * 2.0) * 10 + 0.5) / 10.0
                table.insert(active, {
                    Name = def.name,
                    Ratio = math.floor(ratio * 1000 + 0.5) / 1000,
                    Remaining = remSec
                })
            elseif monTracker then
                monTracker[def.name] = nil
            end
        end
    end
    if mapvars then
        local spearStack = mapvars.spearDamageIncrease and mapvars.spearDamageIncrease[monIndex] or 0
        if spearStack > 0 then
            table.insert(active, {
                Name = "Spear",
                Stacks = math.max(1, math.floor(spearStack + 0.5))
            })
        end
        local legStack = mapvars.legendaryDamageTaken and mapvars.legendaryDamageTaken[monIndex] or 0
        if legStack > 0 then
            table.insert(active, {
                Name = "Legendary",
                Stacks = math.max(1, math.floor(legStack + 0.5))
            })
        end
    end
    return active
end

local function getMonsterDRInfo(mon, monIndex)
    local isUnstoppable = (getBossSkill and getBossSkill(mon) == "Unstoppable")
    local minuteTicks = (const and const.Minute) or 256
    local ccWindowTicks = 10 * minuteTicks -- 10 * const.Minute (~20 seconds)
    local drData = nil
    local now = Game.Time

    -- Group 2: Mind (Fear, Charm, Berserk, Enslave)
    -- Group 3: Stun (Paralyze, Stun)
    local groups = {
        { name = "Mind", id = 2 },
        { name = "Stun", id = 3 }
    }

    for _, g in ipairs(groups) do
        local ratio = 0
        if getMonsterCCRatio then
            ratio = getMonsterCCRatio(monIndex, g.id) or 0
        end

        local isImmune = (ratio >= 0.60)
        if g.id == 3 and isUnstoppable then
            isImmune = true
            ratio = math.max(ratio, 1.0)
        end

        -- Check monster's CC history to find when the rolling window expires
        local history = mapvars and mapvars.ccHistory and mapvars.ccHistory[monIndex] and mapvars.ccHistory[monIndex][g.id]
        local latestEndTime = 0
        if history and #history > 0 then
            for _, entry in ipairs(history) do
                if entry.endTime and entry.endTime > latestEndTime then
                    latestEndTime = entry.endTime
                end
            end
        end

        local windowExpire = latestEndTime + ccWindowTicks
        local isWindowActive = (latestEndTime > 0 and now < windowExpire)

        if ratio >= 0.15 or isWindowActive or (g.id == 3 and isUnstoppable) then
            local tier = 1
            local penalty = 25
            if isImmune then
                tier = 4
                penalty = 100
            elseif ratio >= 0.45 then
                tier = 3
                penalty = 75
            elseif ratio >= 0.30 then
                tier = 2
                penalty = 50
            end

            local remSec = 0
            local decayRatio = 1.0

            if not isUnstoppable or g.id ~= 3 then
                local remTicks = math.max(0, windowExpire - now)
                remSec = math.floor(((remTicks / minuteTicks) * 2.0) * 10 + 0.5) / 10.0
                -- Smooth 20-second rolling window decay ratio:
                decayRatio = math.max(0.0, math.min(1.0, remTicks / ccWindowTicks))
            else
                decayRatio = 1.0
                remSec = 999.0
            end

            drData = drData or {}
            drData[g.name] = {
                Ratio = math.floor(decayRatio * 1000 + 0.5) / 1000,
                Tier = tier,
                Penalty = penalty,
                Remaining = remSec,
                Immune = isImmune
            }
        end
    end

    return drData
end

local function keepHeadOnScreen(headY, footY)
    if headY < 35 and footY > 70 then
        return math.min(math.max(35, headY), footY - 35)
    end
    return headY
end

local function ProjectToScreen(x, y, z, height, radius)
    local eyeLevel = (Party.LastEyeLevel and Party.LastEyeLevel > 40 and Party.LastEyeLevel < 300 and Party.LastEyeLevel) or 105
    local dx, dy = x - Party.X, y - Party.Y
    local dz = z - (Party.Z + eyeLevel)

    local subDir = (Game and Game.PatchOptions and Game.PatchOptions.SubDirection) or 0
    local subLook = (Game and Game.PatchOptions and Game.PatchOptions.SubLookAngle) or 0
    local partyDir = Party.Direction + subDir / 2048.0
    local partyLook = Party.LookAngle + subLook / 2048.0

    local angle = math.rad(partyDir * 360.0 / 2048.0)
    local look = math.rad(partyLook * 180.0 / 1024.0)
    local s = math.sin(angle)
    local c = math.cos(angle)

    local depth = dx * c + dy * s

    -- If depth is zero or behind camera, do not render
    if depth <= 0.1 then 
        return nil, nil
    end

    local horizontal_offset = -dx * s + dy * c
    local base_vertical_offset = dz - depth * math.tan(look)
    local head_vertical_offset = base_vertical_offset + height

    -- Linear perspective scale based on camera depth and FOV
    -- Indoors, GrayFace patch sets IndoorFovMul = 0.81300813 in HW mode,
    -- which scales the effective focal length by 1.0 / 0.813 ~= 1.23 (empirically ~1.205).
    local isIndoor = (Map and Map.IndoorOrOutdoor == 1)
    local fovMul = isIndoor and fovIndoorMultiplier or fovOutdoorMultiplier
    local scale = (screenCenterX * fovMul) / depth

    local screenX = screenCenterX - (horizontal_offset * scale)
    local headY = screenCenterY - (head_vertical_offset * scale)
    local footY = screenCenterY - (base_vertical_offset * scale)
    local halfWidth = (radius or 0) * scale

    -- Check whether the monster's body (feet-to-head and width) intersects the screen bounds
    if (screenX + halfWidth) < -100 or (screenX - halfWidth) > (screenWidth + 100) then
        return nil, nil
    end
    if footY < -100 or headY > (screenHeight + 100) then
        return nil, nil
    end

    return screenX, keepHeadOnScreen(headY, footY)
end

local BillboardArrayRef, BillboardLimitRef, BillboardCount, BillboardStride = 0x43CBF1, 0x43CBF6, 0x529F40, 0x34
local BillboardPid, BillboardSprite, BillboardScaleY, BillboardX, BillboardY = 0x10, 0x18, 0x04, 0x26, 0x28
local MonsterPidKind = 3
local spriteTops, spriteTopsFailed

local function viewRect()
    local po = Game.PatchOptions
    local p = po.Present("RenderRectLeft") and po["?ptr"] + structs.o.PatchOptions.RenderRectLeft or 0xFFDE9C
    return mem.i4[p], mem.i4[p + 4], mem.i4[p + 8], mem.i4[p + 12]
end

local function readSpriteTops()
    local tops = {}
    local base = mem.u4[BillboardArrayRef]
    local count = math.min(mem.i4[BillboardCount], mem.i4[BillboardLimitRef])
    local left, top, right, bottom = viewRect()
    if count <= 0 or right <= left or bottom <= top then
        return tops
    end
    local sx, sy = screenWidth / (right - left), screenHeight / (bottom - top)
    local sprites = Game.SpritesLod.SpritesD3D
    for i = 0, count - 1 do
        local p = base + i * BillboardStride
        local pid = mem.u2[p + BillboardPid]
        local spriteIndex = mem.i2[p + BillboardSprite]
        if pid % 8 == MonsterPidKind and spriteIndex >= 0 and spriteIndex < sprites.count then
            local sprite = sprites[spriteIndex]
            local feet = mem.i2[p + BillboardY]
            local head = feet - (sprite.BufferHeight - sprite.AreaY) * mem.i4[p + BillboardScaleY] / 0x10000
            tops[(pid - MonsterPidKind) / 8] = {
                x = (mem.i2[p + BillboardX] - left) * sx,
                head = (head - top) * sy,
                feet = (feet - top) * sy,
            }
        end
    end
    return tops
end

local barSize = {100, 150, 200, 250, 300, 400}
function CheckBarSize(mon)
    local monType = (mon.Id - 1) % 3 + 1
    if mon.NameId >= 220 and mon.NameId < 300 then
        local nameStr = Game.PlaceMonTxt[mon.NameId] or ""
        local monsterSkill = string.match(nameStr, "([^%s]+)")
        if monsterSkill == "Omnipotent" then
            monType = 6
        elseif monsterSkill == "Broodlord" then
            monType = 5
        else
            monType = 4
        end
    end
    return barSize[monType]
end

local DAMAGE_TYPE_NAMES = {
    [0] = "Fire",
    [1] = "Air",
    [2] = "Water",
    [3] = "Earth",
    [4] = "Phys",
    [5] = "Magic",
    [6] = "Spirit",
    [7] = "Mind",
    [8] = "Body",
    [9] = "Light",
    [10] = "Dark",
    [12] = "Energy",
    [50] = "Dragon"
}

local function getMonsterAttackAndSpells(mon)
    local attackTypes = {}
    local atk1 = mon.Attack1 and mon.Attack1.Type
    local atk1Name = (atk1 and DAMAGE_TYPE_NAMES[atk1]) or (atk1 and const and const.Damage and table.find(const.Damage, atk1)) or "Phys"
    table.insert(attackTypes, atk1Name)

    if (mon.Attack2Chance or 0) > 0 and mon.Attack2 then
        local atk2 = mon.Attack2.Type
        local atk2Name = (atk2 and DAMAGE_TYPE_NAMES[atk2]) or (atk2 and const and const.Damage and table.find(const.Damage, atk2))
        if atk2Name and atk2Name ~= atk1Name then
            table.insert(attackTypes, atk2Name)
        end
    end

    local spells = {}
    if (mon.SpellChance or 0) > 0 and (mon.Spell or 0) > 0 and Game.SpellsTxt and Game.SpellsTxt[mon.Spell] then
        local s1Name = Game.SpellsTxt[mon.Spell].Name
        if s1Name and s1Name ~= "" then
            table.insert(spells, s1Name)
        end
    end
    if (mon.Spell2Chance or 0) > 0 and (mon.Spell2 or 0) > 0 and mon.Spell2 ~= mon.Spell and Game.SpellsTxt and Game.SpellsTxt[mon.Spell2] then
        local s2Name = Game.SpellsTxt[mon.Spell2].Name
        if s2Name and s2Name ~= "" then
            table.insert(spells, s2Name)
        end
    end

    return attackTypes, spells
end

local function getPartyIdMonsterMastery()
    if not (Party and const and const.Skills and const.Skills.IdentifyMonster) then
        return 0
    end
    local maxM = 0
    for i = 0, Party.High do
        local pl = Party[i]
        if pl then
            local s, m = SplitSkill(pl:GetSkill(const.Skills.IdentifyMonster))
            local s1, m1 = SplitSkill(pl.Skills[const.Skills.IdentifyMonster])
            if (s1 and s1 > 0) or (s and s > 0) then
                local effM = math.max(m or 0, m1 or 0)
                if effM == 0 then
                    effM = 1
                end
                if effM > maxM then
                    maxM = effM
                end
            end
        end
    end
    return maxM
end

local ELEMENT_SPECS = {
    { Name = "Fire", Kind = 0 },
    { Name = "Air", Kind = 1 },
    { Name = "Water", Kind = 2 },
    { Name = "Earth", Kind = 3 },
    { Name = "Mind", Kind = 7 },
    { Name = "Body", Kind = 8 },
    { Name = "Light", Kind = 9 },
    { Name = "Dark", Kind = 10 },
}

local function getMonsterResistances(mon)
    local results = {}
    if not mon then
        return results
    end
    local txt = Game.MonstersTxt and Game.MonstersTxt[mon.Id]

    local specs = {
        { Name = "Phys", Val = (mon.Resistances and mon.Resistances[4]) or mon.PhysResistance or 0, Base = (txt and ((txt.Resistances and txt.Resistances[4]) or txt.PhysResistance)) or 0 },
        { Name = "Fire", Val = (mon.Resistances and mon.Resistances[0]) or mon.FireResistance or 0, Base = (txt and ((txt.Resistances and txt.Resistances[0]) or txt.FireResistance)) or 0 },
        { Name = "Air", Val = (mon.Resistances and mon.Resistances[1]) or mon.AirResistance or 0, Base = (txt and ((txt.Resistances and txt.Resistances[1]) or txt.AirResistance)) or 0 },
        { Name = "Water", Val = (mon.Resistances and mon.Resistances[2]) or mon.WaterResistance or 0, Base = (txt and ((txt.Resistances and txt.Resistances[2]) or txt.WaterResistance)) or 0 },
        { Name = "Earth", Val = (mon.Resistances and mon.Resistances[3]) or mon.EarthResistance or 0, Base = (txt and ((txt.Resistances and txt.Resistances[3]) or txt.EarthResistance)) or 0 },
        { Name = "Spirit", Val = (mon.Resistances and mon.Resistances[6]) or mon.SpiritResistance or 0, Base = (txt and ((txt.Resistances and txt.Resistances[6]) or txt.SpiritResistance)) or 0 },
        { Name = "Mind", Val = (mon.Resistances and mon.Resistances[7]) or mon.MindResistance or 0, Base = (txt and ((txt.Resistances and txt.Resistances[7]) or txt.MindResistance)) or 0 },
        { Name = "Body", Val = (mon.Resistances and mon.Resistances[8]) or mon.BodyResistance or 0, Base = (txt and ((txt.Resistances and txt.Resistances[8]) or txt.BodyResistance)) or 0 },
        { Name = "Light", Val = (mon.Resistances and mon.Resistances[9]) or mon.LightResistance or 0, Base = (txt and ((txt.Resistances and txt.Resistances[9]) or txt.LightResistance)) or 0 },
        { Name = "Dark", Val = (mon.Resistances and mon.Resistances[10]) or mon.DarkResistance or 0, Base = (txt and ((txt.Resistances and txt.Resistances[10]) or txt.DarkResistance)) or 0 },
    }

    for _, s in ipairs(specs) do
        local raw = s.Val
        local baseRaw = s.Base
        -- In MAW, Fire resistance encodes HP scaling in thousands (raw % 1000 is actual resistance)
        local val = (s.Name == "Fire") and (raw % 1000) or raw

        -- 3-Tier resistance system:
        -- Tier 3 (Glowing Crowned): >= 200 (75%+ dmg reduction, former 'immune')
        -- Tier 2 (Crowned): >= 100 (50%-74% dmg reduction)
        -- Tier 1 (Standard): >= 50 (~29%-49% dmg reduction)
        local tier = 0
        if val >= 200 then
            tier = 3
        elseif val >= 100 then
            tier = 2
        elseif val >= 50 then
            tier = 1
        end

        table.insert(results, {
            Name = s.Name,
            Value = val,
            Base = baseRaw,
            Tier = tier,
            Immune = (tier >= 3)
        })
    end
    return results
end

local function isMonsterAlly(mon)
    if not mon then
        return false
    end
    if mon.Ally == 9999 then
        return true
    end
    if mon.IsAgainst then
        local ok, against = pcall(function() return mon:IsAgainst() end)
        if ok and against == 0 then
            return true
        end
    end
    if not mon.Hostile and not mon.ShowAsHostile then
        return true
    end
    return false
end

local function isPeasantOrGuardName(name)
    if not name then return false end
    local lower = name:lower()
    return (lower:find("peasant") ~= nil or (lower:find("guard") ~= nil and lower:find("guardian") == nil))
end

local function getMonsterDisplayName(mon)
    if not mon then return "" end
    local name = (Game.MonstersTxt[mon.Id] and Game.MonstersTxt[mon.Id].Name) or ""
    if mon.NameId and mon.NameId > 0 and Game.PlaceMonTxt and Game.PlaceMonTxt[mon.NameId] then
        name = Game.PlaceMonTxt[mon.NameId]
    end
    return name
end

local function buildMonsterEntry(key, mon, value_table, dist, now)
    local hp, fullHP = getRealHP(mon)
    local hp_before_hit = (value_table and value_table.hp_before_hit) or hp
    local is_crit = (value_table and value_table.is_crit) or false

    local name = getMonsterDisplayName(mon)

    local level = (getMonsterLevel and getMonsterLevel(mon)) or mon.Level
    local bSize = CheckBarSize(mon)
    local height, radius = getMonsterVisualDimensions(mon)
    local screenX, screenY
    local sprite = spriteTops and spriteTops[key]
    if spriteTops then
        if not sprite then
            return nil
        end
        screenX, screenY = sprite.x, keepHeadOnScreen(sprite.head, sprite.feet)
    else
        screenX, screenY = ProjectToScreen(mon.X, mon.Y, mon.Z, height, radius)
        if not (screenX and screenY) then
            return nil
        end
    end

    local actual_damage = 0
    local recent_hits = {}
    if value_table then
        if value_table.last_hit_damage and value_table.last_hit_damage > 0 then
            actual_damage = math.min(fullHP, value_table.last_hit_damage)
        else
            actual_damage = math.max(0, math.min(hp_before_hit, hp_before_hit - hp))
        end

        if value_table.recent_hits then
            local kept = {}
            for _, h in ipairs(value_table.recent_hits) do
                if (now - (h.Time or 0)) <= 1.2 then
                    table.insert(kept, h)
                    table.insert(recent_hits, {
                        Seq = h.Seq,
                        Damage = h.Damage,
                        Crit = h.Crit
                    })
                end
            end
            value_table.recent_hits = kept
        end
    end

    local debuffs = getActiveDebuffs(mon, key)
    local attackTypes, spells = getMonsterAttackAndSpells(mon)
    local drInfo = getMonsterDRInfo(mon, key)

    return {
        Index = key,
        Name = name,
        Level = level,
        HP = hp,
        FullHP = fullHP,
        Distance = dist,
        ScreenX = screenX,
        ScreenY = screenY,
        SpriteTop = sprite ~= nil,
        VisualHeight = math.floor(height + 0.5),
        BarSize = bSize,
        LastHitDamage = actual_damage,
        IsCrit = is_crit,
        IsAlly = isMonsterAlly(mon),
        Debuffs = debuffs,
        AttackTypes = attackTypes,
        Spells = spells,
        RecentHits = recent_hits,
        DR = drInfo,
        Resistances = getMonsterResistances(mon)
    }
end

local function recordHitEvent(entry, damage, is_crit, now)
    local dmg = math.max(0, math.floor((damage or 0) + 0.5))
    if dmg <= 0 then
        return
    end
    nextHitSeq = nextHitSeq + 1
    entry.recent_hits = entry.recent_hits or {}
    table.insert(entry.recent_hits, {
        Seq = nextHitSeq,
        Damage = dmg,
        Crit = not not is_crit,
        Time = now
    })
    while #entry.recent_hits > 8 do
        table.remove(entry.recent_hits, 1)
    end
end

local function overlayEnabled()
    return _G.MAW_LuaOverlay ~= nil and MAW_LuaOverlay.IsEnabled ~= nil and MAW_LuaOverlay.IsEnabled()
end

function events.LoadMap()
    mapvars.damaged_monsters = {}
    debuff_duration_tracker = {}
    lastMonstersOutput = {}
    reconcileExistingPotionBuffs()
end

-- Reconcile active potion buffs from MAW tables for save compatibility
function reconcileExistingPotionBuffs()
    if not vars or not Party then return end
    vars.ActivePotionBuffs = vars.ActivePotionBuffs or {}
    local gameTime = Game.Time
    for p = 0, Party.High do
        local pl = Party[p]
        local index = pl:GetIndex()
        vars.ActivePotionBuffs[index] = vars.ActivePotionBuffs[index] or {}
        local pBuffs = vars.ActivePotionBuffs[index]

        -- Check Day of the Gods (Divine Blessing, 257)
        if vars.mawPotionBuff and vars.mawPotionBuff[index] and vars.mawPotionBuff[index][83] and vars.mawPotionBuff[index][83] > gameTime then
            if not pBuffs[257] then
                pBuffs[257] = { ExpireTime = vars.mawPotionBuff[index][83], Name = Game.ItemsTxt[257].Name }
            end
        end
        -- Check Day of Protection (Divine Resistance, 263)
        if vars.mawPotionBuff and vars.mawPotionBuff[index] and vars.mawPotionBuff[index][85] and vars.mawPotionBuff[index][85] > gameTime then
            if not pBuffs[263] then
                pBuffs[263] = { ExpireTime = vars.mawPotionBuff[index][85], Name = Game.ItemsTxt[263].Name }
            end
        end
        -- Check Paladin's Potion (251) vs Protection (231) vs Stone Skin (234)
        if vars.mawPotionBuff and vars.mawPotionBuff[index] then
            local expShield = vars.mawPotionBuff[index][const.Spells.Shield] or 0
            local expStone = vars.mawPotionBuff[index][const.Spells.StoneSkin] or 0
            if expShield > gameTime and expShield == expStone then
                if not pBuffs[251] then
                    pBuffs[251] = { ExpireTime = expShield, Name = Game.ItemsTxt[251].Name }
                end
            else
                if expShield > gameTime and not pBuffs[231] and not pBuffs[251] then
                    pBuffs[231] = { ExpireTime = expShield, Name = Game.ItemsTxt[231].Name }
                end
                if expStone > gameTime and not pBuffs[234] and not pBuffs[251] then
                    pBuffs[234] = { ExpireTime = expStone, Name = Game.ItemsTxt[234].Name }
                end
            end
        end
        -- Check Champion's Potion (245) vs Haste (228) vs Heroism (229)
        if vars.mawPotionBuff and vars.mawPotionBuff[index] then
            local expHaste = vars.mawPotionBuff[index][const.Spells.Haste] or 0
            local expHero = vars.mawPotionBuff[index][const.Spells.Heroism] or 0
            if expHaste > gameTime and expHaste == expHero then
                if not pBuffs[245] then
                    pBuffs[245] = { ExpireTime = expHaste, Name = Game.ItemsTxt[245].Name }
                end
            else
                if expHaste > gameTime and not pBuffs[228] and not pBuffs[245] then
                    pBuffs[228] = { ExpireTime = expHaste, Name = Game.ItemsTxt[228].Name }
                end
                if expHero > gameTime and not pBuffs[229] and not pBuffs[245] then
                    pBuffs[229] = { ExpireTime = expHero, Name = Game.ItemsTxt[229].Name }
                end
            end
        end
        -- Check Elemental Resistance (249)
        if vars.mawPotionBuff and vars.mawPotionBuff[index] and vars.mawPotionBuff[index][3] and vars.mawPotionBuff[index][3] > gameTime then
            if not pBuffs[249] then
                pBuffs[249] = { ExpireTime = vars.mawPotionBuff[index][3], Name = Game.ItemsTxt[249].Name }
            end
        end
        -- Check Self Resistance (250)
        if vars.mawPotionBuff and vars.mawPotionBuff[index] and vars.mawPotionBuff[index][58] and vars.mawPotionBuff[index][58] > gameTime then
            if not pBuffs[250] then
                pBuffs[250] = { ExpireTime = vars.mawPotionBuff[index][58], Name = Game.ItemsTxt[250].Name }
            end
        end
        -- Check Quickmind / Meditation (232)
        if vars.bonusMeditation and vars.bonusMeditation[index] and vars.bonusMeditation[index][1] and vars.bonusMeditation[index][1] > gameTime then
            if not pBuffs[232] then
                pBuffs[232] = { ExpireTime = vars.bonusMeditation[index][1], Name = Game.ItemsTxt[232].Name }
            end
        end
        -- Check Regeneration (233)
        if pl.SpellBuffs[const.PlayerBuff.Regeneration] and pl.SpellBuffs[const.PlayerBuff.Regeneration].ExpireTime > gameTime then
            if not pBuffs[233] then
                pBuffs[233] = { ExpireTime = pl.SpellBuffs[const.PlayerBuff.Regeneration].ExpireTime, Name = Game.ItemsTxt[233].Name }
            end
        end
        -- Check Magic Protection (237)
        if vars.magicResistancePotionExpire and vars.magicResistancePotionExpire > gameTime then
            if not pBuffs[237] then
                pBuffs[237] = { ExpireTime = vars.magicResistancePotionExpire, Name = Game.ItemsTxt[237].Name, IsParty = true }
            end
        end
    end
end

-- Active potion buff alerts helper
local function getActivePotionBuffs()
    reconcileExistingPotionBuffs()
    if not Party or not vars or not vars.ActivePotionBuffs then
        return {}
    end
    local gameTime = Game.Time
    local alerts = {}
    local seenPartyBuffs = {}

    for p = 0, Party.High do
        local pl = Party[p]
        local pIdx = pl:GetIndex()
        local pBuffs = vars.ActivePotionBuffs[pIdx]
        if pBuffs then
            local toRemove = nil
            for potId, data in pairs(pBuffs) do
                if type(data) == "table" and data.ExpireTime then
                    local remTicks = data.ExpireTime - gameTime
                    if remTicks <= 0 then
                        toRemove = toRemove or {}
                        table.insert(toRemove, potId)
                    else
                        local remSec = math.max(0, math.floor(((remTicks / 128.0) * 10 + 0.5)) / 10.0)
                        local isParty = (data.IsParty == true)
                        if isParty then
                            if not seenPartyBuffs[potId] then
                                seenPartyBuffs[potId] = true
                                table.insert(alerts, {
                                    Potion = data.Name or "Potion",
                                    Player = "Party",
                                    Remaining = remSec,
                                    IsParty = true,
                                    PlayerSlot = p,
                                })
                            end
                        else
                            table.insert(alerts, {
                                Potion = data.Name or "Potion",
                                Player = pl.Name or ("Player " .. (p + 1)),
                                Remaining = remSec,
                                IsParty = false,
                                PlayerSlot = p,
                            })
                        end
                    end
                end
            end
            if toRemove then
                for _, id in ipairs(toRemove) do
                    pBuffs[id] = nil
                end
            end
        end
    end

    table.sort(alerts, function(a, b)
        return a.Remaining < b.Remaining
    end)

    return alerts
end

-- Hook that triggers when damage is calculated (runs before MawCore.Damage pipeline)
function events.CalcDamageToMonster(t)
    if not overlayEnabled() or not t or type(t.MonsterIndex) ~= "number" or t.MonsterIndex < 0 or t.MonsterIndex > Map.Monsters.High then
        return
    end
    local mon = Map.Monsters[t.MonsterIndex]
    if mon then
        local curHP, _ = getRealHP(mon)
        mapvars.damaged_monsters = mapvars.damaged_monsters or {}
        local entry = mapvars.damaged_monsters[t.MonsterIndex] or {}
        entry.timestamp = os.clock()
        entry.hp_before_hit = curHP
        entry.last_hit_damage = nil
        entry.is_crit = false
        entry.hit_recorded_this_calc = false
        mapvars.damaged_monsters[t.MonsterIndex] = entry
    end
end

-- Hook called by MawCore/Damage.lua stage_trackAndClamp:
-- ShowDamage(data.Player, damage, DamageState.isCrit(), data.Object, t.Monster)
function ShowDamage(pl, damage, crit, obj, mon)
    if mon and overlayEnabled() then
        local ok, idx = pcall(function() return mon:GetIndex() end)
        if ok and idx and idx >= 0 and idx <= Map.Monsters.High then
            local now = os.clock()
            mapvars.damaged_monsters = mapvars.damaged_monsters or {}
            local entry = mapvars.damaged_monsters[idx] or {}
            if crit then entry.is_crit = true elseif entry.is_crit == nil then entry.is_crit = false end
            entry.last_hit_damage = math.max(0, math.floor((damage or 0) + 0.5))
            entry.timestamp = now
            if entry.last_hit_damage > 0 then
                entry.last_damage = now
            end
            entry.hit_recorded_this_calc = true
            recordHitEvent(entry, entry.last_hit_damage, entry.is_crit, now)
            mapvars.damaged_monsters[idx] = entry
        end
    end
end

-- Hook published at the end of MawCore.Damage pipeline
function events.MawMonsterDamage(t)
    if t and type(t.MonsterIndex) == "number" and (t.Result or 0) > 0 and overlayEnabled() then
        local now = os.clock()
        mapvars.damaged_monsters = mapvars.damaged_monsters or {}
        local entry = mapvars.damaged_monsters[t.MonsterIndex]
        if entry then
            entry.timestamp = now
            entry.last_damage = now
            if MawCore and MawCore.DamageState and MawCore.DamageState.isCrit() then
                entry.is_crit = true
            end
            if not entry.hit_recorded_this_calc then
                entry.last_hit_damage = math.max(0, math.floor((t.Result or 0) + 0.5))
                entry.hit_recorded_this_calc = true
                recordHitEvent(entry, entry.last_hit_damage, entry.is_crit, now)
            end
        end
    end
end

-- On every tick, decide which monsters to show and write to JSON
function events.Tick()
    if not overlayEnabled() then
        return
    end
    local now = os.clock()
    refreshResolutionIfNeeded(now)

    local inMenu = (Game.CurrentScreen ~= 0)
    local idMonsterMastery = getPartyIdMonsterMastery()
    local potionBuffs = getActivePotionBuffs()

    if inMenu then
        local final_output = {
            MapName = (Map and Map.Name) or "",
            InMenu = true,
            IdMonsterMastery = idMonsterMastery,
            Monsters = lastMonstersOutput,
            TargetedMonsterIndex = nil,
            PotionBuffs = potionBuffs,
        }
        _G.MAW_Overlay_LiveData = final_output
        if _G.MAW_LuaOverlay and _G.MAW_LuaOverlay.Tick then
            pcall(_G.MAW_LuaOverlay.Tick, final_output)
        end
        local ok, encoded = pcall(json.encode, final_output)
        if ok and encoded and (encoded ~= lastEncodedOutput or (now - lastWriteTime >= 0.5)) then
            local f = io.open(file_path, "w")
            if f then
                f:write(encoded)
                f:close()
                lastEncodedOutput = encoded
                lastWriteTime = now
            end
        end
        return
    end

    spriteTops = nil
    if Game.IsD3D and not spriteTopsFailed then
        local ok, tops = pcall(readSpriteTops)
        if ok then
            spriteTops = tops
        else
            spriteTopsFailed = true
            print("[overlay] billboard read failed, using the old projection: " .. tostring(tops))
        end
    end
    local output = {}
    local monsters_to_remove = {}
    local targeted_monster_index = nil

    local tar = Mouse:GetTarget()
    if tar and tar.Kind == 3 and tar.Index >= 0 and tar.Index <= Map.Monsters.High then
        targeted_monster_index = tar.Index
    end

    mapvars.damaged_monsters = mapvars.damaged_monsters or {}

    -- Auto-track party summons / companions (Ally == 9999) so their health bar is always visible when in range
    for i = 0, Map.Monsters.High do
        local m = Map.Monsters[i]
        if m and m.HP > 0 and m.ShowOnMap and m.Ally == 9999 then
            local dist = getDistance(Party, m)
            if dist <= 5120 then
                if not mapvars.damaged_monsters[i] then
                    local curHP, _ = getRealHP(m)
                    mapvars.damaged_monsters[i] = {
                        timestamp = now,
                        hp_before_hit = curHP,
                        is_crit = false
                    }
                else
                    mapvars.damaged_monsters[i].timestamp = now
                end
            end
        end
    end

    -- Also auto-track any nearby hostile or allied monster that currently has an active CC/debuff
    local gameTime = Game.Time
    local defs = getDebuffDefs()
    if #defs > 0 then
        for i = 0, Map.Monsters.High do
            if not mapvars.damaged_monsters[i] then
                local m = Map.Monsters[i]
                if m and m.HP > 0 and m.ShowOnMap and (m.ShowAsHostile or isMonsterAlly(m)) then
                    local curHP, fullHP = getRealHP(m)
                    local isAlly = isMonsterAlly(m)
                    local name = getMonsterDisplayName(m)
                    if not (isAlly and isPeasantOrGuardName(name) and curHP >= fullHP) then
                        for _, def in ipairs(defs) do
                            local b = def.id and m.SpellBuffs[def.id]
                            if b and b.ExpireTime > gameTime then
                                local curHP, _ = getRealHP(m)
                                mapvars.damaged_monsters[i] = {
                                    timestamp = now,
                                    hp_before_hit = curHP,
                                    is_crit = false
                                }
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    local included_targeted = false

    for key, value_table in pairs(mapvars.damaged_monsters) do
        if type(key) ~= "number" or key < 0 or key > Map.Monsters.High then
            table.insert(monsters_to_remove, key)
            goto continue_loop
        end

        local mon = Map.Monsters[key]
        if not mon or not mon.ShowOnMap or (not mon.ShowAsHostile and not isMonsterAlly(mon)) then
            table.insert(monsters_to_remove, key)
            goto continue_loop
        end

        local hp, fullHP = getRealHP(mon)
        local isAlly = isMonsterAlly(mon)
        local name = getMonsterDisplayName(mon)

        -- "Peasant" and "Guard" allies only show their HP bar if they are not at 100% HP
        if isAlly and isPeasantOrGuardName(name) and hp >= fullHP then
            table.insert(monsters_to_remove, key)
            goto continue_loop
        end
        local last_hit_timestamp = value_table.timestamp or now

        local effective_display_time = 30000.0
        if hp == 0 then
            effective_display_time = 30.5
        end

        if (now - last_hit_timestamp <= effective_display_time) then
            local dist = getDistance(Party, mon)
            local damageAge = now - (value_table.last_damage or -math.huge)
            local recentlyDamaged = hideBarAfter <= 0 or damageAge <= hideBarAfter
            if dist <= 5120 and (hp == 0 or isAlly or recentlyDamaged) then
                local entry = buildMonsterEntry(key, mon, value_table, dist, now)
                if entry then
                    table.insert(output, entry)
                    if key == targeted_monster_index then
                        included_targeted = true
                    end
                end
            end
        else
            table.insert(monsters_to_remove, key)
        end
        ::continue_loop::
    end

    for _, key in ipairs(monsters_to_remove) do
        mapvars.damaged_monsters[key] = nil
        debuff_duration_tracker[key] = nil
    end

    -- Include mouseover target even if it has not been damaged yet
    if targeted_monster_index and not included_targeted and hideBarAfter <= 0 then
        local mon = Map.Monsters[targeted_monster_index]
        if mon and mon.HP > 0 and mon.ShowOnMap and (mon.ShowAsHostile or isMonsterAlly(mon)) then
            local hp, fullHP = getRealHP(mon)
            local isAlly = isMonsterAlly(mon)
            local name = getMonsterDisplayName(mon)
            if not (isAlly and isPeasantOrGuardName(name) and hp >= fullHP) then
                local dist = getDistance(Party, mon)
                if dist <= 5120 then
                    local entry = buildMonsterEntry(targeted_monster_index, mon, nil, dist, now)
                    if entry then
                        table.insert(output, entry)
                    end
                end
            end
        end
    end

    lastMonstersOutput = output

    local final_output = {
        MapName = Map.Name or "",
        InMenu = false,
        IdMonsterMastery = idMonsterMastery,
        Monsters = output,
        TargetedMonsterIndex = targeted_monster_index,
        PotionBuffs = potionBuffs,
    }
    _G.MAW_Overlay_LiveData = final_output
    if _G.MAW_LuaOverlay and _G.MAW_LuaOverlay.Tick then
        pcall(_G.MAW_LuaOverlay.Tick, final_output)
    end

    local ok, encoded = pcall(json.encode, final_output)
    if ok and encoded then
        -- Only write when data changed (or every 0.5s as heartbeat) to prevent read/write flicker
        if encoded ~= lastEncodedOutput or (now - lastWriteTime >= 0.5) then
            local f = io.open(file_path, "w")
            if f then
                f:write(encoded)
                f:close()
                lastEncodedOutput = encoded
                lastWriteTime = now
            end
        end
    end
end
