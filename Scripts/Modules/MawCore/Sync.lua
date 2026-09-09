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

-- the one player who owns the current map's spawning (true when alone or offline)
function Sync.isMainOnMap()
	return not Sync.inGame() or Multiplayer.main_player_on_map() == Multiplayer.my_id
end

-- whether this client's engine runs the monster's AI: moves, pushes and
-- nudges belong to that client only (true when alone or offline)
function Sync.drivesMonster(index)
	if not Sync.inGame() or type(index) ~= "number" then
		return true
	end
	local owner = Multiplayer.SyncMonsters.monster_owner(index)
	return owner == Multiplayer.my_id or owner == -1
end

-- a debuff written straight into a monster's SpellBuffs bypasses the engine
-- routine the module hooks: tell the module ourselves so the others get it
function Sync.monsterBuffChanged(index, buff)
	if Sync.inGame() and type(index) == "number" and Multiplayer.SyncMonsters.notify_spellbuff then
		Multiplayer.SyncMonsters.notify_spellbuff(index, buff)
	end
end

-- Host-owned game state. vars keys are mirrored verbatim (tables replaced
-- content-wise, so references held by other files stay valid); Game fields
-- likewise. Add a key here and nowhere else.
Sync.GameStateVars = {
	"Mode", "insanityMode", "madnessMode", "AusterityMode", "trueNightmare",
	"freeProgression", "MAWSETTINGS", "MMLVL", "EXPBEFORE", "LVLBEFORE",
	"RandomizerMode", "RandomizerFixed", "Randomizer", "OriginalItemOrder", "ItemFound", "MonsterShuffleList",
}
Sync.GameStateGame = {"Mode", "BolsterAmount", "freeProgression"}

-- host-owned lists that clients also grow: a client's additions are sent up
-- and merged by the host, then come back with the next state
Sync.MergeUpLists = {"ItemFound"}

-- per-party state that travels with the party data the base module keeps for
-- every client (the host's save copy, the client save, the client autosave).
-- Add a key here and nowhere else.
Sync.PartyVars = {
	"mawbags", "CraftingBags", "alchemyPlayer", "inventoryLocked", "SmallerPotionBottles",
	"currentHPPool", "maxHPPool", "currentManaPool", "maxManaPool",
	"mawbuff", "mawbuff_remote", "maw_remote_owners", "maw_remote_values", "_maw_local_off", "maw_special_expire",
	"mawPotionBuff", "mawPotionBuffPower", "PlayerAlchemyBuffs", "BlackPotions", "poisonTime", "bonusMeditation",
	"horizontaSpells", "magicResistancePotionExpire", "buffToIgnore", "mawTranscendence", "PotionBuffs", "enchantSeedList",
	"legendaries", "elementalistSpells", "elementalistSpellBinds", "eleStacks", "eleTimer", "disableRotation",
	"dkActiveAttackSpell", "assassinDamage", "assassinStacks", "AttackSpeedStack", "AttackSpeedStackDecay",
	"oldPlayerMasteries", "storedMasteries", "soloMiscMasteries", "trainings", "weaponSkillRefunded", "UncappedSkills",
	"learningFix", "removeSoloMastery", "checkSoloMastery", "BBFIX", "needToFixCover", "needToFixMaxCharges",
	"StartingItemFix", "hirelingFix", "LichFix", "dragonMeditationRemoved",
	"damageTrack", "damageTrackRanged", "healingDone", "leechDone", "regenerationHeal", "manaShield", "shieldEnchant",
	"normalEnchantResistance", "spearDamageIncrease", "retaliation", "covering",
	"divineProtectionCooldown", "legendaryProtectionCooldown", "healthPotionCooldown", "manaPotionCooldown", "chargeCooldown",
	"artifactRollPity", "artPity", "craftPityCounters", "legendaryAffixDropped", "monsterCounters", "monsterSeeds", "SeedList", "seed",
	"ownedMaps", "introduction", "refundFood",
	"MawCore",
}

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

-- the client side: the last state the host sent is the truth; local drift
-- (a menu closed on the client, a script touching a synced key) is pulled
-- back to it on the next check
local lastReceived

local function applyReceived(s)
	local before = difficultyStamp(Sync.snapshotGameState())
	local buffReworkBefore = vars.MAWSETTINGS and vars.MAWSETTINGS.buffRework
	Sync.applyGameState(s)
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

local function sendMergeUp()
	local lists
	local received = lastReceived.vars or {}
	for _, k in ipairs(Sync.MergeUpLists) do
		local mine, theirs = vars[k], received[k]
		if type(mine) == "table" then
			local extra = {}
			for _, v in ipairs(mine) do
				if not (type(theirs) == "table" and table.find(theirs, v)) then
					extra[#extra + 1] = v
				end
			end
			if #extra > 0 then
				lists = lists or {}
				lists[k] = extra
			end
		end
	end
	if lists then
		Multiplayer.broadcast_questdata({DataType = "MawStateMerge", lists = lists}, "MawStateMerge")
	end
end

local function converge()
	if not Sync.isClient() or not lastReceived or type(vars) ~= "table" or not vars.MMLVL then
		return
	end
	if stamp(Sync.snapshotGameState()) ~= stamp(lastReceived) then
		sendMergeUp()
		applyReceived(lastReceived)
	end
end

local function mergeUp(lists)
	if type(lists) ~= "table" then
		return
	end
	for _, k in ipairs(Sync.MergeUpLists) do
		local items = lists[k]
		if type(items) == "table" then
			if type(vars[k]) ~= "table" then
				vars[k] = {}
			end
			for _, v in ipairs(items) do
				if not table.find(vars[k], v) then
					table.insert(vars[k], v)
				end
			end
		end
	end
end

function Sync.gatherPartyVars(t)
	local out = {}
	for _, k in ipairs(Sync.PartyVars) do
		local v = vars[k]
		if type(v) == "table" then
			v = copyFlat(v)
		end
		out[k] = v
	end
	t.MawPartyVars = out
end

function Sync.applyPartyVars(t)
	local data = t.MawPartyVars
	if type(data) ~= "table" then
		return
	end
	for _, k in ipairs(Sync.PartyVars) do
		local v = data[k]
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
end

function Sync.start()
	function events.MultiplayerInitialized()
		Multiplayer.allow_remote_event("MawGameState")
		Multiplayer.allow_remote_event("MawStateMerge")
	end

	function events.MawStateMerge(t)
		if Sync.isHost() and type(vars) == "table" then
			mergeUp(t.lists)
		end
	end

	function events.GatherPartySaveData(t)
		Sync.gatherPartyVars(t)
	end

	function events.ProcessPartySaveData(t)
		Sync.applyPartyVars(t)
	end

	function events.GatherGameData(t)
		t.MawGameState = Sync.snapshotGameState()
	end

	function events.ProcessGameData(t)
		lastReceived = t.MawGameState
		Sync.applyGameState(t.MawGameState)
	end

	function events.MawGameState(t)
		if not Sync.isClient() or type(vars) ~= "table" then
			return
		end
		lastReceived = t.state
		applyReceived(t.state)
	end

	function events.ClientJoined()
		broadcastGameState(true)
	end

	function events.MultiplayerStopped()
		lastReceived = nil
	end

	MawCore.Scheduler.every("sync/gamestate", 2000, function()
		broadcastGameState(false)
		converge()
	end)
end
