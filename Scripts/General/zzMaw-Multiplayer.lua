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
		
	elseif t[0]=="Cure Curse" or t[0]=="Heal" or t[0]=="Greater Heal" or t[0]=="Power Cure" or t[0]=="Resurrection" then
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
		if Party.SpellBuffs[9].Power<=t[3] then
			Party.SpellBuffs[9].ExpireTime=t[2]
			Party.SpellBuffs[9].Power = t[3]
		end

	elseif t[0]=="DoG" then
		if Party.SpellBuffs[2].Power<=t[3] then
			Party.SpellBuffs[2].ExpireTime=t[2]
			Party.SpellBuffs[2].Power = t[3]
		end
		
	elseif t[0]=="DoP" then
		for _, buffId in ipairs(dopList) do
			if Party.SpellBuffs[buffId].Power<=t[3] then
				Party.SpellBu ffs[buffId].ExpireTime = t[2]
				Party.SpellBuffs[buffId].Power = t[3]
			end
		end
	end
end
