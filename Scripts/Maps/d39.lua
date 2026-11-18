
-- Out13.lua bug consequences fix
function events.AfterLoadMap()
	if not Party.QBits[51] then
		Game.NPC[25].House = 663
	end
end
