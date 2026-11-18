if not mem.dll["ntdll"].NtDelayExecution then
	return -- undocumented function is not supported by this configuration
end

if not mem.dll["ntdll"].NtQuerySystemTime then
	return -- deprecated function is not supported by this configuration
end

local settings = mem.StaticAlloc(20)

-- min update period (nanosec * 100)
local update_period_ptr = settings
mem.u4[update_period_ptr] = 0

-- large integer, timestamp until new frames should not be rendered
local timestamp_ptr = settings + 4

-- large integer, timestamp obtained through NtQuerySystemTime
local current_system_time_ptr = settings + 12

-- Lua hook here barely drops perfomance, but much easier to read and modify, especially regarding qwords comparison
local checkerLua = mem.asmproc([[
nop
nop
nop
nop
nop
retn
]])

local rate, current, nextframe = 0, 0, 0
local NtDelayExecution = mem.dll["ntdll"].NtDelayExecution
local NtQuerySystemTime = mem.dll["ntdll"].NtQuerySystemTime

mem.hook(checkerLua, function(d)
	rate = mem.u4[update_period_ptr]
	if rate == 0 then
		return
	end

	NtQuerySystemTime(current_system_time_ptr)
	current = mem.i8[current_system_time_ptr]
	nextframe = mem.i8[timestamp_ptr]

	if current < nextframe then
		NtDelayExecution(1, timestamp_ptr)
	elseif (current - nextframe) > rate then
		nextframe = current
	end

	mem.i8[timestamp_ptr] = nextframe + rate
end)


local patch = [[
	cmp dword [ds:]] .. update_period_ptr .. [[], 0
	je @nolimit
	call absolute ]] .. checkerLua .. [[;
	@nolimit:
	test byte [ds:0x6f39a5], 1
]]
mem.asmpatch(0x460b71, patch)
mem.asmpatch(0x4612f7, patch)
mem.asmpatch(0x461b36, patch)
mem.asmpatch(0x493f70, patch)

-- Arcomage
mem.asmpatch(0x40b140, [[
	cmp dword [ds:]] .. update_period_ptr .. [[], 0
	je @nolimit
	call absolute ]] .. checkerLua .. [[;
	@nolimit:
	mov ecx, 0x51d338
]])

function Game.SetFrameLimit(n)
	NtQuerySystemTime(timestamp_ptr)
	mem.u4[update_period_ptr] = n > 0 and math.floor(1 / n * 10000000) or 0
end
