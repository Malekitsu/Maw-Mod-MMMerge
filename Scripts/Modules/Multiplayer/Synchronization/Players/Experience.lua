local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item

local function PlayersOnMap()
	local count = 1
	for k,v in pairs(Multiplayer.connector.clients) do
		if v.map == Map.MapStatsIndex then
			count = count + 1
		end
	end
	return count
end

local function MulAddKillExp(Amount, monLvl, monId)
	local avg = math.ceil(Amount / math.min(PlayersInGame(),5))
	
	--maw code
	local partyLvl=getTotalLevel()
	
	
	if vars.insanityMode and monId>300 then 
		return
	end
	
	local partyCount=0
	for i=0, Party.High do
		if Party[i].Dead==0 and Party[i].Eradicated==0 then
			partyCount=partyCount+1
		end
	end
	partyCount=math.max(1,partyCount)
	local experience=avg/partyCount
	local bolsterExp=0
	for i=0, Party.High do
		local playerLevel=math.min(calcLevel(Party[i].Experience),partyLvl) --accounts for the cases which you want to level a low lvl character
		local multiplier1=((monLvl+10)/(playerLevel+5))^2
		local multiplier2=1+(monLvl^0.5)-(playerLevel^0.5)
		mult=math.min(math.max(multiplier1,multiplier2),3)
		if mult<1 then
			multiplier2=1+(playerLevel^0.5)-(monLvl^0.5)
			mult=math.min(math.min(multiplier1,1/multiplier2),1/3)
		end
		local experienceAwarded=experience*mult
		Party[i].Experience=math.min(Party[i].Experience+experienceAwarded, 2^32-3982296)
		
		--calculate again based for bolster
		playerLevel=partyLvl
		bolsterExp=bolsterExp+experience*mult
	end
	
	--no bolster from arena
	if Map.Name=="d42.blv" then
		return
	end
	
	addBolsterExp(bolsterExp)
	
	vars.lastPartyExperience={Party[0]:GetIndex(),Party[0].Experience}
	for i=0, Party.High do
		Party[i].Exp=math.min(Party[i].Exp, 2^32-3982296)
	end
	ShareBolster()
end
Multiplayer.AddKillExp = MulAddKillExp

local packets = {
	quest_exp = {
		bulb = function(amount, topic_title, npc_name)
			local t = {amount, topic_title, npc_name}
			return item_to_bin(t)
		end,
		handler = function(bin_string, metadata)
			-- Turned out, MM8 promotion quests grant extra exp to main character for every empty party slot.
			-- Not even sure if it is intended, because original Evt scripts do not use any specific checks for this procedure,
			-- script just goes on through every possible party member, using ForPlayer(0-4).
			-- ForPlayer(i), if i is empty party slot, redirects to ForPlayer(0).
			-- Leaving this as is for now, because this problem might be deeper, and probably requires some smart solution.
		
			local t = bin_to_item(toptr(bin_string))
			local msg = ("%s: %s grants you %s exp."):format(t[2], t[3], t[1])
			for _, pl in Party do
				pl.Experience = pl.Experience + t[1]
			end
			addBolsterExp(t[1])
			evt.All.Add{"Experience", 0}
			Game.ShowStatusText(msg, 6)
		end,
		check_delivery = true,
		compress = true
	},

	kill_monster_exp = {
		-- was: bulb = Multiplayer.utils.num_to_hexstr,
		bulb = function(amount, monLevel)
			return item_to_bin({amount, monLevel})
		end,
		handler = function(bin_string, metadata)
			-- was: local amount = i4[toptr(bin_string)]; MulAddKillExp(amount)
			local t = bin_to_item(toptr(bin_string))
			local amount, monLevel = t[1], t[2]
			MulAddKillExp(amount, monLevel, monId)
		end,
		check_delivery = true,
		same_map_only = false
	}
}
Multiplayer.utils.init_packets(packets)

-- Monster kill experience

local last_hit_by_player = {}

function events.CalcDamageToMonster(t)
	last_hit_by_player[t.MonsterIndex] = t.ByPlayer
end

function events.MonsterKilled(mon, monId, _, killer)
	if last_hit_by_player[monId] then
		Multiplayer.broadcast(packets.kill_monster_exp:prep(mon.Experience, mon.Level), cond_same_map)
		
		-- override experience gain by player-killer
		MulAddKillExp(mon.Experience, getMonsterLevel(mon), mon.NameId)
		mon.Experience = 0
	end
end

-- Topic experience
local last_exp = {}
local function dump_last_exp()
	for i, v in Party do
		last_exp[i] = v.Experience
	end
end

local last_topic = 0
local function check_diff(current_topic)
	if last_topic == current_topic then
		local total = 0
		local count = 0
		for k, v in pairs(last_exp) do
			if k >= 0 and k < Party.count then
				total = total + Party[k].Experience - v
				count = count + 1
			end
		end
		if count > 0 then
			local avg = math.floor(total / count)
			if avg > 0 then
				Multiplayer.broadcast(packets.quest_exp:prep(avg, Game.NPCTopic[current_topic], Game.NPC[GetCurrentNPC()].Name), nil)
			end
		end
	end
	table.clear(last_exp)
end

local exclude_topics = {} -- for now manually exclude topics, which exp gain should not be shared	
function events.LoadMapScripts(WasInGame)	
	if not WasInGame then
		exclude_topics[NPCFollowers.PeasantPromoteTopic] = true
	end
end

function events.ClickNPCTopic(i)
	last_topic = i
	if not exclude_topics[i] then
		dump_last_exp()
		events.Once("EvtGlobal", check_diff)
	end
end
