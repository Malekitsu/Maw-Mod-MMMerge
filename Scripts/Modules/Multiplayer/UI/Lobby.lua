local events = Multiplayer.events
local UIUtils = Multiplayer.require("UI/UtilsUI.lua")
local relay = Multiplayer.require("Network/Relay.lua")
local conn = Multiplayer.require("Network/Lobby.lua")
local msgs = Multiplayer.require("Network/Lobby/Messages.lua")

local function TextTumbler(...)
	return UIUtils.TextTumbler(Multiplayer.UI_SCREEN, ...)
end
local function SimpleText(...)
	return UIUtils.SimpleText(Multiplayer.UI_SCREEN, ...)
end

-- Create "Direct connect / server list" tumbler for client
local UpdateHostTable
local ServerListOpen = false

local ClienConnTumb = TextTumbler(350, 125, nil, "Server list", " Direct connect", true,
	function(self)
		ServerListOpen = self.On
		if ServerListOpen then
			conn.EnableLobbyLookup()
			conn.BroadcastHostsListRequest()
			Multiplayer.utils.delayed_call2(UpdateHostTable, 200)
		else
			conn.DisableLobbyLookup()
		end
	end,
	function() return not conn.ImHost() and Multiplayer.in_game and Multiplayer.CurrentUITab() == "connection" end
)

local function ToggleServerList(state)
	if state == nil then
		ServerListOpen = not ServerListOpen
		ClienConnTumb.set_state(ServerListOpen)
	else
		ServerListOpen = state
		ClienConnTumb.set_state(state)
	end
	return ServerListOpen
end

function events.MultiplayerStopped()
	ToggleServerList(false)
end

function events.MultiplayerStarted()
	ToggleServerList(false) -- Multiplayer.selected_role() == "client"
end

function events.MultiplayerRoleChanged(role)
	ToggleServerList(false) -- role == "client"
end

-- Create "Closed / Open" tumbler for host with "?" button for tooltip

local HostOpenTumb = TextTumbler(480, 125, nil, "Open ", "Closed", false,
	function(self)
		if self.On then
			local inputs = {
				{header = "Name:       ", default = conn.MyHostGlobals.Name, empty = "Enter server name", multiline = false, limit = 40},
				{header = "Password:   ", default = conn.MyHostGlobals.Password, empty = "none", multiline = false, hidden = true, limit = 40},
				{header = "Description:", default = conn.MyHostGlobals.Description, empty = "Enter server description", multiline = true},
			}

			UIUtils.PopupInput(
				"Open lobby", "Enter server info:", inputs, "  Open ", nil,
				function(values)
					conn.MyHostGlobals.Name = values["Name:       "]
					conn.MyHostGlobals.Password = values["Password:   "]
					conn.MyHostGlobals.Description = values["Description:"]
					conn.EnableLobbyLookup()
					conn.BroadcastMyHost()
				end,
				function()
					self.set_state(conn.LobbyLookupState())
				end)
		else
			conn.DisableLobbyLookup()
		end
	end,
	function() return conn.ImHost() and Multiplayer.in_game and Multiplayer.CurrentUITab() == "connection" end
)

function events.MultiplayerStopped()
	conn.DisableLobbyLookup()
	HostOpenTumb.set_state(false)
end

function events.MultiplayerRoleChanged(role)
	if role ~= "host" then
		conn.DisableLobbyLookup()
		HostOpenTumb.set_state(false)
	end
end

function events.LobbyHostingEnabled()
	HostOpenTumb.set_state(true)
end

function events.LobbyHostingDisabled()
	HostOpenTumb.set_state(false)
end

SimpleText("?", 620, 125, nil,
	function() return conn.ImHost() and Multiplayer.in_game and Multiplayer.CurrentUITab() == "connection" end,
	function()
		CustomUI.DisplayTooltip("Closed hosts accept only direct connections.\n  \nOpen LAN hosts are discoverable in local network\n  \nOpen internet hosts publish themselves on accessible Lobby servers.", 30)
	end
)

-- Create hosts table

local function _ServerListOpen()
	return ServerListOpen and Multiplayer.CurrentUITab() == "connection"
end

local function LobbyHosts()
	local hosts
	if not Multiplayer.internet_connection then
		hosts = conn.LANHosts
		for _, host in pairs(hosts) do
			host.Lobby = "LAN"
			host.LobbyAddr = msgs.LAN_LOBBY
		end
	else
		hosts = {}
		for addr, lobby in pairs(conn.Lobbies) do
			for _, host in pairs(lobby.Hosts) do
				host.Lobby = lobby.Name
				host.LobbyAddr = addr
				table.insert(hosts, host)
			end
		end
	end
	return hosts
end

local function FilterHosts(hosts)
	local result = {}
	for _, host in pairs(hosts) do
		if conn.Selection.SkipPassword and host.PasswordUsed or
			conn.Selection.SkipFull and host.Players >= host.MaxPlayers or
			#conn.Selection.Version > 0 and conn.Selection.Version ~= host.Version then
			-- do nothing
		else
			table.insert(result, host)
		end
	end

	table.sort(result, function(v1,v2) return v1.Name < v2.Name end)
	return result
end

local function ChangeRelay(Addr)
	if Multiplayer.internet_connection and relay.have_relay_access(Addr, true, false, 2000) then
		relay.set_relay_addrport(Addr:match("(%A*):(%d*)"))
	end
end

local function Connect(entry)
	local Input = entry.Data.PasswordUsed and {{header = "Password", default = "", empty = "none", hidden = true, limit = 40}}
	local Descr = entry.Data.Description

	local ServerDesc = ("%s\n  \n%s\n  \n%s\n  \n%s"):format(
		entry.Data.Name, Descr,
		("Players: %d / %d"):format(entry.Data.Players, entry.Data.MaxPlayers), "Version: " .. entry.Data.Version)

	local ProgressTemplate = "Attempt %d. Waiting for response..."
	local Attempt = 0
	local Request
	local function Caller()
		if Attempt > 0 and not conn.CurrentJoinRequest() then
			ChangeRelay(entry.Data.LobbyAddr)
			return true, "Connected"
		elseif Attempt == 4 then
			Attempt = Attempt + 1
			return false, "Timed out"
		elseif Attempt > 4 then
			conn.ClearPendingRequests()
			return true, "Timed out"
		end
		conn.Join(entry.Data.LobbyAddr, Request)
		Attempt = Attempt + 1
		return false, ProgressTemplate:format(Attempt)
	end

	local function Accepted(values)
		Request = msgs.NewJoinRequest(entry.Data.SessionCode, Multiplayer.my_session_code(), values and values["Password"] or "")
		UIUtils.PopupProgress("Connection to " .. entry.Data.Name, "", Caller, 3000, 15000, "JoiningLobby")
	end

	UIUtils.PopupInput("Server connection", ServerDesc, Input, "Connect", nil, Accepted)
end

function events.JoinLobbyRejected(reason)
	CustomUI.DisplayTooltip("Join request rejected: " .. reason, 30, nil, nil, nil, Multiplayer.UI_SCREEN)
end

local HostTable = UIUtils.TextTable(Multiplayer.UI_SCREEN, {"Repr"}, 40, 175, _ServerListOpen, {Repr = Connect})

UpdateHostTable = function()
	conn.PurgeInactive()
	local hosts = FilterHosts(LobbyHosts())
	for i, host in pairs(hosts) do
		hosts[i] = {Data = host, Repr = ("%d. %s | %s | %d / %d | %s | %s"):format(i, host.Name, host.PasswordUsed and "P" or " ", host.Players, host.MaxPlayers, host.Lobby, host.Version)}
	end
	HostTable:load(hosts)
end

function events.MultiplayerStopped()
	HostTable:clear()
end

-- Create table header

local HeaderY = 150

SimpleText("Update", 40, HeaderY, Game.Smallnum_fnt, _ServerListOpen,
	function()
		conn.BroadcastHostsListRequest()
		UpdateHostTable()
	end)

SimpleText("Hide full", 150, HeaderY, Game.Smallnum_fnt,
	function() return _ServerListOpen() and not conn.Selection.SkipFull end,
	function() conn.Selection.SkipFull = true; UpdateHostTable() end
)
SimpleText("Hide passworded", 250, HeaderY, Game.Smallnum_fnt,
	function() return _ServerListOpen() and not conn.Selection.SkipPassword end,
	function() conn.Selection.SkipPassword = true; UpdateHostTable() end
)
SimpleText("Hide other versions", 400, HeaderY, Game.Smallnum_fnt,
	function() return _ServerListOpen() and #conn.Selection.Version == 0 end,
	function() conn.Selection.Version = Multiplayer.VERSION; UpdateHostTable() end
)

SimpleText("Show full", 150, HeaderY, Game.Smallnum_fnt,
	function() return _ServerListOpen() and conn.Selection.SkipFull end,
	function() conn.Selection.SkipFull = false; UpdateHostTable() end
)
SimpleText("Show passworded", 250, HeaderY, Game.Smallnum_fnt,
	function() return _ServerListOpen() and conn.Selection.SkipPassword end,
	function() conn.Selection.SkipPassword = false; UpdateHostTable() end
)
SimpleText("Show other versions", 400, HeaderY, Game.Smallnum_fnt,
	function() return _ServerListOpen() and #conn.Selection.Version > 0 end,
	function() conn.Selection.Version = ""; UpdateHostTable() end
)


Multiplayer.utils.MillisecCounter(function()
	if Game.CurrentScreen == Multiplayer.UI_SCREEN and ServerListOpen then
		conn.BroadcastHostsListRequest()
		UpdateHostTable()
	end
end, 10000)

--

return {
	ServerListOpen = _ServerListOpen,
	ToggleServerList = ToggleServerList
}
