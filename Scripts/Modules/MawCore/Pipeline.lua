-- Pipeline.lua -- ordered, named-stage processing chains.
--
-- This replaces the pattern the rebuild exists to kill (GREENFIELD.md par.2):
-- damage in the legacy mod is 35 anonymous CalcDamageToMonster handlers whose
-- execution order is file load order, readable nowhere. A pipeline declares
-- its stages once, in order; every handler joins a named stage under a unique
-- id; execution is stage order, then registration order within the stage; and
-- p:describe() prints the whole thing -- the one place to read the order.
--
-- Intended first use (NOT created yet -- migration starts after skeleton review):
--   local dmg = MawCore.Pipeline.new("DamageToMonster",
--       {"base", "class", "skills", "items", "legendaries", "resistances", "caps"})
--   dmg:on("skills", "regenLeech", function(ctx) ... end)
--   -- then ONE events.CalcDamageToMonster handler calls dmg:run(ctx).
--
-- Handlers mutate ctx and return nothing. Set ctx.Stop = true to halt the
-- run (remaining handlers and stages are skipped). Errors are not caught: a
-- broken handler should fail loudly in the console, exactly as a broken
-- event handler does today.

local Pipeline = {}
Pipeline.__index = Pipeline
MawCore.Pipeline = Pipeline

function Pipeline.new(name, stages)
	local self = setmetatable({name = name, order = {}, handlers = {}}, Pipeline)
	for _, stage in ipairs(stages or {}) do
		self:addStage(stage)
	end
	return self
end

local function stagePos(self, stage)
	for i, s in ipairs(self.order) do
		if s == stage then
			return i
		end
	end
end

-- addStage("poison")                    -- append at the end
-- addStage("poison", "after", "items")  -- insert relative to an existing stage
function Pipeline:addStage(stage, where, anchor)
	assert(not self.handlers[stage],
		("pipeline %s: stage %s already exists"):format(self.name, stage))
	local pos = #self.order + 1
	if where then
		local a = stagePos(self, anchor)
		assert(a, ("pipeline %s: no stage %s to insert %s %s"):format(
			self.name, tostring(anchor), stage, where))
		pos = (where == "before") and a or a + 1
	end
	table.insert(self.order, pos, stage)
	self.handlers[stage] = {}
	return self
end

-- Every handler carries a unique id within its stage. Ids are what make
-- describe() readable and single handlers replaceable during migration.
function Pipeline:on(stage, id, fn)
	local hs = assert(self.handlers[stage],
		("pipeline %s: no stage %s (registering %s)"):format(
			self.name, tostring(stage), tostring(id)))
	for _, h in ipairs(hs) do
		assert(h.id ~= id,
			("pipeline %s/%s: handler %s already registered"):format(self.name, stage, id))
	end
	hs[#hs + 1] = {id = id, fn = fn}
	return self
end

function Pipeline:remove(stage, id)
	local hs = self.handlers[stage]
	if not hs then
		return false
	end
	for i, h in ipairs(hs) do
		if h.id == id then
			table.remove(hs, i)
			return true
		end
	end
	return false
end

function Pipeline:run(ctx)
	for _, stage in ipairs(self.order) do
		for _, h in ipairs(self.handlers[stage]) do
			h.fn(ctx)
			if ctx.Stop then
				return ctx
			end
		end
	end
	return ctx
end

function Pipeline:describe()
	local out = {("pipeline %s:"):format(self.name)}
	for _, stage in ipairs(self.order) do
		out[#out + 1] = "  " .. stage
		for _, h in ipairs(self.handlers[stage]) do
			out[#out + 1] = "    - " .. h.id
		end
	end
	return table.concat(out, "\n")
end
