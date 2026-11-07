-- zzzMaw_Autosave.lua: presses the quick save key (MM8.ini, F11) after the chosen minutes, only when saving is safe.
-- Run with any Lua 5.1 / LuaJIT:   lua autosave_test.lua ../../Scripts/General/zzzMaw_Autosave.lua
-- args: module path
local modulePath = ...

local posted = {}
local clock = 0
os.clock = function() return clock end
mem = {dll = {user32 = {PostMessageA = function(hwnd, msg, key) posted[#posted + 1] = {hwnd, msg, key} end}}}
Game = {WindowHandle = 77, CurrentScreen = 0, TurnBased = 0, LoadingScreen = false}
Party = setmetatable({}, {__call = function(self, _, i)
	i = (i == nil) and 0 or i + 1
	if self[i + 1] then return i, self[i + 1] end
end})
Party[1] = {Dead = 0, Eradicated = 0, Stoned = 0}
Party.EnemyDetectorRed = false

local handlers = {}
events = setmetatable({}, {__newindex = function(_, k, v) handlers[k] = handlers[k] or {}; table.insert(handlers[k], v) end})
local fails = {}
local function check(cond, msg) if not cond then fails[#fails + 1] = msg end end

dofile(modulePath)
check(MawAutosave.Minutes == 0, "default off")
clock = 10000
MawAutosave.Tick()
check(#posted == 0, "off: nothing is pressed")

MawAutosave.Set(3)
clock = clock + 179
MawAutosave.Tick()
check(#posted == 0, "not yet after 179 s")
clock = clock + 2
MawAutosave.Tick()
check(#posted == 2 and posted[1][2] == 0x100 and posted[1][3] == 0x7A and posted[2][2] == 0x101 and posted[1][1] == 77, "quick save key (F11) down and up after 3 minutes: " .. #posted)

posted = {}
clock = clock + 180
Game.CurrentScreen = 21
MawAutosave.Tick()
check(#posted == 0, "no save on another screen")
Game.CurrentScreen = 0
clock = clock + 5
MawAutosave.Tick()
check(#posted == 0, "retry only after 10 seconds")
clock = clock + 6
Party.EnemyDetectorRed = true
MawAutosave.Tick()
check(#posted == 0, "no save with an enemy near")
Party.EnemyDetectorRed = false
Game.TurnBased = 1
clock = clock + 11
MawAutosave.Tick()
check(#posted == 0, "no save in turn-based mode")
Game.TurnBased = 0
clock = clock + 11
MawAutosave.Tick()
check(#posted == 2, "saves when it is safe again")

-- save before a fight: an enemy comes near and nothing was saved for 5 minutes
MawAutosave.Set(0)
posted = {}
local function fight()  -- the detector goes off for one tick, then on again: a new fight starts
	Party.EnemyDetectorRed = false
	MawAutosave.Tick()
	Party.EnemyDetectorRed = true
	MawAutosave.Tick()
end
clock = clock + 1000
fight()
check(#posted == 0, "combat option off: nothing is pressed")
check(MawAutosave.Combat == false, "combat option default off")
MawAutosave.SetCombat(true)
clock = clock + 1000
fight()
check(#posted == 2 and posted[1][3] == 0x7A, "fight with the option on and no save for a long time: quick save: " .. #posted)
posted = {}
clock = clock + 100
fight()
check(#posted == 0, "no second save within 5 minutes")
clock = clock + 201
fight()
check(#posted == 2, "saves again 5 minutes after the last save")
posted = {}
clock = clock + 400
Party.EnemyDetectorRed = true
MawAutosave.Tick()
check(#posted == 0, "an enemy that stays near is one fight, not a new one")
handlers.AfterSaveGame[1]()  -- a hand-made save
clock = clock + 100
fight()
check(#posted == 0, "a hand-made save 100 s ago: no autosave")
clock = clock + 201
fight()
check(#posted == 2, "5 minutes after the hand-made save: autosave")
posted = {}
clock = clock + 400
Game.CurrentScreen = 21
fight()
check(#posted == 0, "no save on another screen")
Game.CurrentScreen = 0
Game.LoadingScreen = true
clock = clock + 400
fight()
check(#posted == 0, "no save while a map is loading")
Game.LoadingScreen = false
Game.TurnBased = 1
clock = clock + 400
fight()
check(#posted == 0, "no save in turn-based mode")
Game.TurnBased = 0
Party[1].Dead = 1
clock = clock + 400
fight()
check(#posted == 0, "no save with a dead party")
Party[1].Dead = 0
clock = clock + 400
handlers.LoadMap[1](false)  -- a game was loaded
fight()
check(#posted == 0, "a loaded game counts as saved")
clock = clock + 400
handlers.LoadMap[1](true)  -- travel to another map: the old save time stays
fight()
check(#posted == 2, "after travelling the old save time counts")
Party.EnemyDetectorRed = false
MawAutosave.Tick()
-- travelling does not restart the timer of the periodic autosave
posted = {}
MawAutosave.Set(3)
clock = clock + 120
handlers.LoadMap[1](true)
clock = clock + 61
MawAutosave.Tick()
check(#posted == 2, "travelling to another map keeps the timer: " .. #posted)
-- any save restarts the timer of the periodic autosave
posted = {}
MawAutosave.SetCombat(false)
MawAutosave.Set(3)
clock = clock + 170
handlers.AfterSaveGame[1]()
clock = clock + 170
MawAutosave.Tick()
check(#posted == 0, "the timer starts again after a save")
clock = clock + 11
MawAutosave.Tick()
check(#posted == 2, "the periodic autosave comes 3 minutes after the last save")

local result = (#fails > 0) and ("FAIL " .. table.concat(fails, " | ")) or "OK autosave timing, safety and fight checks"
print(result)
return result
