local LogId = "RemoveSkillValueLimits"
local Log = Log
Log(Merge.Log.Info, "Init started: %s", LogId)

-- Create null-terminated string from given lua string
local function mem_cstring(str)
	local ptr = mem.StaticAlloc(#str + 1)
	mem.copy(ptr, str, #str + 1)
	return ptr
end

local function get_player_from_ptr(ptr)
	if ptr < 0xB2187C or ptr > 0xB7AD24 then
		MF.Log(Merge.Log.Error, "%s: invalid player pointer in GetPlayerFromPtr - 0x%X", LogId, ptr)
		return nil, -1
	end
	local player_id = (ptr - Party.PlayersArray["?ptr"])/Party.PlayersArray[0]["?size"]
	return Party.PlayersArray[player_id], player_id
end

-- MaxSkillVal is maximum value of base_skill + skill_bonus
-- Should be 2^N-1 with maximum value of 0x3FF
-- MM8 value is 0x3F
local MaxSkillVal = 0x3FF
-- MaxSkillBase is maximum value of base_skill
-- MM8 value is 0x3C
local MaxSkillBase = 0x1F4
-- Bit offset of Expert Mastery
-- Shouldn't be less than log2(MaxSkillVal + 1) [N from above]
-- MM8 value is 6
local ExpertBit = 10

-- WARNING: there are a lot of hardcoded values in this file still.

local MF, MO = Merge.Functions, Merge.Offsets
local floor, max, pow = math.floor, math.max, math.pow
local asmpatch, asmproc, memcall = mem.asmpatch, mem.asmproc, mem.call
local strformat = string.format

local MaxSkillValH = floor(MaxSkillVal / 0x100)
local SkillAnd = 0xFFFFFFFF - MaxSkillVal
local SkillAndX = 0xFFFF - MaxSkillVal
local MaxSkillValStr, MaxSkillValHStr = strformat("0x%X", MaxSkillVal), strformat("0x%X", MaxSkillValH)
local MaxSkillBaseStr = strformat("0x%X", MaxSkillBase)
local SkillAndStr = strformat("0x%X", SkillAnd)
local SkillAndXStr = strformat("0x%X", SkillAndX)

local MasterBit, GrandMasterBit = ExpertBit + 1, ExpertBit + 2
local ExpertBitH = ExpertBit - 8
local MasterBitH, GrandMasterBitH = ExpertBitH + 1, ExpertBitH + 2

local ExpertBitV = pow(2, ExpertBit)
local ExpertBitVH = ExpertBit > 7 and pow(2, ExpertBitH) or 0
local MasterBitV = ExpertBitV * 2
local MasterBitVH = MasterBit > 7 and pow(2, MasterBitH) or 0
local GrandMasterBitV, GrandMasterBitVH = ExpertBitV * 4, pow(2, GrandMasterBitH)
local ExpertBitStr = strformat("0x%X", ExpertBit)
local MasterBitStr = strformat("0x%X", MasterBit)
local GrandMasterBitStr = strformat("0x%X", GrandMasterBit)
local ExpertBitVStr, ExpertBitVHStr = strformat("0x%X", ExpertBitV), strformat("0x%X", ExpertBitVH)
local MasterBitVStr, MasterBitVHStr = strformat("0x%X", MasterBitV), strformat("0x%X", MasterBitVH)
local GrandMasterBitVStr = strformat("0x%X", GrandMasterBitV)
local GrandMasterBitVHStr = strformat("0x%X", GrandMasterBitVH)

function SplitSkill(val)
	if not val then return end
	local n = val % (MaxSkillVal + 1)
	local mast = 0
	if val >= GrandMasterBitV then
		mast = 4
	elseif val >= MasterBitV then
		mast = 3
	elseif val >= ExpertBitV then
		mast = 2
	elseif val >= 1 then
		mast = 1
	end
	return n, mast
end

local ConvertMastery = {[0] = 0, [1] = 0, [2] = ExpertBitV, [3] = MasterBitV, [4] = GrandMasterBitV}

JoinSkill = function(skill, mastery)
	if skill > MaxSkillVal then
		Log(Merge.Log.Error, "Incorrect skill value %d at JoinSkill()", skill)
		skill = MaxSkillVal
	end
	if mastery > 4 then
		Log(Merge.Log.Error, "Incorrect mastery %d at JoinSkill()", mastery)
		mastery = 4
	end
	return skill + (ConvertMastery[mastery] or 0)
end

-- GetSkillMastery
-- Note: returns 1 if skill value is 0
asmpatch(0x455B09, [[
push 4
pop eax
test cx, ]] .. GrandMasterBitV .. [[;
jnz @end
dec eax
test cx, ]] .. MasterBitV .. [[;
jnz @end
dec eax
test cx, ]] .. ExpertBitV .. [[;
jnz @end
dec eax
@end:
]], 0x455B24 - 0x455B09)

-- GetSkillMastery0
-- Note: returns 0 if skill value is 0
local get_skill_mastery0 = asmproc([[
xor eax, eax
test ecx, ecx
jz @end
call absolute 0x455B09
@end:
retn
]])
MO.GetSkillMastery0 = get_skill_mastery0

-- GetPlayerSkillMastery
-- ecx - player ptr; edx - skill id
local get_player_skill_mastery = asmproc([[
push esi
mov esi, ecx
lea ecx, [ecx + edx * 2 + 0x378]
movzx ecx, word ptr [ecx]
nop
nop
nop
nop
nop
call absolute ]] .. get_skill_mastery0 .. [[;
pop esi
retn]])
MO.GetPlayerSkillMastery = get_player_skill_mastery

mem.hook(get_player_skill_mastery + 13, function(d)
	local t = {PlayerPtr = d.esi, Skill = d.edx, Result = d.ecx}
	t.Player, t.PlayerIndex = get_player_from_ptr(d.esi)
	events.call("GetPlayerSkillMastery", t)
	d.ecx = t.Result
end)

MF.GetPlayerSkillMastery = function(player, skill)
	return memcall(get_player_skill_mastery, 2, player["?ptr"], skill)
end

-- Remove general bonus limit

-- GetSkill
mem.asmpatch(0x48F060, [[
and ecx, ]] .. MaxSkillValStr .. [[;
add ecx, ebx
cmp ecx, ]] .. MaxSkillValStr)
mem.nop(0x48F065, 3)
mem.asmpatch(0x48F06A, [[
and eax, ]] .. SkillAndStr .. [[;
add eax, ]].. MaxSkillValStr)
mem.nop(0x48F06F, 1)
mem.asmpatch(0x48F076, [[
and eax, ]] .. SkillAndStr .. [[;
inc eax
jmp absolute 0x48F07E]])
mem.nop(0x48F07B, 1)

-- Skill upgrade (0x4B074B)
asmpatch(0x4B0AA5, [[
lea ecx, [eax+ecx*2+0x378]
and word ptr [ecx], ]] .. MaxSkillVal, 11)
asmpatch(0x4B0ACE, [[
lea ecx, [eax+ecx*2+0x378]
or word ptr [ecx], ]] .. GrandMasterBitV, 10)
asmpatch(0x4B0B15, [[
lea ecx, [eax+ecx*2+0x378]
or word ptr [ecx], ]] .. MasterBitV, 10)
asmpatch(0x4B0B52, [[
lea ecx, [eax+ecx*2+0x378]
or word ptr [ecx], ]] .. ExpertBitV, 10)

-- Character Skills panel
mem.asmpatch(0x418D8A, [[
mov [ebp-24h], edx
and dword ptr [ebp-24h], ]] .. MaxSkillValStr)

mem.asmpatch(0x418DF8, "test byte ptr [ebp-0xF], " .. GrandMasterBitVH)
mem.asmpatch(0x418E22, "test byte ptr [ebp-0xF], " .. MasterBitVH)
mem.asmpatch(0x418E30, "test byte ptr [ebp-0xF], " .. ExpertBitVH)

local plus_one = mem_cstring(" (+1)")

asmpatch(0x418E5A, [[
mov ecx, [ebp - 0x48]
mov edx, [ebp - 0x20]
call absolute ]] .. get_player_skill_mastery .. [[;
push eax
mov ecx, [ebp - 0x10]
call absolute 0x455B09
pop edx
cmp eax, edx
jge @std
push ]] .. plus_one .. [[;
push 0x5DF0E0
call absolute 0x4D9E30
add esp, 0x8
@std:
push 0xEC]])

mem.asmpatch(0x41912D, [[
mov [ebp-24h], edx
and dword ptr [ebp-24h], ]] .. MaxSkillValStr)

mem.asmpatch(0x4191A5, "test byte ptr [ebp-0xF], " .. GrandMasterBitVH)
mem.asmpatch(0x4191CF, "test byte ptr [ebp-0xF], " .. MasterBitVH)
mem.asmpatch(0x4191DD, "test byte ptr [ebp-0xF], " .. ExpertBitVH)

asmpatch(0x419207, [[
mov ecx, [ebp - 0x48]
mov edx, [ebp - 0x20]
call absolute ]] .. get_player_skill_mastery .. [[;
push eax
mov ecx, [ebp - 0x10]
call absolute 0x455B09
pop edx
cmp eax, edx
jge @std
push ]] .. plus_one .. [[;
push 0x5DF0E0
call absolute 0x4D9E30
add esp, 0x8
@std:
push 0xEC]])

mem.asmpatch(0x4194D7, [[
mov [ebp-24h], edx
and dword ptr [ebp-24h], ]] .. MaxSkillValStr)

mem.asmpatch(0x419545, "test byte ptr [ebp-0xF], " .. GrandMasterBitVH)
mem.asmpatch(0x41956F, "test byte ptr [ebp-0xF], " .. ExpertBitVH)
mem.asmpatch(0x41957D, "test byte ptr [ebp-0xF], " .. MasterBitVH)

asmpatch(0x4195A7, [[
mov ecx, [ebp - 0x48]
mov edx, [ebp - 0x20]
call absolute ]] .. get_player_skill_mastery .. [[;
push eax
mov ecx, [ebp - 0x10]
call absolute 0x455B09
pop edx
cmp eax, edx
jge @std
push ]] .. plus_one .. [[;
push 0x5DF0E0
call absolute 0x4D9E30
add esp, 0x8
@std:
push 0xEC]])

mem.asmpatch(0x41987A, [[
mov [ebp-24h], edx
and dword ptr [ebp-24h], ]] .. MaxSkillValStr)

mem.asmpatch(0x4198E8, "test byte ptr [ebp-0xF], " .. GrandMasterBitVH)
mem.asmpatch(0x419912, "test byte ptr [ebp-0xF], " .. ExpertBitVH)
mem.asmpatch(0x419920, "test byte ptr [ebp-0xF], " .. MasterBitVH)

asmpatch(0x41994A, [[
mov ecx, [ebp - 0x48]
mov edx, [ebp - 0x20]
call absolute ]] .. get_player_skill_mastery .. [[;
push eax
mov ecx, [ebp - 0x10]
call absolute 0x455B09
pop edx
cmp eax, edx
jge @std
push ]] .. plus_one .. [[;
push 0x5DF0E0
call absolute 0x4D9E30
add esp, 0x8
@std:
push 0xEC]])

mem.asmpatch(0x419E59, [[
test word ptr [edx+ecx*2+0x378], ]] .. MaxSkillValStr)
mem.asmpatch(0x419F25, [[
test word ptr [edx+ecx*2+0x378], ]] .. MaxSkillValStr)

-- Increase skill
-- Required skillpoints
mem.asmpatch(0x43234B, [[
mov edx, eax
and edx, ]] .. MaxSkillValStr)
-- Increase skill
mem.asmpatch(0x432359, [[
mov dx, ax
and dx, ]] .. MaxSkillValStr .. [[;
cmp dx, ]] .. MaxSkillBaseStr)
mem.nop(0x43235E, 3)
mem.asmpatch(0x432374, [[
and eax, ]] .. MaxSkillValStr .. [[;
sub [ecx+0x1BF4], eax
]])
--
mem.asmpatch(0x4C9E71, [[
jnz absolute 0x4C9EDE
and eax, ]] .. MaxSkillValStr)
mem.asmpatch(0x4C9EB9, [[
and eax, ]] .. MaxSkillValStr .. [[;
push eax
push 0x4F2F78
]])
mem.asmpatch(0x4C9EDE, [[
and eax, ]] .. MaxSkillValStr .. [[;
inc eax
cmp [edi+0x1BF4], eax
]])

-------------------
-- MonsterCastSpell
asmpatch(0x404D91, [[
and ebx, ]] .. MaxSkillValStr .. [[;
mov dword ptr [ebp - 4], ebx]])
--   Poison Spray shots
asmpatch(0x404E60, [[
mov ecx, eax
shl ecx, 1
dec ecx
jmp absolute 0x404E7F
]], 10)
--   Sparks count
asmpatch(0x4050A9, [[
mov ecx, eax
shl ecx, 1
inc ecx
jmp absolute 0x4050C9
]], 10)
--   Shrapmetal fragments
asmpatch(0x405203, [[
mov ecx, eax
shl ecx, 1
inc ecx
jmp absolute 0x405219
]], 10)
--   Meteor Shower meteors count
asmpatch(0x40563A, [[
mov dword ptr [ebp-0x9C], ecx
mov ecx, dword ptr [0xB21558]
mov dword ptr [ebp-0x84], eax
mov dword ptr [ebp-0x8C], ecx
mov ecx, dword ptr [ebp+0x10]
call absolute 0x455B09
inc eax
shl eax, 2
jmp absolute 0x405672
]])

------------

-- Alchemy
mem.asmpatch(0x4157B4, [[
mov edi, eax
and edi, ]] .. MaxSkillValStr)

-- Notifications
mem.asmpatch(0x417295, [[
mov cx, word [ds:ebx*2+esi+0x378]
and eax, ]] .. MaxSkillValStr .. [[;
push 0x4F3BB8
and ecx, ]] .. MaxSkillValStr)
mem.nop2(0x41729A, 0x4172A7)

mem.asmpatch(0x41741e, [[
mov cx, word [ds:edi]
and eax, ]] .. MaxSkillValStr .. [[;
and ecx, ]] .. MaxSkillValStr)
mem.nop2(0x417423, 0x417426)

mem.asmpatch(0x417463, [[
mov cx, word [ds:edi]
and eax, ]] .. MaxSkillValStr .. [[;
and ecx, ]] .. MaxSkillValStr)
mem.nop2(0x417468, 0x41746B)

-- Id Monster
mem.asmpatch(0x41E07C, [[
mov edi, ecx
and edi, ]] .. MaxSkillValStr)

--
mem.asmpatch(0x4203C1, [[
and ecx, ]] .. MaxSkillValStr .. [[;
inc ecx
cmp eax, ecx
]])

-- Spell target type selection
--   Expert (Skill)
asmpatch(0x425C11, [[
call absolute 0x455B09
cmp eax, 2
jmp short 0x425C59 - 0x425C11
]], 0xA)
--   Expert (Player)
MO.SkillMasteryTarget2 = asmproc([[
pop edx
mov ecx, eax
call absolute ]] .. get_player_skill_mastery .. [[;
jmp absolute 0x425C16]])
--   Master (Player)
MO.SkillMasteryTarget3 = asmproc([[
pop edx
mov ecx, eax
call absolute ]] .. get_player_skill_mastery .. [[;
jmp absolute 0x425C2E]])
--   GM (Player)
MO.SkillMasteryTarget4 = asmproc([[
pop edx
mov ecx, eax
call absolute ]] .. get_player_skill_mastery .. [[;
jmp absolute 0x425C56]])
--   Bless target type
asmpatch(0x425C00, [[
mov ecx, dword ptr [ebp + 8]
test ecx, ecx
jnz short 0x425C11 - 0x425C00
push 16
jmp absolute ]] .. MO.SkillMasteryTarget2,
0x11)
--   Preservation target type
asmpatch(0x425C22, [[
push 16
jmp absolute ]] .. MO.SkillMasteryTarget3)
--   Pain Reflection target type
asmpatch(0x425C3A, [[
push 20
jmp absolute ]] .. MO.SkillMasteryTarget3)
--   Hammerhands target type
asmpatch(0x425C4A, [[
push 18
jmp absolute ]] .. MO.SkillMasteryTarget4)

-- Magic
mem.asmpatch(0x426221, [[
and edi, ]] .. MaxSkillValStr ..[[;
mov dword ptr [ebp - 0x3C], edi
jmp absolute 0x426242]])
mem.asmpatch(0x42623A, [[
mov edi, eax
and edi, ]] .. MaxSkillValStr)
-- Maybe use GetSkillMastery call instead of following patches
mem.asmpatch(0x426242, "test ah, 0x10")
mem.asmpatch(0x426250, [[
test ah, 8
jz absolute 0x42625D
mov dword ptr [ebp-0xC], 3
]])
mem.nop2(0x426255, 0x42625B)
mem.asmpatch(0x42625D, [[
test ah, 4
push 0
pop eax
]])

-- Quick Spell SP cost
mem.asmpatch(0x42E86B, [[
test ah, 0x10
jz absolute 0x42E87D
]])
mem.asmpatch(0x42E87D, [[
test ah, 0x8
jz absolute 0x42E88E
lea eax, [ecx+ecx*4]
]])
mem.asmpatch(0x42E88E, [[
test ah, 0x4
lea eax, [ecx+ecx*4]
]])

-- Spell scroll skill value
-- Set during SpellScrollSkillValue event in ExtraEvents.lua
--mem.asmpatch(0x4320D1, 'push ' .. JoinSkill(5, 3))

-- damageMonsterFromParty
--
mem.asmpatch(0x436FFB, [[
mov ax, [ebx]
and eax, ]] .. MaxSkillValStr)
--   MainHand Weapon
--   Mace Stun
mem.asmpatch(0x4371BE, [[
mov ebx, eax
and ebx, ]] .. MaxSkillValStr)

--   Mace Paralyze
mem.asmpatch(0x4371E9, [[
mov ebx, eax
and ebx, ]] .. MaxSkillValStr)

--   Staff Stun
mem.asmpatch(0x437215, [[
mov ebx, eax
and ebx, ]] .. MaxSkillValStr)

--   Mace Paralyze
mem.asmpatch(0x4377B8, [[
and ebx, ]] .. MaxSkillValStr .. [[;
imul ebx, 1E00h
]])
mem.nop(0x4377BD, 4)

-- Unarmed Evasion
mem.asmpatch(0x4380C4, [[
and edi, ]] .. MaxSkillValStr .. [[;
cmp edx, edi
]])

--
mem.asmpatch(0x439162, [[
and edx, ]] .. MaxSkillValStr .. [[;
mov ecx, esi
]])

-- evt.Cmd
-- evt.CheckSkill
mem.asmpatch(0x443C1B, [[
mov ebp, eax
shr ebp, ]] .. ExpertBitStr)
mem.asmpatch(0x443C26, [[
shr ebp, ]] .. MasterBitStr)
mem.asmpatch(0x443C32, [[
shr ebp, ]] .. GrandMasterBitStr .. [[;
and eax, ]] .. MaxSkillValStr)
mem.nop(0x443C38, 3)
mem.asmpatch(0x443CD6, [[
mov ecx, eax
shr ecx, ]] .. ExpertBitStr)
mem.asmpatch(0x443CE1, [[
shr ecx, ]] .. MasterBitStr)
mem.asmpatch(0x443CED, [[
shr ecx, ]] .. GrandMasterBitStr .. [[;
and eax, ]] .. MaxSkillValStr)
mem.nop(0x443CF3, 3)

-- evt.Cmp
mem.asmpatch(0x4476B8, [[
cmp ebx, ]] .. MaxSkillValStr .. [[;
movzx edi, word ptr [esi+eax*2+0x2F0]
]])
mem.asmpatch(0x4476CC, [[
and edi, ]] .. MaxSkillValStr .. [[;
jmp absolute 0x447AC8
]])

-- evt.Set
mem.asmpatch(0x4481B1, [[
cmp word ptr [ebp+0xC], ]] .. MaxSkillValStr .. [[;
jle absolute 0x4481D1
lea ecx, [edi+eax*2+0x2F0]
mov ax, [ecx]
and ax, ]] .. SkillAndXStr .. [[;
or ax, [ebp+0xC]
]])
mem.nop2(0x4481B7, 0x4481C9)
mem.asmpatch(0x4481D1, [[
mov dx, [ebp+0xC]
lea eax, [edi+eax*2+0x2F0]
xor ecx, ecx
mov cx, [eax]
and ecx, ]] .. MaxSkillValStr)
mem.nop2(0x4481D6, 0x4481E4)

-- evt.Add
mem.asmpatch(0x448AE2, [[
cmp word ptr [ebp+0xC], ]] .. MaxSkillValStr .. [[;
jle absolute 0x448B12
]])
mem.asmpatch(0x448AF8, [[
and eax, ]] .. MaxSkillValStr .. [[;
add eax, edx
cmp eax, ]] .. MaxSkillBaseStr .. [[;
jle absolute 0x448B05
push ]] .. MaxSkillBaseStr)
mem.nop2(0x448AFD, 0x448B04)
mem.asmpatch(0x448B05, [[
and ecx, ]] .. SkillAndStr .. [[;
or ecx, eax
]])
mem.asmpatch(0x448B12, [[
mov dx, [ebp+0xC]
]])
mem.asmpatch(0x448B1E, [[
mov cx, [eax]
and ecx, ]] .. MaxSkillValStr)

-- Monsters.txt
-- SpellSkill
mem.asmpatch(0x453598, [[
mov edi, [ebp+edi-0x1E0]
and eax, ]] .. MaxSkillValStr)
mem.nop(0x45359F, 3)
mem.asmpatch(0x4535B7, [[
jnz absolute 0x4535C2
or word ptr [esi+0x42], ]] .. ExpertBitVStr)
mem.asmpatch(0x4535D1, [[
jnz absolute 0x4535DC
or word ptr [esi+0x42], ]] .. MasterBitVStr)
local gm = "GM"
mem.asmpatch(0x4535EB, [[
jz short @gm
push ]] .. mem.topointer(gm) .. [[;
push edi
call absolute 0x4DA920
test eax, eax
pop ecx
pop ecx
jnz absolute 0x453BAD
@gm:
or word ptr [esi+0x42], ]] .. GrandMasterBitVStr)
mem.nop(0x4535F1, 4)
-- Spell2Skill
mem.asmpatch(0x4536B2, [[
mov edi, [ebp+edi-0x25C]
and eax, ]] .. MaxSkillValStr)
mem.nop(0x4536B9, 3)
mem.asmpatch(0x4536D1, [[
jnz absolute 0x4536DC
or word ptr [esi+0x44], ]] .. ExpertBitVStr)
mem.asmpatch(0x4536EB, [[
jnz absolute 0x4536F6
or word ptr [esi+0x44], ]] .. MasterBitVStr)
mem.asmpatch(0x453705, [[
jz short @gm
push ]] .. mem.topointer(gm) .. [[;
push edi
call absolute 0x4DA920
test eax, eax
pop ecx
pop ecx
jnz absolute 0x453BAD
@gm:
or word ptr [esi+0x44], ]] .. GrandMasterBitVStr)
mem.nop(0x45370B, 4)

-- Spell scroll skill value (Fire Aura etc.)
mem.asmpatch(0x466B88, 'push ' .. JoinSkill(5, 3))

-- Bow GM damage bonus
local BowDamageIncludeItemsBonus = Merge and Merge.Settings and Merge.Settings.Skills
		and Merge.Settings.Skills.BowDamageIncludeItemsBonus or 0

if BowDamageIncludeItemsBonus == 1 then
	-- Take skill bonus from items into account
	-- GetRangedDamageMin
	mem.asmpatch(0x48CA86, [[
	push 5
	mov ecx, esi
	call absolute 0x48EF4F
	and eax, ]] .. MaxSkillValStr)
	-- GetRangedDamageMax
	mem.asmpatch(0x48CAEE, [[
	push 5
	mov ecx, esi
	call absolute 0x48EF4F
	and eax, ]] .. MaxSkillValStr)
	-- CalcRangedDamage
	mem.asmpatch(0x48CBEB, [[
	push 5
	mov ecx, ebx
	sub ecx, 0x382
	call absolute 0x48EF4F
	and eax, ]] .. MaxSkillValStr .. [[;
	add esi, eax]], 0x48CBF2 - 0x48CBEB)
else
	-- Use base skill value
	-- GetRangedDamageMin
	mem.asmpatch(0x48CA86, [[
	mov ax, [esi+0x382]
	and eax, ]] .. MaxSkillValStr)
	-- GetRangedDamageMax
	mem.asmpatch(0x48CAEE, [[
	mov ax, [esi+0x382]
	and eax, ]] .. MaxSkillValStr)
	-- CalcRangedDamage
	mem.asmpatch(0x48CBEB, [[
	mov ax, [ebx]
	and eax, ]] .. MaxSkillValStr .. [[;
	add esi, eax]], 0x48CBF2 - 0x48CBEB)
end
mem.nop(0x48CA8B, 4)
mem.nop(0x48CAF3, 4)

-- GetMeleeDamageRangeText
-- DragonAbility
mem.asmpatch(0x48CC26, [[
and eax, ]] .. MaxSkillValStr .. [[;
lea edi, [eax+0xA]
]])

-- GetRangedDamageRangeText
-- DragonAbility
mem.asmpatch(0x48CCC3, [[
and eax, ]] .. MaxSkillValStr .. [[;
lea edi, [eax+0xA]
]])

-- GetAttackDelay
-- Sword/Axe/Bow
asmpatch(0x48D8B6, [[
mov ecx, esi
mov edx, ebx
push eax
call absolute ]] .. get_player_skill_mastery .. [[;
cmp eax, 2
pop eax]], 0x48D8C8 - 0x48D8B6)
asmpatch(0x48D8CA, [[
and eax, ]] .. MaxSkillValStr, 0x48D8D1 - 0x48D8CA)

-- Armsmaster
asmpatch(0x48D8FC, [[
and edi, ]] .. MaxSkillValStr, 0x48D901 - 0x48D8FC)
asmpatch(0x48D904, [[
mov ecx, esi
mov edx, 0x23
call absolute ]] .. get_player_skill_mastery)

-- GetResistance
-- Leather
mem.asmpatch(0x48DDB9, [[
mov ax, [esi+0x38A]
and eax, ]] .. MaxSkillValStr)
mem.nop(0x48DDBE, 4)

-- CalcStatBonusByItems
-- DragonAbility
mem.asmpatch(0x48E2FD, [[
mov ecx, edi
and ebx, ]] .. MaxSkillValStr)
-- Mind Magic
mem.asmpatch(0x48E75C, [[
mov ax, [edi+0x39A]
]])
-- Magic
mem.asmpatch(0x48E762, [[
and eax, ]] .. MaxSkillValStr .. [[;
shr eax, 1
]])
-- Body Magic
mem.asmpatch(0x48E9D2, [[
mov ax, [edi+0x39C]
]])
-- Air Magic
mem.asmpatch(0x48E9E8, [[
mov ax, [edi+0x392]
]])
-- Dark Magic
mem.asmpatch(0x48EA0F, [[
mov ax, [edi+0x3A0]
]])
-- Light Magic
mem.asmpatch(0x48EA34, [[
mov ax, [edi+0x39E]
]])
-- Fire Magic
mem.asmpatch(0x48EA4A, [[
mov ax, [edi+0x390]
]])
-- Earth Magic
mem.asmpatch(0x48EA60, [[
mov ax, [edi+0x396]
]])
-- Water Magic
mem.asmpatch(0x48EAC9, [[
mov ax, [edi+0x394]
]])
-- Spirit Magic
mem.asmpatch(0x48EADF, [[
mov ax, [edi+0x398]
]])

-- CalcStatBonusBySkills
-- Armsmaster
asmpatch(0x48F0AC, [[
mov ecx, esi
mov edx, 0x23
call absolute ]] .. get_player_skill_mastery)
mem.asmpatch(0x48F0DD, [[
and edi, ]] .. MaxSkillValStr .. [[;
imul edi, [ebp-0x4]
]])
-- Blaster Shoot / Unarmed
mem.asmpatch(0x48F1B6, [[
mov eax, edi
and eax, ]] .. MaxSkillValStr)
-- Bow Shoot
mem.asmpatch(0x48F1C3, [[
mov eax, [ebp+0x8]
and eax, ]] .. MaxSkillValStr)

-- Staff/Dagger/Axe/Spear/Mace Damage
mem.asmpatch(0x48F28E, [[
mov eax, esi
and eax, ]] .. MaxSkillValStr)

-- Unarmed Attack
mem.asmpatch(0x48F2CC, [[
mov eax, esi
and eax, ]] .. MaxSkillValStr)

-- Blaster Attack
mem.asmpatch(0x48F384, [[
mov eax, esi
and eax, ]] .. MaxSkillValStr)
-- Staff Unarmed Attack
mem.asmpatch(0x48F3C4, [[
and esi, ]] .. MaxSkillValStr .. [[;
imul esi, ebx
]])

-- Staff/Dagger/Axe/Spear/Mace Attack
mem.asmpatch(0x48F3CD, [[
mov     eax, [ebp+0x8]
and     eax, ]] .. MaxSkillValStr)
-- Armor Class
mem.asmpatch(0x48F4A4, [[
and edi, ]] .. MaxSkillValStr .. [[;
xor ecx, ecx
]])

-- Dodging Armor Class
mem.asmpatch(0x48F4F8, [[
and esi, ]] .. MaxSkillValStr .. [[;
xor ecx, ecx
]])

--
mem.asmpatch(0x49019C, [[
test ch, 0x10
jz absolute 0x4901A5
]])
mem.asmpatch(0x4901A5, [[
test ch, 0x8
jz absolute 0x4901AD
push 3
]])
mem.asmpatch(0x4901AF, [[
test ch, 0x4
pop eax
setnz al
]])

-- Bodybuilding
mem.asmpatch(0x4901C6, [[
and  ecx, ]] .. MaxSkillValStr .. [[;
imul eax, ecx
]])

-- Meditation
mem.asmpatch(0x4901DB, [[
and  ecx, ]] .. MaxSkillValStr .. [[;
imul eax, ecx
]])

-- Id Item
mem.asmpatch(0x490208, [[
mov eax, ecx
and eax, ]] .. MaxSkillValStr)

-- Repair
mem.asmpatch(0x490255, [[
mov eax, ecx
and eax, ]] .. MaxSkillValStr)

-- Merchant
mem.asmpatch(0x4902A3, [[
mov ecx, eax
and esi, ]] .. MaxSkillValStr)
mem.asmpatch(0x4902D0, [[
and edi, ]] .. MaxSkillValStr .. [[;
imul eax, edi
]])

-- Perception
mem.asmpatch(0x49030E, [[
and esi, ]] .. MaxSkillValStr .. [[;
imul eax, esi
and edi, ]] .. MaxSkillValStr)
mem.nop(0x490314, 3)

-- Disarm Traps
mem.asmpatch(0x490336, [[
and esi, ]] .. MaxSkillValStr .. [[;
and edi, ]] .. MaxSkillValStr)

-- Learning
asmpatch(0x490378, [[
mov edx, eax
test edx, edx
jz @end
mov ecx, eax
call absolute 0x49019C
dec eax
movzx ecx, word ptr [esi+0x3C4]
and ecx, ]] .. MaxSkillValStr .. [[;
imul eax, ecx
and edx, ]] .. MaxSkillValStr ..[[;
lea eax, [eax+edx+9]
@end:
pop esi
]], 0x49039A - 0x490378)

-- roster.txt
mem.asmpatch(0x494C3B, [[
mov edi, ]] .. GrandMasterBitVStr)
mem.asmpatch(0x494C5B, [[
mov edi, ]] .. MasterBitVStr)
mem.asmpatch(0x494C79, [[
jnz absolute 0x494C7E
mov edi, ]] .. ExpertBitVStr)

--[=[
mem.asmpatch(0x4B0AA5, [[
lea ecx, [eax+ecx*2+0x378]
and word ptr [ecx], ]] .. MaxSkillValStr)
mem.nop(0x4B0AAC, 4)
]=]

--
mem.asmpatch(0x4B0E79, [[
and edi, ]] .. MaxSkillValStr .. [[;
cmp eax, edx
]])

-- Donation spell skill value (overwritten in Reputation.lua)
mem.asmpatch(0x4B5B9E, "or edx, " .. MasterBitVStr)

-- Lloyd's Beacon interface
mem.asmpatch(0x4D1485, [[
test ah, 0x10
mov dword ptr [ebp-0x14], 1
jnz absolute 0x4D14A2
test ah, 0x8
jnz absolute 0x4D14A2
test ah, 0x4
]])
mem.nop2(0x4D148A, 0x4D1497)
mem.asmpatch(0x4D173D, [[
test ah, 0x10
mov dword ptr [ebp-0x18], 1
jnz absolute 0x4D1756
test ah, 0x8
jnz absolute 0x4D1756
test ah, 0x4
]])
mem.nop2(0x4D1747, 0x4D174F)

Log(Merge.Log.Info, "Init finished: %s", LogId)
