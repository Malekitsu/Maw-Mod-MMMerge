----------------------------------------------------
--Empower Monsters
----------------------------------------------------

function events.GameInitialized2()
BLevel={}
	for i=1, 217 do
		table.insert(BLevel,Game.MonstersTxt[(i*3)-1].Level)
		table.insert(BLevel,Game.MonstersTxt[(i*3)-1].Level)
		table.insert(BLevel,Game.MonstersTxt[(i*3)-1].Level)
	end
	for i=1, Game.MonstersTxt.high-100 do
		mon=Game.MonstersTxt[i]
		avgLevel=BLevel[i]
		--adjust for type A and B, making health scales similiar to 1-100
		--HP
		mon.HP=math.min(math.round(mon.Level*(mon.Level/10+3)*2),32500)
		if ItemRework==true and StatsRework==true then
			mon.HP=math.min(math.round(mon.HP*(1+mon.Level/180)/10)*10)
		end
		mon.FullHP=mon.HP
		--damage
		dmgMult=avgLevel/20+1.25
		if ItemRework==true  then
			dmgMult=dmgMult*((mon.Level^1.15-1)/1000+1)
		end
		if StatsRework==true then
			dmgMult=dmgMult*((mon.Level^1.25-1)/1000+1)
		end
		
		-----------------------------------------------------------
		--DAMAGE COMPUTATION DOWN HERE, FOR BALANCE MODIFY ABOVE^
		--attack 1
		a=0
		b=0
		c=0
		d=0
		e=0
		f=0
		a=mon.Attack1.DamageAdd * dmgMult
		mon.Attack1.DamageAdd = mon.Attack1.DamageAdd * dmgMult
		b=mon.Attack1.DamageDiceSides * dmgMult^0.5
		mon.Attack1.DamageDiceSides = mon.Attack1.DamageDiceSides * dmgMult^0.5
		mon.Attack1.DamageDiceCount = mon.Attack1.DamageDiceCount * dmgMult^0.5
		--attack 2
		c=mon.Attack2.DamageAdd * dmgMult
		mon.Attack2.DamageAdd = mon.Attack2.DamageAdd * dmgMult
		d=mon.Attack2.DamageDiceSides * dmgMult^0.5
		mon.Attack2.DamageDiceSides = mon.Attack2.DamageDiceSides * dmgMult^0.5
		mon.Attack2.DamageDiceCount = mon.Attack2.DamageDiceCount * dmgMult^0.5
		--OVERFLOW FIX
		--Attack 1 Overflow fix
		--add damage fix
		if (a > 250) then
		Overflow = a - 250
		mon.Attack1.DamageAdd = 250
		b=b + (math.round(2*Overflow/mon.Attack1.DamageDiceCount))
		mon.Attack1.DamageDiceSides = b 
		end
		--Dice Sides fix
		if (b > 250) then
		Overflow = b / 250
		mon.Attack1.DamageDiceSides = 250
		--checking for dice count overflow
		e = mon.Attack1.DamageDiceCount * Overflow
		mon.Attack1.DamageDiceCount = mon.Attack1.DamageDiceCount * Overflow
		end
		--Just in case Dice Count fix
		if not (e == nil) then
			if (e > 250) then
			mon.Attack1.DamageDiceCount = 250
			end
		end
		--Attack 2 Overflow fix, same formula
		--add damage fix
		if (c > 250) then
		Overflow = c - 250
		mon.Attack2.DamageAdd = 250
		d=d + (math.round(2*Overflow/mon.Attack2.DamageDiceCount))
		mon.Attack2.DamageDiceSides = d
		end
		--Dice Sides fix
		if (d > 250) then
		Overflow = d / 250
		mon.Attack2.DamageDiceSides = 250
		--checking for dice count overflow
		f=mon.Attack2.DamageDiceCount * Overflow
		mon.Attack2.DamageDiceCount = mon.Attack2.DamageDiceCount * Overflow
		end
		--Just in case Dice Count fix
		if not (f ==nil) then
			if (f > 250) then
			mon.Attack2.DamageDiceCount = 250
			end
		end
		-------------------------
		--END DAMAGE CALCULATION
		-------------------------
	end
end
--------------------------------------
--DO THE SAME BUT FOR UNIQUE MONSTERS
--------------------------------------

function events.AfterLoadMap()	
	if mapvars.boosted==nil then
		mapvars.boosted=true
		--calculate average level for unique monsters
		for i=0, Map.Monsters.High do
			if (Map.Monsters[i].Name ~= Game.MonstersTxt[Map.Monsters[i].Id].Name) or (Map.Monsters[i].FullHitPoints ~= Game.MonstersTxt[Map.Monsters[i].Id].FullHitPoints) then
				mon=Map.Monsters[i]
				--HP
				mon.HP=math.min(math.round(mon.Level*(mon.Level/10+3)*2),32500)
				if ItemRework==true and StatsRework then
					mon.HP=math.min(math.round(mon.HP*(1+mon.Level/180)))
				end
				mon.FullHP=mon.HP
				--damage
				dmgMult=mon.Level/20+1.25	
				if ItemRework==true  then
					dmgMult=dmgMult*((mon.Level^1.15-1)/1000+1)
				end
				if StatsRework==true then
					dmgMult=dmgMult*((mon.Level^1.25-1)/1000+1)
				end
					
				-----------------------------------------------------------
				--DAMAGE COMPUTATION DOWN HERE, FOR BALANCE MODIFY ABOVE^
				--attack 1
				a=mon.Attack1.DamageAdd * dmgMult
				mon.Attack1.DamageAdd = mon.Attack1.DamageAdd * dmgMult
				b=mon.Attack1.DamageDiceSides * dmgMult^0.5
				mon.Attack1.DamageDiceSides = mon.Attack1.DamageDiceSides * dmgMult^0.5
				mon.Attack1.DamageDiceCount = mon.Attack1.DamageDiceCount * dmgMult^0.5
				--attack 2
				c=mon.Attack2.DamageAdd * dmgMult
				mon.Attack2.DamageAdd = mon.Attack2.DamageAdd * dmgMult
				d=mon.Attack2.DamageDiceSides * dmgMult
				mon.Attack2.DamageDiceSides = mon.Attack2.DamageDiceSides * dmgMult^0.5
				mon.Attack2.DamageDiceCount = mon.Attack2.DamageDiceCount * dmgMult^0.5
				--OVERFLOW FIX
				--Attack 1 Overflow fix
				--add damage fix
				a=0
				b=0
				c=0
				d=0
				e=0
				f=0
				if (a > 250) then
				Overflow = a - 250
				mon.Attack1.DamageAdd = 250
				b=b + (math.round(2*Overflow/mon.Attack1.DamageDiceCount))
				mon.Attack1.DamageDiceSides = b 
				end
				--Dice Sides fix
				if (b > 250) then
				Overflow = b / 250
				mon.Attack1.DamageDiceSides = 250
				--checking for dice count overflow
				e = mon.Attack1.DamageDiceCount * Overflow
				mon.Attack1.DamageDiceCount = mon.Attack1.DamageDiceCount * Overflow
				end
				--Just in case Dice Count fix
				if not (e == nil) then
					if (e > 250) then
					mon.Attack1.DamageDiceCount = 250
					end
				end
				--Attack 2 Overflow fix, same formula
				--add damage fix
				if (c > 250) then
				Overflow = c - 250
				mon.Attack2.DamageAdd = 250
				d=d + (math.round(2*Overflow/mon.Attack2.DamageDiceCount))
				mon.Attack2.DamageDiceSides = d
				end
				--Dice Sides fix
				if (d > 250) then
				Overflow = d / 250
				mon.Attack2.DamageDiceSides = 250
				--checking for dice count overflow
				f=mon.Attack2.DamageDiceCount * Overflow
				mon.Attack2.DamageDiceCount = mon.Attack2.DamageDiceCount * Overflow
				end
				--Just in case Dice Count fix
				if not (f ==nil) then
					if (f > 250) then
					mon.Attack2.DamageDiceCount = 250
					end
				end
				-------------------------
				--END DAMAGE CALCULATION
				-------------------------
		
			end
		end
	end	
end


--MODIFY MONSTERS SPELL DAMAGE

function events.CalcDamageToPlayer(t)
	data=WhoHitPlayer()
	if data and data.Object and data.Object.Spell<100 then
		dmgMult=(data.Monster.Level/16+0.75)
		if ItemRework==true  then
			dmgMult=dmgMult*((data.Monster.Level^1.15-1)/1000+1)
		end
		if StatsRework==true then
			dmgMult=dmgMult*((data.Monster.Level^1.25-1)/1000+1)
		end			
		t.Result=t.Result
	end
end
