
mapvars.AllMercenaries = true -- used by NPCMercenaries.lua
local SwitchDoor = OutdoorAnimObjects.SwitchDoor
local StdPeriod = math.floor(const.Minute/64)
local EvtId = 100
local function IncEvt()
	EvtId = EvtId + 1
	return EvtId
end

evt.map[54] = function()
	evt.MoveToMap{0,0,0,0,0,0,711,2,"BrBase.blv"}
	evt.MoveToMap{0,0,0,0,0,0,0,0,"BrBase.blv"}
end

-- Breach effect
local Delay = 0
evt.map[81] = function()
	if not (Delay > Game.Time) then
		if not mapvars.TelelocatorSet then
			Delay = Game.Time + const.Minute*2
			TownPortalControls.GenDimDoor()
			CastSpellDirect(31, 10, 4)
		else
			local Answer = Question(evt.str[1])
			if string.lower(Answer) == "y" then
				local MapsToStart = {"out01.odm", "7out01.odm", "oute3.odm"}
				evt.Add{"Experience", 0}
				ForceStartNewGame(MapsToStart[math.random(#MapsToStart)], true)
			end
		end
	end
end

-- Telelocator pedestals
local TelelocatorItemId = 666

evt.hint[400] = evt.str[2] -- Pedestal

evt.hint[401] = Game.ItemsTxt[TelelocatorItemId].Name
evt.map[401] = function() Game.ShowStatusText(evt.str[3]) end

evt.hint[402] = evt.str[2] -- Pedestal"
evt.map[402] = function()
	if evt.All.Cmp{"Inventory", TelelocatorItemId} then
		evt.All.Subtract{"Inventory", TelelocatorItemId}
		evt.SetFacetBit{400, const.FacetBits.Invisible, false}
		mapvars.TelelocatorSet = true
		Game.ShowStatusText(evt.str[4]) -- You put your Telelocator into slot.
	elseif not mapvars.TelelocatorSet then
		Game.ShowStatusText(evt.str[5]) -- Slot of this Pedestal is empty.
	end
end

evt.hint[403] = Game.ItemsTxt[TelelocatorItemId].Name
evt.map[403] = function()
	evt[0].Add{"Inventory", TelelocatorItemId}
	evt.SetFacetBit{400, const.FacetBits.Invisible, true}
	mapvars.TelelocatorSet = false
end

function events.AfterLoadMap()
	evt.SetFacetBit{400, const.FacetBits.Invisible, not mapvars.TelelocatorSet}
end

-- Chests
for i = 1, 15 do
	evt.map[300+i] = function()
		evt.OpenChest{i}
	end
end

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

local ControlTimer = function()
	if Party.Z < 500 then
		Party.X = 4
		Party.Y = 34
		Party.Z = 854
		Party.Direction = 1310
		Party.LookAngle = 0
		evt.PlaySound{165}
	end
end

function events.AfterLoadMap()
	local QSet = vars.Quest_CrossContinents
	if QSet and not QSet.QuestFinished then
		QSet.QuestFinished = true
	end

	if QSet and not QSet.GotEndCard then
		QSet.GotEndCard = true
		Game.PrintEndCard(nil, "winbg2.pcx")
	end

	Party.QBits[1713] = false
	Party.QBits[1714] = false
	Party.QBits[1715] = false

	Timer(ControlTimer, const.Minute)
end

function events.WalkToMap(t)
	Party.X = -Party.X
	Party.Y = -Party.Y
end

----- Adventurer's Inn -----
evt.Map[900] = function()
	evt.EnterHouse{1607}
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

function events.SetOutdoorLight(t)
	t.Hour = mapvars.Hour or 4
	t.Minute = mapvars.Minute or t.Minute
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
SwitchDayLight("Time_1", mapvars.DayState or 3)

-----------------------------------
-- Doors
-----------------------------------

for i = 1, 3 do
	CurEvt = IncEvt()
	local CurModel = "Elev_" .. i .. "_Door"
	evt.map[CurEvt] = function() SwitchDoor(CurModel) end

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
	evt.map[CurEvt] = function() SwitchDoor(CurModel) end

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

for i = 1, 4 do
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


for i = 1, 4 do
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
		SwitchDoor(CurModel)
		JumpToTop(X,Y)
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

function events.CanCastTownPortal(t)
	TownPortalControls.GenDimDoor()
	TownPortalControls.SwitchTo(4)
end


-----------------------------------
-- Mercenaries
-----------------------------------

local Spots = {
[1] = {X = -1406,	Y = 292,	Z = 3127},
[2] = {X = 408,		Y = 1311,	Z = 3127},
[3] = {X = 453,		Y = -1478,	Z = 3265},
[4] = {X = -125,	Y = -792,	Z = 3168},
[5] = {X = -2307,	Y = -1447,	Z = 921},
[6] = {X = -466,	Y = -555,	Z = 887},
[7] = {X = 1254,	Y = -314,	Z = 896},
[8] = {X = -1142, 	Y = -1030, 	Z = 2046},
[9] = {X = -2, 		Y = 1119, 	Z = 2508},
[10] = {X = 1345, 	Y = 766, 	Z = 2054},
[11] = {X = 1202, 	Y = -1065, 	Z = 2048}
}

local PortraitApp = {
[0] = 194,
[1] = 255,
[2] = 44,
[3] = 357,
[4] = 368,
[5] = 353,
[6] = 372,
[7] = 377,
[8] = 55,
[9] = 307,
[10] = 293,
[11] = 418,
[12] = 416,
[13] = 307,
[14] = 54,
[15] = 307,
[16] = 27,
[17] = 518,
[18] = 20,
[19] = 24,
[20] = 301,
[21] = 301,
[22] = 58,
[23] = 59,
[24] = 223,
[25] = 225,
[26] = 290,
[27] = 290,
[28] = false,
[29] = false,
[30] = false,
[31] = 517,
[32] = 343,
[33] = 249,
[34] = 637,
[35] = 405,
[36] = 419,
[37] = 459,
[38] = 335,
[39] = 459,
[40] = 336,
[41] = 459,
[42] = 337,
[43] = 459,
[44] = 384,
[45] = 459,
[46] = 459,
[47] = 459,
[48] = 459,
[49] = 261,
[50] = 420,
[51] = 405,
[52] = 419,
[53] = 261,
[54] = 519,
[55] = 271,
[56] = 436,
[57] = 271,
[58] = 437,
[59] = 427,
[60] = 427,
[61] = 231,
[62] = 231,
[63] = 320,
[64] = 319
}

Map.Monsters.count = 0

local MercFriends = {}
for k,v in pairs(vars.MercenariesProps) do
	if v.Hired and not evt.IsPlayerInParty(k) then
		table.insert(MercFriends, k)
		if #MercFriends >= 11 then
			break
		end
	end
end

for k,v in pairs(MercFriends) do
	local Char = Party.PlayersArray[v]
	local Spot = Spots[k]
	local mon = SummonMonster(PortraitApp[Char.Face] or 459, Spot.X, Spot.Y, Spot.Z)

	mon.Hostile = false
	mon.Ally = 9999
	mon.NPC_ID = v + 261
	mon.FullHP = Char:GetFullHP()
	mon.HP = mon.FullHP
	mon.Level = Char.LevelBase
	mon.GuardRadius = 5000
	mon.Gold = 0
	mon.Item = 0

	local cNPC = Game.NPC[mon.NPC_ID]
	cNPC.Name = Char.Name
	cNPC.Pic = Game.CharacterPortraits[Char.Face].NPCPic

	NPCFollowers.ClearEvents(cNPC)
	NPCFollowers.SetJoinEvent(mon.NPC_ID)

end
