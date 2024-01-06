local u1, u2, u4, mstr, mcopy, mptr = mem.u1, mem.u2, mem.u4, mem.string, mem.copy, mem.topointer
local NewCode

local function CastBool(v)
	return tonumber(v) or (v and 1 or 0)
end

local function GetPlayer(p)
	local i = (p - Party.PlayersArray["?ptr"]) / Party.PlayersArray[0]["?size"]
	return Party.PlayersArray[i], i
end

local function GetMonster(p)
	if p < Map.Monsters["?ptr"] then
		return
	end
	local i = (p - Map.Monsters["?ptr"]) / Map.Monsters[0]["?size"]
	return Map.Monsters[i], i
end

local function GetObject(p)
	if Map.Objects.count == 0 then
		return
	end

	if p >= Map.Objects["?ptr"] and p < Map.Objects["?ptr"] + Map.Objects["?size"] then
		local id = math.floor((p - Map.Objects["?ptr"]) / Map.Objects[0]["?size"])
		return Map.Objects[id], id
	end
end

---------------------------------------
-- Set outdoor light event

mem.autohook2(0x4886e5, function(d)
	local t = {Minute = Game.Minute, Hour = d.eax}
	events.call("SetOutdoorLight", t)
	d.eax = t.Hour
end)

mem.autohook2(0x4886f4, function(d)
	local t = {Minute = d.ecx, Hour = Game.Hour}
	events.call("SetOutdoorLight", t)
	d.ecx = t.Minute
end)

mem.autohook2(0x488731, function(d)
	local t = {Minute = d.ecx, Hour = Game.Hour}
	events.call("SetOutdoorLight", t)
	d.ecx = t.Minute
end)

mem.autohook2(0x488be7, function(d)
	local t = {Minute = Game.Minute, Hour = d.eax}
	events.call("SetOutdoorLight", t)
	d.eax = t.Hour
end)

mem.autohook2(0x488CAE, function(d)
	local t = {Minute = d.eax, Hour = Game.Hour}
	events.call("SetOutdoorLight", t)
	d.eax = t.Minute
end)

mem.autohook2(0x488C0E, function(d)
	local t = {Minute = d.edi, Hour = Game.Hour}
	events.call("SetOutdoorLight", t)
	d.edi = t.Minute
end)

---------------------------------------
-- Sounds for extra tilesets
-- allows to change sounds of step or execute event based on tile coordinates;
-- only outdoors.

local TileSoundData = {}
mem.autohook2(0x473cf0, function(d) TileSoundData = {Y = d.eax, X = mem.u4[d.esp], Run = mem.u4[d.esp+4]} end)
mem.autohook2(0x473cf8, function(d)
	TileSoundData.Sound = d.eax
	events.call("TileSound", TileSoundData)
	d.eax = TileSoundData.Sound
	events.call("TileSoundChosen", TileSoundData)
end)

---------------------------------------
-- Step sounds
-- allows to change sound of step
-- indoors and outdoors.

mem.autohook(0x4724f4, function(d)
	if d.edx >= 0 then
		local t = {Sound = u4[d.esp], Run = u4[d.ebp - 0x34] == 0 and 1 or 0, Facet = Map.Facets[d.edx]}
		events.call("StepSound", t)
		u4[d.esp] = t.Sound
		events.call("StepSoundChosen", t)
	end
end)
mem.autohook(0x473d02, function(d)
	if d.ecx > 0xffff then
		local t = {Sound = u4[d.esp], Run = u4[d.esp] == 0x40 and 1 or 0, Facet = structs.ModelFacet:new(d.ecx + d.eax)}
		events.call("StepSound", t)
		u4[d.esp] = t.Sound
		events.call("StepSoundChosen", t)
	end
end)


---------------------------------------
-- Got item

mem.autohook2(0x421244, function(d)
	events.call("GotItem", Mouse.Item.Number)
end)
mem.autohook2(0x491a4b, function(d)
	events.call("GotItem", Mouse.Item.Number)
end)


---------------------------------------
-- Regen tick event
-- Standart regen ticks, - unlike timers, continues to tick during party rest.

mem.autohook2(0x491f58, function(d)
	events.cocall("RegenTick", GetPlayer(d.eax))
end)


---------------------------------------
-- Party rest events

local function CalcRestFoodCost()
	local t = {Amount = mem.u1[0x518570]}
	events.call("CalcRestFoodCost", t)
	mem.u1[0x518570] = t.Amount
end

mem.autohook2(0x41ebff, CalcRestFoodCost)
mem.autohook2(0x41ec24, CalcRestFoodCost)
mem.autohook2(0x41ec2b, CalcRestFoodCost)
mem.autohook2(0x41ec36, CalcRestFoodCost)

---------------------------------------
-- Calc jump height event

mem.autohook2(0x473164, function(d)
	local t = {Height = d.eax}
	events.call("CalcJumpHeight", t)
	d.eax = t.Height
end)

function events.CalcJumpHeight(t)
	t.Height = math.min(t.Height, 420)
end

---------------------------------------
-- Can cast town portal
NewCode = mem.asmproc([[
nop
nop
nop
nop
nop
jnz absolute 0x42735b
idiv ecx
cmp edx, dword [ss:ebp-4]
jmp absolute 0x4296a3]])
mem.asmpatch(0x42969e, "jmp absolute " .. NewCode)

mem.hook(NewCode, function(d)
	local t = {CanCast = true, Handled = false, Mastery = mem.u4[d.ebp-0xC]}
	events.call("CanCastTownPortal", t)
	d.ZF = t.CanCast
	if t.Handled then
		d.ecx = 1
	end
end)

---------------------------------------
-- Open chest
-- Supposed to be used to tweak list of items.

mem.autohook(0x4451c1, function(d)
	local t = {CanOpen = true, ChestId = d.ecx}
	events.call("CanOpenChest", t)

	if t.CanOpen then
		-- event kept for backward compatibility
		events.call("OpenChest", d.ecx)
	else
		d:push(0x445666)
		return true
	end
end)


---------------------------------------
-- Trigger chest trap
-- Can be used to disable trap / implement special trap logic

mem.autohook(0x41f9bf, function(d)
	local t = {
		Handled = false,
		CanOpenChest = true,
		ChestId = mem.u4[d.ebp - 0x24],
		TrapRef = mem.u4[0x5cc030]}

	events.Call("BeforeChestTrapTriggered", t)
	if t.Handled then
		d:push(t.CanOpenChest and 0x41fd35 or 0x41fdad)
		return true
	end
	events.Call("ChestTrapTriggered", t.ChestId, t.TrapRef)
end)

---------------------------------------
-- Get gold
-- Triggers when party finds gold (monster's corpses or gold items)

mem.autohook(0x42013a, function(d)
	local t = {Amount = d.esi}
	events.call("BeforeGotGold", t)
	d.esi = t.Amount
end)

---------------------------------------
-- Pickup object
--

local function GetSqDist(x,y,z)
	local px, py, pz  = XYZ(Party)
	return (px-x)^2 + (py-y)^2 + (pz-z)^2
end

NewCode = mem.asmpatch(0x4217da, [[
	jae absolute 0x421347
	nop
	nop
	nop
	nop
	nop
	jmp absolute 0x4217e0;]])

mem.hook(NewCode + 6, function(d) -- mouse click
	local t = {Handled = false, ObjectId = bit.rshift(bit.And(d.ecx, 0xffff), 3)}
	events.call("PickObject", t)

	if t.Handled then
		d:push(0x421347)
		return true
	end
end)

mem.autohook2(0x468514, function(d) -- spacebar
	-- Prevent looting items too far away from party.
	local obj = Mouse:GetTarget()
	if d.edx ~= obj.Index or (obj.Kind == 2 and GetSqDist(XYZ(Map.Objects[obj.Index])) > 250000) then
		d:push(0x4686a5)
		return true
	end

	if obj.Kind == 2 then
		local t = {Handled = false, ObjectId = d.edx}
		events.call("PickObject", t)

		if t.Handled then
			d:push(0x4686a5)
			return true
		end
	end
end)

mem.autohook(0x42ad74, function(d) -- telekinesis
	local t = {Handled = false, ObjectId = d.edi}
	events.call("PickObject", t)

	if t.Handled then
		d:push(0x42C200)
		return true
	end
end)

---------------------------------------
-- Click shop topic
-- Triggers when player clicks topic in shop
-- (list of topics provided by RemoveHouseRulesLimits.lua in const.ShopTopics)

mem.autohook2(0x4baa76, function(d)
	local t = {Handled = false, Topic = d.ecx}
	events.call("ClickShopTopic", t)

	d.ecx = t.Topic -- topic id change is allowed, but most probably will lead to game crash.

	if t.Handled then
		d.ZF = true
	end
end)

---------------------------------------
-- Calculate fame
-- Allows to change calculation base or overhaul counting.
--

NewCode = mem.asmpatch(0x4903a2, [[
call absolute 0x4026f4
nop; mem hook here
nop
nop
nop
nop

je @over

push 0
push 0xfa
push ecx
push eax
call absolute 0x4dac60

@over:
jmp absolute 0x4903bf]])

mem.hook(NewCode + 5, function(d)
	local t = {Handled = false, Result = 0, Base = Party[0].Experience}
	events.call("GetFameBase", t)

	if t.Handled then
		d.eax = t.Result
	else
		d.ecx = mem.u4[d.eax + 0xa4]
		d.eax = t.Base
	end
	d.ZF = t.Handled
end)

---------------------------------------
-- Get loading screen pic
-- Allows to change loading screen picture.
--
local strlen = string.len
mem.autohook2(0x44031d, function(d)
	local ptr = u4[d.esp]
	local t = {Pic = mstr(ptr)}
	events.call("GetLoadingPic", t)

	mcopy(ptr, t.Pic)
	u1[ptr + strlen(t.Pic)] = 0
end)

---------------------------------------
-- Can show "Heal" topic
--
local function CanShowHealTopic(d)
	local t = {CanShow = d.eax}
	events.call("CanShowHealTopic", t)
	d.eax = CastBool(t.CanShow)
end

mem.autohook2(0x4b5c3b, CanShowHealTopic)
mem.autohook2(0x4b5cd7, CanShowHealTopic)
mem.autohook2(0x4bacdd, CanShowHealTopic)

---------------------------------------
-- Get travel days cost
--
function events.GameInitialized2()

	NewCode = mem.asmpatch(0x4b5626, [[
	nop; mem hook
	nop
	nop
	nop
	nop
	cmp eax, 1
	jge absolute 0x4b562e]])

	mem.hook(NewCode, function(d)
		local t = {Days = d.eax, House = mem.u4[0x518678]}
		events.call("GetTravelDaysCost", t)

		d.eax = t.Days
	end)

	mem.autohook(0x4b51b8, function(d)
		local t = {Days = d.ecx, House = mem.u4[0x518678]}
		events.call("GetTravelDaysCost", t)

		d.ecx = t.Days
	end)

end

---------------------------------------
-- Calc training time
--
mem.autohook2(0x4b036c, function(d)
	if Game.CurrentScreen == const.Screens.House then
		local t = {House = GetCurrentHouse(), Time = d.eax}
		events.Call("CalcTrainingTime", t)
		d.eax = t.Time
		d.edx = 0
	end
end)


---------------------------------------
-- Can identify item
--

mem.autohook2(0x41cf1b, function(d)
	local t = {CanIdentify = d.ZF, Player = Party[math.max(0, Game.CurrentPlayer)]}

	local object, id = GetObject(d.eax)
	if object then
		t.ObjectIndex = id
		t.Object = object
		t.Item = object.Item
	else
		t.Item = structs.Item:new(d.eax)
	end

	events.call("CanIdentifyItem", t)
	d.ZF = t.CanIdentify
end)

---------------------------------------
-- Can repair item
--
NewCode = mem.asmpatch(0x41cfdd, [[
mov ecx, dword [ss:esp-4];
nop; mem hook
nop
nop
nop
nop
cmp eax, 1
mov eax, dword [ss:ebp-4];]])

mem.hook(NewCode + 4, function(d)
	local t = {CanRepair = d.eax == 1, Player = Party[math.max(0, Game.CurrentPlayer)]}

	local object, id = GetObject(d.ecx)
	if object then
		t.ObjectIndex = id
		t.Object = object
		t.Item = object.Item
	else
		t.Item = structs.Item:new(d.ecx)
	end

	events.call("CanRepairItem", t)

	d.ecx = 0
	d.eax = CastBool(t.CanRepair)
end)

---------------------------------------
-- Artifact generated
--
function events.GameInitialized2()
	local function ArtifactGenerated(d)
		local t = {ItemId = d.eax}
		events.call("ArtifactGenerated", t)

		d.eax = t.ItemId
	end

	mem.autohook2(0x44dd8d, ArtifactGenerated)
	mem.autohook(0x4541c4, ArtifactGenerated)
end

---------------------------------------
-- Arrow projectile
--
mem.autohook(0x42636c, function(d)
	local t = {ObjId = u4[d.ebp-0xac], PlayerIndex = u2[0x51d822]}
	events.call("ArrowProjectile", t)

	u4[d.ebp-0xac] = t.ObjId
end)

---------------------------------------
-- Dragon breath projectile
--
mem.autohook(0x4264ef, function(d)
	local t = {ObjId = u4[d.ebp-0xac], PlayerIndex = u2[0x51d822]}
	events.call("DragonBreathProjectile", t)

	u4[d.ebp-0xac] = t.ObjId
end)

---------------------------------------
-- Get spell skill
-- Supposed to modify skill level for default attacks of players (for example, dragon breath)
--
local function SpellSchoolBySpell(spell_id)
	return ((spell_id-1) / 11):floor()
end

function events.GetSkill(t)
	local Spell = u2[0x51d820]
	if Spell > 0 and t.Skill == (SpellSchoolBySpell(Spell) + 12) then
		t.Spell = Spell
		events.call("GetSpellSkill", t)
	end
end

---------------------------------------
-- BeforeLeaveGame
-- called before LeaveGame event, at the moment, when player click "Quit" button second time.
-- Supposed to be used, when player leaving game, but map data still necessary.
mem.autohook2(0x433b0d, function() events.call("BeforeLeaveGame") end)

---------------------------------------
-- MonsterDropItem
-- Additional event call is in MonsterItems.lua
--
mem.autohook(0x40934a, function(d)
	local mon, monid = GetMonster(d.esi)
	local t = {MonsterIndex = monid, Monster = mon, ItemId = mem.u4[d.eax], Handled = false}
	events.Call("MonsterDropItem", t)
	if t.Handled then
		d:push(0x409358)
		return true
	end
end)

---------------------------------------
-- Last created object tracking for optimization of single object creation
-- via Game.SummonObjects
--
local LastObjectBuff = mem.StaticAlloc(4)
mem.asmpatch(0x42e380, [[
	call absolute 0x42E05C
	mov dword [ds:]] .. LastObjectBuff .. [[], eax
]])

function Game.LastCreatedObject()
	return u4[LastObjectBuff]
end

---------------------------------------
-- Turn based mode start / stop
--
--
mem.autohook(0x42e7f5, function(d)
	events.call("TurnBasedStarted")
end)
mem.autohook(0x42e7df, function(d)
	events.call("TurnBasedStopped")
end)

---------------------------------------
-- MonsterCastSpell
--
--
function events.GameInitialized2()

	local TargetBuf = mem.StaticAlloc(Map.Monsters.limit*4)
	local LastAttackTargetBuf = mem.StaticAlloc(Map.Monsters.limit*4)

	mem.asmpatch(0x404638, [[
	mov eax, dword [ss:esp+8]
	cmp eax, dword [ds:0x40123F]
	jl @end

	push edx
	push ecx

	mov ecx, 0x3cc
	sub eax, dword [ds:0x40123F]
	cdq
	idiv ecx

	pop ecx
	pop edx

	mov word [ds:]] .. TargetBuf+2 .. [[+eax*4], 0;
	mov word [ds:]] .. TargetBuf   .. [[+eax*4], 4; -- target is party (const.ObjectRefKind)

	@end:
	mov eax, dword [ss:ebp+0xc]
	cmp eax, edi]])

	mem.asmpatch(0x404650, [[
	mov eax, dword [ss:esp+8]
	cmp eax, dword [ds:0x40123F]
	jl @end

	push edx
	push ecx

	mov ecx, 0x3cc
	sub eax, dword [ds:0x40123F]
	cdq
	idiv ecx

	pop ecx
	pop edx

	mov word [ds:]] .. TargetBuf+2 .. [[+eax*4], si;
	mov word [ds:]] .. TargetBuf   .. [[+eax*4], 3; -- target is monster (const.ObjectRefKind)

	@end:
	imul esi, esi, 0x3cc]])

	-- attack target selection

	mem.asmpatch(0x403f02, [[
	mov eax, dword [ss:ebp-0x4]
	mov word [ds:]] .. LastAttackTargetBuf+2 .. [[+eax*4], 0;
	mov word [ds:]] .. LastAttackTargetBuf   .. [[+eax*4], 4; -- target is party (const.ObjectRefKind)
	mov eax, dword [ds:0xb2155c];]])

	mem.asmpatch(0x403f25, [[
	mov ecx, dword [ss:ebp-0x4]
	mov word [ds:]] .. LastAttackTargetBuf+2 .. [[+ecx*4], ax;
	mov word [ds:]] .. LastAttackTargetBuf   .. [[+ecx*4], 3; -- target is monster (const.ObjectRefKind)
	imul eax, eax, 0x3cc;]])

	-- Fix damaging player upon death of monster being killed by other monsters.
	NewCode = mem.asmpatch(0x436a59, [[
	movzx ecx, word [ds:]] .. LastAttackTargetBuf   .. [[+eax*4]
	cmp ecx, 0x4
	jne absolute 0x436e01
	imul eax, eax, 0x3cc]])

	----

	function GetMonsterTarget(i)
		return u2[TargetBuf+i*4], u2[TargetBuf+i*4+2]
	end

	function GetLastAttackedMonsterTarget(i)
		return u2[LastAttackTargetBuf+i*4], u2[LastAttackTargetBuf+i*4+2]
	end

	local function MonsterCanCastSpellHook(d)
		local Mon, MonId = GetMonster(d.esi)
		if Mon then
			local TargetRef, TargetId = GetMonsterTarget(MonId)
			local t = {Spell = u4[d.ebp-0x8], Monster = Mon, MonsterIndex = MonId, Target = 0, Distance = u4[d.ebp-0xC], Result = d.eax, TargetRef = TargetRef}
			if TargetRef == 4 then
				t.Target = Party
			elseif TargetRef == 3 then
				t.Target = Map.Monsters[TargetId]
			end
			events.call("MonsterCanCastSpell", t)
			d.eax = CastBool(t.Result)
		end
	end

	NewCode = mem.asmhook(0x42543c, [[
	cmp dword [ss:ebp-0x8], 0
	je @end
	nop
	nop
	nop
	nop
	nop
	@end:]])
	mem.hook(NewCode+6, MonsterCanCastSpellHook)

	NewCode = mem.asmhook(0x42544f, [[
	cmp dword [ss:ebp-0x8], 0
	je @end
	nop
	nop
	nop
	nop
	nop
	@end:]])
	mem.hook(NewCode+6, MonsterCanCastSpellHook)

	mem.autohook(0x404d9f, function(d)
		local Mon, MonId = GetMonster(d.esi)
		if Mon then
			local TargetRef, TargetId = GetMonsterTarget(MonId)
			local t = {Spell = d.ecx, Monster = Mon, Target = 0, TargetRef = TargetRef, Handled = false}

			if TargetRef == 4 then
				t.Target = Party
			elseif TargetRef == 3 then
				t.Target = Map.Monsters[TargetId]
			end

			events.call("MonsterCastSpellM", t)
			if t.Handled then
				d.ecx = 0xffff
			else
				d.ecx = t.Spell
			end
		end
	end)

end

---------------------------------------
-- Monsters processed
--
local MonstersProcessedHook = mem.asmpatch(0x4026ef, [[
	nop
	nop
	nop
	nop
	nop
	pop edi
	pop esi
	pop ebx
	leave
	retn]])

mem.hook(MonstersProcessedHook, function()
	events.call("MonstersProcessed")
end)

---------------------------------------
-- On Enter Shop
-- Allow to forbid entrance
NewCode = mem.asmpatch(0x443205, [[
mov [eax], ebx
mov [eax+4], ebx
mov eax, [ebp-0x14]
nop
nop
nop
nop
nop
test eax, eax
jnz absolute 0x4431F2
]])

mem.hook(NewCode + 8, function(d)
	local t = {HouseId = d.eax, Banned = 0}
	events.call("OnEnterShop", t)
	d.eax = t.Banned
end)

-- IsMonsterOfKind
mem.hookfunction(0x436542, 2, 0, function(d, def, id, kind)
	local t = {
		Id = id,
		-- :const.MonsterKind
		Kind = kind,
		Result = def(id, kind),
	}
	events.cocall("IsMonsterOfKind", t)
	return t.Result
end)


---------------------------------------
-- Player yell
--
--
mem.autohook2(0x42e78d, function(d)
	events.call("PlayerYell")
end)

---------------------------------------
-- Player cast spell
--
--
local function EnoughSP(spell_id, Player)
	local spell_school = SpellSchoolBySpell(spell_id)
	local skill_id = spell_school + 12
	local pl_skill, pl_mastery = SplitSkill(Player:GetSkill(skill_id))

	if spell_id > Game.Spells.count then
		return true, 0, pl_skill, pl_mastery
	end

	local required = Game.Spells[spell_id].SpellPoints[math.max(pl_mastery, 1)]
	return Player.SP >= required, required, pl_skill, pl_mastery
end

-- make target ref upon player selection aswell.
mem.asmpatch(0x430b28, [[
	dec ecx
	mov word [ds:eax+4], cx
	shl ecx, 3
	add ecx, 4
	mov word [ds:eax+0xC], cx]])

-- Interrupted by curse
-- copy of the original algorythm starting from 0x4262f9
local InterruptedByCurseFlag = mem.StaticAlloc(4)
local InterruptedByCurseAsm = mem.asmproc([[
	call absolute 0x4d99f2
	push 0x64
	cdq
	pop ecx
	idiv ecx
	xor eax, eax
	cmp edx, 32
	jl @end
	inc eax
	@end:
	ret]])

-- replace original code with fetching pregenerated state flag
mem.asmpatch(0x4262f9, [[
	mov al, byte [ds:]] .. InterruptedByCurseFlag .. [[];
	mov byte [ds:]] .. InterruptedByCurseFlag .. [[], 0
	test al, al
	je absolute 0x42630d
	jmp absolute 0x42d475
]])

mem.autohook(0x42609e, function(d)
	-- u4[d.ebp-0xC8] - number of current spell slot being processed
	-- 0x14 - size of spell slot
	local slot = 0x51d820 + u4[d.ebp-0xC8] * 0x14

	local spell_id = u2[slot]
	if spell_id >= Game.Spells.limit then
		return
	end

	local player_id = u2[slot + 2]
	local player = Party.PlayersArray[player_id]
	local target_ref = u2[slot + 0xc]
	local is_spell_scroll = bit.And(u1[slot + 8], 1) == 1
	local skill_set = u2[slot + 10] > 0
	local enough_sp, sp_cost, skill, mastery

	if is_spell_scroll then
		enough_sp, sp_cost, skill, mastery = true, 0, 7, 3
	elseif skill_set then
		skill, mastery = SplitSkill(u2[slot + 10])
		enough_sp, sp_cost = EnoughSP(spell_id, player)
	else
		enough_sp, sp_cost, skill, mastery = EnoughSP(spell_id, player)
	end

	local cursed = false
	if spell_id < 100 and player.Conditions[const.Condition.Cursed] > 0 then
		cursed = mem.call(InterruptedByCurseAsm) == 1
	end
	u4[InterruptedByCurseFlag] = cursed and 1 or 0

	local t = {
		SpellId = spell_id,
		PlayerIndex = player_id,
		Player = player,
		InventorySlot = mem.u2[slot + 6],
		SPCost = sp_cost,
		Skill = skill,
		Mastery = mastery,
		TargetKind = bit.And(target_ref, 7), -- object or monster
		TargetId = bit.rshift(target_ref, 3),
		IsSpellScroll = is_spell_scroll,
		CurseInterrupt = cursed,
		Handled = false}

	if Multiplayer and Multiplayer.in_game then
		events.call("PlayerCastSpellFirst", t) -- used to insert remote data
		events.call("PlayerCastSpell", t)
		events.call("PlayerCastSpellLast", t) -- used to fetch userdata for remote players
	else
		events.call("PlayerCastSpell", t)
	end

	if t.TargetKind == 4 then
		-- clean service player reference to not mess up with original spells handler.
		u2[slot + 0xc] = 0
	end

	if t.Handled then
		mem.u2[slot] = 0
		d:push(0x42d45d)
		return true
	end

	-- if spell skill is not set, value will be taken from caster's data, bypassing GetSkill event in some cases.
	-- if spell skill is set, caster won't loose spellpoints
	if skill_set then
		u2[slot + 10] = JoinSkill(t.Skill, t.Mastery)
	end
end)

-- Spells test

--~ local count = 1
--~ local function test_spells()
--~ 	if count > 125 then
--~ 		RemoveTimer()
--~ 		Game.ShowStatusText("Done")
--~ 	else
--~ 		Game.ShowStatusText(tostring(count))
--~ 		CastSpellDirect(count)
--~ 	end

--~ 	count = count + 1
--~ end
--~ Timer(test_spells, const.Minute / 4)


