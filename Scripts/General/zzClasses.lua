--code to share promotions
--game ordered from mm6 to mm8, first promotion then honorary promotion qbits, mm7 has 4 qbits total
promotionList={
--Archer
[1]=		{1657,1658,		1586,1587,1588,1589,	1537,20},--dark elf 
--Cleric
[2]=		{1648,1649,		1609,1610,1611,1612,	1546,31},
--Dark Elf
[3]=	{1657,1658,		1586,1587,1588,1589,	1537,20},--archer
--Dragon
[4]=		{1645,1646,		1568,1569,1570,1571,	1543,1544},--knight 
--Druid
[5]= 		{1651,1652,		1615,1616,1617,1618,	1546,31},--cleric
--Knight
[6]=		{1645,1646,		1568,1569,1570,1571,	1540,1541},
--Minotaur
[7]=	{1637,1638,		1592,1593,1594,1595,	1545,29},--paladin
--Monk
[8]=		{1645,1646,		1568,1569,1570,1571,	1538,1539},--knight and troll
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
[17]=	{1648,1649,		1609,1610,1611,1612,	1546,31},--cleric
--DK
[18]=	{1645,1646,		1568,1569,1570,1571,	1540,1541},
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
		levelBonus=2+math.min(t.Player.LevelBase,250)/50
		healValue=bodyS*levelBonus+spiritS*levelBonus
		personality=data.Player:GetPersonality()
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

function events.CalcStatBonusBySkills(t)
	if t.Stat==const.Stats.MeleeDamageBase then
		if t.Player.Class==55 or t.Player.Class==54 or t.Player.Class==53 then
			light=t.Player:GetSkill(const.Skills.Light)
			lightS,lightM=SplitSkill(light)
			--get mind
			mind=t.Player:GetSkill(const.Skills.Mind)
			mindS,mindM=SplitSkill(mind)
			levelBonus=2+math.min(t.Player.LevelBase,250)/100
			damage=mindS*levelBonus + lightS*levelBonus
			t.Result=t.Result+damage
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
				heal=totMana
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


---------------------------------------
--DEATH KNIGHT
---------------------------------------

--skills
--death grip

--runic power
	--attacks will grant 10-12-15-17-20 runic power

--spells
--dark grants some leech (flat, based on promotion)
--water adds damage/attack speed
--earth grants some damage reduction

--spells scale with strength



--spells taking you below 35% of HP will trigger anti-magic shell, 
		--reducing spell damage taken by 50% and converting spell damage into runic power (lasts 5 seconds, 1 minute cooldown, capped to max player HP)

