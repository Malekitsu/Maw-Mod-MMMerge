-- Damage.lua -- both damage pipelines: CalcDamageToMonster (30 stages) and
-- CalcDamageToPlayer (8). Stages are the former legacy handlers, close to
-- verbatim, in legacy registration order; zzzzzMaw_Damage.lua registers the
-- two event handlers per playthrough.
--
-- Inventories, deliberate order changes, open items: DAMAGE_PIPELINE.md.
-- Variable scoping and cross-stage state: NOTES.md.

local Damage = {}
MawCore.Damage = Damage

local Formulas = MawCore.Formulas
local DamageState = MawCore.DamageState

local REMOTE_OWNER_BIT = 0x800

-- Reflect bookkeeping. These three are read and written only inside this
-- file: a stage sets one, a later stage in the same hit consumes it.
local reflecting = false
local painReflectionHit = false
local reflectedDamage = false

-- ===========================================================================
-- Shared helpers -- one source for ideas duplicated across stages.
-- ===========================================================================

-- the mod's standard weapon damage roll: average of two dice
local function rollDice(lo, hi)
	return round((math.random(lo, hi) + math.random(lo, hi))/2)
end

-- the standard resistance mitigation: halved per 100 effective res.
-- Resistance is taken mod 1000 on purpose: some effects park marker values
-- in the thousands (e.g. the stun spell writes 65000, relying on %1000 -> 0).
local function resDivide(damage, res)
	return damage / 2^((res % 1000)/100)
end

-- legendary perks are stored per player index in vars.legendaries
local function hasLegendary(id, n)
	return vars.legendaries and vars.legendaries[id] ~= nil
		and table.find(vars.legendaries[id], n)
end

-- map affix n, when present, cuts a value by its power%
local function affixCut(value, n)
	local p = getMapAffixPower(n)
	if p then
		return value*(1-p/100)
	end
	return value
end

-- per-player stat tracking, mirrored in vars (save-wide) and mapvars (per map)
local function track(name, id, amount)
	vars[name] = vars[name] or {}
	vars[name][id] = (vars[name][id] or 0) + amount
	mapvars[name] = mapvars[name] or {}
	mapvars[name][id] = (mapvars[name][id] or 0) + amount
end

-- total HP of the party members that are alive
local function partyHPSum()
	local sum = 0
	for i = 0, Party.High do
		if Party[i].Dead == 0 and Party[i].Eradicated == 0 then
			sum = sum + Party[i].HP
		end
	end
	return sum
end

-- party slot (0..Party.High) for a player index, or nil if not in the party
local function slotByIndex(id)
	for i = 0, Party.High do
		if Party[i]:GetIndex() == id then
			return i
		end
	end
end

-- context -- the first stage: resolve the attack context once per hit.
-- WhoHitMonster() is stable for the whole event, so every stage reads t.Hit
-- instead of calling it again (the bodies' `data` locals alias t.Hit).
local function stage_context(t)
	t.Hit = WhoHitMonster()
end

-- ===========================================================================
-- Stage bodies, near-verbatim from the legacy files (source noted per stage).
-- ===========================================================================

-- --- Tier 1: was General file-scope (loaded alphabetically) ----------------

-- from Scripts/General/zzClasses.lua:255 -- Seraph melee on-hit heal to the
-- lowest party member (online-aware), healing-done tracking
local function stage_seraphOnHitHeal(t)
	if t.Result==0 then return end
	local data = t.Hit
		if data and data.Player and (data.Player.Class==55 or data.Player.Class==54 or data.Player.Class==53) and t.DamageKind==4 and data.Object==nil then
		local pl=data.Player
		local partyHP=partyHPSum()

		--get body
		local bodyS,bodyM=SplitSkill(pl.Skills[const.Skills.Body])

		--Calculate heal value and apply
		local healValue=(bodyS^1.3*bodyM*2)*damageMultiplier[t.PlayerIndex]["Melee"]
		local personality=pl:GetPersonality()
		healValue=round(healValue*(1+personality/1000))

		local healTarget, lowestHealthPercentage=pickLowestPartyMember()
		
		local percent, partyId, playerId=OnlineLowestHealthPercentage()
		
		if lowestHealthPercentage>0.25 and percent<lowestHealthPercentage then
			SendHeal(partyId, playerId, healValue, pl.Name)
			
			local hp=vars.online.partyHealthMana.Parties[partyId][playerId].HP
			local fhp=vars.online.partyHealthMana.Parties[partyId][playerId].FHP
			
			local healing=math.min(healValue, fhp-hp)
			
			track("healingDone", t.PlayerIndex, healing)
			return
		end
		
		--apply heal
		evt[healTarget].Add("HP",healValue)		
		--bug fix
		if Party[healTarget].HP>0 then
			Party[healTarget].Unconscious=0
		end
		local partyHP2=partyHPSum()
		if partyHP2>partyHP and (Party.EnemyDetectorRed or Party.EnemyDetectorYellow) then
			track("healingDone", t.PlayerIndex, partyHP2-partyHP)
		end
	end
end

-- from Scripts/General/zzClasses.lua:1534 -- Elementalist learn-by-casting
-- progression (spellRequirements stays in zzClasses -- its tooltip code
-- reads it too)
local masteryRequired={1,1,1,1,2,2,2,3,3,3,4}
local function stage_elementalistLearning(t)
	if t.Monster.Hostile==false and t.Monster.ShowAsHostile==false then
		return
	end
	local data=t.Hit
	if data and data.Player and data.Object and table.find(elementalistClass, data.Player.Class) and data.Object.Spell<45 and data.Object.Spell>0 then
		local pl=data.Player
		local spell=data.Object.Spell
		local school=math.ceil(spell/11)+11
		vars.elementalistSpells=vars.elementalistSpells or {}
		vars.elementalistSpells[pl:GetIndex()]=vars.elementalistSpells[pl:GetIndex()] or {}
		vars.elementalistSpells[pl:GetIndex()][school]=vars.elementalistSpells[pl:GetIndex()][school] or 0
		
		local tier=spell%11==0 and 11 or spell%11
		local learningBonus=tier^1.5 * t.Monster.Level^0.5
		if not vars.insanityMode then
			learningBonus = learningBonus * Party.Count^0.5
		end
		if table.find(aoespells,spell) and spell~=15 and spell~=24 then
			learningBonus=learningBonus/3
		end
		vars.elementalistSpells[pl:GetIndex()][school]=vars.elementalistSpells[pl:GetIndex()][school] + learningBonus
		local school2=(school-12)*11
		for i=1,11 do
			local spell2= school2+i
			if pl.Spells[spell2]==false then
				local tier=spell2%11==0 and 11 or spell2%11
				local s,m=SplitSkill(pl:GetSkill(school))
				if vars.elementalistSpells[pl:GetIndex()][school]>=spellRequirements[tier] and m>=masteryRequired[tier] then
					if vars.insanityMode and spell2==19 and m<4 then
						pl.Spells[spell2]=false
					else
						pl.Spells[spell2]=true
						Message("Learned " .. Game.SpellsTxt[spell2].Name)
					end
				end
			end
		end		
	end
end

-- from Scripts/General/zzClasses.lua:1649 -- Elementalist: melee/arrow hits
-- reset concentration stacks
local function stage_elementalistStackReset(t)
	local data=t.Hit
	if data and data.Player and (not data.Object or data.Object.Spell==133) then
		local pl=data.Player
		if table.find(elementalistClass, pl.Class) then
			local id=pl:GetIndex()
			vars.eleStacks=vars.eleStacks or {}
			vars.eleStacks[id]=0
		end
	end
end

-- from Scripts/General/zzMaw-Monsters.lua:2236 -- discard the engine's whole
-- calculation ("disable base monster Resistances"): the raw input damage is
-- the pipeline's real starting value
local function stage_engineReset(t)
	t.Result=t.Damage
end

-- from Scripts/General/zzMaw-Monsters.lua:4475 -- Mode 2 indoor: reveal
-- monsters within 256 of the target
local function stage_revealNearby(t)
	if Map.IsIndoor() and vars.Mode==2 then
		for i=0, Map.Monsters.High do
			local mon = Map.Monsters[i]
			if getDistances(t.Monster, mon)<256 then
				mon.ShowOnMap = true
			end
		end
	end
end

-- from Scripts/General/zzMaw-Monsters.lua:4548 -- monster-vs-monster damage:
-- attacker's damage/3, divided by phys res
local function stage_monsterVsMonster(t)
	local data=t.Hit
	if data and data.Monster then
		local mon=data.Monster
		local damage=getMonsterDamage(mon)/3 --1/3 of damage
		local damage=round(resDivide(damage, t.Monster.Resistances[4]))
		t.Result=damage
	end
end

-- from Scripts/General/zzMAW-Skills.lua:2248 -- Cover GM flag (read by the
-- cover redirect logic in zzMAW-Skills/zzMaw-Monsters; init stays there)
local function stage_coverFlag(t)
	local data = t.Hit	
	if data and data.Player and t.DamageKind==4 then
		if data.Object==nil then
			local s, m=SplitSkill(Skillz.get(data.Player,50))
			if m>=4 then
				local slot=slotByIndex(t.PlayerIndex)
				if slot then
					DamageState.setCoverBonus(slot)
				end
			end
		end
	end
end

--Death Knight active Dark Grasp (spell 96): how long the debuff it leaves
--lasts, refreshed on every hit. Classes.lua prints it.
local DK_GRASP_DURATION = const.Minute
Damage.dkGraspDuration = DK_GRASP_DURATION
local darkGraspCC = {Debuff = const.MonsterBuff.DamageHalved}

local weaponStun = {
	[const.Skills.Mace]  = {mastery = 3, chanceMult = 0.15, duration = const.Minute*2},
	[const.Skills.Staff] = {mastery = 3, chanceMult = 0.10, duration = const.Minute*2},
}
Damage.weaponStun = weaponStun	--zzMAW-Skills prints these in the skill tooltips
local stunCC = {Debuff = const.MonsterBuff.Paralyze}
local function stage_weaponStun(t)
	if not t.Player then return end
	local data=t.Hit
	if t.DamageKind~=4 or not data or data.Object~=nil then return end
	local it=t.Player:GetActiveItem(1)
	if not it then return end
	local skill=it:T().Skill
	local cfg=weaponStun[skill]
	if not cfg then return end
	local s,m=SplitSkill(t.Player:GetSkill(skill))
	if m<cfg.mastery then return end
	local mon=t.Monster
	local lvl=getMonsterLevel(mon)
	local chance=s/estimateSkill(lvl)*cfg.chanceMult
		*damageMultiplier[t.Player:GetIndex()].Melee/math.min(1+lvl/150,3)
	if chance<=math.random() then return end
	local duration=cfg.duration
	if m==cfg.mastery then
		duration=duration/2
	end
	duration=calcDebuffDuration(mon, stunCC, duration)
	if duration<=0 then return end
	RunNextTick(function()
		if mon.HP~=0 then
			--extend, never cut a longer stun already running
			mon.SpellBuffs[6].ExpireTime=math.max(mon.SpellBuffs[6].ExpireTime, Game.Time+duration)
		end
	end)
end

-- from Scripts/General/zzMAW-Skills.lua:2439 -- clear stun when monster dies
local function stage_stunDeathCleanup(t)
	local mon=t.Monster
	RunNextTick(function()
		if mon.HP==0 then
			mon.SpellBuffs[6].ExpireTime=0
		end
	end)
end

-- from Scripts/General/zzMaw-Spells.lua:973 -- high difficulty: attacking
-- cancels Fly except on allowed maps (flyAllowedMaps stays in zzMaw-Spells,
-- its LoadMap handler also reads it)
local function stage_flyRemoval(t)
	if Game.BolsterAmount>100 or vars.AusterityMode then
		if table.find(flyAllowedMaps,Map.Name) then 
			return
		end
		local data=t.Hit
		local flyTime=Party.SpellBuffs[7].ExpireTime
		if data and data.Player and flyTime>Game.Time then
			Party.SpellBuffs[5].ExpireTime=flyTime
			Party.SpellBuffs[7].ExpireTime=0
		end
	end
end

-- from Scripts/General/zzMaw-Spells.lua:1596 -- Stun spell (34): primes the
-- monster's Earth res/Level for the final division in res-and-retaliation,
-- restores them next tick
local function stage_stunSpellPrime(t)
	local data=t.Hit
	if data and data.Player and data.Object and data.Object.Spell==34 then
		local cc=CCMAP[const.Spells.Stun]
		local mon=t.Monster
		local oldResistance=mon.Resistances[const.Damage.Earth]
		local res=mon.Resistances[const.Damage.Earth]
		local lvl=mon.Level
		local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Earth))
		local newLevel=calcEffectChance(lvl, res, s, cc.ChanceMult, mon)
		local hit=(30/(30+newLevel/4))
		--mapping
		hit=affixCut(hit, 13)
		if hit>math.random() then
			mon.Resistances[const.Damage.Earth]=0
			mon.Level=0
		else
			mon.Resistances[const.Damage.Earth]=65000
		end
		RunNextTick(function()
			mon.Level=lvl
			mon.Resistances[const.Skills.Earth]=res
		end)
	end
end

-- from Scripts/General/zzMaw-Spells.lua:1812-1845 -- Mass Distortion rebalance
-- by bolster tier
--MASS DISTORSION Handled
--needs separate code to account for all scenario
local massHPMULT={
	[0]=1,
	[50]=1,
	[100]=1,
	[150]=1.4,
	[200]=1.8,
	[300]=3,
	[600]="doom",
}
local function stage_massDistortion(t)
	local data=t.Hit
			local mon=t.Monster
			local lvl=getMonsterLevel(mon)
	if data and data.Player and data.Spell==44 then
		mult=1

		if massHPMULT[Game.BolsterAmount]=="doom" then

			mult=3.33*(1+lvl/75)
			if mon.NameId>=220 and mon.NameId<300 then
				mult=mult*2*(1+mon.Level/80)
			end
		else
			mult=massHPMULT[Game.BolsterAmount] or 1
		end
		if vars.AusterityMode then
			mult=mult*4
		end
		t.Result=t.Result/mult^0.5*math.max(1, (mon.Level/250)^2)
	end
	
end

-- from Scripts/General/zzMaw-Spells.lua:3191 -- Sparks M+: chain a weaker copy
-- to the closest monster in range
local function stage_sparksChain(t)
	local data = t.Hit
	if data and data.Object and data.Player then
		if data.Object.Spell==18 and data.Object.SpellMastery>1 then
			local monsterIndex=getClosestMonsterInRange(t.Monster,768)
			if monsterIndex~=nil then
				BeginGrabObjects()
				Game.SummonObjects(2060,t.Monster.X,t.Monster.Y,t.Monster.Z+100,0,1)
				local obj=GrabObjects()
				if not obj then return end
				local index=data.Player:GetIndex()
				local id=slotByIndex(index) or 0
				local skill=Party[id].Skills[const.Skills.Air]
				local s, m = SplitSkill(skill)
				obj.Spell=18
				obj.SpellLevel=m
				obj.SpellMastery=data.Object.SpellMastery-1
				obj.SpellSkill=s
				obj.SpellType=18
				obj.TypeIndex=455
				obj.Owner=index*8+4
				obj.Visible=true
				obj.Velocity[0]=3000
				obj.Velocity[1]=3000
				obj.Velocity[2]=3000
				obj.Target=3+8*monsterIndex
			end
		end
	end
end

-- the stat rows bake the might multiplier at PLAYER level (stat screen);
-- real hits swap the level term to the monster's level
local function mightLevelSwap(pl, mon)
	if not mon then return 1 end
	local might=pl:GetMight()
	return (1+GetMightDamageMultiplier(might, safeGetMonsterLevel(mon)))
		/(1+GetMightDamageMultiplier(might, pl.LevelBase))
end

-- from Scripts/General/zzMaw-Stats.lua:141 -- THE base replacement for
-- melee/bow/blaster hits: recompute from Get(Melee|Ranged)DamageMin/Max,
-- x damageMultiplier (weapon-speed scaling), assassin isolation subtraction,
-- x crit (sets the global `crit` read by track-and-clamp), x0.5 Weak,
-- x0.25 blaster bonus2==3
local function stage_weaponRecompute(t)
  local data = t.Hit
  if not (data and data.Player and (t.DamageKind == 4
    or (data.Object and data.Object.Spell == 133 and data.Object.Item and data.Object.Item.Bonus2 == 3)
    or data.Spell == 135)) then
    return
  end

  local pl = t.Player
  if not pl then return end

  local idx = data.Player:GetIndex()
  if not damageMultiplier or not damageMultiplier[idx] then
    return
  end

  local dmgMult
  local baseDamage, maxDamage, damage
  if (data.Object == nil) or (data.Spell == 135) then
    baseDamage   = pl:GetMeleeDamageMin()
    maxDamage    = pl:GetMeleeDamageMax()
    damage       = rollDice(baseDamage, maxDamage)

    if table.find(assassinClass, pl.Class) and assassinationDamage then
      local isolatedDamageReduction = assassinationDamage(pl, t.Monster, data.Object)
      damage = damage - (isolatedDamageReduction or 0)
    end

    dmgMult = damageMultiplier[idx]["Melee"]
  else
    baseDamage   = pl:GetRangedDamageMin()
    maxDamage    = pl:GetRangedDamageMax()
    damage       = rollDice(baseDamage, maxDamage)

    dmgMult = damageMultiplier[idx]["Ranged"]
    if table.find(assassinClass, pl.Class) and assassinationDamage then
      assassinationDamage(pl, t.Monster, data.Object)
    end
  end

  t.Result = damage * (dmgMult or 1) * mightLevelSwap(pl, t.Monster)


  local critChance, critMult, success = getCritInfo(pl, false, safeGetMonsterLevel(t.Monster))
  if success then
    t.Result = t.Result * critMult
	DamageState.setCrit(true)
  end

  if data.Player.Weak and data.Player.Weak > 0 then
    t.Result = t.Result * 0.5
  end
  if data.Object and data.Object.Spell == 133 and data.Object.Item and data.Object.Item.Bonus2 == 3 then
    t.Result = t.Result * 0.25
  end
end

-- from Scripts/General/zzMaw-Stats.lua:770 -- pain-reflection flag dance
-- (pairs with pstage_damageRecompute below, which consumes the flag)
local function stage_painReflectionFlag(t)
	if reflecting then
		reflecting=false
		return
	end
	if t.Monster.SpellBuffs[19].ExpireTime>=Game.Time then
		painReflectionHit=true
	end
end

-- from Scripts/General/zzMaw-Stats.lua:1105 -- damage-kind remaps, GM-bow
-- min-res pick, GM-spear cumulative res shred, legendary 29 res shred,
-- retaliation add, then the FINAL division by 2^(res%1000/100)
local function stage_resAndRetaliation(t)
	local data=t.Hit
	if data and data.Player and data.Spell then
		if data.Spell==const.Spells.Blades then
			t.DamageKind=const.Damage.Phys
		end
	end
	--fix for vampire Lifedrain and Souldrinker
	if data and data.Object and (data.Object.Spell==200 or data.Object.Spell==201) then
		t.DamageKind=const.Damage.Dark
	end
	
	index=table.find(damageKindMap,t.DamageKind)
	local res=t.Monster.Resistances[index]
	if data and data.Object and data.Object.Spell==133 then
		if data and data.Player then
			local it=t.Player:GetActiveItem(2)
			if it then 
			skill=it:T().Skill
				if skill==const.Skills.Bow then
					local s,m=SplitSkill(t.Player.Skills[const.Skills.Bow])
					if m>=4 then
						res=math.min(t.Monster.Resistances[0]%1000, t.Monster.Resistances[4])
					end
				end
			end
		end
	end
	if t.Result==0 then return end
	if not res then res=0 end
	--spear reduction
	if t.Player and data and data.Object==nil and t.DamageKind==4 then
		local it=t.Player:GetActiveItem(1)
		if it then 
			local skill=it:T().Skill
			if skill==const.Skills.Spear then
				local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Spear))
				if m>=4 then
					local id=t.Monster:GetIndex()
					mapvars.originalResistance=mapvars.originalResistance or {}
					mapvars.originalResistance[id]=mapvars.originalResistance[id] or t.Monster.Resistances[index]
					mapvars.spearDamageIncrease=mapvars.spearDamageIncrease or {}
					mapvars.spearDamageIncrease[id]=mapvars.spearDamageIncrease[id] or 0
					local mult=damageMultiplier[t.PlayerIndex]["Melee"]
					local damageIncrease=(2+s*0.02)*mult
					if it:T().EquipStat==1 then
						damageIncrease=damageIncrease*1.5
					end
					mapvars.spearDamageIncrease[id]=mapvars.spearDamageIncrease[id]+damageIncrease
					local reduction=calcSpearResReduction(mapvars.spearDamageIncrease[id])
					t.Monster.Resistances[index]=round(math.max(mapvars.originalResistance[id]-reduction,0))
				end
			end
		end
	end
	if t.Player and hasLegendary(t.PlayerIndex, 29) then
		if data and data.Object==nil and t.DamageKind~=4 then goto continue end --disable for melee elemental damage
		if data and table.find(aoespells, data.Spell) and math.random()>0.4 then goto continue end
		for i=0, 10 do
			if i~=5 then
				if i==4 then
					local id=t.Monster:GetIndex()
					if mapvars.originalResistance and mapvars.originalResistance[id] then
						mapvars.originalResistance[id]=math.max(mapvars.originalResistance[id]-1,0)
					else
						t.Monster.Resistances[i]=math.max(t.Monster.Resistances[i]-1,0)
					end
				else
					t.Monster.Resistances[i]=math.max(t.Monster.Resistances[i]%1000-1,0)+math.floor(t.Monster.Resistances[i]/1000)*1000
				end
			end
		end
	end
	::continue::
	--retaliation code
	if t.Player then
		local id=t.Player:GetIndex()
		if vars.retaliation and vars.retaliation[id] and vars.retaliation[id]["Time"] and vars.retaliation[id].Time+const.Minute*5>Game.Time and vars.retaliation[id].Stacks>0 then
			local pl=t.Player
			local s,m=SplitSkill(Skillz.get(pl,53))
			local fullHP=pl:GetFullHP()
			local stacks=vars.retaliation[id].Stacks
			if m<4 then
				stacks=1
			end
			local powerMult, DPS2, DPS3, vitMult=calcPowerVitality(pl, false)
			local vit=round(vitMult^0.35)
			local power=round(powerMult^0.35)
			local totalRetDamage=power*vit*s*stacks
			t.Result=t.Result+totalRetDamage
			
			if 0.25*stacks>math.random() then
				local stunDuration=const.Minute
				if t.Monster.NameId>=220 and t.Monster.NameId<=300 then
					stunDuration=stunDuration/2
				end
				t.Monster.SpellBuffs[6].ExpireTime=Game.Time+const.Minute
			end
			RunNextTick(function()
				pl.RecoveryDelay=pl.RecoveryDelay*(math.max(1-0.3*stacks,0))
			end)
			vars.retaliation[id].Stacks=0
		end
	end
	
	t.Result = resDivide(t.Result, res)
end


-- --- Tier 2: was GameInitialized2-registered -------------------------------

-- from Scripts/General/zzClasses.lua:855 -- Dragon full damage replacement:
-- melee (fang knockback, SP gain for classes 10/11, own res division) and
-- breath/spell-123 ranged (crit, min-res pick, randomized spread)
local function stage_dragonAttack(t)
	local data=t.Hit
	if data and data.Player and Game.CharacterPortraits[data.Player.Face].Race==const.Race.Dragon then
		local pl=data.Player
		if data.Object==nil then
			local breath = SplitSkill(data.Player:GetSkill(const.Skills.DragonAbility))
			local fang, fangM = SplitSkill(data.Player:GetSkill(const.Skills.Unarmed))
			if breath>=fang then
				local x, y = directionToUnitVector(Party.Direction)
				mult=fang/t.Monster.Level^0.75
				DamageState.addPush({["directionX"]=x, ["directionY"]=y, ["duration"]=60*mult^0.5, ["totalDuration"]=60*mult^0.5, ["totalForce"]=800*mult, ["currentForce"]=800*mult, ["id"]=t.MonsterIndex})
			end
			
			local low=pl:GetMeleeDamageMin()
			local high=pl:GetMeleeDamageMax()
			local damage=rollDice(low, high)*mightLevelSwap(pl, t.Monster)

			--check by damage type
			index=table.find(damageKindMap,t.DamageKind)
			res=t.Monster.Resistances[index]
			if not res then return end
			local gotCrit
			critChance, critMult, gotCrit=getCritInfo(pl,false,getMonsterLevel(t.Monster))
			--assigned, not or'd: a non-crit here clears a previous hit's tag
			DamageState.setCrit(gotCrit)
			if gotCrit then
				damage=damage*critMult
			end
			if pl.Class==10 then
				pl.SP=math.min(pl.SP+10, 60)
			elseif pl.Class==11 then
				pl.SP=math.min(pl.SP+20, 120)
			end
			--apply Damage
			t.Result = resDivide(damage, res)
		elseif t.DamageKind==50 or data.Spell==123 then
			local low=pl:GetRangedDamageMin()
			local high=pl:GetRangedDamageMax()
			local damage=rollDice(low, high)*mightLevelSwap(pl, t.Monster)
			
			local gotCrit
			critChance, critMult, gotCrit=getCritInfo(pl,false,getMonsterLevel(t.Monster))
			--assigned, not or'd: a non-crit here clears a previous hit's tag
			DamageState.setCrit(gotCrit)
			if gotCrit then
				damage=damage*critMult
			end
			if data.Spell==123 then
				local s,m=SplitSkill(t.Player.Skills[const.Skills.DragonAbility])
				local mult=0.85
				if m<=2 then
					mult=0.7
				elseif m>=4 then
					mult=1
				end
				damage=damage*mult
			end
			--randomize
			damage=damage*0.75+(damage*math.random()*0.25)+(damage*math.random()*0.25)
			--resistance
			if t.Monster then
				local res=10000
				local mon=t.Monster
				for i=0,10 do
					if mon.Resistances[i] and mon.Resistances[i]%1000<res then
						res=mon.Resistances[i]%1000
					end
				end
				damage = resDivide(damage, res)
			end
			--apply Damage
			t.Result = damage
		end
	end
end

-- from Scripts/General/zzClasses.lua:972 -- Shaman melee leech + mana restore
local function stage_shamanOnHit(t)
	local data = t.Hit
	if data and data.Player and table.find(shamanClass, data.Player.Class) and t.DamageKind==4 and data.Object==nil and t.Result>0 then	
		local m6=SplitSkill(data.Player.Skills[const.Skills.Mind])
		local m7,bM=SplitSkill(data.Player.Skills[const.Skills.Body])
		
		local FHP=data.Player:GetFullHP()
		local leech=Formulas.bodyLeech(FHP, m7, bM)
		local maxSP=data.Player:GetFullSP()
		data.Player.SP=math.min(data.Player.SP+Formulas.mindLeech(m6), getMaxMana(data.Player))
		
		local id=data.Player:GetIndex()
		
		local healing=math.min(data.Player:GetFullHP()-data.Player.HP, leech)
		if healing>0 then
			track("leechDone", id, healing)
		end
		data.Player.HP=math.min(data.Player.HP+leech, data.Player:GetFullHP())
	end
end

-- from Scripts/General/zzClasses.lua:1133 -- Death Knight: spell-melee damage
-- replacement (DKDamageMult spells), Body leech, dark grasp, on-hit SP regen,
-- slow/paralyze spell effects
local function stage_dkAttack(t)
	local data = t.Hit
	if data and data.Player and table.find(dkClass, data.Player.Class) then
		local pl=data.Player
--this hit's damage; the DKDamageMult branch below rolls its own
		local damage=t.Result
		local spell=0
		if data and data.Object and data.Object.Spell then
			spell=data.Object.Spell
		end
		if DKDamageMult[spell] then
			--add physical damage to spells
			baseDamage=pl:GetMeleeDamageMin()
			maxDamage=pl:GetMeleeDamageMax()
			damage=rollDice(baseDamage, maxDamage)*mightLevelSwap(pl, t.Monster)

			critChance, critMult, success=getCritInfo(pl,false,getMonsterLevel(t.Monster))
			if success then
				damage=damage*critMult
				DamageState.setCrit(true)
			end
			for i=0,1 do
				local it=pl:GetActiveItem(i)
				if it then
					local damage1=calcFireAuraDamage(pl, it, 0, false, false, "damage")
					local damage2=calcEnchantDamage(pl, it, 0, false, false, "damage")
					damage=damage+damage1+damage2
				end
			end
			
			local res=t.Monster.Resistances[t.DamageKind] or t.Monster.Resistances[4]
			damage=resDivide(damage, res)
			local mult=damageMultiplier[t.PlayerIndex]["Melee"]
			t.Result=damage*mult
			
			if pl.Weak>0 then
				t.Result=t.Result*0.5
			end
			
			--add spell modifier
			if DKDamageMult[spell] then
				local s,m=SplitSkill(pl.Skills[DKDamageMult[spell].Skill])
				t.Result=t.Result*DKDamageMult[spell][m]
			end
		end
		--life leech
		if t.DamageKind==4 and table.find(dkClass, data.Player.Class) then
			local pl=data.Player
			local bloodS, bloodM=SplitSkill(pl.Skills[const.Skills.Body])
			local FHP=pl:GetFullHP()
			local monLvl=getMonsterLevel(t.Monster)
			local heal=Formulas.dkPassiveLeech(FHP, bloodS, monLvl)
			--current active leech spell
			vars.dkActiveAttackSpell=vars.dkActiveAttackSpell or {}
			local id=pl:GetIndex()
			leech=0
			if vars.dkActiveAttackSpell and (vars.dkActiveAttackSpell[id]==68 or vars.dkActiveAttackSpell[id]==74) then
				local FHP=pl:GetFullHP()
				leech=Formulas.bloodLeech(FHP, bloodS, bloodM)
				pl.SP=pl.SP-6
				if vars.dkActiveAttackSpell[id]==74 then
					leech=leech * 2
					pl.SP=pl.SP-6
				end
			end
			
			local id=pl:GetIndex()
		
			local healing=math.min(pl:GetFullHP()-pl.HP, round(leech+heal))
			if healing>0 then
				track("leechDone", id, healing)
			end
			
			pl.HP=math.min(pl:GetFullHP(), pl.HP+heal+leech)
			
			local graspCost=MawCore.Classes.DKManaCost[96]
			if vars.dkActiveAttackSpell and vars.dkActiveAttackSpell[id]==96 and pl.SP>=graspCost then
				local graspDuration = calcDebuffDuration(t.Monster, darkGraspCC, DK_GRASP_DURATION)
				if graspDuration > 0 then
					pl.SP=pl.SP-graspCost
					t.Monster.SpellBuffs[const.MonsterBuff.DamageHalved].ExpireTime=math.max(t.Monster.SpellBuffs[const.MonsterBuff.DamageHalved].ExpireTime, Game.Time+graspDuration)
					local s, m=SplitSkill(pl.Skills[const.Skills.Dark])
					if m>=4 then
						t.Monster.SpellBuffs[const.MonsterBuff.MeleeOnly].ExpireTime=math.max(t.Monster.SpellBuffs[const.MonsterBuff.MeleeOnly].ExpireTime, Game.Time+graspDuration)
					end
				end
			end
			--restore SP
			if t.DamageKind==4 then
				local regen=spRegen[pl.Class]
				if damage>MawCore.MonsterHP.current(t.Monster) then
					regen=regen*1.5
				end
				pl.SP=math.min(getMaxMana(pl), pl.SP+regen)
			end
		end
		
		--spell effect
		if data and data.Object then
			if data.Object.Spell==26 then
				local s,m=SplitSkill(pl.Skills[const.Skills.Water])
				if m>=2 then
					local power=math.floor(m/2)*2
					local slowCC = {Debuff = const.MonsterBuff.Slow}
					local slowDuration = calcDebuffDuration(t.Monster, slowCC, const.Minute)
					if slowDuration > 0 then
						t.Monster.SpellBuffs[const.MonsterBuff.Slow].ExpireTime=math.max(t.Monster.SpellBuffs[const.MonsterBuff.Slow].ExpireTime, Game.Time+slowDuration)
						t.Monster.SpellBuffs[const.MonsterBuff.Slow].Power=power
					end
				end
			elseif data.Object.Spell==76 then
				local paraCC = {Debuff = const.MonsterBuff.Paralyze}
				local paraDuration = calcDebuffDuration(t.Monster, paraCC, const.Minute*2)
				if paraDuration > 0 then
					t.Monster.SpellBuffs[const.MonsterBuff.Paralyze].ExpireTime=math.max(t.Monster.SpellBuffs[const.MonsterBuff.Paralyze].ExpireTime, Game.Time+paraDuration)
				end
			end
		end
	end
end

-- from Scripts/General/zzClasses.lua:1962 -- Assassin: spell-melee damage
-- replacement (assassinSpells), blade-dance extra earth-res division
local function stage_assassinAttack(t)
	local data = t.Hit
	if data and data.Player and table.find(assassinClass, data.Player.Class) then
		local pl=data.Player
		local spell=0
		if data and data.Object and data.Object.Spell then
			spell=data.Object.Spell
		end
		if assassinSpells[spell] then
			local baseDamage=pl:GetMeleeDamageMin()
			local maxDamage=pl:GetMeleeDamageMax()
			local damage=rollDice(baseDamage, maxDamage)*mightLevelSwap(pl, t.Monster)
			
			local isolatedDamageReduction=assassinationDamage(pl,t.Monster,data.Object) --must be subtracted
			damage=damage-isolatedDamageReduction
			
			critChance, critMult, success=getCritInfo(pl,false,getMonsterLevel(t.Monster))
			if success then
				damage=damage*critMult
				DamageState.setCrit(true)
			end
			
			for i=0,1 do
				local it=pl:GetActiveItem(i)
				if it then
					local damage1=calcFireAuraDamage(pl, it, 0, false, false, "damage")
					local damage2=calcEnchantDamage(pl, it, 0, false, false, "damage")
					damage=damage+damage1+damage2
				end
			end
			
			local res=t.Monster.Resistances[t.DamageKind] or t.Monster.Resistances[4]
			damage=resDivide(damage, res)
			local mult=damageMultiplier[t.PlayerIndex]["Melee"]
			t.Result=damage*mult
			
			if pl.Weak>0 then
				t.Result=t.Result*0.5
			end
			
			if assassinSpells[spell].DamageMult then
				t.Result=t.Result*assassinSpells[data.Object.Spell].DamageMult
				if spell==44 then
					t.Result=resDivide(t.Result, t.Monster.Resistances[3])
				end
			end
		end
	end
end

-- from Scripts/General/zzMaw-Monsters.lua:3340 -- boss affixes (NameId 220-299):
-- Thorn/Reflecting reflect, Adamantite flat reduction, Swapper, Regenerating
local function stage_bossAffixes(t)
	if t.Monster.NameId>=220 and t.Monster.NameId<300 then
		if t.Player then
			index=slotByIndex(t.Player:GetIndex())
			skill = string.match(Game.PlaceMonTxt[t.Monster.NameId], "([^%s]+)")
			if skill=="Thorn" or skill=="Omnipotent" then
				if t.DamageKind==4 then
					reflectedDamage=true
					Party[index]:DoDamage(t.Result,4)
					reflectedDamage=false
				end
			end
			if skill=="Reflecting" or skill=="Omnipotent" then
				if t.DamageKind~=4 then
					local damageKind = t.DamageKind
					if damageKind==50 then --transform dragon damage into energy
						damageKind = 12
					end
					reflectedDamage=true
					Party[index]:DoDamage(t.Result,damageKind) 
					reflectedDamage=false
				end
			end
			if skill=="Adamantite" or skill=="Omnipotent" then
				t.Result=round(math.max(t.Result-t.Monster.Level^1.15*4,t.Result/4))
			end
			if skill=="Swapper" or skill=="Omnipotent" then
				for i=0,Map.Monsters.High do
					mon=Map.Monsters[i]
					if mon.HP>0 and mon.AIState==const.AIState.Active and mon.ShowOnMap and mon.ShowAsHostile and (mon.NameId<220 or mon.NameId>300) then
						t.Result=0
						Game.ShowStatusText("*Swap*")
						mon.X, mon.Y, mon.Z, t.Monster.X, t.Monster.Y, t.Monster.Z = t.Monster.X, t.Monster.Y, t.Monster.Z, mon.X, mon.Y, mon.Z
					end
				end
			end
			if skill=="Regenerating" or skill=="Omnipotent" then
				id=t.Monster:GetIndex()
				mapvars.regenerating=mapvars.regenerating or {}
				mapvars.regenerating[id] = mapvars.regenerating[id] or 0
				mapvars.regenerating[id] = mapvars.regenerating[id] + 1
				RunNextTick(function()
					if t.Monster.HP<=0 then
						mapvars.regenerating[id]=-1
					end
				end)
			end
		end
	end
end

-- from Scripts/General/zzMaw-Survival.lua:316 -- survival mode: zero all
-- damage outside survival maps
local function stage_survivalGate(t)
	if not survivalMaps[Map.Name] and vars.SuvivalMode then
		t.Result=0
	end
end

-- --- Tier 3: was Global file-scope (re-registered per save load) -----------

-- from Scripts/Global/zzMaw_Legendaries.lua:22 -- enchant/fire-aura flat adds,
-- legendaries 17/21/14/24/11, shaman fire + assassin water adds, shaman spell mult
--legendary-11 recovery-refund flag, consumed once per cast (NOTES.md)
local reduceRecovery

local function stage_legendaries(t)
	if t.Result==0 then return end
	local id=t.PlayerIndex
	local data=t.Hit
	if not data or not data.Player then return end
	local pl=data.Player
	local mon=t.Monster
	--weapon enchants	
	local fireAuraDamage=0
	local enchantDamage=0
	local fireRes=mon.Resistances[0]%1000
	if data and not data.Object and t.DamageKind==4 then
		for i=0,1 do
			local it=pl:GetActiveItem(i)
			if it then
				local damage=calcFireAuraDamage(pl, it, fireRes, true, false, "damage")
				if damage then
					fireAuraDamage=fireAuraDamage+damage
				end
				
				if it and enchantbonusdamage[it.Bonus2] then
					local id=table.find(damageKindMap,enchantbonusdamage[it.Bonus2].Type)
					local res=mon.Resistances[id]%1000
					local dmg=calcEnchantDamage(pl, it, res, true, false, "damage")
					if damage then
						enchantDamage=enchantDamage+dmg
					end
				end 
			end
		end
	elseif data and data.Object and (data.Object.Spell==133 or data.Spell==135) then --bow/blasters
		local it=pl:GetActiveItem(2)
		local damage=calcFireAuraDamage(pl, it, fireRes, true, false, "damage")
		if damage and damage>fireAuraDamage then
			fireAuraDamage=damage
		end
		if it and enchantbonusdamage[it.Bonus2] then
			local id=table.find(damageKindMap,enchantbonusdamage[it.Bonus2].Type)
			local res=mon.Resistances[id]%1000
			local dmg=calcEnchantDamage(pl, it, res, true, false, "damage")
			if damage then
				enchantDamage=enchantDamage+dmg
			end
		end 
	end
	t.Result=t.Result+fireAuraDamage+enchantDamage
	
	--[17]="Your hits will deal 1% of current monster HP health (0.4% for AoE, multi-hit spells and arrows)",
	if hasLegendary(id,17) then
		if t.Result>0 and ((data and data.Object==nil and t.DamageKind==4) or (data and data.Object)) then
			local dmg=MawCore.MonsterHP.current(mon)*0.02
			if data and data.Object and data.Object.Spell==44 then
				dmg=mon.HP*0.02
			end
			dmg=dmg/(1+mon.Resistances[4]/100)
			if (data and data.Object and data.Object.Spell and table.find(aoespells, data.Object.Spell)) or (data and data.Object and data.Object.Spell==133) then
				dmg=dmg*0.5
			end
			if  data and not data.Object then
				dmg=dmg*damageMultiplier[id]["Melee"]
			elseif data and data.Object and data.Object.Spell==133 then
				dmg=dmg*damageMultiplier[id]["Ranged"]
			elseif data and data.Object and data.Object.Spell>0 then
				if  table.find(dkClass, pl.Class) or table.find(assassinClass, pl.Class) then
					dmg=dmg*damageMultiplier[id]["Melee"]
				else
					local s,m = SplitSkill(pl:GetSkill(const.Skills.Learning))
					dmg=dmg*1.015^s
				end
			end
			t.Result=t.Result+dmg
		end
	end
	--shaman fire damage
	if table.find(shamanClass, pl.Class) and t.DamageKind==4 and data.Object==nil and t.Result>0 then	
		local s1=SplitSkill(pl.Skills[const.Skills.Fire])
		local fireDamage=s1*0.001
		fireDamage=math.max(MawCore.MonsterHP.current(mon)*fireDamage,s1)
		fireDamage=resDivide(fireDamage, mon.Resistances[0])
		t.Result=t.Result+fireDamage
	end
	--same for assassin
	if data and pl and table.find(assassinClass, pl.Class) and t.DamageKind==4 and data.Object==nil and t.Result>0 then	
		local s1=SplitSkill(pl.Skills[const.Skills.Water])
		local waterDamage=s1*0.001
		waterDamage=math.max(MawCore.MonsterHP.current(mon)*waterDamage,s1)
		waterDamage=resDivide(waterDamage, mon.Resistances[2])
		t.Result=t.Result+waterDamage
	end
	if hasLegendary(id,21) then
		local mult=1
		for i=0, Map.Monsters.High do
			if Map.Monsters[i].Active then
				local dist=getDistanceToMonster(Map.Monsters[i])
				if dist<=512 then
					mult=mult+0.05
				end
			end
		end
		t.Result=t.Result*math.min(mult,2)
	end
	--end of [17]
	--[14]="Critical chance over 100% increases total damage",
	if hasLegendary(id,14) then
		local critChance=getCritInfo(pl,false,getMonsterLevel(mon))
		t.Result=math.round(t.Result*math.max(critChance,1))
	end
	--end of [14]
	--[24] killing a monster restores a share of health and mana
	if hasLegendary(id,24) then
		--restoreHPLeg=true
		RunNextTick(function()
			--if restoreHPLeg then
				--restoreHPLeg=false
				if mon.HP<=0 then
					local fullHP=GetMaxHP(pl)
					local fullSP=getMaxMana(pl)
					local F=MawCore.Formulas
					pl.HP=math.min(fullHP, pl.HP+fullHP*F.legendary24Health)
					pl.SP=math.min(fullSP, pl.SP+fullSP*F.legendary24Mana)
				end
			--end
		end)
	end
	--end of 24
	if hasLegendary(id,11) then
		data=t.Hit
		--no aoe spells
		if (data and data.Object and table.find(aoespells,data.Object.Spell)) or (data and data.Spell==133) then
			return
		else
			reduceRecovery=true
			RunNextTick(function()
				if reduceRecovery then
					reduceRecovery=false
					if mon.HP<=0 then
						reduceRecovery=false
						pl.RecoveryDelay=pl.RecoveryDelay/2
						--changePlayer(id)
					end
				end
			end)
		end
	end
	if table.find(shamanClass, pl.Class)  then
		if t.Result>0 and data and data.Object and data.Object.Spell>0 and data.Object.Spell<99 and data.Object.Spell~=44 then
			local s=0
			for school=12,18 do
				local skill=SplitSkill(pl.Skills[school])
				s=s+skill
			end
			local mult=1+s/200
			t.Result=t.Result*mult
		end
	end
	
end

-- from Scripts/Global/zzMaw_Mapping.lua:16 -- map affix damage mults/miss/reflect
local function stage_mapAffixes(t)
	if t.Player and t.DamageKind==4 then
		t.Result=affixCut(t.Result, 23)
	end
	if t.Player and t.DamageKind~=4 then
		t.Result=affixCut(t.Result, 24)
	end
	if t.Player and getMapAffixPower(30) then
		if math.random()<getMapAffixPower(30)/100 then
			t.Result=0
		end
	end
	if t.Player and getMapAffixPower(5) and t.DamageKind==4 then
		reflectedDamage=true
		t.Player:DoDamage(affixCut(t.Result, 5),4)
		reflectedDamage=false
	end
	if t.Player and getMapAffixPower(6) and t.DamageKind~=4 then
		reflectedDamage=true
		t.Player:DoDamage(affixCut(t.Result, 6),t.DamageKind)
		reflectedDamage=false
	end
end

-- from Scripts/Global/zzMAWStatusMsg.lua:2 -- multiplayer remote-owner zero
local function stage_remoteOwnerZero(t)
	local source = t.Hit
	if source then
		local obj = source.Object
		if obj and bit.And(obj.Bits, REMOTE_OWNER_BIT) > 0 then
			t.Result = 0 -- let owner calculate damage
		end
	end
end

-- from Scripts/Global/zzMAWStatusMsg.lua:151 (first lines, split out so it
-- runs before leech)
local function stage_friendlyFireZero(t)
	-- disable damage on friendly units
	if vars.MAWSETTINGS.friendlyDamage=="OFF" and t.Player and t.Monster and t.Monster.Hostile==false and t.Monster.ShowAsHostile==false then
		t.Result=0
	end
end

-- from Scripts/Global/zzMAWStatusMsg.lua:24 -- universal leech ("moved here, to
-- make sure it takes all the damage modifiers" -- original comment; that is why
-- it sits this late in the order)
local function stage_leech(t)
	local data=t.Hit
	if data and data.Player and t.Result>0 then
		local partyHP=partyHPSum()
		local pl=data.Player
		local index=pl:GetIndex()
		local mon=t.Monster
		--pick B monster and heal amount
		local id=mon.Id
		if id%3==0 then
			id=id-1
		elseif id%3==1 then
			id=id+1
		end
		local refHP=HPtable[id]
		
		local fullHP=GetMaxHP(pl) or 0 --if player is disintegrated
		local manaLeechLeg=false
		if hasLegendary(index,31) then
			fullHP=getMaxMana(pl) or 0
			manaLeechLeg=true
		end
		local baselineHeal=t.Result/refHP*fullHP --basically dealing 100% of monster B HP as damage heals you by 100%
		
		baselineHeal=affixCut(baselineHeal, 32)
		local totalHeal=0
		local minLeech=0
		if not lifeLeech or not lifeLeech[index] then return end
		
		if t.DamageKind==4 then
			--melee
			if not data.Object then
				local meleeLeech=lifeLeech[index].Melee+getDragonRegenLeech(pl, getMonsterLevel(mon))
				totalHeal=baselineHeal*meleeLeech

				local recovery=pl:GetAttackDelay()
				minLeech=fullHP*meleeLeech/5*recovery/100
			end
			--ranged
			if data.Object and data.Object.Spell==133 then
				totalHeal=baselineHeal*lifeLeech[index].Ranged
				
				local recovery=pl:GetAttackDelay(true)
				minLeech=fullHP*lifeLeech[index].Ranged/5*recovery/100
			end
		end
		--spells
		
		local spell=data.Spell
		--special case for lifeDrain
		if spell==200 then
			spell=111
			totalHeal=baselineHeal*0.1
		end
		if spell==201 then
			spell=99
			totalHeal=baselineHeal*0.1
		end
		if spell and spell>0 and spell<132 then
			totalHeal=totalHeal+baselineHeal*lifeLeech[index].Spell
			
			local recovery=getSpellDelay(pl,spell)
			minLeech=fullHP*lifeLeech[index].Spell/5*recovery/100
			if table.find(aoespells, spell) then
				minLeech=minLeech/2.5
			end
			if spell==9 or spell==22 or spell==43 then
				minLeech=minLeech/4
			end
		end 
		
		--dk death coil
		if spell and spell==90 and table.find(dkClass, pl.Class) then
			local s,m=SplitSkill(pl.Skills[20])
			local mult=1
			if m==3 then
				mult=1.5
			end
			totalHeal=totalHeal+baselineHeal*0.2*mult
		end
		totalHeal=math.ceil(math.max(totalHeal, minLeech))
		
		local overHeal=0
		if manaLeechLeg then
			totalHeal=totalHeal/2
			pl.SP=math.min(getMaxMana(pl),pl.SP+totalHeal)
			totalHeal=totalHeal/fullHP --remove mana portion
			fullHP=GetMaxHP(pl) 
			totalHeal=fullHP*totalHeal --add life portion
		end
		overHeal=round(pl.HP+totalHeal-fullHP)
		pl.HP=math.min(fullHP,pl.HP+totalHeal)
		if overHeal>0 and hasLegendary(index,27) then
			local id, lowestHealthPercentage=pickLowestPartyMember()
			local percent, partyId, playerId=OnlineLowestHealthPercentage()
			if percent<lowestHealthPercentage then
				SendHeal(partyId, playerId, overHeal, pl.Name)
			else
				Party[id].HP=math.min(Party[id].HP+overHeal, GetMaxHP(Party[id]))
			end
		end
		local partyHP2=partyHPSum()
		if partyHP2>partyHP and (Party.EnemyDetectorRed or Party.EnemyDetectorYellow) then
			track("leechDone", pl:GetIndex(), partyHP2-partyHP)
		end
	end
end

-- from Scripts/Global/zzMAWStatusMsg.lua:151 (rest) -- damage tracking vars,
-- ShowDamage status message, HP-overcap divide, ceil + 32500 cap
--AoE-total message state, shared across the hits of one cast (NOTES.md)
local MSGdamage, calls

local function stage_trackAndClamp(t)
	if t.Result==0 then return end

	local data=t.Hit
	local damage=0

	--recount
	if data and data.Player then
		damage=t.Result
		if data.Spell==44 then
			damage=damage*MawCore.MonsterHP.scale(t.Monster)
		end
		
		if data.Object then
			track("damageTrackRanged", data.Player:GetIndex(), damage)
		else
			track("damageTrack", data.Player:GetIndex(), damage)
		end
		if ShowDamage then
			ShowDamage(data.Player, damage, DamageState.isCrit(), data.Object, t.Monster)
		end
		
	end
	
	
	if data and data.Player then
		local slot=slotByIndex(t.PlayerIndex)
		if slot then
			checkSkills(slot) --to use the correct spell name
		end
		MSGdamage=MSGdamage or 0
		MSGdamage=MSGdamage+math.ceil(damage)
		local msgTxt=MSGdamage
		msgTxt=shortenNumber(msgTxt, 4, true)
		local attackIsSpell=false
		local castedAoe=false
		local shoot="hits"
		local critMessage= ""
		local name, monName, msg
		if data.Object then 
			if data.Object.SpellType>1 and data.Object.SpellType<133 then
				name=Game.SpellsTxt[data.Object.SpellType].Name
				attackIsSpell=true
			else
				name=t.Player.Name
				shoot="shoots"
			end
		else
			name=t.Player.Name
		end
		if damage>MawCore.MonsterHP.current(t.Monster) then
			shoot="inflicts"
		end
		if DamageState.isCrit() then
			critMessage=StrColor(255,255,30,"(CRIT!)")
--consume the flag next tick, so same-tick hits still share the tag
			RunNextTick(function()
				DamageState.setCrit(false)
			end)
		end
		if t.Monster.NameId>0 then
			monName=Game.PlaceMonTxt[t.Monster.NameId]
		else
			monName=Game.MonstersTxt[t.Monster.Id].Name
		end	
		if shoot=="shoots" then
			msg=string.format("%s shoots %s for %s points!", name, msgTxt, monName)
		else
			msg=string.format("%s hits %s for %s points!", name, msgTxt, monName)
		end
		if damage>MawCore.MonsterHP.current(t.Monster) then
			msg=string.format("%s inflicts %s points killing %s!", name, msgTxt, monName)
		end
		calls=calls or 0
		calls=calls+1
		if calls>=2 and attackIsSpell then
			castedAoe=true
		end
		local id=t.MonsterIndex
		RunNextTick(function()
			if id<=Map.Monsters.High and MSGdamage>0 then
				if shoot=="shoots" then
				msg=string.format("%s shoots %s for %s points!%s", name, monName, msgTxt, critMessage)
				else
					msg=string.format("%s hits %s for %s points!%s", name, monName, msgTxt, critMessage)
				end
				if t.Monster.HP==0 then
					msg=string.format("%s inflicts %s points killing %s!%s", name, msgTxt, monName, critMessage)
				end
				if castedAoe then
					msg=string.format("%s hits for a total of %s points!%s", name, msgTxt, critMessage)
				end
				Game.ShowStatusText(msg)
				
				
				if calls>0 then
					calls=calls-1
					if t.Result==0 then
						calls=0
					end
				end
				if calls==0 then
					MSGdamage=0
				end
			end
		end)
	end
	--restore tooltips
	local id=Game.CurrentPlayer
	if id>=0 and id<=Party.High then
		checkSkills(id)
	end
end

-- ledger damage application for monsters over the engine HP cap (the module
-- owns the logic; see MawCore/MonsterHP.lua)
local function stage_monsterHP(t)
	MawCore.MonsterHP.stage(t)
end

local function stage_finalClamp(t)
	t.Result=math.ceil(t.Result)
	if t.Result>32500 then
		t.Result=32500
	end
end

-- ===========================================================================
-- The pipeline. Stage order IS the damage formula.
-- ===========================================================================

local pipe = MawCore.Pipeline.new("DamageToMonster", {
	"context",				-- resolve t.Hit once
	-- tier 1: was General file-scope
	"seraph-on-hit-heal",		-- [reactions]
	"elementalist-learning",	-- [reactions]
	"elementalist-stack-reset",	-- [reactions]
	"engine-reset",				-- [base] discard engine calc, start from raw damage
	"reveal-nearby",			-- [reactions]
	"monster-vs-monster",		-- [base]
	"cover-flag",				-- [reactions]
	"weapon-stun",				-- [reactions]
	"stun-death-cleanup",		-- [reactions]
	"fly-removal",				-- [reactions]
	"stun-spell-prime",			-- [resistance] primes res for res-and-retaliation
	"mass-distortion",			-- [mult]
	"sparks-chain",				-- [reactions]
	"weapon-recompute",			-- [base] THE melee/ranged replacement
	"pain-reflection-flag",		-- [reactions]
	"res-and-retaliation",		-- [resistance] final / 2^(res/100)
	-- tier 2: was GameInitialized2-registered
	"dragon-attack",			-- [base] class override
	"shaman-on-hit",			-- [reactions]
	"dk-attack",				-- [base] class override
	"assassin-attack",			-- [base] class override
	"boss-affixes",				-- [reactions]
	"survival-gate",			-- [gates]
	-- tier 3: was Global file-scope
	"legendaries",				-- [additive/mult] post-res on purpose
	"map-affixes",				-- [mult/gates]
	"remote-owner-zero",		-- [gates]
	"friendly-fire-zero",	-- [gates] ahead of leech: zeroed hits must not heal
	"leech",					-- [reactions]
	"track-and-clamp",			-- [reactions] tracking + status message
	"monster-hp",				-- [clamp] real-HP ledger, proxy conversion
	"final-clamp",				-- [clamp] ceil + 32500 cap
})

pipe:on("context",           "MawCore",              stage_context)
pipe:on("seraph-on-hit-heal", "zzClasses:255",       stage_seraphOnHitHeal)
pipe:on("elementalist-learning",    "zzClasses:1534", stage_elementalistLearning)
pipe:on("elementalist-stack-reset", "zzClasses:1649", stage_elementalistStackReset)
pipe:on("engine-reset",      "zzMaw-Monsters:2236",  stage_engineReset)
pipe:on("reveal-nearby",     "zzMaw-Monsters:4475",  stage_revealNearby)
pipe:on("monster-vs-monster","zzMaw-Monsters:4548",  stage_monsterVsMonster)
pipe:on("cover-flag",        "zzMAW-Skills:2248",    stage_coverFlag)
pipe:on("weapon-stun",       "zzMAW-Skills:2395",    stage_weaponStun)
pipe:on("stun-death-cleanup","zzMAW-Skills:2439",    stage_stunDeathCleanup)
pipe:on("fly-removal",       "zzMaw-Spells:973",     stage_flyRemoval)
pipe:on("stun-spell-prime",  "zzMaw-Spells:1596",    stage_stunSpellPrime)
pipe:on("mass-distortion",   "zzMaw-Spells:1823",    stage_massDistortion)
pipe:on("sparks-chain",      "zzMaw-Spells:3191",    stage_sparksChain)
pipe:on("weapon-recompute",  "zzMaw-Stats:141",      stage_weaponRecompute)
pipe:on("pain-reflection-flag", "zzMaw-Stats:770",   stage_painReflectionFlag)
pipe:on("res-and-retaliation",  "zzMaw-Stats:1105",  stage_resAndRetaliation)
pipe:on("dragon-attack",     "zzClasses:855",        stage_dragonAttack)
pipe:on("shaman-on-hit",     "zzClasses:972",        stage_shamanOnHit)
pipe:on("dk-attack",         "zzClasses:1133",       stage_dkAttack)
pipe:on("assassin-attack",   "zzClasses:1962",       stage_assassinAttack)
pipe:on("boss-affixes",      "zzMaw-Monsters:3340",  stage_bossAffixes)
pipe:on("survival-gate",     "zzMaw-Survival:316",   stage_survivalGate)
pipe:on("legendaries",       "zzMaw_Legendaries:22", stage_legendaries)
pipe:on("map-affixes",       "zzMaw_Mapping:16",     stage_mapAffixes)
pipe:on("remote-owner-zero", "zzMAWStatusMsg:2",     stage_remoteOwnerZero)
pipe:on("friendly-fire-zero","zzMAWStatusMsg:151a",  stage_friendlyFireZero)
pipe:on("leech",             "zzMAWStatusMsg:24",    stage_leech)
pipe:on("track-and-clamp",   "zzMAWStatusMsg:151",   stage_trackAndClamp)
pipe:on("monster-hp",        "MawCore",              stage_monsterHP)
pipe:on("final-clamp",       "MawCore",              stage_finalClamp)

Damage.pipe = pipe

function Damage.run(t)
	pipe:run(t)
end

function Damage.describe()
	return pipe:describe() .. "\n" .. Damage.playerPipe:describe()
end

------------------------------------------------------------------------
-- CalcDamageToPlayer pipeline -- stage bodies verbatim from the legacy
-- handlers; zzzzzMaw_Damage.lua registers the event. Inventory and the
-- handlers deliberately left raw: DAMAGE_PIPELINE.md.

local aoespellsMultiplayer={6,9,22,41,97}

-- from zzMaw-Items:3595 -- per-hit itemStats refresh (hits break equipment)
local function pstage_itemRefresh(t)
	RunNextTick(function()
		mawRefresh(t.PlayerIndex)
	end)
end

-- from zzMaw-Monsters:2552 -- madness death-seed mark
local function pstage_deathSeedMark(t)
  if vars.madnessMode and vars.MadnessDeathSeed then
    vars.lastHitTime=Game.Time
    SeedDeaths.mark_pending_for_current()
  end
end

local monsterDamageDebuff = {
	[const.MonsterBuff.DamageHalved] = 0.7,	--Dark Grasp
	[const.MonsterBuff.ShrinkingRay] = 0.7,
}
Damage.monsterDamageDebuff = monsterDamageDebuff	--zzMaw-Spells prints these

-- from zzMaw-Stats:735 -- THE player-damage replacement (reflects, friendly
-- fire, traps, dodge, monster attacks, disease, exploding bosses)
local function pstage_damageRecompute(t)
	local data=DamageState.getCustomAttacker() or WhoHitPlayer()
	if reflectedDamage then
		data=nil
	end
	local pl=t.Player
	
	if reflectedDamage then
		reflectedDamage=false
		t.Result=t.Result^0.85
		return
	end
	--PAIN REFLECTION FIX
	if painReflectionHit then
		painReflectionHit=false
		t.Result=t.Result^0.85
		return
	end
	if pl.SpellBuffs[10].ExpireTime>Game.Time then
		reflecting=true
	end
	if data and data.Player and data.Spell and data.Spell==133 then
		return
	end
	--properly calculate friendly fire damage
	if data and data.Player and data.Spell and data.Spell<133 and data.Spell>0 then	
		local s,m = SplitSkill(data.Player:GetSkill(const.Skills.Learning))
		local diceMin, diceMax, damageAdd = ascendSpellDamage(s, m, data.Spell,data.Player:GetIndex())
		local damage=damageAdd
		for i=1, data.SpellSkill do
			damage=damage+math.random(diceMin,diceMax)
		end
		local distance=getDistance(data.Object.X,data.Object.Y,data.Object.Z)/512
		local damageMult=math.max(1-distance, 0)
		damage=damage*damageMult
		
		--no crit nor intellect buff
		t.Result=calcMawDamage(t.Player,t.DamageKind,damage,false,data.Player.LevelBase)
		return
	end
	
	if not (data) or not (data and data.Monster) then
		if (t.DamageKind~=4 and t.DamageKind~=2) or Map.IndoorOrOutdoor==1 then --drown and fall
			--[[
			local name=Game.MapStats[Map.MapStatsIndex].Name
			local bolster=getPartyLevel()
			local mapLevel=mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High
			if vars.madnessMode then
				mapLevel=madnessMapLevels[name]
			elseif vars.freeProgression then
				mapLevel=bolster+(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3
			end
			if mapvars.mapAffixes then
				mapLevel=(mapvars.mapAffixes.Power*10+(mapLevels[name].Low+mapLevels[name].Mid+mapLevels[name].High)/3)
			end
			if not mapLevel then
				mapLevel=getTotalLevel()
			end
			]]
			local mapLevel=getTotalLevel()
			--trap and objects multiplier
			local damage=getMonsterDamage(false, mapLevel)
			
			if data and data.Object and data.Object.SpellType==15 then 
				damage=damage/3
			end
			local s,m=SplitSkill(t.Player.Skills[const.Skills.Perception])
			damage=damage*math.min((11-m*2)/10,1)
			t.Result=calcMawDamage(t.Player,t.DamageKind,damage)
		end
		
		return
	end
	
	--carnage fix
	if data and data.Player and data.Spell==133 then
		t.Result=0
		return
	end
	
	local mon=data.Monster
	local lvl=getMonsterLevel(mon)

	--dodging DODGE
	local dodging=0
	local Skill, Mas = SplitSkill(pl:GetSkill(const.Skills.Dodging))
	if Mas == 4 then
		dodging=Skill+10
	end
	local dodgeChance=1-1/(1+dodging/200)
	if Game.CharacterPortraits[pl.Face].Race==const.Race.Dragon then
		dodgeChance=0
	end
	--[[
	if table.find(assassinClass,pl.Class) then
		local Skill, Mas = SplitSkill(pl:GetSkill(const.Skills.Air))
		dodgeChance=1-0.995^Skill+0.05
	end
	]]
	roll=math.random()

	local dodgeableHere=data.MonsterAction==2 or data.MonsterAction==3
		or data.Object~=nil
	local speedDodged=dodgeableHere and MawRollDodge(mon, pl)==false
	if dodgeChance>=roll or speedDodged then
		t.Result=0
		-- Use the same player that performed the dodge calculation
		local index = -1
		for i = 0, Party.High do
			if Party[i]:GetIndex() == t.PlayerIndex then
				index = i
				break
			end
		end
		if index >= 0 then
			evt.FaceExpression{Player = index, Frame = 33}
		end
		return
	end
	
	local damage=getMonsterDamage(mon)
	--works for attack 1 and 2
	if data.MonsterAction==1 then
		local atk1=mon["Attack1"]
		local damage1=atk1.DamageAdd
		for i=1,atk1.DamageDiceCount do
			damage1=damage1+(atk1.DamageDiceSides+1)/2
		end
		local atk2=mon["Attack2"]
		local damage2=atk2.DamageAdd
		for i=1,atk2.DamageDiceCount do
			damage2=damage2+(atk2.DamageDiceSides+1)/2
		end
		local mult=damage2/damage1
		
		t.DamageKind=atk2.Type
		t.Damage=damage*mult
	elseif data.MonsterAction==0 then
		local atk=mon["Attack1"]
		t.DamageKind=atk.Type
		t.Damage=damage
		
	end
	
	if t.Damage==0 and t.Result==0 then return end

	if t.DamageKind==4 and restoringMistformTime
			and restoringMistformTime[t.PlayerIndex] then
		t.Damage=t.Damage*0.25
	end

	--mapping
	if getMapAffixPower(14) and math.random()<getMapAffixPower(14) then
		t.DamageKind=12
	end
	
	--apply Damage
	--modify spell damage as it's not handled in maw-monsters
	if data and data.Monster and data.Object and data.Object.Spell<100 and data.Object.Spell>0 then
		local damage=getMonsterDamage(mon)
		if monsterSpellMultiplierList[data.Object.Spell] then
			damage=damage*monsterSpellMultiplierList[data.Object.Spell]
		end
		t.Damage=damage
	end
	t.Damage=round(t.Damage)
	--randomize
	local roll=(math.random(75,125)+math.random(75,125))/200
	t.Damage=t.Damage*roll
	
	if mon then
		local debuffMult=1
		for buff, mult in pairs(monsterDamageDebuff) do
			if mon.SpellBuffs[buff].ExpireTime>=Game.Time then
				debuffMult=math.min(debuffMult, mult)
			end
		end
		t.Damage=t.Damage*debuffMult
	end
	
	if data and data.Monster and data.Object and data.Object.Spell<100 and data.Object.Spell>0 then
		t.Result = calcMawDamage(t.Player,t.DamageKind,t.Damage,false,lvl) -- spell randomization is off
	elseif data and data.Monster then
		t.Result = calcMawDamage(t.Player,t.DamageKind,t.Damage,false,lvl)
	else
		t.Result = calcMawDamage(t.Player,t.DamageKind,t.Damage,true)
	end
	
	local DiseaseDamage = 1
	if t.Player.Disease3>0 then
		DiseaseDamage = 2
	elseif t.Player.Disease2>0 then
		DiseaseDamage = 1.5
	elseif t.Player.Disease1>0 then
		DiseaseDamage = 1.25
	end
	if Party.High==0 then
		DiseaseDamage = (DiseaseDamage-1)/2 + 1
	end
	t.Result = t.Result * DiseaseDamage
	if data and data.Monster and data.Monster.NameId>220 then
		local mon=data.Monster
		local skill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
		if skill=="Exploding" or skill=="Omnipotent" then
			t.Result=t.Result/2
			local aoeDamage=t.Result/Party.Count
			for i=0,Party.High do
				local damage = calcManaShield(Party[i], aoeDamage)
				Party[i].HP=Party[i].HP-damage
				Party[i]:ShowFaceAnimation(24)
			end
		end
	end
end

-- from zzMaw-Monsters:3269 -- boss on-hit affixes vs the player
local function pstage_bossAffixesPlayer(t)
	local data=DamageState.getCustomAttacker() or WhoHitPlayer()
	if data and data.Monster and data.Monster.NameId>=220 and data.Monster.NameId<300 then
		mon=data.Monster
		skill = string.match(Game.PlaceMonTxt[mon.NameId], "([^%s]+)")
		if skill=="Summoner" then
			if math.random()<0.4 or t.DamageKind==4 then
				pseudoSpawnpoint{monster = math.ceil(mon.Id/3)*3-2, x = (Party.X+mon.X)/2, y = (Party.Y+mon.Y)/2, z = Party.Z, count = 1, powerChances = {75, 25, 0}, radius = 64, group = 1,transform = function(mon) mon.Hostile = true mon.ShowAsHostile = true mon.Velocity=350 end}
			end
		elseif skill=="Venomous" then
			t.Player.Poison3=Game.Time
		elseif skill=="Plagueborn" then
			t.Player.Disease3=Game.Time
		elseif skill=="Fixator" then
			t.Player.Weak=Game.Time
		elseif skill=="Swapper" then	
			Game.ShowStatusText("*Swap*")
			Party.X, Party.Y, Party.Z, mon.X, mon.Y, mon.Z = mon.X, mon.Y, mon.Z, Party.X, Party.Y, Party.Z
			Party.Direction, mon.Direction=mon.Direction, Party.Direction
		elseif skill=="Puller" then
			local direction=calculateDirection(Party.X, Party.Y,mon.X,mon.Y)
			evt.Jump{Direction = direction, ZAngle = 128, Speed = 1000}
		end
		
		if skill=="Omnipotent" then
			if math.random()<0.4 or t.DamageKind==4 then
				pseudoSpawnpoint{monster = math.ceil(mon.Id/3)*3-2, x = (Party.X+mon.X)/2, y = (Party.Y+mon.Y)/2, z = Party.Z, count = 1, powerChances = {75, 25, 0}, radius = 64, group = 1,transform = function(mon) mon.Hostile = true mon.ShowAsHostile = true mon.Velocity=350 end}
			end
			t.Player.Poison3=Game.Time
			t.Player.Disease3=Game.Time
			t.Player.Weak=Game.Time
			Game.ShowStatusText("*Swap*")
			Party.X, Party.Y, Party.Z, mon.X, mon.Y, mon.Z = mon.X, mon.Y, mon.Z, Party.X, Party.Y, Party.Z
			Party.Direction, mon.Direction=mon.Direction, Party.Direction
			local direction=calculateDirection(Party.X, Party.Y,mon.X,mon.Y)
			evt.Jump{Direction = direction, ZAngle = 128, Speed = 1000}
		end
	end
end

-- from zzMaw-Survival:309 -- no damage outside survival maps
local function pstage_survivalGatePlayer(t)
	if not survivalMaps[Map.Name] and vars.SuvivalMode then
		t.Result=0
	end
end

-- from zzMaw_Legendaries:53 -- mana shield, legendary 15 + divine protection,
-- bolster>=300 death thresholds.
--
-- Legendary 22 and the shaman/seraph cut used to be here too. They are plain
-- reductions of the hit, so they moved into calcMawDamage (zzMaw-Stats):
-- running after it left the monster tooltip and the character sheet quoting a
-- damage the player never took. What is left below all has a side effect --
-- spent SP, a healed player, a cooldown, a death -- so it cannot run from a
-- display query and has to stay in the pipeline.
local function pstage_legendariesAndShields(t)
	local id=t.Player:GetIndex()
	local pl = t.Player

	--------------------
	--MANA SHIELD CODE--
	--------------------

	t.Result = calcManaShield(pl, t.Result)
	
	---------------------
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 15) then
		if pl.Unconscious==0 and pl.Dead==0 and pl.Eradicated==0 then
			if vars.legendaryProtectionCooldown[id]==nil then
				vars.legendaryProtectionCooldown[id]=0
			end		
			if t.Result>=pl.HP and Game.Time>vars.legendaryProtectionCooldown[id] then
				--calculate healing
				for i=0,Party.High do
					if Party[i]:GetIndex()==id then
						Party[i].HP=Party[i]:GetFullHP()/4
					end
				end
				vars.legendaryProtectionCooldown[id] = Game.Time + const.Minute * 150
				Game.ShowStatusText("Legendary power saves you from lethal damage")
				t.Result=0
			end
		end
	end
	--seraphim
	if table.find(seraphClass, pl.Class) and pl.Unconscious==0 and pl.Dead==0 and pl.Eradicated==0 then
		if vars.divineProtectionCooldown[id]==nil then
			vars.divineProtectionCooldown[id]=0
		end		
		if t.Result>=pl.HP and Game.Time>vars.divineProtectionCooldown[id] then
				--calculate healing
			heal=round(GetMaxHP(pl)*0.25)
			for i=0,Party.High do
				if Party[i]:GetIndex()==id then
					evt[i].Add("HP",heal)
				end
			end
			vars.divineProtectionCooldown[id] = Game.Time + const.Minute * 150
			Game.ShowStatusText("Divine Protection saves you from lethal damage")
			t.Result=math.min(t.Result, pl.HP-1)
		end	
	end
	
	if Game.BolsterAmount>=300 then
		RunNextTick(function()
			local fullHP=pl:GetFullHP()
			local id=pl:GetIndex()
			if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 30) then
				fullHP=math.max(fullHP,pl:GetFullSP())
				fullHP=fullHP*manaShieldManaEfficiency(pl)
			end
			local currentHP=pl.HP
			if currentHP<-fullHP then
				pl.Dead=Game.Time
				pl.SP=0
			end
			if currentHP<-fullHP*2 then
				pl.Eradicated=Game.Time
			end
			if vars.insanityMode and enableDisintegrate and currentHP<-fullHP*10 and Party.Count>1 then
				for i=0,Party.High do
					if Party[i]:GetIndex()==id then
						Game.PlaySound(4833+pl.Voice*100)
						DismissCharacter(i)
						Game.ShowStatusText("Disintegrated")
						return
					end
				end
			end
		end)
	end
end

-- from zzMaw_Mapping:1 -- map affixes 1/2/10 vs the player
local function pstage_mapAffixesPlayer(t)
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

-- from zzMAWStatusMsg:4 -- remote-owner zero (solo-active MP guard)
local function pstage_remoteOwnerZeroPlayer(t)
	local source = WhoHitPlayer()
	if source then
		local obj = source.Object
		if obj and bit.And(obj.Bits, REMOTE_OWNER_BIT) > 0 then
			if not table.find(aoespellsMultiplayer, source.Spell) then
				t.Result = 0
			end
		end
	end
end

local ppipe = MawCore.Pipeline.new("DamageToPlayer", {
	-- tier 1: was General file-scope
	"item-refresh",			-- [reactions] deferred itemStats refresh
	"death-seed-mark",		-- [reactions] madness death-seed marker
	"damage-recompute",		-- [base] THE replacement (dodge, monster damage, disease, ...)

	-- tier 2: was GameInitialized2-registered
	"boss-affixes-player",	-- [reactions] boss on-hit effects
	"survival-gate",		-- [gates]
	-- tier 3: was Global file-scope
	"legendaries-and-shields",	-- [mult/reactions] incl. mana shield + divine protection
	"map-affixes-player",	-- [mult]
	"remote-owner-zero",	-- [gates] solo-active MP guard
})

ppipe:on("item-refresh",        "zzMaw-Items:3595",      pstage_itemRefresh)
ppipe:on("death-seed-mark",     "zzMaw-Monsters:2552",   pstage_deathSeedMark)
ppipe:on("damage-recompute",    "zzMaw-Stats:735",       pstage_damageRecompute)
ppipe:on("boss-affixes-player", "zzMaw-Monsters:3269",   pstage_bossAffixesPlayer)
ppipe:on("survival-gate",       "zzMaw-Survival:309",    pstage_survivalGatePlayer)
ppipe:on("legendaries-and-shields", "zzMaw_Legendaries:53", pstage_legendariesAndShields)
ppipe:on("map-affixes-player",  "zzMaw_Mapping:1",       pstage_mapAffixesPlayer)
ppipe:on("remote-owner-zero",   "zzMAWStatusMsg:4",      pstage_remoteOwnerZeroPlayer)

Damage.playerPipe = ppipe

function Damage.runPlayer(t)
	ppipe:run(t)
end
