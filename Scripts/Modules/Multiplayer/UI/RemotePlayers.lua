local events = Multiplayer.events
local distance = Multiplayer.utils.distance

local UIUtils = Multiplayer.require("UI/UtilsUI.lua")
local Keybinds = Multiplayer.require("UI/Keybinds.lua")

local TOUCH_RANGE = 400 -- for potions
local CAST_RANGE = 3800 -- for spells
local DISPLAY_RANGE = 5400
local MMPatch_UI = Game.PatchOptions.UILayoutActive()
local DISPLAY_PLAYERS_MAX = MMPatch_UI and 4 or 3 -- max npc portraits to display

local RemotePartyUIOpen = false
local DisplayRemoteSP = true
local AlwaysDisplayRemotePlayers = false

-------------------------------------------------
-- Remote alchemy

local function CallMouseItemUse(PartyId)
	mem.call(0x466572, 1, Party[PartyId]["?ptr"], PartyId + 1, 1)
end

local function MousePotionHandler(Condition)
	local selector = Multiplayer.utils.player_by_condition_selector(Condition)
	local function f(Item)
		mem.copy(Mouse.Item["?ptr"], Item["?ptr"], Item["?size"])
		CallMouseItemUse(selector())
	end
	return f
end

local RemoteItemApplication = {
	[222] = MousePotionHandler(const.Condition.Unconscious), -- cure wounds
	[224] = MousePotionHandler(const.Condition.Weak), -- cure weakness
	[225] = MousePotionHandler({const.Condition.Disease1, const.Condition.Disease2, const.Condition.Disease3}), -- cure disease
	[226] = MousePotionHandler({const.Condition.Poison1, const.Condition.Poison2, const.Condition.Poison3}), -- cure poison
	[227] = MousePotionHandler(const.Condition.Sleep), -- awaken
	[237] = MousePotionHandler(const.Condition.Afraid), -- remove fear
	[238] = MousePotionHandler(const.Condition.Cursed), -- remove curse
	[239] = MousePotionHandler(const.Condition.Insane), -- cure insanity
	[251] = MousePotionHandler(const.Condition.Paralyzed), -- cure paralysis
	[262] = MousePotionHandler(const.Condition.Stoned), -- stone to flesh
}

local packets = {}

packets.use_item = {
	bulb = Multiplayer.utils.mmt_dump,
	handler = function(bin_string, metadata)
		local ptr = mem.topointer(bin_string)
		local item = structs.Item:new(ptr)
		local handler = RemoteItemApplication[item.Number]
		if handler then
			Game.ShowStatusText(string.format("%s gave you %s potion.",
				Multiplayer.client_name(metadata.sender_id, true, false),
				Game.ItemsTxt[item.Number].Name))
			handler(item)
		end
	end,
	check_delivery = true,
	compress = true
}

-------------------------------------------------
-- Full remote buffs / conditions broadcasting

local SpellSchoolColors = Multiplayer.utils.SpellSchoolColorsStr

local function SpellColor(spell_id)
	local spell_school = Multiplayer.utils.school_by_spell(spell_id)
	return SpellSchoolColors[spell_school] or StrColor(250, 250, 250)
end

local ConditionNames = Multiplayer.utils.ConditionNames
local PartyBuffNames = Multiplayer.utils.PartyBuffNames
local PlayerBuffNames = Multiplayer.utils.PlayerBuffNames

local function ExpireStr(Time)
	local expire = Time - Game.Time
	local Hour = (expire / const.Hour):floor()
	local Minute = ((expire % const.Hour) / const.Minute):floor()

	return ("%s %s %s %s"):format(Hour, Game.GlobalTxt[110], Minute, Game.GlobalTxt[436])
end

local function CondTimeStr(Time)
	local Lasts = Game.Time - Time
	local Hour = (Lasts / const.Hour):floor()
	local Minute = ((Lasts % const.Hour) / const.Minute):floor()

	return ("%s %s %s %s"):format(Hour, Game.GlobalTxt[110], Minute, Game.GlobalTxt[436])
end

local buff_cond_tooltips = {}
Multiplayer.debug.BuffCondTooltips = function()
	return buff_cond_tooltips
end
Multiplayer.debug.PlayerStatusTimeSepLength = 40

local function gen_status_text(client_id, t)
	local lines = {
		Multiplayer.client_name(client_id, true, false),
		' ',
	}

	-- untill proper text alignment implemented
	local function make_separator(left, right, target)
		local length = target - #left - #right
		local separator = " "
		for i = 1, length do
			separator = separator .. " "
		end
		return separator
	end

	local function add_line(status_color, status, timestr)
		local sep = make_separator(status, timestr, Multiplayer.debug.PlayerStatusTimeSepLength)
		table.insert(lines, ("%s%s%s%s%s"):format(status_color, status, sep, StrColor(250, 250, 250), timestr))
	end

	local function party_members_line(t)
		return string.format("%s%s%s", "(", table.concat(t,","), ")")
	end

	local function gen_party_buffs()
		local buff_size = structs.SpellBuff["?size"]
		local ptr = mem.topointer(t.PartyBuffs)
		for i = 0, #t.PartyBuffs - buff_size, buff_size do
			local buff = structs.SpellBuff:new(ptr + i)
			local name_id = PartyBuffNames[i / buff_size]
			if not name_id then
				break
			end
			if buff.ExpireTime > Game.Time then
				add_line(SpellColor(name_id), Game.SpellsTxt[name_id].Name, ExpireStr(buff.ExpireTime))
			end
		end
		table.insert(lines, ' ')
	end

	local function gen_player_buffs()
		local buff_size = structs.SpellBuff["?size"]
		local buffs = t.PlayerBuffs[1]
		local ptr = mem.topointer(buffs)
		for i = 0, #buffs - buff_size, buff_size do
			local buff = structs.SpellBuff:new(ptr + i)
			local name_id = PlayerBuffNames[i / buff_size]
			if not name_id then
				break
			end
			if buff.ExpireTime > Game.Time then
				add_line(SpellColor(name_id), Game.SpellsTxt[name_id].Name, ExpireStr(buff.ExpireTime))
			end
		end
		table.insert(lines, ' ')
	end

	local function gen_player_conds()
		local conditions = t.PlayerConds[1]
		local ptr = mem.topointer(conditions)
		for i = 0, #conditions - 8, 8 do
			local name_id = ConditionNames[i / 8]
			if not name_id then
				break
			end
			local applied = mem.i8[ptr + i]
			if applied > 0 then
				add_line(StrColor(255, 230, 230), Game.GlobalTxt[name_id], CondTimeStr(applied))
			end
		end
		table.insert(lines, ' ')
	end

	local function gen_players_buffs() -- unused, kept for future use
		local statuses = {}
		for i, ni in pairs(PlayerBuffNames) do
			statuses[i] = {players = {}, min_time = Game.Time + const.Year}
		end

		local buff_size = structs.SpellBuff["?size"]
		for player_number, buffs in ipairs(t.PlayerBuffs) do
			local ptr = mem.topointer(buffs)
			for i = 0, #buffs - buff_size, buff_size do
				local buff = structs.SpellBuff:new(ptr + i)
				local buff_id = i / buff_size
				if not PartyBuffNames[buff_id] then
					break
				end
				if buff.ExpireTime > Game.Time then
					local st = statuses[buff_id]
					table.insert(st.players, player_number)
					st.min_time = math.min(st.min_time, buff.ExpireTime)
				end
			end
		end

		for buff_id, st in pairs(statuses) do
			if next(st.players) then
				local name_id = PlayerBuffNames[buff_id]
				local header = Game.SpellsTxt[name_id].Name .. " " .. party_members_line(st.players)
				add_line(SpellColor(name_id), header, ExpireStr(st.min_time))
			end
		end
		table.insert(lines, ' ')
	end

	local function gen_players_conds() -- unused, kept for future use
		local statuses = {}
		for i, ni in pairs(ConditionNames) do
			statuses[i] = {players = {}, min_time = Game.Time + const.Year}
		end

		for player_number, conditions in ipairs(t.PlayerConds) do
			local ptr = mem.topointer(conditions)
			for i = 0, #conditions - 8, 8 do
				local cond_id = i / 8
				if not ConditionNames[cond_id] then
					break
				end
				local applied = mem.i8[ptr + i]
				if applied > 0 then
					local st = statuses[cond_id]
					table.insert(st.players, player_number)
					st.min_time = math.min(st.min_time, applied)
				end
			end
		end

		for cond_id, st in pairs(statuses) do
			if next(st.players) then
				local name_id = ConditionNames[cond_id]
				local header = Game.GlobalTxt[name_id] .. " " .. party_members_line(st.players)
				add_line(SpellColor(name_id), header, CondTimeStr(st.min_time))
			end
		end
		table.insert(lines, ' ')
	end

	----

	gen_party_buffs()
	if #t.PlayerBuffs == 1 then
		gen_player_buffs()
	else
		gen_players_buffs()
	end
	if #t.PlayerConds == 1 then
		gen_player_conds()
	else
		gen_players_conds()
	end

	return table.concat(lines, '\n')

end

local function player_status_text(client_id)
	local info = buff_cond_tooltips[client_id]
	if not info then
		return Multiplayer.client_name(client_id, true, false) .. "\n..."
	end

	if Game.Time - info.time > const.Minute then
		info.text = gen_status_text(client_id, info.data)
		info.time = Game.Time
	end
	return info.text
end

packets.buff_conds = {
	bulb = function()
		local mtd = Multiplayer.utils.mmt_dump
		local t = {
			PartyBuffs = mtd(Party.SpellBuffs),
			PlayerBuffs = {},
			PlayerConds = {},
		}

		for i, v in Party do
			t.PlayerBuffs[i + 1] = mtd(v.SpellBuffs)
			t.PlayerConds[i + 1] = mtd(v.Conditions)
		end

		return Multiplayer.utils.item_to_bin(t)
	end,
	handler = function(bin_string, metadata)
		local t = Multiplayer.utils.binstr_to_item(bin_string)
		local info = buff_cond_tooltips[metadata.sender_id]
		if not info then
			info = {data = t, time = 0, text = ""}
			buff_cond_tooltips[metadata.sender_id] = info
		else
			info.data = t
		end
	end,
	check_delivery = true,
	same_map_only = true,
	compress = true,
}


local function notify_status()
	Multiplayer.broadcast(packets.buff_conds:prep(), Multiplayer.utils.cond_same_map)
end
events.MapLoadingDone = notify_status
events.SpellAuraReceived = notify_status
events.MultiplayerDeathScreen = notify_status

local status_update_pending = false
local function notify_status_delayed()
	if status_update_pending then
		return
	end
	status_update_pending = true
	Multiplayer.utils.delayed_call(function()
		status_update_pending = false
		notify_status()
	end, 4)
end
events.DoBadThingToPlayer = notify_status_delayed
events.DismissCharacter = notify_status_delayed
events.PlayerCastSpell = notify_status_delayed
events.UseMouseItem = notify_status_delayed

function events.ClientChangeMap(client_id, old, new)
	if new == Map.MapStatsIndex then
		Multiplayer.add_to_send_queue(client_id, packets.buff_conds:prep())
	end
end

-------------------------------------------------
-- Turn based mode status

packets.notify_tb_status = {
	bulb = function()
		local phase = Game.TurnBasedPhase
		if phase == 3 and Multiplayer.debug.CanEndPartyMovePhase() then
			phase = 1
		end
		return Multiplayer.utils.num_to_hexstr(phase, 1)
	end,
	handler = function(bin_string, metadata)
		local phase = Multiplayer.utils.num_from_hexstr(bin_string, 1)
		Multiplayer.client_info(metadata.sender_id).tb_phase = phase
	end,
	same_map_only = true
}

local function start_tb_checker()
	local checker = function()
		if Game.TurnBased then
			Multiplayer.broadcast(packets.notify_tb_status:prep(), Multiplayer.utils.cond_same_map)
			return false
		else
			return true
		end
	end

	local finisher = function()
		events.Once("TurnBasedPhaseChange", start_tb_checker)
	end

	Multiplayer.utils.TickChecker(finisher, 32, checker)
end
events.Once("TurnBasedPhaseChange", start_tb_checker)

-------------------------------------------------
-- Widget conditions

local function InGame()
	return Multiplayer.in_game and mem.u4[0x71ef8d] == 1
end

local function StdCond()
	return RemotePartyUIOpen and InGame()
end

-------------------------------------------------
-- UI init

local function ButtonAction(t)
	if Game.CurrentScreen == const.Screens.SelectTarget then
		ExitScreen()

		if t.data.distance > CAST_RANGE then
			Multiplayer.utils.delayed_call(Game.ShowStatusText, 2, "Target is too far away.")
			Game.PlaySound(136)
			return
		end

		local mon = Multiplayer.get_client_mon(t.data.client_id)
		if not mon or not Pathfinder.TraceSight(mon, Party) then
			Multiplayer.utils.delayed_call(Game.ShowStatusText, 2,"Target is out of sight.")
			Game.PlaySound(136)
			return
		end

		events.Once("CanProcessSpell", function(t)
			t.target_ref = Multiplayer.utils.ref_num(3, mon:GetIndex())
			t.allow = true
			Multiplayer.utils.delayed_call(ExitCurrentScreen, 2)
		end)

	elseif Mouse.Item.Number > 0 then
		if t.data.distance > TOUCH_RANGE then
			Game.ShowStatusText("Player must be in 'touch' range to have item applied.")
			Game.PlaySound(27)
			return
		end

		if not RemoteItemApplication[Mouse.Item.Number] then
			Game.ShowStatusText("This item cannot be applied to player remotely.")
			Game.PlaySound(27)
			return
		end

		Multiplayer.add_to_send_queue(t.data.client_id, packets.use_item:prep(Mouse.Item))
		Mouse.Item.Number = 0
	end
end

local screens = {0, const.Screens.SelectTarget}
local widgets = {}
Multiplayer.debug.PartyWidgets = widgets

Multiplayer.debug.MovePartyWidgets = function(ox,oy)
	for _, wid in pairs(Multiplayer.debug.PartyWidgets) do
		wid.X = wid.X + ox
		wid.Y = wid.Y + oy

		for _, text in pairs{wid.text_range, wid.text_hp, wid.text_tbphase, wid.text_name} do
			text.X = text.X + ox
			text.Y = text.Y + oy
		end
	end
end

local ToggleUIButton = CustomUI.CreateButton{
	IconUp = "tab5a",
	IconDown = "tab5b",
	Masked = true,
	Screen = {0, const.Screens.SelectTarget},
	Layer = 0,
	X = MMPatch_UI and 440 or 0,
	Y = MMPatch_UI and 30 or 66,
	Condition = InGame,
	MouseOverAction = function()
		if RemotePartyUIOpen then
			Game.ShowStatusText("Hide remote players UI")
		else
			Game.ShowStatusText("Show remote players UI")
		end
	end,
	Action = function(t)
		RemotePartyUIOpen = not RemotePartyUIOpen
		t.IUpSrc, t.IDwSrc = t.IDwSrc, t.IUpSrc
		t.IUpPtr, t.IDwPtr = t.IDwPtr, t.IUpPtr
		Game.NeedRedraw = true
	end,
	Key = "OpenMultiplayerParty"
}

local RemoteTargetKeybinds = {}
function Multiplayer.std_events.MultiplayerInitialized()
	for i = 1, DISPLAY_PLAYERS_MAX do
		local n = tostring(i)
		RemoteTargetKeybinds[i] = Keybinds.Add("RemotePlayer" .. n, "Select remote player " .. n .. ":", n, true, {0, const.Screens.SelectTarget}, function()
			local wid = widgets[i]
			if wid and wid.Active then
				wid:Act()
			end
		end)
	end

	Keybinds.Add("ToggleRemotePlayersUI", "Toggle remote players UI:", "P", false, {0, const.Screens.SelectTarget}, function()
		ToggleUIButton:Act()
	end)
end

local function PropText(Text, X, Y)
	return UIUtils.SimpleText(screens, Text, X, Y, Game.Smallnum_fnt, function(self) return self.parent.Active and self.parent:Cond() end, nil, true, 3)
end

local Tooltip = PropText("Apply to player:", MMPatch_UI and 132 or 0, (MMPatch_UI and 320 or 66) + 46)
Tooltip.Cond = function(t)
	return RemotePartyUIOpen
		and (Game.CurrentScreen == const.Screens.SelectTarget or Mouse.Item.Number > 0 and RemoteItemApplication[Mouse.Item.Number])
end

for i = 1, DISPLAY_PLAYERS_MAX do
	local YBase = 370 - i * 80 + (MMPatch_UI and -10 or 0)
	local XBase = (MMPatch_UI and 120 or 0)

	XBase = XBase + 12 --(MMPatch_UI and 36 or 12)
	local widget = CustomUI.CreateButton{
		X = XBase, Y = YBase,
		IconUp = "none",
		Active = false,
		Layer = 3,
		Screen = screens,
		Condition = StdCond,
		Action = ButtonAction,
		MouseOverAction = function(t) Game.ShowStatusText(Multiplayer.client_name(t.data.client_id, true, true)) end
		}

	XBase = XBase + 87

	widget.text_name = PropText("Placeholder name with class and condition", XBase, YBase)
	widget.text_name.parent = widget

	widget.text_range = PropText("Range: far away", XBase, YBase + 14)
	widget.text_range.parent = widget

	widget.text_hp = PropText("HP: %s / %s pt.", XBase, YBase + 28)
	widget.text_hp.parent = widget

	widget.text_sp = PropText("SP: %s / %s pt.", XBase, YBase + 42)
	widget.text_sp.parent = widget

	widget.text_tbphase = PropText("taking turn...", XBase, YBase + 56)
	widget.text_tbphase.parent = widget

	local std_cond = widget.text_tbphase.Cond
	widget.text_tbphase.Cond = function(self) return Game.TurnBased and std_cond(self) end

	widget.SetTexts = function(self)
		local hp_ratio = self.data.hp / self.data.full_hp
		local hp_text = string.format("%s / %s", self.data.hp, self.data.full_hp)
		if hp_ratio > 0.66 then
			hp_text = StrColor(0, 255, 0, hp_text)
		elseif hp_ratio > 0.33 then
			hp_text = StrColor(255, 255, 0, hp_text)
		else
			hp_text = StrColor(255, 0, 0, hp_text)
		end

		self.text_sp.Active = DisplayRemoteSP
		if DisplayRemoteSP then
			local sp_text = string.format("%s / %s", self.data.sp, self.data.full_sp)
			sp_text = StrColor(0, 140, 255, sp_text)
			self.text_sp.Text = "SP: " .. sp_text
			self.text_tbphase.Y = YBase + 56
		else
			self.text_tbphase.Y = YBase + 42
		end

		local range = self.data.touch and StrColor(0, 255, 0, "touch") or self.data.cast and StrColor(255, 255, 0, "spell") or "far away"
		local tb_text = self.data.tb_phase == 2 and StrColor(255, 255, 0, "in combat")
			or self.data.tb_phase == 3 and StrColor(255, 255, 0, "moving")
			or StrColor(0, 255, 0, "ready")

		local hotkey = RemoteTargetKeybinds[i] and StrColor(200, 200, 255, string.char(RemoteTargetKeybinds[i].Value))

		self.text_range.Text = "Range: " .. range
		self.text_hp.Text = "HP: " .. hp_text
		self.text_tbphase.Text = tb_text
		self.text_name.Text = string.format("%s. %s", hotkey or i, Multiplayer.client_name(self.data.client_id, false, true)):sub(1, 40)
	end

	widgets[i] = widget
end

function Multiplayer.std_events.MultiplayerUIInitialized()
	DisplayRemoteSP = Multiplayer.GlobalData().DisplayRemoteSP
	if DisplayRemoteSP == nil then
		DisplayRemoteSP = true
	end

	AlwaysDisplayRemotePlayers = Multiplayer.GlobalData().AlwaysDisplayRemotePlayers
	if AlwaysDisplayRemotePlayers == nil then
		AlwaysDisplayRemotePlayers = false
	end

	local acceptor = {useSP = DisplayRemoteSP, alwaysDisplay = AlwaysDisplayRemotePlayers}
	local UI = Multiplayer.utils.UI.CustomSettings
	local Group = UI.Group("Remote players UI", "Remote players UI")

	Group:Switch("Display players despite distance:", acceptor, "alwaysDisplay", function(t)
		AlwaysDisplayRemotePlayers = acceptor.alwaysDisplay
		Multiplayer.GlobalData().AlwaysDisplayRemotePlayers = AlwaysDisplayRemotePlayers
		Multiplayer.SaveGlobalData()
	end)

	Group:Switch("Show remote SP:", acceptor, "useSP", function(t)
		DisplayRemoteSP = acceptor.useSP
		Multiplayer.GlobalData().DisplayRemoteSP = DisplayRemoteSP
		Multiplayer.SaveGlobalData()
	end)
end

-------------------------------------------------
-- UI tooltips

local TooltipProps = {
	X = 100,
	Y = 100,
	Width = 400,
	Font = nil
}
Multiplayer.debug.ClientTooltipProps = TooltipProps

function events.RightClickTooltip()
	for i, wid in pairs(widgets) do
		if wid.Active and wid.Chk(wid.X, wid.Y, wid.Wt, wid.Ht) then
			CustomUI.ShowTooltip(player_status_text(wid.data.client_id),
				TooltipProps.X, TooltipProps.Y, TooltipProps.Width, TooltipProps.Font or Game.Comic_fnt)
			break
		end
	end
end

-------------------------------------------------
-- UI update

local function npc_pic_name(id)
	local str = tostring(id)
	return 'npc' .. ('0000'):sub(#str + 1) .. str
end

local function PlayersInVicinity()
	local result = {}
	local mon, dist
	for client_id, mon_id in pairs(Multiplayer.client_monsters()) do
		mon = Multiplayer.get_client_mon(client_id)
		if mon then
			dist = distance(Party, mon)
			if dist <= DISPLAY_RANGE or AlwaysDisplayRemotePlayers then
				local client_info = Multiplayer.client_info(client_id)
				table.insert(result, {
					client_id = client_id,
					distance = dist,
					touch = dist <= TOUCH_RANGE,
					cast = dist <= CAST_RANGE,
					npc_pic = client_info.face and Game.CharacterPortraits[client_info.face].NPCPic or 1516,
					hp = mon.HP,
					full_hp = mon.FullHP,
					sp = client_info.SP,
					full_sp = client_info.FullSP,
					condition = client_info.main_cond,
					tb_phase = client_info.tb_phase
				})
			end
		end
	end

	if #result > DISPLAY_PLAYERS_MAX then
		table.sort(result, function(v1, v2) return v1.distance < v2.distance end)
		for i = #result, (DISPLAY_PLAYERS_MAX + 1), -1 do
			result[i] = nil
		end
		table.sort(result, function(v1, v2) return v1.client_id < v2.client_id end)
	end

	return result
end

local function UpdateDisplay()
	if Multiplayer.leave_map_halt then
		for _, wid in pairs(widgets) do
			wid.Active = false
		end
		return
	end

	local players = PlayersInVicinity()
	local pl, wid
	local top_widget
	for i = 1, DISPLAY_PLAYERS_MAX do
		wid = widgets[i]
		pl = players[i]
		if pl then
			wid.Active = true
			wid.IUpSrc = npc_pic_name(pl.npc_pic)
			wid.IDwSrc = wid.IUpSrc
			wid.IMoSrc = wid.IUpSrc
			wid.data = pl
			wid:SetTexts()
			top_widget = wid
		else
			wid.Active = false
		end
	end

	if top_widget then
		Tooltip.X = top_widget.X
		Tooltip.Y = top_widget.Y - 32
	end

	Game.NeedRedraw = true
end

Multiplayer.utils.TickCounter(UpdateDisplay, 16)

----

Multiplayer.utils.init_packets(packets)
