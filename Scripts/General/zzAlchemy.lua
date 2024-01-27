function events.GameInitialized2()
	for i=252, 263 do
		Game.ItemsTxt[i].Picture="item182"
	end
	
	for i=264,299 do
		Game.ItemsTxt[i].Name="Potion Deleted in MAW"
	end
end

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
	vars.BlackPotions=vars.BlackPotions or {}
end

function events.UseMouseItem(t)
	--override
	local it=Mouse.Item
	if it.Number<221 or it.Number>=300 then return end
	t.Allow=false
	local pl=Party[t.PlayerSlot]
	local index=pl:GetIndex()
	
	--check power
	if potionPowerRequirement[it.Number] and potionPowerRequirement[it.Number]>Mouse.Item.Bonus then
		Game.ShowStatusText("This potion has not enough power")
		return
	end
	--healing potion
	if it.Number==222 then
		heal=math.round(it.Bonus^1.4)-it.Bonus
		pl.HP=math.min(pl:GetFullHP(),pl.HP+heal)
	--mana potion
	elseif it.Number==223 then
		spRestore=math.round(it.Bonus^1.4*2/3)-it.Bonus
		pl.SP=math.min(pl:GetFullSP(),pl.SP+spRestore)
	end
	if it.Number==246 then
		heal=math.round(it.Bonus^1.4*3+30)-it.Bonus*5
		pl.HP=math.min(pl:GetFullHP(),pl.HP+heal)
	--mana potion
	elseif it.Number==247 then
		spRestore=math.round(it.Bonus^1.4*2)-it.Bonus*5
		pl.SP=math.min(pl:GetFullSP(),pl.SP+spRestore)
	end
	--Regen
	if it.Number==233 then
		Buff=pl.SpellBuffs[const.PlayerBuff.Regeneration]
		Buff.ExpireTime = Game.Time+const.Hour*6
		Buff.Skill=JoinSkill(it.Bonus/2,4)
	end
	--mana regen
	if it.Number==232 then
		vars.bonusMeditation=vars.bonusMeditation or {}
		vars.bonusMeditation[index]={Game.Time+const.Hour*6, it.Bonus/10 + 2}
	end
	------------------------
	--STATUS IMMUNITY POTIONS--
	------------------------
	if it.Number==237 then
		Party.SpellBuffs[13].ExpireTime=Game.Time+const.Hour*6
		Party.SpellBuffs[13].Power=5+math.floor(it.Bonus/10)
		Party.SpellBuffs[13].Skill=3
		if it.Bonus>=55 then
			Party.SpellBuffs[13].Skill=4
		end
	end
	
	if itemImmunityMapping[it.Number] then 
		for i=1,#itemImmunityMapping[it.Number] do
			local txt=itemImmunityMapping[it.Number][i]
			vars.PlayerBuffs[index][txt]=Game.Time+Const.Hour*6
		end
	end
	--------------------
	--BUFFS--
	--------------------
	if itemBuffMapping[it.Number] then
		local buff=itemBuffMapping[it.Number]
		if type(buff)=="table" then
			for i=1,#buff do
				buffID=itemBuffMapping[it.Number][i]
				pl.SpellBuffs[buffID].Power=it.Bonus+10
				pl.SpellBuffs[buffID].ExpireTime=Game.Time+const.Hour*6
			end
		else
			pl.SpellBuffs[buff].Power=it.Bonus+10
			pl.SpellBuffs[buff].ExpireTime=Game.Time+const.Hour*6
		end
		--half effect for bless, heroism and stoneskin
		if (it.Number<=234 and it.Number~=229) or it.Number==250 or  it.Number==251 then
			pl.SpellBuffs[buff].Power=math.round(pl.SpellBuffs[buff].Power/2)
		end
	end
	
	
	-------------------------
	--PERMANENT BUFFS
	------------------------	
	if blackPermanentBuffs[it.Number] then
		--create vars if not in yet
		if not vars.BlackPotions[index] then
			vars.BlackPotions[index]={}
			for key,_ in pairs(blackPermanentBuffs) do 
				for key2,value2 in pairs(blackPermanentBuffs[key]) do
					vars.BlackPotions[index][value2]=0
				end
			end
		end
		--effect
		local power=math.min(math.floor(it.Bonus/55),3)*20
		if it.Number==261 or it.Number==262 then
			power=power*1.5
		end
		for i=1,#blackPermanentBuffs[it.Number] do
			local stat=blackPermanentBuffs[it.Number][i]
			if power>vars.BlackPotions[index][stat] then
				local buff=power-vars.BlackPotions[index][stat]
				pl[stat]=pl[stat]+buff
				vars.BlackPotions[index][stat]=buff
			else
				Game.ShowStatusText("Can't benefit anymore")
				return
			end
		end
	end	
	
	--age potions
	if it.Number==258 then
		pl.BirthYear=1172-20+math.floor(Game.Time/const.Year)
		Party[0].AgeBonus=0
	end
	if it.Number==260 then
		pl.BirthYear=1172-80+math.floor(Game.Time/const.Year)
		Party[0].AgeBonus=0
	end
	
	--exp potion
	if it.Number==259 then
		local experience=it.Bonus*1000
		pl.Exp=pl.Exp+experience
	end
	
	--consume
	if potionUsingCharges[Mouse.Item.Number] then
		if Mouse.Item.Charges==0 then
			Mouse.Item.Charges=5
		elseif Mouse.Item.Charges>2 then
			Mouse.Item.Charges=Mouse.Item.Charges-1
		elseif Mouse.Item.Charges==2 then
			Mouse.Item.Number=0
		end
	else
		Mouse.Item.Number=0
	end	
	pl:ShowFaceAnimation(36)
	evt.PlaySound(143)
end

function events.GetSkill(t)
	if t.Skill==const.Skills.Meditation then
		if vars and vars.bonusMeditation and vars.bonusMeditation[t.PlayerIndex] and vars.bonusMeditation[t.PlayerIndex][1]>Game.Time then
			t.Result=t.Result+vars.bonusMeditation[t.PlayerIndex][2]
		end
	end
end

potionUsingCharges={228,229,230,231,232,234,235,236,239,240,241,248,249,250,251,257,258}
potionPowerRequirement={
	[231]=20,
	[235]=20,
	[236]=20,
	[239]=20,
	[245]=40,
	[256]=55,
	[263]=55,
}
blackPermanentBuffs={
	[252]={"MightBase","AccuracyBase"},
	[253]={"IntellectBase","PersonalityBase"},
	[254]={"EnduranceBase","SpeedBase","LuckBase"},
	[261]={"FireResistanceBase","AirResistanceBase","WaterResistanceBase","EarthResistanceBase"},
	[262]={"MindResistanceBase","BodyResistanceBase"},
}
itemBuffMapping = {
	[228] = 7,	 --haste
	[229] = 8, 	 --heroism
    [230] = 1,	 --bless
	[231] = {11,13}, -- shield, Preservation
    [234] = 14,  --stoneskin
    [235] = 23,  --water breathing
	
    [240] = {19,15},  --might, accuracy
    [241] = {17,20},  --intellect, personality
    [242] = {16,21,18},  --endurance, speed, luck
    [248] = {5,0,22,3}, --elemental
    [249] = {9,2},  --self
    [250] = {7,8,1},  --Champions
    [251] = {11,13,14},  --Paladins
    [257] = {19,15,17,20,16,21,18},  --stats
    [263] = {5,0,22,3,9,2},  --resistances
}
itemImmunityMapping = {
	[224] = {"weakness","sleep"},
	[225] = {"disease","poison"},
	[226] = {"curse","paralysis"},
	[227] = {"fear","insanity"},
	[239] = {"stone"},
	[245] = {"weakness","sleep","disease","poison","curse","paralysis","fear","insanity","stone"}
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
		t.Description=potionText[t.Item.Number]--REMOVED .. "\n(To drink, pick the potion up and right-click over a character's portrait.  To mix, pick the potion up and right-click over another potion.)"
	elseif t.Item.Number>=264 and t.Item.Number<=299 then
		t.Description="This potion has been removed"
	end
	if t.Item.Number==222 then
		t.Description=StrColor(255,255,153,"Heals " .. math.round(t.Item.Bonus^1.4)+10 .. " Hit Points") .. "\n" .. t.Description
	end
	if t.Item.Number==223 then
		t.Description=StrColor(255,255,153,"Restores " .. math.round(t.Item.Bonus^1.4*2/3)+10 .. " Spell Points") .. "\n" .. t.Description
	end
	if t.Item.Number==246 then
		t.Description=StrColor(255,255,153,"Heals " .. math.round(t.Item.Bonus^1.4*3)+10 .. " Hit Points") .. "\n" .. t.Description
	end
	if t.Item.Number==247 then
		t.Description=StrColor(255,255,153,"Restores " .. math.round(t.Item.Bonus^1.4*2)+10 .. " Spell Points") .. "\n" .. t.Description
	end
	if table.find(potionUsingCharges,t.Item.Number) then
		local charges=t.Item.Charges-1
		if charges==-1 then
			charges=5
		end
		t.Description=StrColor(255,255,153,"Charges: " .. charges) .. "\n" .. t.Description
	end
	
	if potionRecipeText[t.Item.Number] then
		if extraDescription then
			t.Description=t.Description .. "\n\n" .. potionRecipeText[t.Item.Number]
		else
			t.Description=t.Description .. StrColor(100,100,100,"\n\nPress alt to show recipe list")
		end
	end
end

potionText={
	[222] = "",
	[223] = "",
	[224] = "Cures and prevents Weakness and inducted Sleep for 6 hours.",
	[225] = "Cures and prevents Disease and Poison for 6 hours.",
	[226] = "Cures and prevents Curse and Paralysis for 6 hours.",
	[227] = "Cures and prevents Fear and Insanity for 6 hours.",
	[228] = "Increases Speed for 6 Hours",
	[229] = "Increases Melee damage by 5+(0.5 x Power) for 6 Hours",
	[230] = "Increases Attack by 5+(0.5 x Power) for 6 Hours",
	[231] = "Grants Preservation and Shield (as the spell) for 6 Hours\nRequire 20 power to work.\n",
	[232] = "Grants bonus to Meditation skill for 6 hours.",
	[233] = "Regenerates Health for 6 hours.",
	[234] = "Increases Armor Class  by 5+(0.5 x Power) for 6 Hours",
	[235] = "Prevents drowning damage for 6 hours.\nRequire 20 power to work.\n",
	[236] = "Increases item's roughness, making it more resistant to breaking.\nRequire 20 power to work.\n",
	[237] = "Grant 5 +1 per 10 potion power charges of Magic Protection (as the spell) for 6 hours.\nFrom 55 power on will protect also from death and eradication.\n",
	[238] = "Grant 1 enchant to an unenchanted item, based on potion Power.\nRequire at least 20 power to work.\n",
	[239] = "Cures and prevent Stoned condition for 6 hours.\nRequire 20 power to work.\n",
	[240] = "Temporarily increases by 10+(1 x Power) Might and Accuracy for 6 hours.",
	[241] = "Temporarily increases by 10+(1 x Power) Intellect and Personality for 6 hours.",
	[242] = "Temporarily increases by 10+(1 x Power) Endurance, Speed and Luck for 6 hours.",
	[243] = "Adds a random tier 2 elemental damage enchant to a weapon\nRequire 40 power to work.\n",
	[244] = "Adds 'of Swiftness' property to a non-magic weapon.\nRequire 40 power to work.\n",
	[245] = "Removes and prevents all conditions except Dead and Eradicated for 6 hours.\nRequire 40 power to work.\n",
	[246] = "Heals three times the potion's strength of hit points.",
	[247] = "Restores three times the potion's strength of spell points.",
	[248] = "Increases temporary Fire, Air, Water and Earth resistance. (Dark)",
	[249] = "Increases temporary Mind and Body resistance. (Light)",
	[250] = "Provides Haste+Heroism+Bless.",
	[251] = "Provides Protection+Stone Skin+Magic Protection.",
	[252] = "Adds 20/40/60 to permanent Might and Accuracy.\nRequire 55 power per step to work.\n",
	[253] = "Adds 20/40/60 to permanent Intellect and Wisdom.\nRequire 55 power per step to work.\n",
	[254] = "Adds 20/40/60 to permanent Endurance, Speed and Luck.\nRequire 55 power per step to work.\n",
	[255] = "Adds a random tier 3 elemental damage enchant to a weapon.\nRequire 55 power to work.\n.",
	[256] = "Adds 'of Darkness' property to a non-magic weapon.\nRequire 100 power to work.\n",
	[257] = "Increases all Seven Statistics temporarily by 10+(1 x Power) for 6 hours.",
	[258] = "Fix caracter age at 20.\nRequire 55 power to work.\n",
	[259] = "Grant XP to the player.",
	[260] = "Fix caracter age at 60.\nRequire 55 power to work.\n",
	[261] = "Permanently adds 30/60/90 to Fire, Air, Water and Earth Resistance, single-use.\nRequire 55 power per step to work.\n",
	[262] = "Permanently adds 30/60/90 to Mind and Body Resistance, single-use.\nRequire 55 power per step to work.\n",
	[263] = "Increases all resistances temporarily by 10+ (1 x Power) for 6 hours.",
}

potionRecipeText={
	--orange
	[225]="Recipes:\nAdd Red: Haste\nAdd Blue: Protection\nAdd Yellow: Stone Skin\nAdd Purple: Magic Protection\nAdd Green: Stone to Flesh",
	--purple
	[226]="Recipes:\nAdd Red: Heroism\nAdd Blue: Quickmind\nAdd Yellow: Water Breathing\nAdd Orange: Magic Protection\nAdd Green: Enchant Item",
	--green
	[227]="Recipes:\nAdd Red: Bless\nAdd Blue: Regeneration\nAdd Yellow: Harden Item\nAdd Orange: Magic Protection\nAdd Purple: Enchant Item",
	--7-8-9
	[228]="Recipes:\nAdd Orange: Champion's Potion\nAdd Purple: Power Boost\nAdd Green: Divine Cure",
	[229]="Recipes:\nAdd Orange: Champion's Potion\nAdd Purple: Power Boost\nAdd Green: Divine Cure",
	[230]="Recipes:\nAdd Orange: Champion's Potion\nAdd Purple: Power Boost\nAdd Green: Divine Cure",
	--10-11-12
	[231]="Recipes:\nAdd Orange: Lesser Element\nAdd Purple: Wisdom Boost\nAdd Green: Divine Magic",
	[232]="Recipes:\nAdd Orange: Lesser Element\nAdd Purple: Wisdom Boost\nAdd Green: Divine Magic",
	[233]="Recipes:\nAdd Orange: Lesser Element\nAdd Purple: Wisdom Boost\nAdd Green: Divine Magic",
	--13-14-15
	[234]="Recipes:\nAdd Orange: Swiftness\nAdd Purple: Resilience Boost\nAdd Green: Divine Restoration",
	[235]="Recipes:\nAdd Orange: Swiftness\nAdd Purple: Resilience Boost\nAdd Green: Divine Restoration",
	[236]="Recipes:\nAdd Orange: Swiftness\nAdd Purple: Resilience Boost\nAdd Green: Divine Restoration",
	--16-17-18
	[237]="Recipes:\nAdd Orange: Self Resistance\nAdd Purple: Elemental Resistance\nAdd Green: Paladin's Potion",
	[238]="Recipes:\nAdd Orange: Self Resistance\nAdd Purple: Elemental Resistance\nAdd Green: Paladin's Potion",
	[239]="Recipes:\nAdd Orange: Self Resistance\nAdd Purple: Elemental Resistance\nAdd Green: Paladin's Potion",
	--19-20-21
	[240]="Recipes:\nAdd Red: Pure Power\nAdd Blue: Pure Wisdom\nAdd Yellow: Pure Resilience",
	[241]="Recipes:\nAdd Red: Pure Power\nAdd Blue: Pure Wisdom\nAdd Yellow: Pure Resilience",
	[242]="Recipes:\nAdd Red: Pure Power\nAdd Blue: Pure Wisdom\nAdd Yellow: Pure Resilience",
	--22-23-24
	[243]="Recipes:\nAdd Red: Divine Blessing\nAdd Blue: Darkness\nAdd Yellow: Greater Element",
	[244]="Recipes:\nAdd Red: Divine Blessing\nAdd Blue: Darkness\nAdd Yellow: Greater Element",
	[245]="Recipes:\nAdd Red: Divine Blessing\nAdd Blue: Darkness\nAdd Yellow: Greater Element",
	--25-26-27
	[246]="Recipes:\nAdd Red: Twilight\nAdd Blue: Dawn\nAdd Yellow: Trascendance",
	[247]="Recipes:\nAdd Red: Twilight\nAdd Blue: Dawn\nAdd Yellow: Trascendance",
	[248]="Recipes:\nAdd Red: Twilight\nAdd Blue: Dawn\nAdd Yellow: Trascendance",
	--28-29-30
	[249]="Recipes:\nAdd Red: Pure Elemental Resistance\nAdd Blue: Divine Resistance\nAdd Yellow: Pure Self Resistance",
	[250]="Recipes:\nAdd Red: Pure Elemental Resistance\nAdd Blue: Divine Resistance\nAdd Yellow: Pure Self Resistance",
	[251]="Recipes:\nAdd Red: Pure Elemental Resistance\nAdd Blue: Divine Resistance\nAdd Yellow: Pure Self Resistance",
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
			local mult=math.max((Game.BolsterAmount-100)/250+1,1)
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
			if craftWaitTime>0 then return end
			--pick which enchant to pick that is below the item power
			local bolsterMult=math.max((Game.BolsterAmount-100)/250+1,1)
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
					Mouse.Item.Number=0
					enchanted=true
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
			
			Mouse.Item.Number=0
			enchanted=true
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
		if t.Bonus==0 or t.BonusStrength==0 or t.Bonus2==0 then 
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
		[1064]=0.00001,
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

