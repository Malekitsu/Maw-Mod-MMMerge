local lookupTable = {}
function getRange(str)
	if lookupTable[str] then return lookupTable[str][1], lookupTable[str][2] end
	local min, max = str:match("(%d+)%-(%d+)")
	min = tonumber(min)
	max = tonumber(max)
	assert(min ~= nil and max ~= nil)
	lookupTable[str] = {min, max}
	return min, max
end

local random = math.random
function pseudoSpawnpoint(monster, x, y, z, count, powerChances, radius, group, exactZ)
	local t = {} -- will hold arguments
	if type(monster) == "table" then
		t = monster -- user passed table with arguments instead of monster
	else
		-- pack all arguments into a table
		t.monster = monster, monster
		t.x = x
		t.y = y
		t.z = z
		t.count = count
		t.powerChances = powerChances
		t.radius = radius
		t.group = group
		t.exactZ = exactZ
	end
	t.count = t.count or "1-3" -- count is 1-3 by default (if unspecified)
	t.powerChances = t.powerChances or {34, 33, 33}
	t.radius = t.radius or 256
	assert(t.monster and t.x and t.y and (not t.exactZ or t.z), "pseudoSpawnpoint() call is missing critical parameters") -- make sure that all required parameters are provided
	local class = (t.monster + 2):div(3) -- class now contains id of monster class (group of 3 monsters of increasing tiers, as all types are divided into 3 tiers)
	
	local toCreate -- will hold how many monsters to create
	if type(t.count) == "string" then
		local min, max = getRange(t.count)
		toCreate = random(min, max)
	elseif type(t.count) == "table" then
		toCreate = random(t.count[1], t.count[2])
	elseif type(t.count) == "number" then
		toCreate = t.count
	else
		error("Unsupported monster count type", 2)
	end
	
	local summoned = {} -- will hold summoned monsters to return
	for i = 1, toCreate do
		if Map.Monsters.Count >= Map.Monsters.Limit - 20 then
			return summoned
		end
		local x, y, z
		local spawnAttempts = 0
		local failReasons = {}
		while true do
			-- generate random point in a circle centered on provided xy and with provided radius
			local angle = random() * math.pi * 2
			local xadd = math.cos(angle) * random(1, t.radius)
			local yadd = math.sin(angle) * random(1, t.radius)
			x, y = t.x + xadd, t.y + yadd
			z = not t.exactZ and Map.IsOutdoor() and Map.GetGroundLevel(x, y) or t.z
			if Map.IsIndoor() and Map.RoomFromPoint(x, y, z) > 0 then -- room from point check makes sure that monsters won't generate in a wall
				break
			elseif Map.IsIndoor() then
				table.insert(failReasons, {"monster generated in a wall", x, y, z})
			elseif Map.IsOutdoor() then
				-- check if 
				local tilesetFileSuffixes = {[0] = "", [1] = 2, [2] = 3}
				local tilesetsFile = "Tile" .. (Game.Version == 8 and (tilesetFileSuffixes[Map.TilesetsFile] or error("Unknown tileset file " .. Map.TilesetsFile)) or "") .. "Bin"
				local tileId = Map.TileMap[(64 - y / 0x200):floor()][(64 + x / 0x200):floor()]
				--if Game[tilesetsFile][tileId].Water and Game.MonstersTxt[class * 3 - 2].Fly == 0 then
				--	table.insert(failReasons, {"non-flying monster generated above water", x, y, z})
				--else
				break
				--end
			end
			spawnAttempts = spawnAttempts + 1
			if spawnAttempts >= 20 then
				local t2 = {}
				for i, v in ipairs(failReasons) do
					table.insert(t2, string.format("%d:	reason: %s		x: %d	y: %d	z: %d", i, unpack(v)))
				end
				local errorMessage = "\nCouldn't spawn monster, spawnpoint data: " .. dump(t) .. "\n\nSubsequent spawn failure reasons:\n" .. table.concat(t2, "\n")
				error(errorMessage, 2)
			end
		end
		
		-- generate random monster power according to defined powerChances
		local power
		local rand = random(1, 100)
		if t.powerChances[1] ~= 0 and (rand <= t.powerChances[1] or (t.powerChances[2] == 0 and t.powerChances[3] == 0)) then
			power = 0
		elseif t.powerChances[2] ~= 0 and ((rand <= t.powerChances[2] + t.powerChances[1]) or (t.powerChances[1] == 0 and t.powerChances[3] == 0)) then
			power = 1
		elseif t.powerChances[3] ~= 0 then
			power = 2
		elseif t.powerChances[2] ~= 0 then
			power = 1
		else
			power = 0
		end
		
		-- summon monster
		local mon = SummonMonster(class * 3 - 2 + power, x, y, z, true) -- true means monster has treasure
		-- set group
		mon.Group = t.group or 255
		-- perform transform if it is set
		if t.transform and type(t.transform) == "function" then
			t.transform(mon)
		end
		
		-- insert into table to return later
		table.insert(summoned, mon)
	end
	return summoned
end

function psp()
  print(string.format("x = %d, y = %d, z = %d", XYZ(Party)))
  print(string.format("x = %d, y = %d", Party.X, Party.Y))
end

if not table.join then
	function table.join(t1, t2)
		local n = #t1
		for i = 1, #t2 do
			t1[n + i] = t2[i]
		end
		return t1
	end
end

function joinTables(...)
	local n = select("#", ...)
	if n == 0 then return {} end
	local t = (select(1, ...))
	for i = 2, n do
		t = table.join(t, (select(i, ...)))
	end
	return t
end
