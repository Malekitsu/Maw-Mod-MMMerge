local folder = "Synchronization/Players/%s"

local SyncPlayers = {}
local function import_module(name)
	local r = Multiplayer.require(folder:format(name))
	if type(r) == "table" then
		for k, v in pairs(r) do
			SyncPlayers[k] = v
		end
	end
end

import_module("Stats.lua")
import_module("Monster.lua")
import_module("Position.lua")
import_module("Experience.lua")
import_module("StepSounds.lua")
import_module("ItemSounds.lua")
import_module("Color.lua")

Multiplayer.client_info = SyncPlayers.client_info
Multiplayer.client_name = SyncPlayers.client_name
Multiplayer.get_client_mon = SyncPlayers.get_client_mon
Multiplayer.client_monsters = SyncPlayers.client_monsters
Multiplayer.posessed_by_player = SyncPlayers.posessed_by_player
Multiplayer.notify_player_stats = SyncPlayers.notify_player_stats
Multiplayer.notify_player_position = SyncPlayers.notify_player_position
Multiplayer.request_player_stats = SyncPlayers.request_player_stats
Multiplayer.hide_client_monsters = SyncPlayers.hide_client_monsters
Multiplayer.unhide_client_monsters = SyncPlayers.unhide_client_monsters

Multiplayer.SyncPlayers = SyncPlayers

return SyncPlayers
