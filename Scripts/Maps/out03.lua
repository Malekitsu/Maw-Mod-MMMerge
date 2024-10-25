Game.MapEvtLines:RemoveEvent(197)
evt.hint[197] = evt.str[100]  -- ""
evt.map[197] = function()
	if not evt.Cmp{"QBits", Value = 59} and evt.Cmp{"QBits", Value = 63} then         -- Returned to the Merchant guild in Alvar with overdune. Quest 25 done.
		evt.ShowMovie{DoubleSize = 1, Name = "\"overrept\""}
		evt.SetNPCTopic{NPC = 5, Index = 0, Event = 43}         -- "Bastian Loudrin" : "Quest"
		evt.SetNPCGreeting{NPC = 5, Greeting = 15}         -- "Bastian Loudrin" : "Good day."
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = 10000}
		evt.Add{"Awards", Value = 5}         -- "Found a witness to the cataclysm in the Ironsand Desert."
		evt.Add{"History6", Value = 0}
		evt.ForPlayer("Current")
		evt.Subtract{"QBits", Value = 25}         -- "Find a witness to the lake of fire's formation. Bring him back to the merchant guild in Alvar."
		evt.Set{"QBits", Value = 13}         -- "Form an alliance among the major factions of Jadame."
		evt.Set{"QBits", Value = 14}         -- "Form an alliance with the Necromancers' Guild in Shadowspire."
		evt.Set{"QBits", Value = 15}         -- "Form an alliance with the Temple of the Sun in Murmurwoods."
		evt.Set{"QBits", Value = 16}         -- "Form an alliance with the Dragon hunters of Garrote Gorge."
		evt.Set{"QBits", Value = 17}         -- "Form an alliance with the Dragons of Garrote Gorge."
		evt.Set{"QBits", Value = 18}         -- "Form an alliance with the Minotaurs of Ravage Roaming."
		evt.Set{"QBits", Value = 59}         -- Returned to the Merchant guild in Alvar with overdune. Quest 25 done.
		evt.Add{"Gold", Value = 4000}
		evt.SetNPCTopic{NPC = 13, Index = 0, Event = 65}         -- "Masul" : "Alliance"
	end
	evt.EnterHouse{Id = 773}         -- "Merchant Guildhouse"
end