--leech moved here, to make sure it takes all the damage modifiers
function events.CalcDamageToMonster(t)
		local data=WhoHitMonster()
		if data and data.Player then
			local heal=t.Result^0.6
			local fullHP=data.Player:GetFullHP()
			if getMapAffixPower(32) then
				heal=heal*(1-getMapAffixPower(32)/100)
			end
			if t.DamageKind==4 then
				--melee
				if gotVamp[data.Player:GetIndex()] and not data.Object then
					t.Player.HP=math.min(fullHP,t.Player.HP+heal)
				end
				--ranged
				if gotBowVamp[data.Player:GetIndex()] and data.Object and data.Object.Spell==133 then
					if table.find(aoespells, data.Object.Spell) then
						heal=heal/2
					end
					t.Player.HP=math.min(fullHP,t.Player.HP+heal*0.5)
				end
			elseif data and data.Player then --spell leech
				for i=1,2 do
					it=t.Player:GetActiveItem(i)
					if it and it.Bonus2==40 then
						t.Player.HP=math.min(fullHP,t.Player.HP+heal*0.5)
					end
				end
			end 
		
			local pl=data.Player
			local race=Game.CharacterPortraits[pl.Face].Race
			if race==const.Race.Vampire then
				local heal=heal/4
				if pl.Class==40 or pl.Class==41 then
					heal=heal*2
				end
				if data.Object and data.Object then
					heal=heal/2
				end
				heal=math.ceil(heal)
				t.Player.HP=math.min(fullHP,t.Player.HP+heal)
			end
			if buffRework and getBuffSkill(91)>0 then --vampiric aura buff
				local heal=t.Result^0.6*0.5
				if getMapAffixPower(32) then
					heal=heal*(1-getMapAffixPower(32)/100)
				end
				if t.DamageKind==4 then
					--melee
					if not data.Object then
						t.Player.HP=math.min(fullHP,t.Player.HP+heal)
					end
					--ranged
					if data.Object and data.Object.Spell==133 then
						if table.find(aoespells, data.Object.Spell) then
							heal=heal/2
						end
						t.Player.HP=math.min(fullHP,t.Player.HP+heal*0.5)
					end
				elseif data and data.Player then --spell leech
					t.Player.HP=math.min(fullHP,t.Player.HP+heal*0.5)
				end 
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
		if msgTxt>99999 then
			msgTxt=math.round(msgTxt/1000) .. "K"
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
			critMessage="(CRIT!)"
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
				if critMessage=="(CRIT!)" then
					msg=StrColor(255,255,30,msg)
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
