-- Sync.lua -- the core's multiplayer glue: who is host, and the game state
-- the host owns and every client mirrors (join-time via the base module's
-- game data, live via a questdata packet whenever the host's copy changes).

local Sync = {}
MawCore.Sync = Sync

function Sync.inGame()
	return Multiplayer ~= nil and Multiplayer.in_game == true
end

function Sync.isHost()
	return Sync.inGame() and Multiplayer.im_host()
end

function Sync.isClient()
	return Sync.inGame() and not Multiplayer.im_host()
end

-- Host-owned game state. vars keys are mirrored verbatim (tables replaced
-- content-wise, so references held by other files stay valid); Game fields
-- likewise. Add a key here and nowhere else.
Sync.GameStateVars = {
	"Mode", "insanityMode", "madnessMode", "AusterityMode", "trueNightmare",
	"freeProgression", "MAWSETTINGS", "MMLVL", "EXPBEFORE", "LVLBEFORE",
}
Sync.GameStateGame = {"Mode", "BolsterAmount", "freeProgression"}

-- the fields whose change requires the current map's monsters to be redone
local difficultyKeys = {"vars.Mode", "vars.insanityMode", "vars.madnessMode",
	"vars.AusterityMode", "vars.trueNightmare", "game.BolsterAmount", "game.freeProgression"}

local function copyFlat(t)
	local out = {}
	for k, v in pairs(t) do
		out[k] = v
	end
	return out
end

function Sync.snapshotGameState()
	local s = {vars = {}, game = {}}
	for _, k in ipairs(Sync.GameStateVars) do
		local v = vars[k]
		if type(v) == "table" then
			v = copyFlat(v)
		end
		s.vars[k] = v
	end
	for _, k in ipairs(Sync.GameStateGame) do
		s.game[k] = Game[k]
	end
	return s
end

function Sync.applyGameState(s)
	if type(s) ~= "table" then
		return
	end
	local sv, sg = s.vars or {}, s.game or {}
	for _, k in ipairs(Sync.GameStateVars) do
		local v = sv[k]
		if type(v) == "table" then
			if type(vars[k]) ~= "table" then
				vars[k] = {}
			end
			table.clear(vars[k])
			for a, b in pairs(v) do
				vars[k][a] = b
			end
		else
			vars[k] = v
		end
	end
	for _, k in ipairs(Sync.GameStateGame) do
		Game[k] = sg[k]
	end
end

-- canonical string of a value: sorted keys, so two equal states stamp equal
local function stamp(v)
	if type(v) ~= "table" then
		return tostring(v)
	end
	local keys = {}
	for k in pairs(v) do
		keys[#keys + 1] = k
	end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local out = {}
	for _, k in ipairs(keys) do
		out[#out + 1] = tostring(k) .. "=" .. stamp(v[k])
	end
	return "{" .. table.concat(out, ",") .. "}"
end

local function difficultyStamp(s)
	local parts = {}
	for _, path in ipairs(difficultyKeys) do
		local group, key = path:match("^(%a+)%.(.+)$")
		parts[#parts + 1] = tostring(s[group] and s[group][key])
	end
	return table.concat(parts, "|")
end

local lastStamp
local function broadcastGameState(force)
	if not Sync.isHost() or type(vars) ~= "table" or not vars.MMLVL then
		return
	end
	local s = Sync.snapshotGameState()
	local st = stamp(s)
	if not force and st == lastStamp then
		return
	end
	lastStamp = st
	Multiplayer.broadcast_questdata({DataType = "MawGameState", state = s}, "MawGameState")
end

function Sync.start()
	function events.MultiplayerInitialized()
		Multiplayer.allow_remote_event("MawGameState")
	end

	function events.GatherGameData(t)
		t.MawGameState = Sync.snapshotGameState()
	end

	function events.ProcessGameData(t)
		Sync.applyGameState(t.MawGameState)
	end

	function events.MawGameState(t)
		if not Sync.isClient() or type(vars) ~= "table" then
			return
		end
		local before = difficultyStamp(Sync.snapshotGameState())
		local buffReworkBefore = vars.MAWSETTINGS and vars.MAWSETTINGS.buffRework
		Sync.applyGameState(t.state)
		if difficultyStamp(Sync.snapshotGameState()) ~= before
				and type(recalculateMonsterTable) == "function"
				and type(recalculateMawMonster) == "function" then
			recalculateMonsterTable()
			recalculateMawMonster()
		end
		if vars.MAWSETTINGS and vars.MAWSETTINGS.buffRework ~= buffReworkBefore
				and type(adjustSpellTooltips) == "function" then
			adjustSpellTooltips()
		end
	end

	function events.ClientJoined()
		broadcastGameState(true)
	end

	MawCore.Scheduler.every("sync/gamestate", 2000, function() broadcastGameState(false) end)
end
