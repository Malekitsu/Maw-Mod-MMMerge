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
	
	local GoldReward = Party.Gold - LastStats.Gold
	if GoldReward>0 and ExpRewards[0]>0 then
		Party.Gold = Party.Gold + calculateGold(GoldReward)
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

evt.global[2666] = function()
	evt.MoveToMap{-9729, -10555, 160, 512, 0, 0, 0, 3, "oute3.odm"}
end

evt.global[1777] = function()
	if evt.Cmp{"QBits", Value = 527} then
		evt.MoveToMap{-16832, 12512, 372, 0, 0, 0, 0, 3, "7out02.odm"}
	else
		evt.MoveToMap{12552, 800, 193, 512, 0, 0, 0, 3, "7out01.odm"}
	end
end

evt.global[1888] = function()
	if evt.Cmp{"QBits", Value = 93} then
		evt.MoveToMap{10219, -15624, 265, 0, 0, 0, 0, 3, "out02.odm"}
	else
		evt.MoveToMap{3560, 7696, 544, 0, 0, 0, 0, 3, "out01.odm"}
	end
end
