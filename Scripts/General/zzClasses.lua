--code to share promotions
--game ordered from mm6 to mm8, first promotion then honorary promotion qbits, mm7 has 4 qbits total
promotionList={
--Archer
[1]=		{1657,1658,		1586,1587,1588,1589,	1537,20},--dark elf 
--Cleric
[2]=		{1649,1650,		1609,1610,1611,1612,	1546,31},
--Dark Elf
[3]=	{1657,1658,		1586,1587,1588,1589,	1537,20},--archer
--Dragon
[4]=		{1645,1646,		1568,1569,1570,1571,	1543,1544},--knight 
--Druid
[5]= 		{1653,1654,		1615,1616,1617,1618,	1546,31},--cleric
--Knight
[6]=		{1645,1646,		1568,1569,1570,1571,	1540,1541},
--Minotaur
[7]=	{1637,1638,		1592,1593,1594,1595,	1545,29},--paladin
--Monk
[8]=		{1645,1646,		1574,1575,1576,1577,	1538,1539},--knight and troll
--Paladin
[9]=	{1637,1638,		1592,1593,1594,1595,	1545,29},--minotaur
--Ranger
[10]=		{1657,1658,		1580,1581,1582,1583,	1537,20},--archer, dark elf
--Thief
[11]=		{1657,1658,		1564,1565,1566,1567,	1547,33},--archer, vampire
--Troll
[12]=		{1645,1646,		1568,1569,1570,1571,	1538,1539},--knight and monk
--Vampire
[13]=	{1657,1658,		1564,1565,1566,1567,	1547,33},--archer, thief
--Sorcerer
[14]=	{1641,1642,		1621,1622,1623,1624,	1548,35},--necromancer
--Necromancer
[15]=	{1641,1642,		1621,1622,1623,1624,	1548,35},--sorcerer
--Peasant
[16]=	{0,0,		0,0,0,0,	0,0},
--Seraphim
[17]=	{1649,1650,		1609,1610,1611,1612,	1546,31},--cleric
--DK
[18]=	{1645,1646,		1568,1569,1570,1571,	1540,1541},--same as knight
--SHAMAN
[19]=	{1653,1654,		1615,1616,1617,1618,	1546,31}, --same as druid
}

--mid promotionlist
midPromo={
--Seraphim
[17]=	{1646,1647,		1607,1608},--cleric
--DK
[18]=	{1643,1644,		1566,1567},--same as knight
--SHAMAN
[19]=	{1651,1652,		1613,1614}, --same as druid
}

function events.GameInitialized2()
	oldNames={}
	oldHP={}
	oldSP={}
	for i=0,Game.ClassNames.High do
		oldNames[i]=Game.ClassNames[i]
		oldHP[i]=Game.Classes.HPFactor[i]
		oldSP[i]=Game.Classes.SPFactor[i]
	end
end

promotionCount={}
function checkPromo()
	for i= 0,Game.Classes.HPFactor.High do
		--extablish which class needs upgrade
		if Game.ClassesExtra[i].Step==2 then
			totalPromotions=0
			prom=promotionList[Game.ClassesExtra[i].Kind]
			if Party.QBits[prom[1]] or Party.QBits[prom[2]] then
				totalPromotions=totalPromotions+1
			end
			if Party.QBits[prom[3]] or Party.QBits[prom[4]] or Party.QBits[prom[5]] or Party.QBits[prom[6]] then
				totalPromotions=totalPromotions+1
			end
			if prom[8]<105 then
				check=Party[0].Awards[prom[8]]
			else
				check=Party.QBits[prom[8]]
			end
			if Party.QBits[prom[7]] or check then
				totalPromotions=totalPromotions+1
			end
			promotionCount[Game.ClassesExtra[i].Kind]=totalPromotions
			--upgrade class
			if totalPromotions>1 then
				Game.Classes.HPFactor[i]=oldHP[i]*(0.75+0.25*totalPromotions)
				Game.Classes.SPFactor[i]=oldSP[i]*(0.75+0.25*totalPromotions)
				if totalPromotions==2 then
					Game.ClassNames[i]=string.format("Elder " .. oldNames[i])
				else
					Game.ClassNames[i]=string.format("Ultimate " .. oldNames[i])
				end
			else
				Game.Classes.HPFactor[i]=oldHP[i]
				Game.Classes.SPFactor[i]=oldSP[i]
				Game.ClassNames[i]=oldNames[i]
			end
		end
	end
	--check promotion
	for i=0,Party.High do
		class=Party[i].Class
		kind=Game.ClassesExtra[class].Kind
		if promotionCount[kind] and promotionCount[kind]>=1 and Game.ClassesExtra[class].Step<2 then --check if promotion
			--search for available promotions
			promotionCount={}
			for v=0,#Game.ClassesExtra do
				if Game.ClassesExtra[v].Kind==kind and Game.ClassesExtra[v].Step==2 then
					table.insert(promotionCount, v)
				end
			end
			if #promotionCount==1 then
				Party[i].Class=promotionCount[1]
			elseif #promotionCount>1 then
				Party[i].Class=promotionCount[math.random(1,#promotionCount)]
			end
		end
	end 
	
	--mid promo
	for i=0,Party.High do
		class=Party[i].Class
		kind=Game.ClassesExtra[class].Kind
		if Game.ClassesExtra[class].Step==0 and midPromo[Game.ClassesExtra[class].Kind] then
			prom=midPromo[Game.ClassesExtra[class].Kind]
			for v=1,4 do
				if Party.QBits[prom[v]] then
					Party[i].Class=Party[i].Class+1
					goto continue
				end
			end
			::continue::
		end
	end
end


function events.LoadMap()
	checkPromo()
end

function events.EvtGlobal(i)
	checkPromo()
end


----------------------------------------------------------------------
--SERAPHIM
----------------------------------------------------------------------
function events.GameInitialized2()
	Game.ClassDescriptions[53]="Seraphim is a divine warrior, blessed by the gods with otherworldly powers that set him apart from mortal fighters. His origins are shrouded in mystery, but it is said that he was chosen by the divine to carry out their will on the mortal plane. Some whisper that he was born from the union of a mortal and an angel, while others believe that he was created by the gods themselves. Regardless of his origins, there is no denying the power that Seraphim wields, and his presence on the battlefield is a testament to the will of the divine.\n\nProficiency in Plate, Sword, Mace, and Shield (can't dual wield)\n3 HP and 1 mana points gained per level\n\nAbilities:\n\nGods Wrath: Attacks deal extra magic damage based on Light skill (2 damage added per point in Light and Mind)\n\nHoly Strikes: Attacking will heal the most injured party member based on Body skill (2 points per point in Body and Spirit)\n\nDivine Protection: converts 25% of mana into self-healing when facing lethal attacks (2 healing per mana spent), 5 minutes cooldown."
end

--class ID
seraphClass={53,54,55}

--body magic will increase healing done on attack
--bunch of code for healing most injured player
function indexof(table, value)
	for i, v in ipairs(table) do
			if v == value then
				return i
			end
		end
	return nil
end
		
function events.CalcDamageToMonster(t)
	local data = WhoHitMonster()
		if data and data.Player and (data.Player.Class==55 or data.Player.Class==54 or data.Player.Class==53) and t.DamageKind==4 and data.Object==nil then
		--get body
		body=data.Player:GetSkill(const.Skills.Body)
		bodyS,bodyM=SplitSkill(body)

		--get spirit
		spirit=data.Player:GetSkill(const.Skills.Spirit)
		spiritS,spiritM=SplitSkill(spirit)
		
		
		
		-- Define the variables
		a={}
		a[0]=2
		a[1]=2
		a[2]=2
		a[3]=2
		a[4]=2
		for i=0,Party.High do
			if Party[i].Dead==0 and Party[i].Eradicated==0 then
				a[i] = Party[i].HP/Party[i]:GetFullHP()
			end
		end
		a, b, c, d, e= a[0], a[1], a[2], a[3], a[4] 
		-- Find the maximum value and its position
		min_value = math.min(a, b, c, d, e)
		min_index = indexof({a, b, c, d, e}, min_value)
		min_index = min_index - 1
		--Calculate heal value and apply
		levelBonus1=spiritM+math.floor(t.Player.LevelBase/100)
		levelBonus2=bodyM+math.floor(t.Player.LevelBase/100)
		healValue=(bodyS*levelBonus2+spiritS*levelBonus1)*damageMultiplier[t.PlayerIndex]["Melee"]
		personality=data.Player:GetPersonality()/2
		healValue=healValue*(1+personality/1000)
		--calculate crit
		critchance=data.Player:GetLuck()/15*10+50
		roll=math.random(1,1000)
		if roll<critchance then
			healValue=healValue*(1.5+personality*3/2000)
		end
		--apply heal
		evt[min_index].Add("HP",healValue)		
		--bug fix
		if Party[min_index].HP>0 then
		Party[min_index].Unconscious=0
		end
	end
		
end

--mind light increases melee damage

function events.GameInitialized2()
	--damage from skills
	function events.CalcStatBonusByItems(t)
		if t.Stat==const.Stats.MeleeDamageMax or t.Stat==const.Stats.MeleeDamageMin then
			if t.Player.Class==55 or t.Player.Class==54 or t.Player.Class==53 then
				light=t.Player:GetSkill(const.Skills.Light)
				lightS,lightM=SplitSkill(light)
				--get mind
				mind=t.Player:GetSkill(const.Skills.Mind)
				mindS,mindM=SplitSkill(mind)
				levelBonus1=mindM+math.floor(t.Player.LevelBase/100)
				levelBonus2=lightM+math.floor(t.Player.LevelBase/100)
				damage=mindS*levelBonus1 + lightS*levelBonus2
				t.Result=t.Result+damage
			end
		end	
	end
end

--AUTORESS SKILL

function events.LoadMap(wasInGame)
	vars.divineProtectionCooldown=vars.divineProtectionCooldown or {}
	for i=0,Party.High do
		local index=Party[i]:GetIndex()
		vars.divineProtectionCooldown[index]=vars.divineProtectionCooldown[index] or 0
	end
end

function events.GameInitialized2()
	function events.CalcDamageToPlayer(t)

	--divine protection
		if (t.Player.Class==55 or t.Player.Class==54 or t.Player.Class==53) and t.Player.Unconscious==0 and t.Player.Dead==0 and t.Player.Eradicated==0 then
			if vars.divineProtectionCooldown[t.PlayerIndex]==nil then
				vars.divineProtectionCooldown[t.PlayerIndex]=0
			end		
			if t.Result>=t.Player.HP and Game.Time>vars.divineProtectionCooldown[t.PlayerIndex] then
				totMana=t.Player:GetFullSP()
				currentMana=t.Player.SP
				treshold=totMana/4
				if currentMana>=treshold then
					t.Player.SP=t.Player.SP-(totMana/4)
					--calculate healing
					heal=totMana*2
					for i=0,Party.High do
						if Party[i]:GetIndex()==t.PlayerIndex then
							evt[i].Add("HP",heal)
						end
					end
					vars.divineProtectionCooldown[t.PlayerIndex] = Game.Time + const.Minute * 150
					Game.ShowStatusText("Divine Protection saves you from lethal damage")
					t.Result=math.min(t.Result, t.Player.HP-1)
				end
			end	
		end
	end
end

---deactivate offhand weapon
function events.CalcDamageToMonster(t)
	if t.Player and (t.Player.Class==55 or t.Player.Class==54 or t.Player.Class==53) then
		data=WhoHitMonster()
		if data and data.Player then
			item=data.Player:GetActiveItem(0)
		end
		if item~=nil then
			if item:T().Skill==1 then
				t.Result=0
				Message("Seraphim aren't able to dual wield")
			end
		end
	end
end

--skill tooltips
--tooltips
function events.GameInitialized2()
	baseSchoolsTxtSERAPH={
		[16]=Skillz.getDesc(16,1),
		[17]=Skillz.getDesc(17,1),
		[18]=Skillz.getDesc(18,1),
		[19]=Skillz.getDesc(19,1),
	}
end

local function seraphSkills(isSeraph, id)
	if isSeraph then
		pl=Party[id]
		
		local spiritS, spiritM=SplitSkill(pl:GetSkill(const.Skills.Spirit))
		local mindS, mindM=SplitSkill(pl:GetSkill(const.Skills.Mind))
		local bodyS, bodyM=SplitSkill(pl:GetSkill(const.Skills.Body))
		local lightS, lightM=SplitSkill(pl:GetSkill(const.Skills.Light))
		local lvlBonus=math.floor(pl.LevelBonus/100)
		--heal tooltips
		local pers=pl:GetPersonality()
		local healMult=1+pers/2000
		local spiritHeal=math.floor((spiritS*(spiritM+lvlBonus))*healMult)
		local bodyHeal=math.floor((bodyS*(bodyM+lvlBonus))*healMult)
		local txt=baseSchoolsTxtSERAPH[16] .. "\n\nSeraphim healing upon attack increases depending on Spirit magic, scaling with personality(weapon speed multiplier applies).\nGets 1 bonus heal each 100 levels.\n\n" .. "Current heal from Spirit: " .. StrColor(0,255,0,spiritHeal) .. "\n"
		Skillz.setDesc(16,1,txt)
		local txt=baseSchoolsTxtSERAPH[18] .. "\n\nSeraphim healing upon attack increases depending on Body magic, scaling with personality(weapon speed multiplier applies).\nGets 1 bonus heal each 100 levels.\n\n" .. "Current heal from Body: " .. StrColor(0,255,0,bodyHeal) .. "\n"
		Skillz.setDesc(18,1,txt)
		
		--damage tooltip
		local might=pl:GetMight()
		local dmgMult=1+might/1000
		local mindDMG=math.floor((mindS*(mindM+lvlBonus))*dmgMult)
		local lightDMG=math.floor((lightS*(lightM+lvlBonus))*dmgMult)
		local txt=baseSchoolsTxtSERAPH[16] .. "\n\nSeraphim damage upon attack increases depending on Mind magic, scaling with might(weapon speed multiplier applies).\nGets 1 bonus damage each 100 levels.\n\n" .. "Current damage from Mind: " .. StrColor(255,0,0,mindDMG) .. "\n"
		Skillz.setDesc(17,1,txt)
		local txt=baseSchoolsTxtSERAPH[18] .. "\n\nSeraphim damage upon attack increases depending on Light magic, scaling with might(weapon speed multiplier applies).\nGets 1 bonus damage each 100 levels.\n\n" .. "Current damage from Light: " .. StrColor(255,0,0,lightDMG) .. "\n"
		Skillz.setDesc(19,1,txt)
		
		--tooltips
		Skillz.setDesc(16,2,"Increases healing by 1 per Skill point")
		Skillz.setDesc(16,3,"Increases healing by 2 per Skill point")
		Skillz.setDesc(16,4,"Increases healing by 3 per Skill point")
		
		Skillz.setDesc(17,2,"Increases damage by 1 per Skill point")
		Skillz.setDesc(17,3,"Increases damage by 2 per Skill point")
		Skillz.setDesc(17,4,"Increases damage by 3 per Skill point")
		
		Skillz.setDesc(18,2,"Increases healing by 1 per Skill point")
		Skillz.setDesc(18,3,"Increases healing by 2 per Skill point")
		Skillz.setDesc(18,4,"Increases healing by 3 per Skill point")
		
		Skillz.setDesc(19,2,"Increases damage by 1 per Skill point")
		Skillz.setDesc(19,3,"Increases damage by 2 per Skill point")
		Skillz.setDesc(19,4,"Increases damage by 3 per Skill point")
		Skillz.setDesc(19,5,"Increases damage by 4 per Skill point")
	else
		for key, value in pairs(baseSchoolsTxtSERAPH) do
			Skillz.setDesc(key,1,value .. "\n")
			Skillz.setDesc(key,2,"Effects vary per spell")
			Skillz.setDesc(key,3,"Effects vary per spell")
			Skillz.setDesc(key,4,"Effects vary per spell")
		end
		Skillz.setDesc(19,5,"Effects vary per spell")
	end
end







----------------------------------
-- DRAGON REWORK
----------------------------------
local dragonFang={
	["Attack"]={2,3,4,5,[0]=0},
	["Damage"]={4,5,6,8,[0]=0},
	["Speed"]={0,0,1,2,[0]=0},
}
local dragonBreath={
	--["Attack"]={0,0,0,0,[0]=0},
	["Damage"]={3,4,5,6,[0]=0},
	--["Speed"]={0,0,1,1,[0]=0},
}
local dragonScales={
	["AC"]={2,3,4,5,[0]=0},
	["Resistances"]={2,3,4,5,[0]=0},
}

function events.GameInitialized2()
	--fire blast tooltip
	Game.SpellsTxt[123].Description="This ability is an upgraded version of the normal Dragon breath weapon attack.  It acts much like a fireball, striking its target and exploding out to hit everything near it, except the explosion does much more damage than most fireballs."
	Game.SpellsTxt[123].Expert="Deals damage equal to 80% of breath damage"
	Game.SpellsTxt[123].Master="Deals damage equal to 100% of breath damage"
	Game.SpellsTxt[123].GM="Increases Fire Blast damage by 1% per skill point"
	--mana cost
	Game.Spells[123].SpellPointsNormal=10
	Game.Spells[123].SpellPointsExpert=20
	Game.Spells[123].SpellPointsMaster=30
	Game.Spells[123].SpellPointsGM=40
	
	Game.Classes.SPBase[10]=50
	Game.Classes.SPFactor[10]=0
	Game.Classes.SPStats[10]=3
	Game.Classes.SPBase[11]=120
	Game.Classes.SPFactor[11]=0
	Game.Classes.SPStats[11]=3
	
	
	function events.CalcStatBonusByItems(t)
		if Game.CharacterPortraits[t.Player.Face].Race~=const.Race.Dragon then return end
		--melee
		if t.Stat==27 then --min damage
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Unarmed)) 
			local bonus= (dragonFang.Damage[m]-1) * s + t.Player.LevelBase +10
			t.Result=bonus
			local might=t.Player:GetMight()

			t.Result=math.round(bonus*(1+might/1000))
			
		elseif t.Stat==28 then --max damage
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
			local bonus= (dragonFang.Damage[m]+1) * s + t.Player.LevelBase +10
			local might=t.Player:GetMight()
			t.Result=math.round(bonus*(1+might/1000))
			
		elseif t.Stat==25 then --attack
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
			local bonus= (dragonFang.Attack[m]) * s +10
			t.Result=t.Result+bonus 
			
		end
		--breath
		if t.Stat==31 then --min damage
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.DragonAbility))
			local bonus= (dragonBreath.Damage[m]-1) * s
			local might=t.Player:GetMight()
			local mightEffect
			if might>=25 then
				mightEffect=math.floor(might/5)
			else
				mightEffect=math.floor((might-13)/2)
			end
			t.Result=math.round((bonus+mightEffect)*(1+might/1000))
			
		elseif t.Stat==32 then --max damage
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.DragonAbility))
			local bonus= (dragonBreath.Damage[m]+1) * s
			local might=t.Player:GetMight()
			local mightEffect
			if might>=25 then
				mightEffect=math.floor(might/5)
			else
				mightEffect=math.floor((might-13)/2)
			end
			t.Result=math.round((bonus+mightEffect)*(1+might/1000))
		
		--AC
		elseif t.Stat==9 then
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Dodging))
			local oldDodge=skillAC[const.Skills.Dodging][m] or 0
			local bonus= (dragonScales.AC[m]-oldDodge) * s + pl.LevelBase
			t.Result=t.Result+bonus
		elseif t.Stat>=10 and t.Stat<=15 then
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Dodging))
			local bonus= (dragonScales.Resistances[m]) * s
			t.Result=t.Result+bonus
		end
		
		--no mana from items
		if t.Stat==const.Stats.SpellPoints then
			t.Result=0
		end
	end
	
	function events.GetAttackDelay(t)
		if Game.CharacterPortraits[t.Player.Face].Race==const.Race.Dragon then
			t.Result=100
		end	
	end
	
	--skill text
	normal=""
	normal=string.format("%s      %s|",normal,dragonFang.Attack[1])
	normal=string.format("%s      %s|",normal,dragonFang.Speed[1])
	normal=string.format("%s     %s|",normal,dragonFang.Damage[1])
	fangsNormal=normal
	normal=""
	normal=string.format("%s  %s|",normal,dragonScales.AC[1])
	normal=string.format("%s    %s",normal,dragonScales.Resistances[1])
	scalesNormal=normal
	
	expert=""
	expert=string.format("%s      %s|",expert,dragonFang.Attack[2])
	expert=string.format("%s      %s|",expert,dragonFang.Speed[2])
	expert=string.format("%s     %s|",expert,dragonFang.Damage[2])
	fangsExpert=expert
	expert=""
	expert=string.format("%s  %s|",expert,dragonScales.AC[2])
	expert=string.format("%s    %s",expert,dragonScales.Resistances[2])
	scalesExpert=expert
	
	master=""
	master=string.format("%s      %s|",master,dragonFang.Attack[3])
	master=string.format("%s      %s|",master,dragonFang.Speed[3])
	master=string.format("%s     %s|",master,dragonFang.Damage[3])
	fangsMaster=master
	master=""
	master=string.format("%s  %s|",master,dragonScales.AC[3])
	master=string.format("%s    %s",master,dragonScales.Resistances[3])
	scalesMaster=master
	
	gm=""
	gm=string.format("%s      %s|",gm,dragonFang.Attack[4])
	gm=string.format("%s      %s|",gm,dragonFang.Speed[4])
	gm=string.format("%s     %s|",gm,dragonFang.Damage[4])
	fangsGM=gm
	gm=""
	gm=string.format("%s  %s|",gm,dragonScales.AC[4])
	gm=string.format("%s    %s",gm,dragonScales.Resistances[4])
	scalesGM=gm
	
	--make fangs and scales learnable
	Game.Classes.Skills[10][32]=3
	Game.Classes.Skills[10][33]=3
	Game.Classes.Skills[11][32]=4
	Game.Classes.Skills[11][33]=4
end


function events.LoadMap()
	if not unarmedText then
		unarmedText=Skillz.getDesc(33,1)
		unarmedTextN=Game.SkillDesNormal[33]
		unarmedTextE=Game.SkillDesExpert[33]
		unarmedTextM=Game.SkillDesMaster[33]
		unarmedTextGM=Game.SkillDesGM[33]
		dodgeText=Skillz.getDesc(32,1)
		dodgeTextN=Game.SkillDesNormal[32]
		dodgeTextE=Game.SkillDesExpert[32]
		dodgeTextM=Game.SkillDesMaster[32]
		dodgeTextGM=Game.SkillDesGM[32]
	end
end

function events.Action(t)
	if t.Action==114 then
		local race=Game.CharacterPortraits[Party[Game.CurrentPlayer].Face].Race
		if race==const.Race.Dragon then
			dragonSkill(true, Game.CurrentPlayer)
		else
			dragonSkill(false)
		end
	end
	if t.Action==110 then
		local race=Game.CharacterPortraits[Party[t.Param-1].Face].Race
		if race==const.Race.Dragon then
			dragonSkill(true, t.Param-1)
		else
			dragonSkill(false)
		end
	elseif t.Action==176 then
		local current=Game.CurrentPlayer
		local maxParty=Game.Party.High
		for i=1,Party.Count do
			newSelected=current+i+1
			while newSelected>maxParty do
				newSelected=newSelected-Party.Count
			end
			local pl=Party[newSelected]
			if pl.Dead==0 and pl.Stoned==0 and pl.Paralyzed==0 and pl.Eradicated==0 and pl.Asleep==0 and pl.Unconscious==0 then
				local race=Game.CharacterPortraits[pl.Face].Race
				if race==const.Race.Dragon then
					dragonSkill(true, newSelected)
				else
					dragonSkill(false, newSelected)
				end
			end
		end
	end
end

--show damage in real time
function events.Tick() 
	if Game.CurrentCharScreen==101 and Game.CurrentScreen==7 then
		i=Game.CurrentPlayer 
		if i==-1 then return end 
		local pl=Party[i]
		race=Game.CharacterPortraits[pl.Face].Race
		if race==const.Race.Dragon then
			Skillz.setName(33, "Fangs")
			local fang, fangM = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
			--increase damage based on speed
			local speed=pl:GetSpeed()
			if speed>=25 then
				speed=math.floor(speed/5)
			else
				speed=math.floor((speed-13)/2)
			end
			speed=speed+dragonFang.Speed[fangM]*fang
			--increase damage based on might
			local mightBase=pl:GetMight()
			local might
			if mightBase>=25 then
				might=math.floor(mightBase/5)
			else
				might=math.floor((mightBase-13)/2)
			end
			
			local baseDamage=dragonFang.Damage[fangM]*fang+might
			local damage=math.round(baseDamage*(1+speed/100)*(1+mightBase/1000))
				
			local txt="Dragons can use their fangs to deal atrocious damage to enemies.\n\nWhenever this skill is below dragon skill it will push monsters away\nThis skill converts attack speed directly into damage.\n\nCurrent Damage:  " .. StrColor(255,0,0,damage) .. "\n------------------------------------------------------------\n          Attack| Speed| Dmg"
			Skillz.setDesc(33,1,txt)
		end
	end
 end

function dragonSkill(dragon, index)	
	if dragon then
		if index==-1 then return end
		pl=Party[index]
		Skillz.setName(33, "Fangs")
		local fang, fangM = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
		--increase damage based on speed
		local speed=pl:GetSpeed()
		if speed>=25 then
			speed=math.floor(speed/5)
		else
			speed=math.floor((speed-13)/2)
		end
		speed=speed+dragonFang.Speed[fangM]*fang
		--increase damage based on might
		local mightBase=pl:GetMight()
		local might
		if mightBase>=25 then
			might=math.floor(mightBase/5)
		else
			might=math.floor((mightBase-13)/2)
		end
		
		local baseDamage=dragonFang.Damage[fangM]*fang+might
		local damage=math.round(baseDamage*(1+speed/100)*(1+mightBase/1000))
		
		local txt="Dragons can use their fangs to deal atrocious damage to enemies.\n\nWhenever this skill is below dragon skill it will push monsters away\nThis skill converts attack speed directly into damage.\n\nCurrent Damage:  " .. StrColor(255,0,0,damage) .. "\n------------------------------------------------------------\n          Attack| Dmg|"
		Skillz.setDesc(33,1,txt)
		Game.SkillDesNormal[33]=fangsNormal
		Game.SkillDesExpert[33]=fangsExpert
		Game.SkillDesMaster[33]=fangsMaster
		Game.SkillDesGM[33]=fangsGM
		Skillz.setName(32,"Scales")
		txt="Dragons scales are hard enough to work as natural armor, allowing to block and reduce incoming damage\n\n------------------------------------------------------------\n          AC| Res"
		Skillz.setDesc(32,1,txt)
		Game.SkillDesNormal[32]=scalesNormal
		Game.SkillDesExpert[32]=scalesExpert
		Game.SkillDesMaster[32]=scalesMaster
		Game.SkillDesGM[32]=scalesGM
		if index==-1 then return end
		if dragon then
			if pl.Skills[33]==0 then
				pl.Skills[33]=1
			end
			if pl.Skills[32]==0 then
				pl.Skills[32]=1
			end
			if pl.Skills[23]==0 then
				pl.Skills[23]=1
			end
			
		end
	else
		Skillz.setName(33,"Unarmed")
		Skillz.setDesc(33,1,unarmedText)
		Game.SkillDesNormal[33]=unarmedTextN
		Game.SkillDesExpert[33]=unarmedTextE
		Game.SkillDesMaster[33]=unarmedTextM
		Game.SkillDesGM[33]=unarmedTextGM
		Skillz.setName(32,"Dodging")
		Skillz.setDesc(32,1,dodgeText)
		Game.SkillDesNormal[32]=dodgeTextN
		Game.SkillDesExpert[32]=dodgeTextE
		Game.SkillDesMaster[32]=dodgeTextM
		Game.SkillDesGM[32]=dodgeTextGM
	end
end

function events.GameInitialized2()
	function events.CalcDamageToMonster(t)
		data=WhoHitMonster()
		if data and data.Player and Game.CharacterPortraits[data.Player.Face].Race==const.Race.Dragon then
			local pl=data.Player
			if data.Object==nil then
				local breath = SplitSkill(data.Player:GetSkill(const.Skills.DragonAbility))
				local fang, fangM = SplitSkill(data.Player:GetSkill(const.Skills.Unarmed))
				if breath>=fang then
					local x, y = directionToUnitVector(Party.Direction)
					push=push or {}
					mult=fang/t.Monster.Level^0.75
					table.insert(push,{["directionX"]=x, ["directionY"]=y, ["duration"]=60*mult^0.5, ["totalDuration"]=60*mult^0.5, ["totalForce"]=800*mult, ["currentForce"]=800*mult, ["id"]=t.MonsterIndex})
				end
				--increase damage based on speed
				local speed=pl:GetSpeed()
				if speed>=25 then
					speed=math.floor(speed/5)
				else
					speed=math.floor((speed-13)/2)
				end
				local fang, fangM = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
				speed=speed+dragonFang.Speed[fangM]*fang
				--increase damage based on might
				local mightBase=pl:GetMight()
				local might
				if mightBase>=25 then
					might=math.floor(mightBase/5)
				else
					might=math.floor((mightBase-13)/2)
				end
				
				local baseDamage=dragonFang.Damage[fangM]*fang+might
				local damage=math.round(baseDamage*(1+speed/100)*(1+mightBase/1000))
				
				--check by damage type
				index=table.find(damageKindMap,t.DamageKind)
				res=t.Monster.Resistances[index]
				if not res then return end
				res=1-1/2^(res%1000/100)
				luck=data.Player:GetLuck()/1.5
				critDamage=data.Player:GetAccuracy()*3/1000
				critChance=50+luck
				roll=math.random(1, 1000)
				crit=false
				if roll <= critChance then
					damage=damage*(1.5+critDamage)
					crit=true
				end
				if pl.Class==10 then
					pl.SP=math.min(pl.SP+10, 50)
				elseif pl.Class==11 then
					pl.SP=math.min(pl.SP+20, 100)
				end
				--apply Damage
				t.Result = damage * (1-res)
			elseif t.DamageKind==50 or data.Spell==123 then
				--increase damage based on speed
				local speed=pl:GetSpeed()
				if speed>=25 then
					speed=math.floor(speed/5)
				else
					speed=math.floor((speed-13)/2)
				end
				speed=speed/2
				--increase damage based on might
				local mightBase=pl:GetMight()
				local might
				if mightBase>=25 then
					might=math.floor(mightBase/5)
				else
					might=math.floor((mightBase-13)/2)
				end
				
				--breath
				local breath, breathM = SplitSkill(pl:GetSkill(const.Skills.DragonAbility))
				local baseDamage=dragonBreath.Damage[breathM]*breath+might
				local damage=math.round(baseDamage*(1+speed/100)*(1+mightBase/1000))
				
				luck=data.Player:GetLuck()/1.5
				critDamage=data.Player:GetAccuracy()*3/1000
				critChance=50+luck
				roll=math.random(1, 1000)
				crit=false
				if roll <= critChance then
					damage=damage*(1.5+critDamage)
					crit=true
				end
				if data.Spell==123 then
					local s,m=SplitSkill(t.Player.Skills[const.Skills.DragonAbility])
					local mult=1
					if m<=2 then
						mult=0.8
					elseif m==4 then
						mult=mult+s*0.01
					end
					damage=damage*mult
				end
				--randomize
				damage=damage*0.75+(damage*math.random()*0.25)+(damage*math.random()*0.25)
				--apply Damage
				t.Result = damage
			end
		end
	end
end

-- Function to convert party direction to radians
function directionToRadians(direction)
    -- Convert the direction from 0-2048 scale to 0-2π scale
    return (direction / 2048) * 2 * math.pi
end

-- Function to calculate the unit vector based on the direction
function directionToUnitVector(direction)
    local radians = directionToRadians(direction)
    local x = math.cos(radians)
    local y = math.sin(radians)
	asdd=direction
	asdx=x
	asdy=y
    return x, y
end

function events.Tick()
	if push and push[1] then
		for i=1, #push do
			if push[i].duration>0 then
				push[i].duration=push[i].duration-1
				mon=Map.Monsters[push[i].id]
				mon.VelocityX=push[i].directionX * push[i].currentForce
				mon.VelocityY=push[i].directionY * push[i].currentForce
				mon.VelocityZ=push[i].currentForce/2 - push[i].totalForce/4
				push[i].currentForce=push[i].currentForce - push[i].totalForce / push[i].totalDuration
			end
		end
	end
end


---------------------------------------
--SHAMAN
---------------------------------------
function events.GameInitialized2()
	Game.ClassDescriptions[59] = "The Shaman is a mystical warrior whose knowledge of magic enhances his martial prowess.\nYou can check following values by checking magic schools description in skills menu.\n\n - Each rank in Magic schools will increase spell damage and healing by 0.5% and Physical damage by 1\n - Each point in Air will reduce damage by 1% (multiplicative)\n - Each point in Water will reduce damage by Skill^1.33 (increased depending on difficulty)\n\nMelee damage calculation:\n - Each point in spirit will increase melee damage by 1%\n - Each point in any schools will increase damage by 1\n - Each point in Fire will deal around 0.025% of total monster HP as fire damage\n\nRecovery on Melee attack:\n - Each point in Earth will heal by 1% of damage\n - Each point in Body will heal by skill^1.33\n - Each point in mind will restore 1 mana"
end

shamanClass={59, 60, 61}

function events.GameInitialized2()
	function events.CalcSpellDamage(t)
		local data = WhoHitMonster()
		if data and data.Player and table.find(shamanClass, data.Player.Class)  then	
			m1=SplitSkill(data.Player.Skills[const.Skills.Fire])
			m2=SplitSkill(data.Player.Skills[const.Skills.Air])
			m3=SplitSkill(data.Player.Skills[const.Skills.Water])
			m4=SplitSkill(data.Player.Skills[const.Skills.Earth])
			m5=SplitSkill(data.Player.Skills[const.Skills.Spirit])
			m6=SplitSkill(data.Player.Skills[const.Skills.Mind])
			m7=SplitSkill(data.Player.Skills[const.Skills.Body])
			m8=m2+m3+m4+m5+m1+m6+m7
			t.Result =t.Result+t.Result*m8/200
		end
	end

	function events.CalcDamageToPlayer(t)
		if table.find(shamanClass, t.Player.Class) and t.Player.Unconscious==0 and t.Player.Dead==0 and t.Player.Eradicated==0  then
			m2=SplitSkill(t.Player.Skills[const.Skills.Air])
			m3=SplitSkill(t.Player.Skills[const.Skills.Water])
			mult=((math.max(Game.BolsterAmount, 100)/100)-1)/2+1
			t.Result=math.max(t.Result*0.99^m2-m3^1.33*mult,0)
		end
	end
	
	function events.CalcDamageToMonster(t)	
		local data = WhoHitMonster()
		if data and data.Player and table.find(shamanClass, data.Player.Class) and t.DamageKind==4 and data.Object==nil then	
			m1=SplitSkill(t.Player.Skills[const.Skills.Fire])
			m4=SplitSkill(data.Player.Skills[const.Skills.Earth])
			m6=SplitSkill(data.Player.Skills[const.Skills.Mind])
			m7=SplitSkill(data.Player.Skills[const.Skills.Body])
			data.Player.SP=math.min(data.Player.SP+m6, data.Player:GetFullSP())
			data.Player.HP=math.min((data.Player.HP+m7^1.33)+(m4/t.Monster.Level)*0.3*t.Result, data.Player:GetFullHP())
			local fireDamage=(m1^0.5/500)
			if t.Monster.Resistances[0]>=1000 then
				mult=2^math.floor(t.Monster.Resistances[0]/1000)
				fireDamage=fireDamage*mult
			end
			fireDamage=math.max(t.Monster.HP*fireDamage,m1)
			fireRes=t.Monster.Resistances[0]%1000
			fireDamage=fireDamage/2^(fireRes/100)
			t.Result=t.Result+fireDamage
		end
	end
	
	function events.CalcStatBonusByItems(t)
		if t.Stat==const.Stats.MeleeDamageMax or t.Stat==const.Stats.MeleeDamageMin then
			if table.find(shamanClass, t.Player.Class) then	
				--mastery=SplitSkill(t.Player.Skills[const.Skills.Thievery))
				m1=SplitSkill(t.Player.Skills[const.Skills.Fire])
				m2=SplitSkill(t.Player.Skills[const.Skills.Air])
				m3=SplitSkill(t.Player.Skills[const.Skills.Water])
				m4=SplitSkill(t.Player.Skills[const.Skills.Earth])
				m5=SplitSkill(t.Player.Skills[const.Skills.Spirit])
				m6=SplitSkill(t.Player.Skills[const.Skills.Mind])
				m7=SplitSkill(t.Player.Skills[const.Skills.Body])
				m8=m2+m3+m4+m5+m1+m6+m7
				t.Result=(t.Result+m8)*(1+m5/100) --*(0.5+mastery/10)+mastery*2
			end
		end
	end
end

local baseSchoolsTxt={}
function events.GameInitialized2()
	for i=12,18 do
		baseSchoolsTxt[i]=Skillz.getDesc(i,1)
	end
end

local function shamanSkills(isShaman, id)
	if isShaman then
		pl=Party[id]
		local m1=SplitSkill(pl.Skills[const.Skills.Fire])
		local m2=SplitSkill(pl.Skills[const.Skills.Air])
		local m3=SplitSkill(pl.Skills[const.Skills.Water])
		local m4=SplitSkill(pl.Skills[const.Skills.Earth])
		local m5=SplitSkill(pl.Skills[const.Skills.Spirit])
		local m6=SplitSkill(pl.Skills[const.Skills.Mind])
		local m7=SplitSkill(pl.Skills[const.Skills.Body])
		local txt
		local fireDamage=math.round(m1^0.5/0.05)/100
		txt=baseSchoolsTxt[12] .. "\n\nIncreases melee damage by 1 per skill level and spell damage/healing by 0.5%" .. "\n\nMelee attacks deal an extra " .. fireDamage .. "% of monster Hit points as fire damage"
		Skillz.setDesc(12,1,txt)
		local airReduction=100-math.round(0.99^m2*10000)/100
		txt=baseSchoolsTxt[13] .. "\n\nIncreases melee damage by 1 per skill level and spell damage/healing by 0.5%" .. "\n\nReduce all damage taken by " .. airReduction .. " %"
		Skillz.setDesc(13,1,txt)
		mult=((math.max(Game.BolsterAmount, 100)/100)-1)/2+1
		local waterReduction=math.round(m3^1.33*mult)
		txt=baseSchoolsTxt[14] .. "\n\nIncreases melee damage by 1 per skill level and spell damage/healing by 0.5%" .. "\n\nReduce all damage taken by " .. waterReduction .. "(calculated after resistances)"
		Skillz.setDesc(14,1,txt)
		local leech=math.round(m4/pl.LevelBase*10000*0.3)/100
		txt=baseSchoolsTxt[15] .. "\n\nIncreases melee damage by 1 per skill level and spell damage/healing by 0.5%" .. "\n\nMelee attacks heal by " .. leech .. "% of damage done (vs. same level monster, up to 255)" 
		Skillz.setDesc(15,1,txt)
		txt=baseSchoolsTxt[16] .. "\n\nIncreases melee damage by 1 per skill level and spell damage/healing by 0.5%" .. "\n\nIncreases melee damage by " .. m5 .. "%"
		Skillz.setDesc(16,1,txt)
		txt=baseSchoolsTxt[17] .. "\n\nIncreases melee damage by 1 per skill level and spell damage/healing by 0.5%" .. "\n\nMelee attacks restore " .. m6 .. " Spell Points"
		Skillz.setDesc(17,1,txt)
		local hpRestore=math.round(m7^1.33)
		txt=baseSchoolsTxt[18] .. "\n\nIncreases melee damage by 1 per skill level and spell damage/healing by 0.5%" .. "\n\nMelee attacks restore " .. hpRestore .. " Hit Points"
		Skillz.setDesc(18,1,txt)
	else
		for i=12,18 do
			Skillz.setDesc(i,1,baseSchoolsTxt[i])
		end
	end
end


---------------------------------------
--DEATH KNIGHT
---------------------------------------
function events.GameInitialized2()
	Game.ClassDescriptions[56] = "This class combines the evil forces with brute power, making it powerful and versatile.\n Learning Frost/Blood/Unholy E/M/GM will unlock automatically new spells. However death knight can't learn spells from books.\n\nFrost:\n\nIncreases damage by 1-2-3 (at Novice, Master, Grandmaster levels) and boosts attack speed by 1% for every skill point invested.\n\nBlood:\n\nThis skill fortifies their resilience, reducing physical damage taken by 1% per skill point. Additionally, it endows their attacks with a leech effect, converting a portion of the damage dealt into health recovery.\n\nUnholy:\n\nIt amplifies damage by 1-2-3 (at Novice, Master, Grandmaster levels) and diminishes magical damage received by 1% for each skill point allocated."
end
--skills
--death grip

--runic power
dkClass={56,57,58}
spRegen={
	[56]=10,
	[57]=15,
	[58]=20,
}

--change spell cost to personalized value:
local DKManaCost={
	[26]=15,
	[27]=0,
	[29]=30,
	[32]=50,
	[68]=6,
	[71]=0,
	[76]=70,
	[74]=12,
	[91]=0,
	[90]=30,
	[96]=15,
	[97]=100,
}

local DKDamageMult={
	[26]=0.8,
	[29]=1.2,
	[32]=0.5,
	[74]=1.2,
	[90]=1,
	[97]=0.4,
}

--spells
function events.GameInitialized2()
	--damage from skills
	function events.CalcStatBonusByItems(t)
		if t.Stat==const.Stats.MeleeDamageMax or t.Stat==const.Stats.MeleeDamageMin then
			if table.find(dkClass, t.Player.Class) then	
				local s1, m1=SplitSkill(t.Player.Skills[const.Skills.Water])
				--local s2, m2=SplitSkill(t.Player.Skills[const.Skills.Body])
				local s3, m3=SplitSkill(t.Player.Skills[const.Skills.Dark])
				local might=t.Player:GetMight()
				local bonus=s1*math.min(m1, 3)+s3*math.min(m3, 3)
				bonus=bonus*(1+might/1000)
				t.Result=t.Result+s1*math.min(m1, 3)+s3*math.min(m3, 3)
			end
		elseif t.Stat==const.Stats.SpellPoints and table.find(dkClass, t.Player.Class) then
			t.Result=0
		end
	end	
	--body leech damage
	function events.CalcDamageToMonster(t)
		local data = WhoHitMonster()
		if data and data.Player and table.find(dkClass, data.Player.Class) then
			local pl=data.Player
			if data.Object and data.Object.Spell>0 and data.Object.Spell<=99 then
				--add physical damage to spells
				baseDamage=pl:GetMeleeDamageMin()
				maxDamage=pl:GetMeleeDamageMax()
				randomDamage=math.random(baseDamage, maxDamage) + math.random(baseDamage, maxDamage)
				damage=math.round(randomDamage/2)
				local res=t.Monster.Resistances[t.DamageKind] or t.Monster.Resistances[4]
				damage=damage/2^(res/100)
				local mult=damageMultiplier[t.PlayerIndex]["Melee"]
				t.Result=damage*mult
				luck=pl:GetLuck()/1.5
				critDamage=pl:GetAccuracy()*3/1000
				critChance=50+luck
				roll=math.random(1, 1000)
				if roll <= critChance then
					t.Result=t.Result*(1.5+critDamage)
					crit=true
				end
				if pl.Weak>0 then
					t.Result=t.Result*0.5
				end
				
				--add spell modifier
				if data.Object.Spell==26 or data.Object.Spell==29 then
					local s,m=SplitSkill(pl.Skills[const.Skills.Water])
					if m>=3 then
						t.Result=t.Result*(1+s/100)
					end
				elseif data.Object.Spell==97 then
					local s,m=SplitSkill(pl.Skills[const.Skills.Dark])
					t.Result=t.Result*(1+s/100)
				end
				if DKDamageMult[data.Object.Spell] then
					t.Result=t.Result*DKDamageMult[data.Object.Spell]
					if data.Object.Spell==76 then
						local s,m=SplitSkill(pl.Skills[const.Skills.Body])
						if m==4 then
							t.Result=t.Result/3*4
						end
					end
				end
			end
			--life leech
			if t.DamageKind==4 and table.find(dkClass, data.Player.Class) then
				local pl=data.Player
				local bloodS, bloodM=SplitSkill(pl.Skills[const.Skills.Body])
				local heal=t.Result*(bloodS/t.Monster.Level)*0.3
				--current active leech spell
				vars.dkActiveAttackSpell=vars.dkActiveAttackSpell or {}
				local id=pl:GetIndex()
				leech=0
				if vars.dkActiveAttackSpell and (vars.dkActiveAttackSpell[id]==68 or vars.dkActiveAttackSpell[id]==74) then
					leech=bloodS^1.33 * (1+bloodM/4)
					pl.SP=pl.SP-6
					if vars.dkActiveAttackSpell[id]==74 then
						leech=bloodS^1.33 * 4
						pl.SP=pl.SP-6
					end
				end
				pl.HP=math.min(pl:GetFullHP(), pl.HP+heal+leech)
				
				--dark grasp
				if vars.dkActiveAttackSpell and vars.dkActiveAttackSpell[id]==96 then
					pl.SP=pl.SP-15
					t.Monster.SpellBuffs[const.MonsterBuff.DamageHalved].ExpireTime=math.max(t.Monster.SpellBuffs[const.MonsterBuff.DamageHalved].ExpireTime, Game.Time+const.Minute)
					local s, m=SplitSkill(pl.Skills[const.Skills.Dark])
					if m==4 then
						t.Monster.SpellBuffs[const.MonsterBuff.MeleeOnly].ExpireTime=math.max(t.Monster.SpellBuffs[const.MonsterBuff.MeleeOnly].ExpireTime, Game.Time+const.Minute)
					end
				end
				--restore SP
				if t.DamageKind==4 then
					local regen=spRegen[pl.Class]
					if t.Result>t.Monster.HP then
						regen=regen*1.5
					end
					pl.SP=math.min(pl:GetFullSP(), pl.SP+regen)
				end
			end
			
			--spell effect
			if data and data.Object then
				if data.Object.Spell==90 then --toxic cloud
					local s, m=SplitSkill(pl.Skills[const.Skills.Body])
					local leech=t.Result*(s/t.Monster.Level)*0.3 * (1+(m-2)/2)
					pl.HP=math.min(pl:GetFullHP(), pl.HP+leech)
				elseif data.Object.Spell==26 then --ice bolt
					local s,m=SplitSkill(pl.Skills[const.Skills.Water])
					if m>=2 then
						local power=math.floor(m/2)*2
						t.Monster.SpellBuffs[const.MonsterBuff.Slow].ExpireTime=math.max(t.Monster.SpellBuffs[const.MonsterBuff.Slow].ExpireTime, Game.Time+const.Minute)
						t.Monster.SpellBuffs[const.MonsterBuff.Slow].Power=power
					end
				elseif data.Object.Spell==76 then
					t.Monster.SpellBuffs[const.MonsterBuff.Paralyze].ExpireTime=math.max(t.Monster.SpellBuffs[const.MonsterBuff.Paralyze].ExpireTime, Game.Time+const.Minute)
				end
			end
		end
	end
	
	function events.CalcDamageToPlayer(t) --body reduces phys damage, unholy magic damage
		if table.find(dkClass, t.Player.Class) then
			if t.DamageKind==4 then
				local s, m=SplitSkill(t.Player.Skills[const.Skills.Body])
				t.Result=t.Result*0.99^s
			else
				local s, m=SplitSkill(t.Player.Skills[const.Skills.Dark])
				t.Result=t.Result*0.99^s
			end			
		end
	end
	
		
	function events.Action(t)
		if (t.Action==142 and t.Param==68) or (t.Action==142 and t.Param==74) or (t.Action==142 and t.Param==96) then
			if table.find(dkClass, Party[Game.CurrentPlayer].Class) then
				t.Handled=true
				vars.dkActiveAttackSpell=vars.dkActiveAttackSpell or {}
				local id=Party[Game.CurrentPlayer]:GetIndex()
				if vars.dkActiveAttackSpell[id]==t.Param then
					vars.dkActiveAttackSpell[id]=false
					Game.ShowStatusText(Game.SpellsTxt[t.Param].Name .. " on attack disabled")
				else
					Game.ShowStatusText(Game.SpellsTxt[t.Param].Name .. " on attack activated")
					vars.dkActiveAttackSpell[id]=t.Param
				end
			end
		end
		--same for quickcast
		if t.Action==25 and Game.CurrentPlayer>=0 and Game.CurrentPlayer<=Party.High and table.find(dkClass, Party[Game.CurrentPlayer].Class) then
			local pl=Party[Game.CurrentPlayer]
			local id=pl:GetIndex()
			if pl.QuickSpell==68 or pl.QuickSpell==74 or pl.QuickSpell==96 then
				t.Handled=true
				vars.dkActiveAttackSpell=vars.dkActiveAttackSpell or {}
				local id=Party[Game.CurrentPlayer]:GetIndex()
				if vars.dkActiveAttackSpell[id]==t.Param then
					vars.dkActiveAttackSpell[id]=false
					Game.ShowStatusText(Game.SpellsTxt[pl.QuickSpell].Name .. " on attack disabled")
				else
					Game.ShowStatusText(Game.SpellsTxt[pl.QuickSpell].Name .. " on attack activated")
					vars.dkActiveAttackSpell[id]=t.Param
				end
			end
		end
	end
	
	--spells speed depends on weapon
	function events.PlayerCastSpell(t)
		if table.find(dkClass, t.Player.Class) then
			local spell=t.SpellId
			local m=t.Mastery
			Game.Spells[spell]["Delay" .. masteryName[m]]=t.Player:GetAttackDelay()
			if t.SpellId==68 or t.SpellId==74 then
				t.Handled=true
			end
		end
	end
end

DKSpellList={
	[const.Skills.Water]={26, 27, 29, 32},
	[const.Skills.Body]={68, 71, 76, 74},
	[const.Skills.Dark]={91, 90, 96, 97},
}

function events.Action(t)
	if t.Action==105 and Game.CurrentPlayer>=0 and Game.CurrentPlayer<=Party.High then
		
		pl=Party[Game.CurrentPlayer]
		if table.find(dkClass, pl.Class) then
			for i=1,99 do
				pl.Spells[i]=false
			end
			local s1, m1=SplitSkill(pl.Skills[const.Skills.Water])
			local s2, m2=SplitSkill(pl.Skills[const.Skills.Body])
			local s3, m3=SplitSkill(pl.Skills[const.Skills.Dark])
			for i=1, m1 do
				pl.Spells[DKSpellList[const.Skills.Water][i]]=true
			end
			for i=1, m2 do
				pl.Spells[DKSpellList[const.Skills.Body][i]]=true
			end
			for i=1, m3 do
				pl.Spells[DKSpellList[const.Skills.Dark][i]]=true
			end
		end
	end
end

function events.CanLearnSpell(t)
	if table.find(dkClass, t.Player.Class) then
		t.NeedMastery = 5
	end
end


--tooltips
local baseSchoolsTxtDK={}
function events.GameInitialized2()
	baseSchoolsTxtDK={[14]=Skillz.getDesc(14,1), [18]=Skillz.getDesc(18,1), [20]=Skillz.getDesc(20,1)}
	spellDesc={}
	for key, value in pairs(DKSpellList) do
		for i=1,#DKSpellList[key] do
			local spellID=DKSpellList[key][i]
			spellDesc[spellID]={}
			spellDesc[spellID]["Name"]=Game.SpellsTxt[value[i]].Name
			spellDesc[spellID]["Description"]=Game.SpellsTxt[value[i]].Description
			spellDesc[spellID]["Normal"]=Game.SpellsTxt[value[i]].Normal
			spellDesc[spellID]["Expert"]=Game.SpellsTxt[value[i]].Expert
			spellDesc[spellID]["Master"]=Game.SpellsTxt[value[i]].Master
			spellDesc[spellID]["GM"]=Game.SpellsTxt[value[i]].GM
		end
	end
end

local function dkSkills(isDK, id)
	if isDK then
		pl=Party[id]
		for key, value in pairs(DKManaCost) do
			for i=1,4 do
				Game.Spells[key]["SpellPoints" .. masteryName[i]]=value
			end
		end
		Game.SpellsTxt[26].Name="Icy Touch"
		Game.SpellsTxt[26].Description="This spell is exclusive to Death Knights and deals damage equal to 80% of current weapon damage."
		Game.SpellsTxt[26].Normal="No additional effects"
		Game.SpellsTxt[26].Expert="Monster slows by 1/2 of speed"
		Game.SpellsTxt[26].Master="Increases total damage by 1% per spell skill"
		Game.SpellsTxt[26].GM="Monster slows by 1/4 of speed"
		
		Game.SpellsTxt[29].Name="Frostbite"
		Game.SpellsTxt[29].Description="This is the strongest single damage spell available to death knights and deals damage equal to 120% of current weapon damage."
		Game.SpellsTxt[29].Expert="n/a"
		Game.SpellsTxt[29].Master="No additional effects"
		Game.SpellsTxt[29].GM="Increases total damage by 1% per spell skill"
		
		Game.SpellsTxt[32].Name="Ice Bomb"
		Game.SpellsTxt[32].Description="Throw an ice bomb that shatters upon hitting something, most effective versus big foes or multiple enemies.\nDeals damage equal to 50% of current weapon damage."
		Game.SpellsTxt[32].Expert="n/a"
		Game.SpellsTxt[32].Master="n/a"
		Game.SpellsTxt[32].GM="Increases total damage by 1% per spell skill"
		
		
		
		local bloodS, bloodM=SplitSkill(pl.Skills[const.Skills.Body])
		local leech=bloodS^1.33
		Game.SpellsTxt[68].Name="Blood Leech"
		Game.SpellsTxt[68].Description="Activating this spell imbues the knight body with blood, leeching life upon attacking at the cost of 6 spell points."
		Game.SpellsTxt[68].Normal="Leeches " .. math.round(leech * 1.25) .. " Hit Points"
		Game.SpellsTxt[68].Expert="Leeches " .. math.round(leech * 1.5) .. " Hit Points"
		Game.SpellsTxt[68].Master="Leeches " .. math.round(leech * 1.75) .. " Hit Points"
		Game.SpellsTxt[68].GM="Leeches " .. math.round(leech * 2) .. " Hit Points"
		
		Game.SpellsTxt[74].Name="Superior Blood Leech"
		Game.SpellsTxt[74].Description="Activating this spell imbues the knight essence with blood, leeching a superior amount of life upon attacking at the cost of 12 spell points."
		Game.SpellsTxt[74].Master="n/a"
		Game.SpellsTxt[74].GM="Leeches " .. math.round(leech * 4) .. " Hit Points"
		
		Game.SpellsTxt[76].Name="Asphyxiate"
		Game.SpellsTxt[76].Description="Asphyxiate the target deal damage equal to 120% and making him unable to act for 2 seconds"
		Game.SpellsTxt[76].Master="No additional effects"
		Game.SpellsTxt[76].GM="Damage increased to 200%"
		
		Game.SpellsTxt[90].Name="Death Coil"
		Game.SpellsTxt[90].Description="A deadly spell capable to heal the caster upon hitting the target by an amount equal to the unholy skill bonus. Deals damage equal to 100% of the base weapon damage"
		Game.SpellsTxt[90].Expert="No additional effects"
		Game.SpellsTxt[90].Master="Heal increased by 50%"
		Game.SpellsTxt[90].GM="Heal increased by 100%"
		
		Game.SpellsTxt[96].Name="Death Grasp"
		Game.SpellsTxt[96].Description="Activating this spell imbues the knight body with dark powers, empairing oppenents powers (damage halved) upon attacking 15 spell points."
		Game.SpellsTxt[96].Expert="n/a"
		Game.SpellsTxt[96].Master="No additional effects"
		Game.SpellsTxt[96].GM="Monster looses the ability to deal ranged damage"
		
		Game.SpellsTxt[97].Name="Death Breath"
		Game.SpellsTxt[97].Description="A lethal explosion dealing huge damage to all monsters in the area. Can be used safely also in close combat.\nDeals damage equal to 40% of weapon damage"
		Game.SpellsTxt[97].Expert="n/a"
		Game.SpellsTxt[97].Master="n/a"
		Game.SpellsTxt[97].GM="Increases total damage by 1% per spell skill"
		
		--skill names and desc
		
		Skillz.setName(14, "Frost")
		Skillz.setName(18, "Blood")
		Skillz.setName(20, "Unholy")
		local txt
		txt="This skill is only available to death knights and increases damage by 1-2-3 (at Novice, Master, Grandmaster) and increases attack speed by 2% per skill point.\n"
		Skillz.setDesc(14,1,txt)
		leech=math.round(bloodS/math.min(pl.LevelBase,255)*10000*0.3)/100
		txt="This skill is only available to death knights and reduces physical damage taken by 1% per skill point.\nAdditionally it will make your attacks to leech damage based on damage done.\n\nCurrent leech vs. same level monsters (up to 255): " .. leech .. "%\n"            
		Skillz.setDesc(18,1,txt)
		txt="This skill is only available to death knights and increases damage by 1-2-3 (at Novice, Master, Grandmaster) and reduces magical damage taken by 1% per skill point.\n"	
		Skillz.setDesc(20,1,txt)
		Skillz.setDesc(14,5,"Effects vary per spell")
		Skillz.setDesc(18,5,"Effects vary per spell")
	else
		for key, value in pairs(baseSchoolsTxtDK) do
			Skillz.setDesc(key,1,value)
		end
		for key, value in pairs(spellDesc) do
			for key2, value2 in pairs(value) do
				Game.SpellsTxt[key][key2]=value2
			end
		end
		Skillz.setName(14, "Water Magic")
		Skillz.setName(18, "Body Magic")
		Skillz.setName(20, "Dark Magic")
		Skillz.setDesc(14,5,"Grants 3 Luck to all party per skill point")
		Skillz.setDesc(18,5,"Grants 3 Might to all party per skill point")
	end
end


function checkSkills(id)
	shamanSkills(false, id)
	dkSkills(false, id)
	seraphSkills(false, id)
	if id>=0 and id<=Party.High then
		local class=Party[id].Class
		if table.find(shamanClass, class) then
			shamanSkills(true, id)
			return
		end
		if table.find(dkClass, class) then
			dkSkills(true, id)
			return
		end
		if table.find(seraphClass, class) then
			seraphSkills(true, id)
			return
		end
		
	end
end
--add tooltips
function events.Action(t)
	function events.Tick() 
		local id=Game.CurrentPlayer
		if id>=0 and id<=Party.High then
			events.Remove("Tick", 1)
			checkSkills(id)
		end
	end
end

function events.Action(t)
	if t.Action==114 then
		local class=Party[Game.CurrentPlayer].Class
		if table.find(dkClass, class) then
			dkSkills(true, Game.CurrentPlayer)
		else
			dkSkills(false)
		end
	end
	if t.Action==110 then
		local class=Party[t.Param-1].Class
		if table.find(dkClass, class) then
			dkSkills(true, t.Param-1)
		else
			dkSkills(false)
		end
	elseif t.Action==176 then
		local current=Game.CurrentPlayer
		local maxParty=Game.Party.High
		for i=1,Party.Count do
			newSelected=current+i+1
			while newSelected>maxParty do
				newSelected=newSelected-Party.Count
			end
			local pl=Party[newSelected]
			if pl.Dead==0 and pl.Stoned==0 and pl.Paralyzed==0 and pl.Eradicated==0 and pl.Asleep==0 and pl.Unconscious==0 then
				local class=pl.Class
				if table.find(dkClass, class) then
					dkSkills(true, newSelected)
				else
					dkSkills(false, newSelected)
				end
			end
		end
	end
end


----------------
--ELEMENTALIST--
----------------
--[[
elementalistClass={62,63,64}

function events.CanLearnSpell(t)
	if table.find(elementalistClass, t.Player.Class) then
		t.NeedMastery = 5
		Game.ShowStatusText("Elementalists learn their spells through practice")
	end
end

spellRequirements={100,200,1000,2000,5000,10000,15000,25000,40000,60000,100000}

function events.CalcDamageToMonster(t)
	local data=WhoHitMonster()
	if data and data.Player and data.Object and table.find(elementalistClass, data.Player.Class) and data.Object.Spell<45 and data.Object.Spell>0 then
		local pl=data.Player
		local spell=data.Object.Spell
		local school=math.ceil(spell/11)+11
		vars.elementalistSpells=vars.elementalistSpells or {}
		vars.elementalistSpells[pl:GetIndex()]=vars.elementalistSpells[pl:GetIndex()] or {}
		vars.elementalistSpells[pl:GetIndex()][school]=vars.elementalistSpells[pl:GetIndex()][school] or 0
		
		local tier=spell%11==0 and 11 or spell%11
		local learningBonus=tier^1.5 * t.Monster.Level^0.5
		if table.find(aoespells,spell) then
			learningBonus=learningBonus/3
		end
		vars.elementalistSpells[pl:GetIndex()][school]=vars.elementalistSpells[pl:GetIndex()][school] + learningBonus
		school2=(school-12)*11
		for i=1,11 do
			local spell2= school2+i
			if pl.Spells[spell2]==false then
				local tier=spell2%11==0 and 11 or spell2%11
				if vars.elementalistSpells[pl:GetIndex()][school]>=spellRequirements[tier] then
					pl.Spells[spell2]=true
					Message("Learned " .. Game.SpellsTxt[spell2].Name)
				end
			end
		end		
	end
end

eleOffSpellsOut={2,6,7,9,11,15,19,20,22,24,26,29,32,37,39,41,43,44}
eleOffSpellsIn={2,6,7,10,11,15,19,20,24,26,29,32,37,39,41,44}

function events.Action(t)
	if t.Action==105 then
		if Game.CurrentPlayer>=0 and Game.Player<=Party.High then
			local pl=Party[Game.CurrentPlayer]
			if table.find(elementalistClass, pl.Class) then
				pl.Spells[2]=true
				pl.Spells[15]=true
				pl.Spells[24]=true
				pl.Spells[37]=true
			end
		end
	end
	if t.Action==113 then
		if Game.CurrentPlayer>=0 and Game.Player<=Party.High then
			local pl=Party[Game.CurrentPlayer]
			if table.find(elementalistClass, pl.Class) then
				local id=pl:GetIndex()
				vars.elementalistRotation=vars.elementalistRotation or {}
				vars.elementalistRotation[id]=vars.elementalistRotation[id] or 2
				pl.QuickSpell=vars.elementalistRotation[id]
				for i=1,4 do
					if table.find(eleOffSpellsOut, vars.ExtraSettings.SpellSlots[id][i]) or table.find(eleOffSpellsIn, vars.ExtraSettings.SpellSlots[id][i]) then
						vars.ExtraSettings.SpellSlots[id][i]=vars.elementalistRotation[id]
					end
				end
			end
		end
	end
end


function events.PlayerCastSpell(t)
	if table.find(elementalistClass, t.Player.Class) and (table.find(eleOffSpellsOut, t.Spell) or table.find(eleOffSpellsIn, t.Spell)) then
		
		
		--vars.ExtraSettings.SpellSlots[t.PlayerIndex]
		
		
	end
	
end
]]
