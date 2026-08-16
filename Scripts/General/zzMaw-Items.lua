function events.GenerateItem(t)
	--get party average level
	Handled = true
	--[[calculate party experience
	if Map.MapStatsIndex==0 then return end
	local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
	if currentWorld==4 then
		return
	end
	local partyLevelItemGen=vars.MMLVL[currentWorld]

	--nerf items in shops is strong if low level
	if Game.freeProgression then
		if (Game.HouseScreen==2 or Game.HouseScreen==95) then
			if partyLevelItemGen<(t.Strength-3)*18 and t.Strength<7 then
				t.Strength=t.Strength-1
			end
			if (t.Strength-2)*18>partyLevelItemGen and t.Strength>2 and t.Strength<7 then
				roll=math.random((t.Strength-3)*18,(t.Strength-2)*18)
				if roll>partyLevelItemGen then
					t.Strength=t.Strength-1
				end
			end
		end
	end
	]]
	if t.Strength==7 then
		t.Strength=6
	end
end

-- Function to get and advance monster type seed (global for use across scripts)
function getMonsterSeed(monsterId)
	-- Initialize global seed if needed
	if not vars.seed then
		vars.seed = os.time()
	end
	
	-- Initialize monster counters if needed
	vars.monsterCounters = vars.monsterCounters or {}
	vars.monsterSeeds = vars.monsterSeeds or {}
	
	-- Initialize this monster type if first encounter
	if not vars.monsterCounters[monsterId] then
		vars.monsterCounters[monsterId] = 0
		-- Create initial seed for this monster type based on global seed + monster ID
		vars.monsterSeeds[monsterId] = vars.seed + (monsterId * 1009)
	end
	
	-- Get current seed for this monster type
	local currentSeed = vars.monsterSeeds[monsterId]
	
	-- Advance counter and generate next seed deterministically
	vars.monsterCounters[monsterId] = vars.monsterCounters[monsterId] + 1
	
	-- Generate next seed using linear congruential generator formula
	-- Using constants from Numerical Recipes: a=1664525, c=1013904223, m=2^32
	vars.monsterSeeds[monsterId] = (vars.monsterSeeds[monsterId] * 1664525 + 1013904223) % 4294967296
	
	return currentSeed
end

-- Function to get boss loot seed based on global seed, map, and boss spawn count
local function getBossLootSeed(mon)
	-- Initialize global seed if needed
	if not vars.seed then
		vars.seed = os.time()
	end
	-- Create deterministic map hash
	local mapName = Map.Name or "default"
	local mapHash = 0
	for i = 1, #mapName do
		mapHash = mapHash + string.byte(mapName, i) * i * 31
	end
	
	-- Add map index if available
	if Map.MapStatsIndex then
		mapHash = mapHash + Map.MapStatsIndex * 97
	end
	local index=mon:GetIndex()
	mapvars.BossSeed = mapvars.BossSeed or {}
	mapvars.BossSeed[index] = mapvars.BossSeed[index] or 0
	-- Create boss seed based on: global seed + map hash + boss spawn count + monster ID
	local bossLootSeed = vars.seed + mapHash + (index * 1337) + (mon.Id * 2003) + mapvars.BossSeed[index]
	mapvars.BossSeed[index] = mapvars.BossSeed[index]+1
	
	-- Ensure seed is positive and within reasonable range
	bossLootSeed = math.abs(bossLootSeed) % 2147483647
	
	return bossLootSeed
end

--the three base equipment id bands: MM8 1-151, MM6 803-936, MM7 1603-1736.
--Artifacts and quest items sit outside them; 0 is an empty slot, not an item.
function IsBaseItemId(num)
	return (num >= 1 and num <= 151) or (num >= 803 and num <= 936) or (num >= 1603 and num <= 1736)
end

--artifact id bands, one per game. ancientWeapons sit outside these, inside
--the base bands, so tests that want them too must add them explicitly.
function IsArtifactId(num)
	return (num >= 500 and num <= 543) or (num >= 1302 and num <= 1354) or (num >= 2020 and num <= 2049)
end

--base equipment the loot/enchant system may roll on: ancientWeapons are
--artifacts that happen to fall inside the bands, so they are excluded.
--Crafting deliberately does NOT use this -- the alchemy and potion gates
--test IsBaseItemId, so ancient weapons stay craftable by hand while the
--loot roller never touches them.
function IsEnchantableItem(it)
	return IsBaseItemId(it.Number) and not table.find(ancientWeapons, it.Number)
end

------------------------------------------------------------------------
-- LootContext -- what a corpse hands to the item generator.
--
-- One producer (PickCorpse), one consumer (ItemGenerated), so this state
-- belongs to this file and not to a shared type. take() empties it: one corpse
-- feeds one drop, and anything a corpse leaves behind because it rolled
-- nothing dies here instead of leaking into the next chest.
--
-- restore() exists for one reason. A boss drop whose rolled item is not a base
-- item calls Item:Randomize, and Randomize calls 0x453ECC -- the exact engine
-- function the ItemGenerated hook sits on (structs.Item.Randomize). One drop
-- therefore runs the handler TWICE and the INNER call is the one that
-- generates, so the outer call hands the context back before recursing.
------------------------------------------------------------------------
local lootContext = {}
local LootContext = {}

--the corpse's contribution to the next drop
function LootContext.set(t)
	lootContext = {
		monsterLevel = t.monsterLevel,
		multiplier = t.multiplier,
		boss = t.boss,
		omnipotent = t.omnipotent,
	}
end

--chest artifacts are re-rolled through the boss path (AfterLoadMap)
function LootContext.markBoss()
	lootContext.boss = true
end

function LootContext.take()
	local c = lootContext
	lootContext = {}
	return {
		monsterLevel = c.monsterLevel,
		multiplier = c.multiplier or 1,
		boss = c.boss == true,
		omnipotent = c.omnipotent == true,
	}
end

function LootContext.restore(drop)
	lootContext = drop
end

function events.PickCorpse(t)
	--if Game.BolsterAmount~=300 then return end
	local monster = Map.Monsters[t.MonsterIndex]
	if monster then
		-- Check if this is a boss monster (NameId 220-299)
		local isBoss = monster.NameId >= 220 and monster.NameId < 300
		
		-- Apply deterministic seeding first
		if isBoss then
			-- Use boss loot seeding for all modes
			local seed = getBossLootSeed(monster)
			Game.RandSeed = seed
			math.randomseed(seed)
		elseif vars.insanityMode then
			-- Use new deterministic monster-type seeding for insanity mode
			local seed = getMonsterSeed(monster.Id)
			Game.RandSeed = seed
			math.randomseed(seed)
		else
			-- Use old position-based seeding for other modes
			-- Check if seed exists for this monster, if not create one
			if not mapvars.MonsterSeed or not mapvars.MonsterSeed[t.MonsterIndex] then
				-- Initialize mapvars.MonsterSeed if it doesn't exist
				mapvars.MonsterSeed = mapvars.MonsterSeed or {}
				
				-- Create deterministic seed for this monster
				local mapName = Map.Name or "default"
				local mapSeed = vars.seed
				for i = 1, #mapName do
					mapSeed = mapSeed + string.byte(mapName, i) * i * 13
				end
				
				-- Add map index if available
				if Map.MapStatsIndex then
					mapSeed = mapSeed + Map.MapStatsIndex * 47
				end
				
				-- Generate seed for this specific monster
				local monsterSeed = mapSeed + t.MonsterIndex * 97
				mapvars.MonsterSeed[t.MonsterIndex] = monsterSeed
			end
			
			Game.RandSeed = mapvars.MonsterSeed[t.MonsterIndex]
			math.randomseed(mapvars.MonsterSeed[t.MonsterIndex])
		end
		
		-- Now perform loot calculations (merged from zzMaw-Monsters.lua)
		local mon = monster
		
		-- Calculate gold
		local lvl = BLevel[mon.Id] or mon.Level
		local gold = mon.TreasureDiceCount * (mon.TreasureDiceSides + 1) / 2
		local newGold = (bolsterLevel2 + lvl) * 7.5
		local tier = 2
		
		if mon.Id % 3 == 1 then
			newGold = newGold / 2
			tier = 1
		elseif mon.Id % 3 == 0 then
			newGold = newGold * 2
			tier = 3
		end
		
		if gold > 0 and newGold > gold then
			local goldMult = (bolsterLevel2 + lvl)^1.5 / (lvl)^1.5
			mon.TreasureDiceCount = math.min(newGold^0.5, 255)
			mon.TreasureDiceSides = math.min(newGold^0.5, 255)
		end
		
		-- Calculate loot chances and quality
		if mon.Item == 0 and (mon.NameId < 220 or mon.NameId > 300) then
			local name = Game.MapStats[Map.MapStatsIndex].Name
			local lvlID = mon.Id
			if tier == 1 then
				lvlID = mon.Id + 1
			elseif tier == 3 then
				lvlID = mon.Id - 1
			end
			local lvl = math.max(basetable[lvlID].Level, mapLevels[name].Low)
			local originalValue = math.min(mon.TreasureItemPercent, 50)
			mon.TreasureItemPercent = math.ceil(mon.Level^0.5 * (1 + tier) * 0.5 + originalValue * 0.3)
			
			if vars.Mode == 2 then
				mon.TreasureItemPercent = round(mon.TreasureItemPercent * 0.5)
			elseif Game.BolsterAmount == 300 then
				mon.TreasureItemPercent = round(mon.TreasureItemPercent * 0.75)
			end
			
			local itemTier = (lvl + 10 * tier) / 20
			if itemTier % 20 / 20 > math.random() then
				itemTier = itemTier + 1
			end
			itemTier = math.floor(itemTier)
			mon.TreasureItemLevel = math.max(math.min(itemTier, 6), 1)
			if itemTier <= 0 then
				mon.TreasureItemPercent = round(mon.TreasureItemPercent * 2^(itemTier - 1))
			end
			if math.random() < 0.7 then
				mon.TreasureItemType = 0
			end
		end
		
		local densityMultiplier=GetDensityMultiplier(mon.Id)
		local dropIsBoss, dropIsOmnipotent=false, false
		-- Special handling for bosses and resurrected
		if mon.NameId > 300 then
			mon.TreasureItemPercent = round(mon.TreasureItemPercent / 4*densityMultiplier^0.5)
			mon.TreasureDiceSides = math.max(round(mon.TreasureDiceSides / 4*densityMultiplier^0.5), 1)
		elseif mon.NameId > 220 or mon.NameId == 160 then
			mon.TreasureItemPercent = 100
			local skill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
			if skill == "Broodling" then
				if mon.Id % 3 == 0 then
					mon.TreasureItemPercent = 30
				elseif mon.Id % 3 == 2 then
					mon.TreasureItemPercent = 10
				elseif mon.Id % 3 == 1 then
					mon.TreasureItemPercent = 4
				end
			end
			
			-- Item tier for bosses
			local name = Game.MapStats[Map.MapStatsIndex].Name
			local lvl = math.max(basetable[mon.Id].Level, mapLevels[name].Low)
			local id = mon:GetIndex()
			if id and mapvars.uniqueMonsterLevel and mapvars.uniqueMonsterLevel[id] then
				lvl = mapvars.uniqueMonsterLevel[id]
			end
			local itemTier = lvl / 20 + 2
			if itemTier % 15 / 15 > math.random() then
				itemTier = itemTier + 1
			end
			mon.TreasureItemLevel = math.max(math.min(itemTier, 6), 2)
			dropIsBoss = true
			local monsterSkill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
			if monsterSkill == "Omnipotent" then
				dropIsOmnipotent = true
			end
		end
		
		-- Loot filter code
		goldBeforeLoot = Party.Gold
		lootFromMonster = true
		LootContext.set{
			monsterLevel=getMonsterLevel(mon),
			multiplier=densityMultiplier,
			boss=dropIsBoss,
			omnipotent=dropIsOmnipotent,
		}
		local pickCorpseDefault=t.CallDefault
		t.CallDefault=function()
			local allowed=t.Allow
			pickCorpseDefault()
			if allowed then
				mon.TreasureGenerated=false
				mon.AIState=const.AIState.Removed
			end
		end
		-- Handle seed state after loot calculations
		RunNextTick(function()
			lootFromMonster = false
			-- Update seed for non-insanity mode if needed
			if not vars.insanityMode and not isBoss then
				mapvars.MonsterSeed[t.MonsterIndex] = Game.RandSeed
			end
		end)
	end
end

function events.CastTelepathy(t)
	--if Game.BolsterAmount~=300 then return end
	local monster = Map.Monsters[t.MonsterIndex]
	if monster then
		-- Check if this is a boss monster (NameId 220-299)
		local isBoss = monster.NameId >= 220 and monster.NameId < 300
		
		if isBoss then
			-- Use boss loot seeding for all modes
			local seed = getBossLootSeed(monster)
			Game.RandSeed = seed
			RunNextTick(function()
			end)
		elseif vars.insanityMode then
			-- Use new deterministic monster-type seeding for insanity mode
			local seed = getMonsterSeed(monster.Id)
			Game.RandSeed = seed
			RunNextTick(function()
			end)
		else
			-- Use old position-based seeding for other modes
			Game.RandSeed = mapvars.MonsterSeed[t.MonsterIndex]
			RunNextTick(function()
				mapvars.MonsterSeed[t.MonsterIndex] = Game.RandSeed
			end)
		end
	end
end
function events.LoadMap()
	--if Game.BolsterAmount~=300 then return end
	if not vars.insanityMode then
		-- Use old seeding system for non-insanity modes
		if not mapvars.MonsterSeed then
			-- Generate or use existing global seed
			if not vars.seed then
				vars.seed = os.time()
			end
			
			-- Create map-specific seed variation
			local mapName = Map.Name or "default"
			local mapSeed = vars.seed
			for i = 1, #mapName do
				mapSeed = mapSeed + string.byte(mapName, i) * i * 13
			end
			
			-- Add map index if available
			if Map.MapStatsIndex then
				mapSeed = mapSeed + Map.MapStatsIndex * 47
			end
			
			-- Set the combined seed
			Game.RandSeed = mapSeed
			math.randomseed(mapSeed)
			
			mapvars.MonsterSeed = {}
			for i = 0, Map.Monsters.High do
				local monster = Map.Monsters[i]
				if monster then
					-- Generate enough variation for each monster
					local monsterSeed = Game.RandSeed + i * 97
					Game.RandSeed = monsterSeed
					math.randomseed(monsterSeed)
					
					-- Additional randomization to ensure all combinations possible
					for j = 1, 50 + (i % 20) do
						Game.Rand()
						math.random()
					end
					
					mapvars.MonsterSeed[i] = Game.RandSeed
				end
			end
		end
	end
end
--create tables to calculate special enchant
function events.GameInitialized2()
	Game.ItemsTxt[67].NotIdentifiedName="Mace"
	Game.ItemsTxt[804].NotIdentifiedName="Longsword"
	--calculate totals by enchant type
	totBonus2={}
	for k=0,3 do
		totBonus2[k]={}
		for v=0, 11 do
			totBonus2[k][v]=0
			for i=0, Game.SpcItemsTxt.High do
				lvl=Game.SpcItemsTxt[i].Lvl
				if lvl==k then
					totBonus2[k][v]=totBonus2[k][v]+Game.SpcItemsTxt[i].ChanceForSlot[v]
				end
			end
		end
	end
	
	--calculate total of each item level per item type
	itemStrength={}	
	itemStrength[3]={}
	itemStrength[4]={}
	itemStrength[5]={}
	itemStrength[6]={}
	for v=0, 11 do	
		itemStrength[3][v]=totBonus2[0][v]+totBonus2[1][v]
		itemStrength[4][v]=totBonus2[0][v]+totBonus2[1][v]+totBonus2[2][v]
		itemStrength[5][v]=totBonus2[1][v]+totBonus2[2][v]+totBonus2[3][v]
		itemStrength[6][v]=totBonus2[3][v]
	end
	--list of possible enchants per item level
	enchants={}
	enchants[3]={0,1}
	enchants[4]={0,1,2}
	enchants[5]={1,2,3}
	enchants[6]={3}
end


function encStrUpNormal(tier)
	return math.min(tier*3, 100)
end

function encStrUpAusterity(tier)
	if tier<=30 then
		return tier+2
	end
	return 32+(tier-30)*2
end

encStrUp=encStrUpNormal


local function applyDifficulty(strength)
	return math.ceil(strength*GetDifficultyExtraPower())
end

local PRIMORDIAL_ENCHANT_MULT = 1.25
local function rollEnchantStrength(tier, ancientTier)
	if ancientTier==2 then
		return round(applyDifficulty(encStrUp(tier))*PRIMORDIAL_ENCHANT_MULT)
	elseif ancientTier==1 then
		return round(applyDifficulty(encStrUp(tier))*math.random(20,PRIMORDIAL_ENCHANT_MULT*20)/20)
	elseif ancientTier==3 then
		return round(applyDifficulty(encStrUp(tier))*math.random(16,20)/20)
	end
	return applyDifficulty(round(encStrUp(tier)*math.random(8,20)/20))
end

function GetMaxEnchantStrength(level)
	return round(applyDifficulty(encStrUp(GetTier(level)))*PRIMORDIAL_ENCHANT_MULT)
end

local PRIMORDIAL_CHARGES_MULT = 1.2
local ANCIENT_MIN_CHARGES = 2
local PRIMORDIAL_MIN_CHARGES = 4
local LEGENDARY_CHARGES_MULT = 1.2
local LEGENDARY_CHARGES_BONUS = 10

function GetMaxItemCharges()
	return MawCore.ItemLevel.MaxPower()
end

function GetItemChargesCap(it)
	return MawCore.ItemLevel.MaxPower()
end

local function rollTierCharges(charges, ancientTier)
	local rolled = charges
	if ancientTier==2 then
		rolled = math.max(round(charges*PRIMORDIAL_CHARGES_MULT), charges+PRIMORDIAL_MIN_CHARGES)
	elseif ancientTier==1 then
		rolled = math.max(round(charges*math.random(20,PRIMORDIAL_CHARGES_MULT*20)/20),
			charges+ANCIENT_MIN_CHARGES)
	end
	return math.min(rolled, GetMaxItemCharges())
end

function GetPrimordialCharges(level)
	return rollTierCharges(MawCore.ItemLevel.PowerFor(level), 2)
end

function GetItemDropLevel(it)
	local stored=GetStoredDropLevel(it)
	if stored>0 then
		return stored
	end
	local charges=it.MaxCharges
	if HasLegendaryAffix(it) then
		charges=math.floor(math.max(charges/LEGENDARY_CHARGES_MULT,
			charges-LEGENDARY_CHARGES_BONUS))
	end
	local tier=GetAncientTier(it)
	if tier==2 then
		charges=math.floor(math.min(charges/PRIMORDIAL_CHARGES_MULT,
			charges-PRIMORDIAL_MIN_CHARGES))
	elseif tier==1 then
		--ancient rolled a random 1.0..1.2x: undo the midpoint
		charges=math.floor(math.min(charges/((1+PRIMORDIAL_CHARGES_MULT)/2),
			charges-ANCIENT_MIN_CHARGES))
	end
	return charges*MawCore.ItemLevel.PerPower
end


--Bolster/insanity multiplier: it raises the tier cap AND multiplies every
--rolled enchant strength. Insanity overrides the bolster, as in the generator.
function GetDifficultyExtraPower()
	if vars.insanityMode then
		return 1.2
	elseif vars.Mode==2 then
		return 1.1
	elseif vars.trueNightmare then
		return 1.05
	end
	return 1
end

--The tier a drop can reach beyond what its level alone buys: difficulty, map
--affixes and d42 all still ADD tiers, they just no longer cap anything.
function GetEnchantTierBonus()
	local bonus=math.floor((GetDifficultyExtraPower()-1)*10)
	if mapvars and mapvars.mapAffixes then
		bonus=bonus+math.floor(math.max((mapvars.mapAffixes.Power-30+2)/2,0))
	end
	if Map.Name=="d42.blv" then
		bonus=bonus+20
	end
	return bonus
end

RARITY_UNCOMMON, RARITY_RARE, RARITY_EPIC = 1, 2, 3
RARITY_ANCIENT, RARITY_PRIMORDIAL, RARITY_LEGENDARY, RARITY_CELESTIAL = 4, 5, 6, 7

rarityChance = {
	[RARITY_CELESTIAL]  = 0.001,
	[RARITY_LEGENDARY]  = 0.02,
	[RARITY_PRIMORDIAL] = 0.03,
	[RARITY_ANCIENT]    = 0.12,
}

local rarityDifficultyMult = {
	[1] = 1,	--bolster 40
	[2] = 1,	--bolster 70
	[3] = 1,	--bolster 100, baseline
	[4] = 1.1,	--bolster 150
	[5] = 1.2,	--bolster 200
	[6] = 1.4,	--bolster 300
	[7] = 1.6,	--doom
	[8] = 1.8,	--road to insanity
	[9] = 2,	--beyond madness
}

local rarityPityField = {
	[RARITY_CELESTIAL]  = "celestialPityCounter",
	[RARITY_LEGENDARY]  = "legendaryPityCounter",
	[RARITY_PRIMORDIAL] = "primordialPityCounter",
}

--Which roll rollEnchantStrength should use. These are ids, not a scale: 3 is
--the legendary roll and sits BELOW 1 (ancient) in strength.
function GetRarityEnchantTier(rarity)
	if rarity==RARITY_PRIMORDIAL or rarity==RARITY_CELESTIAL then
		return 2
	elseif rarity==RARITY_ANCIENT then
		return 1
	elseif rarity==RARITY_LEGENDARY then
		return 3
	end
	return 0
end

--lootMultiplier arrives as an argument: the drop context owns it, this is a
--pure function of what it is handed.
function GetRarityMultiplier(pseudoStr, bossLoot, lootMultiplier)
	local tierFactor=enc1Chance[math.min(pseudoStr,#enc1Chance)]/enc1Chance[#enc1Chance]
	local mult=(rarityDifficultyMult[GetDifficulty()] or 1)*tierFactor*(lootMultiplier or 1)^0.5
	if bossLoot then
		mult=mult*5
	end
	if mapvars and mapvars.mapAffixes then
		local nAff=0
		for i=1,4 do
			if mapvars.mapAffixes[i]>0 then
				nAff=nAff+1
			end
		end
		mult=mult*(1+(mapvars.mapAffixes.Power*nAff+nAff*20)/400)
	end
	return mult
end

function RollItemRarity(pseudoStr, bossLoot, noLegendary, lootMultiplier)
	local mult=GetRarityMultiplier(pseudoStr, bossLoot, lootMultiplier)
	local result=RARITY_EPIC
	for rarity=RARITY_CELESTIAL, RARITY_ANCIENT, -1 do
		local base=rarityChance[rarity]
		if noLegendary and rarity>=RARITY_LEGENDARY then
			base=0
		end
		if base>0 then
			local field=rarityPityField[rarity]
			local chance=base
			if field then
				vars[field]=vars[field] or 0
				chance=pity_chance(base, vars[field])
			end
			chance=chance*mult
			if math.random()<chance then
				if field then
					vars[field]=0
				end
				result=rarity
				break
			end
		end
	end
	for rarity, field in pairs(rarityPityField) do
		if rarity>result and not (noLegendary and rarity>=RARITY_LEGENDARY) then
			vars[field]=(vars[field] or 0)+mult
		end
	end
	return result
end

function RollEnchantType(it, exclude)
	local highest=GetItemEquipStat(it)==10 and 16 or 10
	local id
	repeat
		id=math.random(1,highest)
	until id~=exclude
	return id
end

function RollStatFromList(list, exclude)
	if #list<=1 then
		return list[1]
	end
	local id
	repeat
		id=list[math.random(1,#list)]
	until id~=exclude
	return id
end

function GetTier(level)
	return math.floor((level or 0)/16)
end
local function rollMaxCharges(maxCharges)
	return round(maxCharges*math.random(16,20)/20)
end

enc1ChanceNormal={20,30,40,50,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80}
enc2ChanceNormal={20,30,35,40,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60}
spcEncChanceNormal={5,10,15,20,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40}
enc1ChanceAusterity={20,20,21,21,22,22,23,23,24,24,25,25,26,26,27,27,28,28,29,29}
enc2ChanceAusterity={10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,17,18,18,19,19}
spcEncChanceAusterity={40,40,41,41,42,42,43,43,44,44,45,45,46,46,47,47,48,48,49,49}
enc1Chance=enc1ChanceNormal
enc2Chance=enc2ChanceNormal
spcEncChance=spcEncChanceNormal

function events.BeforeLoadMap()
	if vars.AusterityMode then
		encStrUp=encStrUpAusterity
		enc1Chance=enc1ChanceAusterity
		enc2Chance=enc2ChanceAusterity
		spcEncChance=spcEncChanceAusterity
	else
		encStrUp=encStrUpNormal
		enc1Chance=enc1ChanceNormal
		enc2Chance=enc2ChanceNormal
		spcEncChance=spcEncChanceNormal
	end
end

primordialWeapEnchants={39,40,41,46}
primordialArmorEnchants={1,2,80}

local goldId={187,188,189,197,198,199,999,1000,1001,1799,1800,1801}
function events.AfterLoadMap()
	Sleep(1)
	if not mapvars.chestGoldFix then
		local name=Game.MapStats[Map.MapStatsIndex].Name
		local mapLevel=(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3
		if vars.madnessMode and madnessMapLevels[name] then
			bolsterLevel=madnessMapLevels[name]
		end	
		if mapvars.mapAffixes then
			bolsterLevel=mapvars.mapAffixes.Power*10+20
		end
		for i=0,Map.Chests.High do
			for k=1,Map.Chests[i].Items.High do
				local it=Map.Chests[i].Items[k]
				if table.find(goldId,it.Number) then
					local goldType=(table.find(goldId,it.Number)-1)%3+1
					if goldType==3 then
						goldType=4
					end
					it.Bonus2=10*(mapLevel+bolsterLevel)*goldType*(0.66+math.random()*0.66)
				end
			end
		end
		mapvars.chestGoldFix=true
	end
	
	if not mapvars.lootFiltered then
		for i=0,Map.Chests.High do
			for k=1,Map.Chests[i].Items.High do
				local it=Map.Chests[i].Items[k]
				if IsBaseItemId(it.Number) then
					local itemPower=1
					if it.Bonus>0 then
						itemPower=itemPower+1
					end
					if it.Bonus2>0 then
						itemPower=itemPower+1
					end
					if HasEnc2(it) then
						itemPower=itemPower+1
					end
					if IsCelestialItem(it) then
						itemPower=8
					elseif HasLegendaryAffix(it) then
						itemPower=7
					elseif IsPrimordialItem(it) then
						itemPower=6
					elseif IsAncientItem(it) then
						itemPower=5
					end
					
					local filter=vars.MAWSETTINGS.lootFilter
					
					local tierList={"Common", "Uncom.", "Rare", "Epic", "Ancient", "Primordial", "Legendary", [0]="OFF"}
					local filterPower=table.find(tierList, filter)
					local itemID=it.Number
					if itemPower<=filterPower then
						local goldId={1799,999,187,1800,1000,188,1801,1001,189}
						local itemGold=getItemValue(it, true)
						it.Number=goldId[math.min((itemPower)*2-math.random(0,1),9)]
						it.Bonus2=itemGold
					end
				end
			end
		end
		mapvars.lootFiltered = true
	end
end

function events.ItemGenerated(t)
	if Game.CurrentScreen==16 or Game.CurrentScreen==21 then return end
	--one corpse feeds one drop: consume the whole context here
	local drop=LootContext.take()
	--boss items forced
	if drop.boss then
		if not IsEnchantableItem(t.Item) then
			--Randomize re-enters this handler; the inner call is the real
			--consumer, so give the context back to it
			LootContext.restore(drop)
			t.Item:Randomize(t.Strength, 0)
			return
		end
	end
	if vars then
		if vars.SeedList==nil then
			vars.SeedList={}
			for i=0,2500 do
				vars.SeedList[i]=i*1000000000+math.random(0,999999999)
			end
		end
		math.randomseed(vars.SeedList[t.Item.Number])
		vars.SeedList[t.Item.Number]=t.Item.Number*1000000000+math.random(0,999999999)
	end

	if Map.MapStatsIndex==0 then
		return 
	end
	
	if t.Strength==7 then
		return
	end

	-- Build combined artifact list and initialize pity counters
	if Game.HouseScreen~=2 and Game.HouseScreen~=95 and IsEnchantableItem(t.Item) then
		local artifactChance = 0.005 * drop.multiplier
		vars.artifactRollPity = vars.artifactRollPity or 0
		local chance = pity_chance(artifactChance, vars.artifactRollPity)
		if math.random() < chance then
			vars.artifactRollPity = 0
			local allArtifacts = {}
			for _, v in ipairs(mawArtifacts) do 
				allArtifacts[#allArtifacts + 1] = v 
			end
			vars.artPity = vars.artPity or {}
			for i = 1, #allArtifacts do
				vars.artPity[i] = vars.artPity[i] or 0
			end
			local rolledIndex = get_affix(vars.artPity)
			vars.artPity[rolledIndex] = vars.artPity[rolledIndex] + 1
			t.Item.Number = allArtifacts[rolledIndex]
			local level = round(getTotalLevel())
			t.Item.BonusExpireTime = math.min(math.max(level,1), 1000)
			t.Item.BonusStrength=0
			t.Item.Bonus2=0
			t.Item.Bonus=0
			t.Item.Charges=0
		else
			vars.artifactRollPity = vars.artifactRollPity + drop.multiplier
		end
	end	

	-- spawn crafting materials in misc shops, substituting recipes
	if (Game.HouseScreen == 2 or Game.HouseScreen == 95) and not vars.AusterityMode then
		local id = Game:GetCurrentHouse()
		local stat = t.Item:T().EquipStat

		if (stat >= 12 and math.random() < 0.3 or stat == 19) and id <= 110 then
			local lootTable = {
				{id = 1061, weight = 7},
				{id = 1062, weight = 7},
				{id = 1063, weight = 15},
				{id = 1064, weight = 2},
				{id = 1065, weight = 5},
				{id = 1066, weight = 7},
				{id = 1067, weight = 3},
			}

			local gold = Party.Gold
			local successChance = math.min((gold / 20000000)^0.7, 1)
			if math.random() < successChance then
				-- SUCCESS: roll from loot table

				-- reset item
				t.Item.Bonus = 0
				t.Item.BonusStrength = 0
				t.Item.Bonus2 = 0
				t.Item.Charges = 0
				t.Item.MaxCharges = 0

				local totalWeight = 0
				for i = 1, #lootTable do
					totalWeight = totalWeight + lootTable[i].weight
				end

				local roll = math.random() * totalWeight
				local cumulative = 0

				for i = 1, #lootTable do
					cumulative = cumulative + lootTable[i].weight
					if roll <= cumulative then
						t.Item.Number = lootTable[i].id
						return
					end
				end
			end

			-- fallback: reagent -- crafting gems no longer come from shops
			--local partyLevel = getPartyLevel(4)
			--local reagentLevel = math.floor(partyLevel / 25)
			--
			--local r = math.random()
			--if r < 0.05 then
			--	reagentLevel = reagentLevel + 2
			--elseif r < 0.30 then
			--	reagentLevel = reagentLevel + 1
			--end
			--
			--t.Item.Number = 1041 + math.min(reagentLevel, 19)
			return
		end
	end
	
	if IsEnchantableItem(t.Item) or reagentList[t.Item.Number] then
		t.Handled=true
		local it=t.Item
		--reset enchants
		it.BonusExpireTime=0
		it.Bonus=0
		it.Bonus2=0
		it.BonusStrength=0
		it.Charges=0
		it.MaxCharges=0
		--calculate party level
		local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
		local currentLevel=vars.MMLVL[currentWorld]
 		local partyLevel=getPartyLevel()
		
		vars.mapResetCount=vars.mapResetCount or {}
		vars.mapResetCount[Map.Name]=vars.mapResetCount[Map.Name] or 0
		local bonus=vars.mapResetCount[Map.Name]*20
		currentLevel=currentLevel+bonus
		partyLevel=partyLevel+bonus
		
		if Map.Name=="d42.blv" then
			currentLevel=monTbl[math.min((vars.highestArenaWave+1)*3,#monTbl)].Level*6
			partyLevel=monTbl[math.min((vars.highestArenaWave+1)*3,#monTbl)].Level*6/1.5
			if (vars.highestArenaWave+1)*3>#monTbl then
				local diff=(vars.highestArenaWave+1)*3-#monTbl
				local extraBoost=diff*3.5
				currentLevel=currentLevel+extraBoost
				partyLevel=partyLevel+extraBoost/1.5
			end
		end
		
		local name=Game.MapStats[Map.MapStatsIndex].Name
		mapLevel=mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High
		if Map.Name~="d42.blv" then
			if not Game.freeProgression then
				partyLevel=getPartyLevel(4)*0.75
				if mapLevels[name] and mapLevels[name].Low~=0 and Game.HouseScreen~=2 and Game.HouseScreen~=95 then
					partyLevel=mapLevel
					mapLevel=0
				end
			elseif mapLevels[name] and mapLevels[name].Low~=0 then
				if Game.HouseScreen~=2 and Game.HouseScreen~=95 then
					partyLevel=mapLevel
					mapLevel=0
				else
					partyLevel=mapLevel*0.2+partyLevel
				end
			else
				partyLevel=partyLevel+math.min(currentLevel/2,54)
				mapLevel=0
			end
		end
		if vars.madnessMode then
			if madnessMapLevels[name] then
				partyLevel=madnessMapLevels[name]
			else
				partyLevel=((mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3)^1.5
			end
			mapLevel=0
		end
		if mapvars.mapAffixes then
			currentLevel=mapvars.mapAffixes.Power*10+20
			partyLevel=mapvars.mapAffixes.Power*10+20
		end
		--modify reagents
		local itmod=3
		if vars.AusterityMode then
			itmod=8
		end
		if reagentList[it.Number] then
			local bonus=math.min(partyLevel, getTotalLevel())
			it.Bonus=round(bonus/itmod)
			return
		end
		
		--difficulty settings
		difficultyExtraPower=GetDifficultyExtraPower()
		--nerf shops if no exp in current world
		--[[
		if (Game.HouseScreen==2 or Game.HouseScreen==95) and Game.freeProgression then 
			partyLevel=round(partyLevel*(math.min(partyLevel/160 + currentLevel/80,1)))
		end
		]]
		--ADD MAX CHARGES BASED ON PARTY LEVEL
		local maxChargesCap=MawCore.ItemLevel.MaxPower()
		local dropLevel=MawCore.ItemLevel.ForDrop(drop.monsterLevel, partyLevel, mapLevel)

		SetStoredDropLevel(it, dropLevel)
		it.MaxCharges=rollMaxCharges(MawCore.ItemLevel.PowerFor(dropLevel))
		
		partyLevel1=GetTier(partyLevel+bonus)+GetEnchantTierBonus()
		--adjust loot Strength
		ps1=t.Strength

		pseudoStr=ps1+partyLevel1
		if drop.boss then
			pseudoStr=pseudoStr+1
		end
		if drop.omnipotent then
			pseudoStr=pseudoStr+1
		end
		if math.random(1,18)<partyLevel1%18 then
			pseudoStr=pseudoStr+1
		end
		power=0
		--difficulty multiplier 
		diffMult=math.max((Game.BolsterAmount-100)/500+1,1)
		if vars.Mode==2 then
			diffMult=1.8
		end

		--the common end: how many of the three enchant chances hit
		local p1=enc1Chance[math.min(pseudoStr,#enc1Chance)]/100
		local p2=enc2Chance[math.min(pseudoStr,#enc2Chance)]/100
		local p3=spcEncChance[math.min(pseudoStr,#spcEncChance)]/100
		p1=p1^(1/diffMult)
		p2=p2^(1/diffMult)
		p3=p3^(1/diffMult)
		local roll1,roll2,rollSpc=math.random(),math.random(),math.random()
		if drop.boss then
			roll1=roll1/2
			roll2=roll2/2
			rollSpc=rollSpc/2
		end
		local rarity=0
		if p1>roll1 then
			rarity=rarity+1
		end
		if p2>roll2 then
			rarity=rarity+1
		end
		if p3>rollSpc then
			rarity=rarity+1
		end
		local noLegendary=vars.AusterityMode or Game.HouseScreen==2 or Game.HouseScreen==95
		if rarity==RARITY_EPIC then
			rarity=RollItemRarity(pseudoStr, drop.boss, noLegendary, drop.multiplier)
		end
		if drop.omnipotent then
			rarity=RARITY_CELESTIAL
		end
		local enchantTier=GetRarityEnchantTier(rarity)

		if rarity>=RARITY_UNCOMMON then
			it.Bonus=RollEnchantType(it)
			it.BonusStrength=rollEnchantStrength(pseudoStr, enchantTier)
			if math.random(1,10)==10 then
				it.Bonus=math.random(17,24)
				local skill=it:T().Skill
				if (skill==10 or skill==11) and it.Bonus==23 then
					it.Bonus=22
				elseif (skill<=7 and skill>0) and it.Bonus==24 then
					it.Bonus=22
				end
			end
		end
		--apply enchant2
		if rarity>=RARITY_RARE then
			local enc2Strength=rollEnchantStrength(pseudoStr, enchantTier)
			--bonus type
			SetEnc2(it,RollEnchantType(it, it.Bonus),enc2Strength)
			--[[ no skill bonuses
			if math.random(1,10)==10 then
				it.Charges=math.random(17,24)*1000
				it.Charges=it.Charges+round(rollEnchantStrength(pseudoStr)^0.5)
			end
			]]
		end
		--make it standard bonus if no standard bonus
		if it.Bonus==0 then
			it.Bonus,it.BonusStrength=GetEnc2(it)
			it.Charges=0
		end
				
		--the whole rare end rolls its special enchant a couple of tiers up
		if rarity>=RARITY_ANCIENT then
			power=2
		end
		if rarity==RARITY_ANCIENT then
			it.MaxCharges=rollTierCharges(it.MaxCharges, 1)
			SetAncientTier(it,1)
		end
		--apply special enchant
		if rarity>=RARITY_EPIC then
			n=it.Number
			c=Game.ItemsTxt[n].EquipStat
			if c<12 then
				power=ps1+power
				power=math.max(math.min(power,6),3)
				totB2=itemStrength[power][c]
				roll=math.random(1,totB2)
				tot=0
				for i=0,Game.SpcItemsTxt.High do
					if roll<=tot then
						it.Bonus2=i
						goto continue
					elseif table.find(enchants[power], Game.SpcItemsTxt[i].Lvl) then
						tot=tot+Game.SpcItemsTxt[i].ChanceForSlot[c]
					end
				end	
			end			
		end
		
		::continue::
		
		
		--primordial item, and the celestial that carries its grade
		if enchantTier==2 then
			SetAncientTier(it,2)
			it.MaxCharges=rollTierCharges(it.MaxCharges, 2)
			--apply special enchant
			n=it.Number
			c=Game.ItemsTxt[n].EquipStat
			if c<=2 then
				roll=math.random(1,#primordialWeapEnchants)
				it.Bonus2=primordialWeapEnchants[roll]
			else
				roll=math.random(1,#primordialArmorEnchants)
				it.Bonus2=primordialArmorEnchants[roll]
			end
		end

		if rarity>=RARITY_LEGENDARY then
			vars.legendaryAffixDropped=vars.legendaryAffixDropped or {}
			for i = 1, LEGENDARY_AFFIX_COUNT do
				vars.legendaryAffixDropped[i] = vars.legendaryAffixDropped[i] or 0
			end
			legendaryAffix=get_affix(vars.legendaryAffixDropped)
			vars.legendaryAffixDropped[legendaryAffix]=vars.legendaryAffixDropped[legendaryAffix]+1
			SetLegendaryAffix(it,legendaryAffix+LEGENDARY_AFFIX_BASE)
			--adjust bonus 2 if enchant damage legendary
			if GetLegendaryAffix(it)==19 then
				if it.Bonus2==40 then
					it.Bonus2=39
				elseif it.Bonus2==41 then
					it.Bonus2=46
				end
			end
			it.MaxCharges=round(math.min(maxChargesCap,
				it.MaxCharges*LEGENDARY_CHARGES_MULT,
				it.MaxCharges+LEGENDARY_CHARGES_BONUS))
			local statSets={{1, 5, 6, 7}, {4, 6, 8, 10}, {2, 3, 4, 6, 7}}
			local stats=statSets[math.random(1,#statSets)]
			if GetItemEquipStat(it)==10 then
				stats={1, 5, 6, 7, 11, 12, 13, 14, 15, 16}
			end
			it.Bonus=RollStatFromList(stats)
			SetEnc2Type(it,RollStatFromList(stats, it.Bonus))
		end
		--celestial
		if rarity==RARITY_CELESTIAL then
			SetCelestialItem(it,true)
		end
		--nerf to skills
		if it.Bonus>=17 and it.Bonus<=24 then
			it.BonusStrength=math.ceil(math.max(it.BonusStrength^0.5,it.BonusStrength/10))
		end
		-- buff to 2h weapons enchants
		local mult=slotMult[it:T().EquipStat]
		if mult then
			it.BonusStrength=math.ceil(it.BonusStrength*mult)
			local enc2Type,enc2Power=GetEnc2(it)
			enc2Power=math.min(enc2Power*mult,ENC2_MAX_STRENGTH)
			SetEnc2(it,enc2Type,enc2Power)
		end
		--check if int/pers or might/accuracy item to change special enchant
		local melee=0
		local caster=0
		if it.Bonus2==39 or it.Bonus2==40 or it.Bonus2==41 or it.Bonus2==46 then
			if it.Bonus==1 or it.Bonus==5 then
				melee=melee+1
			elseif it.Bonus==2 or it.Bonus==3 then
				caster=caster+1
			end
			local bonus=GetEnc2Type(it)
			if bonus==1 or bonus==5 then
				melee=melee+1
			elseif bonus==2 or bonus==3 then
				caster=caster+1
			end
			if melee>caster then
				if it.Bonus2==39 then
					it.Bonus2=46
				elseif it.Bonus2==40 then
					it.Bonus2=41
				end
			elseif caster>melee then
				if it.Bonus2==46 then
					it.Bonus2=39
				elseif it.Bonus2==41 then
					it.Bonus2=40
				end
			end
		end
		local syncType,syncPower=GetEnc2(it)
		if math.abs(syncPower-it.BonusStrength)<=1 then
			SetEnc2(it,syncType,it.BonusStrength)
		end
		
		it.MaxCharges=math.min(GetItemChargesCap(it), it.MaxCharges)
		
		--reduce chances for resistances
		if GetItemEquipStat(it)~=10 and it.Bonus>=11 and it.Bonus<=16 then
			it.Bonus=math.random(1,10)
		end
		local resType=GetEnc2Type(it)
		if resType>=11 and resType<=16 then
			SetEnc2Type(it,math.random(1,10))
		end

		--can't roll same enchant
		local bonus2=GetEnc2Type(it)
		if it.Bonus>0 and it.Bonus<=16 and it.Bonus==bonus2 then
			local low,high=1,10
			if it.Bonus>=11 then
				low,high=11,16
			end
			repeat
				it.Bonus=math.random(low,high)
			until it.Bonus~=bonus2
		end
		
		local itemPower=1
		if it.Bonus>0 then
			itemPower=itemPower+1
		end
		if it.Bonus2>0 then
			itemPower=itemPower+1
		end
		if HasEnc2(it) then
			itemPower=itemPower+1
		end
		--rarest first, same order as the loot filter above
		if IsCelestialItem(it) then
			itemPower=8
		elseif HasLegendaryAffix(it) then
			itemPower=7
		elseif IsPrimordialItem(it) then
			itemPower=6
		elseif IsAncientItem(it) then
			itemPower=5
		end
		
		vars.MAWSETTINGS=vars.MAWSETTINGS or {}
		vars.MAWSETTINGS.lootFilter=vars.MAWSETTINGS.lootFilter or "OFF"
		
		local filter=vars.MAWSETTINGS.lootFilter

		local tierList={"Common", "Uncom.", "Rare", "Epic", "Ancient", "Primordial", "Legendary", [0]="OFF"}
		local filterPower=table.find(tierList, filter)
		local itemID=it.Number
		if itemPower<=filterPower then
			if lootFromMonster then
				lootFromMonster=false
				local itemGold=getItemValue(it, true)
				it.Number=0
				RunNextTick(function()
					goldGained=Party.Gold-goldBeforeLoot
					Party.Gold=Party.Gold+itemGold
					Game.ShowStatusText("You found " .. itemGold+goldGained .. " gold! (" .. tierList[itemPower] .. " " .. Game.ItemsTxt[itemID].NotIdentifiedName .. " filtered)")
				end)
			end
		end
		if IsCelestialItem(it) then
			return
		end
	end
end

-- Function to get an affix based on the pity system
function get_affix(counts)
    local v = {}
    local total = 0
	local N=#counts
    -- Calculate the weight for each affix
    for i = 1, N do
        v[i] = 1 / (N * (counts[i] + 1))
        total = total + v[i]
    end

    -- Compute cumulative probabilities
    local cumulative = {}
    local cum_sum = 0
    for i = 1, N do
        cum_sum = cum_sum + v[i] / total
        cumulative[i] = cum_sum
    end

    -- Generate a random number between 0 and 1
    local r = math.random()

    -- Find and return the affix corresponding to the random number
    for i = 1, N do
        if r <= cumulative[i] then
            return i
        end
    end

    -- Fallback in case of rounding errors
    return N
end

--items stats multiplier:
slotMult={2,1.25,1.5,1,1.25,1,1,1.25,1.25,0.75,1,[0]=1	}

----------------------
--weapon rework
----------------------
function events.GameInitialized2()
	--converts halberds
	local halberds={46,47,48,49,50,507,838,839,840,1638,1639,1640}
	for i=1,#halberds do
		Game.ItemsTxt[halberds[i]].EquipStat=1
	end
--Weapon upscaler 
    for i = 1, 2199 do
		if (i>=1 and i<=83) or (i>=803 and i<=865) or (i>=1603 and i<=1665) then
			
			local goalDamage=WEAPON_BASE_DICE_DAMAGE
			local flatDamage=weaponTierFlat(MawCore.ItemLevel.LadderTier(i))
			if not (Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Axe" or Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Sword" or Game.ItemsTxt[i].NotIdentifiedName == "Halberd" or Game.ItemsTxt[i].Skill==0) then
				goalDamage=goalDamage/2
				flatDamage=flatDamage/2
			end
			if Game.ItemsTxt[i].Mod1DiceCount>0 then
				Game.ItemsTxt[i].Mod1DiceSides=math.ceil(goalDamage*2/Game.ItemsTxt[i].Mod1DiceCount)
			end
			Game.ItemsTxt[i].Mod2=round(flatDamage)

		elseif Game.ItemsTxt[i].Skill==8 then
			--increase shield value
			Game.ItemsTxt[i].Mod2=Game.ItemsTxt[i].Mod2*2+Game.ItemsTxt[i].Mod1DiceCount  
		end
	end
end

--change tooltip
function events.GameInitialized2()
	--menu stats
	if ColouredStats==true then
		Game.GlobalTxt[144]=StrColor(255,0,0,Game.GlobalTxt[144])
		Game.GlobalTxt[116]=StrColor(255,128,0,Game.GlobalTxt[116])
		Game.GlobalTxt[163]=StrColor(0,127,255,Game.GlobalTxt[163])
		Game.GlobalTxt[75]=StrColor(0,255,0,Game.GlobalTxt[75])
		Game.GlobalTxt[1]=StrColor(255,255,0,Game.GlobalTxt[1])
		Game.GlobalTxt[211]=StrColor(127,0,255,Game.GlobalTxt[211])
		Game.GlobalTxt[136]=StrColor(255,255,255,Game.GlobalTxt[136])
		Game.GlobalTxt[108]=StrColor(0,255,0,Game.GlobalTxt[108])
		Game.GlobalTxt[212]=StrColor(0,100,255,Game.GlobalTxt[212])
		Game.GlobalTxt[12]=StrColor(230,204,128,Game.GlobalTxt[12])
	end
end

-----------------------------
---IMMUNITY REWORK
-----------------------------
function events.DoBadThingToPlayer(t)
    local protectionMessages = {
        [18] = { [9] = "disease", [10] = "disease", [11] = "disease", [1] = "curse" },
        [19] = { [5] = "insanity", [22] = "spell drain" },
        [20] = { [12] = "paralysis", [23] = "fear" },
        [21] = { [6] = "poison", [7] = "poison", [8] = "poison", [2] = "weakness" },
        [22] = { [3] = "sleep", [13] = "unconscious" },
        [23] = { [15] = "stone", [21] = "premature ageing" },
        [25] = { [14] = "death", [16] = "eradication" },
    }

    for it in t.Player:EnumActiveItems() do
        if protectionMessages[it.Bonus2] and protectionMessages[it.Bonus2][t.Thing] then
            t.Allow = false
            local protectionType = protectionMessages[it.Bonus2][t.Thing]
            Game.ShowStatusText(string.format("Enchantment protects %s from %s", t.Player.Name, protectionType))
        end
    end
end
function events.GameInitialized2()
--new tooltips
	Game.SpcItemsTxt[2].BonusStat="Explosive Impact! (half damage)"
	Game.SpcItemsTxt[17].BonusStat="Disease and Curse Immunity"
	Game.SpcItemsTxt[18].BonusStat="Insanity and SP drain Immunity"
	Game.SpcItemsTxt[19].BonusStat="Paralysis and fear Immunity"
	Game.SpcItemsTxt[20].BonusStat="Poison and weakness Immunity"
	Game.SpcItemsTxt[21].BonusStat="Sleep and Unconscious Immunity"
	Game.SpcItemsTxt[22].BonusStat="Stone and premature ageing Immunity"
	Game.SpcItemsTxt[24].BonusStat="Death and Eradication Immunity"
	Game.SpcItemsTxt[35].BonusStat="Reduces Physical damage taken by 15%"
end
--------------------
--STATUS REWORK (needs to stay after status immunity)
--------------------

function events.LoadMap(wasInGame)
	function events.DoBadThingToPlayer(t)
		if (t.Thing==6 or t.Thing==7 or t.Thing==8) and t.Allow then
			if vars.poisonTime[t.PlayerIndex]==nil or vars.poisonTime[t.PlayerIndex]==0 then
				vars.poisonTime[t.PlayerIndex]=25
			else
				vars.poisonTime[t.PlayerIndex]=math.min(vars.poisonTime[t.PlayerIndex]+5,50)
			end
		end
	end
end
--carnage fix tooltip
function events.GameInitialized2()
	Game.SpcItemsTxt[2].BonusStat="Explosive Impact! (half damage)"
end


function poisonTimer() 
	vars.poisonTime=vars.poisonTime or {}
	local mult=Game.BolsterAmount/100
	if vars.insanityMode then
		mult=mult*2
	end
	if Party.High==0 then
		mult=mult/2
	end
	for i = 0, Party.High do
		if Party[i].HP>=1 then
			if Party[i].Poison3>0 then
				if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
					vars.poisonTime[i]=20
				end
				if vars.poisonTime[i]>0 then
					vars.poisonTime[i]=vars.poisonTime[i]-1
				end
				if vars.poisonTime[i]==0 then			
					Party[i].Poison3=0
					Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
				else
					Party[i].HP=math.max(Party[i].HP-math.ceil(Party[i]:GetFullHP()*0.01)*mult,1)
				end 
			elseif Party[i].Poison2>0 then
				if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
					vars.poisonTime[i]=20
				end
				if vars.poisonTime[i]>0 then
					vars.poisonTime[i]=vars.poisonTime[i]-1
				end
				if vars.poisonTime[i]==0 then			
					Party[i].Poison2=0
					Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
				else
					Party[i].HP=math.max(Party[i].HP-math.ceil(Party[i]:GetFullHP()*0.005)*mult,1)
				end 
			elseif Party[i].Poison1>0 then
				if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
					vars.poisonTime[i]=20
				end
				if vars.poisonTime[i]>0 then
					vars.poisonTime[i]=vars.poisonTime[i]-1
				end
				if vars.poisonTime[i]==0 then			
					Party[i].Poison1=0
					Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
				else
					Party[i].HP=math.max(Party[i].HP-math.ceil(Party[i]:GetFullHP()*0.0025)*mult,1)
				end 
			else 
				vars.poisonTime[i]=0
			end
		end
	end
end
------------------------------------------
--TOOLTIPS--
------------------------------------------
legendaryEffects={
	[11]="Killing a monster with a single-target attack halves the recovery time",
	[12]="Might and accuracy enchantments give 40% bonus to intellect and personality. Intellect and personality enchantments give 40% bonus to might and accuracy",
	[13]="Immunity to all status effects from monsters",
	[14]="Crit chance increased by 10% and crit chance over 100% increases total damage",
	[15]="Divine protection (instead of dying you go back to 25% HP, once every 5 minutes)",
	
	[16]="Increase the effect of resistances base enchants by 50%",
	
	[17]="Your hits deal 2% of current monster HP as physical damage (1% for AoE, multi-hit spells and arrows).\nDamage is increased by weapon base attack speed or Ascensions for spells.",
	[18]="Reduce all damage taken by 10%",
	[19]="Your weapon enchants scale with the highest between might/int./pers.",
	[20]="Meditation restores 1% more mana for each 1% of your mana reserved by buffs",
	[21]="Increase melee damage by 5% for each enemy in the nearbies",
	[22]="Reduces damage by 3% for each enemy in the nearbies",
	[23]="Successfully covering an ally restores 3% of your HP",
	[24]="Killing a Monster Restores 10% of Health and 5% of Mana",
	[25]="Increases Ascension Skill level by 10",
	[26]="Your weapon enchants can deal critical damage",
	
	[27]="Leech overhealing heals the most injured party member instead",
	[28]="AC gained from armors is doubled",
	[29]="Each attack reduces monster resistances by 1",
	[30]="Threshold HP to determine death/eradication depends on SP multiplied by mana shield efficiency instead, if higher",
	[31]="Leech also restores Mana, but its effect is halved",
	[32]="Buffs reserve Hit Points instead of Mana and Hit Point coefficient is used instead.\nEnlightenment bonus still apply.",
	[33]="Increase Melee weapon skill by 10",
	[34]="Overhealing refunds mana",
	[35]="Overhealing reduces recovery time equal to half overhealing amount",
}

--Roll ids run 1..LEGENDARY_AFFIX_COUNT and store as id+LEGENDARY_AFFIX_BASE.
--Derived from the keys rather than `#legendaryEffects`: that table starts at
--11, so its length only answers correctly because Lua happens to give it an
--array part -- add or remove affixes and it can silently stop matching.
LEGENDARY_AFFIX_COUNT = 0
for id in pairs(legendaryEffects) do
	LEGENDARY_AFFIX_COUNT = math.max(LEGENDARY_AFFIX_COUNT, id - LEGENDARY_AFFIX_BASE)
end

function events.GameInitialized2()
	local F=MawCore.Formulas
	legendaryEffects[24]=string.format(
		"Killing a Monster restores %s%% of Health and %s%% of Mana, counted on the pool left after buffs reserve theirs",
		F.legendary24Health*100, F.legendary24Mana*100)
end

function updateCelestialItem(it,pl)
	if IsCelestialItem(it) then
		if not pl then
			local id=Game.CurrentPlayer
			if id<0 or id>Party.High then
				id=0
			end
			pl=Party[id]
		end
		local equipStat=it:T().EquipStat
		if table.find(twoHandedAxes, it.Number) then
			equipStat=1
		end
		local slotMult=slotMult[equipStat] or 1
		local lvl=pl.LevelBase
		local lvl2=getTotalLevel()
		if lvl>lvl2*1.2 then
			lvl=lvl2*1.2
		end
		local tier=lvl/11+5
		if vars.madnessMode then
			tier=math.min(lvl,500)/11+5
		end
		local mult=1
		if IsPrimordialItem(it) then
			mult=PRIMORDIAL_ENCHANT_MULT
		end
		local strength=math.round(applyDifficulty(encStrUp(tier))*mult*slotMult)
		if it.Bonus>0 and it.BonusStrength>0 then
			it.BonusStrength=strength
			if it.Bonus>=17 then
				it.BonusStrength=math.round(it.BonusStrength/10)
			end
		end
		if HasEnc2(it) then
			SetEnc2Strength(it,math.min(strength,ENC2_MAX_STRENGTH))
		end
		it.MaxCharges=GetPrimordialCharges(lvl)
	end
end

extraDescription=false
function events.KeyDown(t)
	if t.Alt then
		extraDescription=true
	end	
end
function events.KeyUp(t)
	if t.Alt then
		extraDescription=false
	end	
end

--colours
function events.GameInitialized2()
	itemStatName = {}
	itemStatName[1] = StrColor(255, 0, 0, "Might")
	itemStatName[2] = StrColor(255, 128, 0, "Intellect")
	itemStatName[3] = StrColor(0, 127, 255, "Personality")
	itemStatName[4] = StrColor(0, 255, 0, "Endurance")
	itemStatName[5] = StrColor(255, 255, 0, "Accuracy")
	itemStatName[6] = StrColor(127, 0, 255, "Speed")
	itemStatName[7] = StrColor(255, 255, 255, "Luck")
	itemStatName[8] = StrColor(0, 255, 0, "Hit Points")
	itemStatName[9] = StrColor(0, 100, 255, "Spell Points")
	itemStatName[10] = StrColor(230, 204, 128, "Armor Class")
	itemStatName[11] = StrColor(255, 70, 70, "Fire Resistance")
	itemStatName[12] = StrColor(173, 216, 230, "Air Resistance")
	itemStatName[13] = StrColor(100, 180, 255, "Water Resistance")
	itemStatName[14] = StrColor(153, 76, 0, "Earth Resistance")
	itemStatName[15] = StrColor(200, 200, 255, "Mind Resistance")
	itemStatName[16] = StrColor(255, 192, 203, "Body Resistance")
	itemStatName[17] = StrColor(255,255,153, "Alchemy skill")
	itemStatName[18] = StrColor(255,255,153, "Repair skill")
	itemStatName[19] = StrColor(255,255,153, "Disarm skill")
	itemStatName[20] = StrColor(255,255,153, "ID Item skill")
	itemStatName[21] = StrColor(255,255,153, "ID Monster skill")
	itemStatName[22] = StrColor(255,255,153, "Armsmaster skill")
	itemStatName[23] = StrColor(255,255,153, "Dodge skill")
	itemStatName[24] = StrColor(255,255,153, "Unarmed skill")
	itemStatName[25] = StrColor(255,255,153, "Great might")
	
	baseStatName={
		[1]="Might",
		[2]="Intellect",
		[3]="Personality",
		[4]="Endurance",
		[5]="Accuracy",
		[6]="Speed",
		[7]="Luck",
		[8]="Hit Points",
		[9]="Spell Points",
		[10]="Armor Class",
		[11]="Fire Resistance",
		[12]="Air Resistance",
		[13]="Water Resistance",
		[14]="Earth Resistance",
		[15]="Mind Resistance",
		[16]="Body Resistance",
		[17]="Alchemy skill",
		[18]="Repair skill",
		[19]="Disarm skill",
		[20]="ID Item skill",
		[21]="ID Monster skill",
		[22]="Armsmaster skill",
		[23]="Dodge skill",
		[24]="Unarmed skill",
	}
		
end

--fix to enchant2 not applying correctly if same bonus is on the item
--fix to special enchants
--VANILLA ENCHANTS, used to check if there is any difference to compute
bonusEffectsBase = {
    [1] = { bonusType = 1, bonusRange = {11, 16}, statModifier = 10 },
    [2] = { bonusType = 2, bonusRange = {1, 7}, statModifier = 10 },
    [39] = { bonusType = 39, bonusValues = {2, 3}, statModifier = 0 },
    [42] = { bonusType = 42, bonusRange = {1, 16}, statModifier = 1 },
    [43] = { bonusType = 43, bonusValues = {4, 8, 10}, statModifier = 10 },
    [44] = { bonusType = 44, bonusValues = {8}, statModifier = 10 },
    [45] = { bonusType = 45, bonusValues = {5, 6}, statModifier = 5 },
    [46] = { bonusType = 46, bonusValues = {1}, statModifier = 25 },
    [47] = { bonusType = 47, bonusValues = {9}, statModifier = 10 },
    [48] = { bonusType = 48, bonusValues = {4, 10}, statModifier = {15, 5} },
    [49] = { bonusType = 49, bonusValues = {2, 7}, statModifier = 10 },
    [50] = { bonusType = 50, bonusValues = {11}, statModifier = 30 },
    [51] = { bonusType = 51, bonusValues = {2, 6, 9}, statModifier = 10 },
    [52] = { bonusType = 52, bonusValues = {4, 5}, statModifier = 10 },
    [53] = { bonusType = 53, bonusValues = {1, 3}, statModifier = 10 },
    [54] = { bonusType = 54, bonusValues = {4}, statModifier = 15 },
    [55] = { bonusType = 55, bonusValues = {7}, statModifier = 15 },
    [56] = { bonusType = 56, bonusValues = {1, 4}, statModifier = 5 },
    [57] = { bonusType = 57, bonusValues = {2, 3}, statModifier = 5 },
    [74] = { bonusType = 53, bonusValues = {3, 5}, statModifier = 0 },
    [75] = { bonusType = 53, bonusValues = {1, 2}, statModifier = 0 },
    [76] = { bonusType = 53, bonusValues = {2, 5}, statModifier = 0 },
    [77] = { bonusType = 53, bonusValues = {1, 2, 3}, statModifier = 0 },
    [78] = { bonusType = 53, bonusRange = {11, 14}, statModifier = 0 },
    [79] = { bonusType = 53, bonusValues = {15, 16}, statModifier = 0 },
    [80] = { bonusType = 53, bonusRange = {1, 16}, statModifier = 0 },
}

--MODIFY THIS TO CHANGE ACTUAL VALUES
bonusEffects = {
    [1] = { bonusType = 1, bonusRange = {11, 16}, statModifier = 10 },
    [2] = { bonusType = 2, bonusRange = {1, 7}, statModifier = 8 },
    [39] = { bonusType = 39, bonusValues = {2, 3}, statModifier = 25 },
    [42] = { bonusType = 42, bonusRange = {1, 16}, statModifier = 3 },
    [43] = { bonusType = 43, bonusValues = {4, 8, 10}, statModifier = 10 },
    [44] = { bonusType = 44, bonusValues = {8}, statModifier = 10 },
    [45] = { bonusType = 45, bonusValues = {5, 6}, statModifier	 = 10 },
    [46] = { bonusType = 46, bonusValues = {1}, statModifier = 25 },
    [47] = { bonusType = 47, bonusValues = {9}, statModifier = 10 },
    [48] = { bonusType = 48, bonusValues = {4, 10}, statModifier = {15, 5} },
    [49] = { bonusType = 49, bonusValues = {2, 7}, statModifier = 10 },
    [50] = { bonusType = 50, bonusValues = {11}, statModifier = 30 },
    [51] = { bonusType = 51, bonusValues = {2, 6, 9}, statModifier = 10 },
    [52] = { bonusType = 52, bonusValues = {4, 5}, statModifier = 10 },
    [53] = { bonusType = 53, bonusValues = {1, 3}, statModifier = 20 },
    [54] = { bonusType = 54, bonusValues = {4}, statModifier = 15 },
    [55] = { bonusType = 55, bonusValues = {7}, statModifier = 15 },
    [56] = { bonusType = 56, bonusValues = {1, 4}, statModifier = 10 },
    [57] = { bonusType = 57, bonusValues = {2, 3}, statModifier = 15 },
    [74] = { bonusType = 53, bonusValues = {3, 5}, statModifier = 20 },
    [75] = { bonusType = 53, bonusValues = {1, 2}, statModifier = 20 },
    [76] = { bonusType = 53, bonusValues = {2, 5}, statModifier = 20 },
    [77] = { bonusType = 53, bonusValues = {1, 2, 3}, statModifier = 15 },
    [78] = { bonusType = 53, bonusRange = {11, 14}, statModifier = 20 },
    [79] = { bonusType = 53, bonusValues = {15, 16}, statModifier = 20 },
    [80] = { bonusType = 53, bonusRange = {1, 16}, statModifier = 5 },
}

--create dictionary with description list
function checktext(MaxCharges,bonus2,it)
	--[[if MaxCharges <= 20 then
	if vars.insanityMode then
		MaxCharges=math.ceil(MaxCharges*4/3)
	end
	]]
	mult=MawCore.Formulas.chargesStatMult(MaxCharges)
	--else
	--	mult=2+2*(MaxCharges-20)/20
	--end
	--bow tooltip
	local weaponType="Melee"
	if it:T().EquipStat==2 then
		weaponType="Bow"
	end

	--damage enchants read the shared range (same numbers the damage roll uses)
	local plId=Game.CurrentPlayer
	if plId<0 or plId>Party.High then
		plId=0
	end
	local legDmgMult=GetLegendary19Mult(Party[plId])
	local function enchRangeText(id)
		local lo, hi=enchantDamageRange(it, id)
		lo, hi=lo*legDmgMult, hi*legDmgMult
		if math.floor(lo)==math.floor(hi) then
			return tostring(math.floor(lo))
		end
		return math.floor(lo) .. "-" .. math.floor(hi)
	end
	local function enchDmgText(id, kind)
		return "Adds " .. enchRangeText(id) .. " points of " .. kind .. " damage."
	end

	bonus2txt={
		[1] =  " +" .. math.floor(bonusEffects[1].statModifier * mult) .. " to all Resistances.",
		[2] = " +" .. math.floor(bonusEffects[2].statModifier * mult) .. " to all Seven Statistics.",
		[4] = enchDmgText(4, "Cold"),
		[5] = enchDmgText(5, "Cold"),
		[6] = enchDmgText(6, "Cold"),
		[7] = enchDmgText(7, "Electrical"),
		[8] = enchDmgText(8, "Electrical"),
		[9] = enchDmgText(9, "Electrical"),
		[10] = enchDmgText(10, "Fire"),
		[11] = enchDmgText(11, "Fire"),
		[12] = enchDmgText(12, "Fire"),
		[13] = enchDmgText(13, "Body"),
		[14] = enchDmgText(14, "Body"),
		[15] = enchDmgText(15, "Body"),
		--spell enchants
		[26] = "Air Magic Skill +" .. MawCore.Formulas.chargesSchoolSkill(MaxCharges),
		[27] = "Body Magic Skill +" .. MawCore.Formulas.chargesSchoolSkill(MaxCharges),
		[28] = "Dark Magic Skill +" .. MawCore.Formulas.chargesSchoolSkill(MaxCharges),
		[29] = "Earth Magic Skill +" .. MawCore.Formulas.chargesSchoolSkill(MaxCharges),
		[30] = "Fire Magic Skill +" .. MawCore.Formulas.chargesSchoolSkill(MaxCharges),
		[31] = "Light Magic Skill +" .. MawCore.Formulas.chargesSchoolSkill(MaxCharges),
		[32] = "Mind Magic Skill +" .. MawCore.Formulas.chargesSchoolSkill(MaxCharges),
		[33] = "Spirit Magic Skill +" .. MawCore.Formulas.chargesSchoolSkill(MaxCharges),
		[34] = "Water Magic Skill +" .. MawCore.Formulas.chargesSchoolSkill(MaxCharges),
		--stats enchants
		[38] = "Meditation Skill +" .. MawCore.Formulas.chargesMeditationSkill(MaxCharges),
		[39] = "Adds " .. enchRangeText(39) .. " to spell damage and +" .. math.floor(bonusEffects[46].statModifier * mult).. " Intellect and personality.",
		[40] = "Spells Drain Hit points from target and Increased Spell speed.(except when equipping off-hand).",
		[42] = " +" .. math.floor(bonusEffects[42].statModifier * mult) .. " to Seven Stats, HP, SP, Armor, Resistances.",
		[43] = " +" .. math.floor(bonusEffects[43].statModifier * mult) .. " to Endurance, Armor, Hit points.",
		[44] = " +" .. math.floor(bonusEffects[44].statModifier * mult) .. " Hit points and Regenerate Hit points over time.",
		[45] = " +" .. math.floor(bonusEffects[45].statModifier * mult) .. " Speed and Accuracy.",
		[46] = "Adds " .. enchRangeText(46) .. " points of Fire damage to " .. weaponType .. " attacks and +" .. math.floor(bonusEffects[46].statModifier * mult).. " Might.",
		[47] = " +" .. math.floor(bonusEffects[47].statModifier * mult) .. " Spell points and Meditation Skill +" .. MawCore.Formulas.chargesMeditationSkill(MaxCharges),
		[48] = " +" .. math.floor(bonusEffects[48].statModifier[1] * mult) .. " Endurance and" .. " +" .. math.floor(bonusEffects[48].statModifier[2] * mult).. " Armor.",
		[49] = " +" .. math.floor(bonusEffects[49].statModifier * mult) .. " Intellect and Luck.",
		[50] = " +" .. math.floor(bonusEffects[50].statModifier * mult) .. " Fire Resistance and Regenerate Hit points over time.",
		[51] = " +" .. math.floor(bonusEffects[51].statModifier * mult) .. " Spell points, Speed, Intellect.",
		[52] = " +" .. math.floor(bonusEffects[52].statModifier * mult) .. " Endurance and Accuracy.",
		[53] = " +" .. math.floor(bonusEffects[53].statModifier * mult) .. " Might and Personality.",
		[54] = " +" .. math.floor(bonusEffects[54].statModifier * mult) .. " Endurance and Regenerate Hit points over time.",
		[55] = " +" .. math.floor(bonusEffects[55].statModifier * mult) .. " Luck and Meditation Skill +" .. MawCore.Formulas.chargesMeditationSkill(MaxCharges),
		[56] = " +" .. math.floor(bonusEffects[56].statModifier * mult) .. " Might and Endurance.",
		[57] = " +" .. math.floor(bonusEffects[57].statModifier * mult) .. " Intellect and Personality.",
		[66] = "Regenerates Hit Points and Meditation Skill +" .. MawCore.Formulas.chargesMeditationSkill(MaxCharges),
		--hybrids enchants 
		[74] = " +" .. math.floor(bonusEffects[74].statModifier * mult) .. " Personality and Accuracy.",
		[75] = " +" .. math.floor(bonusEffects[75].statModifier * mult) .. " Intellect and Might.",
		[76] = " +" .. math.floor(bonusEffects[76].statModifier * mult) .. " Intellect and Accuracy.",
		[77] = " +" .. math.floor(bonusEffects[77].statModifier * mult) .. " Might, Intellect and Personality.",
		[78] = " +" .. math.floor(bonusEffects[78].statModifier * mult) .. " Elemental Resistances.",
		[79] = " +" .. math.floor(bonusEffects[79].statModifier * mult) .. " Body and mind Resistances.",
		[80] = " +" .. math.floor(bonusEffects[80].statModifier * mult) .. " to Seven Stats, HP, SP, Armor, Resistances.",
	}

	
	return bonus2txt[bonus2]
end

--calculate price
function events.CalcItemValue(t)
	if IsEnchantableItem(t.Item) then
		--base value
		basePrice=Game.ItemsTxt[t.Item.Number].Value
		if reagentList[t.Item.Number] then
			local bonus=round(reagentList[t.Item.Number] *((t.Item.Bonus*0.75)/20+1)+t.Item.Bonus*0.75)
			t.Enchantment="Power: " .. bonus
			t.Value=bonus*10
			return
		end
		t.Value=getItemValue(t.Item)
	end
	if t.Item.Number>=971 and t.Item.Number<=979 then
		t.Value=Game.ItemsTxt[t.Item.BonusStrength].Value
	end
	--add reagents price
	if Game.HouseScreen==2 or Game.HouseScreen==95 then
		if reagentPrices[t.Item.Number] then
			t.Value=reagentPrices[t.Item.Number]
		end
	end
end

function getItemValue(it, lootFilter)
	if IsEnchantableItem(it) then
		--base value
		basePrice=Game.ItemsTxt[it.Number].Value
		--add enchant price
		bonus1=it.BonusStrength*100
		if it.Bonus==8 or it.Bonus==9 then
			bonus1=5*((2*it.BonusStrength+100)^0.5-10)*100
		elseif it.Bonus==10 then
			bonus1=bonus1*2
		elseif it.Bonus>16 and it.Bonus<=24 then
			bonus1=(bonus1/100)^2*100
		end
		
		local enc2Strength
		bonus2Type,enc2Strength=GetEnc2(it)
		bonus2=enc2Strength*100
		if bonus2Type==8 or bonus2Type==9 then
			bonus2=5*((2*bonus2+100)^0.5-10)
		elseif bonus2Type==10 then
			bonus2=bonus2*2
		end
		
		MaxCharges=it.MaxCharges
		
		mult=MaxCharges/20
		
		basePriceBonus=basePrice*mult
		--the expiry test only means something when the field IS a timer: on a
		--rarity item it holds the marker, which is far bigger than Game.Time
		if it.Bonus2>0 and it.Bonus2<=Game.SpcItemsTxt.high
				and (HasRarityData(it) or it.BonusExpireTime<Game.Time) then
			special=Game.SpcItemsTxt[it.Bonus2-1].Value
			if bonusEffects[it.Bonus2]~=nil then
				special=special*mult
			end
			if special<11 then
				basePriceBonus=basePriceBonus*special
				if special==10 then
					basePriceBonus=basePriceBonus*2.5
				end
			else
				basePriceBonus=basePriceBonus+special
			end
		end
		local value=basePrice+(basePriceBonus+bonus1+bonus2)
		if HasLegendaryAffix(it) then
			value=value*2.5
		end
		if Game.HouseScreen==2 or Game.HouseScreen==95 then
			count=0
			if it.Bonus>0 then
				count=count+1
			end
			if HasEnc2(it) then
				count=count+1
			end
			if it.Bonus2>0 then
				count=count+1
			end
			if GetAncientTier(it)>0 then
				count=count+GetAncientTier(it)
			end
			if count>0 then
				value=value^(1+count*0.08)
			end
		else
			value=value*0.4
		end	
		if value>200000  then
			value=round(value/1000)*1000
		elseif value>50000  then
			value=round(value/500)*500	
		elseif value>1000  then
			value=round(value/100)*100
		elseif value>100 then
			value=round(value/10)*10
		end
		return value
	end
	--add reagents price
	if Game.HouseScreen==2 or Game.HouseScreen==95 then
		if reagentPrices[it.Number] then
			value=reagentPrices[it.Number]
			return value
		end
	end
end

reagentPrices={
	[1041] = 1000,
	[1042] = 2000,
	[1043] = 4000,
	[1044] = 7000,
	[1045] = 12000,
	[1046] = 20000,
	[1047] = 30000,
	[1048] = 40000,
	[1049] = 50000,
	[1050] = 60000,
	[1051] = 80000,
	[1052] = 100000,
	[1053] = 120000,
	[1054] = 140000,
	[1055] = 160000,
	[1056] = 180000,
	[1057] = 200000,
	[1058] = 230000,
	[1059] = 260000,
	[1060] = 300000,
	[1061] = 1250000,
	[1062] = 750000,
	[1063] = 325000,
	[1064] = 6668999,
	[1065] = 2000000,
	[1066] = 1000000,
	[1067] = 3000000,
}
--modify weapon enchant damage

--ENCHANTS HERE
--MELEE bonuses
--{min,max} set only the roll's shape; Coeff = share of the undamped
--item-level weapon damage dealt on average (see enchantDamageRange)
enchantbonusdamage = {}
enchantbonusdamage[4] = {3,4,["Type"]=2,["Coeff"]=0.2}
enchantbonusdamage[5] = {9,12,["Type"]=2,["Coeff"]=0.3}
enchantbonusdamage[6] = {18,24,["Type"]=2,["Coeff"]=0.4}
enchantbonusdamage[7] = {2,5,["Type"]=1,["Coeff"]=0.2}
enchantbonusdamage[8] = {6,15,["Type"]=1,["Coeff"]=0.3}
enchantbonusdamage[9] = {12,30,["Type"]=1,["Coeff"]=0.4}
enchantbonusdamage[10] = {1,6,["Type"]=0,["Coeff"]=0.2}
enchantbonusdamage[11] = {3,18,["Type"]=0,["Coeff"]=0.3}
enchantbonusdamage[12] = {6,36,["Type"]=0,["Coeff"]=0.4}
enchantbonusdamage[13] = {5,5,["Type"]=8,["Coeff"]=0.25}
enchantbonusdamage[14] = {12,12,["Type"]=8,["Coeff"]=0.35}
enchantbonusdamage[15] = {24,24,["Type"]=8,["Coeff"]=0.45}
enchantbonusdamage[39] = {20,40,["Type"]=0,["Coeff"]=0.5}
enchantbonusdamage[46] = {20,40,["Type"]=0,["Coeff"]=0.5}

--min/max roll of a damage enchant: average = Coeff * undamped item-level
--weapon damage (the flat base every weapon shares is not part of that scale)
function enchantDamageRange(it, id)
	local ench=enchantbonusdamage[id]
	local avg=GetWeaponLevelDamage(it)*ench.Coeff
	local mean=(ench[1]+ench[2])/2
	--{min,max} are also a guaranteed floor, so a low item level still deals
	--something; two-handed weapons are owed twice as much of it
	local floorMult=IsTwoHandedWeapon(it) and 2 or 1
	local lo=math.max(avg*ench[1]/mean, ench[1]*floorMult)
	local hi=math.max(avg*ench[2]/mean, ench[2]*floorMult)
	return lo, hi, (lo+hi)/2
end

--legendary 19: enchant/aura damage scales with the highest stat, same
--level normalization as the might damage bonus
function GetLegendary19Mult(pl)
	local id=pl:GetIndex()
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 19) then
		local bonusStat=math.max(pl:GetMight(), pl:GetIntellect(), pl:GetPersonality())
		return 1+GetMightDamageMultiplier(bonusStat, pl.LevelBase)
	end
	return 1
end
--calculate enchant damage
function calcEnchantDamage(pl, it, resistance, rand, isSpell, calcType)
	local ench=enchantbonusdamage[it.Bonus2]
	if not ench or (it.Bonus2==39 and not isSpell) or (it.Bonus2==46 and isSpell) then
		return 0
	end
	local lo, hi, avg=enchantDamageRange(it, it.Bonus2)
	local damage=avg
	if rand then
		damage=math.random(round(lo), round(hi))
	end
	local id=pl:GetIndex()
	local mult=GetLegendary19Mult(pl)
	if calcType~="tooltip" and vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 26) then
		if isSpell then
			critChance, critMult, success=getCritInfo(pl,"spell")
		else
			critChance, critMult, success=getCritInfo(pl)
		end
		if calcType=="damage" and success then
			mult=mult*critMult
		end
		if calcType=="power" then
			mult=mult*(1+math.min(critChance,1)*(critMult-1))
		end
	end
	damage=damage*mult
	damage = damage/2^(resistance%1000/100)
	return damage
end

--weaponenchants and ring enchants checker
enchantList={
	[4] = true ,
	[5] = true ,
	[6] = true ,
	[7] = true ,
	[8] = true ,
	[9] = true ,
	[10] = true ,
	[11] = true ,
	[12] = true ,
	[13] = true ,
	[14] = true ,
	[15] = true ,
	[26] = true ,
	[27] = true ,
	[28] = true ,
	[29] = true ,
	[30] = true ,
	[31] = true ,
	[32] = true ,
	[33] = true ,
	[34] = true ,
	[38] = true ,
	[46] = true ,
	[66] = true ,
	[74] = true ,
	[75] = true ,
	[76] = true ,
	[77] = true ,
	[78] = true ,
	[79] = true ,
	[80] = true ,
}

--BOOK COST

local modifiedBookValues =
{
	[0] = 100,
	[1] = 200,
	[2] = 300,
	[3] = 500,
	[4] = 1000,
	[5] = 2000,
	[6] = 4000,
	[7] = 6000,
	[8] = 8000,
	[9] = 10000,
	[10] = 15000,
}

local modifiedBookValuesMM6 =
{
	[0] = 100,
	[1] = 200,
	[2] = 300,
	[3] = 300,
	[4] = 500,
	[5] = 500,
	[6] = 1000,
	[7] = 2000,
	[8] = 4000,
	[9] = 6000,
	[10] = 8000,
	[11] = 10000,
	[12] = 15000,
}


function events.GameInitialized2()
	--greater heal book 
	Game.ItemsTxt[473].Name="Greater Heal"
	Game.ItemsTxt[1275].Name="Greater Heal"
	Game.ItemsTxt[1989].Name="Greater Heal"
	--add crafting material price
	for i=1,20 do
		Game.ItemsTxt[1040+i].Value=i*1000
	end
	Game.ItemsTxt[1061].Value=30000
	Game.ItemsTxt[1062].Value=20000
	Game.ItemsTxt[1063].Value=15000
	Game.ItemsTxt[1064].Value=100000
	Game.ItemsTxt[1065].Value=60000
	Game.ItemsTxt[1066].Value=25000
	Game.ItemsTxt[1067].Value=80000
	Game.ItemsTxt[1068].Value=200000
	
	for i=0,8 do
		for j=1,11 do
			Game.ItemsTxt[399+11*i+j].Value=modifiedBookValues[j-1]
			Game.ItemsTxt[1201+11*i+j].Value=modifiedBookValues[j-1]
		end
	end
	--MM6
	for i=0,8 do
		for j=1,13 do
			Game.ItemsTxt[1901+13*i+j].Value=modifiedBookValuesMM6[j-1]
		end
	end
	
	for i=1,22 do
		Game.ItemsTxt[476+i].Value=Game.ItemsTxt[476+i].Value*2
	end
	--single books cost increased
	local id={399,1201}
	for i=1,#id do
		Game.ItemsTxt[9+id[i]].Value= 40000
		Game.ItemsTxt[21+id[i]].Value= 40000
		Game.ItemsTxt[22+id[i]].Value= 40000
		Game.ItemsTxt[31+id[i]].Value= 20000
		Game.ItemsTxt[33+id[i]].Value= 60000
		Game.ItemsTxt[55+id[i]].Value= 60000
		Game.ItemsTxt[83+id[i]].Value= 20000
		Game.ItemsTxt[85+id[i]].Value= 40000
		Game.ItemsTxt[86+id[i]].Value= 60000
		Game.ItemsTxt[99+id[i]].Value= 100000
	end
	--MM6
	local id=1901
	Game.ItemsTxt[11+id].Value= 40000
	Game.ItemsTxt[25+id].Value= 40000
	Game.ItemsTxt[26+id].Value= 40000
	Game.ItemsTxt[37+id].Value= 20000
	Game.ItemsTxt[39+id].Value= 60000
	Game.ItemsTxt[65+id].Value= 60000
	Game.ItemsTxt[99+id].Value= 20000
	Game.ItemsTxt[101+id].Value= 40000
	Game.ItemsTxt[102+id].Value= 60000
	Game.ItemsTxt[117+id].Value= 100000
	
end
function getBookTier(id)
	if id>=400 and id<=498 then
		local tier=(id-400)%11+1
		return tier		
	elseif id>=1202 and id<=1300 then
		local tier=(id-1202)%11+1
		return tier
	elseif id>=1902 and id<=2018 then
		local tier=(id-1902)%13+1
		if tier>5 then
			tier=tier-2
		elseif tier>3 then
			tier=tier-1
		end
		return tier
	end
end
function events.CalcItemValue(t)
	if vars.insanityMode then
		local it=t.Item
		if it:T().EquipStat==16 then
			local tier=getBookTier(it.Number)
			if Game.HouseScreen==2 or Game.HouseScreen==95 or (Game.HouseScreen>=110 and Game.HouseScreen<=118) then --shops
				local mult=1
				if tier==11 then
					mult=20
				elseif tier>=8 then
					mult=10
				elseif tier>=5 then
					mult=5
				end
				local price=Game.ItemsTxt[it.Number].Value*mult
				t.Value=price
			end
		end
	end
end
--------------------------------------
--ARTIFACTS REWORK
--------------------------------------
--Increase Base Stats of weapons (handled in line 210)
artWeap1h={500,501,502,503,504,506,507,508,509,510,512,523,524,526,527,528,529,538,539,542,1302,1303,1304,1305,1308,1310,1311,1312,1316,1319,1328,1329,1330,1333,1340,1342,1343,1344,1345,1353,1354,2020,2021,2023,2025,2035,2036,2037,2038,2040,2118,1666,866}
artWeap2h={505,511,525,530,540,541,1309,1320,1351,2022,2024,2039,1667,867}
artArmors={513,514,515,516,517,518,520,522,533,534,1306,1307,1313,1314,1318,1321,1322,1323,1324,1326,1327,1331,1332,1334,1335,1336,1337,1346,1349,1350,1352,2026,2027,2028,2030,2031,2041,2042,2043,2045,2046}

function events.GameInitialized2()
--Artifact upscaler 
	for j=1,#artWeap1h do
		i=artWeap1h[j]
		Game.ItemsTxt[i].Mod1DiceSides = ((Game.ItemsTxt[i].Mod1DiceSides+1)*2)-1
		Game.ItemsTxt[i].Mod2=Game.ItemsTxt[i].Mod2*2
	end
	for j=1,#artWeap2h do
		i=artWeap2h[j]
		Game.ItemsTxt[i].Mod1DiceSides = ((Game.ItemsTxt[i].Mod1DiceSides+1)*3)-1
		Game.ItemsTxt[i].Mod2=Game.ItemsTxt[i].Mod2*3
	end
end

--below commented code might turn useful if I have to modify some artifact text individually
--[[
function events.BuildItemInformationBox(t)
	if t.Description and artifactTextBuilder(t.Item.Number,0) and Game.CurrentPlayer>=0 then
		level=Party[Game.CurrentPlayer].LevelBase
		t.Description=artifactTextBuilder(t.Item.Number,level)
	end
end

require("string")
function artifactTextBuilder(n,lvl)
	lvl=math.min(lvl/80,2.5)
	artifactTxt={
		[2023]= "Heavy, yet seemingly light as a feather in skilled hands, Excalibur confers great might upon its wielder.  Opponents do not easily walk away from blows struck by this legendary weapon.  (Special Powers:  +" .. round(30*lvl) .. " Might)",
		[2024]= "Traditionally carried by the High Druid, but lost during struggles over religious doctrine, Merlin acts as a reservoir of spell power the wielder can draw upon at any time.  Merlin is enchanted with swiftness, and rains blows upon enemies much faster than an ordinary staff. (Special Powers:  Swiftness and +" .. round(40*lvl) .. " Spell Points)",
	}
	
	return artifactTxt[n]
end
]]

function replaceNumber(match, bonusStrength)
	lvl=Party[Game.CurrentPlayer].LevelBase
	lvl=artifactPowerMult(lvl, false, bonusStrength)
    num = tonumber(match)
    if num then
        return tostring(round(num * lvl))
    end
    return match
end

--------------------------------
--ARTIFACTS BASE STATS SCALING--
--------------------------------
ancientWeapons={866,867,1666,1667}
--[[
--increase artifact damage tooltip
function events.CalcStatBonusByItems(t)
	local cs = const.Stats
	if t.Stat==cs.MeleeDamageMin or t.Stat==cs.MeleeDamageMax or t.Stat==cs.MeleeAttack then
		for it in t.Player:EnumActiveItems() do 
			if IsArtifactId(it.Number) then 
				txt=Game.ItemsTxt[it.Number]
				c=txt.EquipStat
				if c<=1 then
					t.Result=t.Result-txt.Mod2+math.ceil(txt.Mod2*artifactPowerMult(t.Player.LevelBase))
					if t.Stat==cs.MeleeDamageMax then
						t.Result=t.Result-(txt.Mod1DiceCount*txt.Mod1DiceSides-txt.Mod1DiceCount)+(txt.Mod1DiceCount*txt.Mod1DiceSides*artifactPowerMult(t.Player.LevelBase))
					end
				end
			end	
		end
	end
	--same for ranged
	if t.Stat==cs.RangedDamageMin or t.Stat==cs.RangedDamageMax or t.Stat==cs.RangedAttack then
		for it in t.Player:EnumActiveItems() do 
			if IsArtifactId(it.Number) then 
				txt=Game.ItemsTxt[it.Number]
				c=txt.EquipStat
				if c==2 then
				t.Result=t.Result-txt.Mod2+math.ceil(txt.Mod2*artifactPowerMult(t.Player.LevelBase))
					if t.Stat==cs.RangedDamageMax then
						t.Result=t.Result-(txt.Mod1DiceCount*txt.Mod1DiceSides-txt.Mod1DiceCount)+(txt.Mod1DiceCount*txt.Mod1DiceSides*artifactPowerMult(t.Player.LevelBase))
					end
				end
			end	
		end
	end
end
]]
------------------------------------------------------------------
--bruteforce fix to items spawning maxcharges more than intended--
------------------------------------------------------------------
function events.BeforeNewGameAutosave()
	vars.hirelingFix=true
	vars.needToFixMaxCharges=true
end

function events.BeforeLoadMap(wasInGame)
	if wasInGame or vars.needToFixMaxCharges == nil then
		return
	end
	vars.needToFixMaxCharges=nil
	for i=0,Party.High do
		for j=1, Party[0].Items.High do
			Party[i].Items[j].MaxCharges=0
			Party[i].Items[j].Charges=0
			Party[i].Items[j].BonusExpireTime=0
			if Party[i].Items[j].Bonus>24 then
				Party[i].Items[j].Bonus=0
			end
		end
	end
end

--[[fix maxcharges if someone is trying to equip on a player
function events.Action(t)
	if t.Action==133 and Game.freeProgression then
		partyLevel=getPartyLevel(4)
		maxItemBolster=(partyLevel)/5+20
		if not Game.freeProgression then
			maxItemBolster=maxItemBolster+10
		end
		--failsafe
		if Mouse.Item and Mouse.Item.Charges==0 and Mouse.Item.Bonus==0 and Mouse.Item.Bonus2==0 and Mouse.Item.MaxCharges>maxItemBolster then
			Mouse.Item.MaxCharges=round(partyLevel/5)
		end
	end
end
]]
--REVERTED AS HIGHER DIFFICULTY WILL LOWER THE DAMAGE!
--vampiric nerf
gotVamp={}
gotBowVamp={}
function events.ItemAdditionalDamage(t)
	vamp=false
	gotVamp[t.Player:GetIndex()]=false
	for i=0,1 do
		it=t.Player:GetActiveItem(i)
		if it then
			vamp=it.Bonus2==41 or it.Bonus2==16
			gotVamp[t.Player:GetIndex()]=gotVamp[t.Player:GetIndex()] or 0
			gotVamp[t.Player:GetIndex()]=gotVamp[t.Player:GetIndex()]/2+1
		end
	end
	if vamp then
		t.Vampiric = false
	else
		gotVamp[t.Player:GetIndex()]=false
	end
	it=t.Player:GetActiveItem(2)
	--bow
	vamp=false
	it=t.Player:GetActiveItem(2)
	if it then
		vamp=it.Bonus2==41 or it.Bonus2==16
	end
	if vamp then
		t.Vampiric = false
		gotBowVamp[t.Player:GetIndex()]=true
	else
		gotBowVamp[t.Player:GetIndex()]=false
	end
end
--leech calculation in zzMAWStatusMsg in scripts/global		

--SHOW POWER/VITALITY CHANGE IN TOOLTIPS
slotMap={
	[0]=1,
	[1]=1,
	[2]=2,
	[3]=3,
	[4]=0,
	[5]=4,
	[6]=5,
	[7]=6,
	[8]=7,
	[9]=8,
	[11]=9,
	[10]=10,
}

--item level

function calculateStatsAdd(item, stats)
	statValue={}
	local enc2Type,enc2Strength=GetEnc2(item)
	for i=1,#stats do
		statValue[i]=0
		--bonus1
		if item.Bonus==stats[i] then
			statValue[i]=statValue[i]+item.BonusStrength
		end
		--bonus2
		if enc2Type==stats[i] then
			statValue[i]=statValue[i]+enc2Strength
		end
		--bonus special
		--maxcharges mult
		MaxCharges=item.MaxCharges
		--if MaxCharges <= 20 then
			mult=MawCore.Formulas.chargesStatMult(MaxCharges)
		--else
		--	mult=2+2*(MaxCharges-20)/20
		--end
		
		b2=bonusEffects[item.Bonus2]
		if b2 then
			if b2.bonusValues then 
				for v=1,#b2.bonusValues do
					if item.Bonus2==48 and bonusEffects[48].bonusValues[v]==stats[i] then
						statValue[i]=statValue[i]+math.floor(b2.statModifier[v]*mult)
					elseif b2.bonusValues[v]==stats[i] then
						statValue[i]=statValue[i]+math.floor(b2.statModifier*mult)
					end
				end
			elseif b2.bonusRange then
				if b2.bonusRange[1]<=stats[i] and b2.bonusRange[2]>=stats[i] then
					statValue[i]=statValue[i]+math.floor(b2.statModifier*mult)
				end
			end
		end
	end	
	return statValue
end


function events.ModifyItemDamage(t)
t.Result=0
end

plItemsStats={}	
for i=0,200 do
	plItemsStats[i]={}
	for v=1,50 do
		plItemsStats[i][v]=0
	end
end
function events.CalcStatBonusByItems(t)
	if Game.CurrentScreen==21 then return end
	t.Result=0
	if t.Stat>=0 and t.Stat<24 then
		if plItemsStats[t.PlayerIndex] then
			t.Result=plItemsStats[t.PlayerIndex][t.Stat+1]
		end
	end
	if statMap[t.Stat] then
		t.Result=plItemsStats[t.PlayerIndex][statMap[t.Stat]]
	end
	if vars.BlackPotions and vars.BlackPotions[t.PlayerIndex] and vars.BlackPotions[t.PlayerIndex][t.Stat+1] then
		t.Result=t.Result+vars.BlackPotions[t.PlayerIndex][t.Stat+1]
	end

	if t.Stat==const.Stats.ArmorClass then
		t.Result=t.Result-Game.GetStatisticEffect(t.Player:GetSpeed())
	end
end

--get artifacts Skills
function events.GetSkill(t)
	local bonus=0
	if t.Skill>=12 and t.Skill<=20 then
		bonus = plItemsStats[t.PlayerIndex][equipSpellSlot[t.Skill]]
	end
	if plItemsStats[t.PlayerIndex] and plItemsStats[t.PlayerIndex][t.Skill+50] then
		bonus = bonus+plItemsStats[t.PlayerIndex][t.Skill+50]
	end
	for it in t.Player:EnumActiveItems() do
		if artifactSpellBonus[it.Number] then
			for i=1,#artifactSpellBonus[it.Number] do
				if t.Skill==artifactSpellBonus[it.Number][i] then
					local baseSkill=SplitSkill(t.Player.Skills[t.Skill])
					bonus = bonus + baseSkill * 0.5
				end
			end
		end
	end
	if t.Skill<=38 then
		t.Result=bonus+t.Player.Skills[t.Skill]
		--cap the skill up to double the base amount
		local s1,m1=SplitSkill(t.Result)
		local s2,m2=SplitSkill(t.Player.Skills[t.Skill])
		t.Result=JoinSkill(math.min(s1,s2*2),m2)
	end
end

function events.GameInitialized2()
	--weapons and armors
    referenceAC = {}
    referenceWeaponAttack = {}

    for i = 0, 2199 do
        local txt = Game.ItemsTxt
        local lookup = 0
        while txt[i].NotIdentifiedName == txt[i + lookup + 1].NotIdentifiedName do
            lookup = lookup + 1
        end

        if (txt[i].Skill >= 8 and txt[i].Skill <= 11) or txt[i].Skill == 40 then
            -- Armors
            referenceAC[i] = txt[i + lookup].Mod2 + txt[i + lookup].Mod1DiceCount
        elseif txt[i].Skill <= 7 or txt[i].Skill==39 then
            -- Weapons
            referenceWeaponAttack[i] = txt[i + lookup].Mod2
        end
    end
	if isRedone and Game.ItemsTxt.High>2200 then
		local txt = Game.ItemsTxt[2205]
		for i=1,5 do
			referenceWeaponAttack[i+2200] = txt.Mod2
		end
	end
end

local bonusBaseEnchantSkill={
	[17]=const.Skills.Alchemy,
	[18]=const.Skills.Repair,
	[19]=const.Skills.DisarmTraps,
	[20]=const.Skills.IdentifyItem,
	[21]=const.Skills.IdentifyMonster,
	[22]=const.Skills.Armsmaster,
	[23]=const.Skills.Dodging,
	[24]=const.Skills.Unarmed,
}

--RECALCULATE THE WHOLE ITEMS EFFECTS
--two phases with the snapshot published between them: MawCore/NOTES.md

--built lazily: the axe lists don't exist yet at init time (NOTES.md)
local artArmorsSet, artWeaponsSet, oneHandedAxesSet, twoHandedAxesSet
local ancientWeaponsSet, meditationBonusItemSet
local function makeSet(list, set)
	set=set or {}
	for i=1,#list do
		set[list[i]]=true
	end
	return set
end
local function buildSets()
	if artArmorsSet then
		return
	end
	artArmorsSet=makeSet(artArmors)
	artWeaponsSet=makeSet(artWeap2h, makeSet(artWeap1h))
	oneHandedAxesSet=makeSet(oneHandedAxes)
	twoHandedAxesSet=makeSet(twoHandedAxes)
	ancientWeaponsSet=makeSet(ancientWeapons)
	meditationBonusItemSet=makeSet(meditationBonusItemMap)
end

--phase 1: armor/shield AC accumulated into the globals armorAC/shieldAC
--(read by the armor-skill scaling and the armor skill tooltips) and tab[10]
local function collectArmorAC(pl, index, it, txt, tab)
	if not ((txt.Skill>=8 and txt.Skill<=11) or (txt.Skill==40 and txt.EquipStat~=12)) then
		return
	end
	local ac=txt.Mod1DiceCount+txt.Mod2
	local acBonus=ac
	if it.MaxCharges>0 and not artArmorsSet[it.Number] then
		acBonus=ac+round(MawCore.Formulas.chargesArmorAC(referenceAC[it.Number], it.MaxCharges))
	end
	--artifacts
	if artArmorsSet[it.Number] then
		acBonus=math.ceil(acBonus*artifactPowerMult(pl.LevelBase, true, it.BonusExpireTime))
	end
	--used later by the armor-skill scaling
	if txt.Skill==8 then
		shieldAC=shieldAC+acBonus
	else
		armorAC=armorAC+acBonus
	end
	if table.find(vars.legendaries[index], 28) then
		acBonus=acBonus*1.5
	end
	tab[10]=tab[10]+acBonus
end

--phase 1: one base enchant (it.Bonus, or the second one from GetEnc2):
--stats 1-10 into tab, resistances 11-16 into vars.normalEnchantResistance,
--skill enchants into the +50 slots (first enchant only, as before)
local function collectEnchant(index, it, bonus, power, tab, isSecond)
	--HP/SP enchants scale on read, not baked into BonusStrength at generation
	if bonus==8 or bonus==9 then
		local mult=GetSlotMult(it)
		power=round(power*(1+math.min(power/50/mult,5)))
	end
	local txt=it:T()
	if txt.EquipStat==5 and txt.Mod2==0 then
		power=math.ceil(power*1.5)
	end
	if bonus<=10 then
		tab[bonus]=tab[bonus]+power
		--legendary power 12: stat enchants echo into their counterparts
		if table.find(vars.legendaries[index], 12) then
			if bonus==1 or bonus==5 then -- might or accuracy
				tab[2]=tab[2]+power*0.4 -- intellect
				tab[3]=tab[3]+power*0.4 -- personality
			elseif bonus==2 or bonus==3 then -- intellect or personality
				tab[1]=tab[1]+power*0.4 -- might
				tab[5]=tab[5]+power*0.4 -- accuracy
			end
		end
	elseif bonus<=16 then
		local res=vars.normalEnchantResistance[index]
		local value=power
		if not isSecond then
			value=power+10
		end
		value=MawCore.Formulas.resistanceEnchantPower(value, GetItemEquipStat(it)==10)
		res[bonus]=math.max(res[bonus] or 0, value)
	elseif not isSecond then
		local slot=bonusBaseEnchantSkill[bonus]+50
		tab[slot]=(tab[slot] or 0)+power
	end
end

--phase 1: equipment effects keyed by the special-enchant id (it.Bonus2)
local function collectEquipEffects(it, tab)
	--fix for double enchants
	if it.Bonus2==62 then
		tab[74]=(tab[74] or 0)+3
		tab[84]=(tab[84] or 0)+3
	end
	if it.Bonus2>0 then
		local bonusData=bonusEffects[it.Bonus2]
		if bonusData then
			local mult=MawCore.Formulas.chargesStatMult(it.MaxCharges) --bolster mult
			if bonusData.bonusRange then
				for i=bonusData.bonusRange[1], bonusData.bonusRange[2] do
					tab[i]=tab[i]+bonusData.statModifier*mult
				end
			elseif bonusData.bonusValues then
				for i=1,3 do
					if bonusData.bonusValues[i] then
						local modifier=bonusData.statModifier
						if type(modifier)=="table" then
							tab[bonusData.bonusValues[i]]=round(tab[bonusData.bonusValues[i]]+modifier[i]*mult)
						else
							tab[bonusData.bonusValues[i]]=round(tab[bonusData.bonusValues[i]]+modifier*mult)
						end
					end
				end
			end
		end
	end
	--equipment spell-school bonuses (slots 26-34, read by events.GetSkill)
	if equipSpellMap[it.Bonus2] then
		tab[it.Bonus2]=(tab[it.Bonus2] or 0)+MawCore.Formulas.chargesSchoolSkill(it.MaxCharges)
	end
	if meditationBonusItemSet[it.Bonus2] then
		local slot=50+const.Skills.Meditation
		tab[slot]=(tab[slot] or 0)+MawCore.Formulas.chargesMeditationSkill(it.MaxCharges)
	end
end

--phase 1: artifact flat stat/skill bonuses, scaled by player level
local function collectArtifactBonuses(pl, it, tab)
	if artifactStatsBonus[it.Number] then
		local mult=artifactPowerMult(pl.LevelBase, false, it.BonusExpireTime)
		for key,value in pairs(artifactStatsBonus[it.Number]) do
			tab[key+1]=tab[key+1]+value*mult
		end
	end
	if artifactSkillBonus[it.Number] then
		local mult=artifactPowerMult(pl.LevelBase, false, it.BonusExpireTime)
		for key,value in pairs(artifactSkillBonus[it.Number]) do
			tab[key+50]=(tab[key+50] or 0)+round(value*mult)
		end
	end
end

--phase 2: weapon attack/damage rows (40-43 melee, 44-47 bow); every skill
--read here sees the published snapshot
local function addWeaponRows(pl, index, it, txt, tab, floorPaid)
	if txt.Skill>7 and txt.Skill~=39 then
		return
	end
	--blaster in the main hand disables the offhand weapon
	local mainWeapon=pl:GetActiveItem(1)
	if not ancientWeaponsSet[it.Number] and mainWeapon and mainWeapon:T().Skill==7 then
		return
	end
	--item-level weapon damage replaces base Mod2/sides and charge scaling:
	--the enchant-driven split goes half as attack/flat and half over the sides,
	--while the weapon's own base skips the split entirely -- its dice part lands
	--only on the sides, its flat part only on attack/flat
	local wDmg,wDice,wFlat=GetWeaponDamage(it)
	local split=wDmg-wDice-wFlat
	local bonus=split/2+wFlat
	local sidesBonus=(split/2+wDice)/math.max(txt.Mod1DiceCount,1)
	if artWeaponsSet[it.Number] then
		if txt.EquipStat<=1 then
			local artifactMult=artifactPowerMult(pl.LevelBase, false, it.BonusExpireTime)
			bonus=math.ceil(txt.Mod2*artifactMult)
			sidesBonus=math.ceil(txt.Mod1DiceSides*artifactMult)
		end
	end
	local skill=txt.Skill
	--minotaur fix
	if oneHandedAxesSet[it.Number] or twoHandedAxesSet[it.Number] then
		skill=3
	end
	--armsmaster
	local s,m = SplitSkill(pl:GetSkill(const.Skills.Armsmaster))
	local requirement=GetArmsmasterSupremeRequirement()
	if pl.Class>=16 and pl.Class<=19 and s>=requirement and m>=4 then
		m=5
	end
	--weapon
	local s2,m2=SplitSkill(pl:GetSkill(skill))
	--bow
	if skill==5 then
		bonus=bonus+s2
	end
	if skill==0 then
		if m2>=4 then
			s,m = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
			s=s/2
		else
			s=0
			m=0
		end
	end
	local mult=1
	if skillDamage[skill] then
		mult=(1+s2*skillDamage[skill]/100)
	end
	local side=math.max(sidesBonus*mult)
	local add=math.max(bonus*mult)
	local armsDmg=armsmasterSkill.Damage[m]*s*mult
	--mino nerf
	local axeCount=0
	local axeDamageMult=1
	for k=0,1 do
		local held=pl:GetActiveItem(k)
		if held then
			if oneHandedAxesSet[held.Number] then
				axeCount=axeCount+1
			elseif twoHandedAxesSet[held.Number] then
				axeCount=axeCount+1
				axeDamageMult=axeDamageMult-0.1
			end
		end
	end
	if axeCount==2 then
		side=side*axeDamageMult
		add=add*axeDamageMult
	end
	--substitute with unarmed if staff
	if skill==0 then
		armsDmg=skillDamage[33]*s*mult
	end
	--make classes such as DK, SERAPH, SHAMAN gain their bonus the armsmaster way
	--(halved together with the armsmasterSkill.Damage nerf)
	--DK
	if table.find(dkClass, pl.Class) then
		local s1, m1=SplitSkill(pl.Skills[const.Skills.Water])
		local s2, m2=SplitSkill(pl.Skills[const.Skills.Dark])
		local bonus=s1*math.min(m1, 3)/4+s2*math.min(m2, 3)/4
		armsDmg=armsDmg+bonus*mult
	end
	--SERAPHIM
	if table.find(seraphClass, pl.Class) then
		local s1, m1=SplitSkill(pl.Skills[const.Skills.Mind])
		local mindBonus=s1*(m1+1)/2
		armsDmg=armsDmg+mindBonus*mult
	end
	--SHAMAN
	if table.find(shamanClass, pl.Class) then
		local s,m=SplitSkill(pl.Skills[const.Skills.Earth])
		armsDmg=armsDmg+s*m/2*mult
	end
	if table.find(assassinClass,pl.Class) then
		local s,m=SplitSkill(pl.Skills[const.Skills.Earth])
		armsDmg=armsDmg+s*(1+m)*mult
		--needed to reduce damage when target is not isolated
		vars.assassinDamage=vars.assassinDamage or {}
		vars.assassinDamage[pl:GetIndex()]=armsDmg
		if vars.MAWSETTINGS.buffRework=="ON" then
			if Party.SpellBuffs[9].ExpireTime>=Game.Time or potionBuffActive(pl, const.Spells.Heroism) then
				local s,m=getBuffSkill(51, pl)
				heroismMult=GetBuffMultiplier(const.Spells.Heroism, s, m)
				vars.assassinDamage[pl:GetIndex()]=vars.assassinDamage[pl:GetIndex()]*(1+heroismMult)
			end
		end
	end
	--split armsmaster between main and offhand
	local item=pl:GetActiveItem(0)
	if item and skill ~= 5 and item:T().Skill~=8 then
		if skill~=8 then
			armsDmg=armsDmg/2
		end
	end
	if skill==7 then
		armsDmg=0
	end
	--floor: a weapon skill point is always worth at least 1 average damage.
	--armsDmg/mult recovers what the percentage is applied to, so the top-up is
	--only what the percentage failed to deliver on a weak weapon
	--the top-up is a skill bonus, so a second weapon of the same skill does not
	--earn it again (the percentage above is per weapon and stays per weapon)
	if skillDamage[skill] and not (floorPaid and floorPaid[skill]) then
		if floorPaid then
			floorPaid[skill]=true
		end
		local scalable=bonus+sidesBonus*txt.Mod1DiceCount/2+armsDmg/mult
		add=add+math.max(s2-scalable*(mult-1),0)
	end
	local totBonus=armsDmg+add
	if skill ~= 5 then
		tab[40] = tab[40] + round(bonus)
		tab[41] = tab[41] + round(bonus)
		tab[42] = tab[42] + txt.Mod1DiceCount+round(totBonus)
		tab[43] = tab[43] + round(side)*txt.Mod1DiceCount+round(totBonus)
	else
		tab[44] = tab[44] + round(bonus)
		tab[45] = tab[45] + round(bonus)
		tab[46] = tab[46] + round(txt.Mod1DiceCount)+add
		tab[47] = tab[47] + round(side)*txt.Mod1DiceCount+add
	end
end

--phase 2: bless adds flat attack to both rows
local function addBless(pl, tab)
	if vars.MAWSETTINGS.buffRework=="ON" then
		if pl.SpellBuffs[1].ExpireTime>=Game.Time then
			local s,m, level=getBuffSkill(46, pl)
			local blessBonus=(buffPower[46].Base[m]+level/4)*(1+buffPower[46].Scaling[m]*s/100)
			tab[40] = tab[40] + blessBonus
			tab[44] = tab[44] + blessBonus
		end
	end
end

--phase 2: armor/shield skill scales the accumulated armorAC/shieldAC into
--AC and resistances; also feeds the armor skill tooltip globals
local function addArmorSkillAC(pl, tab)
	local armorMult=0
	local armorResMult=0
	local bodyS=0
	local bodyM=0
	local it=pl:GetActiveItem(3)
	if it then
		local bodyArmorSkill=it:T().Skill
		bodyS, bodyM=SplitSkill(pl:GetSkill(bodyArmorSkill))
		armorMult=skillItemAC[bodyArmorSkill][bodyM]*bodyS/100
		armorResMult=skillItemRes[bodyArmorSkill][bodyM]*bodyS/100
	end
	local s,m=SplitSkill(pl:GetSkill(const.Skills.Shield))
	local shieldMult=(skillItemAC[const.Skills.Shield][m]*s/100)
	local shieldResMult=(skillItemRes[const.Skills.Shield][m]*s/100)

	itemArmorClassBonus1=math.round(armorAC*armorMult)
	if armorAC>=1 and vars.AusterityMode then
		itemArmorClassBonus1=math.max(itemArmorClassBonus1,math.round(bodyS*bodyM)*2)
	end
	itemArmorClassBonus2=math.round(shieldAC*shieldMult)
	if shieldAC>=1 and vars.AusterityMode then
		itemArmorClassBonus2=math.max(itemArmorClassBonus2,math.round(s*m)*2)
	end
	tab[10]=tab[10]+itemArmorClassBonus1+itemArmorClassBonus2

	itemResistanceBonus1=math.round(armorAC*armorResMult)
	if armorAC>=1 and vars.AusterityMode then
		itemResistanceBonus1=math.max(itemResistanceBonus1,math.round(bodyS*bodyM)*2)
	end
	itemResistanceBonus2=math.round(shieldAC*shieldResMult)
	if shieldAC>=1 and vars.AusterityMode then
		itemResistanceBonus2=math.max(itemResistanceBonus2,math.round(s*m)*2)
	end
	for i=11,16 do
		tab[i]=tab[i]+itemResistanceBonus1+itemResistanceBonus2
	end
end

--phase 2: dragons triple their item-derived stats and resistances
local function applyDragonMult(pl, tab)
	if Game.CharacterPortraits[pl.Face].Race==const.Race.Dragon then
		for i=1,16 do
			tab[i]=tab[i]*3
		end
		if tab[82] then
			tab[82]=tab[82]*3
		end
		if tab[83] then
			tab[83]=tab[83]*3
		end
	end
end

--phase 2: buff-rework party buffs on stats and resistances; returns the
--endurance buff for the HP calculation
local function addBuffStats(pl, tab)
	local enduranceStatBuff=0
	if vars.MAWSETTINGS.buffRework=="ON" then
		local buffList={6,0,17,4,12,1}
		local spellList={3,14,25,36,58,69}
		local spellStat={[3]=2,[14]=6,[25]=7,[36]=4,[46]=5,[58]=3,[69]=1}
		--total current stat per tab index (base + potion bonus; tab adds items)
		local statBase={
			pl.MightBase+pl.MightBonus,
			pl.IntellectBase+pl.IntellectBonus,
			pl.PersonalityBase+pl.PersonalityBonus,
			pl.EnduranceBase+pl.EnduranceBonus,
			pl.AccuracyBase+pl.AccuracyBonus,
			pl.SpeedBase+pl.SpeedBonus,
			pl.LuckBase+pl.LuckBonus,
		}
		local s, m, level=getBuffSkill(85, pl)
		local buff2=(buffPower[85].Base[m]+level/4)
			*(1+buffPower[85].Scaling[m]/100*s/DAY_OF_PROTECTION_SKILL_PENALTY)
		--light: percentage of the total stat
		local s83, m83=getBuffSkill(83, pl)
		local lightPct=0
		if m83>0 then
			lightPct=GetBuffStatPct(s83, true)
		end
		for i=1,6 do
			local buff=0
			local pct=0
			if Party.SpellBuffs[buffList[i]].ExpireTime>=Game.Time or potionBuffActive(pl, spellList[i]) then
				local s, m, level=getBuffSkill(spellList[i], pl)
				buff=(buffPower[spellList[i]].Base[m]+level/4)*(1+buffPower[spellList[i]].Scaling[m]/100*s)
				if m>0 then
					--mastery 0 means no source at all; a low-power potion is a NEGATIVE
					--skill and still has to grant its reduced share
					pct=GetBuffStatPct(s)
				end
			end
			buff4=math.max(buff, buff2)
			if buff4>0 then
				tab[i+10]=tab[i+10]+buff4
			end
			pct=math.max(pct, lightPct)
			local tabID=spellStat[spellList[i]]
			local statBuff=(tab[tabID]+statBase[tabID])*pct
			if i==4 then
				enduranceStatBuff=(tab[tabID]+statBase[tabID])*lightPct
			end
			tab[tabID]=tab[tabID]+statBuff
		end
		--special case for accuracy, as it comes from bless
		local accPct=lightPct
		if pl.SpellBuffs[1].ExpireTime>=Game.Time then
			local s,m=getBuffSkill(46, pl)
			if m>0 then
				accPct=math.max(accPct, GetBuffStatPct(s))
			end
		end
		tab[5]=tab[5]+(tab[5]+statBase[5])*accPct
		--stoneskin
		if Party.SpellBuffs[15].ExpireTime>=Game.Time or potionBuffActive(pl, const.Spells.StoneSkin) then
			local s,m,level=bestBuffSource(38, pl, buffValueFlat)
			acBonus=(buffPower[38].Base[m]+level/4)*(1+buffPower[38].Scaling[m]/100*s)
			tab[10]=tab[10]+acBonus
		end
	end
	return enduranceStatBuff
end

--phase 2: luck feeds all resistances
local function addLuckRes(pl, tab)
	local luck=tab[7]+pl.LuckBase+pl.LuckBonus
	local luckEff=Game.GetStatisticEffect(luck)
	for i=11, 16 do
		tab[i]=tab[i]+luckEff -- -penalty
	end
end

--phase 2: endurance + bodybuilding HP into tab[8]; also fills hpStatsMap
local function addHP(pl, id, tab, enduranceStatBuff)
	local buffBonus=math.max(Party.SpellBuffs[2].Power,pl.SpellBuffs[16].Power)
	if enduranceStatBuff>Party.SpellBuffs[2].Power and enduranceStatBuff>pl.SpellBuffs[16].Power then
		buffBonus=0
	end
	local endurance=tab[4]+pl.EnduranceBase+pl.EnduranceBonus+buffBonus
	local endEff=Game.GetStatisticEffect(endurance)

	local s,m=SplitSkill(pl:GetSkill(const.Skills.Bodybuilding))
	local m2=m
	if m>=4 then
		m2=5
	end
	local BBHP=s*m2
	local level=pl.LevelBonus+pl.LevelBase
	local hpScaling=Game.Classes.HPFactor[pl.Class]
	local baseHP=Game.Classes.HPBase[pl.Class]+hpScaling*(level+endEff+BBHP)
	local fullHP1=baseHP+tab[8]
	local enduranceBonus=fullHP1*endurance/STAT_DAMAGE_DIVISOR
	local fullHP2=fullHP1+enduranceBonus
	local BBBonus=fullHP2*(bodybuildingHP[math.min(m,4)]*0.01*s)
	local bbEndBonus=fullHP2+BBBonus-fullHP1
	--used for stats
	hpStatsMap=hpStatsMap or {}
	hpStatsMap[id]={
		["totalhpFromItems"]=round(tab[8]),
		["totalEnduranceBonus"]=round(enduranceBonus+endEff*hpScaling),
		["totalBBBonus"]=round(BBBonus+s*m2*hpScaling),
		["totalBaseHP"]=round(Game.Classes.HPBase[pl.Class]+hpScaling*level),
	}
	tab[8]=tab[8]+bbEndBonus
end

--phase 2: meditation/personality/enlightenment SP into tab[9]
local function addMana(pl, tab)
	local manaScaling=Game.Classes.SPFactor[pl.Class]
	local totalMana=manaScaling*pl.LevelBase+Game.Classes.SPBase[pl.Class]
	local stat=pl:GetPersonality()
	local effect=Game.GetStatisticEffect(stat)
	local s2,m2=SplitSkill(pl:GetSkill(const.Skills.Meditation))
	if m2>=4 then
		m2=5
	end
	local totalEffect=effect*2+s2*m2
	totalMana=totalMana+manaScaling*totalEffect+tab[9]

	local s,m=SplitSkill(Skillz.get(pl,52))
	local enlightIncrease=totalMana*MawCore.Formulas.enlightenmentManaBonus(s, m)
	tab[9]=tab[9]+enlightIncrease+manaScaling*effect
end

--phase 2: per-slot skill attack bonuses + dodging AC
local function addSlotAttackRows(pl, tab)
	--a weapon skill pays its attack bonus once, not once per slot holding it
	local attackSkillPaid={}
	for i=0,3 do
		local item=pl:GetActiveItem(i)
		if item then
			local skill=item:T().Skill
			--minotaur fix
			if i==1 or i==0 then
				if oneHandedAxesSet[item.Number] or twoHandedAxesSet[item.Number] then
					if i==0 then
						skill=2
					else
						skill=3
					end
				end
			end
			local s,m = SplitSkill(pl:GetSkill(skill))

			if skillAttack[skill] and skillAttack[skill][m] and not attackSkillPaid[skill] then
				attackSkillPaid[skill]=true
				if i~=2 then
					tab[40]=tab[40]+skillAttack[skill][m]*s
				else
					tab[44]=tab[44]+skillAttack[skill][m]*s
				end
			end
			if i==2 and m>=4 then --remove vanilla calculation
				tab[46]=tab[46]-s
				tab[47]=tab[47]-s
			end
		end
		local s,m = SplitSkill(pl:GetSkill(const.Skills.Dodging))
		if (i==3 and item==nil and m>=1) or (m>=3 and item and item:T().Skill==9) then
			tab[10]=tab[10]+skillAC[const.Skills.Dodging][m]*s
		end
	end
end

--phase 2: armsmaster attack, bare-hand unarmed rows, hammerhand; returns
--whether the unarmed rows applied (used by the damage multipliers)
local function addMiscAttack(pl, tab)
	--armsmaster attack
	local s,m = SplitSkill(pl:GetSkill(const.Skills.Armsmaster))
	if m>0 then
		tab[40]=tab[40]+armsmasterSkill.Attack[m]*s
	end
	--unarmed
	local s,m = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
	local s1,m1 = SplitSkill(pl:GetSkill(const.Skills.Staff))
	local unarmed=false
	if (m>=1 and not pl:GetActiveItem(0) and not pl:GetActiveItem(1)) or (m1>=4 and pl:GetActiveItem(1) and pl:GetActiveItem(1):T().Skill==0 ) then
		if m>0 then
			tab[40]=tab[40]+skillAttack[const.Skills.Unarmed][m]*s
			tab[41]=tab[41]+skillDamage[const.Skills.Unarmed]*s
			tab[42]=tab[42]+skillDamage[const.Skills.Unarmed]*s
			tab[43]=tab[43]+skillDamage[const.Skills.Unarmed]*s
			unarmed=true
		end
	end
	local buff=pl.SpellBuffs[6]
	if buff.ExpireTime>Game.Time and not vars.MAWSETTINGS.buffRework=="ON" then --hammerhand buff
		tab[41]=tab[41]+buff.Power
		tab[42]=tab[42]+buff.Power
		tab[43]=tab[43]+buff.Power
	end
	return unarmed
end

--phase 2: weapon skill turns weapon attack into AC/resistances (as a %,
--not flat) and collects the life leech sources
local function addWeaponACRes(pl, index, tab)
	--vampiric code
	lifeLeech=lifeLeech or {}
	lifeLeech[index]=lifeLeech[index] or {}
	lifeLeech[index]["Melee"]=0
	lifeLeech[index]["Ranged"]=0
	lifeLeech[index]["Spell"]=0
	for j=0,2 do
		local it=pl:GetActiveItem(j)
		if it then
			local txt=it:T()
			local skill=txt.Skill
			if skillAC[skill] or skillResistance[skill] then
				local s,m=SplitSkill(pl:GetSkill(skill))
				s=s+10
				local bonus = txt.Mod2
				local bonus2 = referenceWeaponAttack[it.Number]
				local bonusATK = MawCore.Formulas.chargesWeaponBonus(bonus2, it.MaxCharges)

				local bonusBase = bonus + round(bonusATK)
				local bonusAC = round(skillAC[skill][m]*bonusBase/100*s)
				local bonusRes = round(skillResistance[skill][m]*bonusBase/100*s)
				tab[10]=tab[10]+bonusAC
				if skill~=0 then
					for v=11,16 do
						tab[v]=tab[v]+bonusRes
					end
				end
			end
			if it.Bonus2==16 or it.Bonus2==41 then
				if j~=2 then
					lifeLeech[index]["Melee"]=0.1
				else
					lifeLeech[index]["Ranged"]=0.05
				end
			elseif it.Bonus2==40 then
				lifeLeech[index]["Spell"]=0.1
			end

		end
	end
	if vars.MAWSETTINGS.buffRework=="ON" and getBuffSkill(91)>0 then
		lifeLeech[index]["Melee"]=lifeLeech[index]["Melee"]+0.05
		lifeLeech[index]["Ranged"]=lifeLeech[index]["Ranged"]+0.025
		lifeLeech[index]["Spell"]=lifeLeech[index]["Spell"]+0.025
	end
	if Game.CharacterPortraits[pl.Face].Race==const.Race.Vampire then
		local mult=1
		if pl.Class==40 or pl.Class==41 then
			mult=2
		end
		lifeLeech[index]["Melee"]=lifeLeech[index]["Melee"]+0.05*mult
		lifeLeech[index]["Ranged"]=lifeLeech[index]["Ranged"]+0.025*mult
		lifeLeech[index]["Spell"]=lifeLeech[index]["Spell"]+0.025*mult
	end
end

--phase 2: every equipped staff in the party adds resistances to everyone
local function addStaffPartyRes(tab)
	local bonusRes=0
	for i=0, Party.High do
		local it=Party[i]:GetActiveItem(1)
		if it then
			local txt=it:T()
			local skill=txt.Skill
			if skill==0 then
				local s,m=SplitSkill(Party[i]:GetSkill(const.Skills.Staff))
				s=s+10
				local bonus = txt.Mod2
				local bonus2 = referenceWeaponAttack[it.Number]
				local bonusATK = MawCore.Formulas.chargesWeaponBonus(bonus2, it.MaxCharges)

				local bonusBase = bonus + round(bonusATK)
				bonusRes = bonusRes + round(skillResistance[skill][m]*bonusBase/100*s)
			end
		end
	end
	for v=11,16 do
		tab[v]=tab[v]+bonusRes
	end
end

--phase 2: might / heroism / unarmed-buff / shaman-spirit multipliers on the
--damage rows
local function applyDamageMultipliers(pl, tab, unarmed)
	local might=tab[1]+pl.MightBase+pl.MightBonus+Party.SpellBuffs[2].Power
	local mightEffect=Game.GetStatisticEffect(might)
	local mightMult=GetMightDamageMultiplier(might, pl.LevelBase)
	local bonusDamage=mightEffect+Party.SpellBuffs[const.PartyBuff.Heroism].Power
	local heroismMult=0
	local unarmedMult=0
	if vars.MAWSETTINGS.buffRework=="ON" then
		bonusDamage=mightEffect
		if Party.SpellBuffs[9].ExpireTime>=Game.Time or potionBuffActive(pl, const.Spells.Heroism) then
			local s,m=getBuffSkill(51, pl)
			heroismMult=GetBuffMultiplier(const.Spells.Heroism, s, m)
		end
		if pl.SpellBuffs[6].ExpireTime>=Game.Time and unarmed then
			local s,m=getBuffSkill(73)
			unarmedMult=GetBuffMultiplier(const.Spells.Hammerhands, s, m)
		end
	end
	local shamanSpiritMult=0
	if table.find(shamanClass, pl.Class) then
		local s=SplitSkill(pl.Skills[const.Skills.Spirit])
		shamanSpiritMult=s/100
	end

	tab[42]=tab[42]+(tab[42]+bonusDamage)*mightMult
	tab[42]=tab[42]+(tab[42]+bonusDamage)*heroismMult
	tab[42]=tab[42]+(tab[42]+bonusDamage)*unarmedMult
	tab[42]=tab[42]+(tab[42]+bonusDamage)*shamanSpiritMult

	tab[43]=tab[43]+(tab[43]+bonusDamage)*mightMult
	tab[43]=tab[43]+(tab[43]+bonusDamage)*heroismMult
	tab[43]=tab[43]+(tab[43]+bonusDamage)*unarmedMult
	tab[43]=tab[43]+(tab[43]+bonusDamage)*shamanSpiritMult

	tab[46]=tab[46]+(tab[46]+bonusDamage)*mightMult
	tab[47]=tab[47]+(tab[47]+bonusDamage)*mightMult
end

function itemStats(index)
	if index==-1 or index==nil then
		return 0
	end
	local id=0
	for i=0,Party.High do
		if Party[i]:GetIndex()==index then
			id=i
		end
	end
	if id>Party.High then return end
	local pl=Party[id]
	buildSets()

	local tab={}
	for i=1,50 do
		tab[i]=0
	end
	--used for armor skill
	shieldAC=0
	armorAC=0
	vars.normalEnchantResistance=vars.normalEnchantResistance or {}
	vars.normalEnchantResistance[index]={}
	for i=11,16 do
		vars.normalEnchantResistance[index][i]=0
	end
	--iterate once for legendaries
	vars.legendaries=vars.legendaries or {}
	vars.legendaries[index]={}
	for it in pl:EnumActiveItems() do
		if HasLegendaryAffix(it) then
			table.insert(vars.legendaries[index], GetLegendaryAffix(it))
		end
	end

	--phase 1: collect everything that does not depend on effective skills
	local gotShieldEnchant=false
	for it in pl:EnumActiveItems() do
		updateCelestialItem(it,pl)
		--maxcharges fix for moon cloak
		if it.Number==1349 or it.Number==1350 then
			it.MaxCharges=0
		end
		local txt=it:T()
		collectArmorAC(pl, index, it, txt, tab)
		if it.Bonus>0 then
			collectEnchant(index, it, it.Bonus, it.BonusStrength, tab, false)
		end
		if HasEnc2(it) then
			local bonus,power=GetEnc2(it)
			collectEnchant(index, it, bonus, power, tab, true)
		end
		collectEquipEffects(it, tab)
		collectArtifactBonuses(pl, it, tab)
		if it.Bonus2==36 then
			gotShieldEnchant=true
		end
	end
	--special enchant
	vars.shieldEnchant=vars.shieldEnchant or {}
	vars.shieldEnchant[index]=gotShieldEnchant

	--PUBLISH: from here on pl:GetSkill sees the just-collected item skill
	--bonuses instead of the previous snapshot's
	plItemsStats[index]=tab

	--phase 2: everything computed from effective skills
	local floorPaid={}
	for it in pl:EnumActiveItems() do
		addWeaponRows(pl, index, it, it:T(), tab, floorPaid)
	end
	addBless(pl, tab)
	addArmorSkillAC(pl, tab)
	applyDragonMult(pl, tab)
	local enduranceStatBuff=addBuffStats(pl, tab)
	addLuckRes(pl, tab)
	addHP(pl, id, tab, enduranceStatBuff)
	addMana(pl, tab)
	addSlotAttackRows(pl, tab)
	local unarmed=addMiscAttack(pl, tab)
	--necessary to load attack speed and damage multiplier
	pl:GetAttackDelay()
	pl:GetAttackDelay(true)
	addWeaponACRes(pl, index, tab)
	addStaffPartyRes(tab)
	applyDamageMultipliers(pl, tab, unarmed)
	return tab
end

equipSpellMap={
	[30] = const.Skills.Fire,
	[26] = const.Skills.Air,
	[34] = const.Skills.Water,
	[29] = const.Skills.Earth,
	[33] = const.Skills.Spirit,
	[32] = const.Skills.Mind,
	[27] = const.Skills.Body,
	[31] = const.Skills.Light,
	[28] = const.Skills.Dark,
}
--reverse map: skill -> plItemsStats slot; the GetSkill hook runs constantly,
--so no table.find there
equipSpellSlot={}
for slot, skill in pairs(equipSpellMap) do
	equipSpellSlot[skill]=slot
end

meditationBonusItemMap={38,47,55,66}

statMap={
	[const.Stats.FireMagic]=30,
	[const.Stats.AirMagic]=26,
	[const.Stats.WaterMagic]=34,
	[const.Stats.EarthMagic]=29,
	[const.Stats.SpiritMagic]=33,
	[const.Stats.MindMagic]=32,
	[const.Stats.BodyMagic]=27,
	[const.Stats.LightMagic]=31,
	[const.Stats.DarkMagic]=28,
	[const.Stats.MeleeAttack]=40,
	[const.Stats.MeleeDamageBase]=41,
	[const.Stats.MeleeDamageMin]=42,
	[const.Stats.MeleeDamageMax]=43,
	[const.Stats.RangedAttack]=44,
	[const.Stats.RangedDamageBase]=45,
	[const.Stats.RangedDamageMin]=46,
	[const.Stats.RangedDamageMax]=47,
	
}

--artifacts stats bonus
--------------------------------
---- Stat bonuses
artifactStatsBonus={}
artifactStatsBonus[500] = {	[const.Stats.Accuracy] = 60}
artifactStatsBonus[501] = {	[const.Stats.Might] = 60}
artifactStatsBonus[502] = {	[const.Stats.AirResistance] = 100}
artifactStatsBonus[503] = {	[const.Stats.Endurance] = 40,
							[const.Stats.Luck] = 40}
artifactStatsBonus[504] = {	[const.Stats.Might] = 100}
artifactStatsBonus[505] = {	[const.Stats.FireResistance] = 100}
artifactStatsBonus[506] = {	[const.Stats.Endurance] = 60}
artifactStatsBonus[507] = {[const.Stats.Might] 		= 20,
							[const.Stats.Intellect] 	= 20,
							[const.Stats.Personality] 	= 20,
							[const.Stats.Speed] 		= 20,
							[const.Stats.Accuracy]		= 20,
							[const.Stats.Endurance] 	= 20,
							[const.Stats.Luck]			= 20}
artifactStatsBonus[509] = {	[const.Stats.Personality]   = 80}
artifactStatsBonus[510] = { [const.Stats.Might] 		= 30,
							[const.Stats.Endurance] 	= 30}		
artifactStatsBonus[512] = { [const.Stats.Accuracy] 		= 50}						
artifactStatsBonus[513] = { [const.Stats.Endurance] 	= 70}						
artifactStatsBonus[514] = { [const.Stats.Might] 		= 20,
							[const.Stats.Intellect] 	= 20,
							[const.Stats.Personality] 	= 20,
							[const.Stats.Speed] 		= 20,
							[const.Stats.Accuracy]		= 20,
							[const.Stats.Endurance] 	= 20,
							[const.Stats.Luck]			= 20,
							[const.Stats.FireResistance]	= 20,
							[const.Stats.AirResistance]		= 20,
							[const.Stats.WaterResistance]	= 20,
							[const.Stats.EarthResistance]	= 20,
							[const.Stats.MindResistance]	= 20,
							[const.Stats.BodyResistance]	= 20,}	
artifactStatsBonus[515] = { [const.Stats.Speed] 		= 60,							
							[const.Stats.Accuracy] 		= 60}
artifactStatsBonus[518] = { [const.Stats.Speed] 		= 60}
artifactStatsBonus[519] = { [const.Stats.FireResistance]	= 40,
							[const.Stats.AirResistance]		= 40,
							[const.Stats.WaterResistance]	= 40,
							[const.Stats.EarthResistance]	= 40}
artifactStatsBonus[520] = { [const.Stats.Personality]	= 60,
							[const.Stats.Intellect]		= 60}	
artifactStatsBonus[521] = {	[const.Stats.Intellect] = 100}							
artifactStatsBonus[522] = { [const.Stats.Intellect]	= 40,
							[const.Stats.FireResistance]	= 10,
							[const.Stats.AirResistance]		= 10,
							[const.Stats.WaterResistance]	= 10,
							[const.Stats.EarthResistance]	= 10,
							[const.Stats.MindResistance]	= 10,
							[const.Stats.BodyResistance]	= 10}
artifactStatsBonus[523] = { [const.Stats.Speed]	= 100,
							[const.Stats.WaterResistance]	= -50,
							[const.Stats.Personality]	= -15}
artifactStatsBonus[524] = {	[const.Stats.Speed]	= 70,
							[const.Stats.Accuracy]	= 70,
							[const.Stats.ArmorClass]	= -20}						
artifactStatsBonus[525] = {	
							[const.Stats.Accuracy]	= 120,		
							[const.Stats.Speed]	= -20}		
artifactStatsBonus[526] = {	[const.Stats.Might]	= 70,
							[const.Stats.Accuracy]		= 70,
							[const.Stats.Personality]	= 50,
							[const.Stats.Intellect]	= 50}		
artifactStatsBonus[527] = {	[const.Stats.Might]	= 80,
							[const.Stats.Luck]	= -40}
artifactStatsBonus[528]	= {	[const.Stats.WaterResistance]	= 140,
							[const.Stats.FireResistance]	= -40}		
artifactStatsBonus[529]	= {	[const.Stats.Might]	= 100,
							[const.Stats.Accuracy]	= 100}		
artifactStatsBonus[530]	= {	[const.Stats.ArmorClass]	= -40}		
artifactStatsBonus[531]	= {	[const.Stats.Accuracy]	= 100,
							[const.Stats.ArmorClass]	= -20}		
artifactStatsBonus[532]	= {	[const.Stats.Might]	= 60,
							[const.Stats.Speed]	= 60,}		
artifactStatsBonus[533]	= {	[const.Stats.Intellect]	= 140,
							[const.Stats.Personality] = 140,
							[const.Stats.MindResistance]	= -100,
							[const.Stats.BodyResistance]	= -100}		
artifactStatsBonus[534]	= {	[const.Stats.Luck]	= -15,
							[const.Stats.Endurance]	= 50}
artifactStatsBonus[535]	= {	[const.Stats.Intellect]	= 60,
							[const.Stats.Endurance]	= -20}			
artifactStatsBonus[536]	= {	[const.Stats.Luck]	= 100,
							[const.Stats.Personality]	= -50}		
artifactStatsBonus[537]	= {	[const.Stats.Might]	= 120,
							[const.Stats.Accuracy]	= -30,
							[const.Stats.ArmorClass]	= -15}							
							

-- Cycle of life
artifactStatsBonus[543] = {	[const.Stats.Endurance] = 20}


-- Puck
artifactStatsBonus[1302] = {[const.Stats.Speed]	= 80}
-- Iron Feather
artifactStatsBonus[1303] = {[const.Stats.Might]	= 80}
-- Wallace
artifactStatsBonus[1304] = {[const.Stats.Personality] = 40}
-- Corsair
artifactStatsBonus[1305] = {[const.Stats.Luck] = 80}
-- Governor's Armor
artifactStatsBonus[1306] = {[const.Stats.Might] 		= 20,
							[const.Stats.Intellect] 	= 20,
							[const.Stats.Personality] 	= 20,
							[const.Stats.Speed] 		= 20,
							[const.Stats.Accuracy]		= 20,
							[const.Stats.Endurance] 	= 20,
							[const.Stats.Luck]			= 20}
-- Yoruba
artifactStatsBonus[1307] = {[const.Stats.Endurance] 	= 100}
-- Splitter
artifactStatsBonus[1308] = {[const.Stats.FireResistance] = 65000}
-- Ullyses
artifactStatsBonus[1312] = {[const.Stats.Accuracy] = 80}
-- Seven League Boots
artifactStatsBonus[1314] = {[const.Stats.Speed] = 80}
-- Mash
artifactStatsBonus[1316] = {[const.Stats.Might] 		= 150,
							[const.Stats.Intellect] 	= -40,
							[const.Stats.Personality] 	= -40,
							[const.Stats.Speed] 		= -40}
-- Hareck's Leather
artifactStatsBonus[1318] = {[const.Stats.Luck]				= 100,
							[const.Stats.FireResistance] 	= -20,
							[const.Stats.AirResistance] 	= -20,
							[const.Stats.WaterResistance] 	= -20,
							[const.Stats.EarthResistance] 	= -20,
							[const.Stats.MindResistance] 	= -20,
							[const.Stats.BodyResistance] 	= -20,}
-- Amuck
artifactStatsBonus[1320] = {[const.Stats.Might] 		= 100,
							[const.Stats.Endurance] 	= 100,
							[const.Stats.ArmorClass] 	= -15}
-- Glory shield
artifactStatsBonus[1321] = {[const.Stats.BodyResistance] = -20,
							[const.Stats.MindResistance] = -20}
-- Kelebrim
artifactStatsBonus[1322] = {[const.Stats.Endurance] = 100,
							[const.Stats.EarthResistance] = -60}
-- Taledon's Helm
artifactStatsBonus[1323] = {
							[const.Stats.Might] = 45,
							[const.Stats.Personality] = 45,
							[const.Stats.Luck] = -40
}
-- Scholar's Cap
artifactStatsBonus[1324] = {[const.Stats.Endurance] = -50}
-- Phynaxian Crown
artifactStatsBonus[1325] = {
							[const.Stats.Personality] = 30,
							[const.Stats.ArmorClass] = -20,
							[const.Stats.WaterResistance] = 100
}
-- Titan's Belt
artifactStatsBonus[1326] = {
							[const.Stats.Might] = 115,
							[const.Stats.Speed] = -40
}
-- Twilight
artifactStatsBonus[1327] = {
							[const.Stats.Speed] = 50,
							[const.Stats.Luck] = 50,
							[const.Stats.FireResistance] = -30,
							[const.Stats.AirResistance] = -30,
							[const.Stats.WaterResistance] = -30,
							[const.Stats.EarthResistance] = -30,
							[const.Stats.MindResistance] = -30,
							[const.Stats.BodyResistance] = -30,
}
-- Ania Selving
artifactStatsBonus[1328] = {[const.Stats.ArmorClass] = -25,
							[const.Stats.Accuracy] = 150}
-- Justice
artifactStatsBonus[1329] = {[const.Stats.Speed] = -40}
-- Mekorig's hammer
artifactStatsBonus[1330] = {[const.Stats.Might] = 75,
							[const.Stats.AirResistance] = -100}
							-- Hermes's Sandals
artifactStatsBonus[1331] = {[const.Stats.Speed] = 100,
							[const.Stats.Accuracy] = 50,
							[const.Stats.AirResistance] = 100}
-- Cloak of the sheep
artifactStatsBonus[1332] = {[const.Stats.Intellect] 	= -20,
							[const.Stats.Personality] 	= -20}
-- Elfbane
artifactStatsBonus[1333] = {[const.Stats.Speed] = 100}
-- Mind's Eye
artifactStatsBonus[1334] = {
							[const.Stats.Intellect] = 30,
							[const.Stats.Personality] = 30
}
-- Elven Chainmail
artifactStatsBonus[1335] = {[const.Stats.Speed] = 30,
							[const.Stats.Accuracy] = 30
}
-- Forge Gauntlets
artifactStatsBonus[1336] = {
							[const.Stats.Might] = 30,
							[const.Stats.Endurance] = 30,
							[const.Stats.FireResistance] = 60
}
-- Hero's belt
artifactStatsBonus[1337] = {[const.Stats.Might] = 30}
-- Lady's Escort ring
artifactStatsBonus[1338] = {[const.Stats.FireResistance]	= 10,
							[const.Stats.AirResistance]		= 10,
							[const.Stats.WaterResistance]	= 10,
							[const.Stats.EarthResistance]	= 10,
							[const.Stats.MindResistance]	= 10,
							[const.Stats.BodyResistance]	= 10,}
-- Thor
artifactStatsBonus[2021] = {[const.Stats.Might] = 75}
-- Conan
artifactStatsBonus[2022] = {[const.Stats.Accuracy] = 150}
-- Excalibur
artifactStatsBonus[2023] = {[const.Stats.Might] = 100}
-- Merlin
artifactStatsBonus[2024] = {[const.Stats.Intellect] = 120,
							[const.Stats.Personality] = 120,
							[const.Stats.SP] = 200,
							}
-- Percival
artifactStatsBonus[2025] = {[const.Stats.Speed] = 40}
-- Galahad
artifactStatsBonus[2026] = {[const.Stats.Endurance] = 100}
-- Pellinore
artifactStatsBonus[2027] = {[const.Stats.Endurance] = 120}
-- Valeria
artifactStatsBonus[2028] = {[const.Stats.Accuracy] = 80}
-- Arthur
artifactStatsBonus[2029] = {
							[const.Stats.Might] = 20,
							[const.Stats.Intellect] = 20,
							[const.Stats.Personality] = 20,
							[const.Stats.Endurance] = 20,
							[const.Stats.Accuracy] = 20,
							[const.Stats.Speed] = 20,
							[const.Stats.Luck] = 20,
							[const.Stats.SP] = 100
}
-- Pendragon
artifactStatsBonus[2030] = {[const.Stats.Luck] = 60}
-- Lucius
artifactStatsBonus[2031] = {[const.Stats.Speed] = 70}
-- Guinevere
artifactStatsBonus[2032] = {[const.Stats.SP] = 100}
-- Igraine
artifactStatsBonus[2033] = {[const.Stats.SP] = 100}
-- Morgan
artifactStatsBonus[2034] = {[const.Stats.SP] = 80}
-- Hades
artifactStatsBonus[2035] = {[const.Stats.Luck] = 60}
-- Ares
artifactStatsBonus[2036] = {[const.Stats.FireResistance] = 100}
-- Poseidon
artifactStatsBonus[2037] = {[const.Stats.Might] 	 = 40,
							[const.Stats.Endurance]  = 40,
							[const.Stats.Accuracy] 	 = 40,
							[const.Stats.Speed] 	 = -10,
							[const.Stats.ArmorClass] = -10}
-- Cronos
artifactStatsBonus[2038] = {[const.Stats.Luck] 	 	= -60,
							[const.Stats.Endurance] = 120}
-- Hercules
artifactStatsBonus[2039] = {[const.Stats.Might] 	= 100,
							[const.Stats.Endurance] = 60,
							[const.Stats.Intellect]	= -30}
-- Artemis
artifactStatsBonus[2040] = {[const.Stats.FireResistance] 	= -20,
							[const.Stats.AirResistance] 	= -20,
							[const.Stats.WaterResistance] 	= -20,
							[const.Stats.EarthResistance] 	= -20}
-- Apollo
artifactStatsBonus[2041] = {[const.Stats.Endurance]			= -30,
							[const.Stats.FireResistance] 	= 40,
							[const.Stats.AirResistance] 	= 40,
							[const.Stats.WaterResistance] 	= 40,
							[const.Stats.EarthResistance] 	= 40,
							[const.Stats.MindResistance] 	= 40,
							[const.Stats.BodyResistance] 	= 40,
							[const.Stats.Luck]				= 20}
-- Zeus
artifactStatsBonus[2042] = {[const.Stats.Endurance] 		= 50,
							[const.Stats.Personality] 		= 50,
							[const.Stats.Luck] 		= 50,
							[const.Stats.Intellect] = -50}
-- Aegis
artifactStatsBonus[2043] = {[const.Stats.Speed] = -20,
							[const.Stats.Luck] 	= 100}
-- Odin
artifactStatsBonus[2044] = {
							[const.Stats.Speed] = -40,
							[const.Stats.FireResistance] = 60,
							[const.Stats.AirResistance] = 60,
							[const.Stats.WaterResistance] = 60,
							[const.Stats.EarthResistance] = 60
						}
-- Atlas
artifactStatsBonus[2045] = {
							[const.Stats.Might] = 120,
							[const.Stats.Speed] = -40
						}
-- Hermes
artifactStatsBonus[2046] = {
							[const.Stats.Speed] = 140,
							[const.Stats.Accuracy] = -40
						}
-- Aphrodite
artifactStatsBonus[2047] = {[const.Stats.Personality] = 100,
							[const.Stats.Luck] 	= -40}
-- Athena
artifactStatsBonus[2048] = {[const.Stats.Intellect] = 100,
							[const.Stats.Might] 	= -40}
-- Hera
artifactStatsBonus[2049] = {[const.Stats.HP] = 100,
							[const.Stats.SP] = 100,
							[const.Stats.Luck] = 50,
							[const.Stats.Personality] = -50}

--SKILLS ARTEFACTS
---- Skill bonuses
artifactSkillBonus={}
artifactSkillBonus[502] =	{	[const.Skills.Armsmaster] = 7}
artifactSkillBonus[512] =	{	[const.Skills.Bow] = 4}
artifactSkillBonus[517] =	{	[const.Skills.DisarmTraps] = 8,
								[const.Skills.Bow] = 8,
								[const.Skills.Armsmaster] = 8}
artifactSkillBonus[531] =	{	[const.Skills.Bow] = 4}
artifactSkillBonus[535] =	{	[const.Skills.Alchemy] = 5}
-- Hero's belt
artifactSkillBonus[1337] =	{	[const.Skills.Armsmaster] = 5}
-- Wallace
artifactSkillBonus[1304] =	{	[const.Skills.Armsmaster] = 10}
-- Corsair
artifactSkillBonus[1305] =	{	[const.Skills.DisarmTraps] = 10}
-- Hands of the Master
artifactSkillBonus[1313] =	{	[const.Skills.Unarmed] = 10,
								[const.Skills.Dodging] = 10}
-- Ethric's Staff
artifactSkillBonus[1317] =	{	[const.Skills.Meditation] = 8}
-- Hareck's Leather
artifactSkillBonus[1318] =	{	[const.Skills.Dagger] = 5,
								[const.Skills.Unarmed] = 5,}
-- Old Nick
artifactSkillBonus[1319] =	{	[const.Skills.DisarmTraps] = 5}
-- Glory shield
artifactSkillBonus[1321] =	{	[const.Skills.Shield] = 5}
-- Scholar's Cap
artifactSkillBonus[1324] = {	[const.Skills.Learning] = 15}
-- Ania Selving
artifactSkillBonus[1328] =	{	[const.Skills.Bow] = 5}
-- Pendragon
artifactSkillBonus[2030] =	{	[const.Skills.Dagger] = 5,
								[const.Skills.DisarmTraps] = 10}
-- Hades
artifactSkillBonus[2035] =	{	[const.Skills.DisarmTraps] = 10}

--artifacts HP/SP regen
artifactHpRegen={509,520,1131,1337}
artifactSpRegen={513,1131,1334}

--artifact spells
artifactSpellBonus={}
-- Eclipse
artifactSpellBonus[516] =	{16, 18, 17}
-- Crown of final Dominion
artifactSpellBonus[521] =	{20}
-- Staff of Elements
artifactSpellBonus[530] =	{12, 13, 14, 15}
-- Ring of Fusion
artifactSpellBonus[535] =	{14}
-- Seven League Boots
artifactSpellBonus[1314] =	{14}
-- Ruler's ring
artifactSpellBonus[1315] =	{17, 20}
-- Ethric's Staff
artifactSpellBonus[1317] =	{20}
-- Glory shield
artifactSpellBonus[1321] =	{16}
-- Taledon's Helm
artifactSpellBonus[1323] = {19}
-- Phynaxian Crown
artifactSpellBonus[1325] = {12}
-- Justice
artifactSpellBonus[1329] =	{17, 18}
-- Mekorig's hammer
artifactSpellBonus[1330] =	{16}
-- Ghost ring
artifactSpellBonus[1347] =	{16}
--faerie ring
artifactSpellBonus[1348] =	{13}
-- Guinevere
artifactSpellBonus[2032] =	{19, 20}
-- Igraine
artifactSpellBonus[2033] =	{16, 18, 17}
-- Morgan
artifactSpellBonus[2034] =	{12, 13, 14, 15}


--refresh stats
function events.AfterLoadMap()
	mawRefresh("all")
end
function events.Action(t)
	--if t.Action==110 or t.Action==115 or t.Action==133 then
		if Game.CurrentPlayer==-1 or Game.CurrentPlayer>Party.High then return end
		local id=Party[Game.CurrentPlayer]:GetIndex()
		RunNextTick(function()
			mawRefresh(id)
		end)
	--end
end
function mawRefresh(i)
	if i=="all" then
		for v=0,Party.High do
			local id=Party[v]:GetIndex()
			plItemsStats[id]=itemStats(id)
		end
		return
	end
	plItemsStats[i]=itemStats(i)
end

local stats={"Might", "Intellect", "Personality", "Endurance", "Accuracy", "Speed", "LUCK", "HP", "SP", "ArmorClass", "Fire", "Air", "Water", "Earth", "Mind", "Body"}
function mawPlayerBaseStats(index)
	local pl=Party[index]
	local tab=plItemsStats[index]
	--set all to 0
	for i=1,7 do
		tab[i]=pl[stats[i] .. "Base"] + pl[stats[i]  .. "Bonus"]
	end
	for i=8,9 do
		tab[i]=0
	end
	tab[10]=pl[ArmorClassBonus]
	for i=11,16 do
		tab[i]=pl[stats[i] .. "ResistanceBase"] + pl[stats[i]  .. "ResistanceBonus"]
	end
end


--randomize item shop

function events.KeyDown(t)
	--base numbers
	if t.Key==82 then
		refreshItems()
	end	
end

shopArmors={31,32,33,34,5}
function refreshItems()
	id=Game:GetCurrentHouse()
	if id==nil or id>=110 then return end
	if isRedone then
		if id>35 then
			id=id+2
		end
		if id>75 then
			id=id+2
		end
	end
	if Game.HouseScreen==2 then
		h=Game.ShopItems[id]
	elseif Game.HouseScreen==95 then
		h=Game.ShopSpecialItems[id]
	else 
		return
	end
	
	local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	local partyLevel=getPartyLevel(4)-math.min(vars.MMLVL[currentWorld]/2, 54)
	--calculate power
	local currentLevel=vars.MMLVL[currentWorld]
	strength=math.floor(currentLevel/18)+2
	strength=math.min(strength,5)
	partyLevel1=GetTier(partyLevel)
	cost=(partyLevel1+strength)^2*250
	if cost>Party.Gold then
		return
	else
		Party.Gold=Party.Gold-cost
	end
	--check for shop
	if not vars.shopType[id] then
		mawStoreShop()
	end
	
	for i=0,11 do
		if math.random(1,18)<currentLevel%18 then
			strength=math.min(strength+1,5)
		end
		if h[i].Number~=0 then
			itemType= h[i]:T().EquipStat
			if itemType==3 or itemType==4 then
				it=math.random(1,#shopArmors)
				h[i]:Randomize(strength, shopArmors[it])
			else
				rnd=math.random(1,#vars.shopType[id])
				h[i]:Randomize(strength, vars.shopType[id][rnd])
			end
			h[i].Identified = true
			Game.GuildItemIconPtr[i] = Game.IconsLod:LoadBitmapPtr(h[i]:T().Picture)
		end
	end
end

--get house info and fix broken prices
function events.ShopItemsGenerated(t)
	mawStoreShop()
end

--attempt to fix price overflow, apparently due to gm merchant
function events.GetMerchantTotalSkill(t)
	if merchantFix then
		t.Result=100
	end
end


function mawStoreShop()

	--broken price fix
	id=Game:GetCurrentHouse()
	merchantFix=false
	for i=0,Party.High do
		s,m=SplitSkill(Party[i].Skills[const.Skills.Merchant])
		if s>15 or m>=4 then
			Game.Houses[id].Val=1
			merchantFix=true
		end
	end
	if Game.HouseScreen==2 or Game.HouseScreen==95 then
		Game.ShowStatusText("Press R to refresh new items (20000 gold)") --not working
	else 
		return
	end
	if id>133 then return end
	if isRedone then
		if id>35 then
			id=id+2
		end
		if id>75 then
			id=id+2
		end
	end
	--check item types to determine what shop is this
	h=Game.ShopSpecialItems[id]
	s=Game.ShopItems[id]
	vars.shopType={}
	vars.shopType[id]={}
	for i=0,11 do
		itemType=h[i]:T().EquipStat
		if h[i].Number>0 and itemType~=3 and itemType~=4 and itemType~=19 then
			itemType=h[i]:T().EquipStat+1
			if not table.find(vars.shopType[id],itemType) then
				table.insert(vars.shopType[id],itemType)
			end
		end
		itemType=s[i]:T().EquipStat
		if s[i].Number>0 and itemType~=3 and itemType~=4 and itemType~=19 then
			itemType=s[i]:T().EquipStat+1
			if not table.find(vars.shopType[id],itemType) then
				table.insert(vars.shopType[id],itemType)
			end
		end
	end
end

--maw artifact scaling calculation
function artifactPowerMult(level, isAC, customLevel)
	if customLevel>=1 then
		level = math.max(customLevel * 1.5, customLevel + 50)
	end
	local bol=math.max(Game.BolsterAmount, 100)
	bol=(bol/100-1)/20+1
	--[[
	if vars.insanityMode then
		bol=bol*4/3
	end
	]]
	local cap=550
	if vars.madnessMode then
		cap=900
	end
	if customLevel>=1 then
		cap=1500
	end
	local mult=(math.min(level,cap)/200+0.75)*bol
	if isAC then
		mult=(math.min(level,cap)/(250)+0.75)*bol
	end
	return mult
end

playerToPartyBuff={
	[0]=0,
	[2]=1,
	[3]=4,
	[5]=6,
	[8]=9,
	[9]=12,
	[14]=15,
	[15]=2,
	[16]=2,
	[17]=2,
	[18]=2,
	[19]=2,
	[20]=2,
	[21]=2,
	[22]=17,
}
statToPlayerbuff={
	[10]=0,
	[15]=2,
	[13]=3,
	[11]=5,
	[27]=8,
	[28]=8,
	[14]=9,
	[9]=14,
	[4]=15,
	[3]=16,
	[1]=17,
	[6]=18,
	[0]=19,
	[2]=20,
	[5]=21,
	[12]=22,
}

--
function events.CalcStatBonusByItems(t)
	if statToPlayerbuff[t.Stat] then
		local stat1=statToPlayerbuff[t.Stat]
		if t.Player.SpellBuffs[stat1].Skill==5 then
			return 
		end
		local power1=t.Player.SpellBuffs[stat1].Power
		local stat2=playerToPartyBuff[stat1]
		local power2=Party.SpellBuffs[stat2].Power
		if power1>=power2 then
			t.Player.SpellBuffs[stat1].Power=t.Player.SpellBuffs[stat1].Power-power2
			t.Player.SpellBuffs[stat1].Skill=5
		else
			t.Player.SpellBuffs[stat1].Power=0
		end
	end
end

--items have an item level requirement
function events.CanWearItem(t)
	local it=Mouse.Item
	if vars.Mode==2 and not it.Identified then
		t.Available=false
	end
	if IsEnchantableItem(it) then 
		--check if equippable
		local plLvl=Party[t.PlayerId].LevelBase
		if plLvl<GetLevelRquirement(it) then
			t.Available=false
		end
	end	
end

--chests blocked if trapped
function events.CanOpenChest(t)
	if vars.Mode==2 then
		if Map.Chests[t.ChestId].Trapped then return end
		local skillRequired=Game.MapStats[Map.MapStatsIndex].Lock
		if skillRequired>=4 then 
			skillRequired=skillRequired*2
		end
		t.CanOpen=false
		for i=0,Party.High do
			local s, m = SplitSkill(Party[i]:GetSkill(const.Skills.DisarmTraps))
			local skill=s*m
			if m>=4 or skill>=skillRequired then
				t.CanOpen=true
			end
		end
		if not t.CanOpen then
			local id=Game.CurrentPlayer
			if id<0 or id>Party.High then
				id=0
			end
			evt.FaceAnimation(id,const.FaceAnimation.DoorLocked)
			Game.ShowStatusText("Not enough disarm skill")
		end
	end
end

--[[remove repair/identify from shops
function events.GetShopItemTreatment(t)
	if vars.Mode==2 then
		if t.Action=="identify" or t.Action=="repair" then
			t.Result=0
		end
	end
end
function events.CanShopOperateOnItem(t)
	if vars.Mode==2 then
		if t.Action=="identify" or t.Action=="repair" then
			t.Result=false
		end
	end
end
]]
--increase prices
local houseValues={}
function events.GetShopItemTreatment(t)
	local id=GetCurrentHouse()
	Game.Houses[id].Val=houseValues[id] or Game.Houses[id].Val
	if vars.Mode==2 then
		if t.Action=="identify" or t.Action=="repair" then
			houseValues[id]=houseValues[id] or Game.Houses[id].Val
			if t.Action=="identify" then
				Game.Houses[id].Val=t.Item:T().IdRepSt^2
			else
				Game.Houses[id].Val=5
			end
		end
	end
end

--convert gems, from lower to highest
--NAMES
local craftingNames={"Lunar Shard", "Fire Topaz", "Amethyst Chunk", "Amber Droplet", "Royal Amethyst", "Gemcutter's Ruby", "Solarstone", "Erudite Crystal", "Erathian Sapphire", "Queen's Diamond","Ascended Lunar Shard", "Ascended Topaz", "Ascended Amethyst", "Ascended Amber", "Ascended Purple Amethyst", "Ascended Ruby", "Ascended Solarstone", "Ascended Amber Droplet", "Ascended Sapphire", "Ascended Diamond"}
function events.KeyDown(t)
	if t.Key ~=85 then
		gemUpgrading=false
	end
    if Game.CurrentScreen == 7 and Game.CurrentCharScreen == 103 then
		if t.Key ==85 and gemUpgrading then
			gemUpgrading=false
			for i=1,19 do
				local id=1040+i
				local bonusStrength=0
				local gemsFound=0
				for j=0,Party.High do
					local pl=Party[j]
					for k=1,pl.Items.High do
						if pl.Items[k].Number==id and pl.Items[k].BonusStrength==bonusStrength then
							gemsFound=gemsFound+1
						end
					end
				end
				
				if gemsFound>=3 then
					local gemsRemoved=0
					for j=0,Party.High do
						local pl=Party[j]
						for k=1,pl.Items.High do
							if pl.Items[k].Number==id and pl.Items[k].BonusStrength==bonusStrength then
								pl.Items[k].Number=0
								gemsRemoved=gemsRemoved+1
								if gemsRemoved==3 then
									id=id+1
									evt.Add("Items",id)
									Mouse.Item.BonusStrength=bonusStrength
									Game.ShowStatusText(string.format("%s created", craftingNames[i+1]))
									return
								end
							end
						end
					end
				end
			end
			
			Game.ShowStatusText("No gem to upgrade")
			return
		end
		
        if t.Key == 85 then -- "u" key
            gemUpgrading=true
            for i=1,19 do
				local id=1040+i
				local bonusStrength=0
				local gemsFound=0
				for j=0,Party.High do
					local pl=Party[j]
					for k=1,pl.Items.High do
						if pl.Items[k].Number==id and pl.Items[k].BonusStrength==bonusStrength then
							gemsFound=gemsFound+1
						end
					end
				end
				if gemsFound>=3 then
					Game.ShowStatusText(string.format("Convert %s into %s? (U)",craftingNames[i], craftingNames[i+1]))
					return
				end
			end
			Game.ShowStatusText("No gem to upgrade")
			return
        end
    end
end
--[[
function events.Tick()
	Mouse.Item.MaxCharges=math.min(Mouse.Item.MaxCharges, 200)
end
]]

--vampiric aura and fire aura
fireAuraDamage={0.1,0.15,0.2,0.25,[0]=0}
--guaranteed damage per mastery when the weapon is too weak for the share
--above to beat it; doubled on two-handed weapons, same as the enchant floor
fireAuraMinDamage={3,6,12,24,[0]=0}
function calcFireAuraDamage(pl, it, res, speedMult, isSpell, calcType)
	if vars.MAWSETTINGS.buffRework=="ON" and vars.mawbuff[4] then
		if not it or (it and it.Number==0) or (it and it:T().EquipStat>2) then return 0 end
		local s, m, level=getBuffSkill(4)
		local id=pl:GetIndex()
		--aura scales with the undamped item-level weapon damage; the flat base
		--every weapon shares is not part of that scale
		local damage=GetWeaponLevelDamage(it)*fireAuraDamage[m]
		damage=math.max(damage, fireAuraMinDamage[m]*(IsTwoHandedWeapon(it) and 2 or 1))
		damage=damage*GetLegendary19Mult(pl)
		if calcType~="tooltip" and vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 26) then
			if isSpell then
				critChance, critMult, success=getCritInfo(pl,"spell")
			else
				critChance, critMult, success=getCritInfo(pl)
			end
			if calcType=="damage" and success then
				damage=damage*critMult
			end
			if calcType=="power" then
				damage=damage*(1+math.min(critChance,1)*(critMult-1))
			end
		end
		local res=res or 0
		damage=damage/2^(res/100)
		if speedMult then
			damage=damage*getItemRecovery(it, pl.LevelBase)/100
		end
		return round(damage)
	else
		return 0
	end
end

function events.AfterLoadMap()
	if isRedone then
		if not mapvars.chestFix then
			mapvars.chestFix=true
			local name=Game.MapStats[Map.MapStatsIndex].Name
			local mapLevel=(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3
			local lootLevel=math.max(math.min(math.floor(mapLevel/20)+1,6),2)
			for k=0,Map.Chests.High do
				for i=1,Map.Chests[k].Items.High do
					local it=Map.Chests[k].Items[i]
					if it.MaxCharges==0 then
						if IsBaseItemId(it.Number) then
							it:Randomize(lootLevel,it:T().EquipStat+1)
						end
					end
				end
			end
			for i=0,Map.Objects.High do
				local it=Map.Objects[i].Item
				if it.MaxCharges==0 then
					if IsBaseItemId(it.Number) then
						it:Randomize(lootLevel,it:T().EquipStat+1)
					end
				end
			end
		end
	end
end


function GetLevelRquirement(it)
	local itemType = it:T().EquipStat
	if itemType>11 then
		return 0
	end
	if IsCelestialItem(it) then
		return 1
	end
	local dropLevel=GetItemDropLevel(it)+MawCore.ItemLevel.TierLevels(it.Number)
	local levelRequired=MawCore.ItemLevel.WearLevel(dropLevel)

	if Game.BolsterAmount>=300 then
		levelRequired=levelRequired-6
	end
	if vars.Mode==2 then
		levelRequired=levelRequired-3
	end
	if vars.insanityMode then
		levelRequired=levelRequired-3
	end

	return math.max(1,math.floor(levelRequired))
end

equipSlotWeights = {
	[0] = {0.55,0.15,0.15,0.15}, --2h weapon
	[1] = {0.55,0.15,0.15,0.15}, --1h weapon
	[2] = {0.55,0.15,0.15,0.15}, --bow
	[3] = {0.4,0.2,0.2,0.2}, --chest
	[4] = {0.4,0.2,0.2,0.2}, --shield
	[5] = {0.25,0.25,0.25,0.25},  
	[6] = {0.25,0.25,0.25,0.25},   
	[7] = {0.25,0.25,0.25,0.25},  
	[8] = {0.25,0.25,0.25,0.25},    
	[9] = {0.25,0.25,0.25,0.25},   
	[10] = {0,0.3,0.3,0.3}, --ring
	[11] = {0,0.3,0.3,0.3}, --amulet
}

function GetItemEquipStat(it)
	if type(it)=="table" then
		itemId=it.Number
	else
		itemId=it
	end
	if itemId<=0 or itemId>Game.ItemsTxt.High then
		return -1
	end
	local equipStat=Game.ItemsTxt[itemId].EquipStat
	if table.find(twoHandedAxes, itemId) then
		equipStat=1
	end
	return equipStat
end


function GetSlotMult(it)
	if type(it)=="table" then
		itemId=it.Number
	else
		itemId=it
	end
	if itemId<=0 or itemId>Game.ItemsTxt.High then
		return 1
	end
	local equipStat=Game.ItemsTxt[itemId].EquipStat
	if table.find(twoHandedAxes, itemId) then
		equipStat=1
	end
	local slotMult=slotMult[equipStat] or 1
	if equipStat==5 and Game.ItemsTxt[itemId].Mod2==0 then
		slotMult=slotMult*1.5
	end
	return slotMult
end

function events.GameInitialized2()
	for i=0, Game.Classes.SPStats.High do
		if Game.Classes.SPStats[i]>0 then
			Game.Classes.SPStats[i]=2
		end
	end
end

function GetItemSkill(it)
	local itemId
	if type(it)=="table" then
		itemId=it.Number
	else
		itemId=it
	end
	if table.find(twoHandedAxes, itemId) or table.find(oneHandedAxes, itemId) then
		return 3
	else
		return Game.ItemsTxt[itemId].Skill
	end
end

--reroll potions
function events.LoadMap()
	for i=0, Map.Objects.High do
		local obj=Map.Objects[i]
		if obj.Item and obj.Item.Number>=264 and obj.Item.Number<=289 then
			obj.Item.Number=math.random(252, 263)
		end
	end
	for i=0, Map.Chests.High do
		local chest=Map.Chests[i]
		for j=1, chest.Items.High do
			if chest.Items[j].Number>=264 and chest.Items[j].Number<=289 then
				chest.Items[j].Number=math.random(252, 263)
			end
		end
	end
end
---------------------------
--PITY SYSTEM CALCULATION--
---------------------------
--[[
-- Tunables
local SURV_TOL   = 1e-12          -- stop when survival prob < this
local BISECT_ITR = 30             -- bisection iterations (30 is plenty)
local TINY_P     = 1e-4           -- threshold to use asymptotic
local MAX_K_CAP  = 5e6            -- hard safety cap so we don't loop forever

-- Compute effective drops/kill for sequence p_k = s * u_k(k), capped at 1
local function effective_rate(u_k, s, p_base)
  -- choose an adaptive upper bound: ~c/p is usually enough
  local max_k = math.min(MAX_K_CAP, math.max(10000, math.floor(20.0 / p_base)))

  -- accumulate survival in log-space for stability when S gets tiny
  local logS, EK, k = 0.0, 0.0, 0
  while true do
    -- S = exp(logS); add S to EK
    EK = EK + math.exp(logS)

    local pk = s * u_k(k)
    if pk >= 1 then
      break
    end

    -- update survival: logS += log1p(-pk)
    -- (use stable log1p if available, otherwise approximation)
    local step = math.log(1 - pk)
    logS = logS + step

    -- termination criteria
    if logS < math.log(SURV_TOL) then break end  -- survival tiny enough
    if k >= max_k then break end

    k = k + 1
  end
  return 1.0 / EK
end

-- Asymptotic scale for tiny p (linear pity shape)
local function tiny_p_scale(p, a)
  -- s ≈ 1 / (1 + a/(2p)), clamp to [0,1]
  local s = 1.0 / (1.0 + (a / (2.0 * p)))
  if s < 0 then s = 0 end
  if s > 1 then s = 1 end
  return s
end

-- Find s so that the long-run effective rate equals the base p
local function scale_for_constant_expectation(p, u_k, a)
  -- start from a good guess for tiny p to avoid massive loops
  local lo, hi
  if p <= TINY_P then
    local s0 = tiny_p_scale(p, a)
    -- bracket around s0
    lo = 0.5 * s0
    hi = math.min(1.0, s0 * 1.5 + 1e-9)
  else
    lo, hi = 0.0, 1.0
  end

  for _ = 1, BISECT_ITR do
    local mid = 0.5 * (lo + hi)
    local r = effective_rate(u_k, mid, p)
    if r > p then
      hi = mid
    else
      lo = mid
    end
  end
  return 0.5 * (lo + hi)
end

-- Optional tiny cache so we don't recompute s(p,a) every call
local _scale_cache = {}
local function _cache_key(p, a)
  local pr = math.floor(p * 1e9 + 0.5)  -- quantize to 1e-9
  local ar = math.floor(a * 1e6 + 0.5)  -- quantize to 1e-6
  return pr .. ":" .. ar
end

-- Returns the pity-adjusted chance for base p, failures k, and slope a (default 0.1)
function pity_chance(p, k, a)
  a = (a == nil) and 0.1 or a
  k = (k and k >= 0) and k or 0
  if p <= 0 then return 0 end
  if p >= 1 then return 1 end

  -- linear unscaled pity shape u_k = p * (1 + a*k)
  local function u_k(idx) return p * (1 + a * idx) end

  -- get or compute scale s so that expectation stays constant
  local key = _cache_key(p, a)
  local s = _scale_cache[key]
  if not s then
    s = scale_for_constant_expectation(p, u_k, a)
    _scale_cache[key] = s
  end

  -- pity-adjusted chance for this failure count
  local pk = s * u_k(k)
  if pk > 1 then pk = 1 end
  if pk < 0 then pk = 0 end
  return pk
end

NEW ONE
succ={}
chance=0.1
pity=0
for i=1,100000 do
	roll=math.random()
	win=chance^(1.8-chance*pity)  1.8 is close to the real mean
	if win>=roll then
		table.insert(succ, pity)
		pity=0
	else
		pity=pity+1
	end
end
sum=0
for i=1,#succ do
	sum=sum+succ[i]
end
mean=sum/#succ
print(mean)

]]

--Each failure raises the chance; the exponent is picked so that the AVERAGE
--wait stays at 1/chance (within 2% for every rate in use, from 0.5% to 12%).
--At 1.45 the curve started so far under the nominal chance that it cost ~10%
--more rolls than having no pity at all.
local PITY_EXPONENT = 1.38
function pity_chance(chance, failures)
	--above 1 the exponent would turn the curve upside down and LOWER it
	if chance>=1 then
		return 1
	end
	return chance^(PITY_EXPONENT-chance*failures*0.5)
end

--remove artifacts
mawArtifacts={500,501,502,503,504,505,506,507,508,509,510,511,512,513,514,515,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,523,533,534,535,536,537,542,1302,1303,1304,1305,1306,1307,1308,1309,1310,1311,1312,1313,1314,1315,1316,1317,1318,1319,1320,1321,1322,1323,1324,1325,1326,1327,1328,1329,1330,1331,1332,1333,1334,1335,1336,1337,1338,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030,2031,2032,2033,2034,2035,2036,2037,2038,2039,2040,2041,2042,2043,2044,2045,2046,2047,2048,2049}
function events.AfterLoadMap()
	for k=0,Map.Chests.High do
		for i=1,Map.Chests[k].Items.High do
			local it=Map.Chests[k].Items[i]
			if it.MaxCharges==0 then
				if table.find(mawArtifacts, it.Number) then
					if it:T().Value>=20000 and it.BonusStrength==0 then
						LootContext.markBoss()
						it:Randomize(6,0)
					end
				end
			end
		end
	end
	if vars.Mode==2 and not vars.StartingItemFix then
		vars.StartingItemFix=true
		local extraPower=5
		if vars.insanityMode then
			extraPower=10
		end
		for i=0,Party.PlayersArray.High do
			local pl=Party.PlayersArray[i]
			for k=1,138 do
				local it=pl.Items[k]
				if IsEnchantableItem(it) and it.MaxCharges==0 and it.Number~=2020 then
					it.MaxCharges=extraPower
				end
			end
		end
	end
end

function IsTwoHandedWeapon(it)
	return it:T().EquipStat==1 or table.find(twoHandedAxes, it.Number)~=nil
end

function GetWeaponFlatDamage(it)
	return weaponTierFlat(MawCore.ItemLevel.LadderTier(it.Number))
end

function GetWeaponDamage(it)
	return getWeaponDamageForLevel(MawCore.ItemLevel.OfItem(it), IsTwoHandedWeapon(it), GetWeaponFlatDamage(it))
end

--what enchants and auras scale off: the item-level share only, undamped
function GetWeaponLevelDamage(it)
	return getWeaponLevelDamage(MawCore.ItemLevel.OfItem(it), IsTwoHandedWeapon(it), GetWeaponFlatDamage(it))
end