function events.CalcDamageToMonster(t)
	local data = WhoHitMonster()	
	--luck/accuracy bonus
	if data and data.Player and t.DamageKind==4 then
		if data.Object==nil or data.Object.Spell==133 then
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
	--might bonus
			might=data.Player:GetMight()
			damageBonus=might/1000
			t.Result=t.Result*(1+damageBonus)
		end
	end
end

--speed
--remove AC from hit calculation and unarmed code from misctweaks
nextACToZero=0
function events.PlayerAttacked(t)
	if t.Attacker.Object then
		nextACToZero=2
	end
end

function events.GetArmorClass(t)
	if nextACToZero>0 then
		t.AC=0
		nextACToZero=nextACToZero-1
	end
	if t.AC==10000 then
		t.AC=t.Player:GetArmorClass()
	end
end

function events.CalcDamageToPlayer(t)
	--UNARMED bonus aswell
	unarmed=0
	Skill, Mas = SplitSkill(t.Player:GetSkill(const.Skills.Unarmed))
	if Mas == 4 then
		unarmed=Skill+10
	end
	speed=t.Player:GetSpeed()
	speedEffect=speed/10
	dodgeChance=1-0.995^(speedEffect+unarmed)
	roll=math.random()
	if roll<=dodgeChance then
		t.Result=0
		evt.FaceExpression{Player = t.PlayerIndex, Frame = 33}
	end
end

--intellect/personality
function events.CalcSpellDamage(t)
	local data = WhoHitMonster()
	if data and data.Player then
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
--AC 
function events.CalcDamageToPlayer(t)
	if t.DamageKind==4 then 
		AC=t.Player:GetArmorClass()
		t.Result=t.Result/(AC/300+1)
	end
end
--endurance
fullHP2={}
for i =0,300 do
fullHP2[i]=0
end

function events.CalcStatBonusByItems(t)
	if t.Stat == const.Stats.HP then
		endurance=t.Player:GetEndurance()/1000
		index2=t.PlayerIndex
		local skill=t.Player.Skills[const.Skills.Bodybuilding]
		local s,m=SplitSkill(skill)
		t.Result=t.Result+math.round(fullHP2[index2]*endurance)+s^2/2
	end
end

function events.Tick()
	for i=0,Party.High do
		endurance2=Party[i]:GetEndurance()
		if endurance2<=21 then
		endEff2=(endurance2-13)/2
		else
			endEff2=math.floor(endurance2/5)
		end
		local skill=Party[i].Skills[const.Skills.Bodybuilding]
		local s,m=SplitSkill(skill)
		if m==4 then
			m=5
		end
		BBHP=s*m
		index3=Party[i]:GetIndex()
		fullHP2[index3]=Game.Classes.HPFactor[Party[i].Class]*(Party[i]:GetLevel()+endEff2+BBHP)+Game.Classes.HPBase[Party[i].Class]+s^2/2
	end
end
--body building description
function events.GameInitialized2()
	Game.SkillDescriptions[27]=Game.SkillDescriptions[24] .. "\n\nHit Points are also increased by an amount equal to Skill^2 divided by 2"
end

function events.BuildStatInformationBox(t)
	if t.Stat==0 then
		i=Game.CurrentPlayer
		might=Party[i]:GetMight()
		t.Text=string.format("%s\n\nBonus Meele/Bow Damage: %s%s",Game.StatsDescriptions[0],might/10,"%")
	end
	if t.Stat==1 then
		i=Game.CurrentPlayer
		meditation=Party[i].Skills[25]%64
		fullSP=Party[i]:GetFullSP()
		personality=Party[i]:GetPersonality()
		intellect=Party[i]:GetIntellect()
		t.Text=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage/healing: %s%s",Game.StatsDescriptions[1],intellect/10,"%",intellect*3/20+50,"%")
	end
	if t.Stat==2 then
		i=Game.CurrentPlayer
		personality=Party[i]:GetPersonality()
		t.Text=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage/healing bonus: %s%s",Game.StatsDescriptions[2],personality/10,"%",personality*3/20+50,"%")
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
		end
		speed=Party[i]:GetSpeed()
		speedEffect=speed/10
		dodgeChance=1-0.995^(speedEffect+unarmed)
		t.Text=string.format("%s\n\nDodge chance: %s%s",Game.StatsDescriptions[5],math.floor(dodgeChance*1000)/10	,"%")
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
		t.Text=string.format("%s\n\nHP bonus from Endurance: %s\n\nHP bonus from Body building: %s\n\nHP bonus from items: %s\n\nBase HP: %s",t.Text,StrColor(0,255,0,enduranceTotalBonus), StrColor(0,255,0,BBHP),StrColor(0,255,0,math.round(fullHP-enduranceTotalBonus-BBHP-BASEHP)),StrColor(0,255,0,BASEHP))
	end
	if t.Stat==8 then
		local i=Game.CurrentPlayer
		local fullSP=Party[i]:GetFullSP()
		local skill=Party[i].Skills[const.Skills.Meditation]
		local s,m=SplitSkill(skill)
		if m==4 then
			m=5
		end
		local medRegen = math.round(fullSP^0.5*s^0.7*((m+5)/50))
		local SPregenItem=0
		local bonusregen=0
		for it in Party[i]:EnumActiveItems() do
			if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 then		
				SPregenItem=SPregenItem+1
				bonusregen=1
			end
		end
		SPregenItem=SPregenItem+bonusregen
		regen=math.ceil(fullSP*SPregenItem*0.005)+medRegen
		t.Text=string.format("%s\n\nSpell point regen per 10 seconds: %s",t.Text,StrColor(40,100,255,regen))
	end
	
	if t.Stat==9 then
		i=Game.CurrentPlayer
		ac=Party[i]:GetArmorClass()
		acReduction=math.round(1000-1000/(ac/300+1))/10
		lvl=math.min(Party[i].LevelBase, 255)
		blockChance= 100-math.round((5+lvl*2)/(10+lvl*2+ac)*10000)/100
		totRed= 100-math.round((100-blockChance)*(100-acReduction))/100
		t.Text=string.format("%s\n\nPhysical damage reduction from AC: %s%s",t.Text,StrColor(255,255,100,acReduction),StrColor(255,255,100,"%") .. "\nBlock chance vs same level monsters (up to 255): " .. StrColor(255,255,100,blockChance) .. StrColor(255,255,100,"%") .. "\n\nTotal average damage reduction: " .. StrColor(255,255,100,totRed) .. "%")
	end
	
	if t.Stat==11 then
		i=Game.CurrentPlayer
		--get spell and its damage
		spellIndex=Party[i].QuickSpell
		if not spellPowers[spellIndex] then return end --if not an offensive spell return
		spellTier=spellIndex%11
		if spellTier==0 then
			spellTier=11
		end
		if Party[i].LevelBase>=spellTier*8+152 then
			diceMin=spellPowers160[spellIndex].diceMin
			diceMax=spellPowers160[spellIndex].diceMax
			damageAdd=spellPowers160[spellIndex].dmgAdd
		elseif Party[i].LevelBase>=spellTier*8+72 then
			diceMin=spellPowers80[spellIndex].diceMin
			diceMax=spellPowers80[spellIndex].diceMax
			damageAdd=spellPowers80[spellIndex].dmgAdd
		else
			diceMin=spellPowers[spellIndex].diceMin
			diceMax=spellPowers[spellIndex].diceMax
			damageAdd=spellPowers[spellIndex].dmgAdd
		end
		--calculate damage
		--skill
		skillType=math.floor(spellIndex/11)+12
		skill, mastery=SplitSkill(Party[i]:GetSkill(skillType))
		
		power=damageAdd + skill*(diceMin+diceMax)/2
		
		intellect=Party[i]:GetIntellect()	
		personality=Party[i]:GetPersonality()
		critChance=Party[i]:GetLuck()/1500
		bonus=math.max(intellect,personality)
		critDamage=bonus*3/2000
		power=power*(1+bonus/1000) 
		critChance=0.05+critChance
		delay=Game.Spells[11].DelayGM
		power=math.round(power*(1+(0.05+critChance)*(0.5+critDamage))/(delay/100))
		
		t.Text=string.format("%s\n\nPower: %s",t.Text,StrColor(255,0,0,power))
		
	end
	
	if t.Stat==5234672 then
		i=Game.CurrentPlayer
		fullHP=Party[i]:GetFullHP()
		--AC
		ac=Party[i]:GetArmorClass()
		acReduction=1-1/(ac/300+1)
		lvl=math.min(Party[i].LevelBase, 255)
		blockChance= 1-(5+lvl*2)/(10+lvl*2+ac)
		ACRed= 1 - (1-blockChance)*(1-acReduction)
		--speed
		speed=Party[i]:GetSpeed()
		unarmed=0
		Skill, Mas = SplitSkill(Party[i]:GetSkill(const.Skills.Unarmed))
		if Mas == 4 then
			unarmed=Skill+10
		end
		speed=Party[i]:GetSpeed()
		speedEffect=speed/10
		dodgeChance=0.995^(speedEffect+unarmed)
		fullHP=fullHP/dodgeChance
		--resistances
		res={}
		res[1]=t.Player:GetResistance(10)
		res[2]=t.Player:GetResistance(11)
		res[3]=t.Player:GetResistance(12)
		res[4]=t.Player:GetResistance(13)
		res[5]=t.Player:GetResistance(14)
		res[6]=t.Player:GetResistance(15)
		res[7]=math.min(res[1],res[2],res[3],res[4],res[5],res[6])
		for i=1,7 do 
			res[i]=1-1/2^(res[i]/100)
		end
		--calculation
		reduction= 1 - (ACRed/2 + res[1]/16 + res[2]/16 + res[3]/16 + res[4]/16 + res[5]/16 + res[6]/16 + res[7]/8)
		vitality=math.round(fullHP/reduction)	
		t.Text=string.format("%s\n\nVitality: %s",t.Text,StrColor(0,255,0,vitality))
	end
	
	if t.Stat==13 or t.Stat==14 then
		bolsterLevel8=vars.MM7LVL+vars.MM6LVL
		bolsterLevel7=vars.MM8LVL+vars.MM6LVL
		bolsterLevel6=vars.MM8LVL+vars.MM7LVL
		bolsterLevel8=math.max(bolsterLevel8*0.95-4,0)
		bolsterLevel7=math.max(bolsterLevel7*0.95-4,0)
		bolsterLevel6=math.max(bolsterLevel6*0.95-4,0)
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
		local DPS=math.round((dmg*(1+might/1000))*(1+(0.05+daggerCritBonus+0.01*luck/15)*(0.5+0.001*accuracy*3))/(delay/100)*hitChance)
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
		local delay=Party[i]:GetAttackDelay()
		local dmg=(low+high)/2
		--hit chance
		local atk=Party[i]:GetRangedAttack()
		local lvl=Party[i].LevelBase
		local hitChance= (15+atk*2)/(30+atk*2+lvl)
		local DPS=math.round((dmg*(1+might/1000))*(1+(0.05+0.01*luck/15)*(0.5+0.001*accuracy*3))/(delay/100)*hitChance)
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
		t.Text=t.Text .. "\n\nDamage is reduced by an amount equal to % shown above.\nMax resistance is 75%(beside immune status) and can be increased with some special enchants\n\nLight resistance is equal to the lowest between Mind and Body resistances.\nDark resistance is equal to the lowest between elemental resistances\nEnergy resistance is equal to the lowest resistance"
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


--resistance map
damageKindToMaxResistanceEnchant={
	[0] = 74,
	[1] = 75,
	[2] = 76,
	[3] = 77,
	[7] = 78,
	[8] = 79,
}

--reduce damage by %
function events.CalcDamageToPlayer(t)
	--recalculate skill
	data=WhoHitPlayer()
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
	if t.Result<1 then return end
	if t.DamageKind==0 or t.DamageKind==1 or t.DamageKind==2 or t.DamageKind==3 or t.DamageKind==7 or t.DamageKind==8 or t.DamageKind==9 or t.DamageKind==10 or t.DamageKind==12 then
		
		--get resistances
		if t.DamageKind==0 then
			res=t.Player:GetResistance(10)
		end
		if t.DamageKind==1 then
			res=t.Player:GetResistance(11)
		end
		if t.DamageKind==2 then
			res=t.Player:GetResistance(12)
		end
		if t.DamageKind==3 then
			res=t.Player:GetResistance(13)
		end
		if t.DamageKind==7 then
			res=t.Player:GetResistance(14)
		end
		if t.DamageKind==8 then
			res=t.Player:GetResistance(15)
		end
		if t.DamageKind==9 then
			res=math.min(t.Player:GetResistance(14),t.Player:GetResistance(15))
		end
		if t.DamageKind==10 then
			res=math.min(t.Player:GetResistance(10),t.Player:GetResistance(11),t.Player:GetResistance(12),t.Player:GetResistance(13))
		end
		if t.DamageKind==12 then
			res=math.min(t.Player:GetResistance(10),t.Player:GetResistance(11),t.Player:GetResistance(12),t.Player:GetResistance(13),t.Player:GetResistance(14),t.Player:GetResistance(15))
		end
		res=1-1/2^(res/100)
		--fix for multiplayer
		local REMOTE_OWNER_BIT = 0x800
		local source = WhoHitPlayer()
		if source then
		local obj = source.Object
			if obj and bit.And(obj.Bits, REMOTE_OWNER_BIT) > 0 then
				return
			end
		end
		
		--randomize resistance
		if res>0 then
			local roll=(math.random()+math.random())-1
			res=math.max(0, res+(math.min(res,1-res)*roll))
		end
		--apply Damage
		t.Result = t.Damage * (1-res)
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
			dmgMult=(levelMult/12+1)*((levelMult+2)/(oldLevel+2))
			t.Result=t.Result*dmgMult
		end
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
end

--add luck to resistances
function events.CalcStatBonusByItems(t)
	if t.Stat>=10 and t.Stat<=15 then
		luck=t.Player:GetLuck()
		if luck<=21 then
			luck=(luck-1)/2-6
		else
			luck=math.floor(luck/5)
		end
		t.Result=t.Result+luck
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
		
		--calculate new resistances
		fireRes=math.round((100-100/2^(fireRes/100))*100)/100
		airRes=math.round((100-100/2^(airRes/100))*100)/100
		waterRes=math.round((100-100/2^(waterRes/100))*100)/100
		earthRes=math.round((100-100/2^(earthRes/100))*100)/100
		mindRes=math.round((100-100/2^(mindRes/100))*100)/100
		bodyRes=math.round((100-100/2^(bodyRes/100))*100)/100
		
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
		Game.GlobalTxt[87]=StrColor(255, 70, 70, string.format("Fire %s%s",fireRes,"%"))
		Game.GlobalTxt[6]=StrColor(173, 216, 230, string.format("Air %s%s",airRes,"%"))
		Game.GlobalTxt[240]=StrColor(100, 180, 255, string.format("Water %s%s",waterRes,"%"))
		Game.GlobalTxt[70]=StrColor(153, 76, 0, string.format("Earth %s%s",earthRes,"%"))
		Game.GlobalTxt[142]=StrColor(200, 200, 255, string.format("Mind %s%s",mindRes,"%"))
		Game.GlobalTxt[29]=StrColor(255, 192, 203, string.format("Body %s%s",bodyRes,"%"))	
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
	--difficulty setting
	if Game.BolsterAmount%50~=0 or Game.BolsterAmount==0 then
		Game.BolsterAmount=100
	end
	--easy
	if Game.BolsterAmount==50 then
		t.Result=t.Result*1.5
	end
	--MAW
	if Game.BolsterAmount==100 then
		t.Result=t.Result*1
	end
	--Hard
	if Game.BolsterAmount==150 then
		t.Result=t.Result/1.4
	end
	--Hell
	if Game.BolsterAmount==200 then
		t.Result=t.Result/1.8
	end
	
	index=table.find(damageKindMap,t.DamageKind)
	res=t.Monster.Resistances[index]
	if not res then return end
	
	res=1-1/2^(res/100)
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
local critAttackMsg = "%s critically hits %s for %lu damage!" .. string.char(0)
local critShootMsg = "%s critically shoots %s for %lu points!" .. string.char(0)
local critKillMsg = "%s critically inflicts %lu points killing %s!" .. string.char(0)

local function isCrit()
	if crit then
		crit=false
		return true
	end
end

	
local crit = false
local function critProcHook(d)
	crit = isCrit()
end
autohook2(0x43703F, critProcHook) -- shoot (ranged)
autohook2(0x437148, critProcHook) -- spell
autohook2(0x437243, critProcHook) -- melee attack

autohook(0x4376AC, function(d)
	if not crit then return end
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


--decrease resistances based on bolster

function events.CalcStatBonusByItems(t)
	if t.Stat>9 and t.Stat<16 then
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
		partyLevel=math.max(partyLevel*0.95-4,0)
		penaltyLevel=math.round(partyLevel/5)*5
		penalty=math.min(penaltyLevel,200)
		t.Result=t.Result-penalty
	end
end
