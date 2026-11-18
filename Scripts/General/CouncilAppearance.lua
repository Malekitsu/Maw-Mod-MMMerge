
local CouncilLayer = CustomUI.ActiveElements[13].Icons[1]
local Council = {}
local CouncilPics = {"16", "17", "13", "14", "10", "11", "07", "08", "04", "05", "02", "02"}
local CouncilAwBits = {59, 61, 60, 62, 58, 57}
local PicsActive = true

function events.GameInitialized2()

	-- Preston Steel
	Council[1] = CustomUI.CreateIcon{
		Icon = "npc00" .. CouncilPics[1*2],
		Screen = 13,
		Layer = 1,
		Masked = true,
		X = 10,
		Y = 191
	}

	-- Tori Goldman
	Council[2] = CustomUI.CreateIcon{
		Icon = "npc00" .. CouncilPics[2*2],
		Screen = 13,
		Layer = 1,
		Masked = true,
		X = 95,
		Y = 199
	}

	-- Isaac Rockwell
	Council[3] = CustomUI.CreateIcon{
		Icon = "npc00" .. CouncilPics[3*2],
		Screen = 13,
		Layer = 1,
		Masked = true,
		X = 160,
		Y = 195
	}

	-- Olaf Heimdall
	Council[4] = CustomUI.CreateIcon{
		Icon = "npc00" .. CouncilPics[4*2],
		Screen = 13,
		Layer = 1,
		Masked = true,
		X = 230,
		Y = 198
	}

	-- Euclid Kepler
	Council[5] = CustomUI.CreateIcon{
		Icon = "npc00" .. CouncilPics[5*2],
		Screen = 13,
		Layer = 1,
		Masked = true,
		X = 298,
		Y = 184
	}

	-- Silvertongue
	Council[6] = CustomUI.CreateIcon{
		Icon = "npc00" .. CouncilPics[6*2],
		Condition = function() return not Party.QBits[1192] end,
		Screen = 13,
		Layer = 1,
		Masked = true,
		X = 370,
		Y = 198
	}

end

function events.EnterHouse(i)
	if i == 209 then
		for k,v in pairs(Council) do
			v.MainIcon = "npc00" .. CouncilPics[k*2 - (Party[0].Awards[CouncilAwBits[k]] and 1 or 0)]
			CouncilLayer[v.Key] = v
		end
		PicsActive = true
	elseif PicsActive then
		for k,v in pairs(Council) do
			CouncilLayer[v.Key] = nil
		end
		PicsActive = false
	end
end
