function events.GenerateItem(t)
	--get party average level
	Handled = true
	--calculate party experience
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
encStrDown={1,1,3,6,10,15,20,24,28,32,36,40,44,48,52,56,60,64,68,76,84,92,105,120}
encStrUp={3,5,8,12,17,25,30,35,40,45,50,55,60,65,70,75,80,85,90,100,110,120,135,150}


enc1Chance={20,30,40,50,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84}
enc2Chance={20,30,35,40,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64}
spcEncChance={0,0,15,20,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44}

primordialWeapEnchants={41,46}
primordialArmorEnchants={1,2,80}

function events.ItemGenerated(t)
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
			roll=math.random(1,1000)/math.min(((Party.Gold+1)/500000),10)
			if roll<=2 then
				t.Item.Number=1064
				return
			elseif roll<=5 then
				t.Item.Number=1061
				return
			elseif roll<=10 then
				t.Item.Number=1062
				return
			elseif roll<=30 then
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
		--modify reagents
		if reagentList[t.Item.Number] then
			t.Item.Bonus=math.round(partyLevel/3)
			return
		end
		
		partyLevel=math.min(vars.MM8LVL+vars.MM7LVL+vars.MM6LVL-math.min(currentLevel,72), partyLevel+36)
		if not Game.freeProgression then
			partyLevel=(vars.MM8LVL+vars.MM7LVL+vars.MM6LVL)*0.75
		end
		--difficulty settings
		difficultyExtraPower=1
		if Game.BolsterAmount==150 then
			difficultyExtraPower=1.025
		elseif Game.BolsterAmount==200 then
			difficultyExtraPower=1.05
		elseif Game.BolsterAmount==300 then
			difficultyExtraPower=1.1
		end
		local flatBonus=(difficultyExtraPower-1)*50
		if math.random()<flatBonus%1 then
			flatBonus=flatBonus+1
		end
		
		if (Game.HouseScreen==2 or Game.HouseScreen==95) and Game.freeProgression then --nerf shops if no exp in current world
			partyLevel=math.round(partyLevel*(math.min(partyLevel/160 + currentLevel/80,1)))
		end
		
		--ADD MAX CHARGES BASED ON PARTY LEVEL
		bonusCharges=(difficultyExtraPower-1)*20
		cap1=50*difficultyExtraPower+bonusCharges
		t.Item.MaxCharges=math.min(math.floor(partyLevel/5),cap1)
		--bolster boost
		t.Item.MaxCharges=math.max(t.Item.MaxCharges+bonusCharges+t.Item.MaxCharges*(difficultyExtraPower-1), t.Item.MaxCharges*difficultyExtraPower) 
		
		cap2=14+ math.floor((difficultyExtraPower-1)*10)
		partyLevel1=math.min(math.floor(partyLevel/18),cap2)
		--adjust loot Strength
		ps1=t.Strength

		pseudoStr=ps1+partyLevel1
		if bossLoot then
			pseudoStr=pseudoStr+2
		end
		if math.random(1,18)<partyLevel1%18 then
			pseudoStr=pseudoStr+1
		end
		if pseudoStr==1 then 
			return 
		end
		pseudoStr=math.min(pseudoStr,20) --CAP CURRENTLY AT 20
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
		diffMult=Game.BolsterAmount/100
		--calculate chances
		local p1=enc1Chance[pseudoStr]/100
		local p2=enc2Chance[pseudoStr]/100
		local p3=spcEncChance[pseudoStr]/100
		p1=math.min(p1+(1-p1)*(diffMult-1)/10, p1*diffMult)
		p2=math.min(p2+(1-p2)*(diffMult-1)/10, p2*diffMult)
		p3=math.min(p3+(1-p3)*(diffMult-1)/10, p3*diffMult)
		
		if p1>roll1 then
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.random(encStrDown[pseudoStr],encStrUp[pseudoStr])
			--bolster
			t.Item.BonusStrength=math.max(t.Item.BonusStrength*difficultyExtraPower, t.Item.BonusStrength+flatBonus)
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
			t.Item.Charges=math.max(t.Item.Charges*difficultyExtraPower, t.Item.Charges+flatBonus)
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
		ancientChance=(p1*p2*p3)/4
		if bossLoot then
			ancientChance=ancientChance*10
			bossLoot=false
		end
	
		ancientRoll=math.random()
		if ancientRoll<=ancientChance then
			ancient=true
			t.Item.Charges=math.random(math.round(encStrUp[pseudoStr]+1),math.round(encStrUp[pseudoStr]*1.25))
			t.Item.Charges=math.max(t.Item.Charges*difficultyExtraPower, t.Item.Charges+flatBonus) --bolster
			t.Item.Charges=t.Item.Charges+math.random(1,16)*1000
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.random(math.round(encStrUp[pseudoStr]+1),math.round(encStrUp[pseudoStr]*1.25))
			t.Item.BonusStrength=math.max(t.Item.BonusStrength*difficultyExtraPower, t.Item.BonusStrength+flatBonus) --bolster
			power=2
			chargesBonus=math.random(1,5)
			t.Item.MaxCharges=t.Item.MaxCharges+chargesBonus
			math.max(t.Item.MaxCharges*(chargesBonus/20)+chargesBonus, t.Item.MaxCharges*(1+chargesBonus))
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
		primordialChance=ancientChance/4
		--No primordials in shop
		if Game.HouseScreen==2 or Game.HouseScreen==95 then
			primordialChance=0
		end
		if primordial<=primordialChance then
			if ancient then
				t.Item.MaxCharges=t.Item.MaxCharges-chargesBonus
			end
			t.Item.BonusExpireTime=2
			t.Item.Charges=math.ceil(encStrUp[pseudoStr]*1.25)+math.random(1,16)*1000
			t.Item.Charges=math.max(t.Item.Charges*difficultyExtraPower, t.Item.Charges+flatBonus) --bolster
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.ceil(encStrUp[pseudoStr]*1.25)
			t.Item.BonusStrength=math.max(t.Item.BonusStrength*difficultyExtraPower, t.Item.BonusStrength+flatBonus) --bolster
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
		
		--buff to hp and mana items
		if t.Item.Bonus==8 or t.Item.Bonus==9 then
			t.Item.BonusStrength=t.Item.BonusStrength*(2+t.Item.BonusStrength/50)
		end
		if math.floor(t.Item.Charges/1000)==8 or math.floor(t.Item.Charges/1000)==9 then
			power=t.Item.Charges%1000
			power=power*(2+power/50) --cap is 999
			if power > 999 and t.Item.Bonus<17 then --swap base with charges
				t.ItemBonus, t.Item.BonusStrength, t.Item.Charges=math.floor(t.Item.Charges/1000), power, t.ItemBonus*1000+t.ItemBonusStrength
			else 
				t.Item.Charges=math.floor(t.Item.Charges/1000)*1000+power
			end
		end
		--nerf to AC and skills
		if t.Item.Bonus==10 then
			t.Item.BonusStrength=math.ceil(t.Item.BonusStrength/2)
		end
		if math.floor(t.Item.Charges/1000)==10 then
			t.Item.Charges=t.Item.Charges-math.floor(t.Item.Charges%1000/2)
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
		Game.GlobalTxt[212]=StrColor(0,100,255,"Spell Points")
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
			vars.poisonTime[i]=25
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
				vars.poisonTime[i]=25
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
					vars.poisonTime[i]=25
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
				else vars.poisonTime[i]=0
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
				if it.Bonus2 == 37 or it.Bonus2==44 or it.Bonus2==50 or it.Bonus2==54 then		
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
				if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 then		
					SPregen=math.max(SPregen+totSP*0.02,SPregen+1)
				end
			end
		SPregen=math.max(SPregen-1,0)
		pl.SP=math.min(pl.SP+math.round(SPregen),totSP)
		end 
	end
	Timer(restoreSPEnchant, const.Minute*5) 
end



--carnage fix
function events.CalcDamageToMonster(t)
    local data = WhoHitMonster()
	if data and data.Player and data.Object ~= nil then
		if data.Object.Item.Bonus2==3 or data.Object.Item.Number==2025 then
			t.Result=t.Result/2
		end
	end
end
function events.GameInitialized2()
	Game.SpcItemsTxt[2].BonusStat="Explosive Impact! (half damage)"
end

------------------------------------------
--TOOLTIPS--
------------------------------------------
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
						local bonusAC=ac2*(t.Item.MaxCharges/20)
						if t.Item.MaxCharges <= 20 then
							ac=ac3+math.round(bonusAC)
						else
							local bonusAC=(ac+ac2)*(t.Item.MaxCharges/20)
							ac=ac3+math.round(bonusAC)
						end		
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
					--attack/+damage
					if t.Item.MaxCharges <= 20 then
						local bonusATK=bonus2*(t.Item.MaxCharges/20)
						bonus=bonus+math.round(bonusATK)
					else
						local bonusATK=(bonus2+bonus)*(t.Item.MaxCharges/20)
						bonus=bonus+math.round(bonusATK)
					end
					--dicesides
					local sides=txt.Mod1DiceSides
					local sides2=Game.ItemsTxt[t.Item.Number+lookup].Mod1DiceSides
					if t.Item.MaxCharges <= 20 then
						local sidesBonus=sides2*(t.Item.MaxCharges/20)
						sides=sides+math.round(sidesBonus)
					else
						local sidesBonus=(sides2+sides)*(t.Item.MaxCharges/20)
						sides=sides+math.round(sidesBonus)
					end
					t.BasicStat= "Attack: +" .. bonus .. "  " .. "Damage: " ..  txt.Mod1DiceCount .. "d" .. sides .. "+" .. bonus
				end
			end
			
			
			--add code to build enchant list
			t.Enchantment=""
			if t.Item.Bonus>0 then
				t.Enchantment = itemStatName[t.Item.Bonus] .. " +" .. t.Item.BonusStrength
			end
			if t.Item.Charges>1000 then
				local bonus=math.floor(t.Item.Charges/1000)
				local strength=t.Item.Charges%1000
				t.Enchantment = itemStatName[bonus] .. " +" .. strength .. "\n" .. t.Enchantment
			elseif t.Item.Bonus~=0 and t.Item.BonusStrength~=0 and t.Item.Bonus2~=0 then
				if extraDescription then
					math.randomseed(t.Item.Number*10000+t.Item.MaxCharges*1000+t.Item.Bonus*100+t.Item.BonusStrength*10+t.Item.Charges)
					local charges=math.random(1,16)*1000+math.min(math.round(t.Item.BonusStrength*(1+0.25*math.random())),100)
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
			if t.Item.Bonus2>0 then	
				if (t.Item.MaxCharges>=0 and bonusEffects[t.Item.Bonus2]~= nil) or enchantList[t.Item.Bonus2] then
					text=checktext(t.Item.MaxCharges,t.Item.Bonus2)
				else
					text=Game.SpcItemsTxt[t.Item.Bonus2-1].BonusStat
				end
				t.Description = StrColor(255,255,153,text) .. "\n\n" .. t.Description
			elseif t.Item.Bonus>0 and t.Item.Charges>1000 and extraDescription then
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
					text=checktext(t.Item.MaxCharges,enchantNumber)
				else
					text=Game.SpcItemsTxt[enchantNumber-1].BonusStat
				end
				t.Description = StrColor(100,100,100,text) .. "\n\n" .. t.Description
				vars.extraShown=true
			elseif (t.Item.Bonus>0 and t.Item.Charges>1000) or (t.Item.Bonus>0 and t.Item.Bonus2>0) then
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
function checktext(MaxCharges,bonus2)
	if MaxCharges <= 20 then
		mult=1+MaxCharges/20
	else
		mult=2+2*(MaxCharges-20)/20
	end
	bonus2txt={
		[1] =  " +" .. math.floor(bonusEffects[1].statModifier * mult) .. " to all Resistances.",
		[2] = " +" .. math.floor(bonusEffects[2].statModifier * mult) .. " to all Seven Statistics.",
		[4] ="Adds " .. math.floor(6*mult) .. "-" .. math.floor(8*mult) .. " points of Cold damage. (Increases also all spell damage if equipped in main hand)",
		[5] ="Adds " .. math.floor(18*mult) .. "-" .. math.floor(24*mult) .. " points of Cold damage. (Increases also all spell damage if equipped in main hand)",
		[6] ="Adds " .. math.floor(36*mult) .. "-" .. math.floor(48*mult) .. " points of Cold damage. (Increases also all spell damage if equipped in main hand)",
		[7] ="Adds " .. math.floor(4*mult) .. "-" .. math.floor(10*mult) .. " points of Electrical damage. (Increases also all spell damage if equipped in main hand)",
		[8] ="Adds " .. math.floor(12*mult) .. "-" .. math.floor(30*mult) .. " points of Electrical damage. (Increases also all spell damage if equipped in main hand)",
		[9] ="Adds " .. math.floor(24*mult) .. "-" .. math.floor(60*mult) .. " points of Electrical damage. (Increases also all spell damage if equipped in main hand)",
		[10] ="Adds " .. math.floor(2*mult) .. "-" .. math.floor(12*mult) .. " points of Fire damage. (Increases also all spell damage if equipped in main hand)",
		[11] ="Adds " .. math.floor(6*mult) .. "-" .. math.floor(36*mult) .. " points of Fire damage. (Increases also all spell damage if equipped in main hand)",
		[12] ="Adds " .. math.floor(12*mult) .. "-" .. math.floor(72*mult) .. " points of Fire damage. (Increases also all spell damage if equipped in main hand)",
		[13] ="Adds " .. math.floor(12*mult) .. " points of Body damage. (Increases also all spell damage if equipped in main hand)",
		[14] ="Adds " .. math.floor(24*mult) .. " points of Body damage. (Increases also all spell damage if equipped in main hand)",
		[15] ="Adds " .. math.floor(48*mult) .. " points of Body damage. (Increases also all spell damage if equipped in main hand)",
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
		[42] = " +" .. math.floor(bonusEffects[42].statModifier * mult) .. " to Seven Stats, HP, SP, Armor, Resistances.",
		[43] = " +" .. math.floor(bonusEffects[43].statModifier * mult) .. " to Endurance, Armor, Hit points.",
		[44] = " +" .. math.floor(bonusEffects[44].statModifier * mult) .. " Hit points and Regenerate Hit points over time.",
		[45] = " +" .. math.floor(bonusEffects[45].statModifier * mult) .. " Speed and Accuracy.",
		[46] = "Adds " .. math.floor(40*mult) .. "-" .. math.floor(80*mult) .. " points of Fire damage and +" .. math.floor(bonusEffects[46].statModifier * mult).. " Might.",
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
		if MaxCharges <= 20 then
			mult=1+MaxCharges/20
		else
			mult=2+2*(MaxCharges-20)/20
		end
		
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
				t.Value=t.Value^(1+count*0.06)
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
}
--modify weapon enchant damage

--ENCHANTS HERE
--MELEE bonuses
enchantbonusdamage = {}
enchantbonusdamage[4] = 2
enchantbonusdamage[5] = 3
enchantbonusdamage[6] = 4
enchantbonusdamage[7] = 2
enchantbonusdamage[8] = 3
enchantbonusdamage[9] = 4
enchantbonusdamage[10] = 2
enchantbonusdamage[11] = 3
enchantbonusdamage[12] = 4
enchantbonusdamage[13] = 2
enchantbonusdamage[14] = 3
enchantbonusdamage[15] = 4
enchantbonusdamage[46] = 4

function events.ItemAdditionalDamage(t)
	--empower enchants
	if enchantbonusdamage[t.Item.Bonus2] then
		t.Result=t.Result*enchantbonusdamage[t.Item.Bonus2]
	end
	--scaling Bonus
	if t.Item.MaxCharges>0 then
		if t.Item.MaxCharges <= 20 then
				mult=1+t.Item.MaxCharges/20
		else
				mult=2+2*(t.Item.MaxCharges-20)/20
		end
		t.Result=t.Result*mult
	end	
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



function events.GameInitialized2()
	--add crafting material price
	for i=1,10 do
		Game.ItemsTxt[1050+i].Value=i*1000
	end
	Game.ItemsTxt[1061].Value=30000
	Game.ItemsTxt[1062].Value=20000
	Game.ItemsTxt[1063].Value=15000
	Game.ItemsTxt[1064].Value=100000
	
	for i=0,8 do
		for j=1,11 do
			Game.ItemsTxt[399+11*i+j].Value=modifiedBookValues[j-1]
		end
	end
	for i=1,22 do
		Game.ItemsTxt[476+i].Value=Game.ItemsTxt[476+i].Value*2
	end
	--single books cost increased
	Game.ItemsTxt[408].Value= 40000
	Game.ItemsTxt[420].Value= 40000
	Game.ItemsTxt[421].Value= 40000
	Game.ItemsTxt[430].Value= 20000
	Game.ItemsTxt[432].Value= 60000
	Game.ItemsTxt[454].Value= 60000
	Game.ItemsTxt[482].Value= 20000
	Game.ItemsTxt[484].Value= 40000
	Game.ItemsTxt[485].Value= 60000
	Game.ItemsTxt[498].Value= 100000
	
end

--------------------------------------
--ARTIFACTS REWORK
--------------------------------------
--Increase Base Stats of weapons (handled in line 210)
artWeap1h={500,501,502,503,504,506,507,508,509,510,512,523,524,526,527,528,529,538,539,542,1302,1303,1304,1305,1308,1310,1311,1312,1316,1319,1328,1329,1330,1333,1340,1342,1343,1344,1345,1353,1354,2020,2021,2023,2025,2035,2036,2037,2038,2040}
artWeap2h={505,511,525,526,530,540,541,1309,1320,1351,2022,2024,2039}
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
			local artifactMult=artifactPowerMult(Party[Game.CurrentPlayer].LevelBase)
			local txt=Game.ItemsTxt[t.Item.Number]
			local ac=math.ceil((txt.Mod2+txt.Mod1DiceCount)*artifactMult)
			if ac>0 then 			
				t.BasicStat= "Armor: +" .. ac
			end
			--WEAPONS
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
				baseSpeed=baseRecovery[skill] * (0.75+itemLevel/200)
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

function events.BuildItemInformationBox(t)
	partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
	maxItemBolster=(partyLevel)/5+20
end

--do the same if someone is trying to equip on a player
function events.Action(t)
	if t.Action==133 then
		partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
		maxItemBolster=(partyLevel)/5+20
		--failsafe
		if Mouse.Item and Mouse.Item.Charges==0 and Mouse.Item.Bonus==0 and Mouse.Item.MaxCharges>maxItemBolster then
			Mouse.Item.MaxCharges=0
		end
	end
end

--REVERTED AS HIGHER DIFFICULTY WILL LOWER THE DAMAGE!
--[[vampiric nerf
gotVamp={}
gotBowVamp={}
function events.ItemAdditionalDamage(t)
	vamp=false
	for i=0,1 do
		it=t.Player:GetActiveItem(0)
		if it then
			vamp=it.Bonus2==41 or it.Bonus2==16
		end
	end
	if t.Vampiric or vamp then
		t.Vampiric = false
		gotVamp[t.Player:GetIndex()]=true
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
		if t.DamageKind==4 then
			data=WhoHitMonster()
			
			if data and data.Player then
				--melee
				if gotVamp[data.Player:GetIndex()] and not data.Object then
					t.Player.HP=math.min(t.Player:GetFullHP(),t.Player.HP+t.Result*0.05)
				end
				--ranged
				if gotVamp[data.Player:GetIndex()] and data.Object and data.Object.Spell==133 then
					t.Player.HP=math.min(t.Player:GetFullHP(),t.Player.HP+t.Result*0.05)
				end
			end
			

		end 
	end
end
]]
			

--SHOW POWER/VITALITY CHANGE IN TOOLTIPS
slotMap={
	[0]=0,
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
	--maxcharges fix
	partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
	maxItemBolster=(partyLevel)/5+20
	--failsafe
	if t.Item and t.Item.Charges==0 and t.Item.Bonus==0 and t.Item.MaxCharges>maxItemBolster then
		t.Item.MaxCharges=0
	end
	if t.Description then
		if Game.CurrentPlayer==-1 then return end
		if t.Item.Number<=151 or (t.Item.Number>=803 and t.Item.Number<=936) or (t.Item.Number>=1603 and t.Item.Number<=1736) then 
			local i=Game.CurrentPlayer
			--get spell and its damage
			local spellIndex=Party[i].QuickSpell
			local pl=Party[i]
			--if not an offensive spell then calculate highest between melee and ranged
			if not spellPowers[spellIndex] then 
				--MELEE
				low=pl:GetMeleeDamageMin()
				high=pl:GetMeleeDamageMax()
				might=pl:GetMight()
				accuracy=pl:GetAccuracy()
				luck=pl:GetLuck()
				delay=math.max(pl:GetAttackDelay())
				dmg=(low+high)/2
				--hit chance
				atk=pl:GetMeleeAttack()
				lvl=pl.LevelBase
				hitChance= (15+atk*2)/(30+atk*2+lvl)
				daggerCritBonus=0
				for v=0,1 do
					if pl:GetActiveItem(v) then
						itSkill=pl:GetActiveItem(v):T().Skill
						if itSkill==2 then
							s,m=SplitSkill(pl:GetSkill(const.Skills.Dagger))
							if m>2 then
								daggerCritBonus=daggerCritBonus+0.025+0.005*s
							end
						end
					end
				end
				DPS1=math.round((dmg*(1+might/1000))*(1+(0.05+daggerCritBonus+0.01*luck/15)*(0.5+0.001*accuracy*3))/(delay/100)*hitChance*damageMultiplier[pl:GetIndex()]["Melee"])
				--debug.Message(string.format("%s %s %s %s %s %s %s %s ", dmg,might,daggerCritBonus,luck,accuracy,delay,hitChance,bonusMult))
				--RANGED
				low=pl:GetRangedDamageMin()
				high=pl:GetRangedDamageMax()
				delay=pl:GetAttackDelay(true)
				dmg=(low+high)/2
				--hit chance
				atk=pl:GetRangedAttack()
				hitChance= (15+atk*2)/(30+atk*2+lvl)
				s,m=SplitSkill(pl.Skills[const.Skills.Bow])
				if m>=3 then
					dmg=dmg*2
				end
				DPS2=math.round((dmg*(1+might/1000))*(1+(0.05+0.01*luck/15)*(0.5+0.001*accuracy*3))/(delay/100)*hitChance*damageMultiplier[pl:GetIndex()]["Ranged"])
				if DPS1>DPS2 then
					power=DPS1
					powerType="Melee"
				else
					power=DPS2
					powerType="Ranged"
				end
			else
				
				--calculate damage
				--skill
				skillType=math.floor(spellIndex/11)+12
				skill, mastery=SplitSkill(pl:GetSkill(skillType))
				--SPELLS
				diceMin, diceMax, damageAdd = ascendSpellDamage(skill, mastery, spellIndex)
				
				power=damageAdd + skill*(diceMin+diceMax)/2
				
				intellect=pl:GetIntellect()	
				personality=pl:GetPersonality()
				critChance=pl:GetLuck()/1500
				bonus=math.max(intellect,personality)
				critDamage=bonus*3/2000
				power=power*(1+bonus/1000) 
				critChance=0.05+critChance
				haste=math.floor(pl:GetSpeed()/10)/100+1
				if mastery==1 then
					delay=Game.Spells[11].DelayNormal
				elseif mastery==2 then
					delay=Game.Spells[11].DelayExpert
				elseif mastery==3 then
					delay=Game.Spells[11].DelayMaster
				elseif mastery==4 then
					delay=Game.Spells[11].DelayGM
				end
				powerType="Spell"
				power=math.round(power*(1+(0.05+critChance)*(0.5+critDamage))/(delay/100)*haste)
			end
			
			oldPower=power
			
			--list of stats that influence damage
			slot=t.Item:T().EquipStat
			it=pl:GetActiveItem(slotMap[slot])
			if not it then return end
			--calculate spell damage
			if powerType=="Spell" then
				stats={2,3,6,7}
				intellect1, personality1, speed1, luck1 = unpack(calculateStatsAdd(t.Item, stats))
				intellect2, personality2, speed2, luck2 = unpack(calculateStatsAdd(it, stats))
				bonusInt=intellect1-intellect2
				bonusPers=personality1-personality2
				bonusLuck=luck1-luck2
				bonusSpeed=speed1-speed2
				
				power=damageAdd + skill*(diceMin+diceMax)/2
				
				intellect=pl:GetIntellect()+bonusInt
				personality=pl:GetPersonality()+bonusPers
				critChance=(pl:GetLuck()+bonusLuck)/1500
				bonus=math.max(intellect,personality)
				critDamage=bonus*3/2000
				power=power*(1+bonus/1000) 
				critChance=0.05+critChance
				haste=math.floor((pl:GetSpeed()+bonusSpeed)/10)/100+1
				
				powerType="Spell"
				power=math.round(power*(1+(0.05+critChance)*(0.5+critDamage))/(delay/100)*haste)
				
			elseif powerType=="Melee" or powerType=="Ranged" then
				stats={1,5,6,7}
				
				might1, acc1, speed1, luck1 = unpack(calculateStatsAdd(t.Item, stats))
				might2, acc2, speed2, luck2 = unpack(calculateStatsAdd(it, stats))
				
				bonusMight=might1-might2
				bonusAcc=acc1-acc2
				bonusSpeed=speed1-speed2
				bonusLuck=luck1-luck2
				
				--calculate new DPS
				--might
				might=pl:GetMight()
				if might>=21 then
					oldBonusDamage=math.floor(might/5)
				else
					oldBonusDamage=(might-13)/2
				end
				might=might+bonusMight
				if might>=21 then
					newBonusDamage=math.floor(might/5)
				else
					newBonusDamage=(might-13)/2
				end
				if powerType=="Melee" then
					low=pl:GetMeleeDamageMin()
					high=pl:GetMeleeDamageMax()
				else
					low=pl:GetRangedDamageMin()
					high=pl:GetRangedDamageMax()
				end
				dmg=(low+high)/2+newBonusDamage-oldBonusDamage
				
				--accuracy
				accuracy=pl:GetAccuracy()
				if accuracy>=21 then
					oldAttack=math.floor(accuracy/5)
				else
					oldAttack=(accuracy-13)/2
				end
				accuracy=accuracy+bonusAcc
				if accuracy>=21 then
					newAttack=math.floor(accuracy/5)
				else
					newAttack=(accuracy-13)/2
				end
				
				--speed
				speed=pl:GetSpeed()
				if speed>=21 then
					oldSpeed=math.floor(speed/5)
				else
					oldSpeed=(speed-13)/2
				end
				speed=speed+bonusSpeed
				if speed>=21 then
					newSpeed=math.floor(speed/5)
				else
					newSpeed=(speed-13)/2
				end
				
				recoveryBonus=damageMultiplier[pl:GetIndex()]["bonusSpeedMelee"]+newSpeed-oldSpeed
				if powerType=="Melee" then
					delay=math.max(math.floor(damageMultiplier[pl:GetIndex()]["baseSpeedMelee"] / (1 + recoveryBonus / 100)),30)
					weaponSpeedMult=damageMultiplier[pl:GetIndex()]["Melee"]
				else
					delay=math.floor(damageMultiplier[pl:GetIndex()]["baseSpeedRanged"] / (1 + recoveryBonus / 100))
					weaponSpeedMult=damageMultiplier[pl:GetIndex()]["Ranged"]
				end	
				--debug.Message(string.format("%s %s %s", delay, recoveryBonus, baseSpeed))				
				--luck
				luck=pl:GetLuck()+bonusLuck
				--hit chance
				if powerType=="Melee" then
					atk=pl:GetMeleeAttack()+newAttack-oldAttack
				else
					atk=pl:GetRangedAttack()
				end
				atk=atk+newAttack-oldAttack
				lvl=pl.LevelBase
				hitChance= (15+atk*2)/(30+atk*2+lvl)
				daggerCritBonus=0
				if powerType=="Melee" then
					for v=0,1 do
						if pl:GetActiveItem(v) then
							itSkill=pl:GetActiveItem(v):T().Skill
							if itSkill==2 then
								s,m=SplitSkill(pl:GetSkill(const.Skills.Dagger))
								if m>2 then
									daggerCritBonus=daggerCritBonus+0.025+0.005*s
								end
							end
						end
					end
				else
					s,m=SplitSkill(pl.Skills[const.Skills.Bow])
					if m>=3 then
						dmg=dmg*2
					end
				end
				power=math.round((dmg*(1+might/1000))*(1+(0.05+daggerCritBonus+0.01*luck/15)*(0.5+0.001*accuracy*3))/(delay/100)*hitChance*weaponSpeedMult)
				--debug.Message(string.format("%s %s %s %s %s %s %s %s ", dmg,might,daggerCritBonus,luck,accuracy,delay,hitChance,bonusMult))
			end
			
			
			newPower=power-oldPower
			percentage=math.round((power/oldPower-1)*10000)/100
			if newPower<0 then
				t.Description = t.Description .. "\n\n" .. "Power: " .. StrColor(255,0,0,percentage .. "%")
			elseif newPower>0 then
				t.Description = t.Description .. "\n\n" .. "Power: " .. StrColor(0,255,0,"+" .. percentage .. "%")
			end
			
			--vitality calculation
			--old vitality
			fullHP=pl:GetFullHP()
			--AC
			ac=pl:GetArmorClass()
			local acReduction=1-calcMawDamage(pl,4,10000)/10000
			lvl=math.min(pl.LevelBase, 255)
			local ac=ac/(Game.BolsterAmount/100)
			blockChance= 1-(5+lvl*2)/(10+lvl*2+ac)
			ACRed= 1 - (1-blockChance)*(1-acReduction)
			--speed
			unarmed=0
			Skill, Mas = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
			dodgeChance=1
			if Mas == 4 then
				unarmed=Skill+10
				dodgeChance=0.995^(unarmed)
			end
			fullHP=fullHP/dodgeChance
			--resistances
			local res={0,1,2,3,7,8,12}
			for j=1,7 do 
				res[j]=1-calcMawDamage(pl,res[j],10000)/10000
			end
			--calculation
			local reduction= 1 - (ACRed/2 + res[1]/16 + res[2]/16 + res[3]/16 + res[4]/16 + res[5]/16 + res[6]/16 + res[7]/8)
			oldVitality=math.round(fullHP/reduction)	
			--check for stats changes
			stats={4,6,7,8,10,11,12,13,14,15,16}	
			end1, speed1, luck1, hp1, ac1, fire1, air1, water1, earth1, mind1, body1 = unpack(calculateStatsAdd(t.Item, stats))
			end2, speed2, luck2, hp2, ac2, fire2, air2, water2, earth2, mind2, body2 = unpack(calculateStatsAdd(it, stats))
			newEnd=end1-end2
			newSpeed=speed1-speed2
			newLuck=luck1-luck2
			newHP=hp1-hp2
			newAC=ac1-ac2
			newFire=fire1-fire2
			newAir=air1-air2
			newWater=water1-water2
			newEarth=earth1-earth2
			newMind=mind1-mind2
			newBody=body1-body2
			
			--add item base AC
			
			newAC=newAC+getNewArmor(t.Item)-getNewArmor(it)
			
			--calculate new HP
			newEndurance=pl:GetEndurance()+newEnd
			if newEndurance<=21 then
				newEndEff=(newEndurance-13)/2
			else
				newEndEff=math.floor(newEndurance/5)
			end
			oldEndurance=pl:GetEndurance()
			if newEndurance<=21 then
				oldEndEff=(oldEndurance-13)/2
			else
				oldEndEff=math.floor(oldEndurance/5)
			end
			
			level=pl:GetLevel()+newEndEff
			if t.Item.Bonus2==25 then
				level=level+5
			end
			if it.Bonus2==25 then
				level=level-5
			end
			HPScaling=Game.Classes.HPFactor[pl.Class]
			
			--remove old
			fullHP=pl:GetFullHP()/(1+pl:GetEndurance()/1000)-oldEndEff*HPScaling
			--add new 
			fullHP=fullHP+newHP+newEndEff*HPScaling
			
			fullHP=math.round((fullHP)*(1+(pl:GetEndurance()+newEnd)/1000))
			ac=pl:GetArmorClass()
			oldSpeed=pl:GetSpeed()
			if oldSpeed<=21 then
				oldSpeedEff=(oldSpeed-13)/2
			else
				oldSpeedEff=math.floor(oldSpeed/5)
			end
			local newSpeed=pl:GetSpeed()+newSpeed
			if newSpeed<=21 then
				newSpeedEff=(newSpeed-13)/2
			else
				newSpeedEff=math.floor(newSpeed/5)
			end
			newSpeedEff=newSpeedEff-oldSpeedEff
			
			ac=ac+newAC+newSpeedEff
			local lvl=pl.LevelBase
			bolster=(Game.BolsterAmount/100-1)/4+1
			local acReduction=1-math.round(1/2^math.min(ac/math.min(150+lvl*bolster,400*bolster),4)*10000)/10000
			lvl=math.min(pl.LevelBase, 255)
			local ac=ac/(Game.BolsterAmount/100)
			blockChance= 1-(5+lvl*2)/(10+lvl*2+ac)
			ACRed= 1 - (1-blockChance)*(1-acReduction)
			--speed
			unarmed=0
			Skill, Mas = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
			dodgeChance=1
			if Mas == 4 then
				unarmed=Skill+10
				dodgeChance=0.995^(unarmed)
			end
			vitality=fullHP/dodgeChance
			--resistances
			--luck
			oldLuck=pl:GetLuck()
			if oldLuck<=21 then
				oldLuckEff=(oldLuck-13)/2
			elseif oldLuck<=100 then
				oldLuckEff=math.floor(oldLuck/5)
			else
				oldLuckEff=math.floor(oldLuck/10)+10
			end
			luck=pl:GetLuck()+newLuck
			if luck<=21 then
				newLuckEff=(luck-13)/2
			elseif luck<=100 then
				newLuckEff=math.floor(luck/5)
			else
				newLuckEff=math.floor(luck/10)+10
			end
			luckChanged=newLuckEff-oldLuckEff
			local res={
				[1]=pl:GetResistance(10)+newFire+luckChanged,
				[2]=pl:GetResistance(11)+newAir+luckChanged,
				[3]=pl:GetResistance(12)+newWater+luckChanged,
				[4]=pl:GetResistance(13)+newEarth+luckChanged,
				[5]=pl:GetResistance(14)+newMind+luckChanged,
				[6]=pl:GetResistance(15)+newBody+luckChanged,
			}
			res[7]=math.min(res[1],res[2],res[3],res[4],res[5],res[6])
			for j=1,7 do 
				res[j]=1-math.round(1/2^math.min(res[j]/math.min(75+pl.LevelBase*0.5*bolster,200*bolster),4)*10000)/10000
			end
			
			--calculation
			reduction= 1 - (ACRed/2 + res[1]/16 + res[2]/16 + res[3]/16 + res[4]/16 + res[5]/16 + res[6]/16 + res[7]/8)
			vitality=math.round(vitality/reduction)	
						
			newVitality=vitality-oldVitality
			percentage=math.round((vitality/oldVitality-1)*10000)/100
			if newVitality<0 then
				t.Description = t.Description .. "\n" .. "Vitality: " .. StrColor(255,0,0, percentage .. "%")
			elseif newVitality>0 then
				t.Description = t.Description .. "\n" .. "Vitality: " .. StrColor(0,255,0,"+" .. percentage .. "%")
			end
			

			
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
			t.Description = t.Description .. "\n\nItem Level: " .. itemLevel
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
			baseSpeed=baseRecovery[skill] * (0.75+itemLevel/200)
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
		if MaxCharges <= 20 then
			mult=1+MaxCharges/20
		else
			mult=2+2*(MaxCharges-20)/20
		end
		
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
	
	
	for it in pl:EnumActiveItems() do
		--bolster mult
		mult=1
		if it.MaxCharges <= 20 then
			mult=1+it.MaxCharges/20
		else
			mult=2+2*(it.MaxCharges-20)/20
		end
		
		if it.Bonus>0 then 
			if it.Bonus<=16 then
				tab[it.Bonus]=tab[it.Bonus]+it.BonusStrength
			else
				local tabNumber=bonusBaseEnchantSkill[it.Bonus]+50
				tab[tabNumber]=math.max(tab[tabNumber] or 0, it.BonusStrength)
			end
		end
		if it.Charges>1000 then
			tab[math.floor(it.Charges/1000)]=tab[math.floor(it.Charges/1000)]+it.Charges%1000
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

		--armors
		local txt=it:T()
		if (txt.Skill>=8 and txt.Skill<=11) or txt.Skill==40 then --AC from items
			local ac=txt.Mod1DiceCount+txt.Mod2
			local acBonus=ac
			if it.MaxCharges>0 then 
				local ac2=referenceAC[it.Number]
				local bonusAC=ac2*(it.MaxCharges/20)
				if it.MaxCharges <= 20 then
					acBonus=ac+math.round(bonusAC)
				else
					acBonus=ac+math.round((ac+ac2)*(it.MaxCharges/20))
				end
			end
			--artifacts
			if artArmors[it.Number] then 
				artifactMult=artifactPowerMult(pl.LevelBase)
				acBonus=math.ceil(acBonus*artifactMult)
			end
			tab[10]=tab[10]+acBonus
		end
		--weapons
		if txt.Skill <= 6 or txt.Skill==39 then
			local bonus = txt.Mod2
			local bonus2 = referenceWeaponAttack[it.Number]
			local bonusATK

			if it.MaxCharges <= 20 then
				bonusATK = bonus2 * (it.MaxCharges / 20)
			else
				bonusATK = (bonus2 + bonus) * (it.MaxCharges / 20)
			end
			bonus = bonus + math.round(bonusATK)

			local sides = txt.Mod1DiceSides
			local sides2 = referenceWeaponSides[it.Number]
			local sidesBonus
			
			if it.MaxCharges <= 20 then
				sidesBonus = sides2 * (it.MaxCharges / 20)
			else
				sidesBonus = (sides2 + sides) * (it.MaxCharges / 20)
			end
			sidesBonus = sides + math.round(sidesBonus)
			
			if table.find(artWeap1h,it.Number) or table.find(artWeap2h,it.Number) then 
				if txt.EquipStat<=1 then
					artifactMult=artifactPowerMult(pl.LevelBase)
					bonus=math.ceil(txt.Mod2*artifactMult)
					sidesBonus=math.ceil(txt.Mod1DiceSides*artifactMult)
				end
			end	
			if txt.Skill ~= 5 then
				tab[40] = tab[40] + math.round(bonus)
				tab[41] = tab[41] + math.round(bonus)
				tab[42] = tab[42] + txt.Mod1DiceCount+math.round(bonus)
				tab[43] = tab[43] + math.round(sidesBonus)*txt.Mod1DiceCount+math.round(bonus)
			else
				tab[44] = tab[44] + math.round(bonus)
				tab[45] = tab[45] + math.round(bonus)
				tab[46] = tab[46] + math.round(txt.Mod1DiceCount)+tab[45]
				tab[47] = tab[47] + math.round(sidesBonus)*txt.Mod1DiceCount+tab[45]
			end
		end
		
		--skills
		if equipSpellMap[it.Bonus2] then
			tab[it.Bonus2]= 5 +  math.floor(it.MaxCharges/4)
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
	--------------
	--end of items
	--------------
	--dragon
	if Game.CharacterPortraits[pl.Face].Race==const.Race.Dragon then
		for i=1,16 do
			tab[i]=tab[i]*2
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
	
	local s,m=SplitSkill(pl.Skills[const.Skills.Bodybuilding])	
	if m==4 then
		m=5
	end
	BBHP=s*m
	BBBonus=math.round(s^2/2)
	level=pl.LevelBonus+pl.LevelBase
	hpScaling=Game.Classes.HPFactor[pl.Class]
	baseHP=Game.Classes.HPBase[pl.Class]+hpScaling*(level+endEff+BBHP)
	fullHP=baseHP+tab[8]+BBBonus
	Endurancebonus=fullHP*endurance/1000
	tab[8]=tab[8]+Endurancebonus+BBBonus+hpScaling*BBHP
	
	--get bonus stats from skills
	
	--meditation
	local s,m=SplitSkill(pl.Skills[const.Skills.Meditation])	
	if m==4 then
		m=5
	end
	tab[9]=tab[9]+Game.Classes.SPFactor[pl.Class]*s*m
	
	ACBONUS=0
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
			
			local bonusDamage=0
			if item:T().EquipStat==1 then
				bonusDamage=twoHandedWeaponDamageBonusByMastery[m]
			elseif skill==4 and  not pl:GetActiveItem(0) then
				bonusDamage=twoHandedWeaponDamageBonusByMastery[m]
			end
			--minotaur axe overrides, no extra damage if 2h weapon in offhand
			if skill==3 and table.find(twoHandedAxes, item.Number) then
				local offHand=pl:GetActiveItem(0)
				if offHand and table.find(twoHandedAxes, offHand.Number) then
					bonusDamage=0
				else
					bonusDamage=3
				end
			end
			
			if skillAC[skill] and skillAC[skill][m] then
				tab[10]=tab[10]+skillAC[skill][m]*s
			end
			if skillResistance[skill] and skillResistance[skill][m] then
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
			if skillDamage[skill] and skillDamage[skill][m] then
				if i~=2 then
					tab[41]=tab[42]+skillDamage[skill][m]*s+bonusDamage*s
					tab[42]=tab[42]+skillDamage[skill][m]*s+bonusDamage*s
					tab[43]=tab[43]+skillDamage[skill][m]*s+bonusDamage*s
				else
					removeVanillaCalculation=0
					if m==4 then removeVanillaCalculation=1 end
					tab[45]=tab[45]+skillDamage[skill][m]*s
					tab[46]=tab[46]+skillDamage[skill][m]*s-(removeVanillaCalculation*s)
					tab[47]=tab[47]+skillDamage[skill][m]*s-(removeVanillaCalculation*s)
				end
			end
		end
		local s,m = SplitSkill(pl:GetSkill(const.Skills.Dodging)) 
		if (i==3 and item==nil and m>=1) or (m==4 and item and item:T().Skill==9) then
			tab[10]=tab[10]+skillAC[const.Skills.Dodging][m]*s
		end
	end
	--armsmaster
	local s,m = SplitSkill(pl:GetSkill(const.Skills.Armsmaster))
	if m>0 then
		tab[40]=tab[40]+armsmasterAttack[m]*s
		tab[41]=tab[41]+armsmasterDamage[m]*s
		tab[42]=tab[42]+armsmasterDamage[m]*s
		tab[43]=tab[43]+armsmasterDamage[m]*s
	end
	--unarmed
	local s,m = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
	local s1,m1 = SplitSkill(pl:GetSkill(const.Skills.Staff))
	if (m>=1 and not pl:GetActiveItem(0) and not pl:GetActiveItem(1)) or (m1==4 and pl:GetActiveItem(1) and pl:GetActiveItem(1):T().Skill==0 ) then
		if m>0 then
			tab[40]=tab[40]+skillAttack[const.Skills.Unarmed][m]*s
			tab[41]=tab[41]+skillDamage[const.Skills.Unarmed][m]*s
			tab[42]=tab[42]+skillDamage[const.Skills.Unarmed][m]*s
			tab[43]=tab[43]+skillDamage[const.Skills.Unarmed][m]*s
		end
	end
	local buff=pl.SpellBuffs[6]
	if buff.ExpireTime>Game.Time then --hammerhand buff
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
	tab[42]=tab[42]+(tab[42]+bonusDamage)*might/1000
	tab[43]=tab[43]+(tab[43]+bonusDamage)*might/1000
	tab[46]=tab[46]+(tab[46]+bonusDamage)*might/1000
	tab[47]=tab[47]+(tab[47]+bonusDamage)*might/1000
	return tab
end

armsmasterAttack={0,1,1,2}
armsmasterDamage={0,0,2,4}

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
							[const.Stats.BodyResistance]	= 20,
							[const.Stats.SpiritResistance]	= 20}	
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
							[const.Stats.MindResistance]	= -200,
							[const.Stats.SpiritResistance]	= -200}		
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
							[const.Stats.BodyResistance] 	= -20,
							[const.Stats.SpiritResistance] 	= -20}
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
							[const.Stats.SpiritResistance] = -30
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
							[const.Stats.BodyResistance]	= 10,
							[const.Stats.SpiritResistance]	= 10}
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
							[const.Stats.SpiritResistance] 	= 40,
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
artifactSkillBonus[1317] =	{	[const.Skills.Meditation] = 15}
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
-- Faerie ring
artifactSkillBonus[1347] =	{	[const.Skills.Fire] = 5,
								[const.Skills.Air] = 5,
								[const.Skills.Water] = 5,
								[const.Skills.Earth] = 5}
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
	partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL-math.min(currentLevel,54)
	--cap
	difficultyExtraPower=1
	if Game.BolsterAmount==150 then
		difficultyExtraPower=1.025
	elseif Game.BolsterAmount==200 then
		difficultyExtraPower=1.05
	elseif Game.BolsterAmount==300 then
		difficultyExtraPower=1.1
	end
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
function artifactPowerMult(level)
	local bol=Game.BolsterAmount
	bol=(bol/100-1)/5+1
	local mult=math.max(math.min(level/80*bol,3*bol),0.5)
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
	[11]=0,
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
function events.CalcStatBonusByItems(t)
	if statToPlayerbuff[t.Stat] then
		local stat1=statToPlayerbuff[t.Stat]
		local power1=t.Player.SpellBuffs[stat1].Power
		local stat2=playerToPartyBuff[stat1]
		local power2=Party.SpellBuffs[stat2].Power
		if power1>=power2 then
			t.Result=t.Result-power2
		else
			t.Result=t.Result-power1
		end
	end
end
