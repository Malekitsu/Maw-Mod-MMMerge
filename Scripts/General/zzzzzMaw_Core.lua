-- zzzzzMaw_Core.lua -- loads and starts the greenfield core (MawCore).
--
-- Five z's: the last file in General/ (the legacy maximum is four, the
-- randomizer). During the strangler migration this guarantees every event
-- handler MawCore registers fires AFTER all legacy handlers. Load order
-- INSIDE the core is the explicit list in Scripts/Modules/MawCoreMain.lua --
-- never add more z-files to sequence core modules.
--
-- General/ lifecycle: runs once, before the game starts. A full game restart
-- is needed to pick up changes here or anywhere in Scripts/Modules/MawCore/.

require "MawCoreMain"
MawCore.start()
