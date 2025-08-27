local takeover_aistates = {
	[const.AIState.MeleeAttack] = true,
	--[const.AIState.Pursue] = true,
	[const.AIState.Interact] = true,
	[const.AIState.Invisible] = true,
}

local events = Multiplayer.events
local LogEvent = Multiplayer.utils.LogEvent

local ALLOWED_CHANGE_FREQUENCY = 4000 -- milliseconds
local TAKEN = 1
local FREED = 0

local LastChanges = {}

local Ownership = {}
local function InitOwnership()
	for i = 0, Map.Monsters.limit do
		Ownership[i] = {Owner = -1, LastChange = 0}
	end
end
local function ResetOwnership()
	for i, v in pairs(Ownership) do
		v.Owner = -1
		v.LastChange = 0
	end
end
function Multiplayer.debug.MonsterOwnership()
	return Ownership
end
events.MultiplayerStarted = InitOwnership
events.MapLoadingDone = ResetOwnership

local packets = {
	notify_ownership_changes = {
		bulb = function(changes)
			return Multiplayer.utils.item_to_bin(changes)
		end,
		handler = function(bin_string, metadata)
			local changes = Multiplayer.utils.binstr_to_item(bin_string)
			local timestamp = timeGetTime()
			for mon_id, act in pairs(changes) do
				local own = Ownership[mon_id]
				if act == TAKEN then
					own.Owner = metadata.sender_id
					own.LastChange = timestamp
				elseif own.Owner == metadata.sender_id then
					own.Owner = -1
				end
			end
		end,
		same_map_only = true,
		compress = true
	},

	notify_ownership = {
		bulb = function()
			local t = {}
			for i, v in pairs(Ownership) do
				if v.Owner == Multiplayer.my_id then
					table.insert(t, i)
				end
			end
			return Multiplayer.utils.num_array_to_bin(t, 2)
		end,
		handler = function(bin_string, metadata)
			local t = Multiplayer.utils.bin_to_num_array(bin_string, 2)
			for i = 0, Map.Monsters.count - 1 do
				if Ownership[i].Owner == metadata.sender_id then
					Ownership[i].Owner = -1
				end
			end
			for _, i in pairs(t) do
				Ownership[i].Owner = metadata.sender_id
			end
		end,
		same_map_only = true
	},
}
Multiplayer.utils.init_packets(packets)

local function can_takeover_monster(i, mon, timestamp, attacked)
	if not mon.Active or Game.Paused then
		return false
	end

	local own = Ownership[i]
	if own.Owner == -1 or own.Owner == Multiplayer.my_id then
		return true
	end

	if takeover_aistates[mon.AIState] or mon.AIState == const.AIState.Flee and not mon.Hostile then
		local kind, id = GetMonsterTarget(i)
		if kind == 4 then
			return true
		end
	end

	if attacked then
		local dist = Multiplayer.utils.distance
		local owner_mon = Multiplayer.get_client_mon(own.Owner)
		if owner_mon and dist(owner_mon, mon) - dist(Party, mon) > 1600 then
			return true
		end
	end

	if timestamp - own.LastChange < ALLOWED_CHANGE_FREQUENCY then
		return false
	end

	return true
end

local function pick_monsters()
	local my_id = Multiplayer.my_id
	local timestamp = timeGetTime()

	for i, mon in Map.Monsters do
		local taken = can_takeover_monster(i, mon, timestamp)
		local own = Ownership[i]
		if taken then
			if own.Owner ~= my_id then
				LastChanges[i] = TAKEN
				own.Owner = my_id
				own.LastChange = timestamp
			end
		else
			if own.Owner == my_id then
				LastChanges[i] = FREED
				own.Owner = -1
			end
		end
	end
end

local function try_takeover(i, mon, attacked)
	local timestamp = timeGetTime()
	if can_takeover_monster(i, mon, timestamp, attacked) then
		local own = Ownership[i]
		own.Owner = Multiplayer.my_id
		own.LastChange = timestamp
		LastChanges[i] = TAKEN
	end
end

local function broadcast_changes()
	if next(LastChanges) then
		Multiplayer.broadcast(packets.notify_ownership_changes:prep(LastChanges), Multiplayer.utils.cond_same_map)
		table.clear(LastChanges)
	end
end

function events.MonsterChooseAIState(t)
	if t.MonsterIndex >= Map.Monsters.count then
		LogEvent("MONSTERS", "Invalid MonsterIndex in MonsterChooseAIState event (%s, monsters count: %s).", t.MonsterIndex, Map.Monsters.count)
		t.allow = false
		return
	end

	if Multiplayer.posessed_by_player(t.MonsterIndex) then
		t.allow = false
		return
	end
end

function events.MonsterAttacked(t)
	if t.Attacker.Player then
		try_takeover(t.MonsterIndex, t.Monster, true)
	end
end

function events.MonsterChooseAIState(t)
	if not t.allow then
		return
	end
	
	if t.MonsterIndex >= Map.Monsters.count then
		LogEvent("MONSTERS", "Invalid MonsterIndex in MonsterChooseAIState event (%s, monsters count: %s).", t.MonsterIndex, Map.Monsters.count)
	end

	local i, mon = t.MonsterIndex, t.Monster
	if not mon then return end
	local old = mon.AIState
	mon.AIState = t.ai_state
	try_takeover(i, mon)
	mon.AIState = old
end

function events.MonsterActionChanged(MonsterIndex, Monster, OldAction)
	try_takeover(MonsterIndex, Monster)
end

Multiplayer.utils.TickCounter(pick_monsters, 64)
Multiplayer.utils.TickCounter(broadcast_changes, 4)
Multiplayer.utils.MillisecCounter(function()
	Multiplayer.broadcast(packets.notify_ownership:prep(), Multiplayer.utils.cond_same_map)
end, ALLOWED_CHANGE_FREQUENCY)

----

local monsters_under_control = {}
setmetatable(monsters_under_control, {
	__newindex = function(t, key, val)
		local old = Ownership[key].Owner
		Ownership[key].LastChange = timeGetTime()
		if old ~= val then
			Ownership[key].Owner = val
			if val == Multiplayer.my_id then
				LastChanges[key] = TAKEN
			elseif val == -1 then
				LastChanges[key] = FREED
			end
		end
	end,
	__index = function(t, key)
		return Ownership[key].Owner
	end
})

Multiplayer.SyncMonsters.monsters_under_control = monsters_under_control

Multiplayer.debug.MonOwnership = Ownership
