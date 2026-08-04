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

local Scheduler = {}
MawCore.Scheduler = Scheduler

local tasks = {}	-- array; execution order = registration order

-- Scheduler.every("buffDecay", 500, fn)	-- at most once per 500ms of real time
-- Scheduler.every("crosshair", 0, fn)		-- every frame; use sparingly
function Scheduler.every(id, ms, fn)
	for _, t in ipairs(tasks) do
		assert(t.id ~= id, ("scheduler: task %s already registered"):format(id))
	end
	tasks[#tasks + 1] = {id = id, ms = ms, fn = fn, last = 0}
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
		out[#out + 1] = ("  %-24s every %s"):format(
			t.id, t.ms == 0 and "frame" or (t.ms .. "ms"))
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
			if not t.removed and (t.ms == 0 or now - t.last >= t.ms) then
				t.last = now
				t.fn()
			end
		end
	end
end
