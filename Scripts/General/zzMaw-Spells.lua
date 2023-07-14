-------------------------------------------------
--Nerf to Day of Protection and Day of the Gods--
-------------------------------------------------
function events.Tick()
	--Day of Protection
	dopList = {0, 1, 4, 6, 12, 17}
	for i = 1, #dopList do
		item=dopList[i]
		if Party.SpellBuffs[item].Skill>=2 then
			m=Party.SpellBuffs[item].Skill
			Party.SpellBuffs[item].Power=Party.SpellBuffs[item].Power/(m+1)*(m-1)
			Party.SpellBuffs[item].Skill=1
		end
	end
	
	--Day of the Gods
	if Party.SpellBuffs[2].Skill>=2 then
		m=Party.SpellBuffs[2].Skill
		Party.SpellBuffs[2].Power=(Party.SpellBuffs[2].Power-10)/(m+1)*(m/2)+5*m
		Party.SpellBuffs[2].Skill=1
	end
end

----------------
--Tooltips fix--
----------------

--Day of Protection
function events.GameInitialized2()
	Game.SpellsTxt[83].Description="Temporarily increases all seven stats on all your characters by 1 per skill in Light Magic.  This spell lasts until you rest."
	Game.SpellsTxt[83].Expert="All stats increased by 10+1 per skill"
	Game.SpellsTxt[83].Master="All stats increased by 15+1.5 per skill"
	Game.SpellsTxt[83].GM="All stats increased by 20+2 per skill"

	--Day of the Gods
	Game.SpellsTxt[85].Description="Simultaneously casts Protection from Fire, Air, Water, Earth, Mind, and Body, plus Feather Fall and Wizard Eye on all your characters at two times your skill in Light Magic."
	Game.SpellsTxt[85].Master="All spells cast at two times skill"
	Game.SpellsTxt[85].GM="All spells cast at three times skill"
end
