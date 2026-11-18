
GroundTex = "gdtyl"
GroundTex = Game.BitmapsLod:LoadBitmap(GroundTex)
Game.BitmapsLod.Bitmaps[GroundTex]:LoadBitmapPalette()

LocalFile(Game.TileBin)
for i = 1, 12 do
	if string.sub(Game.TileBin[i].Name, 1, 4) == "dirt" then
		Game.TileBin[i].Bitmap = GroundTex
	end
end

local TileSounds = {
[5] = {[0] = 101, 	[1] = 62}
}

function events.TileSound(t)
	local Grp = TileSounds[Game.CurrentTileBin[Map.TileMap[t.X][t.Y]].TileSet]
	if Grp then
		t.Sound = Grp[t.Run]
	end
end
