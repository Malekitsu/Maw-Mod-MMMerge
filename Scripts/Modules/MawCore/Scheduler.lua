-- Scheduler.lua -- one events.Tick for the whole core.
--
-- The legacy mod has 57 raw events.Tick handlers, most doing work that does
-- not need to run every frame (GREENFIELD.md par.2). Here a task registers
-- once, with a name and a real-time interval; a single Tick handler drives
-- them all, and Scheduler.describe() lists exactly what runs and how often.
--
-- Scope note: this is for REAL-TIME / per-frame cadence work only. For
-- game-time scheduling MMExtension already provides Timer() and RefillTimer()
-- (Scripts/Core/timers.lua -- Game.Time based, per-map lifecycle). Use those
-- for anything that should follow the game clock; they are not duplicated here.
--
-- Deliberately NOT migrated here: the legacy dynamic transients -- handlers
-- that register `function events.Tick()` inside an action and self-remove
-- with events.Remove("Tick", 1). The number is a STACK LEVEL (the caller
-- removes itself; Core/EventsList.lua `replace`), so inside a scheduler task
-- that call would remove the scheduler's own shared Tick handler. Leave them
-- as raw events.Tick.

local Scheduler = {}
MawCore.Scheduler = Scheduler

local tasks = {}	-- array; execution order = registration order

-- Scheduler.every("buffDecay", 500, fn)	-- at most once per 500ms of real time
-- Scheduler.every("crosshair", 0, fn)		-- every frame; use sparingly
-- Scheduler.every("reskill", -1, fn)		-- poke-only: runs once at startup,
--											-- then only via Scheduler.now(id)
function Scheduler.every(id, ms, fn)
	assert(type(fn) == "function",
		("scheduler: task %s registered without a function"):format(id))
	for _, t in ipairs(tasks) do
		assert(t.id ~= id, ("scheduler: task %s already registered"):format(id))
	end
	tasks[#tasks + 1] = {id = id, ms = ms, fn = fn, last = 0}
end

-- Force a task to run on the next frame regardless of its interval -- for
-- "refresh immediately on this event" pokes (e.g. char-screen labels on
-- character switch) without giving up the task's slow steady cadence.
function Scheduler.now(id)
	for _, t in ipairs(tasks) do
		if t.id == id then
			t.last = 0
			return true
		end
	end
	return false
end

function Scheduler.remove(id)
	for i, t in ipairs(tasks) do
		if t.id == id then
			t.removed = true	-- so an in-progress frame skips it
			table.remove(tasks, i)
			return true
		end
	end
	return false
end

function Scheduler.describe()
	local out = {"scheduler tasks:"}
	for _, t in ipairs(tasks) do
		out[#out + 1] = ("  %-24s %s"):format(
			t.id, t.ms < 0 and "on poke only"
				or (t.ms == 0 and "every frame" or ("every " .. t.ms .. "ms")))
	end
	if #tasks == 0 then
		out[#out + 1] = "  (none)"
	end
	return table.concat(out, "\n")
end

function Scheduler.start()
	function events.Tick()
		local now = timeGetTime()	-- Core/timers.lua global, wrap-corrected ms
		-- run over a snapshot so a task adding/removing tasks cannot derail
		-- the iteration mid-frame
		local frame = {}
		for i, t in ipairs(tasks) do
			frame[i] = t
		end
		for _, t in ipairs(frame) do
			local due
			if t.ms < 0 then
				due = t.last == 0	-- poke-only: Scheduler.now resets last
			else
				due = t.ms == 0 or now - t.last >= t.ms
			end
			if not t.removed and due then
				t.last = now
				t.fn()
			end
		end
	end
end
