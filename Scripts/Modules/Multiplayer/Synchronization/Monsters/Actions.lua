local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local cond_same_map = Multiplayer.utils.cond_same_map
local distance = Multiplayer.utils.distance
local nums_to_bin = Multiplayer.utils.nums_to_bin
local fill_from_bin = Multiplayer.utils.fill_from_bin
local LogEvent = Multiplayer.utils.LogEvent

local FREE, APPROVE, DEMAND = 0, 1, 2
local waiting_for_send = {}
local monsters_under_control = Multiplayer.SyncMonsters.monsters_under_control

local SyncPlayers = Multiplayer.require("Synchronization/Players.lua")
local SyncMonsters = Multiplayer.SyncMonsters

Multiplayer.debug.monsters_under_control = function()
	return monsters_under_control
end

SyncMonsters.monsters_under_control = function()
	local t = {}
	for i = 0, Map.Monsters.count - 1 do
		if monsters_under_control[i] == Multiplayer.my_id then
			table.insert(t, i)
		end
	end
	return t
end

local function monster_owner(i)
	return monsters_under_control[i]
end
SyncMonsters.monster_owner = monster_owner

local function set_control(i, owner, reason)
	if i >= Map.Monsters.count then
		LogEvent("MONSTERS", "Invalid monster index, when taking control: " .. reason)
	end
	monsters_under_control[i] = owner
end

local takeover_aistates = {
	[const.AIState.MeleeAttack] = true,
	[const.AIState.Pursue] = true,
	[const.AIState.Interact] = true,
	[const.AIState.Flee] = true,
	[const.AIState.Invisible] = true,
}

local bin_fields = {
	monster_action = {"Hostile", "AIState", "Id", "CurrentActionStep", "CurrentActionLength", "GraphicState", "Direction", "LookAngle", "X", "Y", "Z", "Ally", "MoveSpeed", "FullHP"}
}

-- each sender numbers its action broadcasts; a packet older than the last one
-- applied from that sender is dropped, so reordering cannot roll a monster back
local action_seq = 0
local last_seq = {} -- sender client id -> last applied sequence

local packets
packets = {
	monster_action = {
		bulb = function(monsters)
			local t = {}
			local source
			local mon_count = Map.Monsters.count
			for _, monIndex in pairs(monsters) do
				if monIndex < mon_count then
					local mon = Map.Monsters[monIndex]
					if mon.AIState == const.AIState.RangedAttack
						or mon.AIState == const.AIState.RangedAttack2
						or mon.AIState == const.AIState.RangedAttack3
						or mon.AIState == const.AIState.RangedAttack4 then

						local oldAIState = mon.AIState
						mon.AIState = const.AIState.MeleeAttack -- avoid projectiles duplication, handled by SyncObjects
						t[monIndex] = nums_to_bin(mon, bin_fields.monster_action, 2)
						mon.AIState = oldAIState
					else
						t[monIndex] = nums_to_bin(mon, bin_fields.monster_action, 2)
					end
				end
			end
			action_seq = action_seq + 1
			return Multiplayer.utils.item_to_bin({s = action_seq, m = t})
		end,
		handler = function(bin_string, metadata)
			local packet = Multiplayer.utils.bin_to_item(toptr(bin_string))
			local last = last_seq[metadata.sender_id]
			if last and packet.s <= last then
				LogEvent("MONSTERS", "Dropped monster actions #%s from #%s, already at #%s.", packet.s, metadata.sender_id, last)
				return
			end
			last_seq[metadata.sender_id] = packet.s

			local monsters = packet.m
			local mon_count = Map.Monsters.count
			local AIState
			for monIndex, bin_info in pairs(monsters) do
				if monIndex >= mon_count then
					SyncMonsters.request_full_monster_data(monIndex, metadata.sender_id)
				else
					AIState = Multiplayer.utils.fetch_field_bin("AIState", toptr(bin_info), bin_fields.monster_action, 2)

					local mon = Map.Monsters[monIndex]
					local old_id = mon.Id
					local was_full_hp = mon.HP == mon.FullHP
					local dying_state = AIState == const.AIState.Dead or AIState == const.AIState.Dying

					if mon.HP <= 0 and not dying_state or mon.HP > 0 and dying_state then
						SyncMonsters.request_full_monster_data(monIndex, metadata.sender_id)
						return
					end

					fill_from_bin(mon, toptr(bin_info), bin_fields.monster_action, 2, true)
					mon.Hostile = Multiplayer.utils.fetch_field_bin("Hostile", toptr(bin_info), bin_fields.monster_action, 2) == 1

					if was_full_hp then
						mon.HP = mon.FullHP
					end

					if old_id ~= mon.Id then
						mon.Id = old_id
						mon.AIState = const.AIState.Removed
						SyncMonsters.request_full_monster_data(monIndex, metadata.sender_id)
					else
						mon.Velocity = mon.MoveSpeed
						Multiplayer.utils.play_mon_sound(mon)
						monsters_under_control[monIndex] = metadata.sender_id
					end
				end
			end
		end,
		same_map_only = true,
		compress = true
	},

	share_experience = {
		bulb = function(amount)
			return Multiplayer.utils.num_to_hexstr(amount, 4)
		end,
		handler = function(bin_string, metadata)
			local amount = i4[toptr(bin_string)]
			Party:AddKillExp(amount)
		end,
		check_delivery = true,
		same_map_only = true
	},

	blood_splat = {
		bulb = function(mon)
			local t = {mon.X, mon.Y, mon.Z}
			return Multiplayer.utils.item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			local t = Multiplayer.utils.binstr_to_item(bin_string)
			CreateBloodSplat(t[1], t[2], t[3])
		end,
		same_map_only = true,
		compress = true
	}
}
Multiplayer.utils.init_packets(packets)

function events.ClientLeft(client_id)
	last_seq[client_id] = nil
end

function events.ClientJoined(client)
	last_seq[client.id] = nil
end

function events.MultiplayerStarted()
	action_seq = 0
	table.clear(last_seq)
end

------------------------------------
-- Actions handler

local function broadcast_mon_actions()
	if Multiplayer.leave_map_halt or not next(waiting_for_send) then
		return
	end

	local main_player = Multiplayer.main_player_on_map()
	local broadcast = {}

	local t = {allow = true, Monster = nil, MonsterIndex = nil, OldAIState = nil}
	for monIndex, behaivor in pairs(waiting_for_send) do
		if behaivor == DEMAND then
			t.allow = true
			t.Monster = Map.Monsters[monIndex]
			t.MonsterIndex = monIndex
			events.call("BroadcastingMonsterAction", t)
			if t.allow then
				table.insert(broadcast, monIndex)
			end
		end
	end

	if next(broadcast) then
		Multiplayer.broadcast(packets.monster_action:prep(broadcast), cond_same_map)
	end

	table.clear(waiting_for_send)
end
Multiplayer.utils.TickCounter(broadcast_mon_actions, 4)

-- triggers only on changes by mm engine
function events.MonsterChooseAIState(t)
	if Multiplayer.leave_map_halt then
		return
	end

	if t.MonsterIndex >= Map.Monsters.count then
		LogEvent("MONSTERS", "Invalid MonsterIndex in MonsterChooseAIState event (%s, monsters count: %s).", t.MonsterIndex, Map.Monsters.count)
		return
	end

	local is_player = SyncPlayers.posessed_by_player(t.MonsterIndex)

	if not t.allow then
		-- forbidden by previous handlers
	elseif is_player then
		t.allow = false
	elseif Game.TurnBased and Game.TurnBasedPhase > 1 and not takeover_aistates[t.ai_state] then
		t.allow = true
		waiting_for_send[t.MonsterIndex] = DEMAND
	elseif monsters_under_control[t.MonsterIndex] == Multiplayer.my_id then
		waiting_for_send[t.MonsterIndex] = DEMAND
	elseif t.Monster.HP <= 0 and (t.ai_state == const.AIState.Dead or t.ai_state == const.AIState.Dying) then
		t.allow = true
	elseif not Game.TurnBased and takeover_aistates[t.ai_state] or t.ai_state == const.AIState.MeleeAttack then
		local kind, id = GetMonsterTarget(t.MonsterIndex)
		t.allow = kind == 4 and distance(Party, t.Monster) < 512
		if t.allow then
			set_control(t.MonsterIndex, Multiplayer.my_id, "taking over control of monster with apropriate action")
			waiting_for_send[t.MonsterIndex] = DEMAND
		end
	else
		t.allow = false
	end

	if not t.allow and t.Monster.CurrentActionStep >= t.Monster.CurrentActionLength and not is_player then
		SyncMonsters.set_mon_action(t.Monster, const.AIState.Stand, 0, 256)
	end
end

-- triggers only on changes by mm engine
function events.MonsterActionChanged(MonsterIndex, Monster, OldAction)
	if Multiplayer.leave_map_halt then
		return
	end

	if Game.TurnBased or SyncPlayers.posessed_by_player(MonsterIndex) then
		return
	end

	if monsters_under_control[MonsterIndex] == Multiplayer.my_id then
		waiting_for_send[MonsterIndex] = DEMAND
	elseif not Monster.ShowAsHostile and Monster.AIState == 1 then
		for k, v in pairs(OldAction) do
			Monster[k] = v
		end
		if Monster.CurrentActionStep >= Monster.CurrentActionLength then
			SyncMonsters.set_mon_action(Monster, const.AIState.Stand, 0, 256)
		end
	end
end

function events.MonsterCanCastSpell(t)
	if monsters_under_control[t.MonsterIndex] ~= Multiplayer.my_id then
		t.Result = false
	end
end

function events.MonsterNeedPathfinding(t)
	if monsters_under_control[t.MonsterIndex] ~= Multiplayer.my_id then
		t.Result = false
	end
end

------------------------------------
-- Speak with monster handler

local monster_interlocutor_id = nil
local hold_monster_timer
local hold_monster_timer_set = false
local iter_count = 0

hold_monster_timer = function()
	iter_count = iter_count + 1
	LogEvent("MONSTERS", "Monster interaction iteration %s", tostring(iter_count))

	if not monster_interlocutor_id then
		LogEvent("MONSTERS", "monster_interlocutor_id variable is nil, stopping  monster interaction timer.")
		hold_monster_timer_set = false
		if Game.CurrentScreen == const.Screens.NPC or Game.CurrentScreen == const.Screens.SimpleMessage then
			ExitCurrentScreen()
		end
	elseif Game.CurrentScreen == const.Screens.NPC or Game.CurrentScreen == const.Screens.SimpleMessage then
		local mon = Map.Monsters[monster_interlocutor_id]
		if mon.AIState ~= const.AIState.Interact then
			LogEvent("MONSTERS", "monster interlocutor has changed its AIState, stopping  monster interaction timer.")
			monster_interlocutor_id = nil
			hold_monster_timer_set = false
			ExitCurrentScreen()
			return
		end

		LogEvent("MONSTERS", "Holding monster interlocutor.")
		mon.CurrentActionLength = 256
		mon.CurrentActionStep = 0
		waiting_for_send[monster_interlocutor_id] = DEMAND
	else
		LogEvent("MONSTERS", "Current screen is not NPC interaction anymore, stopping  monster interaction timer.")
		monster_interlocutor_id = nil
		hold_monster_timer_set = false
	end

	if hold_monster_timer_set then
		Multiplayer.utils.delayed_call(hold_monster_timer, 16)
	end
end

function events.SpeakWithMonster(t)
	LogEvent("MONSTERS", "SpeakWithMonster event trigerred, hold_monster_timer_set variable is %s", tostring(hold_monster_timer_set))
	monster_interlocutor_id = t.MonsterIndex
	if not hold_monster_timer_set then
		LogEvent("MONSTERS", "Setting monster interaction timer.")
		iter_count = 0
		hold_monster_timer_set = true
		Multiplayer.utils.delayed_call(hold_monster_timer, 16)
	end
end

------------------------------------
-- Prevent monster drop duplication

function events.MonsterDropItem(t)
	local owner = monster_owner(t.MonsterIndex)
	local Allow = owner == Multiplayer.my_id or (owner == -1 and Multiplayer.my_id == Multiplayer.main_player_on_map())
	if not Allow then
		t.Handled = true
	end
end

------------------------------------
-- Blood splats

function events.BloodSplatCreated(Monster, MonsterIndex)
	Multiplayer.broadcast(packets.blood_splat:prep(Monster), cond_same_map)
end

local BloodSplatFields = {"X","Y","Z"}

function events.MultiplayerPrepMapData(t)
	local splats = {}
	for i,v in Map.BloodSplats do
		splats[i] = nums_to_bin(v, BloodSplatFields, 2)
	end
	t.BloodSplats = splats

	LogEvent("MAP_LOAD", "Blood splats exported: %s.", #t.BloodSplats)
end

function events.MultiplayerProcessMapData(t, actual)
	-- 'actual' is true, if data came from player currently at map
	-- otherwise do not use blood splats, as they get erased on map reenter originally
	if not actual or not t.BloodSplats then
		return
	end

	LogEvent("MAP_LOAD", "Processing blood splats info: %s, %s.", type(t.BloodSplats), (type(t.BloodSplats) == 'table' and #t.BloodSplats or 0))

	Map.BloodSplatsCount = 0
	Map.BloodSplatsCreated = 0

	local p = {X = 0, Y = 0, Z = 0}
	for i,v in pairs(t.BloodSplats) do
		fill_from_bin(p, toptr(v), BloodSplatFields, 2, true)
		CreateBloodSplat(p.X, p.Y, p.Z)
	end
end
