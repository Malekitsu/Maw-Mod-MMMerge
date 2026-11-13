-- MAW language switch: replaces dialog texts by the German ones.
--
-- Setting in MAWSettings.lua: language = "de" or "en" (nil counts as "en", so
-- an install without the German pack and without the setting stays English).
-- With "de" every file Data/Localization/de/*.txt is applied once the game is
-- initialised, after MMMerge's own LocalizeTables. File format, one row per line,
-- fields separated by a tab, header line skipped:
--
--     Table <TAB> Id <TAB> Field <TAB> Text
--
-- Table = a Game table (NPCText, NPCGreet, NPCNews, NPCTopic ...), Field is empty
-- for plain string tables and 0/1 for NPCGreet (Greeting 1/2). In Text the
-- sequences \n, \t and \\ stand for newline, tab and backslash (a line break
-- would end the row). Files are cp1252 like the game's own tables, so umlauts
-- come out right. A bad row is logged and skipped; the game is never harmed.

local LANG_DIR = "Data/Localization/de/"

local Language = {Active = "en", Applied = 0, Errors = 0}
MawLanguage = Language

local function readSettings()
	local ok, settings = pcall(dofile, (AppPath or "") .. "MAWSettings.lua")
	return (ok and type(settings) == "table") and settings or {}
end

local function readLanguage()
	return readSettings().language == "de" and "de" or "en"
end

-- Items with their tooltips and the shops and houses (names, owners, shop labels, the dialogs of the people who live in
-- houses, the shop greetings) are German only when the player chooses it: languageItems = "de" and languageShops = "de"
-- in MAWSettings.lua (settings page Sprache / Language). Many players know the English item names. The texts of these
-- groups are in Data/Localization/de/items/ and Data/Localization/de/shops/; the voice module reads Language.Shops.
local function readGroups()
	local settings = readSettings()
	return settings.languageItems == "de", settings.languageShops == "de"
end

-- known from the start: pages of the settings menu and key labels are made before the texts are applied
Language.Active = readLanguage()
Language.Items, Language.Shops = readGroups()

local function unescape(s)
	return (s:gsub("\\(.)", function(c)
		if c == "n" then return "\n" end
		if c == "t" then return "\t" end
		return c
	end))
end

local errorLines = {}  -- the first errors, written to MawLanguageLog.txt

local function logError(fmt, ...)
	Language.Errors = Language.Errors + 1
	local ok, msg = pcall(string.format, fmt, ...)
	print("MawLanguage: " .. (ok and msg or fmt))
	if #errorLines < 400 then
		errorLines[#errorLines + 1] = ((ok and msg or fmt):match("^[^\n]*"))  -- the first line: the traceback is long
	end
end

local renames = {}
local applied = {}  -- "Table:id" of the rows the files replaced
local NAME_ARRAYS = {"SkillNames", "StatsNames", "ClassNames", "NPCProfNames"}

-- The name arrays are filled from Global.txt, Class.txt ... when the game starts and do not follow GlobalTxt:
-- every entry whose text equals an English text of the renames is replaced.
local function applyRenames()
	local n = 0
	for _, arrayName in ipairs(NAME_ARRAYS) do
		local arr = Game[arrayName]
		if arr then
			for i, v in arr do
				local new = type(v) == "string" and renames[v]
				if new then
					arr[i] = new
					n = n + 1
				end
			end
		end
	end
	return n
end

local function applyRow(line, file)
	local cols = {}
	for field in (line .. "\t"):gmatch("([^\t]*)\t") do
		cols[#cols + 1] = field
	end
	local name, id, field, text = cols[1], tonumber(cols[2]), cols[3], cols[4]
	if not name or #name == 0 or not id or not text then
		return logError("bad row in %s: %s", file, line:sub(1, 60))
	end
	if name == "Rename" then  -- "Rename<TAB>0<TAB>English<TAB>German": swapped in the name arrays after the rows
		renames[field] = unescape(text)
		return
	end
	local tbl = Game[name]
	if not tbl then
		return logError("unknown table %s in %s", name, file)
	end
	text = unescape(text)
	if #field > 0 then
		tbl[id][tonumber(field) or field] = text
	else
		tbl[id] = text
	end
	applied[name .. ":" .. id] = true
	Language.Applied = Language.Applied + 1
end

local function applyFile(path)
	local f = io.open(path, "rb")
	if not f then
		return logError("cannot read %s", path)
	end
	local data = f:read("*all")
	f:close()
	local first = true
	for line in data:gmatch("([^\r\n]+)") do
		if first then
			first = false  -- header
		else
			local ok, err = pcall(applyRow, line, path)
			if not ok then
				logError("row failed in %s: %s", path, tostring(err))
			end
		end
	end
end

-- Texts that scripts add to the tables (topics and answers of quests made in Lua) have no row number the German
-- files could name. Data/Localization/de/map/*.tsv holds "English<TAB>German": an entry of these tables that is
-- still exactly that English text is replaced.
local MAP_TABLES = {"NPCTopic", "NPCText", "NPCNews"}

local function loadMap()
	local map = {}
	for file in path.find(LANG_DIR .. "map/*.tsv") do
		local f = io.open(file, "rb")
		if f then
			local data = f:read("*all")
			f:close()
			for line in data:gmatch("([^\r\n]+)") do
				local en, de = line:match("^([^\t]*)\t(.*)$")
				if en and #en > 0 then
					map[unescape(en)] = unescape(de)
				end
			end
		end
	end
	return map
end

-- the German of an English text of the map, or nil (zzzMaw_LanguageUI.lua uses it on the texts of Quest{} / Greeting{})
local mapCache
function Language.Lookup(text)
	if Language.Active ~= "de" or type(text) ~= "string" then
		return nil
	end
	if not mapCache then
		mapCache = loadMap()
	end
	return mapCache[text]
end

-- replaces the mapped texts; writes the English texts nothing replaced to MawLanguageUntranslated.txt (what is left to translate)
local function applyMap()
	local map = loadMap()
	local n, left = 0, {}
	for _, name in ipairs(MAP_TABLES) do
		local tbl = Game[name]
		if tbl then
			for i, v in tbl do
				if type(v) == "string" and not applied[name .. ":" .. i] then
					local de = map[v]
					if de then
						tbl[i] = de
						n = n + 1
					elseif v:find("%a") and #left < 6000 then
						left[#left + 1] = name .. "\t" .. i .. "\t" .. v:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\t", "\\t")
					end
				end
			end
		end
	end
	local f = io.open((AppPath or "") .. "MawLanguageUntranslated.txt", "wb")
	if f then
		f:write(table.concat(left, "\n"), "\n")
		f:close()
	end
	return n
end

local function applyAll()
	Language.Active = readLanguage()
	if Language.Active ~= "de" then
		return
	end
	Language.Items, Language.Shops = readGroups()
	for file in path.find(LANG_DIR .. "*.txt") do
		applyFile(file)
	end
	if Language.Items then
		for file in path.find(LANG_DIR .. "items/*.txt") do
			applyFile(file)
		end
	end
	if Language.Shops then
		for file in path.find(LANG_DIR .. "shops/*.txt") do
			applyFile(file)
		end
	end
	local okMap, nMap = pcall(applyMap)
	Language.Mapped = okMap and nMap or 0
	if not okMap then
		logError("map failed: %s", tostring(nMap))
	end
	local ok, n = pcall(applyRenames)
	Language.Renamed = ok and n or 0
	print(ok and ("MawLanguage: %d names renamed"):format(n) or "MawLanguage: renames failed: " .. tostring(n))
	print(string.format("MawLanguage: de, %d texts applied, %d errors", Language.Applied, Language.Errors))
	local f = io.open((AppPath or "") .. "MawLanguageLog.txt", "wb")
	if f then
		f:write(os.date("%Y-%m-%d %H:%M:%S"), string.format(" de, %d texts applied, %d errors, %d names renamed", Language.Applied, Language.Errors, Language.Renamed or 0), '\n')
		for _, line in ipairs(errorLines) do
			f:write(line, '\n')
		end
		f:close()
	end
end

function events.ScriptsLoaded()  -- registered after LocalizeTables, so we run after it
	events.GameInitialized2 = function()
		local ok, err = pcall(applyAll)
		if not ok then
			logError("language switch failed: %s", tostring(err))
		end
	end
end
