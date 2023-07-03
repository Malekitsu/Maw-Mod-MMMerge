local u1, u2, u4, i1, i2, i4 = mem.u1, mem.u2, mem.u4, mem.i1, mem.i2, mem.i4

local skillsCount = 39
function structs.f.SkillMasteryDescriptions(define)
    local skipAmount = (skillsCount + 1) * 4
    define[0].EditPChar("GM")
    [skipAmount].EditPChar("Master")
    [skipAmount*2].EditPChar("Expert")
    [skipAmount*3].EditPChar("Novice")
    .size = 4
end

local oldGame = structs.f.GameStructure
function structs.f.GameStructure(define, ...)
    oldGame(define, ...)
    define[0x5E4A30].array(0, skillsCount).struct(structs.SkillMasteryDescriptions)("SkillMasteryDescriptions")
    define[0x5E4A30].array(0, skillsCount).EditPChar("SkillDescriptionsGM")
    define[0x5E4AD0].array(0, skillsCount).EditPChar("SkillDescriptionsMaster")
    define[0x5E4B70].array(0, skillsCount).EditPChar("SkillDescriptionsExpert")
    define[0x5E4C10].array(0, skillsCount).EditPChar("SkillDescriptionsNovice")
    --define[0x5E4CB0].array(0, skillsHigh + 1).EditPChar("SkillDescriptions")
    -- some stat descriptions: 0x5E4D50
end

-- build skill information box
local function tooltipHook(includesBonus)
    return function(d)
        local t = {ExtraText = "", IncludesBonus = includesBonus, Skill = u4[d.esp + 4]}
        t.PlayerIndex, t.Player = internal.GetPlayer(u4[d.ebp - 4])
        events.call("BuildSkillInformationBox", t)
        local text = t.ExtraText
        if #text > 0 then
            local destination = d.esi
            if not includesBonus then
                text = "\f00000" .. text -- remove color (if bonus is not printed, "color tag" is not closed)
            end
            mem.copy(destination + mem.string(destination):len(), text .. "\0")
        end
    end
end
--function events.BuildSkillInformationBox(t) if t.Skill == const.Skills.Armsmaster then t.ExtraText = "\n\nThis is armsmaster"; else t.ExtraText = "\n\nThis is not armsmaster" end end
mem.autohook2(0x4174C5, tooltipHook(true), 8)
mem.autohook2(0x417648, tooltipHook(false), 8)

-- build stat description box
mem.hookcall(0x417BA5, 2, 0, function(d, def, headerPtr, textPtr)
    local header, text = mem.string(headerPtr), mem.string(textPtr)
    local t = {Stat = u4[d.ebp - 8], Header = header, Text = text}
    assert(Game.CurrentPlayer ~= -1)
    t.Player = Party[Game.CurrentPlayer]
    events.call("BuildStatInformationBox", t)
    local changedHeader, changedText = t.Header ~= header, t.Text ~= text
    if changedHeader then
        local len = #t.Header
        headerPtr = mem.allocMM(len + 1)
        mem.copy(headerPtr, t.Header)
        u1[headerPtr + len] = 0
    end
    if changedText then
        local len = #t.Text
        textPtr = mem.allocMM(len + 1)
        mem.copy(textPtr, t.Text)
        u1[textPtr + len] = 0
    end

    def(headerPtr, textPtr)

    if changedHeader then
        mem.freeMM(headerPtr)
    end
    if changedText then
        mem.freeMM(textPtr)
    end
end)