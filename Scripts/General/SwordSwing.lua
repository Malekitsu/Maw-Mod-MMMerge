-- Rod:
-- this is adapted for multiplayer version of
-- original swordSwing.lua script by Ivan Petrov:
-- https://www.celestialheavens.com/forum/10/17628

function events.MultiplayerInitialized()

	Multiplayer.ShowSwordSwings = true
	Multiplayer.ShowRemoteSwordSwings = true

	local sfp = Multiplayer.utils.step_from_point
	local dir = Multiplayer.utils.direction_to_point

	local function disable_sync(obj_id)
		if obj_id < 0 or obj_id >= Map.Objects.count then
			return
		end
		local obj = Map.Objects[obj_id]
		obj.Bits = bit.Or(obj.Bits, Multiplayer.NO_SYNC_OBJECT_BIT)
	end

	-- remote swing: shown on top of monster, uses object with source sprites increased in size
	local function ShowRemoteSwordSwing(Monster)
		local obj_id = select(Game.Rand() % 4 + 1, 704, 705, 706, 707)

		local X, Y, Z = XYZ(sfp(Monster, 10, dir(Monster, Party)))

		if Game.SummonObjects(obj_id, X, Y, Z + Monster.BodyHeight / 1.6, 0, 1, false, 0) == 1 then
			disable_sync(Game.LastCreatedObject())
		end
	end

	-- std swing
	local function ShowSwordSwing(Monster)
		local obj_id = select(Game.Rand() % 4 + 1, 700, 701, 702, 703)
		local X, Y, Z
		local xxD, yyD, zzD, rr, dd, rr2

		xxD = Party.X - Monster.X
		yyD = Party.Y - Monster.Y
		zzD = Party.Z - Monster.Z

		rr = math.atan2(yyD, xxD) + 3.14
		dd = math.sqrt ( math.pow(xxD,2) + math.pow(yyD,2) )
		rr2 = (math.deg ( math.atan2(zzD, dd) ) + 180 )

		X = Party.X + (40*math.cos(rr))
		Y = Party.Y + (40*math.sin(rr))
		Z = math.floor((Monster.Z + (Party.Z*5)) / 6) + Party.LastEyeLevel - 10

		if Game.SummonObjects(obj_id, X, Y, Z, 0, 1, false, 0) == 1 then
			disable_sync(Game.LastCreatedObject())
		end
	end

	-- Setup remote event to process client's swings
	Multiplayer.allow_remote_event("RemoteSwordSwing")
	function events.RemoteSwordSwing(MonsterIndex)
		if not Multiplayer.ShowRemoteSwordSwings or MonsterIndex >= Map.Monsters.count then
			return
		end

		ShowRemoteSwordSwing(Map.Monsters[MonsterIndex])
	end

	function events.MonsterAttacked(t)
		if not t.Handled
			and t.Attacker.Player and not t.Attacker.Object
			and not Multiplayer.posessed_by_player(t.MonsterIndex) then

			if Multiplayer.ShowSwordSwings then
				ShowSwordSwing(t.Monster, t.MonsterIndex)
			end

			if Multiplayer.in_game then
				-- trigger remote event
				Multiplayer.broadcast_mapdata(t.MonsterIndex, "RemoteSwordSwing")
			end
		end
	end

	-- Manage SaveGame data

	function events.LoadMapScripts(WasInGame)
		if not WasInGame then
			Multiplayer.ShowSwordSwings = vars.ShowSwordSwings or false
			Multiplayer.ShowRemoteSwordSwings = vars.ShowRemoteSwordSwings == nil or vars.ShowRemoteSwordSwings
		end
	end

	function events.BeforeSaveGame()
		vars.ShowSwordSwings = Multiplayer.ShowSwordSwings
		vars.ShowRemoteSwordSwings = Multiplayer.ShowRemoteSwordSwings
	end

	-- Add UI to toggle sword swings

	local UI = Multiplayer.utils.UI.CustomSettings
	UI.Header("Sword swings")
	UI.Switch("Show mine swings:    ", Multiplayer, "ShowSwordSwings")
	UI.Switch("Show remote swings:  ", Multiplayer, "ShowRemoteSwordSwings")

end

--~ testf = function()
--~ 	Multiplayer.init()
--~ 	Map.Monsters.count = 0
--~ 	swsw_mon = SummonMonster(301, XYZ(Party))
--~ 	Multiplayer.utils.TickCounter(function() ShowRemoteSwordSwing(swsw_mon) end, 64)
--~ end

--~ function events.Tick()
--~ 	for i,obj in Map.Objects do
--~ 		obj.Bits = bit.Or(obj.Bits, Multiplayer.NO_SYNC_OBJECT_BIT)
--~ 	end
--~ end
