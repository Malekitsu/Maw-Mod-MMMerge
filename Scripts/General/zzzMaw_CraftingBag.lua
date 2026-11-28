function isCraftingMaterial(number)
	if number >= 1041 and number <= 1070 then
		return true
	end
	return false
end


local function craftingFlags(plId)
	vars.CraftingBags = vars.CraftingBags or {}
	for _, flags in pairs(vars.CraftingBags) do
		if type(flags) ~= "table" then
			vars.CraftingBags = {}
			break
		end
	end
	vars.CraftingBags[plId] = vars.CraftingBags[plId] or {}
	return vars.CraftingBags[plId]
end

local function alchemyFlags(plId)
	vars.AlchemyBags = vars.AlchemyBags or {}
	vars.AlchemyBags[plId] = vars.AlchemyBags[plId] or {}
	return vars.AlchemyBags[plId]
end

function ReservedBagFlags(plId)
	return craftingFlags(plId), alchemyFlags(plId)
end

local function flaggedBagsList(plId)
	local list = {}
	for bagNum in pairs(craftingFlags(plId)) do
		table.insert(list, bagNum)
	end
	table.sort(list)
	return list
end

local function tabBase(pl)
	local bags = vars.mawbags and vars.mawbags[pl:GetIndex()]
	return math.floor((((bags and bags.CurrentBag) or 1) - 1) / 100) * 100
end

local function toggleTab(pl, flags, name)
	local base = tabBase(pl)
	local assigned = true
	for bag = base + 1, base + 5 do
		assigned = assigned and flags[bag] == true
	end
	for bag in pairs(flags) do
		flags[bag] = nil
	end
	local tab = base / 100 + 1
	if assigned then
		Game.ShowStatusText(string.format("Tab %d is no longer the %s tab", tab, name))
		return
	end
	for bag = base + 1, base + 5 do
		flags[bag] = true
	end
	Game.ShowStatusText(string.format("Tab %d is now the %s tab", tab, name))
end

local function togglePlayer(key, name)
	vars[key] = vars[key] or -1
	if vars[key] == Game.CurrentPlayer then
		vars[key] = -1
		Game.ShowStatusText("No " .. name .. " preference when sorting")
	else
		vars[key] = Game.CurrentPlayer
		Game.ShowStatusText(Party[Game.CurrentPlayer].Name .. " will now take " .. name .. " items when sorting")
	end
end

local function toggleContainer(key, flagsOf, name)
	local id = Game.CurrentPlayer
	if id < 0 or id > Party.High then return end
	if Party.High == 0 then
		local pl = Party[id]
		toggleTab(pl, flagsOf(pl:GetIndex()), name)
	else
		togglePlayer(key, name)
	end
end

function ToggleAlchemyBag()
	toggleContainer("alchemyPlayer", alchemyFlags, "alchemy")
end

function ToggleCraftingBag()
	toggleContainer("craftingPlayer", craftingFlags, "crafting")
end

function events.KeyDown(t)
	if Game.CurrentScreen == 7 and Game.CurrentCharScreen == 103 then
		if t.Key == 66 then -- B
			ToggleCraftingBag()
		end
	end
end

local craftingBagMarker

function mawTick_CraftingBagMarker()
	if not craftingBagMarker then return end
	if (Game.CurrentScreen == 7 or Game.CurrentScreen == 13) and Game.CurrentPlayer >= 0 and Game.CurrentPlayer <= Party.High then
		local pl = Party[Game.CurrentPlayer]
		local id = pl:GetIndex()
		vars.mawbags = vars.mawbags or {}
		local flags = craftingFlags(id)
		local alchemy = alchemyFlags(id)
		local currentTab = 1
		if vars.mawbags[id] and vars.mawbags[id].CurrentBag then
			currentTab = math.ceil(vars.mawbags[id].CurrentBag / 100)
		end
		local solo = Party.High == 0
		local crafter = vars.craftingPlayer == Game.CurrentPlayer
		local alchemist = vars.alchemyPlayer == Game.CurrentPlayer
		for i = 1, 5 do
			local rawBag = i + (currentTab - 1) * 100
			local c = solo and flags[rawBag] == true or not solo and crafter
			local a = solo and alchemy[rawBag] == true or not solo and alchemist
			craftingBagMarker[i].Text = (c and "C" or "") .. (a and "A" or "")
		end
	else
		for i = 1, 5 do
			craftingBagMarker[i].Text = ""
		end
	end
end

function events.GameInitialized2()
	craftingBagMarker = {}
	for i = 1, 5 do
		craftingBagMarker[i] = CustomUI.CreateText{
			Text = "",
			Font = Game.Smallnum_fnt,
			X = 455 + i * 30 + 12,
			Y = 372 + 16,
			ColorStd = RGB(255, 210, 0),
			Screen = 7,
		}
	end
	MawCore.Scheduler.every("craftingbag/marker", 100, mawTick_CraftingBagMarker)
end

local function findFreeSlot(isOccupied, x, y)
	for k = 0, 125 do
		local j = (k % 9) * 14 + math.floor(k / 9)
		if not isOccupied(j) then
			local currentLine = math.ceil((j + 1) / 14)
			local fits = true
			local currentPosition = j - 1
			for n = 1, x do
				currentPosition = currentPosition + 1
				if currentLine ~= math.ceil((currentPosition + 1) / 14) then
					fits = false
					break
				end
				if currentPosition >= 126 or isOccupied(currentPosition) then
					fits = false
					break
				end
				local yPos = currentPosition
				for k = 1, y - 1 do
					yPos = yPos + 14
					if yPos >= 126 or isOccupied(yPos) then
						fits = false
						break
					end
				end
				if not fits then break end
			end
			if fits then
				return j
			end
		end
	end
	return nil
end

local function tryPlaceInStoredBag(owner, bagNum, itemRecord)
	local plId = owner:GetIndex()
	vars.mawbags = vars.mawbags or {}
	vars.mawbags[plId] = vars.mawbags[plId] or { CurrentBag = 1 }
	local bagList = vars.mawbags[plId][bagNum]
	if not bagList then
		bagList = {}
		vars.mawbags[plId][bagNum] = bagList
	end

	local count = 0
	while bagList[count + 1] do
		count = count + 1
	end
	local cap = MawCore.Engine.backpackItemCap
	if cap and count >= cap(owner) then
		return false
	end

	local occupied = {}
	for i = 1, count do
		local existing = bagList[i]
		if type(existing) == "table" and existing.Location and itemSizeMap[existing.Number] then
			local ex, ey = itemSizeMap[existing.Number][1], itemSizeMap[existing.Number][2]
			for n = 0, ex - 1 do
				for k = 0, ey - 1 do
					occupied[existing.Location + n + k * 14] = true
				end
			end
		end
	end

	local x, y = itemSizeMap[itemRecord.Number][1], itemSizeMap[itemRecord.Number][2]
	local slot = findFreeSlot(function(cell) return occupied[cell] end, x, y)
	if not slot then
		return false
	end

	itemRecord.Location = slot
	bagList[count + 1] = itemRecord
	return true
end

local function captureItemRecord(it, number)
	number = number or it.Number
	local w, h = itemSizeMap[number][1], itemSizeMap[number][2]
	local size = h
	if size == 1 and w > 1 then
		size = 1.5
	end
	return {
		Bonus = it.Bonus,
		Bonus2 = it.Bonus2,
		BonusExpireTime = it.BonusExpireTime,
		BonusStrength = it.BonusStrength,
		Broken = it.Broken,
		Charges = it.Charges,
		Condition = it.Condition,
		Hardened = it.Hardened,
		Identified = it.Identified,
		MaxCharges = it.MaxCharges,
		Number = number,
		Owner = it.Owner,
		Refundable = it.Refundable,
		Stolen = it.Stolen,
		TemporaryBonus = it.TemporaryBonus,
		size = size,
	}
end

local function craftingContainer()
	if Party.High == 0 then
		local pl = Party[0]
		return pl, flaggedBagsList(pl:GetIndex())
	end
	local slot = vars.craftingPlayer or -1
	if slot < 0 or slot > Party.High then
		return
	end
	local pl = Party[slot]
	local base = tabBase(pl)
	return pl, {base + 1, base + 2, base + 3, base + 4, base + 5}
end

function events.PickObject(t)
	if t.Handled then return end

	local ok, mapObj = pcall(function() return Map.Objects[t.ObjectId] end)
	if not ok or not mapObj or not mapObj.Item then return end

	local itemNumber = mapObj.Item.Number
	if not isCraftingMaterial(itemNumber) then return end
	if not itemSizeMap[itemNumber] then return end

	local id = Game.CurrentPlayer
	if id < 0 or id > Party.High then return end
	local pl = Party[id]
	local plId = pl:GetIndex()

	vars.mawbags = vars.mawbags or {}
	vars.mawbags[plId] = vars.mawbags[plId] or { CurrentBag = 1 }

	local owner, bags = craftingContainer()
	if not owner then return end
	local ownerId = owner:GetIndex()
	local activeBag = (vars.mawbags[ownerId] and vars.mawbags[ownerId].CurrentBag) or 1

	local itemRecord = captureItemRecord(mapObj.Item)
	for _, bagNum in ipairs(bags) do
		local okPlace, placed
		if bagNum == activeBag then
			okPlace, placed = pcall(MawCore.Engine.putInBackpack, owner, itemRecord)
		else
			okPlace, placed = pcall(tryPlaceInStoredBag, owner, bagNum, itemRecord)
		end
		if okPlace and placed then
			mapObj.Type = 0
			mapObj.TypeIndex = 0
			mapObj.Item.Number = 0
			t.Handled = true

			local txt = Game.ItemsTxt[itemNumber]
			local displayName = (itemRecord.Identified and txt.Name) or txt.NotIdentifiedName or txt.Name or "Item"
			local who = ""
			if ownerId ~= plId then
				who = " -- " .. owner.Name
			end
			Game.ShowStatusText("You found an item (" .. displayName .. ")!" .. who)
			Game.PlaySound(133)
			return
		elseif not okPlace then
			print("[CRAFTBAG] pickup error: " .. tostring(placed))
		end
	end
end



