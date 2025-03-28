
-- Multiplayer: notify other players about button visibility

if Multiplayer then
	local function CheckButtonVisible()
		if evt.Cmp("Players", 34) and evt.CanPlayerAct(34) and evt.Cmp("QBits", 28) then
			evt.SetFacetBit{Id = 5, Bit = const.FacetBits.IsSecret, On = true}
		end
	end
	Timer(CheckButtonVisible, const.Minute)
end
Game.MapEvtLines:RemoveEvent(5)
evt.hint[5] = evt.str[100]  -- ""
evt.map[5] = function()  -- function events.LoadMap()
	if (evt.Cmp{"QBits", Value = 19} or mapvars.mapAffixes) then         -- Allied with Necromancers Guild. Steal Nightshade Brazier done.
		goto _9
	end
	if evt.Cmp{"QBits", Value = 230} then         -- You have Pissed off the clerics
		if not evt.Cmp{"Counter8", Value = 1344} then
			goto _9
		end
		evt.SetMonGroupBit{NPCGroup = 39, Bit = const.MonsterBits.Hostile, On = false}         -- ""
		evt.SetMonGroupBit{NPCGroup = 40, Bit = const.MonsterBits.Hostile, On = false}         -- ""
		evt.Subtract{"QBits", Value = 230}         -- You have Pissed off the clerics
	end
::_11::
	if evt.Cmp{"QBits", Value = 28} or mapvars.mapAffixes then         -- "Bring the Nightshade Brazier to the Necromancers' Guild leader, Sandro. The Brazier is in the Temple of the Sun."
		evt.SetFacetBit{Id = 5, Bit = const.FacetBits.IsSecret, On = true}
		return
	end
	evt.SetFacetBit{Id = 5, Bit = const.FacetBits.IsSecret, On = false}
	do return end
::_9::
	evt.SetMonGroupBit{NPCGroup = 39, Bit = const.MonsterBits.Hostile, On = true}         -- ""
	evt.SetMonGroupBit{NPCGroup = 40, Bit = const.MonsterBits.Hostile, On = true}         -- ""
	goto _11
end

events.LoadMap = evt.map[5].last
Game.MapEvtLines:RemoveEvent(452)
evt.hint[452] = "test"
evt.map[452] = function()
	if evt.Cmp{"QBits", Value = 28} or mapvars.mapAffixes then         -- "Bring the Nightshade Brazier to the Necromancers' Guild leader, Sandro. The Brazier is in the Temple of the Sun."
		evt.SetDoorState{Id = 1, State = 0}
	end
end
