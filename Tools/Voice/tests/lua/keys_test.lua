-- Key check: zzzMaw_NPCVoices.lua computes the same key as extract_texts.py.
-- args: module path, cases file (lines "<hex of text bytes> <key>", from run_lua_tests.py)
local modulePath, casesPath = ...

bit = require("bit")
AppPath = ""
mem = {StaticAlloc = function() return 0 end, r4 = {}, u4 = {}, dll = {}}
events = setmetatable({}, {__newindex = function() end})
Game = {}
dofile(modulePath)

local n, fails = 0, {}
for line in io.lines(casesPath) do
	local hex, want = line:match("^(%x*) (%x+)$")
	local text = hex:gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end)
	local got = MawVoices.Key(text)
	n = n + 1
	if got ~= want then
		fails[#fails + 1] = ("want %s got %s for %q"):format(want, got, text:sub(1, 60))
	end
end

if n == 0 then
	return "FAIL no cases"
elseif #fails > 0 then
	return ("FAIL %d of %d cases differ, first: %s"):format(#fails, n, fails[1])
end
return ("OK %d cases, jit=%s"):format(n, tostring(jit and jit.version))
