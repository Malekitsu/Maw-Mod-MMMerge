local events = Multiplayer.events

local Markers = {}
local MapDisplayed

local function MapOffset(TopMost)
	if TopMost then
		return mem.i2[0x587ad0], mem.i2[0x587ad2]
	end
	return mem.i4[0x587ac8], mem.i4[0x587acc] -- X, Y of camera position
end

local function ZoomLevel()
	-- 384: max out,
	-- 768 - 1 in,
	-- 1536 - 2 in - max in outdoors,
	-- 3072 - max in indoors
	return mem.u4[0x587ac4]
end

local function StdCond()
	return MapDisplayed
end

 -- Map: 150:128 - 416:392
 -- Bounds: 22528:-22528
local function ClientMapPos(client_id)
	local mon = Multiplayer.get_client_mon(client_id)
	if mon then
		local X = mon.X / 22528
		local Y = mon.Y / 22528

		local zoom = ZoomLevel()
		local oX, oY = MapOffset(zoom <= 384)
		oX, oY = oX / 22528, oY / 22528
		X, Y = X - oX, Y - oY

		zoom = zoom / 384
		X, Y = X * zoom, Y * zoom

		return (X * 133 + 147 + 133):floor(), (-Y * 132 + 124 + 132):floor()
	end
	return 0, 0
end

local function RebuildMarkers()
	for _, marker in pairs(Markers) do
		CustomUI.RemoveElement(marker)
	end
	table.clear(Markers)

	for client_id, client in pairs(Multiplayer.connector.clients) do
		if client.PlayerColor then
			local X, Y = ClientMapPos(client_id)
			local marker = CustomUI.CreateText{
				Text = "*",
				X = X, Y = Y,
				Screen = const.Screens.Info,
				Condition = StdCond,
				AlignLeft = true,
				Font = Game.Create_fnt,
				Layer = 0
			}
			marker.CStd = client.PlayerColor.Number
			marker.CSh = client.PlayerColor.Shadow
			Markers[client_id] = marker
		end
	end
end

local function PosMarkers()
	for client_id, marker in pairs(Markers) do
		marker.X, marker.Y = ClientMapPos(client_id)
		marker.Active = marker.X >= 150 and marker.X <= 416 and marker.Y >= 128 and marker.Y <= 392
	end
end

local MarkersDisplayed = false
local function StartMarkersDisplay()
	RebuildMarkers()
	PosMarkers()
	MarkersDisplayed = true
	Multiplayer.utils.CoMillisecCounter(coroutine.create(
		function()
			while Game.CurrentScreen == const.Screens.Info and MapDisplayed do
				PosMarkers()
				coroutine.yield()
			end
			MarkersDisplayed = false
		end
	), 500)
end

local TrackAction = {[205] = true, [202] = true, [471] = true, [472] = true, [473] = true, [474] = true}
local TrackActionParam = {[71] = {[0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true}}
function events.Action(t)
	MapDisplayed = TrackAction[t.Action] or TrackActionParam[t.Action] and TrackActionParam[t.Action][t.Param]
	if MapDisplayed then
		if MarkersDisplayed then
			for client_id, marker in pairs(Markers) do
				marker.Active = false -- make inactive unitll next redraw
				Multiplayer.utils.delayed_call(PosMarkers, 1)
			end
		else
			StartMarkersDisplay()
		end
	end
end

local ShowPlayers = CustomUI.CreateText{
	Text = "Show players location",
	X = 186, Y = 100,
	Screen = const.Screens.Info,
	Layer = 0,
	Condition = function() return StdCond() and Multiplayer.connector:active_clients_count() > 0 end,
	Action = function()
		local texts = {}
		for client_id, client in pairs(Multiplayer.connector.clients) do
			if client.in_game then
				local mon = Multiplayer.get_client_mon(client_id)
				local color = client.PlayerColor
				local name=""
				if color then
					name = StrColor(color[1], color[2], color[3], client.name)
				else
					name = StrColor(0, 0, 0, client.name)
				end
				if mon then
					table.insert(texts, ("%s: x:%d, y:%d"):format(name, mon.X, mon.Y))
				elseif client.map then
					table.insert(texts, ("%s: %s"):format(name, Game.MapStats[client.map].Name))
				end
			end
		end
		CustomUI.DisplayTooltip(table.concat(texts, "\r\n"), 30)
	end
}
