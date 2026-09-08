----------------------------------------------------
--Experience curve
----------------------------------------------------
--Everything in the mod that turns experience into a level -- bolster, party level,
--item level, the engine hooks below -- goes through calcExp / calcLevel, so this is
--the one place the curve is edited.
local function expStep(lvl)
	return 1000*lvl*math.max(1 + (lvl-100)*0.01, 1)
end

local MAX_TABLE_LEVEL = 2000
local expRequired = {[1] = 0}
for lvl = 2, MAX_TABLE_LEVEL do
	expRequired[lvl] = expRequired[lvl-1] + expStep(lvl-1)
end

function calcLevel(x)
	if x <= 0 then
		return 1
	end
	local top = expRequired[MAX_TABLE_LEVEL]
	if x >= top then --past the table: extrapolate with the last step
		return MAX_TABLE_LEVEL + (x - top)/expStep(MAX_TABLE_LEVEL)
	end
	local lo, hi = 1, MAX_TABLE_LEVEL --binary search: biggest lo with expRequired[lo] <= x
	while hi - lo > 1 do
		local mid = math.floor((lo + hi)/2)
		if expRequired[mid] <= x then
			lo = mid
		else
			hi = mid
		end
	end
	return lo + (x - expRequired[lo])/expStep(lo)
end
function calcExp(lvl)
	if lvl <= 1 then
		return 0
	end
	if lvl >= MAX_TABLE_LEVEL then
		return expRequired[MAX_TABLE_LEVEL] + (lvl - MAX_TABLE_LEVEL)*expStep(MAX_TABLE_LEVEL)
	end
	local base = math.floor(lvl)
	return expRequired[base] + (lvl - base)*expStep(base)
end

----------------------------------------------------
--Engine level-up check
----------------------------------------------------
--The engine holds its own hardcoded copy of the curve (vanilla 500*L*(L-1)), which the
--table above stops matching past level 100. These hooks make it ask calcExp instead, so
--the trainer and the mod agree on one curve.
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

----------------------------------------------------
--Quest/event experience (evt.Add "Experience")
----------------------------------------------------
--Every event reward, binary map events and Lua evt.Add alike, funnels through the
--engine's AddVariable at 0x4485EC. Experience is varNum 0x0D. With ForPlayer("All")
--the engine calls it once per party member with the full amount, so EventExperience
--runs once per player, not once per reward.
local REFERENCE_PARTY_SIZE = 5
local pendingEventBolster = 0
local eventBolsterQueued = false

local function flushEventBolster()
	eventBolsterQueued = false
	local amount = pendingEventBolster
	pendingEventBolster = 0
	if amount > 0 then
		addBolsterExp(amount)
	end
end

function EventExperience(value, player)
	if value <= 0 or not vars.MMLVL then
		return value
	end
	local partyLevel = getPartyLevel()
	if vars.madnessMode then
		partyLevel = getTotalLevel()
	end
	local total = value*(1+partyLevel/100) + 500*partyLevel
	local partyCount = math.max(Party.Count, 1)
	--each per-member call contributes its slice, so the bolster banks the same amount
	--whatever the party size
	pendingEventBolster = pendingEventBolster + total/partyCount
	if not eventBolsterQueued then
		eventBolsterQueued = true
		RunNextTick(flushEventBolster)
	end
	return total*REFERENCE_PARTY_SIZE/partyCount
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

----------------------------------------------------
--Kill experience
----------------------------------------------------
function events.MonsterKillExp(t)

	--online handled in maw-multiplayer file
	--[[if vars.onlineMode then 
		t.Handled=true
		t.Exp=0
		return
	end 
	]]
	
	if MawCore.Sync.inGame() then
		t.Exp=0
		return
	end
	if vars.madnessMode then
		if mapvars.mawBounty or Map.Name=="zarena.blv" or Map.Name=="d42.blv" or Map.Name=="7d05.blv" then
			t.Exp=0
			return
		end
	end
	local partyLvl=getTotalLevel()
	local mon=t.Monster
	
	
	if vars.insanityMode and mon.NameId>300 then 
		t.Handled=true
		t.Exp=0
		return
	end
	
	--local monLvl=getMonsterLevel(mon)
	t.Handled=true

	local bolsterExp=0
	
	
	local partyCount=0
	for i=0, Party.High do
		if Party[i].Dead==0 and Party[i].Eradicated==0 then
			partyCount=partyCount+1
		end
	end
	partyCount=math.max(1,partyCount)
	local experience=round(t.Exp/partyCount)
	
	local monHealth=getMonsterHealth(mon)
	--local monDamage=getMonsterDamage(mon)
	
	for i=0, Party.High do
		if Party[i].Dead==0 and Party[i].Eradicated==0 then
			local playerLevel=math.min(calcLevel(Party[i].Experience),partyLvl)
			local healthRateo=monHealth/getMonsterHealth(false,playerLevel)
			local mult=healthRateo --*damageRateo
						
			local experienceAwarded=experience*healthRateo
			local lvl=Party[i].LevelBase
			experienceAwarded=math.min((lvl+1)*1000, experienceAwarded)
			Party[i].Experience=math.min(Party[i].Experience+experienceAwarded, 2^32-3982296)
			
			--calculate again based for bolster
			playerLevel=partyLvl
			bolsterExp=bolsterExp+experience*healthRateo
		end
	end
	
	--no bolster from arena
	if Map.Name=="d42.blv" then
		return
	end
	
	addBolsterExp(bolsterExp/5)

	for i=0, Party.High do
		Party[i].Exp=math.min(Party[i].Exp, 2^32-3982296)
	end
end

----------------------------------------------------
--Bolster experience (levels banked per world)
----------------------------------------------------
--MONSTER BOLSTERING
function events.BeforeNewGameAutosave()
	vars.MMLVL = {0, 0, 0, 0}
	vars.EXPBEFORE = 0
	vars.LVLBEFORE = 0
end

function events.BeforeLoadMap(wasInGame)
	if not wasInGame then
		-- migrate from old saves lacking EXPBEFORE
		vars.EXPBEFORE = vars.EXPBEFORE or calcExp(vars.LVLBEFORE or 1)
		if  not vars.MMLVL then
			-- migrate to refactored MMLVL
			vars.MMLVL = {vars.MM8LVL, vars.MM7LVL, vars.MM6LVL, vars.MMMLVL}
			vars.MM8LVL = nil
			vars.MM7LVL = nil
			vars.MM6LVL = nil
			vars.MMMLVL = nil
		end
	end
end

function addBolsterExp(experience)
	if MawCore.Sync.isClient() then
		return
	end
	local currentWorld = TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	vars.EXPBEFORE = vars.EXPBEFORE + experience
	local currentLvl = calcLevel(vars.EXPBEFORE)
	vars.MMLVL[currentWorld] = vars.MMLVL[currentWorld] + currentLvl - vars.LVLBEFORE
	vars.LVLBEFORE = currentLvl
end


function getTotalLevel()
	local result = 0
	for i=1,4 do
		result = result + vars.MMLVL[i]
	end
	return result
end

function getTotalExp()
	return calcExp(getTotalLevel()+1)
end

function getPartyLevel(currentWorld)
	currentWorld = currentWorld or TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	local result = 0
	for i=1,4 do
		if currentWorld ~= i then
			result = result + vars.MMLVL[i]
		end
	end
	return result
end

function getPartyExp(currentWorld)
	return calcExp(getPartyLevel(currentWorld)+1)
end
