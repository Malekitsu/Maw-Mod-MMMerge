-- zzzzzMaw_Damage.lua -- per-playthrough registration of the MawCore damage
-- pipeline. Lives in Global/ so this handler re-registers on every save load,
-- appending after every other Global handler: the pipeline must always run
-- last among mod handlers (map scripts register later still and run after
-- it). The stages live in Scripts/Modules/MawCore/Damage.lua.

function events.CalcDamageToMonster(t)
	MawCore.Damage.run(t)
end

function events.CalcDamageToPlayer(t)
	MawCore.Damage.runPlayer(t)
end
