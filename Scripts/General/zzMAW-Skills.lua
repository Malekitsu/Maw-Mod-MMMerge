local function UncapSkills(char)
	for _,skill in pairs(const.Skills) do
		local value = char.Skills[skill]
		
		if value > 0x100 then
			char.Skills[skill] = value - 0x100 + 0x1000
		elseif value > 0x80 then
			char.Skills[skill] = value - 0x80 + 0x800
		elseif value > 0x40 then
			char.Skills[skill] = value - 0x40 + 0x400
		end
	end
end

function events.LoadMap(wasInGame)
	if not vars.UncappedSkills then
		vars.UncappedSkills = 1
		for i=0,Party.PlayersArray.High do
			UncapSkills(Party.PlayersArray[i])
		end
	end
end

-- weapon base recovery bonuses
baseRecovery =
{
	[const.Skills.Bow] = 100,
	[const.Skills.Blaster] = 40,
	[const.Skills.Staff] = 120,
	[const.Skills.Axe] = 140,
	[const.Skills.Sword] = 80,
	[const.Skills.Spear] = 120,
	[const.Skills.Mace] = 100,
	[const.Skills.Dagger] = 60,
}

weaponImpair =
{
	[const.Skills.Leather]	= {[0]=10, 10, 0, 0, 0,},
	[const.Skills.Chain]	= {[0]=20, 20, 10, 0, 0,},
	[const.Skills.Plate]	= {[0]=20, 20, 10, 10, 0,},
	[const.Skills.Shield]	= {[0]=10, 10, 0, 0, 0,},
}


skillAttack =
{
	[const.Skills.Staff]	= {[0]=0, 1, 2, 2, 2,},
	[const.Skills.Sword]	= {[0]=0, 1, 2, 2, 2,},
	[const.Skills.Dagger]	= {[0]=0, 1, 2, 2, 2,},
	[const.Skills.Axe]		= {[0]=0, 1, 2, 2, 2,},
	[const.Skills.Spear]	= {[0]=0, 1, 2, 2, 3,},
	[const.Skills.Bow]		= {[0]=0, 3, 3, 3, 3,},
	[const.Skills.Mace]		= {[0]=0, 1, 2, 2, 2,},
	[const.Skills.Blaster]	= {[0]=0, 1, 2, 3, 5,},
	[const.Skills.Unarmed]	= {[0]=0, 2, 2, 3, 3,},
}
-- weapon skill recovery bonuses (by rank)

skillRecovery =
{
	[const.Skills.Staff]	= {[0]=0, 0, 0, 0, 0,},
	[const.Skills.Sword]	= {[0]=0, 0, 2, 3, 3,},
	[const.Skills.Dagger]	= {[0]=0, 1, 1, 1, 2,},
	[const.Skills.Axe]		= {[0]=0, 0, 1, 2, 2,},
	[const.Skills.Spear]	= {[0]=0, 0, 0, 0, 0,},
	[const.Skills.Bow]		= {[0]=0, 1, 2, 3, 5,},
	[const.Skills.Mace]		= {[0]=0, 0, 0, 0, 0,},
	[const.Skills.Blaster]	= {[0]=0, 0, 0, 0, 0,},
	[const.Skills.Unarmed]	= {[0]=0, 0, 1, 2, 2,},
}

skillDamage =
{
	[const.Skills.Staff]	= {[0]=0, 2, 3, 3, 4,},
	[const.Skills.Sword]	= {[0]=0, 2, 3, 3, 4,},
	[const.Skills.Dagger]	= {[0]=0, 2, 3, 3, 4,},
	[const.Skills.Axe]		= {[0]=0, 2, 3, 4, 4,},
	[const.Skills.Spear]	= {[0]=0, 1, 2, 3, 3,},
	[const.Skills.Bow]		= {[0]=0, 2, 4, 6, 8,},
	[const.Skills.Mace]		= {[0]=0, 1, 2, 3, 3,},
	[const.Skills.Blaster]	= {[0]=0, 2, 4, 6, 8,},
	[const.Skills.Unarmed]	= {[0]=0, 3, 4, 5, 6,},
}
-- weapon skill AC bonuses (by rank)

skillAC =
{
	[const.Skills.Staff]	= {[0]=0, 1, 2, 3, 4,},
	[const.Skills.Sword]	= {[0]=0, 0, 0, 0, 1,},
	[const.Skills.Dagger]	= {[0]=0, 0, 0, 0, 0,},
	[const.Skills.Axe]		= {[0]=0, 0, 0, 0, 0,},
	[const.Skills.Spear]	= {[0]=0, 1, 2, 3, 4,},
	[const.Skills.Bow]		= {[0]=0, 0, 0, 0, 0,},
	[const.Skills.Mace]		= {[0]=0, 0, 0, 0, 0,},
	[const.Skills.Blaster]	= {[0]=0, 0, 0, 0, 0,},
	[const.Skills.Unarmed]	= {[0]=0, 0, 0, 0, 0,},
	
	--[const.Skills.Shield]	= {[0]=0, 1, 2, 2, 3,},
	--[const.Skills.Leather]	= {[0]=0, 1, 1, 2, 2,},
	--[const.Skills.Chain]	= {[0]=0, 1, 2, 3, 3,},
	--[const.Skills.Plate]	= {[0]=0, 2, 2, 3, 4,},
	[const.Skills.Dodging]	= {[0]=0, 4, 5, 6, 6,},
}
skillResistance =
{
	[const.Skills.Staff]	= {[0]=0, 1, 2, 3, 4},
	[const.Skills.Sword]	= {[0]=0, 0, 0, 0, 0},
	[const.Skills.Dagger]	= {[0]=0, 0, 0, 0, 0},
	[const.Skills.Axe]		= {[0]=0, 0, 0, 0, 0},
	[const.Skills.Spear]	= {[0]=0, 0, 0, 0, 0},
	[const.Skills.Bow]		= {[0]=0, 0, 0, 0, 0},
	[const.Skills.Mace]		= {[0]=0, 0, 0, 0, 0},
	[const.Skills.Blaster]	= {[0]=0, 0, 0, 0, 0},
	[const.Skills.Unarmed]	= {[0]=0, 0, 0, 0, 0,},
	
	--[const.Skills.Leather]	= {[0]=0, 1, 2, 3, 4,},
	--[const.Skills.Chain]	= {[0]=0, 1, 2, 2, 3,},
	--[const.Skills.Plate]	= {[0]=0, 1, 1, 2, 2,},
	--[const.Skills.Shield]	= {[0]=0, 1, 2, 3, 4,},
	[const.Skills.Dodging]	= {[0]=0, 0, 0, 0, 0,},
}
skillItemAC={
	[const.Skills.Leather]	= {[0]=0, 3, 4, 5, 6,},
	[const.Skills.Chain]	= {[0]=0, 3, 4, 5, 6,},
	[const.Skills.Plate]	= {[0]=0, 3, 4, 5, 6,},
	[const.Skills.Shield]	= {[0]=0, 4, 6, 8, 10,},
	[const.Skills.Dodging]	= {[0]=0, 5, 5, 10, 10,},
}
skillItemRes={
	[const.Skills.Leather]	= {[0]=0, 2, 3, 4, 5,},
	[const.Skills.Chain]	= {[0]=0, 1, 2, 3, 4,},
	[const.Skills.Plate]	= {[0]=0, 0, 1, 2, 3,},
	[const.Skills.Shield]	= {[0]=0, 4, 6, 8, 10,},
	[const.Skills.Dodging]	= {[0]=0, 0, 5, 5, 10,},
}
	

twoHandedWeaponDamageBonusByMastery = {
	[0]=0, 
	[const.Novice] = 1, 
	[const.Expert] = 2, 
	[const.Master] = 3, 
	[const.GM] = 4 
}

armsmasterSkill={
	["Damage"]={0.5,1,1.5,2,[0]=0},
	["Speed"]={0,1,2,2,[0]=0},
	["Attack"]={1,1,2,3,[0]=0},
}

--all stats bonus are calculated in Maw Items, as this function only changes hp,sp,ac,attack and damage
function events.CalcStatBonusBySkills(t)
	t.Result=0
end

function getItemRecovery(it, playerLevel)
	local skill=it:T().Skill
	if table.find(twoHandedAxes, it.Number) or table.find(oneHandedAxes, it.Number) then
		skill=3
	end
	local baseSpeed=100
	if table.find(artWeap1h,it.Number) or table.find(artWeap2h,it.Number) then 
		itemLevel=playerLevel
		baseSpeed=baseRecovery[skill] * (0.75+playerLevel/250)
		baseSpeed=round(baseSpeed/10)*10
	elseif baseRecovery[skill] then
		local tot=0
		local lvl=0
		for i=1, 6 do
			tot=tot+it:T().ChanceByLevel[i]
			lvl=lvl+it:T().ChanceByLevel[i]*i
		end
		itemLevel=round(lvl/tot*18-17)+it.MaxCharges*5
		baseSpeed=baseRecovery[skill] * (0.75+itemLevel/250)
		baseSpeed=round(baseSpeed/10)*10
	end
	return baseSpeed
end

function events.GetAttackDelay(t)
	t.Result=100
	baseSpeed=0
	bonusSpeed=0
	count=0
	currentSpeed=0
	
	damageMultiplier=damageMultiplier or {}
	damageMultiplier[t.PlayerIndex]=damageMultiplier[t.PlayerIndex] or {}
	
	if t.Ranged then
		local it=t.Player:GetActiveItem(2)
		if it then
			local skill=it:T().Skill
			if baseRecovery[skill] then
				baseSpeed=getItemRecovery(it, t.Player.LevelBase)
			end
			local s,m = SplitSkill(t.Player:GetSkill(skill))
			if skillRecovery[skill] and skillRecovery[skill][m] then
				bonusSpeed=skillRecovery[skill][m]*s
			end
			if it.Bonus2==41 or it.Bonus2==59 then
				bonusSpeed=bonusSpeed+20
			end
		end
	else
		local speed={}
		for i=0,1 do
			local it=t.Player:GetActiveItem(i)
			if it then
				local skill=it:T().Skill
				if skill==7 then
					t.Result=40
					damageMultiplier[t.PlayerIndex]["Melee"]=0.4
					return
				end
				if skill<8 then
					speed[i]=getItemRecovery(it, t.Player.LevelBase)
					if table.find(twoHandedAxes, it.Number) or table.find(oneHandedAxes, it.Number) then
						skill=3
					end
					local s,m = SplitSkill(t.Player:GetSkill(skill))
					if skillRecovery[skill] and skillRecovery[skill][m] then
						if skill~=3 or i~=0 then
							bonusSpeed=bonusSpeed+skillRecovery[skill][m]*s
						end
					end	
					if it.Bonus2==41 or it.Bonus2==59 then
						bonusSpeed=bonusSpeed+20
					end
					
					--unarmed working with staff GM
					if skill==0 and m==4 then
						local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Unarmed))
						bonusSpeed=bonusSpeed+skillRecovery[const.Skills.Unarmed][m]*s
					end
				end
			elseif i==1 and Game.CharacterPortraits[pl.Face].Race~=const.Race.Dragon then
				local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Unarmed))
				bonusSpeed=bonusSpeed+skillRecovery[const.Skills.Unarmed][m]*s
			end
		end
		local count=0
		for i=0,1 do
			if speed[i] then
				baseSpeed=baseSpeed+speed[i]
				count=count+1
			end
		end
		if count==2 then
			baseSpeed=baseSpeed/2
		end
		
		local s,m = SplitSkill(t.Player:GetSkill(const.Skills.Armsmaster))
		bonusSpeed=bonusSpeed+s*armsmasterSkill.Speed[m]
	end
	if table.find(dkClass, t.Player.Class) then
		local s, m=SplitSkill(t.Player.Skills[const.Skills.Water])
		bonusSpeed=bonusSpeed+s*2
	end
	if baseSpeed==0 then
		baseSpeed=100
	end
	local speed=t.Player:GetSpeed()
	if speed<=21 then
		speedEffect=(speed-13)/4
	else
		speedEffect=math.floor(speed/10)
	end
	bonusSpeed=bonusSpeed+speedEffect
	if t.Player.SpellBuffs[const.PlayerBuff.Haste].ExpireTime>Game.Time or (not vars.MAWSETTINGS.buffRework=="ON" and Party.SpellBuffs[const.PartyBuff.Haste].ExpireTime>Game.Time) then
		bonusSpeed=bonusSpeed+20
	end
	
	if t.Ranged and disableBow then --mostly for tooltip
		baseSpeed=100
		bonusSpeed=0
	end
	
	if t.Ranged then
		damageMultiplier[t.PlayerIndex]["Ranged"]=1*baseSpeed/100
		damageMultiplier[t.PlayerIndex]["bonusSpeedRanged"]=bonusSpeed
		damageMultiplier[t.PlayerIndex]["baseSpeedRanged"]=baseSpeed
	else
		damageMultiplier[t.PlayerIndex]["Melee"]=1*baseSpeed/100
		damageMultiplier[t.PlayerIndex]["bonusSpeedMelee"]=bonusSpeed
		damageMultiplier[t.PlayerIndex]["baseSpeedMelee"]=baseSpeed
	end
	bonusSpeedMult=(100+bonusSpeed)/100
	t.Result=baseSpeed/bonusSpeedMult
	
	--slow depending on item
	delay=0
	local it=t.Player:GetActiveItem(0)
	if it then
		local skill=it:T().Skill
		if weaponImpair[skill] then
			local s,m=SplitSkill(t.Player:GetSkill(skill))
			delay=delay+weaponImpair[skill][m]
		end
	end
	local it=t.Player:GetActiveItem(3)
	if it then
		local skill=it:T().Skill
		if weaponImpair[skill] then
			local s,m=SplitSkill(t.Player:GetSkill(skill))
			delay=delay+weaponImpair[skill][m]
		end
	end
	delayMult=1+delay/100
	t.Result=t.Result*delayMult
	
	if vars.MAWSETTINGS.buffRework=="ON" then
		local hasteMult=1
		if Party.SpellBuffs[8].ExpireTime>=Game.Time then
			local s, m=getBuffSkill(5)
			local s2,m2=getBuffSkill(86)
			s=math.max(s,s2/1.5)
			m=math.max(m,m2)
			hasteMult=math.max(1+buffPower[5].Base[m]/100+buffPower[5].Scaling[m]*s/1000, hasteMult)
		end
		t.Result=t.Result/hasteMult
	end
	
	if t.Ranged and disableBow then --makes melee attack delay instead of bow
		t.Result=t.Player:GetAttackDelay()
	end
end

function calculateAngle(vector1, vector2)
    local dotProduct = vector1.x * vector2.x + vector1.y * vector2.y + vector1.z * vector2.z
    local magnitude1 = math.sqrt(vector1.x^2 + vector1.y^2 + vector1.z^2)
    local magnitude2 = math.sqrt(vector2.x^2 + vector2.y^2 + vector2.z^2)
    
    local cosineTheta = dotProduct / (magnitude1 * magnitude2)
    local angleRadians = math.acos(cosineTheta)
    local angleDegrees = math.deg(angleRadians)
    
    return angleDegrees
end

local function navigateMissile(object)

	-- exclude some special non targeting spells
	if
		-- Meteor Shower
		object.SpellType == 9
		or
		-- Sparks
		object.SpellType == 15
		or
		-- Starburst
		object.SpellType == 22
		or
		-- Poison Spray
		object.SpellType == 24
		or
		-- Ice Blast
		object.SpellType == 32
		or
		-- Shrapmetal
		object.SpellType == 93
	then
		return
	end
	-- object parameters
	local ownerKind = bit.band(object.Owner, 7)
	local targetKind = bit.band(object.Target, 7)
	local targetIndex = bit.rshift(object.Target, 3)
	
	if targetIndex > Map.Monsters.high then
		return
	end
	
	-- current position
	local currentPosition = {["X"] = object.X, ["Y"] = object.Y, ["Z"] = object.Z, }
	
	-- process only missiles between party and monster
	-- target position
	local homingDegree=0.5
	local targetPosition
	if ownerKind == const.ObjectRefKind.Party and targetKind == const.ObjectRefKind.Monster then
		local mapMonster = Map.Monsters[targetIndex]
		-- target only alive monster
		if mapMonster.HitPoints > 0 then
			targetPosition = {["X"] = mapMonster.X, ["Y"] = mapMonster.Y, ["Z"] = mapMonster.Z + mapMonster.BodyHeight * 0.75, }
		else
			return
		end
	-- assume all objects not owned by party and without target are targetting party
	-- this creates issues with cosmetic projectiles like CI Obelisk Arena Paralyze and Gharik/Baa lava fireballs
	elseif ownerKind == const.ObjectRefKind.Monster or ownerKind == 2 then
		local delta_x = Party.X - object.X
		local delta_y = Party.Y - object.Y
		local delta_z = Party.Z - object.Z
		angleDegrees = calculateAngle({ x = delta_x, y = delta_y, z = 0 }, { x = object.VelocityX, y = object.VelocityY, z = 0 })
		if angleDegrees<homingDegree then
			targetPosition = {["X"] = Party.X, ["Y"] = Party.Y, ["Z"] = Party.Z + 120, }
		else
			return
		end
	else
		-- ignore other missiles targetting
		return
	end
	
	-- speed
	local speed = math.sqrt(object.VelocityX * object.VelocityX + object.VelocityY * object.VelocityY + object.VelocityZ * object.VelocityZ)
	
	-- process only objects with non zero speed
	if speed == 0 then
		return
	end
	
	-- direction
	local direction = {["X"] = targetPosition.X - currentPosition.X, ["Y"] = targetPosition.Y - currentPosition.Y, ["Z"] = targetPosition.Z - currentPosition.Z, }
	-- directionLength
	local directionLength = math.sqrt(direction.X * direction.X + direction.Y * direction.Y + direction.Z * direction.Z)
	
	-- normalization koefficient
	local koefficient = speed / directionLength
	
	-- new velocity
	local newVelocity = {["X"] = koefficient * direction.X, ["Y"] = koefficient * direction.Y, ["Z"] = koefficient * direction.Z, }
	
	-- set new velocity
	object.VelocityX = newVelocity.X
	object.VelocityY = newVelocity.Y
	object.VelocityZ = newVelocity.Z
	
end

-- game tick related functionality
function events.Tick()
	-- navigateMissiles
	if vars.MAWSETTINGS.homingProjectiles == "ON" then
		for objectIndex = 0,Map.Objects.high do
			local object =  Map.Objects[objectIndex]
			navigateMissile(object)
		end
	end
end

------------------------
--AUTO GENERATING TOOLTIPS
------------------------
function events.GameInitialized2()
	Skillz.setDesc(6,1,Skillz.getDesc(6,1) .. "\nThe paralyze effect lasts for 5 seconds on regular monsters and 2 seconds on bosses. The stun effect lasts for half the duration of the paralyze effect. The chances of successfully applying these effects depend on the skill level and the monster's level.\n")
	Skillz.setDesc(0,1,Skillz.getDesc(0,1) .. "\nThis skill increases the damage gained from weapon by a percentage when equipping a staff.\nAt Grandmaster can combine staff and unarmed skill, increasing its damage with staff skill at half effect.\n\nEach point of mastery will grant a point to all resistances to ALL party.\n")
	Skillz.setDesc(1,1,Skillz.getDesc(1,1) .. "\nThis skill increases the damage gained from weapon, armsmaster, and special abilities by a percentage when equipping a sword.\n")
	Skillz.setDesc(2,1,Skillz.getDesc(2,1) .. "\nThis skill increases the damage gained from weapon, armsmaster, and special abilities by a percentage when equipping a dagger.\nCrit chance will get lower as monsters grow stronger, up to level 600.")
	Skillz.setDesc(3,1,Skillz.getDesc(3,1) .. "\nThis skill increases the damage gained from weapon, armsmaster, and special abilities by a percentage when equipping an axe.\n")
	Skillz.setDesc(4,1,Skillz.getDesc(4,1) .. "\nThis skill increases the damage gained from weapon, armsmaster, and special abilities by a percentage when equipping a spear.\n")
	Skillz.setDesc(5,1,Skillz.getDesc(5,1) .. "\nThis skill increases the damage gained from weapon, armsmaster, and special abilities by a percentage when equipping a bow.\n")
	Skillz.setDesc(6,1,Skillz.getDesc(6,1) .. "\nThis skill increases the damage gained from weapon, armsmaster, and special abilities by a percentage when equipping a mace.\n")
	for i=0,33 do
		if i<=7 or i==33 then
			attack=false
			recovery=false
			damage=false
			ac=false
			res=false
			baseString=string.format("%s\n------------------------------------------------------------\n",	Skillz.getDesc(i,1))
			for v=1,4 do
				if skillAttack[i][v]~=0 then
					attack=true     
				end
				if skillRecovery[i][v]~=0 then
					recovery=true
				end
				if skillDamage[i][v]~=0 then
					damage=true
				end
				if skillAC[i][v]~=0 then
					ac=true
				end
				if skillResistance[i][v]~=0 then
					res=true
				end
			end
			
			--Novice
			normal=""
			expert=""
			master=""
			gm=""
			local tab=0
			if attack then
				tab=tab+73
				baseString=string.format("%s\t0" .. tab .. "Attack|",baseString)
				normal=string.format("%s\t" .. tab+32 .. "%s|",normal,skillAttack[i][1])
				expert=string.format("%s\t" .. tab+32 .. "%s|",expert,skillAttack[i][2])
				master=string.format("%s\t" .. tab+32 .. "%s|",master,skillAttack[i][3])
				gm=string.format("%s\t" .. tab+32 .. "%s|",gm,skillAttack[i][4])
			end
			if recovery then
				tab=tab+55
				baseString=string.format("%s\t" .. tab .. "Speed|",baseString)
				normal=string.format("%s\t" .. tab+33 .. "%s|",normal,skillRecovery[i][1])
				expert=string.format("%s\t" .. tab+33 .. "%s|",expert,skillRecovery[i][2])
				master=string.format("%s\t" .. tab+33 .. "%s|",master,skillRecovery[i][3])
				gm=string.format("%s\t" .. tab+33 .. "%s|",gm,skillRecovery[i][4])
			end
			if damage and i~=33 then
				tab=tab+55
				baseString=string.format("%s\t" .. tab .. "Dmg%%|",baseString)
				normal=string.format("%s\t" .. tab+22 .. "%s%%|",normal,skillDamage[i][1])
				expert=string.format("%s\t" .. tab+22 .. "%s%%|",expert,skillDamage[i][2])
				master=string.format("%s\t" .. tab+22 .. "%s%%|",master,skillDamage[i][3])
				gm=string.format("%s\t" .. tab+22 .. "%s%%|",gm,skillDamage[i][4])
			else --unarmed
				tab=tab+55
				baseString=string.format("%s\t" .. tab .. "Dmg|",baseString)
				normal=string.format("%s\t" .. tab+22 .. "%s|",normal,skillDamage[i][1])
				expert=string.format("%s\t" .. tab+22 .. "%s|",expert,skillDamage[i][2])
				master=string.format("%s\t" .. tab+22 .. "%s|",master,skillDamage[i][3])
				gm=string.format("%s\t" .. tab+22 .. "%s|",gm,skillDamage[i][4])
			end
			if ac then
				tab=tab+55
				baseString=string.format("%s\t" .. tab .. "AC|",baseString)
				normal=string.format("%s\t" .. tab+9 .. "%s|",normal,skillAC[i][1])
				expert=string.format("%s\t" .. tab+9 .. "%s|",expert,skillAC[i][2])
				master=string.format("%s\t" .. tab+9 .. "%s|",master,skillAC[i][3])
				gm=string.format("%s\t" .. tab+9 .. "%s|",gm,skillAC[i][4])
			end
			if res then
				baseString=string.format("%sRes",baseString)
				normal=string.format("%s\t" .. tab+30 .. "%s",normal,skillResistance[i][1])
				expert=string.format("%s\t" .. tab+30 .. "%s",expert,skillResistance[i][2])
				master=string.format("%s\t" .. tab+30 .. "%s",master,skillResistance[i][3])
				gm=string.format("%s\t" .. tab+30 .. "%s",gm,skillResistance[i][4])
			end
			baseString=baseString .. "\t000"
			Game.SkillDesNormal[i]=normal
			Game.SkillDesExpert[i]=expert
			Game.SkillDesMaster[i]=master
			Game.SkillDesGM[i]=gm
			Skillz.setDesc(i,1,baseString)
		end
	end
end

--now do same for armors
function events.Action(t)
	function events.Tick()
		events.Remove("Tick", 1)
		if Game.CurrentCharScreen==101 and Game.CurrentScreen==7 then
			local i=Game.CurrentPlayer
			if i<0 or i>Party.High then return end
			local pl=Party[i]
			local index=pl:GetIndex()
			itemStats(index)
			--base descriptions
			Skillz.setDesc(8,1,"Shield skill provides great defense against both physical and magical attacks.\n\nShield Skill boosts the AC and Resistances gained from your Shield  by a percent amount.")
			Skillz.setDesc(9,1,"Leather armor is the lightest armor a character can wear.  While leather provides less protection than chain or plate armor, it also slows your character down the least.\n\nLeather Armor Skill boosts the AC and Resistances gained by ALL armors when equipping a Leather Armor by a percent amount.")
			Skillz.setDesc(10,1,"Chain armor is the medium armor type.  It provides more protection than leather and less than plate, but it also slows your character down more than leather.\n\nChain Armor Skill boosts the AC and Resistances gained by ALL armors when equipping a Chain Armor by a percent amount.")
			Skillz.setDesc(11,1,"Plate armor is the heaviest armor type.  It provides the most protection, but it slows your character down more than leather or chain.\n\nPlate Armor Skill boosts the AC and Resistances gained by ALL armors when equipping a Plate Armor by a percent amount.")
			local it=pl:GetActiveItem(3)
			if it then
				local skill=it:T().Skill
				Skillz.setDesc(skill,1,string.format(Skillz.getDesc(skill,1) .. "\n\nCurrent AC from items: " .. StrColor(255,255,100,armorAC) .. "\n"))
				Skillz.setDesc(skill,1,string.format(Skillz.getDesc(skill,1) .. "Bonus AC: " .. StrColor(255,255,100,itemArmorClassBonus1) .. "\n"))
				Skillz.setDesc(skill,1,string.format(Skillz.getDesc(skill,1) .. "Bonus Resistances: " .. StrColor(255,255,100,itemResistanceBonus1) .. "\n"))
			end
			local it=pl:GetActiveItem(0)
			if it then
				local skill=it:T().Skill
				if skill==8 then
					Skillz.setDesc(skill,1,string.format(Skillz.getDesc(skill,1) .. "\n\nBonus AC: " .. StrColor(255,255,100,itemArmorClassBonus2) .. "\n"))
					Skillz.setDesc(skill,1,string.format(Skillz.getDesc(skill,1) .. "Bonus Resistances: " .. StrColor(255,255,100,itemResistanceBonus2) .. "\n"))
				end	
			end
			
			baseString="\n------------------------------------------------------------\n         "
			baseString=string.format("%s\t075AC|",baseString)
			baseString=string.format("%s Res\t000",baseString)
			for i=8,11 do
				Skillz.setDesc(i,1,string.format(Skillz.getDesc(i,1) .. baseString))
			end
		end
	end
end
		
	
function events.GameInitialized2()
	for i=8,32 do
		if i<12 or i==32 then
			recoveryPen=false
			ac=false
			res=false
			baseString=string.format("%s\n------------------------------------------------------------\n         ",	Skillz.getDesc(i,1))
			for v=1,4 do
				if skillItemAC[i][v]~=0 then
					ac=true
				end
				if skillItemRes[i][v]~=0 then
					res=true
				end
			end
			
			--Novice
			normal=""
			expert=""
			master=""
			gm=""
			
			local ac=skillItemAC[i]
			local res=skillItemRes[i]
			if i==32 then
				ac=skillAC[i]
				res=skillResistance[i]
			end
			if ac then
				baseString=string.format("%s\t075AC|",baseString)
				normal=string.format("%s  %s|",normal,ac[1])
				expert=string.format("%s  %s|",expert,ac[2])
				master=string.format("%s  %s|",master,ac[3])
				gm=string.format("%s  %s|",gm,ac[4])
			end
			if res then
				baseString=string.format("%s Res\t000",baseString)
				normal=string.format("%s    %s",normal,res[1])
				expert=string.format("%s    %s",expert,res[2])
				master=string.format("%s    %s",master,res[3])
				gm=string.format("%s    %s",gm,res[4])
			end
			baseString=baseString
			Game.SkillDesNormal[i]=normal
			Game.SkillDesExpert[i]=expert
			Game.SkillDesMaster[i]=master
			Game.SkillDesGM[i]=gm
			Skillz.setDesc(i,1,baseString)
		end
	end
	
	--adjust tooltips with special effects
	Game.SkillDesGM[const.Skills.Axe]=string.format("%s 1%% to halve AC and increases critical strike damage by 3%% per skill point",Game.SkillDesGM[const.Skills.Axe])
	Game.SkillDesMaster[const.Skills.Bow]=string.format("%s 2 arrows",Game.SkillDesMaster[const.Skills.Bow])
	Game.SkillDesGM[const.Skills.Bow]=string.format("%s shoots fire arrows, dealing highest between fire and physical damage",Game.SkillDesGM[const.Skills.Bow])
	Game.SkillDesExpert[const.Skills.Dagger]=string.format("%s can dual wield",Game.SkillDesExpert[const.Skills.Dagger])
	Game.SkillDesMaster[const.Skills.Dagger]=string.format("%s 5+1 crit%%/skill",Game.SkillDesMaster[const.Skills.Dagger])
	Game.SkillDesMaster[const.Skills.Mace]=string.format("%s chance to stun",Game.SkillDesMaster[const.Skills.Mace])
	Game.SkillDesGM[const.Skills.Mace]=string.format("%s chance to paralyze",Game.SkillDesGM[const.Skills.Mace])
	Game.SkillDesMaster[const.Skills.Spear]=string.format("%s can hold with 1 hand",Game.SkillDesMaster[const.Skills.Spear])
	Game.SkillDesMaster[const.Skills.Staff]=string.format("%s 1%% to stun",Game.SkillDesMaster[const.Skills.Staff])
	Game.SkillDesGM[const.Skills.Staff]=string.format("%s usable with Unarm.",Game.SkillDesGM[const.Skills.Staff])
	Game.SkillDesMaster[const.Skills.Sword]=string.format("%s can dual wield",Game.SkillDesMaster[const.Skills.Sword])
	Game.SkillDesExpert[const.Skills.Leather]=string.format("%s recovery penalty eliminated",Game.SkillDesExpert[const.Skills.Leather])
	Game.SkillDesExpert[const.Skills.Chain]=string.format("%s recovery penalty halved",Game.SkillDesExpert[const.Skills.Chain])
	Game.SkillDesMaster[const.Skills.Chain]=string.format("%s recovery penalty eliminated",Game.SkillDesMaster[const.Skills.Chain])
	Game.SkillDesExpert[const.Skills.Plate]=string.format("%s rec. pen. halved",Game.SkillDesExpert[const.Skills.Plate])
	Game.SkillDesGM[const.Skills.Plate]=string.format("%s rec. pen. elim.",Game.SkillDesGM[const.Skills.Plate])
	Game.SkillDesExpert[const.Skills.Shield]=string.format("%s recovery penalty eliminated",Game.SkillDesExpert[const.Skills.Shield])
	Game.SkillDesGM[const.Skills.Shield]=string.format("%s 15%% Magic damage reduction",Game.SkillDesGM[const.Skills.Shield])
	Game.SkillDesNormal[const.Skills.Armsmaster]=string.format("Skills adds " .. armsmasterSkill.Damage[1] .. " dmg and " .. armsmasterSkill.Attack[1] .. " atk")
	Game.SkillDesExpert[const.Skills.Armsmaster]=string.format("Skills adds " .. armsmasterSkill.Damage[2] .. " dmg, " .. armsmasterSkill.Attack[2] .. " atk, " .. armsmasterSkill.Speed[2] .. "%% speed")
	Game.SkillDesMaster[const.Skills.Armsmaster]=string.format("Skills adds " .. armsmasterSkill.Damage[3] .. " dmg, " .. armsmasterSkill.Attack[3] .. " atk, " .. armsmasterSkill.Speed[3] .. "%% speed")
	Game.SkillDesGM[const.Skills.Armsmaster]=string.format("Skills adds " .. armsmasterSkill.Damage[4] .. " dmg, " .. armsmasterSkill.Damage[4] .. " atk, " .. armsmasterSkill.Speed[4] .. "%% speed")
	Game.SkillDesMaster[const.Skills.Dodging]=string.format("%s usable with Leather Armor",Game.SkillDesGM[const.Skills.Dodging])
	Game.SkillDesGM[const.Skills.Dodging]=string.format("%s 0.5%% dodge chance",Game.SkillDesGM[const.Skills.Dodging])
	--Game.SkillDesGM[const.Skills.Unarmed]=string.format("%s 0.5%% dodge chance",Game.SkillDesGM[const.Skills.Unarmed])	
	Skillz.setDesc(35,1,"Armsmaster skill represents the warrior's tricks of the trade, enhancing your proficiency with all weapons-except staves.\nThis skill allows you to strike faster, execute smoother attacks, and deal more powerful blows.\n\nDamage added by armsmaster skill scales with your weapon skill, amplifying its impact as you grow more adept.\n")
	baseSpearTooltip=Game.SkillDesGM[const.Skills.Spear]
	maceGMtxt=Game.SkillDesGM[6] --used for mace tooltip
end

---------------------------------------
-- MMMERGE ONLINE SOLO PLAYER SKILLS --
---------------------------------------

--get distance function
function getDistance(x,y,z)
	distance=((Party.X-x)^2+(Party.Y-y)^2+(Party.Z-z)^2)^0.5
	return distance
end
-------------------------------------------------
--charge skill (usable only in single player)
-------------------------------------------------
function events.KeyDown(t)
	if Party.High~=0 then return end --only in single player
	if Game.CurrentScreen==21 then return end
	if t.Key == chargeKey then
		local class=Party[0].Class
		if class>=16 and class<=19 then
			if vars.chargeCooldown==0 then
				if Mouse:GetTarget().Kind==3 then
					index=Mouse:GetTarget().Index
					local mon=Map.Monsters[index]
					local chargeX=mon.X
					local chargeY=mon.Y
					local chargeZ=mon.Z
					local dist=getDistance(chargeX,chargeY,chargeZ)
					if dist<3000 and dist>500 then
						charge=true
						ticks=20
						--get distance to cover
						distanceX=Party.X-chargeX
						distanceY=Party.Y-chargeY
						distanceZ=Party.Z-chargeZ
						vars.chargeCooldown=25
						evt.FaceExpression{Player = "All", Frame = 46}
						Game.ShowStatusText(string.format("%s casts Charge stunning the enemy",Party[0].Name))
						mon.SpellBuffs[6].Skill=4
						if class==16 then
							duration=const.Minute*1.5
							mon.SpellBuffs[6].ExpireTime=Game.Time+duration
						elseif class==17 then
							duration=const.Minute*2
							mon.SpellBuffs[6].ExpireTime=Game.Time+duration
						else
							duration=const.Minute*2.5
							mon.SpellBuffs[6].ExpireTime=Game.Time+duration
						end
						local vel=mon.Velocity
						mon.Velocity=0
						mon.Active = false
						Sleep(duration)
						mon.Velocity=vel
					else
						Game.ShowStatusText("Out of range")
					end
				end
			else
				Game.ShowStatusText(string.format("Charge has %s seconds of cooldown",vars.chargeCooldown))
			end
		end
	end
end

--
function events.LoadMap(wasInGame)
	checkCharge=180
	vars.chargeCooldown=vars.chargeCooldown or 25
	lastCharge=vars.chargeCooldown
	charge=false
	Timer(chargeTimer, const.Minute/2) 
end
function chargeTimer() 
		if vars.chargeCooldown>0 then
			vars.chargeCooldown=vars.chargeCooldown-1
		end
	end
--movement
function events.Tick()
	if Multiplayer and Multiplayer.client_monsters()[0] and checkCharge and checkCharge>=0 then
		--check for charge working
		checkCharge=checkCharge-1
	end
	if checkCharge==0 and lastCharge==vars.chargeCooldown then
		Timer(chargeTimer, const.Minute/2) 
	end
	if charge~=true then return end --return if charge event is off
	--get closer to Monster
	Party.X=Party.X-distanceX/22
	Party.Y=Party.Y-distanceY/22
	Party.Z=Party.Z-distanceZ/22
	ticks=ticks-1
	if ticks==0 then
		charge=false
	end
end

--------------------------------------
--HEALTH potion drink hotkey only in SOLO
--------------------------------------
function events.KeyDown(t)
	if Party.High~=0 then return end --only in single player
	if Game.CurrentScreen==21 then return end
	if t.Key == healthPotionKey then
		if vars.healthPotionCooldown==0 then
			local heal=false
			local bonus=0
			for i=1, Party[0].Items.High do
				if Party[0].Items[i].Number==222 and Party[0].Items[i].Bonus>=bonus then
					heal=true
					index=i
					bonus=Party[0].Items[i].Bonus
				end
			end
			if heal then
				Party[0].Items[index].Number=0
				local healAmount=round(bonus^1.4)+10
				evt.Add("HP",healAmount)
				vars.healthPotionCooldown=15
				Game.ShowStatusText(string.format("Health Potion heals for %s hit points",healAmount))
			end
		else
			Game.ShowStatusText(string.format("Health Potion has %s seconds of cooldown remaining",vars.healthPotionCooldown))
		end
	end
end

function events.LoadMap(wasInGame)
	vars.healthPotionCooldown=vars.healthPotionCooldown or 15
	charge=false
	local function chargeTimer() 
		if vars.healthPotionCooldown>0 then
			vars.healthPotionCooldown=vars.healthPotionCooldown-1
		end
	end
	Timer(chargeTimer, const.Minute/2) 
end


--------------------------------------
--MANA potion drink hotkey only in SOLO
--------------------------------------
function events.KeyDown(t)
	if Party.High~=0 then return end --only in single player
	if Game.CurrentScreen==21 then return end
	if t.Key == manaPotionKey then
		if vars.manaPotionCooldown==0 then
			local heal=false
			local bonus=0
			for i=1, Party[0].Items.High do
				if Party[0].Items[i].Number==223 and Party[0].Items[i].Bonus>=bonus then
					heal=true
					index=i
					bonus=Party[0].Items[i].Bonus
				end
			end
			if heal then
				Party[0].Items[index].Number=0
				local spAmount=round(bonus^1.4*2/3)+10
				evt.Add("SP",20+bonus*2)
				vars.manaPotionCooldown=15
				Game.ShowStatusText(string.format("Mana Potion restores %s mana",spAmount))
			end
		else
			Game.ShowStatusText(string.format("Mana Potion has %s seconds of cooldown remaining",vars.manaPotionCooldown))
		end
	end
end

function events.LoadMap(wasInGame)
	vars.manaPotionCooldown=vars.manaPotionCooldown or 15
	charge=false
	local function chargeTimer() 
		if vars.manaPotionCooldown>0 then
			vars.manaPotionCooldown=vars.manaPotionCooldown-1
		end
	end
	Timer(chargeTimer, const.Minute/2) 
end


--function that checks for enchant that increases skill 
function checkbonus(enchantNumber, playerIndex)
	local skillBonus=0
	for it in Party[playerIndex]:EnumActiveItems() do
		if it.Bonus==enchantNumber and it.BonusStrength>skillBonus then
			skillBonus=it.BonusStrength
		end
	end
	return skillBonus
end

sharedSkills={0,1,2,3,4,5,6,7,12,13,14,15,16,17,18,19,20,21,22}
function events.Action(t)
	if t.Action==121 then
		vars.checkSoloMastery=true --makes skills to be automatically learned if solo
		local shared=sharedSkills
		if table.find(shamanClass, pl.Class) or table.find(seraphClass, pl.Class) or table.find(dkClass, pl.Class) then
			shared={12,13,14,15,16,17,18,19,20,21,22}
		end
		if table.find(shared, t.Param) then
			t.Handled=false
			pl=Party[Game.CurrentPlayer]
			local currentCost=SplitSkill(pl.Skills[t.Param])+1
			if currentCost>1000 then
				return
			end
			--calculate actual cost
			local n=1
			for i=1,#shared do
				local s,m=SplitSkill(Party[Game.CurrentPlayer].Skills[shared[i]])
				if s>=currentCost then
					n=n+1
				end
			end
			local actualCost=math.ceil(currentCost/n)
			if pl.SkillPoints>=actualCost then
				pl.SkillPoints=pl.SkillPoints+currentCost-actualCost
			end
		end
		--[[  skill share system, disabled, fix at the bottom
		if table.find(partySharedSkills,t.Param) then
			maxS=0
			maxM=0
			increased=-1
			for i=0,Party.High do
				skill=partySharedSkills[table.find(partySharedSkills,t.Param)]
				s,m=SplitSkill(Party[i].Skills[skill])
				if Game.CurrentPlayer==i then
					if Party[i].SkillPoints>s and (s<10 or m~=4) then
						s=s+1
						increased=i
					end
				end
				if s>maxS then
					maxS=s
				end
				if m>maxM then
					maxM=m
				end
			end
			for i=0,Party.High do
				if increased==i then
					Party[i].Skills[skill]=JoinSkill(maxS-1,maxM)
				else
					Party[i].Skills[skill]=JoinSkill(maxS,maxM)
				end
			end
			if maxS>=10 and maxM==4 then
				t.Handled=true
				Game.ShowStatusText("This skill is already as good as it will ever get")
			end
		end
		]]
	end
end
function events.LoadMap()
	if not vars.weaponSkillRefunded then
		vars.weaponSkillRefunded=true
		for i=0, Party.High do
			local p=Party[i]
			if table.find(shamanClass, p.Class) or table.find(seraphClass, p.Class) or table.find(dkClass, p.Class) then
				goto continue
			end
			refund1=0
			refund2=0
			for id=1,#sharedSkills do
				local skill,mastery=p.Skills[sharedSkills[id]]
				oldSkill=oldSkill or {}
				oldSkill[sharedSkills[id]]=skill
			end
			--reset mastery
			for i=1,#sharedSkills do
				p.Skills[sharedSkills[i]]=SplitSkill(p.Skills[sharedSkills[i]])
			end	
			for id=1,#sharedSkills do
				local skill=SplitSkill(p.Skills[sharedSkills[id]])
				if sharedSkills[id]>=12 and sharedSkills[id]<=22 then
					local lastSkill=2
					while lastSkill>1 do
						maxSkill=0
						count=1	
						for v=12,22 do
							if p.Skills[v]>maxSkill then
								maxSkill = p.Skills[v]
								maxIndex=v
								count=1
							elseif p.Skills[v]==maxSkill then
								count=count+1
							end
						end
						lastSkill=maxSkill
						if lastSkill>1 then
							refund1=refund1+math.ceil(maxSkill/count)
							p.Skills[maxIndex]=p.Skills[maxIndex]-1
						end
					end
				else
					refund1=refund1+math.max(skill*(skill+1)/2-1,0)
				end
			end
			for id=1,#sharedSkills do
				p.Skills[sharedSkills[id]]=oldSkill[sharedSkills[id]]
			end
			--reset mastery
			for i=1,#sharedSkills do
				p.Skills[sharedSkills[i]]=SplitSkill(p.Skills[sharedSkills[i]])
			end	
			--now do again with rework and calculate difference
			for id=1,#sharedSkills do
				local skill=SplitSkill(p.Skills[sharedSkills[id]])
				local lastSkill=2
				while lastSkill>1 do
					maxSkill=0
					count=1	
					for v=1,#sharedSkills do
						if p.Skills[sharedSkills[v]]>maxSkill then
							maxSkill = p.Skills[sharedSkills[v]]
							maxIndex=sharedSkills[v]
							count=1
						elseif p.Skills[sharedSkills[v]]==maxSkill then
							count=count+1
						end
					end
					lastSkill=maxSkill
					if lastSkill>1 then
						refund2=refund2+math.ceil(maxSkill/count)
						p.Skills[maxIndex]=p.Skills[maxIndex]-1
					end
				end
			end
			for id=1,#sharedSkills do
				p.Skills[sharedSkills[id]]=oldSkill[sharedSkills[id]]
			end
			p.SkillPoints=p.SkillPoints+(refund1-refund2)
			::continue::
		end
	end
end

--plate&shield cover
--change target
function events.PlayerAttacked(t)
	if t.Attacker and t.Attacker.Monster then
		local masteryRequired=0
		if (t.Attacker.MonsterAction==0 or t.Attacker.MonsterAction==1) and t.Attacker.Monster["Attack" .. t.Attacker.MonsterAction+1].Type==4 then
			masteryRequired=1
		elseif t.Attacker.MonsterAction==2 then
			masteryRequired=3
		else
			masteryRequired=2
		end
		if not vars.covering then
			vars.covering={}
			for i=0,4 do
				vars.covering[i]=true
			end
		end
		
		local skill = string.match(Game.PlaceMonTxt[t.Attacker.Monster.NameId], "([^%s]+)")
		if skill=="Fixator" then
			local lowestHPId=-1
			local lowestHP=math.huge
			for i=0,Party.High do
				local totHP=Party[i]:GetFullHP()
				if Party[i]:IsConscious() and totHP<lowestHP then
					lowestHP=totHP
					lowestHPId=i
				end
			end
			t.PlayerSlot=lowestHPId
			return
		end
		cover={}
		for i=0,Party.High do
			local s, m= SplitSkill(Skillz.get(Party[i], 50))
			if s>0 and vars.covering[i] and m>=masteryRequired and i~=t.PlayerSlot then
				cover[i]={["Chance"]=math.min(0.1+s*0.01,40),["Mastery"]= m}
				if coverBonus[i] then
					cover[i].Chance=cover[i].Chance+0.15
					coverBonus[i]=false
				end
			else
				cover[i]=false
			end
		end
		--roll once per player with player and pick the one with max hp
		coverPlayerIndex=-1
		lastMaxHp=0
		covered=false
		for i=0,#cover-1 do
			if cover[i] then
				local hp=Party[i].HP
				if cover[i].Chance>math.random() and hp>lastMaxHp then
					lastMaxHp=hp
					coverPlayerIndex=i
					covered=true
				end
			end
		end
		if covered then
			mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, mem.u4[0x75CE00]), const.Spells.Shield, t.PlayerSlot)
			Party[coverPlayerIndex]:ShowFaceAnimation(14)
			--Game.ShowStatusText(Party[coverPlayerIndex].Name .. " cover " .. Party[t.PlayerSlot].Name)
			t.PlayerSlot=coverPlayerIndex
			local pl=Party[t.PlayerSlot]
			local id=pl:GetIndex()
			if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 23) then
				evt[t.PlayerSlot].Add("HP", Party[t.PlayerSlot]:GetFullHP()*0.03)
			end
			--retaliation code
			local s,m=Skillz.get(pl,53)
			if s/100>=math.random() then
				vars.retaliation=vars.retaliation or {}
				vars.retaliation[id]=vars.retaliation[id] or {}
				vars.retaliation[id]["Stacks"]=vars.retaliation[id]["Stacks"] or 0
				vars.retaliation[id]["Time"]=Game.Time
				vars.retaliation[id]["Stacks"]=vars.retaliation[id]["Stacks"]+1
				local cap=1
				if m==4 then
					cap=3
				end
				vars.retaliation[id]["Stacks"]=math.min(vars.retaliation[id]["Stacks"],cap)
			end	
		end
	end
end

--AUTOREPAIR
function events.Regeneration(t)
	repair=0
	for i=0,Party.High do
		v=Party[i]
		ko = v.Eradicated or v.Dead or v.Stoned or v.Paralyzed or v.Unconscious or v.Asleep
		r,m = SplitSkill(v:GetSkill(const.Skills.Repair))
		if r*m>repair and (ko == 0) then
			repair=r*m
		end
	end
	v=t.Player.Items
	for k=1, v.High do
		if v[k].Broken == true then
			if v[k]:T().IdRepSt<=repair then
				v[k].Broken = false
				Game.ShowStatusText("Repaired")
			end
		end
	end
end

--MAW REGEN, once every 0.1 seconds
regenHP={0,0,0,0,[0]=0}
regenSP={0,0,0,0,[0]=0}
lastHP={}
lastSP={}
waitHP={}
waitSP={}
local classesWithNoMeditationRegen={10,11,56,57,58}

function getBuffHealthRegen(pl)
	local regen=0
	local FHP = pl:GetFullHP()
	
	--regeneration skill
	local RegS, RegM = SplitSkill(pl:GetSkill(const.Skills.Regeneration))
	local regenEffect={[0]=0,2,4,6,6}
	FHP	= pl:GetFullHP()
	regen=regen + FHP^0.5*RegS^1.65*(regenEffect[RegM]/350)+RegS
	for it in pl:EnumActiveItems() do
		if it.Bonus2 == 37 or it.Bonus2==44 or it.Bonus2==50 or it.Bonus2==54 or it.Bonus2==66 or table.find(artifactHpRegen, it.Number) then		
			regen=regen+FHP*0.02/10	
		end
	end
	
	local Buff=pl.SpellBuffs[const.PlayerBuff.Regeneration]
	if vars.MAWSETTINGS.buffRework=="ON" then 
		if pl.SpellBuffs[12].ExpireTime>=Game.Time then
			-- buff
			local s,m,level=getBuffSkill(71)
			local skill=(level)^0.65*(1+s*buffPower[71].Base[m]/100)
			local regen1 = FHP^0.5*skill^1.25*(buffPower[71].Base[m]/1000)
			--potion
			RegS, RegM = SplitSkill(Buff.Skill)
			local regen2 = FHP^0.5*RegS^1.25*((RegM+1)/1000)
			
			regen=regen+math.max(regen1, regen2)
		end
	elseif Buff.ExpireTime > Game.Time then
		RegS, RegM = SplitSkill(Buff.Skill)
		regen = regen+FHP^0.5*RegS^1.25*((RegM+1)/1000)
	end
	return regen
end

function MawRegen()
	--HP
	vars.lastRegenTime=vars.lastRegenTime or Game.Time
	timePassed=Game.Time-vars.lastRegenTime
	vars.lastRegenTime=Game.Time
	--call is 20 times per minute, which is 12.8 
	local timeMultiplier=(Game.TurnBased and timePassed/12.8) or 1
	if getMapAffixPower(22) then
		timeMultiplier=timeMultiplier*(1-getMapAffixPower(22)/100)
	end
	for i=0,Party.High do
		pl=Party[i]
		local Cond = pl:GetMainCondition()
		if Cond == 18 or Cond == 17 or Cond < 14 then
			lastHP[i]=lastHP[i] or pl.HP
			waitHP[i]=waitHP[i] or 0
			mult=1
			if lastHP[i]>pl.HP then
				waitHP[i]=200
			elseif waitHP[i]>0 then
				waitHP[i]=waitHP[i]-timeMultiplier
			else
				mult=2
			end
			if (not Party.EnemyDetectorYellow and not Party.EnemyDetectorRed) then
				mult=mult*4
			end
		
			local regen=getBuffHealthRegen(pl)/10 * timeMultiplier * mult --/10 because it's called 10 times per second
			regenHP[i] = regenHP[i] + regen
			local FHP=pl:GetFullHP()
			--recount
			local id=pl:GetIndex()
			local healingDone=math.min(FHP-pl.HP, math.floor(regenHP[i]))
			if healingDone>0 and (Party.EnemyDetectorRed or Party.EnemyDetectorYellow) then
				vars.regenerationHeal=vars.regenerationHeal or {}
				vars.regenerationHeal[id]=vars.regenerationHeal[id] or 0
				vars.regenerationHeal[id]=vars.regenerationHeal[id] + healingDone
				mapvars.regenerationHeal=mapvars.regenerationHeal or {}
				mapvars.regenerationHeal[id]=mapvars.regenerationHeal[id] or 0
				mapvars.regenerationHeal[id]=mapvars.regenerationHeal[id] + healingDone
			end
			--actual heal
			pl.HP = math.min(FHP, pl.HP + math.floor(regenHP[i]))
			if pl.HP>0 then
				pl.Unconscious=0
			end
			regenHP[i]=regenHP[i]%1
			lastHP[i]=pl.HP
		end
	end
	--SP
	for i=0,Party.High do
		pl=Party[i]
		local Cond = pl:GetMainCondition()
		if (Cond == 18 or Cond == 17 or Cond < 14) and pl.Insane==0 and (not vars.MAWSETTINGS.buffRework=="ON" or (vars.currentManaPool and type(vars.currentManaPool[i])=="number")) then
			lastSP[i]=lastSP[i] or pl.SP
			waitSP[i]=waitSP[i] or 0
			mult=1
			if lastSP[i]>pl.SP then
				waitSP[i]=200
			elseif waitSP[i]>0 then
				waitSP[i]=waitSP[i]-timeMultiplier
			else
				mult=2
			end
			if (not Party.EnemyDetectorYellow and not Party.EnemyDetectorRed) then
				mult=mult*4
			end
			local RegS, RegM = SplitSkill(pl:GetSkill(const.Skills.Meditation))
			if RegM==4 then
				RegM=8
			end
			FSP	= pl:GetFullSP()
			if FSP>0 and vars.MAWSETTINGS.buffRework=="ON" and vars.currentManaPool and vars.currentManaPool[i] then
				FSP=math.max(math.ceil(FSP*(vars.currentManaPool[i]/FSP)^0.5),0)
				
			end
			
			local SPREGEN = (FSP^0.25*RegS^1.4*((RegM+5)/5000) +0.02)
			
			for it in pl:EnumActiveItems() do
				--[[special enchants now increase meditation
				if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 or it.Bonus2==66 or table.find(artifactSpRegen, it.Number) then	
					SPREGEN=SPREGEN+FSP*0.02/100
				end
				]]
				if table.find(artifactSpRegen, it.Number) then	
					SPREGEN=SPREGEN+FSP*0.02/100
				end
			end
			
			regenSP[i] = regenSP[i] + SPREGEN * timeMultiplier*mult
			--meditation buff
			if vars.MAWSETTINGS.buffRework=="ON" and vars.mawbuff[56] and not table.find(classesWithNoMeditationRegen, pl.Class) then
				local s, m, level=getBuffSkill(56)
				local level=level^0.6
				regenSP[i] = regenSP[i] + (FSP^0.25*level^1.4*((buffPower[56].Base[m])/15000) +0.1)* timeMultiplier*mult*(1+buffPower[56].Scaling[m]/100*s)
			end
			--dragon regen
			if pl.Class==10 then
				regenSP[i]=regenSP[i] + 0.2* timeMultiplier*mult
			elseif pl.Class==11 then
				regenSP[i]=regenSP[i] + 0.5* timeMultiplier*mult
			end
			pl.SP = math.min(vars.currentManaPool[i], pl.SP + math.floor(regenSP[i]))
			regenSP[i]=regenSP[i]%1
			lastSP[i]=pl.SP
		end
	end
end
function events.LoadMap(wasInGame)
	Timer(MawRegen, const.Minute/20) 
end



--DINAMIC SKILL TOOLTIP
function events.GameInitialized2()
	baseRegStr=	Skillz.getDesc(30,1)
	baseMedStr=	Skillz.getDesc(28,1)
	
end
function events.Tick()
	if Game.CurrentCharScreen==101 and Game.CurrentScreen==7 then
		--regeneration tooltip
		if Game.CurrentPlayer<0 or Game.CurrentPlayer>Party.High then return end
		pl=Party[Game.CurrentPlayer]
		local FHP=pl:GetFullHP()
		local s,m = SplitSkill(pl:GetSkill(30))
		local regenEffect={[0]=0,2,4,6,6}
		local hpRegen = round(FHP^0.5*s^1.65*((regenEffect[m])/35))/10+s
		local hpRegen2 = round(FHP^0.5*(s+1)^1.65*((regenEffect[m])/35))/10+(s+1)
		local txt = string.format("%s\n\nCurrent HP Regeneration: %s\nNext Level Bonus: %s HP Regen",baseRegStr,StrColor(0,255,0,hpRegen),StrColor(0,255,0,"+" .. hpRegen2-hpRegen))
		Skillz.setDesc(30,1,txt)
		--meditation tooltip
		local FSP=pl:GetFullSP()
		if vars.MAWSETTINGS.buffRework=="ON" and vars.currentManaPool and vars.currentManaPool[i] then
			FSP=vars.currentManaPool[Game.CurrentPlayer]
		end
		local s,m = SplitSkill(pl:GetSkill(28))
		if m==4 then
			m=8
		end
		local spRegen = (FSP^0.25*s^1.4*((m+5)/50)+2)/10
		local spRegen2 = (FSP^0.25*(s+1)^1.4*((m+5)/50)+2)/10
		local spRegen2 = round((spRegen2-spRegen)*100)/100
		if spRegen>10 then
			spRegen = round((spRegen)*10)/10
		else
			spRegen = round((spRegen)*100)/100
		end
		txt= string.format("%s\n\nIncreases spell points based on SP per level and mastery\n\nCurrent SP Regeneration: %s\nNext Level Bonus: %s SP Regen\n",baseMedStr,StrColor(60,60,255,spRegen),StrColor(60,60,255,"+" .. spRegen2))
		Skillz.setDesc(28,1,txt)
		
		--spear tooltip
		local s,m=SplitSkill(pl:GetSkill(const.Skills.Spear))
		local mult=damageMultiplier[pl:GetIndex()]["Melee"]
		local damageIncrease=round((2+s*0.02)*mult*10)/10
		Game.SkillDesGM[const.Skills.Spear]=string.format("%s\n\t070Each spear attack reduces physical resistance, increasing damage by: %s%%",baseSpearTooltip,damageIncrease)
	end
end

function events.LoadMap()
	if vars.hirelingFix then
		vars.hirelingFix=false
		for i=0,Party.PlayersArray.High do
			pl=Party.PlayersArray[i]
			for v=0,38 do 
				if pl.Skills[v]>4864 then --2^12+2^8*3 no idea why
					pl.Skills[v]=pl.Skills[v]-3840 --1024*3+2^8*3 no idea why
					
				end	
			end
			--[[ no longer needed, changed skill sharing system
			extraSkillPoints=0
			for j=1,5 do
				s=SplitSkill(pl.Skills[partySharedSkills[j] ])
				if s>1 then
					extraSkillPoints=extraSkillPoints+(s*(s+1)/2-1)
					pl.Skills[partySharedSkills[j] ]=1
				end
			end	
			pl.SkillPoints=pl.SkillPoints+extraSkillPoints
			]]
		end
	end
end

--ASCENDANCE
--learning bonus removed and replaced with ascendance
function events.GetLearningTotalSkill(t)
	t.Result=0
end

--retroactive fix
function events.LoadMap()
	vars.learningFix=vars.learningFix or {}
	for i=0,Party.PlayersArray.High do
		pl=Party.PlayersArray[i]
		local id=pl:GetIndex()
		if vars.learningFix[id] then 
			return 
		end 
		local s, m = SplitSkill(pl.Skills[const.Skills.Learning])
		while s>1 do
			pl.SkillPoints=pl.SkillPoints+s
			s=s-1
		end
		pl.Skills[const.Skills.Learning]=0
		vars.learningFix[id]=true
	end
end

function events.GameInitialized2()
	local txt="Increases spell damage at the expense of higher mana. Each skill level boosts the corresponding tier's spells, up to Tier 11 (e.g., Incinerate, Starburst). Spells can be ascended seven times, culminating at skill level 77. This skill affects all magic schools, enabling up to three enhancements per spell (ascended damage amount shown in spell tooltip). \n\nLevel up to unlock the full destructive or healing potential of your magic, balancing higher damage with greater mana expenditure.\n\nEach ascension tier increases cast time.\n"
	Skillz.setDesc(const.Skills.Learning,1,txt)
	Skillz.setName(const.Skills.Learning, "Ascension")
	Game.SkillDesNormal[const.Skills.Learning]= "Mana cost reduced by 12.5%."
	Game.SkillDesExpert[const.Skills.Learning]= "Mana cost reduced by 25%"
	Game.SkillDesMaster[const.Skills.Learning]= "Mana cost reduced by 37.5%"
	Game.SkillDesGM[const.Skills.Learning]= "Mana cost reduced by 50%"
	
	Game.SkillDesNormal[const.Skills.Perception]= "Reduces traps and lava damage by 10%."
	Game.SkillDesExpert[const.Skills.Perception]= "Reduces traps and lava damage by 30%."
	Game.SkillDesMaster[const.Skills.Perception]= "Reduces traps and lava damage by 50%."
	Game.SkillDesGM[const.Skills.Perception]= "Reduces traps and lava damage by 70%."
end


--open time at 5 instead of 6
function events.GameInitialized2()
	baseOpenTimes={}
	baseCloseTimes={}
	for i =0,Game.Houses.High do
		if Game.Houses[i].OpenHour==6 then
			Game.Houses[i].OpenHour=5
		end
		baseOpenTimes[i]=Game.Houses[i].OpenHour
		baseCloseTimes[i]=Game.Houses[i].CloseHour
	end
end
--challenge mode always open
function events.LoadMap()
	if vars.ChallengeMode then
		for i =0,Game.Houses.High do
			Game.Houses[i].OpenHour=0
			Game.Houses[i].CloseHour=0
		end
		Game.NPC[1177].EventB=0
	else
		for i =0,Game.Houses.High do
			Game.Houses[i].OpenHour=baseOpenTimes[i]
			Game.Houses[i].CloseHour=baseCloseTimes[i]
		end
		Game.NPC[1177].EventB=1418
	end
end
--training centers bolster

function events.CalcTrainingTime(t)
	if Game.CurrentPlayer==0 then
		vars.trainings=vars.trainings or {0,0,0}
		currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
		vars.trainings[currentWorld]=vars.trainings[currentWorld]+1
	end	
	--reduced training time
	t.Time=const.Day*2
	if vars.ChallengeMode then
		t.Time=0
	end
end
local trainingCenters={
	[1]={1,2,3,4,5,6},
	[2]={7,8,9,10,11,12,13,14,15,16},
	[3]={20,21,22,23,24,25,26,27,28,29}
}
function events.GameInitialized2()
	baseTrainers={}
	for i=1,29 do
		baseTrainers[i]=Game.HouseRules.Training[i].Quality
		if baseTrainers[i]==-1 then
			baseTrainers[i]=3000
		end
		baseTrainers[i]=math.max(baseTrainers[i], 10)
	end
end

function events.Action(t)
	if vars.insanityMode then
		function events.Tick()
			events.Remove("Tick",1)
			if Game:GetCurrentHouse() then
				local house=Game.Houses[Game:GetCurrentHouse()]
				if house.Type==30 then
					local id=Game.CurrentPlayer
					if id>=0 and id<=Party.High then
						local lvl=Party[id].LevelBase
						house.Val=round(lvl^0.7)+4
					end
				end
			end
		end
	end
end

function events.LoadMap()
	local currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	if currentWorld==4 then return end
	local bolster=0
	vars.trainings=vars.trainings or {vars.MM8LVL,vars.MM7LVL,vars.MM6LVL}
	for i=1,3 do 
		if i~=currentWorld then
			bolster=bolster+vars.trainings[i]
		end
	end
	for i=1,#trainingCenters[currentWorld] do
		Game.HouseRules.Training[trainingCenters[currentWorld][i]].Quality=math.min(baseTrainers[trainingCenters[currentWorld][i]]+bolster+5,3000)
	end
end

--minotaurs equipping axes offhand
--[[requires master for 2h axes, expert for 1h axes (so I expect people starting with 2h axes, then 2h axes+single axe, then double 2h axes.
function events.Action(t)
	if t.Action==133 then
		local pl=Party[Game.CurrentPlayer]
		local race=Game.CharacterPortraits[Party[Game.CurrentPlayer].Face].Race
		if race==const.Race.Minotaur then
			local it=Mouse.Item
			local txt=it:T()
			if txt.Skill==const.Skills.Axe then
				local s,m = SplitSkill(pl.Skills[const.Skills.Axe])
				if m<2 then return end --requires expert axe
				if txt.EquipStat==0 then
					local s,m = SplitSkill(pl.Skills[const.Skills.Dagger])
					if m<2 then
						pl.Skills[const.Skills.Dagger]=JoinSkill(s,2)
					end
					txt.Skill=2
					function events.Tick() 
						events.Remove("Tick", 1)
						txt.Skill=3
					end
				elseif txt.EquipStat==1 and m>=3 then
					local s,m = SplitSkill(pl.Skills[const.Skills.Dagger])
					if m<2 then
						pl.Skills[const.Skills.Dagger]=JoinSkill(s,2)
					end
					txt.Skill=2
					txt.EquipStat=0
					function events.Tick() 
						events.Remove("Tick", 1)
						txt.Skill=3
						txt.EquipStat=1
					end
				end
			end
		end
	end
end
]]
function events.Tick()
	if Game.CurrentScreen==7 or Game.CurrentScreen==15 then
		if Game.CurrentPlayer<0 or Game.CurrentPlayer>Party.High then return end
		local pl=Party[Game.CurrentPlayer]
		local race=Game.CharacterPortraits[Party[Game.CurrentPlayer].Face].Race
		if race==const.Race.Minotaur and (pl.Class<34 or pl.Class>37) then
			local s,m = SplitSkill(pl.Skills[3])
			if m>=2 then
				for i=1,#oneHandedAxes do
					txt=Game.ItemsTxt[oneHandedAxes[i]]
					txt.Skill=2
					txt.EquipStat=0
				end
				for i=1,#twoHandedAxes do
					txt=Game.ItemsTxt[twoHandedAxes[i]]
					txt.Skill=3
					txt.EquipStat=0
				end
			end
			if m>=3 then
				for i=1,#twoHandedAxes do
					txt=Game.ItemsTxt[twoHandedAxes[i]]
					txt.Skill=2
					txt.EquipStat=0
				end
			end
			pl.Skills[2]=1024
			minotaurDetected=true
		elseif race~=const.Race.Minotaur and minotaurDetected then
			for i=1,#oneHandedAxes do
				txt=Game.ItemsTxt[oneHandedAxes[i]]
				txt.Skill=3
				txt.EquipStat=0
			end
			for i=1,#twoHandedAxes do
				txt=Game.ItemsTxt[twoHandedAxes[i]]
				txt.Skill=3
				txt.EquipStat=1
			end
			minotaurDetected=false
		end
	elseif minotaurDetected then
		for i=1,#oneHandedAxes do
			txt=Game.ItemsTxt[oneHandedAxes[i]]
			txt.Skill=3
			txt.EquipStat=0
		end
		for i=1,#twoHandedAxes do
			txt=Game.ItemsTxt[twoHandedAxes[i]]
			txt.Skill=3
			txt.EquipStat=1
		end
		minotaurDetected=false
	end
end

function events.CanWearItem(t)
	local race=Game.CharacterPortraits[Party[t.PlayerId].Face].Race
	if race==const.Race.Minotaur then
		local id=Mouse.Item.Number
		if table.find(oneHandedAxes, id) or table.find(twoHandedAxes, id) then
			return
		end
		if Mouse.Item:T().Skill==2 then
			t.Available=false
		end
	end
end

--list of 2h axes and 1h axe
function events.GameInitialized2()
	oneHandedAxes={}
	twoHandedAxes={}
	for i=1, Game.ItemsTxt.High do
		txt=Game.ItemsTxt[i]
		if txt.Skill==3 then
			if txt.EquipStat==1 then
				table.insert(twoHandedAxes,i)
			else
				table.insert(oneHandedAxes,i)
			end
		end
	end
	
end


--HORIZONTAL SKILL PROGRESSION
local learningRequirements={0,6,12,20}
local learningRequirementsNormal={0,4,7,10}
local horizontalSkills={0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,27,28,30,32,33,35,38}
--online
local insanityLearningRequirements={0,8,20,32}
local insanityCost={0,10000,50000,250000}
function events.CanTeachSkillMastery(t)
	if t.Allow==false then return end --if failing for special requirements (stats, gold, already learned etc)
	if not table.find(horizontalSkills, t.Skill) then return end
	local masteries={"","n Expert", " Master", " GrandMaster"}
	
	--online
	if vars.insanityMode then
		--calculate cost
		local baseCost=insanityCost[t.Mastery]
		local cost=baseCost
		local id=Game.CurrentPlayer
		local masteryToLearn=t.Mastery
		if id>=0 and id<=Party.High then
			local pl=Party[id]
			for i=1,#horizontalSkills do
				local s,m=SplitSkill(pl.Skills[horizontalSkills[i]])
				if m>=masteryToLearn and s~=0 then
					cost=cost+baseCost
				end
			end
		end
		t.Cost=cost
		local skill=SplitSkill(Party[id].Skills[t.Skill])
		if skill<insanityLearningRequirements[t.Mastery] or Party.Gold<cost then
			t.Allow=false
			t.Text="You need at least " .. insanityLearningRequirements[t.Mastery] .. " skill and " .. cost .. " gold to become a" ..  masteries[t.Mastery]
		end
		Message("To learn " .. Skillz.getName(t.Skill) .. " you need at least " .. insanityLearningRequirements[t.Mastery] .. " skill and " .. cost .. " gold.")
		return
	end
	--horizontal mode
	if not Game.freeProgression then
		local skill=SplitSkill(Party[Game.CurrentPlayer].Skills[t.Skill])
		if skill<learningRequirements[t.Mastery] then
			t.Allow=false
			t.Text="You need at least " .. learningRequirements[t.Mastery] .. " skill to become a" ..  masteries[t.Mastery]
		end
	end
end
--reset and store masteries for free progression
--ask confirmation and instructions for true nightmare mode
function horizontalModeMasteries()
	if Game.freeProgression then
		vars.freeProgression=true
	end
	if not Game.freeProgression and vars.freeProgression then --detect difficulty change, from free to horizontal, remove and store
		vars.freeProgression=false
		vars.storedMasteries=vars.storedMasteries or {}
		for i=0,Party.PlayersArray.High do
			pl=Party.PlayersArray[i]
			vars.storedMasteries[i]=vars.storedMasteries[i] or {}
			for v=0,23 do 
				local s,m = SplitSkill(pl.Skills[v])
				while m>0 and s<learningRequirements[m] do
					vars.storedMasteries[i][v]=vars.storedMasteries[i][v] or 0
					vars.storedMasteries[i][v]=math.max(vars.storedMasteries[i][v],m)
					m=m-1
					pl.Skills[v]=JoinSkill(s,m)
				end
			end
		end
	end
	if Game.freeProgression and vars.storedMasteries then
		for i=0,Party.PlayersArray.High do
			pl=Party.PlayersArray[i]
			vars.storedMasteries[i]=vars.storedMasteries[i] or {}
			for v=0,23 do
				if vars.storedMasteries[i][v] then
					local s,m = SplitSkill(pl.Skills[v])
					pl.Skills[v]=JoinSkill(s,math.max(vars.storedMasteries[i][v],m))
				end
			end
		end
		vars.storedMasteries=nil
	end
end


function events.LoadMap(wasInGame)
	Timer(horizontalModeMasteries, const.Minute/4) 
end
function events.Action(t)
	horizontalModeMasteries()
end

--restore masteries 
function events.Action(t)
	if t.Action==121 then
		if t.Param>39 then return end -- to do it better later
		t.Handled=false
		pl=Party[Game.CurrentPlayer]
		local currentCost=SplitSkill(pl.Skills[t.Param])+1
		--calculate actual cost
		local n=1
		if t.Param>=12 and t.Param<=23 then
			for i=1,11 do
				local s,m=SplitSkill(Party[Game.CurrentPlayer].Skills[11+i])
				if s>=currentCost then
					n=n+1
				end
			end
		end
		local actualCost=math.ceil(currentCost/n)
		if pl.SkillPoints>=actualCost then
			local id=pl:GetIndex()
			local s,m=SplitSkill(Party[Game.CurrentPlayer].Skills[t.Param])
			if table.find(horizontalSkills, t.Param) and vars.storedMasteries and vars.storedMasteries[id] and vars.storedMasteries[id][t.Param] then
				while m<4 and vars.storedMasteries[id][t.Param]>m and ((s+1>=learningRequirements[m+1] and not Game.freeProgression) or (s+1>=learningRequirementsNormal[m+1] and Game.freeProgression))  do
					Party[Game.CurrentPlayer].Skills[t.Param]=JoinSkill(s,m+1)
					m=m+1
				end
			end
			if vars.oldPlayerMasteries and vars.oldPlayerMasteries[id] then
				if m<4 and vars.oldPlayerMasteries[id][t.Param]>m then
					if vars.insanityMode and table.find(horizontalSkills, t.Param) then
						requirements={0,8,20,32}
					elseif Game.freeProgression or not table.find(horizontalSkills, t.Param) then
						requirements={0,4,7,10}
					else
						requirements={0,6,12,20}
					end
					if s+1>=requirements[m+1] then
						Party[Game.CurrentPlayer].Skills[t.Param]=JoinSkill(s,m+1)
						m=m+1
					end
				end
			end
		end
	end
end

function events.CanRepairItem(t)
	local requiredSkill=t.Item:T().IdRepSt
	local maxRepairSkill=0
	for i=0, Party.High do
		local s,m=SplitSkill(Party[i]:GetSkill(const.Skills.Repair))
		if s*m>maxRepairSkill then
			maxRepairSkill=s*m
		end		
	end
	if maxRepairSkill>requiredSkill then
		t.CanRepair = true
	end
end

local check=true
function events.GetMerchantTotalSkill(t)
	local maxMerchantSkill=0
	for i=0, Party.High do
		local s,m=SplitSkill(Party[i]:GetSkill(const.Skills.Merchant))
		local tot = s*m
		local glamour=Party[i].SpellBuffs[24]
		if glamour.ExpireTime>=Game.Time then
			tot = tot + glamour.Skill*glamour.Power
			if glamour.Skill==4 then
				tot=100
			end
		end
		if tot>maxMerchantSkill then
			if m==4 then
				maxMerchantSkill=100
			else
				maxMerchantSkill=tot
			end
		end
			
	end
	t.Result=7+maxMerchantSkill
end

function events.CanIdentifyItem(t)
	local requiredSkill=t.Item:T().IdRepSt
	local maxIdentifySkill=0
	for i=0, Party.High do
		local s,m=SplitSkill(Party[i]:GetSkill(const.Skills.IdentifyItem))
		if s*m>maxIdentifySkill then
			maxIdentifySkill=s*m
		end		
	end
	if maxIdentifySkill>requiredSkill then
		t.CanIdentify = true
	end
end

function events.GetDisarmTrapTotalSkill(t)
	local maxDisarmSkill=0
	for i=0, Party.High do
		local s,m=SplitSkill(Party[i]:GetSkill(const.Skills.DisarmTraps))
		if s*m>maxDisarmSkill then
			maxDisarmSkill=s*m
		end		
	end
	t.Result = maxDisarmSkill
end

function events.CanIdentifyMonster(t)
	local lvl=0
	for i=0,Party.High do
		lvl=Party[i].LevelBase+lvl
	end
	lvl=lvl/Party.Count
	requiredSkill=(t.Monster.Level-lvl)
	local maxS=0
	local maxM=0
	t.AllowNovice = false
	t.AllowExpert = false
	t.AllowMaster = false
	t.AllowSpells = false
	t.AllowGM = false
	for i=0, Party.High do
		local s,m=SplitSkill(Party[i]:GetSkill(const.Skills.IdentifyMonster))
		local s1=SplitSkill(Party[i].Skills[const.Skills.IdentifyMonster])
		if s1>0 then
			if s*m>maxS then
				maxS=s*m
			end
			if m>maxM then
				maxM=m
			end
		end
	end
	if maxS>=requiredSkill or maxM==4 then
		if maxM>=1 then
			t.AllowNovice = true
		end
		if maxM>=2 then
			t.AllowExpert = true
		end
		if maxM>=3 then
			t.AllowMaster = true
			t.AllowSpells = true
		end
		if maxM>=4 then
			t.AllowGM = true
		end
	end
end

local partySharedSkills={24,25,26,29,31,34,37}
local skillRequirements={1,4,7,10}
function events.Tick()
	--give masteries to solo player
	vars.checkSoloMastery=vars.checkSoloMastery or true
	if vars.checkSoloMastery and Party.High==0 then
		vars.soloMiscMasteries=vars.soloMiscMasteries or {}
		local id=Party[0]:GetIndex()
		vars.soloMiscMasteries[id]=vars.soloMiscMasteries[id] or {}
		for i=1, #partySharedSkills do
			local s, m=SplitSkill(Party[0].Skills[partySharedSkills[i]])
			local m2=0
			for v=1,#skillRequirements do
				if s>=skillRequirements[v] then
					m2=m2+1
				end
			end
			if m2>m then
				vars.soloMiscMasteries[id][partySharedSkills[i]]=vars.soloMiscMasteries[id][partySharedSkills[i]] or 0
				vars.soloMiscMasteries[id][partySharedSkills[i]]=math.max(vars.soloMiscMasteries[id][partySharedSkills[i]], m)
				vars.removeSoloMastery=true
			end
			Party[0].Skills[partySharedSkills[i]]=JoinSkill(s,m2)
		end
		vars.checkSoloMastery=false--set to true when learning allocating skill points
	end 
	
	--remove masteries when no longer solo
	vars.removeSoloMastery=vars.removeSoloMastery or true
	if vars.removeSoloMastery and Party.High>0 then
		for i=0,Party.PlayersArray.High do
			vars.soloMiscMasteries=vars.soloMiscMasteries or {}
			if vars.soloMiscMasteries[i] then
				for key, value in pairs(vars.soloMiscMasteries[i]) do
					local s,m=SplitSkill(Party.PlayersArray[i].Skills[key])
					Party.PlayersArray[i].Skills[key]=JoinSkill(s,value)
				end
				vars.soloMiscMasteries[i]=nil
			end
		end
		vars.removeSoloMastery=false
	end	
end

--new cover skill
function events.GameInitialized2()
	local coverSkill=50
	Skillz.new_armor(coverSkill)
	Skillz.setName(coverSkill, "Cover")
	Skillz.setDesc(coverSkill, 1, "Cover Skill is a defensive prowess enabling a character to shield allies by intercepting incoming damage. This ability strategically positions the user as the primary target of enemy onslaughts, thereby protecting teammates who are more susceptible to damage.\n\nGrants 10 plus 1% chance per skill point to Cover an ally, up to 40%, however, something might happen once at max level...\n\n\nPress P to enable/disable\n")
	Skillz.setDesc(coverSkill, 2, "Allow use to Cover Physical damage\n")
	Skillz.setDesc(coverSkill, 3, "Allow use to Cover Projectiles damage")
	Skillz.setDesc(coverSkill, 4, "Allow use to Cover Spells damage")
	Skillz.setDesc(coverSkill, 5, "Attacking will increase you next Cover chance by 15%")
	Skillz.learn_at(coverSkill, 30)
end

-- COVER SKILL
function events.Tick()
	if Game.CurrentCharScreen==101 and Game.CurrentScreen==7 then
		local index=Game.CurrentPlayer
		local pl=Party[index]
		if index>=0 and index<=Party.High then
			local skills={50,53,51}
			local txt="Misc"
			for i=1,#skills do
				if Skillz.get(pl,skills[i])>0 then
					if i~=3 or (not skills[1]) then
						txt="\n" .. txt
					end
				else
					skills[i]=false
				end
			end
			Game.GlobalTxt[143]=txt
			
			local noarmor=true
			for i=8, 11 do
				local s=pl.Skills[i]
				if s>0 then
					noarmor=false
				end
			end
			if noarmor then
				Game.GlobalTxt[143]="Misc"
			end
			if Skillz.get(pl,50)>0 and Skillz.get(pl,51)>0 then
				Game.GlobalTxt[143]="\n" .. Game.GlobalTxt[143]
			end
		end	
		if not vars.covering then
			vars.covering={}
			for i=0,4 do
				vars.covering[i]=true
			end
		end
		local s= SplitSkill(Skillz.get(pl, 50))
		local chance=math.min(10+s,40)
		local txt="Cover Skill is a defensive prowess enabling a character to shield allies by intercepting incoming damage. This ability strategically positions the user as the primary target of enemy onslaughts, thereby protecting teammates who are more susceptible to damage.\n\nIf available, Expert, Master and Grandmaster is learned at skill 6-12-20.\n\nGrants 10 plus 1% chance per skill point to Cover, up to 40%, however, something might happen once at max level....\n\nCurrent cover chance: " .. chance .. "%\n\nPress P to enable/disable\n"
		if vars.insanityMode then
			txt="Cover Skill is a defensive prowess enabling a character to shield allies by intercepting incoming damage. This ability strategically positions the user as the primary target of enemy onslaughts, thereby protecting teammates who are more susceptible to damage.\n\nIf available, Expert, Master and Grandmaster is learned at skill 8-20-30.\n\nGrants 10 plus 1% chance per skill point to Cover, up to 40%, however, something might happen once at max level....\n\nCurrent cover chance: " .. chance .. "%\n\nPress P to enable/disable\n"
		end
		if vars.covering[index] then
			txt=txt .. StrColor(0,255,0,"\nCurrently enabled\n")
			Skillz.setDesc(50, 1, txt)
		else
			txt=txt .. StrColor(255,0,0,"\nCurrently disabled\n")
			Skillz.setDesc(50, 1, txt)
		end
		
		--MANA SHIELD
		if not vars.manaShield then
			vars.manaShield={}
			for i=0,4 do
				vars.manaShield[i]=true
			end
		end
		local s, m= SplitSkill(Skillz.get(pl, 51))
		local efficiency=round((1+s^1.4/125*4)*100)/100
		if s > 50 then 
			efficiency=round((1+50^1.4/125*4)*100)/100*s/50
		end

		local txt="Mana shield consume mana to reduce damage when an hit would take you below a certain threshold.\n\nIf available, Expert, Master and Grandmaster is learned at skill 6-12-20.\n\nMastery increase its mana efficience.\n" .. "Current Damage reduction per Mana: " .. StrColor(178,255,255, efficiency) .. "\n\nPress M to enable/disable"
		if vars.insanityMode then
			txt="Mana shield consume mana to reduce damage when an hit would take you below a certain threshold.\n\nIf available, Expert, Master and Grandmaster is learned at skill 8-20-32.\n\nMastery increase its mana efficience.\n" .. "Current Damage reduction per Mana: " .. StrColor(178,255,255, efficiency) .. "\n\nPress M to enable/disable"
		end
		if vars.manaShield[index] then
			txt=txt .. StrColor(0,255,0,"\nCurrently enabled\n")
			Skillz.setDesc(51, 1, txt)
		else
			txt=txt .. StrColor(255,0,0,"\nCurrently disabled\n")
			Skillz.setDesc(51, 1, txt)
		end
		
		local powerMult, DPS2, DPS3, vitMult=calcPowerVitality(pl)
		local vit=round(vitMult^0.35)
		local power=round(powerMult^0.35)
		local retS, m= SplitSkill(Skillz.get(pl, 53))
		Skillz.setDesc(53, 1, "After mastering the art of covering, you have become capable delivering deadly counter attacks to those who dare try harm your allies. Retaliation has a 1% per skill point chance to activate after successfully covering an ally.\n\nExpert, Master and Grandmaster are learned automatically at skill 12, 30 and 50.\n\nDamage done depends on 2 coefficients, multiplied then by skill level:\n\nMelee Power coefficient: " .. StrColor(255,0,0, power) .. "\nVitality coefficient: " .. StrColor(255,0,0, vit) .. "\n\nTotal Damage: " .. StrColor(255,0,0, retS*vit*power) .. "\n\nBalancing power and vitality leads to the highest damage.\n")
		
	end
end
function events.KeyDown(t)
	if t.Key==const.Keys.P then
		if Game.CurrentCharScreen==101 and Game.CurrentScreen==7 then
			vars.covering=vars.covering or {}
			if vars.covering[Game.CurrentPlayer] then
				vars.covering[Game.CurrentPlayer]=false
				Game.ShowStatusText("Cover Disabled")
			else
				vars.covering[Game.CurrentPlayer]=true
				Game.ShowStatusText("Cover Enabled")
			end
		end
	end
	if t.Key==const.Keys.M then
		if Game.CurrentCharScreen==101 and Game.CurrentScreen==7 then
			vars.manaShield=vars.manaShield or {}
			if vars.manaShield[Game.CurrentPlayer] then
				vars.manaShield[Game.CurrentPlayer]=false
				Game.ShowStatusText("Mana Shield Disabled")
			else
				vars.manaShield[Game.CurrentPlayer]=true
				Game.ShowStatusText("Mana Shield Enabled")
			end
		end
	end
	if t.Key==const.Keys.R then
		if Game.CurrentCharScreen==101 and Game.CurrentScreen==7 then
			local pl=Party[Game.CurrentPlayer]
			local id=pl:GetIndex()
			if table.find(elementalistClass, Party[Game.CurrentPlayer].Class) then
				if vars.disableRotation and vars.disableRotation[id] then
					vars.disableRotation[id]=false
					Game.ShowStatusText("Elementalist Rotation Enabled")
				else
					vars.disableRotation=vars.disableRotation or {}
					vars.disableRotation[id]=true
					Game.ShowStatusText("Elementalist Rotation Disabled")
				end
				checkSkills(Game.CurrentPlayer)
			end
		end
	end
end
function events.Action(t)
	if t.Action==121 then
		if t.Param==50 then
			local coverRequirements={6,12,20}
			if vars.insanityMode then
				coverRequirements={8,20,30}
			end
			local pl=Party[Game.CurrentPlayer]
			local s,m=SplitSkill(Skillz.get(pl,50))
			if s==29 and pl.SkillPoints>29 then
				local s,m=SplitSkill(Skillz.get(pl,53))
				if s==0 then
					Skillz.set(pl,53,1)
					Game.ShowStatusText("YOU LEARNED RETALIATION!!")
				end
			end
			if s==30 then 
				t.Handled=true
				local s,m=SplitSkill(Skillz.get(pl,53))
				if s==0 then
					Skillz.set(pl,53,1)
					Game.ShowStatusText("YOU LEARNED RETALIATION!!")
				else
					Game.ShowStatusText("This skill has reached its limit")
				end
			elseif s>30 then
				t.Handled=true
				while s>30 do
					pl.SkillPoints=pl.SkillPoints+s
					s=s-1
				end
				Skillz.set(pl,50,JoinSkill(s,m))
			end
			if pl.SkillPoints>s and coverRequirements[m] and s+1>=coverRequirements[m] and Skillz.MasteryLimit(pl,50)>m then
				Skillz.set(pl,50,JoinSkill(s, m+1))
			elseif coverRequirements[m] and s>=coverRequirements[m] and Skillz.MasteryLimit(pl,50)>m then
				Skillz.set(pl,50,JoinSkill(s, m+1))
			end
		end
	end
end
coverBonus={}
function events.CalcDamageToMonster(t)
	data = WhoHitMonster()	
	if data and data.Player and t.DamageKind==4 then
		if data.Object==nil then
			local s, m=SplitSkill(Skillz.get(data.Player,50))
			if m>=4 then
				for i=0, Party.High do
					if Party[i]:GetIndex()==t.PlayerIndex then
						coverBonus[i]=true
						return
					end
				end
			end
		end
	end
end	

		
function events.CanIdentifyItem(t)
	for k,v in pairs(vars.NPCFollowers) do
		if Game.NPC[v].Profession == 4 then
			t.CanIdentify = true
		end
	end
end

--fix for "yo" text
function events.Action()
	Game.NPCText[128]="You don't meet the requirements, and cannot be taught until you do."	
end

--[[running
function events.KeyDown(t)
	if t.Key ==18 then
		running=true
	end
	if running and t.Key==67 then
		sliding=true
	end
end
function events.KeyUp(t)
	if t.Key ==18 then
		running=false
	end
	if t.Key==67 then
		sliding=false
	end
end

function events.Tick()
	if not sliding then
		lockMovementX=nil
		lockMovementY=nil
		lockMovementZ=nil
	end
	if running and not sliding then
		vars.lastX=vars.lastX or Party.X
		vars.lastY=vars.lastY or Party.Y
		push1=(Party.X-vars.lastX)
		push2=(Party.Y-vars.lastY)
		Party.X=Party.X+ push1*0.5
		Party.Y=Party.Y+ push2*0.5
	end
	if running and sliding then
		Party.X=vars.lastX+ push1*1.5
		Party.Y=vars.lastY+ push2*1.5
	end
	vars.lastX=Party.X
	vars.lastY=Party.Y
end
]]

--racial skills

function events.GameInitialized2()
	local MAWRacialSkills={
		[const.Race.Human]={
			[const.Skills.Leather]=3,
			[const.Skills.Chain]=3,
			[const.Skills.Plate]=3,
			[const.Skills.Shield]=3,
		},
		[const.Race.Vampire]={},
		[const.Race.DarkElf]={
			[const.Skills.Bow]=3,
			[const.Skills.Meditation]=3,
		},
		[const.Race.Minotaur]={
			[const.Skills.Axe]=3,
		},
		[const.Race.Troll]={
			[const.Skills.Regeneration]=3,
		},
		[const.Race.Dragon]={},
		[const.Race.Undead]={},
		[const.Race.Elf]={
			[const.Skills.Bow]=3,
			[const.Skills.Spear]=3,
			[const.Skills.Meditation]=3,
		},
		[const.Race.DarkElf]={
			[const.Skills.Bow]=3,
			[const.Skills.Spear]=3,
			[const.Skills.Meditation]=3,
		}, 
		[const.Race.Goblin]={
			[const.Skills.Sword]=3,
			[const.Skills.Mace]=3,
			[const.Skills.Dagger]=3,
			[const.Skills.Leather]=3,
		},
		[const.Race.Dwarf]={
			[const.Skills.Axe]=3,
			[const.Skills.Shield]=3,
			[const.Skills.Bodybuilding]=3,
		},
		[const.Race.Zombie]={},
	}

	function events.GetSkill(t)
		local pl=t.Player
		local race=Game.CharacterPortraits[pl.Face].Race
		if MAWRacialSkills[race][t.Skill] then
			local baseSkill=SplitSkill(pl.Skills[t.Skill])
			t.Result=t.Result+ MAWRacialSkills[race][t.Skill] + math.floor(baseSkill/10)
		end
	end
end

--fix cover when starting new Game
function events.BeforeNewGameAutosave()
	for i=0,Party.PlayersArray.High do
		pl=Party.PlayersArray[i]
		Skillz.set(pl,50,0)
		Skillz.set(pl,51,0)
		Skillz.set(pl,52,0)
	end
end

--mace stun
function events.CalcDamageToMonster(t)
	if t.Player then
		local it=t.Player:GetActiveItem(1)
		if not it then return end
		local skill=it:T().Skill
		local data=WhoHitMonster()
		if skill==6 and t.DamageKind==4 and data and data.Object==nil then
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Mace))
			if m>=3 then
				local mon=t.Monster
				--get Level
				local id=t.MonsterIndex
				local lvl=getMonsterLevel(mon)
				--chance to paralyze
				local chance=s/lvl^0.65*0.15*damageMultiplier[t.Player:GetIndex()].Melee/math.min(1+lvl/150,3)
				local applyParalyze=applyParalyze or {}
				applyParalyze[id]=false
				local previousDuration=mon.SpellBuffs[6].ExpireTime
				local duration=0
				if chance>math.random() then
					applyParalyze[id]=true
					duration=const.Minute*2.5
					if mon.NameId>220 and mon.NameId<300 then
						duration=duration/2.5
					end
					if m==3 then
						duration=duration/2
					end
				end
				function events.Tick()
					events.Remove("Tick",1)
					if applyParalyze[id] then
						if mon.HP~=0 then
							mon.SpellBuffs[6].ExpireTime=Game.Time+duration
						end
						applyParalyze[id]=false
					else
						mon.SpellBuffs[6].ExpireTime=previousDuration
					end
				end
			end
		end
	end
end


function events.Action(t)
	function events.Tick()
		events.Remove("Tick", 1)
		if Game.CurrentCharScreen==101 and Game.CurrentScreen==7 then
			local i=Game.CurrentPlayer
			if i<0 or i>Party.High then return end
			local pl=Party[i]
			local index=pl:GetIndex()
			itemStats(index)
			--base descriptions
			Skillz.setDesc(6,5,maceGMtxt)
			if m<3 then return end
			local s,m=SplitSkill(pl:GetSkill(const.Skills.Mace))
			local chance=round(s/pl.LevelBase^0.65*1500*damageMultiplier[pl:GetIndex()].Melee/math.min(1+pl.LevelBase/150,3))/100
			local txt="\n\n"
			if m==3 then
				txt=txt .. "Chance to Stun: " .. chance .. "%"
			elseif m==4 then
				txt=txt .. "Chance to Paralyze: " .. chance .. "%"
			end
			Skillz.setDesc(6,5,maceGMtxt .. StrColor(0,0,0,txt))
		end
	end
end

--mana shield
function events.GameInitialized2()
	local manaSkill=51
	Skillz.new_armor(manaSkill)
	Skillz.setName(manaSkill, "Mana Shield")
	Skillz.setDesc(manaSkill, 1, "Mana shield consume mana to reduce damage when an hit would take you below a certain threshold.\n\nIf available, Expert, Master and Grandmaster is learned at skill 6-12-20 (8-20-32 in insanity mode).\n\nMastery increase its mana efficience.\n")
	Skillz.setDesc(manaSkill, 2, "Absorb up to 25% damage")
	Skillz.setDesc(manaSkill, 3, "Absorb up to 50% damage")
	Skillz.setDesc(manaSkill, 4, "Absorb up to 75% damage")
	Skillz.setDesc(manaSkill, 5, "All damage is absorbed by mana")
	Skillz.learn_at(manaSkill, 3) --alchemy shop
end

local manaShieldRequirements={6,12,20}
function events.Action(t)
	if t.Action==121 then
		if t.Param==51 then
			local manaShieldRequirements={6,12,20}
			if vars.insanityMode then
				manaShieldRequirements={8,20,32}
			end
			local pl=Party[Game.CurrentPlayer]
			local s,m=SplitSkill(Skillz.get(pl,51))
			if pl.SkillPoints>s and manaShieldRequirements[m] and s+1>=manaShieldRequirements[m] and Skillz.MasteryLimit(pl,51)>m then
				Skillz.set(pl,51,JoinSkill(s, m+1))
			elseif manaShieldRequirements[m] and s>=manaShieldRequirements[m] and Skillz.MasteryLimit(pl,51)>m then
				Skillz.set(pl,51,JoinSkill(s, m+1))
			end
		end
	end
end

--Enlightenment
function events.GameInitialized2()
	local Enlightenment=52
	Skillz.new_magic(Enlightenment)
	Skillz.setName(Enlightenment, "Enlightenment")
	Skillz.setDesc(Enlightenment, 1, "Unlock the true potential of your mana reserves with Enlightenment, a transformative skill that increases your mana pool and reduces mana reserved by buffs, empowering you to cast more freely and frequently.\n\nThe cost of buffs is divided by the amount of mana you gain per level. As you reach higher mastery levels, the divisor increases, but your total mana pool remains the same.\n\nIf available, Expert, Master and Grandmaster is learned at skill 6-12-20.\n")
	Skillz.setDesc(Enlightenment, 2, "Mana is increased by 2% per skill level, cost divisor increased by 0.5")
	Skillz.setDesc(Enlightenment, 3, "Mana is increased by 3% per skill level, cost divisor increased by 1")
	Skillz.setDesc(Enlightenment, 4, "Mana is increased by 4% per skill level, cost divisor increased by 1.5")
	Skillz.setDesc(Enlightenment, 5, "Mana is increased by 5% per skill level, cost divisor increased by 2")
	Skillz.learn_at(Enlightenment, 3) --alchemy shop
end

function events.Action(t)
	if t.Action==121 then
		if t.Param==52 then
			local EnlightenmentRequirements={6,12,20}
			if vars.insanityMode then
				--EnlightenmentRequirements={8,20,32}
			end
			local pl=Party[Game.CurrentPlayer]
			local s,m=SplitSkill(Skillz.get(pl,52))
			if pl.SkillPoints>s and EnlightenmentRequirements[m] and s+1>=EnlightenmentRequirements[m] and Skillz.MasteryLimit(pl,52)>m then
				Skillz.set(pl,52,JoinSkill(s, m+1))
			elseif EnlightenmentRequirements[m] and s>=EnlightenmentRequirements[m] and Skillz.MasteryLimit(pl,52)>m then
				Skillz.set(pl,52,JoinSkill(s, m+1))
			end
		end
	end
end

--RETALIATION
function events.GameInitialized2()
	local Retaliation=53
	Skillz.new_armor(Retaliation)
	Skillz.setName(Retaliation, "Retaliation")
	Skillz.setDesc(Retaliation, 1, "After mastering the art of covering, you have become capable delivering deadly counter attacks to those who dare try harm your allies. Retaliation has a 1% per skill point chance to activate after successfully covering an ally.\n\nExpert, Master and Grandmaster are learned automatically at skill 12, 30 and 50.\n")
	Skillz.setDesc(Retaliation, 2, "Your next attack deals additional damage, multiplied by skill level")
	Skillz.setDesc(Retaliation, 3, "Your next attack recovery time is reduced by 30%")
	Skillz.setDesc(Retaliation, 4, "Your next attack has a 25% chance to stun the enemy for 2 seconds")
	Skillz.setDesc(Retaliation, 5, "Retaliation can stack up to 3 times, allowing to consume all the stacks in 1 single powerful hit")
end

function events.Action(t)
	if t.Action==121 then
		if t.Param==53 then
			local retaliationRequirements={12,30,50}
			local pl=Party[Game.CurrentPlayer]
			local s,m=SplitSkill(Skillz.get(pl,53))
			if s==50 then 
				t.Handled=true
				Game.ShowStatusText("This skill has reached its limit")
			elseif s>50 then
				t.Handled=true
				while s>50 do
					pl.SkillPoints=pl.SkillPoints+s
					s=s-1
				end
				Skillz.set(pl,53,JoinSkill(s,m))
			end
			if pl.SkillPoints>s and retaliationRequirements[m] and s+1>=retaliationRequirements[m] and Skillz.MasteryLimit(pl,53)>m then
				Skillz.set(pl,53,JoinSkill(s, m+1))
			elseif retaliationRequirements[m] and s>=retaliationRequirements[m] and Skillz.MasteryLimit(pl,53)>m then
				Skillz.set(pl,53,JoinSkill(s, m+1))
			end
		end
	end
end

--regeneration for Troll
function events.GameInitialized2()
	Skillz.setDesc(30, 5, "Increase your regeneration by 1% per every 1% of hp lost")
end

--disable arrows

function events.ArrowProjectile(t)
	if disableBow then
		t.ObjId=0
	end
end

function events.PlaySound(t)
	if disableBow and t.Sound==71 then
		t.Sound=83
	end
end

function events.KeyDown(t)
	if vars then 
		vars.lastUnstuck=vars.lastUnstuck or 0
		if Game.CurrentScreen==0 and t.Key==const.Keys.L and Game.Time>vars.lastUnstuck then
			Party.Z=Party.Z+100
			vars.lastUnstuck=Game.Time+const.Minute*5
		end
	end
end
