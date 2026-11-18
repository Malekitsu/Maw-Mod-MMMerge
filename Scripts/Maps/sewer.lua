
-----------------------------------------
-- The Prince of thieves quest (mm6)

evt.Map[8] = function()
	if Party.QBits[1701] then
		NPCFollowers.Add(802)
	end
end
