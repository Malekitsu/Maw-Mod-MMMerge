-- MMPathfinder.dll source: https://gitlab.com/letr.rod/pathfinder

local dll = mem.dll['MMPathfinder']
if not dll then
	debug.Message(
		"\nCould not load MMPathfinder.dll - pathfinding disabled.\n" ..
		"Ensure MMPathfinder.dll is in ExeMods folder\n" ..
		"and Microsoft Visual C++ Redistributable x86 2015+ is installed.")
	return
end

-- check win version: dll does not handle multithreading properly in win95 comp (keeps all work in main thread, causing freezes)
local function GetWinVersion()
	local GetVersion = mem.dll["Kernel32.dll"].GetVersion
	if not GetVersion then
		-- This method is deprecated in win 8 and higher, which is enough for pathfinder.
		WinVersion = 6
		return WinVersion
	end

	return bit.And(GetVersion(), 0xFF)
end

if GetWinVersion() < 5 then
	debug.Message(
		"\nImproved pathfinding does not work in windows 95, 98, ME, 2000.\n" ..
		"Set compatibility mode of mm8.exe to win XP or higher. Pathfinding disabled.")
	return
end

----

local halted = false
local limit = 8000
local INSTANCE = dll.create_instance()

PathfinderDll = {INSTANCE = INSTANCE}

dll.set_max_threads(INSTANCE, 2)
dll.set_max_tasks(INSTANCE, 50)

local function halt()
	halted = true
	dll.stop(INSTANCE)
end
PathfinderDll.halt = halt

local function resume()
	if not Multiplayer.leave_map_halt then
		halted = false
	end
end
PathfinderDll.resume = resume

local function _halted()
	return halted
end
PathfinderDll.halted = _halted

local function init_indoor()
	dll.init_indoor_map(INSTANCE, Map.Facets.count, Map.Vertexes.count, Map.Facets[0]['?ptr'], Map.Vertexes[0]['?ptr'])
end

local function init_ground()
	local i2 = mem.i2
	local vertexes = mem.malloc(98304) -- space for all possible ground vertexes
	local vertex_pos = vertexes

	local triangles = mem.malloc(193548) -- space for all possible ground triangles
	local tris_pos = triangles
	local tris_count = 0

	local function write_vertex(x, y, z)
		i2[vertex_pos] = -x
		i2[vertex_pos + 2] = y
		i2[vertex_pos + 4] = z
		vertex_pos = vertex_pos + 6
	end

	local function write_tris(v1, v2, v3)
		i2[tris_pos] = v1
		i2[tris_pos + 2] = v2
		i2[tris_pos + 4] = v3
		tris_pos = tris_pos + 6
		tris_count = tris_count + 1
	end

	local function vertex_id(x, y)
		return x + y * 128
	end

	local function water_tile(x, y)
		local TileId = Map.TileMap[y][x]
		if TileId >= 90 then
			TileId = TileId - 90
			TileId = Map.Tilesets[(TileId/36):floor()].Offset + TileId % 36
		end
		return Game.CurrentTileBin[TileId].Water
	end

	for y = 0, 127 do
		for x = 0, 127 do
			write_vertex((64 - x)*512, (64 - y)*512, Map.HeightMap[y][x] * 32)
		end
	end

	local water_tiles = {}
	for y = 1, 125 do
		for x = 1, 125 do
			if water_tile(x, y) then
				water_tiles[vertex_id(x, y)] = true
			else
				write_tris(vertex_id(x, y), vertex_id(x+1, y), vertex_id(x+1, y+1))
				write_tris(vertex_id(x, y), vertex_id(x, y+1), vertex_id(x+1, y+1))
			end
		end
	end

	local corners_radius = 48
	for id, v in pairs(water_tiles) do
		if v and not (water_tiles[id + 1] and water_tiles[id - 1] and water_tiles[id + 128] and  water_tiles[id - 128]) then
			local x, y = (id % 128), (id / 128):floor()
			local z = Map.HeightMap[y][x] * 32 + corners_radius
			x = -(64 - x)*512
			y = (64 - y)*512
			dll.add_outdoor_cube(INSTANCE, corners_radius, x, y, z)
			dll.add_outdoor_cube(INSTANCE, corners_radius, x + 512, y, z)
			dll.add_outdoor_cube(INSTANCE, corners_radius, x , y - 512, z)
			dll.add_outdoor_cube(INSTANCE, corners_radius, x + 512, y - 512, z)
		end
	end

	dll.add_outdoor_ground(INSTANCE, tris_count, triangles, vertexes)
	mem.free(triangles)
	mem.free(vertexes)
end

local function init_outdoor()
	dll.init_outdoor_map(INSTANCE)

	-- Models
	if Map.Models.count > 0 then
		dll.add_outdoor_models(INSTANCE, Map.Models.count, Map.Models[0]['?ptr'])
	end

	-- Ground
	init_ground()

	-- Blocking sprites
	for SpriteId, Sprite in Map.Sprites do
		local DecListItem = Game.DecListBin[Sprite.DecListId]
		if not DecListItem.NoBlockMovement and not DecListItem.NoDraw and DecListItem.Radius > 30 and DecListItem.Height > 30 then
			dll.add_outdoor_cube(INSTANCE, DecListItem.Radius, Sprite.X, Sprite.Y, Sprite.Z + DecListItem.Radius)
		end
	end

	dll.make_outdoor_areas(INSTANCE)
end

local function init_map()
	if Map.IsOutdoor() then
		init_outdoor()
	else
		init_indoor()
	end
end
PathfinderDll.init_map = init_map

local function TraceLine(From, To, ZOffset)
	ZOffset = ZOffset or 0
	return dll.trace_line(INSTANCE, From.X, From.Y, From.Z + ZOffset, To.X, To.Y, To.Z + ZOffset) == 1
end
PathfinderDll.TraceLine = TraceLine

local function TraceWay(Monster, From, To)
	return dll.trace_way(INSTANCE, Monster.Fly, Monster.BodyRadius, 40, From.X, From.Y, From.Z + 16, To.X, To.Y, To.Z + 16) == 1
end
PathfinderDll.TraceWay = TraceWay

local function GetFloorLevel(x, y, z)
	return dll.get_floor_level(INSTANCE, x,y,z)
end
PathfinderDll.GetFloorLevel = GetFloorLevel

local function AStarWay(t)
	if halted then
		return {}
	end

	local function GetResult(ptr, count)
		local result = {}
		if ptr > 0 and count > 0 then
			local pos = ptr
			local i2 = mem.i2
			for i = 0, count - 1 do
				table.insert(result, {X =  i2[pos], Y = i2[pos+2], Z = i2[pos+4]})
				pos = pos + 6
			end
		end
		return result
	end

	local MonId, ToX, ToY, ToZ, FromX, FromY, FromZ = t.MonId, t.ToX, t.ToY, t.ToZ, t.FromX, t.FromY, t.FromZ

	if not ToX or not ToY or not ToZ then
		error("Attempt to make A* way without target coordinates.")
	end

	if not MonId then
		error("Attempt to make A* way without monster to trace with.")
	end

	local Monster = Map.Monsters[MonId]
	local OutputPtr = mem.malloc(limit * 6)
	FromX = FromX or Monster.X
	FromY = FromY or Monster.Y
	FromZ = FromZ or Monster.Z

	local StepLength = Monster.BodyRadius
	if Map.IsOutdoor() then
		StepLength = StepLength * 2
	end

	local result
	if t.Async then
		local task_id = dll.add_task(INSTANCE, Monster.Fly, Monster.BodyRadius, StepLength, t.StepHeight or 40, FromX, FromY, FromZ, ToX, ToY, ToZ, limit)
		local status = dll.task_status(INSTANCE, task_id)
		while status > 0 and status < 3 do
			coroutine.yield()
			status = dll.task_status(INSTANCE, task_id)
		end

		if status == 3 then
			local count = dll.task_result(INSTANCE, task_id, OutputPtr)
			result = GetResult(OutputPtr, count)
		else
			result = {}
		end
	else
		local count = dll.AStarWay(INSTANCE, Monster.Fly, Monster.BodyRadius, StepLength,  t.StepHeight or 40, FromX, FromY, FromZ, ToX, ToY, ToZ, limit, OutputPtr)
		result = GetResult(OutputPtr, count)
	end

	mem.free(OutputPtr)
	return result
end
PathfinderDll.AStarWay = AStarWay

local function AStarWayObjDebug(P1, P2, StepLength, StepHeight, Fly)
	local function GetResult(ptr, count)
		local result = {}
		if ptr > 0 and count > 0 then
			local pos = ptr
			local i2 = mem.i2
			for i = 0, count - 1 do
				table.insert(result, {X =  i2[pos], Y = i2[pos+2], Z = i2[pos+4]})
				pos = pos + 6
			end
		end
		return result
	end

	local FromX, FromY, FromZ = XYZ(P1)
	local ToX, ToY, ToZ = XYZ(P2)

	if not ToX or not ToY or not ToZ then
		error("Attempt to make A* way without target coordinates.")
	end

	local Monster = Map.Monsters[MonId]
	local OutputPtr = mem.malloc(limit * 6)

	local count = dll.AStarWayObjDebug(INSTANCE, Fly or 0, StepLength, StepLength, StepHeight or 40, FromX, FromY, FromZ, ToX, ToY, ToZ, limit, OutputPtr)
	local result = GetResult(OutputPtr, count)

	mem.free(OutputPtr)
	return result
end
PathfinderDll.AStarWayObjDebug = AStarWayObjDebug

---- Events ----

events.LeaveMap = halt
events.BeforeLeaveGame = halt

events.LeaveGame = halt
events.BeforeSaveGame = halt

events.AfterSaveGame = resume
events.AfterLoadMap = resume
events.MapLoadingDone = resume
