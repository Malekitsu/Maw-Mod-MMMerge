-- SkillTooltip.lua -- per-player skill tooltip text (SKILL_TOOLTIPS.md).
--
-- The desc store holds static text only; anything dynamic is a builder
-- fn(pl, skillId, part) -> string registered per (skill, part) slot, and
-- getTooltipText(pl, skillId [, withBonus]) composes the hint at click time.
-- Return nil from a builder to fall through to the static store.
--
-- Slots: 1 = body, part n = mastery row for mastery n-1 (2 Novice, 3 Expert,
-- 4 Master, 5 Grand, 6 Supreme, ...).

local SkillTooltip = {}
MawCore.SkillTooltip = SkillTooltip

local Formulas = MawCore.Formulas

-- damageMultiplier (zzMAW-Skills) is only filled by the in-game skill
-- recalc; on the creation screen it's nil, so fall back to 1
local function meleeMult(pl)
	local t = damageMultiplier and damageMultiplier[pl:GetIndex()]
	return t and t.Melee or 1
end

-- index part -> row label; also the source for SkillsUI's mastery name
-- array (the engine's four name slots get redirected to these strings)
SkillTooltip.masteryNames = {"", "Novice", "Expert", "Master", "Grand",
	"Supreme", "Ultimate", "Ascended", "Deity"}

local builders = {}		-- [skillId][part] = {fn = fn, label = label}

function SkillTooltip.set(id, part, fn, label)
	builders[id] = builders[id] or {}
	assert(not builders[id][part],
		("skill tooltip: builder %d/%d already registered"):format(id, part))
	builders[id][part] = {fn = fn, label = label or "?"}
end

function SkillTooltip.remove(id, part)
	if builders[id] and builders[id][part] then
		builders[id][part] = nil
		return true
	end
	return false
end

-- builder first, static desc store second
function SkillTooltip.partText(pl, id, part)
	local b = builders[id] and builders[id][part]
	if b then
		local text = b.fn(pl, id, part)
		if text then
			return text
		end
	end
	return Skillz.getDesc(id, part)
end

function SkillTooltip.getTooltipText(pl, skillId, withBonus)
	if withBonus == nil then
		withBonus = true
	end
	local race = Game.CharacterPortraits[pl.Face].Race
	local clas = pl.Class
	local mNames = SkillTooltip.masteryNames
	local s = {SkillTooltip.partText(pl, skillId, 1), " \n"}
	for part = 2, 20 do
		local txt = SkillTooltip.partText(pl, skillId, part)
		local mn = mNames[part]
		if not txt or txt == "" or not mn or mn == "" then
			break
		end
		local m = part - 1
		local r, g, b = 255, 0, 0
		if MawCore.Skills.API.MasteryTable_get(race, clas, skillId) >= m then
			r, g, b = 255, 255, 255
		elseif MawCore.Skills.API.MasteryTable_get(race,
				MawCore.Skills.nextClass(clas), skillId) >= m then
			r, g, b = 255, 255, 0
		end
		s[#s + 1] = StrColor(r, g, b,
			string.format("%s:\t%03d%s\t000\n", mn, 72, txt))
	end
	if withBonus then
		local raw = Skillz.get(pl, skillId)
		local buffed = pl:GetSkill(skillId)
		local diff = bit.band(buffed, 0x3FF) - bit.band(raw, 0x3FF)
		if diff ~= 0 then
			s[#s + 1] = string.format("\n\n Bonus: %s%d", diff > 0 and "+" or "", diff)
		end
	end
	return table.concat(s)
end

function SkillTooltip.describe()
	local out = {"skill tooltip builders:"}
	local ids = {}
	for id in pairs(builders) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local parts = {}
		for part in pairs(builders[id]) do
			parts[#parts + 1] = part
		end
		table.sort(parts)
		-- one line per id when every part shares a label, else one per slot
		local label = builders[id][parts[1]].label
		for _, part in ipairs(parts) do
			if builders[id][part].label ~= label then
				label = nil
				break
			end
		end
		if label then
			out[#out + 1] = ("  %3d/%s %s"):format(id, table.concat(parts, ","), label)
		else
			for _, part in ipairs(parts) do
				out[#out + 1] = ("  %3d/%d %s"):format(id, part, builders[id][part].label)
			end
		end
	end
	if #out == 1 then
		out[#out + 1] = "  (none)"
	end
	return table.concat(out, "\n")
end

------------------------------------------------------------------------
-- Dynamic builders -- bodies verbatim from the legacy Tick/Action
-- rewriters. Base strings stay captured in the legacy files (timing) and
-- per-player vars are still read via Game.CurrentPlayer: SKILL_TOOLTIPS.md.
------------------------------------------------------------------------

-- was zzMAW-Skills.lua "DINAMIC SKILL TOOLTIP" events.Tick

SkillTooltip.set(30, 1, function(pl)
	local FHP = GetMaxHP(pl)
	local s, m = SplitSkill(pl:GetSkill(30))
	local hpRegen = round(Formulas.hpRegenPerSec(FHP, s, m) * 10) / 10
	local hpRegen2 = round(Formulas.hpRegenPerSec(FHP, s + 1, m) * 10) / 10
	local txt = string.format("%s\n\nCurrent HP Regeneration: %s\nNext Level Bonus: %s HP Regen", baseRegStr, StrColor(0, 255, 0, hpRegen), StrColor(0, 255, 0, "+" .. hpRegen2 - hpRegen))
	--dragon melee leech, shown only for dragons
	local leech = getDragonRegenLeech(pl)
	if leech > 0 then
		local leechNext = leech * (s + 1) / s
		txt = txt .. string.format("\n\nMelee Life Leech vs equal level: %s\nNext Level Bonus: %s\n(lower against higher level monsters)",
			StrColor(255, 80, 80, round(leech * 1000) / 10 .. "%"),
			StrColor(255, 80, 80, "+" .. round((leechNext - leech) * 1000) / 10 .. "%\n"))
	end
	return txt
end, "regeneration + dragon leech")

SkillTooltip.set(28, 1, function(pl)
	local FSP = pl:GetFullSP()
	if vars.MAWSETTINGS.buffRework == "ON" and vars.currentManaPool and vars.currentManaPool[i] then
		FSP = vars.currentManaPool[Game.CurrentPlayer]
	end
	local s, m = SplitSkill(pl:GetSkill(28))
	local spRegen = Formulas.spRegenPerSec(FSP, s, m)
	local spRegen2 = Formulas.spRegenPerSec(FSP, s + 1, m)
	local spRegen2 = round((spRegen2 - spRegen) * 100) / 100
	if spRegen > 10 then
		spRegen = round((spRegen) * 10) / 10
	else
		spRegen = round((spRegen) * 100) / 100
	end
	return string.format("%s\n\nIncreases spell points based on SP per level and mastery\n\nCurrent SP Regeneration: %s\nNext Level Bonus: %s SP Regen\n", baseMedStr, StrColor(60, 60, 255, spRegen), StrColor(60, 60, 255, "+" .. spRegen2))
end, "meditation SP regen")

SkillTooltip.set(const.Skills.Learning, 1, function(pl)
	local s, m = SplitSkill(pl:GetSkill(const.Skills.Learning))
	local dmgMult = shortenNumber(round(((1 + 0.075 * s) * 1.025 ^ s - 1) * 100), 3)
	local dmgBaseMult = shortenNumber(round(((1 + 0.05 * s ^ 2) * 1.025 ^ s - 1) * 100), 3)
	local healMult = shortenNumber(round(((1 + 0.05 * s) * 1.02 ^ s - 1) * 100), 3)
	local healBaseMult = shortenNumber(round(((1 + 0.03 * s ^ 2) * 1.02 ^ s - 1) * 100), 3)
	local masteryReduction = (1 - m * 0.125)
	local manaMult = shortenNumber(round(((1 + 0.125 * s) * 1.04 ^ s - 1) * masteryReduction * 100), 3)
	local castMult = shortenNumber(round((1.015 ^ s - 1) * 100), 3)
	return string.format("%s\n\nCurrent bonuses at skill %s:\n- Damage base: %s\n- Damage scaling: %s\n\n- Healing base: %s\n- Healing scaling: %s\n\n- Mana cost: %s\n- Cast time: %s\n",
		baseAscStr,
		StrColor(255, 255, 100, s),
		StrColor(0, 255, 0, "+" .. dmgBaseMult .. "%"),
		StrColor(0, 255, 0, "+" .. dmgMult .. "%"),
		StrColor(0, 255, 0, "+" .. healBaseMult .. "%"),
		StrColor(0, 255, 0, "+" .. healMult .. "%"),
		StrColor(255, 100, 100, "+" .. manaMult .. "%"),
		StrColor(255, 100, 100, "+" .. castMult .. "%"))
end, "ascension bonuses")

SkillTooltip.set(const.Skills.Spear, 5, function(pl)
	local s = SplitSkill(pl:GetSkill(const.Skills.Spear))
	local mult = meleeMult(pl)
	local damageIncrease = round((2 + s * 0.02) * mult * 10) / 10
	local it = pl:GetActiveItem(1)
	if it then
		if it:T().Skill == 4 and it:T().EquipStat == 1 then
			damageIncrease = damageIncrease * 1.5
		end
	end
	return string.format("%s\n\t070Each spear attack reduces physical resistance, increasing damage by: %s%%\nIncreased by 50%% with Halberds", baseSpearTooltip, damageIncrease)
end, "spear GM resistance shred")

-- was zzMAW-Skills.lua armor events.Action (RunNextTick on the skill screen)

local armorBase = {
	[8] = "Shield skill provides great defense against both physical and magical attacks.\n\nShield Skill boosts the AC and Resistances gained from your Shield  by a percent amount.",
	[9] = "Leather armor is the lightest armor a character can wear.  While leather provides less protection than chain or plate armor, it also slows your character down the least.\n\nLeather Armor Skill boosts the AC and Resistances gained by ALL armors when equipping a Leather Armor by a percent amount.",
	[10] = "Chain armor is the medium armor type.  It provides more protection than leather and less than plate, but it also slows your character down more than leather.\n\nChain Armor Skill boosts the AC and Resistances gained by ALL armors when equipping a Chain Armor by a percent amount.",
	[11] = "Plate armor is the heaviest armor type.  It provides the most protection, but it slows your character down more than leather or chain.\n\nPlate Armor Skill boosts the AC and Resistances gained by ALL armors when equipping a Plate Armor by a percent amount.",
}

local function armorPart1(pl, id)
	itemStats(pl:GetIndex())
	local txt = armorBase[id]
	local it = pl:GetActiveItem(3)
	if it and it:T().Skill == id then
		txt = txt .. "\n\nCurrent AC from items: " .. StrColor(255, 255, 100, armorAC) .. "\n"
		txt = txt .. "Bonus AC: " .. StrColor(255, 255, 100, itemArmorClassBonus1) .. "\n"
		txt = txt .. "Bonus Resistances: " .. StrColor(255, 255, 100, itemResistanceBonus1) .. "\n"
	end
	local it = pl:GetActiveItem(0)
	if it and id == 8 and it:T().Skill == 8 then
		txt = txt .. "\n\nBonus AC: " .. StrColor(255, 255, 100, itemArmorClassBonus2) .. "\n"
		txt = txt .. "Bonus Resistances: " .. StrColor(255, 255, 100, itemResistanceBonus2) .. "\n"
	end
	txt = txt .. "\n------------------------------------------------------------\n         \t075AC| Res\t000"
	return txt
end

for id = 8, 11 do
	SkillTooltip.set(id, 1, armorPart1, "armor AC/Res from items")
end

-- was zzMAW-Skills.lua "COVER SKILL" events.Tick (desc parts only; the
-- Game.GlobalTxt[143] category-header juggling stays in the legacy Tick)

-- per-player toggle state tail (cover / mana shield); inits the vars table
-- with everyone enabled, as the legacy Tick did
local function toggleState(name)
	if not vars[name] then
		vars[name] = {}
		for i = 0, 4 do
			vars[name][i] = true
		end
	end
	if vars[name][Game.CurrentPlayer] then
		return StrColor(0, 255, 0, "\nCurrently enabled\n")
	end
	return StrColor(255, 0, 0, "\nCurrently disabled\n")
end

SkillTooltip.set(50, 1, function(pl)
	local s = SplitSkill(Skillz.get(pl, 50))
	local chance = math.min(10 + s, 40)
	return "Cover Skill is a defensive prowess enabling a character to shield allies by intercepting incoming damage. This ability strategically positions the user as the primary target of enemy onslaughts, thereby protecting teammates who are more susceptible to damage.\n\nIf available, Expert, Master and Grandmaster is learned at skill "
		.. (vars.insanityMode and "8-20-30" or "6-12-20")
		.. ".\n\nGrants 10 plus 1% chance per skill point to Cover, up to 40%, however, something might happen once at max level....\n\nCurrent cover chance: " .. chance .. "%\n\nPress P to enable/disable\n"
		.. toggleState("covering")
end, "cover chance + toggle state")

SkillTooltip.set(51, 1, function(pl)
	local s = SplitSkill(Skillz.get(pl, 51))
	local efficiency = round(manaShieldManaEfficiency(false, s) * 100) / 100
	return "Mana shield consume mana to reduce damage when an hit would take you below a certain threshold.\n\nIf available, Expert, Master and Grandmaster is learned at skill "
		.. (vars.insanityMode and "8-20-32" or "6-12-20")
		.. ".\n\nMastery increase its mana efficience.\n" .. "Current Damage reduction per Mana: " .. StrColor(178, 255, 255, efficiency) .. "\n\nPress M to enable/disable"
		.. toggleState("manaShield")
end, "mana shield efficiency + toggle state")

SkillTooltip.set(53, 1, function(pl)
	local powerMult, DPS2, DPS3, vitMult = calcPowerVitality(pl)
	local vit = round(vitMult ^ 0.35)
	local power = round(powerMult ^ 0.35)
	local retS = SplitSkill(Skillz.get(pl, 53))
	return "After mastering the art of covering, you have become capable delivering deadly counter attacks to those who dare try harm your allies. Retaliation has a 1% per skill point chance to activate after successfully covering an ally.\n\nExpert, Master and Grandmaster are learned automatically at skill 12, 30 and 50.\n\nDamage done depends on 2 coefficients, multiplied then by skill level:\n\nMelee Power coefficient: " .. StrColor(255, 0, 0, power) .. "\nVitality coefficient: " .. StrColor(255, 0, 0, vit) .. "\n\nTotal Damage: " .. StrColor(255, 0, 0, retS * vit * power) .. "\n\nBalancing power and vitality leads to the highest damage.\n"
end, "retaliation coefficients")

-- was zzMAW-Skills.lua mace events.Action (RunNextTick on the skill screen)

SkillTooltip.set(6, 5, function(pl)
	local s, m = SplitSkill(pl:GetSkill(const.Skills.Mace))
	if m < 3 then
		return maceGMtxt
	end
	local chance = round(s / pl.LevelBase ^ 0.65 * 1500 * meleeMult(pl) / math.min(1 + pl.LevelBase / 150, 3)) / 100
	local txt = "\n\n"
	if m == 3 then
		txt = txt .. "Chance to Stun: " .. chance .. "%"
	elseif m == 4 then
		txt = txt .. "Chance to Paralyze: " .. chance .. "%"
	end
	return maceGMtxt .. StrColor(0, 0, 0, txt)
end, "mace stun/paralyze chance")

-- was zzMAW-Skills.lua armsmaster events.LoadMap (requirement varies with
-- madness/insanity mode, so per save, not per player)

SkillTooltip.set(35, 1, function(pl)
	local requirement = GetArmsmasterSupremeRequirement()
	return Skillz.getDesc(35, 1) .. "\nKnights can learn up to a Supreme level, which is learned automatically at skill level " .. requirement .. ".\n"
end, "armsmaster supreme requirement")


------------------------------------------------------------------------
-- Class school tooltips (12-20) + dragon fangs/scales (32/33), as data:
-- classSpecs[n].slots[skillId][part] = string, or function(pl) when the
-- text carries numbers. Dispatch order, the neutral fallbacks and why
-- registration waits for GameInitialized2: SKILL_TOOLTIPS.md.
------------------------------------------------------------------------

local function registerClassBuilders()
	local ST=MawCore.SkillTooltip
	local EV="Effects vary per spell"
	local ASC="\n\nEvery 7 Skill level adds 1 level into ascension.\n"

	--what the old reset branches forced, where that differs from the store:
	--EV mastery rows for 16-19, plus the part-1 school texts from
	--MawSchoolDescBase (captured by zzClasses.lua at its legacy position,
	--before the later "\n"-append init handlers -- capture timing is part
	--of the displayed text)
	local neutralText={
		[16]={[2]=EV,[3]=EV,[4]=EV},
		[17]={[2]=EV,[3]=EV,[4]=EV},
		[18]={[2]=EV,[3]=EV,[4]=EV},
		[19]={[2]=EV,[3]=EV,[4]=EV,[5]=EV},
		[20]={[1]=MawSchoolDescBase[20]},
	}
	for id=12,15 do
		neutralText[id]={[1]=MawSchoolDescBase[id]}
	end

	local classSpecs={

	--was shamanSkills(true)
	{match=function(pl) return table.find(shamanClass, pl.Class) end, slots={
		[12]={[1]=function(pl)
			local m1=SplitSkill(pl.Skills[const.Skills.Fire])
			return MawSchoolDescBase[12] .. ASC .. "Melee attacks deal an extra " .. m1/10 .. "% of monster Hit points as fire damage."
		end},
		[13]={[1]=function(pl)
			local m2=SplitSkill(pl.Skills[const.Skills.Air])
			local airReduction=Formulas.reductionPercent(m2)
			return MawSchoolDescBase[13] .. ASC .. "Reduce all damage taken by " .. airReduction .. "%\n"
		end},
		[14]={[1]=function(pl)
			local m3=SplitSkill(pl.Skills[const.Skills.Water])
			local lvl=getPartyLevel(4)
			local _,_,_,avgRed=getPlayerEstimatedVitality(lvl+1)
			local waterReduction=round(getMonsterDamage(false,(lvl+1))*(m3/lvl^0.65)/avgRed*0.99^(lvl^0.65)/2) --on average 1/2 of a B monster
			return MawSchoolDescBase[14] .. ASC .. "Reduce all damage taken by " .. waterReduction .. "(calculated after resistances)\n"
		end},
		[15]={[1]=MawSchoolDescBase[15] .. ASC .. "Increases melee damage 0.5-1-1.5-2 (at N-E-M-GM) per Earth Magic Level\n"},
		[16]={[1]=function(pl)
			local m5=SplitSkill(pl.Skills[const.Skills.Spirit])
			return MawSchoolDescBase[16] .. ASC .. "Increases melee damage by " .. m5 .. "%\n"
		end},
		[17]={[1]=function(pl)
			local m6=SplitSkill(pl.Skills[const.Skills.Mind])
			local spLeech=round(Formulas.mindLeech(m6))
			return MawSchoolDescBase[17] .. ASC .. "Melee attacks restore " .. spLeech .. " Spell Points\n"
		end},
		[18]={[1]=function(pl)
			local m7, bodyMastery=SplitSkill(pl.Skills[const.Skills.Body])
			local FHP=pl:GetFullHP()
			local leech=Formulas.bodyLeech(FHP, m7, bodyMastery)
			return MawSchoolDescBase[18] .. ASC .. "Melee attacks restore " .. leech .. " Hit Points\n"
		end},
	}},

	--was dkSkills(true) desc lines
	{match=function(pl) return table.find(dkClass, pl.Class) end, slots={
		[14]={[1]="This skill is only available to death knights and increases damage by 0.25-0.5-0.75 (at Novice, Expert, Master) and increases attack speed by 1% per skill point.\n",
			[5]=EV},
		[18]={[1]=function(pl)
			local bloodS=SplitSkill(pl.Skills[const.Skills.Body])
			local leech=round(Formulas.dkPassiveLeech(100, bloodS, pl.LevelBase)*100)/100
			return "This skill is only available to death knights and reduces physical damage taken.\n" .. "Current Reduction: " .. Formulas.reductionPercent(bloodS) .."%\n\nAdditionally it will make your attacks to leech damage based on your total HP.\n\nCurrent leech vs. same level monsters: " .. leech .. "%\n"
		end,
			[5]=EV},
		[20]={[1]=function(pl)
			local unholyS=SplitSkill(pl.Skills[const.Skills.Dark])
			return "This skill is only available to death knights and increases damage by 0.25-0.5-0.75 (at Novice, Expert, Master) and reduces magical damage taken.\n" .. "Current Reduction: " .. Formulas.reductionPercent(unholyS) .."%\n"
		end},
	}},

	--was seraphSkills(true)
	{match=function(pl) return table.find(seraphClass, pl.Class) end, slots={
		[16]={[1]=function(pl)
			local spiritS=SplitSkill(pl.Skills[const.Skills.Spirit])
			local lvl=getTotalLevel()
			local _,_,_,avgRed=getPlayerEstimatedVitality(lvl+1)
			local spiritReduction=round(getMonsterDamage(false,(lvl+1))*(spiritS/lvl^0.65)/avgRed/2*0.99^(lvl^0.65)) --on average 1/2 of a B monster
			return MawSchoolDescBase[16] .. "\n\nSeraph Spirit strengthens the Seraph's resolve, shrugging off light hits and softening heavy blows\n" .. "Damage reduction: " .. StrColor(0,255,0,spiritReduction) .. " (applied after resistances)\n"
		end},
		[17]={[1]=function(pl)
			local mindS, mindM=SplitSkill(pl.Skills[const.Skills.Mind])
			return MawSchoolDescBase[17] .. "\n\nSeraphim damage upon attack increases depending on Mind magic, scaling with might(weapon speed and weapon damage multiplier applies).\n\n" .. "Current damage from Mind: " .. StrColor(255,0,0,round(mindS*(mindM+1)/2)) .. "\n"
		end,
			[2]="Increases damage by 1 per Skill point",
			[3]="Increases damage by 1.5 per Skill point",
			[4]="Increases damage by 2 per Skill point",
			[5]="n/a"},
		[18]={[1]=function(pl)
			local bodyS, bodyM=SplitSkill(pl.Skills[const.Skills.Body])
			local healMult=1+pl:GetPersonality()/1000
			local bodyHeal=round(bodyS^1.3*bodyM*meleeMult(pl)*healMult*2)
			return MawSchoolDescBase[18] .. "\n\nSeraphim healing upon attack increases depending on Body magic, scaling with personality(weapon speed multiplier applies).\n\n" .. "Current heal from Body: " .. StrColor(0,255,0,bodyHeal) .. "\n"
		end,
			[2]="Melee attacks heal on hit",
			[3]="Double healing effect",
			[4]="Triple healing effect",
			[5]="n/a"},
		[19]={[1]=MawSchoolDescBase[19]
				.. StrColor(255,255,30,"\n\nLight Magic quickens the Seraphim's strikes, increasing attack speed.\n\nIts radiance lightens the blade so much that even a two-handed sword can be wielded in one hand, freeing the off hand for a shield.\n"),
			[2]="Increased Attack speed by 0.5% per Skill",
			[3]="Increased Attack speed by 1% per Skill",
			[4]="Increased Attack speed by 1.5% per Skill",
			[5]="Increased Attack speed by 2% per Skill"},
	}},

	--was elementalistSkills(true) desc loop
	{match=function(pl) return table.find(elementalistClass, pl.Class) end, slots=(function()
		local function progressionText(pl, id)
			vars.elementalistSpells=vars.elementalistSpells or {}
			vars.elementalistSpells[pl:GetIndex()]=vars.elementalistSpells[pl:GetIndex()] or {}
			for i=12,15 do
				vars.elementalistSpells[pl:GetIndex()][i]=vars.elementalistSpells[pl:GetIndex()][i] or 0
			end
			local list = vars.elementalistSpells[pl:GetIndex()]
			local enableDisableText = StrColor(0,255,0, "Enabled")
			if vars.disableRotation and vars.disableRotation[pl:GetIndex()] then
				enableDisableText = StrColor(255,0,0, "Disabled")
			end
			local rotationText = StrColor(0,0,0,"Elementalist offensive spells, when casted randomly, grant elementalist stacks, which increase spell damage, speed and cost.\nPress R to enable/disable random rotation.\nCurrently ") .. enableDisableText .. "\n\n"
			local progression=list[id]
			local currentTier=0
			for j=1,#spellRequirements do
				if progression>=spellRequirements[j] then
					currentTier=j
				end
			end
			if currentTier<11 then
				local low=spellRequirements[currentTier]
				local high=spellRequirements[currentTier+1]
				local percentageProgression=math.floor((progression-low)/(high-low)*10000)/100
				return EV .. " \n\n" .. rotationText .. "Elementalists learn new spells with practice instead of books.\n\nProgress toward learning " .. Game.SpellsTxt[(id-12)*11+currentTier+1].Name .. ": " .. percentageProgression .."%"
			else
				return EV .. " \n\n" .. rotationText .. "Elementalists learn new spells with practice instead of books.\n\nAll the available spells of this school have been learned."
			end
		end
		local slots={}
		for id=12,15 do
			slots[id]={[5]=progressionText}
		end
		return slots
	end)()},

	--was assassinSkills(true) desc lines
	{match=function(pl) return table.find(assassinClass, pl.Class) end, slots={
		[12]={[1]="Combat is the skill that allows you to endure prolonged fights by enhancing your energy recovery.\n\nEach attack has a base 10% chance, plus 1% per skill point, to restore 15 energy.\n\n",
			[2]="Melee attack costs 45 energy",[3]="Melee attack costs 40 energy",[4]="Melee attack costs 35 energy",[5]="Melee attack costs 30 energy"},
		[13]={[1]="Subtlety manipulates the boundary between life and death, granting you energy upon killing enemies and increasing your speed.\n\nEnergy consuming attack grants 1 stack, which increase your attack speed by 0.5% per skill point in Subtlety. Stacks up to 5 times.\n\n",
			[2]="Killing a monster restores 10 energy",[3]="Killing a monster restores 15 energy",[4]="Killing a monster restores 20 energy",[5]="Killing a monster restores 25 energy"},
		[14]={[1]="Poisoning is the art of mastering toxins through self-experimentation, transforming suffering into vitality. Higher skill levels increase your energy regeneration.\n\nEach attack deals bonus water damage equal to 0.1% of the target's HP per skill point.\n\n",
			[2]="You regenerate " .. Formulas.assassinEnergyPerSec(1) .. " energy per second",[3]="You regenerate " .. Formulas.assassinEnergyPerSec(2) .. " energy per second",[4]="You regenerate " .. Formulas.assassinEnergyPerSec(3) .. " energy per second",[5]="You regenerate " .. Formulas.assassinEnergyPerSec(4) .. " energy per second"},
		[15]={[1]="Assassination focuses on eliminating isolated targets before they react. Attacks that spend energy or spells, have your damage increased by 2-3-4-5 per skill point, reduced by 20% for each target's nearby enemy (up to 4 enemies).\nSuch attacks also grant 1 combo point, allowing the assassin to cast offensive spells.\nBow has 50% chance and energy cost.\n\nHigher levels also grant more starting energy, ideal for high burst damage in short engagements.\n\n",
			[2]="Increases your maximum energy by 10",[3]="Increases your maximum energy by 20",[4]="Increases your maximum energy by 30",[5]="Increases your maximum energy by 40"},
	}},

	}

	local function slotText(slots, pl, id, part)
		local slot=slots[id]
		local v=slot and slot[part]
		if type(v)=="function" then
			v=v(pl, id)
		end
		return v
	end

	local function classText(pl, id, part)
		for i=1,#classSpecs do
			if classSpecs[i].match(pl) then
				local v=slotText(classSpecs[i].slots, pl, id, part)
				if v then
					return v
				end
				break
			end
		end
		return neutralText[id] and neutralText[id][part]
	end

	--register exactly the slots the tables above declare
	local covered={}
	local function cover(slots)
		for id, parts in pairs(slots) do
			covered[id]=covered[id] or {}
			for part in pairs(parts) do
				covered[id][part]=true
			end
		end
	end
	for i=1,#classSpecs do
		cover(classSpecs[i].slots)
	end
	cover(neutralText)
	for id, parts in pairs(covered) do
		for part in pairs(parts) do
			ST.set(id, part, classText, "class school text")
		end
	end

	--was dragonSkill desc + engine-array writes: dragons swap Unarmed/Dodging
	--for Fangs/Scales by RACE, independent of the class system above (their
	--slots don't overlap it)
	local dragonSlots={
		[33]={[1]=function(pl)
			local cap=vars.madnessMode and 900 or 600
			return "Dragons can use their fangs to deal atrocious damage to enemies. Damage is 30 + 2 per level (up to level " .. cap .. "). Fang skill increases this amount by a percentage based on mastery and skill level.\n\nWhenever this skill is below dragon skill it will push monsters away\nEach point in the skill increases damage and increases recovery time by 1.5%.\n" .. "\n------------------------------------------------------------\n            Attack| Dmg|"
		end,
			[2]=fangsNormal,[3]=fangsExpert,[4]=fangsMaster,[5]=fangsGM},
		[32]={[1]=function(pl)
			local cap=vars.madnessMode and 900 or 600
			return "Dragons scales are hard enough to work as natural armor, gaining naturally 40 + 1 AC per level (up to level " .. cap .. ").\nScales further enhance their toughness and resistance to magical damage, increasing the thoughness by a percentage.\n\n------------------------------------------------------------\n          AC%| Res%"
		end,
			[2]=scalesNormal,[3]=scalesExpert,[4]=scalesMaster,[5]=scalesGM},
	}
	local function dragonText(pl, id, part)
		if Game.CharacterPortraits[pl.Face].Race~=const.Race.Dragon then
			return nil
		end
		return slotText(dragonSlots, pl, id, part)
	end
	for id, parts in pairs(dragonSlots) do
		for part in pairs(parts) do
			ST.set(id, part, dragonText, id==33 and "dragon fangs" or "dragon scales")
		end
	end
end

function SkillTooltip.start()
	function events.GameInitialized2()
		registerClassBuilders()
	end
end