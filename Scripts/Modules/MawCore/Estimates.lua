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

local BUFF_SKILL_CAP = 50
local BUFF_SKILL_CAP_DAY = 75	--Day of the Gods, Day of Protection, Hour of Power
local dayBuffs = {[83] = true, [85] = true, [86] = true}
local function casterSkill(spellId, s)
	return math.min(s, dayBuffs[spellId] and BUFF_SKILL_CAP_DAY or BUFF_SKILL_CAP)
end

local CASTER_LEVEL_DIVISOR = 4
local STONESKIN_LEVEL_DIVISOR = 4
local function buffFlat(spellId, s, m, level, levelDivisor)
	local bf = buffPower[spellId]
	if not bf then
		return 0
	end
	local flat = bf.Base[m] + level/(levelDivisor or CASTER_LEVEL_DIVISOR)
	return flat*(1 + bf.Scaling[m]/100*casterSkill(spellId, s))*buffRamp(s)
end

local BUFF_MULT_PER_SKILL = 0.02
local function buffMult(spellId, s, m)
	local bf = buffPower[spellId]
	if not bf then
		return 0
	end
	return bf.Base[m]/100 * buffRamp(s) * (1 + BUFF_MULT_PER_SKILL*casterSkill(spellId, s))
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
	return math.floor((math.sqrt(1 + 8*(points+1)) - 1)/2)
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

--A charge pays one channel whole instead of half of each: even charges buy flat damage
--and attack, odd charges buy the dice. Both values are two-handed and expected damage,
--like WEAPON_BASE_DICE_DAMAGE -- the dice one is doubled into the sides budget below,
--because a roll averages half of it.
WEAPON_FLAT_PER_CHARGE = 2	--flat damage and attack, on even charges
WEAPON_DICE_PER_CHARGE = 2	--damage over the dice sides, on odd charges

function getWeaponDamageForLevel(itemLevel, twoHanded, flat)
	local IL = MawCore.ItemLevel
	--above the charge cap no real item can keep scaling, so neither does the model
	local charges = math.min(IL.ChargesFor(itemLevel), IL.MaxCharges())
	local flatCharges = math.floor(charges/2)

	local chargeFlat = WEAPON_FLAT_PER_CHARGE*flatCharges
	local chargeDice = WEAPON_DICE_PER_CHARGE*2*(charges - flatCharges)
	local diceOnly = WEAPON_BASE_DICE_DAMAGE*2 + chargeDice
	local flatOnly = (flat or 0) + chargeFlat
	--the average damage the charges added: what enchants and auras scale off
	local charged = chargeFlat + chargeDice/2
	if not twoHanded then
		diceOnly = diceOnly/2
		flatOnly = flatOnly/2
		charged = charged/2
	end
	--nothing is left to split half and half: each channel is already whole
	return diceOnly + flatOnly, diceOnly, flatOnly, charged
end

function getWeaponLevelDamage(itemLevel, twoHanded, weaponFlat)
	local _, _, _, charged = getWeaponDamageForLevel(itemLevel, twoHanded, weaponFlat)
	return charged*estimateWeaponDamageMultiplier(itemLevel)
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

function gearedFraction(level)
	return 0.1^(1/(1 + level/10))
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
	local bodybuildingFlat = skill*bbMastery
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
	local medMastery = mastery >= 4 and MEDITATION_GM_MASTERY or mastery

	local pool = BASE_SP + perLevel*(lvl + 2*statEffect + skill*medMastery)
	return pool*(1 + MawCore.Formulas.enlightenmentManaBonus(skill, mastery))
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
	local armorMult = skillItemAC[const.Skills.Chain][mastery]*skill/100
	local legendary = 1 + LEGENDARY_28_ARMOR*legendaryRamp(lvl)
	local stoneskin = buffFlat(const.Spells.StoneSkin, skill, mastery, lvl,
		STONESKIN_LEVEL_DIVISOR)
	return estimateWornArmor(lvl)*(legendary + armorMult) + stoneskin
end

local function estimateResistance(lvl)
	local skill = estimateSkill(lvl)
	local mastery = masteryPerLevel(lvl)
	local resMult = skillItemRes[const.Skills.Chain][mastery]*skill/100
	--the six element buffs all carry the same numbers; one stands for all
	return estimateWornArmor(lvl)*resMult
		+ buffFlat(const.Spells.FireResistance, skill, mastery, lvl)
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
local COVER_MAX = 0.40
local COVER_MASTERY = 2

local TANK_RATIO_CAP = 7		--approached, never passed
local TANK_RATIO_MIDPOINT = 240	--level at which it is halfway there
local function tankVitalityRatio(lvl)
	return 1 + (TANK_RATIO_CAP-1)*lvl/(lvl + TANK_RATIO_MIDPOINT)
end

local function coverMultiplier(lvl)
	if masteryPerLevel(lvl) < COVER_MASTERY then
		return 1
	end
	local p = math.min(COVER_BASE + COVER_PER_SKILL*estimateSkill(lvl), COVER_MAX)
	return 1/((1 - p) + p/tankVitalityRatio(lvl))
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
		local id=mon.Id
		if id%3==1 then
			id=id+1
		elseif id%3==0 then
			id=id-1
		end
		level=mon and totalLevel[id] or level
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
	
	--buff based on density
	damage=damage*GetDensityMultiplier(mon.Id)
	
	return damage
end

--what the average character is assumed to be carrying and hitting with
local EXPECTED_ENCHANT_COEFF = 0.5	--one damage enchant (enchantDamageRange ignores tier)
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

--legendary 33 adds 10 to every melee weapon skill
function getMeleeSkill(lvl)
	return estimateSkill(lvl) + LEGENDARY_33_SKILL*legendaryRamp(lvl)
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
		+ GetGradualMasteryValue(skillAttack[const.Skills.Sword], meleeSkill, m)*meleeSkill
		+ GetGradualMasteryValue(armsmasterSkill.Attack, skill, m)*skill
		+ Game.GetStatisticEffect(estimateStat(lvl))
end

function getPlayerEstimatedPower(lvl)
	local F = MawCore.Formulas
	local skill = estimateSkill(lvl)
	local m = masteryPerLevel(lvl)	--the mastery that skill level buys

	local itemLevel = lvl
	local wDmg, wDice, wFlat = getWeaponDamageForLevel(itemLevel, true, estimateWeaponFlat(lvl))	--two-handed reference

	local meleeSkill = getMeleeSkill(lvl)	--the weapon skill, legendary 33 included
	local weaponSkillMult = 1 + skillDamage[const.Skills.Sword]*meleeSkill/100
	local armsBase = GetGradualMasteryValue(armsmasterSkill.Damage, skill, m)*skill
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
	local weaponSpeed = GetGradualMasteryValue(skillRecovery[const.Skills.Sword], meleeSkill, m)*meleeSkill/100
	local armsMasterSpeed = GetGradualMasteryValue(armsmasterSkill.Speed, skill, m)*skill/100
	local hasteBuff = 1 + buffMult(const.Spells.Haste, skill, m)
	damage = damage*(1 + speedEffect + weaponSpeed + armsMasterSpeed)*hasteBuff

	local legendary = legendaryRamp(lvl)

	local luck, accuracy = might, might
	local critChance = F.critChance(luck, lvl) + 0.1*legendary	--legendary 14
	local extraMult = 1
	if critChance > 1 then
		extraMult = critChance
	end
	local critDamage = F.critDamageMult(accuracy, lvl, vars.madnessMode) - 1
	local critMult = 1 + math.min(critChance, 1)*critDamage*extraMult
	damage = damage*critMult

	local enchantLegendary = (1 + GetMightDamageMultiplier(might, lvl)*legendary)
		*(1 + (critMult-1)*legendary)
	local undamped = wDmg*estimateWeaponDamageMultiplier(itemLevel)*enchantLegendary
	damage = damage + undamped*EXPECTED_ENCHANT_COEFF*math.min(lvl/EXPECTED_ENCHANT_LEVEL, 1)
	damage = damage + undamped*GetGradualMasteryValue(fireAuraDamage, skill, m)

	local crowd = math.min(1 + LEGENDARY_21_PER_MONSTER*EXPECTED_NEARBY_MONSTERS*legendary, 2)
	damage = damage*crowd*(1 + LEGENDARY_11_DAMAGE*legendary)

	--the average character has the attack mawHitChance measures against, so
	--its hit chance is par by definition
	return damage*F.hitAtPar
end

local SPELL_REF_NOVICE = {add = 8, dice = 2, delay = 110}	--fire bolt
local SPELL_REF_GM = {add = 19, dice = 21, delay = 90}	--incinerate

CASTER_SKILL_ENCHANT_MULT = 2	--casters carry a doubled school skill via enchants

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
	local haste = math.floor(estimateStat(lvl)/10)
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
	dice = dice*empower*(1 + 0.09*skill)*1.025^skill
	add = add*empower*(1 + 0.04*skill^2)*1.025^skill

	local power = add + skill*CASTER_SKILL_ENCHANT_MULT*(1 + dice)/2

	power = power*(1 + getIntellectDamageMultiplier(stat, lvl))

	local critChance = F.critChance(stat, lvl)
	local critDamage = F.critDamageMult(stat, lvl, vars.madnessMode, true)
	power = power*(1 + math.min(critChance, 1)*(critDamage - 1))

	local legendary = legendaryRamp(lvl)
	local wDmg = getWeaponDamageForLevel(lvl, true, estimateWeaponFlat(lvl))
	local spellCritFactor = 1 + math.min(critChance, 1)*(critDamage - 1)
	local enchantLegendary = (1 + GetMightDamageMultiplier(stat, lvl)*legendary)
		*(1 + (spellCritFactor - 1)*legendary)
	local undamped = wDmg*estimateWeaponDamageMultiplier(lvl)*enchantLegendary
	local enchant = undamped*(EXPECTED_ENCHANT_COEFF*math.min(lvl/EXPECTED_ENCHANT_LEVEL, 1)
		+ GetGradualMasteryValue(fireAuraDamage, skill, m))*1.015^skill

	local delay = estimateSpellDelay(lvl, baseDelay)
	return (power + enchant)/(delay/100)*math.max(critChance, 1)
end

function getMonsterHealth(mon, level)
	local hitToKillMonster={1,1.5,2,2.5,3,3.5,4,4.5,5}
	local hitToKillMonsterAusterity={1,2,4,5,6,7,8,9,9.5}
	if mon then
		local id=mon.Id
		if id%3==1 then
			id=id+1
		elseif id%3==0 then
			id=id-1
		end
		level=mon and totalLevel[id] or level
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
	
	--buff based on density
	health=health*GetDensityMultiplier(mon.Id)
	
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
