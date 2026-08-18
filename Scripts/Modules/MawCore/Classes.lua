-- Classes.lua -- the custom class registry: which class ids belong to each
-- Maw class, and how a class swaps its presentation (skill names, spell
-- texts, mana costs) when a character is selected.
--
-- The class id lists are published as the legacy globals the rest of the mod
-- reads (seraphClass, dkClass, ...), so this table is their one source.
-- See NOTES.md.

local Classes = {}
MawCore.Classes = Classes

------------------------------------------------------------------------
-- Death Knight data
-- spRegen and DKDamageMult are read by the damage pipeline too.
------------------------------------------------------------------------

spRegen={
	[56]=10,
	[57]=15,
	[58]=20,
}

DKDamageMult={
	[26]={1,1,1.2,1.2,["Skill"]=14},
	[29]={1.5,1.5,1.5,2,["Skill"]=14},
	[32]={0.75,0.75,0.75,0.75,["Skill"]=14},
	[76]={1.1,1.1,1.1,1.4,["Skill"]=18},
	[90]={1,1,1,1.2,["Skill"]=20},
	[97]={0.6,0.6,0.6,0.6,["Skill"]=20},
}

DKSpellList={
	[const.Skills.Water]={26, 27, 29, 32},
	[const.Skills.Body]={68, 71, 76, 74},
	[const.Skills.Dark]={91, 90, 96, 97},
}

------------------------------------------------------------------------
-- Elementalist data
-- spellRequirements is read by the damage pipeline and SkillTooltip.
------------------------------------------------------------------------

spellRequirements={0,0,500,1500,5000,10000,20000,40000,80000,160000,320000}

eleOffSpellsOut={2,6,7,9,11,
				15,18,20,22,
				24,26,29,32,
				37,39,41,43,44}

eleOffSpellsIn={2,6,7,10,11,
				15,18,20,
				24,26,29,32,
				37,39,41,44}

singleTarget={2,11,20,26,29,37,39}

shotGun={2,15,24,37}

aoeIn={6,10,18,32,41}

aoeOut={6,9,18,22,32,41,43}

------------------------------------------------------------------------
-- Assassin data
-- assassinSpellList is read by zzMaw-Spells' tooltip pass.
------------------------------------------------------------------------

local sp=const.Spells
assassinSpells={
	[sp.TorchLight]={["Cost"]=1,["StackCost"]=0,["DamageMult"]=0,},
	[sp.FireAura]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
	[sp.Haste]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
	[sp.Fireball]={["Cost"]=0,["StackCost"]=5,["DamageMult"]=1,},
	[sp.FireSpike]={["Cost"]=0,["StackCost"]=3,["DamageMult"]=2.5,},
	
	[sp.WizardEye]={["Cost"]=1,["StackCost"]=0,["DamageMult"]=0,},
	[sp.Jump]={["Cost"]=5,["StackCost"]=0,["DamageMult"]=0,},
	[sp.Shield]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
	[sp.LightningBolt]={["Cost"]=0,["StackCost"]=5,["DamageMult"]=1.5,},
	[sp.Invisibility]={["Cost"]=15,["StackCost"]=0,["DamageMult"]=0,},
	[sp.Fly]={["Cost"]=25,["StackCost"]=0,["DamageMult"]=0,},
	
	[sp.PoisonSpray]={["Cost"]=0,["StackCost"]=3,["DamageMult"]=0.75,},
	[sp.WaterWalk]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
	[sp.AcidBurst]={["Cost"]=0,["StackCost"]=3,["DamageMult"]=3,},
	[sp.TownPortal]={["Cost"]=20,["StackCost"]=0,["DamageMult"]=0,},
	[sp.LloydsBeacon]={["Cost"]=30,["StackCost"]=0,["DamageMult"]=0,},
	
	[sp.Stun]={["Cost"]=0,["StackCost"]=3,["DamageMult"]=1.5,},
	[sp.StoneSkin]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
	[sp.Blades]={["Cost"]=0,["StackCost"]=3,["DamageMult"]=3},
	[sp.Telekinesis]={["Cost"]=0,["StackCost"]=0,["DamageMult"]=0,},
	[sp.MassDistortion]={["Cost"]=0,["StackCost"]=4,["DamageMult"]=4,},
}				

assassinSpellList={
	[const.Skills.Fire]={1, 4, 5, 6, 7},
	[const.Skills.Air]={12, 17, 16, 18, 21, 19},
	[const.Skills.Water]={24, 27, 29, 31, 33},
	[const.Skills.Earth]={34, 38, 39, 42, 44},
}

------------------------------------------------------------------------
-- Presentation swaps, verbatim from zzClasses. dkSkills/assassinSkills
-- stay global: zzMaw-Spells' ascension() calls them directly.
------------------------------------------------------------------------

local DKManaCost={
	[26]=15,
	[27]=0,
	[29]=30,
	[32]=50,
	[68]=6,
	[71]=0,
	[76]=70,
	[74]=12,
	[91]=0,
	[90]=30,
	[96]=15,
	[97]=100,
}
Classes.DKManaCost = DKManaCost	--the damage pipeline charges the per-hit ones

function dkSkills(isDK, id)
	if isDK then
		local pl=Party[id]
		for key, value in pairs(DKManaCost) do
			for i=1,4 do
				Game.Spells[key]["SpellPoints" .. masteryName[i]]=value
			end
		end
		
		-- Spell 26: Icy Touch
		local mult26 = DKDamageMult[26]
		Game.SpellsTxt[26].Name="Icy Touch"
		Game.SpellsTxt[26].Description="This spell is exclusive to Death Knights and deals damage equal to " .. (mult26[1]*100) .. "% of current weapon damage."
		Game.SpellsTxt[26].Normal="Deals damage equal to " .. (mult26[1]*100) .. "% of Melee damage"
		Game.SpellsTxt[26].Expert="Monster slows by 1/2 of speed"
		Game.SpellsTxt[26].Master="Damage Increased to " .. (mult26[3]*100) .. "%"
		Game.SpellsTxt[26].GM="Monster slows by 1/4 of speed"
		
		-- Spell 29: Frostbite
		local mult29 = DKDamageMult[29]
		Game.SpellsTxt[29].Name="Frostbite"
		Game.SpellsTxt[29].Description="This is the strongest single damage spell available to death knights and deals damage equal to " .. (mult29[1]*100) .. "% of current weapon damage."
		Game.SpellsTxt[29].Expert="n/a"
		Game.SpellsTxt[29].Master="Deals damage equal to " .. (mult29[3]*100) .. "% of Melee damage"
		Game.SpellsTxt[29].GM="Deals damage equal to " .. (mult29[4]*100) .. "% of Melee damage"
		
		-- Spell 32: Ice Bomb
		local mult32 = DKDamageMult[32]
		Game.SpellsTxt[32].Name="Ice Bomb"
		Game.SpellsTxt[32].Description="Throw an ice bomb that shatters upon hitting something, most effective versus big foes or multiple enemies.\nDeals damage equal to " .. (mult32[1]*100) .. "% of current weapon damage."
		Game.SpellsTxt[32].Expert="n/a"
		Game.SpellsTxt[32].Master="n/a"
		Game.SpellsTxt[32].GM="Each hit deals damage equal to " .. (mult32[4]*100) .. "% of Melee damage"
		
		
		
		local bloodS, bloodM=SplitSkill(pl.Skills[const.Skills.Body])
		
		local FHP=pl:GetFullHP()
		local leech=MawCore.Formulas.bloodLeech
		Game.SpellsTxt[68].Name="Blood Leech"
		Game.SpellsTxt[68].Description="Activating this spell imbues the knight body with blood, leeching life upon attacking at the cost of 6 spell points."
		Game.SpellsTxt[68].Normal="Leeches " .. round(leech(FHP, bloodS, 1)) .. " Hit Points"
		Game.SpellsTxt[68].Expert="Leeches " .. round(leech(FHP, bloodS, 2)) .. " Hit Points"
		Game.SpellsTxt[68].Master="Leeches " .. round(leech(FHP, bloodS, 3)) .. " Hit Points"
		Game.SpellsTxt[68].GM="Leeches " .. round(leech(FHP, bloodS, 4)) .. " Hit Points"
		
		-- Spell 74: Superior Blood Leech
		Game.SpellsTxt[74].Name="Superior Blood Leech"
		Game.SpellsTxt[74].Description="Activating this spell imbues the knight essence with blood, leeching a superior amount of life upon attacking at the cost of 12 spell points."
		Game.SpellsTxt[74].Master="n/a"
		Game.SpellsTxt[74].GM="Leeches " .. round(leech(FHP, bloodS, 4) * 2) .. " Hit Points"
		
		-- Spell 76: Asphyxiate (no entry in DKDamageMult, but description mentions 110% and 140%)
		local mult76= DKDamageMult[76]
		Game.SpellsTxt[76].Name="Asphyxiate"
		Game.SpellsTxt[76].Description="Asphyxiate the target deal damage equal to " .. (mult76[3]*100) .. "% and making him unable to act for 4 seconds"
		Game.SpellsTxt[76].Master="No additional effects"
		Game.SpellsTxt[76].GM="Damage increased to " .. (mult76[4]*100) .. "%"
		
		-- Spell 90: Death Coil
		local mult90 = DKDamageMult[90]
		Game.SpellsTxt[90].Name="Death Coil"
		Game.SpellsTxt[90].Description="A deadly spell capable to heal the caster upon hitting the target by an amount equal to double the Life leech enchant. Deals damage equal to " .. (mult90[1]*100) .. "% of the base weapon damage"
		Game.SpellsTxt[90].Normal="N/A"
		Game.SpellsTxt[90].Expert="Deals damage equal to " .. (mult90[2]*100) .. "%"
		Game.SpellsTxt[90].Master="Leech amount increased by 50%"
		Game.SpellsTxt[90].GM="Damage increased to " .. (mult90[4]*100) .. "%"
		
		Game.SpellsTxt[96].Name="Death Grasp"
		Game.SpellsTxt[96].Description=string.format("Activating this spell imbues the knight's body with dark powers. Every melee hit costs %d spell points and leaves the target dealing %d%% less damage for %gs, refreshed on each hit.",
			DKManaCost[96],
			round((1 - MawCore.Damage.monsterDamageDebuff[const.MonsterBuff.DamageHalved])*100),
			MawCore.Damage.dkGraspDuration/const.Minute*MawCore.Formulas.gameMinuteSeconds)
		Game.SpellsTxt[96].Expert="n/a"
		Game.SpellsTxt[96].Master="No additional effects"
		Game.SpellsTxt[96].GM="Target also loses the ability to attack at range"
		
		-- Spell 97: Death Breath
		local mult97 = DKDamageMult[97]
		Game.SpellsTxt[97].Name="Death Breath"
		Game.SpellsTxt[97].Description="A lethal explosion dealing huge damage to all monsters in the area. Can be used safely also in close combat.\nDeals damage equal to " .. (mult97[1]*100) .. "% of weapon damage"
		Game.SpellsTxt[97].Expert="n/a"
		Game.SpellsTxt[97].Master="n/a"
		Game.SpellsTxt[97].GM="This spell is as good as it will ever be!"
		
		--skill names and desc
		
		Skillz.setName(14, "Frost")
		Skillz.setName(18, "Blood")
		Skillz.setName(20, "Unholy")
	else
		for key, value in pairs(spellDesc) do
			for key2, value2 in pairs(value) do
				Game.SpellsTxt[key][key2]=value2
			end
		end
		Skillz.setName(14, "Water Magic")
		Skillz.setName(18, "Body Magic")
		Skillz.setName(20, "Dark Magic")
	end
end

local function elementalistSkills(isElementalist, id)
	if isElementalist then
		local pl=Party[id]
		vars.elementalistSpells=vars.elementalistSpells or {}
		vars.elementalistSpells[pl:GetIndex()]=vars.elementalistSpells[pl:GetIndex()] or {}
		for i=12,15 do
			vars.elementalistSpells[pl:GetIndex()][i]=vars.elementalistSpells[pl:GetIndex()][i] or 0
		end
	end
	-- school progression tooltips (12-15 part 5) moved to SkillTooltip builders (SKILL_TOOLTIPS.md)
end

function assassinSkills(isAssassin, pl)
	if isAssassin then
		if pl then
			for key, value in pairs(assassinSpells) do
				local id=pl:GetIndex()
				if vars.assassinStacks[id]<assassinSpells[key].StackCost then
					for i=1,4 do
						Game.Spells[key]["SpellPoints" .. masteryName[i]]=1000
					end
				else
					for i=1,4 do
						Game.Spells[key]["SpellPoints" .. masteryName[i]]=assassinSpells[key].Cost
					end
				end
			end
		end
		--skill names and desc
		
		Skillz.setName(12, "Combat")
		Skillz.setName(13, "Subtlety")
		Skillz.setName(14, "Poisons")
		Skillz.setName(15, "Assassination")
		
		Game.SpellsTxt[6].Description=string.format("Fires a ball of fire at a single target. When it hits, the ball explodes damaging all those nearby, including your characters if they're too close.  Fireball does %s%% of a melee attack damage.",assassinSpells[6].DamageMult*100)
		Game.SpellsTxt[7].Description=string.format("Drops a Fire Spike on the ground that waits for a creature to get near it before exploding.  Fire Spikes last until you leave the map or they are triggered. Fire Spike does %s%% of a melee attack damage.",assassinSpells[7].DamageMult*100)
		Game.SpellsTxt[18].Description=string.format("Lightning Bolt discharges electricity from the caster's hand to a single target.  It always hits and does %s%% of a melee attack damage.\n\nThe spell then arcs to a second target, hitting it as well.",assassinSpells[18].DamageMult*100)
		Game.SpellsTxt[24].Description=string.format("Sprays poison at monsters directly in front of your characters.  Damage is low, but few monsters have resistance to Water Magic, so it usually works.  Each shot does %s%% of a melee attack damage.",assassinSpells[24].DamageMult*100)
		Game.SpellsTxt[29].Description=string.format("Acid burst squirts a jet of extremely caustic acid at a single victim.  It always hits and does %s%% of a melee attack damage.",assassinSpells[29].DamageMult*100)
		Game.SpellsTxt[34].Description=string.format("Slaps a monster with magical force, forcing it to recover from the stun spell before it can do anything else.  Stun also knocks monsters back a little, giving you a chance to get away while the getting is good.  The greater your skill in Earth Magic, the greater the effect of the spell. Stun does %s%% of a melee attack damage.",assassinSpells[34].DamageMult*100)
		Game.SpellsTxt[39].Description=string.format("Fires a rotating, razor-thin metal blade at a single monster.  The blade does %s%% of a melee attack damage.\n\nBlades is the only spell capable to deal Physical damage.",assassinSpells[39].DamageMult*100)
		Game.SpellsTxt[44].Description=string.format("Increases the weight of a single target enormously for an instant, causing internal damage equal to %s%% of a melee attack damage.",assassinSpells[44].DamageMult*100)
		
		Game.SpellsTxt[18].Expert="Spell hits up to 2 times"
		Game.SpellsTxt[18].Master="Spell hits up to 3 times"
		Game.SpellsTxt[18].GM="Spell hits up to 4 times"
		
		for key, value in pairs(assassinSpells) do
			if assassinSpells[key].StackCost>0 then
				Game.SpellsTxt[key].Description=Game.SpellsTxt[key].Description .. "\n\nThis Ability requires " .. assassinSpells[key].StackCost .. " Combo Points to be casted."
			end
		end
		
	else
		for key, value in pairs(spellDesc2) do
			for key2, value2 in pairs(value) do
				Game.SpellsTxt[key][key2]=value2
			end
		end
		Skillz.setName(12, "Fire Magic")
		Skillz.setName(13, "Air Magic")
		Skillz.setName(14, "Water Magic")
		Skillz.setName(15, "Earth Magic")
	end
end

------------------------------------------------------------------------
-- Per-class runtime. Globals: the damage pipeline calls
-- assassinationDamage, zzMaw-Stats calls GetAssassinSpellDelay, and
-- zzClasses' own handlers + scheduler registrations call the rest.
------------------------------------------------------------------------

function elementalistStacksDecay()
	for i=0,Party.High do
		local pl=Party[i]
		if table.find(elementalistClass, pl.Class) then
			local id=pl:GetIndex()
			vars.eleStacks=vars.eleStacks or {}
			vars.eleStacks[id]=vars.eleStacks[id] or 0
			vars.eleTimer=vars.eleTimer or {}
			vars.eleTimer[id]=vars.eleTimer[id] or Game.Time
			if Game.Time>vars.eleTimer[id] then
				vars.eleTimer[id]=Game.Time+const.Minute/2
				vars.eleStacks[id]=math.max(math.floor(vars.eleStacks[id]*0.5),0)
			end
		end	
	end
end

function elementalistRandomizer(pl, spellType)
	local possibleSpells={}
	if spellType=="single" then
		for i=1,#singleTarget do
			if pl.Spells[singleTarget[i]] then
				table.insert(possibleSpells, singleTarget[i])
			end
		end
	elseif spellType=="shotgun" then
		for i=1,#shotGun do
			if pl.Spells[shotGun[i]] then
				table.insert(possibleSpells, shotGun[i])
			end
		end
	elseif spellType=="aoe" and Map.IsIndoor() then
		for i=1,#aoeIn do
			if pl.Spells[aoeIn[i]] then
				table.insert(possibleSpells, aoeIn[i])
			end
		end
	elseif spellType=="aoe" then
		for i=1,#aoeOut do
			if pl.Spells[aoeOut[i]] then
				table.insert(possibleSpells, aoeOut[i])
			end
		end
	end
	if #possibleSpells>=1 then
		return possibleSpells[math.random(1,#possibleSpells)]
	else
		return false
	end
end

function mawTick_ElementalistStacks()
	for i=0,Party.High do
		local pl=Party[i]
		if table.find(elementalistClass,pl.Class) then
			local id=pl:GetIndex()
			vars.eleStacks=vars.eleStacks or {}
			vars.eleStacks[id]=vars.eleStacks[id] or 0
			elementalistStacks[i].Text=string.format(vars.eleStacks[id])
		else
			elementalistStacks[i].Text=""
		end
	end
end

function assassinationDamage(pl,mon,obj)
	local id=pl:GetIndex()
	vars.assassinDamage=vars.assassinDamage or {}
	vars.assassinDamage[id]=vars.assassinDamage[id] or 0
	vars.assassinStacks=vars.assassinStacks or {}
	vars.assassinStacks[id]=vars.assassinStacks[id] or 0
	
	local s,m=SplitSkill(pl:GetSkill(const.Skills.Fire))
	local restoreChance=0.1+s*0.01
	local manaCost=50-m*5
	
	if obj and obj.Spell>0 and obj.Spell<100 then
		restoreChance=0
		manaCost=0
	end
	
	if obj then
		restoreChance=restoreChance/2
		manaCost=manaCost/2
	end
	if restoreChance>math.random() then
		pl.SP=math.min(pl:GetFullSP(),pl.SP+15)
	end
	RunNextTick(function()
		if mon.HP<=0 then
			s,m=SplitSkill(pl:GetSkill(const.Skills.Air))
			local fullSP=pl:GetFullSP()
			pl.SP=math.min(fullSP, pl.SP+(1+m)*5)
			vars.assassinStacks[id]=math.min(vars.assassinStacks[id]+1,5)
		end
	end)
	if pl.SP>=manaCost and mon.ShowAsHostile then
		if obj and obj.Spell>100 then
			vars.assassinStacks[id]=math.min(vars.assassinStacks[id]+0.5,5)--arrow nerf
			vars.AttackSpeedStack=vars.AttackSpeedStack or {}
			vars.AttackSpeedStack[id]=vars.AttackSpeedStack[id] or 0
			vars.AttackSpeedStack[id]=math.min(vars.AttackSpeedStack[id] + 0.5, 5)
			vars.AttackSpeedStackDecay=vars.AttackSpeedStackDecay or {}
			vars.AttackSpeedStackDecay[id]=vars.AttackSpeedStackDecay[id] or {}
			vars.AttackSpeedStackDecay[id]=Game.Time+const.Minute*4
		elseif not obj then
			vars.assassinStacks[id]=math.min(vars.assassinStacks[id]+1,5)
			vars.AttackSpeedStack=vars.AttackSpeedStack or {}
			vars.AttackSpeedStack[id]=vars.AttackSpeedStack[id] or 0
			vars.AttackSpeedStack[id]=math.min(vars.AttackSpeedStack[id] + 1, 5)
			vars.AttackSpeedStackDecay=vars.AttackSpeedStackDecay or {}
			vars.AttackSpeedStackDecay[id]=vars.AttackSpeedStackDecay[id] or {}
			vars.AttackSpeedStackDecay[id]=Game.Time+const.Minute*4
		end
		local damage=vars.assassinDamage[id]
		local monsters=0
		for i=0,Map.Monsters.High do
			local mapMon=Map.Monsters[i]
			if mapMon.AIState~=11 and mapMon.AIState~=5 and getDistances(mon,mapMon)<384 then
				monsters=monsters+1
			end
		end
		local damageMult=math.min(0.8,(monsters-1)*0.2)
		if obj then
			damage=damage/2
		end
		pl.SP=pl.SP-manaCost
		
		damage=damage*damageMult
		return damage
	end
	return vars.assassinDamage[id]	
end

function mawTick_AssassinStacks()
	for i=0,Party.High do
		local pl=Party[i]
		if table.find(assassinClass,pl.Class) then
			local id=pl:GetIndex()
			vars.assassinStacks=vars.assassinStacks or {}
			vars.assassinStacks[id]=vars.assassinStacks[id] or 0
			assassinStacks[i].Text=string.format(math.floor(vars.assassinStacks[id]))
		else
			assassinStacks[i].Text=""
		end
	end
end

function GetAssassinSpellDelay(pl,spell)
	return pl:GetAttackDelay()*2
end

------------------------------------------------------------------------
-- Per-class UI/spell handlers. Bodies verbatim; the events.X
-- registrations STAY in zzClasses as one-line stubs so the handler
-- order within each event chain is untouched (NOTES.md).
------------------------------------------------------------------------

function Classes.dkSpellbook(t)
	if t.Action==105 and Game.CurrentPlayer>=0 and Game.CurrentPlayer<=Party.High then
		
		pl=Party[Game.CurrentPlayer]
		if table.find(dkClass, pl.Class) then
			for i=1,99 do
				pl.Spells[i]=false
			end
			local s1, m1=SplitSkill(pl.Skills[const.Skills.Water])
			local s2, m2=SplitSkill(pl.Skills[const.Skills.Body])
			local s3, m3=SplitSkill(pl.Skills[const.Skills.Dark])
			for i=1, m1 do
				pl.Spells[DKSpellList[const.Skills.Water][i]]=true
			end
			for i=1, m2 do
				pl.Spells[DKSpellList[const.Skills.Body][i]]=true
			end
			for i=1, m3 do
				pl.Spells[DKSpellList[const.Skills.Dark][i]]=true
			end
		end
	end
end

function Classes.dkLearnSpell(t)
	if table.find(dkClass, t.Player.Class) then
		t.NeedMastery = 5
	end
end

function Classes.eleLearnSpell(t)
	if table.find(elementalistClass, t.Player.Class) then
		t.NeedMastery = 5
		Game.ShowStatusText("Elementalists learn their spells through practice")
	end
end

function Classes.eleSpellbook(t)
	if t.Action==105 then
		if Game.CurrentPlayer>=0 and Game.CurrentPlayer<=Party.High then
			local pl=Party[Game.CurrentPlayer]
			if table.find(elementalistClass, pl.Class) then
				pl.Spells[2]=true
				pl.Spells[15]=true
				pl.Spells[24]=true
				pl.Spells[37]=true
			end
		end
	end
end

function Classes.eleCastRotation(t)
	if vars.disableRotation and vars.disableRotation[t.PlayerIndex] then
		return
	end
	if table.find(elementalistClass, t.Player.Class) and (table.find(eleOffSpellsOut, t.SpellId) or table.find(eleOffSpellsIn, t.SpellId)) and vars.elementalistSpellBinds then
		local pl=t.Player
		local index=t.PlayerIndex
		local spell=t.SpellId
		for i=1,6 do
			if i<=4 and ExtraQuickSpells.SpellSlots then
				if ExtraQuickSpells.SpellSlots[index][i]==spell then
					ExtraQuickSpells.SpellSlots[index][i]=elementalistRandomizer(pl, vars.elementalistSpellBinds[index][i])
				end
			elseif i==5 then
				if pl.AttackSpell==spell then
					pl.AttackSpell=elementalistRandomizer(pl, vars.elementalistSpellBinds[index][i])
				end
			elseif i==6 then
				if pl.QuickSpell==spell then
					pl.QuickSpell=elementalistRandomizer(pl, vars.elementalistSpellBinds[index][i])
				end
			end
		end
		vars.eleTimer=vars.eleTimer or {}
		vars.eleTimer[index]=Game.Time+math.max(getSpellDelay(pl,spell)*4, 128)
		vars.eleStacks=vars.eleStacks or {}
		vars.eleStacks[index]=vars.eleStacks[index] or 0
		vars.eleStacks[index]=vars.eleStacks[index]+1
		vars.eleTimer=vars.eleTimer or {}
	end
end

function Classes.eleBindQuick(t)
	if t.Action==142 then
		local id=Game.CurrentPlayer
		if id>=0 and id<=Party.High then
			if table.find(elementalistClass,Party[id].Class) then
				if table.find(eleOffSpellsOut,t.Param) or table.find(eleOffSpellsIn,t.Param) then
					vars.eleStacks=vars.eleStacks or {}
					vars.eleStacks[Party[id]:GetIndex()]=0
				end
			end
		end
	end
end

function Classes.eleBindScreen(t)
	if Game.CurrentScreen==8 and t.Action==113 then
		local id=Game.CurrentPlayer
		if id>=0 and id<=Party.High then
			local pl=Party[id]
			local index=pl:GetIndex()
			if table.find(elementalistClass,pl.Class) then
				for i=1,6 do
					local spell=0
					if i<=4 and ExtraQuickSpells.SpellSlots then
						spell=ExtraQuickSpells.SpellSlots[index][i]
					elseif i==5 then
						spell=pl.AttackSpell
					elseif i==6 then
						spell=pl.QuickSpell
					end
					
					vars.elementalistSpellBinds=vars.elementalistSpellBinds or {}
					vars.elementalistSpellBinds[index]=vars.elementalistSpellBinds[index] or {}
					if table.find(singleTarget,spell) then
						vars.elementalistSpellBinds[index][i]="single"
					elseif table.find(shotGun,spell) then
						vars.elementalistSpellBinds[index][i]="shotgun"
					elseif table.find(aoeIn,spell) or table.find(aoeOut,spell) then
						vars.elementalistSpellBinds[index][i]="aoe"
					else
						vars.elementalistSpellBinds[index][i]=false					
					end
				end
			end
		end
	end
end

function Classes.assassinLearnSpell(t)
	if table.find(assassinClass, t.Player.Class) then
		t.NeedMastery = 5
	end
end

function Classes.assassinSpellbook(t)
	if t.Action==105 and Game.CurrentPlayer>=0 and Game.CurrentPlayer<=Party.High then
		
		pl=Party[Game.CurrentPlayer]
		if table.find(assassinClass, pl.Class) then
			for i=1,99 do
				pl.Spells[i]=false
			end
			local s1, m1=SplitSkill(pl.Skills[const.Skills.Fire])
			local s2, m2=SplitSkill(pl.Skills[const.Skills.Air])
			local s3, m3=SplitSkill(pl.Skills[const.Skills.Water])
			local s4, m4=SplitSkill(pl.Skills[const.Skills.Earth])
			m1=m1+1
			m2=m2+2
			m3=m3+1
			m4=m4+1
			for i=1, m1 do
				pl.Spells[assassinSpellList[const.Skills.Fire][i]]=true
			end
			for i=1, m2 do
				pl.Spells[assassinSpellList[const.Skills.Air][i]]=true
			end
			for i=1, m3 do
				pl.Spells[assassinSpellList[const.Skills.Water][i]]=true
			end
			for i=1, m4 do
				pl.Spells[assassinSpellList[const.Skills.Earth][i]]=true
			end
		end
	end
end

function Classes.assassinCastStacks(t)
	local pl=t.Player
	if table.find(assassinClass,pl.Class) then
		if assassinSpells[t.SpellId] and assassinSpells[t.SpellId].StackCost>0 then 
			local id=pl:GetIndex()
			if vars.assassinStacks[id]<assassinSpells[t.SpellId].StackCost then
				t.Handled=true
				DoGameAction(23,0,0)
			else
				vars.assassinStacks[id]=vars.assassinStacks[id]-assassinSpells[t.SpellId].StackCost
			end
		end
	end
end

-- Registration order is the reset order in present() -- same order the
-- legacy checkSkills used. `present` is nil for classes whose presentation
-- is handled elsewhere (seraph/shaman tooltips are builders now; dragons
-- swap from their own Tick because they are a RACE, not a class group).
Classes.List = {
	{name = "seraph",       global = "seraphClass",       ids = {53, 54, 55}},
	{name = "shaman",       global = "shamanClass",       ids = {59, 60, 61}},
	{name = "dk",           global = "dkClass",           ids = {56, 57, 58},
		present = function(on, id) dkSkills(on, id) end},
	{name = "elementalist", global = "elementalistClass", ids = {62, 63, 64},
		present = function(on, id) elementalistSkills(on, id) end},
	{name = "assassin",     global = "assassinClass",
		ids = {const.Class.Thief, const.Class.Rogue, const.Class.Assassin, const.Class.Spy},
		present = function(on, id) assassinSkills(on, on and Party[id] or nil) end},
}

local byName = {}
for _, c in ipairs(Classes.List) do
	byName[c.name] = c
	_G[c.global] = c.ids		-- the 60+ legacy table.find(xxxClass, ...) readers
end

-- MawCore.Classes.is(pl, "dk")
function Classes.is(pl, name)
	local c = byName[name]
	return c ~= nil and table.find(c.ids, pl.Class) ~= nil
end

-- the registered class a player belongs to, or nil
function Classes.of(pl)
	for _, c in ipairs(Classes.List) do
		if table.find(c.ids, pl.Class) then
			return c
		end
	end
end

-- Reset every class presentation, then apply the one this character needs.
-- The legacy contract, kept: reset all -> adjustSpellTooltips -> apply one.
function Classes.present(id)
	for _, c in ipairs(Classes.List) do
		if c.present then
			c.present(false, id)
		end
	end
	adjustSpellTooltips()
	if id >= 0 and id <= Party.High then
		local c = Classes.of(Party[id])
		if c and c.present then
			c.present(true, id)
		end
	end
end

function Classes.describe()
	local out = {"classes:"}
	for _, c in ipairs(Classes.List) do
		out[#out + 1] = ("  %-13s %-18s ids %s%s"):format(
			c.name, c.global, table.concat(c.ids, ","),
			c.present and "" or "   (no presentation swap)")
	end
	return table.concat(out, "\n")
end


------------------------------------------------------------------------
-- Dragon data and formulas. These moved here with the dragon handlers in
-- Classes.start(): they were file-scope LOCALS of zzClasses, so the handlers
-- lost the binding when they moved and every dragon row read nil. The three
-- tables are published on Classes because zzClasses' skill-description
-- builder still prints them.
------------------------------------------------------------------------

local dragonFang={
	["Attack"]={2,3,4,5,[0]=0},
	["Damage"]={4,6,8,10,[0]=0},
}
local dragonBreath={
	["Damage"]={3,4,5,6,[0]=0},
}
local dragonScales={
	["AC"]={2,3,3,4,[0]=0},
	["Resistances"]={1,1,2,3,[0]=0},
}
Classes.dragonFang, Classes.dragonBreath, Classes.dragonScales = dragonFang, dragonBreath, dragonScales

--shared dragon formulas (min/max rows differ only by the spread mult)
local dragonRecoveryPerSkill=0.015
local function dragonEffLevel(pl)
	local bolster=getPartyLevel(4)+1
	local lvl=pl.LevelBase
	if pl.LevelBase/bolster>1.2 then
		lvl=math.min(pl.LevelBase/2,bolster)
	end
	local cap=600
	if vars.madnessMode then
		cap=900
	end
	return math.min(lvl,cap)
end
local function dragonFangDamage(pl, mult)
	local s, m = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
	local might=pl:GetMight()
	local mightEffect=Game.GetStatisticEffect(might)
	local bonus= (1 + (dragonFang.Damage[m]) * s / 100)  * (dragonEffLevel(pl) * 2 +30)
	return round((bonus*(1+might/1000)+(mightEffect*might/1000))*mult*(1+s*dragonRecoveryPerSkill))
end
local function dragonBreathDamage(pl, mult)
	local s, m = SplitSkill(pl:GetSkill(const.Skills.DragonAbility))
	local might=pl:GetMight()
	local mightEffect=Game.GetStatisticEffect(might)
	local baseDamage=(1 + dragonBreath.Damage[m] * s / 100) * (20 + 2 * dragonEffLevel(pl)) + mightEffect
	return round(baseDamage*(1+might/1000)*mult*(1+s*dragonRecoveryPerSkill))
end

function Classes.start()
	--the dragon/DK engine-event handlers. Legacy nested these in
	--zzClasses' GameInitialized2 to register them after all the
	--file-scope handlers; registering from here keeps that intent
	--and lands them later still. Order among them preserved; all
	--tier-3 peers are disjoint by class/race gates (NOTES.md).
	function events.GameInitialized2()
	function events.CalcStatBonusByItems(t)
		if Game.CharacterPortraits[t.Player.Face].Race~=const.Race.Dragon then return end
		--melee
		if t.Stat==27 then --min damage
			t.Result=dragonFangDamage(t.Player, 0.75)
		elseif t.Stat==28 then --max damage
			t.Result=dragonFangDamage(t.Player, 1.25)
		elseif t.Stat==25 then --attack
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Unarmed))
			local bonus= (dragonFang.Attack[m]) * s +10
			t.Result=t.Result+bonus 
			
		end
		--breath
		if t.Stat==31 then --min damage
			t.Result=dragonBreathDamage(t.Player, 0.75)
		elseif t.Stat==32 then --max damage
			t.Result=dragonBreathDamage(t.Player, 1.25)

		--AC
		elseif t.Stat==9 then
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Dodging))
			local oldDodge=skillAC[const.Skills.Dodging][m] or 0
			local bonus= (1 + dragonScales.AC[m]/100 * s) * (dragonEffLevel(pl)+40) - (s * oldDodge)
			t.Result=t.Result+bonus
		elseif t.Stat>=10 and t.Stat<=15 then
			local pl=t.Player
			local s, m = SplitSkill(pl:GetSkill(const.Skills.Dodging))
			local bonus= (dragonScales.Resistances[m]/100 * s) * (dragonEffLevel(pl)+40)
			t.Result=t.Result+bonus
		end
		
		--no mana from items
		if t.Stat==const.Stats.SpellPoints then
			t.Result=0
		end
	end

	function events.GetAttackDelay(t)
		if Game.CharacterPortraits[t.Player.Face].Race==const.Race.Dragon then
			if useBreathCooldown or t.Ranged then
				local s, m = SplitSkill(t.Player:GetSkill(const.Skills.DragonAbility))
				t.Result=t.Result * (1+dragonRecoveryPerSkill*s)
				useBreathCooldown=false
			else
				local s, m = SplitSkill(t.Player:GetSkill(const.Skills.Unarmed))
				t.Result=t.Result * (1+dragonRecoveryPerSkill*s)
			end
		end	
	end

	function events.PlaySound(t)
		if t.Sound==18080 then
			useBreathCooldown=true
		end
	end

	function events.CalcStatBonusByItems(t)
		--[[damage from skills 
		if t.Stat==const.Stats.MeleeDamageMax or t.Stat==const.Stats.MeleeDamageMin then
			if table.find(dkClass, t.Player.Class) then	
				local s1, m1=SplitSkill(t.Player.Skills[const.Skills.Water])
				--local s2, m2=SplitSkill(t.Player.Skills[const.Skills.Body])
				local s3, m3=SplitSkill(t.Player.Skills[const.Skills.Dark])
				local might=t.Player:GetMight()
				local bonus=s1*math.min(m1, 3)+s3*math.min(m3, 3)
				bonus=bonus*(1+might/1000)
				t.Result=t.Result+s1*math.min(m1, 3)+s3*math.min(m3, 3)
			end
		end
		MOVED IN MAW ITEMS, DUE TO WEAPON SCALING]]
			
		if t.Stat==const.Stats.SpellPoints and table.find(dkClass, t.Player.Class) then
			t.Result=0
		end
	end	

	function events.Action(t)
		if (t.Action==142 and t.Param==68) or (t.Action==142 and t.Param==74) or (t.Action==142 and t.Param==96) then
			if table.find(dkClass, Party[Game.CurrentPlayer].Class) then
				t.Handled=true
				vars.dkActiveAttackSpell=vars.dkActiveAttackSpell or {}
				local id=Party[Game.CurrentPlayer]:GetIndex()
				if vars.dkActiveAttackSpell[id]==t.Param then
					vars.dkActiveAttackSpell[id]=false
					Game.ShowStatusText(Game.SpellsTxt[t.Param].Name .. " on attack disabled")
				else
					Game.ShowStatusText(Game.SpellsTxt[t.Param].Name .. " on attack activated")
					vars.dkActiveAttackSpell[id]=t.Param
				end
			end
		end
		--same for quickcast
		if t.Action==25 and Game.CurrentPlayer>=0 and Game.CurrentPlayer<=Party.High and table.find(dkClass, Party[Game.CurrentPlayer].Class) then
			local pl=Party[Game.CurrentPlayer]
			local id=pl:GetIndex()
			if pl.QuickSpell==68 or pl.QuickSpell==74 or pl.QuickSpell==96 then
				t.Handled=true
				vars.dkActiveAttackSpell=vars.dkActiveAttackSpell or {}
				local id=Party[Game.CurrentPlayer]:GetIndex()
				if vars.dkActiveAttackSpell[id]==t.Param then
					vars.dkActiveAttackSpell[id]=false
					Game.ShowStatusText(Game.SpellsTxt[pl.QuickSpell].Name .. " on attack disabled")
				else
					Game.ShowStatusText(Game.SpellsTxt[pl.QuickSpell].Name .. " on attack activated")
					vars.dkActiveAttackSpell[id]=t.Param
				end
			end
		end
	end

	function events.PlayerCastSpell(t)
		if table.find(dkClass, t.Player.Class) then
			local spell=t.SpellId
			local m=t.Mastery
			Game.Spells[spell]["Delay" .. masteryName[m]]=t.Player:GetAttackDelay()
			if t.SpellId==68 or t.SpellId==74 then
				t.Handled=true
			end
		end
	end
	end
end