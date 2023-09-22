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

	--nerf if item is strong
	if partyLevelItemGen<(t.Strength-3)*20 and t.Strength<7 then
		t.Strength=t.Strength-1
	end
	if (t.Strength-2)*20>partyLevelItemGen and t.Strength>2 and t.Strength<7 then
		roll=math.random((t.Strength-3)*20,(t.Strength-2)*20)
		if roll>partyLevelItemGen then
			t.Strength=t.Strength-1
		end
	end
end

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
encStrDown={1,1,3,6,10,15,20,24,28,32,36,40,44,48,52,56,60,64,68,76}
encStrUp={3,5,8,12,17,25,30,35,40,45,50,55,60,65,70,75,80,85,90,100}


enc1Chance={20,30,40,50,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80}
enc2Chance={20,30,35,40,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60}
spcEncChance={0,0,15,20,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40}

primordialWeapEnchants={41,46}
primordialArmorEnchants={1,2,80}

function events.ItemGenerated(t)
	if Map.MapStatsIndex==0 then
		return 
	end
	if t.Strength==7 then
		return
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
		elseif currentWorld==2 then
			partyLevel=vars.MM8LVL+vars.MM6LVL
		elseif currentWorld==3 then
			partyLevel=vars.MM8LVL+vars.MM7LVL
		elseif currentWorld==4 then
			partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
		end
		--modify reagents
		if reagentList[t.Item.Number] then
			t.Item.Bonus=math.round(partyLevel/3)
			return
		end
		--ADD MAX CHARGES BASED ON PARTY LEVEL
		t.Item.MaxCharges=math.min(math.floor(partyLevel/5),255)
		partyLevel1=math.min(math.floor(partyLevel/18),14)
		--adjust loot Strength
		ps1=t.Strength
		pseudoStr=ps1+partyLevel1
		if math.random(1,18)>partyLevel1%18 then
			pseudoStr=pseudoStr+1
		end
		if pseudoStr==1 then 
			return 
		end
		roll1=math.random(1,100)
		roll2=math.random(1,100)
		rollSpc=math.random(1,100)
		power=0
		--apply enchant1
		if enc1Chance[pseudoStr]>roll1 then
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.random(encStrDown[pseudoStr],encStrUp[pseudoStr])
			if math.random(1,10)==10 then
				t.Item.Bonus=math.random(17,24)
				t.Item.BonusStrength=math.ceil(t.Item.BonusStrength^0.5)
			end
		end
		--apply enchant2
		if enc2Chance[pseudoStr]>roll2 then
			t.Item.Charges=math.random(1,16)*1000
			t.Item.Charges=t.Item.Charges+math.random(encStrDown[pseudoStr],encStrUp[pseudoStr])
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
		ancientRoll=math.random(1,50)
		if ancientRoll<=1 then
			ancient=true
			t.Item.Charges=math.random(math.round(encStrUp[pseudoStr]+1),math.round(encStrUp[pseudoStr]*1.25))+math.random(1,16)*1000
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.random(math.round(encStrUp[pseudoStr]+1),math.round(encStrUp[pseudoStr]*1.25))
			power=2
			chargesBonus=math.random(1,5)
			t.Item.MaxCharges=t.Item.MaxCharges+chargesBonus
			t.Item.BonusExpireTime=1
		end
		--apply special enchant
		if spcEncChance[pseudoStr]>rollSpc or ancient then
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
		primordial=math.random(1,200)
		if primordial<=1 then
			if ancient then
				t.Item.MaxCharges=t.Item.MaxCharges-chargesBonus
			end
			t.Item.BonusExpireTime=2
			t.Item.Charges=math.round(encStrUp[pseudoStr]*1.25)+math.random(1,16)*1000
			t.Item.Bonus=math.random(1,16)
			t.Item.BonusStrength=math.round(encStrUp[pseudoStr]*1.25)
			t.Item.MaxCharges=t.Item.MaxCharges+5
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
			t.Item.BonusStrength=t.Item.BonusStrength*2
		end
		if math.floor(t.Item.Charges/1000)==8 or math.floor(t.Item.Charges/1000)==9 then
			t.Item.Charges=t.Item.Charges+t.Item.Charges%1000
		end
		--nerf to AC
		if t.Item.Bonus==10 then
			t.Item.BonusStrength=math.ceil(t.Item.BonusStrength/2)
		end
		if math.floor(t.Item.Charges/1000)==10 then
			t.Item.Charges=t.Item.Charges-math.floor(t.Item.Charges%1000)/2
		end
		-- buff to 2h weapons enchants
		if t.Item:T().EquipStat == 1 then
			t.Item.BonusStrength=t.Item.BonusStrength*2
			t.Item.Charges=t.Item.Charges+t.Item.Charges%1000
		end
	end
end

--apply charges effect
function events.CalcStatBonusByItems(t)
	for it in t.Player:EnumActiveItems() do
		if it.Charges > 1000 then
			stat=math.floor(it.Charges/1000)-1
			bonus=it.Charges%1000
			if t.Stat==stat then
				if stat>=10 and stat<=15 then
					t.Result = t.Result + bonus * 2
				else
					t.Result = t.Result + bonus
				end
			end

		end
	end
end

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
			if Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Axe" or Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Sword" then
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
			Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.06)
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
				Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.04)
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
					Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.02)
					end 
				else vars.poisonTime[i]=0
				end
			end
		end
	end
end
Timer(poisonTimer, const.Minute) 

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
					HPregen=math.max(HPregen+totHP*0.005,HPregen+1)	
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
					SPregen=math.max(SPregen+totSP*0.005,SPregen+1)
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
		if data.Object.Item.Bonus2==3 then
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
				if t.Item.Bonus>=11 and t.Item.Bonus<=16 then --% values for resistances
					t.Enchantment = itemStatName[t.Item.Bonus] .. " +" .. t.Item.BonusStrength/2 .. "%" 
				else
					t.Enchantment = itemStatName[t.Item.Bonus] .. " +" .. t.Item.BonusStrength
				end
			end
			if t.Item.Charges>1000 then
				local bonus=math.floor(t.Item.Charges/1000)
				local strength=t.Item.Charges%1000
				if bonus>=11 and bonus<=16 then --% values for resistances
					strength=strength/2
					t.Enchantment = itemStatName[bonus] .. " +" .. strength .. "%" .. "\n" .. t.Enchantment
				else
					t.Enchantment = itemStatName[bonus] .. " +" .. strength .. "\n" .. t.Enchantment
				end
			end
		elseif t.Name then
			--add enchant Name
			t.Name = Game.ItemsTxt[t.Item.Number].Name
			if t.Item.Bonus2>0 then
				t.Name= t.Name .. " " .. Game.SpcItemsTxt[t.Item.Bonus2-1].NameAdd
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
				if (t.Item.MaxCharges>0 and bonusEffects[t.Item.Bonus2]~= nil) or enchantList[t.Item.Bonus2] then
					text=checktext(t.Item.MaxCharges,t.Item.Bonus2)
				else
					text=Game.SpcItemsTxt[t.Item.Bonus2-1].BonusStat
				end
				t.Description = StrColor(255,255,153,text) .. "\n\n" .. t.Description
			end
		end
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
end


function events.GameInitialized2()
	Game.SpcItemsTxt[2].BonusStat="Explosive Impact! (half damage)"
end

--max charges empower items base stats by 2 every 100 levels (every 5 levels bolster level you get 1 maxcharges)
--apply MAXcharges effect
function events.CalcStatBonusByItems(t)
	if t.Stat==9 then
		for it in t.Player:EnumActiveItems() do
			if it.MaxCharges > 0 then
				if table.find(artArmors,it.Number) then
					it.MaxCharges=0
					return
				end
				local equipStat=Game.ItemsTxt[it.Number].EquipStat
				if equipStat>=3 and equipStat<=9 then
					lookup=0
					while Game.ItemsTxt[it.Number].NotIdentifiedName==Game.ItemsTxt[it.Number+lookup+1].NotIdentifiedName do 
						lookup=lookup+1
					end
					ac=Game.ItemsTxt[it.Number].Mod2+Game.ItemsTxt[it.Number].Mod1DiceCount 
					ac2=Game.ItemsTxt[it.Number+lookup].Mod2+Game.ItemsTxt[it.Number+lookup].Mod1DiceCount 
					bonusAC=ac2*(it.MaxCharges/20)
					if it.MaxCharges <= 20 then
						t.Result=t.Result+math.round(bonusAC)
					else
						bonusAC=(ac+ac2)*(it.MaxCharges/20)
						t.Result=t.Result+math.round(bonusAC)
					end
				end
			end
		end
	end
end



--visual changes in stats menu for scaled weapon
function events.CalcStatBonusByItems(t)
	--increase damage depending on max CHARGES, only visual (except for attack)
	local cs = const.Stats
	if t.Stat==cs.MeleeDamageMin or t.Stat==cs.MeleeDamageMax or t.Stat==cs.MeleeAttack then
		for i=0,1 do
			local it=t.Player:GetActiveItem(i)
			if	it then
				if table.find(artWeap1h,it.Number) or table.find(artWeap2h,it.Number) then
					it.MaxCharges=0
					return
				end
				if it.MaxCharges>0 then
					local data=Game.ItemsTxt[it.Number]
					if data.EquipStat<=2 then
						lookup=0
						while Game.ItemsTxt[it.Number].NotIdentifiedName==Game.ItemsTxt[it.Number+lookup+1].NotIdentifiedName do 
							lookup=lookup+1
						end
						--add fix damage
						local bonus=data.Mod2
						local bonus2=Game.ItemsTxt[it.Number+lookup].Mod2
						if it.MaxCharges <= 20 then
							local bonus=bonus2*(it.MaxCharges/20)
							t.Result=t.Result+math.round(bonus)
						else
							local bonus=(bonus+bonus2)*(it.MaxCharges/20)
							t.Result=t.Result+math.round(bonus)
						end
						--calculate random damage
						if t.Stat==cs.MeleeDamageMax then
							local bonus=data.Mod1DiceSides
							local bonus2=Game.ItemsTxt[it.Number+lookup].Mod1DiceSides
							local dices=data.Mod1DiceCount
							if it.MaxCharges <= 20 then
								local bonus=bonus2*(it.MaxCharges/20)
								t.Result=t.Result+math.round(bonus)*dices
							else
								local bonus=(bonus+bonus2)*(it.MaxCharges/20)
								t.Result=t.Result+math.round(bonus)*dices
							end
						end
					end
				end
			end
		end
	end
	--same for bows
	if t.Stat==cs.RangedDamageMin or t.Stat==cs.RangedDamageMax or t.Stat==cs.RangedAttack then
		local it=t.Player:GetActiveItem(2)
		if	it then
			if table.find(artWeap1h,it.Number) or table.find(artWeap2h,it.Number) then
				it.MaxCharges=0
				return
			end
			if it.MaxCharges>0 then
				local data=Game.ItemsTxt[it.Number]
				if data.EquipStat<=2 then
				--add fix damage
					local bonus=data.Mod2
					local bonus2=Game.ItemsTxt[it.Number+lookup].Mod2
					if it.MaxCharges <= 20 then
						local bonus=bonus2*(it.MaxCharges/20)
						t.Result=t.Result+math.round(bonus)
					else
						local bonus=(bonus+bonus2)*(it.MaxCharges/20)
						t.Result=t.Result+math.round(bonus)
					end
					--calculate random damage
					if t.Stat==cs.RangedDamageMax then
						local bonus=data.Mod1DiceSides
						local bonus2=Game.ItemsTxt[it.Number+lookup].Mod1DiceSides
						local dices=data.Mod1DiceCount
						if it.MaxCharges <= 20 then
							local bonus=bonus2*(it.MaxCharges/20)
							t.Result=t.Result+math.round(bonus)*dices
						else
							local bonus=(bonus+bonus2)*(it.MaxCharges/20)
							t.Result=t.Result+math.round(bonus)*dices
						end
					end
				end
			end
		end
	end
	
end

					
--recalculate actual damage
function events.ModifyItemDamage(t)
	bonusDamage=0
	if t.Item then
		if t.Item.MaxCharges>0 then
			lookup=0
			while Game.ItemsTxt[t.Item.Number].NotIdentifiedName==Game.ItemsTxt[t.Item.Number+lookup+1].NotIdentifiedName do 
				lookup=lookup+1
			end
			add=Game.ItemsTxt[t.Item.Number].Mod2
			add2=Game.ItemsTxt[t.Item.Number+lookup].Mod2
			side=Game.ItemsTxt[t.Item.Number].Mod1DiceSides
			side2=Game.ItemsTxt[t.Item.Number+lookup].Mod1DiceSides
			if t.Item.MaxCharges <= 20 then
				newside=side+side2*(t.Item.MaxCharges/20)
				newbonus=add+add2*(t.Item.MaxCharges/20)
			else
				newside=side+(side+side2)*(t.Item.MaxCharges/20)
				newbonus=add+(add+add2)*(t.Item.MaxCharges/20)
			end
			--calculate dices
			for i=1,Game.ItemsTxt[t.Item.Number].Mod1DiceCount do
				bonusDamage=bonusDamage+math.random(1,newside)
			end
			t.Result=bonusDamage+newbonus
		end
	end
end

--fix to enchant2 not applying correctly if same bonus is on the item
--fix to special enchants

bonusEffects = {
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
    [57] = { bonusType = 57, bonusValues = {2, 3}, statModifier = 5 }
}

function events.CalcStatBonusByItems(t)
    for it in t.Player:EnumActiveItems() do
        local bonusData = bonusEffects[it.Bonus2]
        if bonusData then
            if bonusData.bonusRange then
                local lower, upper = bonusData.bonusRange[1], bonusData.bonusRange[2]
                if it.Bonus >= lower and it.Bonus <= upper then
                    if t.Stat == it.Bonus - 1 then
                        t.Result = t.Result + bonusData.statModifier
                    end
                end
            elseif bonusData.bonusValues then
                for _, value in ipairs(bonusData.bonusValues) do
                    if it.Bonus == value then
                        if t.Stat == it.Bonus - 1 then
                            if type(bonusData.statModifier) == "table" then
                                t.Result = t.Result + bonusData.statModifier[value]
                            else
                                t.Result = t.Result + bonusData.statModifier
                            end
                        end
                    end
                end
            end
        end
    end
end




--make enchant 2 scale with maxcharges
function events.CalcStatBonusByItems(t)
    for it in t.Player:EnumActiveItems() do
		if it.MaxCharges>0 then
			local bonusData = bonusEffects[it.Bonus2]
			if bonusData then
				if it.MaxCharges <= 20 then
					mult=it.MaxCharges/20
				else
					mult=1+2*(it.MaxCharges-20)/20
				end
				if bonusData.bonusRange then
					local lower, upper = bonusData.bonusRange[1], bonusData.bonusRange[2]
					if t.Stat>=lower-1 and t.Stat<upper then
						t.Result = t.Result + bonusData.statModifier * mult
					end
				elseif bonusData.bonusValues then
					for i =1, 3 do
						if bonusData.bonusValues[i] then
							if bonusData.bonusValues[i]-1==t.Stat then
								local modifier = bonusData.statModifier
								if type(modifier) == "table" then
									t.Result = t.Result + modifier[i] * mult
								else
									t.Result = t.Result + modifier * mult
								end
							end
						end
					end
				end
			end
		end
    end
end


--create dictionary with description list
function checktext(MaxCharges,bonus2)
	if MaxCharges <= 20 then
		mult=1+MaxCharges/20
	else
		mult=2+2*(MaxCharges-20)/20
	end
	bonus2txt={
		[1] =  " +" .. math.round(bonusEffects[1].statModifier * mult) .. " to all Resistances.",
		[2] = " +" .. math.round(bonusEffects[2].statModifier * mult) .. " to all Seven Statistics.",
		[4] ="Adds " .. math.round(6*mult) .. "-" .. math.round(8*mult) .. " points of Cold damage. (Increases also spell damage)",
		[5] ="Adds " .. math.round(18*mult) .. "-" .. math.round(24*mult) .. " points of Cold damage. (Increases also spell damage)",
		[6] ="Adds " .. math.round(36*mult) .. "-" .. math.round(48*mult) .. " points of Cold damage. (Increases also spell damage)",
		[7] ="Adds " .. math.round(4*mult) .. "-" .. math.round(10*mult) .. " points of Electrical damage. (Increases also spell damage)",
		[8] ="Adds " .. math.round(12*mult) .. "-" .. math.round(30*mult) .. " points of Electrical damage. (Increases also spell damage)",
		[9] ="Adds " .. math.round(24*mult) .. "-" .. math.round(60*mult) .. " points of Electrical damage. (Increases also spell damage)",
		[10] ="Adds " .. math.round(2*mult) .. "-" .. math.round(12*mult) .. " points of Fire damage. (Increases also spell damage)",
		[11] ="Adds " .. math.round(6*mult) .. "-" .. math.round(36*mult) .. " points of Fire damage. (Increases also spell damage)",
		[12] ="Adds " .. math.round(12*mult) .. "-" .. math.round(72*mult) .. " points of Fire damage. (Increases also spell damage)",
		[13] ="Adds " .. math.round(12*mult) .. " points of Body damage.",
		[14] ="Adds " .. math.round(24*mult) .. " points of Body damage.",
		[15] ="Adds " .. math.round(48*mult) .. " points of Body damage.",
		--spell enchants
		[26] = "Air Magic Skill +" .. math.round(MaxCharges/4)+5,
		[27] = "Body Magic Skill +" .. math.round(MaxCharges/4)+5,
		[28] = "Dark Magic Skill +" .. math.round(MaxCharges/4)+5,
		[29] = "Earth Magic Skill +" .. math.round(MaxCharges/4)+5,
		[30] = "Fire Magic Skill +" .. math.round(MaxCharges/4)+5,
		[31] = "Light Magic Skill +" .. math.round(MaxCharges/4)+5,
		[32] = "Mind Magic Skill +" .. math.round(MaxCharges/4)+5,
		[33] = "Spirit Magic Skill +" .. math.round(MaxCharges/4)+5,
		[34] = "Water Magic Skill +" .. math.round(MaxCharges/4)+5,
		--stats enchants
		[42] = " +" .. math.round(bonusEffects[42].statModifier * mult) .. " to Seven Stats, HP, SP, Armor, Resistances.",
		[43] = " +" .. math.round(bonusEffects[43].statModifier * mult) .. " to Endurance, Armor, Hit points.",
		[44] = " +" .. math.round(bonusEffects[44].statModifier * mult) .. " Hit points and Regenerate Hit points over time.",
		[45] = " +" .. math.round(bonusEffects[45].statModifier * mult) .. " Speed and Accuracy.",
		[46] = "Adds " .. math.round(40*mult) .. "-" .. math.round(80*mult) .. " points of Fire damage and +" .. math.round(bonusEffects[46].statModifier * mult).. " Might.",
		[47] = " +" .. math.round(bonusEffects[47].statModifier * mult) .. " Spell points and Regenerate Spell points over time.",
		[48] = " +" .. math.round(bonusEffects[48].statModifier[1] * mult) .. " Endurance and" .. " +" .. math.round(bonusEffects[48].statModifier[2] * mult).. " Armor.",
		[49] = " +" .. math.round(bonusEffects[49].statModifier * mult) .. " Intellect and Luck.",
		[50] = " +" .. math.round(bonusEffects[50].statModifier * mult) .. " Fire Resistance and Regenerate Hit points over time.",
		[51] = " +" .. math.round(bonusEffects[51].statModifier * mult) .. " Spell points, Speed, Intellect.",
		[52] = " +" .. math.round(bonusEffects[52].statModifier * mult) .. " Endurance and Accuracy.",
		[53] = " +" .. math.round(bonusEffects[53].statModifier * mult) .. " Might and Personality.",
		[54] = " +" .. math.round(bonusEffects[54].statModifier * mult) .. " Endurance and Regenerate Hit points over time.",
		[55] = " +" .. math.round(bonusEffects[55].statModifier * mult) .. " Luck and Regenerate Spell points over time.",
		[56] = " +" .. math.round(bonusEffects[56].statModifier * mult) .. " Might and Endurance.",
		[57] = " +" .. math.round(bonusEffects[57].statModifier * mult) .. " Intellect and Personality.",
		--max resistance enchant
		[74] = "Increase Max Fire Resistance by " .. 5+math.round(MaxCharges/8) .. "%",
		[75] = "Increase Max Air Resistance by " .. 5+math.round(MaxCharges/8) .. "%",
		[76] = "Increase Max Water Resistance by " .. 5+math.round(MaxCharges/8) .. "%",
		[77] = "Increase Max Earth Resistance by " .. 5+math.round(MaxCharges/8) .. "%",
		[78] = "Increase Max Mind Resistance by " .. 5+math.round(MaxCharges/8) .. "%",
		[79] = "Increase Max Body Resistance by " .. 5+math.round(MaxCharges/8) .. "%",
		[80] = "Increase All Max Resistance by " .. 2+math.round(MaxCharges/20) .. "%",
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
			bonus1=bonus1/2
		end
		if t.Item.Bonus>16 and t.Item.Bonus<=24 then
			bonus1=(bonus1/100)^2*100
		end
		bonus2=(t.Item.Charges%1000)*100
		if math.floor(t.Item.Charges/1000)==8 or math.floor(t.Item.Charges/1000)==9 then
			bonus1=bonus1/2
		end
		
		MaxCharges=t.Item.MaxCharges
		if MaxCharges <= 20 then
			mult=1+MaxCharges/20
		else
			mult=2+2*(MaxCharges-20)/20
		end
		basePrice=basePrice*mult
		if t.Item.Bonus2>0 then
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
	end
end

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

--remove older "of x spell school" enchant and replace

--create enchant Map
magicEnchantMap={}
magicEnchantMap[const.Skills.Fire] = 30
magicEnchantMap[const.Skills.Air] = 26
magicEnchantMap[const.Skills.Water] = 34
magicEnchantMap[const.Skills.Earth] = 29
magicEnchantMap[const.Skills.Spirit] = 33
magicEnchantMap[const.Skills.Mind] = 32
magicEnchantMap[const.Skills.Body] = 27
magicEnchantMap[const.Skills.Light] = 31
magicEnchantMap[const.Skills.Dark] = 28


function events.GetSkill(t)
	if magicEnchantMap[t.Skill] then
		spellBonus=0
		malus=0
		local skill = t.Player.Skills[t.Skill]
		local s,m=SplitSkill(skill)
		for it in t.Player:EnumActiveItems() do
			if it.Bonus2==magicEnchantMap[t.Skill] then
				malus=math.floor(s/2)
				spellBonus=math.max(5+math.round(it.MaxCharges/4))
			end
		end
		t.Result=t.Result+spellBonus-malus
	end
end

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
artWeap1h={500,501,502,503,504,508,509,510,512,523,524,526,529,538,542,1302,1303,1304,1305,1308,1312,1316,1319,1328,1329,1330,1333,1340,1342,1343,1344,1345,1353,1354,2020,2021,2023,2025,2035,2036,2038,2040}
artWeap2h={505,506,507,511,525,526,527,528,530,539,540,541,1309,1310,1311,1320,1351,2022,2024,2037,2039}
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
	lvl=math.max(math.min(lvl/100,2.5),0.5)
    num = tonumber(match)
    if num then
        return tostring(math.floor(num * lvl))
    end
    return match
end

--------------------------------
--ARTIFACTS BASE STATS SCALING--
--------------------------------

function events.BuildItemInformationBox(t)
	if (t.Item.Number>=500 and t.Item.Number<=543) or (t.Item.Number>=1302 and t.Item.Number<=1354) or (t.Item.Number>=2020 and t.Item.Number<=2049) then 
		if t.Type then
			local txt=Game.ItemsTxt[t.Item.Number]
			local ac=math.ceil((txt.Mod2+txt.Mod1DiceCount)*math.max(math.min(Party[Game.CurrentPlayer].LevelBase/100,2.5),0.5))
			if ac>0 then 			
				t.BasicStat= "Armor: +" .. ac
			end
			--WEAPONS
			local equipStat=txt.EquipStat
			if equipStat<=2 then
				local bonus=math.ceil((txt.Mod2)*math.max(math.min(Party[Game.CurrentPlayer].LevelBase/100,2.5),0.5))
				local sides=math.ceil((txt.Mod1DiceSides)*math.max(math.min(Party[Game.CurrentPlayer].LevelBase/100,2.5),0.5))
				t.BasicStat= "Attack: +" .. bonus .. "  " .. "Damage: " ..  txt.Mod1DiceCount .. "d" .. sides .. "+" .. bonus
			end
		end
	end
end
--increase artifact ac
function events.CalcStatBonusByItems(t)
	if t.Stat==const.Stats.ArmorClass then
		for it in t.Player:EnumActiveItems() do 
			if (it.Number>=500 and it.Number<=543) or (it.Number>=1302 and it.Number<=1354) or (it.Number>=2020 and it.Number<=2049) then 
				local txt=Game.ItemsTxt[it.Number]
				c=txt.EquipStat
				if c>2 then
					t.Result=t.Result-(txt.Mod2+txt.Mod1DiceCount)+math.ceil((txt.Mod2+txt.Mod1DiceCount)*math.max(math.min(t.Player.LevelBase/100,2.5),0.5))
				end
			end
		end
	end
end
--increase artifact damage tooltip
function events.CalcStatBonusByItems(t)
	local cs = const.Stats
	if t.Stat==cs.MeleeDamageMin or t.Stat==cs.MeleeDamageMax or t.Stat==cs.MeleeAttack then
		for it in t.Player:EnumActiveItems() do 
			if (it.Number>=500 and it.Number<=543) or (it.Number>=1302 and it.Number<=1354) or (it.Number>=2020 and it.Number<=2049) then 
				txt=Game.ItemsTxt[it.Number]
				c=txt.EquipStat
				if c<=1 then
				t.Result=t.Result-txt.Mod2+math.ceil(txt.Mod2*math.max(math.min(t.Player.LevelBase/100,2.5),0.5))
					if t.Stat==cs.MeleeDamageMax then
						t.Result=t.Result-(txt.Mod1DiceCount*txt.Mod1DiceSides-txt.Mod1DiceCount)+(txt.Mod1DiceCount*txt.Mod1DiceSides*math.max(math.min(t.Player.LevelBase/100,2.5),0.5))
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
				t.Result=t.Result-txt.Mod2+math.ceil(txt.Mod2*math.max(math.min(t.Player.LevelBase/100,2.5),0.5))
					if t.Stat==cs.RangedDamageMax then
						t.Result=t.Result-(txt.Mod1DiceCount*txt.Mod1DiceSides-txt.Mod1DiceCount)+(txt.Mod1DiceCount*txt.Mod1DiceSides*math.max(math.min(t.Player.LevelBase/100,2.5),0.5))
					end
				end
			end	
		end
	end
end

--modify actual damage
--recalculate actual damage
function events.ModifyItemDamage(t)
	if t.Item then
		if (t.Item.Number>=500 and t.Item.Number<=543) or (t.Item.Number>=1302 and t.Item.Number<=1354) or (t.Item.Number>=2020 and t.Item.Number<=2049) then 
			bonusDamage=0
			add=math.ceil(Game.ItemsTxt[t.Item.Number].Mod2*math.max(math.min(t.Player.LevelBase/100,2.5),0.5))
			side=math.ceil(Game.ItemsTxt[t.Item.Number].Mod1DiceSides*math.max(math.min(t.Player.LevelBase/100,2.5),0.5))
			--calculate dices
			for i=1,Game.ItemsTxt[t.Item.Number].Mod1DiceCount do
				bonusDamage=bonusDamage+math.random(1,side)
			end
			t.Result=bonusDamage+add
		end
	end
end

------------------------------------------------------------------
--bruteforce fix to items spawning maxcharges more than intended--
------------------------------------------------------------------
function events.BeforeNewGameAutosave()
	for i=0,Party.High do
		for j=1, Party[0].Items.High do
			Party[i].Items[j].MaxCharges=0
			Party[i].Items[j].Charges=0
		end
	end
end

function events.BuildItemInformationBox(t)
	partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
	maxItemBolster=(partyLevel)/5+5
	--failsafe
	if t.Item.Charges==0 and t.Item.Bonus2==0 and t.Item.Bonus==0 then
		t.Item.MaxCharges=0
	end
end

--do the same if someone is trying to equip on a player
function events.Action(t)
	if t.Action==133 then
		partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
		maxItemBolster=(partyLevel)/5+5
		--failsafe
		if Mouse.Item and Mouse.Item.Charges==0 and Mouse.Item.Bonus2==0 and Mouse.Item.Bonus==0 then
			Mouse.Item.MaxCharges=0
		end
	end
end

--vampiric nerf
gotVamp={}
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
end

function events.GameInitialized2() --make it load later compared to other scripts
	function events.CalcDamageToMonster(t)
		if t.DamageKind==4 then
			data=WhoHitMonster()
			if data and data.Player and not data.Object then
				if gotVamp[data.Player:GetIndex()] then
					t.Player.HP=math.min(t.Player:GetFullHP(),t.Player.HP+t.Result*0.05)
				end
			end
		end
	end
end
				
