local events = Multiplayer.events

local SyncPlayers = Multiplayer.require("Synchronization/Players.lua")

local get_client_mon = SyncPlayers.get_client_mon
local client_name = SyncPlayers.client_name
local distance = Multiplayer.utils.distance

local function CanShowSpellbookTip(t)
	local names = {}
	for client_id, _ in pairs(SyncPlayers.client_monsters()) do
		local mon = get_client_mon(client_id)
		if mon and distance(mon, Party) < Multiplayer.SHARE_BUFF_RANGE then
			table.insert(names, client_name(client_id, false, true))
		end
	end

	if #names == 0 then
		return false
	end

	t.Text = "Players in range: " .. table.concat(names, ", ")
	return true
end

local players_in_range_text

function events.MultiplayerStarted()
	if players_in_range_text then
		CustomUI.ActiveElements[const.Screens.SpellBook].Texts[0][players_in_range_text.Key] = players_in_range_text
	else
		players_in_range_text = CustomUI.CreateText{
			Font = Game.Lucida_fnt,
			X = 50,
			Y = 456,
			Width = 640,
			Height = 480,
			AlignLeft = true,
			Text = "",
			ColorStd = 1,
			ColorShadow = RGB(255, 255, 255),
			Screen = const.Screens.SpellBook,
			Layer = 0,
			Key = "MultiplayerSpellbookTip",
			Condition = CanShowSpellbookTip
		}
		Multiplayer.debug.spellbook_tip = players_in_range_text
	end
end

function events.MultiplayerStopped()
	CustomUI.RemoveElement(players_in_range_text)
end
