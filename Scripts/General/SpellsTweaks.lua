local ceil = math.ceil
local asmpatch = mem.asmpatch

local function GetPlayer(ptr)
	local PLId = (ptr - Party.PlayersArray[0]["?ptr"]) / Party.PlayersArray[0]["?size"]
	local PL = Party.PlayersArray[PLId]
	return PL, PlId
end

local function GetMonster(ptr)
	local MonId = (ptr - Map.Monsters[0]["?ptr"]) / Map.Monsters[0]["?size"]
	local Mon = Map.Monsters[MonId]
	return Mon, MonId
end

-- Change chance calculation for "slow" and "mass distortion" spells to be applied.
local function CanApplySpell(Skill, Mastery, Resistance)
	if Resistance == const.MonsterImmune then
		return false
	else
		return (math.random(5, 100) + Skill + Mastery*2.5) > Resistance
	end
end

local function CanApplySlowMassDistort(d)
	if Map.Monsters.count == 0 then
		return 0
	end

	local PL = GetPlayer(mem.u4[d.ebp-0x1c])
	local Skill, Mastery = SplitSkill(PL:GetSkill(const.Skills.Earth))

	local Mon = GetMonster(d.eax)
	local Res = Mon.Resistances[const.Damage.Earth]

	if CanApplySpell(Skill, Mastery, Res) then
		d.eax = 1
	else
		--d.eax = 0
		d.eax = 1
	end
end

mem.nop(0x426f97, 3)
mem.hook(0x426fa2, CanApplySlowMassDistort)
mem.nop(0x426910, 2)
mem.nop(0x426918, 1)
mem.hook(0x42691e, CanApplySlowMassDistort)

-- Make Stun paralyze target for small duration
mem.autohook2(0x437751, function(d)
	local Player = GetPlayer(d.ebx)
	local Skill, Mas = SplitSkill(Player:GetSkill(const.Skills.Earth))
	local mon = GetMonster(d.ecx)

	local Buff = mon.SpellBuffs[const.MonsterBuff.Paralyze]
	Buff.ExpireTime = math.max(Game.Time + const.Minute + Skill*Mas, Buff.ExpireTime)
end)

-- Make Town Portal be always sccessfull for GM and always successfull for M if there are no hostile enemies.
function events.CanCastTownPortal(t)
	t.Handled = true
	if t.Mastery == 4 or not (Party.EnemyDetectorRed or Party.EnemyDetectorYellow) then
		t.CanCast = true
	else
		t.CanCast = false
		Game.ShowStatusText(Game.GlobalTxt[480])
	end
end

-- Change chance of monster being stunned
mem.autohook2(0x437713, function(d)
	local Player = GetPlayer(d.ebx)
	local Mon = GetMonster(d.esi)
	local Skill, Mastery = SplitSkill(Player:GetSkill(const.Skills.Earth))

	if CanApplySpell(Skill, Mastery, Mon.Resistances[const.Damage.Earth]) then
		d.eax = 1
	else
		d.eax = 0
	end
end)

-- Change chance calculation for Control Undead
mem.nop(0x42c3aa, 6)
mem.nop(0x42c413, 6)
mem.nop(0x42c41c, 2)
mem.nop(0x42c424, 1)
mem.hook(0x42c42a, function(d)
	local mon = GetMonster(d.eax)

	if mon.DarkResistance == const.MonsterImmune or Game.IsMonsterOfKind(mon.Id, const.MonsterKind.Undead) == 0 then
		d.eax = 0
		return
	end

	local Player = GetPlayer(mem.u4[d.ebp-0x1c])
	local Skill, Mas = SplitSkill(Player:GetSkill(const.Skills.Dark))

	if mon.DarkResistance > Skill*Mas then
		d.eax = 0
		return
	end

	if Mas > 3 then
		mon.Group = 0
		mon.Ally = 9999 -- Same as reanimated monster's ally.
	end
	mon.Hostile = false
	mon.ShowAsHostile = false
	d.eax = 1
end)

-- Fix Fire Spikes counting (no extra spike)
asmpatch(0x4266D7, "jge absolute 0x42735B")

-- Fix Shield party spell buff
asmpatch(0x43800A, [[
cmp dword ptr [0xB21818 + 0x4], 0
jl @std
jg @half
cmp dword ptr [0xB21818], 0
jbe @std
@half:
sar dword ptr [ebp - 0x4], 1
@std:
cmp dword ptr [ebx + 0x1B08], 0
]])

-- Make monsters' power cure heal nearby monsters

local function GetDist(t,x,y,z)
	local px, py, pz  = XYZ(t)
	return math.sqrt((px-x)^2 + (py-y)^2 + (pz-z)^2)
end

local function MonCanBeHealed(Mon, ByMon)
	if Mon.Active and Mon.HP > 0 and Mon.HP < Mon.FullHP then
		if (Mon.Group == ByMon.Group or Mon.Ally == ByMon.Ally or Game.HostileTxt[ceil(Mon.Id/3)][ceil(ByMon.Id/3)] == 0) and GetDist(Mon, XYZ(ByMon)) < 2000 then
			return true
		end
	end
	return false
end

function events.MonsterCastSpellM(t)
	if t.Spell == 77 then
		local Skill, Mas = SplitSkill(t.Monster.Spell == t.Spell and t.Monster.SpellSkill or t.Monster.Spell2Skill)
		local Heal = 10 + 5 *Skill
		local x,y,z = XYZ(t.Monster)
		local Mon = t.Monster
		local count = 0
		for i,v in Map.Monsters do
			if MonCanBeHealed(v, Mon) then
				v.HP = math.min(v.HP + Heal, v.FullHP)
				Game.ShowMonsterBuffAnim(i)
				count = count + 1
				if count >= 5 then
					break
				end
			end
		end
	end
end

function events.MonsterCanCastSpell(t)
	if t.Spell == 77 then
		local x,y,z = XYZ(t.Monster)
		local Mon = t.Monster
		for i,v in Map.Monsters do
			if MonCanBeHealed(v, Mon) then
				t.Result = 1
				break
			end
		end
	end
end

-- Fix monster Day of Protection references
asmpatch(0x42595B, "cmp dword ptr [eax + 0x1A0], edx")
asmpatch(0x425965, "cmp dword ptr [eax + 0x19C], edx")
asmpatch(0x42596D, "movzx ecx, word ptr [eax + 0x1A4]")

-- Monsters cannot cast paralyze, replace this spell:
local SpellReplace = {[81] = 87}
function events.MonsterCastSpellM(t)
	t.Spell = SpellReplace[t.Spell] or t.Spell
end

-- Enable several disabled monster spells
mem.IgnoreProtection(true)
mem.u1[0x40603A] = 0	-- Deadly Swarm
mem.u1[0x406061] = 0	-- Flying Fist
mem.u1[0x406072] = 4	-- Make Shrapmetal to use Sparks processing instead of broken own one
mem.IgnoreProtection(false)

--[[ Transform high potency catalyst potions into philosopher stones
function events.PlayerCastSpell(t)
	if t.SpellId == 30 then -- Enchant item
		local item = t.Player.Inventory[t.InventorySlot]
		item = t.Player.Items[item]

		if item.Number == 221 and item.Bonus >= 70 then
			t.Handled = true
			Game.PlaySound(11070)
			item.Number = 1021
		end
	end
end
]]
