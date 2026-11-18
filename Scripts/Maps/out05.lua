
local function ClearLandQuest()

	if 	not	(Party.QBits[22] or Party.QBits[155])
		and	evt.CheckMonstersKilled{2, 189, 0}
		and	evt.CheckMonstersKilled{2, 190, 0}
		and	evt.CheckMonstersKilled{2, 191, 0} then

		evt.Set{"QBits", 155}
		Game.ShowStatusText(evt.str[70])

	end

	if 	not	(Party.QBits[21] or Party.QBits[158])
		and	evt.CheckMonstersKilled{2, 42, 0}
		and	evt.CheckMonstersKilled{2, 43, 0}
		and	evt.CheckMonstersKilled{2, 44, 0} then

		evt.Set{"QBits", 158}
		Game.ShowStatusText(evt.str[71])

	end

end

evt.Map[131] = ClearLandQuest
