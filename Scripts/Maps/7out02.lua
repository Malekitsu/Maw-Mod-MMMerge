
-- Choose Judge quest

evt.Map[37] = function()
	NPCFollowers.Remove(416)
	NPCFollowers.Remove(417)
end

-- Enter castle Harmondale

Game.MapEvtLines:RemoveEvent(301)
evt.Hint = evt.str[30]
evt.Map[301] = function()
	if Party.QBits[519] then
		if Party.QBits[610] or Party.QBits[644] then
			if Party.QBits[610] then
				evt.MoveToMap{-5073, -2842, 1, 512, 0, 0, 382, 9, "7d29.blv"}
			else
				evt.MoveToMap{-5073, -2842, 1, 512, 0, 0, 390, 9, "7d29.blv"}
			end
		else
			Party.QBits[644] = true
			Party.QBits[587] = true

			evt.Add{"History3", 0}
			evt.MoveNPC {397, 240}
			evt.SpeakNPC{397}
		end
	else
		evt.FaceAnimation{Game.CurrentPlayer, const.FaceAnimation.DoorLocked}
	end
end

-- Mercenary guild - invasion

Party.QBits[608] = Party.QBits[611] or Party.QBits[612]

evt.Map[50] = function()
	if (Party.QBits[693] or Party.QBits[694]) and not (Party.QBits[702] or Party.QBits[695]) then
		mapvars.InvasionTime = mapvars.InvasionTime or Game.Time + const.Week*2
		if mapvars.InvasionTime < Game.Time then
			Party.QBits[695] = true
			evt.SetMonGroupBit {60,  const.MonsterBits.Hostile,  true}
			evt.SetMonGroupBit {60,  const.MonsterBits.Invisible, false}
			evt.Set{"BankGold", 0}
			evt.SpeakNPC{437}
		end
	end
end

-- Give "Scavenger hunt" advertisment

local CCTimers = {}

function events.AfterLoadMap()
	if not (mapvars.GotAdvertisment or Party.QBits[519] or evt.All.Cmp{"Inventory", 774}) then

		CCTimers.Catch = function()
			if not (Party.Flying or Party.EnemyDetectorRed or Party.EnemyDetectorYellow)
				and 4000 > math.sqrt((-13115-Party.X)^2 + (12497-Party.Y)^2) then

				mapvars.GotAdvertisment = true
				RemoveTimer(CCTimers.Catch)
				evt.ForPlayer(0).Add{"Inventory", 774}
				evt.SetNPCGreeting(649, 332)
				evt.SpeakNPC{649}

			end
		end
		Timer(CCTimers.Catch, false, const.Minute*3)

	end
end

--MAW
name[300]="Goblin's Liutenant"
if not mapvars.maw then
	mapvars.maw=true
	pseudoSpawnpoint{monster = 106,  x = 7253, y = 5093, z = 481 , count = 1, powerChances = {100, 0, 0}, radius = 0, group = 1, transform = function(mon) mon.NameId=300 mon.Velocity=0 mon.SpellChance=100 end}
end


evt.Map[1000] = function()
	if not mapvars.ambush then
		if Party.X>17390 and Party.X<19429 and Party.Y>-20015 and Party.Y<-19454 and Party.Z<800 then
			Game.ShowStatusText("It's an ambush!")
			pseudoSpawnpoint{monster = 271,  x = 19613, y = -17760, z = 1595 , count = 2, powerChances = {60, 30, 10}, radius = 64, group = 1}
			pseudoSpawnpoint{monster = 271,  x = 19307, y = -18344, z = 1568 , count = 2, powerChances = {60, 30, 10}, radius = 64, group = 1}
			pseudoSpawnpoint{monster = 271,  x = 18344, y = -18861, z = 1666 , count = 2, powerChances = {60, 30, 10}, radius = 64, group = 1}
			pseudoSpawnpoint{monster = 271,  x = 16201, y = -21635, z = 3022  , count = 8, powerChances = {60, 30, 10}, radius = 1400, group = 1}
			mapvars.ambush=true
		end
	end
end
 Timer(evt.map[1000].last, const.Minute*0.5)