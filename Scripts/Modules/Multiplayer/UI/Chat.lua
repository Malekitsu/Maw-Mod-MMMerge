local events = Multiplayer.events
local MMPatch_UI = Game.PatchOptions.UILayoutActive()

local MaxMessageLength = 96
Multiplayer.debug.SetMaxMessageLength = function(n)
	MaxMessageLength = n
end

local ChatLengthLimit = 384
Multiplayer.debug.SetChatLengthLimit = function(n)
	ChatLengthLimit = n
end

local ChatLineSize = 30
Multiplayer.debug.SetChatLineSize = function(n)
	ChatLineSize = n
end

local ChatPreviewMaxLines = 15
Multiplayer.debug.SetChatPreviewMaxLines = function(n)
	ChatPreviewMaxLines = n
end

local ChatMaxLines = 28
Multiplayer.debug.SetChatMaxLines = function(n)
	ChatMaxLines = n
end

local function CountChatLines(str)
	local lines = string.split(str, "\n")
	local count = 0
	for _, msg in ipairs(lines) do
		count = count + math.ceil(#msg / ChatLineSize)
	end
	return count, lines
end

local function ClampChatPreview(str)
	local count, lines = CountChatLines(str)
	if count <= ChatPreviewMaxLines then
		return str
	end

	for i = #lines, 1, -1 do
		local msg = table.remove(lines)
		count = count - math.ceil(#msg / ChatLineSize)
		if count <= ChatPreviewMaxLines then
			return table.concat(lines, "\n")
		end
	end

	return table.concat(lines, "\n")
end

-- Network

local function NameAndMessage(client_id, msg)
	local client = Multiplayer.client_info(client_id)
	local color = client.PlayerColor or Multiplayer.DEFAULT_PLAYER_COLOR
	return StrColor(color[1], color[2], color[3], client.name) .. StrColor(250,250,250, ": " .. msg)
end

local messages = {}
local packets = {
	chat_message = {
		bulb = function(msg)
			return msg
		end,
		handler = function(bin_string, metadata)
			table.insert(messages, NameAndMessage(metadata.sender_id, bin_string))
		end,
		check_delivery = true,
		compress = true,
		ignore_reload_count = true
	}
}
Multiplayer.utils.init_packets(packets)

local function SendMessage(msg)
	table.insert(messages, NameAndMessage(Multiplayer.my_id, msg))
	Multiplayer.broadcast(packets.chat_message:prep(msg), nil)
end

-- UI

local function InGame()
	return Multiplayer.in_game and mem.u4[0x71ef8d] == 1
end

local ChatOn
local function CanShowChat()
	return ChatOn and InGame() and not NPCFollowers.NPCPanelOpen()
end

local TogglePreview = CustomUI.CreateButton{
	IconUp = "tab6a",
	IconDown = "tab6b",
	Masked = true,
	Screen = {0, const.Screens.SelectTarget},
	Layer = 0,
	X = MMPatch_UI and 477 or -1,
	Y = MMPatch_UI and 30 or 100,
	Condition = InGame,
	MouseOverAction = function()
		Game.ShowStatusText(ChatOn and "Hide chat" or "Show chat")
	end,
	Action = function(t)
		ChatOn = not ChatOn
		t.IUpSrc, t.IDwSrc = t.IDwSrc, t.IUpSrc
		t.IUpPtr, t.IDwPtr = t.IDwPtr, t.IUpPtr
		Game.NeedRedraw = true
	end,
	Key = "ShowMultiplayerChat"
}

-- Chat preview on main screen (0)
local ChatPreview = CustomUI.CreateText{
	Text = "",
	Screen = {0, 20},
	Layer = 3,
	AlignLeft = true,
	Condition = CanShowChat,
	X = 440,
	Y = 70,
	Font = Game.Create_fnt,
}
ChatPreview.Wt = 200
ChatPreview.Ht = 16

-- Full chat window on Question screen (19)
local ChatHistory = Multiplayer.utils.NewCycleList(100)
local ChatTextOffset = 0
local ChatOpen = false
local ChatText = CustomUI.CreateText{
	Text = "",
	Screen = 19,
	Layer = 0,
	AlignLeft = true,
	Condition = function() return ChatOpen and InGame() end,
	X = 474,
	Y = 4,
	Font = Game.Create_fnt,
}
ChatText.Wt = 154
ChatText.Ht = 16

local NextChatClear = 0

local AllowedScreen = {[0] = true, [19] = true, [20] = true}
local function ShowNextMessage()
	if #messages == 0 or not AllowedScreen[Game.CurrentScreen] then
		return
	end

	local msg = table.remove(messages, 1)
	ChatHistory:add(msg)
	if not CanShowChat() then
		if Game.CurrentScreen ~= 19 then
			Game.ShowStatusText(msg)
		end
	else
		Game.NeedRedraw = true
	end
	ChatPreview.Text = ClampChatPreview(msg .. "\n" .. ChatPreview.Text)
	NextChatClear = os.time() + 10
end
Multiplayer.utils.MillisecCounter(ShowNextMessage, 300)

local function ClearOldMessage()
	if #ChatPreview.Text == 0 then
		return
	end

	local stamp = os.time()
	if stamp < NextChatClear then
		return
	end

	local lines = string.split(ChatPreview.Text, "\n")
	table.remove(lines)
	ChatPreview.Text = table.concat(lines, "\n")
end
Multiplayer.utils.MillisecCounter(ClearOldMessage, 2000)

function events.MultiplayerStopped()
	ChatHistory:clear()
	ChatPreview.Text = ""
	ChatText.Text = ""
end

function events.MultiplayerRoleChanged()
	ChatHistory:clear()
	ChatPreview.Text = ""
	ChatText.Text = ""
end

function events.MultiplayerConnectionTypeChanged()
	ChatHistory:clear()
	ChatPreview.Text = ""
	ChatText.Text = ""
end

-- Question screen

local function UpdateChatText()
	ChatText.Text = ""
	local count = 0
	local offset = 0
	for _, msg in ChatHistory:ripairs() do
		if offset >= ChatTextOffset then
			count = count + math.ceil(#msg / ChatLineSize)
			if count > ChatMaxLines then
				break
			end
			ChatText.Text = ChatText.Text .. msg .. "\n"
		else
			offset = offset + 1
		end
	end
end

local function ChatTextUpdater()
	while ChatOpen do
		UpdateChatText()
		coroutine.yield()
	end
end

local function OpenChat(offset)
	ChatTextOffset = offset or 0

	if not ChatOpen then
		Multiplayer.utils.CoMillisecCounter(coroutine.create(ChatTextUpdater), 2000)
	end

	ChatOpen = true
	UpdateChatText()

	function ActionCatcher(t) --491
		if not ChatOpen then
			events.Remove("Action", ActionCatcher)
			return
		end
		if t.Action == 491 then
			t.Handled = true
		end
	end
	events.Action = ActionCatcher

	while true do
		Multiplayer.utils.delayed_call(function()
			mem.u4[0x6c8cd4] = MaxMessageLength -- extend input limit
			--0x6c8cd8 -- buffer
			--0x6c8dd9 -- current input length
		end, 2)

		local msg = Question("")
		if msg and #msg > 0 then
			SendMessage(msg)
		else
			ChatOpen = false
			break
		end
	end
end

local StartChat = CustomUI.CreateButton{
	IconUp = "tab-an-7a",
	IconDown = "tab-an-7b",
	Masked = true,
	Screen = {0, const.Screens.SelectTarget},
	Layer = 0,
	X = MMPatch_UI and 510 or -1,
	Y = MMPatch_UI and 30 or 136,
	Condition = InGame,
	MouseOverAction = function()
		Game.ShowStatusText("Open chat")
	end,
	Action = function() Multiplayer.utils.delayed_call(OpenChat, 2) end,
	Key = "OpenMultiplayerChat"
}

-- Keybinds
function Multiplayer.std_events.MultiplayerInitialized()
	Multiplayer.Keybind("ToggleChatPreview", "Toggle chat preview :", "K", false, {0, 20}, function()
		TogglePreview:Act()
	end)
	Multiplayer.Keybind("OpenChat", "Open chat           :", "L", false, {0}, function()
		Multiplayer.utils.delayed_call(OpenChat, 2)
	end)
end

--

return {
	PendingMessages = messages,
	SendMessage = SendMessage,
	ShowNextMessage = ShowNextMessage,
	ChatPreview = ChatPreview,
	ChatText = ChatText,
	ChatHistory = ChatHistory,
	OpenChat = OpenChat
}
