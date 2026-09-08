local events = Multiplayer.events

local REMOTE_TEXT = "%s bounty hunt completed!"
local TARGET_ELIMINATED_TEXT = "%s eliminated bounty hunt target."

local function FullMapName(FileName)
	local Name = FileName:lower()
	for i, v in Game.MapStats do
		if v.FileName:lower() == Name then
			return v.Name
		end
	end
	return ""
end

local packets = {
	request_active_bounty = {
		bulb = function(MapName, Month)
			return Multiplayer.utils.item_to_bin{MapName, Month}
		end,
		handler = function(bin_string, metadata)
			local t = Multiplayer.utils.binstr_to_item(bin_string)
			local MapName, Month = t[1], t[2]

			local Entry = vars.BountyHunt and vars.BountyHunt[MapName]
			if Entry and Entry.Month == Month then
				return Entry
			end
			return false
		end,
		check_delivery = true,
		response = "response_active_bounty"
	},

	response_active_bounty = {
		bulb = function(Entry)
			if Entry then
				return Multiplayer.utils.item_to_bin(Entry)
			end
			return "\0"
		end,
		handler = function(bin_string, metadata)
			if bin_string == "\0" then
				return false
			else
				return Multiplayer.utils.binstr_to_item(bin_string)
			end
		end,
		check_delivery = true
	},

	bounty_hunt_started = {
		bulb = function(MapName, Entry)
			return Multiplayer.utils.item_to_bin{MapName, Entry}
		end,
		handler = function(bin_string, metadata)
			local t = Multiplayer.utils.binstr_to_item(bin_string)
			local MapName, Entry = t[1], t[2]
			vars.BountyHunt = vars.BountyHunt or {}
			vars.BountyHunt[MapName] = Entry
		end,
		check_delivery = true,
		compress = true,
	},

	reward_claimed = {
		bulb = function(MapName, GoldAmount)
			return Multiplayer.utils.item_to_bin{MapName, GoldAmount}
		end,
		handler = function(bin_string, metadata)
			local t = Multiplayer.utils.binstr_to_item(bin_string)
			local MapName, Reward = t[1], t[2]
			BountyHuntFunctions.AddBountyHuntReward(Reward, true)
			Game.ShowStatusText(REMOTE_TEXT:format(FullMapName(MapName)))
			for i,v in Party do
				v:ShowFaceAnimation(const.FaceAnimation.SkillIncreased)
			end

			vars.BountyHunt = vars.BountyHunt or {}
			vars.BountyHunt[MapName] = BountyHuntFunctions.NewEntry(Game.Month, 0, true, true)
		end,
		check_delivery = true
	},

	target_eliminated = {
		bulb = function(MapName)
			return MapName
		end,
		handler = function(bin_string, metadata)
			if vars.BountyHunt and vars.BountyHunt[bin_string] then
				vars.BountyHunt[bin_string].Done = true
				if Map.MapStatsIndex == metadata.map_id then
					Game.ShowStatusText(TARGET_ELIMINATED_TEXT:format(Multiplayer.client_name(metadata.sender_id, true, false)))
				end
			end
		end,
		check_delivery = true
	},
}
Multiplayer.utils.init_packets(packets)

-- ask the others for this month's bounty as soon as the map is up, so the
-- town hall dialog finds it already there
local function prefetch_bounty()
	if Multiplayer.alone_on_map() then
		return
	end

	local map_name, month = Map.Name, Game.Month
	Multiplayer.ask_all(Multiplayer.utils.cond_same_map, packets.request_active_bounty, 4, function(results)
		if Map.Name ~= map_name then
			return
		end
		vars.BountyHunt = vars.BountyHunt or {}
		local mine = vars.BountyHunt[map_name]
		if mine and mine.Month == month then
			return
		end
		for _, response in pairs(results) do
			if response and type(response.handler_result) == "table" then
				vars.BountyHunt[map_name] = response.handler_result
				return
			end
		end
	end, map_name, month)
end
events.MapLoadingDone = prefetch_bounty

-- fallback for a town hall visit that beats the prefetch answer
function events.BountyHuntGeneration(t) -- MapName, Handled, Entry
	if Multiplayer.alone_on_map() then
		return
	end

	local hashes = Multiplayer.broadcast(packets.request_active_bounty:prep(Map.Name, Game.Month), nil)
	local responses = Multiplayer.wait_responses(hashes, 2)

	for _, response in pairs(responses) do
		if response and response.handler_result then
			vars.BountyHunt[Map.Name] = response.handler_result
			t.Handled = true
		end
	end
end

function events.NewBountyHuntCreated(MapName, Entry, Monster)
	Multiplayer.broadcast(packets.bounty_hunt_started:prep(MapName, Entry), nil)
	Multiplayer.SyncMonsters.broadcast_full_monster_data(Monster:GetIndex())
end

function events.BountyHuntRewardClaimed(MapName, Reward)
	Multiplayer.broadcast(packets.reward_claimed:prep(MapName, Reward), nil)
end

function events.BountyHuntEliminated(MapName, Entry, Monster)
	Multiplayer.broadcast(packets.target_eliminated:prep(MapName), nil)
end
