-- Dimension door

evt.map[500] = TownPortalControls.DimDoorEvent

function events.TileSound(t)
	if t.X == 43 and t.Y == 98 then
		TownPortalControls.DimDoorEvent()
	end
end

-- Let statues be dispelled without scroll if player have stone-to-flesh spell.

local function SpeakStatueNPC(i)
	local HaveSpell = Party[math.max(Game.CurrentPlayer, 0)].Spells[40]

	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", 339} or HaveSpell then
		if not HaveSpell then
			evt.Subtract{"Inventory", 339}
		end
		evt.SetSprite{i-132+20, 0, "0"}
		evt.SpeakNPC{46}
	end
end

for i = 133, 136 do
	Game.MapEvtLines:RemoveEvent(i)
	evt.Hint[i] = evt.Str[13]
	evt.Map[i] = SpeakStatueNPC
end

Game.MapEvtLines:RemoveEvent(132)
evt.Hint[132] = evt.Str[13]
evt.Map[132] = function()
	local HaveSpell = Party[math.max(Game.CurrentPlayer, 0)].Spells[40]

	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", 339} or HaveSpell then
		if not HaveSpell then
			evt.Subtract{"Inventory", 339}
		end
		evt.SetSprite{20, 0, "0"}
		evt.Add{"QBits", 40}
		evt.Add{"QBits", 430}
		evt.SpeakNPC{42}
	end
end

-- Gems-exchange tree

local GemsItemTypes = {20,21,22,40,43}

local GemsExchangeTable = {
-- Amber
[180]	= 250,
[2102]	= 250,
-- Amethyst
[181]	= 183,
[2060]	= 183,
-- Citrine
[179]	= 181,
-- Diamond
[997]	= 656,
[994]	= 656,
[186]	= 656,
[2056]	= 656,
-- Emerald
[2064]	= 655,
[990]	= 655,
[183]	= 655,
[2061]	= 655,
-- Lolite
[178]	= 132,
-- Ruby
[998]	= 271,
[2059]	= 271,
[185]	= 271,
-- Sapphire
[2065]	= -2000, -- Gold
[991]	= -2000, -- Gold
[184]	= -2000, -- Gold
-- Topaz
[2058]	= 0, -- Random item
[989]	= 0, -- Random item
[182]	= 0, -- Random item
-- Zircon
[177]	= 179
}

Game.MapEvtLines:RemoveEvent(455)
evt.Hint[455] = evt.Str[40]
evt.Map[455] = function()

	local PlId = Game.CurrentPlayer
	if PlId < 0 then
		return
	end

	local Player = Party[PlId]
	for i,v in Player.Items do
		local Val = GemsExchangeTable[v.Number]
		if Val then
			if Val > 0 then
				evt[PlId].Add{"Inventory", Val}
			elseif Val < 0 then
				evt[PlId].Add{"Gold", -Val}
			else
				Val = GemsItemTypes[math.random(1,#GemsItemTypes)]
				evt[PlId].GiveItem{3,Val,0}
			end
			v.Number = 0
			break
		end
	end

end
