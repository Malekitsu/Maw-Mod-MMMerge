local mmver = offsets.MMVersion

if mmver ~= 8 then
	return 0
end

-- Disable original handler:
mem.asmpatch(0x44e355, "jmp 0x44e39d - 0x44e355")
----

local SpriteEventsStart = 20000
local Events = {}
local random = math.random

-------------------------------------------------------
-- Give apple
local FruitBowls = {"dec28", "7dec08"}
local function GiveApple(Eid)
	local SpriteId = Eid - SpriteEventsStart
	local Sprite = Map.Sprites[SpriteId]

	evt.ForPlayer(0).Add{"Inventory", 655}
	mapvars.ActiveSprites[SpriteId] = true
	Sprite.Invisible = true
end

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	if table.find(FruitBowls, DecName) then
		if ActiveSprites[i] then
			Sprite.Invisible = true
		else
			Sprite.Event = SpriteEventsStart + i
			evt.map[SpriteEventsStart + i] = GiveApple
			evt.hint[SpriteEventsStart + i] = Game.NPCTopic[287]
		end
		return true
	end
end

-------------------------------------------------------
-- Skull piles
local SkullPileReq = {5,6,7,8}
local SkullPileCond = {"Weak","Cursed","Insane","Dead"}
local SkullPileHints = {[0] = 1750,1751,1752,1753,1754}
local function SkullPile(Eid)

	if Game.CurrentPlayer < 0 then
		return
	end

	local SpriteId = Eid - SpriteEventsStart
	local Var = mapvars.ActiveSprites[SpriteId]

	if Var == 0 then
		Game.ShowStatusText(Game.NPCText[2128])
		return
	end

	local Pl = Party[Game.CurrentPlayer]
	local Skill, Mas = SplitSkill(Pl.Skills[const.Skills.Perception])

	if Skill < SkullPileReq[Var] then
		Game.ShowStatusText(Game.NPCText[2118])
		evt[Game.CurrentPlayer].Set{SkullPileCond[Var], true}
	else
		mapvars.ActiveSprites[SpriteId] = 0
		evt[0].GiveItem{1, 43, 0}
		evt.hint[Eid] = Game.NPCTopic[SkullPileHints[0]]
	end

end

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	if DecName == "sklplrev" then
		local Seed = ActiveSprites[i]
		if not Seed then
			Seed = random(1,4)
			ActiveSprites[i] = Seed
		end
		Sprite.Event = SpriteEventsStart + i
		evt.map[SpriteEventsStart + i] = SkullPile
		evt.hint[SpriteEventsStart + i] = Game.NPCTopic[SkullPileHints[Seed]]
		return true
	end
end

-------------------------------------------------------
-- Crystals
-- puple, white, red, blue, breeze, purple, green, purple
local Crystals	= {"crystl0", "crclstr", "crys5", "crys6", "dec09", "dec10", "dec11", "dec12"}
local CrystalItems	= {2060, 2056, 2059, 2065, 2057, 2062, 2064, 2062}
local CrystalTopic	= 1759

local function PlcCrystal(Eid)

	local SpriteId = Eid - SpriteEventsStart
	local Sprite = Map.Sprites[SpriteId]
	local Var = Sprite.EventVariable

	local CurPl = Game.CurrentPlayer > -1 and Game.CurrentPlayer or 0
	if SplitSkill(Party[CurPl].Skills[const.Skills.Perception]) >= 7 then
		evt[0].Add{"Inventory", CrystalItems[Var]}
		Sprite.Invisible = true
		evt.FaceAnimation{CurPl, const.FaceAnimation.Smile}
	else
		evt.FaceAnimation{CurPl, select(math.random(1,2), const.FaceAnimation.Tired, const.FaceAnimation.Beg)}
	end

end

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	local Seed = table.find(Crystals, DecName)
	if Seed then
		Sprite.EventVariable = Seed
		Sprite.Event = SpriteEventsStart + i
		evt.map[SpriteEventsStart + i] = PlcCrystal
		evt.hint[SpriteEventsStart + i] = Game.NPCTopic[CrystalTopic]
		return true
	end
end

-------------------------------------------------------
-- Give item

local function ItemBucket(Eid)

	local SpriteId = Eid - SpriteEventsStart
	local Sprite = Map.Sprites[SpriteId]

	if mapvars.ActiveSprites[SpriteId] then
		Game.ShowStatusText(Game.NPCText[2135])
	else
		evt.GiveItem{1,Sprite.EventVariable}
		mapvars.ActiveSprites[SpriteId] = true
	end

end

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	if DecName == "Bucket" then
		Sprite.Event = SpriteEventsStart + i
		Sprite.EventVariable = 45 -- Reagent item type
		evt.map[SpriteEventsStart + i] = ItemBucket
		if ActiveSprites[i] then
			evt.hint[SpriteEventsStart + i] = Game.NPCText[2135]
		else
			evt.hint[SpriteEventsStart + i] = Game.NPCTopic[1755]
		end
		return true
	end
end

local function ItemSprite(Eid)

	local SpriteId = Eid - SpriteEventsStart
	local Sprite = Map.Sprites[SpriteId]
	local Var = Sprite.EventVariable
	local Seed = math.random(2)

	if Seed == 2 then
		evt.ForPlayer("Current").GiveItem{1,Var}
	else
		Game.ShowStatusText(Game.NPCText[2123])
	end
	mapvars.ActiveSprites[SpriteId] = true
	Sprite.Invisible = true

end

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	if DecName == "bag01" then
		Sprite.Event = SpriteEventsStart + i
		Sprite.EventVariable = 22 -- Misc item type
		evt.map[SpriteEventsStart + i] = ItemSprite
		evt.hint[SpriteEventsStart + i] = Game.NPCTopic[1743]
		Sprite.Invisible = ActiveSprites[i]
		return true
	end
end

-------------------------------------------------------
-- Treasure bag

local function TreasureBag(Eid)
	local SpriteId = Eid - SpriteEventsStart
	local Sprite = Map.Sprites[SpriteId]
	local Seed = math.random(200)

	if Seed > 50 then
		evt.ForPlayer("Current").Add{"Gold", Seed}
	else
		Game.ShowStatusText(Game.NPCText[2123])
	end
	mapvars.ActiveSprites[SpriteId] = true
	Sprite.Invisible = true

end

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	if DecName == "bag_A" then
		Sprite.Event = SpriteEventsStart + i
		evt.map[SpriteEventsStart + i] = TreasureBag
		evt.hint[SpriteEventsStart + i] = Game.NPCTopic[1747]
		Sprite.Invisible = ActiveSprites[i]
		return true
	end
end

-------------------------------------------------------
---- Give food

local CampFires = {"ckfyr00", "cmpfyr00", "fire01", "7dec02", "dec24", "dec25"} -- "dec04"
local CampFireEvents = {285, 286}

local function GiveFood(Eid)
	local SpriteId = Eid - SpriteEventsStart
	local Sprite = Map.Sprites[SpriteId]
	local Seed = math.random(4)

	evt.Add{"Food", Seed}
	mapvars.ActiveSprites[SpriteId] = true
	Sprite.Invisible = true
end

-- Init

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	if table.find(CampFires, DecName) then
		if ActiveSprites[i] then
			Sprite.Invisible = true
		else
			Sprite.Event = SpriteEventsStart + i
			evt.map[SpriteEventsStart + i] = GiveFood
			evt.hint[SpriteEventsStart + i] = Game.NPCTopic[CampFireEvents[1]]
		end
		return true
	end
end

-------------------------------------------------------
---- Food bags

local function FoodBag(Eid)
	local SpriteId = Eid - SpriteEventsStart
	local Sprite = Map.Sprites[SpriteId]
	local Seed = math.random(0,2)

	if Seed > 0 then
		evt.ForPlayer("Current").Add{"Food", Seed}
	else
		Game.ShowStatusText(Game.NPCText[2121])
	end
	mapvars.ActiveSprites[SpriteId] = true
	Sprite.Invisible = true
end

-- Init

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	if DecName == "floursac" then
		Sprite.Event = SpriteEventsStart + i
		evt.map[SpriteEventsStart + i] = FoodBag
		evt.hint[SpriteEventsStart + i] = Game.NPCTopic[1741]
		Sprite.Invisible = ActiveSprites[i]
		return true
	end
end

-------------------------------------------------------
-- Toggleable light sources

local LightSrcs = {	Off	= 	{"brzier00",	"TrchB00"},		--,	"6torch01"}
					On	=	{"brazir2f",	"nwtrchnf"}}	--,	"torchnf"}

local function FindLightSrc(SpriteId, Precision)
	local X, Y, Z = XYZ(Map.Sprites[SpriteId])
	local result = {{}, {}}

	for i,v in Map.Lights do
		if 		v.X >= X - Precision and v.X <= X + Precision
			and	v.Y >= Y - Precision and v.Y <= Y + Precision
			and	v.Z >= Z - Precision and v.Z <= Z + Precision then
			table.insert(result[1], i)
		end
	end
	for i,v in Map.SpriteLights do
		if 		v.X >= X - Precision and v.X <= X + Precision
			and	v.Y >= Y - Precision and v.Y <= Y + Precision
			and	v.Z >= Z - Precision and v.Z <= Z + Precision then
			table.insert(result[2], i)
		end
	end
	return result
end

local function LightSrcOnOff(SpriteId)
	local Sprite = Map.Sprites[SpriteId]
	local on = Sprite.DecName == LightSrcs.On[Sprite.EventVariable]
	Sprite.DecName = LightSrcs[on and "Off" or "On"][Sprite.EventVariable]

	local SrcCon = mapvars.LightSrcsConns[SpriteId]
	if not SrcCon then
		SrcCon = FindLightSrc(SpriteId, 100)
		mapvars.LightSrcsConns[SpriteId] = SrcCon
	end

	local L, SL = SrcCon[1], SrcCon[2]

	if L then
		for k,v in pairs(L) do
			Map.Lights[v].Off = not on
		end
	end
	if SL then
		for k,v in pairs(SL) do
			Map.SpriteLights[v].Radius = on and math.abs(Map.SpriteLights[v].Radius) or -Map.SpriteLights[v].Radius
		end
	end
end

local function ToggleLightSource(Eid)
	local SpriteId = Eid - SpriteEventsStart
	mapvars.ActiveSprites[SpriteId] = OnOff
	LightSrcOnOff(SpriteId)
end

-- Init

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	local Seed = table.find(LightSrcs.On, DecName)
	if Seed then
		Sprite.EventVariable = Seed
		Sprite.Event = SpriteEventsStart + i
		evt.map[SpriteEventsStart + i] = ToggleLightSource
		evt.hint[SpriteEventsStart + i] = Game.DecListBin[Map.Sprites[i].DecListId].GameName
		return true
	end
end

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	local Seed = table.find(LightSrcs.Off, DecName)
	if Seed then
		Sprite.EventVariable = Seed
		Sprite.Event = SpriteEventsStart + i
		evt.map[SpriteEventsStart + i] = ToggleLightSource
		evt.hint[SpriteEventsStart + i] = Game.DecListBin[Map.Sprites[i].DecListId].GameName
		if ActiveSprites[i] then
			LightSrcOnOff(i, Seed, false)
		else
			ActiveSprites[i] = false
		end
		return true
	end
end

-------------------------------------------------------
-- Trash heap

local TrashHeaps = {"trasheap", "7dec01", "7dec10", "dec20", "dec23", "7dec11"}
local TrashHeapEvents = {[0] = 284, 281, 282, 283}
local DiseaseTexts = {726, 727, 728} -- "Diseased!", "Nothing here", "Poisoned!"

local function TrashHeap(Eid)
	local SpriteId = Eid - SpriteEventsStart
	local Seed = math.random(3)

	evt.ForPlayer("Current")

	if mapvars.ActiveSprites[SpriteId] then
		if Seed > 2 and not evt.Cmp {"PerceptionSkill", 1} then
			evt.Set{"DiseasedGreen", 0}
			Game.ShowStatusText(Game.NPCText[DiseaseTexts[1]])
		else
			Game.ShowStatusText(Game.NPCText[DiseaseTexts[2]])
		end
	else
		evt.GiveItem{Seed, 19 + Seed, 0}
		if not evt.Cmp {"PerceptionSkill", 1} then
			evt.Set{113 + Seed, 0}
			Game.ShowStatusText(Game.NPCText[DiseaseTexts[Seed]])
		end

		mapvars.ActiveSprites[SpriteId] = true
		evt.hint[Eid] = Game.NPCTopic[TrashHeapEvents[0]]
	end

end

-- Init

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	if table.find(TrashHeaps, DecName) then
		Sprite.Event = SpriteEventsStart + i
		evt.map[SpriteEventsStart + i] = TrashHeap
		evt.hint[SpriteEventsStart + i] = Game.NPCTopic[TrashHeapEvents[0]]
		return true
	end
end

-------------------------------------------------------
-- Cauldron

local Cauldrons			= {"dec26", "cauld00", "7dec03"}
local CauldronEvents 	= {[0] = 276, 279, 278, 280, 277}
local CauldronTexts		= {[0] = 721, 724, 723, 725, 722}
local CauldronResists	= {1,2,3,0}
local CauldronABits		= {24, 25, 26, 27}

local function Cauldron(Eid)
	local SpriteId = Eid - SpriteEventsStart
	local Sprite = Map.Sprites[SpriteId]
	local Var = Sprite.EventVariable
	local Res = Party[Game.CurrentPlayer > -1 and Game.CurrentPlayer or 0].Resistances[CauldronResists[Var]]

	if mapvars.ActiveSprites[SpriteId] then
		Game.ShowStatusText(Game.NPCText[CauldronTexts[0]])
	else
		Game.ShowStatusText(Game.NPCText[CauldronTexts[Var]])
		Res.Base = Res.Base + 2
		evt.Set{"AutonotesBits", CauldronABits[Var]}
		evt.hint[Eid] = Game.NPCTopic[CauldronEvents[0]]
		mapvars.ActiveSprites[SpriteId] = true
	end
end

-- Init

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	if table.find(Cauldrons, DecName) then
		Seed = random(#CauldronEvents)
		Sprite.EventVariable = Seed
		Sprite.Event = SpriteEventsStart + i
		evt.map[SpriteEventsStart + i] = Cauldron
		if ActiveSprites[i] then
			evt.hint[SpriteEventsStart + i] = Game.NPCTopic[CauldronEvents[0]]
		else
			evt.hint[SpriteEventsStart + i] = Game.NPCTopic[CauldronEvents[Seed]]
		end
		return true
	end
end

-------------------------------------------------------
-- Challenge

local ChallengesMM8 = {"dec40", "dec41", "dec42", "dec43"}
local ChallengesMM7 = {"dec60", "dec61", "dec62", "dec63"}
local ChallengeRewards = {3, 5, 7, 10}
local WinCh, FaultCh, AlWin, WinText = 734, 729, 733, nil
local ChallengeEvents 	=  {{543, 545, 546, 544, 548, 547, 549}, -- Games
							{550, 552, 553, 551, 555, 554, 556}, -- Contests
							{557, 559, 560, 558, 562, 561, 563}, -- Tests
							{564, 566, 567, 565, 569, 568, 570}} -- Challenges

local function Challenge(Eid)
	local SpriteId = Eid - SpriteEventsStart
	local Sprite = Map.Sprites[SpriteId]
	local Var = Sprite.EventVariable
	local ChType = math.floor(Var/100)
	local ChSeed = Var - ChType*100

	local CurPlayer = Party.PlayersIndexes[math.max(Game.CurrentPlayer, 0)]
	vars.WonChallenges[CurPlayer] = vars.WonChallenges[CurPlayer] or {}

	local CurWins = vars.WonChallenges[CurPlayer]

	if CurWins[Var] then
		Game.ShowStatusText(Game.NPCText[AlWin])
	elseif evt.ForPlayer(math.max(Game.CurrentPlayer, 0)).Cmp{38 + ChSeed, 25*2^(ChType-1)} then
		local Reward = ChallengeRewards[ChType] or 2+2^(ChType-1)
		evt.ForPlayer("Current").Add{"SkillPoints", Reward}
		Game.ShowStatusText(string.format(WinText, "+" .. Reward))
		CurWins[Var] = true
	else
		Game.ShowStatusText(Game.NPCText[FaultCh])
	end

end

-- Init

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	local Seed = table.find(ChallengesMM8, DecName) or table.find(ChallengesMM7, DecName)
	if Seed then
		local ChallengeType = ChallengeEvents[Seed]
		local ChallengeSeed = mapvars.ActiveSprites[i] or random(#ChallengeType)

		Sprite.EventVariable = ChallengeSeed + Seed*100
		Sprite.Event = SpriteEventsStart + i
		evt.map[SpriteEventsStart + i] = Challenge
		evt.hint[SpriteEventsStart + i] = Game.NPCTopic[ChallengeType[ChallengeSeed]]

		ActiveSprites[i] = ChallengeSeed
		return true
	end
end

-------------------------------------------------------
-- Pedestal

local Pedestals = {	{"dec44", "dec45", "dec46", "dec47", "dec48", "dec49", "dec50", "dec51", "dec52", "dec53", "dec54", "dec55"},	-- mm8 set
					{"dec64", "dec65", "dec66", "dec67", "dec68", "dec69", "dec70", "dec71", "dec72", "dec73", "dec74", "dec75"} }	-- mm7 set

local PedestalEvents	= {531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542}
local PedestalSpells	= {5, 36, 83, 17, 25, 3, 51, 8, 58, 69, 38, 14}

local function Pedestal(Eid)
	local SpriteId = Eid - SpriteEventsStart
	local Sprite = Map.Sprites[SpriteId]
	local Var = Sprite.EventVariable

	CastSpellDirect(PedestalSpells[Var], 5, 3)

end

-- Init

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	local Seed
	for iL, v in ipairs(Pedestals) do
		local Seed = table.find(v, DecName)
		if Seed then
			Sprite.EventVariable = Seed
			Sprite.Event = SpriteEventsStart + i
			evt.map[SpriteEventsStart + i] = Pedestal
			evt.hint[SpriteEventsStart + i] = Game.NPCTopic[PedestalEvents[Seed]]
			return true
		end
	end
end

-------------------------------------------------------
-- Barrels
-- Might 		- Red,
-- Intellect 	- Orange,
-- Personality 	- Blue,
-- Endurance 	- Green,
-- Speed 		- Purple,
-- Accuracy 	- Yellow,
-- Luck 		- White
local Barrels			= {"dec03", "7dec32", "smlbarel", "bigbarel"}
local BarrelEvents		= {[0] = 268, 269, 272, 271, 273, 274, 270, 275}
local BarrelTexts 		= {[0] = 713, 714, 717, 716, 718, 719, 715, 720}
local BarrelABits 		= {17, 18, 19, 20, 22, 21, 23}

local function Barrel(Eid)
	local SpriteId = Eid - SpriteEventsStart

	if mapvars.ActiveSprites[SpriteId] == 0 then
		Game.ShowStatusText(Game.NPCText[BarrelTexts[0]])
	else
		local Sprite = Map.Sprites[SpriteId]
		local Var = Sprite.EventVariable
		Game.ShowStatusText(Game.NPCText[BarrelTexts[Var]])
		evt.ForPlayer("Current").Add{31 + Var, 2}
		evt.Set{"AutonotesBits", BarrelABits[Var]}
		mapvars.ActiveSprites[SpriteId] = 0
		evt.hint[Eid] = Game.NPCTopic[BarrelEvents[0]]
	end
end

-- Init

Events[#Events+1] = function(i, DecName, Sprite, ActiveSprites)
	if table.find(Barrels, DecName) then
		local Seed = ActiveSprites[i]
		Seed = not Seed and random(#BarrelEvents) or Seed
		mapvars.ActiveSprites[i] = Seed

		Sprite.EventVariable = Seed
		Sprite.Event = SpriteEventsStart + i
		evt.map[SpriteEventsStart + i] = Barrel
		if Seed == 0 or Seed == true then
			evt.hint[SpriteEventsStart + i] = Game.NPCTopic[BarrelEvents[0]]
		else
			evt.hint[SpriteEventsStart + i] = Game.NPCTopic[BarrelEvents[Seed]]
		end
		return true
	end
end

-------------------------------------------------------
---- Initialization

local function InitSprite(i, Force)
	local Sprite = Map.Sprites[i]
	if Sprite.Event > 0 and Sprite.Event < SpriteEventsStart then
		return -- this is predefined sprite event from other script
	end

	if Force or Sprite.Event == 0 then
		local DecName = Sprite.DecName
		evt.map[SpriteEventsStart + i]:clear()
		for k,v in pairs(Events) do
			if v(i, DecName, Sprite, mapvars.ActiveSprites) then
				break
			end
		end
	end
end
Game.ReInitSpriteEvent = InitSprite

local function Init(Force)

	mapvars.LightSrcsConns = mapvars.LightSrcsConns or {}
	mapvars.LightSrcsConns[1] = mapvars.LightSrcsConns[1] or {}
	mapvars.LightSrcsConns[2] = mapvars.LightSrcsConns[2] or {}
	mapvars.ActiveSprites = mapvars.ActiveSprites or {}
	WinText = WinText or string.replace(Game.NPCText[WinCh], " +3", "%s")

	vars.WonChallenges = vars.WonChallenges or {}

	for i = 0, Map.Sprites.count - 1 do
		InitSprite(i, Force)
	end

end

function events.LoadMap()
	Init()
end
Game.ReInitSprites = Init

