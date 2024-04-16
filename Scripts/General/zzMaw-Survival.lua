local survivalMaps={
	["7out01.odm"]=1, -- emerald isle
}
--[[survival mode
function events.GameInitialized2()
	SurvivalModeSwitch=CustomUI.CreateButton{
	IconUp	 	= "TmblrOn",
	IconDown	= "TmblrOff",
	Screen = 21,
	Layer = 1,
	X =	530,
	Y =	10,
	Masked = true,
	Action = function() setSurvival() end,
	}
	setSurvival()
	setSurvival()
end
]]
function setSurvival()
	if SurvivalMode then
		SurvivalMode=false
		SurvivalModeSwitch.IUpSrc="TmblrOff"
		SurvivalModeSwitch.IDwSrc="TmblrOff"
	else
		SurvivalMode=true
		SurvivalModeSwitch.IUpSrc="TmblrOn"
		SurvivalModeSwitch.IDwSrc="TmblrOn"
	end
end

--remove all
function events.LoadMap()
	if survivalMaps[Map.Name] and vars.SuvivalMode then
		Game.MapEvtLines.Count = 0  
		for mid, model in Map.Models do
			for fid, facet in model.Facets do
				facet.Invisible=true
				facet.Untouchable=true
				evt.SetFacetBit{Model = 21, Facet = -1, Bit = const.FacetBits.Invisible, On = false}
				evt.SetFacetBit{Model = 18, Facet = -1, Bit = const.FacetBits.Invisible, On = false}
				evt.SetFacetBit{Model = 12, Facet = -1, Bit = const.FacetBits.Invisible, On = false}
				evt.SetFacetBit{Model = 21, Facet = -1, Bit = const.FacetBits.Untouchable, On = false}
				evt.SetFacetBit{Model = 18, Facet = -1, Bit = const.FacetBits.Untouchable, On = false}
				evt.SetFacetBit{Model = 12, Facet = -1, Bit = const.FacetBits.Untouchable, On = false}
			end
		end
		for i=0,Map.Monsters.High do
			Map.Monsters[i].AIState=19
		end
		currentWave=0
		totalWaves=100
		frequency=currentWave+10
		currentMapLevel=survivalMaps[Map.Name]
	end
end

local survivalMapMonsters={
	["7out01.odm"]={226, 205, 385, 400, 397}, -- emerald isle
}
--spawn monsters
function survivalSpawns()
	if survivalMaps[Map.Name] and currentWave<totalWaves then
		if frequency>0 and (Party.EnemyDetectorYellow or Party.EnemyDetectorRed) then 
			frequency=frequency-1
			return
		end
		currentWave=currentWave+1
		frequency=totalWaves+30-currentWave
		currentMapLevel=currentMapLevel+0.2
		survivalMonsterTable(math.ceil(currentMapLevel))
		--spawn monsters
		local x=math.random(500,3500)
		local y=math.random(500,3500)
		if math.random()>0.5 then
			x=-x
		end
		if math.random()>0.5 then
			y=-y
		end
		monsterType=math.ceil(currentWave/totalWaves*#survivalMapMonsters[Map.Name])
		local spawn=survivalMapMonsters[Map.Name][monsterType]
		local waveLength=totalWaves/#survivalMapMonsters[Map.Name]
		local currentWaveCompletition=(currentWave%waveLength)/waveLength
		local count=math.floor(currentWaveCompletition*5)
		local spawnPower=math.round(currentWaveCompletition*100)
		pseudoSpawnpoint{monster = spawn,  x = Party.X+x, y = Party.Y+y, Z = 0, count = count, powerChances = {50, 35, 15}, radius = 1160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
		goldCollectedSurvival=Party.Gold
		--elite every end of wave
		if currentWaveCompletition==0 then
			pseudoSpawnpoint{monster = spawn,  x = Party.X+x, y = Party.Y+y, Z = 0, count = 1, powerChances = {0, 0, 100}, radius = 1160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
			id=Map.Monsters.High
			generateBoss(id,monsterType)
			frequency=300
			currentMapLevel=currentMapLevel+3
		end
	end
end
function events.LoadMap(wasInGame)
	if vars.SuvivalMode then
		Timer(survivalSpawns, const.Minute/20) --once every 10th of a second
	end
end

--increased size
function events.MonsterSpriteScale(t)
	if survivalMaps[Map.Name] and vars.SuvivalMode then
		t.Scale=t.Scale*1.25
	end
end

function events.DeathMap(t)
	if vars.SuvivalMode then
		t.Name = "oute3.odm"
		Party.X=-9729
		Party.Y=-10555
		Party.Z=160
		Party.Direction=0
		Party.Gold=goldCollectedSurvival
	end
end

function events.BeforeNewGameAutosave()
	if Game.Mode==1 then
		vars.SuvivalMode=true
		vars.survivalTeleport=true
	end
end

function events.Tick()
	if vars.survivalTeleport then
		vars.survivalTeleport=false
		evt.MoveToMap{-9729, -10555, 160, 512, 0, 0, 0, 0, "oute3.odm"}
		Party.Gold=5000
	end
end

--monster balance specifically for survival
function survivalMonsterTable(currentMapLevel)
	
	for i=1, 651 do
		--calculate level scaling
		mon=Game.MonstersTxt[i]
		base=basetable[i]		
		LevelB=BLevel[i]
		
		
		
		mon.Level=math.min(currentMapLevel,255)

		totalLevel=totalLevel or {}
		totalLevel[i]=currentMapLevel
		
		
		--HP
		HPBolsterLevel=basetable[i].Level*(1+(0.1*(totalLevel[i]-basetable[i].Level)/100))+(totalLevel[i]-basetable[i].Level)*0.9
		HPtable=HPtable or {}
		HPtable[i]=HPBolsterLevel*(HPBolsterLevel/10+3)*2*(1+HPBolsterLevel/180)
		--resistances 
		bolsterRes=math.max(math.round((totalLevel[i]-basetable[i].Level)/10)*5,0)
		for v=0,10 do
			if v~=5 then
			mon.Resistances[v]=math.min(bolsterRes+basetable[i].Resistances[v],bolsterRes+200)
			end
		end
		
		--experience
		mon.Experience = math.round(totalLevel[i]^1.8+totalLevel[i]*20)
		if currentWorld==2 then
			mon.Experience = math.min(mon.Experience*2, mon.Experience+1000)
		end
		--true nightmare nerf
		if Game.BolsterAmount==300 then
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
		
		--easy
		if Game.BolsterAmount==0 then
			hpMult=hpMult*0.6
		end	
		--normal
		if Game.BolsterAmount==50 then
			hpMult=hpMult*0.8
		end
		--MAW
		if Game.BolsterAmount==100 then
			hpMult=hpMult*1
		end
		--Hard
		if Game.BolsterAmount==150 then
			hpMult=hpMult*1.4
		end
		--Hell
		if Game.BolsterAmount==200 then
			hpMult=hpMult*1.8
		end
		--Nightmare
		if Game.BolsterAmount==300 then
			hpMult=hpMult*3
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
	--adjust damage if it's too similiar between monster type
	if bolsterLevel>10 or Game.freeProgression==false then
		for i=1, 651 do
			mon=Game.MonstersTxt[i]
			base=basetable[i]		
			LevelB=BLevel[i]
			
			if i%3==1 then
				bMon=basetable[i+1]
			elseif i%3==0 then
				bMon=basetable[i-1]
			else
				bMon=basetable[i]
			end
			bonusDamage=0
			atk1=base.Attack1
			currentBaseDamage=atk1.DamageAdd+atk1.DamageDiceCount*(1+atk1.DamageDiceSides)/2
			batck1=bMon.Attack1
			bBaseDamage=batck1.DamageAdd+batck1.DamageDiceCount*(1+batck1.DamageDiceSides)/2
			dmgMult=math.min(math.max(currentBaseDamage/bBaseDamage,0.75),1.3)
			mon.Attack1.DamageAdd, mon.Attack1.DamageDiceSides, mon.Attack1.DamageDiceCount = calcDices(mon.Attack1.DamageAdd,mon.Attack1.DamageDiceSides,mon.Attack1.DamageDiceCount,dmgMult,bonusDamage)
			
			atk2=base.Attack2
			currentBaseDamage=atk2.DamageAdd+atk2.DamageDiceCount*(1+atk2.DamageDiceSides)/2
			batck2=bMon.Attack2
			bBaseDamage=batck2.DamageAdd+batck2.DamageDiceCount*(1+batck2.DamageDiceSides)/2
			if currentBaseDamage==0 or bBaseDamage==0 then
				dmgMult=1
			else
				dmgMult=math.min(math.max(currentBaseDamage/bBaseDamage,0.75),1.3)
			end
			mon.Attack2.DamageAdd, mon.Attack2.DamageDiceSides, mon.Attack2.DamageDiceCount = calcDices(mon.Attack2.DamageAdd,mon.Attack2.DamageDiceSides,mon.Attack2.DamageDiceCount,dmgMult,bonusDamage)
		end
			
	end
		
	for i=1, 651 do
		--calculate level scaling
		mon=Game.MonstersTxt[i]
		if i%3==1 then
			HPtable[i]=(HPtable[i]*0.3+HPtable[i+1]*(basetable[i].FullHP/basetable[i+1].FullHP))/1.3
		elseif i%3==0 then
			--HPtable[i]=(HPtable[i]*0.3+HPtable[i-1]*(basetable[i].FullHP/basetable[i-1].FullHP))/1.3
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
		--fixes for survival
		mon.AIType=0
		mon.MoveType=math.min(mon.MoveType,1)
	end
	
end

function events.GameInitialized2()
	function events.CalcDamageToPlayer(t)
		if not survivalMaps[Map.Name] and vars.SuvivalMode then
			t.Result=0
		end
	end
	function events.CalcDamageToMonster(t)
		if not survivalMaps[Map.Name] and vars.SuvivalMode then
			t.Result=0
		end
	end
	function events.CanOpenChest(t)
		if not survivalMaps[Map.Name] and vars.SuvivalMode then
			t.CanOpenChest=false
			t.CanOpen=false
			t.ChestId = 22
		end
	end
	function events.PickCorpse(t)
		if not survivalMaps[Map.Name] and vars.SuvivalMode then
			mon=t.Monster
			--calculate bolster
			lvl=BLevel[mon.Id]
			gold=mon.TreasureDiceCount*(mon.TreasureDiceSides+1)/2
			newGold=(bolsterLevel2+lvl)*7.5
			local mult=1
			if mon.Id%3==1 then
				mult=0.5
			elseif mon.Id%3==0 then
				mult=2
			end
			newGold=newGold*mult
			goldMult=(bolsterLevel2+lvl)^1.5/(lvl)^1.5
			mon.TreasureDiceCount=math.min(newGold^0.5,255)
			mon.TreasureDiceSides=math.min(newGold^0.5,255)
			--calculate loot chances
			mon.TreasureItemPercent= math.min(math.round(mon.Level^0.7*2*mult),100)
			mon.TreasureItemLevel=math.max(math.min(math.ceil(mon.Level/15),6),1)
			mon.TreasureItemType=0
		end
	end
end
