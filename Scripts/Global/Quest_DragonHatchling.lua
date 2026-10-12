
-- New NPC texts used: 1685, 1686, 1687, 1688

vars.Quest_DragonHatchling = vars.Quest_DragonHatchling or {}

local QSet = vars.Quest_DragonHatchling
local DragonNPC = 396

local FedText = "Yum! The dragon ate 5 food. Eaten so far: %d of 100."
local DaysLeftText = "Days left: %d."
local HungryText = "Grrr! The dragon needs 5 food, the party has less."
local ReleaseTopic = "Release the dragon"
local ReleaseAsk = "The dragon will fly away for good. Release him? (Y/N)"
local ReleasedText = "The dragon spread his wings and flew away."

-- Every string topic of slot 0 gets the same event (995), so when one of the dragon's topics
-- replaces another, UpdateNPCQuests sees no change and does not redraw the dialog: after naming,
-- the name was taken but the old "Dragon" button stayed and asked for the name again.
local function RefreshTopics()
	UpdateNPCQuests()
	Game.UpdateDialogTopics()
end

-- Refresh NPC's name.
function events.LoadMapScripts(WasInGame)
	if not WasInGame and QSet.NameChosen then
		Game.NPC[DragonNPC].Name = QSet.DragonName
	end
	if QSet.Released and Game.NPC[DragonNPC].Hired then
		NPCFollowers.Remove(DragonNPC)
	end
end

-- Make warlock promotion quest acessblie from both light and dark side.
evt.Global[852]:clear()
evt.Global[852] = function()
	if (Party.QBits[1613] or Party.QBits[1614]) then
		if Party.QBits[611] or Party.QBits[612] then
			Message(Game.NPCText[1161])
			evt.Set{"QBits", 567}
			evt.SetNPCTopic{390, 0, 853}
		else
			Message(Game.NPCText[1163])
		end
	else
		Message(Game.NPCText[1162])
	end
end

-- Same for Arch Druid promotion quest.
evt.Global[850]:clear()
evt.Global[850] = function()
	if (Party.QBits[1613] or Party.QBits[1614]) then
		if Party.QBits[611] or Party.QBits[612] then
			Message(Game.NPCText[1156])
			evt.Set{"QBits", 566}
			evt.SetNPCTopic{389, 1, 851}
		else
			Message(Game.NPCText[1157])
		end
	else
		Message(Game.NPCText[1157])
	end
end

-- A grown dragon who joined the party is an ordinary character and is dismissed like one, to the
-- Adventurer's Inn (NPCMercenaries.lua). That shows a mercenary only in the inns of the continent
-- he was dismissed on; the game's own characters, MM8's dragons among them, are seen in every inn,
-- and so is this one, being the only one of his kind. Runs after NPCMercenaries.lua's handler
-- (General scripts load before Global ones).
function events.ContinentChange3()
	local Id = QSet.DragonRosterId
	local Props = Id and vars.MercenariesProps and vars.MercenariesProps[Id]
	if vars.madnessMode or not Props or not Props.Hired or QSet.Released
		or Game.NPC[DragonNPC].Hired or evt.IsPlayerInParty(Id) then
		return
	end
	Party.QBits[400 + Id] = true
end

-- Create Dragon player upon first hiring.
local function MakeDragonChar()
	local cHave, cNPC, cRosterId = NPCFollowers.HaveFreeMerc()
	if cHave then
		local Char = Party.PlayersArray[cRosterId]
		local Face = Party.QBits[611] and 74 or 71
		QSet.DragonRosterId = cRosterId
		GenerateMercenary{RosterId = cRosterId, Class = 10, Level = 1, Items = {}, Face = Face, Skills = {[const.Skills.DragonAbility] = 1, [const.Skills.Learning] = 1}}
		Char.Name = Game.NPC[DragonNPC].Name
		Char.BirthYear = Game.Year - 1
		Char.Biography = Char.Name .. " - " .. Game.ClassNames[Char.Class]

		vars.MercenariesProps[cRosterId] = {LastRefill = 0, CurContinent = -1, Hired = true}
	end
	return cHave
end

-- Feed Dragon
NPCTopic{
	NPC = DragonNPC,
	Branch = "",
	Slot = 0,
	Topic = Game.NPCText[1692], -- "Feed dragon"
	CanShow = function()
		return not QSet.DragonGrown
	end,
	Ungive = function()
		if QSet.DragonGrown then
			Message(Game.NPCText[1684])
			return
		end

		QSet.FirstFeed = QSet.FirstFeed or Game.Time
		QSet.FoodEaten = QSet.FoodEaten or 0
		if QSet.FoodEaten >= 100 then
			if Game.Time - QSet.FirstFeed > const.Month then
				QSet.DragonGrown = true
				Game.NPC[DragonNPC].Pic = Game.CharacterPortraits[Party.QBits[611] and 74 or 71].NPCPic
				Message(Game.NPCText[1689]) -- "Dragon grown"
				RefreshTopics()
			else
				local DaysLeft = math.max(1, math.ceil((QSet.FirstFeed + const.Month - Game.Time) / const.Day))
				Message(Game.NPCText[1684] .. "\n" .. string.format(DaysLeftText, DaysLeft)) -- "Dragon ate enough"
			end
		elseif Party.Food >= 5 then
			Party.Food = Party.Food - 5
			QSet.FoodEaten = QSet.FoodEaten + 5
			evt.PlaySound{205} -- error sound
			Message(string.format(FedText, QSet.FoodEaten))
		else
			evt.PlaySound{27} -- error sound
			Message(HungryText)
		end
	end}

-- Choose Dragon's name.
NPCTopic{
	NPC = DragonNPC,
	Branch = "",
	Slot = 0,
	Topic = Game.NPCTopic[789],
	CanShow = function()
		return QSet.DragonGrown and not QSet.NameChosen
	end,
	Ungive = function()
		local Name = Question(Game.NPCText[1685])
		if Name and string.len(Name) > 0 then
			local Answer = Question(string.format(Game.NPCText[1686], Name))
			if string.lower(Answer) == "y" then
				Game.NPC[DragonNPC].Name = Name
				QSet.DragonName = Name
				QSet.NameChosen = true
			end
		end
		RefreshTopics()
	end}

-- Move Dragon to Party.
NPCTopic{
	NPC = DragonNPC,
	Branch = "",
	Slot = 0,
	Topic =  Game.NPCTopic[616],
	CanShow = function()
		return QSet.DragonGrown and QSet.NameChosen
	end,
	Ungive = function()
		if not QSet.DragonRosterId and not MakeDragonChar() then
			Message(Game.NPCText[1687])
			return
		end
		if Party.count >= 5 then
			Message(Game.NPCText[1688])
			return
		end
		HireCharacter(QSet.DragonRosterId)
		NPCFollowers.Remove(DragonNPC)
		Sleep(100, 100)
		if Game.CurrentScreen == 4 then
			ExitCurrentScreen()
		end
	end}

-- Release the dragon for good: he has no profession, so NPCFollowers.lua gives him no dismiss topic.
NPCTopic{
	NPC = DragonNPC,
	Branch = "",
	Slot = 1,
	Topic = ReleaseTopic,
	CanShow = function()
		return Game.NPC[DragonNPC].Hired
	end,
	Ungive = function()
		if string.lower(Question(ReleaseAsk) or "") ~= "y" then
			return
		end
		QSet.Released = true
		NPCFollowers.Remove(DragonNPC)
		Game.ShowStatusText(ReleasedText)
		Sleep(100, 100)
		if Game.CurrentScreen == 4 then
			ExitCurrentScreen()
		end
	end}

-- Restore the original functionality of the dragon familiar as long as
-- he's sitting in the hireling slot.

function events.GetSkill(t)
    if  Game.NPC[DragonNPC].Hired
		and Game.ClassesExtra[t.Player.Class].Kind == 5 -- Druid class line
        and const.Skills.Fire <= t.Skill
        and t.Skill < const.Skills.Light
    then
        local s, m = SplitSkill(t.Result)
        t.Result = JoinSkill(s + 3, m)
    end
end

function events.RegenTick(Player)
    if Game.NPC[DragonNPC].Hired
		and Game.ClassesExtra[Player.Class].Kind == 5 -- Druid class line
    then
        Player.SP = math.min(Player:GetFullSP(), Player.SP + 1)
    end
end

