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
}
newWeaponSkillAttackBonuses =
{
	[const.Skills.Staff]	= {1, 2, 2, 2,},
	[const.Skills.Sword]	= {1, 2, 2, 2,},
	[const.Skills.Dagger]	= {1, 2, 2, 2,},
	[const.Skills.Axe]		= {1, 2, 2, 2,},
	[const.Skills.Spear]	= {1, 2, 3, 3,},
	[const.Skills.Bow]		= {3, 3, 3, 3,},
	[const.Skills.Mace]		= {1, 2, 2, 2,},
	[const.Skills.Blaster]	= {5, 10, 15, 25,},
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
}
newWeaponSkillRecoveryBonuses =
{
	[const.Skills.Staff]	= {0, 0, 0, 0,},
	[const.Skills.Sword]	= {0, 2, 2, 2,},
	[const.Skills.Dagger]	= {0, 0, 1, 1,},
	[const.Skills.Axe]		= {0, 2, 2, 2,},
	[const.Skills.Spear]	= {0, 0, 0, 0,},
	[const.Skills.Bow]		= {1, 2, 2, 2,},
	[const.Skills.Mace]		= {0, 0, 0, 0,},
	[const.Skills.Blaster]	= {0, 0, 0, 0,},
}
-- weapon skill damage bonuses (by rank)

oldWeaponSkillDamageBonuses =
{
	[const.Skills.Staff]	= {0, 0, 0, 1},
	[const.Skills.Sword]	= {0, 0, 0, 0},
	[const.Skills.Dagger]	= {0, 0, 0, 1},
	[const.Skills.Axe]		= {0, 0, 1, 1},
	[const.Skills.Spear]	= {0, 0, 1, 1},
	[const.Skills.Bow]		= {0, 0, 0, 1},
	[const.Skills.Mace]		= {0, 1, 1, 1},
	[const.Skills.Blaster]	= {0, 0, 0, 0},
}
newWeaponSkillDamageBonuses =
{
	[const.Skills.Staff]	= {0, 0, 1, 1,},
	[const.Skills.Sword]	= {0, 0, 1, 1,},
	[const.Skills.Dagger]	= {0, 0, 0, 1,},
	[const.Skills.Axe]		= {0, 1, 2, 2,},
	[const.Skills.Spear]	= {0, 1, 2, 2,},
	[const.Skills.Bow]		= {1, 2, 2, 2,},
	[const.Skills.Mace]		= {0, 1, 2, 2,},
	[const.Skills.Blaster]	= {0, 0, 0, 0,},
}
-- weapon skill AC bonuses (by rank)

oldWeaponSkillACBonuses =
{
	[const.Skills.Staff]	= {0, 1, 1, 1,},
	[const.Skills.Sword]	= {0, 0, 0, 1,},
	[const.Skills.Dagger]	= {0, 0, 0, 0,},
	[const.Skills.Axe]		= {0, 0, 0, 0,},
	[const.Skills.Spear]	= {0, 1, 1, 1,},
	[const.Skills.Bow]		= {0, 0, 0, 0,},
	[const.Skills.Mace]		= {0, 0, 0, 0,},
	[const.Skills.Blaster]	= {0, 0, 0, 0,},
}
newWeaponSkillACBonuses =
{
	[const.Skills.Staff]	= {2, 2, 2, 2,},
	[const.Skills.Sword]	= {0, 0, 0, 1,},
	[const.Skills.Dagger]	= {0, 0, 0, 0,},
	[const.Skills.Axe]		= {0, 0, 0, 0,},
	[const.Skills.Spear]	= {0, 2, 4, 6,},
	[const.Skills.Bow]		= {0, 0, 0, 0,},
	[const.Skills.Mace]		= {0, 0, 0, 0,},
	[const.Skills.Blaster]	= {0, 0, 0, 0,},
}
newWeaponSkillResistanceBonuses =
{
	[const.Skills.Staff]	= {0, 1, 2, },
	[const.Skills.Sword]	= {0, 0, 0, },
	[const.Skills.Dagger]	= {0, 0, 0, },
	[const.Skills.Axe]		= {0, 0, 0, },
	[const.Skills.Spear]	= {0, 0, 0, },
	[const.Skills.Bow]		= {0, 0, 0, },
	[const.Skills.Mace]		= {0, 0, 0, },
	[const.Skills.Blaster]	= {0, 0, 0, },
}
-- armor skill AC bonuses (by rank)

newArmorSkillACBonuses =
{
	[const.Skills.Shield]	= {1, 2, 3, 5,},
	[const.Skills.Leather]	= {1, 2, 3, 3,},
	[const.Skills.Chain]	= {2, 3, 4, 5,},
	[const.Skills.Plate]	= {3, 4, 5, 7,},
}
-- armor skill resistance bonuses (by rank)

newArmorSkillResistanceBonuses =
{
	[const.Skills.Leather]	= {2, 4, 6, 9,},
	[const.Skills.Chain]	= {2, 3, 4, 6,},
	[const.Skills.Plate]	= {0, 1, 2, 3,},
}

twoHandedWeaponDamageBonus = 3
twoHandedWeaponDamageBonusByMastery = {[const.Novice] = twoHandedWeaponDamageBonus/3, [const.Expert] = twoHandedWeaponDamageBonus/3*2, [const.Master] = twoHandedWeaponDamageBonus, }

classMeleeWeaponSkillDamageBonus ={[const.Class.Knight]=10,}
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
		
		if equipmentData.main.skill >= 0 then
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
			
			t.Result = t.Result + newWeaponSkillDamageBonuses[bow.skill][bow.rank] * bow.level
			
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
				
				--[[ add class bonus for extra hand weapon if any and different from main weapon
				
				if extra.weapon and extra.skill ~= main.skill then
					if classMeleeWeaponSkillDamageBonus[t.Player.Class] ~= nil then
						t.Result = t.Result + math.round(classMeleeWeaponSkillDamageBonus[t.Player.Class] * extraEffectiveSkillLevel)
					end
				end
				]]
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
			
			t.Result = t.Result - shield.rank * shield.level
			
			-- add new bonus
			
			t.Result = t.Result + (newArmorSkillACBonuses[shield.skill][shield.rank] * shield.level * (shieldDoubleSkillEffectForKnights and table.find(knightClasses, t.Player.Class) and 2 or 1))
			
		end
		
		-- AC bonus from armor skill
		
		local armor = equipmentData.armor
		
		if armor.equipped then
		
			-- subtract old bonus
			
			t.Result = t.Result - armor.level
			
			-- add new bonus
			
			t.Result = t.Result + (newArmorSkillACBonuses[armor.skill][armor.rank] * armor.level)
			
		end
		
	end
	
end


function events.CalcStatBonusByItems(t)

	local equipmentData = getPlayerEquipmentData(t.Player)
	
	local main = equipmentData.main
	local extra = equipmentData.extra
	local armor = equipmentData.armor
	
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
		
		for playerIndex = 0,3 do
		
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
		
	end
	
end