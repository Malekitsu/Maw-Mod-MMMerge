local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local sendbuff = Multiplayer.utils.sendbuff

local item_to_bin = Multiplayer.utils.item_to_bin
local bin_to_item = Multiplayer.utils.bin_to_item
local tkeys = Multiplayer.utils.tkeys
local nums_to_bin = Multiplayer.utils.nums_to_bin
local mmt_dump = Multiplayer.utils.mmt_dump
local fill_from_bin = Multiplayer.utils.fill_from_bin
local num_array_to_bin = Multiplayer.utils.num_array_to_bin
local bin_to_num_array = Multiplayer.utils.bin_to_num_array

local LogEvent = Multiplayer.utils.LogEvent

Multiplayer.require("Network/STUN.lua")
Multiplayer.require("Network/Connector.lua")

local log_packets = {}
Multiplayer.debug.log_packets = log_packets

local ignore_packets = {}
Multiplayer.debug.ignore_packets = ignore_packets

local Binary = Multiplayer.require("Network/Binary.lua")
local NetworkPacket = Multiplayer.require("Network/BasePacket.lua")

local metadata_bin = Binary.metadata_bin
local read_metadata = Binary.read_metadata
local fetch_bulb = Binary.fetch_bulb
local prep_packet = Binary.prep_packet

Multiplayer.prep_packet = prep_packet

-- data formats --

local function clear_old_packets(client_id)
	local t = {}
	local inc = Multiplayer.incoming_packets()
	for hash, packet in pairs(inc) do
		if packet.metadata.sender_id == client_id then
			table.insert(t, hash)
		end
	end
	for _, hash in pairs(t) do
		inc[hash] = nil
	end

	local t = {}
	local out = Multiplayer.outgoing_packets()
	for hash, packet in pairs(out) do
		if packet.delivery_to == client_id then
			table.insert(t, hash)
		end
	end
	for _, hash in pairs(t) do
		out[hash] = nil
	end
end

local packets = {

	-- bulb - function - generates data to send; takes one parameter, if generated as response to other packet;
	-- response - string - name of packet, that should be sent as response to this one;
	-- handler - function - used to process received binary data of this packet (passed in first parameter as binary string),
	--	whatever it returns is passed to bulb function of response packet as first parameter

	-- service

	request_packet_parts = {
		bulb = function(message_id, parts)
			u4[sendbuff] = message_id
			if parts then
				for i, v in pairs(parts) do
					u2[sendbuff + i*2 + 2] = v
				end
				return mstr(sendbuff, #parts * 2 + 4, true)
			end
			return mstr(sendbuff, 4, true)
		end,
		handler = function(bin_string, meta)
			local hash = u4[toptr(bin_string)]
			local parts
			if #bin_string > 4 then
				parts = bin_to_num_array(mstr(toptr(bin_string) + 4, #bin_string - 4, true), 2, false)
			end

			local packet = Multiplayer.outgoing_packets()[hash]

			if not packet then
				LogEvent("NETWORK", "Got resend request of nonexisting message: message hash: %s", hash)
			elseif not parts then
				LogEvent("NETWORK", "Got request to resend message #%s %s from %s.", hash, packet.settings.name, meta.sender_id)
				packet:send()
			elseif #parts == 0 then
				LogEvent("NETWORK", "Got empty resend request: message hash: %s", hash)
			else
				LogEvent("NETWORK", "Got request to resend parts of message #%s %s (%s) from %s.", hash, packet.settings.name, table.concat(parts, ","), meta.sender_id)
				packet:send_parts(parts)
			end
		end,
		ignore_reload_count = true
	},

	-- connection establishing --

	handshake_client = {
		bulb = function(my_addrport, network_kind, host_session_code, host_addr, host_port, use_relay)
			local client_id, client = Multiplayer.connector:add_client(host_addr, host_port, 0)
			client.session_code = host_session_code
			client.remote_relay = use_relay
			clear_old_packets(client_id)
			LogEvent("CONNECTION", "Potential host's packet queues cleared.")

			LogEvent("CONNECTION", "Preparing handshake_client to %s:%s.", host_addr, host_port)
			return item_to_bin{
				version = Multiplayer.VERSION,
				last_session_code = Multiplayer.GlobalData().Connections[host_session_code],
				session_code = Multiplayer.my_session_code(),
				network_kind = network_kind, -- 1 - LAN, 2 - internet, 3 - relay
				ip = my_addrport or Multiplayer.myaddr()
			}
		end,
		response = 'handshake_server',
		handler = function(bin_string, metadata)
			local info = bin_to_item(toptr(bin_string))
			local host = Multiplayer.main_player_in_game()
			if Multiplayer.my_id ~= host then
				-- resend to host
				LogEvent("CONNECTION", "Received client's handshake from %s, redirecting to host.", info.session_code)
				local meta = metadata_bin(0, 0, 0, metadata.packet_code, metadata.bulb_size, 1, 1)
				Multiplayer.add_to_send_queue(host, meta .. bin_string)
				return false
			end

			LogEvent("CONNECTION", "Received client's handshake from %s", info.session_code)

			local error_t
			if info.version ~= Multiplayer.VERSION then
				LogEvent("CONNECTION", "Rejecting client's handshake: versions do not match (mine: %s, remote: %s).", Multiplayer.VERSION, info.version)
				error_t = {can_join = false, error = "versions do not match, server version: " .. Multiplayer.VERSION}
			elseif (Multiplayer.connector:active_clients_count() + 1) > Multiplayer.players_amount_limit then
				LogEvent("CONNECTION", "Rejecting client's handshake: limit of players reached (%s).", Multiplayer.players_amount_limit)
				error_t = {can_join = false, error = "server full"}
			elseif info.network_kind == 3 and not Multiplayer.connector:have_relay_access() then
				LogEvent("CONNECTION", "Rejecting client's handshake: client uses relay, i have no access to it.")
				error_t = {can_join = false, error = "no relay access"}
			end

			if error_t then
				error_t.session_code = Multiplayer.my_session_code()
				local data = item_to_bin(error_t)
				local meta = Binary.metadata_bin(0, 0, 0, Multiplayer.packets.handshake_server.code, #data, 1, 1, 0, 0, 0)
				local addr, port = info.ip:match("(%A*):(%d*)")
				Multiplayer.connector.udp:sendto(meta .. data, addr, port)
				return nil
			end

			if info.last_session_code then
				for i,v in pairs(Multiplayer.connector.clients) do
					if v.session_code == info.last_session_code then -- it is reconnection
						Multiplayer.remove_client(i)
						break
					end
				end
			end

			local client_id, client = Multiplayer.addclient(info.ip)
			LogEvent("CONNECTION", "Client entry created, id #%s.", client_id)
			client.session_code = info.session_code
			client.remote_relay = info.network_kind == 3
			client.last_packet_timestamp = os.time()
			metadata.sender_id = client_id -- for response
			clear_old_packets(client_id)

			LogEvent("CONNECTION", "Accepting client's handshake. Connection by %s address.", info.network_kind == 1 and "local" or info.network_kind == 2 and "public" or "relay")

			local myaddr = info.network_kind == 1 and Multiplayer.my_private_addr(info.session_code) or Multiplayer.my_public_addr()
			local t = {
				can_join = true,
				client_id = client_id,
				server_id = Multiplayer.my_id,
				map_id = Map.MapStatsIndex,
				addr = myaddr,
				network_kind = info.network_kind,
				session_code = Multiplayer.my_session_code()
			}
			return item_to_bin(t)
		end,
		check_delivery = true,
		compress = true,
		allow_anonymous = true,
		ignore_reload_count = true
	},

	handshake_server = {
		bulb = function(handler_result)
			return handler_result
		end,
		response = 'client_i_join',
		handler = function(bin_string, metadata)
			LogEvent("CONNECTION", "Server's handshake received.")
			local t = bin_to_item(toptr(bin_string))
			LogEvent("CONNECTION", "Server's handshake parsed.")

			local host = Multiplayer.connector.clients[0]
			if host and t.session_code ~= host.session_code then -- already joined other server
				LogEvent("CONNECTION", "Ignoring server's handshake: i'm client of other host.")
				return nil
			end

			if not t.can_join then
				LogEvent("CONNECTION", "Joining refused.")
				t.error = t.error or 'undefined_error'
				return t
			end

			Multiplayer.my_id = t.client_id
			LogEvent("CONNECTION", "My id set to %s.", t.client_id)

			local client_id, client = Multiplayer.addclient(t.addr, t.server_id)
			client.session_code = t.session_code
			client.map = t.map_id
			client.in_game = true
			client.remote_relay = t.network_kind == 3
			LogEvent("CONNECTION", "Host's entry created")

			Multiplayer.GlobalData().Connections[client.session_code] = Multiplayer.my_session_code()
			Multiplayer.SaveGlobalData()

			LogEvent("CONNECTION", "My id set to %s, server's id is %s, client entry for host created. Calling 'ClientJoined' event.", t.client_id, t.server_id)
			events.Call("ClientJoined", client)

			return t
		end,
		check_delivery = true,
		allow_anonymous = true,
		ignore_reload_count = true
	},

	client_i_join = {
		bulb = function(response)
			if not response then
				return nil
			elseif response.can_join then
				LogEvent("CONNECTION", "Calling 'GatherClientInitData' event.")
				local t = {}
				events.Call("GatherClientInitData", t) -- cross references are forbidden. MMExt tables must be converted into regular ones or dumped as strings.
				LogEvent("CONNECTION", "Sending client init data.")
				return item_to_bin(t)
			else
				LogEvent("CONNECTION", "Server rejected connection: %s.", response.error)
				debug.Message("Could not join server: " .. response.error)
				return nil
			end
		end,
		response = 'send_initial_data',
		handler = function(bin_string, metadata)
			local client = Multiplayer.connector.clients[metadata.sender_id]
			if not client then
				LogEvent("CONNECTION", "ERROR: client entry %s does not exist at moment of receiving client's initial data.", metadata.sender_id)
				return
			end

			LogEvent("CONNECTION", "Client's initial data received, calling 'ClientJoined' (id #%s) and 'ProcessClientInitData' events.", metadata.sender_id)
			events.Call("ProcessClientInitData", metadata.sender_id, bin_to_item(toptr(bin_string)))
			return metadata.sender_id
		end,
		compress = true,
		check_delivery = true,
		ignore_reload_count = true
	},

	send_initial_data = {
		bulb = function(client_id)
			local client = Multiplayer.connector.clients[client_id]
			if not client or client.in_game then
				LogEvent("CONNECTION", "Initital data generation aborted, client #%s don't exist or already in game.", tostring(client_id))
				return
			end

			for hash, packet in pairs(Multiplayer.outgoing_packets()) do
				if packet.delivery_to == client_id and packet.settings.name == "send_initial_data" then
					LogEvent("CONNECTION", "Initital data generation aborted, already sending it to client #%s (message hash: %s).", tostring(client_id), hash)
					packet:send_next_part()
					return
				end
			end

			LogEvent("CONNECTION", "Generating initial data for client #%s, calling 'GatherServerInitData' event.", client_id)
			local t = {}
			events.Call("GatherServerInitData", t)
			return item_to_bin(t)
		end,
		response = 'client_init_state',
		handler = function(bin_string, metadata)
			local data = bin_to_item(toptr(bin_string))
			if not data then
				LogEvent("CONNECTION", "ERROR: received '%s' as server's initial data.", tostring(data))
				return false
			end

			LogEvent("CONNECTION", "Calling 'ProcessServerInitData' event.")
			events.Call("ProcessServerInitData", data)
			return true
		end,
		compress = true,
		check_delivery = true,
		ignore_reload_count = true
	},

	client_init_state = {
		bulb = function(state)
			LogEvent("CONNECTION", "Responding with result of processing initial data: %s", tostring(state))
			if state then
				return 'mminitsuccess'
			end
		end,
		handler = function(bin_string, metadata)
			local client = Multiplayer.connector.clients[metadata.sender_id]
			if bin_string == 'mminitsuccess' then
				LogEvent("CONNECTION", "Client #%s successfully joined, 'in_game' flag of client's entry set.", metadata.sender_id)
				client.in_game = true
				events.Call("ClientJoined", client)
			else
				LogEvent("CONNECTION", "Client #%s could not join due to fail in initial data handling.", metadata.sender_id)
				Multiplayer.remove_client(metadata.sender_id)
				--events.Call("ClientLeft", metadata.sender_id, client)
			end
		end,
		check_delivery = true,
		ignore_reload_count = true
	},

	-- connection holding --

	ping_request = {
		response = 'ping_response',
		check_delivery = true,
		ignore_reload_count = true
	},

	ping_response = {},

	clients_list = {
		bulb = function()
			local t = {}
			for i, v in pairs(Multiplayer.connector.clients) do
				t[i] = v.session_code
			end
			t[Multiplayer.my_id] = Multiplayer.my_session_code()
			return item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			LogEvent("CONNECTION", "Received participants list.")
			local t = bin_to_item(toptr(bin_string))
			t[Multiplayer.my_id] = nil

			local function puncher(session_ids)
				Multiplayer.connector:set_connections(session_ids)

				local clients = Multiplayer.connector.clients

				local obsolete = {}
				for client_id, client in pairs(clients) do
					if not session_ids[client_id] then
						obsolete[client_id] = client
					end
				end
				for client_id, client in pairs(obsolete) do
					clear_old_packets(client_id)
					events.Call("ClientLeft", client.id, client)
					LogEvent("CONNECTION", "Client %s removed: is not present in received participants list.", client.id)
				end

				local new_clients = {}
				for client_id, session_code in pairs(session_ids) do
					if not clients[client_id] or clients[client_id].session_code ~= session_code then
						clear_old_packets(client_id)
						new_clients[client_id] = session_code
					end
				end

				local timeout = os.time() + 16
				local all_established = false
				while not all_established do
					Multiplayer.connector:punch_connections(true)
					coroutine.yield()
					all_established = true
					for _, conn in pairs(Multiplayer.connector.connections) do
						if not (conn.local_established or conn.public_established) then
							all_established = false
						end
					end

					if os.time() > timeout then
						LogEvent("CONNECTION", "Could not establish connections with all participants within time limit.")
						break
					end
				end

				if all_established then
					LogEvent("CONNECTION", "Successfully established connections with all participants from received list.")
				end

				for client_id, session_code in pairs(new_clients) do
					local conn = Multiplayer.connector.connections[session_code]
					local addr, port

					if conn and conn.local_established then
						addr, port = conn.local_addr, conn.local_port
					elseif conn and conn.public_established then
						addr, port = conn.public_addr, conn.public_port
					else
						LogEvent("CONNECTION", "Could not establish connection with participant #%s: %s, using host-relay.", client_id, session_code)
					end

					local host_relay = false
					local remote_relay = false
					if not addr then
						local priv, pub = Multiplayer.addr_from_session_code(session_code)
						if Multiplayer.internet_connection then
							addr, port = pub:match("(%A*):(%d*)")
						else
							addr, port = priv:match("(%A*):(%d*)")
						end
						host_relay = true
						remote_relay = Multiplayer.connector.clients[Multiplayer.main_player_in_game()].remote_relay
					end

					local client = clients[client_id] or Multiplayer.connector:add_client(addr, port, client_id) and clients[client_id]
					if client then
						client.session_code = session_code
						client.in_game = true
						client.host_relay = host_relay or Multiplayer.debug.force_host_relay
						client.remote_relay = remote_relay
						client.addr = addr
						client.port = port
						Multiplayer.request_player_stats(client_id)
					end
				end
			end

			local co_puncher = coroutine.create(puncher)
			assert(coroutine.resume(co_puncher, t))
			Multiplayer.utils.CoMillisecCounter(co_puncher, Multiplayer.UDP_PUNCH_PERIOD)
		end,
		check_delivery = true,
		ignore_reload_count = true
	}

	-- debug

	--network_error = {
	--	bulb = function(reason)
	--		return reason
	--	end,
	--	handler = function(bin_string, metadata)
	--		local msg = ("Error notification from player #%s: %s"):format(metadata.sender_id, bin_string)
	--		LogEvent("NETWORK", msg)
	--		debug.Message(msg)
	--	end
	--},

}

--Multiplayer.send_error = function(client_id, message)
--	LogEvent("NETWORK", "Notifying player #%s about error: %s", client_id, message)
--	Multiplayer.add_to_send_queue(client_id, packets.network_error:prep(message))
--end

local code = 0
local packet_by_code = {}
local function init_packets(t)
	local by_name = {}
	for k, v in pairs(t) do
		v.name = k
		table.insert(by_name, v)
	end

	table.sort(by_name, function(v1, v2) return v1.name < v2.name end)

	for _, v in pairs(by_name) do
		if not v.code then
			code = code + 1
			v.code = code
		end
		v.prep = prep_packet
		v.same_map_only = v.same_map_only or false
		v.allow_anonymous = v.allow_anonymous or false
		v.ignore_reload_count = v.ignore_reload_count or false
		v.compress = v.compress or false
		v.check_delivery = v.check_delivery or false
		v.bulb = v.bulb or function() return '' end
		packet_by_code[v.code] = v

		if v.response and v.check_delivery and not v.handler then
			v.handler = function() return true end
		end
	end

	for _,v in pairs(by_name) do
		if type(v.response) == 'string' then
			v.response = t[v.response].code
		end
	end
end
init_packets(packets)

Multiplayer.packets = packets
Multiplayer.packet_by_code = packet_by_code
Multiplayer.utils.init_packets = init_packets

----------------------------------------------------------------
-- network invoker

local NETWORK_TRIGGER_MSG = 0x7001
local NETWORK_ON_FLAG = mem.StaticAlloc(4)

local function network_cycle()
	Multiplayer.sendall(32)
	Multiplayer.connector:receiveall()
	Multiplayer.request_resends()
	events.Call("NetworkCycle")
end
Multiplayer.network_cycle = network_cycle

function events.WindowMessage(t)
	if t.Msg == NETWORK_TRIGGER_MSG then
		t.Handled = true
		if Multiplayer.connector then
			network_cycle()
		end
	end
end

local dllSleep = mem.GetProcAddress(mem.dll["kernel32"]["?ptr"], "Sleep")
local dllPostMessage = mem.GetProcAddress(mem.dll["user32"]["?ptr"], "PostMessageA")

local NETWROK_INVOKER = mem.asmproc([[
	@loop:
	mov eax, dword [ds:]] .. NETWORK_ON_FLAG .. [[];
	test eax, eax
	je @end

	push 0
	push 0
	push ]] .. NETWORK_TRIGGER_MSG .. [[;
	push ]] .. Game.WindowHandle .. [[;
	call absolute ]] .. dllPostMessage .. [[;

	push 48
	call absolute ]] .. dllSleep .. [[;
	jmp @loop

	@end:
	retn
]])

function events.MultiplayerStarted()
	u1[NETWORK_ON_FLAG] = 1
	mem.dll['kernel32'].CreateThread(0, 0, NETWROK_INVOKER, 0, 0, 0)
	LogEvent("INTERNAL", "Network invoker thread started.")
end

function events.MultiplayerStopped()
	u1[NETWORK_ON_FLAG] = 0
end

-------------------------------------------------------------------------
-- sender
Multiplayer.require("Network/Sender.lua")

----------------------------------------------------------------
-- receiver
Multiplayer.require("Network/Receiver.lua")

----------------------------------------------------------------
-- connection holding

Multiplayer.CLIENT_TIMEOUT_PERIOD = 30
Multiplayer.LOADING_TIMEOUT_PERIOD = 300
local function check_clients_connections()
	if Multiplayer.CLIENT_TIMEOUT_PERIOD == 0 then
		return
	end

	local timestamp = os.time()
	local clients_left = {}
	for client_id, client in pairs(Multiplayer.connector.clients) do
		local diff = timestamp - client.last_packet_timestamp
		local limit = client.loading and Multiplayer.LOADING_TIMEOUT_PERIOD or Multiplayer.CLIENT_TIMEOUT_PERIOD
		if diff > limit then
			table.insert(clients_left, client)
		elseif diff > limit * 0.5 then
			Multiplayer.add_to_send_queue(client_id, packets.ping_request:prep())
		end
	end

	for _, client in pairs(clients_left) do
		debug.Message(string.format("Client %s timed out.", client.id))
		events.Call("ClientLeft", client.id, client)
		LogEvent("CONNECTION", "Client %s timed out.", client.id)
		if client.id == 0 then
			events.Call("HostLeft")
		end
	end
end

Multiplayer.utils.MillisecCounter(check_clients_connections, 5000)

function events.ClientChangeMap(client_id, old, new)
	local client = Multiplayer.connector.clients[client_id]
	if client then
		client.loading = new == -1 or nil
	end
end

function events.MapLoadingDone()
	local timestamp = os.time()
	for _, client in pairs(Multiplayer.connector.clients) do
		client.last_packet_timestamp = timestamp
	end
end

function events.MultiplayerStopped()
	table.clear(Multiplayer.outgoing_packets())
	table.clear(Multiplayer.incoming_packets())
end

----------------------------------------------------------------
-- client to client setup

function events.ClientJoined(client)
	LogEvent("EVENTS", "ClientJoined event fired, client id: %s", client.id)
	if Multiplayer.im_host() then
		LogEvent("CONNECTION", "I'm host, broadcasting updated participants list.")
		Multiplayer.broadcast(packets.clients_list:prep(), nil)
	end
end

function events.ClientLeft(client_id, client)
	Multiplayer.connector:remove_client(client_id)
	if Multiplayer.im_host() then
		Multiplayer.broadcast(packets.clients_list:prep(), nil)
	end
end

----------------------------------------------------------------
-- log sending

Multiplayer.LogsSender = Multiplayer.require("Network/LogsSender.lua")

----------------------------------------------------------------
-- lobby

Multiplayer.Lobby = Multiplayer.require("Network/Lobby.lua")


