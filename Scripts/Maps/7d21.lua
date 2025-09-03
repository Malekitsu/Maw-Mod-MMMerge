evt.Map[1000] = function()
	if not mapvars.ambush then
		if Party.X>-1183 and Party.X<526 and Party.Y>10342 and Party.Y<12144 then
			mapvars.ambush=true
			mawmapvarsend("ambush",true)
			mawmapvarsend("ambush2",true)
			Game.ShowStatusText("It's a trap!")
			pseudoSpawnpoint{monster = 412,  x = -3723, y = 9579, z = 1, count = 8, powerChances = {70, 30, 0}, radius = 256, group = 1,transform = function(mon) mon.ShowOnMap = true mon.ShowAsHostile = mon:IsAgainst() ~= 0 end}
		end
	end
end
Timer(evt.map[1000].last, const.Minute)

evt.Map[1001] = function()
	if mapvars.ambush and not mapvars.ambush2 then
		if Party.X>-5321 and Party.X<-4316 and Party.Y>8514 and Party.Y<9882 then
			mapvars.ambush2=true
			Game.ShowStatusText("Queen Arrived!")
			pseudoSpawnpoint{monster = 412,  x = -6396, y = 6862, z = 1, count = 10, powerChances = {70, 30, 0}, radius = 256, group = 1, transform = function(mon) mon.ShowOnMap = true mon.ShowAsHostile = mon:IsAgainst() ~= 0 end}
			pseudoSpawnpoint{monster = 412,  x = -6396, y = 6862, z = 1, count = 1, powerChances = {0, 0, 100}, radius = 256, group = 1 ,transform = function(mon)
								mon.FullHP = mon.FullHP*2
								mon.HP = mon.FullHP 
								mon.ShowOnMap = true
								mon.ShowAsHostile = mon:IsAgainst() ~= 0
								end}
		end
	end
end
Timer(evt.map[1001].last, const.Minute)
