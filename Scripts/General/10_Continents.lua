local MV = Merge.Vars

function events.BeforeLoadMap(WasInGame)
	if WasInGame then
		MV.PrevContinent = MV.Continent
		MV.PrevMap = MV.Map
	else
		MV.PrevContinent = nil
		MV.PrevMap = nil
	end
	MV.World = 1
	MV.Map = Map.MapStatsIndex
	MV.Continent = TownPortalControls.MapOfContinent(MV.Map)
	if MV.Continent ~= MV.PrevContinent then
		events.call("ContinentChange1")
	end
end

function events.LoadMapScripts()
	if MV.Continent ~= MV.PrevContinent then
		events.call("ContinentChange2")
	end
end

function events.AfterLoadMap()
	if MV.Continent ~= MV.PrevContinent then
		events.call("ContinentChange3")
	end
end


