local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local cond_same_map = Multiplayer.utils.cond_same_map

local SyncPlayers = Multiplayer.require("Synchronization/Players.lua")

local rest_initiator, remote_can_rest_call
local TELL_TIME_SET = false

Multiplayer.debug.rest_initiator = function()
	return rest_initiator
end

local function OpenRestScreen(remote, now)
	remote_can_rest_call = remote or false
	DoGameAction(0x68, 0, 0, now)
end

local packets = {
	ask_time = {
		bulb = function()
			return ""
		end,
		check_delivery = true,
		response = "tell_time"
	},

	tell_time = {
		bulb = function()
			return Multiplayer.utils.num_to_hexstr(Game.Time, 8)
		end,
		handler = function(bin_string, metadata)
			local old_time = Game.Time
			local remoteTime = mem.i8[toptr(bin_string)]
			--Multiplayer.utils.LogEvent("SYNC", "Got time from %s, difference is %s seconds", metadata.sender_id, remoteTime - old_time)

			local main_player = Multiplayer.main_player_on_map()
			if main_player == Multiplayer.my_id and (Game.Paused or Game.Paused2) then
				-- Let time flow if host's game is paused (on house / death screen)
				Game.Time = remoteTime
				if Game.CurrentScreen ~= const.Screens.Rest then
					Multiplayer.broadcast_time()
				end
			elseif main_player == metadata.sender_id then
				Game.Time = remoteTime
			end

			Party.LastRegenerationTime = math.min(Game.Time, Party.LastRegenerationTime)

			if remoteTime > old_time then
				if Game.Paused or Game.Paused2 then
					-- trigger regen ticks
					mem.call(0x491cce)
				end
			end
		end,
		check_delivery = true,
		same_map_only = true
	},
}
Multiplayer.utils.init_packets(packets)

Multiplayer.broadcast_time = function()
	Multiplayer.broadcast(packets.tell_time:prep(), cond_same_map)
end

local function tell_time()
	if Multiplayer.leave_map_halt or Game.TurnBased or Game.CurrentScreen == const.Screens.Rest then
		return
	end

	local main_player = Multiplayer.main_player_on_map()
	if main_player == Multiplayer.my_id then
		if not (Game.Paused or Game.Paused2) then
			Multiplayer.broadcast_time()
		end
	else
		Multiplayer.add_to_send_queue(main_player, packets.tell_time:prep())
	end
end
Multiplayer.utils.TickCounter(tell_time, const.Minute)

function events.GatherGameData(t)
	t.Time = Game.Time
end

function events.ProcessGameData(t)
	local old_time = Game.Time
	Game.Time = t.Time or Game.Time
	if math.abs(old_time - Game.Time) > const.Day then
		Party.DaysWithoutRest = 0
	end
end

--------------------------------------------
-- Game pause

local paused_screens = {
	[const.Screens.House] = true,
	[const.Screens.EscMessage] = true,
	[const.Screens.SimpleMessage] = true,
	[const.Screens.Rest] = true
}

local pause_no_restrictions = false
local function can_set_pause()
	if Game.LoadingScreen or pause_no_restrictions then
		return
	end

	local pause = paused_screens[Game.CurrentScreen] or false
	Game.Paused = pause
	Game.Paused2 = pause
end

function events.SettingPause(t)
	if Game.LoadingScreen or pause_no_restrictions then
		return
	end

	t.allow = false
	Multiplayer.utils.delayed_call(can_set_pause, 4)
end

function events.Tick()
	if Game.Paused or Game.Paused2 then
		if Game.LoadingScreen or pause_no_restrictions or paused_screens[Game.CurrentScreen] then
			return
		end

		Game.Paused = false
		Game.Paused2 = false
	end
end

-- manipulating pause upon map loading can cause interface break

local function check_walk_to_map_result(t)
	if t.Action == 0x5b then -- walk to map cancelled
		pause_no_restrictions = false
		events.Remove("Action", check_walk_to_map_result)
	end
end

function events.WalkToMap()
	pause_no_restrictions = true
	events.Action = check_walk_to_map_result
end

function events.LeftToMap()
	pause_no_restrictions = true
	events.Remove("Action", check_walk_to_map_result)
end

function events.MapLoadingDone()
	pause_no_restrictions = false
	events.Remove("Action", check_walk_to_map_result)
end

-- disable input, when pause disabled and game window is not active

local GetFgWnd = mem.dll['user32'].GetForegroundWindow
function events.KeysFilter(t)
	if t.Result and GetFgWnd() ~= Game.WindowHandle then
		t.Result = false
	end
end

-- game must not be paused in inventory screen, but time-flow causes inability to switch to unconcious characters (or even causes UI glitch)

local no_switch_screens = {
	[const.Screens.Inventory] = true,
	[const.Screens.Inventory2] = true,
	[const.Screens.InventoryInChest] = true,
	[const.Screens.InventoryInShop] = true,
}

function events.CanSwitchCharacter(t)
	if no_switch_screens[Game.CurrentScreen] then
		t.Handled = true
	end
end

-- remove training time consumption to avoid time desync for players on same map
-- no idea at the moment how to solve this collision in more lore-friendly way
function events.CalcTrainingTime(t)
	t.Time = 0
end

--------------------------------------------
-- Synchronize DoubleSpeed

local function GetDoubleSpeed()
	return i4[u4[Game.PatchOptions["?ptr"] + 0x8834]] == -1
end
Multiplayer.GetDoubleSpeed = GetDoubleSpeed

local function SetDoubleSpeed(state)
	local ptr = Game.PatchOptions["?ptr"]
	i4[u4[ptr + 0x8834]] = state and -1 or 0
end
Multiplayer.SetDoubleSpeed = SetDoubleSpeed

local double_speed_packets = {
	set_double_speed = {
		bulb = Multiplayer.utils.item_to_bin,
		handler = function(bin_string, metadata)
			local state = Multiplayer.utils.binstr_to_item(bin_string)
			Multiplayer.utils.LogEvent("SYNC", "Received remote DoubleSpeed state: %s.", state)

			if state ~= GetDoubleSpeed() then
				local msg = ("%s %s Double Speed."):format(Multiplayer.client_name(metadata.sender_id), state and "activated" or "deactivated")
				Game.ShowStatusText(msg)
			end

			SetDoubleSpeed(state)
		end,
		check_delivery = true,
		same_map_only = true
	}
}
Multiplayer.utils.init_packets(double_speed_packets)

local function SyncDoubleSpeed()
	Multiplayer.broadcast(double_speed_packets.set_double_speed:prep(GetDoubleSpeed()), Multiplayer.utils.cond_same_map)
end

function events.ClientChangeMap(client_id, old, new)
	if new == Map.MapStatsIndex then
		Multiplayer.utils.LogEvent("SYNC", "Client arrived from map %s (my map is %s), broadcasting DoubleSpeed state (%s).",
			new, Map.MapStatsIndex, GetDoubleSpeed())
		SyncDoubleSpeed()
	end
end

local DoubleSpeedKey
function events.KeyDown(t)
	if t.Key == DoubleSpeedKey then
		Multiplayer.utils.LogEvent("SYNC", "DoubleSpeed toggled, broadcasting state.")
		SetDoubleSpeed(not GetDoubleSpeed())
		Game.ShowStatusText(GetDoubleSpeed() and "Double speed" or "Normal speed")
		Multiplayer.utils.delayed_call(SyncDoubleSpeed, 2)
	end
end

-- override MMPatch DoubleSpeed toggle, as it does not check active window, if game is actively running in background
function events.MultiplayerStarted()
	if Game.PatchOptions.DoubleSpeedKey == -1 then
		Game.PatchOptions.DoubleSpeedKey = const.Keys.F2
	end

	DoubleSpeedKey = Game.PatchOptions.DoubleSpeedKey
	Game.PatchOptions.DoubleSpeedKey = -1
end

function events.MultiplayerStopped()
	Game.PatchOptions.DoubleSpeedKey = DoubleSpeedKey or const.Keys.F2
end
