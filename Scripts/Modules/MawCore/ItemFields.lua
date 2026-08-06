-- ItemFields.lua -- the item struct field registry, as code.
--
-- Update it in the same commit as any change to how a field is used.
-- The two hazards (unused bits are not a free field; the Lua-double round
-- trip in Item-Sorter/MultiBag) are written up in GREENFIELD.md par.4.
--
-- spare: "no" = leave alone | "owned" = we control the only encoder
--        | "free" = passes the whole-number test, bits available

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
		holds = "1 ancient, 2 primordial, 11-35 legendary affix, +100 celestial "
			.. "(exactly 100 = celestial without affix, from black potions), "
			.. "1-1000 artifact level, map affix id on map items (getUniqueAffix), "
			.. "vanilla Game.Time expiry on unmodified temp-enchanted items",
		note  = "read as a whole number everywhere -- see hazard 1. Tier/affix/"
			.. "celestial accessors live in zMaw_ItemBits.lua (GetAncientTier, "
			.. "IsAncientItem, IsPrimordialItem, HasLegendaryAffix, "
			.. "GetLegendaryAffix, IsCelestialItem); artifact level, map affixes "
			.. "and the vanilla expiry read the field directly"},
}

function ItemFields.describe()
	local out = {"item struct, 0x24 bytes:"}
	for _, f in ipairs(ItemFields.Registry) do
		out[#out + 1] = ("  0x%02X %-16s %-2s spare:%-5s %s"):format(
			f.offset, f.name, f.type, f.spare, f.holds)
	end
	return table.concat(out, "\n")
end
