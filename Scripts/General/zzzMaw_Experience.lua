----------------------------------------------------
--Level-up experience curve
----------------------------------------------------
--The engine carries its own copy of the curve, and it happens to be identical to calcExp
--(zzMaw-Monsters): experience needed to reach level L is 500*L*(L-1). Everything in the mod
--that turns experience into a level -- bolster, party level, item level -- reads calcExp /
--calcLevel, so the engine copy has to stay in step with it. These hooks make the engine ask
--calcExp instead of computing its own, leaving one place to edit the curve.
--
--Two engine sites hold the formula:
--  0x4B30EF  fastcall(ecx = current level) -> experience needed for the next level.
--            Used by the trainer dialog text, the "can train" check and the level-up action.
--  0x48CD4D  thiscall(ecx = player) -> bool, the same formula inlined. Drives the portrait
--            "you can level up" indicator, so it has to move with the other one or the
--            indicator lights up while the trainer refuses.
--
--Ceiling: two of the call sites sign-extend the returned value with CDQ before comparing it
--against the 64-bit Experience field, so anything from 0x80000000 up reads as negative and
--makes every level free. The requirement is clamped below that.
local EXP_REQUIREMENT_CAP = 0x7FFFFFFF

local function expForNextLevel(level)
	if not level or level < 1 then
		return 0
	end
	local need = calcExp(level + 1)
	if not need or need ~= need or need < 0 then
		return 0
	end
	return math.min(math.floor(need), EXP_REQUIREMENT_CAP)
end

mem.hookfunction(0x4B30EF, 1, 0, function(d, def, level)
	return expForNextLevel(level)
end, 6)

mem.hookfunction(0x48CD4D, 1, 0, function(d, def, playerPtr)
	local ok, _, pl = pcall(internal.GetPlayer, playerPtr)
	if not ok or not pl then
		return def(playerPtr)
	end
	return pl.Experience >= expForNextLevel(pl.LevelBase) and 1 or 0
end, 14)

function EventExperience(value, player)
	if value <= 0 or not vars.MMLVL then
		return value
	end
	local partyLevel = getPartyLevel()
	if vars.madnessMode then
		partyLevel = getTotalLevel()
	end
	local total = value*(1+partyLevel/100) + 500*partyLevel
	addBolsterExp(total/5)
	return total
end

mem.hookfunction(0x4485EC, 1, 2, function(d, def, playerPtr, varNum, value)
	if varNum == 0x0D then
		local ok, _, pl = pcall(internal.GetPlayer, playerPtr)
		local newValue = EventExperience(value, ok and pl or nil)
		if type(newValue) == "number" and newValue == newValue then
			value = math.max(0, math.min(math.floor(newValue), 0x7FFFFFFF))
		end
	end
	return def(playerPtr, varNum, value)
end, 6)
