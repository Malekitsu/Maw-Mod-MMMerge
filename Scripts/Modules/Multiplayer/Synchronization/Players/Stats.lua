local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
local nums_to_bin, fill_from_bin = Multiplayer.utils.nums_to_bin, Multiplayer.utils.fill_from_bin
local sqrt, abs, floor, ceil, rad, deg = math.sqrt, math.abs, math.floor, math.ceil, math.rad, math.deg
local max, asin = math.max, math.asin
local cond_same_map = Multiplayer.utils.cond_same_map
local spell_initsound = Multiplayer.utils.spell_initsound
local distance = Multiplayer.utils.distance
local AIStateToGraphicState = Multiplayer.utils.AIStateToGraphicState

local function client_info(i)
	local client = Multiplayer.connector.clients[i]
	if not client and i == Multiplayer.my_id then
		return {
			id = Multiplayer.my_id,
			name = Party[0].Name,
			map = Map.MapStatsIndex,
			skin = Multiplayer.my_skin,
			house = GetCurrentHouse(),
			PlayerColor = Multiplayer.preferred_color
		}
	end
	return client
end

local function party_operable()
	local player
	for i = 0, Party.count - 1 do
		player = Party[i]
		if player.Conditions[12] == 0
			and player.Conditions[13] == 0
			and player.Conditions[14] == 0
			and player.Conditions[15] == 0
			and player.Conditions[16] == 0 then

			return true
		end
	end
	return false
end

local client_stats = {"Condition", "HP", "SP", "Face", "LevelBase", "Voice", "Class", "FullHP", "FullSP", "ArmorClass", "skin", "Invisible", "Operable", "Map", "house"}

local packets = {
	request_player_stats = {
		response = "player_stats",
		check_delivery = true
	},

	player_stats = {
		bulb = function()
			local player = Party[0]
			local stats = {
				Condition = player:GetMainCondition(),
				HP = player.HP,
				SP = player.SP,
				Face = player.Face,
				LevelBase = player.LevelBase,
				Voice = player.Voice,
				Class = player.Class,
				FullHP = player:GetFullHP(),
				FullSP = player:GetFullSP(),
				ArmorClass = player:GetArmorClass(),
				skin = Multiplayer.my_skin,
				Invisible = Party.SpellBuffs[const.PartyBuff.Invisibility].ExpireTime > Game.Time,
				Operable = party_operable(),
				Map = Map.MapStatsIndex,
				house = Game.GetCurrentHouse() or 0}

			if Party.count > 1 then
				local total = {HP = 0, FullHP = 0, SP = 0, FullSP = 0, ArmorClass = 0, Level = 0}
				for i,v in Party do
					local main_cond = v:GetMainCondition()
					if main_cond < const.Condition.Zombie then
						if stats.Condition >= const.Condition.Zombie then
							stats.Condition = main_cond
						else
							stats.Condition = math.max(main_cond, stats.Condition)
						end
					end
					total.HP = total.HP + v.HP
					total.FullHP = total.FullHP + v:GetFullHP()
					total.SP = total.SP + v.SP
					total.FullSP = total.FullSP + v:GetFullSP()
					total.ArmorClass = total.ArmorClass + v:GetArmorClass()
					total.Level = total.Level + v.LevelBase
				end
				stats.HP = total.HP
				stats.FullHP = total.FullHP
				stats.SP = total.SP
				stats.FullSP = total.FullSP
				stats.ArmorClass = math.ceil(total.ArmorClass / Party.count)
				stats.LevelBase = math.ceil(total.Level / Party.count)
			end

			local result = {name = player.Name, bin = nums_to_bin(stats, client_stats, 2)}
			return item_to_bin(result)
		end,
		handler = function(bin_string, metadata)
			local input = bin_to_item(toptr(bin_string))
			local stats = fill_from_bin({}, toptr(input.bin), client_stats, 2, true)
			local client = client_info(metadata.sender_id)

			stats.Invisible = stats.Invisible == 1
			stats.Operable = stats.Operable == 1
			stats.name = input.name

			events.Call("ClientStatsUpdate", metadata.sender_id, stats, client)

			client.skin = stats.skin
			client.voice = stats.Voice
			client.class = stats.Class
			client.face = stats.Face
			client.name = stats.name
			client.main_cond = stats.Condition
			client.invisible = stats.Invisible
			client.operable = stats.Operable
			client.house = stats.house
			client.level = stats.LevelBase
			client.HP = stats.HP
			client.FullHP = stats.FullHP
			client.SP = stats.SP
			client.FullSP = stats.FullSP

			if client.map ~= stats.Map then
				events.Call("ClientChangeMap", metadata.sender_id, client.map, stats.Map)
				client.map = stats.Map
			end
			Multiplayer.get_client_mon(metadata.sender_id)
		end,
		check_delivery = true,
		compress = true
	}
}
Multiplayer.utils.init_packets(packets)

local function notify_player_stats(same_map)
	Multiplayer.broadcast(packets.player_stats:prep(), same_map and cond_same_map)
end

local function request_player_stats(client_id)
	local data = packets.request_player_stats:prep()
	Multiplayer.add_to_send_queue(client_id, data)
end

-- many hits and casts in one moment collapse into one stats packet
local stats_update_pending = false
local function schedule_stats_update()
	if stats_update_pending then
		return
	end
	stats_update_pending = true
	Multiplayer.utils.delayed_call(function()
		stats_update_pending = false
		notify_player_stats(true)
	end, 4)
end

--------------------------------------------
-- Events

-- send stats upon joining game
function events.GatherServerInitData(t)
	Multiplayer.utils.delayed_call(notify_player_stats, 16)
end

function events.ProcessServerInitData(t)
	Multiplayer.utils.delayed_call(notify_player_stats, 16)
end

-- send stats changes upon taking damage
function events.CalcDamageToPlayer(t)
	if Game.CurrentScreen == const.Screens.House then
		t.Result = 0
		return
	end
	schedule_stats_update()
end

-- update stats upon casting spell
function events.PlayerCastSpell(t)
	schedule_stats_update()
end

--------------------------------------------
-- Periodic stats update

Multiplayer.utils.TickCounter(notify_player_stats, 256)

--------------------------------------------
-- Death

local before_popup = true
local text = "You have been defeated.\nPress ESC to accept death or wait for another player to revive you."

function events.PartyDies(t)
	if before_popup then
		if Game.CurrentScreen == 0 then
			Game.EscMessage(text)
			before_popup = false
			events.Call("MultiplayerDeathScreen")
		else
			ExitCurrentScreen()
		end
		t.Handled = true
	elseif Game.CurrentScreen == const.Screens.EscMessage then
		t.Handled = true
		if party_operable() then
			Multiplayer.ExitDeathScreen(false, false)
			--mem.u4[0x6ceb28] = 0 -- Exit death loop
			--DoGameAction(113) -- Exit EscMessage window
			--before_popup = true
		end
	else
		t.Handled = party_operable()
		before_popup = true
	end
end

function events.RegenTick(Player)
	if Player.HP > 0 and Player.Conditions[13] > 0  then
		Player.Conditions[13] = 0
	end
end

function Multiplayer.OnDeathScreen()
	return not before_popup
end

function Multiplayer.ExitDeathScreen(RaiseParty, Now)
	if RaiseParty then
		for _, pl in Party do
			for i = 0, 17 do
				pl.Conditions[i] = 0
			end
		end
		Party.RestAndHeal()
	end
	mem.u4[0x6ceb28] = 0 -- Exit death loop
	before_popup = true
	ExitCurrentScreen(false, Now) -- Exit EscMessage window
end

--------------------------------------------
-- Save / Load

function events.GatherPartySaveData(t)
	t.DaysWithoutRest = Party.DaysWithoutRest
	t.SpellBuffs = Multiplayer.utils.mmt_dump(Party.SpellBuffs)
end

function events.ProcessPartySaveData(t)
	Party.DaysWithoutRest = t.DaysWithoutRest or 0
	if t.SpellBuffs then
		mcopy(Party.SpellBuffs["?ptr"], t.SpellBuffs)
		Multiplayer.utils.LogEvent("PLAYERS_SYNC", "Remote save loading: SpellBuffs loaded: %s", #t.SpellBuffs)
	end
end

--------------------------------------------
-- Debug

function events.PlayerAttacked(t)
	local mon_id = t.Attacker.MonsterIndex
	if mon_id and Multiplayer.posessed_by_player(mon_id) then
		Multiplayer.utils.LogEvent("PLAYERS_SYNC", "Player received damage from client puppet !!!")
		--t.Handled = true
	end
end

--------------------------------------------

return {
	client_info = client_info,
	party_operable = party_operable,
	notify_player_stats = notify_player_stats,
	request_player_stats = request_player_stats
}
