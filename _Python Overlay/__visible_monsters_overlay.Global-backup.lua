local json = require("json")
local file_path = [[C:\Users\Syspack pc\Desktop\Might and Magic 8 ONLINE\_Python Overlay\visible_monsters.json]]

-- Distance utility
local function getDistance(p, m)
    return math.sqrt((p.X - m.X)^2 + (p.Y - m.Y)^2 + (p.Z - m.Z)^2)
end

local screenWidth = 2560.0
local screenHeight = 1440.0
local screenCenterX = screenWidth / 2.0
local screenCenterY = screenHeight / 2.0

local function ProjectToScreen(x, y, z, height)
    local dx, dy, dz = x - Party.X, y - Party.Y, z - Party.Z

    local angle = math.rad(Party.Direction * 360.0 / 2048.0)
    local look = math.rad(Party.LookAngle * 180.0 / 1024.0)
    local s = math.sin(angle)
    local c = math.cos(angle)

    local depth = dx * c + dy * s
    local horizontal_offset = -dx * s + dy * c

    -- If depth is zero or negative, the object is behind the camera and should not be drawn.
    if depth <= 0.1 then -- Use a small threshold to avoid division by zero
        return nil, nil
    end
	
	local distance=math.sqrt((Party.X - x)^2 + (Party.Y - y)^2 + (Party.Z - z)^2)
    local vertical_offset = dz - depth * math.tan(look)
    local scale_x = screenCenterX / distance
    local scale_y = screenCenterY / depth
    local screenX = screenCenterX - math.max(math.min(horizontal_offset*1.25 * scale_x, screenCenterX/1.1),-screenCenterX/1.1)
    local screenY = screenCenterY - math.max(math.min(vertical_offset*2 * scale_y + height*(screenHeight/distance)^0.5, screenCenterY/1.1),-screenCenterY/1.8)

    return screenX, screenY
end

function events.LoadMap()
    mapvars.damaged_monsters = mapvars.damaged_monsters or {}
end

-- Hook that triggers when damage is calculated (including environmental, other monster, etc.)
function events.CalcDamageToMonster(t)
    local mon = Map.Monsters[t.MonsterIndex]
    if mon then
        -- We store timestamp and HP here, but 'is_crit' will be more accurately set by ShowDamage
        -- This ensures 'hp_before_hit' is always from the most recent damage calculation
        mapvars.damaged_monsters[t.MonsterIndex] = mapvars.damaged_monsters[t.MonsterIndex] or {}
        mapvars.damaged_monsters[t.MonsterIndex].timestamp = os.clock()
        mapvars.damaged_monsters[t.MonsterIndex].hp_before_hit = mon.HP -- Store HP *before* the damage is applied
        -- IMPORTANT: Do NOT reset is_crit here. Let ShowDamage set it if it's a crit.
        -- If CalcDamageToMonster is triggered by a non-crit after a crit, we want the crit indicator to persist briefly.
    end
end

-- On every tick, decide which monsters to show and write to JSON
function events.Tick()
    local now = os.clock()
    local output = {}
    
    if Game.CurrentScreen ~= 0 then return end -- Only process in game screen
    
    local monsters_to_remove = {}
    local targeted_monster_index = nil

    local tar = Mouse:GetTarget()
    if tar and tar.Kind == 3 then
        targeted_monster_index = tar.Index
    end

    for key, value_table in pairs(mapvars.damaged_monsters) do
        local mon = Map.Monsters[key]
        
		local exponent=math.floor(mon.Resistances[0]/1000)
		local hp=mon.HP*2^exponent
		local fullHP=mon.FullHP*2^exponent
		
        if not mon or not mon.ShowOnMap or not mon.ShowAsHostile then
            table.insert(monsters_to_remove, key)
            goto continue_loop
        end

        local last_hit_timestamp = value_table.timestamp
        local hp_before_hit = value_table.hp_before_hit or fullHP -- Fallback for safety
        local is_crit = value_table.is_crit or false -- Retrieve crit status

        local effective_display_time = 30000.0
        if hp == 0 then
            effective_display_time = 30.5
        end

        if (now - last_hit_timestamp <= effective_display_time) then
            local dist = getDistance(Party, mon)
            if dist <= 5120 then
                local name = Game.MonstersTxt[mon.Id].Name
                if mon.NameId > 0 then
                    name = Game.PlaceMonTxt[mon.NameId]
                end
                local barSize = CheckBarSize(mon)

                local height = Game.MonListBin[mon.Id].Height
                local screenX, screenY = ProjectToScreen(mon.X, mon.Y, mon.Z, height)
                
				if screenX and screenY then
                    local actual_damage = math.max(0, math.min(hp_before_hit, hp_before_hit - hp))
                    
                    table.insert(output, {
                        Index = key,
                        Name = name,
                        HP = hp,
                        FullHP = fullHP,
                        Distance = dist,
                        ScreenX = screenX,
                        ScreenY = screenY,
                        BarSize = barSize,
                        LastHitDamage = actual_damage,
                        IsCrit = is_crit -- Include IsCrit in the output JSON
                    })
                end
            end
        else
            table.insert(monsters_to_remove, key)
        end
        ::continue_loop::
    end

    for _, key in ipairs(monsters_to_remove) do
        mapvars.damaged_monsters[key] = nil
    end

    local final_output = {
        Monsters = output,
        TargetedMonsterIndex = targeted_monster_index
    }

    local f = io.open(file_path, "w")
    if f then
        f:write(json.encode(final_output))
        f:close()
    else
        -- print(f"Error: Could not open file for writing: {file_path}")
    end
end

local barSize={100,150,200,250,300,400}
function CheckBarSize(mon)
    local monType=(mon.Id-1)%3+1
    if mon.NameId>=220 and mon.NameId<300 then
        local monsterSkill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
        if monsterSkill=="Omnipotent" then
            monType=6
        elseif monsterSkill=="Broodling" then
            monType=5
        else
            monType=4
        end
    end
    return barSize[monType]
end

-- MODIFIED: Update this function to explicitly set 'is_crit'
function ShowDamage(pl, damage, crit, obj, mon)
    -- This hook is called by the game when damage is displayed to the player.
    -- If 'obj' is a monster and 'crit' is true, update its crit status.
    if obj and obj.Kind == 3 and mon and mapvars.damaged_monsters[obj.Index] then
        -- Ensure mapvars.damaged_monsters[obj.Index] table exists
        mapvars.damaged_monsters[obj.Index] = mapvars.damaged_monsters[obj.Index] or {}
        -- Set is_crit based on the 'crit' parameter from ShowDamage
        mapvars.damaged_monsters[obj.Index].is_crit = crit or false
        -- Also ensure the timestamp is updated so the bar is shown.
        mapvars.damaged_monsters[obj.Index].timestamp = os.clock()
        -- Note: hp_before_hit is set by CalcDamageToMonster for accuracy on damage number
    end
end
