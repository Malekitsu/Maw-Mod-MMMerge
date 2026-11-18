
local function BadEnd()
	local t = {Type = "Bad", Handled = false}
	events.Call("MM6Ending", t)
	if t.Handled then
		return
	end

	evt.ShowMovie{1,0,"mm6end2"}
	evt.PlaySound{130}

	-- exit to main menu
	--mem.u4[0x6ceb28] = 7
	DoGameAction(132, 0, 0, true)
	DoGameAction(132)
end

local function GoodEnd()
	local t = {Type = "Good", Handled = false}
	events.Call("MM6Ending", t)
	if t.Handled then
		return
	end

	Party.QBits[784] = true -- MM6 story completed
	if vars.Quest_CrossContinents then
		vars.Quest_CrossContinents.ContinentFinished[3] = true
	end
	evt.Subtract{"QBits", 1222}
	evt.Subtract{"Inventory", 2164}
	evt.ForPlayer("All").Set{"Awards", 78}

	evt.ShowMovie{1,0,"mm6end1"}
end

function events.CalcDamageToMonster(t)
	if (t.Monster.Id == 647 or t.Monster.Id == 648) and t.DamageKind == 4 then
		t.Result = math.random(2, 40)
	end
end

function events.MonsterKilled(mon)
	if mapvars.ReactorKilled and mon.Id == 646 then
		mapvars.QueenKilled = true
		Party.QBits[1226] = true

	elseif mon.Id == 647 or mon.Id == 648 then
		
		local t =  {HaveScroll = evt.ForPlayer("All").Cmp{"Inventory", 2164}}
		events.Call("MM6ReactorKilled", t)
		
		if t.HaveScroll then
			mapvars.ReactorKilled = true

			evt.SummonMonsters(2, 3, 1, 4352, 20096, -2256)
			evt.SummonMonsters(2, 3, 1, 6016, 21504, -2256)
			evt.SummonMonsters(2, 3, 1, 2816, 22016, -2256)
			evt.SummonMonsters(1, 3, 1, 4352, 24704, -2256)
			evt.SummonMonsters(1, 3, 1, 2944, 23552, -2256)
			evt.SummonMonsters(1, 3, 1, 6144, 23424, -2256)
			evt.SummonMonsters(2, 3, 1, 2688, 19840, -2256)
			evt.SummonMonsters(2, 3, 1, 1920, 21760, -2256)
			evt.SummonMonsters(2, 3, 1, 6144, 19840, -2256)
			evt.SummonMonsters(2, 3, 1, 7168, 21760, -2256)
			evt.SummonMonsters(1, 3, 1, 2584, 25728, -2256)
			evt.SummonMonsters(1, 3, 1, 5248, 25728, -2256)
			evt.SummonMonsters(1, 3, 1, 1792, 23168, -2256)
			evt.SummonMonsters(1, 3, 1, 2688, 25216, -2256)
			evt.SummonMonsters(1, 3, 1, 7296, 23040, -2256)
			evt.SummonMonsters(1, 3, 1, 6144, 25088, -2256)
			evt.SetDoorState(28, 0)
			evt.SetDoorState(30, 1)
			evt.SetDoorState(51, 0)
			evt.SetDoorState(52, 0)
			evt.SetDoorState(53, 1)
			Party.X = 3328 + math.random(-120, 120)
			Party.Y = 25920 + math.random(-120, 120)
			Party.Direction = 512

			for _, pl in Party do
				for i = 0, 13 do
					pl.Conditions[i] = 0
				end
				pl.Conditions[15] = 0
			end
			Party.RestAndHeal()

		else
			BadEnd()
		end

	end
end

function events.LeaveMap()
	if mapvars.ReactorKilled then
		if mapvars.QueenKilled then
			GoodEnd()
		else
			BadEnd()
		end
	end
end

function events.ShowDeathMovie(t)
	if mapvars.ReactorKilled and not mapvars.QueenKilled then
		t.movie = ""
	end
end

Game.MapEvtLines:RemoveEvent(60)
evt.hint[60] = evt.str[27]
evt.Map[60] = function()
	if evt.Cmp{"QBits", 1226} then
		evt.MoveToMap{0,0,0,0,0,0,0,0,"oute3.odm"}
	else
		evt.StatusText{25}
	end
end

