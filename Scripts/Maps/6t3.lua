-----------------------------------------
-- Rescue Sherell Ivanoveh quest (mm6)

evt.Map[30] = function()
	if Party.QBits[1705] then
		NPCFollowers.Add(940)
	end
end

function events.BeforeMonsterBolster(t)
	if t.Monster and t.Monster.NameId == 123 then -- Q
		t.Handled = true
	end
end
