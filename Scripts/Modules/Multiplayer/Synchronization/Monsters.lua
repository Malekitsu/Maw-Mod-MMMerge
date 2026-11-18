local folder = "Synchronization/Monsters/%s"

Multiplayer.SyncMonsters = {}

Multiplayer.require(folder:format("Ownership.lua"))
Multiplayer.require(folder:format("Actions.lua"))
Multiplayer.require(folder:format("Stats.lua"))
Multiplayer.require(folder:format("DamageReceived.lua"))
Multiplayer.require(folder:format("Arena.lua"))
Multiplayer.require(folder:format("Bolster.lua"))
Multiplayer.require(folder:format("CorpsePickup.lua"))
Multiplayer.require(folder:format("BountyHunt.lua"))

