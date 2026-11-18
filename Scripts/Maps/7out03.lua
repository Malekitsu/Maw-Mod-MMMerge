
-- Travel to Emerald Isle if Player was not there before.

if Party.QBits[519] then
	Game.TransportIndex[34][4] = 44
else
	Game.TransportIndex[34][4] = 101
end

-- Give "Scavenger hunt" advertisment

local CCTimers = {}

function events.AfterLoadMap()
	if not (mapvars.GotAdvertisment or Party.QBits[519]) then

		CCTimers.Catch = function()
			if not (Party.Flying or Party.EnemyDetectorRed or Party.EnemyDetectorYellow)
				and 4000 > math.sqrt((-10511-Party.X)^2 + (6119-Party.Y)^2) then

				mapvars.GotAdvertisment = true
				RemoveTimer(CCTimers.Catch)
				evt.ForPlayer(0).Add{"Inventory", 774}
				evt.SetNPCGreeting(649, 332)
				evt.SpeakNPC{649}

			end
		end
		Timer(CCTimers.Catch, false, const.Minute*3)

	end
end
