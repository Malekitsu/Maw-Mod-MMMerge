-- Classes.lua -- the custom class registry: which class ids belong to each
-- Maw class, and how a class swaps its presentation (skill names, spell
-- texts, mana costs) when a character is selected.
--
-- The class id lists are published as the legacy globals the rest of the mod
-- reads (seraphClass, dkClass, ...), so this table is their one source.
-- Presentation bodies still live in zzClasses; see NOTES.md.

local Classes = {}
MawCore.Classes = Classes

-- Registration order is the reset order in present() -- same order the
-- legacy checkSkills used. `present` is nil for classes whose presentation
-- is handled elsewhere (seraph/shaman tooltips are builders now; dragons
-- swap from their own Tick because they are a RACE, not a class group).
Classes.List = {
	{name = "seraph",       global = "seraphClass",       ids = {53, 54, 55}},
	{name = "shaman",       global = "shamanClass",       ids = {59, 60, 61}},
	{name = "dk",           global = "dkClass",           ids = {56, 57, 58},
		present = function(on, id) dkSkills(on, id) end},
	{name = "elementalist", global = "elementalistClass", ids = {62, 63, 64},
		present = function(on, id) elementalistSkills(on, id) end},
	{name = "assassin",     global = "assassinClass",
		ids = {const.Class.Thief, const.Class.Rogue, const.Class.Assassin, const.Class.Spy},
		present = function(on, id) assassinSkills(on, on and Party[id] or nil) end},
}

local byName = {}
for _, c in ipairs(Classes.List) do
	byName[c.name] = c
	_G[c.global] = c.ids		-- the 60+ legacy table.find(xxxClass, ...) readers
end

-- MawCore.Classes.is(pl, "dk")
function Classes.is(pl, name)
	local c = byName[name]
	return c ~= nil and table.find(c.ids, pl.Class) ~= nil
end

-- the registered class a player belongs to, or nil
function Classes.of(pl)
	for _, c in ipairs(Classes.List) do
		if table.find(c.ids, pl.Class) then
			return c
		end
	end
end

-- Reset every class presentation, then apply the one this character needs.
-- The legacy contract, kept: reset all -> adjustSpellTooltips -> apply one.
function Classes.present(id)
	for _, c in ipairs(Classes.List) do
		if c.present then
			c.present(false, id)
		end
	end
	adjustSpellTooltips()
	if id >= 0 and id <= Party.High then
		local c = Classes.of(Party[id])
		if c and c.present then
			c.present(true, id)
		end
	end
end

function Classes.describe()
	local out = {"classes:"}
	for _, c in ipairs(Classes.List) do
		out[#out + 1] = ("  %-13s %-18s ids %s%s"):format(
			c.name, c.global, table.concat(c.ids, ","),
			c.present and "" or "   (no presentation swap)")
	end
	return table.concat(out, "\n")
end
