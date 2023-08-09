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
	spellDamage={}
	newSpellDamageDice={}
	newSpellDamageAdd={}
	spellDesc={}
	spellDescN={}
	spellDescE={}
	spellDescM={}
	spellDescGM={}
	for i=1,99 do
	spellCostNormal[i] = Game.Spells[i]["SpellPointsNormal"]
	spellCostExpert[i] = Game.Spells[i]["SpellPointsExpert"]
	spellCostMaster[i] = Game.Spells[i]["SpellPointsMaster"]
	spellCostGM[i] = Game.Spells[i]["SpellPointsGM"]
	damageAdd[i] = Game.Spells[i].DamageAdd
	damageDiceSides[i] = Game.Spells[i].DamageDiceSides 
	end
	ascendanceCost={30,35,40,45,50,60,70,80,100,120,150}
	spells={2,6,7,8,9,10,11,15,18,20,22,24,26,29,32,37,39,41,43,44,52,58,65,70,76,78,79,84,87,90,93,97,98,99}
	lastIndex=-1
	--new damage calculation
	for i=1,#spells do
		if spells[i]%11==0 then
			newManaCost=ascendanceCost[11]
		else
			newManaCost=ascendanceCost[spells[i]%11]
		end
		newSpellDamageDice[spells[i]]=math.round(newManaCost^0.7*2)
		newSpellDamageAdd[spells[i]]=math.round(newManaCost/2)
	end
	
	--store base descriptions
	for i=1,114 do --spells go up to 114, from 115 to 132 is empty
		spellDesc=Game.SpellsTxt[i].Description
		spellDescN=Game.SpellsTxt[i].Normal
		spellDescE=Game.SpellsTxt[i].Expert
		spellDescM=Game.SpellsTxt[i].Master
		spellDescGM=Game.SpellsTxt[i].GM
	end	
end

--adjust mana cost
	
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
					Game.Spells[num].DamageDiceSides = newSpellDamageDice[num]
					if damageAdd[num]>0 then
						Game.Spells[num].DamageAdd=newSpellDamageDice[num]
					end
				else
					Game.Spells[num]["SpellPointsNormal"]=spellCostNormal[num]
					Game.Spells[num]["SpellPointsExpert"]=spellCostExpert[num]
					Game.Spells[num]["SpellPointsMaster"]=spellCostMaster[num] 
					Game.Spells[num]["SpellPointsGM"]=spellCostGM[num]
					Game.Spells[num].DamageDiceSides=damageDiceSides[num]
					Game.Spells[num].DamageAdd=damageAdd[num]		
				end	
			end
			
			
		--change tooltips according to damage
		Game.SpellsTxt[2].Description=string.format("Launches a burst of fire at a single target.  Damage is 1-%s points of damage per point of skill in Fire Magic.   Firebolt is safe, effective and has a low casting cost.",Game.Spells[2].DamageDiceSides)
		Game.SpellsTxt[6].Description=string.format("Fires a ball of fire at a single target. When it hits, the ball explodes damaging all those nearby, including your characters if they're too close.  Fireball does 1-%s points of damage per point of skill in Fire Magic.",Game.Spells[6].DamageDiceSides)
		--need to fix fire spikes, not sure how
		Game.SpellsTxt[7].Expert=string.format("Causes 1-%s points of damage per point of skill, 5 spikes maximum",Game.Spells[7].DamageDiceSides)
--		Game.SpellsTxt[i].Description
--		Game.SpellsTxt[i].Normal
--		Game.SpellsTxt[i].Expert
--		Game.SpellsTxt[i].Master
--		Game.SpellsTxt[i].GM
		----------------------------------------
		
		Game.SpellsTxt[8].Description=string.format("Surrounds your characters with a very hot fire that is only harmful to others.  The spell will deliver 1-%s points of damage per point of skill to all nearby monsters for as long as they remain in the area of effect.",Game.Spells[8].DamageDiceSides)
		Game.SpellsTxt[9].Description=string.format("Summons flaming rocks from the sky which fall in a large radius surrounding your chosen target.  Try not to be near the victim when you use this spell.  A single meteor does %s points of damage plus %s per point of skill in Fire Magic.  This spell only works outdoors.",Game.Spells[9].DamageAdd,Game.Spells[9].DamageDiceSides)
		Game.SpellsTxt[10].Description=string.format("Inferno burns all monsters in sight when cast, excluding your characters.  One or two castings can clear out a room of weak or moderately powerful creatures. Each monster takes %s points of damage plus %s per point of skill in Fire Magic.  This spell only works indoors.",Game.Spells[10].DamageAdd,Game.Spells[10].DamageDiceSides)
		Game.SpellsTxt[11].Description=string.format("Among the strongest direct damage spells available, Incinerate inflicts massive damage on a single target.  Only the strongest of monsters can expect to survive this spell.  Damage is %s points plus 1-%s per point of skill in Fire Magic.",Game.Spells[11].DamageAdd,Game.Spells[11].DamageDiceSides)
		Game.SpellsTxt[15].Description=string.format("Sparks fires small balls of lightning into the world that bounce around until they hit something or dissipate. It is hard to tell where they will go, so this spell is best used in a room crowded with small monsters. Each spark does %s points plus %s per point of skill in Air Magic.",Game.Spells[15].DamageAdd,Game.Spells[15].DamageDiceSides)
		Game.SpellsTxt[18].Description=string.format("Lightning Bolt discharges electricity from the caster's hand to a single target.  It always hits and does 1-%s points of damage per point of skill in Air Magic.",Game.Spells[18].DamageDiceSides)
		Game.SpellsTxt[20].Description=string.format("Implosion is a nasty spell that affects a single target by destroying the air around it, causing a sudden inrush from the surrounding air, a thunderclap, and %s points plus 1-%s points of damage per point of skill in Air Magic.",Game.Spells[20].DamageAdd,Game.Spells[20].DamageDiceSides)
		Game.SpellsTxt[22].Description=string.format("Calls stars from the heavens to smite and burn your enemies.  Twenty stars are called, and the damage for each star is 20 points plus 1 per point of skill in Air Magic. Try not to get caught in the blast! This spell only works outdoors.",Game.Spells[22].DamageDiceAdd,Game.Spells[22].DamageDiceSides)
		Game.SpellsTxt[24].Description=string.format("Sprays poison at monsters directly in front of your characters.  Damage is low, but few monsters have resistance to Water Magic, so it usually works.  Each shot does %s points of damage plus 1-%s per point of skill.",Game.Spells[24].DamageDiceAdd,Game.Spells[24].DamageDiceSides)
		Game.SpellsTxt[26].Description=string.format("Fires a bolt of ice at a single target.  The missile does 1-%s points of damage per point of skill in Water Magic.",Game.Spells[26].DamageDiceSides)
		Game.SpellsTxt[29].Description=string.format("Acid burst squirts a jet of extremely caustic acid at a single victim.  It always hits and does %s points of damage plus 1-%s per point of skill.",Game.Spells[29].DamageDiceAdd,Game.Spells[29].DamageDiceSides)
		Game.SpellsTxt[32].Description=string.format("Fires a ball of ice in the direction the caster is facing.  The ball will shatter when it hits something, launching 7 shards of ice in all directions except the caster's.  The shards will ricochet until they strike a creature or melt.  Each shard does %s points of damage plus 1-%s per point of skill in Water Magic.",Game.Spells[32].DamageDiceAdd,Game.Spells[32].DamageDiceSides)
		Game.SpellsTxt[37].Description=string.format("Summons a swarm of biting, stinging insects to bedevil a single target.  The swarm does %s points of damage plus 1-%s per point of skill in Earth Magic.",Game.Spells[37].DamageDiceAdd,Game.Spells[37].DamageDiceSides)
		Game.SpellsTxt[39].Description=string.format("Fires a rotating, razor-thin metal blade at a single monster.  The blade does 1-%s points of damage per point of skill in Earth Magic.",Game.Spells[39].DamageDiceSides)
		Game.SpellsTxt[41].Description=string.format("Releases a magical stone into the world that will explode when it comes into contact with a creature or enough time passes.  The rock will bounce and roll until it finds a resting spot, so be careful not to be caught in the blast.  The explosion causes %s points of damage plus 1-%s points of damage per point of skill in Earth Magic.",Game.Spells[41].DamageDiceAdd,Game.Spells[41].DamageDiceSides)
		Game.SpellsTxt[43].Description=string.format("Launches a magical stone which bursts in air, sending shards of explosive earth raining to the ground.  The damage is %s points plus %s per point of skill in Earth Magic for each shard.  This spell can only be used outdoors.",Game.Spells[43].DamageDiceAdd,Game.Spells[43].DamageDiceSides)
		Game.SpellsTxt[44].Description=string.format("Increases the weight of a single target enormously for an instant, causing internal damage equal to %s%% of the monster's hit points plus another %s%% per point of skill in Earth Magic.  The bigger they are, the harder they fall.",Game.Spells[44].DamageDiceAdd,Game.Spells[44].DamageDiceSides)
		Game.SpellsTxt[52].Description=string.format("This spell weakens the link between a target's body and soul, causing %s + 2-%s points of damage per point of skill in Spirit Magic to all monsters near the caster.",Game.Spells[52].DamageDiceAdd,Game.Spells[52].DamageDiceSides)
		Game.SpellsTxt[59].Description=string.format("Fires a bolt of mental force which damages a single target's nervous system.  Mind Blast does %s points of damage plus 1-%s per point of skill in Mind Magic.",Game.Spells[59].DamageDiceAdd,Game.Spells[59].DamageDiceSides)
		Game.SpellsTxt[65].Description=string.format("Similar to Mind Blast, Psychic Shock targets a single creature with mind damaging magic--only it has a much greater effect.  Psychic Shock does %s points of damage plus 1-%s per point of skill in Mind Magic.",Game.Spells[65].DamageDiceAdd,Game.Spells[65].DamageDiceSides)
		Game.SpellsTxt[70].Description=string.format("Directly inflicts magical damage upon a single creature.  Harm does %s points of damage plus 1-%s per point of skill in Body Magic.",Game.Spells[70].DamageDiceAdd,Game.Spells[70].DamageDiceSides)
		Game.SpellsTxt[76].Description=string.format("Flying Fist throws a heavy magical force at a single opponent that does %s points of damage plus 1-%s per point of skill in Body Magic.",Game.Spells[76].DamageDiceAdd,Game.Spells[76].DamageDiceSides)
		Game.SpellsTxt[78].Description=string.format("Fires a bolt of light at a single target that does 1-%s points of damage per point of skill in light magic.  Damage vs. Undead is doubled.",Game.Spells[78].DamageDiceSides)
		Game.SpellsTxt[79].Description=string.format("Calls upon the power of heaven to undo the evil magic that extends the lives of the undead, inflicting %s points of damage plus 1-%s per point of skill in Light Magic upon a single, unlucky target.  This spell only works on the undead.",Game.Spells[79].DamageDiceAdd,Game.Spells[79].DamageDiceSides)
		Game.SpellsTxt[84].Description=string.format("Inflicts %s points of damage plus %s per point of skill in Light Magic on all creatures in sight.  This spell can only be cast indoors.",Game.Spells[84].DamageDiceAdd,Game.Spells[84].DamageDiceSides)
		Game.SpellsTxt[87].Description=string.format("Sunray is the second most devastating damage spell in the game. It does %s points of damage plus 1-%s points per point of skill in Light Magic, by concentrating the light of the sun on one unfortunate creature. It only works outdoors during the day.",Game.Spells[87].DamageDiceAdd,Game.Spells[87].DamageDiceSides)
		Game.SpellsTxt[90].Description=string.format("A poisonous cloud of noxious gases is formed in front of the caster and moves slowly away from your characters.  The cloud does 25 points of damage plus 1-10 per point of skill in Dark Magic and lasts until something runs into it.",Game.Spells[90].DamageDiceAdd,Game.Spells[90].DamageDiceSides)
		Game.SpellsTxt[93].Description=string.format("Fires a blast of hot, jagged metal in front of the caster, striking any creature that gets in the way.  Each piece inflicts 1-%s points of damage per point of skill in Dark Magic.",Game.Spells[93].DamageDiceSides)
		Game.SpellsTxt[97].Description=string.format("Dragon Breath empowers the caster to exhale a cloud of toxic vapors that targets a single monster and damage all creatures nearby, doing 1-%s points of damage per point of skill in Dark Magic.",Game.Spells[97].DamageDiceSides)
		Game.SpellsTxt[98].Description=string.format("This spell is the town killer. Armageddon inflicts %s points of damage plus %s point of damage for every point of Dark skill your character has to every creature on the map, including all your characters. It can only be cast three times per day and only outdoors.",Game.Spells[98].DamageDiceAdd,Game.Spells[98].DamageDiceSides)
		Game.SpellsTxt[99].Description=string.format("This horrible spell sucks the life from all creatures in sight, friend or enemy.  Souldrinker then transfers that life to your party in much the same fashion as Shared Life.  Damage (and healing) is %s + 1-%s per point of skill.",Game.Spells[99].DamageDiceAdd,Game.Spells[99].DamageDiceSides)
		end
	end
end



