
-- Out13.lua bug consequences fix
function events.AfterLoadMap()
	if not Party.QBits[53] then
		Game.NPC[24].House = 662
	end
end
