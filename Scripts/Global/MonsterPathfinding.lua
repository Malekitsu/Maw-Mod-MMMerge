local abs, max, min, sqrt, ceil, floor, random = math.abs, math.max, math.min, math.sqrt, math.ceil, math.floor, math.random
local deg, asin, sin, rad = math.deg, math.asin, math.sin, math.rad
local tinsert, tremove = table.insert, table.remove
local costatus, coresume, coyield, cocreate = coroutine.status, coroutine.resume, coroutine.yield, coroutine.create

if not PathfinderDll then
	if type(PathfinderDll) == "boolean" then
		return
	end

	require("PathfinderDll")
	if not PathfinderDll then
		PathfinderDll = false -- Error message is shown by PathfinderDll module
		return
	end
end
Pathfinder = Pathfinder or {}

local TickEndTime = 0 -- end time for coroutines in current tick.
local MonsterWays = {}
local MonStuck = {}
local IsOutdoor = false

--------------------------------------------------
--					Base functions				--
--------------------------------------------------

local function EqualCoords(a, b, Precision)
	if not Precision then
		return a.X == b.X and a.Y == b.Y and a.Z == b.Z
	else
		return	a.X > b.X - Precision and a.X < b.X + Precision and
				a.Y > b.Y - Precision and a.Y < b.Y + Precision and
				a.Z > b.Z - Precision and a.Z < b.Z + Precision
	end
end

local function GetDist(px, py, pz, x, y, z)
	return sqrt((px-x)^2 + (py-y)^2 + (pz-z)^2)
end

local function GetDist2(p1, p2)
	local px, py, pz = XYZ(p1)
	local x, y, z = XYZ(p2)
	return sqrt((px-x)^2 + (py-y)^2 + (pz-z)^2)
end

local function GetDistXY(px, py, x, y)
	return sqrt((px-x)^2 + (py-y)^2)
end

local function DirectionToPoint(From, To)
	local angle, sector
	local X, Y = From.X - To.X, From.Y - To.Y
	local Hy = sqrt(X^2 + Y^2)

	angle = asin(abs(Y)/Hy)
	angle = (angle/rad(90))*512

	if X < 0 and Y < 0 then
		angle = angle + 1024
	elseif X < 0 and Y >= 0 then
		angle = 1024 - angle
	elseif X >= 0 and Y < 0 then
		angle = 2048 - angle
	end

	return floor(angle)
end
Pathfinder.DirectionToPoint = DirectionToPoint

local function SetMonAction(i, mon, AIState, GraphicState, Length, Step)
	mon.GraphicState = GraphicState
	mon.AIState = AIState
	mon.CurrentActionLength = Length
	mon.CurrentActionStep = Step

	if Multiplayer then
		Multiplayer.monster_action(i, mon, AIState) -- Multiplayer
	end
end

--------------------------------------------------
--					Tracer						--
--------------------------------------------------

local function TraceSight(Monster, To)
	return PathfinderDll.TraceLine(Monster, To, Monster.BodyHeight)
end
Pathfinder.TraceSight = TraceSight

--Pathfinder.TraceMonWayAsm(1, Map.Monsters[1], Map.Monsters[1], Party, 30)
local function TraceMonWayAsm(MonId, Monster, From, To, Radius)
	return PathfinderDll.TraceWay(Monster, From, To)
end
Pathfinder.TraceMonWayAsm = TraceMonWayAsm

local function TraceReach(MonId, Monster, Target)
	if not TraceSight(Monster, Target) then
		return false
	end

	if Monster.Attack1.Missile > 0 or Monster.Attack2.Missile > 0 then
		return true
	end

	-- if there're water tiles between monster and target, and monster cannot shoot, return false
	return TraceMonWayAsm(MonId, Monster, Monster, Target, Monster.BodyRadius)
end
Pathfinder.TraceReach = TraceReach

--------------------------------------------------
--				Way generation			--
--------------------------------------------------

local function ShrinkMonWay(WayMap, MonId, StepSize, Async)
	MonId = MonId or 1
	StepSize = StepSize or #WayMap
	local Current = 1
	local Monster = Map.Monsters[MonId]
	local TraceRadius = ceil(Monster.BodyRadius/3)

	while Current < #WayMap do
		for i = min(Current + StepSize, #WayMap), Current + 1, -1 do
			if TraceMonWayAsm(MonId, Monster, WayMap[Current], WayMap[i], TraceRadius) then
				for _ = Current + 1, i - 1 do
					tremove(WayMap, Current + 1)
				end
				break
			end
		end
		Current = Current + 1
		if Async and timeGetTime() > TickEndTime then
			coyield()
		end
	end

	return WayMap
end
Pathfinder.ShrinkWay = ShrinkMonWay

local function AStarWay(MonId, Monster, Target, Async, CustomStart)
	local t = {MonId = MonId, ToX = Target.X, ToY = Target.Y, ToZ = Target.Z, Async = Async, AvAreas = AvAreas}
	if CustomStart then
		t.FromX = CustomStart.X
		t.FromY = CustomStart.Y
		t.FromZ = CustomStart.Z
	end
	return PathfinderDll.AStarWay(t)
end
Pathfinder.AStarWay = AStarWay

--------------------------------------------------
--				Game handler					--
--------------------------------------------------
local AStarQueue = {}
Pathfinder.AStarQueue = AStarQueue

local function AStarQueueSort(v1, v2)
	return v1.Dist < v2.Dist
end
local function SortQueue()
	local Way, v, Mon
	for i = #AStarQueue, 1, -1 do
		v = AStarQueue[i]
		if v.MonId >= Map.Monsters.count then
			tremove(AStarQueue, i)
		else
			Mon = Map.Monsters[v.MonId]
			v.Dist = GetDist2(Mon, v.Target)
			if Map.Monsters[v.MonId].Fly == 1 then
				v.Dist = v.Dist + 1000
			end
			v.Dist = v.Dist + v.MonWay.FailCount*1000
		end
	end
	table.sort(AStarQueue, AStarQueueSort)
end

local function ClearQueue()
	while #AStarQueue > 0 do
		tremove(AStarQueue)
	end
end

local function ProcessThreads()
	if #AStarQueue == 0 then
		return
	end

	TickEndTime = timeGetTime() + 3
	SortQueue()

	local co = AStarQueue[1] and AStarQueue[1].co
	while co and timeGetTime() < TickEndTime do
		if costatus(co) == "dead" then
			tremove(AStarQueue, 1)
			co = AStarQueue[1] and AStarQueue[1].co
		else
			local err, res = coresume(co)
			if type(res) == "string" then
				debug.Message(res)
			end
		end
	end
end

local function MakeMonWay(cMonWay, cMonId, cTarget)
	local WayMap
	local TooFar = false
	local Monster = Map.Monsters[cMonId]

	cMonWay.InProcess = true
	cMonWay.NeedRebuild = false
	cMonWay.X = cTarget.X
	cMonWay.Y = cTarget.Y
	cMonWay.Z = cTarget.Z
	coyield()

	cMonWay.HoldMonster = true

	WayMap = AStarWay(cMonId, Monster, cTarget, true)

	if #WayMap > 0 then
		cMonWay.GenTime = Game.Time
		cMonWay.FailCount = 0
	else
		 -- delay next generation if previous one failed
		cMonWay.FailCount = cMonWay.FailCount + 1
		cMonWay.GenTime = Game.Time + const.Minute*4
	end
	SetMonAction(cMonId, Monster, 6, 1, 256, 0)

	cMonWay.WayMap = WayMap
	cMonWay.Step = 1
	cMonWay.Size = #cMonWay.WayMap
	cMonWay.HoldMonster = false
	cMonWay.InProcess = false
end

local function SetQueueItem(MonWay, MonId, Target)
	local co = cocreate(MakeMonWay)
	coresume(co, MonWay, MonId, Target)
	tinsert(AStarQueue, {co = co, MonId = MonId, Dist = ceil(GetDist2(Map.Monsters[MonId], Target)), Target = Target, MonWay = MonWay})
end

local function StuckCheck(MonId, Monster)
	MonStuck[MonId] = MonStuck[MonId] or {X = 0, Y = 0, Z = 0, Time = Game.Time, Stuck = 0}
	local StuckCheck = MonStuck[MonId]
	if Monster.AIState == 6 and EqualCoords(StuckCheck, Monster) then
		StuckCheck.Stuck = Game.Time - StuckCheck.Time
		if StuckCheck.Stuck > 512 then
			StuckCheck.Stuck = 0
			return true
		end
	else
		StuckCheck.Time = Game.Time
		StuckCheck.Stuck = 0
		StuckCheck.X = Monster.X
		StuckCheck.Y = Monster.Y
		StuckCheck.Z = Monster.Z
	end

	return false
end

local function MonsterNeedsProcessing(i, Mon)
	local result = true
	if not (Mon.Active and Mon.HP > 0) then
		return false
	end

	if IsOutdoor then
		result = Mon.Fly == 0 and GetDist2(Mon, Party) < 12000
	else
		if Mon.Fly == 1 then
			result = GetDist2(Mon, Party) < 6000
		else
			result = GetDist2(Mon, Party) < 12000
		end
	end

	local t = {
		MonsterIndex = i,
		Monster = Mon,
		Result = result and (Mon.AIState == 6 or (Mon.ShowAsHostile and Mon.AIState == 1))
		}

	events.call("MonsterNeedPathfinding", t)
	return t.Result
end
Pathfinder.MonsterNeedsProcessing = MonsterNeedsProcessing

local function MonsterTargetInSight(MonId, MonWay)
	if (Game.Time - MonWay.LastSeenTarget) < const.Minute then
		return true
	end

	local TargetRef, Target = GetMonsterTarget(MonId)
	if TargetRef == 4 then
		if Party.SpellBuffs[const.PartyBuff.Invisibility].ExpireTime > Game.Time then
			return false
		end
		Target = Party
	elseif TargetRef == 3 and Target < Map.Monsters.count then
		Target = Map.Monsters[Target]
	else
		return true
	end

	local Monster = Map.Monsters[MonId]
	MonWay.TargetInSight = GetDist2(Monster, Party) < 2000 and TraceReach(MonId, Monster, Target)
	if (MonWay.TargetInSight) then
		MonWay.LastSeenTarget = Game.Time
		return true
	end
	return false
end

local NextMon = 0
local function ProcessNextMon()
	if not Game.ImprovedPathfinding or Game.TurnBased then
		return
	end

	if IsOutdoor and Party.Z - Map.GetFloorLevel(XYZ(Party)) > 200 then
		return
	end

	local Target, TargetRef, Monster, MonWay
	local count = 0
	if NextMon >= Map.Monsters.count then
		NextMon = 0
	end

	for MonId = NextMon, Map.Monsters.count - 1 do
		if count > 40 then
			break
		end

		count = count + 1
		NextMon = MonId + 1
		Monster = Map.Monsters[MonId]

		if MonsterNeedsProcessing(MonId, Monster) then

			TargetRef, Target = GetMonsterTarget(MonId)
			-- 11 is const.PartyBuff.Invisibility
			if TargetRef == 4 and Party.SpellBuffs[11].ExpireTime < Game.Time then
				Target = Party
			elseif TargetRef == 3 and Target < Map.Monsters.count then
				Target = Map.Monsters[Target]
			else
				Target = false
			end

			--Target = Party

			MonWay = MonsterWays[MonId] or {
				Status = "",
				WayMap = {},
				NeedRebuild = true,
				InProcess = false,
				TargetInSight = false,
				LastSeenTarget = 0,
				GenTime	= 0,
				StuckTime = 0,
				Size = 0,
				Step = 0,
				FailCount = 0}

			MonsterWays[MonId] = MonWay

			if StuckCheck(MonId, Monster) then
				if not IsOutdoor and #MonWay.WayMap > 0 and MonWay.Step > 1 and MonWay.Step <= #MonWay.WayMap then
					XYZ(Monster, XYZ(MonWay.WayMap[MonWay.Step - 1]))
					Monster.Z = Monster.Z + 5
				end
				MonWay.Status = "Rebuild due to stuck check."
				MonWay.NeedRebuild = true
			end

			if not Target or MonsterTargetInSight(MonId, MonWay) then
				MonWay.TargetInSight = true

			elseif MonWay.HoldMonster then
				SetMonAction(MonId, Monster, 0, 0, 100, 0)

			elseif MonWay.NeedRebuild then
				if MonWay.InProcess then
					MonWay.NeedRebuild = false
				elseif #AStarQueue < 50 then
					SetQueueItem(MonWay, MonId, Target)
				end

			elseif MonWay.Size > 0 and MonWay.Step < MonWay.Size then
				SetMonAction(MonId, Monster, 6, 1, 100, 0)

				if not MonWay.InProcess and GetDist2(Target, MonWay) > 1024 then
					MonWay.Status = "Rebuild due to change of target's position."
					MonWay.NeedRebuild = true
				end

			elseif MonWay.InProcess then
				-- let it roam
			else
				if Game.Time - MonWay.GenTime > const.Minute*2 then
					MonWay.NeedRebuild = true
				end
			end
		end
	end
end

local function PositionCheck()
	if not Game.ImprovedPathfinding or Game.TurnBased then
		return
	end

	local Monster
	for k,v in pairs(MonsterWays) do
		if k >= Map.Monsters.count then
			MonsterWays[k] = nil
			return
		end
		Monster = Map.Monsters[k]
		if v.WayMap and v.Size > 0 and MonsterNeedsProcessing(k, Monster) and not MonsterTargetInSight(k, v) then
			local WayPoint = v.WayMap[v.Step]
			if WayPoint then
				Monster.Direction = DirectionToPoint(WayPoint, Monster)
				if GetDistXY(WayPoint.X, WayPoint.Y, Monster.X, Monster.Y) < Monster.BodyRadius then
					if v.Step >= v.Size then
						v.WayMap = {}
						v.Size = 0
						if not v.InProcess then
							v.Status = "Rebuild due to end of previous way"
							v.NeedRebuild = true
						end
					else
						v.Step = v.Step + 1
					end
				end
			elseif not v.InProcess and Game.Time > MonWay.GenTime then
				v.NeedRebuild = true
			end
		end
	end
end

local function PathfinderTick()
	ProcessNextMon()
	ProcessThreads()
end

--------------------------------------------------
--					Events						--
--------------------------------------------------

events.LeaveMap = ClearQueue
events.BeforeLeaveGame = ClearQueue
events.BeforeLoadMap = ClearQueue

function events.AfterLoadMap()
	MonsterWays = {}
	MonStuck = {}
	Pathfinder.MonsterWays = MonsterWays
	Pathfinder.MonStuck = MonStuck

	events.Remove("Tick", PathfinderTick)
	events.Remove("MonstersProcessed", PositionCheck)

	if not Game.ImprovedPathfinding then
		return
	end

	PathfinderDll.init_map()
	events.Tick = PathfinderTick
	events.MonstersProcessed = PositionCheck

	IsOutdoor = Map.IsOutdoor()
end

----------------------------------------------
--					SERVICE					--
----------------------------------------------

--~ for i,v in pairs(Pathfinder.MonsterWays) do
--~ 	m = Map.Monsters[i]
--~ 	print(i, Pathfinder.TraceReach(m, m, Party), (Game.Time - v.LastSeenTarget) < const.Minute)
--~ end

--~ --TestPerfomance(AStarWay, 10, 2, Map.Monsters[2], Party, nil, false, MapAreas[16].WayPoint)
--~ function TestPerfomance(f, loopamount, ...)
--~ 	loopamount = loopamount or 100
--~ 	local Start = timeGetTime()
--~ 	for i = 1, loopamount do
--~ 		f(...)
--~ 	end
--~ 	return timeGetTime() - Start
--~ end

--~ function ShowWay(WayMap, Pause)
--~ 	Pause = Pause or 300
--~ 	local Step = 1
--~ 	local PrevCell, NextCell = WayMap[Step], WayMap[Step + 1]
--~ 	while NextCell do
--~ 		Party.X = NextCell.X
--~ 		Party.Y = NextCell.Y
--~ 		Party.Z = NextCell.Z + 5
--~ 		Sleep(Pause,Pause)

--~ 		Step = Step + 1
--~ 		PrevCell, NextCell = WayMap[Step], WayMap[Step + 1]
--~ 	end
--~ end

--~ function ClosestMonster()
--~ 	local MinDist, Mon = 30000, 123
--~ 	for i,v in Map.Monsters do
--~ 		local Dist = GetDist2(Party, v)
--~ 		if MinDist > Dist then
--~ 			MinDist, Mon = Dist, i
--~ 		end
--~ 	end
--~ 	return Mon
--~ end

--~ DisableOutdoorHandler = DisableOutdoorHandler or mem.asmpatch(0x401ab1, "retn")

--~ function ClosestItem(t)
--~ 	local MinDist, Mon = 1/0, nil
--~ 	for i,v in pairs(t) do
--~ 		local Dist = GetDist2(Party, v)
--~ 		if MinDist > Dist then
--~ 			MinDist, Mon = Dist, i
--~ 		end
--~ 	end
--~ 	return Mon
--~ end

--~ function GetPoint(t)
--~ 	return {X = t.X, Y = t.Y, Z = t.Z} -- -1215 -1206
--~ end

--~ function events.AfterLoadMap()
--~ 	function CreateTESTWidget()
--~ 		TESTWidget = CustomUI.CreateText{Text = "", Key = "TESTWidget", X = 200, Y = 240, Width = 400, Height = 100, AlignLeft = true}

--~ 		local function WidgetTimer()
--~ 			TESTWidget.Text = tostring(mem.call(Pathfinder.AltGetFloorLevelAsm, 0, Party.X, Party.Y, Party.Z)) ..
--~ 				" - " .. tostring(Map.GetFloorLevel(XYZ(Party))) .. " : " .. Pathfinder.QueueStatus() .. " - " ..  tostring(#AStarQueue)
--~ 			Game.NeedRedraw = true
--~ 		end

--~ 		Timer(WidgetTimer, const.Minute/64)
--~ 	end
--~ 	CreateTESTWidget()
--~ end

