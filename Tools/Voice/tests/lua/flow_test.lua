-- Dialog flow of zzzMaw_NPCVoices.lua against a stubbed engine and a fake SoLoud.
-- args: module path, scratch app directory (Data\Voices\NPC below it must exist)
local modulePath, appDir = ...

local bit = require("bit")
local ffi = require("ffi")
local realClock = os.clock  -- world() replaces os.clock by a fake

local checks, failures = 0, {}
local function check(name, got, want)
	checks = checks + 1
	if got ~= want then
		failures[#failures + 1] = ("%s\n      got:  %s\n      want: %s"):format(name, tostring(got), tostring(want))
	end
end

local function bits(x)
	local b = ffi.new("float[1]", x)
	return ffi.cast("uint32_t*", b)[0]
end

-- A fresh engine + fake SoLoud, then the module is loaded into it.
local function world(opts)
	opts = opts or {}
	local w = {calls = {}, handlers = {}, args = {}, failNow = opts.fail}
	local function record(name, ret)
		return function(...)
			w.calls[#w.calls + 1] = name
			w.args[name] = {...}
			if w.failNow == name then
				error("fake failure in " .. name)
			end
			if type(ret) == "function" then
				return ret(...)
			end
			return ret or 0
		end
	end
	local SL = {
		Soloud_create = record("Soloud_create", 1),
		Soloud_init = record("Soloud_init", 0),
		Soloud_destroy = record("Soloud_destroy", 0),
		Wav_create = record("Wav_create", 2),
		Wav_load = record("Wav_load", function(_, path)
			if opts.loadFails or (opts.rejectOgg and path:find("%.ogg$")) then
				return 1
			end
			return 0
		end),
		Wav_destroy = record("Wav_destroy", 0),
		Soloud_playEx = record("Soloud_playEx", 7),
		Soloud_stop = record("Soloud_stop", 0),
	}
	local floatBuf, lastFloat = 100, 0
	_G.bit = bit
	_G.AppPath = appDir
	_G.npcVoices = opts.npcVoices
	_G.npcVoiceVolume = opts.npcVoiceVolume
	_G.MawVoices = nil
	local dll = opts.noSoloud and {} or {soloud_x86 = SL}
	_G.mem = {
		StaticAlloc = function() return floatBuf end,
		r4 = setmetatable({}, {__newindex = function(_, _, v) lastFloat = v end}),
		u4 = setmetatable({}, {__index = function() return bits(lastFloat) end}),
		dll = dll,
		i2 = {},
	}
	_G.events = setmetatable({}, {__newindex = function(_, name, f)
		w.handlers[name] = w.handlers[name] or {}
		table.insert(w.handlers[name], f)
	end})
	-- Game.SoundVolume: byte 1 = Sound slider, byte 2 = character voices slider, byte 3 = music (each 0-9)
	_G.Game = {SoundVolume = (opts.music or 5) * 65536 + (opts.voices or 9) * 256 + (opts.soundVolume or 1), NPCMessage = opts.leftover or ""}
	_G.print = function() end
	w.now = 0  -- fake clock: the module takes os.clock when it is loaded
	os.clock = function() return w.now end
	dofile(modulePath)
	if _G.MawVoices then
		_G.MawVoices.Log = false
		w.defaultDelay = _G.MawVoices.GreetingDelay
		_G.MawVoices.GreetingDelay = opts.delay or 0  -- most scenarios want the greeting at once
	end
	function w.fire(name, ...)
		for _, f in ipairs(w.handlers[name] or {}) do
			f(...)
		end
	end
	function w.take()
		local c = table.concat(w.calls, " ")
		w.calls = {}
		return c
	end
	function w.file(text, ext, gender)  -- make the audio file the module will look for (<key>[-m|-f])
		local key = _G.MawVoices.Key(text)
		local f = assert(io.open(appDir .. "Data\\Voices\\NPC\\" .. key .. (gender and "-" .. gender or "") .. (ext or ".ogg"), "wb"))
		f:write("x")
		f:close()
		return key
	end
	local function dataFile(name)  -- a Data\Voices file the module reads; nil content removes it
		return function(content)
			local path = appDir .. "Data\\Voices\\" .. name
			if content == nil then
				os.remove(path)
				return
			end
			local f = assert(io.open(path, "wb"))
			f:write(content)
			f:close()
		end
	end
	w.names = dataFile("names.tsv")
	w.templates = dataFile("templates.tsv")
	w.templates(nil)  -- a file left by an earlier test would change what the module recognizes
	return w
end

local function basename(path)
	return path:match("([^\\/]+)$")
end

local GREET = 'Welcome to Dagger Wound Island, "Journeyman" of Alvar.'
local TOPIC = "Topic answer\nsecond line"
local PLAY = "Wav_create Wav_load Soloud_playEx"
local STOP = "Soloud_stop Wav_destroy"

do  -- greeting is read on the next tick and plays once however often it is redrawn
	local w = world()
	local key = w.file(GREET)
	w.fire("EnterAnyNPC", {})
	w.fire("Tick")
	check("enter alone is silent", w.take(), "")
	for _ = 1, 3 do
		w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
		w.fire("Tick")
	end
	check("greeting plays once", w.take(), "Soloud_create Soloud_init " .. PLAY)
	check("greeting file", basename(w.args.Wav_load[2]), key .. ".ogg")
	check("slider at the top: one step louder than full", w.args.Soloud_playEx[3], bits(10 / 9))

	-- a topic answer replaces the greeting
	w.file(TOPIC)
	_G.Game.NPCMessage = TOPIC
	w.fire("Tick")
	check("topic stops greeting and plays", w.take(), STOP .. " " .. PLAY)
	w.fire("Tick")
	check("same message does not replay", w.take(), "")

	-- an answer without a recording silences the previous voice
	_G.Game.NPCMessage = "No recording exists for this one"
	w.fire("Tick")
	check("missing file stops the old voice", w.take(), STOP)

	-- exit stops, and nothing plays outside a dialog
	w.file("Another greeting.")
	w.fire("DrawNPCGreeting", {Text = "Another greeting.", NPC = 1})
	w.fire("Tick")
	check("a different greeting plays", w.take(), PLAY)  -- the old voice was already stopped above
	w.fire("ExitNPC", 1)
	check("exit lets the voice run on", w.take(), "")
	w.fire("KeyDown", {Key = 121})
	check("the stop key stops it", w.take(), STOP)
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	check("greeting outside a dialog is ignored", w.take(), "")
end

do  -- a message left over from an earlier dialog does not play when a new one opens
	local w = world({leftover = TOPIC})
	w.file(TOPIC)
	w.fire("EnterAnyNPC", {})
	w.fire("Tick")
	check("leftover message is ignored", w.take(), "")
end

do  -- a later handler may replace the greeting text before the tick
	local w = world()
	local other = "Quest greeting replaced by another script."
	local key = w.file(other)
	w.fire("EnterAnyNPC", {})
	local t = {Text = GREET, NPC = 1}
	w.fire("DrawNPCGreeting", t)
	t.Text = other
	w.fire("Tick")
	check("final greeting text plays", basename(w.args.Wav_load[2]), key .. ".ogg")
end

do  -- quotes, case, white space and line breaks do not matter
	local w = world()
	w.file("Good day.")
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = '"GOOD   day."\r\n', NPC = 1})
	w.fire("Tick")
	check("normalized lookup", w.take(), "Soloud_create Soloud_init " .. PLAY)
end

do  -- volume: the voice follows the character voices slider (0 is silent), not the Sound slider
	local function played(opts)
		local w = world(opts)
		if opts.boost then _G.MawVoices.BoostSteps = opts.boost end
		w.file(GREET)
		w.fire("EnterAnyNPC", {})
		w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
		w.fire("Tick")
		return w
	end
	local w = played({voices = 0})
	check("voices slider 0 plays nothing", w.take(), "")
	check("voices slider at the top plays one step above full", played({voices = 9}).args.Soloud_playEx[3], bits(10 / 9))
	check("voices slider 1 plays at 2 of 9", played({voices = 1}).args.Soloud_playEx[3], bits(2 / 9))
	check("voices slider 6 plays at 7 of 9", played({voices = 6}).args.Soloud_playEx[3], bits(7 / 9))
	check("the Sound slider does not matter (at 1, as in the fifth test)", played({voices = 9, soundVolume = 1}).args.Soloud_playEx[3], bits(10 / 9))
	check("the Sound slider does not matter (at 9)", played({voices = 3, soundVolume = 9}).args.Soloud_playEx[3], bits(4 / 9))
	check("the Sound slider at 0 does not silence the voice", played({voices = 9, soundVolume = 0}).take(), "Soloud_create Soloud_init " .. PLAY)
	check("the music slider does not matter", played({voices = 9, music = 0}).args.Soloud_playEx[3], bits(10 / 9))
	check("npcVoiceVolume scales", played({npcVoiceVolume = 0.5}).args.Soloud_playEx[3], bits(10 / 9 * 0.5))
	check("npcVoiceVolume scales the voices slider", played({voices = 6, npcVoiceVolume = 0.5}).args.Soloud_playEx[3], bits(7 / 9 * 0.5))

	-- the boost: steps above the slider, level 0 stays silent
	check("BoostSteps 0 plays at the slider (top)", played({voices = 9, boost = 0}).args.Soloud_playEx[3], bits(1.0))
	check("BoostSteps 0 plays at the slider (1)", played({voices = 1, boost = 0}).args.Soloud_playEx[3], bits(1 / 9))
	check("BoostSteps 2 is two steps louder", played({voices = 9, boost = 2}).args.Soloud_playEx[3], bits(11 / 9))
	check("level 0 stays silent with a boost", played({voices = 0, boost = 2}).take(), "")
	check("a negative boost below the slider is quieter", played({voices = 5, boost = -2}).args.Soloud_playEx[3], bits(3 / 9))
	check("a negative boost never goes below silent", played({voices = 2, boost = -5}).take(), "")

	-- the slider is read at every start: a change between two dialogs is heard
	w = played({voices = 9})
	check("first start at the top", w.args.Soloud_playEx[3], bits(10 / 9))
	_G.Game.SoundVolume = 1 * 65536 + 3 * 256 + 1
	w.fire("DrawNPCGreeting", {Text = "Another greeting for the same dialog.", NPC = 1})
	w.file("Another greeting for the same dialog.")
	w.fire("Tick")
	check("slider moved to 3: the next voice is quieter", w.args.Soloud_playEx[3], bits(4 / 9))

	-- console helper and log: what was read is "sound slider,voices slider"
	world({soundVolume = 5, voices = 3})
	check("console helper", _G.MawVoices.VolumeInfo(), "5,3")
	local logPath = appDir .. "NPCVoicesLog.txt"
	os.remove(logPath)
	w = world({soundVolume = 5, voices = 3})
	_G.MawVoices.Log = true
	w.file(GREET)
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	local f = io.open(logPath, "rb")
	local content = f and f:read("*a") or ""
	if f then f:close() end
	os.remove(logPath)
	check("log shows the sound and the voices slider", content:find("vol=5,3", 1, true) ~= nil, true)
end

do  -- switched off in MAWSettings.lua: nothing is registered
	local w = world({npcVoices = false})
	check("npcVoices=false defines nothing", next(w.handlers) == nil and _G.MawVoices == nil, true)
end

do  -- no soloud_x86.dll: no crash, no sound
	local w = world({noSoloud = true})
	w.file(GREET)
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	w.fire("ExitNPC", 1)
	check("missing dll is harmless", w.take(), "")
end

do  -- a file the decoder rejects is released again
	local w = world({loadFails = true})
	w.file(GREET)
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	check("failed load is cleaned up", w.take(), "Soloud_create Soloud_init Wav_create Wav_load Wav_destroy")
end

do  -- repeated errors switch the module off instead of flooding
	local w = world({fail = "Soloud_playEx"})
	w.fire("EnterAnyNPC", {})
	for i = 1, 40 do
		local text = "Line number " .. i .. " of the test."
		w.file(text)
		w.fire("DrawNPCGreeting", {Text = text, NPC = 1})
		local ok = pcall(w.fire, "Tick")
		check("tick never raises (" .. i .. ")", ok, true)
	end
	check("module disables itself after repeated errors", _G.MawVoices.Enabled, false)
end

do  -- clicking a topic whose answer is the same text as before plays it again
	local w = world()
	w.file(TOPIC)
	w.fire("EnterAnyNPC", {})
	_G.Game.NPCMessage = TOPIC
	w.fire("Tick")
	w.take()
	w.fire("Tick")
	check("no click, no replay", w.take(), "")
	w.fire("ClickNPCTopic", 5)
	w.fire("Tick")
	check("click replays the same answer", w.take(), STOP .. " " .. PLAY)
	w.fire("Tick")
	check("one click, one replay", w.take(), "")

	-- a click that brings a new answer plays it once, not twice
	local other = "A different answer to the next topic."
	w.file(other)
	w.fire("ClickNPCTopic", 6)
	_G.Game.NPCMessage = other
	w.fire("Tick")
	check("click with a new answer plays once", w.take(), STOP .. " " .. PLAY)
	w.fire("Tick")
	check("and not again", w.take(), "")
end

do  -- the same topic in the next dialog (Game.NPCMessage still holds its text) plays after the click
	local w = world({leftover = TOPIC})
	w.file(TOPIC)
	w.fire("ClickNPCTopic", 5)  -- no dialog open: ignored
	w.fire("EnterAnyNPC", {})
	w.fire("Tick")
	check("click outside a dialog is ignored", w.take(), "")
	w.fire("ClickNPCTopic", 5)
	w.fire("Tick")
	check("repeat in a new dialog plays", w.take(), "Soloud_create Soloud_init " .. PLAY)
end

do  -- loading a game, leaving the map and the main menu stop the voice
	for _, event in ipairs({"LeaveGame", "LeaveMap"}) do
		local w = world()
		w.file(GREET)
		w.fire("EnterAnyNPC", {})
		w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
		w.fire("Tick")
		w.take()
		w.fire(event)
		check(event .. " stops the voice", w.take(), STOP)
	end
end

do  -- leaving a dialog lets a long text run on; the stop key ends it; the repeat key plays the last three again
	local w = world()
	local g1, g2, g3, g4 = "Greeting one.", "Greeting two.", "Greeting three.", "Greeting four."
	for _, g in ipairs({g1, g2, g3, g4}) do
		w.file(g)
	end
	local function say(text)
		w.fire("EnterAnyNPC", {})
		w.fire("DrawNPCGreeting", {Text = text, NPC = 1})
		w.fire("Tick")
	end
	say(g1)
	w.take()
	w.fire("ExitAnyNPC")
	check("leaving the dialog does not stop the voice", w.take(), "")
	w.fire("KeyDown", {Key = 121})
	check("the stop key ends the voice", w.take(), STOP)
	say(g2)
	say(g3)
	say(g4)
	w.take()
	w.fire("KeyDown", {Key = 120})
	check("repeat key waits before it plays", w.take(), STOP)
	w.now = w.now + 0.25
	w.fire("Tick")
	check("... then plays the last recording", w.take(), PLAY)
	check("... the last one", w.args.Wav_load[2]:find(_G.MawVoices.Key(g4), 1, true) ~= nil, true)
	w.now = w.now + 1
	w.fire("KeyDown", {Key = 120})
	w.now = w.now + 0.25
	w.fire("Tick")
	check("second press within the window: the one before", w.args.Wav_load[2]:find(_G.MawVoices.Key(g3), 1, true) ~= nil, true)
	w.take()
	w.now = w.now + 5
	w.fire("KeyDown", {Key = 120})
	w.now = w.now + 0.05
	w.fire("KeyDown", {Key = 120})
	w.now = w.now + 0.05
	w.fire("KeyDown", {Key = 120})
	w.now = w.now + 0.05
	w.fire("Tick")
	check("three quick presses start nothing yet", w.take():find("Wav_load", 1, true), nil)
	w.now = w.now + 0.25
	w.fire("Tick")
	check("then only the third recording", w.take(), PLAY)
	check("... the one before that", w.args.Wav_load[2]:find(_G.MawVoices.Key(g2), 1, true) ~= nil, true)
	w.now = w.now + 5
	w.fire("KeyDown", {Key = 120})
	w.now = w.now + 0.25
	w.fire("Tick")
	check("after the window the count starts again", w.args.Wav_load[2]:find(_G.MawVoices.Key(g4), 1, true) ~= nil, true)
	w.take()
	w.fire("KeyDown", {Key = 99})
	check("other keys do nothing", w.take(), "")
end

do  -- a new dialog starts without the old voice
	local w = world()
	w.file(GREET)
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	w.take()
	w.fire("EnterAnyNPC", {})  -- the exit event never came
	check("entering stops a stale voice", w.take(), STOP)
end

do  -- an error while stopping never reaches the engine's exit events
	local w = world()
	w.file(GREET)
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	w.failNow = "Soloud_stop"
	check("exit does not raise", (pcall(w.fire, "ExitNPC", 1)), true)
	check("dialog state is cleared anyway", (pcall(w.fire, "Tick")), true)
end

do  -- a damaged .ogg falls back to the .wav of the same key
	local w = world({rejectOgg = true})
	w.file(GREET)
	local key = w.file(GREET, ".wav")
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	check("wav fallback", w.take(), "Soloud_create Soloud_init Wav_create Wav_load Wav_destroy " .. PLAY)
	check("fallback file", basename(w.args.Wav_load[2]), key .. ".wav")
end

do  -- occasional errors do not add up; only an unbroken run of them switches the module off
	local w = world()
	w.fire("EnterAnyNPC", {})
	local n = 0
	local function line()
		n = n + 1
		local text = "Counting line number " .. n .. " of this test."
		w.file(text)
		w.fire("DrawNPCGreeting", {Text = text, NPC = 1})
		w.fire("Tick")
	end
	for _ = 1, 3 do
		w.failNow = "Soloud_playEx"
		for _ = 1, 15 do line() end
		w.failNow = nil
		line()
	end
	check("scattered errors keep the module on", _G.MawVoices.Enabled, true)
end

do  -- guards and monsters: the NPCNews text of the monster's group, after the greeting delay; a script may override it
	local GUARD = "The guard says: halt, traveler, and mind the road."
	local OVERRIDE = "A script made this guard say something else entirely."
	local function guardWorld(opts)
		local w = world(opts)
		-- NPCGroup.txt as the game keeps it: 16-bit news numbers, group g at (g - 1) * 2
		_G.Game.NPCGroup = {["?ptr"] = 1000}
		_G.Game.NPCNews = {[7] = GUARD}
		_G.mem.i2[1002] = 7   -- group 2 -> news 7
		_G.mem.i2[1004] = 0   -- group 3 -> no news
		w.file(GUARD)
		w.file(OVERRIDE)
		return w
	end
	local w = guardWorld({delay = 1.0})
	w.fire("SpeakWithMonster", {Monster = {Group = 2}})
	check("guard waits for its own hello to end", w.take(), "")
	w.now = 0.5
	w.fire("Tick")
	check("still waiting after half a second", w.take(), "")
	w.now = 1.2
	w.fire("Tick")
	check("guard speaks after the greeting delay, outside of any dialog", w.take(), "Soloud_create Soloud_init " .. PLAY)
	check("guard file", basename(w.args.Wav_load[2]), _G.MawVoices.Key(GUARD) .. ".ogg")
	w.now = 3
	w.fire("Tick")
	check("guard speaks once", w.take(), "")

	-- Game.NPCMessage keeps the text of the last dialog and a greeting may have been drawn: outside of a dialog
	-- neither is played, they must not stop or replace the guard's waiting line
	w = guardWorld({delay = 1.0})
	w.file(TOPIC)
	_G.Game.NPCMessage = TOPIC
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("SpeakWithMonster", {Monster = {Group = 2}})
	w.fire("Tick")
	check("a leftover dialog text is not played outside of a dialog", w.take(), "")
	w.now = 1.5
	w.fire("Tick")
	check("the guard's line plays, nothing else", w.take(), "Soloud_create Soloud_init " .. PLAY)
	check("it is the guard's file", basename(w.args.Wav_load[2]), _G.MawVoices.Key(GUARD) .. ".ogg")

	-- trouble with the audio while a guard line starts is caught and does not repeat every frame
	w = guardWorld({delay = 1.0, fail = "Soloud_playEx"})
	w.fire("SpeakWithMonster", {Monster = {Group = 2}})
	w.now = 1.5
	check("an audio error at the start of a guard line never raises", (pcall(w.fire, "Tick")), true)
	w.take()
	w.now = 2.5
	w.fire("Tick")
	check("and the line is not retried", w.take(), "")

	-- speaking again restarts the wait; a dialog, leaving or switching off drops a waiting line
	w = guardWorld({delay = 1.0})
	w.fire("SpeakWithMonster", {Monster = {Group = 2}})
	w.now = 1.2
	w.fire("Tick")
	w.take()
	w.now = 3
	w.fire("SpeakWithMonster", {Monster = {Group = 2}})
	check("speaking again stops the old line and waits anew", w.take(), STOP)
	w.now = 3.5
	w.fire("Tick")
	check("the new wait is not over yet", w.take(), "")
	w.fire("EnterAnyNPC", {})
	w.now = 5
	w.fire("Tick")
	check("opening a dialog drops the waiting guard line", w.take(), "")

	w = guardWorld({delay = 1.0})
	w.fire("SpeakWithMonster", {Monster = {Group = 2}})
	w.fire("LeaveMap")
	w.now = 2
	w.fire("Tick")
	check("leaving the map drops the waiting guard line", w.take(), "")

	w = guardWorld({delay = 1.0})
	w.fire("SpeakWithMonster", {Monster = {Group = 2}})
	_G.MawVoices.Enabled = false
	w.fire("Tick")
	_G.MawVoices.Enabled = true
	w.now = 2
	w.fire("Tick")
	check("switching off drops the waiting guard line", w.take(), "")

	w = guardWorld()
	w.fire("SpeakWithMonster", {Monster = {Group = 2}, Result = OVERRIDE})
	check("a text set by a script wins", basename(w.args.Wav_load[2]), _G.MawVoices.Key(OVERRIDE) .. ".ogg")

	w = guardWorld()
	w.fire("SpeakWithMonster", {Monster = {Group = 2}, Result = ""})
	check("an empty text shows and says nothing", w.take(), "")
	w.fire("SpeakWithMonster", {Monster = {Group = 0}})
	check("a monster without group says nothing", w.take(), "")
	w.fire("SpeakWithMonster", {Monster = {Group = 3}})
	check("a group without news says nothing", w.take(), "")
	w.fire("SpeakWithMonster", {Monster = {Group = 2}})
	w.take()
	w.fire("SpeakWithMonster", {Monster = {Group = 2}})
	check("speaking again replays", w.take(), STOP .. " " .. PLAY)

	w = guardWorld()
	check("a broken event never raises", (pcall(w.fire, "SpeakWithMonster", {})), true)
	check("also without any table", (pcall(w.fire, "SpeakWithMonster")), true)
	_G.MawVoices.Enabled = false
	w.take()
	w.fire("SpeakWithMonster", {Monster = {Group = 2}})
	check("switched off: silent", w.take(), "")

	-- the log tells what the guard said and that nothing was recorded if so
	local logPath = appDir .. "NPCVoicesLog.txt"
	os.remove(logPath)
	w = guardWorld()
	_G.MawVoices.Log = true
	_G.Game.NPCNews[7] = "Nobody recorded this guard line, said the sergeant."
	w.fire("SpeakWithMonster", {Monster = {Group = 2}})
	w.fire("SpeakWithMonster", {})
	local f = io.open(logPath, "rb")
	local content = f and f:read("*a") or ""
	if f then f:close() end
	os.remove(logPath)
	check("log: guard line without recording is missing", content:find("guard    %x%x%x%x%x%x%x%x missing") ~= nil, true)
	check("log: an error in the guard hook is written", content:find("guard    error:", 1, true) ~= nil, true)
end

local SHARED = "Merchant skill is raised for a small fee, dear traveler."

do  -- the recording of the NPC's gender comes first; names are read from names.tsv
	local w = world()
	w.names("keri\tf\nbud\tm\nqueen catherine\tf\n")
	local key = w.file(SHARED)           -- <key>.ogg: the default voice
	w.file(SHARED, ".ogg", "f")          -- <key>-f.ogg: the same text in the other voice
	local function played(npc)
		w.fire("ExitNPC", 1)
		w.take()
		w.args.Wav_load = nil
		_G.Game.NPCMessage = ""
		w.fire("EnterAnyNPC", npc and {NPC = npc} or {})
		_G.Game.NPCMessage = SHARED
		w.fire("Tick")
		return w.take():find("Wav_load", 1, true) and basename(w.args.Wav_load[2]) or "nothing"
	end
	check("a woman gets the female recording", played({Name = "Keri"}), key .. "-f.ogg")
	check("case and surname do not matter", played({Name = "KERI Brown"}), key .. "-f.ogg")
	check("a whole listed name counts", played({Name = "Queen Catherine"}), key .. "-f.ogg")
	check("a man without a male recording gets the default", played({Name = "Bud"}), key .. ".ogg")
	check("an unlisted name gets the default", played({Name = "Zzyzx"}), key .. ".ogg")
	check("no NPC struct gets the default", played(nil), key .. ".ogg")
	check("an NPC without a name gets the default", played({}), key .. ".ogg")
	check("GenderOf answers for the console", _G.MawVoices.GenderOf("Keri") .. tostring(_G.MawVoices.GenderOf(42)), "fnil")

	-- a text that has no recording of that gender plays the default for everybody
	local plain = "Nobody recorded this one twice, said the old sailor."
	local plainKey = w.file(plain)
	w.fire("ExitNPC", 1)
	w.take()
	w.fire("EnterAnyNPC", {NPC = {Name = "Keri"}})
	_G.Game.NPCMessage = plain
	w.fire("Tick")
	check("no second recording: default plays", basename(w.args.Wav_load[2]), plainKey .. ".ogg")
	w.names(nil)
end

do  -- without names.tsv every dialog still plays the default voice
	local w = world()
	w.names(nil)
	local key = w.file(SHARED)
	w.file(SHARED, ".ogg", "f")
	w.fire("EnterAnyNPC", {NPC = {Name = "Keri"}})
	_G.Game.NPCMessage = SHARED
	w.fire("Tick")
	check("missing names file", basename(w.args.Wav_load[2]), key .. ".ogg")
end

do  -- a greeting starts after the delay (the NPC's own "hello" is still playing); the default is 1 second
	local w = world({delay = 1.0})
	check("default delay", w.defaultDelay, 1.0)
	w.file(GREET)
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	check("greeting waits", w.take(), "")
	w.now = 0.9
	w.fire("Tick")
	check("still waiting", w.take(), "")
	w.now = 1.0
	w.fire("Tick")
	check("greeting starts after the delay", w.take(), "Soloud_create Soloud_init " .. PLAY)
	w.now = 5
	w.fire("Tick")
	check("and only once", w.take(), "")

	-- leaving during the wait cancels it
	w = world({delay = 1.0})
	w.file(GREET)
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	w.fire("ExitNPC", 1)
	w.now = 3
	w.fire("Tick")
	check("exit cancels a waiting greeting", w.take(), "")

	-- an answer to a topic does not wait, and the greeting is gone
	w = world({delay = 1.0})
	w.file(GREET)
	w.file(TOPIC)
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	_G.Game.NPCMessage = TOPIC
	w.fire("Tick")
	check("topic answer plays at once", w.take(), "Soloud_create Soloud_init " .. PLAY)
	w.now = 2
	w.fire("Tick")
	check("the waiting greeting was dropped", w.take(), "")

	-- a new dialog never inherits a greeting that was still waiting
	w = world({delay = 1.0})
	w.file(GREET)
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	w.fire("EnterAnyNPC", {})  -- the exit event never came
	w.now = 3
	w.fire("Tick")
	check("a waiting greeting does not survive a new dialog", w.take(), "")

	-- a click that brings no new answer (a sub-screen) drops the waiting greeting as well
	w = world({delay = 1.0})
	w.file(GREET)
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	w.fire("ClickNPCTopic", 3)
	w.fire("Tick")
	w.now = 3
	w.fire("Tick")
	check("a click drops the waiting greeting", w.take(), "")

	-- switched off from the console while a greeting waits: it does not start after switching on again
	w = world({delay = 1.0})
	w.file(GREET)
	w.fire("EnterAnyNPC", {})
	w.fire("DrawNPCGreeting", {Text = GREET, NPC = 1})
	w.fire("Tick")
	_G.MawVoices.Enabled = false
	w.fire("Tick")
	_G.MawVoices.Enabled = true
	w.now = 3
	w.fire("Tick")
	check("switching off drops the waiting greeting", w.take(), "")

	-- the console starts a recording at once, whatever the greeting delay
	w = world({delay = 1.0})
	w.file(GREET)
	_G.MawVoices.Play(GREET)
	check("console Play has no delay", w.take(), "Soloud_create Soloud_init " .. PLAY)
end

do  -- the log names the NPC, its gender and whether the recording of that gender was used
	local logPath = appDir .. "NPCVoicesLog.txt"
	os.remove(logPath)
	local w = world()
	_G.MawVoices.Log = true
	w.names("keri\tf\n")
	w.file(SHARED)
	w.file(SHARED, ".ogg", "f")
	w.fire("EnterAnyNPC", {NPC = {Name = "Keri"}})
	_G.Game.NPCMessage = SHARED
	w.fire("Tick")
	local f = io.open(logPath, "rb")
	local content = f and f:read("*a") or ""
	if f then f:close() end
	os.remove(logPath)
	w.names(nil)
	check("log line shows NPC, gender and variant", content:find("| Keri f alt", 1, true) ~= nil, true)
	check("log line still shows play and kind", content:find("topic    %x%x%x%x%x%x%x%x play") ~= nil, true)
end

do  -- texts with placeholders: the pattern finds the recording, the NPC's voice is chosen as for other texts
	-- hire pitch: one percent value, then a note in brackets; greeting: the name is left out of the recording
	local PITCH_PATTERN = "^i'll join you for 200 gold and (.-) percent of all the gold we find%.$"
	local GREETING_PATTERN = "^back again, .-%?$"
	local TSV = "aaaa1111\t" .. PITCH_PATTERN .. "\t17\t17\n" .. "bbbb2222\t" .. GREETING_PATTERN .. "\t\t\n"
	local PITCH = "I'll join you for 200 gold and 2 percent of all the gold we find."
	local function recording(w, key, gender)
		local f = assert(io.open(appDir .. "Data\\Voices\\NPC\\" .. key .. (gender and "-" .. gender or "") .. ".ogg", "wb"))
		f:write("x")
		f:close()
	end

	local w = world()
	w.templates(TSV)
	recording(w, "taaaa1111~2")
	recording(w, "tbbbb2222")
	w.fire("EnterAnyNPC", {})
	_G.Game.NPCMessage = PITCH .. "\n(Unlimited weapon repair. Tracie takes 2 percent of all gold you find. Click again to hire Tracie.)"
	w.fire("Tick")
	check("hire pitch with its note plays", w.take(), "Soloud_create Soloud_init " .. PLAY)
	check("hire pitch file", basename(w.args.Wav_load[2]), "taaaa1111~2.ogg")

	w.fire("DrawNPCGreeting", {Text = "Back again, Tracie?", NPC = 1})
	w.fire("Tick")
	check("a greeting with a name plays", w.take(), STOP .. " " .. PLAY)
	check("greeting file", basename(w.args.Wav_load[2]), "tbbbb2222.ogg")

	_G.Game.NPCMessage = PITCH:gsub("2 percent", "3 percent")
	w.fire("Tick")
	check("a value without a recording stays silent", w.take(), STOP)

	_G.Game.NPCMessage = "Back again, Tracie? Something else follows."
	w.fire("Tick")
	check("a text that only starts like the template is not matched", w.take(), "")

	-- the voice of the NPC's gender is preferred, as for plain texts
	w.names("tracie\tf\n")
	recording(w, "taaaa1111~2", "f")
	w.fire("EnterAnyNPC", {NPC = {Name = "Tracie"}})
	_G.Game.NPCMessage = PITCH
	w.fire("Tick")
	check("template recording of the NPC's gender plays", basename(w.args.Wav_load[2]), "taaaa1111~2-f.ogg")
	w.names(nil)

	-- an exact recording of the shown text wins over a template
	w = world()
	w.templates(TSV)
	recording(w, "tbbbb2222")
	w.file("Back again, Tracie?")
	w.fire("EnterAnyNPC", {})
	_G.Game.NPCMessage = "Back again, Tracie?"
	w.fire("Tick")
	check("own recording wins", basename(w.args.Wav_load[2]), _G.MawVoices.Key("Back again, Tracie?") .. ".ogg")

	-- no templates.tsv, or a damaged line: nothing breaks
	w = world()
	w.fire("EnterAnyNPC", {})
	_G.Game.NPCMessage = PITCH
	w.fire("Tick")
	check("no templates file is fine", w.take(), "")
	w = world()
	w.templates("broken line\nbad\t^(\t\t\n" .. TSV)
	recording(w, "tbbbb2222")
	w.fire("EnterAnyNPC", {})
	_G.Game.NPCMessage = "Back again, Tracie?"
	w.fire("Tick")
	check("a damaged pattern is skipped, the rest works", w.take(), "Soloud_create Soloud_init " .. PLAY)

	-- a pattern the load-time check does not catch (it is damaged after its first literal) is switched off
	-- when it raises while matching, and the patterns behind it still work
	w = world()
	w.templates("cccc3333\t^back again(\t\t\n" .. "dddd4444\t^back again%\t\t\n" .. TSV)
	recording(w, "tbbbb2222")
	recording(w, "taaaa1111~2")
	w.fire("EnterAnyNPC", {})
	_G.Game.NPCMessage = "Back again, Marcello?"
	w.fire("Tick")
	check("a late-damaged pattern does not hide the others", w.take(), "Soloud_create Soloud_init " .. PLAY)
	check("the right recording plays", basename(w.args.Wav_load[2]), "tbbbb2222.ogg")
	_G.Game.NPCMessage = PITCH
	w.fire("Tick")
	check("and the pitch is found as well", basename(w.args.Wav_load[2]), "taaaa1111~2.ogg")
	check("MawVoices.TemplateKey does not raise on it either", _G.MawVoices.TemplateKey("Back again, Marcello?"), "tbbbb2222")

	-- a byte order mark in front of the first line
	w = world()
	w.templates("\239\187\191" .. TSV)
	check("a byte order mark is ignored", _G.MawVoices.TemplateKey("Back again, Tracie?"), "tbbbb2222")

	-- no unbounded work: a very long text, or one with very many brackets, is answered quickly
	w = world()
	w.templates(TSV)
	local many = ("(x) "):rep(300) .. ")"
	local started = realClock()
	check("many brackets give no match", _G.MawVoices.TemplateKey(many), nil)
	check("a very long text is not matched", _G.MawVoices.TemplateKey(("a"):rep(5000)), nil)
	check("the work for those is bounded", realClock() - started < 1, true)
	w.templates(nil)
end

if #failures > 0 then
	return ("FAIL %d of %d checks:\n   %s"):format(#failures, checks, table.concat(failures, "\n   "))
end
return ("OK %d checks"):format(checks)
