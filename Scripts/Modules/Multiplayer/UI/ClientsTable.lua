local events = Multiplayer.events

local UIUtils = Multiplayer.require("UI/UtilsUI.lua")

local clients_table

local function drop_clients()
	local session_codes = {}
	for i, line in pairs(clients_table.data) do
		table.insert(session_codes, line.session_code)
	end

	local to_drop = {}
	for i, client in pairs(Multiplayer.connector.clients) do
		if not table.find(session_codes, client.session_code) then
			table.insert(to_drop, i)
		end
	end

	for _, i in pairs(to_drop) do
		Multiplayer.remove_client(i)
	end
end

local function renum()
	for i, v in ipairs(clients_table.data) do
		v.number = i
	end
	clients_table:update()
end

local function remove_client_index(data)
	for client_id, t in pairs(clients_table.client_line) do
		if t == data then
			clients_table.client_line[client_id] = nil
			break
		end
	end
end

local function remove_line(data)
	remove_client_index(data)
	clients_table:remove_iline(data.number)
	clients_table.restart_listening()
	renum()
end

local function clear_line(data)
	remove_client_index(data)
	data.session_code = ""
	data.status = ""
	data.name = ""
	clients_table:iupdate(data.number)
	drop_clients()
	clients_table.restart_listening()
end

local function paste_code(data)
	data.session_code = UIUtils.GetSessionCodeFromClipboard()
	clients_table:iupdate(data.number)
	clients_table.restart_listening()
end

local function new_line()
	local n = #clients_table.data + 1
	local line = {number = n, name = string.rep(" ", 13), session_code = string.rep(" ", Multiplayer.SESSION_ID_SIZE - 5), status = "", paste = "Paste", clear = "Clear", remove = "X"}
	Multiplayer.players_amount_limit = n
	local line, i = clients_table:new_line(line)
	clients_table.data[i].session_code = ""
	return line, i
end

local function Create(baseX, baseY, Condition, ListeningStarter)
	UIUtils.SimpleText(Multiplayer.UI_SCREEN, "Clients:", baseX, baseY + 75, nil, Condition)
	UIUtils.SimpleText(Multiplayer.UI_SCREEN, "add line", baseX + 128, baseY + 75, nil, Condition, new_line)

	clients_table = UIUtils.TextTable(
		Multiplayer.UI_SCREEN,
		{"number", "name", "session_code", "status", "paste", "clear", "remove"},
		baseX, baseY + 100, Condition,
		{paste = paste_code, clear = clear_line, remove = remove_line})

	clients_table.client_line = {}
	clients_table.restart_listening = ListeningStarter

	new_line()
	new_line()
	new_line()

	return clients_table
end

-- Events

function events.ConnectionTestStarted(session_code)
	if Game.CurrentScreen ~= Multiplayer.UI_SCREEN then
		return
	end

	for _, line in pairs(clients_table.data) do
		if line.session_code == session_code then
			line.status = "..."
		end
	end
end

function events.ConnectionTestFinished(session_code, conn)
	if Game.CurrentScreen ~= Multiplayer.UI_SCREEN then
		return
	end

	local data
	for _, line in pairs(clients_table.data) do
		if line.session_code == session_code then
			data = line
			break
		end
	end

	if not data then
		return
	end

	local function ConnColor(str, n)
		if n == 1 then -- green
			return StrColor(0,255,0) .. str .. StrColor(255,255,255)
		elseif n == 2 then -- yellow
			return StrColor(255,255,0) .. str .. StrColor(255,255,255)
		else -- red
			return StrColor(255,0,0) .. str .. StrColor(255,255,255)
		end
	end

	local status =
		conn.local_established and ConnColor("LAN", 1) or
		conn.public_established and ConnColor("p2p", 1) or
		conn.relay_established and ConnColor("relay", 2) or
		ConnColor("X", 3)

	data.status = status
	clients_table:iupdate(data.number)
end

function events.ProcessClientInitData(client_id)
	local client = Multiplayer.connector.clients[client_id]
	if not client then
		return
	end

	local data = clients_table.client_line[client_id]
	if data then
		data.session_code = client.session_code
		data.name = client.name
		clients_table:iupdate(data.number)
		return
	end

	for i, line in pairs(clients_table.data) do
		if line.session_code == client.session_code then
			line.name = client.name
			clients_table:iupdate(line.number)
			clients_table.client_line[client_id] = line
			return
		end
	end

	for i, line in pairs(clients_table.data) do
		if line.session_code == "" then
			line.session_code = client.session_code
			line.name = client.name
			clients_table:iupdate(line.number)
			clients_table.client_line[client_id] = line
			return
		end
	end

	local line, i = new_line()
	local data = clients_table.data[i]
	data.session_code = client.session_code
	data.name = client.name
	clients_table:iupdate(i)
	clients_table.client_line[client_id] = data
end

function events.MultiplayerStopped()
	for k, line in pairs(clients_table.data) do
		line.name = ""
		line.session_code = ""
		line.status = ""
	end
	clients_table:update()
	table.clear(clients_table.client_line)
end

function events.ClientLeft(client_id, client)
	local data = clients_table.client_line[client_id]
	if data then
		data.name = ""
		data.session_code = ""
		data.status = ""
		clients_table:iupdate(data.number)
		clients_table.client_line[client_id] = nil
		return
	end

	for i, line in pairs(clients_table.data) do
		if line.session_code == client.session_code then
			line.name = ""
			line.session_code = ""
			line.status = ""
			clients_table:iupdate(i)
		end
	end
end

function events.ClientStatsUpdate(client_id, stats, client)
	local data = clients_table.client_line[client_id]
	if data then
		data.name = stats.name
		if Game.CurrentScreen == Multiplayer.UI_SCREEN then
			clients_table:iupdate(data.number)
		end
	end
end

function events.ClientJoined(client)
	for i, line in pairs(clients_table.data) do
		if line.session_code == client.session_code then
			clients_table.client_line[client.id] = line
			return
		end
	end

	local line, i
	for k, v in pairs(clients_table.data) do
		if v.session_code == "" then
			line = v
			i = k
			break
		end
	end

	if not line then
		line, i = new_line()
	end

	local data = clients_table.data[i]
	data.session_code = client.session_code
	data.name = client.name
	clients_table:iupdate(i)
	clients_table.client_line[client.id] = data
end

return {
	Create = Create
}
