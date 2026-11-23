local MonsterHitstun = {}
MawCore.MonsterHitstun = MonsterHitstun

MonsterHitstun.nonMeleeCooldown = 3*const.Minute

local lastNonMeleeStun = {}

local function isMeleeHit(index)
	local who, target = WhoHitMonster()
	return who ~= nil and target == index and not who.Object and not who.Spell
		and (who.Player ~= nil or who.Monster ~= nil)
end

local function allowStun(index)
	if isMeleeHit(index) then
		return true
	end
	local last = lastNonMeleeStun[index]
	if last and Game.Time - last < MonsterHitstun.nonMeleeCooldown then
		return false
	end
	lastNonMeleeStun[index] = Game.Time
	return true
end

function MonsterHitstun.start()
	MawCore.Engine.setMonsterStunFilter(allowStun)
	function events.LoadMap()
		lastNonMeleeStun = {}
	end
end
