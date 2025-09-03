local REMOTE_OWNER_BIT=0x800
function events.CalcDamageToMonster(t)
	local source = WhoHitMonster()
	if source then
		local obj = source.Object
		if obj and bit.And(obj.Bits, REMOTE_OWNER_BIT) > 0 then
			t.Result = 0 -- let owner calculate damage
		end
	end
end
local aoespellsMultiplayer={6,9,22,41,97}
function events.CalcDamageToPlayer(t)
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
--leech moved here, to make sure it takes all the damage modifiers
function events.CalcDamageToMonster(t)
	local data=WhoHitMonster()
	if data and data.Player and t.Result>0 then
		local partyHP=0
		for i=0,Party.High do
			if Party[i].Dead==0 and Party[i].Eradicated==0 then
				partyHP=partyHP+Party[i].HP
			end
		end
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
		
		local fullHP=GetMaxHP(pl)
		local manaLeechLeg=false
		if vars.legendaries and vars.legendaries[index] and table.find(vars.legendaries[index], 31) then
			fullHP=getMaxMana(pl)
			manaLeechLeg=true
		end
		local baselineHeal=t.Result/refHP*fullHP --basically dealing 100% of monster B HP as damage heals you by 100%
		
		if getMapAffixPower(32) then
			heal=heal*(1-getMapAffixPower(32)/100)
		end
		local totalHeal=0
		local minLeech=0
		if not lifeLeech or not lifeLeech[index] then return end
		
		if t.DamageKind==4 then
			--melee
			if not data.Object then
				totalHeal=baselineHeal*lifeLeech[index].Melee
				
				local recovery=pl:GetAttackDelay()
				minLeech=fullHP*lifeLeech[index].Melee/5*recovery/100
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
		if spell>0 and spell<132 then
			totalHeal=baselineHeal*lifeLeech[index].Spell
			
			local recovery=getSpellDelay(pl,data.Spell)
			minLeech=fullHP*lifeLeech[index].Spell/5*recovery/100
			if table.find(aoespells, spell) then
				minLeech=minLeech/2.5
			end
			if spell==9 or spell==22 or spell==43 then
				minLeech=minLeech/4
			end
		end 
		
		totalHeal=math.ceil(math.max(totalHeal, minLeech))
		
		local overHeal=0
		if manaLeechLeg then
			totalHeal=totalHeal/2
			pl.SP=math.min(getMaxMana(pl),pl.SP+totalHeal)
			return
		else
			overHeal=round(pl.HP+totalHeal-fullHP)
			pl.HP=math.min(fullHP,pl.HP+totalHeal)
		end
		if overHeal>0 and vars.legendaries and vars.legendaries[index] and table.find(vars.legendaries[index], 27) then
			local id, lowestHealthPercentage=pickLowestPartyMember()
			local percent, partyId, playerId=OnlineLowestHealthPercentage()
			if percent<lowestHealthPercentage then
				SendHeal(partyId, playerId, overHeal, pl.Name)
			else
				Party[id].HP=math.min(Party[id].HP+overHeal, fullHP)
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
			local id=pl:GetIndex()
			vars.leechDone=vars.leechDone or {}
			vars.leechDone[id]=vars.leechDone[id] or 0
			vars.leechDone[id]=vars.leechDone[id] + healing
			mapvars.leechDone=mapvars.leechDone or {}
			mapvars.leechDone[id]=mapvars.leechDone[id] or 0
			mapvars.leechDone[id]=mapvars.leechDone[id] + healing
		end
	end
end

function events.CalcDamageToMonster(t)
	-- disable damage on friendly units
	if vars.MAWSETTINGS.friendlyDamage=="OFF" and t.Player and t.Monster and t.Monster.Hostile==false and t.Monster.ShowAsHostile==false then
		t.Result=0
	end
	if t.Result==0 then return end
	
	local data=WhoHitMonster()
	
	--recount
	if data and data.Player then
		local damage=t.Result
		if data.Spell==44 then
			if t.Monster.Resistances[0]>=1000 then
				damage=damage*2^math.floor(t.Monster.Resistances[0]/1000)
			end
		end
		
		if data.Object then
			vars.damageTrackRanged=vars.damageTrackRanged or {}
			vars.damageTrackRanged[data.Player:GetIndex()]=vars.damageTrackRanged[data.Player:GetIndex()] or 0
			vars.damageTrackRanged[data.Player:GetIndex()] = vars.damageTrackRanged[data.Player:GetIndex()] + damage
			mapvars.damageTrackRanged=mapvars.damageTrackRanged or {}
			mapvars.damageTrackRanged[data.Player:GetIndex()]=mapvars.damageTrackRanged[data.Player:GetIndex()] or 0
			mapvars.damageTrackRanged[data.Player:GetIndex()] = mapvars.damageTrackRanged[data.Player:GetIndex()] + damage
		else
			vars.damageTrack=vars.damageTrack or {}
			vars.damageTrack[data.Player:GetIndex()]=vars.damageTrack[data.Player:GetIndex()] or 0
			vars.damageTrack[data.Player:GetIndex()] = vars.damageTrack[data.Player:GetIndex()] + damage
			mapvars.damageTrack=mapvars.damageTrack or {}
			mapvars.damageTrack[data.Player:GetIndex()]=mapvars.damageTrack[data.Player:GetIndex()] or 0
			mapvars.damageTrack[data.Player:GetIndex()] = mapvars.damageTrack[data.Player:GetIndex()] + damage
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
		for i=0, Party.High do
			if Party[i]:GetIndex()==t.PlayerIndex then
				checkSkills(i) --to use the correct spell name
			end
		end
		MSGdamage=MSGdamage or 0
		MSGdamage=MSGdamage+math.ceil(t.Result*divide)
		local msgTxt=MSGdamage
		msgTxt=shortenNumber(msgTxt, 4, true)
		attackIsSpell=false
		castedAoe=false
		shoot="hits"
		kill=""
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
			kill="killing"
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
		function events.Tick()
			events.Remove("Tick", 1)
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
		end
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
