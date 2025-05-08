
BountyHuntFunctions = {}

local BountyText = ""

local function RewardByMon(MonId)
	return Game.MonstersTxt[MonId].Level * 100
end

local function HuntText(MonId)
	local text = Game.NPCText[133]:replace("%lu", tostring(RewardByMon(MonId)))
	return text:format(StrColor(255,255,150, Game.PlaceMonTxt[299]))
end
BountyHuntFunctions.HuntText = HuntText

local function RewardText(MonId)
	local Reward = RewardByMon(MonId)
	local text = Game.NPCText[134]:replace("%lu", Reward)
	return text:format(Game.PlaceMonTxt[299], Reward)
end
BountyHuntFunctions.RewardText = RewardText

local function ClaimedText()
	return Game.NPCText[135]
end
BountyHuntFunctions.ClaimedText = ClaimedText

local function NewEntry(Month, MonId, Done, Claimed)
	return {
		Month = Month or 0,
		MonId = MonId or 0,
		Done = Done or false,
		Claimed = Claimed or false
	}
end
BountyHuntFunctions.NewEntry = NewEntry

local function BountyExpired(Entry)
	return not (Entry and Game.Month == Entry.Month)
end
BountyHuntFunctions.BountyExpired = BountyExpired

local function AddBountyHuntReward(Gold, NoGold)
	evt.ForPlayer("Current")

	if not NoGold then
		evt.Add{"Gold", Gold}
	end
	evt.Add{"MontersHunted", Gold}
	evt.Subtract{"Reputation", math.ceil(Gold/2000)}
end
BountyHuntFunctions.AddBountyHuntReward = AddBountyHuntReward

local function MonstersForBountyHunt(MaxLevel)
	local list = {}
	local append = table.insert
	MaxLevel = MaxLevel or Party[0].LevelBase + 20

	for i, v in Game.MonstersTxt do
		if v.Level > MaxLevel or Game.IsMonsterOfKind(i, const.MonsterKind.NoArena) == 1 then
			-- skip
		else
			append(list, i)
		end
	end
	return list
end
BountyHuntFunctions.MonstersForBountyHunt = MonstersForBountyHunt

local function NewBHSpawnPoint()
	local random = math.random
	local function default_random()
		return random(-15000, 15000), random(-15000, 15000), 1000
	end

	local FacetIds, X, Y, Z
	local append = table.insert
	if Map.IsIndoor() and Map.Facets.count > 0 then
		local Facet, RoomsWFloors, RoomsWWalls = nil, {}, {}
		for i, Room in Map.Rooms do
			if Room.Floors.count > 0 then
				append(RoomsWFloors, Room)
			end
			if Room.Walls.count > 0 then
				append(RoomsWWalls, Room)
			end
		end

		if #RoomsWFloors > 0 then
			FacetIds = RoomsWFloors[random(1, #RoomsWFloors)].Floors
		elseif #RoomsWWalls > 0 then
			FacetIds = RoomsWWalls[random(1, #RoomsWFloors)].Walls
		else
			return default_random()
		end

		Facet = Map.Facets[FacetIds[random(FacetIds.count-1)]]
		return Facet.MinX + (Facet.MaxX - Facet.MinX)/2, Facet.MinY + (Facet.MaxY - Facet.MinY)/2, Facet.MaxZ

	elseif Map.IsOutdoor() then
		X, Y, Z = default_random()

		local Tile = Game.CurrentTileBin[Map.TileMap[(64 - Y / 0x200):floor()][(64 + X / 0x200):floor()]]
		local Cnt = 5
		while Cnt > 0 do
			if not Tile.Water then
				break
			end
			X, Y, Z = default_random()
			Tile = Game.CurrentTileBin[Map.TileMap[(64 - Y / 0x200):floor()][(64 + X / 0x200):floor()]]
			Cnt = Cnt - 1
		end
	else
		X, Y, Z = default_random()
	end
	return X, Y, Z
end
BountyHuntFunctions.NewBHSpawnPoint = NewBHSpawnPoint

local function SetCurrentHunt()
	vars.BountyHunt = vars.BountyHunt or {}

	local random = math.random
	local BountyText
	local Entry = vars.BountyHunt[Map.Name]

	if not BountyExpired(Entry) then
		-- If bounty hunt quest have already been chosen for this month.
		MonId = Entry.MonId
		if not MonId then
			vars.BountyHunt[Map.Name] = nil
			BountyHuntFunctions.SetCurrentHunt()
			return
		end

		if Entry.Done then
			if Entry.Claimed then
				BountyText = ClaimedText()
			else
				local Reward = RewardByMon(MonId)
				BountyText = RewardText(MonId)

				for i,v in Party do
					v.Awards[44] = true
				end

				AddBountyHuntReward(Reward)
				Entry.Claimed = true

				events.Call("BountyHuntRewardClaimed", Map.Name, Reward)
			end
		else
			BountyText = HuntText(MonId)
		end

	else
		-- Choose monster for new hunt.
		local Mons = BountyHuntFunctions.MonstersForBountyHunt()

		-- Create entry in list of bounty hunts.
		local t = {MapName = Map.Name, Handled = false}
		local monsterId=Mons[random(1, #Mons)]
		monsterId=monsterId-monsterId%3+3
		t.Entry = NewEntry(Game.Month, monsterId, false, false)
		events.Call("BountyHuntGeneration", t)

		vars.BountyHunt[Map.Name] = t.Entry
		
		--MAW FIX, not sure why it's always on Handled=true, as it prevents monster to spawn, it's probably to keep vanilla behaviour
		Handled=false
		if Handled then
			return t.Text or HuntText(t.Entry.MonId)
		end
		
		-- Summon monster
		local MonId = t.Entry.MonId
		local X, Y, Z = BountyHuntFunctions.NewBHSpawnPoint()
		
		mapvars.mawBounty=math.max((vars.MM6LVL+vars.MM7LVL+vars.MM8LVL-30),0)
		recalculateMonsterTable()
		mon=pseudoSpawnpoint{monster = MonId,  x = X, y = Y, z = Z, count = 1, powerChances = {0, 0, 100}, radius = 256, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 index=mon:GetIndex() end}
		generateBoss(index,79)
		
		local monsterSkill = string.match(Game.PlaceMonTxt[299], "([^%s]+)")
		if monsterSkill=="Omnipotent" then
			pseudoSpawnpoint{monster = MonId,  x = X, y = Y, z = Z, count = math.random(100,200), powerChances = {55, 30, 15}, radius = 2048, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 index=mon:GetIndex() end}
		end
		
		local setNote=true
		local i=0
		while setNote or i>Map.Notes.High do
			local note=Map.Notes[i]
			if not note.Active then
				note.Active=true
				note.Id=9999
				note.X=X
				note.Y=Y
				note.Text="Bounty"
				setNote=false
			end
			i=i+1
		end
		pseudoSpawnpoint{monster = MonId,  x = X, y = Y, z = Z, count = math.random(15,45), powerChances = {55, 30, 15}, radius = 1024, group = 2,transform = function(mon) mon.ShowOnMap = true mon.Hostile = true mon.Velocity=350 index=mon:GetIndex() end}
		
		-- Make monster berserk to encourage it to fight everything around (peasants, guards, player)
		--local MonBuff = mon.SpellBuffs[const.MonsterBuff.Berserk]
		--MonBuff.ExpireTime = Game.Time + const.Month
		--MonBuff.Power = 4
		--MonBuff.Skill = 4
		--MonBuff.Caster = 49

		events.Call("NewBountyHuntCreated", Map.Name, vars.BountyHunt[Map.Name], mon)
		BountyText = HuntText(MonId)
	end

	return BountyText
end
BountyHuntFunctions.SetCurrentHunt = SetCurrentHunt

function events.MonsterKilled(Monster, MonsterIndex, _, killer)
	if vars.BountyHunt and killer and killer.Player then
		for MapName, Entry in pairs(vars.BountyHunt) do
			if not Entry.Done and Game.Month == Entry.Month and Entry.MonId == Monster.Id and Monster.NameId==299 then
				Entry.Done = true
				events.Call("BountyHuntEliminated", MapName, Entry, Monster)
			end
		end
	end
end

-- Repair town hall topic
NewCode = mem.asmproc([[
nop
nop
nop
nop
nop
jmp absolute 0x4bb3f0]])
mem.asmpatch(0x4bae73, "jmp absolute " .. NewCode)

mem.hook(NewCode, function(d)
	if not mapvars.completed then
		Message("You need to clear the area COMPLETELY first")
		return
	end	
	BountyText = BountyHuntFunctions.SetCurrentHunt()
	mem.u4[0xffd410] = mem.topointer(BountyText)
end)

-- Make MM8 bounty hunt same as MM7 and MM6 now
mem.hook(0x4b080e, function(d)
	if not mapvars.completed then
		Message("You need to clear the area COMPLETELY first")
		return
	end	
	BountyText = BountyHuntFunctions.SetCurrentHunt()
	Message(BountyText)
end)
