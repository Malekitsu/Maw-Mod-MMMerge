-- Hidden book switches that did nothing when clicked.
--
-- MM7's Clanker's Laboratory (7d12) and Haunted Mansion (7d37) hide a secret door behind a
-- book sticking out of a shelf (a 7-unit spine, 8 out). The book's front face carries the
-- shelf's "Bookcase" event 200, which only prints an empty status line; the event that opens
-- the door is on the book's sides (8 units deep) and its back, flush with the shelf - so
-- clicking the book, as anyone would, did nothing (seen 2026-10-08 in both). The faces are the
-- same in the merge's maps and in Redone's. At load the front face gets the door's event,
-- through its facet data as the merge's BrBase.lua sets facet events; only while it still
-- carries 200, so a changed map is left alone.

local Fix = {
	["7d12.blv"] = {face = 1817, event = 3},    -- Clanker's Laboratory: doors 17 (the book) and 3
	["7d37.blv"] = {face = 896, event = 10},    -- Haunted Mansion: doors 15 and 16
}

function events.AfterLoadMap()
	local fix = Fix[Map.Name]
	if not fix or fix.face > Map.Facets.High then
		return
	end
	local data = Map.FacetData[Map.Facets[fix.face].DataIndex]
	if data and data.Event == 200 then
		data.Event = fix.event
	end
end
