if StatsRework then
function events.CalcDamageToMonster(t)
	local data = WhoHitMonster()	
	--luck/accuracy bonus
	if data and data.Player and t.DamageKind==4 then
		if data.Object==nil or data.Object.Spell==133 then
			luck=data.Player:GetLuck()
			accuracy=data.Player:GetAccuracy()
			critDamage=accuracy/250
			critChance=50+luck
			roll=math.random(1, 1000)
			if roll <= critChance then
				t.Result=t.Result*(1.5+critDamage)
			end
	--might bonus
			might=data.Player:GetMight()
			damageBonus=might/500
			t.Result=t.Result*(1+damageBonus)
		end
	end
end

--speed
function events.CalcDamageToPlayer(t)
	speed=t.Player:GetSpeed()
	speedEffect=speed/5
	dodgeChance=(1-0.995^speedEffect)*100
	roll=math.random(1, 100)
	if roll<=dodgeChance then
		t.Result=0
		--Game.ShowStatusText("Evaded")
		evt.FaceExpression{Player = t.PlayerIndex, Frame = 33}
	end
end

--intellect/personality
function events.CalcSpellDamage(t)
	local data = WhoHitMonster()
	if data and data.Player then
		intellect=data.Player:GetIntellect()	
		personality=data.Player:GetPersonality()
		luck=data.Player:GetLuck()
		bonus=math.max(intellect,personality)
		critDamage=bonus/500
		t.Result=t.Result*(1+bonus/500)
		critChance=50+luck
		roll=math.random(1, 1000)
		if roll <= critChance then
			t.Result=t.Result*(1.5+critDamage)
		end
	end
end
--AC 
function events.CalcDamageToPlayer(t)
	if t.DamageKind==4 then 
	AC=t.Player:GetArmorClass()
	t.Result=t.Result/(math.max(AC^0.85/100+0.5,1))
	end
end
--endurance
fullHP={}
for i =0,300 do
fullHP[i]=0
end

function events.CalcStatBonusByItems(t)
  if t.Stat == const.Stats.HP then
	endurance=t.Player:GetEndurance()/500
	i=t.Player:GetIndex()
	t.Result=t.Result+fullHP[i]*endurance
  end
end

function events.Tick()
	for i=0,Party.High do
		fullHP[i]=Game.Classes.HPFactor[Party[i].Class]*Party[i]:GetLevel()+Game.Classes.HPBase[Party[i].Class]
	end
end

function events.BuildStatInformationBox(t)
	if t.Stat==0 then
	i=Game.CurrentPlayer
	might=Party[i]:GetMight()
	t.Text=string.format("%s\n\nBonus Meele/Bow Damage: %s%s",Game.StatsDescriptions[0],might/5,"%")
	end
	if t.Stat==1 then
	i=Game.CurrentPlayer
	meditation=Party[i].Skills[25]%64
	fullSP=Party[i]:GetFullSP()
	personality=Party[i]:GetPersonality()
	intellect=Party[i]:GetIntellect()
	t.Text=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage/healing: %s%s",Game.StatsDescriptions[1],intellect/5,"%",intellect/5+50,"%")
	end
	if t.Stat==2 then
	i=Game.CurrentPlayer
	personality=Party[i]:GetPersonality()
	t.Text=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage/healing bonus: %s%s",Game.StatsDescriptions[2],personality/5,"%",personality/5+50,"%")
	end
	if t.Stat==3 then
	i=Game.CurrentPlayer
	endurance=Party[i]:GetEndurance()
	HPScaling=Game.Classes.HPFactor[Party[i].Class]
	level=Party[i]:GetLevel()
	t.Text=string.format("%s\n\nHealth bonus from Endurance: %s%s\n\nFlat HP bonus from Endurance: %s",Game.StatsDescriptions[3],endurance/5,"%",math.floor(endurance/5)*HPScaling)
	end
	if t.Stat==4 then
	i=Game.CurrentPlayer
	accuracy=Party[i]:GetAccuracy()
	t.Text=string.format("%s\n\nCritical melee and bow strike damage bonus: %s%s",Game.StatsDescriptions[4],accuracy/2.5+50,"%")
	end
	if t.Stat==5 then
	i=Game.CurrentPlayer
	speed=Party[i]:GetSpeed()
	ac=Party[i]:GetArmorClass()
	t.Text=string.format("%s\n\nDodge chance: %s%s",Game.StatsDescriptions[5],math.floor(1000-0.995^(speed/5)*1000)/10,"%")
	end
	if t.Stat==6 then
	i=Game.CurrentPlayer
	luck=Party[i]:GetLuck()
	t.Text=string.format("%s\n\nCritical strike chance: %s%s",Game.StatsDescriptions[6],luck/10+5,"%")
	end
	if t.Stat==7 then
	i=Game.CurrentPlayer
	endurance2=Party[i]:GetEndurance()
	HPScaling=Game.Classes.HPFactor[Party[i].Class]
	skill=Party[i].Skills[const.Skills.Bodybuilding]
	s,m=SplitSkill(skill)
	if m==4 then
		m=5
	end
	BBHP=HPScaling*s*m
	local fullHP=Party[i]:GetFullHP()
	enduranceTotalBonus=math.floor(fullHP-fullHP/(1+endurance2/500))+math.floor(endurance2/5)*HPScaling
	level=Party[i]:GetLevel()
	BASEHP=Game.Classes.HPBase[math.floor(Party[i].Class/3)]+level*HPScaling
	t.Text=string.format("%s\n\nHP bonus from Endurance: %s\n\nHP bonus from Body building: %s\n\nHP bonus from items: %s\n\nBase HP: %s",t.Text,StrColor(0,255,0,enduranceTotalBonus), StrColor(0,255,0,BBHP),StrColor(0,255,0,math.round(fullHP-enduranceTotalBonus-BBHP-BASEHP)),StrColor(0,255,0,BASEHP))
	end
	if t.Stat==8 then
	i=Game.CurrentPlayer
	fullSP=Party[i]:GetFullSP()
	skill=Party[i].Skills[const.Skills.Meditation]
	s,m=SplitSkill(skill)
	medRegen=math.floor(s/10)+m
	SPregenItem=0
	bonusregen=0
	for it in Party[i]:EnumActiveItems() do
		if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 then		
			SPregenItem=SPregenItem+1
			bonusregen=1
		end
	end
	SPregenItem=SPregenItem+bonusregen
	regen=math.ceil(fullSP*SPregenItem*0.005)+medRegen
	personality=Party[i]:GetPersonality()
	t.Text=string.format("%s\n\nSpell point regen per 10 seconds: %s",t.Text,StrColor(40,100,255,regen))
	end
	if t.Stat==9 then
	i=Game.CurrentPlayer
	ac=Party[i]:GetArmorClass()
	acReduction=math.round(1000-1000/math.max(ac^0.85/100+0.5,1))/10
	t.Text=string.format("%s\n\nPhysical damage reduction from AC: %s%s",t.Text,StrColor(255,255,100,acReduction),StrColor(255,255,100,"%"))
	end
	if t.Stat==19 then
		i=Game.CurrentPlayer
		res=Party[i]:GetResistance(10)
		totalReduction=100*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/2+(30/(30+res))*(1-(30/(30+res)))^2/4+(30/(30+res))*(1-(30/(30+res)))^3/8+(1-(30/(30+res)))^4/16)
		totalReduction= 100-math.round(totalReduction*100)/100
		t.Text=string.format("%s\n\nAverage Damage Reduction: %s %s",t.Text,totalReduction,"%")
	end
	if t.Stat==20 then
		i=Game.CurrentPlayer
		res=Party[i]:GetResistance(11)
		totalReduction=100*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/2+(30/(30+res))*(1-(30/(30+res)))^2/4+(30/(30+res))*(1-(30/(30+res)))^3/8+(1-(30/(30+res)))^4/16)
		totalReduction= 100-math.round(totalReduction*100)/100
		t.Text=string.format("%s\n\nAverage Damage Reduction: %s %s",t.Text,totalReduction,"%")
	end
	if t.Stat==21 then
		i=Game.CurrentPlayer
		res=Party[i]:GetResistance(12)
		totalReduction=100*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/2+(30/(30+res))*(1-(30/(30+res)))^2/4+(30/(30+res))*(1-(30/(30+res)))^3/8+(1-(30/(30+res)))^4/16)
		totalReduction= 100-math.round(totalReduction*100)/100
		t.Text=string.format("%s\n\nAverage Damage Reduction: %s %s",t.Text,totalReduction,"%")
	end
	if t.Stat==22 then
		i=Game.CurrentPlayer
		res=Party[i]:GetResistance(13)
		totalReduction=100*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/2+(30/(30+res))*(1-(30/(30+res)))^2/4+(30/(30+res))*(1-(30/(30+res)))^3/8+(1-(30/(30+res)))^4/16)
		totalReduction= 100-math.round(totalReduction*100)/100
		t.Text=string.format("%s\n\nAverage Damage Reduction: %s %s",t.Text,totalReduction,"%")
	end
	if t.Stat==23 then
		i=Game.CurrentPlayer
		res=Party[i]:GetResistance(14)
		totalReduction=100*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/2+(30/(30+res))*(1-(30/(30+res)))^2/4+(30/(30+res))*(1-(30/(30+res)))^3/8+(1-(30/(30+res)))^4/16)
		totalReduction= 100-math.round(totalReduction*100)/100
		t.Text=string.format("%s\n\nAverage Damage Reduction: %s %s",t.Text,totalReduction,"%")
	end
	if t.Stat==24 then
		i=Game.CurrentPlayer
		res=Party[i]:GetResistance(15)
		totalReduction=100*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/2+(30/(30+res))*(1-(30/(30+res)))^2/4+(30/(30+res))*(1-(30/(30+res)))^3/8+(1-(30/(30+res)))^4/16)
		totalReduction= 100-math.round(totalReduction*100)/100
		t.Text=string.format("%s\n\nAverage Damage Reduction: %s %s",t.Text,totalReduction,"%")
	end
end


end




function events.Regeneration(t)
	--HP
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
