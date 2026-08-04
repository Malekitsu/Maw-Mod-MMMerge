-- Gem sockets: up to 6 per item, 64 gem types, per-gem power up to 32767.
--
-- WHY A DICTIONARY, WHEN AFFIXES ARE BIT-PACKED
--
-- 6 sockets x (6-bit type + 15-bit power) is 126 bits. The item struct has
-- nowhere near that free, so gem contents cannot live in the item. Instead the
-- item carries a small handle and the contents live in vars (the per-save table),
-- keyed by that handle.
--
-- The usual objection -- orphaned entries you cannot garbage-collect, because
-- items sit in chests on unloaded maps that no sweep can enumerate -- mostly does
-- not apply, because gems are PLAYER-INSERTED. A freshly generated item in an
-- unopened chest has a socket count and nothing else, so it needs no dictionary
-- entry at all. Entries appear only when the player sockets something: hundreds
-- over a playthrough, not tens of thousands. That leak is small enough to accept.
--
-- WHERE THE HANDLE LIVES, AND WHY NOT BonusExpireTime
--
-- The first version of this file put the handle in the high 32 bits of
-- BonusExpireTime, reasoning that every existing value there is small (ancient=1,
-- primordial=2, legendary affix 11-35, celestial +100, artifact level up to 1000)
-- so the high bytes were unused. That was wrong. The field is an i8 and Lua reads
-- it as ONE number, so setting high bits changed every existing read:
--
--     it.BonusExpireTime == 1            -> became 42949673079, never matched
--     BonusExpireTime > 10 and < 1000    -> never matched
--     legendaryEffects[v % 100]          -> wrong affix
--
-- Unused BITS are not the test. What matters is whether existing code reads the
-- field as a whole value. Condition passes that test: every access in the
-- codebase is either a masked bit operation (:Or(0x10), :And(2), :And(0xf0),
-- :AndNot(0xf0), :And(3)) or a faithful whole-value copy in the item sorter and
-- multibag. Nothing compares it numerically, and it is an i4, so there is no
-- 2^53 precision trap when it is round-tripped through a Lua number.
--
-- LAYOUT, in Item.Condition
--
--     bits 0-10   engine flags: Identified 0x1, Broken 0x2, TemporaryBonus 0x8,
--                 item-effect nibble 0xF0, Stolen 0x100, Hardened 0x200,
--                 Refundable 0x400 -- all left alone
--     bits 11-13  socket count (0-6)
--     bits 14-30  gem-set id (1-131071; 0 means no gems inserted yet)
--     bit  31     left clear -- sign bit of the i4
--
-- Wholesale assignment (it.Condition = 0) still clears sockets, but the only
-- places that do so are clearing a deleted multibag item and a quest item reset,
-- both of which should reset sockets anyway.

local u4 = mem.u4

local COUNT_SHIFT = 11
local COUNT_MASK = 0x7          -- 3 bits, bits 11-13
local ID_SHIFT = 14
local ID_MASK = 0x1FFFF         -- 17 bits, bits 14-30

local SOCKET_BITS = bit.bor(bit.lshift(COUNT_MASK, COUNT_SHIFT), bit.lshift(ID_MASK, ID_SHIFT))

MAW_MAX_SOCKETS = 6
MAW_MAX_GEM_TYPE = 63
MAW_MAX_GEM_POWER = 32767

-------------------------------------------------------------------- raw access

local function readCond(it)
	return it and it.Condition or 0
end

local function writeCond(it, v)
	if it then
		it.Condition = v
	end
end

-------------------------------------------------------------------- dictionary

local function gemStore()
	vars.MawGems = vars.MawGems or {}
	return vars.MawGems
end

-- Ids are never reused, so a stale entry can never be picked up by a different
-- item. 17 bits is 131071 socketed items, far beyond any real playthrough.
local function newGemId()
	local n = (vars.MawGemNextId or 0) + 1
	if n > ID_MASK then
		n = 1 -- pathological; wrap rather than corrupt the field
	end
	vars.MawGemNextId = n
	return n
end

-------------------------------------------------------------------- sockets

function MawGetSocketCount(it)
	return bit.band(bit.rshift(readCond(it), COUNT_SHIFT), COUNT_MASK)
end

function MawSetSocketCount(it, n)
	n = math.max(0, math.min(math.floor(n or 0), MAW_MAX_SOCKETS))
	local c = readCond(it)
	c = bit.band(c, bit.bnot(bit.lshift(COUNT_MASK, COUNT_SHIFT)))
	writeCond(it, bit.bor(c, bit.lshift(n, COUNT_SHIFT)))
	return n
end

-- Convenience for the crafting item that grants an extra socket.
function MawAddSocket(it, n)
	return MawSetSocketCount(it, MawGetSocketCount(it) + (n or 1))
end

-------------------------------------------------------------------- gem id

local function getGemId(it)
	return bit.band(bit.rshift(readCond(it), ID_SHIFT), ID_MASK)
end

local function setGemId(it, id)
	local c = readCond(it)
	c = bit.band(c, bit.bnot(bit.lshift(ID_MASK, ID_SHIFT)))
	writeCond(it, bit.bor(c, bit.lshift(bit.band(id, ID_MASK), ID_SHIFT)))
end

local function ensureGemId(it)
	local id = getGemId(it)
	if id == 0 then
		id = newGemId()
		setGemId(it, id)
	end
	local store = gemStore()
	store[id] = store[id] or {}
	return id
end

-------------------------------------------------------------------- gems

-- Returns type, power for a slot, or nil if empty.
function MawGetGem(it, slot)
	local id = getGemId(it)
	if id == 0 then return nil end
	local set = gemStore()[id]
	local g = set and set[slot]
	if not g then return nil end
	return g.t, g.p
end

-- Returns {slot -> {t = type, p = power}}. Never nil.
function MawGetGems(it)
	local id = getGemId(it)
	if id == 0 then return {} end
	return gemStore()[id] or {}
end

function MawSetGem(it, slot, gemType, power)
	slot = math.floor(slot or 0)
	if slot < 1 or slot > MawGetSocketCount(it) then
		return false, "slot out of range for this item's socket count"
	end
	gemType = math.max(0, math.min(math.floor(gemType or 0), MAW_MAX_GEM_TYPE))
	power = math.max(0, math.min(math.floor(power or 0), MAW_MAX_GEM_POWER))

	local id = ensureGemId(it)
	gemStore()[id][slot] = {t = gemType, p = power}
	return true
end

function MawClearGem(it, slot)
	local id = getGemId(it)
	if id == 0 then return end
	local set = gemStore()[id]
	if set then
		set[slot] = nil
	end
end

-- Drops the gem set and releases the handle. Socket count is left alone.
function MawClearAllGems(it)
	local id = getGemId(it)
	if id ~= 0 then
		gemStore()[id] = nil
		setGemId(it, 0)
	end
end

function MawHasGems(it)
	return next(MawGetGems(it)) ~= nil
end

-------------------------------------------------------------------- utilities

-- Wrap any assignment that clears Condition but should keep sockets:
--     MawPreserveSockets(it, function() it.Condition = 1 end)
function MawPreserveSockets(it, fn)
	local keep = bit.band(readCond(it), SOCKET_BITS)
	fn()
	writeCond(it, bit.bor(bit.band(readCond(it), bit.bnot(SOCKET_BITS)), keep))
end

-- Copies sockets and gems. The copy gets its own id and its own entry, so later
-- edits to one do not affect the other.
function MawCopySockets(from, to)
	MawSetSocketCount(to, MawGetSocketCount(from))
	setGemId(to, 0)
	local src = MawGetGems(from)
	if next(src) == nil then return end
	local id = ensureGemId(to)
	local dst = gemStore()[id]
	for slot, g in pairs(src) do
		dst[slot] = {t = g.t, p = g.p}
	end
end

-- One-shot cleanup for saves touched by the first version of this file, which
-- wrote into the high 32 bits of BonusExpireTime and so broke every
-- ancient/primordial/legendary/celestial check on affected items. Zeroing that
-- dword is always safe: no legitimate value has ever needed it.
function MawRepairBonusExpireTime()
	local fixed = 0
	for i = 0, Party.High do
		local pl = Party[i]
		for j = 0, 138 do
			local ok = pcall(function()
				local it = pl.Items[j]
				local p = it and it["?ptr"]
				if p and u4[p + 0x20] ~= 0 then
					u4[p + 0x20] = 0
					fixed = fixed + 1
				end
			end)
			if not ok then break end
		end
	end
	return fixed
end
