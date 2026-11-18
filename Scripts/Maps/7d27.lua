
Game.MapEvtLines:RemoveEvent(376)
evt.map[376] = function()
	if not evt.ForPlayer("All").Cmp{"Inventory", 1463} and Mouse.Item.Number ~= 1463 then
		evt.ForPlayer(0).Add{"Inventory", 1463}
		evt.SetSprite{20, 1, "0"}
		evt.Add{"QBits", 752}
		evt.SetFacetBit{1, const.FacetBits.Untouchable, true}
		evt.SetFacetBit{1, const.FacetBits.Invisible, true}
	end
	evt.SpeakNPC{626}
end
