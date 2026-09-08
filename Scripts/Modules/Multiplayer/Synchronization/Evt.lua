local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
local nums_to_bin, fill_from_bin = Multiplayer.utils.nums_to_bin, Multiplayer.utils.fill_from_bin
local cond_same_map = Multiplayer.utils.cond_same_map
local LogEvent = Multiplayer.utils.LogEvent

local service_calls = false
local CastSpellLimits = {}
local packets

local function local_evt(evt, params)
	service_calls = true
	local val = evt(params)
	service_calls = false
	return val
end
Multiplayer.utils.local_evt = local_evt

-- prevent timer evt.CastSpell on client side to avoid objects duplication
local object_interaction = false
function Multiplayer.AllowNextEvtCastSpell()
	object_interaction = true
end
function events.Action(t)
	object_interaction = t.Action == 10 or t.Action == 404
end
function events.FacetEventActivation(facet_id)
	object_interaction = true
end
function events.Tick(t)
	object_interaction = false
end
function events.EvtCommandCall(t)
	if t.evt_id == 0x15 and not object_interaction and Multiplayer.my_id ~= Multiplayer.main_player_on_map() then -- CastSpell
		t.Handled = true
	end
end

local LastReceivedNPCMsg = ""
local GreetingBeingDrawn = false
local GreetingMessage = ""
function events.DrawNPCGreeting(t)
	GreetingBeingDrawn = true
	if #GreetingMessage > 0 then
		t.Text = GreetingMessage
	end
	LastReceivedNPCMsg = t.Text
end
function events.ExitNPC()
	GreetingMessage = ""
end

local function cast_target_self(params)
	local self_cast = true
	for i = 4, 9 do
		if params[i] ~= 0 then
			self_cast = false
			break
		end
	end
	return self_cast
end

local function is_service_npc(i)
	return i >= 1184 and i <= 1224 or i >= 262 and i <= 310 or i == Game.HouseExtraExitNPCDummy
end

local function UniMessage(text)
	if Game.CurrentScreen == const.Screens.House then
		HouseMessage(text)
	elseif Game.CurrentScreen == const.Screens.NPC and GreetingBeingDrawn then
		GreetingMessage = text
		Message(GreetingMessage)
		GreetingBeingDrawn = false
	else
		Message(text)
	end
end

local remote_commands = {
	[3] = {
		map_only = true,
		params = {4,4,4},
		evt = evt.PlaySound
	},

	[10] = {
		map_only = true,
		params = {1,1},
		evt = evt.SetSnow
	},

	[11] = {
		map_only = true,
		delay_past_halt = true,
		params = {4,'s'},
		evt = evt.SetTexture
	},

	[12] = {
		--map_only = true,
		params = {1,1,'s'},
		delay_past_halt = true,
		handler = function(self, params, behaivor)
			behaivor.send_this_tick = true
		end,
		evt = function(params)
			-- 0 - don't show
			-- 1 - same map (default)
			-- 2 - everywhere
			local show_rule = {
				["losegame"] = 0,
				["6losegame"] = 0,
				["7losegame"] = 0,
				["subcut.bik"] = 0,
				["subcut"] = 0,

				["wingame"] = 2,
				["intro post"] = 2,
				["pcout01"] = 2,
				["arbiter evil"] = 2,
				["arbiter good"] = 2,
				["endgame 1 good"] = 2,
				["endgame 1 evil"] = 2,

				-- shown individualy on map leave
				["mm6end1"] = 0,
				["mm6end2"] = 0,
			}

			local name = params[3]:lower():replace('"', '')
			local rule = show_rule[name] or 1

			if rule ~= 0 and name == Game.ContinentSettings[TownPortalControls.GetCurrentSwitch()].DeathMovie then
				rule = 0
			end

			LogEvent("EVENTS", "Received evt.ShowMovie %s, show rule is %s.", name, rule)
			if rule == 0 or rule == 1 and Map.MapStatsIndex ~= params._map then
				return
			end

			local function f()
				local_evt(evt.ShowMovie, params)
			end

			Multiplayer.utils.TickChecker(f, 4, function() return Game.CurrentScreen == const.Screens.House or Game.CurrentScreen == 0 end)
		end
	},

	[13] = {
		map_only = true,
		delay_past_halt = true,
		params = {4,1,'s'},
		evt = evt.SetSprite
	},

	[19] = { -- evt.SummonMonsters
		map_only = true,
		delay_past_halt = true,
		params = {1,1,1,4,4,4,4,4},
		handler = function(self, params, behaivor)
			behaivor.dont_send = true
		end,
		evt = evt.SummonMonsters
	},

	[23] = {
		map_only = true,
		delay_past_halt = true,
		params = {4,4,1},
		evt = evt.SetFacetBit
	},

	[26] = { -- evt.Question - don't ask question, but show header text for other players
		map_only = false,
		params = {2},
		handler = function(self, params, behaivor)
			if params[1] <= 0 or self.timestamp == os.time() then
				behaivor.dont_send = true
				return
			end
			-- fetch actual text for client, in case it is not present in NPCTexts and was shown using Placeholder workaround
			self.timestamp = os.time()
			params.extra = Game.NPCText[params[1]]
		end,
		evt = function(params)
			if not params._npc or params._npc == 0 then
				return
			end

			if GetCurrentNPC() == params._npc then
				UniMessage(params.extra)
			end
		end
	},

	[30] = { -- evt.SetMessage
		map_only = false,
		params = {2},
		handler = function(self, params, behaivor)
			if evt.InGlobal() and params[1] <= 0 then
				behaivor.dont_send = true
				return
			end
			-- fetch actual text for client, in case it is not present in NPCTexts and was shown using Placeholder workaround
			params.extra = evt.InGlobal() and Game.NPCText[params[1]] or evt.Str[499]
		end,
		evt = function(params)
			if not params._npc or params._npc == 0 then
				return
			end

			if GetCurrentNPC() == params._npc then
				LastReceivedNPCMsg = params.extra
				UniMessage(params.extra)
			end
		end
	},

	[32] = {
		map_only = true,
		delay_past_halt = true,
		params = {4,1},
		evt = evt.SetLight
	},

	[39] = { -- evt.SetNPCTopic
		map_only = false,
		params = {4,1,4},
		evt = function(params)
			local npc = params[1]
			if is_service_npc(npc) then
				return
			end

			Game.NPC[npc].Events[params[2]] = params[3]
			if GetCurrentNPC() == params._npc and Game.CurrentScreen == const.Screens.House then
				Game.UpdateDialogTopics()
			end
		end
	},

	[40] = { -- evt.MoveNPC
		map_only = false,
		params = {4,4},
		evt = function(params)
			local npc = params[1]
			if Game.CurrentScreen == const.Screens.NPC and npc == GetCurrentNPC() then
				ExitCurrentScreen()
			end

			if is_service_npc(npc) then
				return
			end

			NPCFollowers.Remove(npc)
			local old_house = Game.NPC[npc].House
			local new_house = params[2]
			local cur_house = GetCurrentHouse()

			Game.NPC[npc].House = new_house
			if Game.CurrentScreen == const.Screens.House and (cur_house == old_house or cur_house == new_house) then
				ReloadHouse()
			end
		end
	},

	[47] = {
		map_only = false,
		params = {4,4},
		evt = evt.SetNPCGroupNews
	},

	[50] = {
		map_only = false,
		params = {4,4},
		evt = evt.SetNPCGreeting
	},

	[57] = {
		map_only = true,
		delay_past_halt = true,
		params = {4,4,1},
		evt = evt.SetMonGroupBit
	},

	-- Handled by Sync/Chests.lua
	-- evt.SetChestBit

	-- Handled by Sync/Doors.lua
	--[15] = {
	--	map_only = true,
	--	params = {1,1},
	--	evt = evt.SetDoorState
	--},
	--[63] = {
	--	map_only = true,
	--	params = {4},
	--	evt = evt.StopDoor
	--},

	-- custom commands

	move_service_npc = { -- move NPC bypassing service npc check - for removing shared mercenaries from houses upon hiring
		map_only = false,
		params = {4,4},
		evt = function(params)
			local old_house = Game.NPC[params[1]].House
			local new_house = params[2]
			local house = GetCurrentHouse()

			Game.NPC[params[1]].House = params[2]
			if Game.CurrentScreen == const.Screens.House and (house == old_house or house == new_house) then
				ReloadHouse()
			elseif Game.CurrentScreen == const.Screens.NPC and params[1] == GetCurrentNPC() then
				ExitCurrentScreen()
			end
		end
	}
}

for k, v in pairs(remote_commands) do
	v.id = k
end

packets = {
	remote_evt = {
		bulb = function(command, params)
			params._id = command.id
			params._npc = GetCurrentNPC()
			--LogEvent("EVT", "Prepared bulb of remote evt #%s, params: %s.", command.id, table.concat(params, ","))
			return item_to_bin(params)
		end,
		handler = function(bin_string, metadata)
			local params = bin_to_item(toptr(bin_string))
			local command = remote_commands[params._id]
			if command then
				params._map = metadata.map_id
				--LogEvent("EVT", "Executing remote evt #%s, params: %s.", command.id, table.concat(params, ","))
				local_evt(command.evt, params)
			end
		end,
		check_delivery = true,
		compress = true
	}
}
Multiplayer.utils.init_packets(packets)

local function fetch_params(command, params_ptr)
	local params, shift = {}, 0
	for i, v in ipairs(command.params) do
		if v == 's' then
			params[i] = mstr(params_ptr + shift)
			shift = shift + #params[i]
		else
			params[i] = mem['i' .. tostring(v)][params_ptr + shift]
			shift = shift + v
		end
	end
	return params
end
Multiplayer.debug.evt_commands = remote_commands
Multiplayer.debug.fetch_evt_params = fetch_params

function events.EvtCommandCall(t)
	local command = remote_commands[t.evt_id]
	if not command then
		return
	end

	local params

	if command.delay_past_halt and Multiplayer.leave_map_halt then
		t.Handled = true
		params = fetch_params(command, t.params)
		local f = function()
			local_evt(command.evt, params)
		end
		events.Once("MapLoadingDone", f)
	end

	if service_calls then
		return
	end

	params = params or fetch_params(command, t.params)

	local behaivor = {handled = false, dont_send = false, send_this_tick = false, extra = nil}
	if command.handler then
		command:handler(params, behaivor)
	end
	if behaivor.handled then
		t.Handled = true
	end
	if behaivor.dont_send then
		return
	end

	local data = packets.remote_evt:prep(command, params)
	if command.map_only then
		Multiplayer.broadcast(data, cond_same_map)
	else
		Multiplayer.broadcast(data)
	end

	if behaivor.send_this_tick then
		Multiplayer.sendall()
	end
end

function events.HireCharacter(t)
	local npc_id = GetCurrentNPC()

	if not npc_id or npc_id == 0 then
		return
	end

	if Game.CurrentScreen == const.Screens.House and Game.NPC[npc_id].House ~= GetCurrentHouse() then
		t.Handled = true -- NPC was moved by other client
		return
	end

	local data = packets.remote_evt:prep(remote_commands.move_service_npc, {npc_id, 0})
	Multiplayer.broadcast(data)
end

-- prevent UI break
function events.EvtCommandCall(t)
	if t.evt_id == 0x16 and Game.CurrentScreen ~= 0 then -- SpeakNPC
		t.Handled = true
		local NPCId = mem.i4[t.params]
		Multiplayer.utils.TickChecker(
			function() evt.SpeakNPC{NPCId} end, 16,
			function() return Game.CurrentScreen == 0 end)
	end
end

--------------------------------------------
-- Dialogs - block NPC topics, if other player already talking to this character

local dummy_topic = 1450
local Claims = Multiplayer.Claims

local function init_dummy_topic(WasInGame)
	if not WasInGame then
		evt.Global[dummy_topic]:clear()
		Game.GlobalEvtLines:RemoveEvent(dummy_topic)
		evt.Global[dummy_topic] = function()
			local state = service_calls
			service_calls = true
			UniMessage(LastReceivedNPCMsg)
			service_calls = state
		end
	end
end
events.LoadMapScripts = init_dummy_topic
events.MultiplayerStarted = init_dummy_topic

-- client_id -> npc being talked to, for the house UI
Multiplayer.blocked_npcs = function()
	local t = {}
	for npc, owner in pairs(Claims.list("npc")) do
		t[owner] = npc
	end
	return t
end

local function SetNPCDialog(NPCId, Result)
	local NPC = Game.NPC[NPCId]
	for i, v in NPC.Events do
		if v == dummy_topic then
			local pos = table.find(Result, const.HouseScreens.A + i)
			if pos then table.remove(Result, pos) end
			NPC.Events[i] = 0
		end
	end
end

local PENDING_TOPIC_TEXT = "..."

local function SetNPCBlockTopic(NPCId, Result, pending)
	table.clear(Result)

	local NPC = Game.NPC[NPCId]
	local owner = Claims.owner("npc", NPCId)
	local client = owner and Multiplayer.connector.clients[owner]

	local free_event = NPCFollowers.FindFreeEvent(NPC, {dummy_topic})
	if free_event then
		if pending then
			Game.NPCTopic[dummy_topic] = PENDING_TOPIC_TEXT
		else
			Game.NPCTopic[dummy_topic] = ("%s is busy speaking with %s"):format(NPC.Name, client and client.name or "other player")
		end
		NPC.Events[free_event] = dummy_topic
		table.insert(Result, const.HouseScreens.A + free_event)
	end
end

-- while the verdict travels the dialog shows a placeholder; any change of
-- ownership redraws the topics of the dialog that is open
local function refresh_dialog(npc)
	if GetCurrentNPC() == npc then
		Game.UpdateDialogTopics()
	end
end

Claims.define("npc", {
	scope = "game",
	on_granted = refresh_dialog,
	on_lost = refresh_dialog,
	on_update = refresh_dialog,
})

function events.PopulateNPCDialog(t)
	local IsNPCDialog = t.NPC and t.Index and (t.DlgKind == "Main" or t.DlgKind == "StreetNPC")
	if not IsNPCDialog or t.Index == Game.HouseExtraExitNPCDummy then
		return
	end

	local verdict = Claims.try("npc", t.Index)
	if verdict == "granted" then
		SetNPCDialog(t.Index, t.Result)
	elseif verdict == "pending" then
		SetNPCBlockTopic(t.Index, t.Result, true)
	else
		SetNPCBlockTopic(t.Index, t.Result)
	end
end

function events.ExitNPC(i)
	Claims.release("npc", i)
	NPCFollowers.ClearEvents(Game.NPC[i], {dummy_topic})
	LastReceivedNPCMsg = ""
end
