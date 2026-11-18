local lobby = Multiplayer.require("Network/Lobby/Messages.lua")

-- User defined port

local function LineCheck(self, s)
	local n
	if #s == 0 then
		n = 0
	else
		n = tonumber(s)
		if not n or n <= 0 or n > 0xFFFF then
			CustomUI.DisplayTooltip("Port must be a number greater than 0 and lower than 65535", 8)
			return false
		end
	end

	if Multiplayer.in_game then
		CustomUI.DisplayTooltip("Multiplayer currently running. Restart it to apply new port.", 8)
	end

	return true, n
end

local function MultiplayerPortCheck(self, s)
	local success, n = LineCheck(self, s)
	if success then
		Multiplayer.GlobalData().LastUserSelectedPort = n
		Multiplayer.SaveGlobalData()
		Multiplayer.UDP_PORT = n
	end
	return success
end

local function UpdateMultiplayerPort(self)
	self.Value = tostring(Multiplayer.UDP_PORT)
	self.Input.Text = self.Value
	self.Input:UpdateSize(12)
end

local function LobbyPortCheck(self, s)
	local success, n = LineCheck(self, s)
	if success then
		Multiplayer.GlobalData().LastLobbyPort = n
		Multiplayer.SaveGlobalData()
		lobby.SetPort(n)
	end
	return success
end

local function UpdateLobbyPort(self)
	self.Value = tostring(lobby.LAN_LOBBY_PORT)
	self.Input.Text = self.Value
	self.Input:UpdateSize(12)
end

local function SymbolCheck(self, s)
	local n = tonumber(s)
	return n and n >= 0
end

function events.MultiplayerInitialized()
	local data = Multiplayer.GlobalData()
	Multiplayer.UDP_PORT = data.LastUserSelectedPort or 0
	if data.LastLobbyPort then
		lobby.SetPort(data.LastLobbyPort)
	end

	local UI = Multiplayer.utils.UI.CustomSettings
	UI.Header("Network")
	UI.TextInput("Multiplayer port: ", "0", SymbolCheck, MultiplayerPortCheck, UpdateMultiplayerPort)
	UI.TextInput("LAN lobby port: ", tostring(lobby.DEFAULT_LAN_PORT), SymbolCheck, LobbyPortCheck, UpdateLobbyPort)
end

