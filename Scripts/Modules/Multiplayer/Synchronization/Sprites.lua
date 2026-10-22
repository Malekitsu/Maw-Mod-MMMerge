local std_events = events
local events = Multiplayer.events
local mstr, mcopy, toptr = mem.string, mem.copy, mem.topointer
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item
local fill_table = Multiplayer.utils.fill_table
local mmt_dump = Multiplayer.utils.mmt_dump
local LogEvent = Multiplayer.utils.LogEvent

local last_sprite_state = {}
local last_light_state = {lights = {}, sprite_lights = {}}
local last_sprites_bin
local last_active_sprites = {}

Multiplayer.debug.last_sprite_state = function()
	return last_sprite_state
end
Multiplayer.debug.last_light_state = function()
	return last_light_state
end

Multiplayer.sprites_loaded = true

local compare_fields = {'DecName', 'EventVariable', 'X', 'Y', 'Z', 'Bits'}
local function fill_sprite_state(i)
	if i >= Map.Sprites.count then
		LogEvent("SYNC", "Attempt to fill state of sprite outside of bounds (%s).", i)
	end

	local sprite = Map.Sprites[i]
	local state = last_sprite_state[i]
	if not state then
		state = {}
		last_sprite_state[i] = state
	end

	for _, v in pairs(compare_fields) do
		state[v] = sprite[v]
	end
	state.EventVariable2 = mapvars.ActiveSprites[i]
end

local function sprite_need_send(i, sprite)
	if bit.And(sprite.Bits, Multiplayer.NO_SYNC_OBJECT_BIT) > 0 then
		return false
	end

	local last_state = last_sprite_state[i]
	if not last_state then
		fill_sprite_state(i)
		return false
	end

	if last_state.EventVariable2 ~= mapvars.ActiveSprites[i] then
		return true
	end

	for _, v in pairs(compare_fields) do
		if last_state[v] ~= sprite[v] then
			return true
		end
	end

	return false
end
Multiplayer.debug.sprite_need_send = sprite_need_send

local function sprites_unchanged()
	local count = Map.Sprites.count
	local bin = count > 0 and mstr(Map.Sprites[0]["?ptr"], count * structs.MapSprite["?size"], true) or ""
	local same = bin == last_sprites_bin
	last_sprites_bin = bin

	local active = mapvars.ActiveSprites
	for k, v in pairs(active) do
		if last_active_sprites[k] ~= v then
			same = false
			break
		end
	end
	if same then
		for k, v in pairs(last_active_sprites) do
			if active[k] ~= v then
				same = false
				break
			end
		end
	end
	if not same then
		last_active_sprites = {}
		for k, v in pairs(active) do
			last_active_sprites[k] = v
		end
	end
	return same
end

local function light_need_send(i, light, tname, field)
	if light.Type == Multiplayer.DETACHABLE_LIGHT_TYPE then
		return false -- light position controlled by other scripts
	end

	local last_state = last_light_state[tname][i]
	if not last_state then
		last_state = {[field] = light[field]}
		last_light_state[tname][i] = last_state
		return false
	end

	if last_state[field] ~= light[field] then
		last_state[field] = light[field]
		return true
	end

	return false
end

local packets = {
	sprites_info = {
		bulb = function()
			if sprites_unchanged() then
				return nil
			end
			local to_send = {}
			local need_send = false
			local state
			for i, sprite in Map.Sprites do
				if sprite_need_send(i, sprite) then
					to_send[i] = sprite
					need_send = true
					fill_sprite_state(i)
				end
			end

			if need_send then
				local bulb = {}
				local EvVars = {}
				local size = structs.MapSprite['?size']
				for i, sprite in pairs(to_send) do
					bulb[i] = mstr(sprite['?ptr'], size, true)
					EvVars[i] = mapvars.ActiveSprites[i]
				end
				return item_to_bin({sprites = bulb, ev_vars = EvVars})
			end

			return nil -- no info to send
		end,
		handler = function(bin_string, metadata)
			local data = bin_to_item(toptr(bin_string))

			for i, sbin in pairs(data.sprites) do
				if i >= Map.Sprites.count then
					Map.Sprites.count = i + 1
				end

				local sprite = Map.Sprites[i]
				local old_name = sprite.DecName

				mcopy(sprite['?ptr'], sbin)

				if old_name ~= sprite.DecName then
					ChangeSprite(i, sprite.DecName)
				end
				mapvars.ActiveSprites[i] = data.ev_vars[i]
				if sprite.Event ~= 0 then
					Game.ReInitSpriteEvent(i, true)
				end
				fill_sprite_state(i)
			end
		end,
		check_delivery = true,
		same_map_only = true,
		compress = true
	},

	lights_info = {
		bulb = function()
			local to_send = {lights = {}, sprite_lights = {}}
			local need_send = false

			for i,v in Map.Lights do
				if light_need_send(i, v, 'lights', 'Off') then
					to_send.lights[i] = mmt_dump(v)
					need_send = true
				end
			end
			for i,v in Map.SpriteLights do
				if light_need_send(i, v, 'sprite_lights', 'Radius') then
					to_send.sprite_lights[i] = mmt_dump(v)
					need_send = true
				end
			end

			if need_send then
				return item_to_bin(to_send)
			end

			return nil
		end,
		handler = function(bin_string, metadata)
			local data = bin_to_item(toptr(bin_string))
			if data.lights then
				for i,v in pairs(data.lights) do
					if i >= Map.Lights.count then
						break
					end
					mcopy(Map.Lights[i]['?ptr'], v)
				end
			end
			if data.sprite_lights then
				for i,v in pairs(data.sprite_lights) do
					if i >= Map.SpriteLights.count then
						break
					end
					mcopy(Map.SpriteLights[i]['?ptr'], v)
				end
			end
			LogEvent("SYNC", "%s: Got lights data from #%s.", os.time(), metadata.sender_id)
		end,
		check_delivery = true,
		same_map_only = true,
		compress = true
	}
}
Multiplayer.utils.init_packets(packets)

-- MapLoad
Multiplayer.debug.sprites_update_amount = 32

function events.MultiplayerPrepMapData(t)
	if Map.Sprites.count == 0 then
		return
	end

	t.ActiveSprites = mapvars.ActiveSprites
	t.LightSrcsConns = mapvars.LightSrcsConns

	if Map.Sprites.count > 0 then
		t.sprites = {
			count = Map.Sprites.count,
			bin = mstr(Map.Sprites[0]["?ptr"], Map.Sprites.count * Map.Sprites[0]["?size"], true)
		}
	end

	if Map.IsIndoor() and Map.Lights.count > 0 then
		t.lights = {
			count = Map.Lights.count,
			bin = mstr(Map.Lights[0]["?ptr"], Map.Lights.count * Map.Lights[0]["?size"], true)
		}
	end
end

function events.MultiplayerProcessMapData(t)
	LogEvent("MAP_LOAD", "Processing sprites info: %s.", type(t.sprites))

	Multiplayer.sprites_loaded = false

	if t.ActiveSprites then
		mapvars.ActiveSprites = t.ActiveSprites
	end
	if t.LightSrcsConns then
		mapvars.LightSrcsConns = t.LightSrcsConns
	end

	if t.sprites then
		mcopy(Map.Sprites["?ptr"], t.sprites.bin)
		Map.Sprites.count = t.sprites.count
		Game.ReInitSprites(true)
		for i, sprite in Map.Sprites do
			if sprite.DecListId > 0 then
				Game.LoadDecSprite(sprite.DecName)
			end
		end
	end
	Multiplayer.sprites_loaded = true
	events.Call("MultiplayerSpritesLoaded")

	if t.lights then
		Map.Lights.count = t.lights.count
		mcopy(Map.Lights[0]["?ptr"], t.lights.bin)
	end
end

----

local function process_sprites_sync()
	if Multiplayer.leave_map_halt or not Multiplayer.sprites_loaded then
		return
	end

	local data = packets.sprites_info:prep()
	if data then
		Multiplayer.broadcast(data, Multiplayer.utils.cond_same_map)
	end
end

local function process_lights_sync()
	if not Map.IsIndoor() or Multiplayer.leave_map_halt or Game.CurrentScreen ~= 0 then
		return
	end

	local data = packets.lights_info:prep()
	if data then
		Multiplayer.broadcast(data, Multiplayer.utils.cond_same_map)
	end
end

function events.LeaveMap()
	last_light_state = {lights = {}, sprite_lights = {}}
	last_sprite_state = {}
	last_sprites_bin = nil
	last_active_sprites = {}
end

Multiplayer.utils.TickCounter(process_sprites_sync, 16)
Multiplayer.utils.TickCounter(process_lights_sync, 16)

---- Prevent save map data corruption by extra sprites

local OriginSpritesCount = 0
local ModifiedSpritesCount = 0

function std_events.LoadMapScripts()
	OriginSpritesCount = Map.Sprites.count
end

function std_events.BeforeSaveGame()
	ModifiedSpritesCount = Map.Sprites.count
	Map.Sprites.count = OriginSpritesCount
end

function std_events.AfterSaveGame()
	Map.Sprites.count = ModifiedSpritesCount
end
