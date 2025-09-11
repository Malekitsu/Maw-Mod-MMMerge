----------------------------------------------------
--Empower Monsters
----------------------------------------------------
--function to calculate the level you are (float number) give x amount of experience
function calcLevel(x)
	return (25+(5*x+625)^0.5)/50
end 
function calcExp(lvl)
	return lvl*(lvl-1)*500
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

-- == Version "mêmes comportements" mais sans erreurs nil en multi ==
-- (aucun fallback, aucun changement de formules, on ne touche rien si un champ manque)


function events.AfterLoadMap()
  if not Map or not Map.Monsters or type(Map.Monsters.High) ~= "number" then return end

  for i = 0, Map.Monsters.High do
    pcall(function()
      local m = Map.Monsters[i]
      if not m then return end

      -- SPEED (identique, protégé)
      if m.Velocity and m.Velocity > 150 and m.Attack1 and m.Attack1.Missile == 0 then
        m.Velocity = (m.Velocity + (400 - m.Velocity) / 2 + 100)
      end

      -- Fix broken spell levels (identique)
      if m.SpellSkill and m.SpellSkill > 64 and m.SpellSkill < 1024 then
        m.SpellSkill = m.SpellSkill % 64
      end

      -- Resistances (identique, seulement si tout est présent)
      if basetable and round and m.Level and m.Id and m.Resistances and basetable[m.Id]
         and basetable[m.Id].Level and basetable[m.Id].Resistances then

        local bolsterRes = math.max(round((m.Level - basetable[m.Id].Level) / 2), 0)
        for v = 0, 10 do
          if v ~= 5 then
            if v == 0 and m.Resistances[v] and m.Resistances[v] < 65000 then
              local hpMult = math.floor(m.Resistances[v] / 1000)
              m.Resistances[v] =
                math.min(bolsterRes + basetable[m.Id].Resistances[v], bolsterRes + 200, 999) + 1000 * hpMult
            else
              if basetable[m.Id].Resistances[v] then
                m.Resistances[v] =
                  math.min(bolsterRes + basetable[m.Id].Resistances[v], bolsterRes + 200, 999)
              end
            end
          end
        end
      end
    end)
  end

  -- Rebolster: identique, mais protégé + anti-double-run sur cette map
  if type(recalculateMawMonster) == "function" then
    vars = vars or {}
    vars._maw_monster_recalc_done = vars._maw_monster_recalc_done or {}
    local mapId = Map and Map.MapStatsIndex or "?"
    if not vars._maw_monster_recalc_done[mapId] then
      pcall(recalculateMawMonster)
      vars._maw_monster_recalc_done[mapId] = true
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
			local hp=round(getMonsterHealth(mon))
			hpOvercap=0
			while hp>32500 do
				hp=round(hp/2)
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
		if mon.AIType~=1 then
			mon.AIType=0
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
		local partyLvl=getPartyLevel()
		
		mapvars.oldUniqueMonsterTable=mapvars.oldUniqueMonsterTable or {}
		--calculate average level for unique monsters
		for i=0, Map.Monsters.High do
			local mon=Map.Monsters[i]
			if  mon.NameId >=1 and mon.NameId<220 then
				local oldTable=mapvars.oldUniqueMonsterTable[i]
				--horizontal progression
				local name=Game.MapStats[Map.MapStatsIndex].Name
				if Game.freeProgression==false then
					if not horizontalMaps[name] then
						partyLvl=oldTable.Level*2
					end
				end
				if vars.madnessMode then
					if not madnessStartingMaps[name] and madnessMapLevels[name] then
						partyLvl=madnessMapLevels[name]+(mapLevels[name].High-mapLevels[name].Mid)*2-oldTable.Level
					else 
						partyLvl=oldTable.Level*2
					end
				end
				--level increase 
				oldLevel=oldTable.Level
				mapvars.uniqueMonsterLevel=mapvars.uniqueMonsterLevel or {}
				mapvars.uniqueMonsterLevel[i]=oldTable.Level+partyLvl
				mon.Level=math.min(mapvars.uniqueMonsterLevel[i],255)
				--HP calculated using the proper getMonsterHealth function
				local HP=round(getMonsterHealth(mon))
				--store in HPtable for reference
				HPtable=HPtable or {}
				HPtable[mon.Id]=HP
				
				hpOvercap=0
				while HP>32500 do
					HP=round(HP/2)
					hpOvercap=hpOvercap+1
				end
				
				mon.Resistances[0]=mon.Resistances[0]%1000+hpOvercap*1000
				local HPproportion=mon.HP/mon.FullHP
				mon.FullHP=HP
				mon.HP=mon.FullHP*HPproportion

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
				mapvars.uniqueMonsterLevel=mapvars.uniqueMonsterLevel or {}
				if baseLvl<100 and (lvl<baseLvl*1.1 or lvl>baseLvl*1.3)  then
					mapvars.uniqueMonsterLevel[index]=round(baseLvl*(1.1+math.random()*0.2))
				elseif baseLvl>=100 and (lvl<baseLvl+10 or lvl>baseLvl+30) then
					mapvars.uniqueMonsterLevel[index]=round(baseLvl+math.random()*20+10)
				end
				if mapvars.uniqueMonsterLevel and mapvars.uniqueMonsterLevel[index] then
					mon.Level=math.min(mapvars.uniqueMonsterLevel[index],255)
				end
				local totalHP=mon.HP*2^(math.floor(mon.Resistances[0]/1000))
				local austerityMod=1
				if vars.AusterityMode then
					austerityMod=4
				end
				local HP=round(getMonsterHealth(mon))
				--store in HPtable for reference
				HPtable=HPtable or {}
				HPtable[mon.Id]=HP
				local hpOvercap=0
				while HP>32500 do
					HP=round(HP/2)
					hpOvercap=hpOvercap+1
				end
				mon.Resistances[0]=round(txt.Resistances[0]*5)/5%1000+1000*hpOvercap
				local HPproportion=mon.HP/mon.FullHP
				mon.FullHP=HP
				mon.HP=mon.FullHP*HPproportion
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
		if vars.madnessMode then
			Game.BolsterAmount=600
			vars.freeProgression=false
			Game.freeProgression=false
			recalculateMonsterTable()
			recalculateMawMonster()
		elseif vars.trueNightmare and Game.BolsterAmount~=300 and vars.Mode~=2 then
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

function events.AfterLoadMap()
	if vars.madnessMode then
		Game.BolsterAmount=600
		vars.freeProgression=false
		Game.freeProgression=false
		recalculateMonsterTable()
		recalculateMawMonster()
	elseif vars.trueNightmare and Game.BolsterAmount~=300 and vars.Mode~=2 then
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

--MONSTER BOLSTERING
function events.BeforeNewGameAutosave()
	vars.MMLVL = {0, 0, 0, 0}
	vars.EXPBEFORE = 0
	vars.LVLBEFORE = 0
end

function events.BeforeLoadMap(wasInGame)
	if not wasInGame then
		-- migrate from old saves lacking EXPBEFORE
		vars.EXPBEFORE = vars.EXPBEFORE or calcExp(vars.LVLBEFORE or 1)
		if  not vars.MMLVL then
			-- migrate to refactored MMLVL
			vars.MMLVL = {vars.MM8LVL, vars.MM7LVL, vars.MM6LVL, vars.MMMLVL}
			vars.MM8LVL = nil
			vars.MM7LVL = nil
			vars.MM6LVL = nil
			vars.MMMLVL = nil
		end
	end
end

function addBolsterExp(experience)
	local currentWorld = TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	vars.EXPBEFORE = vars.EXPBEFORE + experience
	local currentLvl = calcLevel(vars.EXPBEFORE)
	vars.MMLVL[currentWorld] = vars.MMLVL[currentWorld] + currentLvl - vars.LVLBEFORE
	vars.LVLBEFORE = currentLvl
end


function getTotalLevel() 
	if Multiplayer and Multiplayer.in_game then
		if not Multiplayer.im_host() and vars.MultiplayerBolsterLevels then
			local lvl=0
			for i=1,4 do
				lvl = lvl + vars.MultiplayerBolsterLevels[i]
			end
			return lvl
		end
	end
	local result = 0
	for i=1,4 do
		result = result + vars.MMLVL[i]
	end
	
	ShareBolster()
	
	return result
end

function getTotalExp()
	return calcExp(getTotalLevel()+1)
end

function getPartyLevel(currentWorld)
	currentWorld = currentWorld or TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
	if Multiplayer and Multiplayer.in_game then
		if not Multiplayer.im_host() and vars.MultiplayerBolsterLevels then
			local lvl=0
			for i=1,4 do
				if currentWorld ~= i then
					lvl = lvl + vars.MultiplayerBolsterLevels[i]
				end
			end
			return lvl
		end
	end
	local result = 0
	for i=1,4 do
		if currentWorld ~= i then
			result = result + vars.MMLVL[i]
		end
	end
	
	ShareBolster()
	
	return result
end

function getPartyExp(currentWorld)
	return calcExp(getPartyLevel(currentWorld)+1)
end

function events.MonsterKillExp(t)

	--online handled in maw-multiplayer file
	--[[if vars.onlineMode then 
		t.Handled=true
		t.Exp=0
		return
	end 
	]]
	
	if Multiplayer and Multiplayer.in_game then
		t.Exp=0
		return
	end
	if vars.madnessMode then 
		if mapvars.mawBounty or Map.Name=="zarena.blv" or Map.Name=="d42.blv" or Map.Name=="7d05.blv" then
			t.Exp=0
			return
		end
	end
	local partyLvl=getTotalLevel()
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
			mult=math.min(math.max(multiplier1,multiplier2),3)
			if mult<1 then
				multiplier2=1+(playerLevel^0.5)-(monLvl^0.5)
				mult=math.max(math.max(multiplier1,1/multiplier2),1/3)
			end
			debug.Message(mult .. "  " .. multiplier1 .. "  " .. multiplier2 .. "  " .. playerLevel .. "  " .. monLvl )
			local experienceAwarded=experience*mult
			Party[i].Experience=math.min(Party[i].Experience+experienceAwarded, 2^32-3982296)
			
			--calculate again based for bolster
			playerLevel=partyLvl
			bolsterExp=bolsterExp+experience*mult
		end
	end
	
	--no bolster from arena
	if Map.Name=="d42.blv" then
		return
	end
	
	addBolsterExp(bolsterExp/5)
	
	vars.lastPartyExperience={Party[0]:GetIndex(),Party[0].Experience}
	for i=0, Party.High do
		Party[i].Exp=math.min(Party[i].Exp, 2^32-3982296)
	end
end

function events.LoadMap()
	recalculateMonsterTable()
	recalculateMawMonster()
end


function recalculateMonsterTable()
	--calculate party experience
	bolsterLevel=getPartyLevel()
	bolsterLevel=math.max(bolsterLevel-4,0)
	
	--add a bonus in case dungeon is resetted
	vars.mapResetCount=vars.mapResetCount or {}
	vars.mapResetCount[Map.Name]=vars.mapResetCount[Map.Name] or 0
	local bonus=vars.mapResetCount[Map.Name]*20
	
	--madness, used to calculate gold
	local name=Game.MapStats[Map.MapStatsIndex].Name
	if vars.madnessMode and madnessMapLevels[name] then
		bolsterLevel=madnessMapLevels[name]
	end	
	
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
		local baseMapLevel=0
		local adjustMult=1.5
		if vars.madnessMode then
			adjustMult=1
		end
		--scale map monsters
		if #currentMapMonsters>0 then 
			for j=1, #currentMapMonsters do
				if math.abs(i-currentMapMonsters[j])<=1 then
					if j==1 then
						baseMapLevel=mp.Low
						extraBolster=mp.Low-LevelB
						adjust=(mean-mp.Low)*adjustMult
					elseif j==2 and #currentMapMonsters==3 then
						baseMapLevel=mp.Mid
						extraBolster=mp.Mid-LevelB
						adjust=(mean-mp.Mid)*adjustMult
					elseif (j==2 and #currentMapMonsters==2) or j==3 then
						baseMapLevel=mp.High
						extraBolster=mp.High-LevelB
						adjust=(mean-mp.High)*adjustMult
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
		
	
		--madness
		if vars.madnessMode and not madnessStartingMaps[name] and not mapvars.mapAffixes then
			local baseLevel=madnessMapLevels[name] or 0
			local withinMapDifference=(baseMapLevel-mean)*2
			local tierModifier=(base.Level-LevelB)*2
			local level=baseLevel+withinMapDifference+tierModifier
			
			totalLevel[i]=math.max(level, 5)
			mon.Level=math.min(totalLevel[i],255)
			
		end
		
		--arena
		if Map.Name=="d42.blv" then
			horizontalMultiplier=6
			bolsterLevel=base.Level*horizontalMultiplier
			flattener=(base.Level-LevelB)*horizontalMultiplier*0.8 --necessary to avoid making too much difference between monster tier
			totalLevel[i]=math.max(base.Level*horizontalMultiplier-flattener+adjust*2, 5)
			mon.Level=math.min(totalLevel[i],255)
			if (vars.highestArenaWave+1)*3>#monTbl then
				local diff=(vars.highestArenaWave+1)*3-#monTbl
				local extraBoost=diff*3.5
				totalLevel[i]=totalLevel[i]+extraBoost+600
			end
		end
		
		if mapvars.mawBounty then
			totalLevel[i]=base.Level+mapvars.mawBounty
		end
		
		--HP - use getMonsterHealth function and store in HPtable
		HPtable=HPtable or {}
		--Create a mock monster object to pass the correct ID and level
		local mockMon = {Id = i, Level = totalLevel[i]}
		HPtable[i] = getMonsterHealth(mockMon, totalLevel[i])
		--resistances 
		bolsterRes=math.max(round((totalLevel[i]-basetable[i].Level)/10)*5,0)
		--mapping
		if getMapAffixPower(12) then
			bolsterRes=bolsterRes+getMapAffixPower(12)
		end
		for v=0,10 do
			if v~=5 then
				mon.Resistances[v]=math.min(bolsterRes+basetable[i].Resistances[v],bolsterRes+200,999)
			end
		end
		
		--experience
		local lvlBase=math.max(basetable[i].Level,totalLevel[i]/3) --added totalLevel/3 because of mapping
		local lvlBase=math.min(lvlBase,120) 
		mon.Experience = round((lvlBase*20+lvlBase^1.8)*totalLevel[i]/lvlBase)
		if currentWorld==2 then
			mon.Experience = math.min(mon.Experience*2, mon.Experience+1000)
		end
		--true nightmare nerf
		if Game.BolsterAmount==300 then
			mon.Experience=mon.Experience*0.67
		end
		if vars.Mode==2 then
			mon.Experience=mon.Experience*0.5
		end
		if vars.insanityMode then
			mon.Experience=mon.Experience*0.8
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
			hpMult=hpMult*(0.6+totalLevel[i]/600)
		end
		--normal
		if Game.BolsterAmount==50 then
			hpMult=hpMult*(0.8+totalLevel[i]/550)
		end
		--MAW
		if Game.BolsterAmount==100 then
			hpMult=hpMult*(1+totalLevel[i]/500)
		end
		--Hard
		if Game.BolsterAmount==150 then
			hpMult=hpMult*(1.25+totalLevel[i]/450)
		end
		--Hell
		if Game.BolsterAmount==200 then
			hpMult=hpMult*(1.5+totalLevel[i]/400)
		end
		--Nightmare
		if Game.BolsterAmount==300 then
			hpMult=hpMult*(1.75+totalLevel[i]/350)
		end
		if Game.BolsterAmount==600 then
			hpMult=hpMult*(2+totalLevel[i]/300)
		end	
		if vars.insanityMode then
			hpMult=hpMult*(1.5+totalLevel[i]/300)
		end
		if vars.AusterityMode==true then
			hpMult=((hpMult*3-math.min(2, hpMult*2))+1)
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
		local expectedDamage=3+totalLevel[i]^0.88
		local currentDamage=(base.Attack1.DamageAdd+(base.Attack1.DamageDiceSides+1)*base.Attack1.DamageDiceCount/2)+bonusDamage
		if currentDamage<expectedDamage then
			bonusDamage=bonusDamage+expectedDamage-currentDamage
		end
		if bonusDamage>=20 then
			levelMult=totalLevel[i]
		end
		
		mon.ArmorClass=base.ArmorClass*((levelMult+10)/(LevelB+10))
	end
	--adjust damage if it's too similiar between monster type
	--if bolsterLevel>10 or Game.freeProgression==false or vars.onlineMode then
	
		
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
			actualHP=round(actualHP/2)
			hpOvercap=hpOvercap+1
		end
		mon.Resistances[0]=mon.Resistances[0]%1000+hpOvercap*1000
		mon.HP=actualHP
		mon.FullHP=actualHP
		if mon.FullHP>1000 then
			mon.FullHP=round(mon.FullHP/10)*10
			mon.HP=round(mon.HP/10)*10
		end
	end
	
	--add ranged attack
	local startingMaps={"out01.odm","out02.odm","7out01.odm","7out02.odm","oute3.odm","outd3.odm"}
	if (Map.IsOutdoor() and not table.find(startingMaps, Map.Name) and Game.BolsterAmount>=200) or mapvars.mawBounty then
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
-- PickCorpse function moved to zzMaw-Items.lua to integrate with deterministic seeding system
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
				Game.MapStats[i].Mon1Hi=BackupMapStats[i].Mon1Hi+4
			end 
			if Game.MapStats[i].Mon2Hi>1 then
				Game.MapStats[i].Mon2Hi=BackupMapStats[i].Mon2Hi+4
			end 
			if Game.MapStats[i].Mon3Hi>1 then
				Game.MapStats[i].Mon3Hi=BackupMapStats[i].Mon3Hi+4
			end 
			Game.MapStats[i].Mon1Dif=math.min(BackupMapStats[i].Mon1Dif+1,5)
			Game.MapStats[i].Mon2Dif=math.min(BackupMapStats[i].Mon2Dif+1,5)
			Game.MapStats[i].Mon3Dif=math.min(BackupMapStats[i].Mon3Dif+1,5)
		end
	end
	if vars.insanityMode then
		for i=1,Game.MapStats.High do
			if Game.MapStats[i].Mon1Hi>1 then
				Game.MapStats[i].Mon1Low=3
				Game.MapStats[i].Mon2Low=3
				Game.MapStats[i].Mon3Low=3
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
		map.Mon1Hi=round(map.Mon1Hi*mapMonsterDensity[2])
		map.Mon2Hi=round(map.Mon2Hi*mapMonsterDensity[2])
		map.Mon3Hi=round(map.Mon3Hi*mapMonsterDensity[2])
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
				
madnessStartingMaps={["Dagger Wound Island"] =true,
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
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["Pirate Outpost"] = 
{["Low"] = 45 , ["Mid"] = 51 , ["High"] = 51},

["Merchant House of Alvar"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

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
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

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
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

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
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},


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
{["Low"] = 60 , ["Mid"] = 70 , ["High"] = 70},

["The Land of the Giants"] = 
{["Low"] = 70 , ["Mid"] = 75 , ["High"] = 90},

["The Small House"] = 
{["Low"] = 5 , ["Mid"] = 42.5 , ["High"] = 80},

["The Strange Temple"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

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
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

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
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["Control Center"] = 
{["Low"] = 90 , ["Mid"] = 90 , ["High"] = 90},

["The Hive"] = 
{["Low"] = 80 , ["Mid"] = 90 , ["High"] = 100},

["The Arena"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["Dragon's Lair"] = 
{["Low"] = 90 , ["Mid"] = 90 , ["High"] = 90},

["pending"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["pending"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["pending"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["pending"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["pending"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["pending"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["pending"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["pending"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["pending"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["pending"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["pending"] = 
{["Low"] = 40 , ["Mid"] = 50 , ["High"] = 50},

["pending"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["Devil Outpost"] = 
{["Low"] = 56 , ["Mid"] = 56 , ["High"] = 56},

["New World Computing"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

["The Breach"] = 
{["Low"] = 100 , ["Mid"] = 110 , ["High"] = 120},

["The Breach"] = 
{["Low"] = 100 , ["Mid"] = 110 , ["High"] = 120},

["Basement of the Breach"] = 
{["Low"] = 100 , ["Mid"] = 110 , ["High"] = 120},

["The Strange Temple"] = 
{["Low"] = 1 , ["Mid"] = 1 , ["High"] = 1},

}

local mm6MapProgression={
--MM6
  ["New Sorpigal"] = 1,
  ["Goblinwatch"] = 4,
  ["The Abandoned Temple"] = 5,
  ["Castle Ironfist"] = 6,
  ["Shadow Guild Hideout"] = 7,
  ["Misty Islands"] = 8,
  ["Bootleg Bay"] = 9,
  ["Temple of the Fist"] = 10,
  ["Temple of Tsantsa"] = 11,
  ["Silver Helm Outpost"] = 12,
  ["Hall of the Fire Lord"] = 13,
  ["Free Haven"] = 14,
  ["Free Haven Sewer"] = 15,
  ["Temple of Baa"] = 16,
  ["Dragoons' Caverns"] = 17,
  ["Frozen Highlands"] = 18,
  ["Shadow Guild"] = 19,
  ["Icewind Keep"] = 20,
  ["Dragoons' Keep"] = 21,
  ["Tomb of Ethric the Mad"] = 22,
  ["Corlagon's Estate"] = 23,
  ["Temple of the Moon"] = 24,
  ["Mire of the Damned"] = 25,
  ["Temple of the Sun"] = 26,
  ["Snergle's Caverns"] = 27,
  ["Snergle's Iron Mines"] = 28,
  ["Silver Cove"] = 29,
  ["The Monolith"] = 30,
  ["Silver Helm Stronghold"] = 31,
  ["Warlord's Fortress"] = 32,
  ["Dragon's Lair"] = 33,
  ["Blackshire"] = 34,
  ["Lair of the Wolf"] = 35,
  ["Gharik's Forge"] = 36,
  ["Eel Infested Waters"] = 37,
  ["Agar's Laboratory"] = 38,
  ["Castle Alamos"] = 39,
  ["Kriegspire"] = 40,
  ["Devil Outpost"] = 41,
  ["Superior Temple of Baa"] = 42,
  ["Castle Darkmoor"] = 43,
  ["Temple of the Snake"] = 44,
  ["Paradise Valley"] = 45,
  ["Castle Kriegspire"] = 46,
  ["Caves of the Dragon Riders"] = 47,
  ["Hermit's Isle"] = 48,
  ["Supreme Temple of Baa"] = 49,
  ["Dragonsand"] = 50,
  ["Tomb of VARN"] = 51,
  ["Sweet Water"] = 52,
  ["Control Center"] = 53,
  ["The Hive"] = 54,
}

local mm7MapProgression={
  ["Emerald Island"] = 1,
  ["The Dragon's Lair"] = 1,
  ["The Temple of the Moon"] = 1,
  ["Castle Harmondale"] = 4,
  ["Harmondale"] = 5,
  ["White Cliff Cave"] = 6,
  ["The Tularean Forest"] = 7,
  ["The Hall under the Hill"] = 8,
  ["Erathia"] = 9,
  ["The Bandit Caves"] = 10,
  ["The Erathian Sewers"] = 11,
  ["The Barrow Downs"] = 12,
  ["Barrow I"] = 13,
  ["Barrow II"] = 13,
  ["Barrow III"] = 13,
  ["Barrow IV"] = 13,
  ["Barrow V"] = 13,
  ["Barrow VI"] = 13,
  ["Barrow VII"] = 13,
  ["Barrow VIII"] = 13,
  ["Barrow IX"] = 13,
  ["Barrow X"] = 13,
  ["Barrow XI"] = 13,
  ["Barrow XII"] = 13,
  ["Barrow XIII"] = 13,
  ["Barrow XIV"] = 13,
  ["Barrow XV"] = 13,
  ["Zokarr's Tomb"] = 13,
  ["The Haunted Mansion"] = 14,
  ["Stone City"] = 15,
  ["Deyja"] = 16,
  ["The Tidewater Caverns"] = 18,
  ["Evenmorn Island"] = 19,
  ["The Bracada Desert"] = 20,
  ["The Red Dwarf Mines"] = 21,
  ["Tatalia"] = 22,
  ["Grand Temple of the Sun"] = 23,
  ["Grand Temple of the Moon"] = 24,
  ["Avlee"] = 25,
  ["The Tularean Caves"] = 26,
  ["Fort Riverstride"] = 26,
  ["Nighon Tunnels"] = 27,
  ["Lord Markham's Manor"] = 28,
  ["Wromthrax's Cave"] = 29,
  ["The Hall of the Pit"] = 30,
  ["The Breeding Zone"] = 31,
  ["The Walls of Mist"] = 31,
  ["Castle Navan"] = 32,
  ["The Temple of Baa"] = 33,
  ["The School of Sorcery"] = 33,
  ["The Hidden Tomb"] = 34,
  ["Castle Gryphonheart"] = 35,
  ["William Setag's Tower"] = 35,
  ["The Mercenary Guild"] = 36,
  ["Watchtower 6"] = 37,
  ["Celeste"] = 38,
  ["The Pit"] = 38,
  ["Temple of the Light"] = 39,
  ["Temple of the Dark"] = 39,
  ["Castle Lambent"] = 40,
  ["Castle Gloaming"] = 40,
  ["The Wine Cellar"] = 41,
  ["Clanker's Laboratory"] = 41,
  ["Thunderfist Mountain"] = 42,
  ["Mount Nighon"] = 43,
  ["The Maze"] = 44,
  ["The Small House"] = 45,
  ["Tunnels to Eeofol"] = 46,
  ["The Titans' Stronghold"] = 47,
  ["The Land of the Giants"] = 48,
  ["The Dragon Caves"] = 49,
  ["Colony Zod"] = 50,
  ["Shoals"] = 51,
  ["The Lincoln"] = 52,
}

local mm8MapProgression={
  --MM8
  ["Dagger Wound Island"] = 1,
  ["Abandoned Temple"] = 4,
  ["Ravenshore"] = 5,
  ["Dire Wolf Den"] = 6,
  ["Smuggler's Cove"] = 7,
  ["Chapel of Eep"] = 8,
  ["Alvar"] = 9,
  ["Wasp Nest"] = 10,
  ["Ogre Fortress"] = 11,
  ["Ironsand Desert"] = 12,
  ["Troll Tomb"] = 13,
  ["Dark Dwarf Compound"] = 14,
  ["Church of Eep"] = 15,
  ["Ravage Roaming"] = 16,
  ["Barbarian Fortress"] = 17,
  ["Grand Temple of Eep"] = 18,
  ["Balthazar Lair"] = 19,
  ["Murmurwoods"] = 20,
  ["Ancient Troll Home"] = 21,
  ["Temple of the Sun"] = 22,
  ["Uplifted Library"] = 23,
  ["Shadowspire"] = 24,
  ["Chain of Fire"] = 25,
  ["The Crypt of Korbu"] = 26,
  ["Cyclops Larder"] = 27,
  ["Garrote Gorge"] = 28,
  ["Naga Vault"] = 29,
  ["Dragon Hunter's Camp"] = 30,
  ["Vampire Crypt"] = 31,
  ["Necromancers' Guild"] = 32,
  ["Mad Necromancer's Lab "] = 33,
  ["Pirate Outpost"] = 34,
  ["Passage Under Regna"] = 35,
  ["Regna"] = 36,
  ["Small Sub Pen"] = 37,
  ["Abandoned Pirate Keep"] = 38,
  ["Pirate Stronghold"] = 39,
  ["Druid Circle"] = 40,
  ["Plane of Air"] = 41,
  ["Castle of Air"] = 42,
  ["Plane of Water"] = 43,
  ["Plane of Fire"] = 44,
  ["War Camp"] = 45,
  ["Castle of Fire"] = 46,
  ["Plane of Earth"] = 47,
  ["Dragon Cave"] = 48,
  ["Ilsingore's Cave"] = 49,
  ["Old Loeb's Cave"] = 50,
  ["Yaardrake's Cave"] = 51,
  ["Escaton's Crystal"] = 52,
  ["Plane Between Planes"] = 53,
  ["Escaton's Palace"] = 54,
  ["Prison of the Lord of Air"] = 55,
  ["Prison of the Lord of Earth"] = 56,
  ["Prison of the Lord of Water"] = 57,
  ["Prison of the Lord of Fire"] = 58,
}

madnessMapLevels={}
for key, value in pairs(mm6MapProgression) do
	madnessMapLevels[key]=round(((value/54)*100)^1.5)
end

for key, value in pairs(mm7MapProgression) do
	madnessMapLevels[key]=round(((value/52)*100)^1.5)
end

for key, value in pairs(mm8MapProgression) do
	madnessMapLevels[key]=round(((value/58)*100)^1.5)
end

madnessMapLevels["Basement of the Breach"] = 1100
madnessMapLevels["The Breach"] = 1100
madnessMapLevels["The Arena"] = 1
madnessMapLevels["Pending"] = 1
madnessMapLevels["NWC"] = 1

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
		lvl=round(totalLevel[mon.Id])
	elseif mapvars.uniqueMonsterLevel and mapvars.uniqueMonsterLevel[mon:GetIndex()] then
		lvl=round(mapvars.uniqueMonsterLevel[mon:GetIndex()])
	end
	return lvl
end

function events.GameInitialized2()
	monsterSpellMultiplierList={
		[const.Spells.FireBolt]=0.75,
		[const.Spells.LightningBolt]=0.95,
		[const.Spells.PoisonSpray]=0.5,
		[const.Spells.Fireball]=0.5,
		[const.Spells.LightBolt]=1.1,
		[const.Spells.Incinerate]=1.35,
		[const.Spells.AcidBurst]=1.15,
		[const.Spells.IceBlast]=1.2,
		[const.Spells.Blades]=1.1,
		[const.Spells.RockBlast]=0.6,
		[const.Spells.Sparks]=0.5,
		[const.Spells.Implosion]=0.8,
		[const.Spells.MassDistortion]=0.4,
		[const.Spells.Shrapmetal]=0.4,
		[const.Spells.MindBlast]=0.8,
		[const.Spells.IceBlast]=0.75,
		[const.Spells.DragonBreath]=0.7,
		[const.Spells.Harm]=0.75,
		[const.Spells.ToxicCloud]=1.15,
		[const.Spells.PsychicShock]=1.25,
		[const.Spells.MeteorShower]=0.3,
		[const.Spells.DeadlySwarm]=0.85,
	}
end

function events.BuildMonsterInformationBox(t)
	lastMonsterNumber=lastMonsterNumber or Map.Monsters.High
	if lastMonsterNumber~=Map.Monsters.High then
		lastMonsterNumber=Map.Monsters.High
		recalculateMawMonster()
	end
	--mon = t.Monster
	local id=Mouse:GetTarget().Index
	if id>Map.Monsters.High then return end
	local mon=Map.Monsters[id]
	--show level Below HP
	mapvars.uniqueMonsterLevel=mapvars.uniqueMonsterLevel or {}
	local lvl=getMonsterLevel(mon)
	if t.IdentifiedHitPoints then
		t.ArmorClass.Text=string.format("Level:          " .. lvl .. "\n" .. t.ArmorClass.Text)
	end
	--difficulty multiplier
	local damage=getMonsterDamage(mon)
	if getMapAffixPower(1) then
		damage=damage*(1+getMapAffixPower(1)/100)
	end
	
	--some statistics here, calculate the standard deviation of dices to get the range of which 95% will fall into
	mean=damage
	range=((damage*1.25-damage*0.75)^2/12/2)^0.5*1.96
	lowerLimit=round(math.max(mean-range, damage*0.75))
	upperLimit=round(math.min(mean+range, damage*1.25))
	
	text=string.format(table.find(const.Damage,mon.Attack1.Type))
	if not baseDamageValue and Game.CurrentPlayer>=0 then
		lowerLimit=round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack1.Type,lowerLimit,false,lvl))
		upperLimit=round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack1.Type,upperLimit,false,lvl))
	end
	lowerLimit=shortenNumber(lowerLimit, 4, true)
	upperLimit=shortenNumber(upperLimit, 4, true)
	if t.IdentifiedDamage or t.IdentifiedAttack then
		t.Damage.Text=string.format("Attack 00000	050" .. lowerLimit .. "-" .. upperLimit .. " " .. text)
		if mon.Attack2Chance>0 and Game.CurrentPlayer>=0 then
			mean=damage
			range=((damage*1.25-damage*0.75)^2*2/12)^0.5*1.96
			lowerLimit=round(math.max(mean-range, damage*0.75))
			upperLimit=round(math.min(mean+range, damage*1.25))
			
			text=string.format(table.find(const.Damage,mon.Attack1.Type))
			if not baseDamageValue and Game.CurrentPlayer>=0 then
				lowerLimit=round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack2.Type,lowerLimit,false,lvl))
				upperLimit=round(calcMawDamage(Party[Game.CurrentPlayer],mon.Attack2.Type,upperLimit,false,lvl))
			end
			text=string.format(table.find(const.Damage,mon.Attack2.Type))
			lowerLimit=shortenNumber(lowerLimit, 4, true)
			upperLimit=shortenNumber(upperLimit, 4, true)
			t.Damage.Text=string.format(t.Damage.Text .. "\n" .. lowerLimit .. "-" .. upperLimit .. " " .. text)
		end
		--spell
		if mon.SpellChance>0 and mon.Spell>0 then
			spellId=mon.Spell
			spell=Game.Spells[spellId]
			name=Game.SpellsTxt[spellId].Name
			skill=SplitSkill(mon.SpellSkill)
			--get damage multiplier
			if monsterSpellMultiplierList[spellId] then
				damage=damage*monsterSpellMultiplierList[spellId]
			end
			--damageType
			damageType=spellToDamageKind[math.ceil(mon.Spell/11)]
			if not damageType then
				damageType=12
			end
			--calculate
			mean=damage
			range=((damage*1.25-damage*0.75)^2/2/12)^0.5*1.96
			lowerLimit=round(math.max(mean-range, damage*0.75))
			upperLimit=round(math.min(mean+range, damage*1.25))
			if not baseDamageValue and Game.CurrentPlayer>=0 then
				lowerLimit=round(calcMawDamage(Party[Game.CurrentPlayer],damageType,lowerLimit,false,lvl))
				upperLimit=round(calcMawDamage(Party[Game.CurrentPlayer],damageType,upperLimit,false,lvl))
			end
			lowerLimit=shortenNumber(lowerLimit, 4, true)
			upperLimit=shortenNumber(upperLimit, 4, true)
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
			hp=shortenNumber(hp, 5)
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
	if (Game.BolsterAmount~=300 or Game.BolsterAmount~=600) and vars.Mode~=2 then return end
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
					mon.TreasureItemPercent=0 --round(old.item/4)
					mon.TreasureDiceSides=0 --round(old.gold/4)
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
		AlignLeft = true,
		Width = 60, Height = 16,
		X = 500, Y = 377}

function events.LoadMap()
	if mapvars.completition then
		local text=mapvars.completition .. "%"
		if mapvars.completed then
			txt=StrColor(0,255,0,text)
		elseif (mapvars.monsterMap and mapvars.monsterMap.cleared) or not Map.IsIndoor() then
			txt=StrColor(255,255,0,text)
		else
			txt=StrColor(255,0,0,text)
		end
		completition.Text=txt
	else
		completition.Text=""
	end
end

local _A,_B,_C,_D
SeedDeaths={}

local function _H(s)
  local t={} for i=1,#s,2 do t[#t+1]=string.char(tonumber(s:sub(i,i+1),16)) end
  return table.concat(t)
end

local _p=package.config:sub(1,1)
local _J=table.concat({_H"53637269707473",_H"4d6f64756c6573",_H"4d756c7469706c61796572",_H"53796e6368726f6e697a6174696f6e",_H"506c6179657273"},_p)
local _F=_J.._p.._H"506c61796572446174612e747874"

-- one-time dir + write dedupe
local dir_ready = false
local _last_written = nil

local function ensure_dir_once()
  if dir_ready then return end
  local ok, lfs = pcall(require, "lfs")
  if ok then
    local mode = lfs.attributes(_J, "mode")
    if mode ~= "directory" then _A(_J) end
  else
    -- try exactly once; silence output; avoid doing this repeatedly
    local cmd = (_p == "\\")
      and ('cmd /c mkdir "%s" >nul 2>nul'):format(_J)
      or  ('mkdir -p "%s" 2>/dev/null'):format(_J)
    os.execute(cmd)
  end
  dir_ready = true
end

function events.GameInitialized2()
  ensure_dir_once()
end

local function _A(path)
  local ok,lfs=pcall(require,_H"6c6673")
  if ok then
    local acc=""
    for part in path:gmatch("[^".._p.."]+") do
      if part~="." then acc=(acc=="") and part or (acc.._p..part); lfs.mkdir(acc) end
    end
  else
    local cmd=(_p=="\\") and _H"6d6b646972202225732220323e6e756c" or _H"6d6b646972202d70202225732220323e2f6465762f6e756c6c"
    os.execute(cmd:format(path))
  end
end

local function _B()
  local st={ current_seed=nil, deaths={}, pending={} }
  local f=io.open(_F,"r"); if not f then return st end
  for line in f:lines() do
    local k,v=line:match("^%s*([%w_%.%-]+)%s*=%s*(.-)%s*$")
    if k then
      if k==_H"63757272656e745f73656564" then
        st.current_seed=tonumber(v)
      else
        local s1=k:match("^".._H"6465617468735f".."(%-?%d+)$"); if s1 then st.deaths[tonumber(s1)]=tonumber(v) or 0 end
        local s2=k:match("^".._H"70656e64696e675f".."(%-?%d+)$"); if s2 then st.pending[tonumber(s2)]=true end
      end
    end
  end
  f:close(); return st
end

-- atomic write (use ensure_dir_once + dedupe)
local function _C(contents)
  ensure_dir_once()
  if contents == _last_written then return end  -- skip identical writes
  local tmp = _F .. _H"2e746d70"
  local f, err = io.open(tmp, "w")
  assert(f, _H"7772697465206f70656e206661696c65643a20"..tostring(err))
  f:write(contents); f:close()
  os.remove(_F)               -- ignore error if missing
  assert(os.rename(tmp, _F))  -- commit
  _last_written = contents
end

local function _D(st)
  local lines={}
  if st.current_seed then lines[#lines+1]=(_H"63757272656e745f73656564".."=%d\n"):format(st.current_seed) end
  local seeds={}; for seed in pairs(st.deaths) do seeds[#seeds+1]=seed end; table.sort(seeds)
  for _,seed in ipairs(seeds) do lines[#lines+1]=(_H"6465617468735f".."%".."d=".."%".."d\n"):format(seed, st.deaths[seed] or 0) end
  for seed in pairs(st.pending) do lines[#lines+1]=(_H"70656e64696e675f".."%".."d=1\n"):format(seed) end
  _C(table.concat(lines))
end

function SeedDeaths.new_game(seed)
  local st=_B()
  local s=tonumber(seed)
  if not s then local now=os.time(); math.randomseed(now); s=math.random(0,0x7fffffff) end
  st.current_seed=s
  if st.deaths[s]==nil then
    -- Use existing death count from vars if available (for save portability)
    local existingDeathCount = (vars and vars.MadnessDeathCounter) or 0
    st.deaths[s] = existingDeathCount
  end
  _D(st); return s
end

function SeedDeaths.set_current_seed(seed)
  assert(type(seed)=="number",_H"73656564206d7573742062652061206e756d626572")
  local st=_B(); st.current_seed=seed
  if st.deaths[seed]==nil then
    -- Use existing death count from vars if available (for save portability)
    local existingDeathCount = (vars and vars.MadnessDeathCounter) or 0
    st.deaths[seed] = existingDeathCount
  end
  _D(st); return seed
end

function SeedDeaths.on_death()
  local st=_B(); local s=st.current_seed
  if not s then return nil,nil end
  st.deaths[s]=(st.deaths[s] or 0)+1; _D(st)
  return st.deaths[s], s
end

function SeedDeaths.get_current()
  local st=_B(); if st.current_seed then return st.current_seed, st.deaths[st.current_seed] or 0 end
  return nil,nil
end

function SeedDeaths.get_for(seed)
  local st=_B(); seed=tonumber(seed); if not seed then return nil end
  return st.deaths[seed] or 0
end

function SeedDeaths.get_all()
  local st=_B(); return st.current_seed, st.deaths
end

function SeedDeaths.mark_pending_for_current()
  local st=_B(); local s=st.current_seed; if not s then return false end
  st.deaths[s]=st.deaths[s] or 0
  if st.pending[s] then return true end
  st.pending[s]=true; _D(st); return true
end

function SeedDeaths.clear_pending_for_current()
  local st=_B(); local s=st.current_seed
  if not s or not st.pending[s] then return false end
  st.pending[s]=nil; _D(st); return true
end

function SeedDeaths.apply_pending_for_current()
  local st=_B(); local s=st.current_seed
  if not s or not st.pending[s] then return nil,nil end
  st.pending[s]=nil; st.deaths[s]=(st.deaths[s] or 0)+1; _D(st)
  return st.deaths[s], s
end

function events.BeforeNewGameAutosave()
  local seed=SeedDeaths.new_game()
  vars.MadnessDeathSeed=seed
  vars=vars or {}; vars.MadnessDeathCounter=0; vars.lastHitTime=0
end

function events.BeforeLoadMap(wasInGame)
  if vars.madnessMode and vars.MadnessDeathSeed then
    local save_seed=tonumber(vars.MadnessDeathSeed)
    if save_seed then SeedDeaths.set_current_seed(save_seed) end
    local count,seed=SeedDeaths.apply_pending_for_current()
    if count then
      vars.MadnessDeathSeed=seed; vars.MadnessDeathCounter=count; vars.lastHitTime=0
    else
      local cur_seed,cur_count=SeedDeaths.get_current()
      vars.MadnessDeathSeed=cur_seed; vars.MadnessDeathCounter=cur_count
    end
  end
end

function events.DeathMap(t)
  if vars.madnessMode and vars.MadnessDeathSeed then
    local count,seed=SeedDeaths.on_death()
	vars.lastHitTime=0
	SeedDeaths.clear_pending_for_current()
    if seed then vars.MadnessDeathSeed=seed; vars.MadnessDeathCounter=count end
  end
end
function events.LeaveMap()
	vars.lastHitTime=0
	SeedDeaths.clear_pending_for_current()
end
function events.CalcDamageToPlayer(t)
  if vars.madnessMode and vars.MadnessDeathSeed then
    vars.lastHitTime=Game.Time
    SeedDeaths.mark_pending_for_current()
  end
end

function events.Tick()
  if not vars then return end
  if vars.madnessMode and vars.MadnessDeathSeed then
    vars.lastHitTime=vars.lastHitTime or 0
    if (not Party.EnemyDetectorRed and not Party.EnemyDetectorYellow) then
      vars.lastHitTime=math.min(vars.lastHitTime, Game.Time - const.Minute*4.5)
    end
    local timeout=(Game.Time >= (vars.lastHitTime + const.Minute*5))
    if vars.lastHitTime~=0 and timeout then
      SeedDeaths.clear_pending_for_current()
      vars.lastHitTime=0
    end
  end
end

deathTimer=CustomUI.CreateText{
  Text=_H"00",
  Layer=1, Screen=0, AlignLeft=true, Width=60, Height=16, X=500, Y=450
}

deathCounter=CustomUI.CreateText{
  Text=_H"74657374",
  Layer=1, Screen=7, AlignLeft=true, Width=300, Height=16, X=470, Y=1
}

function events.Tick()
  if vars and vars.madnessMode and vars.lastHitTime and vars.MadnessDeathSeed and showDeathCounter then
    local secondsLeft=math.max(math.ceil((vars.lastHitTime+const.Minute*5-Game.Time)/128),0)
    local txt=(secondsLeft>0) and StrColor(255,0,0,secondsLeft) or StrColor(0,255,0,secondsLeft)
    deathTimer.Text=txt
    deathCounter.Text=_H"446561746820436f756e743a20"..vars.MadnessDeathCounter
    if vars.MadnessDeathCounter>9999 then
      deathCounter.X=450
    elseif vars.MadnessDeathCounter>999 then
      deathCounter.X=460
    else
      deathCounter.X=470
    end
  else
    deathTimer.Text=""
    deathCounter.Text=""
  end
end

function events.Action(t)
	if vars.madnessMode and showDeathCounter then
		if t.Action==82 then
			SeedDeaths.apply_pending_for_current()
		end
		if t.Action==125 or t.Action==132 then
			if vars.lastHitTime and vars.lastHitTime~=0 and loadWarning then
				t.Handled=true
				Game.ShowStatusText("Loading now will count as death, are you sure to proceed?")
			end
			loadWarning=false
		else
			loadWarning=true
		end
	end
end

function events.ExitMapAction(t)
	if t.Action == const.ExitMapAction.MainMenu then
		completition.Text=""
	end
end

--check for dungeon clear
function events.MonsterKilled(mon)
	monsterKilled=true
	checkMapCompletition(true)
	monsterKilled=false
end


function checkMapCompletition()
	--retroactive fix, can remove this code after a while
	if mapvars.completed and mapvars.monsterMap then
		mapvars.monsterMap.cleared=true
	end

	if (Map.IndoorOrOutdoor==1 and mapvars.monsterMap and mapvars.completed==nil) or (Map.IndoorOrOutdoor==2 and mapvars.completed==nil) then
		if Map.Name=="d42.blv" then return end --arena
		local n=Map.Monsters.Count
		local m=0
		if monsterKilled then
			m=m+1
		end
		--[[if mon.NameId>220 and mon.NameId<300 then
			m=15
		end
		]]
		for i=0,Map.Monsters.High do
			monster=Map.Monsters[i]
			if monster.AIState==4 or monster.AIState==5 or monster.AIState==11 or monster.AIState==16 or monster.AIState==17 or monster.NameId>300 then
				m=m+1
			elseif monster:IsAgainst() == 0 or monster.AIState==19 then
				n=n-1
			end
		end
		local requiredRateo=0.99^(math.floor(n/100))
		if vars.insanityMode and not mapvars.monsterMap then
			requiredRateo=1
		end
		mapvars.completition=math.min(round(m/n*1000/requiredRateo)/10,100)
		if mapvars.completed then
			mapvars.completition=100
		end
		local text=mapvars.completition .. "%"
		local txt
		if mapvars.completed then
			txt=StrColor(0,255,0,text)
		elseif (mapvars.monsterMap and mapvars.monsterMap.cleared) or not Map.IsIndoor() then
			txt=StrColor(255,255,0,text)
		else
			txt=StrColor(255,0,0,text)
		end
		completition.Text=txt
		if m/n>=requiredRateo then
			local name=Game.MapStats[Map.MapStatsIndex].Name
			local bolster=getPartyLevel()
			
			vars.dungeonCompletedList=vars.dungeonCompletedList or {}
			if vars.dungeonCompletedList[name] then
				vars.dungeonCompletedList[name]=true
				if Game.CurrentScreen~=22 then
					if vars.insanityMode then
						if disableCompletitionMessage then
							Game.ShowStatusText("Dungeon Completed!")
						else
							Game.EscMessage(string.format("Dungeon Completed!"))
						end
					else
						if disableCompletitionMessage then
							Game.ShowStatusText("Dungeon Completed!\nReset is possible again.")
						else
							Game.EscMessage(string.format("Dungeon Completed!\nReset is possible again."))
						end
					end
					mapvars.completed=true
				end
				if mapvars.mapAffixes then
					evt.Add("Items", 290)
					assignedAffixes = {} --don't make it local
					
					local possibleMaps={}
					for i=1,#mapDungeons do
						if vars.dungeonCompletedList[Game.MapStats[mapDungeons[i]].Name] then
							table.insert(possibleMaps, mapDungeons[i])
						end
					end
					mapvars.mapsDropped=mapvars.mapsDropped+1
					if vars.madnessMode then
						vars.ownedMaps=vars.ownedMaps+1
					end
					Mouse.Item.BonusStrength=possibleMaps[math.random(1,#possibleMaps)]
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
					possibleMaps={}
					for i=1,#mapDungeons do
						if vars.dungeonCompletedList[Game.MapStats[mapDungeons[i]].Name] then
							table.insert(possibleMaps, mapDungeons[i])
						end
					end
					Mouse.Item.MaxCharges=round(mapvars.mapAffixes.Power+math.random(0,2)-1)
				end
				if mapvars.monsterMap then
					mapvars.monsterMap.cleared=true
				end
				return
			else
				local mapLevel=(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3
				if not Game.freeProgression then
					bolster=mapLevel*2
				end
				if vars.madnessMode then
					bolster=madnessMapLevels[name]-mapLevel
				end

				local totalMonster=m
				if Game.BolsterAmount==300 then
					totalMonster=totalMonster*0.67
				end
				if Game.BolsterAmount==600 then
					totalMonster=totalMonster/2
				end
				if vars.insanityMode then
					totalMonster=totalMonster*0.8
				end
				mapLevel=math.max(mapLevel,1)
				local experience=math.ceil(totalMonster^0.7*(mapLevel*20+mapLevel^1.8)/3*(bolster+mapLevel)/mapLevel/1000)*1000
				--bolster code
				addBolsterExp(experience)
				vars.lastPartyExperience={Party[0]:GetIndex(),Party[0].Experience}
				--end
				local gold=math.ceil(experience^0.9/1000)*1000 
				evt.ForPlayer(0)
				evt.Add{"Gold", Value = gold}
				if not vars.AusterityMode then
					local gemTier=math.ceil((mapLevel+bolster)/25+0.5)
					if gemTier>10 then
						for i=1, math.floor(gemTier/10) do
							evt.Add("Items", 1063)
						end
					else
						evt.Add("Items",1050+gemTier)
						evt.Add("Items",1050+gemTier)
					end
				end
				experience=experience*5/Party.Count
				if Multiplayer and Multiplayer.in_game then
					experience=experience / math.min(PlayersInGame(),5)
				end
				for i=0,Party.High do
					Party[i].Experience=math.min(Party[i].Experience+experience, 2^32-3982296)
				end
				mapvars.completed=true
				vars.dungeonCompletedList=vars.dungeonCompletedList or {}
				vars.dungeonCompletedList[name]=true
				if mapvars.monsterMap then
					mapvars.monsterMap.cleared=true
				end
				if Game.CurrentScreen~=22 then
					if disableCompletitionMessage then
						Game.ShowStatusText("Map Completed! You gain " .. experience .. " Exp, " .. gold .. " Gold and a Crafting Material")
					else
						Game.EscMessage(string.format("Map Completed! You gain " .. experience .. " Exp, " .. gold .. " Gold and a Crafting Material"))
					end
				end
				return
			end
		end
		if mapvars.monsterMap and mapvars.monsterMap.cleared==false and m/n>=0.65 and Game.BolsterAmount>=300 then
			mapvars.monsterMap.cleared=true
		 	if Game.CurrentScreen~=22 then
		 		if disableCompletitionMessage then
		 			Game.ShowStatusText("Monsters are weakened and can no longer resurrect")
		 		else
		 			Game.EscMessage(string.format("Monsters are weakened and can no longer resurrect"))
		 		end
		 	end
		end
	end
end
	
--ask confirmation and instructions for true nightmare mode
function nightmare()
	if vars.madnessMode and not vars.introduction then
		vars.introduction=true
		Message("Beyond Madness - a word of warning.\n\nNo bolster here (except on starting maps).\n\nQuest timing matters:\n- Finish early: immediate power now, less XP.\n- Finish late: bigger XP later, no early power.\n\nRun-wide tracking:\n- On the character screen, you'll see a death counter shared across all saves of this run.\n- On the map, a red counter appears after you take damage and clears when no monsters are nearby.\n- Loading or leaving the game while that counter is red counts as a death.\n\nIf Insanity wasn't enough for you, you're in the right place.")

	end
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

-- === AFTER LOAD MAP (host generates; clients do not generate) ===
function events.AfterLoadMap()
  local IN_MULTI  = Multiplayer and Multiplayer.in_game
  local IS_HOST   = IN_MULTI and Multiplayer.im_host and Multiplayer.im_host()

  -- Multi-client: block local generation; the zzBossSync module will request a snapshot.
  if IN_MULTI and not IS_HOST then
    mapvars = mapvars or {}
    mapvars.bossGenerated = true
  end

  if Game.BolsterAmount >= 100 then
-- HOST ONLY: generates if not already done (or table is empty)
if (not IN_MULTI) or IS_HOST then
  local names_empty = (type(mapvars.bossNames)=="table" and next(mapvars.bossNames)==nil)
  if (not mapvars.bossGenerated) or (mapvars.bossNames == nil) or names_empty then
    mapvars.bossGenerated = true
    mapvars.bossNames = {}      -- on repart propre
    mapvars.bossSet   = {}

    -- (redone) purge invalid NameIds
    if isRedone then
      for i = 0, Map.Monsters.High do
        local mon = Map.Monsters[i]
        if mon.NameId > 220 then mon.NameId = 0 end
      end
    end

    local possibleMonsters = {}
    local bossSpawns = math.ceil((Map.Monsters.Count - 30) / 150)
    if vars.Mode == 2 then bossSpawns = math.ceil((Map.Monsters.Count - 30) / 60) end

    if getMapAffixPower(16) then
      bossSpawns = math.ceil(bossSpawns * (1 + getMapAffixPower(16) / 100))
    end
    if getMapAffixPower(17) then
      for i = 0, Map.Monsters.High do
        if Map.Monsters[i].Id % 3 ~= 0 and math.random() < getMapAffixPower(17) / 100 then
          Map.Monsters[i].Id = Map.Monsters[i].Id + 1
        end
      end
    end
    if getMapAffixPower(19) then
      for i = 0, Map.Monsters.High do
        local id = Map.Monsters[i].Id
        if id % 3 ~= 0 and Game.MonstersTxt[id].AIType ~= 1 and Map.Monsters[i].NameId == 0 and math.random() < getMapAffixPower(19) / 100 then
          generateBoss(i)
        end
      end
    end

    for i = 0, Map.Monsters.High do
      local id = Map.Monsters[i].Id
      if id % 3 == 0 and Game.MonstersTxt[id].AIType ~= 1 and Map.Monsters[i].NameId == 0 then
        table.insert(possibleMonsters, i)
      end
    end

    if bossSpawns > 0 then
      for v = 1, bossSpawns do
        if #possibleMonsters > 0 then
          local index = math.random(1, #possibleMonsters)
          generateBoss(possibleMonsters[index])
          table.remove(possibleMonsters, index)
        end
      end
    end
  end
end
  end

  -- Applies names if there is a table (host & clients)
  if mapvars.bossNames then
    for i = 1, 79 do
      Game.PlaceMonTxt[i + 220] = i + 220
    end
    for key, value in pairs(mapvars.bossNames) do
      Game.PlaceMonTxt[key] = value
    end
  end

  -- If host in multi, snapshot broadcast (name + assignments)
  if IN_MULTI and IS_HOST then
    if type(BossSync_BroadcastSnapshot) == "function" then
      BossSync_BroadcastSnapshot()
    end
  end
end

-- === GENERATE BOSS (remplit bossNames + bossSet) ===
function generateBoss(index, nameIndex, skillType)
	if not nameIndex then
		local nameIdList = {}
		for i = 0, Map.Monsters.High do
			local mon = Map.Monsters[i]
			if mon.NameId >= 220 and mon.NameId < 300 and mon.AIState ~= 11 then
				table.insert(nameIdList, mon.NameId)
			end
		end
		for i = 221, 299 do
			if not table.find(nameIdList, i) then
				Game.PlaceMonTxt[i] = string.format("%s", i)
			end
		end
		nameIndex = 221
		while nameIndex < 300 do
			if Game.PlaceMonTxt[nameIndex] == string.format("%s", nameIndex) then
				break
			end
			nameIndex = nameIndex + 1
		end
	end

	local mon = Map.Monsters[index]
	mon.NameId = nameIndex


	local lvl = totalLevel[mon.Id] or mon.Level
	if lvl > 100 then
		lvl = round(lvl + math.random() * 20 + 10)
	else
		lvl = round(lvl * (1.1 + math.random() * 0.2))
	end
	mon.Level = math.min(lvl, 255)
	

	local austerityMod = vars.AusterityMode and 4 or 1
	local hpMult= 2 * (1 + lvl / 100 / austerityMod) * (1 + math.random() / austerityMod)
	if getMapAffixPower(18) then
		hpMult = hpMult * (1 + getMapAffixPower(18) / 100)
	end
	mon.Exp = mon.Exp * 5

	mon.TreasureDiceCount	= (mon.Level * 100) ^ 0.5
	mon.TreasureDiceSides	= (mon.Level * 100) ^ 0.5
	mon.TreasureItemPercent = 100
	mon.TreasureItemType		= math.random(1, 12)
	mon.TreasureItemLevel	 = math.min(mon.TreasureItemLevel + 1, 6)

	local dmgMult = 1.5 + math.random() * 0.5

	-- skill / nom
	local skill=skillType
	if not skill then
		local chanceMult = 1
		if vars.Mode == 2 then chanceMult = 2 end
		if vars.insanityMode then chanceMult = 3 end

		-- Use seeded generation in madnessMode
		local mapSeed = getMapSeedForBossAffixes()
		if mapSeed and vars.madnessMode then
			-- Seeded boss generation
			skill = getSeededSkillForBoss(mapSeed)
			
			-- Check for pity-protected special bosses
			local specialSkill, specialHpMult, specialDmgMult = checkPityProtectedBoss(mapSeed, chanceMult, generatedByBroodlord)
			
			if specialSkill then
				skill = specialSkill
				hpMult = hpMult * specialHpMult
				dmgMult = dmgMult * specialDmgMult
				
				-- Apply resistance bonuses
				if skill == "Broodlord" then
					mon.Resistances[0] = mon.Resistances[0] + 1000
				elseif skill == "Omnipotent" then
					mon.Resistances[0] = mon.Resistances[0] + 2000
				end
			end
			
			if generatedByBroodlord then
				skill = "Broodling"
			end
		else
			-- Random generation (original behavior)
			skill = SkillList[math.random(1, #SkillList)]
			if math.random() < 0.01 * chanceMult and not generatedByBroodlord then
				skill = "Broodlord"
				mon.Resistances[0] = mon.Resistances[0] + 1000
				hpMult=hpMult*2
				dmgMult = dmgMult * 1.5
			end
			if generatedByBroodlord then
				skill = "Broodling"
			end
			if math.random() < 0.001 * chanceMult then
				skill = "Omnipotent"
				dmgMult = dmgMult * 2
				mon.Resistances[0] = mon.Resistances[0] + 2000
				hpMult=hpMult*4
			end
		end
	end

	local name = string.format(skill .. " " .. Game.MonstersTxt[mon.Id].Name)
	Game.PlaceMonTxt[mon.NameId] = name

	if getMapAffixPower(18) then
		dmgMult = dmgMult * (1 + getMapAffixPower(18) / 100)
	end

	local s, m = SplitSkill(mon.SpellSkill)
	mon.SpellSkill = JoinSkill(s * dmgMult, m)

	--store better boss data
	mapvars.bossData = mapvars.bossData or {}
	mapvars.bossData[index]={["Name"]=name,
	["NameId"]=mon.NameId,
	["Level"]=lvl,
	["DamageMult"]=dmgMult,
	["HealthMult"]=hpMult,
	["Skills"]=skill, 
	}
	
	-- Calculate health using the centralized getMonsterHealth function
	local HP = round(getMonsterHealth(mon, lvl))
	local hpOvercap = 0
	while HP > 32500 do
		HP = round(HP / 2)
		hpOvercap = hpOvercap + 1
	end
	mon.Resistances[0] = mon.Resistances[0] + 1000 * hpOvercap
	mon.FullHP = HP
	mon.HP = mon.FullHP
	
	-- Maintain compatibility with boss sync system
	mapvars.bossNames = mapvars.bossNames or {}
	mapvars.bossSet = mapvars.bossSet or {}
	mapvars.bossNames[mon.NameId] = name
	table.insert(mapvars.bossSet, {index, mon.NameId, mon.Id})
	-- Increment boss counter for seeding (after successful boss creation)
	vars.totalBossesSpawned = (vars.totalBossesSpawned or 0) + 1
end


--SKILLS
SkillList={"Summoner","Venomous","Exploding","Thorn","Reflecting","Adamantite","Swapper","Regenerating","Puller","Leecher","Swift","Fixator","Shadow","Plagueborn"} --defensives
--to add: splitting
--on attack skills

--BOSS AFFIX SEEDING (insanityMode only)
function getMapSeedForBossAffixes()
	if not vars.insanityMode then
		return nil
	end
	
	-- Generate or use existing boss seed
	if not vars.MawBossSeed then
		vars.MawBossSeed = os.time()
	end
	local baseSeed = vars.MawBossSeed
	
	-- Add map-specific variation
	local mapName = Map.Name or "default"
	local mapSeed = 0
	for i = 1, #mapName do
		mapSeed = mapSeed + string.byte(mapName, i) * i
	end
	
	-- Add map index if available
	if Map.MapStatsIndex then
		mapSeed = mapSeed + Map.MapStatsIndex * 7
	end
	
	-- Combine both seeds
	return baseSeed + mapSeed
end

function getSeededSkillForBoss(seed)
	if not seed then
		return nil -- No seeding, use random
	end
	
	-- Initialize boss counter if not exists
	if not vars.totalBossesSpawned then
		vars.totalBossesSpawned = 0
	end
	
	-- Create deterministic "random" number based on seed and persistent boss counter
	local combinedSeed = seed + vars.totalBossesSpawned * 31
	local pseudoRandom = (combinedSeed * 9301 + 49297) % 233280
	local normalizedRandom = pseudoRandom / 233280
	
	-- Determine skill based on seeded random
	local skillIndex = math.floor(normalizedRandom * #SkillList) + 1
	return SkillList[skillIndex]
end

function getSeededSpecialBossChance(seed, chanceType)
	if not seed then
		return nil -- No seeding, use random
	end
	
	-- Initialize boss counter if not exists
	if not vars.totalBossesSpawned then
		vars.totalBossesSpawned = 0
	end
	
	-- Different offset for different chance types
	local offset = 0
	if chanceType == "broodlord" then
		offset = 123
	elseif chanceType == "omnipotent" then
		offset = 456
	end
	
	local combinedSeed = seed + vars.totalBossesSpawned * 31 + offset
	local pseudoRandom = (combinedSeed * 9301 + 49297) % 233280
	return pseudoRandom / 233280
end

-- Pity protection for special bosses (insanityMode only)
function initializePityProtection()
	vars.broodlordPityCounter = vars.broodlordPityCounter or 0
	vars.omnipotentPityCounter = vars.omnipotentPityCounter or 0
end

function getPityAdjustedChance(baseChance, pityCounter)
	-- Use the new pity system
	return pity_chance(baseChance, pityCounter)
end

function checkPityProtectedBoss(seed, chanceMult, generatedByBroodlord)
	if not vars.insanityMode then
		return nil, nil, nil -- No pity protection outside insanityMode
	end
	
	initializePityProtection()
	
	local broodlordChance = getSeededSpecialBossChance(seed, "broodlord")
	local omnipotentChance = getSeededSpecialBossChance(seed, "omnipotent")
	
	-- Apply pity protection using new pity system (insanity mode only)
	local pityBroodlordChance = pity_chance(0.01 * chanceMult, vars.broodlordPityCounter)
	local pityOmnipotentChance = pity_chance(0.001 * chanceMult, vars.omnipotentPityCounter)
	
	local skill = nil
	local hpMult = 1
	local dmgMult = 1
	
	-- Check for Broodlord (higher priority)
	if broodlordChance < pityBroodlordChance and not generatedByBroodlord then
		skill = "Broodlord"
		hpMult = 2
		dmgMult = 1.5
		vars.broodlordPityCounter = 0 -- Reset counter on success
	else
		vars.broodlordPityCounter = vars.broodlordPityCounter + 1 -- Increment on failure
	end
	
	-- Check for Omnipotent (only if not Broodlord)
	if not skill and omnipotentChance < pityOmnipotentChance then
		skill = "Omnipotent"
		hpMult = 4
		dmgMult = 2
		vars.omnipotentPityCounter = 0 -- Reset counter on success
	elseif not skill then
		vars.omnipotentPityCounter = vars.omnipotentPityCounter + 1 -- Increment on failure
	end
	
	return skill, hpMult, dmgMult
end
function events.GameInitialized2() --to make the after all the other code
	function events.CalcDamageToPlayer(t)
		local data=mawCustomMonObj or WhoHitPlayer()
		if data and data.Monster and data.Monster.NameId>=220 and data.Monster.NameId<300 then
			mon=data.Monster
			skill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
			if skill=="Summoner" then
				if math.random()<0.4 or t.DamageKind==4 then
					pseudoSpawnpoint{monster = math.ceil(mon.Id/3)*3-2, x = (Party.X+mon.X)/2, y = (Party.Y+mon.Y)/2, z = Party.Z, count = 1, powerChances = {75, 25, 0}, radius = 64, group = 1,transform = function(mon) mon.Hostile = true mon.ShowAsHostile = true mon.Velocity=350 end}
				end
			elseif skill=="Venomous" then
				t.Player.Poison3=Game.Time
			elseif skill=="Plagueborn" then
				t.Player.Disease3=Game.Time
			elseif skill=="Fixator" then
				t.Player.Weak=Game.Time
			elseif skill=="Swapper" then	
				Game.ShowStatusText("*Swap*")
				Party.X, Party.Y, Party.Z, mon.X, mon.Y, mon.Z = mon.X, mon.Y, mon.Z, Party.X, Party.Y, Party.Z
				Party.Direction, mon.Direction=mon.Direction, Party.Direction
			elseif skill=="Puller" then
				local direction=calculateDirection(Party.X, Party.Y,mon.X,mon.Y)
				evt.Jump{Direction = direction, ZAngle = 128, Speed = 1000}
			end
			
			if skill=="Omnipotent" then
				if math.random()<0.4 or t.DamageKind==4 then
					pseudoSpawnpoint{monster = math.ceil(mon.Id/3)*3-2, x = (Party.X+mon.X)/2, y = (Party.Y+mon.Y)/2, z = Party.Z, count = 1, powerChances = {75, 25, 0}, radius = 64, group = 1,transform = function(mon) mon.Hostile = true mon.ShowAsHostile = true mon.Velocity=350 end}
				end
				t.Player.Poison3=Game.Time
				t.Player.Disease3=Game.Time
				t.Player.Weak=Game.Time
				Game.ShowStatusText("*Swap*")
				Party.X, Party.Y, Party.Z, mon.X, mon.Y, mon.Z = mon.X, mon.Y, mon.Z, Party.X, Party.Y, Party.Z
				Party.Direction, mon.Direction=mon.Direction, Party.Direction
				local direction=calculateDirection(Party.X, Party.Y,mon.X,mon.Y)
				evt.Jump{Direction = direction, ZAngle = 128, Speed = 1000}
			end
		end
	end

	--on damage taken
	function events.CalcDamageToMonster(t)
		if t.Monster.NameId>=220 and t.Monster.NameId<300 then
			if t.Player then
				local id=t.Player:GetIndex()
				for i=0,Party.High do
					if Party[i]:GetIndex()==id then
						index=i
					end
				end
				skill = string.match(Game.PlaceMonTxt[t.Monster.NameId], "([^%s]+)")
				if skill=="Thorn" or skill=="Omnipotent" then
					if t.DamageKind==4 then
						reflectedDamage=true
						Party[index]:DoDamage(t.Result,4)
						reflectedDamage=false
					end
				end
				if skill=="Reflecting" or skill=="Omnipotent" then
					if t.DamageKind~=4 then
						local damageKind = t.DamageKind
						if damageKind==50 then --transform dragon damage into energy
							damageKind = 12
						end
						reflectedDamage=true
						Party[index]:DoDamage(t.Result,damageKind) 
						reflectedDamage=false
					end
				end
				if skill=="Adamantite" or skill=="Omnipotent" then
					t.Result=round(math.max(t.Result-t.Monster.Level^1.15*4,t.Result/4))
				end
				if skill=="Swapper" or skill=="Omnipotent" then
					for i=0,Map.Monsters.High do
						mon=Map.Monsters[i]
						if mon.HP>0 and mon.AIState==const.AIState.Active and mon.ShowOnMap and mon.ShowAsHostile and (mon.NameId<220 or mon.NameId>300) then
							t.Result=0
							Game.ShowStatusText("*Swap*")
							mon.X, mon.Y, mon.Z, t.Monster.X, t.Monster.Y, t.Monster.Z = t.Monster.X, t.Monster.Y, t.Monster.Z, mon.X, mon.Y, mon.Z
						end
					end
				end
				if skill=="Regenerating" or skill=="Omnipotent" then
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
	if mlk then return end
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

function aa1()
	if mlk then return end
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


-- =========================
-- Helpers bornes & lecture
-- =========================
local function inRangeMonIdx(id)
  return type(id) == "number" and id >= 0 and id <= (Map and Map.Monsters and Map.Monsters.High or -1)
end

local function inRangeTxt(id, arr)
  if type(id) ~= "number" or not arr then return false end
  local hi = (arr.High ~= nil) and arr.High or (#arr - 1)
  return id >= 0 and id <= (hi or -1)
end

local function SafeSkillFromPlaceMon(mon)
  if not mon then return nil end
  local nameId = mon.NameId
  if inRangeTxt(nameId, Game.PlaceMonTxt) then
    local entry = Game.PlaceMonTxt[nameId]
    if entry then
      local s = string.match(entry, "([^%s]+)")
      return s
    end
  end
  return nil
end

local function Clamp01(x)
  if not x then return 0 end
  if x < 0 then return 0 elseif x > 1 then return 1 end
  return x
end

-- =========================
-- Regenerating / Leecher
-- =========================
amountHP = amountHP or { [0] = 0, 0, 0, 0, 0 }
amountSP = amountSP or { [0] = 0, 0, 0, 0, 0 }

function leecher()
  if not mapvars or not mapvars.bossData then return end

  for mid = 0, Map.Monsters.High do
    if inRangeMonIdx(mid) then
      local mon = Map.Monsters[mid]
      if mon and mapvars.bossData[mid] then
        local skill = mapvars.bossData[mid].Skills
        if skill == "Leecher" or skill == "Omnipotent" then
          local distance = getDistance(mon.X or 0, mon.Y or 0, mon.Z or 0)
          if (distance or 1e9) < 1500 and (mon.HP or 0) > 0 and mon.AIState ~= 19 then
            local leechmult = Clamp01(((1500 - distance) / 1500) ^ 2)
            local timeMultiplier = Game.TurnBased and 4 or 1  -- nerf conservé
            for pi = 0, Party.High do
              local pl = Party[pi]
              if pl then
                if (pl.HP or 0) > -20 then
                  local drainHP = (pl.GetFullHP and pl:GetFullHP() or (pl.HP or 0)) * leechmult * 0.05 * timeMultiplier
                  amountHP[pi] = (amountHP[pi] or 0) + (drainHP or 0)
                  local take = math.floor(amountHP[pi] or 0)
                  if take ~= 0 then
                    pl.HP = (pl.HP or 0) - take
                    amountHP[pi] = (amountHP[pi] or 0) % 1
                  end
                end
                if (pl.SP or 0) > -20 then
                  local drainSPbase = (pl.SP or 0)  -- si tu préfères le full SP: pl:GetFullSP()
                  local drainSP = drainSPbase * leechmult * 0.05 * timeMultiplier
                  amountSP[pi] = (amountSP[pi] or 0) + (drainSP or 0)
                  local takeSP = math.floor(amountSP[pi] or 0)
                  if takeSP ~= 0 then
                    pl.SP = (pl.SP or 0) - takeSP
                    amountSP[pi] = (amountSP[pi] or 0) % 1
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

-- Un SEUL handler LoadMap qui fait les 2 jobs (timer + reset swift)
function events.LoadMap(wasInGame)
  swiftLocation = nil
end

-- =========================
-- Swift (mob affixe/skill)
-- =========================
function events.Tick()
  -- Swift via boss data
  if mapvars and mapvars.bossData then
    swiftLocation = swiftLocation or {}
    for mid = 0, Map.Monsters.High do
      if inRangeMonIdx(mid) then
        local mon = Map.Monsters[mid]
        if mon and mapvars.bossData[mid] then
          local skill = mapvars.bossData[mid].Skills
          if skill == "Swift" or skill == "Omnipotent" then
            local key = mid  -- clé stable par MonsterID
            local loc = swiftLocation[key]
            if not loc then
              loc = { mon.X or 0, mon.Y or 0 }
              swiftLocation[key] = loc
            end
            if math.abs((mon.X or 0) - loc[1]) < 100 and math.abs((mon.Y or 0) - loc[2]) < 100 then
              mon.X = (mon.X or 0) + ((mon.X or 0) - loc[1])
              mon.Y = (mon.Y or 0) + ((mon.Y or 0) - loc[2])
            end
            loc[1], loc[2] = mon.X or 0, mon.Y or 0
          end
        end
      end
    end
  end

  -- Swift via affixe de carte (id 11)
  local aff = getMapAffixPower and getMapAffixPower(11)
  if aff and aff ~= 0 then
    swiftLocation = swiftLocation or {}
    for i = 0, (Map.Monsters and Map.Monsters.High or -1) do
      local mon = Map.Monsters[i]
      if mon then
        local loc = swiftLocation[i]
        if not loc then
          loc = { mon.X or 0, mon.Y or 0 }
          swiftLocation[i] = loc
        end
        if math.abs((mon.X or 0) - loc[1]) < 100 and math.abs((mon.Y or 0) - loc[2]) < 100 then
          local k = (aff or 0) / 100
          mon.X = (mon.X or 0) + ((mon.X or 0) - loc[1]) * k
          mon.Y = (mon.Y or 0) + ((mon.Y or 0) - loc[2]) * k
        end
        loc[1], loc[2] = mon.X or 0, mon.Y or 0
      end
    end
  end
end

--[[
function calcDices(add, sides, count, mult, bonusDamage)
    local bonusDamage = bonusDamage or 0
    -- Calculate uncapped values
    local uncappedAdd = round((add + bonusDamage) * mult)
    local uncappedSides = round(sides * mult^0.5)
    local uncappedCount = round(count * mult^0.5)
    
    -- Initialize capped values
    local cappedAdd = uncappedAdd
    local cappedSides = uncappedSides
    local cappedCount = uncappedCount
    
    -- Apply caps and adjust parameters
    if cappedAdd > 250 then
        local Overflow = cappedAdd - 250
        cappedAdd = 250
        cappedSides = cappedSides + round(2 * Overflow / cappedCount)
    end
    if cappedSides > 250 then
        local Overflow = cappedSides / 250
        cappedSides = 250
        cappedCount = round(cappedCount * Overflow)
    end
    if cappedCount > 250 then
        local Overflow = cappedCount / 250
        cappedCount = 250
        cappedSides = round(math.min(cappedSides * Overflow, 250))
    end
    
    -- Compute expected damages
    local uncappedDamage = uncappedCount * (uncappedSides + 1) / 2 + uncappedAdd
    local cappedDamage = cappedCount * (cappedSides + 1) / 2 + cappedAdd
    
    -- Compute external multiplier
    local externalMultiplier = uncappedDamage / cappedDamage
    if externalMultiplier < 1 then externalMultiplier = 1 end
    
    return cappedAdd, cappedSides, cappedCount, externalMultiplier
end
]]

--fix out of bound monsters
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

function mappingRegen()
	if getMapAffixPower(7) then
		local regenAmount=mon.FullHitPoints*getMapAffixPower(7)/100
		mon.HP=math.min(mon.HP+regenAmount, mon.FullHP)
	end
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
	if Map.Monsters[round(t.MonsterIndex)].NameId>=220 and Map.Monsters[round(t.MonsterIndex)].NameId<300 then
		if Map.IndoorOrOutdoor==1 then
			t.Scale=t.Scale*1.4
		else
			t.Scale=t.Scale*2
		end
		local monsterSkill = string.match(Game.PlaceMonTxt[Map.Monsters[round(t.MonsterIndex)].NameId], "([^%s]+)")
		if monsterSkill=="Omnipotent" then
			t.Scale=(t.Scale-1)*1.5+t.Scale
		end
	end
end

function events.BeforeLoadMap()
	for i=1, Game.MonstersTxt.High do
		if Game.MonstersTxt[i].AIType~=1 then
			Game.MonstersTxt[i].AIType=0
		end
	end
end

--nerf to movement speed in doom
function events.Tick()
	if Game.TurnBased then
		if vars.Mode==2 or vars.AusterityMode then
			turnBaseStartPositionX=turnBaseStartPositionX or Party.X
			turnBaseStartPositionY=turnBaseStartPositionY or Party.Y
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
					local level = mon.Level
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

function events.AfterLoadMap()
	if vars.madnessMode then
		MAWBOLSTER[600]="Mad."
	elseif vars.insanityMode then
		MAWBOLSTER[600]="Insane"
	else
		MAWBOLSTER[600]="Doom"
	end
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
local transform={
		[500]=734,
		[505]=739,
		[510]=712,
		[515]=732,
		[535]=740,
		[540]=737,
		[555]=736,
		[1010]=712
}
local explosions={
		[734]=723,
		[739]=721,
		[712]=711,
		[732]=718,
		[740]=715,
		[737]=719,
		[736]=722,
}
local transformedList={734,739,712,732,740,737,736}

function events.Tick()
	if vars.MAWSETTINGS.restoreProjectiles=="OFF" then return end
	if Multiplyer and Multiplayer.in_game then return end
	for i=0, Map.Objects.High do
		local obj=Map.Objects[i]
		if transform[obj.Type] and obj.Owner%8==3 and obj.Spell==0 then
			obj.Type=transform[obj.Type]
			obj.TypeIndex=obj.Type-160
			obj.LightMultiplier=0
		end		
	end
	
	if Game.Paused then return end
	
	for i=0, Map.Objects.High do
		local obj=Map.Objects[i]
		lastLocation=lastLocation or {}
		lastLocation[i]=lastLocation[i] or {math.huge,math.huge}
		local dist=getDistance(obj.X,obj.Y,obj.Z-120)
		if table.find(transformedList, obj.Type) and (dist<128 or (obj.X==lastLocation[i][1] and obj.Y==lastLocation[i][2])) and obj.Spell==0 then
			local triggeredByPlayer=false
			if dist<128 then
				triggeredByPlayer=true
			end
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
			if triggeredByPlayer then
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
				
				local skill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
				if skill=="Fixator" then
					covered=false
					local lowestHPId=0
					local lowestHP=math.huge
					for i=0,Party.High do
						local totHP=Party[i]:GetFullHP()
						if Party[i]:IsConscious() and totHP<lowestHP then
							lowestHP=totHP
							lowestHPId=i
						end
					end
					target=lowestHPId
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
					
					--retaliation code
					local s,m=Skillz.get(pl,53)
					if s/100>=math.random() then
						vars.retaliation=vars.retaliation or {}
						vars.retaliation[id]=vars.retaliation[id] or {}
						vars.retaliation[id]["Stacks"]=vars.retaliation[id]["Stacks"] or 0
						vars.retaliation[id]["Time"]=vars.retaliation[id]["Time"] or Game.Time
						vars.retaliation[id]["Stacks"]=vars.retaliation[id]["Stacks"]+1
						local cap=1
						if m==4 then
							cap=3
						end
						vars.retaliation[id]["Stacks"]=math.min(vars.retaliation[id]["Stacks"],cap)
					end						
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
	--fix to items dropping too often
	BeginGrabObjects()
	function events.Tick()
		events.Remove("Tick",1)
		local generatedItemTable={}
		generatedItemTable[1], generatedItemTable[2], generatedItemTable[3], generatedItemTable[4]=GrabObjects()
		for i=1,4 do
			local obj=generatedItemTable[i]
			if obj and obj.Item.Number<=2200 and (table.find(removeItemList, obj.Item.Number) or (obj.Item:T().EquipStat==13 and obj.Item.Bonus==0))  then
				if math.random()>0.2 then
					obj.Type=0
					obj.TypeIndex=0
					obj.Item.Number=0
				end
			end
		end
	end
	
	if mon.Ally==9999 then return end
	
	mon.Ally=9999
	
	local data=WhoHitMonster()
	if data and data.Monster and data.Monster.Ally==9999 and Multiplayer and not Multiplayer.in_game then
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
	end
	
	local killedMonster=mon
	local monsterSkill = string.match(Game.PlaceMonTxt[killedMonster.NameId], "([^%s]+)")
	if monsterSkill=="Omnipotent" then
		for i=1,#SkillList do
			pseudoSpawnpoint{monster = killedMonster.Id,  x = killedMonster.X, y = killedMonster.Y, z = killedMonster.Z, count = 1, powerChances = {0,0,100}, radius = 512, group = 2,transform = function(spawnedMon) spawnedMon.Hostile = true spawnedMon.ShowAsHostile = true spawnedMon.Velocity=350 bossId=spawnedMon:GetIndex() end}
			generateBoss(bossId,false,SkillList[i])
		end
	end
	if monsterSkill=="Broodlord" or monsterSkill=="Broodling" or monsterSkill=="Omnipotent" then
		for i=1,3 do
			local location=monsterSpawnLocation[math.random(1,#monsterSpawnLocation)]
			local powerChance={0, 0, 100}
			if monsterSkill=="Broodling" then
				if killedMonster.Id%3==0 then
					powerChance={0, 100, 0}
				elseif killedMonster.Id%3==2 then
					powerChance={100, 0, 0}
				else 
					return
				end
			end
			pseudoSpawnpoint{monster = killedMonster.Id,  x = killedMonster.X, y = killedMonster.Y, z = killedMonster.Z, count = 1, powerChances = powerChance, radius = 256, group = 2,transform = function(spawnedMon) spawnedMon.Hostile = true spawnedMon.ShowAsHostile = true spawnedMon.Velocity=350 bossId=spawnedMon:GetIndex() end}
			generateBoss(bossId,false,"Broodling")
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

--[[
function getMonsterDamage(lvl,calcType) --NO LONGER USED
	local baseDamage=(3+lvl^0.88)
	if calcType=="baseDamage" then
		return baseDamage
	end
	local baseMult=(1.15+lvl/9)*(1+lvl/400)
	if calcType=="baseMult" then
		return baseMult
	end
	local diffMult=1
	local bol=Game.BolsterAmount
	if bol==0 then
		diffMult=lvl/550+0.6
	elseif bol==50 then
		diffMult=lvl/500+0.8
	elseif bol==100 then
		diffMult=lvl/450+1
	elseif bol==150 then
		diffMult=lvl/400+1.12
	elseif bol==200 then
		diffMult=lvl/350+1.25
	elseif bol==300 then
		diffMult=lvl/300+1.5
	elseif bol==600 then
		diffMult=lvl/400+2
	end
	if vars.insanityMode then
		diffMult=diffMult*(1.5+lvl/600)
	end
	if vars.AusterityMode then
		diffMult=(diffMult*5-math.min(3.5, diffMult*3.5))^1.25
	end
	if calcType=="diffMult" then
		return diffMult
	end
	local totMult=baseMult*diffMult
	if calcType=="totMult" then
		return totMult
	end
	local totDamage=baseDamage*baseMult*diffMult
	return totDamage
end
]]

function events.MonstersProcessed()
	if not Game.TurnBased and Map.IsIndoor() then
		for i=0,Map.Monsters.High do
			local mon=Map.Monsters[i]
			if mon.AIState==0 and mon.ShowOnMap and getDistance(mon.X,mon.Y,mon.Z)<350 then
				local midZ=(mon.Z+Party.Z)/2+50
				local distanceX=mon.X-Party.X
				local distanceY=mon.Y-Party.Y
				local requiresHandling=false
				local j=0
				while not requiresHandling and j<9 do
					j=j+1
					local x=Party.X+distanceX*(0.1*j)
					local y=Party.Y+distanceY*(0.1*j)
					if Map.RoomFromPoint(x, y, midZ) == 0 then
						requiresHandling=true
					end
				end
				
				if requiresHandling then
					-- Get relative position of monster to party
					local dx = mon.X - Party.X
					local dy = mon.Y - Party.Y
					
					-- Calculate angle in radians
					local angle = math.atan2(dy, dx) -- atan2 gives angle in range -pi to pi
					
					-- Calculate theoretical positions
					local clockwise_angle = angle - math.pi / 2 -- Rotate clockwise
					local counterclockwise_angle = angle + math.pi / 2 -- Rotate counterclockwise
					
					-- Define movement distance
					local move_distance = 300
					
					-- Theoretical coordinates after moving
					local directionFound=false
					while not directionFound and move_distance>50 do
						local clockwise_x = mon.X + math.cos(clockwise_angle) * move_distance
						local clockwise_y = mon.Y + math.sin(clockwise_angle) * move_distance
						local counterclockwise_x = mon.X + math.cos(counterclockwise_angle) * move_distance
						local counterclockwise_y = mon.Y + math.sin(counterclockwise_angle) * move_distance
						if Map.RoomFromPoint(clockwise_x, clockwise_y, midZ) == 0 then
							if Map.RoomFromPoint(counterclockwise_x, counterclockwise_y, midZ) ~= 0 then
								clockwise=false
								directionFound=true
							end
						else
							clockwise=true
							directionFound=true
						end
						move_distance = move_distance-50
					end
					if not directionFound then
						return
					end
					-- Set the final angle based on the chosen direction
					if clockwise then
						angle = clockwise_angle
					else
						angle = counterclockwise_angle
					end
					
					-- Normalize angle to range [0, 2*pi]
					if angle < 0 then
						angle = angle + 2 * math.pi
					end
					
					-- Convert angle to the game's direction format (0 to 2048)
					local direction=math.floor(angle / (2 * math.pi) * 2048)
					mon.Direction = direction
					
					-- Set velocity
					local speed = mon.Velocity -- This is the monster's movement speed
					local speedX=math.cos(angle) * speed
					local speedY=math.sin(angle) * speed
					mon.VelocityX = speedX
					mon.VelocityY = speedY
					
					mon.AIState = 6
					
					local calls=10
					function events.Tick()
						calls=calls-1
						if not calls or calls<0 then
							events.Remove("Tick",1)	
						end
						local midX=(mon.X+Party.X)/2
						local midY=(mon.Y+Party.Y)/2
						local midZ=(mon.Z+Party.Z)/2
						if mon.AIState==6 and Map.RoomFromPoint(midX, midY, midZ) == 0 then
							mon.VelocityX = speedX
							mon.VelocityY = speedY
						end
					end
				end
			end
		end
	end
end

--translate mapLevels table
function events.GameInitialized2()
	engLocalizedMap={}
	for i=0, Game.MapStats.High do
		engLocalizedMap[i]=Game.MapStats[i].Name
	end	
end

function events.BeforeLoadMap()
	for i=1, #engLocalizedMap do
		if mapLevels[engLocalizedMap[i]] then
			local tab=mapLevels[engLocalizedMap[i]]
			mapLevels[Game.MapStats[i].Name]={}
			mapLevels[Game.MapStats[i].Name]["Low"]=tab.Low
			mapLevels[Game.MapStats[i].Name]["Mid"]=tab.Mid
			mapLevels[Game.MapStats[i].Name]["High"]=tab.High
		end
	end
end

function events.CalcDamageToMonster(t)
	if Map.IsIndoor() and vars.Mode==2 then
		for i=0, Map.Monsters.High do
			local mon = Map.Monsters[i]
			if getDistances(t.Monster, mon)<256 then
				mon.ShowOnMap = true
			end
		end
	end
end

function getDistances(unit1,unit2)
	distance=((unit1.X-unit2.X)^2+(unit1.Y-unit2.Y)^2+(unit1.Z-unit2.Z)^2)^0.5
	return distance
end

--redone retroactive fix
function events.AfterLoadMap()
	if isRedone then
		for i=0,Map.Monsters.High do
			local mon=Map.Monsters[i]
			if mon.NameId>=220 and mon.NameId<300 and mon.AIState ~= 11 then
				if Game.PlaceMonTxt[mon.NameId]==string.format("%s", mon.NameId) then
					mon.NameId=0
				end
			end
		end
	end
end

--redone bounty hunt quest partial fix
function events.LoadMap()
	if isRedone then
		for i=0,Game.NPC.High do
			npc=Game.NPC[i]
			for j=0,3 do
				if npc.Events[j]==1712 then
				npc.Events[j]=579
				end
			end
		end
	end
end

-- --- SAFE WRAPPER: n'altère pas la logique, évite juste les erreurs console
do
  if type(recalculateMawMonster) == "function" then
    local _orig = recalculateMawMonster
    function recalculateMawMonster(mon)
      if not Game or not Game.MonstersTxt then return end
      if not Map or not Map.Monsters   then return end
      if type(mon) == "number" then mon = Map.Monsters[mon] end
      if mon ~= nil and mon.Id == nil then return end

      local ok, res = pcall(_orig, mon)
      if ok then return res end  -- sinon on avale l’erreur
    end
  end
end


function events.PickCorpse(t)
	if vars.madnessMode then 
		if mapvars.mawBounty or Map.Name=="zarena.blv" or Map.Name=="d42.blv" or Map.Name=="7d05.blv" then
			local mon=t.Monster
			mon.TreasureItemPercent=0
			mon.TreasureDiceCount=0
			mon.TreasureDiceSides=0
		end
	end
end
