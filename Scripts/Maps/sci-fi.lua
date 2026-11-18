
-- Learn blaster
evt.Map[61] = function()
	for i,v in Party do
		if v.Skills[const.Skills.Blaster] == 0 then
			evt.ForPlayer(i).Set{"BlasterSkill", 1}
		end
	end
end
