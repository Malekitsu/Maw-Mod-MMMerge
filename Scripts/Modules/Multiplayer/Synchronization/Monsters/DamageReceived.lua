local events = Multiplayer.events
local item_to_bin, binstr_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.binstr_to_item
local cond_same_map = Multiplayer.utils.cond_same_map

local damaged_monsters = {}
local HP_FLOOR = -32000

-- Damage travels as deltas: every sender numbers its packets per map, every
-- receiver remembers which numbers it applied. A snapshot of monster HP (map
-- data, a full monster copy) carries those numbers, so a delta the snapshot
-- already holds is dropped when it arrives later instead of counting twice.
local seq = 0
local applied = {}	-- sender -> {c = contiguous top, ahead = {seq = true}}
local map_floor = {}	-- sender -> numbers the current map data contained
local mon_floor = {}	-- monster index -> sender -> numbers a full copy contained

local function applied_state(sender)
	local st = applied[sender]
	if not st then
		st = {c = 0, ahead = {}}
		applied[sender] = st
	end
	return st
end

local function is_applied(st, s)
	return s <= st.c or st.ahead[s] == true
end

local function mark_applied(st, s)
	if s == st.c + 1 then
		st.c = s
		while st.ahead[st.c + 1] do
			st.ahead[st.c + 1] = nil
			st.c = st.c + 1
		end
	elseif s > st.c then
		st.ahead[s] = true
	end
end

local function contains(floor, s)
	if not floor then
		return false
	end
	if s <= (floor.c or 0) then
		return true
	end
	return floor.ahead ~= nil and table.find(floor.ahead, s) ~= nil
end

local function seq_snapshot()
	local t = {}
	for sender, st in pairs(applied) do
		local ahead = {}
		for s in pairs(st.ahead) do
			ahead[#ahead + 1] = s
		end
		t[sender] = {c = st.c, ahead = ahead}
	end
	t[Multiplayer.my_id] = {c = seq, ahead = {}}
	return t
end

local function set_map_floor(seqs)
	map_floor = type(seqs) == "table" and seqs or {}
	mon_floor = {}
end

local function set_monster_floor(i, seqs)
	if type(seqs) == "table" then
		mon_floor[i] = seqs
	end
end

local function forget_sender(sender)
	applied[sender] = nil
	map_floor[sender] = nil
	for _, floors in pairs(mon_floor) do
		floors[sender] = nil
	end
end

Multiplayer.SyncMonsters.damage_seq_snapshot = seq_snapshot
Multiplayer.SyncMonsters.set_map_damage_floor = set_map_floor
Multiplayer.SyncMonsters.set_monster_damage_floor = set_monster_floor

local packets = {
	monsters_health = {
		bulb = function(damage_done)
			for mon_id, damage in pairs(damage_done) do
				damage_done[mon_id] = {damage, Map.Monsters[mon_id].HP}
			end
			seq = seq + 1
			return item_to_bin({s = seq, m = damage_done})
		end,
		handler = function(bin_string, metadata)
			local packet = binstr_to_item(bin_string)
			local sender, s = metadata.sender_id, packet.s
			local st = applied_state(sender)
			if is_applied(st, s) then
				return
			end
			mark_applied(st, s)

			local t = packet.m
			for _, monid in pairs(Multiplayer.client_monsters()) do
				t[monid] = nil
			end

			-- damage is a delta, so two players hitting at once both count;
			-- a kill is absolute, so the corpse exists everywhere
			for i, v in pairs(t) do
				if i < Map.Monsters.count
						and not contains(map_floor[sender], s)
						and not contains(mon_floor[i] and mon_floor[i][sender], s) then
					local mon = Map.Monsters[i]
					local dmg, hp = v[1], v[2]
					if mon.HP > 0 then
						mon.HP = math.max(mon.HP - dmg, HP_FLOOR)
					end
					if hp <= 0 and mon.HP > 0 then
						mon.HP = hp
					end

					if dmg > 0 then
						events.Call("RemoteDamageToMonster", mon, i, dmg)
					end
				end
			end
		end,
		same_map_only = true,
		check_delivery = true,
		compress = true
	}
}
Multiplayer.utils.init_packets(packets)

function events.MawMonsterDamage(t)
	local need_send = t.ByPlayer
	if not t.ByPlayer then
		local source = t.Hit
		if source and source.Monster then
			need_send = Multiplayer.SyncMonsters.monster_owner(source.MonsterIndex) == Multiplayer.my_id
		end
	end

	if need_send then
		damaged_monsters[t.MonsterIndex] = (damaged_monsters[t.MonsterIndex] or 0) + t.Result
	end
end

function events.MultiplayerPrepMapData(t)
	t.DamageSeq = seq_snapshot()
end

function events.MultiplayerProcessMapData(t)
	set_map_floor(t.DamageSeq)
end

function events.LeaveMap()
	damaged_monsters = {}
	seq = 0
	map_floor = {}
	mon_floor = {}
end

function events.MultiplayerStarted()
	damaged_monsters = {}
	seq = 0
	applied = {}
	map_floor = {}
	mon_floor = {}
end

function events.ClientChangeMap(client_id)
	forget_sender(client_id)
end

function events.ClientLeft(client_id)
	forget_sender(client_id)
end

function events.ClientJoined(client)
	forget_sender(client.id)
end

local function send_damage()
	if Multiplayer.leave_map_halt then
		return
	end

	if next(damaged_monsters) then
		-- handled by SyncPlayers
		for _, monid in pairs(Multiplayer.client_monsters()) do
			damaged_monsters[monid] = nil
		end

		for k, v in pairs(damaged_monsters) do
			if k >= Map.Monsters.count then
				damaged_monsters[k] = nil
			end
		end

		Multiplayer.broadcast(packets.monsters_health:prep(damaged_monsters), cond_same_map)
		damaged_monsters = {}
	end
end
Multiplayer.utils.TickCounter(send_damage, 4)
