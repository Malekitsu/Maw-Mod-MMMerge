local min, max, floor, ceil, random = math.min, math.max, math.floor, math.ceil, math.random
local PlayerEffects		= {}
local ArtifactBonuses	= {}
local SpecialBonuses	= {}
local StoreEffects
local AdvInnScreen = const.Screens.AdventurersInn

local function PlayerInParty(PlayerIndex)
	for _, i in Party.PlayersIndexes do
		if i == PlayerIndex then
			return true
		end
	end
	return false
end

------------------------------------------------
----			Base events					----
------------------------------------------------

------------------------------------------------
-- Make artifacts unique

local PlacedArtifacts = {
	-- MM8
	501,502,503,504,508,509,516,519,523,539,540,541,
	-- MM7
	1333,1334,1335,1336,1337,1338,
	-- MM6
	2020,2023,2032,2033,2034
}

vars.GotArtifact = vars.GotArtifact or {}
for k,v in pairs(PlacedArtifacts) do
	vars.GotArtifact[v] = true
end

local GItems = Game.ItemsTxt
local ArtifactsList = {}
for i,v in GItems do
	if v.Material > 0 and v.Value > 0 and v.ChanceByLevel[6] > 0 then
		table.insert(ArtifactsList, i)
	end
end

function events.GotItem(i)
	local v = GItems[i]
	if v.Material > 0 and v.Value > 0 and v.ChanceByLevel[6] > 0 then
		vars.GotArtifact[i] = true
	end
end

local function GetNotFoundArts()
	local t = {}
	for k,v in pairs(ArtifactsList) do
		if not vars.GotArtifact[v] then
			table.insert(t, v)
		end
	end
	return t
end

local function RosterHaveItem(ItemId)
	for _,Pl in Party.PlayersArray do
		for __,Item in Pl.Items do
			if Item.Number == ItemId then
				return true
			end
		end
	end
end

local function RecountFoundArtifacts()
	for ItemId,v in pairs(vars.GotArtifact) do
		vars.GotArtifact[ItemId] = RosterHaveItem(ItemId)
	end
	for k,v in pairs(PlacedArtifacts) do
		vars.GotArtifact[v] = true
	end
end
Game.RecountFoundArtifacts = RecountFoundArtifacts

function events.ItemGeneratedM(Item)
	local Num = Item.Number
	local ItemTxt = GItems[Num]
	if ItemTxt.Material > 0 and ItemTxt.Value > 0 and ItemTxt.ChanceByLevel[6] > 0 and vars.GotArtifact[Num] then
		local cArts = GetNotFoundArts()
		if #cArts == 0 then
			Item:Randomize(5, ItemTxt.EquipStat+1)
		else
			Item.Number = cArts[random(#cArts)]
		end
	end
end

function events.ArtifactGenerated(t)
	local cArts = GetNotFoundArts()
	if #cArts == 0 then
		t.ItemId = random(177, 186)
	else
		t.ItemId = cArts[random(#cArts)]
	end
end

vars.NextArtifactsRefill = vars.NextArtifactsRefill or Game.Time + const.Year*2
function events.AfterLoadMap()

	-- Reset flags
	if Game.Time > vars.NextArtifactsRefill then
		RecountFoundArtifacts()
		vars.NextArtifactsRefill = Game.Time + const.Year*2
	end

end

------------------------------------------------
-- Can wear conditions

local WearItemConditions = {}

function events.CanWearItem(t)
	if not t.Available then
		return
	end

	local Cond = WearItemConditions[t.ItemId]
	if Cond then
		t.Available = Cond(t.PlayerId)
	end
end

-- Stat bonuses

function events.CalcStatBonusByItems(t)
	local PLT = PlayerEffects[t.Player]
	if PLT then
		t.Result = t.Result + (PLT.Stats[t.Stat] or 0)*(math.min(t.Player.LevelBase/80,2.5))
	elseif Game.CurrentScreen == AdvInnScreen or PlayerInParty(t.PlayerIndex) then
		StoreEffects(t.Player)
	end
end

-- Skill bonuses

function events.GetSkill(t)
	local PLT = PlayerEffects[t.Player]
	if PLT then
		local Skill, Mas = SplitSkill(t.Result)
		if t.Skill>=12 and t.Skill<=20 then
			Skill = Skill + math.min((PLT.Skills[t.Skill] or 0),Skill*0.5)
		else
			Skill = Skill + math.floor((PLT.Skills[t.Skill] or 0)*t.Player.LevelBase/80)
		end
		t.Result = JoinSkill(Skill, Mas)
	elseif Game.CurrentScreen == AdvInnScreen or PlayerInParty(t.PlayerIndex) then
		StoreEffects(t.Player)
	end
end

-- Buffs and extra effects

local TimerPeriod = 2*const.Minute
local MiscItemsEffects = {}

local function PartyHasItem(item_num)
	for _, pl in Party do
		for _, item in pl.Items do
			if item.Number == item_num then
				return true
			end
		end
	end
	return false
end

local function SetBuffs()

	for iR, Player in Party do
		local PLT = PlayerEffects[Player]
		if PLT then
			for k,b in pairs(PLT.Buffs) do
				local Buff = Player.SpellBuffs[k]
				Buff.ExpireTime = Game.Time + TimerPeriod + const.Minute
				Buff.Power = b
				Buff.Skill = b
				Buff.OverlayId = 0
			end
		else
			StoreEffects(Player)
		end
	end

	for k,v in pairs(MiscItemsEffects) do
		if PartyHasItem(k) then
			v()
		end
	end

end

function events.AfterLoadMap()
	Timer(SetBuffs, TimerPeriod, true)
end

-- Base effects

local function HPSPoverTime(Player, HPSP, Amount, PlayerId)
	local Cond = Player:GetMainCondition()
	if Cond >= 17 or Cond < 14 then
		Player[HPSP] = min(Player[HPSP] + Amount, Player["GetFull" .. HPSP](Player))
	end
end

local function SharedLife(Char, PlayerId)

	local Mid = Char:GetMainCondition()
	if Party.count == 1 or Mid == 14 or Mid == 16 or Char.HP >= Char:GetFullHP() then
		return
	end

	local Players = {}
	local Pool = Char.HP
	local Need = 1
	for i,v in Party do
		local res = v.HP - Char.HP
		if res > 0 then
			Pool = Pool + v.HP
			Need = Need + 1
			Players[i] = res
		end
	end

	Mid = floor(Pool/Need)
	Need = Mid - Char.HP
	Pool = Need
	for k, v in pairs(Players) do
		local p = Party[k]
		local res = min(max(p.HP - Mid, 0), Need)

		Players[k] = v - res
		p.HP = p.HP - floor(res/2)
		Pool = Pool - floor(res/2)
	end
	Char.HP = Char.HP + ceil(Need - Pool)

	if Char.HP > 0 and Char.Conditions[13] > 0 then
		Char.Conditions[13] = 0
	end

	Char:ShowFaceAnimation(const.FaceAnimation.Smile)

end

-- Over time effects

function events.RegenTick(Player)

	local PLT = PlayerEffects[Player]
	if PLT then
		for k,v in pairs(PLT.OverTimeEffects) do
			v(Player)
		end
		PLT = PLT.HPSPRegen
		if PLT.SP ~= 0 then
			HPSPoverTime(Player, "SP", PLT.SP)
		end
		if PLT.HP ~= 0 then
			HPSPoverTime(Player, "HP", PLT.HP)
		end
	else
		StoreEffects(Player)
	end

end

-- Attack delay mods

function events.GetAttackDelay(t)
	local Pl = t.Player
	local PLT = PlayerEffects[Pl]
	if PLT then
		t.Result = t.Result *(((PLT.AttackDelay[t.Ranged and 1 or 2] or 0)/2+100)/100)
		local MHItem = Pl.ItemMainHand > 0 and Pl.Items[Pl.ItemMainHand] or false
		if MHItem and not MHItem.Broken and Game.ItemsTxt[MHItem.Number].Skill == 7 then
			t.Result = max(t.Result, 0)
		else
			t.Result = max(t.Result, 0)
		end
	elseif Game.CurrentScreen == AdvInnScreen or PlayerInParty(t.PlayerIndex) then
		StoreEffects(Pl)
	end
end

-- On-hit effects

local OnHitEffects = {}

function events.ItemAdditionalDamage(t)

	if t.Item.Broken then return end

	local Effect = OnHitEffects[t.Item.Number]

	if not Effect then return end

	t.DamageKind = Effect.DamageKind or t.DamageKind
	if Effect.Add then
		t.Result = t.Result + Effect.Add * math.min(t.Player.LevelBase/80,2.5) * 2
	end
	if Effect.Special then
		Effect.Special(t)
	end
end

-- Effect immunities
function events.DoBadThingToPlayer(t)
	local PLT = PlayerEffects[t.Player]
	if PLT then
		if PLT.EffectImmunities[t.Thing] then
			t.Allow = false
		end
	elseif Game.CurrentScreen == AdvInnScreen or PlayerInParty(t.PlayerIndex) then
		StoreEffects(t.Player)
	end
end

-- Arrow projectiles

local ArrowProjectiles = {}
function events.ArrowProjectile(t)
	if t.ObjId == 0x221 then
		local Pl = Party.PlayersArray[t.PlayerIndex]
		local Bow = Pl.Items[Pl.ItemBow].Number

		t.ObjId = ArrowProjectiles[Bow] or 0x221
	end
end

------------------------------------------------
----			Bake effects				----
------------------------------------------------

local function SpellPowerByItemSkill(Player, Item)
	local Skill, Mas = 7, 3
	local SkillNum = Game.ItemsTxt[Item.Number].Skill
	if SkillNum < 39 then
		Skill, Mas = SplitSkill(Player:GetSkill(SkillNum))
	end
	return Skill, Mas
end

StoreEffects = function(Player)

	local Mod, T
	local PLT = PlayerEffects[Player] or {}
	PlayerEffects[Player] = PLT

	PLT.EffectImmunities = {}
	PLT.OverTimeEffects = {}
	PLT.AttackDelay = {}
	PLT.HPSPRegen = {}
	PLT.Buffs  = {}
	PLT.Stats  = {}
	PLT.Skills = {}

	PLT.HPSPRegen.HP = 0
	PLT.HPSPRegen.SP = 0

	for i,v in Player.EquippedItems do
		if v > Player.Items.limit then
			Player.EquippedItems[i] = 0
		elseif v > 0 then
			local Item = Player.Items[v]
			if not Item.Broken then

				Mod = ArtifactBonuses[Item.Number]
				if Mod then
					-- Stats
					if Mod.Stats then
						T = PLT.Stats
						for k,v in pairs(Mod.Stats) do
							T[k] = (T[k] or 0) + v 
						end
					end
					-- Skills
					if Mod.Skills then
						T = PLT.Skills
						for k,v in pairs(Mod.Skills) do
							T[k] = (T[k] or 0) + v
						end
					end
					-- Spell muls
					if Mod.SpellBonus then
						T = PLT.Skills
						for k,v in pairs(Mod.SpellBonus) do
							local base = SplitSkill(Player.Skills[k])
							T[k] = (T[k] or 0) + base*0.5
						end
					end
					-- Buffs
					if Mod.Buffs then
						T = PLT.Buffs
						local Skill, Mas = SpellPowerByItemSkill(Player, Item)
						for k,v in pairs(Mod.Buffs) do
							T[k] = math.max((T[k] or 0), v, Skill*Mas/2)
						end
					end
					-- Effect immunities
					if Mod.EffectImmunities then
						T = PLT.EffectImmunities
						for k,v in pairs(Mod.EffectImmunities) do
							T[k] = true
						end
					end
					-- Attack recovery
					if Mod.ModAttackDelay then
						local IsRangedItem = Game.ItemsTxt[Item.Number].EquipStat == const.ItemType.Missile - 1
						T = PLT.AttackDelay
						T[IsRangedItem and 1 or 2] = (T[IsRangedItem and 1 or 2] or 0) + Mod.ModAttackDelay
					end
					-- HP/SP regen
					if Mod.HPSPRegen then
						T = PLT.HPSPRegen
						for k, v in pairs(Mod.HPSPRegen) do
							T[k] = (T[k] or 0) + v
						end
					end
					-- Over time effects
					if Mod.OverTimeEffect then
						table.insert(PLT.OverTimeEffects, Mod.OverTimeEffect)
					end
				end

				Mod = SpecialBonuses[Item.Bonus2]
				if Mod then
					-- HP/SP regen
					if Mod.HPSPRegen then
						T = PLT.HPSPRegen
						for k, v in pairs(Mod.HPSPRegen) do
							T[k] = (T[k] or 0) + v
						end
					end
					-- Effect immunities
					if Mod.EffectImmunities then
						T = PLT.EffectImmunities
						for k,v in pairs(Mod.EffectImmunities) do
							T[k] = true
						end
					end
				end

			end
		end
	end

end
Game.CountItemBonuses = StoreEffects

function events.LoadMapScripts(WasInGame)
	if not WasInGame then
		for i,v in Party do
			StoreEffects(v)
		end
	end
end

local NeedRecount = false

function events.Action(t)
	if t.Action == 121 or t.Action == 133 and Game.CurrentScreen == 7 then
		NeedRecount = true
	end
end

function events.Tick()
	if NeedRecount then
		local Pl = max(Game.CurrentPlayer, 0)
		StoreEffects(Party[Pl])
		NeedRecount = false
	end
end

------------------------------------------------
----			Item settings				----
------------------------------------------------

local function GetBonusList(ItemId)
	local t = ArtifactBonuses[ItemId]
	if not t then
		t = {}
		ArtifactBonuses[ItemId] = t
	end
	return t
end

local function GetSpcBonusList(BonusId)
	local t = SpecialBonuses[BonusId]
	if not t then
		t = {}
		SpecialBonuses[BonusId] = t
	end
	return t
end

--------------------------------
-- Special effects of unequipable items

MiscItemsEffects[2055] = function()
	local Buff = Party.SpellBuffs[const.PartyBuff.DetectLife]
	Buff.ExpireTime = Game.Time + TimerPeriod + const.Minute
	Buff.Power = 3
	Buff.Skill = 7
	Buff.OverlayId = 0
end

--------------------------------
---- Can wear conditions

-- Hero's belt
WearItemConditions[1337] = function(PlayerId)
	local Gender = Game.CharacterPortraits[Party[PlayerId].Face].DefSex
	return Gender == 0 -- only male can wear it.
end

-- Lady's Escort ring
WearItemConditions[1338] = function(PlayerId)
	local Gender = Game.CharacterPortraits[Party[PlayerId].Face].DefSex
	return Gender == 1 -- only female can wear it.
end

-- Crown of final Dominion
WearItemConditions[521] = function(PlayerId)
	return Party[PlayerId].Class == 45
end

-- Blade of Mercy
WearItemConditions[529] = function(PlayerId)
	return Party[PlayerId].Class == 44 or Party[PlayerId].Class == 45
end

-- Elderaxe
WearItemConditions[504] = function(PlayerId)
	return GetRace(Party[PlayerId]) == const.Race.Minotaur
end

-- Foulfang
WearItemConditions[508] = function(PlayerId)
	return GetRace(Party[PlayerId]) == const.Race.Vampire
end

-- Glomenmail
WearItemConditions[514] = function(PlayerId)
	return GetRace(Party[PlayerId]) == const.Race.DarkElf
end

-- Supreme plate
WearItemConditions[515] = function(PlayerId)
	return Party[PlayerId].Class >= 16 and Party[PlayerId].Class <= 19
end

-- Eclipse
WearItemConditions[516] = function(PlayerId)
	return Game.ClassesExtra[Party[PlayerId].Class].Kind == 2
end

-- Lightning crossbow
WearItemConditions[532] = function(PlayerId)
	local Race = GetRace(Party[PlayerId])
	return Race == const.Race.DarkElf or Race == const.Race.Elf
end

-- Elfbane
WearItemConditions[1333] = function(PlayerId)
	return GetRace(Party[PlayerId]) == const.Race.Goblin
end

-- Mind's Eye
WearItemConditions[1334] = function(PlayerId)
	return GetRace(Party[PlayerId]) == const.Race.Human
end

-- Elven chainmail
WearItemConditions[1335] = function(PlayerId)
	local Race = GetRace(Party[PlayerId])
	return Race == const.Race.DarkElf or Race == const.Race.Elf
end

-- Forge Gauntlets
WearItemConditions[1336] = function(PlayerId)
	return GetRace(Party[PlayerId]) == const.Race.Dwarf
end

-- Wetsuit
local WetsuitSlots = {0,2,4,5,6,8}
WearItemConditions[1406] = function(PlayerId)

	local Pl = Party[PlayerId]

	if not Game.CharacterDollTypes[Game.CharacterPortraits[Pl.Face].DollType].Armor then
		return false
	end

	local EqItems = Pl.EquippedItems

	-- Armors, except body (this one will be replaced).
	for _,v in pairs(WetsuitSlots) do
		if EqItems[v] > 0 then
			return false
		end
	end

	-- Main hand allow only blasters and one-handed weapons
	local MIt = EqItems[1]
	if MIt > 0 then
		local Item = Game.ItemsTxt[Pl.Items[MIt].Number]
		if Item.EquipStat == 1 then
			return false
		end
	end

	return true
end

function events.CanWearItem(t)
	local Pl = Party[t.PlayerId]
	if Pl.ItemArmor > 0 and Pl.Items[Pl.ItemArmor].Number == 1406 then
		local EqSt = Game.ItemsTxt[t.ItemId].EquipStat
		t.Available = EqSt == 0 or EqSt == 3 or EqSt == 8 or EqSt == 10 or EqSt == 11
	end
end

--------------------------------
---- Stat bonuses
GetBonusList(500).Stats = {	[const.Stats.Accuracy] = 40}
GetBonusList(501).Stats = {	[const.Stats.Might] = 40}
GetBonusList(502).Stats = {	[const.Stats.AirResistance] = 40}
GetBonusList(503).Stats = {	[const.Stats.Endurance] = 40,
							[const.Stats.Luck] = 40}
GetBonusList(504).Stats = {	[const.Stats.Might] = 20}
GetBonusList(505).Stats = {	[const.Stats.FireResistance] = 40}
GetBonusList(506).Stats = {	[const.Stats.Endurance] = 20}
GetBonusList(507).Stats = {[const.Stats.Might] 		= 10,
							[const.Stats.Intellect] 	= 10,
							[const.Stats.Personality] 	= 10,
							[const.Stats.Speed] 		= 10,
							[const.Stats.Accuracy]		= 10,
							[const.Stats.Endurance] 	= 10,
							[const.Stats.Luck]			= 10}
GetBonusList(509).Stats = {	[const.Stats.Personality]   = 40}
GetBonusList(510).Stats = { [const.Stats.Might] 		= 20,
							[const.Stats.Endurance] 	= 20}		
GetBonusList(512).Stats = { [const.Stats.Accuracy] 		= 50}						
GetBonusList(513).Stats = { [const.Stats.Endurance] 	= 30}						
GetBonusList(514).Stats = { [const.Stats.Might] 		= 10,
							[const.Stats.Intellect] 	= 10,
							[const.Stats.Personality] 	= 10,
							[const.Stats.Speed] 		= 10,
							[const.Stats.Accuracy]		= 10,
							[const.Stats.Endurance] 	= 10,
							[const.Stats.Luck]			= 10,
							[const.Stats.FireResistance]	= 10,
							[const.Stats.AirResistance]		= 10,
							[const.Stats.WaterResistance]	= 10,
							[const.Stats.EarthResistance]	= 10,
							[const.Stats.MindResistance]	= 10,
							[const.Stats.BodyResistance]	= 10,
							[const.Stats.SpiritResistance]	= 10}	
GetBonusList(514).Stats = { [const.Stats.Speed] 		= 15,							
							[const.Stats.Accuracy] 		= 15}
GetBonusList(518).Stats = { [const.Stats.Speed] 		= 30}
GetBonusList(519).Stats = { [const.Stats.FireResistance]	= 40,
							[const.Stats.AirResistance]		= 40,
							[const.Stats.WaterResistance]	= 40,
							[const.Stats.EarthResistance]	= 40}
GetBonusList(520).Stats = { [const.Stats.Personality]	= 15,
							[const.Stats.Intellect]		= 15}							
GetBonusList(522).Stats = { [const.Stats.Intellect]	= 30,
							[const.Stats.FireResistance]	= 10,
							[const.Stats.AirResistance]		= 10,
							[const.Stats.WaterResistance]	= 10,
							[const.Stats.EarthResistance]	= 10,
							[const.Stats.MindResistance]	= 10,
							[const.Stats.BodyResistance]	= 10}
GetBonusList(523).Stats = { [const.Stats.Intellect]	= 30,
							[const.Stats.WaterResistance]	= -50,
							[const.Stats.Personality]	= -15}
GetBonusList(524).Stats = {	[const.Stats.Speed]	= 70,
							[const.Stats.Accuracy]	= 70,
							[const.Stats.ArmorClass]	= -20}						
GetBonusList(525).Stats = {	[const.Stats.Speed]	= -20}		
GetBonusList(526).Stats = {	[const.Stats.Might]	= 70,
							[const.Stats.Accuracy]		= 70,
							[const.Stats.Personality]	= 50,
							[const.Stats.Intellect]	= 50}		
GetBonusList(527).Stats = {	[const.Stats.Might]	= 50,
							[const.Stats.Luck]	= -40}
GetBonusList(528).Stats	= {	[const.Stats.WaterResistance]	= 70,
							[const.Stats.FireResistance]	= -70}		
GetBonusList(529).Stats	= {	[const.Stats.Might]	= 40,
							[const.Stats.Accuracy]	= -40}		
GetBonusList(530).Stats	= {	[const.Stats.ArmorClass]	= -40}		
GetBonusList(531).Stats	= {	[const.Stats.Accuracy]	= 100,
							[const.Stats.ArmorClass]	= -20}		
GetBonusList(532).Stats	= {	[const.Stats.Accuracy]	= -50}		
GetBonusList(533).Stats	= {	[const.Stats.Intellect]	= 70,
							[const.Stats.Personality]	= 70,
							[const.Stats.MindResistance]	= -30,
							[const.Stats.SpiritResistance]	= -30}		
GetBonusList(534).Stats	= {	[const.Stats.Luck]	= -15,
							[const.Stats.Personality]	= -15}
GetBonusList(535).Stats	= {	[const.Stats.Intellect]	= 40,
							[const.Stats.Endurance]	= -20}			
GetBonusList(536).Stats	= {	[const.Stats.Luck]	= 90,
							[const.Stats.Personality]	= -50}		
GetBonusList(537).Stats	= {	[const.Stats.Might]	= 100,
							[const.Stats.Accuracy]	= -30,
							[const.Stats.ArmorClass]	= -15}							
							
							
-- Crown of final Dominion
GetBonusList(521).Stats = {	[const.Stats.Intellect] = 50}

-- Cycle of life
GetBonusList(543).Stats = {	[const.Stats.Endurance] = 20}

-- Hero's belt
GetBonusList(1337).Stats = {[const.Stats.Might] = 15}
-- Lady's Escort ring
GetBonusList(1338).Stats = {[const.Stats.FireResistance]	= 10,
							[const.Stats.AirResistance]		= 10,
							[const.Stats.WaterResistance]	= 10,
							[const.Stats.EarthResistance]	= 10,
							[const.Stats.MindResistance]	= 10,
							[const.Stats.BodyResistance]	= 10,
							[const.Stats.SpiritResistance]	= 10}
-- Splitter
GetBonusList(1308).Stats = {[const.Stats.FireResistance] = 65000}
-- Puck
GetBonusList(1302).Stats = {[const.Stats.Speed]	= 40}
-- Iron Feather
GetBonusList(1303).Stats = {[const.Stats.Might]	= 40}
-- Wallace
GetBonusList(1304).Stats = {[const.Stats.Personality] = 40}
-- Corsair
GetBonusList(1305).Stats = {[const.Stats.Luck] = 40}
-- Governor's Armor
GetBonusList(1306).Stats = {[const.Stats.Might] 		= 10,
							[const.Stats.Intellect] 	= 10,
							[const.Stats.Personality] 	= 10,
							[const.Stats.Speed] 		= 10,
							[const.Stats.Accuracy]		= 10,
							[const.Stats.Endurance] 	= 10,
							[const.Stats.Luck]			= 10}
-- Yoruba
GetBonusList(1307).Stats = {[const.Stats.Endurance] 	= 25}
-- Ullyses
GetBonusList(1312).Stats = {[const.Stats.Accuracy] = 50}
-- Seven League Boots
GetBonusList(1314).Stats = {[const.Stats.Speed] = 40}
-- Mash
GetBonusList(1316).Stats = {[const.Stats.Might] 		= 150,
							[const.Stats.Intellect] 	= -40,
							[const.Stats.Personality] 	= -40,
							[const.Stats.Speed] 		= -40}
-- Hareck's Leather
GetBonusList(1318).Stats = {[const.Stats.Luck]				= 50,
							[const.Stats.FireResistance] 	= -10,
							[const.Stats.AirResistance] 	= -10,
							[const.Stats.WaterResistance] 	= -10,
							[const.Stats.EarthResistance] 	= -10,
							[const.Stats.MindResistance] 	= -10,
							[const.Stats.BodyResistance] 	= -10,
							[const.Stats.SpiritResistance] 	= -10}
-- Amuck
GetBonusList(1320).Stats = {[const.Stats.Might] 		= 100,
							[const.Stats.Endurance] 	= 100,
							[const.Stats.ArmorClass] 	= -15}
-- Glory shield
GetBonusList(1321).Stats = {[const.Stats.BodyResistance] = -10,
							[const.Stats.MindResistance] = -10}
-- Kelebrim
GetBonusList(1322).Stats = {[const.Stats.Endurance] = 50,
							[const.Stats.EarthResistance] = -30}
-- Taledon's Helm
GetBonusList(1323).Stats = {
	[const.Stats.Might] = 15,
	[const.Stats.Personality] = 15,
	[const.Stats.Luck] = -40
}
-- Scholar's Cap
GetBonusList(1324).Stats = {[const.Stats.Endurance] = -50}
-- Phynaxian Crown
GetBonusList(1325).Stats = {
	[const.Stats.Personality] = 30,
	[const.Stats.ArmorClass] = -20,
	[const.Stats.WaterResistance] = 50
}
-- Titan's Belt
GetBonusList(1326).Stats = {
	[const.Stats.Might] = 75,
	[const.Stats.Speed] = -40
}
-- Twilight
GetBonusList(1327).Stats = {
	[const.Stats.Speed] = 50,
	[const.Stats.Luck] = 50,
	[const.Stats.FireResistance] = -15,
	[const.Stats.AirResistance] = -15,
	[const.Stats.WaterResistance] = -15,
	[const.Stats.EarthResistance] = -15,
	[const.Stats.MindResistance] = -15,
	[const.Stats.BodyResistance] = -15,
	[const.Stats.SpiritResistance] = -15
}
-- Ania Selving
GetBonusList(1328).Stats = {[const.Stats.ArmorClass] = -25,
							[const.Stats.Accuracy] = 150}
-- Justice
GetBonusList(1329).Stats = {[const.Stats.Speed] = -40}
-- Mekorig's hammer
GetBonusList(1330).Stats = {[const.Stats.Might] = 75,
							[const.Stats.AirResistance] = -50}
-- Mind's Eye
GetBonusList(1334).Stats = {
	[const.Stats.Intellect] = 15,
	[const.Stats.Personality] = 15
}
-- Elven Chainmail
GetBonusList(1335).Stats = {[const.Stats.Speed] = 15,
							[const.Stats.Accuracy] = 15}
-- Forge Gauntlets
GetBonusList(1336).Stats = {
	[const.Stats.Might] = 15,
	[const.Stats.Endurance] = 15,
	[const.Stats.FireResistance] = 30
}
-- Vampire cloak
GetBonusList(1352).Stats = {[const.Stats.Intellect] = 10, [const.Stats.Luck] = 10}
-- Thor
GetBonusList(2021).Stats = {[const.Stats.Might] = 75}
-- Conan
GetBonusList(2022).Stats = {[const.Stats.Might] = 75}
-- Excalibur
GetBonusList(2023).Stats = {[const.Stats.Might] = 30}
-- Merlin
GetBonusList(2024).Stats = {[const.Stats.SP] = 40}
-- Percival
GetBonusList(2025).Stats = {[const.Stats.Speed] = 40}
-- Galahad
GetBonusList(2026).Stats = {[const.Stats.HP] = 25}
-- Pellinore
GetBonusList(2027).Stats = {[const.Stats.Endurance] = 30}
-- Valeria
GetBonusList(2028).Stats = {[const.Stats.Accuracy] = 30}
-- Arthur
GetBonusList(2029).Stats = {
	[const.Stats.Might] = 10,
	[const.Stats.Intellect] = 10,
	[const.Stats.Personality] = 10,
	[const.Stats.Endurance] = 10,
	[const.Stats.Accuracy] = 10,
	[const.Stats.Speed] = 10,
	[const.Stats.Luck] = 10,
	[const.Stats.SP] = 25
}
-- Pendragon
GetBonusList(2030).Stats = {[const.Stats.Luck] = 30}
-- Lucius
GetBonusList(2031).Stats = {[const.Stats.Speed] = 30}
-- Guinevere
GetBonusList(2032).Stats = {[const.Stats.SP] = 30}
-- Igraine
GetBonusList(2033).Stats = {[const.Stats.SP] = 25}
-- Morgan
GetBonusList(2034).Stats = {[const.Stats.SP] = 20}
-- Hades
GetBonusList(2035).Stats = {[const.Stats.Luck] = 20}
-- Ares
GetBonusList(2036).Stats = {[const.Stats.FireResistance] = 25}
-- Poseidon
GetBonusList(2037).Stats = {[const.Stats.Might] 	 = 20,
							[const.Stats.Endurance]  = 20,
							[const.Stats.Accuracy] 	 = 20,
							[const.Stats.Speed] 	 = -10,
							[const.Stats.ArmorClass] = -10}
-- Cronos
GetBonusList(2038).Stats = {[const.Stats.Luck] 	 	= -50,
							[const.Stats.Endurance] = 100}
-- Hercules
GetBonusList(2039).Stats = {[const.Stats.Might] 	= 50,
							[const.Stats.Endurance] = 20,
							[const.Stats.Intellect]	= -30}
-- Artemis
GetBonusList(2040).Stats = {[const.Stats.FireResistance] 	= -10,
							[const.Stats.AirResistance] 	= -10,
							[const.Stats.WaterResistance] 	= -10,
							[const.Stats.EarthResistance] 	= -10}
-- Apollo
GetBonusList(2041).Stats = {[const.Stats.Endurance]			= -30,
							[const.Stats.FireResistance] 	= 20,
							[const.Stats.AirResistance] 	= 20,
							[const.Stats.WaterResistance] 	= 20,
							[const.Stats.EarthResistance] 	= 20,
							[const.Stats.MindResistance] 	= 20,
							[const.Stats.BodyResistance] 	= 20,
							[const.Stats.SpiritResistance] 	= 20,
							[const.Stats.Luck]				= 20}
-- Zeus
GetBonusList(2042).Stats = {[const.Stats.HP] 		= 50,
							[const.Stats.SP] 		= 50,
							[const.Stats.Luck] 		= 50,
							[const.Stats.Intellect] = -50}
-- Aegis
GetBonusList(2043).Stats = {[const.Stats.Speed] = -20,
							[const.Stats.Luck] 	= 20}
-- Odin
GetBonusList(2044).Stats = {
	[const.Stats.Speed] = -40,
	[const.Stats.FireResistance] = 50,
	[const.Stats.AirResistance] = 50,
	[const.Stats.WaterResistance] = 50,
	[const.Stats.EarthResistance] = 50
}
-- Atlas
GetBonusList(2045).Stats = {
	[const.Stats.Might] = 100,
	[const.Stats.Speed] = -40
}
-- Hermes
GetBonusList(2046).Stats = {
	[const.Stats.Speed] = 100,
	[const.Stats.Accuracy] = -40
}
-- Aphrodite
GetBonusList(2047).Stats = {[const.Stats.Personality] = 100,
							[const.Stats.Luck] 	= -40}
-- Athena
GetBonusList(2048).Stats = {[const.Stats.Intellect] = 100,
							[const.Stats.Might] 	= -40}
-- Hera
GetBonusList(2049).Stats = {[const.Stats.HP] = 50,
							[const.Stats.SP] = 50,
							[const.Stats.Luck] = 50,
							[const.Stats.Personality] = -50}
-- Hermes's Sandals
GetBonusList(1331).Stats = {[const.Stats.Speed] = 100,
							[const.Stats.Accuracy] = 50,
							[const.Stats.AirResistance] = 50}
-- Cloak of the sheep
GetBonusList(1332).Stats = {[const.Stats.Intellect] 	= -20,
							[const.Stats.Personality] 	= -20}

--------------------------------
---- Skill bonuses

-- Hero's belt
GetBonusList(1337).Skills =	{	[const.Skills.Armsmaster] = 5}
-- Wallace
GetBonusList(1304).Skills =	{	[const.Skills.Armsmaster] = 10}
-- Corsair
GetBonusList(1305).Skills =	{	[const.Skills.DisarmTraps] = 10}
-- Hands of the Master
GetBonusList(1313).Skills =	{	[const.Skills.Unarmed] = 10,
								[const.Skills.Dodging] = 10}
-- Ethric's Staff
GetBonusList(1317).Skills =	{	[const.Skills.Meditation] = 15}
-- Hareck's Leather
GetBonusList(1318).Skills =	{	[const.Skills.DisarmTraps] = 5,
								[const.Skills.Unarmed] = 5,}
-- Old Nick
GetBonusList(1319).Skills =	{	[const.Skills.DisarmTraps] = 5}
-- Glory shield
GetBonusList(1321).Skills =	{	[const.Skills.Shield] = 5}
-- Scholar's Cap
GetBonusList(1324).Skills = {[const.Skills.Learning] = 15}
-- Ania Selving
GetBonusList(1328).Skills =	{	[const.Skills.Bow] = 5}
-- Faerie ring
GetBonusList(1347).Skills =	{	[const.Skills.Fire] = 5,
								[const.Skills.Air] = 5,
								[const.Skills.Water] = 5,
								[const.Skills.Earth] = 5}
-- Pendragon
GetBonusList(2030).Skills =	{	[const.Skills.Stealing] = 10,
								[const.Skills.DisarmTraps] = 10}
-- Hades
GetBonusList(2035).Skills =	{	[const.Skills.DisarmTraps] = 10}

--------------------------------
---- Spell bonuses

-- Eclipse
GetBonusList(516).SpellBonus =	{[const.Skills.Spirit] = true, [const.Skills.Body] = true, [const.Skills.Mind] = true}
-- Crown of final Dominion
GetBonusList(521).SpellBonus =	{[const.Skills.Dark] = true}
-- Staff of Elements
GetBonusList(530).SpellBonus =	{[const.Skills.Fire] = true, [const.Skills.Air] = true, [const.Skills.Water] = true, [const.Skills.Earth] = true}
-- Staff of Elements
GetBonusList(535).SpellBonus =	{[const.Skills.Water] = true}
-- Seven League Boots
GetBonusList(1314).SpellBonus =	{[const.Skills.Water] = true}
-- Ruler's ring
GetBonusList(1315).SpellBonus =	{[const.Skills.Mind] = true, [const.Skills.Dark] = true}
-- Ethric's Staff
GetBonusList(1317).SpellBonus =	{[const.Skills.Dark] = true}
-- Glory shield
GetBonusList(1321).SpellBonus =	{[const.Skills.Spirit] = true}
-- Taledon's Helm
GetBonusList(1323).SpellBonus = {[const.Skills.Light] = true}
-- Phynaxian Crown
GetBonusList(1325).SpellBonus = {[const.Skills.Fire] = true}
-- Justice
GetBonusList(1329).SpellBonus =	{[const.Skills.Mind] = true,
								 [const.Skills.Body] = true}
-- Mekorig's hammer
GetBonusList(1330).SpellBonus =	{[const.Skills.Spirit] = true}
-- Ghost ring
GetBonusList(1347).SpellBonus =	{[const.Skills.Spirit] = true}
-- Guinevere
GetBonusList(2032).SpellBonus =	{[const.Skills.Light] = true, [const.Skills.Dark] = true}
-- Igraine
GetBonusList(2033).SpellBonus =	{[const.Skills.Spirit] = true, [const.Skills.Body] = true, [const.Skills.Mind] = true}
-- Morgan
GetBonusList(2034).SpellBonus =	{[const.Skills.Fire] = true, [const.Skills.Air] = true, [const.Skills.Water] = true, [const.Skills.Earth] = true}

--------------------------------
---- Buffs and extra effects

-- Lady's Escort ring
GetBonusList(1338).Buffs = {[const.PlayerBuff.WaterBreathing] = 0} -- Buff = Skill
-- Governor's Armor
GetBonusList(1306).Buffs = {[const.PlayerBuff.Shield] = 3}
-- Hareck's Leather
GetBonusList(1318).Buffs = {[const.PlayerBuff.WaterBreathing] = 0}
-- Kelebrim
GetBonusList(1322).Buffs = {[const.PlayerBuff.Shield] = 3}
-- Elfbane
GetBonusList(1333).Buffs = {[const.PlayerBuff.Shield] = 3}
-- Ghost ring
GetBonusList(1347).Buffs = {[const.PlayerBuff.Preservation] = 3}
-- Wetsuit
GetBonusList(1406).Buffs = {[const.PlayerBuff.WaterBreathing] = 0}
-- Excalibur
GetBonusList(2023).Buffs = {[const.PlayerBuff.Bless] = 3}
-- Galahad
GetBonusList(2026).Buffs = {[const.PlayerBuff.Shield] = 3,
							[const.PlayerBuff.Stoneskin] = 20}
--Pellinore
GetBonusList(2027).Buffs = {[const.PlayerBuff.Stoneskin] = 20}
-- Valeria
GetBonusList(2028).Buffs = {[const.PlayerBuff.Shield] = 3}
-- Aegis
GetBonusList(2043).Buffs = {[const.PlayerBuff.Shield] = 3}

--------------------------------
---- Effect Immunities

-- Yoruba
GetBonusList(1307).EffectImmunities = {	[const.MonsterBonus.Insane] 	= true,
							[const.MonsterBonus.Disease1] 	= true,
							[const.MonsterBonus.Disease2] 	= true,
							[const.MonsterBonus.Disease3] 	= true,
							[const.MonsterBonus.Paralyze] 	= true,
							[const.MonsterBonus.Stone] 		= true,
							[const.MonsterBonus.Poison1] 	= true,
							[const.MonsterBonus.Poison2] 	= true,
							[const.MonsterBonus.Poison3] 	= true,
							[const.MonsterBonus.Asleep] 	= true}
-- Ghoulsbane
GetBonusList(1309).EffectImmunities = {[const.MonsterBonus.Paralyze] = true}
-- Kelebrim
GetBonusList(1322).EffectImmunities = {[const.MonsterBonus.Stone] = true}
-- Cloak of the sheep
GetBonusList(1332).EffectImmunities = {	[const.MonsterBonus.Insane] 	= true,
							[const.MonsterBonus.Disease1] 	= true,
							[const.MonsterBonus.Disease2] 	= true,
							[const.MonsterBonus.Disease3] 	= true,
							[const.MonsterBonus.Paralyze] 	= true,
							[const.MonsterBonus.Stone] 		= true,
							[const.MonsterBonus.Poison1] 	= true,
							[const.MonsterBonus.Poison2] 	= true,
							[const.MonsterBonus.Poison3] 	= true,
							[const.MonsterBonus.Asleep] 	= true}
-- Medusa's mirror
GetBonusList(1341).EffectImmunities = {[const.MonsterBonus.Stone] = true}
-- Pendragon
GetBonusList(2030).EffectImmunities = {
	[const.MonsterBonus.Poison1] = true,
	[const.MonsterBonus.Poison2] = true,
	[const.MonsterBonus.Poison3] = true
}
-- Aegis
GetBonusList(2043).EffectImmunities = {[const.MonsterBonus.Stone] = true}

--------------------------------
---- Attack delay mods

-- Supreme plate
GetBonusList(515).ModAttackDelay = -20
-- Percival
GetBonusList(2025).ModAttackDelay = -20
-- Puck
GetBonusList(1302).ModAttackDelay = -20
-- Merlin
GetBonusList(2024).ModAttackDelay = -20

--------------------------------
---- HP/SP regen

-- Mind's Eye
GetBonusList(1334).HPSPRegen = {SP = 3}
-- Hero's belt
GetBonusList(1337).HPSPRegen = {HP = 3}
-- Merlin
GetBonusList(2024).HPSPRegen = {SP = 3}
-- Pellinore
GetBonusList(2027).HPSPRegen = {HP = 3}
-- Guinevere
GetBonusList(2032).HPSPRegen = {SP = 3}
-- Igraine
GetBonusList(2033).HPSPRegen = {SP = 3}
-- Morgan
GetBonusList(2034).HPSPRegen = {SP = 3}
-- Hades
GetBonusList(2035).HPSPRegen = {HP = -3}
-- Hermes's Sandals
GetBonusList(1331).HPSPRegen = {HP = 3, SP = 3}
-- Elven Chainmail
GetBonusList(1335).HPSPRegen = {HP = 3}

GetSpcBonusList(37).HPSPRegen = {HP = 2}
GetSpcBonusList(38).HPSPRegen = {SP = 1}
GetSpcBonusList(44).HPSPRegen = {HP = 2}
GetSpcBonusList(47).HPSPRegen = {SP = 1}
GetSpcBonusList(55).HPSPRegen = {SP = 1}
GetSpcBonusList(66).HPSPRegen = {HP = 2, SP = 1}

GetSpcBonusList(73).EffectImmunities = {
	[const.MonsterBonus.Dead] 	= true,
	[const.MonsterBonus.Errad] 	= true}

--------------------------------
---- Over time item effects

-- Cycle of life
GetBonusList(543).OverTimeEffect = function(Player, PlayerId)
	SharedLife(Player, PlayerId)
end

-- Ethric's Staff
GetBonusList(1317).OverTimeEffect =	function(Player, PlayerId)
	if Player.Class ~= const.Class.Lich then
		HPSPoverTime(Player, "HP", -3, PlayerId)
	end
end

--------------------------------
---- Arrow projectiles

ArrowProjectiles[1312] = 3030

--------------------------------
---- On-hit item effects (only weapons)

-- Splitter
OnHitEffects[1308] = {
	DamageKind 	= const.Damage.Fire,
	Add			= 10,
	Special = function(t)
		local Skill, Mas = SpellPowerByItemSkill(t.Player, t.Item)
		CastSpellDirect(125,Skill,Mas)
		evt.CastSpell(6, Mas, Skill, t.Monster.X,t.Monster.Y,t.Monster.Z+50, t.Monster.X,t.Monster.Y,t.Monster.Z)
	end}
-- Iron Feather
OnHitEffects[1303] = {
	DamageKind 	= const.Damage.Air,
	Add			= 15}
-- Ghoulsbane
OnHitEffects[1309] = {
	DamageKind 	= const.Damage.Fire,
	Add			= 15,
	Special = function(t)
		if Game.Bolster.Monsters[t.Monster.Id].Type == const.MonsterKind.Undead then
			t.Result = t.Result*2
		end
	end}
-- Gibbet
OnHitEffects[1310] = {
	DamageKind 	= const.Damage.Fire,
	Add			= 15,
	Special = function(t)
		local montype = Game.Bolster.Monsters[t.Monster.Id].Type
		if montype == const.MonsterKind.Undead
			or montype == const.MonsterKind.Dragon
			or montype == const.MonsterKind.Demon then

			t.Result = t.Result*2
		end
	end}
-- Ullyses
OnHitEffects[1312] = {
	DamageKind 	= const.Damage.Water,
	Add			= 15}
-- Old Nick
OnHitEffects[1319] = {
	DamageKind 	= const.Damage.Water,
	Add			= 8,
	Special = function(t)
		if Game.Bolster.Monsters[t.Monster.Id].Type == const.MonsterKind.Elf then
			t.Result = t.Result*2
		end
	end}
-- Elfbane
OnHitEffects[1333] = {
	Special = function(t)
		if Game.Bolster.Monsters[t.Monster.Id].Type == const.MonsterKind.Elf then
			t.Result = t.Result*2
		end
	end}
-- Mordred
OnHitEffects[2020] = {
	Special = function(t)
		t.Vampiric = true
	end}
-- Thor
OnHitEffects[2021] = {
	Add			= 10,
	Special = function(t)
		CastSpellDirect(125, 7, 3)
		if t.Monster.HP - t.Result > 0 then
			local Skill, Mas = SpellPowerByItemSkill(t.Player, t.Item)
			evt.CastSpell(18, Mas, Skill, t.Monster.X,t.Monster.Y,t.Monster.Z+50, t.Monster.X,t.Monster.Y,t.Monster.Z)
		end
	end}
-- Conan
OnHitEffects[2022] = {
	Add			= 10,
	Special = function(t)
		local montype = Game.Bolster.Monsters[t.Monster.Id].Type
		if	montype == const.MonsterKind.Dragon
			or	montype == const.MonsterKind.Demon then

			t.Result = t.Result*2
		end
	end}
-- Excalibur
OnHitEffects[2023] = {
	Add			= 10,
	Special = function(t)
		local montype = Game.Bolster.Monsters[t.Monster.Id].Type
		if	montype == const.MonsterKind.Dragon then
			t.Result = t.Result*2
		end
	end}
-- Percival
OnHitEffects[2025] = {
	DamageKind 	= const.Damage.Fire,
	Special = function(t)
		local Skill, Mas = SpellPowerByItemSkill(t.Player, t.Item)
		evt.CastSpell(6, Mas, Skill, t.Monster.X,t.Monster.Y,t.Monster.Z+50, t.Monster.X,t.Monster.Y,t.Monster.Z)
	end}
-- Hades
OnHitEffects[2035] = {
	DamageKind 	= const.Damage.Water,
	Add = 20,
	Special = function(t)
		local Skill, Mas = SpellPowerByItemSkill(t.Player, t.Item)
		CastSpellDirect(29, Skill, Mas)
	end}
-- Ares
OnHitEffects[2036] = {
	DamageKind 	= const.Damage.Fire,
	Add = 30}
-- Artemis
OnHitEffects[2040] = {
	DamageKind 	= const.Damage.Air,
	Add			= 20,
	Special = function(t)
		local Skill, Mas = SpellPowerByItemSkill(t.Player, t.Item)
		CastSpellDirect(125,Skill,Mas)
		evt.CastSpell(18, Mas, Skill, t.Monster.X,t.Monster.Y,t.Monster.Z+50, t.Monster.X,t.Monster.Y,t.Monster.Z)
	end}

-----
--REMOVE MM8 BONUSES
----
artBon={}

artBon[500] = {	[const.Stats.Accuracy] = 40}
artBon[501] = {	[const.Stats.Might] = 40}
artBon[502] = {	[const.Stats.AirResistance] = 40}
artBon[503] = {	[const.Stats.Endurance] = 40,
							[const.Stats.Luck] = 40}
artBon[504] = {	[const.Stats.Might] = 20}
artBon[505] = {	[const.Stats.FireResistance] = 40}
artBon[506] = {	[const.Stats.Endurance] = 20}
artBon[507] = {[const.Stats.Might] 		= 10,
							[const.Stats.Intellect] 	= 10,
							[const.Stats.Personality] 	= 10,
							[const.Stats.Speed] 		= 10,
							[const.Stats.Accuracy]		= 10,
							[const.Stats.Endurance] 	= 10,
							[const.Stats.Luck]			= 10}
artBon[509] = {	[const.Stats.Personality]   = 40}
artBon[510] = { [const.Stats.Might] 		= 20,
							[const.Stats.Endurance] 	= 20}		
artBon[512] = { [const.Stats.Accuracy] 		= 50}						
artBon[513] = { [const.Stats.Endurance] 	= 30}						
artBon[514] = { [const.Stats.Might] 		= 10,
							[const.Stats.Intellect] 	= 10,
							[const.Stats.Personality] 	= 10,
							[const.Stats.Speed] 		= 10,
							[const.Stats.Accuracy]		= 10,
							[const.Stats.Endurance] 	= 10,
							[const.Stats.Luck]			= 10,
							[const.Stats.FireResistance]	= 10,
							[const.Stats.AirResistance]		= 10,
							[const.Stats.WaterResistance]	= 10,
							[const.Stats.EarthResistance]	= 10,
							[const.Stats.MindResistance]	= 10,
							[const.Stats.BodyResistance]	= 10,
							[const.Stats.SpiritResistance]	= 10}	
artBon[514] = { [const.Stats.Speed] 		= 15,							
							[const.Stats.Accuracy] 		= 15}
artBon[518] = { [const.Stats.Speed] 		= 30}
artBon[519] = { [const.Stats.FireResistance]	= 40,
							[const.Stats.AirResistance]		= 40,
							[const.Stats.WaterResistance]	= 40,
							[const.Stats.EarthResistance]	= 40}
artBon[520] = { [const.Stats.Personality]	= 15,
							[const.Stats.Intellect]		= 15}							
artBon[522] = { [const.Stats.Intellect]	= 30,
							[const.Stats.FireResistance]	= 10,
							[const.Stats.AirResistance]		= 10,
							[const.Stats.WaterResistance]	= 10,
							[const.Stats.EarthResistance]	= 10,
							[const.Stats.MindResistance]	= 10,
							[const.Stats.BodyResistance]	= 10}
artBon[523] = { [const.Stats.Intellect]	= 30,
							[const.Stats.WaterResistance]	= -50,
							[const.Stats.Personality]	= -15}
artBon[524] = {	[const.Stats.Speed]	= 70,
							[const.Stats.Accuracy]	= 70,
							[const.Stats.ArmorClass]	= -20}						
artBon[525] = {	[const.Stats.Speed]	= -20}		
artBon[526] = {	[const.Stats.Might]	= 70,
							[const.Stats.Accuracy]		= 70,
							[const.Stats.Personality]	= 50,
							[const.Stats.Intellect]	= 50}		
artBon[527] = {	[const.Stats.Might]	= 50,
							[const.Stats.Luck]	= -40}
artBon[528]	= {	[const.Stats.WaterResistance]	= 70,
							[const.Stats.FireResistance]	= -70}		
artBon[529]	= {	[const.Stats.Might]	= 40,
							[const.Stats.Accuracy]	= -40}		
artBon[530]	= {	[const.Stats.ArmorClass]	= -40}		
artBon[531]	= {	[const.Stats.Accuracy]	= 100,
							[const.Stats.ArmorClass]	= -20}		
artBon[532]	= {	[const.Stats.Accuracy]	= -50}		
artBon[533]	= {	[const.Stats.Intellect]	= 70,
							[const.Stats.Personality]	= 70,
							[const.Stats.MindResistance]	= -30,
							[const.Stats.SpiritResistance]	= -30}		
artBon[534]	= {	[const.Stats.Luck]	= -15,
							[const.Stats.Personality]	= -15}
artBon[535]	= {	[const.Stats.Intellect]	= 40,
							[const.Stats.Endurance]	= -20}			
artBon[536]	= {	[const.Stats.Luck]	= 90,
							[const.Stats.Personality]	= -50}		
artBon[537]	= {	[const.Stats.Might]	= 100,
							[const.Stats.Accuracy]	= -30,
							[const.Stats.ArmorClass]	= -15}		

function events.CalcStatBonusByItems(t)
	for it in t.Player:EnumActiveItems() do
		if it.Number>=500 and it.Number <=537 and it.Number~=521 then
			if artBon[it.Number] and artBon[it.Number][t.Stat] then
				t.Result=t.Result-artBon[it.Number][t.Stat]
			end
		end
	end
end
