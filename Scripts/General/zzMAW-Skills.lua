-- weapon base recovery bonuses

oldWeaponBaseRecoveryBonuses =
{ 
	[const.Skills.Bow] = 0,
	[const.Skills.Blaster] = 70,
	[const.Skills.Staff] = 0,
	[const.Skills.Axe] = 0,
	[const.Skills.Sword] = 10,
	[const.Skills.Spear] = 20,
	[const.Skills.Mace] = 20,
	[const.Skills.Dagger] = 40,
}
newWeaponBaseRecoveryBonuses =
{
	[const.Skills.Bow] = 0,
	[const.Skills.Blaster] = 100,
	[const.Skills.Staff] = 0,
	[const.Skills.Axe] = 20,
	[const.Skills.Sword] = 10,
	[const.Skills.Spear] = 10,
	[const.Skills.Mace] = 20,
	[const.Skills.Dagger] = 40,
}

oldWeaponSkillAttackBonuses =
{
	[const.Skills.Staff]	= {1, 1, 1, 1,},
	[const.Skills.Sword]	= {1, 1, 1, 1,},
	[const.Skills.Dagger]	= {1, 1, 1, 1,},
	[const.Skills.Axe]		= {1, 1, 1, 1,},
	[const.Skills.Spear]	= {1, 1, 1, 1,},
	[const.Skills.Bow]		= {1, 1, 1, 1,},
	[const.Skills.Mace]		= {1, 1, 1, 1,},
	[const.Skills.Blaster]	= {1, 2, 3, 5,},
	[const.Skills.Unarmed]	= {1, 1, 2, 2,},
	
}
newWeaponSkillAttackBonuses =
{
	[const.Skills.Staff]	= {1, 2, 2, 2,},
	[const.Skills.Sword]	= {1, 2, 2, 2,},
	[const.Skills.Dagger]	= {1, 2, 2, 2,},
	[const.Skills.Axe]		= {1, 2, 2, 2,},
	[const.Skills.Spear]	= {1, 2, 2, 3,},
	[const.Skills.Bow]		= {3, 3, 3, 3,},
	[const.Skills.Mace]		= {1, 2, 2, 2,},
	[const.Skills.Blaster]	= {5, 10, 15, 20,},
	[const.Skills.Unarmed]	= {2, 2, 3, 3,},
}
-- weapon skill recovery bonuses (by rank)

oldWeaponSkillRecoveryBonuses =
{
	[const.Skills.Staff]	= {0, 0, 0, 0,},
	[const.Skills.Sword]	= {0, 1, 1, 1,},
	[const.Skills.Dagger]	= {0, 0, 0, 0,},
	[const.Skills.Axe]		= {0, 1, 1, 1,},
	[const.Skills.Spear]	= {0, 0, 0, 0,},
	[const.Skills.Bow]		= {0, 1, 1, 1,},
	[const.Skills.Blaster]	= {0, 0, 0, 0,},
	[const.Skills.Mace]		= {0, 0, 0, 0,},
	[const.Skills.Unarmed]	= {0, 0, 0, 0,},
}
newWeaponSkillRecoveryBonuses =
{
	[const.Skills.Staff]	= {0, 0, 0, 0,},
	[const.Skills.Sword]	= {0, 2, 2, 3,},
	[const.Skills.Dagger]	= {0, 0, 1, 1,},
	[const.Skills.Axe]		= {0, 1, 2, 2,},
	[const.Skills.Spear]	= {0, 0, 0, 0,},
	[const.Skills.Bow]		= {1, 2, 2, 3,},
	[const.Skills.Mace]		= {0, 0, 0, 0,},
	[const.Skills.Blaster]	= {0, 0, 0, 0,},
	[const.Skills.Unarmed]	= {0, 1, 1, 2,},
}
-- weapon skill damage bonuses (by rank)
oldWeaponSkillDamageBonuses =
{
	[const.Skills.Staff]	= {0, 0, 0, 1},
	[const.Skills.Sword]	= {0, 0, 0, 0},
	[const.Skills.Dagger]	= {0, 0, 0, 1},
	[const.Skills.Axe]		= {0, 0, 1, 1},
	[const.Skills.Spear]	= {0, 1, 1, 1},
	[const.Skills.Bow]		= {0, 0, 0, 1},
	[const.Skills.Mace]		= {0, 1, 1, 1},
	[const.Skills.Blaster]	= {0, 0, 0, 0},
	[const.Skills.Unarmed]	= {1, 1, 2, 2,},
}
newWeaponSkillDamageBonuses =
{
	[const.Skills.Staff]	= {0, 1, 2, 3,},
	[const.Skills.Sword]	= {0, 1, 2, 2,},
	[const.Skills.Dagger]	= {0, 0, 1, 1,},
	[const.Skills.Axe]		= {1, 2, 3, 4,},
	[const.Skills.Spear]	= {0, 1, 2, 3,},
	[const.Skills.Bow]		= {1, 2, 2, 3,},
	[const.Skills.Mace]		= {1, 2, 3, 4,},
	[const.Skills.Blaster]	= {0, 0, 0, 0,},
	[const.Skills.Unarmed]	= {2, 3, 4, 4,},
}
-- weapon skill AC bonuses (by rank)

oldWeaponSkillACBonuses =
{
	[const.Skills.Staff]	= {0, 1, 1, 1,},
	[const.Skills.Sword]	= {0, 0, 0, 1,},
	[const.Skills.Dagger]	= {0, 0, 0, 0,},
	[const.Skills.Axe]		= {0, 0, 0, 0,},
	[const.Skills.Spear]	= {0, 0, 0, 1,},
	[const.Skills.Bow]		= {0, 0, 0, 0,},
	[const.Skills.Mace]		= {0, 0, 0, 0,},
	[const.Skills.Blaster]	= {0, 0, 0, 0,},
	[const.Skills.Unarmed]	= {0, 0, 0, 0,},
	
}
newWeaponSkillACBonuses =
{
	[const.Skills.Staff]	= {1, 1, 2, 2,},
	[const.Skills.Sword]	= {0, 0, 0, 1,},
	[const.Skills.Dagger]	= {0, 0, 0, 0,},
	[const.Skills.Axe]		= {0, 0, 0, 0,},
	[const.Skills.Spear]	= {1, 2, 2, 3,},
	[const.Skills.Bow]		= {0, 0, 0, 0,},
	[const.Skills.Mace]		= {0, 0, 0, 0,},
	[const.Skills.Blaster]	= {0, 0, 0, 0,},
	[const.Skills.Unarmed]	= {0, 0, 0, 0,},
}
newWeaponSkillResistanceBonuses =
{
	[const.Skills.Staff]	= {0, 1, 2, 2},
	[const.Skills.Sword]	= {0, 0, 0, 0},
	[const.Skills.Dagger]	= {0, 0, 0, 0},
	[const.Skills.Axe]		= {0, 0, 0, 0},
	[const.Skills.Spear]	= {0, 0, 0, 0},
	[const.Skills.Bow]		= {0, 0, 0, 0},
	[const.Skills.Mace]		= {0, 0, 0, 0},
	[const.Skills.Blaster]	= {0, 0, 0, 0},
	[const.Skills.Unarmed]	= {0, 0, 0, 0,},
	
}
-- armor skill AC bonuses (by rank)
oldArmorSkillACBonuses =
{
	[const.Skills.Shield]	= {1, 1, 2, 2,}, 
	[const.Skills.Leather]	= {1, 1, 2, 2,},
	[const.Skills.Chain]	= {1, 1, 1, 1,},
	[const.Skills.Plate]	= {1, 1, 1, 1,},
	[const.Skills.Dodging]	= {1, 2, 3, 3,},
}
newArmorSkillACBonuses =
{
	[const.Skills.Shield]	= {1, 2, 2, 3,},
	[const.Skills.Leather]	= {1, 1, 2, 2,},
	[const.Skills.Chain]	= {1, 2, 3, 3,},
	[const.Skills.Plate]	= {2, 2, 3, 4,},
	[const.Skills.Dodging]	= {2, 3, 4, 4,},
}
-- armor skill resistance bonuses (by rank)

newArmorSkillResistanceBonuses =
{
	[const.Skills.Leather]	= {2, 4, 6, 8,},
	[const.Skills.Chain]	= {2, 3, 4, 6,},
	[const.Skills.Plate]	= {1, 2, 3, 4,},
	[const.Skills.Shield]	= {2, 4, 6, 8,},
	[const.Skills.Dodging]	= {0, 0, 0, 0,},
}

twoHandedWeaponDamageBonusByMastery = {
	[const.Novice] = 1, 
	[const.Expert] = 2, 
	[const.Master] = 3, 
	[const.GM] = 3 }

classMeleeWeaponSkillDamageBonus ={}
classRangedWeaponSkillAttackBonusMultiplier ={}
classRangedWeaponSkillDamageBonus ={}

-- collects relevant player weapon data

local function getPlayerEquipmentData(player)

	local equipmentData =
	{
		twoHanded = false,
		dualWield = false,
		bow =
		{
			equipped = false,
			item = nil,
			equipStat = nil,
			weapon = false,
			skill = nil,
			rank = nil,
			level = nil,
		},
		main =
		{
			equipped = false,
			item = nil,
			equipStat = nil,
			weapon = false,
			skill = nil,
			rank = nil,
			level = nil,
		},
		extra =
		{
			equipped = false,
			item = nil,
			equipStat = nil,
			weapon = false,
			skill = nil,
			rank = nil,
			level = nil,
		},
		shield =
		{
			equipped = false,
			item = nil,
			skill = nil,
			rank = nil,
			level = nil,
		},
		armor =
		{
			equipped = false,
			item = nil,
			skill = nil,
			rank = nil,
			level = nil,
		},
	}
	
	-- get ranged weapon data
	
	if player.ItemBow ~= 0 then
		
		equipmentData.bow.equipped = true
		
		equipmentData.bow.item = player.Items[player.ItemBow]
		local itemBowTxt = Game.ItemsTxt[equipmentData.bow.item.Number]
		equipmentData.bow.equipStat = itemBowTxt.EquipStat + 1
		equipmentData.bow.skill = itemBowTxt.Skill 
		
		if equipmentData.bow.skill >= 0 then
			equipmentData.bow.level, equipmentData.bow.rank = SplitSkill(player.Skills[equipmentData.bow.skill])
		end
		
		if equipmentData.bow.skill >= 0 and equipmentData.bow.skill <= 7 then
			equipmentData.bow.weapon = true
		end
		
	end
	
	-- get main hand weapon data
			
	if player.ItemMainHand ~= 0 then
		
		equipmentData.main.equipped = true
		
		equipmentData.main.item = player.Items[player.ItemMainHand]
		equipmentData.main.itemTxt = Game.ItemsTxt[equipmentData.main.item.Number]
		equipmentData.main.equipStat = equipmentData.main.itemTxt.EquipStat + 1
		equipmentData.main.skill = equipmentData.main.itemTxt.Skill 
		
		if equipmentData.main.skill >= 0 and equipmentData.main.skill <= 38 then
			equipmentData.main.level, equipmentData.main.rank = SplitSkill(player.Skills[equipmentData.main.skill])
		end
		
		if equipmentData.main.skill >= 0 and equipmentData.main.skill <= 7 then
			equipmentData.main.weapon = true
		end
		
	end
	
	-- get extra hand weapon data only if not holding blaster in main hand
			
	if (player.ItemMainHand == 0 or equipmentData.main.skill ~= const.Skills.Blaster) and player.ItemExtraHand ~= 0 then
		
		equipmentData.extra.equipped = true
		
		equipmentData.extra.item = player.Items[player.ItemExtraHand]
		equipmentData.extra.itemTxt = Game.ItemsTxt[equipmentData.extra.item.Number]
		equipmentData.extra.equipStat = equipmentData.extra.itemTxt.EquipStat + 1
		equipmentData.extra.skill = equipmentData.extra.itemTxt.Skill 
		
		if equipmentData.extra.skill >= 0 then
			equipmentData.extra.level, equipmentData.extra.rank = SplitSkill(player.Skills[equipmentData.extra.skill])
		end
		
		if equipmentData.extra.skill >= 0 and equipmentData.extra.skill <= 7 then
			equipmentData.extra.weapon = true
		end
		
	end
	
	-- populate other info
	
	if equipmentData.main.weapon and equipmentData.main.equipStat == const.ItemType.Weapon2H then
		equipmentData.twoHanded = true
	elseif equipmentData.main.skill == const.Skills.Spear and not equipmentData.extra.equipped then
		equipmentData.twoHanded = true
	elseif equipmentData.main.weapon and equipmentData.extra.weapon then
		equipmentData.dualWield = true
	end
	
	-- get shield data
	
	if player.ItemExtraHand ~= 0 then
		
		equipmentData.extra.item = player.Items[player.ItemExtraHand]
		local itemExtraHandTxt = Game.ItemsTxt[equipmentData.extra.item.Number]
		equipmentData.extra.equipStat = itemExtraHandTxt.EquipStat + 1
		equipmentData.extra.skill = itemExtraHandTxt.Skill 
		
		if equipmentData.extra.skill == const.Skills.Shield then
			equipmentData.shield.equipped = true
			equipmentData.shield.skill = equipmentData.extra.skill
			equipmentData.shield.level, equipmentData.shield.rank = SplitSkill(player.Skills[equipmentData.shield.skill])
		end
		
	end
	
	-- get armor data
	
	if player.ItemArmor ~= 0 then
		
		equipmentData.armor.equipped = true
		
		equipmentData.armor.item = player.Items[player.ItemArmor]
		local itemArmorTxt = Game.ItemsTxt[equipmentData.armor.item.Number]
		equipmentData.armor.skill = itemArmorTxt.Skill 
		equipmentData.armor.level, equipmentData.armor.rank = SplitSkill(player.Skills[equipmentData.armor.skill])
		
	end
	
	
	return equipmentData
	
end




-- calculate stat bonus by skill

function events.CalcStatBonusBySkills(t)

	local equipmentData = getPlayerEquipmentData(t.Player)
	
	-- calculate ranged attack bonus by skill
	
	if t.Stat == const.Stats.RangedAttack then
	
		local bow = equipmentData.bow
	
		if bow.weapon then
		
			-- calculate old bonus
			
			local oldBonus = (oldWeaponSkillAttackBonuses[bow.skill][bow.rank] * bow.level)
			
			-- calculate new bonus
			
			local newBonus = (newWeaponSkillAttackBonuses[bow.skill][bow.rank] * bow.level)
			
			if bow.skill == const.Skills.Bow then
				local rangedWeaponSkillAttackBonusMultiplier = classRangedWeaponSkillAttackBonusMultiplier[t.Player.Class]
				if rangedWeaponSkillAttackBonusMultiplier ~= nil then
					newBonus = newBonus * rangedWeaponSkillAttackBonusMultiplier
				end
			end
			
			-- recalculate bonus
			
			
		end
		
	-- calculate ranged damage bonus by skill
	
	elseif t.Stat == const.Stats.RangedDamageBase then
	
		local bow = equipmentData.bow
	
		if bow.weapon then
		
			-- calculate old bonus
			
			local oldBonus = 0
			
			-- calculate new bonus
			
			local newBonus = 0
			
			-- add new bonus for ranged weapon
			local might=t.Player:GetMight()
			if might<=21 then
				mightBonus=(might-1)/2-6
			else
				mightBonus=math.floor(might/5)
			end
			t.Result = t.Result + newWeaponSkillDamageBonuses[bow.skill][bow.rank] * bow.level+mightBonus
			
			-- add class bonus for ranged weapon
			
			if classRangedWeaponSkillDamageBonus[t.Player.Class] ~= nil then
				t.Result = t.Result + (classRangedWeaponSkillDamageBonus[t.Player.Class] * bow.level)
			end
			
			-- recalculate bonus
			
			t.Result = t.Result - oldBonus + newBonus
			
		end
		
	-- calculate melee attack bonus by skill
	
	elseif t.Stat == const.Stats.MeleeAttack then
	
		local main = equipmentData.main
		local extra = equipmentData.extra
		
		if main.weapon then
			
			-- single wield
			if not equipmentData.dualWield then
				
				-- calculate old bonus
				
				local oldBonus = (oldWeaponSkillAttackBonuses[main.skill][main.rank] * main.level)
				
				-- calculate new bonus
				
				local newBonus = (newWeaponSkillAttackBonuses[main.skill][main.rank] * main.level)
				
				-- class bonus
			
				if main.skill == const.Skills.Blaster and blastersUseClassMultipliers then
					local rangedWeaponSkillAttackBonusMultiplier = classRangedWeaponSkillAttackBonusMultiplier[t.Player.Class]
					if rangedWeaponSkillAttackBonusMultiplier ~= nil then
						newBonus = newBonus * rangedWeaponSkillAttackBonusMultiplier
					end
				end
				
				-- recalculate bonus
				
				t.Result = t.Result - oldBonus + newBonus
				
			-- dual wield
			else
						
				-- calculate effective skill levels
				
				local mainEffectiveSkillLevel
				local extraEffectiveSkillLevel
				
				if main.skill == extra.skill then
					mainEffectiveSkillLevel = main.level
					extraEffectiveSkillLevel = extra.level
				else
					-- effective skill level is not divided by sqrt(2) anymore
					mainEffectiveSkillLevel = main.level
					extraEffectiveSkillLevel = extra.level
				end
			
				-- calculate old bonus
				
				local oldBonus = (oldWeaponSkillAttackBonuses[extra.skill][extra.rank] * main.level)
				
				-- calculate new bonus
				
				local newBonus = ((newWeaponSkillAttackBonuses[main.skill][main.rank] * mainEffectiveSkillLevel) + (newWeaponSkillAttackBonuses[extra.skill][extra.rank] * extraEffectiveSkillLevel))
			
				-- recalculate bonus
				
				t.Result = t.Result - oldBonus + newBonus
				
			end
			
		end
		
	-- calculate melee damage bonus by skill
	
	elseif t.Stat == const.Stats.MeleeDamageBase then
	
		local main = equipmentData.main
		local extra = equipmentData.extra
		local shield = equipmentData.shield
		if main.weapon then
			if shield.equipped then
				if classMeleeWeaponSkillDamageBonus[t.Player.Class] ~= nil then
					t.Result = t.Result + (classMeleeWeaponSkillDamageBonus[t.Player.Class] * shield.level)
				end
			end
			-- single wield
			
			if not equipmentData.dualWield then
				
				-- subtract old bonus
				
				if
					(main.skill == const.Skills.Axe and main.rank >= const.Master)
					or
					(main.skill == const.Skills.Spear and main.rank >= const.Master)
					or
					(main.skill == const.Skills.Mace and main.rank >= const.Expert)
				then
					t.Result = t.Result - main.level
				end
				
				-- add new bonus for main weapon
				
				t.Result = t.Result + newWeaponSkillDamageBonuses[main.skill][main.rank] * main.level

				
				-- add class bonus for main hand weapon
				
				if classMeleeWeaponSkillDamageBonus[t.Player.Class] ~= nil then
					t.Result = t.Result + (classMeleeWeaponSkillDamageBonus[t.Player.Class] * main.level)
				end
				
				-- add bonus for two handed weapon
				
				if equipmentData.twoHanded and equipmentData.main.skill ~= const.Skills.Staff then
					t.Result = t.Result + twoHandedWeaponDamageBonusByMastery[main.rank] * main.level
				end
				
			-- dual wield
			
			else
				
				-- calculate effective skill levels
				
				local mainEffectiveSkillLevel
				local extraEffectiveSkillLevel
				
				if main.skill == extra.skill then
					mainEffectiveSkillLevel = main.level
					extraEffectiveSkillLevel = extra.level
				else
					-- effective skill level is not divided by sqrt(2) anymore
					mainEffectiveSkillLevel = main.level
					extraEffectiveSkillLevel = extra.level
				end
			
				-- subtract old bonus
				
				if
					(main.skill == const.Skills.Axe and main.rank >= const.Master)
					or
					(main.skill == const.Skills.Spear and main.rank >= const.Master)
					or
					(main.skill == const.Skills.Mace and main.rank >= const.Expert)
				then
					t.Result = t.Result - main.level
				end
				local classMeleeDamageBonus = classMeleeWeaponSkillDamageBonus[t.Player.Class] or 0
				
				-- add new bonus for main weapon
				-- removing the class bonus from main hand if main hand sword or dagger
				if main.skill == const.Skills.Sword then
					t.Result = t.Result + (newWeaponSkillDamageBonuses[main.skill][main.rank] * mainEffectiveSkillLevel)-(classMeleeDamageBonus*mainEffectiveSkillLevel)
				elseif main.skill == const.Skills.Dagger then
					t.Result = t.Result + (newWeaponSkillDamageBonuses[main.skill][main.rank] * mainEffectiveSkillLevel)-(classMeleeDamageBonus*mainEffectiveSkillLevel)
				elseif main.skill == const.Skills.Staff then
					local punch=t.Player:GetSkill(const.Skills.Unarmed)
					local s,m = SplitSkill(punch)
					if m==4 then
						t.Result=t.Result-oldWeaponSkillDamageBonuses[const.Skills.Unarmed][m]*s
						t.Result=t.Result+newWeaponSkillDamageBonuses[const.Skills.Unarmed][m]*s
						t.Result = t.Result + (newWeaponSkillDamageBonuses[main.skill][main.rank] * mainEffectiveSkillLevel)
					end
				else
					t.Result = t.Result + (newWeaponSkillDamageBonuses[main.skill][main.rank] * mainEffectiveSkillLevel)
				end
				
				-- add new bonus for extra weapon if any
				
				if extra.weapon then
					t.Result = t.Result + math.round((newWeaponSkillDamageBonuses[extra.skill][extra.rank]+classMeleeDamageBonus) * (extraEffectiveSkillLevel))
				end
				
				-- add class bonus for main hand weapon
				
				if classMeleeWeaponSkillDamageBonus[t.Player.Class] ~= nil then
					t.Result = t.Result + (classMeleeDamageBonus * mainEffectiveSkillLevel)
				end
			
			end
		elseif not main.weapon and not extra.weapon then
			local punch=t.Player:GetSkill(const.Skills.Unarmed)
			local s,m = SplitSkill(punch)
			if m>0 then
				t.Result=t.Result-oldWeaponSkillDamageBonuses[const.Skills.Unarmed][m]*s
				t.Result=t.Result+newWeaponSkillDamageBonuses[const.Skills.Unarmed][m]*s		
			end
		end
		
	-- calculate AC bonus by skill
	
	elseif t.Stat == const.Stats.ArmorClass then
	
		-- AC bonus from weapon skill
		
		main = equipmentData.main
		
		if main.weapon then
		
			if main.skill == const.Skills.Staff then
			
				-- subtract old bonus
				
				if main.skill == const.Skills.Staff and main.rank >= const.Expert then
					t.Result = t.Result - main.level
				end
				
				-- add new bonus
				
				t.Result = t.Result + (newWeaponSkillACBonuses[const.Skills.Staff][main.rank] * main.level)
				
			-- spear grant AC again
			
			elseif main.skill == const.Skills.Spear then
			
				-- subtract old bonus
				
				if main.skill == const.Skills.Spear and main.rank >= const.Expert then
					t.Result = t.Result - main.level
				end
				
			
				
				-- add new bonus
				t.Result = t.Result + (newWeaponSkillACBonuses[const.Skills.Spear][main.rank] * main.level)
				--]]
				
			end
			
		end
		
		-- AC bonus from shield skill
		
		local shield = equipmentData.shield
		
		if shield.equipped then
		
			-- subtract old bonus
			local reduction=oldArmorSkillACBonuses[const.Skills.Shield][shield.rank] * shield.level
			t.Result = t.Result - reduction
			
			-- add new bonus
			
			t.Result = t.Result + (newArmorSkillACBonuses[shield.skill][shield.rank] * shield.level )
			
		end
		
		-- AC bonus from armor skill
		
		local armor = equipmentData.armor
		local dodge=t.Player:GetSkill(const.Skills.Dodging)
		if armor.equipped then
		
			-- subtract old bonus
			
			t.Result = t.Result - oldArmorSkillACBonuses[armor.skill][armor.rank]*armor.level
			
			-- add new bonus
			
			t.Result = t.Result + (newArmorSkillACBonuses[armor.skill][armor.rank] * armor.level)
			
			--check for dodge
			if armor.skill==const.Skills.Leather then
				if dodge>256 then
					s,m=SplitSkill(dodge)
					t.Result = t.Result - oldArmorSkillACBonuses[const.Skills.Dodging][m] * s
					t.Result = t.Result + newArmorSkillACBonuses[const.Skills.Dodging][m] * s
				end		
			end
		else
			s,m=SplitSkill(dodge)
			--calculate dodge
			if m>0 then
				t.Result = t.Result - oldArmorSkillACBonuses[const.Skills.Dodging][m] * s
				t.Result = t.Result + newArmorSkillACBonuses[const.Skills.Dodging][m] * s
			end
		end
		
	end
	
end


function events.CalcStatBonusByItems(t)

	local equipmentData = getPlayerEquipmentData(t.Player)
	
	local main = equipmentData.main
	local extra = equipmentData.extra
	local armor = equipmentData.armor
	local shield = equipmentData.shield
	
	-- calculate resistance
	
	if
		t.Stat == const.Stats.FireResistance
		or
		t.Stat == const.Stats.AirResistance
		or
		t.Stat == const.Stats.WaterResistance
		or
		t.Stat == const.Stats.EarthResistance
		or
		t.Stat == const.Stats.MindResistance
		or
		t.Stat == const.Stats.BodyResistance
	then
	
		-- resistance bonus from weapon
		
		for playerIndex = 0,#Party do
		
			local weaponResistancePlayer = Party.Players[playerIndex]
			local weaponResistancePlayerEquipmentData = getPlayerEquipmentData(weaponResistancePlayer)
			local weaponResistancePlayerMain = weaponResistancePlayerEquipmentData.main
			local weaponResistancePlayerExtra = weaponResistancePlayerEquipmentData.extra
		
			if weaponResistancePlayerMain.equipped and weaponResistancePlayerMain.weapon then
				t.Result = t.Result + (newWeaponSkillResistanceBonuses[weaponResistancePlayerMain.skill][weaponResistancePlayerMain.rank] * weaponResistancePlayerMain.level)
			end
			
			if weaponResistancePlayerExtra.equipped and weaponResistancePlayerExtra.weapon then
				t.Result = t.Result + (newWeaponSkillResistanceBonuses[weaponResistancePlayerExtra.skill][weaponResistancePlayerExtra.rank] * weaponResistancePlayerExtra.level)
			end
			
		end
		
		-- resistance bonus from armor
								
		if armor.equipped then
			t.Result = t.Result + (newArmorSkillResistanceBonuses[armor.skill][armor.rank] * armor.level)
		end	
		if shield.equipped then
			t.Result = t.Result + (newArmorSkillResistanceBonuses[shield.skill][shield.rank] * shield.level)
		end
	end
	
end

-- calculate new and old recovery difference
local function getWeaponRecoveryCorrection(equipmentData1, equipmentData2, player)

	local correction = 0
	
	-- single wield
	if equipmentData2 == nil then
	
		-- calculate old and new recovery bonuses
	
		local oldRecoveryBonus = 0
		local newRecoveryBonus = 0
	
		-- base bonuses
		
		oldRecoveryBonus = oldRecoveryBonus + oldWeaponBaseRecoveryBonuses[equipmentData1.skill]
		newRecoveryBonus = newRecoveryBonus + newWeaponBaseRecoveryBonuses[equipmentData1.skill]
		
		-- skill bonuses
		
		if equipmentData1.rank >= const.Expert then
			oldRecoveryBonus = oldRecoveryBonus + (oldWeaponSkillRecoveryBonuses[equipmentData1.skill][equipmentData1.rank] * equipmentData1.level)
		end
		newRecoveryBonus = newRecoveryBonus + (newWeaponSkillRecoveryBonuses[equipmentData1.skill][equipmentData1.rank] * equipmentData1.level)
		--add unarmed bonus
		if equipmentData1.skill==const.Skills.Staff and equipmentData1.rank==4 then
			local unarmed=t.Player:GetSkill(const.Skills.Unarmed)
			s,m=SplitSkill(unarmed)	
			if s>1 then
				newRecoveryBonus = newRecoveryBonus + newWeaponSkillRecoveryBonuses[const.Skills.Unarmed][m]*s
			end
		end
		-- replace old with new bonus

		correction = correction 
			+ oldRecoveryBonus
			- newRecoveryBonus
		
	-- dual wield
	else
	
		-- calculate effective skill levels
		
		local meleeWeapon1EffectiveSkillLevel
		local meleeWeapon2EffectiveSkillLevel
		
		if equipmentData1.skill == equipmentData2.skill then
			meleeWeapon1EffectiveSkillLevel = equipmentData1.level
			meleeWeapon2EffectiveSkillLevel = equipmentData2.level
		else
			-- effective skill level is not divided by sqrt(2) anymore
			meleeWeapon1EffectiveSkillLevel = equipmentData1.level
			meleeWeapon2EffectiveSkillLevel = equipmentData2.level
		end
	
		-- calculate old and new recovery bonuses
	
		local oldRecoveryBonus1 = 0
		local newRecoveryBonus1 = 0
		local newRecoveryBonus2 = 0
	
		-- weapon 1
		
		-- base bonuses
		
		oldRecoveryBonus1 = oldRecoveryBonus1 + oldWeaponBaseRecoveryBonuses[equipmentData1.skill]
		newRecoveryBonus1 = newRecoveryBonus1 + newWeaponBaseRecoveryBonuses[equipmentData1.skill]
		newRecoveryBonus2 = newRecoveryBonus2 + newWeaponBaseRecoveryBonuses[equipmentData2.skill]
		
		-- swiftness
		
		if equipmentData1.item.Bonus2 == 59 then
			oldRecoveryBonus1 = oldRecoveryBonus1 + 20
			newRecoveryBonus1 = newRecoveryBonus1 + 20
		end
		if equipmentData2.item.Bonus2 == 59 then
			newRecoveryBonus2 = newRecoveryBonus2 + 20
		end
		
		-- skill bonuses
		
		if equipmentData1.rank >= const.Expert then
			oldRecoveryBonus1 = oldRecoveryBonus1 + (oldWeaponSkillRecoveryBonuses[equipmentData1.skill][equipmentData1.rank] * equipmentData1.level)
		end
		newRecoveryBonus1 = (newRecoveryBonus1 + (newWeaponSkillRecoveryBonuses[equipmentData1.skill][equipmentData1.rank] * meleeWeapon1EffectiveSkillLevel))
		newRecoveryBonus2 = (newRecoveryBonus2 + (newWeaponSkillRecoveryBonuses[equipmentData2.skill][equipmentData2.rank] * meleeWeapon2EffectiveSkillLevel))
		
		-- replace old with new bonus
		
		correction = correction
			+ oldRecoveryBonus1
			- (newRecoveryBonus1 + newRecoveryBonus2)
		
	end
	
	return correction
	
end






meleeRecoveryCap=0


-- corrects attack delay

function events.GetAttackDelay(t)

	local equipmentData = getPlayerEquipmentData(t.Player)
	
	-- weapon
	
	if t.Ranged then
	
		local bow = equipmentData.bow
	
		if bow.weapon then
		
			t.Result = t.Result + getWeaponRecoveryCorrection(bow, nil, t.Player)
			
		end
		
	else
	
		local main = equipmentData.main
		local extra = equipmentData.extra
		
		if main.weapon then
			
			-- single wield
			if not equipmentData.dualWield then
				
				t.Result = t.Result + getWeaponRecoveryCorrection(main, nil, t.Player)
				
			-- dual wield
			else
			
				-- no axe and no sword in main hand and sword in extra hand = extra hand skill defines recovery
				if main.skill ~= const.Skills.Axe and main.skill ~= const.Skills.Sword and extra.skill == const.Skills.Sword then
					t.Result = t.Result + getWeaponRecoveryCorrection(extra, main, t.Player)
				-- everything else = main hand skill defines recovery
				else
					t.Result = t.Result + getWeaponRecoveryCorrection(main, extra, t.Player)
				end
				
			end
		else
			local unarmed=t.Player:GetSkill(const.Skills.Unarmed)
			s,m=SplitSkill(unarmed)	
			if s>1 then
				t.Result = t.Result - newWeaponSkillRecoveryBonuses[const.Skills.Unarmed][m]*s
			end		
		end
		
	end
	
	-- turn recovery time into a multiplier rather than divisor-
	
	local recoveryBonus = 100 - t.Result
	local correctedRecoveryTime = math.floor(100 / (1 + recoveryBonus / 100))
	
	t.Result = correctedRecoveryTime
	
	-- cap melee recovery
	
	if not t.Ranged then
		t.Result = math.max(meleeRecoveryCap, t.Result)
	end
	
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
	elseif RealTimeHoming==true then 
		if ownerKind ~= const.ObjectRefKind.Party and targetKind == const.ObjectRefKind.Nothing  then
			targetPosition = {["X"] = Party.X, ["Y"] = Party.Y, ["Z"] = Party.Z + 120, }
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
local homingProjectiles = true
function events.Tick()

	-- navigateMissiles
	if homingProjectiles then
		for objectIndex = 1,Map.Objects.high do
			local object =  Map.Objects[objectIndex]
			navigateMissile(object)
		end
	end
end

--BOW DAMAGE SKILL BONUS
function events.ModifyItemDamage(t)
    local s, m = SplitSkill(t.Player.Skills[const.Skills.Bow])
    if t.Item:T().EquipStat == const.ItemType.Missile - 1 then
		local dmgBonus=newWeaponSkillDamageBonuses[const.Skills.Bow][m]
		local might=t.Player:GetMight()
		if might<=21 then
			mightBonus=(might-1)/2-6
		else
			mightBonus=math.floor(might/5)
		end
        t.Result = t.Result + mightBonus +s * dmgBonus
    end
end
----------------------
--ARMSMASTER CODE, so far it's 2 damage at master and 4 at GM
----------------------
function events.CalcStatBonusBySkills(t)
	if t.Stat == const.Stats.MeleeDamageBase then  -- t.Result ~= 0 is for speedup
		local s, m = SplitSkill(t.Player:GetSkill(const.Skills.Armsmaster))
		if m == 3 then
			t.Result=t.Result+s
		elseif m ==4 then
			t.Result=t.Result+s*2
		end
	end
end


------------------------
--AUTO GENERATING TOOLTIPS
------------------------
function events.GameInitialized2()
	for i=0,33 do
		if i<=7 or i==33 then
			attack=false
			recovery=false
			damage=false
			ac=false
			res=false
			baseString=string.format("%s\n------------------------------------------------------------\n         ",Game.SkillDescriptions[i])
			for v=1,4 do
				if newWeaponSkillAttackBonuses[i][v]~=0 then
					attack=true
				end
				if newWeaponSkillRecoveryBonuses[i][v]~=0 then
					recovery=true
				end
				if newWeaponSkillDamageBonuses[i][v]~=0 then
					damage=true
				end
				if newWeaponSkillACBonuses[i][v]~=0 then
					ac=true
				end
				if newWeaponSkillResistanceBonuses[i][v]~=0 then
					res=true
				end
			end
			
			--Novice
			normal=""
			if attack then
				baseString=string.format("%s Attack|",baseString)
				normal=string.format("%s      %s|",normal,newWeaponSkillAttackBonuses[i][1])
			end
			if recovery then
				normal=string.format("%s      %s|",normal,newWeaponSkillRecoveryBonuses[i][1])
				baseString=string.format("%s Speed|",baseString)
			end
			if damage then
				normal=string.format("%s     %s|",normal,newWeaponSkillDamageBonuses[i][1])
				baseString=string.format("%s Dmg|",baseString)
			end
			if ac then
				normal=string.format("%s  %s|",normal,newWeaponSkillACBonuses[i][1])
				baseString=string.format("%s AC|",baseString)
			end
			if res then
				normal=string.format("%s    %s|",normal,newWeaponSkillResistanceBonuses[i][1])
				baseString=string.format("%s Res|",baseString)
			end
			Game.SkillDesNormal[i]=normal
			
			--Expert
			expert=""
			if attack then
				expert=string.format("%s      %s|",expert,newWeaponSkillAttackBonuses[i][2])
			end
			if recovery then
				expert=string.format("%s      %s|",expert,newWeaponSkillRecoveryBonuses[i][2])
			end
			if damage then
				expert=string.format("%s     %s|",expert,newWeaponSkillDamageBonuses[i][2])
			end
			if ac then
				expert=string.format("%s  %s|",expert,newWeaponSkillACBonuses[i][2])
			end
			if res then
				expert=string.format("%s    %s|",expert,newWeaponSkillResistanceBonuses[i][2])
			end
			Game.SkillDesExpert[i]=expert
			--Master
			master=""
			if attack then
				master=string.format("%s      %s|",master,newWeaponSkillAttackBonuses[i][3])
			end
			if recovery then
				master=string.format("%s      %s|",master,newWeaponSkillRecoveryBonuses[i][3])
			end
			if damage then
				master=string.format("%s     %s|",master,newWeaponSkillDamageBonuses[i][3])
			end
			if ac then
				master=string.format("%s  %s|",master,newWeaponSkillACBonuses[i][3])
			end
			if res then
				master=string.format("%s    %s|",master,newWeaponSkillResistanceBonuses[i][3])
			end
			Game.SkillDesMaster[i]=master
			--GrandMaster
			gm=""
			if attack then
				gm=string.format("%s      %s|",gm,newWeaponSkillAttackBonuses[i][4])
			end
			if recovery then
				gm=string.format("%s      %s|",gm,newWeaponSkillRecoveryBonuses[i][4])
			end
			if damage then
				gm=string.format("%s     %s|",gm,newWeaponSkillDamageBonuses[i][4])
			end
			if ac then
				gm=string.format("%s  %s|",gm,newWeaponSkillACBonuses[i][4])
			end
			if res then
				gm=string.format("%s    %s|",gm,newWeaponSkillResistanceBonuses[i][4])
			end
			Game.SkillDesGM[i]=gm
			Game.SkillDescriptions[i]=string.format("%s",baseString)
		end
	end
	

--now do same for armors
	for i=8,32 do
		if i<12 or i==32 then
			recoveryPen=false
			ac=false
			res=false
			baseString=string.format("%s\n------------------------------------------------------------\n         ",Game.SkillDescriptions[i])
			for v=1,4 do
				if newArmorSkillACBonuses[i][v]~=0 then
					ac=true
				end
				if newArmorSkillResistanceBonuses[i][v]~=0 then
					res=true
				end
			end
			
			--Novice
			normal=""
			if ac then
				normal=string.format("%s  %s|",normal,newArmorSkillACBonuses[i][1])
				baseString=string.format("%s AC|",baseString)
			end
			if res then
				normal=string.format("%s    %s|",normal,newArmorSkillResistanceBonuses[i][1])
				baseString=string.format("%s Res|",baseString)
			end
			Game.SkillDesNormal[i]=normal
			
			--Expert
			expert=""
			if ac then
				expert=string.format("%s  %s|",expert,newArmorSkillACBonuses[i][2])
			end
			if res then
				expert=string.format("%s    %s|",expert,newArmorSkillResistanceBonuses[i][2])
			end
			Game.SkillDesExpert[i]=expert
			--Master
			master=""
			if ac then
				master=string.format("%s  %s|",master,newArmorSkillACBonuses[i][3])
			end
			if res then
				master=string.format("%s    %s|",master,newArmorSkillResistanceBonuses[i][3])
			end
			Game.SkillDesMaster[i]=master
			--GrandMaster
			gm=""
			if ac then
				gm=string.format("%s  %s|",gm,newArmorSkillACBonuses[i][4])
			end
			if res then
				gm=string.format("%s    %s|",gm,newArmorSkillResistanceBonuses[i][4])
			end
			Game.SkillDesGM[i]=gm
			Game.SkillDescriptions[i]=string.format("%s",baseString)
		end
	end
	
	--adjust tooltips with special effects
	Game.SkillDesGM[const.Skills.Axe]=string.format("%s 1%% to halve AC",Game.SkillDesGM[const.Skills.Axe])
	Game.SkillDesMaster[const.Skills.Bow]=string.format("%s 2 arrows",Game.SkillDesMaster[const.Skills.Bow])
	Game.SkillDesExpert[const.Skills.Dagger]=string.format("%s can dual wield",Game.SkillDesExpert[const.Skills.Dagger])
	Game.SkillDesMaster[const.Skills.Mace]=string.format("%s 1%% to stun",Game.SkillDesMaster[const.Skills.Mace])
	Game.SkillDesGM[const.Skills.Mace]=string.format("%s 1%% to paralyze",Game.SkillDesGM[const.Skills.Mace])
	Game.SkillDesMaster[const.Skills.Spear]=string.format("%s can hold with 1 hand",Game.SkillDesMaster[const.Skills.Spear])
	Game.SkillDesMaster[const.Skills.Staff]=string.format("%s 1%% to stun",Game.SkillDesMaster[const.Skills.Staff])
	Game.SkillDesGM[const.Skills.Staff]=string.format("%s usable with Unarm.",Game.SkillDesGM[const.Skills.Staff])
	Game.SkillDesMaster[const.Skills.Sword]=string.format("%s can dual wield",Game.SkillDesMaster[const.Skills.Sword])
	Game.SkillDesExpert[const.Skills.Leather]=string.format("%s recovery penalty eliminated",Game.SkillDesExpert[const.Skills.Leather])
	Game.SkillDesExpert[const.Skills.Chain]=string.format("%s recovery penalty halved",Game.SkillDesExpert[const.Skills.Chain])
	Game.SkillDesMaster[const.Skills.Chain]=string.format("%s recovery penalty eliminated",Game.SkillDesMaster[const.Skills.Chain])
	Game.SkillDesExpert[const.Skills.Plate]=string.format("%s recovery penalty halved",Game.SkillDesExpert[const.Skills.Plate])
	Game.SkillDesGM[const.Skills.Plate]=string.format("%s recovery penalty eliminated",Game.SkillDesGM[const.Skills.Plate])
	Game.SkillDesExpert[const.Skills.Shield]=string.format("%s recovery penalty eliminated",Game.SkillDesExpert[const.Skills.Shield])
	Game.SkillDesGM[const.Skills.Shield]=string.format("%s halve dmg from phys projectiles",Game.SkillDesGM[const.Skills.Shield])
	Game.SkillDesMaster[const.Skills.Armsmaster]=string.format("Skills adds 2 damage to all melee weapons")
	Game.SkillDesGM[const.Skills.Dodging]=string.format("%s usable with Leather Armor",Game.SkillDesGM[const.Skills.Dodging])
	Game.SkillDesGM[const.Skills.Unarmed]=string.format("%s 5+0.5%% dodge chance",Game.SkillDesGM[const.Skills.Unarmed])
end

--REMOVE PLATE/MAIL physical damage reduction

function events.CalcDamageToPlayer(t)
	if t.DamageKind==const.Damage.Phys then
		if Party[0]:GetActiveItem(3) then
			local n=Party[0]:GetActiveItem(3).Number
			if Game.ItemsTxt[n].Skill==const.Skills.Plate then
				s,m=SplitSkill(t.Player.Skills[const.Skills.Plate])
				if m>=3 then
					t.Result=t.Result*2
				end
			elseif Game.ItemsTxt[n].Skill==const.Skills.Chain then
				s,m=SplitSkill(t.Player.Skills[const.Skills.Chain])
				if m>=4 then
					t.Result=t.Result/0.65
				end		
			end
		end
	end
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
	vars.chargeCooldown=vars.chargeCooldown or 25
	charge=false
	local function chargeTimer() 
		if vars.chargeCooldown>0 then
			vars.chargeCooldown=vars.chargeCooldown-1
		end
	end
	Timer(chargeTimer, const.Minute/2) 
end

--movement
function events.Tick()
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
				local healAmount=math.round(bonus^1.4)+10
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
				local spAmount=math.round(Bonus^1.4*2/3)+10
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
