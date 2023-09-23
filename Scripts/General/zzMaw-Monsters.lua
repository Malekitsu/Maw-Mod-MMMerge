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
		lvlMult=(mon.Level+5)/(basetable[Map.Monsters[i].Id].Level+5)
		mon.TreasureDiceCount=Game.MonstersTxt[Map.Monsters[i].Id].TreasureDiceCount*lvlMult
		mon.TreasureDiceSides=Game.MonstersTxt[Map.Monsters[i].Id].TreasureDiceSides*lvlMult
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
		if partyLvl>=120 then 
			partyLvl=120+(partyLvl-120)/2
		end
		--calculate average level for unique monsters
		for i=0, Map.Monsters.High do
			--gold fix
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
				dmgMult=(mon.Level/15+1.5)*((mon.Level^1.3-1)/1000+1)^2
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
				--END DAMAGE CALCULATION
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
	if bolsterLevel>=120 then 
		bolsterLevel=120+(bolsterLevel-120)/2
	end
				 
	for i=1, 651 do
		
		--calculate level scaling
		mon=Game.MonstersTxt[i]
		base=basetable[i]		
		LevelB=BLevel[i]
		
		--level increase centered on B type
		mon.Level=math.min(basetable[i].Level+bolsterLevel,255)
		
		--HP
		HPBolsterLevel=basetable[i].Level*(1+(0.75*bolsterLevel/100))+bolsterLevel*0.75
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
			mon.Resistances[v]=math.min(math.round((mon.Level-basetable[i].Level)/18)*5+basetable[i].Resistances[v],65000)	
			end
		end
		
		--experience
		mon.Experience = math.round(mon.Level^1.8+mon.Level*20)
		--Gold
		--levelMultiplier = (mon.Level) / (LevelB)
		--mon.TreasureDiceCount=math.min(mon.TreasureDiceCount*levelMultiplier,250)
		--mon.TreasureDiceSides=math.min(mon.TreasureDiceSides*levelMultiplier,250)
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
		
		mon.ArmorClass=mon.ArmorClass*((levelMult+10)/(LevelB+10))
		mon.ArmorClass=mon.Level
		dmgMult=(levelMult/15+1.5)*((levelMult+2)/(2+LevelB))*((levelMult^1.3-1)/1000+1)^2
		-----------------------------------------------------------
		--DAMAGE COMPUTATION DOWN HERE, FOR BALANCE MODIFY ABOVE^
		--attack 1
		a=0
		b=0
		c=0
		d=0
		e=0
		f=0
		a=basetable[i].Attack1.DamageAdd * dmgMult
		mon.Attack1.DamageAdd = basetable[i].Attack1.DamageAdd * dmgMult
		b=basetable[i].Attack1.DamageDiceSides * dmgMult^0.5
		if dmgMult<4 then
			mon.Attack1.DamageDiceSides = basetable[i].Attack1.DamageDiceSides * dmgMult
			mon.Attack1.DamageDiceCount = basetable[i].Attack1.DamageDiceCount
		else
			mon.Attack1.DamageDiceSides = basetable[i].Attack1.DamageDiceSides * dmgMult^0.5
			mon.Attack1.DamageDiceCount = basetable[i].Attack1.DamageDiceCount * dmgMult^0.5
		end
		--attack 2
		c=mon.Attack2.DamageAdd * dmgMult
		mon.Attack2.DamageAdd = basetable[i].Attack2.DamageAdd * dmgMult
		d=mon.Attack2.DamageDiceSides * dmgMult^0.5
		mon.Attack2.DamageDiceSides = basetable[i].Attack2.DamageDiceSides * dmgMult^0.5
		mon.Attack2.DamageDiceCount = basetable[i].Attack2.DamageDiceCount * dmgMult^0.5

		-------------------------
		--END DAMAGE CALCULATION
		-------------------------
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
for i=1, 60 do
	local map=Game.MapStats[i]
	if map.
	

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
end
