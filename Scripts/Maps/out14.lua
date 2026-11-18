
function events.WalkToMap(t)

	if t.LeaveSide == "left" then

		for i,v in Party do
			if v.ItemArmor == 0 or v.Items[v.ItemArmor].Number ~= 1406 then
				if not evt[i].Cmp{"Inventory", 1406} then
					if Party.QBits[642] or Party.QBits[643] or Party.QBits[783] then
						Game.ShowStatusText("You must all be wearing your wetsuits!")
					end
					return
				end
			end
		end

		evt.MoveToMap{20096,-16448,2404,1008,0,0,0,8,"7out15.odm"}
	end

end
