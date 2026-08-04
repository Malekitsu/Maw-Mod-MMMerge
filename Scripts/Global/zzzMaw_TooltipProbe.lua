-- TEMPORARY -- gem socket rendering + test harness.
--
-- POSITIONING (inventory / character screen only -- arrows still walk the party
-- on the adventure screen, so these are disabled there):
--
--     arrows            move the gem row by 1px
--     CTRL + arrows     move by 10px
--     SHIFT + left/rt   gem spacing
--     SHIFT + up/down   blank lines reserved in the description
--     CTRL + SHIFT + F  toggle the box outline
--
-- TESTING -- acts on the item currently held on the cursor:
--
--     CTRL + S          add a socket (up to 6)
--     CTRL + G          fill the next empty socket with a random gem
--     CTRL + X          clear all gems and sockets
--
-- REPAIR, for saves damaged by the first storage attempt:
--
--     CTRL + R          clear the stray high bits of BonusExpireTime on every
--                       party item, restoring ancient/legendary/celestial checks
--
-- The tooltip also prints a plain-text socket line. That is deliberate: if the
-- text appears but no icons do, the problem is drawing. If the text does not
-- appear either, the problem is storage. Do not remove it until both work.

local LOG_PATH = "Logs/TooltipDrawTest.txt"
local u4, i4 = mem.u4, mem.i4

local DLG_OFFSET = 0x74
local ITEM_OFFSET = 0x04

local GEM_ITEM_FIRST = 1041   -- gem items are 1041-1060
local GEM_ITEM_LAST = 1060

local DEFAULTS = {
	xFromLeft    = 20,
	yFromTop     = 150,
	spacing      = 26,
	reserveLines = 3,
	drawFrame    = false,
	showText     = true,
	controlSlot  = false, -- slot 1 draws the item's own icon as a known-good control
}

local loggedPictures = {}

local function log(str)
	local f = io.open(LOG_PATH, "a")
	if f then
		f:write(str .. "\n")
		f:close()
	end
end

local function tune()
	vars.MawGemRowTune = vars.MawGemRowTune or {}
	local g = vars.MawGemRowTune
	for k, v in pairs(DEFAULTS) do
		if g[k] == nil then g[k] = v end
	end
	return g
end

local function getItem(d)
	local item
	pcall(function() item = structs.Item:new(u4[d.ebp - ITEM_OFFSET]) end)
	return item
end

local function wantsSockets(item)
	if not item or item.Number <= 0 then return false end
	if item.Number >= GEM_ITEM_FIRST and item.Number <= GEM_ITEM_LAST then return false end
	local ok, res = pcall(function() return IsEnchantableItem(item) end)
	return ok and res or false
end

local function gemPicture(gemType)
	local n = GEM_ITEM_FIRST + (gemType % (GEM_ITEM_LAST - GEM_ITEM_FIRST + 1))
	local pic
	pcall(function() pic = Game.ItemsTxt[n].Picture end)
	return pic
end

-- PLACEHOLDER CONTENT -- names and effects so the tooltip reads properly in a
-- screenshot. Replace with the real gem design; the index is the gem type stored
-- in vars, and it also picks the icon (type N uses item 1041 + N % 20), so keep
-- this list aligned with the gem items if you reorder it.
--
-- When this ships, move this table to General/ alongside zMaw_Sockets.lua so
-- gameplay code can read the effects too. It lives here for now because Global/
-- reloads on a save load, which makes tweaking names fast.
local GEMS = {
	[0]  = {name = "Ruby",          effect = "Might",             color = {255,  70,  70}},
	[1]  = {name = "Sapphire",      effect = "Intellect",         color = { 90, 150, 255}},
	[2]  = {name = "Emerald",       effect = "Personality",       color = { 70, 225, 130}},
	[3]  = {name = "Diamond",       effect = "Endurance",         color = {225, 235, 255}},
	[4]  = {name = "Topaz",         effect = "Accuracy",          color = {255, 210,  80}},
	[5]  = {name = "Amethyst",      effect = "Speed",             color = {190, 120, 255}},
	[6]  = {name = "Opal",          effect = "Luck",              color = {255, 200, 230}},
	[7]  = {name = "Garnet",        effect = "Hit Points",        color = {225,  60, 100}},
	[8]  = {name = "Aquamarine",    effect = "Spell Points",      color = {110, 225, 235}},
	[9]  = {name = "Onyx",          effect = "Armor Class",       color = {165, 165, 185}},
	[10] = {name = "Fire Opal",     effect = "Fire Resistance",   color = {255, 140,  50}},
	[11] = {name = "Citrine",       effect = "Air Resistance",    color = {235, 235, 140}},
	[12] = {name = "Obsidian",      effect = "Water Resistance",  color = { 90, 175, 255}},
	[13] = {name = "Jade",          effect = "Earth Resistance",  color = {170, 200, 110}},
	[14] = {name = "Bloodstone",    effect = "Mind Resistance",   color = {205,  90, 205}},
	[15] = {name = "Pearl",         effect = "Body Resistance",   color = {235, 225, 205}},
	[16] = {name = "Tourmaline",    effect = "Light Resistance",  color = {255, 255, 185}},
	[17] = {name = "Spinel",        effect = "Dark Resistance",   color = {160, 110, 210}},
	[18] = {name = "Zircon",        effect = "Critical Chance",   color = {205, 255, 255}},
	[19] = {name = "Star Sapphire", effect = "Attack Damage",     color = {130, 170, 255}},
}

local UNKNOWN_GEM = {name = "Unknown Gem", effect = "???", color = {180, 180, 180}}

local function gemDef(gemType)
	return GEMS[gemType] or UNKNOWN_GEM
end

-- One line per socket, e.g. "Ruby  +28299 Might", or a greyed "(empty socket)".
local function socketLines(it)
	local n = MawGetSocketCount(it)
	local gems = MawGetGems(it)
	local filled = 0
	local lines = {}
	for slot = 1, n do
		local gem = gems[slot]
		if gem then
			filled = filled + 1
			local def = gemDef(gem.t)
			local c = def.color
			lines[#lines + 1] = StrColor(c[1], c[2], c[3], def.name)
				.. StrColor(235, 235, 235, string.format("  +%d %s", gem.p, def.effect))
		else
			lines[#lines + 1] = StrColor(130, 130, 130, "(empty socket)")
		end
	end
	return n, filled, lines
end

-------------------------------------------------------------------- description

-- Socket data for the tooltip currently being built. The draw hook runs later in
-- the same function, by which point the item pointer slot at ebp-0x04 has been
-- reused -- re-reading the item there gave a DIFFERENT socket set than the text
-- path saw (the giveaway was the control drawing "empty" while the text listed
-- four gems). So resolve everything here, where t.Item is known good, and let the
-- draw hook render this snapshot rather than touching the item again.
local pending = nil

function events.BuildItemInformationBox(t)
	if t.Description == nil then return end
	pending = nil

	-- Deliberately NOT wrapped in a silent pcall: if the socket API is missing or
	-- throwing, we want to see it rather than have the feature quietly vanish.
	if not wantsSockets(t.Item) then return end

	local g = tune()
	local n, filled, lines = socketLines(t.Item)
	if n <= 0 then return end

	local gems = MawGetGems(t.Item)
	local snapshot = {count = n, itemPicture = Game.ItemsTxt[t.Item.Number].Picture, gems = {}}
	for slot = 1, n do
		local gem = gems[slot]
		snapshot.gems[slot] = gem and {t = gem.t, p = gem.p} or false
	end
	pending = snapshot

	if g.showText then
		t.Description = t.Description .. "\n\n"
			.. StrColor(120, 240, 255, string.format("Sockets: %d/%d", filled, n))
			.. "\n" .. table.concat(lines, "\n")
	end
	if g.reserveLines > 0 then
		t.Description = t.Description .. string.rep("\n", g.reserveLines)
	end
end

-------------------------------------------------------------------- drawing

-- Draw at the FINAL hook, not the text-build one. The engine paints the box
-- background and the item's own sprite partway through this function, so
-- anything drawn at text-build time is covered before it reaches the screen.
-- At this point the rect has also been inset by 12px per side for text, which is
-- compensated below so the tuning numbers stay meaningful.
local INSET_COMPENSATION = 12

function MawTooltipProbe(d, tag, t)
	if tag ~= "C-final" then return end

	local ok, err = pcall(function()
		local snap = pending
		if not snap or snap.count <= 0 then return end

		local g = tune()
		local p = d.ebp - DLG_OFFSET
		local L, T, W, H = i4[p], i4[p + 4], i4[p + 8], i4[p + 0xC]
		L = L - INSET_COMPENSATION

		if g.drawFrame then
			Screen:DrawMessageBoxBorder(L, T, W, H)
		end

		local baseX, baseY = L + g.xFromLeft, T + g.yFromTop

		for slot = 1, snap.count do
			local x = baseX + (slot - 1) * g.spacing
			local gem = snap.gems[slot]

			-- Slot 1 can draw the item's own icon as a known-good control: it is
			-- provably loaded, since the engine shows it in this very tooltip.
			local pic
			if slot == 1 and g.controlSlot then
				pic = snap.itemPicture
			else
				pic = gemPicture(gem and gem.t or 0)
			end

			if pic and pic ~= "" then
				-- Log what the icons lod makes of this name -- if gems stay
				-- invisible, this says whether the name or the load is at fault.
				if not loggedPictures[pic] then
					loggedPictures[pic] = true
					local idx, okLoad
					okLoad = pcall(function() idx = Game.IconsLod:LoadBitmap(pic) end)
					log(string.format("icon %q -> LoadBitmap %s",
						pic, okLoad and tostring(idx) or "FAILED"))
				end
				-- Empty sockets use the "unidentified" style so they read as holes.
				-- NOT "gem and nil or 'green'" -- that idiom can never yield nil,
				-- so it painted filled sockets green too.
				local style
				if not gem then
					style = "green"
				end
				Screen:Draw(x, baseY, pic, style)
			else
				log(string.format("slot %d: empty picture name for gem type %s",
					slot, tostring(gem and gem.t or 0)))
			end
		end
	end)

	if not ok then
		log("DRAW FAILED: " .. tostring(err))
	end
end

-------------------------------------------------------------------- test keys

local function heldItem()
	local it = Mouse.Item
	if it and it.Number > 0 then return it end
	return nil
end

-- Plain, uncoloured summary for the status line.
local function statusSummary(it)
	local n = MawGetSocketCount(it)
	local gems = MawGetGems(it)
	local parts = {}
	for slot = 1, n do
		local gem = gems[slot]
		parts[#parts + 1] = gem and string.format("%s+%d", gemDef(gem.t).name, gem.p) or "-"
	end
	return string.format("%d sockets: %s", n, table.concat(parts, ", "))
end

function events.KeyDown(t)
	if Game.CurrentScreen == 0 then return end

	local ok, err = pcall(function()
		local g = tune()
		local K = const.Keys
		local ctrl = Keys.IsPressed(K.CTRL)
		local shift = Keys.IsPressed(K.SHIFT)
		local step = ctrl and 10 or 1
		local handled = true
		local msg

		if ctrl and t.Key == K.D then
			-- Dump gem icon names and whether the icons lod can resolve them.
			log("--- gem icon check ---")
			local good = 0
			for n = GEM_ITEM_FIRST, GEM_ITEM_LAST do
				local pic, idx, err2
				pcall(function() pic = Game.ItemsTxt[n].Picture end)
				local okLoad = pcall(function() idx = Game.IconsLod:LoadBitmap(pic) end)
				if okLoad and idx then good = good + 1 end
				log(string.format("  item %d picture=%q  LoadBitmap=%s",
					n, tostring(pic), okLoad and tostring(idx) or "FAILED"))
			end
			msg = string.format("gem icons: %d/%d resolved -- see log",
				good, GEM_ITEM_LAST - GEM_ITEM_FIRST + 1)

		elseif ctrl and t.Key == K.R then
			msg = "repaired " .. MawRepairBonusExpireTime() .. " items"

		elseif ctrl and (t.Key == K.S or t.Key == K.G or t.Key == K.X) then
			local it = heldItem()
			if not it then
				msg = "pick an item up onto the cursor first"
			elseif t.Key == K.S then
				MawAddSocket(it, 1)
				msg = statusSummary(it)
			elseif t.Key == K.G then
				local n = MawGetSocketCount(it)
				local gems = MawGetGems(it)
				local target
				for slot = 1, n do
					if not gems[slot] then
						target = slot
						break
					end
				end
				if target then
					MawSetGem(it, target, math.random(0, 19), math.random(1, 32767))
					msg = statusSummary(it)
				else
					msg = (n == 0) and "no sockets -- CTRL+S first" or "all sockets full"
				end
			else
				MawClearAllGems(it)
				MawSetSocketCount(it, 0)
				msg = "sockets cleared"
			end

		elseif t.Key == K.LEFT then
			if shift then g.spacing = math.max(0, g.spacing - step) else g.xFromLeft = g.xFromLeft - step end
		elseif t.Key == K.RIGHT then
			if shift then g.spacing = g.spacing + step else g.xFromLeft = g.xFromLeft + step end
		elseif t.Key == K.UP then
			if shift then g.reserveLines = g.reserveLines + 1 else g.yFromTop = g.yFromTop - step end
		elseif t.Key == K.DOWN then
			if shift then g.reserveLines = math.max(0, g.reserveLines - 1) else g.yFromTop = g.yFromTop + step end
		elseif t.Key == K.F and ctrl and shift then
			g.drawFrame = not g.drawFrame
		else
			handled = false
		end

		if handled then
			t.Key = 0
			msg = msg or string.format("gems  x=%d  y=%d  spacing=%d  lines=%d",
				g.xFromLeft, g.yFromTop, g.spacing, g.reserveLines)
			Game.ShowStatusText(msg)
			log(msg)
		end
	end)

	if not ok then
		log("KEY FAILED: " .. tostring(err))
	end
end

log("")
log("######## socket harness loaded (Condition storage) ########")
