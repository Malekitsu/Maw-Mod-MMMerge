-- MawCoreMain.lua -- entry point of the Maw greenfield core ("MawCore").
--
-- Context: GREENFIELD.md at repo root. Decisions in force (2026-08-04):
--   * lives side by side with the legacy mod in this repo (strangler migration)
--   * clean break on saves: the finished greenfield requires a new game
--   * multiplayer descoped; state changes go through named functions so sync
--     can be reattached later at those points
--
-- Structure copied from MultiplayerMain.lua, the one multi-file module this
-- codebase already ships: a single entry file, a global table, a cached
-- require, and -- the point of the whole exercise -- ONE explicit ordered
-- module list. Load order inside the core is THIS LIST, never filenames.
--
-- Two rules every submodule follows:
--   1. Loading a module only DEFINES things. No event registration, no
--      patches, no game state at load time. MawCore.start() activates
--      modules in list order, so activation timing stays pinned to the
--      loader in General/ no matter who require()s us first.
--   2. Only Engine.lua may touch mem.*, raw addresses or struct offsets
--      (GREENFIELD.md par.7, Tier 4). Everything else asks Engine.

MawCore = {}
MawCore.VERSION = 0		-- pre-release skeleton
MawCore.Path = AppPath .. "Scripts\\Modules\\MawCore\\"

local LOADED = {}
function MawCore.require(subpath)
	local filepath = MawCore.Path .. subpath
	local result = LOADED[filepath]
	if result then
		return result
	end
	result = dofile(filepath) or true
	LOADED[filepath] = result
	return result
end

-- The load order. Add new modules here and nowhere else.
MawCore.ModuleOrder = {
	"Engine",		-- Tier-4 boundary: addresses, patches, mem.*
	"Fixes",		-- engine patches ported from MAW_Fixes.dll
	"Pipeline",		-- ordered named-stage processing chains
	"Scheduler",	-- one Tick handler, named interval tasks
	"ItemFields",	-- item struct field registry (the save format)
	"Tooltip",		-- item tooltip section registry
	"Save",			-- per-save namespace + clean-break version stamp
	"Skills",		-- Skillz.dll port (inert while the DLL is present)
	"SkillsUI",		-- Skillz.dll port stage 2: character screen
	"MonsterHP",	-- real monster HP beyond the engine's 16-bit field
	"Damage",		-- CalcDamageToMonster pipeline (DAMAGE_PIPELINE.md)
}

for _, name in ipairs(MawCore.ModuleOrder) do
	MawCore.require(name .. ".lua")
end

local started = false
function MawCore.start()
	if started then
		return
	end
	started = true
	for _, name in ipairs(MawCore.ModuleOrder) do
		local m = MawCore[name]
		if m and m.start then
			m.start()
		end
	end
end
