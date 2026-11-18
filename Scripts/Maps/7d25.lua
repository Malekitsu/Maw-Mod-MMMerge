
function events.AfterLoadMap()
	if Party.QBits[612] then
		evt.SetMonGroupBit{57, const.MonsterBits.Hostile, true}
		evt.SetMonGroupBit{56, const.MonsterBits.Hostile, true}
		evt.SetMonGroupBit{55, const.MonsterBits.Hostile, true}
	end
end
