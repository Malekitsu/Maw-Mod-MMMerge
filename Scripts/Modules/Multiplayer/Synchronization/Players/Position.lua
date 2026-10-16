local events = Multiplayer.events
local LogEvent = Multiplayer.utils.LogEvent

-- animation

local Animations = {}
local Finished = {}

local function Animate(t)
	local stamp = timeGetTime()
	if stamp >= t.end_time then
		t.obj[t.field] = t.to
		t.active = false
		if t.after then
			t.after()
		end
		return
	end

	local step = stamp - t.start_time
	local shift = math.floor(step / t.length * t.distance)
	t.obj[t.field] = t.from + shift
end

function events.Tick()
	for i, t in pairs(Animations) do
		if t.active then
			local success, err = pcall(Animate, t)
			if not success then
				t.active = false
				LogEvent("PLAYERS_SYNC", "Error while animating object: %s", err)
			end
		else
			table.insert(Finished, i)
		end
	end

	for _, i in pairs(Finished) do
		Animations[i] = nil
	end
	table.clear(Finished)
end

local function AddAnimator(obj, field, from, to, time_msec, acceptor, after)
	local t = acceptor or {}
	local active = acceptor.active

	t.active = true
	t.obj = obj
	t.field = field
	t.start_time = timeGetTime()
	t.end_time = timeGetTime() + time_msec
	t.length = time_msec
	t.distance = to - from
	t.after = after
	t.to = to
	t.from = from

	if not active then
		Animations[tostring(obj) .. field] = t
	end
	return t
end

-----

local u1, u2, u4, r4, i4, u8, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.u8, mem.string, mem.copy, mem.topointer
local sendbuff = Multiplayer.utils.sendbuff
local cond_same_map = Multiplayer.utils.cond_same_map
local nums_to_bin, fill_from_bin = Multiplayer.utils.nums_to_bin, Multiplayer.utils.fill_from_bin

local ServiceMon = Multiplayer.require("Synchronization/Players/Monster.lua")
local ServiceStats = Multiplayer.require("Synchronization/Players/Stats.lua")

local get_client_mon = ServiceMon.get_client_mon
local set_player_aistate = ServiceMon.set_player_aistate
local set_player_downstate = ServiceMon.set_player_downstate
local party_operable = ServiceStats.party_operable

local direction_to_point = Multiplayer.utils.direction_to_point
local distance = Multiplayer.utils.distance

local ACCUMULATION_DELAY = 250 -- milliseconds
local client_pos_schedule = {}
Multiplayer.debug.client_pos_schedule = client_pos_schedule

local party_position_fields = {"X", "Y", "Z", "Direction", "LookAngle", "SpeedX", "SpeedY", "SpeedZ"}

local function read_bin_posdata(bin_string)
	local ptr = toptr(bin_string)
	local pos_data = {}
	local bits = u1[ptr + 2]
	fill_from_bin(pos_data, ptr + 18, party_position_fields, 2, true)
	pos_data.time = u8[ptr+8]
	pos_data.sound = u2[ptr+16]

	pos_data.invisible = bit.And(bits, 1) ~= 0
	pos_data.torch_light = bit.And(bits, 2) ~= 0
	pos_data.operable = bit.And(bits, 4) ~= 0
	pos_data.horizontal_move = bit.And(bits, 8) ~= 0
	pos_data.vertical_move = bit.And(bits, 16) ~= 0
	pos_data.InAir = bit.And(bits, 32) ~= 0
	pos_data.Flying = bit.And(bits, 64) ~= 0

	pos_data.move_speed = u2[ptr + 4]
	pos_data.move_direction = u2[ptr + 6]
	pos_data.torch_light_skill = u1[ptr + 3]
	pos_data.torch_light_changed = false
	pos_data.processed = false
	pos_data.map = u2[ptr]
	return pos_data
end

local packets = {
	player_position = {
		bulb = Multiplayer.utils.item_to_bin,
		handler = function(bin_string, metadata)
			local t = Multiplayer.utils.binstr_to_item(bin_string)
			local arrive_time = Game.Time

			local schedule = {}
			client_pos_schedule[metadata.sender_id] = schedule

			local pos_data, prev_data, base_time
			for i, v in ipairs(t) do
				pos_data = read_bin_posdata(v)
				prev_data = schedule[i - 1]

				if prev_data then
					pos_data.torch_light_changed = prev_data.torch_light ~= pos_data.torch_light
					if pos_data.torch_light_changed and pos_data.torch_light == 0 then
						pos_data.torch_light_skill = 0
					end
				end

				table.insert(schedule, pos_data)
				if not base_time then
					base_time = pos_data.time
				end
				pos_data.time = math.ceil((pos_data.time - base_time) * 0.128) + arrive_time
			end
		end,
		same_map_only = true,
		compress = true,
	}
}
Multiplayer.utils.init_packets(packets)

--------------------------------------------
-- Steps sounds tracker

local PlayRemoteStepSounds

local LastStepSound = 0
local function RegisterStepSound(t)
	LastStepSound = t.Sound
end

events.StepSoundChosen = RegisterStepSound
events.TileSoundChosen = RegisterStepSound

function Multiplayer.std_events.MultiplayerUIInitialized()
	PlayRemoteStepSounds = Multiplayer.GlobalData().PlayRemoteStepSounds
	if PlayRemoteStepSounds == nil then
		PlayRemoteStepSounds = true
		Multiplayer.GlobalData().PlayRemoteStepSounds = true
	end

	local function OnSwitch()
		PlayRemoteStepSounds = Multiplayer.GlobalData().PlayRemoteStepSounds
	end

	local Group = Multiplayer.utils.UI.CustomSettings.Group("Remote sounds", "Remote player sounds")
	Group:Switch("Step sounds:       ", Multiplayer.GlobalData, "PlayRemoteStepSounds", OnSwitch)
end

--------------------------------------------
-- Position sender

local position_send_queue = {}

local function player_position_bin(MoveSpeed, MoveDirection, Operable, InMoveHorizontal, InMoveVertical)
	local bits = 0
	local torch_buff = Party.SpellBuffs[const.PartyBuff.TorchLight]
	if Party.SpellBuffs[const.PartyBuff.Invisibility].ExpireTime > Game.Time then
		bits = 1
	end
	if torch_buff.ExpireTime > Game.Time then
		bits = bit.Or(bits, 2)
	end
	if Operable then
		bits = bit.Or(bits, 4)
	end
	if InMoveHorizontal then
		bits = bit.Or(bits, 8)
	end
	if InMoveVertical then
		bits = bit.Or(bits, 16)
	end
	if Party.InAir then
		bits = bit.Or(bits, 32)
	end
	if Party.Flying then
		bits = bit.Or(bits, 64)
	end

	u2[sendbuff] = Map.MapStatsIndex
	u1[sendbuff+2] = bits
	u1[sendbuff+3] = torch_buff.ExpireTime > Game.Time and torch_buff.Skill or 0
	u2[sendbuff+4] = MoveSpeed
	u2[sendbuff+6] = MoveDirection
	u8[sendbuff+8] = timeGetTime() -- Game.Time
	u2[sendbuff+16] = (Party.Flying or Party.InAir) and 0 or LastStepSound

	return mstr(sendbuff, 18, true) .. nums_to_bin(Party, party_position_fields, 2)
end

local move_speed_mul = 64
Multiplayer.debug.SetPuppetMoveSpeedMul = function(n)
	move_speed_mul = n
end

local last_pos_notification = 0
local last_pos = {X = 0, Y = 0, Z = 0, Direction = 0, DirectionPhase = 0, Time = 0, MoveSpeed = 0, Operable = true}
local function PlayerMovement(ForceSend)
	if Multiplayer.leave_map_halt then
		return
	end

	local DirectionChanged = last_pos.Direction ~= Party.Direction
	if DirectionChanged then
		last_pos.Direction = Direction
	end

	local DirectionPhaseChanged = last_pos.DirectionPhase ~= math.floor(Party.Direction / 256)
	if DirectionPhaseChanged then
		last_pos.DirectionPhase = math.floor(Party.Direction / 256)
	end

	local Horizontal, Vertical = last_pos.X ~= Party.X or last_pos.Y ~= Party.Y, last_pos.Z ~= Party.Z
	local PositionChanged = Horizontal or Vertical
	local MoveDirection = Party.Direction
	local MoveSpeed = 0
	local MoveSpeedChanged = false
	if PositionChanged then
		if last_pos.Time > 0 then
			MoveSpeed = distance(last_pos, Party) / (Game.Time - last_pos.Time)
			MoveSpeed = math.floor(MoveSpeed * move_speed_mul)
			MoveSpeed = math.max(MoveSpeed, 0)
		end
		MoveDirection = Multiplayer.utils.direction_to_point(last_pos, Party)
		XYZ(last_pos, XYZ(Party))
	end
	MoveSpeedChanged = last_pos.MoveSpeed ~= MoveSpeed
	last_pos.MoveSpeed = MoveSpeed
	last_pos.Time = Game.Time

	local PartyOperable = party_operable()
	local NeedSend = ForceSend or os.time() - last_pos_notification > 2 or MoveSpeedChanged or (MoveSpeed > 0 and DirectionChanged) or DirectionPhaseChanged or last_pos.Operable ~= PartyOperable
	last_pos.Operable = PartyOperable

	if NeedSend then
		last_pos_notification = os.time()
		table.insert(position_send_queue, player_position_bin(MoveSpeed, MoveDirection, PartyOperable, Horizontal, Vertical))
	end
end

local PlayerPosQueuer = Multiplayer.utils.TickCounter(PlayerMovement, 4)

Multiplayer.debug.SetPosQueueUpdatePeriod = function(ticks)
	events.Remove("Tick", PlayerPosQueuer)
	PlayerPosQueuer = Multiplayer.utils.TickCounter(PlayerMovement, ticks)
end

local function Sender()
	if #position_send_queue > 0 then
		Multiplayer.broadcast(packets.player_position:prep(position_send_queue), cond_same_map)
		table.clear(position_send_queue)
	end
end
Multiplayer.utils.MillisecCounter(Sender, ACCUMULATION_DELAY)

--------------------------------------------
-- Torch light

local outlights = {}
local client_lights = {}

local function OnMapLoad()
	outlights = {}
	client_lights = {}

	local SpriteLightN = -1
	for sprite_id, sprite in Map.Sprites do
		local DecItem = Game.DecListBin[sprite.DecListId]
		if DecItem.LightRadius > 0 then
			SpriteLightN = SpriteLightN + 1
			if SpriteLightN >= Map.SpriteLights.limit then
				break
			elseif sprite.DecName == "outlight1" then
				table.insert(outlights, {sprite_id = sprite_id, light_id = SpriteLightN, owner = -1})
			end
		end
	end

	local count = math.max(SpriteLightN + 1, Map.SpriteLights.count)
	Map.SpriteLights.count = math.min(count, Map.SpriteLights.limit)
end

events.MultiplayerStarted = OnMapLoad
events.MultiplayerSpritesLoaded = OnMapLoad
events.MapLoadingDone = OnMapLoad

function Multiplayer.debug.client_lights()
	return client_lights, outlights
end

local function get_client_outlight(client_id)
	local outlight = client_lights[client_id]
	if outlight then
		return outlight
	end

	local function find()
		for i, v in pairs(outlights) do
			if (v.owner < 0 or v.owner == client_id) and v.light_id < Map.SpriteLights.limit then
				return v
			end
		end
	end

	local function create()
		if Map.SpriteLights.count == Map.SpriteLights.limit then
			-- cannot create new
			local function taken(i)
				for k, v in pairs(outlights) do
					if v.light_id == i and v.owner >= 0 then
						return true
					end
				end
			end

			local t
			for light_id, light in Map.SpriteLights do
				if not taken(light_id) then
					t = {sprite_id = client_id, light_id = light_id, owner = -1}
					break
				end
			end

			if not t then
				t = {sprite_id = client_id, light_id = Map.SpriteLights.limit + 1, owner = -1}
			end

			ChangeSprite(t.sprite_id, "outlight1")
			local sprite = Map.Sprites[t.sprite_id]
			sprite.Bits = bit.Or(sprite.Bits, Multiplayer.NO_SYNC_OBJECT_BIT)
			return t
		end

		local light_id = Map.SpriteLights.count
		local sprite, sprite_id = CreateSprite{"outlight1", -20000, -20000, -20000}
		sprite.Bits = bit.Or(sprite.Bits, Multiplayer.NO_SYNC_OBJECT_BIT)

		if Map.IsIndoor() then
			Map.SpriteLights.count = Map.SpriteLights.count + 1
		end

		local t = {sprite_id = sprite_id, light_id = light_id, owner = -1}
		table.insert(outlights, t)
		return t
	end

	outlight = find() or create()
	outlight.owner = client_id
	client_lights[client_id] = outlight
	return outlight
end

local function set_torch_light(client_id, point, variant)
	if Multiplayer.leave_map_halt or not Multiplayer.sprites_loaded then
		--LogEvent("PLAYERS_SYNC", "Ignoring remote Torch Light change: leave_map_halt.")
		return
	end

	local light_id = get_client_outlight(client_id).light_id
	if light_id >= Map.SpriteLights.count then
		if Map.IsIndoor() and Map.SpriteLights.count < Map.SpriteLights.limit then
			Map.SpriteLights.count = light_id + 1
		else
			return -- Sprite light have not been created yet.
		end
	end

	local light = Map.SpriteLights[light_id]
	light.Type = Multiplayer.DETACHABLE_LIGHT_TYPE

	if not variant or variant < 1 or variant > 4 then
		light.Radius = 0
	else
		if Map.IsIndoor() then
			light.Radius = select(variant, 512, 768, 1024, 1280)
			light.R = 255
			light.G = 200
			light.B = 120
		else
			if Game.Hour > 6 and Game.Hour < 16 then
				light.Radius = 0
			elseif Game.Weather.Fog then
				light.Radius = select(variant, 256, 384, 512, 640)
			else
				light.Radius = select(variant, 1024, 1536, 2048, 2560)
			end
			light.R = 255
			light.G = 245
			light.B = 230
		end
		XYZ(light, XYZ(point))
		light.Z = light.Z + 192
	end
end

function events.PlayerCastSpell(t)
	if t.SpellId == const.Spells.TorchLight then
		Multiplayer.utils.delayed_call(PlayerMovement, 2, true)
	end
end

function events.ClientChangeMap(client_id, old, new)
	if old == Map.MapStatsIndex then
		LogEvent("PLAYERS_SYNC", "Deactivating torch light on client #%s map leave.", client_id)
		set_torch_light(client_id, nil, 0)
	end
end

function events.ClientLeft(client_id, client)
	set_torch_light(client_id, nil, 0)
end

--------------------------------------------
-- Position setter

local INVIS_COLOR = Multiplayer.utils.SpellSchoolColorsRGB24[1] -- Air
local ActionAnimStates = {
	[const.AIState.MeleeAttack] = true,
	[const.AIState.RangedAttack] = true,
	[const.AIState.Stunned] = true,
	[const.AIState.Fidget] = true,
}
Multiplayer.debug.pos_action_length = 128
Multiplayer.debug.pos_allowed_deviation = 256

Multiplayer.debug.anim_allowed_deviation = 1024
Multiplayer.debug.anim_pos_length = 128
Multiplayer.debug.anim_TB_pos_length = 256
Multiplayer.debug.anim_TB_min_distance = 8
Multiplayer.debug.CustomPosAnim = true

local PuppetAnims = {}

local function animate_movement(client_id, mon, pos_data)
	local allowed_deviation = Multiplayer.debug.anim_allowed_deviation
	local action_length

	if Game.TurnBased then
		action_length = Multiplayer.debug.anim_TB_pos_length
	else
		action_length = Multiplayer.debug.anim_pos_length
	end


	local function stop()
		mon.AIState = const.AIState.Stand
		mon:UpdateGraphicState()
	end

	if not Game.TurnBased and (pos_data.move_speed == 0 or distance(mon, pos_data) > allowed_deviation) then
		XYZ(mon, XYZ(pos_data))
	end

	if pos_data.move_speed > 0 or Game.TurnBased and distance(mon, pos_data) > Multiplayer.debug.anim_TB_min_distance then
		local anims = PuppetAnims[client_id]
		if not anims then
			anims = {X = {}, Y = {}, Z = {}}
			PuppetAnims[client_id] = anims
		end

		for k, v in pairs(anims) do
			AddAnimator(mon, k, mon[k], pos_data[k], action_length, v, Game.TurnBased and stop or nil)
		end
	end

	if pos_data.horizontal_move then
		mon.MoveSpeed = 1
		mon.Direction = Multiplayer.utils.direction_to_point(mon, pos_data)
	else
		mon.MoveSpeed = 0
		mon.Direction = pos_data.Direction
	end

	mon.Velocity = 0
end

local function set_movement(mon, pos_data, next_pos_data)
	local allowed_deviation = Multiplayer.debug.pos_allowed_deviation
	local action_length = Multiplayer.debug.pos_action_length

	if not pos_data.horizontal_move or pos_data.move_speed == 0 or distance(mon, pos_data) > allowed_deviation then
		XYZ(mon, XYZ(pos_data))
	end

	if pos_data.move_speed > 0 and pos_data.horizontal_move then
		if next_pos_data then
			mon.Direction = Multiplayer.utils.direction_to_point(mon, next_pos_data)
			mon.MoveSpeed = distance(mon, next_pos_data) / (next_pos_data.time - pos_data.time) * move_speed_mul
			mon.Velocity = mon.MoveSpeed
		else
			mon.Direction = pos_data.move_direction
			mon.MoveSpeed = pos_data.move_speed * 2
			mon.Velocity = mon.MoveSpeed
		end
	else
		mon.Direction = pos_data.Direction
		mon.MoveSpeed = 0
		mon.Velocity = 0
	end
end

local function set_movement_turnbased(mon, pos_data)
	mon.MoveSpeed = 0
	mon.Velocity = 0

	if distance(pos_data, mon) > 32 then
		local function StdCond()
			return Game.TurnBased
		end

		local anim = Multiplayer.utils.Animate
		local action_length = Multiplayer.debug.pos_action_length

		for k in XYZ do
			if pos_data[k] ~= mon[k] then
				anim(mon, k, pos_data[k] - mon[k], action_length, StdCond)
			end
		end

		mon.Direction = Multiplayer.utils.direction_to_point(mon, pos_data)
		if mon.FramesStand ~= mon.FramesWalk then
			Multiplayer.utils.delayed_call2(function(mon, old)
				mon.FramesStand = old
			end, action_length, mon, mon.FramesStand)
		end
		mon.FramesStand = mon.FramesWalk
	else
		mon.Direction = pos_data.Direction
	end
end

local function pos_player(client_id, pos_data, next_pos_data, mon)
	if pos_data.map ~= Map.MapStatsIndex or ServiceMon.clients_in_houses()[client_id] then
		set_player_aistate(client_id, const.AIState.Invisible, const.Hour)
		return
	end

	mon = mon or get_client_mon(client_id)
	if not mon then
		local client = Multiplayer.connector.clients[client_id]
		LogEvent("PLAYERS_SYNC", "Received pos info from client #%s, cannot create monster: my map - %s, his map - %s", client_id, Map.MapStatsIndex, client and client.map or 'nil')
		return
	end

	if pos_data.invisible and pos_data.operable then
		XYZ(mon, XYZ(pos_data))
		set_torch_light(client_id, mon, 0)
		set_player_aistate(client_id, const.AIState.Invisible, const.Hour)
		mon:ShowSpellEffect(INVIS_COLOR)
		return
	end
	set_torch_light(client_id, mon, pos_data.torch_light_skill)

	if not pos_data.operable then
		XYZ(mon, XYZ(pos_data))
		set_player_downstate(client_id)
		return
	end

	if Multiplayer.debug.CustomPosAnim then
		animate_movement(client_id, mon, pos_data)
	elseif Game.TurnBased then
		set_movement_turnbased(mon, pos_data)
	else
		set_movement(mon, pos_data, next_pos_data)
	end

	mon.VelocityX = pos_data.SpeedX
	mon.VelocityY = pos_data.SpeedY
	mon.VelocityZ = pos_data.SpeedZ
	mon.Fly = pos_data.Flying and 1 or 0

	if pos_data.Flying then
		mon.LookAngle = pos_data.LookAngle
		if math.abs(pos_data.move_direction - pos_data.Direction) > 1000 then
			mon.LookAngle = -mon.LookAngle
		end
	else
		mon.LookAngle = 0
	end

	if Map.IsIndoor() then
		mon.Room = Map.RoomFromPoint(mon.X, mon.Y, mon.Z + mon.BodyHeight / 2)
	end

	if not (ActionAnimStates[mon.AIState] and mon.CurrentActionStep < mon.CurrentActionLength) then
		set_player_aistate(client_id, mon.MoveSpeed > 0 and const.AIState.Active or const.AIState.Stand, Multiplayer.debug.pos_action_length)
	end

	if PlayRemoteStepSounds and pos_data.sound > 0 and mon.MoveSpeed > 0 then
		Multiplayer.Audio.PlayStepSound(pos_data.sound, client_id)
		--local service_sprite = get_client_outlight(client_id)
		--XYZ(Map.Sprites[service_sprite.sprite_id], XYZ(mon))
		--ServiceMon.play_puppet_sound(pos_data.sound, bit.lshift(service_sprite.sprite_id, 3) + 5, nil, true)
	end
end

local function PositionSetter()
	for client_id, schedule in pairs(client_pos_schedule) do
		local client_info = ServiceStats.client_info(client_id)
		if not client_info then
			client_pos_schedule[client_id] = nil
			return
		end

		if next(schedule) then
			for i, pos_data in ipairs(schedule) do
				if not pos_data.processed and Game.Time >= pos_data.time then
					client_info.map = pos_data.map
					client_info.invisible = pos_data.invisible
					pos_player(client_id, pos_data, schedule[i+1])
					pos_data.processed = true
					processed = true
					break
				end
			end
		else
			set_player_aistate(client_id, const.AIState.Stand, Multiplayer.debug.pos_action_length)
		end
	end
end
Multiplayer.utils.TickCounter(PositionSetter, 1)

return {
	notify_player_position = PlayerMovement
}
