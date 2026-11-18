
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
		if Target.AgeBonus <= 0 then
			Target.AgeBonus = Target.AgeBonus - math.ceil(Power/10)
			return true
		end
	end
end

-- Divine boost
evt.PotionEffects[60] = function(IsDrunk, Target, Power)
	if IsDrunk then
		local Buffs = Target.SpellBuffs
		local ExpireTime = Game.Time + Power*const.Minute*30
		local Effect = Power*3

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
		local Effect = Power*3

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
		evt[PlayerId].Add{"LevelBonus", 20}
	end
end

-- Essences
local function EssenseOf(Target, Stat, cStat, ItemId)
	local PlayerId = GetPlayerId(Target)
	PSet.UsedPotions[PlayerId] = PSet.UsedPotions[PlayerId] or {}

	local t = PSet.UsedPotions[PlayerId]
	if t[ItemId] then
		return -1
	else
		t[ItemId] = true
		Target[Stat]  = Target[Stat] + 15
		Target[cStat] = Target[cStat] - 5
		return true
	end
end

-- Essence of Might
evt.PotionEffects[52] = function(IsDrunk, Target, Power, ItemId)
	if IsDrunk then
		return EssenseOf(Target, "MightBase", "IntellectBase", ItemId)
	end
end

-- Essence of Intellect
evt.PotionEffects[53] = function(IsDrunk, Target, Power, ItemId)
	if IsDrunk then
		return EssenseOf(Target, "IntellectBase", "MightBase", ItemId)
	end
end

-- Essence of Personality
evt.PotionEffects[54] = function(IsDrunk, Target, Power, ItemId)
	if IsDrunk then
		return EssenseOf(Target, "PersonalityBase", "SpeedBase", ItemId)
	end
end

-- Essence of Endurance
evt.PotionEffects[55] = function(IsDrunk, Target, Power, ItemId)
	if IsDrunk then
		local PlayerId = GetPlayerId(Target)
		PSet.UsedPotions[PlayerId] = PSet.UsedPotions[PlayerId] or {}
		local t = PSet.UsedPotions[PlayerId]

		if t[ItemId] then
			return -1
		else
			t[ItemId] = true
			Target.MightBase		= Target.MightBase - 1
			Target.IntellectBase	= Target.IntellectBase - 1
			Target.PersonalityBase	= Target.PersonalityBase - 1
			Target.AccuracyBase		= Target.AccuracyBase - 1
			Target.SpeedBase		= Target.SpeedBase - 1
			Target.LuckBase			= Target.LuckBase - 1
			Target.EnduranceBase	= Target.EnduranceBase + 15
		end
	end
end

-- Essence of Accuracy
evt.PotionEffects[56] = function(IsDrunk, Target, Power, ItemId)
	if IsDrunk then
		return EssenseOf(Target, "AccuracyBase", "LuckBase", ItemId)
	end
end

-- Essence of Speed
evt.PotionEffects[57] = function(IsDrunk, Target, Power, ItemId)
	if IsDrunk then
		return EssenseOf(Target, "SpeedBase", "PersonalityBase", ItemId)
	end
end

-- Essence of Luck
evt.PotionEffects[58] = function(IsDrunk, Target, Power, ItemId)
	if IsDrunk then
		return EssenseOf(Target, "LuckBase", "AccuracyBase", ItemId)
	end
end

-- Potion of the Gods
evt.PotionEffects[63] = function(IsDrunk, Target, Power, ItemId)
	if IsDrunk then
		local PlayerId = GetPlayerId(Target)
		PSet.UsedPotions[PlayerId] = PSet.UsedPotions[PlayerId] or {}
		if PSet.UsedPotions[PlayerId][ItemId] then
			return -1
		else
			PSet.UsedPotions[PlayerId][ItemId] = true

			local Stats = Target.Stats
			for i = 0, 6 do
				Stats[i].Base = Stats[i].Base + 20
			end
			Target.AgeBonus = Target.AgeBonus + 10
		end
	end
end

-- Potion of Doom
evt.PotionEffects[59] = function(IsDrunk, Target, Power)
	if IsDrunk then
		Target.MightBase		= Target.MightBase + 1
		Target.IntellectBase	= Target.IntellectBase + 1
		Target.PersonalityBase	= Target.PersonalityBase + 1
		Target.EnduranceBase	= Target.EnduranceBase + 1
		Target.AccuracyBase		= Target.AccuracyBase + 1
		Target.SpeedBase		= Target.SpeedBase + 1
		Target.LuckBase			= Target.LuckBase + 1

		for i,v in Target.Resistances do
			v.Base = v.Base + 1
		end
		Target.AgeBonus = Target.AgeBonus + 5
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
