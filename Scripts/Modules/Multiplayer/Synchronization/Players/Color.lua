local events = Multiplayer.events

local COLORS = {
	--{220, 244, 244, Name = "White"}, -- does not fit UI well
	{225, 30, 35, Name = "Red"},
	{244, 254, 2, Name = "Yellow"},
	{43, 98, 30, Name = "Green"},
	{30, 220, 220, Name = "Cyan"},
	{32, 89, 245, Name = "Blue"},
	{73, 48, 233, Name = "Purple"},
	{253, 21, 220, Name = "Magenta"},
	{25, 25, 25, Name = "Black"},
}

Multiplayer.DEFAULT_PLAYER_COLOR = COLORS[1]

local function ShadowColor(r, g, b)
	local function CSh(n)
		return n > 100 and math.max(n - 50, 10) or math.min(n + 100, 250)
	end
	return RGB(CSh(r), CSh(g), CSh(b))
end

local ColorByName = {}
for k, color in pairs(COLORS) do
	color.Number = RGB(color[1], color[2], color[3])
	color.Shadow = ShadowColor(color[1], color[2], color[3])
	ColorByName[color.Name] = color
end

Multiplayer.preferred_color = Multiplayer.DEFAULT_PLAYER_COLOR

local BroadcastPlayerColors
local SelectedColors = {}
local function EvenlySplitted()
	local k, n = next(SelectedColors)
	for k, v in pairs(SelectedColors) do
		if v ~= n then
			return false
		end
	end
	return true
end

local function MaxUsage()
	local k, n = next(SelectedColors)
	for k, v in pairs(SelectedColors) do
		if v > n then
			n = v
		end
	end
	return n
end

local function ColorIsFree(client_id, color)
	if not color.Name or SelectedColors[color.Name] == nil then
		Multiplayer.utils.LogEvent("PLAYERS_SYNC", "Unknown color '%s' received from client #%d", color.Name, client_id)
		return false
	end

	if SelectedColors[color.Name] == 0 then
		return true
	end

	return SelectedColors[color.Name] < MaxUsage() or EvenlySplitted()
end

local function FindFreeColor()
	local free, n = next(SelectedColors)
	for k, v in pairs(SelectedColors) do
		if v < n then
			free = k
			n = v
		end
	end
	return ColorByName[free]
end

local function TakeFreeColor()
	local color = FindFreeColor()
	SelectedColors[color.Name] = (SelectedColors[color.Name] or 0) + 1
	return color
end

local function InitSelectedColors()
	for k, color in pairs(COLORS) do
		SelectedColors[color.Name] = 0
	end
end

-- On multiplayer start - load color from save
function events.MultiplayerStarted()
	local t = Multiplayer.SaveGameData().PlayerColor
	if t then
		Multiplayer.preferred_color = t
	end
	InitSelectedColors()
	SelectedColors[Multiplayer.preferred_color.Name] = 1
end

-- On save (GatherPlayerInfo event) - store color in save data
function events.BeforeSaveGame()
	Multiplayer.SaveGameData().PlayerColor = Multiplayer.preferred_color
end

-- On joining game - send selected color to host
function events.GatherClientInitData(t)
	t.PlayerColor = Multiplayer.preferred_color
end

function events.ProcessClientInitData(client_id, t)
	local client = Multiplayer.client_info(client_id)

	if not t.PlayerColor then
		Multiplayer.utils.LogEvent("PLAYERS_SYNC", "Client #%d have not provided preferred color", client_id)
		client.PlayerColor = TakeFreeColor()
	elseif ColorIsFree(client_id, t.PlayerColor) then
		client.PlayerColor = t.PlayerColor
	else
		client.PlayerColor = TakeFreeColor()
		Multiplayer.utils.LogEvent("PLAYERS_SYNC", "Selected free color for player #%d - '%s'", client_id, client.PlayerColor.Name)
	end

	-- Notify players
	Multiplayer.utils.delayed_call2(BroadcastPlayerColors, 1000)
end

local packets = {
	color_changed = {
		bulb = function()
			return Multiplayer.utils.item_to_bin(Multiplayer.preferred_color)
		end,
		handler = function(bin_string, metadata)
			if not Multiplayer.im_host() then
				return
			end

			local color = Multiplayer.utils.binstr_to_item(bin_string)
			if ColorIsFree(metadata.sender_id, color) then
				Multiplayer.client_info(metadata.sender_id).PlayerColor = color
			else
				Multiplayer.client_info(metadata.sender_id).PlayerColor = TakeFreeColor()
			end
			BroadcastPlayerColors()
		end,
		check_delivery = true,
		compress = true,
		ignore_reload_count = true
	},

	player_colors = {
		bulb = function()
			local t = {[Multiplayer.my_id] = Multiplayer.preferred_color.Name}
			local color
			for client_id, client in pairs(Multiplayer.connector.clients) do
				if client.PlayerColor then
					t[client_id] = client.PlayerColor.Name
				end
			end
			return Multiplayer.utils.item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			local t = Multiplayer.utils.binstr_to_item(bin_string)
			if t[Multiplayer.my_id] then
				Multiplayer.preferred_color = ColorByName[t[Multiplayer.my_id]]
				Multiplayer.utils.LogEvent("PLAYERS_SYNC", "Color '%s' assigned by host", t[Multiplayer.my_id])
			end
			InitSelectedColors()
			for client_id, name in pairs(t) do
				local client = Multiplayer.client_info(client_id)
				local color = ColorByName[name]
				if client then
					client.PlayerColor = color or Multiplayer.DEFAULT_PLAYER_COLOR
					SelectedColors[name] = SelectedColors[name] + 1
				else -- host processed client, but client-to-client connection have not been established yet
					local f = function()
						local timeout = os.time() + 16
						while true do
							local client = Multiplayer.client_info(client_id)
							if not client then
								if os.time() > timeout then
									Multiplayer.utils.LogEvent("PLAYERS_SYNC", "Could not assign color '%s' to client #%d within timeout of %d sec: client entry does not exist.", color.Name, client_id, 16)
									return
								end
								coroutine.yield()
							else
								client.PlayerColor = color
								return
							end
						end
					end
					Multiplayer.utils.CoMillisecCounter(coroutine.create(f), 1000)
				end
			end
		end,
		check_delivery = true,
		compress = true,
		ignore_reload_count = true
	}
}
Multiplayer.utils.init_packets(packets)

BroadcastPlayerColors = function()
	Multiplayer.broadcast(packets.player_colors:prep(), nil)
end

function NotifyColorChange()
	Multiplayer.add_to_send_queue(Multiplayer.main_player_in_game(), packets.color_changed:prep())
end

-- UI elements

local ChangedColor
local ListSwitch
function Multiplayer.std_events.MultiplayerInitialized()
	local t = {}
	for i, v in ipairs(COLORS) do
		table.insert(t, v.Name)
	end

	local UI = Multiplayer.utils.UI.CustomSettings
	local Group = UI.Group("Remote players UI", "Remote players UI")

	ListSwitch = Group:ListSwitch("Preferred color: ", t, function(t, value)
		ChangedColor = ColorByName[value]
		t.Value.CStd = ChangedColor.Number
		t.Value.CSh = ChangedColor.Shadow
	end)

	ListSwitch.Update = function(t)
		t.Value.Text = " " .. Multiplayer.preferred_color.Name
		t.Value.CStd = Multiplayer.preferred_color.Number
		t.Value.CSh = Multiplayer.preferred_color.Shadow
		t.Value:UpdateSize(18)
	end
end

-- On color change - send selected color to host

function events.MultiplayerExtraSettingsClosed()
	if ChangedColor then
		Multiplayer.preferred_color = ChangedColor
		ChangedColor = nil
		NotifyColorChange()
	end
end

-- On menu open filter accessible colors

function events.MultiplayerExtraSettingsOpen()
	local max = 0
	for name, count in pairs(SelectedColors) do
		max = math.max(max, count)
	end
	local list = {}
	for name, count in pairs(SelectedColors) do
		if count < max then
			table.insert(list, name)
		end
	end
	if #list == 0 then
		for _, v in pairs(COLORS) do
			table.insert(list, v.Name)
		end
	end
	ListSwitch.List = list
end

return {
	COLORS = COLORS,
	ColorByName = ColorByName,
	NotifyColorChange = NotifyColorChange,
}
