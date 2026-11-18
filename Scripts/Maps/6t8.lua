
-----------------------------------------
-- Rescue Emmanuel quest (mm6)

evt.Map[25] = function()
	if Party.QBits[1702] then
		NPCFollowers.Add(893)
	end
end

-----------------------------------------
-- Do not bolster Q

function events.BeforeMonsterBolster(t)
	if t.Monster and t.Monster.NameId == 123 then
		t.Handled = true
	end
end
