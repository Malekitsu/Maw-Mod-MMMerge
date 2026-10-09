-- Fixes.lua -- port of MAW_Fixes.dll to Lua, so the DLL can be deleted.
--
-- Source: mm8_plugins repo, MAW_Fixes/dllmain.cpp. The DLL applied these at
-- process attach; both patched values are only read during gameplay, so
-- applying them at General/ load time is equivalent. Running with the DLL
-- still present is harmless -- both write the same bytes.

local Fixes = {}
MawCore.Fixes = Fixes

function Fixes.start()
	local Engine = MawCore.Engine
	local A = Engine.Addr

	-- 1. Skill-hint row format string. Original data at 0x4F3BF8 is
	--    "%s\12%05u\t110%d\12..." (name, color code, number column); the fix
	--    truncates it to "%s\n" so the row shows the name only.
	Engine.patch("SkillHintRowFormat",
		"MAW_Fixes port: skill hint row shows name only", function()
		mem.IgnoreProtection(true)
		mem.u1[A.SkillHintRowFormat]     = 0x25	-- %
		mem.u1[A.SkillHintRowFormat + 1] = 0x73	-- s
		mem.u1[A.SkillHintRowFormat + 2] = 0x0A	-- \n
		mem.u1[A.SkillHintRowFormat + 3] = 0x00
		mem.IgnoreProtection(false)
	end)

	-- 2. Recovery-time floor. 0x42DA51 is "push 30" (6A 1E) -- the clamp the
	--    engine applies right after computing attack recovery. Patch the
	--    immediate to 1 so recovery can go below 30.
	Engine.patch("RecoveryFloor",
		"MAW_Fixes port: minimum attack recovery 30 -> 1", function()
		mem.IgnoreProtection(true)
		mem.u1[A.RecoveryFloorPush + 1] = 1
		mem.IgnoreProtection(false)
	end)

	-- 3. mm8.ini: force FixMonstersBlockingShots=1 (GrayFace patch option).
	--    Like the DLL, this edits the file, and the option is read at engine
	--    startup -- so a correction takes effect on the NEXT launch. Not an
	--    exe patch, hence not in the Engine ledger.
	local path = AppPath .. "mm8.ini"
	local f = io.open(path, "r")
	if f then
		local text = f:read("*a")
		f:close()
		if text:find("FixMonstersBlockingShots=0", 1, true) then
			text = text:gsub("FixMonstersBlockingShots=0",
				"FixMonstersBlockingShots=1", 1)
			f = io.open(path, "w")
			if f then
				f:write(text)
				f:close()
			end
		end
	end

	-- 4. Arena crash at Lord level. MAW rescales MonstersTxt levels, so with a
	--    strong party no monster type falls into the arena's level range and
	--    the engine divides by zero. Offer the 12 types nearest to the range
	--    instead; the engine draws its up-to-6 from those (the nearest alone
	--    would make the whole arena one kind of monster).
	Engine.setArenaPoolFallback(function(min, max, list)
		local function dist(m)
			return m.level < min and min - m.level or m.level > max and m.level - max or 0
		end
		table.sort(list, function(a, b)
			local da, db = dist(a), dist(b)
			return da < db or da == db and a.id < b.id
		end)
		local ids = {}
		for k = 1, math.min(#list, 12) do
			ids[k] = list[k].id
		end
		return ids
	end)
end
