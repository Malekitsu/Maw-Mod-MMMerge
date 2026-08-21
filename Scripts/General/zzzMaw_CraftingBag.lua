function isCraftingMaterial(number)
	if number >= 1041 and number <= 1069 then
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

local function flaggedBagsList(plId)
	local list = {}
	for bagNum in pairs(craftingFlags(plId)) do
		table.insert(list, bagNum)
	end
	table.sort(list)
	return list
end

function ToggleCraftingBag()
	local id = Game.CurrentPlayer
	if id < 0 or id > Party.High then return end
	local pl = Party[id]
	local plId = pl:GetIndex()
	vars.mawbags = vars.mawbags or {}
	local bagData = vars.mawbags[plId]
	local currentBag = (bagData and bagData.CurrentBag) or 1

	local flags = craftingFlags(plId)
	if flags[currentBag] then
		flags[currentBag] = nil
		Game.ShowStatusText(pl.Name .. "'s bag is no longer a crafting bag")
	else
		flags[currentBag] = true
		Game.ShowStatusText(pl.Name .. "'s bag is now a crafting bag")
	end
end

function events.KeyDown(t)
	if Game.CurrentScreen == 7 and Game.CurrentCharScreen == 103 then
		if t.Key == 66 and Keys.IsPressed(const.Keys.SHIFT) then -- Shift+B
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
		local currentTab = 1
		if vars.mawbags[id] and vars.mawbags[id].CurrentBag then
			currentTab = math.ceil(vars.mawbags[id].CurrentBag / 100)
		end
		for i = 1, 5 do
			local rawBag = i + (currentTab - 1) * 100
			craftingBagMarker[i].Text = (flags[rawBag] == true) and "C" or ""
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
	for j = 0, 125 do
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

local function tryPlaceInStoredBag(plId, bagNum, itemRecord)
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

	if craftingFlags(plId)[vars.mawbags[plId].CurrentBag] then
		return -- active bag is itself flagged; normal pickup is already correct
	end

	local owners = {pl}
	for i = 0, Party.High do
		if i ~= id then
			owners[#owners + 1] = Party[i]
		end
	end

	local itemRecord = captureItemRecord(mapObj.Item)
	for _, owner in ipairs(owners) do
		local ownerId = owner:GetIndex()
		local activeBag = (vars.mawbags[ownerId] and vars.mawbags[ownerId].CurrentBag) or 1
		for _, bagNum in ipairs(flaggedBagsList(ownerId)) do
			if bagNum ~= activeBag then
				local okPlace, placed = pcall(tryPlaceInStoredBag, ownerId, bagNum, itemRecord)
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
	end
end



