Game.MapEvtLines:RemoveEvent(15)

evt.hint[15] = evt.str[2]  -- "Door"
evt.map[15] = function()
	if evt.Cmp{"QBits", Value = 20} then         -- Allied with Temple of the Sun. Destroy the Skeleton Transformer done.
		goto _10
	end
	if evt.Cmp{"Players", Value = 34} or Game.NPC[11].EventD==634 then
		if evt.CanPlayerAct{Id = 34} then         -- "Dyson Leyland"
			goto _10
		end
		evt.SetNPCGreeting{NPC = 45, Greeting = 0}         -- "Guard" : ""
	else
		evt.SetNPCGreeting{NPC = 45, Greeting = 107}         -- "Guard" : "Halt! These areas are off limits to guests! Guild members only!"
	end
	if not evt.Cmp{"Invisible", Value = 0} then
		evt.SpeakNPC{NPC = 45}         -- "Guard"
	end
	evt.FaceAnimation{Player = "Current", Animation = 18}
	do return end
::_10::
	evt.SetDoorState{Id = 5, State = 0}
end
Game.MapEvtLines:RemoveEvent(131)
evt.hint[131] = evt.str[100]  -- ""
evt.map[131] = function()
	if not evt.Cmp{"QBits", Value = 27} then         -- Skeleton Transformer Destroyed.
		if evt.Cmp{"QBits", Value = 26} then         -- "Find the skeleton transformer in the Shadowspire Necromancers' Guild. Destroy it and return to Oskar Tyre."
			if evt.Cmp{"Players", Value = 34} or Game.NPC[11].EventD==634 then
				if evt.Cmp{"MapVar19", Value = 15} then
					if evt.CanPlayerAct{Id = 34} then         -- "Dyson Leyland"
						evt.Add{"QBits", Value = 27}         -- Skeleton Transformer Destroyed.
						evt.ShowMovie{DoubleSize = 1, Name = "\"skeltrans\""}
						evt.SetFacetBit{Id = 30, Bit = const.FacetBits.Untouchable, On = true}
						evt.SetFacetBit{Id = 30, Bit = const.FacetBits.Invisible, On = true}
					end
				end
			end
		end
	end
end

