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

local BUFF_MULT_PER_SKILL = 0.02
local function buffMult(spellId, s, m)
	local bf = buffPower[spellId]
	if not bf then
		return 0
	end
	local th = masteryThresholds()
	local ramp = math.min(math.max((s-th[2])/(th[3]-th[2]), 0), 1)
	return bf.Base[m]/100 * ramp * math.min(1 + BUFF_MULT_PER_SKILL*s, 2)
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

WEAPON_BASE_DICE_DAMAGE = 8

function getWeaponDamageForLevel(itemLevel, twoHanded)
	local damage = math.max(Game.GetStatisticEffect(estimateStat(itemLevel)), 0)
	local diceOnly = WEAPON_BASE_DICE_DAMAGE
	if not twoHanded then
		damage = damage/2
		diceOnly = diceOnly/2
	end
	local damping = 1 + estimateWeaponDamageMultiplier(itemLevel)
	return (damage + diceOnly)/damping, diceOnly/damping
end

function estimateStat(level)
	local baseStat = 21
	local statsPerLevel=2
	if vars.insanityMode then
		statsPerLevel=5
	elseif vars.Mode==2 then
		statsPerLevel=4
	elseif Game.BolsterAmount==300 then
		statsPerLevel=3
	elseif Game.BolsterAmount==200 then
		statsPerLevel=2.5
	elseif Game.BolsterAmount==150 then
		statsPerLevel=2
	end
	if vars.AusterityMode then
		statsPerLevel=statsPerLevel+Game.BolsterAmount/100
	end
	return statsPerLevel*level + baseStat
end

--average
function getPlayerEstimatedVitality(lvl, healthOnly)
	local baseHP=25
	local baseScaling=3
	local endScaling=9
	local maxPromotionLevel=250
	if vars.madnessMode then
		maxPromotionLevel=500
	end
	local scalingHP=math.min((endScaling-baseScaling)*lvl/maxPromotionLevel,endScaling-baseScaling)+baseScaling
	local health=baseHP+scalingHP*(lvl)
	
	local estimatedStat=estimateStat(lvl)

	
	local levelCap=700
	if vars.madnessMode then
		levelCap=1050
	end
	local levelMult=math.min(lvl/levelCap,1)
	
	local extimatedEndurance=estimatedStat
	
	local healthPower=estimatedStat/10
	local extimatedHealthBonus=healthPower*math.min(1+healthPower/50,5)*4	
	
	local enduranceEffect=extimatedEndurance/5
	local skill=estimateSkill(lvl)
	local mastery=masteryPerLevel(lvl)
	local bbMasteryBonus=math.min(1+skill/masterLearned()*2,3) --use master as a reference
	local bbPercentBonus=GetGradualMasteryValue(bodybuildingHP, skill, mastery)
	health=health+(enduranceEffect+bbMasteryBonus)*scalingHP+extimatedHealthBonus
	
	health=health*(1+bbPercentBonus*skill/100)*(1+extimatedEndurance/2500)
	
	-- Return just health if requested
	if healthOnly then
		return health
	end
	
	local armorClass=estimatedStat*1.5
	
	local bolster=1
	if vars.insanityMode then
		bolster=3
	end
	
	local bolster=(math.max(Game.BolsterAmount, 100)/100-1)/4+1
	if vars.insanityMode then
		bolster=3
	end
	
	local divider=math.min(90+lvl*0.25*bolster)
	local armorReduction=armorClass/divider+1
	local nerfAmount=math.max(1,lvl/255)
	local blockAC=armorClass/(math.max(Game.BolsterAmount/100,1)/nerfAmount)
	local blockChanceVitMultiplier= 1/((5+lvl*2)/(10+lvl*2+blockAC))
	local totalArmorReduction=armorReduction*blockChanceVitMultiplier
	local resistances=armorClass*2/3
	
	local divider=math.min(60+lvl*0.5*bolster)
	local resReduction=resistances/divider+1
	--Shield buff, same numbers calcMawDamage applies (buffPower, floored at 0.7)
	local shieldBuff=math.max(1-buffMult(const.Spells.Shield, skill, mastery), 0.7)
	resReduction=resReduction/shieldBuff
	local power=estimatedStat/12 
	
	local ringReduction=(power/100+1)
	resReduction=resReduction*ringReduction
	
	local averageReduction=(totalArmorReduction+resReduction)/2

	local extimatedLegendaryPower=1+0.001*lvl
	
	local vitality=health*averageReduction*extimatedLegendaryPower
	
	return vitality, totalArmorReduction, resReduction, averageReduction , health
	
end
function getPlayerExtimatedHealth(lvl)
	local health=getPlayerEstimatedVitality(lvl,true)
	return health
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
local EXPECTED_ENCHANT_COEFF = 0.3	--one tier-2 damage enchant (enchantbonusdamage)
local EXPECTED_WEAPON_DICE = 3		--only feeds the +diceCount/2 floor of a roll


--Attack rating of the average character: the weapon's flat half plus the
--weapon-skill and armsmaster attack rows and the accuracy breakpoint bonus --
--the same pieces itemStats sums into tab[40].
function getPlayerEstimatedAttack(lvl)
	local skill = estimateSkill(lvl)
	local m = masteryPerLevel(lvl)
	local wDmg, wDice = getWeaponDamageForLevel(lvl, true)
	return (wDmg-wDice)/2
		+ GetGradualMasteryValue(skillAttack[const.Skills.Sword], skill, m)*skill
		+ GetGradualMasteryValue(armsmasterSkill.Attack, skill, m)*skill
		+ Game.GetStatisticEffect(estimateStat(lvl))
end

function getPlayerEstimatedPower(lvl)
	local F = MawCore.Formulas
	local skill = estimateSkill(lvl)
	local m = masteryPerLevel(lvl)	--the mastery that skill level buys

	local itemLevel = lvl
	local wDmg, wDice = getWeaponDamageForLevel(itemLevel, true)	--two-handed reference

	local weaponSkillMult = 1 + skillDamage[const.Skills.Sword]*skill/100
	local armsBase = GetGradualMasteryValue(armsmasterSkill.Damage, skill, m)*skill
	--flat half counts in full, the dice half averages to half of it
	local scalable = 0.75*(wDmg-wDice) + 0.5*wDice + armsBase
	local damage = EXPECTED_WEAPON_DICE/2 + scalable*weaponSkillMult

	--the floor: a weapon skill point is worth at least 1 damage
	damage = damage + math.max(skill - scalable*(weaponSkillMult-1), 0)

	--MIGHT: flat breakpoint bonus, then the level-normalized percentage
	local might = estimateStat(lvl)
	local mightEffect = Game.GetStatisticEffect(might)
	local heroismBuff = 1 + buffMult(const.Spells.Heroism, skill, m)
	damage = (damage + mightEffect)*heroismBuff*(1 + GetMightDamageMultiplier(might, lvl))

	--real speed-stat recovery bonus (GetSpeedBonus), in percentage points
	local speedEffect = GetSpeedBonusFromStat(estimateStat(lvl), lvl)/100
	local weaponSpeed = GetGradualMasteryValue(skillRecovery[const.Skills.Sword], skill, m)*skill/100
	local armsMasterSpeed = GetGradualMasteryValue(armsmasterSkill.Speed, skill, m)*skill/100
	local hasteBuff = 1 + buffMult(const.Spells.Haste, skill, m)
	damage = damage*(1 + speedEffect + weaponSpeed + armsMasterSpeed)*hasteBuff

	local luck, accuracy = might, might
	local critChance = F.critChance(luck, lvl) + 0.1*math.min(lvl/300, 1) --assume crit enchant at lvl 500
	local extraMult = 1
	if critChance > 1 then
		extraMult = critChance
	end
	local critDamage = F.critDamageMult(accuracy, lvl, vars.madnessMode) - 1
	damage = damage*(1 + math.min(critChance, 1)*critDamage*extraMult)

	damage = damage + wDmg*estimateWeaponDamageMultiplier(itemLevel)*EXPECTED_ENCHANT_COEFF

	--the average character has the attack mawHitChance measures against, so
	--its hit chance is par by definition
	local extimatedLegendaryPower = 1 + 0.002*lvl
	return damage*F.hitAtPar*extimatedLegendaryPower
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
	
	hits=hits*(1+level/1000)
	
	health=health*hits
	
	--account for resistances
	health=health/2^(math.min(level/2/100,10)) --approx
	
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
