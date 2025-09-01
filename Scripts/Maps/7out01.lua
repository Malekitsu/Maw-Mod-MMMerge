if isRedone then
	-- Remove arcomage from Emerald Island's taverns
	Map.Monsters[20].NameId=0
	function events.DrawShopTopics(t)
		if t.HouseType == const.HouseType.Tavern then
			t.Handled = true
			t.NewTopics[1] = const.ShopTopics.RentRoom
			t.NewTopics[2] = const.ShopTopics.BuyFood
			t.NewTopics[3] = const.ShopTopics.Learn
		end
	end

	evt.hint[109] = evt.str[3]  -- "Well"
	evt.hint[222] = evt.str[4]  -- "Drink from the Well"
	evt.map[222] = function()
		if not evt.Cmp("QBits", 316) then         -- 1-time EI Well
			evt.Add("Gold", 3000)
			evt.ForPlayer("All")
			evt.Set("QBits", 316)         -- 1-time EI Well
			evt.Add("BaseEndurance", 30)
			evt.Add("SkillPoints", 8)
		end
	end

	evt.hint[109] = evt.str[3]  -- "Well"
	evt.hint[221] = evt.str[4]  -- "Drink from the Well"
	evt.map[221] = function()
		if evt.Cmp{"FireResBonus", Value = 50} then
			Game.ShowStatusText ("Refreshing!")         -- "Refreshing!"
		else
			for i=0, Party.High do
				evt.ForPlayer(i)
				evt.Set("FireResBonus", 50)
				if not evt.Cmp{"AutonotesBits", Value = 258} then
					evt.Add("Experience", 500)
				end
			end
			Game.ShowStatusText("+50 Fire Resistance temporary.")          -- "+50 Fire Resistance temporary."
			evt.Add{"AutonotesBits", Value = 258}         -- "50 points of temporary Fire resistance from the central town well on Emerald Island."
		end
	end	

	evt.hint[223] = evt.str[100] 
	evt.map[223] = function()
		evt.ForPlayer(0)
		if not vars.cameBackToEmeraldIsland and evt.Cmp{"Awards", Value = 3} then         -- Return to EI
			vars.cameBackToEmeraldIsland=true
			local function transform(mon)
				mon.Hostile = true
				mon.ShowAsHostile = true
				mon.Velocity=350
			end
			pseudoSpawnpoint{monster = 205, x = 3244,y = 9265,Z = 900,count = 10,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 3244,y = 9265,Z = 900,count = 10,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 4406,y = 8851,Z = 900,count = 2,powerChances = {0,0,100},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 500,y = 8191,Z = 700,count = 8,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 5893,y = 8379,Z = 400,count = 8,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 6758,y = 8856,Z = 0,count = 10,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 7738,y = 7005,Z = 0,count = 2,powerChances = {0,0,100},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 8402,y = 7527,Z = 0,count = 6,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 9881,y = 7481,Z = 0,count = 5,powerChances = {0,100,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 11039,y = 7117,Z = 0,count = 4,powerChances = {0,100,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 12360,y = 6764,Z = 0,count = 7,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 13389,y = 6797,Z = 0,count = 4,powerChances = {0,100,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 14777,y = 6911,Z = 0,count = 2,powerChances = {0,0,100},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 12560,y = 5717,Z = 0,count = 7,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 12438,y = 4787,Z = 170,count = 5,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 12481,y = 3299,Z = 0,count = 2,powerChances = {0,0,100},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 12674,y = 2105,Z = 0,count = 7,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 11248,y = 2852,Z = 0,count = 4,powerChances = {0,100,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 9585,y = 5015,Z = 0,count = 6,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}
			pseudoSpawnpoint{monster = 205,x = 12205,y = 4919,Z = 170,count = 3,powerChances = {100,0,0},radius = 512,group = 2,transform = transform}

			evt.SpeakNPC{NPC = 1184}        -- "Cristalyn"
		end
	end
end
