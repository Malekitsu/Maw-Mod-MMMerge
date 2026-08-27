--[[
Maw artifact effects
====================
What an artifact DOES on top of its stats: on-hit damage and spells, anti-type
multipliers, vampirism, permanent buffs, condition immunities, attack speed,
HP drains, Cycle of Life, wear requirements (class/race/sex, and the Wetsuit's
rules), and the Horn of Ros. Ported out of Global/ExtraArtifacts.lua so that
file can ship empty -- it is a base MMMerge file and players overwrite it.
The tooltip regenerates its effect lines from these same tables
(MawArtifactOnHitText), so Items.txt descriptions can stop mentioning them.

The stat side is NOT here: it lives in the coefficient budget
(artifactPower in zzMaw-Items.lua, priced by MawCore/Artifacts.lua).

Where the damage is applied
---------------------------
NOT through events.ItemAdditionalDamage. That hook stays at 0 (zzMaw_Legendaries
zeroes it) because Maw computes every on-hit add of its own -- fire aura, weapon
enchants -- inside the damage pipeline, after resistances. Artifact on-hit
damage joins them there, as the "artifact-on-hit" stage of MawCore/Damage.lua.
Keeping it in the engine hook would put it before Maw's own resistance handling
and outside the one place the damage order is readable.
--]]

----------------------------------------------------------------------
-- The table
--
--   artifactOnHit[2023] = {
--       DamageKind = const.Damage.Fire,   -- what the on-hit damage counts as
--       Damage     = 1,                   -- x the "of Carnage" enchant, see below
--       MultVs     = {[const.MonsterKind.Dragon] = 2},
--       Vampiric   = true,                -- hits leech, like enchants 16/41
--       OnHit      = function(t, pl, it) ... end,   -- spells and other side effects
--   }
--
-- Damage is a COEFFICIENT, not a number: 1 means exactly what the strongest
-- weapon damage enchant (enchantbonusdamage[46]) would deal on this same
-- weapon at the same item level -- same curve, same roll shape, same floor.
-- Coefficients average about 1 across the artifacts: an artifact whose on-hit
-- power is the whole identity sits above it, one that also casts a spell or
-- doubles against a type pays for that below it.
--
-- MultVs replaces the old hand-written "Special" that poked t.Result: the
-- Specials that only doubled damage against a monster type were data, not code,
-- and as data they can be read by a tooltip later.
----------------------------------------------------------------------

artifactOnHit = {}

--the caster power an artifact's spell goes off at: the wielder's own skill in
--that weapon, or master 7 for weapons with no skill
function MawArtifactSpellPower(pl, it)
	local skill, mastery = 7, 3
	local skillNum = Game.ItemsTxt[it.Number].Skill
	if skillNum < 39 then
		skill, mastery = SplitSkill(pl:GetSkill(skillNum))
	end
	return skill, mastery
end

local function castAt(spell, pl, it, mon)
	local skill, mastery = MawArtifactSpellPower(pl, it)
	evt.CastSpell(spell, mastery, skill, mon.X, mon.Y, mon.Z + 50, mon.X, mon.Y, mon.Z)
end

----------------------------------------------------------------------
-- MM8 artifacts (500-543). Their on-hit effects were hardcoded in the engine
-- and died when Maw zeroed ItemAdditionalDamage, so they are re-stated here
-- from the Items.txt notes. Only the ON-HIT part: stats live in artifactPower,
-- regen and Cycle of Life below. The notes' "20-40 points" is exactly the
-- Carnage enchant's roll, so that reads as Damage = 1; smaller printed rolls
-- read proportionally (12-24 -> 0.6, flat 20 -> 0.5, 8-20 -> 0.5).
----------------------------------------------------------------------

-- Elsenrail: 20-40 Light damage
artifactOnHit[500] = {
	DamageKind = const.Damage.Light,
	Damage = 1,
}
-- Glomenthal: 20-40 Dark damage
artifactOnHit[501] = {
	DamageKind = const.Damage.Dark,
	Damage = 1,
}
-- Judicious Measure: Ogre Slaying
artifactOnHit[503] = {
	Damage = 0.8,
	MultVs = {[const.MonsterKind.Ogre] = 2},
}
-- Elderaxe: 12-24 Cold damage (Swift and the stats live elsewhere)
artifactOnHit[504] = {
	DamageKind = const.Damage.Water,
	Damage = 0.6,
}
-- Volcano: 20-40 Fire damage
artifactOnHit[505] = {
	DamageKind = const.Damage.Fire,
	Damage = 1,
}
-- Wyrm Spitter: Dragon Slaying
artifactOnHit[506] = {
	Damage = 0.8,
	MultVs = {[const.MonsterKind.Dragon] = 2},
}
-- Guardian: 20-40 Body damage
artifactOnHit[507] = {
	DamageKind = const.Damage.Body,
	Damage = 1,
}
-- Foulfang: Vampiric, 20 Poison damage (poison enchants deal Body, like
-- enchantbonusdamage 13-15)
artifactOnHit[508] = {
	DamageKind = const.Damage.Body,
	Damage = 0.5,
	Vampiric = true,
}
-- Breaker: 20-40 Body damage
artifactOnHit[510] = {
	DamageKind = const.Damage.Body,
	Damage = 1,
}
-- Snake: slows target -- the Slow spell cast at the monster, like the other
-- artifacts' on-hit spells, so bosses and CC handling stay the engine's/Maw's
artifactOnHit[523] = {
	Text = "Slows the target on hit",
	OnHit = function(t, pl, it)
		castAt(const.Spells.Slow, pl, it, t.Monster)
	end,
}
-- Finality: 20-40 Fire damage, slows target
artifactOnHit[525] = {
	DamageKind = const.Damage.Fire,
	Damage = 1,
	Text = "Slows the target on hit",
	OnHit = function(t, pl, it)
		castAt(const.Spells.Slow, pl, it, t.Monster)
	end,
}
-- Spiritslayer: Vampiric
artifactOnHit[527] = {
	Vampiric = true,
}
-- Blade of Mercy: 8-20 Electrical damage
artifactOnHit[529] = {
	DamageKind = const.Damage.Air,
	Damage = 0.5,
}
-- Mace of the Sun: Elemental Slaying (its VarA special, stripped at roll time)
artifactOnHit[538] = {
	Damage = 0.8,
	MultVs = {[const.MonsterKind.Elemental] = 2},
}
-- Ebonest: Dragon Slaying
artifactOnHit[539] = {
	Damage = 0.8,
	MultVs = {[const.MonsterKind.Dragon] = 2},
}
-- Sword of Whistlebone: Dragon Slaying
artifactOnHit[540] = {
	Damage = 0.8,
	MultVs = {[const.MonsterKind.Dragon] = 2},
}
-- Axe of Balthazar: "of Ice" -- cold damage on every blow
artifactOnHit[541] = {
	DamageKind = const.Damage.Water,
	Damage = 1,
}
-- Noblebone Bow: "of Carnage" -- literally the enchant this whole table is
-- priced against
artifactOnHit[542] = {
	Damage = 1,
}

-- Splitter
artifactOnHit[1308] = {
	DamageKind = const.Damage.Fire,
	Damage = 0.7,
	Text = "Casts Fireball on hit",
	OnHit = function(t, pl, it)
		local skill, mastery = MawArtifactSpellPower(pl, it)
		CastSpellDirect(125, skill, mastery)
		castAt(6, pl, it, t.Monster)
	end,
}
-- Iron Feather
artifactOnHit[1303] = {
	DamageKind = const.Damage.Air,
	Damage = 1.2,
}
-- Ghoulsbane
artifactOnHit[1309] = {
	DamageKind = const.Damage.Fire,
	Damage = 1,
	MultVs = {[const.MonsterKind.Undead] = 2},
}
-- Gibbet
artifactOnHit[1310] = {
	DamageKind = const.Damage.Fire,
	Damage = 0.9,
	MultVs = {
		[const.MonsterKind.Undead] = 2,
		[const.MonsterKind.Dragon] = 2,
		[const.MonsterKind.Demon]  = 2,
	},
}
-- Ullyses
artifactOnHit[1312] = {
	DamageKind = const.Damage.Water,
	Damage = 1.2,
}
-- Old Nick
artifactOnHit[1319] = {
	DamageKind = const.Damage.Water,
	Damage = 1.1,
	MultVs = {[const.MonsterKind.Elf] = 2},
}
-- Elfbane -- the old code doubled the engine's own additional damage, which
-- Maw zeroes, so this weapon had no anti-elf bonus for a while; the Damage
-- gives its MultVs something to double.
artifactOnHit[1333] = {
	Damage = 0.8,
	MultVs = {[const.MonsterKind.Elf] = 2},
}
-- Mordred
artifactOnHit[2020] = {
	Vampiric = true,
}
-- Thor
artifactOnHit[2021] = {
	Damage = 0.7,
	Text = "Casts Lightning Bolt on hit",
	OnHit = function(t, pl, it)
		CastSpellDirect(125, 7, 3)
		if t.Monster.HP - t.Result > 0 then
			castAt(18, pl, it, t.Monster)
		end
	end,
}
-- Conan
artifactOnHit[2022] = {
	Damage = 0.9,
	MultVs = {
		[const.MonsterKind.Dragon] = 2,
		[const.MonsterKind.Demon]  = 2,
	},
}
-- Excalibur
artifactOnHit[2023] = {
	Damage = 1,
	MultVs = {[const.MonsterKind.Dragon] = 2},
}
-- Percival
artifactOnHit[2025] = {
	DamageKind = const.Damage.Fire,
	Damage = 0.6,
	Text = "Casts Fireball on hit",
	OnHit = function(t, pl, it)
		castAt(6, pl, it, t.Monster)
	end,
}
-- Hades -- the on-hit damage is priced ABOVE the pure-damage artifacts on
-- purpose: the sword pays for it by draining its wielder (artifactLeech)
artifactOnHit[2035] = {
	DamageKind = const.Damage.Water,
	Damage = 2,
	Text = "Casts Acid Burst on hit",
	OnHit = function(t, pl, it)
		local skill, mastery = MawArtifactSpellPower(pl, it)
		CastSpellDirect(29, skill, mastery)
	end,
}
-- Ares
artifactOnHit[2036] = {
	DamageKind = const.Damage.Fire,
	Damage = 1.4,
}
-- Artemis
artifactOnHit[2040] = {
	DamageKind = const.Damage.Air,
	Damage = 1.2,
}

function MawArtifactVampiric(itemNumber)
	local effect = artifactOnHit[itemNumber]
	return effect ~= nil and effect.Vampiric == true
end

----------------------------------------------------------------------
-- Tooltip lines. Items.txt descriptions will stop mentioning these effects:
-- this table is becoming the single source, so the tooltip regenerates the
-- lines from the same fields the damage code reads.
----------------------------------------------------------------------

local damageKindName = {
	[const.Damage.Phys]  = "Physical",
	[const.Damage.Fire]  = "Fire",
	[const.Damage.Air]   = "Air",
	[const.Damage.Water] = "Water",
	[const.Damage.Earth] = "Earth",
	[const.Damage.Spirit]= "Spirit",
	[const.Damage.Mind]  = "Mind",
	[const.Damage.Body]  = "Body",
	[const.Damage.Light] = "Light",
	[const.Damage.Dark]  = "Dark",
}

local monsterKindName
local function kindName(kind)
	if not monsterKindName then
		monsterKindName = {}
		for name, id in pairs(const.MonsterKind) do
			monsterKindName[id] = name
		end
	end
	return monsterKindName[kind] or "?"
end

local playerBuffName = {
	[const.PlayerBuff.Shield] = "Shield",
	[const.PlayerBuff.WaterBreathing] = "Water Breathing",
	[const.PlayerBuff.Bless] = "Bless",
	[const.PlayerBuff.Stoneskin] = "Stone Skin",
	[const.PlayerBuff.Preservation] = "Preservation",
}

--Poison1..3 and Disease1..3 are one word to the player
local immunityName = {
	[const.MonsterBonus.Insane] = "Insanity",
	[const.MonsterBonus.Disease1] = "Disease",
	[const.MonsterBonus.Disease2] = "Disease",
	[const.MonsterBonus.Disease3] = "Disease",
	[const.MonsterBonus.Paralyze] = "Paralysis",
	[const.MonsterBonus.Stone] = "Stone",
	[const.MonsterBonus.Poison1] = "Poison",
	[const.MonsterBonus.Poison2] = "Poison",
	[const.MonsterBonus.Poison3] = "Poison",
	[const.MonsterBonus.Asleep] = "Sleep",
}

--Every effect line an artifact is worth, in display order: on-hit, magic
--schools, buffs, immunities, speed, drain, wear requirement. nil when the item
--has none.
--Items.txt stops mentioning any of this; these tables are the source.
function MawArtifactOnHitText(it)
	local lines = {}
	local effect = artifactOnHit[it.Number]
	if effect then
		if effect.Damage then
			local lo, hi = enchantDamageRange(it, ARTIFACT_ONHIT_ENCHANT, MawArtifactLevel())
			lines[#lines + 1] = "+" .. round(lo*effect.Damage) .. "-"
				.. round(hi*effect.Damage) .. " "
				.. damageKindName[effect.DamageKind or const.Damage.Phys]
				.. " damage on hit"
		end
		if effect.MultVs then
			local names = {}
			for kind in pairs(effect.MultVs) do
				names[#names + 1] = kindName(kind)
			end
			table.sort(names)
			--print the factor of the first entry so a future non-2 value
			--shows itself instead of lying
			local _, factor = next(effect.MultVs)
			lines[#lines + 1] = "x" .. factor .. " damage vs " .. table.concat(names, ", ")
		end
		if effect.Vampiric then
			lines[#lines + 1] = "Vampiric"
		end
		if effect.Text then
			lines[#lines + 1] = effect.Text
		end
	end

	local schools = artifactSpellBonus[it.Number]
	if schools then
		local names = {}
		for _, skill in ipairs(schools) do
			names[#names + 1] = Game.SkillNames[skill]
		end
		table.sort(names)
		lines[#lines + 1] = "+" .. round(ARTIFACT_SPELL_SKILL_BONUS*100)
			.. "% skill in " .. table.concat(names, ", ")
	end
	local buffs = artifactBuffs[it.Number]
	if buffs then
		local names = {}
		for buff in pairs(buffs) do
			names[#names + 1] = playerBuffName[buff] or "?"
		end
		table.sort(names)
		lines[#lines + 1] = "Permanent " .. table.concat(names, ", ")
	end
	local immune = artifactImmunities[it.Number]
	if immune then
		local seen, names = {}, {}
		for thing in pairs(immune) do
			local name = immunityName[thing]
			if name and not seen[name] then
				seen[name] = true
				names[#names + 1] = name
			end
		end
		table.sort(names)
		lines[#lines + 1] = "Immune to " .. table.concat(names, ", ")
	end
	if artifactAttackSpeed[it.Number] then
		lines[#lines + 1] = "Swift"
	end
	local drain = artifactDrain[it.Number]
	if drain then
		lines[#lines + 1] = "Drains " .. -drain.HP .. " HP over time"
	end
	--pre-colored red: the caller wraps lines in orange, and the inner color
	--code wins, so the malus stands out from the bonuses around it
	local leech = artifactLeech[it.Number]
	if leech then
		lines[#lines + 1] = StrColor(255, 64, 64,
			"Negative drain life: " .. round(-leech*100) .. "%")
	end
	local req = artifactWearReq[it.Number]
	if req and req.Text then
		lines[#lines + 1] = req.Text
	end
	if #lines == 0 then
		return nil
	end
	return lines
end

----------------------------------------------------------------------
-- The damage
----------------------------------------------------------------------

--Priced against the strongest weapon damage enchant: enchantDamageRange with
--the level passed EXPLICITLY, so the artifact borrows the enchant's whole
--curve -- roll shape, two-handed floor, level scaling -- at getTotalLevel().
--A regular enchant reads its level off MaxCharges; an artifact has none, and
--rather than trust the ItemLevel.OfItem special case from here, the level is
--handed over directly: tooltip and damage cannot end up on the floor values
--by a broken conditional upstream.
ARTIFACT_ONHIT_ENCHANT = 46

--the level artifact on-hit damage is priced at; 0 before a game exists
function MawArtifactLevel()
	if vars.MMLVL then
		return getTotalLevel()
	end
	return 0
end

function MawArtifactOnHitDamage(it, effect, rand, pl)
	if not effect.Damage then
		return 0
	end
	local lo, hi, avg = enchantDamageRange(it, ARTIFACT_ONHIT_ENCHANT, MawArtifactLevel())
	local damage = avg
	if rand then
		damage = math.random(round(lo), round(hi))
	end
	local pace=pl and GetPlayerBaseRecovery(pl, it)/100 or 1
	return damage*effect.Damage*pace
end

function MawArtifactOnHitPower(it, pl)
	local effect = it and artifactOnHit[it.Number]
	if not effect or it.Broken then
		return 0
	end
	return MawArtifactOnHitDamage(it, effect, false, pl)
end

--damageKindMap is index -> const.Damage; resistances are read by index, so the
--table has to be walked the other way round. Built once, lazily: zzMaw-Stats
--defines the map at load and this file only needs it at damage time.
local resistanceIndex

local function resistanceFor(mon, damageKind)
	if not damageKind then
		return 0
	end
	if not resistanceIndex then
		resistanceIndex = {}
		for index, kind in pairs(damageKindMap) do
			resistanceIndex[kind] = index
		end
	end
	local index = resistanceIndex[damageKind]
	if not index then
		return 0
	end
	return mon.Resistances[index]%1000
end

--One weapon's contribution. Returns the damage; the spells fire as a side
--effect, exactly once per hit per weapon, as they did in the engine hook.
local function onHitForItem(t, pl, it)
	local effect = it and artifactOnHit[it.Number]
	if not effect or it.Broken then
		return 0
	end
	local damage = MawArtifactOnHitDamage(it, effect, true, pl)
	if effect.MultVs then
		local kind = Game.Bolster.Monsters[t.Monster.Id].Type
		damage = damage*(effect.MultVs[kind] or 1)
	end
	--no DamageKind means physical, and physical is still resisted as such --
	--leaving it unresisted would make the "plain" artifacts quietly the best
	local kind = effect.DamageKind or const.Damage.Phys
	damage = damage/2^(resistanceFor(t.Monster, kind)/100)
	if effect.OnHit then
		effect.OnHit(t, pl, it)
	end
	return damage, kind
end

--The "artifact-on-hit" stage of the DamageToMonster pipeline. Same slots and
--the same melee/ranged test stage_legendaries uses for the fire aura, so an
--artifact fires under exactly the conditions an enchant does.
function MawArtifactOnHit(t)
	if t.Result == 0 then
		return
	end
	local data = t.Hit
	if not data or not data.Player or not t.Monster then
		return
	end
	local pl = data.Player
	local damage = 0
	local elemental = 0
	local function add(d, kind)
		damage = damage + d
		if d > 0 and kind ~= const.Damage.Phys then
			elemental = elemental + d
		end
	end
	if not data.Object and t.DamageKind == 4 then
		for i = 0, 1 do
			add(onHitForItem(t, pl, pl:GetActiveItem(i)))
		end
	elseif data.Object and (data.Object.Spell == 133 or data.Spell == 135) then
		add(onHitForItem(t, pl, pl:GetActiveItem(2)))
	end
	t.Result = t.Result + damage
	--the spell leech reads this share, the physical leech skips it
	t.ElementalDamage = (t.ElementalDamage or 0) + elemental
end

----------------------------------------------------------------------
-- Over-time effects that are not plain regen.
--
-- Flat HP/SP regen from artifacts is NOT here: Maw already does it as a share
-- of max HP/SP, off artifactHpRegen / artifactSpRegen in zzMaw-Items.lua, and
-- a second flat source would only drift from it.
----------------------------------------------------------------------

--dead, eradicated and petrified characters do not tick
local function overTimeHPSP(pl, field, amount)
	local cond = pl:GetMainCondition()
	if cond >= 17 or cond < 14 then
		pl[field] = math.min(pl[field] + amount, pl["GetFull" .. field](pl))
	end
end

--Cycle of Life (543): pulls the wearer up towards the party average, paid for
--by whoever is above it.
local function sharedLife(char)
	local mid = char:GetMainCondition()
	if Party.count == 1 or mid == 14 or mid == 16 or char.HP >= char:GetFullHP() then
		return
	end
	local donors = {}
	local pool = char.HP
	local need = 1
	for i, v in Party do
		local over = v.HP - char.HP
		if over > 0 then
			pool = pool + v.HP
			need = need + 1
			donors[i] = over
		end
	end
	mid = math.floor(pool/need)
	need = mid - char.HP
	pool = need
	for k, v in pairs(donors) do
		local p = Party[k]
		local taken = math.min(math.max(p.HP - mid, 0), need)
		p.HP = p.HP - math.floor(taken/2)
		pool = pool - math.floor(taken/2)
	end
	char.HP = char.HP + math.ceil(need - pool)
	if char.HP > 0 and char.Conditions[13] > 0 then
		char.Conditions[13] = 0
	end
	char:ShowFaceAnimation(const.FaceAnimation.Smile)
end

--HP drained per regen tick while the artifact is worn. ExemptClass: a Lich
--pays no price for Ethric's Staff -- its maker.
artifactDrain = {
	[1317] = {HP = -3, ExemptClass = const.Class.Lich},	-- Ethric's Staff
}

--NEGATIVE LEECH: the artifact drains its wielder for a share of the physical
--damage dealt, through the same leech pipeline that heals vampirism -- so it
--stacks against positive leech naturally (Hades + vampiric enchant = the
--difference). itemStats folds these into lifeLeech.
artifactLeech = {
	[2035] = -0.1,	-- Hades: "draws its power from its wielder"
}

function events.RegenTick(pl)
	for it in pl:EnumActiveItems() do
		local drain = artifactDrain[it.Number]
		if it.Number == 543 then
			sharedLife(pl)
		elseif drain and pl.Class ~= drain.ExemptClass then
			overTimeHPSP(pl, "HP", drain.HP)
		end
	end
end

----------------------------------------------------------------------
-- Wear requirements. Ported from ExtraArtifacts' WearItemConditions: class and
-- race gates, plus the Wetsuit's two special rules. Check runs on the player
-- the item is being put on; Text is what the tooltip prints.
----------------------------------------------------------------------

artifactWearReq = {
	-- Elderaxe
	[504]  = {Text = "Minotaurs only",
		Check = function(pl) return GetRace(pl) == const.Race.Minotaur end},
	-- Foulfang
	[508]  = {Text = "Vampires only",
		Check = function(pl) return GetRace(pl) == const.Race.Vampire end},
	-- Glomenmail
	[514]  = {Text = "Dark Elves only",
		Check = function(pl) return GetRace(pl) == const.Race.DarkElf end},
	-- Supreme Plate: the knight classes (merge ids 16-19)
	[515]  = {Text = "Knights only",
		Check = function(pl) return pl.Class >= 16 and pl.Class <= 19 end},
	-- Eclipse: any cleric-kind class
	[516]  = {Text = "Clerics only",
		Check = function(pl) return Game.ClassesExtra[pl.Class].Kind == 2 end},
	-- Crown of Final Dominion (merge class id 45)
	[521]  = {Text = "Liches only",
		Check = function(pl) return pl.Class == 45 end},
	-- Blade of Mercy (merge class ids 44/45)
	[529]  = {Text = "Necromancers and Liches only",
		Check = function(pl) return pl.Class == 44 or pl.Class == 45 end},
	-- Lightning Crossbow
	[532]  = {Text = "Elves only",
		Check = function(pl)
			local race = GetRace(pl)
			return race == const.Race.DarkElf or race == const.Race.Elf
		end},
	-- Elfbane
	[1333] = {Text = "Goblins only",
		Check = function(pl) return GetRace(pl) == const.Race.Goblin end},
	-- Mind's Eye
	[1334] = {Text = "Humans only",
		Check = function(pl) return GetRace(pl) == const.Race.Human end},
	-- Elven Chainmail
	[1335] = {Text = "Elves only",
		Check = function(pl)
			local race = GetRace(pl)
			return race == const.Race.DarkElf or race == const.Race.Elf
		end},
	-- Forge Gauntlets
	[1336] = {Text = "Dwarves only",
		Check = function(pl) return GetRace(pl) == const.Race.Dwarf end},
	-- Hero's Belt
	[1337] = {Text = "Men only",
		Check = function(pl)
			return Game.CharacterPortraits[pl.Face].DefSex == 0
		end},
	-- Lady's Escort ring
	[1338] = {Text = "Women only",
		Check = function(pl)
			return Game.CharacterPortraits[pl.Face].DefSex == 1
		end},
}

--Wetsuit (1406): wearable only on a doll that can show armor, with nothing in
--the slots it replaces, and no two-handed weapon
local WETSUIT = 1406
local wetsuitSlots = {0, 2, 4, 5, 6, 8}
artifactWearReq[WETSUIT] = {Check = function(pl)
	if not Game.CharacterDollTypes[Game.CharacterPortraits[pl.Face].DollType].Armor then
		return false
	end
	for _, slot in pairs(wetsuitSlots) do
		if pl.EquippedItems[slot] > 0 then
			return false
		end
	end
	local main = pl.EquippedItems[1]
	if main > 0 and Game.ItemsTxt[pl.Items[main].Number].EquipStat == 1 then
		return false
	end
	return true
end}

function events.CanWearItem(t)
	if not t.Available then
		return
	end
	local pl = Party[t.PlayerId]
	--while the Wetsuit is worn only helms, belts, rings and amulets go on
	if pl.ItemArmor > 0 and pl.Items[pl.ItemArmor].Number == WETSUIT then
		local equipStat = Game.ItemsTxt[t.ItemId].EquipStat
		if not (equipStat == 0 or equipStat == 3 or equipStat == 8
				or equipStat == 10 or equipStat == 11) then
			t.Available = false
			return
		end
	end
	local req = artifactWearReq[t.ItemId]
	if req and not req.Check(pl) then
		t.Available = false
	end
end

----------------------------------------------------------------------
-- Permanent buffs while equipped, and the Horn of Ros (2055), which grants
-- the party Detect Life just for being carried. The old file refreshed these
-- on a two-game-minute Timer; here a scheduler task tops the buffs up so they
-- quietly lapse a few game minutes after the item leaves.
----------------------------------------------------------------------

artifactBuffs = {
	[1306] = {[const.PlayerBuff.Shield] = 3},			-- Governor's Armor
	[1318] = {[const.PlayerBuff.WaterBreathing] = 0},	-- Hareck's Leather
	[1322] = {[const.PlayerBuff.Shield] = 3},			-- Kelebrim
	[1333] = {[const.PlayerBuff.Shield] = 3},			-- Elfbane
	[1338] = {[const.PlayerBuff.WaterBreathing] = 0},	-- Lady's Escort ring
	[1347] = {[const.PlayerBuff.Preservation] = 3},		-- Ghost Ring
	[WETSUIT] = {[const.PlayerBuff.WaterBreathing] = 0},
	[2023] = {[const.PlayerBuff.Bless] = 3},			-- Excalibur
	[2026] = {[const.PlayerBuff.Shield] = 3,			-- Galahad
			  [const.PlayerBuff.Stoneskin] = 20},
	[2027] = {[const.PlayerBuff.Stoneskin] = 20},		-- Pellinore
	[2028] = {[const.PlayerBuff.Shield] = 3},			-- Valeria
	[2043] = {[const.PlayerBuff.Shield] = 3},			-- Aegis
}

HORN_OF_ROS = 2055

local ARTIFACT_BUFF_DURATION = const.Minute*3

local function refreshBuff(buff, skill)
	buff.ExpireTime = math.max(buff.ExpireTime, Game.Time + ARTIFACT_BUFF_DURATION)
	if buff.Power < skill then
		buff.Power = skill
		buff.Skill = skill
	end
	buff.OverlayId = 0
end

local function partyHasItem(number)
	for i = 0, Party.High do
		for _, item in Party[i].Items do
			if item.Number == number then
				return true
			end
		end
	end
	return false
end

function mawTick_ArtifactBuffs()
	for i = 0, Party.High do
		local pl = Party[i]
		for it in pl:EnumActiveItems() do
			local buffs = artifactBuffs[it.Number]
			if buffs then
				for buff, skill in pairs(buffs) do
					refreshBuff(pl.SpellBuffs[buff], skill)
				end
			end
		end
	end
	if partyHasItem(HORN_OF_ROS) then
		refreshBuff(Party.SpellBuffs[const.PartyBuff.DetectLife], 3)
	end
end

function events.GameInitialized2()
	MawCore.Scheduler.every("artifacts/buffs", 2000, mawTick_ArtifactBuffs)
end

----------------------------------------------------------------------
-- Condition immunities while equipped.
----------------------------------------------------------------------

artifactImmunities = {
	-- Yoruba
	[1307] = {[const.MonsterBonus.Insane] = true,
			[const.MonsterBonus.Disease1] = true,
			[const.MonsterBonus.Disease2] = true,
			[const.MonsterBonus.Disease3] = true,
			[const.MonsterBonus.Paralyze] = true,
			[const.MonsterBonus.Stone] = true,
			[const.MonsterBonus.Poison1] = true,
			[const.MonsterBonus.Poison2] = true,
			[const.MonsterBonus.Poison3] = true,
			[const.MonsterBonus.Asleep] = true},
	-- Ghoulsbane
	[1309] = {[const.MonsterBonus.Paralyze] = true},
	-- Kelebrim
	[1322] = {[const.MonsterBonus.Stone] = true},
	-- Cloak of the Sheep
	[1332] = {[const.MonsterBonus.Insane] = true,
			[const.MonsterBonus.Disease1] = true,
			[const.MonsterBonus.Disease2] = true,
			[const.MonsterBonus.Disease3] = true,
			[const.MonsterBonus.Paralyze] = true,
			[const.MonsterBonus.Stone] = true,
			[const.MonsterBonus.Poison1] = true,
			[const.MonsterBonus.Poison2] = true,
			[const.MonsterBonus.Poison3] = true,
			[const.MonsterBonus.Asleep] = true},
	-- Medusa's Mirror
	[1341] = {[const.MonsterBonus.Stone] = true},
	-- Pendragon
	[2030] = {[const.MonsterBonus.Poison1] = true,
			[const.MonsterBonus.Poison2] = true,
			[const.MonsterBonus.Poison3] = true},
	-- Aegis
	[2043] = {[const.MonsterBonus.Stone] = true},
}

function events.DoBadThingToPlayer(t)
	if not t.Allow then
		return
	end
	for it in t.Player:EnumActiveItems() do
		local immune = artifactImmunities[it.Number]
		if immune and immune[t.Thing] then
			t.Allow = false
			return
		end
	end
end

----------------------------------------------------------------------
-- Attack speed ("Swift"). The old file halved the printed mod and applied it
-- as a multiplier; -20 is x0.9 recovery. Runs after zzMAW-Skills' full
-- GetAttackDelay recompute, so it scales the finished number.
----------------------------------------------------------------------

artifactAttackSpeed = {
	[515]  = -20,	-- Supreme Plate
	[1302] = -20,	-- Puck
	[2024] = -20,	-- Merlin
	[2025] = -20,	-- Percival
}

function events.GetAttackDelay(t)
	for it in t.Player:EnumActiveItems() do
		local mod = artifactAttackSpeed[it.Number]
		if mod then
			t.Result = t.Result*((mod/2 + 100)/100)
		end
	end
	t.Result = math.max(t.Result, 0)
end

----------------------------------------------------------------------
-- Stub kept alive for the multiplayer sync, which calls it per player on load
-- (Modules/Multiplayer/Synchronization/SaveLoadExit.lua). It used to recount
-- ExtraArtifacts' baked effects; Maw recomputes everything in itemStats, so
-- there is nothing left to bake -- but the call site must still find a
-- function here.
----------------------------------------------------------------------
Game.CountItemBonuses = function() end
