-- Damage.lua -- the CalcDamageToMonster pipeline (see DAMAGE_PIPELINE.md).
--
-- Phase 1 of the migration: legacy handlers move here VERBATIM, one stage per
-- handler, in their original execution order (the tier model is documented in
-- DAMAGE_PIPELINE.md). The clean phase structure (context/gates/base/../clamp)
-- comes in phase 2, once everything lives in this file.
--
-- The event handler itself is registered per playthrough by
-- Scripts/Global/zzzzzMaw_Damage.lua: Global scripts re-register on every save
-- load, always appending after the remaining legacy Global handlers, so the
-- pipeline runs last among mod handlers (map scripts still run after it, as
-- they always did).
--
-- Approved deviations from verbatim (user, 2026-08-04):
--   * "friendly-fire-zero" (split out of zzMAWStatusMsg:151) runs BEFORE
--     "leech": zeroed friendly hits no longer heal through leech.
--   * (queued for the tier-1 batch) the Seraph dual-wield zero must actually
--     stick; long-term it becomes a canEquip restriction instead.
--
-- Stage bodies call legacy globals (damageMultiplier, lifeLeech, HPtable,
-- getCritInfo, checkSkills, ...) on purpose -- those migrate in later passes.
--
-- Phase 2 (2026-08-04, order-preserving consolidation): stage bodies are no
-- longer strictly byte-verbatim -- two mechanical rewrites were applied:
--   * every `... = WhoHitMonster()` became `... = t.Hit`, resolved once by the
--     new "context" stage (WhoHitMonster is stable for the whole event);
--   * the six duplicated two-dice weapon rolls became rollDice(lo, hi).
-- Physical re-bucketing into the phase taxonomy is deliberately NOT done:
-- each such move changes execution order and needs its own equivalence
-- argument. The [phase] tags on the stage list mark where each stage would
-- land. Cross-stage globals still in use: `crit` (set by the recompute/class
-- stages, read by track-and-clamp; note it is never reset to false -- legacy
-- behavior kept), `divide`, `coverBonus`, the reflect flags.

local Damage = {}
MawCore.Damage = Damage

-- also still defined in zzMAWStatusMsg.lua, whose CalcDamageToPlayer stays
local REMOTE_OWNER_BIT = 0x800

-- ===========================================================================
-- Shared helpers (phase 2) -- one source for ideas duplicated across stages.
-- ===========================================================================

-- the mod's standard weapon damage roll: average of two dice
local function rollDice(lo, hi)
	return round((math.random(lo, hi) + math.random(lo, hi))/2)
end

-- the standard resistance mitigation: halved per 100 res (callers pass the
-- already-%1000-reduced value where the bolster thousands must be stripped)
local function resDivide(damage, res)
	return damage / 2^(res/100)
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
-- instead of calling it again (the bodies' `data` locals now alias t.Hit).
local function stage_context(t)
	t.Hit = WhoHitMonster()
end

-- ===========================================================================
-- Stage bodies, byte-verbatim from the legacy files (source noted per stage).
-- ===========================================================================

-- --- Tier 1 (General file-scope) -- migrated 2026-08-04, batch 3 -----------
-- The earliest-registered handlers (General file load order, case-insensitive
-- alphabetical). With this batch the whole chain lives in the pipeline; the
-- four Multiplayer sync handlers are the only mod handlers left running BEFORE
-- it (they used to run after this tier -- solo play is unaffected, MP damage
-- sync is descoped; see DAMAGE_PIPELINE.md).

-- from Scripts/General/zzClasses.lua:255 -- Seraph melee on-hit heal to the
-- lowest party member (online-aware), healing-done tracking
local function stage_seraphOnHitHeal(t)
	if t.Result==0 then return end
	local data = t.Hit
		if data and data.Player and (data.Player.Class==55 or data.Player.Class==54 or data.Player.Class==53) and t.DamageKind==4 and data.Object==nil then
		local pl=data.Player
		local partyHP=partyHPSum()

		--get body
		bodyS,bodyM=SplitSkill(pl.Skills[const.Skills.Body])

		--Calculate heal value and apply
		healValue=(bodyS^1.3*bodyM*2)*damageMultiplier[t.PlayerIndex]["Melee"]
		personality=pl:GetPersonality()
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

-- from Scripts/General/zzClasses.lua:357 -- Seraph dual-wield ban. Registered
-- as the "seraph-dual-wield" stage AFTER res-and-retaliation (approved fix:
-- legacy load order let later handlers overwrite this zero, so the ban never
-- worked; long-term it becomes a canEquip restriction instead)
local function stage_seraphDualWield(t)
	if t.Player and (t.Player.Class==55 or t.Player.Class==54 or t.Player.Class==53) then
		data=t.Hit
		if data and data.Player then
			item=data.Player:GetActiveItem(0)
		end
		if item~=nil then
			if item:T().Skill==1 then
				t.Result=0
				Message("Seraphim aren't able to dual wield")
			end
		end
	end
end

-- from Scripts/General/zzClasses.lua:1534 (original numbering) -- Elementalist
-- learn-by-casting progression (spellRequirements stays global in zzClasses,
-- the tooltip code reads it too; the masteryRequired local moved along)
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
		school2=(school-12)*11
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

-- from Scripts/General/zzClasses.lua:1649 (original numbering) -- Elementalist:
-- melee/arrow hits reset concentration stacks
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
		local res=t.Monster.Resistances[4]%1000
		local damage=round(resDivide(damage, res))
		t.Result=damage
	end
end

-- from Scripts/General/zzMAW-Skills.lua:2248 -- Cover GM flag (read by the
-- cover redirect logic in zzMAW-Skills/zzMaw-Monsters; init stays there)
local function stage_coverFlag(t)
	data = t.Hit	
	if data and data.Player and t.DamageKind==4 then
		if data.Object==nil then
			local s, m=SplitSkill(Skillz.get(data.Player,50))
			if m>=4 then
				local slot=slotByIndex(t.PlayerIndex)
				if slot then
					coverBonus[slot]=true
				end
			end
		end
	end
end

-- from Scripts/General/zzMAW-Skills.lua:2393-2436 -- mace M/GM stun/paralyze
-- roll (the maceStunCC local moved along -- it had no other consumer)
--mace stun
local maceStunCC = {Debuff = const.MonsterBuff.Paralyze}
local function stage_maceStun(t)
	if t.Player then
		local it=t.Player:GetActiveItem(1)
		if not it then return end
		local skill=it:T().Skill
		local data=t.Hit
		if skill==6 and t.DamageKind==4 and data and data.Object==nil then
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Mace))
			if m>=3 then
				local mon=t.Monster
				--get Level
				local id=t.MonsterIndex
				local lvl=getMonsterLevel(mon)
				--chance to paralyze
				local chance=s/lvl^0.65*0.15*damageMultiplier[t.Player:GetIndex()].Melee/math.min(1+lvl/150,3)
				local applyParalyze=applyParalyze or {}
				applyParalyze[id]=false
				local previousDuration=mon.SpellBuffs[6].ExpireTime
				local duration=0
				if chance>math.random() then
					applyParalyze[id]=true
					duration=const.Minute*3
					if m==3 then
						duration=duration/2
					end
					-- Apply diminishing returns
					duration = calcDebuffDuration(mon, maceStunCC, duration)
				end
				RunNextTick(function()
					if applyParalyze[id] and duration > 0 then
						if mon.HP~=0 then
							mon.SpellBuffs[6].ExpireTime=Game.Time+duration
						end
						applyParalyze[id]=false
					else
						mon.SpellBuffs[6].ExpireTime=previousDuration
					end
				end)
			end
		end
	end
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
		data=t.Hit
		flyTime=Party.SpellBuffs[7].ExpireTime
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
		if getMapAffixPower(13) then
			hit=hit*(1-getMapAffixPower(13)/100)
		end
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
-- by bolster tier (the massHPMULT local moved along -- no other consumer)
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
			monsterIndex=getClosestMonsterInRange(t.Monster,768)
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

  t.Result = damage * (dmgMult or 1)


  local critChance, critMult, success = getCritInfo(pl, false, safeGetMonsterLevel(t.Monster))
  if success then
    t.Result = t.Result * critMult
	crit=true
  end

  if data.Player.Weak and data.Player.Weak > 0 then
    t.Result = t.Result * 0.5
  end
  if data.Object and data.Object.Spell == 133 and data.Object.Item and data.Object.Item.Bonus2 == 3 then
    t.Result = t.Result * 0.25
  end
end

-- from Scripts/General/zzMaw-Stats.lua:770 -- pain-reflection flag dance
-- (pairs with the CalcDamageToPlayer handler still in zzMaw-Stats; the
-- painReflectionHit init also stays there)
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
					if m==4 then
						res=math.min(t.Monster.Resistances[0]%1000, t.Monster.Resistances[4])
					end
				end
			end
		end
	end
	if t.Result==0 then return end
	if not res then res=0 end
	res=res%1000
	--spear reduction
	if t.Player and data and data.Object==nil and t.DamageKind==4 then
		local it=t.Player:GetActiveItem(1)
		if it then 
			local skill=it:T().Skill
			if skill==const.Skills.Spear then
				local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Spear))
				if m==4 then
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
	if t.Player and vars.legendaries and vars.legendaries[t.PlayerIndex] and table.find(vars.legendaries[t.PlayerIndex], 29) then
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


-- --- Tier 2 (GameInitialized2-registered) -- migrated 2026-08-04, batch 2 ---
-- These ran after every tier-1 (General file-scope) handler and before Global.
-- The four Multiplayer sync handlers of the same tier stay in place, so they
-- keep running before the pipeline, exactly as they always did.
-- Bodies verbatim minus one leading tab (they were nested in their wrappers).

-- from Scripts/General/zzClasses.lua:855 -- Dragon full damage replacement:
-- melee (fang knockback, SP gain for classes 10/11, own res division) and
-- breath/spell-123 ranged (crit, min-res pick, randomized spread)
local function stage_dragonAttack(t)
	data=t.Hit
	if data and data.Player and Game.CharacterPortraits[data.Player.Face].Race==const.Race.Dragon then
		local pl=data.Player
		if data.Object==nil then
			local breath = SplitSkill(data.Player:GetSkill(const.Skills.DragonAbility))
			local fang, fangM = SplitSkill(data.Player:GetSkill(const.Skills.Unarmed))
			if breath>=fang then
				local x, y = directionToUnitVector(Party.Direction)
				push=push or {}
				mult=fang/t.Monster.Level^0.75
				table.insert(push,{["directionX"]=x, ["directionY"]=y, ["duration"]=60*mult^0.5, ["totalDuration"]=60*mult^0.5, ["totalForce"]=800*mult, ["currentForce"]=800*mult, ["id"]=t.MonsterIndex})
			end
			
			local low=pl:GetMeleeDamageMin()
			local high=pl:GetMeleeDamageMax()
			local damage=rollDice(low, high)
			
			--check by damage type
			index=table.find(damageKindMap,t.DamageKind)
			res=t.Monster.Resistances[index]
			if not res then return end
			critChance, critMult, crit=getCritInfo(pl,false,getMonsterLevel(t.Monster))
			if crit then
				damage=damage*critMult
			end
			if pl.Class==10 then
				pl.SP=math.min(pl.SP+10, 60)
			elseif pl.Class==11 then
				pl.SP=math.min(pl.SP+20, 120)
			end
			--apply Damage
			t.Result = resDivide(damage, res%1000)
		elseif t.DamageKind==50 or data.Spell==123 then
			local low=pl:GetRangedDamageMin()
			local high=pl:GetRangedDamageMax()
			local damage=rollDice(low, high)
			
			critChance, critMult, crit=getCritInfo(pl,false,getMonsterLevel(t.Monster))
			if crit then
				damage=damage*critMult
			end
			if data.Spell==123 then
				local s,m=SplitSkill(t.Player.Skills[const.Skills.DragonAbility])
				local mult=0.85
				if m<=2 then
					mult=0.7
				elseif m==4 then
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
		m6=SplitSkill(data.Player.Skills[const.Skills.Mind])
		m7,bM=SplitSkill(data.Player.Skills[const.Skills.Body])
		
		local FHP=data.Player:GetFullHP()
		local leech=math.max(round(FHP^0.5* m7^1.5/70 * (0.5+bM/2)), m7)
		local maxSP=data.Player:GetFullSP()
		data.Player.SP=math.min(data.Player.SP+m6^1.25, getMaxMana(data.Player))
		
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
-- slow/paralyze spell effects. DKDamageMult was made global for this move.
local function stage_dkAttack(t)
	local data = t.Hit
	if data and data.Player and table.find(dkClass, data.Player.Class) then
		local pl=data.Player
		local spell=0
		if data and data.Object and data.Object.Spell then
			spell=data.Object.Spell
		end
		if DKDamageMult[spell] then
			--add physical damage to spells
			baseDamage=pl:GetMeleeDamageMin()
			maxDamage=pl:GetMeleeDamageMax()
			damage=rollDice(baseDamage, maxDamage)
			
			critChance, critMult, success=getCritInfo(pl,false,getMonsterLevel(t.Monster))
			if success then
				damage=damage*critMult
				crit=true
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
			damage=resDivide(damage, res%1000)
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
			local heal=FHP*(bloodS/round(monLvl^0.7))*0.05
			--current active leech spell
			vars.dkActiveAttackSpell=vars.dkActiveAttackSpell or {}
			local id=pl:GetIndex()
			leech=0
			if vars.dkActiveAttackSpell and (vars.dkActiveAttackSpell[id]==68 or vars.dkActiveAttackSpell[id]==74) then
				local FHP=pl:GetFullHP()
				local leech=math.max(FHP^0.5* bloodS^1.5/70* (1+bloodM/4), bloodS*2)
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
			
			--dark grasp
			if vars.dkActiveAttackSpell and vars.dkActiveAttackSpell[id]==96 then
				pl.SP=pl.SP-15
				local darkGraspCC = {Debuff = const.MonsterBuff.DamageHalved}
				local graspDuration = calcDebuffDuration(t.Monster, darkGraspCC, const.Minute)
				if graspDuration > 0 then
					t.Monster.SpellBuffs[const.MonsterBuff.DamageHalved].ExpireTime=math.max(t.Monster.SpellBuffs[const.MonsterBuff.DamageHalved].ExpireTime, Game.Time+graspDuration)
					local s, m=SplitSkill(pl.Skills[const.Skills.Dark])
					if m==4 then
						t.Monster.SpellBuffs[const.MonsterBuff.MeleeOnly].ExpireTime=math.max(t.Monster.SpellBuffs[const.MonsterBuff.MeleeOnly].ExpireTime, Game.Time+graspDuration)
					end
				end
			end
			--restore SP
			if t.DamageKind==4 then
				local regen=spRegen[pl.Class]
				if t.Result>t.Monster.HP then
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
			local damage=rollDice(baseDamage, maxDamage)
			
			local isolatedDamageReduction=assassinationDamage(pl,t.Monster,data.Object) --must be subtracted
			damage=damage-isolatedDamageReduction
			
			critChance, critMult, success=getCritInfo(pl,false,getMonsterLevel(t.Monster))
			if success then
				damage=damage*critMult
				crit=true
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
			damage=resDivide(damage, res%1000)
			local mult=damageMultiplier[t.PlayerIndex]["Melee"]
			t.Result=damage*mult
			
			if pl.Weak>0 then
				t.Result=t.Result*0.5
			end
			
			if assassinSpells[spell].DamageMult then
				t.Result=t.Result*assassinSpells[data.Object.Spell].DamageMult
				if spell==44 then
					local res=t.Monster.Resistances[3]%1000
					t.Result=resDivide(t.Result, res)
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

-- from Scripts/General/zzMaw-Survival.lua:316 -- survival mode: zero all damage
-- outside survival maps. survivalMaps was made global for this move.
local function stage_survivalGate(t)
	if not survivalMaps[Map.Name] and vars.SuvivalMode then
		t.Result=0
	end
end

-- --- Tier 3 (Global) -- migrated 2026-08-04, batch 1 ------------------------

-- from Scripts/Global/zzMaw_Legendaries.lua:22 -- enchant/fire-aura flat adds,
-- legendaries 17/21/14/24/11, shaman fire + assassin water adds, shaman spell mult
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
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 17) then
		if t.Result>0 and ((data and data.Object==nil and t.DamageKind==4) or (data and data.Object)) then
			local dmg=mon.HP*0.02*2^(math.floor(mon.Resistances[0]/1000))
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
		if mon.Resistances[0]>=1000 then
			mult=2^math.floor(mon.Resistances[0]/1000)
			fireDamage=fireDamage*mult
		end
		fireDamage=math.max(mon.HP*fireDamage,s1)
		fireRes=mon.Resistances[0]%1000
		fireDamage=resDivide(fireDamage, fireRes)
		t.Result=t.Result+fireDamage
	end
	--same for assassin
	if data and pl and table.find(assassinClass, pl.Class) and t.DamageKind==4 and data.Object==nil and t.Result>0 then	
		local s1=SplitSkill(pl.Skills[const.Skills.Water])
		local waterDamage=s1*0.001
		if mon.Resistances[0]>=1000 then
			mult=2^math.floor(mon.Resistances[0]/1000)
			waterDamage=waterDamage*mult
		end
		waterDamage=math.max(mon.HP*waterDamage,s1)
		waterRes=mon.Resistances[2]%1000
		waterDamage=resDivide(waterDamage, waterRes)
		t.Result=t.Result+waterDamage
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
		t.Result=t.Result*math.min(mult,2)
	end
	--end of [17]
	--[14]="Critical chance over 100% increases total damage",
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 14) then
		local critChance=getCritInfo(pl,false,getMonsterLevel(mon))
		t.Result=math.round(t.Result*math.max(critChance,1))
	end
	--end of [14]
	--[24]="killing a Monster Restores 10% of Health and Mana"
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 24) then
		--restoreHPLeg=true
		RunNextTick(function()
			--if restoreHPLeg then
				--restoreHPLeg=false
				if mon.HP<=0 then
					local fullHP=pl:GetFullHP()
					local fullSP=pl:GetFullSP()
					pl.HP=math.min(fullHP, pl.HP+fullHP*0.1)
					pl.SP=math.min(fullSP, pl.SP+fullSP*0.1)
				end
			--end
		end)
	end
	--end of 24
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 11) then
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
				skill=SplitSkill(pl.Skills[school])
				s=s+skill
			end
			local mult=1+s/200
			t.Result=t.Result*mult
		end
	end
	
end

-- from Scripts/Global/zzMaw_Mapping.lua:16 -- map affix damage mults/miss/reflect
local function stage_mapAffixes(t)
	if t.Player and t.DamageKind==4 and getMapAffixPower(23) then
		t.Result=t.Result*(1-getMapAffixPower(23)/100)
	end
	if t.Player and t.DamageKind~=4 and getMapAffixPower(24) then
		t.Result=t.Result*(1-getMapAffixPower(24)/100)
	end
	if t.Player and getMapAffixPower(30) then
		if math.random()<getMapAffixPower(30)/100 then
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

-- from Scripts/Global/zzMAWStatusMsg.lua:151 (first lines, split out so it runs
-- before leech -- approved deviation)
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
		if vars.legendaries and vars.legendaries[index] and table.find(vars.legendaries[index], 31) then
			fullHP=getMaxMana(pl) or 0
			manaLeechLeg=true
		end
		local baselineHeal=t.Result/refHP*fullHP --basically dealing 100% of monster B HP as damage heals you by 100%
		
		if getMapAffixPower(32) then
			baselineHeal=baselineHeal*(1-getMapAffixPower(32)/100)
		end
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
		if overHeal>0 and vars.legendaries and vars.legendaries[index] and table.find(vars.legendaries[index], 27) then
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
-- ShowDamage status message, bolster HP-inflation divide, ceil + 32500 cap
local function stage_trackAndClamp(t)
	if t.Result==0 then return end
	
	local data=t.Hit
	
	--recount
	if data and data.Player then
		local damage=t.Result
		if data.Spell==44 then
			if t.Monster.Resistances[0]>=1000 then
				damage=damage*2^math.floor(t.Monster.Resistances[0]/1000)
			end
		end
		
		if data.Object then
			track("damageTrackRanged", data.Player:GetIndex(), damage)
		else
			track("damageTrack", data.Player:GetIndex(), damage)
		end
		if ShowDamage then
			ShowDamage(data.Player, damage, crit, data.Object, t.Monster)
		end
		
	end
	
	
	divide=1
	if data and data.Spell==44 then
		if t.Monster.Resistances[0]>=1000 then
			divide=2^math.floor(t.Monster.Resistances[0]/1000)
		end
	elseif t.Monster.Resistances[0]>=1000 then
		divide=2^math.floor(t.Monster.Resistances[0]/1000)
		t.Result=t.Result/divide
	end
	if data and data.Player then
		local slot=slotByIndex(t.PlayerIndex)
		if slot then
			checkSkills(slot) --to use the correct spell name
		end
		MSGdamage=MSGdamage or 0
		MSGdamage=MSGdamage+math.ceil(t.Result*divide)
		local msgTxt=MSGdamage
		msgTxt=shortenNumber(msgTxt, 4, true)
		attackIsSpell=false
		castedAoe=false
		shoot="hits"
		critMessage= ""
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
		if t.Result>t.Monster.HP then
			shoot="inflicts"
		end
		if crit then
			critMessage=StrColor(255,255,30,"(CRIT!)")
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
		if t.Result>t.Monster.HP then
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
	t.Result=math.ceil(t.Result)
	if t.Result>32500 then
		t.Result=32500
	end
end

-- ===========================================================================
-- The pipeline. Stage order IS the damage formula -- grow this list at the
-- front as earlier tiers migrate (see DAMAGE_PIPELINE.md "Migration strategy").
-- ===========================================================================

local pipe = MawCore.Pipeline.new("DamageToMonster", {
	"context",				-- phase 2: resolve t.Hit once
	-- tier 1 (General file-scope) -- migrated 2026-08-04 (batch 3)
	"seraph-on-hit-heal",		-- [reactions]
	"elementalist-learning",	-- [reactions]
	"elementalist-stack-reset",	-- [reactions]
	"engine-reset",				-- [base] discard engine calc, start from raw damage
	"reveal-nearby",			-- [reactions]
	"monster-vs-monster",		-- [base]
	"cover-flag",				-- [reactions]
	"mace-stun",				-- [reactions]
	"stun-death-cleanup",		-- [reactions]
	"fly-removal",				-- [reactions]
	"stun-spell-prime",			-- [resistance] primes res for res-and-retaliation
	"mass-distortion",			-- [mult]
	"sparks-chain",				-- [reactions]
	"weapon-recompute",			-- [base] THE melee/ranged replacement
	"pain-reflection-flag",		-- [reactions]
	"res-and-retaliation",		-- [resistance] final / 2^(res/100)
	"seraph-dual-wield",	-- [gates] was first in tier 1 (zzClasses:357); moved after
							-- the base recompute so its zero actually sticks (approved fix)
	-- tier 2 (GameInitialized2) -- migrated 2026-08-04 (batch 2)
	"dragon-attack",			-- [base] class override
	"shaman-on-hit",			-- [reactions]
	"dk-attack",				-- [base] class override
	"assassin-attack",			-- [base] class override
	"boss-affixes",				-- [reactions]
	"survival-gate",			-- [gates]
	-- tier 3 (Global) -- migrated 2026-08-04 (batch 1)
	"legendaries",				-- [additive/mult] post-res on purpose
	"map-affixes",				-- [mult/gates]
	"remote-owner-zero",		-- [gates]
	"friendly-fire-zero",	-- [gates] ahead of leech on purpose (approved deviation)
	"leech",					-- [reactions]
	"track-and-clamp",			-- [clamp]
})

pipe:on("context",           "MawCore",              stage_context)
pipe:on("seraph-on-hit-heal", "zzClasses:255",       stage_seraphOnHitHeal)
pipe:on("elementalist-learning",    "zzClasses:1534", stage_elementalistLearning)
pipe:on("elementalist-stack-reset", "zzClasses:1649", stage_elementalistStackReset)
pipe:on("engine-reset",      "zzMaw-Monsters:2236",  stage_engineReset)
pipe:on("reveal-nearby",     "zzMaw-Monsters:4475",  stage_revealNearby)
pipe:on("monster-vs-monster","zzMaw-Monsters:4548",  stage_monsterVsMonster)
pipe:on("cover-flag",        "zzMAW-Skills:2248",    stage_coverFlag)
pipe:on("mace-stun",         "zzMAW-Skills:2395",    stage_maceStun)
pipe:on("stun-death-cleanup","zzMAW-Skills:2439",    stage_stunDeathCleanup)
pipe:on("fly-removal",       "zzMaw-Spells:973",     stage_flyRemoval)
pipe:on("stun-spell-prime",  "zzMaw-Spells:1596",    stage_stunSpellPrime)
pipe:on("mass-distortion",   "zzMaw-Spells:1823",    stage_massDistortion)
pipe:on("sparks-chain",      "zzMaw-Spells:3191",    stage_sparksChain)
pipe:on("weapon-recompute",  "zzMaw-Stats:141",      stage_weaponRecompute)
pipe:on("pain-reflection-flag", "zzMaw-Stats:770",   stage_painReflectionFlag)
pipe:on("res-and-retaliation",  "zzMaw-Stats:1105",  stage_resAndRetaliation)
pipe:on("seraph-dual-wield", "zzClasses:357",        stage_seraphDualWield)
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

Damage.pipe = pipe

function Damage.run(t)
	pipe:run(t)
end

function Damage.describe()
	return pipe:describe()
end
