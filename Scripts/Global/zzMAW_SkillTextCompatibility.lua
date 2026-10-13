-- MAW/MMMerge skill-name compatibility. UI strings only; never rename skill IDs.
-- The original MMMerge data still contains Learning/Diplomacy descriptions.
-- Limit replacements to known text IDs to avoid changing unrelated quests.
local npcTextIds = {
    -- MM8 Learning/Ascension teachers, with old XP-bonus explanations:
    414, 415, 416, 1382, 1383, 1384,
    -- MM6 Learning teachers:
    1950, 1951,
    -- MM8/MM7 teacher-location hints:
    519, 520, 521, 1480, 1481, 1988,
}
local topicIds = {
    414, 415, 416, 1058, 1059, 1060, 1571, 1572
}

local function replaceLearningTeacherText(s)
    -- Old teacher descriptions assert that Learning grants extra XP.
    -- Don't silently retain false mechanics or invent training requirements.
    if s:find("Learning allows you to gain more experience", 1, true) then
        local first = s:find("I will instruct you", 1, true)
        if first then
            s = "Ascension enhances spellcasting rather than experience gained. " .. s:sub(first)
        end
    end
    s = s:gsub("Expert Learning", "Expert Ascension")
         :gsub("Master Learning", "Master Ascension")
         :gsub("Grand Master Learning", "Grand Master Ascension")
         :gsub("Learning skill", "Ascension skill")
         :gsub("learning skill", "Ascension skill")
         :gsub("skill of Learning", "skill of Ascension")
         :gsub("Master of Learning", "Master of Ascension")
         :gsub("master of learning", "master of Ascension")
         :gsub("of learning", "of Ascension")
    return s
end

function events.GameInitialized2()
    for _, id in ipairs(npcTextIds) do
        local original = Game.NPCText[id]
        if original and original ~= "" then
            Game.NPCText[id] = replaceLearningTeacherText(original)
        end
    end
    for _, id in ipairs(topicIds) do
        local original = Game.NPCTopic[id]
        if original and original ~= "" then
            Game.NPCTopic[id] = original:gsub("Learning", "Ascension")
        end
    end

    -- In MAW the Learning skill slot is Ascension. The follower bonuses
    -- use const.Skills.Learning (ID retained), not the old XP mechanic.
    local descriptions = {
        [2324] = "Identifies items and grants +5 Ascension skill points to each character.",
        [2333] = "Grants +10 Ascension skill points to each character.",
        [2334] = "Grants +15 Ascension skill points to each character.",
        -- Negotiator profession 49: MAW follower code grants +4 Merchant.
        -- No Alchemy or Diplomacy bonus is implemented.
        [2369] = "Grants +4 Merchant skill points to each character.",
    }
    for id, prefix in pairs(descriptions) do
        local original = Game.NPCText[id]
        if original and original ~= "" then
            local fee = original:match("(%%01 takes .*)")
            Game.NPCText[id] = prefix .. (fee and ("\n" .. fee) or "")
        end
    end
end
