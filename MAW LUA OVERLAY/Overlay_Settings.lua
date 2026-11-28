-- ============================================================================
-- Overlay_Settings.lua
-- Pure LuaJIT Native Win32 Settings Dialog Window for MAW Monster HP Overlay.
-- Uses Win32 common controls, ChooseColorW, and GDI+ real-time HP Bar Preview.
-- Hardened for in-process MMExtension / LuaJIT 2.0 execution:
--   * Zero FFI WNDPROC callbacks (uses raw C DefWindowProcW + SS_BITMAP + state polling)
--   * JIT compilation disabled on all functions (jit.off)
-- ============================================================================

if jit and jit.off then
    jit.off(true, true)
end

local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

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
local overlay_mod = _G._MAW_OVERLAY_MOD or dofile(SCRIPT_DIR .. "\\MAW_Overlay.lua")

local M = {}
_G._MAW_SETTINGS_MOD = M

local RESOLUTION_OPTIONS = {
    "Auto ( Native Screen )",
    "3840x2160",
    "2560x1440",
    "1920x1080",
    "1600x900",
    "1366x768",
    "1280x720",
}

local PREVIEW_PRESETS = {
    "Enemy (65% HP)",
    "Enemy (Full HP)",
    "Enemy (Critical 20%)",
    "Ally Unit (fill_B)",
    "Boss Monster",
}

-- Win32 Control Message & Style Constants
local BM_GETCHECK   = 0x00F0
local BM_SETCHECK   = 0x00F1
local BST_CHECKED   = 1
local BST_UNCHECKED = 0

local CB_ADDSTRING   = 0x0143
local CB_SETCURSEL   = 0x014E
local CB_GETCURSEL   = 0x0147

local TBM_GETPOS   = 0x0400
local TBM_SETPOS   = 0x0405
local TBM_SETRANGE = 0x0406
local TBS_HORZ     = 0x0000
local TBS_NOTICKS  = 0x0010

local BS_AUTOCHECKBOX = 0x00000003
local BS_GROUPBOX     = 0x00000007
local BS_PUSHLIKE     = 0x00001000
local CBS_DROPDOWNLIST = 0x0003

local SS_BITMAP    = 0x0000000E
local STM_SETIMAGE = 0x0172
local IMAGE_BITMAP = 0

local ES_CENTER      = 0x0001
local ES_AUTOHSCROLL = 0x0080

local shared_edit_buf = ffi.new("WCHAR[64]")

local function list_font_files()
    local fonts = {}
    local files = gdi.list_dir(overlay_mod.FONTS_DIR, false)
    for _, f in ipairs(files) do
        local low = f:lower()
        if low:match("%.ttf$") or low:match("%.otf$") then
            fonts[#fonts + 1] = f
        end
    end
    if #fonts == 0 then
        fonts[1] = overlay_mod.DEFAULT_FONT_FILE
    end
    table.sort(fonts, function(a, b) return a:lower() < b:lower() end)
    return fonts
end

local function read_file_text(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c
end

local function write_file_text(path, content)
    local f = io.open(path, "wb")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

-- ============================================================================
-- SettingsWindow Class (Callback-Free Native Win32 Dialog)
-- ============================================================================
local SettingsWindow = {}
SettingsWindow.__index = SettingsWindow

local settings_class_registered = false
local shared_bg_brush = nil
local active_settings_win = nil

function M.show_settings_window(live_overlay_app)
    if active_settings_win and active_settings_win.hwnd and gdi.user32.IsWindow(active_settings_win.hwnd) ~= 0 then
        gdi.user32.ShowWindow(active_settings_win.hwnd, 5) -- SW_SHOW
        gdi.user32.SetForegroundWindow(active_settings_win.hwnd)
        return active_settings_win
    end
    active_settings_win = SettingsWindow.new(live_overlay_app)
    return active_settings_win
end

function SettingsWindow.new(live_overlay_app)
    local self = setmetatable({
        live_overlay = live_overlay_app,
        win_w = 1040,
        win_h = 770,
        preview_w = 296,
        preview_h = 165,
        preview_x = 707,
        preview_y = 114,
        initializing = true,
        controls = {},
        buttons = {},
        combos = {},
        swatches = {},
        custom_colors = ffi.new("COLORREF[16]"),
        next_id = 2000,
    }, SettingsWindow)

    self.settings = self:load_settings()
    self.preview_renderer = overlay_mod.new_overlay_app(true)
    self.preview_surface = gdi.create_dib_surface(self.preview_w, self.preview_h)

    -- GDI Fonts & Brushes
    if not shared_bg_brush then
        shared_bg_brush = gdi.gdi32.CreateSolidBrush(gdi.COLORREF(240, 240, 240))
    end
    self.font_normal = gdi.gdi32.CreateFontW(-12, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, gdi.W("Segoe UI"))
    self.font_bold   = gdi.gdi32.CreateFontW(-12, 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 5, 0, gdi.W("Segoe UI"))
    self.font_small  = gdi.gdi32.CreateFontW(-11, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, gdi.W("Segoe UI"))

    self:_create_hwnd()
    self:_build_controls()
    self:apply_settings_to_controls()
    self.initializing = false
    self:update_preview()
    self:update_swatches()

    gdi.user32.ShowWindow(self.hwnd, 5)
    gdi.user32.UpdateWindow(self.hwnd)
    return self
end

function SettingsWindow:get_default_settings()
    local res_cols = {}
    for k, v in pairs(overlay_mod.DEFAULT_RESISTANCE_COLORS) do
        res_cols[k] = { v[1], v[2], v[3], v[4] or 255 }
    end
    return {
        font_file = overlay_mod.DEFAULT_FONT_FILE,
        font_size = overlay_mod.DEFAULT_FONT_SIZE,
        text_color = { unpack(overlay_mod.DEFAULT_TEXT_COLOR) },
        text_outline_width = overlay_mod.DEFAULT_TEXT_OUTLINE_WIDTH,
        text_outline_color = { unpack(overlay_mod.DEFAULT_TEXT_OUTLINE_COLOR) },
        show_mouseover_only = overlay_mod.DEFAULT_SHOW_MOUSEOVER_ONLY,
        hide_in_menus = overlay_mod.DEFAULT_HIDE_IN_MENUS,
        smart_anti_overlap = overlay_mod.DEFAULT_SMART_ANTI_OVERLAP,
        tie_to_id_monster = overlay_mod.DEFAULT_TIE_TO_ID_MONSTER,
        show_name_text = overlay_mod.DEFAULT_SHOW_NAME_TEXT,
        show_hp_numbers = overlay_mod.DEFAULT_SHOW_HP_NUMBERS,
        show_monster_level = overlay_mod.DEFAULT_SHOW_MONSTER_LEVEL,
        show_attack_spell_icons = overlay_mod.DEFAULT_SHOW_ATTACK_SPELL_ICONS,
        show_debuff_icons = overlay_mod.DEFAULT_SHOW_DEBUFF_ICONS,
        show_debuff_timers = overlay_mod.DEFAULT_SHOW_DEBUFF_TIMERS,
        show_debuff_stacks = overlay_mod.DEFAULT_SHOW_DEBUFF_STACKS,
        show_floating_damage = overlay_mod.DEFAULT_SHOW_FLOATING_DAMAGE,
        show_cc_dr_tracker = overlay_mod.DEFAULT_SHOW_CC_DR_TRACKER,
        show_potion_buff_tracker = overlay_mod.DEFAULT_SHOW_POTION_BUFF_TRACKER,
        potion_warning_threshold = overlay_mod.DEFAULT_POTION_WARNING_THRESHOLD,
        potion_tracker_pos_x = overlay_mod.DEFAULT_POTION_TRACKER_POS_X,
        potion_tracker_pos_y = overlay_mod.DEFAULT_POTION_TRACKER_POS_Y,
        show_resistance_pips = overlay_mod.DEFAULT_SHOW_RESISTANCE_PIPS,
        show_ally_bars = overlay_mod.DEFAULT_SHOW_ALLY_BARS,
        show_splash_screen = overlay_mod.DEFAULT_SHOW_SPLASH_SCREEN,
        high_resistance_threshold = overlay_mod.DEFAULT_HIGH_RESISTANCE_THRESHOLD,
        micro_bar_mode = overlay_mod.DEFAULT_MICRO_BAR_MODE,
        bar_vertical_offset = overlay_mod.DEFAULT_BAR_VERTICAL_OFFSET,
        fov_scale_indoor = overlay_mod.DEFAULT_FOV_SCALE_INDOOR,
        fov_scale_outdoor = overlay_mod.DEFAULT_FOV_SCALE_OUTDOOR,
        base_height = overlay_mod.DEFAULT_BASE_HEIGHT,
        left_cap_width = overlay_mod.DEFAULT_LEFT_CAP_WIDTH,
        right_cap_width = overlay_mod.DEFAULT_RIGHT_CAP_WIDTH,
        fill_height = overlay_mod.DEFAULT_FILL_HEIGHT,
        boss_icon_base_size = overlay_mod.DEFAULT_BOSS_ICON_BASE_SIZE,
        debuff_icon_base_size = overlay_mod.DEFAULT_DEBUFF_ICON_BASE_SIZE,
        close_range_threshold = overlay_mod.DEFAULT_CLOSE_RANGE_THRESHOLD,
        shorten_number_digits = overlay_mod.DEFAULT_SHORTEN_NUMBER_DIGITS,
        screen_resolution = overlay_mod.DEFAULT_RESOLUTION,
        ui_theme = overlay_mod.DEFAULT_UI_THEME,
        resistance_colors = res_cols,
    }
end

function SettingsWindow:load_settings()
    local defaults = self:get_default_settings()
    local raw = read_file_text(overlay_mod.SETTINGS_FILE)
    if not raw then return defaults end
    local loaded = gdi.json_decode(raw)
    if type(loaded) ~= "table" then return defaults end
    for k, v in pairs(defaults) do
        if loaded[k] == nil then
            loaded[k] = v
        end
    end
    if type(loaded.resistance_colors) ~= "table" then
        loaded.resistance_colors = defaults.resistance_colors
    else
        for k, v in pairs(defaults.resistance_colors) do
            if type(loaded.resistance_colors[k]) ~= "table" then
                loaded.resistance_colors[k] = v
            end
        end
    end
    return loaded
end

function SettingsWindow:save_settings()
    if self.initializing then return end
    local json_str = gdi.json_encode(self.settings)
    write_file_text(overlay_mod.SETTINGS_FILE, json_str)
    if self.live_overlay and self.live_overlay.load_settings then
        self.live_overlay:load_settings(true)
    end
    self:update_preview()
end

function SettingsWindow:_alloc_id()
    self.next_id = self.next_id + 1
    return self.next_id
end

function SettingsWindow:_create_hwnd()
    local hinst = gdi.kernel32.GetModuleHandleW(nil)
    local cls_name = gdi.W("MAW_Lua_SettingsWindow_Class_V2")

    if not settings_class_registered then
        local wc = ffi.new("MAW_WNDCLASSEXW")
        wc.cbSize = ffi.sizeof("MAW_WNDCLASSEXW")
        wc.style = 0x0003 -- CS_HREDRAW | CS_VREDRAW
        wc.lpfnWndProc = gdi.DefWindowProcW_ptr
        wc.hInstance = hinst
        wc.hIcon = gdi.user32.LoadIconW(nil, ffi.cast("LPCWSTR", 32512))
        wc.hCursor = gdi.user32.LoadCursorW(nil, ffi.cast("LPCWSTR", 32512))
        wc.hbrBackground = shared_bg_brush
        wc.lpszClassName = cls_name
        gdi.user32.RegisterClassExW(ffi.cast("const WNDCLASSEXW*", wc))
        settings_class_registered = true
    end

    local sw = gdi.user32.GetSystemMetrics(0)
    local sh = gdi.user32.GetSystemMetrics(1)
    local wx = math.max(0, math.floor((sw - self.win_w) / 2))
    local wy = math.max(0, math.floor((sh - self.win_h) / 2))

    local style = bor(gdi.WS_CAPTION, gdi.WS_SYSMENU, gdi.WS_MINIMIZEBOX, gdi.WS_CLIPCHILDREN)
    self.hwnd = gdi.user32.CreateWindowExW(
        0,
        cls_name,
        gdi.W("MAW Monster HP Overlay Settings (Lua Native Win32)"),
        style,
        wx, wy, self.win_w, self.win_h,
        nil, nil, hinst, nil
    )
end

function SettingsWindow:_add_label(text, x, y, w, h, bold)
    local hinst = gdi.kernel32.GetModuleHandleW(nil)
    local hwnd = gdi.user32.CreateWindowExW(
        0, gdi.W("STATIC"), gdi.W(text),
        bor(gdi.WS_CHILD, gdi.WS_VISIBLE),
        x, y, w, h, self.hwnd, nil, hinst, nil
    )
    gdi.user32.SendMessageW(hwnd, 0x0030, ffi.cast("WPARAM", bold and self.font_bold or self.font_normal), 1)
    return hwnd
end

function SettingsWindow:_add_bitmap_static(x, y, w, h)
    local hinst = gdi.kernel32.GetModuleHandleW(nil)
    local hwnd = gdi.user32.CreateWindowExW(
        0, gdi.W("STATIC"), gdi.W(""),
        bor(gdi.WS_CHILD, gdi.WS_VISIBLE, SS_BITMAP),
        x, y, w, h, self.hwnd, nil, hinst, nil
    )
    return hwnd
end

function SettingsWindow:_add_swatch(key, x, y, w, h, get_color_fn)
    local surf = gdi.create_dib_surface(w, h)
    local hwnd = self:_add_bitmap_static(x, y, w, h)
    self.swatches[key] = {
        hwnd = hwnd,
        surf = surf,
        w = w,
        h = h,
        get = get_color_fn,
    }
end

function SettingsWindow:update_swatches()
    for _, sw in pairs(self.swatches) do
        if sw.surf and sw.hwnd then
            local col = sw.get() or { 255, 255, 255 }
            sw.surf:clear(255, col[1] or 255, col[2] or 255, col[3] or 255)
            sw.surf:draw_rect(0, 0, sw.w - 1, sw.h - 1, 1.0, 255, 60, 75, 74)
            gdi.user32.SendMessageW(sw.hwnd, STM_SETIMAGE, IMAGE_BITMAP, ffi.cast("LPARAM", sw.surf.hbmp))
            gdi.user32.InvalidateRect(sw.hwnd, nil, 0)
        end
    end
end

function SettingsWindow:_add_groupbox(title, x, y, w, h)
    local hinst = gdi.kernel32.GetModuleHandleW(nil)
    local hwnd = gdi.user32.CreateWindowExW(
        0, gdi.W("BUTTON"), gdi.W(title),
        bor(gdi.WS_CHILD, gdi.WS_VISIBLE, BS_GROUPBOX),
        x, y, w, h, self.hwnd, nil, hinst, nil
    )
    gdi.user32.SendMessageW(hwnd, 0x0030, ffi.cast("WPARAM", self.font_bold), 1)
    return hwnd
end

function SettingsWindow:_add_button(text, x, y, w, h, callback)
    local id = self:_alloc_id()
    local hinst = gdi.kernel32.GetModuleHandleW(nil)
    -- BS_AUTOCHECKBOX | BS_PUSHLIKE looks like a normal button and latches BM_GETCHECK=1 when clicked
    local hwnd = gdi.user32.CreateWindowExW(
        0, gdi.W("BUTTON"), gdi.W(text),
        bor(gdi.WS_CHILD, gdi.WS_VISIBLE, BS_AUTOCHECKBOX, BS_PUSHLIKE),
        x, y, w, h, self.hwnd, ffi.cast("HMENU", id), hinst, nil
    )
    gdi.user32.SendMessageW(hwnd, 0x0030, ffi.cast("WPARAM", self.font_normal), 1)
    if callback then
        self.buttons[#self.buttons + 1] = { hwnd = hwnd, id = id, callback = callback }
    end
    return hwnd, id
end

function SettingsWindow:_add_checkbox(text, x, y, w, h, setting_key)
    local id = self:_alloc_id()
    local hinst = gdi.kernel32.GetModuleHandleW(nil)
    local hwnd = gdi.user32.CreateWindowExW(
        0, gdi.W("BUTTON"), gdi.W(text),
        bor(gdi.WS_CHILD, gdi.WS_VISIBLE, BS_AUTOCHECKBOX),
        x, y, w, h, self.hwnd, ffi.cast("HMENU", id), hinst, nil
    )
    gdi.user32.SendMessageW(hwnd, 0x0030, ffi.cast("WPARAM", self.font_small), 1)
    self.controls[setting_key] = { kind = "checkbox", hwnd = hwnd, id = id }
    return hwnd
end

function SettingsWindow:_add_combobox(x, y, w, h, items, on_change)
    local id = self:_alloc_id()
    local hinst = gdi.kernel32.GetModuleHandleW(nil)
    local hwnd = gdi.user32.CreateWindowExW(
        0, gdi.W("COMBOBOX"), gdi.W(""),
        bor(gdi.WS_CHILD, gdi.WS_VISIBLE, CBS_DROPDOWNLIST, gdi.WS_VSCROLL),
        x, y, w, h, self.hwnd, ffi.cast("HMENU", id), hinst, nil
    )
    gdi.user32.SendMessageW(hwnd, 0x0030, ffi.cast("WPARAM", self.font_normal), 1)
    for _, item in ipairs(items) do
        gdi.user32.SendMessageW(hwnd, CB_ADDSTRING, 0, ffi.cast("LPARAM", gdi.W(item)))
    end
    self.combos[#self.combos + 1] = {
        hwnd = hwnd,
        id = id,
        items = items,
        last_idx = -1,
        on_change = on_change,
    }
    return hwnd, id
end

function SettingsWindow:_add_slider_row(parent_x, y, label_text, min_val, max_val, setting_key, scale_factor, editable)
    scale_factor = scale_factor or 1
    self:_add_label(label_text, parent_x + 10, y + 2, 118, 18, false)

    local hinst = gdi.kernel32.GetModuleHandleW(nil)
    local val_lbl
    local tb_w = editable and 132 or 136
    if editable then
        val_lbl = gdi.user32.CreateWindowExW(
            0, gdi.W("EDIT"), gdi.W(""),
            bor(gdi.WS_CHILD, gdi.WS_VISIBLE, gdi.WS_BORDER, gdi.WS_TABSTOP, ES_AUTOHSCROLL, ES_CENTER),
            parent_x + 262, y, 48, 21, self.hwnd, nil, hinst, nil
        )
        gdi.user32.SendMessageW(val_lbl, 0x0030, ffi.cast("WPARAM", self.font_normal), 1)
    else
        val_lbl = self:_add_label("", parent_x + 266, y + 2, 42, 18, false)
    end

    local hwnd = gdi.user32.CreateWindowExW(
        0, gdi.W("msctls_trackbar32"), gdi.W(""),
        bor(gdi.WS_CHILD, gdi.WS_VISIBLE, TBS_HORZ, TBS_NOTICKS),
        parent_x + 128, y, tb_w, 22, self.hwnd, nil, hinst, nil
    )

    -- Handle negative ranges by shifting by offset
    local offset = (min_val < 0) and (-min_val) or 0
    local r_min = min_val + offset
    local r_max = max_val + offset
    local range_lparam = bor(band(r_min, 0xFFFF), lshift(band(r_max, 0xFFFF), 16))
    gdi.user32.SendMessageW(hwnd, TBM_SETRANGE, 1, range_lparam)

    local function format_val(v)
        if scale_factor ~= 1 then
            return string.format("%.2f", v)
        end
        return tostring(math.floor(v + 0.5))
    end

    self.controls[setting_key] = {
        kind = "slider",
        hwnd = hwnd,
        val_lbl = val_lbl,
        offset = offset,
        scale_factor = scale_factor,
        format_val = format_val,
        last_raw_pos = nil,
        editable = editable and true or false,
        min_val = min_val / scale_factor,
        max_val = max_val / scale_factor,
        last_edit_text = nil,
    }
end

function SettingsWindow:_pick_color(initial_rgba)
    local cc = ffi.new("CHOOSECOLORW")
    cc.lStructSize = ffi.sizeof("CHOOSECOLORW")
    cc.hwndOwner = self.hwnd
    cc.lpCustColors = self.custom_colors
    cc.rgbResult = gdi.COLORREF(initial_rgba[1] or 255, initial_rgba[2] or 255, initial_rgba[3] or 255)
    cc.Flags = 0x00000001 + 0x00000002 -- CC_RGBINIT | CC_FULLOPEN
    if gdi.comdlg32.ChooseColorW(cc) ~= 0 then
        local c = tonumber(cc.rgbResult)
        local r = band(c, 0xFF)
        local g = band(rshift(c, 8), 0xFF)
        local b = band(rshift(c, 16), 0xFF)
        return { r, g, b, 255 }
    end
    return nil
end

function SettingsWindow:_build_controls()
    -- ========================================================================
    -- 1. Top Header Bar
    -- ========================================================================
    self:_add_label("Resolution:", 30, 22, 72, 20, true)
    self.res_combo = self:_add_combobox(104, 19, 155, 200, RESOLUTION_OPTIONS, function(val)
        self.settings.screen_resolution = val
        self:save_settings()
    end)

    self:_add_label("Theme:", 272, 22, 50, 20, true)
    self.avail_themes = overlay_mod.get_available_themes()
    self.theme_combo = self:_add_combobox(325, 19, 145, 200, self.avail_themes, function(val)
        self:on_theme_change(val)
    end)

    self:_add_label("Hotkey: Ctrl+Shift+F12", 485, 23, 145, 18, false)

    self:_add_button("Launch Overlay", 640, 18, 115, 25, function()
        if self.live_overlay and self.live_overlay.win then
            self.live_overlay.win:set_visible(true)
        elseif _G.MAW_LuaOverlay and _G.MAW_LuaOverlay.Start then
            _G.MAW_LuaOverlay.Start()
        end
        gdi.user32.MessageBoxW(self.hwnd, gdi.W("MAW Lua Monster HP Overlay is active."), gdi.W("Overlay Launched"), 0x40)
    end)

    self:_add_button("Exit Overlay", 762, 18, 105, 25, function()
        if self.live_overlay and self.live_overlay.win then
            self.live_overlay.win:set_visible(false)
        elseif _G.MAW_LuaOverlay and _G.MAW_LuaOverlay.Stop then
            _G.MAW_LuaOverlay.Stop()
        end
        gdi.user32.MessageBoxW(self.hwnd, gdi.W("MAW Lua Monster HP Overlay has been hidden/stopped."), gdi.W("Overlay Exited"), 0x40)
    end)

    self:_add_button("Restore Defaults", 874, 18, 130, 25, function()
        local res = gdi.user32.MessageBoxW(
            self.hwnd,
            gdi.W("Are you sure you want to restore all settings to their default values?"),
            gdi.W("Restore Defaults"),
            0x04 + 0x20 -- MB_YESNO | MB_ICONQUESTION
        )
        if res == 6 then -- IDYES
            self.settings = self:get_default_settings()
            self.initializing = true
            self:apply_settings_to_controls()
            self.initializing = false
            self:update_swatches()
            self:save_settings()
        end
    end)

    -- ========================================================================
    -- 2. Left Column (x = 25, w = 320)
    -- ========================================================================
    local col1_x = 25
    self:_add_groupbox("Font Settings", col1_x, 58, 320, 78)
    self:_add_label("Font File:", col1_x + 10, 80, 68, 18, false)
    self.font_files = list_font_files()
    self.font_combo = self:_add_combobox(col1_x + 82, 77, 225, 220, self.font_files, function(val)
        self.settings.font_file = val
        self:save_settings()
    end)
    self:_add_slider_row(col1_x, 106, "Font Size:", 8, 48, "font_size", 1)

    -- Text Color Settings
    self:_add_groupbox("Text Color Settings", col1_x, 144, 320, 102)
    self:_add_label("Text Color:", col1_x + 10, 166, 95, 18, false)
    self:_add_swatch("text_color", col1_x + 135, 164, 55, 20, function() return self.settings.text_color end)
    self:_add_button("Choose", col1_x + 235, 163, 72, 22, function()
        local col = self:_pick_color(self.settings.text_color)
        if col then
            self.settings.text_color = col
            self:update_swatches()
            self:save_settings()
        end
    end)

    self:_add_slider_row(col1_x, 192, "Outline Width:", 0, 5, "text_outline_width", 1)

    self:_add_label("Outline Color:", col1_x + 10, 219, 95, 18, false)
    self:_add_swatch("outline_color", col1_x + 135, 217, 55, 20, function() return self.settings.text_outline_color end)
    self:_add_button("Choose", col1_x + 235, 216, 72, 22, function()
        local col = self:_pick_color(self.settings.text_outline_color)
        if col then
            self.settings.text_outline_color = col
            self:update_swatches()
            self:save_settings()
        end
    end)

    -- Display Options (16 Checkboxes + Micro HP Bar Dropdown)
    self:_add_groupbox("Display Options", col1_x, 254, 320, 282)
    local chk_defs = {
        { 0, 0, "Monster Name",           "show_name_text" },
        { 0, 1, "HP Numbers",             "show_hp_numbers" },
        { 1, 0, "Monster Level",          "show_monster_level" },
        { 1, 1, "Attack / Spell Icons",   "show_attack_spell_icons" },
        { 2, 0, "Debuff Icons",           "show_debuff_icons" },
        { 2, 1, "Debuff Clock Timers",    "show_debuff_timers" },
        { 3, 0, "Debuff Stack Counts",    "show_debuff_stacks" },
        { 3, 1, "Floating Damage Text",   "show_floating_damage" },
        { 4, 0, "Anti-Overlap Packs",     "smart_anti_overlap" },
        { 4, 1, "Hide in Menus/Dialogs",  "hide_in_menus" },
        { 5, 0, "Mouseover Target Only",  "show_mouseover_only" },
        { 5, 1, "Tie to ID Monster Skill","tie_to_id_monster" },
        { 6, 0, "CC Diminishing Returns", "show_cc_dr_tracker" },
        { 6, 1, "Potion Buff Tracker",    "show_potion_buff_tracker" },
        { 7, 0, "Resistance Pips",        "show_resistance_pips" },
        { 7, 1, "Ally Health Bars",       "show_ally_bars" },
    }
    for _, cd in ipairs(chk_defs) do
        local r, c, lbl, key = cd[1], cd[2], cd[3], cd[4]
        local cx = col1_x + 10 + c * 154
        local cy = 276 + r * 24
        self:_add_checkbox(lbl, cx, cy, 148, 20, key)
    end

    self:_add_label("Micro HP Bar:", col1_x + 10, 502, 110, 18, false)
    self.micro_combo = self:_add_combobox(col1_x + 164, 499, 142, 160, overlay_mod.MICRO_BAR_OPTIONS, function(val)
        self.settings.micro_bar_mode = val
        self:save_settings()
    end)

    -- ========================================================================
    -- 3. Middle Column (x = 360, w = 320)
    -- ========================================================================
    local col2_x = 360
    self:_add_groupbox("Bar Dimensions", col2_x, 58, 320, 258)
    self:_add_slider_row(col2_x, 82,  "Base Height:",     5,   50,  "base_height", 1)
    self:_add_slider_row(col2_x, 110, "Left Cap Width:",  0,   20,  "left_cap_width", 1)
    self:_add_slider_row(col2_x, 138, "Right Cap Width:", 0,   20,  "right_cap_width", 1)
    self:_add_slider_row(col2_x, 166, "Fill Height:",     1,   40,  "fill_height", 1)
    self:_add_slider_row(col2_x, 194, "Boss Icon Size:",  10,  100, "boss_icon_base_size", 1)
    self:_add_slider_row(col2_x, 222, "Debuff Icon Size:",8,   80,  "debuff_icon_base_size", 1)
    self:_add_slider_row(col2_x, 250, "Bar Y Offset:",   -1000, 1000, "bar_vertical_offset", 1, true)
    self:_add_slider_row(col2_x, 278, "Indoor FOV Scale:",80,  160, "fov_scale_indoor", 100)

    self:_add_groupbox("Close Range Stacking", col2_x, 326, 320, 56)
    self:_add_slider_row(col2_x, 350, "Threshold (0=Off):", 0, 1000, "close_range_threshold", 1)

    self:_add_groupbox("Number Shortening", col2_x, 392, 320, 56)
    self:_add_slider_row(col2_x, 416, "Shortening Digits:", 1, 10, "shorten_number_digits", 1)

    -- ========================================================================
    -- 4. Right Column (x = 695, w = 320): HP Bar Preview & Resistance Pip Colors
    -- ========================================================================
    local col3_x = 695
    self:_add_groupbox("HP Bar Preview", col3_x, 58, 320, 232)
    self:_add_label("Target:", col3_x + 12, 82, 52, 18, true)
    self.preview_target = PREVIEW_PRESETS[1]
    self.preview_combo = self:_add_combobox(col3_x + 68, 79, 235, 180, PREVIEW_PRESETS, function(val)
        self.preview_target = val
        self:update_preview()
    end)
    gdi.user32.SendMessageW(self.preview_combo, CB_SETCURSEL, 0, 0)
    self.preview_static_hwnd = self:_add_bitmap_static(self.preview_x, self.preview_y, self.preview_w, self.preview_h)

    -- Resistance Pip Colors (10 Elements)
    self:_add_groupbox("Resistance Pip Colors", col3_x, 298, 320, 318)
    for i, el in ipairs(overlay_mod.RESISTANCE_ELEMENTS) do
        local elem_key, elem_label = el[1], el[2]
        local ry = 320 + (i - 1) * 25
        self:_add_label(elem_label .. ":", col3_x + 14, ry + 2, 90, 18, false)
        self:_add_swatch("pip_" .. elem_key, col3_x + 130, ry, 55, 20, function()
            return self.settings.resistance_colors[elem_key] or overlay_mod.DEFAULT_RESISTANCE_COLORS[elem_key]
        end)
        self:_add_button("Choose", col3_x + 232, ry - 1, 72, 21, function()
            local cur = self.settings.resistance_colors[elem_key] or overlay_mod.DEFAULT_RESISTANCE_COLORS[elem_key]
            local picked = self:_pick_color(cur)
            if picked then
                self.settings.resistance_colors[elem_key] = picked
                self:update_swatches()
                self:save_settings()
            end
        end)
    end

    self:_add_button("Reset Pip Colors to Default", col3_x + 10, 584, 300, 24, function()
        for k, v in pairs(overlay_mod.DEFAULT_RESISTANCE_COLORS) do
            self.settings.resistance_colors[k] = { v[1], v[2], v[3], v[4] or 255 }
        end
        self:update_swatches()
        self:save_settings()
    end)
end

function SettingsWindow:on_theme_change(selected_theme)
    self.settings.ui_theme = selected_theme
    local theme_json_applied = false
    if selected_theme ~= overlay_mod.DEFAULT_UI_THEME then
        local cfg_path = overlay_mod.THEMES_DIR .. "\\" .. selected_theme .. "\\theme.json"
        local raw = read_file_text(cfg_path)
        if raw then
            local tcfg = gdi.json_decode(raw)
            if type(tcfg) == "table" then
                if tcfg.font_file then self.settings.font_file = tcfg.font_file end
                if type(tcfg.text_color) == "table" and #tcfg.text_color >= 3 then
                    self.settings.text_color = { tcfg.text_color[1], tcfg.text_color[2], tcfg.text_color[3], tcfg.text_color[4] or 255 }
                end
                theme_json_applied = true
            end
        end
    end
    if not theme_json_applied then
        if selected_theme:find("MM6", 1, true) then
            self.settings.font_file = "Arrus BT Bold.ttf"
            self.settings.text_color = { 246, 219, 134, 255 }
        elseif selected_theme:find("WoW", 1, true) then
            self.settings.font_file = overlay_mod.DEFAULT_FONT_FILE
            self.settings.text_color = { 255, 255, 255, 255 }
        elseif selected_theme:find("MAW", 1, true) then
            self.settings.font_file = overlay_mod.DEFAULT_FONT_FILE
            self.settings.text_color = { unpack(overlay_mod.DEFAULT_TEXT_COLOR) }
        end
    end
    self.initializing = true
    self:apply_settings_to_controls()
    self.initializing = false
    self:update_swatches()
    self:save_settings()
end

local function select_combo_item(hwnd, items, target)
    for i, v in ipairs(items) do
        if v == target then
            gdi.user32.SendMessageW(hwnd, CB_SETCURSEL, i - 1, 0)
            return i - 1
        end
    end
    gdi.user32.SendMessageW(hwnd, CB_SETCURSEL, 0, 0)
    return 0
end

function SettingsWindow:apply_settings_to_controls()
    select_combo_item(self.res_combo, RESOLUTION_OPTIONS, self.settings.screen_resolution)
    select_combo_item(self.theme_combo, self.avail_themes, self.settings.ui_theme)
    select_combo_item(self.font_combo, self.font_files, self.settings.font_file)
    select_combo_item(self.micro_combo, overlay_mod.MICRO_BAR_OPTIONS, self.settings.micro_bar_mode)

    for _, c in ipairs(self.combos) do
        c.last_idx = tonumber(gdi.user32.SendMessageW(c.hwnd, CB_GETCURSEL, 0, 0)) or 0
    end

    for key, ctrl in pairs(self.controls) do
        local val = self.settings[key]
        if ctrl.kind == "checkbox" then
            gdi.user32.SendMessageW(ctrl.hwnd, BM_SETCHECK, val and BST_CHECKED or BST_UNCHECKED, 0)
        elseif ctrl.kind == "slider" then
            local num = tonumber(val) or 0
            local raw_pos = math.floor(num * ctrl.scale_factor + 0.5) + ctrl.offset
            local txt = ctrl.format_val(num)
            ctrl.last_raw_pos = raw_pos
            ctrl.last_edit_text = txt
            gdi.user32.SendMessageW(ctrl.hwnd, TBM_SETPOS, 1, raw_pos)
            gdi.user32.SetWindowTextW(ctrl.val_lbl, gdi.W(txt))
        end
    end
end

function SettingsWindow:update_preview()
    if not self.preview_surface or not self.preview_renderer then return end
    self.preview_renderer:load_settings(true)
    local surf = self.preview_surface
    surf:clear(255, 22, 28, 27)
    surf:draw_rect(0, 0, surf.w - 1, surf.h - 1, 1.0, 255, 43, 59, 56)

    local target = self.preview_target or "Enemy (65% HP)"
    local sample_monster = {
        Index = 1,
        Name = "Minotaur",
        Level = 68,
        HP = 812,
        FullHP = 1250,
        ScreenX = math.floor(surf.w / 2),
        ScreenY = math.floor(surf.h / 2) - 8,
        Distance = 950,
        IsAlly = false,
        Attack1Element = "Phys",
        Spell1Icon = "Fire Bolt.png",
        Resistances = {
            Phys = 60, Fire = 110, Air = 20, Water = 50, Earth = 100,
            Spirit = 0, Mind = 120, Body = 0, Light = 75, Dark = 100,
        },
        Debuffs = {
            { Name = "Paralyze", Ratio = 0.65, Stacks = 1 },
            { Name = "ArmorHalved", Ratio = 0.40, Stacks = 1 },
            { Name = "Spear", Ratio = 1.0, Stacks = 3 },
        },
        CC_DR = {
            Mind = { Tier = 1, Ratio = 0.65, Immune = false },
            Stun = { Tier = 4, Ratio = 0.45, Immune = true },
        },
    }

    local drain_ratio = nil
    if target == "Enemy (Full HP)" then
        sample_monster.HP = 1250
    elseif target == "Enemy (65% HP)" then
        sample_monster.HP = 812
        drain_ratio = 0.82
    elseif target == "Enemy (Critical 20%)" then
        sample_monster.HP = 250
        drain_ratio = 0.45
    elseif target == "Ally Unit (fill_B)" then
        sample_monster.Name = "Royal Guard"
        sample_monster.HP = 940
        sample_monster.FullHP = 1100
        sample_monster.IsAlly = true
    elseif target == "Boss Monster" then
        sample_monster.Name = "Omnipotent Titan"
        sample_monster.Level = 120
        sample_monster.HP = 18500
        sample_monster.FullHP = 25000
        drain_ratio = 0.88
    end

    local vis = { name = true, hp_nums = true, hp_bar = true, level = true, attack = true, resistances = true }
    local anim_t = (self.preview_renderer.micro_bar_mode == "Only Micro") and 0.0 or 1.0

    self.preview_renderer:draw_bar(sample_monster, vis, {
        override_x = math.floor(surf.w / 2),
        override_y = math.floor(surf.h / 2) + 14,
        is_highlighted = true,
        size_mult = 1.0,
        bar_opacity = 255,
        drain_ratio = drain_ratio,
        drain_is_crit = false,
        anim_t = anim_t,
        now = 1.0,
        frame = surf,
    })

    if self.preview_static_hwnd then
        gdi.user32.SendMessageW(self.preview_static_hwnd, STM_SETIMAGE, IMAGE_BITMAP, ffi.cast("LPARAM", surf.hbmp))
        gdi.user32.InvalidateRect(self.preview_static_hwnd, nil, 0)
    end
end

function SettingsWindow:poll_controls()
    if self.initializing or not self.hwnd or gdi.user32.IsWindow(self.hwnd) == 0 then return end

    -- 1. Poll Push Buttons (BS_AUTOCHECKBOX | BS_PUSHLIKE latches to 1 on click)
    for _, btn in ipairs(self.buttons) do
        if gdi.user32.SendMessageW(btn.hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED then
            gdi.user32.SendMessageW(btn.hwnd, BM_SETCHECK, BST_UNCHECKED, 0)
            if btn.callback then
                btn.callback()
            end
        end
    end

    -- 2. Poll Comboboxes
    for _, c in ipairs(self.combos) do
        local idx = tonumber(gdi.user32.SendMessageW(c.hwnd, CB_GETCURSEL, 0, 0))
        if idx and idx >= 0 and idx ~= c.last_idx then
            c.last_idx = idx
            if c.items[idx + 1] and c.on_change then
                c.on_change(c.items[idx + 1], idx + 1)
            end
        end
    end

    -- 3. Poll Checkboxes & Sliders
    local changed = false
    for key, ctrl in pairs(self.controls) do
        if ctrl.kind == "checkbox" then
            local checked = (gdi.user32.SendMessageW(ctrl.hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED)
            local cur = self.settings[key] and true or false
            if checked ~= cur then
                self.settings[key] = checked
                changed = true
            end
        elseif ctrl.kind == "slider" then
            local raw_pos = tonumber(gdi.user32.SendMessageW(ctrl.hwnd, TBM_GETPOS, 0, 0))
            if raw_pos and raw_pos ~= ctrl.last_raw_pos then
                ctrl.last_raw_pos = raw_pos
                local real_val = (raw_pos - ctrl.offset) / ctrl.scale_factor
                local txt = ctrl.format_val(real_val)
                ctrl.last_edit_text = txt
                self.settings[key] = real_val
                gdi.user32.SetWindowTextW(ctrl.val_lbl, gdi.W(txt))
                changed = true
            elseif ctrl.editable then
                gdi.user32.GetWindowTextW(ctrl.val_lbl, shared_edit_buf, 63)
                local raw_txt = (gdi.from_W(shared_edit_buf) or ""):match("^%s*(.-)%s*$")
                if raw_txt ~= ctrl.last_edit_text then
                    local num = tonumber(raw_txt)
                    if num then
                        num = math.max(ctrl.min_val, math.min(ctrl.max_val, num))
                        local clamped_raw = math.floor(num * ctrl.scale_factor + 0.5) + ctrl.offset
                        ctrl.last_raw_pos = clamped_raw
                        ctrl.last_edit_text = raw_txt
                        self.settings[key] = num
                        gdi.user32.SendMessageW(ctrl.hwnd, TBM_SETPOS, 1, clamped_raw)
                        changed = true
                    end
                end
            end
        end
    end

    if changed then
        self:save_settings()
    end
end

function SettingsWindow:cleanup()
    if self.preview_surface then
        self.preview_surface:dispose()
        self.preview_surface = nil
    end
    for _, sw in pairs(self.swatches) do
        if sw.surf then
            sw.surf:dispose()
            sw.surf = nil
        end
    end
end

local shared_msg = ffi.new("MSG")

function M.pump_messages()
    if not active_settings_win or not active_settings_win.hwnd then return false end
    if gdi.user32.IsWindow(active_settings_win.hwnd) == 0 then
        active_settings_win:cleanup()
        active_settings_win = nil
        return false
    end
    -- Only pump PeekMessageW when running standalone outside mm8.exe
    if not _G.events then
        while gdi.user32.PeekMessageW(shared_msg, active_settings_win.hwnd, 0, 0, 1) ~= 0 do
            gdi.user32.TranslateMessage(shared_msg)
            gdi.user32.DispatchMessageW(shared_msg)
        end
    end
    if active_settings_win and active_settings_win.hwnd and gdi.user32.IsWindow(active_settings_win.hwnd) ~= 0 then
        active_settings_win:poll_controls()
        return true
    end
    return false
end

gdi.disable_jit(SettingsWindow)
gdi.disable_jit(M)

return M
