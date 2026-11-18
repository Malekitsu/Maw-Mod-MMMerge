local events = Multiplayer.events
local screen = CustomUI.NewScreen(nil, "MultiplayerChooseCharacter")
local prev_screen
local choice
local OnSelection

local function npc_pic_name(id)
	local str = tostring(id)
	return 'npc' .. ('0000'):sub(#str + 1) .. str
end

local function ui_key(i, line)
	return ("mul_char_selection_%s_%s"):format(line, i)
end

local function ShowTextLeft(Text, X, Y)
	CustomUI.ShowText(Text, Game.Arrus_fnt, 0, 0, 3, 640, 480, X, Y, 0xFFFF, 0, true, 0, 0)
end

local function TimeStr(Time)
	local Year = (Time / const.Year):floor() + Game.BaseYear
	local Month = ((Time % const.Year) / const.Month):floor() + 1
	local Day = ((Time % const.Month) / const.Day):floor() + 1
	local Hour = ((Time % const.Day) / const.Hour):floor()
	local Minute = ((Time % const.Hour) / const.Minute):floor()

	return ("%02d.%02d.%04d %02d:%02d"):format(Day, Month, Year, Hour, Minute)
end

local UIElements = {}
local function EndSelection()
	Game.CurrentScreen = prev_screen
	OnSelection = nil
	ExitCurrentScreen()

	for k, v in pairs(UIElements) do
		CustomUI.RemoveElement(v)
	end
	table.clear(UIElements)
end

local function EscChecker(t)
	if Game.CurrentScreen ~= screen then
		assert(events.Remove("Action", EscChecker))
		assert(events.Remove("KeyDown", EscChecker))
		return
	end

	if t.Key == const.Keys.ESCAPE or t.Action == 113 then
		t.Handled = true
		if OnSelection then
			OnSelection(1)
			EndSelection()
		end
	end
end

local function init_ui()
	local function MakeAction(i)
		return function()
			OnSelection(i, choice[i])
			EndSelection()
		end
	end

	local ui = UIElements
	local baseX = 120
	local baseY = 120

	ui[#ui + 1] = CustomUI.CreateIcon{
		Icon = "TPGlobal",
		X = 0,
		Y = 0,
		Screen = screen,
		Layer = 0,
		BlockBG = true,
		Key = "MultiplayerChooseCharBG"
	}

	ui[#ui + 1] = CustomUI.CreateText{
		Text = StrColor(255, 240, 120, "Choose character to play with:"),
		Font = Game.Arrus_fnt,
		X = 0,
		Y = 0,
		Width = 640,
		Height = 480,
		Xof = 0,
		Yof = 76,
		Layer = 0,
		Screen = screen,
		ColorStd = 0xFFFF}

	for i, v in ipairs(choice) do
		local shiftY = (i - 1) * 88

		ui[#ui + 1] = CustomUI.CreateButton{
			IconUp = npc_pic_name(v.PicId),
			X = baseX,
			Y = baseY + shiftY,
			Screen = screen,
			Layer = 0,
			Action = MakeAction(i),
			Key = ui_key(#ui, i)}

		ui[#ui + 1] = CustomUI.CreateText{
			Text = v.Name,
			Font = Game.Arrus_fnt,
			X = baseX + 80,
			Y = baseY + shiftY,
			Layer = 0,
			Screen = screen,
			AlignLeft = true,
			ColorStd = 0xFFFF,
			Key = ui_key(#ui, i)}

		ui[#ui + 1] = CustomUI.CreateText{
			Text = ("%s, Level %s, experience %s"):format(Game.ClassNames[v.ClassId], v.Level, v.Experience),
			Font = Game.Arrus_fnt,
			X = baseX + 80,
			Y = baseY + 20 + shiftY,
			Layer = 0,
			Screen = screen,
			AlignLeft = true,
			ColorStd = 0xFFFF,
			Key = ui_key(#ui, i)}

		local LocTimeStr = {("Party size: %s"):format(v.PartySize)}
		if v.Map and v.Time then
			table.insert(LocTimeStr, ("%s %s"):format(TimeStr(v.Time), v.Map))
		else
			if v.Map then
				table.insert(LocTimeStr, ("Map: %s"):format(v.Map))
			end
			if v.Time then
				table.insert(LocTimeStr, ("Game time: %s"):format(TimeStr(v.Time)))
			end
		end

		ui[#ui + 1] = CustomUI.CreateText{
			Text = table.concat(LocTimeStr, "; "),
			Font = Game.Smallnum_fnt,
			X = baseX + 80,
			Y = baseY + 40 + shiftY,
			Layer = 0,
			Screen = screen,
			AlignLeft = true,
			ColorStd = 0xFFFF,
			Key = ui_key(#ui, i)}
	end
end

-- t is array, item of which have fields: Name, ClassId, PicId, Level, Experience, PartySize
local function CharacterSelection(t, f)
	prev_screen = Game.CurrentScreen
	Game.CurrentScreen = screen
	OnSelection = f
	choice = t
	events.Action = EscChecker
	events.KeyDown = EscChecker

	if #UIElements == 0 then
		init_ui()
	end
end
Multiplayer.SelectCharacter = CharacterSelection

--~ testf = Multiplayer.SelectCharacter
-- Name, ClassId, PicId, Level, Experience, PartySize
--~ t = {
--~ 	{Name = "(current) Jack", ClassId = 0, PicId = 1000, Level = 10, Experience = 5000, PartySize = 1},
--~ 	{Name = "Max", ClassId = 4, PicId = 652, Level = 8, Experience = 4000, PartySize = 2}
--~ }
--~ testf(t, function(i, set)
--~ 	debug.Message(set.Name)
--~ end)
