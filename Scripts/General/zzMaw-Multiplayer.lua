function p()
	debug.Message(dump(string.format(" x = " .. Party.X .. ", y = " .. Party.Y .. ", z = " .. Party.Z .. " "))) 
end

function mawmapvarsend(name,value)
	maw={}
	maw[0]="maw mapvar"
	maw[1]=name
	maw[2]=value
	Multiplayer.broadcast_mapdata(maw)
end

function events.MultiplayerUserdataArrived(t)
	if t[0]=="maw mapvar" then
		mapvars.maw=mapvars.maw or {}
		mapvars.maw[t[1]]=t[2]
	end
end



function events.PlayerCastSpell(t)
	if Multiplayer	 and t.SpellId==68 and t.TargetKind==3 and t.Mastery>0 then
		--return if target is not an online teammate
		if not table.find(Multiplayer.client_monsters(),t.TargetId) then
			return
		end
		local persBonus=Party[Game.CurrentPlayer]:GetPersonality()/1000
		local intBonus=Party[Game.CurrentPlayer]:GetIntellect()/1000
		local statBonus=math.max(persBonus,intBonus)
		local crit=Party[Game.CurrentPlayer]:GetLuck()/1500+0.05
		local baseHeal=(5+(t.Mastery+1)*t.Skill)
		local extraHeal=baseHeal*statBonus
		roll=math.random()
		local gotCrit=false
		if roll<crit then
			extraHeal=(extraHeal+baseHeal)*(1.5+statBonus*3/2)-baseHeal
			gotCrit=true
		end
		if gotCrit then
			Sleep(1)
			Game.ShowStatusText(string.format("You Heal for " .. math.round(baseHeal+extraHeal) .. " Hit points(crit)"))
		else
			Sleep(1)
			Game.ShowStatusText(string.format("You Heal for " .. math.round(baseHeal+extraHeal) .. " Hit points"))
		end
		healData={}
		healData[0]="heal"
		healData[1]=math.round(extraHeal)
		healData[2]=gotCrit
		healData[3]=t.Player.Name
		healData[4]=math.round(baseHeal+extraHeal)
		healData[5]=true
		Multiplayer.broadcast_mapdata(healData)
	end
	if Multiplayer and t.SpellId==68 and t.TargetKind==4 then
		if healData and healData[1] then
			Party[t.TargetId].HP=Party[t.TargetId].HP+healData[1]
			if Party.High==0 then
				Sleep(1)
				Game.ShowStatusText(string.format(healData[3] .. " critical heals you for " .. healData[4] .. " hit points"))
			elseif	healData[2] then
				Sleep(1)
				Game.ShowStatusText(string.format(healData[3] .. " critical heals " .. Party[t.TargetId].Name .. " for " .. healData[4] .. " hit points"))
			else
				Sleep(1)
				Game.ShowStatusText(string.format(healData[3] .. " heals " .. Party[t.TargetId].Name .. " for " .. healData[4] .. " hit points"))
			end
			healData[1]=false
			Multiplayer.broadcast_mapdata(healCast)
		end
	end
end

function events.MultiplayerUserdataArrived(t)
	if t[0]=="heal" then
		for i=0,5 do
			healData[i]=t[i]
		end
	end
end
