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

-- Returns type, strength. Handles both the bitfield and the legacy decimal layout.
function DecodeEnc2(v)
	v = v or 0
	if v <= 0 then
		return 0, 0
	end
	if bit.band(v, ENC2_MARKER) ~= 0 then
		return bit.band(bit.rshift(v, ENC2_TYPE_SHIFT), ENC2_TYPE_MAX), bit.band(v, ENC2_STR_MAX)
	end
	return math.floor(v / 1000), v % 1000
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
------------------------------------------------------------------------

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
	return v > 10 and v < 1000
end

-- The affix id (11-35) with the celestial hundred stripped; 0 if none.
function GetLegendaryAffix(it)
	if HasLegendaryAffix(it) then
		return it.BonusExpireTime % 100
	end
	return 0
end

function IsCelestialItem(it)
	local v = it.BonusExpireTime
	return v >= 100 and v < 200
end
