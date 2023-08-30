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
			if it.Charges>0 then
				it.Charges=it.Charges-1
			else
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

