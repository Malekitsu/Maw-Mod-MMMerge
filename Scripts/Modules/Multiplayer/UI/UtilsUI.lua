local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer

local COL_STD, COL_ACTIVE = 0xFFDF, 0xe664

local function TextTumbler(Screen, X, Y, HeaderText, OnText, OffText, State, Action, Condition, AlignLeft)
	local tumbler = {On = false}

	if AlignLeft == nil then
		AlignLeft = true
	end

	tumbler.set_state = function(state)
		if state then
			tumbler.On = true
			tumbler.OnText.CStd = COL_ACTIVE
			tumbler.OffText.CStd = COL_STD
		else
			tumbler.On = false
			tumbler.OnText.CStd = COL_STD
			tumbler.OffText.CStd = COL_ACTIVE
		end
	end

	tumbler.handler = function(t)
		if not t then
			tumbler.OnText.CStd = tumbler.On and COL_ACTIVE or COL_STD
			tumbler.OffText.CStd = tumbler.On and COL_STD or COL_ACTIVE
		else
			tumbler.set_state(t == tumbler.OnText)
		end
		if Action then
			Action(tumbler)
		end
	end

	if HeaderText then
		tumbler.HeaderText = CustomUI.CreateText{
			Text = HeaderText,
			Font = Game.Arrus_fnt,
			ColorStd = COL_STD,
			Layer = 1,
			Screen = Screen,
			Condition = Condition,
			AlignLeft = AlignLeft,
			X = X,
			Y = Y}

		X = X + tumbler.HeaderText.Wt + 2
	end

	tumbler.OnText = CustomUI.CreateText{
		Text = OnText,
		Font = Game.Arrus_fnt,
		ColorStd = State and COL_ACTIVE or COL_STD,
		ColorMouseOver = COL_ACTIVE,
		Layer = 1,
		Screen = Screen,
		Condition = Condition,
		AlignLeft = AlignLeft,
		Action = tumbler.handler,
		X = X,
		Y = Y}

	tumbler.OnText.Wt = math.max(tumbler.OnText.Wt, 32)

	tumbler.Splitter = CustomUI.CreateText{
		Text = "/",
		Font = Game.Arrus_fnt,
		ColorStd = COL_STD,
		Layer = 1,
		Screen = Screen,
		Condition = Condition,
		AlignLeft = AlignLeft,
		X = X + tumbler.OnText.Wt + 2,
		Y = Y}

	tumbler.OffText = CustomUI.CreateText{
		Text = OffText,
		Font = Game.Arrus_fnt,
		ColorStd = State and COL_STD or COL_ACTIVE,
		ColorMouseOver = COL_ACTIVE,
		Layer = 1,
		Screen = Screen,
		Condition = Condition,
		AlignLeft = AlignLeft,
		Action = tumbler.handler,
		X = X + tumbler.OnText.Wt + 16,
		Y = Y}

	tumbler.OffText.Wt = math.max(tumbler.OffText.Wt, 32)

	return tumbler
end

local function TextRadio(Screen, X, Y, HeaderText, States, Action, Condition)
	assert(#States > 0)

	local tumbler = {On = false}

	tumbler.handler = function(t)
		tumbler.state = t.Text
		for i, v in ipairs(tumbler) do
			if v.Text == t.Text then
				v.CStd = COL_ACTIVE
			else
				v.CStd = COL_STD
			end
		end
		if Action then
			Action(t.Text)
		end
	end

	tumbler.set = function(state)
		for i, v in ipairs(tumbler) do
			if v.Text == state then
				tumbler.handler(v)
				break
			end
		end
	end

	local last_element

	if HeaderText then
		last_element = CustomUI.CreateText{
			Text = HeaderText,
			Font = Game.Arrus_fnt,
			ColorStd = COL_STD,
			Layer = 1,
			Screen = Screen,
			Condition = Condition,
			AlignLeft = true,
			X = X,
			Y = Y}

		tumbler.HeaderText = last_element
	end

	tumbler.splitters = {}

	for i, state in ipairs(States) do
		last_element = CustomUI.CreateText{
			Text = state,
			Font = Game.Arrus_fnt,
			ColorStd = COL_STD,
			ColorMouseOver = COL_ACTIVE,
			Layer = 1,
			Screen = Screen,
			Condition = Condition,
			--AlignLeft = true,
			Action = tumbler.handler,
			X = last_element and last_element.X + last_element.Wt + 2 or X,
			Y = Y}

		last_element.Wt = math.max(last_element.Wt, 48)
		table.insert(tumbler, last_element)

		if i ~= #States then
			last_element = CustomUI.CreateText{
				Text = "/",
				Font = Game.Arrus_fnt,
				ColorStd = COL_STD,
				Layer = 1,
				Screen = Screen,
				Condition = Condition,
				--AlignLeft = true,
				X = last_element.X + last_element.Wt + 2 ,
				Y = Y}

			table.insert(tumbler.splitters, last_element)
		end
	end

	tumbler.state = tumbler[1].Text
	tumbler[1].CStd = COL_ACTIVE

	return tumbler
end

local TextCounter = 0
local function SimpleText(Screen, Text, X, Y, Font, Condition, Action, AlignLeft, Layer)
	TextCounter = TextCounter + 1

	if AlignLeft == nil then
		AlignLeft = true
	end

	return CustomUI.CreateText{
		Key = "MUI_" .. tostring(TextCounter),
		Text = Text,
		Font = Font or Game.Arrus_fnt,
		X = X, Y = Y,
		ColorStd = COL_STD,
		ColorMouseOver = Action and COL_ACTIVE or COL_STD,
		Layer = Layer or 1,
		Screen = Screen,
		AlignLeft = AlignLeft,
		Condition = Condition,
		Action = Action
	}
end

-----------------------------------
-- Custom value regulators

local function CustomSwitch(Screen, X, Y, Condition, Header, Parent, Field, OnSwitch)
	local function FetchParent(self)
		if type(self.FlagSource.Parent) == 'function' then
			return self.FlagSource.Parent()
		end
		return self.FlagSource.Parent
	end

	local function SwitchAction(self)
		local src = self.FlagSource
		self:FetchParent()[src.Field] = self.On
		if self.OnSwitch then
			self:OnSwitch()
		end
	end

	local function Update(self)
		local src = self.FlagSource
		self.On = self:FetchParent()[src.Field]
		self.handler(self.On and self.OnText or self.OffText)
	end

	local Switch = TextTumbler(Screen, X, Y, Header, "On", "Off",
		true,
		SwitchAction,
		Condition)

	Switch.FlagSource = {Parent = Parent, Field = Field}
	Switch.Update = Update
	Switch.FetchParent = FetchParent
	Switch.OnSwitch = OnSwitch

	return Switch
end

local function CustomNumeric(Screen, X, Y, Condition, Header, Parent, Field, Step, Low, High, OnChange)
	local Option = {ValueSource = {Parent = Parent, Field = Field}, Step = Step, Low = Low, High = High, OnChange = OnChange}

	local function Handler(self, side)
		local src = self.ValueSource
		local val = src.Parent[src.Field] + self.Step * side

		val = math.max(val, self.Low)
		val = math.min(val, self.High)
		val = math.round(val * 100) / 100

		src.Parent[src.Field] = val
		self.Value.Text = " " .. tostring(val)
		self.Value:UpdateSize()

		if self.OnChange then
			self:OnChange(val)
		end
	end

	local function Update(self)
		local src = self.ValueSource
		local val = src.Parent[src.Field]
		val = math.round(val * 100) / 100
		self.Value.Text = " " .. tostring(val)
	end

	Option.Header = SimpleText(Screen, Header, X, Y, nil, Condition)

	Option.Left = SimpleText(Screen, "<",
		X + Option.Header.Wt, Y, nil, Condition, function() Handler(Option, -1) end, false)

	Option.Value = SimpleText(Screen, " " .. tostring(Parent[Field]),
		Option.Left.X + Option.Left.Wt + 16, Y, nil, Condition, nil, false)

	Option.Right = SimpleText(Screen, ">",
		Option.Value.X + Option.Value.Wt + 16, Y, nil, Condition, function() Handler(Option, 1) end, false)

	Option.Update = Update

	return Option
end

local function CustomListSwitch(Screen, X, Y, Condition, Header, List, OnSwitch)
	local Option = {Step = 1, List = List, OnSwitch = OnSwitch}

	local Wt = 0
	local Template = ""
	for _, v in pairs(List) do
		if #v > Wt then
			Wt = #v
			Template = v
		end
	end

	local function Handler(self, side)
		self.Step = self.Step + side
		if self.Step <= 0 then
			self.Step = #self.List
		elseif self.Step > #self.List then
			self.Step = 1
		end

		self.Value.Text = " " .. tostring(self.List[self.Step])
		self.Value:UpdateSize(20)

		if self.OnSwitch then
			self:OnSwitch(self.List[self.Step])
		end
	end

	local function Update(self)
		local val = self.List[self.Step]
		if not val then
			self.Step = 1
			val = self.List[self.Step]
		end

		self.Value.Text = " " .. tostring(self.List[self.Step])
		self.Value:UpdateSize(20)
	end

	if Header then
		Option.Header = SimpleText(Screen, Header, X, Y, nil, Condition)
	end

	Option.Left = SimpleText(Screen, "<",
		X + Option.Header.Wt, Y, nil, Condition, function() Handler(Option, -1) end, false)

	Option.Value = SimpleText(Screen, Template, Option.Left.X + Option.Left.Wt + 16, Y, nil, Condition, nil, true)

	Option.Right = SimpleText(Screen, ">",
		Option.Value.X + Option.Value.Wt + 16, Y, nil, Condition, function() Handler(Option, 1) end, false)

	Option.Update = Update
	Option:Update()
	return Option
end

-----------------------------------
-- Text input

local ActiveTextInput = nil

function events.KeyDown(t)
	if not ActiveTextInput then
		return
	end

	if Game.CurrentScreen ~= ActiveTextInput.Screen then
		ActiveTextInput:Discard()
		ActiveTextInput = nil
		return
	end

	t.Handled = true

	local Key = t.Key
	if Key >= 96 and Key <= 105 then -- treat numpad keys as numbers
		Key = Key - 48
	end

	if Key == const.Keys.ENTER then
		ActiveTextInput:Apply()
		ActiveTextInput = nil
	elseif Key == const.Keys.ESCAPE then
		ActiveTextInput:Discard()
		ActiveTextInput = nil
	elseif Key == const.Keys.BACKSPACE then
		ActiveTextInput:EraseLast()
	elseif Key >= 48 and Key <= 90 then
		ActiveTextInput:OnSymbol(string.char(Key))
	end
end

local function ANCIITextInput(Screen, X, Y, Condition, Header, DefaultText, SymbolCheck, OnEdit, Layer)
	local TextInput = {}
	TextInput.SymbolCheck = SymbolCheck
	TextInput.OnEdit = OnEdit
	TextInput.DefaultText = DefaultText
	TextInput.Screen = Screen

	local function OnSymbol(self, symbol)
		if self.SymbolCheck and not self:SymbolCheck(symbol) then
			return
		end
		self.TmpInput = self.TmpInput .. symbol
		self.Input.Text = self.TmpInput
		self.Input:UpdateSize(12)
	end
	TextInput.OnSymbol = OnSymbol

	local function EraseLast(self)
		self.TmpInput = self.TmpInput:sub(1, -2)
		self.Input.Text = self.TmpInput
	end
	TextInput.EraseLast = EraseLast

	local function Discard(self)
		self:EndInput()
	end
	TextInput.Discard = Discard

	local function Apply(self)
		if self.OnEdit and not self:OnEdit(self.TmpInput) then
			self:Discard()
			return
		end
		self.Value = self.TmpInput
		self:EndInput()
	end
	TextInput.Apply = Apply

	local function StartInput(self)
		if ActiveTextInput then
			ActiveTextInput:Apply()
		end
		ActiveTextInput = TextInput
		TextInput.Input.CStd = COL_ACTIVE
		TextInput.TmpInput = TextInput.Value
	end
	TextInput.StartInput = StartInput

	local function EndInput(self)
		self.Input.Text = #self.Value > 0 and self.Value or self.DefaultText
		self.TmpInput = ""
		self.Input.CStd = COL_STD
		self.Input:UpdateSize(12)
	end
	TextInput.EndInput = EndInput

	TextInput.Header = SimpleText(Screen, Header, X, Y, nil, Condition, nil, true, Layer)
	TextInput.Input = SimpleText(Screen, DefaultText, X + TextInput.Header.Wt, Y, nil, Condition, StartInput, nil, Layer)
	TextInput.Value = DefaultText

	return TextInput
end

local function ANCIIKeyInput(Screen, X, Y, Condition, Header, DefaultText, SymbolCheck, OnEdit)
	local TextInput = ANCIITextInput(Screen, X, Y, Condition, Header, DefaultText, SymbolCheck, OnEdit)

	TextInput.TmpCtrl = false
	TextInput.Ctrl = false

	local function OnSymbol(self, symbol)
		if self.SymbolCheck and not self:SymbolCheck(symbol) then
			return
		end
		self.TmpCtrl = Keys.IsPressed(const.Keys.CTRL)
		self.TmpInput = symbol
		self.Input.Text = (self.TmpCtrl and "ctrl + " or "") .. self.TmpInput
		self.Input:UpdateSize(12)
	end
	TextInput.OnSymbol = OnSymbol

	local function EraseLast(self)
		self.TmpInput = ""
		self.TmpCtrl = false
		self.Input.Text = self.TmpInput
	end
	TextInput.EraseLast = EraseLast

	local function Apply(self)
		if self.OnEdit and not self:OnEdit(self.TmpInput, self.TmpCtrl) then
			self:Discard()
			return
		end
		self.Value = self.TmpInput
		self.Ctrl = self.TmpCtrl
		self:EndInput()
	end
	TextInput.Apply = Apply

	local function StartInput(self)
		if ActiveTextInput then
			ActiveTextInput:Apply()
		end
		ActiveTextInput = TextInput
		TextInput.Input.CStd = COL_ACTIVE
		TextInput.TmpInput = ((TextInput.Ctrl and "ctrl + " or "") .. TextInput.Value)
	end
	TextInput.StartInput = StartInput

	local function EndInput(self)
		self.Input.Text = #self.Value > 0 and ((self.Ctrl and "ctrl + " or "") .. self.Value) or self.DefaultText
		self.TmpInput = ""
		self.Input.CStd = COL_STD
		self.Input:UpdateSize(12)
	end
	TextInput.EndInput = EndInput

	return TextInput
end

local function ConsoleInput(Screen, X, Y, Condition, Action, Header, Value, EmptyRepr, Layer, multiline)
	local function Remove(t)
		for _, v in pairs(t.Lines) do
			CustomUI.RemoveElement(v)
		end
		CustomUI.RemoveElement(t.Header)
	end

	local function SetValue(t, text)
		t.Value = text
		if #text == 0 then
			text = t.EmptyRepr or "ENTER VALUE"
		end

		local lines = string.split(text, "\n")
		if not multiline then
			t.Input.Text = lines[1]
			t.Input:UpdateSize(14)
		else
			for i, line in ipairs(lines) do
				local widget = t.Lines[i]
				if not widget then
					widget = SimpleText(Screen, line, X + t.Header.Wt, Y + (i-1)*16, nil, Condition, nil, true, Layer)
					t.Lines[i] = widget
				end
				widget.Text = line
				widget:UpdateSize(14)
			end
			for i = #lines + 1, #t.Lines do
				local widget = t.Lines[i]
				if widget then
					t.Lines[i] = nil
					CustomUI.RemoveElement(widget)
				end
			end
		end
	end

	local Tooltip = "Press CTRL+ENTER to finish input. Closing console will cause value to be cleared.\n"
	local t = {
		Value = Value,
		Tooltip = Tooltip,
		Lines = {},
		Remove = Remove,
		SetValue = SetValue
	}

	local function action()
		internal.DebugConsoleAnswer(t.Value, -1)
		local text = internal.DebugConsole(t.Tooltip, (internal.IsTopmost or internal.IsFullScreen)(), "Multiplayer") or ""
		internal.DebugConsole(nil, false, "Multiplayer")
		if Action then
			Action(text)
		end
		t:SetValue(text)
	end

	t.EmptyRepr = EmptyRepr
	t.Header = SimpleText(Screen, Header, X, Y, nil, Condition, action, true, Layer)
	t.Input = SimpleText(Screen, "", X + t.Header.Wt, Y, nil, Condition, nil, true, Layer)
	t:SetValue(Value)

	return t
end


local MMTextInputActive = nil
local function MMTextInput(Screen, X, Y, Condition, Action, Header, Value, EmptyRepr, Layer, multiline, hidden, limit)
	local function Remove(t)
		CustomUI.RemoveElement(t.Header)
		CustomUI.RemoveElement(t.Input)
		CustomUI.RemoveElement(t.Show)
		Game.EndTextInput()
	end

	local function SetValue(t, text)
		t.Value = text

		if #text == 0 then
			text = t.EmptyRepr
		end

		if t.Hidden and #t.Value > 0 then
			t.Input.Text = string.gsub(text, "%w", "*")
		else
			t.Input.Text = text
		end
		t.Input:UpdateSize(14)
		t.Input.Wt = multiline and 500 or t.Input.Wt
	end

	local Tooltip = "Press CTRL+ENTER to finish input. Closing console will cause value to be cleared.\n"
	local t = {
		Value = Value,
		Tooltip = Tooltip,
		Remove = Remove,
		SetValue = SetValue,
		Hidden = hidden or false
	}

	local function RegisterInput(k)
		local last = false
		
		if MMTextInputActive ~= t then
			events.Remove("KeyDown", RegisterInput)
			return
		elseif k.Key == const.Keys.ENTER and multiline and Game.CtrlPressed then
			t.Handled = true
			mem.u1[0x6c8cd8 + mem.u2[0x6c8dd9]] = 0xa
		elseif Game.CurrentScreen ~= Screen 
			or k.Key == const.Keys.ESCAPE 
			or k.Key == const.Keys.LBUTTON 
			or k.Key == const.Keys.MBUTTON 
			or k.Key == const.Keys.ENTER then
			
			Game.EndTextInput()
			t.Header.CStd = COL_STD
			events.Remove("KeyDown", RegisterInput)
			last = true
		end

		Multiplayer.utils.delayed_call(function(last)
			t:SetValue(mem.string(0x6c8cd8))
			if t.Input.Text == t.EmptyRepr then
				t.Input.Text =  (last and t.EmptyRepr or "_")
			else
				t.Input.Text = t.Input.Text  .. (last and "" or "_")
			end
			t.Input:UpdateSize(14)
			if last then
				MMTextInputActive = nil
			end
		end, 2, last)
	end

	local function action()
		if MMTextInputActive == t then
			return
		elseif MMTextInputActive then
			MMTextInputActive:SetValue(MMTextInputActive.Value)
			MMTextInputActive.Header.CStd = COL_STD
		end

		events.KeyDown = RegisterInput
		Game.EndTextInput()
		Game.StartTextInput(limit and math.min(limit, 192) or 192)
		mem.copy(0x6c8cd8, t.Value, #t.Value)
		mem.u2[0x6c8dd9] = #t.Value
		t.Header.CStd = COL_ACTIVE
		if t.Input.Text == t.EmptyRepr then
			t.Input.Text =  "_"
		else
			t.Input.Text = t.Input.Text  .. "_"
		end
		t.Input:UpdateSize(14)

		MMTextInputActive = t
	end

	t.EmptyRepr = EmptyRepr or "ENTER VALUE"
	t.Show = SimpleText(Screen, "?", X - 10, Y, nil, Condition, function()
		t.Hidden = not t.Hidden
		t:SetValue(t.Value)
	end, true, Layer)
	t.Show.Active = hidden or false

	t.Header = SimpleText(Screen, Header, X, Y, nil, Condition, action, true, Layer)
	t.Input = SimpleText(Screen, "", X + (multiline and 0 or t.Header.Wt), Y + (multiline and 25 or 0), nil, Condition, nil, true, Layer)
	t:SetValue(Value)

	return t
end

-----------------------------------
-- Clipboard

local function GetClipboardData(fmt) -- possible fmt values: 1 - text, 7 - OEM text, 13 - UNICODE text,
	local user32 = mem.dll['user32']
	local result = 0
	if user32.OpenClipboard(Game.WindowHandle) ~= 0 then
		result = user32.GetClipboardData(fmt or 1)
		if result ~= 0 then
			if fmt == 7 then
				result = mem.string(u4[result])
			elseif fmt == 1 then
				result = mem.string(result)
			end
		end
		user32.CloseClipboard()
	end
	return result
end

local function SetClipboardData(fmt, bin_string)
	local user32 = mem.dll['user32']
	local result
	if user32.OpenClipboard(Game.WindowHandle) ~= 0 and user32.EmptyClipboard() ~= 0 then
		local kernel32 = mem.dll['kernel32']
		local handle = kernel32.GlobalAlloc(0x2, #bin_string + 1) -- 0x2 is GMEM_MOVEABLE flag
		mcopy(kernel32.GlobalLock(handle), bin_string)
		kernel32.GlobalUnlock(handle)

		result = user32.SetClipboardData(fmt or 1, handle)
		result = result ~= 0
		user32.CloseClipboard()
	end
	return result
end

local function GetClipboardText()
	local result = GetClipboardData(1)
	if type(result) == 'string' then
		return result
	end
	return ""
end

local function SetClipboardText(bin_string)
	return SetClipboardData(7, bin_string)
end

local function GetSessionCodeFromClipboard()
	local function f()
		local qtext = "\n-- Unable to fetch content from clipboard.\n-- Enter (or paste manually) session code and press Ctrl+Enter\n"
		local result = internal.DebugConsole(qtext, (internal.IsTopmost or internal.IsFullScreen)(), "Multiplayer")
		internal.DebugConsole(nil, false, "Multiplayer")
		return result or ""
	end

	local result = GetClipboardText()
	if #result == 0 then
		result = f()
	end
	return result
end

-----------------------------------
-- Monster icons

-- Unfortunately, i gave up on retreiving image from lod, thus fetching it from video memory...
local ddSDescr = mem.StaticAlloc(0x7c)
local function FetchSpriteImage(SFTId)
	if not Game.IsD3D then
		return nil
	end

	local SFT = Game.SFTBin[SFTId]
	local SpriteName = SFT.SpriteName
	if not SFT.Image1 then
		SpriteName = SpriteName .. "0"
	end
	local D3DId = Game.SpritesLod:LoadSprite(SpriteName, SFT.PaletteId)

	local ddSurface = u4[u4[0x72DC58] + D3DId * 0x28 + 0x8]
	if ddSurface == 0 then
		return {image = "", palette = "", width = 0, height = 0}
	end

	local ddSInterface = u4[ddSurface]
	local hres = 0

	mem.fill(ddSDescr, 0x7c, 0)
	u4[ddSDescr] = 0x7c

	-- ddSurface->GetSurfaceDesc(&descr)
	hres = mem.call(u4[ddSInterface + 0x58], 0, ddSurface, ddSDescr)
	if hres ~= 0 then return hres end

	-- ddSurface->Lock(NULL, &descr, DDLOCK_NOSYSLOCK | DDLOCK_READONLY, NULL)
	hres = mem.call(u4[ddSInterface + 0x64], 0, ddSurface, 0, ddSDescr, 0x810, 0)
	if hres ~= 0 then return hres end

	local image = u4[ddSDescr+0x24]
	local height, width  = u4[ddSDescr+0x8], u4[ddSDescr+0xC]
	local size = height * width

	-- build palette
	local palette = {}
	local color, num = 0, 0
	for pos = image, image + size * 2, 2 do
		color = u2[pos]
		if not palette[color] then
			palette[color] = num
			num = num + 1
		end
	end

	-- make indexed bitmap
	--local buff = mem.malloc(math.max(size, 512) + 0x10)
	local buff_str = mstr(image, math.max(size, 512), true)
	local buff = toptr(buff_str)
	for i = 0, size do
		color = u2[i*2 + image]
		u1[buff + i] = palette[color]
	end
	local bitmap = mstr(buff, size, true)
	bitmap = bitmap .. '\0' -- force copy

	-- dump palette
	mem.fill(buff, 512, 0)
	for i = 0, 256 do
		color = table.find(palette, i)
		if not color then break end
		u2[buff + i * 2] = color
	end

	-- convert pixel format from 1555 to 565
	local And, Or, shl, shr = bit.And, bit.Or, bit.lshift, bit.rshift
	local color, R, G, B
	for ptr = buff, buff + (num + 1)*2, 2 do
		color = u2[ptr]
		R, G, B = And(color, 0x7c00), And(color, 0x3e0), And(color, 0x1f)
		G = shl(math.ceil(shr(G, 5) / 31 * 63), 5)
		u2[ptr] = Or(Or(B, G), shl(R, 1))
	end

	local pal = mstr(buff, 512, true)
	pal = pal .. '\0' -- force copy

	-- ddSurface->Unlock(NULL);
	mem.call(u4[ddSInterface + 0x80], 0, ddSurface, 0)
	--mem.free(buff) -- gives unpredictable crashes, thus using lua string as buffer

	return {image = bitmap, palette = pal, width = width, height = height}
end

-----------------------------------
-- Text table

local function TextTable(Screen, Columns, X, Y, Condition, Actions, MaxLinesOnPage)
	local ctable = {
		columns = Columns,
		X = X, Y = Y,
		lines = {},
		data = {},
		actions = Actions or {},
		viewLimit = MaxLinesOnPage or math.ceil((480 - Y) / 25 - 3),
		page = 1}

	ctable.AGen = function(col, data)
		local f = ctable.actions[col]
		if f then
			return function()
				f(data)
			end
		end
		return nil
	end

	ctable.pages_count = function(ctable)
		return (#ctable.lines / ctable.viewLimit):ceil()
	end

	ctable.new_line = function(ctable, source)
		local line = {}
		local shift = (ctable.page - 1) * ctable.viewLimit
		local X, Y = ctable.X, ctable.Y + (#ctable.lines - shift) * 25
		local last
		local i = #ctable.lines + 1
		for _, col in pairs(Columns) do
			last = SimpleText(Screen, tostring(source[col] or ""), X, Y, Game.Smallnum_fnt, Condition, ctable.AGen(col, source), true)
			last.Wt = last.Wt + 10
			last.Active = i > shift and i <= (shift + ctable.viewLimit)
			line[col] = last
			X = X + last.Wt
		end
		table.insert(ctable.lines, line)
		table.insert(ctable.data, source)
		ctable.pageControl.High = ctable:pages_count()
		return line, #ctable.lines
	end

	ctable.remove_iline = function(ctable, i, supress_update)
		local line = ctable.lines[i]
		if line then
			for k, v in pairs(line) do
				CustomUI.RemoveElement(v)
			end
			table.remove(ctable.lines, i)
			table.remove(ctable.data, i)
			if not supress_update then
				ctable:update()
			end
			ctable.pageControl.High = ctable:pages_count()
		end
	end
	
	ctable.clear = function(ctable)
		while #ctable.data > 0 do
			ctable:remove_iline(1, true)
		end
		ctable:update()
	end

	ctable.remove_line = function(ctable, line, supress_update)
		local n = table.find(ctable.lines, line)
		if n then
			ctable:remove_iline(n, supress_update)
		end
	end

	ctable.iupdate = function(ctable, i)
		local line = ctable.lines[i]
		if not line then
			return
		end

		local shift = (ctable.page - 1) * ctable.viewLimit
		local visible = i > shift and i <= (shift + ctable.viewLimit)

		local Y = ctable.Y + (i - 1 - shift) * 25
		for k, v in pairs(line) do
			v.Active = visible
			v.Y = Y
			local data = ctable.data[i]
			if data then
				v.Text = tostring(data[k])
			end
		end
	end

	ctable.update = function(ctable)
		for i, _ in pairs(ctable.lines) do
			ctable:iupdate(i)
		end
		ctable.pageControl.High = ctable:pages_count()
	end

	ctable.load = function(ctable, data)
		local n = 1
		ctable.data = {}
		for _, source in pairs(data) do
			local line = ctable.lines[n]
			if line then
				for col, widget in pairs(line) do
					widget.Text = tostring(source[col])
					widget.Act = ctable.AGen(col, source)
				end
			else
				ctable:new_line(source)
			end
			ctable.data[n] = source
			n = n + 1
		end

		for i = #data + 1, #ctable.lines do
			ctable:remove_iline(i, true)
		end
		ctable:update()
	end

	ctable.pageControl = CustomNumeric(
		Screen,
		ctable.X,
		ctable.Y + ctable.viewLimit * 25,
		function() return #ctable.lines > ctable.viewLimit and (not Condition or Condition()) end,
		" Page",
		ctable,
		"page", 1, 1, ctable:pages_count(),
		function(widget, val)
			ctable:update()
		end
	)

	return ctable
end

-----------------------------------
-- Popup input
-- Opens overlay window with chosen input elements, have two buttons: accept, cancel, OnAccept calls func with chosen values in input elements
local PopupScreen = CustomUI.NewScreen(nil, "PopupInput")
local HeightPlaceholder = "\n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n  \n"
local function PopupInput(Header, Text, Inputs, AcceptText, CancelText, OnAccept, OnCancel, BGPic)
	local TextInputs = {}
	local elements = {}
	local Header = (Header or "") .. HeightPlaceholder
	local FromScreen = Game.CurrentScreen

	local function clear()
		for _, t in pairs(elements) do
			CustomUI.RemoveElement(t)
		end
		for _, t in pairs(TextInputs) do
			t:Remove()
		end
		Game.CurrentScreen = FromScreen
	end
	OnAccept = OnAccept or function() return nil end
	OnCancel = OnCancel or function() return nil end

	local function ShowBG()
		if Keys.IsPressed(const.Keys.ESCAPE) then
			OnCancel()
			clear()
			return false
		end
		CustomUI.ShowTooltip(Header, 50, 50, 540)
		return true
	end

	elements.block = CustomUI.CreateIcon{
		Icon = BGPic or "TPGlobal",
		Key = "PopupInputBG",
		X = 0,
		Y = 0,
		Layer = 1,
		BlockBG = true,
		Screen = PopupScreen}

	elements.text = SimpleText(PopupScreen, Text or "", 80, 100, nil, ShowBG, nil, true, 1)
	elements.text.Wt = 480

	if Inputs then
		for i, v in ipairs(Inputs) do
			TextInputs[v.header] = MMTextInput(PopupScreen, 80, 120 + elements.text.Ht + i*20, nil, nil, (" %s "):format(v.header), v.default, v.empty, 0, v.multiline, v.hidden, v.limit)
		end

		local _OnAccept = OnAccept
		OnAccept = function()
			local values = {}
			for header, input in pairs(TextInputs) do
				values[header] = input.Value
			end
			_OnAccept(values)
		end
	end

	elements.accept = SimpleText(PopupScreen, AcceptText or "Accept", 100, 360, nil, nil, function() clear(); OnAccept() end, true, 0)
	elements.cancel = SimpleText(PopupScreen, CancelText or "Cancel", 480, 360, nil, nil, function() clear(); OnCancel() end, true, 0)

	Game.CurrentScreen = PopupScreen
end

-----------------------------------
-- Popup progress
-- controlled by calling code, can be used to block user's action, while important operation ongoing, without freezing game
-- takes coroutine, that can yield progress text, when coroutine dies, popup closes itself
local function PopupProgress(Header, Text, Routine, Period, Timeout, UntillEvent, BGPic)

	local function clear(t)
		if t.closed then
			return
		end
		t.closed = true
		for _, v in pairs(t.Elements) do
			CustomUI.RemoveElement(v)
		end
		if Game.CurrentScreen == PopupScreen then
			Game.CurrentScreen = t.FromScreen
		end
	end

	local t = {
		FromScreen = Game.CurrentScreen,
		Header = (Header or "") .. HeightPlaceholder,
		Elements = {},
		Interrupt = false,
		clear = clear,
		closed = false
	}

	local function ShowBG()
		CustomUI.ShowTooltip(t.Header, 50, 50, 540)
		return true
	end

	t.Elements.block = CustomUI.CreateIcon{
		Icon = BGPic or "TPGlobal",
		Key = "PopupInputBG",
		X = 0,
		Y = 0,
		Layer = 1,
		BlockBG = true,
		Screen = PopupScreen
	}

	t.Elements.text = SimpleText(PopupScreen, Text or "", 50, 220, nil, ShowBG, nil, false, 0)
	t.Elements.text.Wt = 540

	local interrupt = false
	local function tick()
		local ended, text = Routine()
		if text then
			t.Elements.text.Text = text
		end
		if ended or t.Interrupt then
			t:clear()
			return true
		end
	end
	local cof = function()
		while true do
			if tick() then
				return
			end
			coroutine.yield()
		end
	end

	Game.CurrentScreen = PopupScreen
	if tick() then
		t:clear()
		return t
	end
	Multiplayer.utils.CoMillisecCounter(coroutine.create(cof), Period)

	local canceler
	if UntillEvent then
		canceler = Multiplayer.events.Once(UntillEvent, function() t:clear() end)
	end

	if Timeout then
		Multiplayer.utils.delayed_call2(
		function()
			if canceler then
				Multiplayer.events.Remove(UntillEvent, canceler)
			end
			t:clear()
		end, Timeout or 15000)
	end

	return t
end

-----------------------------------

return {
	TextTable = TextTable,
	TextTumbler = TextTumbler,
	TextRadio = TextRadio,
	SimpleText = SimpleText,
	GetClipboardData = GetClipboardData,
	SetClipboardData = SetClipboardData,
	GetClipboardText = GetClipboardText,
	SetClipboardText = SetClipboardText,
	GetSessionCodeFromClipboard = GetSessionCodeFromClipboard,
	FetchSpriteImage = FetchSpriteImage,
	CustomSwitch = CustomSwitch,
	CustomNumeric = CustomNumeric,
	CustomListSwitch = CustomListSwitch,
	ANCIITextInput = ANCIITextInput,
	ANCIIKeyInput = ANCIIKeyInput,
	PopupInput = PopupInput,
	PopupProgress = PopupProgress,
}
