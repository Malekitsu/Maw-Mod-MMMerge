local events = Multiplayer.events
local u1, u2, u4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.i4, mem.string, mem.copy, mem.topointer
local sendbuff = Multiplayer.utils.sendbuff
local cond_same_map = Multiplayer.utils.cond_same_map
local spell_initsound = Multiplayer.utils.spell_initsound
local distance = Multiplayer.utils.distance
local AIStateToGraphicState = Multiplayer.utils.AIStateToGraphicState
local LogEvent = Multiplayer.utils.LogEvent

local PUPPET_AITYPE = 60

local client_monsters = {}
local client_in_house = {}

local FreePlaceMonTxtStart = 40

local function get_client_monsters()
	return client_monsters
end

local function clients_in_houses()
	return client_in_house
end

local function posessed_by_player(monId)
	return table.find(client_monsters, monId)
end

local function client_name(client_id, show_class, show_condition)
	if show_class == nil then show_class = true end
	if show_condition == nil then show_condition = true end

	local info = Multiplayer.connector.clients[client_id]
	if not info then
		return "Player"
	end

	local name = info.name or ""
	local class = show_class and info.class and Game.ClassNames[info.class]
	if class then
		name = Game.GlobalTxt[429]:format(name, class)
	end

	local main_cond = show_condition and info.main_cond and info.main_cond ~= 18 and Multiplayer.utils.ConditionNames[info.main_cond]
	main_cond = main_cond and Game.GlobalTxt[main_cond]
	if main_cond then
		name = string.format("%s %s%s%s", name, Game.NPCText[2705], main_cond, Game.NPCText[2706]) --name .. " (" .. main_cond .. ")"
	end
	return name
end

local function get_client_mon(client)
	local client_id
	if type(client) == 'number' then
		client_id = client
		client = Multiplayer.connector.clients[client_id]
	elseif type(client) == 'table' then
		client_id = client.id
	else
		error("Wrong argument to get_client_mon: " .. tostring(client))
	end

	if not client or client.map ~= Map.MapStatsIndex then
		--LogEvent("PLAYERS_SYNC", "Requested client monster, client is on other map, returning nil.")
		local monid = client_monsters[client_id]
		if monid and monid < Map.Monsters.count then
			local mon = Map.Monsters[monid]
			if mon.AIType == PUPPET_AITYPE then
				mon.AIState = const.AIState.Removed
			end
		end
		client_monsters[client_id] = nil
		return nil
	end

	local monid = client_monsters[client_id]
	local mon
	local function mon_setup()
		local info = Multiplayer.client_info(client_id) or {}
		mon.Ally = 9999 -- party
		mon.AIType = PUPPET_AITYPE
		mon.MoveType = 3
		mon.HP = info.HP or 100
		mon.FullHP = info.FullHP or 100
		mon.BodyRadius = 1
		mon.BodyHeight = 160
		mon.AIState = 0
		mon.Fly = 0
		mon.Group = 50
		mon.NPC_ID = 0
		mon.NameId = PlaceMonId
		mon.Hostile = false
		mon.ShowAsHostile = false
		mon.Spell = 0
		mon.Spell2 = 0
		mon.Special = 0
		mon.SpecialA = 0
		mon.SpecialB = 0
		mon.SpecialD = 0
		mon.SpecialC = 0
		client_monsters[client_id] = monid
	end

	if monid and monid < Map.Monsters.count then
		mon = Map.Monsters[monid]
	else
		LogEvent("PLAYERS_SYNC", "No monster selected for the client, at the moment (mon id is %s).", monid)
		for i,v in Map.Monsters do
			if v.AIType == PUPPET_AITYPE and v.Id == client.skin and not posessed_by_player(i) then
				LogEvent("PLAYERS_SYNC", "Found monster to use as client's puppet: %s.", i)
				monid, mon = i, v
				mon_setup()
				break
			end
		end
	end

	if not mon then
		mon, monid = SummonMonster(client.skin, 0,0,0)
		mon_setup()
		LogEvent("PLAYERS_SYNC", "Could not find client's monster, creating new puppet (#%s) for player %s", monid, client.id)
	elseif mon.Id ~= client.skin then
		local old = mon
		LogEvent("PLAYERS_SYNC", "Specified monster's id does not fit client's skin, creating new puppet for player %s.", client_id)
		mon, monid = SummonMonster(client.skin, 0,0,0)
		mon_setup()
		old.AIState = const.AIState.Removed
	end

	if client.invisible or client_in_house[client_id] then
		mon.AIState = const.AIState.Invisible
		mon.CurrentActionLength = const.Hour
		mon.CurrentActionStep = 0
	end

	mon.Ally = 9999 -- party
	mon.AIType = PUPPET_AITYPE
	mon.MoveType = 3
	mon.Hostile = false
	mon.ShowAsHostile = false
	return mon
end

local AIStateToFramesName = {
	[const.AIState.MeleeAttack] = 'FramesAttack',
	[const.AIState.RangedAttack] = 'FramesShoot',
	[const.AIState.Dying] = 'FramesDie',
	[const.AIState.Fidget] = 'FramesFidget'
}

local function set_player_aistate(client_id, state, length, supress_sound)
	local mon = get_client_mon(client_id)
	if not mon then
		return
	end

	if not length then
		if state == const.AIState.Stand or state == const.AIState.Active then
			length = 96
		else
			local frames = AIStateToFramesName[state]
			length = frames and (Game.SFTBin[mon[frames]].TotalTime * 8 - 1) or 96
		end
	end

	if mon.AIState == state then
		mon.CurrentActionLength = math.min(mon.CurrentActionLength + length, const.Hour)
	else
		--LogEvent("PLAYERS_SYNC", "#%s player's AIState changed from %s to %s.", client_id, table.find(const.AIState, mon.AIState), table.find(const.AIState, state))
		mon.AIState = state
		mon.CurrentActionLength = length
		mon.CurrentActionStep = 0
	end

	if not supress_sound then
		Multiplayer.utils.play_mon_sound(mon)
	end

	mon:UpdateGraphicState()
end

local ConditionToDownstate = {
	[const.Condition.Paralyzed] = const.AIState.Stand,
	[const.Condition.Stoned] = const.AIState.Stand,
	[const.Condition.Eradicated ] = const.AIState.Invisible
}

local function set_player_downstate(client_id)
	local mon = get_client_mon(client_id)
	if not mon then
		return
	end

	local info = Multiplayer.client_info(client_id)
	if info.operable then
		return
	end

	local state = ConditionToDownstate[info.main_cond] or const.AIState.Dead
	set_player_aistate(client_id, state, const.Hour)
end

local RemoteSoundsReceived = {}
local function play_puppet_sound(sound_id, mon, volume, detached_from_monster)
	if not RemoteSoundsReceived[sound_id] then
		for si,sv in Game.SoundsBin do
			if sv.Id == sound_id then
				sv.Is3D = true -- otherwise Volume parameter won't be applied correctly
				break
			end
		end
		RemoteSoundsReceived[sound_id] = true
	end
	if detached_from_monster then
		-- mon in this case is any object (const.ObjectRefKind + id << 3) reference
		Game.PlaySound(sound_id, mon, 0, -1, 0, 1, volume or 0, 0)
	else
		-- sound referenced to monster will stop other sounds referenced to same monster,
		-- unless currently playing sound has same id, then new sound won't play
		Game.PlaySound(sound_id, bit.lshift(mon:GetIndex(), 3) + 3, 0, -1, 0, 0, volume or 0, 0)
	end
end

local function play_puppet_sound2(sound_id, client_id, volume)
	local mon = get_client_mon(client_id)
	if mon then
		play_puppet_sound(sound_id, mon, volume, false)
	end
end

local packets = {
	change_skin = {
		bulb = function(monstertxt_id)
			u4[sendbuff] = monstertxt_id
			return mstr(sendbuff, 4, true)
		end,
		handler = function(bin_string, metadata)
			local skinid = u4[toptr(bin_string)]
			Multiplayer.connector.clients[metadata.sender_id].skin = skinid
			get_client_mon(metadata.sender_id)
		end,
		check_delivery = true
	},

	play_monster_anim = {
		bulb = function(ai_state, sound_id, detached_from_monster)
			u1[sendbuff] = ai_state
			u1[sendbuff + 1] = detached_from_monster and 1 or 0
			u2[sendbuff + 2] = sound_id or 0
			return mstr(sendbuff, 4, true)
		end,
		handler = function(bin_string, metadata)
			local mon = get_client_mon(metadata.sender_id)
			if client_in_house[metadata.sender_id] then
				set_player_aistate(metadata.sender_id, const.AIState.Invisible, const.Hour)
				return
			end

			local ptr = toptr(bin_string)
			local ai_state = u1[ptr]
			if mon and mon.AIState ~= const.AIState.Invisible and mon.AIState ~= ai_state then
				local sound_id = u2[ptr + 2]

				local supress_sound = sound_id ~= 0
					or ai_state == const.AIState.MeleeAttack and Multiplayer.remote_attack_sounds_on()
					or ai_state == const.AIState.Stunned and Multiplayer.remote_injury_sounds_on()

				set_player_aistate(metadata.sender_id, ai_state, nil, supress_sound)
				if mon.AIState == const.AIState.Dying and mon.HP > 0 then
					mon.GraphicState = 4
				end

				if sound_id ~= 0 then
					Game.LoadSound(sound_id)
					play_puppet_sound(sound_id, mon, 30, u1[ptr + 1] ~= 0)
				end
			end
		end,
		same_map_only = true
	},

	enter_house = {
		bulb = function(house_id)
			u2[sendbuff] = house_id
			return mstr(sendbuff, 2, true)
		end,
		handler = function(bin_string, metadata)
			local house_id = u2[toptr(bin_string)]
			local client = Multiplayer.connector.clients[metadata.sender_id]
			client_in_house[metadata.sender_id] = house_id
			set_player_aistate(metadata.sender_id, const.AIState.Invisible, const.Hour)
			play_puppet_sound2(6, metadata.sender_id)
		end,
		check_delivery = true
	},

	exit_house = {
		bulb = function()
			return '\0'
		end,
		handler = function(bin_string, metadata)
			local house_id = client_in_house[metadata.sender_id]
			local client = Multiplayer.connector.clients[metadata.sender_id]
			if not house_id then
				return
			end
			client_in_house[metadata.sender_id] = nil
			set_player_aistate(metadata.sender_id, const.AIState.Stand, const.Minute)
			play_puppet_sound2(7, metadata.sender_id)
		end,
		check_delivery = true
	},

	change_map = {
		bulb = function(MapStatsIndex)
			u4[sendbuff] = MapStatsIndex
			return mstr(sendbuff, 4, true)
		end,
		handler = function(bin_string, metadata)
			local client = Multiplayer.connector.clients[metadata.sender_id]
			local mapid = u4[toptr(bin_string)]
			local oldmap = client.map
			client.map = mapid
			client_in_house[metadata.sender_id] = false

			if oldmap == Map.MapStatsIndex then
				local monid = client_monsters[metadata.sender_id]
				if monid and monid < Map.Monsters.count then
					Map.Monsters[monid].AIState = const.AIState.Removed
					client_monsters[metadata.sender_id] = nil
				end
			end
			events.Call("ClientChangeMap", metadata.sender_id, oldmap, mapid)
		end,
		check_delivery = true
	},

	corpse_pick_gold = {
		handler = function()
			if Multiplayer.SyncPlayers.party_operable() then
				return nil
			end

			local Gold = Party.Gold
			Party.Gold = 0
			return Gold
		end,
		response = "corpse_gold_picked",
		same_map_only = true
	},

	corpse_gold_picked = {
		bulb = Multiplayer.utils.num_to_hexstr,
		handler = function(bin_string, metadata)
			local Gold = Multiplayer.utils.num_from_hexstr(bin_string, 4)
			if Gold == 0 then
				Game.ShowStatusText("This corpse has no more gold.")
			else
				Game.ShowStatusText(Game.GlobalTxt[467]:replace("%lu", tostring(Gold)))
				Game.PlaySound(133)
				Party.Gold = Party.Gold + Gold
				Multiplayer.utils.broadcast_pick_object_sound()
			end
		end,
		check_delivery = true
	}
}
Multiplayer.utils.init_packets(packets)

local function notify_skin_changed()
	Multiplayer.broadcast(packets.change_skin:prep(Multiplayer.my_skin), nil)
end

------------------------------------------------
-- Events

-- Remove other players' service monsters upon saving
local old_aistate = {}
local function hide_client_monsters()
	old_aistate = {}
	for client_id, _ in pairs(client_monsters) do
		local mon = get_client_mon(client_id)
		if mon then
			old_aistate[mon:GetIndex()] = mon.AIState
			mon.AIState = const.AIState.Removed
		end
	end

	for i, v in Map.Monsters do
		if v.AIType == PUPPET_AITYPE then
			v.AIState = const.AIState.Removed
		end
	end
end

local function unhide_client_monsters()
	for mon_id, aistate in pairs(old_aistate) do
		if mon_id < Map.Monsters.count then
			local mon = Map.Monsters[mon_id]
			if mon.AIType == PUPPET_AITYPE and mon.AIState == const.AIState.Removed then
				mon.AIState = aistate
			end
		end
	end
	old_aistate = {}
end

function events.BeforeSaveGame()
	vars.Multiplayer = vars.Multiplayer or {}
	vars.Multiplayer.my_skin = Multiplayer.my_skin
	hide_client_monsters()
end

function events.AfterSaveGame()
	unhide_client_monsters()
end

-- Clear leftover puppets on mapload, in a session or not
function Multiplayer.std_events.LoadMapScripts()
	for i, v in Map.Monsters do
		if v.AIType == PUPPET_AITYPE then
			v.AIState = const.AIState.Removed
		end
	end
end

-- Play attack anim
function events.Action(t)
	if t.Action == 23 then
		Multiplayer.broadcast(packets.play_monster_anim:prep(const.AIState.MeleeAttack), cond_same_map)
	end
end

-- Play fidget anim
function events.PlayerYell()
	Multiplayer.broadcast(packets.play_monster_anim:prep(const.AIState.Fidget), cond_same_map)
end

-- Play stagger anim
function events.CalcDamageToPlayer(t)
	if not Game.Paused then
		Multiplayer.broadcast(packets.play_monster_anim:prep(const.AIState.Stunned), cond_same_map)
	end
end

-- Play spell cast anim
function events.PlayerCastSpell(t)
	for i,v in Party.PlayersIndexes do
		if v == t.PlayerIndex then
			Multiplayer.broadcast(packets.play_monster_anim:prep(const.AIState.MeleeAttack, spell_initsound(t.SpellId)), cond_same_map)
			return
		end
	end
end

-- Ignore damage dealt to service monsters
function events.CalcDamageToMonster(t)
	if posessed_by_player(t.MonsterIndex) then
		t.Result = 0
	end
end

function events.MonsterCanCastSpell(t)
	if posessed_by_player(t.MonsterIndex) then
		t.Result = false
	end
end

function events.MonsterNeedPathfinding(t)
	if posessed_by_player(t.MonsterIndex) then
		t.Result = false
	end
end

function events.BeforeMonsterBolster(t)
	if posessed_by_player(t.Id) then
		t.Handled = true
	end
end

-- Forbid picking up remote player's corpse
function events.PickCorpse(t)
	local ClientId = posessed_by_player(t.MonsterIndex)
	if ClientId then
		t.Allow = false
		Multiplayer.add_to_send_queue(ClientId, packets.corpse_pick_gold:prep())
	end
end

function events.SpeakWithMonster(t)
	local ClientId = posessed_by_player(t.MonsterIndex)
	if ClientId and not Multiplayer.client_info(ClientId).operable then
		Multiplayer.add_to_send_queue(ClientId, packets.corpse_pick_gold:prep())
	end
end

-- Show remote player stats as monster's stats
function events.ClientStatsUpdate(client_id, stats)
	local mon = get_client_mon(client_id)
	if mon then
		mon.HP = stats.HP
		mon.FullHP = stats.FullHP
		mon.Level = stats.LevelBase
		mon.ArmorClass = stats.ArmorClass

		if stats.Operable == 0 then
			Multiplayer.utils.delayed_call(set_player_downstate, 1, client_id)
			--set_player_aistate(client_id, const.AIState.Dead, const.Hour)
		elseif stats.Invisible then
			set_player_aistate(client_id, const.AIState.Invisible, const.Hour)
		end

		Game.PlaceMonTxt[FreePlaceMonTxtStart + client_id] = client_name(client_id)
		mon.NameId = FreePlaceMonTxtStart + client_id
	end

	if stats.house > 0 then
		client_in_house[client_id] = stats.house
	else
		client_in_house[client_id] = nil
	end
end

-- notify about map change
function events.MapLoadingDone()
	if vars and vars.Multiplayer then
		Multiplayer.my_skin = vars.Multiplayer.my_skin or 194
	end
	local data = packets.change_map:prep(Map.MapStatsIndex)
	Multiplayer.broadcast(data)
end

function events.LeaveMap()
	local data = packets.change_map:prep(-1)
	Multiplayer.broadcast(data)
	Multiplayer.sendall() -- ticks are suspended on map load, thus leave map notification should be sent manually

	for k,v in pairs(client_monsters) do
		if v < Map.Monsters.count then
			Map.Monsters[v].AIState = const.AIState.Removed
		end
	end
	client_monsters = {}
end

-- nobody drives a puppet once the session is over
function events.MultiplayerStopped()
	for i, v in Map.Monsters do
		if v.AIType == PUPPET_AITYPE then
			v.AIState = const.AIState.Removed
		end
	end
	client_monsters = {}
	client_in_house = {}
	old_aistate = {}
end

-- remove service monster, when client leaves; the slot is free for the engine to reuse
function events.ClientLeft(client_id, client)
	local monid = client_monsters[client_id]
	if monid and monid < Map.Monsters.count then
		Map.Monsters[monid].AIState = const.AIState.Removed
	end
	client_monsters[client_id] = nil
	client_in_house[client_id] = nil
end

--------------------------------------------
-- House enter/exit

-- special color for player on minimap
Multiplayer.MinimapPlayerColor = RGB(200, 100, 255)

function events.MonsterColorOnMinimap(t)
	if posessed_by_player(t.MonsterIndex) then
		t.Color = Multiplayer.MinimapPlayerColor
	end
end

function events.DrawMinimapInfo()
       local ZoomLevel = u4[0x587ac0] - 7
       if ZoomLevel == 0 or ZoomLevel > 4 then
               return
       end

       local Factor = select(ZoomLevel, 256, 128, 64, 32)

	-- in mm engine dot on minimap is displayed by drawing two lines 1:2 next to each other
	local function DrawLine(X, Y, toX, toY, Color)
		mem.call(0x49e22a, 1, 0xec1980, X, Y, toX, toY, Color)
	end

	local function InsideMinimapFrame(X, Y)
		return X >= i4[0xec199c] and X <= i4[0xec19a4] and Y >= i4[0xec19a0] and Y <= i4[0xec19a8]
	end

	-- contains Minimap frame bounds only during DrawMinimapInfo call
	local mX = i4[0xec199c] + (i4[0xec19a4] - i4[0xec199c]) / 2
	local mY = i4[0xec19a0] + (i4[0xec19a8] - i4[0xec19a0]) / 2

	local function RelativeCoords(mon, factor)
		local X, Y
		X = mX - ((Party.X - mon.X) / factor):ceil()
		Y = mY + ((Party.Y - mon.Y) / factor):ceil()
		return X, Y
	end

	local mon, X, Y
	for _, i in pairs(client_monsters) do
		if i < Map.Monsters.count then
			mon = Map.Monsters[i]
			X, Y = RelativeCoords(mon, Factor)
			if InsideMinimapFrame(X, Y) then
				DrawLine(X, Y, X, Y - 1, Multiplayer.MinimapPlayerColor)
				DrawLine(X + 1, Y, X + 1, Y - 1, Multiplayer.MinimapPlayerColor)
			end
		end
	end
end

--------------------------------------------
-- Action interrupts

function events.Tick()
	for client_id, mon_id in pairs(client_monsters) do
		if mon_id < Map.Monsters.count then
			local mon = Map.Monsters[mon_id]

			if mon.AIState ~= const.AIState.Invisible and mon.AIState ~= const.AIState.Removed and (mon.CurrentActionStep + Game.TimeDelta) >= mon.CurrentActionLength then -- approx
				mon.AIState = 0
				mon.CurrentActionStep = 0
				mon.CurrentActionLength = const.Minute
				mon.GraphicState = AIStateToGraphicState[mon.AIState] or 0
			end
		end
	end
end

--------------------------------------------
-- House enter/exit

local exit_house_checker
exit_house_checker = function()
	if Game.CurrentScreen ~= const.Screens.House then
		Multiplayer.broadcast(packets.exit_house:prep(), cond_same_map)
		Multiplayer.notify_player_position(true)
		events.Remove("Tick", exit_house_checker)
	end
end

function events.EnterHouse(i)
	Multiplayer.broadcast(packets.enter_house:prep(i), cond_same_map)
	events.Tick = exit_house_checker
end

--------------------------------------------

Multiplayer.PUPPET_AITYPE = PUPPET_AITYPE

return {
	PUPPET_AITYPE = PUPPET_AITYPE,
	get_client_mon = get_client_mon,
	client_monsters = get_client_monsters,
	clients_in_houses = clients_in_houses,
	posessed_by_player = posessed_by_player,
	notify_skin_changed = notify_skin_changed,
	set_player_aistate = set_player_aistate,
	set_player_downstate = set_player_downstate,
	play_puppet_sound = play_puppet_sound,
	play_puppet_sound2 = play_puppet_sound2,
	client_name = client_name,
	hide_client_monsters = hide_client_monsters,
	unhide_client_monsters = unhide_client_monsters
}
