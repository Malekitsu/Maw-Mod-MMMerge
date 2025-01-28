local max, min, ceil, floor, random, sqrt = math.max, math.min, math.ceil, math.floor, math.random, math.sqrt
local ReadyMons = {}
local MonBolStep = {}
local TxtLocalized = false

Game.Bolster = {}

-----------------------------------------------
--	Constants

const.Bolster = {}

const.Bolster.Types = {
	NoBolster 		= 0,
	OriginalStats	= 1,
	LowerToEqual	= 2,
	AllToEqual		= 3
}

const.MonsterKind = {
	Undead = 1,
	Dragon = 2,
	Swimmer = 3,
	Immobile = 4,
	Peasant = 5,
	NoArena = 6,
	Ogre = 7,
	Elemental = 8,
	Demon = 9,
	Titan = 10,
	Elf = 11,
	Goblin = 12,
	Dwarf = 13,
	Human = 14
}

const.Bolster.MonsterType = {
	Unknown		= 0,
	Undead 		= 1,
	Dragon 		= 2,
	Swimmer		= 3,
	Immobile	= 4,
	Peasant		= 5,
	NoArena		= 6,
	Ogre		= 7,
	Elemental	= 8,
	Demon 		= 9,
	Titan 		= 10,
	Elf 		= 11,
	Goblin		= 12,
	Dwarf		= 13,
	Human		= 14,
	DarkElf		= 15,
	Lizardman	= 16,
	Minotaur	= 17,
	Troll		= 18,
	Creature	= 19,
	Construct	= 20
	}

const.Bolster.Creed = {
	Neutral	= 0,
	Light 	= 1,
	Dark 	= 2,
	Peasant = 3	-- for hireable creatures
	}

const.Bolster.Magic = {
	Any		= 0,
	Fire	= 1,
	Air		= 2,
	Water	= 3,
	Earth	= 4,
	Spirit	= 5,
	Mind	= 6,
	Body	= 7,
	Light	= 8,
	Dark	= 9,
	Self	= 10,
	Elemental = 11
	}

const.Bolster.Style = {
	Strength	= 0,
	Endurance 	= 1,
	Speed 		= 2,
	Magic		= 3,
	Wimpy		= 4
	}

-----------------------------------------------
-- Text tables processing

local function ProcessBolsterTxt()

	local Warning = ""

	local function GetProp(Val, Type, i)
		local result = tonumber(Val) or const.Bolster[Type][Val] or 0
		if not result then
			result = 0
			Warning = Warning .. "Undefined property, line: " .. i .. ", type: " .. Type .. "\n"
		end
		return result
	end

	---- Monsters:

	Game.Bolster.Monsters = {}

	local Bolster = Game.Bolster.Monsters
	local BolsterTxt = io.open("Data/Tables/Bolster - monsters.txt", "r")

	if not BolsterTxt then
		BolsterTxt = io.open("Data/Tables/Bolster - monsters.txt", "w")
		BolsterTxt:write("#	Note	Type	ExtraType	Creed	Style	Pref magic	NoArena	Allow ranged attacks	Allow spells	HP by size	Allow replicate	Allow summons	Summon Id	Extra points	Max HP Boost (%)\n")
		for i,v in Game.MonstersTxt do
			BolsterTxt:write(i .. "\9" .. v.Name .. "\9\9\9\9\9\9-\9-\9-\9-\9-\9-\9\9\n")
			Bolster[i] = {Type = 0, Creed = 0, Style = 0, PrefMagic = 0, Ranged = false, Spells = false, HPBySize = false, Summons = false, SummonId = 0, LevelShift = 0}
		end
	else
		local LineIt = BolsterTxt:lines()
		LineIt() -- skip header

		for line in LineIt do
			local Words = string.split(line, "\9")
			local CurId = tonumber(Words[1]) or 0
			Bolster[CurId] = {
				Type 		= GetProp(Words[3], "MonsterType", CurId),
				ExtraType 	= {},
				Creed 		= GetProp(Words[5], "Creed", CurId),
				Gender 		= Words[6] == "F" and "F" or "M",
				Style	 	= GetProp(Words[7], "Style", CurId),
				Magic 		= GetProp(Words[8], "Magic", CurId),
				NoArena 	= Words[9]  == "x",
				Ranged 		= Words[10] == "x",
				Spells 		= Words[11] == "x",
				HPBySize	= Words[12] == "x",
				Replicate	= Words[13] == "x",
				Summons 	= Words[14] == "x",
				SummonId 	= tonumber(Words[15]) or 0,
				LevelShift 	= tonumber(Words[16]) or 0,
				MaxHPBoost	= (tonumber(Words[17]) or 300)/100}
			local types = string.split(Words[4], ",")
			for _, v in pairs(types) do
				local mon_type = GetProp(v, "MonsterType", CurId)
				if mon_type and mon_type > 0 then
					table.insert(Bolster[CurId].ExtraType, mon_type)
				end
			end
		end

		if string.len(Warning) > 0 then
			Warning = 'Errors in "Bolster - monsters.txt":\n'
			debug.Message(Warning)
		end
	end

	BolsterTxt:close()

	---- Per-map restrictions:

	Game.Bolster.Maps = {}
	Game.Bolster.MapsSource = {}

	Bolster = Game.Bolster.Maps
	BolsterTxt = io.open("Data/Tables/Bolster - maps.txt", "r")

	if not BolsterTxt then
		BolsterTxt = io.open("Data/Tables/Bolster - maps.txt", "w")
		BolsterTxt:write("#	Note	Continent	Bolster kind	Spells	Summons	Level shift\n")
		for i,v in Game.MapStats do
			BolsterTxt:write(i .. "\9" .. v.Name .. "\9\9NoBolster\9-\9-\9-\9\9\n")
			Bolster[i] = {Continent = 1, Type = 0, Spells = false, Summons = false, Weather = false, LevelShift = 0, CustomSky = false}
		end
	else
		local LineIt = BolsterTxt:lines()
		LineIt() -- skip header

		for line in LineIt do
			local Words = string.split(line, "\9")
			local CurId = tonumber(Words[1]) or 0
			Bolster[CurId] = {
				Continent	= tonumber(Words[3]) or 1,
				Type 		= GetProp(Words[4], "Types", CurId),
				Spells 		= Words[5] == "x",
				Summons	 	= Words[6] == "x",
				Weather	 	= Words[7] == "x",
				LevelShift	= tonumber(Words[8]) or 0,
				CustomSky 	= string.len(Words[10]) > 0 and Words[10] or false,
				ProfsMaxRarity = tonumber(Words[9]) or 0}

			Game.Bolster.MapsSource[CurId] = table.copy(Bolster[CurId])
		end

		if string.len(Warning) > 0 then
			Warning = 'Errors in "Bolster - monsters.txt":\n'
			debug.Message(Warning)
		end
	end

	BolsterTxt:close()

	----

	Game.Bolster.MonstersSource = Game.Bolster.Monsters

	---- Formulas:

	Game.Bolster.Formulas = {}
	Bolster = Game.Bolster.Formulas
	BolsterTxt = io.open("Data/Tables/Bolster - formulas.txt", "r")

	if BolsterTxt then
		local LineIt = BolsterTxt:lines()
		LineIt() -- skip header

		for line in LineIt do
			local Words = string.split(line, "\9")
			if Words[1] and Words[2] and Words[3] and string.len(Words[1]) > 0 and string.len(Words[2]) > 0 then
				local CurId = tonumber(Words[1]) or Words[1]
				local str
				Bolster[CurId] = Bolster[CurId] or {}

				if string.len(Words[3]) == 0 then
					str = "return false"
				elseif string.find(Words[3], "return") then
					str = Words[3]
				else
					str = "return " .. Words[3]
				end

				Bolster[CurId][Words[2]] = assert(loadstring(str))
			end
		end
	end

end

local SpellReplace = {[81] = 87}

local OffensiveSpells = {
{2,6,11},		-- fire
{15,18},		-- air
{24,26,29,32},	-- water
{39,41},		-- earth
{46,47,51,59},	-- spirit
{59,65},		-- mind
{68,70,76},		-- body
{78,87},		-- light
{90,93,95}		-- dark
}

local DefensiveSpells = {
{5},			-- fire
{17},			-- air
{26},			-- water
{38},			-- earth
{46,47,51,52},	-- spirit
{59,65},		-- mind
{68,71,77},		-- body
{86},			-- light
{95}			-- dark
}

local HPMulByStyle 		= {[0] = 1, 1.3, 0.9, 0.7, 0.5}
local DamageMulByStyle 	= {[0] = 1.5, 1, 1.2, 1, 1}
local BolsterTypes = const.Bolster.Types

-----------------------------------------------
-- Service

local function GetOverallPartyLevel()
	local Ov, Cnt = 0, 1
	for i,v in Party do
		Ov = Ov + v.LevelBase
		Cnt = i + 1
	end

	local t = {Result = ceil(Ov/Cnt)}
	events.Call("CalcBolsterLevel", t)

	return t.Result
end

local function GetOverallItemBonus() -- approximate equipped items costs as their power
	local result = 0
	for ip,player in Party do
		for i,v in player.EquippedItems do
			if v > 0 then
				result = result + player.Items[v]:GetValue()
			end
		end
	end
	return result
end

local function SetAttackMaxDamage(Attack, MaxDamage)
	MaxDamage = ceil(MaxDamage)

	local Dices, Sides
	local FixDamage = MaxDamage * random(1,3)/10

	MaxDamage = MaxDamage - FixDamage
	Dices = sqrt(MaxDamage)
	Sides = Dices + random(ceil(sqrt(Dices)))

	Attack.DamageAdd 		= FixDamage
	Attack.DamageDiceSides 	= Sides
	Attack.DamageDiceCount 	= Dices
end

local function GenMonSpell(MonSettings, BolStep, SpellNum, OtherSpell)

	local Magic, Creed, Style, Ranged = MonSettings.Magic, MonSettings.Creed, MonSettings.Style, MonSettings.Ranged
	local NoSpell = SpellNum == 2 and (Style == 0 or Style == 2) or Style == 4

	if NoSpell then
		return 0
	end

	local School, Spell
	if Magic == 0 then
		School = random(1,9)
	elseif Magic < 10 then
		School = Magic
	elseif Magic == 10 then
		School = random(5,7)
	elseif Magic == 11 then
		School = random(1,4)
	end

	-- Light mages always have one offensive spell and one defensive spell.
	-- Dark mages always have two offensive spells.
	-- Strength monsters have one offensive or defensive spell according to ability to use ranged attacks.
	-- Endurance monsters have two defensive spells.
	-- Speed monsters have one defensive spell.

	local IsOffensive =
					(Creed == 2 and Style == 3)
				or 	(Creed ~= 2 and Style == 3 and SpellNum == 0)
				or 	(Style == 0 and SpellNum == 0)

	local SpellSet
	if IsOffensive then
		SpellSet = OffensiveSpells[School]
	else
		SpellSet = DefensiveSpells[School]
	end

	Spell = min(#SpellSet, BolStep + SpellNum)
	Spell = SpellSet[random(1,Spell)]

	if OtherSpell and OtherSpell == Spell then
		Spell = DefensiveSpells[School][1]
		if OtherSpell == Spell then
			Spell = 0
		end
	end

	return Spell

end

local function GetMaxDamage(Attack)
	return Attack.DamageDiceCount*Attack.DamageDiceSides+Attack.DamageAdd
end
local function clamp(v, low, high)
	return min(max(v, low), high)
end

local function GetAvgMonLevel(MonsterIndex)
	local MonsterKind = ceil(MonsterIndex/3)
	local result = 0
	for p = 0, 2 do
		result = result + Game.MonstersTxt[MonsterKind*3-p].Level + Game.Bolster.Monsters[MonsterKind*3-p].LevelShift
	end
	result = max(ceil(result/3), 3)

	local shift = ceil(result * (1 - Game.BolsterAmount / 100))
	result = clamp(result + shift, 3, result + 25)
	return result
end

-----------------------------------------------
--	Multipliers

local Multipliers = {
	HP = 1,
	AC = 1,
	MaxDamage = 1,
	PlayerAC = 1,
	MoveSpeed = 1,
}

local function ApplyMultiplier(Field, Old, New)
	local mul = Multipliers[Field]
	if not mul then
		return New
	end
	local Diff = New - Old
	return Old + Diff * mul
end

function events.NeedRebolster(t)
	local old = vars.BolsterMultipliers
	if not old then
		vars.BolsterMultipliers = table.copy(Multipliers)
		t.Need = true
	else
		for k, v in pairs(Multipliers) do
			if v ~= old[k] then
				t.Need = true
				old[k] = v
			end
		end
	end
end

function events.BeforeSaveGame()
	vars.BolsterMultipliers = table.copy(Multipliers)
end

function events.LoadMapScripts(WasInGame)
	if not WasInGame and vars.BolsterMultipliers then
		for k,v in pairs(vars.BolsterMultipliers) do
			Multipliers[k] = v
		end
	end
end

-- UI - like this, untill multiplayer UI utils are moved to general scripts
function events.MultiplayerInitialized()
	local ScreenId = CustomUI.NewSettingsPage("BolsterFineTuning", "Bolster multipliers", "ExSetScr2")
	local Elements = {}
	local function regulator(Y, Header, Field)
		Elements[#Elements + 1] = Multiplayer.utils.UI.CustomNumeric(ScreenId, 120, Y, nil,
			StrColor(255,255,150) .. Header .. StrColor(255,255,255),
			Multipliers, Field, 0.05, 0.05, 5)
	end
	--regulator(190, "Health points ", "HP")
	--regulator(220, "Armor class   ", "AC")
	--regulator(250, "Damage        ", "MaxDamage")
	--regulator(280, "Hit chance    ", "PlayerAC")
	--regulator(310, "Movement speed", "MoveSpeed")

	function events.OpenExtraSettingsMenu()
		for _, v in pairs(Elements) do
			if v.Update then
				v:Update()
			end
		end
	end
end

-----------------------------------------------
--	Rebolster without map reload

local MonTxtDumpFields = "FullHP,ArmorClass,MoveSpeed,Attack2Chance,Spell,Spell2,SpellChance,SpellSkill,Spell2Chance,Spell2Skill,SpecialA,SpecialB,SpecialC,SpecialD,Experience,TreasureItemPercent,TreasureItemLevel,Level"
MonTxtDumpFields = MonTxtDumpFields:split(",")

local monsters_txt_dump

local function dump_monsters_txt()
	local fields = MonTxtDumpFields

	local result = {}
	for i,txtmon in Game.MonstersTxt do
		local t = {}
		result[i] = t
		for fi, field in ipairs(fields) do
			t[fi] = txtmon[field]
		end

		t.Attack1 = mem.string(txtmon.Attack1["?ptr"], txtmon.Attack1["?size"], true)
		t.Attack2 = mem.string(txtmon.Attack2["?ptr"], txtmon.Attack2["?size"], true)
	end
	return result
end
Game.Bolster.DumpMonstersTxt = dump_monsters_txt

local function load_monsters_txt(data)
	local fields = MonTxtDumpFields

	for monid, t in pairs(data) do
		local txtmon = Game.MonstersTxt[monid]
		for fi, field in ipairs(fields) do
			txtmon[field] = t[fi]
		end
		mem.copy(txtmon.Attack1["?ptr"], t.Attack1)
		mem.copy(txtmon.Attack2["?ptr"], t.Attack2)
	end
end
Game.Bolster.LoadMonstersTxt = load_monsters_txt

function events.LoadMapScripts()
	monsters_txt_dump = dump_monsters_txt()
end

local function ReBolsterMonsters()
	table.clear(ReadyMons)
	load_monsters_txt(monsters_txt_dump)
	Game.BolsterMonsters()
end
Game.ReBolsterMonsters = ReBolsterMonsters

function events.ExitExtraSettingsMenu()
	vars.ExtraSettings = vars.ExtraSettings or {}
	local ExSet = vars.ExtraSettings

	local t = {Need = vars.ExtraSettings.BolsterAmount ~= Game.BolsterAmount or Game.UseMonsterBolster ~= ExSet.UseMonsterBolster}
	events.Call("NeedRebolster", t)
	if t.Need then
		Game.ReBolsterMonsters()
		ExSet.BolsterAmount = Game.BolsterAmount
		ExSet.UseMonsterBolster = Game.UseMonsterBolster
	end
end

-----------------------------------------------
-- Bolstering

local LastFormulaEnv = {
	max	= max,
	min	= min,
	ceil = ceil,
	floor = floor,
	sqrt = sqrt,
	random = random,
	abs = math.abs,
	clamp = clamp
}

local function PrepareMapMon(mon, MapSettings)

	local t = {TxtId = mon.Id, Id = mon:GetIndex(), Monster = mon, Handled = false}
	events.Call("BeforeMonsterBolster", t)

	if t.Handled then
		return
	end

	local TxtMon		= Game.MonstersTxt[mon.Id]
	local MonSettings	= Game.Bolster.Monsters[mon.Id]
	local BolStep		= MonBolStep[mon.Id]

	-- Base stats

	if mon.HP > 0 then
		mon.HP = max(floor(TxtMon.FullHP * mon.HP/mon.FullHP), 1)
	end
	mon.FullHP = TxtMon.FullHP

	mon.ArmorClass = TxtMon.ArmorClass
	mon.MoveSpeed = TxtMon.MoveSpeed
	mon.Velocity = mon.MoveSpeed

	-- Attacks

	mon.Attack1.DamageAdd 		= TxtMon.Attack1.DamageAdd
	mon.Attack1.DamageDiceSides = TxtMon.Attack1.DamageDiceSides
	mon.Attack1.DamageDiceCount = TxtMon.Attack1.DamageDiceCount

	mon.Attack2.DamageAdd 		= TxtMon.Attack2.DamageAdd
	mon.Attack2.DamageDiceSides = TxtMon.Attack2.DamageDiceSides
	mon.Attack2.DamageDiceCount = TxtMon.Attack2.DamageDiceCount

	mon.Attack2Chance 			= TxtMon.Attack2Chance
	mon.Attack2.Missile 		= TxtMon.Attack2.Missile
	mon.Attack2.Type 			= TxtMon.Attack2.Type

	-- Spells
	-- Monsters can not cast paralyze, replace it:
	mon.Spell = SpellReplace[mon.Spell] or mon.Spell
	mon.Spell2 = SpellReplace[mon.Spell2] or mon.Spell2

	local NeedSpells = BolStep and MapSettings.Spells and MonSettings.Spells
	if mon.Spell == 0 and NeedSpells then
		mon.Spell = GenMonSpell(MonSettings, BolStep, 0)
	end
	mon.SpellChance		= TxtMon.SpellChance
	mon.SpellSkill 		= TxtMon.SpellSkill

	if mon.Spell2 == 0 and NeedSpells then
		mon.Spell2 = GenMonSpell(MonSettings, BolStep, 1, mon.Spell)
	end
	mon.Spell2Chance	= TxtMon.Spell2Chance
	mon.Spell2Skill 	= TxtMon.Spell2Skill

	-- Summons

	mon.Special 	= TxtMon.Special
	mon.SpecialA 	= TxtMon.SpecialA
	mon.SpecialB 	= TxtMon.SpecialB
--	mon.SpecialC 	= TxtMon.SpecialC
	mon.SpecialD 	= TxtMon.SpecialD

	-- Rewards

	mon.Experience = TxtMon.Experience
	mon.TreasureItemPercent = TxtMon.TreasureItemPercent
	mon.TreasureItemLevel	= TxtMon.TreasureItemLevel

	mon.Level = TxtMon.Level

end

local function PrepareTxtMon(i, PartyLevel, MapSettings, OnlyThis)

	if not Game.UseMonsterBolster or not TxtLocalized or PartyLevel < 0 or MapSettings.Type == 0 then
		return
	end

	local t = {TxtId = i, Id = nil, Handled = false}
	events.Call("BeforeMonsterBolster", t)

	if t.Handled then
		return
	end

	-- formulas variables
	local MonsterLevel,TotalEquipCost,HP,BoostedHP,AC,MonsterHeight,MaxDamage,SpellSkill,SpellMastery,BolsterMul,MonsterPower,MonSettings,MoveSpeed
	--

	local BolStep, MonTable, MonKind
	local TotalEquipCost = GetOverallItemBonus()
	local MonsSettings = Game.Bolster.Monsters
	local BolsterMul = Game.BolsterAmount/100
	local Formulas = Game.Bolster.Formulas

	local env = LastFormulaEnv

	local function ProcessFormula(MonKind, Field, Default)
		local Formula
		local set = Formulas[MonKind]
		if set and set[Field] then
			Formula = set[Field]
		else
			Formula = Formulas["def"][Field]
		end

		if type(Formula) == "function" then
			env.PartyLevel 		= PartyLevel
			env.MonsterLevel 	= MonsterLevel
			env.TotalEquipCost 	= TotalEquipCost
			env.HP				= HP
			env.BoostedHP 		= BoostedHP
			env.AC 				= AC
			env.MonsterHeight 	= MonsterHeight
			env.MaxDamage 		= MaxDamage
			env.SpellSkill		= SpellSkill
			env.SpellMastery 	= SpellMastery
			env.BolsterMul 		= BolsterMul
			env.MonsterPower 	= MonsterPower
			env.MonSettings 	= MonSettings
			env.MapSettings 	= MapSettings
			env.MoveSpeed		= MoveSpeed

			setfenv(Formula, env)
			return ApplyMultiplier(Field, Default, Formula())
		end
		return Default
	end

	MonTable = {}

	if type(i) == "number" then
		MonKind = ceil(i/3)
		MonTable = OnlyThis and {[i] = Game.MonstersTxt[i]}
			or 	{	[MonKind*3-2] = Game.MonstersTxt[MonKind*3-2],
					[MonKind*3-1] = Game.MonstersTxt[MonKind*3-1],
					[MonKind*3  ] = Game.MonstersTxt[MonKind*3  ]}

	elseif type(i) == "table" then
		for k,v in pairs(i) do
			MonKind = ceil(v/3)
			MonTable[MonKind*3-2] = Game.MonstersTxt[MonKind*3-2]
			MonTable[MonKind*3-1] = Game.MonstersTxt[MonKind*3-1]
			MonTable[MonKind*3  ] = Game.MonstersTxt[MonKind*3  ]
		end
	else
		return
	end

	for k,v in pairs(MonTable) do
		if ReadyMons[k] or GetAvgMonLevel(k) >= PartyLevel and MapSettings.Type ~= BolsterTypes.AllToEqual then
			MonTable[k] = nil
		end
	end

	for monId, mon in pairs(MonTable) do

		MonKind 		= ceil(monId/3)
		HP 				= mon.FullHP
		BoostedHP		= mon.FullHP
		AC 				= mon.ArmorClass
		MonSettings		= MonsSettings[monId]
		MonsterHeight 	= Game.MonListBin[monId].Height
		MonsterPower	= monId - MonKind*3 + 3
		MonsterLevel	= GetAvgMonLevel(monId)
		BolStep 		= min(floor(PartyLevel/MonsterLevel), 4)

		local Formula = Formulas[MonKind] or Formulas["def"]

		MonBolStep[monId] = BolStep

		if MapSettings.Type ~= BolsterTypes.OriginalStats then

			-- Base hitpoints
			mon.FullHP = min(ProcessFormula(MonKind, "HP", mon.FullHP), 30000)
			BoostedHP  = mon.FullHP

			-- Armor class
			mon.ArmorClass = ProcessFormula(MonKind, "AC", mon.ArmorClass)

			-- Attacks
			MaxDamage = GetMaxDamage(mon.Attack1)
			MaxDamage = ProcessFormula(MonKind, "MaxDamage", MaxDamage)
			SetAttackMaxDamage(mon.Attack1, MaxDamage)

			if mon.Attack2Chance > 0 then
				MaxDamage = GetMaxDamage(mon.Attack2)
				MaxDamage = ProcessFormula(MonKind, "MaxDamage", MaxDamage)
				SetAttackMaxDamage(mon.Attack2, MaxDamage)
			end

			-- Base spells

			local Skill, Mas
			if mon.Spell > 0 then
				SpellSkill, SpellMastery = SplitSkill(mon.SpellSkill)
				Skill = ProcessFormula(MonKind, "SpellSkill", SpellSkill)
				Mas   = ProcessFormula(MonKind, "SpellMastery", SpellMastery)
				mon.SpellSkill = JoinSkill(Skill, Mas)
			end

			if mon.Spell2 > 0 then
				SpellSkill, SpellMastery = SplitSkill(mon.Spell2Skill)
				Skill = ProcessFormula(MonKind, "SpellSkill", SpellSkill)
				Mas   = ProcessFormula(MonKind, "SpellMastery", SpellMastery)
				mon.Spell2Skill = JoinSkill(Skill, Mas)
			end

		end

		-- Move speed

		MoveSpeed = mon.MoveSpeed
		mon.MoveSpeed = ProcessFormula(MonKind, "MoveSpeed", mon.MoveSpeed)

		-- Additional attacks

		if mon.Attack2Chance == 0 and MonSettings.Ranged and BolStep > 0 then
			mon.Attack2Chance 			= min(BolStep*10, 35)
			mon.Attack2.Missile 		= BolStep > 2 and (MonSettings.Magic == 0 and 1 or 6) or 0
			mon.Attack2.Type 			= mon.Attack1.Type

			MaxDamage = GetMaxDamage(mon.Attack1)
			SetAttackMaxDamage(mon.Attack2, MaxDamage)
		end

		-- Additional spells

		if ProcessFormula(MonKind, "AllowNewSpell", false) then

			local SkillByMas = {1,4,7,10}
			local Mas = MonSettings.Style == 3 and 2 or 1
			local Skill = SkillByMas[Mas]

			SpellSkill, SpellMastery = Skill, Mas
			Skill = ProcessFormula(MonKind, "SpellSkill", SpellSkill)
			Mas   = ProcessFormula(Formula, "SpellMastery", SpellMastery)

			if mon.Spell == 0 and (BolStep >= 1 or MonSettings.Style == 3) then
				mon.SpellSkill = JoinSkill(Skill, Mas)
				mon.SpellChance = MonSettings.Style == 3 and 60 or 35
			end

			if mon.Spell2 == 0 and (BolStep >= 2 or (MonSettings.Style == 3 and BolStep >= 1)) then
				mon.Spell2Skill = JoinSkill(Skill, Mas)
				mon.Spell2Chance = MonSettings.Style == 3 and 35 or 20
			end

		end

		-- Summons

		if ProcessFormula(MonKind, "AllowReplicate", false) then

			mon.Special = 4
			mon.SpecialA = 0
			mon.SpecialB = 0
			mon.SpecialC = 2
			mon.SpecialD = MonSettings.SummonId

		end

		if ProcessFormula(MonKind, "AllowSummons", false) then

			mon.Special = 2
			mon.SpecialA = mon.MoveType == 5 and 0 or max((1 + BolStep),3) -- If monster always stands still, like Trees in The Tularean forest, he will behave like spawn point.
			mon.SpecialB = Game.MonstersTxt[MonSettings.SummonId].Fly == 1 and 0 or 1 -- if summon can fly he will be summoned in air.
			mon.SpecialC = 0
			mon.SpecialD = MonSettings.SummonId == 0 and monId or MonSettings.SummonId

		end

		ReadyMons[monId] = true

	end

end

local function BolsterMonsters()

	local MapSettings = Game.Bolster.Maps[Map.MapStatsIndex]
	if not MapSettings then
		return
	end

	local t = {Handled = false}
	events.Call("BeforeMapBolster", t)

	if not t.Handled then
		local PartyLevel = GetOverallPartyLevel() + MapSettings.LevelShift
		local MapInTxt = Game.MapStats[Map.MapStatsIndex]
		local t = {}

		for i,v in Game.MonListBin do
			if 		string.find(v.Name, MapInTxt.Monster1Pic)
				or	string.find(v.Name, MapInTxt.Monster2Pic)
				or	string.find(v.Name, MapInTxt.Monster3Pic) then

				if not ReadyMons[i] then
					table.insert(t, i)
				end
			end
		end

		-- summons
		for i = 97, 99 do
			if not ReadyMons[i] then
				table.insert(t, i)
			end
		end

		for i,v in Map.Monsters do
			mon=Map.Monsters[i]
			--if  (mon.FullHitPoints == Game.MonstersTxt[mon.Id].FullHitPoints) then
				if not ReadyMons[v.Id] then
					if v.Id > 0 and v.Id < Game.MonstersTxt.Limit then
						table.insert(t, v.Id)
					else
						Log(Merge.Log.Error, "%s: Monster with incorrect Id (%s) at %s %s %s", Map.Name, v.Id, v.X, v.Y, v.Z)
						v.AIState = const.AIState.Removed
					end
				end
			--end
		end

		PrepareTxtMon(t, PartyLevel, MapSettings, false)

		for i,v in Map.Monsters do
			mon=Map.Monsters[i]
			if  (mon.FullHitPoints == Game.MonstersTxt[mon.Id].FullHitPoints) then
				if v.Id > 0 and v.Id < Game.MonstersTxt.Limit then
					PrepareMapMon(v, MapSettings)
				end
			end
		end
	end

	events.Call("AfterMapBolster")

end

-----------------------------------------------
-- Init

local function Init()

	ProcessBolsterTxt()
	Game.Bolster.ReloadTxt = ProcessBolsterTxt
	local StdSummonMonster = SummonMonster

	function SummonMonster(Id, ...)

		local mon, i = StdSummonMonster(Id, ...)
		if not mon then
			return
		end

		if not (Editor and Editor.WorkMode) then

			local MapSettings = Game.Bolster.Maps[Map.MapStatsIndex]
			if MapSettings then
				local PartyLevel = GetOverallPartyLevel() + MapSettings.LevelShift
				if not ReadyMons[Id] then
					PrepareTxtMon(Id, PartyLevel, MapSettings)
				end
				PrepareMapMon(mon, MapSettings)
			end

		end

		return mon, i
	end

	-- Set monster kind check

	function events.IsMonsterOfKind(t)
		local MonExtra = Game.Bolster.MonstersSource[t.Id]
		if t.Kind == MonExtra.Type or table.find(MonExtra.ExtraType, t.Kind) then
			t.Result = 1
		end
	end

	-- Boost summons

	mem.autohook2(0x44d4b1, function(d)
		if Game.UseMonsterBolster and not ReadyMons[d.esi] then
			local MapSettings = Game.Bolster.Maps[Map.MapStatsIndex]
			if MapSettings then
				local PartyLevel = GetOverallPartyLevel() + MapSettings.LevelShift

				for i = d.esi, d.esi+2 do
					if not ReadyMons[i] then
						PrepareTxtMon(i, PartyLevel, MapSettings)
					end
				end
			end
		end
	end)

	-- Arena monsters generation
	local ArenaMonstersList, ArenaPartyLevel, ArenaMapSettings
	function events.BeforeArenaStart(ArenaLevel)

		local PartyLevel = GetOverallPartyLevel()

		local MinLevel, MaxLevel
		if ArenaLevel == 0 then
			MinLevel = 0
			MaxLevel = max(PartyLevel, 10)
		elseif ArenaLevel == 1 then
			MinLevel = min(ceil(PartyLevel/5), 70)
			MaxLevel = max(PartyLevel, 10) + 5
		elseif ArenaLevel == 2 then
			MinLevel = min(ceil(PartyLevel/3), 70)
			MaxLevel = max(PartyLevel, 10) + 7
		elseif ArenaLevel == 3 then
			MinLevel = min(ceil(PartyLevel/2), 70)
			MaxLevel = max(PartyLevel, 10) + 10
		end

		local MinKind, MaxKind
		if ArenaLevel == 0 then
			MinKind, MaxKind = 1,1
		elseif ArenaLevel == 1 then
			MinKind, MaxKind = 1,2
		elseif ArenaLevel == 2 then
			MinKind, MaxKind = 2,3
		elseif ArenaLevel == 3 then
			MinKind, MaxKind = 3,3
		end

		local MonstersTxt = Game.MonstersTxt
		local List, Kind, MonLevel = {}, nil, nil
		for i = 1, Game.MonstersTxt.count-1 do
			Kind = 3 - i % 3
			if not (Kind < MinKind or Kind > MaxKind) then
				MonLevel = MonstersTxt[i].Level
				if not (MonLevel < MinLevel or MonLevel > MaxLevel) and Game.IsMonsterOfKind(i, const.MonsterKind.NoArena) == 0 then
					table.insert(List, i)
				end
			end
		end

		ArenaPartyLevel = PartyLevel
		ArenaMonstersList = List
		ArenaMapSettings = Game.Bolster.Maps[Map.MapStatsIndex]
	end
	--[[
	function events.GenerateArenaMonster(t)
		local MonId = ArenaMonstersList[random(#ArenaMonstersList)]

		t.Handled = true
		t.MonId = MonId

		if Game.UseMonsterBolster and ArenaMapSettings and not ReadyMons[MonId] then
			PrepareTxtMon(MonId, ArenaPartyLevel, ArenaMapSettings, true)
		end
	end
]]
	-- Add player's armor class penalty depending on enemy's bolster
	local NewCode = mem.asmpatch(0x48db2f, [[
	nop; mem hook
	nop
	nop
	nop
	nop

	xor edx, edx
	@std:
	cmp esi, 0x1]])

	local pptr, psize = Party.PlayersArray["?ptr"], Party.PlayersArray[0]["?size"]
	local function GetPlayer(ptr)
		local PlayerId = (ptr - pptr)/psize
		return Party.PlayersArray[PlayerId], PlayerId
	end

	mem.hook(NewCode, function(d)
		local source, player_slot = WhoHitPlayer()
		if not source or not source.Monster then
			return
		end

		local t = {
			Monster = source.Monster,
			MonsterIndex = source.MonsterIndex,
			AC = d.esi,
			Player = Party[player_slot]}

		local monId = t.Monster.Id
		if Game.UseMonsterBolster and ReadyMons[monId] then
			local Formulas = Game.Bolster.Formulas
			local f = Formulas[monId] and Formulas[monId]["PlayerAC"] or Formulas["def"]["PlayerAC"]
			LastFormulaEnv.PlayerAC = t.AC
			LastFormulaEnv.Player = t.Player
			LastFormulaEnv.Monster = t.Monster
			LastFormulaEnv.BolsterMul = Game.BolsterAmount / 100
			setfenv(f, LastFormulaEnv)

			local result = f() or d.esi
			t.AC = math.max(ApplyMultiplier("PlayerAC", t.AC, result), 0)
		end

		events.call("GetArmorClass", t)
		d.esi = t.AC
	end)

	Game.Bolster.Multipliers = Multipliers
	Game.Bolster.BolsterLevel = GetOverallPartyLevel
	Game.Bolster.PreparedTxtMons = function()
		return ReadyMons
	end

	Game.Bolster.OnLoadMap = function()
		if Editor and Editor.WorkMode then
			return
		end

		LocalMonstersTxt()
		TxtLocalized = true
		ReadyMons	= {}
		MonBolStep	= {}

		BolsterMonsters()
	end

end

function events.AfterLoadMap()
	local t = {Handled = false}
	events.Call("BolsterOnLoadMap", t)

	if not t.Handled then
		Game.Bolster.OnLoadMap()
	end
end

function events.LeaveMap()
	TxtLocalized = false
end

function events.LeaveGame()
	TxtLocalized = false
end

function events.GameInitialized2()
	Init()
end

Game.BolsterMonsters = BolsterMonsters
