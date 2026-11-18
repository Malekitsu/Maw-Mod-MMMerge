local LogEvent = Multiplayer.utils.LogEvent

local AllowNewLobbyServers = true
local LAN_HOSTS = {}
local Lobbies = {}

local function LoadLobbies()
	table.clear(Lobbies)

	local path = Multiplayer.Path .. "/Lobby servers.txt"
	local list = io.open(path, "r")
	if not list then
		LogEvent("CONNECTION", "Could not open '%s' to load list of Lobby servers.", path)
		return
	end

	for line in list:lines() do
		local words = string.split(line, "\t")
		Lobbies[words[1]] = {
			Name = words[3],
			Active = words[2] == "1",
			Hosts = {},
		}
	end
	list:close()
end
LoadLobbies()

local function GetLobby(lobbyAddr)
	local addr, port = lobbyAddr:match("(%A*):(%d*)")
	if not tonumber(port) then
		LogEvent("CONNECTION", "Attempt to get invalid lobby: %s.", lobbyAddr)
		return nil
	end

	local t = Lobbies[lobbyAddr]
	if t == nil and AllowNewLobbyServers then
		t = {
			Active = true,
			Hosts = {}
		}
		Lobbies[lobbyAddr] = t
	end
	return t
end

local function GetLobbyHosts(lobbyAddr)
	local lobby = GetLobby(lobbyAddr)
	if lobby then
		return lobby.Hosts
	end
	return nil
end

-- Interaction with lobby server is based on UDP protocol, thus, when receiving host list,
-- we cannot define whether host does not exist anymore or packet was lost.
-- To avoid inactive hosts clogging, purge hosts, that exist without confirmation from lobby server for too long.
local HostTimeout = 20 -- seconds
local function PurgeInactive()
	local stamp = os.time()
	
	local function purge(hosts)
		local keys = {}
		for k, host in pairs(hosts) do
			if not host.Active or (stamp - host.Timestamp) > HostTimeout then
				table.insert(keys, k)
			end
		end
		for _, k in pairs(keys) do
			hosts[k] = nil
		end
	end
	
	for _, lobby in pairs(Lobbies) do
		purge(lobby.Hosts)
	end
	purge(LAN_HOSTS)
end
Multiplayer.utils.MillisecCounter(PurgeInactive, HostTimeout / 2 * 1000)

function events.MultiplayerStopped()
	for _, lobby in pairs(Lobbies) do
		table.clear(lobby.Hosts)
	end
	table.clear(LAN_HOSTS)
end

return {
	Lobbies = Lobbies,
	LanHosts = LAN_HOSTS,
	LoadLobbies = LoadLobbies,
	GetLobby = GetLobby,
	GetLobbyHosts = GetLobbyHosts,
	PurgeInactive = PurgeInactive,
}
