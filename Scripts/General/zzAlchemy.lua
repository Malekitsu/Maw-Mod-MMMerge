function events.GameInitialized2()
	for i=252, 263 do
		Game.ItemsTxt[i].Picture="item182"
	end
	
	for i=264,299 do
		Game.ItemsTxt[i].Name="Potion Deleted in MAW"
	end
	if austerity == true then
	for i=232,237 do
		Game.ItemsTxt[i].Name="Potion Deleted in Austerity"
	end
	for i=252,256 do
		Game.ItemsTxt[i].Name="Potion Deleted in Austerity"
	end
	for i=261,263 do
		Game.ItemsTxt[i].Name="Potion Deleted in Austerity"
	end
	for i=1783,1789 do
		Game.ItemsTxt[i].Name="Potion Deleted in Austerity"
	end
end
end

function events.LoadMap()
if austerity == true then
Party[0].Skills[const.Skills.IdentifyMonster] = JoinSkill(10, const.GM)
Party[1].Skills[const.Skills.IdentifyMonster] = JoinSkill(10, const.GM)
Party[2].Skills[const.Skills.IdentifyMonster] = JoinSkill(10, const.GM)
Party[3].Skills[const.Skills.IdentifyMonster] = JoinSkill(10, const.GM)
Party[4].Skills[const.Skills.IdentifyMonster] = JoinSkill(10, const.GM)
end
end

function events.LoadMap()
	vars.PlayerAlchemyBuffs=vars.PlayerAlchemyBuffs or {}
	for i=0,Party.High do
		local index=Party[i]:GetIndex()
		if not vars.PlayerAlchemyBuffs[index] or not vars.PlayerAlchemyBuffs[index]["Stoned"] then
			vars.PlayerAlchemyBuffs[index]={}
			for i=1,#itemImmunityMapping[246] do
				vars.PlayerAlchemyBuffs[index][itemImmunityMapping[246][i]]=0
			end
		end
	end
	vars.BlackPotions=vars.BlackPotions or {}
end

function events.UseMouseItem(t)
	--override
	local it=Mouse.Item
	if it.Number<221 or it.Number>=300 or it.Number==290 then return end
	t.Allow=false
	local pl=Party[t.PlayerSlot]
	local index=pl:GetIndex()
	local delay=pl.RecoveryDelay
	local action=-1
	local currentPlayer=Game.CurrentPlayer
	if delay==0 then
		action=t.PlayerSlot
	else
		local id=Game.CurrentPlayer
		if id>=0 and id<=Party.High then
			delay=Party[id].RecoveryDelay
			if delay==0 then
				action=id
			end
		end
	end
	if action==-1 then
		for i=0,Party.High do
			if action==-1 then
				delay=Party[i].RecoveryDelay
				if delay==0 then
					action=i
				end
			end
		end
	end
	if action==-1 then
		Game.ShowStatusText("Player must be active to consume the potion")
		return
	end
	--check power
	if potionPowerRequirement[it.Number] and potionPowerRequirement[it.Number]>Mouse.Item.Bonus then
		Game.ShowStatusText("This potion has not enough power")
		return
	end
	--healing potion
	if it.Number==222 then
		heal=math.round(it.Bonus^1.4+10)
		pl.HP=math.min(pl:GetFullHP(),pl.HP+heal)
	--mana potion
	elseif it.Number==223 then
		spRestore=math.round(it.Bonus^1.4*2/3+10)
		pl.SP=math.min(pl:GetFullSP(),pl.SP+spRestore)
	end
	if it.Number==247 then
		heal=math.round(it.Bonus^1.4*1.5+20)
		pl.HP=math.min(pl:GetFullHP(),pl.HP+heal)
	--mana potion
	elseif it.Number==248 then
		spRestore=math.round(it.Bonus^1.4+20)
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
		vars.bonusMeditation[index]={Game.Time+const.Hour*6, math.ceil(it.Bonus^0.5/1.5) + 1}
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
		vars.magicResistancePotionExpire=Game.Time+const.Hour*6
	end
	
	if itemImmunityMapping[it.Number] then 
		for i=1,#itemImmunityMapping[it.Number] do
			local txt=itemImmunityMapping[it.Number][i]
			vars.PlayerAlchemyBuffs[index][txt]=Game.Time+Const.Hour*6
			pl[itemImmunityMapping[it.Number][i]]=0
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
				pl.SpellBuffs[buffID].Skill=0
			end
		else
			pl.SpellBuffs[buff].Power=it.Bonus+10
			pl.SpellBuffs[buff].ExpireTime=Game.Time+const.Hour*6
			pl.SpellBuffs[buff].Skill=0
		end
		--half effect for bless, heroism and stoneskin
		if (it.Number<=234 and it.Number~=229) or it.Number==245 or  it.Number==251 then
			if type(buff)=="table" then
				for i=1,#buff do
					buffID=itemBuffMapping[it.Number][i]
					pl.SpellBuffs[buffID].Power=math.round(pl.SpellBuffs[buffID].Power/2)
					pl.SpellBuffs[buffID].Skill=0
				end
			else
				pl.SpellBuffs[buff].Power=math.round(pl.SpellBuffs[buff].Power/2)
				pl.SpellBuffs[buff].Skill=0
			end
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
				vars.BlackPotions[index][stat]=power
			else
				Game.ShowStatusText("Can't benefit anymore")
				return
			end
		end
	end	
	
	--age potions
	if it.Number==258 then
		pl.BirthYear=1172-60+math.floor(Game.Time/const.Year)
		Party[0].AgeBonus=0
	end
	if it.Number==260 then
		pl.BirthYear=1172-20+math.floor(Game.Time/const.Year)
		Party[0].AgeBonus=0
	end
	
	--exp potion
	if it.Number==259 then
		local experience=it.Bonus*500
		vars.expPot=vars.expPot or {}
		vars.expPot[index]=vars.expPot[index] or 0
		if vars.expPot[index]/(pl.Exp-vars.expPot[index])<0.25 then
			pl.Exp=pl.Exp+experience
			vars.expPot[index]=vars.expPot[index]+experience
		else
			Game.ShowStatusText("You need to gain more exp. to benefit from this potion")
			return
		end
	end
	
	--consume
	if table.find(potionUsingCharges,Mouse.Item.Number) then
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
	Party[action]:SetRecoveryDelay(60)
	pl:ShowFaceAnimation(36)
	evt.PlaySound(143)
	--restore to previous player to avoid inventory issues
	function events.Tick()
		events.Remove("Tick", 1)
		if Game.CurrentScreen~=0 then
			Game.CurrentPlayer=currentPlayer
		end
	end
end

function events.GameInitialized2()
	function events.GetSkill(t)
		if t.Skill==const.Skills.Meditation then
			if vars and vars.bonusMeditation and vars.bonusMeditation[t.PlayerIndex] and vars.bonusMeditation[t.PlayerIndex][1]>Game.Time then
				t.Result=t.Result+vars.bonusMeditation[t.PlayerIndex][2]
			end
		end
	end
end

potionUsingCharges={228,229,230,231,232,233,234,235,237,240,241,242,245,247,248,249,250,251,257,263}
potionPowerRequirement={
	[231]=20,
	[235]=20,
	[236]=20,
	[239]=20,
	[246]=40,
	[256]=55,
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
    [245] = {7,8,1},  --Champions
    [249] = {5,0,22,3}, --elemental
    [250] = {9,2},  --self
    [251] = {11,13,14},  --Paladins
    [257] = {19,15,17,20,16,21,18},  --stats
    [263] = {5,0,22,3,9,2},  --resistances
}
itemImmunityMapping = {
	[224] = {"Weak","Asleep"},
	[225] = {"Disease1","Disease2","Disease3","Poison1","Poison2","Poison3"},
	[226] = {"Cursed","Paralyzed"},
	[227] = {"Afraid","Insane"},
	[239] = {"Stoned"},
	[246] = {"Weak","Asleep","Disease1","Disease2","Disease3","Poison1","Poison2","Poison3","Cursed","Paralyzed","Afraid","Insane","Stoned"}
}


function events.DoBadThingToPlayer(t)
	if t.Allow==true and vars.PlayerAlchemyBuffs[t.Player:GetIndex()] then
		if t.Thing==1 then
			if vars.PlayerAlchemyBuffs[t.Player:GetIndex()]["Cursed"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Curse Immunity")
			end
		elseif t.Thing==2 then
			if vars.PlayerAlchemyBuffs[t.Player:GetIndex()]["Weak"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Weakness Immunity")
			end 
		elseif t.Thing==3 then
			if vars.PlayerAlchemyBuffs[t.Player:GetIndex()]["Asleep"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Forced Sleep Immunity")
			end 
		elseif t.Thing==5 then
			if vars.PlayerAlchemyBuffs[t.Player:GetIndex()]["Insane"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Insanity Immunity")
			end 
		elseif t.Thing==6 or t.Thing==7 or t.Thing==8 then
			if vars.PlayerAlchemyBuffs[t.Player:GetIndex()]["Poison1"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Poison Immunity")
			end 
		elseif t.Thing==9 or t.Thing==10 or t.Thing==11 then
			if vars.PlayerAlchemyBuffs[t.Player:GetIndex()]["Disease1"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Disease Immunity")
			end 
		elseif t.Thing==12 then
			if vars.PlayerAlchemyBuffs[t.Player:GetIndex()]["Paralyzed"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Paralysis Immunity")
			end 
		elseif t.Thing==15 then
			if vars.PlayerAlchemyBuffs[t.Player:GetIndex()]["Stoned"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Petrify Immunity")
			end 
		elseif t.Thing==23 then
			if vars.PlayerAlchemyBuffs[t.Player:GetIndex()]["Afraid"]>Game.Time then
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
	if t.Item.Number==232 then
		t.Description="Grants " .. StrColor(0,0,200,math.ceil(t.Item.Bonus^0.5/1.5) + 1) .. " bonus to Meditation skill for 6 hours."
	end
	if t.Item.Number==247 then
		t.Description=StrColor(255,255,153,"Heals " .. math.round(t.Item.Bonus^1.4*1.5)+20 .. " Hit Points") .. "\n" .. t.Description
	end
	if t.Item.Number==248 then
		t.Description=StrColor(255,255,153,"Restores " .. math.round(t.Item.Bonus^1.4)+20 .. " Spell Points") .. "\n" .. t.Description
	end
	if t.Item.Number==259 then
		local id=Game.CurrentPlayer
		if Game.CurrentPlayer<0 or Game.CurrentPlayer>Party.High then
			id=0
		end
		index=Party[id]:GetIndex()
		vars.expPot=vars.expPot or {}
		vars.expPot[index]=vars.expPot[index] or 0
		local percent=math.round(vars.expPot[index]/(pl.Exp-vars.expPot[index])*10000)/100
		if percent<25 then
			str=StrColor(0,255,0,percent .. "%")
		else
			str=StrColor(255,0,0,percent .. "%")
		end
		t.Description=t.Description .. "\n\nCan benefit only if experience gained this way is less than 25% of base experience\nCurrent amount: " .. str
	end
		
	if table.find(potionUsingCharges,t.Item.Number) then
		local charges=t.Item.Charges-1
		if charges==-1 then
			charges=5
		end
		t.Description=StrColor(255,255,153,"Charges: " .. charges) .. "\n\n" .. t.Description
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
	[245] = "Provides Haste+Heroism+Bless.",
	[246] = "Removes and prevents all conditions except Dead and Eradicated for 6 hours.\nRequire 40 power to work.\n",
	[247] = "Heals based on the potion's power of hit points.",
	[248] = "Restores based on the potion's power of spell points.",
	[249] = "Increases temporary Fire, Air, Water and Earth resistance. (Dark)",
	[250] = "Increases temporary Mind and Body resistance. (Light)",
	[251] = "Provides Protection+Stone Skin+Magic Protection.",
	[252] = "Adds 20/40/60 to permanent Might and Accuracy.\nRequire 55 power per step to work.\n",
	[253] = "Adds 20/40/60 to permanent Intellect and Wisdom.\nRequire 55 power per step to work.\n",
	[254] = "Adds 20/40/60 to permanent Endurance, Speed and Luck.\nRequire 55 power per step to work.\n",
	[255] = "Adds a random tier 3 elemental damage enchant to a weapon.\nRequire 55 power to work.\n",
	[256] = "Adds 'of Darkness' property to a non-magic weapon.\nRequire 100 power to work.\n",
	[257] = "Increases all Seven Statistics temporarily by 10+(1 x Power) for 6 hours.",
	[258] = "Fix caracter age at 60.\nRequire 55 power to work.\n",
	[259] = "Grant 500 Experience point per Power to the player.",
	[260] = "Fix caracter age at 20.\nRequire 55 power to work.\n",
	[261] = "Permanently adds 30/60/90 to Fire, Air, Water and Earth Resistance, single-use.\nRequire 55 power per step to work.\n",
	[262] = "Permanently adds 30/60/90 to Mind and Body Resistance, single-use.\nRequire 55 power per step to work.\n",
	[263] = "Increases all resistances temporarily by 10+ (1 x Power) for 6 hours.",
}

potionRecipeText={
	--orange
	[225]="Recipes:\nAdd Red: Haste\nAdd Blue: Protection\nAdd Yellow: Stone Skin\nAdd Purple: Magic Protection\nAdd Green: Stone to Flesh",
	--purple
	[226]="Recipes:\nAdd Red: Heroism\nAdd Blue: Meditation\nAdd Yellow: Water Breathing\nAdd Orange: Magic Protection\nAdd Green: Enchant Item",
	--green
	[227]="Recipes:\nAdd Red: Bless\nAdd Blue: Regeneration\nAdd Yellow: Harden Item\nAdd Orange: Stone to Flesh\nAdd Purple: Enchant Item",
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
	alcBonus=alcBonus or {}
	if Game.CurrentPlayer<0 or Game.CurrentPlayer>Party.High then 
		return
	end
	alcBonus[Party[Game.CurrentPlayer]:GetIndex()]=0
	if lastModifiedReagent and lastModifiedReagent~=0 then
		Game.ItemsTxt[lastModifiedReagent].Mod1DiceCount=reagentList[lastModifiedReagent]
	end
	if reagentList[Mouse.Item.Number] then
		local it=Game.ItemsTxt[Mouse.Item.Number]
		if Mouse.Item.Bonus>0 then
			it.Mod1DiceCount=math.floor(reagentList[Mouse.Item.Number]*((Mouse.Item.Bonus*0.25)/20+1)+Mouse.Item.Bonus*0.75)
		end
		local alc=Party[Game.CurrentPlayer]:GetSkill(const.Skills.Alchemy)
		s,m=SplitSkill(alc)
		local bonus=0
		if m==3 then
			bonus=s*0.5
		elseif m==4 then
			bonus=s
		end
		if it.Mod1DiceCount+bonus>255 then
			local id=Party[Game.CurrentPlayer]:GetIndex()
			alcBonus[id]=it.Mod1DiceCount+bonus-255
			it.Mod1DiceCount=255
		else
			it.Mod1DiceCount=it.Mod1DiceCount+bonus
		end
		lastModifiedReagent=Mouse.Item.Number
	end
end
--increase alchemy skill to fix reagent power overflow
function events.GameInitialized2()
	function events.GetSkill(t)
		if t.Skill==const.Skills.Alchemy and alcBonus and alcBonus[t.PlayerIndex] then
			t.Result=t.Result+alcBonus[t.PlayerIndex]
		end
	end
end

function events.BuildItemInformationBox(t)
	if reagentList[t.Item.Number] then
		local bonus=math.round(reagentList[t.Item.Number] *((t.Item.Bonus*0.25)/20+1)+t.Item.Bonus*0.75)
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
			chance=(m-2)/100
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
		tier=math.round(math.min(math.max((lvl/20)*(math.random()/2+1.75),1),5))
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
	Skillz.setDesc(const.Skills.Alchemy,1,Skillz.getDesc(const.Skills.Alchemy,1) .. "\n\nMaster will grant 1% to drop random reagents from Monsters.\nAt GM this chance is doubled.")
	Game.SkillDesMaster[const.Skills.Alchemy]="Allows to make white potions. Power when mixing will be increased to 1.5 per skill point."
	Game.SkillDesMaster[const.Skills.Alchemy]="Allows to make white potions. Power when mixing will be increased to 1.5 per skill point."
	Game.SkillDesGM[const.Skills.Alchemy]="Allows to make black potions. Power when mixing will be increased to 2 per skill point."
end
function events.BuildItemInformationBox(t)
	if t.Item.Number>=1051 and t.Item.Number<=1060 then
		if t.Name then
			if t.Item.BonusStrength==1 then
				t.Name=StrColor(178,255,255, "Ascended " .. t.Name) 
			end
		end
		if t.Description then
			local mult=math.max((Game.BolsterAmount-100)/2000+1,1)
			if vars.insanityMode then
				mult=1.4
			end
			local tier=(t.Item.Number-1050)*mult
			if t.Item.BonusStrength==1 then
				tier=tier+10*mult
			end
			local power = 3
			
			
			local twoHanded = tier * 6 * 2
			local bodyArmor = math.round(tier * 1.5 * 6)
			local helmEtc = math.round(tier * 1.25 * 6)
			local rings = math.round(tier * 0.75 * 6)
			
			
			t.Description = "A special Gem that allows to increase an item Enchant Strength (right-click on an item with a base enchant to use)\nLegendary items can more Max power.\n\nMax Power: " 
			.. StrColor(255, 128, 0, tostring(math.round(tier * 6))) .. " (65% on AC)"
			.. "\nBonus: " .. StrColor(255, 128, 0, tostring(power)) 
			.. "\n\nItem Modifier:\nTwo Handed Weapons: " .. StrColor(255, 128, 0, twoHanded)
			.. "\nBody Armor: " .. StrColor(255, 128, 0, bodyArmor)
			.. "\nHelm-Boots-Gloves-Bow: " .. StrColor(255, 128, 0, helmEtc)
			.. "\nRings: " .. StrColor(255, 128, 0, rings)
		end
	end
	if t.Item.Number==1067 then
		if t.Description then
			if t.Item.BonusStrength<10 or t.Item.BonusStrength>1000 then
				t.Description="Oracle's Orb is a mysterious and powerful artifact, a large, purple orb with a haunting face suspended within its core. This enigmatic relic is known for storing legendary abilities upon items it enchants.\n\nRight click a legendary item to store its power"
			else
				t.Description="Oracle's Orb is a mysterious and powerful artifact, a large, purple orb with a haunting face suspended within its core. This enigmatic relic is known for storing legendary abilities upon items it enchants.\n\nAdds the following legendary power to an item:"
			end
			t.Description = t.Description .. "\n\n" .. StrColor(255,255,30,legendaryEffects[t.Item.BonusStrength])
		end
	end
end

local function upgradeGem(it, tier)
	local enchanted=false
	--bolster multiplier
	local bolsterMult=math.max((Game.BolsterAmount-100)/2000+1,1)
	if vars.insanityMode then
		bolsterMult=1.4
	end
	local tier=tier*bolsterMult
	--2nd enchant value
	local bonus2=math.floor(it.Charges/1000)
	local bonus2Strength=it.Charges%1000
	--upgrade amount
	local upgradeAmount1=3
	local upgradeAmount2=upgradeAmount1
	--base value
	local maxValue1=math.round(tier*6)
	
	if it.BonusExpireTime==1 or it.BonusExpireTime==2 then
		maxValue1=math.min(maxValue1+10,maxValue1*1.2)
	end
	if it.BonusExpireTime>10 and it.BonusExpireTime<1000 then
		maxValue1=math.min(maxValue1+20,maxValue1*1.44)
	end
	local maxValue2=maxValue1
	if not vars.itemStatsFix then
		--hp/sp value
		if it.Bonus==8 or it.Bonus==9 then
			maxValue1=math.floor(maxValue1*(2+maxValue1/50))
			upgradeAmount1=upgradeAmount1^2+1
		end
		if bonus2==8 or bonus2==9 then
			maxValue2=math.floor(maxValue2*(2+maxValue2/50))
			upgradeAmount2=upgradeAmount2^2+1
		end
		--AC
		if it.Bonus==10 then
			maxValue1=math.floor(maxValue1*0.667)
		end
		if bonus2==10 then
			maxValue2=math.floor(maxValue2*0.667)
		end
	end
	--skills
	if it.Bonus>=17 then
		maxValue1=math.floor(math.max((tier*10)^0.5, math.round(tier)))
		upgradeAmount1=1
	end
	--item slot multiplier and legendary multiplier
	local mult=slotMult[it:T().EquipStat] or 1
	if table.find(twoHandedAxes, it.Number) then
		mult=2
	end
	--[[if it.BonusExpireTime==20 then
		mult=mult*2
	end
	]]
	maxValue1=math.floor(maxValue1*mult)
	maxValue2=math.floor(maxValue2*mult)
	--pick the lowest one
	local bonus1percent=it.BonusStrength/maxValue1
	local bonus2percent=bonus2Strength/maxValue2
	if it.Bonus==0 then
		bonus1percent=math.huge
	end
	if it.Charges<1000 then
		bonus2percent=math.huge
	end
	if it.Bonus==0 and it.Charges<1000 then
		return "no enchants"
	end
	--apply enchant
	if bonus1percent<=bonus2percent and it.BonusStrength<maxValue1 then
		enchanted=true
		it.BonusStrength=math.min(it.BonusStrength+upgradeAmount1,maxValue1)
	elseif bonus2percent<=bonus1percent and bonus2Strength<maxValue2 and bonus2Strength<999 then --currently capped at 999
		enchanted=true
		it.Charges=bonus2*1000+math.min(bonus2Strength+upgradeAmount2,maxValue2,999)
	end
	return enchanted
end

for i=1,10 do
	evt.PotionEffects[70+i] = function(IsDrunk, t, Power)
		if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) then			
			if craftWaitTime>0 then return end
			local tier=(Mouse.Item.Number-1050)
			if Mouse.Item.BonusStrength==1 then
				tier=tier+10
			end
			local enchanted=upgradeGem(t, tier)
			if enchanted=="no enchants" then
				Game.ShowStatusText("No enchants")
				return
			end
			if enchanted then
				Mouse.Item.Number=0
				mem.u4[0x51E100] = 0x100 
				t.Condition = t.Condition:Or(0x10)
				evt.PlaySound(12070)
			else
				Game.ShowStatusText("Gem power is not enough")
			end
		end
	end
end

function events.GameInitialized2()
	craftWaitTime=craftWaitTime or 0
end
function events.Tick()
	if craftingItemUsed then
		craftWaitTime=60
		craftingItemUsed=false
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
		if t.Bonus>0 and t.BonusStrength>0 and t.Charges<=1000 then 
			math.randomseed(t.Number*10000+t.MaxCharges*1000+t.Bonus*100+t.BonusStrength*10+t.Charges)
			
			local mult=math.max((Game.BolsterAmount-100)/1000+1,1)
			local cap=100*mult
			local power=t.BonusStrength
			if t.Bonus==8 or t.Bonus==9 then
				power=math.floor((-100+(100^2+power*200)^0.5)/2)
			elseif t.Bonus==10 then
				power=power*1.5
			end
			local stat=math.random(1,16)
			if stat==8 or stat==9 then
				power=power*(2+power/50)
			elseif stat==10 then
				power=power*0.667
			end
			local slotMult=slotMult[t:T().EquipStat] or 1
			cap=math.min(cap*slotMult,999)
			
			t.Charges=stat*1000+math.min(math.round(power*(1+0.25*math.random())),cap)
			Mouse.Item.Number=0
			mem.u4[0x51E100] = 0x100 
			t.Condition = t.Condition:Or(0x10)
			evt.PlaySound(12070)
		end
	end
end

evt.PotionEffects[83] = function(IsDrunk, t, Power)
	if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) then
		local difficultyExtraPower=1
		if Game.BolsterAmount>100 then
			difficultyExtraPower=(Game.BolsterAmount-100)/2000+1
		end
		local maxChargesCap=50*((difficultyExtraPower-1)*2+1)
		if t.BonusExpireTime>=10 and t.BonusExpireTime<1000 then
			maxChargesCap=50*((difficultyExtraPower-1)*4+1)
		end
		maxChargesCap=maxChargesCap+100 --mapping release
		maxChargesCap=maxChargesCap/2
		--if level requirement is over player level block it
		local itemLevel=t.MaxCharges*10
		local tot=0
		local lvl=0
		for i=1, 6 do
			tot=tot+t:T().ChanceByLevel[i]
			lvl=lvl+t:T().ChanceByLevel[i]*i
		end
		itemLevel=itemLevel+math.round(lvl/tot*18-17)
		local maxCharges=t.MaxCharges
		if t.BonusExpireTime>0 and t.BonusExpireTime<=2 then
			maxCharges=math.floor(math.min(maxCharges/1.2,maxCharges-5))
		end
		if t.BonusExpireTime>10 and t.BonusExpireTime<=100 then
			maxCharges=math.floor(math.min(maxCharges/1.2,maxCharges-5))
		end
		levelRequired=(maxCharges)*6+lvl/tot*2-24
		if Game.BolsterAmount>=300 then
			levelRequired=levelRequired-6
		end
		if vars.Mode==2 then
			levelRequired=levelRequired-3
		end
		levelRequired=math.max(1,math.floor(levelRequired))
		--check if equippable
		plLvl=Party[Game.CurrentPlayer].LevelBase
		if plLvl<levelRequired then
			Game.ShowStatusText("Your level is too low (Level " .. levelRequired .. " required)")
			return
		end
		
		
		if t.MaxCharges>=maxChargesCap then
			Game.ShowStatusText("Item power reached its limit")
			return
		end
		local changeIncrease=4
		if t:T().EquipStat<=3 then
			changeIncrease=2
		end
		t.MaxCharges=math.min(t.MaxCharges+4,maxChargesCap)
		Mouse.Item.Number=0
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end

evt.PotionEffects[84] = function(IsDrunk, t, Power)
	if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) or (t.Number>=500 and t.Number<=542) or (t.Number>=1302 and t.Number<=1354) or (t.Number>=2020 and t.Number<=2049) then
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

evt.PotionEffects[85] = function(IsDrunk, t, Power)
	if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) then
		local modified=false
		if Game.ItemsTxt[t.Number].NotIdentifiedName==Game.ItemsTxt[t.Number+1].NotIdentifiedName then
			t.Number=t.Number+1
			Mouse.Item.Number=0
			modified=true
		else
			if t:T().EquipStat<=2 then --weapons
				local itemType=t:T().Skill
				local itemSlot=t:T().EquipStat
				local basePower=(t:T().Mod1DiceCount*t:T().Mod1DiceSides+1)/2+t:T().Mod2
				local upgradeItemId=false
				local upgradePower=math.huge
				for i=1, Game.ItemsTxt.High do
					if i<=151 or (i>=803 and i<=936) or (i>=1603 and i<=1736) then
						local it=Game.ItemsTxt[i]
						local power=(it.Mod1DiceCount*it.Mod1DiceSides+1)/2+it.Mod2
						if itemType==it.Skill and itemSlot==it.EquipStat and power>basePower and power<upgradePower then
							upgradeItemId=i
							upgradePower=power
						end
					end
				end
				if upgradeItemId then
					t.Number=upgradeItemId
					modified=true
					Mouse.Item.Number=0
				end
			else --armors
				local itemType=t:T().Skill
				local itemSlot=t:T().EquipStat
				local basePower=t:T().Mod1DiceCount+t:T().Mod2
				local upgradeItemId=false
				local upgradePower=math.huge
				for i=1, Game.ItemsTxt.High do
					if i<=151 or (i>=803 and i<=936) or (i>=1603 and i<=1736) then
						local it=Game.ItemsTxt[i]
						local power=it.Mod1DiceCount+it.Mod2
						if itemType==it.Skill and itemSlot==it.EquipStat and power>basePower and power<upgradePower then
							upgradeItemId=i
							upgradePower=power
						end
					end
				end
				if upgradeItemId then
					t.Number=upgradeItemId
					modified=true
					Mouse.Item.Number=0
				end
			end
		end
		if not modified then return end
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
		Game:ExitHouseScreen()
	end
end

evt.PotionEffects[86] = function(IsDrunk, t, Power)
	if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) then
		if t.Bonus==0 and t.Charges<=1000 and t.Bonus2==0 then
			return 
		end
		local done=false
		while not done do
			local roll=math.random(1,3)
			if roll==1 and t.Bonus~=0 then
				t.Bonus=0
				t.BonusStrength=0
				if t.Charges>1000 then
					t.Bonus=math.floor(t.Charges/1000)
					t.BonusStrength=t.Charges%1000
					t.Charges=0
				end
				done=true
			elseif roll==2 and t.Charges>1000 then
				t.Charges=0
				done=true
			elseif roll==3 and t.Bonus2~=0 then
				t.Bonus2=0
				done=true
			end
		end
		Mouse.Item.Number=0
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end

evt.PotionEffects[87] = function(IsDrunk, t, Power)
	if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) then
		if craftWaitTime>0 then return end
		craftingItemUsed=true
		if (t.BonusExpireTime>=10 and t.BonusExpireTime<1000) then
			Mouse.Item.BonusStrength=t.BonusExpireTime
			t.BonusExpireTime=2
		elseif Mouse.Item.BonusStrength>=10 and Mouse.Item.BonusStrength<1000 then
			t.BonusExpireTime=Mouse.Item.BonusStrength
			Mouse.Item.Number=0
		else
			return
		end
		mem.u4[0x51E100] = 0x100 
		t.Condition = t.Condition:Or(0x10)
		evt.PlaySound(12070)
	end
end


craftDropChances={
		["gems"]=0.006,
		[1061]=0.0002,
		[1062]=0.0002,
		[1063]=0.001,
		[1064]=0.00001,
		[1065]=0.00025,
		[1066]=0.0002,
		[1067]=0.00004,
	}
	
-- Function to generate normally distributed random numbers
function normal_random(mean, stddev)
    local u1 = math.random()
    local u2 = math.random()
    
    -- Avoid taking log of zero
    if u1 == 0 then u1 = 1e-10 end

    local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return z0 * stddev + mean
end

local noCorpseMonsters={82,83,84,97,98,99,241,242,243,523,524,525,529,530,531,532,533,534,622,623,624,625,626,627}
function events.MonsterKilled(mon)
	if mon.Ally == 9999 or mon.NameId>300 then -- no drop from reanimated monsters
		return
	end
	mon.Ally=9999
	
	if getMapAffixPower(9) and math.random()<getMapAffixPower(9)/100 then
		pseudoSpawnpoint{monster = mon.Id,  x = mon.X, y = mon.Y, z = mon.Z, count = 1, powerChances = {55, 30, 15}, radius = 128, group = 2,transform = function(mon) mon.Ally = 0 mon.Hostile=true mon.ShowAsHostile=true end}
	end
	
	--level bonus
	local lvl=mon.Level
	if mon.NameId==0 then
		lvl=math.round(totalLevel[mon.Id])
	elseif mapvars.uniqueMonsterLevel and mapvars.uniqueMonsterLevel[mon:GetIndex()] then
		lvl=math.round(mapvars.uniqueMonsterLevel[mon:GetIndex()])
	end
	bonusRoll=math.min(1+lvl/60,5)
	if mon.NameId>=220 and mon.NameId <300 then
		bonusRoll=bonusRoll*10
	end
	if Multiplayer and Multiplayer.client_monsters()[0] then
		bonusRoll=bonusRoll/(1+#Multiplayer.client_monsters())
	end
	
	if mapvars.mapAffixes then
		local nAff=0
		for i=1,4 do
			if mapvars.mapAffixes[i]>0 then
				nAff=nAff+1
			end
		end
		bonusRoll=bonusRoll*(1+mapvars.mapAffixes.Power*nAff/800*1.5)
	end
	--pick base craft material
	local baseCraftDrop=false
	local ascendedGem=false
	local gemChance=craftDropChances.gems
	local insanityMult=1
	if vars.insanityMode then
		insanityMult=1.5
	end
	--no corpse monster Buff
	if table.find(noCorpseMonsters,mon.Id) then
		bonusRoll=bonusRoll*3
	end
	if austerityc==true then
	bonusRoll=0
	end
	if math.random()<craftDropChances.gems*bonusRoll*insanityMult then
		baseCraftDrop=true
		local craftStrength = math.floor(normal_random(math.max(lvl^0.6/4+1,lvl/40), 2))
		craftStrength=math.max(math.min(craftStrength,20),1)
		if craftStrength>10 then
			craftStrength=craftStrength-10
			ascendedGem=true
		end
		crafMaterialNumber=1050+craftStrength
	end	
	if baseCraftDrop then
		obj = SummonItem(crafMaterialNumber, mon.X, mon.Y, mon.Z + 100, 100)
		if obj then
			obj.Item.Charges=1
			if ascendedGem then
				obj.Item.BonusStrength=1
			end
		end
	end
	--pick special drop
	if math.random()<craftDropChances[1061]*bonusRoll then
		obj = SummonItem(1061, mon.X, mon.Y, mon.Z + 100, 100)
	end
	if math.random()<craftDropChances[1062]*bonusRoll then
		obj = SummonItem(1062, mon.X, mon.Y, mon.Z + 100, 100)
	end
	if math.random()<craftDropChances[1063]*bonusRoll*insanityMult then
		obj = SummonItem(1063, mon.X, mon.Y, mon.Z + 100, 100)
	end
	if math.random()<craftDropChances[1064]*bonusRoll*insanityMult then
		obj = SummonItem(1064, mon.X, mon.Y, mon.Z + 100, 100)
	end
	if math.random()<craftDropChances[1065]*bonusRoll then
		obj = SummonItem(1065, mon.X, mon.Y, mon.Z + 100, 100)
	end
	if math.random()<craftDropChances[1066]*bonusRoll then
		obj = SummonItem(1066, mon.X, mon.Y, mon.Z + 100, 100)
	end
	if math.random()<craftDropChances[1067]*bonusRoll then
		obj = SummonItem(1067, mon.X, mon.Y, mon.Z + 100, 100)
	end
	
end


function events.GameInitialized2()
	--special crafting items
	Game.ItemsTxt[1061].Notes="This Eye allows to add a Special enchant to any equipment that has already 2 base enchants\n(right-click on an item with a base enchant to use)"
	Game.ItemsTxt[1062].Notes="This Hourglass allows to add a second base enchant to any equipment that has 1 base and a special enchant\n(right-click on an item with a base enchant to use)"
	Game.ItemsTxt[1067].Notes="Oracle's Orb is a mysterious and powerful artifact, a large, purple orb with a haunting face suspended within its core. This enigmatic relic is known for storing legendary abilities upon items it enchants.\n\n Adds the following legendary power to an item:"
end
