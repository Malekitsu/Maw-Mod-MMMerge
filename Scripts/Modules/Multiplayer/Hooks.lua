local i1, u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.i1, mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local sendbuff = Multiplayer.utils.sendbuff

local code_backup = {}
local hook_code = {}
local event_handlers = {}

local hooks_on = false

local std_events = events
local events = {
	call = std_events.call,
	Call = std_events.call,
	Remove = function(list, f)
		if event_handlers[list] then
			event_handlers[list][f] = nil
		end
		return std_events.Remove(list, f)
	end,
	Once = Multiplayer.utils.HandleEventOnce
}

local function event_handler(event_name, f)
	local handlers = event_handlers[event_name]
	if not handlers then
		handlers = {}
		event_handlers[event_name] = handlers
	end
	handlers[f] = true

	if hooks_on then
		std_events[event_name] = f
	end
end
Multiplayer.event_handler = event_handler

setmetatable(events, {
	__newindex = function(t, key, val)
		event_handler(key, val)
	end,
	__index = function(t, key)
		return std_events[key]
	end
})

Multiplayer.std_events = std_events
Multiplayer.events = events

local function mulhook(addr, backup_size, htype, f)
	local hookf = htype == 2 and mem.autohook2 or mem.autohook

	mem.IgnoreProtection(true)
	code_backup[addr] = mstr(addr, backup_size, true)
	hookf(addr, f)
	hook_code[addr] = mstr(addr, backup_size, true)
	mem.IgnoreProtection(false)
end

local function enable_hooks()
	if hooks_on then
		return
	end

	mem.IgnoreProtection(true)
	for addr, code in pairs(hook_code) do
		code_backup[addr] = mem.string(addr, #code, true)
		mcopy(addr, code, #code)
	end
	mem.IgnoreProtection(false)

	for event, handlers in pairs(event_handlers) do
		for handler, _ in pairs(handlers) do
			while std_events.Remove(event, handler) do end
			std_events[event] = handler
		end
	end
	hooks_on = true
end
Multiplayer.enable_hooks = enable_hooks

local function disable_hooks()
	mem.IgnoreProtection(true)
	for addr, code in pairs(code_backup) do
		mcopy(addr, code, #code)
	end
	mem.IgnoreProtection(false)

	for event, handlers in pairs(event_handlers) do
		for handler, _ in pairs(handlers) do
			while std_events.Remove(event, handler) do end
		end
	end
	hooks_on = false
end
Multiplayer.disable_hooks = disable_hooks

local function asmpatch_backup(size, ptr, code)
	code_backup[ptr] = mstr(ptr, size, true)
	local new_ptr = mem.asmpatch(ptr, code)
	hook_code[ptr] = mstr(ptr, size, true)
	return new_ptr
end

local function asmhook_backup(size, ptr, code)
	code_backup[ptr] = mstr(ptr, size, true)
	local new_ptr = mem.asmhook(ptr, code)
	hook_code[ptr] = mstr(ptr, size, true)
	return new_ptr
end

-- prevent monster's with custom AI handle (AIState == 3, MoveType == 3) from fleeing of player's yell
local function GetMonster(p)
	if p >= Map.Monsters["?ptr"] and p < Map.Monsters["?ptr"] + Map.Monsters["?size"] then
		local i = ((p - Map.Monsters["?ptr"]) / Map.Monsters[0]["?size"]):floor()
		return Map.Monsters[i], i
	end
end

-- selection mode (used to alter spells selection mode)
const.SelectionMode = {
	Player = 2,
	Monster = 8,
	Interaction = 0x40,
	PlayerOrMonster = 0x100
}

mulhook(0x4ce151, 5, 1, function(d)
	local t = {mode = u4[d.ebp+8]}
	events.call("ChooseSelectionMode", t)

	u4[d.ebp+8] = t.mode
	d.eax = t.mode
end)

-- process all player spells for any target type
mulhook(0x42606b, 5, 1, function(d)
	local t = {allow = d.ZF, target_ref = u2[0x51d82c], spell_id = u2[0x51d820]}
	events.call("CanProcessSpell", t)

	d.ZF = t.allow
	if t.allow then
		u2[0x51d82c] = t.target_ref
	end
end)

-- evt broadcast
mulhook(0x443895, 5, 2, function(d)
	-- d.ecx - command id - 1
	-- d.esi - ptr to command info

	local evt_id = i1[d.esi + 4]
	if evt_id <= 0 then
		return
	end

	local t = {
		evt_id = evt_id,
		params = d.esi + 5,
		Handled = false
	}

	events.call("EvtCommandCall", t)

	if t.Handled then
		d.ecx = 0xFFFFFFFF
	end
end)

-- trigger facet event
mulhook(0x472580, 5, 1, function(d)
	events.call("FacetEventActivation", mem.u4[d.ebp - 0x24])
end)

-- pause
mulhook(0x42475d, 5, 2, function(d)
	local t = {allow = true}
	events.call("SettingPause", t)

	if not t.allow then
		d:push(0x42476c)
		return true
	end
end)

mulhook(0x492b2a, 5, 2, function(d)
	local t = {Handled = false, Player = d.eax}
	events.call("CanSwitchCharacter", t)

	if t.Handled then
		d:push(0x492b34)
		return true
	end
end)

-- disable pause on minimize
u1[sendbuff] = 0xeb
mem.IgnoreProtection(true)
code_backup[0x4612fe] = mstr(0x4612fe, 1, true)
hook_code[0x4612fe] = mstr(sendbuff, 1, true)
mem.IgnoreProtection(false)

-- increase monster move speed limit
u4[sendbuff] = 2048
mem.IgnoreProtection(true)
code_backup[0x46f36c] = mstr(0x46f36c, 4, true)
hook_code[0x46f36c] = mstr(sendbuff, 4, true)
mem.IgnoreProtection(false)

-- monster choose action

--~ -- Conflicting with editor:
--~ local mon_action_fields = {"AIState", "Direction", "LookAngle", "CurrentActionLength"}
--~ mulhook(0x461451, 5, 1, function(d)
--~ 	local old_actions = {}
--~ 	local function fill(i)
--~ 		local t = {}
--~ 		local m = Map.Monsters[i]
--~ 		for _, k in pairs(mon_action_fields) do
--~ 			t[k] = m[k]
--~ 		end
--~ 		t.CurrentActionStep = m.CurrentActionStep
--~ 		old_actions[i] = t
--~ 	end
--~ 	local function differs(i)
--~ 		local t = old_actions[i]
--~ 		local m = Map.Monsters[i]
--~ 		for _, k in pairs(mon_action_fields) do
--~ 			if t[k] ~= m[k] then
--~ 				return true
--~ 			end
--~ 		end
--~ 	end

--~ 	for i, v in Map.Monsters do
--~ 		if v.Active then
--~ 			fill(i)
--~ 		end
--~ 	end
--~ 	mem.call(0x401AB1)
--~ 	for i, old in pairs(old_actions) do
--~ 		if differs(i) then
--~ 			events.call("MonsterActionChanged", i, Map.Monsters[i], old)
--~ 		end
--~ 	end

--~ 	d:push(0x461456)
--~ 	return true
--~ end)

do

	local choose_action_start = 0x401aba
	local mon_action_fields = {"AIState", "Direction", "LookAngle", "CurrentActionLength"}
	local old_actions

	local function fill(i)
		local t = {}
		local m = Map.Monsters[i]
		for _, k in pairs(mon_action_fields) do
			t[k] = m[k]
		end
		t.CurrentActionStep = m.CurrentActionStep
		old_actions[i] = t
	end
	local function differs(i)
		local t = old_actions[i]
		local m = Map.Monsters[i]
		for _, k in pairs(mon_action_fields) do
			if t[k] ~= m[k] then
				return true
			end
		end
	end

	mulhook(choose_action_start, 7, 1, function(d)
		old_actions = {}
		for i, v in Map.Monsters do
			if v.Active then
				fill(i)
			end
		end
	end)

	function events.MonstersProcessed()
		for i, old in pairs(old_actions) do
			if differs(i) then
				events.call("MonsterActionChanged", i, Map.Monsters[i], old)
			end
		end
	end

end

--

mulhook(0x401e93, 8, 1, function(d)
	local t = {MonsterIndex = mem.u4[d.ebp - 0x1c], allow = true}
	events.call("BeforeMonsterChooseAIState", t)
	if not t.allow then
		d:push(0x4026dd)
		return true
	end
end)

local function ChooseActionHook(mon, monid, ai_state)
	local t = {allow = true, Monster = mon, MonsterIndex = monid, ai_state = ai_state}
	events.call("MonsterChooseAIState", t)
	return t.allow
end
Multiplayer.monster_action = function(monid, mon, ai_state)
	if Multiplayer.in_game then
		return ChooseActionHook(mon, monid, ai_state)
	end
	return true
end

local function SetChooseActionHook(addr, size, hook_type, default_handler, monreg, ai_state)
	mulhook(addr, size, hook_type, function(d)
		local mon, monid = GetMonster(d[monreg])
		if mon and not ChooseActionHook(mon, monid, ai_state) then
			d:push(default_handler)
			return true
		end
	end)
end

local choose_action_hooks = {
	--0x401c82 - another monster handler cycle here
	--0x46f1aa - monsters movement handler cycle starts here
	--0x46e40a - monsters ? handler cycle starts here
	--0x4686a8 - interaction with player handler
	--0x401e89 - choose action cycle for active monsters
	--0x4040b8 - stop monster 1
	--0x40410d - stop monster 2
	--0x4041ac - stop monster 3
	--0x404287 - interact
	--0x403ebd - monster attack
	--[0x4040e3] = {6, 1, 0x404105, 'esi', 0}, - begining of turn-based phase
	[0x404181] = {6, 1, 0x4041a8, 'ebx', 0},  -- causes spam in TB mode
	[0x403291] = {6, 1, 0x4032d6, 'ebx', 9},  -- causes spam in TB mode
	[0x40366d] = {7, 2, 0x40369f, 'esi', 1},
	[0x402b91] = {7, 1, 0x402bda, 'ebx', 7},
	[0x4042f3] = {7, 1, 0x404339, 'ebx', 10},
	[0x4028d5] = {7, 1, 0x402918, 'ebx', 6},
	[0x402a3b] = {7, 1, 0x402a64, 'ebx', 6},
	[0x40400e] = {7, 1, 0x4040b1, 'ebx', 2},
	[0x404259] = {6, 1, 0x404280, 'ebx', 0},
	[0x402d75] = {7, 1, 0x402db0, 'ebx', 6},
	[0x403809] = {7, 1, 0x4038bd, 'ebx', 3},
	[0x4033a7] = {7, 1, 0x4033ea, 'ebx', 8},
	[0x402eaf] = {9, 1, 0x402ec1, 'esi', 4},
	[0x4069fe] = {9, 1, 0x406a19, 'eax', 5}, -- turn based mode const.AIState.Dead
}

for i, v in pairs(choose_action_hooks) do
	SetChooseActionHook(i, unpack(v))
end

-- apply spellbuff to monster
mulhook(0x455d9e, 5, 1, function(d)
	if d.ecx < Map.Monsters["?ptr"] or d.ecx > (Map.Monsters["?ptr"] + Map.Monsters["?size"]) then
		-- Is Party or Player buff.
		return
	end

	local mon, monid = GetMonster(d.ecx)
	if not mon then
		return
	end

	local sellbuff_id = (d.ecx - mon.SpellBuffs[0]["?ptr"]) / structs.SpellBuff["?size"]
	local t = {
		Monster = mon,
		MonsterIndex = monid,
		SpellBuff = sellbuff_id,
		ExpireTime = u4[d.ebp + 8],
		Skill = u4[d.ebp + 0x10],
		Power = u4[d.ebp + 0x14],
		Handled = false
	}

	events.call("MonsterReceiveSpellBuff", t)

	if t.Handled then
		d:push(0x455e11)
		return true
	end
end)

-- turn based phases

local function TurnBasedPhaseChangeHook(addr, size, htype, phase, def)
	mulhook(addr, size, htype, function(d)
		local t = {Phase = phase, Handled = false}
		events.call("TurnBasedPhaseChange", t)

		if t.Handled then
			d:push(def)
			return true
		end
	end)
end

-- 0x406679 - actual phase change switch
TurnBasedPhaseChangeHook(0x4066fa, 5, 1, 2, 0x406715)
TurnBasedPhaseChangeHook(0x40669f, 5, 1, 1, 0x406715)
TurnBasedPhaseChangeHook(0x406a84, 7, 1, 3, 0x406aa7)

mulhook(0x4066d3, 5, 1, function(d)
	local t = {Handled = false}
	events.call("TurnBasedMonsterActions", t)

	if t.Handled then
		d:push(0x406715)
		return true
	end
end)

-- hire character

mulhook(0x48c0b6, 6, 1, function(d)
	local t = {Handled = false}
	events.call("HireCharacter", t)

	if t.Handled then
		d:push(0x48c15c)
		return true
	end
end)

-- player's death

mulhook(0x4614d4, 6, 2, function(d)
	local t = {Handled = false}
	events.call("PartyDies", t)
	if t.Handled then
		d:push(0x461856)
		return true
	end
end)

-- can rest

mulhook(0x43188f, 5, 2, function(d)
	local t = {
		Handled = false,
		Allow = d.ZF and d.eax ~= d.edi,
		StatusText = not d.ZF and u4[0x601BC8] or d.eax == d.edi and u4[0x601BC0] or u4[0x601BC4]}

	events.call("PartyCanRest", t)

	if t.Handled then
		if t.Allow then
			d:push(0x43189f)
		else
			if type(t.StatusText) == "number" then
				t.StatusText = mstr(t.StatusText)
			end
			Game.ShowStatusText(t.StatusText)
			d:push(0x430370)
		end
		return true
	end
end)

mulhook(0x48fe9f, 5, 2, function(d)
	events.call("RestAndHealStarted")
end)

-- speak with monster

mulhook(0x46888D, 5, 2, function(d)
	local mon, mon_id = GetMonster(d.ecx)
	if not mon then
		return
	end

	local t = {Handled = false, Monster = mon, MonsterIndex = mon_id}
	events.call("SpeakWithMonster", t)

	if t.Handled then
		d:push(0x468a67)
		return true
	end
end)

mulhook(0x42ef33, 5, 1, function(d)
	local mon, mon_id = GetMonster(d.ecx)
	if not mon then
		return
	end

	local t = {Handled = false, Monster = mon, MonsterIndex = mon_id}
	events.call("SpeakWithMonster", t)

	if t.Handled then
		d:push(0x430370)
		return true
	end
end)

-- deposit / withdraw bank gold using Bank house screen

mulhook(0x4b652d, 6, 1, function(d)
	events.call("DepositBankGold", d.esi)
end)

mulhook(0x4b63cb, 6, 1, function(d)
	events.call("WithdrawBankGold", d.esi)
end)

-- allow movement while selecting spell target

--~ asmpatch_backup(7, 0x420956, [[
--~ 	cmp dword [ds:0x4F37D8], 0x0
--~ 	je absolute 0x42095f
--~ 	cmp dword [ds:0x4F37D8], 0x14
--~ 	je absolute 0x42095f
--~ ]])

--~ asmpatch_backup(6, 0x420319, [[
--~ 	je absolute 0x4205b3
--~ 	cmp dword [ds:0x4F37D8], 0x14
--~ 	je absolute 0x4205b3
--~ ]])
--~
--~ asmpatch_backup(6, 0x4A99A8, [[
--~ 	cmp dword [ds:0x4F37D8], ebx
--~ 	je absolute 0x4A99D4
--~ 	cmp dword [ds:0x4F37D8], 0x14
--~ ]])

local NewCode = [[
	je @exit
	cmp dword [ds:0x4F37D8], 0x14
	je @exit
	jmp absolute 0x42ec44
	@exit:
]]
asmpatch_backup(6, 0x42E645, NewCode)
asmpatch_backup(6, 0x42E6f1, NewCode)
asmpatch_backup(6, 0x42E726, NewCode)
asmpatch_backup(6, 0x42E7B8, NewCode)
asmpatch_backup(6, 0x42E69B, NewCode)

-- Lloyds Beacon recall

mulhook(0x430edc, 5, 1, function(d)
	if mem.u1[0x517b3c] == 1 then
		local pl = Party.PlayersArray[math.floor((d.esi - Party.PlayersArray["?ptr"]) / Party.PlayersArray[0]["?size"])]
		local slot = pl.Beacons[(d.esi - pl.Beacons["?ptr"]) / pl.Beacons[0]["?size"]]
		events.call("LloydsBeaconRecall", pl, slot)
	end
end)

-- Arena win conditions
mem.IgnoreProtection(true)
code_backup[0x4b9e54] = mstr(0x4b9e54, 2, true)
hook_code[0x4b9e54] = "\144\144" -- nop nop
mem.IgnoreProtection(false)

mulhook(0x4b9e56, 5, 1, function(d)
	local t = {Won = d.ebp >= d.edi}
	events.call("ArenaWinConditionsCheck", t)

	if t.Won then
		d:push(0x4b9eb3)
		return true
	end
end)

-- Make outdoor sprite lights detachable from sprites

Multiplayer.DETACHABLE_LIGHT_TYPE = 7

asmpatch_backup(7, 0x4ab700, [[
	cmp byte [eax+0xb], 0x7
	je absolute 0x4ab733

	mov word [ds:eax], dx
	mov dx, word [ss:ebp+0xc]
]])

-- Object color on minimap

NewCode = asmpatch_backup(7, 0x43f380, [[
	nop
	nop
	nop
	nop
	nop
	cmp dword [ss:ebp+0x10], 0x400
]])
mem.hook(NewCode, function(d)
	local t = {Color = mem.u4[d.ebp+0xC]}
	t.Monster, t.MonsterIndex = GetMonster(d.ecx)

	events.Call("MonsterColorOnMinimap", t)
	mem.u4[d.ebp+0xC] = t.Color
end)

mulhook(0x43f0ec, 6, 1, function(d)
	events.Call("DrawMinimapInfo")
end)

-- Party rest encounter

NewCode = asmpatch_backup(6, 0x4319e8, [[
	nop
	nop
	nop
	nop
	nop
	jg absolute 0x431ae3
]])
mem.hook(NewCode, function(d)
	local t = {Happened = d.ZF or d.SF}
	events.Call("PartyRestEncounter", t)

	if t.Happened then
		d.ZF = true
		d.SF = true
	else
		d.ZF = false
		d.SF = false
	end
end)

-- Disable fatal consequences of lack of rest, untill solution for time-desynq found
asmpatch_backup(6, 0x492419, "jmp absolute 0x4924A7")

-- Blood splats

mulhook(0x4375ec, 5, 2, function(d)
	local mon, mon_id = GetMonster(d.esi)
	events.Call("BloodSplatCreated", mon, mon_id)
end)

mulhook(0x42e240, 5, 1, function(d)
	if d.eax < Map.Objects.count then
		events.Call("ObjectCreated", d.eax)
	end
end)

-- Trigger chest trap

local TriggerTrapAsm = mem.asmproc([[
mov edx, 0x3
mov eax, 0x4e6a86
call absolute 0x4d9dec
sub esp, 0xb0
push ebx
push esi
xor esi, esi
cmp ecx, esi
push edi
mov dword [ss:ebp-0x24], ecx
jl absolute 0x41fdad
cmp ecx, 0x14
jge absolute 0x41fdad

inc dword [ds:0x71ef84]
cmp dword [ds:0x71ef80], esi
jne absolute 0x41f8f9

mov eax, dword [ds:0x71ef64]
mov dword [ds:0x71ef80], eax
mov eax, ecx
imul eax, eax, 0x14cc
lea ebx, dword [ds:eax+0x60253a]
mov dword [ss:ebp-0x30], ebx
cmp dword [ds:0x519350], esi
je absolute 0x41fdad

push 0x6f3984
mov ecx, 0x5e6e00
call absolute 0x451f39
mov edi, eax
imul edi, edi, 0x44
add edi, 0x5e6e00

jmp absolute 0x41f9bf]])

function Multiplayer.TriggerChestTrap(chest_id, trap_pos_ref)
	assert(chest_id)
	assert(trap_pos_ref)

	mem.u4[0x5cc030] = trap_pos_ref -- facet or sprite reference, where to play trap spell anim
	mem.call(TriggerTrapAsm, 1, chest_id)
end

----

disable_hooks()

----------------------------------------------------------
-- Debug utilities

Multiplayer.debug.code_backup = code_backup
Multiplayer.debug.hook_code = hook_code
Multiplayer.debug.event_handlers = event_handlers

Multiplayer.debug.disable_hook = function(p)
	if not code_backup[p] or not hook_code[p] then
		return false
	end

	if hooks_on then
		mem.IgnoreProtection(true)
		mcopy(p, code_backup[p])
		mem.IgnoreProtection(false)
	end

	code_backup[p] = nil
	hook_code[p] = nil

	return true
end

Multiplayer.debug.enable_next_hook = function()
	local have
	mem.IgnoreProtection(true)
	for addr, code in pairs(hook_code) do
		if mstr(addr, #code, true) ~= code then
			have = addr
			mcopy(addr, code, #code)
			break
		end
	end
	mem.IgnoreProtection(false)
	return have
end

Multiplayer.debug.disable_next_hook = function()
	local have
	mem.IgnoreProtection(true)
	for addr, code in pairs(Multiplayer.debug.code_backup) do
		if mem.string(addr, #code, true) ~= code then
			have = addr
			mem.copy(addr, code, #code)
			break
		end
	end
	mem.IgnoreProtection(false)
	return have
end

Multiplayer.debug.disable_next_event_handler = function()
	for event, handlers in pairs(Multiplayer.debug.event_handlers) do
		for handler, _ in pairs(handlers) do
			local have_one = std_events.Remove(event, handler)
			if have_one then
				return event, handler
			end
		end
	end
end

Multiplayer.debug.disable_mulhooks = function()
	mem.IgnoreProtection(true)
	for addr, code in pairs(code_backup) do
		mcopy(addr, code, #code)
	end
	mem.IgnoreProtection(false)
end

Multiplayer.debug.disable_event_handlers = function()
	for event, handlers in pairs(event_handlers) do
		for handler, _ in pairs(handlers) do
			while std_events.Remove(event, handler) do end
		end
	end
end

