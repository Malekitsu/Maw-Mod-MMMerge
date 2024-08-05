Game.MapEvtLines:RemoveEvent(131)
evt.hint[131] = evt.str[100]  -- ""
evt.map[131] = function()
	if not vars.sarcophagus then         -- Found the Sarcophagus of Korbu
		evt.SetFacetBit{Id = 10, Bit = const.FacetBits.Invisible, On = true}
		evt.SetFacetBit{Id = 10, Bit = const.FacetBits.Untouchable, On = true}
		evt.Add{"Inventory", Value = 612}         -- "Sarcophagus of Korbu"
		evt.Set{"MapVar9", Value = 1}
		evt.Add{"QBits", Value = 211}         -- Sarcophagus of Korbu - I lost it
		vars.sarcophagus=true
	end
end
