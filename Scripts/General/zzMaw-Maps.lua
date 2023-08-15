------------------------------
-- RESTORE MM6 sprites
------------------------------

-- Mapping of original sprite names to new sprite names
local spriteMappings = {
    -- ROCKS
    ["rock01"] = "Rok1",
    ["rock02"] = "Rok2",
    ["rock03"] = "Rok3",
    ["rock04"] = "Rok4",
    ["rock05"] = "Rok5",
    ["rock06"] = "Rok6",
    ["rock07"] = "Rok7",
    ["rock08"] = "Rok8",
    ["rock09"] = "Rok9",
    ["rock10"] = "Rok1",
    ["rock11"] = "Rok1",
    ["rock12"] = "Rok1",
    ["rock13"] = "Rok1",
    ["rock14"] = "Rok1",
    
    -- FLOWERS
    ["flower01"] = "6Flower01",
    ["flower02"] = "6Flower02",
    ["flower03"] = "6Flower03",
    ["flower04"] = "6Flower04",
    ["flower05"] = "6Flower05",
    ["flower06"] = "6Flower06",
    ["flower07"] = "6Flower07",
    ["flower08"] = "6Flower08",
    ["flower09"] = "6Flower09",
    ["flower10"] = "6Flower10",
    ["flower11"] = "6Flower11",
    ["flower12"] = "6Flower12",
    ["flower13"] = "6Flower13",
    
    -- CORPSES
    ["Corpse"] = "Corpse01",
    ["Corpse01"] = "Corpse02",
    ["Corpse02"] = "Corpse03",
    ["Corpse03"] = "Corpse04",
    ["Corpse04"] = "Corpse05",
    ["Corpse05"] = "Corpse06",
    ["Corpse06"] = "Corpse07",
    ["Corpse07"] = "Corpse08",
    ["Corpse08"] = "Corpse09",
    ["Corpse09"] = "Corpse10",
    ["Corpse10"] = "Corpse11",
    ["Corpse11"] = "Corpse12",
    ["Corpse12"] = "Corpse13",
    ["Corpse13"] = "Corpse14",
    ["Corpse14"] = "Corpse15",
    ["Corpse15"] = "Corpse16",
    ["Corpse16"] = "Corpse17",
    ["Corpse17"] = "Corpse18",
    ["Corpse18"] = "Corpse19",
    ["Corpse19"] = "Corpse20",
}

function events.AfterLoadMap()
    if Map.MapStatsIndex >= 137 and Map.MapStatsIndex <= 203 then
        for i = 0, Map.Sprites.High do
            local sprite = Map.Sprites[i]
            local newSpriteName = spriteMappings[sprite.DecName]
            if newSpriteName then
                sprite.DecName = newSpriteName
            end
        end
    end
end
