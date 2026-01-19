local itemListMM8={516,541,602,603,604,605,606,607,608,609,610,611,612,613,614,615,616,623,626,627,630,636,637,639,641,652,658,659,660,661,741,742}
local keysMM8={619, 620, 621} --629 is locked after progression
local mm7offset=802
local emeraldIsland={43,631,632,635,636,658,715}
local itemListMM7={487,542,543,544,600,601,602,603,605,606,607,614,615,617,618,619,620,621,622,623,624,626,628,629,633,638,639,640,641,642,643,644,645,647,648,651,676,677,683,705}
local keysMM7={652,653,654,655,656,657,660,661,662}
local mm6offset=1620
local itemListMM6={400,433,434,448,449,455,456,457,458,459,464,475,479,480,481,485,486,498,499,502,503,504,506,508,543,550,551,552,553}
local keysMM6={487,488,489,492,560,566,567}

for i=1,#itemListMM7 do
	itemListMM7[i]=itemListMM7[i]+mm7offset
end
for i=1,#itemListMM6 do
	itemListMM6[i]=itemListMM6[i]+mm6offset
end

function events.LoadMap()
	if not vars.RandomizerMode then return end
	if not vars.Randomizer then
		vars.OriginalItemOrder=InitializeItemOrder()
		vars.Randomizer=RandomizerInitialize(vars.OriginalItemOrder)
		vars.ItemFound={}
	end
end

function InitializeItemOrder()
	local allItems = {}
	
	for _, id in ipairs(itemListMM8) do
		allItems[#allItems + 1] = id
	end
	for _, id in ipairs(itemListMM7) do
		allItems[#allItems + 1] = id
	end
	for _, id in ipairs(itemListMM6) do
		allItems[#allItems + 1] = id
	end
	
	return allItems
end

function RandomizerInitialize(items)
	math.randomseed(os.time())
	local shuffled = {}
	for i, v in ipairs(items) do
		shuffled[i] = v
	end
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

function events.LoadMap()
	if not vars.RandomizerMode then return end
	for i=0,Map.Chests.High do
		for k=1,Map.Chests[i].Items.High do
			local it=Map.Chests[i].Items[k]
			local pos=table.find(vars.OriginalItemOrder,it.Number)
			if pos and not table.find(vars.ItemFound, it.Number) then
				it.Number = vars.Randomizer[pos]
				vars.ItemFound[#vars.ItemFound + 1] = vars.Randomizer[pos]
			end
		end
	end
	for i=0, Map.Objects.High do
		local it = Map.Objects[i].Item
		local pos = table.find(vars.OriginalItemOrder, it.Number)
		if pos and not table.find(vars.ItemFound, it.Number) then
			it.Number = vars.Randomizer[pos]
			vars.ItemFound[#vars.ItemFound + 1] = vars.Randomizer[pos]
			local spriteId = it:T().SpriteIndex
			Map.Objects[i].Type=spriteId
			Map.Objects[i].TypeIndex=spriteId
		end
	end
end

function events.Action(t)
	if not vars.RandomizerMode then return end
	if t.Action==404 or t.Action==14 then
		function events.Tick()
			events.Remove("Tick",1)
			for idx, itemId in ipairs(vars.OriginalItemOrder) do
				if not table.find(vars.ItemFound, itemId) and evt.Cmp{"Inventory", Value = itemId} then
					vars.ItemFound[#vars.ItemFound + 1] = itemId
					evt.Subtract("Items", itemId)
					evt.Add("Items", vars.Randomizer[idx])
				end
			end
			local it = Mouse.Item.Number
			local pos = table.find(vars.OriginalItemOrder, it)
			if pos and not table.find(vars.ItemFound, it) then
				vars.ItemFound[#vars.ItemFound + 1] = vars.Randomizer[pos]
				Mouse.Item.Number = vars.Randomizer[pos]
			end
		end
	end
end

--Monster shuffler
local originalMapInfo={}
local needsRestore=false
local disallowedMaps={53,61,132,200,206,207,}
function events.LoadMap()
	if vars.RandomizerFixed then return end
	if not vars.MonsterShuffleList then return end
	for i=1,#vars.MonsterShuffleList do
		if vars.MonsterShuffleList[i].Pic=="DemonQueen" then
			vars.MonsterShuffleList[i].Pic="DemonFly"
		end
	end
	vars.RandomizerFixed=true
end
function events.BeforeLoadMap()
	if vars.RandomizerMode then
		if not vars.MonsterShuffleList then
			SetMonsterDensity()
			local monsterPool = {}
			for i=1,Game.MapStats.High do
				if not table.find(disallowedMaps, i) then
					local m = Game.MapStats[i]
					if m.Monster1Pic ~= "0" then
						monsterPool[#monsterPool + 1] = {Pic = m.Monster1Pic, Dif = m.Mon1Dif, Hi = m.Mon1Hi, Low = m.Mon1Low}
					end
					if m.Monster2Pic ~= "0" then
						monsterPool[#monsterPool + 1] = {Pic = m.Monster2Pic, Dif = m.Mon2Dif, Hi = m.Mon2Hi, Low = m.Mon2Low}
					end
					if m.Monster3Pic ~= "0" and  m.Monster3Pic ~= "DemonQueen" then
						monsterPool[#monsterPool + 1] = {Pic = m.Monster3Pic, Dif = m.Mon3Dif, Hi = m.Mon3Hi, Low = m.Mon3Low}
					end
				end
			end
			math.randomseed(os.time())
			for i = #monsterPool, 2, -1 do
				local j = math.random(1, i)
				monsterPool[i], monsterPool[j] = monsterPool[j], monsterPool[i]
			end
			
			vars.MonsterShuffleList = monsterPool
		end
		local idx = 1
		for i=1,Game.MapStats.High do
			if not table.find(disallowedMaps, i) then
				local m = Game.MapStats[i]
				if originalMapInfo[i].Monster1Pic ~= "0" then
					m.Monster1Pic = vars.MonsterShuffleList[idx].Pic
					m.Mon1Dif = vars.MonsterShuffleList[idx].Dif
					m.Mon1Hi = vars.MonsterShuffleList[idx].Hi
					m.Mon1Low = vars.MonsterShuffleList[idx].Low
					idx = idx + 1
				end
				if originalMapInfo[i].Monster2Pic ~= "0" then
					m.Monster2Pic = vars.MonsterShuffleList[idx].Pic
					m.Mon2Dif = vars.MonsterShuffleList[idx].Dif
					m.Mon2Hi = vars.MonsterShuffleList[idx].Hi
					m.Mon2Low = vars.MonsterShuffleList[idx].Low
					idx = idx + 1
				end
				if originalMapInfo[i].Monster3Pic ~= "0" and  originalMapInfo[i].Monster3Pic ~= "DemonQueen"  then
					m.Monster3Pic = vars.MonsterShuffleList[idx].Pic
					m.Mon3Dif = vars.MonsterShuffleList[idx].Dif
					m.Mon3Hi = vars.MonsterShuffleList[idx].Hi
					m.Mon3Low = vars.MonsterShuffleList[idx].Low
					idx = idx + 1
				end
			end
		end
		needsRestore = true
	elseif needsRestore then
		for i=1,Game.MapStats.High do
			local m = Game.MapStats[i]
			local o = originalMapInfo[i]
			m.Mon1Dif = o.Mon1Dif
			m.Mon1Hi = o.Mon1Hi
			m.Mon1Low = o.Mon1Low
			m.Mon2Dif = o.Mon2Dif
			m.Mon2Hi = o.Mon2Hi
			m.Mon2Low = o.Mon2Low
			m.Mon3Dif = o.Mon3Dif
			m.Mon3Hi = o.Mon3Hi
			m.Mon3Low = o.Mon3Low
			m.Monster1Pic = o.Monster1Pic
			m.Monster2Pic = o.Monster2Pic
			m.Monster3Pic = o.Monster3Pic
		end
	end
end

function events.GameInitialized2()
	for i=1,Game.MapStats.High do
		local m = Game.MapStats[i]
		originalMapInfo[i] = {
			Mon1Dif = m.Mon1Dif,
			Mon1Hi = m.Mon1Hi,
			Mon1Low = m.Mon1Low,
			Mon2Dif = m.Mon2Dif,
			Mon2Hi = m.Mon2Hi,
			Mon2Low = m.Mon2Low,
			Mon3Dif = m.Mon3Dif,
			Mon3Hi = m.Mon3Hi,
			Mon3Low = m.Mon3Low,
			Monster1Pic = m.Monster1Pic,
			Monster2Pic = m.Monster2Pic,
			Monster3Pic = m.Monster3Pic,
		}
	end
end

function SetMonsterDensity()
	--add difficulty related damage
	if Game.BolsterAmount%50~=0 then
		Game.BolsterAmount=100
	end
	
	--MAW
	if Game.BolsterAmount<=100 then
		for i=1,Game.MapStats.High do
			Game.MapStats[i].Mon1Low=BackupMapStats[i].Mon1Low
			Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi
			Game.MapStats[i].Mon2Low=BackupMapStats[i].Mon2Low
			Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi
			Game.MapStats[i].Mon3Low=BackupMapStats[i].Mon3Low
			Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi
		end
	end
	
	--Hard
	if Game.BolsterAmount==150 then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Hi<=3 then
				Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi+1
			end 
			if Game.MapStats[i].Mon2Hi<=3 then
				Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi+1
			end 
			if Game.MapStats[i].Mon3Hi<=3 then
				Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi+1
			end 
		end
	end
	
	--Hell
	if Game.BolsterAmount==200 then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Low==1 then
				Game.MapStats[i].Mon1Low=2
			end
			if Game.MapStats[i].Mon1Hi<=3 then
				Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi+1
			end 
			if Game.MapStats[i].Mon2Low==1 then
				Game.MapStats[i].Mon2Low=2
			end
			if Game.MapStats[i].Mon2Hi<=3 then
				Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi+1
			end 
			if Game.MapStats[i].Mon3Low==1 then
				Game.MapStats[i].Mon3Low=2
			end
			if Game.MapStats[i].Mon3Hi<=3 then
				Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi+1
			end 
		end
	end
	
	if Game.BolsterAmount==300 then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Hi>1 then
				Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi+3
			end 
			if Game.MapStats[i].Mon2Hi>1 then
				Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi+3
			end 
			if Game.MapStats[i].Mon3Hi>1 then
				Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi+3
			end 
			Game.MapStats[i].Mon1Dif=math.min(BackupMapStats[i].Mon1Dif+1,5)
			Game.MapStats[i].Mon2Dif=math.min(BackupMapStats[i].Mon2Dif+1,5)
			Game.MapStats[i].Mon3Dif=math.min(BackupMapStats[i].Mon3Dif+1,5)
		end
	end
	
	if vars.Mode==2 then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Hi>1 then
				Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi+4
			end 
			if Game.MapStats[i].Mon2Hi>1 then
				Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi+4
			end 
			if Game.MapStats[i].Mon3Hi>1 then
				Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi+4
			end 
			Game.MapStats[i].Mon1Dif=math.min(BackupMapStats[i].Mon1Dif+1,5)
			Game.MapStats[i].Mon2Dif=math.min(BackupMapStats[i].Mon2Dif+1,5)
			Game.MapStats[i].Mon3Dif=math.min(BackupMapStats[i].Mon3Dif+1,5)
		end
	end
	if vars.insanityMode then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Hi>1 then
				Game.MapStats[i].Mon1Low=3
				Game.MapStats[i].Mon2Low=3
				Game.MapStats[i].Mon3Low=3
			end
		end
	end
	if vars.madnessMode then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Hi>1 then
				Game.MapStats[i].Mon1Low=5
			end
			if Game.MapStats[i].Mon2Hi>1 then
				Game.MapStats[i].Mon2Low=5
			end
			if Game.MapStats[i].Mon3Hi>1 then
				Game.MapStats[i].Mon3Low=5
			end
			if Game.MapStats[i].Mon1Hi>1 then
				Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi+6
			end 
			if Game.MapStats[i].Mon2Hi>1 then
				Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi+6
			end 
			if Game.MapStats[i].Mon3Hi>1 then
				Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi+6
			end 
		end
	end

	--make bigger monsters more rare
	if vars.Mode==2 then
		for i=1,Game.MapStats.High do
			local map=Game.MapStats[i]
			local name1=map.Monster1Pic
			local name2=map.Monster2Pic
			local name3=map.Monster3Pic
			local divisor=18
			if vars.madnessMode then
				divisor=10
			elseif vars.insanityMode then
				divisor=14
			end
			local level1=math.floor(monsterPicTable[name1]/divisor)
			local level2=math.floor(monsterPicTable[name2]/divisor)
			local level3=math.floor(monsterPicTable[name3]/divisor)
			for j=1,level1 do
				if j%3==0 then
					map.Mon1Low=math.max(map.Mon1Low-1, 1)
				else
					map.Mon1Hi=math.max(map.Mon1Hi-1, 1)
				end
			end
			for j=1,level2 do
				if j%3==0 then
					map.Mon2Low=math.max(map.Mon2Low-1, 1)
				else
					map.Mon2Hi=math.max(map.Mon2Hi-1, 1)
				end
			end
			for j=1,level3 do
				if j%3==0 then
					map.Mon3Low=math.max(map.Mon3Low-1, 1)
				else
					map.Mon3Hi=math.max(map.Mon3Hi-1, 1)
				end
			end
		end
	end
end

function events.GameInitialized2()
	randomizerButton=CustomUI.CreateButton{
		IconUp	 	= "TmblrOff",
		IconDown	= "TmblrOn",
		Screen		= 21,
		Layer		= 0,
		X		=	485,
		Y		=	55,
		Action	=	function()
						if Game.RandomizerMode then
							Game.RandomizerMode=false
							randomizerButton.IUpSrc="TmblrOff"
							randomizerButton.IDwSrc="TmblrOn"
						else
							Game.RandomizerMode=true
							randomizerButton.IUpSrc="TmblrOn"
							randomizerButton.IDwSrc="TmblrOff"
						end
					end
	}
	CustomUI.CreateText{
		Text = " Randomizer",
		X = 380,
		Y = 58,
		Width = 45,
		Height = 16,
		Screen = 21
	}
end

function events.BeforeNewGameAutosave()
	if Game.RandomizerMode then
		vars.RandomizerMode=true
	end
end
