local u1, u2, u4, i1, i2, i4 = mem.u1, mem.u2, mem.u4, mem.i1, mem.i2, mem.i4
local hook, autohook, autohook2, asmpatch = mem.hook, mem.autohook, mem.autohook2, mem.asmpatch
local max, min, floor, ceil, round, random = math.max, math.min, math.floor, math.ceil, math.round, math.random
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
	--int/pers bonus
	local persBonus=pl:GetPersonality()
	local intBonus=pl:GetIntellect()
	local statBonus=math.max(persBonus,intBonus)/1000
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
	
	local currentPl=Game.CurrentPlayer
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
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points"))
			end
		end
		--end of healing calculation
		if t.TargetKind == 3 then
			t.MultiplayerData[1]=math.round(totHeal) --total heal
			t.MultiplayerData[2]=gotCrit --crit 
		elseif t.TargetKind == 4 and t.RemoteData then
			local healData = t.RemoteData
			local name = Multiplayer.client_name(t.RemoteData.client_id)

			Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+healData[1],Party[t.TargetId]:GetFullHP())
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
			Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+math.round(totHeal),Party[t.TargetId]:GetFullHP())
			if Party[t.TargetId].HP>0 then
				Party[t.TargetId].Unconscious=0
			end
		end
	end
	
	--heroism
	if t.SpellId==const.Spells.Heroism and not buffRework then
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
	
	--resurrection
	if t.SpellId == 55 then
		if not t.RemoteData then
			local sp=healingSpells[55]
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Spirit))
			local baseHeal=sp.Base[m]+sp.Scaling[m]*s
			
			local mult, gotCrit=getHealSpellMultiPlier(t.Player)
			
			totHeal=baseHeal*mult

			if gotCrit then
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points"))
			end
		end
		--end of healing calculation
		if t.TargetKind == 3 then
			t.MultiplayerData[1]=math.round(totHeal) --total heal
			t.MultiplayerData[2]=gotCrit --crit 
			return
		elseif t.TargetKind == 4 and t.RemoteData then
			local healData = t.RemoteData
			local name = Multiplayer.client_name(t.RemoteData.client_id)

			Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+healData[1],Party[t.TargetId]:GetFullHP())
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
					Party[t.TargetId].HP=math.max(hp+math.round(totHeal), 1)
				end
			else
				Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+math.round(totHeal),Party[t.TargetId]:GetFullHP())
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
			totHeal=math.round(totHeal-(5+(m+1)*s))
			if gotCrit then
				Game.ShowStatusText(string.format("You Heal for " .. math.round(tooltipHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. math.round(tooltipHeal) .. " Hit points"))
			end
		end
		--end of healing calculation
		if t.TargetKind == 3 and t.MultiplayerData then
			t.MultiplayerData[1]=math.round(totHeal) --bonus heal
			t.MultiplayerData[2]=gotCrit --crit 
			t.MultiplayerData[3]=math.round(tooltipHeal) --total heal
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
			Party[t.TargetId].HP=Party[t.TargetId].HP+math.round(totHeal)
			if Party[t.TargetId].HP>0 then
				Party[t.TargetId].Unconscious=0
			end
		end
	end
	
	--REGENERATION
	if t.SpellId==71 and not buffRework then
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
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points"))
			end
		end
		--end of healing calculation
		if t.TargetKind == 3 then
			t.MultiplayerData[1]=math.round(totHeal) --total heal
			t.MultiplayerData[2]=gotCrit --crit 
			return
		elseif t.TargetKind == 4 and t.RemoteData then
			local healData = t.RemoteData
			local name = Multiplayer.client_name(t.RemoteData.client_id)

			Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+healData[1],Party[t.TargetId]:GetFullHP())
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
			Party[t.TargetId].HP=math.min(Party[t.TargetId].HP+math.round(totHeal),Party[t.TargetId]:GetFullHP())
			if Party[t.TargetId].HP>0 then
				Party[t.TargetId].Unconscious=0
			end
		end
	end
	
	--protection from Magic, no need for online code
	if t.SpellId==75 and not buffRework then
		local s,m = SplitSkill(t.Player:GetSkill(const.Skills.Body))
		if m==4 then
			t.Skill=10
		else
			t.Skill=math.min(t.Skill,10)
		end
	end
	
	--power cure
	if t.SpellId==77 then
		if not t.RemoteData then
			local sp=healingSpells[77]
			t.Skill=0
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Body))
			local baseHeal=sp.Base[m]+sp.Scaling[m]*s

			local mult, gotCrit=getHealSpellMultiPlier(t.Player)
			
			totHeal=baseHeal*mult

			--remove base heal
			tooltipHeal=totHeal
			totHeal=math.round(totHeal-(10+5*s))
			if gotCrit then
				Game.ShowStatusText(string.format("You Heal the Party for " .. math.round(tooltipHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal the Party for " .. math.round(tooltipHeal) .. " Hit points"))
			end
		end
		--end of healing calculation
		if not t.RemoteData then
			for i=0,Party.High do
				Party[i].HP=Party[i].HP+totHeal
				if Party[t.TargetId].HP>0 then
					Party[t.TargetId].Unconscious=0
				end
			end
			if t.MultiplayerData then
				t.MultiplayerData[1]=math.round(totHeal) --bonus heal
				t.MultiplayerData[2]=gotCrit --crit 
				t.MultiplayerData[3]=math.round(tooltipHeal) --total heal
			end
		elseif t.RemoteData then
			local healData = t.RemoteData
			local name = Multiplayer.client_name(t.RemoteData.client_id)
			for i=0,Party.High do
				Party[i].HP=Party[i].HP+healData[1]
				if Party[t.TargetId].HP>0 then
					Party[t.TargetId].Unconscious=0
				end
			end
			if	healData[2] then
				Game.ShowStatusText(string.format(name .. " heals the Party for " .. healData[3] .. " hit points"))
			else
				Game.ShowStatusText(string.format(name .. " heals the Party for " .. healData[3] .. " hit points(crit)"))
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
--Day of Protection
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

	--passive spell buffs
	if not buffRework then
		Skillz.setDesc(const.Skills.Fire,5,"Grants 3 Intellect to all party per skill point")
		Skillz.setDesc(const.Skills.Air,5,"Grants 3 Speed to all party per skill point")
		Skillz.setDesc(const.Skills.Water,5,"Grants 3 Luck to all party per skill point")
		Skillz.setDesc(const.Skills.Earth,5,"Grants 3 Endurance to all party per skill point")
		Skillz.setDesc(const.Skills.Spirit,5,"Grants 3 Accuracy to all party per skill point")
		Skillz.setDesc(const.Skills.Mind,5,"Grants 3 Personality to all party per skill point")
		Skillz.setDesc(const.Skills.Body,5,"Grants 3 Might to all party per skill point")	
	end
end

-- shared life overflow fix
function randomizeHP()
	for i, pl in Party do
		pl.HP = random(1, pl:GetFullHP())
	end
end

-- TODO: test very negative amounts (like -50000), they asserted previously
function doSharedLife(amount, spellQueueData)
	spellQueueData = spellQueueData or {}
	-- for each iteration, try to top up lowest HP deficit party member, increasing others' HP along the way
	local function shouldParticipate(pl)
		if pl.HP<0 then
			return totalHP>0
		end
		return pl.Dead == 0 and pl.Eradicated == 0 and pl.Stoned == 0 -- as in default code
	end
	
	--calculate total HP
	totalHP=0
	for i=0,Party.High do
		totalHP=totalHP+Party[i].HP
	end
	
	local activePlayers = {}
	local fullHPs = {}
	amount = amount or 0
	
	--skill scaling
	local id=Game.CurrentPlayer
	if id>=0 and id<=Party.High then
		local pl=Party[id]

		local s,m
		if spellQueueData.FromScroll then
			s,m = spellQueueData.Skill, spellQueueData.Mastery
		else -- could simply always use table data if it's provided, but this code gets player by CurrentPlayer, not by queue data, so leaving it for now to not change behavior unintentionally
			s,m = SplitSkill(pl:GetSkill(const.Skills.Spirit))
		end
		local healingAmount=0
		--remove base bonus
		if m==3 then
			healingAmount=healingAmount-s*3
		elseif m==4 then
			healingAmount=healingAmount-s*4
		end
		
		local sp=healingSpells[54]
		local baseHeal=sp.Base[m]+sp.Scaling[m]*s/2
		
		local mult, gotCrit=getHealSpellMultiPlier(pl)
		
		totHeal=baseHeal*mult

		if gotCrit then
			Game.ShowStatusText(string.format("Shared Life heals for " .. math.round(totHeal*2) .. " Hit points(crit)"))
		else
			Game.ShowStatusText(string.format("Shared Life heals for " .. math.round(totHeal*2) .. " Hit points"))
		end
		amount=amount+totHeal-healingAmount
		
	end
	
	for i, pl in Party do
		if shouldParticipate(pl) then
			table.insert(activePlayers, pl)
			fullHPs[pl:GetIndex()] = pl:GetFullHP()
			amount = amount + pl.HP
			pl.HP = 0
		end
	end
	local affectedPlayers = table.copy(activePlayers)
	local pool = amount
	local steps = 0
	while amount > 0 and #activePlayers > 0 do
		steps = steps + 1
		local minDeficit = math.huge
		for i, pl in ipairs(activePlayers) do
			local def = fullHPs[pl:GetIndex()] - pl.HP
			if def > 0 then
				minDeficit = min(minDeficit, def)
			end
		end

		local part = minDeficit
		if minDeficit * #activePlayers > amount then
			part = amount:div(#activePlayers)
		end

		amount = amount - part * #activePlayers

		local newPlayers = {}
		for i, pl in ipairs(activePlayers) do
			pl.HP = pl.HP + part
			if part == 0 and amount > 0 then
				pl.HP = pl.HP + 1
				amount = amount - 1
			end
			if pl.HP ~= fullHPs[pl:GetIndex()] then
				table.insert(newPlayers, pl)
			end
		end
		activePlayers = newPlayers
	end
	local result = 0
	local everyoneFull = true
	for i, pl in ipairs(affectedPlayers) do
		result = result + pl.HP
		if pl.HP > 0 then
			pl.Unconscious = 0
		end
		if pl.HP ~= pl:GetFullHP() then
			everyoneFull = false
		end
	end
	--assert((pool == result) or everyoneFull, format("Pool %d, result %d, everyoneFull: %s", pool, result, everyoneFull))
	--printf("Steps: %d", steps)
	return affectedPlayers
	--debug.Message(format("%d HP left", amount))
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
	if Game.BolsterAmount>100 then
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
TimerPeriod=const.Minute/2
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
	if not buffRework then
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

function events.AfterLoadMap()
	Timer(elementalBuffs, TimerPeriod, true)
end

--let town portal scroll to be reused if solo
function events.PlayerCastSpell(t)
	if Party.High==0 and t.IsSpellScroll then
		if t.SpellId==31 then
			evt.Add("Items",330)
		elseif t.SpellId==33 then
			evt.Add("Items",332)
		elseif t.SpellId==21 then
			evt.Add("Items",320)
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

--ascension tier 
function getAscensionTier(skill,spellID, index)
	local spelltier=spellID%11
	if spelltier==0 then
		spelltier=11
	end
	ascensionTier=math.min(math.floor(skill/11),6)
	if skill>=77 then
		ascensionTier=7
	elseif spelltier<=skill%11  then
		ascensionTier=ascensionTier+1
	end
	local id=index or Party[Game.CurrentPlayer]:GetIndex()
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 25) then
		ascensionTier=ascensionTier+1
	end
	return ascensionTier
end

masteryName={"Normal", "Expert", "Master", "GM"}
function events.Action(t)
	if t.Action==25 and autoTargetHeals then
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
		if spellCast==68 and pl.RecoveryDelay==0 then
			local sp=healingSpells[68]
			local s,m=SplitSkill(pl:GetSkill(const.Skills.Body))
			local cost=Game.Spells[68]["SpellPoints" .. masteryName[m]]
			if pl.SP<cost then return end
			t.Handled=true
			pl.SP=pl.SP-cost

			local baseHeal=sp.Base[m]+sp.Scaling[m]*s
			
			local mult, gotCrit=getHealSpellMultiPlier(pl)
			
			totHeal=baseHeal*mult
			
			if gotCrit then
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points"))
			end

			min_index = pickLowestPartyMember()
			--apply heal
			mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, mem.u4[0x75CE00]), const.Spells.Heal, min_index)
			Party[min_index].HP=math.min(Party[min_index].HP+totHeal, Party[min_index]:GetFullHP())	
			--bug fix
			if Party[min_index].HP>0 then
			Party[min_index].Unconscious=0
			end
			local haste=math.floor(pl:GetSpeed()/10)
			local delay=getSpellDelay(pl,spellCast)
			pl:SetRecoveryDelay(delay)
			evt.PlaySound(16010)
			pl.Expression=40
			Party.SpellBuffs[11].ExpireTime=0 --invisibility
		elseif spellCast==74 and pl.RecoveryDelay==0 then
			local sp=healingSpells[74]
			local s,m=SplitSkill(pl:GetSkill(const.Skills.Body))
			local cost=Game.Spells[74]["SpellPoints" .. masteryName[m]]
			if pl.SP<cost then return end
			t.Handled=true
			pl.SP=pl.SP-cost
			local baseHeal=sp.Base[m]+sp.Scaling[m]*s
			
			local mult, gotCrit=getHealSpellMultiPlier(pl)
			
			totHeal=baseHeal*mult
			if gotCrit then
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points"))
			end

			min_index = pickLowestPartyMember()
			--apply heal
			mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, mem.u4[0x75CE00]), const.Spells.Heal, min_index)
			Party[min_index].HP=math.min(Party[min_index].HP+totHeal, Party[min_index]:GetFullHP())	
			--bug fix
			if Party[min_index].HP>0 then
			Party[min_index].Unconscious=0
			end
			Party[min_index].Disease1=0
			Party[min_index].Disease2=0
			Party[min_index].Disease3=0
			local haste=math.floor(pl:GetSpeed()/10)
			local delay=getSpellDelay(pl,spellCast)
			pl:SetRecoveryDelay(delay)
			evt.PlaySound(16070)
			pl.Expression=40
			Party.SpellBuffs[11].ExpireTime=0 --invisibility
		elseif spellCast==49 and pl.RecoveryDelay==0 then
			local sp=healingSpells[49]
			local s,m=SplitSkill(pl:GetSkill(const.Skills.Spirit))
			local cost=Game.Spells[49]["SpellPoints" .. masteryName[m]]
			if pl.SP<cost then return end
			t.Handled=true
			pl.SP=pl.SP-cost
			local baseHeal=sp.Base[m]+sp.Scaling[m]*s
			
			local mult, gotCrit=getHealSpellMultiPlier(pl)
			
			totHeal=baseHeal*mult
			if gotCrit then
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal) .. " Hit points"))
			end

			min_index = pickLowestPartyMember()
			--apply heal
			mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, mem.u4[0x75CE00]), const.Spells.Heal, min_index)
			Party[min_index].HP=math.min(Party[min_index].HP+totHeal, Party[min_index]:GetFullHP())
			--bug fix
			if Party[min_index].HP>0 then
			Party[min_index].Unconscious=0
			end
			Party[min_index].Cursed=0
			local haste=math.floor(pl:GetSpeed()/10)
			local delay=getSpellDelay(pl,spellCast)
			pl:SetRecoveryDelay(delay)
			evt.PlaySound(14040)
			pl.Expression=40
			Party.SpellBuffs[11].ExpireTime=0 --invisibility
		end
	end
end


----------------------------------------
--CC REWORK
----------------------------------------
CCMAP={
	[const.Spells.Stun]=	{["Duration"]=const.Minute,["ChanceMult"]=0.03, ["BaseCost"]=1, ["ScalingCost"]=10},
	[const.Spells.Slow]=	{["Duration"]=const.Minute*4, ["ChanceMult"]=0.03, ["BaseCost"]=1, ["ScalingCost"]=3, ["School"]=const.Skills.Earth, ["DamageKind"]=const.Damage.Earth,["Debuff"]=const.MonsterBuff.Slow},
	[60]=					{["Duration"]=const.Minute*6, ["ChanceMult"]=0.05, ["BaseCost"]=5, ["ScalingCost"]=4, ["School"]=const.Skills.Mind, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Charm},--Mind Charm, has no const value, due to dark elf one overwriting
	[const.Spells.Charm]=	{["Duration"]=const.Minute*3, ["ChanceMult"]=0.05, ["BaseCost"]=1, ["ScalingCost"]=4, ["School"]=const.Skills.DarkElfAbility, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Charm},--dark elf one
	[const.Spells.Berserk]=	{["Duration"]=const.Minute*1, ["ChanceMult"]=0.02, ["BaseCost"]=1, ["ScalingCost"]=1.5, ["School"]=const.Skills.Mind, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Berserk},
	[const.Spells.MassFear]={["Duration"]=const.Minute*4, ["ChanceMult"]=0.1, ["BaseCost"]=1, ["ScalingCost"]=0.5, ["School"]=const.Skills.Mind, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Fear},
	[const.Spells.Fear]=	{["Duration"]=const.Minute*2, ["ChanceMult"]=0.005, ["BaseCost"]=1, ["ScalingCost"]=2, ["School"]=const.Skills.Mind, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Fear},
	[const.Spells.Enslave]=	{["Duration"]=const.Minute*3, ["ChanceMult"]=0.07, ["BaseCost"]=1, ["ScalingCost"]=1.5, ["School"]=const.Skills.Mind, ["DamageKind"]=const.Damage.Mind, ["Debuff"]=const.MonsterBuff.Enslave},
	[const.Spells.Paralyze]={["Duration"]=const.Minute*3, ["ChanceMult"]=0.04, ["BaseCost"]=1, ["ScalingCost"]=3, ["School"]=const.Skills.Light, ["DamageKind"]=const.Damage.Light,["Debuff"]=const.MonsterBuff.Paralyze},	
[const.Spells.ShrinkingRay]={["Duration"]=const.Minute*3, ["ChanceMult"]=0.01, ["BaseCost"]=1, ["ScalingCost"]=2, ["School"]=const.Skills.Dark, ["DamageKind"]=const.Damage.Dark,["Debuff"]=const.MonsterBuff.ShrinkingRay},
[const.Spells.DarkGrasp]=	{["Duration"]=const.Minute*4, ["ChanceMult"]=0.07, ["BaseCost"]=1, ["ScalingCost"]=3, ["School"]=const.Skills.Dark, ["DamageKind"]=const.Damage.Dark, ["Debuff"]={const.MonsterBuff.ArmorHalved, const.MonsterBuff.Slow, const.MonsterBuff.DamageHalved, const.MonsterBuff.MeleeOnly}},																									
	[const.Spells.TurnUndead]={["Duration"]=const.Minute*4, ["ChanceMult"]=0.005, ["BaseCost"]=1, ["ScalingCost"]=0.5, ["School"]=const.Skills.Spirit, ["DamageKind"]=const.Damage.Spirit, ["Debuff"]=const.MonsterBuff.Fear},	
	[const.Spells.ControlUndead]={["Duration"]=const.Minute*3, ["ChanceMult"]=0.07, ["BaseCost"]=1, ["ScalingCost"]=1.5, ["School"]=const.Skills.Dark, ["DamageKind"]=const.Damage.Dark, ["Debuff"]=const.MonsterBuff.Enslave},
}

function getCCDiffMult(bolster)
	local diffMult=math.max(((bolster-100)/200)+1,1)
	if bolster==600 then 
		diffMult=3
	end
	return diffMult
end

function events.Action(t)
	local id=Game.CurrentPlayer
	if id<0 or id>Party.High then return end
	local mult=getCCDiffMult(Game.BolsterAmount)
	for key, value in pairs(CCMAP) do
		local lvl=Party[id].LevelBase
		local baseCost=value.BaseCost
		local scalingCost=value.ScalingCost
		local cost=math.round((baseCost+(lvl/scalingCost))*(1+mult)) --edit here to change mana cost
		Game.Spells[key]["SpellPointsNormal"]=cost
		Game.Spells[key]["SpellPointsExpert"]=cost
		Game.Spells[key]["SpellPointsMaster"]=cost
		Game.Spells[key]["SpellPointsGM"]=cost
	end
	--dragon fix
	Game.Spells[122]["SpellPointsNormal"]=15
	Game.Spells[122]["SpellPointsExpert"]=15
	Game.Spells[122]["SpellPointsMaster"]=25
	Game.Spells[122]["SpellPointsGM"]=30
end

--Tooltips
function events.GameInitialized2()
	for key, value in pairs(CCMAP) do
		local duration=value.Duration/const.Minute*2
		local bonus=value.ChanceMult*100
		Game.SpellsTxt[key].Description=Game.SpellsTxt[key].Description .. "\n\nDuration: " .. duration .. " seconds" .. "\nBonus Hit chance per skill level: " .. bonus .. "%"
	end
end

function events.PlayerCastSpell(t)
	if CCMAP[t.SpellId] then
		if t.SpellId==const.Spells.Stun then return end --stun is handled differently
		local resistance={}
		local level={}
		local cc=CCMAP[t.SpellId]
		for i=0,Map.Monsters.High do
			local mon=Map.Monsters[i]
			local res=mon.Resistances[cc.DamageKind]
			local lvl=mon.Level
				resistance[i]=res
				level[i]=lvl
			local s,m=SplitSkill(t.Player:GetSkill(cc.School))
			local newLevel=calcEffectChance(lvl, res, s, cc.ChanceMult, mon)
			local hit=(30/(30+newLevel/4))
			if hit>math.random() then
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
			for i=0,Map.Monsters.High do
				local mon=Map.Monsters[i]
				mon.Level=level[i]
				mon.Resistances[cc.DamageKind]=resistance[i]
				if type(cc.Debuff)=="table" then
					for v =1,4 do 
						local debuff=mon.SpellBuffs[cc.Debuff[v]]
						debuff.ExpireTime=math.min(debuff.ExpireTime, Game.Time+cc.Duration/(1+mult/6))
					end
				else
					local debuff=mon.SpellBuffs[cc.Debuff]
					debuff.ExpireTime=math.min(debuff.ExpireTime, Game.Time+cc.Duration/(1+mult/6))
				end
			end
		end
	end
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
	newLevel=math.max(math.round(newRes*4),0)
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
	
	spells={2,6,7,8,9,10,11,15,18,20,22,24,26,29,32,37,39,41,43,44,52,59,65,70,76,78,79,84,87,90,93,97,98,99,103,111}
	lastIndex=-1 --used later

	--if you change diceMin or values that are 0 remember to update the tooltip manually 
	spellPowers =
		{
			[2] = {dmgAdd =8, diceMin = 1, diceMax = 1, },--fire bolt
			[6] = {dmgAdd = 0, diceMin = 1, diceMax = 8, },--fireball
			[7] = {dmgAdd = 0, diceMin = 1, diceMax = 8, },--fire spike, the only spell with damage depending on mastery, fix in events.calcspelldamage
			[8] = {dmgAdd = 10, diceMin = 1, diceMax = 30, },--immolation
			[9] = {dmgAdd = 2, diceMin = 1, diceMax = 1, },--meteor shower
			[10] = {dmgAdd = 12, diceMin = 1, diceMax = 7, },--inferno
			[11] = {dmgAdd = 18, diceMin = 1, diceMax = 18, },--incinerate
			[15] = {dmgAdd = 0, diceMin = 1, diceMax = 4, },--sparks
			[18] = {dmgAdd = 13, diceMin = 1, diceMax = 8, },--lightning bolt
			[20] = {dmgAdd = 20, diceMin = 1, diceMax = 12, },--implosion
			[22] = {dmgAdd = 5, diceMin = 1, diceMax = 1, },--starburst
			[24] = {dmgAdd = 5, diceMin = 1, diceMax = 3, },--poison spray
			[26] = {dmgAdd = 6, diceMin = 1, diceMax = 7, },--ice bolt
			[29] = {dmgAdd = 2, diceMin = 1, diceMax = 14, },--acid burst
			[32] = {dmgAdd = 6, diceMin = 1, diceMax = 6, },--ice blast
			[37] = {dmgAdd = 8, diceMin = 1, diceMax = 5, },--deadly swarm
			[39] = {dmgAdd = 7, diceMin = 1, diceMax = 7, },--blades
			[41] = {dmgAdd = 8, diceMin = 1, diceMax = 8, },--rock blast
			[43] = {dmgAdd = 0, diceMin = 1, diceMax = 2, },--death blossom
			[44] = {dmgAdd = 15, diceMin = 0.5, diceMax = 0.5, },--mass distorsion, nerfed
			[52] = {dmgAdd = 10, diceMin = 2, diceMax = 8, },--spirit lash
			[59] = {dmgAdd = 12, diceMin = 1, diceMax = 6, },--mind blast
			[65] = {dmgAdd = 25, diceMin = 1, diceMax = 25, },--psychic shock
			[70] = {dmgAdd = 4, diceMin = 1, diceMax = 4, },--harm
			[76] = {dmgAdd = 20, diceMin = 1, diceMax = 5, },--flying fist
			[78] = {dmgAdd = 12, diceMin = 1, diceMax = 2, },--light bolt
			[79] = {dmgAdd = 12, diceMin = 1, diceMax = 8, },--destroy undead
			[84] = {dmgAdd = 25, diceMin = 2, diceMax = 5, },--prismatic light
			[87] = {dmgAdd = 50, diceMin = 1, diceMax = 50, },--sunray
			[90] = {dmgAdd = 15, diceMin = 1, diceMax = 9, },--toxic cloud
			[93] = {dmgAdd = 0, diceMin = 1, diceMax = 7, },--shrapmetal
			[97] = {dmgAdd = 0, diceMin = 1, diceMax = 28, },--dragon breath
			[98] = {dmgAdd = 50, diceMin = 1, diceMax = 1, },--armageddon
			[99] = {dmgAdd = 25, diceMin = 1, diceMax = 5, },--souldrinker
			[103] = {dmgAdd = 46, diceMin = 1, diceMax = 28, },--darkfire bolt
			[111] = {dmgAdd = 21, diceMin = 1, diceMax = 7, },--lifedrain scales with mastery, fixed in calcspelldamage
			--[123] = {dmgAdd = 0, diceMin = 1, diceMax = 25, },--scales with breath damage
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
	local ascensionTier=0
	if data and data.Player then
		local s,m = SplitSkill(data.Player.Skills[const.Skills.Learning])
		local id=data.Player:GetIndex()
		if table.find(elementalistClass, data.Player.Class) then
			s=0
			m=4
			for i=12,15 do
				local skill = SplitSkill(data.Player.Skills[i])
				s=s+skill
			end
			s=s/4
			vars.eleStacks=vars.eleStacks or {}
			vars.eleStacks[id]=vars.eleStacks[id] or 0
		end
		diceMin, diceMax, damageAdd, ascensionTier = ascendSpellDamage(s, m, t.Spell, data.Player:GetIndex())
		if table.find(elementalistClass, data.Player.Class) then
			diceMax=math.round(diceMax*(1+vars.eleStacks[id]*0.1))
			damageAdd=math.round(damageAdd*(1+vars.eleStacks[id]*0.1))
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
				damage=(dmg1+dmg2)*1.2^ascensionTier
				if table.find(aoespells, t.Spell) then
					damage=damage/2.5
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
	if data and data.Player and data.Spell==44 then
		mult=1
		if massHPMULT[Game.BolsterAmount]=="doom" then
			local mon=t.Monster
			local lvl=getMonsterLevel(mon)
			mult=3.33*(1+lvl/75)
			if mon.NameId>=220 and mon.NameId<300 then
				mult=mult*2*(1+mon.Level/80)
			end
		else
			mult=massHPMULT[Game.BolsterAmount] or 1
		end
		t.Result=t.Result/mult^0.5
	end
	
end


function ascendSpellDamage(skill, mastery, spell, index)
	--empower spell buff
	local empowerMult=1
	if buffRework and vars.mawbuff[28] then
		local s, m=getBuffSkill(28)
		empowerMult=1+buffPower[5].Base[m]/100+buffPower[5].Scaling[m]/1000*s
	end
	
	diceMin=spellPowers[spell].diceMin*empowerMult
	diceMax=spellPowers[spell].diceMax*empowerMult
	damageAdd=spellPowers[spell].dmgAdd*empowerMult
	local ascensionLevel=getAscensionTier(skill,spell,index)
	if ascensionLevel>0 then
		-- old formula
		--diceMax=diceMax * (1+0.04 * skill * ascensionLevel)
		--damageAdd=damageAdd*(1+skill * (ascensionLevel+1) / 8)
		--diceMax=diceMax * (1+0.05 * skill * (ascensionLevel+1))
		--damageAdd=damageAdd*(1+skill^2 / 45 * (ascensionLevel+1)^2)
		
		damageAdd=damageAdd*(1+skill*0.15)*(ascensionLevel+0.25)^2.25 *1.2^ascensionLevel
		diceMax=diceMax * (1+0.03 * skill * (ascensionLevel+1)) *1.2^ascensionLevel
		
		--damageAdd=damageAdd*(1+skill*0.1 )*(ascensionLevel+1)^2*1.2^ascensionLevel
		--diceMax=diceMax*(1+0.15*(ascensionLevel+1)^2)*1.2^ascensionLevel
	end
	diceMin, diceMax, damageAdd = math.round(diceMin), math.round(diceMax), math.round(damageAdd)
	return diceMin, diceMax, damageAdd, ascensionLevel
end

function ascendSpellHealing(skill, mastery, spell, healM)
	base=healingSpells[spell].Base[healM]
	scaling=healingSpells[spell].Scaling[healM]
	local ascensionLevel=getAscensionTier(skill,spell)
	if ascensionLevel>0 then
		scaling=scaling * (1+0.01 * skill * ascensionLevel)*1.2^ascensionLevel
		base=base*(1+skill*0.05 * ascensionLevel)*1.8^ascensionLevel
		scaling, base = math.round(scaling), math.round(base)
	end
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
end

-----------------------
--Healing Spells
-----------------------
healingSpellList={const.Spells.RemoveCurse,const.Spells.Resurrection,const.Spells.Heal,const.Spells.CureDisease,const.Spells.PowerCure}



function ascension()
	index=Game.CurrentPlayer
	if index> Party.High then
		Game.CurrentPlayer=0
	end
	if index>=0 and index<=Party.High then
		local pl=Party[index]
		if table.find(dkClass, pl.Class) then return end --necessary to make dk tooltips work
		local level=pl.Skills[const.Skills.Learning]
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
		for v=1,#spells do 
			num=spells[v]
			local ascensionLevel=getAscensionTier(s,num)
			if ascensionLevel>=1 then
				for i=1,4 do
					Game.Spells[num]["SpellPoints" .. masteryName[i]]=math.min(spellCost[num][masteryName[i]]*(1+s*0.125)*1.8^(ascensionLevel)*(1-0.125*m),65000)
					if elementalist then
						local baseCost=math.round((spellCost[num][masteryName[i]]+vars.eleStacks[id])*(1+s*0.125)*1.5^(ascensionLevel)*(1-0.125*m))
						Game.Spells[num]["SpellPoints" .. masteryName[i]]=math.min(math.round(baseCost*(1+vars.eleStacks[id]*0.075)),65000)
					end
				end
			else
				for i=1,4 do
					Game.Spells[num]["SpellPoints" .. masteryName[i]]=spellCost[num][masteryName[i]]
				end
			end
			if num==44 then	
				Game.Spells[num]["SpellPointsGM"]=math.min(pl.LevelBase, 255)^1.6/12.5
			end
		end				
			
		--change tooltips according to ascended damage
		Game.SpellsTxt[2].Description=string.format("Launches a burst of fire at a single target.  Damage is %s+1-%s points of damage per point of skill in Fire Magic.   Firebolt is safe, effective and has a low casting cost.",dmgAddTooltip(s, m,2),diceMaxTooltip(s, m,2))
		Game.SpellsTxt[6].Description=string.format("Fires a ball of fire at a single target. When it hits, the ball explodes damaging all those nearby, including your characters if they're too close.  Fireball does 1-%s points of damage per point of skill in Fire Magic.",diceMaxTooltip(s, m,6))
		--fire spikes fix
		Game.SpellsTxt[7].Description="Drops a Fire Spike on the ground that waits for a creature to get near it before exploding.  Fire Spikes last until you leave the map or they are triggered."
		Game.SpellsTxt[7].Expert=string.format("Causes 1-%s points of damage per point of skill, 5 spikes maximum",diceMaxTooltip(s, m,7))
		Game.SpellsTxt[7].Master=string.format("Causes 1-%s points of damage per point of skill, 5 spikes maximum",math.round(diceMaxTooltip(s, m,7)/6*8))
		Game.SpellsTxt[7].GM=string.format("Causes 1-%s points of damage per point of skill, 5 spikes maximum",math.round(diceMaxTooltip(s, m,7)/6*10))
		----------------------------------------
		
		Game.SpellsTxt[8].Description=string.format("Reserve a mana percentage to surround your characters with a very hot fire that is only harmful to others.  The spell will deliver %s points of damage plus 1-%s per point of skill to all nearby monsters for as long as they remain in the area of effect.",dmgAddTooltip(s, m,8),diceMaxTooltip(s, m,8))
		Game.SpellsTxt[9].Description=string.format("Summons flaming rocks from the sky which fall in a large radius surrounding your chosen target.  Try not to be near the victim when you use this spell.  A single meteor does %s points of damage plus %s per point of skill in Fire Magic.  This spell only works outdoors.",dmgAddTooltip(s, m,9),diceMaxTooltip(s, m,9))
		Game.SpellsTxt[10].Description=string.format("Inferno burns all monsters in sight when cast, excluding your characters.  One or two castings can clear out a room of weak or moderately powerful creatures. Each monster takes %s points of damage plus %s per point of skill in Fire Magic.  This spell only works indoors.",dmgAddTooltip(s, m,10),diceMaxTooltip(s, m,10))
		Game.SpellsTxt[11].Description=string.format("Among the strongest direct damage spells available, Incinerate inflicts massive damage on a single target.  Only the strongest of monsters can expect to survive this spell.  Damage is %s points plus 1-%s per point of skill in Fire Magic.",dmgAddTooltip(s, m,11),diceMaxTooltip(s, m,11))
		Game.SpellsTxt[15].Description=string.format("Sparks fires small balls of lightning into the world that bounce around until they hit something or dissipate. It is hard to tell where they will go, so this spell is best used in a room crowded with small monsters. Each spark does 1-%s per point of skill in Air Magic.",diceMaxTooltip(s, m,15))
		Game.SpellsTxt[18].Description=string.format("Lightning Bolt discharges electricity from the caster's hand to a single target.  It always hits and does %s points plus 1-%s points of damage per point of skill in Air Magic.",dmgAddTooltip(s, m,18),diceMaxTooltip(s, m,18))
		Game.SpellsTxt[20].Description=string.format("Implosion is a nasty spell that affects a single target by destroying the air around it, causing a sudden inrush from the surrounding air, a thunderclap, and %s points plus 1-%s points of damage per point of skill in Air Magic.",dmgAddTooltip(s, m,20),diceMaxTooltip(s, m,20))
		Game.SpellsTxt[22].Description=string.format("Calls stars from the heavens to smite and burn your enemies.  Twenty stars are called, and the damage for each star is %s points plus %s per point of skill in Air Magic. Try not to get caught in the blast! This spell only works outdoors.",dmgAddTooltip(s, m,22),diceMaxTooltip(s, m,22))
		Game.SpellsTxt[24].Description=string.format("Sprays poison at monsters directly in front of your characters.  Damage is low, but few monsters have resistance to Water Magic, so it usually works.  Each shot does %s points of damage plus 1-%s per point of skill.",dmgAddTooltip(s, m,24),diceMaxTooltip(s, m,24))
		Game.SpellsTxt[26].Description=string.format("Fires a bolt of ice at a single target.  The missile does %s + 1-%s points of damage per point of skill in Water Magic.",dmgAddTooltip(s, m,26),diceMaxTooltip(s, m,26))
		Game.SpellsTxt[29].Description=string.format("Acid burst squirts a jet of extremely caustic acid at a single victim.  It always hits and does %s points of damage plus 1-%s per point of skill.",dmgAddTooltip(s, m,29),diceMaxTooltip(s, m,29))
		Game.SpellsTxt[32].Description=string.format("Fires a ball of ice in the direction the caster is facing.  The ball will shatter when it hits something, launching 7 shards of ice in all directions except the caster's.  The shards will ricochet until they strike a creature or melt.  Each shard does %s points of damage plus 1-%s per point of skill in Water Magic.",dmgAddTooltip(s, m,32),diceMaxTooltip(s, m,32))
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
		Game.SpellsTxt[111].Description=string.format("Lifedrain allows the vampire to damage his or her target and simultaneously heal based on the damage done in the Lifedrain.  This ability does %s points of damage plus 1-%s points of damage per skill.",dmgAddTooltip(s, m,111),diceMaxTooltip(s, m,111))
		Game.SpellsTxt[111].Master=string.format("Damage %s points plus 1-%s per point of skill",math.round(dmgAddTooltip(s, m,111)/3*5),math.round(diceMaxTooltip(s, m,111)/3*5))
		Game.SpellsTxt[111].GM=string.format("Damage %s points plus 1-%s per point of skill",math.round(dmgAddTooltip(s, m,111)/3*7),math.round(diceMaxTooltip(s, m,111)/3*7))
		
		for i=1, #spells do
			local ascensionLevel=getAscensionTier(s,spells[i])
			if spells[i]~=44 then
				if ascensionLevel>=1 then
					if ascensionLevel==8 then
						ascensionLevel="max"
					end
					Game.SpellsTxt[spells[i]].Description=Game.SpellsTxt[spells[i]].Description .. "\n\nAscension level: " .. ascensionLevel
				else
					Game.SpellsTxt[spells[i]].Description=Game.SpellsTxt[spells[i]].Description .. "\n\nNot Ascended"
				end
			end
		end
		
		-----------------------
		--Healing Spells
		-----------------------
		healingSpells={
			[const.Spells.RemoveCurse]=    {["Cost"]={0,5,10,20}, ["Base"]={0,10,15,25}, ["Scaling"]={0,3,4,5}},
			[const.Spells.SharedLife]=    {["Cost"]={0,0,25,40}, ["Base"]={0,0,0,0}, ["Scaling"]={0,0,7,9}},
            [const.Spells.Resurrection]={["Cost"]={0,0,0,100}, ["Base"]={0,0,0,100}, ["Scaling"]={0,0,0,14}},
            [const.Spells.Heal]=        {["Cost"]={2,4,6,8}, ["Base"]={4,6,8,10}, ["Scaling"]={1,2,3,4}},
            [const.Spells.CureDisease]=    {["Cost"]={0,0,15,25}, ["Base"]={0,0,15,25}, ["Scaling"]={0,0,5,7}},
            [const.Spells.PowerCure]=    {["Cost"]={0,0,0,30}, ["Base"]={0,0,0,10}, ["Scaling"]={0,0,0,3}}
		}
		for i=1, 6 do
			local ascensionLevel=getAscensionTier(s,healingList[i])
			if ascensionLevel>=1 then
				Game.SpellsTxt[healingList[i]].Description=baseHealTooltip[healingList[i]] .. "\n\nAscension level: " .. ascensionLevel
			else
				Game.SpellsTxt[healingList[i]].Description=baseHealTooltip[healingList[i]] .. "\n\nNot Ascended"
			end
			if ascensionLevel>=1 then
				for v=1,4 do
					healingSpells[healingList[i]].Cost[v]=math.round(healingSpells[healingList[i]].Cost[v]*(1+s*0.125)*1.8^(ascensionLevel)*(1-0.125*m))
					healingSpells[healingList[i]].Scaling[v], healingSpells[healingList[i]].Base[v]=ascendSpellHealing(s, m, healingList[i], v)
				end
			end
		end
		--shaman modifier
		if table.find(shamanClass, pl.Class) then
			local m1,m2,m3,m4,m5,m6,m7,m8
			m1=SplitSkill(pl.Skills[const.Skills.Fire])
			m2=SplitSkill(pl.Skills[const.Skills.Air])
			m3=SplitSkill(pl.Skills[const.Skills.Water])
			m4=SplitSkill(pl.Skills[const.Skills.Earth])
			m5=SplitSkill(pl.Skills[const.Skills.Spirit])
			m6=SplitSkill(pl.Skills[const.Skills.Mind])
			m7=SplitSkill(pl.Skills[const.Skills.Body])
			m8=m2+m3+m4+m5+m1+m6+m7
			local mult=1+m8/400
			for i=1,5 do
				for v=1,4 do
					healingSpells[healingList[i]].Scaling[v]=math.round(healingSpells[healingList[i]].Scaling[v]*mult)
					healingSpells[healingList[i]].Base[v]=math.round(healingSpells[healingList[i]].Base[v]*mult)
				end
			end
		end
		--remove curse
		local sp=healingSpells[49]
		Game.Spells[49]["SpellPointsExpert"]=sp.Cost[2]
		Game.Spells[49]["SpellPointsMaster"]=sp.Cost[3]
		Game.Spells[49]["SpellPointsGM"]=sp.Cost[4]
		Game.SpellsTxt[49].Master=string.format("%s Mana cost: \ncures %s + %s HP per point of skill\n1 day limit\n",sp.Cost[3], sp.Base[3], sp.Scaling[3])
		Game.SpellsTxt[49].GM=string.format("%s Mana cost: \ncures %s + %s HP per point of skill\n1 day limit\n",sp.Cost[4], sp.Base[4], sp.Scaling[4])

		--shared life
		local sp=healingSpells[54]
		Game.Spells[54]["SpellPointsMaster"]=sp.Cost[3]
		Game.Spells[54]["SpellPointsGM"]=sp.Cost[4]
		Game.SpellsTxt[54].Master=string.format("Adds %s + %s HP per point of skill to the pool", sp.Base[3], sp.Scaling[3])
		Game.SpellsTxt[54].GM=string.format("Adds %s + %s HP per point of skill to the pool", sp.Base[4], sp.Scaling[4])
		
		--resurrection
		local sp=healingSpells[55]
		Game.Spells[55]["SpellPointsGM"]=sp.Cost[4]
		Game.SpellsTxt[55].GM=string.format("Cures %s + %s HP per point of skill", sp.Base[4], sp.Scaling[4])
		
		--heal
		local sp=healingSpells[68]
		Game.Spells[68]["SpellPointsNormal"]=sp.Cost[1]
		Game.Spells[68]["SpellPointsExpert"]=sp.Cost[2]
		Game.Spells[68]["SpellPointsMaster"]=sp.Cost[3]
		Game.Spells[68]["SpellPointsGM"]=sp.Cost[4]
		Game.SpellsTxt[68].Normal=string.format("%s Mana cost: \ncures %s + %s HP per point of skill",sp.Cost[1], sp.Base[1], sp.Scaling[1])
		Game.SpellsTxt[68].Expert=string.format("%s Mana cost: \ncures %s + %s HP per point of skill",sp.Cost[2], sp.Base[2], sp.Scaling[2])
		Game.SpellsTxt[68].Master=string.format("%s Mana cost: \ncures %s + %s HP per point of skill",sp.Cost[3], sp.Base[3], sp.Scaling[3])
		Game.SpellsTxt[68].GM=string.format("%s Mana cost: \ncures %s + %s HP per point of skill",sp.Cost[4], sp.Base[4], sp.Scaling[4])
		
		--greater heal
		local sp=healingSpells[74]
		Game.Spells[74]["SpellPointsMaster"]=sp.Cost[3]
		Game.Spells[74]["SpellPointsGM"]=sp.Cost[4]
		Game.SpellsTxt[74].Master=string.format("%s Mana cost: \ncures %s + %s HP per point of skill\n1 day limit\n",sp.Cost[3], sp.Base[3], sp.Scaling[3])
		Game.SpellsTxt[74].GM=string.format("%s Mana cost: \ncures %s + %s HP per point of skill\nno limit\n",sp.Cost[4], sp.Base[4], sp.Scaling[4])
		
		--power heal
		local sp=healingSpells[77]
		Game.Spells[77]["SpellPointsGM"]=sp.Cost[4]
		Game.SpellsTxt[77].GM=string.format("%s Mana cost: \ncures %s + %s HP per point of skill",sp.Cost[4], sp.Base[4], sp.Scaling[4])
		
		--ADD CAST RECOVERY TIME 
		
		--haste
		local haste=math.floor(pl:GetSpeed()/10)
		local it=pl:GetActiveItem(1)
		if it and it.Bonus2==40 then
			haste=haste+20
		end
		
		if buffRework then
			for i=1, #buffSpellList do
				local sp=buffSpellList[i]
				if buffSpell[sp] then
					local cost, percent=getBuffCost(pl, sp)
					percent=math.round(percent*10000)/100
					local txt=StrColor(255,0,0,"\nNot Active")
					if vars.mawbuff[sp] then
						for j=0, Party.High do
							if Party[j]:GetIndex()==vars.mawbuff[sp] then
								txt=StrColor(0,255,0,"\nActive (" .. Party[j].Name .. ")")
							end
						end
					end
					if sp==8 then --immolate exception
						Game.SpellsTxt[sp].Description=Game.SpellsTxt[sp].Description .. "\n\nMana Reserved: " .. StrColor(0,100,255,percent .. "%" .. txt)
					else
						Game.SpellsTxt[sp].Description=oldSpellTooltips[sp] .. "\n\nMana Reserved: " .. StrColor(0,100,255,percent .. "%" .. txt)
					end
				elseif utilitySpell[sp] then
					local cost, percent=getBuffCost(pl, sp)
					cost=math.round(cost)
					local txt=StrColor(255,0,0,"\nNot Active")
					if vars.mawbuff[sp] then
						for j=0, Party.High do
							if Party[j]:GetIndex()==vars.mawbuff[sp] then
								txt=StrColor(0,255,0,"\nActive(" .. Party[j].Name .. ")")
							end
						end
					end
					Game.SpellsTxt[sp].Description=oldSpellTooltips[sp] .. "\n\nMana Reserved: " .. cost .. txt
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
	end
end


--[[
OLD ASCENSION
mass fear; 40 mana , 6 secs, skill/2 first cast
slow 12 sec duration, skill first cast
paralyze 6 sec, skill x 2 first cast
shrink ray 3 sec duration, skill/2 first cas
berserk 6 sec, skill x 2 first cast
enslave 6 sec, skill x 2 first cast

	MonsterBuff = {
		ArmorHalved = 21,
		Berserk = 8,
		Bless = 16,
		Charm = 1,
		DamageHalved = 23,
		DayOfProtection = 12,
		Enslave = 11,
		Fate = 10,
		Fear = 4,
		Hammerhands = 20,
		Haste = 18,
		Heroism = 17,
		HourOfPower = 13,
		MassDistortion = 9,
		MeleeOnly = 22,
		Mistform = 25,
		Null = 0,
		PainReflection = 19,
		Paralyze = 6,
		Shield = 14,
		ShrinkingRay = 3,
		Slow = 7,
		StoneSkin = 15,
		Stoned = 5,
		Summoned = 2,
		Wander = 24
	},
]]


--[[old ascendance, from level 80 every 8 levels, no skills involved


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
	--vampire
	spellCostMaster[111]=8
	spellCostGM[111]=10
	
	ascendanceCost={11,14,17,20,35,50,65,80,95,110,125,[0]=125}
	ascendanceCost2={25,30,35,40,70,100,140,180,220,260,300,[0]=300}
	spells={2,6,7,8,9,10,11,15,18,20,22,24,26,29,32,37,39,41,43,44,52,59,65,70,76,78,79,84,87,90,93,97,98,99,103,111,123}
	lastIndex=-1 --used later

	--if you change diceMin or values that are 0 remember to update the tooltip manually 
	spellPowers =
		{
			[2] = {dmgAdd =8, diceMin = 1, diceMax = 1, },--fire bolt
			[6] = {dmgAdd = 0, diceMin = 1, diceMax = 11, },--fireball
			[7] = {dmgAdd = 17, diceMin = 1, diceMax = 4, },--fire spike, the only spell with damage depending on mastery, fix in events.calcspelldamage
			[8] = {dmgAdd = 16, diceMin = 1, diceMax = 10, },--immolation
			[9] = {dmgAdd = 8, diceMin = 1, diceMax = 1, },--meteor shower
			[10] = {dmgAdd = 12, diceMin = 1, diceMax = 7, },--inferno
			[11] = {dmgAdd = 18, diceMin = 1, diceMax = 18, },--incinerate
			[15] = {dmgAdd = 6, diceMin = 1, diceMax = 2, },--sparks
			[18] = {dmgAdd = 13, diceMin = 1, diceMax = 8, },--lightning bolt
			[20] = {dmgAdd = 20, diceMin = 1, diceMax = 12, },--implosion
			[22] = {dmgAdd = 20, diceMin = 1, diceMax = 1, },--starburst
			[24] = {dmgAdd = 5, diceMin = 1, diceMax = 2, },--poison spray
			[26] = {dmgAdd = 6, diceMin = 1, diceMax = 6, },--ice bolt
			[29] = {dmgAdd = 2, diceMin = 1, diceMax = 12, },--acid burst
			[32] = {dmgAdd = 5, diceMin = 1, diceMax = 5, },--ice blast
			[37] = {dmgAdd = 5, diceMin = 1, diceMax = 5, },--deadly swarm
			[39] = {dmgAdd = 7, diceMin = 1, diceMax = 7, },--blades
			[41] = {dmgAdd = 8, diceMin = 1, diceMax = 8, },--rock blast
			[43] = {dmgAdd = 0, diceMin = 1, diceMax = 12, },--death blossom
			[44] = {dmgAdd = 15, diceMin = 0.5, diceMax = 0.5, },--mass distorsion, nerfed
			[52] = {dmgAdd = 10, diceMin = 2, diceMax = 8, },--spirit lash
			[59] = {dmgAdd = 16, diceMin = 1, diceMax = 3, },--mind blast
			[65] = {dmgAdd = 25, diceMin = 1, diceMax = 25, },--psychic shock
			[70] = {dmgAdd = 4, diceMin = 1, diceMax = 4, },--harm
			[76] = {dmgAdd = 20, diceMin = 1, diceMax = 5, },--flying fist
			[78] = {dmgAdd = 12, diceMin = 1, diceMax = 2, },--light bolt
			[79] = {dmgAdd = 12, diceMin = 1, diceMax = 8, },--destroy undead
			[84] = {dmgAdd = 25, diceMin = 2, diceMax = 2, },--prismatic light
			[87] = {dmgAdd = 50, diceMin = 1, diceMax = 50, },--sunray
			[90] = {dmgAdd = 15, diceMin = 1, diceMax = 9, },--toxic cloud
			[93] = {dmgAdd = 0, diceMin = 1, diceMax = 8, },--shrapmetal
			[97] = {dmgAdd = 0, diceMin = 1, diceMax = 18, },--dragon breath
			[98] = {dmgAdd = 50, diceMin = 1, diceMax = 1, },--armageddon
			[99] = {dmgAdd = 25, diceMin = 1, diceMax = 5, },--souldrinker
			[103] = {dmgAdd = 46, diceMin = 1, diceMax = 28, },--darkfire bolt
			[111] = {dmgAdd = 18, diceMin = 1, diceMax = 6, },--lifedrain scales with mastery, fixed in calcspelldamage
			[123] = {dmgAdd = 0, diceMin = 1, diceMax = 25, },--flame blast scales with mastery, fixed in calcspelldamage
		}

	--calculate table for spells from level 100
	spellPowers80={}
	spellPowers160={}
	for i =1,132 do
		if spellPowers[i] then
			--calculate damage assuming formula is manacost^0.7
			local theoreticalDamage=spellCostGM[i]^0.7
			local dmgAddProportion=spellPowers[i].dmgAdd/theoreticalDamage
			if spellPowers[i].diceMax==spellPowers[i].diceMin then
				diceMaxProportion=spellPowers[i].diceMax/theoreticalDamage
			else
				diceMaxProportion=((spellPowers[i].diceMax+1)/2)/theoreticalDamage
			end
			--get new mana cost and calculate theoretical Damage for level 80+
			local manaCost=ascendanceCost[i%11]
			if i>77 and i<100 then
				manaCost=manaCost+100
			end
			--exception for racial spells
			if i==103 then 
				manaCost=100
			end
			if i==111 then 
				manaCost=15
			end
			if i==123 then 
				manaCost=60
			end
			local theoreticalDamage80=manaCost^0.6*1.4
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
				manaCost=manaCost+200
			end
			--exception for racial spells
			if i==103 then 
				manaCost=200
			end
			if i==111 then 
				manaCost=25
			end
			if i==123 then 
				manaCost=120
			end
			local theoreticalDamage160=manaCost^0.5*2.5
			--scale new values according to original differences
			local dmgAdd160=math.round(theoreticalDamage160*dmgAddProportion)
			if spellPowers[i].diceMax==spellPowers[i].diceMin then
				diceMax160=math.round(theoreticalDamage160*diceMaxProportion)
			else
				diceMax160=math.round(theoreticalDamage160*(diceMaxProportion)*2)+1
			end
			spellPowers160[i]={dmgAdd = dmgAdd160, diceMin = 1, diceMax = diceMax160,}
		end
	end
	spellPowers160[44]={dmgAdd = 15, diceMin = 0.5, diceMax = 0.5}
	spellPowers80[44]={dmgAdd = 15, diceMin = 0.5, diceMax = 0.5}
end

--calculate spell Damage
function events.CalcSpellDamage(t)
	--mass distorsion
	if t.Spell == 44 then 
		t.Result = t.HP*0.15+t.HP*t.Skill*0.005
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
		--vampiric ascends 20 levels later
		local extraRequiredLevels=0
		if t.Spell==111 then
		--	extraRequiredLevels=20
		end
		if data.Player.LevelBase>=spellTier*8+152+extraRequiredLevels then
			diceMin=spellPowers160[t.Spell].diceMin
			diceMax=spellPowers160[t.Spell].diceMax
			damageAdd=spellPowers160[t.Spell].dmgAdd
		elseif data.Player.LevelBase>=spellTier*8+72+extraRequiredLevels then
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
			t.Result=t.Result/3*4
		elseif t.Mastery==4 then
			t.Result=t.Result/3*5
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
		return
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
		return
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
		return
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
	if index> Party.High then
		Game.CurrentPlayer=0
	end
	if index>=0 and index<=Party.High then
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
							Game.Spells[num]["SpellPointsNormal"] = ascendanceCost2[num2]+100
							Game.Spells[num]["SpellPointsExpert"] = ascendanceCost2[num2]+100
							Game.Spells[num]["SpellPointsMaster"] = ascendanceCost2[num2]+100
							Game.Spells[num]["SpellPointsGM"] = ascendanceCost2[num2]+100
						else
							Game.Spells[num]["SpellPointsNormal"] = ascendanceCost2[num2]
							Game.Spells[num]["SpellPointsExpert"] = ascendanceCost2[num2]
							Game.Spells[num]["SpellPointsMaster"] = ascendanceCost2[num2]
							Game.Spells[num]["SpellPointsGM"] = ascendanceCost2[num2]
						end
					elseif level>=check then
						if num>77 then --increase light and dark cost
							Game.Spells[num]["SpellPointsNormal"] = ascendanceCost[num2]+50
							Game.Spells[num]["SpellPointsExpert"] = ascendanceCost[num2]+50
							Game.Spells[num]["SpellPointsMaster"] = ascendanceCost[num2]+50
							Game.Spells[num]["SpellPointsGM"] = ascendanceCost[num2]+50
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
						Game.Spells[num]["SpellPointsNormal"] = 20
						Game.Spells[num]["SpellPointsExpert"] = 20
						Game.Spells[num]["SpellPointsMaster"] = 20
						Game.Spells[num]["SpellPointsGM"] = 25
					elseif level>=check then
						Game.Spells[num]["SpellPointsNormal"] = 10
						Game.Spells[num]["SpellPointsExpert"] = 10
						Game.Spells[num]["SpellPointsMaster"] = 15
						Game.Spells[num]["SpellPointsGM"] = 15
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
				if num==44 then	
						Game.Spells[num]["SpellPointsGM"]=level^1.6/12.5
				end	
			end	
			
			
				
			--change tooltips according to ascended damage
			Game.SpellsTxt[2].Description=string.format("Launches a burst of fire at a single target.  Damage is %s+1-%s points of damage per point of skill in Fire Magic.   Firebolt is safe, effective and has a low casting cost.",dmgAddTooltip(level,2),diceMaxTooltip(level,2))
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
			Game.SpellsTxt[18].Description=string.format("Lightning Bolt discharges electricity from the caster's hand to a single target.  It always hits and does %s + 1-%s points of damage per point of skill in Air Magic.",dmgAddTooltip(level,18),diceMaxTooltip(level,18))
			Game.SpellsTxt[20].Description=string.format("Implosion is a nasty spell that affects a single target by destroying the air around it, causing a sudden inrush from the surrounding air, a thunderclap, and %s points plus 1-%s points of damage per point of skill in Air Magic.",dmgAddTooltip(level,20),diceMaxTooltip(level,20))
			Game.SpellsTxt[22].Description=string.format("Calls stars from the heavens to smite and burn your enemies.  Twenty stars are called, and the damage for each star is %s points plus %s per point of skill in Air Magic. Try not to get caught in the blast! This spell only works outdoors.",dmgAddTooltip(level,22),diceMaxTooltip(level,22))
			Game.SpellsTxt[24].Description=string.format("Sprays poison at monsters directly in front of your characters.  Damage is low, but few monsters have resistance to Water Magic, so it usually works.  Each shot does %s points of damage plus 1-%s per point of skill.",dmgAddTooltip(level,24),diceMaxTooltip(level,24))
			Game.SpellsTxt[26].Description=string.format("Fires a bolt of ice at a single target.  The missile does %s + 1-%s points of damage per point of skill in Water Magic.",dmgAddTooltip(level,26),diceMaxTooltip(level,26))
			Game.SpellsTxt[29].Description=string.format("Acid burst squirts a jet of extremely caustic acid at a single victim.  It always hits and does %s points of damage plus 1-%s per point of skill.",dmgAddTooltip(level,29),diceMaxTooltip(level,29))
			Game.SpellsTxt[32].Description=string.format("Fires a ball of ice in the direction the caster is facing.  The ball will shatter when it hits something, launching 7 shards of ice in all directions except the caster's.  The shards will ricochet until they strike a creature or melt.  Each shard does %s points of damage plus 1-%s per point of skill in Water Magic.",dmgAddTooltip(level,32),diceMaxTooltip(level,32))
			Game.SpellsTxt[37].Description=string.format("Summons a swarm of biting, stinging insects to bedevil a single target.  The swarm does %s points of damage plus 1-%s per point of skill in Earth Magic.",dmgAddTooltip(level,37),diceMaxTooltip(level,37))
			Game.SpellsTxt[39].Description=string.format("Fires a rotating, razor-thin metal blade at a single monster.  The blade does 1-%s points of damage per point of skill in Earth Magic.",diceMaxTooltip(level,39))
			Game.SpellsTxt[41].Description=string.format("Releases a magical stone into the world that will explode when it comes into contact with a creature or enough time passes.  The rock will bounce and roll until it finds a resting spot, so be careful not to be caught in the blast.  The explosion causes %s points of damage plus 1-%s points of damage per point of skill in Earth Magic.",dmgAddTooltip(level,41),diceMaxTooltip(level,41))
			Game.SpellsTxt[43].Description=string.format("Launches a magical stone which bursts in air, sending shards of explosive earth raining to the ground.  The damage is 1-%s per point of skill in Earth Magic for each shard.  This spell can only be used outdoors.",diceMaxTooltip(level,43))
			Game.SpellsTxt[44].Description=string.format("Increases the weight of a single target enormously for an instant, causing internal damage equal to %s%% of the monster's hit points plus another %s%% per point of skill in Earth Magic.  The bigger they are, the harder they fall.",dmgAddTooltip(level,44),diceMaxTooltip(level,44))
			Game.SpellsTxt[52].Description=string.format("This spell weakens the link between a target's body and soul, causing %s + 2-%s points of damage per point of skill in Spirit Magic to all monsters near the caster.",dmgAddTooltip(level,52),diceMaxTooltip(level,52))
			Game.SpellsTxt[59].Description=string.format("Fires a bolt of mental force which damages a single target's nervous system.  Mind Blast does %s points of damage plus 1-%s per point of skill in Mind Magic.",dmgAddTooltip(level,59),diceMaxTooltip(level,59))
			Game.SpellsTxt[65].Description=string.format("Similar to Mind Blast, Psychic Shock targets a single creature with mind damaging magic--only it has a much greater effect.  Psychic Shock does %s points of damage plus 1-%s per point of skill in Mind Magic.",dmgAddTooltip(level,65),diceMaxTooltip(level,65))
			Game.SpellsTxt[70].Description=string.format("Directly inflicts magical damage upon a single creature.  Harm does %s points of damage plus 1-%s per point of skill in Body Magic.",dmgAddTooltip(level,70),diceMaxTooltip(level,70))
			Game.SpellsTxt[76].Description=string.format("Flying Fist throws a heavy magical force at a single opponent that does %s points of damage plus 1-%s per point of skill in Body Magic.",dmgAddTooltip(level,76),diceMaxTooltip(level,76))
			Game.SpellsTxt[76].Description=string.format("Flying Fist throws a heavy magical force at a single opponent that does %s points of damage plus 1-%s per point of skill in Body Magic.",dmgAddTooltip(level,76),diceMaxTooltip(level,76))
			Game.SpellsTxt[78].Description=string.format("Fires a bolt of light at a single target that does %s + 1-%s points of damage per point of skill in light magic.  Damage vs. Undead is doubled.",dmgAddTooltip(level,78),diceMaxTooltip(level,78))
			Game.SpellsTxt[79].Description=string.format("Calls upon the power of heaven to undo the evil magic that extends the lives of the undead, inflicting %s points of damage plus 1-%s per point of skill in Light Magic upon a single, unlucky target.  This spell only works on the undead.",dmgAddTooltip(level,79),diceMaxTooltip(level,79))
			Game.SpellsTxt[84].Description=string.format("Inflicts %s points of damage plus %s per point of skill in Light Magic on all creatures in sight.  This spell can only be cast indoors.",dmgAddTooltip(level,84),diceMaxTooltip(level,84))
			Game.SpellsTxt[87].Description=string.format("Sunray is the second most devastating damage spell in the game. It does %s points of damage plus 1-%s points per point of skill in Light Magic, by concentrating the light of the sun on one unfortunate creature. It only works outdoors during the day.",dmgAddTooltip(level,87),diceMaxTooltip(level,87))
			Game.SpellsTxt[90].Description=string.format("A poisonous cloud of noxious gases is formed in front of the caster and moves slowly away from your characters.  The cloud does %s points of damage plus 1-%s per point of skill in Dark Magic and lasts until something runs into it.",dmgAddTooltip(level,90),diceMaxTooltip(level,90))
			Game.SpellsTxt[93].Description=string.format("Fires a blast of hot, jagged metal in front of the caster, striking any creature that gets in the way.  Each piece inflicts 1-%s points of damage per point of skill in Dark Magic.",diceMaxTooltip(level,93))
			Game.SpellsTxt[97].Description=string.format("Dragon Breath empowers the caster to exhale a cloud of toxic vapors that targets a single monster and damage all creatures nearby, doing 1-%s points of damage per point of skill in Dark Magic.",diceMaxTooltip(level,97))
			Game.SpellsTxt[98].Description=string.format("This spell is the town killer. Armageddon inflicts %s points of damage plus %s point of damage for every point of Dark skill your character has to every creature on the map, including all your characters. It can only be cast three times per day and only outdoors.",dmgAddTooltip(level,98),diceMaxTooltip(level,98))
			Game.SpellsTxt[99].Description=string.format("This horrible spell sucks the life from all creatures in sight, friend or enemy.  Souldrinker then transfers that life to your party in much the same fashion as Shared Life.  Damage (and healing) is %s + 1-%s per point of skill.",dmgAddTooltip(level,99),diceMaxTooltip(level,99))
			
			Game.SpellsTxt[103].Description=string.format("This frightening ability grants the Dark Elf the power to wield Darkfire, a dangerous combination of the powers of Dark and Fire. Any target stricken by the Darkfire bolt resists with either its Fire or Dark resistance--whichever is lower. Damage is 1-%s per point of skill.",diceMaxTooltip(level,103))
			Game.SpellsTxt[111].Description=string.format("Lifedrain allows the vampire to damage his or her target and simultaneously heal based on the damage done in the Lifedrain.  This ability does %s points of damage plus 1-%s points of damage per skill.",dmgAddTooltip(level,111),diceMaxTooltip(level,111))
			Game.SpellsTxt[111].Master=string.format("Damage %s points plus 1-%s per point of skill",math.round(dmgAddTooltip(level,111)/3*4),math.round(diceMaxTooltip(level,111)/3*4))
			Game.SpellsTxt[111].GM=string.format("Damage %s points plus 1-%s per point of skill",math.round(dmgAddTooltip(level,111)/3*5),math.round(diceMaxTooltip(level,111)/3*5))
			Game.SpellsTxt[123].Expert=string.format("Damage %s points plus 1-%s points per point of skill",dmgAddTooltip(level,123),diceMaxTooltip(level,123))
			Game.SpellsTxt[123].Master=string.format("Damage %s points plus 1-%s points per point of skill",math.round(dmgAddTooltip(level,123)/10*11),math.round(diceMaxTooltip(level,123)/10*11))
			Game.SpellsTxt[123].GM=string.format("Damage %s points plus 1-%s points per point of skill",math.round(dmgAddTooltip(level,123)/10*12),math.round(diceMaxTooltip(level,123)/10*12))
			
			--remove curse
			Game.SpellsTxt[49].Master="8 Mana cost: \ncures 24 + 4 HP per point of skill\n1 day limit\n"
			Game.SpellsTxt[49].GM="16 Mana cost: \ncures 36 + 6 HP per point of skill\nno limit\n"
			Game.Spells[49]["SpellPointsExpert"]=5
			Game.Spells[49]["SpellPointsMaster"]=8
			Game.Spells[49]["SpellPointsGM"]=16
			--Remove curse matrix
			curseBase={0,12,24,36}
			curseScaling={0,2,4,6}
			if level>=120 then
				Game.SpellsTxt[49].Master="16 Mana cost: \ncures 36 + 6 HP per point of skill\n1 day limit\n"
				Game.SpellsTxt[49].GM="32 Mana cost: \ncures 72 + 9 HP per point of skill\nno limit\n"
				Game.Spells[49]["SpellPointsMaster"]=16
				Game.Spells[49]["SpellPointsGM"]=32
				curseBase={0,12,36,72}
				curseScaling={0,2,6,9}
			end
			if level>=200 then
				Game.SpellsTxt[49].Master="32 Mana cost: \ncures 72 + 9 HP per point of skill\n1 day limit\n"
				Game.SpellsTxt[49].GM="64 Mana cost: \ncures 150 + 13 HP per point of skill\nno limit\n"
				Game.Spells[49]["SpellPointsMaster"]=32
				Game.Spells[49]["SpellPointsGM"]=64
				curseBase={0,12,72,150}
				curseScaling={0,2,9,14}
			end
				
			--resurrection
			Game.Spells[55]["SpellPointsGM"]=200
			resurrectionBase={0,0,0,200}
			resurrectionScaling={0,0,0,20}
			Game.SpellsTxt[55].GM="Cures 200 + 20 HP per point of skill"
			if level>=160 then
				Game.SpellsTxt[55].GM="Cures 400 + 30 HP per point of skill"
				Game.Spells[55]["SpellPointsGM"]=400
				resurrectionBase={0,0,0,400}
				resurrectionScaling={0,0,0,30}
			end
			if level>=240 then
				Game.SpellsTxt[55].GM="Cures 800 + 45 HP per point of skill"
				Game.Spells[55]["SpellPointsGM"]=800
				resurrectionBase={0,0,0,800}
				resurrectionScaling={0,0,0,45}
			end
			
			--heal
			Game.Spells[68]["SpellPointsNormal"]=3
			Game.Spells[68]["SpellPointsExpert"]=5
			Game.Spells[68]["SpellPointsMaster"]=8
			Game.Spells[68]["SpellPointsGM"]=12
			lesserHealBase={5,10,15,20}
			lesserHealScaling={2,3,4,5}
			Game.SpellsTxt[68].Master="8 Mana cost: \ncures 15 + 4 HP per point of skill"
			Game.SpellsTxt[68].GM="12 Mana cost: \ncures 20 + 5 HP per point of skill"
			
			if level>=88 then
				Game.SpellsTxt[68].Master="10 Mana cost: \ncures 30 + 5 HP per point of skill"
				Game.SpellsTxt[68].GM="15 Mana cost: \ncures 50 + 7 HP per point of skill"
				Game.Spells[68]["SpellPointsMaster"]=10
				Game.Spells[68]["SpellPointsGM"]=15
				lesserHealBase={5,10,30,50}
				lesserHealScaling={2,3,5,7}
			end
			if level>=168 then
				Game.SpellsTxt[68].Master="20 Mana cost: \ncures 60 + 8 HP per point of skill"
				Game.SpellsTxt[68].GM="30 Mana cost: \ncures 100 + 12 HP per point of skill"
				Game.Spells[68]["SpellPointsMaster"]=20
				Game.Spells[68]["SpellPointsGM"]=30
				lesserHealBase={5,10,60,100}
				lesserHealScaling={2,3,8,12}
			end
			
			--greater heal
			Game.Spells[74]["SpellPointsMaster"]=15
			Game.Spells[74]["SpellPointsGM"]=25
			Game.SpellsTxt[74].Master="15 Mana cost: \ncures 25 + 6 HP per point of skill\n1 day limit\n"
			Game.SpellsTxt[74].GM="25 Mana cost: \ncures 40 + 9 HP per point of skill\nno limit\n"
			greaterHealBase={0,0,25,40}
			greaterHealScaling={0,0,6,9}
			if level>=136 then
				Game.SpellsTxt[74].Master="35 Mana cost: \ncures 50 + 10 HP per point of skill\n1 day limit\n"
				Game.SpellsTxt[74].GM="50 Mana cost: \ncures 75 + 13 HP per point of skill\nno limit\n"
				Game.Spells[74]["SpellPointsMaster"]=35
				Game.Spells[74]["SpellPointsGM"]=50
				greaterHealBase={0,12,50,75}
				greaterHealScaling={0,2,10,13}
			end
			if level>=216 then
				Game.SpellsTxt[74].Master="90 Mana cost: \ncures 100 + 18 HP per point of skill\n1 day limit\n"
				Game.SpellsTxt[74].GM="125 Mana cost: \ncures 160 + 25 HP per point of skill\nno limit\n"
				Game.Spells[74]["SpellPointsMaster"]=90
				Game.Spells[74]["SpellPointsGM"]=125
				greaterHealBase={0,12,100,160}
				greaterHealScaling={0,2,18,25}
			end
			
			Game.Spells[77]["SpellPointsGM"]=30
			powerHealBase = 10
			powerHealScaling = 3
			Game.SpellsTxt[77].GM="This spell is as good as it will ever get! Or not..."
			if level>=160 then
				Game.Spells[77]["SpellPointsGM"]=60
				powerHealBase = 30
				powerHealScaling = 5
				Game.SpellsTxt[77].GM="Cures all party members by 30 plus 5 per point of skill"
			end
			if level>=240 then
				Game.Spells[77]["SpellPointsGM"]=90
				powerHealBase = 50
				powerHealScaling = 7
				Game.SpellsTxt[77].GM="Cures all party members by 50 plus 7 per point of skill"
			end
		end
	end
end
]]

---------------
--BUFF REWORK--
---------------	
if buffRework then
	function events.GameInitialized2()
		spScaling={}
		for i=0,Game.Classes.SPFactor.High do
			spScaling[i]=Game.Classes.SPFactor[i]
		end
		--dk
		spScaling[56]=2
		spScaling[57]=4
		spScaling[58]=6
		spScaling[59]=1
		spScaling[60]=1.5
		spScaling[61]=2
	end

	buffSpell={
	[3]= {["Cost"]=60, ["Sound"]=10020, ["PartyBuff"]=6},--fire res
	[4]= {["Cost"]=90, ["Sound"]=10040,},				--fire aura
	[14]={["Cost"]=60, ["Sound"]=11020,["PartyBuff"]=0},--air res
	[25]={["Cost"]=60, ["Sound"]=12020,["PartyBuff"]=17},--water res
	[36]={["Cost"]=60, ["Sound"]=13020,["PartyBuff"]=4},--earth res
	[58]={["Cost"]=60, ["Sound"]=15020,["PartyBuff"]=12},--mind res
	[69]={["Cost"]=60, ["Sound"]=16020,["PartyBuff"]=1},--body res
	[5]= {["Cost"]=120, ["Sound"]=10040,["PartyBuff"]=8},--haste
	[8]= {["Cost"]=40, ["Sound"]=10070,["PartyBuff"]=10},--immolation
	[17]={["Cost"]=75, ["Sound"]=11050,["PartyBuff"]=14},--shield
	[28]={["Cost"]=150, ["Sound"]=10070,},				--empower magic
	[38]={["Cost"]=75, ["Sound"]=13040,["PartyBuff"]=15},--stoneskin
	[46]={["Cost"]=75, ["Sound"]=14010,["SingleBuff"]=1},--bless
	[47]={["Cost"]=75, ["Sound"]=14020,["SingleBuff"]=4},--fate
	[50]={["Cost"]=120, ["Sound"]=14050,["SingleBuff"]=11},--preservation
	[51]={["Cost"]=120, ["Sound"]=14060,["PartyBuff"]=9},--Heroism
	[56]={["Cost"]=120, ["Sound"]=15020,},				--Meditation
	[71]={["Cost"]=120, ["Sound"]=16040,["SingleBuff"]=12},--Regeneration
	[73]={["Cost"]=75, ["Sound"]=16060,["SingleBuff"]=6},--Hammerhands
	[75]={["Cost"]=180,["Sound"]=16080,["PartyBuff"]=13},--Protection from magic
	[83]={["Cost"]=200,["Sound"]=17050,["PartyBuff"]=2},--day of the gods
	[85]={["Cost"]=150,["Sound"]=17070,["MultiBuff"]={6,0,17,4,12,1}},--day of Protection
	[86]={["Cost"]=300,["Sound"]=17080,["MultiBuff"]={8,14,15}, ["SingleBuff"]=4},--hour of power
	[91]={["Cost"]=150,["Sound"]=18020,},				--vampiric aura
	[95]={["Cost"]=10,["Sound"]=18060,["SingleBuff"]=10},--pain reflection
	}
	utilitySpell={
	[1]= {["Cost"]=5,  ["Sound"]=10000, ["PartyBuff"]=16},--torch
	[12]={["Cost"]=5,  ["Sound"]=11000, ["PartyBuff"]=19},--wizard eye
	--[19]={["Cost"]=100,["Sound"]=11070, ["PartyBuff"]=11},--Invisibility
	--[21]={["Cost"]=120,["Sound"]=11090, ["PartyBuff"]=7},--fly
	[27]={["Cost"]=20, ["Sound"]=12040, ["PartyBuff"]=18},--water walk
	--[124]={["Cost"]=20, ["Sound"]=21020, ["PartyBuff"]=7},--fly
	}

	buffSpellList={1,3,4,12,14,21,25,27,28,36,56,58,69,5,8,17,38,46,47,50,51,71,73,75,83,85,86,91,95}
	utilityBuffs={16,19,11,18}
	
	mawPartyBuffList={6,0,17,4,12,1,8,10,14,15,9,13,2,16,19,18}
	mawPartyBuffIgnore={16,19,11,18,10}
	mawSingleBuffList={1,4,11,12,6,10}
	
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
		[83]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--day of the gods
		[85]= {["Base"]={[0]=0,20,20,20,20}, ["Scaling"]={[0]=0,2,2,2,2}},--day of Protection
		[86]= {["Base"]={[0]=0,10,10,10,10}, ["Scaling"]={[0]=0,2,2,2,2}},--hour of power (formulas don't use this values, but takes skill and divide by 1.5)
	}
	
	function events.LoadMap()
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
					end
				end
			end
		end
		--remove temples even indoor
		for i=1, #buffSpellList do
			if removeTempleBuffs then
				local buff=buffSpellList[i]
				if vars.mawbuff[buff] then
					if vars.mawbuff[buff]=="Temple" then
						vars.mawbuff[buff]=false
					end
				end
			end
		end
		removeTempleBuffs=false
	end
	
	function events.LeaveMap()
		removeTempleBuffs=true
	end
	
	function events.Action(t)
		if t.Action==142 and (buffSpell[t.Param] or utilitySpell[t.Param]) then
			t.Handled=true
			local pl=Party[t.Param2]
			local id=pl:GetIndex()
			mawBuffCast(pl, id, t.Param)
		end		
	end

	function events.PlayerCastSpell(t)
		if buffSpell[t.SpellId] or utilitySpell[t.SpellId] then
			--fix scrolls and pedestals
			if t.TargetKind==4 or t.IsSpellScroll then
				vars.mawbuff[t.SpellId]=Map.Name
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
			local s,m=SplitSkill(Skillz.get(pl,52))
			local div=spScaling[pl.Class]+m/2
			percentageDecrease=(buffSpell[spellId].Cost/div)*0.01
			local id=pl:GetIndex()
			for i=0, Party.High do
				if id==Party[i]:GetIndex() and vars.maxManaPool[i] then
					cost=vars.maxManaPool[i]*percentageDecrease
				end
			end
		elseif utilitySpell[spellId] then
			cost=math.round(utilitySpell[spellId].Cost)
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
			
			pl=Party[id]
			if not vars.maxManaPool then
				for i=0,Party.High do
					local sp=Party[i]:GetFullSP()
					vars.maxManaPool[i]=sp
					vars.currentManaPool[i]=sp
				end
			end

			if buffSpell[spellId] then
				sound=buffSpell[spellId].Sound
			elseif utilitySpell[spellId] then
				sound=utilitySpell[spellId].Sound
			end	
			
			local cost=getBuffCost(pl, spellId)
			
			if vars.currentManaPool[id]<cost then
				Game.ShowStatusText("Not enough Mana")
				return
			end
			
			vars.mawbuff[spellId]=index
			for i=0, Party.High do
				mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, mem.u4[0x75CE00]), spellId, i)
			end
			evt.PlaySound(sound)
			local delay=getSpellDelay(pl,spellId)
			if not delay then --this should apply only when donating in temples
				vars.mawbuff[spellId]="Temple"
			else
				pl:SetRecoveryDelay(delay)
			end
			--pl.SP=pl.SP-cost
			
			function events.Tick() 
				events.Remove("Tick", 1)
				mawBuffApply()
			end
		else
			vars.mawbuff[spellId]=false
			function events.Tick() 
				events.Remove("Tick", 1)
				mawBuffApply()
				Game.ShowStatusText("Buff Disabled")
			end
		end
	end

	function mawBuffApply()
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
		for j=0, Party.High do
			local pl=Party[j]
			--[[for i=0, pl.SpellBuffs.High do
				pl.SpellBuffs[i].ExpireTime=0
				pl.SpellBuffs[i].Power=0
				pl.SpellBuffs[i].Skill=0
			end
			]]
			for k=1,#mawSingleBuffList do
				local id=mawSingleBuffList[k]
				pl.SpellBuffs[id].ExpireTime=0
			end
		end
		for i=1, #buffSpellList do
			local buff=buffSpellList[i]
			if vars.mawbuff[buff] then
				local pl=GetPlayerFromIndex(vars.mawbuff[buff])
				if (pl and pl:IsConscious()) or type(vars.mawbuff[buff])=="string" or type(vars.mawbuff[buff])=="table" then
					if buff==75 then
						Party.SpellBuffs[13].Power=4 --allow protection from magic to protect from death/eradicate
						Party.SpellBuffs[13].Skill=4 --allow protection from magic to protect from death/eradicate
					end
					if buff==85 then --day of protection
						for i=1, #buffSpell[buff].MultiBuff do
							local buffId=buffSpell[buff].MultiBuff[i]
							Party.SpellBuffs[buffId].ExpireTime=Game.Time+const.Week
						end
					elseif buff==86 then --hour of power
						for i=1, #buffSpell[buff].MultiBuff do
							local buffId=buffSpell[buff].MultiBuff[i]
							Party.SpellBuffs[buffId].ExpireTime=Game.Time+const.Week
						end
						local buffId=buffSpell[buff].SingleBuff
						for i=0, Party.High do
							Party[i].SpellBuffs[buffId].ExpireTime=Game.Time+const.Week
						end
					elseif buffSpell[buff] and buffSpell[buff].PartyBuff then
						local buffId=buffSpell[buff].PartyBuff
						Party.SpellBuffs[buffId].ExpireTime=Game.Time+const.Week
						if buffId==8 then
							Party.SpellBuffs[buffId].ExpireTime=Game.Time+const.Week
						end
					elseif buffSpell[buff] and buffSpell[buff].SingleBuff then
						local buffId=buffSpell[buff].SingleBuff
						for i=0, Party.High do
							Party[i].SpellBuffs[buffId].ExpireTime=Game.Time+const.Week
						end
					elseif utilitySpell[buff] and utilitySpell[buff].PartyBuff then
						local buffId=utilitySpell[buff].PartyBuff
						--if buffId~=7 or (not Party.EnemyDetectorYellow and not Party.EnemyDetectorRed and Map.IndoorOrOutdoor==2) then --fly
						if type(vars.mawbuff[buff])=="string" then
							Party.SpellBuffs[buffId].Caster=1 --crashes otherwise
						elseif type(vars.mawbuff[buff])=="number" then
							Party.SpellBuffs[buffId].Caster=vars.mawbuff[buff]+1
						else
							Party.SpellBuffs[buffId].Caster=1
						end
						Party.SpellBuffs[buffId].Bits=1 --allow fly
						Party.SpellBuffs[buffId].ExpireTime=Game.Time+const.Week
						--end
					end	
				end
				if vars.mawbuff[8] then
					Party.SpellBuffs[10].Caster=vars.mawbuff[8]+1
				end
			end
		end
		--vampire night preservation
		for k=0, Party.High do
			pl=Party[k]
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
			Party.SpellBuffs[16].Power=math.max(2,Party.SpellBuffs[16].Power)
			Party.SpellBuffs[16].Skill=math.max(1,Party.SpellBuffs[16].Skill)
		end
		
		mawRefresh("all")
	end
	
	function buffManaLock()
		vars.maxManaPool={}
		vars.currentManaPool={}
		local partyIndexes={}
		for i=0,Party.High do
			local id=Party[i]:GetIndex()
			partyIndexes[id]=i
			local sp=Party[i]:GetFullSP()
			vars.maxManaPool[i]=sp
			vars.currentManaPool[i]=sp
		end
		for i=1, #buffSpellList do
			local spell=buffSpellList[i]
			if vars.mawbuff[spell] then
				local id=partyIndexes[vars.mawbuff[spell]]
				if id then
					local pl=Party[id]
					
					if buffSpell[spell] then
						local s,m=SplitSkill(Skillz.get(pl,52))
						local div=spScaling[pl.Class]+m/2
						local percentageDecrease=(buffSpell[spell].Cost/div)*0.01
						vars.currentManaPool[id]=vars.currentManaPool[id]-vars.maxManaPool[id]*percentageDecrease
					elseif utilitySpell[spell] then
						local s,m=SplitSkill(Skillz.get(pl,52))
						vars.currentManaPool[id]=vars.currentManaPool[id]-math.round(utilitySpell[spell].Cost*(1-m/10))
					end
				end
			end
		end
		for i=0, Party.High do
			Party[i].SP=math.min(math.ceil(vars.currentManaPool[i]), Party[i].SP)
		end
	end
	
	function events.LoadMap()
		buffManaLock()
	end
	
	function events.AfterLoadMap()
		Timer(mawBuffApply, const.Minute/2, true)
		Timer(buffManaLock, const.Minute/20) 
	end
	
	function GetPlayerFromIndex(index)
		for i=0,Party.High do
			player=Party[i]
			if player:GetIndex()==index then
				return player
			end
		end
		return false
	end
	
	function getBuffSkill(spell)
		local id=vars.mawbuff[spell]
		if type(id)=="table" then
			return id[1], id[2], id[3]
		end
		if type(id)=="string" then
			return 7,3,40
		end
		local player=GetPlayerFromIndex(id)
		if player and player:IsConscious() then
			local school=11+math.ceil(spell/11)
			local s,m=SplitSkill(player.Skills[school])
			return s, m, player.LevelBase
		else
			return 0,0,0
		end
	end
	
	--code to make buff work is elsewhere
	
	--tooltips
	function events.GameInitialized2()
		--fire resistance
		local id=3
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Fire Resistance and Intellect by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--fire aura
		local id=4
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Causes your party weapons to burn with a magical fire, giving the weapons fire enchant, on top of any other enchants")
		
		--air resistance
		local id=14
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Air Resistance and Speed by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--water resistance
		local id=25
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Water Resistance and Luck by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--earth res
		local id=36
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Earth Resistance and Endurance by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--mind res
		local id=58
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Mind Resistance and Personality by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--body res
		local id=69
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Body Resistance and Might by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--Bless
		local id=46
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Attack and Accuracy.\nThe enhancement equals a flat %s plus an additional 1 point for every 2 caster levels, increased by %s%% per skill level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--Haste
		local id=5
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase your party Recovery speed by %s%% plus %s%% per Skill Level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		
		--Shield
		local id=17
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to reduce any incoming magic damage to your party by %s%% plus %s%% per Skill Level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		
		--Stoneskin
		local id=38
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance your party's Armor Class by %s.\nYou get an additional 1 point for every 2 caster levels, increased by %s%% per skill level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1])
		
		--Empower Magic
		local id=28
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase spell damage of your party by %s%% plus %s%% per Skill Level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		sp.Name = "Empower Magic"
		
		--fate
		local id=47
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase critical chance of your party by %s%% plus %s%% per Skill Level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		
		--heroism
		local id=51
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase your party melee damage by %s%% plus %s%% per Skill Level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		
		--meditation
		local id=56
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase your party mana regen.\nRegen depends on the mana pool, caster level and it's increased by %s%% per skill point.\nThis effect remains active until deactivated or lose consciousness.", bf.Scaling[1])
		sp.Name = "Meditation"
		
		--regeneration
		local id=71
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase your party health regen.\nRegen depends on the health pool, caster level and it's increased by %s%% per skill point.\nThis effect remains active until deactivated or lose consciousness.", bf.Scaling[1])
		
		--Hammerhands
		local id=73
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increase your party unarmed damage by %s%% plus %s%% per Skill Level.\nStaves with GM skill and Unarmed is considered as unarmed as well.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1],bf.Scaling[1]/10)
		
		--day of the gods
		local id=83
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to increases all seven stats on all your characters by %s.\nYou get an additional 1 point for every 3 caster levels, increased by %s%% per skill level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
		--day of protection
		local id=85
		local sp=Game.SpellsTxt[id]
		local bf=buffPower[id]
		sp.Description = string.format("Reserve a percentage of your mana to enhance all of your party's Resistances by %s.\nYou get an additional 1 point for every 3 caster levels, increased by %s%% per skill level.\nThis effect remains active until deactivated or lose consciousness.", bf.Base[1], bf.Scaling[1])
		
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
		sp.Description = string.format("Reserve a percentage of your mana to affect the entire party at once, granting immunity to certain spells and monster abilities that cause debilitation conditions.  These are:  Poison, Disease, Stone, Paralyze, and Weak.\nThis effect remains active until deactivated or lose consciousness.")
		
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
