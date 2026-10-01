-- SpecialItems.lua -- what shops do with quest and "special" items.
--
-- The merge refuses every item with Value 0 or Material 3 ("special") for
-- every shop service (RemoveItemsLimits.lua; vanilla MM8 refused item
-- numbers 538-599 and 600+). That keeps quest items out of shops, but it also
-- means no shop will identify or repair them -- Eclipse (an artifact at
-- Value 0, identify difficulty 20) or the Noblebone Bow (special, 30) can
-- never be identified unless someone in the party can -- and the refusal is
-- the "Unnecessary" sentence ("You already know what that is") although the
-- item is not identified.
--
-- Here: identify and repair always; selling stays as the merge has it.

local SpecialItems = {}
MawCore.SpecialItems = SpecialItems

local IDENTIFY, REPAIR = 4, 5

-- true refuses; see Engine.setShopItemFilter
function SpecialItems.refuses(item, action, forText)
	if action == IDENTIFY or action == REPAIR then
		return false
	end
	local txt = Game.ItemsTxt[item.Number]
	return txt.Value == 0 or txt.Material == 3
end

function SpecialItems.start()
	-- not at load time: the merge writes its own test into the same sites
	-- when the engine loads the item tables (ExtraItemsInShops in
	-- RemoveItemsLimits.lua), which would overwrite ours
	function events.GameInitialized2()
		MawCore.Engine.setShopItemFilter(SpecialItems.refuses)
	end
end
