-- SkillTooltip.lua -- per-player skill tooltip text (SKILL_TOOLTIPS.md).
--
-- Legacy: events.Tick/Action handlers rewrote the GLOBAL description store
-- (Skillz.setDesc / Game.SkillDes*) for the current player while the skill
-- screen was open. Here the store holds only static text; anything dynamic
-- is a builder function (pl, skillId, part) -> string registered per
-- (skill, part) slot. Nothing is written back; text is computed at
-- click time for the player the tooltip is about.
--
-- Entry point:
--   MawCore.SkillTooltip.getTooltipText(pl, skillId [, withBonus])
-- composes the full hint exactly as SkillsUI renders it: part 1 body, then
-- one row per mastery part (2 = Novice .. 9 = Deity) colored by whether the
-- player's class / promoted class can reach that mastery, then the buffed
-- "Bonus:" line unless withBonus is false.
--
-- Part slots follow the Skillz desc convention: 1 = description body,
-- part n = mastery row for mastery n-1 (2 Novice, 3 Expert, 4 Master,
-- 5 Grand, 6 Supreme, ...). Builders return nil to fall through to the
-- static desc store (Skillz.getDesc, which itself falls back to the
-- engine's SkillDes* arrays for base skills).

local SkillTooltip = {}
MawCore.SkillTooltip = SkillTooltip

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
-- Migrated dynamic builders (batch 1) -- verbatim bodies from the legacy
-- Tick/Action rewriters, per SKILL_TOOLTIPS.md. Base strings captured by
-- the legacy files at GameInitialized2 (baseRegStr, baseMedStr, baseAscStr,
-- baseSpearTooltip, maceGMtxt) stay captured THERE -- the capture timing
-- relative to other init appends is part of the displayed text.
-- Where legacy indexed per-player vars tables with Game.CurrentPlayer it
-- still does; the hint is only ever built for the current player.
------------------------------------------------------------------------

-- was zzMAW-Skills.lua "DINAMIC SKILL TOOLTIP" events.Tick

SkillTooltip.set(30, 1, function(pl)
	local FHP = GetMaxHP(pl)
	local s, m = SplitSkill(pl:GetSkill(30))
	local regenEffect = {[0] = 0, 2, 4, 6, 6}
	local hpRegen = round(FHP ^ 0.5 * s ^ 1.65 * ((regenEffect[m]) / 35)) / 10 + s
	local hpRegen2 = round(FHP ^ 0.5 * (s + 1) ^ 1.65 * ((regenEffect[m]) / 35)) / 10 + (s + 1)
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
	if m == 4 then
		m = 5
	end
	local spRegen = (FSP ^ 0.35 * s ^ 1.4 * ((m + 1) / 20) + 2) / 10
	local spRegen2 = (FSP ^ 0.35 * (s + 1) ^ 1.4 * ((m + 1) / 20) + 2) / 10
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
	local mult = damageMultiplier[pl:GetIndex()]["Melee"]
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
	local chance = round(s / pl.LevelBase ^ 0.65 * 1500 * damageMultiplier[pl:GetIndex()].Melee / math.min(1 + pl.LevelBase / 150, 3)) / 100
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
