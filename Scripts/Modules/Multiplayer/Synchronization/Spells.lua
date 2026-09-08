local events = Multiplayer.events
local u1, u2, u4, r4, i2, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i2, mem.i4, mem.string, mem.copy, mem.topointer
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
local sqrt, abs, floor, ceil, rad, deg = math.sqrt, math.abs, math.floor, math.ceil, math.rad, math.deg
local max, asin = math.max, math.asin
local sendbuff = Multiplayer.utils.sendbuff
local mon_index_from_ptr = Multiplayer.utils.mon_index_from_ptr
local cond_same_map = Multiplayer.utils.cond_same_map
local spell_initsound = Multiplayer.utils.spell_initsound
local distance = Multiplayer.utils.distance
local LogEvent = Multiplayer.utils.LogEvent
local SpellSchoolColorsRGB24 = Multiplayer.utils.SpellSchoolColorsRGB24

local SyncPlayers = Multiplayer.require("Synchronization/Players.lua")
local RemoteSpellsData = {}

Multiplayer.SERVICE_CASTER = 49
Multiplayer.SHARE_BUFF_RANGE = 1400
Multiplayer.SHARE_AURA_RANGE = 3000

local function color24_by_spell(spell_id)
	local school = Multiplayer.utils.school_by_spell(spell_id)
	return SpellSchoolColorsRGB24[school] or 0
end

local function std_can_process_cond(spell_info, t)
	return t.allow or (t.target_ref ~= 0)
end

local function set_spell_recovery_delay(Player, Spell, Mastery)
	if Game.TurnBased then
		-- tmp. t.Player:SetRecoveryDelay gives strange results in TB mode
		mem.call(0x4049BA, 1, 0x509C98) -- end turn
	else
		Multiplayer.utils.delayed_call(Player.SetRecoveryDelay, 2, Player, Game.Spells[Spell].Delay[Mastery])
	end
end

local function resurrect_monster(t, hp_rate)
	local mon = Map.Monsters[t.TargetId]
	if mon.AIState ~= const.AIState.Dead then
		Game.PlaySound(142) -- spell failed
		return true
	end

	t.Player.SP = t.Player.SP - t.SPCost
	Game.PlaySound(spell_initsound(t.SpellId))
	set_spell_recovery_delay(t.Player, t.SpellId, t.Mastery)

	mon.HP = math.ceil(mon.FullHP * hp_rate)
	Multiplayer.SyncMonsters.set_mon_action(mon, 16)
	return true
end

local function std_target_handler(self, t)
	if t.TargetKind ~= 3 then
		return false
	end

	Game.ShowMonsterBuffAnim(t.TargetId, color24_by_spell(t.SpellId))

	t.Player.SP = t.Player.SP - t.SPCost
	set_spell_recovery_delay(t.Player, t.SpellId, t.Mastery)
	Game.PlaySound(spell_initsound(t.SpellId))
	t.Player:ShowFaceAnimation(const.FaceAnimation.CastSpell)

	return self.override -- override original behaivor if necessary
end

local function aoe_buff_cond(client, client_id)
	if client.map ~= Map.MapStatsIndex then
		return false
	end

	local mon = SyncPlayers.get_client_mon(client_id)
	if mon and distance(mon, Party) < Multiplayer.SHARE_BUFF_RANGE then
		return true
	end
	return false
end

local function aura_buff_cond(client, client_id)
	if client.map ~= Map.MapStatsIndex then
		return false
	end

	local mon = SyncPlayers.get_client_mon(client_id)
	return mon and distance(mon, Party) < Multiplayer.SHARE_AURA_RANGE
end

local function set_aura_buff(buff, expire_time)
	if buff.ExpireTime < expire_time then
		buff.ExpireTime = expire_time
		buff.Caster = Multiplayer.SERVICE_CASTER
		buff.Skill = 4
	end
end

local function aura_handler(isPartyBuff, BuffId)
	if isPartyBuff then
		return function()
			set_aura_buff(Party.SpellBuffs[BuffId], Game.Time + const.Minute * 8)
		end
	else
		return function()
			local newExpire = Game.Time + const.Minute * 8
			for i, v in Party do
				set_aura_buff(v.SpellBuffs[BuffId], newExpire)
			end
		end
	end
end

local function player_priority_wrapper(fpred)
	return function()
		if Party.count == 1 then
			return 0
		end

		local current = math.max(Game.CurrentPlayer, 0)
		if fpred(current) then
			return current
		end

		for i = 0, Party.count - 1 do
			if fpred(i) then
				return i
			end
		end

		return current
	end
end

local function current_wo_buff(player_buff)
	return player_priority_wrapper(function(i) return Party[i].SpellBuffs[player_buff].ExpireTime <= Game.Time end)
end

local function condition_priority(condition)
	local f
	if type(condition) == "table" then
		f = function(i)
			for _, v in pairs(condition) do
				if Party[i].Conditions[v] > 0 then
					return true
				end
			end
			return false
		end
	else
		f = function(i)
			return Party[i].Conditions[condition] > 0
		end
	end

	return player_priority_wrapper(f)
end
Multiplayer.utils.player_by_condition_selector = condition_priority

local heal_disabled_conds = {
	[const.Condition.Dead] = true,
	[const.Condition.Stoned] = true,
	[const.Condition.Paralyzed] = true,
	[const.Condition.Eradicated] = true,
}

local function lowest_hp_priority()
	local t = {}
	for i, p in Party do
		local disabled = false
		for k in pairs(heal_disabled_conds) do
			if p.Conditions[k] > 0 then
				disabled = true
				break
			end
		end
		if not disabled and p.HP < p:GetFullHP() then
			table.insert(t, {id = i, HP = p.HP})
		end
	end
	table.sort(t, function(a, b) return a.HP < b.HP end)
	return t[1] and t[1].id or math.max(Game.CurrentPlayer, 0)
end

-- cure spells that heal as well: the afflicted member first, else the most hurt one
local function condition_then_lowest_hp(condition)
	local has
	if type(condition) == "table" then
		has = function(i)
			for _, v in pairs(condition) do
				if Party[i].Conditions[v] > 0 then
					return true
				end
			end
			return false
		end
	else
		has = function(i)
			return Party[i].Conditions[condition] > 0
		end
	end

	return function()
		if Party.count == 1 then
			return 0
		end
		local current = math.max(Game.CurrentPlayer, 0)
		if has(current) then
			return current
		end
		for i = 0, Party.count - 1 do
			if has(i) then
				return i
			end
		end
		return lowest_hp_priority()
	end
end

local function ShowAoeBuffEffect(spell_id, pos)
	for client_id, mon_id in pairs(Multiplayer.client_monsters()) do
		local mon = Multiplayer.get_client_mon(client_id)
		if mon and distance(pos, mon) < Multiplayer.SHARE_BUFF_RANGE then
			mon:ShowSpellEffect(color24_by_spell(spell_id))
		end
	end
end

local function std_apply_buff(spell_info, skill, mastery, single_target, extra)
	local target = 0
	if single_target then
		target = spell_info.party_priority and spell_info:party_priority() or 0
		LogEvent("SPELLS", "Target for direct spell: %s", target)
	else
		ShowAoeBuffEffect(spell_info.id, extra)
	end

	local pl = Party.PlayersArray[Multiplayer.SERVICE_CASTER]
	pl.SP = 1000
	pl.DevineInterventionCasts = 0
	pl.ArmageddonCasts = 0
	pl.AgeBonus = 0

	CastSpellDirect(spell_info.id, skill, mastery, Multiplayer.SERVICE_CASTER, target)
	Multiplayer.utils.delayed_call(Multiplayer.notify_player_stats, 16, true)
end

local function std_buff_handler(aoe_since, party_priority, override)
	return {
		is_buff = true,
		aoe_buff_since = aoe_since or 0xFF,
		can_process_cond = std_can_process_cond,
		selection_mode = const.SelectionMode.PlayerOrMonster,
		apply_buff = std_apply_buff,
		anim_handler = nil,
		party_priority = party_priority,
		override = override,
		target_handler = {
			-- target kind = function
			[3] = std_target_handler, -- override default handler.
		},
	}
end

local function std_aura_handler(aura_type, aura_buff)
	return {
		is_buff = true,
		aura_buff_since = 0, -- same as aoe buff but for limited duration, forcing clients to stay around caster to keep receiving the buff
		can_process_cond = std_can_process_cond,
		aura_type = aura_type, -- party or player
		aura_buff = aura_buff, -- id from const.PartyBuff or const.PlayerBuff
		apply_aura = aura_handler(aura_type == 'party', aura_buff),
		apply_buff = std_apply_buff,
		anim_handler = nil,
	}
end

-- description of special spell processing
local spells_info = {
-- auras
	[21] = std_aura_handler('party', const.PartyBuff.Fly), -- Fly
	[27] = std_aura_handler('party', const.PartyBuff.WaterWalk), -- Water Walk
	[112] = std_aura_handler('player', const.PlayerBuff.Levitate), --Levitate
	[124] = std_aura_handler('party', const.PartyBuff.Fly), --Flight

-- simple aoe buffs
	[3] = std_buff_handler(0), -- Fire Resistance
	[5] = std_buff_handler(0), -- Haste
	[8] = std_buff_handler(0), -- Immolation
	[12] = std_buff_handler(0), -- Wizard Eye
	[13] = std_buff_handler(0), -- Feather Fall
	[14] = std_buff_handler(0), -- Air Resistance
	[17] = std_buff_handler(0), -- Shield
	[19] = std_buff_handler(0), -- Invisibility
	[25] = std_buff_handler(0), -- Water Resistance
	[36] = std_buff_handler(0), -- Earth Resistance
	[38] = std_buff_handler(0), -- Stone Skin
	[45] = std_buff_handler(0), -- Detect Life
	[51] = std_buff_handler(0), -- Heroism
	[58] = std_buff_handler(0), -- Mind Resistance
	[69] = std_buff_handler(0), -- Body Resistance
	[75] = std_buff_handler(0), -- Protection from Magic
	[77] = std_buff_handler(0), -- Power Cure
	[83] = std_buff_handler(0), -- Day of the Gods
	[85] = std_buff_handler(0), -- Day of Protection
	[86] = std_buff_handler(0), -- Hour of Power
	[101] = std_buff_handler(0), --Travelers' Boon

-- single target / complex buffs
	[40] = std_buff_handler(nil, condition_priority(const.Condition.Stoned), true), -- Stone to flesh
	[46] = std_buff_handler(2, current_wo_buff(const.PlayerBuff.Bless), true), -- Bless
	[47] = std_buff_handler(nil, current_wo_buff(const.PlayerBuff.Fate), false), -- Fate
	[49] = std_buff_handler(nil, condition_then_lowest_hp(const.Condition.Cursed), true), -- Remove Curse
	[50] = std_buff_handler(3, current_wo_buff(const.PlayerBuff.Preservation), true), -- Preservation
	[57] = std_buff_handler(nil, condition_priority(const.Condition.Fear), true), -- Remove Fear
	[61] = std_buff_handler(nil, condition_priority(const.Condition.Paralyzed), true), -- Cure Paralysis
	[64] = std_buff_handler(nil, condition_priority(const.Condition.Insane), true), -- Cure Insanity
	[67] = std_buff_handler(nil, condition_priority(const.Condition.Weak), true), -- Cure Weakness
	[71] = std_buff_handler(nil, current_wo_buff(const.PlayerBuff.Regeneration), true), -- Regeneration
	[72] = std_buff_handler(nil, condition_priority{const.Condition.Poison1, const.Condition.Poison2, const.Condition.Poison3}, true), -- Cure Poison
	[74] = std_buff_handler(nil, condition_then_lowest_hp{const.Condition.Disease1, const.Condition.Disease2, const.Condition.Disease3}, true), -- Cure Disease
	[95] = std_buff_handler(3, current_wo_buff(const.PlayerBuff.PainReflection), true), -- Pain Reflection

-- Heal
	[68] = std_buff_handler(nil, lowest_hp_priority, false),

-- Hammerhands
	[73] = std_buff_handler(4, player_priority_wrapper(function(i)
		local p = Party[i]
		return p.SpellBuffs[const.PlayerBuff.Hammerhands].ExpireTime <= Game.Time and p:GetSkill(const.Skills.Unarmed) > 0
	end)),

-- Divine intervention - no range restriction
	[88] = {
		is_buff = true,
		anim_handler = function(spell_info, skill, mastery, target_kind, target_id, extra)
			if extra.can_apply then
				std_apply_buff(spell_info, skill, mastery, false, extra)
			end
		end,
		extra_info = function(t)
			t.can_apply = Party[Game.CurrentPlayer].DevineInterventionCasts < 3
		end,
	},

-- Armageddon - no range restriction
	[98] = {
		is_buff = true,
		anim_handler = function(spell_info, skill, mastery, target_kind, target_id, extra)
			if extra.can_apply then
				std_apply_buff(spell_info, skill, mastery, false, extra)
			end
		end,
		extra_info = function(t, skill, mastery)
			t.can_apply = Party[Game.CurrentPlayer].ArmageddonCasts < mastery
		end,
	},

-- Awaken - disables weather effects - process without range restriction
	[23] = {
		is_buff = true,
		anim_handler = function(spell_info, skill, mastery, target_kind, target_id, extra)
			CastSpellDirect(spell_info.id, skill, mastery, Multiplayer.SERVICE_CASTER)
		end
	},

-- Town portal
	[31] = {
		is_buff = true,
		aoe_buff_since = 3,
		can_process_cond = std_can_process_cond,
		selection_mode = const.SelectionMode.PlayerOrMonster,
		target_handler = {},
		sender_override = true,
		extra_info = function(t)
			t.switch = TownPortalControls.GetCurrentSwitch()
			t.bits = {}
			for i = 180, 185 do
				t.bits[i] = Party.QBits[i]
			end
		end,
		apply_buff = function(spell_info, skill, mastery, single_target, extra)
			local function f()
				CastSpellDirect(spell_info.id, skill, mastery, Multiplayer.SERVICE_CASTER, Party.PlayersIndexes[0])
			end

			if Game.CurrentScreen == 3 then
				return -- already at town portal screen
			end

			if extra.switch == 4 then
				TownPortalControls.GenDimDoor()
			end
			for i = 180, 185 do
				Party.QBits[i] = Party.QBits[i] or extra.bits[i] or false
			end
			TownPortalControls.SwitchTo(extra.switch)

			if Game.CurrentScreen ~= 0 then
				-- wait player to leave screen to avoid UI break
				Multiplayer.utils.TickChecker(f, 4, function() return Game.CurrentScreen == 0 end)
			else
				f()
			end
		end,
	},

-- Lloyd's beacon
	-- [33] = {} -- special handler below

-- Raise Dead
	[53] = {
		is_buff = true,
		can_process_cond = std_can_process_cond,
		selection_mode = const.SelectionMode.PlayerOrMonster,
		party_priority = condition_priority(const.Condition.Dead),
		apply_buff = std_apply_buff,
		target_handler = {
			[3] = function(self, t)
				return resurrect_monster(t, 0.1)
			end,
		},
		override = true,
	},

-- Resurrect
	[55] = {
		is_buff = true,
		can_process_cond = std_can_process_cond,
		selection_mode = const.SelectionMode.PlayerOrMonster,
		party_priority = condition_priority{const.Condition.Dead, const.Condition.Eradicated},
		apply_buff = std_apply_buff,
		target_handler = {
			[3] = function(self, t)
				return resurrect_monster(t, 1)
			end,
		},
		override = true,
	},

-- Reanimate
	[89] = {
		is_buff = true,
		party_priority = condition_priority{const.Condition.Dead},
		apply_buff = function(spell_info, skill, mastery, single_target, extra)
			local target = spell_info:party_priority()
			Game.TransformToZombie(Party[target], skill, mastery)
		end,
		target_handler = {
			-- target kind = function
			[3] = function(self, t)
				if t.TargetKind == 3 and Multiplayer.posessed_by_player(t.TargetId) then
					return std_target_handler(self, t)
				end
			end,
		},
		override = true,
	},

-- Charm
	[60] = {
		is_buff = false,
		can_process_cond = std_can_process_cond,
		target_handler = {
			[3] = function(self, t)
				local mon = Map.Monsters[t.TargetId]
				-- allow to talk with talkative monsters
				mon.Hostile = false
				mon.ShowAsHostile = false
			end,
		},
		override = true,
	},
}

for k, v in pairs(spells_info) do
	v.id = k
	v.aoe_buff_since = v.aoe_buff_since or 0xFF
end

Multiplayer.debug.SpellsInfo = spells_info

local packets = {

	cast_spell_anim = {
		bulb = function(spell_id, target_kind, target_id, skill, mastery, userdata)
			local spell_info = spells_info[spell_id]
			if not spell_info then
				return nil
			end

			u2[sendbuff] = spell_id
			u2[sendbuff+2] = target_kind
			u2[sendbuff+4] = target_id
			u2[sendbuff+6] = 0xFFFF
			u1[sendbuff+8] = skill
			u1[sendbuff+9] = mastery

			if target_kind == 3 then
				local client_id = table.find(SyncPlayers.client_monsters(), target_id)
				if client_id then
					u2[sendbuff+6] = client_id
				end
			end

			local t = {bin = mstr(sendbuff, 10, true), X = Party.X, Y = Party.Y, Z = Party.Z}
			if spell_info.extra_info then
				spell_info.extra_info(t, skill, mastery)
			end
			if userdata and next(userdata) then
				t.userdata = userdata
			end

			LogEvent("SPELLS", "Casting spell: spell - %s, target kind - %s, target id - %s, client id - %s", spell_id, target_kind, target_id, i2[sendbuff+6])
			return item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			local t = bin_to_item(toptr(bin_string))
			local ptr = toptr(t.bin)
			local spell_id, target_kind, target_id, client_id, skill, mastery = u2[ptr], u2[ptr+2], u2[ptr+4], i2[ptr+6], u1[ptr+8], u1[ptr+9]

			local spell_info = spells_info[spell_id]
			if not spell_info then return end

			LogEvent("SPELLS", "Notified about spell casted: spell - %s, target kind - %s, target id - %s, client id - %s", spell_id, target_kind, target_id, client_id)

			if target_kind == 4 or target_kind == 0 then
				local mon = SyncPlayers.get_client_mon(metadata.sender_id)
				target_kind, target_id = 3, mon and mon:GetIndex() or nil
				target_self = true
			elseif target_kind == 3 then
				if client_id == Multiplayer.my_id then
					target_kind, target_id = 4, 0
				elseif client_id ~= 0xFFFF then
					local mon = SyncPlayers.get_client_mon(client_id)
					if mon then
						target_kind, target_id = 3, mon:GetIndex()
					else
						target_kind, target_id = 0, 0
					end
				else
					target_kind, target_id = 3, target_id < Map.Monsters.count and target_id or nil
				end
			else
				LogEvent("SPELLS", "Skipping spell with unsupported target_kind %s.", target_kind)
				return
			end

			-- anim
			if spell_info.anim_handler then
				spell_info.anim_handler(spell_info, skill, mastery, target_kind, target_id, t)
			elseif target_kind == 3 and target_id then
				Game.ShowMonsterBuffAnim(target_id, color24_by_spell(spell_info.id))
			end

			if t.userdata then
				RemoteSpellsData[spell_id] = t.userdata
			end

			-- effect
			if not spell_info.is_buff then
				return
			elseif target_kind == 4 and spell_info.apply_buff then
				LogEvent("SPELLS", "Received direct buff: spell - %s, skill - %s, mastery - %s", spell_id, skill, mastery)
				spell_info:apply_buff(skill, mastery, true, t)
			elseif target_kind == 3 and target_id then
				local range = distance(Map.Monsters[target_id], Party)
				if mastery >= spell_info.aoe_buff_since and range <= Multiplayer.SHARE_BUFF_RANGE then
					LogEvent("SPELLS", "Received aoe buff: spell - %s, skill - %s, mastery - %s", spell_id, skill, mastery)
					spell_info:apply_buff(skill, mastery, false, t)
				elseif spell_info.aura_buff_since and mastery >= spell_info.aura_buff_since and range <= Multiplayer.SHARE_AURA_RANGE then
					LogEvent("SPELLS", "Received aura buff: spell - %s", spell_id)
					spell_info:apply_aura(t)
				end
			end
		end,
		check_delivery = true,
		same_map_only = true,
		compress = true
	},

	aura_spell_buff = {
		bulb = function(spell_id, skill, mastery)
			u2[sendbuff] = spell_id
			return mstr(sendbuff, 2, true)
		end,
		handler = function(bin_string, metadata)
			local ptr = toptr(bin_string)
			local spell_id = u2[ptr]
			LogEvent("SPELLS", "Received aura buff: spell - %s", spell_id)
			spells_info[spell_id].apply_aura()
			events.Call("SpellAuraReceived", spell_id)
		end,
		check_delivery = true,
		same_map_only = true
	},

	lloyds_beacon = {
		bulb = function(slot)
			return Multiplayer.utils.mmt_dump(slot)
		end,
		handler = function(bin_string, metadata)
			local t = structs.LloydBeaconSlot:new(toptr(bin_string))
			local text = "%s casting Lloyd's Beacon... %s..."
			local name = SyncPlayers.client_name(metadata.sender_id)
			local move_params = {t.X, t.Y, t.Z, t.Direction, 0, 0, 0, 0, t.Map}

			Game.ShowStatusText(text:format(name, 3))

			Multiplayer.utils.delayed_call2(function()
				Game.ShowStatusText(text:format(name, 2))
			end, 1000)

			Multiplayer.utils.delayed_call2(function()
				Game.ShowStatusText(text:format(name, 1))
			end, 2000)

			Multiplayer.utils.delayed_call2(function()
				local f = function()
					evt.MoveToMap(move_params)
					Multiplayer.utils.delayed_call(Multiplayer.notify_player_position, 16, true)
				end
				local c = function() return Game.CurrentScreen == 0 or Game.CurrentScreen == 22 end

				Multiplayer.utils.TickChecker(f, 4, c)
			end, 3000)
		end,
		check_delivery = true,
		same_map_only = true
	}
}
Multiplayer.utils.init_packets(packets)

-- Handlers
local function dump_recovery_times()
	local t = {CurrentPlayer = Game.CurrentPlayer}
	for i, v in Party do
		t[i] = v.RecoveryDelay
	end
	t.bin = mstr(0x509c98, 80, 0)
	return t
end

local function revert_recovery_times(t)
	Game.TurnBased = true
	for i, v in Party do
		v.RecoveryDelay = t[i]
	end
	Game.CurrentPlayer = t.CurrentPlayer
	mcopy(0x509c98, t.bin, 80)
end

function events.PlayerCastSpellFirst(t)
	if t.PlayerIndex == Multiplayer.SERVICE_CASTER then
		if RemoteSpellsData[t.SpellId] then
			t.RemoteData = RemoteSpellsData[t.SpellId]
			RemoteSpellsData[t.SpellId] = nil
		end
	elseif spells_info[t.SpellId] then
		t.MultiplayerData = {client_id = Multiplayer.my_id}
	end
end

local last_spell_info
function events.PlayerCastSpellLast(t)
	last_spell_info = t

	if t.PlayerIndex == Multiplayer.SERVICE_CASTER or not evt.IsPlayerInParty(t.PlayerIndex) then
		LogEvent("SPELLS", "Skipping service spell cast (by player %s).", t.PlayerIndex)
		return -- spell casted by service call
	end

	if t.CurseInterrupt then
		LogEvent("SPELLS", "Spell #%s interrupted by curse (by player %s).", t.SpellId, t.PlayerIndex)
		return
	elseif t.SPCost > t.Player.SP then
		LogEvent("SPELLS", "Not enough SP to cast spell #%s (by player %s).", t.SpellId, t.PlayerIndex)
		if Game.TurnBased then
			Multiplayer.utils.delayed_call(revert_recovery_times, 1, dump_recovery_times())
		end
		return
	end

	local spell_info = spells_info[t.SpellId]
	if not spell_info or not spell_info.sender_override then
		LogEvent("SPELLS", "Broadcasting spell #%s (by player %s).", t.SpellId, t.PlayerIndex)
		Multiplayer.broadcast(packets.cast_spell_anim:prep(t.SpellId, t.TargetKind, t.TargetId, t.Skill, t.Mastery, t.MultiplayerData), cond_same_map)
	end

	if spell_info then
		local handler = spell_info.target_handler and spell_info.target_handler[t.TargetKind]
		if handler then
			t.Handled = handler(spell_info, t)
		end
		if not t.Handled and spell_info.is_buff and spell_info.aoe_buff_since <= t.Mastery then
			ShowAoeBuffEffect(t.SpellId, Party)
		end
	end
end

function events.CanCastTownPortal(t)
	if t.CanCast and evt.IsPlayerInParty(last_spell_info.PlayerIndex) then
		LogEvent("SPELLS", "Broadcasting spell #%s (by player %s).", 31, last_spell_info.PlayerIndex)
		Multiplayer.broadcast(packets.cast_spell_anim:prep(31, 4, last_spell_info.PlayerIndex, last_spell_info.Skill, last_spell_info.Mastery), cond_same_map)
	end
end

function events.ChooseSelectionMode(t)
	local spell_id = u2[0x51d820]
	local spell_info = spells_info[spell_id]
	if spell_info and spell_info.selection_mode then
		t.mode = spell_info.selection_mode
	end
end

function events.CanProcessSpell(t)
	local spell_info = spells_info[t.spell_id]
	if spell_info and spell_info.can_process_cond then
		t.allow = spell_info:can_process_cond(t)
	end
end

local auras = {}
for spell_id, v in pairs(spells_info) do
	if v.apply_aura then
		auras[spell_id] = v
	end
end

local function share_auras()
	if not Multiplayer.in_game then
		return
	end

	for spell_id, info in pairs(auras) do
		if info.aura_type == 'party' then
			local buff = Party.SpellBuffs[info.aura_buff]
			if buff.ExpireTime > Game.Time and buff.Caster ~= 0 and buff.Caster ~= Multiplayer.SERVICE_CASTER then
				Multiplayer.broadcast(packets.aura_spell_buff:prep(spell_id), aura_buff_cond)
			end
		else
			for i, pl in Party do
				local buff = pl.SpellBuffs[info.aura_buff]
				if buff.ExpireTime > Game.Time and buff.Caster == (Party.PlayersIndexes[i] + 1) then
					Multiplayer.broadcast(packets.aura_spell_buff:prep(spell_id), aura_buff_cond)
					break
				end
			end
		end
	end
end
Multiplayer.utils.MillisecCounter(share_auras, 4000)

function events.LloydsBeaconRecall(Player, Slot)
	Multiplayer.broadcast(packets.lloyds_beacon:prep(Slot), aoe_buff_cond)
	Multiplayer.sendall()
end
