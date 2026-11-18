local events = Multiplayer.events
local play_puppet_sound = Multiplayer.require("Synchronization/Players/Monster.lua").play_puppet_sound2
local num_to_hexstr = Multiplayer.utils.num_to_hexstr
local num_from_hexstr = Multiplayer.utils.num_from_hexstr

local packets = {
	play_sound = {
		bulb = function(SoundId)
			return num_to_hexstr(SoundId)
		end,
		handler = function(bin_string, metadata)
			--play_puppet_sound(num_from_hexstr(bin_string), metadata.sender_id)
			local mon = Multiplayer.get_client_mon(metadata.sender_id)
			if mon then
				-- soloud used here, rather than game PlaySound, to allow sound overlapping
				Multiplayer.Audio.PlaySound(num_from_hexstr(bin_string), mon.X, mon.Y)
			end
		end,
		same_map_only = true
	},
}
Multiplayer.utils.init_packets(packets)

function events.UseMouseItem(t)
	local SoundId = Game.ItemSounds[Mouse.Item.Number]
	if SoundId then
		Multiplayer.broadcast(packets.play_sound:prep(SoundId), Multiplayer.utils.cond_same_map)
	end
end

--------------------------------------------
-- Player sounds

-- Categorize sounds

local SoundCategory = {}

local Categories = {
	Chest = 1, -- 0 - 5,
	Items = 2, -- 8 - 17, 48 - 61
	MonsterId = 3, -- 18 - 23
	Injuries = 4, -- 28 - 33
	Condition = 5, -- 34 - 43
	OtherVoice = 6, -- rest voice ids
	DamageTaken = 7, -- generic sounds
	DamageDealt = 8,
}

local CategoryById = {
	Ranges = {
		{0, 5}, {8, 17, 48, 61}, {18, 23}, {28, 33}, {34, 43}
	},
}

for i = 0, 99 do
	CategoryById[i] = Categories.OtherVoice
end

for category, range in pairs(CategoryById.Ranges) do
	for r = 1, #range, 2 do
		for i = range[r], range[r + 1] do
			CategoryById[i] = category
		end
	end
end

for _, SoundSet in Game.CharacterVoices.Sounds do
	for i, v in SoundSet do
		SoundCategory[v] = CategoryById[i]
	end
end

SoundCategory[141] = Categories.Chest

SoundCategory[142] = Categories.OtherVoice
SoundCategory[143] = Categories.OtherVoice
SoundCategory[144] = Categories.OtherVoice

SoundCategory[158] = Categories.Condition
SoundCategory[165] = Categories.Condition
SoundCategory[205] = Categories.Condition

SoundCategory[44] = Categories.DamageTaken
SoundCategory[45] = Categories.DamageTaken
SoundCategory[47] = Categories.DamageTaken
for i = 105, 110 do
	SoundCategory[i] = Categories.DamageTaken
end

SoundCategory[67] = Categories.DamageDealt -- Blaster
SoundCategory[71] = Categories.DamageDealt -- Bow
SoundCategory[78] = Categories.DamageDealt -- Axe
SoundCategory[80] = Categories.DamageDealt
SoundCategory[81] = Categories.DamageDealt -- Blunt
SoundCategory[83] = Categories.DamageDealt
SoundCategory[84] = Categories.DamageDealt -- Sword
SoundCategory[85] = Categories.DamageDealt

Multiplayer.debug.SoundCategory = SoundCategory

-- Create UI

local CategoryStatus

function Multiplayer.std_events.MultiplayerInitialized()
	CategoryStatus = Multiplayer.GlobalData().CategoryStatus or {}
	for k, v in pairs(Categories) do
		if CategoryStatus[v] == nil then
			CategoryStatus[v] = true
		end
	end

	local WidgetHeaders = {
		[Categories.Chest] =		"Chest interaction: ",
		[Categories.Items] =		"Items interaction: ",
		[Categories.MonsterId] =	"Id. Monster:       ",
		[Categories.Injuries] =		"Injures:           ",
		[Categories.Condition] =	"Condition received:",
		[Categories.OtherVoice] =	"NPC interaction:   ",
		[Categories.DamageTaken] =	"Damage taken:      ",
		[Categories.DamageDealt] =	"Attack:            ",
	}

	local UI = Multiplayer.utils.UI.CustomSettings
	local Group = UI.Group("Remote sounds", "Remote player sounds")
	for k, v in pairs(Categories) do
		Group:Switch(WidgetHeaders[v], CategoryStatus, v)
	end
end

function Multiplayer.std_events.MultiplayerExtraSettingsClosed()
	Multiplayer.GlobalData().CategoryStatus = CategoryStatus
end

local function CategoryOn(Category)
	if not Category then
		return false
	end
	return CategoryStatus[Category]
end

function Multiplayer.remote_attack_sounds_on()
	return CategoryStatus[Categories.DamageDealt]
end

function Multiplayer.remote_injury_sounds_on()
	return CategoryStatus[Categories.DamageTaken]
end


-- Network interaction

local packets = {
	play_player_sound = {
		bulb = function(SoundId)
			return num_to_hexstr(SoundId)
		end,
		handler = function(bin_string, metadata)
			local SoundId = num_from_hexstr(bin_string)
			if CategoryOn(SoundCategory[SoundId]) then
				play_puppet_sound(SoundId, metadata.sender_id)
			end
		end,
		same_map_only = true
	},
}
Multiplayer.utils.init_packets(packets)

function events.PlaySound(t)
	-- Player will have 4 in first 3 bits and 40 + PartyId in upper bits
	if (t.ObjRef == 0 or bit.And(t.ObjRef, 7) == 4) and SoundCategory[t.Sound] then
		Multiplayer.broadcast(packets.play_player_sound:prep(t.Sound), Multiplayer.utils.cond_same_map)
	end
end
