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


--MANA COST CHANGE 
--spell cost increase dictionary
function events.GameInitialized2()
	spellCostNormal={}
	spellCostExpert={}
	spellCostMaster={}
	spellCostGM={}
	damageAdd={}
	damageDiceSides={}
	for i=1,99 do
	spellCostNormal[i] = Game.Spells[i]["SpellPointsNormal"]
	spellCostExpert[i] = Game.Spells[i]["SpellPointsExpert"]
	spellCostMaster[i] = Game.Spells[i]["SpellPointsMaster"]
	spellCostGM[i] = Game.Spells[i]["SpellPointsGM"]
	damageAdd[i] = Game.Spells[i].DamageAdd
	damageDiceSides[i] = Game.Spells[i].DamageDiceSides 
	end
end

--adjust mana cost
--with race spells it gets up to 132
--cost table
ascendanceCost={30,35,40,45,50,60,70,80,100,120,150}
--list of spell to chance
spells={2,6,7,8,9,10,11,15,18,20,22,24,26,29,32,37,39,41,43,44,52,58,65,70,76,78,79,84,87,90,93,97,98,99}
lastIndex=-1
function events.Tick()
	index=Game.CurrentPlayer
	if index>=0 then
		level=Party[index].LevelBase
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
				check2=(num2+9)*10
				if level>=check2 then
					Game.Spells[num]["SpellPointsNormal"] = ascendanceCost[num2]
					Game.Spells[num]["SpellPointsExpert"] = ascendanceCost[num2]
					Game.Spells[num]["SpellPointsMaster"] = ascendanceCost[num2]
					Game.Spells[num]["SpellPointsGM"] = ascendanceCost[num2]
					Game.Spells[num].DamageDiceSides = math.round(ascendanceCost[num2]^0.7*2)
					if damageAdd[num]>0 then
						Game.Spells[num].damageAdd=math.round(ascendanceCost[num2]/2)
					end						
				else
					Game.Spells[num]["SpellPointsNormal"]=spellCostNormal[num]
					Game.Spells[num]["SpellPointsExpert"]=spellCostExpert[num]
					Game.Spells[num]["SpellPointsMaster"]=spellCostMaster[num] 
					Game.Spells[num]["SpellPointsGM"]=spellCostGM[num]
					Game.Spells[num].DamageDiceSides=damageDiceSides[num]
					Game.Spells[num].damageAdd=damageAdd[num]
				end	
			end
		end
	end
end
