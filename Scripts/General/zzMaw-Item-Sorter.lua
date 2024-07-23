--[[function getItemData()
	a=""
	Mouse.Item.Number=1
	for i=0,125 do
		Party[0].Inventory[i]=0
	end
	for i=1,Game.ItemsTxt.High-1 do

		evt.Add("Items", i+1)
		x=0
		y=0
		while x<14 and Party[0].Inventory[x]~=0 do
			x=x+1
		end
		while y<9 and Party[0].Inventory[y*14]~=0 do
			y=y+1
		end
		a=string.format(a .. "	[" .. i .. "]" .. "={" .. x .. "," .. y .. "},\n")
		for i=0,125 do
			Party[0].Inventory[i]=0
		end
		for i=1,138 do
			Party[0].Items[i].Number=0
		end
	end
	Mouse.Item.Number=0
	debug.Message(a)
end
use this only if you need to write a new item size list, due to different game version]] 
--[[ here code to clean inventory: sometimes items are stored in items even if they don't appear anywhere in the inventory. Use once inventory is empty
for i=1,Party[2].Items.High do
	if Party[2].Items[i].BodyLocation==0 then
		Party[2].Items[i].Number=0
	end
end
]]


function events.KeyDown(t)
    if Game.CurrentScreen == 7 and Game.CurrentCharScreen == 103 then
        if t.Key == 82 then
            sortInventory(false)
            Game.ShowStatusText("Inventory sorted")
        elseif t.Key == 84 then
            sortInventory(true)
            Game.ShowStatusText("All inventories have been sorted")
        elseif t.Key == 69 then
            vars.alchemyPlayer = vars.alchemyPlayer or -1
            if vars.alchemyPlayer == Game.CurrentPlayer then
                vars.alchemyPlayer = -1
                Game.ShowStatusText("No alchemy preference when sorting")
            else
                vars.alchemyPlayer = Game.CurrentPlayer
                Game.ShowStatusText(Party[Game.CurrentPlayer].Name .. " will now take alchemy items when sorting")
            end
        end
    end
end

function sortInventory(all)
	evt.Add("Items", 0)
	local itemList={}
	local j=0
	local low, high
	if all then
		low=0
		high=Party.High
	else
		low=Game.CurrentPlayer
		high=Game.CurrentPlayer
	end
	
	for i=low,high do
		local pl=Party[i]
		
		removeList={}
		for i=0,125 do
			if pl.Inventory[i]>0 then
				if pl.Items[pl.Inventory[i]].BodyLocation==0 then
					removeList[-i-1]=true
				end
				local it=pl.Items[pl.Inventory[i]]
				if it.Number>0 then
					j=j+1
					itemList[j] = {} 
					--iterating doesn't seem to work
					itemList[j]["Bonus"]=it.Bonus
					itemList[j]["Bonus2"]=it.Bonus2
					itemList[j]["BonusExpireTime"]=it.BonusExpireTime
					itemList[j]["BonusStrength"]=it.BonusStrength
					itemList[j]["Broken"]=it.Broken
					itemList[j]["Charges"]=it.Charges
					itemList[j]["Condition"]=it.Condition 
					itemList[j]["Hardened"]=it.Hardened
					itemList[j]["Identified"]=it.Identified
					itemList[j]["MaxCharges"]=it.MaxCharges
					itemList[j]["Number"]=it.Number
					itemList[j]["Owner"]=it.Owner
					itemList[j]["Refundable"]=it.Refundable
					itemList[j]["Stolen"]=it.Stolen
					itemList[j]["TemporaryBonus"]=it.TemporaryBonus
					itemList[j]["size"]=itemSizeMap[it.Number][2]
					if itemList[j]["size"]==1 and itemSizeMap[it.Number][1] >1 then
						itemList[j]["size"]=1.5
					end
					pl.Inventory[i]=0 
					it.Number=0
				end
			end
		end
			
		for i=0,125 do
			if removeList[pl.Inventory[i]] then
				pl.Inventory[i]=0
			end
		end
		vars.alchemyPlayer=vars.alchemyPlayer or -1
		table.sort(itemList, function(a, b)
			-- Custom function to find index of an item in alchemyItemsOrder
			local function getIndexInOrder(number)
				for index, value in ipairs(alchemyItemsOrder) do
					if value == number then
						return index
					end
				end
				return nil -- Return nil if the item is not found
			end

			-- Special sorting for items with number >= 220 and < 300
			if vars.alchemyPlayer>=0 then
				if (a["Number"] >= 220 and a["Number"] < 300) or (b["Number"] >= 220 and b["Number"] < 300) then
					-- Ensure that items in the specified range are sorted first and from biggest to smallest
					if (a["Number"] >= 220 and a["Number"] < 300) and (b["Number"] >= 220 and b["Number"] < 300) then
						return a["Number"] > b["Number"] -- Both in range, sort descending
					else
						return a["Number"] >= 220 and a["Number"] < 300 -- Only one in range, it goes first
					end
				end

				-- Sorting according to alchemyItemsOrder
				local indexA = getIndexInOrder(a["Number"])
				local indexB = getIndexInOrder(b["Number"])
				if indexA and indexB then -- If both items are in the list
					return indexA < indexB
				elseif indexA or indexB then -- If only one item is in the list, it goes first
					return indexA ~= nil
				end
			end
			
			-- Original sorting logic
			if a["size"] == b["size"] then
				-- When sizes are equal, compare by skill
				local skillA = Game.ItemsTxt[a["Number"]].Skill
				local skillB = Game.ItemsTxt[b["Number"]].Skill
				
				if skillA == skillB then
					-- If skills are also equal, then sort by item number
					return a["Number"] < b["Number"]
				else
					-- Otherwise, sort by skill
					return skillA < skillB
				end
			else
				-- Primary sort by size
				return a["size"] > b["size"]
			end
		end)

	end
	
	
	if itemList[1] then
		lastPlayer=Game.CurrentPlayer
		vars.alchemyPlayer=vars.alchemyPlayer or -1
		for i=1,#itemList do
			if vars.alchemyPlayer>=0 then
				if table.find(alchemyItemsOrder,itemList[i].Number) or (itemList[i].Number>=220 and itemList[i].Number<300) then
					Game.CurrentPlayer=vars.alchemyPlayer
				end
			end
			evt.Add("Items", itemList[i].Number)
			it=Mouse.Item
			it.Bonus=itemList[i].Bonus
			it.Bonus2=itemList[i].Bonus2
			it.BonusExpireTime=itemList[i].BonusExpireTime
			it.BonusStrength=itemList[i].BonusStrength
			it.Broken=itemList[i].Broken
			it.Charges=itemList[i].Charges
			it.Condition=itemList[i].Condition
			it.Hardened=itemList[i].Hardened
			it.Identified=itemList[i].Identified
			it.MaxCharges=itemList[i].MaxCharges
			it.Owner=itemList[i].Owner
			it.Refundable=itemList[i].Refundable
			it.Stolen=itemList[i].Stolen
			it.TemporaryBonus=itemList[i].TemporaryBonus
			evt.Add("Items", 0) --to give item to proper player
			Game.CurrentPlayer=lastPlayer
		end
	end
	table.clear(itemList)
end	



function sortMultibag()
	--let's fill first all inventories
	local playerCurrentInventories={}
	local plToSort=Game.CurrentPlayer
	for i=0, Party.High do
		Game.CurrentPlayer=i
		local pl=Party[i]
		if vars.mawbags[pl:GetIndex()] and vars.mawbags[pl:GetIndex()].CurrentBag then
			playerCurrentInventories[i]=vars.mawbags[pl:GetIndex()].CurrentBag
		else
			playerCurrentInventories[i]=1
		end
		changeBag(pl , 0)
		if Party[i].Inventory[0]==0 then
			evt.Add("Items",612)
			evt.Add("Items",612)
			for j=1,14 do
				evt.Add("Items",2080)
			end
			evt.Add("Items",0)
		end
	end
	Game.CurrentPlayer=plToSort
	evt.Add("Items", 0)
	local itemList={}
	local j=0
	local pl=Party[Game.CurrentPlayer]
	for bag=1,5 do
		changeBag(pl , bag)
		removeList={}
		for i=0,125 do
			if pl.Inventory[i]>0 then
				if pl.Items[pl.Inventory[i]].BodyLocation==0 then
					removeList[-i-1]=true
				end
				local it=pl.Items[pl.Inventory[i]]
				if it.Number>0 then
					j=j+1
					itemList[j] = {} 
					--iterating doesn't seem to work
					itemList[j]["Bonus"]=it.Bonus
					itemList[j]["Bonus2"]=it.Bonus2
					itemList[j]["BonusExpireTime"]=it.BonusExpireTime
					itemList[j]["BonusStrength"]=it.BonusStrength
					itemList[j]["Broken"]=it.Broken
					itemList[j]["Charges"]=it.Charges
					itemList[j]["Condition"]=it.Condition 
					itemList[j]["Hardened"]=it.Hardened
					itemList[j]["Identified"]=it.Identified
					itemList[j]["MaxCharges"]=it.MaxCharges
					itemList[j]["Number"]=it.Number
					itemList[j]["Owner"]=it.Owner
					itemList[j]["Refundable"]=it.Refundable
					itemList[j]["Stolen"]=it.Stolen
					itemList[j]["TemporaryBonus"]=it.TemporaryBonus
					itemList[j]["size"]=itemSizeMap[it.Number][2]
					if itemList[j]["size"]==1 and itemSizeMap[it.Number][1] >1 then
						itemList[j]["size"]=1.5
					end
					pl.Inventory[i]=0 
					it.Number=0
				end
			end
		end
			
		for i=0,125 do
			if removeList[pl.Inventory[i]] then
				pl.Inventory[i]=0
			end
		end
		vars.alchemyPlayer=vars.alchemyPlayer or -1
		table.sort(itemList, function(a, b)
			-- Custom function to find index of an item in alchemyItemsOrder
			local function getIndexInOrder(number)
				for index, value in ipairs(alchemyItemsOrder) do
					if value == number then
						return index
					end
				end
				return nil -- Return nil if the item is not found
			end

			-- Special sorting for items with number >= 220 and < 300
			if vars.alchemyPlayer>=0 then
				if (a["Number"] >= 220 and a["Number"] < 300) or (b["Number"] >= 220 and b["Number"] < 300) then
					-- Ensure that items in the specified range are sorted first and from biggest to smallest
					if (a["Number"] >= 220 and a["Number"] < 300) and (b["Number"] >= 220 and b["Number"] < 300) then
						return a["Number"] > b["Number"] -- Both in range, sort descending
					else
						return a["Number"] >= 220 and a["Number"] < 300 -- Only one in range, it goes first
					end
				end

				-- Sorting according to alchemyItemsOrder
				local indexA = getIndexInOrder(a["Number"])
				local indexB = getIndexInOrder(b["Number"])
				if indexA and indexB then -- If both items are in the list
					return indexA < indexB
				elseif indexA or indexB then -- If only one item is in the list, it goes first
					return indexA ~= nil
				end
			end
			
			-- Original sorting logic
			if a["size"] == b["size"] then
				-- When sizes are equal, compare by skill
				local skillA = Game.ItemsTxt[a["Number"]].Skill
				local skillB = Game.ItemsTxt[b["Number"]].Skill
				
				if skillA == skillB then
					-- If skills are also equal, then sort by item number
					return a["Number"] < b["Number"]
				else
					-- Otherwise, sort by skill
					return skillA < skillB
				end
			else
				-- Primary sort by size
				return a["size"] > b["size"]
			end
		end)
		
	end
	
	changeBag(pl , 1)
	local currentBag=1
	local currentAlchemyBag=1
	local i=1
	if itemList[1] then
		vars.alchemyPlayer=vars.alchemyPlayer or -1
		lastPlayer=Game.CurrentPlayer
		while i<=#itemList do
			local alchemyItem=false
			if vars.alchemyPlayer>=0 and vars.alchemyPlayer~=Game.CurrentPlayer then
				alchemyPlayer=Party[vars.alchemyPlayer]
				if table.find(alchemyItemsOrder,itemList[i].Number) or (itemList[i].Number>=220 and itemList[i].Number<300) then
					Game.CurrentPlayer=vars.alchemyPlayer
					alchemyItem=true
					changeBag(pl , 0)
					changeBag(alchemyPlayer , currentAlchemyBag)
				end
			end
			evt.Add("Items", itemList[i].Number)
			it=Mouse.Item
			it.Bonus=itemList[i].Bonus
			it.Bonus2=itemList[i].Bonus2
			it.BonusExpireTime=itemList[i].BonusExpireTime
			it.BonusStrength=itemList[i].BonusStrength
			it.Broken=itemList[i].Broken
			it.Charges=itemList[i].Charges
			it.Condition=itemList[i].Condition
			it.Hardened=itemList[i].Hardened
			it.Identified=itemList[i].Identified
			it.MaxCharges=itemList[i].MaxCharges
			it.Owner=itemList[i].Owner
			it.Refundable=itemList[i].Refundable
			it.Stolen=itemList[i].Stolen
			it.TemporaryBonus=itemList[i].TemporaryBonus
			BeginGrabObjects()
			evt.Add("Items", 0) --to give item to proper player
			local obj=GrabObjects()
			i=i+1
			
			if not alchemyItem then
				if not obj then
					currentBag=1
					changeBag(pl , 1)
				elseif currentBag~=5 then
					changeBag(pl , currentBag+1)
					currentBag=currentBag+1
					obj.Type=0
					obj.TypeIndex=0
					i=i-1
				end
			else
				if not obj then
					changeBag(alchemyPlayer , 0)
					changeBag(pl , 1)
					currentAlchemyBag=1
				elseif alchemyItem and currentAlchemyBag~=5 then
					changeBag(alchemyPlayer , currentAlchemyBag+1)
					currentAlchemyBag=currentAlchemyBag+1
					obj.Type=0
					obj.TypeIndex=0
					i=i-1
				end
			end
			Game.CurrentPlayer=lastPlayer
		end
	end
	
	for i=0,Party.High do
		if i~=plToSort then
			changeBag(Party[i], playerCurrentInventories[i])
		end
	end
	changeBag(pl, currentBag)
	table.clear(itemList)
end	

--[[
function events.KeyDown(t)
    if Game.CurrentScreen == 7 and Game.CurrentCharScreen == 103 then
        if t.Key == const.Keys.L then
			local pl=Party[Game.CurrentPlayer]
			vars.inventoryLocked=vars.inventoryLocked or {}
			vars.inventoryLocked[Game.CurrentPlayer]=vars.inventoryLocked[Game.CurrentPlayer] or {}
			if vars.mawbags[pl:GetIndex()] and vars.mawbags[pl:GetIndex()].CurrentBag then
				table.insert(vars.inventoryLocked[Game.CurrentPlayer], vars.mawbags[pl:GetIndex()].CurrentBag)
				Game.ShowStatusText("Inventory number " .. vars.mawbags[pl:GetIndex()].CurrentBag .. " will not be sorted with C"
			else
				table.insert(vars.inventoryLocked[Game.CurrentPlayer],1)
				Game.ShowStatusText("Inventory number " .. 1 .. " will not be sorted with C")
			end
		end
	end
end
]]

function events.KeyDown(t)
    if Game.CurrentScreen == 7 and Game.CurrentCharScreen == 103 then
        if t.Key == const.Keys.C then
			if vars.SmallerPotionBottles then
				for i=220, 299 do
					itemSizeMap[i][2]=1
				end	
			else
				for i=220, 299 do
					itemSizeMap[i][2]=2
				end	
			end
            sortMultibag()
			local name=Party[Game.CurrentPlayer].Name
            Game.ShowStatusText("All " .. name .. "'s bags sorted")
		end
	end
end

function gigaChadSort()
	evt.Add("Items", 0)
	local currentPl=Game.CurrentPlayer
	Game.CurrentPlayer=0
	local playerCurrentInventories={}
	for i=0, Party.High do
		Game.CurrentPlayer=i
		local pl=Party[i]
		if vars.mawbags[pl:GetIndex()] and vars.mawbags[pl:GetIndex()].CurrentBag then
			playerCurrentInventories[i]=vars.mawbags[pl:GetIndex()].CurrentBag
		else
			playerCurrentInventories[i]=1
		end
		changeBag(pl , 0)
		if Party[i].Inventory[0]==0 then
			evt.Add("Items",612)
			evt.Add("Items",612)
			for j=1,14 do
				evt.Add("Items",2080)
			end
			evt.Add("Items",0)
		end
	end
	
	local itemList={}
	local j=0
	for k=0, Party.High do
	local pl=Party[k]
		for bag=1,5 do
			changeBag(pl , bag)
			removeList={}
			for i=0,125 do
				if pl.Inventory[i]>0 then
					if pl.Items[pl.Inventory[i]].BodyLocation==0 then
						removeList[-i-1]=true
					end
					local it=pl.Items[pl.Inventory[i]]
					if it.Number>0 then
						j=j+1
						itemList[j] = {} 
						--iterating doesn't seem to work
						itemList[j]["Bonus"]=it.Bonus
						itemList[j]["Bonus2"]=it.Bonus2
						itemList[j]["BonusExpireTime"]=it.BonusExpireTime
						itemList[j]["BonusStrength"]=it.BonusStrength
						itemList[j]["Broken"]=it.Broken
						itemList[j]["Charges"]=it.Charges
						itemList[j]["Condition"]=it.Condition 
						itemList[j]["Hardened"]=it.Hardened
						itemList[j]["Identified"]=it.Identified
						itemList[j]["MaxCharges"]=it.MaxCharges
						itemList[j]["Number"]=it.Number
						itemList[j]["Owner"]=it.Owner
						itemList[j]["Refundable"]=it.Refundable
						itemList[j]["Stolen"]=it.Stolen
						itemList[j]["TemporaryBonus"]=it.TemporaryBonus
						itemList[j]["size"]=itemSizeMap[it.Number][2]
						if itemList[j]["size"]==1 and itemSizeMap[it.Number][1] >1 then
							itemList[j]["size"]=1.5
						end
						pl.Inventory[i]=0 
						it.Number=0
					end
				end
			end
				
			for i=0,125 do
				if removeList[pl.Inventory[i]] then
					pl.Inventory[i]=0
				end
			end
			vars.alchemyPlayer=vars.alchemyPlayer or -1
		end
	end
	
	table.sort(itemList, function(a, b)
		-- Custom function to find index of an item in alchemyItemsOrder
		local function getIndexInOrder(number)
			for index, value in ipairs(alchemyItemsOrder) do
				if value == number then
					return index
				end
			end
			return nil -- Return nil if the item is not found
		end

		-- Special sorting for items with number >= 220 and < 300
		if vars.alchemyPlayer>=0 then
			if (a["Number"] >= 220 and a["Number"] < 300) or (b["Number"] >= 220 and b["Number"] < 300) then
				-- Ensure that items in the specified range are sorted first and from biggest to smallest
				if (a["Number"] >= 220 and a["Number"] < 300) and (b["Number"] >= 220 and b["Number"] < 300) then
					return a["Number"] > b["Number"] -- Both in range, sort descending
				else
					return a["Number"] >= 220 and a["Number"] < 300 -- Only one in range, it goes first
				end
			end

			-- Sorting according to alchemyItemsOrder
			local indexA = getIndexInOrder(a["Number"])
			local indexB = getIndexInOrder(b["Number"])
			if indexA and indexB then -- If both items are in the list
				return indexA < indexB
			elseif indexA or indexB then -- If only one item is in the list, it goes first
				return indexA ~= nil
			end
		end
		
		-- Original sorting logic
		if a["size"] == b["size"] then
			-- When sizes are equal, compare by skill
			local skillA = Game.ItemsTxt[a["Number"]].Skill
			local skillB = Game.ItemsTxt[b["Number"]].Skill
			
			if skillA == skillB then
				-- If skills are also equal, then sort by item number
				return a["Number"] < b["Number"]
			else
				-- Otherwise, sort by skill
				return skillA < skillB
			end
		else
			-- Primary sort by size
			return a["size"] > b["size"]
		end
	end)
		
	for i=0, Party.High do
		local pl=Party[i]
		changeBag(pl , 1)
	end
	
	--lock alchemy guy
	vars.alchemyPlayer=vars.alchemyPlayer or -1
	if vars.alchemyPlayer>=0 and vars.alchemyPlayer<=Party.High then
		changeBag(Party[vars.alchemyPlayer] , 0)
	end
	
	local currentBag=1
	local currentAlchemyBag=1
	local i=1
	Game.CurrentPlayer=0
	if itemList[1] then
		vars.alchemyPlayer=vars.alchemyPlayer or -1
		lastPlayer=Game.CurrentPlayer
		while i<=#itemList do
			local alchemyItem=false
			if vars.alchemyPlayer>=0 and vars.alchemyPlayer~=Game.CurrentPlayer then
				alchemyPlayer=Party[vars.alchemyPlayer]
				if table.find(alchemyItemsOrder,itemList[i].Number) or (itemList[i].Number>=220 and itemList[i].Number<300) then
					Game.CurrentPlayer=vars.alchemyPlayer
					alchemyItem=true
					for k=0, Party.High do
						local pl=Party[k]
						if k~=vars.alchemyPlayer then
							changeBag(pl , 0)
						end
					end
					changeBag(alchemyPlayer , currentAlchemyBag)
				end
			end
			evt.Add("Items", itemList[i].Number)
			it=Mouse.Item
			it.Bonus=itemList[i].Bonus
			it.Bonus2=itemList[i].Bonus2
			it.BonusExpireTime=itemList[i].BonusExpireTime
			it.BonusStrength=itemList[i].BonusStrength
			it.Broken=itemList[i].Broken
			it.Charges=itemList[i].Charges
			it.Condition=itemList[i].Condition
			it.Hardened=itemList[i].Hardened
			it.Identified=itemList[i].Identified
			it.MaxCharges=itemList[i].MaxCharges
			it.Owner=itemList[i].Owner
			it.Refundable=itemList[i].Refundable
			it.Stolen=itemList[i].Stolen
			it.TemporaryBonus=itemList[i].TemporaryBonus
			BeginGrabObjects()
			evt.Add("Items", 0) --to give item to proper player
			local obj=GrabObjects()
			i=i+1
			
			if not alchemyItem then
				if obj and currentBag~=5 then
					for k=0, Party.High do
						local pl=Party[k]
						if k~=vars.alchemyPlayer then
							changeBag(pl , currentBag+1)
						end
					end
					currentBag=currentBag+1
					obj.Type=0
					obj.TypeIndex=0
					i=i-1
				end
			else
				if not obj then
					changeBag(alchemyPlayer , 0)
					for k=0, Party.High do
						local pl=Party[k]
						if k~=vars.alchemyPlayer then
							changeBag(pl , currentBag)
						else
							changeBag(pl, 0)
						end
					end
				elseif alchemyItem and currentAlchemyBag~=5 then
					changeBag(alchemyPlayer , currentAlchemyBag+1)
					currentAlchemyBag=currentAlchemyBag+1
					obj.Type=0
					obj.TypeIndex=0
					i=i-1
				end
			end
			Game.CurrentPlayer=lastPlayer
		end
	end
	
	for i=0,Party.High do
		if i~=plToSort then
			changeBag(Party[i], playerCurrentInventories[i])
		end
	end
	Game.CurrentPlayer=currentPl
	changeBag(pl, currentBag)
	table.clear(itemList)
end	



function events.KeyDown(t)
    if Game.CurrentScreen == 7 and Game.CurrentCharScreen == 103 then
        if t.Key == const.Keys.G then
			if vars.SmallerPotionBottles then
				for i=220, 299 do
					itemSizeMap[i][2]=1
				end	
			else
				for i=220, 299 do
					itemSizeMap[i][2]=2
				end	
			end
            gigaChadSort()
            Game.ShowStatusText("All Party bags sorted")
		end
	end
end


-- Define the alchemyItemsOrder list for reference in sorting
alchemyItemsOrder = {
	200, 1002, 1764, 201, 1003, 202, 1004, 203, 1005, 204, 1006,
	205, 1007, 1763, 206, 1008, 207, 1009, 208, 1010, 209, 1011,
	210, 1012, 1762, 211, 1013, 212, 1014, 213, 1015, 214, 1016,
	215, 1017, 216, 1018, 217, 1019, 218, 1020, 219, 1021, 
	1064, 1067, 1065, 1063, 1066, 1061, 1062, 1060, 1059, 1058, 1057, 1056, 1055, 1054, 1053, 1052, 1051
}
itemEquipStat={
	[1]=0,
	[2]=1,
	[3]=2,
	[4]=3,
	[5]=4,
	[6]=5,
	[7]=6,
	[8]=7,
	[9]=8,
	[10]=9,
	[11]=10,
	[12]=11,
	[13]=12,
	[14]=13,
	[15]=14,
	[16]=15,
}
itemSizeMap={
	[1]={1,5},
	[2]={1,5},
	[3]={1,5},
	[4]={1,5},
	[5]={1,5},
	[6]={1,6},
	[7]={1,6},
	[8]={1,6},
	[9]={1,6},
	[10]={1,6},
	[11]={1,5},
	[12]={1,5},
	[13]={1,5},
	[14]={1,5},
	[15]={1,5},
	[16]={1,5},
	[17]={1,5},
	[18]={1,5},
	[19]={1,5},
	[20]={1,5},
	[21]={1,3},
	[22]={1,3},
	[23]={1,3},
	[24]={1,3},
	[25]={2,3},
	[26]={1,4},
	[27]={1,4},
	[28]={1,4},
	[29]={1,4},
	[30]={1,4},
	[31]={1,4},
	[32]={1,4},
	[33]={2,4},
	[34]={2,5},
	[35]={2,5},
	[36]={2,7},
	[37]={2,8},
	[38]={2,7},
	[39]={2,8},
	[40]={2,9},
	[41]={1,9},
	[42]={1,9},
	[43]={1,9},
	[44]={2,9},
	[45]={1,9},
	[46]={1,9},
	[47]={2,9},
	[48]={2,9},
	[49]={2,9},
	[50]={2,9},
	[51]={2,8},
	[52]={2,9},
	[53]={2,9},
	[54]={2,9},
	[55]={2,9},
	[56]={2,6},
	[57]={2,6},
	[58]={2,6},
	[59]={2,6},
	[60]={2,6},
	[61]={2,4},
	[62]={2,4},
	[63]={2,4},
	[64]={2,5},
	[65]={2,5},
	[66]={1,5},
	[67]={2,5},
	[68]={2,5},
	[69]={1,7},
	[70]={2,7},
	[71]={2,4},
	[72]={2,4},
	[73]={2,4},
	[74]={2,5},
	[75]={2,5},
	[76]={1,5},
	[77]={2,5},
	[78]={2,6},
	[79]={1,8},
	[80]={1,9},
	[81]={1,9},
	[82]={2,9},
	[83]={2,9},
	[84]={3,3},
	[85]={3,3},
	[86]={3,3},
	[87]={3,3},
	[88]={3,3},
	[89]={2,3},
	[90]={3,4},
	[91]={3,3},
	[92]={3,3},
	[93]={3,3},
	[94]={3,2},
	[95]={3,3},
	[96]={3,3},
	[97]={3,3},
	[98]={3,3},
	[99]={2,4},
	[100]={3,4},
	[101]={3,6},
	[102]={2,6},
	[103]={4,6},
	[104]={2,2},
	[105]={3,3},
	[106]={3,3},
	[107]={3,3},
	[108]={3,4},
	[109]={1,1},
	[110]={2,2},
	[111]={1,2},
	[112]={2,2},
	[113]={2,2},
	[114]={2,1},
	[115]={2,1},
	[116]={1,1},
	[117]={2,1},
	[118]={2,1},
	[119]={2,1},
	[120]={2,1},
	[121]={2,1},
	[122]={2,1},
	[123]={2,2},
	[124]={2,1},
	[125]={2,1},
	[126]={2,2},
	[127]={1,2},
	[128]={1,2},
	[129]={1,2},
	[130]={1,2},
	[131]={1,2},
	[132]={2,2},
	[133]={2,2},
	[134]={2,2},
	[135]={2,2},
	[136]={2,2},
	[137]={1,1},
	[138]={1,1},
	[139]={1,1},
	[140]={1,1},
	[141]={1,1},
	[142]={1,1},
	[143]={1,1},
	[144]={1,1},
	[145]={1,1},
	[146]={1,1},
	[147]={1,2},
	[148]={1,2},
	[149]={1,2},
	[150]={1,2},
	[151]={1,2},
	[152]={1,4},
	[153]={1,4},
	[154]={1,4},
	[155]={1,4},
	[156]={1,4},
	[157]={1,4},
	[158]={1,4},
	[159]={1,4},
	[160]={1,4},
	[161]={1,4},
	[162]={1,4},
	[163]={1,4},
	[164]={1,4},
	[165]={1,4},
	[166]={1,4},
	[167]={1,4},
	[168]={1,4},
	[169]={1,4},
	[170]={1,4},
	[171]={1,4},
	[172]={1,4},
	[173]={1,4},
	[174]={1,4},
	[175]={1,4},
	[176]={1,4},
	[177]={1,1},
	[178]={1,1},
	[179]={1,1},
	[180]={1,1},
	[181]={1,1},
	[182]={1,1},
	[183]={1,1},
	[184]={1,1},
	[185]={1,1},
	[186]={1,1},
	[187]={2,1},
	[188]={2,1},
	[189]={2,2},
	[190]={2,2},
	[191]={2,2},
	[192]={2,2},
	[193]={2,2},
	[194]={2,2},
	[195]={2,2},
	[196]={2,2},
	[197]={2,1},
	[198]={3,1},
	[199]={3,2},
	[200]={1,1},
	[201]={1,1},
	[202]={1,2},
	[203]={1,1},
	[204]={1,2},
	[205]={1,1},
	[206]={1,1},
	[207]={1,1},
	[208]={1,1},
	[209]={1,2},
	[210]={1,1},
	[211]={1,1},
	[212]={1,1},
	[213]={1,1},
	[214]={1,2},
	[215]={1,1},
	[216]={1,1},
	[217]={2,1},
	[218]={1,1},
	[219]={1,1},
	[220]={1,2},
	[221]={1,2},
	[222]={1,2},
	[223]={1,2},
	[224]={1,2},
	[225]={1,2},
	[226]={1,2},
	[227]={1,2},
	[228]={1,2},
	[229]={1,2},
	[230]={1,2},
	[231]={1,2},
	[232]={1,2},
	[233]={1,2},
	[234]={1,2},
	[235]={1,2},
	[236]={1,2},
	[237]={1,2},
	[238]={1,2},
	[239]={1,2},
	[240]={1,2},
	[241]={1,2},
	[242]={1,2},
	[243]={1,2},
	[244]={1,2},
	[245]={1,2},
	[246]={1,2},
	[247]={1,2},
	[248]={1,2},
	[249]={1,2},
	[250]={1,2},
	[251]={1,2},
	[252]={1,2},
	[253]={1,2},
	[254]={1,2},
	[255]={1,2},
	[256]={1,2},
	[257]={1,2},
	[258]={1,2},
	[259]={1,2},
	[260]={1,2},
	[261]={1,2},
	[262]={1,2},
	[263]={1,2},
	[264]={1,2},
	[265]={1,2},
	[266]={1,2},
	[267]={1,2},
	[268]={1,2},
	[269]={1,2},
	[270]={1,2},
	[271]={1,2},
	[272]={1,2},
	[273]={1,2},
	[274]={1,2},
	[275]={1,2},
	[276]={1,2},
	[277]={1,2},
	[278]={1,2},
	[279]={1,2},
	[280]={1,2},
	[281]={1,2},
	[282]={1,2},
	[283]={1,2},
	[284]={1,2},
	[285]={1,2},
	[286]={1,2},
	[287]={1,2},
	[288]={1,2},
	[289]={1,2},
	[290]={1,2},
	[291]={2,2},
	[292]={2,2},
	[293]={2,2},
	[294]={2,2},
	[295]={2,2},
	[296]={2,2},
	[297]={2,2},
	[298]={2,2},
	[299]={2,2},
	[300]={2,1},
	[301]={2,1},
	[302]={2,1},
	[303]={2,1},
	[304]={2,1},
	[305]={2,1},
	[306]={2,1},
	[307]={2,1},
	[308]={2,1},
	[309]={2,1},
	[310]={2,1},
	[311]={2,1},
	[312]={2,1},
	[313]={2,1},
	[314]={2,1},
	[315]={2,1},
	[316]={2,1},
	[317]={2,1},
	[318]={2,1},
	[319]={2,1},
	[320]={2,1},
	[321]={2,1},
	[322]={2,1},
	[323]={2,1},
	[324]={2,1},
	[325]={2,1},
	[326]={2,1},
	[327]={2,1},
	[328]={2,1},
	[329]={2,1},
	[330]={2,1},
	[331]={2,1},
	[332]={2,1},
	[333]={2,1},
	[334]={2,1},
	[335]={2,1},
	[336]={2,1},
	[337]={2,1},
	[338]={2,1},
	[339]={2,1},
	[340]={2,1},
	[341]={2,1},
	[342]={2,1},
	[343]={2,1},
	[344]={2,1},
	[345]={2,1},
	[346]={2,1},
	[347]={2,1},
	[348]={2,1},
	[349]={2,1},
	[350]={2,1},
	[351]={2,1},
	[352]={2,1},
	[353]={2,1},
	[354]={2,1},
	[355]={2,1},
	[356]={2,1},
	[357]={2,1},
	[358]={2,1},
	[359]={2,1},
	[360]={2,1},
	[361]={2,1},
	[362]={2,1},
	[363]={2,1},
	[364]={2,1},
	[365]={2,1},
	[366]={2,1},
	[367]={2,1},
	[368]={2,1},
	[369]={2,1},
	[370]={2,1},
	[371]={2,1},
	[372]={2,1},
	[373]={2,1},
	[374]={2,1},
	[375]={2,1},
	[376]={2,1},
	[377]={2,1},
	[378]={2,1},
	[379]={2,1},
	[380]={2,1},
	[381]={2,1},
	[382]={2,1},
	[383]={2,1},
	[384]={2,1},
	[385]={2,1},
	[386]={2,1},
	[387]={2,1},
	[388]={2,1},
	[389]={2,1},
	[390]={2,1},
	[391]={2,1},
	[392]={2,1},
	[393]={2,1},
	[394]={2,1},
	[395]={2,1},
	[396]={2,1},
	[397]={2,1},
	[398]={2,1},
	[399]={2,2},
	[400]={2,2},
	[401]={2,2},
	[402]={2,2},
	[403]={2,2},
	[404]={2,2},
	[405]={2,2},
	[406]={2,2},
	[407]={2,2},
	[408]={2,2},
	[409]={2,2},
	[410]={2,2},
	[411]={2,2},
	[412]={2,2},
	[413]={2,2},
	[414]={2,2},
	[415]={2,2},
	[416]={2,2},
	[417]={2,2},
	[418]={2,2},
	[419]={2,2},
	[420]={2,2},
	[421]={2,2},
	[422]={2,2},
	[423]={2,2},
	[424]={2,2},
	[425]={2,2},
	[426]={2,2},
	[427]={2,2},
	[428]={2,2},
	[429]={2,2},
	[430]={2,2},
	[431]={2,2},
	[432]={2,2},
	[433]={2,2},
	[434]={2,2},
	[435]={2,2},
	[436]={2,2},
	[437]={2,2},
	[438]={2,2},
	[439]={2,2},
	[440]={2,2},
	[441]={2,2},
	[442]={2,2},
	[443]={2,2},
	[444]={2,2},
	[445]={2,2},
	[446]={2,2},
	[447]={2,2},
	[448]={2,2},
	[449]={2,2},
	[450]={2,2},
	[451]={2,2},
	[452]={2,2},
	[453]={2,2},
	[454]={2,2},
	[455]={2,2},
	[456]={2,2},
	[457]={2,2},
	[458]={2,2},
	[459]={2,2},
	[460]={2,2},
	[461]={2,2},
	[462]={2,2},
	[463]={2,2},
	[464]={2,2},
	[465]={2,2},
	[466]={2,2},
	[467]={2,2},
	[468]={2,2},
	[469]={2,2},
	[470]={2,2},
	[471]={2,2},
	[472]={2,2},
	[473]={2,2},
	[474]={2,2},
	[475]={2,2},
	[476]={2,2},
	[477]={2,2},
	[478]={2,2},
	[479]={2,2},
	[480]={2,2},
	[481]={2,2},
	[482]={2,2},
	[483]={2,2},
	[484]={2,2},
	[485]={2,2},
	[486]={2,2},
	[487]={2,2},
	[488]={2,2},
	[489]={2,2},
	[490]={2,2},
	[491]={2,2},
	[492]={2,2},
	[493]={2,2},
	[494]={2,2},
	[495]={2,2},
	[496]={2,2},
	[497]={2,2},
	[498]={2,2},
	[499]={2,2},
	[500]={2,6},
	[501]={2,6},
	[502]={1,5},
	[503]={2,5},
	[504]={2,5},
	[505]={2,8},
	[506]={1,9},
	[507]={3,9},
	[508]={1,4},
	[509]={1,7},
	[510]={2,8},
	[511]={2,9},
	[512]={2,6},
	[513]={3,4},
	[514]={3,3},
	[515]={3,3},
	[516]={3,5},
	[517]={1,2},
	[518]={2,2},
	[519]={1,1},
	[520]={2,2},
	[521]={2,2},
	[522]={2,1},
	[523]={2,6},
	[524]={1,5},
	[525]={1,6},
	[526]={2,5},
	[527]={2,9},
	[528]={1,9},
	[529]={1,3},
	[530]={2,9},
	[531]={2,6},
	[532]={2,5},
	[533]={3,4},
	[534]={4,4},
	[535]={1,1},
	[536]={2,1},
	[537]={2,1},
	[538]={2,5},
	[539]={1,9},
	[540]={1,6},
	[541]={2,9},
	[542]={2,6},
	[543]={1,1},
	[544]={2,2},
	[545]={2,2},
	[546]={2,2},
	[547]={2,2},
	[548]={2,2},
	[549]={2,2},
	[550]={2,2},
	[551]={2,2},
	[552]={2,2},
	[553]={2,2},
	[554]={2,2},
	[555]={2,2},
	[556]={2,2},
	[557]={2,2},
	[558]={2,2},
	[559]={2,2},
	[560]={2,2},
	[561]={2,2},
	[562]={2,2},
	[563]={2,2},
	[564]={2,2},
	[565]={2,2},
	[566]={2,2},
	[567]={2,2},
	[568]={2,2},
	[569]={2,2},
	[570]={2,2},
	[571]={2,2},
	[572]={2,2},
	[573]={2,2},
	[574]={2,2},
	[575]={2,2},
	[576]={2,2},
	[577]={2,2},
	[578]={2,2},
	[579]={2,2},
	[580]={2,2},
	[581]={2,2},
	[582]={2,2},
	[583]={2,2},
	[584]={2,2},
	[585]={2,2},
	[586]={2,2},
	[587]={2,2},
	[588]={2,2},
	[589]={2,2},
	[590]={2,2},
	[591]={2,2},
	[592]={2,2},
	[593]={2,2},
	[594]={2,2},
	[595]={2,2},
	[596]={2,2},
	[597]={2,2},
	[598]={2,2},
	[599]={2,2},
	[600]={2,2},
	[601]={2,2},
	[602]={2,1},
	[603]={2,2},
	[604]={2,2},
	[605]={1,1},
	[606]={1,1},
	[607]={1,1},
	[608]={1,1},
	[609]={1,1},
	[610]={2,2},
	[611]={2,2},
	[612]={14,4},
	[613]={1,1},
	[614]={1,2},
	[615]={2,2},
	[616]={1,2},
	[617]={1,1},
	[618]={1,1},
	[619]={1,2},
	[620]={1,2},
	[621]={1,2},
	[622]={2,2},
	[623]={1,1},
	[624]={1,1},
	[625]={1,1},
	[626]={2,2},
	[627]={3,1},
	[628]={2,2},
	[629]={2,2},
	[630]={2,4},
	[631]={2,2},
	[632]={2,4},
	[633]={3,4},
	[634]={2,1},
	[635]={1,2},
	[636]={2,2},
	[637]={1,2},
	[638]={2,1},
	[639]={1,1},
	[640]={2,1},
	[641]={1,1},
	[642]={2,1},
	[643]={2,2},
	[644]={1,2},
	[645]={1,2},
	[646]={4,2},
	[647]={4,4},
	[648]={4,4},
	[649]={4,4},
	[650]={2,1},
	[651]={4,4},
	[652]={2,2},
	[653]={1,1},
	[654]={2,1},
	[655]={1,1},
	[656]={1,1},
	[657]={1,2},
	[658]={2,1},
	[659]={2,1},
	[660]={1,1},
	[661]={1,2},
	[662]={2,2},
	[663]={1,2},
	[664]={1,1},
	[665]={2,1},
	[666]={1,4},
	[667]={2,2},
	[668]={2,2},
	[669]={2,2},
	[670]={2,2},
	[671]={2,2},
	[672]={2,2},
	[673]={2,2},
	[674]={2,2},
	[675]={2,2},
	[676]={2,2},
	[677]={2,2},
	[678]={2,2},
	[679]={2,2},
	[680]={2,2},
	[681]={2,2},
	[682]={2,2},
	[683]={2,2},
	[684]={2,2},
	[685]={2,2},
	[686]={1,1},
	[687]={1,1},
	[688]={1,1},
	[689]={1,1},
	[690]={1,1},
	[691]={1,1},
	[692]={2,2},
	[693]={2,2},
	[694]={2,2},
	[695]={2,2},
	[696]={2,2},
	[697]={2,2},
	[698]={2,2},
	[699]={2,2},
	[700]={2,1},
	[701]={2,1},
	[702]={2,1},
	[703]={2,1},
	[704]={2,1},
	[705]={2,1},
	[706]={2,1},
	[707]={2,1},
	[708]={2,1},
	[709]={2,1},
	[710]={2,1},
	[711]={2,1},
	[712]={2,1},
	[713]={2,1},
	[714]={2,1},
	[715]={2,1},
	[716]={2,1},
	[717]={2,1},
	[718]={2,1},
	[719]={2,1},
	[720]={2,1},
	[721]={2,1},
	[722]={2,1},
	[723]={2,1},
	[724]={2,1},
	[725]={2,1},
	[726]={2,1},
	[727]={2,1},
	[728]={2,1},
	[729]={2,1},
	[730]={2,1},
	[731]={2,1},
	[732]={2,1},
	[733]={2,1},
	[734]={2,1},
	[735]={2,1},
	[736]={2,1},
	[737]={2,1},
	[738]={2,1},
	[739]={2,1},
	[740]={2,1},
	[741]={2,2},
	[742]={2,2},
	[743]={2,1},
	[744]={2,2},
	[745]={2,1},
	[746]={2,2},
	[747]={2,2},
	[748]={2,1},
	[749]={2,1},
	[750]={2,1},
	[751]={2,1},
	[752]={2,1},
	[753]={2,1},
	[754]={2,1},
	[755]={2,1},
	[756]={2,1},
	[757]={2,1},
	[758]={2,1},
	[759]={2,1},
	[760]={2,1},
	[761]={2,1},
	[762]={2,1},
	[763]={2,1},
	[764]={2,1},
	[765]={2,1},
	[766]={2,1},
	[767]={2,1},
	[768]={2,1},
	[769]={2,1},
	[770]={2,2},
	[771]={2,2},
	[772]={2,2},
	[773]={2,2},
	[774]={2,1},
	[775]={2,2},
	[776]={2,2},
	[777]={2,2},
	[778]={2,2},
	[779]={2,2},
	[780]={2,2},
	[781]={2,2},
	[782]={2,2},
	[783]={2,2},
	[784]={2,2},
	[785]={2,2},
	[786]={2,2},
	[787]={2,2},
	[788]={2,2},
	[789]={2,2},
	[790]={2,2},
	[791]={2,2},
	[792]={2,2},
	[793]={2,2},
	[794]={2,2},
	[795]={2,2},
	[796]={2,2},
	[797]={2,2},
	[798]={2,2},
	[799]={2,2},
	[800]={2,1},
	[801]={2,1},
	[802]={1,1},
	[803]={1,5},
	[804]={1,6},
	[805]={1,5},
	[806]={1,5},
	[807]={1,6},
	[808]={1,6},
	[809]={2,6},
	[810]={2,6},
	[811]={1,5},
	[812]={1,5},
	[813]={1,5},
	[814]={1,4},
	[815]={1,5},
	[816]={1,5},
	[817]={1,3},
	[818]={1,3},
	[819]={1,3},
	[820]={1,3},
	[821]={1,3},
	[822]={1,4},
	[823]={1,3},
	[824]={1,4},
	[825]={1,4},
	[826]={2,4},
	[827]={1,4},
	[828]={1,5},
	[829]={2,5},
	[830]={2,7},
	[831]={2,9},
	[832]={1,9},
	[833]={1,8},
	[834]={1,9},
	[835]={1,9},
	[836]={1,9},
	[837]={1,9},
	[838]={2,9},
	[839]={2,9},
	[840]={2,9},
	[841]={1,8},
	[842]={1,9},
	[843]={2,9},
	[844]={2,7},
	[845]={2,7},
	[846]={2,7},
	[847]={2,7},
	[848]={3,6},
	[849]={2,6},
	[850]={1,4},
	[851]={2,4},
	[852]={1,4},
	[853]={1,4},
	[854]={1,4},
	[855]={1,4},
	[856]={2,4},
	[857]={1,4},
	[858]={2,4},
	[859]={2,4},
	[860]={1,5},
	[861]={1,4},
	[862]={1,4},
	[863]={1,8},
	[864]={1,9},
	[865]={1,9},
	[866]={2,1},
	[867]={1,4},
	[868]={3,4},
	[869]={3,4},
	[870]={3,3},
	[871]={3,4},
	[872]={4,3},
	[873]={3,5},
	[874]={3,5},
	[875]={3,5},
	[876]={4,4},
	[877]={3,5},
	[878]={4,3},
	[879]={4,4},
	[880]={4,4},
	[881]={3,4},
	[882]={3,4},
	[883]={3,6},
	[884]={3,6},
	[885]={3,5},
	[886]={2,2},
	[887]={3,3},
	[888]={3,3},
	[889]={3,3},
	[890]={3,4},
	[891]={1,2},
	[892]={1,1},
	[893]={2,2},
	[894]={2,2},
	[895]={2,2},
	[896]={2,2},
	[897]={2,1},
	[898]={1,1},
	[899]={2,1},
	[900]={2,2},
	[901]={2,2},
	[902]={2,1},
	[903]={2,1},
	[904]={2,1},
	[905]={2,1},
	[906]={2,1},
	[907]={2,1},
	[908]={2,1},
	[909]={2,1},
	[910]={2,1},
	[911]={2,1},
	[912]={1,2},
	[913]={1,2},
	[914]={1,2},
	[915]={1,2},
	[916]={1,2},
	[917]={2,2},
	[918]={2,2},
	[919]={3,3},
	[920]={2,3},
	[921]={2,3},
	[922]={1,1},
	[923]={1,1},
	[924]={1,1},
	[925]={1,1},
	[926]={1,1},
	[927]={1,1},
	[928]={1,1},
	[929]={1,1},
	[930]={1,1},
	[931]={1,1},
	[932]={1,2},
	[933]={1,1},
	[934]={1,2},
	[935]={1,1},
	[936]={1,1},
	[937]={1,4},
	[938]={1,4},
	[939]={1,4},
	[940]={1,4},
	[941]={1,4},
	[942]={1,5},
	[943]={1,5},
	[944]={1,5},
	[945]={1,5},
	[946]={1,5},
	[947]={1,4},
	[948]={1,4},
	[949]={1,4},
	[950]={1,4},
	[951]={1,4},
	[952]={1,4},
	[953]={1,4},
	[954]={1,4},
	[955]={1,4},
	[956]={1,4},
	[957]={2,5},
	[958]={2,5},
	[959]={2,5},
	[960]={2,5},
	[961]={2,5},
	[962]={2,2},
	[963]={2,2},
	[964]={2,2},
	[965]={2,2},
	[966]={2,2},
	[967]={2,2},
	[968]={2,2},
	[969]={2,2},
	[970]={2,2},
	[971]={2,2},
	[972]={2,2},
	[973]={2,2},
	[974]={2,2},
	[975]={2,2},
	[976]={2,2},
	[977]={2,2},
	[978]={2,2},
	[979]={2,2},
	[980]={2,2},
	[981]={2,2},
	[982]={2,2},
	[983]={2,2},
	[984]={2,2},
	[985]={2,2},
	[986]={2,2},
	[987]={2,2},
	[988]={1,1},
	[989]={1,1},
	[990]={1,1},
	[991]={1,1},
	[992]={1,1},
	[993]={1,1},
	[994]={1,1},
	[995]={1,1},
	[996]={1,1},
	[997]={1,1},
	[998]={1,1},
	[999]={2,1},
	[1000]={3,1},
	[1001]={3,2},
	[1002]={1,1},
	[1003]={1,1},
	[1004]={1,2},
	[1005]={1,1},
	[1006]={1,1},
	[1007]={1,1},
	[1008]={1,1},
	[1009]={1,2},
	[1010]={1,1},
	[1011]={1,1},
	[1012]={1,1},
	[1013]={1,2},
	[1014]={1,1},
	[1015]={1,1},
	[1016]={1,2},
	[1017]={1,1},
	[1018]={1,1},
	[1019]={1,2},
	[1020]={1,2},
	[1021]={1,1},
	[1022]={1,1},
	[1023]={1,1},
	[1024]={2,2},
	[1025]={2,2},
	[1026]={2,2},
	[1027]={2,2},
	[1028]={2,2},
	[1029]={2,2},
	[1030]={2,2},
	[1031]={2,2},
	[1032]={2,2},
	[1033]={2,2},
	[1034]={2,2},
	[1035]={2,2},
	[1036]={2,2},
	[1037]={2,2},
	[1038]={2,2},
	[1039]={2,2},
	[1040]={2,2},
	[1041]={2,2},
	[1042]={2,2},
	[1043]={2,2},
	[1044]={2,2},
	[1045]={2,2},
	[1046]={2,2},
	[1047]={2,2},
	[1048]={2,2},
	[1049]={2,2},
	[1050]={2,2},
	[1051]={1,1},
	[1052]={1,1},
	[1053]={1,1},
	[1054]={1,1},
	[1055]={1,1},
	[1056]={1,1},
	[1057]={1,1},
	[1058]={1,1},
	[1059]={1,1},
	[1060]={1,1},
	[1061]={1,2},
	[1062]={1,3},
	[1063]={1,1},
	[1064]={1,2},
	[1065]={1,2},
	[1066]={1,1},
	[1067]={2,2},
	[1068]={2,2},
	[1069]={2,2},
	[1070]={2,2},
	[1071]={2,2},
	[1072]={2,2},
	[1073]={2,2},
	[1074]={2,2},
	[1075]={2,2},
	[1076]={2,2},
	[1077]={2,2},
	[1078]={2,2},
	[1079]={2,2},
	[1080]={2,2},
	[1081]={2,2},
	[1082]={2,2},
	[1083]={2,2},
	[1084]={2,2},
	[1085]={2,2},
	[1086]={2,2},
	[1087]={2,2},
	[1088]={2,2},
	[1089]={2,2},
	[1090]={2,2},
	[1091]={2,2},
	[1092]={2,2},
	[1093]={2,2},
	[1094]={2,2},
	[1095]={2,2},
	[1096]={2,2},
	[1097]={2,2},
	[1098]={2,2},
	[1099]={2,2},
	[1100]={2,2},
	[1101]={2,2},
	[1102]={2,1},
	[1103]={2,1},
	[1104]={2,1},
	[1105]={2,1},
	[1106]={2,1},
	[1107]={2,1},
	[1108]={2,1},
	[1109]={2,1},
	[1110]={2,1},
	[1111]={2,1},
	[1112]={2,1},
	[1113]={2,1},
	[1114]={2,1},
	[1115]={2,1},
	[1116]={2,1},
	[1117]={2,1},
	[1118]={2,1},
	[1119]={2,1},
	[1120]={2,1},
	[1121]={2,1},
	[1122]={2,1},
	[1123]={2,1},
	[1124]={2,1},
	[1125]={2,1},
	[1126]={2,1},
	[1127]={2,1},
	[1128]={2,1},
	[1129]={2,1},
	[1130]={2,1},
	[1131]={2,1},
	[1132]={2,1},
	[1133]={2,1},
	[1134]={2,1},
	[1135]={2,1},
	[1136]={2,1},
	[1137]={2,1},
	[1138]={2,1},
	[1139]={2,1},
	[1140]={2,1},
	[1141]={2,1},
	[1142]={2,1},
	[1143]={2,1},
	[1144]={2,1},
	[1145]={2,1},
	[1146]={2,1},
	[1147]={2,1},
	[1148]={2,1},
	[1149]={2,1},
	[1150]={2,1},
	[1151]={2,1},
	[1152]={2,1},
	[1153]={2,1},
	[1154]={2,1},
	[1155]={2,1},
	[1156]={2,1},
	[1157]={2,1},
	[1158]={2,1},
	[1159]={2,1},
	[1160]={2,1},
	[1161]={2,1},
	[1162]={2,1},
	[1163]={2,1},
	[1164]={2,1},
	[1165]={2,1},
	[1166]={2,1},
	[1167]={2,1},
	[1168]={2,1},
	[1169]={2,1},
	[1170]={2,1},
	[1171]={2,1},
	[1172]={2,1},
	[1173]={2,1},
	[1174]={2,1},
	[1175]={2,1},
	[1176]={2,1},
	[1177]={2,1},
	[1178]={2,1},
	[1179]={2,1},
	[1180]={2,1},
	[1181]={2,1},
	[1182]={2,1},
	[1183]={2,1},
	[1184]={2,1},
	[1185]={2,1},
	[1186]={2,1},
	[1187]={2,1},
	[1188]={2,1},
	[1189]={2,1},
	[1190]={2,1},
	[1191]={2,1},
	[1192]={2,1},
	[1193]={2,1},
	[1194]={2,1},
	[1195]={2,1},
	[1196]={2,1},
	[1197]={2,1},
	[1198]={2,1},
	[1199]={2,1},
	[1200]={2,1},
	[1201]={2,2},
	[1202]={2,2},
	[1203]={2,2},
	[1204]={2,2},
	[1205]={2,2},
	[1206]={2,2},
	[1207]={2,2},
	[1208]={2,2},
	[1209]={2,2},
	[1210]={2,2},
	[1211]={2,2},
	[1212]={2,2},
	[1213]={2,2},
	[1214]={2,2},
	[1215]={2,2},
	[1216]={2,2},
	[1217]={2,2},
	[1218]={2,2},
	[1219]={2,2},
	[1220]={2,2},
	[1221]={2,2},
	[1222]={2,2},
	[1223]={2,2},
	[1224]={2,2},
	[1225]={2,2},
	[1226]={2,2},
	[1227]={2,2},
	[1228]={2,2},
	[1229]={2,2},
	[1230]={2,2},
	[1231]={2,2},
	[1232]={2,2},
	[1233]={2,2},
	[1234]={2,2},
	[1235]={2,2},
	[1236]={2,2},
	[1237]={2,2},
	[1238]={2,2},
	[1239]={2,2},
	[1240]={2,2},
	[1241]={2,2},
	[1242]={2,2},
	[1243]={2,2},
	[1244]={2,2},
	[1245]={2,2},
	[1246]={2,2},
	[1247]={2,2},
	[1248]={2,2},
	[1249]={2,2},
	[1250]={2,2},
	[1251]={2,2},
	[1252]={2,2},
	[1253]={2,2},
	[1254]={2,2},
	[1255]={2,2},
	[1256]={2,2},
	[1257]={2,2},
	[1258]={2,2},
	[1259]={2,2},
	[1260]={2,2},
	[1261]={2,2},
	[1262]={2,2},
	[1263]={2,2},
	[1264]={2,2},
	[1265]={2,2},
	[1266]={2,2},
	[1267]={2,2},
	[1268]={2,2},
	[1269]={2,2},
	[1270]={2,2},
	[1271]={2,2},
	[1272]={2,2},
	[1273]={2,2},
	[1274]={2,2},
	[1275]={2,2},
	[1276]={2,2},
	[1277]={2,2},
	[1278]={2,2},
	[1279]={2,2},
	[1280]={2,2},
	[1281]={2,2},
	[1282]={2,2},
	[1283]={2,2},
	[1284]={2,2},
	[1285]={2,2},
	[1286]={2,2},
	[1287]={2,2},
	[1288]={2,2},
	[1289]={2,2},
	[1290]={2,2},
	[1291]={2,2},
	[1292]={2,2},
	[1293]={2,2},
	[1294]={2,2},
	[1295]={2,2},
	[1296]={2,2},
	[1297]={2,2},
	[1298]={2,2},
	[1299]={2,2},
	[1300]={2,2},
	[1301]={2,2},
	[1302]={2,6},
	[1303]={1,6},
	[1304]={1,5},
	[1305]={1,5},
	[1306]={3,5},
	[1307]={4,4},
	[1308]={2,4},
	[1309]={3,9},
	[1310]={1,9},
	[1311]={2,9},
	[1312]={2,8},
	[1313]={1,2},
	[1314]={3,3},
	[1315]={1,1},
	[1316]={1,4},
	[1317]={2,9},
	[1318]={4,3},
	[1319]={1,3},
	[1320]={2,5},
	[1321]={4,4},
	[1322]={3,3},
	[1323]={2,2},
	[1324]={2,2},
	[1325]={2,2},
	[1326]={2,1},
	[1327]={2,1},
	[1328]={2,4},
	[1329]={2,4},
	[1330]={2,4},
	[1331]={2,2},
	[1332]={2,1},
	[1333]={2,6},
	[1334]={2,2},
	[1335]={3,5},
	[1336]={1,2},
	[1337]={2,1},
	[1338]={1,1},
	[1339]={1,1},
	[1340]={1,5},
	[1341]={1,1},
	[1342]={1,3},
	[1343]={1,6},
	[1344]={2,7},
	[1345]={2,7},
	[1346]={2,2},
	[1347]={1,1},
	[1348]={1,1},
	[1349]={2,1},
	[1350]={2,1},
	[1351]={1,9},
	[1352]={2,1},
	[1353]={2,5},
	[1354]={1,5},
	[1355]={2,2},
	[1356]={2,2},
	[1357]={2,2},
	[1358]={2,2},
	[1359]={2,2},
	[1360]={2,2},
	[1361]={2,2},
	[1362]={2,2},
	[1363]={2,2},
	[1364]={2,2},
	[1365]={2,2},
	[1366]={2,2},
	[1367]={2,2},
	[1368]={2,2},
	[1369]={2,2},
	[1370]={2,2},
	[1371]={2,2},
	[1372]={2,2},
	[1373]={2,2},
	[1374]={2,2},
	[1375]={2,2},
	[1376]={2,2},
	[1377]={2,2},
	[1378]={2,2},
	[1379]={2,2},
	[1380]={2,2},
	[1381]={2,2},
	[1382]={2,2},
	[1383]={2,2},
	[1384]={2,2},
	[1385]={2,2},
	[1386]={2,2},
	[1387]={2,2},
	[1388]={2,2},
	[1389]={2,2},
	[1390]={2,2},
	[1391]={2,2},
	[1392]={2,2},
	[1393]={2,2},
	[1394]={2,2},
	[1395]={2,2},
	[1396]={2,2},
	[1397]={2,2},
	[1398]={2,2},
	[1399]={2,2},
	[1400]={2,2},
	[1401]={2,2},
	[1402]={1,1},
	[1403]={1,2},
	[1404]={4,3},
	[1405]={1,2},
	[1406]={3,4},
	[1407]={1,2},
	[1408]={1,1},
	[1409]={2,2},
	[1410]={2,2},
	[1411]={2,2},
	[1412]={2,2},
	[1413]={2,2},
	[1414]={2,2},
	[1415]={2,2},
	[1416]={2,2},
	[1417]={1,2},
	[1418]={2,1},
	[1419]={1,2},
	[1420]={2,2},
	[1421]={2,4},
	[1422]={2,7},
	[1423]={2,3},
	[1424]={2,3},
	[1425]={2,3},
	[1426]={1,2},
	[1427]={1,2},
	[1428]={1,1},
	[1429]={2,1},
	[1430]={1,2},
	[1431]={1,2},
	[1432]={1,1},
	[1433]={2,2},
	[1434]={2,4},
	[1435]={2,2},
	[1436]={1,3},
	[1437]={2,1},
	[1438]={2,1},
	[1439]={2,2},
	[1440]={2,2},
	[1441]={3,2},
	[1442]={2,2},
	[1443]={2,2},
	[1444]={4,1},
	[1445]={4,1},
	[1446]={3,1},
	[1447]={3,1},
	[1448]={1,1},
	[1449]={1,1},
	[1450]={1,2},
	[1451]={2,2},
	[1452]={2,2},
	[1453]={1,1},
	[1454]={1,2},
	[1455]={1,2},
	[1456]={1,2},
	[1457]={1,2},
	[1458]={1,2},
	[1459]={1,2},
	[1460]={3,4},
	[1461]={1,2},
	[1462]={1,2},
	[1463]={1,2},
	[1464]={1,2},
	[1465]={1,2},
	[1466]={1,2},
	[1467]={1,2},
	[1468]={1,2},
	[1469]={1,2},
	[1470]={1,2},
	[1471]={1,2},
	[1472]={1,2},
	[1473]={2,2},
	[1474]={2,2},
	[1475]={2,1},
	[1476]={2,1},
	[1477]={1,1},
	[1478]={1,2},
	[1479]={1,2},
	[1480]={2,1},
	[1481]={2,1},
	[1482]={2,1},
	[1483]={2,1},
	[1484]={2,1},
	[1485]={2,1},
	[1486]={2,1},
	[1487]={2,1},
	[1488]={1,1},
	[1489]={1,1},
	[1490]={1,1},
	[1491]={1,1},
	[1492]={1,1},
	[1493]={1,1},
	[1494]={4,3},
	[1495]={4,3},
	[1496]={4,3},
	[1497]={4,3},
	[1498]={4,3},
	[1499]={4,3},
	[1500]={2,1},
	[1501]={2,1},
	[1502]={2,1},
	[1503]={2,1},
	[1504]={2,1},
	[1505]={2,1},
	[1506]={2,1},
	[1507]={2,1},
	[1508]={2,1},
	[1509]={2,1},
	[1510]={2,1},
	[1511]={2,1},
	[1512]={2,1},
	[1513]={2,1},
	[1514]={2,1},
	[1515]={2,1},
	[1516]={2,1},
	[1517]={2,1},
	[1518]={2,1},
	[1519]={2,1},
	[1520]={2,1},
	[1521]={2,1},
	[1522]={2,1},
	[1523]={2,1},
	[1524]={2,1},
	[1525]={2,1},
	[1526]={2,1},
	[1527]={2,1},
	[1528]={2,1},
	[1529]={2,1},
	[1530]={2,1},
	[1531]={2,1},
	[1532]={2,1},
	[1533]={2,1},
	[1534]={2,1},
	[1535]={2,1},
	[1536]={2,1},
	[1537]={2,1},
	[1538]={2,1},
	[1539]={2,1},
	[1540]={2,1},
	[1541]={2,1},
	[1542]={2,1},
	[1543]={2,1},
	[1544]={2,1},
	[1545]={2,1},
	[1546]={2,1},
	[1547]={2,1},
	[1548]={2,1},
	[1549]={2,1},
	[1550]={2,1},
	[1551]={2,1},
	[1552]={2,1},
	[1553]={2,1},
	[1554]={2,1},
	[1555]={2,1},
	[1556]={2,1},
	[1557]={2,1},
	[1558]={2,1},
	[1559]={2,1},
	[1560]={2,1},
	[1561]={2,1},
	[1562]={2,1},
	[1563]={2,1},
	[1564]={2,1},
	[1565]={2,1},
	[1566]={2,1},
	[1567]={2,1},
	[1568]={2,1},
	[1569]={2,1},
	[1570]={2,1},
	[1571]={2,1},
	[1572]={2,1},
	[1573]={2,1},
	[1574]={2,1},
	[1575]={2,1},
	[1576]={2,1},
	[1577]={2,1},
	[1578]={2,1},
	[1579]={2,1},
	[1580]={2,1},
	[1581]={2,1},
	[1582]={2,1},
	[1583]={2,2},
	[1584]={2,2},
	[1585]={2,2},
	[1586]={2,2},
	[1587]={2,2},
	[1588]={2,2},
	[1589]={2,2},
	[1590]={2,2},
	[1591]={2,2},
	[1592]={2,2},
	[1593]={2,2},
	[1594]={2,2},
	[1595]={2,2},
	[1596]={2,2},
	[1597]={2,2},
	[1598]={2,2},
	[1599]={2,2},
	[1600]={2,2},
	[1601]={2,2},
	[1602]={2,2},
	[1603]={1,6},
	[1604]={1,6},
	[1605]={1,6},
	[1606]={1,6},
	[1607]={1,6},
	[1608]={2,7},
	[1609]={2,7},
	[1610]={1,7},
	[1611]={1,6},
	[1612]={1,6},
	[1613]={1,6},
	[1614]={1,6},
	[1615]={1,6},
	[1616]={1,6},
	[1617]={1,3},
	[1618]={1,4},
	[1619]={1,4},
	[1620]={1,3},
	[1621]={1,4},
	[1622]={1,5},
	[1623]={1,5},
	[1624]={1,4},
	[1625]={1,3},
	[1626]={2,5},
	[1627]={1,4},
	[1628]={1,4},
	[1629]={2,5},
	[1630]={2,6},
	[1631]={1,8},
	[1632]={2,8},
	[1633]={1,9},
	[1634]={1,9},
	[1635]={1,9},
	[1636]={1,9},
	[1637]={1,9},
	[1638]={2,9},
	[1639]={2,9},
	[1640]={2,9},
	[1641]={2,9},
	[1642]={2,9},
	[1643]={2,9},
	[1644]={1,8},
	[1645]={1,7},
	[1646]={1,7},
	[1647]={1,6},
	[1648]={2,7},
	[1649]={2,5},
	[1650]={3,5},
	[1651]={2,5},
	[1652]={1,4},
	[1653]={1,5},
	[1654]={2,5},
	[1655]={1,4},
	[1656]={2,4},
	[1657]={2,5},
	[1658]={2,5},
	[1659]={1,4},
	[1660]={1,5},
	[1661]={1,6},
	[1662]={1,5},
	[1663]={1,7},
	[1664]={1,9},
	[1665]={2,9},
	[1666]={1,3},
	[1667]={2,7},
	[1668]={2,4},
	[1669]={3,3},
	[1670]={3,5},
	[1671]={4,4},
	[1672]={3,5},
	[1673]={3,5},
	[1674]={3,5},
	[1675]={4,5},
	[1676]={4,5},
	[1677]={4,5},
	[1678]={4,6},
	[1679]={4,6},
	[1680]={4,6},
	[1681]={3,5},
	[1682]={3,4},
	[1683]={3,4},
	[1684]={3,3},
	[1685]={3,3},
	[1686]={2,2},
	[1687]={2,2},
	[1688]={2,3},
	[1689]={3,3},
	[1690]={2,3},
	[1691]={1,1},
	[1692]={2,2},
	[1693]={2,2},
	[1694]={2,2},
	[1695]={2,2},
	[1696]={2,1},
	[1697]={2,1},
	[1698]={2,2},
	[1699]={2,1},
	[1700]={1,1},
	[1701]={1,1},
	[1702]={2,1},
	[1703]={2,1},
	[1704]={2,1},
	[1705]={2,1},
	[1706]={2,1},
	[1707]={2,1},
	[1708]={2,1},
	[1709]={2,1},
	[1710]={2,1},
	[1711]={3,1},
	[1712]={1,3},
	[1713]={1,3},
	[1714]={1,3},
	[1715]={1,3},
	[1716]={1,3},
	[1717]={2,2},
	[1718]={2,2},
	[1719]={2,2},
	[1720]={2,2},
	[1721]={2,2},
	[1722]={1,1},
	[1723]={1,1},
	[1724]={1,1},
	[1725]={1,1},
	[1726]={1,1},
	[1727]={1,1},
	[1728]={1,1},
	[1729]={1,1},
	[1730]={1,1},
	[1731]={1,1},
	[1732]={1,2},
	[1733]={1,3},
	[1734]={1,2},
	[1735]={1,2},
	[1736]={1,2},
	[1737]={1,5},
	[1738]={1,5},
	[1739]={1,5},
	[1740]={1,5},
	[1741]={1,5},
	[1742]={1,6},
	[1743]={1,6},
	[1744]={1,6},
	[1745]={1,6},
	[1746]={1,6},
	[1747]={1,5},
	[1748]={1,5},
	[1749]={1,5},
	[1750]={1,5},
	[1751]={1,5},
	[1752]={1,6},
	[1753]={1,6},
	[1754]={1,6},
	[1755]={1,6},
	[1756]={1,6},
	[1757]={1,5},
	[1758]={1,5},
	[1759]={1,5},
	[1760]={1,5},
	[1761]={1,5},
	[1762]={1,1},
	[1763]={1,1},
	[1764]={1,1},
	[1765]={1,2},
	[1766]={1,2},
	[1767]={1,2},
	[1768]={1,2},
	[1769]={1,2},
	[1770]={1,2},
	[1771]={1,2},
	[1772]={1,2},
	[1773]={1,2},
	[1774]={1,2},
	[1775]={1,2},
	[1776]={1,2},
	[1777]={1,2},
	[1778]={1,2},
	[1779]={1,2},
	[1780]={1,2},
	[1781]={1,2},
	[1782]={1,2},
	[1783]={1,2},
	[1784]={1,2},
	[1785]={1,2},
	[1786]={1,2},
	[1787]={1,2},
	[1788]={1,2},
	[1789]={1,2},
	[1790]={1,2},
	[1791]={1,2},
	[1792]={1,2},
	[1793]={1,2},
	[1794]={1,2},
	[1795]={1,2},
	[1796]={1,2},
	[1797]={1,2},
	[1798]={1,2},
	[1799]={2,1},
	[1800]={3,1},
	[1801]={3,2},
	[1802]={2,1},
	[1803]={2,1},
	[1804]={2,1},
	[1805]={2,1},
	[1806]={2,1},
	[1807]={2,1},
	[1808]={2,1},
	[1809]={2,1},
	[1810]={2,1},
	[1811]={2,1},
	[1812]={2,1},
	[1813]={2,1},
	[1814]={2,1},
	[1815]={2,1},
	[1816]={2,1},
	[1817]={2,1},
	[1818]={2,1},
	[1819]={2,1},
	[1820]={2,1},
	[1821]={2,1},
	[1822]={2,1},
	[1823]={2,1},
	[1824]={2,1},
	[1825]={2,1},
	[1826]={2,1},
	[1827]={2,1},
	[1828]={2,1},
	[1829]={2,1},
	[1830]={2,1},
	[1831]={2,1},
	[1832]={2,1},
	[1833]={2,1},
	[1834]={2,1},
	[1835]={2,1},
	[1836]={2,1},
	[1837]={2,1},
	[1838]={2,1},
	[1839]={2,1},
	[1840]={2,1},
	[1841]={2,1},
	[1842]={2,1},
	[1843]={2,1},
	[1844]={2,1},
	[1845]={2,1},
	[1846]={2,1},
	[1847]={2,1},
	[1848]={2,1},
	[1849]={2,1},
	[1850]={2,1},
	[1851]={2,1},
	[1852]={2,1},
	[1853]={2,1},
	[1854]={2,1},
	[1855]={2,1},
	[1856]={2,1},
	[1857]={2,1},
	[1858]={2,1},
	[1859]={2,1},
	[1860]={2,1},
	[1861]={2,1},
	[1862]={2,1},
	[1863]={2,1},
	[1864]={2,1},
	[1865]={2,1},
	[1866]={2,1},
	[1867]={2,1},
	[1868]={2,1},
	[1869]={2,1},
	[1870]={2,1},
	[1871]={2,1},
	[1872]={2,1},
	[1873]={2,1},
	[1874]={2,1},
	[1875]={2,1},
	[1876]={2,1},
	[1877]={2,1},
	[1878]={2,1},
	[1879]={2,1},
	[1880]={2,1},
	[1881]={2,1},
	[1882]={2,1},
	[1883]={2,1},
	[1884]={2,1},
	[1885]={2,1},
	[1886]={2,1},
	[1887]={2,1},
	[1888]={2,1},
	[1889]={2,1},
	[1890]={2,1},
	[1891]={2,1},
	[1892]={2,1},
	[1893]={2,1},
	[1894]={2,1},
	[1895]={2,1},
	[1896]={2,1},
	[1897]={2,1},
	[1898]={2,1},
	[1899]={2,1},
	[1900]={2,1},
	[1901]={2,2},
	[1902]={2,2},
	[1903]={2,2},
	[1904]={2,2},
	[1905]={2,2},
	[1906]={2,2},
	[1907]={2,2},
	[1908]={2,2},
	[1909]={2,2},
	[1910]={2,2},
	[1911]={2,2},
	[1912]={2,2},
	[1913]={2,2},
	[1914]={2,2},
	[1915]={2,2},
	[1916]={2,2},
	[1917]={2,2},
	[1918]={2,2},
	[1919]={2,2},
	[1920]={2,2},
	[1921]={2,2},
	[1922]={2,2},
	[1923]={2,2},
	[1924]={2,2},
	[1925]={2,2},
	[1926]={2,2},
	[1927]={2,2},
	[1928]={2,2},
	[1929]={2,2},
	[1930]={2,2},
	[1931]={2,2},
	[1932]={2,2},
	[1933]={2,2},
	[1934]={2,2},
	[1935]={2,2},
	[1936]={2,2},
	[1937]={2,2},
	[1938]={2,2},
	[1939]={2,2},
	[1940]={2,2},
	[1941]={2,2},
	[1942]={2,2},
	[1943]={2,2},
	[1944]={2,2},
	[1945]={2,2},
	[1946]={2,2},
	[1947]={2,2},
	[1948]={2,2},
	[1949]={2,2},
	[1950]={2,2},
	[1951]={2,2},
	[1952]={2,2},
	[1953]={2,2},
	[1954]={2,2},
	[1955]={2,2},
	[1956]={2,2},
	[1957]={2,2},
	[1958]={2,2},
	[1959]={2,2},
	[1960]={2,2},
	[1961]={2,2},
	[1962]={2,2},
	[1963]={2,2},
	[1964]={2,2},
	[1965]={2,2},
	[1966]={2,2},
	[1967]={2,2},
	[1968]={2,2},
	[1969]={2,2},
	[1970]={2,2},
	[1971]={2,2},
	[1972]={2,2},
	[1973]={2,2},
	[1974]={2,2},
	[1975]={2,2},
	[1976]={2,2},
	[1977]={2,2},
	[1978]={2,2},
	[1979]={2,2},
	[1980]={2,2},
	[1981]={2,2},
	[1982]={2,2},
	[1983]={2,2},
	[1984]={2,2},
	[1985]={2,2},
	[1986]={2,2},
	[1987]={2,2},
	[1988]={2,2},
	[1989]={2,2},
	[1990]={2,2},
	[1991]={2,2},
	[1992]={2,2},
	[1993]={2,2},
	[1994]={2,2},
	[1995]={2,2},
	[1996]={2,2},
	[1997]={2,2},
	[1998]={2,2},
	[1999]={2,2},
	[2000]={2,2},
	[2001]={2,2},
	[2002]={2,2},
	[2003]={2,2},
	[2004]={2,2},
	[2005]={2,2},
	[2006]={2,2},
	[2007]={2,2},
	[2008]={2,2},
	[2009]={2,2},
	[2010]={2,2},
	[2011]={2,2},
	[2012]={2,2},
	[2013]={2,2},
	[2014]={2,2},
	[2015]={2,2},
	[2016]={2,2},
	[2017]={2,2},
	[2018]={2,2},
	[2019]={2,2},
	[2020]={1,4},
	[2021]={1,4},
	[2022]={2,8},
	[2023]={1,6},
	[2024]={2,9},
	[2025]={2,7},
	[2026]={4,5},
	[2027]={4,6},
	[2028]={2,3},
	[2029]={1,1},
	[2030]={3,1},
	[2031]={2,2},
	[2032]={1,1},
	[2033]={1,1},
	[2034]={1,2},
	[2035]={1,6},
	[2036]={2,4},
	[2037]={2,9},
	[2038]={2,5},
	[2039]={1,7},
	[2040]={2,7},
	[2041]={4,5},
	[2042]={4,6},
	[2043]={3,3},
	[2044]={1,1},
	[2045]={3,1},
	[2046]={2,2},
	[2047]={1,1},
	[2048]={1,1},
	[2049]={1,2},
	[2050]={1,2},
	[2051]={1,2},
	[2052]={2,2},
	[2053]={1,3},
	[2054]={1,1},
	[2055]={2,1},
	[2056]={1,1},
	[2057]={1,1},
	[2058]={1,1},
	[2059]={1,1},
	[2060]={1,1},
	[2061]={1,1},
	[2062]={1,1},
	[2063]={1,1},
	[2064]={1,1},
	[2065]={1,1},
	[2066]={1,2},
	[2067]={2,1},
	[2068]={1,2},
	[2069]={2,2},
	[2070]={3,2},
	[2071]={2,2},
	[2072]={2,2},
	[2073]={2,2},
	[2074]={2,2},
	[2075]={1,1},
	[2076]={1,1},
	[2077]={1,1},
	[2078]={1,1},
	[2079]={1,1},
	[2080]={1,1},
	[2081]={1,2},
	[2082]={3,2},
	[2083]={1,1},
	[2084]={2,2},
	[2085]={1,2},
	[2086]={1,2},
	[2087]={1,3},
	[2088]={2,3},
	[2089]={2,2},
	[2090]={2,1},
	[2091]={1,2},
	[2092]={2,1},
	[2093]={3,2},
	[2094]={2,1},
	[2095]={1,2},
	[2096]={1,1},
	[2097]={1,1},
	[2098]={2,1},
	[2099]={2,2},
	[2100]={2,1},
	[2101]={1,1},
	[2102]={1,2},
	[2103]={2,1},
	[2104]={1,1},
	[2105]={2,1},
	[2106]={2,2},
	[2107]={1,1},
	[2108]={1,1},
	[2109]={1,1},
	[2110]={1,2},
	[2111]={1,1},
	[2112]={1,1},
	[2113]={2,2},
	[2114]={2,2},
	[2115]={2,2},
	[2116]={2,2},
	[2117]={2,2},
	[2118]={1,4},
	[2119]={3,4},
	[2120]={2,1},
	[2121]={2,1},
	[2122]={2,1},
	[2123]={2,1},
	[2124]={2,1},
	[2125]={2,1},
	[2126]={2,1},
	[2127]={2,1},
	[2128]={2,1},
	[2129]={2,1},
	[2130]={2,1},
	[2131]={2,1},
	[2132]={2,1},
	[2133]={2,1},
	[2134]={2,1},
	[2135]={2,1},
	[2136]={2,1},
	[2137]={2,1},
	[2138]={2,1},
	[2139]={2,1},
	[2140]={2,1},
	[2141]={2,1},
	[2142]={2,1},
	[2143]={2,1},
	[2144]={2,1},
	[2145]={2,1},
	[2146]={2,1},
	[2147]={2,1},
	[2148]={2,1},
	[2149]={2,1},
	[2150]={2,1},
	[2151]={2,1},
	[2152]={2,1},
	[2153]={2,1},
	[2154]={2,1},
	[2155]={2,1},
	[2156]={2,1},
	[2157]={2,1},
	[2158]={2,1},
	[2159]={2,1},
	[2160]={2,1},
	[2161]={2,1},
	[2162]={2,1},
	[2163]={2,1},
	[2164]={2,1},
	[2165]={2,1},
	[2166]={2,1},
	[2167]={2,1},
	[2168]={2,1},
	[2169]={2,1},
	[2170]={2,2},
	[2171]={2,2},
	[2172]={2,2},
	[2173]={2,2},
	[2174]={1,2},
	[2175]={1,1},
	[2176]={1,1},
	[2177]={1,1},
	[2178]={1,2},
	[2179]={1,1},
	[2180]={1,1},
	[2181]={1,1},
	[2182]={1,1},
	[2183]={1,1},
	[2184]={1,2},
	[2185]={1,1},
	[2186]={1,1},
	[2187]={1,1},
	[2188]={1,1},
	[2189]={1,1},
	[2190]={1,2},
	[2191]={1,1},
	[2192]={1,1},
	[2193]={1,1},
	[2194]={1,1},
	[2195]={1,1},
	[2196]={1,2},
	[2197]={1,1},
	[2198]={1,1},
	[2199]={1,2},
	[2200]={2,1},
}
