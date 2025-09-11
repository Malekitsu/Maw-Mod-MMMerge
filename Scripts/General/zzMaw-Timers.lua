--fix for timer events, specially online
local second=256/60
local minute=256
local hour=15360
local day=368640
local week=2580480
local month=10321920
local year=123863040

function events.Tick()
	vars.LastTime=vars.LastTime or Game.Time
	local timePassed=Game.Time-vars.LastTime
	if timePassed<0 or timePassed>hour then
		timePassed=0
	end
	local irlSeconds=timePassed/128
	MawTimer(irlSeconds)
	vars.LastTime=Game.Time
end

local MawTimers = {}

-- add a periodic task
function MawAddTimer(name, interval, fn)
  assert(type(fn) == "function", "MawAddTimer('"..tostring(name).."'): fn must be a function, got "..type(fn))
  MawTimers[name] = { interval = interval, acc = 0, fn = fn, enabled = true }
end

-- optional helpers
function MawEnableTimer(name, enabled)
  local t = MawTimers[name]; if t then t.enabled = (enabled ~= false) end
end

function MawRemoveTimer(name) MawTimers[name] = nil end
function MawSetInterval(name, interval) local t=MawTimers[name]; if t then t.interval = interval end end
function MawResetTimer(name) local t=MawTimers[name]; if t then t.acc = 0 end end

-- call this every frame with seconds since last frame
function MawTimer(dt)
  if not dt or dt <= 0 then return end
  for _, t in pairs(MawTimers) do
    if t.enabled then
      t.acc = t.acc + dt
      if t.acc >= t.interval then
        local fn = t.fn
        if fn then fn(t.acc) end   -- minimal guard: skip if fn is nil
        t.acc = 0
      end
    end
  end
end

-- register your timers (make sure these functions are defined BEFORE this point)
MawAddTimer("horizontalModeMasteries", 0.5, horizontalModeMasteries)
MawAddTimer("MawRegen", 0.1, function(elapsed) MawRegen(elapsed) end)
MawAddTimer("leecher", 0.5, leecher)
MawAddTimer("checkOutOfBound", 2, checkOutOfBound)
MawAddTimer("eliteRegen", 0.1, eliteRegen)
MawAddTimer("mappingRegen", 1, mappingRegen)
MawAddTimer("checkMapCompletition", 10, checkMapCompletition) -- double-check this name/spelling
MawAddTimer("nightmare", 0.5, nightmare)
MawAddTimer("elementalBuffs", 1, elementalBuffs)
MawAddTimer("mawBuffApply", 0.5, mawBuffApply)
MawAddTimer("elementalistStacksDecay", 0.1, elementalistStacksDecay)
MawAddTimer("poisonTimer", 1, poisonTimer)

