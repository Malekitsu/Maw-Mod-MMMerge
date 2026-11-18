local random = math.random

---- Parse table

local TravelsTable = {}
Game.OutdoorTravels = TravelsTable

function ParseTravelsTable(FilePath, Table)

	local File	= io.open(FilePath)

	if not File then
		return
	end

	local LineIt 	= File:lines()
	LineIt()

	for line in LineIt do
		local Words = string.split(line, "\9")
		if string.len(Words[1]) == 0 then
			break
		end

		local Key = string.lower(Words[1])

		Table[Key] = {}

		if string.len(Words[2]) > 0 then
			Table[Key].up 		= {map = Words[2], side = tonumber(Words[3]) or Words[3], days = tonumber(Words[4]) or 0}
		end

		if string.len(Words[5]) > 0 then
			Table[Key].down 	= {map = Words[5], side = tonumber(Words[6]) or Words[6], days = tonumber(Words[7]) or 0}
		end

		if string.len(Words[8]) > 0 then
			Table[Key].left 	= {map = Words[8], side = tonumber(Words[9]) or Words[9], days = tonumber(Words[10]) or 0}
		end

		if string.len(Words[11]) > 0 then
			Table[Key].right 	= {map = Words[11], side = tonumber(Words[12]) or Words[12], days = tonumber(Words[13]) or 0}
		end

		Table[Key].StraightTravel = Words[14] == "x"

	end

	io.close(File)

end

ParseTravelsTable("Data/Tables/Outdoor travels.txt", TravelsTable)

----

local SwCoord = "X"
local StTrConns = {up = "Y", down = "Y", left = "X", right = "X"}
local NeedST = 0

function events.WalkToMap(t)

	local L = TravelsTable[string.lower(t.LeaveMap)]

	if L then
		local ST = L.StraightTravel
		L = L[t.LeaveSide]
		if L then
			t.Days = L.days
			t.EnterMap = L.map
			t.EnterSide = L.side
			if ST then
				SwCoord = StTrConns[L.side]
			end
		end
	end

end

-- Triggers during travel between outdoor maps by walk
mem.autohook2(0x4307e9, function(d)
	local t = {Map = d.eax, Straight = false}
	events.call("LeftToMap", t)
	if t.Straight then
		mem.i4[0x6F399C] = -1
	end
end)

function events.LeftToMap(t)
	local L = TravelsTable[string.lower(Game.MapStats[t.Map].FileName)]
	if L and L.StraightTravel then
		local A = Party[SwCoord] > 0 and -1 or 1
		Party[SwCoord] = (math.abs(Party[SwCoord]) - 30) * A
		t.Straight = true
	end
end

 -- Death map

 -- Disable original death movie, show one according to current continent.
mem.IgnoreProtection(true)
mem.u4[0x4a7c5e+4*6] = mem.u4[0x4a7c5e+4*4]
mem.IgnoreProtection(false)

function events.LoadMapScripts()
	if Map.IsOutdoor() then
		vars.LastOutdoorMap = Map.Name
	end
end

function events.DeathMap(t)

	local CurCont = TownPortalControls.GetCurrentSwitch()
	local ContMap = Game.DeathMaps[CurCont]
	local DefMap = ContMap[1].n == "" and ContMap[2] or ContMap[1]

	if DefMap.n == "" then
		CurCont = random(1, 3)
		ContMap = Game.DeathMaps[CurCont]
		DefMap = ContMap[1].n == "" and ContMap[2] or ContMap[1]
	end

	-- Show death movie
	local tmpT = {movie = Game.ContinentSettings[CurCont].DeathMovie}
	events.call("ShowDeathMovie", tmpT)
	if string.len(tmpT.movie) > 0 then
		if CurCont == 3 then
			evt.ShowMovie{0, 0, tmpT.movie}
		else
			evt.ShowMovie{1, 0, tmpT.movie}
		end
	end
	--

	if Map.Name == ContMap[1].n or vars.LastOutdoorMap == ContMap[1].n then
		ContMap = ContMap[1]
	else
		ContMap = ContMap[2]
	end

	ContMap = ContMap.n ~= "" and ContMap or DefMap

	t.Name = ContMap.n
	Party.X = ContMap.X
	Party.Y = ContMap.Y
	Party.Z = ContMap.Z
	Party.Direction = ContMap.Dir

end

-- New game map

function events.NewGameMap()

	local ContMap = Game.DeathMaps[TownPortalControls.GetCurrentSwitch()][1]
	Party.X = ContMap.X
	Party.Y = ContMap.Y
	Party.Z = ContMap.Z
	Party.Direction = ContMap.Dir

end

function events.GameInitialized2()
	local UnderwaterByName = {}
	for i,v in Game.MapStats do
		UnderwaterByName[v.FileName] = v.EaxEnvironments == 22
	end

	function events.IsUnderwater(t)
		if UnderwaterByName[t.Map] then
			t.Result = true
		end
	end
end

-- Dimension door setup
local StdTPHeader = Game.GlobalTxt[10]

function events.LeaveMap()
	if TownPortalControls.GetCurrentSwitch() == 4 then
		Game.GlobalTxt[10] = StdTPHeader
	end
end

function TownPortalControls.RevertTPSwitch()
	if Game.CurrentScreen ~= 3 then -- do not revert, if player still choosing destination
		TownPortalControls.CheckSwitch()
		Game.GlobalTxt[10] = StdTPHeader
		RemoveTimer(TownPortalControls.RevertTPSwitch)
	end
end

function TownPortalControls.GenDimDoor()

	local JadamMaps 	= {1,2,6,1,2,7,7,8}
	local AntagrichMaps	= {64,67,67,68,70,65,66,72}
	local EnrothMaps	= {144,151,150,143,147}

	local TPSets = TownPortalControls.Sets[4]

	local function ProcessContinent(PicPrefix, TPSet, Maps, Id)
		local CurMap = Id or random(1, #Maps)
		TPSet.IN	= PicPrefix .. CurMap
		TPSet.Map	= Maps[CurMap]
	end

	local day = math.floor(Game.Time / const.Day)
	ProcessContinent("TPJadam", TPSets[1], JadamMaps, day % 8 + 1)
	ProcessContinent("TPAntag", TPSets[3], AntagrichMaps, math.ceil(day / 1.2) % 8 + 1)
	ProcessContinent("TPEnroth", TPSets[5], EnrothMaps, day % 5 + 1)

end

function TownPortalControls.DimDoorEvent()
	Game.ShowStatusText(Game.GlobalTxt[737])
	TownPortalControls.GenDimDoor()

	TownPortalControls.SwitchTo(4)
	Timer(TownPortalControls.RevertTPSwitch, const.Minute*8, Game.Time+const.Minute*8, false, false)

	Game.GlobalTxt[10] = " "
end

-- Different loading screens for continents
local function MapOfContinent(Map)
	local MapId

	for i,v in Game.MapStats do
		if v.FileName == Map then
			MapId = i
			break
		end
	end

	if not MapId then
		return TownPortalControls.GetCurrentSwitch()
	end

	return Game.Bolster.MapsSource[MapId].Continent or TownPortalControls.GetCurrentSwitch()
end

function events.GetLoadingPic(t)
	local CurCont = MapOfContinent(Map.Name) -- Name used instead of index, because, "MapStatsIndex" field of map structure have not been changed yet.
	local ContPicList = Game.ContinentSettings[CurCont].LoadingPics
	t.Pic = ContPicList[random(1, #ContPicList)]
end
