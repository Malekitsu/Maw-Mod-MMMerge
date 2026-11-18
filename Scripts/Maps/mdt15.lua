
-- Reset control cube and blaster on map refill (both could be acquired only once)

function events.AfterLoadMap()
	if Map.Refilled then
		local function set_items(mon)
			for i,v in mon.Items do
				v.Number = 0
			end
			mon.Item = 1477
			mon.Items[0].Number = 866
		end

		if Map.Monsters.count >= 1 then
			set_items(Map.Monsters[0])
		end

		if Map.Monsters.count >= 2 then
			set_items(Map.Monsters[1])
		end
	end
end
