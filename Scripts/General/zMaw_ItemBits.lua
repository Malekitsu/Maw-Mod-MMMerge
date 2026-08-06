--   bit  31     sign bit of the i4 -- never set
--   bits 23-30  reserved
--   bit  22     format marker, always set on values written by SetEnc2
--   bits 16-21  enchant type      (0-63)
--   bits 0-15   enchant strength  (0-65535)

local ENC2_MARKER = 0x400000  -- bit 22
local ENC2_TYPE_SHIFT = 16
local ENC2_TYPE_MAX = 0x3F    -- 6 bits
local ENC2_STR_MAX = 0xFFFF   -- 16 bits

ENC2_MAX_TYPE = ENC2_TYPE_MAX
ENC2_MAX_STRENGTH = ENC2_STR_MAX

-- Returns type, strength. Only marked values are enc2 data: Charges also
-- carries potion counters, map affix pairs and MP sync ids, and those now
-- read as "no enchant" instead of being decoded as one.
function DecodeEnc2(v)
	v = v or 0
	if v > 0 and bit.band(v, ENC2_MARKER) ~= 0 then
		return bit.band(bit.rshift(v, ENC2_TYPE_SHIFT), ENC2_TYPE_MAX), bit.band(v, ENC2_STR_MAX)
	end
	return 0, 0
end

-- Packs type and strength into the bitfield, clamping both to their field widths.
function EncodeEnc2(ty, strength)
	ty = math.max(0, math.min(math.floor(ty or 0), ENC2_TYPE_MAX))
	strength = math.max(0, math.min(math.floor(strength or 0), ENC2_STR_MAX))
	if ty == 0 then
		return 0
	end
	return ENC2_MARKER + bit.lshift(ty, ENC2_TYPE_SHIFT) + strength
end

-- Returns type, strength for an item.
function GetEnc2(it)
	return DecodeEnc2(it.Charges)
end

function GetEnc2Type(it)
	local ty = DecodeEnc2(it.Charges)
	return ty
end

function GetEnc2Strength(it)
	local _, strength = DecodeEnc2(it.Charges)
	return strength
end

function SetEnc2(it, ty, strength)
	it.Charges = EncodeEnc2(ty, strength)
end

-- Keeps the existing type, replaces the strength.
function SetEnc2Strength(it, strength)
	local ty = DecodeEnc2(it.Charges)
	it.Charges = EncodeEnc2(ty, strength)
end

-- Keeps the existing strength, replaces the type.
function SetEnc2Type(it, ty)
	local _, strength = DecodeEnc2(it.Charges)
	it.Charges = EncodeEnc2(ty, strength)
end

-- Replaces the old "it.Charges > 1000" test.
function HasEnc2(it)
	local ty = DecodeEnc2(it.Charges)
	return ty > 0
end

function ClearEnc2(it)
	it.Charges = 0
end

------------------------------------------------------------------------
-- BonusExpireTime -- item tier / legendary affix / celestial. The field
-- carries other meanings per item class (artifact level, map affix,
-- vanilla expiry) which read it directly: NOTES.md, ItemFields.lua.
--
--   0        nothing        1  ancient        2  primordial
--   11-35    legendary affix (rolled 1-25 + LEGENDARY_AFFIX_BASE, the
--            same ids legendaryEffects is keyed by)
--   +100     celestial (exactly 100 = celestial with no affix)
------------------------------------------------------------------------

LEGENDARY_AFFIX_BASE = 10
CELESTIAL_OFFSET = 100

-- Ancient (1) / primordial (2) weapon tier; 0 for everything else.
function GetAncientTier(it)
	local v = it.BonusExpireTime
	if v == 1 or v == 2 then
		return v
	end
	return 0
end

function IsAncientItem(it)
	return it.BonusExpireTime == 1
end

function IsPrimordialItem(it)
	return it.BonusExpireTime == 2
end

-- Legendary affix stored as id 11-35 (+100 when celestial). The dominant
-- legacy gate is ">10 and <1000".
function HasLegendaryAffix(it)
	local v = it.BonusExpireTime
	return v > LEGENDARY_AFFIX_BASE and v < 1000
end

-- The affix id (11-35) with the celestial hundred stripped; 0 if none.
function GetLegendaryAffix(it)
	if HasLegendaryAffix(it) then
		return it.BonusExpireTime % CELESTIAL_OFFSET
	end
	return 0
end

function IsCelestialItem(it)
	local v = it.BonusExpireTime
	return v >= CELESTIAL_OFFSET and v < CELESTIAL_OFFSET * 2
end

-- Ancient (1) / primordial (2); any other value clears the field.
function SetAncientTier(it, tier)
	it.BonusExpireTime = (tier == 1 or tier == 2) and tier or 0
end

-- Writes a stored affix id (11-35); 0 removes the affix. Whatever tier the
-- item carried is replaced, the celestial hundred is kept.
function SetLegendaryAffix(it, affix)
	affix = (affix and affix > 0) and affix % CELESTIAL_OFFSET or 0
	it.BonusExpireTime = (IsCelestialItem(it) and CELESTIAL_OFFSET or 0) + affix
end

-- Adds/removes the celestial hundred, keeping the tier or affix underneath.
-- Returns false (item untouched) when the item is not in a state for it.
function SetCelestialItem(it, on)
	if on then
		if it.BonusExpireTime >= CELESTIAL_OFFSET then
			return false
		end
		it.BonusExpireTime = it.BonusExpireTime + CELESTIAL_OFFSET
	else
		if not IsCelestialItem(it) then
			return false
		end
		it.BonusExpireTime = it.BonusExpireTime - CELESTIAL_OFFSET
	end
	return true
end
