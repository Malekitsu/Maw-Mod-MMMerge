local ORACLES = {[314] = 4, [413] = 4, [794] = 0}

local FIRST_TIER = 80
local UNLOCK_TIER = 500
local FIRST_STEP = 30
local LAST_STEP = 10

local LEGACY_TIERS = {100, 140, 170, 200}
for level = 220, 500, 20 do
	LEGACY_TIERS[#LEGACY_TIERS + 1] = level
end

local function nextTier(level)
	local tier, step = FIRST_TIER, FIRST_STEP
	while tier <= level do
		tier = tier + step
		step = math.max(step - 1, LAST_STEP)
	end
	return tier
end

local function migrate(q)
	if q.Tier then
		q.TierLevel = LEGACY_TIERS[q.Tier] or nextTier(UNLOCK_TIER)
		q.LegacyStamp = q.Map and q.Tier or nil
		q.Tier = nil
	end
	q.TierLevel = q.TierLevel or FIRST_TIER
end

local TEXT_TOO_LOW = "The rifts between worlds open only for those who have walked far enough. Return to me when one of you has reached level %d."
local TEXT_GIVE = "I have looked beyond the veil and found a place the other side has rewritten. Take this map: it will open %s anew, filled with creatures from another dimension (Map Level %d). Clear it, then return to me."
local TEXT_NOT_CLEARED = "The rift I showed you still stands. Clear it, then return to me."
local TEXT_REWARD = "The rift in %s is sealed. Accept this reward: %d gold."

local function highestLevel()
	local best = 0
	for i = 0, Party.High do
		best = math.max(best, Party[i].LevelBase)
	end
	return best
end

local function rollQuestMap(level)
	if not vars.seed then
		vars.seed = os.time()
	end
	math.randomseed((vars.seed + level*7919) % 2147483647)
	local pool = getDimensionMapPool()
	if #pool == 0 then
		pool = mapDungeons
	end
	assignedAffixes = {}
	local m = {}
	m.BonusStrength = pool[math.random(1, #pool)]
	m.Bonus2 = getUniqueAffix()
	m.Charges = getUniqueAffix()
	m.Charges = m.Charges + getUniqueAffix()*1000
	m.BonusExpireTime = getUniqueAffix()
	local roll = math.random()
	m.Bonus = roll <= 0.1 and 4 or roll < 0.3 and 3 or 2
	math.randomseed(os.time())
	m.MaxCharges = math.min(math.floor((level - 20)/10), MawCore.ItemLevel.MaxPower())
	m.Level = getDimensionMapLevel(m.BonusStrength, m.MaxCharges)
	return m
end

local function giveMap(m)
	evt.Add("Items", 290)
	local it = Mouse.Item
	it.BonusStrength = m.BonusStrength
	it.Bonus = m.Bonus
	it.Bonus2 = m.Bonus2
	it.Charges = m.Charges
	it.BonusExpireTime = m.BonusExpireTime
	it.MaxCharges = m.MaxCharges
	if vars.madnessMode then
		vars.ownedMaps = (vars.ownedMaps or 0) + 1
	end
end

local function dimensionalMapsTopic()
	local q = vars.dimensionalMapsQuest or {}
	vars.dimensionalMapsQuest = q
	migrate(q)
	local level = q.TierLevel
	local m = q.Map
	if not m then
		if highestLevel() < level then
			Message(string.format(TEXT_TOO_LOW, level))
			return
		end
		m = rollQuestMap(level)
		q.Map = m
		giveMap(m)
		Message(string.format(TEXT_GIVE, Game.MapStats[m.BonusStrength].Name, m.Level))
		return
	end
	if not q.Cleared then
		Message(TEXT_NOT_CLEARED)
		return
	end
	local reward = q.Level*1000
	AddGoldExp(reward, reward)
	Message(string.format(TEXT_REWARD, q.MapName, reward))
	if level >= UNLOCK_TIER then
		q.Done = true
	end
	q.TierLevel = nextTier(level)
	q.Map = nil
	q.Cleared = nil
	q.Level = nil
	q.MapName = nil
	q.LegacyStamp = nil
end

function events.LoadMap()
	local q = vars.dimensionalMapsQuest
	if not q then
		return
	end
	migrate(q)
	if q.Map and not q.Cleared and mapvars.mapAffixes and not mapvars.completed then
		mapvars.dimensionalMapsTier = q.TierLevel
	end
end

function events.LeaveMap()
	local q = vars.dimensionalMapsQuest
	if not q then
		return
	end
	migrate(q)
	local affixes = mapvars.mapAffixes
	local stamp = mapvars.dimensionalMapsTier
	if not q.Map or q.Cleared or not mapvars.completed or not affixes then
		return
	end
	if stamp ~= q.TierLevel and (not q.LegacyStamp or stamp ~= q.LegacyStamp) then
		return
	end
	q.Cleared = true
	q.Level = getDimensionMapLevel(Map.MapStatsIndex, affixes.Power)
	q.MapName = Game.MapStats[Map.MapStatsIndex].Name
end

for npc, slot in pairs(ORACLES) do
	Quest{
		"DimensionalMaps" .. npc,
		BaseName = "DimensionalMaps",
		NPC = npc,
		Slot = slot,
		Ungive = dimensionalMapsTopic,
		Texts = {Topic = "Dimensional Maps"},
	}
end
