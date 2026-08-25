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
-- BonusExpireTime -- item rarity. Tier, legendary affix and celestial now
-- live side by side instead of overwriting each other: setting one keeps
-- the others.
--
--   bit 30     marker: this value is rarity data
--   bits 0-5   legendary affix, 1-25 (0 = none)
--   bits 6-7   tier: 0 none, 1 ancient, 2 primordial
--   bit 8      celestial
--   bits 9-19  the drop level the item spawned at (0 = unknown: loot from
--              saves made before it was stored). Charges are randomized and
--              rarity-inflated, so only this field remembers what AREA
--              produced the item -- the wear gate (GetLevelRquirement) reads
--              it through GetItemDropLevel.
--   bits 20-24 cube quality, 0-20: percentage points added to the item's BASE
--              stat (a weapon's damage rows, an armor's AC). Pandora's Cube
--              raises it by a step that depends on the item's rarity.
--
-- The same field also carries an artifact's level, a map affix id and the
-- vanilla bonus expiry. Those are plain numbers with no marker, so they read
-- as "no rarity". Values written before the marker existed are still
-- understood (0/1/2 tier, 11-35 affix, +100 celestial) so old saves keep
-- their items -- except on artifacts, where the number is a level and never
-- was a rarity.
------------------------------------------------------------------------
local RARITY_MARKER = 0x40000000
local RARITY_AFFIX_MAX = 0x3F		--bits 0-5
local RARITY_TIER_SHIFT = 6
local RARITY_TIER_MAX = 3		--bits 6-7
local RARITY_CELESTIAL = 0x100		--bit 8
local RARITY_LEVEL_SHIFT = 9
local RARITY_LEVEL_MAX = 0x7FF		--bits 9-19
local RARITY_QUALITY_SHIFT = 20
local RARITY_QUALITY_MAX = 0x1F		--bits 20-24

--the base stat a fully refined item gains, in percent
CUBE_QUALITY_MAX = 20

LEGENDARY_AFFIX_BASE = 10
CELESTIAL_OFFSET = 100

--mawArtifacts is defined later in load order, so the set is built on demand
local artifactSet
local function isArtifact(it)
	if artifactSet == nil then
		if not mawArtifacts then
			return false
		end
		artifactSet = {}
		for _, number in ipairs(mawArtifacts) do
			artifactSet[number] = true
		end
	end
	return artifactSet[it.Number] == true
end

--tier, affix (1-25, 0 for none), celestial, drop level (0 = unknown), quality
local function DecodeRarity(it)
	local v = it.BonusExpireTime or 0
	if bit.band(v, RARITY_MARKER) ~= 0 then
		return bit.band(bit.rshift(v, RARITY_TIER_SHIFT), RARITY_TIER_MAX),
			bit.band(v, RARITY_AFFIX_MAX),
			bit.band(v, RARITY_CELESTIAL) ~= 0,
			bit.band(bit.rshift(v, RARITY_LEVEL_SHIFT), RARITY_LEVEL_MAX),
			bit.band(bit.rshift(v, RARITY_QUALITY_SHIFT), RARITY_QUALITY_MAX)
	end
	if v <= 0 or isArtifact(it) then
		return 0, 0, false, 0, 0
	end
	--legacy layout: had no room for a level or a quality, both read as unset
	local celestial = v >= CELESTIAL_OFFSET and v < CELESTIAL_OFFSET*2
	local base = celestial and v - CELESTIAL_OFFSET or v
	if base > LEGENDARY_AFFIX_BASE and base < CELESTIAL_OFFSET then
		return 0, base - LEGENDARY_AFFIX_BASE, celestial, 0, 0
	elseif base == 1 or base == 2 then
		return base, 0, celestial, 0, 0
	end
	return 0, 0, celestial, 0, 0
end

local function EncodeRarity(tier, affix, celestial, level, quality)
	tier = math.max(0, math.min(math.floor(tier or 0), RARITY_TIER_MAX))
	affix = math.max(0, math.min(math.floor(affix or 0), RARITY_AFFIX_MAX))
	level = math.max(0, math.min(math.floor(level or 0), RARITY_LEVEL_MAX))
	quality = math.max(0, math.min(math.floor(quality or 0), RARITY_QUALITY_MAX))
	if tier == 0 and affix == 0 and not celestial and level == 0 and quality == 0 then
		return 0
	end
	return RARITY_MARKER + bit.lshift(tier, RARITY_TIER_SHIFT) + affix
		+ (celestial and RARITY_CELESTIAL or 0)
		+ bit.lshift(level, RARITY_LEVEL_SHIFT)
		+ bit.lshift(quality, RARITY_QUALITY_SHIFT)
end

local function SetRarity(it, tier, affix, celestial, level, quality)
	it.BonusExpireTime = EncodeRarity(tier, affix, celestial, level, quality)
end

function HasRarityData(it)
	return bit.band(it.BonusExpireTime or 0, RARITY_MARKER) ~= 0
end

-- Ancient (1) / primordial (2) tier; 0 for everything else.
function GetAncientTier(it)
	return (DecodeRarity(it))
end

function IsAncientItem(it)
	return GetAncientTier(it) == 1
end

function IsPrimordialItem(it)
	return GetAncientTier(it) == 2
end

function HasLegendaryAffix(it)
	local _, affix = DecodeRarity(it)
	return affix > 0
end

-- The affix id as legendaryEffects keys it (11-35); 0 if none.
function GetLegendaryAffix(it)
	local _, affix = DecodeRarity(it)
	if affix > 0 then
		return affix + LEGENDARY_AFFIX_BASE
	end
	return 0
end

function IsCelestialItem(it)
	local _, _, celestial = DecodeRarity(it)
	return celestial
end

-- Ancient (1) / primordial (2); any other value clears the tier. Affix and
-- celestial are kept.
function SetAncientTier(it, tier)
	local _, affix, celestial, level, quality = DecodeRarity(it)
	SetRarity(it, (tier == 1 or tier == 2) and tier or 0, affix, celestial, level, quality)
end

-- Takes a stored affix id (11-35); 0 removes the affix. Tier and celestial
-- are kept.
function SetLegendaryAffix(it, affix)
	local tier, _, celestial, level, quality = DecodeRarity(it)
	affix = (affix and affix > LEGENDARY_AFFIX_BASE) and affix - LEGENDARY_AFFIX_BASE or 0
	SetRarity(it, tier, affix, celestial, level, quality)
end

-- Adds/removes celestial, keeping tier and affix. Returns false (item
-- untouched) when it already is in the requested state.
function SetCelestialItem(it, on)
	local tier, affix, celestial, level, quality = DecodeRarity(it)
	if celestial == (on and true or false) then
		return false
	end
	SetRarity(it, tier, affix, on, level, quality)
	return true
end

-- The drop level the item spawned at; 0 when unknown (legacy loot).
function GetStoredDropLevel(it)
	local _, _, _, level = DecodeRarity(it)
	return level
end

function SetStoredDropLevel(it, level)
	local tier, affix, celestial, _, quality = DecodeRarity(it)
	SetRarity(it, tier, affix, celestial, level, quality)
end

------------------------------------------------------------------------
-- Cube quality -- percentage points on the item's BASE stat. Read by the
-- two funnels that own a base stat: GetWeaponDamageRows (damage rows) and
-- collectArmorAC (armor/shield AC), both in zzMaw-Items.
------------------------------------------------------------------------

function GetItemQuality(it)
	local _, _, _, _, quality = DecodeRarity(it)
	return quality
end

-- Clamped to CUBE_QUALITY_MAX; everything else on the item is kept.
function SetItemQuality(it, quality)
	local tier, affix, celestial, level = DecodeRarity(it)
	quality = math.max(0, math.min(math.floor(quality or 0), CUBE_QUALITY_MAX))
	SetRarity(it, tier, affix, celestial, level, quality)
end

-- What the base stat is multiplied by: 1 with no cube, 1.20 fully refined.
function ItemQualityMult(it)
	return 1 + GetItemQuality(it)/100
end
