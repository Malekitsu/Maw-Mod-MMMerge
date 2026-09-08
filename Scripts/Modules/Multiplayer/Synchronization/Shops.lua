local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
local cond_same_map = Multiplayer.utils.cond_same_map
local mmt_dump = Multiplayer.utils.mmt_dump
local Claims = Multiplayer.Claims

local last_shop

local function type_id_from_ref(ref)
	return ref % 100, math.floor(ref / 100)
end
Multiplayer.debug.type_id_from_ref = type_id_from_ref

local function stock_by_ref(ref)
	local stock_type, stock_id = type_id_from_ref(ref)
	local stock1, stock2, refill

	if stock_type == 1 or stock_type == 2 then
		stock1 = Game.ShopItems[stock_id]
		stock2 = Game.ShopSpecialItems[stock_id]
		refill = Game.ShopNextRefill[stock_id]
	elseif stock_type >= 3 then
		stock_type = stock_type - 3
		stock1 = Game.GuildItems[stock_type]
		refill = Game.GuildNextRefill2[stock_type]
	else
		error(("Attempt to export nonexistent shop assortment: %s"):format(ref))
	end
	return stock1, stock2, refill
end
Multiplayer.debug.stock_by_ref = stock_by_ref

local packets = {
	stock_info = {
		bulb = function(shop_ref)
			local stock1, stock2, refill = stock_by_ref(shop_ref)
			local bulb = {ref = shop_ref, refill = refill, bin1 = mmt_dump(stock1), bin2 = stock2 and mmt_dump(stock2)}
			return item_to_bin(bulb)
		end,
		handler = function(bin_string, metadata)
			local data = bin_to_item(toptr(bin_string))
			local stock_type, stock_id = type_id_from_ref(data.ref)
			local stock1, stock2 = stock_by_ref(data.ref)

			if #data.bin1 == stock1['?size'] then
				mcopy(stock1['?ptr'], data.bin1)
			end
			if data.bin2 and #data.bin2 == stock2['?size'] then
				mcopy(stock2['?ptr'], data.bin2)
			end

			if stock_type == 1 or stock_type == 2 then
				Game.ShopNextRefill[stock_id] = data.refill
			else
				Game.GuildNextRefill2[stock_type - 3] = data.refill
			end
		end,
		check_delivery = true,
		compress = true
	},
}
Multiplayer.utils.init_packets(packets)

-- Init data events

local ShopTables = {"ShopItems", "ShopSpecialItems", "GuildItems", "GuildNextRefill2", "ShopNextRefill"}

function events.GatherGameData(t)
	for _, name in pairs(ShopTables) do
		t[name] = mmt_dump(Game[name])
	end
end

function events.ProcessGameData(t)
	for _, name in pairs(ShopTables) do
		if t[name] then
			mcopy(Game[name]['?ptr'], t[name])
		end
	end
end

-- Handlers
local function shop_ref(stock_type, stock_id)
	return stock_id * 100 + stock_type
end

local function shake_head()
	local cur_player = math.min(math.max(Game.CurrentPlayer, 0), Party.count - 1)
	Party[cur_player]:ShowFaceAnimation(const.FaceAnimation.ShakeHeadNo)
	Game.PlaySound(27)
end

-- one player per stock; the stock opens at once and a lost claim sends us back out
Claims.define("stock", {
	scope = "map",
	on_lost = function(ref)
		if last_shop == ref then
			last_shop = nil
			if Game.CurrentScreen == const.Screens.House then
				ExitCurrentScreen()
			end
			shake_head()
		end
	end,
})

function events.ClickShopTopic(t)
	if t.Handled then
		-- Was handled by previous functions.
		return
	end

	local house_id = GetCurrentHouse()
	local house_type = Game.Houses[house_id].Type
	if house_type < 1 or house_type > 15 then
		return
	end

	local stock_type, stock_id
	if t.Topic == const.ShopTopics.Standart then
		local shop_id = GetHouseWritePos(house_id)
		-- Game.ShopItems[shop_id]
		stock_type, stock_id = 1, shop_id

	elseif t.Topic == const.ShopTopics.Special then
		local shop_id = GetHouseWritePos(house_id)
		-- Game.ShopItemsSpecial[shop_id]
		stock_type, stock_id = 2, shop_id

	elseif t.Topic >= const.ShopTopics.MagicFire and t.Topic <= const.ShopTopics.MagicDark then -- magic topics
		local index_by_type = Game.HousesExtra[house_id].IndexByType
		local assortment_id = t.Topic - const.ShopTopics.MagicFire
		-- Game.GuildItems[index_by_type][assortment_id]
		stock_type, stock_id = index_by_type + 2, assortment_id
	else
		return
	end

	local this_shop = shop_ref(stock_type, stock_id)
	Multiplayer.debug.last_stock_ref = this_shop

	if Claims.try("stock", this_shop) == "taken" then
		shake_head()
		t.Handled = true
		return
	end
	last_shop = this_shop
end

function events.Action(t)
	if t.Action ~= 113 then
		return
	end

	local house_type = Game.Houses[GetCurrentHouse()].Type
	if house_type < 1 or house_type > 15 then
		last_shop = nil
		return
	end

	if not last_shop then
		return
	end

	if Claims.owner("stock", last_shop) == Multiplayer.my_id then
		Multiplayer.broadcast(packets.stock_info:prep(last_shop))
	end
	Claims.release("stock", last_shop)
	last_shop = nil
end
