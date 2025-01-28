function events.KeyDown(t)
    if Game.CurrentScreen == 7 and Game.CurrentCharScreen == 100 then
        if t.Key == 82 then -- "r" key
            Game.ShowStatusText(string.format("Map data reset, press Y to continue..."))
            map_data_reset_confirmation = 1;
        end

        if (t.Key ~= 89) and (t.Key ~= 82) and (map_data_reset_confirmation == 1) then -- not "y" key
            map_data_reset_confirmation = 0; -- aborting reset without confirmation
        end

        if t.Key == 89 and (map_data_reset_confirmation == 1) then -- "y" key
            Game.ShowStatusText(string.format("Current map data reset."))
            map_data_reset_confirmation = 0;
            local i
            for i = 0, Party.High do
                mapvars.damageTrack[Party[i]:GetIndex()] = 0 -- melee
                mapvars.damageTrackRanged[Party[i]:GetIndex()] = 0 -- ranged
            end
        end
    end
end

function getCritInfo(pl,dmgType,monLvl)
	if not monLvl then
		monLvl=pl.LevelBase
	end
	local luck=pl:GetLuck()
	local totalCrit=luck/math.min((500+monLvl*7.5),5000)+0.05
	local critDamageMultiplier=1
	if dmgType=="spell" then
		local intellect=pl:GetIntellect()	
		local personality=pl:GetPersonality()
		local bonus=math.max(intellect,personality)
		critDamageMultiplier=bonus/2000+1.5
	elseif dmgType=="heal" then
		local intellect=pl:GetIntellect()	
		local personality=pl:GetPersonality()
		local bonus=math.max(intellect,personality)
		critDamageMultiplier=bonus*3/4000+1.25
		--crit removed for healing
		return 0, 0, false
	else --physical
		local accuracy=pl:GetAccuracy()
		critDamageMultiplier=accuracy*2/1000+1.5
	end
	--dagger bonus
	if not dmgType then
		for i=0,1 do
			if pl:GetActiveItem(i) then
				local itSkill=pl:GetActiveItem(i):T().Skill
				if itSkill==2 then
					s,m=SplitSkill(pl:GetSkill(const.Skills.Dagger))
					if m>2 then
						totalCrit=totalCrit+0.05+0.01*s/math.min(1+monLvl/200,4)
					end
				end
			end
		end
	end
	--axe bonus
	if not dmgType then
		local it=pl:GetActiveItem(1)
		if it then	
			if table.find(twoHandedAxes, it.Number) or table.find(oneHandedAxes, it.Number) then
				local s,m=SplitSkill(pl:GetSkill(const.Skills.Axe))
				if m==4 then
					critDamageMultiplier=critDamageMultiplier+0.03*s
				end
			end
		end
	end
	
	if vars.MAWSETTINGS.buffRework=="ON" then 
		if pl.SpellBuffs[4].ExpireTime>=Game.Time then
			local s,m=getBuffSkill(47)
			local s2,m2=getBuffSkill(86)
			s=math.max(s,s2/1.5)
			m=math.max(m,m2)
			local bonus=buffPower[47].Base[m]/100+buffPower[47].Scaling[m]*s/1000
			totalCrit=totalCrit+bonus
		end
	end
	if getMapAffixPower(20) then
		totalCrit=totalCrit-getMapAffixPower(20)/100
	end
	if getMapAffixPower(21) then
		critDamageMultiplier=(critDamageMultiplier-1)*(1-getMapAffixPower(21)/100)+1
	end
	
	
	--legendary bonus
	local id=pl:GetIndex()
	if vars.legendaries and table.find(vars.legendaries[id], 14) then
		totalCrit=totalCrit+0.1
	else
		totalCrit=math.min(totalCrit,1)
	end
	
	local success=math.random()<totalCrit
	
	return totalCrit, critDamageMultiplier, success
end

function events.CalcDamageToMonster(t)
	local data = WhoHitMonster()	
	--luck/accuracy bonus
	if data and data.Player and (t.DamageKind==4 or (data and data.Object and data.Object.Spell==133 and data.Object.Item and data.Object.Item.Bonus2==3 ) or (data and data.Spell==135)) then
		if data.Object==nil or data.Object.Spell==133 or data.Spell==135 then
			pl=t.Player
			--OVERRIDE DAMAGE WITH MAW CALCULATION
			if data.Object==nil or data.Spell==135 then
				baseDamage=pl:GetMeleeDamageMin()
				maxDamage=pl:GetMeleeDamageMax()
				randomDamage=math.random(baseDamage, maxDamage) + math.random(baseDamage, maxDamage)
				damage=round(randomDamage/2)
				dmgMult=damageMultiplier[data.Player:GetIndex()]["Melee"]
			else --bow
				baseDamage=pl:GetRangedDamageMin()
				maxDamage=pl:GetRangedDamageMax()
				randomDamage=math.random(baseDamage, maxDamage) + math.random(baseDamage, maxDamage)
				damage=round(randomDamage/2)
				dmgMult=damageMultiplier[data.Player:GetIndex()]["Ranged"]
			end
			
			t.Result=damage*dmgMult
			
			if data.Object and data.Object.Spell==133 then
				critChance, critMult, success=getCritInfo(pl,true)
			else
				critChance, critMult, success=getCritInfo(pl)
			end
			
			if success then
				t.Result=t.Result*critMult
				crit=true
			end
			if data.Player.Weak>0 then
				t.Result=t.Result*0.5
			end
			if data and data.Object and data.Object.Spell==133 and data.Object.Item and data.Object.Item.Bonus2==3 then
				t.Result=t.Result*0.25
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
	local m=math.max(1,t.Mastery)
	Game.Spells[spell]["Delay" .. masteryName[m]]=getSpellDelay(t.Player,spell)
end

function getSpellDelay(pl,spell)
	local s,m=SplitSkill(pl.Skills[math.ceil(spell/11)+11])
	if m==0 then return end
	local haste=math.floor(pl:GetSpeed()/10)
	for i=1,2 do
		local it=pl:GetActiveItem(i)
		if it and it.Bonus2==40 then
			haste=haste+20
		end
	end
	local tier=0
	local skill=SplitSkill(pl.Skills[const.Skills.Learning])
	if table.find(spells, spell) or (healingSpells and healingSpells[spell]) then
		tier=getAscensionTier(skill,spell,pl:GetIndex())
	end
	
	--haste buff
	local hasteDiv=1
	if vars.MAWSETTINGS.buffRework=="ON" and Party.SpellBuffs[8].ExpireTime>=Game.Time then
		local s, m=getBuffSkill(5)
		hasteDiv=1+buffPower[5].Base[m]/100+buffPower[5].Scaling[m]/1000*s
	end
	local delay=round(oldTable[spell][m]/(1+haste/100)*1.2^tier/hasteDiv)
	if table.find(elementalistClass, pl.Class) then
		delay=delay*1.5
		local id=pl:GetIndex()
		vars.eleStacks=vars.eleStacks or {}
		vars.eleStacks[id]=vars.eleStacks[id] or 0
		local stacks=vars.eleStacks[id]
		local speedIncrease=1+stacks*0.05
		delay=delay/speedIncrease
	end
	if spell==123 then
		delay=100
	end
	if getMapAffixPower(27) then
		delay=delay/(1-getMapAffixPower(27)/100)
	end
	return delay
end
--remove AC from hit calculation and unarmed code from misctweaks
nextACToZero=0
acNerf=0
function events.PlayerAttacked(t)
	if t.Attacker and t.Attacker.Monster then
		local mon=t.Attacker.Monster
		local lvl=getMonsterLevel(mon)
		nerfAmount=math.max(1,lvl/255)
		if t.Attacker.MonsterAction==0 then
			ac=t.Player:GetArmorClass()
			if t.Attacker.Monster.Attack1.Type~=4 then
				nextACToZero=2
			elseif Game.BolsterAmount>100 then
				acNerf=2
				nerfAmount=nerfAmount*math.min(Game.BolsterAmount,300)/100
			end
		elseif t.Attacker.MonsterAction==1 then
			if t.Attacker.Monster.Attack2.Type~=4 then
				nextACToZero=2
			elseif Game.BolsterAmount>100 then
				acNerf=2
				nerfAmount=nerfAmount*math.min(Game.BolsterAmount,300)/100
			end
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



--body building description
function events.GameInitialized2()
	txt=Skillz.getDesc(27,1) .. "\n\nHit Points are also increased 2% per skill point (multiplicative)"
	Skillz.setDesc(27,1,txt)
end

function events.BuildStatInformationBox(t)
	if t.Stat==0 then
		i=Game.CurrentPlayer
		might=Party[i]:GetMight()
		t.Text=string.format("%s\n\nBonus Melee/Bow Damage: %s%s",Game.StatsDescriptions[0],might/10,"%")
	end
	if t.Stat==1 then
		i=Game.CurrentPlayer
		intellect=Party[i]:GetIntellect()
		_,critDmg=getCritInfo(Party[i],"spell")
		t.Text=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage: %s%s\nHealing spells cannot crit",Game.StatsDescriptions[1],intellect/10,"%",critDmg*100-100,"%")
	end
	if t.Stat==2 then
		i=Game.CurrentPlayer
		personality=Party[i]:GetPersonality()
		_,critDmg=getCritInfo(Party[i],"spell")
		t.Text=string.format("%s\n\nBonus magic damage/healing: %s%s\n\nCritical spell strike damage: %s%s\nHealing spells cannot crit",Game.StatsDescriptions[2],personality/10,"%",critDmg*100-100,"%")
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
		_,critDmg=getCritInfo(Party[i])
		t.Text=string.format("%s\n\nCritical melee and bow strike damage bonus: %s%s",Game.StatsDescriptions[4],critDmg*100-100,"%")
	end
	if t.Stat==5 then
		i=Game.CurrentPlayer
		speed=Party[i]:GetSpeed()
		dodging=0
		Skill, Mas = SplitSkill(Party[i]:GetSkill(const.Skills.Dodging))
		if Mas == 4 then
			dodging=Skill+10
			dodgeChance=1-0.995^(dodging)
			t.Text=string.format("%s\n\nDodge chance: %s%%",Game.StatsDescriptions[5],math.floor(dodgeChance*1000)/10)
		end
		--spell haste
		speed=Party[i]:GetSpeed()
		spellSpeedEffect=math.floor(speed/10)
		local it=Party[i]:GetActiveItem(1)
		if it and it.Bonus2==40 then
			spellSpeedEffect=spellSpeedEffect+20
		end
		--melee haste
		delay=math.max(Party[i]:GetAttackDelay())
		meleeHaste=bonusSpeed
		--bow haste
		delay=Party[i]:GetAttackDelay(true)
		bowHaste=bonusSpeed
		t.Text=string.format("%s\n\nMelee Haste:   %s%%\nRanged Haste: %s%%\nSpell Haste:   %s%%",t.Text,meleeHaste,bowHaste,spellSpeedEffect)
	end
	if t.Stat==6 then
		i=Game.CurrentPlayer
		local critChance=round(getCritInfo(Party[i], "ranged")*10000)/100
		local daggerCritBonus=round(getCritInfo(Party[i])*10000)/100
		t.Text=string.format("%s\n\nCritical strike chance: %s%%",Game.StatsDescriptions[6],critChance)
		daggerBonus=daggerCritBonus~=critChance
		if daggerBonus then
			t.Text=string.format("%s\n\nCritical strike chance: %s%%(%s%% with dagger)",Game.StatsDescriptions[6],critChance, daggerCritBonus)
		end
	end
	if t.Stat==7 then
		local index=Game.CurrentPlayer
		level=Party[index]:GetLevel()
		--hp regen calculation
		local i=Game.CurrentPlayer
		local FHP=Party[i]:GetFullHP()
		local skill=Party[i]:GetSkill(const.Skills.Regeneration)
		local s,m=SplitSkill(skill)

		local regenEffect={[0]=0,2,4,6,6}
		local hpRegen = round(FHP^0.5*s^1.65*((regenEffect[m])/35))+s*10
		local HPregenItem=0
		local bonusregen=0
		for it in Party[i]:EnumActiveItems() do
			if it.Bonus2 == 37 or it.Bonus2==44 or it.Bonus2==50 or it.Bonus2==54 or it.Bonus2==66 then	
				HPregenItem=HPregenItem+1
				bonusregen=1
			end
		end
		HPregenItem=HPregenItem
		regen=math.ceil(FHP*HPregenItem*0.02)+hpRegen+bonusregen
		
		Buff=Party[i].SpellBuffs[const.PlayerBuff.Regeneration]
		
		if vars.MAWSETTINGS.buffRework=="ON" then
			if pl.SpellBuffs[12].ExpireTime>=Game.Time then
				local s,m,level=getBuffSkill(71)
				local skill=(level)^0.65*(1+s*buffPower[71].Base[m]/100)
				regen = regen + math.ceil(FHP^0.5*skill^1.3*(buffPower[71].Base[m]/100)) -- around 1/4 of regen compared to skill, considering that of body enchants give around skill*2
			end
		else
			if Buff.ExpireTime > Game.Time then
				RegS, RegM = SplitSkill(Buff.Skill)
				regen = math.ceil(regen + FHP^0.5*RegS^1.3*((RegM+1)/100)) 
			end
		end
		
		hpMap=hpStatsMap[index]
		
		t.Text=string.format("%s\n\nHP bonus from Endurance: %s\nHP bonus from Body building: %s\nHP bonus from items: %s\nBase HP: %s\n\n HP Regen per second: %s",t.Text,StrColor(0,255,0,hpMap.totalEnduranceBonus), StrColor(0,255,0,hpMap.totalBBBonus),StrColor(0,255,0,round(hpMap.totalhpFromItems)),StrColor(0,255,0,hpMap.totalBaseHP),StrColor(0,255,0,regen/10))
	end
	if t.Stat==8 then
		local i=Game.CurrentPlayer
		local fullSP=Party[i]:GetFullSP()
		if vars.MAWSETTINGS.buffRework=="ON" and vars.currentManaPool and vars.currentManaPool[i] then
			fullSP=fullSP*(vars.currentManaPool[Game.CurrentPlayer]/fullSP)^0.5
		end
		local skill=Party[i]:GetSkill(const.Skills.Meditation)
		local s,m=SplitSkill(skill)
		if m==4 then
			m=8
		end
		local medRegen = round(fullSP^0.25*s^1.4*(m+5)/50)+2
		--meditation buff
		if vars.MAWSETTINGS.buffRework=="ON" and vars.mawbuff[56] then
			local s, m, level=getBuffSkill(56)
			local level=level^0.6
			medRegen = medRegen + round((fullSP^0.25*level^1.4*((buffPower[56].Base[m])/150) +10)*(1+buffPower[56].Scaling[m]/100*s))
		end
		
		local SPregenItem=0
		local bonusregen=0
		for it in Party[i]:EnumActiveItems() do
			if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 or it.Bonus2==66 then		
				--SPregenItem=SPregenItem+1
				--bonusregen=1
				--such enchants now increase meditation instead
			end
			if table.find(artifactSpRegen, it.Number) then
				SPregenItem=SPregenItem+1
				bonusregen=1
			end
		end
		SPregenItem=SPregenItem
		regen=math.ceil(Party[i]:GetFullSP()*SPregenItem*0.01)+medRegen+bonusregen
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
		blockChance= 100-round((5+lvl*2)/(10+lvl*2+ac)*10000)/100
		totRed= 100-round((100-blockChance)*(100-acReduction))/100
		t.Text=string.format("%s\n\nPhysical damage reduction from AC: %s%s",t.Text,StrColor(255,255,100,acReduction),StrColor(255,255,100,"%") .. "\nBlock chance vs same level monsters (up to 255): " .. StrColor(255,255,100,blockChance) .. StrColor(255,255,100,"%") .. "\n\nTotal average damage reduction: " .. StrColor(255,255,100,totRed) .. "%")
	end
	
	if t.Stat==5234672 then
		i=Game.CurrentPlayer
		local pl=Party[i]
		--get spell and its damage
		DPS1, DPS2, DPS3, vitality=calcPowerVitality(pl)
		local txt=string.format("Melee Power: %s\nRanged Power: %s\nSpell Power: %s",StrColor(255,0,0,DPS1),StrColor(200,200,0,DPS2),StrColor(50,50,220,DPS3))
			
		t.Text=string.format("%s\n%s",t.Text,txt)
		
	end
	
	if t.Stat==11 then
		local i=Game.CurrentPlayer
		local pl=Party[i]
		local id=pl:GetIndex()
		--check and add equipped legendaries
		local legTxt="Currently Active Legendary effects:"
		for i=1,#legendaryEffects-10 do
			local legId=i+10
			if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], legId) then
				legTxt= legTxt .. StrColor(255,255,30,"\n\n - " .. legendaryEffects[legId])
			end
		end
		
		t.Text=legTxt
	end
	
	if t.Stat==13 or t.Stat==14 then
		local bolsterLevel8=vars.MM7LVL+vars.MM6LVL
		local bolsterLevel7=vars.MM8LVL+vars.MM6LVL
		local bolsterLevel6=vars.MM8LVL+vars.MM7LVL
		local bolsterLevel8=math.max(bolsterLevel8-4,0)
		local bolsterLevel7=math.max(bolsterLevel7-4,0)
		local bolsterLevel6=math.max(bolsterLevel6-4,0)
		t.Text=t.Text .."\n\nLevels gained in MM6: " .. StrColor(255,255,153,round(vars.MM6LVL*100)/100) .. "\nLevels gained in MM7: " .. StrColor(255,255,153,round(vars.MM7LVL*100)/100) .. "\nLevels gained in MM8: " .. StrColor(255,255,153,round(vars.MM8LVL*100)/100) .. "\n\nBolster Level in MM6: " .. StrColor(255,255,153,round(bolsterLevel6)) .."\nBolster Level in MM7: " .. StrColor(255,255,153,round(bolsterLevel7)) .."\nBolster Level in MM8: " .. StrColor(255,255,153,round(bolsterLevel8))
	end
	if t.Stat==15 then
		local i=Game.CurrentPlayer
		local atk=Party[i]:GetMeleeAttack()
		local lvl=Party[i].LevelBase
		local hitChance= round((15+atk*2)/(30+atk*2+lvl)*10000)/100
		t.Text=string.format("%s\n\nHit chance vs same level monster: %s%s",t.Text,StrColor(255,255,100,hitChance),StrColor(255,255,100,"%"))
	end
	
	if t.Stat==16 then
		local i=Game.CurrentPlayer
		--damage tracker
		vars.damageTrack=vars.damageTrack or {}
		vars.damageTrack[Party[i]:GetIndex()]=vars.damageTrack[Party[i]:GetIndex()] or 0

		vars.damageTrack=vars.damageTrack or {}
		vars.damageTrack[Party[i]:GetIndex()]=vars.damageTrack[Party[i]:GetIndex()] or 0
		vars.damageTrackRanged=vars.damageTrackRanged or {}
		vars.damageTrackRanged[Party[i]:GetIndex()]=vars.damageTrackRanged[Party[i]:GetIndex()] or 0
				
		local damage= vars.damageTrack[Party[Game.CurrentPlayer]:GetIndex()] or 0
		t.Text=string.format("%s\n\nTOTAL DAMAGE RECOUNT\nTotal Damage done: %s",t.Text,StrColor(255,255,100,round(damage)))
		local damage= vars.damageTrackRanged[Party[Game.CurrentPlayer]:GetIndex()] or 0
		t.Text=string.format("%s\nTotal Ranged Damage done: %s",t.Text,StrColor(255,255,100,round(damage)))

        t.Text = string.format("%s\n\nTotal percentage, Melee/Ranged/Total:", t.Text)
		local total_map_damage_m = 0
		local total_map_damage_r = 0                
		local player_damage_m = {}
		local player_damage_r = {}
		for i = 0, Party.High do
			player_damage_m[i] = (vars.damageTrack[Party[i]:GetIndex()] or 0)
			player_damage_r[i] = (vars.damageTrackRanged[Party[i]:GetIndex()] or 0)
			total_map_damage_m = total_map_damage_m + player_damage_m[i]
			total_map_damage_r = total_map_damage_r + player_damage_r[i]
		end
		
		total_map_damage_m=math.max(total_map_damage_m,1)
		total_map_damage_r=math.max(total_map_damage_r,1)
        for i = 0, Party.High do
            t.Text = string.format("%s\n %s\t %29s\t%32s %s\t%37s %s\t%42s", t.Text, Party[i].Name,
			round(100 * player_damage_m[i] / total_map_damage_m),'/', 
			round(100 * player_damage_r[i] / total_map_damage_r),'/',
			round(100 * (player_damage_m[i] + player_damage_r[i]) / (total_map_damage_m + total_map_damage_r)),' %')
        end
		
		--HEALING RECOUNT
		for i=0,Party.High do
			local id=Party[i]:GetIndex()
			--initialize
			vars.regenerationHeal=vars.regenerationHeal or {}
			vars.regenerationHeal[id]=vars.regenerationHeal[id] or 0
			
			vars.healingDone=vars.healingDone or {}
			vars.healingDone[id]=vars.healingDone[id] or 0
			
			vars.leechDone=vars.leechDone or {}
			vars.leechDone[id]=vars.leechDone[id] or 0
		end
		local id=Party[Game.CurrentPlayer]:GetIndex()
		--show
		t.Text = t.Text .. "\n\nTOTAL HEALING RECOUNT:\nTotal Healing Done:  " .. StrColor(0,255,0,vars.healingDone[id]) .. "\nTotal Regen Healing: " .. StrColor(0,255,0,vars.regenerationHeal[id]) .. "\nTotal Leech Healing: " .. StrColor(0,255,0,vars.leechDone[id])
		
		--matrix
		t.Text = t.Text .. "\n\nTotal percentage, Heal/Regen/Leech/Total:"

		--totals
		local tot1=0
		local tot2=0
		local tot3=0
		for i=0,Party.High do
			local id=Party[i]:GetIndex()
			tot1=tot1+vars.healingDone[id]
			tot2=tot2+vars.regenerationHeal[id]
			tot3=tot3+vars.leechDone[id]
		end
		tot1=math.max(tot1,1)
		tot2=math.max(tot2,1)
		tot3=math.max(tot3,1)
		local tot4=tot1+tot2+tot3
		
        for i = 0, Party.High do
			local id=Party[i]:GetIndex()
            t.Text = string.format("%s\n %s\t %29s\t%32s %s\t%37s %s\t%42s %s\t%47s", t.Text, Party[i].Name,
			round(100 * vars.healingDone[id] / tot1),'/', 
			round(100 * vars.regenerationHeal[id] / tot2),'/',
			round(100 * vars.leechDone[id] / tot3),'/',
			round(100 * (vars.healingDone[id]+vars.regenerationHeal[id]+vars.leechDone[id]) / tot4),' %')
        end
		
		t.Text = t.Text .. "\n\nOnly healing done when monsters are in the nearbies is counted" 
		
	end
	
	
	
	if t.Stat==17 then
		local i=Game.CurrentPlayer
		local atk=Party[i]:GetRangedAttack()
		local lvl=Party[i].LevelBase
		local hitChance= round((15+atk*2)/(30+atk*2+lvl)*10000)/100
		t.Text=string.format("%s\n\nHit chance vs same level monster: %s%s",t.Text,StrColor(255,255,100,hitChance),StrColor(255,255,100,"%"))
	end
	
	if t.Stat==18 then
		local i=Game.CurrentPlayer
		mapvars.damageTrackRanged=mapvars.damageTrackRanged or {}
		mapvars.damageTrackRanged[Party[i]:GetIndex()]=mapvars.damageTrackRanged[Party[i]:GetIndex()] or 0

		mapvars.damageTrack=mapvars.damageTrack or {}
		mapvars.damageTrack[Party[i]:GetIndex()]=mapvars.damageTrack[Party[i]:GetIndex()] or 0
		mapvars.damageTrackRanged=mapvars.damageTrackRanged or {}
		mapvars.damageTrackRanged[Party[i]:GetIndex()]=mapvars.damageTrackRanged[Party[i]:GetIndex()] or 0

		local damage= mapvars.damageTrack[Party[Game.CurrentPlayer]:GetIndex()] or 0
		t.Text=string.format("%s\n\nCURRENT MAP DAMAGE RECOUNT\nMelee Damage done in current map: %s",t.Text,StrColor(255,255,100,round(damage)))
		local damage= mapvars.damageTrackRanged[Party[Game.CurrentPlayer]:GetIndex()] or 0
		t.Text=string.format("%s\nRanged Damage done in current map: %s",t.Text,StrColor(255,255,100,round(damage)))

            	t.Text = string.format("%s\n\nMap percentage, Melee/Ranged/Total:", t.Text)
		local total_map_damage_m = 0
		local total_map_damage_r = 0                
		local player_damage_m = {}
		local player_damage_r = {}
		for i = 0, Party.High do
			player_damage_m[i] = (mapvars.damageTrack[Party[i]:GetIndex()] or 0)
			player_damage_r[i] = (mapvars.damageTrackRanged[Party[i]:GetIndex()] or 0)
			total_map_damage_m = total_map_damage_m + player_damage_m[i]
			total_map_damage_r = total_map_damage_r + player_damage_r[i]
		end
		
		total_map_damage_m=math.max(total_map_damage_m,1)
		total_map_damage_r=math.max(total_map_damage_r,1)
        for i = 0, Party.High do
            t.Text = string.format("%s\n %s\t %29s\t%32s %s\t%37s %s\t%42s", t.Text, Party[i].Name,
			round(100 * player_damage_m[i] / total_map_damage_m),'/', 
			round(100 * player_damage_r[i] / total_map_damage_r),'/',
			round(100 * (player_damage_m[i] + player_damage_r[i]) / (total_map_damage_m + total_map_damage_r)),' %')
        end
		
		
		--HEALING RECOUNT
		for i=0,Party.High do
			local id=Party[i]:GetIndex()
			--initialize
			mapvars.regenerationHeal=mapvars.regenerationHeal or {}
			mapvars.regenerationHeal[id]=mapvars.regenerationHeal[id] or 0
			
			mapvars.healingDone=mapvars.healingDone or {}
			mapvars.healingDone[id]=mapvars.healingDone[id] or 0
			
			mapvars.leechDone=mapvars.leechDone or {}
			mapvars.leechDone[id]=mapvars.leechDone[id] or 0
		end
		local id=Party[Game.CurrentPlayer]:GetIndex()
		--show
		t.Text = t.Text .. "\n\nCURRENT MAP HEALING RECOUNT:\nHealing Done in current Map:  " .. StrColor(0,255,0,mapvars.healingDone[id]) .. "\nRegen Healing in current Map: " .. StrColor(0,255,0,mapvars.regenerationHeal[id]) .. "\nLeech Healing in current Map: " .. StrColor(0,255,0,mapvars.leechDone[id])
		
		--matrix
		t.Text = t.Text .. "\n\nMap percentage, Heal/Regen/Leech/Total:"

		--totals
		local tot1=0
		local tot2=0
		local tot3=0
		for i=0,Party.High do
			local id=Party[i]:GetIndex()
			tot1=tot1+mapvars.healingDone[id]
			tot2=tot2+mapvars.regenerationHeal[id]
			tot3=tot3+mapvars.leechDone[id]
		end
		tot1=math.max(tot1,1)
		tot2=math.max(tot2,1)
		tot3=math.max(tot3,1)
		local tot4=tot1+tot2+tot3
		
        for i = 0, Party.High do
			local id=Party[i]:GetIndex()
            t.Text = string.format("%s\n %s\t %29s\t%32s %s\t%37s %s\t%42s %s\t%47s", t.Text, Party[i].Name,
			round(100 * mapvars.healingDone[id] / tot1),'/', 
			round(100 * mapvars.regenerationHeal[id] / tot2),'/',
			round(100 * mapvars.leechDone[id] / tot3),'/',
			round(100 * (mapvars.healingDone[id]+mapvars.regenerationHeal[id]+mapvars.leechDone[id]) / tot4),' %')
        end
		t.Text = t.Text .. "\n\nOnly healing done when monsters are in the nearbies is counted" 
	end
	
	if t.Stat>=19 and t.Stat<=24 then
		t.Text=t.Text .. "\n\nDamage is reduced by an amount equal to % shown.\n\nLight resistance is equal to the lowest between Mind and Body resistances.\nDark resistance is equal to the lowest between elemental resistances.\nEnergy resistance is equal to the lowest resistance."
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
		t.HP=round(t.HP)
		--SP
		totSP=Party[t.PlayerIndex]:GetFullSP()
			for it in Party[t.PlayerIndex]:EnumActiveItems() do
				if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 then		
					t.SP=t.SP+math.max(totSP*0.01-1,0)
				end
			end
		t.SP=round(t.SP)
	end
end

painReflectionHit=false
--fix for pain reflection:
function events.CalcDamageToMonster(t)
	if t.Monster.SpellBuffs[19].ExpireTime>=Game.Time then
		painReflectionHit=true
	end
end


--reduce damage by %
function events.CalcDamageToPlayer(t)
	local data=mawCustomMonObj or WhoHitPlayer()
	local pl=t.Player
	local lvl=0
	if data and data.Monster then
		local mon=data.Monster
		lvl=getMonsterLevel(mon)
	end
	--dodging DODGE 
	local dodging=0
	local Skill, Mas = SplitSkill(pl:GetSkill(const.Skills.Dodging))
	if Mas == 4 then
		dodging=Skill+10
	end
	dodgeChance=1-0.995^(dodging)
	roll=math.random()
	if roll<=dodgeChance then
		t.Result=0
		evt.FaceExpression{Player = t.PlayerIndex, Frame = 33}
		return
	end
	
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
		end
		if mapvars.nameIdMult and mapvars.nameIdMult[data.Monster.NameId] and mapvars.nameIdMult[data.Monster.NameId][data.MonsterAction+1] then
			t.Damage=t.Damage*mapvars.nameIdMult[data.Monster.NameId][data.MonsterAction+1]
		elseif data.MonsterAction<=1 then
			t.Damage=t.Damage*overflowMult[data.Monster.Id][data.MonsterAction+1]
		end
	end
	
	if t.DamageKind==4 and pl.SpellBuffs[26].ExpireTime>Game.Time then --mistform 
		t.Damage=t.Damage*0.25
	end
	if t.Monster and t.Monster.SpellBuffs[const.MonsterBuff.DamageHalved].ExpireTime>=Game.Time then
		t.Damage=t.Damage/2
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
	--mapping
	if getMapAffixPower(14) and math.random()<getMapAffixPower(14) then
		t.DamageKind=12
	end
	--carnage fix
	if data and data.Player and data.Spell==133 then
		t.Result=0
		return
	end
	
	--properly calculate friendly fire damage
	if data and data.Player and data.Spell and data.Spell<133 and data.Spell>0 then	
		local s,m = SplitSkill(data.Player.Skills[const.Skills.Learning])
		local diceMin, diceMax, damageAdd = ascendSpellDamage(s, m, data.Spell,data.Player:GetIndex())
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
	
	--apply Damage
	--modify spell damage as it's not handled in maw-monsters
	if data and data.Monster and data.Object and data.Object.Spell<100 and data.Object.Spell>0 then
		oldLevel=BLevel[data.Monster.Id]
		local bonus=math.max((lvl^0.88-BLevel[data.Monster.Id]^0.88),0)
		dmgMult=getMonsterDamage(lvl,"diffMult")
		if data.Object.Spell==6 or data.Object.Spell==97 then
			dmgMult=dmgMult/2
		end
		t.Damage=(t.Result+bonus)*dmgMult
	end
	if data and data.Monster and data.Object and data.Object.Spell<100 and data.Object.Spell>0 then
		t.Result = calcMawDamage(t.Player,t.DamageKind,t.Damage,false,lvl) -- spell randomization is off
	elseif data and data.Monster then
		t.Result = calcMawDamage(t.Player,t.DamageKind,t.Damage,false,lvl)
	else
		t.Result = calcMawDamage(t.Player,t.DamageKind,t.Damage,true)
	end
	if reflectedDamage then
		reflectedDamage=false
		t.Result=t.Result^0.9
		return
	end
	--PAIN REFLECTION FIX
	if painReflectionHit then
		painReflectionHit=false
		t.Result=t.Result^0.85
		return
	end
	
	--add difficulty related damage
	if Game.BolsterAmount%50~=0 then
		Game.BolsterAmount=100
	end
	local lvl=false
	if data and data.Monster then
		lvl=getMonsterLevel(data.Monster)
	end
	--Check for any difficulty
	if Game.BolsterAmount<=200 then
		if data and data.Monster then
			t.Result=t.Result*getMonsterDamage(lvl,"diffMult")
		end
	end
	if Game.BolsterAmount==300 then
		if data and data.Monster then
			t.Result=t.Result*getMonsterDamage(lvl,"diffMult")
		elseif ((t.DamageKind~=4 and t.DamageKind~=2) or Map.IndoorOrOutdoor==1) then --drown and fall
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
			if vars.freeProgression then
				mapLevel=bolster+(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3
			else
				mapLevel=mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High
			end
			
			--trap and objects multiplier
			mult=(mapLevel/20+1)*3
			if data and data.Object and data.Object.SpellType==15 then 
				bonusDamage=mapLevel/24
			else
				bonusDamage=mapLevel/8
			end
			damage=(t.Damage+bonusDamage)*mult
			local s,m=SplitSkill(t.Player.Skills[const.Skills.Perception])
			damage=damage*math.min((11-m*2)/10,1)
			t.Result=math.min(calcMawDamage(t.Player,t.DamageKind,damage),mapLevel*10)
		end
	end
	if vars.Mode==2 then
		if data and data.Monster then
			t.Result=t.Result*getMonsterDamage(lvl,"diffMult")
		elseif (t.DamageKind~=4 and t.DamageKind~=2) or Map.IndoorOrOutdoor==1 then --drown and fall
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
			if vars.freeProgression then
				mapLevel=bolster+(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3
			else
				mapLevel=mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High
			end
			if mapvars.mapAffixes then
				mapLevel=(mapvars.mapAffixes.Power*10+(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3)
			end
			--trap and objects multiplier
			local damage=getMonsterDamage(mapLevel)
			
			if data and data.Object and data.Object.SpellType==15 then 
				damage=damage/3
			end
			local s,m=SplitSkill(t.Player.Skills[const.Skills.Perception])
			damage=damage*math.min((11-m*2)/10,1)
			t.Result=calcMawDamage(t.Player,t.DamageKind,damage)
		end
	end
	if data and data.Monster and data.Monster.NameId>220 then
		local mon=data.Monster
		local skill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
		if skill=="Exploding" then
			t.Result=t.Result/2
			aoeDamage=t.Result/Party.Count
			for i=0,Party.High do
				Party[i].HP=Party[i].HP-aoeDamage
				Party[i]:ShowFaceAnimation(24)
			end
		end
	end
end

--TOOLTIPS
function events.Action(t)
	if vars.MAWSETTINGS.buffRework=="ON" then
		if t.Action==94 then
			local i=t.Param-1
			if i>=0 and i<=Party.High and vars.currentManaPool[i] and vars.maxManaPool[i]>0 then
				local manaPool=round(vars.currentManaPool[i]/vars.maxManaPool[i]*1000)/10
				Game.GlobalTxt[212]=StrColor(0,100,255,"Mana " .. manaPool .. "%")
			end
		end
	end
end
function events.Tick()
	if Game.CurrentCharScreen==100 and Game.CurrentScreen==7 then
		i=Game.CurrentPlayer 
		if i==-1 then return end --prevent bug message
		if vars.MAWSETTINGS.buffRework=="ON" and vars.maxManaPool[i]>0 then
			vars.currentManaPool[i]=vars.currentManaPool[i] or 1
			vars.maxManaPool[i]=vars.maxManaPool[i] or 1
			local manaPool=round(vars.currentManaPool[i]/vars.maxManaPool[i]*1000)/10
			Game.GlobalTxt[212]=StrColor(0,100,255,"Mana " .. manaPool .. "%")
		end
		pl=Party[i]
		local resistances={}
		local resistances2={}
		local damageList={0,1,2,3,7,8}
		for i=10,15 do
			resistances[i]=pl:GetResistance(i)
			if resistances[i]>=64000 then
				resistances[i]="Immune"
			end
			resistances2[i]=100-math.max(round(calcMawDamage(pl,damageList[i-9],1000))/10, 0)
			resistances2[i]=round(resistances2[i]*100)/100
			if resistances2[i]%1==0 then
				resistances2[i]=resistances2[i] .. ".0"
			end
		end
		local resistanceText={}
		local id=pl:GetIndex()
		for i=1,6 do
			if vars.normalEnchantResistance[id][10+i]>0 then
				resistanceText[i]=StrColor(0,255,0,string.format("%6s", resistances[9+i]))
			else
				resistanceText[i]=string.format("%6s", resistances[9+i])
			end
		end
		Game.GlobalTxt[87]=StrColor(255, 70, 70,    string.format(resListBackup[1] .. "\t            %s%s ",resistances2[10],"%")) .. resistanceText[1] .. "\n\n\n\n\n\n\n\n\n"
		Game.GlobalTxt[6]=StrColor(173, 216, 230,   string.format(resListBackup[2] .. "\t            %s%s ",resistances2[11],"%")) .. resistanceText[2] .. "\n\n\n\n\n\n\n\n\n"
		Game.GlobalTxt[240]=StrColor(100, 180, 255, string.format(resListBackup[3] .. "\t            %s%s ",resistances2[12],"%")) .. resistanceText[3] .. "\n\n\n\n\n\n\n\n\n"
		Game.GlobalTxt[70]=StrColor(153, 76, 0,     string.format(resListBackup[4] .. "\t            %s%s ",resistances2[13],"%")) .. resistanceText[4] .. "\n\n\n\n\n\n\n\n\n"
		Game.GlobalTxt[142]=StrColor(200, 200, 255, string.format(resListBackup[5] .. "\t            %s%s ",resistances2[14],"%")) .. resistanceText[5] .. "\n\n\n\n\n\n\n\n\n"
		Game.GlobalTxt[29]=StrColor(255, 192, 203,  string.format(resListBackup[6] .. "\t            %s%s ",resistances2[15],"%"))	 .. resistanceText[6] .. "\n\n\n\n\n\n\n\n\n"
		statsChanged=true
	elseif statsChanged and (Game.CurrentCharScreen~=100 or Game.CurrentScreen~=7) then
		Game.GlobalTxt[87]=resListBackup[1]
		Game.GlobalTxt[6]=resListBackup[2]
		Game.GlobalTxt[240]=resListBackup[3]
		Game.GlobalTxt[70]=resListBackup[4]
		Game.GlobalTxt[142]=resListBackup[5]
		Game.GlobalTxt[29]=resListBackup[6]
		statsChanged=false
	end
end

function events.BeforeLoadMap()
	if not resListBackup then
		resListBackup={}
		resListBackup[1]=Game.GlobalTxt[87]
		resListBackup[2]=Game.GlobalTxt[6]
		resListBackup[3]=Game.GlobalTxt[240]
		resListBackup[4]=Game.GlobalTxt[70]
		resListBackup[5]=Game.GlobalTxt[142]
		resListBackup[6]=Game.GlobalTxt[29]
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
	local data=WhoHitMonster()
	if data and data.Player and data.Spell then
		if data.Spell==const.Spells.Blades then
			t.DamageKind=const.Damage.Phys
		end
	end
	index=table.find(damageKindMap,t.DamageKind)
	local res=t.Monster.Resistances[index]
	if data and data.Object and data.Object.Spell==133 then
		if data and data.Player then
			local it=t.Player:GetActiveItem(2)
			if it then 
			skill=it:T().Skill
				if skill==const.Skills.Bow then
					local s,m=SplitSkill(t.Player.Skills[const.Skills.Bow])
					if m==4 then
						res=math.min(t.Monster.Resistances[0]%1000, t.Monster.Resistances[4])
					end
				end
			end
		end
	end
	if not res or t.Result==0 then return end
	res=res%1000
	--spear reduction
	if t.Player and data and data.Object==nil and t.DamageKind==4 then
		local it=t.Player:GetActiveItem(1)
		if it then 
			local skill=it:T().Skill
			if skill==const.Skills.Spear then
				local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Spear))
				if m==4 then
					local id=t.Monster:GetIndex()
					mapvars.originalResistance=mapvars.originalResistance or {}
					mapvars.originalResistance[id]=mapvars.originalResistance[id] or t.Monster.Resistances[index]
					mapvars.spearDamageIncrease=mapvars.spearDamageIncrease or {}
					mapvars.spearDamageIncrease[id]=mapvars.spearDamageIncrease[id] or 0
					local mult=damageMultiplier[t.PlayerIndex]["Melee"]
					local damageIncrease=(2+s*0.02)*mult
					mapvars.spearDamageIncrease[id]=mapvars.spearDamageIncrease[id]+damageIncrease
					local reduction=calcSpearResReduction(mapvars.spearDamageIncrease[id])
					t.Monster.Resistances[index]=round(math.max(mapvars.originalResistance[id]-reduction,0))
				end
			end
		end
	end
	if t.Player and vars.legendaries and vars.legendaries[t.PlayerIndex] and table.find(vars.legendaries[t.PlayerIndex], 29) then
		if data and data.Object==nil and t.DamageKind~=4 then goto continue end --disable for melee elemental damage
		if data and table.find(aoespells, data.Spell) and math.random()>0.4 then goto continue end
		for i=0, 10 do
			if i~=5 then
				if i==4 then
					local id=t.Monster:GetIndex()
					if mapvars.originalResistance and mapvars.originalResistance[id] then
						mapvars.originalResistance[id]=math.max(mapvars.originalResistance[id]-1,0)
					else
						t.Monster.Resistances[i]=math.max(t.Monster.Resistances[i]-1,0)
					end
				else
					t.Monster.Resistances[i]=math.max(t.Monster.Resistances[i]%1000-1,0)+math.floor(t.Monster.Resistances[i]/1000)*1000
				end
			end
		end
	end
	::continue::
	--retaliation code
	if t.Player then
		local id=t.Player:GetIndex()
		if vars.retaliation and vars.retaliation[id] and vars.retaliation[id]["Time"] and vars.retaliation[id].Time+const.Minute*5>Game.Time and vars.retaliation[id].Stacks>0 then
			local pl=t.Player
			local s,m=SplitSkill(Skillz.get(pl,53))
			local fullHP=pl:GetFullHP()
			local stacks=vars.retaliation[id].Stacks
			if m<4 then
				stacks=1
			end
			local powerMult, DPS2, DPS3, vitMult=calcPowerVitality(pl, false)
			local vit=round(vitMult^0.35)
			local power=round(powerMult^0.35)
			local totalRetDamage=power*vit*s*stacks
			t.Result=t.Result+totalRetDamage
			
			if 0.25*stacks>math.random() then
				local stunDuration=const.Minute
				if t.Monster.NameId>=220 and t.Monster.NameId<=300 then
					stunDuration=stunDuration/2
				end
				t.Monster.SpellBuffs[6].ExpireTime=Game.Time+const.Minute
			end
			function events.Tick()
				events.Remove("Tick",1)
				pl.RecoveryDelay=pl.RecoveryDelay*(math.max(1-0.3*stacks,0))
			end
			vars.retaliation[id].Stacks=0
		end
	end
	
	res=1-1/2^(res/100)
	t.Result = t.Result * (1-res)
end

--spear reset stacks after kill
function events.MonsterKilled(mon)
	local id=mon:GetIndex()
	if mapvars.spearDamageIncrease and mapvars.spearDamageIncrease[id] then
		mapvars.spearDamageIncrease[id]=0
	end
end


function calcSpearResReduction(y)
    local log2 = math.log(1 + y / 100) / math.log(2)
    local reduction = 100 * log2
    return reduction
end

--stats breakpoints
function events.GetStatisticEffect(t)
	if t.Value >=25 then
		t.Result=math.floor(t.Value/5)
	end
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

buffToResistance={
	[0] = 6,
	[1] = 0,
	[2] = 17,
	[3] = 4,
	[6] = 12,
	[7] = 12,
	[8] = 1,
	[9] = {12,1},
	[10] = {6,0,17,4},
	[12] = {12,1,6,0,17,4},
}

buffToSpell={
	[0] = 3,
	[1] = 14,
	[2] = 25,
	[3] = 36,
	[6] = 58,
	[7] = 58,
	[8] = 69,
	[9] = {58,69},
	[10] = {3,14,25,36},
	[12] = {58,69,3,14,25,36},
}

function compute_damage(x)
    -- Start with the base damage multiplier
    local damage = 1
	x=math.max(x,0)
    -- Loop through each step from 1 to the floor of x
    for i = 1, math.floor(x) do
        -- Multiply the damage by (2 - i*0.2)
        damage = damage * math.max(2.2 - i * 0.1, 1.8)
    end

    -- If x is not an integer, handle the fractional part
    local fractional_part = x - math.floor(x)
    if fractional_part > 0 then
        damage = damage * math.max(2.2 - (math.floor(x) + 1) * 0.1,1.8) ^ fractional_part
    end
	
    return damage
end


function calcMawDamage(pl,damageKind,damage,rand,monLvl)
	local monLvl=monLvl or pl.LevelBase
	local bolster=(math.max(Game.BolsterAmount, 100)/100-1)/4+1
	if vars.insanityMode then
		bolster=3
	end
	local id=pl:GetIndex()
	--AC for phys
	
	
	--[18]="Reduce all damage taken by 10%",
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 18) then
		damage=damage*0.9
	end	
	
	--PHYSICAL DAMAGE CALCULATION
	if damageKind==4 then 		
		local AC=pl:GetArmorClass()
		local AC=pl:GetArmorClass()
		local AC=pl:GetArmorClass()--multiple times to avoid chance to hit code to interfere with AC
		if getMapAffixPower(28) then
			AC=AC*(1-getMapAffixPower(28)/100)
		end
		local divider=math.min(120+monLvl*0.75*bolster,600*bolster)
		local reduction=compute_damage(AC/divider)
		local damage=round(damage/reduction)
		return damage
	end
	
	--MAGIC DAMAGE CALCULATION
	--shield buff
	if vars.MAWSETTINGS.buffRework=="ON" then
		if Party.SpellBuffs[14].ExpireTime>=Game.Time then
			local s,m=getBuffSkill(17)
			local s2,m2=getBuffSkill(86)
			s=math.max(s,s2/1.5)
			m=math.max(m,m2)
			damage=damage*(0.9-0.002*s)
		end
	else
		if pl.SpellBuffs[11].ExpireTime>Game.Time or Party.SpellBuffs[14].ExpireTime>Game.Time  then --shield buff
			damage=damage*0.85
		end
	end
	--shield skill
	if pl:GetActiveItem(0) then
		local it=pl:GetActiveItem(0)
		if it and it:T().Skill==const.Skills.Shield then --shield skill
			s,m=SplitSkill(pl.Skills[const.Skills.Shield])
			if m>=4 then
				damage=damage*0.85
			end
		end
	end
	--enchant reduction
	if vars.shieldEnchant and vars.shieldEnchant[id] then
		damage=damage*0.85
	end
	
	--get resistances
	if not damageKindResistance[damageKind] then
		local damage=round(damage)
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
	
	if getMapAffixPower(29) then
		res=res*(1-getMapAffixPower(29)/100)
	end
	local divider=math.min(60+monLvl*0.5*bolster,400*bolster)
	local reduction=compute_damage(res/divider)
	local res=1/reduction	
	
	--base enchants
	currentItemRes=10000
	for i=1,#resList do
		local itemRes = vars.normalEnchantResistance[id][resList[i]+1]
		if itemRes<currentItemRes then
			currentItemRes=itemRes
		end
	end
	
	
	--LEGENDARY POWER 16
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 16) then
		currentItemRes=currentItemRes*1.5
	end
	
	currentItemRes=1/1.5^(currentItemRes^0.6/10)
	res=res*currentItemRes
	--randomize resistance
	if res>0 and rand then
		local roll=(math.random()+math.random())-1
		res=math.max(0, res+(math.min(res,1-res)*roll))
	end
	
	local damage=round(damage*res)
	return damage
end



function events.Tick()
	if Game.CurrentCharScreen==100 and Game.CurrentScreen==7 then
		local i=Game.CurrentPlayer
		if i<0 or i>Party.High then return end
		local pl=Party[i]
		DPS1, DPS2, DPS3, vitality=calcPowerVitality(pl, true)
		--get spell and its damage
		spellIndex = pl.AttackSpell==0 and pl.QuickSpell or pl.AttackSpell
		
        if spellPowers[spellIndex] or (healingSpells and healingSpells[spellIndex]) then 		
			Game.GlobalTxt[47]=string.format("M/R/S:%s/%s/%s\n\n\n\n\n\n\n",StrColor(255,0,0,DPS1),StrColor(200,200,0,DPS2),StrColor(50,50,220,DPS3))
		else
		    Game.GlobalTxt[47]=string.format("M/R:%s/%s\n\n\n\n\n\n\n",StrColor(255,0,0,DPS1),StrColor(200,200,0,DPS2))
		end
		Game.GlobalTxt[172]=string.format("Vitality: %s\n\n\n\n\n\n\n\n",StrColor(0,255,0,vitality))
	else
		Game.GlobalTxt[47]="Condition"
		Game.GlobalTxt[172]="Quick Spell"
	end
end


function events.GameInitialized2()
	for i=12,38 do
		Skillz.setDesc(i,1,Skillz.getDesc(i,1) .. "\n")
	end
end

function calcPowerVitality(pl, statsMenu)
	local DPS1=0
	local DPS2=0
	local DPS3=0
	--get spell and its damage
	spellIndex = pl.AttackSpell==0 and pl.QuickSpell or pl.AttackSpell
	--MELEE
	local low=pl:GetMeleeDamageMin()
	local high=pl:GetMeleeDamageMax()
	local might=pl:GetMight()
	local accuracy=pl:GetAccuracy()
	local luck=pl:GetLuck()
	local delay=pl:GetAttackDelay()
	local dmg=(low+high)/2
	--hit chance
	local atk=pl:GetMeleeAttack()
	local lvl=pl.LevelBase
	local hitChance= (15+atk*2)/(30+atk*2+lvl)
	local critChance, critMult=getCritInfo(pl)
	local enchantDamage=0
	for i=0,1 do 
		local it=pl:GetActiveItem(i)
		if it and it:T().EquipStat<=2 then
			local dmg1=calcEnchantDamage(pl, it, 0, false, false, "power")
			local dmg2=calcFireAuraDamage(pl, it, 0, false, false, "power")
			enchantDamage=enchantDamage+dmg1+dmg2
		end
	end
	DPS1=round((dmg*(1+math.min(critChance,1)*(critMult-1))+enchantDamage)/(delay/60)*hitChance*damageMultiplier[pl:GetIndex()]["Melee"]*math.max(critChance,1))
	
	--RANGED
	local low=pl:GetRangedDamageMin()
	local high=pl:GetRangedDamageMax()
	local delay=pl:GetAttackDelay(true)
	local dmg=(low+high)/2
	--hit chance
	local atk=pl:GetRangedAttack()
	local hitChance= (15+atk*2)/(30+atk*2+lvl)
	local it=pl:GetActiveItem(2)
	enchantDamage=0
	if it and it:T().EquipStat<=2 then
		local dmg=calcEnchantDamage(pl, it, 0, false, false, "power")
		local dmg2=calcFireAuraDamage(pl, it, 0, false, false, "power")
		enchantDamage=enchantDamage+dmg+dmg2
	end
	local s,m=SplitSkill(pl.Skills[const.Skills.Bow])
	if m>=3 then
		dmg=dmg*2
	end
	local DPS2=round((dmg*(1+math.min(critChance,1)*(critMult-1))+enchantDamage)/(delay/60)*hitChance*damageMultiplier[pl:GetIndex()]["Ranged"]*math.max(critChance,1))
	if spellPowers[spellIndex] or (healingSpells and healingSpells[spellIndex]) then 
		--calculate damage
		--skill
		skillType=math.floor((spellIndex-1)/11)+12
		skill, mastery=SplitSkill(pl:GetSkill(skillType))
		local mastery=math.max(1,mastery)
		--SPELLS
		local s, m = SplitSkill(pl.Skills[const.Skills.Learning])
		if spellPowers[spellIndex] then
			diceMin, diceMax, damageAdd, ascensionTier = ascendSpellDamage(s, m, spellIndex)
		else
			diceMin, diceMax, damageAdd = healingSpells[spellIndex].Scaling[mastery], healingSpells[spellIndex].Scaling[mastery], healingSpells[spellIndex].Base[mastery]
		end
		
		power=damageAdd + skill*(diceMin+diceMax)/2
		intellect=pl:GetIntellect()	
		personality=pl:GetPersonality()
		bonus=math.max(intellect,personality)
		if healingSpells and healingSpells[spellIndex] then
			critChance, critDamage=getCritInfo(pl, "heal")
			power=power*(1+bonus/2000) 
		else
			critChance, critDamage=getCritInfo(pl, "spell")
			power=power*(1+bonus/1000) 
		end
		enchantDamage=0
		for i=0,2 do 
			local it=pl:GetActiveItem(i)
			if it and it:T().EquipStat<=2 then
				local dmg=calcEnchantDamage(pl, it, 0, false, true, "power")
				local dmg2=calcFireAuraDamage(pl, it, 0, false, true, "power")
				enchantDamage=enchantDamage+dmg+dmg2
			end
		end
		enchantDamage=enchantDamage*1.2^ascensionTier
		if table.find(aoespells, spellIndex) then
			enchantDamage=enchantDamage/2.5
		end
		haste=math.floor(pl:GetSpeed()/10)/100+1
		delay=getSpellDelay(pl,spellIndex) or 100
		DPS3=round((power*(1+math.min(critChance,1)*(critDamage-1))+enchantDamage)/(delay/60)*math.max(critChance,1))			
	end
			
	local fullHP=pl:GetFullHP()
	--AC
	local ac=pl:GetArmorClass()
	local acReduction=1-calcMawDamage(pl,4,10000)/10000
	local lvl=pl.LevelBase
	local ac=ac/(Game.BolsterAmount/100)
	local blockChance= 1-(5+lvl*2)/(10+lvl*2+ac)
	local ACRed= 1 - (1-blockChance)*(1-acReduction)
	--dodging
	local speed=pl:GetSpeed()
	local dodging=0
	local Skill, Mas = SplitSkill(pl:GetSkill(const.Skills.Dodging))
	if Mas == 4 then
		dodging=Skill+10
	end
	--local speed=pl:GetSpeed()
	--local speedEffect=speed/10
	local dodgeChance=0.995^(dodging)
	local fullHP=fullHP/dodgeChance
	--resistances
	res={0,1,2,3,7,8,12}
	for v=1,7 do 
		res[v]=1-calcMawDamage(pl,res[v],10000)/10000
	end
	
	--calculation
	local reduction= 1 - (ACRed/2 + res[1]/16 + res[2]/16 + res[3]/16 + res[4]/16 + res[5]/16 + res[6]/16 + res[7]/8)
	
	--dk/shaman bonus
	if table.find(shamanClass, pl.Class) then
		local s=SplitSkill(pl.Skills[const.Skills.Air])
		reduction=reduction*0.99^s
	elseif table.find(dkClass, pl.Class) then
		local s1=SplitSkill(pl.Skills[const.Skills.Body])
		local s2=SplitSkill(pl.Skills[const.Skills.Dark])
		reduction=reduction*0.99^((s1+s2)/2)
	end
	
	vitality=round(fullHP/reduction)
	if statsMenu then
		DPS1=shortenNumber(DPS1, 4)
		DPS2=shortenNumber(DPS2, 4)
		DPS3=shortenNumber(DPS3, 4)
		vitality=shortenNumber(vitality, 6)
	end
	return DPS1, DPS2, DPS3, vitality
end

--racial skills down below
function events.CalcStatBonusByItems(t)

	local Res = t.Stat
	if not (Res >= 10 and Res <= 15) then
		return
	end
	
	local Race = GetRace(t.Player, t.PlayerIndex)
	local lvl=t.Player.LevelBase
	if Race == 6 and (Res == 15 or Res == 14) then -- Lich's immunities
		t.Result = 65000
		t.Player.Resistances[6].Base = 65000
		t.Player.Resistances[7].Base = 65000
	
	elseif Race == 1 and Res == 14 then -- Vampire's mind immunity
		t.Result = 65000
		t.Player.Resistances[7].Base = 65000
	
	elseif (Race == 2 or Race == 7) and (Res == 10 or Res == 11 or Res == 12 or Res == 13) then -- elves
		t.Result = t.Result+25 + lvl
	
	elseif Race == 4 and (Res == 12 or Res == 13) then -- Troll's Water and Earth resistance.
		t.Result = t.Result + 25 + lvl
		
	elseif Race == 8 and (Res == 11 or Res == 13) then -- Goblins's Air and Earth resistance.
		t.Result = t.Result + 25 + lvl

	elseif Race == 9 and (Res == 13 or Res == 14) then -- Dwarf's Mind and Earth resistance.
		t.Result = t.Result + 25 + lvl
	elseif Race == 5 and Res == 10 then -- Dragon's bonus
		t.Result = t.Result + 100 + math.floor(lvl*2)

	end	
	
end

