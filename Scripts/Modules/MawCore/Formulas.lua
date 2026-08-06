-- Formulas.lua -- gameplay formulas shared by the code that APPLIES them
-- and the tooltips that PRINT them. Pure functions, no state.
-- Rationale and the two curves that must not be merged: NOTES.md.

local Formulas = {}
MawCore.Formulas = Formulas

-- Display % for the "divide by (1 + power/100)" reductions. decimals=2 for
-- two shown digits.
function Formulas.reductionPercent(power, decimals)
	local f = decimals == 2 and 100 or 10
	local fraction = 1 - 1/(power/100 + 1)
	return round(fraction * 100 * f) / f
end

-- Regeneration skill: HP/sec at full health (the GM low-HP amplification
-- stays at the effect site -- it needs current HP).
local regenEffect = {[0] = 0, 2, 4, 6, 6}
function Formulas.hpRegenPerSec(fullHP, s, m)
	return fullHP^0.5 * s^1.65 * (regenEffect[m]/350) + s
end

-- Meditation skill: SP/sec (GM counts as mastery 5).
function Formulas.spRegenPerSec(fullSP, s, m)
	if m == 4 then
		m = 5
	end
	return fullSP^0.35 * s^1.4 * ((m+1)/200) + 0.2
end

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
	return fullHP * (s/round(monsterLevel^0.7)) * 0.05
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
