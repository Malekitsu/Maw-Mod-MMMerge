mapvars.SplittedNPC = mapvars.SplittedNPC or {}
local QSet = vars.Quest_CrossContinents
local SplittedNPC = mapvars.SplittedNPC
local CurEvt
local SwitchDoor = OutdoorAnimObjects.SwitchDoor
local ChaosNPC = 1092

local StdPeriod = math.floor(const.Minute/64)
local EvtId = 100
local function IncEvt()
	EvtId = EvtId + 1
	return EvtId
end

-----------------------------------
-- Multiplayer support
-----------------------------------

if Multiplayer then
	Multiplayer.mapvar_watch{"Hour", "Minute", "DayState", "SwordsAggro"}

	local npc_fields = {"House", "Pic", "Greet", "EventA", "EventB", "EventC", "EventD", "EventE", "EventF"}

	local function prep_split_info()
		local t = {}
		for k,v in pairs(mapvars.SplittedNPC) do
			t[k] = {v, Game.NPC[k].Name, Multiplayer.utils.nums_to_bin(Game.NPC[k], npc_fields, 2)}
		end
		return t
	end

	local function process_split_info(t)
		QSet.BreachSplit = true
		for k,v in pairs(mapvars.SplittedNPC) do
			Game.NPC[k].House = 0
		end
		for k,v in pairs(t) do
			mapvars.SplittedNPC[k] = v[1]
			Game.NPC[k].Name = v[2]
			Multiplayer.utils.fill_from_bin(Game.NPC[k], mem.topointer(v[3]), npc_fields, 2)
		end
	end

	function events.MultiplayerPrepMapData(t)
		if QSet.BreachSplit then
			t.BrAlvarSplittedNPC = prep_split_info()
		else
			Multiplayer.utils.TickChecker(
				function() Multiplayer.broadcast_mapdata(prep_split_info()) end,
				32,
				function() return QSet.BreachSplit end)
		end
	end

	function events.MultiplayerProcessMapData(t)
		if t.BrAlvarSplittedNPC then
			process_split_info(t.BrAlvarSplittedNPC)
		end
	end

	function events.MultiplayerUserdataArrived(t)
		if t == "WinGame" then
			Multiplayer.utils.TickChecker(
				function()
					evt.MoveToMap{-841,-475,4501,176,0,0,0,0,"Breach.odm"}
					NPCFollowers.Remove(ChaosNPC)
					evt.ForPlayer("All").Add{"Experience", 100000}
				end,
				16,
				function()
					return Game.CurrentScreen == 0
				end)
		else
			process_split_info(t)
		end
	end
end

-----------------------------------
-- Step sounds
-----------------------------------

local StepSounds = {
	["7hdwtr000"]	= {[0] = 101, [1] = 62},
	["7wtrtyl"]		= {[0] = 101, [1] = 62},
	["6grastyl"] 	= {[0] = 93, [1] = 54},
	["t1books"] 	= {[0] = 103, [1] = 64},
	["bemhwal"] 	= {[0] = 103, [1] = 64},
	["bemtila"] 	= {[0] = 103, [1] = 64},
	["t66d01p1"] 	= {[0] = 89, [1] = 50},
	["t66d01p2"] 	= {[0] = 89, [1] = 50}
}

local SSFastConns = {}

function events.StepSound(t)
	local BId = t.Facet.BitmapId
	local Sound = SSFastConns[BId]
	if Sound == false then
		return
	elseif Sound == nil then
		SSFastConns[BId] = StepSounds[Game.BitmapsLod.Bitmaps[BId].Name] or false
		Sound = SSFastConns[BId]
		if Sound then
			t.Sound = Sound[t.Run]
		end
	else
		t.Sound = Sound[t.Run]
	end
end

-----------------------------------
-- Operate daylight
-----------------------------------

mapvars.Hour = mapvars.Hour or 4
mapvars.Minute = mapvars.Minute or 12

function events.SetOutdoorLight(t)
	t.Hour = mapvars.Hour or 4
	t.Minute = mapvars.Minute or t.Minute
end

local function InitDaylight()
	mapvars.Hour = mapvars.Hour or 4
	mapvars.Minute = mapvars.Minute or 12
end

local function SwitchDayLight(M, State)
	local CanSwitch = SwitchDoor("Time_1", false)
		and SwitchDoor("Time_2", false)
		and SwitchDoor("Time_3", false)

	if CanSwitch then
		if State == 1 then
			mapvars.Hour = 4
			mapvars.Minute = 12
		elseif State == 2 then
			mapvars.Hour = 6
			mapvars.Minute = 12
		else
			mapvars.Hour = 11
			mapvars.Minute = false
		end

		mapvars.DayState = State
		OutdoorAnimObjects.SwitchDoor(M)
	end
end

for i = 1, 3 do
	local CurModel = "Time_" .. i
	CurEvt = IncEvt()
	evt.map[CurEvt] = function() SwitchDayLight(CurModel, i) end

	OutdoorAnimObjects.SetDoor{
		Model = CurModel,
		EvtId = CurEvt,
		Time = const.Minute,
		dx = 0, dy = 0, dz = -10,
		Period = StdPeriod,
		Closed		= true,
		Normal 		= false,
		InMove		= false	}
end
SwitchDayLight("Time_1", mapvars.DayState or 1)

-----------------------------------
-- Find companions
-----------------------------------

local function SplitParty()

	if Party.count > 1 then
		Game.ShowStatusText(evt.str[1], 5) -- "Your friends have disappeared!"
		Party.QBits[1714] = true
	end

	local splitted = 0
	local i
	local v
	if Party.count <= 1 then
		i = 38
		v = Party.PlayersArray[i]
		if v.Experience == 100000 and v.LevelBase == 10 then
			GenerateMercenary{RosterId = 38, Level = math.max(Party[0].LevelBase + math.random(-5, 8), 1)}
			QSet.FQMercRnd[772] = true
		end
	else
		local ri = math.random(1, Party.count-1)
		i = Party.PlayersIndexes[ri]
		DismissCharacter(ri)
		v = Party.PlayersArray[i]
	end

	local NPCId = 772
	local NPC = Game.NPC[NPCId]
	NPC.Pic = Game.CharacterPortraits[v.Face].NPCPic
	NPC.Name = v.Name
	NPC.Greet = 0

	SplittedNPC[NPCId] = i

	for i,v in NPC.Events do
		NPC.Events[i] = 0
	end
	NPC.EventA = 1789

	local monByRace = {[1] = 417, [3] = 66, [4] = 60, [5] = 72, [6] = 290}
	local Race = Game.CharacterPortraits[v.Face].Race
	local monId = monByRace[Race]

	if not monId then
		local Class = v.Class
		local ClassKind = Game.ClassesExtra[Class].Kind
		local Gender = Game.CharacterPortraits[v.Face].DefSex

		if ClassKind == 1 then
			monId = Gender == 1 and 477 or 204

		elseif ClassKind == 2 then
			monId = Class == 7 and 216 or 219

		elseif ClassKind == 5 then
			monId = Gender == 1 and 519 or 633

		elseif ClassKind == 6 or ClassKind == 9 then
			monId = 261

		elseif ClassKind == 8 then
			monId = 585

		elseif ClassKind == 10 then
			monId = 258

		elseif ClassKind == 11 then
			monId = Gender == 1 and 15 or 408

		elseif ClassKind == 14 or ClassKind == 15 then
			monId = Gender == 1 and 420 or 293

		else
			monId = 261

		end
	end

	local monKind = math.floor(monId/3)+1
	Game.HostileTxt[monKind][0] = 0

	Game.HostileTxt[monKind][25]  = 4
	Game.HostileTxt[monKind][150] = 4
	Game.HostileTxt[monKind][217] = 4

	local mon, monId = SummonMonster(monId, -20633, -14746, 4864)
	mon.FullHP = mon.FullHP*5
	mon.HP = mon.FullHP
	mon.NPC_ID = NPCId
	mon.Hostile = false
	mon.Group = 50
	mon.Ally = 9999

	mapvars.FriendMon = monId

	for i = 1, 3 do
		local v
		local NPCId = 772 + i
		local NPC = Game.NPC[NPCId]
		if i < Party.count then
			v = Party[i]
			SplittedNPC[NPCId] = Party.PlayersIndexes[i]
		else
			v = Party.PlayersArray[38+i]
			SplittedNPC[NPCId] = 38+i
			if v.Experience == 100000 and v.LevelBase == 10 then
				GenerateMercenary{RosterId = 38+i, Level = math.max(Party[0].LevelBase + math.random(-5, 8), 1)}
				QSet.FQMercRnd[NPCId] = true
			end
		end

		NPC.Pic = Game.CharacterPortraits[v.Face].NPCPic
		NPC.Name = v.Name
		NPC.Greet = 0

		for i,v in NPC.Events do
			NPC.Events[i] = 0
		end
		NPC.EventA = 1789

		mapvars.Prince = mapvars.Prince or NPCId
		evt.MoveNPC{NPCId, 705 + splitted}
		splitted = splitted + 1
	end

	for i = 1, Party.count-1 do
		DismissCharacter(1)
	end

end

Game.Houses[705].Picture = 389
Game.Houses[705].Name = Game.Houses[222].Name

evt.map[50] = function() -- Ironfist
	evt.EnterHouse{705}
end

Game.Houses[706].Picture = 119
Game.Houses[706].Name = Game.MapStats[52].Name -- "Ogre Fortress"

evt.map[51] = function() -- Ogre Fortress
	evt.EnterHouse{706}
end

Game.Houses[707].Picture = 38
Game.Houses[707].Name = Game.Houses[773].Name

evt.map[52] = function() -- Alvarian merchanthouse
	evt.EnterHouse{707}
end

Game.Houses[710].Picture = 369
Game.Houses[711].Picture = 369

evt.map[53] = function()
	evt.MoveToMap{0,0,0,0,0,0,710,3,"BrBase.blv"}
	QSet.EnteredBasement = false
	evt.MoveToMap{0,0,0,0,0,0,0,0,"BrBase.blv"}
end
evt.map[54] = function()
	evt.MoveToMap{0,0,0,0,0,0,711,2,"BrBase.blv"}
	evt.MoveToMap{0,0,0,0,0,0,0,0,"BrBase.blv"}
end
evt.map[81] = function()
	if QSet.CoughtChaos and NPCFollowers.NPCInGroup(ChaosNPC) then
		Multiplayer.broadcast_mapdata("WinGame")
		evt.MoveToMap{-841,-475,4501,176,0,0,0,0,"Breach.odm"}
		NPCFollowers.Remove(ChaosNPC)
		evt.ForPlayer("All").Add{"Experience", 100000}
	end
end

evt.map[60] = function()
	if not mapvars.SwordsAggro and (mapvars.Prince == nil or Game.NPC[mapvars.Prince].House ~= 705) then
		Message(evt.str[2]) -- 'Someone shouts: "Prince Nicolai have been kidnapped!".'
		evt.SetMonGroupBit{15, const.MonsterBits.Hostile, true}
		mapvars.SwordsAggro = true
	end
end

-----------------------------------

-----------------------------------
-- Catch chaos
-----------------------------------

mapvars.DoorKeys = {}

Game.Houses[712].Name = Game.Houses[1246].Name

-- Closed houses
evt.map[5] = function()
	local DoorKeys = mapvars.DoorKeys

	local ceil = math.ceil
	local Key = ceil(Party.X/500) + ceil(Party.Y/500)
	if not QSet.GotFQHint3 then
		local NPC = Game.NPC[ChaosNPC]
		NPC.Pic = math.random(68,438)
		NPC.Name = Game.NPCNames.M[math.random(1, #Game.NPCNames.M)]
		NPC.Profession = math.random(1, #Game.NPCProfessions-1)
	end

	if not QSet.GotFQHint2 or QSet.CoughtChaos or DoorKeys[Key] then
		local r = math.random(1,3)
		if r == 1 then
			Game.PlaySound(420)
		elseif r == 2 then
			Game.PlaySound(438)
		else
			evt.FaceAnimation{Game.CurrentPlayer, const.FaceAnimation.DoorLocked}
		end
	else
		DoorKeys[Key] = true
		if Game.NPC[ChaosNPC].House ~= 712 then
			evt.MoveNPC{ChaosNPC, 712}
		end
		evt.EnterHouse{712}
	end
end

local function ClearDoorKeys()
	local DoorKeys = mapvars.DoorKeys
	for k,v in pairs(DoorKeys) do
		DoorKeys[k] = false
	end
end

Timer(ClearDoorKeys, const.Hour)

-----------------------------------

-----------------------------------
-- Misc events
-----------------------------------

-- Tavern
evt.map[7] = function()
	evt.EnterHouse{231} -- Troll's Inn
end

-- Special trash heaps
evt.hint[30] = Game.NPCTopic[284]
evt.map[30] = function()
	evt.ForPlayer("Current")
	evt.Add{"Inventory", 315}
	if not evt.Cmp {"RepairSkill", 1} then
		evt.Set{114, 0}
		Game.ShowStatusText(Game.NPCText[726])
	end
end

local function RndJump()
	evt.Jump{math.abs(Party.Direction-2048), math.random(128,256), 1800}
end

-- Jumpers sprites
evt.map[15] = RndJump

-- Jumpers facets
evt.map[16] = RndJump

-- Breach library
mapvars.LibKeys = mapvars.LibKeys or {}
local LibKeys = mapvars.LibKeys
evt.map[82] = function()
	local X,Y,Z = XYZ(Party)
	local ceil = math.ceil
	local key = ceil(X/200) + ceil(Y/200) + ceil(Z/100)

	if LibKeys[key] then
		return
	else
		LibKeys[key] = true
		evt[0].GiveItem{math.random(3,6), math.random(16,17), 0}
	end
end

-- Chests
local function ChestTrap()
	evt.FaceAnimation{Game.CurrentPlayer, const.FaceAnimation.DoorLocked}
end

for i = 1, 15 do
	evt.map[300+i] = ChestTrap
end

-----------------------------------
-- Limit fly spell
-----------------------------------

local CCTimers = {}
local StartFlight
local TimerSet
CCTimers.NoFly = function()
	if Party.Flying then
		local X,Y,Z = XYZ(Party)
		local rnd = math.random
		evt.CastSpell{18, 3, 7,
				rnd(X - 1000, X + 1000),
				rnd(Y - 1000, Y + 1000),
				rnd(Z - 1000, Z + 1000),
				X, Y, Z}
	end
end

CCTimers.ControlTimer = function()
	if Party.Flying then
		local rnd = math.random
		local X,Y,Z = XYZ(Party)
		local rX,rY,rZ = rnd(X - 500, X + 500), rnd(Y - 500, Y + 500), rnd(Z - 200, Z + 200)
		evt.CastSpell{18, 3, 7, rX, rY, rZ, X, Y, Z}
		evt.SummonMonsters{3, 2, 1, rX, rY, rZ, 13}
	end

	if not QSet.EnteredBreach and 2500 > math.sqrt((332-Party.X)^2 + (-268-Party.Y)^2) then
		local rnd = math.random
		Party.X = rnd(3000, 4000)*(rnd(2) == 1 and -1 or 1)
		Party.Y = rnd(3000, 4000)*(rnd(2) == 1 and -1 or 1)
		Game.PlaySound(165)
	end

	local monId = mapvars.FriendMon
	if monId and monId > Map.Monsters.count then
		mapvars.FriendMon = nil
		for i,v in Map.Monsters do
			if v.NPC_ID == 772 then -- 772 is id of NPC used for missed party member.
				mapvars.FriendMon = i
				monId = i
				break
			end
		end
	end

	if monId then
		local mon = Map.Monsters[monId]
		if mon.AIState ~= const.AIState.Removed then
			mon.Hostile = false
			mon.HP = math.min(mon.FullHP, mon.HP+15)
			if mon.AIState == const.AIState.Dead then
				mon.AIState = const.AIState.Stand
			end
		end
	end

end

-----------------------------------
-- Doors
-----------------------------------

for i = 1, 3 do
	CurEvt = IncEvt()
	local CurModel = "Elev_" .. i .. "_Door"
	evt.map[CurEvt] = function()
		if QSet.BrFirstFloor then
			SwitchDoor(CurModel)
		elseif Party.Z >= 1980 then
			evt.SummonMonsters{3, 2, 3, 1343, 763, 1992, 13}
			evt.SummonMonsters{3, 2, 2, -1397, -731, 2071, 13}
			evt.SummonMonsters{3, 2, 2, -1390, 677, 2069, 13}
			evt.SummonMonsters{3, 2, 2, 1354, -646, 2487, 13}
			QSet.BrFirstFloor = true
			SwitchDoor(CurModel)
		else
			Game.ShowStatusText(evt.str[3]) -- "Door won't budge!"
		end
	end

	OutdoorAnimObjects.SetDoor{
		Model = CurModel,
		dx = 0, dy = 0, dz = 250,
		Time = const.Minute,
		Period = StdPeriod,
		EvtId = CurEvt,
		StopSound = 178,
		StartSound = 185,
		Closed		= true,
		Normal 		= false,
		InMove		= false	}
end

for i = 1, 3 do
	CurEvt = IncEvt()
	local CurModel = "SubTower_Door_" .. i
	evt.map[CurEvt] = function()
		if QSet.BrSecFloor then
			SwitchDoor(CurModel)
		elseif Party.Z >= 1990 then
			QSet.BrSecFloor = true
			evt.SummonMonsters{3, 2, 3, 75, -1077, 3126, 13}
			evt.SummonMonsters{3, 2, 3, 1067, -100, 3127, 13}
			evt.SummonMonsters{3, 2, 3, -1025, 647, 3127, 13}
			evt.SummonMonsters{3, 2, 3, 401, 1156, 3127, 13}
			SwitchDoor(CurModel)
		else
			Game.ShowStatusText(evt.str[3]) -- "Door won't budge!"
		end
	end

	OutdoorAnimObjects.SetDoor{
		Model = CurModel,
		dx = 0, dy = 0, dz = 250,
		Time = const.Minute,
		Period = StdPeriod,
		EvtId = CurEvt,
		StopSound = 178,
		StartSound = 185,
		Closed		= true,
		Normal 		= false,
		InMove		= false	}
end

for i = 1, 2 do
	CurEvt = IncEvt()
	local CurModel = "LibDoor_" .. i
	evt.map[CurEvt] = function() SwitchDoor(CurModel) end

	OutdoorAnimObjects.SetDoor{
		Model = CurModel,
		dx = 0, dy = 0, dz = 300,
		Time = const.Minute,
		Period = StdPeriod,
		EvtId = CurEvt,
		StopSound = 168,
		StartSound = 177,
		Closed		= true,
		Normal 		= false,
		InMove		= false	}
end

for i = 3, 4 do
	CurEvt = IncEvt()
	local CurModel = "LibDoor_" .. i
	evt.map[CurEvt] = function()
		if QSet.BrThirdFloor then
			SwitchDoor(CurModel)
		else
			Game.ShowStatusText(evt.str[3]) -- "Door won't budge!"
		end
	end

	OutdoorAnimObjects.SetDoor{
		Model = CurModel,
		dx = 0, dy = 0, dz = 300,
		Time = const.Minute,
		Period = StdPeriod,
		EvtId = CurEvt,
		StopSound = 168,
		StartSound = 177,
		Closed		= true,
		Normal 		= false,
		InMove		= false	}
end

for i = 2, 4 do
	CurEvt = IncEvt()
	local CurModel = "Mus_Door_" .. i
	evt.map[CurEvt] = function() SwitchDoor(CurModel) end

	OutdoorAnimObjects.SetDoor{
		Model = CurModel,
		dx = 0, dy = 0, dz = 300,
		Time = const.Minute,
		Period = StdPeriod,
		EvtId = CurEvt,
		StopSound = 178,
		StartSound = 177,
		Closed		= true,
		Normal 		= false,
		InMove		= false	}
end

CurEvt = IncEvt()
local CurModel = "Mus_Door_1"
evt.map[CurEvt] = function()
	if QSet.BrThirdFloor then
		SwitchDoor(CurModel)
	else
		Game.ShowStatusText(evt.str[3]) -- "Door won't budge!"
	end
end

OutdoorAnimObjects.SetDoor{
	Model = CurModel,
	dx = 0, dy = 0, dz = 300,
	Time = const.Minute,
	Period = StdPeriod,
	EvtId = CurEvt,
	StopSound = 178,
	StartSound = 185,
	Closed		= true,
	Normal 		= false,
	InMove		= false	}

for i = 1, 7 do
	CurEvt = IncEvt()
	local CurModel = "RoomDoor_" .. i
	evt.map[CurEvt] = function() SwitchDoor(CurModel) end

	OutdoorAnimObjects.SetDoor{
		Model	= CurModel,
		dx		= 0, dy = 0, dz = 200,
		Time	= const.Minute/2,
		Period	= StdPeriod,
		EvtId	= CurEvt,
		StopSound = 170,
		Closed		= true,
		Normal 		= false,
		InMove		= false	}
end

CurEvt = IncEvt()
local CurModel = "RoomElev"
evt.map[CurEvt] = function() SwitchDoor(CurModel) end

OutdoorAnimObjects.SetDoor{
		Model	= CurModel,
		dx		= 0, dy = 0, dz = 455,
		Time	= const.Minute*2,
		Period	= StdPeriod,
		EvtId	= CurEvt,
		StopSound = 170,
		StartSound = 177,
		Closed		= true,
		Normal 		= false,
		InMove		= false	}

local function PartyInRadius(R,X,Y)
	return math.sqrt((X-Party.X)^2 + (Y-Party.Y)^2) < R
end

local function JumpToTop(X,Y)
	if PartyInRadius(100,X,Y) then
		local Ff = Party.SpellBuffs[5]
		Ff.ExpireTime = math.max(Ff.ExpireTime, Game.Time + const.Minute*4)
		evt.Jump{0, 512, math.sqrt(2*800*(4410-Party.Z))}
	end
end

local Coords = {10, -2334, 1971, 1139, -1962, 1137}
for i = 1, 3 do
	CurEvt = IncEvt()

	local X,Y = Coords[i*2-1], Coords[i*2]
	local CurModel = "Elev_" .. i .. "_Button"

	evt.map[CurEvt] = function()
		if QSet.BrThirdFloor then
			SwitchDoor(CurModel)
			JumpToTop(X,Y)
		elseif Party.Z >= 3120 then
			evt.SummonMonsters{3, 3, 1, 14, 86, 5184, 13}
			evt.SummonMonsters{3, 2, 4, 14, 86, 5184, 13}
			QSet.BrThirdFloor = true
			SwitchDoor(CurModel)
			JumpToTop(X,Y)
		else
			Game.ShowStatusText(evt.str[4]) -- "Button won't budge."
		end
	end

	OutdoorAnimObjects.SetDoor{
		Model	= CurModel,
		dx 		= 0, dy = 0, dz = 5,
		Time	= const.Minute/4,
		Period	= StdPeriod,
		EvtId	= CurEvt,
		StartSound = 177,
		Closed		= true,
		Normal 		= false,
		InMove		= false}
end

-----------------------------------
-- Map events
-----------------------------------

function events.AfterLoadMap()
	LocalHostileTxt()

	if not QSet.QuestFinished then
		Party.QBits[1715] = true
	end

	Timer(CCTimers.ControlTimer, const.Minute)

	-- Troll - fire element
	Game.HostileTxt[25][150] = 4
	Game.HostileTxt[150][25] = 4

	-- Troll - archer
	Game.HostileTxt[150][159] = 4
	Game.HostileTxt[159][150] = 4

	-- Cactus - archer
	Game.HostileTxt[217][159] = 4
	Game.HostileTxt[159][217] = 4

	-- Swordsman - cactus
	Game.HostileTxt[217][87] = 4
	Game.HostileTxt[87][217] = 4

	-- Swordsman - fire element
	Game.HostileTxt[25][87] = 4
	Game.HostileTxt[87][25] = 4

	-- Fire element - archer
	Game.HostileTxt[25][159] = 4
	Game.HostileTxt[159][25] = 4

	-- Archmage - cactus
	Game.HostileTxt[217][98] = 4
	Game.HostileTxt[98][217] = 1

	-- Golem - cactus
	Game.HostileTxt[217][93] = 4
	Game.HostileTxt[93][217] = 4

	-- Archmage - fire element
	Game.HostileTxt[25][98] = 4
	Game.HostileTxt[98][25] = 1

	-- Golem - fire element
	Game.HostileTxt[25][93] = 4
	Game.HostileTxt[93][25] = 4

	Game.HostileTxt[159][0] = 0
	Game.HostileTxt[25][0] = 4
	Game.HostileTxt[0][25] = 4
	Game.HostileTxt[25][25] = 0

	for i,v in Map.Monsters do
		if v.Id == 294 then
			v.AIType = 1
		end
	end

	if not QSet.BreachSplit then
		SplitParty()
		QSet.BreachSplit = true
	else
		for k,v in pairs(SplittedNPC) do
			Game.NPC[k].Name = Party.PlayersArray[v].Name
		end
	end

	evt.Global[1789] = function()
		local NPCId = GetCurrentNPC()
		local PId = SplittedNPC[NPCId]
		if PId and PId > 0 and PId < 50 then
			HireCharacter(PId)
			evt.MoveNPC{NPCId, 0}
			evt.SetNPCTopic{NPCId, 0, 0}
			if Game.CurrentScreen == 13 then
				ReloadHouse()
			else
				if mapvars.FriendMon then
					Map.Monsters[mapvars.FriendMon].AIState = const.AIState.Removed
					ExitCurrentScreen()

					-- Multiplayer support
					if Multiplayer and Multiplayer.in_game then
						Multiplayer.SyncMonsters.broadcast_full_monster_data(mapvars.FriendMon)
					end
					--
				end
			end
		end
	end

	-- remove excess trash heaps, as they block proper interaction with Dark Dwarf Compound entrance
	Map.Sprites[381].Invisible = true
	Map.Sprites[676].Invisible = true
	Map.Sprites[792].Invisible = true

end

function events.WalkToMap(t)
	local TDir = {up = 1532, down = 500, left = 0, right = 968}
	local A
	A = Party.X < 0 and 1 or -1
	Party.X = Party.X + 100*A
	A = Party.Y < 0 and 1 or -1
	Party.Y = Party.Y + 100*A
	evt.Jump{TDir[t.LeaveSide], math.random(128,256), 2500}
end

function events.CanCastLloyd(t)
	t.Result = false
end

function events.CanCastTownPortal(t)
	TownPortalControls.GenDimDoor()
	TownPortalControls.SwitchTo(4)
end
