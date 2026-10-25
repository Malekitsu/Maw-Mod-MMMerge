-- TrainerHint.lua -- optional line in the skill tooltip: who teaches the next
-- mastery of this skill, and where.
--
-- Pure core (buildIndex / pick / compose / selfTest): no engine globals, so it
-- loads and tests under a plain Lua interpreter. All engine reads sit in the
-- game adapter further down and reach the core through a `src` table.
--
-- Index: [skillId][mastery] = list of entries, mastery as in Teacher topics.txt
-- (1 = Expert teacher, 2 = Master, 3 = Grand Master).

local TrainerHint = {}
MawCore.TrainerHint = TrainerHint

TrainerHint.MAX_ENTRIES = 1		-- the tooltip box is short: the nearest teacher only

-- 2DEvents.txt names the houses of the ordinary Enroth teachers just "House"
local PLACEHOLDER_HOUSE = "House"

-- TownPortalControls.MapOfContinent
local CONTINENTS = {[1] = "Jadame", [2] = "Antagarich", [3] = "Enroth"}

local COLOR_HEAD = {255, 255, 100}
local COLOR_MET = {0, 255, 0}
local COLOR_MISSING = {255, 0, 0}

local function trim(s)
	return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function isOutdoor(file)
	return file ~= nil and tostring(file):lower():sub(-4) == ".odm"
end

-- src = {
--   npcs      = {{id, name, house, events = {topicId, ...}}, ...}
--   topics    = {[topicId] = {SId = skill, Mas = mastery}}   (Teacher topics.txt)
--   moves     = {[mapFile] = {{npc, house}, ...}} or nil     (zzMAW_MoveTrainers.lua)
--   houseMap  = function(house) -> map index or nil
--   mapInfo   = function(map)   -> {name, file, cont} or nil
--   houseName = function(house) -> string or nil
-- }
-- An NPC is listed at the house it stands in plus every house the move script
-- may put it in; one entry per (npc, house) and slot.
function TrainerHint.buildIndex(src)
	local index = {}
	-- every skill that has a teacher topic is known, taught by anyone or not:
	-- "No trainer found." needs to tell that apart from "nobody teaches this"
	for _, topic in pairs(src.topics) do
		index[topic.SId] = index[topic.SId] or {}
		index[topic.SId][topic.Mas] = index[topic.SId][topic.Mas] or {}
	end

	local movedTo = {}
	if src.moves then
		for _, list in pairs(src.moves) do
			for _, move in ipairs(list) do
				movedTo[move[1]] = movedTo[move[1]] or {}
				table.insert(movedTo[move[1]], move[2])
			end
		end
	end

	local places = {}		-- [house] = place table, or false when it can't be shown
	local function placeOf(house)
		local place = places[house]
		if place == nil then
			place = false
			local map = src.houseMap(house)
			local info = map and src.mapInfo(map)
			if info then
				local houseName = trim(src.houseName(house))
				if houseName == "" or houseName == PLACEHOLDER_HOUSE then
					houseName = nil
				end
				place = {
					house = house, houseName = houseName, map = map,
					mapName = info.name or info.file or "?", cont = info.cont,
					outdoor = isOutdoor(info.file),
				}
			end
			places[house] = place
		end
		return place or nil
	end

	local listed = {}		-- [skill:mastery:npc:house] = true
	for _, npc in ipairs(src.npcs) do
		local taught = {}
		for _, eventId in ipairs(npc.events) do
			local topic = src.topics[eventId]
			if topic then
				taught[#taught + 1] = topic
			end
		end
		if #taught > 0 then
			local houses, seen = {}, {}
			local function add(house)
				if house and house ~= 0 and not seen[house] then
					seen[house] = true
					houses[#houses + 1] = house
				end
			end
			add(npc.house)
			for _, house in ipairs(movedTo[npc.id] or {}) do
				add(house)
			end
			for _, house in ipairs(houses) do
				local place = placeOf(house)
				if place then
					for _, topic in ipairs(taught) do
						local key = topic.SId .. ":" .. topic.Mas .. ":" .. npc.id .. ":" .. house
						if not listed[key] then
							listed[key] = true
							local slot = index[topic.SId][topic.Mas]
							slot[#slot + 1] = {
								npc = npc.id, name = trim(npc.name), house = house,
								houseName = place.houseName, map = place.map,
								mapName = place.mapName, cont = place.cont,
								outdoor = place.outdoor,
							}
						end
					end
				end
			end
		end
	end
	return index
end

-- Where one can get to from each map in one step: links[from][to] = "walk" (the
-- outdoor map borders it) or "route" (a coach or boat goes there; walking wins).
-- src = {
--   travels   = {[fileLower] = {up|down|left|right = {map = file}}}   (Game.OutdoorTravels)
--   routes    = {{from = map, to = {map, ...}}, ...}                  (coach and boat houses)
--   mapByFile = function(fileLower) -> map index or nil
-- }
-- Missing parts just mean fewer links.
function TrainerHint.buildLinks(src)
	local links = {}
	if not src or not src.mapByFile then
		return links
	end
	local function link(from, to, kind)
		if from and to and from ~= to then
			links[from] = links[from] or {}
			if links[from][to] ~= "walk" then
				links[from][to] = kind
			end
		end
	end
	for file, travel in pairs(src.travels or {}) do
		local from = src.mapByFile(tostring(file):lower())
		if from then
			for _, side in ipairs({"up", "down", "left", "right"}) do
				local exit = type(travel) == "table" and travel[side]
				if exit and exit.map then
					link(from, src.mapByFile(tostring(exit.map):lower()), "walk")
				end
			end
		end
	end
	for _, route in ipairs(src.routes or {}) do
		for _, to in ipairs(route.to or {}) do
			link(route.from, to, "route")
		end
	end
	return links
end

-- the neighbours pick() gets: those of the party map plus, in an indoor map,
-- those of the outdoor map the party came from (refMap); walking wins. nil when
-- neither has any.
function TrainerHint.neighbours(links, curMap, refMap)
	local a = links and curMap ~= nil and links[curMap] or nil
	local b = links and refMap ~= nil and links[refMap] or nil
	if not (a and b) then
		return a or b
	end
	local out = {}
	for map, kind in pairs(a) do
		out[map] = kind
	end
	for map, kind in pairs(b) do
		if out[map] ~= "walk" then
			out[map] = kind
		end
	end
	return out
end

-- rank 0 = party map (or the outdoor map the party came from when it stands in
-- an indoor one: refMap, marked outside = true), 1 = a neighbour (neighbors[map]
-- = "walk" | "route"), 2 = same continent, 3 = rest; then outdoor before indoor
-- maps, continent, map name, NPC name. A teacher who stands in several places
-- counts once, at the best one.
function TrainerHint.pick(entries, curMap, curCont, limit, neighbors, refMap)
	limit = limit or TrainerHint.MAX_ENTRIES
	local ranked = {}
	for i, e in ipairs(entries or {}) do
		local rank = 3
		if e.map == curMap or (refMap ~= nil and e.map == refMap) then
			rank = 0
		elseif neighbors and neighbors[e.map] then
			rank = 1
		elseif curCont ~= nil and e.cont == curCont then
			rank = 2
		end
		ranked[i] = {e = e, rank = rank}
	end
	table.sort(ranked, function(a, b)
		if a.rank ~= b.rank then
			return a.rank < b.rank
		end
		local ea, eb = a.e, b.e
		if ea.outdoor ~= eb.outdoor then
			return ea.outdoor
		end
		local ca, cb = ea.cont or math.huge, eb.cont or math.huge
		if ca ~= cb then
			return ca < cb
		end
		if ea.mapName ~= eb.mapName then
			return ea.mapName < eb.mapName
		end
		if ea.name ~= eb.name then
			return ea.name < eb.name
		end
		if ea.npc ~= eb.npc then
			return ea.npc < eb.npc
		end
		return ea.house < eb.house
	end)
	local out, taken = {}, {}
	for _, r in ipairs(ranked) do
		if #out >= limit then
			break
		end
		if not taken[r.e.npc] then
			taken[r.e.npc] = true
			local copy = {}
			for k, v in pairs(r.e) do
				copy[k] = v
			end
			copy.rank = r.rank
			copy.link = r.rank == 1 and neighbors[r.e.map] or nil
			copy.outside = r.rank == 0 and r.e.map ~= curMap or nil
			out[#out + 1] = copy
		end
	end
	return out
end

local function defaultColor(r, g, b, s)
	if StrColor then
		return StrColor(r, g, b, s)
	end
	return s
end

-- info.kind:
--   "trainers"  nextName, need, have, curCont, trainers (picked entries)
--   "none"      nextName
--   "auto"      nextName, need
--   "promotion" nextName, need, have, curCont, trainers (possibly empty; nil = skill
--               without teachers, learned automatically)
--   "max"
--   "grandmaster"  (nothing left to learn)
-- `color` (r, g, b, text) defaults to the engine's StrColor.
function TrainerHint.compose(info, color)
	if not info then
		return nil
	end
	color = color or defaultColor
	local function paint(c, s)
		return color(c[1], c[2], c[3], s)
	end
	local kind = info.kind
	if kind == "trainers" and not (info.trainers and #info.trainers > 0) then
		kind = "none"
	end
	if kind == "max" then
		return paint(COLOR_HEAD, "Highest mastery for this class reached.")
	end
	if kind == "grandmaster" then
		return paint(COLOR_HEAD, "Grand Master reached.")
	end
	if kind ~= "none" and kind ~= "auto" and kind ~= "trainers" and kind ~= "promotion" then
		return nil
	end
	local head = "Next mastery: " .. info.nextName
	if kind == "none" then
		return paint(COLOR_HEAD, head) .. "\n No trainer found."
	elseif kind == "auto" then
		return paint(COLOR_HEAD, head) .. "\n Learned automatically at skill " .. info.need .. "."
	end

	local met = info.have ~= nil and info.have >= info.need
	local lines = {paint(COLOR_HEAD, head .. " (skill ")
		.. paint(met and COLOR_MET or COLOR_MISSING, tostring(info.need))
		.. paint(COLOR_HEAD, " required)")}
	if kind == "promotion" then
		lines[#lines + 1] = " Requires a class promotion first."
	end
	if info.trainers and #info.trainers == 0 then
		lines[#lines + 1] = " No trainer found."
	end
	for _, e in ipairs(info.trainers or {}) do
		local line = " " .. e.name .. " - "
		if e.houseName then
			line = line .. e.houseName .. ", "
		end
		line = line .. e.mapName
		if e.rank == 0 then
			line = line .. " " .. paint(COLOR_MET, e.outside and "(outside)" or "(this map)")
		else
			local tags = {}
			if e.rank == 1 and e.link == "walk" then
				tags[#tags + 1] = "next map"
			elseif e.rank == 1 and e.link == "route" then
				tags[#tags + 1] = "coach/boat"
			end
			if e.cont and e.cont ~= info.curCont and CONTINENTS[e.cont] then
				tags[#tags + 1] = CONTINENTS[e.cont]
			end
			if #tags > 0 then
				line = line .. " (" .. table.concat(tags, ", ") .. ")"
			end
		end
		lines[#lines + 1] = line
	end
	return table.concat(lines, "\n")
end

function TrainerHint.selfTest()
	local errors = {}
	local function eq(name, got, want)
		if got ~= want then
			errors[#errors + 1] = ("%s: got %s, want %s"):format(name, tostring(got), tostring(want))
		end
	end
	local function plain(r, g, b, s)
		return s
	end
	local function tag(r, g, b, s)
		return ("<%d,%d,%d:%s>"):format(r, g, b, s)
	end
	-- "Ann@101,Ed@103" -- entry list as text, in list order
	local function show(list)
		local t = {}
		for i, e in ipairs(list) do
			t[i] = e.name .. "@" .. e.house
		end
		return table.concat(t, ",")
	end
	-- same, sorted: for index slots, whose inner order is not part of the contract
	local function showSorted(list)
		local t = {}
		for i, e in ipairs(list) do
			t[i] = e.name .. "@" .. e.house
		end
		table.sort(t)
		return table.concat(t, ",")
	end

	-- synthetic world ---------------------------------------------------
	local maps = {
		[1] = {name = "Alpha", file = "out01.odm", cont = 1},
		[2] = {name = "Beta", file = "out02.odm", cont = 2},
		[3] = {name = "Cave", file = "d01.blv", cont = 1},
		[4] = {name = "Gamma", file = "out03.odm"},		-- continent unknown
	}
	local houseMaps = {[0] = 1, [101] = 1, [102] = 2, [103] = 3, [105] = 4}	-- 104: no map; 0 must be skipped even if it maps
	local houseNames = {[101] = "Hunter's Hovel", [102] = "House", [103] = "  ", [105] = "Gamma Hall"}
	local topics = {
		[10] = {SId = 5, Mas = 1},
		[11] = {SId = 5, Mas = 2},
		[12] = {SId = 7, Mas = 1},
		[13] = {SId = 5, Mas = 3},		-- a topic nobody has
	}
	local npcs = {
		{id = 1, name = "Ann", house = 101, events = {10, 0, 0, 0, 0, 0}},
		{id = 2, name = "Bob", house = 0, events = {10}},		-- house 0
		{id = 3, name = "Cy", house = 104, events = {10}},		-- house without a map
		{id = 4, name = "Di", house = 102, events = {11, 12}},	-- two topics
		{id = 5, name = "Ed", house = 103, events = {10}},		-- indoor map
		{id = 6, name = "Flo", house = 105, events = {10}},		-- continent unknown
		{id = 7, name = "Gus", house = 102, events = {99}},		-- no teacher topic
	}
	local moves = {
		["x.odm"] = {{1, 102}, {1, 103}, {7, 101}},
		["y.odm"] = {{1, 103}, {1, 101}},					-- repeats
	}
	local function src(moveTable)
		return {
			npcs = npcs, topics = topics, moves = moveTable,
			houseMap = function(h) return houseMaps[h] end,
			mapInfo = function(m) return maps[m] end,
			houseName = function(h) return houseNames[h] end,
		}
	end

	-- buildIndex -----------------------------------------------------------
	local index = TrainerHint.buildIndex(src(moves))
	local expert = index[5] and index[5][1] or {}
	eq("index[5][1] (moves)", showSorted(expert), "Ann@101,Ann@102,Ann@103,Ed@103,Flo@105")
	eq("index[5][2]", showSorted(index[5] and index[5][2] or {}), "Di@102")
	eq("index[7][1] (npc with two topics)", showSorted(index[7] and index[7][1] or {}), "Di@102")
	eq("index[5][3] exists and is empty", index[5] and index[5][3] and #index[5][3], 0)
	eq("index[9] (skill without topics)", index[9], nil)
	local plainIndex = TrainerHint.buildIndex(src(nil))
	eq("index[5][1] (moves=nil)", showSorted(plainIndex[5] and plainIndex[5][1] or {}), "Ann@101,Ed@103,Flo@105")

	local byKey = {}
	for _, e in ipairs(expert) do
		byKey[e.name .. "@" .. e.house] = e
	end
	local ann, ed, flo = byKey["Ann@101"], byKey["Ed@103"], byKey["Flo@105"]
	eq("entry house name kept", ann and ann.houseName, "Hunter's Hovel")
	eq("entry map name", ann and ann.mapName, "Alpha")
	eq("entry map id", ann and ann.map, 1)
	eq("entry npc id", ann and ann.npc, 1)
	eq("entry outdoor", ann and ann.outdoor, true)
	eq("placeholder house name dropped", byKey["Ann@102"] and tostring(byKey["Ann@102"].houseName), "nil")
	eq("blank house name dropped", ed and tostring(ed.houseName), "nil")
	eq("indoor map is not outdoor", ed and ed.outdoor, false)
	eq("unknown continent stays nil", flo and tostring(flo.cont), "nil")

	local dupIndex = TrainerHint.buildIndex({
		npcs = {{id = 8, name = "Hal", house = 101, events = {10, 10}}},
		topics = topics, moves = {["z.odm"] = {{8, 101}}},
		houseMap = function(h) return houseMaps[h] end,
		mapInfo = function(m) return maps[m] end,
		houseName = function(h) return houseNames[h] end,
	})
	eq("one entry per (npc, house) and slot", #(dupIndex[5] and dupIndex[5][1] or {}), 1)
	local paddedIndex = TrainerHint.buildIndex({
		npcs = {{id = 9, name = "Pat  ", house = 101, events = {10}}},
		topics = topics,
		houseMap = function(h) return houseMaps[h] end,
		mapInfo = function(m) return maps[m] end,
		houseName = function(h) return houseNames[h] end,
	})
	eq("NPC names are trimmed (the tables pad some)", paddedIndex[5] and paddedIndex[5][1] and paddedIndex[5][1][1]
		and paddedIndex[5][1][1].name, "Pat")

	-- pick -------------------------------------------------------------------
	eq("pick same map, then continent, then rest",
		show(TrainerHint.pick(expert, 1, 1, 3)), "Ann@101,Ed@103,Flo@105")
	eq("pick ranks", (function()
		local r = TrainerHint.pick(expert, 1, 1, 3)
		return table.concat({tostring(r[1] and r[1].rank), tostring(r[2] and r[2].rank), tostring(r[3] and r[3].rank)}, ",")
	end)(), "0,2,3")
	eq("pick limit", show(TrainerHint.pick(expert, 2, 2, 2)), "Ann@102,Flo@105")
	eq("pick outdoor before indoor, unknown continent last",
		show(TrainerHint.pick(expert, 99, nil, 3)), "Ann@101,Flo@105,Ed@103")
	eq("pick indoor map of the party", show(TrainerHint.pick(expert, 3, 1, 3)), "Ann@103,Ed@103,Flo@105")
	eq("pick one entry per npc", show(TrainerHint.pick(expert, 1, 1, 10)), "Ann@101,Ed@103,Flo@105")
	eq("pick default limit is MAX_ENTRIES", #TrainerHint.pick(expert, 99, nil), TrainerHint.MAX_ENTRIES)
	eq("MAX_ENTRIES is 1: only the nearest trainer", TrainerHint.MAX_ENTRIES, 1)
	eq("pick empty list", #TrainerHint.pick({}, 1, 1, 3), 0)
	-- neighbours: neighbors[map] = "walk" | "route" (out of the map the party stands on)
	eq("pick: a walk neighbour beats a teacher elsewhere on the continent",
		show(TrainerHint.pick(expert, 99, 1, 1, {[4] = "walk"})), "Flo@105")
	eq("pick: without neighbour data the continent decides as before",
		show(TrainerHint.pick(expert, 99, 1, 1)), "Ann@101")
	eq("pick: neighbours, then the rest of the continent", show(TrainerHint.pick(expert, 99, 1, 3,
		{[2] = "route", [4] = "walk"})), "Ann@102,Flo@105,Ed@103")
	eq("pick: neighbour ranks and links", (function()
		local r = TrainerHint.pick(expert, 99, 1, 3, {[2] = "route", [4] = "walk"})
		return table.concat({r[1].rank, tostring(r[1].link), r[2].rank, tostring(r[2].link), r[3].rank, tostring(r[3].link)}, ",")
	end)(), "1,route,1,walk,2,nil")
	eq("pick: the party's own map still comes first", show(TrainerHint.pick(expert, 1, 1, 2, {[2] = "route"})),
		"Ann@101,Ed@103")
	eq("pick: party in an indoor map, last outdoor map as reference", (function()
		local r = TrainerHint.pick(expert, 3, 1, 3, {[4] = "walk"}, 1)
		return show(r) .. ";" .. r[1].rank .. r[2].rank .. r[3].rank
	end)(), "Ann@101,Ed@103,Flo@105;001")
	eq("pick: a teacher on the reference map is outside, one on the party map is not", (function()
		local r = TrainerHint.pick(expert, 3, 1, 3, {[4] = "walk"}, 1)
		return tostring(r[1].outside) .. "," .. tostring(r[2].outside) .. "," .. tostring(r[3].outside)
	end)(), "true,nil,nil")
	eq("pick: without a reference map the indoor map counts alone", show(TrainerHint.pick(expert, 3, 1, 3)),
		"Ann@103,Ed@103,Flo@105")
	eq("pick leaves the index alone", tostring((expert[1] or {rank = "missing"}).rank), "nil")

	-- buildLinks ---------------------------------------------------------------------
	local mapByFile = {["out01.odm"] = 1, ["out02.odm"] = 2, ["out03.odm"] = 4, ["d01.blv"] = 3}
	local links = TrainerHint.buildLinks({
		travels = {
			["out01.odm"] = {up = {map = "Out03.odm"}, down = {map = "Nowhere.odm"}, StraightTravel = false},
			["out99.odm"] = {left = {map = "out01.odm"}},		-- unknown source file
			["out02.odm"] = {right = {map = "out02.odm"}},		-- itself
		},
		routes = {
			{from = 1, to = {2, 4, 1, -1}},
			{from = 2, to = {1}},
			{from = 7, to = {}},
		},
		mapByFile = function(file) return mapByFile[file] end,
	})
	eq("links: walk wins over a route to the same map", links[1] and links[1][4], "walk")
	eq("links: route", links[1] and links[1][2], "route")
	eq("links: not to itself", links[1] and links[1][1], nil)
	eq("links: unknown target file ignored", links[1] and links[1][0], nil)
	eq("links: routes are one-way", links[2] and links[2][1], "route")
	eq("links: unknown source file ignored", links[4], nil)
	eq("links: no data at all", next(TrainerHint.buildLinks({mapByFile = function() end})), nil)
	eq("links: nothing given", next(TrainerHint.buildLinks(nil)), nil)

	-- neighbours --------------------------------------------------------------------
	local nl = {[1] = {[2] = "route", [5] = "walk"}, [3] = {[2] = "walk", [6] = "route"}}
	eq("neighbours: party map only", TrainerHint.neighbours(nl, 1), nl[1])
	eq("neighbours: indoor map without links uses the reference map", TrainerHint.neighbours(nl, 9, 3), nl[3])
	eq("neighbours: both merged, walking wins", (function()
		local n = TrainerHint.neighbours(nl, 1, 3)
		return table.concat({n[2], n[5], n[6]}, ",")
	end)(), "walk,walk,route")
	eq("neighbours: merging leaves the links alone", nl[1][2], "route")
	eq("neighbours: none", TrainerHint.neighbours(nl, 9, 8), nil)
	eq("neighbours: no links", TrainerHint.neighbours(nil, 1, 3), nil)

	-- compose: exact texts -------------------------------------------------------
	local jasp = {name = "Jasp Hunter", houseName = "Hunter's Hovel", mapName = "Ravenshore", cont = 1, rank = 0}
	local dalin = {name = "Dalin Keenedge", houseName = "Keenedge Residence", mapName = "The Pit", cont = 2, rank = 2}
	local rexella = {name = "Rexella", mapName = "Paradise Valley", cont = 3, rank = 2}
	local nearby = {name = "Zed", mapName = "Harmondale", cont = 2, rank = 1}
	eq("compose trainers", TrainerHint.compose({kind = "trainers", nextName = "Master", need = 7, have = 3,
			curCont = 1, trainers = {jasp, dalin}}, plain),
		"Next mastery: Master (skill 7 required)\n Jasp Hunter - Hunter's Hovel, Ravenshore (this map)\n"
		.. " Dalin Keenedge - Keenedge Residence, The Pit (Antagarich)")
	eq("compose trainers without house name", TrainerHint.compose({kind = "trainers", nextName = "Master",
			need = 7, have = 3, curCont = 1, trainers = {rexella}}, plain),
		"Next mastery: Master (skill 7 required)\n Rexella - Paradise Valley (Enroth)")
	eq("compose same continent shows no suffix", TrainerHint.compose({kind = "trainers", nextName = "Expert",
			need = 4, have = 4, curCont = 2, trainers = {nearby}}, plain),
		"Next mastery: Expert (skill 4 required)\n Zed - Harmondale")
	eq("compose unknown current continent shows every continent", TrainerHint.compose({kind = "trainers",
			nextName = "Expert", need = 4, have = 4, trainers = {nearby}}, plain),
		"Next mastery: Expert (skill 4 required)\n Zed - Harmondale (Antagarich)")
	eq("compose neighbour labels", TrainerHint.compose({kind = "trainers", nextName = "Master", need = 7, have = 7,
			curCont = 1, trainers = {
				{name = "A", mapName = "M1", cont = 1, rank = 1, link = "walk"}}}, plain),
		"Next mastery: Master (skill 7 required)\n A - M1 (next map)")
	eq("compose route label", TrainerHint.compose({kind = "trainers", nextName = "Master", need = 7, have = 7,
			curCont = 1, trainers = {{name = "A", mapName = "M1", cont = 1, rank = 1, link = "route"}}}, plain),
		"Next mastery: Master (skill 7 required)\n A - M1 (coach/boat)")
	eq("compose route to another continent", TrainerHint.compose({kind = "trainers", nextName = "Master", need = 7,
			have = 7, curCont = 1, trainers = {{name = "A", mapName = "M1", cont = 2, rank = 1, link = "route"}}}, plain),
		"Next mastery: Master (skill 7 required)\n A - M1 (coach/boat, Antagarich)")
	eq("compose outside label", TrainerHint.compose({kind = "trainers", nextName = "Master", need = 7, have = 7,
			curCont = 1, trainers = {{name = "A", mapName = "M1", cont = 1, rank = 0, outside = true}}}, plain),
		"Next mastery: Master (skill 7 required)\n A - M1 (outside)")
	eq("compose none", TrainerHint.compose({kind = "none", nextName = "Grand Master"}, plain),
		"Next mastery: Grand Master\n No trainer found.")
	eq("compose trainers with an empty list is none", TrainerHint.compose({kind = "trainers",
			nextName = "Grand Master", need = 10, have = 3, trainers = {}}, plain),
		"Next mastery: Grand Master\n No trainer found.")
	eq("compose auto", TrainerHint.compose({kind = "auto", nextName = "Master", need = 12}, plain),
		"Next mastery: Master\n Learned automatically at skill 12.")
	eq("compose max", TrainerHint.compose({kind = "max"}, plain),
		"Highest mastery for this class reached.")
	eq("compose promotion with trainers", TrainerHint.compose({kind = "promotion", nextName = "Master",
			need = 7, have = 7, curCont = 1, trainers = {jasp}}, plain),
		"Next mastery: Master (skill 7 required)\n Requires a class promotion first.\n"
		.. " Jasp Hunter - Hunter's Hovel, Ravenshore (this map)")
	eq("compose promotion without trainers", TrainerHint.compose({kind = "promotion", nextName = "Master",
			need = 7, have = 3, trainers = {}}, plain),
		"Next mastery: Master (skill 7 required)\n Requires a class promotion first.\n No trainer found.")
	eq("compose promotion, no trainer list (skills that are learned automatically)", TrainerHint.compose({
			kind = "promotion", nextName = "Master", need = 12, have = 14}, plain),
		"Next mastery: Master (skill 12 required)\n Requires a class promotion first.")
	eq("compose grand master reached", TrainerHint.compose({kind = "grandmaster"}, plain), "Grand Master reached.")
	eq("compose unknown kind",TrainerHint.compose({kind = "bogus"}, plain), nil)
	eq("compose nil", TrainerHint.compose(nil, plain), nil)

	-- compose: colours ---------------------------------------------------------------
	eq("compose colours, requirement not met", TrainerHint.compose({kind = "trainers", nextName = "Master",
			need = 7, have = 3, curCont = 1, trainers = {jasp, dalin}}, tag),
		"<255,255,100:Next mastery: Master (skill ><255,0,0:7><255,255,100: required)>\n"
		.. " Jasp Hunter - Hunter's Hovel, Ravenshore <0,255,0:(this map)>\n"
		.. " Dalin Keenedge - Keenedge Residence, The Pit (Antagarich)")
	eq("compose colours, requirement met", TrainerHint.compose({kind = "trainers", nextName = "Master",
			need = 7, have = 9, curCont = 1, trainers = {dalin}}, tag),
		"<255,255,100:Next mastery: Master (skill ><0,255,0:7><255,255,100: required)>\n"
		.. " Dalin Keenedge - Keenedge Residence, The Pit (Antagarich)")
	eq("compose colours, grand master", TrainerHint.compose({kind = "grandmaster"}, tag),
		"<255,255,100:Grand Master reached.>")
	eq("compose colours, special lines", TrainerHint.compose({kind = "max"}, tag),
		"<255,255,100:Highest mastery for this class reached.>")

	return #errors == 0 and "ok" or table.concat(errors, "\n")
end

------------------------------------------------------------------------
-- Game adapter: reads the live engine data, caches the index and the map
-- links until the next map load (a quest MoveNPC, hiring or a route's quest
-- bit without a map change shows up only then -- known and accepted).
------------------------------------------------------------------------

local MASTERY_NAMES = {[2] = "Expert", [3] = "Master", [4] = "Grand Master"}
local MAX_MASTERY = 4			-- SplitSkill reports nothing above Grand Master
local CHARACTER_CREATION = 21	-- Game.CurrentScreen while the party is built: no map yet
local HOUSE_STABLES, HOUSE_BOATS = 27, 28	-- Game.Houses[i].Type

local cache, links, mapByFile
local builtMs

local function contains(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end
	return false
end

-- the engine arrays raise on a bad index: wrap each lookup, a house or map the
-- tables don't know is simply left out
local function gameSource()
	local npcs = {}
	for i = 0, Game.NPC.High do
		local npc = Game.NPC[i]
		local events = {}
		for e = 0, 5 do
			events[#events + 1] = npc.Events[e]
		end
		npcs[#npcs + 1] = {id = i, name = npc.Name, house = npc.House, events = events}
	end
	return {
		npcs = npcs,
		topics = Game.TeacherTopics or {},
		-- zzMAW_MoveTrainers.lua moves teachers only while enableAllTrainers is on
		moves = enableAllTrainers and MawTrainerMoves or nil,
		houseMap = function(house)
			local ok, map = pcall(function() return Game.HousesExtra[house].Map end)
			if ok and map and map > 0 then
				return map
			end
		end,
		mapInfo = function(map)
			local ok, info = pcall(function()
				local stats = Game.MapStats[map]
				return {name = stats.Name, file = stats.FileName}
			end)
			if not ok then
				return nil
			end
			local contOk, cont = pcall(TownPortalControls.MapOfContinent, map)
			info.cont = contOk and cont or nil
			return info
		end,
		houseName = function(house)
			local ok, name = pcall(function() return Game.Houses[house].Name end)
			return ok and name or nil
		end,
	}
end

-- map index by lower-case file name (Game.MapStats does not change in a game)
local function mapIndexByFile()
	if not mapByFile then
		mapByFile = {}
		for i, stats in Game.MapStats do
			local file = stats.FileName
			if type(file) == "string" and file ~= "" and not mapByFile[file:lower()] then
				mapByFile[file:lower()] = i
			end
		end
	end
	return mapByFile
end

-- src for buildLinks. A coach or boat house reads its row of Game.TransportIndex:
-- row = its place among the stables (IndexByType - 1), the boats come after all
-- stables (the layout RemoveHouseRulesLimits.lua gives the table from "House
-- rules.txt"). A row holds up to four Game.TransportLocations (-1 = none); a
-- location that needs a quest bit counts only once the bit is set.
local function linkSource()
	local houses, stables = {}, 0
	for i, house in Game.Houses do
		local kind = house.Type
		if kind == HOUSE_STABLES or kind == HOUSE_BOATS then
			local ok, nth, map = pcall(function()
				local extra = Game.HousesExtra[i]
				return extra.IndexByType, extra.Map
			end)
			if ok and nth and nth > 0 then
				houses[#houses + 1] = {kind = kind, nth = nth, map = map}
				if kind == HOUSE_STABLES then
					stables = math.max(stables, nth)
				end
			end
		end
	end

	local routes = {}
	for _, h in ipairs(houses) do
		if h.map and h.map > 0 then
			local row = (h.kind == HOUSE_BOATS and stables or 0) + h.nth - 1
			local to = {}
			for slot = 1, 4 do
				local ok, map = pcall(function()
					local loc = Game.TransportIndex[row][slot]
					if loc < 0 then
						return nil
					end
					local tran = Game.TransportLocations[loc]
					if tran.QBit ~= 0 and not Party.QBits[tran.QBit] then
						return nil
					end
					return tran.MapIndex
				end)
				if ok and map then
					to[#to + 1] = map
				end
			end
			routes[#routes + 1] = {from = h.map, to = to}
		end
	end

	local byFile = mapIndexByFile()
	return {
		travels = Game.OutdoorTravels,	-- MMMerge's 2_OutdoorTravels.lua
		routes = routes,
		mapByFile = function(file)
			return byFile[file]
		end,
	}
end

local function getIndex()
	if not cache then
		local t0 = os.clock()
		cache = TrainerHint.buildIndex(gameSource())
		builtMs = (os.clock() - t0) * 1000
	end
	return cache
end

local function getLinks()
	if not links then
		links = TrainerHint.buildLinks(linkSource())
	end
	return links
end

-- in an indoor map: the outdoor map the party came from (vars.LastOutdoorMap,
-- kept by MMMerge's 2_OutdoorTravels.lua); nil outdoors or when unknown
local function referenceMap()
	local ok, outdoor = pcall(Map.IsOutdoor)
	if not ok or outdoor then
		return nil
	end
	local file = vars.LastOutdoorMap
	return type(file) == "string" and mapIndexByFile()[file:lower()] or nil
end

function TrainerHint.invalidate()
	cache = nil
	links = nil
end

-- block, reason: the hint block for (pl, skillId), or nil and why there is none.
-- Errors are not caught here; SkillTooltip isolates them.
function TrainerHint.explain(pl, skillId)
	if not (MawTrainerHintsEnabled and MawTrainerHintsEnabled()) then
		return nil, "option off"
	end
	if Game.CurrentScreen == CHARACTER_CREATION then
		return nil, "character creation screen"
	end
	-- SplitSkill reports mastery 1 for every value >= 1, so skill 0 is its own test
	local s, m = SplitSkill(Skillz.get(pl, skillId))
	if not s or s == 0 then
		return nil, "skill not learned"
	end
	if m + 1 > MAX_MASTERY then
		-- nothing left to learn: say so, but only for skills that have masteries to learn at all
		if not getIndex()[skillId] and not (skillMasteryLadder and skillMasteryLadder[skillId]) then
			return nil, "nobody teaches this skill"
		end
		return TrainerHint.compose({kind = "grandmaster"})
	end
	local nextM = m + 1
	local info = {
		nextName = MASTERY_NAMES[nextM], have = s,
		need = GetLearningRequirements(skillId)[nextM],
	}
	local function finish()
		local text = TrainerHint.compose(info)
		return text, text == nil and "nothing to say" or nil
	end

	-- a solo party gets these masteries by skill level alone (mawTick_SoloMastery),
	-- whatever the class
	if Party.High == 0 and MawSoloAutoMasterySkills and contains(MawSoloAutoMasterySkills, skillId) then
		info.kind = "auto"
		return finish()
	end

	local topics = getIndex()[skillId]
	local ladder = skillMasteryLadder and skillMasteryLadder[skillId]
	if not topics and not ladder then
		return nil, "nobody teaches this skill"		-- and nothing grants it
	end

	local API = MawCore.Skills.API
	local race = Game.CharacterPortraits[pl.Face].Race
	local reachable = API.MasteryTable_get(race, pl.Class, skillId) >= nextM
	if not reachable and API.MasteryTable_get(race, MawCore.Skills.nextClass(pl.Class), skillId) < nextM then
		info.kind = "max"
		return finish()
	end

	-- same ladder and same rule as autoLearnMastery (zzMAW-Skills.lua)
	local steps = ladder and ((vars.insanityMode and ladder.insanity) or ladder.normal)
	if steps and steps[m] then
		info.need = steps[m]
		info.kind = reachable and "auto" or "promotion"
		return finish()
	end
	if not topics then
		return nil, "no teacher topic for this mastery"
	end

	local curMap = Map.MapStatsIndex
	local contOk, curCont = pcall(TownPortalControls.MapOfContinent, curMap)
	info.curCont = contOk and curCont or nil
	local refMap = referenceMap()
	local neighbors = TrainerHint.neighbours(getLinks(), curMap, refMap)
	-- teacher topics count masteries from Expert = 1, i.e. by the mastery the player has now
	info.trainers = TrainerHint.pick(topics[m] or {}, curMap, info.curCont, nil, neighbors, refMap)
	info.kind = reachable and "trainers" or "promotion"
	return finish()
end

-- the block SkillTooltip appends to the end of the tooltip
function TrainerHint.text(pl, skillId)
	return (TrainerHint.explain(pl, skillId))
end

-- console: print(MawCore.TrainerHint.probe(skillId)) -- why the hint is (not) in the
-- tooltip of this skill for the current character: lengths and outcome
function TrainerHint.probe(skillId)
	local pl = Party[math.max(Game.CurrentPlayer, 0)]
	local _, info = MawCore.SkillTooltip.build(pl, skillId)
	local outcome = info.status
	if info.status == "skipped" then
		outcome = "skipped (too long)"
	elseif info.status == "nil" then
		outcome = "nil (" .. select(2, TrainerHint.explain(pl, skillId)) .. ")"
	elseif info.status == "error" then
		outcome = "error (" .. tostring(info.error) .. ")"
	end
	return ("skill %d: tooltip without hint %d bytes, hint %d bytes, limit %d, %s"):format(
		skillId, info.baseLen, info.hintLen or 0, 4095, outcome)
end

-- console: print(MawCore.TrainerHint.describe()) -- rebuilds the index, so the
-- time shown is a fresh build of the current game data
function TrainerHint.describe()
	TrainerHint.invalidate()
	local index = getIndex()
	local skills, entries = 0, 0
	for _, slots in pairs(index) do
		skills = skills + 1
		for _, list in pairs(slots) do
			entries = entries + #list
		end
	end
	local linked, walks, routes = 0, 0, 0
	for _, to in pairs(getLinks()) do
		linked = linked + 1
		for _, kind in pairs(to) do
			if kind == "walk" then
				walks = walks + 1
			else
				routes = routes + 1
			end
		end
	end
	local refMap = referenceMap()
	return table.concat({
		"trainer hint:",
		"  option: " .. ((MawTrainerHintsEnabled and MawTrainerHintsEnabled()) and "ON" or "OFF"),
		"  moved teachers: " .. ((enableAllTrainers and MawTrainerMoves) and "included" or "not included"),
		("  index: %d skills, %d entries, built in %.1f ms"):format(skills, entries, builtMs),
		("  links: %d maps, %d walking, %d coach/boat"):format(linked, walks, routes),
		"  reference map: " .. (refMap and tostring(refMap) or "none (outdoors or unknown)"),
	}, "\n")
end

-- console: print(MawCore.TrainerHint.dump(skillId, mastery)) -- every entry of
-- one slot (mastery 1 = Expert teachers), unranked
function TrainerHint.dump(skillId, mastery)
	local slot = getIndex()[skillId] and getIndex()[skillId][mastery]
	if not slot then
		return ("skill %d, mastery %d: no teacher topic"):format(skillId, mastery)
	end
	local sorted = {}
	for i, e in ipairs(slot) do
		sorted[i] = e
	end
	table.sort(sorted, function(a, b)
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.house < b.house
	end)
	local out = {("skill %d, mastery %d: %d entries"):format(skillId, mastery, #sorted)}
	for _, e in ipairs(sorted) do
		out[#out + 1] = ("  %s (npc %d) - house %d %s, %s (map %d, continent %s)"):format(
			e.name, e.npc, e.house, e.houseName or "-", e.mapName, e.map, tostring(e.cont))
	end
	return table.concat(out, "\n")
end

-- console: print(MawCore.TrainerHint.travel()) -- where one gets in one step from the
-- party's map, or from map index `map`
function TrainerHint.travel(map)
	map = map or Map.MapStatsIndex
	local function name(i)
		local ok, n = pcall(function() return Game.MapStats[i].Name end)
		return ok and trim(n) or ("map " .. tostring(i))
	end
	local walk, route = {}, {}
	for to, kind in pairs(getLinks()[map] or {}) do
		local list = kind == "walk" and walk or route
		list[#list + 1] = name(to)
	end
	table.sort(walk)
	table.sort(route)
	return table.concat({
		("%s (map %d):"):format(name(map), map),
		"  walking: " .. (#walk > 0 and table.concat(walk, ", ") or "-"),
		"  coach/boat: " .. (#route > 0 and table.concat(route, ", ") or "-"),
	}, "\n")
end

function TrainerHint.start()
	function events.LoadMap()
		TrainerHint.invalidate()
	end
end
