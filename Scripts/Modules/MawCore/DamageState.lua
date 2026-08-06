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
