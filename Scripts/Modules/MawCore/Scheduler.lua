-- Scheduler.lua -- one events.Tick for the whole core: named tasks with
-- real-time intervals instead of N raw Tick handlers.
--
-- Game-TIME scheduling stays with MMExtension's Timer()/RefillTimer().
-- Cadence rules and what must never be throttled: NOTES.md.

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

-- Run a task next frame regardless of its interval (event pokes).
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
