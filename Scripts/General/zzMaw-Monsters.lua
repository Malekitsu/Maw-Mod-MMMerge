----------------------------------------------------
--Empower Monsters
----------------------------------------------------
--function to calculate the level you are (float number) give x amount of experience
function calcLevel(x)
	local level=((500+(250000+2000*x)^0.5)/1000)
	return level
end 
function calcExp(lvl)
	local lvl=lvl-1
	local EXP=lvl*(lvl+1)*500
	return EXP
end 

function events.GameInitialized2()
BLevel={}
	for i=1, 217 do
		table.insert(BLevel,Game.MonstersTxt[(i*3)-1].Level)
		table.insert(BLevel,Game.MonstersTxt[(i*3)-1].Level)
		table.insert(BLevel,Game.MonstersTxt[(i*3)-1].Level)
	end
end
--------------------------------------
--UNIQUE MONSTERS BUFF
--------------------------------------

function events.AfterLoadMap()	
	for i=0, Map.Monsters.High do
		--SPEED
		if Map.Monsters[i].Velocity>150 then
			Map.Monsters[i].Velocity=(Map.Monsters[i].Velocity + (400 - Map.Monsters[i].Velocity) / 2 +100)
		end
		--fix broken spell levels
		if Map.Monsters[i].SpellSkill>64 and Map.Monsters[i].SpellSkill<1024 then
			Map.Monsters[i].SpellSkill=Map.Monsters[i].SpellSkill%64
		end
		--resistances 
		bolsterRes=math.max(math.round((Map.Monsters[i].Level-basetable[Map.Monsters[i].Id].Level)/2),0)
		for v=0,10 do
			if v~=5 then
			hpMult=math.floor(Map.Monsters[i].Resistances[v]/1000)
			Map.Monsters[i].Resistances[v]=math.min(bolsterRes+basetable[Map.Monsters[i].Id].Resistances[v],bolsterRes+200)+1000*hpMult	
			end
		end
	end	
	if mapvars.boosted==nil then
		mapvars.boosted=true
		--calculate party experience
		currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
		if currentWorld==1 then
			partyLvl=vars.MM7LVL+vars.MM6LVL
		elseif currentWorld==2 then
			partyLvl=vars.MM8LVL+vars.MM6LVL
		elseif currentWorld==3 then
			partyLvl=vars.MM8LVL+vars.MM7LVL
		elseif currentWorld==4 then
			partyLvl=vars.MM6LVL+vars.MM7LVL+vars.MM8LVL
		end
		--calculate average level for unique monsters
		for i=0, Map.Monsters.High do
			mon=Map.Monsters[i]
			
			if  mon.NameId >=1 and mon.NameId<220 then
				--level increase 
				oldLevel=mon.Level
				mon.Level=math.min(mon.Level+partyLvl,255)
				--HP calculated based on previous HP rapported to the previous level
				HPRateo=mon.HP/(oldLevel*(oldLevel/10+3))
				HPBolsterLevel=oldLevel*(1+(0.75*partyLvl/100))+partyLvl*0.75
				mon.HP=math.min(math.round(HPBolsterLevel*(HPBolsterLevel/10+3)*2*(1+HPBolsterLevel/180))*HPRateo,32500)
				mon.FullHP=mon.HP
				--damage
				dmgMult=(mon.Level/9+1.15)*((mon.Level+2)/(oldLevel+2))*(1+(mon.Level/200))
				atk1=mon.Attack1
				atk1.DamageAdd, atk1.DamageDiceSides, atk1.DamageDiceCount = calcDices(atk1.DamageAdd,atk1.DamageDiceSides,atk1.DamageDiceCount,dmgMult)
				atk2=mon.Attack2
				atk2.DamageAdd, atk2.DamageDiceSides, atk2.DamageDiceCount = calcDices(atk2.DamageAdd,atk2.DamageDiceSides,atk2.DamageDiceCount,dmgMult)
			end
		end
	end	
end


--MODIFY MONSTERS SPELL DAMAGE
--moved in resistance rework in MAW-STATS


--CREATE OLD TABLE COPY
function events.GameInitialized2()
	basetable={}
	basetable.Attack1={}
	basetable.Attack2={}
	basetable.Resistances={}
	--COPY TABLE
	for i=1,651 do
		basetable[i]={}
		basetable[i].ArmorClass=Game.MonstersTxt[i].ArmorClass
		basetable[i].Attack1={}
		basetable[i].Attack1.DamageAdd=Game.MonstersTxt[i].Attack1.DamageAdd
		basetable[i].Attack1.DamageDiceCount=Game.MonstersTxt[i].Attack1.DamageDiceCount
		basetable[i].Attack1.DamageDiceSides=Game.MonstersTxt[i].Attack1.DamageDiceSides
		basetable[i].Attack1.Missile=Game.MonstersTxt[i].Attack1.Missile
		basetable[i].Attack1.Type=Game.MonstersTxt[i].Attack1.Type
		basetable[i].Attack2={}
		basetable[i].Attack2.DamageAdd=Game.MonstersTxt[i].Attack2.DamageAdd
		basetable[i].Attack2.DamageDiceCount=Game.MonstersTxt[i].Attack2.DamageDiceCount
		basetable[i].Attack2.DamageDiceSides=Game.MonstersTxt[i].Attack2.DamageDiceSides
		basetable[i].Attack2.Missile=Game.MonstersTxt[i].Attack2.Missile
		basetable[i].Attack2.Type=Game.MonstersTxt[i].Attack2.Type
		basetable[i].Exp=Game.MonstersTxt[i].Exp
		basetable[i].Experience=Game.MonstersTxt[i].Experience
		basetable[i].FullHP=Game.MonstersTxt[i].FullHP
		basetable[i].FullHitPoints=Game.MonstersTxt[i].FullHitPoints
		basetable[i].Level=Game.MonstersTxt[i].Level
		basetable[i].TreasureDiceCount=Game.MonstersTxt[i].TreasureDiceCount
		basetable[i].TreasureDiceSides=Game.MonstersTxt[i].TreasureDiceSides
		basetable[i].TreasureItemLevel=Game.MonstersTxt[i].TreasureItemLevel
		basetable[i].TreasureItemPercent=Game.MonstersTxt[i].TreasureItemPercent
		basetable[i].TreasureItemType=Game.MonstersTxt[i].TreasureItemType
		basetable[i].Resistances={}
		for v=0,10 do 
			if v~=5 then
				basetable[i].Resistances[v]=Game.MonstersTxt[i].Resistances[v]
				else
				basetable[i].Resistances[v]=0
			end
		end
	end
end

--MONSTER BOLSTERING
function events.BeforeNewGameAutosave()
vars.UNKNOWNEXP=0
vars.LVLBEFORE=0
vars.EXPBEFORE=0
vars.MM6LVL=0
vars.MM7LVL=0
vars.MM8LVL=0
vars.MMMLVL=0
end

function events.LoadMap()
	vars.EXPBEFORE=vars.EXPBEFORE or calcExp(vars.LVLBEFORE or 1) --for working retroactively
end

function events.MonsterKillExp(t)
	local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	local currentLVL=calcLevel(t.Exp/4 + vars.EXPBEFORE)
		
	if currentWorld==1 then
		vars.MM8LVL = vars.MM8LVL + currentLVL - vars.LVLBEFORE
	elseif currentWorld==2 then
		vars.MM7LVL = vars.MM7LVL + currentLVL - vars.LVLBEFORE
	elseif currentWorld==3 then
		vars.MM6LVL = vars.MM6LVL + currentLVL - vars.LVLBEFORE
	elseif currentWorld==4 then
		vars.MMMLVL = vars.MMMLVL + currentLVL - vars.LVLBEFORE
	end
	vars.EXPBEFORE = vars.EXPBEFORE + t.Exp/4
	vars.LVLBEFORE = calcLevel(vars.EXPBEFORE)
end

function events.LoadMap()
	--calculate party experience
	currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
	if currentWorld==1 then
		bolsterLevel=vars.MM7LVL+vars.MM6LVL
	elseif currentWorld==2 then
		bolsterLevel=vars.MM8LVL+vars.MM6LVL
	elseif currentWorld==3 then
		bolsterLevel=vars.MM8LVL+vars.MM7LVL
	elseif currentWorld==4 then
		bolsterLevel=vars.MM6LVL+vars.MM7LVL+vars.MM8LVL
	end
	bolsterLevel=math.max(bolsterLevel-4,0)
	
	--check for current map monsters
	currentMapMonsters={}
	local index=1
	for i=1, 651 do	
		mon=Game.MonstersTxt[i]
		for v=1,3 do 
			if Game.MapStats[Map.MapStatsIndex]["Monster" .. v .. "Pic"] .. " B" == mon.Picture then
				currentMapMonsters[index]= i
				index=index+1
			end			
		end
	end
	if #currentMapMonsters>=2 then
		if basetable[currentMapMonsters[1]].Level>basetable[currentMapMonsters[2]].Level then
			currentMapMonsters[1], currentMapMonsters[2] = currentMapMonsters[2], currentMapMonsters[1]
		end
		if #currentMapMonsters==3 then
			if basetable[currentMapMonsters[2]].Level > basetable[currentMapMonsters[3]].Level then
				currentMapMonsters[3], currentMapMonsters[2] = currentMapMonsters[2], currentMapMonsters[3]
			end
			if basetable[currentMapMonsters[1]].Level>basetable[currentMapMonsters[2]].Level then
				currentMapMonsters[1], currentMapMonsters[2] = currentMapMonsters[2], currentMapMonsters[1]
			end
		end
	end
	for i=1, 651 do
		--calculate level scaling
		mon=Game.MonstersTxt[i]
		base=basetable[i]		
		LevelB=BLevel[i]
		
		--level increase centered on B type
		mon.Level=math.min(basetable[i].Level+bolsterLevel,255)
		
		--monsters scale based on map
		extraBolster=0
		--scale non map monsters based on MID
		local mapName=Game.MapStats[Map.MapStatsIndex].Name
		if mapLevels[mapName].Mid then
			if LevelB<mapLevels[mapName].Low then
				extraBolster=(mapLevels[mapName].Low-LevelB)/2
			elseif LevelB>mapLevels[mapName].High then
				extraBolster=(mapLevels[mapName].High-LevelB)/2
			end
		end
		
		--scale map monsters
		if #currentMapMonsters>0 then 
			for j=1, #currentMapMonsters do
				if math.abs(i-currentMapMonsters[j])<=1 then
					if j==1 then
						extraBolster=mapLevels[mapName].Low-LevelB
					elseif j==2 and #currentMapMonsters==3 then
						extraBolster=mapLevels[mapName].Mid-LevelB
					elseif j==2 and #currentMapMonsters==2 then
						extraBolster=mapLevels[mapName].High-LevelB
					elseif j==3 then
						extraBolster=mapLevels[mapName].High-LevelB
					end
				end
			end
		end
		
		if mapName=="The Arena" or mapName=="Arena" then
			extraBolster = 0
		end
		mon.Level=math.min(mon.Level+extraBolster,255)
		totalLevel=totalLevel or {}
		totalLevel[i]=basetable[i].Level+bolsterLevel+extraBolster
		--HP
		HPBolsterLevel=basetable[i].Level*(1+(0.1*(bolsterLevel+extraBolster)/100))+(bolsterLevel+extraBolster)*0.9
		HPtable=HPtable or {}
		HPtable[i]=HPBolsterLevel*(HPBolsterLevel/10+3)*2*(1+HPBolsterLevel/180)
		--resistances 
		bolsterRes=math.max(math.round((totalLevel[i]-basetable[i].Level)/2),0)
		for v=0,10 do
			if v~=5 then
			mon.Resistances[v]=math.min(bolsterRes+basetable[i].Resistances[v],bolsterRes+200)
			end
		end
		
		--experience
		mon.Experience = math.round(totalLevel[i]^1.7+totalLevel[i]*20)
		if currentWorld==2 then
			mon.Experience = math.min(mon.Experience*2, mon.Experience+1000)
		end
		--true nightmare nerf
		if Game.BolsterAmount==250 then
			mon.Experience=mon.Experience*0.75
		end
	end
	--CALCULATE DAMAGE AND HP
	for i=1, 651 do
		mon=Game.MonstersTxt[i]
		base=basetable[i]		
		LevelB=BLevel[i]
		
		--ADJUST HP
		hpMult=1
		if i%3==1 then
			lvl=totalLevel[i+2]
			if totalLevel[i]*2<=lvl then
				hpMult=hpMult+lvl/(totalLevel[i]*5)
			end
		elseif i%3==2 then
			lvl=totalLevel[i+1]
			if totalLevel[i-1]*2<=lvl then
				hpMult=hpMult+lvl/(totalLevel[i]*5)
			end
		end
		HPtable[i]=HPtable[i]*hpMult
		--damage
		if i%3==1 then
			levelMult=totalLevel[i+1]
		elseif i%3==0 then
			levelMult=totalLevel[i-1]
		else
			levelMult=totalLevel[i]
		end
		
		bonusDamage=math.max((levelMult^0.88-LevelB^0.88),0)
		if bonusDamage>=20 then
			levelMult=totalLevel[i]
		end
		
		mon.ArmorClass=base.ArmorClass*((levelMult+10)/(LevelB+10))
		
		dmgMult=(levelMult/9+1.15)*(1+(levelMult/200))
		--DAMAGE COMPUTATION
		atk1=base.Attack1
		mon.Attack1.DamageAdd, mon.Attack1.DamageDiceSides, mon.Attack1.DamageDiceCount = calcDices(atk1.DamageAdd,atk1.DamageDiceSides,atk1.DamageDiceCount,dmgMult,bonusDamage)
		atk2=base.Attack2
		mon.Attack2.DamageAdd, mon.Attack2.DamageDiceSides, mon.Attack2.DamageDiceCount = calcDices(atk2.DamageAdd,atk2.DamageDiceSides,atk2.DamageDiceCount,dmgMult,bonusDamage)
	end
	if bolsterLevel>20 then
		for i=1, 651 do
			--calculate level scaling
			mon=Game.MonstersTxt[i]
			if i%3==1 then
				HPtable[i]=(HPtable[i]*0.3+HPtable[i+1]*(basetable[i].FullHP/basetable[i+1].FullHP))/1.3
			elseif i%3==0 then
				mon.HP=(HPtable[i]*0.3+HPtable[i-1]*(basetable[i].FullHP/basetable[i-1].FullHP))/1.3
			end
			
			hpOvercap=0
			while HPtable[i]>32500 do
				HPtable[i]=math.round(HPtable[i]/2)
				hpOvercap=hpOvercap+1
			end
			mon.Resistances[0]=mon.Resistances[0]+hpOvercap*1000
			mon.HP=HPtable[i]
			mon.FullHP=HPtable[i]
			if mon.FullHP>1000 then
				mon.FullHP=math.round(mon.FullHP/10)*10
				mon.HP=math.round(mon.HP/10)*10
			end
		end
	end
	
end

function events.LoadMap()
	--DRAGON BREATH FIX
	for i=1, 651 do
		mon=Game.MonstersTxt[i]
		if mon.Spell==97 then
			s,m=SplitSkill(mon.SpellSkill)
			mon.SpellSkill=JoinSkill(math.ceil(s/2), m)
		elseif mon.Spell==93 then
			s,m=SplitSkill(mon.SpellSkill)
			mon.SpellSkill=JoinSkill(math.ceil(s/1.5), m)
		end
	end
	
end

--LOOT FIX
function events.PickCorpse(t)
	--calculate gold
	mon=t.Monster
	--calculate bolster
	lvl=BLevel[mon.Id]
	gold=mon.TreasureDiceCount*(mon.TreasureDiceSides+1)/2
	newGold=(bolsterLevel+lvl)*7.5
	if mon.Id%3==1 then
		newGold=newGold/2
	elseif mon.Id%3==0 then
		newGold=newGold*2
	end
	if gold>0 and newGold>gold then
		goldMult=(bolsterLevel+lvl)^1.5/(lvl)^1.5
		mon.TreasureDiceCount=math.min(newGold^0.5,255)
		mon.TreasureDiceSides=math.min(newGold^0.5*2,255)
	end
	--calculate loot chances
	if bolsterLevel>50 or mon.TreasureItemPercent>70 then
		mon.TreasureItemPercent= math.round(mon.TreasureItemPercent^0.85 + (50 - mon.TreasureItemPercent^0.85 / 2) * bolsterLevel / 250)
	end
end
-----------------------------
-----MAP MONSTER CHANGES-----
-----------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
> debug.Message(dump(Game.MapStats[1]))
——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
Debug Message
{
	AlertDays = 0,
	EaxEnvironments = 15,
	EncounterChance = 10,
	EncounterChanceM1 = 0,
	EncounterChanceM2 = 100,
	EncounterChanceM3 = 0,
	FileName = "out01.odm",
	FirstVisitDay = 0,
	Lock = 0,
	Mon1Dif = 1,
	Mon1Hi = 5,
	Mon1Low = 2,
	Mon2Dif = 1,
	Mon2Hi = 3,
	Mon2Low = 1,
	Mon3Dif = 1,
	Mon3Hi = 3,
	Mon3Low = 1,
	Monster1Pic = "Lizardmen Warrior",
	Monster2Pic = "Wimpy Pirate Warrior Male",
	Monster3Pic = "Couatl (winged snake)",
	Name = "Dagger Wound Island",
	Per = 0,
	RedbookTrack = 4,
	RefillDays = 672,
	ResetCount = 0,
	StealPerm = 1,
	Trap = 0,
	Tres = 0
}

]]


--MAP CHANGES
--BACKUP
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Create a backup of Game.MapStats
BackupMapStats={}
function events.GameInitialized2()
	for i=1,Game.MapStats.High do
		BackupMapStats[i]={}
		BackupMapStats[i].Mon1Low=Game.MapStats[i].Mon1Low
		BackupMapStats[i].Mon1Hi=Game.MapStats[i].Mon1Hi
		BackupMapStats[i].Mon2Low=Game.MapStats[i].Mon2Low
		BackupMapStats[i].Mon2Hi=Game.MapStats[i].Mon2Hi
		BackupMapStats[i].Mon3Low=Game.MapStats[i].Mon3Low
		BackupMapStats[i].Mon3Hi=Game.MapStats[i].Mon3Hi
		BackupMapStats[i].Mon1Dif=Game.MapStats[i].Mon1Dif
		BackupMapStats[i].Mon2Dif=Game.MapStats[i].Mon2Dif
		BackupMapStats[i].Mon3Dif=Game.MapStats[i].Mon3Dif
	end
end
--BackupMapStats = deepcopy(Game.MapStats)
function events.LoadMap()
	--add difficulty related damage
	if Game.BolsterAmount%50~=0 or Game.BolsterAmount==0 then
		Game.BolsterAmount=100
	end

	--MAW
	if Game.BolsterAmount<=100 then
		for i=1,Game.MapStats.High do
			Game.MapStats[i].Mon1Low=BackupMapStats[i].Mon1Low
			Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi
			Game.MapStats[i].Mon2Low=BackupMapStats[i].Mon2Low
			Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi
			Game.MapStats[i].Mon3Low=BackupMapStats[i].Mon3Low
			Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi
		end
	end
	
	--Hard
	if Game.BolsterAmount==150 then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Hi<=3 then
				Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi+1
			end 
			if Game.MapStats[i].Mon2Hi<=3 then
				Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi+1
			end 
			if Game.MapStats[i].Mon3Hi<=3 then
				Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi+1
			end 
		end
	end
	
	--Hell
	if Game.BolsterAmount==200 then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Low==1 then
				Game.MapStats[i].Mon1Low=2
			end
			if Game.MapStats[i].Mon1Hi<=3 then
				Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi+1
			end 
			if Game.MapStats[i].Mon2Low==1 then
				Game.MapStats[i].Mon2Low=2
			end
			if Game.MapStats[i].Mon2Hi<=3 then
				Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi+1
			end 
			if Game.MapStats[i].Mon3Low==1 then
				Game.MapStats[i].Mon3Low=2
			end
			if Game.MapStats[i].Mon3Hi<=3 then
				Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi+1
			end 
		end
	end
	
	if Game.BolsterAmount==300 then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Hi>1 then
				Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi+3
			end 
			if Game.MapStats[i].Mon2Hi>1 then
				Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi+3
			end 
			if Game.MapStats[i].Mon3Hi>1 then
				Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi+3
			end 
			Game.MapStats[i].Mon1Dif=math.min(BackupMapStats[i].Mon1Dif+2,5)
			Game.MapStats[i].Mon2Dif=math.min(BackupMapStats[i].Mon2Dif+2,5)
			Game.MapStats[i].Mon3Dif=math.min(BackupMapStats[i].Mon3Dif+2,5)
		end
	end
	
	--individual map CHANGES-----
	--hall under the hill
	Game.MapStats[96].Monster2Pic="Will ' O Wisp"
	Game.MapStats[96].Monster3Pic="Unicorn"
	Game.MapStats[96].Mon3Low=1
	Game.MapStats[96].Mon3Hi=3
end

--fix to monsters AI (zombies and ghouls)
function events.GameInitialized2()
	Game.HostileTxt[152][0]=4
	Game.HostileTxt[143][0]=4
	Game.HostileTxt[152][143]=0
	Game.HostileTxt[143][152]=0
end

--map levels
mapLevels={
--MM8
["Dagger Wound Island"] = 
{["Low"] = 6 , ["Mid"] = 8 , ["High"] = 8},

["Abandoned Temple"] = 
{["Low"] = 5 , ["Mid"] = 6 , ["High"] = 7},

["Ravenshore"] = 
{["Low"] = 14 , ["Mid"] = 14 , ["High"] = 17},

["Smuggler's Cove"] = 
{["Low"] = 11 , ["Mid"] = 13 , ["High"] = 17},

["Dire Wolf Den"] = 
{["Low"] = 14 , ["Mid"] = 14 , ["High"] = 14},

["Chapel of Eep"] = 
{["Low"] = 14 , ["Mid"] = 16 , ["High"] = 20},

["Alvar"] = 
{["Low"] = 21 , ["Mid"] = 24 , ["High"] = 35},

["Ironsand Desert"] = 
{["Low"] = 16 , ["Mid"] = 28 , ["High"] = 36},

["Troll Tomb"] = 
{["Low"] = 18 , ["Mid"] = 18 , ["High"] = 18},

["Garrote Gorge"] = 
{["Low"] = 38 , ["Mid"] = 45 , ["High"] = 50},

["Shadowspire"] = 
{["Low"] = 28 , ["Mid"] = 35 , ["High"] = 45},

["Murmurwoods"] = 
{["Low"] = 23 , ["Mid"] = 27 , ["High"] = 35},

["Ravage Roaming"] = 
{["Low"] = 28 , ["Mid"] = 28 , ["High"] = 35},

["Plane of Air"] = 
{["Low"] = 60 , ["Mid"] = 62 , ["High"] = 65},

["Plane of Earth"] = 
{["Low"] = 70 , ["Mid"] = 75 , ["High"] = 80},

["Plane of Fire"] = 
{["Low"] = 65 , ["Mid"] = 70 , ["High"] = 75},

["Plane of Water"] = 
{["Low"] = 60 , ["Mid"] = 65 , ["High"] = 70},

["Regna"] = 
{["Low"] = 45 , ["Mid"] = 50 , ["High"] = 55},

["Plane Between Planes"] = 
{["Low"] = 85 , ["Mid"] = 90 , ["High"] = 90},

["Tutorial"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Pirate Outpost"] = 
{["Low"] = 45 , ["Mid"] = 51 , ["High"] = 51},

["Merchant House of Alvar"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Escaton's Crystal"] = 
{["Low"] = 70 , ["Mid"] = 80 , ["High"] = 90},

["Wasp Nest"] = 
{["Low"] = 18 , ["Mid"] = 18 , ["High"] = 18},

["Ogre Fortress"] = 
{["Low"] = 20 , ["Mid"] = 24 , ["High"] = 24},

["Cyclops Larder"] = 
{["Low"] = 42 , ["Mid"] = 42 , ["High"] = 42},

["Chain of Fire"] = 
{["Low"] = 31 , ["Mid"] = 40 , ["High"] = 49},

["Dragon Hunter's Camp"] = 
{["Low"] = 35 , ["Mid"] = 40 , ["High"] = 45},

["Dragon Cave"] = 
{["Low"] = 35 , ["Mid"] = 60 , ["High"] = 85},

["Naga Vault"] = 
{["Low"] = 30 , ["Mid"] = 34 , ["High"] = 38},

["Necromancers' Guild"] = 
{["Low"] = 28 , ["Mid"] = 34 , ["High"] = 42},

["Mad Necromancer's Lab "] = 
{["Low"] = 37 , ["Mid"] = 42 , ["High"] = 45},

["Vampire Crypt"] = 
{["Low"] = 42 , ["Mid"] = 42 , ["High"] = 42},

["Temple of the Sun"] = 
{["Low"] = 40 , ["Mid"] = 40 , ["High"] = 40},

["Druid Circle"] = 
{["Low"] = 45 , ["Mid"] = 49 , ["High"] = 60},

["Balthazar Lair"] = 
{["Low"] = 35 , ["Mid"] = 47 , ["High"] = 59},

["Barbarian Fortress"] = 
{["Low"] = 25 , ["Mid"] = 28 , ["High"] = 36},

["The Crypt of Korbu"] = 
{["Low"] = 32 , ["Mid"] = 36 , ["High"] = 40},

["Castle of Air"] = 
{["Low"] = 65 , ["Mid"] = 65 , ["High"] = 65},

["Tomb of Lord Brinne"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Castle of Fire"] = 
{["Low"] = 75 , ["Mid"] = 75 , ["High"] = 75},

["War Camp"] = 
{["Low"] = 65 , ["Mid"] = 70 , ["High"] = 75},

["Pirate Stronghold"] = 
{["Low"] = 50 , ["Mid"] = 55 , ["High"] = 55},

["Abandoned Pirate Keep"] = 
{["Low"] = 50 , ["Mid"] = 55 , ["High"] = 60},

["Passage Under Regna"] = 
{["Low"] = 50 , ["Mid"] = 55 , ["High"] = 60},

["Small Sub Pen"] = 
{["Low"] = 50 , ["Mid"] = 55 , ["High"] = 55},

["Escaton's Palace"] = 
{["Low"] = 80 , ["Mid"] = 90 , ["High"] = 100},

["Prison of the Lord of Air"] = 
{["Low"] = 85 , ["Mid"] = 90 , ["High"] = 100},

["Prison of the Lord of Fire"] = 
{["Low"] = 85 , ["Mid"] = 90 , ["High"] = 100},

["Prison of the Lord of Water"] = 
{["Low"] = 85 , ["Mid"] = 90 , ["High"] = 100},

["Prison of the Lord of Earth"] = 
{["Low"] = 85 , ["Mid"] = 90 , ["High"] = 100},

["Uplifted Library"] = 
{["Low"] = 30 , ["Mid"] = 35 , ["High"] = 40},

["Dark Dwarf Compound"] = 
{["Low"] = 20 , ["Mid"] = 22 , ["High"] = 24},

["Arena"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Ancient Troll Home"] = 
{["Low"] = 23 , ["Mid"] = 25 , ["High"] = 27},

["Grand Temple of Eep"] = 
{["Low"] = 21 , ["Mid"] = 23 , ["High"] = 27},

["Church of Eep"] = 
{["Low"] = 20 , ["Mid"] = 22 , ["High"] = 26},

["Old Loeb's Cave"] = 
{["Low"] = 35 , ["Mid"] = 60 , ["High"] = 85},

["Ilsingore's Cave"] = 
{["Low"] = 35 , ["Mid"] = 60 , ["High"] = 85},

["Yaardrake's Cave"] = 
{["Low"] = 35 , ["Mid"] = 60 , ["High"] = 85},

["NWC"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},


--MM7
["Emerald Island"] = 
{["Low"] = 5 , ["Mid"] = 5 , ["High"] = 5},

["The Temple of the Moon"] = 
{["Low"] = 5 , ["Mid"] = 6 , ["High"] = 8},

["The Dragon's Lair"] = 
{["Low"] = 5 , ["Mid"] = 45 , ["High"] = 85},

["Castle Harmondale"] = 
{["Low"] = 5 , ["Mid"] = 6 , ["High"] = 6},

["Harmondale"] = 
{["Low"] = 6 , ["Mid"] = 11.5 , ["High"] = 17},

["The Barrow Downs"] = 
{["Low"] = 11 , ["Mid"] = 13 , ["High"] = 16},

["Barrow VII"] = 
{["Low"] = 11 , ["Mid"] = 12 , ["High"] = 13},

["Barrow IV"] = 
{["Low"] = 10 , ["Mid"] = 11.5 , ["High"] = 13},

["Barrow II"] = 
{["Low"] = 13 , ["Mid"] = 15 , ["High"] = 17},

["Barrow XIV"] = 
{["Low"] = 17 , ["Mid"] = 18 , ["High"] = 19},

["Barrow III"] = 
{["Low"] = 17 , ["Mid"] = 18 , ["High"] = 19},

["Barrow IX"] = 
{["Low"] = 10 , ["Mid"] = 10.5 , ["High"] = 11},

["Barrow VI"] = 
{["Low"] = 17 , ["Mid"] = 18 , ["High"] = 19},

["Barrow I"] = 
{["Low"] = 17 , ["Mid"] = 18 , ["High"] = 19},

["Barrow VIII"] = 
{["Low"] = 17 , ["Mid"] = 18 , ["High"] = 19},

["Barrow XIII"] = 
{["Low"] = 17 , ["Mid"] = 18 , ["High"] = 19},

["Barrow X"] = 
{["Low"] = 10 , ["Mid"] = 10.5 , ["High"] = 11},

["Barrow XII"] = 
{["Low"] = 10 , ["Mid"] = 11.5 , ["High"] = 13},

["Barrow V"] = 
{["Low"] = 10 , ["Mid"] = 11.5 , ["High"] = 13},

["Barrow XI"] = 
{["Low"] = 13 , ["Mid"] = 15 , ["High"] = 17},

["Barrow XV"] = 
{["Low"] = 13 , ["Mid"] = 15 , ["High"] = 17},

["White Cliff Cave"] = 
{["Low"] = 14 , ["Mid"] = 16 , ["High"] = 18},

["The Hall under the Hill"] = 
{["Low"] = 12 , ["Mid"] = 18 , ["High"] = 24},

["Zokarr's Tomb"] = 
{["Low"] = 17 , ["Mid"] = 18 , ["High"] = 19},

["Deyja"] = 
{["Low"] = 14 , ["Mid"] = 16 , ["High"] = 18},

["The Haunted Mansion"] = 
{["Low"] = 14 , ["Mid"] = 17 , ["High"] = 19},

["The Erathian Sewers"] = 
{["Low"] = 15 , ["Mid"] = 18.5 , ["High"] = 22},

["The Bandit Caves"] = 
{["Low"] = 15 , ["Mid"] = 16 , ["High"] = 17},

["The Tularean Forest"] = 
{["Low"] = 18 , ["Mid"] = 22 , ["High"] = 24},

["Stone City"] = 
{["Low"] = 17 , ["Mid"] = 18.5 , ["High"] = 20},

["Erathia"] = 
{["Low"] = 17 , ["Mid"] = 20 , ["High"] = 23},

["The Tidewater Caverns"] = 
{["Low"] = 18 , ["Mid"] = 20 , ["High"] = 21},

["The Tularean Caves"] = 
{["Low"] = 18 , ["Mid"] = 22 , ["High"] = 28},

["The Red Dwarf Mines"] = 
{["Low"] = 18 , ["Mid"] = 23 , ["High"] = 28},

["Evenmorn Island"] = 
{["Low"] = 24 , ["Mid"] = 27 , ["High"] = 30},

["Grand Temple of the Sun"] = 
{["Low"] = 26 , ["Mid"] = 28 , ["High"] = 30},

["Grand Temple of the Moon"] = 
{["Low"] = 29 , ["Mid"] = 31 , ["High"] = 33},

["The Bracada Desert"] = 
{["Low"] = 25 , ["Mid"] = 29 , ["High"] = 35},

["Tatalia"] = 
{["Low"] = 19 , ["Mid"] = 23.5 , ["High"] = 28},

["Avlee"] = 
{["Low"] = 22 , ["Mid"] = 24 , ["High"] = 28},

["Lord Markham's Manor"] = 
{["Low"] = 28 , ["Mid"] = 44 , ["High"] = 60},

["Fort Riverstride"] = 
{["Low"] = 30 , ["Mid"] = 32 , ["High"] = 37},

["Nighon Tunnels"] = 
{["Low"] = 31 , ["Mid"] = 33 , ["High"] = 35},

["Castle Gryphonheart"] = 
{["Low"] = 31 , ["Mid"] = 36 , ["High"] = 50},

["William Setag's Tower"] = 
{["Low"] = 33 , ["Mid"] = 46.5 , ["High"] = 60},

["Castle Navan"] = 
{["Low"] = 25 , ["Mid"] = 32 , ["High"] = 43},

["The Hall of the Pit"] = 
{["Low"] = 33 , ["Mid"] = 37 , ["High"] = 42},

["The Mercenary Guild"] = 
{["Low"] = 44 , ["Mid"] = 49 , ["High"] = 60},

["The Temple of Baa"] = 
{["Low"] = 38 , ["Mid"] = 44 , ["High"] = 50},

["The School of Sorcery"] = 
{["Low"] = 45 , ["Mid"] = 45 , ["High"] = 45},

["Celeste"] = 
{["Low"] = 35 , ["Mid"] = 39 , ["High"] = 50},

["Watchtower 6"] = 
{["Low"] = 45 , ["Mid"] = 45 , ["High"] = 50},

["Temple of the Dark"] = 
{["Low"] = 47 , ["Mid"] = 50 , ["High"] = 63},

["Clanker's Laboratory"] = 
{["Low"] = 50 , ["Mid"] = 55 , ["High"] = 60},

["The Wine Cellar"] = 
{["Low"] = 42 , ["Mid"] = 45 , ["High"] = 55},

["Castle Gloaming"] = 
{["Low"] = 53 , ["Mid"] = 57 , ["High"] = 62},

["The Walls of Mist"] = 
{["Low"] = 42 , ["Mid"] = 55 , ["High"] = 64},

["The Pit"] = 
{["Low"] = 50 , ["Mid"] = 53 , ["High"] = 55},

["Temple of the Light"] = 
{["Low"] = 42 , ["Mid"] = 48 , ["High"] = 60},

["The Breeding Zone"] = 
{["Low"] = 44 , ["Mid"] = 52 , ["High"] = 70},

["Castle Lambent"] = 
{["Low"] = 55 , ["Mid"] = 55 , ["High"] = 75},

["Thunderfist Mountain"] = 
{["Low"] = 55 , ["Mid"] = 65 , ["High"] = 75},

["The Hidden Tomb"] = 
{["Low"] = 65 , ["Mid"] = 67.5 , ["High"] = 70},

["Shoals"] = 
{["Low"] = 70 , ["Mid"] = 70 , ["High"] = 70},

["Mount Nighon"] = 
{["Low"] = 65 , ["Mid"] = 69 , ["High"] = 85},

["Tunnels to Eeofol"] = 
{["Low"] = 60 , ["Mid"] = 70 , ["High"] = 80},

["The Land of the Giants"] = 
{["Low"] = 70 , ["Mid"] = 75 , ["High"] = 90},

["The Small House"] = 
{["Low"] = 5 , ["Mid"] = 42.5 , ["High"] = 80},

["The Strange Temple"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["The Titans' Stronghold"] = 
{["Low"] = 75 , ["Mid"] = 82.5 , ["High"] = 90},

["Colony Zod"] = 
{["Low"] = 85 , ["Mid"] = 85 , ["High"] = 85},

["The Maze"] = 
{["Low"] = 75 , ["Mid"] = 85 , ["High"] = 89},

["Wromthrax's Cave"] = 
{["Low"] = 90 , ["Mid"] = 90 , ["High"] = 90},

["The Dragon Caves"] = 
{["Low"] = 90 , ["Mid"] = 90 , ["High"] = 90},

["The Lincoln"] = 
{["Low"] = 100 , ["Mid"] = 100 , ["High"] = 100},

["The Arena"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

--MM6
["Sweet Water"] = 
{["Low"] = 70 , ["Mid"] = 85 , ["High"] = 100},

["Paradise Valley"] = 
{["Low"] = 55 , ["Mid"] = 75 , ["High"] = 90},

["Hermit's Isle"] = 
{["Low"] = 36 , ["Mid"] = 55 , ["High"] = 75},

["Kriegspire"] = 
{["Low"] = 40 , ["Mid"] = 45 , ["High"] = 79},

["Blackshire"] = 
{["Low"] = 40 , ["Mid"] = 44 , ["High"] = 50},

["Dragonsand"] = 
{["Low"] = 50 , ["Mid"] = 60 , ["High"] = 90},

["Frozen Highlands"] = 
{["Low"] = 17 , ["Mid"] = 19 , ["High"] = 20},

["Free Haven"] = 
{["Low"] = 6 , ["Mid"] = 12.5 , ["High"] = 19},

["Mire of the Damned"] = 
{["Low"] = 17 , ["Mid"] = 26 , ["High"] = 29},

["Silver Cove"] = 
{["Low"] = 30 , ["Mid"] = 31.5 , ["High"] = 33},

["Bootleg Bay"] = 
{["Low"] = 7 , ["Mid"] = 12 , ["High"] = 12},

["Castle Ironfist"] = 
{["Low"] = 5 , ["Mid"] = 5 , ["High"] = 7},

["Eel Infested Waters"] = 
{["Low"] = 24 , ["Mid"] = 35 , ["High"] = 36},

["Misty Islands"] = 
{["Low"] = 5 , ["Mid"] = 5 , ["High"] = 5},

["New Sorpigal"] = 
{["Low"] = 6 , ["Mid"] = 6 , ["High"] = 6},

["Goblinwatch"] = 
{["Low"] = 5 , ["Mid"] = 5 , ["High"] = 6},

["Abandoned Temple"] = 
{["Low"] = 6 , ["Mid"] = 8 , ["High"] = 10},

["Shadow Guild Hideout"] = 
{["Low"] = 12 , ["Mid"] = 16 , ["High"] = 20},

["Hall of the Fire Lord"] = 
{["Low"] = 6 , ["Mid"] = 13 , ["High"] = 20},

["Snergle's Caverns"] = 
{["Low"] = 30 , ["Mid"] = 32.5 , ["High"] = 35},

["Dragoons' Caverns"] = 
{["Low"] = 18 , ["Mid"] = 20 , ["High"] = 26},

["Silver Helm Outpost"] = 
{["Low"] = 16 , ["Mid"] = 26 , ["High"] = 34},

["Shadow Guild"] = 
{["Low"] = 12 , ["Mid"] = 20 , ["High"] = 66},

["Snergle's Iron Mines"] = 
{["Low"] = 30 , ["Mid"] = 33 , ["High"] = 40},

["Dragoons' Keep"] = 
{["Low"] = 26 , ["Mid"] = 30 , ["High"] = 34},

["Corlagon's Estate"] = 
{["Low"] = 26 , ["Mid"] = 29 , ["High"] = 55},

["Silver Helm Stronghold"] = 
{["Low"] = 5 , ["Mid"] = 12 , ["High"] = 40},

["The Monolith"] = 
{["Low"] = 24 , ["Mid"] = 30 , ["High"] = 40},

["Tomb of Ethric the Mad"] = 
{["Low"] = 26 , ["Mid"] = 29 , ["High"] = 55},

["Icewind Keep"] = 
{["Low"] = 20 , ["Mid"] = 23 , ["High"] = 26},

["Warlord's Fortress"] = 
{["Low"] = 34 , ["Mid"] = 40 , ["High"] = 80},

["Lair of the Wolf"] = 
{["Low"] = 26 , ["Mid"] = 40 , ["High"] = 45},

["Gharik's Forge"] = 
{["Low"] = 39 , ["Mid"] = 39 , ["High"] = 50},

["Agar's Laboratory"] = 
{["Low"] = 35 , ["Mid"] = 40 , ["High"] = 55},

["Caves of the Dragon Riders"] = 
{["Low"] = 60 , ["Mid"] = 70 , ["High"] = 80},

["Temple of Baa"] = 
{["Low"] = 8 , ["Mid"] = 16 , ["High"] = 26},

["Temple of the Fist"] = 
{["Low"] = 5 , ["Mid"] = 10.5 , ["High"] = 16},

["Temple of Tsantsa"] = 
{["Low"] = 10 , ["Mid"] = 12 , ["High"] = 12},

["Temple of the Sun"] = 
{["Low"] = 30 , ["Mid"] = 54.5 , ["High"] = 79},

["Temple of the Moon"] = 
{["Low"] = 10 , ["Mid"] = 30 , ["High"] = 45},

["Supreme Temple of Baa"] = 
{["Low"] = 39 , ["Mid"] = 70 , ["High"] = 70},

["Superior Temple of Baa"] = 
{["Low"] = 30 , ["Mid"] = 50 , ["High"] = 70},

["Temple of the Snake"] = 
{["Low"] = 45 , ["Mid"] = 67.5 , ["High"] = 90},

["Castle Alamos"] = 
{["Low"] = 44 , ["Mid"] = 50 , ["High"] = 50},

["Castle Darkmoor"] = 
{["Low"] = 40 , ["Mid"] = 55 , ["High"] = 80},

["Castle Kriegspire"] = 
{["Low"] = 35 , ["Mid"] = 45 , ["High"] = 79},

["Free Haven Sewer"] = 
{["Low"] = 5 , ["Mid"] = 12 , ["High"] = 16},

["Tomb of VARN"] = 
{["Low"] = 65 , ["Mid"] = 66 , ["High"] = 90},

["Oracle of Enroth"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Control Center"] = 
{["Low"] = 90 , ["Mid"] = 90 , ["High"] = 90},

["The Hive"] = 
{["Low"] = 70 , ["Mid"] = 85 , ["High"] = 100},

["The Arena"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Dragon's Lair"] = 
{["Low"] = 90 , ["Mid"] = 90 , ["High"] = 90},

["pending"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["pending"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["pending"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["pending"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["pending"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["pending"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["pending"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["pending"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["pending"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["pending"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["pending"] = 
{["Low"] = 40 , ["Mid"] = 50 , ["High"] = 50},

["pending"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Devil Outpost"] = 
{["Low"] = 70 , ["Mid"] = 70 , ["High"] = 70},

["New World Computing"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["The Breach"] = 
{["Low"] = 23 , ["Mid"] = 23 , ["High"] = 23},

["The Breach"] = 
{["Low"] = 28 , ["Mid"] = 40 , ["High"] = 65},

["Basement of the Breach"] = 
{["Low"] = 40 , ["Mid"] = 40 , ["High"] = 40},

["The Strange Temple"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

}

--[[
mapLevels={}
text=""
for i=0,#Game.MapStats do
	mapLevels[i]={}
	a=0
	b=0
	c=0
	for v=0,#Game.MonstersTxt do
		if Game.MonstersTxt[v].Picture==string.format(Game.MapStats[i].Monster1Pic .. " B") and Game.MonstersTxt[v].AIType ~= 1 then
			a=Game.MonstersTxt[v].Level
		end
		if Game.MonstersTxt[v].Picture==string.format(Game.MapStats[i].Monster2Pic .. " B") and Game.MonstersTxt[v].AIType ~= 1 then
			b=Game.MonstersTxt[v].Level
		end
		if Game.MonstersTxt[v].Picture==string.format(Game.MapStats[i].Monster3Pic .. " B") and Game.MonstersTxt[v].AIType ~= 1 then
			c=Game.MonstersTxt[v].Level
		end
	end
	if a > b then
    a, b = b, a
	end
	if b > c then
		b, c = c, b
	end
	if a > b then
		a, b = b, a
	end
	
	if b==0 then
		b=c
	end
	if a==0 then
		a=b
		b=(b+c)/2
	end
	
	mapLevels[i]["Low"]=a
	mapLevels[i]["Mid"]=b
	mapLevels[i]["High"]=c
	text=string.format(text .. '["' .. Game.MapStats[i].Name .. '"] = \n{["Low"] = ' .. a .. ' , ["Mid"] = ' .. b .. ' , ["High"] = ' .. c .. '},\n\n'  )
end

]]
baseDamageValue=false
function events.KeyDown(t)
	--base numbers
	if t.Alt then
		baseDamageValue=true
	end	
end
function events.KeyUp(t)
	--base numbers
	if t.Alt then
		baseDamageValue=false
	end	
end
--monster tooltips
function events.BuildMonsterInformationBox(t)
	--mon = t.Monster
	mon=Map.Monsters[Mouse:GetTarget().Index]
	--show level Below HP
	t.ArmorClass.Text=string.format("Level:         " .. mon.Level .. "\n" .. "58992Armor Class0000000000	100?")
	
	--difficulty multiplier
	diff=Game.BolsterAmount/100 or 1
	if diff==0.5 then
		diff=0.7
	end
	if Game.BolsterAmount==300 then
		diff=diff+mon.Level/85
	end
	--some statistics here, calculate the standard deviation of dices to get the range of which 95% will fall into
	mean=mon.Attack1.DamageAdd+mon.Attack1.DamageDiceCount*(mon.Attack1.DamageDiceSides+1)/2
	range=(mon.Attack1.DamageDiceSides^2*mon.Attack1.DamageDiceCount/12)^0.5*1.96
	lowerLimit=math.round(math.max(mean-range, mon.Attack1.DamageAdd+mon.Attack1.DamageDiceCount)*diff)
	upperLimit=math.round(math.min(mean+range, mon.Attack1.DamageAdd+mon.Attack1.DamageDiceCount*mon.Attack1.DamageDiceSides)*diff)
	
	text=string.format(table.find(const.Damage,mon.Attack1.Type))
	if not baseDamageValue and Game.CurrentPlayer>=0 then
		lowerLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack1.Type,lowerLimit))
		upperLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack1.Type,upperLimit))
	end
	t.Damage.Text=string.format("Attack 00000	050" .. lowerLimit .. "-" .. upperLimit .. " " .. text)
	
	if mon.Attack2Chance>0 and Game.CurrentPlayer>=0 then
		mean=mon.Attack2.DamageAdd+mon.Attack2.DamageDiceCount*(mon.Attack2.DamageDiceSides+1)/2
		range=(mon.Attack2.DamageDiceSides^2*mon.Attack2.DamageDiceCount/12)^0.5*1.96
		lowerLimit=math.round(math.max(mean-range, mon.Attack2.DamageAdd+mon.Attack2.DamageDiceCount)*diff)
		upperLimit=math.round(math.min(mean+range, mon.Attack2.DamageAdd+mon.Attack2.DamageDiceCount*mon.Attack2.DamageDiceSides)*diff)
		if not baseDamageValue then
			lowerLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack1.Type,lowerLimit))
			upperLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack1.Type,upperLimit))
		end
		text=string.format(table.find(const.Damage,mon.Attack2.Type))
		
		t.Damage.Text=string.format(t.Damage.Text .. "\n" .. lowerLimit .. "-" .. upperLimit .. " " .. text)
	end
	--spell
	if mon.SpellChance>0 and mon.Spell>0 then
		spellId=mon.Spell
		spell=Game.Spells[spellId]
		name=Game.SpellsTxt[spellId].Name
		skill=SplitSkill(mon.SpellSkill)
		--get damage multiplier
		oldLevel=BLevel[mon.Id]
		local i=mon.Id
		if i%3==1 then
			levelMult=Game.MonstersTxt[i+1].Level
		elseif i%3==0 then
			levelMult=Game.MonstersTxt[i-1].Level
		else
			levelMult=Game.MonstersTxt[i].Level
		end
		dmgMult=(levelMult/9+1)*((levelMult+10)/(oldLevel+10))*(1+(levelMult/200))
		
		--calculate
		mean=spell.DamageAdd+skill*(spell.DamageDiceSides+1)/2
		range=(spell.DamageDiceSides^2*skill/12)^0.5*1.96
		lowerLimit=math.round(math.max(mean-range, spell.DamageAdd+skill)*dmgMult*diff)
		upperLimit=math.round(math.min(mean+range, spell.DamageAdd+skill*spell.DamageDiceSides)*dmgMult*diff)
		if not baseDamageValue and Game.CurrentPlayer>=0 then
			lowerLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack1.Type,lowerLimit))
			upperLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack1.Type,upperLimit))
		end
		t.SpellFirst.Text=string.format("Spell00000	040" .. name .. " " .. lowerLimit .. "-" .. upperLimit)
	end
	
	if mon.Resistances[0]>=1000 then
		res=mon.Resistances[0]%1000
		t.Resistances[1].Text=string.format("Fire\01200000	070" .. res)
		hp=t.Monster.FullHP*2^math.floor(mon.Resistances[0]/1000)
		t.HitPoints.Text=string.format("02016Hit Points0000000000	100" .. hp)
		
	end
end


--disable bolster
function events.LoadMap()
	vars.ExtraSettings.UseMonsterBolster=false
	Game.UseMonsterBolster=false
end

--disable base monster Resistances
function events.CalcDamageToMonster(t)
	t.Result=t.Damage
end

--disable respawn in outside maps (mostly)
outSideMaps={1,2,3,4,5,6,7,8,13, 62,63,64,65,66,67,68,69,70,72,73,74,99,100,140,141,143,144,145,146,147,148,149,150,151}
function events.GameInitialized2()
	for i=1,#outSideMaps do
	Game.MapStats[i].RefillDays=-1
	end
	
	--fix shots being blocked by monsters
	Game.PatchOptions.FixMonstersBlockingShots=true
end

--[[Naga
function events.MonsterSpriteScale(t)
	if t.Monster.FullHP>3205 then
		t.Scale=t.Scale
	end
end
]]

--TRUE NIGHTMARE MODE
function events.CanSaveGame(t)
	if Game.BolsterAmount~=300 then return end
	if (Party.EnemyDetectorYellow or Party.EnemyDetectorRed) and t.SaveKind ~=1 then
		t.Result=false
		Game.ShowStatusText("Can't save now")
	end
end
function events.CanCastLloyd(t)
	if Game.BolsterAmount~=300 then return end
	if Party.EnemyDetectorYellow or Party.EnemyDetectorRed then
		t.Result=false
		Sleep(1)
		Game.ShowStatusText("Can't teleport now")
	end
end
function events.CanCastTownPortal(t)
	if Game.BolsterAmount~=300 then return end
	if Party.EnemyDetectorYellow or Party.EnemyDetectorRed then
		t.Can=false
	end
end	


--resurrect monsters
--new names
function events.GameInitialized2()
	for i=0,Game.MonstersTxt.High do
		Game.PlaceMonTxt[i+300]=string.format("Resurrected " .. Game.MonstersTxt[i].Name)
	end
end
function events.LoadMap()
	if Game.BolsterAmount==300 then
		if Map.IndoorOrOutdoor==1 then
			if mapvars.monsterMap==nil then
				mapvars.monsterMap={["cleared"]=false, ["names"]={}}
				for i=0,Map.Monsters.High do
					mon=Map.Monsters[i]
					if mon.NameId==0 then
						mapvars.monsterMap[i]={["x"] = mon.X, ["y"] = mon.Y, ["z"] = mon.Z, ["exp"]=mon.Exp, ["item"]=mon.TreasureItemPercent, ["gold"]=mon.TreasureDiceSides, ["respawn"]=true}
					else
						mapvars.monsterMap[i]={["respawn"]=false}
					end
				end
			end
		end
	end
end
function events.LeaveMap()
	if Map.IndoorOrOutdoor==1 and mapvars.monsterMap and mapvars.monsterMap.cleared==false then
		if Map.Monsters.Count==0 then return end
		for i=0,#mapvars.monsterMap do
			mon=Map.Monsters[i]
			old=mapvars.monsterMap[i]
			if mon and old and old.respawn and (mon.AIState==const.AIState.Removed or mon.AIState==const.AIState.Dead)  then --no unique monsters respawn
				mon.HP=mon.FullHP
				mon.X, mon.Y, mon.Z=old.x, old.y, old.z 
				mon.AIState=0
				mon.Exp=old.exp or mon.Exp
				mon.Exp=mon.Exp/4
				mon.ShowOnMap=false
				mon.NameId=mon.Id+300
				if mon.AIState==const.AIState.Removed then
					mon.TreasureItemPercent=0 --math.round(old.item/4)
					mon.TreasureDiceSides=0 --math.round(old.gold/4)
					mapvars.MonsterSeed[i] = Game.RandSeed
					for i = 1, 30 do
						Game.Rand()
					end
				end
			end
		end
	end
end

function events.PickCorpse(t)
	if t.Monster.NameId>300 then
		t.Monster.TreasureItemPercent=t.Monster.TreasureItemPercent/4
		t.Monster.TreasureDiceSides=math.round(t.Monster.TreasureDiceSides/4)
	end
end
--check for dungeon clear
function events.MonsterKilled(mon)
	if Map.IndoorOrOutdoor==1 and mapvars.monsterMap and mapvars.completed==nil then
		n=Map.Monsters.Count
		m=1
		if mon.NameId>220 and mon.NameId<300 then
			m=30
		end
		for i=0,Map.Monsters.High do
			monster=Map.Monsters[i]
			if monster.AIState==4 or monster.AIState==5 or monster.AIState==11 or monster.AIState==16 or monster.AIState==17 or monster.AIState==19 or monster.NameId>300 then
				m=m+1
				if monster.NameId>220 and monster.NameId<300 then
					m=m+29
				end
			end
		end
		if m/n>0.95 then
			name=Game.MapStats[Map.MapStatsIndex].Name
			local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
			if currentWorld==1 then
			mapLevel=vars.MM6LVL+vars.MM7LVL
			elseif currentWorld==2 then
				mapLevel=vars.MM8LVL+vars.MM6LVL
			elseif currentWorld==3 then
				mapLevel=vars.MM8LVL+vars.MM7LVL
			else 
				mapLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
			end
			mapLevel=mapLevel+(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3
			experience=math.ceil(m^0.7*(mapLevel^1.7+mapLevel*20)/3/1000)*1000  
			gold=math.ceil(experience^0.9/1000)*1000 
			evt.ForPlayer(0)
			evt.Add{"Gold", Value = gold}
			evt.ForPlayer("All")
			evt.Add{"Experience", Value = experience}
			Message(string.format("Dungeon Completed! You gain " .. experience .. " Exp, " .. gold .. " Gold and a Crafting Item"))
			evt.GiveItem{Id=math.min(1050+math.ceil(Party[0].LevelBase/25+0.5),1060)}
			mapvars.completed=true
			vars.dungeonCompletedList=vars.dungeonCompletedList or {}
			vars.dungeonCompletedList[name]=true
			mapvars.monsterMap.cleared=true
			return
		end
		if mapvars.monsterMap.cleared==false and m/n>=0.8 then
			mapvars.monsterMap.cleared=true
			Message("Monsters are weakened and can no longer resurrect")
		end
	end
end
--ask confirmation and instructions for true nightmare mode
function nightmare()
	if vars.trueNightmare then
		Game.BolsterAmount=300
		return
	end
	if Game.BolsterAmount==250 then
			answer=Question("You activated Nightmare Mode, monsters will be much stronger and you can't save nor teleport away from them, however, items found will be much stronger.\nLeaving a dungeon before killing most of them will cause monsters to respawn.\nClearing a dungeon will grant you extra rewards.\nRespawned monsters give less experience and loot, once True Nightmare is activated there is no way back, are you sure? (yes/no)")		if answer=="yes" or answer=="Yes" or answer=="YES" then
			vars.trueNightmare=true
			Game.BolsterAmount=300
			Sleep(1)
			Message("Welcome to the Nightmare...\nGood luck.. you will need")
		else
			Sleep(1)
			Message("Difficulty reverted to Hell")
			Game.BolsterAmount=200
		end
	end
	--game introduction
	if not vars.introduction then
		vars.introduction=true
		Message("Greeting adventurer!\nYour journey is about to start, but first make sure to check the difficulty settings (ESC-->Controls-->Extra Settings(on the top)-->Bolstering Power)")
	end
end
function events.LoadMap(wasInGame)
	Timer(nightmare, const.Minute/4) 
end

--dungeon entrance level 
function events.GameInitialized2()
	for i=1,109 do 
		name=Game.Houses[340+i].Name
		if mapLevels[name] then
			levelLow=mapLevels[name].Low
			levelHigh=mapLevels[name].High
			Game.TransTxt[46+i]=string.format(Game.TransTxt[46+i] .. "\nLevel Recommended:\n" .. levelLow .. "-" .. levelHigh)
		end
	end
end

--[[BOSSES SKILLS
bosses have baseline more damage, hp, loot, spells and exp
extra abilities:
Extra HP
Summon monsters as a special ability
Inflicts some random status effect (mostly poison3)
has 1 to 4 extra mini bosses
teleport behind party
]]

function events.AfterLoadMap()
	if Map.IndoorOrOutdoor==1 and Game.BolsterAmount==300 then
		if not mapvars.bossGenerated then
			mapvars.bossGenerated=true
			possibleMonsters={}
			bossSpawns=math.ceil((Map.Monsters.Count-30)/150)
			for i=0,Map.Monsters.High do
				if Map.Monsters[i].Id%3==0 then
					table.insert(possibleMonsters,i)
				end
			end
			if bossSpawns>0 then
				for v=1,bossSpawns do
					index=math.random(1, #possibleMonsters)
					generateBoss(possibleMonsters[index],v)
					table.remove(possibleMonsters,index)
				end
			end
		end
	end
	if mapvars.bossNames then
		for key, value in pairs(mapvars.bossNames) do
			Game.PlaceMonTxt[key]=value
		end
	end
end

function generateBoss(index,nameIndex)
	mon=Map.Monsters[index]
	HP=math.round(mon.FullHP*2+math.random()*2)
	hpOvercap=0
	while HP>32500 do
		HP=math.round(HP/2)
		hpOvercap=hpOvercap+1
	end
	mon.Resistances[0]=mon.Resistances[0]+1000*hpOvercap
	mon.FullHP=HP
	mon.HP=mon.FullHP
	mon.Exp=mon.Exp*10
	mon.Level=math.round(math.min(mon.Level*(1.1+math.random()*0.2),255))
	mon.TreasureDiceCount=(mon.Level*100)^0.5
	mon.TreasureDiceSides=(mon.Level*100)^0.5
	mon.TreasureItemPercent=100
	mon.TreasureItemType=math.random(1,12)
	mon.TreasureItemLevel=math.min(mon.TreasureItemLevel+1, 6)
	
	--name and skills
	mon.NameId=220+nameIndex
	mapvars.bossNames=mapvars.bossNames or {}
	mapvars.bossSkillList=mapvars.SkillList or {}
	skill=SkillList[math.random(1,#SkillList)]
	mapvars.bossSkills=mapvars.bossSkills or {}
	mapvars.bossSkills[mon.NameId]=mapvars.bossSkills[mon.NameId] or {}
	table.insert(mapvars.bossSkills[mon.NameId],skill)
	Game.PlaceMonTxt[mon.NameId]=string.format(skill .. " " .. Game.MonstersTxt[mon.Id].Name)
	
	mapvars.bossNames[mon.NameId]=Game.PlaceMonTxt[mon.NameId]
	--damage calculation, need to fix this shit
	dmgMult=1.5+math.random()
	atk1=mon.Attack1
	atk1.DamageAdd, atk1.DamageDiceSides, atk1.DamageDiceCount = calcDices(atk1.DamageAdd,atk1.DamageDiceSides,atk1.DamageDiceCount,dmgMult)
	atk2=mon.Attack2
	atk2.DamageAdd, atk2.DamageDiceSides, atk2.DamageDiceCount = calcDices(atk2.DamageAdd,atk2.DamageDiceSides,atk2.DamageDiceCount,dmgMult)
end

--SKILLS
SkillList={"Summoner","Venomous","Exploding","Thorn","Reflecting","Adamantite","Swapper","Regenerating",} --defensives
--to add: splitting
--on attack skills
function events.GameInitialized2() --to make the after all the other code
	function events.CalcDamageToPlayer(t)
		data=WhoHitPlayer()
		if data and data.Monster and data.Monster.NameId>220 then
			skill = string.match(Game.PlaceMonTxt[data.Monster.NameId], "([^%s]+)")
			if skill=="Summoner" then
				if math.random()<0.4 or t.DamageKind==4 then
					pseudoSpawnpoint{monster = data.Monster.Id-2, x = (Party.X+data.Monster.X)/2, y = (Party.Y+data.Monster.Y)/2, z = Party.Z, count = 1, powerChances = {75, 25, 0}, radius = 64, group = 1}
				end
			elseif skill=="Venomous" then
				t.Player.Poison3=Game.Time
			elseif skill=="Exploding" then
				t.Result=t.Result/2
				aoeDamage=t.Result/Party.Count
				for i=0,Party.High do
					Party[i].HP=Party[i].HP-aoeDamage
					Party[i]:ShowFaceAnimation(24)
				end
			elseif skill=="Swapper" then	
				t.Result=0
				Game.ShowStatusText("*Swap*")
				Party.X, Party.Y, Party.Z, data.Monster.X, data.Monster.Y, data.Monster.Z = data.Monster.X, data.Monster.Y, data.Monster.Z, Party.X, Party.Y, Party.Z
				Party.Direction, data.Monster.Direction=data.Monster.Direction, Party.Direction
			end
		end
	end

	--on damage taken
	function events.CalcDamageToMonster(t)
		if t.Monster.NameId>220 then
			if t.Player then
				local id=t.Player:GetIndex()
				for i=0,Party.High do
					if Party[i]:GetIndex()==id then
						index=i
					end
				end
				skill = string.match(Game.PlaceMonTxt[t.Monster.NameId], "([^%s]+)")
				if skill=="Thorn" then
					if t.DamageKind==4 then
						Party[index]:DoDamage(t.Result*2,4) 
					end
				elseif skill=="Reflecting" then
					if t.DamageKind~=4 then
						Party[index]:DoDamage(t.Result*2,4) 
					end
				elseif skill=="Adamantite" then
					t.Result=math.round(math.max(t.Result-t.Monster.Level^1.15,t.Result/10))
				elseif skill=="Swapper" then
					for i=0,Map.Monsters.High do
						mon=Map.Monsters[i]
						if mon.HP>0 and (mon.NameId<220 or mon.NameId>300) then
							t.Result=0
							Game.ShowStatusText("*Swap*")
							mon.X, mon.Y, mon.Z, t.Monster.X, t.Monster.Y, t.Monster.Z = t.Monster.X, t.Monster.Y, t.Monster.Z, mon.X, mon.Y, mon.Z
						end
					end
				elseif skill=="Regenerating" then
					id=t.Monster:GetIndex()
					mapvars.regenerating=mapvars.regenerating or {}
					mapvars.regenerating[id] = mapvars.regenerating[id] or 0
					mapvars.regenerating[id] = mapvars.regenerating[id] + 1
					if t.Result>t.Monster.HP then
						mapvars.regenerating[id]=-1
					end
				end
			end
		end
	end
end
function calcDices(add,sides,count, mult, bonusDamage)
	local bonusDamage=bonusDamage or 0
	local add=math.round((add+bonusDamage)*mult)
	local sides=math.round(sides*mult^0.5)
	local count=math.round(count*mult^0.5)
	if add > 250 then
		Overflow=add-250
		add=250
		sides=sides + (math.round(2*Overflow/count))
	end
	if sides > 250 then
		Overflow = sides / 250
		sides = 250
		--checking for dice count overflow
		count=math.round(count* Overflow)
	end
	if count > 250 then
		Overflow = count / 250
		count = 250
		--checking for dice count overflow
		sides=math.round(math.min(sides * Overflow,250))
	end
	
	return add, sides, count
end

--fix out of bound monsters
function events.LoadMap(wasInGame)
	function checkOutOfBound()
		if Map.IndoorOrOutdoor==2 then
			for i=0, Map.Monsters.High do
				monster=Map.Monsters[i]
				-- Check and adjust X coordinate
				if monster.X > 22528 then
					monster.X = 22400
				elseif monster.X < -22528 then
					monster.X = -22400
				end

				-- Check and adjust Y coordinate
				if monster.Y > 22528 then
					monster.Y = 22400
				elseif monster.Y < -22528 then
					monster.Y = -22400
				end
			end
		end
	end

	Timer(checkOutOfBound, const.Minute) 
end

--regenerating skill
function eliteRegen()
	if mapvars.regenerating then
		for key, value in pairs(mapvars.regenerating) do	
			if value>0 then
				mon=Map.Monsters[key]
				mon.HP=mon.HP+mon.FullHitPoints*0.01*0.99^value
			end
		end
	end
end

function events.LoadMap(wasInGame)
	Timer(eliteRegen, const.Minute/20) 
end
