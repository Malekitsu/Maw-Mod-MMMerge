-----------------------------------------
-- Rescue dwarfs quest (mm7)

local function RemoveDwarves()
	if Party.QBits[610] then
		for i = 399, 405 do
			NPCFollowers.Remove(i)
		end
		NPCFollowers.Rebuild()
	end
end

evt.Global[858] = RemoveDwarves

for i = 0, 6 do
	evt.Global[859+i] = function()
		NPCFollowers.Add(399+i)
	end
end

-- Clear leftover dwarves in case they were not removed properly
function events.EnterNPC(i)
	if i == 398 then
		RemoveDwarves()
	end
end

-----------------------------------------
-- Rescue Loren Steel quest (mm7)

local RemoveLoren = function()
	if not Party.QBits[1695] then
		NPCFollowers.Remove(410) -- Loren
	end
	if not Party.QBits[1696] then
		NPCFollowers.Remove(411) -- fake Loren
	end
end
evt.Global[875] = RemoveLoren
evt.Global[876] = RemoveLoren
evt.Global[885] = RemoveLoren
evt.Global[886] = RemoveLoren

evt.Global[884] = function()
	if Party.QBits[1696] then
		NPCFollowers.Add(411)
	end
end -- Loren rescue part is in 7d08.lua

-----------------------------------------
-- Choose Judge quest (mm7)

evt.Global[891] = function()
	NPCFollowers.Remove(416)
	NPCFollowers.Add(417)
end

evt.Global[893] = function()
	NPCFollowers.Remove(417)
	NPCFollowers.Add(416)
end

-----------------------------------------
-- Rescue Angela Dowson quest (mm6)

evt.Global[1642] = function()
	NPCFollowers.Remove(980)
end

-----------------------------------------
-- Rescue Melody Silver quest (paladin promotion) (mm6)

evt.Global[1344] = function()
	NPCFollowers.Add(796)
end

evt.Global[1327] = function()
	if not Party.QBits[1699] then
		NPCFollowers.Remove(796)
	end
end

-----------------------------------------
-- Nicolai's quest (mm6)

local function KidnapNicolai()
	NPCFollowers.Remove(798)
	Party.QBits[1114] = false
	Party.QBits[1700] = false

	evt.MoveNPC{798, 1595}
	evt.Add{"QBits", 1119}
	evt.SetNPCTopic{798, 0, 1334}

	Game.ShowStatusText(Game.NPCText[1720], 5)
	RemoveTimer(KidnapNicolai)
end

function events.AfterLoadMap()
	if Party.QBits[1114] and NPCFollowers.NPCInGroup(798) then
		Timer(KidnapNicolai, 256*5, Game.Time + 256*60)
	end
end

Game.GlobalEvtLines:RemoveEvent(1331)
evt.Global[1331] = function()
	Timer(KidnapNicolai, 256*5, Game.Time + 256*60)
	NPCFollowers.Add(798)

	evt.MoveNPC{798, 0}
	evt.Add{"QBits", 1114}
	evt.Add{"QBits", 1700}
	evt.SetMessage{1718}
	evt.SetNPCTopic{798, 0, 1332}
end

evt.Global[1333] = function()
	NPCFollowers.Remove(798)
end

evt.Global[1334] = function()
	NPCFollowers.Add(798)
end -- Other part is in outd3.lua

-----------------------------------------
-- The Prince of thieves quest (mm6)

evt.Global[1346] = function()
	if not Party.QBits[1701] then
		NPCFollowers.Remove(802)
	end
end -- Other part is in sewer.lua

-- Remove Prince of thieves, if he was not properly removed before
evt.Global[1347] = function()
	NPCFollowers.Remove(802)
end

-----------------------------------------
-- Rescue Emmanuel quest (mm6)

evt.Global[1631] = function()
	if not Party.QBits[1702] then
		NPCFollowers.Remove(893)
	end
end

evt.Global[1634] = function()
	NPCFollowers.Add(893)
end -- Other part is in 6t8.lua

-----------------------------------------
-- Rescue Sherry Carnegie quest (mm6)

evt.Global[1638] = function()
	NPCFollowers.Remove(978)
end

evt.Global[1640] = function()
	NPCFollowers.Add(978)
end -- Other part is in 6d03.lua

-----------------------------------------
-- Rescue Sherell Ivanoveh quest (mm6)

evt.Global[1645] = function()
	if not Party.QBits[1705] then
		NPCFollowers.Remove(940)
	end
end

evt.Global[1646] = function()
	NPCFollowers.Add(940)
end -- Other part is in 6t3.lua

