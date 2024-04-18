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
}


]]
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
--list legendaries
function events.Action(t)
	function events.Tick()
		events.Remove("Tick", 1)
		vars.legendaries={}
		for i=0,Party.High do
			local pl=Party[i]
			local id=pl:GetIndex()
			vars.legendaries[id]={}
			for it in pl:EnumActiveItems() do
				if it.BonusExpireTime>10 and it.BonusExpireTime<1000 then
					table.insert(vars.legendaries[id], it.BonusExpireTime)
				end
			end
		end
	end
end

--[11]="Killing a monster will recover you action time",
function events.CalcDamageToMonster(t)
	--[17]="Your hits will deal 1% of current monster HP health (0.4% for AoE, multi-hit spells and arrows)",
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 17) then
		local dmg=t.Monster.HP*0.01
		data=WhoHitMonster()
		if (data.Object.Spell and table.find(aoespells, data.Object.Spell)) or data.Object.Spell==133 then
			dmg=dmg*0.4
		end
		t.Result=t.Result+dmg
	end
	--end of [17]
	if t.Player then
		--[14]="Critical chance over 100% increases total damage",
		if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 14) then
			local luck=t.Player:GetLuck()
		end
		t.Result=math.round(math.max(t.Result, t.Result*(luck/1500)))
		--end of [14]
		if t.Result>=t.Monster.HP then
			local id=t.Player:GetIndex()
			if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 11) then
				function events.Tick()
					events.Remove("Tick", 1)
					t.Player.RecoveryDelay=0
				end
			end
		end
	end
end


--[12]="75% of base enchants increasing might, intellect or personality will increase the other 2 stats (highest one is picked)",
function events.CalcStatBonusByItems(t)
	if t.Stat==0 or t.Stat==1 or t.Stat==2 then
		local pl=t.Player
		local id=pl:GetIndex()
		if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 12) then
			local str=0
			local int=0
			local per=0
			for it in pl:EnumActiveItems() do
				if it.Bonus==1 then
					str=str+it.BonusStrength
				elseif it.Bonus==2 then
					int=int+it.BonusStrength
				elseif it.Bonus==3 then
					per=per+it.BonusStrength
				end
				if it.Charges>1000 then
					local bonus=math.floor(it.Charges/1000)
					if bonus==1 then
						str=str+it.Charges%1000
					elseif bonus==2 then
						int=int+it.Charges%1000
					elseif bonus==3 then
						per=per+it.Charges%1000
					end
				end	
			end
			if str>int and str>per then
				if t.Stat==1 or t.Stat==2 then
					t.Result=t.Result+str*0.75
				end
			end
			if int>str and int>per then
				if t.Stat==0 or t.Stat==2 then
					t.Result=t.Result+int*0.75
				end
			end
			if per>str and per>int then
				if t.Stat==0 or t.Stat==1 then
					t.Result=t.Result+per*0.75
				end
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
		Game.ShowStatusText("Status Immunity")
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
end

--[16]="Your highest resistance will always be used against non physical attacks",
--inside calcMawDamage


--[18]="Reduce all damage taken by 10%",
function events.CalcDamageToPlayer(t)
	local id=t.Player:GetIndex()
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 18) then
		t.Result=math.round(t.Result*0.9)
	end
end

--[19]="Your weapon enchants now scales with the highest between might/int./pers.",
--inside calcspelldamage in maw spells and all across the code for tooltips
