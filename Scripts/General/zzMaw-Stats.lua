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

function events.GameInitialized2()
Game.StatsDescriptionsRework={}
Game.StatsDescriptionsRework[0]= "Might is the statistic that represents a character's overall strength, and the ability to put that strength where it counts.  Characters with a high might statistic do more damage in combat.\n\nEvery 5 point in might will increase damage by 1 point and 1% of total melee damage"
Game.StatsDescriptionsRework[1]="Intellect represents a character's ability to reason and understand complex, abstract concepts.  A high intellect contributes to Sorcerer, Archer, and Druid spell points.\n\nEvery 5 point in intellect will increase spell damage and healing by 1%. If personality is higher, personality will be used instead"
Game.StatsDescriptionsRework[2]="Personality represents both a character's strength of will and personal charm.  Clerics, Paladins, and Druids depend on personality for their spell points.\n\nEvery 5 point in personality will increase spell damage and healing by 1%. If intellect is higher, intellect will be used instead"
Game.StatsDescriptionsRework[3]="Endurance is a measure of the physical toughness and durability of a character.  A high endurance gives a character more hit points and less knockback when receiving hits.\n\nEvery 5 point in endurance will increase your Hit Points by 1%"
Game.StatsDescriptionsRework[4]="Accuracy represents a character's precision and hand-eye coordination.  A high accuracy will allow a character to hit monsters more frequently in combat.\n\nEvery 5 point in accuracy will increase Critical Damage by 2%."
Game.StatsDescriptionsRework[5]="Speed is a measure of how quick a character is.  A high speed statistic will increase a character's armor class and the rate with which the character recovers from attacks.\n\nEvery 5 point in speed will grant 0.5% chance to Dodge incoming damage. Effect is multiplicative."
Game.StatsDescriptionsRework[6]="Luck has a subtle influence throughout the game, but is most visible in the ability of a character to resist magical attacks and avoid taking (as much) damage from traps.\n\nEvery 5 point in luck will increase critical chance by 0.5%."
Game.StatsDescriptionsRework[7]="Hit points indicate how much damage your character can sustain before falling unconscious or dying.  A character is unconscious at zero hit points or less.  Hit points return after 8 hours of uninterrupted rest."
Game.StatsDescriptionsRework[8]="Armor Class is a measure of how difficult it is for a monster to hit a character.  The higher the armor class, the better the chance of avoiding an attack."
Game.StatsDescriptionsRework[9]="Spell points are needed to cast spells.  Every spell has a spell point cost that is deducted from this statistic when it's cast.  Spell points return after 8 hours of uninterrupted rest."
Game.StatsDescriptionsRework[10]="The Quick Spell is the spell that will be cast when you use the 's' key to cast a spell, or control-click on a monster.  You can set the quick spell by opening your spell book ('c'), clicking on the spell you want to set, then clicking on the set spell tab at the bottom of the spell book."
Game.StatsDescriptionsRework[11]="Condition shows the worst 'effect' your character is suffering, such as poisoned, diseased, or dead.  Many conditions seriously hurt your character's ability to fight, and should be cured as soon as possible."
Game.StatsDescriptionsRework[12]="Age shows the current age of your character.  The first number is the temporary age number, and the second is your real age.  Certain monsters and magical effects can raise your temporary age above your real age."
Game.StatsDescriptionsRework[13]="Level is a measure of the training your character has gone through.  A high level contributes to hit points and spell points."
Game.StatsDescriptionsRework[14]="Experience is a simple indicator of your character's overall understanding of the world.  With enough experience points (and a little gold), you can train your characters in training grounds throughout the land to increase their level and gain skill points to spend on skills."
Game.StatsDescriptionsRework[15]="Attack Bonus is the sum of all factors (skill, spells, Accuracy, etc.) that influence your character's chance to hit monsters with an equipped weapon.  "
Game.StatsDescriptionsRework[16]="Attack Damage is the sum of all factors (Might, spells, certain weapon skills at expert or master, etc.) that influence the damage your character does with an equipped weapon."
Game.StatsDescriptionsRework[17]="Shoot Bonus is the sum of all factors (skill, spells, Accuracy, etc.) that influence your character's chance to hit monsters with an equipped bow."
Game.StatsDescriptionsRework[18]="Shoot Damage is the sum of all factors (spells, weapon bonuses, etc.) that influence the damage your character does with an equipped bow."
Game.StatsDescriptionsRework[19]="Fire Resistance represents your character's ability to minimize damage from fire.  Though a high resistance can greatly reduce fire damage, it does not make your character immune."
Game.StatsDescriptionsRework[20]="Electricity Resistance represents your character's ability to minimize damage from electricity.  Though a high resistance can greatly reduce electricity damage, it does not make your character immune."
Game.StatsDescriptionsRework[21]="Cold Resistance represents your character's ability to minimize damage from cold.  Though a high resistance can greatly reduce cold damage, it does not make your character immune."
Game.StatsDescriptionsRework[22]="Poison Resistance represents your character's ability to minimize damage from poison or acid.  Though a high resistance can greatly reduce poison damage, it does not make your character immune."
Game.StatsDescriptionsRework[23]="Magic Resistance represents your character's ability to minimize damage from magical attacks.  Though a high resistance can greatly reduce magic damage, it does not make your character immune."
Game.StatsDescriptionsRework[24]="Skill points are awarded whenever your character trains for a new level.  You can spend skill points on your skills at any time."


end

--STATS TOOLTIPS

local newCode = mem.asmpatch(0x41330E, [[
	nop
	nop
	nop
	nop
	nop
	cmp edx,0x19
	ja absolute 0x41386E
]])

mem.hook(newCode, function(d)
	local t = {Stat = d.edx}
	events.call("ShowStatDescription", t)
end)

mem.autohook(0x41386E, function(d)
	events.call("AfterShowStatDescription")
end)

function events.ShowStatDescription(t)
	if t.Stat==0 then
	i=Game.CurrentPlayer
	might=Party[i]:GetMight()
	Game.StatsDescriptions[0]=string.format("%s\n\nBonus Meele/Bow Damage: %s%s",Game.StatsDescriptionsRework[0],might/5,"%")
	end
	if t.Stat==1 then
	i=Game.CurrentPlayer
	meditation=Party[i].Skills[25]%64
	fullSP=Party[i]:GetFullSP()
	personality=Party[i]:GetPersonality()
	intellect=Party[i]:GetIntellect()
	Game.StatsDescriptions[1]=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage/healing: %s%s",Game.StatsDescriptionsRework[1],intellect/5,"%",intellect/5+50,"%")
	end
	if t.Stat==2 then
	i=Game.CurrentPlayer
	personality=Party[i]:GetPersonality()
	Game.StatsDescriptions[2]=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage/healing bonus: %s%s",Game.StatsDescriptionsRework[2],personality/5,"%",personality/5+50,"%")
	end
	if t.Stat==3 then
	i=Game.CurrentPlayer
	endurance=Party[i]:GetEndurance()
	HPScaling=Game.Classes.HPFactor[Party[i].Class]
	
	
	level=Party[i]:GetLevel()
	
	Game.StatsDescriptions[3]=string.format("%s\n\nHealth bonus from Endurance: %s%s\n\nFlat HP bonus from Endurance: %s",Game.StatsDescriptionsRework[3],endurance/5,"%",math.floor(endurance/5)*HPScaling)
	end
	if t.Stat==4 then
	i=Game.CurrentPlayer
	accuracy=Party[i]:GetAccuracy()
	Game.StatsDescriptions[4]=string.format("%s\n\nCritical melee and bow strike damage bonus: %s%s",Game.StatsDescriptionsRework[4],accuracy/2.5+50,"%")
	end
	if t.Stat==5 then
	i=Game.CurrentPlayer
	speed=Party[i]:GetSpeed()
	ac=Party[i]:GetArmorClass()
	Game.StatsDescriptions[5]=string.format("%s\n\nDodge chance: %s%s",Game.StatsDescriptionsRework[5],math.floor(1000-0.995^(speed/5)*1000)/10,"%")
	end
	if t.Stat==6 then
	i=Game.CurrentPlayer
	luck=Party[i]:GetLuck()
	Game.StatsDescriptions[6]=string.format("%s\n\nCritical strike chance: %s%s",Game.StatsDescriptionsRework[6],luck/10+5,"%")
	end
	
	if t.Stat==7 then
	i=Game.CurrentPlayer
	endurance=Party[i]:GetEndurance()
	HPScaling=Game.Classes.HPFactor[Party[i].Class]
	
	m=math.ceil(Party[i].Skills[const.Skills.Bodybuilding]/64)
	s=Party[i].Skills[const.Skills.Bodybuilding]%64
	if m<3 then
		BBHP=HPScaling*s*m
	else
		BBHP=s^2-6*s+s*m*HPScaling
	end
	fullHP=Party[i]:GetFullHP()
	enduranceTotalBonus=math.floor(fullHP-fullHP/(1+endurance/500))+math.floor(endurance/5)*HPScaling
	
	level=Party[i]:GetLevel()
	BASEHP=Game.ClassKinds.HPBase[math.floor(Party[i].Class/3)]+level*HPScaling
	
	Game.ExtraStatDescriptions[const.Stats.HP]=string.format("%s\n\nHP bonus from Endurance: %s\n\nHP bonus from Body building: %s\n\nHP bonus from items: %s\n\nBase HP: %s",Game.StatsDescriptionsRework[7],StrColor(0,255,0,enduranceTotalBonus), StrColor(0,255,0,BBHP),StrColor(0,255,0,math.round(fullHP-enduranceTotalBonus-BBHP-BASEHP)),StrColor(0,255,0,BASEHP))
	end
	if t.Stat==8 then
	i=Game.CurrentPlayer
	meditation=Party[i].Skills[25]%64
	fullSP=Party[i]:GetFullSP()
	SPregenItem=0
	bonusregen=0
	for it in Party[i]:EnumActiveItems() do
		if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 then		
			SPregenItem=SPregenItem+1
			bonusregen=1
		end
	end
	SPregenItem=SPregenItem+bonusregen
	regen=math.ceil((fullSP^0.5 * meditation^2/400)+fullSP*SPregenItem*0.005)
	personality=Party[i]:GetPersonality()
	Game.ExtraStatDescriptions[const.Stats.SP]=string.format("%s\n\nSpell point regen per 10 seconds: %s",Game.StatsDescriptionsRework[9],StrColor(40,100,255,regen))
	end
	
	if t.Stat==9 then
	i=Game.CurrentPlayer
	ac=Party[i]:GetArmorClass()
	acReduction=math.round(1000-1000/math.max(ac^0.85/100+0.5,1))/10
	Game.ExtraStatDescriptions[const.Stats.ArmorClass]=string.format("%s\n\nPhysical damage reduction from AC: %s%s",Game.StatsDescriptionsRework[8],StrColor(255,255,100,acReduction),StrColor(255,255,100,"%"))
	end
	
	if t.Stat==19 then
		i=Game.CurrentPlayer
		resistance=Party[i]:GetFireResistance()
		luck=math.floor(Party[i]:GetLuck()/5)
		res=resistance+luck		
		if SETTINGS["ReworkedMagicDamageCalculation"]==true then
		fixedReduction= 100 * (1 / (1 + (resistance+luck)^0.7 / 100))
		totalReduction= fixedReduction*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/1.5+(30/(30+res))*(1-(30/(30+res)))^2/2+(30/(30+res))*(1-(30/(30+res)))^3/2.5+(1-(30/(30+res)))^4/3)
		else 
		totalReduction=100*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/2+(30/(30+res))*(1-(30/(30+res)))^2/4+(30/(30+res))*(1-(30/(30+res)))^3/8+(1-(30/(30+res)))^4/16)
		end
		totalReduction= 100-math.round(totalReduction*100)/100
		Game.ExtraStatDescriptions[const.Stats.FireResistance]=string.format("%s\n\nAverage Damage Reduction: %s %s",Game.StatsDescriptionsRework[19],totalReduction,"%")
	end
	if t.Stat==20 then
		i=Game.CurrentPlayer
		resistance=Party[i]:GetElectricityResistance()
		luck=math.floor(Party[i]:GetLuck()/5)
		res=resistance+luck		
		if SETTINGS["ReworkedMagicDamageCalculation"]==true then
		fixedReduction= 100 * (1 / (1 + (resistance+luck)^0.7 / 100))
		totalReduction= fixedReduction*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/1.5+(30/(30+res))*(1-(30/(30+res)))^2/2+(30/(30+res))*(1-(30/(30+res)))^3/2.5+(1-(30/(30+res)))^4/3)
		else 
		totalReduction=100*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/2+(30/(30+res))*(1-(30/(30+res)))^2/4+(30/(30+res))*(1-(30/(30+res)))^3/8+(1-(30/(30+res)))^4/16)
		end
		totalReduction= 100-math.round(totalReduction*100)/100
		Game.ExtraStatDescriptions[const.Stats.ElecResistance]=string.format("%s\n\nAverage Damage Reduction: %s %s",Game.StatsDescriptionsRework[20],totalReduction,"%")
	end
	if t.Stat==21 then
		i=Game.CurrentPlayer
		resistance=Party[i]:GetColdResistance()
		luck=math.floor(Party[i]:GetLuck()/5)
		res=resistance+luck		
		if SETTINGS["ReworkedMagicDamageCalculation"]==true then
		fixedReduction= 100 * (1 / (1 + (resistance+luck)^0.7 / 100))
		totalReduction= fixedReduction*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/1.5+(30/(30+res))*(1-(30/(30+res)))^2/2+(30/(30+res))*(1-(30/(30+res)))^3/2.5+(1-(30/(30+res)))^4/3)
		else 
		totalReduction=100*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/2+(30/(30+res))*(1-(30/(30+res)))^2/4+(30/(30+res))*(1-(30/(30+res)))^3/8+(1-(30/(30+res)))^4/16)
		end
		totalReduction= 100-math.round(totalReduction*100)/100
		Game.ExtraStatDescriptions[const.Stats.ColdResistance]=string.format("%s\n\nAverage Damage Reduction: %s %s",Game.StatsDescriptionsRework[21],totalReduction,"%")
	end
	if t.Stat==22 then
		i=Game.CurrentPlayer
		resistance=Party[i]:GetPoisonResistance()
		luck=math.floor(Party[i]:GetLuck()/5)
		res=resistance+luck	
		if SETTINGS["ReworkedMagicDamageCalculation"]==true then
		fixedReduction= 100 * (1 / (1 + (resistance+luck)^0.7 / 100))
		totalReduction= fixedReduction*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/1.5+(30/(30+res))*(1-(30/(30+res)))^2/2+(30/(30+res))*(1-(30/(30+res)))^3/2.5+(1-(30/(30+res)))^4/3)
		else 
		totalReduction=100*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/2+(30/(30+res))*(1-(30/(30+res)))^2/4+(30/(30+res))*(1-(30/(30+res)))^3/8+(1-(30/(30+res)))^4/16)
		end
		totalReduction= 100-math.round(totalReduction*100)/100
		Game.ExtraStatDescriptions[const.Stats.PoisonResistance]=string.format("%s\n\nAverage Damage Reduction: %s %s",Game.StatsDescriptionsRework[22],totalReduction,"%")
	end
	if t.Stat==23 then
		i=Game.CurrentPlayer
		resistance=Party[i]:GetMagicResistance()
		luck=math.floor(Party[i]:GetLuck()/5)
		res=resistance+luck		
		if SETTINGS["ReworkedMagicDamageCalculation"]==true then
		fixedReduction= 100 * (1 / (1 + (resistance+luck)^0.7 / 100))
		totalReduction= fixedReduction*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/1.5+(30/(30+res))*(1-(30/(30+res)))^2/2+(30/(30+res))*(1-(30/(30+res)))^3/2.5+(1-(30/(30+res)))^4/3)
		else 
		totalReduction=100*(30/(30+res)+(30/(30+res))*(1-(30/(30+res)))/2+(30/(30+res))*(1-(30/(30+res)))^2/4+(30/(30+res))*(1-(30/(30+res)))^3/8+(1-(30/(30+res)))^4/16)
		end
		totalReduction= 100-math.round(totalReduction*100)/100
		Game.ExtraStatDescriptions[const.Stats.MagicResistance]=string.format("%s\n\nAverage Damage Reduction: %s %s",Game.StatsDescriptionsRework[23],totalReduction,"%")
	end
	
end


--unused
function events.AfterShowStatDescription()
end

end
