local u1, u2, u4, i1, i2, i4 = mem.u1, mem.u2, mem.u4, mem.i1, mem.i2, mem.i4
local hook, autohook, autohook2, asmpatch = mem.hook, mem.autohook, mem.autohook2, mem.asmpatch
local max, min, round, random = math.max, math.min, math.round, math.random
local format = string.format

local function getSFTItem(p)
	local i = (p - Game.SFTBin.Frames["?ptr"]) / Game.SFTBin.Frames[0]["?size"]
	return Game.SFTBin.Frames[i]
end

-- cosmetic change: some monsters (mainly bosses) can be larger
local scaleHook = function(d)
	local t = {Scale = d.eax, Frame = getSFTItem(d.ebx)}
	t.MonsterIndex, t.Monster = internal.GetMonster(d.edi - 0x9A)
	events.call("MonsterSpriteScale", t)
	d.eax = t.Scale
end

-- outdoor
autohook2(0x47AC26, scaleHook)
autohook2(0x47AC46, scaleHook)

-- indoor
autohook2(0x43D02E, scaleHook)
autohook2(0x43D04D, scaleHook)