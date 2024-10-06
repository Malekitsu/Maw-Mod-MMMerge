local folder = "Synchronization/%s"

local modules = {
	"Players.lua",
	"Monsters.lua",
	"SaveLoadExit.lua",
	"MapLoad.lua",
	"Mapvars.lua",
--	"TurnBased.lua",
	"Objects.lua",
	"Chests.lua",
	"Shops.lua",
	"Weather.lua",
	"Sprites.lua",
--	"Evt.lua",
	"Spells.lua",
--	"Quests.lua",
	"QuestsSpecial.lua",
	"Time.lua",
	"Doors.lua",
--	"BankGold.lua",
--	"ArcomageWins.lua",
--	"RestScreen.lua"
}

for _, name in pairs(modules) do
	Multiplayer.require(folder:format(name))
end


