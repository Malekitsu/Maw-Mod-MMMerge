-- zzMaw-Timers.lua

-- Engine time constants
local second = 256/60
local minute = 256
local hour   = 15360
local day    = 368640
local week   = 2580480
local month  = 10321920
local year   = 123863040

-- Timer driver: robust against time rollbacks, but no ticking when paused
local FALLBACK_DT = 1/60   -- used ONLY when time goes backwards (<0)
local MAX_DT      = 0.25   -- cap to avoid huge bursts

function events.Tick()
  vars = vars or {}
  vars.LastTime = vars.LastTime or Game.Time

  local timePassed = Game.Time - vars.LastTime
  local dt

  if timePassed < 0 then
    -- Game time rolled back (common during loads/joins): keep timers alive a tiny step
    dt = FALLBACK_DT
  elseif timePassed == 0 then
    -- Paused or no advancement: do NOT tick regen or any periodic logic
    dt = 0
  elseif timePassed > hour then
    -- Huge jump: cap the step
    dt = MAX_DT
  else
    -- Normal advance: convert engine ticks to seconds (128 ticks/sec)
    dt = timePassed / 128
  end

  if dt > 0 then
    if dt > MAX_DT then dt = MAX_DT end
    MawTimer(dt)
  end

  vars.LastTime = Game.Time
end

-- Lightweight timer system
local MawTimers = {}

-- add a periodic task
function MawAddTimer(name, interval, fn)
  assert(type(fn) == "function", "MawAddTimer('"..tostring(name).."'): fn must be a function, got "..type(fn))
  MawTimers[name] = { interval = tonumber(interval) or 1, acc = 0, fn = fn, enabled = true }
end

-- optional helpers
function MawEnableTimer(name, enabled)
  local t = MawTimers[name]; if t then t.enabled = (enabled ~= false) end
end

function MawRemoveTimer(name) MawTimers[name] = nil end
function MawSetInterval(name, interval) local t = MawTimers[name]; if t then t.interval = tonumber(interval) or t.interval end end
function MawResetTimer(name) local t = MawTimers[name]; if t then t.acc = 0 end end

-- call this every frame with seconds since last frame
function MawTimer(dt)
  local MAX_STEPS = 10  -- safety cap to avoid infinite loops

  for _, t in pairs(MawTimers) do
    if t.enabled then
      t.acc = t.acc + dt
      local steps = 0
      while t.acc >= t.interval and steps < MAX_STEPS do
        local fn = t.fn
        if fn then fn(t.interval) end
        t.acc = t.acc - t.interval
        steps = steps + 1
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
