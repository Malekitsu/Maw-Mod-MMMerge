
-- Pick portrait
Game.MapEvtLines:RemoveEvent(376)
evt.Hint[376] = mapvars.PortraitTaken and "" or evt.str[15]

evt.Map[376] = function()
	if mapvars.PortraitTaken then
		return
	end

	evt.SetTexture{15,"t2bs"}
	evt[0].Add{"Inventory", 1423}
	Party.QBits[778] = true

	evt.Hint[376] = ""
	mapvars.PortraitTaken = true
end

--MAW
if not mapvars.mawSpawn then
	pseudoSpawnpoint{monster = 307,  x = -25, y = 1312, z = -31, count = 1, powerChances = {100, 0, 0}, radius = 0, group = 1,transform = function(mon) mon.ShowOnMap = true 
		mon.HP=mon.HP*2.5 
		mon.FullHP=mon.HP 
		mon.Attack1Type=0 
		mon.Attack1Missile = 0 
		mon.Hostile=true
		mon.SpellChance  =30 
		mon.SpellSkill= 1
		mon.TreasureItemPercent = 100 
		if bolsterLevel>25 then
			mon.Items[0].Number=174
		else
			mon.Items[0].Number=171
		end
		mon.Items[0].Charges=66
		end
		}
	mapvars.mawSpawn=true
end
