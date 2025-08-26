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
[11]=		{1657,1658,		1562,1563,1564,1565,	1547,33},--archer, vampire
--Troll
[12]=		{1645,1646,		1568,1569,1570,1571,	1538,1539},--knight and monk
--Vampire
[13]=	{1657,1658,		1562,1563,1564,1565,	1547,33},--archer, thief
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
--ELEMENTALIST
[20]=	{1641,1642,		1621,1622,1623,1624,	1548,35},--same as mage
}

--mid promotionlist
midPromo={
--Seraphim
[17]=	{1647,1648,		1607,1608},--cleric
--DK
[18]=	{1643,1644,		1566,1567},--same as knight
--SHAMAN
[19]=	{1651,1652,		1613,1614}, --same as druid
--ELEMENTALIST
[20]=	{1639,1640,		1619,1620},--same as mage
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
	Game.ClassDescriptions[53]="Seraphim is a divine warrior, blessed by the gods with otherworldly powers that set him apart from mortal fighters. His origins are shrouded in mystery, but it is said that he was chosen by the divine to carry out their will on the mortal plane. Some whisper that he was born from the union of a mortal and an angel, while others believe that he was created by the gods themselves. Regardless of his origins, there is no denying the power that Seraphim wields, and his presence on the battlefield is a testament to the will of the divine.\n\nProficiency in Plate, Sword, Mace, and Shield (can't dual wield)\n3 HP and 1 mana points gained per level\n\nAbilities:\n\nGods Wrath: Attacks deal extra magic damage based on Light skill (2 damage added per point in Light and Mind)\n\nHoly Strikes: Attacking will heal the most injured party member based on Body skill (2 points per point in Body and Spirit)\n\nDivine Protection: self-heals by 25% of your HP when facing lethal attacks, 5 minutes cooldown."
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
		
function pickLowestPartyMember()
	-- Define the variables
	local a={}
	a[0]=2
	a[1]=2
	a[2]=2
	a[3]=2
	a[4]=2
	for i=0,Party.High do
		if Party[i].Dead==0 and Party[i].Eradicated==0 then
			a[i] = Party[i].HP/GetMaxHP(Party[i])
		end
	end
	local a, b, c, d, e= a[0], a[1], a[2], a[3], a[4] 
	-- Find the maximum value and its position
	local min_value = math.min(a, b, c, d, e)
	local min_index = indexof({a, b, c, d, e}, min_value)
	min_index = min_index - 1
	return min_index
end

function events.CalcDamageToMonster(t)
	local data = WhoHitMonster()
		if data and data.Player and (data.Player.Class==55 or data.Player.Class==54 or data.Player.Class==53) and t.DamageKind==4 and data.Object==nil then
		
		local partyHP=0
		for i=0,Party.High do
			if Party[i].Dead==0 and Party[i].Eradicated==0 then
				partyHP=partyHP+Party[i].HP
			end
		end
		
		--get body
		body=data.Player:GetSkill(const.Skills.Body)
		bodyS,bodyM=SplitSkill(body)
		
		--get spirit
		spirit=data.Player:GetSkill(const.Skills.Spirit)
		spiritS,spiritM=SplitSkill(spirit)
		
		--Calculate heal value and apply
		healValue=(bodyS^1.3*bodyM+spiritS^1.3*spiritM)*damageMultiplier[t.PlayerIndex]["Melee"]
		personality=data.Player:GetPersonality()
		healValue=healValue*(1+personality/1000)
		--[[calculate crit
		critchance=data.Player:GetLuck()/15*10+50
		roll=math.random(1,1000)
		if roll<critchance then
			healValue=healValue*(1.5+personality*3/2000)
		end
		]]
		
		local healTarget=pickLowestPartyMember()
		--apply heal
		evt[healTarget].Add("HP",healValue)		
		--bug fix
		if Party[healTarget].HP>0 then
			Party[healTarget].Unconscious=0
		end
		local partyHP2=0
		for i=0,Party.High do
			if Party[i].Dead==0 and Party[i].Eradicated==0 then
				partyHP2=partyHP2+Party[i].HP
			end
		end
		if partyHP2>partyHP and (Party.EnemyDetectorRed or Party.EnemyDetectorYellow) then	
			local healing=partyHP2-partyHP
			local id=t.PlayerIndex
			vars.healingDone=vars.healingDone or {}
			vars.healingDone[id]=vars.healingDone[id] or 0
			vars.healingDone[id]=vars.healingDone[id] + healing
			mapvars.healingDone=mapvars.healingDone or {}
			mapvars.healingDone[id]=mapvars.healingDone[id] or 0
			mapvars.healingDone[id]=mapvars.healingDone[id] + healing
		end
	end
end

--[[mind light increases melee damage

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
MOVED IN MAW ITEMS, DUE TO WEAPON SCALING]]

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
					--calculate healing
				heal=round(GetMaxHP(t.Player)*0.25)
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
				
		--heal tooltips
		local pers=pl:GetPersonality()
		local healMult=1+pers/1000
		
		local spiritHeal=round(spiritS^1.3*spiritM*damageMultiplier[pl:GetIndex()]["Melee"]*healMult)
		local bodyHeal=round(bodyS^1.3*bodyM*damageMultiplier[pl:GetIndex()]["Melee"]*healMult)
		local txt=baseSchoolsTxtSERAPH[16] .. "\n\nSeraphim healing upon attack increases depending on Spirit magic, scaling with personality(weapon speed multiplier applies).\n\n" .. "Current heal from Spirit: " .. StrColor(0,255,0,spiritHeal) .. "\n"
		Skillz.setDesc(16,1,txt)
		local txt=baseSchoolsTxtSERAPH[18] .. "\n\nSeraphim healing upon attack increases depending on Body magic, scaling with personality(weapon speed multiplier applies).\n\n" .. "Current heal from Body: " .. StrColor(0,255,0,bodyHeal) .. "\n"
		Skillz.setDesc(18,1,txt)
		
		--damage tooltip
		local mindDMG=mindS*mindM
		local lightDMG=lightS*lightM
		local txt=baseSchoolsTxtSERAPH[16] .. "\n\nSeraphim damage upon attack increases depending on Mind magic, scaling with might(weapon speed and weapon damage multiplier applies).\n\n" .. "Current damage from Mind: " .. StrColor(255,0,0,mindDMG) .. "\n"
		Skillz.setDesc(17,1,txt)
		local txt=baseSchoolsTxtSERAPH[18] .. "\n\nSeraphim damage upon attack increases depending on Light magic, scaling with might(weapon speed and weapon damage multiplier applies).\n\n" .. "Current damage from Light: " .. StrColor(255,0,0,lightDMG) .. "\n"
		Skillz.setDesc(19,1,txt)
		
		--tooltips
		Skillz.setDesc(16,2,"Melee attacks heal on hit")
		Skillz.setDesc(16,3,"Double healing effect")
		Skillz.setDesc(16,4,"Triple healing effect")
		Skillz.setDesc(16,5,"n/a")
		
		Skillz.setDesc(17,2,"Increases damage by 0.5 per Skill point")
		Skillz.setDesc(17,3,"Increases damage by 1 per Skill point")
		Skillz.setDesc(17,4,"Increases damage by 1.5 per Skill point")
		Skillz.setDesc(17,5,"n/a")
		
		Skillz.setDesc(18,2,"Melee attacks heal on hit")
		Skillz.setDesc(18,3,"Double healing effect")
		Skillz.setDesc(18,4,"Triple healing effect")
		Skillz.setDesc(18,5,"n/a")
		
		Skillz.setDesc(19,2,"Increases damage by 0.5 per Skill point")
		Skillz.setDesc(19,3,"Increases damage by 1 per Skill point")
		Skillz.setDesc(19,4,"Increases damage by 1.5 per Skill point")
		Skillz.setDesc(19,5,"Increases damage by 2 per Skill point")
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
	["Damage"]={4,6,8,10,[0]=0},
	--["Speed"]={0,0,1,2,[0]=0},
}
local dragonBreath={
	--["Attack"]={0,0,0,0,[0]=0},
	["Damage"]={3,4,5,6,[0]=0},
	--["Speed"]={0,0,1,1,[0]=0},
}
local dragonScales={
	["AC"]={2,3,3,4,[0]=0},
	["Resistances"]={1,1,2,3,[0]=0},
}

function events.GameInitialized2()
	--fire blast tooltip
	Game.SpellsTxt[123].Description="This ability is an upgraded version of the normal Dragon breath weapon attack.  It acts much like a fireball, striking its target and exploding out to hit everything near it, except the explosion does much more damage than most fireballs."
	Game.SpellsTxt[123].Expert="Deals damage equal to 70% of breath damage"
	Game.SpellsTxt[123].Master="Deals damage equal to 85% of breath damage"
	Game.SpellsTxt[123].GM="Deals damage equal to 100% of breath damage"
	--mana cost
	Game.Spells[123].SpellPointsNormal=25
	Game.Spells[123].SpellPointsExpert=40
	Game.Spells[123].SpellPointsMaster=50
	Game.Spells[123].SpellPointsGM=60
	
	Game.Classes.SPBase[10]=60
	Game.Classes.SPFactor[10]=0
	Game.Classes.SPStats[10]=3
	Game.Classes.SPBase[11]=120
	Game.Classes.SPFactor[11]=0
	Game.Classes.SPStats[11]=3
	
	Skillz.setDesc(23,1,"Dragons are powerful creatures with innate abilities.\nLike the racial abilities of Dark Elves and Vampires, Dragon abilities are cast like spells, but are acquired like skills. Dragons begin able to cast Fear, the gain a second breath weapon, Flight and Wing Bugget at expert, master and grandmaster rankings.\n\nBreath damage is 20 + 2 per level (up to level 600) and total damage is increased by " .. dragonBreath.Damage[1] .. "-" .. dragonBreath.Damage[2] .. "-" .. dragonBreath.Damage[3] .. "-" .. dragonBreath.Damage[4] .. "% at novice, expert, master and grandmaster rankings per point of skill in Dragon Ability.\nEach point in the skill increases damage and increases recovery time by 3%."  )
	
	function events.CalcStatBonusByItems(t)
		if Game.CharacterPortraits[t.Player.Face].Race~=const.Race.Dragon then return end
		--melee
		if t.Stat==27 then --min damage
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Unarmed)) 
			local might=t.Player:GetMight()
			if might>=25 then
				mightEffect=math.floor(might/5)
			else
				mightEffect=math.floor((might-13)/2)
			end
			local bolster=getPartyLevel(4)+1
			local lvl=pl.LevelBase
			if pl.LevelBase/bolster>1.2 then
				lvl=math.min(pl.LevelBase/2,bolster)
			end
			local bonus= (1 + (dragonFang.Damage[m]) * s / 100)  * (math.min(lvl,600) * 2 +30) 
			t.Result=round((bonus*(1+might/1000)+(mightEffect*might/1000))*0.75*(1+0.03*s))
			
		elseif t.Stat==28 then --max damage
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Unarmed)) 
			local might=t.Player:GetMight()
			if might>=25 then
				mightEffect=math.floor(might/5)
			else
				mightEffect=math.floor((might-13)/2)
			end
			
			
			local bolster=getPartyLevel(4)+1
			local lvl=pl.LevelBase
			if pl.LevelBase/bolster>1.2 then
				lvl=math.min(pl.LevelBase/2,bolster)
			end
			local bonus= (1 + (dragonFang.Damage[m]) * s / 100)  * (math.min(lvl,600) * 2 +30)
			
			t.Result=round((bonus*(1+might/1000)+(mightEffect*might/1000))*1.25*(1+0.03*s))
			
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
			local might=t.Player:GetMight()
			local mightEffect
			if might>=25 then
				mightEffect=math.floor(might/5)
			else
				mightEffect=math.floor((might-13)/2)
			end
			
			local bolster=getPartyLevel(4)+1
			local lvl=pl.LevelBase
			if pl.LevelBase/bolster>1.2 then
				lvl=math.min(pl.LevelBase/2,bolster)
			end
			local baseDamage=(1 + dragonBreath.Damage[m] * s / 100) * (20 + 2 * math.min(lvl,600)) + mightEffect
			local damage=round(baseDamage*(1+might/1000)*0.75*(1+0.03*s))
			
			t.Result=damage
			
		elseif t.Stat==32 then --max damage
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.DragonAbility))
			local might=t.Player:GetMight()
			local mightEffect
			if might>=25 then
				mightEffect=math.floor(might/5)
			else
				mightEffect=math.floor((might-13)/2)
			end
			
			local bolster=getPartyLevel(4)+1
			local lvl=pl.LevelBase
			if pl.LevelBase/bolster>1.2 then
				lvl=math.min(pl.LevelBase/2,bolster)
			end
			local baseDamage=(1 + dragonBreath.Damage[m] * s / 100) * (20 + 2 * math.min(lvl,600)) + mightEffect
			local damage=round(baseDamage*(1+might/1000)*1.25*(1+0.03*s))
			
			t.Result=damage
		
		--AC
		elseif t.Stat==9 then
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Dodging))
			local oldDodge=skillAC[const.Skills.Dodging][m] or 0
			
			local bolster=getPartyLevel(4)+1
			local lvl=pl.LevelBase
			if pl.LevelBase/bolster>1.2 then
				lvl=math.min(pl.LevelBase/2,bolster)
			end
			local bonus= (1 + dragonScales.AC[m]/100 * s) * (math.min(lvl,600)+40) - (s * oldDodge)
			t.Result=t.Result+bonus
		elseif t.Stat>=10 and t.Stat<=15 then
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Dodging))
			local oldDodge=skillAC[const.Skills.Dodging][m] or 0
			
			local bolster=getPartyLevel(4)+1
			local lvl=pl.LevelBase
			if pl.LevelBase/bolster>1.2 then
				lvl=math.min(pl.LevelBase/2,bolster)
			end
			local bonus= (dragonScales.AC[m]/100 * s) * (math.min(lvl,600)+40)
			t.Result=t.Result+bonus
		end
		
		--no mana from items
		if t.Stat==const.Stats.SpellPoints then
			t.Result=0
		end
	end
	
	function events.GetAttackDelay(t)
		if Game.CharacterPortraits[t.Player.Face].Race==const.Race.Dragon then
			if useBreathCooldown or t.Ranged then
				local s, m = SplitSkill(t.Player:GetSkill(const.Skills.DragonAbility))
				t.Result=t.Result * (1+0.03*s)
				useBreathCooldown=false
			else
				local s, m = SplitSkill(t.Player:GetSkill(const.Skills.Unarmed))
				t.Result=t.Result * (1+0.03*s)
			end
		end	
	end
	function events.PlaySound(t)
		if t.Sound==18080 then
			useBreathCooldown=true
		end
	end
	--skill text
	normal=""
	normal=string.format("%s      %s|",normal,dragonFang.Attack[1])
	--normal=string.format("%s      %s|",normal,dragonFang.Speed[1])
	normal=string.format("%s     %s|",normal,dragonFang.Damage[1])
	fangsNormal=normal
	normal=""
	normal=string.format("%s  %s|",normal,dragonScales.AC[1])
	normal=string.format("%s    %s",normal,dragonScales.Resistances[1])
	scalesNormal=normal
	
	expert=""
	expert=string.format("%s      %s|",expert,dragonFang.Attack[2])
	--expert=string.format("%s      %s|",expert,dragonFang.Speed[2])
	expert=string.format("%s     %s|",expert,dragonFang.Damage[2])
	fangsExpert=expert
	expert=""
	expert=string.format("%s  %s|",expert,dragonScales.AC[2])
	expert=string.format("%s    %s",expert,dragonScales.Resistances[2])
	scalesExpert=expert
	
	master=""
	master=string.format("%s      %s|",master,dragonFang.Attack[3])
	--master=string.format("%s      %s|",master,dragonFang.Speed[3])
	master=string.format("%s     %s|",master,dragonFang.Damage[3])
	fangsMaster=master
	master=""
	master=string.format("%s  %s|",master,dragonScales.AC[3])
	master=string.format("%s    %s",master,dragonScales.Resistances[3])
	scalesMaster=master
	
	gm=""
	gm=string.format("%s      %s|",gm,dragonFang.Attack[4])
	--gm=string.format("%s      %s|",gm,dragonFang.Speed[4])
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
	if not vars.dragonMeditationRemoved then
		for i=0,Party.High do
			local pl=Party[i]
			if Game.CharacterPortraits[pl.Face].Race==const.Race.Dragon and (pl.Class==10 or pl.Class==11) then
				local s,m = SplitSkill(pl.Skills[const.Skills.Meditation])
				while s>1 do
					pl.SkillPoints=pl.SkillPoints+s
					s=s-1
				end
				pl.Skills[const.Skills.Meditation]=0
			end
		end
		vars.dragonMeditationRemoved=true
	end
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

function events.Tick()
	if Game.CurrentScreen==7 then
		local current=Game.CurrentPlayer
		if current>=0 and current<=Party.High then
			local race=Game.CharacterPortraits[Party[Game.CurrentPlayer].Face].Race
			if race==const.Race.Dragon then
				dragonSkill(true, Game.CurrentPlayer)
			else
				dragonSkill(false)
			end
		end
	end
end

function dragonSkill(dragon, index)	
	if dragon then
		if index==-1 then return end
		pl=Party[index]
		Skillz.setName(33, "Fangs")

		local txt="Dragons can use their fangs to deal atrocious damage to enemies. Damage is 30 + 2 per level (up to level 600). Fang skill increases this amount by a percentage based on mastery and skill level.\n\nWhenever this skill is below dragon skill it will push monsters away\nEach point in the skill increases damage and increases recovery time by 3%.\n" .. "\n------------------------------------------------------------\n            Attack| Dmg|"
		Skillz.setDesc(33,1,txt)
		Game.SkillDesNormal[33]=fangsNormal
		Game.SkillDesExpert[33]=fangsExpert
		Game.SkillDesMaster[33]=fangsMaster
		Game.SkillDesGM[33]=fangsGM
		Skillz.setName(32,"Scales")
		txt="Dragons scales are hard enough to work as natural armor, gaining naturally 40 + 1 AC per level (up to level 600).\nScales further enhance their thoughness and resistance to magical damage, increasing the thoughness by a percentage.\n\n------------------------------------------------------------\n          AC%| Res%"
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
		if Game.CurrentCharScreen==100 and Game.CurrentScreen==7 then
			Game.GlobalTxt[53] = "Damage\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
			Game.GlobalTxt[18] = "Attack         +" .. pl:GetMeleeAttack() .. "\n                 " .. shortenNumber(pl:GetMeleeDamageMin(), 4, false) .. "-" .. shortenNumber(pl:GetMeleeDamageMax(), 4, false) .. "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
			Game.GlobalTxt[203]="Shoot         +" .. pl:GetRangedAttack() .. "\n                 " .. shortenNumber(pl:GetRangedDamageMin(), 4, false) .. "-" .. shortenNumber(pl:GetRangedDamageMax(), 4, false) .. "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
		else
			Game.GlobalTxt[18]="Attack"
			Game.GlobalTxt[53]="Damage"
			Game.GlobalTxt[203]="Shoot"
		end
	else
		Game.GlobalTxt[18]="Attack"
		Game.GlobalTxt[53]="Damage"
		Game.GlobalTxt[203]="Shoot"
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
				
				local low=pl:GetMeleeDamageMin()
				local high=pl:GetMeleeDamageMax()
				local randomDamage=math.random(low, high) + math.random(low, high)
				local damage=round(randomDamage/2)
				
				--check by damage type
				index=table.find(damageKindMap,t.DamageKind)
				res=t.Monster.Resistances[index]
				if not res then return end
				critChance, critMult, crit=getCritInfo(pl,false,getMonsterLevel(t.Monster))
				if crit then
					damage=damage*critMult
				end
				if pl.Class==10 then
					pl.SP=math.min(pl.SP+10, 60)
				elseif pl.Class==11 then
					pl.SP=math.min(pl.SP+20, 120)
				end
				--apply Damage
				t.Result = damage /2^(res%1000/100)
			elseif t.DamageKind==50 or data.Spell==123 then
				local low=pl:GetRangedDamageMin()
				local high=pl:GetRangedDamageMax()
				local randomDamage=math.random(low, high) + math.random(low, high)
				local damage=round(randomDamage/2)
				
				critChance, critMult, crit=getCritInfo(pl,false,getMonsterLevel(t.Monster))
				if crit then
					damage=damage*critMult
				end
				if data.Spell==123 then
					local s,m=SplitSkill(t.Player.Skills[const.Skills.DragonAbility])
					local mult=0.85
					if m<=2 then
						mult=0.7
					elseif m==4 then
						mult=1
					end
					damage=damage*mult
				end
				--randomize
				damage=damage*0.75+(damage*math.random()*0.25)+(damage*math.random()*0.25)
				--resistance
				if t.Monster then
					local res=10000
					local mon=t.Monster
					for i=0,10 do
						if mon.Resistances[i] and mon.Resistances[i]%1000<res then
							res=mon.Resistances[i]%1000
						end
					end
					damage = damage/2^(res/100)
				end
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
	Game.ClassDescriptions[59] = "The Shaman is a mystical warrior whose knowledge of magic enhances his martial prowess.\nYou can check following values by checking magic schools description in skills menu.\n - Each school will provide a unique bonus. There is strength in diversifying as well as specialization\n - Each point in Air will reduce damage a % pr rank reduced by level\n - Each point in Water will reduce damage by a flat number, making water better for weaker enemies, or if your defenses are already strong\n - Each point in spirit will increase healing and spell damage by a %\n - Fire will deal a % of current monster HP as fire damage, partially piercing this resistance. The bosskiller.\n - Each point in Earth will increase melee damage by a flat amount\n - Each point in Body will heal by flat amount\n - Each point in mind will restore a flat amount of mana"
end

shamanClass={59, 60, 61}

function events.GameInitialized2()
	function events.CalcDamageToPlayer(t)
		if table.find(shamanClass, t.Player.Class) and t.Player.Unconscious==0 and t.Player.Dead==0 and t.Player.Eradicated==0  then
			m2=SplitSkill(t.Player.Skills[const.Skills.Air])
			m3=SplitSkill(t.Player.Skills[const.Skills.Water])
			local lvl=getPartyLevel(4)
			local reduction=getMonsterDamage((lvl+1)^0.325*m3)^0.7
			t.Result=math.max(t.Result-reduction, t.Result*0.25)
			t.Result=t.Result*0.99^m2
		end
	end
	
	function events.CalcDamageToMonster(t)	
		local data = WhoHitMonster()
		if data and data.Player and table.find(shamanClass, data.Player.Class) and t.DamageKind==4 and data.Object==nil and t.Result>0 then	
			m6=SplitSkill(data.Player.Skills[const.Skills.Mind])
			m7,bM=SplitSkill(data.Player.Skills[const.Skills.Body])
			
			local FHP=data.Player:GetFullHP()
			local leech=math.max(round(FHP^0.5* m7^1.5/70 * (0.5+bM/2)), m7)
			local maxSP=data.Player:GetFullSP()
			data.Player.SP=math.min(data.Player.SP+m6^1.25, getMaxMana(data.Player))
			
			local id=data.Player:GetIndex()
			
			local healing=math.min(data.Player:GetFullHP()-data.Player.HP, leech)
			if healing>0 then
				vars.leechDone=vars.leechDone or {}
				vars.leechDone[id]=vars.leechDone[id] or 0
				vars.leechDone[id]=vars.leechDone[id] + healing
				mapvars.leechDone=mapvars.leechDone or {}
				mapvars.leechDone[id]=mapvars.leechDone[id] or 0
				mapvars.leechDone[id]=mapvars.leechDone[id] + healing
			end
			data.Player.HP=math.min(data.Player.HP+leech, data.Player:GetFullHP())
		end
	end
	--[[
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
	MOVED IN MAW ITEMS, DUE TO WEAPON SCALING]]
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
		local m4, earthMastery=SplitSkill(pl.Skills[const.Skills.Earth])
		local m5=SplitSkill(pl.Skills[const.Skills.Spirit])
		local m6=SplitSkill(pl.Skills[const.Skills.Mind])
		local m7, bodyMastery=SplitSkill(pl.Skills[const.Skills.Body])
		local txt
		local fireDamage=m1/10
		txt=baseSchoolsTxt[12] .. "\n\nEach Skill point increases total spell damage by 0.5% and healing by 0.25%\nMelee attacks deal an extra " .. fireDamage .. "% of monster Hit points as fire damage"
		Skillz.setDesc(12,1,txt)
		local airReduction=100-round(0.99^m2*10000)/100
		txt=baseSchoolsTxt[13] .. "\n\nEach Skill point increases total spell damage by 0.5% and healing by 0.25%\nReduce all damage taken by " .. airReduction .. "%\n"
		Skillz.setDesc(13,1,txt)
		local lvl=getPartyLevel(4)
		local waterReduction=round(getMonsterDamage((lvl+1)^0.325*m3)^0.7)
		txt=baseSchoolsTxt[14] .. "\n\nEach Skill point increases total spell damage by 0.5% and healing by 0.25%\nReduce all damage taken by " .. waterReduction .. "(calculated after resistances)\n"
		Skillz.setDesc(14,1,txt)
		local armsmasterDamage=earthMastery*m4
		txt=baseSchoolsTxt[15] .. "\n\nEach Skill point increases total spell damage by 0.5% and healing by 0.25%\nIncreases melee damage 1-2-3-4 (at N-E-M-GM) per Earth Magic Level\n"
		Skillz.setDesc(15,1,txt)
		local spelldh=m5
		txt=baseSchoolsTxt[16] .. "\n\nEach Skill point increases total spell damage by 0.5% and healing by 0.25%\nIncreases melee damage by " .. spelldh .. "%\n"
		Skillz.setDesc(16,1,txt)
		SPLEECH=round(m6^1.25)
		txt=baseSchoolsTxt[17] .. "\n\nEach Skill point increases total spell damage by 0.5% and healing by 0.25%\nMelee attacks restore " .. SPLEECH .. " Spell Points\n"
		Skillz.setDesc(17,1,txt)
		local FHP=pl:GetFullHP()
		local leech=math.max(round(FHP^0.5* m7^1.5/70 * (1+bodyMastery/2)),m7)
		txt=baseSchoolsTxt[18] .. "\n\nEach Skill point increases total spell damage by 0.5% and healing by 0.25%\nMelee attacks restore " .. leech .. " Hit Points\n"
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
	function events.CalcStatBonusByItems(t)
		--[[damage from skills 
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
		end
		MOVED IN MAW ITEMS, DUE TO WEAPON SCALING]]
			
		if t.Stat==const.Stats.SpellPoints and table.find(dkClass, t.Player.Class) then
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
				damage=round(randomDamage/2)
				
				for i=0,1 do
					local it=pl:GetActiveItem(i)
					if it then
						local damage1=calcFireAuraDamage(pl, it, 0, true, false, "damage")
						local damage2=calcEnchantDamage(pl, it, 0, true, false, "damage")
						damage=damage+damage1+damage2
					end
				end
				
				local res=t.Monster.Resistances[t.DamageKind] or t.Monster.Resistances[4]
				damage=damage/2^(res/100)
				local mult=damageMultiplier[t.PlayerIndex]["Melee"]
				t.Result=damage*mult
				
				critChance, critMult, success=getCritInfo(pl,false,getMonsterLevel(t.Monster))
				
				if success then
					t.Result=t.Result*critMult
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
				local FHP=pl:GetFullHP()
				local monLvl=getMonsterLevel(t.Monster)
				local heal=FHP*(bloodS/round(monLvl^0.7))*0.05
				--current active leech spell
				vars.dkActiveAttackSpell=vars.dkActiveAttackSpell or {}
				local id=pl:GetIndex()
				leech=0
				if vars.dkActiveAttackSpell and (vars.dkActiveAttackSpell[id]==68 or vars.dkActiveAttackSpell[id]==74) then
					local FHP=pl:GetFullHP()
					local leech=FHP^0.5* bloodS^1.5/70* (1+bloodM/4)
					pl.SP=pl.SP-6
					if vars.dkActiveAttackSpell[id]==74 then
						leech=leech * 2
						pl.SP=pl.SP-6
					end
				end
				
				local id=pl:GetIndex()
			
				local healing=math.min(pl:GetFullHP()-pl.HP, round(leech+heal))
				if healing>0 then
					vars.leechDone=vars.leechDone or {}
					vars.leechDone[id]=vars.leechDone[id] or 0
					vars.leechDone[id]=vars.leechDone[id] + healing
					mapvars.leechDone=mapvars.leechDone or {}
					mapvars.leechDone[id]=mapvars.leechDone[id] or 0
					mapvars.leechDone[id]=mapvars.leechDone[id] + healing
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
					pl.SP=math.min(getMaxMana(pl), pl.SP+regen)
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
			if spellID~=71 then
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
end

function dkSkills(isDK, id)
	if isDK then
		local pl=Party[id]
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
		
		local FHP=pl:GetFullHP()
		local leech=FHP^0.5* bloodS^1.5/70
		Game.SpellsTxt[68].Name="Blood Leech"
		Game.SpellsTxt[68].Description="Activating this spell imbues the knight body with blood, leeching life upon attacking at the cost of 6 spell points."
		Game.SpellsTxt[68].Normal="Leeches " .. round(leech * 1.25) .. " Hit Points"
		Game.SpellsTxt[68].Expert="Leeches " .. round(leech * 1.5) .. " Hit Points"
		Game.SpellsTxt[68].Master="Leeches " .. round(leech * 1.75) .. " Hit Points"
		Game.SpellsTxt[68].GM="Leeches " .. round(leech * 2) .. " Hit Points"
		
		Game.SpellsTxt[74].Name="Superior Blood Leech"
		Game.SpellsTxt[74].Description="Activating this spell imbues the knight essence with blood, leeching a superior amount of life upon attacking at the cost of 12 spell points."
		Game.SpellsTxt[74].Master="n/a"
		Game.SpellsTxt[74].GM="Leeches " .. round(leech * 4) .. " Hit Points"
		
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
		txt="This skill is only available to death knights and increases damage by 0.5-1-1.5 (at Novice, Expert, Master) and increases attack speed by 2% per skill point.\n"
		Skillz.setDesc(14,1,txt)
		local leech=round(bloodS/round(pl.LevelBase^0.7)*5*100)/100
		txt="This skill is only available to death knights and reduces physical damage taken by 1% per skill point.\nAdditionally it will make your attacks to leech damage based on your total HP.\n\nCurrent leech vs. same level monsters: " .. leech .. "%\n"            
		Skillz.setDesc(18,1,txt)
		txt="This skill is only available to death knights and increases damage by 0.5-1-1.5 (at Novice, Expert, Master) and reduces magical damage taken by 1% per skill point.\n"	
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
	end
end


--[[add tooltips
function events.Action(t)
	function events.Tick() 
		local id=Game.CurrentPlayer
		if id>=0 and id<=Party.High then
			events.Remove("Tick", 1)
			checkSkills(id)
		end
	end
end
moved into ascension tick event, as it was causing some mana cost issues]]

function events.Action(t)
	if t.Action==114 then
		checkSkills(Game.CurrentPlayer)
	end
	if t.Action==110 then
		checkSkills(t.Param-1)
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
				checkSkills(newSelected)
			end
		end
	end
end


----------------
--ELEMENTALIST--
----------------

elementalistClass={62,63,64}

function events.GameInitialized2()
	Game.ClassDescriptions[62] = "The Elementalist is the caster with the highest mana pool, who learns spells not from the book, but from casting spells of the same elemental school. He can't learn Ascension, but his ascension level is directly tied to the sum of the school levels divided by 4. Baseline spell recovery time is 50% higher; however, when he casts Magic, he gains stacks, which increase:\n\nSpell Damage: 10% per stack\nSpell Recovery Speed: 5% per stack\nMana Cost: 1 + 7.5% of the total.\n\nAfter a few seconds without casting, the stacks decay by 50%. Dealing damage with a bow, melee weapon, or from the spellbook will break concentration, instantly resetting all stacks.\n\nSpells are cast randomly but divided into three categories: Single Target, Area of Effect, and Shotgun. Depending on the chosen quick-cast spell, the rotation is adjusted accordingly. For example, setting Fireball as a quick-cast spell will automatically prioritize AoE spells."
	Game.Classes.HPFactor[63]=2.5
end

function events.CanLearnSpell(t)
	if table.find(elementalistClass, t.Player.Class) then
		t.NeedMastery = 5
		Game.ShowStatusText("Elementalists learn their spells through practice")
	end
end

spellRequirements={0,0,500,1500,5000,10000,20000,40000,80000,160000,320000}
local masteryRequired={1,1,1,1,2,2,2,3,3,3,4}
function events.CalcDamageToMonster(t)
	if t.Monster.Hostile==false and t.Monster.ShowAsHostile==false then
		return
	end
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
		if not vars.insanityMode then
			learningBonus = learningBonus * Party.Count^0.5
		end
		if table.find(aoespells,spell) and spell~=15 and spell~=24 then
			learningBonus=learningBonus/3
		end
		vars.elementalistSpells[pl:GetIndex()][school]=vars.elementalistSpells[pl:GetIndex()][school] + learningBonus
		school2=(school-12)*11
		for i=1,11 do
			local spell2= school2+i
			if pl.Spells[spell2]==false then
				local tier=spell2%11==0 and 11 or spell2%11
				local s,m=SplitSkill(pl:GetSkill(school))
				if vars.elementalistSpells[pl:GetIndex()][school]>=spellRequirements[tier] and m>=masteryRequired[tier] then
					pl.Spells[spell2]=true
					Message("Learned " .. Game.SpellsTxt[spell2].Name)
				end
			end
		end		
	end
end

eleOffSpellsOut={2,6,7,9,11,
				15,18,20,22,
				24,26,29,32,
				37,39,41,43,44}
eleOffSpellsIn={2,6,7,10,11,
				15,18,20,
				24,26,29,32,
				37,39,41,44}

function events.Action(t)
	if t.Action==105 then
		if Game.CurrentPlayer>=0 and Game.CurrentPlayer<=Party.High then
			local pl=Party[Game.CurrentPlayer]
			if table.find(elementalistClass, pl.Class) then
				pl.Spells[2]=true
				pl.Spells[15]=true
				pl.Spells[24]=true
				pl.Spells[37]=true
			end
		end
	end
end


function events.PlayerCastSpell(t)
	if vars.disableRotation and vars.disableRotation[t.PlayerIndex] then
		return
	end
	if table.find(elementalistClass, t.Player.Class) and (table.find(eleOffSpellsOut, t.SpellId) or table.find(eleOffSpellsIn, t.SpellId)) and vars.elementalistSpellBinds then
		local pl=t.Player
		local index=t.PlayerIndex
		local spell=t.SpellId
		for i=1,6 do
			if i<=4 and ExtraQuickSpells.SpellSlots then
				if ExtraQuickSpells.SpellSlots[index][i]==spell then
					ExtraQuickSpells.SpellSlots[index][i]=elementalistRandomizer(pl, vars.elementalistSpellBinds[index][i])
				end
			elseif i==5 then
				if pl.AttackSpell==spell then
					pl.AttackSpell=elementalistRandomizer(pl, vars.elementalistSpellBinds[index][i])
				end
			elseif i==6 then
				if pl.QuickSpell==spell then
					pl.QuickSpell=elementalistRandomizer(pl, vars.elementalistSpellBinds[index][i])
				end
			end
		end
		vars.eleTimer=vars.eleTimer or {}
		vars.eleTimer[index]=Game.Time+math.max(getSpellDelay(pl,spell)*4, 128)
		vars.eleStacks=vars.eleStacks or {}
		vars.eleStacks[index]=vars.eleStacks[index] or 0
		vars.eleStacks[index]=vars.eleStacks[index]+1
		vars.eleTimer=vars.eleTimer or {}
	end
end

function elementalistStacksDecay()
	for i=0,Party.High do
		local pl=Party[i]
		if table.find(elementalistClass, pl.Class) then
			local id=pl:GetIndex()
			vars.eleStacks=vars.eleStacks or {}
			vars.eleStacks[id]=vars.eleStacks[id] or 0
			vars.eleTimer=vars.eleTimer or {}
			vars.eleTimer[id]=vars.eleTimer[id] or Game.Time
			if Game.Time>vars.eleTimer[id] then
				vars.eleTimer[id]=Game.Time+const.Minute/2
				vars.eleStacks[id]=math.max(math.floor(vars.eleStacks[id]*0.5),0)
			end
		end	
	end
end


function events.CalcDamageToMonster(t)
	local data=WhoHitMonster()
	if data and data.Player and (not data.Object or data.Object.Spell==133) then
		local pl=data.Player
		if table.find(elementalistClass, pl.Class) then
			local id=pl:GetIndex()
			vars.eleStacks=vars.eleStacks or {}
			vars.eleStacks[id]=0
		end
	end
end

singleTarget={2,11,20,26,29,37,39}
shotGun={2,15,24,37}
aoeIn={6,10,18,32,41}
aoeOut={6,9,18,22,32,41,43}

function elementalistRandomizer(pl, spellType)
	local possibleSpells={}
	if spellType=="single" then
		for i=1,#singleTarget do
			if pl.Spells[singleTarget[i]] then
				table.insert(possibleSpells, singleTarget[i])
			end
		end
	elseif spellType=="shotgun" then
		for i=1,#shotGun do
			if pl.Spells[shotGun[i]] then
				table.insert(possibleSpells, shotGun[i])
			end
		end
	elseif spellType=="aoe" and Map.IsIndoor() then
		for i=1,#aoeIn do
			if pl.Spells[aoeIn[i]] then
				table.insert(possibleSpells, aoeIn[i])
			end
		end
	elseif spellType=="aoe" then
		for i=1,#aoeOut do
			if pl.Spells[aoeOut[i]] then
				table.insert(possibleSpells, aoeOut[i])
			end
		end
	end
	if #possibleSpells>=1 then
		return possibleSpells[math.random(1,#possibleSpells)]
	else
		return false
	end
end

--reset stacks when casting from spellbook
function events.Action(t)
	if t.Action==142 then
		local id=Game.CurrentPlayer
		if id>=0 and id<=Party.High then
			if table.find(elementalistClass,Party[id].Class) then
				if table.find(eleOffSpellsOut,t.Param) or table.find(eleOffSpellsIn,t.Param) then
					vars.eleStacks=vars.eleStacks or {}
					vars.eleStacks[Party[id]:GetIndex()]=0
				end
			end
		end
	end
end

--set current keybind by keybindrotation
function events.Action(t)
	if Game.CurrentScreen==8 and t.Action==113 then
		local id=Game.CurrentPlayer
		if id>=0 and id<=Party.High then
			local pl=Party[id]
			local index=pl:GetIndex()
			if table.find(elementalistClass,pl.Class) then
				for i=1,6 do
					local spell=0
					if i<=4 and ExtraQuickSpells.SpellSlots then
						spell=ExtraQuickSpells.SpellSlots[index][i]
					elseif i==5 then
						spell=pl.AttackSpell
					elseif i==6 then
						spell=pl.QuickSpell
					end
					
					vars.elementalistSpellBinds=vars.elementalistSpellBinds or {}
					vars.elementalistSpellBinds[index]=vars.elementalistSpellBinds[index] or {}
					if table.find(singleTarget,spell) then
						vars.elementalistSpellBinds[index][i]="single"
					elseif table.find(shotGun,spell) then
						vars.elementalistSpellBinds[index][i]="shotgun"
					elseif table.find(aoeIn,spell) or table.find(aoeOut,spell) then
						vars.elementalistSpellBinds[index][i]="aoe"
					else
						vars.elementalistSpellBinds[index][i]=false					
					end
				end
			end
		end
	end
end

--show stacks
function events.GameInitialized2()
	elementalistStacks={}
	for i=0,4 do
		elementalistStacks[i]=CustomUI.CreateText{
			Text = "",
			Layer 	= 1,
			Screen 	= 0,
			X = 5+i*96, Y = 387
		}
	end
end

function events.Tick()
	for i=0,Party.High do
		local pl=Party[i]
		if table.find(elementalistClass,pl.Class) then
			local id=pl:GetIndex()
			vars.eleStacks=vars.eleStacks or {}
			vars.eleStacks[id]=vars.eleStacks[id] or 0
			elementalistStacks[i].Text=string.format(vars.eleStacks[id])
		else
			elementalistStacks[i].Text=""
		end
	end
end

local function elementalistSkills(isElementalist, id)
	if isElementalist then
		local pl=Party[id]
		vars.elementalistSpells=vars.elementalistSpells or {}
		vars.elementalistSpells[pl:GetIndex()]=vars.elementalistSpells[pl:GetIndex()] or {}
		for i=12,15 do
			vars.elementalistSpells[pl:GetIndex()][i]=vars.elementalistSpells[pl:GetIndex()][i] or 0
		end
	
		local list = vars.elementalistSpells[pl:GetIndex()]
		local enableDisableText = StrColor(0,255,0, "Enabled")
		if vars.disableRotation and vars.disableRotation[pl:GetIndex()] then
			enableDisableText = StrColor(255,0,0, "Disabled")
		end
		local rotationText = StrColor(0,0,0,"Elementalist offensive spells, when casted randomly, grant elementalist stacks, which increase spell damage, speed and cost.\nPress R to enable/disable random rotation.\nCurrently ") .. enableDisableText .. "\n\n"
		for i=12,15 do
			local progression=list[i]
			local currentTier=0
			for j=1,#spellRequirements do
				if progression>=spellRequirements[j] then
					currentTier=j
				end
			end
			if currentTier<11 then
				local low=spellRequirements[currentTier]
				local high=spellRequirements[currentTier+1]
				local percentageProgression=math.floor((progression-low)/(high-low)*10000)/100
				Skillz.setDesc(i,5, "Effects vary per spell \n\n" .. rotationText .. "Elementalists learn new spells with practice instead of books.\n\nProgress toward learning " .. Game.SpellsTxt[(i-12)*11+currentTier+1].Name .. ": " .. percentageProgression .."%")
			else
				Skillz.setDesc(i,5, "Effects vary per spell \n\n" .. rotationText .. "Elementalists learn new spells with practice instead of books.\n\nAll the available spells of this school have been learned.")
			end
		end
	else
		for i=12,15 do
			Skillz.setDesc(i,5,"Effects vary per spell")		
		end
	end
end


function checkSkills(id)
	lastCheckSkill=id
	shamanSkills(false, id)
	dkSkills(false, id)
	seraphSkills(false, id)
	elementalistSkills(false, id)
	assassinSkills(false)
	adjustSpellTooltips()
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
		if table.find(elementalistClass, class) then
			elementalistSkills(true, id)
			return
		end
		if table.find(assassinClass, class) then
			assassinSkills(true, Party[id])
			return			
		end
	end
end
--[[test code
function events.PlayerCastSpell(t)
	if t.SpellId==2 then
		BeginGrabObjects()
		function events.Tick()
			events.Remove("Tick",1)
			obj1=GrabObjects()
			
			--calculate velocity
			-- Define math constants
			local pi = math.pi
			local sqrt = math.sqrt
			local atan2 = math.atan2
			local cos = math.cos
			local sin = math.sin

			-- Original velocity components
			local V_x = obj1.VelocityX
			local V_y = obj1.VelocityY

			-- Number of projectiles and spread angle
			local n = 5
			local delta_theta = pi / 12

			-- Calculate the speed
			local speed = sqrt(V_x * V_x + V_y * V_y)

			-- Original direction angle
			local theta_0 = atan2(V_y, V_x)

			-- Calculate new velocities for each projectile
			new_velocities = {}

			for i = -math.floor(n / 2), math.floor(n / 2) do
				local theta_i = theta_0 + (delta_theta * i)
				local V_x_i = speed * cos(theta_i)
				local V_y_i = speed * sin(theta_i)
				table.insert(new_velocities, {V_x_i, V_y_i})
			end
			
			--manually change it
			for i=1,n do
			
				BeginGrabObjects()
				Game.SummonObjects(obj1.Type, obj1.X, obj1.Y, obj1.Z, 100,1)
				obj2=GrabObjects()
				
				obj2.Age=obj1.Age
				obj2.AttachToHead=obj1.AttachToHead
				obj2.AttackType=obj1.AttackType
				obj2.Bits=obj1.Bits
				obj2.Direction=obj2.Direction
				obj2.DroppedByPlayer=obj1.DroppedByPlayer
				obj2.HaltTurnBased=obj1.HaltTurnBased
				obj2.IgnoreRange=obj1.IgnoreRange
				obj2.LightMultiplier=obj1.LightMultiplier
				obj2.LookAngle=obj1.LookAngle
				obj2.MaxAge=obj1.MaxAge
				obj2.Missile=obj1.Missile
				obj2.NoZBuffer=obj1.NoZBuffer
				obj2.Owner=obj1.Owner
				obj2.Range=obj1.Range
				obj2.Removed=obj1.Removed
				obj2.Room=obj1.Room
				obj2.SkipAFrame=obj1.SkipAFrame
				obj2.Spell=obj1.Spell
				obj2.SpellLevel=obj1.SpellLevel
				obj2.SpellMastery=obj1.SpellMastery
				obj2.SpellSkill=obj1.SpellSkill
				obj2.SpellType=obj1.SpellType
				obj2.StartX=obj1.StartX
				obj2.StartY=obj1.StartY
				obj2.StartZ=obj1.StartZ
				obj2.Target=obj1.Target
				obj2.Temporary=obj1.Temporary
				obj2.Type=obj1.Type
				obj2.TypeIndex=obj1.TypeIndex
				obj2.VelocityX=new_velocities[i][1]
				obj2.VelocityY=new_velocities[i][2]
				obj2.VelocityZ=obj1.VelocityZ
				obj2.Visible=obj1.Visible
				obj2.X=obj1.X
				obj2.Y=obj1.Y
				obj2.Z=obj1.Z
			end
		end
	end
end
--getDistance(obj1.X,obj1.Y,obj1.Z,obj2.X,obj2.Y,obj2.Z,)
]]
--starts at +50% recovery time
--each spell cast grants a stack
--each stack increases attack speed by 10%, up to 10 stacks (making spell cast half as a normal caster would have)
--each stack increase ascension skill by 1
--base ascension skill increased by 1 every 8 elemental school level
--no ascension cap
--can't learn ascension
--attacking or shooting an arrow will reset stacks
--not casting for more than 5 seconds will reset stacks
--each spell is categorized between single, AoE or shotgun.
--each spell can have multiple categories

--minotaur hp fix
function events.GameInitialized2()
	Game.Classes.HPFactor[const.Class.Minotaur]=6
	Game.Classes.HPFactor[const.Class.MinotaurLord]=12
end

------------
--ASSASSIN--
------------

assassinClass={const.Class.Thief,const.Class.Rogue,const.Class.Assassin,const.Class.Spy}

function events.GameInitialized2()
	baseSchoolsTxtAssassin={}
	for i=1,5 do
		baseSchoolsTxtAssassin[i]={[12]=Skillz.getDesc(12,i), [13]=Skillz.getDesc(13,i), [14]=Skillz.getDesc(14,i), [15]=Skillz.getDesc(15,i)}
	end

	spellDesc2={}
	for key, value in pairs(assassinSpellList) do
		for i=1,#assassinSpellList[key] do
			local spellID=assassinSpellList[key][i]
			spellDesc2[spellID]={}
			spellDesc2[spellID]["Name"]=Game.SpellsTxt[value[i]].Name
			spellDesc2[spellID]["Description"]=Game.SpellsTxt[value[i]].Description
			spellDesc2[spellID]["Normal"]=Game.SpellsTxt[value[i]].Normal
			spellDesc2[spellID]["Expert"]=Game.SpellsTxt[value[i]].Expert
			spellDesc2[spellID]["Master"]=Game.SpellsTxt[value[i]].Master
			spellDesc2[spellID]["GM"]=Game.SpellsTxt[value[i]].GM
		end
	end

	
	function events.CalcStatBonusByItems(t)
		if t.Stat==const.Stats.SpellPoints and table.find(assassinClass, t.Player.Class) then
			local pl=t.Player
			local s,m=SplitSkill(pl:GetSkill(const.Skills.Earth))
			t.Result=m*10
		end
	end	
	
		

	function events.CalcDamageToMonster(t)
		local data = WhoHitMonster()
		if data and data.Player and table.find(assassinClass, data.Player.Class) then
			local pl=data.Player
			if data.Object and data.Object.Spell>0 and data.Object.Spell<=99 then
				local baseDamage=pl:GetMeleeDamageMin()
				local maxDamage=pl:GetMeleeDamageMax()
				local randomDamage=math.random(baseDamage, maxDamage) + math.random(baseDamage, maxDamage)
				local damage=round(randomDamage/2)
				
				local isolatedDamageReduction=assassinationDamage(pl,t.Monster,data.Object) --must be subtracted
				damage=damage-isolatedDamageReduction
				
				
				for i=0,1 do
					local it=pl:GetActiveItem(i)
					if it then
						local damage1=calcFireAuraDamage(pl, it, 0, true, false, "damage")
						local damage2=calcEnchantDamage(pl, it, 0, true, false, "damage")
						damage=damage+damage1+damage2
					end
				end
				
				local res=t.Monster.Resistances[t.DamageKind] or t.Monster.Resistances[4]
				damage=damage/2^(res/100)
				
				
				local mult=damageMultiplier[t.PlayerIndex]["Melee"]
				t.Result=damage*mult
				
				
				local critChance, critMult, success=getCritInfo(pl,false,getMonsterLevel(t.Monster))
				if success then
					t.Result=t.Result*critMult
					crit=true
				end
				
				t.Result=t.Result
				if pl.Weak>0 then
					t.Result=t.Result*0.5
				end
				
				if assassinSpells[data.Object.Spell].DamageMult then
					t.Result=t.Result*assassinSpells[data.Object.Spell].DamageMult
				end
			end
		end
	end
	
end


function assassinationDamage(pl,mon,obj)
	local id=pl:GetIndex()
	vars.assassinDamage=vars.assassinDamage or {}
	vars.assassinDamage[id]=vars.assassinDamage[id] or 0
	vars.assassinStacks=vars.assassinStacks or {}
	vars.assassinStacks[id]=vars.assassinStacks[id] or 0
	
	local s,m=SplitSkill(pl:GetSkill(const.Skills.Fire))
	local restoreChance=0.1+s*0.01
	local manaCost=50-m*5
	
	if obj and obj.Spell>0 and obj.Spell<100 then
		restoreChance=0
		manaCost=0
	end
	
	if obj then
		restoreChance=restoreChance/2
		manaCost=manaCost/2
	end
	if restoreChance>math.random() then
		pl.SP=math.min(pl:GetFullSP(),pl.SP+15)
	end
	function events.Tick()
		events.Remove("Tick", 1)
		if mon.HP<=0 then
			s,m=SplitSkill(pl:GetSkill(const.Skills.Air))
			local fullSP=pl:GetFullSP()
			pl.SP=math.min(fullSP, pl.SP+(1+m)*5)
			vars.assassinStacks[id]=math.min(vars.assassinStacks[id]+1,5)
		end
	end
	if pl.SP>=manaCost and mon.ShowAsHostile then
		if obj and obj.Spell>100 then
			vars.assassinStacks[id]=math.min(vars.assassinStacks[id]+0.5,5)--arrow nerf
		elseif not obj then
			vars.assassinStacks[id]=math.min(vars.assassinStacks[id]+1,5)
		end
		local damage=vars.assassinDamage[id]
		local monsters=0
		for i=0,Map.Monsters.High do
			local mapMon=Map.Monsters[i]
			if mapMon.AIState~=11 and mapMon.AIState~=5 and getDistances(mon,mapMon)<384 then
				monsters=monsters+1
			end
		end
		local damageMult=math.min(0.8,(monsters-1)*0.2)
		if obj then
			damage=damage/2
		end
		pl.SP=pl.SP-manaCost
		
		damage=damage*damageMult
		return damage
	end
	return vars.assassinDamage[id]	
end

function assassinSkills(isAssassin, pl)
	if isAssassin then
		if pl then
			for key, value in pairs(assassinSpells) do
				local id=pl:GetIndex()
				if vars.assassinStacks[id]<assassinSpells[key].StackCost then
					for i=1,4 do
						Game.Spells[key]["SpellPoints" .. masteryName[i]]=1000
					end
				else
					for i=1,4 do
						Game.Spells[key]["SpellPoints" .. masteryName[i]]=assassinSpells[key].Cost
					end
				end
			end
		end
		--skill names and desc
		
		Skillz.setName(12, "Combat")
		Skillz.setName(13, "Subtlety")
		Skillz.setName(14, "Poisons")
		Skillz.setName(15, "Assassination")
		
		Skillz.setDesc(12,1,"Combat is the skill that allows you to endure prolonged fights by enhancing your energy recovery.\n\nEach attack has a base 10% chance, plus 1% per skill point, to restore 15 energy.\n\n");
		Skillz.setDesc(13,1,"Subtlety manipulates the boundary between life and death, granting you energy upon killing enemies and increasing your chance to evade.\n\nEach incoming attack has a base 5% chance, plus 0.05% per skill point, to be dodged.\n\n");
		Skillz.setDesc(14,1,"Poisoning is the art of mastering toxins through self-experimentation, transforming suffering into vitality. Higher skill levels increase your energy regeneration.\n\nEach attack deals bonus water damage equal to 0.1% of the target's HP per skill point.\n\n");
		Skillz.setDesc(15,1,"Assassination focuses on eliminating isolated targets before they react. Attacks that spend energy or spells, have your damage increased by 4-6-8-10 per skill point, reduced by 20% for each target's nearby enemy (up to 4 enemies).\nSuch attacks also grant 1 combo point, allowing the assassin to cast offensive spells.\nBow has 50% chance and energy cost.\n\nHigher levels also grant more starting energy, ideal for high burst damage in short engagements.\n\n");

		
		Skillz.setDesc(12,2,"Melee attack costs 45 energy")
		Skillz.setDesc(13,2,"Killing a monster restores 10 energy")
		Skillz.setDesc(14,2,"You regenerate 8 energy per second")
		Skillz.setDesc(15,2,"Increases your maximum energy by 10")
		
		Skillz.setDesc(12,3,"Melee attack costs 40 energy")
		Skillz.setDesc(13,3,"Killing a monster restores 15 energy")
		Skillz.setDesc(14,3,"You regenerate 10 energy per second")
		Skillz.setDesc(15,3,"Increases your maximum energy by 20")
		
		Skillz.setDesc(12,4,"Melee attack costs 35 energy")
		Skillz.setDesc(13,4,"Killing a monster restores 20 energy")
		Skillz.setDesc(14,4,"You regenerate 12 energy per second")
		Skillz.setDesc(15,4,"Increases your maximum energy by 30")
		
		Skillz.setDesc(12,5,"Melee attack costs 30 energy")
		Skillz.setDesc(13,5,"Killing a monster restores 25 energy")
		Skillz.setDesc(14,5,"You regenerate 14 energy per second")
		Skillz.setDesc(15,5,"Increases your maximum energy by 40")
		
		Game.SpellsTxt[6].Description=string.format("Fires a ball of fire at a single target. When it hits, the ball explodes damaging all those nearby, including your characters if they're too close.  Fireball does %s%% of a melee attack damage.",assassinSpells[6].DamageMult*100)
		Game.SpellsTxt[7].Description=string.format("Drops a Fire Spike on the ground that waits for a creature to get near it before exploding.  Fire Spikes last until you leave the map or they are triggered. Fire Spike does %s%% of a melee attack damage.",assassinSpells[7].DamageMult*100)
		Game.SpellsTxt[18].Description=string.format("Lightning Bolt discharges electricity from the caster's hand to a single target.  It always hits and does %s%% of a melee attack damage.\n\nThe spell then arcs to a second target, hitting it as well.",assassinSpells[18].DamageMult*100)
		Game.SpellsTxt[24].Description=string.format("Sprays poison at monsters directly in front of your characters.  Damage is low, but few monsters have resistance to Water Magic, so it usually works.  Each shot does %s%% of a melee attack damage.",assassinSpells[24].DamageMult*100)
		Game.SpellsTxt[29].Description=string.format("Acid burst squirts a jet of extremely caustic acid at a single victim.  It always hits and does %s%% of a melee attack damage.",assassinSpells[29].DamageMult*100)
		Game.SpellsTxt[34].Description=string.format("Slaps a monster with magical force, forcing it to recover from the stun spell before it can do anything else.  Stun also knocks monsters back a little, giving you a chance to get away while the getting is good.  The greater your skill in Earth Magic, the greater the effect of the spell. Stun does %s%% of a melee attack damage.",assassinSpells[34].DamageMult*100)
		Game.SpellsTxt[39].Description=string.format("Fires a rotating, razor-thin metal blade at a single monster.  The blade does %s%% of a melee attack damage.\n\nBlades is the only spell capable to deal Physical damage.",assassinSpells[39].DamageMult*100)
		Game.SpellsTxt[44].Description=string.format("Increases the weight of a single target enormously for an instant, causing internal damage equal to %s%% of a melee attack damage.",assassinSpells[44].DamageMult*100)
		
		Game.SpellsTxt[18].Expert="Spell hits up to 2 times"
		Game.SpellsTxt[18].Master="Spell hits up to 3 times"
		Game.SpellsTxt[18].GM="Spell hits up to 4 times"
		
		for key, value in pairs(assassinSpells) do
			if assassinSpells[key].StackCost>0 then
				Game.SpellsTxt[key].Description=Game.SpellsTxt[key].Description .. "\n\nThis Ability requires " .. assassinSpells[key].StackCost .. " Combo Points to be casted."
			end
		end
		
	else
		for i=1,5 do
			for key, value in pairs(baseSchoolsTxtAssassin[i]) do
				Skillz.setDesc(key,i,value)
			end
		end
		for key, value in pairs(spellDesc2) do
			for key2, value2 in pairs(value) do
				Game.SpellsTxt[key][key2]=value2
			end
		end
		Skillz.setName(12, "Fire Magic")
		Skillz.setName(13, "Air Magic")
		Skillz.setName(14, "Water Magic")
		Skillz.setName(15, "Earth Magic")
	end
end
function events.CanLearnSpell(t)
	if table.find(assassinClass, t.Player.Class) then
		t.NeedMastery = 5
	end
end

function events.GameInitialized2()
	local sp=const.Spells
	assassinSpells={
		[sp.TorchLight]={["Cost"]=1,["StackCost"]=0,["DamageMult"]=0,},
		[sp.FireAura]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
		[sp.Haste]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
		[sp.Fireball]={["Cost"]=0,["StackCost"]=5,["DamageMult"]=1,},
		[sp.FireSpike]={["Cost"]=0,["StackCost"]=3,["DamageMult"]=2.5,},
		
		[sp.WizardEye]={["Cost"]=1,["StackCost"]=0,["DamageMult"]=0,},
		[sp.Jump]={["Cost"]=5,["StackCost"]=0,["DamageMult"]=0,},
		[sp.Shield]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
		[sp.LightningBolt]={["Cost"]=0,["StackCost"]=5,["DamageMult"]=1.5,},
		[sp.Invisibility]={["Cost"]=15,["StackCost"]=0,["DamageMult"]=0,},
		[sp.Fly]={["Cost"]=25,["StackCost"]=0,["DamageMult"]=0,},
		
		[sp.PoisonSpray]={["Cost"]=0,["StackCost"]=3,["DamageMult"]=0.75,},
		[sp.WaterWalk]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
		[sp.AcidBurst]={["Cost"]=0,["StackCost"]=3,["DamageMult"]=3,},
		[sp.TownPortal]={["Cost"]=20,["StackCost"]=0,["DamageMult"]=0,},
		[sp.LloydsBeacon]={["Cost"]=30,["StackCost"]=0,["DamageMult"]=0,},
		
		[sp.Stun]={["Cost"]=0,["StackCost"]=3,["DamageMult"]=1.5,},
		[sp.StoneSkin]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
		[sp.Blades]={["Cost"]=0,["StackCost"]=3,["DamageMult"]=3},
		[sp.Telekinesis]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
		[sp.MassDistortion]={["Cost"]=0,["StackCost"]=4,["DamageMult"]=4,},
	}				
end

assassinSpellList={
	[const.Skills.Fire]={1, 4, 5, 6, 7},
	[const.Skills.Air]={12, 17, 16, 18, 19, 21},
	[const.Skills.Water]={24, 27, 29, 31, 33},
	[const.Skills.Earth]={34, 38, 39, 42, 44},
}

function events.Action(t)
	if t.Action==105 and Game.CurrentPlayer>=0 and Game.CurrentPlayer<=Party.High then
		
		pl=Party[Game.CurrentPlayer]
		if table.find(assassinClass, pl.Class) then
			for i=1,99 do
				pl.Spells[i]=false
			end
			local s1, m1=SplitSkill(pl.Skills[const.Skills.Fire])
			local s2, m2=SplitSkill(pl.Skills[const.Skills.Air])
			local s3, m3=SplitSkill(pl.Skills[const.Skills.Water])
			local s4, m4=SplitSkill(pl.Skills[const.Skills.Earth])
			m1=m1+1
			m2=m2+2
			m3=m3+1
			m4=m4+1
			for i=1, m1 do
				pl.Spells[assassinSpellList[const.Skills.Fire][i]]=true
			end
			for i=1, m2 do
				pl.Spells[assassinSpellList[const.Skills.Air][i]]=true
			end
			for i=1, m3 do
				pl.Spells[assassinSpellList[const.Skills.Water][i]]=true
			end
			for i=1, m4 do
				pl.Spells[assassinSpellList[const.Skills.Earth][i]]=true
			end
		end
	end
end

--show stacks
function events.GameInitialized2()
	assassinStacks={}
	for i=0,4 do
		assassinStacks[i]=CustomUI.CreateText{
			Text = "",
			Layer 	= 1,
			Screen 	= 0,
			X = 5+i*96, Y = 387
		}
	end
end

function events.Tick()
	for i=0,Party.High do
		local pl=Party[i]
		if table.find(assassinClass,pl.Class) then
			local id=pl:GetIndex()
			vars.assassinStacks=vars.assassinStacks or {}
			vars.assassinStacks[id]=vars.assassinStacks[id] or 0
			assassinStacks[i].Text=string.format(math.floor(vars.assassinStacks[id]))
		else
			assassinStacks[i].Text=""
		end
	end
end

function events.PlayerCastSpell(t)
	local pl=t.Player
	if table.find(assassinClass,pl.Class) then
		if assassinSpells[t.SpellId] and assassinSpells[t.SpellId].StackCost>0 then 
			local id=pl:GetIndex()
			if vars.assassinStacks[id]<assassinSpells[t.SpellId].StackCost then
				t.Handled=true
				DoGameAction(23,0,0)
			else
				vars.assassinStacks[id]=vars.assassinStacks[id]-assassinSpells[t.SpellId].StackCost
			end
		end
	end
end
--spells speed depends on weapon
function GetAssassinSpellDelay(pl,spell)
	return pl:GetAttackDelay()*2
end
--CastQuickSpell(0,6)
--[[spells
fire spike fire aura fireball haste
invisibility chain lightning jump shield
poison spray, town portal, lloyd, acid burst
stun stoneskin blades mass distorsion

combat - attack speed on skill
subtlety - i0.5% chance to dodge an incoming attack
poison - %HP water damage on energy attack
assassination - adds flat damage (scaling with weapon skill) on isolated targets on skill (damage decreases depending on the number of targets in the nearby)
]]
