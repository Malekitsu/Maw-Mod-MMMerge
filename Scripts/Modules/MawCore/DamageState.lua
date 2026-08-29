-- DamageState.lua -- the damage values that genuinely cross file boundaries.
--
-- Only two do. Everything else the pipeline carries between stages is a local
-- in Damage.lua. These are here because a legacy file on the other side reads
-- or writes them, and because multiplayer (dormant, GREENFIELD par.9) will
-- need exactly these points to sync: one named setter each, and nothing
-- outside this file touches the storage.

local DamageState = {}
MawCore.DamageState = DamageState

-- Cover bonus. The damage pipeline flags a party slot when a cover lands;
-- the next cover roll adds a bonus chance and consumes the flag. Written by
-- Damage.lua, taken by zzMAW-Skills and zzMaw-Monsters.
local coverBonus = {}

function DamageState.setCoverBonus(slot)
	coverBonus[slot] = true
end

-- True at most once per setCoverBonus, clearing the flag.
function DamageState.takeCoverBonus(slot)
	if not coverBonus[slot] then
		return false
	end
	coverBonus[slot] = false
	return true
end

local soloCover = false

function DamageState.setSoloCover()
	soloCover = true
end

function DamageState.takeSoloCover()
	local on = soloCover
	soloCover = false
	return on
end

-- Custom attacker. zzMaw-Monsters drives some monster projectiles itself
-- instead of through the engine, so WhoHitPlayer() cannot answer "who hit
-- me" for those; it publishes the attacker record here around the hit.
local customAttacker = false

function DamageState.setCustomAttacker(data)
	customAttacker = data
end

function DamageState.clearCustomAttacker()
	customAttacker = false
end

function DamageState.getCustomAttacker()
	return customAttacker
end

-- Crit tag. Set while a hit resolves and read by the status-message stage,
-- which clears it on the NEXT tick rather than immediately so every hit of
-- one same-tick cast shares the tag. zzMaw-Spells sets it for spell crits;
-- the engine crit-message hook in zzMaw-Stats clears it. Stored as given,
-- not normalised, because ShowDamage receives the value directly.
local crit = false

function DamageState.setCrit(on)
	crit = on
end

function DamageState.isCrit()
	return crit
end

-- Monster knockback queue. Damage.lua appends one entry per pushing hit;
-- the classes/monster-push scheduler task decays them every frame. Entries
-- are never removed once spent -- that is legacy behaviour, see NOTES.md.
local pushes = {}

function DamageState.addPush(entry)
	pushes[#pushes + 1] = entry
end

function DamageState.getPushes()
	return pushes
end
