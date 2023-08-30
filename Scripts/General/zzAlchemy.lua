function events.LoadMap()
	if not vars.PlayerBuff then
		vars.PlayerBuff={} 
		for i=0,4 do
			vars.PlayerBuff[i]={}
			vars.PlayerBuff[i]["weakness"]=0
			vars.PlayerBuff[i]["disease"]=0
			vars.PlayerBuff[i]["poison"]=0
			vars.PlayerBuff[i]["sleep"]=0
			vars.PlayerBuff[i]["fear"]=0
			vars.PlayerBuff[i]["curse"]=0
			vars.PlayerBuff[i]["insanity"]=0
			vars.PlayerBuff[i]["paralysis"]=0
			vars.PlayerBuff[i]["stone"]=0
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
			vars.PlayerBuff[t.PlayerSlot][txt]=Game.Time+Const.Hour*6
		end
		--------------------
		--BUFFS--
		--------------------
		if itemBuffMapping[it.Number] then
			local buff=itemBuffMapping[it.Number]
			pl.SpellBuffs[buff].Power=it.Bonus+10
			pl.SpellBuffs[buff].ExpireTime=Game.Time+const.Minute*30*it.Bonus
			
			if it.Number<=234 then
				pl.SpellBuffs[buff].Power=math.round(pl.SpellBuffs[buff].Power/2)
			end
		--disable original behaviour and simulate sound
			t.Allow=false
			pl:ShowFaceAnimation(36)
			evt.PlaySound(143)
			if it.Charges==0 then
				it.Charges=5
			elseif it.Charges>1 then
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
	if t.Allow==true then
		if t.Thing==1 then
			if vars.PlayerBuff[t.PlayerIndex]["curse"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Curse Immunity")
			end
		elseif t.Thing==2 then
			if vars.PlayerBuff[t.PlayerIndex]["weakness"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Weakness Immunity")
			end 
		elseif t.Thing==3 then
			if vars.PlayerBuff[t.PlayerIndex]["sleep"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Forced Sleep Immunity")
			end 
		elseif t.Thing==5 then
			if vars.PlayerBuff[t.PlayerIndex]["insanity"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Insanity Immunity")
			end 
		elseif t.Thing==6 or t.Thing==7 or t.Thing==8 then
			if vars.PlayerBuff[t.PlayerIndex]["poison"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Poison Immunity")
			end 
		elseif t.Thing==9 or t.Thing==10 or t.Thing==11 then
			if vars.PlayerBuff[t.PlayerIndex]["disease"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Disease Immunity")
			end 
		elseif t.Thing==12 then
			if vars.PlayerBuff[t.PlayerIndex]["paralysis"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Paralysis Immunity")
			end 
		elseif t.Thing==15 then
			if vars.PlayerBuff[t.PlayerIndex]["stone"]>Game.Time then
				t.Allow=false
				Game.ShowStatusText("Petrify Immunity")
			end 
		elseif t.Thing==23 then
			if vars.PlayerBuff[t.PlayerIndex]["fear"]>Game.Time then
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
		t.Description=StrColor(255,255,153,"Restores " .. math.round(t.Item.Bonus^1.4*3/2)+10 .. " Spell Points") .. "\n" .. t.Description
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
	[229] = "Increases Melee damage by 5+(0.5 x Power) for (30 x Power) minutes",
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
	[263] = "Adds 'of Dragon Slaying' to a weapon.",
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


