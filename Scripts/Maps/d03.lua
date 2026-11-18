
-- Enter Throne Room

Game.MapEvtLines:RemoveEvent(5)
evt.Hint[5] = evt.str[20]
evt.Map[5] = function()
	if Party.QBits[611] or not Party.QBits[612]
		or Party.EnemyDetectorYellow
		or Party.EnemyDetectorRed then

		Game.ShowStatusText(evt.str[21])
	elseif Party.QBits[710] then
		evt.EnterHouse{221}
	else
		evt.EnterHouse{219}
	end
end

function events.LoadMap()
	if vars.Quest_CrossContinents and Party.QBits[633] then
		vars.Quest_CrossContinents.ContinentFinished[2] = true
	end
end
