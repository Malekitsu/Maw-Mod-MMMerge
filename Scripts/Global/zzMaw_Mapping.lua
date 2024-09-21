function events.CalcDamageToPlayer(t)
	if t.Monster and getMapAffixPower(1) then
		t.Result=t.Result*(1+getMapAffixPower(1)/100)
	end
	if getMapAffixPower(2) then
		if math.random()<getMapAffixPower(2)/100 then
			t.Result=t.Result*2
		end
	end
	if t.Monster and getMapAffixPower(10) then
		local hp=t.Player:GetFullHP()
		t.Result=t.Result+hp*getMapAffixPower(10)/100
	end
end

function events.CalcDamageToMonster(t)
	if t.Player and t.DamageKind==4 and getMapAffixPower(23) then
		t.Result=t.Result*(getMapAffixPower(23)/100)
	end
	if t.Player and t.DamageKind~=4 and getMapAffixPower(24) then
		t.Result=t.Result*(getMapAffixPower(24)/100)
	end
	if t.Player and getMapAffixPower(30) then
		if math.random()<getMapAffixPower(30)/100 then
			t.Result=0
		end
	end
	if t.Player and getMapAffixPower(34) then
		if math.random()<getMapAffixPower(34)/100 then
			t.Result=0
		end
	end
	if t.Player and getMapAffixPower(5) and t.DamageKind==4 then
		reflectedDamage=true
		t.Player:DoDamage(t.Result*(1-getMapAffixPower(5)/100),4) 
		reflectedDamage=false
	end
	if t.Player and getMapAffixPower(6) and t.DamageKind~=4 then
		reflectedDamage=true
		t.Player:DoDamage(t.Result*(1-getMapAffixPower(6)/100),t.DamageKind) 
		reflectedDamage=false
	end
end
function events.DoBadThingToPlayer(t)
	if t.Allow==false and getMapAffixPower(8) and math.random()<getMapAffixPower(8)/100 then
		t.Allow=true
		Game.ShowStatusText("Resistance Ignored")
	end
end
function events.MonsterKilled(mon)
	if getMapAffixPower(9) and math.random()<getMapAffixPower(9)/100 then
		pseudoSpawnpoint{monster = mon.Id,  x = mon.X, y = mon.Y, z = mon.Z, count = 1, powerChances = {55, 30, 15}, radius = 128, group = 2,}
	end
	
end
function events.Tick()
	if getMapAffixPower(11) then
		monLocation=monLocation or {}
		for i=1, Map.Monsters.High do
			local mon=Map.Monsters[i]
			if not monLocation[i] then
				monLocation[i]={mon.X,mon.Y}
			end
			if math.abs(mon.X-monLocation[i][1])<100 and math.abs(mon.Y-monLocation[i][2])<100 then
				mon.X=mon.X + (mon.X-monLocation[i][1])*getMapAffixPower(11)/100
				mon.Y=mon.Y + (mon.Y-monLocation[i][2])*getMapAffixPower(11)/100
			end
			monLocation[i][1]=mon.X
			monLocation[i][2]=mon.Y
		end
	end
end
function events.Tick()
	if getMapAffixPower(25) then
		vars.lastX=vars.lastX or Party.X
		vars.lastY=vars.lastY or Party.Y
		push1=(Party.X-vars.lastX)
		push2=(Party.Y-vars.lastY)
		Party.X=Party.X- push1*getMapAffixPower(25)/100
		Party.Y=Party.Y- push2*getMapAffixPower(25)/100
		vars.lastX=Party.X
		vars.lastY=Party.Y
	end
end
function events.GetAttackDelay(t)
	if getMapAffixPower(26) then
		t.Result=math.round(t.Result/(1-getMapAffixPower(26)/100))
	end
end

function events.AfterLoadMap()
	if getMapAffixPower(33) then
		local nerf=1-getMapAffixPower(33)/100
		for key,value in pairs(buffPower) do 
			buff=buffPower[key]
			for i=0,4 do
				buff.Base[i]=buff.Base[i]*nerf
				buff.Scaling[i]=buff.Scaling[i]*nerf
			end
		end
		buffPower={ --values are inteneded as % and /1000 for scaling
			[3]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--fire res  
			[14]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--air res
			[25]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--water res
			[36]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--earth res
			[58]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--mind res
			[69]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--body res
			[5]= {["Base"]={[0]=0,10,10,10,10}, ["Scaling"]={[0]=0,2,2,2,2}},--haste
			[17]= {["Base"]={[0]=0,10,10,10,10}, ["Scaling"]={[0]=0,2,2,2,2}},--shield
			[28]= {["Base"]={[0]=0,15,15,15,15}, ["Scaling"]={[0]=0,3,3,3,3}},--Empower Magic
			[38]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--stoneskin
			[46]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--bless, acc bonus is calculated by using fire res bonus
			[47]= {["Base"]={[0]=0,5,5,5,5}, ["Scaling"]={[0]=0,1,1,1,1}},--fate
			[51]= {["Base"]={[0]=0,15,15,15,15}, ["Scaling"]={[0]=0,3,3,3,3}},--Heroism
			[56]= {["Base"]={[0]=0,10,10,10,10}, ["Scaling"]={[0]=0,2,2,2,2}},--Meditation
			[71]= {["Base"]={[0]=0,5,5,5,5}, ["Scaling"]={[0]=0,2,2,2,2}},--Regeneration (check code before changing, fomula is complex)
			[73]= {["Base"]={[0]=0,15,15,15,15}, ["Scaling"]={[0]=0,3,3,3,3}},--Hammerhands
			[83]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,1.5,1.5,1.5,1.5}},--day of the gods
			[85]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--day of Protection
			[86]= {["Base"]={[0]=0,10,10,10,10}, ["Scaling"]={[0]=0,2,2,2,2}},--hour of power (formulas don't use this values, but takes skill and divide by 1.5)
		}
	else
		buffPower={ --values are inteneded as % and /1000 for scaling
			[3]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--fire res  
			[14]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--air res
			[25]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--water res
			[36]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--earth res
			[58]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--mind res
			[69]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--body res
			[5]= {["Base"]={[0]=0,10,10,10,10}, ["Scaling"]={[0]=0,2,2,2,2}},--haste
			[17]= {["Base"]={[0]=0,10,10,10,10}, ["Scaling"]={[0]=0,2,2,2,2}},--shield
			[28]= {["Base"]={[0]=0,15,15,15,15}, ["Scaling"]={[0]=0,3,3,3,3}},--Empower Magic
			[38]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--stoneskin
			[46]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--bless, acc bonus is calculated by using fire res bonus
			[47]= {["Base"]={[0]=0,5,5,5,5}, ["Scaling"]={[0]=0,1,1,1,1}},--fate
			[51]= {["Base"]={[0]=0,15,15,15,15}, ["Scaling"]={[0]=0,3,3,3,3}},--Heroism
			[56]= {["Base"]={[0]=0,10,10,10,10}, ["Scaling"]={[0]=0,2,2,2,2}},--Meditation
			[71]= {["Base"]={[0]=0,5,5,5,5}, ["Scaling"]={[0]=0,2,2,2,2}},--Regeneration (check code before changing, fomula is complex)
			[73]= {["Base"]={[0]=0,15,15,15,15}, ["Scaling"]={[0]=0,3,3,3,3}},--Hammerhands
			[83]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,1.5,1.5,1.5,1.5}},--day of the gods
			[85]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--day of Protection
			[86]= {["Base"]={[0]=0,10,10,10,10}, ["Scaling"]={[0]=0,2,2,2,2}},--hour of power (formulas don't use this values, but takes skill and divide by 1.5)
		}
	end
end
