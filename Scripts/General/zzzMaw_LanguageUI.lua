-- German texts of the mod's own settings pages and key bindings (language = "de", see zzzMaw_Language.lua).
-- The pages are made by other scripts with English strings in Lua code. Instead of editing those scripts, the
-- functions that put a text on the screen are wrapped: a text that contains one of the English phrases below is
-- shown with the German phrase instead. Without language = "de" nothing changes. Umlauts are written as decimal
-- escapes (the game's font is cp1252): \228 a, \246 o, \252 u, \220 U, \223 ss.

local PHRASES = {
	{"Buff Rework", "Buff-\220berarbeitung"},
	{"M&M6 Projectiles", "M&M6-Geschosse"},
	{"Homing Projectiles", "Zielsuchende Geschosse"},
	{"Damage on Friendly Units", "Schaden an Verb\252ndeten"},
	{"Loot Filter", "Beutefilter"},
	{"Extra Item Tooltip", "Zusatz-Tooltip"},
	{"Trainer Hints", "Trainer-Hinweise"},
	{"MAW SETTINGS", "MAW-EINSTELLUNGEN"},
	{"EXTRA KEYBINDS", "ZUSATZ-TASTEN"},
	{"Q. SPELL", "SCHNELLZ."},
	{"NPC PANEL", "NPC-FENSTER"},
	{"VOICE AGAIN", "STIMME NEU"},
	{"VOICE STOP", "STIMME AUS"},
	{"General settings", "Allgemeine Einstellungen"},
	{"Keybinds", "Tastenbelegung"},
}

local function german()
	return MawLanguage and MawLanguage.Active == "de"
end

local function translate(text)
	if type(text) ~= "string" or not german() then
		return text
	end
	for _, p in ipairs(PHRASES) do
		local from, to = text:find(p[1], 1, true)
		if from then
			text = text:sub(1, from - 1) .. p[2] .. text:sub(to + 1)
		end
	end
	return text
end
MawTranslateUI = translate

if CustomUI then
	local createText = CustomUI.CreateText
	if createText then
		CustomUI.CreateText = function(t, ...)
			if type(t) == "table" and type(t.Text) == "string" then
				t.Text = translate(t.Text)
			end
			return createText(t, ...)
		end
	end
	local newPage = CustomUI.NewSettingsPage
	if newPage then
		CustomUI.NewSettingsPage = function(name, header, ...)
			return newPage(name, translate(header), ...)
		end
	end
end

-- texts that BountyHunt.lua writes into its code
if BountyHuntFunctions and BountyHuntFunctions.SetCurrentHunt then
	local setHunt = BountyHuntFunctions.SetCurrentHunt
	BountyHuntFunctions.SetCurrentHunt = function(...)
		local text = setHunt(...)
		if german() and text == "You need to clear the area COMPLETELY first." then
			return "Ihr m\252sst das Gebiet zuerst VOLLST\196NDIG s\228ubern."
		end
		return text
	end
end

-- The mod's quest scripts give English texts to Quest{} / Greeting{} (Respec, Druid Circlet, Arena ...). They are
-- looked up in Data/Localization/de/map/ (zzzMaw_Language.lua) before the quest is registered.
local function translateQuests()
	local quest = Quest
	if type(quest) ~= "function" or MawQuestsTranslated then
		return
	end
	MawQuestsTranslated = true
	Quest = function(t, ...)
		if german() and type(t) == "table" and type(t.Texts) == "table" and MawLanguage.Lookup then
			for k, v in pairs(t.Texts) do
				local de = type(v) == "string" and MawLanguage.Lookup(v)
				if de then
					t.Texts[k] = de
				end
			end
		end
		return quest(t, ...)
	end
end
translateQuests()
function events.ScriptsLoaded()
	translateQuests()
end

-- zzMAW-Skills.lua puts the English refusal of a teacher back into NPCText[128] on every Action; this handler runs after it
function events.Action()
	if german() then
		Game.NPCText[128] = "Ihr entsprecht nicht den Anforderungen und k\246nnt nicht unterrichtet werden, bis Ihr alle Anforderungen erf\252llt."
	end
end

local MF = Merge and Merge.Functions
if MF and MF.RegisterExtraKeyBind then
	local register = MF.RegisterExtraKeyBind
	MF.RegisterExtraKeyBind = function(t, ...)
		if type(t) == "table" and type(t.Label) == "string" then
			t.Label = translate(t.Label)
		end
		return register(t, ...)
	end
end
