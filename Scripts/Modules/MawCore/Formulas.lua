-- Formulas.lua -- gameplay formulas shared by the code that APPLIES them
-- and the tooltips that PRINT them. Pure functions, no state.
-- Rationale and the two curves that must not be merged: NOTES.md.

local Formulas = {}
MawCore.Formulas = Formulas

Formulas.ringReductionDivisor = 200

function Formulas.resistanceEnchantPower(roll, isRing)
	if isRing then
		return roll*100/Formulas.ringReductionDivisor
	end
	return roll
end

-- Display % for the "divide by (1 + power/100)" reductions. decimals=2 for
-- two shown digits. Takes STORED power: run a raw ring roll through
-- resistanceEnchantPower first.
function Formulas.reductionPercent(power, decimals)
	local f = decimals == 2 and 100 or 10
	local fraction = 1 - 1/(power/100 + 1)
	return round(fraction * 100 * f) / f
end


Formulas.damageFloor = 0.1

Formulas.armorDivisorBase = 200
Formulas.armorDivisorPerLevel = 3
function Formulas.armorDamageTaken(ac, monsterLevel)
	local divisor = Formulas.armorDivisorBase + monsterLevel*Formulas.armorDivisorPerLevel
	return 1/(ac/divisor + 1)
end

Formulas.resistanceDivisorBase = 100
Formulas.resistanceDivisorPerLevel = 6
function Formulas.resistanceDamageTaken(resistance, monsterLevel)
	local divisor = Formulas.resistanceDivisorBase + monsterLevel*Formulas.resistanceDivisorPerLevel
	return 1/(resistance/divisor + 1)
end

function Formulas.enchantResistanceDamageTaken(itemResistance)
	return 1/(itemResistance/100 + 1)
end

Formulas.speedDodgeShare = 0.5
function Formulas.chanceToBeHit(speed, monsterLevel)
	local expected = estimateStat(monsterLevel)
	return 1/(1 + speed/(100 + expected)*Formulas.speedDodgeShare)
end

-- Vitality counts physical for half, the elements for the other half.
Formulas.physicalVitalityShare = 0.5

Formulas.hitAtPar    = 0.75	--attack == expected for the monster's level
Formulas.hitMax      = 1	--reached at hitOverPar above par
Formulas.hitMin      = 0.25	--floor
Formulas.hitOverPar  = 0.5

--one straight line through par, clamped at both ends
function Formulas.mawHitChance(atk, monsterLevel)
	local expected = getPlayerEstimatedAttack(monsterLevel)
	if not expected or expected <= 0 then
		return nil
	end
	local overPar = (Formulas.hitAtPar * 10 + atk)/(expected + 10) - 1
	local slope = (Formulas.hitMax - Formulas.hitAtPar)/Formulas.hitOverPar
	return math.min(math.max(Formulas.hitAtPar + overPar*slope, Formulas.hitMin), Formulas.hitMax)
end

--what the PlayerHitOrMiss hook rolls against; nil leaves the engine's roll
function Formulas.mawPlayerHitChance(pl, mon, range, bonus)
	local atk = (range == 0 and pl:GetMeleeAttack() or pl:GetRangedAttack()) + (bonus or 0)
	return Formulas.mawHitChance(atk, getMonsterLevel(mon))
end

function Formulas.critCap(madness)
	return madness and 5000 or 3000
end

function Formulas.critChance(luck, monsterLevel)
	return luck/math.min(500 + monsterLevel*9.5, 10000) + 0.05
end

function Formulas.critDiminishingLevel(monsterLevel, madness)
	return math.min(250 + monsterLevel*2.5, Formulas.critCap(madness))
end

function Formulas.critDamageMult(stat, monsterLevel, madness, isSpell)
	local dim = Formulas.critDiminishingLevel(monsterLevel, madness)
	if isSpell then
		return stat/(dim*4) + 1.5
	end
	return stat/dim + 1.5
end

Formulas.hpRegenRate = {0.06, 0.08, 0.10, 0.10}

function Formulas.hpRegenPerSec(fullHP, s, m)
	local rate = Formulas.hpRegenRate[math.min(m or 0, #Formulas.hpRegenRate)]
	if not rate or s <= 0 or fullHP <= 0 then
		return 0
	end
	local expected = getPlayerEstimatedHealth(s^1.4)
	return rate*math.sqrt(expected*fullHP)
end

Formulas.spRegenRate = {0.015, 0.02, 0.025, 0.025}

function Formulas.spRegenPerSec(fullSP, s, m)
	local rate = Formulas.spRegenRate[math.min(m or 0, #Formulas.spRegenRate)]
	if not rate or s <= 0 or fullSP <= 0 then
		return 0
	end
	local expected = getPlayerEstimatedMana(s^1.4)
	return rate*math.sqrt(expected*fullSP)
end

function Formulas.meditationRegenPerSec(fullSP, s, m, reserved, legendary20)
	reserved = math.min(math.max(reserved or 0, 0), 1)
	local pool = fullSP
	if reserved > 0 then
		pool = math.max(math.ceil(fullSP*(1 - reserved)^0.5), 0)
	end
	local regen = Formulas.spRegenPerSec(pool, s, m)
	if legendary20 and reserved > 0 then
		regen = regen*(1 + reserved)
	end
	return regen, pool
end

Formulas.enlightenmentManaPerSkill = {0.5, 1, 1.5, 2}

function Formulas.enlightenmentManaBonus(s, m)
	local t = Formulas.enlightenmentManaPerSkill
	local pct = t[math.min(m, #t)]
	if not pct then
		return 0
	end
	return pct/100*s
end

Formulas.legendary24Health = 0.10
Formulas.legendary24Mana = 0.05

-- Shaman melee hit: HP leeched (Body magic).
function Formulas.bodyLeech(fullHP, s, m)
	return math.max(round(fullHP^0.5 * s^1.5/70 * (0.5 + m/2)), s)
end

-- Shaman melee hit: SP restored (Mind magic).
function Formulas.mindLeech(s)
	return s^1.25
end

-- Death Knight active Blood Leech per hit (spell 74 doubles it at its
-- call sites).
function Formulas.bloodLeech(fullHP, s, m)
	return math.max(fullHP^0.5 * s^1.5/70 * (1 + m/4), s*2)
end

-- Death Knight passive on-hit leech; the Body tooltip passes fullHP=100
-- to show it as a % vs same-level monsters.
function Formulas.dkPassiveLeech(fullHP, s, monsterLevel)
	return fullHP * (s/estimateSkill(monsterLevel)) * 0.05
end

-- Regeneration buff/potion: HP/sec for the buff's stored skill.
function Formulas.hpRegenBuffPerSec(fullHP, s, m)
	return fullHP^0.5 * s^1.25 * ((m+1)/1000)
end

-- Assassin passive: energy (SP)/sec from Water magic mastery.
function Formulas.assassinEnergyPerSec(m)
	return (0.6 + m*0.2) * 10
end

------------------------------------------------------------------------
-- Item "bonus power" (MaxCharges) scaling -- itemStats applies these,
-- checktext and the item tooltips print them.
------------------------------------------------------------------------

-- Special-enchant (Bonus2) stat multiplier.
function Formulas.chargesStatMult(charges)
	return 1 + charges/20
end

-- Enchant weapon-damage curve; unclamped on purpose (NOTES.md).
function Formulas.chargesDamageScale(charges)
	return (0.5 + charges/20)^1.5
end

-- Spell-school skill bonus from school enchants.
function Formulas.chargesSchoolSkill(charges)
	return math.floor(charges/4) + 5
end

-- Meditation skill bonus from meditation-granting special enchants.
function Formulas.chargesMeditationSkill(charges)
	return math.floor(charges*3/20) + 3
end

-- Armor AC growth: reference (top-tier sibling) AC scaled by charges.
function Formulas.chargesArmorAC(referenceAC, charges)
	return referenceAC * (charges/40)
end

-- Weapon attack / dice-sides growth from the reference stat.
function Formulas.chargesWeaponBonus(reference, charges)
	return reference * (charges/30)
end
