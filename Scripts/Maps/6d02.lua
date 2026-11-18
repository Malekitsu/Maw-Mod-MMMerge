
-- Rescue Angela Dowson quest

Game.MapEvtLines:RemoveEvent(14)
evt.Map[14] = function()
	if not Party.QBits[1056] then
		Party.QBits[1056] = true
		Party.QBits[1704] = true
		NPCFollowers.Add(980)
		evt.SpeakNPC{980}
	end
end
