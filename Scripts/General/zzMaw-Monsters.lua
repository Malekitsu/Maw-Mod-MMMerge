----------------------------------------------------
--Empower Monsters
----------------------------------------------------
--function to calculate the level you are (float number) give x amount of experience
local function calcLevel(x)
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
--DO THE SAME BUT FOR UNIQUE MONSTERS
--------------------------------------

function events.AfterLoadMap()	
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
			if  (Map.Monsters[i].FullHitPoints ~= Game.MonstersTxt[Map.Monsters[i].Id].FullHitPoints) and Map.Monsters[i].Level>5 then
				mon=Map.Monsters[i]

				--level increase 
				oldLevel=mon.Level
				mon.Level=math.min(mon.Level+partyLvl,255)
				--HP calculated based on previous HP rapported to the previous level
				HPRateo=mon.HP/oldLevel*(oldLevel/10+3)
				mon.HP=math.min(math.round(mon.Level*(mon.Level/10+3)*2*(1+mon.Level/180))*HPRateo,32500)
				mon.FullHP=mon.HP
				--damage
				dmgMult=(mon.Level/20+1.25)*((mon.Level^1.15-1)/1000+1)*((mon.Level^1.25-1)/1000+1)	
	
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

function events.CalcDamageToPlayer(t)
	data=WhoHitPlayer()
	if data and data.Monster and data.Object and data.Object.Spell<100 then
		dmgMult=(data.Monster.Level/16+0.75)
		if ItemRework==true  then
			dmgMult=dmgMult*((data.Monster.Level^1.15-1)/1000+1)
		end
		if StatsRework==true then
			dmgMult=dmgMult*((data.Monster.Level^1.25-1)/1000+1)
		end			
		t.Result=t.Result
	end
end




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
vars.MM6EXPBEFORE=0
vars.MM7EXPBEFORE=0
vars.MM8EXPBEFORE=0
vars.MM6LVL=0
vars.MM7LVL=0
vars.MM8LVL=0
vars.MMMLVL=0
end

function events.LeaveMap()
	local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	local exp=Party[0].Experience
	if currentWorld==1 then
		vars.MM8LVL=vars.MM8LVL+calcLevel(exp)-calcLevel(vars.MM8EXPBEFORE)
	elseif currentWorld==2 then
		vars.MM7LVL=vars.MM7LVL+calcLevel(exp)-calcLevel(vars.MM7EXPBEFORE)
	elseif currentWorld==3 then
		vars.MM6LVL=vars.MM6LVL+calcLevel(exp)-calcLevel(vars.MM6EXPBEFORE)
	elseif currentWorld==4 then
		vars.MMMLVL=vars.MMMLVL+calcLevel(exp)-calcLevel(vars.MMMEXPBEFORE)
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
		mon.HP=math.min(math.round(mon.Level*(mon.Level/10+3)*2),32500)
		if ItemRework and StatsRework then
			mon.HP=math.min(math.round(mon.HP*(1+mon.Level/180),32500))
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
		mon.Experience = math.round(mon.Level*(mon.Level+10))
		--Gold
		levelMultiplier = (mon.Level) / (LevelB)
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
		dmgMult=(levelMult/18+1.25)*((levelMult+2)/(2+LevelB))*((levelMult^1.25-1)/1000+1)*((levelMult^1.25-1)/1000+1)
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
