local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
local cond_same_map = Multiplayer.utils.cond_same_map
local mmt_dump = Multiplayer.utils.mmt_dump
local num_to_hexstr = Multiplayer.utils.num_to_hexstr
local num_from_hexstr = Multiplayer.utils.num_from_hexstr

local last_shop
local shop_users = {}
local pending_stock = {} -- request hash -> stock ref opened on trust

Multiplayer.debug.shop_users = shop_users

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
		error(("Attempt to export nonexistent shop assortment: %s"):format(shop_ref))
	end
	return stock1, stock2, refill
end
Multiplayer.debug.stock_by_ref = stock_by_ref

local packets = {
	can_open_stock = {
		bulb = num_to_hexstr,
		handler = function(bin_string, metadata)
			local shop_ref = num_from_hexstr(bin_string, 4, false)

			local clients = Multiplayer.connector.clients
			local user
			for ref, client_id in pairs(shop_users) do
				if client_id ~= Multiplayer.my_id then
					user = clients[client_id]
					if not user or not user.in_game then
						shop_users[ref] = nil
					end
				end
			end

			user = shop_users[shop_ref]
			if user == nil then
				shop_users[shop_ref] = metadata.sender_id
			end
			return shop_users
		end,
		check_delivery = true,
		response = 'can_open_stock_result'
	},

	can_open_stock_result = {
		bulb = function(handler_result)
			return item_to_bin(handler_result)
		end,
		handler = function(bin_string, metadata)
			local result = bin_to_item(toptr(bin_string))
			for k,v in pairs(result) do
				shop_users[k] = v
			end

			-- we opened the stock on trust; if somebody else holds it, step back out
			local ref = pending_stock[metadata.response_to]
			pending_stock[metadata.response_to] = nil
			if ref and last_shop == ref and shop_users[ref] ~= nil and shop_users[ref] ~= Multiplayer.my_id then
				last_shop = nil
				if Game.CurrentScreen == const.Screens.House then
					ExitCurrentScreen()
				end
				local cur_player = math.min(math.max(Game.CurrentPlayer, 0), Party.count - 1)
				Party[cur_player]:ShowFaceAnimation(const.FaceAnimation.ShakeHeadNo)
				Game.PlaySound(27)
			end
			return shop_users
		end,
		check_delivery = true
	},

	free_stock = {
		bulb = num_to_hexstr,
		handler = function(bin_string, metadata)
			local shop_ref = num_from_hexstr(bin_string, 4, false)
			shop_users[shop_ref] = nil
		end,
		check_delivery = true
	},

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

local function can_view_assortment(ref)
	local user = shop_users[ref]
	local result = user == nil or user == Multiplayer.my_id
	if not result then
		local cur_player = math.min(math.max(Game.CurrentPlayer, 0), Party.count - 1)
		Party[cur_player]:ShowFaceAnimation(const.FaceAnimation.ShakeHeadNo)
		Game.PlaySound(27)
	end
	return result
end

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

	local main_player = Multiplayer.main_player_on_map()
	if main_player == Multiplayer.my_id then
		t.Handled = not can_view_assortment(this_shop)
	else
		-- open with what we know; the main player's answer can still send us back out
		t.Handled = not can_view_assortment(this_shop)
		if not t.Handled then
			local hash = Multiplayer.add_to_send_queue(main_player, packets.can_open_stock:prep(this_shop))
			pending_stock[hash] = this_shop
		end
	end

	if not t.Handled then
		last_shop = this_shop
		shop_users[this_shop] = Multiplayer.my_id
	end
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

	if shop_users[last_shop] == Multiplayer.my_id then
		shop_users[last_shop] = nil

		local data = packets.stock_info:prep(last_shop)
		Multiplayer.broadcast(data)

		local data = packets.free_stock:prep(last_shop)
		Multiplayer.add_to_send_queue(Multiplayer.main_player_on_map(), data)
	end

	last_shop = nil
end

