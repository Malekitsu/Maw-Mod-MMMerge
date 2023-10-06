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
