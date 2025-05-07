
Game.MapEvtLines:RemoveEvent(1)
function events.AfterLoadMap()

	if Map.LastVisitTime + const.Day < Game.Time then
		mapvars.WereratsMad = false
	end

	if Party.QBits[10] and not mapvars.WereratsMad then
		evt.SetMonGroupBit {8,	const.MonsterBits.Hostile,	 false}
		evt.SetMonGroupBit {10,	const.MonsterBits.Hostile,	 false}
		evt.SetMonGroupBit {11,	const.MonsterBits.Hostile,	 false}
		evt.SetMonGroupBit {8,	const.MonsterBits.Invisible, true}
		evt.SetMonGroupBit {11,	const.MonsterBits.Invisible, false}
	else
		evt.Set{"MapVar9", 2}

		evt.SetMonGroupBit {8,	const.MonsterBits.Hostile,	 true}
		evt.SetMonGroupBit {10,	const.MonsterBits.Hostile,	 true}
		evt.SetMonGroupBit {11,	const.MonsterBits.Hostile,	 true}
		--evt.SetMonGroupBit {8,	const.MonsterBits.Invisible, false}
		evt.SetMonGroupBit {11,	const.MonsterBits.Invisible, true}
	end

end

function events.MonsterKilled()
	mapvars.WereratsMad = true
end
