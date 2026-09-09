-- Claims.lua -- who owns what: one arbiter per scope, optimistic claims
-- everywhere else, per-kind callbacks for "granted" and "lost".
--
-- A kind is anything players compete for (an object on the ground, a corpse,
-- a chest, a shop stock, an NPC dialog). Claims.try marks the thing as ours
-- at once and asks the arbiter in the background; the arbiter grants first
-- come first served. Only the rollback stays specific to the kind.

local events = Multiplayer.events
local LogEvent = Multiplayer.utils.LogEvent
local cond_same_map = Multiplayer.utils.cond_same_map
local item_to_bin, binstr_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.binstr_to_item

local Claims = {}
Multiplayer.Claims = Claims

local CLAIM_TIMEOUT = 5 -- seconds without a verdict: the claimant keeps it

local kinds = {}	-- kind -> {scope = "map"|"game", announce = bool, on_granted, on_lost, on_timeout}
local claims = {}	-- kind -> id -> owner client id
local pending = {}	-- kind -> id -> {ctx = ...} while the arbiter has not answered

-- Claims.define("chest", {scope = "map", on_granted = f(id, ctx), on_lost = f(id, ctx), on_timeout = f(id, ctx)})
-- announce = false keeps grants off the wire for kinds whose outcome travels by other means
function Claims.define(kind, def)
	def.scope = def.scope or "map"
	if def.announce == nil then
		def.announce = true
	end
	kinds[kind] = def
	claims[kind] = claims[kind] or {}
	pending[kind] = pending[kind] or {}
end

function Claims.owner(kind, id)
	return claims[kind] and claims[kind][id]
end

function Claims.list(kind)
	return claims[kind] or {}
end

local function arbiter(kind)
	if kinds[kind].scope == "game" then
		return Multiplayer.main_player_in_game()
	end
	return Multiplayer.main_player_on_map()
end

local function owner_present(kind, owner)
	if owner == Multiplayer.my_id then
		return true
	end
	local client = Multiplayer.connector.clients[owner]
	if not client or not client.in_game then
		return false
	end
	if kinds[kind].scope == "map" then
		return client.map == Map.MapStatsIndex
	end
	return true
end

local packets
local function broadcast_state(kind, id, owner)
	local def = kinds[kind]
	if not def.announce then
		return
	end
	Multiplayer.broadcast(packets.claims_update:prep(kind, id, owner), def.scope == "map" and cond_same_map or nil)
end

-- arbiter side: first come first served; asking again for your own claim is fine
local function arbitrate(kind, id, claimant)
	local owner = claims[kind][id]
	if owner ~= nil and owner ~= claimant and owner_present(kind, owner) then
		return owner, false
	end
	if owner ~= claimant then
		claims[kind][id] = claimant
		broadcast_state(kind, id, claimant)
	end
	return claimant, true
end

packets = {
	claim = {
		bulb = function(kind, id)
			return item_to_bin{kind, id, Map.MapStatsIndex}
		end,
		handler = function(bin_string, metadata)
			local t = binstr_to_item(bin_string)
			local kind, id, map = t[1], t[2], t[3]
			if not kinds[kind] then
				return {kind = kind, id = id, owner = metadata.sender_id, granted = true}
			end
			if kinds[kind].scope == "map" and map ~= Map.MapStatsIndex then
				return {kind = kind, id = id, owner = metadata.sender_id, granted = true} -- not my map to arbitrate
			end
			local owner, granted = arbitrate(kind, id, metadata.sender_id)
			return {kind = kind, id = id, owner = owner, granted = granted}
		end,
		response = "claim_result",
		check_delivery = true,
	},

	claim_result = {
		bulb = item_to_bin,
		handler = function(bin_string, metadata)
			return binstr_to_item(bin_string)
		end,
		check_delivery = true,
	},

	claim_release = {
		bulb = function(kind, id)
			return item_to_bin{kind, id}
		end,
		handler = function(bin_string, metadata)
			local t = binstr_to_item(bin_string)
			local kind, id = t[1], t[2]
			if kinds[kind] and claims[kind][id] == metadata.sender_id then
				claims[kind][id] = nil
				broadcast_state(kind, id, false)
			end
		end,
		check_delivery = true,
	},

	claims_update = {
		bulb = function(kind, id, owner)
			return item_to_bin{kind, id, owner, Map.MapStatsIndex}
		end,
		handler = function(bin_string, metadata)
			local t = binstr_to_item(bin_string)
			local kind, id, owner, map = t[1], t[2], t[3], t[4]
			if not kinds[kind] then
				return
			end
			if kinds[kind].scope == "map" and map ~= Map.MapStatsIndex then
				return
			end
			if owner == false then
				claims[kind][id] = nil
			elseif not (owner == Multiplayer.my_id and pending[kind][id]) then
				-- an echo of our own pending claim is skipped: the verdict comes by claim_result
				claims[kind][id] = owner
			end
			if kinds[kind].on_update then
				kinds[kind].on_update(id, claims[kind][id])
			end
		end,
		check_delivery = true,
	},

	claims_snapshot = {
		bulb = function(scope, exclude_mine)
			local t = {scope = scope, map = Map.MapStatsIndex, kinds = {}}
			for kind, def in pairs(kinds) do
				if def.scope == scope then
					local list = {}
					for id, owner in pairs(claims[kind]) do
						if not (exclude_mine and owner == Multiplayer.my_id) then
							list[id] = owner
						end
					end
					t.kinds[kind] = list
				end
			end
			return item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			local t = binstr_to_item(bin_string)
			if t.scope == "map" and t.map ~= Map.MapStatsIndex then
				return
			end
			for kind, list in pairs(t.kinds) do
				if kinds[kind] then
					for id, owner in pairs(list) do
						if owner ~= Multiplayer.my_id then
							claims[kind][id] = owner
						end
					end
				end
			end
		end,
		check_delivery = true,
		compress = true,
	},
}
Multiplayer.utils.init_packets(packets)

-- "granted" when settled on the spot, "pending" when the arbiter is being asked
-- (the thing is ours meanwhile), "taken" when someone present already has it
function Claims.try(kind, id, ctx)
	local def = assert(kinds[kind], "unknown claim kind " .. tostring(kind))
	local mine = Multiplayer.my_id
	local owner = claims[kind][id]

	local ask = pending[kind][id]
	if ask then
		ask.release = nil
		return "pending"
	end
	if owner == mine then
		return "granted"
	end
	if owner ~= nil and owner_present(kind, owner) then
		return "taken"
	end

	local judge = arbiter(kind)
	if judge == mine then
		arbitrate(kind, id, mine)
		return "granted"
	end

	claims[kind][id] = mine
	pending[kind][id] = {ctx = ctx}
	Multiplayer.ask(judge, packets.claim, CLAIM_TIMEOUT, function(ok, response)
		local ask = pending[kind][id]
		if not ask then
			return -- map left while the answer travelled
		end
		pending[kind][id] = nil

		local verdict = ok and response.handler_result
		if ask.release then
			-- released before the verdict: hand it back only once the arbiter has seen the claim
			if not ok or type(verdict) ~= "table" or verdict.granted then
				claims[kind][id] = nil
				Multiplayer.add_to_send_queue(judge, packets.claim_release:prep(kind, id))
			else
				claims[kind][id] = verdict.owner
			end
			return
		end
		if not ok or type(verdict) ~= "table" then
			LogEvent("SYNC", "No verdict for %s #%s, keeping it", kind, tostring(id))
			if def.on_timeout then
				def.on_timeout(id, ask.ctx)
			end
		elseif verdict.granted then
			if def.on_granted then
				def.on_granted(id, ask.ctx)
			end
		else
			claims[kind][id] = verdict.owner
			LogEvent("SYNC", "Lost %s #%s to player %s", kind, tostring(id), tostring(verdict.owner))
			if def.on_lost then
				def.on_lost(id, ask.ctx)
			end
		end
	end, kind, id)
	return "pending"
end

function Claims.release(kind, id)
	if not kinds[kind] then
		return
	end
	local ask = pending[kind][id]
	if ask then
		ask.release = true
		return
	end
	if claims[kind][id] ~= Multiplayer.my_id then
		return
	end
	claims[kind][id] = nil

	local judge = arbiter(kind)
	if judge == Multiplayer.my_id then
		broadcast_state(kind, id, false)
	else
		Multiplayer.add_to_send_queue(judge, packets.claim_release:prep(kind, id))
	end
end

-- housekeeping

local function drop_owner(client_id, scope)
	for kind, def in pairs(kinds) do
		if not scope or def.scope == scope then
			for id, owner in pairs(claims[kind]) do
				if owner == client_id then
					claims[kind][id] = nil
				end
			end
		end
	end
end

local function reset(scope)
	for kind, def in pairs(kinds) do
		if not scope or def.scope == scope then
			claims[kind] = {}
			pending[kind] = {}
		end
	end
end

function events.ClientLeft(client_id)
	drop_owner(client_id)
end

function events.ClientChangeMap(client_id, old, new)
	drop_owner(client_id)
	if new == Map.MapStatsIndex and Multiplayer.main_player_on_map() == Multiplayer.my_id then
		Multiplayer.add_to_send_queue(client_id, packets.claims_snapshot:prep("map"))
	end
end

function events.ClientJoined(client)
	if Multiplayer.main_player_in_game() == Multiplayer.my_id then
		Multiplayer.add_to_send_queue(client.id, packets.claims_snapshot:prep("game"))
	end
end

-- the arbiter leaving hands the map's claims to the next main player, so a
-- chest or a stock someone is in stays taken
function events.LeaveMap()
	if Multiplayer.in_game and Multiplayer.connector and Multiplayer.main_player_on_map() == Multiplayer.my_id then
		local heir
		for client_id, client in pairs(Multiplayer.connector.clients) do
			if client.in_game and client.map == Map.MapStatsIndex and (not heir or client_id < heir) then
				heir = client_id
			end
		end
		if heir then
			Multiplayer.add_to_send_queue(heir, packets.claims_snapshot:prep("map", true))
		end
	end
	reset("map")
end

function events.MultiplayerStarted()
	reset()
end

function events.MultiplayerStopped()
	reset()
end

Multiplayer.debug.claims = function()
	return claims, pending
end
