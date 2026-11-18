
evt.SetMonGroupBit {56,  const.MonsterBits.Hostile,  false}
evt.SetMonGroupBit {56,  const.MonsterBits.Invisible, true}

Game.MapEvtLines:RemoveEvent(501)
evt.hint[501] = evt.str[2]
evt.map[501] = function()

	for i,v in Party do
		if v.ItemArmor == 0 or v.Items[v.ItemArmor].Number ~= 1406 then
			if not evt[i].Cmp{"Inventory", 1406} then
				Game.ShowStatusText(evt.str[20])
				return
			end
		end
	end

	evt.MoveToMap{-7005, 7856, 225, 128, 0, 0, 0, 8, "7out15.odm"}

end
