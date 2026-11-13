-- zzzMaw_LanguageUI.lua translates the texts of the settings pages and key labels only for language = "de".
-- args: UI module path
local uiPath = ...

local actionHandler
events = setmetatable({}, {__newindex = function(_, k, v) if k == "Action" then actionHandler = v end end})

local function run(active)
	local created = {}
	CustomUI = {
		CreateText = function(t) created[#created + 1] = t.Text; return t end,
		NewSettingsPage = function(name, header) created[#created + 1] = header; return name end,
	}
	local labels = {}
	Merge = {Functions = {RegisterExtraKeyBind = function(t) labels[#labels + 1] = t.Label; return t end}}
	MawLanguage = {Active = active, Lookup = function(s) return active == "de" and s == "Skill reset info" and "Fertigkeiten zur\252cksetzen" or nil end}
	MawQuestsTranslated = nil
	Quest = function(t) questSeen = t; return t end
	dofile(uiPath)
	Quest{Texts = {Topic = "Skill reset info", Other = "Unknown text"}}
	CustomUI.CreateText{Text = "\f1Buff Rework\f2"}
	CustomUI.CreateText{Text = "Q. SPELL 3"}
	CustomUI.NewSettingsPage("p", "MAW SETTINGS")
	Merge.Functions.RegisterExtraKeyBind{Label = "VOICE AGAIN"}
	return created, labels
end

local fails = {}
local function check(cond, msg) if not cond then fails[#fails + 1] = msg end end

local c, l = run("de")
Game = {NPCText = {[128] = "English"}}
actionHandler()
check(Game.NPCText[128]:sub(1, 20) == "Ihr entsprecht nicht", "de teacher text: " .. Game.NPCText[128])
check(c[1] == "\f1Buff-\220berarbeitung\f2", "de text: " .. tostring(c[1]))
check(c[2] == "SCHNELLZ. 3", "de Q. SPELL: " .. tostring(c[2]))
check(c[3] == "MAW-EINSTELLUNGEN", "de header: " .. tostring(c[3]))
check(l[1] == "STIMME NEU", "de key label: " .. tostring(l[1]))
check(questSeen.Texts.Topic == "Fertigkeiten zur\252cksetzen" and questSeen.Texts.Other == "Unknown text", "de quest texts: " .. tostring(questSeen.Texts.Topic))

c, l = run("en")
check(c[1] == "\f1Buff Rework\f2" and c[3] == "MAW SETTINGS" and l[1] == "VOICE AGAIN", "en must not change anything")
check(questSeen.Texts.Topic == "Skill reset info", "en quest texts stay")

if #fails > 0 then return "FAIL " .. table.concat(fails, " | ") end
return "OK settings page and key label texts, de/en"
