local u1, u2, u4, i1, i2, i4 = mem.u1, mem.u2, mem.u4, mem.i1, mem.i2, mem.i4
local hook, autohook, autohook2, asmpatch = mem.hook, mem.autohook, mem.autohook2, mem.asmpatch
local max, min, round, random = math.max, math.min, math.round, math.random
local format = string.format

-- malloc always returns 0 (not enough memory) in mm8 multiplayer if no win xp compatibility?
local alloc, free = mem.allocMM, mem.freeMM

--[[
function events.BuildItemInformationBox(t)
    parameters:
    Item
    either one of these groups will be set at once (they are texts you can modify; event handler will be called three times for single item):
        Type, Enchantment, BasicStat - enchantment is also charges etc., basic stat is "armor: +X" or "Damage: 1d1+1" etc.
        Description
        Name
]]

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
    --define[0x5E4CB0].array(0, skillsCount).EditPChar("SkillDescriptions")
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

-- adjust item values
mem.hookfunction(0x453CE7, 1, 0, function(d, def, itemPtr)
	local t = {Item = structs.Item:new(itemPtr), Value = def(itemPtr)}
	events.call("CalcItemValue", t)
	return t.Value
end)

-- modify item tooltip
--[[
do
    local itemTypeBuf, itemTypeBufLen
    mem.autohook2(0x41D220, function(d)
        local text = mem.string(u4[d.esp + 4])
        local t = {Item = structs.Item:new(u4[d.esp + 0x10]), TxtItem = structs.ItemsTxtItem:new(d.edi), Text = text}
        events.call("GetItemTooltipType", t)
        if text ~= t.Text then
            local len = t.Text:len()
            if not itemTypeBufLen or len + 1 > itemTypeBufLen then -- +1 for null terminator
                if itemTypeBuf then
                    mem.freeMM(itemTypeBuf)
                end
                itemTypeBufLen = len + 1
                itemTypeBuf = mem.allocMM(itemTypeBufLen)
            end
            mem.copy(itemTypeBuf, t.Text)
            u1[itemTypeBuf + len] = 0 -- null terminator
        end
    end, 7)
end
]]

local ROW_COUNT = 5
local itemTextRowAddresses = mem.StaticAlloc(ROW_COUNT*4)
local itemTextRowContentsByIndex = {}

local function prepareTable(d, rows)
    local t = {}
    for _, row in pairs(rows) do
        t[row.name] = mem.string(row.addr)
        row.text = t[row.name]
    end
    t.Item = structs.Item:new(u4[d.ebp - 4])
    return t
end

local function processNewTexts(t, rows)
    for _, rowData in pairs(rows) do
        assert(rowData.index < ROW_COUNT)
        local addr, name = rowData.addr, rowData.name
        if t[name] ~= rowData.text then
            local newLen = rowData.text:len()
            local contentData = itemTextRowContentsByIndex[rowData.index]
            if not contentData or contentData.len < newLen + 1 then -- len is length of content (without null terminator)
                if contentData then
                    free(contentData.buf)
                end
                local new = {}
                new.buf, new.len = alloc(newLen + 1), newLen
                itemTextRowContentsByIndex[rowData.index] = new
                contentData = new
            end
            mem.copy(contentData.buf, t[name] .. string.char(0))
            addr = contentData.buf
        end
        u4[itemTextRowAddresses + rowData.index * 4] = addr
    end
end

local function itemTooltipEvent(t)
    events.cocall("BuildItemInformationBox", t)
end
local INDEX_DESCRIPTION, INDEX_NAME = 3, 4

autohook2(0x41D40E, function(d)
    --[[
        0x270 - item type str
        0x20C - basic stat (like "Armor: +50")
        0x1A8 - enchantment/charges/power
        0x74 - full item name (assigned later)
    ]]
    local rows = {
        Type = {
            addr = d.ebp - 0x270,
            index = 0,
            name = "Type",
        },
        BasicStat = {
            addr = d.ebp - 0x20C,
            index = 1,
            name = "BasicStat",
        },
        Enchantment = {
            addr = d.ebp - 0x1A8,
            index = 2,
            name = "Enchantment",
        }
    }
    local t = prepareTable(d, rows)
    itemTooltipEvent(t)
    processNewTexts(t, rows)
end)

local hooks = HookManager{addresses = itemTextRowAddresses}

-- calc text height

-- change address ptr to index
asmpatch(0x41D405, [[
    and dword ptr [ebp-8],0
]], 9)

hooks.asmpatch(0x41D415, [[
    mov eax, dword [ebp - 8]
    mov eax, dword [%addresses% + eax * 4]
    cmp [eax], bl
]])

asmpatch(0x41D41C, "mov edx, eax")

asmpatch(0x41D438, "inc dword [ebp - 8]")

-- write text

asmpatch(0x41D591, [[
    and dword [ebp - 0x14], 0
]], 9)

hooks.asmpatch(0x41D5A1, [[
    mov eax, dword [ebp - 0x14]
    mov eax, dword [%addresses% + eax * 4]
    cmp [eax], bl
]])

hooks.asmpatch(0x41D5BB, [[
    mov edx, [ebp - 0x14]
    mov edx, [%addresses% + edx * 4]
    mov ecx,dword ptr [ebp-0x10]
]])

asmpatch(0x41D5D1, "inc dword [ebp - 0x14]")

local code = asmpatch(0x41D441, [[
    nop
    nop
    nop
    nop
    nop
    cmp [edi], bl
]])

hook(code, function(d)
    local rows = {
        Description = {
            addr = u4[d.edi + 0xC],
            index = INDEX_DESCRIPTION,
            name = "Description",
        }
    }
    local t = prepareTable(d, rows)
    itemTooltipEvent(t)
    processNewTexts(t, rows)
    d.edi = itemTextRowContentsByIndex[rows.Description.index].buf
end)

autohook(0x41D4BD, function(d)
    local rows = {
        Name = {
            addr = d.eax,
            index = INDEX_NAME,
            name = "Name",
        }
    }
    local t = prepareTable(d, rows)
    itemTooltipEvent(t)
    processNewTexts(t, rows)
    d.eax = itemTextRowContentsByIndex[rows.Name.index].buf
end)

hook(0x41D5DA, function(d)
    d.eax = itemTextRowContentsByIndex[INDEX_DESCRIPTION].buf
end)

autohook(0x41D60C, function(d)
    d.eax = itemTextRowContentsByIndex[INDEX_NAME].buf
end)

local function randomStr(chars, len)
    local str = ""
    for i = 1, len do
        local idx = math.random(1, chars:len())
        str = str .. chars:sub(idx, idx)
    end
    return str
end

-- ITEM NAME HOOK --
-- there are two variations, one is for any item, second for only identified items. First one jumps to second if item is identified
-- any item variant requires asmpatch to hookfunction it, because it has short jump
-- since both variations are called by game code, I need two hooks here
-- however, I opted for using hook manager to disable second hook if first is entered and reenable after finishing, to avoid unnecessary double hook
-- so "identified items only" hook is called only if game calls precisely this address, and not "any item" address

addr = asmpatch(0x453D3E, [[
    test byte ptr [ecx+0x14],1
    je absolute 0x453D58
]], 0x6)

local function getOwnBufferHookFunction(identified)
    local itemNameBuf, itemNameBufLen
    return function(d, def, itemPtr)
        local defNamePtr = def(itemPtr)
        -- identified name only means that function should only set full item names, if it's false, when item is not identified, for example only "Chain Mail" may be set
        local t = {Item = structs.Item:new(d.ecx), Name = mem.string(defNamePtr), IdentifiedNameOnly = identified}
        local prevName = t.Name
        events.call("GetItemName", t)
        if t.Name ~= prevName then
            local len = t.Name:len()
            if len <= 0x63 then
                mem.copy(0x5E4888, t.Name .. string.char(0))
            else
                if not itemNameBuf or itemNameBufLen < len + 1 then
                    if itemNameBuf then
                        free(itemNameBuf)
                    end
                    itemNameBufLen = len + 1
                    itemNameBuf = alloc(itemNameBufLen)
                end
                mem.copy(itemNameBuf, t.Name .. string.char(0))
                return itemNameBuf
            end
        end
        return defNamePtr
    end
end

local identifiedItemNameHooks = HookManager()
identifiedItemNameHooks.hookfunction(0x453D58, 1, 0, getOwnBufferHookFunction(true))

local secondHookFunc = getOwnBufferHookFunction(false)
mem.hookfunction(addr, 1, 0, function(d, def, itemPtr)
    identifiedItemNameHooks.Switch(false)
    local r = secondHookFunc(d, def, itemPtr)
    identifiedItemNameHooks.Switch(true)
    return r
end)

-- test handlers, disable once you want to test your own

function events.GetItemName(t)
    t.Name = t.Name .. "myitem"
end

function events.BuildItemInformationBox(t)
    if t.Type then
        t.Type = t.Type .. randomStr("abc", 12)
        t.BasicStat = t.BasicStat .. randomStr("190", 25)
        t.Enchantment = t.Enchantment .. randomStr("tyu", 50)
    elseif t.Name then
        t.Name = t.Name .. t.Item.Number
    elseif t.Description then
        t.Description = t.Description .. "this is description lol"
    end
end