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
function resetMap(dungeonId)
	--if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked and not vars.onlineMode then
	if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
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
	end
end

--barrels fix
local stats={"MightBase", "IntellectBase", "PersonalityBase", "EnduranceBase", "AccuracyBase", "SpeedBase", "LuckBase", "LuckBase", "LuckBase", "LuckBase", "LuckBase", "FireResistanceBase", "AirResistanceBase", "WaterResistanceBase", "EarthResistanceBase", "MindResistanceBase", "BodyResistanceBase", }
function events.EvtMap(evtId)
	if evtId>=20000 then
		previousStats=previousStats or {}
		local event=evtId
		function events.Tick()
			events.Remove("Tick", 1)
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
		end
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
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[50]  -- "Enter the Abandoned Temple"
		evt.map[501] = function()
			local dungeonId="d05.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -3008, Y = -1696, Z = 2464, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 346, Icon = 1, Name = "d05.blv"}         -- "Abandoned Temple"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[51]  -- "Enter the Regnan Pirate Outpost"
		evt.map[502] = function()
			local dungeonId="d06.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -7, Y = -714, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 349, Icon = 1, Name = "d06.blv"}         -- "Pirate Outpost"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[52]  -- "Enter the Uplifted Library"
		evt.map[503] = function()
			local dungeonId="d40.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -592, Y = 624, Z = 0, Direction = 552, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d40.blv"}
		end

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[50]  -- "Enter the Abandoned Temple"
		evt.map[504] = function()
			local dungeonId="d05.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 12704, Y = 2432, Z = 385, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 345, Icon = 1, Name = "d05.blv"}         -- "Backdoor of Abandoned Temple"
		end

		Game.MapEvtLines:RemoveEvent(505)
		evt.hint[505] = evt.str[53]  -- "Enter the Plane of Earth"
		evt.map[505] = function()
			local dungeonId="eleme.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 0, Y = 0, Z = 49, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 352, Icon = 1, Name = "eleme.blv"}         -- "Gateway to the Plane of Earth"
		end
	end
	
	--Ravenshore
	if Map.Name=="out02.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[50]  -- "Enter Smuggler's Cove"
		evt.map[501] = function()
			local dungeonId="d07.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -3800, Y = 623, Z = 1, Direction = 2000, LookAngle = 0, SpeedZ = 0, HouseId = 351, Icon = 1, Name = "d07.blv"}         -- "Smuggler's Cove"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[51]  -- "Enter the Dire Wolf Den"
		evt.map[502] = function()
			local dungeonId="d08.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 2157, Y = 1003, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 353, Icon = 1, Name = "d08.blv"}         -- "Dire Wolf Den"
		end

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[53]  -- "Enter Escaton's Crystal"
		evt.map[504] = function()
			local dungeonId="d10.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.ForPlayer("All")
			if evt.Cmp{"Inventory", Value = 610} then         -- "Conflux Key"
				evt.MoveToMap{X = -1024, Y = -1626, Z = 0, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 355, Icon = 1, Name = "d10.blv"}         -- "Inside the Crystal"
			else
				evt.FaceAnimation{Player = "Current", Animation = 18}
			end
		end

		Game.MapEvtLines:RemoveEvent(507)
		evt.hint[507] = evt.str[44]  -- "Enter the Chapel of Eep"
		evt.map[507] = function()
			local dungeonId="d45.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -481, Y = -2824, Z = 321, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d45.blv"}
		end
	end
	
	--Alvar
	if Map.Name=="out03.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[50]  -- "Enter the Wasp Nest"
		evt.map[501] = function()
			local dungeonId="d11.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -2192, Y = -1840, Z = -127, Direction = 33, LookAngle = 0, SpeedZ = 0, HouseId = 356, Icon = 1, Name = "d11.blv"}         -- "Wasp Nest"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[51]  -- "Enter the Ogre Raiding Fort"
		evt.map[502] = function()
			local dungeonId="d12.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -3424, Y = 32, Z = 0, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 357, Icon = 1, Name = "d12.blv"}         -- "Ogre Raiding Fort"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[52]  -- "Enter the Dark Dwarf Compound"
		evt.map[503] = function()
			local dungeonId="d41.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -10528, Y = -352, Z = -896, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d41.blv"}
		end

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[50]  -- "Enter the Wasp Nest"
		evt.map[504] = function()
			local dungeonId="d11.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 301, Y = 2162, Z = 513, Direction = 161, LookAngle = 0, SpeedZ = 0, HouseId = 356, Icon = 1, Name = "d11.blv"}         -- "Wasp Nest"
		end
	end
	
	--Ironsand Desert
	if Map.Name=="out04.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[50]  -- "Enter the Troll Tomb"
		evt.map[501] = function()
			local dungeonId="d13.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -672, Y = 768, Z = -28, Direction = 256, LookAngle = 0, SpeedZ = 0, HouseId = 358, Icon = 1, Name = "d13.blv"}         -- "Troll Tomb"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[51]  -- "Enter the Cyclops Larder"
		evt.map[502] = function()
			local dungeonId="d14.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 0, Y = 0, Z = 1, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 359, Icon = 1, Name = "d14.blv"}         -- "Cyclops Larder"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[52]  -- "Enter the Chain of Fire"
		evt.map[503] = function()
			local dungeonId="d15.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -288, Y = -768, Z = 0, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 360, Icon = 1, Name = "d15.blv"}         -- "Chain of Fire"
		end

		Game.MapEvtLines:RemoveEvent(505)
		evt.hint[505] = evt.str[52]  -- "Enter the Chain of Fire"
		evt.map[505] = function()
			local dungeonId="d15.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -12423, Y = 4347, Z = -135, Direction = 1544, LookAngle = 0, SpeedZ = 0, HouseId = 360, Icon = 1, Name = "d15.blv"}         -- "Chain of Fire"
		end

		Game.MapEvtLines:RemoveEvent(506)
		evt.hint[506] = evt.str[53]  -- "Enter the Cave"
		evt.map[506] = function()
			local dungeonId="d48.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 2116, Y = 9631, Z = 1, Direction = 1296, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 3, Name = "d48.blv"}
		end
	end
	
	--Garrote Gorge
	if Map.Name=="out05.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[50]  -- "Enter the Dragon Hunter's Camp"
		evt.map[501] = function()
			local dungeonId="d16.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -1216, Y = 1888, Z = 1, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 361, Icon = 1, Name = "d16.blv"}         -- "Dragon Hunter Camp"
		end
		
		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[51]  -- "Enter the Dragon Cave"
		evt.map[502] = function()
			local dungeonId="d17.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 223, Y = -8, Z = 170, Direction = 1088, LookAngle = 0, SpeedZ = 0, HouseId = 362, Icon = 1, Name = "d17.blv"}         -- "Dragon Cave"
		end
		
		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[52]  -- "Enter the Naga Vault"
		evt.map[503] = function()
			local dungeonId="d18.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -500, Y = -1567, Z = -63, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 363, Icon = 1, Name = "d18.blv"}         -- "Naga Vault"
		end
		
		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[53]  -- "Enter the Grand Temple of Eep"
		evt.map[504] = function()
			local dungeonId="d44.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -2812, Y = 726, Z = 1, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d44.blv"}
		end
	end
	
	if Map.Name=="out06.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[50]  -- "Enter the Necromancers' Guild"
		evt.map[501] = function()
			local dungeonId="d19.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 0, Y = 64, Z = 0, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 371, Icon = 1, Name = "d19.blv"}         -- "Necromancers' Guild"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[51]  -- "Enter the Mad Necromancer's Lab"
		evt.map[502] = function()
			local dungeonId="d20.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -900, Y = -127, Z = 1, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 372, Icon = 1, Name = "d20.blv"}         -- "Mad Necromancer's Lab"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[53]  -- "Enter the Vampire Crypt"
		evt.map[503] = function()
			local dungeonId="d21.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -457, Y = -1749, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d21.blv"}
		end

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[52]  -- "Enter the Cave"
		evt.map[504] = function()
			local dungeonId="d49.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 9690, Y = 1334, Z = 1176, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 3, Name = "d49.blv"}
		end
	end
	
	--Murmurwoods
	if Map.Name=="out07.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[50]  -- "Enter the Temple of the Sun"
		evt.map[501] = function()
			local dungeonId="d22.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -768, Y = -768, Z = 96, Direction = 280, LookAngle = 0, SpeedZ = 0, HouseId = 364, Icon = 1, Name = "d22.blv"}         -- "Temple of the Sun"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[51]  -- "Enter the Druid Circle"
		evt.map[502] = function()
			local dungeonId="d23.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 235, Y = 2980, Z = 673, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 365, Icon = 3, Name = "d23.blv"}         -- "Abandoned Druid Circle"
		end

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[52]  -- "Enter the Ancient Troll Home"
		evt.map[504] = function()
			local dungeonId="d43.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			if not evt.Cmp{"QBits", Value = 69} then         -- Ancient Troll Homeland Found
				evt.Set{"QBits", Value = 69}         -- Ancient Troll Homeland Found
			end
			evt.MoveToMap{X = 448, Y = -224, Z = 0, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d43.blv"}
		end
	end
	
	--ravage roaming
	if Map.Name=="out08.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[50]  -- "Enter the Balthazar Lair"
		evt.map[501] = function()
			local dungeonId="d24.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 1, Y = -100, Z = -85, Direction = 1540, LookAngle = 0, SpeedZ = 0, HouseId = 366, Icon = 1, Name = "d24.blv"}         -- "Minotaur Lair"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[51]  -- "Enter the Barbarian Fortress"
		evt.map[502] = function()
			local dungeonId="d25.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -2284, Y = 1847, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 367, Icon = 1, Name = "d25.blv"}         -- "Barbarian Fortress"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[52]  -- "Enter the Crypt of Korbu"
		evt.map[503] = function()
			local dungeonId="d26.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -4436, Y = -6538, Z = 317, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d26.blv"}
		end

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[50]  -- "Enter the Balthazar Lair"
		evt.map[504] = function()
			local dungeonId="d24.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 832, Y = 849, Z = 44, Direction = 1548, LookAngle = 0, SpeedZ = 0, HouseId = 344, Icon = 1, Name = "d24.blv"}         -- "Balthazar Lair"
		end

		Game.MapEvtLines:RemoveEvent(505)
		evt.hint[505] = evt.str[51]  -- "Enter the Barbarian Fortress"
		evt.map[505] = function()
			local dungeonId="d25.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 614, Y = 1858, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 367, Icon = 1, Name = "d25.blv"}         -- "Barbarian Fortress"
		end

		Game.MapEvtLines:RemoveEvent(506)
		evt.hint[506] = evt.str[51]  -- "Enter the Barbarian Fortress"
		evt.map[506] = function()
			local dungeonId="d25.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 628, Y = -1274, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 367, Icon = 1, Name = "d25.blv"}         -- "Barbarian Fortress"
		end

		Game.MapEvtLines:RemoveEvent(507)
		evt.hint[507] = evt.str[51]  -- "Enter the Barbarian Fortress"
		evt.map[507] = function()
			local dungeonId="d25.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -2284, Y = -1353, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 367, Icon = 1, Name = "d25.blv"}         -- "Barbarian Fortress"
		end
		
		Game.MapEvtLines:RemoveEvent(509)
		evt.hint[509] = evt.str[53]  -- "Enter the Church of Eep"
		evt.map[509] = function()
			local dungeonId="d46.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -21, Y = 5, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d46.blv"}
		end
	end
	
	--Regna
	if Map.Name=="out13.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[50]  -- "Enter the Pirate Stronghold"
		evt.map[501] = function()
			local dungeonId="d31.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -554, Y = 3682, Z = 1, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 368, Icon = 1, Name = "d31.blv"}         -- "Pirate Stronghold"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[51]  -- "Enter the Abandoned Pirate Keep"
		evt.map[502] = function()
			local dungeonId="d32.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -6520, Y = -6512, Z = 129, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 369, Icon = 1, Name = "d32.blv"}         -- "Abandoned Pirate Keep"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[44]  -- "Enter the Tower"
		evt.map[503] = function()
			if evt.Cmp{"QBits", Value = 197} then         -- Door to the passage under regna from the northern watch tower is unlocked
				local dungeonId="d33.blv"
				if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
					resetMap(dungeonId)
					return
				end
				evt.MoveToMap{X = 5892, Y = 4632, Z = 1853, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d33.blv"}
			else
				evt.FaceAnimation{Player = "Current", Animation = 18}
			end
		end

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[54]  -- "Enter the Cave"
		evt.map[504] = function()
			local dungeonId="d34.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -28, Y = -193, Z = 57, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 370, Icon = 3, Name = "d34.blv"}         -- "Small Sub Pen"
		end

		Game.MapEvtLines:RemoveEvent(505)
		evt.hint[505] = evt.str[54]  -- "Enter the Cave"
		evt.map[505] = function()
			local dungeonId="d47.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 1328, Y = -1576, Z = 4, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 1, Name = "d47.blv"}
		end

		Game.MapEvtLines:RemoveEvent(506)
		evt.hint[506] = evt.str[44]  -- "Enter the Tower"
		evt.map[506] = function()
			if evt.Cmp{"QBits", Value = 198} then         -- Door to the passage under regna from the southern watch tower is unlocked
				local dungeonId="d33.blv"
				if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
					resetMap(dungeonId)
					return
				end
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
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[30]  -- "Enter the Grand Temple of the Moon"
		evt.map[501] = function()
			local dungeonId="7d19.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 3136, Y = 2053, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 404, Icon = 1, Name = "7d19.blv"}         -- "Grand Temple of the Moon"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[31]  -- "Enter the Grand Temple of the Sun"
		evt.map[502] = function()
			local dungeonId="t03.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 0, Y = -3179, Z = 161, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 405, Icon = 1, Name = "t03.blv"}         -- "Grand Temple of the Sun"
		end
	end
	
	--Mount Nighon
	if Map.Name=="out10.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[30]  -- "Enter Thunderfist Mountain"
		evt.map[501] = function()
			local dungeonId="7d07.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -1024, Y = 768, Z = 4097, Direction = 1792, LookAngle = 0, SpeedZ = 0, HouseId = 406, Icon = 9, Name = "7d07.blv"}         -- "Thunderfist Mountain"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[31]  -- "Enter The Maze"
		evt.map[502] = function()
			local dungeonId="d02.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 1536, Y = -8614, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 407, Icon = 2, Name = "d02.blv"}         -- "The Maze"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[30]  -- "Enter Thunderfist Mountain"
		evt.map[503] = function()
			local dungeonId="7d07.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 9960, Y = 1443, Z = 390, Direction = 1936, LookAngle = 0, SpeedZ = 0, HouseId = 406, Icon = 9, Name = "7d07.blv"}         -- "Thunderfist Mountain"
		end

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[30]  -- "Enter Thunderfist Mountain"
		evt.map[504] = function()
			local dungeonId="7d07.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -11058, Y = 4858, Z = 3969, Direction = 148, LookAngle = 0, SpeedZ = 0, HouseId = 406, Icon = 9, Name = "7d07.blv"}         -- "Thunderfist Mountain"
		end
		
		Game.MapEvtLines:RemoveEvent(505)
		evt.hint[505] = evt.str[30]  -- "Enter Thunderfist Mountain"
		evt.map[505] = function()
			local dungeonId="7d07.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 11471, Y = -3498, Z = 2814, Direction = 414, LookAngle = 0, SpeedZ = 0, HouseId = 406, Icon = 9, Name = "7d07.blv"}         -- "Thunderfist Mountain"
		end
	end
	
	--Dwarven Barrows
	if Map.Name=="out11.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[30]  -- "Enter Stone City"
		evt.map[501] = function()
			local dungeonId="7d24.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 245, Y = -5362, Z = 34, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 408, Icon = 2, Name = "7d24.blv"}         -- "Stone City"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[32]  -- "Enter Mansion"
		evt.map[502] = function()
			local dungeonId="7d37.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 2, Y = -1096, Z = -31, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 9, Name = "7d37.blv"}
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[31]  -- "Enter Dwarven Barrow"
		evt.map[503] = function()
			local dungeonId="mdt01.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 382, Y = 324, Z = -15, Direction = 1280, LookAngle = 0, SpeedZ = 0, HouseId = 1085, Icon = 2, Name = "mdt01.blv"}         -- ""
		end

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[31]  -- "Enter Dwarven Barrow"
		evt.map[504] = function()
			local dungeonId="mdr01.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 106, Y = -666, Z = 49, Direction = 256, LookAngle = 0, SpeedZ = 0, HouseId = 1085, Icon = 2, Name = "mdr01.blv"}         -- ""
		end
		
		Game.MapEvtLines:RemoveEvent(505)
		evt.hint[505] = evt.str[31]  -- "Enter Dwarven Barrow"
		evt.map[505] = function()
			local dungeonId="mdr01.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -384, Y = -983, Z = 1, Direction = 256, LookAngle = 0, SpeedZ = 0, HouseId = 1085, Icon = 2, Name = "mdr01.blv"}         -- "Arbiter"
		end
	end
	
	--The Land of the Giants
	if Map.Name=="out12.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[30]  -- "Enter Colony Zod"
		evt.map[501] = function()
			local dungeonId="7d27.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 2648, Y = -1372, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 409, Icon = 3, Name = "7d27.blv"}         -- "Colony Zod"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[31]  -- "Enter the Cave"
		evt.map[502] = function()
			local dungeonId="7d36.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 9165, Y = 15139, Z = -583, Direction = 24, LookAngle = 0, SpeedZ = 0, HouseId = 48, Icon = 3, Name = "7d36.blv"}         -- "Tunnels to Eeofol"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[32]  -- "Enter the Cave"
		evt.map[503] = function()
			local dungeonId="mdt12.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -54, Y = 3470, Z = 1, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 3, Name = "mdt12.blv"}
		end

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[32]  -- "Enter the Cave"
		evt.map[504] = function()
			local dungeonId="mdt12.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 19341, Y = 21323, Z = 1, Direction = 256, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 3, Name = "mdt12.blv"}
		end
	end
	
	--Avlee
	if Map.Name=="out14.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[30]  -- "Enter the The Titan Stronghold"
		evt.map[501] = function()
			local dungeonId="7d09.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -1707, Y = -21848, Z = -1007, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 413, Icon = 9, Name = "7d09.blv"}         -- "Titan's Stronghold"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[31]  -- "Enter the Temple of Baa"
		evt.map[502] = function()
			local dungeonId="d04.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 1, Y = -2772, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 414, Icon = 9, Name = "d04.blv"}         -- "Temple of Baa"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[32]  -- "Enter the Hall under the Hill"
		evt.map[503] = function()
			local dungeonId="D22.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -1114, Y = 2778, Z = 1, Direction = 1280, LookAngle = 0, SpeedZ = 0, HouseId = 415, Icon = 3, Name = "7D22.blv"}         -- "Hall under the Hill"
		end
	end
	
	--Emeralnd Island
	if Map.Name=="7out01.odm" then
		Game.MapEvtLines:RemoveEvent(101)
		evt.hint[101] = evt.str[30]  -- "Enter The Temple of the Moon"
		evt.map[101] = function()
			local dungeonId="7d06.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -1208, Y = -4225, Z = 366, Direction = 320, LookAngle = 0, SpeedZ = 0, HouseId = 387, Icon = 3, Name = "7d06.blv"}         -- "Temple of the Moon"
		end
	end
	
	--Harmondale
	if Map.Name=="7out02.odm" then
		Game.MapEvtLines:RemoveEvent(302)
		evt.hint[302] = evt.str[31]  -- "Enter the White Cliff Caves"
		evt.map[302] = function()
			local dungeonId="7d21.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 1344, Y = -256, Z = -107, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 391, Icon = 3, Name = "7d21.blv"}         -- "White Cliff Cave"
		end
	end
	
	--Erathia
	if Map.Name=="7out03.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[30]  -- "Enter The Erathian Sewer"
		evt.map[501] = function()
			local dungeonId="d01.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 28, Y = -217, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 392, Icon = 5, Name = "d01.blv"}         -- "Erathian Sewer"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[32]  -- "Enter Fort Riverstride"
		evt.map[502] = function()
			local dungeonId="7d31.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 64, Y = -448, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 393, Icon = 9, Name = "7d31.blv"}         -- "Fort Riverstride"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[31]  -- "Enter Castle Gryphonheart"
		evt.map[503] = function()
			local dungeonId="7d33.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 768, Y = 0, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 383, Icon = 9, Name = "7d33.blv"}         -- "Castle Gryphonheart"
		end

		Game.MapEvtLines:RemoveEvent(504)
		evt.hint[504] = evt.str[20]  -- "Door"
		evt.map[504] = function()
			local dungeonId="7d33.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			if evt.Cmp{"Inventory", Value = 1462} then         -- "Catherine's Key"
				evt.MoveToMap{X = -6314, Y = -618, Z = 1873, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 383, Icon = 9, Name = "7d33.blv"}         -- "Castle Gryphonheart"
			else
				evt.StatusText{Str = 21}         -- "This Door is Locked"
				evt.FaceAnimation{Player = 4, Animation = 18}
			end
		end

		Game.MapEvtLines:RemoveEvent(505)
		evt.hint[505] = evt.str[32]  -- "Enter Fort Riverstride"
		evt.map[505] = function()
			local dungeonId="7d31.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -1262, Y = 587, Z = -1215, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 393, Icon = 9, Name = "7d31.blv"}         -- "Fort Riverstride"
		end

		Game.MapEvtLines:RemoveEvent(506)
		evt.hint[506] = evt.str[30]  -- "Enter The Erathian Sewer"
		evt.map[506] = function()
			local dungeonId="d01.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 6647, Y = 3511, Z = -511, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 392, Icon = 5, Name = "d01.blv"}         -- "Erathian Sewer"
		end

		Game.MapEvtLines:RemoveEvent(507)
		evt.hint[507] = evt.str[30]  -- "Enter The Erathian Sewer"
		evt.map[507] = function()
			local dungeonId="d01.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -6507, Y = 10205, Z = -383, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 392, Icon = 5, Name = "d01.blv"}         -- "Erathian Sewer"
		end

		Game.MapEvtLines:RemoveEvent(508)
		evt.hint[508] = evt.str[33]  -- "Enter"
		evt.map[508] = function()
			local dungeonId="mdt11.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -111, Y = -25, Z = 1, Direction = 640, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 2, Name = "mdt11.blv"}
		end

		Game.MapEvtLines:RemoveEvent(509)
		evt.hint[509] = evt.str[33]  -- "Enter"
		evt.map[509] = function()
			local dungeonId="mdt14.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -104, Y = 128, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 3, Name = "mdt14.blv"}
		end
	end
	
	--Tularean Forest
	if Map.Name=="7out04.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[30]  -- "Enter Castle Navan"
		evt.map[501] = function()
			local dungeonId="7d32.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 0, Y = -1589, Z = 225, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 384, Icon = 1, Name = "7d32.blv"}         -- "Castle Navan"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[31]  -- "Enter Tularean Caves"
		evt.map[502] = function()
			local dungeonId="7d08.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 2071, Y = 448, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 394, Icon = 3, Name = "7d08.blv"}         -- "Tularean Caves"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[32]  -- "Enter Clanker's Laboratory"
		evt.map[503] = function()
			if not evt.Cmp{"QBits", Value = 710} then         -- Archibald in Clankers Lab now
				local dungeonId="7d12.blv"
				if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
					resetMap(dungeonId)
					return
				end
				evt.MoveToMap{X = 0, Y = -709, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 395, Icon = 9, Name = "7d12.blv"}         -- "Clanker's Laboratory"
			end
			evt.SpeakNPC{NPC = 427}         -- "Archibald Ironfist"
		end
	end
	
	--Deija
	if Map.Name=="7out05.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[30]  -- "Enter the Hall of the Pit"
		evt.map[501] = function()
			local dungeonId="t04.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 512, Y = -3156, Z = 1, Direction = 545, LookAngle = 0, SpeedZ = 0, HouseId = 396, Icon = 2, Name = "t04.blv"}         -- "Hall of the Pit"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[31]  -- "Enter Watchtower 6"
		evt.map[502] = function()
			local dungeonId="7d15.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -416, Y = -1033, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 397, Icon = 9, Name = "7d15.blv"}         -- "Watchtower 6"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.map[503] = function()
			if evt.Cmp{"QBits", Value = 611} then         -- Chose the path of Light
				local dungeonId="mdt10.blv"
				if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
					resetMap(dungeonId)
					return
				end
				evt.MoveToMap{X = 442, Y = -1112, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 9, Name = "mdt10.blv"}
			else
				evt.SpeakNPC{NPC = 357}         -- "William Setag"
			end
		end
	end
	
	--Bracada Desert
	if Map.Name=="7out06.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[30]  -- "Enter the School of Sorcery"
		evt.map[501] = function()
			local dungeonId="7d14.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 2, Y = -1341, Z = -159, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 398, Icon = 9, Name = "7d14.blv"}         -- "School of Sorcery"
		end

		Game.MapEvtLines:RemoveEvent(502)
		evt.hint[502] = evt.str[31]  -- "Enter the Red Dwarf Mines"
		evt.map[502] = function()
			local dungeonId="7d34.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 26, Y = 6, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 399, Icon = 3, Name = "7d34.blv"}         -- "Red Dwarf Mines"
		end
	end
	
	--Tatalia
	if Map.Name=="7out13.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[30]  -- "Enter the Wine Cellar"
		evt.map[501] = function()
			local dungeonId="7d16.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 601, Y = -512, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 412, Icon = 2, Name = "7d16.blv"}         -- "Wine Cellar"
		end

		Game.MapEvtLines:RemoveEvent(503)
		evt.hint[503] = evt.str[32]  -- "Enter the Tidewater Caverns"
		evt.map[503] = function()
			local dungeonId="7d17.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -1944, Y = -2052, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 411, Icon = 9, Name = "7d17.blv"}         -- "Tidewater Caverns"
		end
	end
	
	--Shoals
	if Map.Name=="7out15.odm" then
		Game.MapEvtLines:RemoveEvent(501)
		evt.hint[501] = evt.str[30]
		evt.map[501] = function()
			local dungeonId="7d23.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 524, Y = 1463, Z = 225, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 416, Icon = 9, Name = "7d23.blv"}         -- "The Lincoln"
		end
	end	
	
	
	-------------------------
	--MM6
	-------------------------
	--Sweet Water
	if Map.Name=="outa1.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.house[90] = 421  -- "The Hive"
		evt.map[90] = function()
			local dungeonId="hive.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 435, Y = 3707, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 421, Icon = 5, Name = "hive.blv"}         -- "The Hive"
		end
	end
	
	--Hermit's Isle
	if Map.Name=="outa3.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.map[90] = function()
			local dungeonId="6t6.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -2048, Y = 3453, Z = 2049, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 433, Icon = 5, Name = "6t6.blv"}         -- "Supreme Temple of Baa"
		end
	end
	
	--Kriegspire
	if Map.Name=="outb1.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.map[90] = function()
			evt.ForPlayer("All")
			if evt.Cmp{"Inventory", Value = 2105} then         -- "Cloak of Baa"
			local dungeonId="6t7.blv"
				if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
					resetMap(dungeonId)
					return
				end
				evt.MoveToMap{X = 2094, Y = -19, Z = 177, Direction = 337, LookAngle = 0, SpeedZ = 0, HouseId = 435, Icon = 5, Name = "6t7.blv"}         -- "Superior Temple of Baa"
			else
				evt.StatusText{Str = 12}         -- "You are not a follower of Baa.  Begone!"
			end
		end

		Game.MapEvtLines:RemoveEvent(91)
		evt.map[91] = function()
			local dungeonId="6d19.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 2702, Y = -2926, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 448, Icon = 5, Name = "6d19.blv"}         -- "Agar's Laboratory"
		end

		Game.MapEvtLines:RemoveEvent(92)
		evt.map[92] = function()
			local dungeonId="6d20.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -49, Y = -42, Z = -2, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 449, Icon = 5, Name = "6d20.blv"}         -- "Caves of the Dragon Riders"
		end

		Game.MapEvtLines:RemoveEvent(93)
		evt.map[93] = function()
			local dungeonId="cd3.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 5861, Y = 2720, Z = 169, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 427, Icon = 5, Name = "cd3.blv"}         -- "Castle Kriegspire"
		end

		Game.MapEvtLines:RemoveEvent(94)
		evt.hint[94] = evt.str[1]  -- "Demon Lair"
		evt.map[94] = function()
			local dungeonId="zdwj02.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 1893, Y = 122, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 5, Name = "zdwj02.blv"}
		end

		Game.MapEvtLines:RemoveEvent(100)
		evt.hint[100] = evt.str[2]  -- "Drink from Well."
		evt.map[100] = function()
			local dungeonId="cd3.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.StatusText{Str = 3}         -- "You feel Strange."
			evt.MoveToMap{X = 12768, Y = 4192, Z = 512, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 0, Name = "cd3.blv"}
		end
	end
	
	--Blackshire
	if Map.Name=="outb2.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.map[90] = function()
			local dungeonId="6t8.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -4158, Y = 1792, Z = 1233, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 437, Icon = 5, Name = "6t8.blv"}         -- "Temple of the Snake"
		end

		Game.MapEvtLines:RemoveEvent(91)
		evt.map[91] = function()
			local dungeonId="6d17.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -9600, Y = 22127, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 446, Icon = 5, Name = "6d17.blv"}         -- "Lair of the Wolf"
		end
	end
	
	--Dragonsand
	if Map.Name=="outb3.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.map[90] = function()
			local dungeonId="pyramid.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -9734, Y = -19201, Z = 772, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 420, Icon = 5, Name = "pyramid.blv"}         -- "Tomb of VARN"
		end
	end
	
	--Frozen Highlands
	if Map.Name=="outc1.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.map[90] = function()
			local dungeonId="6d08.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 1408, Y = -1664, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 436, Icon = 5, Name = "6d08.blv"}         -- "Shadow Guild"
		end

		Game.MapEvtLines:RemoveEvent(91)
		evt.map[91] = function()
			local dungeonId="6d15.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -495, Y = -219, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 444, Icon = 5, Name = "6d15.blv"}         -- "Icewind Keep"
		end
	end
	
	--Free Haven
	if Map.Name=="outc2.odm" then
		Game.MapEvtLines:RemoveEvent(150)
		evt.map[150] = function()
			local dungeonId="6d10.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -2, Y = -128, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 439, Icon = 5, Name = "6d10.blv"}         -- "Dragoons' Keep"
		end

		Game.MapEvtLines:RemoveEvent(151)
		evt.map[151] = function()
			local dungeonId="6d14.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -118, Y = -1640, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 443, Icon = 5, Name = "6d14.blv"}         -- "Tomb of Ethric the Mad"
		end

		Game.MapEvtLines:RemoveEvent(152)
		evt.map[152] = function()
			local dungeonId="6t5.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 0, Y = -2135, Z = 125, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 431, Icon = 5, Name = "6t5.blv"}         -- "Temple of the Moon"
		end
	end
	
	--Mire of the Damned
	if Map.Name=="outc3.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.map[90] = function()
			local dungeonId="6d09.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -3714, Y = 1250, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 438, Icon = 5, Name = "6d09.blv"}         -- "Snergle's Iron Mines"
		end

		Game.MapEvtLines:RemoveEvent(91)
		evt.map[91] = function()
			local dungeonId="cd2.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 21169, Y = 1920, Z = -689, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 424, Icon = 5, Name = "cd2.blv"}         -- "Castle Darkmoor"
		end

		Game.MapEvtLines:RemoveEvent(93)
		evt.hint[93] = evt.str[2]  -- "Dragon's Lair"
		evt.map[93] = function()
			local dungeonId="zddb01.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -622, Y = 239, Z = 1, Direction = 128, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 5, Name = "zddb01.blv"}
		end
	end
	
	--Silver Cove
	if Map.Name=="outd1.odm" then
		Game.MapEvtLines:RemoveEvent(150)
		evt.map[150] = function()
			local dungeonId="6d12.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -127, Y = 4190, Z = 1, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 441, Icon = 5, Name = "6d12.blv"}         -- "Silver Helm Stronghold"
		end

		Game.MapEvtLines:RemoveEvent(151)
		evt.map[151] = function()
			local dungeonId="6d13.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -128, Y = -3968, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 442, Icon = 5, Name = "6d13.blv"}         -- "The Monolith"
		end

		Game.MapEvtLines:RemoveEvent(152)
		evt.map[152] = function()
			local dungeonId="6d16.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -4724, Y = 1494, Z = 127, Direction = 1920, LookAngle = 0, SpeedZ = 0, HouseId = 445, Icon = 5, Name = "6d16.blv"}         -- "Warlord's Fortress"
		end
	end
	
	--Bootleg Bay
	if Map.Name=="outd2.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.map[90] = function()
			local dungeonId="6d04.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -1792, Y = -19, Z = 1, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 428, Icon = 5, Name = "6d04.blv"}         -- "Hall of the Fire Lord"
		end

		Game.MapEvtLines:RemoveEvent(91)
		evt.house[91] = 423  -- "Temple of the Fist"
		evt.map[91] = function()
			local dungeonId="6t2.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 0, Y = -2231, Z = 513, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 423, Icon = 5, Name = "6t2.blv"}         -- "Temple of the Fist"
		end

		Game.MapEvtLines:RemoveEvent(92)
		evt.house[92] = 429  -- "Temple of the Sun"
		evt.map[92] = function()
			local dungeonId="6t4.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -3258, Y = 483, Z = 49, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 429, Icon = 5, Name = "6t4.blv"}         -- "Temple of the Sun"
		end

		Game.MapEvtLines:RemoveEvent(93)
		evt.house[93] = 426  -- "Temple of Tsantsa"
		evt.map[93] = function()
			local dungeonId="6t3.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 2817, Y = -4748, Z = -639, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 426, Icon = 5, Name = "6t3.blv"}         -- "Temple of Tsantsa"
		end
	end
	
	--Castle Ironfist
	if Map.Name=="outd3.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.map[90] = function()
			local dungeonId="6d03.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -130, Y = -1408, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 425, Icon = 5, Name = "6d03.blv"}         -- "Shadow Guild Hideout"
		end

		Game.MapEvtLines:RemoveEvent(91)
		evt.map[91] = function()
			local dungeonId="6d05.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 1664, Y = -1896, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 430, Icon = 5, Name = "6d05.blv"}         -- "Snergle's Caverns"
		end

		Game.MapEvtLines:RemoveEvent(92)
		evt.map[92] = function()
			local dungeonId="6d06.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 2716, Y = -256, Z = 1, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 432, Icon = 5, Name = "6d06.blv"}         -- "Dragoons' Caverns"
		end

		Game.MapEvtLines:RemoveEvent(93)
		evt.map[93] = function()
			local dungeonId="6d11.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 128, Y = -151, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 440, Icon = 5, Name = "6d11.blv"}         -- "Corlagon's Estate"
		end

		Game.MapEvtLines:RemoveEvent(94)
		evt.map[94] = function()
			local dungeonId="6t1.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -15592, Y = 120, Z = -191, Direction = 0, LookAngle = 0, SpeedZ = 0, HouseId = 418, Icon = 5, Name = "6t1.blv"}         -- "Temple of Baa"
		end
	end
	
	--Eel Infested Waters
	if Map.Name=="oute1.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.map[90] = function()
			local dungeonId="cd1.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -2921, Y = 13139, Z = 225, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 419, Icon = 5, Name = "cd1.blv"}         -- "Castle Alamos"
		end
	end
	
	--Misty Islands
	if Map.Name=="oute2.odm" then
		Game.MapEvtLines:RemoveEvent(90)
		evt.map[90] = function()
			local dungeonId="6d07.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 4427, Y = 3061, Z = 769, Direction = 1024, LookAngle = 0, SpeedZ = 0, HouseId = 434, Icon = 5, Name = "6d07.blv"}         -- "Silver Helm Outpost"
		end
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
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 601, Y = 6871, Z = 177, Direction = 1400, LookAngle = 0, SpeedZ = 0, HouseId = 417, Icon = 5, Name = "6d01.blv"}         -- "Goblinwatch"
		end

		Game.MapEvtLines:RemoveEvent(102)
		evt.map[102] = function()
			local dungeonId="6d02.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = 16406, Y = -19669, Z = 865, Direction = 500, LookAngle = 0, SpeedZ = 0, HouseId = 422, Icon = 1, Name = "6d02.blv"}         -- "Abandoned Temple"
		end

		Game.MapEvtLines:RemoveEvent(103)
		evt.map[103] = function()
			local dungeonId="6d18.blv"
			if canResetDungeon(dungeonId) and not vars.resetDungeon and not questionAsked then
				resetMap(dungeonId)
				return
			end
			evt.MoveToMap{X = -2688, Y = 1216, Z = 1153, Direction = 1536, LookAngle = 0, SpeedZ = 0, HouseId = 447, Icon = 5, Name = "6d18.blv"}         -- "Gharik's Forge"
		end
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
	
	for i=1,651 do
		i=652-i
		if Game.MonstersTxt[monTbl[i].Index].AIType==1 or monTbl[i].Index%3~=0 then
			table.remove(monTbl, i)
		end
	end
	
end

mapDungeons={1,2,3,4,5,6,7,8,9,10,11,12,13,14,16,17,19,21,22,23,24,25,26,27,28,29,30,31,32,33,34,36,37,38,40,41,42,43,44,45,46,47,48,49,51,52,54,55,56,57,62,63,64,65,66,67,68,69,70,71,72,73,75,76,77,78,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,101,104,105,106,108,109,110,111,133,134,135,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,186}

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
	local levelRequired=100
	if vars.madnessMode then
		levelRequired=70
		if vars.ownedMaps>=3 then
			--return disabled, as maps are no longer easily farmable
		end
	end
	
	-- Seeded map drop calculation
	local densityMult = GetDensityMultiplier(mon.Id)
	local dropChance = chances * mon.Level / 100 / (mapvars.mapsDropped + 1) * densityMult
	-- Apply pity protection using new pity system
	dropChance = pity_chance(dropChance, vars.mapDropFailures)
	
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
		possibleMaps={}
		for i=1,#mapDungeons do
			if vars.dungeonCompletedList[Game.MapStats[mapDungeons[i]].Name] then
				table.insert(possibleMaps, mapDungeons[i])
			end
		end
		if table.find(possibleMaps,mapDungeons[math.random(1,#mapDungeons)]) then
			obj.Item.BonusStrength=possibleMaps[math.random(1,#possibleMaps)]
			mapvars.mapsDropped=mapvars.mapsDropped+1
			vars.mapDropFailures=0 -- Reset pity counter on successful drop
			if vars.madnessMode then
				vars.ownedMaps=vars.ownedMaps+1
			end
		else
			obj.Item.Number=0
			obj.Type=0
			obj.TypeIndex=0
		end
		if math.random()<1 then
			obj.Item.Bonus2=getUniqueAffix()
		end
		if math.random()<0.6 then
			obj.Item.Charges=getUniqueAffix()
		end
		if math.random()<0.5 then
			obj.Item.Charges=obj.Item.Charges+getUniqueAffix()*1000
		end
		if math.random()<0.4 then
			obj.Item.BonusExpireTime=getUniqueAffix()
		end
		obj.Item.MaxCharges=round(getMonsterLevel(mon)/10-math.random(0,3))
		if vars.insanityMode and not vars.madnessMode then
			obj.Item.MaxCharges=math.max(obj.Item.MaxCharges,30)
		end
	elseif getMonsterLevel(mon) >= levelRequired then
		vars.mapDropFailures = vars.mapDropFailures + densityMult
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
		
		mapAffixList={it.BonusExpireTime, it.Bonus2, it.Charges%1000, round(it.Charges/1000), ["Power"]=it.MaxCharges}
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
		local mult=1+it.MaxCharges*nAff/300
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

function calculateAffixPower(n, p)
	local power=false
    if n == 1 then
         power=20+p*1.5
    elseif n == 2 then
		power=10+p*1
	elseif n == 3 then
		power=10+p*1
	elseif n == 4 then
		power=5+p*0.5
	elseif n == 5 then
		power=7+p*0.1
	elseif n == 6 then
		power=7+p*0.1
	elseif n == 7 then
		power=1+p*0.1
	elseif n == 8 then
		power=5+p*0.25
	elseif n == 9 then
		power=15+p*0.5
	elseif n == 10 then
		power=3+p*0.3
	elseif n == 11 then
		power=30+p*1
	elseif n == 12 then
		power=30+p*2
	elseif n == 13 then
		power=30+p*1
	elseif n == 14 then
		power=20+p*1
	elseif n == 15 then
		power=20+p*1.5
	elseif n == 16 then
		power=40+p*2
	elseif n == 17 then
		power=20+p*0.5
	elseif n == 18 then
		power=15+p*1
	elseif n == 19 then
		power=10+p*0.2
	elseif n == 20 then
		power=10+p*0.2
	elseif n == 21 then
		power=10+p*0.2
	elseif n == 22 then
		power=20+p
	elseif n == 23 then
		power=15+p*0.5
	elseif n == 24 then
		power=15+p*0.5
	elseif n == 25 then
		power=15+p*0.5
	elseif n == 26 then
		power=15+p*0.5
	elseif n == 27 then
		power=15+p*0.5
	elseif n == 28 then
		power=15+p*0.5
	elseif n == 29 then
		power=15+p*0.5
	elseif n == 30 then
		power=15+p*0.5
	elseif n == 31 then
		power=15+p*0.5
	elseif n == 32 then
		power=15+p*0.5
	elseif n == 33 then
		power=15+p*0.5
    else
        return false
    end
	--reductions can eventually go to 0, fix
	local reductionAffix={13,21,22,23,24,25,26,27,28,29,30,31,32,33}
	if table.find(reductionAffix,n) then
		power=round((1-1/(power/100+1))*10000)/100
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
function events.BuildItemInformationBox(t)
	local it=t.Item
	if it.Number==290 and t.Enchantment then
		local baseMap=mapLevels[Game.MapStats[it.BonusStrength].Name]
		local baseLevel=round((baseMap.Low+baseMap.Mid+baseMap.High)/3)
		t.Enchantment="Map Level: " .. it.MaxCharges*10+20+baseLevel
		local power=0
		if it.BonusExpireTime>0 then
			power=power+1
		end
		if it.Bonus2>0 then
			power=power+1
		end
		if it.Charges>0 then
			power=power+1
			if it.Charges>=1000 then
				power=power+1
			end
		end
		t.Enchantment=t.Enchantment .. StrColor(0, 127, 255,"\n+" .. round(it.MaxCharges*power/8*1.5) .. "% craft items drop chances "  .. "\n+" .. round(it.MaxCharges*power/4) .. "% item quality " .. "%\n+" .. round(it.MaxCharges*power/3) .. "% monster density")	
	end
	if it.Number==290 and t.Name then
		t.Name=Game.MapStats[it.BonusStrength].Name .. " Map"
	end
	
	if it.Number==290 and t.Description then
		local power=it.MaxCharges
		mapAffixes={
			[0]="",
			[1]="Monsters deal " .. getMapAffixPower(1, power) .. "% increased damage",
			[2]="Monsters have " .. getMapAffixPower(2, power) .. "% critical chance",
			[3]="Monsters have " .. getMapAffixPower(3, power) .. "% chance to cast fireball",
			[4]="Monsters have " .. getMapAffixPower(4, power) .. "% chance to cast dragon breath",
			[5]="Monsters reflect " .. getMapAffixPower(5, power) .. "% of physical damage",
			[6]="Monsters reflect " .. getMapAffixPower(6, power) .. "% of magic damage",
			[7]="Monsters regenerate " .. getMapAffixPower(7, power) .. "%HP per second",
			[8]="Monsters have " .. getMapAffixPower(8, power) .. "% chance to ignore status resistance",
			[9]="Monsters have " .. getMapAffixPower(9, power) .. "% chance to summon a monster upon death",
			[10]="Monsters deal " .. getMapAffixPower(10, power) .. "% of player hp as damage",
			[11]="Monsters have " .. getMapAffixPower(11, power) .. "% increased movement speed",
			[12]="Monsters resistances are increased by " .. getMapAffixPower(12, power),
			[13]="Monsters have " .. getMapAffixPower(13, power) .. "% extra chance to resist control effects",
			[14]="Monsters have " .. getMapAffixPower(14, power) .. "% chance to deal energy damage",
			[15]="Monsters have " .. getMapAffixPower(15, power) .. "% increased HP",
			[16]="Boss density increased by " .. getMapAffixPower(16, power) .. "%",
			[17]="Monsters have " .. getMapAffixPower(17, power) .. "% be an higher tier",
			[18]="Bosses have " .. getMapAffixPower(18, power) .. "% increased HP and damage",
			[19]="Monsters have " .. getMapAffixPower(19, power) .. "% chance to become a boss",
			[20]="Players critical chance reduced by " .. getMapAffixPower(20, power) .. "%",
			[21]="Players critical damage reduced by " .. getMapAffixPower(21, power) .. "%",
			[22]="Players HP/SP regen reduced by " .. getMapAffixPower(22, power) .. "%",
			[23]="Players physical damage reduced by " .. getMapAffixPower(23, power) .. "%",
			[24]="Players magic damage reduced by " .. getMapAffixPower(24, power) .. "%",
			[25]="Players movement speed reduced by " .. getMapAffixPower(25, power) .. "%",
			[26]="Players attack speed reduced by " .. getMapAffixPower(26, power) .. "%",
			[27]="Players spell recovery speed increased by " .. getMapAffixPower(27, power) .. "%",
			[28]="Players armor reduced by " .. getMapAffixPower(28, power) .. "%",
			[29]="Players resistances reduced by " .. getMapAffixPower(29, power) .. "%",
			[30]="Players have a " .. getMapAffixPower(30, power) .. "% chance to miss attacks",
			[31]="Healing reduced by " .. getMapAffixPower(31, power) .. "%",
			[32]="Leech reduced by " .. getMapAffixPower(32, power) .. "%",
			[33]="Buff effects reduced by " .. getMapAffixPower(33, power) .. "%",
		}
		
		local txt=""
		if it.BonusExpireTime>0 then
			txt=mapAffixes[it.BonusExpireTime] .. "\n" .. txt
		end
		if it.Bonus2>0 then
			txt=mapAffixes[it.Bonus2] .. "\n" .. txt
		end
		if it.Charges>0 then
			txt=mapAffixes[it.Charges%1000] .. "\n" .. txt
			if it.Charges>=1000 then
				txt=mapAffixes[math.floor(it.Charges/1000)] .. "\n" .. txt
			end
		end
		t.Description=StrColor(255,255,153,txt)
		t.Description=t.Description .. "\nUsing this map will teleport you to the entrance."
	end
end

function events.LoadMap()
	if vars.madnessMode then
		vars.ownedMaps=vars.ownedMaps or 0
		vars.ownedMaps=math.max(vars.ownedMaps,0)
	end
end

--remove dropped maps
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
