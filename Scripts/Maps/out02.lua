
-- Multiplayer support

if Multiplayer then

	function events.MultiplayerUserdataArrived(t)
		if Multiplayer.utils.distance(t, Party) < Multiplayer.SHARE_BUFF_RANGE then
			local QSet = vars.Quest_CrossContinents
			evt.MoveToMap{0,0,0,0,0,0,0,0, QSet.QuestFinished and "Breach.odm" or "BrAlvar.odm"}
		end
	end

end

-- Final part of Cross continents quest

local function InBreachRange()
	local QSet = vars.Quest_CrossContinents
	return QSet and QSet.GotFinalQuest and 600 > math.sqrt((15103-Party.X)^2 + (-9759-Party.Y)^2)
end

function events.TileSound(t)
	if InBreachRange() then
		TownPortalControls.DimDoorEvent()
	end
end

function events.CanCastTownPortal(t)
	if InBreachRange() then
		local QSet = vars.Quest_CrossContinents
		t.CanCast = false
		evt.MoveToMap{0,0,0,0,0,0,0,0, QSet.QuestFinished and "Breach.odm" or "BrAlvar.odm"}

		-- Multiplayer
		Multiplayer.broadcast_mapdata({X = Party.X, Y = Party.Y, Z = Party.Z})
	end
end

function events.LoadMap()
	if vars.Quest_CrossContinents and Party.QBits[56] then
		vars.Quest_CrossContinents.ContinentFinished[1] = true
	end
end

-- Allow entering crystal without conflux key, if it was opened at least once before
Game.MapEvtLines:RemoveEvent(504)
evt.map[504] = function()
	evt.ForPlayer("All")
	if mapvars.CrystalOpened or evt.Cmp("Inventory", 610) then -- "Conflux Key"
		mapvars.CrystalOpened = true
		evt.MoveToMap{X = -1024, Y = -1626, Z = 0, Direction = 520, LookAngle = 0, SpeedZ = 0, HouseId = 355, Icon = 1, Name = "D10.blv"} -- "Inside the Crystal"
	else
		evt.FaceAnimation{Player = "Current", Animation = 18}
	end
end

evt.hint[2666]="Enroth"
evt.map[2666] = function()
	evt.MoveToMap{-9729, -10555, 160, 512, 0, 0, 0, 3, "oute3.odm"}
end

evt.hint[1777]="Antagarich"
evt.map[1777] = function()
	if evt.Cmp{"QBits", Value = 527} then
		evt.MoveToMap{-16832, 12512, 372, 0, 0, 0, 0, 3, "7out02.odm"}
	else
		evt.MoveToMap{12552, 800, 193, 512, 0, 0, 0, 3, "7out01.odm"}
	end
end
