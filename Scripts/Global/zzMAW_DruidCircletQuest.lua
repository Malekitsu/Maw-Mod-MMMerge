-- A use for the Druid Circlet of Power (item 638). It lies in chest 3 of the Druid Circle
-- (d23) since MM8 itself, but no quest ever asked for it.
--
-- Giver: Dantillion (NPC 41), Cleric of the Sun in Murmurwoods, slot B (his slot A holds
-- the Cauri Blackthorne topics). Quest bit 299, empty in Quests.txt.

local rewarding

function events.ItemGenerated(t)
	if rewarding then
		t.Item.Identified = true
	end
end

local function reward()
	-- through the generator, so MAW rolls rarity and enchantments; lands on the mouse cursor
	rewarding = true
	local ok, err = pcall(evt.GiveItem, {Strength = 5, Type = const.ItemType.Amulet, Id = 0})
	rewarding = nil
	assert(ok, err)
end

Quest{
	"DruidCircletQuest",
	NPC = 41,
	Slot = 1,
	Quest = 299,
	QuestItem = 638,
	Gold = 3000,
	Exp = 10000,
	Done = reward,
}.SetTexts{
	Topic = "Druid Circlet",
	Give = "The pilgrims bound for the Druid Circle were seeking more than old stones. It is said the druids of the Ancients left a relic there, the Druid Circlet of Power. The Temple of the Sun wishes to keep it safe before it falls into the wrong hands. The Circle lies to the northeast of here. If you find the circlet, bring it to me, and the Temple will reward you.",
	Undone = "You do not have the circlet. The Druid Circle lies to the northeast of here; look for it there.",
	Done = "The Druid Circlet of Power! How many pilgrims gave their lives just to set eyes on it... The Temple of the Sun will keep it safe. Accept the Temple's gratitude, and this amulet.",
	After = "The circlet is in safe hands. The Temple of the Sun will not forget your help.",
	Quest = "Find the Druid Circlet of Power in the Druid Circle and bring it to Dantillion in Murmurwoods.",
}
