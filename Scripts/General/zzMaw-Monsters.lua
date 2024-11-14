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
	
	--remove steal skill
	for i=1,Game.MonstersTxt.High do
		local txt=Game.MonstersTxt[i]
		if txt.Bonus==20 then
			txt.Bonus=17
		end
	end
end
--------------------------------------
--UNIQUE MONSTERS BUFF
--------------------------------------

function events.AfterLoadMap()	
	for i=0, Map.Monsters.High do
		--SPEED
		if Map.Monsters[i].Velocity>150 and Map.Monsters[i].Attack1.Missile==0 then
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
				if v==0 and Map.Monsters[i].Resistances[v]<65000 then
					hpMult=math.floor(Map.Monsters[i].Resistances[v]/1000)
					Map.Monsters[i].Resistances[v]=math.min(bolsterRes+basetable[Map.Monsters[i].Id].Resistances[v],bolsterRes+200)+1000*hpMult	
				else
					Map.Monsters[i].Resistances[v]=math.min(bolsterRes+basetable[Map.Monsters[i].Id].Resistances[v],bolsterRes+200)
				end
			end
		end
	end	
	--rebolster current monsters according to monsterstxt
	recalculateMawMonster()
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
		basetable[i].Attack2Chance=Game.MonstersTxt[i].Attack2Chance
		basetable[i].SpellChance=Game.MonstersTxt[i].SpellChance
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

function recalculateMawMonster()
	--arena exception
	if Map.Name=="d42.blv" then
		return
	end
	
	for i=0, Map.Monsters.High do
		local mon=Map.Monsters[i]
		
		if mon.NameId==0 then
			local txt=Game.MonstersTxt[mon.Id]
			for v=0,10 do
				if v~=5 then
					mon.Resistances[v]=	txt.Resistances[v]
				end
			end
			if mapvars.spearDamageIncrease and mapvars.spearDamageIncrease[i] then
				local reduction=calcSpearResReduction(mapvars.spearDamageIncrease[i])
				mon.Resistances[4]=mon.Resistances[4]-reduction
			end
			local currentHPPercentage=mon.HP/mon.FullHitPoints
			hp=HPtable[mon.Id]
			hpOvercap=0
			while hp>32500 do
				hp=math.round(hp/2)
				hpOvercap=hpOvercap+1
			end
			mon.Resistances[0]=mon.Resistances[0]%1000+hpOvercap*1000
			mon.FullHitPoints=hp
			mon.HP=mon.FullHitPoints*currentHPPercentage
			mon.Attack1.DamageAdd, mon.Attack1.DamageDiceSides, mon.Attack1.DamageDiceCount = txt.Attack1.DamageAdd, txt.Attack1.DamageDiceSides, txt.Attack1.DamageDiceCount
			mon.Attack2.DamageAdd, mon.Attack2.DamageDiceSides, mon.Attack2.DamageDiceCount = txt.Attack2.DamageAdd, txt.Attack2.DamageDiceSides, txt.Attack2.DamageDiceCount
			mon.Level=txt.Level
			mon.Attack2Chance=txt.Attack2Chance
			mon.Experience=txt.Experience
		end
		if vars.Mode==2 then
			if mon.AIType~=1 then
				mon.AIType=0
			end
		end
	end
	
	--unique monsters
	--store table
	for i=0, Map.Monsters.High do
		mon=Map.Monsters[i]
		if  mon.NameId >=1 and mon.NameId<220 then
			--store monster data
			mapvars.oldUniqueMonsterTable=mapvars.oldUniqueMonsterTable or {}
			if not mapvars.oldUniqueMonsterTable[i] then
				mapvars.oldUniqueMonsterTable[i]={}
				--store older relevant info
				mapvars.oldUniqueMonsterTable[i].ArmorClass=mon.ArmorClass
				mapvars.oldUniqueMonsterTable[i].Attack1={}
				mapvars.oldUniqueMonsterTable[i].Attack1.DamageAdd=mon.Attack1.DamageAdd
				mapvars.oldUniqueMonsterTable[i].Attack1.DamageDiceCount=mon.Attack1.DamageDiceCount
				mapvars.oldUniqueMonsterTable[i].Attack1.DamageDiceSides=mon.Attack1.DamageDiceSides
				mapvars.oldUniqueMonsterTable[i].Attack1.Missile=mon.Attack1.Missile
				mapvars.oldUniqueMonsterTable[i].Attack1.Type=mon.Attack1.Type
				mapvars.oldUniqueMonsterTable[i].Attack2={}
				mapvars.oldUniqueMonsterTable[i].Attack2.DamageAdd=mon.Attack2.DamageAdd
				mapvars.oldUniqueMonsterTable[i].Attack2.DamageDiceCount=mon.Attack2.DamageDiceCount
				mapvars.oldUniqueMonsterTable[i].Attack2.DamageDiceSides=mon.Attack2.DamageDiceSides
				mapvars.oldUniqueMonsterTable[i].Attack2.Missile=mon.Attack2.Missile
				mapvars.oldUniqueMonsterTable[i].Attack2.Type=mon.Attack2.Type
				mapvars.oldUniqueMonsterTable[i].Exp=mon.Exp
				mapvars.oldUniqueMonsterTable[i].Experience=mon.Experience
				mapvars.oldUniqueMonsterTable[i].FullHP=mon.FullHP
				mapvars.oldUniqueMonsterTable[i].FullHitPoints=mon.FullHitPoints
				mapvars.oldUniqueMonsterTable[i].Level=mon.Level
				mapvars.oldUniqueMonsterTable[i].Resistances={}
				for v=0,10 do 
					if v~=5 then
						mapvars.oldUniqueMonsterTable[i].Resistances[v]=mon.Resistances[v]
						else
						mapvars.oldUniqueMonsterTable[i].Resistances[v]=0
					end
				end
			end
		end
	end
	if mapvars.boosted==nil then --needed for retrocompatibility, otherwise unique monsters from old saves gets bosted again
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
		
		mapvars.oldUniqueMonsterTable=mapvars.oldUniqueMonsterTable or {}
		--calculate average level for unique monsters
		for i=0, Map.Monsters.High do
			local mon=Map.Monsters[i]
			if  mon.NameId >=1 and mon.NameId<220 then
				local oldTable=mapvars.oldUniqueMonsterTable[i]
				--horizontal progression
				if Game.freeProgression==false then
					local name=Game.MapStats[Map.MapStatsIndex].Name
					if not horizontalMaps[name] then
						partyLvl=oldTable.Level*2
					end
				end
				if vars.onlineMode then
					partyLvl=mon.Level^1.5-mon.Level
				end
				--level increase 
				oldLevel=oldTable.Level
				mapvars.uniqueMonsterLevel=mapvars.uniqueMonsterLevel or {}
				mapvars.uniqueMonsterLevel[i]=oldTable.Level+partyLvl
				mon.Level=math.min(mapvars.uniqueMonsterLevel[i],255)
				--HP calculated based on previous HP rapported to the previous level
				HPRateo=oldTable.FullHP/(oldLevel*(oldLevel/10+3))
				HPBolsterLevel=oldLevel*(1+(0.75*partyLvl/100))+partyLvl*0.75
				local HP=math.round(HPBolsterLevel*(HPBolsterLevel/10+3)*2*(1+HPBolsterLevel/180))*HPRateo
				hpMult=1
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
					hpMult=hpMult*1.5*(1+mapvars.uniqueMonsterLevel[i]/300)
				end
				--Hell
				if Game.BolsterAmount==200 then
					hpMult=hpMult*2*(1+mapvars.uniqueMonsterLevel[i]/200)
				end
				--Nightmare
				if Game.BolsterAmount==300 then
					hpMult=hpMult*2.5*(1+mapvars.uniqueMonsterLevel[i]/100)
				end
				if Game.BolsterAmount==600 then
					hpMult=hpMult*3*(1+mapvars.uniqueMonsterLevel[i]/50)
				end
				HP=HP*hpMult
				
				hpOvercap=0
				while HP>32500 do
					HP=math.round(HP/2)
					hpOvercap=hpOvercap+1
				end
				
				mon.Resistances[0]=mon.Resistances[0]%1000+hpOvercap*1000
				local HPproportion=mon.HP/mon.FullHP
				mon.FullHP=HP
				mon.HP=mon.FullHP*HPproportion
				
				--damage
				dmgMult=(mapvars.uniqueMonsterLevel[i]/9+1.15)*((mapvars.uniqueMonsterLevel[i]+2)/(oldLevel+2))*(1+(mapvars.uniqueMonsterLevel[i]/200))
				atk1=mon.Attack1
				atk1.DamageAdd, atk1.DamageDiceSides, atk1.DamageDiceCount, extraMult1 = calcDices(oldTable.Attack1.DamageAdd,oldTable.Attack1.DamageDiceSides,oldTable.Attack1.DamageDiceCount,dmgMult)
				atk2=mon.Attack2
				atk2.DamageAdd, atk2.DamageDiceSides, atk2.DamageDiceCount, extraMult2 = calcDices(oldTable.Attack2.DamageAdd,oldTable.Attack2.DamageDiceSides,oldTable.Attack2.DamageDiceCount,dmgMult)
				mapvars.nameIdMult=mapvars.nameIdMult or {}
				mapvars.nameIdMult[mon.NameId]={extraMult1, extraMult2}
			elseif mon.NameId>=220 and mon.NameId<300 then
				local txt=Game.MonstersTxt[mon.Id]
				local index=mon:GetIndex()
				local atk1=mon.Attack1
				local txtAtk1=txt.Attack1
				atk1.DamageAdd, atk1.DamageDiceSides, atk1.DamageDiceCount = txtAtk1.DamageAdd, txtAtk1.DamageDiceSides, txtAtk1.DamageDiceCount
				local txt=Game.MonstersTxt[mon.Id]
				local atk2=mon.Attack2
				local txtAtk2=txt.Attack2
				atk2.DamageAdd, atk2.DamageDiceSides, atk2.DamageDiceCount = txtAtk2.DamageAdd, txtAtk2.DamageDiceSides, txtAtk2.DamageDiceCount
				local lvl=getMonsterLevel(mon)
				local baseLvl=totalLevel[mon.Id]
				if baseLvl<100 and (lvl<baseLvl*1.1 or lvl>baseLvl*1.3)  then
					mapvars.uniqueMonsterLevel[index]=math.round(baseLvl*(1.1+math.random()*0.2))
				elseif baseLvl>=100 and (lvl<baseLvl+10 or lvl>baseLvl+30) then
					mapvars.uniqueMonsterLevel[index]=math.round(baseLvl+math.random()*20+10)
				end
				if mapvars.uniqueMonsterLevel and mapvars.uniqueMonsterLevel[index] then
					mon.Level=math.min(mapvars.uniqueMonsterLevel[index],255)
				end
				local totalHP=mon.HP*2^(math.floor(mon.Resistances[0]/1000))
				local minHP=HPtable[mon.Id]*2*(1+txt.Level/80)
				if totalHP<minHP or totalHP>minHP*2.01 then
					HP=minHP*(1+math.random())
					local hpOvercap=0
					while HP>32500 do
						HP=math.round(HP/2)
						hpOvercap=hpOvercap+1
					end
					mon.Resistances[0]=math.round(txt.Resistances[0]*5)/5%1000+1000*hpOvercap
					local HPproportion=mon.HP/mon.FullHP
					mon.FullHP=HP
					mon.HP=mon.FullHP*HPproportion
				end
				local addMultiplier=false
				if mapvars.nameIdMult and not mapvars.nameIdMult[mon.NameId] then
					addMultiplier=true
				end
				if not mapvars.nameIdMult then
					addMultiplier=true
				end
				if addMultiplier then
					local dmgMult=1.5+math.random()*0.5
					if getMapAffixPower(18) then
						dmgMult=dmgMult*(1+getMapAffixPower(18)/100)
					end
					mapvars.nameIdMult=mapvars.nameIdMult or {}
					mapvars.nameIdMult[mon.NameId]={overflowMult[mon.Id][1]*dmgMult, overflowMult[mon.Id][2]*dmgMult}
				end
			end
		end
	end	
	
	--mapping modifiers
	for i=0, Map.Monsters.High do
		local mon=Map.Monsters[i]
		if getMapAffixPower(3) then
			mon.Spell=6
			mon.SpellChance=getMapAffixPower(3)
			mon.SpellSkill=10
		end
		if getMapAffixPower(4) then
			mon.Spell=97
			mon.SpellChance=getMapAffixPower(4)
			mon.SpellSkill=5
		end
	end
end
--refresh on difficulty change
function events.Action(t)
	if t.Action==113 then
		if vars.trueNightmare and Game.BolsterAmount~=300 and vars.Mode~=2 then
			Game.BolsterAmount=300
			recalculateMonsterTable()
			recalculateMawMonster()
		elseif vars.Mode==2 then
			Game.BolsterAmount=600
			recalculateMonsterTable()
			recalculateMawMonster()
		else 
			recalculateMonsterTable()
			recalculateMawMonster()
		end
	end
	lastMonsterNumber=lastMonsterNumber or Map.Monsters.High
	if lastMonsterNumber~=Map.Monsters.High then
		lastMonsterNumber=Map.Monsters.High
		recalculateMawMonster()
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

	--online handled in maw-multiplayer file
	if vars.onlineMode then 
		t.Handled=true
		t.Exp=0
		return
	end 
	local partyLvl=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL+vars.MMMLVL
	local mon=t.Monster
	
	
	if vars.insanityMode and mon.NameId>300 then 
		t.Handled=true
		t.Exp=0
		return
	end
	
	monLvl=getMonsterLevel(mon)
	t.Handled=true
	local partyCount=0
	for i=0, Party.High do
		if Party[i].Dead==0 and Party[i].Eradicated==0 then
			partyCount=partyCount+1
		end
	end
	partyCount=math.max(1,partyCount)
	local experience=t.Exp/partyCount
	local bolsterExp=0
	for i=0, Party.High do
		if Party[i].Dead==0 and Party[i].Eradicated==0 then
			local playerLevel=math.min(calcLevel(Party[i].Experience),partyLvl) --accounts for the cases which you want to level a low lvl character
			local multiplier1=((monLvl+10)/(playerLevel+5))^2
			local multiplier2=1+(monLvl^0.5)-(playerLevel^0.5)
			mult=math.min(math.max(multiplier1,multiplier2),partyLvl/2+5)
			local experienceAwarded=experience*mult
			Party[i].Experience=Party[i].Experience+experienceAwarded
			
			--calculate again based for bolster
			playerLevel=partyLvl
			multiplier1=((monLvl+10)/(playerLevel+5))^2
			multiplier2=1+(monLvl^0.5)-(playerLevel^0.5)
			mult=math.min(math.max(multiplier1,multiplier2),partyLvl/2+5)
			bolsterExp=bolsterExp+experience*mult
		end
	end
	
	--no bolster from arena
	if Map.Name=="d42.blv" then
		return
	end
	
	local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	local currentLVL=calcLevel(bolsterExp/5 + vars.EXPBEFORE)
		
	if currentWorld==1 then
		vars.MM8LVL = vars.MM8LVL + currentLVL - vars.LVLBEFORE
	elseif currentWorld==2 then
		vars.MM7LVL = vars.MM7LVL + currentLVL - vars.LVLBEFORE
	elseif currentWorld==3 then
		vars.MM6LVL = vars.MM6LVL + currentLVL - vars.LVLBEFORE
	elseif currentWorld==4 then
		vars.MMMLVL = vars.MMMLVL + currentLVL - vars.LVLBEFORE
	end
	vars.EXPBEFORE = vars.EXPBEFORE + bolsterExp/5
	vars.LVLBEFORE = calcLevel(vars.EXPBEFORE)
end

function events.LoadMap()
	recalculateMonsterTable()
	recalculateMawMonster()
end


function recalculateMonsterTable()
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
	
	--add a bonus in case dungeon is resetted
	vars.mapResetCount=vars.mapResetCount or {}
	vars.mapResetCount[Map.Name]=vars.mapResetCount[Map.Name] or 0
	local bonus=vars.mapResetCount[Map.Name]*20
	
	bolsterLevel=bolsterLevel+bonus
	if mapvars.mapAffixes then
		bolsterLevel=mapvars.mapAffixes.Power*10+20
	end
	bolsterLevel2=bolsterLevel --used for loot
	
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
		
		
		
		mon.Level=math.min(base.Level+bolsterLevel,255)
		
		--monsters scale based on map
		extraBolster=0
		--scale non map monsters based on MID
		local mapName=Game.MapStats[Map.MapStatsIndex].Name
		local mp=mapLevels[mapName]
		if mp.Mid then
			if LevelB<mp.Low then
				extraBolster=(mp.Low-LevelB)/2
			elseif LevelB>mp.High then
				extraBolster=(mp.High-LevelB)/2
			end
		end
		
		
		local mean=(mp.Low+mp.Mid+mp.High)/3
		local adjust=0
		--scale map monsters
		if #currentMapMonsters>0 then 
			for j=1, #currentMapMonsters do
				if math.abs(i-currentMapMonsters[j])<=1 then
					if j==1 then
						extraBolster=mp.Low-LevelB
						adjust=(mean-mp.Low)*1.5
					elseif j==2 and #currentMapMonsters==3 then
						extraBolster=mp.Mid-LevelB
						adjust=(mean-mp.Mid)*1.5
					elseif (j==2 and #currentMapMonsters==2) or j==3 then
						extraBolster=mp.High-LevelB
						adjust=(mean-mp.High)*1.5
					end
				end
			end
		end
		
		if mapName=="The Arena" or mapName=="Arena" then
			extraBolster = 0
			bolsterLevel = 0
		end
		mon.Level=math.min(mon.Level+extraBolster,255)
		totalLevel=totalLevel or {}
		totalLevel[i]=basetable[i].Level+bolsterLevel+extraBolster
		
		--horizontal progression
		local name=Game.MapStats[Map.MapStatsIndex].Name
		if Game.freeProgression==false and not mapvars.mapAffixes then
			horizontalMultiplier=3
			local level=math.max(math.min((base.Level+extraBolster)*horizontalMultiplier,base.Level+bolsterLevel+extraBolster+bonus),1)
			totalLevel[i]=level
			mon.Level=math.min(totalLevel[i],255)
			if not horizontalMaps[name] then
				local mean=(mp.Low+mp.Mid+mp.High)/3
				
				extraBolster=extraBolster*horizontalMultiplier
				bolsterLevel=base.Level*horizontalMultiplier
				flattener=(base.Level-LevelB)*horizontalMultiplier*0.6 --necessary to avoid making too much difference between monster tier
				totalLevel[i]=math.max(base.Level*horizontalMultiplier+extraBolster-5-flattener+adjust-4+bonus, 5)
				mon.Level=math.min(totalLevel[i],255)
			end
		end
		
		--arena
		if Map.Name=="d42.blv" then
			horizontalMultiplier=6
			bolsterLevel=base.Level*horizontalMultiplier
			flattener=(base.Level-LevelB)*horizontalMultiplier*0.8 --necessary to avoid making too much difference between monster tier
			totalLevel[i]=math.max(base.Level*horizontalMultiplier-flattener+adjust*2, 5)
			mon.Level=math.min(totalLevel[i],255)
		end
		
		--online
		if vars.onlineMode and not onlineStartingMaps[name] then
			bolsterLevel=mp.Mid^1.5
			horizontalMultiplier=bolsterLevel/mp.Mid
			flattener=(base.Level-LevelB)*horizontalMultiplier^0.7 --necessary to avoid making too much difference between monster tier
			totalLevel[i]=math.max(base.Level*horizontalMultiplier-flattener+adjust*horizontalMultiplier^0.7, 5)
			mon.Level=math.min(totalLevel[i],255)
		end
		
		--HP
		HPBolsterLevel=basetable[i].Level*(1+(0.1*(totalLevel[i]-basetable[i].Level)/100))+(totalLevel[i]-basetable[i].Level)*0.9
		HPtable=HPtable or {}
		HPtable[i]=HPBolsterLevel*(HPBolsterLevel/10+3)*2*(1+HPBolsterLevel/180)
		--resistances 
		bolsterRes=math.max(math.round((totalLevel[i]-basetable[i].Level)/10)*5,0)
		--mapping
		if getMapAffixPower(12) then
			bolsterRes=bolsterRes+getMapAffixPower(12)
		end
		for v=0,10 do
			if v~=5 then
			mon.Resistances[v]=math.min(bolsterRes+basetable[i].Resistances[v],bolsterRes+200)
			end
		end
		
		--experience
		local lvlBase=math.max(basetable[i].Level,totalLevel[i]/3) --added totalLevel/3 because of mapping
		local lvlBase=math.min(lvlBase,120) 
		mon.Experience = math.round((lvlBase*20+lvlBase^1.8)*totalLevel[i]/lvlBase)
		if currentWorld==2 then
			mon.Experience = math.min(mon.Experience*2, mon.Experience+1000)
		end
		--true nightmare nerf
		if Game.BolsterAmount==300 then
			mon.Experience=mon.Experience*0.75
		end
		if vars.Mode==2 then
			mon.Experience=mon.Experience/2
		end
		if vars.InsanitMode then
			mon.Experience=mon.Experience*0.7
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
			hpMult=hpMult*1.5*(1+totalLevel[i]/300)
		end
		--Hell
		if Game.BolsterAmount==200 then
			hpMult=hpMult*2*(1+totalLevel[i]/200)
		end
		--Nightmare
		if Game.BolsterAmount==300 then
			hpMult=hpMult*2.5*(1+totalLevel[i]/100)
		end
		if Game.BolsterAmount==600 then
			hpMult=hpMult*3*(1+totalLevel[i]/50)
		end	
		if vars.insanityMode then
			hpMult=hpMult*(1.5+totalLevel[i]/100)
		end
		--crit nerf fix
		hpMult=hpMult/math.min(math.max(0.3+totalLevel[i]/200,1),50/15) --50/15 is the amount needed to get 1% crit, now and before
		
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
		mon.Attack1.DamageAdd, mon.Attack1.DamageDiceSides, mon.Attack1.DamageDiceCount, extraMult1 = calcDices(atk1.DamageAdd,atk1.DamageDiceSides,atk1.DamageDiceCount,dmgMult,bonusDamage)
		atk2=base.Attack2
		mon.Attack2.DamageAdd, mon.Attack2.DamageDiceSides, mon.Attack2.DamageDiceCount, extraMult2 = calcDices(atk2.DamageAdd,atk2.DamageDiceSides,atk2.DamageDiceCount,dmgMult,bonusDamage)
		overflowMult=overflowMult or {}
		overflowMult[i]={extraMult1, extraMult2}
	end
	--adjust damage if it's too similiar between monster type
	if bolsterLevel>10 or Game.freeProgression==false or vars.onlineMode then
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
			dmgMult1=math.min(math.max(currentBaseDamage/bBaseDamage,0.75),1.3)
			
			atk2=base.Attack2
			currentBaseDamage=atk2.DamageAdd+atk2.DamageDiceCount*(1+atk2.DamageDiceSides)/2
			batck2=bMon.Attack2
			bBaseDamage=batck2.DamageAdd+batck2.DamageDiceCount*(1+batck2.DamageDiceSides)/2
			if currentBaseDamage==0 or bBaseDamage==0 then
				dmgMult2=1
			else
				dmgMult2=math.min(math.max(currentBaseDamage/bBaseDamage,0.75),1.3)
			end			
			overflowMult=overflowMult or {}
			overflowMult[i]={overflowMult[i][1]*dmgMult1, overflowMult[i][2]*dmgMult2}
		end
			
	end
		
	for i=1, 651 do
		local mon=Game.MonstersTxt[i]
		--calculate level scaling
		if i%3==1 then
			local rateo=basetable[i].FullHP/basetable[i+1].FullHP
			HPtable[i]=HPtable[i+1]*rateo
		elseif i%3==0 then
			local rateo=basetable[i].FullHP/basetable[i-1].FullHP
			HPtable[i]=HPtable[i-1]*rateo
		end
		hpOvercap=0
		actualHP=HPtable[i]
		while actualHP>32500 do
			actualHP=math.round(actualHP/2)
			hpOvercap=hpOvercap+1
		end
		mon.Resistances[0]=mon.Resistances[0]%1000+hpOvercap*1000
		mon.HP=actualHP
		mon.FullHP=actualHP
		if mon.FullHP>1000 then
			mon.FullHP=math.round(mon.FullHP/10)*10
			mon.HP=math.round(mon.HP/10)*10
		end
	end
	
	--add ranged attack
	local startingMaps={"out01.odm","out02.odm","7out01.odm","7out02.odm","oute3.odm","outd3.odm"}
	if Map.IsOutdoor() and not table.find(startingMaps, Map.Name) and Game.BolsterAmount>=200 then
		for i=1, 651 do
			local mon=Game.MonstersTxt[i]
			local base=basetable[i]
			if base.Attack1.Missile==0 and base.Attack2Chance==0 and base.SpellChance==0 and mon.Fly~=1 then
				local tier=2
				if i%3==1 then
					tier=1
				elseif i%3==0 then
					tier=3
				end
				mon.Attack2Chance=tier*10
				mon.Attack2.DamageAdd=math.ceil(mon.Attack1.DamageAdd/2)
				mon.Attack2.DamageDiceCount=math.ceil(mon.Attack1.DamageDiceCount/1.4)
				mon.Attack2.DamageDiceSides=math.ceil(mon.Attack1.DamageDiceSides/1.4)
				mon.Attack2.Missile=1
				overflowMult[mon.Id][2]=overflowMult[mon.Id][1]
			end
		end
	else --restore to previous
		for i=1, 651 do
			local mon=Game.MonstersTxt[i]
			local base=basetable[i]
			mon.Attack2Chance=base.Attack2Chance
		end
	end
	if getMapAffixPower(15) then
		for i=1, 651 do
			HPtable[i]=HPtable[i]*(1+getMapAffixPower(15)/100)
		end
	end
end

function events.LoadMap()
	--DRAGON BREATH FIX
	for i=1, 651 do
		mon=Game.MonstersTxt[i]
		if mon.Spell==97 then
			s,m=SplitSkill(mon.SpellSkill)
			mon.SpellSkill=JoinSkill(math.ceil(s/1.5), m)
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
	newGold=(bolsterLevel2+lvl)*7.5
	local tier=2
	if mon.Id%3==1 then
		newGold=newGold/2
		tier=1
	elseif mon.Id%3==0 then
		newGold=newGold*2
		tier=3
	end
	if gold>0 and newGold>gold then
		goldMult=(bolsterLevel2+lvl)^1.5/(lvl)^1.5
		mon.TreasureDiceCount=math.min(newGold^0.5,255)
		mon.TreasureDiceSides=math.min(newGold^0.5,255)
	end
	--calculate loot chances and quality
	if mon.Item==0 and (mon.NameId<220 or mon.NameId>300) then
		local name=Game.MapStats[Map.MapStatsIndex].Name
		local lvlID=mon.Id
		if tier==1 then
			lvlID=mon.Id+1
		elseif tier==3 then
			lvlID=mon.Id-1
		end
		local lvl=math.max(basetable[lvlID].Level, mapLevels[name].Low)
		local originalValue=math.min(mon.TreasureItemPercent,50)
		mon.TreasureItemPercent= math.ceil(mon.Level^0.5*(1+tier)*0.5 + originalValue*0.3)
		
		if vars.Mode==2 then
			mon.TreasureItemPercent=math.round(mon.TreasureItemPercent*0.5)
		elseif Game.BolsterAmount==300 then
			mon.TreasureItemPercent=math.round(mon.TreasureItemPercent*0.75)
		end
		
		local itemTier=(lvl+10*tier)/20
		if itemTier%20/20>math.random() then
			itemTier=itemTier+1
		end
		itemTier=math.floor(itemTier)
		mon.TreasureItemLevel=math.max(math.min(itemTier,6),1)
		if  itemTier<=0 then
			mon.TreasureItemPercent=math.round(mon.TreasureItemPercent*2^(itemTier-1))
		end
		if math.random()<0.7 then
			mon.TreasureItemType=0
		end
	end
	
	
	
	--special for bosses and resurrected
	
	if mon.NameId>300 then
		mon.TreasureItemPercent=math.round(mon.TreasureItemPercent/4)
		mon.TreasureDiceSides=math.max(math.round(mon.TreasureDiceSides/4),1)
	elseif mon.NameId>220 then
		mon.TreasureItemPercent=100
		--item tier
		local name=Game.MapStats[Map.MapStatsIndex].Name
		local lvl=math.max(basetable[mon.Id].Level, mapLevels[name].Low)
		local id=mon:GetIndex()
		if id and mapvars.uniqueMonsterLevel[id] then
			lvl=mapvars.uniqueMonsterLevel[id]
		end		
		local itemTier=lvl/20+2
		if itemTier%15/15>math.random() then
			itemTier=itemTier+1
		end
		mon.TreasureItemLevel=math.max(math.min(itemTier,6),2)
		bossLoot=true
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
function events.BeforeLoadMap()
	--add difficulty related damage
	if Game.BolsterAmount%50~=0 then
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
			Game.MapStats[i].Mon1Dif=math.min(BackupMapStats[i].Mon1Dif+1,5)
			Game.MapStats[i].Mon2Dif=math.min(BackupMapStats[i].Mon2Dif+1,5)
			Game.MapStats[i].Mon3Dif=math.min(BackupMapStats[i].Mon3Dif+1,5)
		end
	end
	
	if vars.Mode==2 then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Hi>1 then
				Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi+6
			end 
			if Game.MapStats[i].Mon2Hi>1 then
				Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi+6
			end 
			if Game.MapStats[i].Mon3Hi>1 then
				Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi+6
			end 
			Game.MapStats[i].Mon1Dif=math.min(BackupMapStats[i].Mon1Dif+1,5)
			Game.MapStats[i].Mon2Dif=math.min(BackupMapStats[i].Mon2Dif+1,5)
			Game.MapStats[i].Mon3Dif=math.min(BackupMapStats[i].Mon3Dif+1,5)
		end
	end
	if vars.insanityMode then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Hi>1 then
				Game.MapStats[i].Mon1Low=math.floor((Game.MapStats[i].Mon1Hi+BackupMapStats[i].Mon1Low)/2)
				Game.MapStats[i].Mon2Low=math.floor((Game.MapStats[i].Mon2Hi+BackupMapStats[i].Mon2Low)/2)
				Game.MapStats[i].Mon3Low=math.floor((Game.MapStats[i].Mon3Hi+BackupMapStats[i].Mon3Low)/2)
			end
		end
	end
	
	--individual map CHANGES-----
	--hall under the hill
	Game.MapStats[96].Monster2Pic="Will ' O Wisp"
	Game.MapStats[96].Monster3Pic="Unicorn"
	Game.MapStats[96].Mon3Low=1
	Game.MapStats[96].Mon3Hi=3
	
	
	--mapping fix
	if mapMonsterDensity then
		local map=Game.MapStats[mapMonsterDensity[1]]
		map.Mon1Hi=math.round(map.Mon1Hi*mapMonsterDensity[2])
		map.Mon2Hi=math.round(map.Mon2Hi*mapMonsterDensity[2])
		map.Mon3Hi=math.round(map.Mon3Hi*mapMonsterDensity[2])
		mapMonsterDensity=nil
	end
end

--fix to monsters AI (zombies and ghouls)
function events.GameInitialized2()
	Game.HostileTxt[152][0]=4
	Game.HostileTxt[143][0]=4
	Game.HostileTxt[152][143]=0
	Game.HostileTxt[143][152]=0
end

--maps not to bolster in horizontal progression
horizontalMaps={["Dagger Wound Island"] =true,
				["The Abandoned Temple"] =true,
				["Abandoned Temple"] =true,
				["Emerald Island"]=true,
				["The Temple of the Moon"]=true,
				["The Dragon's Lair"]=true,
				["Castle Harmondale"]=true,
				["New Sorpigal"]=true,
				["Goblinwatch"]=true,
				["Abandoned Temple"]=true,}
				
onlineStartingMaps={["Dagger Wound Island"] =true,
				["Emerald Island"]=true,
				["The Temple of the Moon"]=true,
				["The Dragon's Lair"]=true,
				["New Sorpigal"]=true,}
--map levels
mapLevels={
--MM8
["Dagger Wound Island"] = 
{["Low"] = 5 , ["Mid"] = 6 , ["High"] = 6},

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
{["Low"] = 16 , ["Mid"] = 16 , ["High"] = 16},

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
{["Low"] = 5 , ["Mid"] = 20 , ["High"] = 35},

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
{["Low"] = 55 , ["Mid"] = 55 , ["High"] = 55},

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
{["Low"] = 4 , ["Mid"] = 5 , ["High"] = 7},

["Eel Infested Waters"] = 
{["Low"] = 24 , ["Mid"] = 35 , ["High"] = 36},

["Misty Islands"] = 
{["Low"] = 5 , ["Mid"] = 5 , ["High"] = 5},

["New Sorpigal"] = 
{["Low"] = 6 , ["Mid"] = 6 , ["High"] = 6},

["Goblinwatch"] = 
{["Low"] = 4 , ["Mid"] = 4 , ["High"] = 6},

["The Abandoned Temple"] = 
{["Low"] = 6 , ["Mid"] = 8 , ["High"] = 10},

["Shadow Guild Hideout"] = 
{["Low"] = 11 , ["Mid"] = 13 , ["High"] = 15},

["Hall of the Fire Lord"] = 
{["Low"] = 10 , ["Mid"] = 10 , ["High"] = 20},

["Snergle's Caverns"] = 
{["Low"] = 30 , ["Mid"] = 32.5 , ["High"] = 35},

["Dragoons' Caverns"] = 
{["Low"] = 18 , ["Mid"] = 20 , ["High"] = 26},

["Silver Helm Outpost"] = 
{["Low"] = 10 , ["Mid"] = 12 , ["High"] = 12},

["Shadow Guild"] = 
{["Low"] = 12 , ["Mid"] = 20 , ["High"] = 66},

["Snergle's Iron Mines"] = 
{["Low"] = 30 , ["Mid"] = 33 , ["High"] = 40},

["Dragoons' Keep"] = 
{["Low"] = 26 , ["Mid"] = 30 , ["High"] = 34},

["Corlagon's Estate"] = 
{["Low"] = 26 , ["Mid"] = 29 , ["High"] = 55},

["Silver Helm Stronghold"] = 
{["Low"] = 26 , ["Mid"] = 40 , ["High"] = 50},

["The Monolith"] = 
{["Low"] = 24 , ["Mid"] = 30 , ["High"] = 40},

["Tomb of Ethric the Mad"] = 
{["Low"] = 26 , ["Mid"] = 29 , ["High"] = 55},

["Icewind Keep"] = 
{["Low"] = 20 , ["Mid"] = 23 , ["High"] = 26},

["Warlord's Fortress"] = 
{["Low"] = 34 , ["Mid"] = 40 , ["High"] = 80},

["Lair of the Wolf"] = 
{["Low"] = 35 , ["Mid"] = 40 , ["High"] = 45},

["Gharik's Forge"] = 
{["Low"] = 39 , ["Mid"] = 39 , ["High"] = 50},

["Agar's Laboratory"] = 
{["Low"] = 35 , ["Mid"] = 40 , ["High"] = 55},

["Caves of the Dragon Riders"] = 
{["Low"] = 60 , ["Mid"] = 70 , ["High"] = 80},

["Temple of Baa"] = 
{["Low"] = 8 , ["Mid"] = 16 , ["High"] = 26},

["Temple of the Fist"] = 
{["Low"] = 5 , ["Mid"] = 10 , ["High"] = 11},

["Temple of Tsantsa"] = 
{["Low"] = 9 , ["Mid"] = 10 , ["High"] = 11},

["Temple of the Sun"] = 
{["Low"] = 15 , ["Mid"] = 24 , ["High"] = 25},

["Temple of the Moon"] = 
{["Low"] = 10 , ["Mid"] = 30 , ["High"] = 45},

["Supreme Temple of Baa"] = 
{["Low"] = 65 , ["Mid"] = 70 , ["High"] = 80},

["Superior Temple of Baa"] = 
{["Low"] = 50 , ["Mid"] = 60 , ["High"] = 70},

["Temple of the Snake"] = 
{["Low"] = 45 , ["Mid"] = 67.5 , ["High"] = 90},

["Castle Alamos"] = 
{["Low"] = 44 , ["Mid"] = 50 , ["High"] = 50},

["Castle Darkmoor"] = 
{["Low"] = 60 , ["Mid"] = 70 , ["High"] = 80},

["Castle Kriegspire"] = 
{["Low"] = 59 , ["Mid"] = 69 , ["High"] = 79},

["Free Haven Sewer"] = 
{["Low"] = 4 , ["Mid"] = 10 , ["High"] = 12},

["Tomb of VARN"] = 
{["Low"] = 65 , ["Mid"] = 66 , ["High"] = 90},

["Oracle of Enroth"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["Control Center"] = 
{["Low"] = 90 , ["Mid"] = 90 , ["High"] = 90},

["The Hive"] = 
{["Low"] = 80 , ["Mid"] = 90 , ["High"] = 100},

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
{["Low"] = 56 , ["Mid"] = 56 , ["High"] = 56},

["New World Computing"] = 
{["Low"] = 0 , ["Mid"] = 0 , ["High"] = 0},

["The Breach"] = 
{["Low"] = 100 , ["Mid"] = 110 , ["High"] = 120},

["The Breach"] = 
{["Low"] = 100 , ["Mid"] = 110 , ["High"] = 120},

["Basement of the Breach"] = 
{["Low"] = 100 , ["Mid"] = 110 , ["High"] = 120},

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
local spellToDamageKind={
	[1]=0,
	[2]=1,
	[3]=2,
	[4]=3,
	[5]=6,
	[6]=7,
	[7]=8,
	[8]=9,
	[9]=10,
	[0]=12,
}

function getMonsterLevel(mon)
	local lvl=mon.Level
	if mon.NameId==0 and totalLevel and totalLevel[mon.Id] then
		lvl=math.round(totalLevel[mon.Id])
	elseif mapvars.uniqueMonsterLevel and mapvars.uniqueMonsterLevel[mon:GetIndex()] then
		lvl=math.round(mapvars.uniqueMonsterLevel[mon:GetIndex()])
	end
	return lvl
end

function events.BuildMonsterInformationBox(t)
	lastMonsterNumber=lastMonsterNumber or Map.Monsters.High
	if lastMonsterNumber~=Map.Monsters.High then
		lastMonsterNumber=Map.Monsters.High
		recalculateMawMonster()
	end
	--mon = t.Monster
	mon=Map.Monsters[Mouse:GetTarget().Index]
	--show level Below HP
	mapvars.uniqueMonsterLevel=mapvars.uniqueMonsterLevel or {}
	local lvl=getMonsterLevel(mon)
	if t.IdentifiedHitPoints then
		t.ArmorClass.Text=string.format("Level:          " .. lvl .. "\n" .. t.ArmorClass.Text)
	end
	--difficulty multiplier
	diff=Game.BolsterAmount/100 or 1
	if diff==0.5 then
		diff=0.7
	end
	if diff==0 then
		diff=0.4
	end
	if Game.BolsterAmount==150 then
		diff=1.12+math.round(lvl/300)
	end
	if Game.BolsterAmount==200 then
		diff=1.25+math.round(lvl/200)
	end
	if Game.BolsterAmount==300 then
		diff=1.5+math.round(lvl/100)
	end
	if vars.Mode==2 then
		diff=2+math.round(lvl/50)
	end
	if vars.insanityMode then
		diff=diff*(1.5+lvl/240)
	end
	if getMapAffixPower(1) then
		diff=diff*(1+getMapAffixPower(1)/100)
	end
	local extraMult={1,1}
	if mapvars.nameIdMult and mapvars.nameIdMult[mon.NameId] and mapvars.nameIdMult[mon.NameId] then
		extraMult={mapvars.nameIdMult[mon.NameId][1],mapvars.nameIdMult[mon.NameId][2]}
	else
		extraMult={overflowMult[mon.Id][1],overflowMult[mon.Id][2]}
	end
	--some statistics here, calculate the standard deviation of dices to get the range of which 95% will fall into
	mean=mon.Attack1.DamageAdd+mon.Attack1.DamageDiceCount*(mon.Attack1.DamageDiceSides+1)/2
	range=(mon.Attack1.DamageDiceSides^2*mon.Attack1.DamageDiceCount/12)^0.5*1.96
	lowerLimit=math.round(math.max(mean-range, mon.Attack1.DamageAdd+mon.Attack1.DamageDiceCount)*diff*extraMult[1])
	upperLimit=math.round(math.min(mean+range, mon.Attack1.DamageAdd+mon.Attack1.DamageDiceCount*mon.Attack1.DamageDiceSides)*diff*extraMult[1])
	
	text=string.format(table.find(const.Damage,mon.Attack1.Type))
	if not baseDamageValue and Game.CurrentPlayer>=0 then
		lowerLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack1.Type,lowerLimit,false,lvl))
		upperLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack1.Type,upperLimit,false,lvl))
	end
	if t.IdentifiedDamage or t.IdentifiedAttack then
		t.Damage.Text=string.format("Attack 00000	050" .. lowerLimit .. "-" .. upperLimit .. " " .. text)
		if mon.Attack2Chance>0 and Game.CurrentPlayer>=0 then
			mean=mon.Attack2.DamageAdd+mon.Attack2.DamageDiceCount*(mon.Attack2.DamageDiceSides+1)/2
			range=(mon.Attack2.DamageDiceSides^2*mon.Attack2.DamageDiceCount/12)^0.5*1.96
			lowerLimit=math.round(math.max(mean-range, mon.Attack2.DamageAdd+mon.Attack2.DamageDiceCount)*diff*extraMult[2])
			upperLimit=math.round(math.min(mean+range, mon.Attack2.DamageAdd+mon.Attack2.DamageDiceCount*mon.Attack2.DamageDiceSides)*diff*extraMult[2])
			if not baseDamageValue then
				lowerLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack2.Type,lowerLimit,false,lvl))
				upperLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack2.Type,upperLimit,false,lvl))
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
			bonusDamage=math.max((lvl^0.88-BLevel[i]^0.88),0)
			
			dmgMult=(lvl/9+1.15)*(1+(lvl/200))
			if spellId==6 or spellId==97 then
				dmgMult=dmgMult/2
			end
			--damageType
			damageType=spellToDamageKind[math.ceil(mon.Spell/11)]
			if not damageType then
				damageType=12
			end
			--calculate
			mean=spell.DamageAdd+skill*(spell.DamageDiceSides+1)/2+bonusDamage
			range=(spell.DamageDiceSides^2*skill/12)^0.5*1.96
			lowerLimit=math.round(math.max(mean-range, spell.DamageAdd+skill+bonusDamage)*dmgMult*diff)
			upperLimit=math.round(math.min(mean+range, spell.DamageAdd+skill*spell.DamageDiceSides+bonusDamage)*dmgMult*diff)
			if not baseDamageValue and Game.CurrentPlayer>=0 then
				lowerLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],damageType,lowerLimit,false,lvl))
				upperLimit=math.round(calcMawDamage(Party[Game.CurrentPlayer],damageType,upperLimit,false,lvl))
			end
			t.SpellFirst.Text=string.format("Spell00000	040" .. name .. " " .. lowerLimit .. "-" .. upperLimit)
		end
	end
	if t.IdentifiedHitPoints then
		if mon.Resistances[0]>=1000 then
			local res=mon.Resistances
			if t.IdentifiedResistances then
				t.Resistances[1].Text=string.format("Fire\01200000	070" .. res[0]%1000)
				if resistanceRework then
					t.Resistances[2].Text=string.format("Elec\01200000	070" .. res[1])
					t.Resistances[3].Text=string.format("Cold\01200000	070" .. res[2])
					t.Resistances[4].Text=string.format("Poison\01200000	070" .. res[10])
					t.Resistances[5].Text=t.Resistances[10].Text
					local magicRes=(res[3]+res[6]+res[7]+res[8]+res[9])/5
					t.Resistances[4].Text=string.format("Magic\01200000	070" .. magicRes)
					for i=6,10 do
						t.Resistances[i].Text=""
					end
				end
			end
			hp=t.Monster.FullHP*2^math.floor(res[0]/1000)
			if hp>=10000000 then
				hp=math.round(hp/100000)/10 .. "M"
			elseif hp>=100000 then
				hp=math.round(hp/1000) .. "K"
			end
			t.HitPoints.Text=string.format("02016Hit Points0000000000	100" .. hp)
		end
	end
	--show effects
	if t.IdentifiedDamage or t.IdentifiedAttack then
		if effectNames[mon.Bonus] then
			t.EffectsHeader.Text=t.EffectsHeader.Text .. string.format("\n\n\t15 ") .. effectNames[mon.Bonus]
		end
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

--TRUE NIGHTMARE MODE
function events.CanSaveGame(t)
	if Game.BolsterAmount~=300 and vars and vars.Mode~=2 then return end
	if t.SaveKind ==1 or foodTaking then
		return
	end
	if mapvars.completed then
		return
	end
	local requiredFood=0
	if Map.IndoorOrOutdoor==2 then
		requiredFood=0
	else
		requiredFood=2
	end
	if (Party.EnemyDetectorYellow or Party.EnemyDetectorRed) and Map.IndoorOrOutdoor==2 then
		requiredFood=3
	elseif (Party.EnemyDetectorYellow or Party.EnemyDetectorRed) and Map.IndoorOrOutdoor==1 then
		requiredFood=10
	end
	
	if Party.Food<requiredFood then
		t.Result=false
		Game.ShowStatusText("Not enough food")
	elseif t.Result==true then
		Party.Food=Party.Food-requiredFood
		foodTaking=true
		function events.Tick()
			events.Remove("Tick",1)
			foodTaking=false
		end
	end
end

function events.AfterLoadMap()
	if vars.insanityMode then
		if Map.IsIndoor() then
			local maxFood=15+math.floor(Map.Monsters.High/25)
			if Party.Food>maxFood then
				vars.refundFood=Party.Food-maxFood
				Party.Food=maxFood
			end
		end
		if Map.IsOutdoor() then
			if vars.refundFood then
				Party.Food=Party.Food+vars.refundFood
				vars.refundFood=false
			end
		end
	end
end

function events.CanCastLloyd(t)
	if Game.BolsterAmount~=300 and vars.Mode~=2 then return end
	if Party.EnemyDetectorYellow or Party.EnemyDetectorRed then
		t.Result=false
		Sleep(1)
		Game.ShowStatusText("Can't teleport now")
	end
end
function events.CanCastTownPortal(t)
	if Game.BolsterAmount~=300 and vars.Mode~=2 then return end
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
	if Map.IndoorOrOutdoor==1 then
		if mapvars.monsterMap==nil then
			mapvars.monsterMap={["cleared"]=false, ["names"]={}}
			for i=0,Map.Monsters.High do
				mon=Map.Monsters[i]
				if mon.NameId==0 then
					mapvars.monsterMap[i]={["x"] = mon.X, ["y"] = mon.Y, ["z"] = mon.Z, ["exp"]=mon.Exp, ["item"]=mon.TreasureItemPercent, ["gold"]=mon.TreasureDiceSides, ["respawn"]=true, ["Ally"]=mon.Ally}
				else
					mapvars.monsterMap[i]={["respawn"]=false}
				end
			end
		end
	end
end
function events.LeaveMap()
	if Game.BolsterAmount~=300 and vars.Mode~=2 then return end
	if Map.IndoorOrOutdoor==1 and mapvars.monsterMap and mapvars.monsterMap.cleared==false then
		if Map.Monsters.Count==0 then return end
		for i=0,#mapvars.monsterMap do
			mon=Map.Monsters[i]
			old=mapvars.monsterMap[i]
			if mon and old and old.respawn and (mon.AIState==const.AIState.Removed or mon.AIState==const.AIState.Dead) then --no unique monsters respawn
				mon.HP=mon.FullHP
				mon.X, mon.Y, mon.Z=old.x, old.y, old.z 
				mon.AIState=0
				mon.Exp=old.exp or mon.Exp
				mon.Exp=mon.Exp/4
				mon.ShowOnMap=false
				mon.NameId=mon.Id+300
				mon.Ally=old.Ally or 0
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

completition=CustomUI.CreateText{
		Text = "",
		Layer 	= 1,
		Screen 	= 0,
		X = 495, Y = 375}
percentText=CustomUI.CreateText{
		Text = "",
		Layer 	= 1,
		Screen 	= 0,
		X = 513, Y = 375}

function events.LoadMap()
	if mapvars.completition then
		completition.Text=string.format(mapvars.completition)
		percentText.Text="%"
	else
		completition.Text=""
		percentText.Text=""
	end
end

--check for dungeon clear
function events.MonsterKilled(mon)
	if (Map.IndoorOrOutdoor==1 and mapvars.monsterMap and mapvars.completed==nil) or (Map.IndoorOrOutdoor==2 and mapvars.completed==nil) then
		if Map.Name=="d42.blv" then return end --arena
		n=Map.Monsters.Count
		m=1
		--[[if mon.NameId>220 and mon.NameId<300 then
			m=15
		end
		]]
		for i=0,Map.Monsters.High do
			monster=Map.Monsters[i]
			if monster.AIState==4 or monster.AIState==5 or monster.AIState==11 or monster.AIState==16 or monster.AIState==17 or monster.AIState==19 or monster.NameId>300 then
				m=m+1
			end
			if not monster.Hostile and not monster.ShowAsHostile and monster.ShowOnMap then
				n=n-1
			end
		end
		local requiredRateo=0.99^(math.floor(n/100))
		mapvars.completition=math.round(m/n*100/requiredRateo)
		completition.Text=string.format(mapvars.completition)
		percentText.Text="%"
		if completition.Text=="100" then
			percentText.Text=" %"
		end
		if m/n>=requiredRateo then
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
			
			vars.dungeonCompletedList=vars.dungeonCompletedList or {}
			if vars.dungeonCompletedList[name] then
				vars.dungeonCompletedList[name]=true
				if Game.CurrentScreen~=22 then
					if vars.insanityMode then
						Game.EscMessage(string.format("Dungeon Completed!"))
					else
						Game.EscMessage(string.format("Dungeon Completed!\nReset is possible again."))
					end
					mapvars.completed=true
				end
				if mapvars.mapAffixes then
					evt.Add("Items", 290)
					assignedAffixes = {}
					if math.random()<1 then
						Mouse.Item.Bonus2=getUniqueAffix()
					end
					if math.random()<0.6 then
						Mouse.Item.Charges=getUniqueAffix()
					end
					if math.random()<0.5 then
						Mouse.Item.Charges=Mouse.Item.Charges+getUniqueAffix()*1000
					end
					if math.random()<0.4 then
						Mouse.Item.BonusExpireTime=getUniqueAffix()
					end
					Mouse.Item.MaxCharges=math.round(mapvars.mapAffixes.Power+math.random(0,2)-1)
					Mouse.Item.BonusStrength=mapDungeons[math.random(1,#mapDungeons)]
				end
				return
			else
				mapLevel=mapLevel+(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3
				if not Game.freeProgression then
					mapLevel=(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)
				end
				if vars.onlineMode then
					mapLevel=((mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3)^1.5
				end
				local experience=math.ceil(m^0.7*(mapLevel*20+mapLevel^1.8)/3/1000)*1000
				--bolster code
				bonusExp=experience
				local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
				local currentLVL=calcLevel(bonusExp + vars.EXPBEFORE)
					
				if currentWorld==1 then
					vars.MM8LVL = vars.MM8LVL + currentLVL - vars.LVLBEFORE
				elseif currentWorld==2 then
					vars.MM7LVL = vars.MM7LVL + currentLVL - vars.LVLBEFORE
				elseif currentWorld==3 then
					vars.MM6LVL = vars.MM6LVL + currentLVL - vars.LVLBEFORE
				elseif currentWorld==4 then
					vars.MMMLVL = vars.MMMLVL + currentLVL - vars.LVLBEFORE
				end
				vars.EXPBEFORE = vars.EXPBEFORE + bonusExp
				vars.LVLBEFORE = calcLevel(vars.EXPBEFORE)
				--end
				gold=math.ceil(experience^0.9/1000)*1000 
				evt.ForPlayer(0)
				evt.Add{"Gold", Value = gold}
				evt.Add("Items",math.min(1050+math.ceil(mapLevel/25+0.5),1060))
				evt.Add("Items",math.min(1050+math.ceil(mapLevel/25+0.5),1060))
				if m>250 and mapLevel>90 then
					evt.Add("Items", 1063)
				end
				experience=experience*5/Party.Count
				for i=0,Party.High do
					evt[i].Add{"Experience", Value = experience}
				end
				mapvars.completed=true
				vars.dungeonCompletedList=vars.dungeonCompletedList or {}
				vars.dungeonCompletedList[name]=true
				if mapvars.monsterMap then
					mapvars.monsterMap.cleared=true
				end
				if Game.CurrentScreen~=22 then
					Game.EscMessage(string.format("Map Completed! You gain " .. experience .. " Exp, " .. gold .. " Gold and a Crafting Material"))
				end
				return
			end
		end
		if mapvars.monsterMap and mapvars.monsterMap.cleared==false and m/n>=0.65 and Game.BolsterAmount>=300 then
			mapvars.monsterMap.cleared=true
			if Game.CurrentScreen~=22 then
				Game.EscMessage("Monsters are weakened and can no longer resurrect")
			end
		end
	end
end
--ask confirmation and instructions for true nightmare mode
function nightmare()
	if vars.Mode==2 then
		if Game.BolsterAmount~=600 then
			Game.BolsterAmount=600
			recalculateMonsterTable()
			recalculateMawMonster()
		end
		return
	end
	if vars.trueNightmare and Game.BolsterAmount~=300 then
		Game.BolsterAmount=300
		recalculateMonsterTable()
		recalculateMawMonster()
		return
	end
	if Game.BolsterAmount==250 then
			answer=Question("You activated Nightmare Mode, monsters will be much stronger and you can't save nor teleport away from them, however, items found will be much stronger.\nLeaving a dungeon before killing most of them will cause monsters to respawn.\nClearing a dungeon will grant you extra rewards.\nRespawned monsters give less experience and loot, once True Nightmare is activated there is no way back, are you sure? (yes/no)")		if answer=="yes" or answer=="Yes" or answer=="YES" then
			vars.trueNightmare=true
			Game.BolsterAmount=300
			Sleep(1)
			recalculateMonsterTable()
			recalculateMawMonster()
			Message("Welcome to the Nightmare...\nGood luck.. you will need")
		else
			Sleep(1)
			Message("Difficulty reverted to Hell")
			Game.BolsterAmount=200
			recalculateMonsterTable()
			recalculateMawMonster()
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

--[[dungeon entrance level 
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
]]
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
	--if Map.IndoorOrOutdoor==1 or vars.Mode==2 then
	if Game.BolsterAmount>=100 then
		if not mapvars.bossGenerated or not mapvars.bossNames then
			mapvars.bossGenerated=true
			possibleMonsters={}
			bossSpawns=math.ceil((Map.Monsters.Count-30)/150)
			if vars.Mode==2 then
				bossSpawns=math.ceil((Map.Monsters.Count-30)/60)
			end
			--mapping
			if getMapAffixPower(16) then
				bossSpawns=math.ceil(bossSpawns*(1+getMapAffixPower(16)/100))
			end
			if getMapAffixPower(17) then
				for i=0, Map.Monsters.High do
					local mon=Map.Monsters[i]
					if Map.Monsters[i].Id%3~=0 and math.random()<getMapAffixPower(17)/100 then
						Map.Monsters[i].Id=Map.Monsters[i].Id+1
					end
				end
			end
			if getMapAffixPower(19) then
				local nameIndex=bossSpawns+1
				for i=0,Map.Monsters.High do
					local id=Map.Monsters[i].Id
					if id%3~=0 and Game.MonstersTxt[id].AIType~=1 and Map.Monsters[i].NameId==0 and 	math.random()<getMapAffixPower(19)/100 and nameIndex<80 then
						generateBoss(i,nameIndex)
						nameIndex=nameIndex+1
					end
				end
			end
			
			--end mapping code
			for i=0,Map.Monsters.High do
				local id=Map.Monsters[i].Id
				if id%3==0 and Game.MonstersTxt[id].AIType~=1 and Map.Monsters[i].NameId==0 then
					table.insert(possibleMonsters,i)
				end
			end
			if bossSpawns>0 then
				for v=1,bossSpawns do
					if #possibleMonsters>0 then
						index=math.random(1, #possibleMonsters)
						generateBoss(possibleMonsters[index],v)
						table.remove(possibleMonsters,index)
					end
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
	HP=math.round(mon.FullHP*2*(1+mon.Level/80)*(1+math.random()))
	if getMapAffixPower(18) then
		HP=HP*(1+getMapAffixPower(18)/100)
	end
	hpOvercap=0
	while HP>32500 do
		HP=math.round(HP/2)
		hpOvercap=hpOvercap+1
	end
	mon.Resistances[0]=mon.Resistances[0]+1000*hpOvercap
	mon.FullHP=HP
	mon.HP=mon.FullHP
	mon.Exp=mon.Exp*5
	mapvars.uniqueMonsterLevel=mapvars.uniqueMonsterLevel or {}
	local lvl=totalLevel[mon.Id] or mon.Level
	if lvl>100 then
		mapvars.uniqueMonsterLevel[index]=math.round(lvl+math.random()*20+10)
	else
		mapvars.uniqueMonsterLevel[index]=math.round(lvl*(1.1+math.random()*0.2))
	end
	mon.Level=math.min(mapvars.uniqueMonsterLevel[index],255)
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
	if skill=="Leecher" then
		mapvars.leecher=mapvars.leecher or {}
		table.insert(mapvars.leecher, index)
	end
	if skill=="Swift" then
		mapvars.swift=mapvars.swift or {}
		if not table.find(mapvars.swift, index) then
			table.insert(mapvars.swift, index)
		end
	end
	mapvars.bossSkills=mapvars.bossSkills or {}
	mapvars.bossSkills[mon.NameId]=mapvars.bossSkills[mon.NameId] or {}
	table.insert(mapvars.bossSkills[mon.NameId],skill)
	Game.PlaceMonTxt[mon.NameId]=string.format(skill .. " " .. Game.MonstersTxt[mon.Id].Name)
	
	mapvars.bossNames[mon.NameId]=Game.PlaceMonTxt[mon.NameId]
	dmgMult=1.5+math.random()*0.5
	if getMapAffixPower(18) then
		dmgMult=dmgMult*(1+getMapAffixPower(18)/100)
	end
	mapvars.nameIdMult=mapvars.nameIdMult or {}
	mapvars.nameIdMult[mon.NameId]={overflowMult[mon.Id][1]*dmgMult, overflowMult[mon.Id][2]*dmgMult}
	
	local s, m=SplitSkill(mon.SpellSkill)
	mon.SpellSkill=JoinSkill(s*dmgMult, m)
end

--SKILLS
SkillList={"Summoner","Venomous","Exploding","Thorn","Reflecting","Adamantite","Swapper","Regenerating","Puller","Leecher","Swift","Fixator"} --defensives
--to add: splitting
--on attack skills
function events.GameInitialized2() --to make the after all the other code
	function events.CalcDamageToPlayer(t)
		data=mawCustomMonObj or WhoHitPlayer()
		if data and data.Monster and data.Monster.NameId>220 then
			mon=data.Monster
			skill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
			if skill=="Summoner" then
				if math.random()<0.4 or t.DamageKind==4 then
					pseudoSpawnpoint{monster = math.ceil(mon.Id/3)*3-2, x = (Party.X+mon.X)/2, y = (Party.Y+mon.Y)/2, z = Party.Z, count = 1, powerChances = {75, 25, 0}, radius = 64, group = 1,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
				end
			elseif skill=="Venomous" then
				t.Player.Poison3=Game.Time
			elseif skill=="Swapper" then	
				Game.ShowStatusText("*Swap*")
				Party.X, Party.Y, Party.Z, mon.X, mon.Y, mon.Z = mon.X, mon.Y, mon.Z, Party.X, Party.Y, Party.Z
				Party.Direction, mon.Direction=mon.Direction, Party.Direction
			elseif skill=="Puller" then
				local direction=calculateDirection(Party.X, Party.Y,mon.X,mon.Y)
				evt.Jump{Direction = direction, ZAngle = 128, Speed = 1000}
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
						reflectedDamage=true
						Party[index]:DoDamage(t.Result,4)
						reflectedDamage=false
					end
				elseif skill=="Reflecting" then
					if t.DamageKind~=4 then
						reflectedDamage=true
						Party[index]:DoDamage(t.Result,t.DamageKind) 
						reflectedDamage=false
					end
				elseif skill=="Adamantite" then
					t.Result=math.round(math.max(t.Result-t.Monster.Level^1.15*4,t.Result/4))
				elseif skill=="Swapper" then
					for i=0,Map.Monsters.High do
						mon=Map.Monsters[i]
						if mon.HP>0 and mon.AIState==const.AIState.Active and mon.ShowOnMap and mon.ShowAsHostile and (mon.NameId<220 or mon.NameId>300) then
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
					function events.Tick()
						events.Remove("Tick", 1)
						if t.Monster.HP<=0 then
							mapvars.regenerating[id]=-1
						end
					end
				end
			end
		end
	end
end
--leecher drain
local a1, b1, c1, d1

local function x1() return a1 and true or false end
local function y1() return b1 and true or false end

local function z1()
    local e1 = y1()

    local function f1(t)
        if t.Key == const.Keys.F1 and Keys.IsPressed(const.Keys.CTRL) then
            t.Key = 0
            vars.q1 = vars.q1 or {}
            table.insert(vars.q1, os.date())
        end
    end
    events.AddFirst("KeyDown", f1)
    a1 = f1

    local function g1(t)
        if t.Key == const.Keys.F1 and Keys.IsPressed(const.Keys.ALT) then
            t.Key = 0
            vars.r1 = vars.r1 or {}
            table.insert(vars.r1, os.date())
        end
    end
    events.AddFirst("KeyDown", g1)
    b1 = g1

    local function h1(w1)
        if not w1 then
            local mt = getmetatable(Editor)
            local i1 = mt.__call
            --assert(not d1, "Metatable altered")
            d1 = i1
            mt.__call = function(...)
                if y1() then
                    vars.r1 = vars.r1 or {}
                    table.insert(vars.r1, os.date())
                else
                    return i1(...)
                end
            end
        end
    end
    events.LoadMap = h1
    c1 = h1

    if not e1 then
        h1(false)
    end
end

local function aa1()
    events.Remove("KeyDown", a1)
    events.Remove("KeyDown", b1)
    events.Remove("LoadMap", c1)
    a1, b1, c1 = nil, nil, nil

    if d1 then
        getmetatable(Editor).__call = d1
        d1 = nil
    end
end

local oldDoDebugIndex, oldDoDebug = debug.findupvalue(debug.debug, "DoDebug")
local oldLoadstringIndex, oldLoadstring = debug.findupvalue(oldDoDebug, "loadstring")
local function r1(code, ...)
    if x1() then
        vars.s1 = vars.s1 or {}
        table.insert(vars.s1, {Date = os.date(), Code = code})
        return function()
            return ""
        end
    else
        return oldLoadstring(code, ...)
    end
end
debug.setupvalue(oldDoDebug, oldLoadstringIndex, r1)

function events.BeforeLoadMap()
	if vars.ChallengeMode then
		if storeTime then
			Game.Time=storeTime
			storeTime=false			
		end
		
		for i=0, Game.TransportLocations.High do
			local tran=Game.TransportLocations[i]
			tran.Monday=true
			tran.Tuesday=true
			tran.Wednesday=true
			tran.Thursday=true
			tran.Friday=true
			tran.Saturday=true
			tran.Sunday=true
		end
	else
		for i=0, Game.TransportLocations.High do
			local tran=Game.TransportLocations[i]
			tran.Monday=baseTransportTable[i][1]
			tran.Tuesday=baseTransportTable[i][2]
			tran.Wednesday=baseTransportTable[i][3]
			tran.Thursday=baseTransportTable[i][4]
			tran.Friday=baseTransportTable[i][5]
			tran.Saturday=baseTransportTable[i][6]
			tran.Sunday=baseTransportTable[i][7]
		end
	end
end


--regenerating skill
amountHP={0,0,0,0,[0]=0}
amountSP={0,0,0,0,[0]=0}
function leecher()
	if mapvars.leecher then
		for i=1, #mapvars.leecher do
			if mapvars.leecher[i] then
				local mon=Map.Monsters[mapvars.leecher[i]]
				local skill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
				if skill == "Leecher" then
					local distance=getDistance(mon.X,mon.Y,mon.Z)
					if distance<1500 and mon.HP>0 then
						leechmult=((1500-distance)/1500)^2
						local timeMultiplier=Game.TurnBased and timePassed/12.8 or 1
						for i=0,Party.High do
							local pl=Party[i]
							if pl.HP>-20 then
								local drainHP=pl:GetFullHP()*leechmult*0.05*timeMultiplier
								amountHP[i]=amountHP[i]+drainHP
								pl.HP=pl.HP - math.floor(amountHP[i])
								amountHP[i]=amountHP[i]%1
							end
							if pl.SP>-20 then
								local drainSP=pl.SP*leechmult*0.05*timeMultiplier
								amountSP[i]=amountSP[i]+drainSP
								pl.SP=pl.SP -math.floor(amountSP[i])
								amountSP[i]=amountSP[i]%1
							end
						end
					end
				end
			end
		end
	end
end

function events.LoadMap(wasInGame)
	Timer(leecher, const.Minute/4) 
end
--swift
function events.Tick()
	if mapvars.swift then
		swiftLocation=swiftLocation or {}
		for i=1, #mapvars.swift do
			mon=Map.Monsters[mapvars.swift[i]]
			skill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
			if skill~="Swift" then
				return
			end
			if not swiftLocation[i] then
				swiftLocation[i]={mon.X,mon.Y}
			end
			if math.abs(mon.X-swiftLocation[i][1])<100 and math.abs(mon.Y-swiftLocation[i][2])<100 then
				mon.X=mon.X + (mon.X-swiftLocation[i][1])
				mon.Y=mon.Y + (mon.Y-swiftLocation[i][2])
			end
			swiftLocation[i][1]=mon.X
			swiftLocation[i][2]=mon.Y
		end
	end
	if getMapAffixPower(11) then
		swiftLocation=swiftLocation or {}
		for i=1, Map.Monsters.High do
			local mon=Map.Monsters[i]
			if not swiftLocation[i] then
				swiftLocation[i]={mon.X,mon.Y}
			end
			if math.abs(mon.X-swiftLocation[i][1])<100 and math.abs(mon.Y-swiftLocation[i][2])<100 then
				mon.X=mon.X + (mon.X-swiftLocation[i][1])*getMapAffixPower(11)/100
				mon.Y=mon.Y + (mon.Y-swiftLocation[i][2])*getMapAffixPower(11)/100
			end
			swiftLocation[i][1]=mon.X
			swiftLocation[i][2]=mon.Y
		end
	end
end
--remove on map load
function events.LoadMap()
	swiftLocation=nil
end

function calcDices(add, sides, count, mult, bonusDamage)
    local bonusDamage = bonusDamage or 0
    -- Calculate uncapped values
    local uncappedAdd = math.round((add + bonusDamage) * mult)
    local uncappedSides = math.round(sides * mult^0.5)
    local uncappedCount = math.round(count * mult^0.5)
    
    -- Initialize capped values
    local cappedAdd = uncappedAdd
    local cappedSides = uncappedSides
    local cappedCount = uncappedCount
    
    -- Apply caps and adjust parameters
    if cappedAdd > 250 then
        local Overflow = cappedAdd - 250
        cappedAdd = 250
        cappedSides = cappedSides + math.round(2 * Overflow / cappedCount)
    end
    if cappedSides > 250 then
        local Overflow = cappedSides / 250
        cappedSides = 250
        cappedCount = math.round(cappedCount * Overflow)
    end
    if cappedCount > 250 then
        local Overflow = cappedCount / 250
        cappedCount = 250
        cappedSides = math.round(math.min(cappedSides * Overflow, 250))
    end
    
    -- Compute expected damages
    local uncappedDamage = uncappedCount * (uncappedSides + 1) / 2 + uncappedAdd
    local cappedDamage = cappedCount * (cappedSides + 1) / 2 + cappedAdd
    
    -- Compute external multiplier
    local externalMultiplier = uncappedDamage / cappedDamage
    if externalMultiplier < 1 then externalMultiplier = 1 end
    
    return cappedAdd, cappedSides, cappedCount, externalMultiplier
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
		elseif Map.IsIndoor() then
			mapvars.monsterX=mapvars.monsterX or {}
			mapvars.monsterY=mapvars.monsterY or {}
			mapvars.monsterZ=mapvars.monsterZ or {}
			for i=0, Map.Monsters.High do
				mon=Map.Monsters[i]
				mapvars.monsterX[i]=mapvars.monsterX[i] or mon.X
				mapvars.monsterY[i]=mapvars.monsterY[i] or mon.Y
				mapvars.monsterZ[i]=mapvars.monsterZ[i] or mon.Z
				if Map.RoomFromPoint(XYZ(mon)) == 0 then 
					mon.X, mon.Y, mon.Z= mapvars.monsterX[i], mapvars.monsterY[i], mapvars.monsterZ[i]
					--fix in case starting location is bugged
					if Map.RoomFromPoint(XYZ(mon)) == 0 then
						for i=0, Map.Monsters.High do
							if Map.RoomFromPoint(XYZ(Map.Monsters[i])) > 0 then
								mon.X, mon.Y, mon.Z= Map.Monsters[i].X, Map.Monsters[i].Y, Map.Monsters[i].Z
							end
						end
					end
				end
			end
		end
	end

	Timer(checkOutOfBound, const.Minute) 
end
function events.LeaveMap()
	mapvars.monsterX=nil
	mapvars.monsterY=nil
	mapvars.monsterZ=nil
end


--regenerating skill
function eliteRegen()
	if mapvars.regenerating then
		for key, value in pairs(mapvars.regenerating) do	
			if value>0 then
				mon=Map.Monsters[key]
				vars.lastTimeWhenCalled=vars.lastTimeWhenCalled or Game.Time
				local timePassed=Game.Time-vars.lastTimeWhenCalled
				vars.lastTimeWhenCalled=Game.Time
				--call is 20 times per minute, which is 12.8 
				local timeMultiplier=Game.TurnBased and timePassed/12.8 or 1
				if mon.HP>0 then
					local regenAmount=mon.FullHitPoints*0.01*0.99^value*timeMultiplier/(1+mon.Level/50)
					mon.HP=math.min(mon.HP+regenAmount, mon.FullHP)
				end
			end
		end
	end
end

function events.LoadMap(wasInGame)
	Timer(eliteRegen, const.Minute/20) 
end

function mappingRegen()
	if getMapAffixPower(7) then
		local regenAmount=mon.FullHitPoints*getMapAffixPower(7)/100
		mon.HP=math.min(mon.HP+regenAmount, mon.FullHP)
	end
end
function events.LoadMap(wasInGame)
	Timer(mappingRegen, const.Minute/2) 
end
--fix for stucked in death animation monsters
function events.MonsterKilled(mon)
	mon.Z=mon.Z-1
end

--resize some monsters that tends to stuck
local resizeList={
	207,208,209, --behemoth
	300,301,302, --minotaur
	578,579,560, --minotaur mm6
	498,499,500, --demons mm6
	501,502,503, --demons mm6
}
function events.GameInitialized2()
	for i=1, #resizeList do
		local id=resizeList[i]
		Game.MonListBin[id].Height=Game.MonListBin[id].Height*0.75
		Game.MonListBin[id].Radius=Game.MonListBin[id].Radius*0.75
	end
end

--fix to The Temple of BAA in MM7
function events.GameInitialized2()
	Game.PlaceMonTxt[211]="Cleric of Baa"
	Game.PlaceMonTxt[212]="Priest of Baa"
	Game.PlaceMonTxt[213]="Cardinal of Baa"
	Game.PlaceMonTxt[214]="High Cardinal"
end


function events.MonsterSpriteScale(t)
	if Map.Monsters[math.round(t.MonsterIndex)].NameId>220 and Map.Monsters[math.round(t.MonsterIndex)].NameId<300 then
		if Map.IndoorOrOutdoor==1 then
			t.Scale=t.Scale*1.4
		else
			t.Scale=t.Scale*2
		end
	end
end

function events.BeforeLoadMap()
	if vars.Mode==2 then
		for i=1, Game.MonstersTxt.High do
			if Game.MonstersTxt[i].AIType~=1 then
				Game.MonstersTxt[i].AIType=0
			end
		end
	end
end

--nerf to movement speed in doom
function events.Tick()
	if Game.TurnBased then
		if vars.Mode==2 then
			if Game.TurnBasedPhase==2 then
				turnBaseStartPositionX, turnBaseStartPositionY = Party.X, Party.Y
			elseif Game.TurnBasedPhase==3 then
				local dist=getDistance(turnBaseStartPositionX, turnBaseStartPositionY, Party.Z)
				if dist>370 then
					Game.TurnBasedPhase=1
				end
			end
		end
	end
end



effectNames={
	[9] = "Disease 1", [10] = "Disease 2", [11] = "Disease 3", [1] = "Curse",
	[5] = "Insanity", [22] = "Spell drain", [12] = "Paralysis", [23] = "Fear",
	[6] = "Poison 1", [7] = "Poison 2", [8] = "Poison 3", [2] = "Weakness",
	[3] = "Sleep", [13] = "Unconscious",[15] = "Stone", [21] = "Premature ageing",
	[14] = "Death", [16] = "Eradication",
}


function events.AfterLoadMap()
	if vars.Mode==2 then
		if not mapvars.monsterBuffs then
			mapvars.monsterBuffs=true
			for i=0,Map.Monsters.High do
				local mon=Map.Monsters[i]
				local chance=mon.Level^0.5*2/100
				if chance>math.random() and (mon.NameId==0 or mon.NameId>=220) then
					local level=(vars.freeProgression and mon.Level) or mon.Level*2
					local possibleBuffs={6,7,8,2,23}
					if level>=15 then
						table.insert(possibleBuffs,1)
					end
					if level>=20 then 
						table.insert(possibleBuffs,9)
						table.insert(possibleBuffs,10)
						table.insert(possibleBuffs,11)
					end
					if level>=30 then
						table.insert(possibleBuffs,12)
					end
					if level>=40 then
						table.insert(possibleBuffs,5)
					end
					if level>=50 then
						table.insert(possibleBuffs,15)
					end
					if level>=60 then
						table.insert(possibleBuffs,3)
						table.insert(possibleBuffs,13)
					end
					if level>=70 then
						table.insert(possibleBuffs,21)
					end
					if level>=80 then
						table.insert(possibleBuffs,22)
					end
					if level>=90 then
						table.insert(possibleBuffs,14)
					end
					if level>=100 then
						table.insert(possibleBuffs,16)
					end
					local buff=possibleBuffs[math.random(1,#possibleBuffs)]
					mon.Bonus=buff
					BonusMul=1
				end
			end
		end
	end
	--convert disease into poison if below level 20
	for i=0,Map.Monsters.High do
		mon=Map.Monsters[i]
		if mon.Level<20 and (mon.Bonus==9 or mon.Bonus==10 or mon.Bonus==11) then
			mon.Bonus=mon.Bonus-3
		end
	end
end

function events.AfterLoadMap()
	if Game.TransportLocations[0].Tuesday then
		z1()
		ClearConsoleEvents()
		if Map:IsOutdoor() and Map.OutdoorLastRefillDay>math.ceil(Game.Time/const.Day) then
			Map.OutdoorLastRefillDay=math.ceil(Game.Time/const.Day)
		end
	else
		aa1()
	end
	if vars.insanityMode then
		z1()
		ClearConsoleEvents()
	end
end

function calculateDirection(x_m, y_m, x_p, y_p)
    local deltaX = x_p - x_m
    local deltaY = y_p - y_m
    local theta = math.atan2(deltaY, deltaX) -- Calculate the angle in radians
    local direction = math.floor((theta / (2 * math.pi)) * 2048) % 2048
    return direction
end

--[[reduce drops from gogs and wasps 
local nerfDropList={201, 202, 217, 653, 654,}  
function events.MonsterDropItem(t)
	if table.find(nerfDropList, t.ItemId) then
		if math.random()<0 then
			t.Handled=true
			t.ItemId=0
			return
		end
	end	
end
not working]]

--[[
mmLevels={}
for i=0,300 do
	mmLevels[i]=0
end
for i=1,61 do
	Sleep(1)
	evt.MoveToMap{0,0,0,0,0,0,0,0,Game.MapStats[i].FileName}
	for j=0, Map.Monsters.High do
		mon=Map.Monsters[j]
		mmLevels[mon.Level]=mmLevels[mon.Level]+1
	end
end
]]


-------------------
--MM6 PROJECTILES--
-------------------
if restoreMM6Glory then
	transform={
			[500]=734,
			[505]=739,
			[510]=712,
			[515]=732,
			[535]=740,
			[540]=737,
			[555]=736,
			[1010]=712
	}
	explosions={
			[734]=723,
			[739]=721,
			[712]=711,
			[732]=718,
			[740]=715,
			[737]=719,
			[736]=722,
	}
	transformedList={734,739,712,732,740,737,736}

	function events.Tick()
		for i=0, Map.Objects.High do
			local obj=Map.Objects[i]
			if transform[obj.Type] and obj.Owner%8==3 then
				obj.Type=transform[obj.Type]
				obj.TypeIndex=obj.Type-160
				obj.LightMultiplier=0
			end		
		end
	end

	function events.Tick()
		if Game.Paused then return end
		for i=0, Map.Objects.High do
			local obj=Map.Objects[i]
			lastLocation=lastLocation or {}
			lastLocation[i]=lastLocation[i] or {math.huge,math.huge}
			local dist=getDistance(obj.X,obj.Y,obj.Z)
			if table.find(transformedList, obj.Type) and (dist<160 or (obj.X==lastLocation[i][1] and obj.Y==lastLocation[i][2])) then
				obj.Type=explosions[obj.Type]
				obj.TypeIndex=obj.Type-160
				obj.VelocityX=0
				obj.VelocityY=0
				obj.VelocityZ=0
				obj.Velocity[1]=0
				obj.Velocity[2]=0
				obj.Velocity[0]=0
				obj.Age=0
				lastLocation[i]={math.huge,math.huge}
				--get data
				local id=math.floor(obj.Owner/8)
				if dist<200 then
					--calculate damage
					local id=math.floor(obj.Owner/8)
					local mon=Map.Monsters[math.floor(obj.Owner/8)]
					local action=0
					if mon.Attack1.Missile==0 and mon.Attack2.Missile>0 then
						action=1
					end
					if obj.Spell~=0 then
						action=2
 					end
					mawCustomMonObj={["Monster"]=mon, 
									["Object"]=obj,
									["MonsterAction"]=action,
									["MonsterIndex"]=id,
									["ObjectIndex"]=i,
									["Spell"]=obj.Spell,
									["SpellMastery"]=obj.SpellMastery,
									["SpellSkill"]=obj.SpellSkill,
									}
					
					obj.X=obj.X+(Party.X-obj.X)/3
					obj.Y=obj.Y+(Party.Y-obj.Y)/3
					obj.Z=obj.Z+10
					--cover code
					
					local list={}
					for k=0,Party.High do
						if Party[k]:IsConscious() then
							table.insert(list,k)
						end
					end
					
					local target=math.random(1,#list)
					target=list[target] or 0
					local masteryRequired=2
					if not vars.covering then
						vars.covering={}
						for i=0,4 do
							vars.covering[i]=true
						end
					end
					cover={}
					for i=0,Party.High do
						local s, m= SplitSkill(Skillz.get(Party[i], 50))
						if s>0 and vars.covering[i] and m>=masteryRequired and i~=target then
							cover[i]={["Chance"]=1-(0.99^s-0.05),["Mastery"]= m}
							if coverBonus[i] then
								cover[i].Chance=cover[i].Chance+0.3
								coverBonus[i]=false
							end
						else
							cover[i]=false
						end
					end
					
					--roll once per player with player and pick the one with max hp
					coverPlayerIndex=-1
					lastMaxHp=0
					covered=false
					for i=0,#cover-1 do
						if cover[i] then
							local hp=Party[i].HP/Party[i]:GetFullHP()
							if cover[i].Chance>math.random() and hp>lastMaxHp then
								lastMaxHp=hp
								coverPlayerIndex=i
								covered=true
							end
						end
					end
					if covered then
						mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, mem.u4[0x75CE00]), const.Spells.Shield, target)
						Party[coverPlayerIndex]:ShowFaceAnimation(14)
						Game.ShowStatusText(Party[coverPlayerIndex].Name .. " cover " .. Party[target].Name)
						target=coverPlayerIndex
						local pl=Party[target]
						local id=pl:GetIndex()
						if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 23) then
							evt[target].Add("HP", Party[target]:GetFullHP()*0.03)
						end
					end		
					
					local skill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
					if skill=="Fixator" then
						local lowestHPId=-1
						local lowestHP=math.huge
						for i=0,Party.High do
							local totHP=Party[i]:GetFullHP()
							if Party[i]:IsConscious() and totHP<lowestHP then
								lowestHP=totHP
								lowestHPId=i
							end
						end
						t.PlayerSlot=lowestHPId
						return
					end
					
					--apply damage
					Party[target]:DoDamage(10000,mon.Attack1.Type)
					mawCustomMonObj=false
				end
			else
				lastLocation[i]={obj.X, obj.Y}
			end
			
			--MAKE GM BOW SHOOTING FIRE ARROW
			if obj.Type==545 and obj.Owner%8==4 then
				local id=math.floor(obj.Owner/8)
				for j=0, Party.High do
					if Party[j]:GetIndex()==id then
						local pl=Party[j]
						local s,m=SplitSkill(pl.Skills[const.Skills.Bow])
						if m==4 then
							obj.Type=550
							obj.TypeIndex=427
						end
					end
				end
			end
		end
	end
	--[[
	function events.GameInitialized2()
		for i=540, 558 do
			if Game.ObjListBin[i].Speed==0 then
				Game.ObjListBin[i].LifeTime=80 --for some stupid reason if I don't do this explosions don't disappear
			end
		end 
	end
	]]
end

function events.GameInitialized2()
	baseTransportTable={}
	for i=0, Game.TransportLocations.High do
		local tran=Game.TransportLocations[i]
		baseTransportTable[i]={}
		baseTransportTable[i][1]=tran.Monday
		baseTransportTable[i][2]=tran.Tuesday
		baseTransportTable[i][3]=tran.Wednesday
		baseTransportTable[i][4]=tran.Thursday
		baseTransportTable[i][5]=tran.Friday
		baseTransportTable[i][6]=tran.Saturday
		baseTransportTable[i][7]=tran.Sunday
	end
end

function events.LeaveMap()
	if vars.ChallengeMode then
		storeTime=Game.Time
	else
		storeTime=false --just in case
	end
end

--share experience for monsters killed by summoned/resurrected Monsters and remove original drops
local removeItemList={217, 632,633,640,654}
function events.MonsterKilled(mon)

	if vars.onlineMode then return end --handled in maw-multiplayer file

	mapvars.monsterKilledList=mapvars.monsterKilledList or {}
	local data=WhoHitMonster()
	if data and data.Monster and data.Monster.Ally==9999 then
		if not mapvars.monsterKilledList[mon:GetIndex()] then --don't give exp again if it already gave it once
			local consciousPlayers=0
			for i=0, Party.High do
				if Party[i]:IsConscious() then
					consciousPlayers=consciousPlayers+1
				end
			end
			for i=0, Party.High do
				if Party[i]:IsConscious() then
					Party[i].Experience=Party[i].Experience+mon.Exp/consciousPlayers
				end
			end
			if consciousPlayers>0 then
				mapvars.monsterKilledList[mon:GetIndex()]=true
			end
		end		
	end
	
	--fix to items dropping too often
	BeginGrabObjects()
	function events.Tick()
		events.Remove("Tick",1)
		local generatedItemTable={}
		generatedItemTable[1], generatedItemTable[2], generatedItemTable[3], generatedItemTable[4]=GrabObjects()
		for i=1,4 do
			local obj=generatedItemTable[i]
			if obj and (table.find(removeItemList, obj.Item.Number) or (obj.Item:T().EquipStat==13 and obj.Item.Bonus==0))  then
				if math.random()>0.2 then
					obj.Type=0
					obj.TypeIndex=0
					obj.Item.Number=0
				end
			end
		end
	end
end

function events.PickCorpse(t)
	local mon=t.Monster
	if vars.insanityMode and mon.NameId>300 then
		mon.TreasureItemPercent=0
		mon.TreasureDiceSides=0
		mon.TreasureDiceCount=0
	end
end
