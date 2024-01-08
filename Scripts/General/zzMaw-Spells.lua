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

-- START OF ACTUAL CHANGES --

-------------------------------------------------
------------------SPELL CHANGES------------------
-------------------------------------------------
--day of protection buff list
local dopList = {0, 1, 4, 6, 12, 17}

--hour of power buff list
local hopList = {8, 9, 14, 15}

--Remove curse matrix
local curseBase={0,12,24,36}
local curseScaling={0,2,4,6}

--lesser heal matrix
local lesserHealBase={5,10,15,20}
local lesserHealScaling={2,3,4,5}

--greater heal matrix
local greaterHealBase={0,0,25,40}
local greaterHealScaling={0,0,6,9}

--modify Spells
function events.PlayerCastSpell(t)
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
			t.Skill=1
			t.Mastery=3
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Air))
			minutesPerSkill=(m-3)*3+3
			baseDuration=(m-3)*15+15
			Party.SpellBuffs[11].ExpireTime=Game.Time+const.Minute*(baseDuration+minutesPerSkill*s)
			Party.SpellBuffs[11].Power=1000
			--online code
			if t.MultiplayerData then
				t.MultiplayerData[1]=Party.SpellBuffs[11].ExpireTime
				t.MultiplayerData[2]=Party.SpellBuffs[11].Power
			end
		elseif t.RemoteData then
			Party.SpellBuffs[11].ExpireTime=t.RemoteData[1]
			Party.SpellBuffs[11].Power=t.RemoteData[2]
		end
	end
	
	--cure curse
	if t.SpellId==49 then
		if not t.RemoteData then
			local persBonus=t.Player:GetPersonality()/1000
			local intBonus=t.Player:GetIntellect()/1000
			local statBonus=math.max(persBonus,intBonus)
			local crit=t.Player:GetLuck()/1500+0.05
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Spirit))
			local baseHeal=curseBase[m]+curseScaling[m]*s
			totHeal=baseHeal*(statBonus+1)
			roll=math.random()
			gotCrit=false
			if roll<crit then
				totHeal=(totHeal)*(1.5+statBonus*3/2)
				gotCrit=true
			end
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
	if t.SpellId==const.Spells.Heroism then
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
			local persBonus=t.Player:GetPersonality()/1000
			local intBonus=t.Player:GetIntellect()/1000
			local statBonus=math.max(persBonus,intBonus)
			local crit=t.Player:GetLuck()/1500+0.05
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Spirit))
			local baseHeal=resurrectionBase+resurrectionScaling*s
			totHeal=baseHeal*(statBonus+1)
			roll=math.random()
			gotCrit=false
			if roll<crit then
				totHeal=(totHeal)*(1.5+statBonus*3/2)
				gotCrit=true
			end
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
	
	
	--lesser heal
	if t.SpellId == 68 then
		if not t.RemoteData then
			t.Skill=0
			local persBonus=t.Player:GetPersonality()/1000
			local intBonus=t.Player:GetIntellect()/1000
			local statBonus=math.max(persBonus,intBonus)
			local crit=t.Player:GetLuck()/1500+0.05
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Body))
			local baseHeal=lesserHealBase[m]+lesserHealScaling[m]*s
			totHeal=baseHeal*(statBonus+1)
			roll=math.random()
			gotCrit=false
			if roll<crit then
				totHeal=(totHeal)*(1.5+statBonus*3/2)
				gotCrit=true
			end
			--remove base heal
			totHeal=math.round(totHeal-5)
			if gotCrit then
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal+5) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal for " .. math.round(totHeal+5) .. " Hit points"))
			end
		end
		--end of healing calculation
		if t.TargetKind == 3 then
			t.MultiplayerData[1]=math.round(totHeal) --bonus heal
			t.MultiplayerData[2]=gotCrit --crit 
			t.MultiplayerData[3]=math.round(5+totHeal) --total heal
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

	
	--cure disease, reworked to greater heal
	if t.SpellId==74 then
		if not t.RemoteData then
			local persBonus=t.Player:GetPersonality()/1000
			local intBonus=t.Player:GetIntellect()/1000
			local statBonus=math.max(persBonus,intBonus)
			local crit=t.Player:GetLuck()/1500+0.05
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Body))
			local baseHeal=greaterHealBase[m]+greaterHealScaling[m]*s
			totHeal=baseHeal*(statBonus+1)
			roll=math.random()
			gotCrit=false
			if roll<crit then
				totHeal=(totHeal)*(1.5+statBonus*3/2)
				gotCrit=true
			end
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
	if t.SpellId==75 then
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
			t.Skill=0
			local persBonus=t.Player:GetPersonality()/1000
			local intBonus=t.Player:GetIntellect()/1000
			local statBonus=math.max(persBonus,intBonus)
			local crit=t.Player:GetLuck()/1500+0.05
			local s,m=SplitSkill(t.Player:GetSkill(const.Skills.Body))
			local baseHeal=powerHealBase+powerHealScaling*s
			totHeal=baseHeal*(statBonus+1)
			roll=math.random()
			gotCrit=false
			if roll<crit then
				totHeal=(totHeal)*(1.5+statBonus*3/2)
				gotCrit=true
			end
			--remove base heal
			totHeal=math.round(totHeal-10)
			if gotCrit then
				Game.ShowStatusText(string.format("You Heal the Party for " .. math.round(totHeal+10) .. " Hit points(crit)"))
			else
				Game.ShowStatusText(string.format("You Heal the Party for " .. math.round(totHeal+10) .. " Hit points"))
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
				t.MultiplayerData[3]=math.round(10+totHeal) --total heal
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
			t.Skill=1
			local s,m = SplitSkill(t.Player:GetSkill(const.Skills.Light))
			local power=m*5+s*m/2
			if Party.SpellBuffs[2].Power<=	power then
				Party.SpellBuffs[2].Power = power
				Party.SpellBuffs[2].Skill = t.Mastery
				Party.SpellBuffs[2].ExpireTime = Game.Time+const.Hour*s*4
			end
			if t.MultiplayerData then
				t.MultiplayerData[1]=power
				t.MultiplayerData[2]=Game.Time+const.Hour*s*4
			end
		--online code
		elseif t.RemoteData then
			Party.SpellBuffs[2].Power=t.RemoteData[1]
			Party.SpellBuffs[2].ExpireTime = t.RemoteData[2]
		end
	end
	
	--protection spells
	protectionSpells={[25]={17,14} ,[69]={1,18} ,[36]={4,15} ,[3]={6,12} ,[58]={12,17} ,[14]={0,13} } --first value is spell ID, second is school skill ID
	if protectionSpells[t.SpellId] then
		if not t.RemoteData then
			t.Skill=1
			local buffId=protectionSpells[t.SpellId][1]
			local s,m = SplitSkill(t.Player:GetSkill(protectionSpells[t.SpellId][2]))
			local power=s*math.min(m,3)
			if Party.SpellBuffs[buffId].Power<=	power then
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
	
	--Day of Protection
	dopList = {0, 1, 4, 6, 12, 17}
	if t.SpellId==85 then
		if not t.RemoteData then
			t.Skill=0
			local s,m = SplitSkill(t.Player:GetSkill(const.Skills.Light))
			local power=s*m/2
			for _, buffId in ipairs(dopList) do
				if Party.SpellBuffs[buffId].Power<=power then
					Party.SpellBuffs[buffId].Power = power
					Party.SpellBuffs[buffId].Skill = t.Mastery
					Party.SpellBuffs[buffId].ExpireTime = Game.Time+const.Hour*s*4
				end
			end
			if t.MultiplayerData then
				t.MultiplayerData[1]=power
				t.MultiplayerData[2]=Game.Time+const.Hour*s*4
			end
		elseif t.RemoteData then
			for _, buffId in ipairs(dopList) do
				if Party.SpellBuffs[buffId].Power<=t.RemoteData[1] then
					Party.SpellBuffs[buffId].Power = t.RemoteData[1]
					Party.SpellBuffs[buffId].Skill = t.Mastery
					Party.SpellBuffs[buffId].ExpireTime = t.RemoteData[2]
				end
			end
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
				power = 10 + s * m / 2
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

------------------------------
--Tooltips and mana cost fix--
------------------------------
function events.GameInitialized2()
--Day of Protection
	--Invisibility
	Game.SpellsTxt[19].Master="Duration 15+3 minutes per point of skill"
	Game.SpellsTxt[19].GM="Duration 30+6 minutes per point of skill"
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
	
	
	--resurrection
	Game.SpellsTxt[55].GM="Cures 200 + 20 HP per point of skill"
	
	--heal
	Game.SpellsTxt[68].Normal="3 Mana cost: \ncures 5 + 2 HP per point of skill"
	Game.SpellsTxt[68].Expert="5 Mana cost: \ncures 10 + 3 HP per point of skill"
	Game.SpellsTxt[68].Master="8 Mana cost: \ncures 15 + 4 HP per point of skill"
	Game.SpellsTxt[68].GM="12 Mana cost: \ncures 20 + 5 HP per point of skill"
	
	--greater heal
	Game.SpellsTxt[74].Name="Greater Heal"
	Game.SpellsTxt[74].ShortName="Greater Heal"
	Game.SpellsTxt[74].Normal="n/a\n"
	Game.SpellsTxt[74].Expert="n/a\n"
	Game.SpellsTxt[74].Master="15 Mana cost: \ncures 25 + 6 HP per point of skill\n1 day limit\n"
	Game.SpellsTxt[74].GM="25 Mana cost: \ncures 40 + 9 HP per point of skill\nno limit\n"
	
	--Protection from magic
	Game.SpellsTxt[75].Description="Protection from Magic affects the entire party at once, granting immunity to certain spells and monster abilities that cause debilitation conditions.  These are:  Poison, Disease, Stone, Paralyze, and Weak.  Every time this spell saves a character from an effect, it weakens.  The spell can survive 1 attack per point of skill in body magic up to 10 attacks--after that, Protection from Magic is broken."
	
	--Power Cure
	Game.SpellsTxt[75].Description="Cures hit points of all characters in your party at once.  The number cured is equal to 10 plus 5 per point of skill in Body Magic."
	
	--protections
	protectionSpells={25,69,36,3,58,14}
	for _, i in ipairs(protectionSpells) do
		Game.SpellsTxt[i].GM="Effect is now passive"
	end
	--day of protection
	Game.SpellsTxt[83].Description="Temporarily increases all seven stats on all your characters by 1 per skill in Light Magic.  This spell lasts until you rest."
	Game.SpellsTxt[83].Expert="All stats increased by 10+1 per skill"
	Game.SpellsTxt[83].Master="All stats increased by 15+1.5 per skill"
	Game.SpellsTxt[83].GM="All stats increased by 20+2 per skill"

	--Day of the Gods
	Game.SpellsTxt[85].Description="Simultaneously casts Protection from Fire, Air, Water, Earth, Mind, and Body, plus Feather Fall and Wizard Eye on all your characters at two times your skill in Light Magic."
	Game.SpellsTxt[85].Master="All spells cast at 1.5 times skill"
	Game.SpellsTxt[85].GM="All spells cast at 2 times skill"
	

	
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
	ascendanceCost={4,6,8,10,15,20,25,30,40,50,60,[0]=60}
	ascendanceCost2={5,10,20,35,50,70,90,115,140,170,200,[0]=200}
	spells={2,6,7,8,9,10,11,15,18,20,22,24,26,29,32,37,39,41,43,44,52,59,65,70,76,78,79,84,87,90,93,97,98,99,103,111,123}
	lastIndex=-1 --used later

	--if you change diceMin or values that are 0 remember to update the tooltip manually 
	spellPowers =
		{
			[2] = {dmgAdd =6, diceMin = 1, diceMax = 3, },--fire bolt
			[6] = {dmgAdd = 0, diceMin = 1, diceMax = 6, },--fireball
			[7] = {dmgAdd = 0, diceMin = 1, diceMax = 6, },--fire spike, the only spell with damage depending on mastery, fix in events.calcspelldamage
			[8] = {dmgAdd = 0, diceMin = 1, diceMax = 6, },--immolation
			[9] = {dmgAdd = 8, diceMin = 1, diceMax = 1, },--meteor shower
			[10] = {dmgAdd = 12, diceMin = 2, diceMax = 2, },--inferno
			[11] = {dmgAdd = 32, diceMin = 1, diceMax = 21, },--incinerate
			[15] = {dmgAdd = 3, diceMin = 2, diceMax = 2, },--sparks
			[18] = {dmgAdd = 15, diceMin = 1, diceMax = 9, },--lightning bolt
			[20] = {dmgAdd = 20, diceMin = 1, diceMax = 16, },--implosion
			[22] = {dmgAdd = 20, diceMin = 1, diceMax = 1, },--starburst
			[24] = {dmgAdd = 4, diceMin = 1, diceMax = 2, },--poison spray
			[26] = {dmgAdd = 8, diceMin = 1, diceMax = 5, },--ice bolt
			[29] = {dmgAdd = 15, diceMin = 1, diceMax = 9, },--acid burst
			[32] = {dmgAdd = 6, diceMin = 1, diceMax = 9, },--ice blast
			[37] = {dmgAdd = 8, diceMin = 1, diceMax = 4, },--deadly swarm
			[39] = {dmgAdd = 12, diceMin = 1, diceMax = 8, },--blades
			[41] = {dmgAdd = 8, diceMin = 1, diceMax = 8, },--rock blast
			[43] = {dmgAdd = 0, diceMin = 1, diceMax = 12, },--death blossom
			[44] = {dmgAdd = 15, diceMin = 1, diceMax = 1, },--mass distorsion, nerfed
			[52] = {dmgAdd = 10, diceMin = 2, diceMax = 12, },--spirit lash
			[59] = {dmgAdd = 12, diceMin = 1, diceMax = 7, },--mind blast
			[65] = {dmgAdd = 45, diceMin = 1, diceMax = 30, },--psychic shock
			[70] = {dmgAdd = 8, diceMin = 1, diceMax = 4, },--harm
			[76] = {dmgAdd = 30, diceMin = 1, diceMax = 11, },--flying fist
			[78] = {dmgAdd = 12, diceMin = 1, diceMax = 4, },--light bolt
			[79] = {dmgAdd = 16, diceMin = 1, diceMax = 16, },--destroy undead
			[84] = {dmgAdd = 25, diceMin = 2, diceMax = 2, },--prismatic light
			[87] = {dmgAdd = 60, diceMin = 1, diceMax = 20, },--sunray
			[90] = {dmgAdd = 25, diceMin = 1, diceMax = 10, },--toxic cloud
			[93] = {dmgAdd = 0, diceMin = 1, diceMax = 6, },--shrapmetal
			[97] = {dmgAdd = 0, diceMin = 1, diceMax = 25, },--dragon breath
			[98] = {dmgAdd = 50, diceMin = 1, diceMax = 1, },--armageddon
			[99] = {dmgAdd = 50, diceMin = 1, diceMax = 5, },--souldrinker
			[103] = {dmgAdd = 30, diceMin = 1, diceMax = 22, },--darkfire bolt
			[111] = {dmgAdd = 15, diceMin = 1, diceMax = 6, },--lifedrain scales with mastery, fixed in calcspelldamage
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
			local theoreticalDamage80=manaCost^0.5*2.5
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
			Game.SpellsTxt[111].Master=string.format("Damage %s points plus 1-%s per point of skill",math.round(dmgAddTooltip(level,111)/3*5),math.round(diceMaxTooltip(level,111)/3*5))
			Game.SpellsTxt[111].GM=string.format("Damage %s points plus 1-%s per point of skill",math.round(dmgAddTooltip(level,111)/3*7),math.round(diceMaxTooltip(level,111)/3*7))
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
			Game.SpellsTxt[68].Master="5 Mana cost: \ncures 15 + 4 HP per point of skill"
			Game.SpellsTxt[68].GM="8 Mana cost: \ncures 20 + 5 HP per point of skill"
			
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
			Game.SpellsTxt[77].GM="This spell is as good as it will ever get! ...maybe..."
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

-- shared life overflow fix
function randomizeHP()
	for i, pl in Party do
		pl.HP = random(1, pl:GetFullHP())
	end
end

-- TODO: test very negative amounts (like -50000), they asserted previously
function doSharedLife(amount)
	-- for each iteration, try to top up lowest HP deficit party member, increasing others' HP along the way
	local function shouldParticipate(pl)
		return pl.Dead == 0 and pl.Eradicated == 0 and pl.Stoned == 0 -- as in default code
	end

	local activePlayers = {}
	local fullHPs = {}
	amount = amount or 0
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
	assert((pool == result) or everyoneFull, format("Pool %d, result %d, everyoneFull: %s", pool, result, everyoneFull))
	--printf("Steps: %d", steps)
	return affectedPlayers
	--debug.Message(format("%d HP left", amount))
end

-- replace shared life code with my own
hook(0x42A171, function(d)
	local amount = u4[d.ebp - 4]
	local t = getSpellQueueData(d.ebx)
	t.Amount = amount
	events.call("HealingSpellPower", t)
	local affectedPlayers = doSharedLife(t.Amount)
	for i, pl in ipairs(affectedPlayers) do
		mem.call(0x4A6FCE, 1, mem.call(0x42D747, 1, u4[0x75CE00]), const.Spells.SharedLife, getPartyIndex(pl)) -- show animation
	end
end)
asmpatch(0x42A176, "jmp absolute 0x42C200") -- "cast successful"


--removes fly when attacking, except in certain maps
flyAllowedMaps={"elema.odm","elemf.odm","elemw.odm","out12.odm","outa1.odm","outa2.odm","outa3.odm","outb3.odm"}
function events.CalcDamageToMonster(t)
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

function events.LoadMap()
	if table.find(flyAllowedMaps,Map.Name) then 
		Sleep(5)
		Game.ShowStatusText("Fly is allowed without restrictions here")
	end
end

function events.GameInitialized2()
	Game.SpellsTxt[21].Description= "Grants the power of flight to your characters!  This spell is very expensive and only works outdoors, but it is very useful.  Fly will drain one spell point every five minutes it is in use (i.e. when you aren't touching the ground).\n\nWith the exception of few places, attacking monsters will cancel the effect"
end


--WHEN GM ELEMENTAL BUFFS WILL BE GRANTED PASSIVELY
TimerPeriod=const.Minute/2
schools={12,13,14,15,17,18}
buffsOrdered = {6, 0, 17, 4, 12, 1}
function elementalBuffs()
	--buffs to apply
	for i=0, Party.High do
		for v=1,6 do
			s,m=SplitSkill(Party[i]:GetSkill(schools[v]))
			if m==4 then
				if Party.SpellBuffs[buffsOrdered[v]].Power<=s*3 then
					Party.SpellBuffs[buffsOrdered[v]].ExpireTime=Game.Time+const.Hour
					Party.SpellBuffs[buffsOrdered[v]].Power=s*3
					Party.SpellBuffs[buffsOrdered[v]].Skill=4
				end
			end
		end
	end
	if Party.High==0 then
		Party.SpellBuffs[19].ExpireTime=Game.Time+const.Hour
		Party.SpellBuffs[19].Power=10
		Party.SpellBuffs[19].Skill=2
	end
end

function events.AfterLoadMap()
	Timer(elementalBuffs, TimerPeriod, true)
end


---------------------------
----end OF SPELL REWORK----
---------------------------
