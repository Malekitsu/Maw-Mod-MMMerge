local count = 10

function events.KeyDown(t)
	if t.Key==16 then
		shiftPressed=true
	end
    if ((Game.CurrentScreen == 7 or Game.CurrentScreen==15) and Game.CurrentCharScreen == 103) or Game.CurrentScreen==13 then
		local id=Game.CurrentPlayer
		if (id>=0 and id <=Party.High) then
			local pl = Party[Game.CurrentPlayer]
			if Party.High==0 and shiftPressed then
				if t.Key>=49 and t.Key<=48+5 then
					changeBag(pl , (t.Key-48)+5)
				end
			elseif Party.High==0 or shiftPressed then
				if t.Key>=49 and t.Key<=48+5 then
					changeBag(pl , t.Key-48)
				end
			end
		end
	end
end
function events.KeyUp(t)
	if t.Key==16 then
		shiftPressed=false
	end
end
function events.GameInitialized2()
	multibagButton={}
	for i=1,count do
		if i<=5 then
			multibagButton[i]=CustomUI.CreateButton{
			IconUp = "SlChar" .. i .. "U",
			IconDown = "SlChar" .. i .. "D",
			Screen = {7, 13, 15},
			Layer = 1,
			X =	455+i*30,
			Y =	372,
			Masked = true,
			Action = function() changeBag(Party[Game.CurrentPlayer], i) end,
			}
		else
			multibagButton[i]=CustomUI.CreateButton{
			IconUp = "SlChar" .. i-5 .. "U",
			IconDown = "SlChar" .. i-5 .. "D",
			Screen = {7, 13, 15},
			Layer = 1,
			X =	455+(i-5)*30,
			Y =	445,
			Masked = true,
			Action = function() changeBag(Party[Game.CurrentPlayer], i) end,
			}

		end
	end
	arcomageButtonFix=false
end

function events.Action(t)
	if t.Action==29 and not arcomageButtonFix then
		for i=1,count do
			multibagButton[i].Y=multibagButton[i].Y+1000
		end
		arcomageButtonFix=true
		function events.Tick()
			if Game.HouseScreen~=104 then
				events.Remove("Tick", 1)
				for i=1,count do
					multibagButton[i].Y=372
					if i>5 then
						multibagButton[i].Y=445
					end
					arcomageButtonFix=false
				end
			end
		end
	end
	--keep the button pushed effect
	function events.Tick()
		events.Remove("Tick", 1)
		if Game.CurrentPlayer>=0 and Game.CurrentPlayer<=Party.High then
			local pl=Party[Game.CurrentPlayer]
			local id=pl:GetIndex()
			vars.mawbags=vars.mawbags or {}
			if not vars.mawbags[id] then
				currentBag=1
			else
				currentBag=vars.mawbags[id].CurrentBag%5
				if currentBag==0 then
					currentBag=5
				end				
			end
			for i=1,5 do
				if i==currentBag then
					multibagButton[i].IUpSrc="SlChar" .. i .. "D"
				else
					multibagButton[i].IUpSrc="SlChar" .. i .. "U"
				end
			end
			--tab
			local currentTab=math.ceil(vars.mawbags[id]["CurrentBag"]/5)
			for i=1,5 do
				if i==currentTab then
					multibagButton[i+5].IUpSrc="SlChar" .. i .. "D"
				else
					multibagButton[i+5].IUpSrc="SlChar" .. i .. "U"
				end
				if Party.High>0 then
					multibagButton[i+5].Active=false
				else
					multibagButton[i+5].Active=true
				end
			end
		end
	end	
end


--multiple inventory code
function changeBag(pl, bag)
	local id=pl:GetIndex()
	vars.mawbags=vars.mawbags or {}
	if not vars.mawbags[id] then
		vars.mawbags[id]={}
		vars.mawbags[id]["CurrentBag"]=1
	end
	local currentTab=math.ceil(vars.mawbags[id]["CurrentBag"]/5)
	local currentBag=vars.mawbags[id]["CurrentBag"]%5
	if currentBag==0 then
		currentBag=5
	end
	--bags
	if bag<=5 then
		for i=1,5 do
			if i==bag then
				multibagButton[i].IUpSrc="SlChar" .. i .. "D"
			else
				multibagButton[i].IUpSrc="SlChar" .. i .. "U"
			end
		end
	end
	if bag>5 then
		bag=currentBag+(bag-6)*5
	else
		bag=bag+(currentTab-1)*5
	end
	--tab
	local newCurrentTab=math.ceil(bag/5)
	for i=1,5 do
		if i==newCurrentTab then
			multibagButton[i+5].IUpSrc="SlChar" .. i .. "D"
		else
			multibagButton[i+5].IUpSrc="SlChar" .. i .. "U"
		end
	end
	--store current bag
	local itemList={}
	local removeList={}
	local j=0
	for i=0,125 do
		if pl.Inventory[i]>0 then
			if pl.Items[pl.Inventory[i]].BodyLocation==0 then
				removeList[-i-1]=true
			end
			local it=pl.Items[pl.Inventory[i]]
			itemList[i+1000]=pl.Inventory[i]
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
				itemList[j]["Location"]=i
				itemList[j]["oldLocation"]=pl.Inventory[i]
				itemList[j]["size"]=itemSizeMap[it.Number][2]
				if itemList[j]["size"]==1 and itemSizeMap[it.Number][1] >1 then
					itemList[j]["size"]=1.5
				end
				pl.Inventory[i]=0 
				it.Number=0
			end
		end
	end
	local currentBag=vars.mawbags[id]["CurrentBag"]
	vars.mawbags[id][currentBag]=itemList
	vars.mawbags[id].CurrentBag=bag
	--remove also from inventory
	for i=0,125 do
		if removeList[pl.Inventory[i]] then
			pl.Inventory[i]=0
		end
	end
	for i=1,138 do
		if pl.Items[i].BodyLocation==0 and pl.Items[i].Broken==false then
			local it=pl.Items[i]
			it.Bonus = 0	
			it.Bonus2 = 0
			it.BonusExpireTime = 0
			it.BonusStrength = 0
			it.Broken = false
			it.Charges = false
			it.Condition = 0
			it.Hardened = false
			it.Identified = true
			it.MaxCharges = 0
			it.Number = 0
			it.Owner = 0
			it.Refundable = false
			it.Stolen = false
			it.TemporaryBonus = false
		end                                     
	end
	if not vars.mawbags[id][bag] then 
		return
	else
		local bags=vars.mawbags[id][bag]
		local j=0
		for i=1,#bags do
			local it=bags[i]
			local inv
			while j<=138 and pl.Items[i+j].Number>0 do
				j=j+1
			end
			if it and it.Location then
				pl.Inventory[it.Location]=i+j
				local inv=pl.Items[i+j]
				inv["Bonus"]=it.Bonus
				inv["Bonus2"]=it.Bonus2
				inv["BonusExpireTime"]=it.BonusExpireTime
				inv["BonusStrength"]=it.BonusStrength
				inv["Broken"]=it.Broken
				inv["Charges"]=it.Charges
				inv["Condition"]=it.Condition 
				inv["Hardened"]=it.Hardened
				inv["Identified"]=it.Identified
				inv["MaxCharges"]=it.MaxCharges
				inv["Number"]=it.Number
				inv["Owner"]=it.Owner
				inv["Refundable"]=it.Refundable
				inv["Stolen"]=it.Stolen
				inv["TemporaryBonus"]=it.TemporaryBonus
			else
				debug.Message("One of the " .. pl.Name .. "'s item from the bag " .. bag .. " might have been corrupted, contact Malekith on discord (or in bug report in discord) and copy paste this message and the following ones.\nKeep in mind that corrupted item might have been just some 'random' unexpected value with no actual consequences, so if you don't notice anything missing, you can continue playing normally.\n\nItem data:\n" .. dump(it))
			end
		end
		--remove empty spaces
		for i=0,125 do
			if pl.Inventory[i]>0 then
				 it=pl.Items[pl.Inventory[i]]
				 if it.Number>0 then
					local id=-i-1
					local x, y=itemSizeMap[it.Number][1], itemSizeMap[it.Number][2]
					local inv=pl.Inventory
					local currentPosition=i-1
					for j=1, x do
						currentPosition=currentPosition+1
						if currentPosition<126 and pl.Inventory[currentPosition]<=0 then
							pl.Inventory[currentPosition]=id
						end
						 yPos=currentPosition
						for k=1,y-1 do
							yPos=yPos+14
							if yPos<126 and pl.Inventory[yPos]<=0 then
								pl.Inventory[yPos]=id
							end
						end
					end
				end
			end
		end	
	end
end

--remove buttons when tooltip is on the bottom right
function events.BuildItemInformationBox(t)
	for i=1,5 do
		multibagButton[i].Active=false
		function events.Tick()
			events.Remove("Tick", 1)
			multibagButton[i].Active=true
		end
	end
end

--sortMultiBag(Party[0])
--debug.Message(dump(tempBag))




function sortMultiBag(pl)
	local id=pl:GetIndex()
	local lastBag=false
	if vars.mawbags and vars.mawbags[id] and vars.mawbags[id]["CurrentBag"] then
		lastBag=vars.mawbags[id]["CurrentBag"]
	end
	for i=1,5 do
		changeBag(pl, i)
	end
	changeBag(pl, 1)
	vars.mawbags=vars.mawbags or {}
	if not vars.mawbags[id] then
		vars.mawbags[id]={}
		vars.mawbags[id]["CurrentBag"]=1
	end
	--put all items into a temporary bag
	tempBag={}
	for bag,item in pairs(vars.mawbags[id]) do
		if type(bag)=="number" and type(item)=="table" then
			for i=1, #item do
				if type(item)=="table" then
					table.insert(tempBag, item[i])
				end
			end
		end
	end
	--sort items
	table.sort(tempBag, function(a, b)
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
		if vars.alchemyPlayer and vars.alchemyPlayer>=0 then
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
	--remove all items
	vars.mawbags[id]={}
	vars.mawbags[id]["CurrentBag"]=1
	for i=0,125 do
		pl.Inventory[i]=0
	end
	--place items
	local currentItem={1,1,1,1,1}
	for i=1, #tempBag do
		local it=tempBag[i]
		local placeFound=false
		local x, y=itemSizeMap[it.Number][1], itemSizeMap[it.Number][2]
		local currentBag=1
		if vars.mawbags[id]["CurrentBag"]~=1 then
			changeBag(pl, 1)
		end
		while not placeFound do
			for j=0,125 do
				asddd=asddd or 0
				asddd=asddd+1
				j=j*14%126+math.floor(j/9)
				--pick the correct inventory slot
				local inv=pl.Inventory
				if inv[j]==0 then
					local currentPosition=j-1
					local currentLine=math.ceil((j+1)/14)
					for n=1, x do
						currentPosition=currentPosition+1
						if currentLine~=math.ceil((currentPosition+1)/14) then
							goto continue
						end
						if currentPosition>=126 and inv[currentPosition]~=0 then
							goto continue
						end
						local yPos=currentPosition
						for k=1,y-1 do
							yPos=yPos+14
							if yPos>=126 or inv[yPos]~=0 then
								goto continue
							end
						end
					end
					while not placeFound do
						if currentItem[currentBag]<=138 and pl.Items[currentItem[currentBag]].BodyLocation==0 then
							placeItem(pl,it,j,currentItem[currentBag],x,y)
							currentItem[currentBag]=currentItem[currentBag]+1
							placeFound=true
						else 
							currentItem[currentBag]=currentItem[currentBag]+1
							if currentItem[currentBag]>138 then
								goto continue
							end
						end
					end
					goto nextItem
				end
				:: continue ::				
			end	
			--no inventory slots, go to next bag
			changeBag(pl, currentBag+1)
			currentBag=currentBag+1
		end
		:: nextItem ::
		placeFound=true
	end
	if lastBag then
		changeBag(pl, lastBag)
	end
end

function placeItem(pl,it,invSlot,itemId,x, y)
	local occupiedCode=-itemId-1
	for n=1, x do
		if n==1 then
			pl.Inventory[invSlot]=itemId
		else
			pl.Inventory[invSlot]=occupiedCode
		end
		yPos=invSlot
		invSlot=invSlot+1
		for k=1,y-1 do
			yPos=yPos+14
			pl.Inventory[yPos]=occupiedCode
		end
	end
	local inv=pl.Items[itemId]
	inv["Bonus"]=it.Bonus
	inv["Bonus2"]=it.Bonus2
	inv["BonusExpireTime"]=it.BonusExpireTime
	inv["BonusStrength"]=it.BonusStrength
	inv["Broken"]=it.Broken
	inv["Charges"]=it.Charges
	inv["Condition"]=it.Condition 
	inv["Hardened"]=it.Hardened
	inv["Identified"]=it.Identified
	inv["MaxCharges"]=it.MaxCharges
	inv["Number"]=it.Number
	inv["Owner"]=it.Owner
	inv["Refundable"]=it.Refundable
	inv["Stolen"]=it.Stolen
	inv["TemporaryBonus"]=it.TemporaryBonus
end

function events.Action(t)
	if t.Action==113 or t.Action==123 then
		if vars.SmallerPotionBottles then
			for i=220, 299 do
				itemSizeMap[i][2]=1
			end	
		else
			for i=220, 299 do
				itemSizeMap[i][2]=2
			end	
		end
	end
end
