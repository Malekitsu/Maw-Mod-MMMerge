function p()
	debug.Message(dump(string.format(" x = " .. Party.X .. ", y = " .. Party.Y .. ", z = " .. Party.Z .. " "))) 
end

function mawmapvarsend(name,value)
	if not Multiplayer then return end
	maw={}
	maw["DataType"]="mapvar"
	maw[1]=name
	maw[2]=value
	Multiplayer.broadcast_mapdata(maw)
end

function events.MultiplayerUserdataArrived(t)
	if t["DataType"]=="mapvar" then
		mapvars[t[1]]=t[2]
	end
end

function events.Tick()
	Game.TurnBased=false
	Game.TurnBasedPhase=0
end

function events.AfterLoadMap()
	local prevHP={}
	for i=0, Party.High do
		prevHP[i]=Party[i].HP
	end
	Party.RestAndHeal()
	for i=0, Party.High do
		Party[i].HP=prevHP[i]
	end
end

--share buffs
function sendBuffs()
	if Multiplayer then
		local buffTable={["DataType"]="BuffShare"}
		buffTable["X"]=Party.X
		buffTable["Y"]=Party.Y
		buffTable["Z"]=Party.Z
		buffTable["Time"]=Game.Time
		buffTable["Buffs"]={}
		for key, value in pairs(vars.mawbuff) do
			buffTable["Buffs"][key]={getBuffSkill(key)}
		end
		Multiplayer.broadcast_mapdata(buffTable)
	end
end

function events.MultiplayerUserdataArrived(t)
	if t["DataType"]=="BuffShare" then
		if Game.Time-t.Time<const.Hour and getDistance(t.X,t.Y,t.Z)<4048 then
			buffs=t.Buffs
			for key, value in pairs(buffs) do
				vars.mawbuff[key]=buffs[key]
			end
		end
	end
end


function events.AfterLoadMap()
	Timer(sendBuffs, const.Minute/2, true)
end
