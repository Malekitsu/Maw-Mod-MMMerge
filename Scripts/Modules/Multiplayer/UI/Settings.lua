local UIUtils = Multiplayer.require("UI/UtilsUI.lua")

local Groups = {}
local BaseX, BaseY = 60, 80
local Shift = 30
local DefaultNewGroup
local CurrentGroup
local CurentSubGroupId
local MaxOnPage = 10
local CurrentPage = 1
local SettignsOpen = false

--- UI

local LeftPage, RightPage

local function Show(State, Direction)
	SettignsOpen = State == nil or State
	if not SettignsOpen then
		return
	end

	if CurrentGroup == nil then
		CurrentGroup = Groups["main"]
		CurrentPage = 1
	end
	Direction = Direction or 0

	if Direction > 0 and (CurrentPage * MaxOnPage >= #CurrentGroup.Elements or #CurrentGroup.Elements == 0) then
		CurrentPage = 1
		-- move to next group
		local group = CurrentGroup:NextGroup()
		if group then
			LeftPage.Text = "<<< " .. CurrentGroup.Name
			LeftPage:UpdateSize()
			CurrentGroup = group
			CurrentPage = 1

			group = CurrentGroup:NextGroup()
			if group then
				RightPage.Text = group.Name .. " >>>"
				RightPage:UpdateSize()
			else
				RightPage.Text = " "
				RightPage:UpdateSize()
			end
		end

	elseif Direction < 0 and (CurrentPage == 1 or #CurrentGroup.Elements == 0) then
		CurrentPage = 1
		-- move to previous group
		local group = CurrentGroup:PrevGroup()
		if group then
			RightPage.Text = CurrentGroup.Name .. " >>>"
			RightPage:UpdateSize()
			CurrentGroup = group
			CurrentPage = 1

			group = group:PrevGroup()
			if group then
				LeftPage.Text = "<<< " .. group.Name
				LeftPage:UpdateSize()
			else
				LeftPage.Text = " "
				LeftPage:UpdateSize()
			end
		end

	elseif Direction > 0 then
		CurrentPage = CurrentPage + 1
	elseif Direction < 0 then
		CurrentPage = CurrentPage - 1
	else
		local group = CurrentGroup:PrevGroup()
		if group then
			LeftPage.Text = "<<< " .. group.Name
			LeftPage:UpdateSize()
		else
			LeftPage.Text = " "
			LeftPage:UpdateSize()
		end
		local group = CurrentGroup:NextGroup()
		if group then
			RightPage.Text = group.Name .. " >>>"
			RightPage:UpdateSize()
		else
			RightPage.Text = " "
			RightPage:UpdateSize()
		end
	end
end

LeftPage = UIUtils.SimpleText(Multiplayer.UI_SCREEN, "none", 60, 400, nil,
	function()
		return SettignsOpen
	end,
	function()
		Show(true, -1)
	end,
	false)

RightPage = UIUtils.SimpleText(Multiplayer.UI_SCREEN, "none", 320, 400, nil,
	function()
		return SettignsOpen
	end,
	function()
		Show(true, 1)
	end,
	false)

---

local function StdCond(Group, Id)
	return function()
		return SettignsOpen and Group == CurrentGroup and math.ceil(Id / MaxOnPage) == CurrentPage
	end
end

local function CustomHeader(Group, Text)
	local Id = #Group.Elements + 1
	local Y = BaseY + #Group.Elements % MaxOnPage * Shift
	local Header = UIUtils.SimpleText(Multiplayer.UI_SCREEN, StrColor(235,235,50, Text), BaseX, Y, nil, StdCond(Group, Id))
	Group.Elements[Id] = Header
	return Header
end

local function CustomSwitch(Group, Header, Parent, Field, OnSwitch)
	local Id = #Group.Elements + 1
	local Y = BaseY + #Group.Elements % MaxOnPage * Shift
	local Switch = UIUtils.CustomSwitch(Multiplayer.UI_SCREEN, BaseX, Y, StdCond(Group, Id), Header, Parent, Field, OnSwitch)
	Group.Elements[Id] = Switch
	return Switch
end

local function CustomNumeric(Group, Header, Parent, Field, Step, Low, High)
	local Id = #Group.Elements + 1
	local Y = BaseY + #Group.Elements % MaxOnPage * Shift
	local Option = UIUtils.CustomNumeric(Multiplayer.UI_SCREEN, BaseX, Y, StdCond(Group, Id), Header, Parent, Field, Step, Low, High)
	Group.Elements[Id] = Option
	return Option
end

local function CustomListSwitch(Group, Header, List, OnSwitch)
	local Id = #Group.Elements + 1
	local Y = BaseY + #Group.Elements % MaxOnPage * Shift
	local Switch = UIUtils.CustomListSwitch(Multiplayer.UI_SCREEN, BaseX, Y, StdCond(Group, Id), Header, List, OnSwitch)
	Group.Elements[Id] = Switch
	return Switch
end

local function TextInput(Group, Header, DefaultText, OnSymbol, OnEnter, UpdateText)
	local Id = #Group.Elements + 1
	local Y = BaseY + #Group.Elements % MaxOnPage * Shift
	local Widget = UIUtils.ANCIITextInput(Multiplayer.UI_SCREEN, BaseX, Y, StdCond(Group, Id), Header, DefaultText, OnSymbol, OnEnter)
	Widget.Update = UpdateText

	Group.Elements[Id] = Widget
	return Widget
end

local function KeyInput(Group, Header, DefaultText, OnSymbol, OnEnter, UpdateText)
	local Id = #Group.Elements + 1
	local Y = BaseY + #Group.Elements % MaxOnPage * Shift
	local Widget = UIUtils.ANCIIKeyInput(Multiplayer.UI_SCREEN, BaseX, Y, StdCond(Group, Id), Header, DefaultText, OnSymbol, OnEnter)
	Widget.Update = UpdateText

	Group.Elements[Id] = Widget
	return Widget
end

local function NextGroup(Group)
	if Group.Order[1] then
		return Group.Order[1]
	end

	local id = table.find(Group.Parent.Order, Group)
	if Group.Parent.Order[id + 1] then
		return Group.Parent.Order[id + 1]
	end

	return nil
end

local function PrevGroup(Group)
	if not Group.Parent then
		return nil
	end

	local id = table.find(Group.Parent.Order, Group)
	if Group.Parent.Order[id - 1] then
		return Group.Parent.Order[id - 1]
	end

	return Group.Parent
end

local function Update(Group)
	for _, v in pairs(Group.Elements) do
		if v.Update then
			v:Update()
		end
	end
	for _, v in pairs(Group.Groups) do
		v:Update()
	end
end

local function Group(Parent, Name, Header)
	if Parent.Groups[Name] then
		return Parent.Groups[Name]
	end

	local group = {
		Parent = Parent,
		Name = Name,
		Elements = {},
		Groups = {},
		Order = {},

		Group = Group,
		Header = CustomHeader,
		Switch = CustomSwitch,
		Numeric = CustomNumeric,
		ListSwitch = CustomListSwitch,
		TextInput = TextInput,
		KeyInput = KeyInput,
		Update = Update,

		NextGroup = NextGroup,
		PrevGroup = PrevGroup
	}

	if Header then
		group:Header(Header)
	end

	Parent.Groups[Name] = group
	Parent.Order[#Parent.Order + 1] = group
	return group
end

Group({Groups = Groups, Order = {}}, "main")
Groups["main"].Parent = nil
Groups["main"].Name = "General settings"
DefaultNewGroup = Groups["main"]

-- Backwards compatibility

local function _Group(Name, Header)
	if Name == "main" then
		return Groups["main"]
	end
	return Group(Groups["main"], Name, Header)
end

local function NewPage(Name)
	DefaultNewGroup = _Group(Name)
	return 0
end

local function _CustomHeader(Text)
	return CustomHeader(DefaultNewGroup, Text)
end

local function _CustomSwitch(Header, Parent, Field, OnSwitch)
	return CustomSwitch(DefaultNewGroup, Header, Parent, Field, OnSwitch)
end

local function _CustomNumeric(Header, Parent, Field, Step, Low, High)
	return CustomNumeric(DefaultNewGroup, Header, Parent, Field, Step, Low, High)
end

local function _CustomListSwitch(Header, List, OnSwitch)
	return CustomListSwitch(DefaultNewGroup, Header, List, OnSwitch)
end

local function _TextInput(Header, DefaultText, OnSymbol, OnEnter, UpdateText)
	return TextInput(DefaultNewGroup, Header, DefaultText, OnSymbol, OnEnter, UpdateText)
end

local function _KeyInput(Header, DefaultText, OnSymbol, OnEnter, UpdateText)
	return KeyInput(DefaultNewGroup, Header, DefaultText, OnSymbol, OnEnter, UpdateText)
end

local function _Update()
	for _, v in pairs(Groups) do
		v:Update()
	end
end

events.MultiplayerExtraSettingsOpen = _Update

UIUtils.CustomSettings =  {
	NewPage = NewPage,
	Show = Show,
	Update = _Update,
	Header = _CustomHeader,
	Switch = _CustomSwitch,
	Numeric = _CustomNumeric,
	ListSwitch = _CustomListSwitch,
	TextInput = _TextInput,
	KeyInput = _KeyInput,
	Groups = Groups,
	Group = _Group,
}

return UIUtils.CustomSettings
