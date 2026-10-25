-- MAW / MMMerge: correct known legacy trainer and hireling text.
-- Only visible text is changed here. Skill IDs and class tables stay intact.
-- MM6/7/8 text IDs were cross-checked against the MMMerge reference text tables.
-- The descriptions are read through Game.NPCProf's dynamic NPCText lookup.
-- Do not do global Learning/Diplomacy replacements: normal quest dialogue and
-- internal const.Skills.Learning use those words for unrelated reasons.

local ascensionOverview =
    "Ascension strengthens spell damage and healing at the cost of higher " ..
    "mana consumption and casting time. "

-- The six MM8/MM7 trainer speeches still advertised XP gains. Preserve
-- the original rank/price numbers so MAW's teacher-dialog formatter can
-- replace them with the difficulty-mode-specific requirements and cost.
local ascensionTrainerTexts = {
    [414] = ascensionOverview ..
        "I can teach you Expert Ascension if your skill is level 4 and you pay 2000 gold.",
    [415] = ascensionOverview ..
        "I can teach you Master Ascension if your Expert skill is level 7 and you pay 5000 gold.",
    [416] = ascensionOverview ..
        "I can teach you Grand Master Ascension if your Master skill is level 10 and you pay 8000 gold.",
    [1382] = ascensionOverview ..
        "I can teach you Expert Ascension if your skill is level 4 and you pay 2000 gold.",
    [1383] = ascensionOverview ..
        "I can teach you Master Ascension if your Expert skill is level 7 and you pay 5000 gold.",
    [1384] = ascensionOverview ..
        "I can teach you Grand Master Ascension if your Master skill is level 10 and you pay 8000 gold.",
    -- Original MM6 expert and master training speeches:
    [1950] = ascensionOverview ..
        "I can teach you Expert Ascension if your skill is level 4 and you pay 2000 gold.",
    [1951] = ascensionOverview ..
        "I can teach you Master Ascension if your Expert skill is level 7 and you pay 5000 gold.",
}

-- The base game labels these two old MM6 diplomacy speeches as unused.
-- Still update them when present, since a custom map can reference them.
-- Avoid hard-coded requirements: they are supplied by the trainer's logic.
local legacyDiplomacyTexts = {
    [1946] = "I can teach you Expert Alchemy if you meet the requirements.",
    [1947] = "I can teach you Master Alchemy if you meet the requirements.",
}

-- Hints remain otherwise unchanged, including trainer names and locations.
local ascensionHintTextIds = {519, 520, 521, 1480, 1481, 1988}
local ascensionTopicIds = {414, 415, 416, 1058, 1059, 1060, 1571, 1572}
local alchemyTopicIds = {1031, 1032, 1033}

local function replaceSkillWord(s, old, new)
    -- Lua frontier patterns match whole words, not "Learning" in other words.
    return s:gsub("%f[%a]" .. old .. "%f[%A]", new)
end

local function replaceDescription(id, summary)
    local original = Game.NPCText[id]
    if not original or original == "" then return end

    -- Keep the engine's placeholders for NPC name and fee. NPCFollowers.lua
    -- performs the %01 / %17 substitutions when the player reads the text.
    local fee = original:match("(%%01 takes .*)")
    Game.NPCText[id] = summary .. (fee and ("\n" .. fee) or "")
end

function events.GameInitialized2()
    if not Game.NPCText or not Game.NPCTopic then return end

    for id, updated in pairs(ascensionTrainerTexts) do
        local original = Game.NPCText[id]
        if original and original:find("Learning", 1, true) then
            Game.NPCText[id] = updated
        end
    end

    for id, updated in pairs(legacyDiplomacyTexts) do
        local original = Game.NPCText[id]
        if original and original:lower():find("diploma", 1, true) then
            Game.NPCText[id] = updated
        end
    end

    for _, id in ipairs(ascensionHintTextIds) do
        local original = Game.NPCText[id]
        if original then
            original = replaceSkillWord(original, "Learning", "Ascension")
            -- ID 1988 uses lowercase "learning skill".
            if id == 1988 then
                original = replaceSkillWord(original, "learning", "Ascension")
            end
            Game.NPCText[id] = original
        end
    end

    for _, id in ipairs(ascensionTopicIds) do
        local original = Game.NPCTopic[id]
        if original then
            Game.NPCTopic[id] = replaceSkillWord(original, "Learning", "Ascension")
        end
    end

    -- Legacy MM6 diplomacy-topic labels; modern merged trainers use Alchemy.
    for _, id in ipairs(alchemyTopicIds) do
        local original = Game.NPCTopic[id]
        if original then
            Game.NPCTopic[id] = replaceSkillWord(original, "Diplomacy", "Alchemy")
        end
    end

    -- Scholar (4), Teacher (13), Instructor (14): effective Ascension
    -- (internal Learning skill ID) levels, only the highest counts, and only
    -- for characters who have learned Ascension.
    -- MAW has no experience bonus from these followers.
    replaceDescription(2324, "Can identify items and grants +2 effective Ascension skill to party members who have learned Ascension.")
    replaceDescription(2333, "Grants +4 effective Ascension skill to party members who have learned Ascension.")
    replaceDescription(2334, "Grants +6 effective Ascension skill to party members who have learned Ascension.")

    -- Counselor (23) and Barrister (24) no longer have a working Diplomacy
    -- bonus; no Alchemy or Merchant bonus is defined for them in MAW.
    -- Do not invent a replacement bonus merely to match an old tooltip.
    replaceDescription(2343, "No skill bonus is implemented for the Counselor in MAW.")
    replaceDescription(2344, "No skill bonus is implemented for the Barrister in MAW.")

    -- Negotiator (49): +4 effective Merchant, restored in the bonus table.
    -- There is no bonus to Alchemy or to the removed Diplomacy skill.
    replaceDescription(2369, "Grants +4 effective Merchant skill to party members.")
end
