local events = Multiplayer.events
local KeyActions = {}
local KeybindsMap = {}

local function Apply(self, symbol, ctrl)
	if #symbol == 0 then
		self.Set.Value = 0
		self.Value = ""
		self.Input.Text = "none"
		self.DefaultText = "none"
		return true
	end

	local key = string.byte(symbol)
	if not key then
		return false
	end

	for _, screen in pairs(self.Set.Screens) do
		KeybindsMap[screen][self.Set.Value] = nil
	end
	self.Set.Value = key
	self.Set.WithCtrl = ctrl

	for _, screen in pairs(self.Set.Screens) do
		KeybindsMap[screen][self.Set.Value] = self.Set
	end

	return true
end

local function Update(self)
	local key = self.Set.Value
	if key == 0 then
		self.Value = ""
		self.Input.Text = "none"
		self.DefaultText = "none"
	else
		self.Value = string.char(key)
		self.Input.Text = (self.Set.WithCtrl and "ctrl + " or "") .. self.Value
		for _, screen in pairs(self.Set.Screens) do
			KeybindsMap[screen][self.Set.Value] = self.Set
		end
	end
	self.Input:UpdateSize(12)
end

local function AddKeybind(Name, Header, Default, WithCtrl, Screens, Action)
	local UI = Multiplayer.utils.UI.CustomSettings
	local t = {
		Set = {
			Name = Name,
			Header = Header,
			Default = string.byte(Default),
			Value = string.byte(Default),
			WithCtrl = WithCtrl,
			Screens = Screens,
			Action = Action
		},
		Widget = UI.Group(" Keybinds ", "Remote UI keybinds"):KeyInput(Header, Default, nil, Apply, Update)
	}
	t.Widget.Set = t.Set
	KeyActions[Name] = t

	for _, screen in pairs(Screens) do
		KeybindsMap[screen] = KeybindsMap[screen] or {}
		KeybindsMap[screen][t.Set.Value] = t.Set
	end
	return t.Set
end
Multiplayer.Keybind = AddKeybind

function events.KeyDown(t)
	local sets = KeybindsMap[Game.CurrentScreen]
	if not sets then
		return
	end

	local set = sets[t.Key]
	if set and (not set.WithCtrl or Game.CtrlPressed) then
		t.Handled = true
		set.Action()
	end
end

local function LoadSavedKeybinds()
	local Keybinds = Multiplayer.GlobalData().Keybinds
	if not Keybinds then
		return
	end

	for name, v in pairs(Keybinds) do
		local t = KeyActions[name]
		if t then
			t.Set.Value = v
			t.Widget:Update()
		end
	end
end

function Multiplayer.std_events.MultiplayerInitialized()
	local UI = Multiplayer.utils.UI.CustomSettings
	UI.Group(" Keybinds ", "Remote UI keybinds")
	-- let all default keybinds finish initialization
	Multiplayer.utils.delayed_call(LoadSavedKeybinds, 10)
end

function Multiplayer.std_events.MultiplayerExtraSettingsClosed()
	local Keybinds = {}
	for name, t in pairs(KeyActions) do
		Keybinds[t.Set.Name] = t.Set.Value
	end
	Multiplayer.GlobalData().Keybinds = Keybinds
end

return {
	Add = AddKeybind,
	KeyActions = KeyActions,
	KeybindsMap = KeybindsMap
}
