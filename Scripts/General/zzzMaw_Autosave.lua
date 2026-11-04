-- Autosave: saves the game every few minutes (settings page "Autosave" in the extra settings: Off / 3 / 5 / 10 minutes,
-- remembered in the registry). It presses the quick save key for the player (QuickSavesKey of MM8.ini, F11 by default), so the game's own
-- save routine runs and the save is a quick save like a hand-made one (the patch keeps QuickSavesCount of them).
--
-- Saved only when it is safe: the main game screen is shown (no dialog, shop, menu), no turn-based fight, no enemy
-- nearby (the red enemy detector), the party is not dead. Otherwise it tries again after 10 seconds. The time counts in
-- real time while the game runs. Default: off.
--
-- Second option "Save before a fight" (own switch on the same page, default off): when an enemy comes near (the red
-- enemy detector turns on) and nothing was saved for 5 minutes (by hand, quick save or autosave), the game is saved
-- right then. A save of any kind starts the counting again, also for the timer above.

local MF = Merge and Merge.Functions
local REG_KEY = "maw_autosave_minutes"
local REG_KEY_COMBAT = "maw_autosave_combat"
local COMBAT_GAP = 300  -- seconds without a save before a fight starts
local CHOICES = {0, 3, 5, 10}
local RETRY = 10  -- seconds until the next try when saving is not safe now
local DEFAULT_KEY = 0x7A  -- F11, the default of QuickSavesKey in MM8.ini

MawAutosave = {Minutes = 0, Combat = false}

local TEXT = {
	de = {header = " Autosave", label = "Autosave: %s", off = "Aus", minutes = "alle %d Min",
		combat = "Speichern vor Kampf: %s", on = "An"},
	en = {header = " Autosave", label = "Autosave: %s", off = "Off", minutes = "every %d min",
		combat = "Save before a fight: %s", on = "On"},
}

local function lang()
	return (MawLanguage and MawLanguage.Active == "de") and "de" or "en"
end

local function optionText(minutes)
	local t = TEXT[lang()]
	return minutes > 0 and t.minutes:format(minutes) or t.off
end

local function enemyNear()
	local ok, result = pcall(function()
		return Party.EnemyDetectorRed == true or Party.EnemyDetectorRed == 1
	end)
	return ok and result
end

-- the main game screen is shown, no turn-based fight, someone is alive (an enemy may be near)
local function playable()
	local ok, result = pcall(function()
		if Game.CurrentScreen ~= 0 then
			return false
		end
		if Game.TurnBased == 1 or Game.TurnBased == true then
			return false
		end
		for _, pl in Party do
			if pl.Dead == 0 and pl.Eradicated == 0 and pl.Stoned == 0 then
				return true
			end
		end
		return false
	end)
	return ok and result
end

local function safe()
	return playable() and not enemyNear()
end

-- the key code of the quick save: QuickSavesKey in MM8.ini (0 = quick saves off, then nothing is pressed)
local function quickSaveKey()
	local f = io.open((AppPath or "") .. "MM8.ini", "rb")
	if f then
		local text = f:read("*all")
		f:close()
		local value = text:match("[\r\n]%s*QuickSavesKey%s*=%s*(%d+)")
		if value then
			return tonumber(value)
		end
	end
	return DEFAULT_KEY
end

-- presses the quick save key in the game window
local function pressQuickSave()
	local key = quickSaveKey()
	if key == 0 then
		return
	end
	local user32 = mem.dll.user32
	local scan = user32.MapVirtualKeyA and user32.MapVirtualKeyA(key, 0) or 0
	user32.PostMessageA(Game.WindowHandle, 0x100, key, 1 + scan * 65536)  -- WM_KEYDOWN
	user32.PostMessageA(Game.WindowHandle, 0x101, key, 0xC0000001 + scan * 65536)  -- WM_KEYUP
end
MawAutosave.Press = pressQuickSave

local dueAt  -- os.clock() time of the next save, nil while off
local function schedule(seconds)
	dueAt = (MawAutosave.Minutes > 0) and (os.clock() + (seconds or MawAutosave.Minutes * 60)) or nil
end

local lastSave = os.clock()  -- os.clock() time of the last save of any kind
local wasNear = false

-- an enemy comes near and nothing was saved for COMBAT_GAP seconds: save now
local function combatCheck(now)
	local near = enemyNear()
	local started = near and not wasNear
	wasNear = near
	if started and MawAutosave.Combat and now - lastSave >= COMBAT_GAP and playable() then
		if pcall(pressQuickSave) then
			lastSave = now  -- the save itself is reported by AfterSaveGame; this stops a second try within the same fight
			schedule()
		end
	end
end

function MawAutosave.Tick()
	combatCheck(os.clock())
	if not dueAt or os.clock() < dueAt then
		return
	end
	if safe() then
		if pcall(pressQuickSave) then
			schedule()
		else
			schedule(RETRY)
		end
	else
		schedule(RETRY)
	end
end

function events.Tick()
	MawAutosave.Tick()
end

function events.AfterSaveGame()  -- every save: hand-made, quick save, autosave
	lastSave = os.clock()
	schedule()
end

function MawAutosave.SetCombat(on)
	MawAutosave.Combat = on and true or false
	if MF and MF.SetRegistryValue then
		pcall(MF.SetRegistryValue, REG_KEY_COMBAT, MawAutosave.Combat and 1 or 0)
	end
end

function MawAutosave.Set(minutes)
	MawAutosave.Minutes = minutes
	schedule()
	if MF and MF.SetRegistryValue then
		pcall(MF.SetRegistryValue, REG_KEY, minutes)
	end
end

function events.GameInitialized2()
	if MF and MF.GetRegistryValue then
		local ok, v = pcall(MF.GetRegistryValue, REG_KEY, 0)
		if ok and type(v) == "number" then
			MawAutosave.Minutes = v
		end
		ok, v = pcall(MF.GetRegistryValue, REG_KEY_COMBAT, 0)
		MawAutosave.Combat = ok and v == 1
	end
	schedule()
	if not CustomUI or not CustomUI.NewSettingsPage then
		return
	end
	local Screen = CustomUI.NewSettingsPage("MawAutosaveSettings", TEXT[lang()].header, "ExSetScr2")
	local label, combatLabel
	local function refresh()
		label.Text = " " .. TEXT[lang()].label:format(optionText(MawAutosave.Minutes))
		combatLabel.Text = " " .. TEXT[lang()].combat:format(MawAutosave.Combat and TEXT[lang()].on or TEXT[lang()].off)
	end
	label = CustomUI.CreateText{
		Text = " ", X = 120, Y = 160, AlignLeft = true, Layer = 0, Screen = Screen, Font = Game.Lucida_fnt, Width = 440, Height = 20,
		Action = function()
			local index = 1
			for i, m in ipairs(CHOICES) do
				if m == MawAutosave.Minutes then
					index = i
				end
			end
			MawAutosave.Set(CHOICES[index % #CHOICES + 1])
			Game.PlaySound(25)
			refresh()
		end}
	combatLabel = CustomUI.CreateText{
		Text = " ", X = 120, Y = 190, AlignLeft = true, Layer = 0, Screen = Screen, Font = Game.Lucida_fnt, Width = 440, Height = 20,
		Action = function()
			MawAutosave.SetCombat(not MawAutosave.Combat)
			Game.PlaySound(25)
			refresh()
		end}
	function events.OpenExtraSettingsMenu()
		refresh()
	end
	refresh()
end

function events.LoadMap(wasInGame)  -- a new map or a loaded game: count from here
	schedule()
	wasNear = false
	if wasInGame == false then  -- a loaded game is as good as saved
		lastSave = os.clock()
	end
end
