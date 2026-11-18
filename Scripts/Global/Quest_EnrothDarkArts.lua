
-- Allow some classes to swap their alligment at Enroth:
-- Priest of Light to Priest of Dark; Archmage to Dark Archmage (new class); Hero to Villain, Master Archer to Sniper.

----------------------
---- LOCALIZATION ----

local TXT = {

PathOfLight = Game.NPCText[2102], --"Path of Light",
PathOfDark  = Game.NPCText[2103], --"Path of Dark",

WarningLight = Game.NPCText[2104], --"Are you sure, you want to change your path? Dark spells will be vanished from your spellbook and dark magic will be erased from your mind. (Yes/No)",
WarningDark  = Game.NPCText[2105], --"Are you sure, you want to change your path? Light spells will be vanished from your spellbook and light magic will be erased from your mind. (Yes/No)",

AdvertLight = Game.NPCText[2106], --"It is never late to turn back to light, child. Choose light side.",
AdvertDark  = Game.NPCText[2107], --"Darkness wait and it's patience is eternal. Choose dark side.",

Yes = Game.NPCText[2108], --"yes",

Std = Game.NPCText[2109] --"Either you've already choosen your path, or you are not ready to do it."

}
---- LOCALIZATION ----
----------------------

local LastClick = 0

local DarkPromTable = {
	[51] = 47,
	[50] = 7,
	[46] = 47,
	[28] = 29,
	[15] = 14,
	[6] = 7,
	[2] = 3
}

local LightPromTable = {
	[51] = 46,
	[50] = 6,
	[47] = 46,
	[29] = 28,
	[14] = 15,
	[7] = 6,
	[3] = 2
}

local function SwapAllignmentDark()

	local CurPl = math.max(Game.CurrentPlayer, 0)
	local v = Party[CurPl]
	local PromClass = DarkPromTable[v.Class]

	if PromClass and LastClick + 2 > os.time() then
		local Answer = Question(TXT.WarningDark)

		if string.lower(Answer) == TXT.Yes then
			v.Skills[const.Skills.Dark] = math.max(v.Skills[const.Skills.Dark], v.Skills[const.Skills.Light])
			v.Skills[const.Skills.Light] = 0
			for i = 78, 88 do
				v.Spells[i] = false
			end

			v.Class = PromClass
			evt[CurPl].Add{"Experience", 0}
			v:ShowFaceAnimation(71)
		else
			v:ShowFaceAnimation(67)
		end
	else
		if PromClass then
			Message(TXT.AdvertDark)
		else
			Message(TXT.Std)
		end
	end
	LastClick = os.time()

end

local function SwapAllignmentLight()

	local CurPl = math.max(Game.CurrentPlayer, 0)
	local v = Party[CurPl]
	local PromClass = LightPromTable[v.Class]

	if PromClass and LastClick + 2 > os.time() then
		local Answer = Question(TXT.WarningLight)

		if string.lower(Answer) == TXT.Yes then
			v.Skills[const.Skills.Light] = math.max(v.Skills[const.Skills.Dark], v.Skills[const.Skills.Light])
			v.Skills[const.Skills.Dark] = 0
			for i = 89, 99 do
				v.Spells[i] = false
			end

			v.Class = PromClass
			evt[CurPl].Add{"Experience", 0}
			v:ShowFaceAnimation(71)
		else
			v:ShowFaceAnimation(67)
		end
	else
		if PromClass then
			Message(TXT.AdvertLight)
		else
			Message(TXT.Std)
		end

	end
	LastClick = os.time()

end

-- Path of Dark topic

NPCTopic{
	Topic = TXT.PathOfDark,
	NPC = 1040,
	Slot = 4,
	Branch = "",
	Ungive = SwapAllignmentDark
}

NPCTopic{
	Topic = TXT.PathOfDark,
	NPC = 1030,
	Slot = 4,
	Branch = "",
	Ungive = SwapAllignmentDark
}

-- Path of Light topic

NPCTopic{
	Topic = TXT.PathOfLight,
	NPC = 1057,
	Slot = 4,
	Branch = "",
	Ungive = SwapAllignmentLight
}

NPCTopic{
	Topic = TXT.PathOfLight,
	NPC = 1031,
	Slot = 4,
	Branch = "",
	Ungive = SwapAllignmentLight
}

NPCTopic{
	Topic = TXT.PathOfLight,
	NPC = 795,
	Slot = 4,
	Branch = "",
	Ungive = SwapAllignmentLight
}
