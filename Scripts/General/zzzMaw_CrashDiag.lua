local diagSetting = crashDiagnostics
if diagSetting == false or diagSetting == "off" or diagSetting == "OFF" then
	return
end

local ffi = require("ffi")
local band, lshift = bit.band, bit.lshift
local floor, min, max = math.floor, math.min, math.max
local format, concat = string.format, table.concat
local clock = os.clock
local u4, u2 = mem.u4, mem.u2

local okNew, tnew = pcall(require, "table.new")
if not okNew then
	tnew = function()
		return {}
	end
end

local LOG_PATH = AppPath .. "MawDiag.txt"
local LOG_OLD_PATH = AppPath .. "MawDiag.old.txt"
local LOG_MAX = 3 * 1024 * 1024
local FULL = diagSetting == "full" or diagSetting == "FULL"
local BUDGET = FULL and 0.3 or 0.03
local WORK = FULL and 10000 or 4000
local HEARTBEAT = 60
local TRAIL = 512
local LIST_LIMIT = 4000000
local MAX_ERRORS = 200

local logFile = io.open(LOG_PATH, "a")
if logFile and (logFile:seek("end") or 0) > LOG_MAX then
	logFile:close()
	os.remove(LOG_OLD_PATH)
	os.rename(LOG_PATH, LOG_OLD_PATH)
	logFile = io.open(LOG_PATH, "w")
end
if logFile then
	logFile:setvbuf("no")
end

local function log(s)
	if logFile then
		logFile:write(s, "\n")
	end
end

local function stamp()
	return format("%s +%.1fs", os.date("%H:%M:%S"), clock())
end

local function context()
	local ok, s = pcall(function()
		return format("map %s, game time %s", tostring(Map.Name), tostring(Game.Time))
	end)
	return ok and s or "no map"
end

local trailOn = false
local ring = tnew(TRAIL, 0)
local ringPos = 0
local counts, prevCounts = {}, {}

local function note(k)
	ringPos = ringPos % TRAIL + 1
	ring[ringPos] = k
	counts[k] = (counts[k] or 0) + 1
end

local U32 = ffi.cast("uint32_t*", 0)
local U8 = ffi.cast("uint8_t*", 0)
local IsBadReadPtr
local MS
local heapOn = false
local heapOffReason = "not started"

local function rd(a)
	return U32[a / 4]
end

local segBase, segEnd = tnew(8192, 0), tnew(8192, 0)
local segCount, heapBytes = 0, 0
local pageSeg = tnew(65536, 0)
local pageList = tnew(65536, 0)
local pageListN = 0

local function loadSegments()
	for i = 1, pageListN do
		pageSeg[pageList[i]] = nil
	end
	pageListN, segCount, heapBytes = 0, 0, 0
	local sp = MS + 0x1A8
	while sp ~= 0 do
		if sp % 4 ~= 0 or segCount >= 8192 or IsBadReadPtr(sp, 12) ~= 0 then
			return false
		end
		local base, size = rd(sp), rd(sp + 4)
		if base % 0x10000 ~= 0 or size == 0 or size % 8 ~= 0 or pageListN + size / 0x10000 + 1 > 65536 then
			return false
		end
		segCount = segCount + 1
		segBase[segCount], segEnd[segCount] = base, base + size
		heapBytes = heapBytes + size
		for pg = base / 0x10000, floor((base + size - 1) / 0x10000) do
			pageSeg[pg] = segCount
			pageListN = pageListN + 1
			pageList[pageListN] = pg
		end
		sp = rd(sp + 8)
	end
	return true
end

local function inRange(a, len)
	local s = pageSeg[floor(a / 0x10000)]
	return s ~= nil and a >= segBase[s] and a + len <= segEnd[s]
end

local function okChunk(a)
	return a % 8 == 0 and inRange(a, 32)
end

local failKind, failBin, failA, failB, failV

local function fail(kind, bin, a, b, v)
	failKind, failBin, failA, failB, failV = kind, bin, a, b, v
	return false
end

local function footerOk(c, size)
	local nxt = c + size
	return inRange(nxt, 8) and rd(nxt) == size and band(rd(nxt + 4), 1) == 0
end

local function footerValue(c, size)
	return inRange(c + size, 8) and rd(c + size) or 0
end

local function checkTop()
	local top, topsize = rd(MS + 0x14), rd(MS + 0x0C)
	if not okChunk(top) or band(rd(top + 4), -8) ~= topsize then
		return fail("top chunk does not match its size", -1, top, topsize, okChunk(top) and rd(top + 4) or 0)
	end
	local dv, dvsize = rd(MS + 0x10), rd(MS + 0x08)
	if dvsize ~= 0 and (not okChunk(dv) or band(rd(dv + 4), -8) ~= dvsize) then
		return fail("dv chunk does not match its size", -1, dv, dvsize, okChunk(dv) and rd(dv + 4) or 0)
	end
	return true
end

local function checkSmallBin(i)
	if band(rd(MS), lshift(1, i)) == 0 then
		return true, 0
	end
	local B = MS + 0x20 + i * 8
	local P = rd(B + 8)
	if P == B then
		return fail("small bin is marked but empty", i, B, P, 0), 0
	end
	local size, prev, n = i * 8, B, 0
	while P ~= B do
		if not okChunk(P) then
			return fail("small bin fd points outside the Lua heap", i, prev, P, 0), n
		end
		local bk = rd(P + 12)
		if bk ~= prev then
			return fail("small bin bk does not match", i, P, prev, bk), n
		end
		local head = rd(P + 4)
		if band(head, -8) ~= size or band(head, 2) ~= 0 then
			return fail("small bin chunk header is wrong", i, P, size, head), n
		end
		if not footerOk(P, size) then
			return fail("small bin chunk footer is wrong", i, P, P + size, footerValue(P, size)), n
		end
		prev, P, n = P, rd(P + 8), n + 1
		if n > LIST_LIMIT then
			return fail("small bin list does not end", i, P, prev, n), n
		end
	end
	if rd(B + 12) ~= prev then
		return fail("small bin tail does not match", i, B, prev, rd(B + 12)), n
	end
	return true, n
end

local stack = tnew(1024, 0)

local function checkTreeBin(i)
	local treemap = rd(MS + 4)
	if band(treemap, lshift(1, i)) == 0 then
		return true, 0
	end
	local slot = MS + 0x128 + i * 4
	local root = rd(slot)
	if root == 0 then
		return fail("tree bin is marked but empty", i, slot, 0, treemap), 0
	end
	if not okChunk(root) then
		return fail("tree bin root points outside the Lua heap", i, slot, root, 0), 0
	end
	if rd(root + 24) ~= slot then
		return fail("tree root parent does not match", i, root, slot, rd(root + 24)), 0
	end
	local total = 0
	local sp = 1
	stack[1] = root
	while sp > 0 do
		local T = stack[sp]
		sp = sp - 1
		local head = rd(T + 4)
		local size = band(head, -8)
		if size < 256 or band(head, 2) ~= 0 then
			return fail("tree chunk header is wrong", i, T, 0, head), total
		end
		local U, n = T, 0
		repeat
			if rd(U + 28) ~= i then
				return fail("tree chunk index is wrong", i, U, T, rd(U + 28)), total
			end
			if U ~= T then
				local h = rd(U + 4)
				if band(h, -8) ~= size or band(h, 2) ~= 0 then
					return fail("tree list chunk header is wrong", i, U, T, h), total
				end
				if rd(U + 24) ~= 0 or rd(U + 16) ~= 0 or rd(U + 20) ~= 0 then
					return fail("tree list chunk has tree links", i, U, T, rd(U + 24)), total
				end
			end
			if not footerOk(U, size) then
				return fail("tree chunk footer is wrong", i, U, U + size, footerValue(U, size)), total
			end
			local F = rd(U + 8)
			if not okChunk(F) then
				return fail("tree list fd points outside the Lua heap", i, U, F, 0), total
			end
			if rd(F + 12) ~= U then
				return fail("tree list fd->bk does not match", i, U, F, rd(F + 12)), total
			end
			U, n = F, n + 1
			if n > LIST_LIMIT then
				return fail("tree list does not end", i, U, T, n), total
			end
		until U == T
		total = total + n
		local C0, C1 = rd(T + 16), rd(T + 20)
		if C0 ~= 0 then
			if not okChunk(C0) or rd(C0 + 24) ~= T then
				return fail("tree child 0 is wrong", i, T, C0, okChunk(C0) and rd(C0 + 24) or 0), total
			end
			sp = sp + 1
			stack[sp] = C0
		end
		if C1 ~= 0 then
			if not okChunk(C1) or rd(C1 + 24) ~= T then
				return fail("tree child 1 is wrong", i, T, C1, okChunk(C1) and rd(C1 + 24) or 0), total
			end
			sp = sp + 1
			stack[sp] = C1
		end
		if sp > 1000 then
			return fail("tree is too deep", i, T, 0, sp), total
		end
	end
	return true, total
end

local binCursor = 0
local cycleChunks, lastCycleChunks = 0, 0

local function walkBatch(work)
	failKind = nil
	if not loadSegments() then
		return nil
	end
	if not checkTop() then
		return false
	end
	local done = 0
	repeat
		local ok, n
		if binCursor < 32 then
			ok, n = checkSmallBin(binCursor)
		else
			ok, n = checkTreeBin(binCursor - 32)
		end
		if not ok then
			return false
		end
		done = done + n + 1
		cycleChunks = cycleChunks + n
		binCursor = binCursor + 1
		if binCursor == 64 then
			binCursor = 0
			lastCycleChunks, cycleChunks = cycleChunks, 0
			return true, true
		end
	until done >= work
	return true, false
end

local GC_TYPES = {[4] = "string", [5] = "upvalue", [6] = "thread", [7] = "prototype", [8] = "function", [9] = "trace", [10] = "cdata", [11] = "table", [12] = "userdata"}

local function dump(a, len)
	a = a - a % 16
	for row = a, a + len - 1, 16 do
		if inRange(row, 16) then
			local chars = {}
			for k = 0, 15 do
				local c = U8[row + k]
				chars[k + 1] = (c >= 32 and c < 127) and string.char(c) or "."
			end
			log(format("    %08X: %08X %08X %08X %08X  %s", row, rd(row), rd(row + 4), rd(row + 8), rd(row + 12), concat(chars)))
		else
			log(format("    %08X: (outside the Lua heap)", row))
		end
	end
end

local function describe(label, c)
	if not inRange(c, 8) then
		log(format("  %s %08X: outside the Lua heap", label, c))
		return 0
	end
	local head = rd(c + 4)
	local size = band(head, -8)
	local used = band(head, 2) ~= 0
	local kind = used and inRange(c + 16, 1) and GC_TYPES[U8[c + 13]]
	log(format("  %s %08X: size %d, %s%s (prev_foot %08X, head %08X)", label, c, size, used and "in use" or "free", kind and ", looks like a Lua " .. kind or "", rd(c), head))
	dump(c, min(max(size, 32), 192) + 16)
	return size
end

local function findPrev(target)
	local s = pageSeg[floor(target / 0x10000)]
	if not s then
		return nil, "chunk is outside the known segments"
	end
	local c, prev, n = segBase[s], nil, 0
	while c < target do
		if not inRange(c, 8) then
			return prev, "segment walk left the segment"
		end
		local size = band(rd(c + 4), -8)
		if size <= 0 then
			return prev, format("segment walk hit a zero-size chunk at %08X", c)
		end
		prev, c, n = c, c + size, n + 1
		if n > 8000000 then
			return prev, "segment walk too long"
		end
	end
	if c ~= target then
		return prev, format("segment walk did not land on the chunk: chunk %08X spans over it", prev or 0)
	end
	return prev
end

local function scanExe(lo, hi)
	local base = 0x400000
	local pe = base + u4[base + 0x3C]
	local sections = pe + 24 + u2[pe + 20]
	local hits = 0
	for k = 0, u2[pe + 6] - 1 do
		local h = sections + k * 40
		if band(u4[h + 36], 0x80000000) ~= 0 then
			local a, stop = base + u4[h + 12], base + u4[h + 12] + u4[h + 8]
			while a < stop do
				local pageEnd = min(stop, a - a % 4096 + 4096)
				if IsBadReadPtr(a, pageEnd - a) == 0 then
					for p = a, pageEnd - 4, 4 do
						local v = rd(p)
						if v >= lo and v < hi then
							hits = hits + 1
							log(format("    [%08X] = %08X", p, v))
							if hits >= 32 then
								return hits
							end
						end
					end
				end
				a = pageEnd
			end
		end
	end
	return hits
end

local function entryName(k)
	return type(k) == "number" and format("hook %06X", k) or tostring(k)
end

local function trailReport()
	local merged, keys = {}, {}
	for _, t in ipairs({prevCounts, counts}) do
		for k, n in pairs(t) do
			if n > 0 then
				if not merged[k] then
					keys[#keys + 1] = k
				end
				merged[k] = (merged[k] or 0) + n
			end
		end
	end
	table.sort(keys, function(a, b)
		return merged[a] > merged[b]
	end)
	log(format("  activity during the last full check cycle and after it (%d different hooks/events):", #keys))
	for i = 1, min(#keys, 150) do
		log(format("    %8d  %s", merged[keys[i]], entryName(keys[i])))
	end
	log("  last hooks/events, oldest first:")
	local line, last, rep = {}, nil, 0
	local function flush()
		if last ~= nil then
			line[#line + 1] = rep > 1 and format("%s x%d", entryName(last), rep) or entryName(last)
			if #line >= 6 then
				log("    " .. concat(line, ", "))
				line = {}
			end
		end
	end
	for j = 1, TRAIL do
		local k = ring[(ringPos + j - 1) % TRAIL + 1]
		if k ~= nil then
			if k == last then
				rep = rep + 1
			else
				flush()
				last, rep = k, 1
			end
		end
	end
	flush()
	if #line > 0 then
		log("    " .. concat(line, ", "))
	end
end

local cyclesDone, batches, skipped, batchTime, batchMax, lastClean, cycleStart, lastCycleTime = 0, 0, 0, 0, 0, 0, 0, 0

local function reportCorruption()
	log("")
	log(format("[%s] !!! LUA HEAP CORRUPTION DETECTED (%s)", stamp(), context()))
	log(format("  problem: %s, bin %d, A %08X, B %08X, value %08X", failKind, failBin, failA or 0, failB or 0, failV or 0))
	if cyclesDone == 0 then
		log("  found before the first full check cycle ended: this can also mean the checker misreads this lua51.dll")
	end
	log(format("  last full clean cycle ended %.3fs before, %d clean cycles this session, a cycle takes %.2fs", clock() - lastClean, cyclesDone, lastCycleTime))
	local sizeA = describe("chunk A", failA)
	if failB and failB ~= 0 and failB ~= failA then
		describe("chunk B", failB)
	end
	local prev, why = findPrev(failA)
	if prev then
		describe("chunk before A", prev)
	end
	if why then
		log("  " .. why)
	end
	if sizeA > 0 then
		describe("chunk after A", failA + sizeA)
	end
	log("  pointers into chunk A found in mm8.exe memory:")
	if scanExe(failA, failA + max(sizeA, 32) + 8) == 0 then
		log("    none")
	end
	trailReport()
	log(format("  %d segments, %.1f MB heap, lua %.1f MB", segCount, heapBytes / 1048576, collectgarbage("count") / 1024))
	log("")
end

local function heapStats()
	if not heapOn and batches == 0 then
		return "heap checker off: " .. heapOffReason
	end
	return format("heap cycles %d (%.2fs each, %d free chunks), batches %d (skipped %d, avg %.2f ms, max %.1f ms), %d segments, %.1f MB heap, lua %.1f MB%s",
		cyclesDone, lastCycleTime, lastCycleChunks, batches, skipped, batches > 0 and batchTime / batches * 1000 or 0, batchMax * 1000,
		segCount, heapBytes / 1048576, collectgarbage("count") / 1024,
		heapOn and "" or ", checker stopped: " .. heapOffReason)
end

if jit then
	for _, f in ipairs({rd, inRange, okChunk, fail, footerOk, footerValue, loadSegments, checkTop, checkSmallBin, checkTreeBin, walkBatch, dump, describe, findPrev, scanExe}) do
		jit.off(f)
	end
end

local nextCheck, nextBeat = 0, 0
local tickDead = false

local function tick()
	local now = clock()
	if heapOn and now >= nextCheck then
		local res, cycled = walkBatch(WORK)
		local done = clock()
		local cost = done - now
		if res == false then
			heapOn = false
			heapOffReason = "corruption found"
			collectgarbage("stop")
			local ok, err = pcall(reportCorruption)
			collectgarbage("restart")
			if not ok then
				log("  report failed: " .. tostring(err))
			end
			pcall(Game.ShowStatusText, "Maw: memory corruption detected, please send MawDiag.txt")
		elseif res then
			batches = batches + 1
			batchTime = batchTime + cost
			batchMax = max(batchMax, cost)
			if cycled then
				cyclesDone = cyclesDone + 1
				lastCycleTime = done - cycleStart
				cycleStart, lastClean = done, done
				prevCounts, counts = counts, prevCounts
				for k in pairs(counts) do
					counts[k] = 0
				end
			end
		else
			skipped = skipped + 1
		end
		nextCheck = done + max(cost, 0.0005) / BUDGET
	end
	if now >= nextBeat then
		nextBeat = now + HEARTBEAT
		log(format("[%s] alive (%s) | %s", stamp(), context(), heapStats()))
	end
end

function events.Tick()
	if tickDead then
		return
	end
	local ok, err = pcall(tick)
	if not ok then
		tickDead = true
		heapOn = false
		heapOffReason = "diagnostics error"
		log(format("[%s] diagnostics stopped by an error: %s", stamp(), tostring(err)))
	end
end

local function initHeap()
	pcall(ffi.cdef, "int __stdcall IsBadReadPtr(uintptr_t lp, uintptr_t ucb);")
	local ok, f = pcall(function()
		return ffi.C.IsBadReadPtr
	end)
	if not ok or not pcall(f, 0, 4) then
		return "IsBadReadPtr not available"
	end
	IsBadReadPtr = f
	local L = tonumber(tostring(coroutine.create(function() end)):match("0x(%x+)") or "", 16)
	if not L or L % 8 ~= 0 or IsBadReadPtr(L, 12) ~= 0 then
		return "thread address not readable"
	end
	local g = rd(L + 8)
	if g % 4 ~= 0 or IsBadReadPtr(g, 0x44) ~= 0 then
		return "global state not readable"
	end
	for off = 0, 0x40, 4 do
		local v = rd(g + off)
		if v % 0x10000 == 8 and IsBadReadPtr(v - 8, 0x1C0) == 0 and rd(v - 4) == 0x1C3 then
			MS = v
			break
		end
	end
	if not MS then
		return "allocator state not found"
	end
	if not loadSegments() or not inRange(MS - 8, 0x1C0) then
		MS = nil
		return "heap segments not readable"
	end
end

local guardHits, guardUnique = 0, 0
local guardSeen = {}

local function luaHeapWrite(p, size)
	guardHits = guardHits + 1
	if guardHits > 500 or not loadSegments() or not inRange(p, 1) then
		return
	end
	local tb = debug.traceback("", 2)
	if guardSeen[tb] then
		return
	end
	guardSeen[tb] = true
	guardUnique = guardUnique + 1
	if guardUnique > 30 then
		return
	end
	if trailOn then
		note("LUA WRITE INTO LUA HEAP")
	end
	log(format("[%s] LUA CODE WROTE INTO LUA HEAP MEMORY at %08X, %d bytes (%s)%s", stamp(), p, size, context(), tb))
end

local function installWriteGuard()
	local prev = internal.mem_ptr_callback
	internal.mem_ptr_callback = function(p, size)
		local s = pageSeg[floor(p / 0x10000)]
		if s and p < segEnd[s] and p + size > segBase[s] then
			pcall(luaHeapWrite, p, size)
		end
		if prev then
			return prev(p, size)
		end
	end
	internal.UpdateCallbacks()
end

local function installTrail()
	for _, name in ipairs({"call", "Call", "cocall", "cocalls", "pcall", "pcalls"}) do
		local orig = rawget(events, name)
		if type(orig) == "function" then
			rawset(events, name, function(a, ...)
				if a ~= nil then
					note(a)
				end
				return orig(a, ...)
			end)
		end
	end
	local hooks = mem.hooks
	local wrapped = setmetatable({}, {__mode = "k"})
	local function wrap(p, f)
		if type(f) ~= "function" or wrapped[f] then
			return f
		end
		local w = function(d)
			note(p)
			return f(d)
		end
		wrapped[w] = true
		return w
	end
	for p, f in pairs(hooks) do
		hooks[p] = wrap(p, f)
	end
	if getmetatable(hooks) == nil then
		setmetatable(hooks, {__newindex = function(t, p, f)
			rawset(t, p, wrap(p, f))
		end})
	end
	trailOn = true
end

local errorsLogged = 0
local prevOnError = internal.OnError
internal.OnError = function(msg)
	errorsLogged = errorsLogged + 1
	if errorsLogged <= MAX_ERRORS then
		pcall(function()
			if trailOn then
				note("LUA ERROR")
			end
			log(format("[%s] LUA ERROR (%s)\n%s", stamp(), context(), tostring(msg)))
			if errorsLogged == MAX_ERRORS then
				log("  (further Lua errors are not logged in this session)")
			end
		end)
	end
	if prevOnError then
		return prevOnError(msg)
	end
end

local function fileDate(st)
	local t = (st.LastWriteTimeHigh * 4294967296 + st.LastWriteTimeLow) / 1e7 - 11644473600
	return os.date("%Y-%m-%d", floor(t))
end

local function listFiles(label, pattern, withDate)
	local parts = {}
	for f, st in path.find(pattern) do
		if band(st.FileAttributes, 0x10) == 0 then
			local name = f:match("[^\\/]+$") or f
			parts[#parts + 1] = withDate and format("%s %d %s", name, st.FileSizeLow, fileDate(st)) or format("%s %d", name, st.FileSizeLow)
		end
	end
	table.sort(parts)
	local line = format("  %s (%d):", label, #parts)
	for _, p in ipairs(parts) do
		if #line + #p > 200 then
			log(line)
			line = "     "
		end
		line = line .. " " .. p .. ";"
	end
	log(line)
end

local function gitHead()
	local f = io.open(DevPath .. ".git\\HEAD")
	if not f then
		return "no .git folder"
	end
	local head = f:read("*l") or ""
	f:close()
	local ref = head:match("^ref: (.+)$")
	if not ref then
		return head
	end
	local rf = io.open(DevPath .. ".git\\" .. ref:gsub("/", "\\"))
	if rf then
		local commit = rf:read("*l")
		rf:close()
		return ref .. " " .. tostring(commit)
	end
	local pf = io.open(DevPath .. ".git\\packed-refs")
	if pf then
		for line in pf:lines() do
			local commit, name = line:match("^(%x+) (.+)$")
			if name == ref then
				pf:close()
				return ref .. " " .. commit
			end
		end
		pf:close()
	end
	return ref
end

local function writeHeader()
	log("")
	log("==========================================================================")
	log(format("[%s] Maw diagnostics, session started %s, mode %s", stamp(), os.date("%Y-%m-%d"), FULL and "full" or "normal"))
	log(format("  %s, jit %s, compat layer %s", jit and jit.version or _VERSION, jit and tostring((jit.status())) or "-", os.getenv("__COMPAT_LAYER") or "none"))
	log("  git " .. gitHead())
	listFiles("game folder exe", AppPath .. "*.exe", true)
	listFiles("game folder dll", AppPath .. "*.dll", true)
	listFiles("ExeMods", AppPath .. "ExeMods\\*.dll", true)
	listFiles("ExeMods\\MMExtension", AppPath .. "ExeMods\\MMExtension\\*.dll", true)
	listFiles("Scripts\\Core", DevPath .. "Scripts\\Core\\*.lua")
	listFiles("Scripts\\Structs", DevPath .. "Scripts\\Structs\\*.lua")
	listFiles("Scripts\\Structs\\After", DevPath .. "Scripts\\Structs\\After\\*.lua")
	listFiles("Scripts\\General", DevPath .. "Scripts\\General\\*.lua")
	listFiles("Scripts\\Global", DevPath .. "Scripts\\Global\\*.lua")
	listFiles("Scripts\\Modules", DevPath .. "Scripts\\Modules\\*.lua")
	listFiles("Scripts\\Modules\\MawCore", DevPath .. "Scripts\\Modules\\MawCore\\*.lua")
end

local okHeader, headerErr = pcall(writeHeader)
if not okHeader then
	log("  header failed: " .. tostring(headerErr))
end

local okInit, initErr = pcall(initHeap)
if not okInit or initErr then
	heapOffReason = tostring(initErr)
	MS = nil
	log("  heap checker off: " .. heapOffReason)
else
	heapOn = true
	cycleStart = clock()
	local okGuard, guardErr = pcall(installWriteGuard)
	local okTrail, trailErr = pcall(installTrail)
	log(format("  heap checker on: allocator %08X, %d segments, %.1f MB, budget %d%% | write guard %s | trail %s",
		MS, segCount, heapBytes / 1048576, BUDGET * 100,
		okGuard and "on" or "off (" .. tostring(guardErr) .. ")", okTrail and "on" or "off (" .. tostring(trailErr) .. ")"))
end

function events.GameInitialized2()
	log(format("[%s] game initialized, multiplayer %s", stamp(), tostring(Multiplayer and Multiplayer.VERSION)))
end

function events.LoadMap()
	log(format("[%s] LoadMap (%s) | %s", stamp(), context(), heapStats()))
end

function events.LeaveMap()
	log(format("[%s] LeaveMap (%s)", stamp(), context()))
end
