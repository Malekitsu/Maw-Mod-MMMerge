--MAW SETTING HERE

--makes your healing spells to automatically target with lowest % HP
autoTargetHeals=true 

--stats menu has more colours
ColouredStats=true

--remove all buffs, when the spellbook is open
removeBuffsKey=82

--a charge ability usable by knights only when SOLO (default is "E")
chargeKey=69

--quickly consumes a red potion from your current inventory (default is "G")
healthPotionKey=71

--quickly consumes a blue potion from your current inventory (default is "V")
manaPotionKey=86

--normally loot enchants ranges from 2 to 3 per enchant tier (so for example tier 20 goes between 40 and 60). Leaving this on will make enchants go between 1 to 100, making you find the strongest possible items in the game.
higherLootPowerRange=true

--useful for a melee only challenge
disableBow=false

--you can find regeneration, unarmed and all the trainers that weren't previously available in all continents in some houses
enableAllTrainers=true

--in insanity only, taking too much damage disintegrates your character (you can still get them back at the Adventurer's Inn)
enableDisintegrate=true

--recommended to set this on for online play. Making this on will disable the message that informs you when monsters are no longer resurrecting and when you complete the dungeon. You still get the reward.
disableCompletitionMessage=false

-- ONLINE remove travel time, training time and coaches/ships always taking everywhere possible
onlineQualityOfLifeFeatures=true

-- Beyond Madness only, death counter is shown
showDeathCounter=true

--needed to fix some weird bug, don't touch this
Game.PatchOptions.FixMonstersBlockingShots=true


--sorting buttons
currentBagSortKey=82
partyBagSortKey=84
multiBagSortKey=67
partyMultyBagSortKey=71
AlchemyBagKey=69

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

---------------------------------
--HERE IS THE KEYBIND LIST--
---------------------------------
--[[
LBUTTON= 1	
RBUTTON= 2	
CANCEL= 3	
MBUTTON= 4	NOT contiguous with L & RBUTTON
XBUTTON1= 5	
XBUTTON2= 6	
BACK= 8	
BACKSPACE= 8	
TAB= 9	
CLEAR= 12	
ENTER= 13	
RETURN= 13	
SHIFT= 16	
CONTROL= 17	
CTRL= 17	
ALT= 18	
MENU= 18	
PAUSE= 19	
CAPITAL= 20	
CAPSLOCK= 20	
HANGUL= 21	
KANA= 21	
JUNJA= 23	
FINAL= 24	
HANJA= 25	
KANJI= 25	
ESCAPE= 27	
CONVERT= 28	
NONCONVERT= 29	
ACCEPT= 30	
MODECHANGE= 31	
SPACE= 32	
PGUP= 33	
PRIOR= 33	
NEXT= 34	
PGDN= 34	
end= 35	
HOME= 36	
LEFT= 37	
UP= 38	
RIGHT= 39	
DOWN= 40	
SELECT= 41	
PRINT= 42	
EXECUTE= 43	
SNAPSHOT= 44	
INSERT= 45	
DELETE= 46	
HELP= 47	
0= 48	
1= 49	
2= 50	
3= 51	
4= 52	
5= 53	
6= 54	
7= 55	
8= 56	
9= 57	
A= 65	
B= 66	
C= 67	
D= 68	
E= 69	
F= 70	
G= 71	
H= 72	
I= 73	
J= 74	
K= 75	
L= 76	
M= 77	
N= 78	
O= 79	
P= 80	
Q= 81	
R= 82	
S= 83	
T= 84	
U= 85	
V= 86	
W= 87	
X= 88	
Y= 89	
Z= 90	
LWIN= 91	
RWIN= 92	
APPS= 93	
SLEEP= 95	
NUMPAD0= 96	
NUMPAD1= 97	
NUMPAD2= 98	
NUMPAD3= 99	
NUMPAD4= 100	
NUMPAD5= 101	
NUMPAD6= 102	
NUMPAD7= 103	
NUMPAD8= 104	
NUMPAD9= 105	
MULTIPLY= 106	
ADD= 107	
SEPARATOR= 108	
SUBTRACT= 109	
DECIMAL= 110	
DIVIDE= 111	
F1= 112	
F2= 113	
F3= 114	
F4= 115	
F5= 116	
F6= 117	
F7= 118	
F8= 119	
F9= 120	
F10= 121	
F11= 122	
F12= 123	
F13= 124	
F14= 125	
F15= 126	
F16= 127	
F17= 128	
F18= 129	
F19= 130	
F20= 131	
F21= 132	
F22= 133	
F23= 134	
F24= 135	
NUMLOCK= 144	
SCROLL= 145	
SCROLLLOCK= 145	
LSHIFT= 160	
RSHIFT= 161	
LCONTROL= 162	
RCONTROL= 163	
LMENU= 164	
RMENU= 165	
BROWSER_BACK= 166	
BROWSER_FORWARD= 167	
BROWSER_REFRESH= 168	
BROWSER_STOP= 169	
BROWSER_SEARCH= 170	
BROWSER_FAVORITES= 171	
BROWSER_HOME= 172	
VOLUME_MUTE= 173	
VOLUME_DOWN= 174	
VOLUME_UP= 175	
MEDIA_NEXT_TRACK= 176	
MEDIA_PREV_TRACK= 177	
MEDIA_STOP= 178	
MEDIA_PLAY_PAUSE= 179	
LAUNCH_MAIL= 180	
LAUNCH_MEDIA_SELECT= 181	
LAUNCH_APP1= 182	
LAUNCH_APP2= 183	
OEM_1= 186	
OEM_PLUS= 187	
OEM_COMMA= 188	
OEM_MINUS= 189	
OEM_PERIOD= 190	
OEM_2= 191	
OEM_3= 192	
OEM_4= 219	
OEM_5= 220	
OEM_6= 221	
OEM_7= 222	
OEM_8= 223	
OEM_102= 226	
PROCESSKEY= 229	
PACKET= 231	
ATTN= 246	
CRSEL= 247	
EXSEL= 248	
EREOF= 249	
PLAY= 250	
ZOOM= 251	
NONAME= 252	
PA1= 253	
OEM_CLEAR= 254
]]



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
    createSwitch(340, "Loot Filter", "lootFilter", {"OFF","Common", "Uncom.", "Rare", "Epic"})
	
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
