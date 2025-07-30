----------------------------------------------------
--Experience curve
----------------------------------------------------
--Everything in the mod that turns experience into a level -- bolster, party level,
--item level, the engine hooks below -- goes through calcExp / calcLevel, so this is
--the one place the curve is edited.
--Curve: vanilla 500*L*(L-1) through EXP_RAMP_LEVEL, then each step picks up the
--(1 + (L-EXP_RAMP_LEVEL)*EXP_RAMP) ramp. Both pieces have closed forms, so calcExp and
--calcLevel are exact (RAMP_OFFSET joins the cubic branch onto vanilla at the branch level).
do
	local EXP_RAMP_LEVEL = 100
	--per-level ramp rate past EXP_RAMP_LEVEL
	local EXP_RAMP = 0.005
	--calcLevel's cubic branch needs a nonnegative discriminant: (3L+1)^2*r^2 - 6(5L-1)*r + 9 <= 0, i.e. roughly L*r in [1/3, 3]
	assert((3*EXP_RAMP_LEVEL+1)*(3*EXP_RAMP_LEVEL+1)*EXP_RAMP*EXP_RAMP - 6*(5*EXP_RAMP_LEVEL-1)*EXP_RAMP + 9 <= 0,
	  "EXP_RAMP_LEVEL*EXP_RAMP outside ~[1/3,3]: calcLevel would go NaN just past the ramp level")

	local RC = 500*EXP_RAMP/3
	local RAMP3 = 3*EXP_RAMP_LEVEL
	local RAMP3P1 = RAMP3+1
	--adds back the ramp summed below the branch level, for continuity
	local RAMP_OFFSET = 500*EXP_RAMP*EXP_RAMP_LEVEL*(EXP_RAMP_LEVEL*EXP_RAMP_LEVEL-1)/3

	function calcExp(lvl)
		if lvl <= 1 then
			return 0
		end
		local vanilla = 500*lvl*(lvl-1)
		if lvl <= EXP_RAMP_LEVEL then
			return vanilla
		end
		--vanilla plus sum_{k=EXP_RAMP_LEVEL+1}^{lvl-1} EXP_RAMP*1000*k*(k-EXP_RAMP_LEVEL)
		return vanilla + EXP_RAMP*vanilla*(2*lvl-RAMP3P1)/3 + RAMP_OFFSET
	end

	--calcLevel solves calcExp(L) = x: quadratic inverse below VANILLA_TOP, depressed cubic
	--above; coefficients derived from the constants so the pair cannot desync.
	local A = 2*RC
	local B = 500-(RAMP3+3)*RC
	local C = -500+RAMP3P1*RC
	local CUBIC_SHIFT = B/(3*A)
	local COA = C/A
	local CUBIC_P = COA - B*B/(3*A*A)
	local VANILLA_TOP = calcExp(EXP_RAMP_LEVEL)
	--the x-independent parts of the depressed-cubic solve, hoisted out of calcLevel
	local M = B/A
	local Q_BASE = 2*M*M*M/27 - M*COA/3
	local NEG_C3_27 = -CUBIC_P*CUBIC_P*CUBIC_P/27

	function calcLevel(x)
		if x <= 0 then
			return 1
		end
		if x <= VANILLA_TOP then
			return (1 + math.sqrt(1 + x/125))/2
		end
		local u = ((x-RAMP_OFFSET)/A - Q_BASE)/2
		--nonnegative discriminant: guarded by the assert above
		local d = math.sqrt(u*u - NEG_C3_27)
		local s = u+d
		--(NEG_C3_27/s) == u-d: the quotient avoids cancellation at big x
		return s^(1/3) + (NEG_C3_27/s)^(1/3) - CUBIC_SHIFT
	end
end

----------------------------------------------------
--Engine level-up check
----------------------------------------------------
--The engine holds its own hardcoded copy of the curve (vanilla 500*L*(L-1)), which the
--curve above stops matching past level 100. These hooks make it ask calcExp instead, so
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

--flat experience to one player: no bolster scaling, nothing banked into the bolster
function addExpNoBolster(pl, amount)
	pl.Experience = math.min(pl.Experience + amount, 2^32-3982296)
end

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
			bolsterExp=bolsterExp+experienceAwarded
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
	--party creation: skill tooltips ask before BeforeNewGameAutosave creates MMLVL
	if not vars.MMLVL then
		return result
	end
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
	if not vars.MMLVL then
		return result
	end
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
