
local ceil, floor, random, min, max, sqrt, abs = math.ceil, math.floor, math.random, math.min, math.max, math.sqrt, math.abs

local TrapSpells, TrapNextShot, EmptyBookcases, MonRage
local TrapSpellsList = {2, 15, 24, 39, 18, 6, 7, 11, 32, 41, 93}
local StdBitmaps = {}
local BitmapSets = {
	[1] = {Wall = "7cdb",		Floor = "7c1fl",	Misc = "7cdb",		Deco = "7c1fl", 	loaded = false},
	[2] = {Wall = "cwb", 		Floor = "7c1fl",	Misc = "cwb",		Deco = "cwb1", 		loaded = false},
	[3] = {Wall = "7t1s2bs4",	Floor = "7tfb1",	Misc = "7trim9_32",	Deco = "7trimd",	loaded = false},
	[4] = {Wall = "t65c02",		Floor = "t65b03",	Misc = "t65b10",	Deco = "t65a03",	loaded = false},
	}

local QSet = vars.Quest_CrossContinents

local function TriggerReload()
	Merge.Tables.BrBase = mapvars
	evt.MoveToMap{0,0,0,0,0,0,0,0,"BrBase.blv"}
end

---------------------------------
-- Maze geneartion functions
---------------------------------
local function CreateMaze(W,H)

	-- Eller's algorithm
	-- Detailed description: http://weblog.jamisbuck.org/2010/12/29/maze-generation-eller-s-algorithm
	local pairs = pairs
	local maze = {}

	-- Make template
	for R = 1, H do
		maze[R] = {}
		for C = 1, W do
			maze[R][C] = {true, true, 0} -- right, down, set id
		end
	end

	-- Prepairing sets representations
	local sets = {}
	local setMap = {}
	for i = 1, W do
		setMap[i] = i
		sets[i] = { [i] = true, n = 1 }
	end

	for y = 1, H do
		for x = 1, W - 1 do
			maze[y][x][3] = setMap[x]
			-- Randomly remove east wall and merge sets
			if setMap[x] ~= setMap[x + 1] and (random(2) == 1 or y == H) then
				maze[y][x][1] = false
				-- Merging sets together
				local lIndex = setMap[x]
				local rIndex = setMap[x + 1]
				local lSet = sets[lIndex]
				local rSet = sets[rIndex]
				for i = 1, W do
					if setMap[i] == rIndex then
						setMap[i] = lIndex
						lSet[i]	= true
						lSet.n	= lSet.n + 1
						rSet[i]	= nil
						rSet.n	= rSet.n - 1
					end
				end
			end
		end
		maze[y][W][3] = setMap[W]

		if y == H then
			break
		end

		-- Randomly remove south walls and making sure that at least one cell in each set has no south wall
		for i, set in pairs(sets) do
			local opened
			local lastCell
			for x, j in pairs(set) do
				if x ~= "n" then
					lastCell = x
					if random(2) == 1 then
						maze[y][x][2] = false
						opened = true
					end
				end
			end

			if not opened and lastCell then
				maze[y][lastCell][2] = false
			end
		end

		-- Removing cell with south walls from their sets
		for x = 1, W do
			if maze[y][x][2] then
				local set = sets[setMap[x]]
				set[x] = nil; set.n = set.n - 1
				setMap[x] = nil
			end
		end

		-- Gathering all empty sets in a list
		local emptySets = {}
		for i, set in pairs(sets) do
			if set.n == 0 then emptySets[#emptySets + 1] = i end
		end

		-- Assigning all cell without a set to an empty set from the list
		for x = 1, W do
			if not setMap[x] then
				setMap[x] = emptySets[#emptySets]
				emptySets[#emptySets] = nil
				local set = sets[setMap[x]]
				set[x] = true
				set.n = set.n + 1
			end
		end
	end

	-- Prepare grid
	local MazeGrid = {}
	for Y = 1, #maze do
		MazeGrid[Y] = {}
		line = MazeGrid[Y]
		for X = 1, #maze[Y] do
			local Cell = maze[Y][X]
			line[X] = {
				west	= X == 1 or maze[Y][X-1][1],
				north	= Y == 1 or maze[Y-1][X][2],
				east	= Cell[1],
				south	= Cell[2],
				room	= Cell[3],
				cell	= 0
				}
		end
	end

	return MazeGrid

end

local function FindCells(Maze)

	-- Find and sort cells, define cell info
	local CellW = 601.5
	local bX,bY = 0,0
	local ins = table.insert

	local CellsInfo
	local MaxY, MaxX = #Maze, #Maze[1]
	if mapvars.CellsInfo then
		CellsInfo = mapvars.CellsInfo
		for i,v in pairs(CellsInfo) do
			if v.Y <= MaxY and v.X <= MaxX then
				local MazeCell = Maze[v.Y][v.X]
				MazeCell.cell = i
				v.Parent = MazeCell.room
				for _, fid in pairs(v.Facets) do
					Map.Facets[fid].Invisible = false
				end
			else
				for _, fid in pairs(v.Facets) do
					Map.Facets[fid].Invisible = true
				end
			end
			v.OpenWallsCount = 0
			v.BmSet = 0
			v.YEdge = v.Y == 1 or v.Y == MaxY
			v.XEdge = v.X == 1 or v.X == MaxX
		end
	else
		CellsInfo = {}

		local FGroups = {}
		for Y = 1, 16 do
			FGroups[Y] = {}
			for X = 1, 16 do
				FGroups[Y][X] = {}
			end
		end

		local R = CellW/2 - 10
		for i,v in Map.Facets do
			local X = ceil(( v.MaxX + R)/CellW)
			local Y = ceil((-v.MinY + R)/CellW)
			ins(FGroups[Y][X], i)
		end

		for Y = 1, 16 do
			local cY = -CellW*(Y-1)
			for X = 1, 16 do
				local Facets = FGroups[Y][X]
				local cX = CellW*(X-1)

				local n = #CellsInfo+1
				CellsInfo[n] = {
					cX = cX,
					cY = cY,
					cZ = -200,
					X = X,
					Y = Y,
					Walls = {},
					Floor = -1,
					Facets = Facets,
					OpenWallsCount = 0,
					BmSet = 0,
					Parent = 0,
					YEdge = Y == 1 or Y == MaxY,
					XEdge = X == 1 or X == MaxX
				}

				if Y <= MaxY and X <= MaxX then
					local MazeCell = Maze[Y][X]
					CellsInfo[n].Parent = MazeCell.room
					MazeCell.cell = n
					for _, fid in pairs(Facets) do
						Map.Facets[fid].Invisible = false
					end
				else
					for _, fid in pairs(Facets) do
						Map.Facets[fid].Invisible = true
					end
				end
			end
		end
	end

	return CellsInfo

end

local function PrepareMaze(Maze, CellsInfo)

	local function GetWallSide(F, Fid, invert)
		local Nx = ceil(F.NormalFX)
		local Ny = ceil(F.NormalFY)
		local A = invert and 1 or -1
		local Side
		if Ny == -1*A then
			Side = "south"
		elseif Ny == 1*A then
			Side = "north"
		elseif Nx == -1*A then
			Side = "west"
		elseif Nx == 1*A then
			Side = "east"
		end
		return Side
	end

	local function GetMiscWallSide(F, Fid, bX, bY)
		local mX, mY = F.MinX + (F.MaxX - F.MinX)/2, F.MinY + (F.MaxY - F.MinY)/2
		local Side
		if abs(bX - mX) > abs(bY - mY) then
			if mX > bX then
				Side = "east"
			else
				Side = "west"
			end
		else
			if mY > bY then
				Side = "north"
			else
				Side = "south"
			end
		end
		return Side
	end

	-- Find service bitmaps ids
	local PortalBm, WallBm, FloorBm, DecoBm, MiscBm
	for i,v in Game.BitmapsLod.Bitmaps do
		if v.Name == "RmzWal" then
			WallBm = i
		elseif v.Name == "RmzPrt" then
			PortalBm = i
		elseif v.Name == "RmzFlr" then
			FloorBm = i
		elseif v.Name == "RmzDec" then
			DecoBm = i
		elseif v.Name == "RmzMsc" then
			MiscBm = i
		end
	end

	StdBitmaps[1] = WallBm
	StdBitmaps[2] = PortalBm
	StdBitmaps[4] = FloorBm
	StdBitmaps[5] = DecoBm
	StdBitmaps[3] = MiscBm

	local function ProcessFacet(FId, MazeCell, CellInfo, BitmapSet)
		local F = Map.Facets[FId]
		local Bm = F.BitmapId
		local FData = Map.FacetData[F.DataIndex]

		FData.Event = 0

		-- Main walls
		if FData.Id == 1 or Bm == WallBm then
			FData.Id = 1
			local Side	= GetWallSide(F, FId)
			local IsOpen = not MazeCell[Side]

			if IsOpen then
				F.IsPortal	  = true
				F.Invisible	  = true
				F.Untouchable = true
				CellInfo.OpenWallsCount = CellInfo.OpenWallsCount + 1
			else
				F.IsPortal	  = false
				F.Invisible	  = false
				F.Untouchable = false
				F.BitmapId = BitmapSet.Wall
			end

			if #CellInfo.Walls < 4 then
				table.insert(CellInfo.Walls, FId)
			end

		-- Portals
		elseif FData.Id == 2 or Bm == PortalBm then
			FData.Id = 2
			-- Portals do not work without consequenses in this case :(

		-- Misc walls
		elseif FData.Id == 3 or Bm == MiscBm then
			FData.Id = 3
			F.BitmapId = BitmapSet.Misc

		-- Floors
		elseif FData.Id == 4 or Bm == FloorBm then
			FData.Id = 4

			if CellInfo.Floor == -1 then
				if abs(F.MinX + (F.MaxX - F.MinX)/2 - CellInfo.cX) < 100 and abs(F.MinY + (F.MaxY - F.MinY)/2 - CellInfo.cY) < 100 then
					CellInfo.Floor = FId
				end
			end

			F.BitmapId = BitmapSet.Floor

		-- Rest
		else
			FData.Id = 5
			F.BitmapId = BitmapSet.Deco

		end

		FData.BitmapIndex = F.BitmapId

	end

	-- Init bitmap sets
	local RoomBmSets = {}

	local function LoadBmSet(i)
		local set = BitmapSets[i]
		for k,v in pairs(set) do
			v = Game.BitmapsLod:LoadBitmap(v)
			Game.BitmapsLod.Bitmaps[v]:LoadBitmapPalette()
			set[k] = v
		end
	end

	-- Setup maze and prepare table for encounter positioning
	for Y = 1, #Maze do
		for X = 1, #Maze[Y] do
			local MazeCell = Maze[Y][X]
			local CellInfo = CellsInfo[MazeCell.cell]

			-- assign bitmap set to room
			local BmSet = RoomBmSets[MazeCell.room]
			if not BmSet then
				BmSet = random(#BitmapSets)
				RoomBmSets[MazeCell.room] = BmSet
				if not BitmapSets[BmSet].loaded then
					LoadBmSet(BmSet)
					BitmapSets[BmSet].loaded = true
				end
			end
			BmSet = BitmapSets[BmSet]

			CellInfo.BmSet = BmSet

			-- setup facets
			for i,v in pairs(CellInfo.Facets) do
				ProcessFacet(v, MazeCell, CellInfo, BmSet)
			end

		end
	end

end


local function PopulateMaze(Maze, CellsInfo)
	-- Cells with three closed walls considered as treasure spot, one of them is party start.
	-- (item/gold, useful sprite or single buffed monster)
	-- These are limited.
	--
	-- Rare cells with four open walls considered as group encounter spot
	-- (Few monsters)
	--
	-- Cells with three open walls considered as single encounter spot
	-- (One monster)
	--
	-- Cells with two open walls considered as way - either noting or common sprite
	-- (torch, deco etc)

	local SpritesCount = 255
	local SpritesSet = -1

	local LightsCount = 255
	local LightsSet = -1

	local MonSelection = {}
	for i = 1, Game.MonstersTxt.count - 1 do
		if (Game.IsMonsterOfKind(i, const.MonsterKind.NoArena) == 1)
			or (Game.IsMonsterOfKind(i, const.MonsterKind.Swimmer) == 1)
			or (Game.IsMonsterOfKind(i, const.MonsterKind.Peasant) == 1) then
			-- do nothing
		elseif Game.MonListBin[i].Height > 400 then
			-- do nothing
		--elseif Game.MonstersTxt[i].Level < math.min(mapvars.MazeLevel, 50) or Game.MonstersTxt[i].Level > mapvars.MazeLevel * 10 then
			-- do nothing
		else
			table.insert(MonSelection, i)
		end
	end

	local function GetMonster()
		return MonSelection[random(1, #MonSelection)]
	end

	local MazeLevel		= mapvars.MazeLevel
	local TresPerRoom	= {}
	local TresLimit		= random(MazeLevel*(#Maze/4))
	local MazeMonLimit	= random((MazeLevel-1)*(#Maze/4), (MazeLevel*(#Maze/4))^2)

	local UsefulSprites = {
		"crystl0", "crclstr", "crys5", "crys6", "trashheap",
		"bag01", "Bucket", "floursac", "bigbarel", "7dec03",
		"7dec10", "dec62", "dec61", "dec63"}

	local EnterCell
	local EdgeCell1 = 0
	local EdgeCell2 = 0

	local DoorA = Game.BitmapsLod:LoadBitmap("RmzDrA")
	Game.BitmapsLod.Bitmaps[DoorA]:LoadBitmapPalette()

	local DoorB = Game.BitmapsLod:LoadBitmap("RmzDrB")
	Game.BitmapsLod.Bitmaps[DoorB]:LoadBitmapPalette()

	local function SetEnterExit(Cell, Type)
		local Cell = CellsInfo[Cell]
		local F
		for k,v in ipairs(Cell.Walls) do
			F = Map.Facets[v]
			if not F.Invisible
				and (Cell.XEdge and (Cell.X == 1  and F.NormalFX == 1 or Cell.X == #Maze  and F.NormalFX == -1)
					or Cell.YEdge and (Cell.Y == 1  and F.NormalFY == -1 or Cell.Y == #Maze  and F.NormalFY == 1)) then
				break
			end
		end
		F.BitmapId = Type == "Enter" and DoorA or DoorB
		F.TriggerByClick = true
		Map.FacetData[F.DataIndex].Event = Type == "Enter" and 1 or 2
	end

	local function GetFinalCell(side, shift)
		local X = (side == 1 and 1) or (side == 2 and #Maze)
		local Y = (side == 3 and 1) or (side == 4 and #Maze)
		for i = 1+shift, #Maze do
			local cell = Maze[Y or i][X or i].cell
			if CellsInfo[cell].OpenWallsCount == 1 then
				return cell
			end
		end
		return false
	end

	local function IsSingleCellRoom(X,Y)
		local mc = Maze[Y][X]
		local result = true
		if not mc.north and result then
			result = Maze[Y - 1][X].room ~= mc.room
		end
		if not mc.south and result then
			result = Maze[Y + 1][X].room ~= mc.room
		end
		if not mc.west and result then
			result = Maze[Y][X - 1].room ~= mc.room
		end
		if not mc.east and result then
			result = Maze[Y][X + 1].room ~= mc.room
		end
		return result
	end

	local EnterCell = random(4)
	local ExitCell  = random(4)
	while ExitCell == EnterCell do
		ExitCell = random(4)
	end

	EnterCell = GetFinalCell(EnterCell, 0) or 1
	ExitCell  = GetFinalCell(ExitCell, 1) or #Maze

	if ExitCell == EnterCell then
		EnterCell = 1
		ExitCell = #Maze
	end

	mapvars.EnterCell	= EnterCell
	mapvars.ExitCell	= ExitCell

	SetEnterExit(EnterCell, "Enter")
	SetEnterExit(ExitCell, "Exit")

	for i,v in Map.Sprites do
		v.Invisible = true
		v.ShowOnMap = false
		v.Event = 0
		evt.map[20000 + i]:clear()
	end

	local CanSeeTraps = false
	for i,v in Party do
		local Skill, Mas = SplitSkill(v.Skills[const.Skills.Perception])
		if Mas == 4 or Skill > ceil(mapvars.MazeLevel/Mas) then
			CanSeeTraps = true
			break
		end
	end

	local LibBm
	local MaxY, MaxX = #Maze, #Maze[1]
	for Y = 1, #Maze do
		for X = 1, #Maze[Y] do

			local MazeCell = Maze[Y][X]
			local CellId = MazeCell.cell
			local v = CellsInfo[CellId]
			if v.OpenWallsCount == 1 then

				TresPerRoom[v.Parent] = TresPerRoom[v.Parent] or 0
				if TresPerRoom[v.Parent] <= TresLimit and CellId ~= EnterCell and CellId ~= ExitCell then
					TresPerRoom[v.Parent] = TresPerRoom[v.Parent] + 1
					local Seed = random(1,3)

					if IsSingleCellRoom(X, Y) then
						local TCell

						if not MazeCell.north then
							TCell = CellsInfo[Maze[Y - 1][X].cell]
						elseif not MazeCell.south then
							TCell = CellsInfo[Maze[Y + 1][X].cell]
						elseif not MazeCell.west then
							TCell = CellsInfo[Maze[Y][X - 1].cell]
						else
							TCell = CellsInfo[Maze[Y][X + 1].cell]
						end

						local BmSet = TCell.BmSet
						for _,Fid in pairs(v.Facets) do
							local F = Map.Facets[Fid]
							local FData = Map.FacetData[F.DataIndex]
							if FData.Id == 1 then
								F.BitmapId = BmSet.Wall
							elseif FData.Id == 3 then
								F.BitmapId = BmSet.Misc
							elseif FData.Id == 4 then
								F.BitmapId = BmSet.Floor
							else
								F.BitmapId = BmSet.Deco
							end
						end

						if Seed ~= 2 then
							-- Library
							if not LibBm then
								LibBm = Game.BitmapsLod:LoadBitmap("bookcas1")
								Game.BitmapsLod.Bitmaps[LibBm]:LoadBitmapPalette()
							end

							for _,Fid in ipairs(v.Walls) do
								local F = Map.Facets[Fid]
								local FData = Map.FacetData[F.DataIndex]
								FData.Event = 4
								F.BitmapId = LibBm
								F.TriggerByClick = true
							end

						end

					end

					if Seed == 1 then
						-- treasure
						local ItemObj = SummonItem(random(177,186), v.cX, v.cY, v.cZ, 0)
						local Item = ItemObj.Item
						Item:Randomize(min(random(ceil(MazeLevel/2), MazeLevel), 6),0,0)
						if Item.Bonus > 0 then
							Item.BonusStrength = max(1, Item.BonusStrength)
						end

					elseif Seed == 2 then
						-- sprite
						if SpritesSet < SpritesCount then
							SpritesSet = SpritesSet + 1
							local Sprite = UsefulSprites[random(1, #UsefulSprites)]
							ChangeSprite(SpritesSet, Sprite)
							Sprite = Map.Sprites[SpritesSet]
							Sprite.X = v.cX
							Sprite.Y = v.cY
							Sprite.Z = -211
							Sprite.Invisible = false
							Sprite.ShowOnMap = false
						end

					elseif MazeMonLimit > 0 then
						local mon = SummonMonster(GetMonster(), v.cX, v.cY, v.cZ)
						mon.FullHP = mon.FullHP*2
						mon.HP = mon.FullHP
						MazeMonLimit = MazeMonLimit - 1

					else -- empty potion bottle
						SummonItem(220, v.cX, v.cY, v.cZ, 0)

					end
				end

			elseif v.OpenWallsCount == 2 and CellId ~= EnterCell and CellId ~= ExitCell then
				-- Place light source
				if SpritesSet < SpritesCount and LightsSet < LightsCount then
					for _, Fid in ipairs(v.Walls) do
						local F = Map.Facets[Fid]
						if not F.Invisible and random(1, min(MazeLevel, 3)) == 1 then
							SpritesSet = SpritesSet + 1
							LightsSet = LightsSet + 1
							local Sprite = "torch01"
							ChangeSprite(SpritesSet, Sprite)
							Sprite = Map.Sprites[SpritesSet]
							Sprite.X = F.MinX + (F.MaxX - F.MinX)/2 + 10*F.NormalFX
							Sprite.Y = F.MinY + (F.MaxY - F.MinY)/2 + 10*F.NormalFY
							Sprite.Z = v.cZ + 150
							Sprite.Invisible = false
							Sprite.ShowOnMap = false

							break
						end
					end
				end

				-- Set trap
				if v.Floor >= 0 and v.Floor < Map.Facets.count and random(1,6) == 1 then
					local F = Map.Facets[v.Floor]
					Map.FacetData[F.DataIndex].Event = 3

					F.IsSecret		 = CanSeeTraps
					F.TriggerByClick = false
					F.TriggerByStep	 = true
				end

			elseif v.OpenWallsCount == 3 then
				if MazeMonLimit > 0 then
					local rnd = GetMonster()
					for i = 1, random(1,3) do
						SummonMonster(rnd, v.cX + random(10,50), v.cY + random(10,50), v.cZ)
						MazeMonLimit = MazeMonLimit - 1
					end
				end

			elseif v.OpenWallsCount == 4 then
				if MazeMonLimit > 0 then
					local rnd = GetMonster()
					for i = 1, random(3,5) do
						SummonMonster(rnd, v.cX + random(10,50), v.cY + random(10,50), v.cZ)
						MazeMonLimit = MazeMonLimit - 1
					end
				end

				-- treasure
				local ItemObj = SummonItem(random(177,186), v.cX, v.cY, v.cZ, 0)
				local Item = ItemObj.Item
				Item:Randomize(min(random(ceil(MazeLevel/2), MazeLevel), 6),0,0)
				if Item.Bonus > 0 then
					Item.BonusStrength = max(1, Item.BonusStrength)
				end

			elseif v.OpenWallsCount == 0 then
				error("Error in maze generation algorithm. Closed cell found.")
			end

		end
	end

	mapvars.ActiveSprites = {}
	Game.ReInitSprites()

	for i,v in Map.Lights do
		local Sprite = Map.Sprites[i]
		XYZ(v, XYZ(Sprite))
		v.Off = Sprite.Invisible
	end

	for i,v in Map.Monsters do
		v.HostileType = 3
		v.Hostile = true
		v.ShowOnMap = false
		v.OnAlertMap = true
		v.GuardRadius = 10
		v.Room = 0
		v.TreasureDiceCount = 0
		v.TreasureDiceSides = 0
	end

	for i,v in Map.Objects do
		Editor.UpdateObjectLook(v)
	end

end
---------------------------------

---------------------------------
-- Service functions
---------------------------------
local XSideConns = {[-1] = "east", [0] = "0", [1] = "west"}
local YSideConns = {[-1] = "south", [0] = "0", [1] = "north"}
local function MonHostile()
	local Maze = mapvars.Maze
	local pX = floor(( Party.X + 300.525)/601.5)+1
	local pY = floor((-Party.Y + 300.525)/601.5)+1

	local STorch = Party.SpellBuffs[const.PartyBuff.TorchLight]
	local LR = min(STorch.Power, 3)
	STorch.Power = LR

	local MazeCell = Maze[pY]
	if not MazeCell then
		return
	end
	MazeCell = Maze[pY][pX]
	if not MazeCell then
		return
	end
	local PRoom = MazeCell.room

	for i,v in Map.Monsters do
		if v.HP > 0 and v.Ally ~= 9999 then
			if MonRage[i] then
				v.HostileType = 4
				v.Hostile = true
			else
				local X,Y = floor((v.X + 300.525)/601.5)+1, floor((-v.Y + 300.525)/601.5)+1
				--local MRoom = Maze[Y][X].room
				local MRoom = Maze[Y] and Maze[Y][X] and Maze[Y][X].room
				if not MRoom then
					MRoom = Maze[1][1].room
					v.X = 300
					v.Y = 300
				end
				local dX, dY = pX-X, pY-Y
				local InLine = abs(dX) <= 1 and abs(dY) <= 1 and not MazeCell[XSideConns[dX]] and not MazeCell[YSideConns[dY]]

				dX, dY = abs(dX), abs(dY)
				if InLine or (MRoom == PRoom and dX <= 1+LR and dY <= 1+LR) then
					v.HostileType = 4
					v.Hostile = true
				else
					v.HostileType = 3
					v.ShowAsHostile = true
				end
			end
		end
	end
end

local function ResetMaze()
	for i,v in Map.Facets do
		v.BitmapId = StdBitmaps[Map.FacetData[v.DataIndex].Id]
		v.Invisible = false
		v.Untouchable = false
		v.IsPortal = false
		v.IsSecret = false
	end

--~ 	for i,v in Map.Objects do
--~ 		v.Removed = true
--~ 		v.Visible = false
--~ 		v.Temporary = true
--~ 	end

--~ 	Map.Monsters.count = 0
--~ 	Map.Objects.count = 0

	mem.fill(Map.Objects["?ptr"], Map.Objects["?size"], 0)
end

local function InitMaze()
	ResetMaze()

	local side = random(4, max(8, min(mapvars.MazeLevel, 16)))
	local Maze	= CreateMaze(side, side)
	local CellsInfo = FindCells(Maze)

	mapvars.Maze = Maze
	mapvars.CellsInfo = CellsInfo

	PrepareMaze(Maze, CellsInfo)
	PopulateMaze(Maze, CellsInfo)

	collectgarbage("collect")
end

local function SaveMazeData(Dest, All)
	Dest.FacetBitmaps	= {}
	Dest.BitmapNames	= {}
	Dest.FacetEvents	= {}

	local FacetBitmaps = Dest.FacetBitmaps
	local BitmapNames = Dest.BitmapNames
	local Bitmaps = Game.BitmapsLod.Bitmaps

	for i,v in Map.Facets do
		FacetBitmaps[i] = v.BitmapId
		Dest.FacetEvents[i] = Map.FacetData[v.DataIndex].Event

		if not BitmapNames[v.BitmapId] then
			BitmapNames[v.BitmapId] = Bitmaps[min(v.BitmapId, Bitmaps.count-1)].Name
		end
	end

	Dest.SpriteIds	 = {}
	Dest.SpriteNames = {}
	Dest.SpritesXYZ	 = {}

	for i,v in Map.Sprites do
		Dest.SpriteIds[i] = v.DecListId
		Dest.SpritesXYZ[i] = {X = v.X, Y = v.Y, Z = v.Z, Invisible = v.Invisible}
		if not Dest.SpriteNames[v.DecListId] then
			Dest.SpriteNames[v.DecListId] = v.DecName
		end
	end

	Dest.TrapSpells = TrapSpells
	Dest.TrapNextShot = TrapNextShot
	Dest.EmptyBookcases = EmptyBookcases

	if All then
		Dest.Maze = mapvars.Maze
		Dest.CellsInfo = mapvars.CellsInfo
		Dest.ActiveSprites = mapvars.ActiveSprites
		Dest.EnterCell = mapvars.EnterCell
		Dest.ExitCell = mapvars.ExitCell

		Dest.MonData = {}
		for i,v in Map.Monsters do
			if not Multiplayer or v.AIType ~= Multiplayer.PUPPET_AITYPE then
				Dest.MonData[i] = {X = v.X, Y = v.Y, Z = v.Z, Id = v.Id, HP = v.HP, Ally = v.Ally, Group = v.Group}
			end
		end

		if Map.Objects.count > 0 then
			Dest.Objects = mem.string(Map.Objects["?ptr"], Map.Objects[0]["?size"] * Map.Objects.count, true)
			Dest.ObjectsCount = Map.Objects.count
		end
	end

	Dest.pX = Party.X
	Dest.pY = Party.Y
	Dest.pZ = Party.Z

end

local function LoadMazeData(Src, All)

	if All then
		mapvars.Maze = Src.Maze
		mapvars.CellsInfo = FindCells(Src.Maze)
		mapvars.ActiveSprites = Src.ActiveSprites
		mapvars.EnterCell = Src.EnterCell
		mapvars.ExitCell = Src.ExitCell

		PrepareMaze(mapvars.Maze, mapvars.CellsInfo)

		if Src.MonData then
			Map.Monsters.count = 0
			for i,v in pairs(Src.MonData) do
				local mon = SummonMonster(v.Id, v.X, v.Y, v.Z)
				mon.HP = v.HP
				mon.Ally = v.Ally
				mon.Group = v.Group

				mon.HostileType = 3
				mon.Hostile = v.Ally ~= 9999
				mon.ShowOnMap = false
				mon.OnAlertMap = true
				mon.GuardRadius = 10
				mon.Room = 0
				mon.TreasureDiceCount = 0
				mon.TreasureDiceSides = 0
				if v.HP <= 0 then
					mon.AIState = 5
					mon.GraphicState = 6
				end
			end
		end

		if Src.Objects then
			mem.copy(Map.Objects["?ptr"], Src.Objects, #Src.Objects)
			Map.Objects.count = Src.ObjectsCount
		end
	end

	local NewBitmaps = {}
	for i,v in pairs(Src.BitmapNames) do
		v = Game.BitmapsLod:LoadBitmap(v)
		Game.BitmapsLod.Bitmaps[v]:LoadBitmapPalette()

		NewBitmaps[i] = v
	end

	local CanSeeTraps = false
	for i,v in Party do
		local Skill, Mas = SplitSkill(v.Skills[const.Skills.Perception])
		if Mas == 4 or Skill > ceil(mapvars.MazeLevel/Mas) then
			CanSeeTraps = true
			break
		end
	end

	for i,v in Map.Facets do
		local BitmapId = Src.FacetBitmaps[i]
		local FData = Map.FacetData[v.DataIndex]
		v.BitmapId = NewBitmaps[BitmapId]
		FData.BitmapIndex = NewBitmaps[BitmapId]
		FData.Event = Src.FacetEvents[i]

		if FData.Event > 0 then
			v.IsSecret = CanSeeTraps and FData.Event == 3
			v.TriggerByClick = FData.Event ~= 3
			v.TriggerByStep	 = true
		end
	end

	if Src.SpritesXYZ then
		for i,v in Map.Sprites do
			local SpriteProps = Src.SpritesXYZ[i]
			if SpriteProps then
				v.DecName = Src.SpriteNames[Src.SpriteIds[i]]
				v.Invisible = SpriteProps.Invisible or v.DecName == "dec57"
				XYZ(v, XYZ(SpriteProps))

				if i < Map.Lights.count then
					XYZ(Map.Lights[i], XYZ(v))
					Map.Lights[i].Off = v.Invisible
				end
			end
		end

		Game.ReInitSprites()
	end

	if not All and Src.MonData then
		for i,v in Map.Monsters do
			v.AIState = v.HP > 0 and 1 or 5
			v:LoadFramesAndSounds()
		end
	end

	Party.X = Src.pX
	Party.Y = Src.pY
	Party.Z = Src.pZ

	TrapSpells = Src.TrapSpells or {}
	TrapNextShot = Src.TrapNextShot or {}
	EmptyBookcases = Src.EmptyBookcases or {}

end

---------------------------------

---------------------------------
-- Multiplayer support

Multiplayer.BrBase = Multiplayer.BrBase or {}
Multiplayer.BrBase.LevelChange = Multiplayer.BrBase.LevelChange or {}

local msgs = {
	LevelChange = 1,
	TrapDisarmed = 2,
	CanChangeLevel = 3,
	CanChangeLevelResponse = 4,
}

local function CanChangeLevel()
	if not Multiplayer.connector then
		return true
	end

	for client_id, client in pairs(Multiplayer.connector.clients) do
		if client.map == Map.MapStatsIndex and Multiplayer.BrBase.LevelChange[client_id] then
			return false
		end
	end
	return true
end

function events.MultiplayerPrepMapData(t)
	t.BrBaseMaze = {}
	t.BrMazeMoveDirection = mapvars.MoveDirection
	if t.BrMazeMoveDirection ~= "Up" and t.BrMazeMoveDirection ~= "Down" then
		t.BrMazeMoveDirection = "Down"
	end

	t.BrMazeLevel = mapvars.MazeLevel
	SaveMazeData(t.BrBaseMaze, true)

	-- done by multiplayer routines
	t.BrBaseMaze.MonData = nil
	t.BrBaseMaze.Objects = nil
	t.BrBaseMaze.SpritesXYZ = nil
	t.mapvars = nil

	Multiplayer.utils.LogEvent("MAP_LOAD", "%s: Preparing maze data: [%s] = %s. (MazeLevel: %s, MoveDirection: %s)", Map.Name, mapvars.MazeLevel, t.BrBaseMaze, mapvars.MazeLevel, mapvars.MoveDirection)
end

function events.MultiplayerProcessMapData(t)
	if t.BrBaseMaze then
		if Merge.Tables.BrBase then
			mapvars = Merge.Tables.BrBase
		end
		mapvars.OtherFloors = mapvars.OtherFloors or {}
		mapvars.MazeLevel = t.BrMazeLevel
		mapvars.OtherFloors[mapvars.MazeLevel] = t.BrBaseMaze
		mapvars.MoveDirection = t.BrMazeMoveDirection
		Multiplayer.utils.LogEvent("MAP_LOAD", "%s: Maze data set: [%s] = %s. (MoveDirection: %s)", Map.Name, mapvars.MazeLevel, t.BrBaseMaze, mapvars.MoveDirection)

		Merge.Tables.BrBase = mapvars
	end
end

function events.MultiplayerUserdataArrived(t)
	local handlers = {
		[msgs.LevelChange] = function(t)
			Multiplayer.utils.LogEvent("MAP_LOAD", "Received BrBase level change notification: %d -> %d", mapvars.MazeLevel, t.MazeLevel)
			if t.MazeLevel == mapvars.MazeLevel then
				return
			end

			Multiplayer.BrBase.LevelChangeInProgress = true
			mapvars.NeedBroadcast = false
			Multiplayer.utils.LogEvent("MAP_LOAD", "Initiating map load")
			Multiplayer.LoadMapData[Map.MapStatsIndex] = t.Data
			TriggerReload()
		end,

		[msgs.TrapDisarmed] = function(t)
			TrapSpells[t.CellId] = 0
			local F = Map.Facets[t.FacetId]
			F.IsSecret = false
			Map.FacetData[F.DataIndex].Event = 0
		end,

		[msgs.CanChangeLevel] = function(t)
			Multiplayer.broadcast_mapdata{
				MType = msgs.CanChangeLevelResponse,
				ClientId = Multiplayer.my_id,
				Result = Multiplayer.BrBase.LevelChangeInProgress}
		end,

		[msgs.CanChangeLevelResponse] = function(t)
			Multiplayer.BrBase.LevelChange[t.ClientId] = t.Result
		end,
	}

	local handler = handlers[t.MType]
	if handler then
		handler(t)
	end
end

local function NotifyLevelChange()
	if not (Multiplayer and Multiplayer.in_game) then
		return
	end

	local t = {
		MType = msgs.LevelChange,
		Author = Multiplayer.my_id,
		MazeLevel = mapvars.MazeLevel,
		Data = Multiplayer.prep_map_data()
	}
	Multiplayer.broadcast_mapdata(t)
end

local function NotifyTrapDisarmed(FacetId, CellId)
	if not (Multiplayer and Multiplayer.in_game) then
		return
	end

	local t = {
		MType = msgs.TrapDisarmed,
		Author = Multiplayer.my_id,
		FacetId = FacetId,
		CellId = CellId
	}
	Multiplayer.broadcast_mapdata(t)
end

local function NotifyCanChangeLevel()
	if not (Multiplayer and Multiplayer.in_game) then
		return
	end

	local t = {	MType = msgs.CanChangeLevel}
	Multiplayer.broadcast_mapdata(t)
end

---------------------------------

local function OnLoadMap()
	Multiplayer.utils.LogEvent("MAP_LOAD", "OnLoad started (MazeLevel: %s, MoveDirection: %s)", mapvars.MazeLevel, mapvars.MoveDirection)

	if Merge.Tables.BrBase then
		mapvars = Merge.Tables.BrBase
		Merge.Tables.BrBase = nil
	end
	mapvars.MazeLevel = mapvars.MazeLevel or 1

	if QSet and not QSet.EnteredBasement and not QSet.QuestFinished then
		mapvars.MazeLevel = 3
		Multiplayer.utils.LogEvent("MAP_LOAD", "MazeLevel set to 3 (MazeLevel: %s, MoveDirection: %s)", mapvars.MazeLevel, mapvars.MoveDirection)
	elseif mapvars.MoveDirection == "0" then
		mapvars.MazeLevel = 1
	end

	mapvars.OtherFloors = mapvars.OtherFloors or {}
	MonRage = {}

	if not mapvars.MoveDirection or mapvars.MoveDirection == "0" then
		mapvars.OtherFloors = {}
	end

	if mapvars.OtherFloors[mapvars.MazeLevel] then
		ResetMaze()
		LoadMazeData(mapvars.OtherFloors[mapvars.MazeLevel], true)

	else
		Multiplayer.utils.LogEvent("MAP_LOAD", "Data generated (MazeLevel: %s, MoveDirection: %s)", mapvars.MazeLevel, mapvars.MoveDirection)
		InitMaze()

		local Cell
		if QSet and not QSet.EnteredBasement and not QSet.QuestFinished then
			Cell = mapvars.CellsInfo[mapvars.ExitCell]
		else
			Cell = mapvars.CellsInfo[mapvars.MoveDirection == "Up" and mapvars.ExitCell or mapvars.EnterCell]
		end

		Party.X = Cell.cX
		Party.Y = Cell.cY
		Party.Z = Cell.cZ

		TrapSpells = {}
		TrapNextShot = {}
		EmptyBookcases = {}

	end

	if QSet then
		QSet.EnteredBasement = true
	end

	Timer(MonHostile, const.Minute, true)

	if Game.IsD3D then
		Map.Rooms[1].Darkness = 26
	else
		Map.Rooms[1].Darkness = 36
	end

	local MazeLevel = mapvars.MazeLevel
	if MazeLevel == 1 then
		evt.hint[1] = evt.str[1] -- "Exit Breach Basement."
	else
		evt.hint[1] = string.format(evt.str[2], MazeLevel-1) -- "Go up to the %sth floor."
	end
	evt.hint[2] = string.format(evt.str[3], MazeLevel+1) -- "Go down to the %sth floor."

	Map.BloodSplatsCount = 0
	Map.BloodSplatsCreated = 0

	if mapvars.NeedBroadcast then
		Multiplayer.utils.LogEvent("MAP_LOAD", "Broadcasting maze change")
		mapvars.NeedBroadcast = false
		NotifyLevelChange() -- Multiplayer
	end

	Multiplayer.BrBase.LevelChangeInProgress = false
end

---------------------------------

---------------------------------
-- Active elements functions
---------------------------------

local function ExitMaze()

	Multiplayer.BrBase.LevelChangeInProgress = true
	NotifyCanChangeLevel()

	Multiplayer.events.Once("Action", function(t)
		if t.Action == 412 then
			Multiplayer.BrBase.LevelChangeInProgress = false
		end
	end)

	evt.MoveToMap{0,0,0,0,0,0,0,1,"0"}

	if not CanChangeLevel() then
		evt.FaceAnimation{Game.CurrentPlayer, const.FaceAnimation.DoorLocked}
		Multiplayer.BrBase.LevelChangeInProgress = false
		return
	end

	if mapvars.MazeLevel <= 1 then
		mapvars.MazeLevel = 1
		mapvars.MoveDirection = "0"
		if QSet then
			QSet.EnteredBreach = true
			if QSet.QuestFinished then
				evt.MoveToMap{1578,899,847,1160,0,0,0,0,"Breach.odm"}
			else
				evt.MoveToMap{1578,899,847,1160,0,0,0,0,"BrAlvar.odm"}
			end
		else
			evt.MoveToMap{20487,-4443,2,1167,0,0,0,0,"out02.odm"}
		end
	else
		local OtherFloors = mapvars.OtherFloors
		local CurLevel = mapvars.MazeLevel

		OtherFloors[CurLevel] = {}
		SaveMazeData(OtherFloors[CurLevel], true)

		OtherFloors[CurLevel+2] = nil
		OtherFloors[CurLevel-2] = nil

		mapvars.MazeLevel = mapvars.MazeLevel - 1
		mapvars.MoveDirection = "Up"

		Multiplayer.LoadMapData[Map.MapStatsIndex] = true
		mapvars.NeedBroadcast = true
		TriggerReload()
	end
end

local function NextLevel()
	if QSet and not QSet.QuestFinished then
		evt.FaceAnimation{Game.CurrentPlayer, const.FaceAnimation.DoorLocked}
		return
	end

	Multiplayer.BrBase.LevelChangeInProgress = true
	NotifyCanChangeLevel()

	Multiplayer.events.Once("Action", function(t)
		if t.Action == 412 then
			Multiplayer.BrBase.LevelChangeInProgress = false
		end
	end)

	evt.MoveToMap{0,0,0,0,0,0,0,1,"0"}

	if not CanChangeLevel() then
		evt.FaceAnimation{Game.CurrentPlayer, const.FaceAnimation.DoorLocked}
		Multiplayer.BrBase.LevelChangeInProgress = false
		return
	end

	local OtherFloors = mapvars.OtherFloors
	local CurLevel = mapvars.MazeLevel

	OtherFloors[CurLevel] = {}
	SaveMazeData(OtherFloors[CurLevel], true)

	OtherFloors[CurLevel+2] = nil
	OtherFloors[CurLevel-2] = nil

	mapvars.MazeLevel = CurLevel + 1
	mapvars.MoveDirection = "Down"

	Multiplayer.LoadMapData[Map.MapStatsIndex] = true
	mapvars.NeedBroadcast = true
	TriggerReload()
end

local function FloorTrap()
	local X,Y = floor((Party.X + 300.525)/601.5)+1, floor((-Party.Y + 300.525)/601.5)+1
	local Cell, TrapSpell, CellId
	local Maze = mapvars.Maze

	if Maze[Y] and Maze[Y][X] then
		Cell = Maze[Y][X].cell
		CellId = Cell
		TrapSpell = TrapSpells[Cell]

		if not TrapSpell then
			TrapSpell = TrapSpellsList[random(1, min(mapvars.MazeLevel, #TrapSpellsList))]
			TrapSpells[Cell] = TrapSpell
		end

		if TrapSpell == 0 then
			return -- trap have been disarmed

		elseif Game.CurrentPlayer >= 0 then
			local Pl = Party[Game.CurrentPlayer]
			local Skill, Mas = SplitSkill(Pl.Skills[const.Skills.DisarmTraps])
			if Mas == 4 or Skill > ceil(mapvars.MazeLevel/Mas) then
				TrapSpells[CellId] = 0
				Game.ShowStatusText(evt.str[4]) -- "Trap disarmed!"
				evt.FaceAnimation(Game.CurrentPlayer, const.FaceAnimation.DisarmTrap)
				Cell = mapvars.CellsInfo[Cell]

				NotifyTrapDisarmed(Cell.Floor, CellId)
				local F = Map.Facets[Cell.Floor]
				F.IsSecret = false
				Map.FacetData[F.DataIndex].Event = 0
				return
			end
		end

		if TrapNextShot[Cell] and TrapNextShot[Cell] > Game.Time then
			return
		end
		TrapNextShot[Cell] = Game.Time + const.Minute*3

		Cell = mapvars.CellsInfo[Cell]
		evt.FaceAnimation(Game.CurrentPlayer, random(5,6))
		Game.ShowStatusText(evt.str[5]) -- "Trap!"
		evt.CastSpell{TrapSpell, 3, 7, Cell.cX, Cell.cY, Cell.cZ + 200, Party.X, Party.Y, Party.Z + random(100)}

		if random(1,3) == 1 then
			TrapSpells[CellId] = 0 -- Trap won't fire anymore.

			NotifyTrapDisarmed(Cell.Floor, CellId)
			local F = Map.Facets[Cell.Floor]
			F.IsSecret = false
			Map.FacetData[F.DataIndex].Event = 0
		end
	end

end

local function Bookcase()

	local X,Y = floor((Party.X + 300.525)/601.5)+1, floor((-Party.Y + 300.525)/601.5)+1
	local Cell
	local Maze, MazeLevel = mapvars.Maze, mapvars.MazeLevel

	if Maze[Y] and Maze[Y][X] then
		Cell = Maze[Y][X].cell

		if EmptyBookcases[Cell] then
			Game.ShowStatusText(Game.GlobalTxt[521])
		else
			EmptyBookcases[Cell] = true
			evt[0].GiveItem{min(random(ceil(MazeLevel/2), MazeLevel), 6), 16, 0}

		end
	end

end
---------------------------------

---------------------------------
-- Events
---------------------------------

function events.MonsterNeedPathfinding(t)
	if not MonRage[t.MonsterIndex] then
		t.Result = false
	end
end

function events.AfterLoadMap()
	OnLoadMap(true)

	evt.map[1] = ExitMaze
	evt.map[2] = NextLevel
	evt.map[3] = FloorTrap
	evt.map[4] = Bookcase
	evt.hint[4] = evt.str[6]
end

function events.CanCastLloyd(t)
	t.Result = false
end

function events.CanCastTownPortal(t)
	TownPortalControls.GenDimDoor()
	TownPortalControls.SwitchTo(4)
end

function events.CalcDamageToMonster(t)
	if t.ByPlayer then
		MonRage[t.MonsterIndex] = true
	end
end

function events.BeforeSaveGame()
	mapvars.OtherFloors[mapvars.MazeLevel] = {}
	SaveMazeData(mapvars.OtherFloors[mapvars.MazeLevel], true)
end

--------------------------------
-- Service

--~ PrintMaze = function()
--~ 	local str = ""
--~ 	for k,v in pairs(mapvars.Maze) do
--~ 		str = str .. "\n"
--~ 		for a,b in pairs(v) do
--~ 			if b.south then
--~ 				str = str .. "__"
--~ 			else
--~ 				str = str .. "  "
--~ 			end

--~ 			if b.east then
--~ 				str = str .. "|"
--~ 			else
--~ 				str = str .. " "
--~ 			end
--~ 		end
--~ 	end
--~ 	return str
--~ end


