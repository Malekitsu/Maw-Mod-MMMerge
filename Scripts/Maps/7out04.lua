-- Dimension door

function events.TileSound(t)
	if t.X == 84 and t.Y == 94 then
		TownPortalControls.DimDoorEvent()
	end
end

evt.map[504] = function()
	TownPortalControls.DimDoorEvent()
end

function events.AfterLoadMap()
	local model
	for i,v in Map.Models do
		if v.Name == "ClL1_W" then
			model = v
		end
	end

	if model then
		for i,v in model.Facets do
			v.Event = 504
		end
	end
end

-- Clanker's Laboratory
Game.MapEvtLines:RemoveEvent(503)
evt.map[503] = function()
	if Party.QBits[710] then
		evt.MoveNPC{427, 395}
		Game.Houses[395].ExitMap = 86
		Game.Houses[395].ExitPic = 1
		evt.EnterHouse{395}
	else
		evt.MoveToMap{0,-709,1,512,0,0,395,9,"7d12.blv"}
	end
end

-- Artifact messenger
Game.MapEvtLines:RemoveEvent(401)
function events.LoadMap()
	if Party.QBits[646] then -- Judge Grey died
		return
	end

	if not Party.QBits[649] then -- Already met messenger
		if not Party.QBits[600] then -- Did not talk to Catherine
			return
		end
		if Party.QBits[589] or Party.QBits[590] then -- Any of fraction quests is still active
			return
		end
		evt.SpeakNPC(412) -- "Messenger"
		evt.Add("Inventory", 1502) -- "Message from Erathia"
		evt.Set("QBits", 649) -- Artifact Messenger only happens once
		evt.Set("QBits", 591) -- "Retrieve Gryphonheart's Trumpet from the battle in the Tularean Forest and return it to whichever side you choose."
		evt.Set{"MapVar11", Value = 0}
	end

	if evt.Cmp{"QBits", Value = 591} then -- "Retrieve Gryphonheart's Trumpet from the battle in the Tularean Forest and return it to whichever side you choose."
		if not evt.Cmp{"MapVar11", Value = 1} then
			evt.Set{"MapVar11", Value = 1}
			evt.SetFacetBit{Id = 1, Bit = const.FacetBits.Untouchable, On = false}
			evt.SetFacetBit{Id = 1, Bit = const.FacetBits.Invisible, On = false}
			evt.SummonMonsters{TypeIndexInMapStats = 2, Level = 2, Count = 3, X = -15752, Y = 21272, Z = 3273, NPCGroup = 51, unk = 0}
			evt.SummonMonsters{TypeIndexInMapStats = 2, Level = 2, Count = 5, X = -14000, Y = 18576, Z = 4250, NPCGroup = 51, unk = 0}
			evt.SummonMonsters{TypeIndexInMapStats = 2, Level = 2, Count = 10, X = -16016, Y = 19280, Z = 3284, NPCGroup = 51, unk = 0}
			evt.SummonMonsters{TypeIndexInMapStats = 3, Level = 2, Count = 3, X = -15752, Y = 21272, Z = 3273, NPCGroup = 50, unk = 0}
			evt.SummonMonsters{TypeIndexInMapStats = 3, Level = 2, Count = 9, X = -14000, Y = 18576, Z = 4250, NPCGroup = 50, unk = 0}
			evt.SummonMonsters{TypeIndexInMapStats = 3, Level = 2, Count = 10, X = -16016, Y = 19280, Z = 3284, NPCGroup = 50, unk = 0}
		end
	end
end
