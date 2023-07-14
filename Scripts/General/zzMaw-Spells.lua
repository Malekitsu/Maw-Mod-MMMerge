--NERF TO DOP AND DOG
function events.Tick()
	if Party.SpellBuffs[2].Skill>=2 then
		m=Party.SpellBuffs[2].Skill
		Party.SpellBuffs[2].Power=Party.SpellBuffs[2].Power/(m+1)*(m/2)
		Party.SpellBuffs[2].Skill=1
	end

	dopList = {0, 1, 4, 6, 12, 17}

	for i = 1, #dopList do
		item=dopList[i]
		if Party.SpellBuffs[item].Skill>=2 then
			m=Party.SpellBuffs[item].Skill
			Party.SpellBuffs[item].Power=Party.SpellBuffs[item].Power/(m+1)*(m-1)
			Party.SpellBuffs[item].Skill=1
		end
	end
end