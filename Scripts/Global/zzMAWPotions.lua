
vars.PotionBuffs = vars.PotionBuffs or {}
local PSet	= vars.PotionBuffs
PSet.UsedPotions = PSet.UsedPotions or {}

local function GetPlayerId(Player)
	return Player:GetIndex()
end

local function GetPartyId(Player)
	for i, v in Party do
		if v['?ptr'] == Player['?ptr'] then
			return i
		end
	end
end

-- Rejuvenation potion
evt.PotionEffects[51] = function(IsDrunk, Target, Power)
	if IsDrunk then
		Target.MightBase		= Target.MightBase - 5
		Target.IntellectBase	= Target.IntellectBase - 5
		Target.PersonalityBase	= Target.PersonalityBase - 5
		Target.EnduranceBase	= Target.EnduranceBase - 5
		Target.AccuracyBase		= Target.AccuracyBase - 5
		Target.SpeedBase		= Target.SpeedBase - 5
		Target.LuckBase			= Target.LuckBase - 5

		for i,v in Target.Resistances do
			v.Base = v.Base - 5
		end
		Target.BirthYear = Target.BirthYear + 10
	end
end

-- Divine boost
evt.PotionEffects[60] = function(IsDrunk, Target, Power)
	if IsDrunk then
		local Buffs = Target.SpellBuffs
		local ExpireTime = Game.Time + Power*const.Minute*30
		local Effect = 10+Power

		for k,v in pairs({"TempLuck", "TempIntellect", "TempPersonality", "TempAccuracy", "TempEndurance", "TempSpeed", "TempMight"}) do
			Buff = Buffs[const.PlayerBuff[v]]
			Buff.ExpireTime = ExpireTime
			Buff.Power = Effect
		end
	end
end

-- Divine protection
evt.PotionEffects[61] = function(IsDrunk, Target, Power)
	if IsDrunk then
		local Buffs = Target.SpellBuffs
		local ExpireTime = Game.Time + Power*const.Minute*30
		local Effect = 10+Power

		for k,v in pairs({"AirResistance", "BodyResistance", "EarthResistance", "FireResistance", "MindResistance", "WaterResistance"}) do
			Buff = Buffs[const.PlayerBuff[v]]
			Buff.ExpireTime = ExpireTime
			Buff.Power = Effect
		end
	end
end

-- Divine Transcendence
evt.PotionEffects[62] = function(IsDrunk, Target, Power)
	if IsDrunk then
		local PlayerId = GetPartyId(Target)
		evt[PlayerId].Add{"LevelBonus", 10+math.round(Power/4)}
	end
end

-- Potion of Doom
evt.PotionEffects[59] = function(IsDrunk, Target, Power)
	if IsDrunk then
		if Game.Year<=Target.BirthYear+100 then
			Target.MightBase		= Target.MightBase + 5
			Target.IntellectBase	= Target.IntellectBase + 5
			Target.PersonalityBase	= Target.PersonalityBase + 5
			Target.EnduranceBase	= Target.EnduranceBase + 5
			Target.AccuracyBase		= Target.AccuracyBase + 5
			Target.SpeedBase		= Target.SpeedBase + 5
			Target.LuckBase			= Target.LuckBase + 5

			for i,v in Target.Resistances do
				v.Base = v.Base + 5
			end
			Target.BirthYear = Target.BirthYear - 10
		else
			Game.ShowStatusText("Can't drink anymore")
		end
	end
end

-- Pure resistances
local function PureResistance(Target, Stat, ItemId)
	local PlayerId = GetPlayerId(Target)
	PSet.UsedPotions[PlayerId] = PSet.UsedPotions[PlayerId] or {}

	local t = PSet.UsedPotions[PlayerId]
	if t[ItemId] then
		return -1
	else
		t[ItemId] = true
		Target.Resistances[Stat].Base = Target.Resistances[Stat].Base + 40
	end
end

evt.PotionEffects[64] = function(IsDrunk, Target, Power, ItemId) return PureResistance(Target, 0, ItemId) end
evt.PotionEffects[65] = function(IsDrunk, Target, Power, ItemId) return PureResistance(Target, 1, ItemId) end
evt.PotionEffects[66] = function(IsDrunk, Target, Power, ItemId) return PureResistance(Target, 2, ItemId) end
evt.PotionEffects[67] = function(IsDrunk, Target, Power, ItemId) return PureResistance(Target, 3, ItemId) end
evt.PotionEffects[68] = function(IsDrunk, Target, Power, ItemId) return PureResistance(Target, 7, ItemId) end
evt.PotionEffects[69] = function(IsDrunk, Target, Power, ItemId) return PureResistance(Target, 8, ItemId) end

-- Protection from Magic
evt.PotionEffects[70] = function(IsDrunk, Target, Power)
	if IsDrunk then
		local Buff = Party.SpellBuffs[const.PartyBuff.ProtectionFromMagic]
		Buff.ExpireTime = Game.Time + const.Minute*30*math.max(Power, 1)
		Buff.Power = 3
		Buff.Skill = JoinSkill(10,4)
	end
end

--remove older potions
removelist={52,53,54,55,56,57,58,63}

for i=1,#removelist do
	evt.PotionEffects[removelist[i]] = function(IsDrunk, t, Power)
		Game.ShowStatusText("This potion has no power in MAW")
	end
end

evt.PotionEffects[43] = function(IsDrunk, t, Power)
	if t.Bonus2==0 and Game.ItemsTxt[t.Number].Skill<7 then
		t.Bonus2=46
		Mouse.Item.Number=0
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end
evt.PotionEffects[26] = function(IsDrunk, t, Power)
	if t.Bonus2==0 and Game.ItemsTxt[t.Number].Skill<7 then
		t.Bonus2=11
		Mouse.Item.Number=0
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end
evt.PotionEffects[27] = function(IsDrunk, t, Power)
	if t.Bonus2==0 and Game.ItemsTxt[t.Number].Skill<7 then
		t.Bonus2=5
		Mouse.Item.Number=0
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end
evt.PotionEffects[28] = function(IsDrunk, t, Power)
	if t.Bonus2==0 and Game.ItemsTxt[t.Number].Skill<7 then
		t.Bonus2=14
		Mouse.Item.Number=0
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end
evt.PotionEffects[29] = function(IsDrunk, t, Power)
	if t.Bonus2==0 and Game.ItemsTxt[t.Number].Skill<7 then
		t.Bonus2=46
		Mouse.Item.Number=0
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end
evt.PotionEffects[30] = function(IsDrunk, t, Power)
	if t.Bonus2==0 and Game.ItemsTxt[t.Number].Skill<7 then
		t.Bonus2=59
		Mouse.Item.Number=0
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end
