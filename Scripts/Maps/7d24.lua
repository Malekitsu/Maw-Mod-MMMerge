evt.Map[1000] = function()
	if not mapvars.ambush then
		if Party.X>-8205 and Party.X<-7060 and Party.Y>6216 and Party.Y<7546 then
			mapvars.ambush=true
			Game.ShowStatusText("Monsters swarming...")
			pseudoSpawnpoint{monster = 412,  x = -7532, y = 7495, z = -1535, count = 4, powerChances = {50, 35, 15}, radius = 256, group = 1,transform = function(mon) mon.ShowOnMap = true end}
			spawnCount=20
		end
	end
end
Timer(evt.map[1000].last, const.Minute)

 
evt.Map[1001] = function()
	if mapvars.ambush and spawnCount>0 then
		spawnCount=spawnCount-1
		if spawnCount==0 then
			pseudoSpawnpoint{monster = 296,  x = -7532, y = 7495, z = -1535, count = 1, powerChances = {0, 100, 0}, radius = 256, group = 1,transform = function(mon) mon.ShowOnMap = true mon.HP=mon.HP*2.5 mon.FullHP=mon.HP mon.Attack1Type=0 mon.Attack1Missile = 0 mon.Spell = 6 mon.SpellChance = 25 mon.SpellSkill=3 mon.MoveSpeed=400 mon.MoveType= 0 mon.TreasureItemLevel  = 6 mon.TreasureItemPercent = 100 mon.TreasureItemPercent = 100 end}
			return
		end
		pseudoSpawnpoint{monster = 412,  x = -7532, y = 7495, z = -1535, count = 1, powerChances = {50, 35, 15}, radius = 256, group = 1,transform = function(mon) mon.ShowOnMap = true end}
	end
end
Timer(evt.map[1001].last, const.Minute)
