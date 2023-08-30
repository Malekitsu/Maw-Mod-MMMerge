function events.LoadMap()
	if not vars.PlayerBuff then
		vars.PlayerBuff={} 
		for i=0,4 do
			vars.PlayerBuff[i]={}
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