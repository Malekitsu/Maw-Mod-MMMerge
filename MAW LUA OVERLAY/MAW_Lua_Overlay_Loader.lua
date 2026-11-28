-- ============================================================================
-- MAW_Lua_Overlay_Loader.lua
-- Integration & Standalone Runner for the Pure Lua Monster HP Overlay
-- and Native Win32 Settings Window.
--
-- Can be loaded inside MM8 / MMExtension:
--   dofile(AppPath .. "MAW LUA OVERLAY\\MAW_Lua_Overlay_Loader.lua")
-- Or controlled anytime from Lua / Console / MenuExtraSettings:
--   MAW_LuaOverlay.Start()
--   MAW_LuaOverlay.Stop()
--   MAW_LuaOverlay.Toggle()
--   MAW_LuaOverlay.OpenSettings()
-- ============================================================================

if jit and jit.off then
    jit.off(true, true)
end

local ffi = require("ffi")

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

-- If an old overlay instance was active, destroy its window cleanly before reloading
if _G.MAW_LuaOverlay and _G.MAW_LuaOverlay.Destroy then
    pcall(_G.MAW_LuaOverlay.Destroy)
end
_G._MAW_WIN32_GDIPLUS_MOD = nil
_G._MAW_OVERLAY_MOD = nil
_G._MAW_SETTINGS_MOD = nil

local SCRIPT_DIR = get_script_dir()
local gdi = dofile(SCRIPT_DIR .. "\\win32_gdiplus.lua")
local overlay_mod = dofile(SCRIPT_DIR .. "\\MAW_Overlay.lua")
local settings_mod = dofile(SCRIPT_DIR .. "\\Overlay_Settings.lua")

local M = {}
_G.MAW_LuaOverlay = M

M.app = nil
M.enabled = false

local function read_settings()
    local f = io.open(overlay_mod.SETTINGS_FILE, "rb")
    if not f then return {} end
    local raw = f:read("*a")
    f:close()
    local ok, s = pcall(gdi.json_decode, raw)
    return (ok and type(s) == "table") and s or {}
end

local wanted = read_settings().enabled == true

function M.IsEnabled()
    return wanted
end

function M.SetEnabled(on)
    wanted = on and true or false
    local s = read_settings()
    s.enabled = wanted
    local f = io.open(overlay_mod.SETTINGS_FILE, "wb")
    if f then
        f:write(gdi.json_encode(s))
        f:close()
    end
end

M.Options = setmetatable({}, {
    __index = function(_, key)
        if key == "Enabled" then
            return wanted and "ON" or "OFF"
        end
    end,
    __newindex = function(_, key, value)
        if key == "Enabled" then
            M.SetEnabled(value == "ON")
        end
    end,
})

function M.Start()
    if not M.app then
        M.app = overlay_mod.new_overlay_app(false)
        M.app.on_open_settings = function()
            M.OpenSettings()
        end
    elseif M.app.win then
        M.app.win:set_visible(true)
    end
    M.enabled = true
    return "MAW Lua Overlay: ON"
end

function M.Stop()
    M.enabled = false
    if M.app and M.app.win then
        M.app.win:set_visible(false)
    end
    return "MAW Lua Overlay: OFF"
end

function M.Destroy()
    M.enabled = false
    if M.app then
        M.app:destroy()
        M.app = nil
    end
    return "MAW Lua Overlay: Destroyed"
end

function M.Toggle()
    if not M.app or not M.app.win or not M.app.win.visible then
        M.Start()
        return true
    else
        M.Stop()
        return false
    end
end

function M.IsRunning()
    return (M.app ~= nil and M.app.win ~= nil and M.app.win.visible == true)
end

function M.OpenSettings()
    settings_mod.show_settings_window(M.app)
    return "MAW Lua Overlay Settings Opened"
end

local last_tick_time = 0
function M.Tick(external_game_data)
    if _G.events and wanted ~= M.enabled then
        if wanted then M.Start() else M.Stop() end
    end
    local now = gdi.now()
    -- Throttle overlay & settings polling to ~40 FPS (every 25ms) for smooth rendering with minimal overhead
    if now - last_tick_time < 0.025 then return end
    last_tick_time = now

    settings_mod.pump_messages()
    if M.enabled and M.app then
        M.app:step(external_game_data or _G.MAW_Overlay_LiveData)
    elseif M.app and M.app.win then
        M.app.win:pump_events(M.app)
    end
end

-- ============================================================================
-- MMExtension In-Game Hook (if loaded inside Might & Magic 8 / MAW)
-- ============================================================================
if _G.events then
    function events.Tick()
        M.Tick(_G.MAW_Overlay_LiveData)
    end
    if jit and jit.off then
        pcall(jit.off, events.Tick, true)
    end

    function events.KeyDown(t)
        if t and t.Key == const.Keys.F12 and Game.CurrentScreen == 0 then
            M.SetEnabled(not wanted)
            Game.ShowStatusText(wanted and "Monster HP bars: ON" or "Monster HP bars: OFF")
        end
    end
    if jit and jit.off then
        pcall(jit.off, events.KeyDown, true)
    end

    function events.LeaveGame()
        M.Destroy()
    end
    if jit and jit.off then
        pcall(jit.off, events.LeaveGame, true)
    end
else
    -- Standalone mode if executed outside the game via LuaJIT
    local args = { ... }
    local settings_only = false
    for _, a in ipairs(args) do
        if a == "--settings" or a == "-s" then
            settings_only = true
        end
    end

    if settings_only then
        M.OpenSettings()
        while settings_mod.pump_messages() do
            gdi.kernel32.Sleep(16)
        end
    else
        M.Start()
        M.app.running = true
        while M.app and M.app.running do
            M.Tick()
            gdi.kernel32.Sleep(16)
        end
        M.Destroy()
    end
end

gdi.disable_jit(M)

return M
