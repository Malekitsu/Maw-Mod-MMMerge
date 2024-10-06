--initialize events
function events.MultiplayerInitialized()
	Multiplayer.VERSION = "MAW " .. Multiplayer.VERSION
	Multiplayer.allow_remote_event("mawBuffs")
	Multiplayer.allow_remote_event("MAWMapvarArrived")
	Multiplayer.allow_remote_event("mawMultiPlayerData")
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

function events.AfterLoadMap()
	if Multiplayer and Multiplayer.in_game then
		local prevHP={}
		local prevSP={}
		for i=0, Party.High do
			prevHP[i]=Party[i].HP
			prevSP[i]=Party[i].SP
		end
		Party.RestAndHeal()
		for i=0, Party.High do
			Party[i].HP=prevHP[i]
			Party[i].SP=prevSP[i]
		end
	end
end

--------------------------------
--MAW BUFF REWORK BUFF SHARING--
--------------------------------

function sendBuffs()
	if Multiplayer and Multiplayer.in_game then
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
				if not vars.mawbuff[key] and type(key)=="number" then
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
	if buffRework then
		Timer(sendBuffs, const.Minute/2, true)
	end
end

function events.mawMultiPlayerData(t)
	Game.ShowStatusText(t.Message)
end

--Multiplayer.broadcast_questdata({Message = "Hello"}, "mawMultiPlayerData")

------------------------------
--MONSTER RESPAWN FOR ONLINE--
------------------------------

function events.AfterLoadMap()
	if vars.onlineMode and Map.IndoorOrOutdoor==2 then --outdoor, indoor directly reset map
		if mapvars.monsterRespawns==nil then
			mapvars.monsterRespawns={}
			for i=0,Map.Monsters.High do
				local mon=Map.Monsters[i]
				if mon.AIState~=const.AIState.Invisible then --just to make sure not to spawn unintended monsters
					mapvars.monsterRespawns[i]={["X"] = mon.X, ["Y"] = mon.Y, ["Z"] = mon.Z,["deathTime"]=false}
				end
			end
		end
	end
	if vars.onlineMode then
		for i=1,Game.MapStats.High do
			Game.MapStats[i].RefillDays=7
		end
	end
end

function events.MonsterKilled(mon)
	if vars.onlineMode and Map.IndoorOrOutdoor==2 then
		local id=mon:GetIndex()
		if mapvars.monsterRespawns and mapvars.monsterRespawns[id] then
			mapvars.monsterRespawns[id].deathTime=Game.Time
		end
	end
end

function respawnMonsters()
	if vars.onlineMode and mapvars.monsterRespawns then
		for i=0,#mapvars.monsterRespawns do
			local mon=Map.Monsters[i]
			local baseMon=mapvars.monsterRespawns[i]
			if mon and baseMon and ((mon.AIState==const.AIState.Removed and baseMon.deathTime and Game.Time>baseMon.deathTime+const.Hour*5) or (baseMon.deathTime and Game.Time>baseMon.deathTime+const.Week)) then
				mon.HP=mon.FullHP
				mon.AIState=0
				mon.X=baseMon.X
				mon.Y=baseMon.Y
				mon.Z=baseMon.Z
				mon.Ally=0
				--remove bosses
				if mon.NameId>=220 and mon.NameId<=300 then
					if mapvars.uniqueMonsterLevel then
						mapvars.uniqueMonsterLevel[i]=nil
					end
					if mapvars.bossNames then
						mapvars.bossNames[mon.NameId]=nil
						Game.PlaceMonTxt[mon.NameId]=tostring(mon.NameId)
					end
					mon.NameId=0
				end
				recalculateMawMonster()
				--generate bosses
				if mon.Id%3==0 and math.random()<0.2 then
					local found=false
					local freeNameIndex=1
					while not found and freeNameIndex<80 do
						if Game.PlaceMonTxt[freeNameIndex+220]==tostring(freeNameIndex+220) then
							found=true
							generateBoss(i,freeNameIndex)
						else
							freeNameIndex=freeNameIndex+1
						end
					end
				end
			end
		end
	end
end

--avoid spawn right after looting
function events.PickCorpse(t)
	if vars.onlineMode then
		local mon=t.Monster
		local id=mon:GetIndex()
		if mapvars.monsterRespawns and mapvars.monsterRespawns[i] and mapvars.monsterRespawns[i].deathTime then
			mapvars.monsterRespawns[i].deathTime=math.max(mapvars.monsterRespawns[i].deathTime, Game.Time+const.Hour*2)
		end			
	end
end


function events.LoadMap(wasInGame)
	if vars.onlineMode then
		Timer(respawnMonsters, const.Minute*30) 
	end
end

function events.CanSaveGame(t)
	if vars.onlineMode then
		t.Result=false
	end
end


-------------
--EXP SHARE--
-------------
function PlayersOnMap()
	local count = 1
	for k,v in pairs(Multiplayer.connector.clients) do
		if v.map == Map.MapStatsIndex then
			count = count + 1
		end
	end
	return count
end

--share experience for monsters killed by summoned/resurrected Monsters
function events.MonsterKilled(mon)
	if Multiplayer and Multiplayer.in_game then
		data=WhoHitMonster()
		if (data and data.PlayerIndex) or (not data and getDistance(mon.X,mon.Y,mon.Z)<8000) or (data and data.Monster and data.Monster.Ally==9999) then
			local consciousPlayers=0
			for i=0, Party.High do
				if Party[i]:IsConscious() then
					consciousPlayers=consciousPlayers+1
				end
			end
			local players=PlayersOnMap()
			--divide for both, some bonus for multiplayer
			consciousPlayers=consciousPlayers*(0.5+0.5*players)
			for i=0, Party.High do
				if Party[i]:IsConscious() then
					Party[i].Experience=Party[i].Experience+mon.Exp/consciousPlayers
					debug.Message(mon.Exp .. "  " .. consciousPlayers)
				end
			end
		end
	end
end
--Multiplayer.client_monsters()
