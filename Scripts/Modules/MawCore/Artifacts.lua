-- Artifacts.lua -- what an artifact is worth, priced against loot.
--
-- An artifact is written as a BUDGET, not as numbers. One unit is what a
-- single enchant of a PERFECTLY ROLLED EPIC is worth, on the same slot, at
-- the same level. Coefficients that add up to Artifacts.Slots therefore make
-- an artifact exactly as strong as a perfect Epic -- and that statement stays
-- true at every level and in every slot, because there is no second power
-- curve to keep in sync with the loot one: both read encStrUp(GetLootTier()).
--
-- The shape, kept in the global artifactPower table next to the rest of the
-- artifact data in zzMaw-Items.lua:
--
--   artifactPower[504] = {
--       [const.Stats.Might]     = 2,    -- worth two perfect enchants
--       [const.Stats.Endurance] = 1,
--       Skills = { [const.Skills.Armsmaster] = 0.5 },
--       baseStatMultiplier = 1.2,       -- weapon damage / armor AC
--   }
--
-- Stats and Skills are separated because their ids collide (both are small
-- integers) and because they are different currencies: see SkillUnit below.
--
-- baseStatMultiplier is NOT part of the enchant budget. An artifact already
-- carries a top-tier weapon at the party's own item level (ItemLevel.OfItem),
-- which is what a perfect Epic of that level carries too, so 1.0 means "the
-- same base rows as that Epic" and the multiplier is the deviation from it.
--
-- Until an artifact has an entry here the callers fall back to the legacy
-- artifactStatsBonus/artifactSkillBonus tables scaled by artifactPowerMult,
-- so the two systems can coexist while the data is migrated one item at a
-- time. BonusesOf returning nil is the signal to fall back.

local Artifacts = {}
MawCore.Artifacts = Artifacts

Artifacts.Slots = 3	--enchants a perfect Epic carries (enchantCountByRarity)

--One entry point for the data, so it can move without touching the callers.
function Artifacts.PowerOf(itemId)
	return artifactPower and artifactPower[itemId]
end

function Artifacts.Has(it)
	return Artifacts.PowerOf(it.Number) ~= nil
end

--One level for the whole artifact -- the same one its weapon damage already
--uses, so stats and damage cannot drift apart.
function Artifacts.LevelOf(it)
	return MawCore.ItemLevel.OfItem(it)
end

--One perfect Epic enchant BEFORE the slot has its say: rollEnchantStrength at
--the top of its range, which is encStrUp of the loot tier, times the
--difficulty power every roll gets.
function Artifacts.EnchantUnit(level)
	return encStrUp(GetLootTier(level))*GetDifficultyExtraPower()
end

--A stat enchant: the slot multiplies it whole (zzMaw-Items, the slotMult pass
--right after the roll).
function Artifacts.StatUnit(level, itemId)
	return Artifacts.EnchantUnit(level)*GetSlotMult(itemId)
end

--A skill enchant: the generator square-roots the roll BEFORE the slot
--multiplier, so the two are applied in that order here as well.
function Artifacts.SkillUnit(level, itemId)
	return MawCore.Formulas.skillEnchantPower(Artifacts.EnchantUnit(level))
		*GetSlotMult(itemId)
end

--The resistance stats sit in one band, but the band ends on a different name
--per game (MM8/Merge runs Fire..Body, the other layout ends at Poison), so read
--the end off const.Stats instead of naming one of them.
local function isResistanceStat(stat)
	local last = const.Stats.BodyResistance or const.Stats.PoisonResistance
	return stat >= const.Stats.FireResistance and stat <= last
end

--Every bonus one artifact is worth: {Stats={[stat]=value}, Skills={[skill]=value}}.
--nil when the artifact has no coefficients yet -- the caller falls back.
function Artifacts.BonusesOf(it)
	local power = Artifacts.PowerOf(it.Number)
	if not power then
		return nil
	end
	local level = Artifacts.LevelOf(it)
	local statUnit = Artifacts.StatUnit(level, it.Number)
	local skillUnit = Artifacts.SkillUnit(level, it.Number)
	local isRing = GetItemEquipStat(it) == 10
	local stats = {}
	--string keys are the named fields (Skills, baseStatMultiplier)
	for key, coeff in pairs(power) do
		if type(key) == "number" then
			local value = coeff*statUnit
			if isResistanceStat(key) then
				value = MawCore.Formulas.resistanceEnchantPower(value, isRing)
			end
			stats[key] = value
		end
	end
	local skills = {}
	if power.Skills then
		for key, coeff in pairs(power.Skills) do
			skills[key] = coeff*skillUnit
		end
	end
	return {Stats = stats, Skills = skills}
end

--1.0 = exactly the base damage (weapons) or AC (armor) a perfect Epic of the
--same item power carries. 1 for anything with no entry, so callers can
--multiply unconditionally.
function Artifacts.BaseMult(it)
	local power = Artifacts.PowerOf(it.Number)
	return power and power.baseStatMultiplier or 1
end

return Artifacts
