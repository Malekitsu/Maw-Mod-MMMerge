Multiplayer.UI_SCREEN = CustomUI.NewScreen(nil, "MultiplayerUI")

Multiplayer.utils.UI = Multiplayer.require("UI/UtilsUI.lua")

Multiplayer.require("UI/Settings.lua")
Multiplayer.require("UI/Keybinds.lua")
Multiplayer.require("UI/Menu.lua")
Multiplayer.require("UI/House.lua")
Multiplayer.require("UI/GoldDrop.lua")
Multiplayer.require("UI/Spellbook.lua")
Multiplayer.require("UI/FriendlyFire.lua")
Multiplayer.require("UI/Network.lua")
Multiplayer.require("UI/RemotePlayers.lua")
Multiplayer.require("UI/ChooseCharacter.lua")
Multiplayer.require("UI/MergeSettingsMenu.lua")
Multiplayer.require("UI/Lobby.lua")
Multiplayer.require("UI/GlobalMap.lua")
Multiplayer.require("UI/Chat.lua")

events.Call("MultiplayerUIInitialized")

function events.MultiplayerStarted()
	Game.Dll.UILayoutSetVarInt('MultiplayerOn', 1)
end

function events.MultiplayerStopped()
	Game.Dll.UILayoutSetVarInt('MultiplayerOn', 0)
end

local events = Multiplayer.events

function events.LeaveMap()
	Game.Dll.UILayoutSetVarInt('MultiplayerOn', 0)
end

function events.BeforeLoadMap()
	Game.Dll.UILayoutSetVarInt('MultiplayerOn', 0)
end

function events.AfterLoadMap()
	Game.Dll.UILayoutSetVarInt('MultiplayerOn', 1)
end
