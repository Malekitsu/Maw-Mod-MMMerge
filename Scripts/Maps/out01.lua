-- Dimension door

function events.TileSound(t)
	if t.X == 63 and t.Y == 59 then
		TownPortalControls.DimDoorEvent()
	end
end

-- Town portal

function events.LoadMap()
	Party.QBits[185] = true
end

Game.MapEvtLines:RemoveEvent(463)
evt.hint[463] = evt.str[100]  -- ""
evt.map[463] = function()  -- Timer(<function>, 10*const.Minute)
	if evt.Cmp{"QBits", Value = 6} then         -- Pirate Leader in Dagger Wound Pirate Outpost killed (quest given at Q Bit 5). Ends pirate/lizardman war on Dagger Wound. Shuts off pirate timer.
		return
	end
	mapvars.piratesSpawned=mapvars.piratesSpawned or 0
	if vars.insanityMode and mapvars.piratesSpawned>25 then return end
	if evt.CheckMonstersKilled{CheckType = 1, Id = 10, Count = 0, InvisibleAsDead = 1} then
		evt.SummonMonsters{TypeIndexInMapStats = 2, Level = 2, Count = 3, X = 776, Y = -66192, Z = 0, NPCGroup = 10, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 2, Level = 2, Count = 3, X = 0, Y = -5608, Z = 0, NPCGroup = 10, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 2, Level = 2, Count = 3, X = -656, Y = -5696, Z = 23, NPCGroup = 10, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 2, Level = 2, Count = 3, X = -1280, Y = -5720, Z = 0, NPCGroup = 10, unk = 0}         -- ""
		mapvars.piratesSpawned=mapvars.piratesSpawned+1
	end
	if evt.CheckMonstersKilled{CheckType = 1, Id = 11, Count = 0, InvisibleAsDead = 1} then
		evt.SummonMonsters{TypeIndexInMapStats = 2, Level = 2, Count = 3, X = -2744, Y = 4864, Z = 176, NPCGroup = 11, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 2, Level = 2, Count = 3, X = -2984, Y = 4208, Z = 561, NPCGroup = 11, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 2, Level = 2, Count = 3, X = -3624, Y = 4280, Z = 400, NPCGroup = 11, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 2, Level = 2, Count = 3, X = -3504, Y = 4992, Z = 74, NPCGroup = 11, unk = 0}         -- ""
		mapvars.piratesSpawned=mapvars.piratesSpawned+1
	end
	if evt.CheckMonstersKilled{CheckType = 1, Id = 12, Count = 0, InvisibleAsDead = 1} then
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 2, Count = 3, X = 5208, Y = -736, Z = 46, NPCGroup = 12, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 2, Count = 3, X = 3120, Y = 800, Z = 226, NPCGroup = 12, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 2, Count = 3, X = 3480, Y = -2656, Z = 88, NPCGroup = 12, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 2, Count = 3, X = 2080, Y = -2248, Z = 539, NPCGroup = 12, unk = 0}         -- ""
	end
	if evt.CheckMonstersKilled{CheckType = 1, Id = 13, Count = 0, InvisibleAsDead = 1} then
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 2, Count = 3, X = -896, Y = 55504, Z = 384, NPCGroup = 13, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 2, Count = 3, X = -104, Y = 5328, Z = 384, NPCGroup = 13, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 2, Count = 3, X = -880, Y = 4464, Z = 510, NPCGroup = 13, unk = 0}         -- ""
		evt.SummonMonsters{TypeIndexInMapStats = 1, Level = 2, Count = 3, X = -1256, Y = 5296, Z = 241, NPCGroup = 13, unk = 0}         -- ""
	end
end
