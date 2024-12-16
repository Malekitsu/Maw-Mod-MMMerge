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
		if data and data.Player then
			local mon=t.Monster
			--pick B monster and heal amount
			local id=mon.Id
			if id%3==0 then
				id=id-1
			elseif id%3==1 then
				id=id+1
			end
			local refHP=HPtable[id]
			
			local fullHP=data.Player:GetFullHP()
			
			local heal=t.Result/refHP*fullHP*0.1
			
			if getMapAffixPower(32) then
				heal=heal*(1-getMapAffixPower(32)/100)
			end
			local totalHeal=0
			if t.DamageKind==4 then
				--melee
				if gotVamp[data.Player:GetIndex()] and not data.Object then
					totalHeal=totalHeal+heal
				end
				--ranged
				if gotBowVamp[data.Player:GetIndex()] and data.Object and data.Object.Spell==133 then
					totalHeal=totalHeal+heal*0.5
				end
			elseif data and data.Player then --spell leech
				if data.Object and table.find(aoespells, data.Object.Spell) then
					heal=heal/2
				end
				for i=0,2 do
					it=t.Player:GetActiveItem(i)
					if it and it.Bonus2==40 then
						totalHeal=totalHeal+heal*0.5
					end
				end
			end 
		
			local pl=data.Player
			local race=Game.CharacterPortraits[pl.Face].Race
			if race==const.Race.Vampire then
				local heal=t.Result^0.75*0.25
				if pl.Class==40 or pl.Class==41 then
					heal=heal*2
				end
				if data.Object and data.Object then
					heal=heal/2
				end
				totalHeal=totalHeal+heal
			end
			if buffRework and getBuffSkill(91)>0 then --vampiric aura buff
				local heal=t.Result^0.75*0.5
				if getMapAffixPower(32) then
					heal=heal*(1-getMapAffixPower(32)/100)
				end
				if t.DamageKind==4 then
					--melee
					if not data.Object then
						totalHeal=totalHeal+heal
					end
					--ranged
					if data.Object and data.Object.Spell==133 then
						totalHeal=totalHeal+heal*0.5
					end
				elseif data and data.Player then --spell leech
					if data.Object and table.find(aoespells, data.Object.Spell) then
						heal=heal/2
					end
					totalHeal=totalHeal+heal*0.5
				end 
			end
			overHeal=t.Player.HP+totalHeal-fullHP
			t.Player.HP=math.min(fullHP,t.Player.HP+totalHeal)
			local id=t.PlayerIndex
			if overHeal>0 and vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 27) then
				local id=pickLowestPartyMember()
				Party[id].HP=Party[id].HP+overHeal
			end
		end
	end

function events.CalcDamageToMonster(t)
	-- disable damage on friendly units
	if disableDamageOnFriendlyUnits and t.Player and t.Monster and t.Monster.Hostile==false and t.Monster.ShowAsHostile==false then
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
		MSGdamage=MSGdamage+math.ceil(t.Result)*divide
		local msgTxt=MSGdamage
		if msgTxt>9999999999 then
			msgTxt=StrColor(255,0,0,math.round(msgTxt/1000000) .. "B")
		elseif msgTxt>9999999 then
			msgTxt=StrColor(255,165,0,math.round(msgTxt/1000000) .. "M")
		elseif msgTxt>9999 then
			msgTxt=StrColor(255,255,30,math.round(msgTxt/1000) .. "K")
		end
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
	if t.Result>32500 then
		t.Result=32500
	end
end
