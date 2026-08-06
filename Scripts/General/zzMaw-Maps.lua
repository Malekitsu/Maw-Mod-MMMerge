------------------------------
-- RESTORE MM6 sprites
------------------------------

-- Mapping of original sprite names to new sprite names
local spriteMappings = {
    -- ROCKS
    ["rock01"] = "Rok1",
    ["rock02"] = "Rok2",
    ["rock03"] = "Rok3",
    ["rock04"] = "Rok4",
    ["rock05"] = "Rok5",
    ["rock06"] = "Rok6",
    ["rock07"] = "Rok7",
    ["rock08"] = "Rok8",
    ["rock09"] = "Rok9",
    ["rock10"] = "Rok1",
    ["rock11"] = "Rok1",
    ["rock12"] = "Rok1",
    ["rock13"] = "Rok1",
    ["rock14"] = "Rok1",
    
    -- FLOWERS
    ["flower01"] = "6Flower01",
    ["flower02"] = "6Flower02",
    ["flower03"] = "6Flower03",
    ["flower04"] = "6Flower04",
    ["flower05"] = "6Flower05",
    ["flower06"] = "6Flower06",
    ["flower07"] = "6Flower07",
    ["flower08"] = "6Flower08",
    ["flower09"] = "6Flower09",
    ["flower10"] = "6Flower10",
    ["flower11"] = "6Flower11",
    ["flower12"] = "6Flower12",
    ["flower13"] = "6Flower13",
    
    -- CORPSES
    ["Corpse"] = "Corpse01",
    ["Corpse01"] = "Corpse02",
    ["Corpse02"] = "Corpse03",
    ["Corpse03"] = "Corpse04",
    ["Corpse04"] = "Corpse05",
    ["Corpse05"] = "Corpse06",
    ["Corpse06"] = "Corpse07",
    ["Corpse07"] = "Corpse08",
    ["Corpse08"] = "Corpse09",
    ["Corpse09"] = "Corpse10",
    ["Corpse10"] = "Corpse11",
    ["Corpse11"] = "Corpse12",
    ["Corpse12"] = "Corpse13",
    ["Corpse13"] = "Corpse14",
    ["Corpse14"] = "Corpse15",
    ["Corpse15"] = "Corpse16",
    ["Corpse16"] = "Corpse17",
    ["Corpse17"] = "Corpse18",
    ["Corpse18"] = "Corpse19",
    ["Corpse19"] = "Corpse20",
}

function events.AfterLoadMap()
    if Map.MapStatsIndex >= 137 and Map.MapStatsIndex <= 203 then
        for i = 0, Map.Sprites.High do
            local sprite = Map.Sprites[i]
            local newSpriteName = spriteMappings[sprite.DecName]
            if newSpriteName then
                sprite.DecName = newSpriteName
            end
        end
    end
end

--disable respawn in outside maps (mostly)
outSideMaps={1,2,3,4,5,6,7,8,13, 62,63,64,65,66,67,68,69,70,72,73,74,99,100,140,141,143,144,145,146,147,148,149,150,151}
function events.GameInitialized2()
	for i=1,#outSideMaps do
		Game.MapStats[outSideMaps[i]].RefillDays=1000000000
	end
end
function events.BeforeLoadMap()
	if vars.insanityMode then
		for i=1,Game.MapStats.High do
			Game.MapStats[i].RefillDays=1000000000
		end
	end
end
--reset dungeons
--store
function events.GameInitialized2()
	dungeonResetList={}
	for i=1,Game.MapStats.High do
		dungeonResetList[i]=Game.MapStats[i].RefillDays
	end
end

function events.LoadMap()
	if vars.resetDungeon==Map.Name then
		vars.mapResetCount=vars.mapResetCount or {}
		vars.mapResetCount[Map.Name]=vars.mapResetCount[Map.Name] or 0
		vars.mapResetCount[Map.Name]=vars.mapResetCount[Map.Name]+1
	end
end

--restore
function events.AfterLoadMap()
	for i=1,Game.MapStats.High do
		Game.MapStats[i].RefillDays=dungeonResetList[i]
		if vars.insanityMode then
			Game.MapStats[i].RefillDays=1000000000
		end
	end
	vars.dungeonCompletedList=vars.dungeonCompletedList or {}
	for key, value in pairs(vars.dungeonCompletedList) do
		if vars.dungeonCompletedList[key]=="resetting" and vars.resetDungeon==Map.Name then
			vars.dungeonCompletedList[key]="resetted"
		elseif vars.dungeonCompletedList[key]=="resetting" then
			vars.dungeonCompletedList[key]=true
		end
	end
	questionAsked=false
	vars.resetDungeon=false
end

function canResetDungeon(mapFileName)
	if vars.insanityMode then
		return false
	end
	for i=1,Game.MapStats.High do
		if Game.MapStats[i].FileName==mapFileName then
			local name=Game.MapStats[i].Name
			if vars.dungeonCompletedList[name]==true then
				return true
			else
				return false
			end			
		end
	end
end

--used in maps
resetTxt="The dungeon has already been cleared, but you have the option to reset it and attempt it once more with even harder monsters. Please note that no completion rewards will be given for this reset. Would you like to proceed with resetting the dungeon? (yes/no)"
local possibleAnswers={"yes", "Yes", "YES", " yes", " Yes", " YES"} 
--Offers the reset prompt the first time a cleared dungeon is entered.
--Returns true when it took over the entrance: the caller must not move.
function tryResetDungeon(dungeonId)
	--the guard once carried "and not vars.onlineMode" as well:
	--if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked and not vars.onlineMode then
	if not canResetDungeon(dungeonId) or vars.resetDungeon or questionAsked then
		return false
	end
	local answer=Question(resetTxt)
	questionAsked=true
	if table.find(possibleAnswers, answer) then 
		vars.resetDungeon=dungeonId
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].FileName==vars.resetDungeon then
				vars.dungeonCompletedList[Game.MapStats[i].Name]="resetting"
				Game.MapStats[i].RefillDays=0
				Game.ShowStatusText("Entering will reset the dungeon")
			end
		end
	end
	return true
end

function resetMap(dungeonId)
	tryResetDungeon(dungeonId)
end

--One dungeon entrance: drop the map's own event, restore its label, and
--install a handler that offers the reset prompt before moving the party.
--`label` is {hint = <evt.str id>} or {house = <house id>}, omitted when the
--event carries neither. Shaped after MMExtension's own evt.HouseDoor.
function addDungeonEntrance(eventId, dungeonId, moveArgs, label)
	Game.MapEvtLines:RemoveEvent(eventId)
	if label and label.hint then
		evt.hint[eventId] = evt.str[label.hint]
	elseif label and label.house then
		evt.house[eventId] = label.house
	end
	evt.map[eventId] = function()
		if tryResetDungeon(dungeonId) then return end
		evt.MoveToMap(moveArgs)
	end
end

--barrels fix
local stats={"MightBase", "IntellectBase", "PersonalityBase", "EnduranceBase", "AccuracyBase", "SpeedBase", "LuckBase", "LuckBase", "LuckBase", "LuckBase", "LuckBase", "FireResistanceBase", "AirResistanceBase", "WaterResistanceBase", "EarthResistanceBase", "MindResistanceBase", "BodyResistanceBase", }
function events.EvtMap(evtId)
	if evtId>=20000 then
		previousStats=previousStats or {}
		local event=evtId
		RunNextTick(function()
			k=0
			found=false
			for i=0, Party.High do
				for j=1, #stats do
					k=k+1
					if previousStats[k]~=Party[i][stats[j]] then
						found=true
						previousStats[k]=Party[i][stats[j]]
					end
				end
			end
			if found then
				vars.usedBarrels=vars.usedBarrels or {}
				vars.usedBarrels[Map.Name]=vars.usedBarrels[Map.Name] or {}
				table.insert(vars.usedBarrels[Map.Name], event)
			end
		end)
	end
end
function events.AfterLoadMap()
	previousStats=previousStats or {}
	local k=0
	for i=0, Party.High do
		for j=1, #stats do
			k=k+1
			previousStats[k]=Party[i][stats[j]]
		end
	end
	if vars.usedBarrels and vars.usedBarrels[Map.Name] then
		for i=0, Map.Sprites.High do
			if table.find(vars.usedBarrels[Map.Name], Map.Sprites[i].Event) then
				Map.Sprites[i].Event=19999
			end
		end
		evt.hint[19999] = "Empty Barrel"
	end	
end
--dungeon reset
function events.AfterLoadMap()
	-------------------------
	--MM8
	-------------------------
	--Daggerwound Island
	if Map.Name=="out01.odm" then
		addDungeonEntrance(501, "d05.blv", {X = -3008, Y = -1696, Z = 2464, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 346, Icon = 1, Name = "d05.blv"}, {hint = 50})         -- "Abandoned Temple"

		addDungeonEntrance(502, "d06.blv", {X = -7, Y = -714, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 349, Icon = 1, Name = "d06.blv"}, {hint = 51})         -- "Pirate Outpost"

		addDungeonEntrance(503, "d40.blv", {X = -592, Y = 624, Z = 0, Direction = 552, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d40.blv"}, {hint = 52})  -- "Enter the Uplifted Library"

		addDungeonEntrance(504, "d05.blv", {X = 12704, Y = 2432, Z = 385, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 345, Icon = 1, Name = "d05.blv"}, {hint = 50})         -- "Backdoor of Abandoned Temple"

		addDungeonEntrance(505, "eleme.blv", {X = 0, Y = 0, Z = 49, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 352, Icon = 1, Name = "eleme.blv"}, {hint = 53})         -- "Gateway to the Plane of Earth"
	end
	
	--Ravenshore
	if Map.Name=="out02.odm" then
		addDungeonEntrance(501, "d07.blv", {X = -3800, Y = 623, Z = 1, Direction = 2000, LookAngle = 0, SpeedZ = 0, HouseId = 351, Icon = 1, Name = "d07.blv"}, {hint = 50})         -- "Smuggler's Cove"

		addDungeonEntrance(502, "d08.blv", {X = 2157, Y = 1003, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 353, Icon = 1, Name = "d08.blv"}, {hint = 51})         -- "Dire Wolf Den"

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[53]  -- "Enter Escaton's Crystal"
		evt.map[504] = function()
			local dungeonId="d10.blv"
			if tryResetDungeon(dungeonId) then return end
			evt.ForPlayer("All")
			if evt.Cmp{"Inventory", Value = 610} then         -- "Conflux Key"
				evt.MoveToMap{X = -1024, Y = -1626, Z = 0, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 355, Icon = 1, Name = "d10.blv"}         -- "Inside the Crystal"
			else
				evt.FaceAnimation{Player = "Current", Animation = 18}
			end
		end

		addDungeonEntrance(507, "d45.blv", {X = -481, Y = -2824, Z = 321, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d45.blv"}, {hint = 44})  -- "Enter the Chapel of Eep"
	end
	
	--Alvar
	if Map.Name=="out03.odm" then
		addDungeonEntrance(501, "d11.blv", {X = -2192, Y = -1840, Z = -127, Direction = 33, LookAngle = 0, SpeedZ = 0, HouseId = 356, Icon = 1, Name = "d11.blv"}, {hint = 50})         -- "Wasp Nest"

		addDungeonEntrance(502, "d12.blv", {X = -3424, Y = 32, Z = 0, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 357, Icon = 1, Name = "d12.blv"}, {hint = 51})         -- "Ogre Raiding Fort"

		addDungeonEntrance(503, "d41.blv", {X = -10528, Y = -352, Z = -896, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d41.blv"}, {hint = 52})  -- "Enter the Dark Dwarf Compound"

		addDungeonEntrance(504, "d11.blv", {X = 301, Y = 2162, Z = 513, Direction = 161, LookAngle = 0, SpeedZ = 0, HouseId = 356, Icon = 1, Name = "d11.blv"}, {hint = 50})         -- "Wasp Nest"
	end
	
	--Ironsand Desert
	if Map.Name=="out04.odm" then
		addDungeonEntrance(501, "d13.blv", {X = -672, Y = 768, Z = -28, Direction = 256, LookAngle = 0, SpeedZ = 0, HouseId = 358, Icon = 1, Name = "d13.blv"}, {hint = 50})         -- "Troll Tomb"

		addDungeonEntrance(502, "d14.blv", {X = 0, Y = 0, Z = 1, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 359, Icon = 1, Name = "d14.blv"}, {hint = 51})         -- "Cyclops Larder"

		addDungeonEntrance(503, "d15.blv", {X = -288, Y = -768, Z = 0, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 360, Icon = 1, Name = "d15.blv"}, {hint = 52})         -- "Chain of Fire"

		addDungeonEntrance(505, "d15.blv", {X = -12423, Y = 4347, Z = -135, Direction = 1544, LookAngle = 0, SpeedZ = 0, HouseId = 360, Icon = 1, Name = "d15.blv"}, {hint = 52})         -- "Chain of Fire"

		addDungeonEntrance(506, "d48.blv", {X = 2116, Y = 9631, Z = 1, Direction = 1296, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 3, Name = "d48.blv"}, {hint = 53})  -- "Enter the Cave"
	end
	
	--Garrote Gorge
	if Map.Name=="out05.odm" then
		addDungeonEntrance(501, "d16.blv", {X = -1216, Y = 1888, Z = 1, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 361, Icon = 1, Name = "d16.blv"}, {hint = 50})         -- "Dragon Hunter Camp"
		
		addDungeonEntrance(502, "d17.blv", {X = 223, Y = -8, Z = 170, Direction = 1088, LookAngle = 0, SpeedZ = 0, HouseId = 362, Icon = 1, Name = "d17.blv"}, {hint = 51})         -- "Dragon Cave"
		
		addDungeonEntrance(503, "d18.blv", {X = -500, Y = -1567, Z = -63, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 363, Icon = 1, Name = "d18.blv"}, {hint = 52})         -- "Naga Vault"
		
		addDungeonEntrance(504, "d44.blv", {X = -2812, Y = 726, Z = 1, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d44.blv"}, {hint = 53})  -- "Enter the Grand Temple of Eep"
	end
	
	if Map.Name=="out06.odm" then
		addDungeonEntrance(501, "d19.blv", {X = 0, Y = 64, Z = 0, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 371, Icon = 1, Name = "d19.blv"}, {hint = 50})         -- "Necromancers' Guild"

		addDungeonEntrance(502, "d20.blv", {X = -900, Y = -127, Z = 1, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 372, Icon = 1, Name = "d20.blv"}, {hint = 51})         -- "Mad Necromancer's Lab"

		addDungeonEntrance(503, "d21.blv", {X = -457, Y = -1749, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d21.blv"}, {hint = 53})  -- "Enter the Vampire Crypt"

		addDungeonEntrance(504, "d49.blv", {X = 9690, Y = 1334, Z = 1176, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 3, Name = "d49.blv"}, {hint = 52})  -- "Enter the Cave"
	end
	
	--Murmurwoods
	if Map.Name=="out07.odm" then
		addDungeonEntrance(501, "d22.blv", {X = -768, Y = -768, Z = 96, Direction = 280, LookAngle = 0, SpeedZ = 0, HouseId = 364, Icon = 1, Name = "d22.blv"}, {hint = 50})         -- "Temple of the Sun"

		addDungeonEntrance(502, "d23.blv", {X = 235, Y = 2980, Z = 673, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 365, Icon = 3, Name = "d23.blv"}, {hint = 51})         -- "Abandoned Druid Circle"

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[52]  -- "Enter the Ancient Troll Home"
		evt.map[504] = function()
			local dungeonId="d43.blv"
			if tryResetDungeon(dungeonId) then return end
			if not evt.Cmp{"QBits", Value = 69} then         -- Ancient Troll Homeland Found
				evt.Set{"QBits", Value = 69}         -- Ancient Troll Homeland Found
			end
			evt.MoveToMap{X = 448, Y = -224, Z = 0, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d43.blv"}
		end
	end
	
	--ravage roaming
	if Map.Name=="out08.odm" then
		addDungeonEntrance(501, "d24.blv", {X = 1, Y = -100, Z = -85, Direction = 1540, LookAngle = 0, SpeedZ = 0, HouseId = 366, Icon = 1, Name = "d24.blv"}, {hint = 50})         -- "Minotaur Lair"

		addDungeonEntrance(502, "d25.blv", {X = -2284, Y = 1847, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 367, Icon = 1, Name = "d25.blv"}, {hint = 51})         -- "Barbarian Fortress"

		addDungeonEntrance(503, "d26.blv", {X = -4436, Y = -6538, Z = 317, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d26.blv"}, {hint = 52})  -- "Enter the Crypt of Korbu"

		addDungeonEntrance(504, "d24.blv", {X = 832, Y = 849, Z = 44, Direction = 1548, LookAngle = 0, SpeedZ = 0, HouseId = 344, Icon = 1, Name = "d24.blv"}, {hint = 50})         -- "Balthazar Lair"

		addDungeonEntrance(505, "d25.blv", {X = 614, Y = 1858, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 367, Icon = 1, Name = "d25.blv"}, {hint = 51})         -- "Barbarian Fortress"

		addDungeonEntrance(506, "d25.blv", {X = 628, Y = -1274, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 367, Icon = 1, Name = "d25.blv"}, {hint = 51})         -- "Barbarian Fortress"

		addDungeonEntrance(507, "d25.blv", {X = -2284, Y = -1353, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 367, Icon = 1, Name = "d25.blv"}, {hint = 51})         -- "Barbarian Fortress"
		
		addDungeonEntrance(509, "d46.blv", {X = -21, Y = 5, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d46.blv"}, {hint = 53})  -- "Enter the Church of Eep"
	end
	
	--Regna
	if Map.Name=="out13.odm" then
		addDungeonEntrance(501, "d31.blv", {X = -554, Y = 3682, Z = 1, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 368, Icon = 1, Name = "d31.blv"}, {hint = 50})         -- "Pirate Stronghold"

		addDungeonEntrance(502, "d32.blv", {X = -6520, Y = -6512, Z = 129, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 369, Icon = 1, Name = "d32.blv"}, {hint = 51})         -- "Abandoned Pirate Keep"

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[44]  -- "Enter the Tower"
		evt.map[503] = function()
			if evt.Cmp{"QBits", Value = 197} then         -- Door to the passage under regna from the northern watch tower is unlocked
				local dungeonId="d33.blv"
				if tryResetDungeon(dungeonId) then return end
				evt.MoveToMap{X = 5892, Y = 4632, Z = 1853, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d33.blv"}
			else
				evt.FaceAnimation{Player = "Current", Animation = 18}
			end
		end

		addDungeonEntrance(504, "d34.blv", {X = -28, Y = -193, Z = 57, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 370, Icon = 3, Name = "d34.blv"}, {hint = 54})         -- "Small Sub Pen"

		addDungeonEntrance(505, "d47.blv", {X = 1328, Y = -1576, Z = 4, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d47.blv"}, {hint = 54})  -- "Enter the Cave"

		Game.MapEvtLines:RemoveEvent(506)
		evt.hint[506] = evt.str[44]  -- "Enter the Tower"
		evt.map[506] = function()
			if evt.Cmp{"QBits", Value = 198} then         -- Door to the passage under regna from the southern watch tower is unlocked
				local dungeonId="d33.blv"
				if tryResetDungeon(dungeonId) then return end
				evt.MoveToMap{X = 1926, Y = -7682, Z = 1572, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d33.blv"}
			else
				evt.FaceAnimation{Player = "Current", Animation = 18}
			end
		end
	end
	
	
	-------------------------
	--MM7
	-------------------------
	--Evenmorn Island
	if Map.Name=="out09.odm" then
		addDungeonEntrance(501, "7d19.blv", {X = 3136, Y = 2053, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 404, Icon = 1, Name = "7d19.blv"}, {hint = 30})         -- "Grand Temple of the Moon"

		addDungeonEntrance(502, "t03.blv", {X = 0, Y = -3179, Z = 161, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 405, Icon = 1, Name = "t03.blv"}, {hint = 31})         -- "Grand Temple of the Sun"
	end
	
	--Mount Nighon
	if Map.Name=="out10.odm" then
		addDungeonEntrance(501, "7d07.blv", {X = -1024, Y = 768, Z = 4097, Direction = 1792, LookAngle = 0, SpeedZ = 0, HouseId = 406, Icon = 9, Name = "7d07.blv"}, {hint = 30})         -- "Thunderfist Mountain"

		addDungeonEntrance(502, "d02.blv", {X = 1536, Y = -8614, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 407, Icon = 2, Name = "d02.blv"}, {hint = 31})         -- "The Maze"

		addDungeonEntrance(503, "7d07.blv", {X = 9960, Y = 1443, Z = 390, Direction = 1936, LookAngle = 0, SpeedZ = 0, HouseId = 406, Icon = 9, Name = "7d07.blv"}, {hint = 30})         -- "Thunderfist Mountain"

		addDungeonEntrance(504, "7d07.blv", {X = -11058, Y = 4858, Z = 3969, Direction = 148, LookAngle = 0, SpeedZ = 0, HouseId = 406, Icon = 9, Name = "7d07.blv"}, {hint = 30})         -- "Thunderfist Mountain"
		
		addDungeonEntrance(505, "7d07.blv", {X = 11471, Y = -3498, Z = 2814, Direction = 414, LookAngle = 0, SpeedZ = 0, HouseId = 406, Icon = 9, Name = "7d07.blv"}, {hint = 30})         -- "Thunderfist Mountain"
	end
	
	--Dwarven Barrows
	if Map.Name=="out11.odm" then
		addDungeonEntrance(501, "7d24.blv", {X = 245, Y = -5362, Z = 34, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 408, Icon = 2, Name = "7d24.blv"}, {hint = 30})         -- "Stone City"

		addDungeonEntrance(502, "7d37.blv", {X = 2, Y = -1096, Z = -31, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 9, Name = "7d37.blv"}, {hint = 32})  -- "Enter Mansion"

		addDungeonEntrance(503, "mdt01.blv", {X = 382, Y = 324, Z = -15, Direction = 1280, LookAngle = 0, SpeedZ = 0, HouseId = 1085, Icon = 2, Name = "mdt01.blv"}, {hint = 31})         -- ""

		addDungeonEntrance(504, "mdr01.blv", {X = 106, Y = -666, Z = 49, Direction = 256, LookAngle = 0, SpeedZ = 0, HouseId = 1085, Icon = 2, Name = "mdr01.blv"}, {hint = 31})         -- ""
		
		addDungeonEntrance(505, "mdr01.blv", {X = -384, Y = -983, Z = 1, Direction = 256, LookAngle = 0, SpeedZ = 0, HouseId = 1085, Icon = 2, Name = "mdr01.blv"}, {hint = 31})         -- "Arbiter"
	end
	
	--The Land of the Giants
	if Map.Name=="out12.odm" then
		addDungeonEntrance(501, "7d27.blv", {X = 2648, Y = -1372, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 409, Icon = 3, Name = "7d27.blv"}, {hint = 30})         -- "Colony Zod"

		addDungeonEntrance(502, "7d36.blv", {X = 9165, Y = 15139, Z = -583, Direction = 24, LookAngle = 0, SpeedZ = 0, HouseId = 48, Icon = 3, Name = "7d36.blv"}, {hint = 31})         -- "Tunnels to Eeofol"

		addDungeonEntrance(503, "mdt12.blv", {X = -54, Y = 3470, Z = 1, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 3, Name = "mdt12.blv"}, {hint = 32})  -- "Enter the Cave"

		addDungeonEntrance(504, "mdt12.blv", {X = 19341, Y = 21323, Z = 1, Direction = 256, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 3, Name = "mdt12.blv"}, {hint = 32})  -- "Enter the Cave"
	end
	
	--Avlee
	if Map.Name=="out14.odm" then
		addDungeonEntrance(501, "7d09.blv", {X = -1707, Y = -21848, Z = -1007, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 413, Icon = 9, Name = "7d09.blv"}, {hint = 30})         -- "Titan's Stronghold"

		addDungeonEntrance(502, "d04.blv", {X = 1, Y = -2772, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 414, Icon = 9, Name = "d04.blv"}, {hint = 31})         -- "Temple of Baa"

		addDungeonEntrance(503, "D22.blv", {X = -1114, Y = 2778, Z = 1, Direction = 1280, LookAngle = 0, SpeedZ = 0, HouseId = 415, Icon = 3, Name = "7D22.blv"}, {hint = 32})         -- "Hall under the Hill"
	end
	
	--Emeralnd Island
	if Map.Name=="7out01.odm" then
		addDungeonEntrance(101, "7d06.blv", {X = -1208, Y = -4225, Z = 366, Direction = 320, LookAngle = 0, SpeedZ = 0, HouseId = 387, Icon = 3, Name = "7d06.blv"}, {hint = 30})         -- "Temple of the Moon"
	end
	
	--Harmondale
	if Map.Name=="7out02.odm" then
		addDungeonEntrance(302, "7d21.blv", {X = 1344, Y = -256, Z = -107, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 391, Icon = 3, Name = "7d21.blv"}, {hint = 31})         -- "White Cliff Cave"
	end
	
	--Erathia
	if Map.Name=="7out03.odm" then
		addDungeonEntrance(501, "d01.blv", {X = 28, Y = -217, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 392, Icon = 5, Name = "d01.blv"}, {hint = 30})         -- "Erathian Sewer"

		addDungeonEntrance(502, "7d31.blv", {X = 64, Y = -448, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 393, Icon = 9, Name = "7d31.blv"}, {hint = 32})         -- "Fort Riverstride"

		addDungeonEntrance(503, "7d33.blv", {X = 768, Y = 0, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 383, Icon = 9, Name = "7d33.blv"}, {hint = 31})         -- "Castle Gryphonheart"

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[20]  -- "Door"
		evt.map[504] = function()
			local dungeonId="7d33.blv"
			if tryResetDungeon(dungeonId) then return end
			if evt.Cmp{"Inventory", Value = 1462} then         -- "Catherine's Key"
				evt.MoveToMap{X = -6314, Y = -618, Z = 1873, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 383, Icon = 9, Name = "7d33.blv"}         -- "Castle Gryphonheart"
			else
				evt.StatusText{Str = 21}         -- "This Door is Locked"
				evt.FaceAnimation{Player = 4, Animation = 18}
			end
		end

		addDungeonEntrance(505, "7d31.blv", {X = -1262, Y = 587, Z = -1215, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 393, Icon = 9, Name = "7d31.blv"}, {hint = 32})         -- "Fort Riverstride"

		addDungeonEntrance(506, "d01.blv", {X = 6647, Y = 3511, Z = -511, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 392, Icon = 5, Name = "d01.blv"}, {hint = 30})         -- "Erathian Sewer"

		addDungeonEntrance(507, "d01.blv", {X = -6507, Y = 10205, Z = -383, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 392, Icon = 5, Name = "d01.blv"}, {hint = 30})         -- "Erathian Sewer"

		addDungeonEntrance(508, "mdt11.blv", {X = -111, Y = -25, Z = 1, Direction = 640, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 2, Name = "mdt11.blv"}, {hint = 33})  -- "Enter"

		addDungeonEntrance(509, "mdt14.blv", {X = -104, Y = 128, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 3, Name = "mdt14.blv"}, {hint = 33})  -- "Enter"
	end
	
	--Tularean Forest
	if Map.Name=="7out04.odm" then
		addDungeonEntrance(501, "7d32.blv", {X = 0, Y = -1589, Z = 225, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 384, Icon = 1, Name = "7d32.blv"}, {hint = 30})         -- "Castle Navan"

		addDungeonEntrance(502, "7d08.blv", {X = 2071, Y = 448, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 394, Icon = 3, Name = "7d08.blv"}, {hint = 31})         -- "Tularean Caves"

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[32]  -- "Enter Clanker's Laboratory"
		evt.map[503] = function()
			if not evt.Cmp{"QBits", Value = 710} then         -- Archibald in Clankers Lab now
				local dungeonId="7d12.blv"
				if tryResetDungeon(dungeonId) then return end
				evt.MoveToMap{X = 0, Y = -709, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 395, Icon = 9, Name = "7d12.blv"}         -- "Clanker's Laboratory"
			end
			evt.SpeakNPC{NPC = 427}         -- "Archibald Ironfist"
		end
	end
	
	--Deija
	if Map.Name=="7out05.odm" then
		addDungeonEntrance(501, "t04.blv", {X = 512, Y = -3156, Z = 1, Direction = 545, LookAngle = 0, SpeedZ = 0, HouseId = 396, Icon = 2, Name = "t04.blv"}, {hint = 30})         -- "Hall of the Pit"

		addDungeonEntrance(502, "7d15.blv", {X = -416, Y = -1033, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 397, Icon = 9, Name = "7d15.blv"}, {hint = 31})         -- "Watchtower 6"

		Game.MapEvtLines:RemoveEvent(503)
		evt.map[503] = function()
			if evt.Cmp{"QBits", Value = 611} then         -- Chose the path of Light
				local dungeonId="mdt10.blv"
				if tryResetDungeon(dungeonId) then return end
				evt.MoveToMap{X = 442, Y = -1112, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 9, Name = "mdt10.blv"}
			else
				evt.SpeakNPC{NPC = 357}         -- "William Setag"
			end
		end
	end
	
	--Bracada Desert
	if Map.Name=="7out06.odm" then
		addDungeonEntrance(501, "7d14.blv", {X = 2, Y = -1341, Z = -159, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 398, Icon = 9, Name = "7d14.blv"}, {hint = 30})         -- "School of Sorcery"

		addDungeonEntrance(502, "7d34.blv", {X = 26, Y = 6, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 399, Icon = 3, Name = "7d34.blv"}, {hint = 31})         -- "Red Dwarf Mines"
	end
	
	--Tatalia
	if Map.Name=="7out13.odm" then
		addDungeonEntrance(501, "7d16.blv", {X = 601, Y = -512, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 412, Icon = 2, Name = "7d16.blv"}, {hint = 30})         -- "Wine Cellar"

		addDungeonEntrance(503, "7d17.blv", {X = -1944, Y = -2052, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 411, Icon = 9, Name = "7d17.blv"}, {hint = 32})         -- "Tidewater Caverns"
	end
	
	--Shoals
	if Map.Name=="7out15.odm" then
		addDungeonEntrance(501, "7d23.blv", {X = 524, Y = 1463, Z = 225, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 416, Icon = 9, Name = "7d23.blv"}, {hint = 30})         -- "The Lincoln"
	end	
	
	
	-------------------------
	--MM6
	-------------------------
	--Sweet Water
	if Map.Name=="outa1.odm" then
		addDungeonEntrance(90, "hive.blv", {X = 435, Y = 3707, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 421, Icon = 5, Name = "hive.blv"}, {house = 421})         -- "The Hive"
	end
	
	--Hermit's Isle
	if Map.Name=="outa3.odm" then
		addDungeonEntrance(90, "6t6.blv", {X = -2048, Y = 3453, Z = 2049, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 433, Icon = 5, Name = "6t6.blv"})         -- "Supreme Temple of Baa"
	end
	
	--Kriegspire
	if Map.Name=="outb1.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.map[90] = function()
			evt.ForPlayer("All")
			if evt.Cmp{"Inventory", Value = 2105} then         -- "Cloak of Baa"
			local dungeonId="6t7.blv"
				if tryResetDungeon(dungeonId) then return end
				evt.MoveToMap{X = 2094, Y = -19, Z = 177, Direction = 337, LookAngle = 0, SpeedZ = 0, HouseId = 435, Icon = 5, Name = "6t7.blv"}         -- "Superior Temple of Baa"
			else
				evt.StatusText{Str = 12}         -- "You are not a follower of Baa.  Begone!"
			end
		end

		addDungeonEntrance(91, "6d19.blv", {X = 2702, Y = -2926, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 448, Icon = 5, Name = "6d19.blv"})         -- "Agar's Laboratory"

		addDungeonEntrance(92, "6d20.blv", {X = -49, Y = -42, Z = -2, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 449, Icon = 5, Name = "6d20.blv"})         -- "Caves of the Dragon Riders"

		addDungeonEntrance(93, "cd3.blv", {X = 5861, Y = 2720, Z = 169, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 427, Icon = 5, Name = "cd3.blv"})         -- "Castle Kriegspire"

		addDungeonEntrance(94, "zdwj02.blv", {X = 1893, Y = 122, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 5, Name = "zdwj02.blv"}, {hint = 1})  -- "Demon Lair"

		Game.MapEvtLines:RemoveEvent(100)
		evt.hint[100] = evt.str[2]  -- "Drink from Well."
		evt.map[100] = function()
			local dungeonId="cd3.blv"
			if tryResetDungeon(dungeonId) then return end
			evt.StatusText{Str = 3}         -- "You feel Strange."
			evt.MoveToMap{X = 12768, Y = 4192, Z = 512, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 0, Name = "cd3.blv"}
		end
	end
	
	--Blackshire
	if Map.Name=="outb2.odm" then
		addDungeonEntrance(90, "6t8.blv", {X = -4158, Y = 1792, Z = 1233, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 437, Icon = 5, Name = "6t8.blv"})         -- "Temple of the Snake"

		addDungeonEntrance(91, "6d17.blv", {X = -9600, Y = 22127, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 446, Icon = 5, Name = "6d17.blv"})         -- "Lair of the Wolf"
	end
	
	--Dragonsand
	if Map.Name=="outb3.odm" then
		addDungeonEntrance(90, "pyramid.blv", {X = -9734, Y = -19201, Z = 772, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 420, Icon = 5, Name = "pyramid.blv"})         -- "Tomb of VARN"
	end
	
	--Frozen Highlands
	if Map.Name=="outc1.odm" then
		addDungeonEntrance(90, "6d08.blv", {X = 1408, Y = -1664, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 436, Icon = 5, Name = "6d08.blv"})         -- "Shadow Guild"

		addDungeonEntrance(91, "6d15.blv", {X = -495, Y = -219, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 444, Icon = 5, Name = "6d15.blv"})         -- "Icewind Keep"
	end
	
	--Free Haven
	if Map.Name=="outc2.odm" then
		addDungeonEntrance(150, "6d10.blv", {X = -2, Y = -128, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 439, Icon = 5, Name = "6d10.blv"})         -- "Dragoons' Keep"

		addDungeonEntrance(151, "6d14.blv", {X = -118, Y = -1640, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 443, Icon = 5, Name = "6d14.blv"})         -- "Tomb of Ethric the Mad"

		addDungeonEntrance(152, "6t5.blv", {X = 0, Y = -2135, Z = 125, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 431, Icon = 5, Name = "6t5.blv"})         -- "Temple of the Moon"
	end
	
	--Mire of the Damned
	if Map.Name=="outc3.odm" then
		addDungeonEntrance(90, "6d09.blv", {X = -3714, Y = 1250, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 438, Icon = 5, Name = "6d09.blv"})         -- "Snergle's Iron Mines"

		addDungeonEntrance(91, "cd2.blv", {X = 21169, Y = 1920, Z = -689, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 424, Icon = 5, Name = "cd2.blv"})         -- "Castle Darkmoor"

		addDungeonEntrance(93, "zddb01.blv", {X = -622, Y = 239, Z = 1, Direction = 128, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 5, Name = "zddb01.blv"}, {hint = 2})  -- "Dragon's Lair"
	end
	
	--Silver Cove
	if Map.Name=="outd1.odm" then
		addDungeonEntrance(150, "6d12.blv", {X = -127, Y = 4190, Z = 1, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 441, Icon = 5, Name = "6d12.blv"})         -- "Silver Helm Stronghold"

		addDungeonEntrance(151, "6d13.blv", {X = -128, Y = -3968, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 442, Icon = 5, Name = "6d13.blv"})         -- "The Monolith"

		addDungeonEntrance(152, "6d16.blv", {X = -4724, Y = 1494, Z = 127, Direction = 1920, LookAngle = 0, SpeedZ = 0, HouseId = 445, Icon = 5, Name = "6d16.blv"})         -- "Warlord's Fortress"
	end
	
	--Bootleg Bay
	if Map.Name=="outd2.odm" then
		addDungeonEntrance(90, "6d04.blv", {X = -1792, Y = -19, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 428, Icon = 5, Name = "6d04.blv"})         -- "Hall of the Fire Lord"

		addDungeonEntrance(91, "6t2.blv", {X = 0, Y = -2231, Z = 513, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 423, Icon = 5, Name = "6t2.blv"}, {house = 423})         -- "Temple of the Fist"

		addDungeonEntrance(92, "6t4.blv", {X = -3258, Y = 483, Z = 49, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 429, Icon = 5, Name = "6t4.blv"}, {house = 429})         -- "Temple of the Sun"

		addDungeonEntrance(93, "6t3.blv", {X = 2817, Y = -4748, Z = -639, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 426, Icon = 5, Name = "6t3.blv"}, {house = 426})         -- "Temple of Tsantsa"
	end
	
	--Castle Ironfist
	if Map.Name=="outd3.odm" then
		addDungeonEntrance(90, "6d03.blv", {X = -130, Y = -1408, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 425, Icon = 5, Name = "6d03.blv"})         -- "Shadow Guild Hideout"

		addDungeonEntrance(91, "6d05.blv", {X = 1664, Y = -1896, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 430, Icon = 5, Name = "6d05.blv"})         -- "Snergle's Caverns"

		addDungeonEntrance(92, "6d06.blv", {X = 2716, Y = -256, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 432, Icon = 5, Name = "6d06.blv"})         -- "Dragoons' Caverns"

		addDungeonEntrance(93, "6d11.blv", {X = 128, Y = -151, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 440, Icon = 5, Name = "6d11.blv"})         -- "Corlagon's Estate"

		addDungeonEntrance(94, "6t1.blv", {X = -15592, Y = 120, Z = -191, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 418, Icon = 5, Name = "6t1.blv"})         -- "Temple of Baa"
	end
	
	--Eel Infested Waters
	if Map.Name=="oute1.odm" then
		addDungeonEntrance(90, "cd1.blv", {X = -2921, Y = 13139, Z = 225, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 419, Icon = 5, Name = "cd1.blv"})         -- "Castle Alamos"
	end
	
	--Misty Islands
	if Map.Name=="oute2.odm" then
		addDungeonEntrance(90, "6d07.blv", {X = 4427, Y = 3061, Z = 769, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 434, Icon = 5, Name = "6d07.blv"})         -- "Silver Helm Outpost"
	end
	
	--New Sorpigal
	if Map.Name=="oute3.odm" then
		Game.MapEvtLines:RemoveEvent(101)
		evt.map[101] = function()
			if not evt.Cmp{"QBits", Value = 1324} then         -- Peter
				evt.ForPlayer("All")
				if not evt.Cmp{"Inventory", Value = 2109} then         -- "Key to Goblinwatch"
					evt.StatusText{Str = 18}         -- "The door is locked."
					return
				end
				evt.Subtract{"Inventory", Value = 2109}         -- "Key to Goblinwatch"
				evt.Set{"QBits", Value = 1324}         -- Peter
			end
			local dungeonId="6d01.blv"
			if tryResetDungeon(dungeonId) then return end
			evt.MoveToMap{X = 601, Y = 6871, Z = 177, Direction = 1400, LookAngle = 0, SpeedZ = 0, HouseId = 417, Icon = 5, Name = "6d01.blv"}         -- "Goblinwatch"
		end

		addDungeonEntrance(102, "6d02.blv", {X = 16406, Y = -19669, Z = 865, Direction = 500, LookAngle = 0, SpeedZ = 0, HouseId = 422, Icon = 1, Name = "6d02.blv"})         -- "Abandoned Temple"

		addDungeonEntrance(103, "6d18.blv", {X = -2688, Y = 1216, Z = 1153, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 447, Icon = 5, Name = "6d18.blv"})         -- "Gharik's Forge"
	end
end

--arena monster list

function events.GameInitialized2()
	-- Initialize the monsterOrderTable
	local monsterOrderTable = {}

	-- Fill the table with monster levels
	for i = 1, 651 do
		local index = i
		monsterOrderTable[i] = Game.MonstersTxt[index].Level
	end

	-- Create a table of indices
	local indices = {}
	for i = 1, #monsterOrderTable do
		indices[i] = i
	end

	-- Sort the indices based on the values in the monsterOrderTable
	table.sort(indices, function(a, b)
		return monsterOrderTable[a] < monsterOrderTable[b]
	end)

	-- Create a new sorted table
	monTbl = {}
	for i, index in ipairs(indices) do
		monTbl[i] = {
			Index = index,
			Level = monsterOrderTable[index]
		}
	end
	local removeList={462, 579}
	for i=1,651 do
		i=652-i
		if Game.MonstersTxt[monTbl[i].Index].AIType==1 or monTbl[i].Index%3~=0 or table.find(removeList, monTbl[i].Index) then
			table.remove(monTbl, i)
		end
	end
	
end

mapDungeons={1,2,3,4,5,6,7,8,9,10,11,12,13,14,16,17,19,21,22,23,24,25,26,27,28,29,30,31,32,34,36,37,38,40,41,42,43,44,45,46,47,48,49,51,52,54,55,56,57,62,63,64,65,66,67,68,69,70,71,72,73,75,76,77,78,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,101,104,105,106,108,109,110,111,133,134,135,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,186}

-- Function to get a unique random affix
function getUniqueAffix()
    local affix
    repeat
        affix = math.random(1, totalMapAffixes)
    until not assignedAffixes[affix]  -- Repeat until an unassigned affix is found
    assignedAffixes[affix] = true     -- Mark this affix as assigned
    return affix
end

function events.MonsterKilled(mon)
	if mon.NameId>300 then -- no drop from reanimated monsters
		return
	end
	mapvars.mapsDropped=mapvars.mapsDropped or 0
	vars.mapDropFailures=vars.mapDropFailures or 0
	local chances=0.001
	if vars.madnessMode then
		chances=chances*2
		if mapvars.mapAffixes then
			local map=mapLevels[Game.MapStats[Map.MapStatsIndex].Name]
			local level=mapvars.mapAffixes.Power*10+round((map.Low+map.Mid+map.High)/3)+20
			if level<1000 then
				chances=0
			else
				chances=chances/2
			end
		end
	end
	local levelRequired=100
	if vars.madnessMode then
		levelRequired=70
		if vars.ownedMaps>=3 then
			--return disabled, as maps are no longer easily farmable
		end
	end
	
	possibleMaps={}
	for i=1,#mapDungeons do
		if vars.dungeonCompletedList[Game.MapStats[mapDungeons[i]].Name] then
			table.insert(possibleMaps, mapDungeons[i])
		end
	end
	
	
	-- Apply pity protection using new pity system
	local dropChance=chances*#possibleMaps/#mapDungeons
	dropChance = pity_chance(dropChance, vars.mapDropFailures)
	
	-- Seeded map drop calculation
	local mult = GetDensityMultiplier(mon.Id)
	if mon.NameId>=220 and mon.NameId<=300 then
		mult=mult*10
		
		local skill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
		if skill=="Broodling" then
			local tier=(mon.Id-1)%3+1
			mult=mult/(5-tier)
		end
	end
	dropChance = dropChance * mon.Level / 100 / (mapvars.mapsDropped + 1) * mult
	
	-- Use seeded random if available, otherwise fallback to regular random
	local rollValue
	if vars.seed and mapvars.MonsterSeed then
		local monsterIndex = mon:GetIndex()
		if monsterIndex and mapvars.MonsterSeed[monsterIndex] then
			-- Use monster-specific seed for deterministic drop calculation
			local dropSeed = mapvars.MonsterSeed[monsterIndex] + 1337 -- Offset for map drops
			math.randomseed(dropSeed)
			rollValue = math.random()
			-- Additional randomization for item properties
			for i = 1, 3 do
				math.random()
			end
		else
			rollValue = math.random()
		end
	else
		rollValue = math.random()
	end
	if getMonsterLevel(mon)>=levelRequired and rollValue < dropChance then
		assignedAffixes = {}
		obj = SummonItem(290, mon.X, mon.Y, mon.Z + 100, 100)
		obj.Item.BonusStrength=possibleMaps[math.random(1,#possibleMaps)]
		mapvars.mapsDropped=mapvars.mapsDropped+1
		vars.mapDropFailures=0
		obj.Item.Bonus2=getUniqueAffix()
		obj.Item.Charges=getUniqueAffix()
		obj.Item.Charges=obj.Item.Charges+getUniqueAffix()*1000
		obj.Item.BonusExpireTime=getUniqueAffix()
		
		local roll=math.random()
		local bonus=1
		if roll<=0.1 then
			bonus=4
		elseif roll<0.3 then
			bonus=3
		elseif bonus<=0.6 then
			bonus=2
		end
		obj.Item.Bonus=bonus
		obj.Item.MaxCharges=round(getMonsterLevel(mon)/10-math.random(0,3))
		if vars.insanityMode and not vars.madnessMode then
			obj.Item.MaxCharges=math.max(obj.Item.MaxCharges,30)
		end
	elseif getMonsterLevel(mon) >= levelRequired then
		vars.mapDropFailures = vars.mapDropFailures + mult
	end
end

local possibleMonstersIn={7,10,13,16,31,34,37,40,52,55,73,76,79,82,85,88,91,
						94,100,103,106,109,112,115,118,121,124,127,130,133,
						139,142,148,151,154,157,160,169,172,175,181,184,187,
						193,196,202,205,208,211,214,217,220,226,229,232,235,
						238,241,244,253,256,259,262,265,268,271,274,277,280,
						283,286,289,292,295,298,301,304,307,310,388,391,397,
						400,403,406,409,412,415,418,421,424,427,448,451,454,
						457,475,478,481,484,487,490,493,496,499,502,505,511,
						517,520,523,526,529,532,535,538,541,544,547,550,553,
						556,559,562,565,568,571,574,580,583,586,589,592,601,
						604,610,613,619,622,628,631,634,637,640,643}
local possibleMonstersOut={7,10,13,16,31,34,37,40,52,55,70,73,76,79,82,85,88,91,
						94,100,103,106,109,112,115,118,121,124,127,130,133,136,
						139,142,148,151,154,157,160,163,169,172,175,181,184,187,190,
						193,196,202,205,208,211,214,217,220,223,226,229,232,235,
						238,241,244,253,256,259,262,265,268,271,274,277,280,
						283,286,289,292,295,298,301,304,307,310,388,391,394,397,
						400,403,406,409,412,415,418,421,424,427,448,451,454,
						457,460,475,478,481,484,487,490,493,496,499,502,505,508,511,514,
						517,520,523,526,529,532,535,538,541,544,547,550,553,
						556,559,562,565,568,571,574,580,583,586,589,592,601,
						604,610,613,619,622,628,631,634,637,640,643}
--map teleport
function events.UseMouseItem(t)
	local it=Mouse.Item
	if it.Number==290 then
		if Game.CurrentScreen~=0 then
			Game:ExitHouseScreen()
		end
		local map=Game.MapStats[it.BonusStrength]
		storeRefillDaysAfterMapUsage={it.BonusStrength, map.RefillDays}
		map.RefillDays=0
		local fileName=string.sub(map.FileName, 1, -5)
		local affixes=it.Bonus
		if affixes==0 then
			affixes=4
		end
		mapAffixList={	it.BonusExpireTime, 
						affixes>=2 and it.Bonus2 or 0, 
						affixes>=3 and it.Charges%1000 or 0, 
						affixes>=4 and math.floor(it.Charges/1000) or 0,
						["Power"]=it.MaxCharges}
		math.randomseed(it.BonusExpireTime+it.Bonus2*10^3+it.Charges*10^6+it.MaxCharges*10^9+it.BonusStrength*10^12)

		--randomize monsters
		mappingMonsters={}
		if string.sub(map.FileName,-3)=="blv" then
			for i=1,3 do
				table.insert(mappingMonsters,string.sub(Game.MonstersTxt[possibleMonstersIn[math.random(1,#possibleMonstersIn)]].Picture,1, -3))
			end
		else
			for i=1,3 do
				table.insert(mappingMonsters,string.sub(Game.MonstersTxt[possibleMonstersOut[math.random(1,#possibleMonstersOut)]].Picture,1, -3))
			end
		end
		--monster density
		local nAff=0
		for i=1,4 do
			if mapAffixList[i]>0 then
				nAff=nAff+1
			end
		end
		local mult=1+(it.MaxCharges*nAff+nAff*20)/300
		mapMonsterDensity={it.BonusStrength,mult}
		if string.sub(map.FileName,-3)=="blv" then
			blv(fileName)
		else
			odm(fileName)
		end
		if vars.madnessMode then
			vars.ownedMaps=vars.ownedMaps-1
		end
		Mouse.Item.Number=0
		local wait=10
		function events.Tick()
			if wait<=0 then
				events.Remove("Tick",1)
			else
				wait=wait-1
			end
			for i=0,Map.Sprites.High do
				if Map.Sprites[i].DecName=="Party Start" then
					local start=Map.Sprites[i]
					Party.X=start.X
					Party.Y=start.Y
					Party.Z=start.Z
					Party.Direction=start.Direction
				end	
			end
		end
	end
end
--store map monsters
function events.GameInitialized2()
	baseSpawnMonsters={}
	for i=1,Game.MapStats.High do
		baseSpawnMonsters[i]={}
		baseSpawnMonsters[i][1]=Game.MapStats[i].Monster1Pic
		baseSpawnMonsters[i][2]=Game.MapStats[i].Monster2Pic
		baseSpawnMonsters[i][3]=Game.MapStats[i].Monster3Pic
	end
	Game.ItemsTxt[290].Name="Dimension Map"
end

--needed for chest/objects loot
function events.BeforeLoadMap()
	if mapAffixList then
		mapvars.mapAffixes={mapAffixList[1],mapAffixList[2],mapAffixList[3],mapAffixList[4],["Power"]=mapAffixList.Power}
	end
	local id=Map.MapStatsIndex
	local map=Game.MapStats[id]
	if mappingMonsters then
		map.Monster1Pic=mappingMonsters[1]
		map.Monster2Pic=mappingMonsters[2]
		map.Monster3Pic=mappingMonsters[3]
	else
		map.Monster1Pic=baseSpawnMonsters[id][1]
		map.Monster2Pic=baseSpawnMonsters[id][2]
		map.Monster3Pic=baseSpawnMonsters[id][3]
	end
	mappingMonsters=nil
end
--needed to apply changes
function events.LoadMap()
	if mapAffixList then
		mapvars.mapAffixes={mapAffixList[1],mapAffixList[2],mapAffixList[3],mapAffixList[4],["Power"]=mapAffixList.Power}
		mapAffixList=nil
		for i=0,Map.Monsters.High do
			--Map.Monsters[i].Hostile=true
			--Map.Monsters[i].ShowAsHostile=true
			--removed, hopefully there aren't many friendly npcs spawning 
		end
	end
end
--restore
function events.AfterLoadMap()
	if storeRefillDaysAfterMapUsage then
		local map=Game.MapStats[storeRefillDaysAfterMapUsage[1]]
		map.RefillDays=storeRefillDaysAfterMapUsage[2]
		map.Mon1Hi=oldDensity1
		map.Mon2Hi=oldDensity2
		map.Mon3Hi=oldDensity3
		Game.ShowStatusText("")
		storeRefillDaysAfterMapUsage=nil
	end
end

--affix id -> {base, scale}: power = base + mapLevel*scale
local affixPowerTable={
	[1]={20,0.5},	[2]={10,1},		[3]={10,1},		[4]={5,0.5},
	[5]={7,0.15},	[6]={7,0.15},	[7]={1,0.1},	[8]={5,0.25},
	[9]={15,0.2},	[10]={5,0.1},	[11]={30,1},	[12]={30,2},
	[13]={30,1},	[14]={20,1},	[15]={20,1.5},	[16]={30,0.5},
	[17]={20,0.5},	[18]={15,1},	[19]={4,0.05},	[20]={10,0.2},
	[21]={10,0.2},	[22]={20,1},	[23]={15,0.5},	[24]={15,0.5},
	[25]={15,0.5},	[26]={15,0.5},	[27]={15,0.5},	[28]={15,0.5},
	[29]={15,0.5},	[30]={15,0.5},	[31]={15,0.5},	[32]={15,0.5},
	[33]={15,0.5},
}
function calculateAffixPower(n, p)
	local affix=affixPowerTable[n]
	if not affix then
		return false
	end
	local power=affix[1]+p*affix[2]
	--reductions can eventually go to 0, fix
	local reductionAffix={13,21,22,23,24,25,26,27,28,29,30,31,32,33}
	if table.find(reductionAffix,n) then
		power=MawCore.Formulas.reductionPercent(power, 2)
	end
	--fix for proc chance over 100
	local procAffix={3,4,8,9,14,19,34}
	if table.find(procAffix,n) then
		power=math.min(power,100)
	end
	return power
end

function getMapAffixPower(n, power)
	--for tooltips
	if power then
		return calculateAffixPower(n, power)
	end
	
    if not mapvars.mapAffixes then return false end
    
	local id = table.find(mapvars.mapAffixes, n)
    if type(id) == "number" then
        return calculateAffixPower(n, mapvars.mapAffixes.Power)
    else 
        return false
    end
end

--map affixes

totalMapAffixes=33
-- moved to Scripts/Modules/MawCore/Tooltip.lua (item tooltip sections)

function events.LoadMap()
	if vars.madnessMode then
		vars.ownedMaps=vars.ownedMaps or 0
		vars.ownedMaps=math.max(vars.ownedMaps,0)
	end
end

--remove dropped maps
--[[ NO LONGER NEEDED
function events.LeaveMap()
	if vars.madnessMode then
		for i=0, Map.Objects.High do
			local obj=Map.Objects[i]
			if obj.Item and obj.Item.Number==290 then
				obj.Type=0
				obj.TypeIndex=0
				obj.Item.Number=0
				vars.ownedMaps=vars.ownedMaps-1
			end
		end
		for i=0, Map.Chests.High do
			local chest=Map.Chests[i]
			for j=1, chest.Items.High do
				if chest.Items[j]==290 then
					chest.Items[j]=0
					vars.ownedMaps=vars.ownedMaps-1
				end
			end
		end
	end
end
]]
function events.Action(t)
	if t.Action==14 and vars.madnessMode then
		BeginGrabObjects()
		checkForMapDropped=true
		function events.Tick()
			if checkForMapDropped then
				events.Remove("Tick",1)
				local obj=GrabObjects()
				if obj and obj.Item.Number==290 then
					local it=obj.Item
					evt.Add("Items", 290)
					Mouse.Item.Bonus=it.Bonus
					Mouse.Item.Charges=it.Charges
					Mouse.Item.MaxCharges=it.MaxCharges
					Mouse.Item.Bonus2=it.Bonus2
					Mouse.Item.BonusStrength=it.BonusStrength
					Mouse.Item.BonusExpireTime=it.BonusExpireTime
					obj.Item.Number=0
					obj.Type=0
					obj.TypeIndex=0
				end
			end
		end
	end
end


function events.Action(t)
	if (t.Action==23 or t.Action==25) and vars.madnessMode then
		checkForMapDropped=false
	end
end