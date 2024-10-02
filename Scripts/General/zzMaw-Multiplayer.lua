--initialize events
function events.MultiplayerInitialized()
	Multiplayer.allow_remote_event("mawBuffs")
	Multiplayer.allow_remote_event("MAWMapvarArrived")
end

function mawmapvarsend(name,value)
	if not Multiplayer then return end
	maw={}
	maw["DataType"]="mapvar"
	maw[1]=name
	maw[2]=value
	Multiplayer.broadcast_mapdata(maw,"MAWMapvarArrived")
end

function events.MAWMapvarArrived(t)
	if t["DataType"]=="mapvar" then
		mapvars[t[1]]=t[2]
	end
end

--[[
function events.Tick()
	Game.TurnBased=false
	Game.TurnBasedPhase=0
end
]]

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
		local buffTable={}
		buffTable["DataType"]="mawBuffs"
		buffTable["X"]=Party.X
		buffTable["Y"]=Party.Y
		buffTable["Z"]=Party.Z
		buffTable["Time"]=Game.Time+const.Minute*5
		for key, value in pairs(vars.mawbuff) do
			if vars.mawbuff[key] and type(vars.mawbuff[key])=="number" then
				buffTable[key]={}
				buffTable[key][1],buffTable[key][2],buffTable[key][3]=getBuffSkill(key)
			end
		end
		Multiplayer.broadcast_mapdata(buffTable, "MAWMapvarArrived")
	end
end

function events.MAWMapvarArrived(t)
	if t.DataType=="mawBuffs" then
		if getDistance(t.X,t.Y,t.Z)<10000 then
			for key, value in pairs(t) do
				if type(key)=="number" then
					vars.mawbuff[key]={}
					vars.mawbuff[key][1]=value[1]
					vars.mawbuff[key][2]=value[2]
					vars.mawbuff[key][3]=value[3]
					vars.mawbuff[key][4]=t.Time
				end
			end
		end
	end
end


function events.AfterLoadMap()
	Timer(sendBuffs, const.Minute/2, true)
end
