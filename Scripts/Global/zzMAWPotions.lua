evt.PotionEffects[36] = function(IsDrunk, t, Power)
	if Mouse.Item.Bonus<100 then
		Game.ShowStatusText("This potion has not enough power")
		return
	end
	if t.Bonus2==0 and Game.ItemsTxt[t.Number].Skill<7 then
		if IsBaseItemId(t.Number) then
			local enchNumber=(t.Number+t.Charges+t.MaxCharges+t.Bonus+t.BonusStrength)%4
			t.Bonus2=41
			Mouse.Item.Number=0
			ShowCraftedItemEffect(t)
		end
	end
end
evt.PotionEffects[35] = function(IsDrunk, t, Power)
	if Mouse.Item.Bonus<55 then
		Game.ShowStatusText("This potion has not enough power")
		return
	end
	if t.Bonus2==0 and Game.ItemsTxt[t.Number].Skill<7 then
		if IsBaseItemId(t.Number) then
			t.Bonus2=math.random(1,4)*3+3
			Mouse.Item.Number=0
			ShowCraftedItemEffect(t)
		end
	end
end
evt.PotionEffects[23] = function(IsDrunk, t, Power)
	if Mouse.Item.Bonus<40 then
		Game.ShowStatusText("This potion has not enough power")
		return
	end
	if t.Bonus2==0 and Game.ItemsTxt[t.Number].Skill<7 then
		if IsBaseItemId(t.Number) then
			t.Bonus2=math.random(1,4)*3+2
			Mouse.Item.Number=0
			ShowCraftedItemEffect(t)
		end
	end
end
evt.PotionEffects[24] = function(IsDrunk, t, Power)
	if Mouse.Item.Bonus<40 then
		Game.ShowStatusText("This potion has not enough power")
		return
	end
	if t.Bonus2==0 and Game.ItemsTxt[t.Number].Skill<7 then
		if IsBaseItemId(t.Number) then
			t.Bonus2=59
			Mouse.Item.Number=0
			ShowCraftedItemEffect(t)
		end
	end
end
evt.PotionEffects[18] = function(IsDrunk, t, Power)
	if IsBaseItemId(t.Number) then
		if t.Bonus2==0 and t.Bonus==0 and not HasEnc2(t) then
			if vars.enchantSeedList==nil then
				vars.enchantSeedList={}
				for i=0,2500 do
					vars.enchantSeedList[i]=math.random(1,100000)
				end
			end
			math.randomseed(vars.enchantSeedList[t.Number]+t.MaxCharges)
			if math.random(1,10)==1 then
				t.Bonus=math.random(17,24)
			elseif GetItemEquipStat(t)==10 then
				t.Bonus=math.random(1,16)
			else
				t.Bonus=math.random(1,10)
			end
			
			t.BonusStrength=math.min(Mouse.Item.Bonus/3,200)
			-- buff to 2h weapons enchants
			local mult=slotMult[t:T().EquipStat]
			if mult then
				t.BonusStrength=math.ceil(t.BonusStrength*mult)
			end	
			
			--nerf to skill enchant
			if t.Bonus>=17 then
				t.BonusStrength=math.max(t.BonusStrength^0.5, math.ceil(t.BonusStrength/10))
			end
			
			vars.enchantSeedList[t.Number]=vars.enchantSeedList[t.Number]+math.random(1,1000)
			Mouse.Item.Number=0
			ShowCraftedItemEffect(t)
		end
	end
end
--[[ not working
evt.PotionEffects[16] = function(IsDrunk, t, Power)
	if IsBaseItemId(t.Number) or table.find(artWeap1h, t.Number) or table.find(artWeap2h, t.Number) or table.find(artArmors, t.Number)  then
		if not t.Hardened then			
			t.Hardened=true
			Mouse.Item.Number=0
			ShowCraftedItemEffect(t)
		else
			return
		end
	end
end
]]
