local REMOTE_OWNER_BIT=0x800
-- moved to the MawCore damage pipeline: Scripts/Modules/MawCore/Damage.lua (DAMAGE_PIPELINE.md)
local aoespellsMultiplayer={6,9,22,41,97}
function events.CalcDamageToPlayer(t)
	local source = WhoHitPlayer()
	if source then
		local obj = source.Object
		if obj and bit.And(obj.Bits, REMOTE_OWNER_BIT) > 0 then
			if not table.find(aoespellsMultiplayer, source.Spell) then
				t.Result = 0
			end
		end
	end
end
-- moved to the MawCore damage pipeline: Scripts/Modules/MawCore/Damage.lua (DAMAGE_PIPELINE.md)

-- moved to the MawCore damage pipeline: Scripts/Modules/MawCore/Damage.lua (DAMAGE_PIPELINE.md)
