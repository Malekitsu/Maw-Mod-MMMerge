local events = Multiplayer.events
local r4u = Multiplayer.utils.r4asint

Multiplayer.STEP_SOUNDS_MAX_DIST = 5600
Multiplayer.STEP_SOUNDS_ATTENUATION = 2
Multiplayer.SOLOUD_GLOBAL_VOLUME = 0.8 -- multiplier for std voice volume and game volume

local mSounds = {}
Multiplayer.Audio = mSounds

local Playback = {}
Multiplayer.debug.Playback = Playback

local info_buff = mem.StaticAlloc(40)
--typedef struct _AILSOUNDINFO {
--  S32 format;
--  void const FAR* data_ptr;
--  U32 data_len;
--  U32 rate;
--  S32 bits;
--  S32 channels;
--  U32 samples;
--  U32 block_size;
--  void const FAR* initial_ptr;
--} AILSOUNDINFO;

local WAV_info = mem.dll['mss32']["_AIL_WAV_info@8"]

local function SoundBinFromId(Id)
	local SoundBinItem
	for i, v in Game.SoundsBin do
		if v.Id == Id then
			return v
		end
	end
end

local function SoundBinData(SoundBin)
	for i, v in SoundBin.Data do
		if v > 0 then
			return v + 4
		end
	end
	if SoundBin.Data3D > 0 then
		return SoundBin.Data3D
	end
end

local function GetSoundInfo(Id)
	local SoundBinItem = SoundBinFromId(Id)
	if not SoundBinItem then
		return false
	end

	local ptr = SoundBinData(SoundBinItem)

	if ptr and WAV_info(ptr, info_buff) == 1 then
		local u4 = mem.u4
		local result = {
			format = u4[info_buff],
			header_ptr = ptr,
			file_size = u4[ptr-4],
			data_ptr = u4[info_buff+4],
			data_len = u4[info_buff+8],
			rate = u4[info_buff+12],
			bits = u4[info_buff+16],
			channels = u4[info_buff+20],
			samples = u4[info_buff+24],
			block_size = u4[info_buff+28],
			initial_ptr = u4[info_buff+32],
		}
		if result.format == 1 then
			result.file_size = result.data_len + (result.data_ptr - result.header_ptr)
		end
		return result
	end
	return false
end
mSounds.GetSoundInfo = GetSoundInfo

-----------------------------------------
-- Soloud -- https://solhsa.com/soloud/

local SL = mem.dll['soloud_x86']
local Soloud
local LoadedWAVs = {}

mSounds.LoadedWAVs = LoadedWAVs

function Multiplayer.SoloudInstance()
	return Soloud
end

function events.MultiplayerStarted()
	if not SL or Soloud then
		return
	end

	Soloud = SL.Soloud_create()
	SL.Soloud_init(Soloud, 1, 4) -- CLIP_ROUNDOFF, WINMM
	SL.Soloud_setGlobalVolume(Soloud, r4u(Multiplayer.SOLOUD_GLOBAL_VOLUME))
end

function events.MultiplayerStopped()
	if not SL or not Soloud then
		return
	end

	for _, t in pairs(LoadedWAVs) do
		SL.Wav_destroy(t.handle)
	end
	table.clear(LoadedWAVs)

	SL.Soloud_deinit(Soloud)
	SL.Soloud_destroy(Soloud)

	Soloud = nil
end

local function SoloudMMWav(Id, wav)
	assert(Soloud)
	assert(Id)

	SL.Soloud_stopAll(Soloud)
	Multiplayer.utils.LogEvent("INTERNAL", "Loading sound #%s.", Id)

	local SoundBin = SoundBinFromId(Id)
	Game.LoadSound(Id)
	SoundBin.Type = 4 -- prevent sound unloading
	SoundBin.Locked = true
	Multiplayer.utils.LogEvent("INTERNAL", "Game.LoadSound passed.", Id)

	local wav = wav or SL.Wav_create()
	Multiplayer.utils.LogEvent("INTERNAL", "SOLOUD: WAV handle created.")
	local info = GetSoundInfo(Id)
	Multiplayer.utils.LogEvent("INTERNAL", "MSS32: WAV info read.")
	local result, length = -1, 0

	if info then
		length = math.ceil(info.samples / info.rate * 1000)
		result = SL.Wav_loadMemEx(wav, info.header_ptr, info.file_size, 0, 0)
		Multiplayer.utils.LogEvent("INTERNAL", "SOLOUD: Sound #%s loading using header ptr: %s.", Id, result == 0 and "success" or "failure")
	end

	local t = {
		info = info,
		length = length,
		handle = wav,
		loaded = result == 0
	}

	return t, result
end

local dtdeg = Multiplayer.utils.direction_to_degrees
local function LocalRelative(Point, Direction, X, Y)
	local dx, dy = X - Point.X, Y - Point.Y
	local dir = math.rad(dtdeg(Direction))
	local dist = math.sqrt((dx)^2 + (dy)^2)

	local rx, ry = 0, 0
	if dist > 0 then
		local k = math.sin(dir)
		rx = dx * k / dist
		ry = dy * k / dist
	end

	return rx, ry, dist
end

local function SoloudPlaySound(Id, X, Y)
	assert(Soloud)

	local wav = LoadedWAVs[Id]
	if not wav then
		wav = SoloudMMWav(Id)
		LoadedWAVs[Id] = wav
	end
	if not wav.loaded then
		wav = SoloudMMWav(Id, wav.handle)
		LoadedWAVs[Id] = wav
		if not wav.loaded then
			return
		end
	end
	wav = wav.handle

	local vol = bit.And(Game.SoundVolume, 255)
	if vol == 0 then
		return
	end
	vol = vol / 9

	if X and Y then
		local mdist = Multiplayer.STEP_SOUNDS_MAX_DIST
		local px, py, dist = LocalRelative(Party, Party.Direction, X, Y)
		vol = vol * math.max((mdist - dist) / mdist, 0)

		local handle = SL.Soloud_play3d(Soloud, wav,
			r4u(px),
			r4u(py),
			r4u(0))
		SL.Soloud_setVolume(Soloud, handle, r4u(vol))

		SL.Soloud_set3dListenerPosition(Soloud,
			r4u(Party.X),
			r4u(Party.Y),
			r4u(0))

		local at = Multiplayer.utils.step_from_point(Party, 100, Party.Direction)
		SL.Soloud_set3dListenerAt(Soloud,
			r4u(at.X),
			r4u(at.Y),
			r4u(0))

		SL.Soloud_set3dSourcePosition(Soloud,
			handle,
			r4u(X), r4u(Y), r4u(0))

		SL.Soloud_set3dSourceMinMaxDistance(Soloud,
			handle,
			r4u(0), r4u(Multiplayer.STEP_SOUNDS_MAX_DIST))

		SL.Soloud_set3dSourceAttenuation(Soloud,
			handle,
			Multiplayer.STEP_SOUNDS_ATTENUATION, r4u(1))

		SL.Soloud_update3dAudio(Soloud)
		SL.Soloud_setPan(Soloud, handle, r4u(px))
	else
		SL.Soloud_play(Soloud, wav, r4u(vol))
	end
end

local SoundLength = {}
local function GetSoundLength(SoundId)
	if SoundLength[SoundId] then
		return SoundLength[SoundId]
	end

	local info = GetSoundInfo(SoundId)
	if info then
		local length = math.ceil(info.samples / info.rate * 1000)
		SoundLength[SoundId] = length
		return length
	end

	return 0
end

local function PlayStepSound(SoundId, ClientId)
	local Puppet = Multiplayer.get_client_mon(ClientId)
	if not Puppet then
		return
	end

	local ClientPlayback = Playback[ClientId]
	if not ClientPlayback then
		ClientPlayback = {}
		Playback[ClientId] = ClientPlayback
	end

	local LastEnds = ClientPlayback[SoundId] or 0
	local Timestamp = timeGetTime()
	if Timestamp < LastEnds then
		return
	end

	if Soloud then
		SoloudPlaySound(SoundId, Puppet.X, Puppet.Y)
		ClientPlayback[SoundId] = Timestamp + LoadedWAVs[SoundId].length
	else
		Game.PlaySound(SoundId, 1, 0, Puppet.X, Puppet.Y)
		ClientPlayback[SoundId] = Timestamp + GetSoundLength(SoundId)
	end
end
mSounds.PlayStepSound = PlayStepSound

local function PlaySound(SoundId, X, Y)
	if Soloud then
		SoloudPlaySound(SoundId, X, Y)
	else
		Game.PlaySound(SoundId, 1, 0, X, Y)
	end
end
mSounds.PlaySound = PlaySound
