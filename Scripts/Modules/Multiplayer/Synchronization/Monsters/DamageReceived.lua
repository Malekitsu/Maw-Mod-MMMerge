local events = Multiplayer.events
local item_to_bin, binstr_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.binstr_to_item
local cond_same_map = Multiplayer.utils.cond_same_map

local damaged_monsters = {}
local HP_FLOOR = -32000

local packets = {
	monsters_health = {
		bulb = function(damage_done)
			for mon_id, damage in pairs(damage_done) do
				damage_done[mon_id] = {damage, Map.Monsters[mon_id].HP}
			end
			return item_to_bin(damage_done)
		end,
		handler = function(bin_string, metadata)
			local t = binstr_to_item(bin_string)
			for _, monid in pairs(Multiplayer.client_monsters()) do
				t[monid] = nil
			end

			-- damage is a delta, so two players hitting at once both count;
			-- a kill is absolute, so the corpse exists everywhere
			for i, v in pairs(t) do
				if i < Map.Monsters.count then
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

function events.LeaveMap()
	damaged_monsters = {}
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
