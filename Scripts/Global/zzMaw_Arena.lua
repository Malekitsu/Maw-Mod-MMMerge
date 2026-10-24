QuestNPC = 313
Greeting{
NPC = 313,
Text = "Welcome to the arena, warriors! This might be different than you remember. Prepare yourselves, sharpen your skills, and brace for the challenge ahead. Get ready to showcase your strength, strategy, and determination. The battle awaits!"
}

local ARENA_MAP="d42.blv"
local PUPPET_AITYPE=Multiplayer and Multiplayer.PUPPET_AITYPE
local arenaOwner
local arenaAnnounce
local arenaReloading
local arenaBuffSnapshot

if Multiplayer and Multiplayer.allow_remote_event then
	for _, name in ipairs{"MawArenaRequest", "MawArenaStart", "MawArenaProgress", "MawArenaEnd"} do
		Multiplayer.allow_remote_event(name)
	end
end

local function online()
	return MawCore.Sync.inGame()
end

local function myId()
	return online() and Multiplayer.my_id or 0
end

local function resetArenaState()
	stop=true
	isArenaStarted=false
	arenaOwner=nil
	arenaAnnounce=nil
end

local function arenaOwnerPresent()
	local c=Multiplayer.connector and Multiplayer.connector.clients[arenaOwner]
	return c and c.in_game and c.map==Map.MapStatsIndex
end

local function setArenaProgress(percent)
	completition.Text=string.format(percent) .. "%"
	if online() then
		Multiplayer.broadcast_mapdata({owner=myId(), percent=percent}, "MawArenaProgress")
	end
end

local function rewardArena(level)
	resetArenaState()
	Message("Level " .. level .. " completed!")
	evt.Add("Gold",level*20000)
	vars.highestArenaWave=math.max(vars.highestArenaWave, level)
	arenaTopic()
end

local function abortArena()
	resetArenaState()
	completition.Text=""
	arenaTopic()
end

function events.LoadMap()
	vars.highestArenaWave=vars.highestArenaWave or 0
	if Map.Name==ARENA_MAP then
		Timer(arenaSpawns, const.Minute*2.5)
		if not isArenaStarted then
			arenaTopic()
			stop=true
			if online() then
				Multiplayer.broadcast_mapdata({sender=myId(), join=true}, "MawArenaRequest")
			end
		end
	else
		stop=false
		isArenaStarted=false
		arenaOwner=nil
		arenaAnnounce=nil
	end
end

function arenaTopic()
	local txt="It looks like you've never tried the Endless Waves mode before. In this mode, waves of enemies will keep appearing, growing stronger over time. Everytime you clear a level, your progress is saved, and you can start from the latest checkpoint. Prepare yourself for a relentless challenge!"
	QuestNPC = 313
	Quest{
		Slot = 1,
		Ungive = function(t) startArena() end,
		Texts = {
			Topic = "Endless Arena",
			Ungive = txt,
		}
	}
end	

function startArena()
	QuestNPC = 313
	Quest{
	Slot = 1,
	Ungive = function(t) arenaStarted() end,
	Texts = {
		  Topic = "Start Level "  .. vars.highestArenaWave+1,
		  Ungive = "Let's get started!",
		}
	}
end

local function reloadArena()
	arenaReloading=true
	local function move()
		arenaBuffSnapshot=MawCore.Engine.snapshotPlayerBuffs()
		if online() and arenaOwner==myId() then
			Multiplayer.LoadMapData[Map.MapStatsIndex]=true
		end
		evt.MoveToMap{X = 3850, Y = 5776, Z = 1, Direction = 512, LookAngle = 0, SpeedZ = 0, HouseId = 0, Icon = 0, Name = ARENA_MAP}
	end
	if online() then
		Multiplayer.utils.ExitToScreen0(move)
	else
		ExitCurrentScreen()
		Sleep(100,100)
		move()
	end
end

local function beginArena(level, owner, reload)
	QuestNPC = 313
	Quest{Slot = 0,
	Texts = {
		  CanShow =false
		}
	}
	Quest{Slot = 1,
	Texts = {
		  CanShow =false
		}
	}
	arenaOwner=owner
	arenaAnnounce=reload and owner==myId() and online() or nil
	startGeneratingWaves(level, reload)
end

local function arenaRequest(t)
	if isArenaStarted and arenaOwner~=myId() and t.sender==arenaOwner then
		abortArena()
		return
	end
	if isArenaStarted then
		if arenaOwner==myId() and not arenaAnnounce and online() then
			Multiplayer.broadcast_mapdata({owner=arenaOwner, level=currentArenaLevel, reload=false}, "MawArenaStart")
		end
		return
	end
	if t.join or online() and not MawCore.Sync.isMainOnMap() then
		return
	end
	beginArena(vars.highestArenaWave+1, myId(), true)
end

function arenaStarted()
	local t={sender=myId()}
	if online() then
		Multiplayer.broadcast_mapdata(t, "MawArenaRequest")
	end
	arenaRequest(t)
end

monsterSpawnLocation={ --Z is 1
	--center
	[1]={3850,9350},
	--right side
	[2]={4600,9350},
	[3]={5500,8600},
	[4]={6500,7600},
	[5]={6500,6600},
	[6]={6500,5600},
	[7]={6500,3600},
	
	--left side
	[8]={2200,8600},
	[9]={1200,7600},
	[10]={1200,6600},
	[11]={1200,5600},
	[12]={1200,4600},
	[13]={1200,3600},
	[14]={3100,9350},
}

function startGeneratingWaves(level, reload)
	currentArenaLevel=level
	currentWave=level*3-2
	wavesToSpawn=3
	totalWaves=wavesToSpawn
	stop=false
	isArenaStarted=true
	bossSpawned=0
	removedWaves=0
	waveState=1
	if reload then
		reloadArena()
	end
end

function events.AfterLoadMap()
	if arenaBuffSnapshot and Map.Name==ARENA_MAP then
		MawCore.Engine.restorePlayerBuffs(arenaBuffSnapshot)
	end
	arenaBuffSnapshot=nil
	arenaReloading=nil
	if arenaAnnounce and Map.Name==ARENA_MAP and isArenaStarted and online() then
		Multiplayer.broadcast_mapdata({owner=myId(), level=currentArenaLevel, reload=true}, "MawArenaStart")
	end
	arenaAnnounce=nil
end

function arenaSpawns()
	if isArenaStarted and arenaOwner~=myId() then
		if not online() or not arenaOwnerPresent() then
			abortArena()
		end
		return
	end
	if stop or arenaReloading then
		return
	end
	levelCompleted=true
	for i=0,Map.Monsters.High do
		if Map.Monsters[i].AIState==5  and Map.Monsters[i].NameId==0 then
			Map.Monsters[i].AIState=11
		end
		if Map.Monsters[i].AIState~=11 and Map.Monsters[i].AIType~=PUPPET_AITYPE and Map.Monsters[i].Ally~=9999 then
			levelCompleted=false
		end
	end	
	
	
	if wavesToSpawn==0 then
		if levelCompleted then
			stop=true
			endArena(currentArenaLevel)
		end
		return
	end
	
	if waitNextWave and waitNextWave>0 then
		if levelCompleted then
			waitNextWave=0
		else
			waitNextWave=waitNextWave-1
			return
		end
	end
	
	local tableId=currentWave%#monTbl
	if tableId==0 then
		tableId=#monTbl
	end
	local spawn=monTbl[tableId].Index-1
	
	waveState=waveState or 1
	
	local p1=0
	local p2=0
	local p3=0
	local wave={
		[1]={["p1"]=80,["p2"]=20,["p3"]=0,["N"]=math.random(8,10)},
		[2]={["p1"]=65,["p2"]=25,["p3"]=10,["N"]=math.random(6,8)},
		[3]={["p1"]=50,["p2"]=30,["p3"]=20,["N"]=math.random(4,6)},
		[4]={["p1"]=35,["p2"]=35,["p3"]=30,["N"]=math.random(3,4)},
		[5]={["p1"]=20,["p2"]=40,["p3"]=40,["N"]=math.random(2,4)},
		[6]={["p1"]=0,["p2"]=0,["p3"]=100,["N"]=1},
	}
	

	for i=1,wave[waveState].N do
		local location=monsterSpawnLocation[math.random(1,#monsterSpawnLocation)]
		pseudoSpawnpoint{monster = spawn,  x = location[1], y = location[2], z = 1, count = 1, powerChances = {wave[waveState].p1, wave[waveState].p2, wave[waveState].p3}, radius = 256, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.ShowAsHostile = true mon.Velocity=350 bossId=mon:GetIndex() end}
	end
	if waveState==6 then
		bossSpawned=bossSpawned or 0
		bossSpawned=bossSpawned+1
		generateBoss(bossId)
	end
	waitNextWave=1
	waveState=waveState+1
	if waveState>6 then
		currentWave=currentWave+1
		wavesToSpawn=wavesToSpawn-1
		waveState=1
		waitNextWave=12
	end
	local n=3
	local m=(3-wavesToSpawn)+(waveState-1)/6
	local percent=math.round(m/n*100)
	setArenaProgress(percent)
end

function events.PickCorpse(t)
	local mon=t.Monster
	if Map.Name=="d42.blv" and mon.NameId==0 then
		mon.TreasureItemPercent=0
		mon.TreasureDiceCount=0
		mon.TreasureDiceSides=0
	end
end

function endArena(level)
	if online() then
		Multiplayer.broadcast_questdata({owner=myId(), level=level}, "MawArenaEnd")
	end
	rewardArena(level)
end

function events.MawArenaRequest(t)
	if Map.Name==ARENA_MAP then
		arenaRequest(t)
	end
end

function events.MawArenaStart(t)
	if Map.Name~=ARENA_MAP or t.owner==myId() then
		return
	end
	if isArenaStarted and arenaOwner==t.owner and currentArenaLevel==t.level then
		return
	end
	beginArena(t.level, t.owner, t.reload)
end

function events.MawArenaProgress(t)
	if Map.Name==ARENA_MAP and isArenaStarted and arenaOwner==t.owner then
		completition.Text=string.format(t.percent) .. "%"
	end
end

function events.MawArenaEnd(t)
	if online() and Multiplayer.im_host() then
		vars.highestArenaWave=math.max(vars.highestArenaWave, t.level)
	end
	if Map.Name==ARENA_MAP and isArenaStarted and arenaOwner==t.owner and currentArenaLevel==t.level then
		rewardArena(t.level)
	end
end

function events.ProcessGameData()
	if isArenaStarted then
		abortArena()
	end
end

--[[unfortunately is buggy and will not save many values
function events.CanSaveGame(t)
	if mapvars.ArenaCompleted then
		t.Result=true
	end
end
]]
