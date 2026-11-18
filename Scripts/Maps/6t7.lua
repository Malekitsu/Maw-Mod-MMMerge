
Game.MapEvtLines:RemoveEvent(1)
evt.hint[1] = evt.str[1]  -- "Door"
evt.map[1] = function()
	evt.ForPlayer("Current")
	if evt.CheckSkill{const.Skills.Perception, Mastery = const.Novice, Level = 8} then
		evt.SetDoorState{Id = 1, State = 1}
	else
		evt.DamagePlayer{Player = "Current", DamageType = const.Damage.Fire, Damage = 50}
	end
end
