
function events.AfterLoadMap()
	LocalHostileTxt()
	Game.HostileTxt[91][0] = 0

	evt.SetMonGroupBit {56,  const.MonsterBits.Hostile,  true}
	evt.SetMonGroupBit {55,  const.MonsterBits.Hostile,  Party.QBits[611]}
end

function events.ExitNPC(i)
	if i == 461 and not Party.QBits[761] then
		evt.SummonMonsters{3, 3, 5, Party.X, Party.Y, Party.Z + 400, 59}
		evt.SetMonGroupBit{59, const.MonsterBits.Hostile, true}
	end
end

mapvars.ambush={}
mapvars.alert={}
--spawn monsters at night
evt.Map[1000] = function()
	local i=math.round(Game.Time/const.Day)
	if not mapvars.ambush[i] then
		if not mapvars.alert[i] then
			if Game.Time%const.Day>=const.Hour*21.5 then
				Game.ShowStatusText("The night is dark and full of terrors")
				mapvars.alert[i]=true
			end
		end
		--from 20 to 4 in the night
		if Game.Time%const.Day>const.Hour*22 or Game.Time%const.Day<const.Hour*4 then
			roll=math.random()
			if roll<0.1 or Game.Time%const.Day>const.Hour*23.90 then
				mapvars.ambush[i]=true
				Game.ShowStatusText("In the night the deads rise")
				spawnCount=10
				mapvars.firstSpawn=true
			end
		end
	end
end
Timer(evt.map[1000].last, const.Minute*5)

evt.Map[1001] = function()
	local i=math.round(Game.Time/const.Day)
	if mapvars.ambush[i] and spawnCount>0 and (Game.Time%const.Day>const.Hour*22 or Game.Time%const.Day<const.Hour*4) then
		if mapvars.firstSpawn then
			pseudoSpawnpoint{monster = 427,  x = Party.X, y = Party.Y, Z = 0, count = 5, powerChances = {50, 35, 15}, radius = 4000, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
			pseudoSpawnpoint{monster = 427,  x = Party.X+4000, y = Party.Y+4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 1160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
			pseudoSpawnpoint{monster = 427,  x = Party.X+4000, y = Party.Y-4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 1160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
			pseudoSpawnpoint{monster = 427,  x = Party.X-4000, y = Party.Y+4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 1160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
			pseudoSpawnpoint{monster = 427,  x = Party.X-4000, y = Party.Y-4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 1160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
			pseudoSpawnpoint{monster = 427,  x = Party.X, y = Party.Y+4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 1160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
			pseudoSpawnpoint{monster = 427,  x = Party.X+4000, y = Party.Y, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 1160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
			pseudoSpawnpoint{monster = 427,  x = Party.X-4000, y = Party.Y, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 1160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
			pseudoSpawnpoint{monster = 427,  x = Party.X, y = Party.Y-4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 1160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
		end
		pseudoSpawnpoint{monster = 427,  x = Party.X, y = Party.Y, Z = 0, count = 3, powerChances = {50, 35, 15}, radius = 4000, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
		pseudoSpawnpoint{monster = 427,  x = Party.X+4000, y = Party.Y+4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 4160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
		pseudoSpawnpoint{monster = 427,  x = Party.X+4000, y = Party.Y-4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 4160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
		pseudoSpawnpoint{monster = 427,  x = Party.X-4000, y = Party.Y+4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 4160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
		pseudoSpawnpoint{monster = 427,  x = Party.X-4000, y = Party.Y-4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 4160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
		pseudoSpawnpoint{monster = 427,  x = Party.X, y = Party.Y+4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 4160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
		pseudoSpawnpoint{monster = 427,  x = Party.X+4000, y = Party.Y, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 4160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
		pseudoSpawnpoint{monster = 427,  x = Party.X-4000, y = Party.Y, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 4160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
		pseudoSpawnpoint{monster = 427,  x = Party.X, y = Party.Y-4000, Z = 0, count = 1, powerChances = {50, 35, 15}, radius = 4160, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 end}
		spawnCount=spawnCount-1
	end
end

Timer(evt.map[1001].last, const.Minute*5)