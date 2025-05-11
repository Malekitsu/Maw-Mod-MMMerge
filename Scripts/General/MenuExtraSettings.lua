local MF = Merge.Functions

local Pages = {}
local CurrentPage = 1

-- Setup special screen for interface manager
local function NewSettingsPage(ScreenName, Header, BackgroundIcon)
	local ScreenId = CustomUI.NewScreen(nil, ScreenName)
	table.insert(Pages, ScreenId)

	if Header then
		CustomUI.CreateText{
			Text = Header,
			X = 0,
			Y = 422,
			Width = 640,
			Height = 16,
			Screen = ScreenId
		}
	end

	if BackgroundIcon then
		CustomUI.CreateIcon{
			Icon = BackgroundIcon,
			X = 0,
			Y = 0,
			Layer = 1,
			Condition = function()
				if Keys.IsPressed(const.Keys.ESCAPE) then
					CustomUI.ExitExtraSettingsMenu()
				end
				return true
			end,
			BlockBG = true,
			Screen = ScreenId}
	end

	return ScreenId
end
CustomUI.NewSettingsPage = NewSettingsPage

local function ExitExtSetScreen()
	Editor.UpdateVisibility(Game.InfinityView)
	if not Game.ShowWeatherEffects then
		CustomUI.ShowSFTAnim() -- stop current animation
	end

	events.call("ExitExtraSettingsMenu")

	Game.CurrentScreen = 2
end
CustomUI.ExitExtraSettingsMenu = ExitExtSetScreen

-- simplify tumbler creation
local Tumblers = {}

local function ToggleTumbler(Tumbler)
	Tumbler.IUpSrc, Tumbler.IDwSrc = Tumbler.IDwSrc, Tumbler.IUpSrc
	Tumbler.IUpPtr, Tumbler.IDwPtr = Tumbler.IDwPtr, Tumbler.IUpPtr

	Game.NeedRedraw = true
	Game[Tumbler.VarName] = Tumbler.IUpSrc == "TmblrOn"
	Game.PlaySound(25)
end

local function OnOffTumbler(Screen, X, Y, VarName)
	local Tumbler = CustomUI.CreateButton{
		IconUp	 	= "TmblrOn",
		IconDown	= "TmblrOff",
		Screen		= Screen,
		Layer		= 0,
		X		=	X,
		Y		=	Y,
		Action	=	ToggleTumbler}

	table.insert(Tumblers, Tumbler)
	Tumbler.VarName = VarName
	return Tumbler
end

function events.OpenExtraSettingsMenu()
	for k,v in pairs(Tumblers) do
		if Game[v.VarName] then
			v.IUpSrc = "TmblrOn"
			v.IDwSrc = "TmblrOff"
		else
			v.IUpSrc = "TmblrOff"
			v.IDwSrc = "TmblrOn"
		end
	end
end

-- simplify number regulator creation
local Regulators = {}

local function NumberRegulator(Screen, X, Y, VarName, OnChange, ReprFunc, Init, Min, Max, Step, Width)
	local Regulator = {
		OnChange = OnChange,
		Repr = ReprFunc or tostring,
		Value = Init or 0,
		Min = Min or 0,
		Max = Max or 100,
		Step = Step or 5,
		VarName = VarName}

	Regulator.Text = CustomUI.CreateText{
		Text = Regulator.Repr(Regulator.Value),
		Layer 	= 0,
		Screen	= Screen,
		Width = Width or 60,	Height = 10,
		X = X + 40, Y = Y}

	-- Decrease bolster
	Regulator.DecButton = CustomUI.CreateButton{
		IconUp 			= "ar_lt_up",
		IconDown 		= "ar_lt_dn",
		IconMouseOver 	= "ar_lt_ht",
		Action = function(t)
			Game.PlaySound(24)
			Regulator.Value = math.max(Regulator.Value - Regulator.Step, Regulator.Min)
			Regulator:OnChange(Regulator.Value)
			Regulator.Text.Text = Regulator.Repr(Regulator.Value)
		end,
		Layer 	= 0,
		Screen 	= Screen,
		X = X, Y = Y}

	-- Increase bolster
	Regulator.IncButton = CustomUI.CreateButton{
		IconUp 			= "ar_rt_up",
		IconDown 		= "ar_rt_dn",
		IconMouseOver 	= "ar_rt_ht",
		Action = function(t)
			Game.PlaySound(23)
			if type(Regulator.Value) == "boolean" then
				Regulator.Value = 0
			end
			Regulator.Value = math.min(Regulator.Value + Regulator.Step, Regulator.Max)
			Regulator:OnChange(Regulator.Value)
			Regulator.Text.Text = Regulator.Repr(Regulator.Value)
		end,
		Layer 	= 0,
		Screen 	= Screen,
		X = X + 20, Y = Y}

	table.insert(Regulators, Regulator)
	return Regulator
end

function events.OpenExtraSettingsMenu()
	for _, Regulator in pairs(Regulators) do
		Regulator.Value = Game[Regulator.VarName]
		Regulator.Text.Text = Regulator.Repr(Regulator.Value)
	end
end

function events.GameInitialized2()

	local ExSetScr = NewSettingsPage("MergeExtraSettings", " General settings", "ExSetScr")
	const.Screens.ExtraSettings = const.Screens.MergeExtraSettings

	local VarsToStore = {"UseMonsterBolster", "BolsterAmount", "ShowWeatherEffects", "ImprovedPathfinding", "freeProgression", "Mode"}
	local RETURN = const.Keys.RETURN
	local ESCAPE = const.Keys.ESCAPE

	---- Switch extra screen ----
	local RightSwitch = CustomUI.CreateButton{
		IconUp 			= "ar_rt_up",
		IconDown 		= "ar_rt_dn",
		IconMouseOver 	= "ar_rt_ht",
		Action = function(t)
			Game.PlaySound(23)
			if CurrentPage < #Pages then
				CurrentPage = CurrentPage + 1
			else
				CurrentPage = 1
			end
			Game.CurrentScreen = Pages[CurrentPage]
		end,
		Condition = function() return #Pages > 1 end,
		Layer 	= 0,
		Screen 	= {ExSetScr},
		X = 554, Y = 422}

	local LeftSwitch = CustomUI.CreateButton{
		IconUp 			= "ar_lt_up",
		IconDown 		= "ar_lt_dn",
		IconMouseOver 	= "ar_lt_ht",
		Action = function(t)
			Game.PlaySound(24)
			if CurrentPage > 1 then
				CurrentPage = CurrentPage - 1
			else
				CurrentPage = #Pages
			end
			Game.CurrentScreen = Pages[CurrentPage]
		end,
		Condition = function() return #Pages > 1 end,
		Layer 	= 0,
		Screen 	= {ExSetScr},
		X = 69, Y = 422}

	---- first page creation ----

	-- Create elements

	local ExSetBtn
	ExSetBtn = CustomUI.CreateButton{
		IconUp	 	  = "ExtSetDw",
		IconDown	  = "ExtSetUp",
		IconMouseOver = "ExtSetUp",
		Screen		= 2,
		Layer		= 0,
		X		=	159,
		Y		=	25,
		Key		=	"MergeExSet",
		Action	=	function(t)
			if Game.CurrentScreen == 2 then
				for k,v in pairs(Pages) do
					CustomUI.ActiveElements[v].Buttons[0][RightSwitch.Key] = RightSwitch
					CustomUI.ActiveElements[v].Buttons[0][LeftSwitch.Key] = LeftSwitch
					CustomUI.ActiveElements[v].Buttons[0][ExSetBtn.Key] = ExSetBtn
				end
				CurrentPage = table.find(Pages, ExSetScr)
				Game.CurrentScreen = ExSetScr
				events.call("OpenExtraSettingsMenu")
			else
				ExitExtSetScreen()
			end
			Game.PlaySound(412)
		end}

	OnOffTumbler(ExSetScr, 95, 175, VarsToStore[5])
	OnOffTumbler(ExSetScr, 95, 251, VarsToStore[3])
	OnOffTumbler(ExSetScr, 95, 326, VarsToStore[4])
	
	-- Game mode
	gameMode={[0]="Normal", [2]="Doom", [4]="Road to\ninsanity",[6]=" Austerity",[8]="Speed\nrun" }
	Game.Mode = Game.Mode or 0
	NumberRegulator(21, 530, 20, "Mode",
		function(t, val)
			Game.Mode = val
		end,
		function(val)
			return gameMode[Game.Mode]
		end,
		Game.Mode, 0, 8, 2, 70)
	--store value
	function events.BeforeNewGameAutosave()
		Game.Mode=Game.Mode or 1
		vars.Mode=Game.Mode

		if vars.Mode==4 then
			vars.insanityMode=true
			vars.Mode=2
		end
		if vars.Mode==8 then
			vars.Mode=2
			vars.ChallengeMode=true
		end
		if vars.Mode==2 then
			Party.Gold=5000
			for i=0,Party.High do
				Party[i].Experience=Party[i].Experience+10000/Party.Count
			end
		end
		if vars.Mode==6 then
			vars.AusterityMode=true
		end
		--[[ removed, as it's buggy and take too much work compared to the demand for it
		if vars.Mode==8 then
			vars.ChallengeMode=true
			vars.Mode=2 --doom
			vars.onlineMode=true
		end
		]]
	end
	function events.Action(t)
		if t.Action==132 or t.Action==124 then
			Game.Mode=0
		end
	end
	-- Bolster amount
	MAWBOLSTER={[0]="Easy", [50]="Norm.", [100]="MAW", [150]="Hard", [200]="Hell", [250]="Night\nmare", [300]="Night\nmare",[600]="Doom"}
	Game.BolsterAmount = Game.BolsterAmount or 50
	NumberRegulator(ExSetScr, 103, 220, "BolsterAmount",
		function(t, val)
			Game.BolsterAmount = val
		end,
		function(val)
			return MAWBOLSTER[Game.BolsterAmount]
		end,
		Game.BolsterAmount, 0, 250, 50)

	-- Frame limit
	Game.FrameLimit = MF.GetRegistryValue("m_framelimit", 0)
	if Game.FrameLimit >= 30 then
		Game.SetFrameLimit(Game.FrameLimit)
	end

	NumberRegulator(ExSetScr, 103, 295, "FrameLimit",
		function(t, val)
			Game.FrameLimit = val
			Game.SetFrameLimit(val >= 30 and val or 0)
			MF.SetRegistryValue("m_framelimit", val)
		end,
		function(val)
			return val >= 30 and tostring(Game.FrameLimit) or "none"
		end,
		Game.FrameLimit, 0, 360, 30)

	-- events

	function events.BeforeSaveGame()
		vars.ExtraSettings = vars.ExtraSettings or {}
		local ExSet = vars.ExtraSettings
		for k,v in pairs(VarsToStore) do
			ExSet[v] = Game[v]
		end
	end

	local function DelayedEscMessage(Text)
		local f = function(str)
			Sleep(1,1)
			Game.EscMessage(str)
		end
		coroutine.resume(coroutine.create(f), Text)
	end

	function events.LoadMapScripts(WasInGame)
		if not WasInGame then
			vars.ExtraSettings = vars.ExtraSettings or {}
			local ExSet = vars.ExtraSettings

			ExSet.BolsterAmount = ExSet.BolsterAmount or 100
			if ExSet.ImprovedPathfinding == nil then
				ExSet.ImprovedPathfinding = true
			end

			for k,v in pairs(VarsToStore) do
				Game[v] = (ExSet[v] == nil) and true or ExSet[v]
			end
		end
	end

end
