local u1, u2, u4, i1, i2, i4 = mem.u1, mem.u2, mem.u4, mem.i1, mem.i2, mem.i4
local hook, autohook, autohook2, asmpatch = mem.hook, mem.autohook, mem.autohook2, mem.asmpatch
local max, min, floor, ceil, round, random = math.max, math.min, math.floor, math.ceil, round, math.random
local format = string.format
local MS = Merge.ModSettings

local mmver = offsets.MMVersion
function mmv(...)
	local r = select(mmver - 5, ...)
	assert(r ~= nil)
	return r
end

local function getPartyIndex(player)
	for i, pl in Party do
		if pl == player then
			return i
		end
	end
end

function events.KeyDown(t)
	if Game.CurrentScreen==8 and t.Key==removeBuffsKey then
		vars.mawbuff={}
		Game.ShowStatusText("All buffs have been removed")
	end
end

local function getSpellQueueData(spellQueuePtr, targetPtr)
	-- find active queue slot
	local i, foundNpc = 0 -- might be the case where there is only npc spell in queue, which makes my code error with "no active spell queue slot found"
	while i2[spellQueuePtr] == 0 or i2[spellQueuePtr + 4] == 49 do -- 49 is workaround for merge mechanism, where hireling spells are represented by 49 roster index in party index field, which causes a bug
		if i2[spellQueuePtr + 4] == 49 then
			foundNpc = true
		end
		spellQueuePtr = spellQueuePtr + 0x14
		i = i + 1
		if i >= 10 then
			if foundNpc then
				return -- no active spell queue slot found, but there is npc spell in queue, which we don't care about
			else
				error("No active spell queue slot found") -- not a single spell in queue, invalid state
			end
		end
	end
	local t = {Spell = i2[spellQueuePtr], Caster = Party.PlayersArray[i2[spellQueuePtr + 2]]}
	t.SpellSchool = ceil(t.Spell / 11)
	local flags = u2[spellQueuePtr + 8]
	if flags:And(0x10) ~= 0 then -- caster is target
		t.Caster = Party[i2[spellQueuePtr + 4]]
	end
    t.CasterIndex = getPartyIndex(t.Caster)

	if flags:And(1) ~= 0 then
		t.FromScroll = true
		t.Skill, t.Mastery = SplitSkill(u2[spellQueuePtr + 0xA])
	else
		if mmver > 6 then
			t.Skill, t.Mastery = SplitSkill(t.Caster:GetSkill(const.Skills.Fire + t.SpellSchool - 1))
		else -- no GetSkill
			t.Skill, t.Mastery = SplitSkill(t.Caster.Skills[const.Skills.Fire + t.SpellSchool - 1]) -- TODO: factor in "of X magic" rings
		end
	end

	local targetIdKey = mmv("TargetIndex", "TargetIndex", "TargetRosterId")
	if targetPtr then
		if type(targetPtr) == "number" then
			t[targetIdKey], t.Target = internal.GetPlayer(targetPtr)
		else
			t[targetIdKey], t.Target = targetPtr:GetIndex(), targetPtr
		end
	else
		local pl = Party[i2[spellQueuePtr + 4]]
		t[targetIdKey], t.Target = pl:GetIndex(), pl
	end
	return t
end

function getHealSpellMultiPlier(pl)
	local mult=1
	--crit
	local critChance, critMult, success=getCritInfo(pl,"heal")
	--heal crit disabled
	success=false
	if success then
		mult=critMult
	end
	--personality bonus for healing only
	local persBonus=pl:GetPersonality()
	local level = pl.LevelBase
	local statBonus=persBonus/math.min(1000+level*3, 4000)
	mult=mult*(1+statBonus)
	if getMapAffixPower(31) then
		mult=mult*(1-getMapAffixPower(31)/100)
	end
	return mult, success
end

-- START OF ACTUAL CHANGES --

-------------------------------------------------
------------------SPELL CHANGES------------------
-------------------------------------------------
--hour of power buff list
local hopList = {8, 9, 14, 15}

--modify Spells
function events.PlayerCastSpell(t)
	--refresh everyone before and after casting
	mawRefresh(t.PlayerIndex)
	function events.Tick() 
		events.Remove("Tick", 1)
		mawRefresh("all")
	end
	
	local partyHP=0
	for i=0,Party.High do
		if Party[i].Dead==0 and Party[i].Eradicated==0 then
			partyHP=partyHP+Party[i].HP
		end
	end
	
	local currentPl=Game.CurrentPlayer
	if table.find(assassinClass, t.Player.Class) then return end
	for i=0,Party.High do
		if Party[i]:GetIndex()==t.PlayerIndex then
			Game.CurrentPlayer=i
			ascension()
		end
	end
	Game.CurrentPlayer=currentPl
	
	if t.IsSpellScroll then -- disable for scrolls
		return
	end
	if t.Player.SP<t.SPCost then 
		return
	end
	--Invisibility
	if t.SpellId==19 then
		if Party.EnemyDetectorRed or Party.EnemyDetectorYellow then
			return
		end
		if not t.RemoteData then
			function events.Tick() 
				events.Remove("Tick", 1)
				invisCasted={true,t.Skill,t.Mastery}
				mawBuffs()
			end
			if t.MultiplayerData then
				t.MultiplayerData[1]=invisCasted
			end
		--online code
		elseif t.RemoteData then
			invisCasted=t.RemoteData[1]
			mawBuffs()
		end
	end
	
	--cure curse
	if t.SpellId==49 then
		if not t.RemoteData then
			local sp=healingSpells[49]
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Spirit))
			local baseHeal=sp.Base[m]+sp.Scaling[m]*s
			local mult, gotCrit=getHealSpellMultiPlier(t.Player)
			
			totHeal=baseHeal*mult
			if gotCrit then
				Game.ShowStatusText(string.format("You Heal for " .. round(totHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. round(totHeal) .. " Hit points"))
			end
		end
		--end of healing calculation
		if t.TargetKind == 3 then
			t.MultiplayerData[1]=round(totHeal) --total heal
			t.MultiplayerData[2]=gotCrit --crit 
		elseif t.TargetKind == 4 and t.RemoteData then
			local healData = t.RemoteData
			local name = Multiplayer.client_name(t.RemoteData.client_id)

			Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+healData[1],GetMaxHP(Party[t.TargetId]))
			if Party[t.TargetId].HP>0 then
				Party[t.TargetId].Unconscious=0
			end
			if Party.High==0 and healData[2] then
				Game.ShowStatusText(string.format(name .. " heals you for " .. healData[1] .. " hit points(crit)"))
			elseif Party.High==0 then
				Game.ShowStatusText(string.format(name .. " heals you for " .. healData[1] .. " hit points"))
			elseif	healData[2] then
				Game.ShowStatusText(string.format(name .. " heals " .. Party[t.TargetId].Name .. " for " .. healData[1] .. " hit points(crit)"))
			else
				Game.ShowStatusText(string.format(name .. " heals " .. Party[t.TargetId].Name .. " for " .. healData[1] .. " hit points"))
			end
		elseif t.TargetKind == 4 and not t.RemoteData then
			Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+round(totHeal),GetMaxHP(Party[t.TargetId]))
			if Party[t.TargetId].HP>0 then
				Party[t.TargetId].Unconscious=0
			end
		end
	end
	
	--heroism
	if t.SpellId==const.Spells.Heroism and not vars.MAWSETTINGS.buffRework=="ON" then
		if not t.RemoteData then
			t.Skill = 0
			local s,m = SplitSkill(t.Player:GetSkill(const.Skills.Spirit))
			local power = 10 + s * m/2
			local duration = Game.Time + (2 + s) * const.Hour
			if Party.SpellBuffs[9].Power <= power then
				Party.SpellBuffs[9].Power = power
				Party.SpellBuffs[9].Skill = m
				Party.SpellBuffs[9].ExpireTime= duration
			end
			if t.MultiplayerData then
				t.MultiplayerData[1]=power
				t.MultiplayerData[2]=m
				t.MultiplayerData[3]=duration
			end
		elseif t.RemoteData then
			if Party.SpellBuffs[9].Power<=	t.RemoteData[1] then
				Party.SpellBuffs[9].Power = t.RemoteData[1]
				Party.SpellBuffs[9].Skill = t.RemoteData[2]
				Party.SpellBuffs[9].ExpireTime = t.RemoteData[3]
			end
		end
	end
	--raise dead removes erad at GM
	if t.SpellId == 53 then
		if t.TargetKind == 4 and not t.RemoteData then
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Spirit))
			if m==4 then
				Party[t.TargetId].Unconscious=0
				Party[t.TargetId].Dead=0
				Party[t.TargetId].Eradicated=0
				Party[t.TargetId].HP=math.max(Party[t.TargetId].HP,1)
			end
		end
	end
	--resurrection
	if t.SpellId == 55 then
		if not t.RemoteData then
			local sp=healingSpells[55]
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Spirit))
			local baseHeal=sp.Base[m]+sp.Scaling[m]*s
			
			local mult, gotCrit=getHealSpellMultiPlier(t.Player)
			
			totHeal=baseHeal*mult

			if gotCrit then
				Game.ShowStatusText(string.format("You Heal for " .. round(totHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. round(totHeal) .. " Hit points"))
			end
		end
		--end of healing calculation
		if t.TargetKind == 3 then
			t.MultiplayerData[1]=round(totHeal) --total heal
			t.MultiplayerData[2]=gotCrit --crit 
			return
		elseif t.TargetKind == 4 and t.RemoteData then
			local healData = t.RemoteData
			local name = Multiplayer.client_name(t.RemoteData.client_id)

			Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+healData[1],GetMaxHP(Party[t.TargetId]))
			if Party[t.TargetId].HP>0 then
				Party[t.TargetId].Unconscious=0
			end
			if Party.High==0 and healData[2] then
				Game.ShowStatusText(string.format(name .. " heals you for " .. healData[1] .. " hit points(crit)"))
			elseif Party.High==0 then
				Game.ShowStatusText(string.format(name .. " heals you for " .. healData[1] .. " hit points"))
			elseif	healData[2] then
				Game.ShowStatusText(string.format(name .. " heals " .. Party[t.TargetId].Name .. " for " .. healData[1] .. " hit points(crit)"))
			else
				Game.ShowStatusText(string.format(name .. " heals " .. Party[t.TargetId].Name .. " for " .. healData[1] .. " hit points"))
			end
		elseif t.TargetKind == 4 and not t.RemoteData then
			if Party[t.TargetId].Dead>0 or Party[t.TargetId].Eradicated>0 then
				local hp=Party[t.TargetId].HP
				function events.Tick() 
					events.Remove("Tick", 1)
					Party[t.TargetId].HP=math.max(hp+round(totHeal), round(totHeal))
				end
			else
				Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+round(totHeal),GetMaxHP(Party[t.TargetId]))
				if Party[t.TargetId].HP>0 then
					Party[t.TargetId].Unconscious=0
				end
			end
		end
	end
	
	
	--lesser heal
	if t.SpellId == 68 then
		if table.find(dkClass, t.Player.Class) then return end
		if not t.RemoteData then
			local sp=healingSpells[68]
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Body))
			local baseHeal=sp.Base[m]+sp.Scaling[m]*s
			
			local mult, gotCrit=getHealSpellMultiPlier(t.Player)
			
			totHeal=baseHeal*mult

			--remove base heal
			tooltipHeal=totHeal
			totHeal=round(totHeal-(5+(m+1)*s))
			if gotCrit then
				Game.ShowStatusText(string.format("You Heal for " .. round(tooltipHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. round(tooltipHeal) .. " Hit points"))
			end
		end
		--end of healing calculation
		if t.TargetKind == 3 and t.MultiplayerData then
			t.MultiplayerData[1]=round(totHeal) --bonus heal
			t.MultiplayerData[2]=gotCrit --crit 
			t.MultiplayerData[3]=round(tooltipHeal) --total heal
			return
		elseif t.TargetKind == 4 and t.RemoteData then
			local healData = t.RemoteData
			local name = Multiplayer.client_name(t.RemoteData.client_id)

			Party[t.TargetId].HP=Party[t.TargetId].HP+healData[1]
			if Party[t.TargetId].HP>0 then
				Party[t.TargetId].Unconscious=0
			end
			if Party.High==0 and healData[2] then
				Game.ShowStatusText(string.format(name .. " heals you for " .. healData[3] .. " hit points(crit)"))
			elseif Party.High==0 then
				Game.ShowStatusText(string.format(name .. " heals you for " .. healData[3] .. " hit points"))
			elseif	healData[2] then
				Game.ShowStatusText(string.format(name .. "  heals " .. Party[t.TargetId].Name .. " for " .. healData[3] .. " hit points(crit)"))
			else
				Game.ShowStatusText(string.format(name .. " heals " .. Party[t.TargetId].Name .. " for " .. healData[3] .. " hit points"))
			end
		elseif t.TargetKind == 4 and not t.RemoteData then
			Party[t.TargetId].HP=Party[t.TargetId].HP+round(totHeal)
			if Party[t.TargetId].HP>0 then
				Party[t.TargetId].Unconscious=0
			end
		end
	end
	
	--REGENERATION
	if t.SpellId==71 and not vars.MAWSETTINGS.buffRework=="ON" then
		if not t.RemoteData then
			function events.Tick() 
				events.Remove("Tick", 1)
				regenerationCasted={true,t.Skill,t.Mastery}
				for i=0, Party.High do
					mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, mem.u4[0x75CE00]), const.Spells.Regeneration, i)
				end
				mawBuffs()
			end
			if t.MultiplayerData then
				t.MultiplayerData[1]=regenerationCasted
			end
		--online code
		elseif t.RemoteData then
			regenerationCasted=t.RemoteData[1]
			mawBuffs()
		end
	end
	
	--cure disease, reworked to greater heal
	if t.SpellId==74 then
		if table.find(dkClass, t.Player.Class) then return end
		if not t.RemoteData then
			local sp=healingSpells[74]
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Body))
			local baseHeal=sp.Base[m]+sp.Scaling[m]*s
			
			local mult, gotCrit=getHealSpellMultiPlier(t.Player)
			
			totHeal=baseHeal*mult

			if gotCrit then
				Game.ShowStatusText(string.format("You Heal for " .. round(totHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. round(totHeal) .. " Hit points"))
			end
		end
		--end of healing calculation
		if t.TargetKind == 3 then
			t.MultiplayerData[1]=round(totHeal) --total heal
			t.MultiplayerData[2]=gotCrit --crit 
			return
		elseif t.TargetKind == 4 and t.RemoteData then
			local healData = t.RemoteData
			local name = Multiplayer.client_name(t.RemoteData.client_id)

			Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+healData[1],GetMaxHP(Party[t.TargetId]))
			if Party[t.TargetId].HP>0 then
				Party[t.TargetId].Unconscious=0
			end
			if Party.High==0 and healData[2] then
				Game.ShowStatusText(string.format(name .. " heals you for " .. healData[1] .. " hit points(crit)"))
			elseif Party.High==0 then
				Game.ShowStatusText(string.format(name .. " heals you for " .. healData[1] .. " hit points"))
			elseif	healData[2] then
				Game.ShowStatusText(string.format(name .. " heals " .. Party[t.TargetId].Name .. " for " .. healData[1] .. " hit points(crit)"))
			else
				Game.ShowStatusText(string.format(name .. " heals " .. Party[t.TargetId].Name .. " for " .. healData[1] .. " hit points"))
			end
		elseif t.TargetKind == 4 and not t.RemoteData then
			Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+round(totHeal),GetMaxHP(Party[t.TargetId]))
			if Party[t.TargetId].HP>0 then
				Party[t.TargetId].Unconscious=0
			end
		end
	end
	
	--protection from Magic, no need for online code
	if t.SpellId==75 and not vars.MAWSETTINGS.buffRework=="ON" then
		local s,m = SplitSkill(t.Player:GetSkill(const.Skills.Body))
		if m==4 then
			t.Skill=10
		else
			t.Skill=math.min(t.Skill,10)
		end
	end
-- power cure
if t.SpellId == 77 then
  local totHeal, tooltipHeal, gotCrit = 0, 0, false

  if not t.RemoteData then
    -- === calcul local ===
    local sp = healingSpells and healingSpells[77] or nil
    t.Skill = 0

    local bodySkill = (t.Player and t.Player.GetSkill and t.Player:GetSkill(const.Skills.Body)) or 0
    local s, m = SplitSkill(bodySkill or 0)
    s = s or 0
    m = m or 1

    local base = (sp and sp.Base and sp.Base[m]) or 0
    local scale = (sp and sp.Scaling and sp.Scaling[m]) or 0
    local baseHeal = base + scale * s

    local multFn = (type(getHealSpellMultiPlier) == "function") and getHealSpellMultiPlier or function() return 1, false end
    local mult; mult, gotCrit = multFn(t.Player)

    local rawTotal = (baseHeal or 0) * (mult or 1)
    tooltipHeal = round(rawTotal or 0)

    -- retire le "base heal" pour rester aligné avec ton tooltip
    totHeal = round((rawTotal or 0) - (10 + 5 * s))
    if totHeal < 0 then totHeal = 0 end

    if gotCrit then
      Game.ShowStatusText("You heal the party for " .. tooltipHeal .. " hit points (crit)")
    else
      Game.ShowStatusText("You heal the party for " .. tooltipHeal .. " hit points")
    end
  end

  -- === application du soin ===
  if not t.RemoteData then
    local applyHeal = tonumber(totHeal) or 0
    if applyHeal ~= 0 then
      for i = 0, Party.High do
        -- Optionnel: clamp au max HP si dispo
        local newHP = (Party[i].HP or 0) + applyHeal
        Party[i].HP = newHP
      end
    end
    local tgt = t.TargetId
    if tgt and Party[tgt] and (Party[tgt].HP or 0) > 0 then
      Party[tgt].Unconscious = 0
    end

    if t.MultiplayerData then
      t.MultiplayerData[1] = round(applyHeal)       -- bonus heal appliqué
      t.MultiplayerData[2] = gotCrit               -- crit bool
      t.MultiplayerData[3] = round(tooltipHeal)    -- heal total affiché
    end

  else
    -- === branche Remote ===
    local healData = t.RemoteData or {}
    local applyHeal = tonumber(healData[1]) or 0
    local crit = not not healData[2]
    local shown = tonumber(healData[3]) or applyHeal

    if applyHeal ~= 0 then
      for i = 0, Party.High do
        Party[i].HP = (Party[i].HP or 0) + applyHeal
      end
    end
    local tgt = t.TargetId
    if tgt and Party[tgt] and (Party[tgt].HP or 0) > 0 then
      Party[tgt].Unconscious = 0
    end

    local name = (Multiplayer and Multiplayer.client_name and Multiplayer.client_name(healData.client_id)) or "Ally"
    if crit then
      Game.ShowStatusText(name .. " heals the party for " .. shown .. " hit points (crit)")
    else
      Game.ShowStatusText(name .. " heals the party for " .. shown .. " hit points")
    end
  end
end

	
	--Day of the Gods
	if t.SpellId==83 then
		if not t.RemoteData then
			function events.Tick() 
				events.Remove("Tick", 1)
				DoGCasted={true,t.Skill,t.Mastery}
				mawBuffs()
			end
			if t.MultiplayerData then
				t.MultiplayerData[1]=DoGCasted
			end
		--online code
		elseif t.RemoteData then
			DoGCasted=t.RemoteData[1]
			mawBuffs()
		end
	end
	--protection spells
	protectionSpells={[25]={17,14} ,[69]={1,18} ,[36]={4,15} ,[3]={6,12} ,[58]={12,17} ,[14]={0,13} } --first value is spell ID, second is school skill ID
	if protectionSpells[t.SpellId] then
		local buffId=protectionSpells[t.SpellId][1]
		if not t.RemoteData then
			t.Skill=1
			local s,m = SplitSkill(t.Player:GetSkill(protectionSpells[t.SpellId][2]))
			local power=s*math.min(m,3)
			function events.Tick()
				events.Remove("Tick", 1)
				Party.SpellBuffs[buffId].Power = power
				Party.SpellBuffs[buffId].Skill = t.Mastery
				Party.SpellBuffs[buffId].ExpireTime = Game.Time+const.Hour*s
			end
			if t.MultiplayerData then
				t.MultiplayerData[1]=power
				t.MultiplayerData[2]=Game.Time+const.Hour*s
			end
		--online code
		elseif t.RemoteData then
			Party.SpellBuffs[buffId].Power=t.RemoteData[1]
			Party.SpellBuffs[buffId].ExpireTime = t.RemoteData[2]
		end
	end
	
	--day of the gods
	if t.SpellId==85 then
		if not t.RemoteData then
			function events.Tick() 
				events.Remove("Tick", 1)
				DoPCasted={true,t.Skill,t.Mastery}
				mawBuffs()
			end
			if t.MultiplayerData then
				t.MultiplayerData[1]=DoPCasted
			end
		--online code
		elseif t.RemoteData then
			DoPCasted=t.RemoteData[1]
			mawBuffs()
		end
	end
	
	local applyHoP = function(s, m)
		--calculate some common values
		local sharedPower = s + 5 --Bless/Haste/Stoneskin power value
		local commonTime = Game.Time + const.Hour
		if m == 3 then commonTime = commonTime + s * const.Hour end --Expiration for M Bless/Shield/Stoneskin
		if m > 3 then commonTime = commonTime + 5 * s * const.Hour end --Expiration for GM Bless/Shield/Stoneskin
		
		--start with Bless
		local buffId = const.PlayerBuff.Bless
		
		for i=0,Party.High do
			if Party[i].SpellBuffs[buffId].Power <= sharedPower then
				Party[i].SpellBuffs[buffId].Power = sharedPower
				Party[i].SpellBuffs[buffId].Skill = m
				Party[i].SpellBuffs[buffId].ExpireTime = commonTime
			end
		end
		
		for _, buffId in ipairs(hopList) do
			local power = sharedPower
			local expireTime = commonTime
			
			if buffId == const.PartyBuff.Haste then
				expireTime = Game.Time + const.Hour + (m + 1) * m * Const.Minute * s
			elseif buffId == const.PartyBuff.Heroism then
				power = 10 + s -- nerf * m / 2
				expireTime = Game.Time + (2 + s * (m + 1)) * const.Hour
			end
			
			if Party.SpellBuffs[buffId].Power <= power then
				Party.SpellBuffs[buffId].Power = power
				Party.SpellBuffs[buffId].Skill = m
				Party.SpellBuffs[buffId].ExpireTime = expireTime
			end
		end
	end
	
	--Hour of Power
	if t.SpellId==const.Spells.HourOfPower then
		if not t.RemoteData then
			t.Skill = 0
			local s,m = SplitSkill(t.Player:GetSkill(const.Skills.Light))
			applyHoP(s, m)
			if t.MultiplayerData then
				t.MultiplayerData[1] = s
				t.MultiplayerData[2] = m
			end
		elseif t.RemoteData then
			applyHoP(t.RemoteData[1], t.RemoteData[2])
		end
	end
	
	local partyHP2=0
	for i=0,Party.High do
		if Party[i].Dead==0 and Party[i].Eradicated==0 then
			partyHP2=partyHP2+Party[i].HP
		end
	end
	if partyHP2>partyHP and (Party.EnemyDetectorRed or Party.EnemyDetectorYellow) then	
		local healing=partyHP2-partyHP
		local id=t.PlayerIndex
		vars.healingDone=vars.healingDone or {}
		vars.healingDone[id]=vars.healingDone[id] or 0
		vars.healingDone[id]=vars.healingDone[id] + healing
		mapvars.healingDone=mapvars.healingDone or {}
		mapvars.healingDone[id]=mapvars.healingDone[id] or 0
		mapvars.healingDone[id]=mapvars.healingDone[id] + healing
	end
end

------------------------------------------------------
--online data are processed in zzMAW-Multiplayer.lua--
------------------------------------------------------

--tick event to manually override buffs, as code seems to be unreliable (might be to recent skill limit removal
function mawBuffs()
	if DoGCasted and DoGCasted[1] then
		local power=DoGCasted[3]*5+DoGCasted[2]*DoGCasted[3]/2
		Party.SpellBuffs[2].Power = power
		Party.SpellBuffs[2].ExpireTime = Game.Time+const.Hour*DoGCasted[2]*2
		Sleep(1)
		DoGCasted[1]=false
	end
	if DoPCasted and DoPCasted[1] then
		local power=DoPCasted[2]*DoPCasted[3]/2
		--day of protection buff list
		local dopList = {0, 1, 4, 6, 12, 17}
		for i=1,#dopList do
			Party.SpellBuffs[dopList[i]].Power = power
			Party.SpellBuffs[dopList[i]].ExpireTime = Game.Time+const.Hour*DoPCasted[2]*2
		end
		Sleep(1)
		DoPCasted[1]=false
	end
	if invisCasted and invisCasted[1] then
		local m=invisCasted[3]-2
		local duration=m*15+m*invisCasted[2]
		Party.SpellBuffs[11].Power = invisCasted[2]
		Party.SpellBuffs[11].ExpireTime = Game.Time+duration*const.Minute*1.5
		Sleep(1)
		invisCasted[1]=false
	end
	if regenerationCasted and regenerationCasted[1] then
		for i=0, Party.High do
			Buff=Party[i].SpellBuffs[const.PlayerBuff.Regeneration]
			Buff.Power=0
			Buff.Skill=JoinSkill(regenerationCasted[2], regenerationCasted[3])
			Buff.ExpireTime=Game.Time+const.Hour*regenerationCasted[2]
			regenerationCasted[1]=false
		end
	end
	--refresh stats
	mawRefresh("all")
end

--invis fix for wall of mist
function events.AfterLoadMap()
	if Map.Name=="7d11.blv" and Party.X>-4698 and Party.X<2906 then
		Party.SpellBuffs[11].ExpireTime = Game.Time+const.Hour*10
	end
end

------------------------------
--Tooltips and mana cost fix--
------------------------------
function events.GameInitialized2()
	Game.SpellsTxt[18].Name="Chain Lightning"
	Game.SpellsTxt[18].Expert="Spell hits up to 2 times"
	Game.SpellsTxt[18].Master="Spell hits up to 3 times"
	Game.SpellsTxt[18].GM="Spell hits up to 4 times"

	--Invisibility
	Game.SpellsTxt[19].Master="Duration 15+1.5 minutes per point of skill"
	Game.SpellsTxt[19].GM="Duration 30+3 minutes per point of skill"
	--curse
	Game.SpellsTxt[49].Description=string.format(Game.SpellsTxt[49].Description .. "\n\nExpert has 1 hour limit per skill point, Master has 1 day per skill point, Grand has not time limit.")
	Game.SpellsTxt[49].Normal="n/a\n"
	Game.SpellsTxt[49].Expert="5 Mana cost: \ncures 12 + 2 HP per point of skill\n1 hour limit\n"
	Game.SpellsTxt[49].Master="8 Mana cost: \ncures 24 + 4 HP per point of skill\n1 day limit\n"
	Game.SpellsTxt[49].GM="16 Mana cost: \ncures 36 + 6 HP per point of skill\nno limit\n"
	
	--heroism
	Game.SpellsTxt[51].Description="Heroism increases the damage a character does on a successful attack by 10 + 1 point per point of skill in Spirit Magic. This spell affects the entire party at once.\nLasts for 2 hours plus 1 hour per point of skill"
	Game.SpellsTxt[51].Expert="Increases damage by 10 plus 1 per skill point"
	Game.SpellsTxt[51].Master="Increases damage by 10 plus 1.5 per skill point"
	Game.SpellsTxt[51].GM="Increases damage by 10 plus 2 per skill point"

	--greater heal
	Game.SpellsTxt[74].Name="Greater Heal"
	Game.SpellsTxt[74].ShortName="Greater Heal"
	Game.SpellsTxt[74].Normal="n/a\n"
	Game.SpellsTxt[74].Expert="n/a\n"
	
	--Protection from magic
	Game.SpellsTxt[75].Description="Protection from Magic affects the entire party at once, granting immunity to certain spells and monster abilities that cause debilitation conditions.  These are:  Poison, Disease, Stone, Paralyze, and Weak.  Every time this spell saves a character from an effect, it weakens.  The spell can survive 1 attack per point of skill in body magic up to 10 attacks--after that, Protection from Magic is broken."
	
	--protections
	protectionSpells={25,69,36,3,58,14}
	for _, i in ipairs(protectionSpells) do
		Game.SpellsTxt[i].GM="Effect is now passive"
	end
	--day of Gods 
	Game.SpellsTxt[83].Description="Temporarily increases all seven stats on all your characters by 1 per skill in Light Magic.  This spell lasts until you rest."
	Game.SpellsTxt[83].Expert="All stats increased by 10+1 per skill"
	Game.SpellsTxt[83].Master="All stats increased by 15+1.5 per skill"
	Game.SpellsTxt[83].GM="All stats increased by 20+2 per skill"

	--Day of the protection
	Game.SpellsTxt[85].Description="Simultaneously casts Protection from Fire, Air, Water, Earth, Mind, and Body, plus Feather Fall and Wizard Eye on all your characters at two times your skill in Light Magic."
	Game.SpellsTxt[85].Master="All spells cast at 1.5 times skill"
	Game.SpellsTxt[85].GM="All spells cast at 2 times skill"
	

	Game.SpellsTxt[114].Description="Mistform allows the vampire to reduce physical damage by 75%.  However, a vampire in Mistform cannot perform any physical attacks.  Vampires in Mistform are able to use spells and abilities and are affected by spells and abilities."

	

	--store non buff rework tooltips
	storeBaseText={}
	for i=1, Game.SpellsTxt.High do
		storeBaseText[i]=Game.SpellsTxt[i].Description
	end
end

-- shared life overflow fix
function randomizeHP()
	for i, pl in Party do
		pl.HP = random(1, GetMaxHP(pl))
	end
end


local function shouldParticipate(pl)
	if pl.Dead ~= 0 or pl.Eradicated ~= 0 or pl.Stoned ~= 0 then
		return false
	end
	if pl.HP<=0 then
		return false
	end
	return true
end
local function canParticipate(pl)
	if pl.Dead ~= 0 or pl.Eradicated ~= 0 or pl.Stoned ~= 0 then
		return false
	end
	return true
end

function doSharedLife(amount, spellQueueData)
	-- Calculate initial party HP for statistics tracking
	local initialPartyHP=0
	for i=0,Party.High do
		if canParticipate(Party[i]) then
			initialPartyHP=initialPartyHP+Party[i].HP
		end
	end
	
	local pl=spellQueueData.Caster
	local castedByPlayer=false
	local s,m
	if spellQueueData.FromScroll then
		s,m = spellQueueData.Skill, spellQueueData.Mastery
		castedByPlayer=false
	else -- could simply always use table data if it's provided, but this code gets player by CurrentPlayer, not by queue data, so leaving it for now to not change behavior unintentionally
		s,m = SplitSkill(pl:GetSkill(const.Skills.Spirit))
		castedByPlayer=true
	end
	local totHeal=healingSpells[54].Base[m]+healingSpells[54].Scaling[m]*s/2
	local gotCrit=false
	local mult=1
	if castedByPlayer then
		mult, gotCrit=getHealSpellMultiPlier(pl)
		totHeal=totHeal*mult
	end		
	if m==3 then
		totHeal=totHeal-s*3
	elseif m==4 then
		totHeal=totHeal-s*4
	end
	totHeal=math.max(totHeal, 0)
	
	if gotCrit then
		Game.ShowStatusText(string.format("Shared Life heals for " .. round(totHeal) .. " Hit points(crit)"))
	else
		Game.ShowStatusText(string.format("Shared Life heals for " .. round(totHeal) .. " Hit points"))
	end
	--calculate total HP and determine which players can safely participate
	local fullHPs = {}	
	local sortedParty = {}
	for i=0,Party.High do
		if canParticipate(Party[i]) then
			table.insert(sortedParty, {player=Party[i], index=i, hp=Party[i].HP})
		end
		fullHPs[i]=GetMaxHP(Party[i])
	end
	-- Sort from highest to lowest HP
	table.sort(sortedParty, function(a, b) return a.hp > b.hp end)
	
	-- Add players from highest to lowest, stop if total would go below 0
	local participatingPlayers = {}
	local totalHP = totHeal
	for i, entry in ipairs(sortedParty) do
		local potentialTotal = totalHP + entry.hp
		if potentialTotal >= 0 then
			table.insert(participatingPlayers, entry)
			totalHP = potentialTotal
		else
			-- Stop adding players to prevent game over
			break
		end
	end

	local healToDistribute = totalHP
	
	-- Set participating players' HP to 0 and prepare for redistribution
	for i, entry in ipairs(participatingPlayers) do
		entry.player.HP = 0
	end
	
	-- Distribute healing to participating players with overhealing redistribution
	if #participatingPlayers > 0 then
		local remaining = healToDistribute
		local maxIterations = 1000 -- Safety limit to prevent infinite loops
		local iterations = 0
		
		while remaining > 0 and iterations < maxIterations do
			iterations = iterations + 1
			local activePlayers = {}
			local minDeficit = math.huge
			
			-- Find players who still need healing
			for i, entry in ipairs(participatingPlayers) do
				local maxHP = fullHPs[entry.index]
				local deficit = maxHP - entry.player.HP
				if deficit > 0 then
					table.insert(activePlayers, entry)
					minDeficit = math.min(minDeficit, deficit)
				end
			end
			
			-- All players at full HP, stop
			if #activePlayers == 0 then break end
			
			-- Calculate how much to give each player this iteration
			local portion = math.min(minDeficit, math.floor(remaining / #activePlayers))
			if portion == 0 and remaining > 0 then
				portion = 1
			end
			
			-- Distribute the portion, collecting any overheal
			local distributed = 0
			for i, entry in ipairs(activePlayers) do
				local maxHP = fullHPs[entry.index]
				local deficit = maxHP - entry.player.HP
				local toGive = math.min(portion, deficit, remaining - distributed)
				
				if toGive > 0 then
					entry.player.HP = entry.player.HP + toGive
					distributed = distributed + toGive
					
					-- If player is now at full HP, any excess goes to others
					if entry.player.HP >= maxHP then
						entry.player.HP = maxHP
					end
				end
			end
			
			remaining = remaining - distributed
			
			if distributed == 0 then break end
		end
	end
	
	-- Wake up unconscious players who now have positive HP
	for i, entry in ipairs(participatingPlayers) do
		if entry.player.HP > 0 then
			entry.player.Unconscious = 0
		end
	end
	
	-- Calculate final party HP and track actual healing done for statistics
	local finalPartyHP=0
	for i=0,Party.High do
		if canParticipate(Party[i]) then
			finalPartyHP=finalPartyHP+Party[i].HP
		end
	end
	
	if castedByPlayer then
		if (Party.EnemyDetectorRed or Party.EnemyDetectorYellow) then	
			local actualHealing=finalPartyHP-initialPartyHP
			if actualHealing > 0 then
				local id=pl:GetIndex()
				vars.healingDone=vars.healingDone or {}
				vars.healingDone[id]=vars.healingDone[id] or 0
				vars.healingDone[id]=vars.healingDone[id] + actualHealing
				mapvars.healingDone=mapvars.healingDone or {}
				mapvars.healingDone[id]=mapvars.healingDone[id] or 0
				mapvars.healingDone[id]=mapvars.healingDone[id] + actualHealing
			end
		end
	end
	
	-- Return list of affected player objects
	local affectedPlayers = {}
	for i, entry in ipairs(participatingPlayers) do
		table.insert(affectedPlayers, entry.player)
	end
	return affectedPlayers
end


-- replace shared life code with my own
autohook(0x42A171, function(d)
	local amount = u4[d.ebp - 4]
	local t = getSpellQueueData(d.ebx)
	if not t then
		return -- no player spell, return to original code
	end
	t.Amount = amount
	events.call("HealingSpellPower", t)
	local affectedPlayers = doSharedLife(t.Amount, t)
	for i, pl in ipairs(affectedPlayers) do
		mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, u4[0x75CE00]), const.Spells.SharedLife, getPartyIndex(pl)) -- show animation
	end
	d:push(0x42C200) -- return to "cast successful" code
	return true
end)
--asmpatch(0x42A176, "jmp absolute 0x42C200")


--removes fly when attacking, except in certain maps
flyAllowedMaps={"elema.odm","elemf.odm","elemw.odm","out12.odm","outa1.odm","outa2.odm","outa3.odm","outb2.odm","outb3.odm","out05.odm"}
function events.CalcDamageToMonster(t)
	if Game.BolsterAmount>100 or vars.AusterityMode then
		if table.find(flyAllowedMaps,Map.Name) then 
			return
		end
		data=WhoHitMonster()
		flyTime=Party.SpellBuffs[7].ExpireTime
		if data and data.Player and flyTime>Game.Time then
			Party.SpellBuffs[5].ExpireTime=flyTime
			Party.SpellBuffs[7].ExpireTime=0
		end
	end
end

function events.LoadMap()
	if table.find(flyAllowedMaps,Map.Name) then 
		if Game.BolsterAmount>100 then
			Sleep(5)
			Game.ShowStatusText("Fly is allowed without restrictions here")
		end
	end
end

function events.GameInitialized2()
	Game.SpellsTxt[21].Description= "Grants the power of flight to your characters!  This spell is very expensive and only works outdoors, but it is very useful.  Fly will drain one spell point every five minutes it is in use (i.e. when you aren't touching the ground).\n\nAt higher difficulties, with the exception of few places, attacking monsters will cancel the effect"
end

--WHEN GM ELEMENTAL BUFFS WILL BE GRANTED PASSIVELY
schools={12,13,14,15,17,18}
buffsOrdered = {6, 0, 17, 4, 12, 1}
schoolToBuff={
	[12]=17,
	[13]=21,
	[14]=18,
	[15]=16,
	[16]=15,
	[17]=20,
	[18]=19,
}

function elementalBuffs()
	if not vars.MAWSETTINGS.buffRework=="ON" then
		--buffs to apply
		for i=0, Party.High do
			local pl=Party[i]
			if not table.find(dkClass,pl.Class) then
				for v=1,6 do
					local s,m=SplitSkill(pl:GetSkill(schools[v]))
					if m==4 then
						local power=s*3
						if Party.SpellBuffs[buffsOrdered[v]].Power<=s*3 then
							if Party.SpellBuffs[buffsOrdered[v]].Power<=power then
								Party.SpellBuffs[buffsOrdered[v]].ExpireTime=Game.Time+const.Hour
								Party.SpellBuffs[buffsOrdered[v]].Power=s*3
								Party.SpellBuffs[buffsOrdered[v]].Skill=4
							end
						end
					end
				end
				--stats bonus
				for key, value in pairs(schoolToBuff) do
					local s,m=SplitSkill(pl:GetSkill(key))
					if m==4 then
						local power=s*3
						for k=0, Party.High do
							if Party[k].SpellBuffs[value].Power<=s*3 then
								Party[k].SpellBuffs[value].Power=s*3
								Party[k].SpellBuffs[value].ExpireTime=Game.Time+const.Hour
								Party[k].SpellBuffs[value].Skill=0
							end
						end
					end
				end
			end
		end
		--vampire night preservation
		local race=Game.CharacterPortraits[pl.Face].Race
		if race==const.Race.Vampire then
			local hour=Game.Time%const.Day/const.Hour
			if (hour>21 or hour<5 or  Map.IndoorOrOutdoor==1) and Map.Name~="7d25.blv" then
				pl.SpellBuffs[const.PlayerBuff.Preservation].ExpireTime=math.max(Game.Time+const.Minute*5, pl.SpellBuffs[const.PlayerBuff.Preservation].ExpireTime)
			end
		end
		if Party.High==0 then
			Party.SpellBuffs[19].ExpireTime=math.max(Game.Time+const.Hour, Party.SpellBuffs[19].ExpireTime)
			Party.SpellBuffs[19].Power=math.max(10,Party.SpellBuffs[19].Power)
			Party.SpellBuffs[19].Skill=math.max(2,Party.SpellBuffs[19].Skill)
			Party.SpellBuffs[16].ExpireTime=math.max(Game.Time+const.Hour, Party.SpellBuffs[16].ExpireTime)
			Party.SpellBuffs[16].Power=math.max(2,Party.SpellBuffs[16].Power)
			Party.SpellBuffs[16].Skill=math.max(1,Party.SpellBuffs[16].Skill)
		end
	end
end

--let town portal scroll to be reused if solo
function events.PlayerCastSpell(t)
	if Party.High==0 and t.IsSpellScroll then
		if t.SpellId==31 then
			evt.Add("Items",330)
		elseif t.SpellId==33 then
			evt.Add("Items",332)
		elseif t.SpellId==16 then
			evt.Add("Items",315)
		elseif t.SpellId==21 then
			evt.Add("Items",320)
			Party.SpellBuffs[7].Caster=50
			Party.SpellBuffs[7].Skill=4
			Party.SpellBuffs[7].Power=0
			Party.SpellBuffs[7].Bits=1
			Party.SpellBuffs[7].ExpireTime=Game.Time+const.Hour*7
			t.Handled=true
			t.Player:SetRecoveryDelay(120)
		elseif t.SpellId==27 then
			evt.Add("Items",326)
		end
	end
end


---------------------------
----end OF SPELL REWORK----
---------------------------
--[[allow for spells to be learned freely in horizontal moderately
function events.CanLearnSpell(t)
	if Game.freeProgression then
		if t.Player.Spells[t.Spell] then
			return
		end
		local school=math.floor(t.Spell/11)+12
		if t.Player.Skills[school]>0 then
			vars.horizontaSpells=vars.horizontaSpells or {}
			vars.horizontaSpells[t.PlayerIndex]=vars.horizontaSpells[t.PlayerIndex] or {}
			vars.horizontaSpells[t.PlayerIndex][t.Spell]=true
			t.Player.Spells[t.Spell]=true
			Mouse.Item.Number=0
		end
	end
end
]]


masteryName={"Normal", "Expert", "Master", "GM",[0]="Normal"}

function processAutoTargetHeal(spellId, pl, skillType, soundId, removeConditionFunc)
	local sp=healingSpells[spellId]
	local s,m=SplitSkill(pl:GetSkill(skillType))
	local cost=Game.Spells[spellId]["SpellPoints" .. masteryName[m]]
	
	local baseHeal=sp.Base[m]+sp.Scaling[m]*s
	local mult, gotCrit=getHealSpellMultiPlier(pl)
	totHeal=baseHeal*mult
	
	-- Show status message
	if gotCrit then
		Game.ShowStatusText(string.format("You Heal for " .. round(totHeal) .. " Hit points(crit)"))
	else
		Game.ShowStatusText(string.format("You Heal for " .. round(totHeal) .. " Hit points"))
	end

	min_index = pickLowestPartyMember()
	
	-- Calculate overheal
	local hpBefore = Party[min_index].HP
	local maxHP = GetMaxHP(Party[min_index])
	local missingHP = maxHP - hpBefore
	local overheal = math.max(0, totHeal - missingHP)
	
	-- Deduct mana
	pl.SP=pl.SP-cost
	
	-- Apply heal
	mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, mem.u4[0x75CE00]), const.Spells.Heal, min_index)
	Party[min_index].HP=math.min(Party[min_index].HP+totHeal, maxHP)
	
	-- Bug fix
	if Party[min_index].HP>0 then
		Party[min_index].Unconscious=0
	end
	
	-- Remove specific conditions (if provided)
	if removeConditionFunc then
		removeConditionFunc(min_index)
	end
	
	-- [34] Overhealing refunds mana
	local overhealPercent = 0
	local id = pl:GetIndex()
	if overheal > 0 and vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 34) then
		overhealPercent = overheal / totHeal
		local manaRefund = math.floor(cost * overhealPercent)
		pl.SP = pl.SP + manaRefund
	end
	
	-- Calculate and apply recovery delay
	local delay=getSpellDelay(pl,spellId)
	-- [35] Overhealing reduces recovery time equal to half overhealing amount
	if overheal > 0 and vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 35) then
		if overhealPercent == 0 then
			overhealPercent = overheal / totHeal
		end
		delay = math.floor(delay * (1 - (overhealPercent / 2)))
	end
	pl:SetRecoveryDelay(delay)
	
	-- Effects
	evt.PlaySound(soundId)
	pl.Expression=40
	Party.SpellBuffs[11].ExpireTime=0 --invisibility
end

local notEnoughManaShown = false

local function checkManaForSpell(pl, spellId, skillType)
	local s,m=SplitSkill(pl:GetSkill(skillType))
	local cost=Game.Spells[spellId]["SpellPoints" .. masteryName[m]]
	if pl.SP<cost then
		if not notEnoughManaShown then
			notEnoughManaShown = true
			DoGameAction(23,0,0)
		end
		return false
	end
	return true
end

function events.Action(t)
	if t.Action==25 and autoTargetHeals then
		notEnoughManaShown = false
		ascension()
		if Game.CurrentPlayer<0 or Game.CurrentPlayer>Party.High then return end
		local pl=Party[Game.CurrentPlayer]
		local spellCast=0
		if t.Param==0 then
			spellCast=pl.QuickSpell
		elseif t.Param==1 then
			spellCast=pl.AttackSpell
		end
		--spellCast=ExtraQuickSpells.SpellSlots[pl:GetIndex()][1] might turn useful later
		
		if table.find(dkClass, Party[Game.CurrentPlayer].Class) then return end
		
		local partyHP=0
		for i=0,Party.High do
			if Party[i].Dead==0 and Party[i].Eradicated==0 then
				partyHP=partyHP+Party[i].HP
			end
		end
		
		if spellCast==55 and pl.RecoveryDelay==0 then
			if not checkManaForSpell(pl, 74, const.Skills.Body) then return end
			t.Handled=true
			Party[idx].HP=math.max(Party[idx].HP,1)
			processAutoTargetHeal(74, pl, const.Skills.Body, 16070, function(idx)
				Party[idx].Dead=0
				Party[idx].Eradicated=0
			end)
		elseif spellCast==68 and pl.RecoveryDelay==0 then
			if not checkManaForSpell(pl, 68, const.Skills.Body) then return end
			t.Handled=true
			processAutoTargetHeal(68, pl, const.Skills.Body, 16010)
		elseif spellCast==74 and pl.RecoveryDelay==0 then
			if not checkManaForSpell(pl, 74, const.Skills.Body) then return end
			t.Handled=true
			processAutoTargetHeal(74, pl, const.Skills.Body, 16070, function(idx)
				Party[idx].Disease1=0
				Party[idx].Disease2=0
				Party[idx].Disease3=0
			end)
		elseif spellCast==49 and pl.RecoveryDelay==0 then
			if not checkManaForSpell(pl, 49, const.Skills.Spirit) then return end
			t.Handled=true
			processAutoTargetHeal(49, pl, const.Skills.Spirit, 16010, function(idx)
				Party[idx].Cursed=0
			end)
		end
		local partyHP2=0
		for i=0,Party.High do
			if Party[i].Dead==0 and Party[i].Eradicated==0 then
				partyHP2=partyHP2+Party[i].HP
			end
		end
		if partyHP2>partyHP and (Party.EnemyDetectorRed or Party.EnemyDetectorYellow) then	
			local healing=partyHP2-partyHP
			local id=pl:GetIndex()
			vars.healingDone=vars.healingDone or {}
			vars.healingDone[id]=vars.healingDone[id] or 0
			vars.healingDone[id]=vars.healingDone[id] + healing
			mapvars.healingDone=mapvars.healingDone or {}
			mapvars.healingDone[id]=mapvars.healingDone[id] or 0
			mapvars.healingDone[id]=mapvars.healingDone[id] + healing
		end
	end
end



----------------------------------------
--CC REWORK
----------------------------------------
CCMAP={
	[const.Spells.Stun]=	{["Duration"]=const.Minute*2,["ChanceMult"]=0.01, ["BaseCost"]=1, ["ScalingCost"]=10},
	[const.Spells.Slow]=	{["Duration"]=const.Minute*6, ["ChanceMult"]=0.03, ["BaseCost"]=1, ["ScalingCost"]=3, ["School"]=const.Skills.Earth, ["DamageKind"]=const.Damage.Earth,["Debuff"]=const.MonsterBuff.Slow},
	[60]=					{["Duration"]=const.Minute*10, ["ChanceMult"]=0.05, ["BaseCost"]=5, ["ScalingCost"]=4, ["School"]=const.Skills.Mind, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Charm},--Mind Charm, has no const value, due to dark elf one overwriting
	[const.Spells.Charm]=	{["Duration"]=const.Minute*10, ["ChanceMult"]=0.05, ["BaseCost"]=1, ["ScalingCost"]=4, ["School"]=const.Skills.DarkElfAbility, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Charm},--dark elf one
	[const.Spells.Berserk]=	{["Duration"]=const.Minute*4.5, ["ChanceMult"]=0.04, ["BaseCost"]=1, ["ScalingCost"]=1.5, ["School"]=const.Skills.Mind, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Berserk},
	[const.Spells.MassFear]={["Duration"]=const.Minute*3, ["ChanceMult"]=0.1, ["BaseCost"]=1, ["ScalingCost"]=0.5, ["School"]=const.Skills.Mind, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Fear},
	[const.Spells.Fear]=	{["Duration"]=const.Minute*4, ["ChanceMult"]=0.005, ["BaseCost"]=1, ["ScalingCost"]=2, ["School"]=const.Skills.Mind, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Fear},
	[const.Spells.Enslave]=	{["Duration"]=const.Minute*5, ["ChanceMult"]=0.07, ["BaseCost"]=1, ["ScalingCost"]=1, ["School"]=const.Skills.Mind, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Enslave},
	[const.Spells.Paralyze]={["Duration"]=const.Minute*3, ["ChanceMult"]=0.04, ["BaseCost"]=1, ["ScalingCost"]=3, ["School"]=const.Skills.Light, ["DamageKind"]=const.Damage.Light,["Debuff"]=const.MonsterBuff.Paralyze},	
[const.Spells.ShrinkingRay]={["Duration"]=const.Minute*6, ["ChanceMult"]=0.01, ["BaseCost"]=1, ["ScalingCost"]=2, ["School"]=const.Skills.Dark, ["DamageKind"]=const.Damage.Dark,["Debuff"]=const.MonsterBuff.ShrinkingRay},
[const.Spells.DarkGrasp]=	{["Duration"]=const.Minute*10, ["ChanceMult"]=0.07, ["BaseCost"]=1, ["ScalingCost"]=3, ["School"]=const.Skills.Dark, ["DamageKind"]=const.Damage.Dark, ["Debuff"]={const.MonsterBuff.ArmorHalved, const.MonsterBuff.Slow, const.MonsterBuff.DamageHalved, const.MonsterBuff.MeleeOnly}},																									
	[const.Spells.TurnUndead]={["Duration"]=const.Minute*5, ["ChanceMult"]=0.005, ["BaseCost"]=1, ["ScalingCost"]=0.5, ["School"]=const.Skills.Spirit, ["DamageKind"]=const.Damage.Spirit, ["Debuff"]=const.MonsterBuff.Fear},	
	[const.Spells.ControlUndead]={["Duration"]=const.Minute*10, ["ChanceMult"]=0.07, ["BaseCost"]=1, ["ScalingCost"]=1.5, ["School"]=const.Skills.Dark, ["DamageKind"]=const.Damage.Dark, ["Debuff"]=const.MonsterBuff.Enslave},
}
--[[
function events.PlayerCastSpell(t)
	if CCMAP[t.SpellId] then
		t.Handled=true
		
		if t.SpellId==66 then
			local mon=Map.Monsters[Mouse:GetTarget().Index]
			BeginGrabObjects()
			Game.SummonObjects(497, mon.X,mon.Y,mon.Z+100, 0,1)
			local obj=GrabObjects()
			if obj then
				obj.Spell=66
				obj.SpellLevel=0
				obj.SpellMastery=0
				obj.SpellSkill=0
				obj.SpellType=66
				obj.TypeIndex=497
				obj.Owner=4
				obj.Visible=true
				obj.Target=3
				obj.AttachToHead=true
			end
		end
	end
end
]]
function getCCDiffMult(bolster)
	local diffMult=math.max(((bolster-100)/200)+1,1)
	if bolster==600 then 
		diffMult=3
	end
	if vars.insanityMode then
		diffMult=5
	end
	if vars.AusterityMode then
	diffMult=diffMult*2.5
	end
	return diffMult
end

function events.Action(t)
	--[[
	local id=Game.CurrentPlayer
	if id<0 or id>Party.High then return end
	local mult=getCCDiffMult(Game.BolsterAmount)
	-- Apply personality mana cost reduction
	local personalityReduction = getPersonalityManaCostReduction(Party[id])
	for key, value in pairs(CCMAP) do
		local lvl=Party[id].LevelBase
		local baseCost=value.BaseCost
		local scalingCost=value.ScalingCost
		local cost=round((baseCost+(lvl/scalingCost/3))*(1+mult*2)) --edit here to change mana cost
		local finalCost = math.ceil(cost * personalityReduction)
		Game.Spells[key]["SpellPointsNormal"]=finalCost
		Game.Spells[key]["SpellPointsExpert"]=finalCost
		Game.Spells[key]["SpellPointsMaster"]=finalCost
		Game.Spells[key]["SpellPointsGM"]=finalCost
	end
]]
	--dragon fix
	Game.Spells[122]["SpellPointsNormal"]=15
	Game.Spells[122]["SpellPointsExpert"]=15
	Game.Spells[122]["SpellPointsMaster"]=25
	Game.Spells[122]["SpellPointsGM"]=30
end

function events.PlayerCastSpell(t)
	if CCMAP[t.SpellId] then
		if t.SpellId==const.Spells.Stun then return end --stun is handled differently
		local resistance={}
		local level={}
		local prevExpireTime={} -- Record current debuff ExpireTime before cast
		local cc=CCMAP[t.SpellId]
		for i=0,Map.Monsters.High do
			local mon=Map.Monsters[i]
			local res=mon.Resistances[cc.DamageKind]
			local lvl=mon.Level
				resistance[i]=res
				level[i]=lvl
			-- Record current ExpireTime
			if type(cc.Debuff)=="table" then
				prevExpireTime[i]=mon.SpellBuffs[cc.Debuff[1]].ExpireTime
			else
				prevExpireTime[i]=mon.SpellBuffs[cc.Debuff].ExpireTime
			end
			local s,m=SplitSkill(t.Player:GetSkill(cc.School))
			local newLevel=calcEffectChance(lvl, res, s, cc.ChanceMult, mon)
			local hit=math.max(0.15,(30/(30+newLevel/4)))
			-- Pre-check if debuff duration would be > 0 (without recording history)
			local preDuration = cc.Duration
			if Party.High==0 then preDuration = preDuration*3 end
			local wouldApply = checkDebuffDuration(mon, cc, preDuration) > 0
			--if hit>math.random() then
			if wouldApply then
				mon.Resistances[cc.DamageKind]=0
				mon.Level=0
				--Game.ShowStatusText("Hit" .. "  " .. hit)
			else
				mon.Resistances[cc.DamageKind]=65000
				--Game.ShowStatusText("Miss" .. "  " .. hit)
			end
			if (t.SpellId==const.Spells.TurnUndead or t.SpellId==const.Spells.ControlUndead)and Game.IsMonsterOfKind(mon.Id, const.MonsterKind.Undead)~=1 then
				mon.Resistances[cc.DamageKind]=65000
			end
		end
				
		local reset=1
		if cc.DamageKind==const.Damage.Dark then
			reset=100
		end
		function events.Tick() 
			reset=reset-1
			if reset==0 then
				events.Remove("Tick", 1)
			end
			local mult=getCCDiffMult(Game.BolsterAmount) 
				if vars.AusterityMode then
				mult=mult*2.5
				end
			for i=0,Map.Monsters.High do
				local mon=Map.Monsters[i]
				mon.Level=level[i]
				mon.Resistances[cc.DamageKind]=resistance[i]
				-- Check if ExpireTime changed (monster was affected by this spell)
				local currentExpireTime
				if type(cc.Debuff)=="table" then
					currentExpireTime=mon.SpellBuffs[cc.Debuff[1]].ExpireTime
				else
					currentExpireTime=mon.SpellBuffs[cc.Debuff].ExpireTime
				end
				if currentExpireTime > prevExpireTime[i] then
					-- Monster was affected, apply diminishing returns
					local masteryMult = ({0.5, 0.65, 0.8, 1})[math.max(1,m)]
					local duration=cc.Duration * masteryMult
					if t.SpellId~=122 then
						local ascension = SplitSkill(t.Player:GetSkill(const.Skills.Learning))
						duration=duration*1.015^ascension/(1+resistance[i]/100)
					end
					if Party.High==0 then
						duration=duration*2
					end
					local finalDuration = calcDebuffDuration(mon, cc, duration)
					if type(cc.Debuff)=="table" then
						for v =1,#cc.Debuff do 
							mon.SpellBuffs[cc.Debuff[v]].ExpireTime=math.min(mon.SpellBuffs[cc.Debuff[v]].ExpireTime, Game.Time+finalDuration)
						end
					else
						mon.SpellBuffs[cc.Debuff].ExpireTime=math.min(mon.SpellBuffs[cc.Debuff].ExpireTime, Game.Time+finalDuration)
					end
				end
			end
		end
	end
end

-- Debuff Groups for diminishing returns
-- Group 1: Slow/Damage reduction
-- Group 2: Fear/Charm/Control
-- Group 3: Stuns
function events.GameInitialized2()
	debuffGroups = {
	[const.MonsterBuff.Slow] = 1,
	[const.MonsterBuff.ArmorHalved] = 1,
	[const.MonsterBuff.DamageHalved] = 1,
	[const.MonsterBuff.MeleeOnly] = 1,
	[const.MonsterBuff.ShrinkingRay] = 1,
	[const.MonsterBuff.Fear] = 2,
	[const.MonsterBuff.Charm] = 2,
	[const.MonsterBuff.Berserk] = 2,
	[const.MonsterBuff.Enslave] = 2,
	[const.MonsterBuff.Paralyze] = 3,
}
end

-- Tracks CC history per monster: ccHistory[monsterIndex][group] = {{startTime, endTime}, ...} 
local CC_WINDOW = 10 * const.Minute -- 30 seconds in game time
function events.LoadMap()
	mapvars.ccHistory = mapvars.ccHistory or {}
end
function events.LeaveMap()
	mapvars.ccHistory=nil
end
function getMonsterCCRatio(monsterIndex, group)
	if not mapvars.ccHistory[monsterIndex] or not mapvars.ccHistory[monsterIndex][group] then
		return 0
	end
	local now = Game.Time
	local windowStart = now - CC_WINDOW
	local totalCCTime = 0
	local history = mapvars.ccHistory[monsterIndex][group]
	-- Clean old entries and calculate CC time in window
	local newHistory = {}
	for i, entry in ipairs(history) do
		local startTime = math.max(entry.startTime, windowStart)
		local endTime = math.min(entry.endTime, now)
		if endTime > windowStart then
			totalCCTime = totalCCTime + math.max(0, endTime - startTime)
			if entry.endTime > windowStart then
				table.insert(newHistory, entry)
			end
		end
	end
	mapvars.ccHistory[monsterIndex][group] = newHistory
	return totalCCTime / CC_WINDOW
end

-- Get duration multiplier based on CC ratio thresholds
local function getCCDurationMult(ccRatio)
	if ccRatio >= 0.6 then
		return 0
	elseif ccRatio >= 0.45 then
		return 0.25   
	elseif ccRatio >= 0.3 then
		return 0.5 
	elseif ccRatio >= 0.15 then
		return 0.75  
	else
		return 1 
	end
end

-- Check-only version: calculates duration WITHOUT recording history
function checkDebuffDuration(monster, cc, duration)
	local monsterIndex = monster:GetIndex()
	local debuffList = cc.Debuff
	if type(debuffList) ~= "table" then
		debuffList = {debuffList}
	end
	
	local group = debuffGroups[debuffList[1]] or 1
	if group==1 then
		return duration
	end
	local ccRatio = getMonsterCCRatio(monsterIndex, group)
	return duration * getCCDurationMult(ccRatio)
end

-- Full version: calculates duration AND records history
function calcDebuffDuration(monster, cc, duration)
	local monsterIndex = monster:GetIndex()
	local debuffList = cc.Debuff
	if type(debuffList) ~= "table" then
		debuffList = {debuffList}
	end
	
	-- Find which group this CC belongs to
	local group = debuffGroups[debuffList[1]] or 1
	if group==1 then
		return duration
	end
	-- Calculate diminishing returns based on CC ratio
	local ccRatio = getMonsterCCRatio(monsterIndex, group)
	local durationMult = getCCDurationMult(ccRatio)
	
	-- If immune, return 0 without recording
	if durationMult == 0 then
		return 0
	end
	
	local finalDuration = duration * durationMult
	
	-- Record this CC application
	mapvars.ccHistory[monsterIndex] = mapvars.ccHistory[monsterIndex] or {}
	mapvars.ccHistory[monsterIndex][group] = mapvars.ccHistory[monsterIndex][group] or {}
	table.insert(mapvars.ccHistory[monsterIndex][group], {
		startTime = Game.Time,
		endTime = Game.Time + finalDuration
	})
	
	if mon.NameId>=220 and mon.NameId<300 then
		return finalDuration/2
	end
	return finalDuration
end

--stun code
function events.CalcDamageToMonster(t)
	local data=WhoHitMonster()
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
		function events.Tick() 
			events.Remove("Tick", 1)
			mon.Level=lvl
			mon.Resistances[const.Skills.Earth]=res
		end
	end
end


function calcEffectChance(lvl, res, skill, chance, mon)
	totRes=lvl/4+res
	mult=(1+skill*chance)
	newRes=(totRes+30)/mult-30
	newLevel=math.max(round(newRes*4),0)
	--nerfed cc effects on bosses
	if mon.NameId>=220 and mon.NameId<300 then
		newLevel=newLevel*2
	end
	return newLevel
end
------------------------------
------MANA COST CHANGE--------
------------------------------

--spell cost increase dictionary
function events.GameInitialized2()
	spellCost={}
	for i=1,132 do
		spellCost[i]={}
		for v=1,4 do
			spellCost[i][masteryName[v]] = Game.Spells[i]["SpellPoints" .. masteryName[v]]
		end
	end
	--vampire
	spellCost[111][masteryName[3]]=10
	spellCost[111][masteryName[4]]=15
	
	--chain lighning
	spellCost[18][masteryName[3]]=20
	spellCost[18][masteryName[4]]=30
	
	
	spells={2,6,7,8,9,10,11,15,18,20,22,24,26,29,32,37,39,41,43,44,52,59,65,70,76,78,79,84,87,90,93,97,98,99,103,111,123}
	lastIndex=-1 --used later

	--if you change diceMin or values that are 0 remember to update the tooltip manually 
	spellPowers =
		{
			[2] = {dmgAdd =8, diceMin = 1, diceMax = 2, },--fire bolt
			[6] = {dmgAdd = 0, diceMin = 1, diceMax = 8, },--fireball
			[7] = {dmgAdd = 0, diceMin = 1, diceMax = 10, },--fire spike, the only spell with damage depending on mastery, fix in events.calcspelldamage
			[8] = {dmgAdd = 10, diceMin = 1, diceMax = 30, },--immolation
			[9] = {dmgAdd = 2, diceMin = 1, diceMax = 1, },--meteor shower
			[10] = {dmgAdd = 12, diceMin = 1, diceMax = 7, },--inferno
			[11] = {dmgAdd = 19, diceMin = 1, diceMax = 21, },--incinerate
			[15] = {dmgAdd = 0, diceMin = 1, diceMax = 4, },--sparks
			[18] = {dmgAdd = 12, diceMin = 1, diceMax = 8, },--lightning bolt
			[20] = {dmgAdd = 20, diceMin = 1, diceMax = 12, },--implosion
			[22] = {dmgAdd = 7, diceMin = 1, diceMax = 1, },--starburst
			[24] = {dmgAdd = 5, diceMin = 1, diceMax = 3, },--poison spray
			[26] = {dmgAdd = 6, diceMin = 1, diceMax = 7, },--ice bolt
			[29] = {dmgAdd = 4, diceMin = 1, diceMax = 14, },--acid burst
			[32] = {dmgAdd = 6, diceMin = 1, diceMax = 6, },--ice blast
			[37] = {dmgAdd = 8, diceMin = 1, diceMax = 5, },--deadly swarm
			[39] = {dmgAdd = 7, diceMin = 1, diceMax = 7, },--blades
			[41] = {dmgAdd = 8, diceMin = 1, diceMax = 8, },--rock blast
			[43] = {dmgAdd = 4, diceMin = 1, diceMax = 2, },--death blossom
			[44] = {dmgAdd = 15, diceMin = 0.5, diceMax = 0.5, },--mass distorsion, nerfed
			[52] = {dmgAdd = 20, diceMin = 2, diceMax = 16, },--spirit lash
			[59] = {dmgAdd = 12, diceMin = 1, diceMax = 6, },--mind blast
			[65] = {dmgAdd = 25, diceMin = 1, diceMax = 25, },--psychic shock
			[70] = {dmgAdd = 4, diceMin = 1, diceMax = 4, },--harm
			[76] = {dmgAdd = 20, diceMin = 1, diceMax = 5, },--flying fist
			[78] = {dmgAdd = 12, diceMin = 1, diceMax = 2, },--light bolt
			[79] = {dmgAdd = 45, diceMin = 1, diceMax = 45, },--destroy undead
			[84] = {dmgAdd = 30, diceMin = 2, diceMax = 6, },--prismatic light
			[87] = {dmgAdd = 60, diceMin = 1, diceMax = 60, },--sunray
			[90] = {dmgAdd = 15, diceMin = 1, diceMax = 9, },--toxic cloud
			[93] = {dmgAdd = 0, diceMin = 1, diceMax = 7, },--shrapmetal
			[97] = {dmgAdd = 0, diceMin = 1, diceMax = 28, },--dragon breath
			[98] = {dmgAdd = 50, diceMin = 1, diceMax = 1, },--armageddon
			[99] = {dmgAdd = 25, diceMin = 1, diceMax = 5, },--souldrinker
			[201] = {dmgAdd = 25, diceMin = 1, diceMax = 5, },--souldrinker, needed for LEECH FIX
			[103] = {dmgAdd = 46, diceMin = 1, diceMax = 28, },--darkfire bolt
			[111] = {dmgAdd = 0, diceMin = 1, diceMax = 22, },--lifedrain scales with mastery, fixed in calcspelldamage
			[200] = {dmgAdd = 0, diceMin = 1, diceMax = 22, },--lifedrain scales with mastery, fixed in calcspelldamage, needed for LEECH FIX
			[123] = {dmgAdd = 0, diceMin = 1, diceMax = 25, },--special scaling, calculate in zzClasses
		}
end

--calculate spell Damage
function events.CalcSpellDamage(t)
	--mass distorsion
	if t.Spell == 44 then 
		t.Result = math.min(t.HP*0.15+t.HP*t.Skill*0.005)
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
	local ascensionSkill=0
	if data and data.Player then
		ascensionSkill,m = SplitSkill(data.Player:GetSkill(const.Skills.Learning))
		local id=data.Player:GetIndex()
		if table.find(elementalistClass, data.Player.Class) then
			ascensionSkill=0
			m=4
			for i=12,15 do
				local skill = SplitSkill(data.Player.Skills[i])
				ascensionSkill=ascensionSkill+skill
			end
			ascensionSkill=ascensionSkill/4
			vars.eleStacks=vars.eleStacks or {}
			vars.eleStacks[id]=vars.eleStacks[id] or 0
		end
		diceMin, diceMax, damageAdd = ascendSpellDamage(ascensionSkill, m, t.Spell, data.Player:GetIndex())
		if table.find(elementalistClass, data.Player.Class) then
			diceMax=round(diceMax*(1+vars.eleStacks[id]*0.1))
			damageAdd=round(damageAdd*(1+vars.eleStacks[id]*0.1))
		end
	end
	--calculate
	if t.Spell>1 and t.Spell<132 or t.Spell==200 or t.Spell==201 then
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
	if t.Spell == 200 then  -- lifedrain
		if t.Mastery==3 then
			t.Result=t.Result/3*5
		elseif t.Mastery==4 then
			t.Result=t.Result/3*7
		end
	end
	
	--int/crit/enchant scaling
	if data and data.Player and (data.Player.Class==10 or data.Player.Class==11 or table.find(dkClass, data.Player.Class)) then return end
	if data and data.Player then
		if data.Player.Class==10 or data.Player.Class==11 then return end --dragons scale off might
		
		local critChance, critMult, success=getCritInfo(data.Player,"spell")
		
		--int/pers scaling
		local int=data.Player:GetIntellect()
		local per=data.Player:GetPersonality()
		local mult=math.max(int,per)/1000+1
		t.Result=t.Result*mult
		if success then
			t.Result=t.Result*critMult
			crit=true
		end
	end
	--enchants
	if data and data.Player then
		for i=0,2 do
			local it=data.Player:GetActiveItem(i)
			if it then
				local dmg1=calcEnchantDamage(data.Player, it, 0, true, true, "damage")
				local dmg2=calcFireAuraDamage(data.Player, it, 0, false, true, "damage")
				damage=(dmg1+dmg2)*1.015^ascensionSkill
				if table.find(aoespells, t.Spell) then
					damage=damage/2.5
					if vars.madnessMode then
						--damage=damage*0.7
					end
				end
				t.Result = t.Result+damage
			end
		end
	end
	
end

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
function events.CalcDamageToMonster(t)
	local data=WhoHitMonster()
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


function ascendSpellDamage(skill, mastery, spell, index)
	--empower spell buff
	local empowerMult=1
	if vars.MAWSETTINGS.buffRework=="ON" and vars.mawbuff[28] then
		local s, m=getBuffSkill(28)
		empowerMult=1+buffPower[5].Base[m]/100+buffPower[5].Scaling[m]/1000*s
	end
	
	diceMin=spellPowers[spell].diceMin*empowerMult
	diceMax=spellPowers[spell].diceMax*empowerMult
	damageAdd=spellPowers[spell].dmgAdd*empowerMult
	
	diceMax=diceMax * (1+0.09 * skill)*1.025^skill
	damageAdd=damageAdd*(1+0.04*skill^2)*1.025^skill
		
	diceMin, diceMax, damageAdd = round(diceMin), round(diceMax), round(damageAdd)
	return diceMin, diceMax, damageAdd
end

function ascendSpellHealing(skill, mastery, spell, healM)
	base=healingSpells[spell].Base[healM]
	scaling=healingSpells[spell].Scaling[healM]
	scaling=scaling * (1+0.06 * skill)*1.02^skill
	base=base*(1 + 0.025 * skill^2)*1.02^skill
	scaling, base = round(scaling), round(base)
	return scaling, base
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
spellbonusdamage[39] = {["low"]=40, ["high"]=80}

aoespells = {6, 7, 8, 9, 10, 15, 22, 24, 32, 41, 43, 84, 93, 97, 98, 99, 123}

--function for tooltips
function dmgAddTooltip(skill, mastery, spell)
	_, _, dmgAdd = ascendSpellDamage(skill, mastery, spell)
	return dmgAdd
end

function diceMaxTooltip(skill, mastery, spell)
	_, diceMax, _ = ascendSpellDamage(skill, mastery, spell)
	return diceMax
end

--backup healing tooltips
local healingList={49, 54, 55, 68, 74, 77}
function events.GameInitialized2()
	baseHealTooltip={}
	for i=1,6 do
		baseHealTooltip[healingList[i]]=Game.SpellsTxt[healingList[i]].Description
	end
end
--adjust mana cost and tooltips	
function events.Action(t)
	function events.Tick() 
		events.Remove("Tick", 1)
		ascension()
	end
--[[	if t.Action==25 then
		ascension()
		local id=Game.CurrentPlayer
		if id>=0 and id<=Party.High then
			local pl=Party[id]
			local spellCast=0
			if t.Param==0 then
				spellCast=pl.QuickSpell
			elseif t.Param==1 then
				spellCast=pl.AttackSpell
			end
			local s,m=SplitSkill(pl.Skills[11+math.ceil(spellCast/11)])
			if pl.SP<Game.Spells[spellCast]["SpellPoints" .. masteryName[m] ] then
				--DoGameAction(23,0,0)
				t.Handled=true
				debug.Message(t.Action)
			else
				Game.ShowStatusText(id .. "  " .. spellCast .. "  " ..Game.Spells[spellCast]["SpellPoints" .. masteryName[m] ])
			end
		end
	end
	]]
end

function events.Tick()
	lastCheck=lastCheck or -1
	local lowestDelay=math.huge
	local playerToAscend=Game.CurrentPlayer
	if playerToAscend>Party.High then return end
	if Game.CurrentPlayer==-1 then
		for i=0,Party.High do
			local pl=Party[i]
			local delay=pl.RecoveryDelay
			if delay<lowestDelay then
				lowestDelay=delay
				playerToAscend=i
			end
		end
	end
	if playerToAscend~=lastCheck then
		ascension(playerToAscend)
		checkSkills(playerToAscend)
		lastCheck=playerToAscend
	end
end

-----------------------
--Healing Spells
-----------------------
healingSpellList={const.Spells.RemoveCurse,const.Spells.Resurrection,const.Spells.Heal,const.Spells.CureDisease,const.Spells.PowerCure}

-- Calculate personality-based mana cost reduction
function getPersonalityManaCostReduction(pl)
	local personality = pl:GetPersonality()
	local level = math.min(getTotalLevel(),1000)
	
	local personalityDivisor = 10 + (level) * 65 / 1000
	local reductionPercent = personality / personalityDivisor
	return (0.99^reductionPercent)
end

function AscendCCSpells(pl,s,m,personalityReduction)
	local mult=getCCDiffMult(Game.BolsterAmount)
	local lvl=pl.LevelBase
	
	for key, value in pairs(CCMAP) do
		if key~=122 then
			for i=1,4 do
				local baseCost = spellCost[key][masteryName[i]]*(1+s*0.125)*1.04^(s)*(1-0.125*m)
				local finalCost=math.min(math.ceil(baseCost * personalityReduction), 65000)
				Game.Spells[key]["SpellPoints" .. masteryName[i]]=finalCost
			end
			
			local baseDuration=value.Duration/const.Minute*2
			local school=math.ceil(key/11)+11
			local spellS, spellM = SplitSkill(pl.Skills[school])
			local masteryMult = ({0.5, 0.65, 0.8, 1})[math.max(1,spellM)]
			local ascendedDuration=baseDuration * masteryMult * 1.015^(s) / (lvl/200)
			
			-- Update N/E/M/GM descriptions with duration at each mastery
			local durN = baseDuration * ({0.5, 0.65, 0.8, 1})[1] * 1.015^(s) / (lvl/200)
			local durE = baseDuration * ({0.5, 0.65, 0.8, 1})[2] * 1.015^(s) / (lvl/200)
			local durM = baseDuration * ({0.5, 0.65, 0.8, 1})[3] * 1.015^(s) / (lvl/200)
			local durGM = baseDuration * ({0.5, 0.65, 0.8, 1})[4] * 1.015^(s) / (lvl/200)
			Game.SpellsTxt[key].Normal = string.format("Duration: %.1f seconds", durN)
			Game.SpellsTxt[key].Expert = string.format("Duration: %.1f seconds", durE)
			Game.SpellsTxt[key].Master = string.format("Duration: %.1f seconds", durM)
			Game.SpellsTxt[key].GM = string.format("Duration: %.1f seconds", durGM)
		end
	end
end

function ascension(customIndex)
	local index=customIndex or Game.CurrentPlayer 
	if index> Party.High then
		Game.CurrentPlayer=0
	end 
	if index>=0 and index<=Party.High then
		local pl=Party[index]
		
		--necessary to make dk/assassin tooltips work
		if table.find(dkClass, pl.Class) then
			dkSkills(true, index)
			return
		end
		if table.find(assassinClass, pl.Class) then 
			assassinSkills(true, pl)
			return
		end
		
		
		local level=pl:GetSkill(const.Skills.Learning)
		lastLevel=level
		local s,m = SplitSkill(level)
		local elementalist=false
		local id=pl:GetIndex()
		if table.find(elementalistClass, pl.Class) then
			elementalist=true
			s=0
			m=4
			for i=12,15 do
				local skill = SplitSkill(pl.Skills[i])
				s=s+skill
			end
			s=s/4
			vars.eleStacks=vars.eleStacks or {}
			vars.eleStacks[id]=vars.eleStacks[id] or 0
		end
		if table.find(shamanClass, pl.Class) then
			elementalist=true
			s=0
			m=4
			for i=12,18 do
				local skill = SplitSkill(pl.Skills[i])
				s=s+skill
			end
			s=s/7
		end
		-- Apply personality mana cost reduction
		local personalityReduction = getPersonalityManaCostReduction(pl)

		for v=1,#spells do 
			num=spells[v]
			for i=1,4 do
				local baseCost = spellCost[num][masteryName[i]]*(1+s*0.125)*1.04^(s)*(1-0.125*m)
				Game.Spells[num]["SpellPoints" .. masteryName[i]]=math.min(math.ceil(baseCost * personalityReduction), 65000)
				if elementalist then
					local baseCost=round((spellCost[num][masteryName[i]]+vars.eleStacks[id])*(1+s*0.125)*1.04^(s)*(1-0.125*m))
					Game.Spells[num]["SpellPoints" .. masteryName[i]]=math.min(round(math.ceil(baseCost*(1+vars.eleStacks[id]*0.075) * personalityReduction)),65000)
				end
			end
			if num==44 then	
				Game.Spells[num]["SpellPointsGM"]=math.min(pl.LevelBase, 255)^1.4/12.5
			end
		end				
			
		--change tooltips according to ascended damage
		Game.SpellsTxt[2].Description=string.format("Launches a burst of fire at a single target.  Damage is %s+1-%s points of damage per point of skill in Fire Magic.   Firebolt is safe, effective and has a low casting cost.",dmgAddTooltip(s, m,2),diceMaxTooltip(s, m,2))
		Game.SpellsTxt[6].Description=string.format("Fires a ball of fire at a single target. When it hits, the ball explodes damaging all those nearby, including your characters if they're too close.  Fireball does 1-%s points of damage per point of skill in Fire Magic.",diceMaxTooltip(s, m,6))
		--fire spikes fix
		Game.SpellsTxt[7].Description="Drops a Fire Spike on the ground that waits for a creature to get near it before exploding.  Fire Spikes last until you leave the map or they are triggered."
		Game.SpellsTxt[7].Expert=string.format("Causes 1-%s points of damage per point of skill, 5 spikes maximum",diceMaxTooltip(s, m,7))
		Game.SpellsTxt[7].Master=string.format("Causes 1-%s points of damage per point of skill, 5 spikes maximum",round(diceMaxTooltip(s, m,7)/6*8))
		Game.SpellsTxt[7].GM=string.format("Causes 1-%s points of damage per point of skill, 5 spikes maximum",round(diceMaxTooltip(s, m,7)/6*10))
		----------------------------------------
		
		Game.SpellsTxt[8].Description=string.format("Reserve a mana percentage to surround your characters with a very hot fire that is only harmful to others.  The spell will deliver %s points of damage plus 1-%s per point of skill to all nearby monsters for as long as they remain in the area of effect.",dmgAddTooltip(s, m,8),diceMaxTooltip(s, m,8))
		Game.SpellsTxt[9].Description=string.format("Summons flaming rocks from the sky which fall in a large radius surrounding your chosen target.  Try not to be near the victim when you use this spell.  A single meteor does %s points of damage plus %s per point of skill in Fire Magic.  This spell only works outdoors.",dmgAddTooltip(s, m,9),diceMaxTooltip(s, m,9))
		Game.SpellsTxt[10].Description=string.format("Inferno burns all monsters in sight when cast, excluding your characters.  One or two castings can clear out a room of weak or moderately powerful creatures. Each monster takes %s points of damage plus %s per point of skill in Fire Magic.  This spell only works indoors.",dmgAddTooltip(s, m,10),diceMaxTooltip(s, m,10))
		Game.SpellsTxt[11].Description=string.format("Among the strongest direct damage spells available, Incinerate inflicts massive damage on a single target.  Only the strongest of monsters can expect to survive this spell.  Damage is %s points plus 1-%s per point of skill in Fire Magic.",dmgAddTooltip(s, m,11),diceMaxTooltip(s, m,11))
		Game.SpellsTxt[15].Description=string.format("Sparks fires small balls of lightning into the world that bounce around until they hit something or dissipate. It is hard to tell where they will go, so this spell is best used in a room crowded with small monsters. Each spark does 1-%s per point of skill in Air Magic.",diceMaxTooltip(s, m,15))
		Game.SpellsTxt[18].Description=string.format("Lightning Bolt discharges electricity from the caster's hand to a single target.  It always hits and does %s points plus 1-%s points of damage per point of skill in Air Magic.\n\nThe spell then arcs to a second target, hitting it as well.",dmgAddTooltip(s, m,18),diceMaxTooltip(s, m,18))
		Game.SpellsTxt[20].Description=string.format("Implosion is a nasty spell that affects a single target by destroying the air around it, causing a sudden inrush from the surrounding air, a thunderclap, and %s points plus 1-%s points of damage per point of skill in Air Magic.",dmgAddTooltip(s, m,20),diceMaxTooltip(s, m,20))
		Game.SpellsTxt[22].Description=string.format("Calls stars from the heavens to smite and burn your enemies.  Twenty stars are called, and the damage for each star is %s points plus %s per point of skill in Air Magic. Try not to get caught in the blast! This spell only works outdoors.",dmgAddTooltip(s, m,22),diceMaxTooltip(s, m,22))
		Game.SpellsTxt[24].Description=string.format("Sprays poison at monsters directly in front of your characters.  Damage is low, but few monsters have resistance to Water Magic, so it usually works.  Each shot does %s points of damage plus 1-%s per point of skill.",dmgAddTooltip(s, m,24),diceMaxTooltip(s, m,24))
		Game.SpellsTxt[26].Description=string.format("Fires a bolt of ice at a single target.  The missile does %s + 1-%s points of damage per point of skill in Water Magic.",dmgAddTooltip(s, m,26),diceMaxTooltip(s, m,26))
		Game.SpellsTxt[29].Description=string.format("Acid burst squirts a jet of extremely caustic acid at a single victim.  It always hits and does %s points of damage plus 1-%s per point of skill.",dmgAddTooltip(s, m,29),diceMaxTooltip(s, m,29))
		Game.SpellsTxt[32].Description=string.format("Fires a ball of ice in the direction the caster is facing.  The ball will shatter when it hits something, launching 7 shards of ice in all directions except the caster's.  The shards will ricochet until they strike a creature or melt.  Each shard does %s points of damage plus 1-%s per point of skill in Water Magic.",dmgAddTooltip(s, m,32),diceMaxTooltip(s, m,32))
		Game.SpellsTxt[34].Description="Slaps a monster with magical force, forcing it to recover from the stun spell before it can do anything else.  Stun also knocks monsters back a little, giving you a chance to get away while the getting is good.  The greater your skill in Earth Magic, the greater the effect of the spell."
		Game.SpellsTxt[37].Description=string.format("Summons a swarm of biting, stinging insects to bedevil a single target.  The swarm does %s points of damage plus 1-%s per point of skill in Earth Magic.",dmgAddTooltip(s, m,37),diceMaxTooltip(s, m,37))
		Game.SpellsTxt[39].Description=string.format("Fires a rotating, razor-thin metal blade at a single monster.  The blade does 1-%s points of damage per point of skill in Earth Magic.\n\nBlades is the only spell capable to deal Physical damage.",diceMaxTooltip(s, m,39))
		Game.SpellsTxt[41].Description=string.format("Releases a magical stone into the world that will explode when it comes into contact with a creature or enough time passes.  The rock will bounce and roll until it finds a resting spot, so be careful not to be caught in the blast.  The explosion causes %s points of damage plus 1-%s points of damage per point of skill in Earth Magic.",dmgAddTooltip(s, m,41),diceMaxTooltip(s, m,41))
		Game.SpellsTxt[43].Description=string.format("Launches a magical stone which bursts in air, sending shards of explosive earth raining to the ground.  The damage is 1-%s per point of skill in Earth Magic for each shard.  This spell can only be used outdoors.",diceMaxTooltip(s, m,43))
		--Game.SpellsTxt[44].Description=string.format("Increases the weight of a single target enormously for an instant, causing internal damage equal to %s%% of the monster's hit points plus another %s%% per point of skill in Earth Magic.  The bigger they are, the harder they fall.",dmgAddTooltip(s, m,44),diceMaxTooltip(s, m,44))
		Game.SpellsTxt[44].Description="Increases the weight of a single target enormously for an instant, causing internal damage equal to 15%% of the monster's hit points plus another 0.5%% per point of skill in Earth Magic. The bigger they are, the harder they fall."
		Game.SpellsTxt[52].Description=string.format("This spell weakens the link between a target's body and soul, causing %s + 2-%s points of damage per point of skill in Spirit Magic to all monsters near the caster.",dmgAddTooltip(s, m,52),diceMaxTooltip(s, m,52))
		Game.SpellsTxt[59].Description=string.format("Fires a bolt of mental force which damages a single target's nervous system.  Mind Blast does %s points of damage plus 1-%s per point of skill in Mind Magic.",dmgAddTooltip(s, m,59),diceMaxTooltip(s, m,59))
		Game.SpellsTxt[65].Description=string.format("Similar to Mind Blast, Psychic Shock targets a single creature with mind damaging magic--only it has a much greater effect.  Psychic Shock does %s points of damage plus 1-%s per point of skill in Mind Magic.",dmgAddTooltip(s, m,65),diceMaxTooltip(s, m,65))
		Game.SpellsTxt[70].Description=string.format("Directly inflicts magical damage upon a single creature.  Harm does %s points of damage plus 1-%s per point of skill in Body Magic.",dmgAddTooltip(s, m,70),diceMaxTooltip(s, m,70))
		Game.SpellsTxt[76].Description=string.format("Flying Fist throws a heavy magical force at a single opponent that does %s points of damage plus 1-%s per point of skill in Body Magic.",dmgAddTooltip(s, m,76),diceMaxTooltip(s, m,76))
		Game.SpellsTxt[76].Description=string.format("Flying Fist throws a heavy magical force at a single opponent that does %s points of damage plus 1-%s per point of skill in Body Magic.",dmgAddTooltip(s, m,76),diceMaxTooltip(s, m,76))
		Game.SpellsTxt[78].Description=string.format("Fires a bolt of light at a single target that does %s + 1-%s points of damage per point of skill in light magic.  Damage vs. Undead is doubled.",dmgAddTooltip(s, m,78),diceMaxTooltip(s, m,78))
		Game.SpellsTxt[79].Description=string.format("Calls upon the power of heaven to undo the evil magic that extends the lives of the undead, inflicting %s points of damage plus 1-%s per point of skill in Light Magic upon a single, unlucky target.  This spell only works on the undead.",dmgAddTooltip(s, m,79),diceMaxTooltip(s, m,79))
		Game.SpellsTxt[84].Description=string.format("Inflicts %s points of damage plus %s per point of skill in Light Magic on all creatures in sight.  This spell can only be cast indoors.",dmgAddTooltip(s, m,84),diceMaxTooltip(s, m,84))
		Game.SpellsTxt[87].Description=string.format("Sunray is the second most devastating damage spell in the game. It does %s points of damage plus 1-%s points per point of skill in Light Magic, by concentrating the light of the sun on one unfortunate creature. It only works outdoors during the day.",dmgAddTooltip(s, m,87),diceMaxTooltip(s, m,87))
		Game.SpellsTxt[90].Description=string.format("A poisonous cloud of noxious gases is formed in front of the caster and moves slowly away from your characters.  The cloud does %s points of damage plus 1-%s per point of skill in Dark Magic and lasts until something runs into it.",dmgAddTooltip(s, m,90),diceMaxTooltip(s, m,90))
		Game.SpellsTxt[93].Description=string.format("Fires a blast of hot, jagged metal in front of the caster, striking any creature that gets in the way.  Each piece inflicts 1-%s points of damage per point of skill in Dark Magic.",diceMaxTooltip(s, m,93))
		Game.SpellsTxt[97].Description=string.format("Dragon Breath empowers the caster to exhale a cloud of toxic vapors that targets a single monster and damage all creatures nearby, doing 1-%s points of damage per point of skill in Dark Magic.",diceMaxTooltip(s, m,97))
		Game.SpellsTxt[98].Description=string.format("This spell is the town killer. Armageddon inflicts %s points of damage plus %s point of damage for every point of Dark skill your character has to every creature on the map, including all your characters. It can only be cast three times per day and only outdoors.",dmgAddTooltip(s, m,98),diceMaxTooltip(s, m,98))
		Game.SpellsTxt[99].Description=string.format("This horrible spell sucks the life from all creatures in sight, friend or enemy.  Souldrinker then transfers that life to your party in much the same fashion as Shared Life.  Damage (and healing) is %s + 1-%s per point of skill.",dmgAddTooltip(s, m,99),diceMaxTooltip(s, m,99))
		
		Game.SpellsTxt[103].Description=string.format("This frightening ability grants the Dark Elf the power to wield Darkfire, a dangerous combination of the powers of Dark and Fire. Any target stricken by the Darkfire bolt resists with either its Fire or Dark resistance--whichever is lower. Damage is %s points of damage plus 1-%s per point of skill.",dmgAddTooltip(s, m,103),diceMaxTooltip(s, m,103))
		Game.SpellsTxt[111].Description=string.format("Lifedrain allows the vampire to damage his or her target and simultaneously heal based on the damage done in the Lifedrain.  This ability does 1-%s points of damage per skill.",diceMaxTooltip(s, m,111))
		Game.SpellsTxt[111].Master=string.format("Damage 1-%s per point of skill",round(diceMaxTooltip(s, m,111)/3*5))
		Game.SpellsTxt[111].GM=string.format("Damage 1-%s per point of skill",round(diceMaxTooltip(s, m,111)/3*7))
		Game.SpellsTxt[123].Description="This ability is an upgraded version of the normal Dragon breath weapon attack.  It acts much like a fireball, striking its target and exploding out to hit everything near it, except the explosion does much more damage than most fireballs."
		
		-----------------------
		--Healing Spells
		-----------------------
		if vars.insanityMode then
			healingSpells={
			[const.Spells.RemoveCurse]=    {["Cost"]={0,15,30,60,[0]=0}, ["Base"]={0,20,40,60,[0]=0}, ["Scaling"]={0,8,12,16}},
			[const.Spells.SharedLife]=    {["Cost"]={0,0,25,40,[0]=0}, ["Base"]={0,0,0,0,[0]=0}, ["Scaling"]={0,0,7,9}},
            [const.Spells.Resurrection]={["Cost"]={0,0,0,300,[0]=0}, ["Base"]={0,0,0,450,[0]=0}, ["Scaling"]={0,0,0,50}},
            [const.Spells.Heal]=        {["Cost"]={6,15,24,40,[0]=0}, ["Base"]={12,24,36,48,[0]=0}, ["Scaling"]={6,9,12,15}},
            [const.Spells.CureDisease]=    {["Cost"]={0,0,45,100,[0]=0}, ["Base"]={0,0,50,100,[0]=0}, ["Scaling"]={0,0,16,25}},
            [const.Spells.PowerCure]=    {["Cost"]={0,0,0,150,[0]=0}, ["Base"]={0,0,0,50,[0]=0}, ["Scaling"]={0,0,0,12}}
		}
		else
			healingSpells={
				[const.Spells.RemoveCurse]=    {["Cost"]={0,5,10,20,[0]=0}, ["Base"]={0,10,20,30,[0]=0}, ["Scaling"]={0,4,6,8}},
				[const.Spells.SharedLife]=    {["Cost"]={0,0,25,40,[0]=0}, ["Base"]={0,0,0,0,[0]=0}, ["Scaling"]={0,0,7,9}},
				[const.Spells.Resurrection]={["Cost"]={0,0,0,100,[0]=0}, ["Base"]={0,0,0,150,[0]=0}, ["Scaling"]={0,0,0,21}},
				[const.Spells.Heal]=        {["Cost"]={2,4,6,8,[0]=0}, ["Base"]={4,8,12,16,[0]=0}, ["Scaling"]={2,3,4,6}},
				[const.Spells.CureDisease]=    {["Cost"]={0,0,15,25,[0]=0}, ["Base"]={0,0,25,40,[0]=0}, ["Scaling"]={0,0,7,10}},
				[const.Spells.PowerCure]=    {["Cost"]={0,0,0,30,[0]=0}, ["Base"]={0,0,0,15,[0]=0}, ["Scaling"]={0,0,0,4}}
			}
		end
		for i=1, 6 do
			for v=1,4 do
				local baseCost = healingSpells[healingList[i]].Cost[v]*(1+s*0.125)*1.04^(s)*(1-0.125*m)
				healingSpells[healingList[i]].Cost[v]=math.min(round(baseCost*personalityReduction), 65000)
				healingSpells[healingList[i]].Scaling[v], healingSpells[healingList[i]].Base[v]=ascendSpellHealing(s, m, healingList[i], v)
			end
		end
		for i=1, 6 do
			Game.SpellsTxt[healingList[i]].Description=baseHealTooltip[healingList[i]]
		end
		--shaman modifier
		if table.find(shamanClass, pl.Class) then
			local s=0
			for school=12,18 do
				skill=SplitSkill(pl.Skills[school])
				s=s+skill
			end
			local mult=1+s/400
			for i=1,5 do
				for v=1,4 do
					healingSpells[healingList[i]].Scaling[v]=round(healingSpells[healingList[i]].Scaling[v]*mult)
					healingSpells[healingList[i]].Base[v]=round(healingSpells[healingList[i]].Base[v]*mult)
				end
			end
		end
		--remove curse
		local sp=healingSpells[49]
		Game.Spells[49]["SpellPointsExpert"]=math.ceil(sp.Cost[2])
		Game.Spells[49]["SpellPointsMaster"]=math.ceil(sp.Cost[3])
		Game.Spells[49]["SpellPointsGM"]=math.ceil(sp.Cost[4])
		Game.SpellsTxt[49].Expert=string.format("%s Mana cost: \ncures %s + %s HP per point of skill\n1 day limit\n",sp.Cost[2], sp.Base[2], sp.Scaling[2])
		Game.SpellsTxt[49].Master=string.format("%s Mana cost: \ncures %s + %s HP per point of skill\n1 day limit\n",sp.Cost[3], sp.Base[3], sp.Scaling[3])
		Game.SpellsTxt[49].GM=string.format("%s Mana cost: \ncures %s + %s HP per point of skill\n1 day limit\n",sp.Cost[4], sp.Base[4], sp.Scaling[4])

		--shared life
		local sp=healingSpells[54]
		Game.Spells[54]["SpellPointsMaster"]=math.ceil(sp.Cost[3])
		Game.Spells[54]["SpellPointsGM"]=math.ceil(sp.Cost[4])
		Game.SpellsTxt[54].Master=string.format("Adds %s + %s HP per point of skill to the pool", sp.Base[3], sp.Scaling[3])
		Game.SpellsTxt[54].GM=string.format("Adds %s + %s HP per point of skill to the pool", sp.Base[4], sp.Scaling[4])
		
		--raise dead
		local sp=healingSpells[53]
		Game.SpellsTxt[53].GM="Removes Death and Eradication with no time limit"
		
		--resurrection
		local sp=healingSpells[55]
		Game.Spells[55]["SpellPointsGM"]=math.ceil(sp.Cost[4])
		Game.SpellsTxt[55].GM=string.format("Cures %s + %s HP per point of skill", sp.Base[4], sp.Scaling[4])
		
		--heal
		local sp=healingSpells[68]
		Game.Spells[68]["SpellPointsNormal"]=math.ceil(sp.Cost[1])
		Game.Spells[68]["SpellPointsExpert"]=math.ceil(sp.Cost[2])
		Game.Spells[68]["SpellPointsMaster"]=math.ceil(sp.Cost[3])
		Game.Spells[68]["SpellPointsGM"]=math.ceil(sp.Cost[4])
		Game.SpellsTxt[68].Normal=string.format("%s Mana cost: \ncures %s + %s HP per point of skill",sp.Cost[1], sp.Base[1], sp.Scaling[1])
		Game.SpellsTxt[68].Expert=string.format("%s Mana cost: \ncures %s + %s HP per point of skill",sp.Cost[2], sp.Base[2], sp.Scaling[2])
		Game.SpellsTxt[68].Master=string.format("%s Mana cost: \ncures %s + %s HP per point of skill",sp.Cost[3], sp.Base[3], sp.Scaling[3])
		Game.SpellsTxt[68].GM=string.format("%s Mana cost: \ncures %s + %s HP per point of skill",sp.Cost[4], sp.Base[4], sp.Scaling[4])
		
		--greater heal
		local sp=healingSpells[74]
		Game.Spells[74]["SpellPointsMaster"]=math.ceil(sp.Cost[3])
		Game.Spells[74]["SpellPointsGM"]=math.ceil(sp.Cost[4])
		Game.SpellsTxt[74].Master=string.format("%s Mana cost: \ncures %s + %s HP per point of skill\n1 day limit\n",sp.Cost[3], sp.Base[3], sp.Scaling[3])
		Game.SpellsTxt[74].GM=string.format("%s Mana cost: \ncures %s + %s HP per point of skill\nno limit\n",sp.Cost[4], sp.Base[4], sp.Scaling[4])
		
		--power heal
		local sp=healingSpells[77]
		Game.Spells[77]["SpellPointsGM"]=math.ceil(sp.Cost[4])
		Game.SpellsTxt[77].GM=string.format("%s Mana cost: \ncures %s + %s HP per point of skill",sp.Cost[4], sp.Base[4], sp.Scaling[4])
		
		--ADD CAST RECOVERY TIME 
		
		--haste
		local haste=math.floor(pl:GetSpeed()/10)
		local it=pl:GetActiveItem(1)
		if it and it.Bonus2==40 then
			haste=haste+20
		end
		
		adjustSpellTooltips()
		
		if vars.MAWSETTINGS.buffRework=="ON" then
			for i=1, #buffSpellList do
				local sp=buffSpellList[i]
				if buffSpell[sp] then
					local cost, percent=getBuffCost(pl, sp)
					percent=round(percent*10000)/100
					local txt=StrColor(255,0,0,"\nNot Active")
					if vars.mawbuff[sp] then
						for j=0, Party.High do
							if Party[j]:GetIndex()==vars.mawbuff[sp] then
								txt=StrColor(0,255,0,"\nActive (" .. Party[j].Name .. ")")
							end
						end
					end
					if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 32) then
						Game.SpellsTxt[sp].Description=Game.SpellsTxt[sp].Description .. "\n\nHealth Reserved: " .. StrColor(0,255,0,percent .. "%" .. txt)
					else
						Game.SpellsTxt[sp].Description=Game.SpellsTxt[sp].Description .. "\n\nMana Reserved: " .. StrColor(0,100,255,percent .. "%" .. txt)
					end					
				elseif utilitySpell[sp] then
					local cost, percent=getBuffCost(pl, sp)
					cost=round(cost)
					local txt=StrColor(255,0,0,"\nNot Active")
					if vars.mawbuff[sp] then
						for j=0, Party.High do
							if Party[j]:GetIndex()==vars.mawbuff[sp] then
								txt=StrColor(0,255,0,"\nActive(" .. Party[j].Name .. ")")
							end
						end
					end
					if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 32) then
						Game.SpellsTxt[sp].Description=oldSpellTooltips[sp] .. "\n\nHealth Reserved: " .. StrColor(0,255,0,cost .. txt)
					else
						Game.SpellsTxt[sp].Description=oldSpellTooltips[sp] .. "\n\nMana Reserved: " .. StrColor(0,100,255,cost .. txt)
					end			
				end
				for v=1,4 do
					if buffSpell[sp] then
						Game.Spells[sp]["SpellPoints" .. masteryName[v]]=0
						Game.SpellsTxt[sp].Normal=""
						Game.SpellsTxt[sp].Expert=""
						Game.SpellsTxt[sp].Master=""
						Game.SpellsTxt[sp].GM=""
					elseif utilitySpell[sp] then
						Game.Spells[sp]["SpellPoints" .. masteryName[v]]=0
						Game.SpellsTxt[sp].Normal=""
						Game.SpellsTxt[sp].Expert=""
						Game.SpellsTxt[sp].Master=""
						Game.SpellsTxt[sp].GM=""
					end
				end
			end
		end
		
		for i=1,132 do
			local skill=11+math.ceil(i/11)
			local magicS, magicM=SplitSkill(pl.Skills[skill])
			if magicM>0 then
				local speed=getSpellDelay(pl,i)
				if table.find(spells, i) then
					Game.SpellsTxt[i].Description=Game.SpellsTxt[i].Description .. "\n\nRecovery time: " .. speed
				elseif healingSpells[i] then
					Game.SpellsTxt[i].Description=Game.SpellsTxt[i].Description .. "\n\nRecovery time: " .. speed
				elseif CCMAP[i] and i~=122 then
					Game.SpellsTxt[i].Description=oldSpellTooltips[i] .. "\n\nControl Spell duration is reduced by monster resistances but increased by Ascension; Recovery time is reduced by Spell Skill. Duration shown is against " .. round(pl.LevelBase/2) .. " resistance. Control duration against bosses is halved.\n\nRecovery time: " .. speed
				elseif buffSpell and (buffSpell[i] or utilitySpell[i]) then
					Game.SpellsTxt[i].Description=Game.SpellsTxt[i].Description .. "\n\nRecovery time: " .. oldTable[i][magicM]
				else
					Game.SpellsTxt[i].Description=oldSpellTooltips[i] .. "\n\nRecovery time: " .. oldTable[i][magicM]
				end
			end
			local capMastery=Skillz.MasteryLimit(pl,skill)
			local tier=i%11==0 and 11 or i%11
			local learnableSpells={{1,2,3,4},{5,6,7},{8,9,10},{11}}
			if not pl.Spells[i] then
				local txt=StrColor(255,0,0,"\n\nCan't learn")
				for k=1,capMastery do
					if table.find(learnableSpells[k],tier) then
						txt=StrColor(255,0,0,"\n\nNot Learned")
					end
				end
				
				if table.find(spells, i) then
					Game.SpellsTxt[i].Description=Game.SpellsTxt[i].Description .. txt
				elseif healingSpells[i] then
					Game.SpellsTxt[i].Description=Game.SpellsTxt[i].Description .. txt
				elseif buffSpell and (buffSpell[i] or utilitySpell[i]) then
					Game.SpellsTxt[i].Description=Game.SpellsTxt[i].Description .. txt
				else
					Game.SpellsTxt[i].Description=oldSpellTooltips[i] .. txt
				end
			end
		end

		AscendCCSpells(pl,s,m,personalityReduction)
	end
end

---------------
-- BUFF REWORK (MAW SPELL)
-- SOLO : spéciaux sans TTL (comportement original)
-- MULTI : spéciaux avec TTL (Temple/Scroll/Piédestal)
---------------

function events.GameInitialized2()
	spScaling={}
	for i=0,Game.Classes.SPFactor.High do
		spScaling[i]=Game.Classes.SPFactor[i]
	end
	hpScalings={}
	for i=0,Game.Classes.HPFactor.High do
		hpScalings[i]=Game.Classes.HPFactor[i]
	end

	--dk
	spScaling[56]=3
	spScaling[57]=6
	spScaling[58]=9
	--shaman
	spScaling[59]=1
	spScaling[60]=1.5
	spScaling[61]=2
	--assassin
	spScaling[const.Class.Thief]=7.5
	spScaling[const.Class.Rogue]=7.5
	spScaling[const.Class.Assassin]=7.5
	spScaling[const.Class.Spy]=7.5

	-- === TTL par défaut pour buffs spéciaux (Temple / Scroll / Piédestal)
	vars = vars or {}
	vars.MAWSETTINGS = vars.MAWSETTINGS or {}
	if vars.MAWSETTINGS.templeBuffTTL == nil then
		vars.MAWSETTINGS.templeBuffTTL = const.Hour           -- 1h temple (MULTI)
	end
	if vars.MAWSETTINGS.scrollBuffTTL == nil then
		vars.MAWSETTINGS.scrollBuffTTL  = const.Minute*15     -- 15min scroll/piedestal (MULTI)
	end

	-- map OFF local
	vars._maw_local_off = vars._maw_local_off or {}
end

-- === Tables d’origine ===
buffSpell={
[3]= {["Cost"]=60, ["Sound"]=10020, ["PartyBuff"]=6},--fire res
[4]= {["Cost"]=90, ["Sound"]=10040,},                --fire aura
[14]={["Cost"]=60, ["Sound"]=11020,["PartyBuff"]=0}, --air res
[25]={["Cost"]=60, ["Sound"]=12020,["PartyBuff"]=17},--water res
[36]={["Cost"]=60, ["Sound"]=13020,["PartyBuff"]=4}, --earth res
[58]={["Cost"]=60, ["Sound"]=15020,["PartyBuff"]=12},--mind res
[69]={["Cost"]=60, ["Sound"]=16020,["PartyBuff"]=1}, --body res
[5]= {["Cost"]=120,["Sound"]=10040,["PartyBuff"]=8}, --haste
[8]= {["Cost"]=40, ["Sound"]=10070,["PartyBuff"]=10},--immolation
[17]={["Cost"]=75, ["Sound"]=11050,["PartyBuff"]=14},--shield
[28]={["Cost"]=150,["Sound"]=10070,},                --empower magic
[38]={["Cost"]=75, ["Sound"]=13040,["PartyBuff"]=15},--stoneskin
[46]={["Cost"]=75, ["Sound"]=14010,["SingleBuff"]=1},--bless
[47]={["Cost"]=75, ["Sound"]=14020,["SingleBuff"]=4},--fate
[50]={["Cost"]=120,["Sound"]=14050,["SingleBuff"]=11},--preservation
[51]={["Cost"]=120,["Sound"]=14060,["PartyBuff"]=9}, --Heroism
[56]={["Cost"]=120,["Sound"]=15020,},                --Meditation
[71]={["Cost"]=120,["Sound"]=16040,["SingleBuff"]=12},--Regeneration
[73]={["Cost"]=75, ["Sound"]=16060,["SingleBuff"]=6},--Hammerhands
[75]={["Cost"]=180,["Sound"]=16080,["PartyBuff"]=13},--Protection from magic
[83]={["Cost"]=200,["Sound"]=17050,["PartyBuff"]=2}, --day of the gods
[85]={["Cost"]=150,["Sound"]=17070,["MultiBuff"]={6,0,17,4,12,1}},--day of Protection
[86]={["Cost"]=300,["Sound"]=17080,["MultiBuff"]={8,14,15}, ["SingleBuff"]=4},--hour of power
[91]={["Cost"]=150,["Sound"]=18020,},               --vampiric aura
[95]={["Cost"]=10, ["Sound"]=18060,["SingleBuff"]=10},--pain reflection
}
utilitySpell={
[1]= {["Cost"]=5,  ["Sound"]=10000,["PartyBuff"]=16},--torch
[12]={["Cost"]=5,  ["Sound"]=11000,["PartyBuff"]=19},--wizard eye
--[19]={["Cost"]=100,["Sound"]=11070,["PartyBuff"]=11},--Invisibility
--[21]={["Cost"]=120,["Sound"]=11090,["PartyBuff"]=7}, --fly
[27]={["Cost"]=20, ["Sound"]=12040,["PartyBuff"]=18},--water walk
--[124]={["Cost"]=20,["Sound"]=21020,["PartyBuff"]=7}, --fly
}

buffSpellList={1,3,4,12,14,21,25,27,28,36,56,58,69,5,8,17,38,46,47,50,51,71,73,75,83,85,86,91,95}
utilityBuffs={16,19,11,18}

mawPartyBuffList={6,0,17,4,12,1,8,10,14,15,9,13,2,16,19,18}
mawPartyBuffIgnore={16,19,11,18,10}
mawSingleBuffList={1,4,11,12,6,10}

buffPower={
	[3]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},
	[14]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},
	[25]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},
	[36]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},
	[58]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},
	[69]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},
	[5]=  {["Base"]={[0]=0,10,10,10,10}, ["Scaling"]={[0]=0,2,2,2,2}},
	[17]= {["Base"]={[0]=0,15,15,15,15}, ["Scaling"]={[0]=0,3,3,3,3}},
	[28]= {["Base"]={[0]=0,15,15,15,15}, ["Scaling"]={[0]=0,3,3,3,3}},
	[38]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},
	[46]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},
	[47]= {["Base"]={[0]=0,5,5,5,5},    ["Scaling"]={[0]=0,1,1,1,1}},
	[51]= {["Base"]={[0]=0,15,15,15,15},["Scaling"]={[0]=0,3,3,3,3}},
	[56]= {["Base"]={[0]=0,10,10,10,10},["Scaling"]={[0]=0,2,2,2,2}},
	[71]= {["Base"]={[0]=0,5,5,5,5},    ["Scaling"]={[0]=0,2,2,2,2}},
	[73]= {["Base"]={[0]=0,15,15,15,15},["Scaling"]={[0]=0,3,3,3,3}},
	[83]= {["Base"]={[0]=0,20,20,20,20},["Scaling"]={[0]=0,2,2,2,2}},
	[85]= {["Base"]={[0]=0,20,20,20,20},["Scaling"]={[0]=0,2,2,2,2}},
	[86]= {["Base"]={[0]=0,10,10,10,10},["Scaling"]={[0]=0,2,2,2,2}},
}

-- =================================================================================
-- Spéciaux (Temple/Scroll/Piédestal) : SOLO vs MULTI
-- =================================================================================
local function __is_special_source(v) return type(v)=="string" end
local function __is_temple(v) return v=="Temple" end
local function __special_ttl_for(v)
	if __is_temple(v) then
		return (vars.MAWSETTINGS and vars.MAWSETTINGS.templeBuffTTL) or const.Hour
	end
	return (vars.MAWSETTINGS and vars.MAWSETTINGS.scrollBuffTTL) or (const.Minute*15)
end
local function __ensure_expire_map()
	vars.maw_special_expire = vars.maw_special_expire or {}
	return vars.maw_special_expire
end

-- SOLO vs MULTI
local function inMulti()
	return Multiplayer and Multiplayer.in_game and true or false
end
local function special_use_ttl()
	-- On utilise le TTL uniquement en MULTI et si le rework n'est pas OFF
	return inMulti() and (not vars.MAWSETTINGS or vars.MAWSETTINGS.buffRework ~= "OFF")
end

-- NE PAS renouveler auto quand expiré (on écrit une fois)
local function __ensure_special_expire(buff)
	if not special_use_ttl() then return nil end  -- SOLO => pas de TTL
	local exmap = __ensure_expire_map()
	local src = vars.mawbuff and vars.mawbuff[buff]
	if not __is_special_source(src) then return nil end
	local ex = exmap[buff]
	if not ex then
		ex = Game.Time + __special_ttl_for(src)
		exmap[buff] = ex
	end
	return ex
end
local function __get_special_expire(buff)
	local exmap = __ensure_expire_map()
	return exmap[buff]
end
local function __clear_special_expire(buff)
	local exmap = __ensure_expire_map()
	exmap[buff] = nil
end

-- === Gestion Load / Leave et purge des spéciaux ===
function events.LoadMap()
	if vars.MAWSETTINGS and vars.MAWSETTINGS.buffRework=="OFF" then return end
	if not vars.mawbuff then
		vars.mawbuff={}
		for i=1,#buffSpellList do
			vars.mawbuff[buffSpellList[i]]=false
		end
	end
	--remove buffs from pedestal/scrolls if going into another outside map
	if Map.IsOutdoor() then
		for i=1, #buffSpellList do
			local buff=buffSpellList[i]
			if vars.mawbuff[buff] then
				if type(vars.mawbuff[buff])=="string" and vars.mawbuff[buff]~=Map.Name and vars.mawbuff[buff]~="Temple" then
					vars.mawbuff[buff]=false
					__clear_special_expire(buff)
				end
			end
		end
	end
	--remove temples even indoor (flag LeaveMap)
	for i=1, #buffSpellList do
		if removeTempleBuffs then
			local buff=buffSpellList[i]
			if vars.mawbuff[buff] and vars.mawbuff[buff]=="Temple" then
				vars.mawbuff[buff]=false
				__clear_special_expire(buff)
			end
		end
	end
	removeTempleBuffs=false

	-- ré-appliquer l’état rework si actif
	if vars.MAWSETTINGS.buffRework=="ON" then
		mawBuffApply()
	end
end

function events.LeaveMap()
	if vars.MAWSETTINGS and vars.MAWSETTINGS.buffRework=="ON" then
		removeTempleBuffs=true
	end
end

-- interception Action & Cast (pose TTL sur spéciaux en MULTI)
function events.Action(t)
	if t.Action==142 and (buffSpell[t.Param] or utilitySpell[t.Param]) and vars.MAWSETTINGS.buffRework=="ON" then
		t.Handled=true
		local pl=Party[t.Param2]
		local id=pl:GetIndex()
		mawBuffCast(pl, id, t.Param)
	end
end

function events.PlayerCastSpell(t)
	if (buffSpell[t.SpellId] or utilitySpell[t.SpellId]) and vars.MAWSETTINGS.buffRework=="ON" then
		-- Scrolls & Pedestals
		if t.TargetKind==4 or t.IsSpellScroll then
			vars.mawbuff[t.SpellId]=Map.Name
			do
				if special_use_ttl() and type(vars.mawbuff[t.SpellId])=="string" then
					local exmap = __ensure_expire_map()
					exmap[t.SpellId] = Game.Time + __special_ttl_for(vars.mawbuff[t.SpellId])
				end
			end
			function events.Tick()
				events.Remove("Tick",1)
				mawBuffApply()
			end
		else
			t.Handled=true
			mawBuffCast(t.Player, t.PlayerIndex, t.SpellId)
		end
	end
end

function getBuffCost(pl, spellId)
	local cost=0
	local percentageDecrease=0
	if buffSpell[spellId] then
		local id=pl:GetIndex()
		local s,m=SplitSkill(Skillz.get(pl,52))
		local div=spScaling[pl.Class]+m/2
		if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 32) then
			div=hpScalings[pl.Class]+m/2
		end
		percentageDecrease=(buffSpell[spellId].Cost/div)*0.01
		for i=0, Party.High do
			if id==Party[i]:GetIndex() and vars.maxManaPool[i] then
				if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 32) then
					cost=vars.maxHPPool[i]*percentageDecrease
				else
					cost=vars.maxManaPool[i]*percentageDecrease
				end
			end
		end
	elseif utilitySpell[spellId] then
		cost=round(utilitySpell[spellId].Cost)
	end
	return cost, percentageDecrease
end

--maw manual buff cast
function mawBuffCast(pl, index, spellId)
	if vars.mawbuff[spellId]~=index then --cast buff
		local id=-1
		for i=0, Party.High do
			if Party[i]:GetIndex()==index then
				id=i
			end
		end
		if id==-1 then return end

		local pl=Party[id]
		if not vars.maxManaPool then
			vars.maxManaPool={}
			vars.currentManaPool={}
			vars.maxHPPool={}
			vars.currentHPPool={}
			for i=0,Party.High do
				local sp=Party[i]:GetFullSP()
				vars.maxManaPool[i]=sp
				vars.currentManaPool[i]=sp
				local hp=Party[i]:GetFullHP()
				vars.maxHPPool[i]=hp
				vars.currentHPPool[i]=hp
			end
		end

		local sound
		if buffSpell[spellId] then
			sound=buffSpell[spellId].Sound
		elseif utilitySpell[spellId] then
			sound=utilitySpell[spellId].Sound
		end

		local cost=getBuffCost(pl, spellId)

		if vars.legendaries and vars.legendaries[index] and table.find(vars.legendaries[index], 32) then --reserve HP instead
			if vars.currentHPPool[id]<cost and not Game:GetCurrentHouse() then
				Game.ShowStatusText("Not enough Hit Points")
				return
			end
		elseif vars.currentManaPool[id]<cost and not Game:GetCurrentHouse() then
			Game.ShowStatusText("Not enough Mana")
			return
		end

		vars.mawbuff[spellId]=index
		-- clear override OFF si on rebuff
		vars._maw_local_off[spellId] = nil

		for i=0, Party.High do
			mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, mem.u4[0x75CE00]), spellId, i)
		end
		evt.PlaySound(sound)
		local delay=getSpellDelay(pl,spellId)
		if not delay or Game:GetCurrentHouse() then --donation en Temple
			vars.mawbuff[spellId]="Temple"
			do
				if special_use_ttl() then
					local exmap = __ensure_expire_map()
					exmap[spellId] = Game.Time + __special_ttl_for("Temple")
				end
			end
		else
			pl:SetRecoveryDelay(delay)
		end

		function events.Tick()
			events.Remove("Tick", 1)
			mawBuffApply()
		end
	else
		-- === DEBUFF local : pose un override OFF de 90s pour ignorer les retours distants
		vars.mawbuff[spellId]=false
		__clear_special_expire(spellId)
		vars._maw_local_off[spellId] = Game.Time + const.Minute + const.Second*30

		function events.Tick()
			events.Remove("Tick", 1)
			mawBuffApply()
			Game.ShowStatusText("Buff Disabled")
		end
	end
end

function mawBuffApply()
	if vars.MAWSETTINGS and vars.MAWSETTINGS.buffRework=="OFF" then return end
	-- reset party buffs de base
	for i=1, #mawPartyBuffList do
		local id=mawPartyBuffList[i]
		Party.SpellBuffs[id].ExpireTime=0
		if not table.find(mawPartyBuffIgnore, id) then
			Party.SpellBuffs[id].Power=0
			Party.SpellBuffs[id].Skill=0
		end
	end
	local s, m=getBuffSkill(1)
	Party.SpellBuffs[16].Power=m+1

	-- reset single buffs de base (sauf exceptions)
	for j=0, Party.High do
		local pl=Party[j]
		for k=1,#mawSingleBuffList do
			local id=mawSingleBuffList[k]
			if vars.buffToIgnore and vars.buffToIgnore[j] and vars.buffToIgnore[j][id] and vars.buffToIgnore[j][id]>Game.Time then
				pl.SpellBuffs[id].ExpireTime=vars.buffToIgnore[j][id]
			else
				pl.SpellBuffs[id].ExpireTime=0
			end
		end
	end

	for i=1, #buffSpellList do
		local buff=buffSpellList[i]
		if vars.mawbuff[buff] then
			-- si override OFF actif, on n’applique pas
			if vars._maw_local_off[buff] and Game.Time < vars._maw_local_off[buff] then
				goto skip_apply_this_buff
			end

			-- déterminer expiration cible
			local isSpecial = (type(vars.mawbuff[buff])=="string")
			local expireTarget
			if isSpecial then
				if special_use_ttl() then
					-- MULTI: TTL spécial
					local ex = __ensure_special_expire(buff)
					-- si le TTL existe ET qu'il est dépassé, couper
					if ex and Game.Time >= ex then
						vars.mawbuff[buff]=false
						__clear_special_expire(buff)
						goto skip_apply_this_buff
					else
						expireTarget = ex or (Game.Time + const.Hour) -- fallback sécurité
					end
				else
					-- SOLO: comportement original => longue durée
					expireTarget = Game.Time + const.Week
				end
			else
				expireTarget = Game.Time + const.Week
			end

			local pl=GetPlayerFromIndex(vars.mawbuff[buff])
			if (pl and pl:IsConscious()) or isSpecial or type(vars.mawbuff[buff])=="table" then
				if buff==75 then
					Party.SpellBuffs[13].Power=50
					Party.SpellBuffs[13].Skill=4
				end
				if buff==85 then
					for i2=1, #buffSpell[buff].MultiBuff do
						local buffId=buffSpell[buff].MultiBuff[i2]
						Party.SpellBuffs[buffId].ExpireTime=math.max(Party.SpellBuffs[buffId].ExpireTime, expireTarget)
					end
				elseif buff==86 then
					for i2=1, #buffSpell[buff].MultiBuff do
						local buffId=buffSpell[buff].MultiBuff[i2]
						Party.SpellBuffs[buffId].ExpireTime=math.max(Party.SpellBuffs[buffId].ExpireTime, expireTarget)
					end
					local buffId=buffSpell[buff].SingleBuff
					for j2=0, Party.High do
						Party[j2].SpellBuffs[buffId].ExpireTime=math.max(Party[j2].SpellBuffs[buffId].ExpireTime, expireTarget)
					end
				elseif buffSpell[buff] and buffSpell[buff].PartyBuff then
					local buffId=buffSpell[buff].PartyBuff
					Party.SpellBuffs[buffId].ExpireTime=math.max(Party.SpellBuffs[buffId].ExpireTime, expireTarget)
					if buffId==8 then
						Party.SpellBuffs[buffId].ExpireTime=math.max(Party.SpellBuffs[buffId].ExpireTime, expireTarget)
					end
				elseif buffSpell[buff] and buffSpell[buff].SingleBuff then
					local buffId=buffSpell[buff].SingleBuff
					for j2=0, Party.High do
						Party[j2].SpellBuffs[buffId].ExpireTime=math.max(Party[j2].SpellBuffs[buffId].ExpireTime, expireTarget)
					end
				elseif utilitySpell[buff] and utilitySpell[buff].PartyBuff then
					local buffId=utilitySpell[buff].PartyBuff
					if type(vars.mawbuff[buff])=="string" then
						Party.SpellBuffs[buffId].Caster=1
					elseif type(vars.mawbuff[buff])=="number" then
						Party.SpellBuffs[buffId].Caster=vars.mawbuff[buff]+1
					else
						Party.SpellBuffs[buffId].Caster=1
					end
					Party.SpellBuffs[buffId].Bits=1
					Party.SpellBuffs[buffId].ExpireTime=math.max(Party.SpellBuffs[buffId].ExpireTime, expireTarget)
				end
			end
			if vars.mawbuff[8] then
				if type(vars.mawbuff[8])=="string" then
					Party.SpellBuffs[10].Caster=1
				else
					Party.SpellBuffs[10].Caster=vars.mawbuff[8]+1
				end
			end
		end
		::skip_apply_this_buff::
	end

	--vampire night preservation
	for k=0, Party.High do
		local pl=Party[k]
		local race=Game.CharacterPortraits[pl.Face].Race
		if race==const.Race.Vampire then
			local hour=Game.Time%const.Day/const.Hour
			if (hour>21 or hour<5 or  Map.IndoorOrOutdoor==1) and Map.Name~="7d25.blv" then
				pl.SpellBuffs[const.PlayerBuff.Preservation].ExpireTime=math.max(Game.Time+const.Minute*5, pl.SpellBuffs[const.PlayerBuff.Preservation].ExpireTime)
			end
		end
	end
	if Party.High==0 then
		Party.SpellBuffs[19].ExpireTime=math.max(Game.Time+const.Hour, Party.SpellBuffs[19].ExpireTime)
		Party.SpellBuffs[19].Power=math.max(10,Party.SpellBuffs[19].Power)
		Party.SpellBuffs[19].Skill=math.max(2,Party.SpellBuffs[19].Skill)
		Party.SpellBuffs[16].ExpireTime=math.max(Game.Time+const.Hour, Party.SpellBuffs[16].ExpireTime)
		Party.SpellBuffs[16].Power=math.max(3,Party.SpellBuffs[16].Power)
		Party.SpellBuffs[16].Skill=math.max(1,Party.SpellBuffs[16].Skill)
	end

	for i=1,#vars.NPCFollowers do
		if Game.NPC[vars.NPCFollowers[i]].Profession==38 then
			Party.SpellBuffs[19].ExpireTime=math.max(Game.Time+const.Hour, Party.SpellBuffs[19].ExpireTime)
			Party.SpellBuffs[19].Power=math.max(10,Party.SpellBuffs[19].Power)
			Party.SpellBuffs[19].Skill=math.max(2,Party.SpellBuffs[19].Skill)
		end
	end

	--magic potion fix
	if vars.magicResistancePotionExpire and vars.magicResistancePotionExpire>Game.Time then
		Party.SpellBuffs[13].ExpireTime=vars.magicResistancePotionExpire
		Party.SpellBuffs[13].Power=4
		Party.SpellBuffs[13].Skill=10
	end

	--shadow bosses
	if mapvars.bossData then
		for index, bossInfo in pairs(mapvars.bossData) do
			if bossInfo.Skills == "Shadow" or bossInfo.Skills == "Omnipotent" then
				local mon = Map.Monsters[index]
				if mon then
					local distance = getDistance(mon.X, mon.Y, mon.Z)
					if distance < 2000 and mon.HP > 0 and mon.AIState ~= 19 then
						Party.SpellBuffs[const.PartyBuff.WizardEye].ExpireTime = 0
					end
				end
			end
		end
	end
	mawRefresh("all")
	buffManaLock()
end

function buffManaLock()
	if vars.MAWSETTINGS and vars.MAWSETTINGS.buffRework=="OFF" then return end
	vars.maxManaPool={}
	vars.currentManaPool={}
	vars.maxHPPool={}
	vars.currentHPPool={}
	local partyIndexes={}
	for i=0,Party.High do
		local id=Party[i]:GetIndex()
		partyIndexes[id]=i
		local sp=Party[i]:GetFullSP()
		vars.maxManaPool[i]=sp
		vars.currentManaPool[i]=sp
		local hp=Party[i]:GetFullHP()
		vars.maxHPPool[i]=hp
		vars.currentHPPool[i]=hp
	end
	for i=1, #buffSpellList do
		local spell=buffSpellList[i]
		if vars.mawbuff[spell] then
			local index=vars.mawbuff[spell]
			local id=partyIndexes[index]
			if id then
				local pl=Party[id]
				local s,m=SplitSkill(Skillz.get(pl,52))
				if vars.legendaries and vars.legendaries[index] and table.find(vars.legendaries[index], 32) then
					if buffSpell[spell] then
						local div=hpScalings[pl.Class]+m/2
						local percentageDecrease=(buffSpell[spell].Cost/div)*0.01
						vars.currentHPPool[id]=vars.currentHPPool[id]-vars.maxHPPool[id]*percentageDecrease
					elseif utilitySpell[spell] then
						vars.currentHPPool[id]=vars.currentHPPool[id]-round(utilitySpell[spell].Cost*(1-m/10))
					end
				else
					if buffSpell[spell] then
						local div=spScaling[pl.Class]+m/2
						local percentageDecrease=(buffSpell[spell].Cost/div)*0.01
						vars.currentManaPool[id]=vars.currentManaPool[id]-vars.maxManaPool[id]*percentageDecrease
					elseif utilitySpell[spell] then
						vars.currentManaPool[id]=vars.currentManaPool[id]-round(utilitySpell[spell].Cost*(1-m/10))
					end
				end
			end
		end
	end
	for i=0, Party.High do
		if table.find(assassinClass,Party[i].Class) or table.find(dkClass,Party[i].Class) then
			vars.currentManaPool[i]=vars.maxManaPool[i]
			vars.currentHPPool[i]=vars.maxHPPool[i]
		end
		Party[i].SP = math.min(math.ceil(vars.currentManaPool[i]), Party[i].SP)
		Party[i].HP = math.min(math.ceil(vars.currentHPPool[i]), Party[i].HP)
	end
end

function GetPlayerFromIndex(index)
	for i=0,Party.High do
		local player=Party[i]
		if player:GetIndex()==index then
			return player
		end
	end
	return false
end

-- NOTE:
--  - si vars.mawbuff[spell] est un {s,m,l} (table), on retourne tel quel
--  - si c’est un "string" (Temple/Map.Name) on retourne une valeur >0 pour l’appliquer localement,
--    mais le MULTI côté client filtre ces spéciaux pour éviter la re-diffusion.
function getBuffSkill(spell)
	local id=vars.mawbuff[spell]
	if type(id)=="table" then
		return id[1], id[2], id[3]
	end
	if type(id)=="string" then
		-- spécial (Temple/Scroll/Piédestal) : applique localement
		return 7,3,40
	end
	local player=GetPlayerFromIndex(id)
	if player and player:IsConscious() then
		local school=11+math.ceil(spell/11)
		local s,m=SplitSkill(player.Skills[school])
		if spell==83 or spell==85 or spell==86 then
			s=math.min(s,75)
		else
			s=math.min(s,50)
		end
		return s, m, player.LevelBase
	else
		return 0,0,0
	end
end

	
	--code to make buff work is elsewhere

--tooltips
function adjustSpellTooltips()
	if vars.MAWSETTINGS.buffRework=="ON" then
		--fire resistance
		local id=3
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Fire Resistance and Intellect by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--fire aura
		local id=4
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Causes your party weapons to burn with a magical fire, giving the weapons fire enchant, on top of any other enchants")
		
		--air resistance
		local id=14
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Air Resistance and Speed by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--water resistance
		local id=25
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Water Resistance and Luck by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--earth res
		local id=36
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Earth Resistance and Endurance by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--mind res
		local id=58
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Mind Resistance and Personality by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--body res
		local id=69
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Body Resistance and Might by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--Bless
		local id=46
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Attack and Accuracy.\nThe enhancement equals a flat %s plus an additional 1 point for every 2 caster levels, increased by %s%% per skill level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--Haste
		local id=5
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase your party Recovery speed by %s%% plus %s%% per Skill Level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		
		--Shield
		local id=17
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to reduce any incoming magic damage to your party by %s%% plus %s%% per Skill Level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		
		--Stoneskin
		local id=38
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Armor Class by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1])
		
		--Empower Magic
		local id=28
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase spell damage of your party by %s%% plus %s%% per Skill Level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		sp.Name = "Empower Magic"
		
		--fate
		local id=47
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase critical chance of your party by %s%% plus %s%% per Skill Level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		
		--heroism
		local id=51
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase your party melee damage by %s%% plus %s%% per Skill Level, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		
		--meditation
		local id=56
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase your party mana regen.\nRegen depends on the mana pool, caster level and it's increased by %s%% per skill point, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Scaling[1])
		sp.Name = "Meditation"
		
		--regeneration
		local id=71
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase your party health regen.\nRegen depends on the health pool, caster level and it's increased by %s%% per skill point, up to double bonus.\nThis effect remains active until deactivated or lose consciousness.", bf.Scaling[1])
		
		--Hammerhands
		local id=73
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase your party unarmed damage by %s%% plus %s%% per Skill Level, up to double bonus.\nStaves with GM skill and Unarmed is considered as unarmed as well.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		
		--day of the gods
		local id=83
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increases all seven stats on all your characters by %s.\nWhile the base effects remain consistent, each additional 3 levels in Light Magic will enhance the effects equivalently to only 2 levels.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--day of protection
		local id=85
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance all of your party's Resistances by %s.\nWhile the base effects remain consistent, each additional 3 levels in Light Magic will enhance the effects equivalently to only 2 levels.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--hour of power
		local id=86
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to simultaneously casts Haste, Shield, Stone Skin, and Fate on all your characters.\nWhile the base effects remain consistent, each additional 3 levels in Light Magic will enhance the effects equivalently to only 2 levels.\nThis effect remains active until deactivated or lose consciousness.")
		
		--preservation
		local id=50
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to  tightly binds the soul to the body. This will delay death due to massive hit point loss, but will not stop a character from going unconscious. If a preserved character's hit points are too low when the spell wears off, he or she will die.\nThis effect remains active until deactivated or lose consciousness.")
		
		--Protection from magic
		local id=75
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to affect the entire party at once, granting immunity to certain spells and monster abilities that cause debilitation conditions.  These are:  Poison, Disease, Stone, Paralyze, Weak, Death and Eradicated.\nThis effect remains active until deactivated or lose consciousness.")

		
		--pain reflection
		local id=95
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana.\nWhen a monster hits a character with Pain Reflection active, the monster takes damage equal to what it inflicted on the character.")
		
		--vampiric aura
		local id=91
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = "Enchants party weapons with the Vampiric ability.  Damage inflicted on monsters will be given to the weapon's wielder as extra hit points, up to his or her normal hit point maximum."
		sp.Name="Vampiric Aura"
		
		--Torch
		local id=1
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a flat amount of mana to increase the radius of light surrounding your party in the dark.\nThis effect remains active until deactivated or lose consciousness.")
		
		--wizard eye
		local id=12
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a flat amount of mana to show the locations of monsters and other points of interest while outdoors in the minimap.\nThis effect remains active until deactivated or lose consciousness.")
		
		--[[Invisibility
		local id=19
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a flat amount of mana\nInvisibility works on the minds of nearby creatures, making them unable to notice the party unless spoken to or attacked.  Any attack you make, regardless of whether or not it hits or misses, will break this spell. This spell can't be cast while hostile monsters are nearby.\nThis effect remains active until deactivated, attacking or lose consciousness. While active and no monster is in the nearbies, it gets casted automatically.")
		]]
		--Fly
		local id=21
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a flat amount of mana to grants the power of flight to your characters!  Only works outdoors, but it is very useful.  Fly will drain one spell point every five minutes it is in use (i.e. when you aren't touching the ground).\nThis effect remains active until deactivated or lose consciousness.")
		
		--Water walk
		local id=27
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a flat amount of mana\nOnly useful outdoors, Water Walk lets your characters walk along the surface of water without sinking.\nThis effect remains active until deactivated or lose consciousness.")
		
		
	else
		for i=1,#buffSpellList do
			local id=buffSpellList[i]
			Game.SpellsTxt[id].Description=storeBaseText[id]
		end
		
		--passive spell buffs
		Skillz.setDesc(const.Skills.Fire,5,"Grants 3 Intellect to all party per skill point")
		Skillz.setDesc(const.Skills.Air,5,"Grants 3 Speed to all party per skill point")
		Skillz.setDesc(const.Skills.Water,5,"Grants 3 Luck to all party per skill point")
		Skillz.setDesc(const.Skills.Earth,5,"Grants 3 Endurance to all party per skill point")
		Skillz.setDesc(const.Skills.Spirit,5,"Grants 3 Accuracy to all party per skill point")
		Skillz.setDesc(const.Skills.Mind,5,"Grants 3 Personality to all party per skill point")
		Skillz.setDesc(const.Skills.Body,5,"Grants 3 Might to all party per skill point")	
		
	end
end	

--store older Tooltips, need to be after any tooltip change
function events.GameInitialized2()
	oldSpellTooltips={}
	for i=1,132 do
		oldSpellTooltips[i]=Game.SpellsTxt[i].Description
	end
end

function events.PlayerCastSpell(t)
	if t.SpellId==const.Spells.SummonWisp then
		local nMon=Map.Monsters.High
		local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Light))
		local maxSpawns=m*2-3
		function events.Tick()
			events.Remove("Tick",1)
			if nMon==Map.Monsters.High then
				local currentSummoned=0
				for i=0, Map.Monsters.High do
					local mon=Map.Monsters[i]
					if mon.Id==99 and mon.HP>0 and mon.Ally==9999 then
						currentSummoned=currentSummoned+1
					end
				end
				if currentSummoned<maxSpawns then
					pseudoSpawnpoint{monster = 97,  x = Party.X, y = Party.Y, z = Party.Z, count = 1, powerChances = {0, 0, 100}, radius = 256, group = 9999,transform = function(mon) mon.ShowOnMap = true mon.Hostile = false mon.Velocity=350 mon.Ally=9999 end}
				end
			end
		end
	end
end

function getMaxMana(pl)
	if vars.MAWSETTINGS.buffRework=="ON" and vars.currentManaPool then
		local index=pl:GetIndex()
		for i=0, Party.High do
			local p=Party[i]
			if p:GetIndex()==index then
				if vars.currentManaPool[i] then
					return vars.currentManaPool[i]
				else
					local sp=pl:GetFullSP()
					return sp
				end
			end
		end
	else
		local sp=pl:GetFullSP()
		return sp
	end	
end


function events.CalcDamageToMonster(t)
	local data = WhoHitMonster()
	if data and data.Object and data.Player then
		if data.Object.Spell==18 and data.Object.SpellMastery>1 then
			monsterIndex=getClosestMonsterInRange(t.Monster,768)
			if monsterIndex~=nil then
				BeginGrabObjects()
				Game.SummonObjects(2060,t.Monster.X,t.Monster.Y,t.Monster.Z+100,0,1)
				local obj=GrabObjects()
				if not obj then return end
				local index=data.Player:GetIndex()
				local id=0
				for i=0, Party.High do
					if Party[i]:GetIndex()==index then
						id=i
					end
				end
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

--set reference coord and desired range
function getClosestMonsterInRange(mon,range)
	local X,Y,Z=mon.X,mon.Y,mon.Z
	local closestMonster = nil
	local closestDistance = math.huge
	local ignoreList={mon:GetIndex()}
	if Multiplayer and Multiplayer.in_game then
		local playerList=Multiplayer.client_monsters()
		for key,value in pairs(playerList) do
			table.insert(ignoreList, value)
		end
	end
	for i=0,Map.Monsters.high do
		distance=range+1
		local X2, Y2, Z2 = XYZ(Map.Monsters[i])
		if Map.Monsters[i].HP>0 then
			distance=((X-X2)^2+(Y-Y2)^2+(Z-Z2)^2)^0.5
		end
		if distance <= range and distance < closestDistance then
			if not table.find(ignoreList,i) then
				closestMonster = i
				closestDistance = distance
			end
		end
	end
	--will return as monster index
	return closestMonster
end

function events.KeyDown(t)
	if Game.CurrentScreen==8 and t.Key==const.Keys.TAB then
		local id=Game.CurrentPlayer
		if id<0 or id>Party.High then return end
		local pl=Party[id]
		local tabs={}
		for i=12,23 do
			if pl.Skills[i]>0 then
				table.insert(tabs,i-12)
			end
		end
        local firstTab=next(tabs)
        --if no spells known, do nothing
        if firstTab==nil then return end
		local currentTab=pl.SpellBookPage
        local currentIndexTab=table.find(tabs, currentTab)
        --check if spell page is already selected on valid page, set as first available page if not
        if currentIndexTab==nil then currentIndexTab=firstTab end
		local book=tabs[currentIndexTab+1]
		if not table.find(tabs,book) then
			book=tabs[1]
		end
		DoGameAction(87,book,0)
	end
end

--[[
local invisBooks={418, 1220, 1924}
local starburstBooks={421, 1223, 1927}

local booksPic={"sbair3","sbair3","sbair3"}
local booksPicGM={"sbair4","sbair4","sbair4"}
if disableSpellBookRework then
	booksPic={"item210","7item192","book4"}
    booksPicGM={"item209","7item193","book5"}
end

function events.LoadMap()
	if vars.insanityMode then
		for i=1,3 do
			Game.ItemsTxt[invisBooks[i] ].Picture=booksPicGM[i]
			Game.ItemsTxt[starburstBooks[i] ].Picture=booksPic[i]
		end
		Game.SpellsTxt[19].Master="n/a"
		Game.SpellsTxt[22].Master="This spell is as good as it will ever get!"
	else
		for i=1,3 do
			Game.ItemsTxt[invisBooks[i] ].Picture=booksPic[i]
			Game.ItemsTxt[starburstBooks[i] ].Picture=booksPicGM[i]
			Game.SpellsTxt[19].Master="Duration 15+1.5 minutes per point of skill"
			Game.SpellsTxt[22].Master="n/a"
		end
	end
end
]]
--[[
function events.CanLearnSpell(t)
	if vars.insanityMode then
		if t.Spell==const.Spells.Invisibility then
			t.NeedMastery = 4
		elseif t.Spell==const.Spells.Starburst then
			t.NeedMastery = 3
		end
	end
end
]]


function events.GameInitialized2()
	baseSchoolsTxtAssassin={}
	for i=1,5 do
		baseSchoolsTxtAssassin[i]={[12]=Skillz.getDesc(12,i), [13]=Skillz.getDesc(13,i), [14]=Skillz.getDesc(14,i), [15]=Skillz.getDesc(15,i)}
	end

	spellDesc2={}
	for key, value in pairs(assassinSpellList) do
		for i=1,#assassinSpellList[key] do
			local spellID=assassinSpellList[key][i]
			spellDesc2[spellID]={}
			spellDesc2[spellID]["Name"]=Game.SpellsTxt[value[i]].Name
			spellDesc2[spellID]["Description"]=Game.SpellsTxt[value[i]].Description
			spellDesc2[spellID]["Normal"]=Game.SpellsTxt[value[i]].Normal
			spellDesc2[spellID]["Expert"]=Game.SpellsTxt[value[i]].Expert
			spellDesc2[spellID]["Master"]=Game.SpellsTxt[value[i]].Master
			spellDesc2[spellID]["GM"]=Game.SpellsTxt[value[i]].GM
		end
	end

	
	function events.CalcStatBonusByItems(t)
		if t.Stat==const.Stats.SpellPoints and table.find(assassinClass, t.Player.Class) then
			local pl=t.Player
			local s,m=SplitSkill(pl:GetSkill(const.Skills.Earth))
			t.Result=m*10
		end
	end	
end

local bookStart={400,1202,1902}
local names={"fire","air","water","earth","spirit","mind","body","light","dark"}
function events.GameInitialized2()
	if disableSpellBookRework then return end
	local txt=Game.ItemsTxt
	for i=1, 9 do
		txt[970+i].NotIdentifiedName="Book"
		
		local increaser=(i-1)*11
		local mm6increaser=(i-1)*13
		local name="sb" .. names[i]
		for j=0,10 do
			local m=1
			if j>=10 then
				m=4
			elseif j>6 then
				m=3
			elseif j>3 then
				m=2
			end
			txt[bookStart[1]+j+increaser].Picture=name .. m
			txt[bookStart[2]+j+increaser].Picture=name .. m
			if j==5 then
				txt[bookStart[3]+j+mm6increaser+2].Picture=name .. 2
				txt[bookStart[3]+j+mm6increaser+1].Picture=name .. 2
				txt[bookStart[3]+j+mm6increaser].Picture=name .. 1
				txt[bookStart[3]+j+mm6increaser-1].Picture=name .. 1
			elseif j>5 then
				txt[bookStart[3]+j+2+mm6increaser].Picture=name .. m
			else
				txt[bookStart[3]+j+mm6increaser].Picture=name .. m
			end
		end
	end
	
	--unidentified books
	txt[971].Picture="sbfireu"
	txt[972].Picture="sbairu"
	txt[973].Picture="sbwateru"
	txt[974].Picture="sbearthu"
	txt[975].Picture="sbspiritu"
	txt[976].Picture="sbmindu"
	txt[977].Picture="sbbodyu"
	txt[978].Picture="sblightu"
	txt[979].Picture="sbdarku"
	txt[971].Name="Fire Magic Book"
	txt[972].Name="Air Magic Book"
	txt[973].Name="Water Magic Book"
	txt[974].Name="Earth Magic Book"
	txt[975].Name="Spirit Magic Book"
	txt[976].Name="Mind Magic Book"
	txt[977].Name="Body Magic Book"
	txt[978].Name="Light Magic Book"
	txt[979].Name="Dark Magic Book"
	txt[971].Notes="A scorched grimoire that radiates gentle heat; a heat-seal brands the cover, and the pages grow too hot to hold unless you're versed in Fire."
	txt[972].Notes="Feather-light pages hum with static; a whirling air-sigil scatters the lines to the wind, settling only for one trained in Air."
	txt[973].Notes="Damp vellum where ink ripples like tides; a water-ward dissolves every character into droplets unless a Water adept calls them back."
	txt[974].Notes="Heavy as quarried rock, grit packed in the spine; a stone-seal weighs the script down, rising into legible relief for those attuned to Earth."
	txt[975].Notes="A calm glow lingers between the leaves; a spirit-binding sigil veils the prayers, and they fade to silence without skill in Spirit."
	txt[976].Notes="Margins of tight glyphs that reorder themselves; a thought-lock scrambles the text into riddles unless a Mind disciple aligns it."
	txt[977].Notes="Thick, herb-scented vellum warm to the pulse; a vigor-ward stiffens the pages, relaxing only for the steady hands of Body practitioners."
	txt[978].Notes="A pale radiance seeps through the cover; a sun-seal flares too bright to read, dimming into clarity for those trained in Light."
	txt[979].Notes="Ink like pooled night that drinks the torchglow; a shadow-ward devours the lines, revealing them only to readers skilled in Dark."
	
	for i=971, 979 do
		Game.ItemsTxt[i].SpriteIndex=78
	end

end

local mastery={"Novice","Expert","Master","Grandmaster"}
function events.BuildItemInformationBox(t)
	local it=t.Item
	if it.Number>=971 and it.Number<980 then
		local identify=Game.ItemsTxt[it.BonusStrength].IdRepSt
		local m=1
		if identify>=15 then
			m=4
		elseif identify>=10 then
			m=3
		elseif identify>=5 then
			m=2
		end
		local id=Game.CurrentPlayer
		if id<0 or id>Party.High then return end
		local pl=Party[Game.CurrentPlayer]
		local s2,m2=SplitSkill(pl.Skills[t.Item.Number-959])
		if m2>=m then
			it.Number=it.BonusStrength
		end
		if t.Description then
			local name=Skillz.getName(t.Item.Number-959)
			t.Description=t.Description .. StrColor(255,0,0, "\n\nYou need at least " .. mastery[m] .. " skill in " ..  name .. " to open the book")
		end
	end
end

function events.ItemGenerated(t)
	if disableSpellBookRework then return end
	if Game.HouseScreen==2 or Game.HouseScreen==95 then return end
	local it=t.Item
	if (it.Number>=400 and it.Number<=498) then
		it.BonusStrength=it.Number
		local school=math.ceil((it.Number-399)/11)
		it.Number=970+school
	end
	if (it.Number>=1202 and it.Number<=1300) then
		it.BonusStrength=it.Number
		local school=math.ceil((it.Number-1201)/11)
		it.Number=970+school
	end
	if (it.Number>=1902 and it.Number<=2018) then
		it.BonusStrength=it.Number
		local school=math.ceil((it.Number-1901)/13)
		it.Number=970+school
	end
end

function events.CanCastTownPortal(t)
	if vars.madnessMode and (Party.EnemyDetectorYellow or Party.EnemyDetectorRed) then
		t.CanCast=false
		function events.Tick() 
			events.Remove("Tick", 1)
			Game.ShowStatusText("Madness is not a place for cowards")
		end
	end
end

--target closest enemy if there are no monster in the mouse

function events.PlayerCastSpell(t)
	BeginGrabObjects()
	local targetSpell=t.SpellId
	if Mouse:GetTarget().Kind==3 then return end --monster in the mouse
	function events.Tick()
		events.Remove("Tick",1)
		local obj=GrabObjects()
		if not obj then 
			--debug.Message("No Object")
			return 
		end
		if obj.Spell~=targetSpell then 
			--debug.Message("Wrong Object")
			--debug.Message(dump(obj))
			return 
		end
		local MonList = Game.GetMonstersInSight()
		local closestEnemyDistance=math.huge
		local changeTarget=false
		local target=-1
		local ai=const.AIState
		local lim = Map.Monsters.High
		for i=1,#MonList do
			local tar=MonList[i]
			if tar<=lim then
				local mon=Map.Monsters[tar]
				if  mon.AIState~=ai.Dead and mon.AIState~=ai.Invisible and mon.AIState~=ai.Removed and mon.ShowAsHostile and mon.Hostile then 
					local distance=getDistanceToMonster(mon)
					if distance<closestEnemyDistance then
						changeTarget=true
						target=tar
						closestEnemyDistance=distance
					end
				end
			end
		end
		if changeTarget then
			obj.Target=3+target*8
		end
	end		
end


function events.MonsterAttacked(t)
	data=WhoHitMonster()
	if data.Spell==111 then
		data.Spell=200
		data.Object.Spell=200
	elseif data.Spell==99 then
		data.Spell=201
		data.Object.Spell=201
	end
end

--[[
ironman code
function events.PartyDies(t)
	t.Handled=true
	local gold=Party.Gold
	local continentId=TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	function events.Tick()
		events.Remove("Tick",1)
		local lvl1=vars.MMLVL[1]
		local lvl2=vars.MMLVL[2]
		local lvl3=vars.MMLVL[3]
		local lvl4=vars.MMLVL[4]
		--local MapsToStart = {"out01.odm", "7out01.odm", "oute3.odm", "oute3.odm"}
		for i=0,Party.High do
			local pl=Party[i]
			for j=0,pl.Conditions.High do
				pl.Conditions[j]=0
			end
			pl.HP=GetMaxHP(pl)
			pl.SP=getMaxMana(pl)
		end
		--ForceStartNewGame(MapsToStart[continentId], true)
		ForceStartNewGame("oute3.odm", true)
		Party.Gold=gold
		vars.MMLVL[1]=lvl1
		vars.MMLVL[2]=lvl2
		vars.MMLVL[3]=lvl3
		vars.MMLVL[4]=lvl4
	end
end

-- player's death
local i1, u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.i1, mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer

local code_backup = {}
local hook_code = {}

local std_events = events
function mulhook(addr, backup_size, htype, f)
	local hookf = htype == 2 and mem.autohook2 or mem.autohook

	mem.IgnoreProtection(true)
	code_backup[addr] = mstr(addr, backup_size, true)
	hookf(addr, f)
	hook_code[addr] = mstr(addr, backup_size, true)
	mem.IgnoreProtection(false)
end
mulhook(0x4614d4, 6, 2, function(d)
	local t = {Handled = false}
	events.call("PartyDies", t)
	if t.Handled then
		d:push(0x461856)
		return true
	end
end)

]]

function events.Tick()
	if vars.insanityMode then
		if Party.SpellBuffs[11].ExpireTime>=Game.Time then
			if Party.EnemyDetectorRed then
				Party.SpellBuffs[11].ExpireTime=0
			end
		end
	end
end
