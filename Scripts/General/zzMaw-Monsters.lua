----------------------------------------------------
--Empower Monsters
----------------------------------------------------
--function to calculate the level you are (float number) give x amount of experience
function calcLevel(x)
	local level=((500+(250000+2000*x)^0.5)/1000)
	return level
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
	end	
	for i=0, Map.Monsters.High do
		local mon=Map.Monsters[i]
		if not basetable[Map.Monsters[i].Id] then 
			goto continue
		end
		lvlMult=(mon.Level+5)/(basetable[Map.Monsters[i].Id].Level+5)
		mon.TreasureDiceCount=Game.MonstersTxt[Map.Monsters[i].Id].TreasureDiceCount*lvlMult
		mon.TreasureDiceSides=Game.MonstersTxt[Map.Monsters[i].Id].TreasureDiceSides*lvlMult
		:: continue :: 
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
			
			if  (mon.FullHitPoints ~= Game.MonstersTxt[Map.Monsters[i].Id].FullHitPoints) and mon.Level>5 then
				--level increase 
				oldLevel=mon.Level
				mon.Level=math.min(mon.Level+partyLvl,255)
				--HP calculated based on previous HP rapported to the previous level
				HPRateo=mon.HP/(oldLevel*(oldLevel/10+3))
				HPBolsterLevel=oldLevel*(1+(0.75*partyLvl/100))+partyLvl*0.75
				mon.HP=math.min(math.round(HPBolsterLevel*(HPBolsterLevel/10+3)*2*(1+HPBolsterLevel/180))*HPRateo,32500)
				mon.FullHP=mon.HP
				--damage
				dmgMult=(mon.Level/9+1.15)*((mon.Level+2)/(oldLevel+2))
				-----------------------------------------------------------
				--DAMAGE COMPUTATION DOWN HERE, FOR BALANCE MODIFY ABOVE^
				--attack 1
				a=mon.Attack1.DamageAdd * dmgMult
				mon.Attack1.DamageAdd = mon.Attack1.DamageAdd * dmgMult
				b=mon.Attack1.DamageDiceSides * dmgMult^0.5
				mon.Attack1.DamageDiceSides = mon.Attack1.DamageDiceSides * dmgMult^0.5
				mon.Attack1.DamageDiceCount = mon.Attack1.DamageDiceCount * dmgMult^0.5
				--attack 2
				c=mon.Attack2.DamageAdd * dmgMult
				mon.Attack2.DamageAdd = mon.Attack2.DamageAdd * dmgMult
				d=mon.Attack2.DamageDiceSides * dmgMult
				mon.Attack2.DamageDiceSides = mon.Attack2.DamageDiceSides * dmgMult^0.5
				mon.Attack2.DamageDiceCount = mon.Attack2.DamageDiceCount * dmgMult^0.5
				--OVERFLOW FIX
				--Attack 1 Overflow fix
				--add damage fix
				a=0
				b=0
				c=0
				d=0
				e=0
				f=0
				if (a > 250) then
				Overflow = a - 250
				mon.Attack1.DamageAdd = 250
				b=b + (math.round(2*Overflow/mon.Attack1.DamageDiceCount))
				mon.Attack1.DamageDiceSides = b 
				end
				--Dice Sides fix
				if (b > 250) then
				Overflow = b / 250
				mon.Attack1.DamageDiceSides = 250
				--checking for dice count overflow
				e = mon.Attack1.DamageDiceCount * Overflow
				mon.Attack1.DamageDiceCount = mon.Attack1.DamageDiceCount * Overflow
				end
				--Just in case Dice Count fix
				if not (e == nil) then
					if (e > 250) then
					mon.Attack1.DamageDiceCount = 250
					end
				end
				--Attack 2 Overflow fix, same formula
				--add damage fix
				if (c > 250) then
				Overflow = c - 250
				mon.Attack2.DamageAdd = 250
				d=d + (math.round(2*Overflow/mon.Attack2.DamageDiceCount))
				mon.Attack2.DamageDiceSides = d
				end
				--Dice Sides fix
				if (d > 250) then
				Overflow = d / 250
				mon.Attack2.DamageDiceSides = 250
				--checking for dice count overflow
				f=mon.Attack2.DamageDiceCount * Overflow
				mon.Attack2.DamageDiceCount = mon.Attack2.DamageDiceCount * Overflow
				end
				--Just in case Dice Count fix
				if not (f ==nil) then
					if (f > 250) then
					mon.Attack2.DamageDiceCount = 250
					end
				end
				-------------------------
				--end DAMAGE CALCULATION
				-------------------------
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
		--[[
		basetable[i].FireResistance=Game.MonstersTxt[i].FireResistance
		basetable[i].AirResistance=Game.MonstersTxt[i].AirResistance
		basetable[i].WaterResistance=Game.MonstersTxt[i].WaterResistance
		basetable[i].EarthResistance=Game.MonstersTxt[i].EarthResistance
		basetable[i].MindResistance=Game.MonstersTxt[i].MindResistance
		basetable[i].SpiritResistance=Game.MonstersTxt[i].SpiritResistance
		basetable[i].BodyResistance=Game.MonstersTxt[i].BodyResistance
		basetable[i].LightResistance=Game.MonstersTxt[i].LightResistance
		basetable[i].DarkResistance=Game.MonstersTxt[i].DarkResistance
		basetable[i].PhysResistance=Game.MonstersTxt[i].PhysResistance	
		]]
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
vars.MM6LVL=0
vars.MM7LVL=0
vars.MM8LVL=0
vars.MMMLVL=0
end


function events.LeaveMap()
	local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	Exp=Party[0].Experience
	if currentWorld==1 then
		currentExp=calcLevel(Exp)
		vars.MM8LVL=vars.MM8LVL+currentExp-vars.LVLBEFORE
		vars.LVLBEFORE=currentExp
	elseif currentWorld==2 then
		currentExp=calcLevel(Exp)
		vars.MM7LVL=vars.MM7LVL+currentExp-vars.LVLBEFORE
		vars.LVLBEFORE=currentExp
	elseif currentWorld==3 then
		currentExp=calcLevel(Exp)
		vars.MM6LVL=vars.MM6LVL+currentExp-vars.LVLBEFORE
		vars.LVLBEFORE=currentExp
	elseif currentWorld==4 then
		currentExp=calcLevel(Exp)
		vars.MMMLVL=vars.MMMLVL+currentExp-vars.LVLBEFORE
		vars.LVLBEFORE=currentExp
	end
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
	else
		debug.Message("You are in an unknown world, report this bug in MAW discord")
	end
	bolsterLevel=math.max(bolsterLevel*0.95-4,0)
	
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
		if Game.MonstersTxt[currentMapMonsters[1]].Level>Game.MonstersTxt[currentMapMonsters[2]].Level then
			currentMapMonsters[1], currentMapMonsters[2] = currentMapMonsters[2], currentMapMonsters[1]
		end
		if #currentMapMonsters==3 then
			if Game.MonstersTxt[currentMapMonsters[2]].Level > Game.MonstersTxt[currentMapMonsters[3]].Level then
				currentMapMonsters[3], currentMapMonsters[2] = currentMapMonsters[2], currentMapMonsters[3]
			end
			if Game.MonstersTxt[currentMapMonsters[1]].Level>Game.MonstersTxt[currentMapMonsters[2]].Level then
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
		
		--HP
		HPBolsterLevel=basetable[i].Level*(1+(0.25*(bolsterLevel+extraBolster)/100))+(bolsterLevel+extraBolster)*0.75
		mon.HP=math.min(math.round(HPBolsterLevel*(HPBolsterLevel/10+3)*2),32500)
		if ItemRework and StatsRework then
			mon.HP=math.min(math.round(mon.HP*(1+HPBolsterLevel/180),32500))
		end
		mon.FullHP=mon.HP
		--[[resistances
		Game.MonstersTxt[i].FireResistance=base.FireResistance+(math.round(mon.Level-base.Level)/18)*5
		Game.MonstersTxt[i].AirResistance=base.AirResistance+(math.round(mon.Level-base.Level)/18)*5
		Game.MonstersTxt[i].WaterResistance=base.WaterResistance+(math.round(mon.Level-base.Level)/18)*5
		Game.MonstersTxt[i].EarthResistance=base.EarthResistance+(math.round(mon.Level-base.Level)/18)*5
		Game.MonstersTxt[i].MindResistance=base.MindResistance+(math.round(mon.Level-base.Level)/18)*5
		Game.MonstersTxt[i].SpiritResistance=base.SpiritResistance+(math.round(mon.Level-base.Level)/18)*5
		Game.MonstersTxt[i].BodyResistance=base.BodyResistance+(math.round(mon.Level-base.Level)/18)*5
		Game.MonstersTxt[i].LightResistance=base.LightResistance+(math.round(mon.Level-base.Level)/18)*5
		Game.MonstersTxt[i].DarkResistance=base.DarkResistance+(math.round(mon.Level-base.Level)/18)*5
		Game.MonstersTxt[i].PhysResistance=base.PhysResistance+(math.round(mon.Level-base.Level)/18)*5
		--]]
		for v=0,10 do
			if v~=5 then
			mon.Resistances[v]=math.min(math.max(math.round((mon.Level-basetable[i].Level)/18)*5,0)+basetable[i].Resistances[v],65000)	
			end
		end
		
		--experience
		mon.Experience = math.round(mon.Level^1.7+mon.Level*20)
	end
	--CALCULATE DAMAGE AND HP
	for i=1, 651 do
		mon=Game.MonstersTxt[i]
		base=basetable[i]		
		LevelB=BLevel[i]
		
		--ADJUST HP
		hpMult=1
		if i%3==1 then
			lvl=Game.MonstersTxt[i+2].Level
			if mon.Level*2<=lvl then
				hpMult=hpMult+lvl/(mon.Level*5)
			end
		elseif i%3==2 then
			lvl=Game.MonstersTxt[i+1].Level
			if Game.MonstersTxt[i-1].Level*2<=lvl then
				hpMult=hpMult+lvl/(mon.Level*5)
			end
		end
		mon.HP=mon.HP*hpMult
		mon.FullHP=mon.HP
		--damage
		if i%3==1 then
			levelMult=Game.MonstersTxt[i+1].Level
		elseif i%3==0 then
			levelMult=Game.MonstersTxt[i-1].Level
		else
			levelMult=Game.MonstersTxt[i].Level
		end
		
		mon.ArmorClass=base.ArmorClass*((levelMult+10)/(LevelB+10))
		mon.ArmorClass=mon.Level
		dmgMult=(levelMult/9+1.15)*((levelMult+2)/(2+LevelB))	
		-----------------------------------------------------------
		--DAMAGE COMPUTATION DOWN HERE, FOR BALANCE MODIFY ABOVE^
		--attack 1
		a=base.Attack1.DamageAdd * dmgMult
		mon.Attack1.DamageAdd = base.Attack1.DamageAdd * dmgMult
		b=base.Attack1.DamageDiceSides * dmgMult^0.5
		mon.Attack1.DamageDiceSides = base.Attack1.DamageDiceSides * dmgMult^0.5
		e=base.Attack1.DamageDiceCount * dmgMult^0.5
		mon.Attack1.DamageDiceCount = base.Attack1.DamageDiceCount * dmgMult^0.5
		--attack 2
		c=base.Attack2.DamageAdd * dmgMult
		mon.Attack2.DamageAdd = base.Attack2.DamageAdd * dmgMult
		d=base.Attack2.DamageDiceSides * dmgMult^0.5
		mon.Attack2.DamageDiceSides = base.Attack2.DamageDiceSides * dmgMult^0.5
		f=base.Attack2.DamageDiceCount * dmgMult^0.5
		mon.Attack2.DamageDiceCount = base.Attack2.DamageDiceCount * dmgMult^0.5
		--OVERFLOW FIX
		--Attack 1 Overflow fix
		--add damage fix
		if (a > 250) then
		Overflow = a - 250
		mon.Attack1.DamageAdd = 250
		b=b + (math.round(2*Overflow/mon.Attack1.DamageDiceCount))
		mon.Attack1.DamageDiceSides = b 
		end
		--Dice Sides fix
		if (b > 250) then
		Overflow = b / 250
		mon.Attack1.DamageDiceSides = 250
		--checking for dice count overflow
		e = e * Overflow
		mon.Attack1.DamageDiceCount = e
		end
		--Just in case Dice Count fix
		if (e > 250) then
		mon.Attack1.DamageDiceCount = 250
		end
		--Attack 2 Overflow fix, same formula
		--add damage fix
		if (c > 250) then
		Overflow = c - 250
		mon.Attack2.DamageAdd = 250
		d=d + (math.round(2*Overflow/mon.Attack2.DamageDiceCount))
		mon.Attack2.DamageDiceSides = d
		end
		--Dice Sides fix
		if (d > 250) then
		Overflow = d / 250
		mon.Attack2.DamageDiceSides = 250
		--checking for dice count overflow
		f=f * Overflow
		mon.Attack2.DamageDiceCount = f 
		end
		--Just in case Dice Count fix
		if (f > 250) then
		mon.Attack2.DamageDiceCount = 250
		end
		-------------------------
		--end DAMAGE CALCULATION
		-------------------------
	end
	if bolsterLevel>20 then
		for i=1, 651 do
			--calculate level scaling
			mon=Game.MonstersTxt[i]
			if i%3==1 then
				mon.HP=(mon.HP*0.3+Game.MonstersTxt[i+1].HP*(basetable[i].FullHP/basetable[i+1].FullHP))/1.3
			elseif i%3==0 then
				mon.HP=(mon.HP*0.3+Game.MonstersTxt[i-1].HP*(basetable[i].FullHP/basetable[i-1].FullHP))/1.3
			end
			mon.FullHP=mon.HP
			if mon.FullHP>1000 then
				mon.FullHP=math.round(mon.FullHP/10)*10
			end
		end
	end
	for i=1, 651 do
		mon=Game.MonstersTxt[i]
		if mon.FullHP>=2^15 then
			mon.FullHP=2^15-1
			mon.HP=2^15-1
		end
	end
end

--LOOT FIX
function events.PickCorpse(t)
	--calculate bolster
	lvl=BLevel[mon.Id]
	--calculate gold
	mon=t.Monster
	gold=mon.TreasureDiceCount*(mon.TreasureDiceSides+1)/2
	goldMult=(bolsterLevel+lvl)^1.4/(lvl)^1.4
	mon.TreasureDiceCount=math.min(mon.TreasureDiceCount*goldMult^0.5,255)
	mon.TreasureDiceSides=math.min(mon.TreasureDiceSides*goldMult^0.5,255)
	
	--calculate loot chances
	
	mon.TreasureItemPercent= math.round(mon.TreasureItemPercent^0.85 + (50 - mon.TreasureItemPercent^0.85 / 2) * bolsterLevel / 250)
	
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


function events.GameInitialized2()
	for i=1,Game.MapStats.High do
		if Game.MapStats[i].Mon1Low==1 then
			Game.MapStats[i].Mon1Low=2
		end
		if Game.MapStats[i].Mon1Hi<=3 then
			Game.MapStats[i].Mon1Hi=Game.MapStats[i].Mon1Hi+1
		end 
		if Game.MapStats[i].Mon2Low==1 then
			Game.MapStats[i].Mon2Low=2
		end
		if Game.MapStats[i].Mon2Hi<=3 then
			Game.MapStats[i].Mon2Hi=Game.MapStats[i].Mon2Hi+1
		end 
		if Game.MapStats[i].Mon3Low==1 then
			Game.MapStats[i].Mon3Low=2
		end
		if Game.MapStats[i].Mon3Hi<=3 then
			Game.MapStats[i].Mon3Hi=Game.MapStats[i].Mon3Hi+1
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
{["Low"] = 6 , ["Mid"] = 8 , ["High"] = 11},

["Ravenshore"] = 
{["Low"] = 14 , ["Mid"] = 14 , ["High"] = 17},

["Alvar"] = 
{["Low"] = 18 , ["Mid"] = 20 , ["High"] = 27},

["Ironsand Desert"] = 
{["Low"] = 13 , ["Mid"] = 28 , ["High"] = 36},

["Garrote Gorge"] = 
{["Low"] = 28 , ["Mid"] = 30 , ["High"] = 35},

["Shadowspire"] = 
{["Low"] = 13 , ["Mid"] = 28 , ["High"] = 45},

["Murmurwoods"] = 
{["Low"] = 23 , ["Mid"] = 27 , ["High"] = 35},

["Ravage Roaming"] = 
{["Low"] = 20 , ["Mid"] = 28 , ["High"] = 35},

["Plane of Air"] = 
{["Low"] = 50 , ["Mid"] = 59 , ["High"] = 65},

["Plane of Earth"] = 
{["Low"] = 20 , ["Mid"] = 60 , ["High"] = 65},

["Plane of Fire"] = 
{["Low"] = 49 , ["Mid"] = 55 , ["High"] = 65},

["Plane of Water"] = 
{["Low"] = 30 , ["Mid"] = 65 , ["High"] = 70},

["Regna"] = 
{["Low"] = 31 , ["Mid"] = 31 , ["High"] = 50},

["Plane Between Planes"] = 
{["Low"] = 58 , ["Mid"] = 70 , ["High"] = 70},

["Tutorial"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Abandoned Temple"] = 
{["Low"] = 5 , ["Mid"] = 6 , ["High"] = 7},

["Pirate Outpost"] = 
{["Low"] = 5 , ["Mid"] = 31 , ["High"] = 31},

["Smuggler's Cove"] = 
{["Low"] = 11 , ["Mid"] = 13 , ["High"] = 17},

["Dire Wolf Den"] = 
{["Low"] = 11 , ["Mid"] = 12.5 , ["High"] = 14},

["Merchant House of Alvar"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Escaton's Crystal"] = 
{["Low"] = 80 , ["Mid"] = 90 , ["High"] = 100},

["Wasp Nest"] = 
{["Low"] = 18 , ["Mid"] = 18 , ["High"] = 18},

["Ogre Fortress"] = 
{["Low"] = 17 , ["Mid"] = 20 , ["High"] = 28},

["Troll Tomb"] = 
{["Low"] = 13 , ["Mid"] = 13 , ["High"] = 13},

["Cyclops Larder"] = 
{["Low"] = 36 , ["Mid"] = 36 , ["High"] = 36},

["Chain of Fire"] = 
{["Low"] = 13 , ["Mid"] = 31 , ["High"] = 49},

["Dragon Hunter's Camp"] = 
{["Low"] = 17 , ["Mid"] = 23.5 , ["High"] = 30},

["Dragon Cave"] = 
{["Low"] = 35 , ["Mid"] = 60 , ["High"] = 85},

["Naga Vault"] = 
{["Low"] = 7 , ["Mid"] = 17.5 , ["High"] = 28},

["Necromancers' Guild"] = 
{["Low"] = 13 , ["Mid"] = 28 , ["High"] = 42},

["Mad Necromancer's Lab "] = 
{["Low"] = 13 , ["Mid"] = 42 , ["High"] = 45},

["Vampire Crypt"] = 
{["Low"] = 28 , ["Mid"] = 28 , ["High"] = 28},

["Temple of the Sun"] = 
{["Low"] = 20 , ["Mid"] = 20 , ["High"] = 20},

["Druid Circle"] = 
{["Low"] = 20 , ["Mid"] = 24 , ["High"] = 60},

["Balthazar Lair"] = 
{["Low"] = 30 , ["Mid"] = 44.5 , ["High"] = 59},

["Barbarian Fortress"] = 
{["Low"] = 17 , ["Mid"] = 20 , ["High"] = 28},

["The Crypt of Korbu"] = 
{["Low"] = 28 , ["Mid"] = 41.5 , ["High"] = 55},

["Castle of Air"] = 
{["Low"] = 65 , ["Mid"] = 65 , ["High"] = 65},

["Tomb of Lord Brinne"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Castle of Fire"] = 
{["Low"] = 65 , ["Mid"] = 65 , ["High"] = 65},

["War Camp"] = 
{["Low"] = 13 , ["Mid"] = 55 , ["High"] = 59},

["Pirate Stronghold"] = 
{["Low"] = 17 , ["Mid"] = 31 , ["High"] = 31},

["Abandoned Pirate Keep"] = 
{["Low"] = 28 , ["Mid"] = 31 , ["High"] = 50},

["Passage Under Regna"] = 
{["Low"] = 20 , ["Mid"] = 31 , ["High"] = 50},

["Small Sub Pen"] = 
{["Low"] = 31 , ["Mid"] = 31 , ["High"] = 50},

["Escaton's Palace"] = 
{["Low"] = 58 , ["Mid"] = 64 , ["High"] = 70},

["Prison of the Lord of Air"] = 
{["Low"] = 58 , ["Mid"] = 65 , ["High"] = 80},

["Prison of the Lord of Fire"] = 
{["Low"] = 58 , ["Mid"] = 65 , ["High"] = 100},

["Prison of the Lord of Water"] = 
{["Low"] = 58 , ["Mid"] = 65 , ["High"] = 70},

["Prison of the Lord of Earth"] = 
{["Low"] = 65 , ["Mid"] = 70 , ["High"] = 70},

["Uplifted Library"] = 
{["Low"] = 20 , ["Mid"] = 25 , ["High"] = 30},

["Dark Dwarf Compound"] = 
{["Low"] = 20 , ["Mid"] = 22 , ["High"] = 24},

["Arena"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Ancient Troll Home"] = 
{["Low"] = 23 , ["Mid"] = 25 , ["High"] = 27},

["Grand Temple of Eep"] = 
{["Low"] = 11 , ["Mid"] = 13 , ["High"] = 17},

["Chapel of Eep"] = 
{["Low"] = 11 , ["Mid"] = 13 , ["High"] = 17},

["Church of Eep"] = 
{["Low"] = 11 , ["Mid"] = 13 , ["High"] = 17},

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

--monster tooltips
function events.BuildMonsterInformationBox(t)
	--some statistics here, calculate the standard deviation of dices to get the range of which 95% will fall into
	mean=t.Monster.Attack1.DamageAdd+t.Monster.Attack1.DamageDiceCount*(t.Monster.Attack1.DamageDiceSides+1)/2
	range=(t.Monster.Attack1.DamageDiceSides^2*t.Monster.Attack1.DamageDiceCount/12)^0.5*1.96
	lowerLimit=math.round(math.max(mean-range, t.Monster.Attack1.DamageAdd+t.Monster.Attack1.DamageDiceCount))
	upperLimit=math.round(math.min(mean+range, t.Monster.Attack1.DamageAdd+t.Monster.Attack1.DamageDiceCount*t.Monster.Attack1.DamageDiceSides))
	
	
	if t.Monster.Attack1.Missile == 0 then
		text=string.format(table.find(const.Damage,t.Monster.Attack1.Type) .. "-Melee")
	else
		text=string.format(table.find(const.Damage,t.Monster.Attack1.Type) .. "-Ranged")
	end
	t.Damage.Text=string.format("Attack 00000	050" .. lowerLimit .. "-" .. upperLimit .. " " .. text)
	if t.Monster.Attack2Chance>0 then
		mean=t.Monster.Attack2.DamageAdd+t.Monster.Attack2.DamageDiceCount*(t.Monster.Attack2.DamageDiceSides+1)/2
		range=(t.Monster.Attack2.DamageDiceSides^2*t.Monster.Attack2.DamageDiceCount/12)^0.5*1.96
		lowerLimit=math.round(math.max(mean-range, t.Monster.Attack2.DamageAdd+t.Monster.Attack2.DamageDiceCount))
		upperLimit=math.round(math.min(mean+range, t.Monster.Attack2.DamageAdd+t.Monster.Attack2.DamageDiceCount*t.Monster.Attack2.DamageDiceSides))
		if t.Monster.Attack1.Missile == 0 then
			text=string.format(table.find(const.Damage,t.Monster.Attack1.Type) .. "-Melee")
		else
			text=string.format(table.find(const.Damage,t.Monster.Attack1.Type) .. "-Ranged")
		end
		t.Damage.Text=string.format(t.Damage.Text .. "\n" .. lowerLimit .. "-" .. upperLimit .. " " .. text)
	end
	--spell
	if t.Monster.SpellChance>0 and t.Monster.Spell>0 then
		spellId=t.Monster.Spell
		spell=Game.Spells[spellId]
		name=Game.SpellsTxt[spellId].Name
		skill=SplitSkill(t.Monster.SpellSkill)
		--get damage multiplier
		oldLevel=BLevel[t.Monster.Id]
		local i=t.Monster.Id
		if i%3==1 then
			levelMult=Game.MonstersTxt[i+1].Level
		elseif i%3==0 then
			levelMult=Game.MonstersTxt[i-1].Level
		else
			levelMult=Game.MonstersTxt[i].Level
		end
		dmgMult=(levelMult/12+1)*((levelMult+2)/(oldLevel+2))
		
		--calculate
		mean=spell.DamageAdd+skill*(spell.DamageDiceSides+1)/2
		range=(spell.DamageDiceSides^2*skill/12)^0.5*1.96
		lowerLimit=math.round(math.max(mean-range, spell.DamageAdd+skill)*dmgMult)
		upperLimit=math.round(math.min(mean+range, spell.DamageAdd+skill*spell.DamageDiceSides)*dmgMult)
		
		t.SpellFirst.Text=string.format("Spell00000	040" .. name .. " " .. lowerLimit .. "-" .. upperLimit)
	end
end

