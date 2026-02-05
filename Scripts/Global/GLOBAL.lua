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
	mouseItemBeforeClick=Mouse.Item.Number
end

function events.Action(t)
	if t.Action==405 then
		local pl=Party[Game.CurrentPlayer]
		if calcExp(pl.LevelBase)>pl.Experience then
			local lvl=pl.LevelBase
			local ex=pl.Experience
			pl.LevelBase=1
			pl.Experience=0
			function events.Tick()
				events.Remove("Tick",1)
				pl.LevelBase=lvl
				pl.Experience=ex
				itemStats(Party[0])
				mawRefresh("all")
				mawRefresh("all")
			end
		end
	end
end

local tradeItems={643,644,645,646,647,648,649,650,651,1494,1495,1946,1497,1498,1499}
function events.EvtGlobal(i)
	if vars.insanityMode then
		local mouseItemAfterClick=Mouse.Item.Number
		if mouseItemBeforeClick~=mouseItemAfterClick then
			if table.find(tradeItems, mouseItemAfterClick) and Game.CurrentScreen==13 then
				local npc=GetCurrentNPC()
				Game.NPC[npc].EventA=0
			end
		end
	end
end

function events.EvtGlobal(i) -- happens after related global evt executed
	if i ~= LastTopic then
		return
	end
	LastTopic = nil
	
	-- calculate differencies and recalculate rewards
	
	local ExpRewards = {}
	
	local partyLevel=getPartyLevel()
	if vars.madnessMode then
		partyLevel=getTotalLevel()
	end
	for i, Exp in pairs(LastStats.Exp) do
		if i < Party.count then
			ExpRewards[i] = Party[i].Exp - Exp
			if ExpRewards[i]>0 then
				local bonusExp=calculateExp(ExpRewards[i], partyLevel)
				Party[i].Experience=math.min(Party[i].Experience+bonusExp, 2^32-3982296)
				
				--bolster code
				addBolsterExp((bonusExp+ExpRewards[i])/5)
			end
		end
	end
	vars.lastPartyExperience={Party[0]:GetIndex(),Party[0].Experience}
	
	local GoldReward = Party.Gold - LastStats.Gold
	if GoldReward>0 and ExpRewards[0]>0 then
		Party.Gold = Party.Gold + calculateGold(GoldReward)
	end
end
function events.Tick()
	vars.lastPartyExperience={Party[0]:GetIndex(),Party[0].Experience}
end
function events.EvtMap(i)
	if vars.lastPartyExperience and Party[0]:GetIndex()==vars.lastPartyExperience[1] then --check if party member isn't changed
		if Party[0].Experience>vars.lastPartyExperience[2] then --bolster
			local expGained=Party[0].Experience-vars.lastPartyExperience[2]
			addBolsterExp(expGained)
			vars.lastPartyExperience={Party[0]:GetIndex(),Party[0].Experience}
		end
	else --in case player 1 is changed
		vars.lastPartyExperience={Party[0]:GetIndex(),Party[0].Experience}		
		for i=0, Party.High do
			Party[i].Exp=math.min(Party[i].Exp, 2^32-3982296)
		end
	end
end


function calculateExp(experience, partyLevel)
	return experience*(1+partyLevel/100)+500*partyLevel - experience
end
function calculateGold(gold)
	--calculate party level
	local partyLevel=getPartyLevel()
	return gold*(1+partyLevel/100)+250*partyLevel - gold
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


--QUEST FIX
local questRemoveList={207,571,572,573,574,575,576, 181, 203, 212,234,246,1442,1443,1444,1445,1446,1447}
for i=1,#questRemoveList do
	Game.GlobalEvtLines:RemoveEvent(questRemoveList[i])
end
evt.global[181] = function()
	if not evt.CheckItemsCount{MinItemIndex = 200, MaxItemIndex = 204, Count = 4} then         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif not evt.CheckItemsCount{MinItemIndex = 205, MaxItemIndex = 209, Count = 2} then         -- "Phima Root"..."Dragon Turtle Fang"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif evt.CheckItemsCount{MinItemIndex = 210, MaxItemIndex = 214, Count = 1} then         -- "Poppy Pod"..."Unicorn Horn"
		evt.SetMessage{Str = 626}         --[[ "The ingredients!
Thank you!
Take this as a reward!" ]]
		evt.RemoveItems{MinItemIndex = 200, MaxItemIndex = 204, Count = 4}         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.RemoveItems{MinItemIndex = 205, MaxItemIndex = 209, Count = 2}         -- "Phima Root"..."Dragon Turtle Fang"
		evt.RemoveItems{MinItemIndex = 210, MaxItemIndex = 214, Count = 1}         -- "Poppy Pod"..."Unicorn Horn"
		evt.Subtract{"QBits", Value = 113}         -- "Bring Thistle on the Dagger Wound Islands the basic ingredients for a potion of Pure Speed."
		evt.Add{"QBits", Value = 114}         -- returned ingredients for a potion of Pure Speed
		evt.Add{"Inventory", Value = 254}         -- "Pure Speed"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 1000}
		evt.SetNPCTopic{NPC = 68, Index = 2, Event = 0}         -- "Thistle"
	else
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	end
end

evt.global[203] = function()
	if not evt.CheckItemsCount{MinItemIndex = 200, MaxItemIndex = 204, Count = 2} then         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif not evt.CheckItemsCount{MinItemIndex = 205, MaxItemIndex = 209, Count = 3} then         -- "Phima Root"..."Dragon Turtle Fang"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif evt.CheckItemsCount{MinItemIndex = 210, MaxItemIndex = 214, Count = 3} then         -- "Poppy Pod"..."Unicorn Horn"
		evt.SetMessage{Str = 648}         --[[ "Excellent!
With this I can brew another Potion of Pure Luck.
Take this potion as your reward!" ]]
		evt.RemoveItems{MinItemIndex = 200, MaxItemIndex = 204, Count = 2}         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.RemoveItems{MinItemIndex = 205, MaxItemIndex = 209, Count = 3}         -- "Phima Root"..."Dragon Turtle Fang"
		evt.RemoveItems{MinItemIndex = 210, MaxItemIndex = 214, Count = 3}         -- "Poppy Pod"..."Unicorn Horn"
		evt.Subtract{"QBits", Value = 115}         -- "Bring Rihansi in Alvar the basic ingredients for a potion of Pure Luck."
		evt.Add{"QBits", Value = 116}         -- returned ingredients for a potion of Pure Luck
		evt.Add{"Inventory", Value = 254}         -- "Pure Luck"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 5000}
		evt.SetNPCTopic{NPC = 74, Index = 2, Event = 0}         -- "Rihansi"
	else
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	end
end

evt.global[212] = function()
	if not evt.CheckItemsCount{MinItemIndex = 200, MaxItemIndex = 204, Count = 2} then         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif not evt.CheckItemsCount{MinItemIndex = 205, MaxItemIndex = 209, Count = 4} then         -- "Phima Root"..."Dragon Turtle Fang"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif evt.CheckItemsCount{MinItemIndex = 210, MaxItemIndex = 214, Count = 1} then         -- "Poppy Pod"..."Unicorn Horn"
		evt.SetMessage{Str = 648}         --[[ "Excellent!
With this I can brew another Potion of Pure Luck.
Take this potion as your reward!" ]]
		evt.RemoveItems{MinItemIndex = 200, MaxItemIndex = 204, Count = 2}         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.RemoveItems{MinItemIndex = 205, MaxItemIndex = 209, Count = 4}         -- "Phima Root"..."Dragon Turtle Fang"
		evt.RemoveItems{MinItemIndex = 210, MaxItemIndex = 214, Count = 1}         -- "Poppy Pod"..."Unicorn Horn"
		evt.Subtract{"QBits", Value = 121}         -- "Bring Talion in the Ironsand Desert the basic ingredients for a potion of Pure Endurance."
		evt.Add{"QBits", Value = 122}         -- returned ingredients for a potion of Pure Endurance
		evt.Add{"Inventory", Value = 254}         -- "Pure Endurance"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 5000}
		evt.SetNPCTopic{NPC = 78, Index = 2, Event = 0}         -- "Talion"
	else
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	end
end

evt.global[234] = function()
	if not evt.CheckItemsCount{MinItemIndex = 200, MaxItemIndex = 204, Count = 1} then         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif not evt.CheckItemsCount{MinItemIndex = 205, MaxItemIndex = 209, Count = 2} then         -- "Phima Root"..."Dragon Turtle Fang"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif evt.CheckItemsCount{MinItemIndex = 210, MaxItemIndex = 214, Count = 4} then         -- "Poppy Pod"..."Unicorn Horn"
		evt.SetMessage{Str = 679}         --[[ "You have returned with the ingredients, holding up you end of the bargain.
Here is your Potion of Pure Intellect." ]]
		evt.RemoveItems{MinItemIndex = 200, MaxItemIndex = 204, Count = 1}         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.RemoveItems{MinItemIndex = 205, MaxItemIndex = 209, Count = 2}         -- "Phima Root"..."Dragon Turtle Fang"
		evt.RemoveItems{MinItemIndex = 210, MaxItemIndex = 214, Count = 4}         -- "Poppy Pod"..."Unicorn Horn"
		evt.Subtract{"QBits", Value = 123}         -- "Bring Kelvin in Shadowspire the basic ingredients for a potion of Pure Intellect."
		evt.Add{"QBits", Value = 124}         -- returned ingredients for a potion of Pure Intellect
		evt.Add{"Inventory", Value = 253}         -- "Pure Intellect"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 5000}
		evt.SetNPCTopic{NPC = 83, Index = 2, Event = 0}         -- "Kelvin"
	else
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	end
end

evt.global[246] = function()
	if not evt.CheckItemsCount{MinItemIndex = 200, MaxItemIndex = 204, Count = 2} then         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif not evt.CheckItemsCount{MinItemIndex = 205, MaxItemIndex = 209, Count = 1} then         -- "Phima Root"..."Dragon Turtle Fang"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif evt.CheckItemsCount{MinItemIndex = 210, MaxItemIndex = 214, Count = 4} then         -- "Poppy Pod"..."Unicorn Horn"
		evt.SetMessage{Str = 691}         -- "Ah, the right ingredients always do the trick! Here is your potion."
		evt.RemoveItems{MinItemIndex = 200, MaxItemIndex = 204, Count = 2}         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.RemoveItems{MinItemIndex = 205, MaxItemIndex = 209, Count = 1}         -- "Phima Root"..."Dragon Turtle Fang"
		evt.RemoveItems{MinItemIndex = 210, MaxItemIndex = 214, Count = 4}         -- "Poppy Pod"..."Unicorn Horn"
		evt.Subtract{"QBits", Value = 133}         -- returned ingredients for a potion of Pure Accuracy
		evt.Add{"QBits", Value = 134}         -- Gave Gem of Restoration to Blazen Stormlance
		evt.Add{"Inventory", Value = 252}         -- "Pure Accuracy"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 5000}
		evt.SetNPCTopic{NPC = 77, Index = 2, Event = 0}         -- "Galvinus"
	else
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	end
end

evt.global[207] = function()
	evt.SetMessage{Str = 652}         --[[ "The survivors in this region need Potions of Fire Resistance!
With them we can survive until a place is found for us to move to!
Take these potions!
Unfortunately they are all I have!
Deliver them to the six southernmost houses that remain standing in the village of Rust!" ]]
	evt.Add{"QBits", Value = 142}         -- "Deliver Fire Resistance Potions to the six southernmost houses of Rust.  Return to Hobert in Rust."
	evt.Add{"Inventory", Value = 249}         -- "Fire Resistance"
	evt.Add{"Inventory", Value = 249}         -- "Fire Resistance"
	evt.Add{"Inventory", Value = 249}         -- "Fire Resistance"
	evt.SetNPCTopic{NPC = 84, Index = 1, Event = 208}         -- "Pole" : "Not enough potions?"
end-- "Fire Resistance Potion"

evt.global[571] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 249} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 249}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 143}         -- Delivered potion to house 1
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 1000}
	end
	if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
		if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
			if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
				if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
					if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = 7500}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end

evt.global[572] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 249} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 249}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 144}         -- Delivered potion to house 2
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 1000}
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
			if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
				if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
					if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = 1500}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end

evt.global[573] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 249} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 249}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 145}         -- Delivered potion to house 3
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 1000}
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
			if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
				if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
					if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = 1500}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end

evt.global[574] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 249} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 249}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 146}         -- Delivered potion to house 4
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 1000}
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
			if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
				if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
					if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = 1500}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end

evt.global[575] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 249} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 249}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 147}         -- Delivered potion to house 5
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 1000}
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
			if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
				if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
					if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = 1500}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end

evt.global[576] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 249} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 249}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 148}         -- Delivered potion to house 6
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 1000}
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
			if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
				if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
					if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = 1500}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end

-- "Trade Pyramid for Armor"
evt.global[1442] = function()
	mapvars.circusLootStrong=mapvars.circusLootStrong or 0
	if mapvars.circusLootStrong>=10 then
		Message("We have no more items to trade for pyramids")
		return
	end
	evt.ForPlayer(0)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Armor_, Id = 0}
		evt.SetMessage{Str = 2138}         -- "Great to do business with you, here's your armor!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
		return
	end
	evt.ForPlayer(1)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Armor_, Id = 0}
		evt.SetMessage{Str = 2138}         -- "Great to do business with you, here's your armor!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
		return
	end
	evt.ForPlayer(2)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Armor_, Id = 0}
		evt.SetMessage{Str = 2138}         -- "Great to do business with you, here's your armor!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
		return
	end
	evt.ForPlayer(3)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Armor_, Id = 0}
		evt.SetMessage{Str = 2138}         -- "Great to do business with you, here's your armor!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
	else
		evt.SetMessage{Str = 2140}         -- "I'm afraid you don't have a golden pyramid, so I can't make a deal with you."
	end
end

-- "Trade Pyramid for Weapon"
evt.global[1443] = function()
	mapvars.circusLootStrong=mapvars.circusLootStrong or 0
	if mapvars.circusLootStrong>=10 then
		Message("We have no more items to trade for pyramids")
		return
	end
	evt.ForPlayer(0)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Weapon_, Id = 0}
		evt.SetMessage{Str = 2142}         -- "Great to do business with you, here's your weapon!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
		return
	end
	evt.ForPlayer(1)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Weapon_, Id = 0}
		evt.SetMessage{Str = 2142}         -- "Great to do business with you, here's your weapon!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
		return
	end
	evt.ForPlayer(2)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Weapon_, Id = 0}
		evt.SetMessage{Str = 2142}         -- "Great to do business with you, here's your weapon!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
		return
	end
	evt.ForPlayer(3)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Weapon_, Id = 0}
		evt.SetMessage{Str = 2142}         -- "Great to do business with you, here's your weapon!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
	else
		evt.SetMessage{Str = 2140}         -- "I'm afraid you don't have a golden pyramid, so I can't make a deal with you."
	end
end

-- "Trade Pyramid for Accessory"
evt.global[1444] = function()
	mapvars.circusLootStrong=mapvars.circusLootStrong or 0
	if mapvars.circusLootStrong>=10 then
		Message("We have no more items to trade for pyramids")
		return
	end
	evt.ForPlayer(0)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Misc, Id = 0}
		evt.SetMessage{Str = 2143}         -- "Great to do business with you, here's your accessory!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
		return
	end
	evt.ForPlayer(1)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Misc, Id = 0}
		evt.SetMessage{Str = 2143}         -- "Great to do business with you, here's your accessory!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
		return
	end
	evt.ForPlayer(2)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Misc, Id = 0}
		evt.SetMessage{Str = 2143}         -- "Great to do business with you, here's your accessory!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
		return
	end
	evt.ForPlayer(3)
	if evt.Cmp{"Inventory", Value = 2092} then         -- "Golden Pyramid"
		evt.Subtract{"Inventory", Value = 2092}         -- "Golden Pyramid"
		evt.GiveItem{Strength = 6, Type = const.ItemType.Misc, Id = 0}
		evt.SetMessage{Str = 2143}         -- "Great to do business with you, here's your accessory!"
		mapvars.circusLootStrong=mapvars.circusLootStrong+1
	else
		evt.SetMessage{Str = 2140}         -- "I'm afraid you don't have a golden pyramid, so I can't make a deal with you."
	end
end

-- "Trade Keg for Armor"
evt.global[1445] = function()
	mapvars.circusLootWeak=mapvars.circusLootWeak or 0
	if mapvars.circusLootWeak>=10 then
		Message("We have no more items to trade for kegs")
		return
	end
	evt.ForPlayer(0)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Armor_, Id = 0}
		evt.SetMessage{Str = 2138}         -- "Great to do business with you, here's your armor!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
		return
	end
	evt.ForPlayer(1)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Armor_, Id = 0}
		evt.SetMessage{Str = 2138}         -- "Great to do business with you, here's your armor!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
		return
	end
	evt.ForPlayer(2)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Armor_, Id = 0}
		evt.SetMessage{Str = 2138}         -- "Great to do business with you, here's your armor!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
		return
	end
	evt.ForPlayer(3)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Armor_, Id = 0}
		evt.SetMessage{Str = 2138}         -- "Great to do business with you, here's your armor!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
	else
		evt.SetMessage{Str = 2141}         -- "You don't have a keg of wine to trade!"
	end
end

-- "Trade Keg for Weapon"
evt.global[1446] = function()
	mapvars.circusLootWeak=mapvars.circusLootWeak or 0
	if mapvars.circusLootWeak>=10 then
		Message("We have no more items to trade for kegs")
		return
	end
	evt.ForPlayer(0)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Weapon_, Id = 0}
		evt.SetMessage{Str = 2142}         -- "Great to do business with you, here's your weapon!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
		return
	end
	evt.ForPlayer(1)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Weapon_, Id = 0}
		evt.SetMessage{Str = 2142}         -- "Great to do business with you, here's your weapon!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
		return
	end
	evt.ForPlayer(2)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Weapon_, Id = 0}
		evt.SetMessage{Str = 2142}         -- "Great to do business with you, here's your weapon!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
		return
	end
	evt.ForPlayer(3)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Weapon_, Id = 0}
		evt.SetMessage{Str = 2142}         -- "Great to do business with you, here's your weapon!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
	else
		evt.SetMessage{Str = 2141}         -- "You don't have a keg of wine to trade!"
	end
end

-- "Trade Keg for Accessory"
evt.global[1447] = function()
	mapvars.circusLootWeak=mapvars.circusLootWeak or 0
	if mapvars.circusLootWeak>=10 then
		Message("We have no more items to trade for kegs")
		return
	end
	evt.ForPlayer(0)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Misc, Id = 0}
		evt.SetMessage{Str = 2143}         -- "Great to do business with you, here's your accessory!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
		return
	end
	evt.ForPlayer(1)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Misc, Id = 0}
		evt.SetMessage{Str = 2143}         -- "Great to do business with you, here's your accessory!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
		return
	end
	evt.ForPlayer(2)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Misc, Id = 0}
		evt.SetMessage{Str = 2143}         -- "Great to do business with you, here's your accessory!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
		return
	end
	evt.ForPlayer(3)
	if evt.Cmp{"Inventory", Value = 2093} then         -- "Keg of Wine"
		evt.Subtract{"Inventory", Value = 2093}         -- "Keg of Wine"
		evt.GiveItem{Strength = 4, Type = const.ItemType.Misc, Id = 0}
		evt.SetMessage{Str = 2143}         -- "Great to do business with you, here's your accessory!"
		mapvars.circusLootWeak=mapvars.circusLootWeak+1
	else
		evt.SetMessage{Str = 2141}         -- "You don't have a keg of wine to trade!"
	end
end

if vars.Mode==2 then
	evt.MoveNPC{1109, 0}
	evt.MoveNPC{1165, 0}
	evt.MoveNPC{1166, 0}
end
