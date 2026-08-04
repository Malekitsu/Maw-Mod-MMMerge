-- zzzzzMaw_Damage.lua -- per-playthrough registration of the MawCore damage
-- pipeline (DAMAGE_PIPELINE.md). Lives in Global/ so this handler re-registers
-- on every save load, appending AFTER every remaining legacy Global handler:
-- the pipeline must always run last among mod handlers (map scripts register
-- later still and keep running after it, exactly as before the migration).
-- The stages live in Scripts/Modules/MawCore/Damage.lua.

function events.CalcDamageToMonster(t)
	MawCore.Damage.run(t)
end
