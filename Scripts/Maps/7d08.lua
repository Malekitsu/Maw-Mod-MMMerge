
-- Rescue Loren Steel quest (mm7)

evt.map[376] = function()
	if Party.QBits[1695] then
		NPCFollowers.Add(410)
	end
end -- Other Loren's parts are in StdQuestsFollowers.lua
