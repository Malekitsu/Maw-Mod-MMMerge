local MonsterAttackSpeed = {}
MawCore.MonsterAttackSpeed = MonsterAttackSpeed

local KEY = "MawAttackSpeed"

local ATTACK_STATES = {
	[const.AIState.MeleeAttack] = true,
	[const.AIState.RangedAttack] = true,
	[const.AIState.RangedAttack2] = true,
	[const.AIState.CastSpell] = true,
	[const.AIState.RangedAttack4] = true,
}

local GONE_STATES = {
	[const.AIState.Dying] = true,
	[const.AIState.Dead] = true,
	[const.AIState.Removed] = true,
}

local progress = {}
local dirty = false

local function ledger()
	mapvars[KEY] = mapvars[KEY] or {}
	return mapvars[KEY]
end

function MonsterAttackSpeed.get(mon)
	local t = type(mapvars) == "table" and mapvars[KEY]
	return t and t[mon:GetIndex()] or 1
end

function MonsterAttackSpeed.set(mon, mult)
	assert(mult == nil or type(mult) == "number" and mult > 0,
		"monster attack speed: the multiplier must be a positive number")
	local index = mon:GetIndex()
	ledger()[index] = mult ~= 1 and mult or nil
	progress[index] = nil
	dirty = true
end

local function advance(index, mon, mult)
	local step = mon.CurrentActionStep
	local p = progress[index]
	if step == 0 then
		if not p or p.written ~= 0 then
			mon.AttackRecovery = math.floor(mon.AttackRecovery/mult + 0.5)
		end
		progress[index] = {exact = 0, written = 0}
		return
	end
	local dt = Game.TimeDelta2
	if p and dt > 0 and step == p.written + dt then
		p.exact = p.exact + dt*mult
		local last = mon.CurrentActionLength - 1
		if p.exact > last then
			p.exact = math.max(last, step)
		end
		p.written = math.floor(p.exact)
		mon.CurrentActionStep = p.written
	elseif not p or step ~= p.written then
		progress[index] = {exact = step, written = step}
	end
end

local function processed()
	if Game.TurnBased or type(mapvars) ~= "table" then
		return
	end
	local t = mapvars[KEY]
	if not t or not next(t) then
		return
	end
	local high = Map.Monsters.High
	for index, mult in pairs(t) do
		local mon = type(index) == "number" and index <= high and Map.Monsters[index]
		if not mon or GONE_STATES[mon.AIState] then
			t[index] = nil
			progress[index] = nil
		elseif ATTACK_STATES[mon.AIState] then
			advance(index, mon, mult)
		else
			progress[index] = nil
		end
	end
end

local function send()
	if not dirty then
		return
	end
	dirty = false
	if MawCore.Sync.inGame() and type(mapvars) == "table" and mapvars[KEY] then
		mawmapvarsend(KEY, mapvars[KEY])
	end
end

function MonsterAttackSpeed.start()
	function events.MonstersProcessed()
		processed()
	end
	function events.LoadMap()
		progress = {}
	end
	MawCore.Scheduler.every("monster-attack-speed/sync", 250, send)
	MawSetMonsterAttackSpeed = MonsterAttackSpeed.set
end
