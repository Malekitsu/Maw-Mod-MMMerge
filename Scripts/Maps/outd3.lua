
local TXT = {
[1] = evt.str[9]
}

function events.AfterLoadMap()
	LocalHostileTxt()
	Game.HostileTxt[159][0] = 0
	Game.HostileTxt[196][0] = 0
	Game.HostileTxt[196][191] = 2
	Game.HostileTxt[191][196] = 2
	Game.HostileTxt[196][205] = 2
	Game.HostileTxt[205][196] = 1
end

----------------------------------------
-- Release Archibald (mm6)

Game.MapEvtLines:RemoveEvent(42)
evt.house[42] = 1215
evt.Map[42] = function()

	if Party.QBits[1201] then

		if Game.NPC[797].House == 1244 then
			Game.Houses[1244].Picture = 486
		else
			Game.Houses[1244].Picture = 487
		end

		evt.EnterHouse{1244}

	elseif evt.ForPlayer("All").Cmp{"Inventory", 2081} then

		evt.ShowMovie{0, 0, "archie"}
		Game.Houses[1244].Picture = 486
		evt.EnterHouse{1244}

	else
		evt.EnterHouse{1215}
	end

end

----------------------------------------
-- Nicolai's quest (mm6)

Game.MapEvtLines:RemoveEvent(43)
evt.Map[43] = function()

	if Party.QBits[1119] then
		if table.find(vars.NPCFollowers, 798) then
			evt.MoveNPC{798, 222}
			Party.QBits[1700] = false
			Party.QBits[1119] = false
			NPCFollowers.Remove(798)
			evt.ForPlayer{"All"}.Add{"Experience", 7500}
			evt.SetNPCTopic{798, 0, 1337}
			Message(Game.NPCText[1723])
		else
			Message(TXT[1])
		end
		return
	end

	evt.MoveToMap{0, 0, 0, 0, 0, 0, 335, 2, "0"}
	evt.EnterHouse{222}

end -- Other parts are in StdQuestsFollowers.lua

----------------------------------------
-- Loretta Fleise's fix prices quest

Game.MapEvtLines:RemoveEvent(8)
evt.house[8] = 471
evt.map[8] = function() StdQuestsFunctions.CheckPrices(471, 1522) end

Game.MapEvtLines:RemoveEvent(9)
evt.house[9] = 471
evt.map[9] = function() StdQuestsFunctions.CheckPrices(471, 1522) end

----------------------------------------
-- Bandits

Game.MapEvtLines:RemoveEvent(210)
evt.house[210] = ""
evt.map[210] = function()

	if not evt.Cmp{"MapVar4", 0} then
		evt.CastSpell{98, 0, 1, 5784, 11584, 512, 5784, 11584, 0}
		evt.CastSpell{98, 0, 1, 4312, 11600, 512, 4312, 11600, 0}
		Message(evt.str[7])
		Message(evt.str[12])

		local Answer = string.lower(Question(evt.str[8]))
		if Answer == string.lower(evt.str[9]) then

			if Party.Gold >= 100 then
				evt.Subtract{"Gold", 100}
				evt.Set{"MapVar4", 0}
			else
				Message(evt.str[11])
				evt.MoveToMap{4856, 10288, 0, 500, 0, 0, 0, 0, "0"}
			end

		elseif Answer == string.lower(evt.str[10]) then
			evt.SummonMonsters{1, 2, 5, 4920, 12976, 0, 0, 0}
			evt.Set{"MapVar4", 0}
		else
			Message(evt.str[11])
			evt.MoveToMap{4856, 10288, 0, 500, 0, 0, 0, 0, "0"}
		end
	end

end
Game.MapEvtLines:RemoveEvent(261)
evt.hint[261] = evt.str[18]  -- "Shrine of Electricity"
evt.map[261] = function()
	if not evt.Cmp{"QBits", Value = 1230} then         -- NPC
		evt.Set{"QBits", Value = 1230}         -- NPC
		if evt.Cmp{"QBits", Value = 1239} then         -- NPC
			evt.ForPlayer("All")
			evt.Add{"AirResistance", Value = 3}
		else
			evt.Set{"QBits", Value = 1239}         -- NPC
			evt.ForPlayer("All")
			evt.Add{"AirResistance", Value = 10}
			evt.StatusText{Str = 20}         -- "+10 Electricity resistance permanent"
		end
		return
	end
	evt.StatusText{Str = 19}         -- "You pray at the shrine."
end


