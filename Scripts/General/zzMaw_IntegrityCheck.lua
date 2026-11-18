local MANIFEST = "MAW_Manifest.txt"
local REPORT = "MAW_IntegrityReport.txt"
local SHOWN = 15
local DIRECTORY = 0x10

local function rootFor(p)
	if p:lower():sub(1, 8) == "scripts/" then
		return DevPath or AppPath or ""
	end
	return AppPath or ""
end

local function readManifest()
	local f = io.open((DevPath or AppPath or "") .. MANIFEST, "rb")
	if not f then
		return nil
	end
	local sections, current = {maw = {}, base = {}}
	for line in f:lines() do
		line = line:gsub("\r$", "")
		local name = line:match("^%[(%a+)%]$")
		if name then
			current = sections[name]
		elseif current and line ~= "" and line:sub(1, 1) ~= "#" then
			current[#current + 1] = line
		end
	end
	f:close()
	return sections
end

local function normalize(p)
	return (p:gsub("\\", "/"):lower())
end

local function exists(p)
	local f = io.open(rootFor(p) .. p, "rb")
	if f then
		f:close()
		return true
	end
	return false
end

local function collect(dir, suffix, recursive, out)
	local root = rootFor(dir)
	local seen = {}
	local function visit(p, info)
		local name = p:match("[^/\\]+$") or p
		if name == "." or name == ".." or seen[name] then
			return
		end
		seen[name] = true
		if bit.band(info.FileAttributes, DIRECTORY) ~= 0 then
			if recursive then
				collect(dir .. name .. "/", suffix, true, out)
			end
		elseif name:lower():sub(-#suffix) == suffix then
			out[#out + 1] = dir .. name
		end
	end
	for p, info in path.find(root .. dir .. "*") do
		visit(p, info)
	end
	for p, info in path.find(root .. dir .. "*", true) do
		visit(p, info)
	end
end

local function listing(title, list, limit)
	local lines = {title .. ":"}
	for i = 1, math.min(#list, limit or #list) do
		lines[#lines + 1] = "  " .. list[i]
	end
	if limit and #list > limit then
		lines[#lines + 1] = string.format("  ... and %d more (see %s)", #list - limit, REPORT)
	end
	return table.concat(lines, "\n")
end

function MawCheckGameFiles()
	local manifest = readManifest()
	if not manifest then
		debug.Message("Game files check\n\n" .. MANIFEST .. " was not found in the game folder.\n"
			.. "Your MAW installation is incomplete or older than this check: download MAW again and copy it over the game folder.")
		return
	end

	local known = {}
	for _, list in pairs(manifest) do
		for _, p in ipairs(list) do
			known[normalize(p)] = true
		end
	end

	local missing = {}
	for _, p in ipairs(manifest.maw) do
		if not exists(p) then
			missing[#missing + 1] = p
		end
	end

	local present = {}
	collect("Scripts/", ".lua", true, present)
	collect("Data/", ".lod", false, present)
	local extra = {}
	for _, p in ipairs(present) do
		if not known[normalize(p)] then
			extra[#extra + 1] = p
		end
	end
	table.sort(missing)
	table.sort(extra)

	local header = string.format("Game files check\n\nMissing MAW files: %d\nUnknown scripts and LODs: %d", #missing, #extra)
	local advice = {}
	if #missing > 0 then
		advice[#advice + 1] = "Missing files: download MAW again and copy it over the game folder."
	end
	if #extra > 0 then
		advice[#advice + 1] = "Unknown files are usually left over from an older MAW version. The game still loads them, so delete them unless you added them on purpose."
	end

	local full = {header}
	local shown = {header}
	if #missing > 0 then
		full[#full + 1] = listing("Missing", missing)
		shown[#shown + 1] = listing("Missing", missing, SHOWN)
	end
	if #extra > 0 then
		full[#full + 1] = listing("Unknown", extra)
		shown[#shown + 1] = listing("Unknown", extra, SHOWN)
	end
	if #advice > 0 then
		full[#full + 1] = table.concat(advice, "\n")
		shown[#shown + 1] = table.concat(advice, "\n")
	else
		shown[#shown + 1] = "Everything is in place."
	end

	local f = io.open((AppPath or "") .. REPORT, "wb")
	if f then
		f:write(table.concat(full, "\n\n"), "\n")
		f:close()
	end
	debug.Message(table.concat(shown, "\n\n"))
end

function events.GameInitialized2()
	CustomUI.CreateText{
		Text = "Check game files",
		X = 12,
		Y = 458,
		AlignLeft = true,
		Layer = 0,
		Screen = 0,
		Condition = function() return Game.MainMenuCode >= 0 end,
		Action = MawCheckGameFiles,
	}
end
