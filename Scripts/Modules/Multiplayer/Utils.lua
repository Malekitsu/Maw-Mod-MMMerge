local u1, u2, u4, i4, r4, r8, i8 = mem.u1, mem.u2, mem.u4, mem.i4, mem.r4, mem.r8, mem.i8
local mstr = mem.string
local sqrt, abs, asin, rad = math.sqrt, math.abs, math.asin, math.rad
local floor, ceil = math.floor, math.ceil
local tinsert = table.insert

local utils = {}
Multiplayer.utils = utils

local AIStateToGraphicState = {
	[const.AIState.Stand] = 0,
	[const.AIState.Active] = 1,
	[const.AIState.MeleeAttack] = 2,
	[const.AIState.RangedAttack] = 3,
	[const.AIState.Dying] = 5, -- dying
	[const.AIState.Dead] = 6, -- dead
	[const.AIState.Stunned] = 4, -- take damage
	[const.AIState.Fidget] = 7, -- fidget
}
utils.AIStateToGraphicState = AIStateToGraphicState

local AIStateToFramesId = {
	[const.AIState.Stand] = 0,
	[const.AIState.Active] = 1,
	[const.AIState.MeleeAttack] = 2,
	[const.AIState.RangedAttack] = 3,
	[const.AIState.Dying] = 5,
	[const.AIState.Dead] = 6,
	[const.AIState.Pursue] = 1,
	[const.AIState.Flee] = 1,
	[const.AIState.Stunned] = 4,
	[const.AIState.Fidget] = 7,
	[const.AIState.Interact] = 0,
	[const.AIState.Removed] = nil,
	[const.AIState.RangedAttack2] = 3,
	[const.AIState.CastSpell] = 3,
	[const.AIState.Stoned] = 0,
	[const.AIState.Paralyzed] = 0,
	[const.AIState.Resurrect] = nil,
	[const.AIState.Summoned] = nil,
	[const.AIState.RangedAttack4] = 3,
	[const.AIState.Invisible] = nil,
}
utils.AIStateToFramesId = AIStateToFramesId

local ConditionNames = { -- GlobalTxt indexes
	[const.Condition.Cursed]	= 52,
	[const.Condition.Weak]		= 241,
	[const.Condition.Asleep]	= 14,
	[const.Condition.Afraid]	= 4,
	[const.Condition.Drunk]		= 69,
	[const.Condition.Insane]	= 117,
	[const.Condition.Poison1]	= 166,
	[const.Condition.Disease1]	= 65,
	[const.Condition.Poison2]	= 166,
	[const.Condition.Disease2]	= 65,
	[const.Condition.Poison3]	= 166,
	[const.Condition.Disease3]	= 65,
	[const.Condition.Paralyzed]	= 162,
	[const.Condition.Unconscious]	= 231,
	[const.Condition.Dead]	= 58,
	[const.Condition.Stoned]	= 220,
	[const.Condition.Eradicated]	= 76,
	[18] = 98 -- Good
}
utils.ConditionNames = ConditionNames

local PartyBuffNames = { -- Game.SpellsTxt[X].Name
	[const.PartyBuff.AirResistance] = 14,
	[const.PartyBuff.BodyResistance] = 69,
	[const.PartyBuff.DayOfGods] = 83,
	[const.PartyBuff.DetectLife] = 45,
	[const.PartyBuff.EarthResistance] = 36,
	[const.PartyBuff.FeatherFall] = 13,
	[const.PartyBuff.FireResistance] = 3,
	[const.PartyBuff.Fly] = 21,
	[const.PartyBuff.Haste] = 5,
	[const.PartyBuff.Heroism] = 51,
	[const.PartyBuff.Immolation] = 8,
	[const.PartyBuff.Invisibility] = 19,
	[const.PartyBuff.MindResistance] = 58,
	[const.PartyBuff.ProtectionFromMagic] = 75,
	[const.PartyBuff.Shield] = 17,
	[const.PartyBuff.Stoneskin] = 38,
	[const.PartyBuff.TorchLight] = 1,
	[const.PartyBuff.WaterResistance] = 25,
	[const.PartyBuff.WaterWalk] = 27,
	[const.PartyBuff.WizardEye] = 12
}
utils.PartyBuffNames = PartyBuffNames

local PlayerBuffNames = { -- Game.SpellsTxt[X].Name
	[const.PlayerBuff.AirResistance] = 14,
	[const.PlayerBuff.Bless] = 46,
	[const.PlayerBuff.BodyResistance] = 69,
	[const.PlayerBuff.EarthResistance] = 36,
	[const.PlayerBuff.Fate] = 47,
	[const.PlayerBuff.FireResistance] = 3,
	[const.PlayerBuff.Glamour] = 100,
	[const.PlayerBuff.Hammerhands] = 73,
	[const.PlayerBuff.Haste] = 5,
	[const.PlayerBuff.Heroism] = 51,
	[const.PlayerBuff.Levitate] = 112,
	[const.PlayerBuff.MindResistance] = 58,
	[const.PlayerBuff.Misform] = 112,
	[const.PlayerBuff.PainReflection] = 95,
	[const.PlayerBuff.Preservation] = 50,
	[const.PlayerBuff.Regeneration] = 71,
	[const.PlayerBuff.Shield] = 17,
	[const.PlayerBuff.Stoneskin] = 38,
	[const.PlayerBuff.WaterBreathing] = 27,
	[const.PlayerBuff.WaterResistance] = 25
}
utils.PlayerBuffNames = PlayerBuffNames

local SpellSchoolColorsStr = {
	[0] = StrColor(255, 150, 0), -- Fire
	[1] = StrColor(170, 170, 255), -- Air
	[2] = StrColor(0, 150, 255), -- Water
	[3] = StrColor(160, 100, 20), -- Earth
	[4] = StrColor(255, 255, 255), -- Spirit
	[5] = StrColor(200, 255, 160), -- Mind
	[6] = StrColor(255, 200, 160), -- Body
	[7] = StrColor(255, 255, 10), -- Light
	[8] = StrColor(200, 50, 255), -- Dark
	[9] = StrColor(255, 150, 150), -- Dark Elf
	[10] = StrColor(255, 50, 200), -- Vampire
	[11] = StrColor(255, 20, 20), -- Dragon
}
utils.SpellSchoolColorsStr = SpellSchoolColorsStr

local function RGB24(r,g,b)
	return b + bit.lshift(g, 8) + bit.lshift(r, 16)
end
utils.RGB24 = RGB24

local function ConnColor(str, n)
	if n == 1 then -- green
		return StrColor(0,255,0) .. str .. StrColor(255,255,255)
	elseif n == 2 then -- yellow
		return StrColor(255,255,0) .. str .. StrColor(255,255,255)
	else -- red
		return StrColor(255,0,0) .. str .. StrColor(255,255,255)
	end
end
utils.ConnStatusColor = ConnColor

local SpellSchoolColorsRGB24 = {
	[0] = RGB24(255, 150, 0), -- Fire
	[1] = RGB24(170, 170, 255), -- Air
	[2] = RGB24(0, 150, 255), -- Water
	[3] = RGB24(160, 100, 20), -- Earth
	[4] = RGB24(255, 255, 255), -- Spirit
	[5] = RGB24(200, 255, 160), -- Mind
	[6] = RGB24(255, 200, 160), -- Body
	[7] = RGB24(255, 255, 10), -- Light
	[8] = RGB24(200, 50, 255), -- Dark
	[9] = RGB24(255, 150, 150), -- Dark Elf
	[10] = RGB24(255, 50, 200), -- Vampire
	[11] = RGB24(255, 20, 20), -- Dragon
}
utils.SpellSchoolColorsRGB24 = SpellSchoolColorsRGB24

local function boolnum(v)
	return tonumber(v) or (v and 1 or 0)
end

local function school_by_spell(spell_id)
	return ((spell_id-1) / 11):floor()
end
utils.school_by_spell = school_by_spell

local sendbuff = mem.StaticAlloc(8192)
utils.sendbuff_size = 8192
utils.sendbuff = sendbuff

local function tkeys(t)
	local keys = {}
	for k, v in pairs(t) do
		tinsert(keys, k)
	end
	table.sort(keys)
	return keys
end
utils.tkeys = tkeys

local function fill_table(dest, src, keysfrom)
	for k, _ in pairs(keysfrom) do
		dest[k] = src[k]
	end
end
utils.fill_table = fill_table

local field_size_to_f = {1, 2, 4, 4, 8, 8, 8, 8}
local function num_to_hexstr(num, field_size)
	local ux = mem["u" .. tostring(field_size_to_f[field_size or 4])]
	ux[sendbuff] = boolnum(num)
	return mstr(sendbuff, field_size or 4, true)
end
utils.num_to_hexstr = num_to_hexstr

local function num_from_hexstr(str, field_size, signed)
	local ux = mem[(signed and "i" or "u") .. tostring(field_size_to_f[field_size or 4])]
	return ux[mem.topointer(str)]
end
utils.num_from_hexstr = num_from_hexstr

function utils.num_array_to_bin(t, item_size)
	local ux = mem['u' .. tostring(item_size)]
	local pos = 0
	for i, v in ipairs(t) do
		ux[sendbuff + pos] = v
		pos = pos + item_size
	end
	return mstr(sendbuff, pos, true)
end

function utils.bin_to_num_array(binstr, item_size, signed)
	local ptr = mem.topointer(binstr)
	local ux = mem[(signed and 'i' or 'u') .. tostring(item_size)]
	local t = {}
	for i = 0, #binstr - item_size, item_size do
		table.insert(t, ux[ptr + i])
	end
	return t
end

local function nums_to_bin(t, fields, field_size)
	local pos = 0
	local ux = mem['u' .. tostring(field_size)]
	for _, k in ipairs(fields) do
		ux[sendbuff + pos] = boolnum(t[k])
		pos = pos + field_size
	end
	return mstr(sendbuff, pos, true)
end
utils.nums_to_bin = nums_to_bin

local function fill_from_bin(t, data, fields, field_size, signed)
	local ux
	if signed then
		ux = mem['i' .. tostring(field_size)]
	else
		ux = mem['u' .. tostring(field_size)]
	end

	for i, k in ipairs(fields) do
		t[k] = ux[data + (i-1) * field_size]
	end
	return t
end
utils.fill_from_bin = fill_from_bin

local function fetch_field_bin(field, data, fields, field_size, signed)
	local i = table.find(fields, field)
	local u = signed and mem["i" .. field_size] or mem["u" .. field_size]
	return u[data + (i-1) * field_size]
end
utils.fetch_field_bin = fetch_field_bin

local function mmt_dump(t)
	return mstr(t["?ptr"], t["?size"], true)
end
utils.mmt_dump = mmt_dump

local function mon_index_from_ptr(mon)
	return (mon['?ptr'] - Map.Monsters[0]['?ptr']) / mon['?size']
end
utils.mon_index_from_ptr = mon_index_from_ptr

-- Positioning

local function distance(from, to)
	local px, py, pz = XYZ(from)
	local x, y, z = XYZ(to)
	return sqrt((px-x)^2 + (py-y)^2 + (pz-z)^2)
end
utils.distance = distance

local function distanceXY(from, to)
	local px, py, pz = XYZ(from)
	local x, y, z = XYZ(to)
	return sqrt((px-x)^2 + (py-y)^2)
end
utils.distanceXY = distanceXY

local function direction_to_point(to, from)
	local X, Y = from.X - to.X, from.Y - to.Y
	local angle = asin(abs(Y) / sqrt(X^2 + Y^2)) * 512 / rad(90)

	if X < 0 and Y < 0 then
		angle = angle + 1024
	elseif X < 0 and Y >= 0 then
		angle = 1024 - angle
	elseif X >= 0 and Y < 0 then
		angle = 2048 - angle
	end

	return floor(angle)
end
utils.direction_to_point = direction_to_point

local function direction_to_degrees(dir)
	return dir / 2048 * 360
end
utils.direction_to_degrees = direction_to_degrees

local function direction_from_degrees(angle)
	return angle * 2048 / 360
end
utils.direction_from_degrees = direction_from_degrees

local function step_from_point(point, length, direction)
	local angle = math.rad(direction_to_degrees(direction))
	local result = {
		X = ceil(point.X + length * math.cos(angle)),
		Y = ceil(point.Y + length * math.sin(angle)),
		Z = point.Z}

	return result
end
utils.step_from_point = step_from_point

local function Animate(Parent, Field, Amount, Time, Condition)
	local function f(Parent, Field, From, To, Time, Condition)
		local TimeStep = 8
		local Step

		local ValLeft = Amount
		local TimeLeft = Time

		TimeLeft = TimeLeft - TimeStep
		while TimeLeft >= TimeStep do
			if Condition and not Condition() then
				return
			end

			Step = (ValLeft / TimeLeft * TimeStep):ceil()
			Parent[Field] = Parent[Field] + Step

			ValLeft = ValLeft - Step
			TimeLeft = TimeLeft - TimeStep

			Sleep(TimeStep, TimeStep)
		end
		Parent[Field] = Parent[Field] + ValLeft
	end

	local co = coroutine.create(f)
	return coroutine.resume(co, Parent, Field, From, To, Time, Condition)
end
utils.Animate = Animate

-- Lua objects to bin (does not support cross- and selfreferences)

local type_codes = {boolean = 1, number = 2, float = 3, string = 4, table = 5, long = 6, double = 7, ["nil"] = 8}
local function type_code(val)
	local val_type = type(val)
	local code = type_codes[val_type]
	if code == 2 then
		if val ~= val:floor() then
			code = 7
		else
			code = (val >= -0x80000000 and val < 0x80000000) and 2 or 6
		end
	end
	return code
end

local conv_buff = mem.StaticAlloc(8)
local type_encoder = {}
local type_decoder = {}

local function item_to_bin(val)
	local type_code = type_code(val)
	if not type_code then -- happens with special objects of ffi and socket
		utils.LogEvent("INTERNAL", "[ERROR] Attempt to serialize unsupported type of object: %s - %s", val, type(val))
		return ''
	else
		return type_encoder[type_code](val)
	end
end
utils.item_to_bin = item_to_bin

local function bin_to_item(data)
	local type_code = u1[data]
	return type_decoder[type_code](data)
end
utils.bin_to_item = bin_to_item

do
	type_encoder[1] = function(v)
		return '\1' .. (v and '\1' or '\0')
	end
	type_encoder[2] = function(v)
		u4[conv_buff] = v
		return '\2' .. mstr(conv_buff, 4, true)
	end
	type_encoder[3] = function(v)
		r4[conv_buff] = v
		return '\3' .. mstr(conv_buff, 4, true)
	end
	type_encoder[4] = function(str)
		u4[conv_buff] = #str
		return '\4' .. mstr(conv_buff, 4, true) .. str
	end
	type_encoder[5] = function(val)
		local data = {[1] = '\5', [2] = ''}
		local field_type, key_type
		local fields_count = 0
		for k, v in pairs(val) do
			fields_count = fields_count + 1
			tinsert(data, item_to_bin(k))
			tinsert(data, item_to_bin(v))
		end
		u4[conv_buff] = fields_count
		data[2] = mstr(conv_buff, 4, true)
		return table.concat(data, "")
	end
	type_encoder[6] = function(v)
		i8[conv_buff] = v
		return '\6' .. mstr(conv_buff, 8, true)
	end
	type_encoder[7] = function(v)
		r8[conv_buff] = v
		return '\7' .. mstr(conv_buff, 8, true)
	end
	type_encoder[8] = function(v)
		return '\8'
	end

	type_decoder[1] = function(ptr)
		return u1[ptr+1] == 1, 2
	end
	type_decoder[2] = function(ptr)
		return i4[ptr+1], 5
	end
	type_decoder[3] = function(ptr)
		return r4[ptr+1], 5
	end
	type_decoder[4] = function(ptr)
		return mstr(ptr+5, u4[ptr+1], true), 5 + u4[ptr+1]
	end
	type_decoder[5] = function(data)
		local result = {}
		local pos = data + 5
		local key, value, size
		for i = 1, u4[data+1] do
			key, size = bin_to_item(pos)
			pos = pos + size
			value, size = bin_to_item(pos)
			pos = pos + size
			result[key] = value
		end
		return result, (pos - data)
	end
	type_decoder[6] = function(ptr)
		return i8[ptr+1], 9
	end
	type_decoder[7] = function(ptr)
		return r8[ptr+1], 9
	end
	type_decoder[8] = function(v)
		return nil, 1
	end

end

local function binstr_to_item(str)
	return bin_to_item(mem.topointer(str))
end
utils.binstr_to_item = binstr_to_item

---- Broadcast conditions

local function cond_same_map(client)
	return client.map == Map.MapStatsIndex
end
utils.cond_same_map = cond_same_map

---- Sounds

local function spell_initsound(spell_id)
	spell_id = spell_id - 1
	local id = spell_id % 11
	local spell_school = (spell_id / 11):floor()
	return 10000 + spell_school * 1000 + id * 10
end
utils.spell_initsound = spell_initsound

---- Objects

local function object_otref(object, field)
	local val = object[field]

	-- first 3 bits encode kind
	local target_ref = bit.And(val, 7)

	-- next bits encode id
	local target_id = bit.rshift(val, 3)

	return target_ref, target_id
end
utils.object_otref = object_otref

local function ref_num(kind, id)
	return bit.lshift(id, 3) + kind
end
utils.ref_num = ref_num

local function split_ref(ref)
	return bit.And(ref, 7), bit.rshift(ref, 3)
end
utils.split_ref = split_ref

local function object_owner(object)
	return object_otref(object, 'Owner')
end
utils.object_owner = object_owner

local function object_target(object)
	return object_otref(object, 'Target')
end
utils.object_target = object_target

---- Monsters

local function CurrentPlayer()
	return math.min(math.max(Game.CurrentPlayer, 0), Party.count - 1)
end
utils.CurrentPlayer = CurrentPlayer

local function play_mon_sound(mon)
	local AIStateToSound = {
		[const.AIState.MeleeAttack] = "Attack",
		[const.AIState.RangedAttack] = "Attack",
		[const.AIState.RangedAttack2] = "Attack",
		[const.AIState.RangedAttack3] = "Attack",
		[const.AIState.RangedAttack4] = "Attack",
		[const.AIState.CastSpell] = "Attack",
		[const.AIState.Stunned] = "GotHit",
		[const.AIState.Dying] = "Die",
	}

	if AIStateToSound[mon.AIState] then
		mon:PlaySound(AIStateToSound[mon.AIState])
	end
end
utils.play_mon_sound = play_mon_sound

---- Screens

local function ExitToScreen0(After, AfterParam)
	local attempt = 0
	local function f()
		if Game.CurrentScreen == 0 then
			After(AfterParam)
			return
		elseif attempt < 10 and Game.CurrentScreen ~= 0 then
			ExitCurrentScreen()
			attempt = attempt + 1
		end
		Multiplayer.utils.delayed_call(f, 4)
	end
	Multiplayer.utils.delayed_call(f, 4)
end
utils.ExitToScreen0 = ExitToScreen0

---- Delayed calls and Timers

local function SetBGTimer(f, period)
	local events = Multiplayer.events
	events.MapLoadingDone = function() Timer(f, period) end
	events.MultiplayerStarted = function() Timer(f, period) end
	events.MultiplayerStopped = function() pcall(RemoveTimer, f) end
end
utils.SetBGTimer = SetBGTimer

local TickTimers = {}

local function AddTickTimer(f, bits) -- bits: 0x1 - keep in table on multiplayer stop, 0x2 - millisec timer
	if TickTimers[f] then
		error("Tick timer already set!")
	end
	TickTimers[f] = bits
end
local function RemoveTickTimer(f)
	local r = TickTimers[f]
	TickTimers[f] = nil
	return r
end
function events.MultiplayerInitialized()
	function Multiplayer.events.Tick()
		for f, bits in pairs(TickTimers) do
			if bit.And(bits, 2) == 0 then f() end
		end
	end
	function Multiplayer.events.NetworkCycle()
		for f, bits in pairs(TickTimers) do
			if bit.And(bits, 2) == 2 then f() end
		end
	end
end
function events.MultiplayerStopped()
	local to_remove = {}
	for f, mode in pairs(TickTimers) do
		if bit.And(mode, 1) == 0 then
			table.insert(to_remove, f)
		end
	end
	for _, f in pairs(to_remove) do
		TickTimers[f] = nil
	end
end

local function delayed_call(f, ticks_to_skip, arg1, arg2, arg3)
	assert(f)

	local caller, skip_count

	skip_count = ticks_to_skip
	caller = function()
		if skip_count > 0 then
			skip_count = skip_count - 1
		else
			f(arg1, arg2, arg3)
			RemoveTickTimer(caller)
		end
	end
	AddTickTimer(caller, 0)
end
utils.delayed_call = delayed_call

local function delayed_call2(f, msecs_to_skip, arg1, arg2, arg3)
	assert(f)

	local caller
	local calltime = timeGetTime() + msecs_to_skip

	caller = function()
		if timeGetTime() >= calltime then
			f(arg1, arg2, arg3)
			RemoveTickTimer(caller)
		end
	end
	AddTickTimer(caller, 2)
end
utils.delayed_call2 = delayed_call2

local function TickCounter(f, period)
	if period <= 1 then
		Multiplayer.events.Tick = f
		return f
	end

	local tick_count = 0
	local counter = function()
		tick_count = tick_count + 1
		if tick_count >= period then
			tick_count = 0
			f()
		end
	end
	AddTickTimer(counter, 1)
	return counter
end
utils.TickCounter = TickCounter

local function CoTickCounter(co, period)
	assert(type(co) == "thread")

	local tick_count = 0
	local function counter()
		tick_count = tick_count + 1
		if tick_count >= period then
			tick_count = 0
			assert(coroutine.resume(co))
			if coroutine.status(co) == "dead" then
				assert(RemoveTickTimer(counter))
			end
		end
	end
	AddTickTimer(counter, 1)
	return counter
end
utils.CoTickCounter = CoTickCounter

local function MillisecCounter(f, period)
	local nextcall = timeGetTime() + period
	local function counter()
		if timeGetTime() >= nextcall then
			nextcall = timeGetTime() + period
			f()
		end
	end
	AddTickTimer(counter, 3)
	return counter
end
utils.MillisecCounter = MillisecCounter

local function CoMillisecCounter(co, period)
	assert(type(co) == "thread")

	local nextcall = timeGetTime() + period
	local function counter()
		if timeGetTime() >= nextcall then
			nextcall = timeGetTime() + period
			if coroutine.status(co) == "dead" then
				assert(RemoveTickTimer(counter))
			else
				assert(coroutine.resume(co))
			end
		end
	end
	AddTickTimer(counter, 3)
	return counter
end
utils.CoMillisecCounter = CoMillisecCounter

local function TickChecker(f, period, condition)
	if not condition then
		delayed_call(f, period)
		return
	end

	local tick_count = 0
	local function checker()
		tick_count = tick_count + 1
		if tick_count >= period then
			tick_count = 0
			if condition() then
				f()
				assert(RemoveTickTimer(checker))
			end
		end
	end
	AddTickTimer(checker, 0)
end
utils.TickChecker = TickChecker

local function HandleEventOnce(event_name, handler)
	local function f(...)
		handler(...)
		events.Remove(event_name, f)
	end
	events[event_name] = f
	return f
end
utils.HandleEventOnce = HandleEventOnce

---- Log extension

utils.LogEventsLevel = Merge.Log.Error

local EnabledEvents = {}
local function SetEventLogging(EventName, State)
	EnabledEvents[EventName] = State
end
utils.SetEventLogging = SetEventLogging

local function LogEvent(EventName, TemplateStr, ...)
	if EnabledEvents[EventName] then
		local msg = TemplateStr:format(...)
		Log(utils.LogEventsLevel, "[%s]%s %s: %s", EventName, Multiplayer.in_game and "" or " (multiplayer off)", os.date("%H:%M:%S"), msg)
		-- Merge.Log.LogFile:flush()
	end
end
utils.LogEvent = LogEvent

---- Address conversions

local function toipv4(hexstr)
	local function numhex(str)
		return tonumber('0x' .. str)
	end

	local parts = {numhex(hexstr:sub(1,2)), numhex(hexstr:sub(3,4)), numhex(hexstr:sub(5,6)), numhex(hexstr:sub(7,8))}
	return table.concat(parts, '.')
end
utils.toipv4 = toipv4

local function ipv4bin(addrs)
	assert(type(addrs) == 'table' or type(addrs) == 'string')

	local function f(addr, result)
		for i, v in ipairs{addr:match("(%d*).(%d*).(%d*).(%d*)")} do
			table.insert(result, bit.tohex(v, 2))
		end
	end

	local result = {}
	if type(addrs) == 'table' then
		for i, addr in ipairs(addrs) do
			f(addr, result)
		end
	else
		f(addrs, result)
	end

	return table.concat(result, '')
end
utils.ipv4bin = ipv4bin

local function r4asint(n)
	mem.r4[sendbuff] = n
	return mem.u4[sendbuff]
end
utils.r4asint = r4asint

---- Circular list

local function NewCycleList(size, fill)
	local list = {pos = 0, filled = 0, max = size}
	if fill then
		list.filled = size
		for i = 1, size do
			list[i] = fill
		end
	end

	function list.add(self, val)
		if self.pos >= self.max then
			self.pos = 0
		end
		self.pos = self.pos + 1
		self.filled = math.max(self.filled, self.pos)
		self[self.pos] = val
	end

	function list.last(self)
		return self[self.pos]
	end

	function list.ipairs(self)
		local it = self.pos + 1
		local limit = self.filled
		return function()
			if limit <= 0 then
				return nil, nil
			elseif it > self.filled then
				it = 1
			end
			it = it + 1
			limit = limit - 1
			return it - 1, self[it - 1]
		end
	end

	function list.ripairs(self)
		local it = self.pos
		local limit = self.filled
		return function()
			if limit <= 0 then
				return nil, nil
			elseif it < 1 then
				it = self.filled
			end
			it = it - 1
			limit = limit - 1
			return it + 1, self[it + 1]
		end
	end

	function list.clear(self)
		self.pos = 0
		self.filled = 0
	end

	return list
end
utils.NewCycleList = NewCycleList
