local ItemLevel = {}
MawCore.ItemLevel = ItemLevel

-- item levels one point of bonus power (the MaxCharges field) is worth
ItemLevel.PerPower = 5

ItemLevel.POWER_HARD_CAP = 255

function ItemLevel.MaxPower()
	return ItemLevel.POWER_HARD_CAP
end

function ItemLevel.Max()
	return ItemLevel.MaxPower()*ItemLevel.PerPower
end

-- the bonus power a drop needs in order to read back as a given level
function ItemLevel.PowerFor(level)
	return math.floor(math.max(level, 0)/ItemLevel.PerPower)
end

ItemLevel.Tiers = 6
ItemLevel.ExpectedTier = (1 + ItemLevel.Tiers)/2	--the tier the damage model assumes

local ladder

local function buildLadder()
	ladder = {}
	local txt = Game.ItemsTxt
	local i = 0
	while i <= txt.High do
		local name = txt[i].NotIdentifiedName
		local last = i
		while last < txt.High and txt[last + 1].NotIdentifiedName == name do
			last = last + 1
		end
		local span = last - i
		for k = i, last do
			--a type with no siblings has no position to read: assume average
			ladder[k] = span > 0 and 1 + (k - i)/span*(ItemLevel.Tiers - 1) or ItemLevel.ExpectedTier
		end
		i = last + 1
	end
end

function ItemLevel.LadderTier(itemId)
	if not ladder then
		buildLadder()
	end
	return ladder[itemId]
end

ItemLevel.PerTier = 3	--extra levels to wear, per tier above the first

function ItemLevel.TierLevels(itemId)
	local tier = ItemLevel.LadderTier(itemId) or ItemLevel.ExpectedTier
	return (math.min(math.max(tier, 1), ItemLevel.Tiers) - 1)*ItemLevel.PerTier
end

function ItemLevel.OfItem(it)
	return it.MaxCharges*ItemLevel.PerPower
end

local FALLBACK_PARTY_SHARE = 7/8

ItemLevel.GUARD_MARGIN = 10

function ItemLevel.WearLevel(dropLevel)
	local margin = ItemLevel.GUARD_MARGIN + (dropLevel * 0.09)
	return dropLevel - margin
end

function ItemLevel.ForDrop(monsterLevel, partyLevel, mapLevel)
	if monsterLevel then
		return monsterLevel
	end
	return partyLevel*FALLBACK_PARTY_SHARE + mapLevel*(1 - FALLBACK_PARTY_SHARE)
end

return ItemLevel
