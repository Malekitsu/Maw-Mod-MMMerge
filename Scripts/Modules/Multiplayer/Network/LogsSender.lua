local Relay = Multiplayer.require("Network/Relay.lua")
local Binary = Multiplayer.require("Network/Binary.lua")

local function set_log_sending(state)
	Multiplayer.GlobalData().SendLogs = (state == nil or state == true)
	Multiplayer.SaveGlobalData()
end

local function log_sending_enabled()
	return Multiplayer.GlobalData().SendLogs
end

local function disable_log_sending()
	set_log_sending(false)
end

local function enable_log_sending()
	set_log_sending(true)
end

local function fetch_log()
	Merge.Log.LogFile:flush()
	local file = io.open("MMMergeLog.txt", "r")
	if not file then
		return
	end

	local log = file:read("*all")
	file:close()
	--return Multiplayer.compress(log)
	return log
end

local function send_log()
	if not log_sending_enabled() then
		return
	end

	local udp = Multiplayer.connector and Multiplayer.connector.udp
	if not (udp and Relay.have_relay_access(nil, true)) then
		return
	end

	local log = fetch_log()
	if not log then
		return
	end

	Relay.send_log(log)
end
events.MultiplayerStopped = send_log

function events.MultiplayerInitialized()
	local GlobalData = Multiplayer.GlobalData()
	if GlobalData.SendLogs == nil then
		GlobalData.SendLogs = true
	end
end

function events.MultiplayerUIInitialized()
	Multiplayer.utils.UI.CustomSettings.Switch("Auto logs uploading:     ", Multiplayer.GlobalData, "SendLogs")
end

return {
	set_log_sending = set_log_sending,
	log_sending_enabled = log_sending_enabled,
	disable_log_sending = disable_log_sending,
	enable_log_sending = enable_log_sending,
	send_log = send_log
}
