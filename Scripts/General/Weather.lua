
-- Weather states from 0 - sunny to 7 - storm, 5 - raining, 0,1,2,3,4 - sky and fog setups.
-- EaxEnvironments: 5 - Stoneroom, 8 - Cave, 15 - Forest, 16 - City, 22 - Underwater, 26 - Plains/Mountain
local EffectActive	= false
local CurrentEffect	= 0
local SkyStates = {}

local function ResetWeather()
	CustomUI.ShowSFTAnim()
end

local function GetWeatherState()
	local WeatherState

	if not Map.IsOutdoor() or table.find({5,8,22}, Game.MapStats[Map.MapStatsIndex].EaxEnvironments) then
		mapvars.LastWeatherState = WeatherState
		mapvars.LastVisitDay = Game.DayOfMonth
		WeatherState = 0
	elseif mapvars.LastWeatherState and mapvars.LastVisitDay and mapvars.LastVisitDay == Game.DayOfMonth then
		WeatherState = mapvars.LastWeatherState
	else
		local Continent = TownPortalControls.GetCurrentSwitch()
		WeatherState = (Game.Hour > 21 or Game.Hour < 5) and 1 or 0
		WeatherState = WeatherState + Game.Month < 3 and 1 or Game.Month < 6 and 2 or Game.Month < 9 and 0 or Game.Month < 12 and 1
		WeatherState = WeatherState + math.random(0, #SkyStates[Continent]-2)
		WeatherState = math.max(WeatherState, 0)
		mapvars.LastWeatherState = WeatherState
		mapvars.LastVisitDay = Game.DayOfMonth
	end

	return WeatherState
end

function SetSkyTexture(texture)
	if texture == nil or texture == "" then
		return
	end

	local SkyBitmap = Game.BitmapsLod:LoadBitmap(texture)
	Game.BitmapsLod.Bitmaps[SkyBitmap]:LoadBitmapPalette()
	Map.LoadedSkyBitmap = SkyBitmap
end

local function SetSky()
	local MapExtra = Game.Bolster.MapsSource[Map.MapStatsIndex]
	local Continent = TownPortalControls.GetCurrentSwitch()
	local SkySet = SkyStates[Continent]
	local SkyBitmap = MapExtra and MapExtra.CustomSky or SkySet[math.min(GetWeatherState(), #SkySet)]

	SetSkyTexture(SkyBitmap)
end

local function SetWeather(WeatherState, Effect)
	local Continent = TownPortalControls.GetCurrentSwitch()
	local WeatherState = WeatherState or GetWeatherState()

	CustomUI.ShowSFTAnim() -- remove weather effect

	if Game.IsD3D then
		if WeatherState > math.floor(#SkyStates[Continent]/3) then
			Game.Weather.New()
			Game.Weather.FogRange1 = math.floor(4096/WeatherState*2)
			Game.Weather.FogRange2 = math.floor(8096/WeatherState*2)
			Game.Weather.Fog = true
		else
			Game.Weather.Fog = false
		end
	end

	if Effect then
		CurrentEffect = Effect
	elseif WeatherState > math.floor(#SkyStates[Continent]/2) then
		if evt.CheckSeason{3} or (evt.CheckSeason{2} and math.random(0,1) == 1) then
			CurrentEffect = 0
		else
			CurrentEffect = 2
		end
	else
		CurrentEffect = -1
	end

	local t = {WeatherState = WeatherState, CurrentEffect = CurrentEffect, EffectActive = EffectActive, Reason = "Day", Handled = false}
	events.call("WeatherChanged", t)

	if not t.Handled then
		mapvars.LastWeatherState = t.WeatherState
		mapvars.LastVisitDay = Game.DayOfMonth
		mapvars.CurrentWeatherEffect = t.CurrentEffect
		CurrentEffect = t.CurrentEffect
		SetSky()
	end
end
Game.SetWeather = SetWeather

local LastWeatherDay = 0
local function WeatherTimer()
	local WeatherEffects = Game.ShowWeatherEffects
	local WeatherState = GetWeatherState()

	if LastWeatherDay ~= Game.DayOfMonth then
		LastWeatherDay = Game.DayOfMonth
		SetWeather()
	end
end

local function WeatherEffectTimer()
	local WeatherEffects = Game.ShowWeatherEffects
	if not WeatherEffects then
		return
	end

	local WeatherState = GetWeatherState()

	if WeatherState <= 3 then
		ResetWeather()
	elseif mapvars.EffectWasActive or  math.random(0,1) == 1 then
		if mapvars.EffectWasActive == nil then
			EffectActive = not EffectActive
		else
			EffectActive = mapvars.EffectWasActive
			mapvars.EffectWasActive = nil
		end
		CurrentEffect = mapvars.CurrentWeatherEffect

		local t = {WeatherState = GetWeatherState(), CurrentEffect = CurrentEffect, EffectActive = EffectActive, Reason = "WeatherEffect", Handled = false}
		events.call("WeatherChanged", t)
		if not t.Handled then
			CurrentEffect = t.CurrentEffect
			EffectActive = t.EffectActive
			if CurrentEffect then
				evt.SetSnow{CurrentEffect, EffectActive and 1 or 0}
			end
		end
	end
end

function events.AfterLoadMap()
	local MapExtra = Game.Bolster.MapsSource[Map.MapStatsIndex]
	if MapExtra then
		if MapExtra.Weather then
			SetWeather()
			Timer(WeatherEffectTimer, const.Hour, true)
			Timer(WeatherTimer, const.Day, true)
		else
			SetSky()
		end
	end
end

function events.BeforeSaveGame()
	mapvars.EffectWasActive = EffectActive
end

local TargetTransp, CurTransp, StepTransp, FadeTimer
local function FadeWeatherEffect(Period, StartStep, TargetStep)

	CurTransp = StartStep
	TargetTransp = TargetStep
	if StartStep > TargetStep then
		StepTransp = -1
	else
		StepTransp = 1
	end

	FadeTimer = function()
		if not Game.ShowWeatherEffects then
			CustomUI.ShowSFTAnim()
			RemoveTimer(FadeTimer)
			return
		end

		if CurTransp ~= TargetTransp then
			CurTransp = CurTransp + StepTransp
			CustomUI.ShowSFTAnim{Transparency = CurTransp}
		else
			RemoveTimer(FadeTimer)
			if TargetTransp == 0 then
				CustomUI.ShowSFTAnim()
			end
		end
	end

	Timer(FadeTimer, Period)

end

function events.GameInitialized2()

	-- Load sky sets
	for k,v in pairs(Game.ContinentSettings) do
		SkyStates[k] = v.Skies
		if #SkyStates[k] == 0 then
			SkyStates[k] = Game.ContinentSettings[1].Skies
		end
	end

	-- evt.SetSnow
	mem.hook(0x444ec3, function(d)
		if not Game.IsD3D then
			return
		end

		if d.edx == 0 then
			if d.ecx == 0 then
				FadeWeatherEffect(const.Minute/32, Game.SnowOpacity or 70, 0)
			elseif d.ecx == 2 then
				FadeWeatherEffect(const.Minute/32, Game.RainOpacity or 50, 0)
			end
		elseif Game.ShowWeatherEffects then
			if d.ecx == 0 then
				FadeWeatherEffect(const.Minute/32, 0, Game.SnowOpacity or 70)
				CustomUI.ShowSFTAnim{SFTGroupName = "Snow",	Transparency = 0, Period = 55,
					Width = 831, Height = 420, X = -193, Y = -20,
					Start = 23339, End = 23388}
			elseif d.ecx == 2 then
				FadeWeatherEffect(const.Minute/32, 0, Game.RainOpacity or 50)
				CustomUI.ShowSFTAnim{SFTGroupName = "Rain",	Transparency = 0, Period = 55,
					Width = 831, Height = 420, X = -193, Y = -20}
			end
		end
	end)

	function events.LeaveMap()
		ResetWeather()
	end

	function events.LeaveGame()
		ResetWeather()
		RemoveTimer(WeatherTimer)
	end

	-- Make Awaken spell clear weather effects
	local WTimer
	WTimer = function()
		FadeWeatherEffect(const.Minute/32, 70, 0)
		RemoveTimer(WTimer)
	end
	mem.autohook2(0x4287ed, function(d)
		if CustomUI.SFTAnimActive() then
			Timer(WTimer, const.Minute)
		end
	end)

end

