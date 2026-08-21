--[[
Maw artifact effects
====================
What an artifact DOES on top of its stats: on-hit damage, on-hit spells,
anti-type multipliers, vampirism, and the two over-time effects that are not
plain regen. Ported out of Global/ExtraArtifacts.lua so that file can ship
empty -- it is a base MMMerge file and players overwrite it.

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
--       Add        = 10,                  -- base on-hit damage, see MawArtifactOnHitDamage
--       MultVs     = {[const.MonsterKind.Dragon] = 2},
--       Vampiric   = true,                -- hits leech, like enchants 16/41
--       OnHit      = function(t, pl, it) ... end,   -- spells and other side effects
--   }
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

-- Splitter
artifactOnHit[1308] = {
	DamageKind = const.Damage.Fire,
	Add = 10,
	OnHit = function(t, pl, it)
		local skill, mastery = MawArtifactSpellPower(pl, it)
		CastSpellDirect(125, skill, mastery)
		castAt(6, pl, it, t.Monster)
	end,
}
-- Iron Feather
artifactOnHit[1303] = {
	DamageKind = const.Damage.Air,
	Add = 15,
}
-- Ghoulsbane
artifactOnHit[1309] = {
	DamageKind = const.Damage.Fire,
	Add = 15,
	MultVs = {[const.MonsterKind.Undead] = 2},
}
-- Gibbet
artifactOnHit[1310] = {
	DamageKind = const.Damage.Fire,
	Add = 15,
	MultVs = {
		[const.MonsterKind.Undead] = 2,
		[const.MonsterKind.Dragon] = 2,
		[const.MonsterKind.Demon]  = 2,
	},
}
-- Ullyses
artifactOnHit[1312] = {
	DamageKind = const.Damage.Water,
	Add = 15,
}
-- Old Nick
artifactOnHit[1319] = {
	DamageKind = const.Damage.Water,
	Add = 36,
	MultVs = {[const.MonsterKind.Elf] = 2},
}
-- Elfbane -- NOTE: no Add. The old code doubled the engine's own additional
-- damage instead, which Maw zeroes, so this weapon has had no anti-elf bonus
-- for a while. It needs an Add of its own to mean anything.
artifactOnHit[1333] = {
	MultVs = {[const.MonsterKind.Elf] = 2},
}
-- Mordred
artifactOnHit[2020] = {
	Vampiric = true,
}
-- Thor
artifactOnHit[2021] = {
	Add = 10,
	OnHit = function(t, pl, it)
		CastSpellDirect(125, 7, 3)
		if t.Monster.HP - t.Result > 0 then
			castAt(18, pl, it, t.Monster)
		end
	end,
}
-- Conan
artifactOnHit[2022] = {
	Add = 10,
	MultVs = {
		[const.MonsterKind.Dragon] = 2,
		[const.MonsterKind.Demon]  = 2,
	},
}
-- Excalibur
artifactOnHit[2023] = {
	Add = 10,
	MultVs = {[const.MonsterKind.Dragon] = 2},
}
-- Percival
artifactOnHit[2025] = {
	DamageKind = const.Damage.Fire,
	OnHit = function(t, pl, it)
		castAt(6, pl, it, t.Monster)
	end,
}
-- Hades
artifactOnHit[2035] = {
	DamageKind = const.Damage.Water,
	Add = 20,
	OnHit = function(t, pl, it)
		local skill, mastery = MawArtifactSpellPower(pl, it)
		CastSpellDirect(29, skill, mastery)
	end,
}
-- Ares
artifactOnHit[2036] = {
	DamageKind = const.Damage.Fire,
	Add = 30,
}
-- Artemis
artifactOnHit[2040] = {
	DamageKind = const.Damage.Air,
	Add = 20,
}

function MawArtifactVampiric(itemNumber)
	local effect = artifactOnHit[itemNumber]
	return effect ~= nil and effect.Vampiric == true
end

----------------------------------------------------------------------
-- The damage
----------------------------------------------------------------------

--The legacy curve, kept as it was so nothing moves in this pass: doubles by
--level 100, caps at x5, never below x0.5. It is deliberately one function so
--rebalancing this is one edit, not fifteen.
ARTIFACT_ONHIT_LEVEL_CAP = 2.5
ARTIFACT_ONHIT_LEVEL_MIN = 0.5

function MawArtifactOnHitDamage(pl, effect)
	if not effect.Add then
		return 0
	end
	local levelMult = math.max(
		math.min(pl.LevelBase/100, ARTIFACT_ONHIT_LEVEL_CAP)*2,
		ARTIFACT_ONHIT_LEVEL_MIN)
	return effect.Add*levelMult
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
	local damage = MawArtifactOnHitDamage(pl, effect)
	if effect.MultVs then
		local kind = Game.Bolster.Monsters[t.Monster.Id].Type
		damage = damage*(effect.MultVs[kind] or 1)
	end
	damage = damage/2^(resistanceFor(t.Monster, effect.DamageKind)/100)
	if effect.OnHit then
		effect.OnHit(t, pl, it)
	end
	return damage
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
	if not data.Object and t.DamageKind == 4 then
		for i = 0, 1 do
			damage = damage + onHitForItem(t, pl, pl:GetActiveItem(i))
		end
	elseif data.Object and (data.Object.Spell == 133 or data.Spell == 135) then
		damage = damage + onHitForItem(t, pl, pl:GetActiveItem(2))
	end
	t.Result = t.Result + damage
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

ETHRIC_STAFF_HP_DRAIN = -3

function events.RegenTick(pl)
	for it in pl:EnumActiveItems() do
		if it.Number == 543 then
			sharedLife(pl)
		elseif it.Number == 1317 and pl.Class ~= const.Class.Lich then
			overTimeHPSP(pl, "HP", ETHRIC_STAFF_HP_DRAIN)
		end
	end
end

----------------------------------------------------------------------
-- Stub kept alive for the multiplayer sync, which calls it per player on load
-- (Modules/Multiplayer/Synchronization/SaveLoadExit.lua). It used to recount
-- ExtraArtifacts' baked effects; Maw recomputes everything in itemStats, so
-- there is nothing left to bake -- but the call site must still find a
-- function here.
----------------------------------------------------------------------
Game.CountItemBonuses = function() end
