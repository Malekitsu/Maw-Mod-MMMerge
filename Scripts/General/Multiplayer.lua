local function Init()
	--if tonumber(Merge.PackVersion) < 20231105 or  tonumber(Merge.PatchVersion) < 20240930 then
	--	local text = 
	--	"\n" ..
	--	"Multiplayer disabled.\n" .. 
	--	"Multiplayer requires pack version of 05.11.2023 or older and patch version 30.09.2024 or older.\n\n" ..
	--	"Version of the merge: %s\n\n" .. 
	--	"Check and download latest merge patch at https://www.celestialheavens.com/forum/topic/16657"
	--	
	--	debug.Message(text:format(Merge.VersionFull))
	--	return
	--end

	require "MultiplayerMain"

	events.Call("MultiplayerInitialized")

	CustomUI.CreateButton{
		IconUp = "MulBUp",
		IconDown = "MulBDw",
		IconMouseOver = "MulBMO",
		X = 511,
		Y = 11,
		Layer = 1,
		Screen = 1,
		IsEllipse = true,
		Action = Multiplayer.OpenMulUI,
		MouseOverAction = function() Game.ShowStatusText("Multiplayer") end,
		Key = "MultiplayerUIButton"
	}
end

events.GameInitialized2 = Init