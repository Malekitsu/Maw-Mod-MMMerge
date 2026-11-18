-----------------------------------------
-- Rescue Sharry Carnegie quest (mm6)

Game.MapEvtLines:RemoveEvent(22)
evt.map[22] = function()
	if not Party.QBits[1036] then         -- 12 D3, given when you save Mom.
		Party.QBits[1036] = true         -- 12 D3, given when you save Mom.
		Party.QBits[1703] = true         -- Replacement for NPCs 193 ver. 6
		NPCFollowers.Add(978)
		evt.SpeakNPC{NPC = 978}         -- "Sharry Carnegie"
	end
end
