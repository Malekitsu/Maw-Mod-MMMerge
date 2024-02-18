
--------------------------------
----	Hireling's skills	----
--------------------------------

local NPCBonuses = {}
NPCBonuses.Skills	= {}
NPCBonuses.Stats	= {}
NPCBonuses.Gold		= nil

vars.ProfUsed = vars.ProfUsed or {}
local ProfUsed = vars.ProfUsed

---- Service functions
local function SetProfUsed(NPC)
	local Prof = NPC or GetCurrentNPC()
	ProfUsed[Prof] = Game.DayOfMonth
end

local function CanUseProf(NPC)
	local Prof = NPC or GetCurrentNPC()
	local State = ProfUsed[Prof]
	return State == nil or State ~= Game.DayOfMonth
end

local function CastFollowersSpell(Spell, Skill, Mastery)
	if CanUseProf(NPC) then
		CastSpellDirect(Spell,Skill,Mastery)
		SetProfUsed(NPC)
		Message(Game.GlobalTxt[569])
	else
		Message(Game.GlobalTxt[561])
	end
end

---- Skill bonuses ----
-- SkillID = {ProfID = Bonus}
local SkillBonuses
local function CountSkillBonus(skill)
	local Bonus = SkillBonuses[skill]
	local res = 0
	if Bonus then
		for k,v in pairs(vars.NPCFollowers) do
			local Amount = Bonus[Game.NPC[v].Profession]
			if Amount then
				res = math.max(res, Amount)
			end
		end
	end
	NPCBonuses.Skills[skill] = res
	return res
end

function events.GetSkill(t)
	local Skill, Mas = SplitSkill(t.Result)
	Skill = Skill + (NPCBonuses.Skills[t.Skill] or CountSkillBonus(t.Skill))
	t.Result = JoinSkill(Skill, Mas)
end

---- Crossing map bonuses ----
-- ProfID == Amount of days to subtract
local CrossMapBonuses
local function CountCrossMapBonus()
	local res = 0
	for k,v in pairs(vars.NPCFollowers) do
		local Bonus = CrossMapBonuses[Game.NPC[v].Profession]
		if Bonus then
			res = res + Bonus
		end
	end
	return res
end

function events.WalkToMap(t)
	t.Days = math.max(1, t.Days-CountCrossMapBonus())
end

---- Boat/stable travels bonuses
local BoatBonuses
local StableBonuses
local function CountBSBonuses(t)
	local res = 0
	for k,v in pairs(vars.NPCFollowers) do
		local Bonus = t[Game.NPC[v].Profession]
		if Bonus then
			res = res + Bonus
		end
	end
	return res
end

function events.GetTravelDaysCost(t)
	local Type = Game.Houses[t.House].Type
	if Type == 27 then
		t.Days = math.max(1, t.Days - CountBSBonuses(StableBonuses))
	else
		t.Days = math.max(1, t.Days - CountBSBonuses(BoatBonuses))
	end
end

---- Food consumption
-- ProfID == Amount to subtract
local FoodConBonuses
function events.CalcRestFoodCost(t)
	for k,v in pairs(vars.NPCFollowers) do
		local Bonus = FoodConBonuses[Game.NPC[v].Profession]
		if Bonus then
			t.Amount = math.max(1, t.Amount - Bonus)
		end
	end
end

---- Stat bonuses
-- StatID = {ProfID = Bonus}
local StatsBonuses
local function CountStatBonus(stat)
	local Bonus = StatsBonuses[stat]
	local res = 0
	if Bonus then
		for k,v in pairs(vars.NPCFollowers) do
			local Amount = Bonus[Game.NPC[v].Profession]
			if Amount then
				res = res + Amount
			end
		end
	end
	NPCBonuses.Stats[stat] = res
	return res
end

function events.CalcStatBonusByItems(t)
	t.Result = t.Result + (NPCBonuses.Stats[t.Stat] or CountStatBonus(t.Stat))
	t.Result = t.Result
end

---- Constant party buffs
local TimerPeriod = 8*const.Minute
-- ProfID = {Buff = PartyBuff, Skill = , Power = }
local FollowersBuffs
local function SetBuffs()
	for k,v in pairs(vars.NPCFollowers) do
		local Buff = FollowersBuffs[Game.NPC[v].Profession]
		if Buff then
			local cBuff = Party.SpellBuffs[Buff.Buff]
			cBuff.ExpireTime = Game.Time + TimerPeriod + const.Minute
			cBuff.Power = Buff.Power
			cBuff.Skill = Buff.Skill
		end
	end
end

function events.AfterLoadMap()
	Timer(SetBuffs, TimerPeriod, true)
end

---- Repair items
function events.CanRepairItem(t)
	local Type = Game.ItemsTxt[t.Item.Number].EquipStat + 1

	if Type >= 4 and Type <= 10 then -- armors
		if NPCFollowers.HaveProfession(2) then
			t.CanRepair = true
		end

	elseif Type >= 11 and Type <= 18 then -- magic items
		if NPCFollowers.HaveProfession(3) then
			t.CanRepair = true
		end

	else -- weapons
		if NPCFollowers.HaveProfession(1) then
			t.CanRepair = true
		end
	end
end

---- Identify items
function events.CanIdentifyItem(t)
	local Type = Game.ItemsTxt[t.Item.Number].EquipStat + 1
	if Type >= 7 and Type <= 18 and NPCFollowers.HaveProfession(4) then
		t.CanIdentify = true
	end
end

------------------------------------------------
---- Payments
local GoldFindBonuses = {}
local function CountGoldBonus()
	local res = 0
	for k,v in pairs(vars.NPCFollowers) do
		local Bonus = GoldFindBonuses[Game.NPC[v].Profession]
		if Bonus then
			res = res + Bonus
		end
	end
	NPCBonuses.Gold = res
	return res
end

NPCFollowers.LastGoldTaken = 0
function events.BeforeGotGold(t)
	-- Gold bonuses
	t.Amount = t.Amount + t.Amount*(NPCBonuses.Gold or CountGoldBonus())

	-- Payments
	if Game.CurrentScreen == 13 then
		NPCFollowers.LastGoldTaken = 0
	else
		NPCFollowers.LastGoldTaken = NPCFollowers.GetTotalFee(t.Amount)
		t.Amount = math.max(0, t.Amount - NPCFollowers.LastGoldTaken)
	end
end

----

local function NeedBonusesRecount(topic)
	if not topic or not NPCFollowers.HireState then
		NPCBonuses.Skills	= {}
		NPCBonuses.Stats	= {}
		NPCBonuses.Gold	= nil
	end
end
NPCFollowers.NeedBonusesRecount = NeedBonusesRecount

evt.Global[NPCFollowers.DismissNPCTopic]	= NeedBonusesRecount
evt.Global[NPCFollowers.HireNPCTopic]		= NeedBonusesRecount

------------------------------------------------
----				Values					----
------------------------------------------------

---- Find gold bonuses

GoldFindBonuses = {[31] = 0.10, [32] = 0.20, [45] = 0.10}

---- Skill bonuses
SkillBonuses = {

[const.Skills.Learning] = {[4]	= 5, [13] = 10, [14] = 15},
[const.Skills.Staff]	= {[15] = 2, [16] = 3, [46] = 2},
[const.Skills.Sword]	= {[15] = 2, [16] = 3, [46] = 2},
[const.Skills.Dagger]	= {[15] = 2, [16] = 3, [46] = 2},
[const.Skills.Axe]		= {[15] = 2, [16] = 3, [46] = 2},
[const.Skills.Spear]	= {[15] = 2, [16] = 3, [46] = 2},
[const.Skills.Bow]		= {[15] = 2, [16] = 3, [46] = 2},
[const.Skills.Mace]		= {[15] = 2, [16] = 3, [46] = 2},
[const.Skills.Leather]	= {[46] = 2},
[const.Skills.Chain]	= {[46] = 2},
[const.Skills.Plate]	= {[46] = 2},
[const.Skills.Fire]		= {[17] = 2, [18] = 3, [19] = 4},
[const.Skills.Air]		= {[17] = 2, [18] = 3, [19] = 4},
[const.Skills.Water]	= {[17] = 2, [18] = 3, [19] = 4},
[const.Skills.Earth]	= {[17] = 2, [18] = 3, [19] = 4},
[const.Skills.Spirit]	= {[17] = 2, [18] = 3, [19] = 4},
[const.Skills.Mind]		= {[17] = 2, [18] = 3, [19] = 4},
[const.Skills.Body]		= {[17] = 2, [18] = 3, [19] = 4},
[const.Skills.Light]	= {[17] = 2, [18] = 3, [19] = 4},
[const.Skills.Dark]		= {[17] = 2, [18] = 3, [19] = 4},
[const.Skills.Merchant]		= {[20] = 4, [21] = 6},
[const.Skills.DisarmTraps]	= {[25] = 4, [26] = 6},
[const.Skills.Perception]	= {[22] = 6, [47] = 5}
}

------------------------------------------------
---- Crossing map bonuses
-- ProfID == Amount of days to subtract
CrossMapBonuses = {

[5] = 1,
[6] = 2,
[7] = 3,
[44] = 1

}

------------------------------------------------
---- Travel days bonuses
-- ProfID == Amount of days to subtract
BoatBonuses = {[8] = 2, [9] = 3, [44] = 1, [45] = 2}
StableBonuses = {[35] = 2, [44] = 1}

------------------------------------------------
---- Food consumption
FoodConBonuses = {

[29] = 1,
[30] = 2

}

------------------------------------------------
---- Stat bonuses
-- StatID = {ProfID = Bonus}
StatsBonuses = {

[const.Stats.AirResistance]		= {[37] = 20},
[const.Stats.FireResistance]	= {[37] = 20},
[const.Stats.WaterResistance]	= {[37] = 20},
[const.Stats.EarthResistance]	= {[37] = 20},

[const.Stats.Luck] = {[27] = 10, [28] = 20}

}

------------------------------------------------
---- Constant party buffs
-- ProfID = {Buff = PartyBuff, Skill = , Power = }
FollowersBuffs = {

[38] = {Buff = const.PartyBuff.WizardEye, Skill = 4, Power = 2}

}

------------------------------------------------
---- Follower's skill-topic functions
local function MakeFollowersFood()
	local cNPC = GetCurrentNPC()

	if not cNPC then
		return
	end

	local Amount = Game.NPC[cNPC].Profession == 34 and 2 or 1
	if Party.Food > 14 then
		Message(Game.GlobalTxt[140])
	elseif CanUseProf() then
		evt.ForPlayer("Current").Add{"Food", Amount}
		SetProfUsed()
		Message(Game.GlobalTxt[569])
	else
		Message(Game.GlobalTxt[561])
	end
end

local function HealFollowersParty()
	local cNPC = GetCurrentNPC()

	if not cNPC then
		return
	end

	if CanUseProf() then
		local Prof = Game.NPC[cNPC].Profession

		if Prof == 12 then
			CastSpellDirect(88,10,10)

		elseif Prof == 11 then
			CastSpellDirect(77,10,10)

			evt.ForPlayer("All")
			for i = 113, 118 do
				evt.Subtract{i, 1}
			end

			for i = 107, 112 do
				evt.Subtract{i, 1}
			end

			for i,v in Party do
				v.HP = v:GetFullHP()
			end

		else
			CastSpellDirect(77,10,10)
			for i,v in Party do
				v.HP = v:GetFullHP()
			end
		end

		SetProfUsed()
		Message(Game.GlobalTxt[569])
	else
		Message(Game.GlobalTxt[561])
	end
end

-- Cast heroism
evt.Global[1720] = function()
	CastFollowersSpell(51, 5, 3)
end

-- Cast bless
evt.Global[1719] = function()
	CastFollowersSpell(46, 5, 3)
end

-- Cast town portal
evt.Global[1718] = function()
	local NPC = GetCurrentNPC()
	if CanUseProf(NPC) then
		if Party.EnemyDetectorRed or Party.EnemyDetectorYellow then
			Message(Game.GlobalTxt[480])
		else
			SetProfUsed()
			ExitCurrentScreen(false, true)
			CastSpellDirect(31, 10, 4)
		end
	else
		Message(Game.GlobalTxt[561])
	end

end

-- Cast water walk
evt.Global[1717] = function()
	CastFollowersSpell(27, 3, 4)
end

-- Cast fly
evt.Global[1716] = function()
	CastFollowersSpell(21, 2, 4)
end

-- Make food
evt.Global[1715] = function()
	MakeFollowersFood()
end

-- Heal party
evt.Global[1714] = function()
	HealFollowersParty()
end

