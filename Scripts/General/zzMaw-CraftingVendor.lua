-- =================================================================================================
-- zzMaw-CraftingVendor.lua
--
-- Adds a specialized Crafting Item Vendor that sells ALL Crafting Items (1041..1070)
-- with UNLIMITED STOCK at authentic shop prices affected by Party Merchant skill.
--
-- Features:
--   1. Complete Catalog of All 30 Crafting Items:
--      - Tab 1: Standard Gems (Tiers 1 to 10: Lunar Shard -> Queen's Diamond)
--      - Tab 2: Ascended Gems (Tiers 1 to 10: Ascended Lunar Shard -> Ascended Queen's Diamond)
--      - Tab 3: Special Relics & Cubes (Eye of Void, Creator's Hourglass, Pandora's Cube,
--               Archibald's Mirror, Emerald of Power, Pearl of Memory, Orb of Creation,
--               Celestial Orb, Endless Potion, Crafting Cube)
--   2. Authentic Shop Pricing & Merchant Scaling:
--      - Base values read from MAW's live reagentPrices / BASE_PRICES / ItemsTxt.
--      - Applies standard shop markup (2.0) and discounts via Party Merchant skill
--        matching the MM8 engine buy formula (0x4b66d1) and MAW's GetMerchantTotalSkill.
--      - At effective Merchant >= 50 (or Grandmaster), items are bought at exact base cost!
--   3. Safe Unlimited Stock & Bulk Buying:
--      - Pre-validates free inventory space across the party BEFORE deducting gold.
--      - Supports [Buy 1] and [Buy 5] buttons per item without dropping items on the ground.
--      - Items are automatically identified, and Endless Potion (1069) rolls proper
--        charge power from the party's highest Alchemy skill rank.
--   4. Rock-Solid Stability & Procedural UI:
--      - 100% native CustomUI Direct3D rendering pipeline with a procedurally generated
--        640x480 in-memory LodBitmap backdrop (no external assets required).
--      - Masked icon rendering with automatic fitting for oversized Tab 3 relic icons.
--      - Clean shop state transitions without invalidating house pointers.
--   5. Access:
--      - Inside any Alchemy Shop (House Type 4, main shop menu on Screen 13),
--        click "[Crafting Items]" in the shop menu to open the vendor directly.
--      - Keyboard shortcuts inside vendor: Keys 1, 2, 3 switch tabs; Esc or Space closes.
-- =================================================================================================

local VendorScreenId = nil
local currentTab = 1
local previousScreen = 0

-- -------------------------------------------------------------------------------------------------
-- Base Values for All Crafting Items (matching zzMaw-Items.lua reagentPrices)
-- -------------------------------------------------------------------------------------------------
local BASE_PRICES = {
	[1041] = 1000,     -- Lunar Shard
	[1042] = 2000,     -- Fire Topaz
	[1043] = 4000,     -- Amethyst Chunk
	[1044] = 7000,     -- Amber Droplet
	[1045] = 12000,    -- Royal Amethyst
	[1046] = 20000,    -- Gemcutter's Ruby
	[1047] = 30000,    -- Solarstone
	[1048] = 40000,    -- Erudite Crystal
	[1049] = 50000,    -- Erathian Sapphire
	[1050] = 60000,    -- Queen's Diamond
	[1051] = 80000,    -- Ascended Lunar Shard
	[1052] = 100000,   -- Ascended Fire Topaz
	[1053] = 120000,   -- Ascended Amethyst Chunk
	[1054] = 140000,   -- Ascended Amber Droplet
	[1055] = 160000,   -- Ascended Royal Amethyst
	[1056] = 180000,   -- Ascended Gemcutter's Ruby
	[1057] = 200000,   -- Ascended Solarstone
	[1058] = 230000,   -- Ascended Erudite Crystal
	[1059] = 260000,   -- Ascended Erathian Sapphire
	[1060] = 300000,   -- Ascended Queen's Diamond
	[1061] = 1250000,  -- Eye of Void
	[1062] = 750000,   -- Creator's Hourglass
	[1063] = 325000,   -- Pandora's Cube
	[1064] = 6668999,  -- Archibald's Mirror
	[1065] = 2000000,  -- Emerald of Power
	[1066] = 1000000,  -- Pearl of Memory
	[1067] = 3000000,  -- Orb of Creation
	[1068] = 200000,   -- Celestial Orb
	[1069] = 100000,   -- Endless Potion
	[1070] = 250000,   -- Crafting Cube
}

-- Fallback inventory grid sizes (matching zzMaw-Item-Sorter.lua itemSizeMap)
local ITEM_SIZES = {
	[1041] = { 1, 1 },
	[1042] = { 1, 1 },
	[1043] = { 1, 1 },
	[1044] = { 1, 1 },
	[1045] = { 1, 1 },
	[1046] = { 1, 1 },
	[1047] = { 1, 1 },
	[1048] = { 1, 1 },
	[1049] = { 1, 1 },
	[1050] = { 1, 1 },
	[1051] = { 1, 1 },
	[1052] = { 1, 1 },
	[1053] = { 1, 1 },
	[1054] = { 1, 1 },
	[1055] = { 1, 1 },
	[1056] = { 1, 1 },
	[1057] = { 1, 1 },
	[1058] = { 1, 1 },
	[1059] = { 1, 1 },
	[1060] = { 1, 1 },
	[1061] = { 2, 2 },
	[1062] = { 1, 2 },
	[1063] = { 1, 1 },
	[1064] = { 2, 2 },
	[1065] = { 1, 2 },
	[1066] = { 1, 1 },
	[1067] = { 2, 2 },
	[1068] = { 2, 3 },
	[1069] = { 1, 2 },
	[1070] = { 2, 2 },
}

-- Item catalog definitions categorized into 3 tabs of 10 items each
local CATALOG = {
	-- Tab 1: Standard Gems
	[1] = {
		{ id = 1041, icon = "vCraft1",  name = "Lunar Shard",       desc = "Tier 1 Crafting Gem" },
		{ id = 1042, icon = "vCraft2",  name = "Fire Topaz",        desc = "Tier 2 Crafting Gem" },
		{ id = 1043, icon = "vCraft3",  name = "Amethyst Chunk",    desc = "Tier 3 Crafting Gem" },
		{ id = 1044, icon = "vCraft4",  name = "Amber Droplet",     desc = "Tier 4 Crafting Gem" },
		{ id = 1045, icon = "vCraft5",  name = "Royal Amethyst",    desc = "Tier 5 Crafting Gem" },
		{ id = 1046, icon = "vCraft6",  name = "Gemcutter's Ruby",  desc = "Tier 6 Crafting Gem" },
		{ id = 1047, icon = "vCraft7",  name = "Solarstone",        desc = "Tier 7 Crafting Gem" },
		{ id = 1048, icon = "vCraft8",  name = "Erudite Crystal",   desc = "Tier 8 Crafting Gem" },
		{ id = 1049, icon = "vCraft9",  name = "Erathian Sapphire", desc = "Tier 9 Crafting Gem" },
		{ id = 1050, icon = "vCraft10", name = "Queen's Diamond",   desc = "Tier 10 Crafting Gem (Max)" },
	},
	-- Tab 2: Ascended Gems
	[2] = {
		{ id = 1051, icon = "vCraft1Asc",  name = "Ascended Lunar Shard",       desc = "Tier 1 Ascended Gem" },
		{ id = 1052, icon = "vCraft2Asc",  name = "Ascended Fire Topaz",        desc = "Tier 2 Ascended Gem" },
		{ id = 1053, icon = "vCraft3Asc",  name = "Ascended Amethyst Chunk",    desc = "Tier 3 Ascended Gem" },
		{ id = 1054, icon = "vCraft4Asc",  name = "Ascended Amber Droplet",     desc = "Tier 4 Ascended Gem" },
		{ id = 1055, icon = "vCraft5Asc",  name = "Ascended Royal Amethyst",    desc = "Tier 5 Ascended Gem" },
		{ id = 1056, icon = "vCraft6Asc",  name = "Ascended Gemcutter's Ruby",  desc = "Tier 6 Ascended Gem" },
		{ id = 1057, icon = "vCraft7Asc",  name = "Ascended Solarstone",        desc = "Tier 7 Ascended Gem" },
		{ id = 1058, icon = "vCraft8Asc",  name = "Ascended Erudite Crystal",   desc = "Tier 8 Ascended Gem" },
		{ id = 1059, icon = "vCraft9Asc",  name = "Ascended Erathian Sapphire", desc = "Tier 9 Ascended Gem" },
		{ id = 1060, icon = "vCraft10Asc", name = "Ascended Queen's Diamond",   desc = "Tier 10 Ascended (Supreme)" },
	},
	-- Tab 3: Special Relics & Cubes
	[3] = {
		{ id = 1061, icon = "vEye1",     name = "Eye of Void",         desc = "Adds special enchantment" },
		{ id = 1062, icon = "vHour1",    name = "Creator's Hourglass", desc = "Adds 2nd base enchantment" },
		{ id = 1063, icon = "vCraft11",  name = "Pandora's Cube",      desc = "Refines weapon/armor stats" },
		{ id = 1064, icon = "vMirror",   name = "Archibald's Mirror",  desc = "Creates a copy of equipment" },
		{ id = 1065, icon = "vCraft12",  name = "Emerald of Power",    desc = "Increases item tier (+1)" },
		{ id = 1066, icon = "vCraft13",  name = "Pearl of Memory",     desc = "Erases 1 random enchantment" },
		{ id = 1067, icon = "vEternal2", name = "Orb of Creation",     desc = "Transfers Legendary Affix" },
		{ id = 1068, icon = "vEternal1", name = "Celestial Orb",       desc = "Transfers Celestial essence" },
		{ id = 1069, icon = "item280",   name = "Endless Potion",      desc = "Adds charges to buff potions" },
		{ id = 1070, icon = "cube",      name = "Crafting Cube",       desc = "Increases item bonus power" },
	},
}

-- -------------------------------------------------------------------------------------------------
-- Helpers: Color, Math & Formatting
-- -------------------------------------------------------------------------------------------------
local function colorRGB(r, g, b)
	if type(RGB) == "function" then
		return RGB(r, g, b)
	end
	return math.floor(r / 8) * 2048 + math.floor(g / 4) * 32 + math.floor(b / 8)
end

-- Initialized during buildVendorUI() once display bit-depth is ready
local COL_GOLD = 0xFFE0
local COL_WHITE = 0xFFFF
local COL_GREY = 0xCE79
local COL_CYAN = 0x07FF
local COL_GREEN = 0x07E0
local COL_RED = 0xF800
local COL_SHOP_BTN = 0xFBE0

local function initColors()
	COL_GOLD = colorRGB(255, 224, 64)
	COL_WHITE = colorRGB(255, 255, 255)
	COL_GREY = colorRGB(196, 200, 208)
	COL_CYAN = colorRGB(96, 232, 255)
	COL_GREEN = colorRGB(96, 240, 128)
	COL_RED = colorRGB(255, 112, 104)
	COL_SHOP_BTN = colorRGB(255, 224, 96)
end

local function formatGold(n)
	local val = math.max(0, math.floor(tonumber(n) or 0))
	local s = tostring(val)
	local pos = string.len(s) % 3
	if pos == 0 then pos = 3 end
	return string.sub(s, 1, pos) .. string.gsub(string.sub(s, pos + 1), "(%d%d%d)", ",%1")
end

-- -------------------------------------------------------------------------------------------------
-- Helper: Calculate Shop Price with Merchant Skill
-- Matches MM8 engine buy calculation (0x4b66d1) and MAW's GetMerchantTotalSkill
-- -------------------------------------------------------------------------------------------------
local function getPartyMerchantSkill()
	if not Party or Party.High < 0 then
		return 0
	end
	local cur = Game.CurrentPlayer
	local idx = (cur and cur >= 0 and cur <= Party.High) and cur or 0
	local pl = Party[idx]
	if pl and pl.GetMerchantTotalSkill then
		local ok, res = pcall(function() return pl:GetMerchantTotalSkill() end)
		if ok and type(res) == "number" then
			return math.max(0, res)
		end
	end
	local t = {
		Player = pl,
		PlayerIndex = idx,
		Result = 0
	}
	events.call("GetMerchantTotalSkill", t)
	return math.max(0, t.Result or 0)
end

local function getShopPrice(itemId)
	local baseVal = (reagentPrices and reagentPrices[itemId])
		or BASE_PRICES[itemId]
		or (Game.ItemsTxt and Game.ItemsTxt[itemId] and Game.ItemsTxt[itemId].Value)
		or 1000
	local mSkill = getPartyMerchantSkill()

	if mSkill >= 100 then
		return baseVal
	end

	-- Standard shop markup for alchemist shops is 2.0
	local markup = 2.0
	local markedUp = math.floor(baseVal * markup)
	local discounted = math.floor(markedUp * (100 - mSkill) / 100)
	return math.max(baseVal, discounted)
end

-- -------------------------------------------------------------------------------------------------
-- Helper: Alchemy Shop Entry Condition & Shop Menu Guard
-- -------------------------------------------------------------------------------------------------
local SHOP_BTN_X = 475
local SHOP_BTN_Y = 310
local SHOP_BTN_W = 150
local SHOP_BTN_H = 25

local function isInAlchemyShopMainMenu()
	if Game.CurrentScreen ~= 13 then
		return false
	end
	local hs = Game.HouseScreen
	if hs ~= 0 and hs ~= 1 then
		return false
	end
	local houseId = (GetCurrentHouse and GetCurrentHouse()) or (Game.GetCurrentHouse and Game.GetCurrentHouse())
	if houseId and houseId >= 1 and Game.Houses and houseId <= Game.Houses.High and Game.Houses[houseId] then
		local alchemistType = (const.HouseType and const.HouseType.Alchemist) or 4
		return Game.Houses[houseId].Type == alchemistType
	end
	return false
end

-- -------------------------------------------------------------------------------------------------
-- UI Elements References & Updates
-- -------------------------------------------------------------------------------------------------
local goldWidget = nil
local merchantWidget = nil
local statusWidget = nil
local tabWidgets = {}
local priceWidgets = {}

local function updateUIHeader()
	if goldWidget then
		goldWidget.Text = "Party Gold: " .. formatGold(Party and Party.Gold or 0)
	end
	if merchantWidget then
		local mSkill = getPartyMerchantSkill()
		local effMult = (mSkill >= 100) and 1.0 or math.max(1.0, 2.0 * (100 - mSkill) / 100)
		if effMult <= 1.0001 then
			merchantWidget.Text = "Merchant: Max Discount (Base Cost)"
		else
			merchantWidget.Text = string.format("Merchant Skill: %d (Shop Markup: %.2fx)", mSkill, effMult)
		end
	end
end

local function updateAllItemPrices()
	for itemId, widget in pairs(priceWidgets) do
		if widget then
			widget.Text = "Cost: " .. formatGold(getShopPrice(itemId)) .. " Gold"
		end
	end
end

local function setTab(tabIdx, silent)
	currentTab = tabIdx
	for i = 1, 3 do
		if tabWidgets[i] then
			if i == currentTab then
				tabWidgets[i].Text = (i == 1 and "[ * 1. Standard Gems * ]")
					or (i == 2 and "[ * 2. Ascended Gems * ]")
					or "[ * 3. Special Relics * ]"
				tabWidgets[i].CStd = COL_GOLD
			else
				tabWidgets[i].Text = (i == 1 and "[ 1. Standard Gems ]")
					or (i == 2 and "[ 2. Ascended Gems ]")
					or "[ 3. Special Relics ]"
				tabWidgets[i].CStd = COL_GREY
			end
		end
	end
	if not silent and Game.PlaySound then
		Game.PlaySound(24)
	end
	Game.NeedRedraw = true
end

-- -------------------------------------------------------------------------------------------------
-- Inventory Placement & Purchase Execution
-- -------------------------------------------------------------------------------------------------
local function getItemGridSize(itemId)
	local sz = (itemSizeMap and itemSizeMap[itemId]) or ITEM_SIZES[itemId]
	if sz then
		return sz[1] or 1, sz[2] or 1
	end
	return 1, 1
end

local function clearItemStruct(it)
	it.Bonus = 0
	it.Bonus2 = 0
	it.BonusExpireTime = 0
	it.BonusStrength = 0
	it.Broken = false
	it.Charges = 0
	it.Condition = 0
	it.Hardened = false
	it.Identified = false
	it.MaxCharges = 0
	it.Number = 0
	it.Owner = 0
	it.Refundable = false
	it.Stolen = false
	it.TemporaryBonus = false
	it.BodyLocation = 0
end

local function getPartyMaxAlchemyRank()
	if not Party or Party.High < 0 then
		return 0
	end
	local maxRank = 0
	for p = 0, Party.High do
		local pl = Party[p]
		if pl and pl.GetSkill and const and const.Skills and const.Skills.Alchemy then
			local rank = SplitSkill(pl:GetSkill(const.Skills.Alchemy))
			if rank > maxRank then
				maxRank = rank
			end
		end
	end
	return maxRank
end

local function planInventoryPlacements(itemId, count)
	if not Party or Party.High < 0 then
		return nil, false
	end

	local w, h = getItemGridSize(itemId)
	local playerOrder = {}
	local cur = Game.CurrentPlayer
	local primaryIdx = (cur and cur >= 0 and cur <= Party.High) and cur or 0
	playerOrder[1] = primaryIdx
	for p = 0, Party.High do
		if p ~= primaryIdx then
			playerOrder[#playerOrder + 1] = p
		end
	end

	local placements = {}
	local overflowedToOther = false

	for _, pIdx in ipairs(playerOrder) do
		local pl = Party[pIdx]
		if pl and pl.Inventory and pl.Items then
			local simGrid = {}
			local usedItemIdx = {}

			if pl.EquippedItems then
				for s = 0, 15 do
					local eq = pl.EquippedItems[s]
					if eq and eq > 0 then
						usedItemIdx[eq] = true
					end
				end
			end

			for cell = 0, 125 do
				local v = pl.Inventory[cell]
				simGrid[cell] = v
				if v > 0 then
					usedItemIdx[v] = true
				end
			end

			for idx = 1, pl.Items.High do
				if pl.Items[idx].Number ~= 0 or pl.Items[idx].BodyLocation ~= 0 then
					usedItemIdx[idx] = true
				end
			end

			local nextFreeIdx = 1
			local function allocItemIdx()
				while nextFreeIdx <= pl.Items.High do
					local idx = nextFreeIdx
					nextFreeIdx = nextFreeIdx + 1
					if not usedItemIdx[idx] then
						usedItemIdx[idx] = true
						return idx
					end
				end
				return nil
			end

			local placedHere = true
			while #placements < count and placedHere do
				placedHere = false
				local foundSlot = nil
				for col = 0, 14 - w do
					for row = 0, 9 - h do
						local fits = true
						for dy = 0, h - 1 do
							for dx = 0, w - 1 do
								if simGrid[(row + dy) * 14 + (col + dx)] ~= 0 then
									fits = false
									break
								end
							end
							if not fits then
								break
							end
						end
						if fits then
							foundSlot = row * 14 + col
							break
						end
					end
					if foundSlot then
						break
					end
				end

				if foundSlot then
					local itemIdx = allocItemIdx()
					if itemIdx then
						local topCol = foundSlot % 14
						local topRow = math.floor(foundSlot / 14)
						for dy = 0, h - 1 do
							for dx = 0, w - 1 do
								local c = (topRow + dy) * 14 + (topCol + dx)
								if dx == 0 and dy == 0 then
									simGrid[c] = itemIdx
								else
									simGrid[c] = -foundSlot - 1
								end
							end
						end
						placements[#placements + 1] = {
							plIdx = pIdx,
							itemIdx = itemIdx,
							slot = foundSlot,
							w = w,
							h = h,
						}
						if pIdx ~= primaryIdx then
							overflowedToOther = true
						end
						placedHere = true
					end
				end
			end

			if #placements >= count then
				return placements, overflowedToOther
			end
		end
	end

	return nil, false
end

local function buyCraftingItem(itemId, count)
	count = count or 1
	local unitPrice = getShopPrice(itemId)
	local totalPrice = unitPrice * count
	local itemName = (Game.ItemsTxt and Game.ItemsTxt[itemId] and Game.ItemsTxt[itemId].Name) or ("Item " .. itemId)

	if Party.Gold < totalPrice then
		if Game.PlaySound then
			Game.PlaySound(23) -- Error buzz
		end
		if statusWidget then
			statusWidget.Text = string.format("Not enough gold! Need %s Gold.", formatGold(totalPrice))
		end
		Game.NeedRedraw = true
		return
	end

	-- Validate space across party bags before deducting any gold
	local placements, overflowedToOther = planInventoryPlacements(itemId, count)
	if not placements then
		if Game.PlaySound then
			Game.PlaySound(23)
		end
		if statusWidget then
			statusWidget.Text = string.format("Not enough inventory space for %dx %s!", count, itemName)
		end
		Game.NeedRedraw = true
		return
	end

	local endlessPower = (itemId == 1069) and math.min(getPartyMaxAlchemyRank() + 10, 100) or 0

	-- Deduct Gold and place identified items directly into reserved inventory slots
	Party.Gold = Party.Gold - totalPrice

	for _, p in ipairs(placements) do
		local pl = Party[p.plIdx]
		local it = pl.Items[p.itemIdx]
		clearItemStruct(it)
		it.Number = itemId
		it.Identified = true
		if itemId == 1069 then
			it.BonusStrength = endlessPower
		end

		local topCol = p.slot % 14
		local topRow = math.floor(p.slot / 14)
		for dy = 0, p.h - 1 do
			for dx = 0, p.w - 1 do
				local c = (topRow + dy) * 14 + (topCol + dx)
				if dx == 0 and dy == 0 then
					pl.Inventory[c] = p.itemIdx
				else
					pl.Inventory[c] = -p.slot - 1
				end
			end
		end
	end

	if Game.PlaySound then
		Game.PlaySound(25) -- Cash register purchase sound
	end

	if statusWidget then
		local suffix = overflowedToOther and " (placed in party bags)" or ""
		statusWidget.Text = string.format("Bought %dx %s for %s Gold!%s", count, itemName, formatGold(totalPrice), suffix)
	end
	updateUIHeader()
	Game.NeedRedraw = true
end

-- -------------------------------------------------------------------------------------------------
-- Open & Close Vendor Screen
-- -------------------------------------------------------------------------------------------------
function OpenCraftingVendor()
	if not VendorScreenId then
		return
	end
	if Game.CurrentScreen ~= VendorScreenId then
		previousScreen = Game.CurrentScreen or 0
	end

	setTab(currentTab or 1, true)
	updateUIHeader()
	updateAllItemPrices()
	if statusWidget then
		statusWidget.Text = "Welcome! Click [Buy 1] or [Buy 5] to purchase. Stock is unlimited."
	end

	Game.CurrentScreen = VendorScreenId
	if Game.PlaySound then
		Game.PlaySound(24)
	end
	Game.NeedRedraw = true
end

function CloseCraftingVendor()
	if Game.CurrentScreen ~= VendorScreenId then
		return
	end
	local houseId = (GetCurrentHouse and GetCurrentHouse()) or (Game.GetCurrentHouse and Game.GetCurrentHouse())
	if previousScreen == 13 and houseId and houseId > 0 then
		Game.CurrentScreen = 13 -- Safely return to active shop without crashing
	else
		Game.CurrentScreen = 0  -- Return to game
	end
	if Game.PlaySound then
		Game.PlaySound(24)
	end
	Game.NeedRedraw = true
end

-- -------------------------------------------------------------------------------------------------
-- Procedural 640x480 In-Memory Background Bitmap & Icon Fitting
-- -------------------------------------------------------------------------------------------------
local ROW_Y = { 74, 146, 218, 290, 362 }
local COL_X = { 8, 324 }

local function fillBgRect(buf, x, y, w, h, colorIdx)
	local x0 = math.max(0, x)
	local y0 = math.max(0, y)
	local x1 = math.min(640, x + w)
	local y1 = math.min(480, y + h)
	local rw = x1 - x0
	if rw <= 0 or y1 <= y0 then
		return
	end
	for py = y0, y1 - 1 do
		mem.fill(buf + py * 640 + x0, rw, colorIdx)
	end
end

local function drawBgBorder(buf, x, y, w, h, colorIdx)
	if w <= 0 or h <= 0 then
		return
	end
	fillBgRect(buf, x, y, w, 1, colorIdx)
	fillBgRect(buf, x, y + h - 1, w, 1, colorIdx)
	fillBgRect(buf, x, y, 1, h, colorIdx)
	fillBgRect(buf, x + w - 1, y, 1, h, colorIdx)
end

local function createVendorBackground()
	local pxCount = 640 * 480
	local bgStruct = mem.StaticAlloc(0x48)
	local bgPixels = mem.StaticAlloc(pxCount)
	local bgPal16 = mem.StaticAlloc(256 * 2)
	local bgPal24 = mem.StaticAlloc(256 * 3)

	local ok, basePtr = pcall(CustomUI.LoadIcon, "SlBackgr")
	if ok and type(basePtr) == "number" and basePtr ~= 0 then
		mem.copy(bgStruct, basePtr, 0x48)
	else
		mem.fill(bgStruct, 0x48, 0)
	end

	mem.fill(bgStruct, 16, 0)
	mem.copy(bgStruct, "MawCV_BG")
	mem.u1[bgStruct + 0x0E] = 0 -- Opaque draw (0x4a3cd5)
	mem.i4[bgStruct + 0x10] = pxCount
	mem.i4[bgStruct + 0x14] = pxCount
	mem.i2[bgStruct + 0x18] = 640
	mem.i2[bgStruct + 0x1A] = 480
	mem.i2[bgStruct + 0x1C] = 0
	mem.i2[bgStruct + 0x1E] = 0
	mem.i2[bgStruct + 0x20] = 639
	mem.i2[bgStruct + 0x22] = 479
	mem.i2[bgStruct + 0x24] = 0
	mem.i2[bgStruct + 0x26] = 0
	mem.i4[bgStruct + 0x28] = pxCount
	mem.u4[bgStruct + 0x2C] = 0
	mem.i4[bgStruct + 0x30] = bgPixels
	mem.i4[bgStruct + 0x34] = 0
	mem.i4[bgStruct + 0x38] = 0
	mem.i4[bgStruct + 0x3C] = 0
	mem.i4[bgStruct + 0x40] = bgPal16
	mem.i4[bgStruct + 0x44] = bgPal24

	local palette = {
		[0]  = { 26, 28, 36 },   -- Fallback base dark slate
		[1]  = { 26, 28, 36 },   -- Main canvas background
		[2]  = { 20, 22, 29 },   -- Header and footer bar fill
		[3]  = { 32, 35, 45 },   -- Navigation tab strip
		[4]  = { 34, 37, 47 },   -- Item card fill (odd rows)
		[5]  = { 39, 42, 54 },   -- Item card fill (even rows)
		[6]  = { 22, 24, 31 },   -- Sunken icon well fill
		[7]  = { 66, 70, 86 },   -- Card and icon-well inner borders
		[8]  = { 136, 108, 62 }, -- Antique bronze outer border and main dividers
		[9]  = { 90, 72, 44 },   -- Muted bronze inner trim and tab separators
		[10] = { 48, 52, 66 },   -- Subtle top card highlight
		[11] = { 26, 44, 34 },   -- Dark emerald [Buy] button plate
		[12] = { 56, 98, 72 },   -- Emerald [Buy] button border
		[13] = { 54, 26, 28 },   -- Dark crimson [CLOSE] button plate
		[14] = { 124, 58, 60 },  -- Crimson [CLOSE] button border
	}

	mem.fill(bgPal16, 256 * 2, 0)
	mem.fill(bgPal24, 256 * 3, 0)
	for idx, c in pairs(palette) do
		mem.u2[bgPal16 + idx * 2] = colorRGB(c[1], c[2], c[3])
		local p24 = bgPal24 + idx * 3
		mem.u1[p24] = c[1]
		mem.u1[p24 + 1] = c[2]
		mem.u1[p24 + 2] = c[3]
	end

	-- 1. Main background canvas
	mem.fill(bgPixels, pxCount, 1)

	-- 2. Header & Tab strip
	fillBgRect(bgPixels, 4, 4, 632, 42, 2)
	fillBgRect(bgPixels, 4, 46, 632, 1, 8)
	fillBgRect(bgPixels, 4, 47, 632, 23, 3)
	fillBgRect(bgPixels, 216, 49, 1, 19, 9)
	fillBgRect(bgPixels, 423, 49, 1, 19, 9)
	fillBgRect(bgPixels, 4, 70, 632, 1, 8)

	-- 3. 10 Item cards (2 columns x 5 rows)
	for rIdx = 1, 5 do
		local by = ROW_Y[rIdx]
		local cardFill = (rIdx % 2 == 1) and 4 or 5
		for cIdx = 1, 2 do
			local bx = COL_X[cIdx]
			-- Card base & border
			fillBgRect(bgPixels, bx, by, 308, 68, cardFill)
			drawBgBorder(bgPixels, bx, by, 308, 68, 7)
			fillBgRect(bgPixels, bx + 1, by + 1, 306, 1, 10)

			-- Sunken icon well (46x62)
			fillBgRect(bgPixels, bx + 3, by + 3, 46, 62, 6)
			drawBgBorder(bgPixels, bx + 3, by + 3, 46, 62, 7)

			-- [Buy 1] and [Buy 5] button plates
			fillBgRect(bgPixels, bx + 248, by + 11, 56, 19, 11)
			drawBgBorder(bgPixels, bx + 248, by + 11, 56, 19, 12)

			fillBgRect(bgPixels, bx + 248, by + 36, 56, 19, 11)
			drawBgBorder(bgPixels, bx + 248, by + 36, 56, 19, 12)
		end
	end

	-- 4. Footer bar & Close button plate
	fillBgRect(bgPixels, 4, 433, 632, 1, 8)
	fillBgRect(bgPixels, 4, 434, 632, 42, 2)
	fillBgRect(bgPixels, 513, 442, 114, 24, 13)
	drawBgBorder(bgPixels, 513, 442, 114, 24, 14)

	-- 5. Outer 2px antique bronze frame, inner trim, and subtle corner accents
	fillBgRect(bgPixels, 0, 0, 640, 2, 8)
	fillBgRect(bgPixels, 0, 478, 640, 2, 8)
	fillBgRect(bgPixels, 0, 0, 2, 480, 8)
	fillBgRect(bgPixels, 638, 0, 2, 480, 8)
	drawBgBorder(bgPixels, 3, 3, 634, 474, 9)

	for _, corner in ipairs({
		{ 4, 4 }, { 630, 4 }, { 4, 470 }, { 630, 470 }
	}) do
		fillBgRect(bgPixels, corner[1], corner[2], 6, 6, 9)
		drawBgBorder(bgPixels, corner[1], corner[2], 6, 6, 8)
	end

	return bgStruct
end

local function createVendorItemIcon(iconName, itemId, bx, by, tabIndex)
	local WELL_X = bx + 3
	local WELL_Y = by + 3
	local WELL_W = 46
	local WELL_H = 62
	local MAX_W = 42
	local MAX_H = 58

	local ok, srcPtr = pcall(CustomUI.LoadIcon, iconName, true)
	if ok and type(srcPtr) == "number" and srcPtr ~= 0 and string.lower(mem.string(srcPtr)) ~= "pending" then
		local srcW = mem.u2[srcPtr + 0x18]
		local srcH = mem.u2[srcPtr + 0x1A]

		if srcW > 0 and srcH > 0 then
			if srcW > MAX_W or srcH > MAX_H then
				local srcPixels = mem.u4[srcPtr + 0x30]
				local srcPal16 = mem.u4[srcPtr + 0x40]
				local srcPal24 = mem.u4[srcPtr + 0x44]

				if srcPixels ~= 0 and srcPal16 ~= 0 then
					local scale = math.min(MAX_W / srcW, MAX_H / srcH)
					local dstW = math.max(1, math.floor(srcW * scale + 0.5))
					local dstH = math.max(1, math.floor(srcH * scale + 0.5))
					local dstCount = dstW * dstH

					local dstStruct = mem.StaticAlloc(0x48)
					local dstPixels = mem.StaticAlloc(dstCount)
					local dstPal16 = mem.StaticAlloc(256 * 2)
					local dstPal24 = (srcPal24 ~= 0) and mem.StaticAlloc(256 * 3) or 0

					local uName = "MawCV_I" .. tostring(itemId)
					mem.copy(dstStruct, srcPtr, 0x48)
					mem.fill(dstStruct, 16, 0)
					mem.copy(dstStruct, uName)
					mem.u1[dstStruct + 0x0E] = 1 -- Transparent mask draw (0x4a419b)
					mem.i4[dstStruct + 0x10] = dstCount
					mem.i4[dstStruct + 0x14] = dstCount
					mem.i2[dstStruct + 0x18] = dstW
					mem.i2[dstStruct + 0x1A] = dstH
					mem.i2[dstStruct + 0x1C] = 0
					mem.i2[dstStruct + 0x1E] = 0
					mem.i2[dstStruct + 0x20] = dstW - 1
					mem.i2[dstStruct + 0x22] = dstH - 1
					mem.i4[dstStruct + 0x28] = dstCount
					mem.u4[dstStruct + 0x30] = dstPixels
					mem.u4[dstStruct + 0x34] = 0
					mem.u4[dstStruct + 0x38] = 0
					mem.u4[dstStruct + 0x3C] = 0
					mem.u4[dstStruct + 0x40] = dstPal16
					mem.u4[dstStruct + 0x44] = dstPal24

					mem.copy(dstPal16, srcPal16, 256 * 2)
					if dstPal24 ~= 0 then
						mem.copy(dstPal24, srcPal24, 256 * 3)
					end

					for dy = 0, dstH - 1 do
						local sy = math.min(srcH - 1, math.floor((dy + 0.5) * srcH / dstH))
						local srcRow = srcPixels + sy * srcW
						local dstRow = dstPixels + dy * dstW
						for dx = 0, dstW - 1 do
							local sx = math.min(srcW - 1, math.floor((dx + 0.5) * srcW / dstW))
							mem.u1[dstRow + dx] = mem.u1[srcRow + sx]
						end
					end

					local widget = CustomUI.CreateIcon{
						Icon = uName,
						X = WELL_X + math.floor((WELL_W - dstW) / 2),
						Y = WELL_Y + math.floor((WELL_H - dstH) / 2),
						Layer = 0,
						Masked = true,
						DynLoad = true,
						Screen = VendorScreenId,
						Condition = function()
							return currentTab == tabIndex
						end,
					}
					widget.Icon = dstStruct
					widget.MainIcon = uName
					widget.Wt = dstW
					widget.Ht = dstH
					widget.DynLoad = false
					return widget
				end
			end

			-- Standard size icon centered in sunken well
			return CustomUI.CreateIcon{
				Icon = iconName,
				X = WELL_X + math.floor((WELL_W - srcW) / 2),
				Y = WELL_Y + math.floor((WELL_H - srcH) / 2),
				Layer = 0,
				Masked = true,
				Screen = VendorScreenId,
				Condition = function()
					return currentTab == tabIndex
				end,
			}
		end
	end

	-- Safe fallback if icon dimensions were unavailable during initialization
	return CustomUI.CreateIcon{
		Icon = iconName,
		X = bx + 10,
		Y = by + 18,
		Layer = 0,
		Masked = true,
		Screen = VendorScreenId,
		Condition = function()
			return currentTab == tabIndex
		end,
	}
end

-- -------------------------------------------------------------------------------------------------
-- Screen & UI Creation
-- -------------------------------------------------------------------------------------------------
local function buildVendorUI()
	initColors()
	VendorScreenId = CustomUI.NewScreen(nil, "CraftingVendor")

	-- 1. Full Screen Procedural Background & Click Blocker
	local bgStruct = createVendorBackground()
	local bgIcon = CustomUI.CreateIcon{
		Icon = "MawCV_BG",
		X = 0,
		Y = 0,
		Layer = 1,
		BlockBG = true,
		DynLoad = true,
		Screen = VendorScreenId,
	}
	bgIcon.Icon = bgStruct
	bgIcon.MainIcon = "MawCV_BG"
	bgIcon.Wt = 640
	bgIcon.Ht = 480
	bgIcon.DynLoad = false

	-- 2. Header Area
	CustomUI.CreateText{
		Text = "CRAFTING ITEM VENDOR",
		Font = Game.Create_fnt or Game.Lucida_fnt,
		X = 0,
		Y = 8,
		Width = 640,
		Height = 18,
		ColorStd = COL_GOLD,
		ColorShadow = 0,
		Screen = VendorScreenId,
	}

	goldWidget = CustomUI.CreateText{
		Text = "Party Gold: 0",
		Font = Game.Smallnum_fnt,
		X = 16,
		Y = 28,
		Width = 280,
		Height = 16,
		ColorStd = COL_WHITE,
		ColorShadow = 0,
		AlignLeft = true,
		Screen = VendorScreenId,
	}

	merchantWidget = CustomUI.CreateText{
		Text = "Merchant Skill: Calculating...",
		Font = Game.Smallnum_fnt,
		X = 312,
		Y = 28,
		Width = 312,
		Height = 16,
		ColorStd = COL_CYAN,
		ColorShadow = 0,
		AlignLeft = true,
		Screen = VendorScreenId,
	}

	-- 3. Navigation Tabs
	local tabConfigs = {
		{ name = "[ * 1. Standard Gems * ]", x = 12,  w = 200, tab = 1 },
		{ name = "[ 2. Ascended Gems ]",       x = 220, w = 200, tab = 2 },
		{ name = "[ 3. Special Relics ]",      x = 428, w = 200, tab = 3 },
	}

	for _, tc in ipairs(tabConfigs) do
		local tIdx = tc.tab
		tabWidgets[tIdx] = CustomUI.CreateText{
			Text = tc.name,
			Font = Game.Smallnum_fnt,
			X = tc.x,
			Y = 51,
			Width = tc.w,
			Height = 18,
			ColorStd = (tIdx == 1 and COL_GOLD or COL_GREY),
			ColorMouseOver = COL_WHITE,
			ColorShadow = 0,
			Action = function()
				setTab(tIdx)
			end,
			Screen = VendorScreenId,
		}
	end

	-- 4. Item Grid (10 items per tab: 2 columns of 5 rows)
	for tabIndex = 1, 3 do
		local items = CATALOG[tabIndex]
		for itemPos = 1, 10 do
			local item = items[itemPos]
			if item then
				local cIdx = (itemPos <= 5) and 1 or 2
				local rIdx = ((itemPos - 1) % 5) + 1
				local bx = COL_X[cIdx]
				local by = ROW_Y[rIdx]
				local capturedTab = tabIndex
				local capturedItem = item

				local txtPic = Game.ItemsTxt and Game.ItemsTxt[capturedItem.id] and Game.ItemsTxt[capturedItem.id].Picture
				local iconName = (txtPic and txtPic ~= "" and txtPic ~= "null" and txtPic) or capturedItem.icon
				createVendorItemIcon(iconName, capturedItem.id, bx, by, capturedTab)

				-- Item Name
				CustomUI.CreateText{
					Text = item.name,
					Font = Game.Smallnum_fnt,
					X = bx + 54,
					Y = by + 6,
					Width = 190,
					Height = 15,
					ColorStd = COL_WHITE,
					ColorShadow = 0,
					AlignLeft = true,
					Screen = VendorScreenId,
					Condition = function()
						return currentTab == capturedTab
					end,
				}

				-- Item Price
				priceWidgets[item.id] = CustomUI.CreateText{
					Text = "Cost: " .. formatGold(BASE_PRICES[item.id] or 1000) .. " Gold",
					Font = Game.Smallnum_fnt,
					X = bx + 54,
					Y = by + 24,
					Width = 190,
					Height = 15,
					ColorStd = COL_GOLD,
					ColorShadow = 0,
					AlignLeft = true,
					Screen = VendorScreenId,
					Condition = function()
						return currentTab == capturedTab
					end,
				}

				-- Short Description
				CustomUI.CreateText{
					Text = item.desc,
					Font = Game.Smallnum_fnt,
					X = bx + 54,
					Y = by + 42,
					Width = 190,
					Height = 15,
					ColorStd = COL_GREY,
					ColorShadow = 0,
					AlignLeft = true,
					Screen = VendorScreenId,
					Condition = function()
						return currentTab == capturedTab
					end,
				}

				-- [Buy 1] Button
				CustomUI.CreateText{
					Text = "[Buy 1]",
					Font = Game.Smallnum_fnt,
					X = bx + 248,
					Y = by + 13,
					Width = 56,
					Height = 16,
					ColorStd = COL_GREEN,
					ColorMouseOver = COL_WHITE,
					ColorShadow = 0,
					Action = function()
						buyCraftingItem(capturedItem.id, 1)
					end,
					Screen = VendorScreenId,
					Condition = function()
						return currentTab == capturedTab
					end,
				}

				-- [Buy 5] Button
				CustomUI.CreateText{
					Text = "[Buy 5]",
					Font = Game.Smallnum_fnt,
					X = bx + 248,
					Y = by + 38,
					Width = 56,
					Height = 16,
					ColorStd = COL_GREEN,
					ColorMouseOver = COL_WHITE,
					ColorShadow = 0,
					Action = function()
						buyCraftingItem(capturedItem.id, 5)
					end,
					Screen = VendorScreenId,
					Condition = function()
						return currentTab == capturedTab
					end,
				}
			end
		end
	end

	-- 5. Bottom Feedback Bar & Close Button
	statusWidget = CustomUI.CreateText{
		Text = "Click [Buy 1] or [Buy 5] to purchase crafting items. Stock is unlimited.",
		Font = Game.Smallnum_fnt,
		X = 16,
		Y = 438,
		Width = 490,
		Height = 16,
		ColorStd = COL_GOLD,
		ColorShadow = 0,
		AlignLeft = true,
		Screen = VendorScreenId,
	}

	CustomUI.CreateText{
		Text = "Navigation: Keys 1, 2, 3 switch categories. Esc or Space to close.",
		Font = Game.Smallnum_fnt,
		X = 16,
		Y = 456,
		Width = 490,
		Height = 16,
		ColorStd = COL_GREY,
		ColorShadow = 0,
		AlignLeft = true,
		Screen = VendorScreenId,
	}

	-- Close Button
	CustomUI.CreateText{
		Text = "[ CLOSE (Esc) ]",
		Font = Game.Smallnum_fnt,
		X = 513,
		Y = 447,
		Width = 114,
		Height = 18,
		ColorStd = COL_RED,
		ColorMouseOver = COL_WHITE,
		ColorShadow = 0,
		Action = function()
			CloseCraftingVendor()
		end,
		Screen = VendorScreenId,
	}

	-- Shop entry button inside Alchemy Shops ONLY (House Type 4, Screen 13 main menu)
	CustomUI.CreateText{
		Text = "[Crafting Items]",
		Font = Game.Arrus_fnt or Game.Smallnum_fnt,
		Screen = 13,
		Layer = 0,
		X = SHOP_BTN_X,
		Y = SHOP_BTN_Y,
		Width = SHOP_BTN_W,
		Height = SHOP_BTN_H,
		ColorStd = COL_SHOP_BTN,
		ColorMouseOver = COL_WHITE,
		ColorShadow = 0,
		Condition = isInAlchemyShopMainMenu,
		Action = function()
			OpenCraftingVendor()
		end,
	}
end

-- -------------------------------------------------------------------------------------------------
-- Game Events
-- -------------------------------------------------------------------------------------------------
function events.GameInitialized2()
	buildVendorUI()
end

-- Prevent click-through onto Screen 13 behind [Crafting Items] (without blocking Exit / Esc)
function events.Action(t)
	local exitAction = (const.Actions and const.Actions.Exit) or 113
	if not t.Handled and t.Action ~= exitAction and isInAlchemyShopMainMenu()
			and CustomUI.MouseInBox(SHOP_BTN_X, SHOP_BTN_Y, SHOP_BTN_W, SHOP_BTN_H) then
		t.Handled = true
	end
end

-- Key Down Event for Vendor Navigation inside Vendor screen
function events.KeyDown(t)
	if Game.CurrentScreen ~= VendorScreenId then
		return
	end

	local keys = const.Keys or {}
	local escKey = keys.ESCAPE or 27
	local spaceKey = keys.SPACE or 32
	local k1, np1 = keys["1"] or 49, keys.NUMPAD1 or 97
	local k2, np2 = keys["2"] or 50, keys.NUMPAD2 or 98
	local k3, np3 = keys["3"] or 51, keys.NUMPAD3 or 99

	if t.Key == escKey or t.Key == spaceKey then
		if not t.WasPressed then
			CloseCraftingVendor()
		end
		t.Handled = true
		return
	elseif t.Key == k1 or t.Key == np1 then
		if not t.WasPressed then
			setTab(1)
		end
		t.Handled = true
	elseif t.Key == k2 or t.Key == np2 then
		if not t.WasPressed then
			setTab(2)
		end
		t.Handled = true
	elseif t.Key == k3 or t.Key == np3 then
		if not t.WasPressed then
			setTab(3)
		end
		t.Handled = true
	end
end
