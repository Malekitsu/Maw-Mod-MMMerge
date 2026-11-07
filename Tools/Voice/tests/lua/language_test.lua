-- Language switch: zzzMaw_Language.lua applies Data/Localization/de/*.txt only for language = "de".
-- args: language module path, voice module path, work dir (ends with \), expected-keys file
local langPath, voicePath, work, keysPath = ...

bit = require("bit")
AppPath = work
mem = {StaticAlloc = function() return 0 end, r4 = {}, u4 = {}, dll = {}}

local handlers = {}
events = setmetatable({}, {__newindex = function(_, k, v) handlers[k] = handlers[k] or {}; table.insert(handlers[k], v) end})

local files, mapFiles, shopFiles, itemFiles = {}, {}, {}, {}
path = {find = function(pat)
    local list = files
    if pat:find("map/", 1, true) then list = mapFiles
    elseif pat:find("shops/", 1, true) then list = shopFiles
    elseif pat:find("items/", 1, true) then list = itemFiles end
    local i = 0
    return function() i = i + 1; return list[i] end
end}

local function fresh()
	local function array(data)  -- like the game's arrays: "for i, v in arr do" walks it from 0
		return setmetatable({data = data}, {
			__index = function(self, k) return rawget(self, "data")[k] end,
			__newindex = function(self, k, v) rawget(self, "data")[k] = v end,
			__call = function(self, _, i)
				i = (i == nil) and 0 or i + 1
				if rawget(self, "data")[i] ~= nil then return i, rawget(self, "data")[i] end
			end,
		})
	end
	Game = {NPCText = array({[1628] = "orig text"}), NPCGreet = {[1] = {[0] = "orig g0", [1] = "orig g1"}}, NPCNews = array({[1] = "orig news"}),
		SkillNames = array({[0] = "Dagger", [1] = "Staff", [2] = "Unrelated"}), ClassNames = array({[0] = "Knight"}),
        NPCTopic = array({[0] = "Skill reset info", [1] = "Hint", [2] = "Known row"})}
	handlers = {}
	Language = nil
	MawLanguage = nil
	local printed = {}
	print = function(s) printed[#printed + 1] = s end
	return printed
end

local function write(name, data)
	local f = assert(io.open(work .. name, "wb")); f:write(data); f:close()
	return work .. name
end

local function run(lang, content, extra)
	local printed = fresh()
	dofile(write("MAWSettings.lua", lang and ('return {language = "' .. lang .. '"' .. (extra or "") .. '}') or "return {}"))
	files = {write("a.txt", content)}
	mapFiles = {write("m.tsv", "Skill reset info\tFertigkeiten zur\xfccksetzen\r\nUnused\tx\r\n")}
	_G.dofileOrig = _G.dofileOrig or dofile
	dofile(langPath)
	for _, h in ipairs(handlers.ScriptsLoaded or {}) do h() end
	for _, h in ipairs(handlers.GameInitialized2 or {}) do h() end
	return printed
end

local de = "Table\tId\tField\tText\r\n"
	.. "NPCText\t1628\t\tGr\xfc\xdfe, Fremder!\\nSch\xf6n, dass Ihr da seid.\r\n"
	.. "NPCGreet\t1\t1\t\xc4pfel, \xd6l, \xdcbung\r\n"
	.. "NPCNews\t1\t\tTab\\tund \\\\ Strich\r\n"
	.. "Rename\t0\tDagger\tDolch\r\n"
	.. "Rename\t0\tKnight\tRitter\r\n"
	.. "Nope\t1\t\tx\r\n"
	.. "NPCText\tabc\t\tbad id\r\n"
	.. "NPCTopic\t2\t\tBekannt\r\n"

local function asc(s) return (tostring(s):gsub("[^ -~]", function(c) return ("<%02x>"):format(c:byte()) end)) end
local fails = {}
local function check(cond, msg) if not cond then fails[#fails + 1] = msg end end

local p = run("de", de)
check(Game.NPCText[1628] == "Gr\xfc\xdfe, Fremder!\nSch\xf6n, dass Ihr da seid.", "NPCText not replaced / \n not decoded: " .. asc(Game.NPCText[1628]))
check(Game.NPCGreet[1][1] == "\xc4pfel, \xd6l, \xdcbung", "NPCGreet field 1")
check(Game.NPCGreet[1][0] == "orig g0", "NPCGreet field 0 must stay")
check(Game.NPCNews[1] == "Tab\tund \\ Strich", "NPCNews escapes")
check(Game.SkillNames[0] == "Dolch" and Game.SkillNames[1] == "Staff" and Game.SkillNames[2] == "Unrelated",
	"SkillNames swap: " .. tostring(Game.SkillNames[0]) .. "/" .. tostring(Game.SkillNames[1]))
check(Game.ClassNames[0] == "Ritter", "ClassNames swap")
check(Game.NPCTopic[0] == "Fertigkeiten zur\xfccksetzen" and Game.NPCTopic[1] == "Hint" and Game.NPCTopic[2] == "Bekannt", "map: " .. tostring(Game.NPCTopic[0]) .. "/" .. tostring(Game.NPCTopic[1]) .. "/" .. tostring(Game.NPCTopic[2]))
local lf = io.open(work .. "MawLanguageUntranslated.txt", "rb"); local left = lf and lf:read("*all") or ""; if lf then lf:close() end
check(left:find("NPCTopic\t1\tHint", 1, true) and not left:find("Known row", 1, true), "untranslated list: " .. left)
check(MawLanguage.Applied == 4, "applied count " .. tostring(MawLanguage.Applied))
check(MawLanguage.Errors == 2, "error count " .. tostring(MawLanguage.Errors) .. " " .. table.concat(p, " | "))
local lang = MawLanguage.Active
check(lang == "de", "active de")

run("en", de)
check(Game.NPCText[1628] == "orig text" and Game.NPCNews[1] == "orig news", "en must not change anything")
run(nil, de)
check(Game.NPCText[1628] == "orig text", "no setting = en")

-- the groups: their files apply only when chosen (default English), each group on its own
shopFiles = {write("s.txt", "Table\tId\tField\tText\r\nNPCNews\t1\t\tShop German\r\n")}
itemFiles = {write("i.txt", "Table\tId\tField\tText\r\nNPCText\t1628\t\tItem German\r\n")}
run("de", de)
check(not MawLanguage.Shops and not MawLanguage.Items and Game.NPCNews[1] == "Tab\tund \\ Strich", "groups off by default: " .. tostring(Game.NPCNews[1]))
run("de", de, ', languageShops = "de"')
check(MawLanguage.Shops and not MawLanguage.Items and Game.NPCNews[1] == "Shop German" and Game.NPCText[1628] ~= "Item German", "shops group on")
run("de", de, ', languageItems = "de"')
check(MawLanguage.Items and not MawLanguage.Shops and Game.NPCText[1628] == "Item German" and Game.NPCNews[1] ~= "Shop German", "items group on")
shopFiles, itemFiles = {}, {}

-- the voice module must find the same key for the shown German text as Python does
fresh()
dofile(voicePath)
for line in io.lines(keysPath) do
	local hex, want = line:match("^(%x*) (%x+)$")
	local text = hex:gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end)
	local got = MawVoices.Key(text)
	check(got == want, ("key want %s got %s"):format(want, got))
end

-- a note in brackets that the game appends to a text is cut off before the recording is looked up
local shapes = MawVoices.NoteShapes("Hallo.\n( Klickt erneut, um anzuwerbenHelmut.)")
check(#shapes == 1 and shapes[1] == "Hallo.", "note shape: " .. tostring(shapes[1]))
shapes = MawVoices.NoteShapes("A (Regie) text (note)")
check(#shapes == 2 and shapes[1] == "A (Regie) text" and shapes[2] == "A", "two notes, longer cut first: " .. tostring(shapes[1]))
check(#MawVoices.NoteShapes("No brackets") == 0 and #MawVoices.NoteShapes("f(x)") == 0, "no cut without a space before the bracket")

-- a teacher's text: the sentence with the player's numbers is cut off, the ordinal "10." does not end a sentence
check(MawVoices.TailShape("Erster Satz.\nZweiter Satz! Ihr k\246nnt den 10. Rang erreichen und 8000 Gold zahlen.") == "Erster Satz.\nZweiter Satz!", "tail shape: " .. tostring(MawVoices.TailShape("Erster Satz.\nZweiter Satz! Ihr k\246nnt den 10. Rang erreichen und 8000 Gold zahlen.")))
check(MawVoices.TailShape("Nur ein Satz mit 5 Zahlen.") == nil and MawVoices.TailShape("Ohne Zahl. Auch nicht.") == nil, "tail shape needs a digit sentence after the first")

-- recordings: English folder by default, NPC_de once the language module reports "de"
check(MawVoices.Dir():sub(-4) == "NPC\\", "English voice folder: " .. MawVoices.Dir())
MawLanguage = {Active = "de"}
check(MawVoices.Dir():sub(-7) == "NPC_de\\", "German voice folder: " .. MawVoices.Dir())

-- the settings page: language and voice switch
do
	local menuPath = langPath:gsub("zzzMaw_Language%.lua$", "zzzMaw_LanguageMenu.lua")
	local labels, handlers2 = {}, {}
	CustomUI = {
		NewSettingsPage = function() return 99 end,
		CreateText = function(t) local o = {Text = t.Text, Action = t.Action}; labels[#labels + 1] = o; return o end,
	}
	Game.PlaySound = function() end
	Game.Lucida_fnt = 1
	MawLanguage = {Active = "de"}
	MawVoices.Enabled = true
	write("MAWSettings.lua", 'return {' .. string.char(13, 10) .. '    language = "de",   -- comment' .. string.char(13, 10) .. '    other = 1,' .. string.char(13, 10) .. '}' .. string.char(13, 10))
	handlers = {}
	dofile(menuPath)
	for _, h in ipairs(handlers.GameInitialized2 or {}) do h() end
	check(#labels == 5, "five labels, got " .. #labels)
	check(labels[1].Text == " Sprache: Deutsch", "language label: " .. tostring(labels[1].Text))
	check(labels[2].Text == " Gegenst\228nde, Tooltips: English" and labels[3].Text == " L\228den, H\228user: English", "group labels: " .. asc(labels[2].Text) .. " / " .. asc(labels[3].Text))
	check(labels[4].Text == " Sprachausgabe: An", "voice label: " .. tostring(labels[4].Text))
	labels[1].Action()
	check(labels[1].Text == " Language: English", "language toggled: " .. tostring(labels[1].Text))
	check(labels[5].Text:find("Restart", 1, true) ~= nil, "restart note: " .. tostring(labels[5].Text))
	local f = io.open(work .. "MAWSettings.lua", "rb"); local s = f:read("*all"); f:close()
	check(s:find('language = "en",', 1, true) and s:find("-- comment", 1, true) and s:find("other = 1", 1, true), "settings file: " .. s)
	labels[1].Action()
	check(labels[5].Text == " ", "no note when back at the active language")
	labels[2].Action()
	labels[3].Action()
	check(labels[2].Text:find("Deutsch", 1, true) and labels[3].Text:find("Deutsch", 1, true) and labels[5].Text:find("Neustart", 1, true), "groups on: " .. asc(labels[2].Text) .. asc(labels[5].Text))
	f = io.open(work .. "MAWSettings.lua", "rb"); s = f:read("*all"); f:close()
	check(s:find('languageItems = "de",', 1, true) and s:find('languageShops = "de",', 1, true), "group settings written: " .. s)
	labels[4].Action()
	check(MawVoices.Enabled == false and labels[4].Text == " Sprachausgabe: Aus", "voice off: " .. tostring(labels[4].Text))
	labels[4].Action()
	check(MawVoices.Enabled == true, "voice on again")
end

if #fails > 0 then return "FAIL " .. table.concat(fails, " | ") end
return "OK language switch, de/en/nil, 5 rows, key parity, voice folder"
