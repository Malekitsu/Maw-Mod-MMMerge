-- MAW Settings Loader
-- This script loads settings from the external MAWSettings.lua file

local function createDefaultSettingsFile(settingsPath)
    local defaultSettings = [[-- MAW Settings Configuration File
-- This file stores all configurable settings for the Might and Magic 8 ONLINE mod
-- Edit these values to customize your gameplay experience

return {
    -- Healing and Combat
    autoTargetHeals = true,             -- makes your healing spells automatically target with lowest % HP
    disableBow = false,                 -- useful for a melee only challenge
    enableDisintegrate = true,          -- in insanery only, taking too much damage disintegrates your character
    
    -- User Interface
    ColouredStats = true,               -- stats menu has more colours
    showDeathCounter = true,            -- Beyond Madness only, death counter is shown
    disableCompletitionMessage = false, -- disable completion messages (recommended for online play)
	disableSpellBookRework = false,      -- disable the new book skin
    
    -- Hotkeys
    removeBuffsKey = 82,                -- remove all buffs when spellbook is open (default: R)
    chargeKey = 69,                     -- charge ability for knights when solo (default: E)  
    healthPotionKey = 71,               -- quickly consume red potion (default: G)
    manaPotionKey = 86,                 -- quickly consume blue potion (default: V)
    
    -- Sorting Hotkeys
    currentBagSortKey = 82,             -- sort current bag (default: R)
    partyBagSortKey = 84,               -- sort party bag (default: T)
    multiBagSortKey = 67,               -- sort multiple bags (default: C)
    partyMultyBagSortKey = 71,          -- sort party multiple bags (default: G)
    AlchemyBagKey = 69,                 -- alchemy bag key (default: E)
    
    -- Gameplay Features
    higherLootPowerRange = true,        -- enchants range from 1-100 instead of tier-based ranges
    enableAllTrainers = true,           -- find trainers that weren't previously available in all continents
    onlineQualityOfLifeFeatures = true, -- remove travel/training time, coaches/ships always available
	teleportDeadMonstersAndCraftingKey = 75, -- teleports up to 30 monsters and 30 crafting items to the player location
    
    -- Movement
    fasterStrafing = true,              -- faster strafing speed
    slowerBackpedaling = true,          -- slower backpedaling speed
}

-----------------------------
----HERE IS THE KEYBIND LIST--
-----------------------------
--LBUTTON= 1	
--RBUTTON= 2	
--CANCEL= 3	
--MBUTTON= 4	NOT contiguous with L & RBUTTON
--XBUTTON1= 5	
--XBUTTON2= 6	
--BACK= 8	
--BACKSPACE= 8	
--TAB= 9	
--CLEAR= 12	
--ENTER= 13	
--RETURN= 13	
--SHIFT= 16	
--CONTROL= 17	
--CTRL= 17	
--ALT= 18	
--MENU= 18	
--PAUSE= 19	
--CAPITAL= 20	
--CAPSLOCK= 20	
--HANGUL= 21	
--KANA= 21	
--JUNJA= 23	
--FINAL= 24	
--HANJA= 25	
--KANJI= 25	
--ESCAPE= 27	
--CONVERT= 28	
--NONCONVERT= 29	
--ACCEPT= 30	
--MODECHANGE= 31	
--SPACE= 32	
--PGUP= 33	
--PRIOR= 33	
--NEXT= 34	
--PGDN= 34	
--end= 35	
--HOME= 36	
--LEFT= 37	
--UP= 38	
--RIGHT= 39	
--DOWN= 40	
--SELECT= 41	
--PRINT= 42	
--EXECUTE= 43	
--SNAPSHOT= 44	
--INSERT= 45	
--DELETE= 46	
--HELP= 47	
--0= 48	
--1= 49	
--2= 50	
--3= 51	
--4= 52	
--5= 53	
--6= 54	
--7= 55	
--8= 56	
--9= 57	
--A= 65	
--B= 66	
--C= 67	
--D= 68	
--E= 69	
--F= 70	
--G= 71	
--H= 72	
--I= 73	
--J= 74	
--K= 75	
--L= 76	
--M= 77	
--N= 78	
--O= 79	
--P= 80	
--Q= 81	
--R= 82	
--S= 83	
--T= 84	
--U= 85	
--V= 86	
--W= 87	
--X= 88	
--Y= 89	
--Z= 90	
--LWIN= 91	
--RWIN= 92	
--APPS= 93	
--SLEEP= 95	
--NUMPAD0= 96	
--NUMPAD1= 97	
--NUMPAD2= 98	
--NUMPAD3= 99	
--NUMPAD4= 100	
--NUMPAD5= 101	
--NUMPAD6= 102	
--NUMPAD7= 103	
--NUMPAD8= 104	
--NUMPAD9= 105	
--MULTIPLY= 106	
--ADD= 107	
--SEPARATOR= 108	
--SUBTRACT= 109	
--DECIMAL= 110	
--DIVIDE= 111	
--F1= 112	
--F2= 113	
--F3= 114	
--F4= 115	
--F5= 116	
--F6= 117	
--F7= 118	
--F8= 119	
--F9= 120	
--F10= 121	
--F11= 122	
--F12= 123	
--F13= 124	
--F14= 125	
--F15= 126	
--F16= 127	
--F17= 128	
--F18= 129	
--F19= 130	
--F20= 131	
--F21= 132	
--F22= 133	
--F23= 134	
--F24= 135	
--NUMLOCK= 144	
--SCROLL= 145	
--SCROLLLOCK= 145	
--LSHIFT= 160	
--RSHIFT= 161	
--LCONTROL= 162	
--RCONTROL= 163	
--LMENU= 164	
--RMENU= 165	
--BROWSER_BACK= 166	
--BROWSER_FORWARD= 167	
--BROWSER_REFRESH= 168	
--BROWSER_STOP= 169	
--BROWSER_SEARCH= 170	
--BROWSER_FAVORITES= 171	
--BROWSER_HOME= 172	
--VOLUME_MUTE= 173	
--VOLUME_DOWN= 174	
--VOLUME_UP= 175	
--MEDIA_NEXT_TRACK= 176	
--MEDIA_PREV_TRACK= 177	
--MEDIA_STOP= 178	
--MEDIA_PLAY_PAUSE= 179	
--LAUNCH_MAIL= 180	
--LAUNCH_MEDIA_SELECT= 181	
--LAUNCH_APP1= 182	
--LAUNCH_APP2= 183	
--OEM_1= 186	
--OEM_PLUS= 187	
--OEM_COMMA= 188	
--OEM_MINUS= 189	
--OEM_PERIOD= 190	
--OEM_2= 191	
--OEM_3= 192	
--OEM_4= 219	
--OEM_5= 220	
--OEM_6= 221	
--OEM_7= 222	
--OEM_8= 223	
--OEM_102= 226	
--PROCESSKEY= 229	
--PACKET= 231	
--ATTN= 246	
--CRSEL= 247	
--EXSEL= 248	
--EREOF= 249	
--PLAY= 250	
--ZOOM= 251	
--NONAME= 252	
--PA1= 253	
--OEM_CLEAR= 254
]]
    
    local file = io.open(settingsPath, "w")
    if file then
        file:write(defaultSettings)
        file:close()
        print("Created default MAWSettings.lua file")
        return true
    else
        print("Error: Could not create MAWSettings.lua file")
        return false
    end
end

local function loadMAWSettings()
    local settingsPath = "MAWSettings.lua"
    
    -- Try to load existing settings file
    local settingsFile = io.open(settingsPath, "r")
    if settingsFile then
        settingsFile:close()
        print("Loading MAW settings from " .. settingsPath)
        
        -- Load the settings using dofile
        local success, settings = pcall(dofile, settingsPath)
        if success and type(settings) == "table" then
            return settings
        else
            print("Error loading settings file, using fallback defaults...")
            -- Don't overwrite existing file, just use fallback
        end
    else
        print("MAWSettings.lua not found, creating default file...")
        -- Only create file if it doesn't exist
        if createDefaultSettingsFile(settingsPath) then
            local success, settings = pcall(dofile, settingsPath)
            if success and type(settings) == "table" then
                return settings
            end
        end
    end
end

-- Load settings and assign to global variables
local mawSettings = loadMAWSettings()

-- Assign settings to global variables for compatibility
autoTargetHeals = mawSettings.autoTargetHeals
ColouredStats = mawSettings.ColouredStats
removeBuffsKey = mawSettings.removeBuffsKey
chargeKey = mawSettings.chargeKey
healthPotionKey = mawSettings.healthPotionKey
manaPotionKey = mawSettings.manaPotionKey
higherLootPowerRange = mawSettings.higherLootPowerRange
disableBow = mawSettings.disableBow
enableAllTrainers = mawSettings.enableAllTrainers
enableDisintegrate = mawSettings.enableDisintegrate
disableCompletitionMessage = mawSettings.disableCompletitionMessage
onlineQualityOfLifeFeatures = mawSettings.onlineQualityOfLifeFeatures
showDeathCounter = mawSettings.showDeathCounter
fasterStrafing = mawSettings.fasterStrafing
slowerBackpedaling = mawSettings.slowerBackpedaling
currentBagSortKey = mawSettings.currentBagSortKey
partyBagSortKey = mawSettings.partyBagSortKey
multiBagSortKey = mawSettings.multiBagSortKey
partyMultyBagSortKey = mawSettings.partyMultyBagSortKey
AlchemyBagKey = mawSettings.AlchemyBagKey
disableSpellBookRework = mawSettings.disableSpellBookRework
teleportDeadMonstersAndCraftingKey = mawSettings.teleportDeadMonstersAndCraftingKey

-- Store settings in vars for access by other scripts
function events.LoadMap()
	vars.MAWINITSETTINGS = mawSettings
end

--needed to fix some weird bug, don't touch this
Game.PatchOptions.FixMonstersBlockingShots=true

function events.GameInitialized2()
	if Game.ItemsTxt[1466].Name=="Emerald Island" then
		isRedone=true
	end
	for i=0,11 do
		Skillz.setDesc(i,1,Skillz.getDesc(i,1) .. "\n")
	end
end

--custom rounding function, as math.round is capped to 2^32
function round(x)
	if x%1>=0.5 then
		x=x-x%1+1
	else
		x=x-x%1
	end
	return x
end
--[[
function shortenNumber(number, significantDigits, color)
    if significantDigits < 1 then
        error("Number of digits needs to be at least 1")
    end

    local suffix = ""
    local divisor = 1

    if math.abs(number) >= 10^(9+math.max(0,significantDigits-3)) then
        suffix = "B"
        divisor = 1e9
    elseif math.abs(number) >= 10^(6+math.max(0,significantDigits-3)) then
        suffix = "M"
        divisor = 1e6
    elseif math.abs(number) >= 10^(3+math.max(0,significantDigits-3)) then
        suffix = "K"
        divisor = 1e3
    end

    local shortened = round(number / divisor)
	if color then
		if suffix == "K" then
			local txt=StrColor(255,255,30,tostring(shortened) .. suffix)
			return txt
		end
		if suffix == "M" then
			local txt=StrColor(255,165,0,tostring(shortened) .. suffix)
			return txt
		end
		if suffix == "B" then
			local txt=StrColor(255,0,0,tostring(shortened) .. suffix)
			return txt
		end
	end
	
    return tostring(shortened) .. suffix
end
]]
function shortenNumber(number, significantDigits, color)
    if significantDigits < 1 then
        error("Number of digits needs to be at least 1")
    end

    -- helpers
    local function roundTo(x, decimals)
        local p = 10 ^ (decimals or 0)
        if x >= 0 then return math.floor(x * p + 0.5) / p
        else return math.ceil(x * p - 0.5) / p end
    end
    local function intDigits(x)
        x = math.floor(math.abs(x))
        if x == 0 then return 1 end
        local d = 0
        while x > 0 do x = math.floor(x / 10); d = d + 1 end
        return d
    end
    local function fmtTrim(x)
        -- stringify and trim trailing zeros in decimals (and trailing dot)
        local s = string.format("%.10f", x)  -- enough precision buffer
        s = s:gsub("(%..-)[0]*$", "%1"):gsub("%.$", "")
        -- also trim superfluous extra decimals if we had fewer
        return s
    end

    local absn = math.abs(number)
    local suffix, divisor = "", 1
    if absn >= 1e9 then
        suffix, divisor = "B", 1e9
    elseif absn >= 1e6 then
        suffix, divisor = "M", 1e6
    elseif absn >= 1e3 then
        suffix, divisor = "K", 1e3
    end

    local val = number / divisor

    -- if no suffix, keep it simple: integers only, no padding
    if divisor == 1 then
        local shortened = tostring(math.floor(val + (val>=0 and 0.5 or -0.5)))
        return shortened
    end

    -- with suffix: choose decimals so that intDigits + decimals >= significantDigits
    local id = intDigits(val)
    local decimals = math.max(0, significantDigits - id)

    -- round to that many decimals
    local rounded = roundTo(val, decimals)

    -- if rounding bumps us to 1000, carry to next suffix
    if rounded >= 1000 and suffix ~= "B" then
        rounded = rounded / 1000
        if suffix == "K" then suffix = "M"
        elseif suffix == "M" then suffix = "B" end
        -- recompute digits/decimals for new scale
        id = intDigits(rounded)
        decimals = math.max(0, significantDigits - id)
        rounded = roundTo(rounded, decimals)
    end

    local numStr = fmtTrim(string.format("%." .. decimals .. "f", rounded))  -- trim trailing zeros

    if color then
        if suffix == "K" then
            return StrColor(255,255,30, numStr .. suffix)
        elseif suffix == "M" then
            return StrColor(255,165,0, numStr .. suffix)
        elseif suffix == "B" then
            return StrColor(255,0,0, numStr .. suffix)
        end
    end
    return numStr .. suffix
end


function GetMaxHP(pl)
	if vars.MAWSETTINGS.buffRework=="ON" and vars.currentHPPool then
		local id=pl:GetIndex()
		for i=0, Party.High do
			if Party[i]:GetIndex()==id then
				if vars.currentHPPool[i] then
					return math.max(round(vars.currentHPPool[i]), 1)
				end
			end
		end
	end	
	return pl:GetFullHP()
end

local TextCounter = 0
local function SimpleText(Screen, Text, X, Y, Font, Condition, Action, AlignLeft, Layer)
	TextCounter = TextCounter + 1

	if AlignLeft == nil then
		AlignLeft = true
	end

	return CustomUI.CreateText{
		Key = "MUI_" .. tostring(TextCounter),
		Text = Text,
		Font = Font or Game.Arrus_fnt,
		X = X, Y = Y,
		ColorStd = 0xFFFF,
		ColorMouseOver = Action and 0xe664 or 0xFFFF,
		Layer = Layer or 1,
		Screen = Screen,
		AlignLeft = AlignLeft,
		Condition = Condition,
		Action = Action
	}
end
local function CustomSwitch(Screen, X, Y, Condition, Header, Parent, Field, Options)
    local Option = {
        ValueSource = {Parent = Parent, Field = Field},
        Options = Options or {"Option 1", "Option 2"},
    }

    -- Handles switching between options
    local function Handler(self, side)
        local src = self.ValueSource
        local currentIndex = nil

        -- Find the current index of the value
        for i, v in ipairs(self.Options) do
            if v == src.Parent[src.Field] then
                currentIndex = i
                break
            end
        end

        -- Calculate the next index based on direction (-1 for left, +1 for right)
        currentIndex = (currentIndex or 1) + side
        if currentIndex < 1 then currentIndex = #self.Options end
        if currentIndex > #self.Options then currentIndex = 1 end

        -- Update the value in the parent and UI
        src.Parent[src.Field] = self.Options[currentIndex]
        self.Value.Text = " " .. self.Options[currentIndex] .. " "
        self.Value:UpdateSize()
    end

    -- Updates the UI element to reflect the current value
    local function Update(self)
        local src = self.ValueSource
        local val = src.Parent[src.Field]
        self.Value.Text = " " .. tostring(val) .. " "
    end

    -- Create the UI elements
    Option.Header = SimpleText(Screen, Header, X, Y, nil, Condition)

    Option.Left = SimpleText(Screen, "<",
        400 , Y, nil, Condition, function() Handler(Option, -1) end, false)

    Option.Value = SimpleText(Screen, " " .. tostring(Parent[Field]) .. " ",
        450, Y, nil, Condition, nil, false)

    Option.Right = SimpleText(Screen, ">",
        520, Y, nil, Condition, function() Handler(Option, 1) end, false)

    Option.Update = Update

    return Option
end

local mawSettings={
	buffRework="ON",
	restoreProjectiles="ON",
	homingProjectiles="ON",
	friendlyDamage="OFF",
	lootFilter="OFF",
}
local defaultSettings=mawSettings

function events.MultiplayerInitialized()
    local ScreenId = 111
	local mawSettingsButton={}
    local function createSwitch(Y, Header, Field, Options)
        mawSettingsButton[#mawSettingsButton + 1] = CustomSwitch(ScreenId, 120, Y, nil,
            StrColor(255, 255, 150) .. Header .. StrColor(255, 255, 255),
            mawSettings, Field, Options)
    end

    -- Define switches
    createSwitch(180, "Buff Rework", "buffRework", {"ON","OFF"})
    createSwitch(220, "M&M6 Projectiles", "restoreProjectiles", {"ON","OFF"})
    createSwitch(260, "Homing Projectiles", "homingProjectiles", {"ON","OFF"})
    createSwitch(300, "Damage on Friendly Units", "friendlyDamage", {"ON","OFF"})
    createSwitch(340, "Loot Filter", "lootFilter", {"OFF","Common", "Uncom.", "Rare", "Epic","Ancient","Primordial"})
	
    function events.OpenExtraSettingsMenu()
        for _, v in pairs(mawSettingsButton) do
            if v.Update then
                v:Update()
            end
        end
    end
end

function events.Action(t)
	if t.Action==113 then
		vars.MAWSETTINGS=vars.MAWSETTINGS or {}
		
		local buffRework
		if vars.MAWSETTINGS.buffRework=="ON" then
			buffRework=true
		else
			buffRework=false
		end
		
		for key,value in pairs(mawSettings) do
			vars.MAWSETTINGS[key]=value
		end
		
		if buffRework and vars.MAWSETTINGS.buffRework=="OFF" or not buffRework and vars.MAWSETTINGS.buffRework=="ON" then
			adjustSpellTooltips()	
		end
	end
end

function events.LoadMap()
	vars.MAWSETTINGS=vars.MAWSETTINGS or {}
	
	local buffRework
	if vars.MAWSETTINGS.buffRework=="ON" then
		buffRework=true
	else
		buffRework=false
	end
	
	for key,value in pairs(defaultSettings) do
		vars.MAWSETTINGS[key]=vars.MAWSETTINGS[key] or value
	end
	for key,value in pairs(vars.MAWSETTINGS) do
		mawSettings[key]=vars.MAWSETTINGS[key]
	end
	
	if buffRework and vars.MAWSETTINGS.buffRework=="OFF" or not buffRework and vars.MAWSETTINGS.buffRework=="ON" then
		adjustSpellTooltips()	
	end
end


--fix for inv+exit bug
local preventAction=false
function events.Action(t)
	if preventAction then
		t.Handled=true
		function events.Tick() --just in case
			events.Remove("Tick",1)
			preventAction=false
		end
		return
	end
	if t.Action==168 then
		preventAction=true
		function events.Tick()
			events.Remove("Tick",1)
			preventAction=false
		end
	end
end
