-- SpecialItems.lua -- what shops do with quest and "special" items.
--
-- The merge refuses every item with Value 0 or Material 3 ("special") for
-- every shop service (RemoveItemsLimits.lua; vanilla MM8 refused item
-- numbers 538-599 and 600+). That keeps quest items out of shops, but it also
-- means no shop will identify or repair them -- Eclipse (an artifact at
-- Value 0, identify difficulty 20) can never be identified -- and the
-- refusal is the "Unnecessary" sentence ("You already know what that is").
--
-- Here: identify and repair always. Sell when the item has a price and no
-- quest needs it any more. Items that are only rewards sell at once; a
-- quest-bound one when its quest is done. For the promotion items those are
-- the bits Classes/zzClasses promote characters hired later by, so the item
-- is not needed for that either. Junk with Value 0 that drops in numbers
-- (Endless Potion, Whisp wrappings) gets a nominal price. Items without a
-- price (keys, letters, the Wetsuit and the Cloak of Baa, which open maps,
-- the blasters) still do not sell.
--
-- Unique items that the game can hand out again sell once per game: the MM8
-- seer returns Ebonest/Whistlebone/Balthazar while their "lost it" bit is set
-- and nobody carries one (table at 0x500C68 of mm8.exe, sub_4B069E), and the
-- merge's "I lost it" topic (StdQuestsFunctions.lua) returns any item it
-- registered, once per map load. With a price on them either would print
-- money; after the first sale the number is refused, and its re-issue
-- sources are cleared.

local SpecialItems = {}
MawCore.SpecialItems = SpecialItems

local SELL, IDENTIFY, REPAIR = 3, 4, 5

-- item -> the quest bits, awards or MMExtension quests (vars.Quests[name] ==
-- "Done") of which any one means "done"
SpecialItems.QuestBound = {
	[516] = {QBits = {128}},					-- Eclipse: Lathius, Ravenshore
	[539] = {QBits = {1540, 1541}},				-- Ebonest: Champion (Charles Quixote)
	[540] = {QBits = {1543, 1544}},				-- Sword of Whistlebone: Great Wyrm (Deftclaw Redreaver)
	[541] = {QBits = {1545}, Awards = {29}},	-- Axe of Balthazar: Minotaur Lord
	[1342] = {QBits = {1564, 1565}},			-- Lady Carmine's Dagger: Assassin
	[1344] = {QBits = {1586, 1587, 1588, 1589}},	-- The Perfect Bow (unrepaired): Master Archer / Sniper
	[2118] = {Awards = {79}},					-- Snergle's Axe: Avinril Smythers
	[2119] = {Awards = {57}},					-- Lord Kilburn's Shield: Wilbur Humphrey
	[665] = {Quests = {"SG_WispWrappings"}},	-- Whisp wrappings: Verdant (Quest_SavingGoobers.lua) takes one
}

-- items whose Value is 0 in the table
SpecialItems.Prices = {
	[516] = 20000,	-- Eclipse, as the other artifacts
	[539] = 20000,	-- as Wyrm Spitter, Gibbet
	[540] = 20000,	-- as Iron Feather (4d5 two-handed sword)
	[541] = 20000,	-- as Conan (3d7 two-handed axe)
	[665] = 10,		-- Whisp wrappings: the dungeon drops dozens, the quest takes one
	[1069] = 10,	-- Endless Potion: nominal value to sell unwanted drops
	[1439] = 2500,	-- Winged Sandals: no script uses them
	[2118] = 2500,
	[2119] = 2500,
	[2199] = 2500,	-- Fire Amulet: no script uses it
}

-- sold at most once per game, and how the game could hand them out again
SpecialItems.SellOnce = {
	[516] = {}, [539] = {SeerBit = 199}, [540] = {SeerBit = 200}, [541] = {SeerBit = 201},
	[1439] = {}, [2118] = {}, [2119] = {}, [2199] = {},
}

-- merchant answers for quest-bound and already-sold items; %24 = item name
SpecialItems.Text = {
	AlreadySold = "I have already bought an item like that.",
	QuestItem = "No, no -- you will still need that %24. Come back once the task it is for is done.",
}

function SpecialItems.questDone(number)
	local q = SpecialItems.QuestBound[number]
	if not q then
		return true
	end
	for _, b in ipairs(q.QBits or {}) do
		if Party.QBits[b] then
			return true
		end
	end
	for _, a in ipairs(q.Awards or {}) do
		for _, pl in Party do
			if pl.Awards[a] then
				return true
			end
		end
	end
	for _, name in ipairs(q.Quests or {}) do
		if vars.Quests and vars.Quests[name] == "Done" then
			return true
		end
	end
	return false
end

local function soldOnce()
	local d = MawCore.Save.data()
	d.soldUnique = d.soldUnique or {}
	return d.soldUnique
end

-- MerchantTxt[1][5]: the Sell column, "Unnecessary" row
local unnecessary, shownReason

local function setSellRefusal(reason)
	if reason == shownReason then
		return
	end
	local col = Game.MerchantTxt[1]
	if not shownReason then
		unnecessary = col[5]
	end
	col[5] = reason and SpecialItems.Text[reason] or unnecessary
	shownReason = reason
end

-- true refuses; see Engine.setShopItemFilter
function SpecialItems.refuses(item, action, forText)
	if action == IDENTIFY or action == REPAIR then
		return false
	end
	local n = item.Number
	local txt = Game.ItemsTxt[n]
	local refuse, reason = txt.Value == 0, false
	if action == SELL and not refuse then
		if SpecialItems.SellOnce[n] and soldOnce()[n] then
			refuse = true
			reason = "AlreadySold"
		elseif txt.Material == 3 or SpecialItems.QuestBound[n] then
			refuse = not SpecialItems.questDone(n)
			reason = refuse and "QuestItem" or false
		end
	end
	if forText and action == SELL then
		setSellRefusal(reason)
	end
	return refuse
end

function SpecialItems.sold(item)
	local n = item.Number
	local once = SpecialItems.SellOnce[n]
	if once then
		soldOnce()[n] = true
		if once.SeerBit then
			Party.QBits[once.SeerBit] = false
		end
	end
	-- a sold item is not "lost": without this the topic would hand out a new
	-- one on the next map load (Whisp wrappings were registered while their
	-- Value was 0). Continent 0 never matches, so the topic does not return
	-- it, while the entry still counts as "the party had it" (outb2.lua
	-- refills Kilburn's chest until then) and keeps GotItem from registering
	-- it again
	if vars.LostItems and (once or vars.LostItems[n]) then
		vars.LostItems[n] = 0
	end
end

-- the merge registers an item for its "I lost it" topic only while its Value
-- is 0 (IsQuestItem in StdQuestsFunctions.lua); ours now have a price, so
-- register them the same way, by the merge's number ranges
local function lostItContinent(i)
	if (i > 600 and i < 635) or i == 663 then
		return 1
	elseif (i > 1401 and i < 1488) or i == 664 then
		return 2
	elseif (i > 2066 and i < 2200) or i == 665 then
		return 3
	end
end

function SpecialItems.start()
	-- not at load time: the merge writes its own test into the same sites
	-- when the engine loads the item tables (ExtraItemsInShops in
	-- RemoveItemsLimits.lua), which would overwrite ours
	function events.GameInitialized2()
		MawCore.Engine.setShopItemFilter(SpecialItems.refuses, SpecialItems.sold)
		for number, value in pairs(SpecialItems.Prices) do
			if Game.ItemsTxt[number].Value == 0 then
				Game.ItemsTxt[number].Value = value
			end
		end
	end
	function events.GotItem(i)
		local cont = SpecialItems.Prices[i] and lostItContinent(i)
		if cont and vars.LostItems and not vars.LostItems[i] then
			vars.LostItems[i] = cont
		end
	end
end
