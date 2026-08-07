--Per-class data, runtime and handler bodies live in
--Scripts/Modules/MawCore/Classes.lua (see MawCore/NOTES.md).
--What stays here: promotions, seraph, dragon, shaman, and the one-line
--registration stubs that must keep their position in the handler chain.
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
--class id lists + the presentation dispatcher: MawCore/Classes.lua

--2h swords in 1h
function events.GameInitialized2()
	twoHandedSwords={}
	for i=1,Game.ItemsTxt.High do
		local it=Game.ItemsTxt[i]
		if it.Skill==1 and it.EquipStat==1 then
			table.insert(twoHandedSwords, i)
		end
	end
end
function events.Action(t)
	if t.Action==133 then
		local id=Game.CurrentPlayer
		if id<0 or id>Party.High then
			Game.CurrentPlayer=0
			id=0
		end
		local pl=Party[id]
		if table.find(seraphClass, pl.Class) then
			local it=Mouse.Item
			if it then
				local txt=it:T()
				local s=SplitSkill(pl.Skills[const.Skills.Sword])
				if txt.EquipStat==1 and txt.Skill==1 then
					txt.EquipStat=0
--Novice for this action only: the now-one-handed sword must not go offhand
					tempSkillForEquip(pl, const.Skills.Sword, s, 1)
					RunNextTick(function()
						txt.EquipStat=1
					end)
				elseif txt.EquipStat==4 and txt.Skill==8 then
					local weapon=pl:GetActiveItem(1,true)
					if weapon then
						local txt=weapon:T()
						if txt.EquipStat==1 and txt.Skill==1 then
							txt.EquipStat=0
							RunNextTick(function()
								txt.EquipStat=1
							end)
						end
					end
				end
			end
			local weapon=pl:GetActiveItem(1,true)
			local shield=pl:GetActiveItem(0,true)
			if weapon and shield then
				local txt=weapon:T()
				if txt.EquipStat==1 and txt.Skill==1 then
					txt.EquipStat=0
					RunNextTick(function()
						txt.EquipStat=1
					end)
				end
			end
		end
	end
end
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
	return min_index, min_value
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

--base school texts for the tooltip builders, captured before the later
--init handlers append to them (SKILL_TOOLTIPS.md)
MawSchoolDescBase={}
function events.GameInitialized2()
	for id=12,20 do
		MawSchoolDescBase[id]=Skillz.getDesc(id,1)
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

--shared dragon formulas (min/max rows differ only by the spread mult)
local dragonRecoveryPerSkill=0.015
local function dragonEffLevel(pl)
	local bolster=getPartyLevel(4)+1
	local lvl=pl.LevelBase
	if pl.LevelBase/bolster>1.2 then
		lvl=math.min(pl.LevelBase/2,bolster)
	end
	local cap=600
	if vars.madnessMode then
		cap=900
	end
	return math.min(lvl,cap)
end
local function dragonFangDamage(pl, mult)
	local s, m = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
	local might=pl:GetMight()
	local mightEffect=Game.GetStatisticEffect(might)
	local bonus= (1 + (dragonFang.Damage[m]) * s / 100)  * (dragonEffLevel(pl) * 2 +30)
	return round((bonus*(1+might/1000)+(mightEffect*might/1000))*mult*(1+s*dragonRecoveryPerSkill))
end
local function dragonBreathDamage(pl, mult)
	local s, m = SplitSkill(pl:GetSkill(const.Skills.DragonAbility))
	local might=pl:GetMight()
	local mightEffect=Game.GetStatisticEffect(might)
	local baseDamage=(1 + dragonBreath.Damage[m] * s / 100) * (20 + 2 * dragonEffLevel(pl)) + mightEffect
	return round(baseDamage*(1+might/1000)*mult*(1+s*dragonRecoveryPerSkill))
end

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
	
	Skillz.setDesc(23,1,"Dragons are powerful creatures with innate abilities.\nLike the racial abilities of Dark Elves and Vampires, Dragon abilities are cast like spells, but are acquired like skills. Dragons begin able to cast Fear, the gain a second breath weapon, Flight and Wing Bugget at expert, master and grandmaster rankings.\n\nBreath damage is 20 + 2 per level (up to level 600, or 900 in madness) and total damage is increased by " .. dragonBreath.Damage[1] .. "-" .. dragonBreath.Damage[2] .. "-" .. dragonBreath.Damage[3] .. "-" .. dragonBreath.Damage[4] .. "% at novice, expert, master and grandmaster rankings per point of skill in Dragon Ability.\nEach point in the skill increases damage and increases recovery time by 3%."  )
	--skill text: one row per mastery from the dragonFang/dragonScales tables
	local function fangRow(m)
		return string.format("      %s|     %s|",dragonFang.Attack[m],dragonFang.Damage[m])
	end
	local function scaleRow(m)
		return string.format("  %s|    %s",dragonScales.AC[m],dragonScales.Resistances[m])
	end
	fangsNormal,fangsExpert,fangsMaster,fangsGM=fangRow(1),fangRow(2),fangRow(3),fangRow(4)
	scalesNormal,scalesExpert,scalesMaster,scalesGM=scaleRow(1),scaleRow(2),scaleRow(3),scaleRow(4)

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

function mawTick_DragonCharScreen()
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
		Skillz.setName(32,"Scales")
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
		Skillz.setName(32,"Dodging")
	end
end

function events.GameInitialized2()
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

function mawTick_MonsterPush()
	local push=MawCore.DamageState.getPushes()
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


---------------------------------------
--SHAMAN
---------------------------------------
function events.GameInitialized2()
	Game.ClassDescriptions[59] = "The Shaman is a mystical warrior whose knowledge of magic enhances his martial prowess.\nYou can check following values by checking magic schools description in skills menu.\n - Each school will provide a unique bonus. There is strength in diversifying as well as specialization\n - Each point in Air will reduce damage a % pr rank reduced by level\n - Each point in Water will reduce damage by a flat number, making water better for weaker enemies, or if your defenses are already strong\n - Each point in spirit will increase healing and spell damage by a %\n - Fire will deal a % of current monster HP as fire damage, partially piercing this resistance. The bosskiller.\n - Each point in Earth will increase melee damage by a flat amount\n - Each point in Body will heal by flat amount\n - Each point in mind will restore a flat amount of mana"
end


function events.GameInitialized2()
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


---------------------------------------
--DEATH KNIGHT
---------------------------------------
function events.GameInitialized2()
	Game.ClassDescriptions[56] = "This class combines the evil forces with brute power, making it powerful and versatile.\n Learning Frost/Blood/Unholy E/M/GM will unlock automatically new spells. However death knight can't learn spells from books.\n\nFrost:\n\nIncreases damage by 1-2-3 (at Novice, Master, Grandmaster levels) and boosts attack speed by 1% for every skill point invested.\n\nBlood:\n\nThis skill fortifies their resilience, reducing physical damage taken by 1% per skill point. Additionally, it endows their attacks with a leech effect, converting a portion of the damage dealt into health recovery.\n\nUnholy:\n\nIt amplifies damage by 1-2-3 (at Novice, Master, Grandmaster levels) and diminishes magical damage received by 1% for each skill point allocated."
end
--skills
--death grip

--runic power

--change spell cost to personalized value:

--spells

--body: MawCore/Classes.lua; registration kept here for handler order
function events.Action(t)
	MawCore.Classes.dkSpellbook(t)
end

--body: MawCore/Classes.lua; registration kept here for handler order
function events.CanLearnSpell(t)
	MawCore.Classes.dkLearnSpell(t)
end


--tooltips
function events.GameInitialized2()
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


function events.GameInitialized2()
	Game.ClassDescriptions[62] = "The Elementalist is the caster with the highest mana pool, who learns spells not from the book, but from casting spells of the same elemental school. He can't learn Ascension, but his ascension level is directly tied to the sum of the school levels divided by 4. Baseline spell recovery time is 50% higher; however, when he casts Magic, he gains stacks, which increase:\n\nSpell Damage: 10% per stack\nSpell Recovery Speed: 5% per stack\nMana Cost: 1 + 7.5% of the total.\n\nAfter a few seconds without casting, the stacks decay by 50%. Dealing damage with a bow, melee weapon, or from the spellbook will break concentration, instantly resetting all stacks.\n\nSpells are cast randomly but divided into three categories: Single Target, Area of Effect, and Shotgun. Depending on the chosen quick-cast spell, the rotation is adjusted accordingly. For example, setting Fireball as a quick-cast spell will automatically prioritize AoE spells."
	Game.Classes.HPFactor[63]=2.5
end

--body: MawCore/Classes.lua; registration kept here for handler order
function events.CanLearnSpell(t)
	MawCore.Classes.eleLearnSpell(t)
end

--body: MawCore/Classes.lua; registration kept here for handler order
function events.Action(t)
	MawCore.Classes.eleSpellbook(t)
end


--body: MawCore/Classes.lua; registration kept here for handler order
function events.PlayerCastSpell(t)
	MawCore.Classes.eleCastRotation(t)
end


--reset stacks when casting from spellbook
--body: MawCore/Classes.lua; registration kept here for handler order
function events.Action(t)
	MawCore.Classes.eleBindQuick(t)
end

--set current keybind by keybindrotation
--body: MawCore/Classes.lua; registration kept here for handler order
function events.Action(t)
	MawCore.Classes.eleBindScreen(t)
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


function checkSkills(id)
	MawCore.Classes.present(id)
end
--[[test code
function events.PlayerCastSpell(t)
	if t.SpellId==2 then
		BeginGrabObjects()
		RunNextTick(function()
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
		end)
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


function events.GameInitialized2()
	
end

--body: MawCore/Classes.lua; registration kept here for handler order
function events.CanLearnSpell(t)
	MawCore.Classes.assassinLearnSpell(t)
end


--body: MawCore/Classes.lua; registration kept here for handler order
function events.Action(t)
	MawCore.Classes.assassinSpellbook(t)
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

--body: MawCore/Classes.lua; registration kept here for handler order
function events.PlayerCastSpell(t)
	MawCore.Classes.assassinCastStacks(t)
end
--spells speed depends on weapon
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
function events.BeforeLoadMap()
	if not vars.LichFix then
		for i=0, Party.High do
			local pl=Party[i]
			if pl.Class==const.Class.Lich and pl.LevelBase==1 then
				pl.Class=const.Class.Necromancer
			end
		end
		vars.LichFix=true
	end
end

--Tick handlers above run as MawCore scheduler tasks (ms; 0=frame, -1=poke only)
function events.GameInitialized2()
	local every=MawCore.Scheduler.every
	every("classes/dragon-charscreen", 100, mawTick_DragonCharScreen)
	every("classes/monster-push", 0, mawTick_MonsterPush)
	every("classes/elementalist-stacks", 100, mawTick_ElementalistStacks)
	every("classes/assassin-stacks", 100, mawTick_AssassinStacks)
end
