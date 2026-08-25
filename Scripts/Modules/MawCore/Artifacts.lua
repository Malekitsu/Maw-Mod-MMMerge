-- Artifacts.lua -- what an artifact is worth, priced against loot.
--
-- An artifact is written as a BUDGET, not as numbers. One unit is what a
-- single enchant of a PERFECTLY ROLLED EPIC is worth, on the same slot, at
-- the same level. That statement stays true at every level and in every slot,
-- because there is no second power curve to keep in sync with the loot one:
-- both read encStrUp(GetLootTier()).
--
-- Artifacts.Slots is what a whole artifact is worth, and it is the one dial
-- for "how strong are artifacts". An Epic carries two stat enchants plus a
-- special effect (Bonus, Enc2, Bonus2); an artifact has no slot for a special
-- effect, so the third unit stands in for it. Artifacts with a unique power of
-- their own are that much ahead, which is the point of an artifact.
--
-- The shape, kept in the global artifactPower table next to the rest of the
-- artifact data in zzMaw-Items.lua:
--
--   artifactPower[504] = {
--       [const.Stats.Might]     = 2,    -- worth two perfect enchants
--       [const.Stats.Endurance] = 1,
--       Skills = { [const.Skills.Armsmaster] = 0.5 },
--       Flat   = { [const.Stats.FireResistance] = 65000 },  -- see below
--       baseStatMultiplier = 1.2,       -- weapon damage / armor AC
--   }
--
-- Stats and Skills are separated because their ids collide (both are small
-- integers) and because they are different currencies: see SkillUnit below.
-- Negative coefficients are drawbacks and are perfectly legal.
--
-- Flat is the escape hatch for a number that is NOT a budget: an immunity, a
-- threshold, anything the level curve must not touch. It is added as written.
--
-- baseStatMultiplier is NOT part of the enchant budget. An artifact already
-- carries a top-tier weapon at the party's own item level (ItemLevel.OfItem),
-- which is what a perfect Epic of that level carries too, so 1.0 means "the
-- same base rows as that Epic" and the multiplier is the deviation from it.
--
-- Every artifact is on this system: an id with no entry simply has no bonuses,
-- which is different from having no budget. IsArtifactItem is the test.

local Artifacts = {}
MawCore.Artifacts = Artifacts

Artifacts.Slots = 3	--enchants a perfect Epic carries (enchantCountByRarity)

--One entry point for the data, so it can move without touching the callers.
function Artifacts.PowerOf(itemId)
	return artifactPower and artifactPower[itemId]
end

--Is this item priced by the budget at all? Every artifact is, entry or not.
function Artifacts.Has(it)
	return IsArtifactItem ~= nil and IsArtifactItem(it)
end

--One level for the whole artifact -- the same one its weapon damage uses, so
--stats and damage cannot drift apart.
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

--HP and SP enchants are amplified on read, not at generation: a budget point
--spent on them has to buy the same as the enchant it is priced against.
local function isVitalityStat(stat)
	return stat == const.Stats.HP or stat == const.Stats.SP
end

--Every bonus one artifact is worth: {Stats={[stat]=value}, Skills={[skill]=value}}.
--nil only when the item is not an artifact at all.
--
--Values come out ROUNDED. The character sheet takes whatever lands in the stat
--table and the tooltip prints the same number, so rounding here instead of in
--each caller is what keeps the printed value and the worn value identical.
function Artifacts.BonusesOf(it)
	if not Artifacts.Has(it) then
		return nil
	end
	local power = Artifacts.PowerOf(it.Number)
	local stats, skills = {}, {}
	if power then
		local level = Artifacts.LevelOf(it)
		local slotMult = GetSlotMult(it.Number)
		local statUnit = Artifacts.StatUnit(level, it.Number)
		local skillUnit = Artifacts.SkillUnit(level, it.Number)
		local isRing = GetItemEquipStat(it) == 10
		--string keys are the named fields (Skills, Flat, baseStatMultiplier)
		for key, coeff in pairs(power) do
			if type(key) == "number" then
				local value = coeff*statUnit
				if isResistanceStat(key) then
					value = MawCore.Formulas.resistanceEnchantPower(value, isRing)
				elseif isVitalityStat(key) then
					value = MawCore.Formulas.vitalityEnchantPower(value, slotMult)
				end
				stats[key] = round(value)
			end
		end
		if power.Skills then
			for key, coeff in pairs(power.Skills) do
				skills[key] = round(coeff*skillUnit)
			end
		end
		--Flat is already the number it means, so it is added after the rounding
		--rather than through it
		if power.Flat then
			for key, value in pairs(power.Flat) do
				stats[key] = (stats[key] or 0) + value
			end
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
