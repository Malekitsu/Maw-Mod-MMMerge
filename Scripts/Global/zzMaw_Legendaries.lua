--[[
local legendaryEffects={
	[11]="Killing a monster will recover you action time",
	[12]="75% of base enchants increasing might, intellect or personality will increase the other 2 stats (highest one is picked)",
	[13]="Immunity to all status effects from monsters",
	[14]="Critical chance over 100% increases total damage",
	[15]="Divine protection (instead of dying you go back to 25% HP, once every 5 minutes)",
	[16]="Your highest resistance will always be used against non physical attacks",
	[17]="Your hits will deal 1% of total monster HP health (0.4% for AoE, multi-hit spells and arrows)",
	[18]="Reduce all damage taken by 10%",
	[19]="Your weapon enchants now scales with the highest between might/int./pers.",
	[20]="Base enchants on this items can be upgraded up to twice the cap value with crafting items",
	[21]="Increase melee damage by 5% for each enemy in the nearbies"
	[22]="Reduces damage by 3% for each enemy in the nearbies"
}


]]
function getDistanceToMonster(monster)
	return math.sqrt((Party.X - monster.X) * (Party.X - monster.X) + (Party.Y - monster.Y) * (Party.Y - monster.Y)) - monster.BodyRadius
end
--give legendary effect if dropped prior this file inclusion
function events.BuildItemInformationBox(t)
	if t.Item.Number<=151 or (t.Item.Number>=803 and t.Item.Number<=936) or (t.Item.Number>=1603 and t.Item.Number<=1736) then 
		if t.Item.BonusExpireTime==3 then
			math.randomseed(t.Item.Number)
			local roll=math.random(11,#legendaryEffects)
			t.Item.BonusExpireTime=roll
		end
	end
end


--[11]="Killing a monster will recover you action time",
function events.CalcDamageToMonster(t)
	local id=t.PlayerIndex
	local data=WhoHitMonster()
	if not data or not data.Player then return end
	--weapon enchants	
	local fireAuraDamage=0
	local fireRes=t.Monster.Resistances[0]%1000
	if data and not data.Object and t.DamageKind==4 then
		for i=0,1 do
			local it=data.Player:GetActiveItem(i)
			if it then
				local damage=calcFireAuraDamage(pl, it, fireRes, true, false, "damage")
				if damage then
					fireAuraDamage=fireAuraDamage+damage
				end
			end
		end
	elseif data and data.Object and (data.Object.Spell==133 or data.Spell==135) then --bow/blasters
		local it=data.Player:GetActiveItem(2)
		local damage=calcFireAuraDamage(pl, it, fireRes, true, false, "damage")
		if damage and damage>fireAuraDamage then
			fireAuraDamage=damage
		end
	end
	t.Result=t.Result+fireAuraDamage
	
	--[17]="Your hits will deal 1% of current monster HP health (0.4% for AoE, multi-hit spells and arrows)",
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 17) then
		if t.Result>0 and ((data and data.Object==nil and t.DamageKind==4) or (data and data.Object)) then
			local dmg=t.Monster.HP*0.02*2^(math.floor(t.Monster.Resistances[0]/1000))
			if data and data.Spell and data.Spell==44 then
				dmg=t.Monster.HP*0.02
			end
			if (data and data.Object and data.Object.Spell and table.find(aoespells, data.Object.Spell)) or (data and data.Object and data.Object.Spell==133) then
				dmg=dmg*0.5
			end
			t.Result=t.Result+dmg
		end
	end
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 21) then
		local mult=1
		for i=0, Map.Monsters.High do
			if Map.Monsters[i].Active then
				dist=getDistanceToMonster(Map.Monsters[i])
				if dist<=512 then
					mult=mult+0.05
				end
			end
		end
		t.Result=t.Result*mult
	end
	--end of [17]
	if t.Player then
		--[14]="Critical chance over 100% increases total damage",
		if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 14) then
			local critChance=getCritInfo(t.Player)
			t.Result=math.round(t.Result*math.max(critChance,1))
		end
		--end of [14]
		--[24]="killing a Monster Restores 10% of Health and Mana"
		if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 24) then
			restoreHPLeg=true
			function events.Tick()
				events.Remove("Tick", 1)
				if restoreHPLeg then
					restoreHPLeg=false
					if t.Monster.HP<=0 then
						local fullHP=t.Player:GetFullHP()
						local fullSP=t.Player:GetFullSP()
						t.Player.HP=math.min(fullHP, t.Player.HP+fullHP*0.1)
						t.Player.SP=math.min(fullSP, t.Player.SP+fullSP*0.1)
					end
				end
			end
		end
		--end of 24
		if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 11) then
			data=WhoHitMonster()
			--no aoe spells
			if (data and data.Object and table.find(aoespells,data.Object.Spell)) or (data and data.Spell==133) then
				return
			else
				reduceRecovery=true
				function events.Tick()
					events.Remove("Tick", 1)
					if reduceRecovery then
						reduceRecovery=false
						if t.Monster.HP<=0 then
							reduceRecovery=false
							t.Player.RecoveryDelay=t.Player.RecoveryDelay/4
							--changePlayer(id)
						end
					end
				end
			end
		end
	end
	
end

function changePlayer(id)
	function events.Tick()
		events.Remove("Tick", 1)
		for i=0, Party.High do
			if Party[i]:GetIndex()==id then
				Game.CurrentPlayer=i
				return
			end
		end
	end
end

--[13]="Immunity to all status effects from monsters",
function events.DoBadThingToPlayer(t)
	local pl=t.Player
	local id=pl:GetIndex()
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 13) then
		t.Allow = false
		--Game.ShowStatusText("Status Immunity")
	end
end

--[15]="Divine protection (instead of dying you go back to 25% HP, once every 5 minutes)",
function events.LoadMap(wasInGame)
	vars.legendaryProtectionCooldown=vars.legendaryProtectionCooldown or {}
	for i=0,Party.High do
		local index=Party[i]:GetIndex()
		vars.legendaryProtectionCooldown[index]=vars.legendaryProtectionCooldown[index] or 0
	end
end
function events.CalcDamageToPlayer(t)
	local id=t.Player:GetIndex()
	--legendary [22]
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 22) then
		local count=0
		for i=0, Map.Monsters.High do
			if Map.Monsters[i].Active then
				dist=getDistanceToMonster(Map.Monsters[i])
				if dist<=512 then
					count=count+1
				end
			end
		end
		t.Result=t.Result*0.97^count
	end
	--end of [22]
	--------------------
	--MANA SHIELD CODE--
	--------------------
	local pl=t.Player
	local s,m=SplitSkill(Skillz.get(pl,51))
	local m2=m
	local id=t.PlayerIndex
	local slot=-1
	for i=0,Party.High do
		if Party[i]:GetIndex()==id then
			slot=i
		end
	end
	if s>0 and vars.manaShield and vars.manaShield[slot] then
		if m==4 then
			m=100000
		end
		local currentHP=pl.HP
		local totalHP=pl:GetFullHP()
		local divider=1
		local damageReduced=0
		local damage=t.Result
		while m>0 do
			divider=divider*2
			threshold=math.ceil(totalHP/divider)
			HPAfterDamage=currentHP-damage
			if HPAfterDamage>=threshold then
				m=0
			else
				damage=math.min(threshold,currentHP)-HPAfterDamage
				damageReduced=damageReduced+math.ceil(damage/2)
				damage=math.floor(damage/2)
			end
			m=m-1
		end
		local manaEfficiency=math.round((1+s^1.5/125*4)*100)/100
		if s > 50 then
			manaEfficiency=math.round((1+50^1.5/125*4)*100)/100*s/50
		end
		local mana=pl.SP
		reductionPercent=math.min(mana*manaEfficiency/damageReduced,1)
		damageReduced=damageReduced*reductionPercent
		pl.SP=math.max(pl.SP-math.floor(damageReduced/manaEfficiency),0)
		
		t.Result=(damage+damageReduced)-damageReduced*reductionPercent
	end	
	
	
	
	---------------------
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 15) then
		if t.Player.Unconscious==0 and t.Player.Dead==0 and t.Player.Eradicated==0 then
			if vars.legendaryProtectionCooldown[t.PlayerIndex]==nil then
				vars.legendaryProtectionCooldown[t.PlayerIndex]=0
			end		
			if t.Result>=t.Player.HP and Game.Time>vars.legendaryProtectionCooldown[t.PlayerIndex] then
				--calculate healing
				for i=0,Party.High do
					if Party[i]:GetIndex()==t.PlayerIndex then
						Party[i].HP=Party[i]:GetFullHP()/4
					end
				end
				vars.legendaryProtectionCooldown[t.PlayerIndex] = Game.Time + const.Minute * 150
				Game.ShowStatusText("Legendary power saves you from lethal damage")
				t.Result=0
			end
		end
	end
	if Game.BolsterAmount>=300 then
		function events.Tick()
			events.Remove("Tick",1)
			local fullHP=t.Player:GetFullHP()
			local currentHP=t.Player.HP
			if currentHP<-fullHP then
				t.Player.Dead=Game.Time
			end
			if currentHP<-fullHP*2 then
				t.Player.Eradicated=Game.Time
			end
		end
	end
end

--[16]="Your highest resistance will always be used against non physical attacks",
--inside calcMawDamage



--[19]="Your weapon enchants now scales with the highest between might/int./pers.",
--inside calcspelldamage in maw spells and all across the code for tooltips
