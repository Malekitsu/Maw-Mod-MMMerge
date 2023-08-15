------------------------------
--RESTORE MM6 sprites
------------------------------
function events.AfterLoadMap()	
	if Map.MapStatsIndex>=137 and Map.MapStatsIndex<=203 then
		for i=0, Map.Sprites.High do
			--ROCKS
			if Map.Sprites[i].DecName=="rock01" then
				Map.Sprites[i].DecName="Rok1"
			elseif Map.Sprites[i].DecName=="rock02" then
				Map.Sprites[i].DecName="Rok2"
			elseif Map.Sprites[i].DecName=="rock03" then
				Map.Sprites[i].DecName="Rok3"
			elseif Map.Sprites[i].DecName=="rock04" then
				Map.Sprites[i].DecName="Rok4"
			elseif Map.Sprites[i].DecName=="rock05" then
				Map.Sprites[i].DecName="Rok5"
			elseif Map.Sprites[i].DecName=="rock06" then
				Map.Sprites[i].DecName="Rok6"
			elseif Map.Sprites[i].DecName=="rock07" then
				Map.Sprites[i].DecName="Rok7"
			elseif Map.Sprites[i].DecName=="rock08" then
				Map.Sprites[i].DecName="Rok8"
			elseif Map.Sprites[i].DecName=="rock09" then
				Map.Sprites[i].DecName="Rok9"
			elseif Map.Sprites[i].DecName=="rock10" then
				Map.Sprites[i].DecName="Rok1"
			elseif Map.Sprites[i].DecName=="rock11" then
				Map.Sprites[i].DecName="Rok1"
			elseif Map.Sprites[i].DecName=="rock12" then
				Map.Sprites[i].DecName="Rok1"
			elseif Map.Sprites[i].DecName=="rock13" then
				Map.Sprites[i].DecName="Rok1"
			elseif Map.Sprites[i].DecName=="rock14" then
				Map.Sprites[i].DecName="Rok1"
			--FLOWERS
			elseif Map.Sprites[i].DecName=="flower01" then
				Map.Sprites[i].DecName="6Flower01"
			elseif Map.Sprites[i].DecName=="flower02" then
				Map.Sprites[i].DecName="6Flower02"
			elseif Map.Sprites[i].DecName=="flower03" then
				Map.Sprites[i].DecName="6Flower03"
			elseif Map.Sprites[i].DecName=="flower04" then
				Map.Sprites[i].DecName="6Flower04"
			elseif Map.Sprites[i].DecName=="flower05" then
				Map.Sprites[i].DecName="6Flower05"
			elseif Map.Sprites[i].DecName=="flower06" then
				Map.Sprites[i].DecName="6Flower06"
			elseif Map.Sprites[i].DecName=="flower07" then
				Map.Sprites[i].DecName="6Flower07"
			elseif Map.Sprites[i].DecName=="flower08" then
				Map.Sprites[i].DecName="6Flower08"
			elseif Map.Sprites[i].DecName=="flower09" then
				Map.Sprites[i].DecName="6Flower09"
			elseif Map.Sprites[i].DecName=="flower10" then
				Map.Sprites[i].DecName="6Flower10"
			elseif Map.Sprites[i].DecName=="flower11" then
				Map.Sprites[i].DecName="6Flower11"
			elseif Map.Sprites[i].DecName=="flower12" then
				Map.Sprites[i].DecName="6Flower12"
			elseif Map.Sprites[i].DecName=="flower13" then
				Map.Sprites[i].DecName="6Flower13"
			--CORPSES
			elseif Map.Sprites[i].DecName=="Corpse" then
				Map.Sprites[i].DecName="Corpse01"
			elseif Map.Sprites[i].DecName=="Corpse01" then
				Map.Sprites[i].DecName="Corpse02"
			elseif Map.Sprites[i].DecName=="Corpse02" then
				Map.Sprites[i].DecName="Corpse03"
			elseif Map.Sprites[i].DecName=="Corpse03" then
				Map.Sprites[i].DecName="Corpse04"
			elseif Map.Sprites[i].DecName=="Corpse04" then
				Map.Sprites[i].DecName="Corpse05"
			elseif Map.Sprites[i].DecName=="Corpse05" then
				Map.Sprites[i].DecName="Corpse06"
			elseif Map.Sprites[i].DecName=="Corpse06" then
				Map.Sprites[i].DecName="Corpse07"
			elseif Map.Sprites[i].DecName=="Corpse07" then
				Map.Sprites[i].DecName="Corpse08"
			elseif Map.Sprites[i].DecName=="Corpse08" then
				Map.Sprites[i].DecName="Corpse09"
			elseif Map.Sprites[i].DecName=="Corpse09" then
				Map.Sprites[i].DecName="Corpse10"
			elseif Map.Sprites[i].DecName=="Corpse10" then
				Map.Sprites[i].DecName="Corpse11"
			elseif Map.Sprites[i].DecName=="Corpse11" then
				Map.Sprites[i].DecName="Corpse12"
			elseif Map.Sprites[i].DecName=="Corpse12" then
				Map.Sprites[i].DecName="Corpse13"
			elseif Map.Sprites[i].DecName=="Corpse13" then
				Map.Sprites[i].DecName="Corpse14"
			elseif Map.Sprites[i].DecName=="Corpse14" then
				Map.Sprites[i].DecName="Corpse15"
			elseif Map.Sprites[i].DecName=="Corpse15" then
				Map.Sprites[i].DecName="Corpse16"
			elseif Map.Sprites[i].DecName=="Corpse16" then
				Map.Sprites[i].DecName="Corpse17"
			elseif Map.Sprites[i].DecName=="Corpse17" then
				Map.Sprites[i].DecName="Corpse18"
			elseif Map.Sprites[i].DecName=="Corpse18" then
				Map.Sprites[i].DecName="Corpse19"
			elseif Map.Sprites[i].DecName=="Corpse19" then
				Map.Sprites[i].DecName="Corpse20"
			end
		end
	end
end
