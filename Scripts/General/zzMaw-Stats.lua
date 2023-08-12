function events.CalcDamageToMonster(t)
	local data = WhoHitMonster()	
	--luck/accuracy bonus
	if data and data.Player and t.DamageKind==4 then
		if data.Object==nil or data.Object.Spell==133 then
			luck=data.Player:GetLuck()
			accuracy=data.Player:GetAccuracy()
			critDamage=accuracy/500
			critChance=50+luck/2
			roll=math.random(1, 1000)
			if roll <= critChance then
				t.Result=t.Result*(1.5+critDamage)
			end
	--might bonus
			might=data.Player:GetMight()
			damageBonus=might/1000
			t.Result=t.Result*(1+damageBonus)
		end
	end
end

--speed
function events.CalcDamageToPlayer(t)
	speed=t.Player:GetSpeed()
	speedEffect=speed/10
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
		critDamage=bonus/1000
		t.Result=t.Result*(1+bonus/1000)
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
	t.Result=t.Result/(math.max(AC^0.85/200+0.75,1))
	end
end
--endurance
fullHP={}
for i =0,300 do
fullHP[i]=0
end

function events.CalcStatBonusByItems(t)
  if t.Stat == const.Stats.HP then
	endurance=t.Player:GetEndurance()/1000
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
	t.Text=string.format("%s\n\nBonus Meele/Bow Damage: %s%s",Game.StatsDescriptions[0],might/10,"%")
	end
	if t.Stat==1 then
	i=Game.CurrentPlayer
	meditation=Party[i].Skills[25]%64
	fullSP=Party[i]:GetFullSP()
	personality=Party[i]:GetPersonality()
	intellect=Party[i]:GetIntellect()
	t.Text=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage/healing: %s%s",Game.StatsDescriptions[1],intellect/10,"%",intellect/10+50,"%")
	end
	if t.Stat==2 then
	i=Game.CurrentPlayer
	personality=Party[i]:GetPersonality()
	t.Text=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage/healing bonus: %s%s",Game.StatsDescriptions[2],personality/10,"%",personality/10+50,"%")
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
	t.Text=string.format("%s\n\nCritical melee and bow strike damage bonus: %s%s",Game.StatsDescriptions[4],accuracy/5+50,"%")
	end
	if t.Stat==5 then
	i=Game.CurrentPlayer
	speed=Party[i]:GetSpeed()
	ac=Party[i]:GetArmorClass()
	t.Text=string.format("%s\n\nDodge chance: %s%s",Game.StatsDescriptions[5],math.floor(1000-0.995^(speed/10)*1000)/10	,"%")
	end
	if t.Stat==6 then
	i=Game.CurrentPlayer
	luck=Party[i]:GetLuck()
	t.Text=string.format("%s\n\nCritical strike chance: %s%s",Game.StatsDescriptions[6],luck/20+5,"%")
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
	enduranceTotalBonus=math.floor(fullHP-fullHP/(1+endurance2/500))+math.floor(endurance2/10)*HPScaling
	level=Party[i]:GetLevel()
	BASEHP=Game.Classes.HPBase[math.floor(Party[i].Class/3)]+level*HPScaling
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
damage1=0
	if t.DamageKind==0 or t.DamageKind==1 or t.DamageKind==2 or t.DamageKind==3 or t.DamageKind==7 or t.DamageKind==8 then
	--get resistances
		if t.DamageKind==0 then
		res=t.Player:GetResistance(10)/4
		end
		if t.DamageKind==1 then
		res=t.Player:GetResistance(11)/4
		end
		if t.DamageKind==2 then
		res=t.Player:GetResistance(12)/4
		res2=0
		end
		if t.DamageKind==3 then
		res=t.Player:GetResistance(13)/4
		end
		if t.DamageKind==7 then
		res=t.Player:GetResistance(14)/4
		end
		if t.DamageKind==8 then
		res=t.Player:GetResistance(15)/4
		end	
		luck=t.Player:GetLuck()/20
		--put here code to change max res
		maxres=75
		res=math.min(res,maxres)/100
		--apply Damage
		t.Result = t.Damage * (1-res)
	end
end


--remove resistance rating
function events.CalcStatBonusByItems(t)
	for it in t.Player:EnumActiveItems() do
		if t.Stat == const.Stats.FireResistance and it.Bonus==11 then
			t.Result = t.Result+it.BonusStrength
		end
		if t.Stat == const.Stats.AirResistance and it.Bonus==12 then
			t.Result = t.Result+it.BonusStrength
		end
		if t.Stat == const.Stats.WaterResistance and it.Bonus==13 then
			t.Result = t.Result+it.BonusStrength
		end
		if t.Stat == const.Stats.EarthResistance and it.Bonus==14 then
			t.Result = t.Result+it.BonusStrength
		end
		if t.Stat == const.Stats.MindResistance and it.Bonus==15 then
			t.Result = t.Result+it.BonusStrength
		end
		if t.Stat == const.Stats.BodyResistance and it.Bonus==16 then
			t.Result = t.Result+it.BonusStrength
		end
	end
end








--TOOLTIPS
function events.Tick()
	if Game.CurrentCharScreen==100 then
	local i=Game.CurrentPlayer 
	if i==-1 then return end --prevent bug message
	fireRes=Party[i]:GetResistance(10)/4
	airRes=Party[i]:GetResistance(11)/4
	waterRes=Party[i]:GetResistance(12)/4
	earthRes=Party[i]:GetResistance(13)/4
	mindRes=Party[i]:GetResistance(14)/4
	bodyRes=Party[i]:GetResistance(15)/4

		--FIRE RESISTANCE
		for it in Party[Game.CurrentPlayer]:EnumActiveItems() do
			if it.Bonus==11 then
				fireRes = fireRes+it.BonusStrength/4
			end
			if math.floor(it.Charges/1000+1)==11 then
				fireRes = fireRes+it.Charges%1000/4
			end
		end
		--AIR RESISTANCE
		for it in Party[Game.CurrentPlayer]:EnumActiveItems() do
			if it.Bonus==12 then
				airRes = airRes+it.BonusStrength/4
			end
			if math.floor(it.Charges/1000+1)==12 then
				airRes = airRes+it.Charges%1000/4
			end
		end
		--WATER RESISTANCE
		for it in Party[Game.CurrentPlayer]:EnumActiveItems() do
			if it.Bonus==13 then
				waterRes = waterRes+it.BonusStrength/4
			end
			if math.floor(it.Charges/1000+1)==13 then
				waterRes = waterRes+it.Charges%1000/4
			end
		end
		--EARTH RESISTANCE
		for it in Party[Game.CurrentPlayer]:EnumActiveItems() do
			if it.Bonus==14 then
				earthRes = earthRes+it.BonusStrength/4
			end
			if math.floor(it.Charges/1000+1)==11 then
				earthRes = earthRes+it.Charges%1000/4
			end
		end
		--MIND RESISTANCE
		for it in Party[Game.CurrentPlayer]:EnumActiveItems() do
			if it.Bonus==15 then
				mindRes = mindRes+it.BonusStrength/4
			end
			if math.floor(it.Charges/1000+1)==15 then
				mindRes = mindRes+it.Charges%1000/4
			end
		end
		--BODY RESISTANCE
		for it in Party[Game.CurrentPlayer]:EnumActiveItems() do
			if it.Bonus==16 then
				bodyRes = bodyRes+it.BonusStrength/4
			end
			if math.floor(it.Charges/1000+1)==16 then
				bodyRes = bodyRes+it.Charges%1000/4
			end
		end

		--add bonus2
		for it in Party[Game.CurrentPlayer]:EnumActiveItems() do
			if it.Bonus2==1 then
				fireRes=fireRes+10/2
				airRes=airRes+10/2
				waterRes=waterRes+10/2
				earthRes=earthRes+10/2
				mindRest=mindRes+10/2
				bodyRes=bodyRes+10/2
			end
			if it.Bonus2==42 then
				fireRes=fireRes+1/2
				airRes=airRes+1/2
				waterRes=waterRes+1/2
				earthRes=earthRes+1/2
				mindRest=mindRes+1/2
				bodyRes=bodyRes+1/2
			end
			if it.Bonus2==50 then
				fireRes=fireRes+30/2
			end
		end
		if fireRes>=75 then
			fireRes=StrColor(0,255,0,"Max")
		end
		if airRes>=75 then
			airRes=StrColor(0,255,0,"Max")
		end
		if waterRes>=75 then
			waterRes=StrColor(0,255,0,"Max")
		end
		if earthRes>=75 then
			earthRes=StrColor(0,255,0,"Max")
		end
		if mindRes>=75 then
			mindRes=StrColor(0,255,0,"Max")
		end
		if bodyRes>=75 then
			bodyRes=StrColor(0,255,0,"Max")
		end
		Game.GlobalTxt[87]=string.format("Fire %s%s",fireRes,"%")
		Game.GlobalTxt[6]=string.format("Air %s%s",airRes,"%")
		Game.GlobalTxt[240]=string.format("Water %s%s",waterRes,"%")
		Game.GlobalTxt[70]=string.format("Earth %s%s",earthRes,"%")
		Game.GlobalTxt[142]=string.format("Mind %s%s",mindRes,"%")
		Game.GlobalTxt[29]=string.format("Body %s%s",bodyRes,"%")
	end
	if Game.CurrentCharScreen==101 then
		Game.GlobalTxt[87]="Fire"
		Game.GlobalTxt[71]="Elec"
		Game.GlobalTxt[43]="Cold"
		Game.GlobalTxt[166]="Poison"
		Game.GlobalTxt[138]="Magic"
	end
end
