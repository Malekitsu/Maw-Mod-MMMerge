function p()
	debug.Message(dump(string.format(" x = " .. Party.X .. ", y = " .. Party.Y .. ", z = " .. Party.Z .. " "))) 
end

function mawmapvarsend(name,value)
	if not Multiplayer then return end
	maw={}
	maw[0]="maw mapvar"
	maw[1]=name
	maw[2]=value
	Multiplayer.broadcast_mapdata(maw)
end

function events.MultiplayerUserdataArrived(t)
	if t[0]=="maw mapvar" then
		mapvars[t[1]]=t[2]
	end
end



function events.PlayerCastSpell(t)
	if Multiplayer	 and t.SpellId==68 and t.TargetKind==3 and t.Mastery>0 then
		--return if target is not an online teammate
		if not table.find(Multiplayer.client_monsters(),t.TargetId) then
			return
		end
		local persBonus=t.Player:GetPersonality()/1000
		local intBonus=t.Player:GetIntellect()/1000
		local statBonus=math.max(persBonus,intBonus)
		local crit=t.Player:GetLuck()/1500+0.05
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
		if healData and healData[5] then
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
			healData[5]=false
			Multiplayer.broadcast_mapdata(healData)
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


------------------
--ONLINE HANDLER--
------------------
--here goes instructions for the player receiving the data in the function above
function events.GameInitialized2()
	Multiplayer.allow_remote_event("MAWSpell")
end
function events.MAWSpell(t)
	--return if you are not the target
	if not table.find(t[1],Multiplayer.my_id) then
		return
	end
	if t[0]=="Invisibility" then
		Party.SpellBuffs[11].ExpireTime=t[2]
		Party.SpellBuffs[11].Power=t[3]
		
	elseif t[0]=="Cure Curse" then
		if Party.High==0 then
			local maxHP=Party[0]:GetFullHP()
			Party[0].HP=math.min(Party[0].HP+t[2],maxHP)
			if t[3] then
				Sleep(1)
				Game.ShowStatusText(string.format(t[4] .. " heals you for " .. totHeal .. " Hit points(critical)"))
			else
				Sleep(1)
				Game.ShowStatusText(string.format(t[4] .. " heals you for " .. totHeal .. " Hit points"))
			end
		end
	elseif t[0]=="Heroism" then
		
	elseif t[0]=="Resurrection" then
	
	elseif t[0]=="Heal" then
	
	elseif t[0]=="Greater Heal" then
	
	elseif t[0]=="Power Cure" then
	
	elseif t[0]=="DoG" then
	
	elseif t[0]=="DoP" then
	
	end
end
