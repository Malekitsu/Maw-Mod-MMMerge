local ORACLES = {[314] = 4, [413] = 4, [794] = 0}

local TIERS = {100, 140, 170, 200}
for level = 220, 500, 20 do
	TIERS[#TIERS + 1] = level
end

local TEXT_TOO_LOW = "The rifts between worlds open only for those who have walked far enough. Return to me when one of you has reached level %d."
local TEXT_GIVE = "I have looked beyond the veil and found a place the other side has rewritten. Take this map: it will open %s anew, filled with creatures from another dimension (Map Level %d). Clear it, then return to me."
local TEXT_NOT_CLEARED = "The rift in %s still stands. Clear it, then return to me."
local TEXT_REWARD = "The rift in %s is sealed. Accept this reward: %d gold."
local TEXT_ALL_DONE = "You have sealed every rift I could find. There is nothing more I can show you."

local function highestLevel()
	local best = 0
	for i = 0, Party.High do
		best = math.max(best, Party[i].LevelBase)
	end
	return best
end

local function rollQuestMap(tier, level)
	if not vars.seed then
		vars.seed = os.time()
	end
	math.randomseed((vars.seed + tier*7919) % 2147483647)
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
	m.MaxCharges = (level - 20)/10
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
	local q = vars.dimensionalMapsQuest or {Tier = 1}
	vars.dimensionalMapsQuest = q
	local level = TIERS[q.Tier]
	if not level then
		Message(TEXT_ALL_DONE)
		return
	end
	local m = q.Map
	if not m then
		if highestLevel() < level then
			Message(string.format(TEXT_TOO_LOW, level))
			return
		end
		m = rollQuestMap(q.Tier, level)
		q.Map = m
		giveMap(m)
		Message(string.format(TEXT_GIVE, Game.MapStats[m.BonusStrength].Name, m.Level))
		return
	end
	local name = Game.MapStats[m.BonusStrength].Name
	if not q.Cleared then
		Message(string.format(TEXT_NOT_CLEARED, name))
		return
	end
	local reward = m.Level*1000
	AddGoldExp(reward, reward)
	Message(string.format(TEXT_REWARD, name, reward, m.Level))
	q.Tier = q.Tier + 1
	q.Map = nil
	q.Cleared = nil
end

function events.LeaveMap()
	local q = vars.dimensionalMapsQuest
	local m = q and q.Map
	local affixes = mapvars.mapAffixes
	if not m or q.Cleared or not mapvars.completed or not affixes then
		return
	end
	if Map.MapStatsIndex == m.BonusStrength and affixes.Power == m.MaxCharges and affixes[1] == m.BonusExpireTime then
		q.Cleared = true
	end
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
