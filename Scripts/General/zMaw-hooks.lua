
do
	local function getSFTItem(p)
		local i = (p - Game.SFTBin.Frames["?ptr"]) / Game.SFTBin.Frames[0]["?size"]
		return Game.SFTBin.Frames[i]
	end

	-- cosmetic change: some monsters (mainly bosses) can be larger
	local scaleHook = function(indoor)
		return function(d)
			local t = {Scale = d.eax, Frame = getSFTItem(d.ebx)}
			t.MonsterIndex, t.Monster = internal.GetMonster(indoor and d.edi or (d.edi - 0x9A))
			events.call("MonsterSpriteScale", t)
			d.eax = t.Scale
		end
	end

	-- outdoor
	mem.autohook2(0x47AC26, scaleHook())
	mem.autohook2(0x47AC46, scaleHook())

	-- indoor
	mem.autohook2(0x43D02E, scaleHook(true))
	mem.autohook2(0x43D04D, scaleHook(true))
end
