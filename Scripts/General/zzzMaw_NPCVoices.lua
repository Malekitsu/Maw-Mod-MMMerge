-- NPC voices: plays pre-generated audio for NPC greetings, street news and
-- the answers to topics shown in NPC dialogs.
--
-- Audio lives in Data\Voices\NPC\<key>.ogg (or .wav). The key is the CRC32 of
-- the normalized text, made by Tools/Voice/extract_texts.py from the same
-- rules as normalize() below - keep the two identical. Lookup is by text, not
-- by table index: a text that MAW or a quest script changed has no file and
-- stays silent instead of playing a stale line.
--
-- Texts whose speaker is not known have a second recording in the other
-- voice, <key>-m.ogg or <key>-f.ogg. The module reads the name of the NPC in
-- the dialog, looks its gender up in Data\Voices\names.tsv ("name<TAB>m|f",
-- made by extract_texts.py --names) and prefers the recording of that gender.
-- When the NPC has no name, its name is not listed or the text has no
-- recording of that gender, the plain <key>.ogg plays.
-- Texts with placeholders (the hire pitch with its percent, "Back again,
-- <name>?") are shown with the values filled in, so the table text is not what
-- the module sees. Data\Voices\templates.tsv (made by Tools/Voice/templates.py)
-- holds a pattern per such text; a shown text that has no recording of its own
-- is matched against them, the values that vary are read out of it (percent,
-- reputation word, time of day, ...) and the recording t<key>~<value>... plays.
-- Names are not spoken: the recordings leave them out.
-- A greeting starts MawVoices.GreetingDelay seconds late: the NPC's own
-- "hello" sound is still playing then. A guard's or monster's saying waits too.
--
-- Language: with language = "de" the German recordings in Data\Voices\NPC_de are played (key = CRC32 of
-- the German text, Tools/Voice/de/).
--
-- Settings in MAWSettings.lua: npcVoices (false = off, nil counts as on) and
-- npcVoiceVolume (1.0 = the game's character voices slider, nil counts as 1.0).
-- The voice follows the game's character voices slider, one step louder
-- (MawVoices.BoostSteps), see volumeFactor() below.
-- Console: MawVoices.Stop(), MawVoices.Play(text), MawVoices.Key(text),
-- MawVoices.Enabled = false, MawVoices.Log = false, MawVoices.BoostSteps = 1, MawVoices.BoostStepsDe = 1 (German).
-- Notes and open points: Tools/Voice/README.md.

if npcVoices == false then
	return
end

local band, bxor, bnot, rshift, tohex = bit.band, bit.bxor, bit.bnot, bit.rshift, bit.tohex
local byte, gsub, char = string.byte, string.gsub, string.char

local VOICE_DIR = AppPath .. "Data\\Voices\\NPC\\"
local VOICE_DIR_DE = AppPath .. "Data\\Voices\\NPC_de\\"	-- German recordings, keyed by the CRC32 of the German text
local NAMES_PATH = AppPath .. "Data\\Voices\\names.tsv"
local PICS_PATH = AppPath .. "Data\\Voices\\pics.tsv"	-- portrait number -> sex, for NPCs whose name names.tsv does not know
local TEMPLATES_PATH = AppPath .. "Data\\Voices\\templates.tsv"
local TEMPLATES_PATH_DE = AppPath .. "Data\\Voices\\templates_de.tsv"	-- patterns of the German templates (templates_de.py)
local CHARS_PATH_DE = AppPath .. "Data\\Voices\\chars_de.tsv"	-- party member sounds: "sound id<TAB>file stem" (char_voices.py)
local CHAR_DIR_DE = AppPath .. "Data\\Voices\\Char_de\\"
local LOG_PATH = AppPath .. "NPCVoicesLog.txt"
local LOG_MAX = 1024 * 1024		-- the log starts over when it grows beyond this
local EXTENSIONS = {".ogg", ".wav"}
local clock = os.clock

MawVoices = {
	Enabled = true,
	Log = true,		-- one line per dialog text: key, found/missing, text start, NPC and gender
	Volume = tonumber(npcVoiceVolume) or 1,		-- multiplier on top of the game's character voices slider
	BoostStepsDe = 1,	-- the same for language = "de" (the German recordings are about 1 dB louder, the shop greeting follows the Sound slider)
	BoostSteps = 1,		-- slider steps (of 9) the voice plays louder than the slider says, see volumeFactor()
	RepeatDelay = 0.2,		-- seconds the repeat key waits before it plays, so a series of presses starts only the last recording
	RepeatWindow = 2.0,		-- seconds in which pressing the repeat key again goes one recording further back
	KeepPlayingAfterLeave = true,	-- a long text keeps playing when the dialog is left; the stop key ends it
	GreetingDelay = 1.0,	-- seconds before a greeting is spoken (the NPC's own "hello" sound plays first)
}
local MAX_ERRORS = 20	-- consecutive Tick errors before the module switches itself off

---------------------------------------------------------------------------
-- key: CRC32 (zlib flavour) of the normalized text

local CRC = {}
for i = 0, 255 do
	local c = i
	for _ = 1, 8 do
		if band(c, 1) ~= 0 then
			c = bxor(rshift(c, 1), 0xEDB88320)
		else
			c = rshift(c, 1)
		end
	end
	CRC[i] = c
end

local function lowerASCII(c)
	return char(byte(c) + 32)
end

-- drop quotes, collapse whitespace, trim, lowercase A-Z only. Explicit
-- character sets instead of %s / string.lower: those follow the C locale.
local function normalize(s)
	s = gsub(s, '"', "")
	s = gsub(s, "[ \t\r\n\v\f]+", " ")
	s = gsub(s, "^ ", "")
	s = gsub(s, " $", "")
	return (gsub(s, "[A-Z]", lowerASCII))
end

local keyCache = {}
local function textKey(text)
	local key = keyCache[text]
	if key then
		return key
	end
	local s = normalize(text)
	local c = 0xFFFFFFFF
	for i = 1, #s do
		c = bxor(rshift(c, 8), CRC[band(bxor(c, byte(s, i)), 0xFF)])
	end
	key = tohex(bnot(c))
	keyCache[text] = key
	return key
end
MawVoices.Key = textKey

---------------------------------------------------------------------------
-- SoLoud (ExeMods\soloud_x86.dll, also used by the multiplayer module).
-- Own instance, created on first use. Floats go in as their bit pattern.

local SL, Soloud, broken
local wav, handle
local dueAt, duePaths	-- a recording that waits for its start time (greetings)
local floatBuf = mem.StaticAlloc(4)

local function f32(x)
	mem.r4[floatBuf] = x
	return mem.u4[floatBuf]
end

local function loadDll()
	return mem.dll["soloud_x86"]
end

local function audio()
	if Soloud or broken then
		return Soloud
	end
	local ok, dll = pcall(loadDll)
	SL = ok and dll or nil
	if not SL then
		broken = true
		return
	end
	local s = SL.Soloud_create()
	if s == 0 or SL.Soloud_init(s) ~= 0 then
		if s ~= 0 then
			SL.Soloud_destroy(s)
		end
		broken = true
		return
	end
	Soloud = s
	return Soloud
end

local function stop()
	dueAt, duePaths = nil, nil
	if not Soloud then
		return
	end
	if handle then
		SL.Soloud_stop(Soloud, handle)
		handle = nil
	end
	if wav then
		SL.Wav_destroy(wav)
		wav = nil
	end
end
MawVoices.Stop = stop

-- Gender of an NPC by name: Data\Voices\names.tsv, "lowercase name<TAB>m|f".
-- Whole name first ("queen catherine"), then its first word ("keri brown" -> "keri").
local names
local function loadNames()
	names = {}
	local f = io.open(NAMES_PATH, "rb")
	if not f then
		return
	end
	for line in f:lines() do
		local name, gender = line:match("^(.-)\t([mf])")
		if name and name ~= "" then
			names[name] = gender
		end
	end
	f:close()
end

local pics
local function loadPics()
	pics = {}
	local f = io.open(PICS_PATH, "rb")
	if not f then
		return
	end
	for line in f:lines() do
		local pic, gender = line:match("^(%d+)\t([mf])")
		if pic then
			pics[tonumber(pic)] = gender
		end
	end
	f:close()
end

-- whole name, then the sex of the portrait (given by the caller), then the first word of the name
local function genderOf(name, pic)
	if type(name) ~= "string" then
		return nil
	end
	if not names then
		loadNames()
	end
	local s = gsub(name, "[A-Z]", lowerASCII)
	s = gsub(s, "[ \t]+", " ")
	s = gsub(s, "^ ", "")
	s = gsub(s, " $", "")
	if names[s] then
		return names[s]
	end
	if type(pic) == "number" then
		if not pics then
			loadPics()
		end
		if pics[pic] then
			return pics[pic]
		end
	end
	return names[s:match("^[a-z%.'%-]+") or ""]
end
MawVoices.GenderOf = genderOf

-- Texts with placeholders. templates.tsv: "key<TAB>pattern<TAB>captures<TAB>suffix"
-- - pattern: Lua pattern over the normalized shown text, a capture for each
--   placeholder that varies (the others match any text)
-- - captures: the placeholders of the captures, "08,17"
-- - suffix: the placeholders that make up the file name, in order
-- The recording is t<key>~<value>~<value>, the values as slug() writes them.
local logLine  -- defined below
local templates
local function loadTemplates()
	templates = {}
	local german = MawLanguage and MawLanguage.Active == "de"
	-- with German the English patterns too: the texts of the groups items and shops can still be English
	local paths = german and {TEMPLATES_PATH_DE, TEMPLATES_PATH} or {TEMPLATES_PATH}
	local skipped = 0
	for _, templatesPath in ipairs(paths) do
		local f = io.open(templatesPath, "rb")
		if not f then
			logLine("templates none: " .. templatesPath .. " is missing")
		else
			for line in f:lines() do
				line = gsub(line, "^\239\187\191", "")  -- a byte order mark at the start of the file
				local key, pattern, captures, suffix = line:match("^([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t\r\n]*)")
				-- a quick check only: it stops at the first literal of the pattern. A pattern that is
				-- damaged further on is caught when it is matched (templateKey).
				if key and pcall(string.find, "", pattern) then
					local t = {key = key, pattern = pattern, captures = {}, suffix = {}}
					for token in captures:gmatch("[^,]+") do
						t.captures[#t.captures + 1] = token
					end
					for token in suffix:gmatch("[^,]+") do
						t.suffix[#t.suffix + 1] = token
					end
					templates[#templates + 1] = t
				elseif line ~= "" then
					skipped = skipped + 1
				end
			end
			f:close()
		end
	end
	logLine(("templates %d patterns%s"):format(#templates, skipped > 0 and (", " .. skipped .. " lines skipped") or ""))
end

-- file-name form of a value: runs of anything but a-z, 0-9 and "." become "_"
local function slug(value)
	value = gsub(value, "[^a-z0-9%.]+", "_")
	value = gsub(value, "^_+", "")
	return (gsub(value, "_+$", ""))
end

local MAX_TEMPLATE_TEXT = 2000  -- longer texts (the longest in the tables has 1,219 characters) are not matched
local MAX_SHAPES = 3            -- the text, and up to two cuts before a " (" (the hire note comes first)

-- the key of the recording for a shown text that fills in a template, or nil.
-- Also tried: the text without a trailing parenthesis, as the hire dialog adds
-- a note in brackets after the pitch.
local function templateKey(text)
	if not templates then
		loadTemplates()
	end
	if #templates == 0 or #text > MAX_TEMPLATE_TEXT then
		return nil
	end
	local s = normalize(text)
	local shapes = {s}
	if s:sub(-1) == ")" then
		local from = 1
		while #shapes < MAX_SHAPES do
			local i = s:find(" (", from, true)
			if not i then
				break
			end
			shapes[#shapes + 1] = s:sub(1, i - 1)
			from = i + 1
		end
	end
	for _, shape in ipairs(shapes) do
		for _, t in ipairs(templates) do
			local ok, hit = false, false
			if not t.dead then
				ok, hit = pcall(string.find, shape, t.pattern)
				if not ok then
					t.dead = true  -- damaged in a place the check at load time does not reach
				end
			end
			if ok and hit then
				local found = {shape:match(t.pattern)}
				local value = {}
				for i, token in ipairs(t.captures) do
					value[token] = value[token] or found[i]
				end
				local key = "t" .. t.key
				for _, token in ipairs(t.suffix) do
					key = key .. "~" .. slug(value[token] or "")
				end
				return key
			end
		end
	end
end
MawVoices.TemplateKey = templateKey

-- The text without the note in brackets that the game appends to it (the hire dialog: "( Click again to hire X.)"),
-- the longer cut first. A recording of the text itself is looked for after this.
local function noteShapes(text)
	local cuts, from = {}, 1
	while true do
		local i = text:find("%(", from)
		if not i then
			break
		end
		local before = text:sub(1, i - 1)
		if i > 1 and before:match("%s$") then
			local cut = (before:gsub("%s+$", ""))
			if cut ~= "" then
				table.insert(cuts, 1, cut)
			end
		end
		from = i + 1
	end
	return cuts
end
MawVoices.NoteShapes = noteShapes

-- The text without its last sentence that holds a digit, or nil. A skill teacher's text carries the player's own
-- requirement and price (zzMAW-Skills.lua), so the shown text has no recording, but the text before that sentence is
-- the recorded one (teacher_cuts.py). A sentence ends at . ! ? plus white space, not after a digit ("10. Rang").
local function tailShape(text)
	local starts, i, n = {1}, 1, #text
	while i < n do
		local c = text:sub(i, i)
		if (c == "." or c == "!" or c == "?") and text:sub(i + 1, i + 1):find("^%s") and not text:sub(i - 1, i - 1):find("^%d") then
			local j = i + 1
			while j <= n and text:sub(j, j):find("^%s") do
				j = j + 1
			end
			starts[#starts + 1] = j
			i = j
		else
			i = i + 1
		end
	end
	for k = #starts, 2, -1 do
		local from, to = starts[k], (starts[k + 1] or n + 1) - 1
		if text:sub(from, to):find("%d") then
			local cut = (text:sub(1, from - 1):gsub("%s+$", ""))
			return cut ~= "" and cut or nil
		end
	end
	return nil
end
MawVoices.TailShape = tailShape

-- every existing file for a key, in the order of EXTENSIONS. With a gender the
-- recording of that gender (<key>-m / <key>-f) comes first, the plain <key>
-- file after it. The second result tells that a gender recording exists.
-- With language = "de" (zzzMaw_Language.lua) the dialogs show German texts: their recordings are in
-- NPC_de, and a German text without a file there stays silent (no English line over German text).
local function voiceDir()
	if MawLanguage and MawLanguage.Active == "de" then
		return VOICE_DIR_DE
	end
	return VOICE_DIR
end
MawVoices.Dir = voiceDir

-- Texts of the groups items and shops stay English unless the player chose German for them (zzzMaw_Language.lua), so
-- with German the English recordings are searched after the German ones: a key made of an English text is found there,
-- one made of a German text is not (no English line over German text).
local function voiceDirs()
	if MawLanguage and MawLanguage.Active == "de" then
		return {VOICE_DIR_DE, VOICE_DIR}
	end
	return {VOICE_DIR}
end

local function candidates(key, gender)
	local stems = {key}
	if gender then
		table.insert(stems, 1, key .. "-" .. gender)
	end
	for _, dir in ipairs(voiceDirs()) do
		local found, variant
		for i, stem in ipairs(stems) do
			for _, ext in ipairs(EXTENSIONS) do
				local path = dir .. stem .. ext
				local f = io.open(path, "rb")
				if f then
					f:close()
					found = found or {}
					found[#found + 1] = path
					variant = variant or (gender and i == 1)
				end
			end
		end
		if found then
			return found, variant
		end
	end
end

local logFile
function logLine(s)
	if not MawVoices.Log then
		return
	end
	if not logFile then
		logFile = io.open(LOG_PATH, "a")
		if logFile and (logFile:seek("end") or 0) > LOG_MAX then
			logFile:close()
			logFile = io.open(LOG_PATH, "w")
		end
	end
	if logFile then
		logFile:write(os.date("%H:%M:%S"), " ", s, "\n")
		logFile:flush()
	end
end

-- The game's volume. The voice follows the character voices slider (byte 0x6F39B0,
-- level 0-9, the second byte of Game.SoundVolume), not the Sound slider (byte 0x6F39AF,
-- the first byte): the log of the fifth in-game test showed the Sound slider standing
-- at 1 all the time while the player moved the voices slider (9, 1, 8) and heard the
-- game's voices follow it. The third byte is the music slider. Level 0 is silent, as
-- in the game.
-- The recordings are a little quieter than the game's own voices at the same slider
-- position (median -24 dBFS), so the voice plays MawVoices.BoostSteps slider steps louder:
-- at the top that is 10/9 of full volume. The decoded peaks of the recordings stay
-- below 0.92, so only about 1 % of the files touch full scale at this gain, by at most
-- 0.2 dB (not audible). Console: MawVoices.BoostSteps = 0 plays at the slider, 2 is
-- two steps louder.
local function volumeFactor()  -- 0 (silent) to 1 (slider at the top), plus the boost
	local level = math.min(9, band(rshift(Game.SoundVolume, 8), 255))
	if level <= 0 then return 0 end
	local boost = MawVoices.BoostSteps
	if MawLanguage and MawLanguage.Active == "de" then
		boost = MawVoices.BoostStepsDe
	end
	return math.max(0, (level + boost) / 9)
end

local function volume()
	return volumeFactor() * MawVoices.Volume
end

-- "sound slider,voices slider" as the game keeps them; console: print(MawVoices.VolumeInfo())
local function volumeInfo()
	local ok, s = pcall(function()
		local v = Game.SoundVolume
		return ("%d,%d"):format(band(v, 255), band(rshift(v, 8), 255))
	end)
	return ok and s or "?"
end

MawVoices.VolumeInfo = volumeInfo

local langLogged
local npcName, npcGender  -- the NPC of the open dialog

-- ... text start | NPC name, its gender (? = unknown), "alt" = the recording of that gender was used,
-- vol=<sound slider>,<voices slider>
local function logText(kind, key, found, text, variant)
	if not MawVoices.Log then
		return
	end
	if not langLogged then
		langLogged = true
		logLine("language " .. tostring(MawLanguage and MawLanguage.Active) .. ", folder " .. voiceDir())
	end
	logLine(("%-8s %s %s %s | %s %s%s vol=%s"):format(kind, key, found and "play   " or "missing",
		(gsub(text, "[\r\n]+", " ")):sub(1, 70), tostring(npcName or "?"), npcGender or "?", variant and " alt" or "", volumeInfo()))
end

-- Starts the first of the files the decoder accepts.
local function start(paths)
	if volume() <= 0 or not audio() then
		return false
	end
	for _, path in ipairs(paths) do
		wav = SL.Wav_create()
		if SL.Wav_load(wav, path) == 0 then
			-- playEx(soloud, sound, volume, pan, paused, bus)
			handle = SL.Soloud_playEx(Soloud, wav, f32(volume()), f32(0), 0, 0)
			return true
		end
		SL.Wav_destroy(wav)  -- damaged or unsupported file: try the next one
		wav = nil
	end
	return false
end

---------------------------------------------------------------------------
-- The voices of the party members (greetings, remarks about items, monsters, hunger, gold ...).
-- The game plays them as sounds of the Character voices table. With language = "de" a sound that
-- chars_de.tsv knows is replaced by the German recording (Data\Voices\Char_de\<stem>.ogg, from the
-- German original voices of Data\GermanD.lod, see Tools/Voice/de/char_voices.py) and the English
-- sound is suppressed. A missing or damaged file leaves the English sound.
local charMap
local charShop = {}  -- sound ids that are shop greetings: German only with German shops (zzzMaw_Language.lua)
local charWav, charHandle
local charLogged = {}

local function loadCharMap()
	charMap = {}
	local f = io.open(CHARS_PATH_DE, "rb")
	if not f then
		logLine("charvoice none: Data\\Voices\\chars_de.tsv is missing")
		return
	end
	local n = 0
	for line in f:lines() do
		local id, stem, tag = line:match("^(%d+)\t(%d+)\t?(%a?)")
		if id then
			charMap[tonumber(id)] = stem
			if tag == "s" then
				charShop[tonumber(id)] = true  -- a shop greeting
			end
			n = n + 1
		end
	end
	f:close()
	logLine(("charvoice %d sounds"):format(n))
end

-- the gender of the owner of the house the party is in (a shop greeting is spoken by the owner), or nil
local function houseOwnerGender()
	local ok, g = pcall(function()
		local house = Game.GetCurrentHouse()
		if not house or house <= 0 then
			return nil
		end
		return genderOf(Game.Houses[house].OwnerName)
	end)
	return ok and g or nil
end

local function playCharVoice(id)
	-- not tied to MawVoices.Enabled ("Voice output" of the settings page is the NPC speech): with it off the game
	-- would play its own English sounds instead of these German ones
	if not (MawLanguage and MawLanguage.Active == "de") then
		return false
	end
	if not charMap then
		loadCharMap()
	end
	local stem = charMap[id]
	if not stem or (charShop[id] and not MawLanguage.Shops) or volume() <= 0 or not audio() then
		return false
	end
	-- the installer writes .ogg (with ffmpeg) or .wav (without)
	local function exists(base)
		for _, ext in ipairs({".ogg", ".wav"}) do
			local f = io.open(base .. ext, "rb")
			if f then
				f:close()
				return base .. ext
			end
		end
	end
	local path = exists(CHAR_DIR_DE .. stem) or (CHAR_DIR_DE .. stem .. ".ogg")
	local gender = houseOwnerGender()  -- shop greetings exist in both voices: <id>.ogg and <id>-<m|f>.ogg
	if gender then
		path = exists(CHAR_DIR_DE .. stem .. "-" .. gender) or path
	end
	if charHandle then
		SL.Soloud_stop(Soloud, charHandle)
		charHandle = nil
	end
	if charWav then
		SL.Wav_destroy(charWav)
		charWav = nil
	end
	local w = SL.Wav_create()
	if SL.Wav_load(w, path) ~= 0 then
		SL.Wav_destroy(w)
		if not charLogged[id] then
			charLogged[id] = true
			logLine(("charvoice %d missing %s"):format(id, path))
		end
		return false
	end
	charWav = w
	charHandle = SL.Soloud_playEx(Soloud, w, f32(volume()), f32(0), 0, 0)
	if not charLogged[id] then
		charLogged[id] = true
		logLine(("charvoice %d play    %s"):format(id, stem))
	end
	return true
end

-- Diagnosis of loudness complaints: MawVoices.LogSounds = false writes the id of every sound the game
-- starts (at most 400 per session) as "sound <id> vol=<slider>", so a sound can be looked up in Sounds.txt.
MawVoices.LogSounds = false
local soundsLogged = 0

function events.PlaySound(t)
	if MawVoices.LogSounds and soundsLogged < 400 and t.Sound and t.Sound ~= 0 then
		soundsLogged = soundsLogged + 1
		logLine(("sound    %d vol=%s"):format(t.Sound, volumeInfo()))
	end
	if t.Sound and playCharVoice(t.Sound) then
		t.Sound = 0  -- the English sound stays silent
	end
end

-- The last three recordings, newest first: the repeat key plays them again (see events.KeyDown below).
local recent = {}
local function remember(paths)
	if recent[1] == paths[1] then
		return
	end
	table.insert(recent, 1, paths)
	recent[4] = nil
end

-- Stops whatever plays; plays the file for 'text' if there is one, after
-- 'delay' seconds when given (the next Tick after that starts it).
local function playText(text, kind, delay)
	stop()
	if not MawVoices.Enabled or not text or text == "" then
		return false
	end
	local key = textKey(text)
	local paths, variant = candidates(key, npcGender)
	if not paths then
		local tkey = templateKey(text)  -- a template with its placeholders filled in
		if tkey then
			key = tkey
			paths, variant = candidates(key, npcGender)
		end
	end
	if not paths then
		for _, shape in ipairs(noteShapes(text)) do
			local k = textKey(shape)
			paths, variant = candidates(k, npcGender)
			if paths then
				key = k
				break
			end
		end
	end
	if not paths then
		local shape = tailShape(text)  -- a teacher's text with the player's own numbers: the part before them
		if shape then
			local k = textKey(shape)
			paths, variant = candidates(k, npcGender)
			if paths then
				key = k
			end
		end
	end
	logText(kind or "text", key, paths, text, variant)
	if not paths then
		return false
	end
	remember(paths)
	if delay and delay > 0 then
		dueAt, duePaths = clock() + delay, paths
		return true
	end
	return start(paths)
end
MawVoices.Play = function(text)  -- console: at once, no greeting delay
	return playText(text, "console")
end

---------------------------------------------------------------------------
-- Dialog tracking.
-- Greeting: DrawNPCGreeting may run on every redraw and later handlers may
-- still replace t.Text (quests, multiplayer), so the table is read on the
-- next Tick and only a changed text plays. Street news come this way too.
-- Topics: a topic's evt (compiled Global.EVT or Lua Message()) ends in
-- SetMessage, which sets Game.NPCMessage; a change of that text while the
-- dialog is open plays it. Same idea for any other dialog message.
-- ClickNPCTopic fires before the topic's event runs: the answer is played
-- after a click even when it is the same text as before (Game.NPCMessage
-- keeps its text after a dialog, so "changed" alone would miss it).

local inDialog, pendingGreeting, lastGreeting, lastMessage, clicked

local function readMessage()
	return Game.NPCMessage
end

local function currentMessage()
	local ok, s = pcall(readMessage)
	return ok and s or nil
end

local function lookupNpc(t)
	local name = t.NPC.Name
	local okPic, pic = pcall(function() return t.NPC.Pic end)
	return name, genderOf(name, okPic and pic or nil)
end

-- t = {NPC = <the NPC struct>, Index, Kind} of events.EnterAnyNPC (empty in tests)
local function enter(t)
	stop()
	inDialog = true
	lastGreeting, clicked = nil, nil
	lastMessage = currentMessage()  -- left over from an earlier dialog
	npcName, npcGender = nil, nil
	local ok, name, gender = pcall(lookupNpc, t or {})
	if ok then
		npcName, npcGender = name, gender
	end
end

local function leaveNow(keepPlaying)
	inDialog, pendingGreeting, lastGreeting, lastMessage, clicked = nil, nil, nil, nil, nil
	npcName, npcGender = nil, nil
	if keepPlaying and MawVoices.KeepPlayingAfterLeave then
		dueAt, duePaths = nil, nil  -- a recording that already plays runs to its end; a waiting one is dropped
	else
		stop()
	end
end

local function leave()
	pcall(leaveNow)  -- the engine's own events call this: never raise
end

-- leaving a dialog: a long text runs to its end while the player walks on (the stop key ends it);
-- leaving the map or the game always stops it
local function leaveDialog()
	pcall(leaveNow, true)
end

local function enterSafe(t)
	pcall(enter, t)
end

function events.EnterAnyNPC(t)
	enterSafe(t)
end

function events.DrawNPCGreeting(t)
	pendingGreeting = t
end

function events.ClickNPCTopic()
	if inDialog then
		clicked = true
	end
end

events.ExitNPC = leaveDialog
events.ExitAnyNPC = leaveDialog
events.LeaveMap = leave
events.LeaveGame = leave

---------------------------------------------------------------------------
-- Guards and other monsters with a generic message (events.SpeakWithMonster).
-- This is not an NPC dialog and does not use Game.NPCMessage (the first in-game
-- test showed the old dialog text still in place). The message is the NPCNews
-- text of the monster's group - NPCGroup.txt maps group -> news number, the same
-- lookup as GetNPCGroupNews in NPCNewsTopics.lua - unless a script sets t.Result
-- (an empty string shows nothing). It plays once, MawVoices.GreetingDelay seconds
-- late like a greeting: the guard says its own "hello" first (fourth in-game test).
-- There is no dialog open then, so Tick also has to start a waiting recording
-- outside of dialogs.

local function groupNews(group)
	local id = mem.i2[Game.NPCGroup["?ptr"] + (group - 1) * 2]
	if id and id > 0 then
		return Game.NPCNews[id]
	end
end

local function monsterText(t)
	if t.Result ~= nil then
		return t.Result
	end
	local group = t.Monster.Group
	if group and group > 0 then
		return groupNews(group)
	end
end

local function speakWithMonster(t)
	if not MawVoices.Enabled then
		return
	end
	local text = monsterText(t)
	if type(text) == "string" and text ~= "" then
		npcName, npcGender = nil, nil
		playText(text, "guard", MawVoices.GreetingDelay)
	end
end

function events.SpeakWithMonster(t)
	local ok, err = pcall(speakWithMonster, t)  -- the engine calls this: never raise
	if not ok then
		pcall(logLine, "guard    error: " .. tostring(err):sub(1, 120))
	end
end

---------------------------------------------------------------------------

local function tick()
	if inDialog then
		if pendingGreeting then
			local text = pendingGreeting.Text
			pendingGreeting = nil
			if text and text ~= lastGreeting then
				lastGreeting = text
				playText(text, "greeting", MawVoices.GreetingDelay)
			end
		end
		local msg = currentMessage()
		if msg ~= lastMessage or clicked then
			if clicked then
				dueAt, duePaths = nil, nil  -- the player moved on: a greeting still waiting is dropped
			end
			clicked = nil
			lastMessage = msg
			if msg and msg ~= "" and msg ~= lastGreeting then
				playText(msg, "topic")  -- no delay: the player clicked, no "hello" sound is playing
			end
		end
	end
	if dueAt and clock() >= dueAt then
		local paths = duePaths
		dueAt, duePaths = nil, nil
		start(paths)
	end
end

local errors = 0
-- Keys (MAWSettings.lua: repeatVoiceKey, stopVoiceKey; defaults F9 and F10):
-- the repeat key plays the last recording again; pressed again within MawVoices.RepeatWindow seconds it plays
-- the one before, a third time the one before that. The stop key ends the recording and the waiting ones.
local keyCodes
local function loadKeyCodes()
	keyCodes = {repeatKey = 120, stopKey = 121}
	local ok, settings = pcall(dofile, (AppPath or "") .. "MAWSettings.lua")
	if ok and type(settings) == "table" then
		keyCodes.repeatKey = tonumber(settings.repeatVoiceKey) or keyCodes.repeatKey
		keyCodes.stopKey = tonumber(settings.stopVoiceKey) or keyCodes.stopKey
	end
end

-- The two keys are also entries of MAW's Keybinds page (Merge.Functions.RegisterExtraKeyBind: the player picks
-- the key in the game, the game keeps it in the registry). Without that page the keys of MAWSettings.lua apply.
local bindRepeat, bindStop
local function registerBinds()
	local ok, MF = pcall(function() return Merge.Functions end)
	if not ok or type(MF) ~= "table" or not MF.RegisterExtraKeyBind then
		return
	end
	loadKeyCodes()
	bindRepeat = MF.RegisterExtraKeyBind({DefKey = keyCodes.repeatKey, RegValue = "xkey_voicerepeat", Label = "VOICE AGAIN"})
	bindStop = MF.RegisterExtraKeyBind({DefKey = keyCodes.stopKey, RegValue = "xkey_voicestop", Label = "VOICE STOP"})
end
pcall(registerBinds)

local function currentKeys()
	if bindRepeat and bindStop then
		local binds = Merge.Tables.ExtraKeyBinds
		return binds[bindRepeat].Key, binds[bindStop].Key
	end
	if not keyCodes then
		loadKeyCodes()
	end
	return keyCodes.repeatKey, keyCodes.stopKey
end

local presses, lastPress = 0, nil
local function keyPressed(key)
	local repeatKey, stopKey = currentKeys()
	if key == stopKey then
		stop()
		return true
	elseif key == repeatKey then
		local now = clock()
		presses = (lastPress and now - lastPress <= MawVoices.RepeatWindow and presses < 3) and presses + 1 or 1
		lastPress = now
		local paths = recent[presses]
		if paths then
			stop()
			dueAt, duePaths = now + MawVoices.RepeatDelay, paths  -- a quick series of presses must not leave a snippet of the earlier ones
		end
		return true
	end
end
MawVoices.KeyPressed = keyPressed

function events.KeyDown(t)
	if MawVoices.Enabled and t and t.Key then
		pcall(keyPressed, t.Key)
	end
end

function events.Tick()
	if not MawVoices.Enabled then
		dueAt, duePaths = nil, nil  -- switched off (console) while a greeting waited
		return
	end
	if not inDialog and not dueAt then
		return  -- nothing to track and nothing waiting (a guard's line waits outside of dialogs)
	end
	local ok, err = pcall(tick)
	if ok then
		errors = 0
		return
	end
	-- never let audio trouble spoil a dialog, and do not flood the log
	errors = errors + 1
	if errors <= 3 then
		print("MawVoices: " .. tostring(err))
	end
	if errors >= MAX_ERRORS then
		MawVoices.Enabled = false
		pcall(stop)
	end
end
