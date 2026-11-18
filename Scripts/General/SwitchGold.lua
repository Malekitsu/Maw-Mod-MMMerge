function events.BeforeLoadMap(WasInGame)
	local i = TownPortalControls.MapOfContinent(Map.MapStatsIndex)
	local mm8 = (i ~= 2) and (i ~= 3)
	local pic = (mm8 and {"item204", "item205", "item206"} or {"7item187", "7item188", "7item189"})
	local sprite = (mm8 and {83, 84, 85} or {283, 284, 285})
	for i = 1, 3 do
		local a = Game.ItemsTxt[i + 186]
		a.Picture = pic[i]
		a.SpriteIndex = sprite[i]
	end
end
