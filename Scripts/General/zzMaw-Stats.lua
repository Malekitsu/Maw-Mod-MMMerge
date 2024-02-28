function events.CalcDamageToMonster(t)
	local data = WhoHitMonster()	
	--luck/accuracy bonus
	if data and data.Player and t.DamageKind==4 then
		if data.Object==nil or data.Object.Spell==133 then
			
			--OVERRIDE DAMAGE WITH MAW CALCULATION
			if data.Object==nil then
				baseDamage=t.Player:GetMeleeDamageMin()
				maxDamage=t.Player:GetMeleeDamageMax()
				randomDamage=math.random(baseDamage, maxDamage) + math.random(baseDamage, maxDamage)
				damage=math.round(randomDamage/2)
				dmgMult=damageMultiplier[t.PlayerIndex]["Melee"]
			else --bow
				baseDamage=t.Player:GetRangedDamageMin()
				maxDamage=t.Player:GetRangedDamageMax()
				randomDamage=math.random(baseDamage, maxDamage) + math.random(baseDamage, maxDamage)
				damage=math.round(randomDamage/2)
				dmgMult=damageMultiplier[t.PlayerIndex]["Ranged"]
			end
			
			t.Result=damage*dmgMult

			luck=data.Player:GetLuck()/1.5
			critDamage=data.Player:GetAccuracy()*3/1000
			critChance=50+luck
			--dagger bonus
			daggerCritBonus=0
			for i=0,1 do
				if data.Player:GetActiveItem(i) and data.Object==nil then
					itSkill=data.Player:GetActiveItem(i):T().Skill
					if itSkill==2 then
						s,m=SplitSkill(data.Player:GetSkill(const.Skills.Dagger))
						if m>2 then
							daggerCritBonus=daggerCritBonus+25+5*s
						end
					end
				end
			end
			roll=math.random(1, 1000)-daggerCritBonus
			if roll <= critChance then
				t.Result=t.Result*(1.5+critDamage)
				crit=true
			end
			if data.Player.Weak>0 then
				t.Result=t.Result*0.5
			end
		end
	end
end

--speed
--SPEED WILL NOW REDUCE RECOVERY TIME
masteryName={"Normal", "Expert", "Master", "GM"}
oldTable={}
function events.GameInitialized2()
	for i=0,132 do 
		oldTable[i]={}
		for v=1,4 do
			oldTable[i][v]=Game.Spells[i]["Delay" .. masteryName[v]]
		end
	end
end
function events.PlayerCastSpell(t)
	local spell=t.SpellId
	local m=t.Mastery
	local haste=math.floor(t.Player:GetSpeed()/10)
	Game.Spells[spell]["Delay" .. masteryName[m]]=oldTable[spell][m]/(1+haste/100)
end

--remove AC from hit calculation and unarmed code from misctweaks
nextACToZero=0
acNerf=0
function events.PlayerAttacked(t)
	if t.Attacker.MonsterAction==0 then
		ac=t.Player:GetArmorClass()
		if t.Attacker.Monster.Attack1.Type~=4 then
			nextACToZero=2
		elseif Game.BolsterAmount>100 then
			acNerf=2
			nerfAmount=Game.BolsterAmount/100
		end
	elseif t.Attacker.MonsterAction==1 then
		if t.Attacker.Monster.Attack2.Type~=4 then
			nextACToZero=2
		elseif Game.BolsterAmount>100 then
			acNerf=2
			nerfAmount=Game.BolsterAmount/100
		end
	end
end

function events.GetArmorClass(t)
	if nextACToZero>0 then
		t.AC=0
		nextACToZero=nextACToZero-1
	elseif acNerf>0 then
		t.AC=t.AC/nerfAmount
		acNerf=acNerf-1
	end
	if t.AC==10000 then
		t.AC=ac
	end
end

function events.CalcDamageToPlayer(t)
	--UNARMED bonus 
	unarmed=0
	Skill, Mas = SplitSkill(t.Player:GetSkill(const.Skills.Unarmed))
	if Mas == 4 then
		unarmed=Skill+10
	end
	dodgeChance=1-0.995^(unarmed)
	roll=math.random()
	if roll<=dodgeChance then
		t.Result=0
		evt.FaceExpression{Player = t.PlayerIndex, Frame = 33}
	end
end

--intellect/personality
function events.CalcSpellDamage(t)
	local data = WhoHitMonster()
	if data and data.Player and (data.Player.Class==10 or data.Player.Class==11 or table.find(dkClass, data.Player.Class)) then return end
	if data and data.Player then
		if data.Player.Class==10 or data.Player.Class==11 then return end --dragons scale off might
		intellect=data.Player:GetIntellect()	
		personality=data.Player:GetPersonality()
		critChance=data.Player:GetLuck()/1500
		bonus=math.max(intellect,personality)
		critDamage=bonus*3/2000
		t.Result=t.Result*(1+bonus/1000) 
		critChance=50+critChance*100
		roll=math.random(1, 1000)
		if roll <= critChance then
			t.Result=t.Result*(1.5+critDamage)
			crit=true
		end
	end
end


--body building description
function events.GameInitialized2()
	Game.SkillDescriptions[27]=Game.SkillDescriptions[27] .. "\n\nHit Points are also increased by an amount equal to Skill^2 divided by 2"
end

function events.BuildStatInformationBox(t)
	if t.Stat==0 then
		i=Game.CurrentPlayer
		might=Party[i]:GetMight()
		t.Text=string.format("%s\n\nBonus Melee/Bow Damage: %s%s",Game.StatsDescriptions[0],might/10,"%")
	end
	if t.Stat==1 then
		i=Game.CurrentPlayer
		meditation=Party[i].Skills[25]%64
		fullSP=Party[i]:GetFullSP()
		personality=Party[i]:GetPersonality()
		intellect=Party[i]:GetIntellect()
		t.Text=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage/healing: %s%s\nCritical heal effect is halved in Nightmare",Game.StatsDescriptions[1],intellect/10,"%",intellect*3/20+50,"%")
	end
	if t.Stat==2 then
		i=Game.CurrentPlayer
		personality=Party[i]:GetPersonality()
		t.Text=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage/healing bonus: %s%s\nCritical heal effect is halved in Nightmare",Game.StatsDescriptions[2],personality/10,"%",personality*3/20+50,"%")
	end
	if t.Stat==3 then
		i=Game.CurrentPlayer
		endurance=Party[i]:GetEndurance()
		HPScaling=Game.Classes.HPFactor[Party[i].Class]
		level=Party[i]:GetLevel()
		t.Text=string.format("%s\n\nHealth bonus from Endurance: %s%s\n\nFlat HP bonus from Endurance: %s",Game.StatsDescriptions[3],endurance/10,"%",math.floor(endurance/5)*HPScaling)
	end
	if t.Stat==4 then
		i=Game.CurrentPlayer
		accuracy=Party[i]:GetAccuracy()
		t.Text=string.format("%s\n\nCritical melee and bow strike damage bonus: %s%s",Game.StatsDescriptions[4],accuracy*3/10+50,"%")
	end
	if t.Stat==5 then
		i=Game.CurrentPlayer
		speed=Party[i]:GetSpeed()
		unarmed=0
		Skill, Mas = SplitSkill(Party[i]:GetSkill(const.Skills.Unarmed))
		if Mas == 4 then
			unarmed=Skill+10
			dodgeChance=1-0.995^(unarmed)
			t.Text=string.format("%s\n\nDodge chance: %s%%",Game.StatsDescriptions[5],math.floor(dodgeChance*1000)/10)
		end
		--spell haste
		speed=Party[i]:GetSpeed()
		speedEffect=math.floor(speed/10)
		--melee haste
		delay=math.max(Party[i]:GetAttackDelay())
		meleeHaste=bonusSpeed
		--bow haste
		delay=Party[i]:GetAttackDelay(true)
		bowHaste=bonusSpeed
		t.Text=string.format("%s\n\nMelee Haste:   %s%%\nRanged Haste: %s%%\nSpell Haste:   %s%%",t.Text,meleeHaste,bowHaste,speedEffect)
	end
	if t.Stat==6 then
		i=Game.CurrentPlayer
		luck=Party[i]:GetLuck()
		daggerCritBonus=0
		for v=0,1 do
			if Party[i]:GetActiveItem(v) then
				itSkill=Party[i]:GetActiveItem(v):T().Skill
				if itSkill==2 then
					s,m=SplitSkill(Party[i]:GetSkill(const.Skills.Dagger))
					if m>2 then
						daggerCritBonus=daggerCritBonus+2.5+0.5*s
					end
				end
			end
		end
		t.Text=string.format("%s\n\nCritical strike chance: %s%%",Game.StatsDescriptions[6],math.round((luck/10*2/3+5)*100)/100)
		if daggerCritBonus>0 then
			
		t.Text=string.format("%s\n\nCritical strike chance: %s%%(%s%% with dagger)",Game.StatsDescriptions[6],math.round((luck/10*2/3+5)*100)/100, math.round((luck/10*2/3+5+daggerCritBonus)*100)/100)
		end
	end
	if t.Stat==7 then
		local index=Game.CurrentPlayer
		endurance2=Party[index]:GetEndurance()
		if endurance2<=21 then
			endEff=(endurance2-13)/2
		else
			endEff=math.floor(endurance2/5)
		end
		HPScaling=Game.Classes.HPFactor[Party[index].Class]
		skill=Party[index].Skills[const.Skills.Bodybuilding]
		s,m=SplitSkill(skill)
		if m==4 then
			m=5
		end
		BBHP=HPScaling*s*m+s^2/2
		fullHP=Party[index]:GetFullHP()
		enduranceTotalBonus=math.round(fullHP-fullHP/(1+endurance2/1000))+endEff*HPScaling
		level=Party[index]:GetLevel()
		BASEHP=Game.Classes.HPBase[Party[index].Class]+level*HPScaling
		--hp regen calculation
		local i=Game.CurrentPlayer
		local FHP=Party[i]:GetFullHP()
		local skill=Party[i]:GetSkill(const.Skills.Regeneration)
		local s,m=SplitSkill(skill)
		if m==4 then
			m=5
		end
		local hpRegen = math.round(FHP^0.5*s^1.5*((m+1)/25))
		local HPregenItem=0
		local bonusregen=0
		for it in Party[i]:EnumActiveItems() do
			if it.Bonus2 == 37 or it.Bonus2==44 or it.Bonus2==50 or it.Bonus2==54 then	
				HPregenItem=HPregenItem+1
				bonusregen=1
			end
		end
		HPregenItem=HPregenItem
		regen=math.ceil(FHP*HPregenItem*0.02)+hpRegen+bonusregen
		
		Buff=Party[i].SpellBuffs[const.PlayerBuff.Regeneration]
		if Buff.ExpireTime > Game.Time then
			RegS, RegM = SplitSkill(Buff.Skill)
			regen = math.ceil(regen + FHP^0.5*RegS^1.3*((RegM+1)/100)) 
		end
	
		t.Text=string.format("%s\n\nHP bonus from Endurance: %s\nHP bonus from Body building: %s\nHP bonus from items: %s\nBase HP: %s\n\n HP Regen per second: %s",t.Text,StrColor(0,255,0,enduranceTotalBonus), StrColor(0,255,0,BBHP),StrColor(0,255,0,math.round(fullHP-enduranceTotalBonus-BBHP-BASEHP)),StrColor(0,255,0,BASEHP),StrColor(0,255,0,regen/10))
	end
	if t.Stat==8 then
		local i=Game.CurrentPlayer
		local fullSP=Party[i]:GetFullSP()
		local skill=Party[i]:GetSkill(const.Skills.Meditation)
		local s,m=SplitSkill(skill)
		if m==4 then
			m=5
		end
		local medRegen = math.round(fullSP^0.35*s^1.4*(m+5)/50)+2
		local SPregenItem=0
		local bonusregen=0
		for it in Party[i]:EnumActiveItems() do
			if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 then		
				SPregenItem=SPregenItem+1
				bonusregen=1
			end
		end
		SPregenItem=SPregenItem
		regen=math.ceil(fullSP*SPregenItem*0.01)+medRegen+bonusregen
		t.Text=string.format("%s\n\nSpell point regen per second: %s",t.Text,StrColor(40,100,255,regen/10))
	end
	
	if t.Stat==9 then
		i=Game.CurrentPlayer
		ac=Party[i]:GetArmorClass()
		local lvl=math.min(Party[i].LevelBase,200)
		local acReduction=100-calcMawDamage(Party[i],4,10000)/100
		lvl=math.min(Party[i].LevelBase, 255)
		if Game.BolsterAmount>100 then
			nerfAmount=Game.BolsterAmount/100
			ac=ac/nerfAmount
		end
		blockChance= 100-math.round((5+lvl*2)/(10+lvl*2+ac)*10000)/100
		totRed= 100-math.round((100-blockChance)*(100-acReduction))/100
		t.Text=string.format("%s\n\nPhysical damage reduction from AC: %s%s",t.Text,StrColor(255,255,100,acReduction),StrColor(255,255,100,"%") .. "\nBlock chance vs same level monsters (up to 255): " .. StrColor(255,255,100,blockChance) .. StrColor(255,255,100,"%") .. "\n\nTotal average damage reduction: " .. StrColor(255,255,100,totRed) .. "%")
	end
	
	if t.Stat==5234672 then
		i=Game.CurrentPlayer
		--get spell and its damage
		spellIndex=Party[i].QuickSpell
		
		--if not an offensive spell then calculate highest between melee and ranged
		if not spellPowers[spellIndex] then 
			--MELEE
			local i=Game.CurrentPlayer
			local low=Party[i]:GetMeleeDamageMin()
			local high=Party[i]:GetMeleeDamageMax()
			local might=Party[i]:GetMight()
			local accuracy=Party[i]:GetAccuracy()
			local luck=Party[i]:GetLuck()
			local delay=Party[i]:GetAttackDelay()
			local dmg=(low+high)/2
			--hit chance
			local atk=Party[i]:GetMeleeAttack()
			local lvl=Party[i].LevelBase
			local hitChance= (15+atk*2)/(30+atk*2+lvl)
			local daggerCritBonus=0
			for v=0,1 do
				if Party[i]:GetActiveItem(v) then
					itSkill=Party[i]:GetActiveItem(v):T().Skill
					if itSkill==2 then
						s,m=SplitSkill(Party[i]:GetSkill(const.Skills.Dagger))
						if m>2 then
							daggerCritBonus=daggerCritBonus+0.025+0.005*s
						end
					end
				end
			end
			DPS1=math.round(dmg*(1+(0.05+daggerCritBonus+0.01*luck/15)*(0.5+0.001*accuracy*3))/(delay/6000)*hitChance*damageMultiplier[Party[i]:GetIndex()]["Melee"])/100
			
			--RANGED
			local low=Party[i]:GetRangedDamageMin()
			local high=Party[i]:GetRangedDamageMax()
			local delay=Party[i]:GetAttackDelay(true)
			local dmg=(low+high)/2
			--hit chance
			local atk=Party[i]:GetRangedAttack()
			local hitChance= (15+atk*2)/(30+atk*2+lvl)
			
			local s,m=SplitSkill(Party[i].Skills[const.Skills.Bow])
			if m>=3 then
				dmg=dmg*2
			end
			local DPS2=math.round((dmg*(1+might/1000))*(1+(0.05+0.01*luck/15)*(0.5+0.001*accuracy*3))/(delay/6000)*hitChance*damageMultiplier[Party[i]:GetIndex()]["Ranged"])/100
			power=math.max(DPS1,DPS2)
			
			t.Text=string.format("%s\n\nPower: %s",t.Text,StrColor(255,0,0,power))
			return
		end
		
		--SPELLS
		local s, m =  SplitSkill(Party[i].Skills[const.Skills.Learning])
		diceMin, diceMax, damageAdd = ascendSpellDamage(s, m, spellIndex)
		--calculate damage
		--skill
		skillType=math.floor((spellIndex-1)/11)+12
		skill, mastery=SplitSkill(Party[i]:GetSkill(skillType))
		
		power=damageAdd + skill*(diceMin+diceMax)/2
		
		intellect=Party[i]:GetIntellect()	
		personality=Party[i]:GetPersonality()
		critChance=Party[i]:GetLuck()/1500
		bonus=math.max(intellect,personality)
		critDamage=bonus*3/2000
		power=power*(1+bonus/1000) 
		critChance=0.05+critChance
		haste=math.floor((Party[i]:GetSpeed())/10)/100+1
		delay=oldTable[spellIndex][mastery]
		power=math.round(power*(1+(0.05+critChance)*(0.5+critDamage))/(delay/6000)*haste)/100
		
		t.Text=string.format("%s\n\nSpellPower: %s",t.Text,StrColor(255,0,0,power))
		
	end
	
	if t.Stat==11 then
		local i=Game.CurrentPlayer
		local fullHP=Party[i]:GetFullHP()
		--AC
		local ac=Party[i]:GetArmorClass()
		local lvl=math.min(Party[i].LevelBase,200)
		local acReduction=1-calcMawDamage(t.Player,4,10000)/10000
		local lvl=math.min(Party[i].LevelBase, 255)
		local ac=ac/(Game.BolsterAmount/100)
		local blockChance= 1-(5+lvl*2)/(10+lvl*2+ac)
		local ACRed= 1 - (1-blockChance)*(1-acReduction)
		--unarmed
		local speed=Party[i]:GetSpeed()
		local unarmed=0
		local Skill, Mas = SplitSkill(Party[i]:GetSkill(const.Skills.Unarmed))
		if Mas == 4 then
			unarmed=Skill+10
		end
		--local speed=Party[i]:GetSpeed()
		--local speedEffect=speed/10
		local dodgeChance=0.995^(unarmed)
		local fullHP=fullHP/dodgeChance
		--resistances
		res={0,1,2,3,7,8,12}
		for i=1,7 do 
			res[i]=1-calcMawDamage(t.Player,res[i],10000)/10000
		end
		
		--calculation
		local reduction= 1 - (ACRed/2 + res[1]/16 + res[2]/16 + res[3]/16 + res[4]/16 + res[5]/16 + res[6]/16 + res[7]/8)
		vitality=math.round(fullHP/reduction)	
		t.Text=string.format("%s\n\nVitality: %s",t.Text,StrColor(0,255,0,vitality))
	end
	
	if t.Stat==13 or t.Stat==14 then
		local bolsterLevel8=vars.MM7LVL+vars.MM6LVL
		local bolsterLevel7=vars.MM8LVL+vars.MM6LVL
		local bolsterLevel6=vars.MM8LVL+vars.MM7LVL
		local bolsterLevel8=math.max(bolsterLevel8-4,0)
		local bolsterLevel7=math.max(bolsterLevel7-4,0)
		local bolsterLevel6=math.max(bolsterLevel6-4,0)
		t.Text=t.Text .."\n\nLevels gained in MM6: " .. StrColor(255,255,153,math.round(vars.MM6LVL*100)/100) .. "\nLevels gained in MM7: " .. StrColor(255,255,153,math.round(vars.MM7LVL*100)/100) .. "\nLevels gained in MM8: " .. StrColor(255,255,153,math.round(vars.MM8LVL*100)/100) .. "\n\nBolster Level in MM6: " .. StrColor(255,255,153,math.round(bolsterLevel6)) .."\nBolster Level in MM7: " .. StrColor(255,255,153,math.round(bolsterLevel7)) .."\nBolster Level in MM8: " .. StrColor(255,255,153,math.round(bolsterLevel8))
	end
	if t.Stat==15 then
		local i=Game.CurrentPlayer
		local atk=Party[i]:GetMeleeAttack()
		local lvl=Party[i].LevelBase
		local hitChance= math.round((15+atk*2)/(30+atk*2+lvl)*10000)/100
		t.Text=string.format("%s\n\nHit chance vs same level monster: %s%s",t.Text,StrColor(255,255,100,hitChance),StrColor(255,255,100,"%"))
	end
	
	if t.Stat==16 then
		local i=Game.CurrentPlayer
		local low=Party[i]:GetMeleeDamageMin()
		local high=Party[i]:GetMeleeDamageMax()
		local might=Party[i]:GetMight()
		local accuracy=Party[i]:GetAccuracy()
		local luck=Party[i]:GetLuck()
		local delay=Party[i]:GetAttackDelay()
		local dmg=(low+high)/2
		--hit chance
		local atk=Party[i]:GetMeleeAttack()
		local lvl=Party[i].LevelBase
		local hitChance= (15+atk*2)/(30+atk*2+lvl)
		local daggerCritBonus=0
		for v=0,1 do
			if Party[i]:GetActiveItem(v) then
				itSkill=Party[i]:GetActiveItem(v):T().Skill
				if itSkill==2 then
					s,m=SplitSkill(Party[i]:GetSkill(const.Skills.Dagger))
					if m>2 then
						daggerCritBonus=daggerCritBonus+0.025+0.005*s
					end
				end
			end
		end
		--damage tracker
		local DPS=math.round(dmg*(1+(0.05+daggerCritBonus+0.01*luck/15)*(0.5+0.001*accuracy*3))/(delay/6000)*hitChance*damageMultiplier[Party[i]:GetIndex()]["Melee"])/100
		t.Text=string.format("%s\n\nDamage per second: %s",t.Text,StrColor(255,255,100,DPS))
		vars.damageTrack=vars.damageTrack or {}
		vars.damageTrack[Party[i]:GetIndex()]=vars.damageTrack[Party[i]:GetIndex()] or 0
		mapvars.damageTrack=mapvars.damageTrack or {}
		mapvars.damageTrack[Party[i]:GetIndex()]=mapvars.damageTrack[Party[i]:GetIndex()] or 0
		local damage= vars.damageTrack[Party[Game.CurrentPlayer]:GetIndex()] or 0
		t.Text=string.format("%s\n\nTotal Damage done: %s",t.Text,StrColor(255,255,100,math.round(damage)))
		local damage= mapvars.damageTrack[Party[Game.CurrentPlayer]:GetIndex()] or 0
		t.Text=string.format("%s\nDamage done in current map: %s",t.Text,StrColor(255,255,100,math.round(damage)))
	end
	
	
	
	if t.Stat==17 then
		local i=Game.CurrentPlayer
		local atk=Party[i]:GetRangedAttack()
		local lvl=Party[i].LevelBase
		local hitChance= math.round((15+atk*2)/(30+atk*2+lvl)*10000)/100
		t.Text=string.format("%s\n\nHit chance vs same level monster: %s%s",t.Text,StrColor(255,255,100,hitChance),StrColor(255,255,100,"%"))
	end
	
	if t.Stat==18 then
		local i=Game.CurrentPlayer
		local low=Party[i]:GetRangedDamageMin()
		local high=Party[i]:GetRangedDamageMax()
		local might=Party[i]:GetMight()
		local accuracy=Party[i]:GetAccuracy()
		local luck=Party[i]:GetLuck()
		local delay=Party[i]:GetAttackDelay(true)
		local dmg=(low+high)/2
		--hit chance
		local atk=Party[i]:GetRangedAttack()
		local lvl=Party[i].LevelBase
		local hitChance= (15+atk*2)/(30+atk*2+lvl)
		local DPS=math.round(dmg*(1+(0.05+0.01*luck/15)*(0.5+0.001*accuracy*3))/(delay/6000)*hitChance*damageMultiplier[Party[i]:GetIndex()]["Ranged"])/100
		local s,m=SplitSkill(Party[i].Skills[const.Skills.Bow])
		if m>=3 then
			DPS=DPS*2
		end
		t.Text=string.format("%s\n\nDamage per second: %s",t.Text,StrColor(255,255,100,DPS))
		vars.damageTrackRanged=vars.damageTrackRanged or {}
		vars.damageTrackRanged[Party[i]:GetIndex()]=vars.damageTrackRanged[Party[i]:GetIndex()] or 0
		mapvars.damageTrackRanged=mapvars.damageTrackRanged or {}
		mapvars.damageTrackRanged[Party[i]:GetIndex()]=mapvars.damageTrackRanged[Party[i]:GetIndex()] or 0
		local damage= vars.damageTrackRanged[Party[Game.CurrentPlayer]:GetIndex()] or 0
		t.Text=string.format("%s\n\nTotal Ranged Damage done: %s",t.Text,StrColor(255,255,100,math.round(damage)))
		local damage= mapvars.damageTrackRanged[Party[Game.CurrentPlayer]:GetIndex()] or 0
		t.Text=string.format("%s\nRanged Damage done in current map: %s",t.Text,StrColor(255,255,100,math.round(damage)))
	end
	
	if t.Stat>=19 and t.Stat<=24 then
		t.Text=t.Text .. "\n\nDamage is reduced by an amount equal to % shown.\nMax resistance is 93.75%(beside immune status)\n\nLight resistance is equal to the lowest between Mind and Body resistances.\nDark resistance is equal to the lowest between elemental resistances\nEnergy resistance is equal to the lowest resistance"
	end
end

function events.Regeneration(t)
	--HP
	if t.PlayerIndex<=Party.High then
		totHP=Party[t.PlayerIndex]:GetFullHP()
			for it in Party[t.PlayerIndex]:EnumActiveItems() do
				if it.Bonus2 == 37 or it.Bonus2==44 or it.Bonus2==50 or it.Bonus2==54 then			
					t.HP=t.HP+math.max(totHP*0.01-1,0)
				end
			end
		t.HP=math.round(t.HP)
		--SP
		totSP=Party[t.PlayerIndex]:GetFullSP()
			for it in Party[t.PlayerIndex]:EnumActiveItems() do
				if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 then		
					t.SP=t.SP+math.max(totSP*0.01-1,0)
				end
			end
		t.SP=math.round(t.SP)
	end
end




--reduce damage by %
function events.CalcDamageToPlayer(t)

	data=WhoHitPlayer()
	pl=t.Player
	
	
	if t.Damage==0 and t.Result==0 then return end
	--works for attack 1 and 2
	if data and data.Monster then --manually recalculate monster damage
		if data.MonsterAction<=1 then
			local atk=data.Monster["Attack" .. data.MonsterAction+1]
			local damage=atk.DamageAdd
			for i=1,atk.DamageDiceCount do
				damage=damage+math.random(1, atk.DamageDiceSides)
			end
			t.Damage=damage
			if data and data.Object then
				if data.Object.Spell==0 then
					if pl:GetActiveItem(0) then
						local n=pl:GetActiveItem(0).Number
						if Game.ItemsTxt[n].Skill==const.Skills.Shield then --shield skill
							s,m=SplitSkill(t.Player.Skills[const.Skills.Shield])
							if m>=4 then
								t.Damage=t.Damage*0.85
							end
						end
					end
					if pl.SpellBuffs[11].ExpireTime>Game.Time or Party.SpellBuffs[14].ExpireTime>Game.Time  then --shield buff
						t.Damage=t.Damage*0.85
					end
				end
			end	
		end
	end
	
	if t.DamageKind==4 and pl.SpellBuffs[26].ExpireTime>Game.Time then --mistform 
		t.Damage=t.Damage*0.25
	end
	--recalculate spells damage
	if data and data.Monster and data.Object and data.Object.Spell<100 and data.Object.Spell>0 then
		local skill=SplitSkill(data.Monster.SpellSkill)
		damage=Game.Spells[data.Object.Spell].DamageAdd
		if skill>0 then
			for i=1,skill do 
				damage=damage+math.random(1,Game.Spells[data.Object.Spell].DamageDiceSides)
			end
			t.Result=damage
			t.Damage=damage
			if t.DamageKind==4 then
				t.DamageKind=3
			end
		end
	end
	
	--properly calculate friendly fire damage
	if data and data.Player and data.Spell then	
		local s,m = SplitSkill(data.Player.Skills[const.Skills.Learning])
		local diceMin, diceMax, damageAdd = ascendSpellDamage(s, m, data.Spell)
		local damage=damageAdd
		for i=1, data.SpellSkill do
			damage=damage+math.random(diceMin,diceMax)
		end
		local distance=getDistance(data.Object.X,data.Object.Y,data.Object.Z)/512
		local damageMult=math.max(1-distance, 0)
		damage=damage*damageMult
		
		--no crit nor intellect buff
		t.Result=calcMawDamage(t.Player,t.DamageKind,damage,false,data.Player.LevelBase)
		return
	end
	--fix for multiplayer
	local REMOTE_OWNER_BIT = 0x800
	local source = WhoHitPlayer()
	if source then
	local obj = source.Object
		if obj and bit.And(obj.Bits, REMOTE_OWNER_BIT) > 0 then
			return
		end
	end
	
	--apply Damage
	--modify spell damage as it's not handled in maw-monsters
	data=WhoHitPlayer()
	if data and data.Monster and data.Object and data.Object.Spell<100 and data.Object.Spell>0 then
		oldLevel=BLevel[data.Monster.Id]
		local i=data.Monster.Id
		if i%3==1 then
			levelMult=Game.MonstersTxt[i+1].Level
		elseif i%3==0 then
			levelMult=Game.MonstersTxt[i-1].Level
		else
			levelMult=Game.MonstersTxt[i].Level
		end
		dmgMult=(levelMult/12+1.15)*((levelMult+10)/(oldLevel+10))*(1+(levelMult/200))
		t.Damage=t.Result*dmgMult
	end
	if data and data.Monster and data.Object and data.Object.Spell<100 and data.Object.Spell>0 then
		t.Result = calcMawDamage(t.Player,t.DamageKind,t.Damage,true,data.Monster.Level)
	elseif data and data.Monster then
		t.Result = calcMawDamage(t.Player,t.DamageKind,t.Damage,false,data.Monster.Level)
	else
		t.Result = calcMawDamage(t.Player,t.DamageKind,t.Damage,true)
	end
	--add difficulty related damage
	if Game.BolsterAmount%50~=0 or Game.BolsterAmount==0 then
		Game.BolsterAmount=100
	end
	--easy
	if Game.BolsterAmount==50 then
		t.Result=t.Result*0.7
	end
	--MAW
	if Game.BolsterAmount==100 then
		t.Result=t.Result*1
	end
	--Hard
	if Game.BolsterAmount==150 then
		t.Result=t.Result*1.5
	end
	--Hell
	if Game.BolsterAmount==200 then
		t.Result=t.Result*2
	end
	if Game.BolsterAmount==300 then
		if data and data.Monster then
			t.Result=t.Result*3
		elseif t.DamageKind~=4 and t.DamageKind~=2 then --drown and fall
			name=Game.MapStats[Map.MapStatsIndex].Name
			local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
			if currentWorld==1 then
				bolster=vars.MM6LVL+vars.MM7LVL
			elseif currentWorld==2 then
				bolster=vars.MM8LVL+vars.MM6LVL
			elseif currentWorld==3 then
				bolster=vars.MM8LVL+vars.MM7LVL
			else 
				bolster=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
			end
			mapLevel=bolster+(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3
			--trap and objects multiplier
			mult=(mapLevel/20+1)*3
			if data and data.Object and data.Object.SpellType==15 then 
				bonusDamage=mapLevel/24
			else
				bonusDamage=mapLevel/8
			end
			damage=(t.Damage+bonusDamage)*mult
			t.Result=math.min(calcMawDamage(t.Player,t.DamageKind,damage),mapLevel*10)
		end
	end
end

--TOOLTIPS
function events.Tick()
	if Game.CurrentCharScreen==100 and Game.CurrentScreen==7 then
		i=Game.CurrentPlayer 
		if i==-1 then return end --prevent bug message
		fireRes=Party[i]:GetResistance(10)
		airRes=Party[i]:GetResistance(11)
		waterRes=Party[i]:GetResistance(12)
		earthRes=Party[i]:GetResistance(13)
		mindRes=Party[i]:GetResistance(14)
		bodyRes=Party[i]:GetResistance(15)
		lvl=math.min(Party[i].LevelBase/1.6,125)
		fireRes=100-math.max(math.round(calcMawDamage(Party[i],0,1000))/10, 0)
		airRes=100-math.max(math.round(calcMawDamage(Party[i],1,1000))/10, 0)
		waterRes=100-math.max(math.round(calcMawDamage(Party[i],2,1000))/10, 0)
		earthRes=100-math.max(math.round(calcMawDamage(Party[i],3,1000))/10, 0)
		mindRes=100-math.max(math.round(calcMawDamage(Party[i],7,1000))/10, 0)
		bodyRes=100-math.max(math.round(calcMawDamage(Party[i],8,1000))/10, 0)
		--[[calculate new resistances
		fireRes=math.round((100-100/2^(fireRes/(75+lvl/1.6)))*100)/100
		airRes=math.round((100-100/2^(airRes/(75+lvl/1.6)))*100)/100
		waterRes=math.round((100-100/2^(waterRes/(75+lvl/1.6)))*100)/100
		earthRes=math.round((100-100/2^(earthRes/(75+lvl/1.6)))*100)/100
		mindRes=math.round((100-100/2^(mindRes/(75+lvl/1.6)))*100)/100
		bodyRes=math.round((100-100/2^(bodyRes/(75+lvl/1.6)))*100)/100
		]]
		if fireRes>=93.75 then
			fireRes=StrColor(0,255,0,"Max")
		end
		if airRes>=93.75 then
			airRes=StrColor(0,255,0,"Max")
		end
		if waterRes>=93.75 then
			waterRes=StrColor(0,255,0,"Max")
		end
		if earthRes>=93.75 then
			earthRes=StrColor(0,255,0,"Max")
		end
		if mindRes>=93.75 then
			mindRes=StrColor(0,255,0,"Max")
		end
		if bodyRes>=93.75 then
			bodyRes=StrColor(0,255,0,"Max")
		end		
		Game.GlobalTxt[87]=StrColor(255, 70, 70,    string.format("Fire\t            %s%s",fireRes,"%"))
		Game.GlobalTxt[6]=StrColor(173, 216, 230,   string.format("Air\t            %s%s",airRes,"%"))
		Game.GlobalTxt[240]=StrColor(100, 180, 255, string.format("Water\t            %s%s",waterRes,"%"))
		Game.GlobalTxt[70]=StrColor(153, 76, 0,     string.format("Earth\t            %s%s",earthRes,"%"))
		Game.GlobalTxt[142]=StrColor(200, 200, 255, string.format("Mind\t            %s%s",mindRes,"%"))
		Game.GlobalTxt[29]=StrColor(255, 192, 203,  string.format("Body\t            %s%s",bodyRes,"%"))	
		statsChanged=true
	elseif statsChanged and (Game.CurrentCharScreen~=100 or Game.CurrentScreen~=7) then
		Game.GlobalTxt[87]="Fire"
		Game.GlobalTxt[6]="Air"
		Game.GlobalTxt[240]="Water"
		Game.GlobalTxt[70]="Earth"
		Game.GlobalTxt[142]="Mind"
		Game.GlobalTxt[29]="Body"
		statsChanged=false
	end
end


damageKindMap={
	[0]=const.Damage.Fire,
	[1]=const.Damage.Air,
	[2]=const.Damage.Water,
	[3]=const.Damage.Earth,
	[4]=const.Damage.Phys,
	[6]=const.Damage.Spirit,
	[7]=const.Damage.Mind,
	[8]=const.Damage.Body,
	[9]=const.Damage.Light,
	[10]=const.Damage.Dark,
}
function events.CalcDamageToMonster(t)
	index=table.find(damageKindMap,t.DamageKind)
	res=t.Monster.Resistances[index]
	if not res then return end
	
	res=1-1/2^(res%1000/100)
	--randomize resistance
	if res>0 then
		--local roll=(math.random()+math.random())-1
		--res=math.max(0, res+(math.min(res,1-res)*roll))
	end
	--apply Damage
	t.Result = t.Result * (1-res)
end

--stats breakpoints
function events.GetStatisticEffect(t)
	if t.Value >=25 then
		t.Result=math.floor(t.Value/5)
	end
end

--recount
function events.CalcDamageToMonster(t)
	data=WhoHitMonster()
	if data and data.Player then
		local damage=math.round(t.Result)
		local damage=math.max(math.min(damage,32768),0)
		if data.Object then 
			vars.damageTrackRanged=vars.damageTrackRanged or {}
			vars.damageTrackRanged[data.Player:GetIndex()]=vars.damageTrackRanged[data.Player:GetIndex()] or 0
			vars.damageTrackRanged[data.Player:GetIndex()] = vars.damageTrackRanged[data.Player:GetIndex()] + damage
			mapvars.damageTrackRanged=mapvars.damageTrackRanged or {}
			mapvars.damageTrackRanged[data.Player:GetIndex()]=mapvars.damageTrackRanged[data.Player:GetIndex()] or 0
			mapvars.damageTrackRanged[data.Player:GetIndex()] = mapvars.damageTrackRanged[data.Player:GetIndex()] + damage
		else
			vars.damageTrack=vars.damageTrack or {}
			vars.damageTrack[data.Player:GetIndex()]=vars.damageTrack[data.Player:GetIndex()] or 0
			vars.damageTrack[data.Player:GetIndex()] = vars.damageTrack[data.Player:GetIndex()] + damage
			mapvars.damageTrack=mapvars.damageTrack or {}
			mapvars.damageTrack[data.Player:GetIndex()]=mapvars.damageTrack[data.Player:GetIndex()] or 0
			mapvars.damageTrack[data.Player:GetIndex()] = mapvars.damageTrack[data.Player:GetIndex()] + damage
		end
	end
	dmg=t.Result
end

--crit message
local hook, autohook, autohook2, asmpatch = mem.hook, mem.autohook, mem.autohook2, mem.asmpatch
local u1, u2, u4, i1, i2, i4 = mem.u1, mem.u2, mem.u4, mem.i1, mem.i2, mem.i4
local critAttackMsg = "" 
local critShootMsg = "" 
local critKillMsg = "" 

autohook(0x4376AC, function(d)
	local addr, result = u4[d.esp + 4]
	if addr == u4[0x6016D8] then -- attack
		result = mem.topointer(critAttackMsg)
	elseif addr == u4[0x60173C] then -- shoot
		result = mem.topointer(critShootMsg)
	elseif addr == u4[0x601704] then -- kill
		result = mem.topointer(critKillMsg)
	else
		error("Unknown attack message type")
	end
	u4[d.esp + 4] = result
	crit = false
end)

--resistance map
damageKindResistance={
	[0] = {10},
	[1] = {11},
	[2] = {12},
	[3] = {13},
	[6] = {14},
	[7] = {14},
	[8] = {15},
	[9] = {14,15},
	[10] = {10,11,12,13},
	[12] = {10,11,12,13,14,15},
}

function calcMawDamage(pl,damageKind,damage,rand,monLvl)
	monLvl=monLvl or pl.LevelBase
	bolster=(Game.BolsterAmount/100-1)/4+1
	
	--AC for phys
	if damageKind==4 then 
		extraACFromCAP=extraACFromCAP or 0
		local AC=pl:GetArmorClass()+extraACFromCAP
		local damage=math.round(damage/2^(math.min(AC/math.min(150+monLvl*bolster,400*bolster),4)))
		return damage
	end

	--get resistances
	if not damageKindResistance[damageKind] then
		local damage=math.round(damage)
		return damage
	end
	local res=math.huge
	local resList=damageKindResistance[damageKind]
	for i=1,#resList do
		local playerRes = pl:GetResistance(resList[i])
		if playerRes<res then
			res=playerRes
		end
	end
	
	res=1/2^math.min(res/math.min(75+monLvl*0.5*bolster,200*bolster),4)
	
	--randomize resistance
	if res>0 and rand then
		local roll=(math.random()+math.random())-1
		res=math.max(0, res+(math.min(res,1-res)*roll))
	end
	
	local damage=math.round(damage*res)
	return damage
end


--
function events.GameInitialized2()
	function events.CalcDamageToMonster(t)
		divide=1
		if t.Monster.Resistances[0]>=1000 then
			divide=2^math.floor(t.Monster.Resistances[0]/1000)
			t.Result=t.Result/divide
		end
		data=WhoHitMonster()
		if data and data.Player then
			MSGdamage=MSGdamage or 0
			MSGdamage=MSGdamage+math.ceil(t.Result)*divide
			attackIsSpell=false
			castedAoe=false
			shoot="hits"
			kill=""
			critMessage= ""
			if data.Object then 
				if data.Object.SpellType>1 and data.Object.SpellType<133 then
					name=Game.SpellsTxt[data.Object.SpellType].Name
					attackIsSpell=true
				else
					name=t.Player.Name
					shoot="shoots"
				end
			else
				name=t.Player.Name
			end
			if t.Result>t.Monster.HP then
				kill="killing"
				shoot="inflicts"
			end
			if crit then
				critMessage="critically"
			end
			if t.Monster.NameId>0 then
				monName=Game.PlaceMonTxt[t.Monster.NameId]
			else
				monName=Game.MonstersTxt[t.Monster.Id].Name
			end
			
			if crit then
				name=string.format(name .. " critically")
			end			
			if shoot=="shoots" then
				msg=string.format("%s shoots %s for %s points!", name, MSGdamage, monName)
			else
				msg=string.format("%s hits %s for %s points!", name, MSGdamage, monName)
			end
			if t.Result>t.Monster.HP then
				msg=string.format("%s inflicts %s points killing %s!", name, MSGdamage, monName)
			end
			calls=calls or 0
			calls=calls+1
			if calls>=2 and attackIsSpell then
				castedAoe=true
			end
			function events.Tick() 
				events.Remove("Tick", 1)
				if shoot=="shoots" then
				msg=string.format("%s shoots %s for %s points!", name, monName, MSGdamage)
				else
					msg=string.format("%s hits %s for %s points!", name, monName, MSGdamage)
				end
				if t.Result>t.Monster.HP then
					msg=string.format("%s inflicts %s points killing %s!", name, MSGdamage, monName)
				end
				if castedAoe then
					msg=string.format("%s hits for a total of %s points!", name, MSGdamage)
				end
				Game.ShowStatusText(msg)
				if calls>0 then
					calls=calls-1
				end
				if calls==0 then
					MSGdamage=0
				end
			end
		end	
	end

end

--[[
	function events.CalcDamageToMonster(t)
		data=WhoHitMonster()
		if data and data.Player then
			lastDamagingAttacker=lastDamagingAttacker or -1 
			id=data.Player:GetIndex()
			if lastDamagingAttacker~=id then
				lastDamagingAttacker=id
				MSGdamage=0
			end
			function events.Tick() 
				events.Remove("Tick", 1)
				if Game.CurrentPlayer==-1
			end
		end
	end
	]]



function events.Tick()
	if Game.CurrentCharScreen==100 and Game.CurrentScreen==7 then
		i=Game.CurrentPlayer
		--get spell and its damage
		spellIndex=Party[i].QuickSpell
		
		--if not an offensive spell then calculate highest between melee and ranged

			--MELEE
			local i=Game.CurrentPlayer
			local low=Party[i]:GetMeleeDamageMin()
			local high=Party[i]:GetMeleeDamageMax()
			local might=Party[i]:GetMight()
			local accuracy=Party[i]:GetAccuracy()
			local luck=Party[i]:GetLuck()
			local delay=Party[i]:GetAttackDelay()
			local dmg=(low+high)/2
			--hit chance
			local atk=Party[i]:GetMeleeAttack()
			local lvl=Party[i].LevelBase
			local hitChance= (15+atk*2)/(30+atk*2+lvl)
			local daggerCritBonus=0
			for v=0,1 do
				if Party[i]:GetActiveItem(v) then
					itSkill=Party[i]:GetActiveItem(v):T().Skill
					if itSkill==2 then
						s,m=SplitSkill(Party[i]:GetSkill(const.Skills.Dagger))
						if m>2 then
							daggerCritBonus=daggerCritBonus+0.025+0.005*s
						end
					end
				end
			end
			DPS1=math.round(dmg*(1+(0.05+daggerCritBonus+0.01*luck/15)*(0.5+0.001*accuracy*3))/(delay/60)*hitChance*damageMultiplier[Party[i]:GetIndex()]["Melee"])
			
			--RANGED
			local low=Party[i]:GetRangedDamageMin()
			local high=Party[i]:GetRangedDamageMax()
			local delay=Party[i]:GetAttackDelay(true)
			local dmg=(low+high)/2
			--hit chance
			local atk=Party[i]:GetRangedAttack()
			local hitChance= (15+atk*2)/(30+atk*2+lvl)
			
			local s,m=SplitSkill(Party[i].Skills[const.Skills.Bow])
			if m>=3 then
				dmg=dmg*2
			end
			local DPS2=math.round(dmg*(1+(0.05+0.01*luck/15)*(0.5+0.001*accuracy*3))/(delay/60)*hitChance*damageMultiplier[Party[i]:GetIndex()]["Ranged"])
                        if spellPowers[spellIndex] then 
			--SPELLS
			local s, m = SplitSkill(Party[i].Skills[const.Skills.Learning])
			diceMin, diceMax, damageAdd = ascendSpellDamage(s, m, spellIndex)
			--calculate damage
			--skill
			skillType=math.floor((spellIndex-1)/11)+12
			skill, mastery=SplitSkill(Party[i]:GetSkill(skillType))
			
			power=damageAdd + skill*(diceMin+diceMax)/2
			
			intellect=Party[i]:GetIntellect()	
			personality=Party[i]:GetPersonality()
			critChance=Party[i]:GetLuck()/1500
			bonus=math.max(intellect,personality)
			critDamage=bonus*3/2000
			power=power*(1+bonus/1000) 
			critChance=0.05+critChance
			haste=math.floor((Party[i]:GetSpeed())/10)/100+1
			delay=oldTable[spellIndex][mastery]
			DPS3=math.round(power*(1+(0.05+critChance)*(0.5+critDamage))/(delay/60)*haste)			
			Game.GlobalTxt[47]=string.format("M/R/S:%s/%s/%s\n\n\n\n\n\n\n",StrColor(255,0,0,DPS1),StrColor(200,200,0,DPS2),StrColor(50,50,220,DPS3))
		   else
		        Game.GlobalTxt[47]=string.format("M/R:%s/%s\n\n\n\n\n\n\n",StrColor(255,0,0,DPS1),StrColor(200,200,0,DPS2))
		    end
				
		local i=Game.CurrentPlayer
		local fullHP=Party[i]:GetFullHP()
		--AC
		local ac=Party[i]:GetArmorClass()
		local lvl=math.min(Party[i].LevelBase,200)
		local acReduction=1-calcMawDamage(Party[i],4,10000)/10000
		local lvl=math.min(Party[i].LevelBase, 255)
		local ac=ac/(Game.BolsterAmount/100)
		local blockChance= 1-(5+lvl*2)/(10+lvl*2+ac)
		local ACRed= 1 - (1-blockChance)*(1-acReduction)
		--unarmed
		local speed=Party[i]:GetSpeed()
		local unarmed=0
		local Skill, Mas = SplitSkill(Party[i]:GetSkill(const.Skills.Unarmed))
		if Mas == 4 then
			unarmed=Skill+10
		end
		--local speed=Party[i]:GetSpeed()
		--local speedEffect=speed/10
		local dodgeChance=0.995^(unarmed)
		local fullHP=fullHP/dodgeChance
		--resistances
		res={0,1,2,3,7,8,12}
		for v=1,7 do 
			res[v]=1-calcMawDamage(Party[i],res[v],10000)/10000
		end
		
		--calculation
		local reduction= 1 - (ACRed/2 + res[1]/16 + res[2]/16 + res[3]/16 + res[4]/16 + res[5]/16 + res[6]/16 + res[7]/8)
		vitality=math.round(fullHP/reduction)	
		Game.GlobalTxt[172]=string.format("Vitality: %s\n\n\n\n\n\n\n\n",StrColor(0,255,0,vitality))
	else
		Game.GlobalTxt[47]="Condition"
		Game.GlobalTxt[172]="Quick Spell"
	end
end
