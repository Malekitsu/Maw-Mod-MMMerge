-- Estimates.lua -- the balance model: what an AVERAGE character of a given
-- level is expected to have (stats, health, vitality, damage), and the
-- monster numbers derived from it. Moved verbatim out of zzMaw-Stats.lua.
--
-- These are estimates, not live readings: they take a level and rebuild a
-- typical character from the same curves the real code uses (statsPerLevel,
-- skillDamage, armsmasterSkill, bodybuildingHP, GetMightDamageMultiplier).
-- When one of those curves is retuned, the matching term HERE must move too,
-- or monster HP/damage stops tracking player power.
--
-- The chain: estimateStat -> getPlayerEstimatedVitality / getPlayerEstimatedPower
-- -> getMonsterDamage / getMonsterHealth (monsters are sized as a ratio of the
-- expected player, via GetDifficulty's hits-to-kill tables).
--
-- Still globals on purpose: legacy files and other MawCore modules
-- (SkillTooltip, Damage) call them by bare name.

--A buff is worth nothing until expert and reaches its full value at master.
local function buffRamp(s)
	local th = masteryThresholds()
	return math.min(math.max((s-th[2])/(th[3]-th[2]), 0), 1)
end

local function gradualRow(tbl, s, m)
	if m <= 1 then
		return tbl[1] or 0
	end
	return GetGradualMasteryValue(tbl, s, m)
end

--the caps live in zzMAW-Skills (skillEffectCap), the same numbers getBuffSkill applies
local dayBuffs = {[83] = true, [85] = true, [86] = true}
local function casterSkill(spellId, s)
	return math.min(s, dayBuffs[spellId] and skillEffectCap.dayBuff or skillEffectCap.buff)
end

local CASTER_LEVEL_DIVISOR = 4
local STONESKIN_LEVEL_DIVISOR = 4
local function buffFlat(spellId, s, m, level, levelDivisor)
	local bf = buffPower[spellId]
	if not bf then
		return 0
	end
	local flat = gradualRow(bf.Base, s, m) + level/(levelDivisor or CASTER_LEVEL_DIVISOR)
	return flat*(1 + gradualRow(bf.Scaling, s, m)/100*casterSkill(spellId, s))*buffRamp(s)
end

local BUFF_MULT_PER_SKILL = 0.02
local function buffMult(spellId, s, m)
	local bf = buffPower[spellId]
	if not bf then
		return 0
	end
	return gradualRow(bf.Base, s, m)/100 * buffRamp(s) * (1 + BUFF_MULT_PER_SKILL*casterSkill(spellId, s))
end

--how fast the average character reaches the next mastery; the estimators use
--it wherever the real code would read a skill's mastery
local function masterLearned()
	if vars.madnessMode then
		return 30
	elseif vars.insanityMode then
		return 20
	end
	return 12
end

function estimateWeaponDamageMultiplier(level)
	return 1 + 0.02 * estimateSkill(level)
end

local LEGENDARY_START_LEVEL = 100
local LEGENDARY_FULL_LEVEL = 420	--exp-equivalent of the old 700 on the slowed curve
local function legendaryRamp(lvl)
	local t = (lvl - LEGENDARY_START_LEVEL)/(LEGENDARY_FULL_LEVEL - LEGENDARY_START_LEVEL)
	return math.min(math.max(t, 0), 1)
end

function skillPointsAtLevel(lvl)
	if lvl < 2 then
		return 0
	end
	local q = math.floor(lvl/10)
	local r = lvl - q*10
	return 5*(lvl-1) + 5*q*(q-1) + q*(r+1)
end

function skillLevelFromPoints(points)
	return (math.sqrt(1 + 8*(points+1)) - 1)/2
end

local SKILLS_TRAINED = 5
function estimateSkill(lvl)
	return skillLevelFromPoints(skillPointsAtLevel(lvl)/SKILLS_TRAINED)
end


WEAPON_BASE_DICE_DAMAGE = 8	--expected damage, spread over the dice; same on every weapon
WEAPON_TIER_FLAT_DAMAGE = 16	--flat damage a top-tier base type is worth; tier 1 gets none

function weaponTierFlat(tier)
	local IL = MawCore.ItemLevel
	tier = math.min(math.max(tier or IL.ExpectedTier, 1), IL.Tiers)
	return WEAPON_TIER_FLAT_DAMAGE*(tier - 1)/(IL.Tiers - 1)
end

WEAPON_FLAT_PER_LEVEL = 0.5	

function estimateWeaponFlat(lvl)
	return math.min(lvl*WEAPON_FLAT_PER_LEVEL, WEAPON_TIER_FLAT_DAMAGE)
end

--A point of item bonus power pays one channel whole instead of half of each: even points
--buy flat damage and attack, odd points buy the dice. Both values are two-handed and
--expected damage, like WEAPON_BASE_DICE_DAMAGE -- the dice one is doubled into the sides
--budget below, because a roll averages half of it.
WEAPON_FLAT_PER_POWER = 2	--flat damage and attack, on even points
WEAPON_DICE_PER_POWER = 2	--damage over the dice sides, on odd points

function getWeaponDamageForLevel(itemLevel, twoHanded, flat)
	local IL = MawCore.ItemLevel
	--above the power cap no real item can keep scaling, so neither does the model
	local power = math.min(IL.PowerFor(itemLevel), IL.MaxPower())
	local flatPower = math.floor(power/2)

	local powerFlat = WEAPON_FLAT_PER_POWER*flatPower
	local powerDice = WEAPON_DICE_PER_POWER*2*(power - flatPower)
	local diceOnly = WEAPON_BASE_DICE_DAMAGE*2 + powerDice
	local flatOnly = (flat or 0) + powerFlat
	--the average damage the item power added: what enchants and auras scale off
	local levelDamage = powerFlat + powerDice/2
	if not twoHanded then
		diceOnly = diceOnly/2
		flatOnly = flatOnly/2
		levelDamage = levelDamage/2
	end
	--nothing is left to split half and half: each channel is already whole
	return diceOnly + flatOnly, diceOnly, flatOnly, levelDamage
end

function estimateStatFlatDamage(level)
	return Game.GetStatisticEffect(estimateStat(level))
end

function getWeaponLevelDamage(itemLevel, twoHanded, weaponFlat)
	local _, _, _, levelDamage = getWeaponDamageForLevel(itemLevel, twoHanded, weaponFlat)
	local armsSkill = estimateSkill(itemLevel)*SKILL_ENCHANT_MULT

	local arms = GetGradualMasteryValue(armsmasterSkill.Damage, armsSkill,
		masteryForSkill(armsSkill))*armsSkill
	local statFlat = estimateStatFlatDamage(itemLevel)
	if not twoHanded then
		arms = arms/2
		statFlat = statFlat/2
	end
	local mightMult = 1 + GetMightDamageMultiplier(estimateStat(itemLevel), itemLevel)
	return ((levelDamage + arms)*estimateWeaponDamageMultiplier(itemLevel) + statFlat)*mightMult
end

local STAT_SHARE = 0.25

--Every enchant a fully geared character wears, added up.
--slots are: 2h weapon, cloak, helm, armor, gloves, boots, ring, amulet, bow, belt,
-- coefficients are: 2, 1, 1.25, 1.5, 1.25, 1.25, 0.75 * 6, 1, 1.25, 1
local TOTAL_SLOTS = 13.75	--16 - 2.25 for ring resistance enchants
local ENCHANTS_PER_ITEM = 3	--2 normal + 1 special

function getTotalEnchantPower(level)
	return ENCHANTS_PER_ITEM*TOTAL_SLOTS*GetMaxEnchantStrength(level)
end

local function gearedAnchor(level)
	return (level+20)/(level + 100)
end

local GEARED_ANCHOR_DIFFICULTY = 9	--beyond madness

--both are AT THE ANCHOR: lower densities are scaled down below
local DROPS_PER_SLOT_RATE = 3.6		--a candidate every ~3.6 levels early on
local DROPS_PER_SLOT_CAP = 140		--saturating at ~140 seen per slot

--The density gearedAnchor was fitted against: madness as it spawned then.
--It is a CONSTANT on purpose. Read the live madness density on both sides of
--the ratio below and madness cancels out to exactly gearedAnchor, so thinning
--the spawns could never reach the model -- the whole loss would silently land
--on the other difficulties instead.
local GEARED_ANCHOR_DENSITY = 1

--Almost all loot comes off monsters, so drops seen scale with monster density:
--these are the mean spawn per point from AdjustMonsterDensity (zzMaw-Monsters),
--as a share of the anchor. Retune the spawn counts -> move the matching row.
local DROPS_DENSITY_BY_DIFFICULTY = {
	[1] = 0.40,	--bolster 40
	[2] = 0.40,	--bolster 70
	[3] = 0.40,	--bolster 100, baseline
	[4] = 0.43,	--bolster 150
	[5] = 0.43,	--bolster 200
	[6] = 0.47,	--bolster 300
	[7] = 0.59,	--doom
	[8] = 0.66,	--road to insanity
	[9] = 0.70,	--beyond madness
}

local function dropsSeenPerSlot(level, density)
	return (level/(DROPS_PER_SLOT_RATE + level/DROPS_PER_SLOT_CAP) + 1)*density
end

local gearedCache, gearedCacheDifficulty = {}, nil

function gearedFraction(level)
	local difficulty = GetDifficulty()
	if difficulty ~= gearedCacheDifficulty then
		gearedCache, gearedCacheDifficulty = {}, difficulty
	end
	local cached = gearedCache[level]
	if not cached then
		local tier = GetLootTier(level)
		local density = DROPS_DENSITY_BY_DIFFICULTY[difficulty] or 1
		cached = gearedAnchor(level)
			*GetExpectedEnchantFraction(tier, dropsSeenPerSlot(level, density), difficulty)
			/GetExpectedEnchantFraction(tier,
				dropsSeenPerSlot(level, GEARED_ANCHOR_DENSITY), GEARED_ANCHOR_DIFFICULTY)
		gearedCache[level] = cached
	end
	return cached
end

function estimateStat(level)
	local baseStat = 17 --on creation
	local statsFromAlchemy = math.min(level, 500)*0.2
	--most of the stats come from enchants
	local geared = gearedFraction(level)
	local skill = estimateSkill(level)
	local dayOfTheGods = 1 + GetBuffStatPct(skill, true)*buffRamp(skill)

	return (baseStat + statsFromAlchemy + getTotalEnchantPower(level)*STAT_SHARE*geared)*dayOfTheGods
end


local BASE_HP = 25
local HP_PER_LEVEL_MIN = 3
local HP_PER_LEVEL_MAX = 9
local BODYBUILDING_MASTERY = 3	--the average character stops at Master, never GM
local BB_FLAT_PER_RANK = {1, 2, 3}	--the skill*mastery multiplier, one row per rank

--HP per level grows into its cap over the promotion range
local function hpPerLevel(lvl)
	local promotionLevel = vars.madnessMode and 330 or 210	--exp-equivalent of 500/250 on the slowed curve
	local growth = HP_PER_LEVEL_MAX - HP_PER_LEVEL_MIN
	return math.min(growth*lvl/promotionLevel, growth) + HP_PER_LEVEL_MIN
end

local function computeHealth(lvl)
	local perLevel = hpPerLevel(lvl)
	local stat = estimateStat(lvl)
	local skill = estimateSkill(lvl)
	local mastery = masteryPerLevel(lvl)

	--flat HP enchants: they roll on their own curve, not the per-level one
	local healthPower = stat/10
	local flatBonus = healthPower*math.min(1 + healthPower/50, 5)*4

	--endurance and bodybuilding both buy extra HP on every level
	local enduranceEffect = stat/5

	local bbMastery = math.min(mastery, BODYBUILDING_MASTERY)
	local bodybuildingFlat = skill*gradualRow(BB_FLAT_PER_RANK, skill, bbMastery)
	local bodybuildingPct = GetGradualMasteryValue(bodybuildingHP, skill, bbMastery)

	local health = BASE_HP + perLevel*lvl + (enduranceEffect + bodybuildingFlat)*perLevel + flatBonus
	return health*(1 + bodybuildingPct*skill/100)*(1 + stat/STAT_DAMAGE_DIVISOR)
end

local healthCache = {}
local cachedMadness, cachedInsanity, cachedAusterity, cachedBolster

local function estimateHealth(lvl)
	if vars.madnessMode ~= cachedMadness or vars.insanityMode ~= cachedInsanity
			or vars.AusterityMode ~= cachedAusterity
			or Game.BolsterAmount ~= cachedBolster then
		healthCache = {}
		cachedMadness, cachedInsanity = vars.madnessMode, vars.insanityMode
		cachedAusterity, cachedBolster = vars.AusterityMode, Game.BolsterAmount
	end
	local health = healthCache[lvl]
	if not health then
		health = computeHealth(lvl)
		--NaN check
		if lvl == lvl then
			healthCache[lvl] = health
		end
	end
	return health
end

local BASE_SP = 15
local SP_PER_LEVEL_MIN = 3
local SP_PER_LEVEL_MAX = 9
local MEDITATION_GM_MASTERY = 5
local MED_PER_RANK = {1, 2, 3, MEDITATION_GM_MASTERY}	--the skill*mastery multiplier, GM counts double+

local function spPerLevel(lvl)
	local promotionLevel = vars.madnessMode and 330 or 210	--exp-equivalent of 500/250 on the slowed curve
	local growth = SP_PER_LEVEL_MAX - SP_PER_LEVEL_MIN
	return math.min(growth*lvl/promotionLevel, growth) + SP_PER_LEVEL_MIN
end

local function computeMana(lvl)
	local perLevel = spPerLevel(lvl)
	local stat = estimateStat(lvl)
	local skill = estimateSkill(lvl)
	local mastery = masteryPerLevel(lvl)

	local statEffect = Game.GetStatisticEffect(stat)

	local pool = BASE_SP + perLevel*(lvl + 2*statEffect + skill*gradualRow(MED_PER_RANK, skill, mastery))
	local enlightenment = gradualRow(MawCore.Formulas.enlightenmentManaPerSkill, skill, mastery)/100*skill
	return pool*(1 + enlightenment)
end

local manaCache = {}
local manaMadness, manaInsanity, manaAusterity, manaBolster

local function estimateMana(lvl)
	if vars.madnessMode ~= manaMadness or vars.insanityMode ~= manaInsanity
			or vars.AusterityMode ~= manaAusterity
			or Game.BolsterAmount ~= manaBolster then
		manaCache = {}
		manaMadness, manaInsanity = vars.madnessMode, vars.insanityMode
		manaAusterity, manaBolster = vars.AusterityMode, Game.BolsterAmount
	end
	local mana = manaCache[lvl]
	if not mana then
		mana = computeMana(lvl)
		--NaN check
		if lvl == lvl then
			manaCache[lvl] = mana
		end
	end
	return mana
end

function getPlayerEstimatedMana(lvl)
	return estimateMana(lvl)
end

local EXPECTED_NEARBY_MONSTERS = 5
local ARMOR_REFERENCE_AC = 116

local function estimateWornArmor(lvl)
	local charges = GetPrimordialCharges(lvl)
	local worn = ARMOR_REFERENCE_AC + MawCore.Formulas.chargesArmorAC(ARMOR_REFERENCE_AC, charges)
	return worn*gearedFraction(lvl)
end

local LEGENDARY_28_ARMOR = 0.5

local function estimateArmorClass(lvl)
	local skill = estimateSkill(lvl)
	local mastery = masteryPerLevel(lvl)
	local armorMult = gradualRow(skillItemAC[const.Skills.Chain], skill, mastery)*skill/100
	local legendary = 1 + LEGENDARY_28_ARMOR*legendaryRamp(lvl)
	local stoneskin = buffFlat(const.Spells.StoneSkin, skill, mastery, lvl,
		STONESKIN_LEVEL_DIVISOR)
	return estimateWornArmor(lvl)*(legendary + armorMult) + stoneskin
end

local function estimateResistance(lvl)
	local skill = estimateSkill(lvl)
	local mastery = masteryPerLevel(lvl)
	local resMult = gradualRow(skillItemRes[const.Skills.Chain], skill, mastery)*skill/100
	--the six element buffs all carry the same numbers; one stands for all
	return estimateWornArmor(lvl)*resMult
		+ buffFlat(const.Spells.FireResistance, skill, mastery, lvl)
		+ Game.GetStatisticEffect(estimateStat(lvl))	--luck, the same addLuckRes gives
end

local LEGENDARY_16_RESISTANCE = 0.5

local function estimateEnchantResistance(level)
	local power = MawCore.Formulas.resistanceEnchantPower(GetMaxEnchantStrength(level), true)
	return power*(1 + LEGENDARY_16_RESISTANCE*legendaryRamp(level))
end

local function estimateChanceToGetHit(lvl)
	return MawCore.Formulas.chanceToBeHit(estimateStat(lvl), lvl)
end

local function estimatePhysicalDamageTaken(lvl)
	local F = MawCore.Formulas
	return math.max(F.armorDamageTaken(estimateArmorClass(lvl), lvl), F.damageFloor)
end

local function estimateMagicDamageTaken(lvl)
	local F = MawCore.Formulas
	local skill = estimateSkill(lvl)
	local mastery = masteryPerLevel(lvl)
	local taken = F.resistanceDamageTaken(estimateResistance(lvl), lvl)
	--Shield buff, same numbers calcMawDamage applies (buffPower, floored at 0.7)
	taken = taken*math.max(1 - buffMult(const.Spells.Shield, skill, mastery), 0.7)
	taken = taken*F.enchantResistanceDamageTaken(estimateEnchantResistance(lvl))
	return math.max(taken, F.damageFloor)
end

local LEGENDARY_18_REDUCTION = 0.10	--flat cut to everything
local LEGENDARY_22_PER_MONSTER = 0.03	--per monster within 512

local function estimateLegendaryDamageTaken(lvl)
	local ramp = legendaryRamp(lvl)
	local crowd = (1-LEGENDARY_22_PER_MONSTER)^EXPECTED_NEARBY_MONSTERS
	return (1 - LEGENDARY_18_REDUCTION*ramp)*(1 - (1-crowd)*ramp)
end

local COVER_BASE = 0.10
local COVER_PER_SKILL = 0.01
local COVER_GATE = {0, 1}	--worthless at novice, phases in across the expert band

local TANK_RATIO_CAP = 7		--approached, never passed
local TANK_RATIO_MIDPOINT = 240	--level at which it is halfway there
local function tankVitalityRatio(lvl)
	return 1 + (TANK_RATIO_CAP-1)*lvl/(lvl + TANK_RATIO_MIDPOINT)
end

local function coverMultiplier(lvl)
	local skill = estimateSkill(lvl)
	local gate = gradualRow(COVER_GATE, skill, masteryPerLevel(lvl))
	if gate <= 0 then
		return 1
	end
	local p = math.min(COVER_BASE + COVER_PER_SKILL*skill,
		COVER_BASE + COVER_PER_SKILL*skillCap[50])*gate
	local ratio = tankVitalityRatio(lvl)
	if Party.Count <= 1 then
		ratio = 1/MawCore.Formulas.soloCoverDamageTaken
	end
	return 1/((1 - p) + p/ratio)
end

--average
function getPlayerEstimatedVitality(lvl)
	local health = estimateHealth(lvl)
	local share = MawCore.Formulas.physicalVitalityShare

	--the swing has to land before anything gets to cut it, and Speed now
	--dodges the elemental half too
	local physical = estimatePhysicalDamageTaken(lvl)
	local magic = estimateMagicDamageTaken(lvl)
	local taken = (physical*share + magic*(1-share))
		*estimateChanceToGetHit(lvl)*estimateLegendaryDamageTaken(lvl)

	return health/taken*coverMultiplier(lvl), physical, magic, taken, health
end

function getPlayerEstimatedHealth(lvl)
	return estimateHealth(lvl)
end

function getMonsterDamage(mon, level)
	local hitToKill={14,10,7,6.5,6,5.5,5,4.5,4}
	local hitToKillAusterity={15,10,5,4,3,2.5,2,1.5,1}
	
	if mon then
		level=totalLevel[MawTierB(mon.Id)] or level
	end
	local vitality=getPlayerEstimatedVitality(level)

	local difficulty=GetDifficulty()
	local hits=hitToKill[difficulty]
	if vars.AusterityMode then
		hits=hitToKillAusterity[difficulty]
	end

	local damage=vitality/hits
	
	if not mon then
		return damage
	end
	
	if mon.Id%3==1 then
		damage=damage*0.66
	elseif mon.Id%3==0 then
		damage=damage*1.5
	end
	local index=mon:GetIndex()
	if mon.NameId>=220 and mon.NameId<=300 then
		mapvars.bossData=mapvars.bossData or {}
		if not mapvars.bossData[index] then
			generateBoss(index)
		end
		damage=damage*mapvars.bossData[index].DamageMult
	end
	
	return damage
end

--what the average character is assumed to be carrying and hitting with.
--The enchant coefficient is read LIVE off the same table the game deals from
--(enchant 46 times the global dial), so tuning ENCHANT_DAMAGE_MULT moves the
--model by itself.
local function expectedEnchantCoeff()
	return enchantbonusdamage[46].Coeff*ENCHANT_DAMAGE_MULT
end
local EXPECTED_ENCHANT_LEVEL = 100	--level by which the weapon carries that enchant
local EXPECTED_WEAPON_DICE = 3		--only feeds the +diceCount/2 floor of a roll

local LEGENDARY_21_PER_MONSTER = 0.05	--melee damage per monster within 512
--11 halves the recovery after a kill, so it is worth more the fewer swings a
--kill takes -- which depends on the weapon's base recovery, the monster's HP
--and the difficulty. Pricing that properly costs more time than it is worth:
--15% is a gut number.
local LEGENDARY_11_DAMAGE = 0.15
local LEGENDARY_33_SKILL = 10		--added to every melee weapon skill

--Legendary 29 (every hit shaves a point off the monster's resistance) is NOT
--modelled anywhere. It used to sit inside a blanket residual that has since
--been removed. It belongs on the monster side -- getMonsterHealth already
--divides by 2^(resistance/100) -- not in the player's damage.
--Also unmodelled by choice: 12 enables hybrid builds instead of adding power,


SKILL_ENCHANT_MULT = 1.5

function getMeleeSkill(lvl)
	return estimateSkill(lvl)*SKILL_ENCHANT_MULT + LEGENDARY_33_SKILL*legendaryRamp(lvl)
end


--Attack rating of the average character: the weapon's flat half plus the
--weapon-skill and armsmaster attack rows and the accuracy breakpoint bonus --
--the same pieces itemStats sums into tab[40].
function getPlayerEstimatedAttack(lvl)
	local skill = estimateSkill(lvl)
	local m = masteryPerLevel(lvl)
	local meleeSkill = getMeleeSkill(lvl)
	local wDmg, wDice, wFlat = getWeaponDamageForLevel(lvl, true, estimateWeaponFlat(lvl))
	--half the enchant split becomes attack; the weapon's own flat part all does
	return (wDmg-wDice-wFlat)/2 + wFlat
		+ GetGradualMasteryValue(skillAttack[const.Skills.Sword], meleeSkill, masteryForSkill(meleeSkill))*meleeSkill
		+ GetGradualMasteryValue(armsmasterSkill.Attack, skill, m)*skill
		+ Game.GetStatisticEffect(estimateStat(lvl))
		+ buffFlat(const.Spells.Bless, skill, m, lvl)
end

function getPlayerEstimatedPower(lvl)
	local F = MawCore.Formulas
	local skill = estimateSkill(lvl)
	local m = masteryPerLevel(lvl)	--the mastery that skill level buys

	local itemLevel = lvl
	local wDmg, wDice, wFlat = getWeaponDamageForLevel(itemLevel, true, estimateWeaponFlat(lvl))	--two-handed reference

	local meleeSkill = getMeleeSkill(lvl)	--the weapon skill, legendary 33 included
	local weaponSkillMult = 1 + skillDamage[const.Skills.Sword]*meleeSkill/100
	local armsSkill = skill*SKILL_ENCHANT_MULT
	--inflated skills pair with their own mastery, or the ramp steps at flips
	local mMelee, mArms = masteryForSkill(meleeSkill), masteryForSkill(armsSkill)
	local armsBase = GetGradualMasteryValue(armsmasterSkill.Damage, armsSkill, mArms)*armsSkill
	local scalable = 0.75*(wDmg-wDice-wFlat) + wFlat + 0.5*wDice + armsBase
	local damage = EXPECTED_WEAPON_DICE/2 + scalable*weaponSkillMult

	--the floor: a weapon skill point is worth at least 1 damage
	damage = damage + math.max(meleeSkill - scalable*(weaponSkillMult-1), 0)

	--MIGHT: flat breakpoint bonus, then the level-normalized percentage
	local might = estimateStat(lvl)
	local mightEffect = Game.GetStatisticEffect(might)
	local heroismBuff = 1 + buffMult(const.Spells.Heroism, skill, m)
	damage = (damage + mightEffect)*heroismBuff*(1 + GetMightDamageMultiplier(might, lvl))

	--real speed-stat recovery bonus (GetSpeedBonus), in percentage points
	local speedEffect = GetSpeedBonusFromStat(estimateStat(lvl), lvl)/100
	local weaponSpeed = GetGradualMasteryValue(skillRecovery[const.Skills.Sword], meleeSkill, mMelee)*meleeSkill/100
	local armsMasterSpeed = GetGradualMasteryValue(armsmasterSkill.Speed, armsSkill, mArms)*armsSkill/100
	local hasteBuff = 1 + buffMult(const.Spells.Haste, skill, m)
	damage = damage*(1 + speedEffect + weaponSpeed + armsMasterSpeed)*hasteBuff

	local legendary = legendaryRamp(lvl)

	local luck, accuracy = might, might
	local critChance = F.critChance(luck, lvl) + 0.1*legendary
		+ buffMult(const.Spells.Fate, skill, m)
	local critDamage = F.critDamageMult(accuracy, lvl, vars.madnessMode) - 1
	local critMult = 1 + math.min(critChance, 1)*critDamage
	damage = damage*critMult

	local enchantLegendary = (1 + (LEGENDARY19_ENCHANT_MULT - 1)*legendary)
		*(1 + (critMult-1)*legendary)
	--the same call the game makes in GetWeaponLevelDamage
	local enchantBase = getWeaponLevelDamage(itemLevel, true, estimateWeaponFlat(lvl))*enchantLegendary
	damage = damage + enchantBase*expectedEnchantCoeff()*math.min(lvl/EXPECTED_ENCHANT_LEVEL, 1)
	damage = damage + enchantBase*GetGradualMasteryValue(fireAuraDamage, skill, m)

	local crowd = math.min(1 + LEGENDARY_21_PER_MONSTER*EXPECTED_NEARBY_MONSTERS*legendary, 2)
	damage = damage*crowd*(1 + LEGENDARY_11_DAMAGE*legendary)

	damage = damage*math.max(critChance, 1)
	local hitChance = math.min(F.hitAtPar + F.blessHitBonusForSkill(skill), F.hitMax)
	return damage*hitChance
end

local SPELL_REF_NOVICE = {add = 8, dice = 2, delay = 110}	--fire bolt
local SPELL_REF_GM = {add = 19, dice = 21, delay = 90}	--incinerate

local function estimateSpellReference(lvl)
	local th = masteryThresholds()
	local t = math.min(estimateSkill(lvl)/th[4], 1)
	local a, b = SPELL_REF_NOVICE, SPELL_REF_GM
	return a.add + (b.add - a.add)*t,
		a.dice + (b.dice - a.dice)*t,
		a.delay + (b.delay - a.delay)*t
end

function estimateSpellDelay(lvl, baseDelay)
	local skill = estimateSkill(lvl)
	local m = masteryPerLevel(lvl)
	local haste = math.floor(estimateStat(lvl)/SPELL_HASTE_DIVISOR)
	local hasteBuff = 1 + buffMult(const.Spells.Haste, skill, m)
	return baseDelay/(1 + haste/100)*1.015^skill/hasteBuff
end

function getPlayerEstimatedSpellPower(lvl)
	local F = MawCore.Formulas
	local skill = estimateSkill(lvl)
	local m = masteryPerLevel(lvl)
	local stat = estimateStat(lvl)

	local add, dice, baseDelay = estimateSpellReference(lvl)
	local empower = 1 + buffMult(const.Spells.Haste, skill, m)
	dice = dice*empower*F.spellDiceScale(skill)
	add = add*empower*F.spellAddScale(skill)

	local power = add + skill*SKILL_ENCHANT_MULT*(1 + dice)/2

	power = power*(1 + getIntellectDamageMultiplier(stat, lvl))

	local legendary = legendaryRamp(lvl)
	local critChance = F.critChance(stat, lvl) + 0.1*legendary
		+ buffMult(const.Spells.Fate, skill, m)
	local critDamage = F.critDamageMult(stat, lvl, vars.madnessMode, true)
	power = power*(1 + math.min(critChance, 1)*(critDamage - 1))

	local spellCritFactor = 1 + math.min(critChance, 1)*(critDamage - 1)
	--legendary 19 is a flat enchant bonus now, here as on the melee side
	local enchantLegendary = (1 + (LEGENDARY19_ENCHANT_MULT - 1)*legendary)
		*(1 + (spellCritFactor - 1)*legendary)
	local enchantBase = getWeaponLevelDamage(lvl, true, estimateWeaponFlat(lvl))*enchantLegendary
	local enchant = enchantBase*(expectedEnchantCoeff()*math.min(lvl/EXPECTED_ENCHANT_LEVEL, 1)
		+ GetGradualMasteryValue(fireAuraDamage, skill, m))*1.015^skill

	local delay = estimateSpellDelay(lvl, baseDelay)
	return (power + enchant)/(delay/100)*math.max(critChance, 1)
end

local function estimateHealingFor(spellId, lvl, skill, m)
	local sp = getBaseHealingSpells()[spellId]
	local scaling, base = ascendHealingValues(skill,
		gradualRow(sp.Base, skill, m), gradualRow(sp.Scaling, skill, m))
	local heal = (base + scaling*skill)*(1 + getHealPersonalityBonus(estimateStat(lvl), lvl))
	local delay = estimateSpellDelay(lvl, gradualRow(oldTable[spellId], skill, m))
	return heal/(delay/100)
end

function getPlayerEstimatedHealing(lvl)
	local skill = estimateSkill(lvl)
	local m = masteryPerLevel(lvl)
	return math.max(estimateHealingFor(const.Spells.Heal, lvl, skill, m),
		estimateHealingFor(const.Spells.CureDisease, lvl, skill, m))
end

--[[ healing balance readout: HPS as a share of max health (madness runs to 500)
for i=1,50 do
	local l=i*10
	print(l, round(getPlayerEstimatedHealing(l)/getPlayerEstimatedHealth(l)*1000)/10 .. "%")
end
]]

function getMonsterHealth(mon, level)
	local hitToKillMonster={1,1.5,2,2.5,3,3.5,4,4.5,5}
	local hitToKillMonsterAusterity={1,2,4,5,6,7,8,9,9.5}
	if mon then
		level=totalLevel[MawTierB(mon.Id)] or level
	end
	local health=getPlayerEstimatedPower(level)

	local difficulty=GetDifficulty()

	local hits=hitToKillMonster[difficulty] --baseline MAW

	if vars.AusterityMode then
		hits=hitToKillMonsterAusterity[difficulty]
	end
	health=health*hits
		
	if not mon then
		return health
	end	
	
	
	local id=mon.Id
	local rateo=1
	if id%3==1 then
		rateo=basetable[id].FullHP/basetable[id+1].FullHP
	elseif id%3==0 then
		rateo=basetable[id].FullHP/basetable[id-1].FullHP
	end
	rateo=math.max(0.6,math.min(rateo,1.8))
	health=health*rateo
	
	-- Check if monster has GetIndex method (real monster vs mock object)
	if not mon.GetIndex then
		return health
	end
	
	local index=mon:GetIndex()
	if mon.NameId>=220 and mon.NameId<=300 then
		mapvars.bossData=mapvars.bossData or {}
		if not mapvars.bossData[index] then
			generateBoss(index)
		end
		health=health*mapvars.bossData[index].HealthMult
	end
	
	return health
end

--[[ test code, don't touch
for i=1,1000 do
	HPtable=i*(i/10+3)*2*(1+i/360)
	if Game.BolsterAmount==600 then
		hpMult=(2+i/300)
	end	
	if vars.insanityMode then
		hpMult=hpMult*(1.5+i/300)
	end		
	
	hpMult=hpMult/math.min(math.max(0.3+totalLevel[i]/200,1),50/15) --50/15 is the amount needed to get 1% crit, now and before

	HPtable=HPtable*hpMult
	
	res=i/2
	HPtable=HPtable*2^(res/(100))
	
	print(round(HPtable/GetPlayerEstimatedPower(i)*100)/100)
end
]]

--[[
for i=1,1000 do
	print(round(getMonsterDamage(i)/getPlayerEstimatedVitality(i)*100)/100)
end
]]
