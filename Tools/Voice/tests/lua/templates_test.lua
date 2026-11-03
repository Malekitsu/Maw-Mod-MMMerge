-- Template check: zzzMaw_NPCVoices.lua finds the recording of every text with filled-in placeholders.
-- args: module path, scratch app directory (its Data\Voices\templates.tsv is read),
--       cases file (lines "<hex of the shown text> <recording key>", from run_lua_tests.py)
local modulePath, appDir, casesPath = ...

bit = require("bit")
AppPath = appDir
mem = {StaticAlloc = function() return 0 end, r4 = {}, u4 = {}, dll = {}}
events = setmetatable({}, {__newindex = function() end})
Game = {}
dofile(modulePath)

local n, fails = 0, {}
local function expect(what, text, want)
	n = n + 1
	local got = MawVoices.TemplateKey(text)
	if got ~= want then
		fails[#fails + 1] = ("%s: want %s got %s for %q"):format(what, tostring(want), tostring(got), text:sub(1, 70))
	end
end

for line in io.lines(casesPath) do
	local hex, want = line:match("^(%x*) (%S+)$")
	local text = hex:gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end)
	expect("plain", text, want)
	-- the hire dialog puts a note in brackets after the pitch
	expect("with note", text .. "\n(Unlimited weapon repair. Tracie takes 2 percent of all gold you find. Click again to hire Tracie.)", want)
	local spaced = text:upper():gsub(" ", "   ")
	expect("quotes, case, spacing", '"' .. spaced .. '"\r\n', want)
end

expect("an ordinary text", "Welcome to Dagger Wound Island.", nil)
expect("empty", "", nil)

if n == 0 then
	return "FAIL no cases"
elseif #fails > 0 then
	return ("FAIL %d of %d checks differ, first: %s"):format(#fails, n, fails[1])
end
return ("OK %d checks"):format(n)
