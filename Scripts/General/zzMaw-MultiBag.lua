local count = 5

function events.KeyDown(t)

    if ((Game.CurrentScreen == 7 or Game.CurrentScreen==15) and Game.CurrentCharScreen == 103) or Game.CurrentScreen==13 then
		pl = Party[Game.CurrentPlayer]
		if Party.High==0 then
			if t.Key>=49 and t.Key<=48+count then
				changeBag(pl , t.Key-48)
			end
		end		
	end
end

function events.GameInitialized2()
	multibagButton={}
	for i=1,count do
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
					arcomageButtonFix=false
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
	if not vars.mawbags[id][bag] then 
		return
	else
		local bags=vars.mawbags[id][bag]
		local j=0
		for i=1,#bags do
			local it=bags[i]
			local inv
			while pl.Items[i+j].Number>0 do
				j=j+1
			end
			
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
		end
		--remove empty spaces
		for i=0,125 do
			if pl.Inventory[i]>0 then
				 it=pl.Items[pl.Inventory[i]]
				 if it.Number>0 then
					 id=-i-1
					 x, y=itemSizeMap[it.Number][1], itemSizeMap[it.Number][2]
					 inv=pl.Inventory
					 currentPosition=i-1
					for j=1, x do
						currentPosition=currentPosition+1
						if pl.Inventory[currentPosition]<=0 then
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
