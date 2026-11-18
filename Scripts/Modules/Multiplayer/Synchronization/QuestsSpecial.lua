local events = Multiplayer.events
local item_to_bin, binstr_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.binstr_to_item

----------------------------------------------------------
-- MM6 ending

local mm6_packets = {
	have_scroll = {
		response = 'have_scroll_response',
		check_delivery = true
	},

	have_scroll_response = {
		bulb = function()
			return  evt.ForPlayer("All").Cmp{"Inventory", 2164} and "\1" or "\0"
		end,
		handler = function(bin_string, metadata)
			return bin_string == "\1"
		end,
		check_delivery = true,
	}
}
Multiplayer.utils.init_packets(mm6_packets)

function events.MM6ReactorKilled(t)
	Multiplayer.utils.LogEvent("EVENTS", "MM6ReactorKilled event handled")

	if t.HaveScroll then
		return
	end

	local hashes = {}
	Multiplayer.broadcast_keep_hash(mm6_packets.have_scroll, Multiplayer.utils.cond_same_map, hashes)

	local responses = Multiplayer.wait_responses(hashes, 6)
	for _, response in pairs(responses) do
		if response and response.handler_result then
			t.HaveScroll = true
			break
		end
	end
end

----------------------------------------------------------
-- Nonstructured data

local SupportedEvents = {}

local packets = {
	map_userdata = {
		bulb = function(t, event_name)
			local success, result = pcall(item_to_bin, {data = t, event = event_name})
			if not success then
				Multiplayer.utils.LogEvent("NETWORK", "Error, while encoding user mapdata:\n%s", result)
				return nil
			end
			return result
		end,
		handler = function(bin_string, metadata)
			local success, result = pcall(binstr_to_item, bin_string)
			if not success then
				Multiplayer.utils.LogEvent("NETWORK", "Error, while decoding user mapdata:\n%s", result)
				return
			end
			if result.event then
				if SupportedEvents[result.event] then
					events.call(result.event, result.data)
				else
					Multiplayer.utils.LogEvent("NETWORK", "Forbidden event call arrived from player %s: %s", metadata.sender_id, event_name)
				end
			else
				events.call("MultiplayerUserdataArrived", result.data)
			end
		end,
		compress = true,
		check_delivery = true,
		same_map_only = true
	},

	quest_userdata = {
		bulb = function(t, event_name)
			local success, result = pcall(item_to_bin, {event_name, t})
			if not success then
				Multiplayer.utils.LogEvent("NETWORK", "Error, while encoding user questdata:\n%s", result)
				return nil
			end
			return result
		end,
		handler = function(bin_string, metadata)
			local success, result = pcall(binstr_to_item, bin_string)
			if not success then
				Multiplayer.utils.LogEvent("NETWORK", "Error, while decoding user questdata:\n%s", result)
				return
			end
			local event_name = result[1]
			if SupportedEvents[event_name] then
				events.call(event_name, result[2])
			else
				Multiplayer.utils.LogEvent("NETWORK", "Forbidden event call arrived from player %s: %s", metadata.sender_id, event_name)
			end
		end,
		compress = true,
		check_delivery = true
	},
}
Multiplayer.utils.init_packets(packets)

Multiplayer.broadcast_mapdata = function(t, event_name)
	if Multiplayer.in_game then
		Multiplayer.broadcast(packets.map_userdata:prep(t, event_name), Multiplayer.utils.cond_same_map)
	end
end

Multiplayer.broadcast_questdata = function(t, event_name)
	assert(event_name)
	if Multiplayer.in_game then
		Multiplayer.broadcast(packets.quest_userdata:prep(t, event_name), nil)
	end
end

Multiplayer.allow_remote_event = function(event_name)
	SupportedEvents[event_name] = true
end
