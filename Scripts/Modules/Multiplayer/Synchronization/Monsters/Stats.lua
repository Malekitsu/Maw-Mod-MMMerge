local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local item_to_bin, binstr_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.binstr_to_item
local nums_to_bin, fill_from_bin = Multiplayer.utils.nums_to_bin, Multiplayer.utils.fill_from_bin
local tkeys = Multiplayer.utils.tkeys
local mmt_dump = Multiplayer.utils.mmt_dump
local cond_same_map = Multiplayer.utils.cond_same_map
local num_to_hexstr = Multiplayer.utils.num_to_hexstr
local num_from_hexstr = Multiplayer.utils.num_from_hexstr
local distance = Multiplayer.utils.distance
local LogEvent = Multiplayer.utils.LogEvent

local info_from_clients = {}
local damaged_monsters = {}
local received_spellbuffs = {}

const.AIState.CastSpell = 13
const.AIState.RangedAttack3 = 13

local function DefMonAnimLength(mon, AIState)
	local FramesId = Multiplayer.utils.AIStateToFramesId[AIState]
	return FramesId and (Game.SFTBin[mon.Frames[FramesId]].TotalTime * 8) or 256
end

local function set_mon_action(mon, AIState, Step, Length)
	mon.AIState = AIState
	mon.CurrentActionLength = Length or DefMonAnimLength(mon, AIState)
	mon.CurrentActionStep = Step or 0
	mon:UpdateGraphicState()
end
Multiplayer.SyncMonsters.set_mon_action = set_mon_action

local bin_export, bin_import

bin_export = {
	monster_data_full = function(i, monster)
		return num_to_hexstr(i, 2) .. mmt_dump(monster)
	end,

	all_monsters = function()
		Multiplayer.hide_client_monsters()
		local monsters = {}
		for i, v in Map.Monsters do
			monsters[i] = bin_export.monster_data_full(i, v)
		end
		Multiplayer.unhide_client_monsters()
		return monsters
	end
}

bin_import = {
	monster_data_full = function(data)
		local i = u2[data]
		if i >= Map.Monsters.count then
			local old = Map.Monsters.count
			Map.Monsters.count = i + 1
			for monid = old, i do
				Map.Monsters[monid].AIState = const.AIState.Removed
			end
		end

		local mon = Map.Monsters[i]
		mcopy(mon["?ptr"], data + 2, mon["?size"])
		mon:SetId(mon.Id)
		mon:LoadFramesAndSounds()
	end,

	all_monsters = function(monsters)
		Map.Monsters.count = 0
		if monsters[0] then
			Map.Monsters.count = #monsters + 1
			bin_import.monster_data_full(toptr(monsters[0]))
			for i,v in ipairs(monsters) do
				bin_import.monster_data_full(toptr(v))
			end
		end
	end
}

local packets = {

	request_full_monster_data = {
		bulb = num_to_hexstr,
		handler = function(bin_string, metadata)
			local i = num_from_hexstr(bin_string)
			if i < Map.Monsters.count then
				return bin_export.monster_data_full(i, Map.Monsters[i])
			end
		end,
		response = 'send_full_monster_data',
		same_map_only = true
	},

	send_full_monster_data = {
		-- the copy carries the damage numbers it already contains; keep_hp
		-- copies everything but the HP, which only ever moves by damage deltas
		bulb = function(handler_data)
			local bin, keep_hp = handler_data, false
			if type(handler_data) == "table" then
				bin, keep_hp = handler_data.bin, handler_data.keep_hp == true
			end
			if not bin then
				return nil
			end
			return item_to_bin{bin, Multiplayer.SyncMonsters.damage_seq_snapshot(), keep_hp}
		end,
		handler = function(bin_string, metadata)
			local packet = binstr_to_item(bin_string)
			local bin, seqs, keep_hp = packet[1], packet[2], packet[3]
			local data = toptr(bin)
			local i = u2[data]
			local hp = keep_hp and i < Map.Monsters.count and Map.Monsters[i].HP or nil
			damaged_monsters[i] = nil
			received_spellbuffs[i] = nil
			bin_import.monster_data_full(data)
			if hp then
				Map.Monsters[i].HP = hp
			else
				Multiplayer.SyncMonsters.set_monster_damage_floor(i, seqs)
			end

			local client_monsters = Multiplayer.client_monsters()
			local client_id = table.find(client_monsters, i)
			if client_id then
				client_monsters[client_id] = nil
				local mon = Multiplayer.get_client_mon(client_id)
				if mon:GetIndex() == i then
					error("Client puppet and map monster collision.")
				end
			end
		end,
		same_map_only = true,
		compress = true
	},

	all_monsters = {
		bulb = function()
			return item_to_bin{monsters = bin_export.all_monsters(), seqs = Multiplayer.SyncMonsters.damage_seq_snapshot()}
		end,
		handler = function(bin_string, metadata)
			local t = binstr_to_item(bin_string)
			bin_import.all_monsters(t.monsters)
			Multiplayer.SyncMonsters.set_map_damage_floor(t.seqs)
		end,
		same_map_only = true,
		check_delivery = true,
		compress = true
	},

	spellbuffs = {
		bulb = function(received_spellbuffs)
			if not next(received_spellbuffs) then
				return nil
			end

			local result, tinsert = {}, table.insert
			for monid, spellbuffs in pairs(received_spellbuffs) do
				for buff_id, vals in pairs(spellbuffs) do
					tinsert(result, num_to_hexstr(monid, 2))
					tinsert(result, num_to_hexstr(buff_id, 1))
					tinsert(result, num_to_hexstr(vals.ExpireTime, 4))
					tinsert(result, num_to_hexstr(vals.Power, 1))
					tinsert(result, num_to_hexstr(vals.Skill, 1))
					--tinsert(result, num_to_hexstr(Multiplayer.posessed_by_player(monid) or 127, 1))
				end
			end

			return table.concat(result, '')
		end,
		handler = function(bin_string, metadata)
			if #bin_string == 0 then
				return
			end

			local ptr = toptr(bin_string)
			local buffed_mons = {}
			local moncount, monid, buffptr, buff = Map.Monsters.count, nil, nil, nil
			for i = 0, #bin_string - 9, 9 do
				buffptr = ptr + i
				monid = u2[buffptr]
				if monid < moncount then -- and u1[buffptr + 9] ~= Multiplayer.my_id
					buff = Map.Monsters[monid].SpellBuffs[u1[buffptr + 2]]
					buff.ExpireTime = u4[buffptr + 3]
					buff.Power = u1[buffptr + 7]
					buff.Skill = u1[buffptr + 8]
					buffed_mons[monid] = true
				end
			end

			for i, _ in pairs(buffed_mons) do
				Game.ShowMonsterBuffAnim(i)
			end
		end,
		check_delivery = true,
		same_map_only = true
	}
}
Multiplayer.utils.init_packets(packets)

Multiplayer.SyncMonsters.request_full_monster_data = function(mon_id, from_client)
	Multiplayer.add_to_send_queue(from_client, packets.request_full_monster_data:prep(mon_id))
end

Multiplayer.SyncMonsters.broadcast_full_monster_data = function(i)
	local data = packets.send_full_monster_data:prep(bin_export.monster_data_full(i, Map.Monsters[i]))
	Multiplayer.broadcast(data, Multiplayer.utils.cond_same_map)
end

Multiplayer.SyncMonsters.sync_all_monsters = function()
	Multiplayer.broadcast(packets.all_monsters:prep(), Multiplayer.utils.cond_same_map)
end

---- Map load

function events.MultiplayerPrepMapData(t)
	t.monsters = bin_export.all_monsters()
end

function events.MultiplayerProcessMapData(t)
	LogEvent("MAP_LOAD", "Processing monsters stats info: %s.", type(t.monsters))
	if t.monsters then
		bin_import.all_monsters(t.monsters)
	end
end

---- Handlers

-- Buffs / debuffs

local function send_full_mon_data(i)
	local data = packets.send_full_monster_data:prep({bin = bin_export.monster_data_full(i, Map.Monsters[i]), keep_hp = true})
	Multiplayer.broadcast(data, cond_same_map)
end

function events.PlayerCastSpell(t)
	if t.TargetKind == 3 and not Multiplayer.posessed_by_player(t.TargetId) then
		Multiplayer.utils.delayed_call(send_full_mon_data, 2, t.TargetId)
	end
end

local function queue_spellbuff(mon_index, buff_id, skill, power, expire_time)
	local spellbuffs = received_spellbuffs[mon_index]
	if not spellbuffs then
		spellbuffs = {}
		received_spellbuffs[mon_index] = spellbuffs
	end
	spellbuffs[buff_id] = {Skill = skill, Power = power, ExpireTime = expire_time}
end

function events.MonsterReceiveSpellBuff(t)
	if Multiplayer.posessed_by_player(t.MonsterIndex) then
		t.Handled = true
		return
	end
	queue_spellbuff(t.MonsterIndex, t.SpellBuff, t.Skill, t.Power, t.ExpireTime)
end

-- for buffs written into the monster struct by scripts, past the engine routine
Multiplayer.SyncMonsters.notify_spellbuff = function(mon_index, buff_id)
	if mon_index >= Map.Monsters.count or Multiplayer.posessed_by_player(mon_index) then
		return
	end
	local buff = Map.Monsters[mon_index].SpellBuffs[buff_id]
	queue_spellbuff(mon_index, buff_id, buff.Skill, buff.Power, buff.ExpireTime)
end

function events.Tick()
	if Multiplayer.leave_map_halt then
		return
	end

	Multiplayer.broadcast(packets.spellbuffs:prep(received_spellbuffs), cond_same_map)
	received_spellbuffs = {}
end
