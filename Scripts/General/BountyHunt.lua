
BountyHuntFunctions = {}

local BountyText = ""

local function RewardByMon(MonId)
	return round(basetable[MonId].Level + getPartyLevel(4)) * 100 
end

local function HuntText(MonId, MonName, MapFileName)
	local text = Game.NPCText[133]:replace("%lu", tostring(RewardByMon(MonId)))
	local MapName
	for _, MapStats in pairs(Game.MapStats) do
		if type(MapStats) == "table" and MapStats.FileName == MapFileName then
			MapName = MapStats.Name
		end
	end
	local function Yellow(x)
		return StrColor(255, 255, 150, x)
	end
	local contents = Yellow(MonName or "monster")
	if MapName then
		contents = contents .. " in " .. Yellow(MapName)
	end
	return text:format(contents)
end
BountyHuntFunctions.HuntText = HuntText

local function RewardText(MonId, MonName)
	local Reward = RewardByMon(MonId)
	local text = Game.NPCText[134]:replace("%lu", Reward)
	return text:format(MonName, Reward)
end
BountyHuntFunctions.RewardText = RewardText

local function ClaimedText()
	return Game.NPCText[135]
end
BountyHuntFunctions.ClaimedText = ClaimedText

local function FindNextNoteIndex()
	for i=0,Map.Notes.High do
		local Note = Map.Notes[i]
		if not Note.Active then
			return i
		end
	end
end

local function NewEntry(Month, MonId, Done, Claimed, NoteIndex)
	return {
		Month = Month or 0,
		MonId = MonId or 0,
		Done = Done or false,
		Claimed = Claimed or false,
		NoteIndex = NoteIndex or FindNextNoteIndex()
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
	
	if vars.insanityMode then
		for key, value in pairs(vars.BountyHunt) do
			if key ~= Map.Name and value.Month==Game.Month and value.Done==false then
				return HuntText(value.MonId, value.MonName, key)
			end
		end
	end

	if not BountyExpired(Entry) then
		-- If bounty hunt quest have already been chosen for this month.
		local MonId = Entry.MonId
		if not MonId then
			vars.BountyHunt[Map.Name] = nil
			BountyHuntFunctions.SetCurrentHunt()
			return
		end

		local MonName = Entry.MonName or Game.PlaceMonTxt[299] -- compatibility with old saves
		if Entry.Done then
			if Entry.Claimed then
				BountyText = ClaimedText()
			else
				local Reward = RewardByMon(MonId)
				BountyText = RewardText(MonId, MonName)

				for i,v in Party do
					v.Awards[44] = true
				end

				AddBountyHuntReward(Reward)
				Entry.Claimed = true

				events.Call("BountyHuntRewardClaimed", Map.Name, Reward)
			end
		else
			BountyText = HuntText(MonId, MonName)
		end

	elseif not mapvars.completed then
		-- If map hasn't yet been cleared, don't give out a new bounty
		BountyText = "You need to clear the area COMPLETELY first."
	else
		-- Choose monster for new hunt.
		local Mons = BountyHuntFunctions.MonstersForBountyHunt()

		-- Create entry in list of bounty hunts.
		local t = {MapName = Map.Name, Handled = false}
		local id=random(1, #monTbl)
		local monsterId=monTbl[id].Index
		t.Entry = NewEntry(Game.Month, monsterId, false, false, Entry and Entry.NoteIndex)
		Entry = t.Entry
		events.Call("BountyHuntGeneration", t)

		vars.BountyHunt[Map.Name] = Entry
		
		-- Summon monster
		local MonId = Entry.MonId
		local X, Y, Z = BountyHuntFunctions.NewBHSpawnPoint()
		
		mapvars.mawBounty=math.max((getPartyLevel(4)-BLevel[MonId]/1.5),0)
		recalculateMonsterTable()
		local Hunt = pseudoSpawnpoint{monster = MonId,  x = X, y = Y, z = Z, count = 1, powerChances = {0, 0, 100}, radius = 256, group = 2,transform = function(mon) mon.Hostile = true mon.ShowAsHostile = true mon.Velocity=350 end}[1]
		generateBoss(Hunt:GetIndex())
		Entry.MonName = Game.PlaceMonTxt[Hunt.NameId]

		local monsterSkill = string.match(Entry.MonName, "([^%s]+)")
		if monsterSkill=="Omnipotent" then
			pseudoSpawnpoint{monster = MonId,  x = X, y = Y, z = Z, count = math.random(100,200), powerChances = {55, 30, 15}, radius = 2048, group = 2,transform = function(mon) mon.Hostile = true mon.ShowAsHostile=true mon.Velocity=350 end}
		end
		local Note=Map.Notes[Entry.NoteIndex]
		if Note then
			Note.Active=true
			Note.Id=9999
			Note.X=X
			Note.Y=Y
			Note.Text="Bounty"
		end

		pseudoSpawnpoint{monster = MonId,  x = X, y = Y, z = Z, count = math.random(5,15), powerChances = {55, 30, 15}, radius = 1024, group = 2,transform = function(mon) mon.Hostile = true mon.ShowAsHostile = true mon.Velocity=350 end}
		recalculateMawMonster()
		-- Make monster berserk to encourage it to fight everything around (peasants, guards, player)
		--local MonBuff = mon.SpellBuffs[const.MonsterBuff.Berserk]
		--MonBuff.ExpireTime = Game.Time + const.Month
		--MonBuff.Power = 4
		--MonBuff.Skill = 4
		--MonBuff.Caster = 49

		events.Call("NewBountyHuntCreated", Map.Name, Entry, mon)
		BountyText = HuntText(Entry.MonId, Entry.MonName)
	end

	return BountyText
end
BountyHuntFunctions.SetCurrentHunt = SetCurrentHunt

function events.MonsterKilled(Monster, MonsterIndex, _, killer)
	if not (killer and killer.Player) then
		return
	end
	local Entry = vars.BountyHunt and vars.BountyHunt[Map.Name]
	if not Entry then
		return
	end
	local MonName = Entry.MonName or Game.PlaceMonTxt[299] -- compatibility with old saves
	if MonName ~= Game.PlaceMonTxt[Monster.NameId] then
		return
	end
	local Note = Map.Notes[Entry.NoteIndex]
	if Note then
		Note.Active = false
	end
	Entry.NoteIndex = nil
	if not Entry.Done and Game.Month == Entry.Month then
		Entry.Done = true
		events.Call("BountyHuntEliminated", Map.Name, Entry, Monster)
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
	BountyText = BountyHuntFunctions.SetCurrentHunt()
	mem.u4[0xffd410] = mem.topointer(BountyText)
end)

-- Make MM8 bounty hunt same as MM7 and MM6 now
mem.hook(0x4b080e, function(d)
	BountyText = BountyHuntFunctions.SetCurrentHunt()
	Message(BountyText)
end)
