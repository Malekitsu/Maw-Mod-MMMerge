-- ItemFields.lua -- the item struct field registry, as code.
--
-- GREENFIELD.md par.4 calls this table "the single most valuable thing in
-- this document". Update it in the same commit as any change to how a field
-- is used. The two hazards to re-read before touching anything:
--
--   1. UNUSED BITS ARE NOT A FREE FIELD. The test is whether existing code
--      reads the field as a whole number. BonusExpireTime looked free in its
--      high 32 bits, failed that test, and broke celestial/legendary items
--      on live saves.
--   2. THE LUA-NUMBER ROUND TRIP. Item-Sorter and MultiBag copy items field
--      by field through Lua doubles: anything above 2^52 corrupts silently,
--      and the unnamed pad byte at 0x1B does not survive the copy at all.
--
-- Clean-break note (decision 2026-08-04): the finished greenfield requires a
-- new game, so NEW encodings need no legacy decode path. But while the legacy
-- mod runs side by side, its systems keep WRITING the old encodings -- a
-- field only becomes free to redesign once its last legacy writer has been
-- migrated. Check writers before redesigning, not after.
--
-- spare column: "no" = leave alone | "owned" = we control the only encoder
--               | "free" = passes the whole-number test, bits available

local ItemFields = {}
MawCore.ItemFields = ItemFields

ItemFields.Registry = {
	{offset = 0x00, name = "Number",          type = "i4", spare = "no",
		holds = "item id; ItemsTxt.High > 2200",
		note  = "dereferenced constantly"},
	{offset = 0x04, name = "Bonus",           type = "i4", spare = "no",
		holds = "StdItems enchant 0-24",
		note  = "indexes StdItemsTxt"},
	{offset = 0x08, name = "BonusStrength",   type = "i4", spare = "no",
		holds = "enchant strength",
		note  = "feeds stat math"},
	{offset = 0x0C, name = "Bonus2",          type = "i4", spare = "no",
		holds = "SpcItems enchant (<=80) or gold value",
		note  = "indexes SpcItemsTxt"},
	{offset = 0x10, name = "Charges",         type = "i4", spare = "owned",
		holds = "enc2 bitfield (zMaw_ItemBits.lua) + 3 unrelated legacy meanings",
		note  = "marker bit 22, type bits 16-21, strength bits 0-15; bits 23-30 free. "
			.. "Also: potion charge counters (zzAlchemy), map affix pairs (zzMaw-Maps), "
			.. "MP object sync ids -- never route those through the enc2 accessors"},
	{offset = 0x14, name = "Condition",       type = "i4", spare = "free",
		holds = "flag bits: 0x1 Identified, 0x2 Broken, 0x8 TemporaryBonus, "
			.. "0xF0 item-effect nibble, 0x100 Stolen, 0x200 Hardened, 0x400 Refundable",
		note  = "bits 11-30 pass the whole-number test (every access is a masked "
			.. "bit op or a faithful copy); earmarked by the gem-sockets design"},
	{offset = 0x18, name = "BodyLocation",    type = "i1", spare = "no",
		holds = "equip slot"},
	{offset = 0x19, name = "MaxCharges",      type = "u1", spare = "no",
		holds = "capped at 200",
		note  = "completely full, no slack"},
	{offset = 0x1A, name = "Owner",           type = "i1", spare = "no",
		holds = "unused by the mod",
		note  = "OFF-LIMITS by user decision"},
	{offset = 0x1B, name = "(pad)",           type = "u1", spare = "no",
		holds = "unused",
		note  = "unnamed, so field-by-field copies (Item-Sorter, MultiBag) drop it"},
	{offset = 0x1C, name = "BonusExpireTime", type = "i8", spare = "no",
		holds = "1 ancient, 2 primordial, 11-35 legendary affix, +100 celestial, "
			.. "1-1000 artifact level",
		note  = "read as a whole number everywhere -- see hazard 1"},
}

function ItemFields.describe()
	local out = {"item struct, 0x24 bytes:"}
	for _, f in ipairs(ItemFields.Registry) do
		out[#out + 1] = ("  0x%02X %-16s %-2s spare:%-5s %s"):format(
			f.offset, f.name, f.type, f.spare, f.holds)
	end
	return table.concat(out, "\n")
end
