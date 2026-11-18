local events = Multiplayer.events

local RemoteVars = {"UseMonsterBolster", "BolsterAmount", "ImprovedPathfinding"}
local LastReceivedSettings

local function log_update(MergeSettings)
	local text = {}
	for k,v in pairs(MergeSettings) do
		table.insert(text, ("%s: %s"):format(k, v))
	end
	Multiplayer.utils.LogEvent("SYNC", "Host-controlled game settings received: %s.", table.concat(text, ", "))
end

local function prep_merge_settings()
	if not vars.ExtraSettings then
		return
	end

	local MergeSettings = {}
	for _, v in pairs(RemoteVars) do
		MergeSettings[v] = Game[v]
	end
	MergeSettings.BolsterMultipliers = Game.Bolster.Multipliers

	return MergeSettings
end

local function process_merge_settings(MergeSettings)
	if MergeSettings then
		vars.BolsterMultipliers = vars.BolsterMultipliers or {}
		for k,v in pairs(MergeSettings.BolsterMultipliers) do
			vars.BolsterMultipliers[k] = v
			Game.Bolster.Multipliers[k] = v
		end

		for _, v in pairs(RemoteVars) do
			Game[v] = MergeSettings[v]
			vars.ExtraSettings[v] = MergeSettings[v]
		end
	end
end

local packets = {
	merge_settings = {
		bulb = function()
			return Multiplayer.utils.item_to_bin(prep_merge_settings())
		end,
		handler = function(bin_string, metadata)
			if metadata.sender_id ~= Multiplayer.main_player_in_game() then
				return
			end

			local t = Multiplayer.utils.binstr_to_item(bin_string)
			process_merge_settings(t)
			log_update(t)
			LastReceivedSettings = t
		end,
		check_delivery = true
	}
}
Multiplayer.utils.init_packets(packets)

function events.ExitExtraSettingsMenu()
	local main_player = Multiplayer.main_player_in_game()
	if main_player == Multiplayer.my_id then
		Multiplayer.broadcast(packets.merge_settings:prep(), nil)
	else
		process_merge_settings(LastReceivedSettings) -- revert
	end
end

function events.GatherGameData(t)
	t.MergeSettings = prep_merge_settings()
end

function events.ProcessGameData(t)
	process_merge_settings(t.MergeSettings)
	log_update(t.MergeSettings)
	LastReceivedSettings = t.MergeSettings
end

-- UI

local UIUtils = Multiplayer.require("UI/UtilsUI.lua")
local function HostControllNote(X, Y)
	local function StdCond()
		return Multiplayer.in_game and Multiplayer.my_id ~= Multiplayer.main_player_in_game()
	end
	local Text = UIUtils.SimpleText(const.Screens.MergeExtraSettings, "(host only)", X, Y, Game.Smallnum_fnt, StdCond)
	return Text
end

HostControllNote(460, 185)
HostControllNote(460, 225)
HostControllNote(460, 340)
