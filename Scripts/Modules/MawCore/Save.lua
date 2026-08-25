-- Save.lua -- per-save namespace and the clean-break stamp.
--
-- Decision (2026-08-04): the finished greenfield requires a NEW GAME.
-- Players finish current runs on the stable release; there is no migration
-- path. vars.MawCore.version is the stamp that lets greenfield systems tell
-- a greenfield save from a legacy one. Enforcement (warn? refuse?) is not
-- decided yet; the skeleton enforces nothing.
--
-- All MawCore per-save state lives under vars.MawCore -- core modules never
-- write other top-level vars keys. Note that 'vars' only exists while a game
-- is loaded: never call Save.data() from load-time code, only from event
-- handlers and functions that run in-game.

local Save = {}
MawCore.Save = Save

Save.VERSION = 1

-- Lazily creates the namespace. First write from any greenfield system is
-- what stamps a save as greenfield -- there is no separate stamping step.
function Save.data()
	local d = vars.MawCore
	if not d then
		d = {version = Save.VERSION}
		vars.MawCore = d
	end
	return d
end

function Save.isGreenfieldSave()
	return vars.MawCore ~= nil
end
