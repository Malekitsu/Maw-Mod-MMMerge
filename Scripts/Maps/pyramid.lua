-- VARN codes.

Game.MapEvtLines:RemoveEvent(1)
evt.hint[1] = evt.str[21]
evt.Map[1] = function()
	evt.Set{"MapVar0", 0}
	if evt.Cmp{"Inventory", 2157} then
		if evt.Cmp{"MapVar27", 1} then
			local Answer = string.lower(Question(evt.str[44]))
			if Answer == string.lower(evt.str[43]) then
				evt.Set{"MapVar15", 1}
				evt.Subtract{"Inventory", 2157}
				evt.Subtract{"QBits", 1255}
				evt.SetDoorState{1, 1}
				Game.ShowStatusText(evt.str[15])
			else
				Game.ShowStatusText(evt.str[45])
				evt.Subtract{"HP", 5}
				evt.FaceExpression{"Current", 44}
			end
		else
			Game.ShowStatusText(evt.str[46])
			evt.Subtract{"HP", 25}
			evt.FaceExpression{"Current", 35}
		end
	end
end

local function SetCode(ItemId, CodeId, TextId, QuestionId, AnswerId, QBit, FaceExpr)
	evt.Set{"MapVar0", 0}
	if evt.Cmp{"Inventory", ItemId} then
		local Answer = string.lower(Question(evt.str[TextId]))
		if Answer == string.lower(evt.str[AnswerId]) then
			evt.Set{"MapVar" .. CodeId, 1}
			local AllVars = true
			for i = 10, 14 do
				if not evt.Cmp{"MapVar" .. i, 1} then
					AllVars = false
					break
				end
			end

			if AllVars then
				evt.Set{"MapVar27", 1}
			end

			evt.ForPlayer("All").Subtract{"Inventory", ItemId}
			evt.Subtract{"QBits", QBit}

		else
			Game.ShowStatusText(evt.str[45])
			evt.FaceExpression{"Current", FaceExpr}
			evt.Subtract{"HP", 5}

		end
	end
end

Game.MapEvtLines:RemoveEvent(21)
evt.hint[21] = evt.str[26]
evt.Map[21] = function() SetCode(2158, 10, 32, 44, 33, 1253, 48) end

Game.MapEvtLines:RemoveEvent(22)
evt.hint[22] = evt.str[26]
evt.Map[22] = function() SetCode(2159, 11, 34, 44, 35, 1256, 33) end

Game.MapEvtLines:RemoveEvent(23)
evt.hint[23] = evt.str[26]
evt.Map[23] = function() SetCode(2160, 12, 36, 44, 37, 1258, 50) end

Game.MapEvtLines:RemoveEvent(24)
evt.hint[24] = evt.str[26]
evt.Map[24] = function() SetCode(2161, 13, 38, 44, 39, 1257, 46) end

Game.MapEvtLines:RemoveEvent(25)
evt.hint[25] = evt.str[26]
evt.Map[25] = function() SetCode(2162, 14, 40, 44, 41, 1254, 13) end

Game.MapEvtLines:RemoveEvent(12)
evt.map[12] = function()  -- Timer(<function>, 1.5*const.Minute)
	local i
	if evt.Cmp{"MapVar0", Value = 1} then
		if evt.Cmp{"Inventory", Value = 2086} then         -- "Crystal Skull"
			evt.StatusText{Str = 18}         -- "Crystal Skull absorbs radiation damage."
		else
			i = Game.Rand() % 6
			if i == 1 then
				evt.DamagePlayer{Player = "All", DamageType = const.Damage.Phys, Damage = 5}
				evt.StatusText{Str = 4}         -- "Radiation Damage!"
			elseif i == 2 then
				evt.DamagePlayer{Player = "All", DamageType = const.Damage.Water, Damage = 5}
				evt.StatusText{Str = 10}         -- "Radiation Damage!"
			elseif i == 3 then
				evt.DamagePlayer{Player = "All", DamageType = const.Damage.Earth, Damage = 5}
				evt.StatusText{Str = 13}         -- "Radiation Damage!"
			elseif i == 4 then
				evt.DamagePlayer{Player = "All", DamageType = const.Damage.Air, Damage = 5}
				evt.StatusText{Str = 14}         -- "Radiation Damage!"
			elseif i == 5 then
				evt.DamagePlayer{Player = "All", DamageType = const.Damage.Fire, Damage = 5}
				evt.StatusText{Str = 13}         -- "Radiation Damage!"
			else
				evt.DamagePlayer{Player = "All", DamageType = const.Damage.Body, Damage = 5}
				evt.StatusText{Str = 10}         -- "Radiation Damage!"
			end
		end
	end
end

Timer(evt.map[12].last, 1.5*const.Minute)