-- Tooltip.lua -- item tooltip section registry.
--
-- Legacy: 16 raw BuildItemInformationBox handlers across 7 files appending
-- to the same t.Description string in file load order (GREENFIELD.md par.2).
-- Here every section registers once with a sort key; ONE event handler
-- (registered by start()) runs them in declared order.
--
-- Section fn signature: fn(t) -> string or nil.
--   t is the BuildItemInformationBox event table (t.Item, t.Description,
--   t.Type, t.Name, ...). Return a string to append it to the description --
--   include your own leading "\n\n". Return nil for "no section on this
--   item". A section that must REWRITE rather than append (as the artifact
--   text builder does today) can mutate t directly and return nil.
--
-- Rendering knowledge (images, tooltip geometry, draw timing) lives in
-- GREENFIELD.md par.6; none of it is wired here yet.

local Tooltip = {}
MawCore.Tooltip = Tooltip

local sections = {}
local seq = 0

-- Tooltip.addSection("sockets", 500, fn) -- lower sort key = earlier in tooltip;
-- equal keys keep registration order.
function Tooltip.addSection(id, sort, fn)
	for _, s in ipairs(sections) do
		assert(s.id ~= id, ("tooltip: section %s already registered"):format(id))
	end
	seq = seq + 1
	sections[#sections + 1] = {id = id, sort = sort, seq = seq, fn = fn}
	table.sort(sections, function(a, b)
		if a.sort ~= b.sort then
			return a.sort < b.sort
		end
		return a.seq < b.seq
	end)
end

function Tooltip.remove(id)
	for i, s in ipairs(sections) do
		if s.id == id then
			table.remove(sections, i)
			return true
		end
	end
	return false
end

function Tooltip.describe()
	local out = {"tooltip sections:"}
	for _, s in ipairs(sections) do
		out[#out + 1] = ("  %4d %s"):format(s.sort, s.id)
	end
	if #sections == 0 then
		out[#out + 1] = "  (none)"
	end
	return table.concat(out, "\n")
end

function Tooltip.start()
	function events.BuildItemInformationBox(t)
		for _, s in ipairs(sections) do
			local text = s.fn(t)
			if text and t.Description then
				t.Description = t.Description .. text
			end
		end
	end
end
