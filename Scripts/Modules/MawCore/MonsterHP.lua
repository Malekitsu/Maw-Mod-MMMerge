-- MonsterHP.lua -- real monster HP beyond the engine's 16-bit field.
--
-- The engine keeps a capped proxy HP (death check, AI, health bar all keep
-- working on it); the real pool lives in mapvars.MawMonsterHP[monsterIndex]
-- = {hp, max, proxy}. Registration happens at the recalc/spawn sites through
-- MawSetMonsterHP (compat global for the legacy files); damage flows through
-- the pipeline's "monster-hp" stage, which keeps ledger and proxy in sync.
--
-- The ledger is per map. LeaveMap is unreliable, so the wipe rule is:
-- on LoadMap, if the map differs from the previously visited one, the
-- entered map's stored ledger is stale (its monsters were rebuilt) and is
-- cleared; reloading a save on the same map keeps it.

local MonsterHP = {}
MawCore.MonsterHP = MonsterHP

local CAP = 32000	-- engine proxy FullHP cap (16-bit field; damage caps at 32500)

local function ledger()
	mapvars.MawMonsterHP = mapvars.MawMonsterHP or {}
	return mapvars.MawMonsterHP
end

-- real current HP of any monster
function MonsterHP.current(mon)
	local e = ledger()[mon:GetIndex()]
	if e then
		return e.hp
	end
	return mon.HP
end

-- real maximum HP of any monster
function MonsterHP.max(mon)
	local e = ledger()[mon:GetIndex()]
	if e then
		return e.max
	end
	return mon.FullHP
end

-- scale factor from engine (proxy) damage to real damage, for damage the
-- engine computed out of the proxy HP pool (e.g. Mass Distortion)
function MonsterHP.scale(mon)
	local e = ledger()[mon:GetIndex()]
	if e then
		return e.max / math.max(mon.FullHP, 1)
	end
	return 1
end

-- register a monster's real pool: caps the engine fields, keeps the given
-- fraction of current HP, ledgers the remainder. Replaces the retired
-- res-thousands halving at every recalc/spawn site.
function MonsterHP.apply(mon, realMax, fraction)
	realMax = math.max(round(realMax), 1)
	fraction = fraction or 1
	if fraction ~= fraction or fraction > 1 then	-- NaN (0/0) or overfull
		fraction = 1
	end
	local full = math.min(realMax, CAP)
	if full > 1000 then
		full = round(full/10)*10
	end
	mon.FullHP = full
	mon.HP = fraction > 0 and math.max(round(full*fraction), 1) or 0
	if realMax > CAP then
		ledger()[mon:GetIndex()] = {max = realMax, hp = realMax*fraction, proxy = mon.HP}
	else
		ledger()[mon:GetIndex()] = nil
	end
end

-- the pipeline stage: runs after track-and-clamp, before final-clamp.
-- Applies the real damage to the ledger and turns t.Result into the proxy
-- damage that keeps the engine HP tracking the real pool's percentage.
function MonsterHP.stage(t)
	local mon = t.Monster
	local e = ledger()[t.MonsterIndex]
	if not e then
		return
	end
	-- reconcile engine-side heals/regeneration/off-pipeline damage
	if mon.HP ~= e.proxy then
		e.hp = math.max(math.min(e.hp + (mon.HP - e.proxy)*(e.max/math.max(mon.FullHP, 1)), e.max), 0)
	end
	local real = t.Result
	local data = t.Hit
	if data and data.Spell == 44 then	-- engine computed this from the proxy pool
		real = real * (e.max/math.max(mon.FullHP, 1))
	end
	e.hp = e.hp - real
	if e.hp <= 0 then
		ledger()[t.MonsterIndex] = nil
		t.Result = 32500	-- >= any proxy HP: the engine kills it
		return
	end
	local target = math.max(math.ceil(e.hp/e.max*mon.FullHP), 1)
	t.Result = math.max(mon.HP - target, 0)
	e.proxy = mon.HP - t.Result
end

function MonsterHP.start()
	function events.LoadMap()
		local d = MawCore.Save.data()
		if d.monsterHPMap ~= Map.Name then
			mapvars.MawMonsterHP = {}
		end
		d.monsterHPMap = Map.Name
	end
	function events.MonsterKilled(mon, monId)
		if mapvars.MawMonsterHP and monId then
			mapvars.MawMonsterHP[monId] = nil
		end
	end
	-- compat global for the recalc/spawn sites in the legacy files
	MawSetMonsterHP = MonsterHP.apply
end
