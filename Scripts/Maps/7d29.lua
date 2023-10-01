
-- Golem quest (wizard first promotion) (mm7)

evt.Map[376] = function()
	if Party.QBits[585] or Party.QBits[586] then
		NPCFollowers.Remove(395)
	end
end-- Golem join part is in StdQuestsFollowers.lua

-- Rest cost

function events.CalcRestFoodCost(t)
	if Party.QBits[610] then
		t.Amount = 0
	end
end

--

function events.LeaveMap()
	if Party.QBits[695] and evt.CheckMonstersKilled{1, 60, 0, 6} then
		Party.QBits[696] = true
		Party.QBits[702] = Party.QBits[696] and Party.QBits[697]
		Party.QBits[695] = not Party.QBits[702]
	end
end

Game.MapEvtLines:RemoveEvent(377)
function events.LoadMap()
	if Party.QBits[526] and Party.QBits[695] and not (Party.QBits[696] or Party.QBits[702]) then
		evt.SetMonGroupBit{60, const.MonsterBits.Hostile, true}
		evt.SetMonGroupBit{60, const.MonsterBits.Invisible, false}
		evt.Set{"BankGold", 0}
		evt.Subtract {"QBits", 693}
		evt.Subtract {"QBits", 694}
	else
		evt.SetMonGroupBit{60, const.MonsterBits.Hostile, false}
		evt.SetMonGroupBit{60, const.MonsterBits.Invisible, true}
	end
end

Game.PlaceMonTxt[300]="Goblin King"
evt.map[1000] = function()  
	if not vars.goblingKing and not vars.goblingKing then
		if evt.CheckMonstersKilled{CheckType = 1, Id = 56, Count = 0, InvisibleAsDead = 0} then
			vars.goblingKing=true
			mapvars.goblingKing=true
			mawmapvarsend("goblingKing",true)
			Sleep(1)
			Game.ShowStatusText("Noises from the throne room")
			pseudoSpawnpoint{monster = 271, x = -5110, y = 2852, z = 65, count = 1, powerChances = {0, 0, 100}, radius = 64, group = 1, 
								transform = function(mon) 
								mon.FullHP = mon.FullHP*3 
								mon.HP = mon.FullHP  
								mon.NameId=300
								mon.Velocity=400
								end}
			pseudoSpawnpoint{monster = 271, x = -5122, y = 2219, z = 1, count = 2, powerChances = {0, 100, 0}, radius = 128, group = 1, transform = function(mon) mon.Velocity=400 end}
			pseudoSpawnpoint{monster = 271,  x = -4423, y = 1456, z = 1 , count = 3, powerChances = {100, 0, 0}, radius = 256, group = 1, transform = function(mon) mon.Velocity=400 end}
			pseudoSpawnpoint{monster = 271,  x = -5937, y = 1456, z = 1  , count = 3, powerChances = {100, 0, 0}, radius = 256, group = 1, transform = function(mon) mon.Velocity=400 end}
		end
	end
end


Timer(evt.map[1000].last, const.Minute)
