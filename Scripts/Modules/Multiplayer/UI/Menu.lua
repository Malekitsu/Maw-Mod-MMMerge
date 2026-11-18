local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer

local SyncPlayers = Multiplayer.require("Synchronization/Players.lua")
local Lobby = Multiplayer.require("UI/Lobby.lua")
local UIUtils = Multiplayer.require("UI/UtilsUI.lua")

local GetClipboardData = UIUtils.GetSessionCodeFromClipboard
local SetClipboardData = UIUtils.SetClipboardText

local function TextTumbler(...)
	return UIUtils.TextTumbler(Multiplayer.UI_SCREEN, ...)
end
local function SimpleText(...)
	return UIUtils.SimpleText(Multiplayer.UI_SCREEN, ...)
end

SimpleText(Multiplayer.VERSION, 20, 460, Game.Smallnum_fnt).CStd = RGB(200, 200, 200)

local MulUIScreen = Multiplayer.UI_SCREEN
local MySessionCodeText, HostSessionCodeText
local HostingSectionOpen = false
local ListeningTumbler
local CurrentTab
local MainTumbler

local tab_connection
local tab_appearance
local tab_settings

local bitmapsCache
local display_skin

----------------------------------
-- Base functions

local PrevScreen = 0
local function NeedExitChecker(t)
	if t.Action == 113 then
		Multiplayer.ExitMulUI()
		t.Handled = true
	end
end

local function EscapeChecker(t)
	if not t.Handled and t.Key == const.Keys.ESCAPE then
		t.Handled = true
		Multiplayer.ExitMulUI()
	end
end

local function OpenMulUI()
	if Game.CurrentScreen == MulUIScreen then
		return
	end

	PrevScreen = Game.CurrentScreen
	Game.CurrentScreen = MulUIScreen
	events.Action = NeedExitChecker
	events.KeyDown = EscapeChecker

	if Multiplayer.connector then
		MySessionCodeText.Text = Multiplayer.my_session_code()
	end

	tab_connection:Act()
	bitmapsCache = {}

	vars.Multiplayer = vars.Multiplayer or {}
	Multiplayer.my_skin = vars.Multiplayer.my_skin or 194
	display_skin(Multiplayer.my_skin)

	if Multiplayer.in_game then
		MainTumbler.set(Multiplayer.internet_connection and "Internet" or "LAN")
	else
		MainTumbler.set("Off")
	end

	ListeningTumbler.On = Multiplayer.connection_listening_on()
	ListeningTumbler.handler()
end
Multiplayer.OpenMulUI = OpenMulUI

local function ExitMulUI()
	if Game.CurrentScreen == MulUIScreen then
		Game.CurrentScreen = PrevScreen
		PrevScreen = 0
	end
	CustomUI.UnloadIcons(MulUIScreen)
	events.Remove("Action", NeedExitChecker)
	events.Remove("KeyDown", EscapeChecker)
	bitmapsCache = nil
	if Multiplayer.in_game then
		SyncPlayers.notify_skin_changed()
	end

	if CurrentTab == tab_settings then
		events.Call("MultiplayerExtraSettingsClosed")
	end
end
Multiplayer.ExitMulUI = ExitMulUI

Multiplayer.CurrentUITab = function()
	return tab_connection == CurrentTab and "connection" or
			tab_appearance == CurrentTab and "appearance" or
			tab_settings == CurrentTab and "settings"
end

----------------------------------
-- Main interface

local function TabAction(tab)
	tab_connection.CStd = 0xFFFF
	tab_appearance.CStd = 0xFFFF
	tab_settings.CStd = 0xFFFF

	tab.CStd = 0xe664

	if CurrentTab == tab_settings and tab ~= tab_settings then
		events.Call("MultiplayerExtraSettingsClosed")
	elseif CurrentTab ~= tab_settings and tab == tab_settings then
		events.Call("MultiplayerExtraSettingsOpen")
	end

	CurrentTab = tab

	UIUtils.CustomSettings.Show(tab == tab_settings)
end

local function SimpleTab(Text, X, Y)
	return CustomUI.CreateText{
		Text = Text,
		X = X, Y = Y,
		ColorStd = 0xFFFF,
		ColorMouseOver = 0xe664,
		Font = Game.Arrus_fnt,
		Layer = 1,
		Screen = MulUIScreen,
		Action = TabAction
	}
end

tab_connection = SimpleTab("Connection", 100, 25)
tab_connection.X = tab_connection.X - tab_connection.Wt / 2

tab_appearance = SimpleTab(" Appearance", 320, 25)
tab_appearance.X = tab_appearance.X - tab_appearance.Wt / 2

tab_settings = SimpleTab("Settings", 540, 25)
tab_settings.X = tab_settings.X - tab_settings.Wt / 2

CustomUI.CreateIcon{
	Icon = "TPGlobal",
	X = 0,
	Y = 0,
	Layer = 1,
	BlockBG = true,
	Screen = MulUIScreen}

-- Exit button
SimpleText("Exit", 520, 440, nil, nil, ExitMulUI)

----------------------------------
-- Connection interface

local baseX = 40
local baseY = 100

local function im_host()
	return HostingSectionOpen and Multiplayer.in_game and CurrentTab == tab_connection
end

local function im_client()
	return not HostingSectionOpen and Multiplayer.in_game and CurrentTab == tab_connection
end

-- 0. Multiplayer on/off toggle for hooks controll
local function IsConnectionTab()
	return CurrentTab == tab_connection
end

local function IsConnectionTabMulOn()
	return CurrentTab == tab_connection and Multiplayer.in_game
end

local function MultiplayerOnOff(state)
	if state == "Off" then
		Game.Paused = true
		Game.Paused2 = true

		if Multiplayer.connector then
			Multiplayer.close()
		end
		return
	end

	local JustEnabled = not Multiplayer.connector
	local IsInternet = state == "Internet"
	if JustEnabled or IsInternet ~= Multiplayer.internet_connection then
		events.Call("MultiplayerBeforeConnectionTypeChanged", JustEnabled, IsInternet)
		Multiplayer.internet_connection = state == "Internet"

		if Multiplayer.connector then
			Multiplayer.connector:close()
			Multiplayer.connector = Multiplayer.create_connector(Multiplayer.receive_handler)
		else
			Multiplayer.init()
		end

		Game.Paused = false
		Game.Paused2 = false

		MySessionCodeText.Text = Multiplayer.my_session_code()
		events.Call("MultiplayerConnectionTypeChanged", JustEnabled)
	end
end

MainTumbler = UIUtils.TextRadio(MulUIScreen, baseX, baseY, "Multiplayer:", {"Off", "LAN", "Internet"}, MultiplayerOnOff, IsConnectionTab)

-- 1. toggle my state host / client
TextTumbler(baseX, baseY + 25, "I am:", "Client", "Host", true, function(self)
	local new = not self.On
	if HostingSectionOpen ~= new then
		if self.On then
			ListeningTumbler.On = false
			ListeningTumbler.handler()
		end
		events.Call("MultiplayerRoleChanged", self.On and "client" or "host")
	end
	HostingSectionOpen = new
end, IsConnectionTabMulOn)

function Multiplayer.selected_role()
	return HostingSectionOpen and "host" or "client"
end

-- 2. Show my session code
local function IsConnectionTabMulOnNoSrvList()
	return IsConnectionTabMulOn() and not Lobby.ServerListOpen()
end

local function ImClientNoSrvList()
	return im_client() and not Lobby.ServerListOpen()
end

local header = SimpleText("My session code:", baseX, baseY + 50, nil, IsConnectionTabMulOnNoSrvList)
local headerWt = header.Wt
local header = SimpleText("Host session code:", baseX, baseY + 75, nil, ImClientNoSrvList)
headerWt = math.max(header.Wt, headerWt)

MySessionCodeText = SimpleText("", baseX + headerWt, baseY + 52, Game.Smallnum_fnt, IsConnectionTabMulOnNoSrvList)
MySessionCodeText.Wt = 24 * 12
MySessionCodeText.Ht = 16

CustomUI.CreateText{
	Text = "Copy",
	Font = Game.Arrus_fnt,
	X = MySessionCodeText.X + MySessionCodeText.Wt - 16, Y = baseY + 50,
	Height = 16, Width = 64,
	ColorStd = 0xFFFF,
	ColorMouseOver = 0xe664,
	Action = function() SetClipboardData(Multiplayer.my_session_code()) end,
	Condition = IsConnectionTabMulOnNoSrvList,
	Layer = 1,
	Screen = MulUIScreen,
	AlignLeft = true,
}

CustomUI.CreateText{
	Text = "Show",
	Font = Game.Arrus_fnt,
	X = MySessionCodeText.X + MySessionCodeText.Wt - 16 + 64, Y = baseY + 50,
	Height = 16, Width = 64,
	ColorStd = 0xFFFF,
	ColorMouseOver = 0xe664,
	Action = function()
		local qtext = ("\nSession code: %s\nPrivate address: %s\nPublic address: %s\n"):format(
			Multiplayer.my_session_code(),
			Multiplayer.my_private_addr(),
			Multiplayer.my_public_addr())

		internal.DebugConsole(qtext, (internal.IsTopmost or internal.IsFullScreen)(), "Multiplayer")
		internal.DebugConsole(nil, false, "Multiplayer")
	end,
	Condition = IsConnectionTabMulOnNoSrvList,
	Layer = 1,
	Screen = MulUIScreen,
	AlignLeft = true,
}

-- 2. text input: session id for client mode
HostSessionCodeText = SimpleText("", baseX + headerWt, baseY + 77, Game.Smallnum_fnt, ImClientNoSrvList)
HostSessionCodeText.Wt = 24 * 12
HostSessionCodeText.Ht = 16

local ClientConnectionStatus = SimpleText("     ", HostSessionCodeText.X + HostSessionCodeText.Wt - 72, baseY + 77, Game.Smallnum_fnt, ImClientNoSrvList)
SimpleText("Paste", HostSessionCodeText.X + HostSessionCodeText.Wt - 16, baseY + 75, nil, ImClientNoSrvList, function() HostSessionCodeText.Text = GetClipboardData() end)
SimpleText("Clear", HostSessionCodeText.X + HostSessionCodeText.Wt + 48, baseY + 75, nil, ImClientNoSrvList, function() HostSessionCodeText.Text = "" end)

-- 3. check connection for both states

local clients_table

SimpleText("Connect", baseX, baseY + 100, nil, ImClientNoSrvList, function() Multiplayer.connect_session(HostSessionCodeText.Text) end)

local function host_check_connections(self)
	if self.On then
		local session_ids = {}
		for _, line in pairs(clients_table.data) do
			if #line.session_code == Multiplayer.SESSION_ID_SIZE then
				table.insert(session_ids, line.session_code)
			end
		end
		Multiplayer.listen_connections(session_ids, true)
	else
		Multiplayer.stop_listening()
	end
end
ListeningTumbler = TextTumbler(baseX + 256, baseY + 75, "Listen for connections:", "On", "Off", false, host_check_connections, im_host)

-- 4. clients table for host

clients_table = Multiplayer.require("UI/ClientsTable.lua").Create(baseX, baseY, im_host,
	function()
		if ListeningTumbler.On then
			ListeningTumbler.On = false
			host_check_connections(ListeningTumbler)
			ListeningTumbler.On = true
			host_check_connections(ListeningTumbler)
		end
	end
)

-- Events

function events.ConnectionTestStarted(session_code)
	if Game.CurrentScreen == MulUIScreen and not HostingSectionOpen then
		ClientConnectionStatus.Text = "..."
	end
end

function events.ConnectionTestFinished(session_code, conn)
	if Game.CurrentScreen == MulUIScreen and not HostingSectionOpen then
		local ConnColor = Multiplayer.utils.ConnStatusColor
		ClientConnectionStatus.Text =
			conn.local_established and ConnColor("LAN", 1) or
			conn.public_established and ConnColor("p2p", 1) or
			conn.relay_established and ConnColor("relay", 2) or
			ConnColor("X", 3)
	end
end

function events.MultiplayerStopped()
	ListeningTumbler.On = false
	ListeningTumbler.handler()

	MySessionCodeText.Text = ""
	HostSessionCodeText.Text = ""
	ClientConnectionStatus.Text = ""
end

function events.ClientJoined(client)
	if client.id == 0 then
		HostSessionCodeText.Text = client.session_code
	end
end

----------------------------------
-- Appearance interface

-- Race,Gender = list
local ShowRecommended = true
local RecommendedSkins = {
	-- Human
	10,11,12,13,14,15,16,17,18,34,35,36,43,44,45,46,47,48,49,50,51,193,194,195,202,203,204,217,218,219,253,254,255,256,257,258,259,260,261,292,293,294,307,308,309,403,404,405,406,407,408,418,419,420,
	-- DarkElf
	19,20,21,22,23,24,25,26,27,247,248,249,
	-- Dragon
	--71,72,70,164,165,163, -- too big for most indoor maps
	-- Elf
	250,251,252,331,332,333,340,341,342,
	-- Goblin
	271,272,273,430,431,432,439,440,441,
	-- Dwarf
	175,176,177,229,230,231,313,314,315,322,323,324,
	-- Minotaur
	64,65,66,301,302,303,
	-- Troll
	28,29,30,31,32,33,58,59,60,61,62,63,106,107,108,
	-- Vampire
	52,53,54,415,416,417,454,455,456,
	-- Undead
	55,56,57,172,173,174,214,215,216,268,269,270,289,290,291,397,398,399,421,422,423,
	-- Zombie
	427,428,429}

local function IsAppearanceTab()
	return CurrentTab == tab_appearance
end

TextTumbler(174, 390, nil, " Recommended ", " Free selection ", ShowRecommended,
	function(self)
		ShowRecommended = not ShowRecommended
	end,
	IsAppearanceTab, false)

local SkinPreview = CustomUI.CreateIcon{
	Icon = "none",
	NoPending = true,
	DynLoad = false,
	X = 25,
	Y = 25,
	Layer = 1,
	Screen = MulUIScreen,
	Condition = IsAppearanceTab}

local icon_buff, bitmap_dummy

display_skin = function(monTxtId)
	if not Game.IsD3D then
		return nil
	end

	if not icon_buff then
		local bitmaps = Game.IconsLod.Bitmaps
		local bitmap = bitmaps[bitmaps.count-1]
		icon_buff = mem.StaticAlloc(bitmap['?size'])
		mcopy(icon_buff, bitmap['?ptr'], bitmap['?size'])
		bitmap_dummy = structs.LodBitmap:new(icon_buff)
		SkinPreview.Icon = bitmap_dummy['?ptr']
		SkinPreview.MainIcon = bitmap_dummy.Name
	end

	local sprite = bitmapsCache[monTxtId]
	if not sprite then
		local SFTName = Game.MonListBin[monTxtId].FramesStand
		local SFTId = Game.SFTBin:FindGroup(SFTName)

		sprite = UIUtils.FetchSpriteImage(SFTId)
		if not sprite then
			return nil
		end

		bitmapsCache[monTxtId] = sprite
	end

	bitmap_dummy.Image = toptr(sprite.image)
	bitmap_dummy.Palette16 = toptr(sprite.palette)
	bitmap_dummy.Width, bitmap_dummy.Height = sprite.width, sprite.height

	local icon = SkinPreview
	icon.X = 640 / 2 - sprite.width / 2
	icon.Y = 480 / 2 - sprite.height / 2
	icon.Wt, icon.Ht = sprite.width, sprite.height
	icon.Icon = icon_buff
	icon.MainIcon = bitmap_dummy.Name
	icon.sprite = sprite -- prevent garbage collecting upon leaving screen

	CustomUI.SetMask(bitmap_dummy)
end

local SkinName = CustomUI.CreateText{
	Text = " ", X = 160, Y = 75,
	Width = 320,
	Height = 64,
	Font = Game.Arrus_fnt,
	Layer = 1,
	Screen = MulUIScreen,
	Condition = IsAppearanceTab}

local function shift_skin(step)
	local limit = Game.MonstersTxt.count - 3

	if ShowRecommended then
		local id = table.find(RecommendedSkins, Multiplayer.my_skin)
		if not id then
			Multiplayer.my_skin = RecommendedSkins[1]
		else
			id = id + step
			if id > #RecommendedSkins then
				id = 1
			elseif id < 1 then
				id = #RecommendedSkins
			end
			Multiplayer.my_skin = RecommendedSkins[id]
		end
	else
		Multiplayer.my_skin = Multiplayer.my_skin + step
		if Multiplayer.my_skin > limit then
			Multiplayer.my_skin = 1
		elseif Multiplayer.my_skin < 1 then
			Multiplayer.my_skin = limit
		end
	end

	display_skin(Multiplayer.my_skin)
	SkinName.Text = (" %s\n(%s / %s)"):format(Game.MonstersTxt[Multiplayer.my_skin].Name, Multiplayer.my_skin, limit)
	if not Game.IsD3D then
		SkinName.Text = SkinName.Text .. "\n\nPreview is not supported in software rendering mode."
	end
	vars.Multiplayer.my_skin = Multiplayer.my_skin
end

local function SkinSwitch(Text, X, Y, Shift)
	return UIUtils.SimpleText(Multiplayer.UI_SCREEN, Text, X, Y, nil, IsAppearanceTab, function() shift_skin(Shift) end, false)
end

SkinSwitch("<", 170, 240, -1)
SkinSwitch(">", 430, 240, 1)

SkinSwitch("<<", 110, 240, -3)
SkinSwitch(">>", 490, 240, 3)

SkinSwitch("<<<", 50, 240, -30)
SkinSwitch(">>>", 550, 240, 30)

local def = tab_appearance.Act
tab_appearance.Act = function(t)
	shift_skin(0)
	def(t)
end
