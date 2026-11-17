local count = 10

-- The Adventurer's Inn shows a character's screen without leaving its own
-- screen (const.Screens.AdventurersInn), so the checks for screens 7/13/15
-- missed its backpack. Returns the roster player whose backpack the inn
-- shows, party member or not: the inn dialog has 1 at +0xC while a
-- character's screen is open (29 in the list; CurrentCharScreen keeps its
-- last value there) and the character's roster index at +0x128.
local function innBagPlayer()
	if Game.CurrentScreen ~= 29 or Game.CurrentCharScreen ~= 103 then
		return
	end
	local dlg = mem.u4[0x100614C]
	if dlg == 0 or mem.i4[dlg + 0xC] ~= 1 then
		return
	end
	local index = mem.i4[dlg + 0x128]
	if index >= 0 and index < Party.PlayersArray.count then
		return Party.PlayersArray[index]
	end
end

-- The player whose bags the buttons and keys act on.
local function bagOwner()
	return innBagPlayer() or Party[Game.CurrentPlayer]
end

-- changeBag hands an item on the mouse to the current party member, so
-- a character outside the party may switch bags only with an empty mouse.
local function switchBag(pl, bag)
	if Mouse.Item.Number ~= 0 and pl:GetIndex() ~= Party.PlayersIndexes[Game.CurrentPlayer] then
		Game.ShowStatusText("Put the item down before switching this character's bag")
		return
	end
	changeBag(pl, bag)
end

function events.KeyDown(t)
	if t.Key==16 then
		shiftPressed=true
	end
    local innPl = innBagPlayer()
    if ((Game.CurrentScreen == 7 or Game.CurrentScreen==15) and Game.CurrentCharScreen == 103) or Game.CurrentScreen==13 or innPl then
		local id=Game.CurrentPlayer
		if innPl or (id>=0 and id <=Party.High) then
			local pl = innPl or Party[Game.CurrentPlayer]
			if Party.High==0 and shiftPressed then
				if t.Key>=49 and t.Key<=48+5 then
					switchBag(pl , (t.Key-48)*100)
				end
			elseif Party.High==0 or shiftPressed then
				if t.Key>=49 and t.Key<=48+5 then
					if Party.High==0 and t.Key==49 and Mouse.Item.Number~=0 then
						return
					else
						switchBag(pl , t.Key-48)
					end
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
			Screen = {7, 13, 15, 29},
			Condition = function() return Game.CurrentScreen ~= 29 or innBagPlayer() ~= nil end,
			Layer = 1,
			X =	455+i*30,
			Y =	372,
			Masked = true,
			Action = function() switchBag(bagOwner(), i) end,
			}
		else
			multibagButton[i]=CustomUI.CreateButton{
			IconUp = "SlChar" .. i-5 .. "U",
			IconDown = "SlChar" .. i-5 .. "D",
			Screen = {7, 13, 15, 29},
			Condition = function() return Game.CurrentScreen ~= 29 or innBagPlayer() ~= nil end,
			Layer = 1,
			X =	455+(i-5)*30,
			Y =	445,
			Masked = true,
			Action = function() switchBag(bagOwner(), (i-5)*100) end,
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
end

--keep the button pushed effect
function mawTick_MultibagButtons()
	if Game.CurrentScreen ~= 7 then
		for i=6,10 do
			multibagButton[i].Active=false
		end
	end
	local innPl = innBagPlayer()
	if innPl or (Game.CurrentScreen == 7 or Game.CurrentScreen==13) and Game.CurrentPlayer>=0 and Game.CurrentPlayer<=Party.High then
		local pl=innPl or Party[Game.CurrentPlayer]
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
		local currentTab=1
		if vars and vars.mawbags and vars.mawbags[id] then
			currentTab=math.ceil(vars.mawbags[id]["CurrentBag"]/100)
		end
		for i=1,5 do
			if i==currentTab then
				multibagButton[i+5].IUpSrc="SlChar" .. i .. "D"
			else
				multibagButton[i+5].IUpSrc="SlChar" .. i .. "U"
			end
			if Party.High==0 and Game.CurrentScreen==7 then
				multibagButton[i+5].Active=true
			else
				multibagButton[i+5].Active=false
			end
		end
	end
end	


--multiple inventory code
local function ensureBags(pl)
	local id=pl:GetIndex()
	vars.mawbags=vars.mawbags or {}
	if not vars.mawbags[id] then
		vars.mawbags[id]={}
		vars.mawbags[id]["CurrentBag"]=1
	end
	return id
end

local function equippedRecords(pl)
	local equipped={}
	for s=0,15 do
		if pl.EquippedItems[s]>0 then
			equipped[pl.EquippedItems[s]]=true
		end
	end
	return equipped
end

function dropItemAtParty(it)
	local obj=SummonItem(it.Number, Party.X, Party.Y, Party.Z + 128, 0)
	if not obj then
		return false
	end
	local drop=obj.Item
	drop.Bonus=it.Bonus
	drop.Bonus2=it.Bonus2
	drop.BonusExpireTime=it.BonusExpireTime
	drop.BonusStrength=it.BonusStrength
	drop.Broken=it.Broken
	drop.Charges=it.Charges
	drop.Condition=it.Condition
	drop.Hardened=it.Hardened
	drop.Identified=it.Identified
	drop.MaxCharges=it.MaxCharges
	drop.Owner=it.Owner
	drop.Refundable=it.Refundable
	drop.Stolen=it.Stolen
	drop.TemporaryBonus=it.TemporaryBonus
	return true
end

function storeBag(pl)
	local id=ensureBags(pl)
	local equipped=equippedRecords(pl)
	--store current bag
	local itemList={}
	local removeList={}
	local j=0
	for i=0,125 do
		if pl.Inventory[i]>0 then
			if not equipped[pl.Inventory[i]] then
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
	--remove also from inventory
	for i=0,125 do
		if removeList[pl.Inventory[i]] then
			pl.Inventory[i]=0
		end
	end
	for i=1,138 do
		if not equipped[i] then
			local it=pl.Items[i]
			it.Bonus = 0	
			it.Bonus2 = 0
			it.BonusExpireTime = 0
			it.BonusStrength = 0
			it.Broken = false
			it.Charges = 0
			it.Condition = 0
			it.Hardened = false
			it.Identified = true
			it.MaxCharges = 0
			it.Number = 0
			it.Owner = 0
			it.Refundable = false
			it.Stolen = false
			it.TemporaryBonus = false
			it.BodyLocation = 0
		end                                     
	end
end

function loadBag(pl, bag)
	local id=ensureBags(pl)
	vars.mawbags[id].CurrentBag=bag
	local equipped=equippedRecords(pl)
	if not vars.mawbags[id][bag] then 
		return false
	else
		local bags=vars.mawbags[id][bag]
		local j=0
		if isnan(bags) then
			bags={}
			debug.Message(pl.Name .. "'s bag number " .. bag .. " is corrupted. Bag has been resetted, otherwise game will crash. If you have a previous save you might want to load hope the bag is not broken there.")
		end
		for i=1,#bags do
			local it=bags[i]
			local inv
			while i+j<=138 and (pl.Items[i+j].Number>0 or equipped[i+j]) do
				j=j+1
			end
			if i+j>138 then
				local spare
				for tab=0,(Party.High==0 and 4 or 0) do
					for slot=1,5 do
						local b=slot+tab*100
						local stored=vars.mawbags[id][b]
						if not spare and b~=bag and (stored==nil or type(stored)=="table" and #stored==0) then
							spare=b
						end
					end
				end
				if spare then
					local moved={}
					for k=i,#bags do
						if bags[k] and bags[k].Location then
							moved[#moved+1]=bags[k]
						end
					end
					for k=#bags,i,-1 do
						bags[k]=nil
					end
					vars.mawbags[id][spare]=moved
					Game.ShowStatusText(string.format("%s: bag %d is over the item limit, %d items moved to bag %d", pl.Name, bag, #moved, spare))
					break
				end
				local dropped=0
				for k=i,#bags do
					local lost=bags[k]
					if lost and lost.Location and dropItemAtParty(lost) then
						dropped=dropped+1
					end
				end
				Game.ShowStatusText(string.format("%s: not enough item slots for bag %d, %d items dropped on the ground", pl.Name, bag, dropped))
				break
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
	return true
end

function changeBag(pl, bag)
	local id=ensureBags(pl)
	local currentTab=math.floor(vars.mawbags[id]["CurrentBag"]/100)+1
	local currentBag=vars.mawbags[id]["CurrentBag"]%100

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
	if bag>=100 then
		bag=currentBag+bag-100
	else
		bag=bag+(currentTab-1)*100
	end
	--tab
	newCurrentTab=math.ceil(bag/100)
	for i=1,5 do
		if i==newCurrentTab then
			multibagButton[i+5].IUpSrc="SlChar" .. i .. "D"
		else
			multibagButton[i+5].IUpSrc="SlChar" .. i .. "U"
		end
	end
	storeBag(pl)
	if not loadBag(pl, bag) then
		return
	end
	--store mouse item
	local mouseItem = {}
	local it = Mouse.Item
	if it.Number==0 then return end
	mouseItem = {} 
	mouseItem["Bonus"]=it.Bonus
	mouseItem["Bonus2"]=it.Bonus2
	mouseItem["BonusExpireTime"]=it.BonusExpireTime
	mouseItem["BonusStrength"]=it.BonusStrength
	mouseItem["Broken"]=it.Broken
	mouseItem["Charges"]=it.Charges
	mouseItem["Condition"]=it.Condition 
	mouseItem["Hardened"]=it.Hardened
	mouseItem["Identified"]=it.Identified
	mouseItem["MaxCharges"]=it.MaxCharges
	mouseItem["Number"]=it.Number
	mouseItem["Refundable"]=it.Refundable
	mouseItem["Stolen"]=it.Stolen
	mouseItem["TemporaryBonus"]=it.TemporaryBonus
	
	Mouse.Item.Number=0
	evt.Add("Items", 0)

	DoGameAction(110,Game.CurrentPlayer+1,0)
	
	RunNextTick(function()
		Mouse.Item.Bonus = mouseItem.Bonus
		Mouse.Item.Bonus2 = mouseItem.Bonus2
		Mouse.Item.BonusExpireTime = mouseItem.BonusExpireTime
		Mouse.Item.BonusStrength = mouseItem.BonusStrength
		Mouse.Item.Broken = mouseItem.Broken
		Mouse.Item.Charges = mouseItem.Charges
		Mouse.Item.Condition = mouseItem.Condition 
		Mouse.Item.Hardened = mouseItem.Hardened
		Mouse.Item.Identified = mouseItem.Identified
		Mouse.Item.MaxCharges = mouseItem.MaxCharges
		Mouse.Item.Number = mouseItem.Number
		Mouse.Item.Refundable = mouseItem.Refundable
		Mouse.Item.Stolen = mouseItem.Stolen
		Mouse.Item.TemporaryBonus = mouseItem.TemporaryBonus
	end)
end

--remove buttons when tooltip is on the bottom right

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

function isnan(x)
    return x ~= x
end

--Tick handlers above run as MawCore scheduler tasks (ms; 0=frame, -1=poke only)
function events.GameInitialized2()
	local every=MawCore.Scheduler.every
	every("multibag/buttons", 100, mawTick_MultibagButtons)
end
