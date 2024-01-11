function events.LoadMap()
	vars.PlayerBuffs=vars.PlayerBuffs or {}
	for i=0,Party.High do
		local index=Party[i]:GetIndex()
		if not vars.PlayerBuffs[index] then
			vars.PlayerBuffs[index]={}
			vars.PlayerBuffs[index]["weakness"]=0
			vars.PlayerBuffs[index]["disease"]=0
			vars.PlayerBuffs[index]["poison"]=0
			vars.PlayerBuffs[index]["sleep"]=0
			vars.PlayerBuffs[index]["fear"]=0
			vars.PlayerBuffs[index]["curse"]=0
			vars.PlayerBuffs[index]["insanity"]=0
			vars.PlayerBuffs[index]["paralysis"]=0
			vars.PlayerBuffs[index]["stone"]=0
		end
	end
end

function events.UseMouseItem(t)
	if t.Allow==true then
		local it=Mouse.Item
		local pl=Party[t.PlayerSlot]
		--healing potion
		if it.Number==222 then
			heal=math.round(it.Bonus^1.4)-it.Bonus
			pl.HP=math.min(pl:GetFullHP(),pl.HP+heal)
			return
		--mana potion
		elseif it.Number==223 then
			spRestore=math.round(it.Bonus^1.4*2/3)-it.Bonus
			pl.SP=math.min(pl:GetFullSP(),pl.SP+spRestore)
			return
		end
		if it.Number==253 then
			heal=math.round(it.Bonus^1.4*3+30)-it.Bonus*5
			pl.HP=math.min(pl:GetFullHP(),pl.HP+heal)
			return
		--mana potion
		elseif it.Number==254 then
			spRestore=math.round(it.Bonus^1.4*2)-it.Bonus*5
			pl.SP=math.min(pl:GetFullSP(),pl.SP+spRestore)
			return
		end
		
		------------------------
		--STATUS POTIONS--
		------------------------
		if itemImmunityMapping[it.Number] then 
			local txt=itemImmunityMapping[it.Number]
			vars.PlayerBuffs[Party[t.PlayerSlot]:GetIndex()][txt]=Game.Time+Const.Hour*6
		end
		--------------------
		--BUFFS--
		--------------------
		if itemBuffMapping[it.Number] then
			local buff=itemBuffMapping[it.Number]
			pl.SpellBuffs[buff].Power=it.Bonus+10
			pl.SpellBuffs[buff].ExpireTime=Game.Time+const.Minute*30*it.Bonus
			
			if it.Number<=234 and it.Number~=229 then
				pl.SpellBuffs[buff].Power=math.round(pl.SpellBuffs[buff].Power/2)
			end
		--disable original behaviour and simulate sound
			t.Allow=false
			pl:ShowFaceAnimation(36)
			evt.PlaySound(143)
			if it.Charges==0 then
				it.Charges=5
			elseif it.Charges>2 then
				it.Charges=it.Charges-1
			elseif it.Charges==2 then
				it.Number=0
			end
			return
		end
		-------------------------
		--PERMANENT BUFFS
		------------------------
		if it.Number==264 and not Party[0].UsedBlackPotions[it.Number] then
			pl.LuckBase=pl.LuckBase-20
		elseif it.Number==265 and not Party[0].UsedBlackPotions[it.Number] then
			pl.SpeedBase=pl.SpeedBase-20
		elseif it.Number==266 and not Party[0].UsedBlackPotions[it.Number] then
			pl.IntellectBase=pl.IntellectBase-20
		elseif it.Number==267 and not Party[0].UsedBlackPotions[it.Number] then
			pl.EnduranceBase=pl.EnduranceBase-20
		elseif it.Number==268 and not Party[0].UsedBlackPotions[it.Number] then
			pl.PersonalityBase=pl.PersonalityBase-20
		elseif it.Number==269 and not Party[0].UsedBlackPotions[it.Number] then
			pl.AccuracyBase=pl.AccuracyBase-20
		elseif it.Number==270 and not Party[0].UsedBlackPotions[it.Number] then
			pl.MightBase=pl.MightBase-20
		end		
	end
end

itemBuffMapping = {
	[228] = 7,	 --haste
	[229] = 8, 	 --heroism
    [230] = 1,	 --bless
    [234] = 14,  --stoneskin
    [240] = 19,  --might
    [241] = 17,  --intellect
    [242] = 20,  --personality
    [243] = 16,  --endurace
    [244] = 15,  --accuracy
    [245] = 21,  --speed
    [255] = 18,  --luck
	[256] = 5,   --Fire
	[257] = 0,   --Air
	[258] = 22,  --Water
	[259] = 3,   --Earth
	[260] = 9,   --Mind
	[261] = 2,   --Body
}
itemImmunityMapping = {
	[224] = "weakness",
	[225] = "disease",
	[226] = "poison",
	[227] = "sleep",
	[237] = "fear",
	[238] = "curse",
	[239] = "insanity",
	[251] = "paralysis",
	[262] = "stone",
}

itemPermanentBuffMapping = {
	[264] = "weakness",
	[225] = "disease",
	[226] = "poison",
	[227] = "sleep",
	[237] = "fear",
	[238] = "curse",
	[239] = "insanity",
	[251] = "paralysis",
	[262] = "stone",
}

function events.DoBadThingToPlayer(t)
	if t.Allow==true and vars.PlayerBuffs[t.Player:GetIndex()] then
		if t.Thing==1 then
			if vars.PlayerBuffs[t.Player:GetIndex()]["curse"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Curse Immunity")
			end
		elseif t.Thing==2 then
			if vars.PlayerBuffs[t.Player:GetIndex()]["weakness"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Weakness Immunity")
			end 
		elseif t.Thing==3 then
			if vars.PlayerBuffs[t.Player:GetIndex()]["sleep"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Forced Sleep Immunity")
			end 
		elseif t.Thing==5 then
			if vars.PlayerBuffs[t.Player:GetIndex()]["insanity"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Insanity Immunity")
			end 
		elseif t.Thing==6 or t.Thing==7 or t.Thing==8 then
			if vars.PlayerBuffs[t.Player:GetIndex()]["poison"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Poison Immunity")
			end 
		elseif t.Thing==9 or t.Thing==10 or t.Thing==11 then
			if vars.PlayerBuffs[t.Player:GetIndex()]["disease"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Disease Immunity")
			end 
		elseif t.Thing==12 then
			if vars.PlayerBuffs[t.Player:GetIndex()]["paralysis"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Paralysis Immunity")
			end 
		elseif t.Thing==15 then
			if vars.PlayerBuffs[t.Player:GetIndex()]["stone"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Petrify Immunity")
			end 
		elseif t.Thing==23 then
			if vars.PlayerBuffs[t.Player:GetIndex()]["fear"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Fear Immunity")
			end 
		end
	end
end

function events.BuildItemInformationBox(t)
	if potionText[t.Item.Number] then
		t.Description=potionText[t.Item.Number] .. "\n(To drink, pick the potion up and right-click over a character's portrait.  To mix, pick the potion up and right-click over another potion.)"
	end
	if t.Item.Number==222 then
		t.Description=StrColor(255,255,153,"Heals " .. math.round(t.Item.Bonus^1.4)+10 .. " Hit Points") .. "\n" .. t.Description
	end
	if t.Item.Number==223 then
		t.Description=StrColor(255,255,153,"Restores " .. math.round(t.Item.Bonus^1.4*2/3)+10 .. " Spell Points") .. "\n" .. t.Description
	end
	if t.Item.Number==253 then
		t.Description=StrColor(255,255,153,"Heals " .. math.round(t.Item.Bonus^1.4*3)+10 .. " Hit Points") .. "\n" .. t.Description
	end
	if t.Item.Number==254 then
		t.Description=StrColor(255,255,153,"Restores " .. math.round(t.Item.Bonus^1.4*2)+10 .. " Spell Points") .. "\n" .. t.Description
	end
	if itemBuffMapping[t.Item.Number] then
		local charges=t.Item.Charges-1
		if charges==-1 then
			charges=5
		end
		t.Description=StrColor(255,255,153,"Charges: " .. charges) .. "\n" .. t.Description
	end
end


potionText={
	[222] = "",
	[223] = "",
	[224] = "Cures and prevents Weakness for 6 hours.",
	[225] = "Cures and prevents Disease for 6 hours.",
	[226] = "Cures and prevents Poison for 6 hours.",
	[227] = "Remove and prevents inducted Sleep for 6 hours.",
	[228] = "Increases Speed for 30 minutes per point of potion strength. (30 minutes per potion strength)",
	[229] = "Increases Melee damage by 10+(1 x Power) for (30 x Power) minutes",
	[230] = "Increases Attack by 5+(0.5 x Power) for (30 x Power) minutes",
	[231] = "Grants Preservation (as the spell) for 30 minutes per point of potion strength.",
	[232] = "Grants Shield (as the spell) for 30 minutes per point of potion strength.",
	[233] = "Grants Recharge Item (as the spell).",
	[234] = "Increases Armor Class  by 5+(0.5 x Power) for (30 x Power) minutes",
	[235] = "Prevents drowning damage.",
	[236] = "Increases item's roughness, making it more resistant to breaking.",
	[237] = "Cures and prevents Fear for 6 hours.",
	[238] = "Cures and prevents Curse for 6 hours.",
	[239] = "Cures and prevents Insanity for 6 hours.",
	[240] = "Temporarily increases Might by 10+(1 x Power) for (30 x Power) minutes",
	[241] = "Temporarily increases Intellect by 10+(1 x Power) for (30 x Power) minutes",
	[242] = "Temporarily increases Personality by 10+(1 x Power) for (30 x Power) minutes",
	[243] = "Temporarily increases Endurance by 10+(1 x Power) for (30 x Power) minutes",
	[244] = "Temporarily increases Speed by 10+(1 x Power) for (30 x Power) minutes",
	[245] = "Temporarily increases Accuracy by 10+(1 x Power) for (30 x Power) minutes",
	[246] = "Adds 'of Flame' property to a weapon.",
	[247] = "Adds 'of Frost' property to a weapon.",
	[248] = "Adds 'of Poison' property to a weapon.",
	[249] = "Adds 'of Sparks' property to a weapon.",
	[250] = "Adds 'of Swiftness' property to a weapon.",
	[251] = "Cures and prevents Paralysis for 6 hours.",
	[252] = "Removes all conditions except Dead, Stoned, or Eradicated.",
	[253] = "",
	[254] = "",
	[255] = "Increases temporary Luck by 10+(1 x Power) for (30 x Power) minutes",
	[256] = "Increases temporary Fire resistance by by 20+(1 x Power) for (30 x Power) minutes",
	[257] = "Increases temporary Air resistance by 20+(1 x Power) for (30 x Power) minutes",
	[258] = "Increases temporary Water resistance by 20+(1 x Power) for (30 x Power) minutes",
	[259] = "Increases temporary Earth resistance by 20+(1 x Power) for (30 x Power) minutes",
	[260] = "Increases temporary Mind resistance by 20+(1 x Power) for (30 x Power) minutes",
	[261] = "Increases temporary Body resistance by 20+(1 x Power) for (30 x Power) minutes",
	[262] = "Cures Stoned condition.",
	[263] = "Adds a permanent random Superior Elemental Damage Enchantment to a weapon.",
	[264] = "Adds 30 to permanent Luck.",
	[265] = "Adds 30 to permanent Speed.",
	[266] = "Adds 30 to permanent Intellect.",
	[267] = "Adds 30 to permanent Endurance.",
	[268] = "Adds 30 to permanent Personality.",
	[269] = "Adds 30 to permanent Accuracy.",
	[270] = "Adds 30 to permanent Might.",
	[271] = "Removes all unnatural aging, 10 years of PERMANENT aging, reduces all stats by 5.",

	[279] = "Permanently adds 5 to all seven stats, HP, SP, AC and resistances at the cost of 10 years of PERMANENT aging",
	[280] = "Increases all Seven Statistics temporarily by 10+(1 x Power) for (30 x Power) minutes",
	[281] = "Increases Fire, Air, Water, Earth, Mind and Body resistances temporarily by 10+ (1 x Power) for (30 x Power) minutes",
	[282] = "Increases the character's level by 10+0.25 per power for (30 x Power) minutes",
}




--rework to reagents
reagentList={
	--mm8
	[200] = 1, [201] = 5, [202] = 10, [203] = 20, [204] = 30, --red
	[205] = 1, [206] = 5, [207] = 10, [208] = 20, [209] = 30, --blue
	[210] = 1, [211] = 5, [212] = 10, [213] = 20, [214] = 30, --yellow
	[215] = 1, [216] = 5, [217] = 10, [218] = 20, [219] = 45, --gray
	--mm7
	[1002] = 1, [1003] = 5, [1004] = 10, [1005] = 20, [1006] = 30, --red
	[1007] = 1, [1008] = 5, [1009] = 10, [1010] = 20, [1011] = 30, --blue
	[1012] = 1, [1013] = 5, [1014] = 10, [1015] = 20, [1016] = 30, --yellow
	[1017] = 1, [1018] = 5, [1019] = 10, [1020] = 20, [1021] = 45, --gray
	--mm6
	[1762] = 1, [1763] = 1, [1764] = 1,
}
function events.Tick()
	if Game.CurrentPlayer<0 then 
		return
	end
	if lastModifiedReagent and lastModifiedReagent~=0 then
		Game.ItemsTxt[lastModifiedReagent].Mod1DiceCount=reagentList[lastModifiedReagent]
	end
	if reagentList[Mouse.Item.Number] then
		local it=Game.ItemsTxt[Mouse.Item.Number]
		if Mouse.Item.Bonus>0 then
			it.Mod1DiceCount=math.floor(reagentList[Mouse.Item.Number]*((Mouse.Item.Bonus*0.75)/20+1)+Mouse.Item.Bonus*0.75)
		end
		local alc=Party[Game.CurrentPlayer]:GetSkill(const.Skills.Alchemy)
		s,m=SplitSkill(alc)
		if m==3 then
			it.Mod1DiceCount=it.Mod1DiceCount+s*0.5
		elseif m==4 then
			it.Mod1DiceCount=it.Mod1DiceCount+s
		end
		lastModifiedReagent=Mouse.Item.Number
	end
end


function events.BuildItemInformationBox(t)
	if reagentList[t.Item.Number] then
		local bonus=math.round(reagentList[t.Item.Number] *((t.Item.Bonus*0.75)/20+1)+t.Item.Bonus*0.75)
		t.Enchantment="Power: " .. bonus
	end
end

--add scaling effect on reagents
function events.ItemGenerated(t)
	if Map.MapStatsIndex==0 then return end
	if t.Strength==7 then 
		return
	end
	if reagentList[t.Item.Number] then
		t.Handled=true
		--calculate party level
		currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
		if currentWorld==1 then
			partyLevel=vars.MM7LVL+vars.MM6LVL
		elseif currentWorld==2 then
			partyLevel=vars.MM8LVL+vars.MM6LVL
		elseif currentWorld==3 then
			partyLevel=vars.MM8LVL+vars.MM7LVL
		end
		--ADD MAX CHARGES BASED ON PARTY LEVEL
		t.Item.Bonus=math.min(math.floor(partyLevel/5),255)
	end
end


function events.MonsterKilled(mon)
	if mon.Ally == 9999 then -- no drop from reanimated monsters
		return
	end
	dropPossible=false
	for i=0,Party.High do
		s,m = SplitSkill(Party[i].Skills[const.Skills.Alchemy])
		if m>=3 then
			dropPossible=true
			chance=(m-2)/40
		end
	end
	if dropPossible and math.random()<chance then
		-- check bolster level
		currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
		if currentWorld==1 then
			partyLevel=vars.MM7LVL+vars.MM6LVL
		elseif currentWorld==2 then
			partyLevel=vars.MM8LVL+vars.MM6LVL
		elseif currentWorld==3 then
			partyLevel=vars.MM8LVL+vars.MM7LVL
		elseif currentWorld==4 then
			partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
		end
		--determine level
		local lvl=basetable[mon.Id].Level
		tier=math.round(math.min(math.max((lvl/20)*(math.random()/2+0.75),1),5))
		roll=math.random(1,#reagentDropTable[tier])
		reagent=reagentDropTable[tier][roll]	
		obj = SummonItem(reagent, mon.X, mon.Y, mon.Z + 100, 100)
		if obj then
			obj.Item.Bonus=math.round(partyLevel/3)
		end
	end
end

reagentDropTable={}
reagentDropTable[1]={200,205,210,215,1002,1007,1012,1017}
reagentDropTable[2]={201,206,211,216,1003,1008,1013,1018}
reagentDropTable[3]={202,207,212,217,1004,1009,1014,1019}
reagentDropTable[4]={203,208,213,218,1005,1010,1015,1020}
reagentDropTable[5]={204,209,214,219,1006,1011,1016,1021}
function events.GameInitialized2()
	Game.SkillDescriptions[const.Skills.Alchemy]=Game.SkillDescriptions[const.Skills.Alchemy] .. "\n\nMaster will grant a small chance (2.5%) to drop random reagents from Monsters.\nAt GM this chance is doubled."
	Game.SkillDesMaster[const.Skills.Alchemy]="Allows to make white potions. Power when mixing will be increased to 1.5 per skill point."
	Game.SkillDesMaster[const.Skills.Alchemy]="Allows to make white potions. Power when mixing will be increased to 1.5 per skill point."
	Game.SkillDesGM[const.Skills.Alchemy]="Allows to make black potions. Power when mixing will be increased to 2 per skill point."
end
function events.BuildItemInformationBox(t)
	if t.Item.Number>=1051 and t.Item.Number<=1060 then
		if t.Description then
			local mult=math.max((Game.BolsterAmount-100)/500+1,1)
			local tier=(t.Item.Number-1050)*mult
			local power = math.round((tier * 10) ^ 0.5 / 2, 0)
			local twoHanded = tier * 10 * 2 .. " - " .. power * 2
			local bodyArmor = math.floor(tier * 1.5 * 10) .. " - " .. math.floor(power * 1.5)
			local helmEtc = math.floor(tier * 1.25 * 10) .. " - " .. math.floor(power * 1.25)
			local rings = math.floor(tier * 0.75 * 10) .. " - " .. math.floor(power * 0.75)

			t.Description = "A special Gem that allows to increase an item Enchant Strength (right-click on an item with a base enchant to use)\n\nMax Power: " 
			.. StrColor(255, 128, 0, tostring(tier * 10)) 
			.. "\nBonus: " .. StrColor(255, 128, 0, tostring(power)) 
			.. "\n\nItem Modifier:\nTwo Handed Weapons: " .. StrColor(255, 128, 0, twoHanded)
			.. "\nBody Armor: " .. StrColor(255, 128, 0, bodyArmor)
			.. "\nHelm-Boots-Gloves-Bow: " .. StrColor(255, 128, 0, helmEtc)
			.. "\nRings: " .. StrColor(255, 128, 0, rings)
		end
	end
end

for i=1,10 do
	evt.PotionEffects[70+i] = function(IsDrunk, t, Power)
		if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) then
			if t.Bonus==0 and t.Charges<=1000 then 
				return
			end
			
			if craftWaitTime>0 then return end
			--pick which enchant to pick that is below the item power
			local bolsterMult=math.max((Game.BolsterAmount-100)/500+1,1)
			tier=(Mouse.Item.Number-1050)*bolsterMult
			mult=slotMult[t:T().EquipStat]
			maxStrength=math.floor(tier*10*mult)
			upgradeAmount=math.round(maxStrength^0.5/2)
			if t.BonusStrength>=maxStrength and t.Charges%1000>=maxStrength then 
				Game.ShowStatusText("Gem power is not enough")
				return
			end
			baseEnchantValue=t.BonusStrength
			--check for special enchant
			if t.Bonus>=17 then
				skillMaxStrength=math.floor(math.max((tier*10)^0.5*mult, math.round(tier*mult)))
				if t.BonusStrength<skillMaxStrength then
					t.BonusStrength=t.BonusStrength+1
					if Mouse.Item.Charges<=1 then
						Mouse.Item.Number=0
					else
						Mouse.Item.Charges=Mouse.Item.Charges-1
						enchanted=true
					end
					mem.u4[0x51E100] = 0x100 
					t.Condition = t.Condition:Or(0x10)
					evt.PlaySound(12070)
					return
				else
					baseEnchantValue=math.huge
				end
			end
			if baseEnchantValue<=t.Charges%1000 or (t.Charges<=1000 and baseEnchantValue<maxStrength) then
				t.BonusStrength=math.min(t.BonusStrength+upgradeAmount,maxStrength)
			elseif t.Charges%1000<maxStrength and t.Charges>1000 then
				newBonus=math.min(t.Charges%1000+upgradeAmount,maxStrength)
				t.Charges=t.Charges-t.Charges%1000+newBonus
			else
				Game.ShowStatusText("Gem power is not enough")
				return
			end
			if Mouse.Item.Charges<=1 then
				Mouse.Item.Number=0
			else
				Mouse.Item.Charges=Mouse.Item.Charges-1
				enchanted=true
			end
			mem.u4[0x51E100] = 0x100 
			t.Condition = t.Condition:Or(0x10)
			evt.PlaySound(12070)
		end
	end
end

function events.GameInitialized2()
	craftWaitTime=craftWaitTime or 0
end
function events.Tick()
	if enchanted then
		craftWaitTime=30
		enchanted=false
	end
	if craftWaitTime>0 then
		craftWaitTime=craftWaitTime-1
	end
end

evt.PotionEffects[81] = function(IsDrunk, t, Power)
	if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) then
		if t.Bonus2~=0 then 
			return
		end
		n=t.Number
		c=Game.ItemsTxt[n].EquipStat
		math.randomseed(t.Number*10000+t.MaxCharges*1000+t.Bonus*100+t.BonusStrength*10+t.Charges)
		if c<12 then
			power=6
			totB2=itemStrength[power][c]
			roll=math.random(1,totB2)
			tot=0
			for i=0,Game.SpcItemsTxt.High do
				if roll<=tot then
					t.Bonus2=i
					goto continue
				elseif table.find(enchants[power], Game.SpcItemsTxt[i].Lvl) then
					tot=tot+Game.SpcItemsTxt[i].ChanceForSlot[c]
				end
			end	
		end			
		::continue::
		Mouse.Item.Number=0
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end

evt.PotionEffects[82] = function(IsDrunk, t, Power)
	if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) then
		if t.Charges>1000 or t.BonusStrength==0 then 
			return
		end
		math.randomseed(t.Number*10000+t.MaxCharges*1000+t.Bonus*100+t.BonusStrength*10+t.Charges)
		t.Charges=math.random(1,16)*1000+math.min(math.round(t.BonusStrength*(1+0.25*math.random())),100)
		Mouse.Item.Number=0
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end

evt.PotionEffects[83] = function(IsDrunk, t, Power)
	if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) and t.MaxCharges<55 then
		t.MaxCharges=math.min(t.MaxCharges+2,55)
		Mouse.Item.Number=0
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end

evt.PotionEffects[84] = function(IsDrunk, t, Power)
	if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) then
		Mouse.Item.Number=t.Number
		Mouse.Item.Bonus=t.Bonus
		Mouse.Item.BonusStrength=t.BonusStrength
		Mouse.Item.Charges=t.Charges
		Mouse.Item.Bonus2=t.Bonus2
		Mouse.Item.MaxCharges=t.MaxCharges
		Mouse.Item.BonusExpireTime=t.BonusExpireTime
		
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end


craftDropChances={
		["gems"]=0.005,
		[1061]=0.000125,
		[1062]=0.000125,
		[1063]=0.00125,
		[1064]=0.0001,
	}
function events.MonsterKilled(mon)
	if mon.Ally == 9999 then -- no drop from reanimated monsters
		return
	end
	--level bonus
	partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
	bonusRoll=1+partyLevel/200
	if Multiplayer and Multiplayer.client_monsters()[0] then
		bonusRoll=bonusRoll/(1+#Multiplayer.client_monsters())
	end
	--pick base craft material
	baseCraftDrop=false
	if math.random()<craftDropChances.gems*bonusRoll then
		baseCraftDrop=true
		craftStrength=mon.Level/25+(math.random(0,50)-25)/25+1
		craftStrength=math.max(math.min(craftStrength,10),1)
		crafMaterialNumber=1050+craftStrength
	end	
	if baseCraftDrop then
		obj = SummonItem(crafMaterialNumber, mon.X, mon.Y, mon.Z + 100, 100)
		if obj then
			obj.Item.Charges=1
		end
	end
	--pick special drop
	if math.random()<craftDropChances[1061]*bonusRoll then
		obj = SummonItem(1061, mon.X, mon.Y, mon.Z + 100, 100)
	end
	if math.random()<craftDropChances[1062]*bonusRoll then
		obj = SummonItem(1062, mon.X, mon.Y, mon.Z + 100, 100)
	end
	if math.random()<craftDropChances[1063]*bonusRoll then
		obj = SummonItem(1063, mon.X, mon.Y, mon.Z + 100, 100)
	end
	if math.random()<craftDropChances[1064]*bonusRoll then
		obj = SummonItem(1064, mon.X, mon.Y, mon.Z + 100, 100)
	end
end

