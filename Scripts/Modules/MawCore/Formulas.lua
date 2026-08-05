-- Formulas.lua -- single source of truth for gameplay formulas that used to
-- be copy-pasted between the EFFECT site (damage pipeline, regen tick, stat
-- rows) and one or more DISPLAY sites (skill tooltips, spell texts, item
-- tooltips). Every function here is the effect site's version lifted
-- verbatim -- where a display copy had drifted from it, the display now
-- shows what the effect actually does.
--
-- Pure functions only: values in, value out. No events, no engine access,
-- no state. Callers pass plain numbers (fullHP, skill, mastery) so display
-- code can evaluate "what if" variants (other masteries, skill+1) through
-- the same source.
--
-- Related single sources that already exist and are NOT duplicated here:
--   * Game.GetStatisticEffect(stat) -- the stat->effect breakpoints, re-
--     curved by the mod in zzMaw-Stats' events.GetStatisticEffect (>=25 ->
--     floor(stat/5)). Call it directly; the hand-rolled inline copies of
--     the curve were replaced with calls to it.
-- NOTE: monster resistances use a different curve entirely -- resDivide in
-- Damage.lua is damage/2^(res/100), not the (1+power/100) divisor below.

local Formulas = {}
MawCore.Formulas = Formulas

-- The % shown for the "divide by (1 + power/100)" damage reduction (shaman
-- Air / DK Body / DK Dark class reductions, resistance-enchant displays,
-- map reduction affixes). decimals = 2 for two shown digits, anything else
-- means the usual one.
function Formulas.reductionPercent(power, decimals)
	local f = decimals == 2 and 100 or 10
	local fraction = 1 - 1/(power/100 + 1)
	return round(fraction * 100 * f) / f
end

-- Regeneration skill: HP per second at full health. The GM low-HP
-- amplification stays at the effect site (it depends on current HP).
-- Effect: getBuffHealthRegen (zzMAW-Skills); display: skill 30 tooltip.
local regenEffect = {[0] = 0, 2, 4, 6, 6}
function Formulas.hpRegenPerSec(fullHP, s, m)
	return fullHP^0.5 * s^1.65 * (regenEffect[m]/350) + s
end

-- Meditation skill: SP per second (GM counts as mastery 5).
-- Effect: MawRegen's SP loop (zzMAW-Skills; per tick = this /10);
-- display: skill 28 tooltip.
function Formulas.spRegenPerSec(fullSP, s, m)
	if m == 4 then
		m = 5
	end
	return fullSP^0.35 * s^1.4 * ((m+1)/200) + 0.2
end

-- Shaman melee hit: HP leeched per hit (Body magic skill s, mastery m).
-- Effect: stage_shamanOnHit (MawCore/Damage.lua); display: Body school
-- tooltip. The tooltip used to claim (1 + m/2) where the effect applies
-- (0.5 + m/2); the effect version is the truth kept here.
function Formulas.bodyLeech(fullHP, s, m)
	return math.max(round(fullHP^0.5 * s^1.5/70 * (0.5 + m/2)), s)
end

-- Shaman melee hit: SP restored (Mind magic skill s).
-- Effect: stage_shamanOnHit; display: Mind school tooltip (rounded there).
function Formulas.mindLeech(s)
	return s^1.25
end

-- Death Knight active Blood Leech per hit (spell 68; spell 74 doubles the
-- result at its call sites). Body magic skill s at mastery m.
-- Effect: stage_dkAttack (MawCore/Damage.lua); display: Game.SpellsTxt
-- mastery rows (zzClasses dkSkills), which used to apply the s*2 floor
-- before the mastery multiplier instead of after.
function Formulas.bloodLeech(fullHP, s, m)
	return math.max(fullHP^0.5 * s^1.5/70 * (1 + m/4), s*2)
end

-- Death Knight passive on-hit leech (shrinks vs higher-level monsters).
-- Effect: stage_dkAttack; display: Body school tooltip, which passes
-- fullHP=100 to show it as a % of full HP vs same-level monsters.
function Formulas.dkPassiveLeech(fullHP, s, monsterLevel)
	return fullHP * (s/round(monsterLevel^0.7)) * 0.05
end

-- Regeneration BUFF/potion: HP per second for the buff's stored skill.
-- Effect: both branches of getBuffHealthRegen (zzMAW-Skills); the
-- buffRework spell variant beside it scales differently and stays inline.
function Formulas.hpRegenBuffPerSec(fullHP, s, m)
	return fullHP^0.5 * s^1.25 * ((m+1)/1000)
end

-- Assassin passive: energy (SP) per second from Water magic mastery m.
-- Effect: MawRegen's SP loop (zzMAW-Skills; per tick = this /10);
-- display: the Poisoning skill mastery rows.
function Formulas.assassinEnergyPerSec(m)
	return (0.6 + m*0.2) * 10
end

------------------------------------------------------------------------
-- Item "bonus power" (MaxCharges) scaling. Effect sites live in itemStats
-- (zzMaw-Items collect* helpers); display sites in checktext / the artifact
-- stat preview (zzMaw-Items) and the item tooltips (MawCore/Tooltip.lua).
------------------------------------------------------------------------

-- Special-enchant (Bonus2) stat multiplier.
function Formulas.chargesStatMult(charges)
	return 1 + charges/20
end

-- Enchant weapon-damage scaling curve. Call sites clamp: the tooltip and
-- fire aura clamp the multiplier at 0.5, calcEnchantDamage clamps the
-- damage result instead.
function Formulas.chargesDamageScale(charges)
	return (0.5 + charges/20)^1.5
end

-- Spell-school skill bonus from school enchants (GetSkill slots 26-34).
function Formulas.chargesSchoolSkill(charges)
	return math.floor(charges/4) + 5
end

-- Meditation skill bonus from meditation-granting special enchants.
function Formulas.chargesMeditationSkill(charges)
	return math.floor(charges*3/20) + 3
end

-- Armor AC growth: the reference (top-tier sibling) AC scaled by charges.
function Formulas.chargesArmorAC(referenceAC, charges)
	return referenceAC * (charges/40)
end

-- Weapon attack / dice-sides growth: the reference stat scaled by charges
-- (also the staff attack bonus feeding party resistances).
function Formulas.chargesWeaponBonus(reference, charges)
	return reference * (charges/30)
end
