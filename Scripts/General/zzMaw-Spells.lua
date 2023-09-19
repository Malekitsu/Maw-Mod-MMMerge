-------------------------------------------------
--Nerf to Day of Protection and Day of the Gods--
-------------------------------------------------
function events.Tick()
	--Day of Protection
	dopList = {0, 1, 4, 6, 12, 17}
	for i = 1, #dopList do
		item=dopList[i]
		if Party.SpellBuffs[item].Skill>=2 then
			m=Party.SpellBuffs[item].Skill
			Party.SpellBuffs[item].Power=Party.SpellBuffs[item].Power/(m+1)*(m-1)
			Party.SpellBuffs[item].Skill=1
		end
	end
	
	--Day of the Gods
	if Party.SpellBuffs[2].Skill>=2 then
		m=Party.SpellBuffs[2].Skill
		Party.SpellBuffs[2].Power=(Party.SpellBuffs[2].Power-10)/(m+1)*(m/2)+5*m
		Party.SpellBuffs[2].Skill=1
	end
end

----------------
--Tooltips fix--
----------------

--Day of Protection
function events.GameInitialized2()
	Game.SpellsTxt[83].Description="Temporarily increases all seven stats on all your characters by 1 per skill in Light Magic.  This spell lasts until you rest."
	Game.SpellsTxt[83].Expert="All stats increased by 10+1 per skill"
	Game.SpellsTxt[83].Master="All stats increased by 15+1.5 per skill"
	Game.SpellsTxt[83].GM="All stats increased by 20+2 per skill"

	--Day of the Gods
	Game.SpellsTxt[85].Description="Simultaneously casts Protection from Fire, Air, Water, Earth, Mind, and Body, plus Feather Fall and Wizard Eye on all your characters at two times your skill in Light Magic."
	Game.SpellsTxt[85].Master="All spells cast at two times skill"
	Game.SpellsTxt[85].GM="All spells cast at three times skill"
end

------------------------------
------MANA COST CHANGE--------
------------------------------

--spell cost increase dictionary
function events.GameInitialized2()
	spellCostNormal={}
	spellCostExpert={}
	spellCostMaster={}
	spellCostGM={}
	for i=1,132 do
		spellCostNormal[i] = Game.Spells[i]["SpellPointsNormal"]
		spellCostExpert[i] = Game.Spells[i]["SpellPointsExpert"]
		spellCostMaster[i] = Game.Spells[i]["SpellPointsMaster"]
		spellCostGM[i] = Game.Spells[i]["SpellPointsGM"]
	end
	ascendanceCost={10,15,20,30,40,50,60,70,80,90,100,[0]=100}
	ascendanceCost2={20,30,40,60,80,100,120,140,160,180,200,[0]=200}
	spells={2,6,7,8,9,10,11,15,18,20,22,24,26,29,32,37,39,41,43,44,52,59,65,70,76,78,79,84,87,90,93,97,98,99,103,111,123}
	lastIndex=-1 --used later

	--if you change diceMin or values that are 0 remember to update the tooltip manually 
	spellPowers =
		{
			[2] = {dmgAdd = 0, diceMin = 1, diceMax = 3, },--fire bolt
			[6] = {dmgAdd = 0, diceMin = 1, diceMax = 6, },--fireball
			[7] = {dmgAdd = 0, diceMin = 1, diceMax = 6, },--fire spike, the only spell with damage depending on mastery, fix in events.calcspelldamage
			[8] = {dmgAdd = 0, diceMin = 1, diceMax = 6, },--immolation
			[9] = {dmgAdd = 8, diceMin = 1, diceMax = 1, },--meteor shower
			[10] = {dmgAdd = 12, diceMin = 2, diceMax = 2, },--inferno
			[11] = {dmgAdd = 15, diceMin = 1, diceMax = 15, },--incinerate
			[15] = {dmgAdd = 2, diceMin = 1, diceMax = 1, },--sparks
			[18] = {dmgAdd = 0, diceMin = 1, diceMax = 8, },--lightning bolt
			[20] = {dmgAdd = 12, diceMin = 1, diceMax = 12, },--implosion
			[22] = {dmgAdd = 20, diceMin = 1, diceMax = 1, },--starburst
			[24] = {dmgAdd = 2, diceMin = 1, diceMax = 2, },--poison spray
			[26] = {dmgAdd = 0, diceMin = 1, diceMax = 4, },--ice bolt
			[29] = {dmgAdd = 9, diceMin = 1, diceMax = 9, },--acid burst
			[32] = {dmgAdd = 12, diceMin = 1, diceMax = 6, },--ice blast
			[37] = {dmgAdd = 5, diceMin = 1, diceMax = 3, },--deadly swarm
			[39] = {dmgAdd = 0, diceMin = 1, diceMax = 9, },--blades
			[41] = {dmgAdd = 10, diceMin = 1, diceMax = 10, },--rock blast
			[43] = {dmgAdd = 20, diceMin = 2, diceMax = 2, },--death blossom
			[44] = {dmgAdd = 15, diceMin = 1, diceMax = 1, },--mass distorsion, nerfed
			[52] = {dmgAdd = 10, diceMin = 2, diceMax = 8, },--spirit lash
			[59] = {dmgAdd = 3, diceMin = 1, diceMax = 3, },--mind blast
			[65] = {dmgAdd = 12, diceMin = 1, diceMax = 12, },--psychic shock
			[70] = {dmgAdd = 8, diceMin = 1, diceMax = 2, },--harm
			[76] = {dmgAdd = 20, diceMin = 1, diceMax = 10, },--flying fist
			[78] = {dmgAdd = 0, diceMin = 1, diceMax = 4, },--light bolt
			[79] = {dmgAdd = 16, diceMin = 1, diceMax = 16, },--destroy undead
			[84] = {dmgAdd = 25, diceMin = 1, diceMax = 1, },--prismatic light
			[87] = {dmgAdd = 20, diceMin = 1, diceMax = 20, },--sunray
			[90] = {dmgAdd = 25, diceMin = 1, diceMax = 10, },--toxic cloud
			[93] = {dmgAdd = 0, diceMin = 1, diceMax = 6, },--shrapmetal
			[97] = {dmgAdd = 0, diceMin = 1, diceMax = 25, },--dragon breath
			[98] = {dmgAdd = 50, diceMin = 1, diceMax = 1, },--armageddon
			[99] = {dmgAdd = 25, diceMin = 1, diceMax = 8, },--souldrinker
			[103] = {dmgAdd = 17, diceMin = 1, diceMax = 17, },--darkfire bolt
			[111] = {dmgAdd = 15, diceMin = 1, diceMax = 3, },--lifedrain scales with mastery, fixed in calcspelldamage
			[123] = {dmgAdd = 10, diceMin = 1, diceMax = 10, },--flame blast scales with mastery, fixed in calcspelldamage
		}

	--calculate table for spells from level 100
	spellPowers80={}
	spellPowers160={}
	for i =1,132 do
		if spellPowers[i] then
			--calculate damage assuming formula is manacost^0.7
			local theoreticalDamage=spellCostNormal[i]^0.7
			local dmgAddProportion=spellPowers[i].dmgAdd/theoreticalDamage
			if spellPowers[i].diceMax==spellPowers[i].diceMin then
				diceMaxProportion=spellPowers[i].diceMax/theoreticalDamage
			else
				diceMaxProportion=((spellPowers[i].diceMax+1)/2)/theoreticalDamage
			end
			--get new mana cost and calculate theoretical Damage for level 80+
			local manaCost=ascendanceCost[i%11]
			if i>77 and i<100 then
				manaCost=manaCost*1.5
			end
			--exception for racial spells
			if i==103 then 
				manaCost=100
			end
			if i==111 then 
				manaCost=30
			end
			if i==123 then 
				manaCost=60
			end
			local theoreticalDamage80=manaCost^0.7
			--scale new values according to original differences
			local dmgAdd80=math.round(theoreticalDamage80*dmgAddProportion)
			if spellPowers[i].diceMax==spellPowers[i].diceMin then
				diceMax80=math.round(theoreticalDamage80*diceMaxProportion)
			else
				diceMax80=math.round(theoreticalDamage80*(diceMaxProportion)*2)+1
			end
			spellPowers80[i]={dmgAdd = dmgAdd80, diceMin = 1, diceMax = diceMax80,}
			----------
			--do the same, but for level 160
			----------
			--get new mana cost and calculate theoretical Damage for level 80+
			local manaCost=ascendanceCost2[i%11]
			if i>77 and i<100 then
				manaCost=manaCost*1.5
			end
			--exception for racial spells
			if i==103 then 
				manaCost=200
			end
			if i==111 then 
				manaCost=60
			end
			if i==123 then 
				manaCost=120
			end
			local theoreticalDamage160=manaCost^0.7
			--scale new values according to original differences
			local dmgAdd160=math.round(theoreticalDamage80*dmgAddProportion)
			if spellPowers[i].diceMax==spellPowers[i].diceMin then
				diceMax160=math.round(theoreticalDamage160*diceMaxProportion)
			else
				diceMax160=math.round(theoreticalDamage160*(diceMaxProportion)*2)+1
			end
			spellPowers160[i]={dmgAdd = dmgAdd160, diceMin = 1, diceMax = diceMax160,}
		end
	end
end

--calculate spell Damage
function events.CalcSpellDamage(t)
	--mass distorsion
	if t.Spell == 44 then 
		t.Result = t.HP*0.15+t.HP*t.Skill*0.01
		return
	end
	--check for spell tier
	local spellTier=t.Spell%11
	if spellTier==0 then
		spellTier=11
	end
	--take damage info
	if spellPowers[t.Spell]==nil then return end
	diceMin=spellPowers[t.Spell].diceMin
	diceMax=spellPowers[t.Spell].diceMax
	damageAdd=spellPowers[t.Spell].dmgAdd
	local data=WhoHitMonster()
	if data and data.Player then
	--calculate if level is>treshold to check for lvl 100 spells
		if data.Player.LevelBase>=spellTier*8+152 then
			diceMin=spellPowers160[t.Spell].diceMin
			diceMax=spellPowers160[t.Spell].diceMax
			damageAdd=spellPowers160[t.Spell].dmgAdd
		elseif data.Player.LevelBase>=spellTier*8+72 then
			diceMin=spellPowers80[t.Spell].diceMin
			diceMax=spellPowers80[t.Spell].diceMax
			damageAdd=spellPowers80[t.Spell].dmgAdd
		end	
	end
	--calculate
	if t.Spell>1 and t.Spell<132 then
		if diceMin~=diceMax then --roll dices
			damage=0
			for i=1,t.Skill do
				damage=damage+math.random(diceMin,diceMax)
			end
			t.Result=damageAdd+damage
		else
			t.Result=damageAdd+spellPowers[t.Spell].diceMax*t.Skill
		end
	end
	
	--fix for mastery scaling spells
	if t.Spell == 7 then  -- fire spike
		if t.Mastery==3 then
			t.Result=t.Result/6*8
		elseif t.Mastery==4 then
			t.Result=t.Result/6*10
		end
	end
	if t.Spell == 111 then  -- lifedrain
		if t.Mastery==3 then
			t.Result=t.Result/3*5
		elseif t.Mastery==4 then
			t.Result=t.Result/3*7
		end
	end
	if t.Spell == 123 then  -- flame blast
		if t.Mastery==3 then
			t.Result=t.Result/10*11
		elseif t.Mastery==4 then
			t.Result=t.Result/10*12
		end
	end
end

--add enchant damage


spellbonusdamage={}
spellbonusdamage[4] = {["low"]=6, ["high"]=8}
spellbonusdamage[5] = {["low"]=18, ["high"]=24}
spellbonusdamage[6] = {["low"]=36, ["high"]=48}
spellbonusdamage[7] = {["low"]=4, ["high"]=10}
spellbonusdamage[8] = {["low"]=12, ["high"]=30}
spellbonusdamage[9] = {["low"]=24, ["high"]=60}
spellbonusdamage[10] = {["low"]=2, ["high"]=12}
spellbonusdamage[11] = {["low"]=6, ["high"]=36}
spellbonusdamage[12] = {["low"]=12, ["high"]=72}
spellbonusdamage[13] = {["low"]=12, ["high"]=12}
spellbonusdamage[14] = {["low"]=24, ["high"]=24}
spellbonusdamage[15] = {["low"]=48, ["high"]=48}

aoespells = {6, 7, 8, 9, 10, 15, 22, 26, 32, 41, 43, 84, 92, 97, 98, 99, 123}
function events.CalcSpellDamage(t)
data=WhoHitMonster()
	if data and data.Player then
		it=data.Player:GetActiveItem(1)
		if it then
			if spellbonusdamage[it.Bonus2] then
				damage=math.random(spellbonusdamage[it.Bonus2]["low"],spellbonusdamage[it.Bonus2]["high"])
				for i = 1, #aoespells do
					if aoespells[i] == t.Spell then
						damage=damage/2.5
					end
				end
				if it.MaxCharges>0 then
					if it.MaxCharges <= 20 then
						mult=1+it.MaxCharges/20
					else
						mult=2+2*(it.MaxCharges-20)/20
					end
					damage=damage*mult
				end
				t.Result = t.Result+damage
			end
		end
	end
end

--function for tooltips
function dmgAddTooltip(level,spellIndex)
	--exception for racials
	if spellIndex==104 then 
		if level>=240 then
			local dmgAdd=spellPowers160[spellIndex].dmgAdd
			return dmgAdd
		elseif level>=160 then
			local dmgAdd=spellPowers80[spellIndex].dmgAdd
			return dmgAdd
		else 
			local dmgAdd=spellPowers[spellIndex].dmgAdd
			return dmgAdd
		end
	end
	if spellIndex==111 then 
		if level>=180 then
			local dmgAdd=spellPowers160[spellIndex].dmgAdd
			return dmgAdd
		elseif level>=100 then
			local dmgAdd=spellPowers80[spellIndex].dmgAdd
			return dmgAdd
		else 
			local dmgAdd=spellPowers[spellIndex].dmgAdd
			return dmgAdd
		end
	end
	if spellIndex==123 then 
		if level>=200 then
			local dmgAdd=spellPowers160[spellIndex].dmgAdd
			return dmgAdd
		elseif level>=120 then
			local dmgAdd=spellPowers80[spellIndex].dmgAdd
			return dmgAdd
		else 
			local dmgAdd=spellPowers[spellIndex].dmgAdd
			return dmgAdd
		end
	end
	--check for index to see if to show normal or ascended spells
	local index=spellIndex%11
	if index==0 then
		index=11
	end
	if level>=index*8+152 then
		local dmgAdd=spellPowers160[spellIndex].dmgAdd
		return dmgAdd
	elseif level>=index*8+72 then
		local dmgAdd=spellPowers80[spellIndex].dmgAdd
		return dmgAdd
	else 
		local dmgAdd=spellPowers[spellIndex].dmgAdd
		return dmgAdd
	end
end

function diceMaxTooltip(level,spellIndex)
	--exception for racials
	if spellIndex==104 then 
		if level>=240 then
			local diceMax=spellPowers160[spellIndex].diceMax
			return diceMax
		elseif level>=160 then
			local diceMax=spellPowers80[spellIndex].diceMax
			return diceMax
		else 
			local diceMax=spellPowers[spellIndex].diceMax
			return diceMax
		end
	end
	if spellIndex==111 then 
		if level>=180 then
			local diceMax=spellPowers160[spellIndex].diceMax
			return diceMax
		elseif level>=100 then
			local diceMax=spellPowers80[spellIndex].diceMax
			return diceMax
		else 
			local diceMax=spellPowers[spellIndex].diceMax
			return diceMax
		end
	end
	if spellIndex==123 then 
		if level>=200 then
			local diceMax=spellPowers160[spellIndex].diceMax
			return diceMax
		elseif level>=120 then
			local diceMax=spellPowers80[spellIndex].diceMax
			return diceMax
		else 
			local diceMax=spellPowers[spellIndex].diceMax
			return diceMax
		end
	end
	--check for index to see if to show normal or ascended spells
	local index=spellIndex%11
	if index==0 then
		index=11
	end
	if level>=index*8+152 then
		local diceMax=spellPowers160[spellIndex].diceMax
		return diceMax
	elseif level>=index*8+72 then
		local diceMax=spellPowers80[spellIndex].diceMax
		return diceMax
	else 
		local diceMax=spellPowers[spellIndex].diceMax
		return diceMax
	end
end

--adjust mana cost and tooltips	
function events.Tick()
	index=Game.CurrentPlayer
	if index>=0 then
		local level=Party[index].LevelBase
		if lastIndex~=index or lastLevel~=level then
			lastIndex=index
			lastLevel=level
			for _, num in ipairs(spells) do 
				--check for level
				if num%11==0 then
					num2=11
				else
					num2=num%11
				end
				if num<100 then
					local check2=(num2)*8+152
					local check=(num2)*8+72
					if level>=check2 then
						if num>77 then --increase light and dark cost
							Game.Spells[num]["SpellPointsNormal"] = ascendanceCost2[num2]*1.5
							Game.Spells[num]["SpellPointsExpert"] = ascendanceCost2[num2]*1.5
							Game.Spells[num]["SpellPointsMaster"] = ascendanceCost2[num2]*1.5
							Game.Spells[num]["SpellPointsGM"] = ascendanceCost2[num2]*1.5
						else
							Game.Spells[num]["SpellPointsNormal"] = ascendanceCost2[num2]
							Game.Spells[num]["SpellPointsExpert"] = ascendanceCost2[num2]
							Game.Spells[num]["SpellPointsMaster"] = ascendanceCost2[num2]
							Game.Spells[num]["SpellPointsGM"] = ascendanceCost2[num2]
						end
					elseif level>=check then
						if num>77 then --increase light and dark cost
							Game.Spells[num]["SpellPointsNormal"] = ascendanceCost[num2]*1.5
							Game.Spells[num]["SpellPointsExpert"] = ascendanceCost[num2]*1.5
							Game.Spells[num]["SpellPointsMaster"] = ascendanceCost[num2]*1.5
							Game.Spells[num]["SpellPointsGM"] = ascendanceCost[num2]*1.5
						else
							Game.Spells[num]["SpellPointsNormal"] = ascendanceCost[num2]
							Game.Spells[num]["SpellPointsExpert"] = ascendanceCost[num2]
							Game.Spells[num]["SpellPointsMaster"] = ascendanceCost[num2]
							Game.Spells[num]["SpellPointsGM"] = ascendanceCost[num2]
						end
					else
						Game.Spells[num]["SpellPointsNormal"]=spellCostNormal[num]
						Game.Spells[num]["SpellPointsExpert"]=spellCostExpert[num]
						Game.Spells[num]["SpellPointsMaster"]=spellCostMaster[num] 
						Game.Spells[num]["SpellPointsGM"]=spellCostGM[num]	
					end	
				end				
				--cost exception for racials
				if num==103 then
					local check2=240
					local check=160
					if level>=check2 then
						Game.Spells[num]["SpellPointsNormal"] = ascendanceCost2[11]
						Game.Spells[num]["SpellPointsExpert"] = ascendanceCost2[11]
						Game.Spells[num]["SpellPointsMaster"] = ascendanceCost2[11]
						Game.Spells[num]["SpellPointsGM"] = ascendanceCost2[11]
					elseif level>=check then
						Game.Spells[num]["SpellPointsNormal"] = ascendanceCost[11]
						Game.Spells[num]["SpellPointsExpert"] = ascendanceCost[11]
						Game.Spells[num]["SpellPointsMaster"] = ascendanceCost[11]
						Game.Spells[num]["SpellPointsGM"] = ascendanceCost[11]
					else
						Game.Spells[num]["SpellPointsNormal"]=spellCostNormal[num]
						Game.Spells[num]["SpellPointsExpert"]=spellCostExpert[num]
						Game.Spells[num]["SpellPointsMaster"]=spellCostMaster[num] 
						Game.Spells[num]["SpellPointsGM"]=spellCostGM[num]	
					end	
				end	
				if num==111 then
					local check2=180
					local check=100
					if level>=check2 then
						Game.Spells[num]["SpellPointsNormal"] = ascendanceCost2[4]
						Game.Spells[num]["SpellPointsExpert"] = ascendanceCost2[4]
						Game.Spells[num]["SpellPointsMaster"] = ascendanceCost2[4]
						Game.Spells[num]["SpellPointsGM"] = ascendanceCost2[4]
					elseif level>=check then
						Game.Spells[num]["SpellPointsNormal"] = ascendanceCost[4]
						Game.Spells[num]["SpellPointsExpert"] = ascendanceCost[4]
						Game.Spells[num]["SpellPointsMaster"] = ascendanceCost[4]
						Game.Spells[num]["SpellPointsGM"] = ascendanceCost[4]
					else
						Game.Spells[num]["SpellPointsNormal"]=spellCostNormal[num]
						Game.Spells[num]["SpellPointsExpert"]=spellCostExpert[num]
						Game.Spells[num]["SpellPointsMaster"]=spellCostMaster[num] 
						Game.Spells[num]["SpellPointsGM"]=spellCostGM[num]	
					end	
				end	
				if num==123 then
					local check2=200
					local check=120
					if level>=check2 then
						Game.Spells[num]["SpellPointsNormal"] = ascendanceCost2[8]
						Game.Spells[num]["SpellPointsExpert"] = ascendanceCost2[8]
						Game.Spells[num]["SpellPointsMaster"] = ascendanceCost2[8]
						Game.Spells[num]["SpellPointsGM"] = ascendanceCost2[8]
					elseif level>=check then
						Game.Spells[num]["SpellPointsNormal"] = ascendanceCost[8]
						Game.Spells[num]["SpellPointsExpert"] = ascendanceCost[8]
						Game.Spells[num]["SpellPointsMaster"] = ascendanceCost[8]
						Game.Spells[num]["SpellPointsGM"] = ascendanceCost[8]
					else
						Game.Spells[num]["SpellPointsNormal"]=spellCostNormal[num]
						Game.Spells[num]["SpellPointsExpert"]=spellCostExpert[num]
						Game.Spells[num]["SpellPointsMaster"]=spellCostMaster[num] 
						Game.Spells[num]["SpellPointsGM"]=spellCostGM[num]	
					end	
				end		
			end	
			
			
				
			--change tooltips according to ascended damage
			Game.SpellsTxt[2].Description=string.format("Launches a burst of fire at a single target.  Damage is 1-%s points of damage per point of skill in Fire Magic.   Firebolt is safe, effective and has a low casting cost.",diceMaxTooltip(level,2))
			Game.SpellsTxt[6].Description=string.format("Fires a ball of fire at a single target. When it hits, the ball explodes damaging all those nearby, including your characters if they're too close.  Fireball does 1-%s points of damage per point of skill in Fire Magic.",diceMaxTooltip(level,6))
			--fire spikes fix
			Game.SpellsTxt[7].Expert=string.format("Causes 1-%s points of damage per point of skill, 5 spikes maximum",diceMaxTooltip(level,7))
			Game.SpellsTxt[7].Master=string.format("Causes 1-%s points of damage per point of skill, 5 spikes maximum",math.round(diceMaxTooltip(level,7)/6*8))
			Game.SpellsTxt[7].GM=string.format("Causes 1-%s points of damage per point of skill, 5 spikes maximum",math.round(diceMaxTooltip(level,7)/6*10))
			----------------------------------------
			
			Game.SpellsTxt[8].Description=string.format("Surrounds your characters with a very hot fire that is only harmful to others.  The spell will deliver 1-%s points of damage per point of skill to all nearby monsters for as long as they remain in the area of effect.",diceMaxTooltip(level,8))
			Game.SpellsTxt[9].Description=string.format("Summons flaming rocks from the sky which fall in a large radius surrounding your chosen target.  Try not to be near the victim when you use this spell.  A single meteor does %s points of damage plus %s per point of skill in Fire Magic.  This spell only works outdoors.",dmgAddTooltip(level,9),diceMaxTooltip(level,9))
			Game.SpellsTxt[10].Description=string.format("Inferno burns all monsters in sight when cast, excluding your characters.  One or two castings can clear out a room of weak or moderately powerful creatures. Each monster takes %s points of damage plus %s per point of skill in Fire Magic.  This spell only works indoors.",dmgAddTooltip(level,10),diceMaxTooltip(level,10))
			Game.SpellsTxt[11].Description=string.format("Among the strongest direct damage spells available, Incinerate inflicts massive damage on a single target.  Only the strongest of monsters can expect to survive this spell.  Damage is %s points plus 1-%s per point of skill in Fire Magic.",dmgAddTooltip(level,11),diceMaxTooltip(level,11))
			Game.SpellsTxt[15].Description=string.format("Sparks fires small balls of lightning into the world that bounce around until they hit something or dissipate. It is hard to tell where they will go, so this spell is best used in a room crowded with small monsters. Each spark does %s points plus %s per point of skill in Air Magic.",dmgAddTooltip(level,15),diceMaxTooltip(level,15))
			Game.SpellsTxt[18].Description=string.format("Lightning Bolt discharges electricity from the caster's hand to a single target.  It always hits and does 1-%s points of damage per point of skill in Air Magic.",diceMaxTooltip(level,18))
			Game.SpellsTxt[20].Description=string.format("Implosion is a nasty spell that affects a single target by destroying the air around it, causing a sudden inrush from the surrounding air, a thunderclap, and %s points plus 1-%s points of damage per point of skill in Air Magic.",dmgAddTooltip(level,20),diceMaxTooltip(level,20))
			Game.SpellsTxt[22].Description=string.format("Calls stars from the heavens to smite and burn your enemies.  Twenty stars are called, and the damage for each star is 20 points plus 1 per point of skill in Air Magic. Try not to get caught in the blast! This spell only works outdoors.",dmgAddTooltip(level,22),diceMaxTooltip(level,22))
			Game.SpellsTxt[24].Description=string.format("Sprays poison at monsters directly in front of your characters.  Damage is low, but few monsters have resistance to Water Magic, so it usually works.  Each shot does %s points of damage plus 1-%s per point of skill.",dmgAddTooltip(level,24),diceMaxTooltip(level,24))
			Game.SpellsTxt[26].Description=string.format("Fires a bolt of ice at a single target.  The missile does 1-%s points of damage per point of skill in Water Magic.",diceMaxTooltip(level,26))
			Game.SpellsTxt[29].Description=string.format("Acid burst squirts a jet of extremely caustic acid at a single victim.  It always hits and does %s points of damage plus 1-%s per point of skill.",dmgAddTooltip(level,29),diceMaxTooltip(level,29))
			Game.SpellsTxt[32].Description=string.format("Fires a ball of ice in the direction the caster is facing.  The ball will shatter when it hits something, launching 7 shards of ice in all directions except the caster's.  The shards will ricochet until they strike a creature or melt.  Each shard does %s points of damage plus 1-%s per point of skill in Water Magic.",dmgAddTooltip(level,32),diceMaxTooltip(level,32))
			Game.SpellsTxt[37].Description=string.format("Summons a swarm of biting, stinging insects to bedevil a single target.  The swarm does %s points of damage plus 1-%s per point of skill in Earth Magic.",dmgAddTooltip(level,37),diceMaxTooltip(level,37))
			Game.SpellsTxt[39].Description=string.format("Fires a rotating, razor-thin metal blade at a single monster.  The blade does 1-%s points of damage per point of skill in Earth Magic.",diceMaxTooltip(level,39))
			Game.SpellsTxt[41].Description=string.format("Releases a magical stone into the world that will explode when it comes into contact with a creature or enough time passes.  The rock will bounce and roll until it finds a resting spot, so be careful not to be caught in the blast.  The explosion causes %s points of damage plus 1-%s points of damage per point of skill in Earth Magic.",dmgAddTooltip(level,41),diceMaxTooltip(level,41))
			Game.SpellsTxt[43].Description=string.format("Launches a magical stone which bursts in air, sending shards of explosive earth raining to the ground.  The damage is %s points plus %s per point of skill in Earth Magic for each shard.  This spell can only be used outdoors.",dmgAddTooltip(level,43),diceMaxTooltip(level,43))
			Game.SpellsTxt[44].Description=string.format("Increases the weight of a single target enormously for an instant, causing internal damage equal to %s%% of the monster's hit points plus another %s%% per point of skill in Earth Magic.  The bigger they are, the harder they fall.",dmgAddTooltip(level,44),diceMaxTooltip(level,44))
			Game.SpellsTxt[52].Description=string.format("This spell weakens the link between a target's body and soul, causing %s + 2-%s points of damage per point of skill in Spirit Magic to all monsters near the caster.",dmgAddTooltip(level,52),diceMaxTooltip(level,52))
			Game.SpellsTxt[59].Description=string.format("Fires a bolt of mental force which damages a single target's nervous system.  Mind Blast does %s points of damage plus 1-%s per point of skill in Mind Magic.",dmgAddTooltip(level,59),diceMaxTooltip(level,59))
			Game.SpellsTxt[65].Description=string.format("Similar to Mind Blast, Psychic Shock targets a single creature with mind damaging magic--only it has a much greater effect.  Psychic Shock does %s points of damage plus 1-%s per point of skill in Mind Magic.",dmgAddTooltip(level,65),diceMaxTooltip(level,65))
			Game.SpellsTxt[70].Description=string.format("Directly inflicts magical damage upon a single creature.  Harm does %s points of damage plus 1-%s per point of skill in Body Magic.",dmgAddTooltip(level,70),diceMaxTooltip(level,70))
			Game.SpellsTxt[76].Description=string.format("Flying Fist throws a heavy magical force at a single opponent that does %s points of damage plus 1-%s per point of skill in Body Magic.",dmgAddTooltip(level,76),diceMaxTooltip(level,76))
			Game.SpellsTxt[78].Description=string.format("Fires a bolt of light at a single target that does 1-%s points of damage per point of skill in light magic.  Damage vs. Undead is doubled.",diceMaxTooltip(level,78))
			Game.SpellsTxt[79].Description=string.format("Calls upon the power of heaven to undo the evil magic that extends the lives of the undead, inflicting %s points of damage plus 1-%s per point of skill in Light Magic upon a single, unlucky target.  This spell only works on the undead.",dmgAddTooltip(level,79),diceMaxTooltip(level,79))
			Game.SpellsTxt[84].Description=string.format("Inflicts %s points of damage plus %s per point of skill in Light Magic on all creatures in sight.  This spell can only be cast indoors.",dmgAddTooltip(level,84),diceMaxTooltip(level,84))
			Game.SpellsTxt[87].Description=string.format("Sunray is the second most devastating damage spell in the game. It does %s points of damage plus 1-%s points per point of skill in Light Magic, by concentrating the light of the sun on one unfortunate creature. It only works outdoors during the day.",dmgAddTooltip(level,87),diceMaxTooltip(level,87))
			Game.SpellsTxt[90].Description=string.format("A poisonous cloud of noxious gases is formed in front of the caster and moves slowly away from your characters.  The cloud does 25 points of damage plus 1-10 per point of skill in Dark Magic and lasts until something runs into it.",dmgAddTooltip(level,90),diceMaxTooltip(level,90))
			Game.SpellsTxt[93].Description=string.format("Fires a blast of hot, jagged metal in front of the caster, striking any creature that gets in the way.  Each piece inflicts 1-%s points of damage per point of skill in Dark Magic.",diceMaxTooltip(level,93))
			Game.SpellsTxt[97].Description=string.format("Dragon Breath empowers the caster to exhale a cloud of toxic vapors that targets a single monster and damage all creatures nearby, doing 1-%s points of damage per point of skill in Dark Magic.",diceMaxTooltip(level,97))
			Game.SpellsTxt[98].Description=string.format("This spell is the town killer. Armageddon inflicts %s points of damage plus %s point of damage for every point of Dark skill your character has to every creature on the map, including all your characters. It can only be cast three times per day and only outdoors.",dmgAddTooltip(level,98),diceMaxTooltip(level,98))
			Game.SpellsTxt[99].Description=string.format("This horrible spell sucks the life from all creatures in sight, friend or enemy.  Souldrinker then transfers that life to your party in much the same fashion as Shared Life.  Damage (and healing) is %s + 1-%s per point of skill.",dmgAddTooltip(level,99),diceMaxTooltip(level,99))
			
			Game.SpellsTxt[103].Description=string.format("This frightening ability grants the Dark Elf the power to wield Darkfire, a dangerous combination of the powers of Dark and Fire. Any target stricken by the Darkfire bolt resists with either its Fire or Dark resistance--whichever is lower. Damage is 1-%s per point of skill.",diceMaxTooltip(level,103))
			Game.SpellsTxt[111].Description=string.format("Lifedrain allows the vampire to damage his or her target and simultaneously heal based on the damage done in the Lifedrain.  This ability does %s points of damage plus 1-%s points of damage per skill.",dmgAddTooltip(level,111),diceMaxTooltip(level,111))
			Game.SpellsTxt[111].Master=string.format("Damage %s points plus 1-%s per point of skill",math.round(dmgAddTooltip(level,111)/3*5),math.round(diceMaxTooltip(level,111)/3*5))
			Game.SpellsTxt[111].GM=string.format("Damage %s points plus 1-%s per point of skill",math.round(dmgAddTooltip(level,111)/3*7),math.round(diceMaxTooltip(level,111)/3*7))
			Game.SpellsTxt[123].Expert=string.format("Damage %s points plus 1-%s points per point of skill",dmgAddTooltip(level,123),diceMaxTooltip(level,123))
			Game.SpellsTxt[123].Master=string.format("Damage %s points plus 1-%s points per point of skill",math.round(dmgAddTooltip(level,123)/10*11),math.round(diceMaxTooltip(level,123)/10*11))
			Game.SpellsTxt[123].GM=string.format("Damage %s points plus 1-%s points per point of skill",math.round(dmgAddTooltip(level,123)/10*12),math.round(diceMaxTooltip(level,123)/10*12))
		end
	end
end
---------------------------
----END OF SPELL REWORK----
---------------------------

---------------------------------------------
--HEALING SCALING WITH PERSONALITY AND CRIT--
---------------------------------------------

function events.Action(t)
	--heal
	if t.Action==141 then
		local persBonus=Party[Game.CurrentPlayer]:GetPersonality()/1000
		local intBonus=Party[Game.CurrentPlayer]:GetIntellect()/1000
		local statBonus=math.max(persBonus,intBonus)
		crit=Party[Game.CurrentPlayer]:GetLuck()/2000+0.05
		local body=Party[Game.CurrentPlayer]:GetSkill(const.Skills.Body)
		local s,m=SplitSkill(body)
		local baseHeal=(5+(m+1)*s)
		local extraHeal=baseHeal*statBonus
		roll=math.random()
		local gotCrit=false
		if roll<crit then
			extraHeal=(extraHeal+baseHeal)*(1.5+statBonus)-baseHeal
			gotCrit=true
		end
		--apply heal
		local maxHP=Party[t.Param-1]:GetFullHP()
		Party[t.Param-1].HP=math.min(Party[t.Param-1].HP+extraHeal,maxHP)
		if gotCrit then
			Sleep(1)
			Game.ShowStatusText("Critical Heal")
		end
	end
	--power cure
	if t.Action==142 then
		local persBonus=Party[Game.CurrentPlayer]:GetPersonality()/1000
		local intBonus=Party[Game.CurrentPlayer]:GetIntellect()/1000
		local statBonus=math.max(persBonus,intBonus)
		crit=Party[Game.CurrentPlayer]:GetLuck()/2000+0.05
		local body=Party[Game.CurrentPlayer]:GetSkill(const.Skills.Body)
		local s,m=SplitSkill(body)
		local baseHeal=(10+s*5)
		local extraHeal=baseHeal*statBonus
		roll=math.random()
		local gotCrit=false
		if roll<crit then
			extraHeal=(extraHeal+baseHeal)*(1.5+statBonus)-baseHeal
			gotCrit=true
		end
		--apply heal
		for i=0,Party.High do
			local maxHP=Party[i]:GetFullHP()
			Party[i].HP=math.min(Party[i].HP+extraHeal,maxHP)
		end
		if gotCrit then
			Sleep(1)
			Game.ShowStatusText("Critical Heal")
		end
	end
end

--Invisibility Nerf
function events.Action(t)
	if t.Action == 142 then
		local s,m=SplitSkill(Party[Game.CurrentPlayer].Skills[const.Skills.Air])
		Sleep(1)
		local minutesPerSkill=(m-3)*3+3
		local baseDuration=(m-3)*15+15
		Party.SpellBuffs[11].ExpireTime=Game.Time+const.Minute*(baseDuration+minutesPerSkill*s)
	end
end

function events.GameInitialized2()
	Game.SpellsTxt[19].Master="Duration 15+3 minutes per point of skill"
	Game.SpellsTxt[19].GM="Duration 30+6 minutes per point of skill"
end
