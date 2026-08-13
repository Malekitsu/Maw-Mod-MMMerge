local function safeGet(get, p)
	if type(p) ~= "number" or p == 0 then
		return nil, nil
	end
	local ok, index, obj = pcall(get, p)
	if ok then
		return index, obj
	end
	return nil, nil
end

function MawRollDodge(mon, pl)
	if not mon or not pl then
		return nil
	end
	return CalcHitOrMiss(getMonsterLevel(mon), pl:GetSpeed())
end

local function rollHit(this, player)
	local _, mon = safeGet(internal.GetMonster, this)
	local _, pl = safeGet(internal.GetPlayer, player)
	return MawRollDodge(mon, pl)
end

mem.hookfunction(0x425893, 0, 2, function(d, def, this, player)
	local ok, hit = pcall(rollHit, this, player)
	if not ok or hit == nil then
		return def(this, player)
	end
	return hit and 1 or 0
end)
