local u1,u4,i1,i4,memstr = mem.u1,mem.u4,mem.i1,mem.i4,mem.string
local topointer = mem.topointer
local call = mem.call
local sqrt = math.sqrt

---- Base functions
CustomUI = {}

local PENDING = 0x70d624 -- default pending image ptr.
local Params = mem.StaticAlloc(128)

local PicStructPtr = Params
local ImageNamePtr = Params + 8
local PicX = Params + 16
local PicY = Params + 24

local TShadowColor = Params + 28
local Font = Params + 32
local Text = Params + 36
local LShift = Params + 40
local TColor = Params + 44

local TextParams = Params + 48
--TextX
--TextY
--TextWidth
--TextHeight
--TextUnk1
--TextUnk2

local SFTAnimActive = Params + 80
local SFTAnimParams = Params + 81
local SFTAnimName = Params + 101

local LoadIconAs = mem.asmproc([[

push 0
push 0
push 2
push dword[ds:]] .. ImageNamePtr .. [[]; ImageNamePtr
mov ecx, 0x70d3e8; Icons.LOD path
call absolute 0x410d70

lea eax, dword [ds:eax+eax*8]
lea eax, dword [ds:eax*8+0x70d624]

retn]]) -- returns pointer to icon struct.

local LoadDIconAs = mem.asmproc([[

push 1; Seek for image in EnglishD.
push 0
push 2
push dword[ds:]] .. ImageNamePtr .. [[]; ImageNamePtr
mov ecx, 0x70d3e8; Icons.LOD path
call absolute 0x410d70

lea eax, dword [ds:eax+eax*8]
lea eax, dword [ds:eax*8+0x70d624]

retn]]) -- returns pointer to icon struct.

local SetMaskAs = mem.asmproc([[

mov eax, dword [ds:]] .. PicStructPtr .. [[];
movzx edx, word [ds:eax+0x18]
movzx ecx, word [ds:eax+0x1a]
imul ecx, edx
mov eax, dword [ds:eax+0x30]
movzx edx, byte [ds:eax]
test edx, edx
je @end

@rep:
	cmp byte [ds:eax], dl
	jnz @next
	mov byte [ds:eax], 0

	@next:
	inc eax
	dec ecx
	jnz @rep

@end:
retn

]]) -- replacing mask (upper left pixel) color with 00.

local UnloadIconAs = mem.asmproc([[

mov ecx, dword[ds:]] .. PicStructPtr .. [[];
call absolute 0x410a10

retn]]) -- removing loaded icon from memory and clearing it's appearance.

local ShowIconAs = mem.asmproc([[
mov eax, dword [ds:]] .. PicStructPtr .. [[];
cmp byte [ds:eax+0xe], 1
jnz @Std

push 0

@Std:
push dword[ds:]] .. PicStructPtr .. [[];
push dword[ds:]] .. PicY .. [[];
push dword[ds:]] .. PicX .. [[];
mov ecx, 0xec1980

je @trn

call absolute 0x4a3cd5
jmp @end

@trn:
call absolute 0x4a419b

@end:
retn]])

local ShowTextAs = mem.asmproc([[
pushfd
pushad

mov ecx, ]] .. TextParams .. [[;
xor esi, esi
mov eax, dword [ds:ecx-0xC];
mov edx, dword [ds:ecx-0x10]; Font
push dword [ds:ecx-0x8];	Shift between lines
push eax; 	String
push dword [ds:ecx-0x4]; Color
push dword[ds:]] .. PicY .. [[]; Y offset (does not affect box)
push dword[ds:]] .. PicX .. [[]; X offset (does not affect box)
call absolute 0x44aae3

popad
popfd
retn]])

local ShowTextLeftAs = mem.asmproc([[
pushfd
pushad

mov ecx, ]] .. TextParams .. [[;
xor esi, esi
mov eax, dword [ds:ecx-0xC];
mov edx, dword [ds:ecx-0x10]; Font
push dword [ds:]] .. TShadowColor .. [[];
push esi
push dword [ds:ecx-0x8];	Shift between lines
push eax; 	String
push dword [ds:ecx-0x4]; Color
push dword[ds:]] .. PicY .. [[]; Y offset (does not affect box)
push dword[ds:]] .. PicX .. [[]; X offset (does not affect box)
call absolute 0x44a50f

popad
popfd
retn]])

-- takes text ptr, x, y, width
local TooltipFontOverride = mem.StaticAlloc(4)
function events.GameInitialized2()
	u4[TooltipFontOverride] = Game.Lucida_fnt
end

local ShowTooltipAs = mem.asmproc([[
push ebp
mov ebp, esp
sub esp, 0x78

mov eax, dword [ss:ebp+0x18]
mov dword [ds:]] ..TooltipFontOverride .. [[], eax;

lea ecx, [ebp-0x68]

mov eax, dword [ss:ebp+0x8]
mov dword [ds:ecx+0x48], eax;		text ptr

mov eax, dword [ss:ebp+0xC]
mov dword [ds:ecx], eax;	x

mov eax, dword [ss:ebp+0x10]
mov dword [ds:ecx+4], eax;	y

mov eax, dword [ss:ebp+0x14]
mov dword [ds:ecx+8], eax;	width

mov eax, dword [ss:ebp+0x1c]
mov dword [ds:ecx+0xC], eax; unk1

mov eax, dword [ss:ebp+0x20]
mov dword [ds:ecx+0x10], eax; unk2

mov eax, dword [ss:ebp+0x24]
mov dword [ds:ecx+0x14], eax; unk3

push 0x0; 0 - keep position, 1 - follow mouse
call absolute 0x414a61

mov eax, dword [ds:0x5DB91C]; Game.Lucida_fnt
mov dword [ds:]] ..TooltipFontOverride .. [[], eax;

add esp, 0x78
mov esp, ebp
pop ebp
retn 0x20]])

-- Allow tooltip header font override
for ptr, reg in pairs{[0x414b83] = 'ecx', [0x414bc8] = 'ecx', [0x414be6] = 'edx'} do
	mem.asmpatch(ptr, ("mov %s, dword [ds:%s]"):format(reg, TooltipFontOverride))
end

local function ShowTooltip(Text, X, Y, Width, Font, unk1, unk2, unk3)
	if type(Text) == "string" then
		Text = topointer(Text)
	end
	call(ShowTooltipAs, 0, Text, X, Y, Width, Font or Game.Lucida_fnt, unk1 or 0, unk2 or 0, unk3 or 0)
end
CustomUI.ShowTooltip = ShowTooltip

local function DisplayTooltip(Text, Timeout, X, Y, Width, Screen, Font)
	local Widget = CustomUI.CreateText{
		Text = Text,
		Font = Font,
		X = X or 160,
		Y = Y or 120,
		Width = Width or 320,
		Height = 320,
		Screen = Screen or Game.CurrentScreen,
		Condition = function(t)
			if Keys.IsPressed(const.Keys.LBUTTON) or os.time() > t.Timeout then
				CustomUI.RemoveElement(t)
			else
				ShowTooltip(t.Text, t.X, t.Y, t.Wt, t.Font)
			end
			return false
		end}

	Widget.Timeout = os.time() + (Timeout or 8)
	return Widget
end
CustomUI.DisplayTooltip = DisplayTooltip

local function FindIconPtr(Name)
	local ptr
	local low = string.lower
	Name = low(Name)
	for i = 0, 0x3e8 do
		ptr = i*72+0x70d624
		if low(memstr(ptr)) == Name then
			return ptr, i
		end
	end
	return nil
end
CustomUI.FindIconPtr = FindIconPtr

local function LoadIcon(Icon, Masked)
	local IconPtr
	if type(Icon) == "string" then
		u4[ImageNamePtr] = topointer(Icon)
	elseif type(Icon) == "number" then
		u4[ImageNamePtr] = Icon
	else
		return false
	end

	if Game.IconsLod.Bitmaps.count < 999 then
		IconPtr = call(LoadIconAs)
		if IconPtr == PENDING then
			IconPtr = call(LoadDIconAs)
		end

		if Masked then
			u4[PicStructPtr] = IconPtr
			call(SetMaskAs)
			u1[IconPtr+0xE] = 1
		end
	else
		return PENDING
	end
	return IconPtr
end
CustomUI.LoadIcon = LoadIcon

local function SetMask(bitmap) -- structs.LoadBitmap
	u4[PicStructPtr] = bitmap['?ptr']
	call(SetMaskAs)
	u1[bitmap['?ptr']+0xE] = 1
end
CustomUI.SetMask = SetMask

local function LoadIconToPos(Icon, Id, Masked)

	local NewPtr = Id*72 + 0x70d624
	local OldPtr = LoadIcon(Icon, Masked)

	mem.copy(NewPtr, OldPtr, 72)
	for i = 0, 17 do
		u4[OldPtr + i*4] = 0
	end

	return NewPtr
end
CustomUI.LoadIconToPos = LoadIconToPos

local function UnloadIcon(IconPtr)
	if IconPtr and type(IconPtr) == "number" then
		u4[PicStructPtr] = IconPtr
		return call(UnloadIconAs)
	end
	return false
end
CustomUI.UnloadIcon = UnloadIcon

local function ReplaceIcon(Old, New, Masked)
	local Ptr, Pos = FindIconPtr(Old)
	if Ptr then
		local Count = u4[0x71ef64]
		UnloadIcon(Ptr)
		LoadIconToPos(New, Pos, Masked)
		u4[0x71ef64] = Count -- count of loaded icons
	end
end
CustomUI.ReplaceIcon = ReplaceIcon

local function ShowIcon(Icon, X, Y)
	local IcType, IconPtr = type(Icon), nil
	if IcType == "number" then
		IconPtr = Icon
	elseif IcType == "string" then
		IconPtr = LoadIcon(Icon) -- in case icon is already in memory, function won't load it again, but return pointer to existing.
	else
		return false
	end

	u4[PicStructPtr] = IconPtr
	i4[PicX] = X or 0
	i4[PicY] = Y or 0

	call(ShowIconAs)
end
CustomUI.ShowIcon = ShowIcon

local function ShowText(Str, Fnt, X, Y, Shift, BoxWt, BoxHt, Xof, Yof, ColorStd, ColorShadow, AlignLeft, Unk1, Unk2)

	if not Str then
		return false
	end

	if not Fnt or Fnt == 0 then
		Fnt = Game.Arrus_fnt
	end

	u4[Text] = topointer(Str)
	u4[Font] = Fnt

	i4[TextParams] = X or 0
	i4[TextParams+0x4] = Y or 0
	i4[TextParams+0x8] = BoxWt or 0
	i4[TextParams+0xc] = BoxHt or 0
	i4[TextParams+0x10] = Unk1 or 0
	i4[TextParams+0x14] = Unk2 or 0

	i4[PicX] = Xof or 0
	i4[PicY] = Yof or 0

	i4[LShift] = Shift or 3
	u4[TColor] = ColorStd or 0xFFFF --0xe664
	u4[TShadowColor] = ColorShadow or 0

	if AlignLeft then
		call(ShowTextLeftAs)
	else
		call(ShowTextAs)
	end

end
CustomUI.ShowText = ShowText

local function MouseInBox(X,Y,W,H)
	return Mouse.X > X and Mouse.X < X + W and Mouse.Y > Y and Mouse.Y < Y + H
end
CustomUI.MouseInBox = MouseInBox

local function CoordsInBox(aX,aY,X,Y,W,H)
	return aX > X and aX < X + W and aY > Y and aY < Y + H
end
CustomUI.CoordsInBox = CoordsInBox

local function MouseInCircle(X,Y,R,Offset)
	if Offset then
		return R > sqrt((X+Offset-Mouse.X)^2 + (Y+Offset-Mouse.Y)^2)
	else
		return R > sqrt((X-Mouse.X)^2 + (Y-Mouse.Y)^2)
	end
end
CustomUI.MouseInCircle = MouseInCircle

local function CoordsInCircle(aX,aY,X,Y,R,Offset)
	if Offset then
		return R > sqrt((X+Offset-aX)^2 + (Y+Offset-aY)^2)
	else
		return R > sqrt((X-aX)^2 + (Y-aY)^2)
	end
end
CustomUI.CoordsInCircle = CoordsInCircle

-- "t" is animated icon (CreateIcon{})
local function StdAnimator(t)
	local CurT = timeGetTime()
	t.CurFrame = math.floor((CurT - t.StartTime)/t.Period + 1)
	if t.FramesCount < t.CurFrame then
		t.StartTime = CurT
		t.CurFrame = 1
	end
	return t.CurFrame
end
CustomUI.StdAnimator = StdAnimator

---- Elements
const.Screens.AdventurersInn = 29
const.Screens.Inventory2 = 15
const.Screens.SelectTarget = 20
const.Screens.SelectTarget2 = 23
const.Screens.LoadingScreen = 99
local ActiveElements = {}
local function NewScreen(Id, Name)
	if not Id then
		Id = 105
		while table.find(const.Screens, Id) do
			Id = Id + 1
		end
	end

	local Screen
	ActiveElements[Id] = ActiveElements[Id] or {}
	Screen = ActiveElements[Id]

	Screen.Texts 	= Screen.Texts or {[0] = {}, {}, {}, {}, {}}
	Screen.Icons	= Screen.Icons or {[0] = {}, {}, {}, {}, {}}
	Screen.Buttons 	= Screen.Buttons or {[0] = {}, {}, {}, {}, {}}

	if Name then
		const.Screens[Name] = Id
	end

	return Id
end
CustomUI.NewScreen = NewScreen

for k,v in pairs(const.Screens) do
	NewScreen(v)
end
CustomUI.ActiveElements = ActiveElements

local function AddElement(t)
	local Key = t.Key
	local ListName = t.Type .. "s"

	local KeyGen = {
		Icon    = function(t) return t.MainIcon .. t.X .. t.Y .. "_" .. t.Layer end,
		Text    = function(t) return (string.sub(t.Text, 1, 3) .. t.X .. t.Y .. "_" .. t.Layer) end,
		Button  = function(t) return t.IUpSrc .. t.X .. t.Y .. "_" .. t.Layer end,
	}

	if type(t.Screen) == "table" then
		if not Key then
			Key = KeyGen[t.Type](t)
			t.Key = Key
		end
		for k,v in pairs(t.Screen) do
			ActiveElements[v][ListName][t.Layer][Key] = t
		end
	else
		local List = ActiveElements[t.Screen][ListName][t.Layer]
		if not Key then
			Key = #List + 1
			t.Key = Key
		end
		List[Key] = t
	end
end

--[[ t - structure of settings:
-- IconUp			- string - item name form icons.lod
-- IconDown			- string - item name form icons.lod
-- IconMouseOver	- string - item name form icons.lod
-- Action			- function
-- MouseOverAction	- function
-- Condition		- function, which returns true if button can be shown
-- X				- number - upper left corner of image
-- Y				- number - upper left corner of image
-- Layer			- number (0 - front, 1 - middle, 2 - back, 3 - background, 4 - inventory (behind backhand))
-- Screen			- const.Screens or table
-- IsEllipse		- boolean - shape of button
-- BlockBG			- boolean - true if original mouse click actions should be interrupted by this element.
-- Active			- boolean - true if button must appear right now.]]
local function CreateButton(t)

	local MainIcon = t.IconUp or t.IconMouseOver or t.IconDown
	if not MainIcon then return false end

	t.X = t.X or 0
	t.Y = t.Y or 0

	local Layer = t.Layer or 0
	local Chk = MouseInBox
	local sChk = CoordsInBox
	local Active = t.Active
	local IUpPtr, IDwPtr, IMoPtr
	local Width, Height = 1, 1

	if Active == nil then Active = true end
	if t.DynLoad == nil then t.DynLoad = true end

	if t.DynLoad then
		IUpPtr, IDwPtr = 0, 0
	else
		IUpPtr = LoadIcon(t.IconUp or MainIcon, t.Masked)
		IDwPtr = LoadIcon(t.IconDown or MainIcon, t.Masked)
		if t.IconMouseOver then
			IMoPtr = LoadIcon(t.IconMouseOver or MainIcon, t.Masked)
		end

		Width, Height = mem.u2[IUpPtr+0x18], mem.u2[IUpPtr+0x1a]

		if t.IsEllipse then
			local R = Width/2
			Width  = R
			Height = R
			Chk = MouseInCircle
			sChk = CoordsInCircle
		end
	end

	local Settings = {
		IUpPtr = IUpPtr, IDwPtr = IDwPtr, IMoPtr = IMoPtr,
		IUpSrc = t.IconUp or MainIcon, IDwSrc = t.IconDown or MainIcon, IMoSrc = t.IconMouseOver,
		Masked = t.Masked, DynLoad = t.DynLoad,
		Act = t.Action, Cond = t.Condition,
		X = t.X, Y = t.Y, Wt = Width, Ht = Height, IsEllipse = t.IsEllipse,
		Layer 	= Layer,
		Screen	= t.Screen or 0,
		Active 	= Active,
		Pressed = false,
		MouseOver = false,
		MOAct	= t.MouseOverAction,
		Key 	= t.Key,
		Chk		= Chk,
		sChk	= sChk,
		BlockBG = t.BlockBG,
		Type 	= "Button"}


	AddElement(Settings)

	return Settings

end
CustomUI.CreateButton = CreateButton

--[[ Text 	 - string
-- Font		 - Game. ... _fnt
-- X 		 - number
-- Y		 - number
-- Unnecessary:
-- Layer	 - 0 - front, 1 - middle, 2 - back, 3 - behind main interface, 4 - inventory (behind backhand)
-- Screen	 - const.Screens
-- Condition - function
-- ColorStd 	  - number - def == 0 - black
-- ColorMouseOver - number - def == 0 - black
-- ColorShadow	  - number - def == 0 - black - color of shadow casted by text
-- Action		  - function - on click
-- BlockBG		  - boolean - true if original mouse click actions should be interrupted by this element.
-- Active		  - boolean
-- AlignLeft	  - boolean]]
local function CreateText(t)

	if type(t) ~= "table" or not t.Text then
		return false
	end

	local Active = t.Active

	if Active == nil then Active = true end

	if not t.ColorStd and t.R and t.G and t.B then
		t.ColorStd = RGB(t.R, t.G, t.B)
	end

	if not t.ColorMouseOver and t.Rm and t.Gm and t.Bm then
		t.ColorMouseOver = RGB(t.Rm, t.Gm, t.Bm)
	end

	local function UpdateSize(self, symbol_width, line_height)
		symbol_width = symbol_width or 10
		line_height = line_height or 16

		local n = #self.Text:split("\n")
		self.Wt = math.max(math.ceil(#self.Text * symbol_width / n), 32)
		self.Ht = line_height * n
	end

	local Settings = {Text = t.Text, X = t.X or 0, Y = t.Y or 0,
		Wt = t.Width or 0,
		Ht = t.Height or 0,
		Layer = t.Layer or 0, Cond = t.Condition,
		CStd = t.ColorStd or 0xFFFF,
		CMo = t.ColorMouseOver or 0xe664,
		CSh = t.ColorShadow or 0,
		Act = t.Action,
		AlignLeft = t.AlignLeft or false,
		HvAct	= type(t.Action) == "function",
		Pressed = false,
		Font  	= t.Font,
		Shift 	= t.Shift or 3,
		BlockBG = t.BlockBG,
		Active 	= Active,
		Screen 	= t.Screen or 0,
		Xof 	= t.Xof or 0,
		Yof 	= t.Yof or 0,
		Type 	= "Text"}

	Settings.UpdateSize = UpdateSize
	if Settings.Wt == 0 or Settings.Ht == 0 then
		Settings:UpdateSize()
	end

	Settings.Key = t.Key
	AddElement(Settings)

	return Settings

end
CustomUI.CreateText = CreateText

--[[ Icon 	- string (for static) or table of strings (for animated)
-- Condition- function
-- X 		- number
-- Y		- number
-- Layer	- number
-- Screen	- const.Screens
-- Active	- boolean
-- BlockBG	- boolean - true if original mouse click actions should be interrupted by this element.
-- for animated:
-- Period	- number - to define animation speed (in StdAnimator: higher - slower)
-- Animator - function(t) - which will return frame number, "t" is access to icon settings. Default - StdAnimator
--]]--
local function CreateIcon(t)

	if not t.Icon then
		return false
	end

	local Icon, MainIcon
	local Settings = {}
	local IsAnim = type(t.Icon) == "table"
	local Width, Height = 1, 1
	local Active = t.Active

	if Active == nil then Active = true end
	if t.DynLoad == nil then t.DynLoad = true end

	if IsAnim then
		Icon = {}
		MainIcon = t.Icon[1]
		for i, v in ipairs(t.Icon) do
			Icon[i] = {Fr = PENDING, Src = v} -- LoadIcon(v, t.Masked)
		end
		Settings.Period = t.Period or 25
		Settings.FramesCount = table.maxn(t.Icon)
		Settings.CurFrame = 1
		Settings.StartTime = timeGetTime()
		Settings.CF = t.Animator or StdAnimator
		Width, Height = mem.u2[Icon[1].Fr+0x18], mem.u2[Icon[1].Fr+0x1a]
	else
		MainIcon = t.Icon
		if not t.DynLoad then
			Icon = LoadIcon(t.Icon, t.Masked)
			Width, Height = mem.u2[Icon+0x18], mem.u2[Icon+0x1a]
		end
	end

	Settings ={
		Icon		= Icon,
		Masked	= t.Masked,
		Cond		= t.Condition,
		X		= t.X or 0,
		Y		= t.Y or 0,
		Wt		= Width,
		Ht		= Height,
		Layer	= t.Layer or 0,
		Screen	= t.Screen,
		MainIcon	= MainIcon,
		Active	= Active,
		IsAnim	= IsAnim,
		Type		= "Icon",
		BlockBG	= t.BlockBG,
		MouseOver	= false,
		MOAct	= t.MouseOverAction,
		DynLoad	= t.DynLoad
	}

	if t.NoPending == nil then
		Settings.NoPending = false
	else
		Settings.NoPending = t.NoPending
	end

	Settings.Key = t.Key
	AddElement(Settings)

	return Settings

end
CustomUI.CreateIcon = CreateIcon

local function RemoveElement(t)

	if type(t) ~= "table" then
		return false
	end

	local ListName
	t.Active = false

	if t.Type == "Button" then
		UnloadIcon(t.IUpPtr)
		UnloadIcon(t.IDwPtr)
		UnloadIcon(t.IMoPtr)
		ListName = "Buttons"
	elseif t.Type == "Icon" then
		if t.Anim then
			for Ii, Iv in ipairs(v.Icon) do
				UnloadIcon(Iv.Fr)
			end
		else
			UnloadIcon(t.Icon)
		end
		ListName = "Icons"
	else
		ListName = "Texts"
	end

	if type(t.Screen) == "table" then
		for k,v in pairs(t.Screen) do
			ActiveElements[v][ListName][t.Layer][t.Key] = nil
		end
	else
		ActiveElements[t.Screen][ListName][t.Layer][t.Key] = nil
	end

	Log(Merge.Log.Info, "%s: gc", LogId)
	collectgarbage("collect")
	Log(Merge.Log.Info, "%s: gc finished", LogId)

	return true

end
CustomUI.RemoveElement = RemoveElement

-- Record start coords of click, for cases of drag'n'drop
local sX, sY = 0, 0
Keys[const.Keys.LBUTTON] = function()
	sX, sY = Mouse.X, Mouse.Y
end

local function InMenu()
	return u4[0x71ef8d] == 0
end

local function CurScreen()
	return ActiveElements[Game.CurrentScreen] and (Game.LoadingScreen and 99 or Game.CurrentScreen) or 0
end

local LBUTTON = const.Keys.LBUTTON
local function ProcessButtons(la, Screen)

	local T = ActiveElements[Screen].Buttons[la]

	for k, v in pairs(T) do
		if v.Active and (not v.Cond or v:Cond()) then
			if v.DynLoad then
				if v.IUpPtr == 0 then
					v.IUpPtr = LoadIcon(v.IUpSrc, v.Masked)
					v.Wt, v.Ht = mem.u2[v.IUpPtr + 0x18], mem.u2[v.IUpPtr + 0x1a]
					if v.IsEllipse then
						v.Wt = v.Wt / 2
						v.Ht = v.Wt
						v.Chk = MouseInCircle
						v.sChk = CoordsInCircle
					else
						v.Chk = MouseInBox
						v.sChk = CoordsInBox
					end
				end
				if v.IDwPtr == 0 then
					if v.IDwSrc == v.IUpSrc then
						v.IDwPtr = v.IUpPtr
					else
						v.IDwPtr = LoadIcon(v.IDwSrc, v.Masked)
					end
				end
				if v.IMoSrc and (not v.IMoPtr or v.IMoPtr == 0) then
					if v.IMoSrc == v.IUpSrc then
						v.IMoPtr = v.IUpPtr
					elseif v.IMoSrc == v.IDwSrc then
						v.IMoPtr = v.IDwPtr
					else
						v.IMoPtr = LoadIcon(v.IMoSrc, v.Masked)
					end
				end
			end

			if v.IUpSrc ~= memstr(v.IUpPtr) then
				v.IUpPtr = LoadIcon(v.IUpSrc, v.Masked)
			end
			if v.IDwSrc ~= memstr(v.IDwPtr) then
				v.IDwPtr = LoadIcon(v.IDwSrc, v.Masked)
			end
			if v.IMoSrc and v.IMoSrc ~= memstr(v.IMoPtr) then
				v.IMoPtr = LoadIcon(v.IMoSrc, v.Masked)
			end

			if v.Chk(v.X,v.Y,v.Wt,v.Ht) then

				if Keys.IsPressed(LBUTTON) and (InMenu() or v.sChk(sX,sY,v.X,v.Y,v.Wt,v.Ht)) then
					ShowIcon(v.IDwPtr, v.X, v.Y)
					v.Pressed = true
				else
					if not v.MouseOver and v.MOAct then
						v:MOAct()
					end
					if v.Pressed then
						v:Act()
					end
					v.Pressed = false
					ShowIcon(v.IMoPtr or v.IUpPtr, v.X, v.Y)
				end

				v.MouseOver = true

			else
				ShowIcon(v.IUpPtr, v.X, v.Y)
				v.Pressed = false
				v.MouseOver = false
			end
		end
	end

end

local function ProcessTexts(la, Screen)

	local T = ActiveElements[Screen].Texts[la]

	for k, v in pairs(T) do
		if v.Active and (not v.Cond or v:Cond()) then
			if v.HvAct then
				if MouseInBox(v.X,v.Y,v.Wt,v.Ht) then
					ShowText(v.Text, v.Font, v.X, v.Y, v.Shift, v.Wt, v.Ht, v.Xof, v.Yof, v.CMo, v.CSh, v.AlignLeft)
					if Keys.IsPressed(LBUTTON) then
						v.Pressed = true
					else
						if v.Pressed then
							v:Act()
						end
						v.Pressed = false
					end
				else
					ShowText(v.Text, v.Font, v.X, v.Y, v.Shift, v.Wt, v.Ht, v.Xof, v.Yof, v.CStd, v.CSh, v.AlignLeft)
					v.Pressed = false
				end
			else
				ShowText(v.Text, v.Font, v.X, v.Y, v.Shift, v.Wt, v.Ht, v.Xof, v.Yof, v.CStd, v.CSh, v.AlignLeft)
			end
		end
	end
end

local function ProcessIcons(la, Screen)

	local T = ActiveElements[Screen].Icons[la]

	for k,v in pairs(T) do

		if v.Active and (not v.Cond or v:Cond()) then
			--if v.DynLoad then
			--	v.Icon = LoadIcon(v.MainIcon, v.Masked)
			--	v.Wt, v.Ht = mem.u2[v.Icon + 0x18], mem.u2[v.Icon + 0x1a]
			--end

			if v.IsAnim then
				local CurF = v.Icon[v:CF()] or v.Icon[1]
				if CurF.Src ~= memstr(CurF.Fr) then
					CurF.Fr = LoadIcon(CurF.Src, v.Masked)
					v.Wt, v.Ht = mem.u2[CurF.Fr + 0x18], mem.u2[CurF.Fr + 0x1a]
					if CurF.Fr ~= PENDING or not v.NoPending then
						ShowIcon(CurF.Fr, v.X, v.Y)
					end
				else
					ShowIcon(CurF.Fr, v.X, v.Y)
				end

			else
				if v.MainIcon ~= memstr(v.Icon) then
					v.Icon = LoadIcon(v.MainIcon, v.Masked)
					v.Wt, v.Ht = mem.u2[v.Icon + 0x18], mem.u2[v.Icon + 0x1a]
					if v.Icon ~= PENDING or not v.NoPending then
						ShowIcon(v.Icon, v.X, v.Y)
					end
				else
					ShowIcon(v.Icon, v.X, v.Y)
				end

			end

			if v.MOAct then
				if MouseInBox(v.X,v.Y,v.Wt,v.Ht) then
					if not v.MouseOver then
						v:MOAct()
					end
					v.MouseOver = true
				else
					v.MouseOver = false
				end
			end

		end
	end
end

local function UnloadIcons(Screen)
	for i, _ in pairs(ActiveElements[Screen].Buttons) do
		for k, v in pairs(ActiveElements[Screen].Buttons[i]) do
			if v.DynLoad then
				local up_ptr, dw_ptr
				if v.IUpPtr > 0 then
					up_ptr = v.IUpPtr
					UnloadIcon(v.IUpPtr)
					v.IUpPtr = 0
				end
				if v.IDwPtr > 0 then
					dw_ptr = v.IDwPtr
					if v.IDwPtr ~= up_ptr then
						UnloadIcon(v.IDwPtr)
					end
					v.IDwPtr = 0
				end
				if v.IMoPtr and v.IMoPtr > 0 then
					if v.IMoPtr ~= up_ptr and v.IMoPtr ~= dw_ptr then
						UnloadIcon(v.IMoPtr)
					end
					v.IDwPtr = 0
				end
			end
		end
	end
	for i, _ in pairs(ActiveElements[Screen].Icons) do
		for k, v in pairs(ActiveElements[Screen].Icons[i]) do
			if v.DynLoad then
				UnloadIcon(v.Icon)
			end
		end
	end
	-- shrink Game.IconsLod.Bitmaps
	mem.call(0x410C09, 1, 0x70D3E8)
end
CustomUI.UnloadIcons = UnloadIcons

---- Events

-- UI elements processing

mem.autohook(0x43bb12, function(d) -- Inventory, behind backhand.
	ProcessIcons(4, CurScreen())
end)

mem.autohook2(0x4d1d26, function()
	local Screen = CurScreen()

	events.call("BGInterfaceUpd")
	ProcessIcons(3, Screen)
	ProcessTexts(3, Screen)
	ProcessButtons(3, Screen)

	events.call("L2InterfaceUpd")
	ProcessIcons(2, Screen)
	ProcessTexts(2, Screen)
	ProcessButtons(2, Screen)
end)

mem.autohook2(0x4a30a5, function(d)
	if u4[d.eax] > 0 then
		local Screen = CurScreen()

		ProcessIcons(1, Screen)
		ProcessTexts(1, Screen)
		ProcessButtons(1, Screen)
		events.call("L1InterfaceUpd")

		ProcessIcons(0, Screen)
		ProcessTexts(0, Screen)
		ProcessButtons(0, Screen)
		events.call("FGInterfaceUpd")
	end
end)

mem.autohook2(0x416817, function()
	-- Called, when player clicks right mouse button
	-- Can be used for calls to CustomUI.ShowTooltip
	-- or other low CustomUI methods to draw tooltips
	-- Elements will be drawn properly even on screen 0 with MMPatch UI layout active

	events.Call("RightClickTooltip")
end)

-- PENDING check

local function GetPending()
	PENDING = LoadIcon("pending")
end

function events.LoadInventoryPics()
	GetPending()
end

function events.LoadMapScripts()
	GetPending()
end

-- Optional background block by UI elements

local function MouseInterceptByCustomUI()
	local Screen = Game.CurrentScreen
	for LayerId, Icons in pairs(ActiveElements[Screen].Icons) do
		for key, Icon in pairs(Icons) do
			if Icon.Active and Icon.BlockBG and (not Icon.Cond or Icon:Cond()) and MouseInBox(Icon.X,Icon.Y,Icon.Wt,Icon.Ht) then
				return true
			end
		end
	end

	for LayerId, Buttons in pairs(ActiveElements[Screen].Buttons) do
		for key, Button in pairs(Buttons) do
			if Button.Active and Button.BlockBG and (not Button.Cond or Button:Cond()) and Button.Chk(Button.X,Button.Y,Button.Wt,Button.Ht) then
				return true
			end
		end
	end

	return false
end

function events.Action(t)
	t.Handled = MouseInterceptByCustomUI()
end

function events.MenuAction(t)
	t.Handled = MouseInterceptByCustomUI()
end

---------------------------------------------------------
---- Show SFT Anim

function events.GameInitialized2()
	local RenderRect = 0xFFDE9C
	local RenderRectBottomPixel = 0xFFDEA8
	if Game.PatchOptions.Present'RenderBottomPixel' then
		local p, o = Game.PatchOptions['?ptr'], structs.o.PatchOptions
		RenderRect = p + o.RenderRectLeft
		RenderRectBottomPixel = p + o.RenderBottomPixel
	end

	mem.asmpatch(0x4a72ad, [[
	cmp byte [ds:]] .. SFTAnimActive .. [[], 0
	jnz absolute 0x4a72b9
	cmp dword [ds:ebx+0x5e4], esi]])

	mem.asmpatch(0x4a72be, [[
	cmp byte [ds:]] .. SFTAnimActive .. [[], 0
	jnz @anim

	push 0x500364
	jmp @end

	@anim:
	push ]] .. SFTAnimName .. [[;

	@end:]])

	mem.asmpatch(0x4a72e4, [[
	cmp byte [ds:]] .. SFTAnimActive .. [[], 0
	jnz @anim

	push 0x500364
	jmp @end

	@anim:
	push ]] .. SFTAnimName .. [[;

	@end:]])

	mem.asmpatch(0x4a7336, [[
	cmp byte [ds:]] .. SFTAnimActive .. [[], 0
	je @std

	fild dword [ds:]] .. SFTAnimParams+4 .. [[]
	jmp @end

	@std:
	fild dword [ds:]] .. RenderRect+8 .. [[]
	@end:]])

	mem.asmpatch(0x4a731c, [[
	cmp byte [ds:]] .. SFTAnimActive .. [[], 0
	je @std

	mov eax, dword [ds:]] .. SFTAnimParams+8 .. [[]
	jmp @end

	@std:
	mov eax, dword [ds:]] .. RenderRectBottomPixel .. [[]
	@end:]])

	mem.asmpatch(0x4a7316, [[
	cmp byte [ds:]] .. SFTAnimActive .. [[], 0
	je @std

	fild dword [ds:]] .. SFTAnimParams+12 .. [[]
	jmp @end

	@std:
	fild dword [ds:]] .. RenderRect .. [[]
	@end:]])

	mem.asmpatch(0x4a7354, [[
	cmp byte [ds:]] .. SFTAnimActive .. [[], 0
	je @std

	fild dword [ds:]] .. SFTAnimParams+16 .. [[]
	jmp @end

	@std:
	fild dword [ds:]] .. RenderRect .. [[]
	@end:]])

	mem.asmpatch(0x4a732b, [[
	cmp byte [ds:]] .. SFTAnimActive .. [[], 0
	je @std

	mov eax, dword [ds:]] .. SFTAnimParams .. [[]
	jmp @end

	@std:
	mov eax, 0x7f7f7f
	@end:]])

end

local SFTStartFrame, SFTEndFrame, SFTCurFrame, SFTPeriod = 0, 0, 0, 50
local SFTStartTime = 0
local SFTBin

local NewCode = mem.asmpatch(0x4a72f1, [[
call absolute 0x44afe1
cmp byte [ds:]] .. SFTAnimActive .. [[], 0
je @std

nop
nop
nop
nop
nop

@std:]])

mem.hook(NewCode + 14, function(d)
	local CurT = timeGetTime()
	SFTCurFrame = math.floor((CurT - SFTStartTime)/SFTPeriod) + SFTStartFrame
	if SFTCurFrame > SFTEndFrame or SFTCurFrame > SFTBin.count-1 then
		SFTStartTime = CurT
		SFTCurFrame = SFTStartFrame
	end
	d.eax = SFTBin[SFTCurFrame]["?ptr"]
end)

-- Shows SFT group stretched to game screen,
-- if t == nil, stops the animation.
-- Animation must be declared in ObjList.txt

local function ShowSFTAnim(t) -- SFTGroupName, Transparency, Period, Width, Height, X, Y, Start, End

	if not t then
		u1[SFTAnimActive] = 0
		return
	end

	u1[SFTAnimActive] = 1
	SFTBin = Game.SFTBin

	local Current = not t.SFTGroupName

	if t.Start and t.End then
		SFTStartFrame = t.Start
		SFTEndFrame = t.End
		SFTCurFrame = t.Start
	elseif not Current then
		SFTStartFrame = SFTBin:FindGroup(t.SFTGroupName)
		SFTEndFrame = SFTStartFrame
		SFTCurFrame = SFTStartFrame + 1

		while SFTCurFrame < SFTBin.count and not SFTBin[SFTCurFrame].GroupStart do
			SFTEndFrame = SFTCurFrame
			SFTCurFrame = SFTCurFrame + 1
		end
	end

	if not Current then
		SFTStartTime = timeGetTime()
		mem.copy(SFTAnimName, t.SFTGroupName)
		u1[SFTAnimName + string.len(t.SFTGroupName)] = 0
	end

	if t.Transparency then
		local Transp = math.ceil(t.Transparency/100*255)
		u1[SFTAnimParams  ] = Transp
		u1[SFTAnimParams+1] = Transp
		u1[SFTAnimParams+2] = Transp
	end
	if t.Period then
		SFTPeriod = t.Period
	end
	if t.Width then
		i4[SFTAnimParams+ 4] = t.Width
	end
	if t.Height then
		i4[SFTAnimParams+ 8] = t.Height
	end
	if t.X then
		i4[SFTAnimParams+12] = t.X
	end
	if t.Y then
		i4[SFTAnimParams+16] = t.Y
	end

end
CustomUI.ShowSFTAnim = ShowSFTAnim

local function IsSFTAnimActive()
	return u1[SFTAnimActive] > 0
end
CustomUI.SFTAnimActive = IsSFTAnimActive
