local ItemLevel = {}
MawCore.ItemLevel = ItemLevel

ItemLevel.PerCharge = 5

local maxByDifficulty = {
	[1] = 350,	--bolster 40
	[2] = 350,	--bolster 70
	[3] = 350,	--bolster 100, baseline
	[4] = 350,	--bolster 150
	[5] = 350,	--bolster 200
	[6] = 350,	--bolster 300
	[7] = 500,	--doom
	[8] = 700,	--road to insanity
	[9] = 1000,	--beyond madness
}

function ItemLevel.Max()
	return maxByDifficulty[GetDifficulty()] or maxByDifficulty[3]
end

function ItemLevel.MaxCharges()
	return math.floor(ItemLevel.Max()/ItemLevel.PerCharge)
end

-- the charges a drop needs in order to read back as a given level
function ItemLevel.ChargesFor(level)
	return math.floor(math.max(level, 0)/ItemLevel.PerCharge)
end

function ItemLevel.OfItem(it)
	local txt = it:T()
	local tot = 0
	local lvl = 0
	for i = 1, 6 do
		tot = tot + txt.ChanceByLevel[i]
		lvl = lvl + txt.ChanceByLevel[i]*i
	end
	if tot == 0 then
		return it.MaxCharges*ItemLevel.PerCharge
	end
	return round(lvl/tot*6 - 5) + it.MaxCharges*ItemLevel.PerCharge
end

local FALLBACK_PARTY_SHARE = 7/8

local GUARD_PERCENT = 1.1
local GUARD_MARGIN_MONSTER = 40
local GUARD_MARGIN_CHEST = 20

local function progressionGuard(partyLevel, margin)
	return math.max(partyLevel*GUARD_PERCENT, partyLevel + margin)
end

function ItemLevel.ForDrop(monsterLevel, partyLevel, mapLevel)
	if monsterLevel then
		return math.min(monsterLevel, progressionGuard(partyLevel, GUARD_MARGIN_MONSTER))
	end
	local level = partyLevel*FALLBACK_PARTY_SHARE + mapLevel*(1 - FALLBACK_PARTY_SHARE)
	return math.min(level, progressionGuard(partyLevel, GUARD_MARGIN_CHEST))
end

return ItemLevel
