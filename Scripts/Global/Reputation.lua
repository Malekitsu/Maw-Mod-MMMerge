
vars.GlobalReputation	= vars.GlobalReputation or {}
vars.ContinentFame		= vars.ContinentFame or {} -- contains exp base for fame counting.

local ShopsClosed = false
local ContSet

local function ExitBTBTopics(npc)
	NPCFollowers.ClearEvents(Game.NPC[npc])

	NPCFollowers.SetHireTopic(npc)
	NPCFollowers.SetNewsTopics(npc)
end

-- Beg topic.
Game.GlobalEvtLines:RemoveEvent(NPCFollowers.BegTopic)
evt.Global[NPCFollowers.BegTopic] = function()
	if Game.CurrentPlayer < 0 then
		return
	end

	local MerchantSkill = SplitSkill(Party[Game.CurrentPlayer]:GetSkill(const.Skills.Merchant))
	local npc = GetCurrentNPC()
	local PersSet = Game.NPCPersonalities[Game.NPCProf[Game.NPC[npc].Profession].Personality]
	local NPCExtra = mapvars.MapNPCNews[npc]

	if NPCExtra.BegSuccess == Game.DayOfMonth then
		Message(NPCFollowers.PrepareBTBString(npc, PersSet.BegRet))
		Party[Game.CurrentPlayer]:ShowFaceAnimation(const.FaceAnimation.BegFail)
	elseif PersSet.AcceptBeg then
		NPCExtra.BegSuccess = Game.DayOfMonth
		Message(NPCFollowers.PrepareBTBString(npc, PersSet.BegSuccess))
		ExitBTBTopics(npc)
		Party[Game.CurrentPlayer]:ShowFaceAnimation(const.FaceAnimation.Beg)
	else
		Message(NPCFollowers.PrepareBTBString(npc, PersSet.BegFail))
		Party[Game.CurrentPlayer]:ShowFaceAnimation(const.FaceAnimation.BegFail)
	end
end

-- Threat topic
Game.GlobalEvtLines:RemoveEvent(NPCFollowers.ThreatTopic)
evt.Global[NPCFollowers.ThreatTopic] = function()
	if Game.CurrentPlayer < 0 then
		return
	end

	local npc = GetCurrentNPC()
	local PersSet = Game.NPCPersonalities[Game.NPCProf[Game.NPC[npc].Profession].Personality]

	if PersSet.AcceptThreat then
		mapvars.MapNPCNews[npc].ThreatSuccess = Game.DayOfMonth
		Message(NPCFollowers.PrepareBTBString(npc, PersSet.ThreatSuccess))
		ExitBTBTopics(npc)
	else
		Message(NPCFollowers.PrepareBTBString(npc, PersSet.ThreatFail))
		Party[Game.CurrentPlayer]:ShowFaceAnimation(const.FaceAnimation.ThreatFail)
	end
end

-- Bribe topic.
Game.GlobalEvtLines:RemoveEvent(NPCFollowers.BribeTopic)
evt.Global[NPCFollowers.BribeTopic] = function()
	local npc = GetCurrentNPC()
	local ProfSet = Game.NPCProf[Game.NPC[npc].Profession]
	local Cost = ProfSet.Cost or 50
	local PersSet = Game.NPCPersonalities[ProfSet.Personality]

	evt.ForPlayer(0)

	if PersSet.AcceptBribe then
		if Party.Gold > Cost then
			evt.Subtract("Gold", Cost)
			mapvars.MapNPCNews[npc].BribeSuccess = Game.DayOfMonth
			Message(NPCFollowers.PrepareBTBString(npc, PersSet.BribeSuccess))
			ExitBTBTopics(npc)
		else
			Message(Game.GlobalTxt[155])
			Party[Game.CurrentPlayer]:ShowFaceAnimation(const.FaceAnimation.BribeFail)
		end
	else
		Message(NPCFollowers.PrepareBTBString(npc, PersSet.BribeFail))
		Party[Game.CurrentPlayer]:ShowFaceAnimation(const.FaceAnimation.BribeFail)
	end
end


local StdBribeTopic = Game.NPCTopic[1765]
function events.EnterNPC(i)
	local Cost = Game.NPCProf[Game.NPC[i].Profession].Cost or 50
	Game.NPCTopic[NPCFollowers.BribeTopic] = StdBribeTopic .. " " .. tostring(Cost) .. " " .. Game.GlobalTxt[97]
end

----

local function ChangeShopsState(State)
	State = State or 0

	local T = Game.HousesByMaps[Map.MapStatsIndex]
	local BanTime = State == 0 and 0 or Game.Time + const.Day
	if T then
		for k,v in pairs(T) do
			if k >= 1 and k <= 4 then
				for _,i in pairs(v) do
					Game.ShopTheftExpireTime[GetHouseWritePos(i)] = BanTime
				end
			end
		end
	end
end

local function ChangeGuardsState(State)
	for i,v in Map.Monsters do
		if v.Group == 38 or v.Group == 55 then -- default groups for map guards.
			v.Hostile = State
		end
	end
end

local function GetPartyReputation()
	return mem.call(0x47603F) --mem.i4[0x6cf0a4]
end
NPCFollowers.GetPartyReputation = GetPartyReputation

local function GetFameBase()
	local CurCont = TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	if CurCont == 4 then
		return Party[0].Experience
	else
		local Total = 0

		for k,v in pairs(vars.ContinentFame) do
			Total = Total + v
		end

		local res = Party[0].Experience - Total + (vars.ContinentFame[CurCont] or 0)
		vars.ContinentFame[CurCont] = res

		return res
	end
end

local function GetPartyFame()
	return Party.GetFame()
end
NPCFollowers.GetPartyFame = GetPartyFame

local function StoreReputation()
	local CurCont = TownPortalControls.MapOfContinent(Map.MapStatsIndex)

	vars.GlobalReputation[CurCont] = GetPartyReputation()
end


local BanText = Game.NPCText[1683]

local function ExitShopAfter(t)
	if t.Key == 27 then -- escape
		ExitCurrentScreen()
		events.Remove("KeysFilter", ExitShopAfter)
	end
end

local function ShowBanText()
	events.KeysFilter = ExitShopAfter
	Game.EscMessage(BanText)
end

----

function events.GetFameBase(t)
	t.Base = GetFameBase() or 0
end

function events.MonsterKilled(mon, monIndex, defaultHandler, player, playerIndex)

	if not ContSet.UseRep then
		return
	end

	-- affect reputation only if monster killed by party, and monster was not reanimated.
	if player and mon.Ally ~= 9999 then

		local CurCont = TownPortalControls.MapOfContinent(Map.MapStatsIndex)
		local MonExtra = Game.Bolster.MonstersSource[mon.Id]
		local ContRep = vars.GlobalReputation[CurCont]

		evt.ForPlayer(0)

		-- Subtract Reputation if peasant killed (peasants can not be bounty hunt targets or arena participants).
		if MonExtra.Creed == const.Bolster.Creed.Peasant and mon.NPC_ID > 0 then
			if not evt.Cmp{"Reputation", 100} then -- Don't drop reputation below 100.
				evt.Add{"Reputation", 1} -- Add and Sub kind of reverted for reputation.

				if ContRep < 20 then
					vars.GlobalReputation[CurCont] = ContRep + 1
					evt.Add{"Reputation", 1} -- Let party get murderer reputation across continent
				end
			end

			local PartyRep = GetPartyReputation()

			if not ShopsClosed and ContSet.RepShops and PartyRep >= 25 then
				ChangeShopsState(1)
				ShopsClosed = true
			end

			if ContSet.RepGuards and PartyRep >= 20 then
				ChangeGuardsState(true)
			end

			return
		end

		-- Increase Reputation if monster is bounty hunt target.
		local BH = vars.BountyHunt and vars.BountyHunt[Map.Name]
		if BH and not BH.Done and BH.MonId == mon.Id then
			local Reward = math.floor(mon.Level/20)

			if evt.Cmp{"Reputation", -20} then
				evt.Subtract{"Reputation", Reward}
			end

			-- Let party adjust global reputation by BH quests.
			if ContRep > -5 then
				vars.GlobalReputation[CurCont] = ContRep - 1
			end

			return
		end

	end

end

function events.ClickShopTopic(t)

	if not ContSet.UseRep then
		return
	end

	local Rep = GetPartyReputation()
	if Rep > 0 then
		local cHouse = Game.Houses[GetCurrentHouse()]

		if t.Topic == const.ShopTopics.Donate and cHouse.C == 0 then

			local Amount = Game.Houses[GetCurrentHouse()].Val
			local cGold = Party.Gold
			if Party.Gold >= Amount then
				if Rep > 0 then
					Party.Gold = cGold - math.min((math.floor(Amount*Rep/5)), cGold) + Amount
				end

				if ContSet.RepGuards and Rep <= 20 then
					ChangeGuardsState(false)
				end
			end

		elseif table.find({const.HouseType.Boats, const.HouseType.Stables, const.HouseType.Temple}, cHouse.Type) then
			return

		elseif ContSet.RepShops and Rep > 25 then
			t.Handled = true
			ShowBanText()

		end
	end
end

function events.BeforeSaveGame()
	StoreReputation()
end

function events.LeaveMap()
	StoreReputation()
end

function events.AfterLoadMap()

	local CurCont = TownPortalControls.MapOfContinent(Map.MapStatsIndex) or TownPortalControls.GetCurrentSwitch()

	ContSet = Game.ContinentSettings[CurCont]

	if not ContSet.UseRep then
		return
	end

	vars.GlobalReputation[CurCont] = vars.GlobalReputation[CurCont] or 0

	local State

	-- Separate reputation by continents
	local CurRep = vars.GlobalReputation[CurCont]

	evt.Set{"Reputation", CurRep}

	-- Close shops for party with terrible reputation
	if ContSet.RepShops then
		ShopsClosed = CurRep >= 25
		State = ShopsClosed and 1 or 0
		ChangeShopsState(State)
	end

	-- Make guards aggressive
	if ContSet.RepGuards then
		State = CurRep >= 25
		ChangeGuardsState(State)
	end

end


