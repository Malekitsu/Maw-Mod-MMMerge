-- Town Portal chose a town by itself (2026-10-11).
-- Casting from the spellbook by a double click opens the Town Portal window on the second press,
-- while the left button is still held. The engine's mouse state for its newer windows keeps
-- "button pressed" (byte 0x1006140), and the Town Portal window (constructor 0x4D0FC4), unlike
-- others (0x4C978B, 0x4CE12B), does not clear it when it opens. With mouse look on, the patch
-- moves the cursor to the centre while the screen briefly returns to the game view, so the press
-- landed on the central town's button and the release clicked it (Free Haven, Ravenshore,
-- Harmondale sit there) - about half of the casts, depending on frame timing.
-- Now the flag is cleared as the window opens, as the other windows do.

local addr = 0x4D0FDC  -- or dword [0x1006130], -1 (7 bytes), right after the window's setup call
if mem.string(addr, 7, true) ~= "\131\13\48\97\0\1\255" then
	return
end

mem.autohook(addr, function()
	mem.u1[0x1006140] = 0
end)
