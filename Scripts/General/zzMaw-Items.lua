function events.GenerateItem(t)
	--get party average level
	Handled = true
	--[[calculate party experience
	if Map.MapStatsIndex==0 then return end
	currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
	if currentWorld==4 then
		return
	end
	if currentWorld==1 then
		partyLevelItemGen=vars.MM8LVL
	elseif currentWorld==2 then
		partyLevelItemGen=vars.MM7LVL
	elseif currentWorld==3 then
		partyLevelItemGen=vars.MM6LVL
	end

	--nerf items in shops is strong if low level
	if Game.freeProgression then
		if (Game.HouseScreen==2 or Game.HouseScreen==95) then
			if partyLevelItemGen<(t.Strength-3)*18 and t.Strength<7 then
				t.Strength=t.Strength-1
			end
			if (t.Strength-2)*18>partyLevelItemGen and t.Strength>2 and t.Strength<7 then
				roll=math.random((t.Strength-3)*18,(t.Strength-2)*18)
				if roll>partyLevelItemGen then
					t.Strength=t.Strength-1
				end
			end
		end
	end
	]]
end

function events.PickCorpse(t)
	--if Game.BolsterAmount~=300 then return end
	Game.RandSeed=mapvars.MonsterSeed[t.MonsterIndex]
	function events.Tick() 
		events.Remove("Tick", 1)
		mapvars.MonsterSeed[t.MonsterIndex]=Game.RandSeed
	end
end
function events.CastTelepathy(t)
	--if Game.BolsterAmount~=300 then return end
	Game.RandSeed=mapvars.MonsterSeed[t.MonsterIndex]
	function events.Tick() 
		events.Remove("Tick", 1)
		mapvars.MonsterSeed[t.MonsterIndex]=Game.RandSeed
	end
end
function events.LoadMap()
	--if Game.BolsterAmount~=300 then return end
	if not mapvars.MonsterSeed then
		mapvars.MonsterSeed={}
		for i = 0, Map.Monsters.Limit - 1 do
			mapvars.MonsterSeed[i] = Game.RandSeed
			for i = 1, 30 do
				Game.Rand()
			end
		end
	end
end
--[[
local function NeedSeed()
	local t = mapvars.MonsterSeed
	if not t then
		t = {}
		mapvars.MonsterSeed = t
		for i = 0, Map.Monsters.Limit - 1 do
			t[i] = Game.RandSeed
			for i = 1, 30 do
				Game.Rand()
			end
		end
	end
	return t
end

events.LoadMap = NeedSeed

local function f(t)
	local seed = NeedSeed()
	Game.RandSeed = seed[t.MonsterIndex]
	t.CallDefault()
	seed[t.MonsterIndex] = Game.RandSeed
end

events.PickCorpse = f
events.CastTelepathy = f
]]
--create tables to calculate special enchant
function events.GameInitialized2()
	Game.ItemsTxt[67].NotIdentifiedName="Mace"
	Game.ItemsTxt[804].NotIdentifiedName="Longsword"
	--calculate totals by enchant type
	totBonus2={}
	for k=0,3 do
		totBonus2[k]={}
		for v=0, 11 do
			totBonus2[k][v]=0
			for i=0, Game.SpcItemsTxt.High do
				lvl=Game.SpcItemsTxt[i].Lvl
				if lvl==k then
					totBonus2[k][v]=totBonus2[k][v]+Game.SpcItemsTxt[i].ChanceForSlot[v]
				end
			end
		end
	end
	
	--calculate total of each item level per item type
	itemStrength={}	
	itemStrength[3]={}
	itemStrength[4]={}
	itemStrength[5]={}
	itemStrength[6]={}
	for v=0, 11 do	
		itemStrength[3][v]=totBonus2[0][v]+totBonus2[1][v]
		itemStrength[4][v]=totBonus2[0][v]+totBonus2[1][v]+totBonus2[2][v]
		itemStrength[5][v]=totBonus2[1][v]+totBonus2[2][v]+totBonus2[3][v]
		itemStrength[6][v]=totBonus2[3][v]
	end
	--list of possible enchants per item level
	enchants={}
	enchants[3]={0,1}
	enchants[4]={0,1,2}
	enchants[5]={1,2,3}
	enchants[6]={3}
end

--create enchant table
encStrDown={1,1,3,6,9,12,15,18,21,24,28,32,36,40,44,48,52,56,60,64,70,76,80,84,88,92,96,100,104,108,112,116,120,124,128,132,136,140,144,148,152,156}
encStrUp={3,5,8,12,16,20,24,29,34,38,42,48,52,56,60,65,70,75,80,85,90,100,105,110,115,120,125,130,135,140,145,150,155,160,165,170,175,180,185,190,195,200}


enc1Chance={20,30,40,50,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84}
enc2Chance={20,30,35,40,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64}
spcEncChance={5,10,15,20,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44}

primordialWeapEnchants={39,40,41,46}
primordialArmorEnchants={1,2,80}


function events.ItemGenerated(t)
	--boss items forced
	if bossLoot then
		if not (t.Item.Number<=151 or (t.Item.Number>=803 and t.Item.Number<=936) or (t.Item.Number>=1603 and t.Item.Number<=1736)) then
			t.Item:Randomize(t.Strength, 0)
			return
		end
	end
	if vars then
		if vars.SeedList==nil then
			vars.SeedList={}
			for i=0,2500 do
				vars.SeedList[i]=math.random(1,100000)
			end
		end
		math.randomseed(vars.SeedList[t.Item.Number])
		vars.SeedList[t.Item.Number]=vars.SeedList[t.Item.Number]+math.random(1,1000)
	end

	if Map.MapStatsIndex==0 then
		return 
	end
	if t.Strength==7 then
		return
	end
	--spawn crafting materials in misc shops, substituting recipes
	if (Game.HouseScreen==2 or Game.HouseScreen==95) then
		id=Game:GetCurrentHouse()
		if (t.Item:T().EquipStat>=12 and math.random()<0.05 or t.Item:T().EquipStat==19) and id<=110 then 
			t.Item.Bonus=0
			t.Item.BonusStrength=0
			t.Item.Bonus2=0
			t.Item.Charges=0
			t.Item.MaxCharges=0
			roll=math.random(1,1000)/math.min(((Party.Gold+1)/1000000),10)
			if roll<=2 then
				t.Item.Number=1064
				return
			elseif roll<=7 then
				t.Item.Number=1061
				return
			elseif roll<=12 then
				t.Item.Number=1062
				return
			elseif roll<=15 then
				t.Item.Number=1065
				return
			elseif roll<=35 then
				t.Item.Number=1063
				return
			else
				partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
				reagentLevel=math.floor(partyLevel/25)
				if math.random()<0.05 then
					reagentLevel=reagentLevel+2
				elseif math.random()<0.25 then
					reagentLevel=reagentLevel+1
				end
				t.Item.Number=1051+math.min(reagentLevel,9)
				return
			end
		end
	end
	if t.Item.Number<=151 or (t.Item.Number>=803 and t.Item.Number<=936) or (t.Item.Number>=1603 and t.Item.Number<=1736) or reagentList[t.Item.Number] then
		t.Handled=true
		--reset enchants
		t.Item.BonusExpireTime=0
		t.Item.Bonus=0
		t.Item.Bonus2=0
		t.Item.BonusStrength=0
		--calculate party level
		currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
		if currentWorld==1 then
			partyLevel=vars.MM7LVL+vars.MM6LVL
			currentLevel=vars.MM8LVL
		elseif currentWorld==2 then
			partyLevel=vars.MM8LVL+vars.MM6LVL
			currentLevel=vars.MM7LVL
		elseif currentWorld==3 then
			partyLevel=vars.MM8LVL+vars.MM7LVL
			currentLevel=vars.MM6LVL
		elseif currentWorld==4 then
			partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
			currentLevel=vars.MMMLVL
		end
		
		vars.mapResetCount=vars.mapResetCount or {}
		vars.mapResetCount[Map.Name]=vars.mapResetCount[Map.Name] or 0
		local bonus=vars.mapResetCount[Map.Name]*20
		if mapvars.mapAffixes then
			bonus=mapvars.mapAffixes.Power*10+20
		end
		currentLevel=currentLevel+bonus
		partyLevel=partyLevel+bonus
		if Map.Name=="d42.blv" then
			currentLevel=monTbl[math.min((vars.highestArenaWave+1)*3,#monTbl)].Level*6
			partyLevel=monTbl[math.min((vars.highestArenaWave+1)*3,#monTbl)].Level*6/1.5
		end
		--modify reagents
		if reagentList[t.Item.Number] then
			t.Item.Bonus=math.round(partyLevel/3)
			return
		end
		
		local name=Game.MapStats[Map.MapStatsIndex].Name
		mapLevel=mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High
		if Map.Name~="d42.blv" then
			if not Game.freeProgression then
				partyLevel=(vars.MM8LVL+vars.MM7LVL+vars.MM6LVL)*0.75
				if mapLevels[name] and mapLevels[name].Low~=0 and Game.HouseScreen~=2 and Game.HouseScreen~=95 then
					partyLevel=mapLevel
					mapLevel=0
				end
			elseif mapLevels[name] and mapLevels[name].Low~=0 then
				partyLevel=mapLevel*0.2+partyLevel
			else
				partyLevel=partyLevel+math.min(currentLevel/2,54)
				mapLevel=0
			end
		end
		--difficulty settings
		difficultyExtraPower=1
		if Game.BolsterAmount>100 then
			difficultyExtraPower=(Game.BolsterAmount-100)/2000+1
		end
		local flatBonus=(difficultyExtraPower-1)*50
		if math.random()<flatBonus%1 then
			flatBonus=flatBonus+1
		end
		--nerf shops if no exp in current world
		--[[
		if (Game.HouseScreen==2 or Game.HouseScreen==95) and Game.freeProgression then 
			partyLevel=math.round(partyLevel*(math.min(partyLevel/160 + currentLevel/80,1)))
		end
		]]
		--ADD MAX CHARGES BASED ON PARTY LEVEL
		bonusCharges=(difficultyExtraPower-1)*20
		cap1=50*((difficultyExtraPower-1)*2+1)
		maxChargesCap=50*((difficultyExtraPower-1)*4+1)
		if mapvars.mapAffixes then
			cap1=cap1+100
			maxChargesCap=maxChargesCap+100
		end
		t.Item.MaxCharges=math.floor(partyLevel/5+mapLevel/40)
		--bolster boost
		t.Item.MaxCharges=math.min(math.floor(t.Item.MaxCharges*difficultyExtraPower+bonusCharges),cap1)
		
		bonusCap=math.floor((difficultyExtraPower-1)*10)
		if mapvars.mapAffixes then
			bonusCap=bonusCap+math.min(math.max((mapvars.mapAffixes.Power-30+2)/2,0),20)  --cap at map level 700
		end
		cap2=14+bonusCap
		partyLevel1=math.min(math.floor((partyLevel+bonus)/18),cap2) 
		--adjust loot Strength
		ps1=t.Strength

		pseudoStr=ps1+partyLevel1
		if bossLoot then
			pseudoStr=pseudoStr+1
		end
		if math.random(1,18)<partyLevel1%18 then
			pseudoStr=pseudoStr+1
		end
		if pseudoStr==1 then 
			return 
		end
		pseudoStr=math.min(pseudoStr,20+bonusCap) --CAP CURRENTLY AT 20, 22 in doom,42 for mapping
		roll1=math.random()
		roll2=math.random()
		rollSpc=math.random()
		power=0
		if bossLoot then
			roll1=roll1/2
			roll2=roll1/2
			rollSpc=roll1/2
		end
		--difficulty multiplier 
		diffMult=math.max((Game.BolsterAmount-100)/500+1,1)
		if vars.Mode==2 then
			diffMult=1.8
		end
		--calculate chances
		local p1=enc1Chance[math.min(pseudoStr,#enc1Chance)]/100
		local p2=enc2Chance[math.min(pseudoStr,#enc2Chance)]/100
		local p3=spcEncChance[math.min(pseudoStr,#spcEncChance)]/100
		
		p1=p1^(1/diffMult)
		p2=p2^(1/diffMult)
		p3=p3^(1/diffMult)
		
		if p1>roll1 then
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.random(encStrDown[pseudoStr],encStrUp[pseudoStr])
			--bolster
			t.Item.BonusStrength=math.ceil(t.Item.BonusStrength*difficultyExtraPower)
			if math.random(1,10)==10 then
				t.Item.Bonus=math.random(17,24)
				local skill=t.Item:T().Skill
				if (skill==10 or skill==11) and t.Item.Bonus==23 then
					t.Item.Bonus=22
				elseif (skill<=7 and skill>0) and t.Item.Bonus==24 then
					t.Item.Bonus=22
				end
			end
		end
		--apply enchant2
		if p2>roll2 then
			t.Item.Charges=math.random(encStrDown[pseudoStr],encStrUp[pseudoStr])
			--bolster
			t.Item.Charges=math.ceil(t.Item.Charges*difficultyExtraPower)
			--bonus type
			t.Item.Charges=t.Item.Charges+math.random(1,16)*1000
			--[[ no skill bonuses
			if math.random(1,10)==10 then
				t.Item.Charges=math.random(17,24)*1000
				t.Item.Charges=t.Item.Charges+math.round(math.random(encStrDown[pseudoStr],encStrUp[pseudoStr])^0.5)
			end
			]]
		end
		--make it standard bonus if no standard bonus
		if t.Item.Bonus==0 then
			t.Item.Bonus=math.floor(t.Item.Charges/1000)
			t.Item.BonusStrength=t.Item.Charges%1000
			t.Item.Charges=0
		end
				
		--ancient item
		ancient=false
		ancientChance=(p1*p2*p3)/4^(1/diffMult^0.5)
		if mapvars.mapAffixes then
			local nAff=0
			for i=1,4 do
				if mapvars.mapAffixes[i]>0 then
					nAff=nAff+1
				end
			end
			ancientChance=ancientChance*(1+mapvars.mapAffixes.Power*nAff/400)
		end
		
		if bossLoot then
			ancientChance=ancientChance*5
			bossLoot=false
		end
	
		ancientRoll=math.random()
		if ancientRoll<=ancientChance then
			ancient=true
			t.Item.Charges=math.random(math.round(encStrUp[pseudoStr]+1),math.ceil(encStrUp[pseudoStr]*1.2))
			t.Item.Charges=math.ceil(t.Item.Charges*difficultyExtraPower) --bolster
			t.Item.Charges=t.Item.Charges+math.random(1,16)*1000
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.random(math.round(encStrUp[pseudoStr]+1),math.ceil(encStrUp[pseudoStr]*1.2))
			t.Item.BonusStrength=math.ceil(t.Item.BonusStrength*difficultyExtraPower) --bolster
			power=2
			chargesBonus=math.random(1,5)
			t.Item.MaxCharges=t.Item.MaxCharges+chargesBonus
			t.Item.BonusExpireTime=1
		end
		--apply special enchant
		if p3>rollSpc or ancient then
			n=t.Item.Number
			c=Game.ItemsTxt[n].EquipStat
			if c<12 then
				power=ps1+power
				power=math.max(math.min(power,6),3)
				totB2=itemStrength[power][c]
				roll=math.random(1,totB2)
				tot=0
				for i=0,Game.SpcItemsTxt.High do
					if roll<=tot then
						t.Item.Bonus2=i
						goto continue
					elseif table.find(enchants[power], Game.SpcItemsTxt[i].Lvl) then
						tot=tot+Game.SpcItemsTxt[i].ChanceForSlot[c]
					end
				end	
			end			
		end
		
		::continue::
		
		
		--primordial item
		primordial=math.random()
		primordialChance=ancientChance/4^(1/diffMult^0.5)
		if primordial<=primordialChance then
			if ancient then
				t.Item.MaxCharges=t.Item.MaxCharges-chargesBonus
			end
			t.Item.BonusExpireTime=2
			t.Item.Charges=math.ceil(encStrUp[pseudoStr]*1.2)
			t.Item.Charges=math.ceil(t.Item.Charges*difficultyExtraPower) --bolster
			t.Item.Charges=math.round(t.Item.Charges+math.random(1,16)*1000)
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.ceil(encStrUp[pseudoStr]*1.2)
			t.Item.BonusStrength=math.ceil(t.Item.BonusStrength*difficultyExtraPower) --bolster
			t.Item.MaxCharges=math.max(t.Item.MaxCharges*0.25+5, t.Item.MaxCharges*1.25)
			--apply special enchant
			n=t.Item.Number
			c=Game.ItemsTxt[n].EquipStat
			if c<=2 then
				roll=math.random(1,#primordialWeapEnchants)
				t.Item.Bonus2=primordialWeapEnchants[roll]
			else
				roll=math.random(1,#primordialArmorEnchants)
				t.Item.Bonus2=primordialArmorEnchants[roll]
			end
		end			
		
		--legendary
		if t.Item.BonusExpireTime==2 then
			local chance=0.1
			if vars.Mode==2 then
				chance=chance*2
			end
			--No legendary in shop
			if Game.HouseScreen==2 or Game.HouseScreen==95 then
				chance=0
			end
			if chance>=math.random() then
				--roll legendary effect
				local roll=math.random(11,#legendaryEffects)
				t.Item.BonusExpireTime=roll
				--adjust bonus 2 if enchant damage legendary
				if t.Item.BonusExpireTime==19 then
					if t.Item.Bonus2==40 then
						t.Item.Bonus2=39
					elseif t.Item.Bonus2==41 then
						t.Item.Bonus2=46
					end
				end
				local relevantStats={1,2,3,4,5,6,7,8,10}
				t.Item.MaxCharges=math.round(t.Item.MaxCharges*1.2)
				local roll=math.random(1,3)
				if roll==1 then
					local stats={1, 5, 6, 7}
					t.Item.Bonus=stats[math.random(1,4)]
					t.Item.Charges=t.Item.Charges%1000+stats[math.random(1,4)]*1000
				elseif roll==2 then
					local stats={4, 6, 8, 10}
					t.Item.Bonus=stats[math.random(1,4)]
					t.Item.Charges=t.Item.Charges%1000+stats[math.random(1,4)]*1000
				elseif roll==3 then
					local stats={2, 3, 4, 6, 7}
					t.Item.Bonus=stats[math.random(1,5)]
					t.Item.Charges=t.Item.Charges%1000+stats[math.random(1,5)]*1000
					if (t.Item.Bonus==2 and math.floor(t.Item.Charges/1000)==3) or (t.Item.Bonus==2 and math.floor(t.Item.Charges/1000)==3) then
						t.Item.Bonus=math.floor(t.Item.Charges/1000)
					end
				end
				--increase stats
				t.Item.Charges=math.ceil(math.min(t.Item.Charges%1000*0.2,999)+t.Item.Charges)
				t.Item.BonusStrength=math.ceil(t.Item.BonusStrength*1.2)
			end
		end
		
		--buff to hp and mana items
		if t.Item.Bonus==8 or t.Item.Bonus==9 then
			t.Item.BonusStrength=t.Item.BonusStrength*(2+t.Item.BonusStrength/50)
		end
		if math.floor(t.Item.Charges/1000)==8 or math.floor(t.Item.Charges/1000)==9 then
			local power=t.Item.Charges%1000
			power=power*(2+power/50) --cap is 999
			if power >= 999 and t.Item.Bonus<17 then --swap base with charges
				local bonus=t.Item.Bonus
				local str=t.Item.BonusStrength
				t.Item.Bonus=math.floor(t.Item.Charges/1000)
				t.Item.BonusStrength=power
				t.Item.Charges= bonus*1000+str
			else 
				t.Item.Charges=math.floor(t.Item.Charges/1000)*1000+power
			end
		end
		--nerf to AC and skills
		if t.Item.Bonus==10 then
			t.Item.BonusStrength=math.ceil(t.Item.BonusStrength*0.667)
		end
		if math.floor(t.Item.Charges/1000)==10 then
			t.Item.Charges=t.Item.Charges-math.floor(t.Item.Charges%1000*0.333)
		end
		if t.Item.Bonus>=17 and t.Item.Bonus<=24 then
			t.Item.BonusStrength=math.ceil(math.max(t.Item.BonusStrength^0.5,t.Item.BonusStrength/10))
		end
		-- buff to 2h weapons enchants
		local mult=slotMult[t.Item:T().EquipStat]
		if mult then
			t.Item.BonusStrength=math.ceil(t.Item.BonusStrength*mult)
			local bonus=math.ceil(t.Item.Charges%1000*(mult-1))
			bonus=t.Item.Charges%1000
			bonus=math.min(bonus*mult,999) --cap is 999
			t.Item.Charges=math.floor(t.Item.Charges/1000)*1000+bonus
		end
		--check if int/pers or might/accuracy item to change special enchant
		local melee=0
		local caster=0
		if t.Item.Bonus2==39 or t.Item.Bonus2==40 or t.Item.Bonus2==41 or t.Item.Bonus2==46 then
			if t.Item.Bonus==1 or t.Item.Bonus==5 then
				melee=melee+1
			elseif t.Item.Bonus==2 or t.Item.Bonus==3 then
				caster=caster+1
			end
			local bonus=math.floor(t.Item.Charges/1000)
			if bonus==1 or bonus==5 then
				melee=melee+1
			elseif bonus==2 or bonus==3 then
				caster=caster+1
			end
			if melee>caster then
				if t.Item.Bonus2==39 then
					t.Item.Bonus2=46
				elseif t.Item.Bonus2==40 then
					t.Item.Bonus2=41
				end
			elseif caster>melee then
				if t.Item.Bonus2==46 then
					t.Item.Bonus2=39
				elseif t.Item.Bonus2==41 then
					t.Item.Bonus2=40
				end
			end
		end
		if math.abs(t.Item.Charges%1000-t.Item.BonusStrength)<=1 then
			t.Item.Charges=math.floor(t.Item.Charges/1000)*1000+t.Item.BonusStrength
		end
		--round above 100
		if t.Item.BonusStrength>100 then
			t.Item.BonusStrength=math.round(t.Item.BonusStrength/5)*5
		end
		if t.Item.Charges%1000>100 then
			t.Item.Charges=math.min(math.round(t.Item.Charges%1000/5)*5,999)+math.floor(t.Item.Charges/1000)*1000
		end
		
		--maxcharges Cap
		t.Item.MaxCharges=math.min(maxChargesCap, t.Item.MaxCharges)
		
		--reduce chances for resistances
		if t.Item.Bonus>=11 and t.Item.Bonus<=16 then
			if math.random()<0.4 then
				t.Item.Bonus=math.random(1,7)
			end
		end
		if math.floor(t.Item.Charges/1000)>=11 and math.floor(t.Item.Charges/1000)<=16 then
			if math.random()<0.4 then
				t.Item.Charges=t.Item.Charges-math.floor(t.Item.Charges/1000)*1000+math.random(1,7)*1000
			end
		end
		
		--fix to resistances not to rolled be twice
		local bonus2=math.floor(t.Item.Charges/1000)
		while t.Item.Bonus>0 and t.Item.Bonus==bonus2 do
			t.Item.Bonus=math.random(11,16)
		end
		
		
		--[[statistics
		ancientDrops=ancientDrops or 0
		primordialDrops=primordialDrops or 0
		legendaryDrops=legendaryDrops or 0
		if t.Item.BonusExpireTime==1 then
			ancientDrops=ancientDrops+1
		elseif t.Item.BonusExpireTime==2 then
			primordialDrops=primordialDrops+1
		elseif t.Item.BonusExpireTime>=10 and t.Item.BonusExpireTime<=30 then
			legendaryDrops=legendaryDrops+1
		end
		]]
	end
end

--items stats multiplier:
slotMult={2,1.25,1.5,1,1.25,1,1,1.25,1.25,0.75,1,[0]=1	}


----------------------
--weapon rework
----------------------
function events.GameInitialized2()
--Weapon upscaler 
	for i=1,2200 do
		if (i>=1 and i<=83) or (i>=803 and i<=865) or (i>=1603 and i<=1665) then
			
			upTierDifference=0
			downTierDifference=0
			downDamage=0
			--set goal damage for weapons (end game weapon damage)
			goalDamage=35
			if Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Axe" or Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Sword" or Game.ItemsTxt[i].Skill==0 then
				goalDamage=goalDamage*2
			end
			currentDamage = (Game.ItemsTxt[i].Mod1DiceCount *Game.ItemsTxt[i]. Mod1DiceSides + 1)/2+Game.ItemsTxt[i].Mod2 

				for v=1,4 do
					if Game.ItemsTxt[i].NotIdentifiedName==Game.ItemsTxt[i+v].NotIdentifiedName then
					upTierDifference=upTierDifference+1
					end
					if Game.ItemsTxt[i].NotIdentifiedName==Game.ItemsTxt[math.max(i-v,0)].NotIdentifiedName then
					downTierDifference=downTierDifference+1
					downDamage = (Game.ItemsTxt[i-v].Mod1DiceCount *Game.ItemsTxt[i-v]. Mod1DiceSides + 1)/2+Game.ItemsTxt[i-v].Mod2
					elseif downTierDifference==0 then
							downDamage = currentDamage
					end
				end

			--calculate expected value
			tierRange=upTierDifference+downTierDifference+1
			damageRange=goalDamage-downDamage
			expectedDamageIncrease=damageRange*(downTierDifference/(tierRange-1))
			Game.ItemsTxt[i].Mod1DiceSides = Game.ItemsTxt[i].Mod1DiceSides + (expectedDamageIncrease / Game.ItemsTxt[i].Mod1DiceCount)
			Game.ItemsTxt[i].Mod2=expectedDamageIncrease/2

		elseif Game.ItemsTxt[i].Skill==8 then
	--increase shield value
			Game.ItemsTxt[i].Mod2=Game.ItemsTxt[i].Mod2*2+Game.ItemsTxt[i].Mod1DiceCount  
		end
	end	
end




--change tooltip
function events.GameInitialized2()
	--menu stats
	if ColouredStats==true then
		Game.GlobalTxt[144]=StrColor(255,0,0,"Might")
		Game.GlobalTxt[116]=StrColor(255,128,0,"Intellect")
		Game.GlobalTxt[163]=StrColor(0,127,255,"Personality")
		Game.GlobalTxt[75]=StrColor(0,255,0,"Endurance")
		Game.GlobalTxt[1]=StrColor(255,255,0,"Accuracy")
		Game.GlobalTxt[211]=StrColor(127,0,255,"Speed")
		Game.GlobalTxt[136]=StrColor(255,255,255,"Luck")
		Game.GlobalTxt[108]=StrColor(0,255,0,"Hit Points")
		Game.GlobalTxt[212]=StrColor(0,100,255,"Mana")
		Game.GlobalTxt[12]=StrColor(230,204,128,"Armor Class")
	end
end

-----------------------------
---IMMUNITY REWORK
-----------------------------
function events.DoBadThingToPlayer(t)
    local protectionMessages = {
        [18] = { [9] = "disease", [10] = "disease", [11] = "disease", [1] = "curse" },
        [19] = { [5] = "insanity", [22] = "spell drain" },
        [20] = { [12] = "paralysis", [23] = "fear" },
        [21] = { [6] = "poison", [7] = "poison", [8] = "poison", [2] = "weakness" },
        [22] = { [3] = "sleep", [13] = "unconscious" },
        [23] = { [15] = "stone", [21] = "premature ageing" },
        [25] = { [14] = "death", [16] = "eradication" },
    }

    for it in t.Player:EnumActiveItems() do
        if protectionMessages[it.Bonus2] and protectionMessages[it.Bonus2][t.Thing] then
            t.Allow = false
            local protectionType = protectionMessages[it.Bonus2][t.Thing]
            Game.ShowStatusText(string.format("Enchantment protects %s from %s", t.Player.Name, protectionType))
        end
    end
end
function events.GameInitialized2()
--new tooltips
	Game.SpcItemsTxt[2].BonusStat="Explosive Impact! (half damage)"
	Game.SpcItemsTxt[17].BonusStat="Disease and Curse Immunity"
	Game.SpcItemsTxt[18].BonusStat="Insanity and SP drain Immunity"
	Game.SpcItemsTxt[19].BonusStat="Paralysis and fear Immunity"
	Game.SpcItemsTxt[20].BonusStat="Poison and weakness Immunity"
	Game.SpcItemsTxt[21].BonusStat="Sleep and Unconscious Immunity"
	Game.SpcItemsTxt[22].BonusStat="Stone and premature ageing Immunity"
	Game.SpcItemsTxt[24].BonusStat="Death and Eradication Immunity"
end
--------------------
--STATUS REWORK (needs to stay after status immunity)
--------------------

function events.LoadMap(wasInGame)
	local function poisonTimer() 
		vars.poisonTime=vars.poisonTime or {}
		for i = 0, Party.High do
			if Party[i].Poison3>0 then
				if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
					vars.poisonTime[i]=20
				end
				if vars.poisonTime[i]>0 then
					vars.poisonTime[i]=vars.poisonTime[i]-1
				end
				if vars.poisonTime[i]==0 then			
					Party[i].Poison3=0
					Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
				else
					Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.06)*(Game.BolsterAmount/100)
				end 
			else if Party[i].Poison2>0 then
					if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
						vars.poisonTime[i]=20
					end
					if vars.poisonTime[i]>0 then
						vars.poisonTime[i]=vars.poisonTime[i]-1
					end
					if vars.poisonTime[i]==0 then			
						Party[i].Poison2=0
						Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
					else
						Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.04)*(Game.BolsterAmount/100)
					end 
				else if Party[i].Poison1>0 then
						if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
							vars.poisonTime[i]=20
						end
						if vars.poisonTime[i]>0 then
							vars.poisonTime[i]=vars.poisonTime[i]-1
						end
						if vars.poisonTime[i]==0 then			
							Party[i].Poison1=0
							Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
						else
							Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.02)*(Game.BolsterAmount/100)
						end 
					else 
						vars.poisonTime[i]=0
					end
				end
			end
		end
	end
	Timer(poisonTimer, const.Minute/2) 

	function events.DoBadThingToPlayer(t)
		if (t.Thing==6 or t.Thing==7 or t.Thing==8) and t.Allow then
			if vars.poisonTime[t.PlayerIndex]==nil or vars.poisonTime[t.PlayerIndex]==0 then
				vars.poisonTime[t.PlayerIndex]=25
			else
				vars.poisonTime[t.PlayerIndex]=math.min(vars.poisonTime[t.PlayerIndex]+5,50)
			end
		end
	end

--hp and sp regen
	local function restoreHPEnchant() 
		for _, pl in Party do 
		HPregen=0
		totHP=pl:GetFullHP()
			for it in pl:EnumActiveItems() do
				if it.Bonus2 == 37 or it.Bonus2==44 or it.Bonus2==50 or it.Bonus2==54 or it.Bonus2==66 then		
					HPregen=math.max(HPregen+totHP*0.02,HPregen+1)	
				end
			end
		HPregen=math.max(HPregen-1,0)
		pl.HP=math.min(pl.HP+math.round(HPregen),totHP)
		end 
	end
	Timer(restoreHPEnchant, const.Minute*5) 


	local function restoreSPEnchant() 
		for _, pl in Party do 
		SPregen=0
		totSP=pl:GetFullSP()
			for it in pl:EnumActiveItems() do
				if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 or it.Bonus2==66 then		
					SPregen=math.max(SPregen+totSP*0.02,SPregen+1)
				end
			end
		SPregen=math.max(SPregen-1,0)
		pl.SP=math.min(pl.SP+math.round(SPregen),totSP)
		end 
	end
	Timer(restoreSPEnchant, const.Minute*5) 
end



--carnage fix tooltip
function events.GameInitialized2()
	Game.SpcItemsTxt[2].BonusStat="Explosive Impact! (half damage)"
end

------------------------------------------
--TOOLTIPS--
------------------------------------------
legendaryEffects={
	[11]="Killing a monster with a single-target attack will recover your action time",
	[12]="When a base enchantment increases one of the stats-might, intellect, or personality-the two lesser stats will each receive a bonus equivalent to 75% of the value of the highest stat.",
	[13]="Immunity to all status effects from monsters",
	[14]="Crit chance increased by 10% and crit chance over 100% increases total damage",
	[15]="Divine protection (instead of dying you go back to 25% HP, once every 5 minutes)",
	[16]="Increases your resistances by 50%, up to you highest resistance",
	[17]="Your hits will deal 2% of current monster HP health (1% for AoE, multi-hit spells and arrows)",
	[18]="Reduce all damage taken by 10%",
	[19]="Your weapon enchants now scales with the highest between might/int./pers.",
	[20]="Base enchants on this items can be upgraded up to twice the cap value with crafting Gems",
	[21]="Increase melee damage by 5% for each enemy in the nearbies",
	[22]="Reduces damage by 3% for each enemy in the nearbies",
	[23]="Successfully covering an ally restores 3% of your HP",
	[24]="Killing a Monster Restores 10% of Health and Mana",
	[25]="Increases spells ascension level by 1",
}

function events.BuildItemInformationBox(t)
	if t.Item.Number<=151 or (t.Item.Number>=803 and t.Item.Number<=936) or (t.Item.Number>=1603 and t.Item.Number<=1736) then 
		if t.Type then
			t.Type = t.Type
			--add code to increase base stats based on bolster enchant
			--ARMORS
			if t.Item.MaxCharges>0 then
				local txt=Game.ItemsTxt[t.Item.Number]
				local equipStat=txt.EquipStat
				if equipStat>=3 and equipStat<=9 then
				local ac3=txt.Mod2+txt.Mod1DiceCount 
					if ac3>0 then
						local lookup=0
						while Game.ItemsTxt[t.Item.Number].NotIdentifiedName==Game.ItemsTxt[t.Item.Number+lookup+1].NotIdentifiedName do 
							lookup=lookup+1
						end
						local ac=Game.ItemsTxt[t.Item.Number].Mod2+Game.ItemsTxt[t.Item.Number].Mod1DiceCount 
						local ac2=Game.ItemsTxt[t.Item.Number+lookup].Mod2+Game.ItemsTxt[t.Item.Number+lookup].Mod1DiceCount 
						local bonusAC=ac2*(t.Item.MaxCharges/40)
						--if t.Item.MaxCharges <= 20 then
							ac=ac3+math.round(bonusAC)
						--else
						--	local bonusAC=(ac+ac2)*(t.Item.MaxCharges/20)
						--	ac=ac3+math.round(bonusAC)
						--end		
						t.BasicStat= "Armor: +" .. ac
					end
				end
			end
			--WEAPONS
			if t.Item.MaxCharges>0 then
				local txt=Game.ItemsTxt[t.Item.Number]
				local equipStat=txt.EquipStat
				if equipStat<=2 then
					
					local lookup=0
					while Game.ItemsTxt[t.Item.Number].NotIdentifiedName==Game.ItemsTxt[t.Item.Number+lookup+1].NotIdentifiedName do 
						lookup=lookup+1
					end
					local bonus=txt.Mod2
					local bonus2=Game.ItemsTxt[t.Item.Number+lookup].Mod2
					local bonusATK=bonus2*(t.Item.MaxCharges/30)
					bonus=bonus+math.round(bonusATK)
					local sides=txt.Mod1DiceSides
					local sides2=Game.ItemsTxt[t.Item.Number+lookup].Mod1DiceSides
					local sidesBonus=sides2*(t.Item.MaxCharges/30)
					sides=sides+math.round(sidesBonus)
					t.BasicStat= "Attack: +" .. bonus .. "  " .. "Damage: " ..  txt.Mod1DiceCount .. "d" .. sides .. "+" .. bonus
				end
			end
			
			
			--add code to build enchant list
			t.Enchantment=""
			if t.Item.Bonus>0 then
				local power=t.Item.BonusStrength
				if t.Item.Bonus>=11 and t.Item.Bonus<=16 then
					power=math.round(power^0.6/50*1000)/10 .. "%"
				end
				t.Enchantment = itemStatName[t.Item.Bonus] .. " +" .. power
			end
			if t.Item.Charges>1000 then
				local bonus=math.floor(t.Item.Charges/1000)
				local strength=t.Item.Charges%1000
				if bonus>=11 and bonus<=16 then
					strength=math.round(strength^0.6/50*1000)/10 .. "%"
				end
				t.Enchantment = itemStatName[bonus] .. " +" .. strength .. "\n" .. t.Enchantment
			elseif t.Item.Bonus~=0 and t.Item.BonusStrength~=0 then
				if extraDescription then
					math.randomseed(t.Item.Number*10000+t.Item.MaxCharges*1000+t.Item.Bonus*100+t.Item.BonusStrength*10+t.Item.Charges)
					
					local mult=math.max((Game.BolsterAmount-100)/1000+1,1)
					local cap=100*mult
					local power=t.Item.BonusStrength
					if t.Item.Bonus==8 or t.Bonus==9 then
						power=math.floor((-100+(100^2+power*200)^0.5)/2)
					elseif t.Item.Bonus==10 then
						power=power*1.5
					end
					local stat=math.random(1,16)
					if stat==8 or stat==9 then
						power=power*(2+power/50)
					elseif stat==10 then
						power=power*0.667
					end
					local slotMult=slotMult[t.Item:T().EquipStat] or 1
					cap=math.min(cap*slotMult,999)
					
					charges=stat*1000+math.min(math.round(power*(1+0.25*math.random())),cap)
					
					local bonus=math.floor(charges/1000)
					local strength=charges%1000
					txt=baseStatName[bonus] .. " +" .. strength .. "\n" .. t.Enchantment
					t.Enchantment = StrColor(100,100,100, txt)
					vars.extraShown=true
				end
			end
			if t.Item.Bonus==0 and t.Item.Bonus2==0 and t.Item.Charges<1000 and extraDescription then
				if vars.enchantSeedList==nil then
				vars.enchantSeedList={}
					for i=0,2500 do
						vars.enchantSeedList[i]=math.random(1,100000)
					end
				end
				math.randomseed(vars.enchantSeedList[t.Item.Number]+t.Item.MaxCharges)
				if math.random(1,10)==1 then
					bonus=math.random(17,24)
				else
					bonus=math.random(1,16)
				end
				txt=baseStatName[bonus] .. " +X"
				t.Enchantment = StrColor(100,100,100, txt)
			end
		elseif t.Name then
			--add enchant Name
			t.Name = Game.ItemsTxt[t.Item.Number].Name
			if t.Item.Bonus2>0 then
				enchString=Game.SpcItemsTxt[t.Item.Bonus2-1].NameAdd
				if string.match(enchString, "^%u") then
					t.Name= enchString .. " " .. t.Name
				else
					t.Name= t.Name .. " " .. enchString
				end
			elseif t.Item.Bonus>0 then
				t.Name= t.Name .. " " .. Game.StdItemsTxt[t.Item.Bonus-1].NameAdd
			end
			--choose colour
			local bonus=0
			if t.Item.Bonus>0 then
				bonus=bonus+1
			end
			if t.Item.Bonus2>0 then
				bonus=bonus+1
			end
			if t.Item.Charges>1000 then
				bonus=bonus+1
			end
			if t.Item.BonusExpireTime==1 then
				t.Name=StrColor(255,128,0,"Ancient " .. t.Name)
			elseif t.Item.BonusExpireTime==2 then
				t.Name=StrColor(255,0,0,"Primordial " .. t.Name)
			elseif legendaryEffects[t.Item.BonusExpireTime] then
				t.Name=StrColor(255,255,30,"Legendary " .. t.Name)
			elseif bonus==3 then
				t.Name=StrColor(163,53,238,t.Name)
			elseif bonus==2 then
				t.Name=StrColor(0,150,255,t.Name)
			elseif bonus==1 then
				t.Name=StrColor(30,255,0,t.Name)
			else
				t.Name=StrColor(255,255,255,t.Name)
			end
		elseif t.Description then
			if legendaryEffects[t.Item.BonusExpireTime]then
				local legText=legendaryEffects[t.Item.BonusExpireTime]
				if t.Item.BonusExpireTime==21 then
					local count=0
					for i=0, Map.Monsters.High do
						if Map.Monsters[i].Active then
							dist=getDistanceToMonster(Map.Monsters[i])
							if dist<=512 then
								count=count+1
							end
						end
					end
					local dmg=count*5
					legText=legText .. "\nCurrent bonus Damage: " .. dmg .. "%"
				elseif t.Item.BonusExpireTime==22 then
					local count=0
					for i=0, Map.Monsters.High do
						if Map.Monsters[i].Active then
							dist=getDistanceToMonster(Map.Monsters[i])
							if dist<=512 then
								count=count+1
							end
						end
					end
					local red=math.round((1-0.97^count)*10000)/100
					legText=legText .. "\nCurrent Reduction: " .. red .. "%"
				end
				t.Description = StrColor(255,255,30,legText) .. "\n\n" .. t.Description
			end
			if t.Item.Bonus2>0 then	
				if (t.Item.MaxCharges>=0 and bonusEffects[t.Item.Bonus2]~= nil) or enchantList[t.Item.Bonus2] then
					text=checktext(t.Item.MaxCharges,t.Item.Bonus2,t.Item)
				else
					text=Game.SpcItemsTxt[t.Item.Bonus2-1].BonusStat
				end
				t.Description = StrColor(255,255,153,text) .. "\n\n" .. t.Description
			end
			if t.Item.Bonus>0 and t.Item.Bonus2==0 and extraDescription then
				n=t.Item.Number
				c=Game.ItemsTxt[n].EquipStat
				math.randomseed(t.Item.Number*10000+t.Item.MaxCharges*1000+t.Item.Bonus*100+t.Item.BonusStrength*10+t.Item.Charges)
				if c<12 then
					power=6
					totB2=itemStrength[power][c]
					roll=math.random(1,totB2)
					tot=0
					for i=0,Game.SpcItemsTxt.High do
						if roll<=tot then
							enchantNumber=i
							goto continue
						elseif table.find(enchants[power], Game.SpcItemsTxt[i].Lvl) then
							tot=tot+Game.SpcItemsTxt[i].ChanceForSlot[c]
						end
					end	
				end
				:: continue ::
				if (t.Item.MaxCharges>=0 and bonusEffects[enchantNumber]~= nil) or enchantList[enchantNumber] then
					text=checktext(t.Item.MaxCharges,enchantNumber,t.Item)
				else
					text=Game.SpcItemsTxt[enchantNumber-1].BonusStat
				end
				t.Description = StrColor(100,100,100,text) .. "\n\n" .. t.Description
				vars.extraShown=true
			end
			if t.Item.Bonus>0 and t.Item.BonusStrength>0 then
				if not extraDescription and not vars.extraShown then
					t.Description = t.Description .. "\n\n" .. StrColor(100,100,100,"Press alt to show craftable stats")
				end
			end
		end
	end
end

extraDescription=false
function events.KeyDown(t)
	if t.Alt then
		extraDescription=true
	end	
end
function events.KeyUp(t)
	if t.Alt then
		extraDescription=false
	end	
end

--colours
function events.GameInitialized2()
	itemStatName = {}
	itemStatName[1] = StrColor(255, 0, 0, "Might")
	itemStatName[2] = StrColor(255, 128, 0, "Intellect")
	itemStatName[3] = StrColor(0, 127, 255, "Personality")
	itemStatName[4] = StrColor(0, 255, 0, "Endurance")
	itemStatName[5] = StrColor(255, 255, 0, "Accuracy")
	itemStatName[6] = StrColor(127, 0, 255, "Speed")
	itemStatName[7] = StrColor(255, 255, 255, "Luck")
	itemStatName[8] = StrColor(0, 255, 0, "Hit Points")
	itemStatName[9] = StrColor(0, 100, 255, "Spell Points")
	itemStatName[10] = StrColor(230, 204, 128, "Armor Class")
	itemStatName[11] = StrColor(255, 70, 70, "Fire Resistance")
	itemStatName[12] = StrColor(173, 216, 230, "Air Resistance")
	itemStatName[13] = StrColor(100, 180, 255, "Water Resistance")
	itemStatName[14] = StrColor(153, 76, 0, "Earth Resistance")
	itemStatName[15] = StrColor(200, 200, 255, "Mind Resistance")
	itemStatName[16] = StrColor(255, 192, 203, "Body Resistance")
	itemStatName[17] = StrColor(255,255,153, "Alchemy skill")
	itemStatName[18] = StrColor(255,255,153, "Stealing skill")
	itemStatName[19] = StrColor(255,255,153, "Disarm skill")
	itemStatName[20] = StrColor(255,255,153, "ID Item skill")
	itemStatName[21] = StrColor(255,255,153, "ID Monster skill")
	itemStatName[22] = StrColor(255,255,153, "Armsmaster skill")
	itemStatName[23] = StrColor(255,255,153, "Dodge skill")
	itemStatName[24] = StrColor(255,255,153, "Unarmed skill")
	itemStatName[25] = StrColor(255,255,153, "Great might")
	
	baseStatName={
		[1]="Might",
		[2]="Intellect",
		[3]="Personality",
		[4]="Endurance",
		[5]="Accuracy",
		[6]="Speed",
		[7]="Luck",
		[8]="Hit Points",
		[9]="Spell Points",
		[10]="Armor Class",
		[11]="Fire Resistance",
		[12]="Air Resistance",
		[13]="Water Resistance",
		[14]="Earth Resistance",
		[15]="Mind Resistance",
		[16]="Body Resistance",
		[17]="Alchemy skill",
		[18]="Stealing skill",
		[19]="Disarm skill",
		[20]="ID Item skill",
		[21]="ID Monster skill",
		[22]="Armsmaster skill",
		[23]="Dodge skill",
		[24]="Unarmed skill",
	}
		
end

--fix to enchant2 not applying correctly if same bonus is on the item
--fix to special enchants
--VANILLA ENCHANTS, used to check if there is any difference to compute
bonusEffectsBase = {
    [1] = { bonusType = 1, bonusRange = {11, 16}, statModifier = 10 },
    [2] = { bonusType = 2, bonusRange = {1, 7}, statModifier = 10 },
    [39] = { bonusType = 39, bonusValues = {2, 3}, statModifier = 0 },
    [42] = { bonusType = 42, bonusRange = {1, 16}, statModifier = 1 },
    [43] = { bonusType = 43, bonusValues = {4, 8, 10}, statModifier = 10 },
    [44] = { bonusType = 44, bonusValues = {8}, statModifier = 10 },
    [45] = { bonusType = 45, bonusValues = {5, 6}, statModifier = 5 },
    [46] = { bonusType = 46, bonusValues = {1}, statModifier = 25 },
    [47] = { bonusType = 47, bonusValues = {9}, statModifier = 10 },
    [48] = { bonusType = 48, bonusValues = {4, 10}, statModifier = {15, 5} },
    [49] = { bonusType = 49, bonusValues = {2, 7}, statModifier = 10 },
    [50] = { bonusType = 50, bonusValues = {11}, statModifier = 30 },
    [51] = { bonusType = 51, bonusValues = {2, 6, 9}, statModifier = 10 },
    [52] = { bonusType = 52, bonusValues = {4, 5}, statModifier = 10 },
    [53] = { bonusType = 53, bonusValues = {1, 3}, statModifier = 10 },
    [54] = { bonusType = 54, bonusValues = {4}, statModifier = 15 },
    [55] = { bonusType = 55, bonusValues = {7}, statModifier = 15 },
    [56] = { bonusType = 56, bonusValues = {1, 4}, statModifier = 5 },
    [57] = { bonusType = 57, bonusValues = {2, 3}, statModifier = 5 },
    [74] = { bonusType = 53, bonusValues = {3, 5}, statModifier = 0 },
    [75] = { bonusType = 53, bonusValues = {1, 2}, statModifier = 0 },
    [76] = { bonusType = 53, bonusValues = {2, 5}, statModifier = 0 },
    [77] = { bonusType = 53, bonusValues = {1, 2, 3}, statModifier = 0 },
    [78] = { bonusType = 53, bonusRange = {11, 14}, statModifier = 0 },
    [79] = { bonusType = 53, bonusValues = {15, 16}, statModifier = 0 },
    [80] = { bonusType = 53, bonusRange = {1, 16}, statModifier = 0 },
}

--MODIFY THIS TO CHANGE ACTUAL VALUES
bonusEffects = {
    [1] = { bonusType = 1, bonusRange = {11, 16}, statModifier = 10 },
    [2] = { bonusType = 2, bonusRange = {1, 7}, statModifier = 10 },
    [39] = { bonusType = 39, bonusValues = {2, 3}, statModifier = 25 },
    [42] = { bonusType = 42, bonusRange = {1, 16}, statModifier = 3 },
    [43] = { bonusType = 43, bonusValues = {4, 8, 10}, statModifier = 10 },
    [44] = { bonusType = 44, bonusValues = {8}, statModifier = 10 },
    [45] = { bonusType = 45, bonusValues = {5, 6}, statModifier	 = 10 },
    [46] = { bonusType = 46, bonusValues = {1}, statModifier = 25 },
    [47] = { bonusType = 47, bonusValues = {9}, statModifier = 10 },
    [48] = { bonusType = 48, bonusValues = {4, 10}, statModifier = {15, 5} },
    [49] = { bonusType = 49, bonusValues = {2, 7}, statModifier = 10 },
    [50] = { bonusType = 50, bonusValues = {11}, statModifier = 30 },
    [51] = { bonusType = 51, bonusValues = {2, 6, 9}, statModifier = 10 },
    [52] = { bonusType = 52, bonusValues = {4, 5}, statModifier = 10 },
    [53] = { bonusType = 53, bonusValues = {1, 3}, statModifier = 20 },
    [54] = { bonusType = 54, bonusValues = {4}, statModifier = 15 },
    [55] = { bonusType = 55, bonusValues = {7}, statModifier = 15 },
    [56] = { bonusType = 56, bonusValues = {1, 4}, statModifier = 10 },
    [57] = { bonusType = 57, bonusValues = {2, 3}, statModifier = 15 },
    [74] = { bonusType = 53, bonusValues = {3, 5}, statModifier = 20 },
    [75] = { bonusType = 53, bonusValues = {1, 2}, statModifier = 20 },
    [76] = { bonusType = 53, bonusValues = {2, 5}, statModifier = 20 },
    [77] = { bonusType = 53, bonusValues = {1, 2, 3}, statModifier = 15 },
    [78] = { bonusType = 53, bonusRange = {11, 14}, statModifier = 20 },
    [79] = { bonusType = 53, bonusValues = {15, 16}, statModifier = 20 },
    [80] = { bonusType = 53, bonusRange = {1, 16}, statModifier = 5 },
}

--create dictionary with description list
function checktext(MaxCharges,bonus2,it)
	--if MaxCharges <= 20 then
		mult=1+MaxCharges/20
	--else
	--	mult=2+2*(MaxCharges-20)/20
	--end
	local attackSpeedMult=getBaseAttackSpeed(it)
	local id=Game.CurrentPlayer
	if id<0 or id>Party.High then
		id=0
	end
	local legDmgMult=1
	local pl=Party[id]
	local index=pl:GetIndex()
	if vars.legendaries and vars.legendaries[index] and table.find(vars.legendaries[index], 19) then
		local str=pl:GetMight()
		local int=pl:GetIntellect()
		local pers=pl:GetPersonality()
		local bonusStat=math.max(str,int,pers)
		legDmgMult=(1+bonusStat/1000)
	end
	bonus2txt={
		[1] =  " +" .. math.floor(bonusEffects[1].statModifier * mult) .. " to all Resistances.",
		[2] = " +" .. math.floor(bonusEffects[2].statModifier * mult) .. " to all Seven Statistics.",
		[4] ="Adds " .. math.floor(6*mult*attackSpeedMult*legDmgMult) .. "-" .. math.floor(8*mult*attackSpeedMult*legDmgMult) .. " points of Cold damage. (Increases also all spell damage if equipped in main hand)",
		[5] ="Adds " .. math.floor(18*mult*attackSpeedMult*legDmgMult) .. "-" .. math.floor(24*mult*attackSpeedMult*legDmgMult) .. " points of Cold damage. (Increases also all spell damage if equipped in main hand)",
		[6] ="Adds " .. math.floor(36*mult*attackSpeedMult*legDmgMult) .. "-" .. math.floor(48*mult*attackSpeedMult*legDmgMult) .. " points of Cold damage. (Increases also all spell damage if equipped in main hand)",
		[7] ="Adds " .. math.floor(4*mult*attackSpeedMult*legDmgMult) .. "-" .. math.floor(10*mult*attackSpeedMult*legDmgMult) .. " points of Electrical damage. (Increases also all spell damage if equipped in main hand)",
		[8] ="Adds " .. math.floor(12*mult*attackSpeedMult*legDmgMult) .. "-" .. math.floor(30*mult*attackSpeedMult*legDmgMult) .. " points of Electrical damage. (Increases also all spell damage if equipped in main hand)",
		[9] ="Adds " .. math.floor(24*mult*attackSpeedMult*legDmgMult) .. "-" .. math.floor(60*mult*attackSpeedMult*legDmgMult) .. " points of Electrical damage. (Increases also all spell damage if equipped in main hand)",
		[10] ="Adds " .. math.floor(2*mult*attackSpeedMult*legDmgMult) .. "-" .. math.floor(12*mult*attackSpeedMult*legDmgMult) .. " points of Fire damage. (Increases also all spell damage if equipped in main hand)",
		[11] ="Adds " .. math.floor(6*mult*attackSpeedMult*legDmgMult) .. "-" .. math.floor(36*mult*attackSpeedMult*legDmgMult) .. " points of Fire damage. (Increases also all spell damage if equipped in main hand)",
		[12] ="Adds " .. math.floor(12*mult*attackSpeedMult*legDmgMult) .. "-" .. math.floor(72*mult*attackSpeedMult*legDmgMult) .. " points of Fire damage. (Increases also all spell damage if equipped in main hand)",
		[13] ="Adds " .. math.floor(12*mult*attackSpeedMult*legDmgMult) .. " points of Body damage. (Increases also all spell damage if equipped in main hand)",
		[14] ="Adds " .. math.floor(24*mult*attackSpeedMult*legDmgMult) .. " points of Body damage. (Increases also all spell damage if equipped in main hand)",
		[15] ="Adds " .. math.floor(48*mult*attackSpeedMult*legDmgMult) .. " points of Body damage. (Increases also all spell damage if equipped in main hand)",
		--spell enchants
		[26] = "Air Magic Skill +" .. math.floor(MaxCharges/4)+5,
		[27] = "Body Magic Skill +" .. math.floor(MaxCharges/4)+5,
		[28] = "Dark Magic Skill +" .. math.floor(MaxCharges/4)+5,
		[29] = "Earth Magic Skill +" .. math.floor(MaxCharges/4)+5,
		[30] = "Fire Magic Skill +" .. math.floor(MaxCharges/4)+5,
		[31] = "Light Magic Skill +" .. math.floor(MaxCharges/4)+5,
		[32] = "Mind Magic Skill +" .. math.floor(MaxCharges/4)+5,
		[33] = "Spirit Magic Skill +" .. math.floor(MaxCharges/4)+5,
		[34] = "Water Magic Skill +" .. math.floor(MaxCharges/4)+5,
		--stats enchants
		[39] = "Adds " .. math.floor(40*mult*attackSpeedMult*legDmgMult) .. "-" .. math.floor(80*mult*attackSpeedMult*legDmgMult) .. " to spell damage(except when equipping off-hand) and +" .. math.floor(bonusEffects[46].statModifier * mult).. " Intellect and personality.",
		[40] = "Spells Drain Hit points from target and Increased Spell speed.(except when equipping off-hand).",
		[42] = " +" .. math.floor(bonusEffects[42].statModifier * mult) .. " to Seven Stats, HP, SP, Armor, Resistances.",
		[43] = " +" .. math.floor(bonusEffects[43].statModifier * mult) .. " to Endurance, Armor, Hit points.",
		[44] = " +" .. math.floor(bonusEffects[44].statModifier * mult) .. " Hit points and Regenerate Hit points over time.",
		[45] = " +" .. math.floor(bonusEffects[45].statModifier * mult) .. " Speed and Accuracy.",
		[46] = "Adds " .. math.floor(40*mult*attackSpeedMult*legDmgMult) .. "-" .. math.floor(80*mult*attackSpeedMult*legDmgMult) .. " points of Fire damage and +" .. math.floor(bonusEffects[46].statModifier * mult).. " Might.",
		[47] = " +" .. math.floor(bonusEffects[47].statModifier * mult) .. " Spell points and Regenerate Spell points over time.",
		[48] = " +" .. math.floor(bonusEffects[48].statModifier[1] * mult) .. " Endurance and" .. " +" .. math.floor(bonusEffects[48].statModifier[2] * mult).. " Armor.",
		[49] = " +" .. math.floor(bonusEffects[49].statModifier * mult) .. " Intellect and Luck.",
		[50] = " +" .. math.floor(bonusEffects[50].statModifier * mult) .. " Fire Resistance and Regenerate Hit points over time.",
		[51] = " +" .. math.floor(bonusEffects[51].statModifier * mult) .. " Spell points, Speed, Intellect.",
		[52] = " +" .. math.floor(bonusEffects[52].statModifier * mult) .. " Endurance and Accuracy.",
		[53] = " +" .. math.floor(bonusEffects[53].statModifier * mult) .. " Might and Personality.",
		[54] = " +" .. math.floor(bonusEffects[54].statModifier * mult) .. " Endurance and Regenerate Hit points over time.",
		[55] = " +" .. math.floor(bonusEffects[55].statModifier * mult) .. " Luck and Regenerate Spell points over time.",
		[56] = " +" .. math.floor(bonusEffects[56].statModifier * mult) .. " Might and Endurance.",
		[57] = " +" .. math.floor(bonusEffects[57].statModifier * mult) .. " Intellect and Personality.",
		--hybrids enchants 
		[74] = " +" .. math.floor(bonusEffects[74].statModifier * mult) .. " Personality and Accuracy.",
		[75] = " +" .. math.floor(bonusEffects[75].statModifier * mult) .. " Intellect and Might.",
		[76] = " +" .. math.floor(bonusEffects[76].statModifier * mult) .. " Intellect and Accuracy.",
		[77] = " +" .. math.floor(bonusEffects[77].statModifier * mult) .. " Might, Intellect and Personality.",
		[78] = " +" .. math.floor(bonusEffects[78].statModifier * mult) .. " Elemental Resistances.",
		[79] = " +" .. math.floor(bonusEffects[79].statModifier * mult) .. " Body and mind Resistances.",
		[80] = " +" .. math.floor(bonusEffects[80].statModifier * mult) .. " to Seven Stats, HP, SP, Armor, Resistances.",
	}

	
	return bonus2txt[bonus2]
end

--calculate price
function events.CalcItemValue(t)
	if t.Item.Number<=151 or (t.Item.Number>=803 and t.Item.Number<=936) or (t.Item.Number>=1603 and t.Item.Number<=1736) then
		--base value
		basePrice=Game.ItemsTxt[t.Item.Number].Value
		if reagentList[t.Item.Number] then
			local bonus=math.round(reagentList[t.Item.Number] *((t.Item.Bonus*0.75)/20+1)+t.Item.Bonus*0.75)
			t.Enchantment="Power: " .. bonus
			t.Value=bonus*10
			return
		end
		--add enchant price
		bonus1=t.Item.BonusStrength*100
		if t.Item.Bonus==8 or t.Item.Bonus==9 then
			bonus1=5*((2*t.Item.BonusStrength+100)^0.5-10)*100
		elseif t.Item.Bonus==10 then
			bonus1=bonus1*2
		elseif t.Item.Bonus>16 and t.Item.Bonus<=24 then
			bonus1=(bonus1/100)^2*100
		end
		
		bonus2=(t.Item.Charges%1000)*100
		bonus2Type=math.floor(t.Item.Charges/1000)
		if bonus2Type==8 or bonus2Type==9 then
			bonus2=5*((2*bonus2+100)^0.5-10)
		elseif bonus2Type==10 then
			bonus2=bonus2*2
		end
		
		MaxCharges=t.Item.MaxCharges
		--if MaxCharges <= 20 then
			mult=1+MaxCharges/20
		--else
		--	mult=2+2*(MaxCharges-20)/20
		--end
		
		basePrice=basePrice*mult
		if t.Item.Bonus2>0 and t.Item.BonusExpireTime<Game.Time then
			special=Game.SpcItemsTxt[t.Item.Bonus2-1].Value
			if bonusEffects[t.Item.Bonus2]~=nil then
				special=special*mult
			end
			if special<11 then
				basePrice=basePrice*special
			else
				basePrice=basePrice+special
			end
		end
		t.Value=basePrice+bonus1+bonus2
		if t.Item.BonusExpireTime>10 and t.Item.BonusExpireTime<1000 then
			t.Value=t.Value*2.5
		end
		if Game.HouseScreen==3 or Game.HouseScreen==94 then
			t.Value=t.Value*0.4
		end
		if Game.HouseScreen==2 or Game.HouseScreen==95 then
			count=0
			if t.Item.Bonus>0 then
				count=count+1
			end
			if t.Item.Charges>1000 then
				count=count+1
			end
			if t.Item.Bonus2>0 then
				count=count+1
			end
			if t.Item.BonusExpireTime>0 and t.Item.BonusExpireTime<3 then
				count=count+t.Item.BonusExpireTime
			end	
			if count>0 then
				t.Value=t.Value^(1+count*0.08)
			end
		end	
		if t.Value>200000  then
			t.Value=math.round(t.Value/1000)*1000
		elseif t.Value>50000  then
			t.Value=math.round(t.Value/500)*500	
		elseif t.Value>1000  then
			t.Value=math.round(t.Value/100)*100
		elseif t.Value>100 then
			t.Value=math.round(t.Value/10)*10
		end
	end
	--add reagents price
	if Game.HouseScreen==2 or Game.HouseScreen==95 then
		if reagentPrices[t.Item.Number] then
			t.Value=reagentPrices[t.Item.Number]
		end
	end
end

reagentPrices={
	[1051] = 1000,
	[1052] = 5000,
	[1053] = 15000,
	[1054] = 30000,
	[1055] = 50000,
	[1056] = 100000,
	[1057] = 200000,
	[1058] = 350000,
	[1059] = 500000,
	[1060] = 750000,
	[1061] = 1250000,
	[1062] = 750000,
	[1063] = 325000,
	[1064] = 6668999,
	[1065] = 2000000,
}
--modify weapon enchant damage

--ENCHANTS HERE
--MELEE bonuses
enchantbonusdamage = {}
enchantbonusdamage[4] = {6,8,["Type"]=2}
enchantbonusdamage[5] = {18,24,["Type"]=2}
enchantbonusdamage[6] = {36,48,["Type"]=2}
enchantbonusdamage[7] = {4,10,["Type"]=1}
enchantbonusdamage[8] = {18,45,["Type"]=1}
enchantbonusdamage[9] = {24,60,["Type"]=1}
enchantbonusdamage[10] = {2,12,["Type"]=0}
enchantbonusdamage[11] = {6,36,["Type"]=0}
enchantbonusdamage[12] = {12,72,["Type"]=0}
enchantbonusdamage[13] = {10,10,["Type"]=8}
enchantbonusdamage[14] = {24,24,["Type"]=8}
enchantbonusdamage[15] = {48,48,["Type"]=8}
enchantbonusdamage[46] = {40,80,["Type"]=0}

--calculate enchant damage
function calcEnchantDamage(pl, enchant, maxcharges, resistance,rand)
	local ench=enchantbonusdamage[enchant]
	if not ench then
		return 0
	end
	local damage=0
	if rand then
		damage=math.random(ench[1],ench[2])
	else
		damage=(ench[1]+ench[2])/2
	end
	local id=pl:GetIndex()
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 19) then
		local str=pl:GetMight()
		local int=pl:GetIntellect()
		local pers=pl:GetPersonality()
		local bonusStat=math.max(str,int,pers)
		local mult=(1+bonusStat/1000)
		damage=damage*mult
	end
	damage=damage*(1+maxcharges/20)
	damage = damage/2^(resistance%1000/100)
	return damage
end

function events.ItemAdditionalDamage(t)
	--empower enchants
	local damage=0
	if enchantbonusdamage[t.Item.Bonus2] then
		local id=t.Player:GetIndex()
		local index=table.find(damageKindMap,enchantbonusdamage[t.Item.Bonus2].Type)
		local res=t.Monster.Resistances[index]
		damage=calcEnchantDamage(t.Player, t.Item.Bonus2, t.Item.MaxCharges, res,true)
		local attackSpeedMult=getBaseAttackSpeed(t.Item)
		t.Result=math.round(damage*attackSpeedMult)
		return
	end

	--attack speed bonus, for other enchants
	local attackSpeedMult=getBaseAttackSpeed(t.Item)
	t.Result=math.round(t.Result*attackSpeedMult)
end

--weaponenchants and ring enchants checker
enchantList={
	[4] = true ,
	[5] = true ,
	[6] = true ,
	[7] = true ,
	[8] = true ,
	[9] = true ,
	[10] = true ,
	[11] = true ,
	[12] = true ,
	[13] = true ,
	[14] = true ,
	[15] = true ,
	[26] = true ,
	[27] = true ,
	[28] = true ,
	[29] = true ,
	[30] = true ,
	[31] = true ,
	[32] = true ,
	[33] = true ,
	[34] = true ,
	[46] = true ,
	[74] = true ,
	[75] = true ,
	[76] = true ,
	[77] = true ,
	[78] = true ,
	[79] = true ,
	[80] = true ,
}

--BOOK COST

local modifiedBookValues =
{
	[0] = 100,
	[1] = 200,
	[2] = 300,
	[3] = 500,
	[4] = 1000,
	[5] = 2000,
	[6] = 4000,
	[7] = 6000,
	[8] = 8000,
	[9] = 10000,
	[10] = 15000,
}

local modifiedBookValuesMM6 =
{
	[0] = 100,
	[1] = 200,
	[2] = 300,
	[3] = 300,
	[4] = 500,
	[5] = 500,
	[6] = 1000,
	[7] = 2000,
	[8] = 4000,
	[9] = 6000,
	[10] = 8000,
	[11] = 10000,
	[12] = 15000,
}


function events.GameInitialized2()
	--greater heal book 
	Game.ItemsTxt[473].Name="Greater Heal"
	Game.ItemsTxt[1275].Name="Greater Heal"
	Game.ItemsTxt[1989].Name="Greater Heal"
	--add crafting material price
	for i=1,10 do
		Game.ItemsTxt[1050+i].Value=i*1000
	end
	Game.ItemsTxt[1061].Value=30000
	Game.ItemsTxt[1062].Value=20000
	Game.ItemsTxt[1063].Value=15000
	Game.ItemsTxt[1064].Value=100000
	Game.ItemsTxt[1065].Value=60000
	
	for i=0,8 do
		for j=1,11 do
			Game.ItemsTxt[399+11*i+j].Value=modifiedBookValues[j-1]
			Game.ItemsTxt[1201+11*i+j].Value=modifiedBookValues[j-1]
		end
	end
	--MM6
	for i=0,8 do
		for j=1,13 do
			Game.ItemsTxt[1901+13*i+j].Value=modifiedBookValuesMM6[j-1]
		end
	end
	
	for i=1,22 do
		Game.ItemsTxt[476+i].Value=Game.ItemsTxt[476+i].Value*2
	end
	--single books cost increased
	local id={399,1201}
	for i=1,#id do
		Game.ItemsTxt[9+id[i]].Value= 40000
		Game.ItemsTxt[21+id[i]].Value= 40000
		Game.ItemsTxt[22+id[i]].Value= 40000
		Game.ItemsTxt[31+id[i]].Value= 20000
		Game.ItemsTxt[33+id[i]].Value= 60000
		Game.ItemsTxt[55+id[i]].Value= 60000
		Game.ItemsTxt[83+id[i]].Value= 20000
		Game.ItemsTxt[85+id[i]].Value= 40000
		Game.ItemsTxt[86+id[i]].Value= 60000
		Game.ItemsTxt[99+id[i]].Value= 100000
	end
	--MM6
	local id=1901
	Game.ItemsTxt[11+id].Value= 40000
	Game.ItemsTxt[25+id].Value= 40000
	Game.ItemsTxt[26+id].Value= 40000
	Game.ItemsTxt[37+id].Value= 20000
	Game.ItemsTxt[39+id].Value= 60000
	Game.ItemsTxt[65+id].Value= 60000
	Game.ItemsTxt[99+id].Value= 20000
	Game.ItemsTxt[101+id].Value= 40000
	Game.ItemsTxt[102+id].Value= 60000
	Game.ItemsTxt[117+id].Value= 100000
	
end

--------------------------------------
--ARTIFACTS REWORK
--------------------------------------
--Increase Base Stats of weapons (handled in line 210)
artWeap1h={500,501,502,503,504,506,507,508,509,510,512,523,524,526,527,528,529,538,539,542,1302,1303,1304,1305,1308,1310,1311,1312,1316,1319,1328,1329,1330,1333,1340,1342,1343,1344,1345,1353,1354,2020,2021,2023,2025,2035,2036,2037,2038,2040}
artWeap2h={505,511,525,530,540,541,1309,1320,1351,2022,2024,2039}
artArmors={513,514,515,516,517,518,520,522,533,534,1306,1307,1313,1314,1318,1321,1322,1323,1324,1327,1331,1332,1334,1335,1336,1337,1346,1349,1350,1352,2026,2027,2028,2030,2031,2041,2042,2043,2045,2046}

function events.GameInitialized2()
--Artifact upscaler 
	for j=1,#artWeap1h do
		i=artWeap1h[j]
		Game.ItemsTxt[i].Mod1DiceSides = ((Game.ItemsTxt[i].Mod1DiceSides+1)*2)-1
		Game.ItemsTxt[i].Mod2=Game.ItemsTxt[i].Mod2*2
	end
	for j=1,#artWeap2h do
		i=artWeap2h[j]
		Game.ItemsTxt[i].Mod1DiceSides = ((Game.ItemsTxt[i].Mod1DiceSides+1)*3)-1
		Game.ItemsTxt[i].Mod2=Game.ItemsTxt[i].Mod2*3
	end
end

--below commented code might turn useful if I have to modify some artifact text individually
--[[
function events.BuildItemInformationBox(t)
	if t.Description and artifactTextBuilder(t.Item.Number,0) and Game.CurrentPlayer>=0 then
		level=Party[Game.CurrentPlayer].LevelBase
		t.Description=artifactTextBuilder(t.Item.Number,level)
	end
end

require("string")
function artifactTextBuilder(n,lvl)
	lvl=math.min(lvl/80,2.5)
	artifactTxt={
		[2023]= "Heavy, yet seemingly light as a feather in skilled hands, Excalibur confers great might upon its wielder.  Opponents do not easily walk away from blows struck by this legendary weapon.  (Special Powers:  +" .. math.round(30*lvl) .. " Might)",
		[2024]= "Traditionally carried by the High Druid, but lost during struggles over religious doctrine, Merlin acts as a reservoir of spell power the wielder can draw upon at any time.  Merlin is enchanted with swiftness, and rains blows upon enemies much faster than an ordinary staff. (Special Powers:  Swiftness and +" .. math.round(40*lvl) .. " Spell Points)",
	}
	
	return artifactTxt[n]
end
]]
function events.BuildItemInformationBox(t)
	if t.Description and ((t.Item.Number>=500 and t.Item.Number<=543) or (t.Item.Number>=1302 and t.Item.Number<=1354) or (t.Item.Number>=2020 and t.Item.Number<=2049)) then
		require("string")
		pattern = "(%d+)"
		text=t.Description
		t.Description = text:gsub(pattern, replaceNumber)
		t.Description = t.Description .. "\n\nScale with player level, up to level 250."
	end
end

function replaceNumber(match)
	lvl=Party[Game.CurrentPlayer].LevelBase
	lvl=artifactPowerMult(lvl)
    num = tonumber(match)
    if num then
        return tostring(math.round(num * lvl))
    end
    return match
end

--------------------------------
--ARTIFACTS BASE STATS SCALING--
--------------------------------

function events.BuildItemInformationBox(t)
	if (t.Item.Number>=500 and t.Item.Number<=543) or (t.Item.Number>=1302 and t.Item.Number<=1354) or (t.Item.Number>=2020 and t.Item.Number<=2049) then 
		if t.Type then
			local id=Game.CurrentPlayer
			if id==-1 then
				id=0
			end
			local artifactMult=artifactPowerMult(Party[id].LevelBase, true)
			local txt=Game.ItemsTxt[t.Item.Number]
			local ac=math.ceil((txt.Mod2+txt.Mod1DiceCount)*artifactMult)
			if ac>0 then 			
				t.BasicStat= "Armor: +" .. ac
			end
			--WEAPONS
			artifactMult=artifactPowerMult(Party[id].LevelBase)
			local equipStat=txt.EquipStat
			if equipStat<=2 then
				local bonus=math.ceil(txt.Mod2*artifactMult)
				local sides=math.ceil(txt.Mod1DiceSides*artifactMult)
				t.BasicStat= "Attack: +" .. bonus .. "  " .. "Damage: " ..  txt.Mod1DiceCount .. "d" .. sides .. "+" .. bonus
			end
			local skill=t.Item:T().Skill
			if table.find(twoHandedAxes, t.Item.Number) or table.find(oneHandedAxes, t.Item.Number) then
				skill=3
			end
			if baseRecovery[skill] then
				local itemLevel=artifactMult*100
				baseSpeed=baseRecovery[skill] * (0.75+itemLevel/250)
				baseSpeed=math.round(baseSpeed/10)/10
				
				t.Type = t.Type .. "\nAttack Speed: " .. baseSpeed
			end
		end
	end
end
--[[
--increase artifact damage tooltip
function events.CalcStatBonusByItems(t)
	local cs = const.Stats
	if t.Stat==cs.MeleeDamageMin or t.Stat==cs.MeleeDamageMax or t.Stat==cs.MeleeAttack then
		for it in t.Player:EnumActiveItems() do 
			if (it.Number>=500 and it.Number<=543) or (it.Number>=1302 and it.Number<=1354) or (it.Number>=2020 and it.Number<=2049) then 
				txt=Game.ItemsTxt[it.Number]
				c=txt.EquipStat
				if c<=1 then
					t.Result=t.Result-txt.Mod2+math.ceil(txt.Mod2*artifactPowerMult(t.Player.LevelBase))
					if t.Stat==cs.MeleeDamageMax then
						t.Result=t.Result-(txt.Mod1DiceCount*txt.Mod1DiceSides-txt.Mod1DiceCount)+(txt.Mod1DiceCount*txt.Mod1DiceSides*artifactPowerMult(t.Player.LevelBase))
					end
				end
			end	
		end
	end
	--same for ranged
	if t.Stat==cs.RangedDamageMin or t.Stat==cs.RangedDamageMax or t.Stat==cs.RangedAttack then
		for it in t.Player:EnumActiveItems() do 
			if (it.Number>=500 and it.Number<=543) or (it.Number>=1302 and it.Number<=1354) or (it.Number>=2020 and it.Number<=2049) then 
				txt=Game.ItemsTxt[it.Number]
				c=txt.EquipStat
				if c==2 then
				t.Result=t.Result-txt.Mod2+math.ceil(txt.Mod2*artifactPowerMult(t.Player.LevelBase))
					if t.Stat==cs.RangedDamageMax then
						t.Result=t.Result-(txt.Mod1DiceCount*txt.Mod1DiceSides-txt.Mod1DiceCount)+(txt.Mod1DiceCount*txt.Mod1DiceSides*artifactPowerMult(t.Player.LevelBase))
					end
				end
			end	
		end
	end
end
]]
------------------------------------------------------------------
--bruteforce fix to items spawning maxcharges more than intended--
------------------------------------------------------------------
function events.BeforeNewGameAutosave()
	vars.hirelingFix=true
	for i=0,Party.High do
		for j=1, Party[0].Items.High do
			Party[i].Items[j].MaxCharges=0
			Party[i].Items[j].Charges=0
			Party[i].Items[j].BonusExpireTime=0
			if Party[i].Items[j].Bonus>24 then
				Party[i].Items[j].Bonus=0
			end
		end
	end
end

--fix maxcharges if someone is trying to equip on a player
function events.Action(t)
	if t.Action==133 and Game.freeProgression then
		partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
		maxItemBolster=(partyLevel)/5+20
		if not Game.freeProgression then
			maxItemBolster=maxItemBolster+10
		end
		--failsafe
		if Mouse.Item and Mouse.Item.Charges==0 and Mouse.Item.Bonus==0 and Mouse.Item.Bonus2==0 and Mouse.Item.MaxCharges>maxItemBolster then
			Mouse.Item.MaxCharges=math.round(partyLevel/5)
		end
	end
end

--REVERTED AS HIGHER DIFFICULTY WILL LOWER THE DAMAGE!
--vampiric nerf
gotVamp={}
gotBowVamp={}
function events.ItemAdditionalDamage(t)
	vamp=false
	gotVamp[t.Player:GetIndex()]=false
	for i=0,1 do
		it=t.Player:GetActiveItem(i)
		if it then
			vamp=it.Bonus2==41 or it.Bonus2==16
			gotVamp[t.Player:GetIndex()]=gotVamp[t.Player:GetIndex()] or 0
			gotVamp[t.Player:GetIndex()]=gotVamp[t.Player:GetIndex()]/2+1
		end
	end
	if vamp then
		t.Vampiric = false
	else
		gotVamp[t.Player:GetIndex()]=false
	end
	it=t.Player:GetActiveItem(2)
	--bow
	vamp=false
	it=t.Player:GetActiveItem(2)
	if it then
		vamp=it.Bonus2==41 or it.Bonus2==16
	end
	if vamp then
		t.Vampiric = false
		gotBowVamp[t.Player:GetIndex()]=true
	else
		gotBowVamp[t.Player:GetIndex()]=false
	end
end

function events.GameInitialized2() --make it load later compared to other scripts
	function events.CalcDamageToMonster(t)
		local data=WhoHitMonster()
		if data and data.Player then
			local heal=t.Result*data.Player.LevelBase^0.6/t.Monster.Level*0.30
			if getMapAffixPower(32) then
				heal=heal*(1-getMapAffixPower(32)/100)
			end
			if t.DamageKind==4 then
				--melee
				if gotVamp[data.Player:GetIndex()] and not data.Object then
					local fullHP=t.Player:GetFullHP()
					t.Player.HP=math.min(fullHP,t.Player.HP+heal)
				end
				--ranged
				if gotBowVamp[data.Player:GetIndex()] and data.Object and data.Object.Spell==133 then
					local fullHP=t.Player:GetFullHP()
					t.Player.HP=math.min(fullHP,t.Player.HP+heal*0.5)
				end
			elseif data and data.Player then --spell leech
				for i=1,2 do
					it=t.Player:GetActiveItem(i)
					local fullHP=t.Player:GetFullHP()
					if it and it.Bonus2==40 then
						t.Player.HP=math.min(fullHP,t.Player.HP+heal*0.5)
					end
				end
			end 
		
			local pl=data.Player
			local race=Game.CharacterPortraits[pl.Face].Race
			if race==const.Race.Vampire then
				local fullHP=t.Player:GetFullHP()
				local heal=heal/4
				if pl.Class==40 or pl.Class==41 then
					heal=heal*2
				end
				if data.Object and data.Object then
					heal=heal/2
				end
				heal=math.ceil(heal)
				t.Player.HP=math.min(fullHP,t.Player.HP+heal)
			end
		end
	end
end

			

--SHOW POWER/VITALITY CHANGE IN TOOLTIPS
slotMap={
	[0]=1,
	[1]=1,
	[2]=2,
	[3]=3,
	[4]=0,
	[5]=4,
	[6]=5,
	[7]=6,
	[8]=7,
	[9]=8,
	[11]=9,
	[10]=10,
}


function events.BuildItemInformationBox(t)
	partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
	maxItemBolster=(partyLevel)/5+20
	--failsafe
	if Game.freeProgression and t.Item and t.Item.Charges==0 and t.Item.Bonus==0 and t.Item.Bonus2==0 and t.Item.MaxCharges>maxItemBolster then
		if not Game.freeProgression then
			maxItemBolster=maxItemBolster+10
		end
		t.Item.MaxCharges=math.round(partyLevel/5)
	end
	if t.Description then
		if Game.CurrentPlayer==-1 then return end
		local equipStat=t.Item:T().EquipStat
		if equipStat<=11 then 
			local i=Game.CurrentPlayer
			local pl=Party[i]
			local playerIndex=pl:GetIndex()
			local oldDPS1, oldDPS2, oldDPS3, oldVitality=calcPowerVitality(pl)
			--substitute item
			local slot=slotMap[equipStat]
			local i=0
			local found=false
			local index=0
			local itemBackup={}
			local it=pl:GetActiveItem(slot)
			if it then
				--backup item
				itemBackup["BodyLocation"]=it.BodyLocation
				itemBackup["Bonus"]=it.Bonus
				itemBackup["Bonus2"]=it.Bonus2
				itemBackup["BonusExpireTime"]=it.BonusExpireTime
				itemBackup["BonusStrength"]=it.BonusStrength
				itemBackup["Broken"]=it.Broken
				itemBackup["Charges"]=it.Charges
				itemBackup["Condition"]=it.Condition
				itemBackup["Hardened"]=it.Hardened
				itemBackup["Identified"]=it.Identified
				itemBackup["MaxCharges"]=it.MaxCharges
				itemBackup["Number"]=it.Number
				itemBackup["Owner"]=it.Owner
				itemBackup["Refundable"]=it.Refundable
				itemBackup["Stolen"]=it.Stolen
				itemBackup["TemporaryBonus"]=it.TemporaryBonus
				
				--substitute item
				it.BodyLocation=t.Item.BodyLocation
				it.Bonus=t.Item.Bonus
				it.Bonus2=t.Item.Bonus2
				it.BonusExpireTime=t.Item.BonusExpireTime
				it.BonusStrength=t.Item.BonusStrength
				it.Broken=t.Item.Broken
				it.Charges=t.Item.Charges
				it.Condition=t.Item.Condition
				it.Hardened=t.Item.Hardened
				it.Identified=t.Item.Identified
				it.MaxCharges=t.Item.MaxCharges
				it.Number=t.Item.Number
				it.Owner=t.Item.Owner
				it.Refundable=t.Item.Refundable
				it.Stolen=t.Item.Stolen
				it.TemporaryBonus=t.Item.TemporaryBonus
			else
				return
			end
			mawRefresh(playerIndex)
			mawRefresh(playerIndex)
			
			local newDPS1, newDPS2, newDPS3, newVitality=calcPowerVitality(pl)
			local increaseDPSPercent=math.round(math.max(newDPS1, newDPS2, newDPS3)/math.max(oldDPS1, oldDPS2, oldDPS3)*10000-10000)/100
			local increaseVitalityPercent=math.round(newVitality/oldVitality*10000-10000)/100
			if increaseDPSPercent<0 then
				t.Description = t.Description .. "\n\n" .. "Power: " .. StrColor(255,0,0,increaseDPSPercent .. "%")
			elseif increaseDPSPercent>0 then
				t.Description = t.Description .. "\n\n" .. "Power: " .. StrColor(0,255,0,"+" .. increaseDPSPercent .. "%")
			end
			if increaseVitalityPercent<0 then
				t.Description = t.Description .. "\n" .. "Vitality: " .. StrColor(255,0,0, increaseVitalityPercent .. "%")
			elseif increaseVitalityPercent>0 then
				t.Description = t.Description .. "\n" .. "Vitality: " .. StrColor(0,255,0,"+" .. increaseVitalityPercent .. "%")
			end
			--restore item
			it.BodyLocation=itemBackup["BodyLocation"]
			it.Bonus=itemBackup["Bonus"]
			it.Bonus2=itemBackup["Bonus2"]
			it.BonusExpireTime=itemBackup["BonusExpireTime"]
			it.BonusStrength=itemBackup["BonusStrength"]
			it.Broken=itemBackup["Broken"]
			it.Charges=itemBackup["Charges"]
			it.Condition=itemBackup["Condition"]
			it.Hardened=itemBackup["Hardened"]
			it.Identified=itemBackup["Identified"]
			it.MaxCharges=itemBackup["MaxCharges"]
			it.Number=itemBackup["Number"]
			it.Owner=itemBackup["Owner"]
			it.Refundable=itemBackup["Refundable"]
			it.Stolen=itemBackup["Stolen"]
			it.TemporaryBonus=itemBackup["TemporaryBonus"]
			mawRefresh(playerIndex)
			mawRefresh(playerIndex)
		end
	end
end
--item level
function events.BuildItemInformationBox(t)
	if t.Item.Number<=151 or (t.Item.Number>=803 and t.Item.Number<=936) or (t.Item.Number>=1603 and t.Item.Number<=1736) then 
		if t.Description then
			local itemLevel=t.Item.MaxCharges*5
			local tot=0
			local lvl=0
			for i=1, 6 do
				tot=tot+t.Item:T().ChanceByLevel[i]
				lvl=lvl+t.Item:T().ChanceByLevel[i]*i
			end
			itemLevel=itemLevel+math.round(lvl/tot*18-17)
			--t.Description = t.Description .. "\n\nItem Level: " .. itemLevel
			local maxCharges=t.Item.MaxCharges
			if t.Item.BonusExpireTime>0 and t.Item.BonusExpireTime<=2 then
				maxCharges=math.floor(math.min(maxCharges/1.2,maxCharges-5))
			end
			if t.Item.BonusExpireTime>10 and t.Item.BonusExpireTime<=100 then
				maxCharges=math.floor(math.min(maxCharges/1.2,maxCharges-5))
			end
			local levelRequired=(maxCharges)*3+lvl/tot*2-12
			if Game.BolsterAmount>=300 then
				levelRequired=levelRequired-6
			end
			if vars.Mode==2 then
				levelRequired=levelRequired-3
			end
			local enchants=3
			if t.Item.Bonus>0 then
				enchants=enchants+1
			end
			if t.Item.Bonus2>0 then
				enchants=enchants+1
			end
			if t.Item.Charges>1000 then
				enchants=enchants+1
			end
			levelRequired=math.max(1,math.floor(levelRequired*enchants/6))
			local txt="\n\nLevel Required: " .. levelRequired 
			--local txt="" --not shown when can equip
			--check if equippable
			local id=Game.CurrentPlayer
			if id<0 or id>Party.High then
				id=0
			end
			local plLvl=Party[id].LevelBase
			if plLvl<levelRequired then
				txt=StrColor(255,0,0,txt)
			end
			t.Description = t.Description .. txt
			
		end	
		
		--attack speed tooltip
		local skill=t.Item:T().Skill
		if table.find(twoHandedAxes, t.Item.Number) or table.find(oneHandedAxes, t.Item.Number) then
			skill=3
		end
		if t.Type and baseRecovery[skill] then
			local itemLevel=t.Item.MaxCharges*5
			local tot=0
			local lvl=0
			for i=1, 6 do
				tot=tot+t.Item:T().ChanceByLevel[i]
				lvl=lvl+t.Item:T().ChanceByLevel[i]*i
			end
			itemLevel=itemLevel+math.round(lvl/tot*18-17)
			baseSpeed=baseRecovery[skill] * (0.75+itemLevel/250)
			baseSpeed=math.round(baseSpeed/10)/10
			
			t.Type = t.Type .. "\nAttack Speed: " .. baseSpeed
		end
	end
end

function calculateStatsAdd(item, stats)
	statValue={}
	for i=1,#stats do
		statValue[i]=0
		--bonus1
		if item.Bonus==stats[i] then
			statValue[i]=statValue[i]+item.BonusStrength
		end
		--bonus2
		if math.floor(item.Charges/1000)==stats[i] then
			statValue[i]=statValue[i]+item.Charges%1000
		end
		--bonus special
		--maxcharges mult
		MaxCharges=item.MaxCharges
		--if MaxCharges <= 20 then
			mult=1+MaxCharges/20
		--else
		--	mult=2+2*(MaxCharges-20)/20
		--end
		
		b2=bonusEffects[item.Bonus2]
		if b2 then
			if b2.bonusValues then 
				for v=1,#b2.bonusValues do
					if item.Bonus2==48 and bonusEffects[48].bonusValues[v]==stats[i] then
						statValue[i]=statValue[i]+math.floor(b2.statModifier[v]*mult)
					elseif b2.bonusValues[v]==stats[i] then
						statValue[i]=statValue[i]+math.floor(b2.statModifier*mult)
					end
				end
			elseif b2.bonusRange then
				if b2.bonusRange[1]<=stats[i] and b2.bonusRange[2]>=stats[i] then
					statValue[i]=statValue[i]+math.floor(b2.statModifier*mult)
				end
			end
		end
	end	
	return statValue
end

function getNewArmor(it)
	local txt=it:T()
	local charges=it.MaxCharges
	if txt.EquipStat>=3 and txt.EquipStat<=9 then
		local ac3=txt.Mod2+txt.Mod1DiceCount
		local n=it.Number
		if charges>0 then
			if ac3>0 then
				local lookup=0
				while txt.NotIdentifiedName==Game.ItemsTxt[n+lookup+1].NotIdentifiedName do 
					lookup=lookup+1
				end
				local ac=txt.Mod2+txt.Mod1DiceCount 
				local ac2=Game.ItemsTxt[n+lookup].Mod2+Game.ItemsTxt[n+lookup].Mod1DiceCount 
				local bonusAC=ac2*(charges/20)
				if charges <= 20 then
					ac3=ac3+math.round(bonusAC)
				else
					local bonusAC=(ac+ac2)*(charges/20)
					ac3=ac3+math.round(bonusAC)
				end				
			end
		end
		return ac3	
	else
		return 0
	end
end




function events.ModifyItemDamage(t)
t.Result=0
end

plItemsStats={}	
for i=0,200 do
	plItemsStats[i]={}
	for v=1,50 do
		plItemsStats[i][v]=0
	end
end
function events.CalcStatBonusByItems(t)
	if Game.CurrentScreen==21 then return end
	t.Result=0
	if t.Stat>=0 and t.Stat<24 then
		if plItemsStats[t.PlayerIndex] then
			t.Result=plItemsStats[t.PlayerIndex][t.Stat+1]
		end
	end
	if statMap[t.Stat] then
		t.Result=plItemsStats[t.PlayerIndex][statMap[t.Stat]]
	end
end

--get artifacts Skills
function events.GetSkill(t)
	local bonus=0
	if t.Skill>=12 and t.Skill<=20 then
		bonus = plItemsStats[t.PlayerIndex][table.find(equipSpellMap,t.Skill)]
	end
	if plItemsStats[t.PlayerIndex] and plItemsStats[t.PlayerIndex][t.Skill+50] then
		bonus = bonus+plItemsStats[t.PlayerIndex][t.Skill+50]
	end
	if t.Skill<=38 then
		t.Result=bonus+t.Player.Skills[t.Skill]
		--cap the skill up to double the base amount
		local s1,m1=SplitSkill(t.Result)
		local s2,m2=SplitSkill(t.Player.Skills[t.Skill])
		t.Result=JoinSkill(math.min(s1,s2*2),m2)
	end
end

function events.GameInitialized2()
	--weapons and armors
    referenceAC = {}
    referenceWeaponAttack = {}
    referenceWeaponSides = {}

    for i = 0, Game.ItemsTxt.High - 1 do
        local txt = Game.ItemsTxt
        local lookup = 0
        while txt[i].NotIdentifiedName == txt[i + lookup + 1].NotIdentifiedName do
            lookup = lookup + 1
        end

        if (txt[i].Skill >= 8 and txt[i].Skill <= 11) or txt[i].Skill == 40 then
            -- Armors
            referenceAC[i] = txt[i + lookup].Mod2 + txt[i + lookup].Mod1DiceCount
        elseif txt[i].Skill <= 6 or txt[i].Skill==39 then
            -- Weapons
            referenceWeaponAttack[i] = txt[i + lookup].Mod2
            referenceWeaponSides[i] = txt[i + lookup].Mod1DiceSides
        end
    end
end

local bonusBaseEnchantSkill={
	[17]=const.Skills.Alchemy,
	[18]=const.Skills.Stealing,
	[19]=const.Skills.DisarmTraps,
	[20]=const.Skills.IdentifyItem,
	[21]=const.Skills.IdentifyMonster,
	[22]=const.Skills.Armsmaster,
	[23]=const.Skills.Dodging,
	[24]=const.Skills.Unarmed,
}

--RECALCULATE THE WHOLE ITEMS EFFECTS
function itemStats(index)
	if index==-1 or index==nil then
		return 0
	end
	local id=0
	for i=0,Party.High do 
		if Party[i]:GetIndex()==index then
			id=i
		end
	end
	if id>Party.High then return end
	local pl=Party[id]
	tab=plItemsStats[index]
	
	--set all to 0
	tab={}
	for i=1,50 do
		tab[i]=0
	end
	--used for armor skill	
	shieldAC=0
	armorAC=0
	normalEnchantResistance=normalEnchantResistance or {}
	normalEnchantResistance[index]={}
	for i=11,16 do
		normalEnchantResistance[index][i]=0
	end
	--iterate items and get bonuses
	for it in pl:EnumActiveItems() do
		--maxcharges fix for moon cloak
		if it.Number==1349 or it.Number==1350 then
			it.MaxCharges=0
		end
		
		local txt=it:T()
		if (txt.Skill>=8 and txt.Skill<=11) or (txt.Skill==40 and txt.EquipStat~=12) then --AC from items
			local mult=0
			local resMult=0
			local skill=it:T().Skill
			local slot=it:T().EquipStat
						
			local ac=txt.Mod1DiceCount+txt.Mod2
			local acBonus=ac
			if it.MaxCharges>0 then 
				local ac2=referenceAC[it.Number]
				local bonusAC=ac2*(it.MaxCharges/40)
				acBonus=ac+math.round(bonusAC)
			end
			--artifacts
			if table.find(artArmors,it.Number) then 
				artifactMult=artifactPowerMult(pl.LevelBase, true)
				acBonus=math.ceil(acBonus*artifactMult)
			end

			acBonus=math.round(acBonus*(1+mult))
			--used later
			if skill==8 then
				shieldAC=shieldAC+acBonus
			else
				armorAC=armorAC+acBonus
			end
			tab[10]=tab[10]+acBonus
		end
				
		--bolster mult
		mult=1+it.MaxCharges/20
		if it.Bonus>0 then 
			if it.Bonus<=10 then
				tab[it.Bonus]=tab[it.Bonus]+it.BonusStrength
			elseif it.Bonus<=16 then
				normalEnchantResistance[index][it.Bonus]=math.max(normalEnchantResistance[index][it.Bonus], it.BonusStrength)		
			else
				local tabNumber=bonusBaseEnchantSkill[it.Bonus]+50
				tab[tabNumber]=tab[tabNumber] or 0
				tab[tabNumber]=tab[tabNumber]+it.BonusStrength
				--tab[tabNumber]=math.max(tab[tabNumber] or 0, it.BonusStrength)
			end
		end
		--fix for double enchants
		if it.Bonus2==62 then
			tab[74]=tab[74] or 0
			tab[74]=tab[74]+3
			tab[84]=tab[84] or 0
			tab[84]=tab[84]+3
		end		
		if it.Charges>1000 then
			local bonus=math.floor(it.Charges/1000)
			if bonus<=10 then
				tab[math.floor(it.Charges/1000)]=tab[math.floor(it.Charges/1000)]+it.Charges%1000
			else
				normalEnchantResistance[index][bonus]=math.max(normalEnchantResistance[index][bonus], it.Charges%1000)	
			end
		end		
		if it.Bonus2>0 then
			bonusData = bonusEffects[it.Bonus2]
			if bonusData then
				if bonusData.bonusRange then
					for i=bonusData.bonusRange[1], bonusData.bonusRange[2] do
						tab[i]=tab[i]+bonusData.statModifier*mult
					end
				elseif bonusData.bonusValues then
					for i =1, 3 do
						if bonusData.bonusValues[i] then
							 modifier = bonusData.statModifier
							if type(modifier) == "table" then
								tab[bonusData.bonusValues[i]] = math.round(tab[bonusData.bonusValues[i]] + modifier[i] * mult)
							else
								tab[bonusData.bonusValues[i]] = math.round(tab[bonusData.bonusValues[i]] + modifier * mult)
							end
						end
					end
				end
			end
		end

		
		--weapons
		if txt.Skill <= 6 or txt.Skill==39 then
			local bonus = txt.Mod2
			local bonus2 = referenceWeaponAttack[it.Number]
			local bonusATK

			bonusATK = bonus2 * (it.MaxCharges / 30)
			
			bonus = bonus + math.round(bonusATK)

			local sides = txt.Mod1DiceSides
			local sides2 = referenceWeaponSides[it.Number]
			local sidesBonus
			
			sidesBonus = sides2 * (it.MaxCharges / 30)
			
			sidesBonus = sides + math.round(sidesBonus)
			
			if table.find(artWeap1h,it.Number) or table.find(artWeap2h,it.Number) then 
				if txt.EquipStat<=1 then
					artifactMult=artifactPowerMult(pl.LevelBase)
					bonus=math.ceil(txt.Mod2*artifactMult)
					sidesBonus=math.ceil(txt.Mod1DiceSides*artifactMult)
				end
			end	
			
			local skill=txt.Skill
			--minotaur fix
			if table.find(oneHandedAxes, it.Number) or table.find(twoHandedAxes, it.Number) then
				skill=3
			end	
			
			--armsmaster
			local s,m = SplitSkill(pl:GetSkill(const.Skills.Armsmaster))
			--weapon 
			local s2,m2=SplitSkill(pl:GetSkill(skill))
			
			if skill==0 then
				if m2==4 then
					s,m = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
					s=s/2
				else
					s=0
					m=0
				end
			end
			
			local mult=1
			if skillDamage[skill] then
				mult=(1+s2*skillDamage[skill][m2]/100)
			end
			
			local side=sidesBonus*mult
			local add=bonus*mult
			local armsDmg=armsmasterDamage[m]*s*mult
			
			--substitute with unarmed if staff
			if skill==0 then
				armsDmg=skillDamage[33][m]*s*mult
			end
			
			
			--make classes such as DK, SERAPH,SHAMAN to make their bonus work in a similar way as armsmaster
			--DK
			if table.find(dkClass, pl.Class) then	
				local s1, m1=SplitSkill(pl.Skills[const.Skills.Water])
				local s2, m2=SplitSkill(pl.Skills[const.Skills.Dark])
				local bonus=s1*math.min(m1, 3)+s2*math.min(m2, 3)
				armsDmg=armsDmg+bonus*mult
			end
			--SERAPHIM
			if table.find(seraphClass, pl.Class) then	
				local s1, m1=SplitSkill(pl.Skills[const.Skills.Mind])
				local s2, m2=SplitSkill(pl.Skills[const.Skills.Light])
				local bonus=s1*m1+s2*m2
				armsDmg=armsDmg+bonus*mult
			end
			--SHAMAN
			if table.find(shamanClass, pl.Class) then	
				local m1=SplitSkill(pl.Skills[const.Skills.Fire])
				local m2=SplitSkill(pl.Skills[const.Skills.Air])
				local m3=SplitSkill(pl.Skills[const.Skills.Water])
				local m4=SplitSkill(pl.Skills[const.Skills.Earth])
				local m5=SplitSkill(pl.Skills[const.Skills.Spirit])
				local m6=SplitSkill(pl.Skills[const.Skills.Mind])
				local m7=SplitSkill(pl.Skills[const.Skills.Body])
				local bonus=m2+m3+m4+m5+m1+m6+m7
				armsDmg=armsDmg+bonus*mult
			end
			
			--split armsmaster between main and offhand
			local item=pl:GetActiveItem(0)
			if item and skill ~= 5 and item:T().Skill~=8 then
				if skill~=8 then
					armsDmg=armsDmg/2
				end
			end
			
			local totBonus=armsDmg+add
			if skill ~= 5 then
				tab[40] = tab[40] + math.round(bonus)
				tab[41] = tab[41] + math.round(bonus)
				tab[42] = tab[42] + txt.Mod1DiceCount+math.round(totBonus)
				tab[43] = tab[43] + math.round(side)*txt.Mod1DiceCount+math.round(totBonus)
			else
				tab[44] = tab[44] + math.round(bonus)
				tab[45] = tab[45] + math.round(bonus)
				tab[46] = tab[46] + math.round(txt.Mod1DiceCount)+add
				tab[47] = tab[47] + math.round(side)*txt.Mod1DiceCount+add
			end
		end
		
		--skills
		if equipSpellMap[it.Bonus2] then
			tab[it.Bonus2]=tab[it.Bonus2] or 0
			tab[it.Bonus2]=tab[it.Bonus2] + (5 +  math.floor(it.MaxCharges/4))
		end
		--artifacts stats bonus
		
		if artifactStatsBonus[it.Number] then
			artifactMult=artifactPowerMult(pl.LevelBase)
			for key,value in pairs(artifactStatsBonus[it.Number]) do
				tab[key+1]=tab[key+1]+value*artifactMult
			end
		end
		--artifacts skill bonuses
		if artifactSkillBonus[it.Number] then
			artifactMult=artifactPowerMult(pl.LevelBase)
			for key,value in pairs(artifactSkillBonus[it.Number]) do
				tab[key+50]=tab[key+50] or 0
				tab[key+50]=tab[key+50]+math.round(value*artifactMult)
			end
		end
	end	
	
	--bless
	if buffRework then
		if pl.SpellBuffs[1].ExpireTime>=Game.Time then
			local s,m, level=getBuffSkill(46)
			local blessBonus=buffPower[46].Base[m]+level*0.5*(1+buffPower[46].Scaling[m]*s/100)
			tab[40] = tab[40] + blessBonus
			tab[44] = tab[44] + blessBonus
		end
	end
	
	--armor skill multiplier
	local armorMult=0
	local armorResMult=0
	local shieldMult=0
	local shieldResMult=0
	local it=pl:GetActiveItem(3)
	if it then
		bodyArmorSkill=it:T().Skill
		bodyS, bodyM=SplitSkill(pl:GetSkill(bodyArmorSkill))
		armorMult=skillItemAC[bodyArmorSkill][bodyM]*bodyS/100
		armorResMult=skillItemRes[bodyArmorSkill][bodyM]*bodyS/100
	end
	local s,m=SplitSkill(pl:GetSkill(const.Skills.Shield))
	local shieldMult=(skillItemAC[const.Skills.Shield][m]*s/100)
	local shieldResMult=(skillItemRes[const.Skills.Shield][m]*s/100)
	
	itemArmorClassBonus1=math.round(armorAC*armorMult)
	itemArmorClassBonus2=math.round(shieldAC*shieldMult)
	tab[10]=tab[10]+itemArmorClassBonus1+itemArmorClassBonus2
	
	itemResistanceBonus1=math.round(armorAC*armorResMult) 
	itemResistanceBonus2=math.round(shieldAC*shieldResMult)
	
	for i=11,16 do
		tab[i]=tab[i]+itemResistanceBonus1+itemResistanceBonus2
	end
	
	--------------
	--end of items
	--------------
	--buffs
	if buffRework then
		local buffList={6,0,17,4,12,1}
		local spellList={3,14,25,36,58,69}
		local spellStat={[3]=2,[14]=6,[25]=7,[36]=4,[46]=5,[58]=3,[69]=1}
		--resistances and stats
		local s, m, level=getBuffSkill(85)
		local buff2=buffPower[85].Base[m]+(level/2)*(1+buffPower[85].Scaling[m]/100*s)
		local s, m, level=getBuffSkill(83)
		local buff3=buffPower[83].Base[m]+(level/2)*(1+buffPower[83].Scaling[m]/100*s)
		for i=1,6 do
			local buff=0
			local statBuff=0
			if Party.SpellBuffs[buffList[i]].ExpireTime>=Game.Time then
				local s, m, level=getBuffSkill(spellList[i])
				buff=buffPower[spellList[i]].Base[m]+(level/2)*(1+buffPower[spellList[i]].Scaling[m]/100*s)
				buff4=math.max(buff,buff2)
				tab[i+10]=tab[i+10]+buff4
			end
			statBuff=math.max(buff, buff3)
			local tabID=spellStat[spellList[i]]
			tab[tabID]=tab[tabID]+statBuff
		end
		--special case for accuracy, as it comes from bless
		local accBonus=0
		local buff=0
		if pl.SpellBuffs[1].ExpireTime>=Game.Time then
			local s, m, level=getBuffSkill(46)
			buff=buffPower[3].Base[m]+(level/2)*(1+buffPower[3].Scaling[m]/100*s)
		end
		accBonus=math.max(buff3, buff)
		tab[5]=tab[5]+accBonus
		--stoneskin
		if Party.SpellBuffs[15].ExpireTime>=Game.Time then
			local s,m,level=getBuffSkill(38)
			local s2,m2,level2=getBuffSkill(86)
			s=math.max(s,s2/1.5)
			m=math.max(m,m2)
			level=math.max(level,level2)
			acBonus=buffPower[38].Base[m]+(level/2)*(1+buffPower[38].Scaling[m]/100*s)
			tab[10]=tab[10]+acBonus
		end
	end
	--dragon
	if Game.CharacterPortraits[pl.Face].Race==const.Race.Dragon then
		for i=1,16 do
			tab[i]=tab[i]*3
		end
	end
	--add luck to resistances
	local luck=tab[7]+pl.LuckBase+pl.LuckBonus
	if luck<=21 then
		luck=(luck-13)/2
	elseif luck<=100 then
		luck=math.floor(luck/5)
	else
		luck=math.floor(luck/10)+10
	end
	
	for i=11, 16 do
		tab[i]=tab[i]+luck -- -penalty
	end	
	--BB HP INCREASE
	local endurance=tab[4]+pl.EnduranceBase+pl.EnduranceBonus+Party.SpellBuffs[2].Power
	local endEff
	if endurance<=21 then
		endEff=(endurance-13)/2
	else
		endEff=math.floor(endurance/5)
	end
	
	local s,m=SplitSkill(pl:GetSkill(const.Skills.Bodybuilding))	
	if m==4 then
		m=5
	end
	BBHP=s*m
	level=pl.LevelBonus+pl.LevelBase
	hpScaling=Game.Classes.HPFactor[pl.Class]
	baseHP=Game.Classes.HPBase[pl.Class]+hpScaling*(level+endEff+BBHP)
	fullHP=baseHP+tab[8]
	Endurancebonus=fullHP*endurance/1000
	BBBonus=fullHP*(1.02^s-1)
	
	--used for stats
	hpStatsMap=hpStatsMap or {}
	hpStatsMap[id]={
		["totalhpFromItems"]=math.round(tab[8]),
		["totalEnduranceBonus"]=math.round(Endurancebonus+endEff*hpScaling),
		["totalBBBonus"]=math.round(BBBonus+s*m*hpScaling),
		["totalBaseHP"]=math.round(Game.Classes.HPBase[pl.Class]+hpScaling*level),
	}
	
	tab[8]=tab[8]+Endurancebonus+BBBonus+hpScaling*BBHP
	
	--get bonus stats from skills
	
	--enlighnenment
	local manaScaling=Game.Classes.SPFactor[pl.Class]
	local manaType=Game.Classes.SPStats[pl.Class]
	local totalMana=manaScaling*pl.LevelBase+Game.Classes.SPBase[pl.Class]
	local effect=0
	if manaType==1 then
		local stat=pl:GetIntellect()
		if stat<=21 then
			effect=effect+math.floor((stat-13)/2)
		else
			effect=effect+math.floor(stat/5)
		end
	elseif manaType==2 then
		local stat=pl:GetPersonality()
		if stat<=21 then
			effect=effect+math.floor((stat-13)/2)
		else
			effect=effect+math.floor(stat/5)
		end
	elseif manaType==3 then
		local stat=pl:GetIntellect()
		if stat<=21 then
			effect=effect+math.floor((stat-13)/2)
		else
			effect=effect+math.floor(stat/5)
		end
		local stat=pl:GetPersonality()
		if stat<=21 then
			effect=effect+math.floor((stat-13)/2)
		else
			effect=effect+math.floor(stat/5)
		end
	end
	local s2,m2=SplitSkill(pl:GetSkill(const.Skills.Meditation))
	if m2==4 then
		m2=5
	end
	effect=effect+s2*m2
	totalMana=totalMana+manaScaling*effect+tab[9]
	
	local s,m=SplitSkill(Skillz.get(pl,52))
	if s>20 then
		s=s+(s-20)*2
	end
	local enlightIncrease=totalMana*((m+1)/100*s)
	tab[9]=tab[9]+enlightIncrease+manaScaling*s2*m2
	
	for i=0,3 do 
		local item=pl:GetActiveItem(i)
		if item then
			local skill=item:T().Skill
			--minotaur fix
			if i==1 or i==0 then
				if table.find(oneHandedAxes, item.Number) or table.find(twoHandedAxes, item.Number) then
					if i==0 then
						skill=2
					else
						skill=3
					end
				end				
			end
			local s,m = SplitSkill(pl:GetSkill(skill))
			
			if skillAC[skill] and skillAC[skill][m] then
				tab[10]=tab[10]+skillAC[skill][m]*s
			end
			if skillResistance[skill] and skillResistance[skill][m] and skill~=0 then --staff exception
				for v=11,16 do
					tab[v]=tab[v]+skillResistance[skill][m]*s
				end
			end
			if skillAttack[skill] and skillAttack[skill][m] then
				if i~=2 then
					tab[40]=tab[40]+skillAttack[skill][m]*s
				else
					tab[44]=tab[44]+skillAttack[skill][m]*s
				end
			end
			if i==2 and m==4 then --remove vanilla calculation
				tab[46]=tab[46]-s
				tab[47]=tab[47]-s
			end
		end
		local s,m = SplitSkill(pl:GetSkill(const.Skills.Dodging)) 
		if (i==3 and item==nil and m>=1) or (m>=3 and item and item:T().Skill==9) then
			tab[10]=tab[10]+skillAC[const.Skills.Dodging][m]*s
		end
	end
	
	--staff party buff
	local staffResistance=0
	for i=0, Party.High do
		local item=Party[i]:GetActiveItem(1)
		if item then
			local skill=item:T().Skill
			if skill==0 then
				local s,m=SplitSkill(Party[i]:GetSkill(const.Skills.Staff))
				staffResistance=staffResistance+skillResistance[skill][m]*s
			end
		end
	end
	for v=11,16 do
		tab[v]=tab[v]+staffResistance
	end
	--armsmaster attack
	local s,m = SplitSkill(pl:GetSkill(const.Skills.Armsmaster))
	if m>0 then
		tab[40]=tab[40]+armsmasterAttack[m]*s
	end
	--unarmed
	local s,m = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
	local s1,m1 = SplitSkill(pl:GetSkill(const.Skills.Staff))
	local unarmed=false
	if (m>=1 and not pl:GetActiveItem(0) and not pl:GetActiveItem(1)) or (m1==4 and pl:GetActiveItem(1) and pl:GetActiveItem(1):T().Skill==0 ) then
		if m>0 then
			tab[40]=tab[40]+skillAttack[const.Skills.Unarmed][m]*s
			tab[41]=tab[41]+skillDamage[const.Skills.Unarmed][m]*s
			tab[42]=tab[42]+skillDamage[const.Skills.Unarmed][m]*s
			tab[43]=tab[43]+skillDamage[const.Skills.Unarmed][m]*s
			unarmed=true
		end
	end
	local buff=pl.SpellBuffs[6]
	if buff.ExpireTime>Game.Time and not buffRework then --hammerhand buff
		tab[41]=tab[41]+buff.Power
		tab[42]=tab[42]+buff.Power
		tab[43]=tab[43]+buff.Power
	end
	--necessary to load attack speed and damage multiplier
	pl:GetAttackDelay()
	pl:GetAttackDelay(true)
	--add might and speed multiplier
	local might=tab[1]+pl.MightBase+pl.MightBonus+Party.SpellBuffs[2].Power
	if might<=21 then
		mightEffect=(might-13)/2
	else
		mightEffect=math.floor(might/5)
	end
	local bonusDamage=mightEffect+Party.SpellBuffs[const.PartyBuff.Heroism].Power
	local heroismMult=0
	local unarmedMult=0
	if buffRework then 
		bonusDamage=mightEffect
		if Party.SpellBuffs[9].ExpireTime>=Game.Time then
			local s,m=getBuffSkill(51)
			heroismMult=(buffPower[51].Base[m]/100+buffPower[51].Scaling[m]*s/1000)
		end
		if pl.SpellBuffs[6].ExpireTime>=Game.Time then
			local s,m=getBuffSkill(73)
			unarmedMult=(buffPower[73].Base[m]/100+buffPower[73].Scaling[m]*s/1000)
		end
	end
	local shamanSpiritMult=0
	if table.find(shamanClass, pl.Class) then
		local s=SplitSkill(pl.Skills[const.Skills.Spirit])
		shamanSpiritMult=s/100
	end
	tab[42]=tab[42]+(tab[42]+bonusDamage)*might/1000
	tab[42]=tab[42]+(tab[42]+bonusDamage)*heroismMult 
	tab[42]=tab[42]+(tab[42]+bonusDamage)*unarmedMult
	tab[42]=tab[42]+(tab[42]+bonusDamage)*shamanSpiritMult
	
	tab[43]=tab[43]+(tab[43]+bonusDamage)*might/1000
	tab[43]=tab[43]+(tab[43]+bonusDamage)*heroismMult 
	tab[43]=tab[43]+(tab[43]+bonusDamage)*unarmedMult
	tab[43]=tab[43]+(tab[43]+bonusDamage)*shamanSpiritMult
	
	tab[46]=tab[46]+(tab[46]+bonusDamage)*might/1000
	tab[47]=tab[47]+(tab[47]+bonusDamage)*might/1000
	return tab
end

armsmasterAttack={[0]=0,0,1,2,2}
armsmasterDamage={[0]=0,1,2,3,4}

equipSpellMap={
	[30] = const.Skills.Fire,
	[26] = const.Skills.Air,
	[34] = const.Skills.Water,
	[29] = const.Skills.Earth,
	[33] = const.Skills.Spirit,
	[32] = const.Skills.Mind,
	[27] = const.Skills.Body,
	[31] = const.Skills.Light,
	[28] = const.Skills.Dark,
}

statMap={
	[const.Stats.FireMagic]=30,
	[const.Stats.AirMagic]=26,
	[const.Stats.WaterMagic]=34,
	[const.Stats.EarthMagic]=29,
	[const.Stats.SpiritMagic]=33,
	[const.Stats.MindMagic]=32,
	[const.Stats.BodyMagic]=27,
	[const.Stats.LightMagic]=31,
	[const.Stats.DarkMagic]=28,
	[const.Stats.MeleeAttack]=40,
	[const.Stats.MeleeDamageBase]=41,
	[const.Stats.MeleeDamageMin]=42,
	[const.Stats.MeleeDamageMax]=43,
	[const.Stats.RangedAttack]=44,
	[const.Stats.RangedDamageBase]=45,
	[const.Stats.RangedDamageMin]=46,
	[const.Stats.RangedDamageMax]=47,
	
}

--artifacts stats bonus
--------------------------------
---- Stat bonuses
artifactStatsBonus={}
artifactStatsBonus[500] = {	[const.Stats.Accuracy] = 60}
artifactStatsBonus[501] = {	[const.Stats.Might] = 60}
artifactStatsBonus[502] = {	[const.Stats.AirResistance] = 100}
artifactStatsBonus[503] = {	[const.Stats.Endurance] = 40,
							[const.Stats.Luck] = 40}
artifactStatsBonus[504] = {	[const.Stats.Might] = 100}
artifactStatsBonus[505] = {	[const.Stats.FireResistance] = 100}
artifactStatsBonus[506] = {	[const.Stats.Endurance] = 60}
artifactStatsBonus[507] = {[const.Stats.Might] 		= 20,
							[const.Stats.Intellect] 	= 20,
							[const.Stats.Personality] 	= 20,
							[const.Stats.Speed] 		= 20,
							[const.Stats.Accuracy]		= 20,
							[const.Stats.Endurance] 	= 20,
							[const.Stats.Luck]			= 20}
artifactStatsBonus[509] = {	[const.Stats.Personality]   = 80}
artifactStatsBonus[510] = { [const.Stats.Might] 		= 30,
							[const.Stats.Endurance] 	= 30}		
artifactStatsBonus[512] = { [const.Stats.Accuracy] 		= 50}						
artifactStatsBonus[513] = { [const.Stats.Endurance] 	= 70}						
artifactStatsBonus[514] = { [const.Stats.Might] 		= 20,
							[const.Stats.Intellect] 	= 20,
							[const.Stats.Personality] 	= 20,
							[const.Stats.Speed] 		= 20,
							[const.Stats.Accuracy]		= 20,
							[const.Stats.Endurance] 	= 20,
							[const.Stats.Luck]			= 20,
							[const.Stats.FireResistance]	= 20,
							[const.Stats.AirResistance]		= 20,
							[const.Stats.WaterResistance]	= 20,
							[const.Stats.EarthResistance]	= 20,
							[const.Stats.MindResistance]	= 20,
							[const.Stats.BodyResistance]	= 20,}	
artifactStatsBonus[515] = { [const.Stats.Speed] 		= 60,							
							[const.Stats.Accuracy] 		= 60}
artifactStatsBonus[518] = { [const.Stats.Speed] 		= 60}
artifactStatsBonus[519] = { [const.Stats.FireResistance]	= 40,
							[const.Stats.AirResistance]		= 40,
							[const.Stats.WaterResistance]	= 40,
							[const.Stats.EarthResistance]	= 40}
artifactStatsBonus[520] = { [const.Stats.Personality]	= 60,
							[const.Stats.Intellect]		= 60}	
artifactStatsBonus[521] = {	[const.Stats.Intellect] = 100}							
artifactStatsBonus[522] = { [const.Stats.Intellect]	= 40,
							[const.Stats.FireResistance]	= 10,
							[const.Stats.AirResistance]		= 10,
							[const.Stats.WaterResistance]	= 10,
							[const.Stats.EarthResistance]	= 10,
							[const.Stats.MindResistance]	= 10,
							[const.Stats.BodyResistance]	= 10}
artifactStatsBonus[523] = { [const.Stats.Speed]	= 100,
							[const.Stats.WaterResistance]	= -50,
							[const.Stats.Personality]	= -15}
artifactStatsBonus[524] = {	[const.Stats.Speed]	= 70,
							[const.Stats.Accuracy]	= 70,
							[const.Stats.ArmorClass]	= -20}						
artifactStatsBonus[525] = {	
							[const.Stats.Accuracy]	= 120,		
							[const.Stats.Speed]	= -20}		
artifactStatsBonus[526] = {	[const.Stats.Might]	= 70,
							[const.Stats.Accuracy]		= 70,
							[const.Stats.Personality]	= 50,
							[const.Stats.Intellect]	= 50}		
artifactStatsBonus[527] = {	[const.Stats.Might]	= 80,
							[const.Stats.Luck]	= -40}
artifactStatsBonus[528]	= {	[const.Stats.WaterResistance]	= 140,
							[const.Stats.FireResistance]	= -40}		
artifactStatsBonus[529]	= {	[const.Stats.Might]	= 100,
							[const.Stats.Accuracy]	= 100}		
artifactStatsBonus[530]	= {	[const.Stats.ArmorClass]	= -40}		
artifactStatsBonus[531]	= {	[const.Stats.Accuracy]	= 100,
							[const.Stats.ArmorClass]	= -20}		
artifactStatsBonus[532]	= {	[const.Stats.Might]	= 60,
							[const.Stats.Speed]	= 60,}		
artifactStatsBonus[533]	= {	[const.Stats.Intellect]	= 140,
							[const.Stats.Personality] = 140,
							[const.Stats.MindResistance]	= -100,
							[const.Stats.BodyResistance]	= -100}		
artifactStatsBonus[534]	= {	[const.Stats.Luck]	= -15,
							[const.Stats.Endurance]	= 50}
artifactStatsBonus[535]	= {	[const.Stats.Intellect]	= 60,
							[const.Stats.Endurance]	= -20}			
artifactStatsBonus[536]	= {	[const.Stats.Luck]	= 100,
							[const.Stats.Personality]	= -50}		
artifactStatsBonus[537]	= {	[const.Stats.Might]	= 120,
							[const.Stats.Accuracy]	= -30,
							[const.Stats.ArmorClass]	= -15}							
							


-- Cycle of life
artifactStatsBonus[543] = {	[const.Stats.Endurance] = 20}


-- Puck
artifactStatsBonus[1302] = {[const.Stats.Speed]	= 80}
-- Iron Feather
artifactStatsBonus[1303] = {[const.Stats.Might]	= 80}
-- Wallace
artifactStatsBonus[1304] = {[const.Stats.Personality] = 40}
-- Corsair
artifactStatsBonus[1305] = {[const.Stats.Luck] = 80}
-- Governor's Armor
artifactStatsBonus[1306] = {[const.Stats.Might] 		= 20,
							[const.Stats.Intellect] 	= 20,
							[const.Stats.Personality] 	= 20,
							[const.Stats.Speed] 		= 20,
							[const.Stats.Accuracy]		= 20,
							[const.Stats.Endurance] 	= 20,
							[const.Stats.Luck]			= 20}
-- Yoruba
artifactStatsBonus[1307] = {[const.Stats.Endurance] 	= 100}
-- Splitter
artifactStatsBonus[1308] = {[const.Stats.FireResistance] = 65000}
-- Ullyses
artifactStatsBonus[1312] = {[const.Stats.Accuracy] = 80}
-- Seven League Boots
artifactStatsBonus[1314] = {[const.Stats.Speed] = 80}
-- Mash
artifactStatsBonus[1316] = {[const.Stats.Might] 		= 150,
							[const.Stats.Intellect] 	= -40,
							[const.Stats.Personality] 	= -40,
							[const.Stats.Speed] 		= -40}
-- Hareck's Leather
artifactStatsBonus[1318] = {[const.Stats.Luck]				= 100,
							[const.Stats.FireResistance] 	= -20,
							[const.Stats.AirResistance] 	= -20,
							[const.Stats.WaterResistance] 	= -20,
							[const.Stats.EarthResistance] 	= -20,
							[const.Stats.MindResistance] 	= -20,
							[const.Stats.BodyResistance] 	= -20,}
-- Amuck
artifactStatsBonus[1320] = {[const.Stats.Might] 		= 100,
							[const.Stats.Endurance] 	= 100,
							[const.Stats.ArmorClass] 	= -15}
-- Glory shield
artifactStatsBonus[1321] = {[const.Stats.BodyResistance] = -20,
							[const.Stats.MindResistance] = -20}
-- Kelebrim
artifactStatsBonus[1322] = {[const.Stats.Endurance] = 100,
							[const.Stats.EarthResistance] = -60}
-- Taledon's Helm
artifactStatsBonus[1323] = {
							[const.Stats.Might] = 45,
							[const.Stats.Personality] = 45,
							[const.Stats.Luck] = -40
}
-- Scholar's Cap
artifactStatsBonus[1324] = {[const.Stats.Endurance] = -50}
-- Phynaxian Crown
artifactStatsBonus[1325] = {
							[const.Stats.Personality] = 30,
							[const.Stats.ArmorClass] = -20,
							[const.Stats.WaterResistance] = 100
}
-- Titan's Belt
artifactStatsBonus[1326] = {
							[const.Stats.Might] = 115,
							[const.Stats.Speed] = -40
}
-- Twilight
artifactStatsBonus[1327] = {
							[const.Stats.Speed] = 50,
							[const.Stats.Luck] = 50,
							[const.Stats.FireResistance] = -30,
							[const.Stats.AirResistance] = -30,
							[const.Stats.WaterResistance] = -30,
							[const.Stats.EarthResistance] = -30,
							[const.Stats.MindResistance] = -30,
							[const.Stats.BodyResistance] = -30,
}
-- Ania Selving
artifactStatsBonus[1328] = {[const.Stats.ArmorClass] = -25,
							[const.Stats.Accuracy] = 150}
-- Justice
artifactStatsBonus[1329] = {[const.Stats.Speed] = -40}
-- Mekorig's hammer
artifactStatsBonus[1330] = {[const.Stats.Might] = 75,
							[const.Stats.AirResistance] = -100}
							-- Hermes's Sandals
artifactStatsBonus[1331] = {[const.Stats.Speed] = 100,
							[const.Stats.Accuracy] = 50,
							[const.Stats.AirResistance] = 100}
-- Cloak of the sheep
artifactStatsBonus[1332] = {[const.Stats.Intellect] 	= -20,
							[const.Stats.Personality] 	= -20}
-- Elfbane
artifactStatsBonus[1333] = {[const.Stats.Speed] = 100}
-- Mind's Eye
artifactStatsBonus[1334] = {
							[const.Stats.Intellect] = 30,
							[const.Stats.Personality] = 30
}
-- Elven Chainmail
artifactStatsBonus[1335] = {[const.Stats.Speed] = 30,
							[const.Stats.Accuracy] = 30
}
-- Forge Gauntlets
artifactStatsBonus[1336] = {
							[const.Stats.Might] = 30,
							[const.Stats.Endurance] = 30,
							[const.Stats.FireResistance] = 60
}
-- Hero's belt
artifactStatsBonus[1337] = {[const.Stats.Might] = 30}
-- Lady's Escort ring
artifactStatsBonus[1338] = {[const.Stats.FireResistance]	= 10,
							[const.Stats.AirResistance]		= 10,
							[const.Stats.WaterResistance]	= 10,
							[const.Stats.EarthResistance]	= 10,
							[const.Stats.MindResistance]	= 10,
							[const.Stats.BodyResistance]	= 10,}
-- Thor
artifactStatsBonus[2021] = {[const.Stats.Might] = 75}
-- Conan
artifactStatsBonus[2022] = {[const.Stats.Accuracy] = 150}
-- Excalibur
artifactStatsBonus[2023] = {[const.Stats.Might] = 100}
-- Merlin
artifactStatsBonus[2024] = {[const.Stats.Intellect] = 120,
							[const.Stats.Personality] = 120,
							[const.Stats.SP] = 200,
							}
-- Percival
artifactStatsBonus[2025] = {[const.Stats.Speed] = 40}
-- Galahad
artifactStatsBonus[2026] = {[const.Stats.Endurance] = 100}
-- Pellinore
artifactStatsBonus[2027] = {[const.Stats.Endurance] = 120}
-- Valeria
artifactStatsBonus[2028] = {[const.Stats.Accuracy] = 80}
-- Arthur
artifactStatsBonus[2029] = {
							[const.Stats.Might] = 20,
							[const.Stats.Intellect] = 20,
							[const.Stats.Personality] = 20,
							[const.Stats.Endurance] = 20,
							[const.Stats.Accuracy] = 20,
							[const.Stats.Speed] = 20,
							[const.Stats.Luck] = 20,
							[const.Stats.SP] = 100
}
-- Pendragon
artifactStatsBonus[2030] = {[const.Stats.Luck] = 60}
-- Lucius
artifactStatsBonus[2031] = {[const.Stats.Speed] = 70}
-- Guinevere
artifactStatsBonus[2032] = {[const.Stats.SP] = 100}
-- Igraine
artifactStatsBonus[2033] = {[const.Stats.SP] = 100}
-- Morgan
artifactStatsBonus[2034] = {[const.Stats.SP] = 80}
-- Hades
artifactStatsBonus[2035] = {[const.Stats.Luck] = 60}
-- Ares
artifactStatsBonus[2036] = {[const.Stats.FireResistance] = 100}
-- Poseidon
artifactStatsBonus[2037] = {[const.Stats.Might] 	 = 40,
							[const.Stats.Endurance]  = 40,
							[const.Stats.Accuracy] 	 = 40,
							[const.Stats.Speed] 	 = -10,
							[const.Stats.ArmorClass] = -10}
-- Cronos
artifactStatsBonus[2038] = {[const.Stats.Luck] 	 	= -60,
							[const.Stats.Endurance] = 120}
-- Hercules
artifactStatsBonus[2039] = {[const.Stats.Might] 	= 100,
							[const.Stats.Endurance] = 60,
							[const.Stats.Intellect]	= -30}
-- Artemis
artifactStatsBonus[2040] = {[const.Stats.FireResistance] 	= -20,
							[const.Stats.AirResistance] 	= -20,
							[const.Stats.WaterResistance] 	= -20,
							[const.Stats.EarthResistance] 	= -20}
-- Apollo
artifactStatsBonus[2041] = {[const.Stats.Endurance]			= -30,
							[const.Stats.FireResistance] 	= 40,
							[const.Stats.AirResistance] 	= 40,
							[const.Stats.WaterResistance] 	= 40,
							[const.Stats.EarthResistance] 	= 40,
							[const.Stats.MindResistance] 	= 40,
							[const.Stats.BodyResistance] 	= 40,
							[const.Stats.Luck]				= 20}
-- Zeus
artifactStatsBonus[2042] = {[const.Stats.Endurance] 		= 50,
							[const.Stats.Personality] 		= 50,
							[const.Stats.Luck] 		= 50,
							[const.Stats.Intellect] = -50}
-- Aegis
artifactStatsBonus[2043] = {[const.Stats.Speed] = -20,
							[const.Stats.Luck] 	= 100}
-- Odin
artifactStatsBonus[2044] = {
							[const.Stats.Speed] = -40,
							[const.Stats.FireResistance] = 60,
							[const.Stats.AirResistance] = 60,
							[const.Stats.WaterResistance] = 60,
							[const.Stats.EarthResistance] = 60
						}
-- Atlas
artifactStatsBonus[2045] = {
							[const.Stats.Might] = 120,
							[const.Stats.Speed] = -40
						}
-- Hermes
artifactStatsBonus[2046] = {
							[const.Stats.Speed] = 140,
							[const.Stats.Accuracy] = -40
						}
-- Aphrodite
artifactStatsBonus[2047] = {[const.Stats.Personality] = 100,
							[const.Stats.Luck] 	= -40}
-- Athena
artifactStatsBonus[2048] = {[const.Stats.Intellect] = 100,
							[const.Stats.Might] 	= -40}
-- Hera
artifactStatsBonus[2049] = {[const.Stats.HP] = 100,
							[const.Stats.SP] = 100,
							[const.Stats.Luck] = 50,
							[const.Stats.Personality] = -50}

--SKILLS ARTEFACTS
---- Skill bonuses
artifactSkillBonus={}
artifactSkillBonus[502] =	{	[const.Skills.Armsmaster] = 7}
artifactSkillBonus[512] =	{	[const.Skills.Bow] = 4}
artifactSkillBonus[517] =	{	[const.Skills.DisarmTraps] = 8,
								[const.Skills.Bow] = 8,
								[const.Skills.Armsmaster] = 8}
artifactSkillBonus[531] =	{	[const.Skills.Bow] = 4}
artifactSkillBonus[535] =	{	[const.Skills.Alchemy] = 5}
-- Hero's belt
artifactSkillBonus[1337] =	{	[const.Skills.Armsmaster] = 5}
-- Wallace
artifactSkillBonus[1304] =	{	[const.Skills.Armsmaster] = 10}
-- Corsair
artifactSkillBonus[1305] =	{	[const.Skills.DisarmTraps] = 10}
-- Hands of the Master
artifactSkillBonus[1313] =	{	[const.Skills.Unarmed] = 10,
								[const.Skills.Dodging] = 10}
-- Ethric's Staff
artifactSkillBonus[1317] =	{	[const.Skills.Meditation] = 8}
-- Hareck's Leather
artifactSkillBonus[1318] =	{	[const.Skills.DisarmTraps] = 5,
								[const.Skills.Unarmed] = 5,}
-- Old Nick
artifactSkillBonus[1319] =	{	[const.Skills.DisarmTraps] = 5}
-- Glory shield
artifactSkillBonus[1321] =	{	[const.Skills.Shield] = 5}
-- Scholar's Cap
artifactSkillBonus[1324] = {	[const.Skills.Learning] = 15}
-- Ania Selving
artifactSkillBonus[1328] =	{	[const.Skills.Bow] = 5}
-- Pendragon
artifactSkillBonus[2030] =	{	[const.Skills.Stealing] = 10,
								[const.Skills.DisarmTraps] = 10}
-- Hades
artifactSkillBonus[2035] =	{	[const.Skills.DisarmTraps] = 10}

--refresh stats
function events.AfterLoadMap()
	mawRefresh("all")
end
function events.Action(t)
	--if t.Action==110 or t.Action==115 or t.Action==133 then
		if Game.CurrentPlayer==-1 or Game.CurrentPlayer>Party.High then return end
		local id=Party[Game.CurrentPlayer]:GetIndex()
		function events.Tick() 
			events.Remove("Tick", 1)
			mawRefresh(id)
			mawRefresh(id) --fixes some skill not being accounted on the first go this could be optimized, but it doesn't affects performance
		end
	--end
end
function events.CalcDamageToPlayer(t)
	function events.Tick() 
		events.Remove("Tick", 1)
		mawRefresh(t.PlayerIndex)
	end
end
function mawRefresh(i)
	if i=="all" then
		for v=0,Party.High do
			local id=Party[v]:GetIndex()
			plItemsStats[id]=itemStats(id)
		end
		return
	end
	plItemsStats[i]=itemStats(i)
end

local stats={"Might", "Intellect", "Personality", "Endurance", "Accuracy", "Speed", "LUCK", "HP", "SP", "ArmorClass", "Fire", "Air", "Water", "Earth", "Mind", "Body"}
function mawPlayerBaseStats(index)
	local pl=Party[index]
	local tab=plItemsStats[index]
	--set all to 0
	for i=1,7 do
		tab[i]=pl[stats[i] .. "Base"] + pl[stats[i]  .. "Bonus"]
	end
	for i=8,9 do
		tab[i]=0
	end
	tab[10]=pl[ArmorClassBonus]
	for i=11,16 do
		tab[i]=pl[stats[i] .. "ResistanceBase"] + pl[stats[i]  .. "ResistanceBonus"]
	end
end


--randomize item shop

function events.KeyDown(t)
	--base numbers
	if t.Key==82 then
		refreshItems()
	end	
end

shopArmors={31,32,33,34,5}
function refreshItems()
	id=Game:GetCurrentHouse()
	if id==nil or id>=110 then return end
	if Game.HouseScreen==2 then
		h=Game.ShopItems[id]
	elseif Game.HouseScreen==95 then
		h=Game.ShopSpecialItems[id]
	else 
		return
	end
	
	currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
	if currentWorld==1 then
		currentLevel=vars.MM8LVL
	elseif currentWorld==2 then
		currentLevel=vars.MM7LVL
	elseif currentWorld==3 then
		currentLevel=vars.MM6LVL
	elseif currentWorld==4 then
		currentLevel=vars.MMMLVL
	end
	partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL-math.min(currentLevel/2, 54)
	--cap
	difficultyExtraPower=math.max((Game.BolsterAmount-100)/2000+1,1)
	cap2=14+ math.floor((difficultyExtraPower-1)*10)

	--calculate power
	strength=math.floor(currentLevel/18)+2
	strength=math.min(strength,5)
	partyLevel1=math.min(math.floor(partyLevel/18),cap2)
	cost=(partyLevel1+strength)^2*250
	if cost>Party.Gold then
		return
	else
		Party.Gold=Party.Gold-cost
	end
	--check for shop
	if not vars.shopType[id] then
		mawStoreShop()
	end
	
	for i=0,11 do
		if math.random(1,18)<currentLevel%18 then
			strength=math.min(strength+1,5)
		end
		if h[i].Number~=0 then
			itemType= h[i]:T().EquipStat
			if itemType==3 or itemType==4 then
				it=math.random(1,#shopArmors)
				h[i]:Randomize(strength, shopArmors[it])
			else
				rnd=math.random(1,#vars.shopType[id])
				h[i]:Randomize(strength, vars.shopType[id][rnd])
			end
			h[i].Identified = true
			Game.GuildItemIconPtr[i] = Game.IconsLod:LoadBitmapPtr(h[i]:T().Picture)
		end
	end
end

--get house info and fix broken prices
function events.ShopItemsGenerated(t)
	mawStoreShop()
end

--attempt to fix price overflow, apparently due to gm merchant
function events.GetMerchantTotalSkill(t)
	if merchantFix then
		t.Result=100
	end
end


function mawStoreShop()

	--broken price fix
	id=Game:GetCurrentHouse()
	merchantFix=false
	for i=0,Party.High do
		s,m=SplitSkill(Party[i].Skills[const.Skills.Merchant])
		if s>15 or m==4 then
			Game.Houses[id].Val=1
			merchantFix=true
		end
	end
	if Game.HouseScreen==2 or Game.HouseScreen==95 then
		Game.ShowStatusText("Press R to refresh new items (20000 gold)") --not working
	else 
		return
	end
	if id>133 then return end
	--check item types to determine what shop is this
	h=Game.ShopSpecialItems[id]
	s=Game.ShopItems[id]
	vars.shopType={}
	vars.shopType[id]={}
	for i=0,11 do
		itemType=h[i]:T().EquipStat
		if h[i].Number>0 and itemType~=3 and itemType~=4 and itemType~=19 then
			itemType=h[i]:T().EquipStat+1
			if not table.find(vars.shopType[id],itemType) then
				table.insert(vars.shopType[id],itemType)
			end
		end
		itemType=s[i]:T().EquipStat
		if s[i].Number>0 and itemType~=3 and itemType~=4 and itemType~=19 then
			itemType=s[i]:T().EquipStat+1
			if not table.find(vars.shopType[id],itemType) then
				table.insert(vars.shopType[id],itemType)
			end
		end
	end
end

--maw artifact scaling calculation
function artifactPowerMult(level, isAC)
	local bol=math.max(Game.BolsterAmount, 100)
	bol=(bol/100-1)/20+1
	local mult=math.min(level/100+0.5,3)*bol
	if isAC then
		mult=math.min(level/(250/1.5)+0.5,3)*bol
	end
	return mult
end

playerToPartyBuff={
	[0]=0,
	[2]=1,
	[3]=4,
	[5]=6,
	[8]=9,
	[9]=12,
	[14]=15,
	[15]=2,
	[16]=2,
	[17]=2,
	[18]=2,
	[19]=2,
	[20]=2,
	[21]=2,
	[22]=17,
}
statToPlayerbuff={
	[10]=0,
	[15]=2,
	[13]=3,
	[11]=5,
	[27]=8,
	[28]=8,
	[14]=9,
	[9]=14,
	[4]=15,
	[3]=16,
	[1]=17,
	[6]=18,
	[0]=19,
	[2]=20,
	[5]=21,
	[12]=22,
}

--
function events.CalcStatBonusByItems(t)
	if statToPlayerbuff[t.Stat] then
		local stat1=statToPlayerbuff[t.Stat]
		if t.Player.SpellBuffs[stat1].Skill==5 then
			return 
		end
		local power1=t.Player.SpellBuffs[stat1].Power
		local stat2=playerToPartyBuff[stat1]
		local power2=Party.SpellBuffs[stat2].Power
		if power1>=power2 then
			t.Player.SpellBuffs[stat1].Power=t.Player.SpellBuffs[stat1].Power-power2
			t.Player.SpellBuffs[stat1].Skill=5
		else
			t.Player.SpellBuffs[stat1].Power=0
		end
	end
end

function getBaseAttackSpeed(it)
	local skill=it:T().Skill
	if table.find(twoHandedAxes, it.Number) or table.find(oneHandedAxes, it.Number) then
		skill=3
	end
	if baseRecovery[skill] then
		local itemLevel=it.MaxCharges*5
		local tot=0
		local lvl=0
		for i=1, 6 do
			tot=tot+it:T().ChanceByLevel[i]
			lvl=lvl+it:T().ChanceByLevel[i]*i
		end
		itemLevel=itemLevel+math.round(lvl/tot*18-17)
		baseSpeed=baseRecovery[skill] * (0.75+itemLevel/200)
		baseSpeed=math.round(baseSpeed/10)/10
		return baseSpeed
	end
	return 1
end

--items have an item level requirement
function events.CanWearItem(t)
	it=Mouse.Item
	if vars.Mode==2 and not it.Identified then
		t.Available=false
	end
	if it.Number<=151 or (it.Number>=803 and it.Number<=936) or (it.Number>=1603 and it.Number<=1736) then 
		local itemLevel=it.MaxCharges*5
		local tot=0
		local lvl=0
		for i=1, 6 do
			tot=tot+it:T().ChanceByLevel[i]
			lvl=lvl+it:T().ChanceByLevel[i]*i
		end
		itemLevel=itemLevel+math.round(lvl/tot*18-17)
		local maxCharges=it.MaxCharges
		if it.BonusExpireTime>0 and it.BonusExpireTime<=2 then
			maxCharges=math.floor(math.min(maxCharges/1.2,maxCharges-5))
		end
		if it.BonusExpireTime>10 and it.BonusExpireTime<=100 then
			maxCharges=math.floor(math.min(maxCharges/1.2,maxCharges-5))
		end
		local levelRequired=(maxCharges)*3+lvl/tot*2-12
		if Game.BolsterAmount>=300 then
			levelRequired=levelRequired-6
		end
		if vars.Mode==2 then
			levelRequired=levelRequired-3
		end
		local enchants=3
		if it.Bonus>0 then
			enchants=enchants+1
		end
		if it.Bonus2>0 then
			enchants=enchants+1
		end
		if it.Charges>1000 then
			enchants=enchants+1
		end
		levelRequired=levelRequired*enchants/6
		levelRequired=math.max(1,math.floor(levelRequired))
		--check if equippable
		local plLvl=Party[t.PlayerId].LevelBase
		if plLvl<levelRequired then
			t.Available=false
		end
	end	
end

--chests blocked if trapped
function events.CanOpenChest(t)
	if vars.Mode==2 then
		if Map.Chests[t.ChestId].Trapped then return end
		local skillRequired=Game.MapStats[Map.MapStatsIndex].Lock
		if skillRequired>=4 then 
			skillRequired=skillRequired*2
		end
		t.CanOpen=false
		for i=0,Party.High do
			local s, m = SplitSkill(Party[i]:GetSkill(const.Skills.DisarmTraps))
			local skill=s*m
			if m==4 or skill>=skillRequired then
				t.CanOpen=true
			end
		end
		if not t.CanOpen then
			local id=Game.CurrentPlayer
			if id<0 or id>Party.High then
				id=0
			end
			evt.FaceAnimation(id,const.FaceAnimation.DoorLocked)
			Game.ShowStatusText("Not enough disarm skill")
		end
	end
end

--[[remove repair/identify from shops
function events.GetShopItemTreatment(t)
	if vars.Mode==2 then
		if t.Action=="identify" or t.Action=="repair" then
			t.Result=0
		end
	end
end
function events.CanShopOperateOnItem(t)
	if vars.Mode==2 then
		if t.Action=="identify" or t.Action=="repair" then
			t.Result=false
		end
	end
end
]]
--increase prices
local houseValues={}
function events.GetShopItemTreatment(t)
	local id=GetCurrentHouse()
	Game.Houses[id].Val=houseValues[id] or Game.Houses[id].Val
	if vars.Mode==2 then
		if t.Action=="identify" or t.Action=="repair" then
			houseValues[id]=houseValues[id] or Game.Houses[id].Val
			if t.Action=="identify" then
				Game.Houses[id].Val=t.Item:T().IdRepSt^2
			else
				Game.Houses[id].Val=5
			end
		end
	end
end

--convert gems, from lower to highest
--NAMES
local craftingNames={"Moonstone", "Topaz", "Amethyst", "Amber", "Purple Topaz", "Ruby", "Sunstone", "Emerald", "Sapphire", "Diamond"}
function events.KeyDown(t)
	if t.Key ~=85 then
		gemUpgrading=false
	end
    if Game.CurrentScreen == 7 and Game.CurrentCharScreen == 103 then
		if t.Key ==85 and gemUpgrading then
			gemUpgrading=false
			for i=1,9 do
				local id=1050+i
				if evt.CheckItemsCount{MinItemIndex = id, MaxItemIndex = id, Count = 3} then
					evt.Subtract("Items",id)
					evt.Subtract("Items",id)
					evt.Subtract("Items",id)
					evt.Add("Items",id+1)
					Game.ShowStatusText(string.format("%s created", craftingNames[i+1]))
					return
				end
			end
			Game.ShowStatusText("No gem to upgrade")
			return
		end
		
        if t.Key == 85 then -- "u" key
            gemUpgrading=true
            for i=1,9 do
				local id=1050+i
				if evt.CheckItemsCount{MinItemIndex = id, MaxItemIndex = id, Count = 3} then
					Game.ShowStatusText(string.format("Convert %s into %s? (U)",craftingNames[i], craftingNames[i+1]))
					return
				end
			end
			Game.ShowStatusText("No gem to upgrade")
			return
        end
    end
end

function events.Tick()
	Mouse.Item.MaxCharges=math.min(Mouse.Item.MaxCharges, 100)
end
