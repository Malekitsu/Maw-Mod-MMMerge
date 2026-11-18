local function update(i)

	local ContSet, S, V

	-- MM6 original: S, V = 1.0, 1.0
	-- MM7 original: S, V = 0.65, 1.1
	-- MM8 original: S, V = 1.0, 1.1

	if Game.MapStats[Map.MapStatsIndex].EaxEnvironments == 25 then -- PSYCHOTIC
		S, V = 0.5, 0.5
	else
		ContSet = Game.ContinentSettings[i or 1]
		S, V = ContSet.Saturation or 1.0, ContSet.Softness or 1.1
	end

	if (Game.PatchOptions or {}).PaletteVMul then
		Game.PatchOptions.PaletteSMul, Game.PatchOptions.PaletteVMul = S, V
	end
	-- setting Game.PatchOptions.PaletteVMul doesn't actually do anything at this stage
	mem.IgnoreProtection(true)
	mem.r4[0x4E8878] = V
	mem.IgnoreProtection(false)

end

function events.BeforeLoadMap(WasInGame)
	update(TownPortalControls.MapOfContinent(Map.MapStatsIndex))
end

local ver = {}

for i,set in pairs(Game.ContinentSettings) do
	for _,v in pairs(set.Water) do
		ver[v] = i
	end
end

function events.BeforeLoadWater(SW, HW)
	update(ver[SW])
end
