Game.MapEvtLines:RemoveEvent(24)
evt.hint[24] = evt.str[6]	-- "Evil Altar"
evt.Map[24] = function()
	if Party.QBits[1047] then	-- 23 D13, Given when Altar is desecrated
		return
	end
	evt.SetTexture{Facet = -949, Name = "d6flora"}
	evt.SetTexture{Facet = -947, Name = "d6flora"}
	evt.SetTexture{Facet = -927, Name = "d6flora"}
	evt.SetTexture{Facet = -928, Name = "d6flora"}
	evt.SetTexture{Facet = -929, Name = "d6flora"}
	evt.SetTexture{Facet = -948, Name = "d6flora"}
	evt.SetTexture{Facet = -945, Name = "d6flora"}
	evt.SetTexture{Facet = -946, Name = "d6flora"}
	evt.SetTexture{Facet = -944, Name = "d6flora"}
	evt.SetTexture{Facet = -943, Name = "d6flora"}
	evt.SetTexture{Facet = -942, Name = "d6flora"}
	evt.StatusText{Str = 11}	-- "+5 Personality permanent to Druids and Clerics."
	for k, player in Party do
		evt.ForPlayer(k)
		if evt.Cmp{"ClassIs", Value = const.Class.Cleric}
				or evt.Cmp{"ClassIs", Value = const.Class.Druid}
				or not evt.Cmp{"MapVar7", Value = 0} then
			evt.Add{"BasePersonality", Value = 5}
		end
	end
	Party.QBits[1047] = true	-- 23 D13, Given when Altar is desecrated
end
