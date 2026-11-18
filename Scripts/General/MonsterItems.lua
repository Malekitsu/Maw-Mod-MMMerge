local random, floor, ceil = math.random, math.floor, math.ceil
local MonsterItems = {
[20] = 1004,
[21] = 1004,
[24] = 1006,
[64] = 1006,
[74] = 1016,
[75] = 1006,
[81] = 207,
[92] = 202,
[95] = 1009,
[104] = 1019,
[150] = 1004,
[167] = 1016,
[168] = 1016,
[172] = 1006,
[186] = 1009
}

function events.MonsterKilled(mon)
	if mon.Ally == 9999 then -- no drop from reanimated monsters
		return
	end

	local monKind = ceil(mon.Id/3)
	local Mul = mon.Id - monKind*3 + 3
	local ItemId = MonsterItems[monKind]
	if ItemId and random(100) + Mul*5 > 80 then
		local t = {MonsterIndex = mon:GetIndex(), Monster = mon, ItemId = ItemId, Handled = false}
		events.Call("MonsterDropItem", t)
		if not t.Handled then
			evt.SummonObject(ItemId, mon.X, mon.Y, mon.Z + 100, 100)
		end
	end
end

-- Make monsters in indoor maps active once party sees them.
local function ActiveMonTimer()
	local MonList = Game.GetMonstersInSight()
	local mon
	local lim = Map.Monsters.count
	for k,v in pairs(MonList) do
		if v < lim then
			mon = Map.Monsters[v]
			mon.Active = true
			mon.ShowOnMap = true
		end
	end
end

function events.AfterLoadMap()
	if Map.IsIndoor() then
		Timer(ActiveMonTimer, const.Minute/4, false)
	end
end

-- Clean out-of-bounds monsters
function events.LoadMapScripts()
	local count = 0
	local stuck = {}
	local function clean()
		if Map.Monsters.count == 0 then
			return
		end

		if count >= Map.Monsters.count then
			count = 0
		end

		local stuck_time
		local mon = Map.Monsters[count]
		if Map.RoomFromPoint(XYZ(mon)) == 0 then
			local stuck_time = stuck[count] or 0
			if stuck_time > 6 then
				mon.AIState = const.AIState.Removed
				stuck[count] = 0
			else
				stuck[count] = stuck_time + 1
			end
		else
			stuck[count] = 0
		end
		count = count + 1
	end

	if Map:IsIndoor() then
		Timer(clean, const.Second)
	end
end

-- Make additional special effect: when monster dies, spawn other monsters.
local FieldsToCopy = {"Hostile", "Ally", "NoFlee", "HostileType", "Group", "MoveType"}

local function SummonWithDelay(Count, Source, Delay, SummonId)

	local f = function()
		local StartTime = Game.Time
		while Game.Time < StartTime + Delay do
			Sleep(25,25)
		end

		for i = 1, Count do
			local NewMon = SummonMonster(SummonId, random(Source.X-100, Source.X+100), random(Source.Y-100, Source.Y+100), Source.Z + random(50,150), true)
			if NewMon then
				NewMon.Direction = random(0,2047)
				NewMon.LookAngle = random(100,400)
				NewMon.Velocity  = 10000
				NewMon.VelocityY = random(1000,2000)
				for k,v in pairs(FieldsToCopy) do
					NewMon[k] = Source[k]
				end
			end
			Source.SpecialA = Source.SpecialA + 1
		end

		Source.GraphicState = -1
		Source.AIState = const.AIState.Removed
	end

	coroutine.resume(coroutine.create(f))

end

function events.MonsterKilled(mon)

	if mon.Special == 4 then

		local SummonId = mon.SpecialD

		if SummonId == 0 then
			local WeakMonId = ceil(mon.Id/3)*3-2
			if mon.Id ~= WeakMonId then
				SummonId = mon.Id - 1
			else
				SummonId = mon.Id
			end
		end

		-- don't allow to summon same monsters as killed one.
		if SummonId == mon.Id then
			return
		end

		local count = (mon.SpecialC == 0 and 2 or mon.SpecialC) - mon.SpecialA
		SummonWithDelay(count, mon, const.Minute/6, SummonId)

	end
end

