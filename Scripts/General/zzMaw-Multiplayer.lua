-- ==== Buff share — BY RAFIKI59

function PlayersInGame()
	local count = 1
	for k,v in pairs(Multiplayer.connector.clients) do
		count = count + 1
	end
	return count
end

------------------------------------------------------------
-- ÉTAT / HELPERS
------------------------------------------------------------
local function ensure_state()
	vars = vars or {}
	vars.MAWSETTINGS = vars.MAWSETTINGS or {}
	if vars.MAWSETTINGS.buffRework == nil then vars.MAWSETTINGS.buffRework = true end
	if type(vars.MAWSETTINGS.buffRadius) ~= "number" then vars.MAWSETTINGS.buffRadius = 20000 end
	vars.MAWSETTINGS.blockSpells = vars.MAWSETTINGS.blockSpells or {}
	vars.MAWSETTINGS.blockSpells[8] = true

	vars.mawbuff						= vars.mawbuff						or {}
	vars._maw_last_sent		 = vars._maw_last_sent		 or {}
	vars.mawbuff_remote		 = vars.mawbuff_remote		 or {}
	vars.maw_remote_owners	= vars.maw_remote_owners	or {}
	vars.maw_remote_values	= vars.maw_remote_values	or {}
	vars._maw_local_off		 = vars._maw_local_off		 or {}

	-- Horloge & cadence
	vars._maw_next_send_time		 = vars._maw_next_send_time or 0
	vars._maw_clock_last				 = vars._maw_clock_last or 0
	vars._maw_last_time					= vars._maw_last_time or 0
	vars._maw_resend_boost_until = vars._maw_resend_boost_until or 0

	-- Guards
	vars._maw_sync_guard_until	 = vars._maw_sync_guard_until or 0

	-- Weak
	vars._maw_weak_protect_until = vars._maw_weak_protect_until or 0
	vars._maw_clear_weak_ticks	 = vars._maw_clear_weak_ticks or 0
end

local function isReworkOn()
	local s = vars and vars.MAWSETTINGS and vars.MAWSETTINGS.buffRework
	if s == true or s == 1 then return true end
	return type(s)=="string" and s:lower()=="on"
end

local function inMulti() return MawCore.Sync.inGame() end
local function isHost() return MawCore.Sync.isHost() end
local SEC	= const.Minute/2
local NOW	= function() return (Game and Game.Time) or 0 end
local BASE_RADIUS	= 20000
local SEND_PERIOD	= 4 * SEC
local DAY					= const.Day

local function maxSpellId()
	if Game and Game.Spells and type(Game.Spells.High)=="number" then return Game.Spells.High end
	return 300
end

local function senderId() return Multiplayer.my_id end
local function sum3(a,b,c) return (tonumber(a) or 0)+(tonumber(b) or 0)+(tonumber(c) or 0) end
local function pick_max(a,b)
	local as,am,al = a[1] or 0, a[2] or 0, a[3] or 0
	local bs,bm,bl = b[1] or 0, b[2] or 0, b[3] or 0
	if bs>as or (bs==as and (bm>am or (bm==am and bl>al))) then return b else return a end
end
local function lex_gt(a,b)
	local as,am,al = a[1] or 0, a[2] or 0, a[3] or 0
	local bs,bm,bl = b[1] or 0, b[2] or 0, b[3] or 0
	if as~=bs then return as>bs end
	if am~=bm then return am>bm end
	return al>bl
end
local function remote_effective(id)
	local per = vars.maw_remote_values[id]
	if type(per)~="table" then return {0,0,0} end
	local eff = {0,0,0}
	for _,t in pairs(per) do eff = pick_max(eff, t) end
	return eff
end

------------------------------------------------------------
-- CONDITIONS (indices Weak/Poison/Disease/Curse)
------------------------------------------------------------
local __MAW_IDX = { Weak=nil, Poison=nil, Disease=nil, Curse=nil }
local function __find_cond_idx(patterns)
	if not (Game and Game.ConditionTxt) then return nil end
	local hi = Game.ConditionTxt.High or 32
	for i=0,hi do
		local t = Game.ConditionTxt[i]
		if t and type(t.Name)=="string" then
			local name = t.Name:lower()
			for _,p in ipairs(patterns) do if name:find(p) then return i end end
		end
	end
	return nil
end
local function __refresh_condition_indices()
	if __MAW_IDX.Weak == nil then
		if const and const.Condition and type(const.Condition.Weak)=="number" then
			__MAW_IDX.Weak = const.Condition.Weak
		else
			__MAW_IDX.Weak = __find_cond_idx({"weak","faib","schwach","débil","debil"})
		end
	end
	if __MAW_IDX.Poison == nil then __MAW_IDX.Poison = __find_cond_idx({"poison","empoison"}) end
	if __MAW_IDX.Disease == nil then __MAW_IDX.Disease = __find_cond_idx({"disea","malad"}) end
	if __MAW_IDX.Curse == nil then __MAW_IDX.Curse = __find_cond_idx({"curse","maudit"}) end
end
local function __idx(name) __refresh_condition_indices(); return __MAW_IDX[name] end

------------------------------------------------------------
-- WEAK FIX
------------------------------------------------------------
local function MAW_ClearWeakAll()
	__refresh_condition_indices()
	if not Party or type(Party.High) ~= "number" then return end
	local iWeak = __idx("Weak")
	for i = 0, Party.High do
		local p = Party[i]
		if p then
			if p.Weak then p.Weak = 0 end
			if iWeak and p.Conditions then p.Conditions[iWeak] = 0 end
		end
	end
end

function MAW_StartWeakProtect(secs)
	ensure_state()
	local dur = math.max(tonumber(secs) or 18, 0)
	vars._maw_weak_protect_until = NOW() + dur
end

local function __guard_active()
	local now = NOW()
	return now < (vars._maw_sync_guard_until or 0) or now < (vars._maw_weak_protect_until or 0)
end

local function __purge_bad_conditions_during_guard()
	if not __guard_active() then return end
	__refresh_condition_indices()
	if not Party or type(Party.High)~="number" then return end
	local iW,iP,iD,iC = __idx("Weak"), __idx("Poison"), __idx("Disease"), __idx("Curse")
	for i=0,Party.High do
		local p = Party[i]
		if p and p.Conditions then
			if iW then p.Conditions[iW] = 0 end
			if iP then p.Conditions[iP] = 0 end
			if iD then p.Conditions[iD] = 0 end
			if iC then p.Conditions[iC] = 0 end
			if p.Weak then p.Weak = 0 end
		end
	end
	if Party and Party.Food ~= nil and Party.Food < 3 then Party.Food = 3 end
end

function events.CalcDamageToPlayer(t)
	if not t or not t.Player then return end
	if not inMulti() then return end
	local now = NOW()

	if vars and vars._maw_weak_protect_until and now < vars._maw_weak_protect_until then
		if t.Player.Weak and t.Player.Weak ~= 0 then t.Player.Weak = 0 end
		local iw = __idx("Weak")
		if iw and t.Player.Conditions then t.Player.Conditions[iw] = 0 end
	end

	if not __guard_active() then return end
	__purge_bad_conditions_during_guard()
end

------------------------------------------------------------
-- SOLO: purge remote-only
------------------------------------------------------------
local function purge_remote_buffs_keep_local()
	ensure_state()
	local changed=false
	for id, owners in pairs(vars.maw_remote_owners) do
		if owners and next(owners) ~= nil then
			if type(vars.mawbuff[id])=="table" then vars.mawbuff[id] = nil; changed = true end
			vars.mawbuff_remote[id]		= nil
			vars.maw_remote_values[id] = nil
			vars.maw_remote_owners[id] = nil
		end
	end
	for id,_ in pairs(vars._maw_last_sent or {}) do
		if vars.mawbuff[id] == nil then vars._maw_last_sent[id] = nil end
	end
	if changed and type(mawBuffApply)=="function" then mawBuffApply() end
end

------------------------------------------------------------
-- RÉCEPTION BUFFS (ON/OFF)
------------------------------------------------------------
function events.MAWMapvarArrived(t)
	if not t or type(t) ~= "table" then return end
	if t.DataType == "mapvar" then
		mapvars = mapvars or {}
		mapvars[t[1]] = t[2]
		return
	end
	if (t.DataType ~= "mawBuffs") and (t.DataType ~= "mawBuffsOff") then return end
	if not isReworkOn() then return end
	ensure_state()

	if not (t.X and t.Y and t.Z) then return end
	local dx,dy,dz = (Party.X or 0)-t.X, (Party.Y or 0)-t.Y, (Party.Z or 0)-t.Z
	local dist = (dx*dx + dy*dy + dz*dz)^0.5
	if dist > (vars.MAWSETTINGS.buffRadius or BASE_RADIUS) then return end

	local BLOCK	= vars.MAWSETTINGS.blockSpells or {}
	local sender = tostring(t.sender or "?")
	local dtype	= t.DataType
	local changed=false

	if dtype == "mawBuffs" then
		for id, payload in pairs(t) do
			if type(id)=="number" and type(payload)=="table" and not BLOCK[id] then
				local owners = vars.maw_remote_owners[id] or {}
				owners[sender] = true
				vars.maw_remote_owners[id] = owners

				local perSender = vars.maw_remote_values[id] or {}
				perSender[sender] = { tonumber(payload[1]) or 0, tonumber(payload[2]) or 0, tonumber(payload[3]) or 0 }
				vars.maw_remote_values[id] = perSender

				local eff = remote_effective(id)
				local v = vars.mawbuff[id]
				if not (type(v)=="number" or v==true) then
					local old = vars.mawbuff[id]
					if (type(old)~="table") or (old[1]~=eff[1] or old[2]~=eff[2] or old[3]~=eff[3]) then
						vars.mawbuff[id] = { eff[1], eff[2], eff[3] }
						changed = true
					end
				end
				vars.mawbuff_remote[id] = true
			end
		end
	else
		for id,_ in pairs(t) do
			if type(id)=="number" then
				local owners = vars.maw_remote_owners[id]
				if owners then owners[sender] = nil end
				local perSender = vars.maw_remote_values[id]
				if perSender then perSender[sender] = nil end

				local hasOther = owners and (next(owners) ~= nil)
				if hasOther then
					local eff = remote_effective(id)
					local v = vars.mawbuff[id]
					if not (type(v)=="number" or v==true) then
						if (type(v)~="table") or (v[1]~=eff[1] or v[2]~=eff[2] or v[3]~=eff[3]) then
							vars.mawbuff[id] = { eff[1], eff[2], eff[3] }
							changed = true
						end
					end
					vars.mawbuff_remote[id] = true
				else
					if type(vars.mawbuff[id])=="table" then
						vars.mawbuff[id] = nil
						changed = true
					end
					vars.mawbuff_remote[id]	 = nil
					vars.maw_remote_values[id]= nil
					vars.maw_remote_owners[id]= nil
				end
			end
		end
	end

	if changed and type(mawBuffApply)=="function" then mawBuffApply() end
end

-- WEAK — canal dédié
function events.mawWeakEvt(t)
	if not t or t.DataType ~= "mawWeak" then return end
	if t.action == "clear" then
		MAW_ClearWeakAll()
	elseif t.action == "prime" then
		vars._maw_clear_weak_ticks = math.max(vars._maw_clear_weak_ticks or 0, tonumber(t.ticks) or 15)
		MAW_ClearWeakAll()
	elseif t.action == "protect" then
		MAW_StartWeakProtect(tonumber(t.seconds) or 30)
	end
end

-- TimeSync guard réseau
function events.mawTimeSync(t)
	ensure_state()
	vars._maw_sync_guard_until = math.max(vars._maw_sync_guard_until or 0, NOW() + (tonumber(t.guard) or 8))
	vars._maw_resend_boost_until = NOW() + 6*SEC
	if Party and Party.Food ~= nil and Party.Food < 3 then Party.Food = 3 end
end

function events.mawHostDown(t) ensure_state(); vars._maw_resend_boost_until = NOW() + 6*SEC end
function events.mawClientDown(t) ensure_state(); vars._maw_resend_boost_until = NOW() + 6*SEC end

------------------------------------------------------------
-- ENVOI (ON/OFF) — cadence Tick
------------------------------------------------------------
local function sendBuffs()
	if not inMulti() or not isReworkOn() then return end
	ensure_state()
	if not Party then return end

	local payload_on	= { DataType="mawBuffs",		X=Party.X, Y=Party.Y, Z=Party.Z, sender=senderId() }
	local payload_off = { DataType="mawBuffsOff", X=Party.X, Y=Party.Y, Z=Party.Z, sender=senderId() }

	local BLOCK = vars.MAWSETTINGS.blockSpells or {}
	local current = {}
	local hasOn, hasOff = false, false

	-- cas local explicite
	for id, v in pairs(vars.mawbuff) do
		if type(id)=="number" and not BLOCK[id] then
			local owners = vars.maw_remote_owners[id]
			local isRemote = owners and next(owners)~=nil
			local s,m,l = 0,0,0
			local localActive=false

			if (type(v)=="number" and v~=0) or v==true then
				localActive = true
				if type(getBuffSkill)=="function" then s,m,l = getBuffSkill(id) end
			elseif type(v)=="table" and not isRemote then
				localActive = true
				s = tonumber(v[1]) or 0; m = tonumber(v[2]) or 0; l = tonumber(v[3]) or 0
				if (s+m+l)==0 and type(getBuffSkill)=="function" then s,m,l = getBuffSkill(id) end
			end

			if localActive and (s+m+l)>0 then
				payload_on[id] = { s,m,l }
				current[id] = true
				hasOn = true
			end
		end
	end

	-- fallback: scanner les sorts actifs
	if type(getBuffSkill)=="function" then
		local maxId = maxSpellId()
		for id=1,maxId do
			if not BLOCK[id] and not current[id] then
				local s,m,l = getBuffSkill(id)
				local gs = { tonumber(s) or 0, tonumber(m) or 0, tonumber(l) or 0 }
				if (gs[1]+gs[2]+gs[3]) > 0 then
					local owners = vars.maw_remote_owners[id]
					local eff = remote_effective(id)
					if (not owners or next(owners)==nil) or lex_gt(gs, eff) then
						payload_on[id] = { gs[1], gs[2], gs[3] }
						current[id] = true
						hasOn = true
						if vars.mawbuff[id] == nil then vars.mawbuff[id] = 1 end
					end
				end
			end
		end
	end

	-- OFF = ce qu’on avait envoyé au tick-1 mais plus actif
	for id,_ in pairs(vars._maw_last_sent or {}) do
		if not current[id] and not BLOCK[id] then payload_off[id] = 1; hasOff = true end
	end

	if hasOn	then Multiplayer.broadcast_mapdata(payload_on,	"MAWMapvarArrived") end
	if hasOff then Multiplayer.broadcast_mapdata(payload_off, "MAWMapvarArrived") end
	vars._maw_last_sent = current
end

------------------------------------------------------------
-- BLOCS AUX
------------------------------------------------------------
local function block_forbidden_spells_in_multi()
	if not inMulti() or not isReworkOn() then return end
	local BLOCK = vars.MAWSETTINGS.blockSpells or {}
	if type(getBuffSkill)~="function" then return end
	for id,blocked in pairs(BLOCK) do
		if blocked then
			local s,m,l = getBuffSkill(id)
			if sum3(s,m,l) > 0 then
				if vars.mawbuff then vars.mawbuff[id] = nil end
				vars.mawbuff_remote[id]	 = nil
				vars.maw_remote_values[id]= nil
				vars.maw_remote_owners[id]= nil
			end
		end
	end
end

------------------------------------------------------------
-- TICK + RESYNC DETECTION
------------------------------------------------------------
local function __broadcast_timesync_guard(sec)
	if inMulti() and Multiplayer.allow_remote_event then
		Multiplayer.allow_remote_event("mawTimeSync")
		Multiplayer.broadcast_mapdata({ DataType="mawTimeSync", guard=sec or 8, sender=senderId() }, "mawTimeSync")
	end
end

function events.Tick()
	if not inMulti() then return end
	ensure_state()
	local now = NOW()

	-- Détection resync/rewind/bond
	local lastClock = vars._maw_clock_last or now
	local delta = now - lastClock
	if delta < -0.5*SEC or delta > 12*const.Hour then
		vars._maw_next_send_time = now + SEC
		vars._maw_last_sent = {}
		vars._maw_sync_guard_until = now + 10
		vars._maw_resend_boost_until = now + 6*SEC
		__broadcast_timesync_guard(10)
	end
	vars._maw_clock_last = now

	-- Protect WEAK
	if vars._maw_weak_protect_until > 0 and now < vars._maw_weak_protect_until then
		MAW_ClearWeakAll()
	end

	-- Grand skip (jours)
	vars._maw_last_time = vars._maw_last_time or now
	if (now - vars._maw_last_time) > (DAY*6) then
		vars._maw_last_sent = {}
		vars._maw_sync_guard_until = now + 10
		vars._maw_clear_weak_ticks = math.max(vars._maw_clear_weak_ticks or 0, 14)
		__broadcast_timesync_guard(10)
	end
	vars._maw_last_time = now

	-- Rafales clear WEAK + purge DoT + anti “no-sleep”
	if vars._maw_clear_weak_ticks and vars._maw_clear_weak_ticks > 0 then
		MAW_ClearWeakAll()
		vars._maw_clear_weak_ticks = vars._maw_clear_weak_ticks - 1
	end
	__purge_bad_conditions_during_guard()

	-- Blocage sorts interdits
	block_forbidden_spells_in_multi()

	-- Cadence d’envoi sans Timer
	if not isReworkOn() then return end
	local period = SEND_PERIOD
	if now < (vars._maw_resend_boost_until or 0) then period = SEC end
	if (vars._maw_next_send_time or 0) <= now then
		sendBuffs()
		vars._maw_next_send_time = now + period
	end
end

------------------------------------------------------------
-- LOAD / INIT
------------------------------------------------------------
function events.LoadMap()
	ensure_state()
	vars._maw_last_sent = {}
	vars._maw_next_send_time = NOW() + 0.5*SEC
	if not inMulti() then purge_remote_buffs_keep_local() end
	vars._maw_clear_weak_ticks = math.max(vars._maw_clear_weak_ticks or 0, 12)
	__refresh_condition_indices()
end

function events.MultiplayerInitialized()
	ensure_state()
	if Multiplayer and Multiplayer.VERSION then Multiplayer.VERSION = "MAW " .. Multiplayer.VERSION end
	if Multiplayer and Multiplayer.allow_remote_event then
		Multiplayer.allow_remote_event("MAWMapvarArrived")
		Multiplayer.allow_remote_event("mawWeakEvt")
		Multiplayer.allow_remote_event("mawTimeSync")
		Multiplayer.allow_remote_event("mawHostDown")
		Multiplayer.allow_remote_event("mawClientDown")
	end
	vars._maw_next_send_time = NOW() + 0.5*SEC
	vars._maw_clear_weak_ticks = math.max(vars._maw_clear_weak_ticks or 0, 12)
	__refresh_condition_indices()
end

------------------------------------------------------------
-- SÉQUENCES DE MORT → guards + pulses
------------------------------------------------------------
local function __notify(which)
	if inMulti() and Multiplayer.allow_remote_event then
		Multiplayer.allow_remote_event(which)
		Multiplayer.broadcast_mapdata({ DataType=which, sender=senderId() }, which)
	end
end

local function __after_death_resend_pulse()
	ensure_state()
	vars._maw_last_sent = {}
	vars._maw_next_send_time = 0
	vars._maw_resend_boost_until = NOW() + 6*SEC
end

function events.MultiplayerDeathScreen()
	ensure_state()
	if isHost() then __notify("mawHostDown") else __notify("mawClientDown") end
	vars._maw_clear_weak_ticks = math.max(vars._maw_clear_weak_ticks or 0, 20)
	MAW_StartWeakProtect(30)
	__after_death_resend_pulse()
end
