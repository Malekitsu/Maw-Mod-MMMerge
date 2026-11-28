-- ============================================================================
-- MAW_Overlay.lua
-- Pure LuaJIT + GDI+ Monster HP Overlay Engine for Might & Magic MAW.
-- Ports 100% of _Python Overlay/MAW_Overlay.py into native Lua + Win32 GDI+.
-- ============================================================================

if jit and jit.off then
    jit.off(true, true)
end

local ffi = require("ffi")

-- Determine SCRIPT_DIR automatically
local function get_script_dir()
    if _G.AppPath then
        return (_G.AppPath:gsub("/", "\\"):gsub("\\+$", "")) .. "\\MAW LUA OVERLAY"
    end
    local info = debug.getinfo(1, "S")
    local src = info and info.source or ""
    if src:sub(1, 1) == "@" then src = src:sub(2) end
    src = src:gsub("/", "\\")
    local dir = src:match("^(.*)\\[^\\]+$")
    return dir or "."
end

local SCRIPT_DIR = get_script_dir()
local gdi = _G._MAW_WIN32_GDIPLUS_MOD or dofile(SCRIPT_DIR .. "\\win32_gdiplus.lua")
local game_target = _G.mem and _G.events and dofile(SCRIPT_DIR .. "\\d3d_game_target.lua")

local M = {}
_G._MAW_OVERLAY_MOD = M
M.SCRIPT_DIR = SCRIPT_DIR

-- ============================================================================
-- Configuration & Constants
-- ============================================================================
M.JSON_PATH     = SCRIPT_DIR .. "\\visible_monsters.json"
M.SETTINGS_FILE = SCRIPT_DIR .. "\\overlay_settings.json"
M.UI_FOLDER     = SCRIPT_DIR .. "\\UI"
M.THEMES_DIR    = SCRIPT_DIR .. "\\themes"
M.FONTS_DIR     = SCRIPT_DIR .. "\\fonts"
M.BOSS_ICONS_DIR   = SCRIPT_DIR .. "\\boss icons"
M.DEBUFF_ICONS_DIR = SCRIPT_DIR .. "\\debuff icons"
M.ATTACK_ICONS_DIR = SCRIPT_DIR .. "\\attack icons"
M.SPELL_ICONS_DIR  = SCRIPT_DIR .. "\\spell icons"

M.DEFAULT_UI_THEME = "MAW (Default)"
M.MICRO_BAR_OPTIONS = { "Off", "On", "Dynamic", "Only Micro" }
M.DEFAULT_MICRO_BAR_MODE = "Dynamic"

M.DEFAULT_FONT_FILE = "Ubuntu-Bold.ttf"
M.DEFAULT_FONT_SIZE = 12
M.DEFAULT_TEXT_COLOR = { 255, 255, 255, 255 }
M.DEFAULT_TEXT_OUTLINE_WIDTH = 1
M.DEFAULT_TEXT_OUTLINE_COLOR = { 0, 0, 0, 255 }

M.DEFAULT_SHOW_MOUSEOVER_ONLY    = false
M.DEFAULT_HIDE_IN_MENUS          = true
M.DEFAULT_SMART_ANTI_OVERLAP     = true
M.DEFAULT_TIE_TO_ID_MONSTER      = false
M.DEFAULT_SHOW_NAME_TEXT         = true
M.DEFAULT_SHOW_HP_NUMBERS        = true
M.DEFAULT_SHOW_MONSTER_LEVEL     = false
M.DEFAULT_SHOW_ATTACK_SPELL_ICONS = true
M.DEFAULT_SHOW_DEBUFF_ICONS      = true
M.DEFAULT_SHOW_DEBUFF_TIMERS     = true
M.DEFAULT_SHOW_DEBUFF_STACKS     = true
M.DEFAULT_SHOW_FLOATING_DAMAGE   = true
M.DEFAULT_SHOW_CC_DR_TRACKER     = true
M.DEFAULT_SHOW_POTION_BUFF_TRACKER = true
M.DEFAULT_POTION_WARNING_THRESHOLD = 20.0
M.DEFAULT_POTION_TRACKER_POS_X   = 0.015
M.DEFAULT_POTION_TRACKER_POS_Y   = 0.56
M.DEFAULT_SHOW_RESISTANCE_PIPS   = true
M.DEFAULT_SHOW_ALLY_BARS         = true
M.DEFAULT_SHOW_BOSS_ICONS        = true
M.DEFAULT_SHOW_KILL_SKULL        = true
M.DEFAULT_SHOW_SPLASH_SCREEN     = false
M.DEFAULT_HIGH_RESISTANCE_THRESHOLD = 100
M.DEFAULT_BAR_VERTICAL_OFFSET    = 0
M.DEFAULT_FOV_SCALE_INDOOR       = 0.96
M.DEFAULT_FOV_SCALE_OUTDOOR      = 1.00

M.RESISTANCE_ELEMENTS = {
    { "Phys",   "Physical" },
    { "Fire",   "Fire" },
    { "Air",    "Air" },
    { "Water",  "Water" },
    { "Earth",  "Earth" },
    { "Spirit", "Spirit" },
    { "Mind",   "Mind" },
    { "Body",   "Body" },
    { "Light",  "Light" },
    { "Dark",   "Dark" },
}

M.DEFAULT_RESISTANCE_COLORS = {
    Phys   = { 190, 198, 210, 255 },
    Fire   = { 255,  75,  35, 255 },
    Air    = { 100, 225, 255, 255 },
    Water  = {  35, 130, 255, 255 },
    Earth  = { 185, 125,  55, 255 },
    Spirit = { 245, 160, 220, 255 },
    Mind   = { 185,  85, 255, 255 },
    Body   = {  65, 215,  75, 255 },
    Light  = { 255, 240, 130, 255 },
    Dark   = { 115,  50, 165, 255 },
}

M.DEFAULT_BASE_HEIGHT           = 20
M.DEFAULT_LEFT_CAP_WIDTH        = 3
M.DEFAULT_RIGHT_CAP_WIDTH       = 3
M.DEFAULT_FILL_HEIGHT           = 14
M.DEFAULT_BOSS_ICON_BASE_SIZE   = 32
M.DEFAULT_DEBUFF_ICON_BASE_SIZE = 18
M.DEFAULT_CLOSE_RANGE_THRESHOLD = 450
M.DEFAULT_SHORTEN_NUMBER_DIGITS = 4
M.DEFAULT_RESOLUTION            = "Auto ( Native Screen )"

M.DRAIN_HOLD_DURATION = 0.15
M.DRAIN_SPEED_FACTOR  = 6.5
M.DEATH_POP_DURATION  = 0.40
M.FLOAT_DMG_DURATION  = 1.15
M.FLOAT_DMG_RISE_PX   = 46.0
M.FLOAT_DMG_BASE_COLOR = { 255, 255, 255, 255 }
M.FLOAT_DMG_SUFFIX_COLORS = {
    K = { 255, 255, 30, 255 },
    M = { 255, 165, 0, 255 },
    B = { 255, 0, 0, 255 },
}
M.SPLASH_HOLD_DURATION = 3.0
M.SPLASH_FADE_DURATION = 0.8

M.BOSS_PREFIXES = {
    "Venomous", "Leecher", "Leech", "Exploding", "Adamantite", "Puller",
    "Summoner", "Swift", "Regenerating", "Reflecting", "Thorn",
    "Swapper", "Fixator", "Plagueborn", "Broodlord", "Broodling",
    "Omnipotent", "Shadow", "Cryptic", "Unstoppable", "Berserker", "Berserk", "Skilled"
}

-- Per-monster ID default Y offsets (calibrated per monster ID 1..652)
M.MONSTER_DEFAULT_Y_OFFSETS = {}
do
    local ranges = {
        {   1,   6,  -90 }, {   7,   9,  -40 }, {  10,  15, -120 }, {  16,  24,  -95 },
        {  25,  30, -125 }, {  31,  33, -100 }, {  34,  40,  -80 }, {  41,  41,  -90 },
        {  42,  42, -115 }, {  43,  48,  -95 }, {  49,  51, -100 }, {  52,  57,  -95 },
        {  58,  60, -125 }, {  61,  63, -115 }, {  64,  66, -150 }, {  67,  69, -100 },
        {  70,  72, -430 }, {  73,  73, -145 }, {  74,  75, -200 }, {  76,  76,  -85 },
        {  77,  77, -115 }, {  78,  81, -150 }, {  82,  82, -105 }, {  83,  83, -140 },
        {  84,  84, -155 }, {  85,  85,  -50 }, {  86,  86,  -60 }, {  87,  90,  -70 },
        {  91,  93, -150 }, {  94,  94,  -50 }, {  95,  95,  -80 }, {  96,  99, -100 },
        { 100, 102, -140 }, { 103, 105, -210 }, { 106, 108, -130 }, { 109, 109,  -80 },
        { 110, 110, -100 }, { 111, 111, -155 }, { 112, 112, -115 }, { 113, 113, -150 },
        { 114, 114, -190 }, { 115, 117, -150 }, { 118, 120,  -40 }, { 121, 123, -150 },
        { 124, 126,  -60 }, { 127, 127, -120 }, { 128, 132, -130 }, { 133, 133, -120 },
        { 134, 134, -125 }, { 135, 135, -130 }, { 136, 136, -150 }, { 137, 137, -190 },
        { 138, 138, -230 }, { 139, 141, -100 }, { 142, 142,  -80 }, { 143, 143, -110 },
        { 144, 144, -160 }, { 145, 148, -140 }, { 149, 149, -160 }, { 150, 150, -190 },
        { 151, 151, -150 }, { 152, 152, -160 }, { 153, 153, -170 }, { 154, 156, -140 },
        { 157, 159, -220 }, { 160, 160,  -60 }, { 161, 161,  -80 }, { 162, 162, -110 },
        { 163, 163,    0 }, { 164, 164,  -40 }, { 165, 165,  -80 }, { 166, 171, -110 },
        { 172, 173, -130 }, { 174, 174, -100 }, { 175, 177,  -75 }, { 178, 186, -120 },
        { 187, 189,  -95 }, { 190, 192, -430 }, { 193, 195,  -90 }, { 196, 198,  -70 },
        { 199, 201, -140 }, { 202, 204,  -80 }, { 205, 205, -120 }, { 206, 206, -130 },
        { 207, 207, -150 }, { 208, 208, -120 }, { 209, 213, -130 }, { 214, 216,  -80 },
        { 217, 219,  -90 }, { 220, 222,  -70 }, { 223, 225, -450 }, { 226, 226, -120 },
        { 227, 227, -140 }, { 228, 228, -180 }, { 229, 231, -125 }, { 232, 232, -160 },
        { 233, 233, -200 }, { 234, 234, -225 }, { 235, 236,  -90 }, { 237, 237,  -95 },
        { 238, 243, -100 }, { 244, 246,  -70 }, { 247, 255,  -80 }, { 256, 264,  -75 },
        { 265, 270, -105 }, { 271, 273,  -80 }, { 274, 275, -135 }, { 276, 276, -200 },
        { 277, 285, -100 }, { 286, 288,  -80 }, { 289, 291,  -90 }, { 292, 294,  -70 },
        { 295, 297, -100 }, { 298, 299,  -80 }, { 300, 300, -105 }, { 301, 301, -135 },
        { 302, 302, -145 }, { 303, 303,  -90 }, { 304, 309,  -85 }, { 310, 312,  -30 },
        { 313, 321, -130 }, { 322, 330,  -95 }, { 331, 348, -105 }, { 349, 384, -115 },
        { 385, 389,  -75 }, { 390, 390, -100 }, { 391, 393, -130 }, { 394, 396, -100 },
        { 397, 399,  -90 }, { 400, 402,  -60 }, { 403, 405,  -85 }, { 406, 408, -100 },
        { 409, 411, -110 }, { 412, 414,  -70 }, { 415, 426,  -90 }, { 427, 429, -105 },
        { 430, 447, -115 }, { 448, 450, -125 }, { 451, 453, -300 }, { 454, 459,  -90 },
        { 460, 462, -480 }, { 463, 474, -110 }, { 475, 480,  -80 }, { 481, 481, -100 },
        { 482, 483, -115 }, { 484, 484,  -70 }, { 485, 485,  -80 }, { 486, 486, -100 },
        { 487, 489,  -80 }, { 490, 492,  -90 }, { 493, 494,  -75 }, { 495, 495,  -35 },
        { 496, 497,  -75 }, { 498, 500, -105 }, { 501, 501, -115 }, { 502, 502, -100 },
        { 503, 503, -110 }, { 504, 507,  -90 }, { 508, 508, -340 }, { 509, 509, -380 },
        { 510, 510, -390 }, { 511, 513, -200 }, { 514, 516,    0 }, { 517, 519,  -90 },
        { 520, 521,  -75 }, { 522, 522,  -55 }, { 523, 523,  -70 }, { 524, 524,  -80 },
        { 525, 525,  -50 }, { 526, 531,  -70 }, { 532, 537, -115 }, { 538, 540, -105 },
        { 541, 541,  -70 }, { 542, 542,  -75 }, { 543, 543,  -90 }, { 544, 546,  -70 },
        { 547, 549,  -80 }, { 550, 550,  -85 }, { 551, 551,  -90 }, { 552, 555, -105 },
        { 556, 557, -125 }, { 558, 558, -130 }, { 559, 559,  -95 }, { 560, 560, -115 },
        { 561, 561, -140 }, { 562, 564, -115 }, { 565, 565, -105 }, { 566, 566, -125 },
        { 567, 567, -150 }, { 568, 573,  -85 }, { 574, 574, -110 }, { 575, 575, -130 },
        { 576, 576, -140 }, { 577, 577,  -80 }, { 578, 580, -110 }, { 581, 581, -100 },
        { 582, 582, -120 }, { 583, 585,  -85 }, { 586, 588,  -95 }, { 589, 591,  -70 },
        { 592, 618,  -85 }, { 619, 619,  -70 }, { 620, 620,  -50 }, { 621, 621,  -85 },
        { 622, 624,  -60 }, { 625, 626, -340 }, { 627, 627, -440 }, { 628, 628,  -90 },
        { 629, 629, -105 }, { 630, 630, -125 }, { 631, 634,  -80 }, { 635, 635,  -90 },
        { 636, 636, -100 }, { 637, 639,  -85 }, { 640, 642, -100 }, { 643, 645, -110 },
        { 646, 646, -195 }, { 647, 648, -250 }, { 649, 651, -110 }, { 652, 652, -250 },
    }
    for _, r in ipairs(ranges) do
        for id = r[1], r[2] do
            M.MONSTER_DEFAULT_Y_OFFSETS[id] = r[3]
        end
    end
end

M.BOSS_ICON_ALIASES = {
    Exploding = "Explosion",
    Leecher   = "Leech",
    Broodling = "Broodlord",
    Berserk   = "Berserker",
}

M.ATTACK_ICON_ALIASES = {
    physical = "phys",
    poison   = "body",
    pois     = "body",
    elec     = "air",
    cold     = "water",
    ener     = "energy",
}

M.SPELL_ICON_ALIASES = {
    lightningbolt  = "chainlightning",
    chainlightning = "lightningbolt",
    curedisease    = "greaterheal",
    greaterheal    = "curedisease",
    dayogods       = "dayofthegods",
    dayofthegods   = "dayogods",
    psychicshockt  = "psychicshock",
}

M.DEBUFF_DEFS = {
    { key = "Paralyze",     file = "Paralyze.png" },
    { key = "Stoned",       file = "Stoned.png" },
    { key = "Slow",         file = "Slow.png" },
    { key = "ArmorHalved",  file = "ArmorHalved.png" },
    { key = "DamageHalved", file = "DamageHalved.png" },
    { key = "MeleeOnly",    file = "MeleeOnly.png" },
    { key = "ShrinkingRay", file = "ShrinkingRay.png" },
    { key = "Fear",         file = "Fear.png" },
    { key = "Charm",        file = "Charm.png" },
    { key = "Berserk",      file = "Berserk.png" },
    { key = "Enslave",      file = "Enslave.png" },
    { key = "Wander",       file = "Wander.png" },
    { key = "Spear",        file = "Spear.png" },
    { key = "Legendary",    file = "Legendary.png" },
    { key = "Stun",         file = "Stun.png" },
    { key = "ArmorBreak",   file = "ArmorHalved.png" },
    { key = "Shrink",       file = "ShrinkingRay.png" },
    { key = "Weakness",     file = "DamageHalved.png" },
}

M.CC_DR_DEFS = {
    Mind = { file = "dr_mind.png", window = 20.0, side = "left" },
    Stun = { file = "dr_stun.png", window = 20.0, side = "right" },
}

M.POTION_BUFF_DEFS = {
    { key = "Heroism",         label = "Heroism",         color = { 255, 110,  70, 255 } },
    { key = "Bless",           label = "Bless",           color = { 255, 225, 100, 255 } },
    { key = "Haste",           label = "Haste",           color = { 255, 165,  50, 255 } },
    { key = "Stoneskin",       label = "Stoneskin",       color = { 190, 160, 120, 255 } },
    { key = "Shield",          label = "Shield",          color = { 100, 200, 255, 255 } },
    { key = "DayOfTheGods",    label = "Day of Gods",     color = { 255, 240, 150, 255 } },
    { key = "DayOfProtection", label = "Protection",      color = { 140, 220, 255, 255 } },
    { key = "HourOfPower",     label = "Hour of Power",   color = { 255, 130,  90, 255 } },
    { key = "Rejuvenation",    label = "Rejuvenation",    color = { 120, 240, 140, 255 } },
    { key = "Preservation",    label = "Preservation",    color = { 220, 170, 255, 255 } },
}

-- ============================================================================
-- Helper Functions
-- ============================================================================
local function file_exists(path)
    if not path then return false end
    local f = io.open(path, "rb")
    if f then f:close() return true end
    return false
end

local function read_file_text(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local function round(x)
    return math.floor(x + 0.5)
end

local function clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function blend_white(rgb, factor)
    return {
        math.min(255, round(rgb[1] + (255 - rgb[1]) * factor)),
        math.min(255, round(rgb[2] + (255 - rgb[2]) * factor)),
        math.min(255, round(rgb[3] + (255 - rgb[3]) * factor)),
    }
end

function M.is_peasant_or_guard_full_hp_ally(m)
    if not m or not m.IsAlly then return false end
    local hp = tonumber(m.HP) or 0
    local full_hp = tonumber(m.FullHP) or 1
    if hp < full_hp then return false end
    local name = tostring(m.Name or ""):lower()
    if name:find("peasant", 1, true) then return true end
    -- Match "guard" as a whole word (so "Guardian" is not matched)
    for word in name:gmatch("%a+") do
        if word == "guard" or word == "guards" then
            return true
        end
    end
    return false
end

local function norm_icon_key(name)
    return tostring(name or ""):lower():gsub("[^%w]", "")
end

function M.get_available_themes()
    local themes = { M.DEFAULT_UI_THEME }
    local dirs = gdi.list_dir(M.THEMES_DIR, true)
    table.sort(dirs, function(a, b) return a:lower() < b:lower() end)
    for _, d in ipairs(dirs) do
        local trimmed = d:match("^%s*(.-)%s*$")
        local low = trimmed:lower()
        if trimmed ~= "" and trimmed ~= M.DEFAULT_UI_THEME
           and trimmed:sub(1, 1) ~= "." and trimmed:sub(1, 1) ~= "_"
           and not low:find("icon pack", 1, true) then
            themes[#themes + 1] = trimmed
        end
    end
    return themes
end

-- ============================================================================
-- OverlayApp Class
-- ============================================================================
local OverlayApp = {}
OverlayApp.__index = OverlayApp

function M.new_overlay_app(headless_preview)
    local self = setmetatable({
        headless = headless_preview and true or false,
        running = false,
        screen_width = gdi.user32.GetSystemMetrics(0),
        screen_height = gdi.user32.GetSystemMetrics(1),

        -- Caches
        text_cache = {},
        text_cache_count = 0,
        res_pip_cache = {},
        res_pip_cache_count = 0,
        debuff_icon_cache = {},
        debuff_raw_bitmaps = {},
        boss_raw_bitmaps = {},
        attack_raw_bitmaps = {},
        spell_raw_bitmaps = {},

        -- Animation state
        damage_drain_state = {},
        micro_anim_state = {},
        fading_monsters = {},
        permanently_hidden_monsters = {},
        floating_popups = {},
        seen_hit_ids = {},
        last_update_time = gdi.now(),
        splash_start_time = nil,
        last_settings_check = 0,
        last_settings_raw = nil,
        current_loaded_theme = nil,
    }, OverlayApp)

    self:apply_default_settings()
    self:load_settings(true)
    self:load_ui_images()

    if not self.headless then
        self.win = game_target and game_target.create(self.screen_width, self.screen_height, gdi)
            or gdi.create_layered_window(self.screen_width, self.screen_height, "MAW Lua Monster HP Overlay")
    end

    return self
end

function OverlayApp:apply_default_settings()
    self.font_file = M.DEFAULT_FONT_FILE
    self.font_size = M.DEFAULT_FONT_SIZE
    self.text_color = { unpack(M.DEFAULT_TEXT_COLOR) }
    self.text_outline_width = M.DEFAULT_TEXT_OUTLINE_WIDTH
    self.text_outline_color = { unpack(M.DEFAULT_TEXT_OUTLINE_COLOR) }

    self.show_mouseover_only     = M.DEFAULT_SHOW_MOUSEOVER_ONLY
    self.hide_in_menus           = M.DEFAULT_HIDE_IN_MENUS
    self.smart_anti_overlap      = M.DEFAULT_SMART_ANTI_OVERLAP
    self.tie_to_id_monster       = M.DEFAULT_TIE_TO_ID_MONSTER
    self.show_name_text          = M.DEFAULT_SHOW_NAME_TEXT
    self.show_hp_numbers         = M.DEFAULT_SHOW_HP_NUMBERS
    self.show_monster_level      = M.DEFAULT_SHOW_MONSTER_LEVEL
    self.show_attack_spell_icons = M.DEFAULT_SHOW_ATTACK_SPELL_ICONS
    self.show_debuff_icons       = M.DEFAULT_SHOW_DEBUFF_ICONS
    self.show_debuff_timers      = M.DEFAULT_SHOW_DEBUFF_TIMERS
    self.show_debuff_stacks      = M.DEFAULT_SHOW_DEBUFF_STACKS
    self.show_floating_damage    = M.DEFAULT_SHOW_FLOATING_DAMAGE
    self.show_cc_dr_tracker      = M.DEFAULT_SHOW_CC_DR_TRACKER
    self.show_potion_buff_tracker = M.DEFAULT_SHOW_POTION_BUFF_TRACKER
    self.potion_warning_threshold = M.DEFAULT_POTION_WARNING_THRESHOLD
    self.potion_tracker_pos_x    = M.DEFAULT_POTION_TRACKER_POS_X
    self.potion_tracker_pos_y    = M.DEFAULT_POTION_TRACKER_POS_Y
    self.show_resistance_pips    = M.DEFAULT_SHOW_RESISTANCE_PIPS
    self.show_ally_bars          = M.DEFAULT_SHOW_ALLY_BARS
    self.show_boss_icons         = M.DEFAULT_SHOW_BOSS_ICONS
    self.show_kill_skull         = M.DEFAULT_SHOW_KILL_SKULL
    self.show_splash_screen      = M.DEFAULT_SHOW_SPLASH_SCREEN
    self.high_resistance_threshold = M.DEFAULT_HIGH_RESISTANCE_THRESHOLD
    self.micro_bar_mode          = M.DEFAULT_MICRO_BAR_MODE
    self.bar_vertical_offset     = M.DEFAULT_BAR_VERTICAL_OFFSET
    self.fov_scale_indoor        = M.DEFAULT_FOV_SCALE_INDOOR
    self.fov_scale_outdoor       = M.DEFAULT_FOV_SCALE_OUTDOOR

    self.base_height           = M.DEFAULT_BASE_HEIGHT
    self.left_cap_width        = M.DEFAULT_LEFT_CAP_WIDTH
    self.right_cap_width       = M.DEFAULT_RIGHT_CAP_WIDTH
    self.fill_height           = M.DEFAULT_FILL_HEIGHT
    self.boss_icon_base_size   = M.DEFAULT_BOSS_ICON_BASE_SIZE
    self.debuff_icon_base_size = M.DEFAULT_DEBUFF_ICON_BASE_SIZE
    self.close_range_threshold = M.DEFAULT_CLOSE_RANGE_THRESHOLD
    self.shorten_number_digits = M.DEFAULT_SHORTEN_NUMBER_DIGITS
    self.ui_theme              = M.DEFAULT_UI_THEME

    self.resistance_colors = {}
    for k, v in pairs(M.DEFAULT_RESISTANCE_COLORS) do
        self.resistance_colors[k] = { v[1], v[2], v[3], v[4] or 255 }
    end
end

function OverlayApp:clear_caches()
    for _, surf in pairs(self.text_cache) do
        if surf and surf.dispose then surf:dispose() end
    end
    self.text_cache = {}
    self.text_cache_count = 0

    for _, surf in pairs(self.res_pip_cache) do
        if surf and surf.dispose then surf:dispose() end
    end
    self.res_pip_cache = {}
    self.res_pip_cache_count = 0

    for _, surf in pairs(self.debuff_icon_cache) do
        if surf and surf.dispose then surf:dispose() end
    end
    self.debuff_icon_cache = {}
end

function OverlayApp:clear_raw_icon_bitmaps()
    local tables = {
        self.boss_raw_bitmaps,
        self.attack_raw_bitmaps,
        self.spell_raw_bitmaps,
        self.debuff_raw_bitmaps,
    }
    for _, tbl in ipairs(tables) do
        if type(tbl) == "table" then
            for _, bmp in pairs(tbl) do
                if type(bmp) == "table" and bmp.dispose then
                    bmp:dispose()
                end
            end
        end
    end
    self.boss_raw_bitmaps = {}
    self.attack_raw_bitmaps = {}
    self.spell_raw_bitmaps = {}
    self.debuff_raw_bitmaps = {}
end

function OverlayApp:load_settings(force)
    local raw = read_file_text(M.SETTINGS_FILE)
    if not raw then return end
    if not force and raw == self.last_settings_raw then return end
    self.last_settings_raw = raw

    local s = gdi.json_decode(raw)
    if type(s) ~= "table" then return end

    local prev_theme = self.ui_theme
    self.font_file = s.font_file or M.DEFAULT_FONT_FILE
    self.font_size = tonumber(s.font_size) or M.DEFAULT_FONT_SIZE
    if type(s.text_color) == "table" and #s.text_color >= 3 then
        self.text_color = { s.text_color[1], s.text_color[2], s.text_color[3], s.text_color[4] or 255 }
    end
    self.text_outline_width = tonumber(s.text_outline_width) or M.DEFAULT_TEXT_OUTLINE_WIDTH
    if type(s.text_outline_color) == "table" and #s.text_outline_color >= 3 then
        self.text_outline_color = { s.text_outline_color[1], s.text_outline_color[2], s.text_outline_color[3], s.text_outline_color[4] or 255 }
    end

    local function bool_opt(val, def)
        if type(val) == "boolean" then return val end
        return def
    end

    self.show_mouseover_only      = bool_opt(s.show_mouseover_only, M.DEFAULT_SHOW_MOUSEOVER_ONLY)
    self.hide_in_menus            = bool_opt(s.hide_in_menus, M.DEFAULT_HIDE_IN_MENUS)
    self.smart_anti_overlap       = bool_opt(s.smart_anti_overlap, M.DEFAULT_SMART_ANTI_OVERLAP)
    self.tie_to_id_monster        = bool_opt(s.tie_to_id_monster, M.DEFAULT_TIE_TO_ID_MONSTER)
    self.show_name_text           = bool_opt(s.show_name_text, M.DEFAULT_SHOW_NAME_TEXT)
    self.show_hp_numbers          = bool_opt(s.show_hp_numbers, M.DEFAULT_SHOW_HP_NUMBERS)
    self.show_monster_level       = bool_opt(s.show_monster_level, M.DEFAULT_SHOW_MONSTER_LEVEL)
    self.show_attack_spell_icons  = bool_opt(s.show_attack_spell_icons, M.DEFAULT_SHOW_ATTACK_SPELL_ICONS)
    self.show_debuff_icons        = bool_opt(s.show_debuff_icons, M.DEFAULT_SHOW_DEBUFF_ICONS)
    self.show_debuff_timers       = bool_opt(s.show_debuff_timers, M.DEFAULT_SHOW_DEBUFF_TIMERS)
    self.show_debuff_stacks       = bool_opt(s.show_debuff_stacks, M.DEFAULT_SHOW_DEBUFF_STACKS)
    self.show_floating_damage     = bool_opt(s.show_floating_damage, M.DEFAULT_SHOW_FLOATING_DAMAGE)
    self.show_cc_dr_tracker       = bool_opt(s.show_cc_dr_tracker, M.DEFAULT_SHOW_CC_DR_TRACKER)
    self.show_potion_buff_tracker = bool_opt(s.show_potion_buff_tracker, M.DEFAULT_SHOW_POTION_BUFF_TRACKER)
    self.potion_warning_threshold = tonumber(s.potion_warning_threshold) or M.DEFAULT_POTION_WARNING_THRESHOLD
    self.potion_tracker_pos_x     = tonumber(s.potion_tracker_pos_x) or M.DEFAULT_POTION_TRACKER_POS_X
    self.potion_tracker_pos_y     = tonumber(s.potion_tracker_pos_y) or M.DEFAULT_POTION_TRACKER_POS_Y
    self.show_resistance_pips     = bool_opt(s.show_resistance_pips, M.DEFAULT_SHOW_RESISTANCE_PIPS)
    self.show_ally_bars           = bool_opt(s.show_ally_bars, M.DEFAULT_SHOW_ALLY_BARS)
    self.show_boss_icons          = bool_opt(s.show_boss_icons, M.DEFAULT_SHOW_BOSS_ICONS)
    self.show_kill_skull          = bool_opt(s.show_kill_skull, M.DEFAULT_SHOW_KILL_SKULL)
    self.show_splash_screen       = bool_opt(s.show_splash_screen, M.DEFAULT_SHOW_SPLASH_SCREEN)
    self.high_resistance_threshold = tonumber(s.high_resistance_threshold) or M.DEFAULT_HIGH_RESISTANCE_THRESHOLD
    self.micro_bar_mode           = s.micro_bar_mode or M.DEFAULT_MICRO_BAR_MODE
    self.bar_vertical_offset      = tonumber(s.bar_vertical_offset) or M.DEFAULT_BAR_VERTICAL_OFFSET
    self.fov_scale_indoor         = tonumber(s.fov_scale_indoor) or M.DEFAULT_FOV_SCALE_INDOOR
    self.fov_scale_outdoor        = tonumber(s.fov_scale_outdoor) or M.DEFAULT_FOV_SCALE_OUTDOOR

    self.base_height           = tonumber(s.base_height) or M.DEFAULT_BASE_HEIGHT
    self.left_cap_width        = tonumber(s.left_cap_width) or M.DEFAULT_LEFT_CAP_WIDTH
    self.right_cap_width       = tonumber(s.right_cap_width) or M.DEFAULT_RIGHT_CAP_WIDTH
    self.fill_height           = tonumber(s.fill_height) or M.DEFAULT_FILL_HEIGHT
    self.boss_icon_base_size   = tonumber(s.boss_icon_base_size) or M.DEFAULT_BOSS_ICON_BASE_SIZE
    self.debuff_icon_base_size = tonumber(s.debuff_icon_base_size) or M.DEFAULT_DEBUFF_ICON_BASE_SIZE
    self.close_range_threshold = tonumber(s.close_range_threshold) or M.DEFAULT_CLOSE_RANGE_THRESHOLD
    self.shorten_number_digits = tonumber(s.shorten_number_digits) or M.DEFAULT_SHORTEN_NUMBER_DIGITS
    self.ui_theme              = s.ui_theme or M.DEFAULT_UI_THEME

    if type(s.resistance_colors) == "table" then
        for elem, col in pairs(s.resistance_colors) do
            if type(col) == "table" and #col >= 3 then
                self.resistance_colors[elem] = { col[1], col[2], col[3], col[4] or 255 }
            end
        end
    end

    -- Resolution handling
    local res = tostring(s.screen_resolution or M.DEFAULT_RESOLUTION)
    local rw, rh = res:match("^(%d+)x(%d+)$")
    if rw and rh then
        self.screen_width = tonumber(rw)
        self.screen_height = tonumber(rh)
    else
        self.screen_width = gdi.user32.GetSystemMetrics(0)
        self.screen_height = gdi.user32.GetSystemMetrics(1)
    end
    if self.win then
        self.win:resize(self.screen_width, self.screen_height)
    end

    if prev_theme ~= self.ui_theme then
        self:load_ui_images()
    end
    self:clear_caches()
end

function OverlayApp:resolve_ui_image_path(filename)
    if self.ui_theme and self.ui_theme ~= M.DEFAULT_UI_THEME then
        local themed_ui = M.THEMES_DIR .. "\\" .. self.ui_theme .. "\\UI\\" .. filename
        if file_exists(themed_ui) then return themed_ui end
        local themed = M.THEMES_DIR .. "\\" .. self.ui_theme .. "\\" .. filename
        if file_exists(themed) then return themed end
    end
    return M.UI_FOLDER .. "\\" .. filename
end

function OverlayApp:find_theme_subdir(category_name)
    if not self.ui_theme or self.ui_theme == M.DEFAULT_UI_THEME then
        return nil
    end
    local theme_dir = M.THEMES_DIR .. "\\" .. self.ui_theme
    local subdirs = gdi.list_dir(theme_dir, true)
    if #subdirs == 0 then return nil end

    local cat_clean = norm_icon_key(category_name)
    local shorthand = cat_clean:gsub("icons$", "")
    for _, entry in ipairs(subdirs) do
        if entry == category_name then
            return theme_dir .. "\\" .. entry
        end
    end
    for _, entry in ipairs(subdirs) do
        local entry_clean = norm_icon_key(entry)
        if entry_clean == cat_clean or (shorthand ~= "" and entry_clean == shorthand) then
            return theme_dir .. "\\" .. entry
        end
    end
    return nil
end

function OverlayApp:build_icon_path_map(subfolder_name, default_dir)
    local exact = {}
    local norm = {}

    local function scan_dir(dir_path)
        if not dir_path then return end
        local files = gdi.list_dir(dir_path, false)
        for _, fname in ipairs(files) do
            local low = fname:lower()
            if (low:match("%.png$") or low:match("%.jpg$"))
               and fname:sub(1, 1) ~= "_"
               and low ~= "all.png" then
                local stem = fname:gsub("%.[pP][nN][gG]$", ""):gsub("%.[jJ][pP][gG]$", "")
                local full_p = dir_path .. "\\" .. fname
                exact[stem] = full_p
                exact[stem:lower()] = full_p
                norm[norm_icon_key(stem)] = full_p
            end
        end
    end

    -- 1. Base default icon directory
    scan_dir(default_dir)

    -- 2. Theme override directory (overwrites matching keys)
    local t_sub = self:find_theme_subdir(subfolder_name)
    if t_sub then
        scan_dir(t_sub)
    end

    return { exact = exact, norm = norm }
end

function OverlayApp:load_ui_images()
    self:clear_raw_icon_bitmaps()

    local function load_ui(name)
        local p = self:resolve_ui_image_path(name)
        return gdi.load_bitmap(p)
    end

    self.bg_bmp         = load_ui("background.png")
    self.left_cap_bmp   = load_ui("left_cap.png")
    self.right_cap_bmp  = load_ui("right_cap.png")
    self.fill_a_bmp     = load_ui("fill_A.png") or load_ui("fill _A.png") or load_ui("fill.png")
    self.fill_bmp       = self.fill_a_bmp
    self.fill_boss_bmp  = load_ui("fill_boss.png") or self.fill_a_bmp
    self.fill_hit_bmp   = load_ui("fill_hit.png") or self.fill_a_bmp
    self.fill_crit_bmp  = load_ui("fill_crit.png") or self.fill_hit_bmp
    self.fill_b_bmp     = load_ui("fill_B.png") or self.fill_a_bmp
    self.kill_skull_bmp = load_ui("kill_skull.png")
    self.dr_mind_bmp    = load_ui("dr_mind.png")
    self.dr_stun_bmp    = load_ui("dr_stun.png")

    -- Build theme-aware path maps for boss, debuff, attack, and spell icons
    self.boss_icon_paths   = self:build_icon_path_map("boss icons", M.BOSS_ICONS_DIR)
    self.debuff_icon_paths = self:build_icon_path_map("debuff icons", M.DEBUFF_ICONS_DIR)
    self.attack_icon_paths = self:build_icon_path_map("attack icons", M.ATTACK_ICONS_DIR)
    self.spell_icon_paths  = self:build_icon_path_map("spell icons", M.SPELL_ICONS_DIR)

    self.current_loaded_theme = self.ui_theme
end

function OverlayApp:render_text_cached(text, font_size, text_rgba, outline_w, outline_rgba, bold)
    font_size = math.max(6, round(font_size))
    outline_w = math.max(0, round(outline_w or self.text_outline_width))
    local tc = text_rgba or self.text_color
    local oc = outline_rgba or self.text_outline_color
    local font_path = M.FONTS_DIR .. "\\" .. (self.font_file or M.DEFAULT_FONT_FILE)

    local key = string.format("%s|%s|%d|%d,%d,%d,%d|%d|%d,%d,%d,%d|%s",
        text, self.font_file, font_size,
        tc[1], tc[2], tc[3], tc[4] or 255,
        outline_w,
        oc[1], oc[2], oc[3], oc[4] or 255,
        bold and "B" or "R"
    )
    local cached = self.text_cache[key]
    if cached then return cached end

    if self.text_cache_count > 600 then
        self:clear_caches()
    end

    local surf = gdi.render_text_surface(text, font_path, font_size, tc, outline_w, oc, bold)
    if surf then
        self.text_cache[key] = surf
        self.text_cache_count = self.text_cache_count + 1
    end
    return surf
end

function OverlayApp:shorten_number(num, digits)
    num = tonumber(num) or 0
    digits = tonumber(digits) or self.shorten_number_digits or 4
    local abs_n = math.abs(num)
    local threshold = math.pow(10, digits)
    if abs_n < threshold then
        return tostring(math.floor(num + 0.5))
    end
    local suffixes = {
        { 1e12, "T" },
        { 1e9,  "B" },
        { 1e6,  "M" },
        { 1e3,  "K" },
    }
    for _, s in ipairs(suffixes) do
        if abs_n >= s[1] then
            local val = num / s[1]
            if math.abs(val) >= 100 then
                return string.format("%.0f%s", val, s[2])
            elseif math.abs(val) >= 10 then
                return string.format("%.1f%s", val, s[2]):gsub("%.0([KMGT])$", "%1")
            else
                return string.format("%.2f%s", val, s[2]):gsub("0([KMGT])$", "%1"):gsub("%.([KMGT])$", "%1")
            end
        end
    end
    return tostring(math.floor(num + 0.5))
end

function OverlayApp:get_scale(distance)
    distance = tonumber(distance) or 1000
    if distance <= 1000 then
        return 1.2
    end
    if distance >= 5000 then
        return 0.6
    end
    local t = (distance - 1000) / (5000 - 1000)
    return 1.2 + t * (0.6 - 1.2)
end

function OverlayApp:calculate_bar_width(full_hp, scale)
    return math.max(20, round(200 * scale))
end

function OverlayApp:get_distance_y_offset(distance)
    local d = math.max(0, tonumber(distance) or 1500)
    return (750.0 * (d - 1500.0)) / (13.0 * d + 6000.0)
end

function OverlayApp:get_monster_y_offset(monster)
    if monster and monster.SpriteTop then
        return round(tonumber(self.bar_vertical_offset) or 0)
    end
    local id = monster and tonumber(monster.Id or monster.MonsterId)
    local base_offset = (id and M.MONSTER_DEFAULT_Y_OFFSETS[id]) or 0
    local dist_offset = (monster and monster.Distance ~= nil) and self:get_distance_y_offset(monster.Distance) or 0
    return round(base_offset + dist_offset + (tonumber(self.bar_vertical_offset) or 0))
end

function OverlayApp:get_boss_prefix(name, mon_id)
    if not name or name == "" then return nil end
    if tonumber(mon_id) == 560 and name:lower() == "venomous hydra" then
        return nil
    end
    for _, prefix in ipairs(M.BOSS_PREFIXES) do
        if name:sub(1, #prefix + 1):lower() == (prefix:lower() .. " ") then
            return prefix
        end
    end
    return nil
end

function OverlayApp:get_boss_bitmap(prefix)
    if not prefix then return nil end
    local icon_key = (M.BOSS_ICON_ALIASES and M.BOSS_ICON_ALIASES[prefix]) or prefix
    local key = icon_key:lower()
    if self.boss_raw_bitmaps[key] ~= nil then
        return self.boss_raw_bitmaps[key] or nil
    end

    local map = self.boss_icon_paths or self:build_icon_path_map("boss icons", M.BOSS_ICONS_DIR)
    self.boss_icon_paths = map

    local p = map.exact[icon_key]
        or map.exact[key]
        or map.norm[norm_icon_key(icon_key)]
        or map.exact[prefix]
        or map.norm[norm_icon_key(prefix)]
        or map.exact["default_boss"]
        or map.exact["boss"]

    if p then
        local bmp = gdi.load_bitmap(p)
        if bmp then
            self.boss_raw_bitmaps[key] = bmp
            return bmp
        end
    end
    self.boss_raw_bitmaps[key] = false
    return nil
end

function OverlayApp:get_attack_or_spell_bitmap(is_spell, icon_name)
    if not icon_name or icon_name == "" or icon_name == "None" then return nil end
    local cache = is_spell and self.spell_raw_bitmaps or self.attack_raw_bitmaps
    local key = icon_name:lower()
    if cache[key] ~= nil then return cache[key] or nil end

    local map
    local aliases
    if is_spell then
        map = self.spell_icon_paths or self:build_icon_path_map("spell icons", M.SPELL_ICONS_DIR)
        self.spell_icon_paths = map
        aliases = M.SPELL_ICON_ALIASES
    else
        map = self.attack_icon_paths or self:build_icon_path_map("attack icons", M.ATTACK_ICONS_DIR)
        self.attack_icon_paths = map
        aliases = M.ATTACK_ICON_ALIASES
    end

    local name_clean = icon_name:gsub("%.[pP][nN][gG]$", ""):gsub("%.[jJ][pP][gG]$", "")
    local nk = norm_icon_key(name_clean)
    local alias = aliases and aliases[nk] or nil

    local p = map.exact[name_clean]
        or map.exact[name_clean:lower()]
        or map.norm[nk]
        or (alias and (map.norm[alias] or map.exact[alias]))

    if p then
        local bmp = gdi.load_bitmap(p)
        if bmp then
            cache[key] = bmp
            return bmp
        end
    end
    cache[key] = false
    return nil
end

function OverlayApp:get_debuff_raw_bitmap(filename)
    if not filename or filename == "" then return nil end
    if self.debuff_raw_bitmaps[filename] ~= nil then
        return self.debuff_raw_bitmaps[filename] or nil
    end

    local map = self.debuff_icon_paths or self:build_icon_path_map("debuff icons", M.DEBUFF_ICONS_DIR)
    self.debuff_icon_paths = map

    local stem = filename:gsub("%.[pP][nN][gG]$", ""):gsub("%.[jJ][pP][gG]$", "")
    local nk = norm_icon_key(stem)
    local p = map.exact[stem]
        or map.exact[stem:lower()]
        or map.norm[nk]

    local bmp = p and gdi.load_bitmap(p) or nil
    self.debuff_raw_bitmaps[filename] = bmp or false
    return bmp
end

-- ============================================================================
-- 3-Tier Resistance Crystal Pip Builder (with pip-colored lighter aura glow)
-- ============================================================================
function OverlayApp:get_res_pip_surface(elem_key, color_rgb, pip_w, pip_h, tier, pulse_bucket)
    pip_w = math.max(5, round(pip_w))
    pip_h = math.max(5, round(pip_h))
    tier = tier or 1
    pulse_bucket = (tier >= 3) and (pulse_bucket or 4) or 0

    local key = string.format("%s|%d,%d,%d|%d|%d|%d|%d",
        elem_key, color_rgb[1], color_rgb[2], color_rgb[3],
        pip_w, pip_h, tier, pulse_bucket
    )
    local cached = self.res_pip_cache[key]
    if cached then return cached end

    if self.res_pip_cache_count > 400 then
        for _, s in pairs(self.res_pip_cache) do if s.dispose then s:dispose() end end
        self.res_pip_cache = {}
        self.res_pip_cache_count = 0
    end

    local crown_h = (tier >= 2) and math.max(3, round(pip_h * 0.45)) or 0
    local glow_pad = (tier >= 3) and math.max(4, round(math.max(pip_w, pip_h) * 0.55)) or 1
    local total_w = pip_w + glow_pad * 2
    local total_h = pip_h + crown_h + glow_pad * 2

    local surf = gdi.create_surface(total_w, total_h, false)
    if not surf then return nil end

    local ox = glow_pad
    local oy = glow_pad + crown_h
    local cx = ox + pip_w / 2.0
    local cy = oy + pip_h / 2.0
    local hw = pip_w / 2.0
    local hh = pip_h / 2.0

    -- 1. Tier 3 Pulsating Aura (same color as pip, slightly lighter!)
    if tier >= 3 then
        local pulse = pulse_bucket / 8.0
        local aura_rgb = blend_white(color_rgb, 0.30)
        local ray_rgb  = blend_white(color_rgb, 0.45)

        local outer_a = round(55 + 65 * pulse)
        local inner_a = round(95 + 75 * pulse)
        local rx_out = hw + glow_pad * (0.65 + 0.30 * pulse)
        local ry_out = hh + glow_pad * (0.65 + 0.30 * pulse)
        surf:fill_ellipse(cx - rx_out, cy - ry_out, rx_out * 2, ry_out * 2, outer_a, aura_rgb[1], aura_rgb[2], aura_rgb[3])

        local rx_in = hw + glow_pad * 0.38
        local ry_in = hh + glow_pad * 0.38
        surf:fill_ellipse(cx - rx_in, cy - ry_in, rx_in * 2, ry_in * 2, inner_a, aura_rgb[1], aura_rgb[2], aura_rgb[3])

        local ray_len = glow_pad * (0.75 + 0.25 * pulse)
        local ray_a = round(140 + 85 * pulse)
        surf:draw_line(cx - hw - ray_len * 0.5, cy, cx + hw + ray_len * 0.5, cy, 1.2, ray_a, ray_rgb[1], ray_rgb[2], ray_rgb[3])
        surf:draw_line(cx, cy - hh - ray_len * 0.5, cx, cy + hh + ray_len * 0.5, 1.2, ray_a, ray_rgb[1], ray_rgb[2], ray_rgb[3])
    end

    -- 2. Outer Diamond Bezel (Gold for Tier 2+, Metallic Silver-Gold for Tier 1)
    local diamond_outer = {
        { cx, oy },
        { ox + pip_w, cy },
        { cx, oy + pip_h },
        { ox, cy },
    }
    if tier >= 2 then
        surf:fill_polygon(diamond_outer, 255, 255, 215, 65)
    else
        surf:fill_polygon(diamond_outer, 240, 175, 160, 120)
    end

    -- 3. Dark Recess Inside Bezel
    local inset1 = math.max(1.0, math.min(pip_w, pip_h) * 0.14)
    local diamond_dark = {
        { cx, oy + inset1 },
        { ox + pip_w - inset1, cy },
        { cx, oy + pip_h - inset1 },
        { ox + inset1, cy },
    }
    surf:fill_polygon(diamond_dark, 255, 18, 20, 24)

    -- 4. Inner Colored Gem Body
    local inset2 = math.max(1.8, math.min(pip_w, pip_h) * 0.24)
    local diamond_gem = {
        { cx, oy + inset2 },
        { ox + pip_w - inset2, cy },
        { cx, oy + pip_h - inset2 },
        { ox + inset2, cy },
    }
    surf:fill_polygon(diamond_gem, 255, color_rgb[1], color_rgb[2], color_rgb[3])

    -- 5. Top-Left Specular Facet Highlight
    local hi_rgb = blend_white(color_rgb, 0.55)
    local facet_top = {
        { cx, oy + inset2 },
        { (cx + ox + pip_w - inset2) * 0.5, (oy + inset2 + cy) * 0.5 },
        { cx, cy },
        { (cx + ox + inset2) * 0.5, (oy + inset2 + cy) * 0.5 },
    }
    surf:fill_polygon(facet_top, 210, hi_rgb[1], hi_rgb[2], hi_rgb[3])

    -- 6. Tier 2+ Royal 3-Point Gold Crown Above Gem
    if tier >= 2 and crown_h >= 3 then
        local cb_y = oy + 1
        local ct_y = oy - crown_h + 1
        local cw_half = math.max(2.5, hw * 0.78)
        local crown_pts = {
            { cx - cw_half, cb_y },
            { cx - cw_half * 0.85, ct_y + crown_h * 0.25 },
            { cx - cw_half * 0.38, cb_y - crown_h * 0.35 },
            { cx, ct_y },
            { cx + cw_half * 0.38, cb_y - crown_h * 0.35 },
            { cx + cw_half * 0.85, ct_y + crown_h * 0.25 },
            { cx + cw_half, cb_y },
        }
        surf:fill_polygon(crown_pts, 255, 255, 215, 55)
        surf:draw_polygon(crown_pts, 1.0, 230, 60, 40, 10)
    end

    self.res_pip_cache[key] = surf
    self.res_pip_cache_count = self.res_pip_cache_count + 1
    return surf
end

-- ============================================================================
-- Debuff & CC Diminishing Returns Icon Builders
-- ============================================================================
function OverlayApp:get_debuff_icon_surface(def, size, rem_ratio, stacks)
    size = math.max(10, round(size))
    local raw_bmp = self:get_debuff_raw_bitmap(def.file)
    if not raw_bmp then return nil end

    local ratio_step = 0
    if self.show_debuff_timers and rem_ratio and rem_ratio > 0 and rem_ratio < 0.995 then
        ratio_step = clamp(round(rem_ratio * 36), 1, 35)
    end
    local disp_stacks = (self.show_debuff_stacks and stacks and stacks > 1) and stacks or 0

    local key = string.format("debuff|%s|%d|%d|%d", def.key, size, ratio_step, disp_stacks)
    local cached = self.debuff_icon_cache[key]
    if cached then return cached end

    local surf = gdi.create_surface(size, size, false)
    if not surf then return nil end

    -- Dark backing + icon
    surf:fill_rect(0, 0, size, size, 210, 12, 14, 18)
    surf:draw_image(raw_bmp, 1, 1, size - 2, size - 2, 255)

    -- Radial clockwise elapsed sweep
    if ratio_step > 0 then
        local elapsed_frac = 1.0 - (ratio_step / 36.0)
        local sweep_deg = elapsed_frac * 360.0
        local pad = size * 0.45
        surf:fill_pie(-pad, -pad, size + pad * 2, size + pad * 2, -90.0, sweep_deg, 165, 0, 0, 0)
    end

    -- Crisp dark-gold border
    surf:draw_rect(0, 0, size - 1, size - 1, 1.0, 220, 90, 80, 65)

    -- Stack count badge in bottom-right
    if disp_stacks > 1 then
        local st_font = math.max(8, round(size * 0.52))
        local txt_s = self:render_text_cached(tostring(disp_stacks), st_font, { 255, 235, 80, 255 }, 1, { 0, 0, 0, 255 }, true)
        if txt_s then
            surf:draw_image(txt_s, size - txt_s.w + 1, size - txt_s.h + 1, txt_s.w, txt_s.h, 255)
        end
    end

    self.debuff_icon_cache[key] = surf
    return surf
end

function OverlayApp:get_cc_dr_icon_surface(cat_name, def, dr_entry, size)
    size = math.max(10, round(size))
    local raw_bmp = (cat_name == "Mind") and self.dr_mind_bmp or self.dr_stun_bmp
    if not raw_bmp then
        raw_bmp = self:get_debuff_raw_bitmap((cat_name == "Mind") and "Charm.png" or "Paralyze.png")
    end
    if not raw_bmp then return nil end

    local is_immune = (type(dr_entry) == "table" and dr_entry.Immune) and true or false
    local tier_val = is_immune and 4 or clamp(round(tonumber(dr_entry and (dr_entry.Tier or dr_entry.stacks)) or 1), 1, 4)

    local ratio = 1.0
    if type(dr_entry) == "table" then
        if dr_entry.Ratio ~= nil then
            ratio = clamp(tonumber(dr_entry.Ratio) or 1.0, 0.0, 1.0)
        else
            local rem_time = tonumber(dr_entry.rem or dr_entry.Remaining) or 0
            ratio = clamp(rem_time / ((def and def.window) or 20.0), 0.0, 1.0)
        end
    end

    local ratio_step = 0
    if self.show_debuff_timers and ratio < 0.995 then
        ratio_step = clamp(round(ratio * 36), 1, 35)
    end

    local key = string.format("ccdr|%s|%d|%d|%d|%s", cat_name, size, tier_val, ratio_step, is_immune and "I" or "N")
    local cached = self.debuff_icon_cache[key]
    if cached then return cached end

    local surf = gdi.create_surface(size, size, false)
    if not surf then return nil end

    surf:fill_rect(0, 0, size, size, 240, 18, 20, 26)
    surf:draw_image(raw_bmp, 1, 1, size - 2, size - 2, 255)

    if ratio_step > 0 then
        local elapsed_frac = 1.0 - (ratio_step / 36.0)
        local pad = size * 0.45
        surf:fill_pie(-pad, -pad, size + pad * 2, size + pad * 2, -90.0, elapsed_frac * 360.0, 145, 0, 0, 0)
    end

    local border_col
    if tier_val == 1 then
        border_col = { 255, 215, 0, 240 }
    elseif tier_val == 2 then
        border_col = { 255, 140, 0, 240 }
    elseif tier_val == 3 then
        border_col = { 255, 45, 45, 240 }
    else
        border_col = { 230, 30, 30, 255 }
        local lpad = math.max(2, round(size * 0.14))
        local lw = math.max(2.0, round(size * 0.15))
        surf:draw_line(lpad, lpad, size - 1 - lpad, size - 1 - lpad, lw + 1.5, 220, 0, 0, 0)
        surf:draw_line(lpad, lpad, size - 1 - lpad, size - 1 - lpad, lw, 255, 255, 35, 35)
    end

    surf:draw_rect(0, 0, size - 1, size - 1, math.max(1.5, round(size * 0.09)), border_col[4] or 240, border_col[1], border_col[2], border_col[3])

    self.debuff_icon_cache[key] = surf
    return surf
end

-- ============================================================================
-- Core Bar Drawing (Used by both Live Overlay and Settings Preview!)
-- Matches _Python Overlay/MAW_Overlay.py draw_bar 1:1
-- ============================================================================
function OverlayApp:draw_bar(monster, vis, opts)
    opts = opts or {}
    local surface = opts.frame or (self.win and self.win.surface)
    if not surface then return nil end

    local hp = math.max(0, tonumber(monster.HP) or 0)
    local full_hp = math.max(1, tonumber(monster.FullHP) or 1)
    local hp_ratio = clamp(hp / full_hp, 0.0, 1.0)
    local dist = tonumber(monster.Distance) or 1000
    local size_mult = tonumber(opts.size_mult) or 1.0
    local scale = self:get_scale(dist) * size_mult

    local name = tostring(monster.Name or "Monster")
    local is_ally = monster.IsAlly and true or false
    local boss_prefix = (not is_ally) and self:get_boss_prefix(name, monster.Id) or nil
    local is_boss = (boss_prefix ~= nil)

    local anim_t = clamp(tonumber(opts.anim_t) or 1.0, 0.0, 1.0)

    local full_bw = math.max(20, round((tonumber(monster.BarSize) or 200) * scale * (is_boss and 1.2 or 1.0)))
    local micro_bw = math.max(20, round(68 * scale))
    local bar_w = round(micro_bw + (full_bw - micro_bw) * anim_t)

    local full_bh = math.max(4, round(self.base_height * scale))
    local micro_bh = math.max(3, round(self.base_height * 0.45 * scale))
    local bar_h = round(micro_bh + (full_bh - micro_bh) * anim_t)

    local full_fh = math.max(2, round(self.fill_height * scale))
    local micro_fh = math.max(2, round(self.fill_height * 0.45 * scale))
    local fill_h = round(micro_fh + (full_fh - micro_fh) * anim_t)

    local lcap_w = math.max(0, round(self.left_cap_width * scale * (0.4 + 0.6 * anim_t)))
    local rcap_w = math.max(0, round(self.right_cap_width * scale * (0.4 + 0.6 * anim_t)))

    local cx = tonumber(opts.override_x) or tonumber(monster.ScreenX) or (surface.w / 2)
    local cy = tonumber(opts.override_y) or ((tonumber(monster.ScreenY) or (surface.h / 2)) + self:get_monster_y_offset(monster))
    local x0 = round(cx - bar_w / 2)
    local y0 = round(cy - bar_h)

    local text_top_y = y0 - 4

    local bar_opacity = clamp(round(tonumber(opts.bar_opacity) or 255), 0, 255)
    if bar_opacity <= 0 then
        return { cx = cx, top_y = text_top_y, scale = scale }
    end

    -- 1. Ambient soft drop shadow & Target Highlight Border
    surface:fill_rect(x0 - 2, y0 - 1, bar_w + 4, bar_h + 3, round(115 * (bar_opacity / 255.0)), 0, 0, 0)
    if opts.is_highlighted then
        surface:draw_rect(x0 - 2, y0 - 2, bar_w + 3, bar_h + 3, 2.0, bar_opacity, 255, 255, 255)
    end

    -- 2. Background & End Caps
    if self.bg_bmp then
        surface:draw_image(self.bg_bmp, x0, y0, bar_w, bar_h, bar_opacity)
    else
        surface:fill_rect(x0, y0, bar_w, bar_h, round(bar_opacity * 0.8), 20, 24, 28)
    end
    if lcap_w > 0 and self.left_cap_bmp then
        surface:draw_image(self.left_cap_bmp, x0, y0, lcap_w, bar_h, bar_opacity)
    end
    if rcap_w > 0 and self.right_cap_bmp then
        surface:draw_image(self.right_cap_bmp, x0 + bar_w - rcap_w, y0, rcap_w, bar_h, bar_opacity)
    end

    -- 3. Inner Fill Area & Animated Damage Drain Bar
    local fill_max_w = math.max(1, bar_w - lcap_w - rcap_w)
    local fill_x = x0 + lcap_w
    local fill_y = y0 + math.floor((bar_h - fill_h) / 2)

    local drain_ratio = tonumber(opts.drain_ratio)
    if drain_ratio and drain_ratio > hp_ratio + 0.002 then
        local drain_w = round(fill_max_w * clamp(drain_ratio, 0.0, 1.0))
        local drain_bmp = opts.drain_is_crit and self.fill_crit_bmp or self.fill_hit_bmp
        if drain_w > 0 and drain_bmp then
            surface:draw_image(drain_bmp, fill_x, fill_y, drain_w, fill_h, bar_opacity)
        end
    end

    -- Active HP Fill
    local cur_fill_w = round(fill_max_w * hp_ratio)
    if cur_fill_w > 0 then
        local active_fill = self.fill_a_bmp or self.fill_bmp
        if is_ally and self.fill_b_bmp then
            active_fill = self.fill_b_bmp
        elseif is_boss and self.fill_boss_bmp then
            active_fill = self.fill_boss_bmp
        end

        if active_fill then
            surface:draw_image(active_fill, fill_x, fill_y, cur_fill_w, fill_h, bar_opacity)
        else
            surface:fill_rect(fill_x, fill_y, cur_fill_w, fill_h, bar_opacity, 180, 35, 35)
        end
    end

    -- 4. Left Flank: Boss Icon (scales between micro and full)
    if is_boss and self.show_boss_icons then
        local boss_bmp = self:get_boss_bitmap(boss_prefix)
        if boss_bmp then
            local full_isize = math.max(12, round(self.boss_icon_base_size * scale))
            local micro_isize = math.max(8, round(12 * scale))
            local bsize = round(micro_isize + (full_isize - micro_isize) * anim_t)
            local bx = x0 - 3 - bsize
            local by = round(y0 + bar_h / 2 - bsize / 2)
            surface:draw_image(boss_bmp, bx, by, bsize, bsize, bar_opacity)
        end
    end

    -- Detail elements (Attack/Spell icons, Name/HP/Level text, Resistance Pips) fade in when anim_t > 0.05
    if anim_t > 0.05 then
        local detail_alpha = clamp(round(bar_opacity * anim_t), 0, 255)

        -- 5. Right Flank: Attack & Spell Icons
        if self.show_attack_spell_icons and vis and vis.attack then
            local icon_sz = math.max(10, round(self.debuff_icon_base_size * scale))
            local icon_pad = math.max(2, round(3 * scale))
            local ix = x0 + bar_w + 5
            local iy = round(y0 + bar_h / 2 - icon_sz / 2)
            local step_x = icon_sz + icon_pad

            if type(monster.AttackTypes) == "table" then
                for _, atk_name in ipairs(monster.AttackTypes) do
                    local atk_bmp = self:get_attack_or_spell_bitmap(false, atk_name)
                    if atk_bmp then
                        surface:draw_image(atk_bmp, ix, iy, icon_sz, icon_sz, detail_alpha)
                        ix = ix + step_x
                    end
                end
            elseif monster.Attack1Element then
                local atk_bmp = self:get_attack_or_spell_bitmap(false, monster.Attack1Element)
                if atk_bmp then
                    surface:draw_image(atk_bmp, ix, iy, icon_sz, icon_sz, detail_alpha)
                    ix = ix + step_x
                end
            end

            if type(monster.Spells) == "table" then
                for _, sp_name in ipairs(monster.Spells) do
                    local sp_bmp = self:get_attack_or_spell_bitmap(true, sp_name)
                    if sp_bmp then
                        surface:draw_image(sp_bmp, ix, iy, icon_sz, icon_sz, detail_alpha)
                        ix = ix + step_x
                    end
                end
            elseif monster.Spell1Icon then
                local sp_bmp = self:get_attack_or_spell_bitmap(true, monster.Spell1Icon)
                if sp_bmp then
                    surface:draw_image(sp_bmp, ix, iy, icon_sz, icon_sz, detail_alpha)
                end
            end
        end

        -- 6. Above Bar: 3-Tier Resistance Crystal Pips & Unified Monster Name + HP + Level Text
        local active_pips = {}
        if self.show_resistance_pips and vis and vis.resistances and type(monster.Resistances) == "table" then
            local thresh = tonumber(self.high_resistance_threshold) or 50
            if monster.Resistances[1] and type(monster.Resistances[1]) == "table" then
                local by_name = {}
                for _, r_entry in ipairs(monster.Resistances) do
                    if r_entry.Name then by_name[r_entry.Name] = r_entry end
                end
                for _, el in ipairs(M.RESISTANCE_ELEMENTS) do
                    local key = el[1]
                    local r_entry = by_name[key]
                    if r_entry then
                        local val = tonumber(r_entry.Value) or 0
                        local tier = tonumber(r_entry.Tier)
                        if not tier then
                            if val >= 200 then tier = 3
                            elseif val >= 100 then tier = 2
                            elseif val >= thresh then tier = 1
                            else tier = 0 end
                        end
                        if tier >= 1 then
                            active_pips[#active_pips + 1] = {
                                key = key,
                                tier = tier,
                                color = self.resistance_colors[key] or M.DEFAULT_RESISTANCE_COLORS[key] or { 200, 200, 200, 255 }
                            }
                        end
                    end
                end
            else
                for _, el in ipairs(M.RESISTANCE_ELEMENTS) do
                    local key = el[1]
                    local val = tonumber(monster.Resistances[key]) or 0
                    local tier = 0
                    if val >= 200 then tier = 3
                    elseif val >= 100 then tier = 2
                    elseif val >= thresh then tier = 1 end
                    if tier >= 1 then
                        active_pips[#active_pips + 1] = {
                            key = key,
                            tier = tier,
                            color = self.resistance_colors[key] or M.DEFAULT_RESISTANCE_COLORS[key]
                        }
                    end
                end
            end
        end

        local has_t2_or_t3 = false
        for _, p in ipairs(active_pips) do
            if p.tier >= 2 then has_t2_or_t3 = true break end
        end
        local pip_w = math.max(6, round((has_t2_or_t3 and 8 or 7) * scale))
        local pip_h = math.max(10, round((has_t2_or_t3 and 15 or 13) * scale))
        local pip_gap_x = math.max(8, round((has_t2_or_t3 and 11 or 9) * scale))
        local pip_gap_y = math.max(3, round(4 * scale))

        local text_y
        if #active_pips > 0 then
            local pip_cy = y0 - pip_gap_y - math.floor(pip_h / 2)
            text_y = y0 - pip_h - pip_gap_y - math.max(3, round(4 * scale))

            local total_pips_w = #active_pips * pip_w + (#active_pips - 1) * pip_gap_x
            local start_px = cx - total_pips_w / 2.0 + pip_w / 2.0
            local now_t = tonumber(opts.now) or gdi.now()
            local pulse_bucket = round(((math.sin(now_t * 5.0) + 1.0) * 0.5) * 8)

            for i, p in ipairs(active_pips) do
                local psurf = self:get_res_pip_surface(p.key, p.color, pip_w, pip_h, p.tier, pulse_bucket)
                if psurf then
                    local px_center = start_px + (i - 1) * (pip_w + pip_gap_x)
                    surface:draw_image(psurf, px_center, pip_cy, psurf.w, psurf.h, detail_alpha, "center")
                end
            end
        else
            text_y = y0 - 4
        end

        -- Render Unified Monster Name + HP Numbers + Level ABOVE the HP bar (and above any pips)
        local parts = {}
        if self.show_name_text and vis and vis.name and name ~= "" then
            parts[#parts + 1] = name
        end
        if self.show_hp_numbers and vis and vis.hp_nums then
            parts[#parts + 1] = self:shorten_number(hp) .. "/" .. self:shorten_number(full_hp)
        end
        if self.show_monster_level and vis and vis.level and monster.Level and tonumber(monster.Level) and tonumber(monster.Level) > 0 then
            parts[#parts + 1] = "Lv." .. tostring(math.floor(tonumber(monster.Level) + 0.5))
        end

        if #parts > 0 then
            local main_text = table.concat(parts, " ")
            local fsize = math.max(8, round(self.font_size * size_mult))
            local ow = (self.text_outline_width > 0) and math.max(0, round(self.text_outline_width * size_mult)) or 0
            local txt_surf = self:render_text_cached(main_text, fsize, self.text_color, ow, self.text_outline_color, true)
            if txt_surf then
                local tx = round(cx - txt_surf.w / 2)
                local ty = round(text_y - txt_surf.h + 3)
                surface:draw_image(txt_surf, tx, ty, txt_surf.w, txt_surf.h, detail_alpha)
                text_top_y = ty
            else
                text_top_y = text_y
            end
        else
            text_top_y = text_y
        end
    end

    -- 7. Below Bar: Active Debuff Icons & Flanking CC Diminishing Returns
    local full_dsize = math.max(8, round(self.debuff_icon_base_size * scale))
    local micro_dsize = math.max(7, round(11 * scale))
    local debuff_sz = round(micro_dsize + (full_dsize - micro_dsize) * anim_t)
    local debuff_Gap = math.max(1, round(3 * scale * (0.6 + 0.4 * anim_t)))
    local debuff_y = y0 + bar_h + math.max(2, round(3 * anim_t))
    local active_debuffs = {}

    if self.show_debuff_icons and type(monster.Debuffs) == "table" then
        if monster.Debuffs[1] ~= nil then
            for _, d_item in ipairs(monster.Debuffs) do
                local dname = (type(d_item) == "table") and tostring(d_item.Name or "") or tostring(d_item or "")
                local file_name = dname .. ".png"
                for _, ddef in ipairs(M.DEBUFF_DEFS) do
                    if ddef.key:lower() == dname:lower() then
                        file_name = ddef.file
                        break
                    end
                end
                if self:get_debuff_raw_bitmap(file_name) then
                    active_debuffs[#active_debuffs + 1] = {
                        def = { key = dname, file = file_name },
                        ratio = (type(d_item) == "table" and d_item.Ratio ~= nil) and clamp(tonumber(d_item.Ratio) or 1.0, 0.0, 1.0) or 1.0,
                        stacks = (type(d_item) == "table" and tonumber(d_item.Stacks)) or 1,
                    }
                end
            end
        else
            local durations = type(monster.DebuffDurations) == "table" and monster.DebuffDurations or {}
            local stacks_tbl = type(monster.DebuffStacks) == "table" and monster.DebuffStacks or {}
            for _, ddef in ipairs(M.DEBUFF_DEFS) do
                local rem = tonumber(monster.Debuffs[ddef.key]) or 0
                if rem > 0 and self:get_debuff_raw_bitmap(ddef.file) then
                    local dur = math.max(rem, tonumber(durations[ddef.key]) or rem)
                    local ratio = (dur > 0) and clamp(rem / dur, 0.0, 1.0) or 1.0
                    local st = tonumber(stacks_tbl[ddef.key]) or 1
                    active_debuffs[#active_debuffs + 1] = {
                        def = ddef,
                        ratio = ratio,
                        stacks = st,
                    }
                end
            end
        end
    end

    local total_debuff_w = (#active_debuffs > 0) and (#active_debuffs * debuff_sz + (#active_debuffs - 1) * debuff_Gap) or 0
    local debuff_start_x = round(cx - total_debuff_w / 2)

    for i, d in ipairs(active_debuffs) do
        local dsurf = self:get_debuff_icon_surface(d.def, debuff_sz, d.ratio, (anim_t > 0.4) and d.stacks or 0)
        if dsurf then
            local dx = debuff_start_x + (i - 1) * (debuff_sz + debuff_Gap)
            surface:draw_image(dsurf, dx, debuff_y, debuff_sz, debuff_sz, bar_opacity)
        end
    end

    -- CC Diminishing Returns flanking icons (Mind anchored at x0, Stun anchored at x0 + bar_w - debuff_sz)
    local dr_tbl = monster.CC_DR or monster.DR
    if self.show_cc_dr_tracker and type(dr_tbl) == "table" then
        local mind_dr = dr_tbl.Mind
        if type(mind_dr) == "table" then
            local st = tonumber(mind_dr.stacks or mind_dr.Tier) or (mind_dr.Immune and 4 or 0)
            local rem = tonumber(mind_dr.rem or mind_dr.Remaining or mind_dr.Ratio) or (mind_dr.Immune and 1 or 0)
            if st > 0 and rem > 0 then
                local msurf = self:get_cc_dr_icon_surface("Mind", M.CC_DR_DEFS.Mind, mind_dr, debuff_sz)
                if msurf then
                    surface:draw_image(msurf, x0, debuff_y, debuff_sz, debuff_sz, bar_opacity)
                end
            end
        end
        local stun_dr = dr_tbl.Stun or dr_tbl.Paralyze
        if type(stun_dr) == "table" then
            local st = tonumber(stun_dr.stacks or stun_dr.Tier) or (stun_dr.Immune and 4 or 0)
            local rem = tonumber(stun_dr.rem or stun_dr.Remaining or stun_dr.Ratio) or (stun_dr.Immune and 1 or 0)
            if st > 0 and rem > 0 then
                local ssurf = self:get_cc_dr_icon_surface("Stun", M.CC_DR_DEFS.Stun, stun_dr, debuff_sz)
                if ssurf then
                    surface:draw_image(ssurf, x0 + bar_w - debuff_sz, debuff_y, debuff_sz, debuff_sz, bar_opacity)
                end
            end
        end
    end

    return { cx = cx, top_y = text_top_y, scale = scale }
end

-- ============================================================================
-- Anti-Overlap, Damage Drain, Floating Damage, Potion Alerts, Splash Screen
-- ============================================================================
function OverlayApp:resolve_world_anti_overlap(monsters, targeted_idx)
    if #monsters <= 1 then return end

    -- Sort front-to-back (closest first, targeted monster prioritized)
    table.sort(monsters, function(a, b)
        local a_t = (a.Index == targeted_idx) and 1 or 0
        local b_t = (b.Index == targeted_idx) and 1 or 0
        if a_t ~= b_t then return a_t > b_t end
        return (tonumber(a.Distance) or 1000) < (tonumber(b.Distance) or 1000)
    end)

    local boxes = {}
    for i, m in ipairs(monsters) do
        local sc = self:get_scale(m.Distance)
        local bw = self:calculate_bar_width(m.FullHP, sc)
        if self:get_boss_prefix(m.Name, m.Id) then bw = round(bw * 1.2) end
        local bh = math.max(10, round((self.base_height + 10) * sc))
        local sx = tonumber(m.ScreenX) or 0
        local sy = (tonumber(m.ScreenY) or 0) + self:get_monster_y_offset(m)
        local ground_y = tonumber(m.GroundY) or (sy + bh * 2.5)
        boxes[i] = {
            m = m,
            x = sx,
            y = sy,
            orig_y = sy,
            w = bw + 12,
            h = bh + 6,
            min_y = sy - 140 * sc,
            max_y = math.max(sy, ground_y),
        }
    end

    -- Pass 1: Push overlapping bars upward
    for i = 2, #boxes do
        local cur = boxes[i]
        for j = 1, i - 1 do
            local prev = boxes[j]
            local dx = math.abs(cur.x - prev.x)
            local min_dx = (cur.w + prev.w) * 0.46
            if dx < min_dx then
                local dy = math.abs(cur.y - prev.y)
                local min_dy = (cur.h + prev.h) * 0.52
                if dy < min_dy then
                    cur.y = math.max(cur.min_y, prev.y - min_dy)
                end
            end
        end
    end

    for _, b in ipairs(boxes) do
        b.m._adjusted_y = clamp(b.y, b.min_y, b.max_y)
    end
end

function OverlayApp:update_damage_drain(monsters, now, dt)
    local drain_info = {}
    local active_indices = {}

    for _, m in ipairs(monsters) do
        local idx = m.Index
        if idx then
            active_indices[idx] = true
            local hp = math.max(0, tonumber(m.HP) or 0)
            local full_hp = math.max(1, tonumber(m.FullHP) or 1)
            local ratio = clamp(hp / full_hp, 0.0, 1.0)
            local st = self.damage_drain_state[idx]
            if not st then
                self.damage_drain_state[idx] = {
                    last_hp_ratio = ratio,
                    drain_ratio = ratio,
                    hold_until = 0,
                    is_crit = false,
                }
            else
                if ratio < st.last_hp_ratio - 0.001 then
                    local drop = st.last_hp_ratio - ratio
                    if st.drain_ratio <= st.last_hp_ratio + 0.005 then
                        st.drain_ratio = st.last_hp_ratio
                    end
                    st.hold_until = now + M.DRAIN_HOLD_DURATION
                    st.is_crit = (drop >= 0.22)
                elseif ratio > st.drain_ratio then
                    st.drain_ratio = ratio
                end
                st.last_hp_ratio = ratio

                if st.drain_ratio > ratio then
                    if now >= st.hold_until then
                        st.drain_ratio = math.max(ratio, st.drain_ratio - M.DRAIN_SPEED_FACTOR * dt * math.max(0.08, st.drain_ratio - ratio))
                    end
                    if st.drain_ratio > ratio + 0.002 then
                        drain_info[idx] = { st.drain_ratio, st.is_crit }
                    end
                end
            end
        end
    end

    return drain_info
end

function OverlayApp:ingest_recent_hits(game_data, now)
    if not self.show_floating_damage or type(game_data) ~= "table" then return end
    local stagger_per_mon = {}

    local function add_hit(hid, midx, dmg, is_crit, sx, sy)
        if hid and not self.seen_hit_ids[hid] and midx and dmg > 0 then
            self.seen_hit_ids[hid] = now
            local cnt = (stagger_per_mon[midx] or 0)
            stagger_per_mon[midx] = cnt + 1
            self.floating_popups[#self.floating_popups + 1] = {
                monster_idx = midx,
                amount = dmg,
                is_crit = is_crit and true or false,
                start_time = now + cnt * 0.07,
                x_jitter = ((tonumber(hid) or 0) % 5 - 2) * 5,
                last_x = tonumber(sx) or (self.screen_width / 2),
                last_y = tonumber(sy) or (self.screen_height / 2),
                scale = 1.0,
            }
        end
    end

    -- Top-level RecentHits (if present)
    if type(game_data.RecentHits) == "table" then
        for _, h in ipairs(game_data.RecentHits) do
            add_hit(h.Id or h.id or h.Seq, h.MonsterIndex or h.Index, tonumber(h.Damage) or 0, h.IsCrit or h.Crit, h.ScreenX, h.ScreenY)
        end
    end

    -- Per-monster RecentHits from __visible_monsters_overlay.lua
    local monsters = game_data.Monsters or (game_data[1] and game_data) or {}
    for _, m in ipairs(monsters) do
        if type(m.RecentHits) == "table" then
            for _, h in ipairs(m.RecentHits) do
                add_hit(h.Seq or h.Id, m.Index, tonumber(h.Damage) or 0, h.Crit or h.IsCrit, m.ScreenX, m.ScreenY)
            end
        end
    end

    -- Prune old seen_hit_ids
    for k, t in pairs(self.seen_hit_ids) do
        if now - t > 10.0 then self.seen_hit_ids[k] = nil end
    end
end

function OverlayApp:damage_color(amount)
    local text = _G.shortenNumber and _G.shortenNumber(amount, 4) or self:shorten_number(amount, 3)
    return M.FLOAT_DMG_SUFFIX_COLORS[text:sub(-1)] or M.FLOAT_DMG_BASE_COLOR
end

function OverlayApp:draw_floating_damage_popups(bar_anchors, now, surface)
    if not self.show_floating_damage or #self.floating_popups == 0 then return end
    local alive = {}
    for _, p in ipairs(self.floating_popups) do
        local elapsed = now - p.start_time
        if elapsed < 0 then
            alive[#alive + 1] = p
        elseif elapsed < M.FLOAT_DMG_DURATION then
            local anchor = bar_anchors[p.monster_idx]
            if anchor then
                p.last_x = anchor.cx
                p.last_y = anchor.top_y
                p.scale  = anchor.scale
            end
            local prog = clamp(elapsed / M.FLOAT_DMG_DURATION, 0.0, 1.0)
            local rise = M.FLOAT_DMG_RISE_PX * (1.0 - (1.0 - prog) ^ 2)
            local alpha = 255
            if prog > 0.55 then
                alpha = round(255 * (1.0 - (prog - 0.55) / 0.45))
            end
            local txt = "-" .. self:shorten_number(p.amount) .. (p.is_crit and "!" or "")
            local col = self:damage_color(p.amount)
            local fsize = math.max(10, round((self.font_size + (p.is_crit and 5 or 2)) * p.scale))
            local tsurf = self:render_text_cached(txt, fsize, col, 2, { 0, 0, 0, 255 }, true)
            if tsurf then
                surface:draw_image(tsurf, p.last_x + p.x_jitter, p.last_y - rise - 6, tsurf.w, tsurf.h, alpha, "center")
            end
            alive[#alive + 1] = p
        end
    end
    self.floating_popups = alive
end

function OverlayApp:draw_potion_buff_alerts(game_data, now, surface)
    if not self.show_potion_buff_tracker or type(game_data) ~= "table" then return end
    local warnings = {}
    local seen = {}
    local thresh = tonumber(self.potion_warning_threshold) or 20.0
    if thresh <= 0 then thresh = 20.0 end

    if type(game_data.PotionBuffs) == "table" then
        for _, b in ipairs(game_data.PotionBuffs) do
            if type(b) == "table" then
                local rem = tonumber(b.Remaining)
                if rem and rem > 0 and rem <= thresh then
                    local pot_raw = tostring(b.Potion or "Potion")
                    local pot_clean = pot_raw:gsub("'s Potion", " Potion"):gsub("\226\128\153s Potion", " Potion"):match("^%s*(.-)%s*$")
                    local pc_name = tostring(b.Player or "Party"):match("^%s*(.-)%s*$")
                    local key = pot_clean .. "|" .. pc_name
                    if not seen[key] then
                        seen[key] = true
                        warnings[#warnings + 1] = { pot_name = pot_clean, pc_name = pc_name, rem = rem }
                    end
                end
            end
        end
    elseif type(game_data.PartyBuffs) == "table" then
        for _, def in ipairs(M.POTION_BUFF_DEFS) do
            local rem = tonumber(game_data.PartyBuffs[def.key])
            if rem and rem > 0 and rem <= thresh then
                warnings[#warnings + 1] = { pot_name = def.label, pc_name = "Party", rem = rem }
            end
        end
    end
    if #warnings == 0 then return end

    -- Sort so the buff expiring soonest is at the top
    table.sort(warnings, function(a, b) return a.rem < b.rem end)

    local max_count = math.min(6, #warnings)
    local line_height = math.max(22, round(self.font_size * 1.5))
    local total_h = max_count * line_height

    local raw_px = tonumber(self.potion_tracker_pos_x) or M.DEFAULT_POTION_TRACKER_POS_X
    local raw_py = tonumber(self.potion_tracker_pos_y) or M.DEFAULT_POTION_TRACKER_POS_Y

    -- Left-aligned X position (matches Python's anchor="w" at start_x ~20-28px from left edge)
    local start_x = (raw_px > 1.0)
        and clamp(round(raw_px), 16, math.max(16, surface.w - 260))
        or round(surface.w * clamp(raw_px, 0.01, 0.85))

    -- Y position clamped above the bottom-left HUD panel (0.76 * screen height) so alerts never go off-screen
    local max_bottom_y = math.max(100, round(surface.h * 0.76) - total_h)
    local start_y = (raw_py > 1.0)
        and clamp(round(raw_py), 48, max_bottom_y)
        or clamp(round(surface.h * clamp(raw_py, 0.05, 0.76)), 48, max_bottom_y)

    local fsize = math.max(12, round(self.font_size * 1.12))

    for i = 1, max_count do
        local w = warnings[i]
        local rem_ceil = math.max(1, math.ceil(w.rem))
        local sec_unit = (rem_ceil == 1) and "sec" or "secs"
        local txt = string.format("%s <%d%s (%s)", w.pot_name, rem_ceil, sec_unit, w.pc_name)

        local col
        if w.rem <= 5.0 then
            local pulse = 0.5 + 0.5 * math.sin(now * 8.0)
            local gb = round(50 + 60 * pulse)
            col = { 255, gb, gb, 255 }
        elseif w.rem <= 10.0 then
            col = { 255, 160, 40, 255 }
        else
            col = { 255, 215, 75, 255 }
        end

        local tsurf = self:render_text_cached(txt, fsize, col, 2, { 0, 0, 0, 255 }, true)
        if tsurf then
            local draw_y = start_y + (i - 1) * line_height
            surface:draw_image(tsurf, start_x, draw_y, tsurf.w, tsurf.h, 255, "w")
        end
    end
end

function OverlayApp:draw_splash_screen(surface, now)
    -- Startup splash screen disabled for in-game stability
    return
end

-- ============================================================================
-- Main Frame Update
-- ============================================================================
function OverlayApp:get_visibility_flags(game_data)
    if not self.tie_to_id_monster then
        return { name = true, hp_nums = true, hp_bar = true, level = true, attack = true, resistances = true }
    end
    local mastery = tonumber(game_data and game_data.IdMonsterMastery) or 4
    local skill = tonumber(game_data and game_data.IdMonsterSkill) or 10
    if skill <= 0 then
        return { name = true, hp_nums = false, hp_bar = false, level = false, attack = false, resistances = false }
    elseif mastery == 1 then
        return { name = true, hp_nums = true, hp_bar = true, level = true, attack = false, resistances = false }
    elseif mastery == 2 then
        return { name = true, hp_nums = true, hp_bar = true, level = true, attack = true, resistances = false }
    else
        return { name = true, hp_nums = true, hp_bar = true, level = true, attack = true, resistances = true }
    end
end

function OverlayApp:load_game_data_from_json()
    local raw = read_file_text(M.JSON_PATH)
    if not raw or raw == "" then
        local fallback_path = SCRIPT_DIR .. "\\..\\_Python Overlay\\visible_monsters.json"
        raw = read_file_text(fallback_path)
    end
    if not raw or raw == "" then return nil end
    return gdi.json_decode(raw)
end

function OverlayApp:update_bars(game_data)
    if not self.win or not self.win.visible or not self.win.surface then return end
    local surface = self.win.surface
    local now = gdi.now()
    local dt = clamp(now - (self.last_update_time or now), 0.001, 0.25)
    self.last_update_time = now

    surface:clear()

    if type(game_data) == "table" then
        if self.hide_in_menus and game_data.InMenu then
            self:draw_splash_screen(surface, now)
            self.win:present()
            return
        end

        self:ingest_recent_hits(game_data, now)

        local vis = self:get_visibility_flags(game_data)
        if vis.hp_bar then
            local raw_monsters = game_data.Monsters or (game_data[1] and game_data) or {}
            local targeted_idx = tonumber(game_data.TargetedMonsterIndex or game_data.TargetedIndex) or -1

            local drain_info = self:update_damage_drain(raw_monsters, now, dt)

            local valid_monsters = {}
            for _, m in ipairs(raw_monsters) do
                local idx = m.Index
                local hp = tonumber(m.HP) or 0
                if hp <= 0 then
                    if idx and not self.permanently_hidden_monsters[idx] and not self.fading_monsters[idx] then
                        self.fading_monsters[idx] = { start = now, data = m }
                    end
                else
                    if idx then self.permanently_hidden_monsters[idx] = nil end
                    local skip = false
                    if m.IsAlly and not self.show_ally_bars then skip = true end
                    if not skip and M.is_peasant_or_guard_full_hp_ally(m) then skip = true end
                    if not skip and self.show_mouseover_only and idx ~= targeted_idx then skip = true end
                    if not skip then
                        valid_monsters[#valid_monsters + 1] = m
                    end
                end
            end

            -- Split into close-range stacked grid vs world-space bars
            local close_monsters = {}
            local world_monsters = {}
            for _, m in ipairs(valid_monsters) do
                local dist = tonumber(m.Distance) or 1000
                if self.close_range_threshold > 0 and dist <= self.close_range_threshold then
                    close_monsters[#close_monsters + 1] = m
                else
                    world_monsters[#world_monsters + 1] = m
                end
            end

            if self.smart_anti_overlap and #world_monsters > 1 then
                self:resolve_world_anti_overlap(world_monsters, targeted_idx)
            end

            -- Update Micro Bar animation state (matches MAW_Overlay.py get_target_anim_t)
            local total_visible_bars = #world_monsters + #close_monsters
            local ANIM_SPEED = 9.0
            for _, m in ipairs(valid_monsters) do
                local idx = m.Index or -1
                local target_t = 1.0
                if self.micro_bar_mode == "Only Micro" then
                    target_t = 0.0
                elseif self.micro_bar_mode == "On" then
                    target_t = (idx == targeted_idx) and 1.0 or 0.0
                elseif self.micro_bar_mode == "Dynamic" then
                    if total_visible_bars >= 4 then
                        target_t = (idx == targeted_idx) and 1.0 or 0.0
                    else
                        target_t = 1.0
                    end
                end
                local cur_t = self.micro_anim_state[idx]
                if cur_t == nil then cur_t = target_t end
                if math.abs(cur_t - target_t) > 0.005 then
                    if cur_t < target_t then
                        cur_t = math.min(target_t, cur_t + ANIM_SPEED * dt)
                    else
                        cur_t = math.max(target_t, cur_t - ANIM_SPEED * dt)
                    end
                else
                    cur_t = target_t
                end
                self.micro_anim_state[idx] = cur_t
            end

            local active_bar_anchors = {}

            -- Draw back-to-front so closer monsters render on top
            table.sort(world_monsters, function(a, b)
                return (tonumber(a.Distance) or 1000) > (tonumber(b.Distance) or 1000)
            end)

            for _, m in ipairs(world_monsters) do
                local idx = m.Index
                local d_info = idx and drain_info[idx]
                local anchor = self:draw_bar(m, vis, {
                    override_y = m._adjusted_y,
                    is_highlighted = (idx == targeted_idx),
                    drain_ratio = d_info and d_info[1] or nil,
                    drain_is_crit = d_info and d_info[2] or false,
                    anim_t = idx and self.micro_anim_state[idx] or 1.0,
                    now = now,
                    frame = surface,
                })
                if idx and anchor then active_bar_anchors[idx] = anchor end
            end

            -- Draw close-range grid (matches MAW_Overlay.py CLOSE_STACK layout)
            if #close_monsters > 0 then
                table.sort(close_monsters, function(a, b)
                    return (tonumber(a.Distance) or 1000) > (tonumber(b.Distance) or 1000)
                end)
                local max_per_col = 3
                local cols = math.ceil(#close_monsters / max_per_col)
                local dynamic_shrink = 1.0
                if cols > 2 then
                    dynamic_shrink = 0.70
                elseif cols > 1 then
                    dynamic_shrink = 0.85
                end
                local current_grid_scale = 0.75 * dynamic_shrink
                local start_x = surface.w / 2.0
                local start_y = surface.h - 350
                local spacing_x = 180 * dynamic_shrink
                local spacing_y = 65 * dynamic_shrink

                for i, m in ipairs(close_monsters) do
                    local idx = m.Index
                    local col_idx = math.floor((i - 1) / max_per_col)
                    local row_idx = (i - 1) % max_per_col
                    local gx = start_x + (col_idx - (cols - 1) / 2.0) * spacing_x
                    local gy = start_y + row_idx * spacing_y
                    local d_info = idx and drain_info[idx]
                    local anchor = self:draw_bar(m, vis, {
                        override_x = gx,
                        override_y = gy,
                        is_highlighted = (idx == targeted_idx),
                        size_mult = current_grid_scale,
                        drain_ratio = d_info and d_info[1] or nil,
                        drain_is_crit = d_info and d_info[2] or false,
                        anim_t = idx and self.micro_anim_state[idx] or 1.0,
                        now = now,
                        frame = surface,
                    })
                    if idx and anchor then active_bar_anchors[idx] = anchor end
                end
            end

            -- Render Killing-Blow Skull Pop for Dying Monsters
            for idx, f in pairs(self.fading_monsters) do
                local elapsed = now - f.start
                if elapsed >= M.DEATH_POP_DURATION then
                    self.permanently_hidden_monsters[idx] = true
                    self.fading_monsters[idx] = nil
                    self.damage_drain_state[idx] = nil
                else
                    local m_data = f.data
                    local scale = self:get_scale(m_data.Distance or 1000)
                    local prog = clamp(elapsed / M.DEATH_POP_DURATION, 0.0, 1.0)
                    local shrink = math.max(0.1, 1.0 - (prog ^ 1.3) * 0.9)
                    local opacity = (prog < 0.15) and 255 or clamp(round(255 * (1.0 - (prog - 0.15) / 0.85)), 0, 255)
                    local kx = tonumber(m_data.ScreenX) or 0
                    local ky = (tonumber(m_data.ScreenY) or 0) + self:get_monster_y_offset(m_data) - 8
                    local ksize = math.max(4, round(34 * scale * shrink))
                    if self.show_kill_skull and self.kill_skull_bmp and opacity > 0 then
                        surface:draw_image(self.kill_skull_bmp, kx, ky, ksize, ksize, opacity, "center")
                    end
                    active_bar_anchors[idx] = { cx = kx, top_y = ky - ksize / 2 - 4, scale = scale }
                end
            end

            self:draw_floating_damage_popups(active_bar_anchors, now, surface)
            self:draw_potion_buff_alerts(game_data, now, surface)
        end
    end

    self:draw_splash_screen(surface, now)
    self.win:present()
end

function OverlayApp:toggle_visibility()
    if not self.win then return end
    self.win:set_visible(not self.win.visible)
end

function OverlayApp:open_settings()
    if self.on_open_settings then
        self.on_open_settings()
    else
        local settings_mod = _G._MAW_SETTINGS_MOD or dofile(SCRIPT_DIR .. "\\Overlay_Settings.lua")
        if settings_mod and settings_mod.show_settings_window then
            settings_mod.show_settings_window(self)
        end
    end
end

function OverlayApp:step(external_game_data)
    if not self.win then return end
    self.win:pump_events(self)
    local now = gdi.now()
    if now - (self.last_settings_check or 0) >= 1.0 then
        self.last_settings_check = now
        self:load_settings(false)
    end
    local data = external_game_data or self:load_game_data_from_json()
    self:update_bars(data)
end

function OverlayApp:destroy()
    self:clear_caches()
    if self.win then
        self.win:destroy()
        self.win = nil
    end
end

gdi.disable_jit(OverlayApp)
gdi.disable_jit(M)

return M
