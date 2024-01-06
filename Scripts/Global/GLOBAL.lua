--quest exp
local LastTopic
local LastStats

function events.ClickNPCTopic(i) -- happens just before global evt execution
	LastTopic= i
	
	-- capture current stats
	LastStats= {
		Gold = Party.Gold, 
		Exp = {}
	}
	for i,v in Party do
		LastStats.Exp[i] = v.Exp
	end
end

function events.EvtGlobal(i) -- happens after related global evt executed
	if i ~= LastTopic then
		return
	end
	LastTopic = nil
	
	-- calculate differencies and recalculate rewards
	local GoldReward = Party.Gold - LastStats.Gold
	if GoldReward>0 then
		Party.Gold = Party.Gold + calculateGold(GoldReward)
	end
	local ExpRewards = {}
	for i, Exp in pairs(LastStats.Exp) do
		if i < Party.count then
			ExpRewards[i] = Party[i].Exp - Exp
			if ExpRewards[i]>0 then
				bonusExp=calculateExp(ExpRewards[i])
				Party[i].Exp = Party[i].Exp + bonusExp
				
				--bolster code
				bonusExp=(bonusExp+ExpRewards[i])/Party.Count
				local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
				local currentLVL=calcLevel(bonusExp + vars.EXPBEFORE)
					
				if currentWorld==1 then
					vars.MM8LVL = vars.MM8LVL + currentLVL - vars.LVLBEFORE
				elseif currentWorld==2 then
					vars.MM7LVL = vars.MM7LVL + currentLVL - vars.LVLBEFORE
				elseif currentWorld==3 then
					vars.MM6LVL = vars.MM6LVL + currentLVL - vars.LVLBEFORE
				elseif currentWorld==4 then
					vars.MMMLVL = vars.MMMLVL + currentLVL - vars.LVLBEFORE
				end
				vars.EXPBEFORE = vars.EXPBEFORE + bonusExp
				vars.LVLBEFORE = calcLevel(vars.EXPBEFORE)
			end
		end
	end
	
	
		
end


function calculateExp(experience)
	--calculate party level
	currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
	if currentWorld==1 then
		partyLevel=vars.MM7LVL+vars.MM6LVL
	elseif currentWorld==2 then
		partyLevel=vars.MM8LVL+vars.MM6LVL
	elseif currentWorld==3 then
		partyLevel=vars.MM8LVL+vars.MM7LVL
	elseif currentWorld==4 then
		partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
	end
	experience=experience*(1+partyLevel/100)+500*partyLevel - experience
	return experience
end
function calculateGold(gold)
	--calculate party level
	currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
	if currentWorld==1 then
		partyLevel=vars.MM7LVL+vars.MM6LVL
	elseif currentWorld==2 then
		partyLevel=vars.MM8LVL+vars.MM6LVL
	elseif currentWorld==3 then
		partyLevel=vars.MM8LVL+vars.MM7LVL
	elseif currentWorld==4 then
		partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
	end
	gold=gold*(1+partyLevel/100)+250*partyLevel - gold
	return gold
end
