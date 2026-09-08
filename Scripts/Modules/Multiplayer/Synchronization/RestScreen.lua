local events = Multiplayer.events
local num_to_hexstr = Multiplayer.utils.num_to_hexstr
local num_from_hexstr = Multiplayer.utils.num_from_hexstr
local item_to_bin = Multiplayer.utils.item_to_bin
local binstr_to_item = Multiplayer.utils.binstr_to_item
local cond_same_map = Multiplayer.utils.cond_same_map

local GatherPartyMessage = "All players on the map must be nearby to start rest."
local NotEnoughFoodMsg = "Party missing %s food to start rest."
local FoodBorrowed = "%s borrowed %s food from you!"
local remote_call = false
local last_food_cost = 0
local food_in_posession = {}
local borrow_food, next_lender

local acts = const.GameActions
acts.RestScreenWait5Min = 95
acts.RestScreenWait1H = 96
acts.RestScreenHeal = 97
acts.RestScreenOpen = 104
acts.RestScreenWaitDawn = 109
acts.RestScreenExit = 167

local party_operable = Multiplayer.require("Synchronization/Players/Stats.lua").party_operable

local function cant_rest_here_anim()
	local pl = math.max(Game.CurrentPlayer, 0)
	if Party[pl]:IsConscious() then
		Party[pl]:ShowFaceAnimation(const.FaceAnimation.CantRestHere)
	else
		for i, v in Party do
			if v:IsConscious() then
				v:ShowFaceAnimation(const.FaceAnimation.CantRestHere)
				break
			end
		end
	end
end

local function rest_makes_operable()
	local unaffected = {
		[const.Condition.Dead] = true,
		[const.Condition.Stoned] = true,
		[const.Condition.Paralyzed] = true,
		[const.Condition.Eradicated] = true,
	}

	local function any_unaffected(player)
		for k, v in pairs(unaffected) do
			if player.Conditions[k] > 0 then
				return true
			end
		end
		return false
	end

	for i,pl in Party do
		if pl:IsConscious() or pl.Conditions[const.Condition.Unconscious] > 0 and not any_unaffected(pl) then
			return true
		end
	end
	return false
end

local function remove_unconsciousness()
	for i, v in Party do
		v.HP = math.max(v.HP, 1)
		v.Conditions[const.Condition.Unconscious] = 0
	end
end

local function party_gathered()
	for i, v in pairs(Multiplayer.client_monsters()) do
		local mon = Multiplayer.get_client_mon(i)
		if mon and Multiplayer.utils.distance(Party, mon) > 1000 then
			return false
		end
	end
	return true
end

local function is_rest_screen()
	return Game.CurrentScreen == const.Screens.Rest
end

local action_conditions = {
	[acts.RestScreenWait5Min] = is_rest_screen,
	[acts.RestScreenWait1H] = is_rest_screen,
	[acts.RestScreenWaitDawn] = is_rest_screen,
	[acts.RestScreenExit] = is_rest_screen,

	[acts.RestScreenHeal] = function(t)
		return Game.CurrentScreen == const.Screens.Rest or Multiplayer.OnDeathScreen()
	end,

	[acts.RestScreenOpen] = function(t)
		if Game.CurrentScreen == const.Screens.Rest then
			return false
		end

		if not remote_call and (Game.TurnBased or Party.EnemyDetectorRed or Party.EnemyDetectorYellow) then
			return false, Game.GlobalTxt[480]
		end

		if not party_gathered() then
			return false, GatherPartyMessage
		end

		return true
	end,
}

local function DoRestAction(action, now, remote)
	if remote then
		Party.EnemyDetectorRed = false
		Party.EnemyDetectorYellow = false
		remote_call = remote
	end

	if action_conditions[action] and action_conditions[action]() then
		mem.u4[0x51e330] = 1
		mem.u4[0x51e334] = action
		mem.u4[0x51e338] = 0
		mem.u4[0x51e33c] = 0
		if now then
			mem.call(0x42edd8)
		end
		return true
	else
		remote_call = false
		return false
	end
end

local function SkipTimeRestScreen(minutes)
	mem.u4[0x518574] = 1
	mem.u4[0x518578] = minutes
end

local function TavernRest(WakeTime)
	local wake_time = WakeTime
	if not wake_time then
		wake_time = math.floor(Game.Time / const.Day) * const.Day
		wake_time = wake_time + (Game.Hour >= 2 and const.Day or 0)
	end

	if DoRestAction(acts.RestScreenOpen, true, true)  then
		local delta = ((wake_time + 6 * const.Hour - Game.Time) / const.Minute):floor()
		SkipTimeRestScreen(delta)
	end

	for i, v in Party do
		v:ShowFaceExpression(4, const.Minute) -- Asleep
	end
	Party.DaysWithoutRest = 0

	Timer(function()
		Party.RestAndHeal()
		RemoveTimer()
	end, Game.Time - wake_time - 1)
end

local function action_valid(action, sender_id)
	local cond = action_conditions[action]
	if cond == nil then
		return false
	end
	if sender_id ~= Multiplayer.main_player_on_map() and action ~= acts.RestScreenExit then
		return false -- actions except "exit rest screen" are forbidden for clients
	end
	if Multiplayer.OnDeathScreen() and action == acts.RestScreenHeal then
		return cond() -- Allow unconscious characters on death screen to be healed
	end
	if Game.CurrentScreen ~= const.Screens.Rest and action ~= acts.RestScreenOpen then
		return false -- rest screen action outside of rest screen
	end
	return cond()
end

local packets = {
	do_rest_action = {
		-- main player uses this packet
		bulb = function(action)
			Multiplayer.utils.LogEvent("EVENTS", "Broadcasting rest action: #%s - %s", action, table.find(acts, action))
			return item_to_bin{action, num_to_hexstr(Game.Time, 8)}
		end,
		handler = function(bin_string, metadata)
			local data = binstr_to_item(bin_string)
			local action = data[1]
			local time = num_from_hexstr(data[2], 8)
			if action_valid(action, metadata.sender_id) then
				Game.Time = time
				DoRestAction(action, false, true)
				Multiplayer.utils.LogEvent("EVENTS", "Received valid rest action: #%s - %s", action, table.find(acts, action))
			else
				Multiplayer.utils.LogEvent("EVENTS", "Skipping invalid rest action: #%s - %s", action, table.find(acts, action))
			end
		end,
		check_delivery = true,
		same_map_only = true
	},

	remote_open_rest_screen = {
		handler = function()
			if action_conditions[acts.RestScreenOpen]() then
				return true
			end

			cant_rest_here_anim()
			return false
		end,
		response = "can_open_rest_screen",
		check_delivery = true,
		same_map_only = true,
	},

	can_open_rest_screen = {
		bulb = function(bool)
			return bool and '\1' or '\0'
		end,
		handler = function(bin_string, metadata)
			return bin_string == '\1'
		end,
		same_map_only = true
	},

	request_rest_action = {
		-- clients use this packet
		bulb = function(action)
			Multiplayer.utils.LogEvent("EVENTS", "Requesting rest action: #%s - %s", action, table.find(acts, action))
			return num_to_hexstr(action, 4)
		end,
		handler = function(bin_string, metadata)
			local action = num_from_hexstr(bin_string, 4)
			return action
		end,
		response = "request_response",
		check_delivery = true,
		same_map_only = true
	},

	request_response = {
		bulb = function(action)
			-- acts.RestScreenExit should not be requested
			local result = num_to_hexstr(Game.Time, 8)
			if action == acts.RestScreenExit or not action_valid(action, Multiplayer.my_id) then
				result = '\0' .. num_to_hexstr(action, 2)
			else
				DoRestAction(action, false, false)
			end
			Multiplayer.utils.LogEvent("EVENTS", "Responding to rest action request: #%s - %s - %s", action, table.find(acts, action), result:sub(1,1) ~= '\0')
			return result
		end,
		handler = function(bin_string, metadata)
			local allow = bin_string:sub(1,1) ~= '\0'
			if allow then
				Game.Time = num_from_hexstr(bin_string, 8)
				return true
			end
			local action = num_from_hexstr(bin_string:sub(2), 2)
			if action == acts.RestScreenOpen then
				cant_rest_here_anim()
			end
			return false
		end,
		check_delivery = true,
		same_map_only = true
	},

	tavern_rest = {
		handler = function(bin_string, metadata)
			Multiplayer.utils.LogEvent("EVENTS", "Tavern rest notification received from %s", metadata.sender_id)

			if not party_operable() then
				if rest_makes_operable() then
					Multiplayer.utils.LogEvent("EVENTS", "Reviving unconscious players.")
					remove_unconsciousness()
				else
					Multiplayer.utils.LogEvent("EVENTS", "Party is not operable, skipping rest.")
					return
				end
			end

			if Game.CurrentScreen ~= 0 then
				Multiplayer.utils.ExitToScreen0(TavernRest)
			else
				TavernRest()
			end
		end,
		check_delivery = true,
		same_map_only = true
	},

	request_spare_food_amount = {
		check_delivery = true,
		same_map_only = true,
		response = "tell_spare_food_amount"
	},

	tell_spare_food_amount = {
		bulb = function()
			return Multiplayer.utils.item_to_bin{Party.Food, last_food_cost}
		end,
		handler = function(bin_string, metadata)
			local data = Multiplayer.utils.binstr_to_item(bin_string)
			food_in_posession[metadata.sender_id] = data[1]
			return data[1] - data[2]
		end,
		check_delivery = true,
		same_map_only = true
	},

	borrow_food = {
		bulb = num_to_hexstr,
		handler = function(bin_string, metadata)
			local amount = num_from_hexstr(bin_string)
			if Party.Food >= amount then
				Party.Food = Party.Food - amount
				Game.ShowStatusText(FoodBorrowed:format(Multiplayer.client_name(metadata.sender_id, true, false), amount), 6)
			else
				local lender = next_lender(Multiplayer.my_id)
				if lender then
					borrow_food(lender, amount)
				end
			end
		end,
		check_delivery = true,
		same_map_only = true
	}
}
Multiplayer.utils.init_packets(packets)

borrow_food = function(client_id, amount)
	Multiplayer.add_to_send_queue(client_id, packets.borrow_food:prep(amount))
end

next_lender = function(current)
	for client_id, client in pairs(Multiplayer.connector.clients) do
		if client.in_game and client_id > current and client.map == Map.MapStatsIndex then
			return client_id
		end
	end
end

-- no round trip before resting: missing food is borrowed on trust, the
-- lender passes the request on if it cannot cover it
local function check_food_amount()
	if last_food_cost > Party.Food then
		local main_player = Multiplayer.main_player_on_map()
		local amount = last_food_cost - Party.Food
		local lender = Multiplayer.my_id ~= main_player and main_player or next_lender(Multiplayer.my_id)
		if lender then
			Party.Food = Party.Food + amount
			borrow_food(lender, amount)
		end
	end

	return false
end

-- the rest starts here at once; remote parties get the rest action pushed to them
local function sync_open_rest_screen()
	Multiplayer.broadcast(packets.remote_open_rest_screen:prep(), cond_same_map)
	return false
end

function events.CalcRestFoodCost(t)
	last_food_cost = t.Amount
end

function events.Action(t)
	local cond = action_conditions[t.Action]
	if not cond then
		return
	end

	Multiplayer.utils.LogEvent("EVENTS", "Processing rest action: #%s - %s (remote call: %s)", t.Action, table.find(acts, t.Action), remote_call)

	local was_remote = remote_call
	local result, msg = cond()
	if not result then
		t.Handled = true
		if msg then
			Game.ShowStatusText(msg)
			Game.PlaySound(27)
		end
		remote_call = false
		return
	end

	local main_player = Multiplayer.main_player_on_map()
	local im_main = Multiplayer.my_id == main_player

	if remote_call then
		remote_call = false
	elseif im_main and t.Action == acts.RestScreenOpen then
		t.Handled = sync_open_rest_screen()
		if not t.Handled then
			Multiplayer.broadcast(packets.do_rest_action:prep(t.Action), cond_same_map)
		end
	elseif im_main or t.Action == acts.RestScreenExit then
		Multiplayer.broadcast(packets.do_rest_action:prep(t.Action), cond_same_map)
	else
		Multiplayer.add_to_send_queue(main_player, packets.request_rest_action:prep(t.Action))
		t.Handled = true
	end

	if not t.Handled then
		if t.Action == acts.RestScreenHeal then
			t.Handled = check_food_amount()
			if not t.Handled and Multiplayer.OnDeathScreen() and rest_makes_operable() then
				t.Handled = true
				remove_unconsciousness()
				Multiplayer.utils.ExitToScreen0(TavernRest, Game.Time + const.Hour * 8)
			end
			if not t.Handled then
				Party.DaysWithoutRest = 0
			end
		end
	end
end

-- tavern
function events.ClickShopTopic(t)
	if t.Topic == const.ShopTopics.RentRoom then
		local cost = Game.Houses[GetCurrentHouse()].Val
		cost = cost * (cost / 10):floor()
		if Party.Gold < cost then
			Game.ShowStatusText(Game.GlobalTxt[155]) -- not enough gold
			Game.PlaySound(27)
			return
		end

		if not party_gathered() then
			t.Handled = true
			Game.EscMessage(GatherPartyMessage)
		else
			Multiplayer.broadcast(packets.tavern_rest:prep(), cond_same_map)
		end
	end
end

-- encounter chance: prevent double encounters and chance grow depending on players amount
function events.PartyRestEncounter(t)
	if Multiplayer.my_id ~= Multiplayer.main_player_on_map() then
		t.Happened = false
		return
	end

	if t.Happened then
		Multiplayer.broadcast(packets.do_rest_action:prep(acts.RestScreenExit), cond_same_map)
	end
end
