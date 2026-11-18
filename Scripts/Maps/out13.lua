
-- Allow firing cannon of dominion again, if cannon ball present in inventory
-- evt 451 and 452 taken from https://gitlab.com/GrayFace/mmext-scripts/-/blob/master/Decompiled%20Scripts/mm8/Out13.lua

local function FireCannonEffect1()

	if Multiplayer and Multiplayer.in_game then
		Multiplayer.AllowNextEvtCastSpell()
	end

	evt.CastSpell{Spell = 6, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -13371, ToY = 13740, ToZ = 2793}         -- "Fireball"
	evt.CastSpell{Spell = 6, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -13600, ToY = 13740, ToZ = 2793}         -- "Fireball"
	evt.CastSpell{Spell = 6, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -13250, ToY = 13740, ToZ = 2793}         -- "Fireball"
	evt.CastSpell{Spell = 6, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -13371, ToY = 13600, ToZ = 2793}         -- "Fireball"
	evt.CastSpell{Spell = 6, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -13371, ToY = 13820, ToZ = 3000}         -- "Fireball"
	evt.CastSpell{Spell = 6, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -13371, ToY = 13740, ToZ = 2250}         -- "Fireball"
	evt.CastSpell{Spell = 6, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -13371, ToY = 13800, ToZ = 2500}         -- "Fireball"
	evt.CastSpell{Spell = 6, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -13100, ToY = 13740, ToZ = 3000}         -- "Fireball"
end

local function FireCannonEffect2()

	if Multiplayer and Multiplayer.in_game then
		Multiplayer.AllowNextEvtCastSpell()
	end

	evt.CastSpell{Spell = 9, Mastery = const.GM, Skill = 3, FromX = -19692, FromY = 14204, FromZ = 4000, ToX = -19692, ToY = 14204, ToZ = 0}         -- "Meteor Shower"
	evt.CastSpell{Spell = 9, Mastery = const.GM, Skill = 3, FromX = -16984, FromY = 15783, FromZ = 4000, ToX = -16984, ToY = 15783, ToZ = 0}         -- "Meteor Shower"
	evt.CastSpell{Spell = 9, Mastery = const.GM, Skill = 3, FromX = -12333, FromY = 18364, FromZ = 4000, ToX = -12333, ToY = 18364, ToZ = 0}         -- "Meteor Shower"
	evt.CastSpell{Spell = 9, Mastery = const.GM, Skill = 3, FromX = -13102, FromY = 20346, FromZ = 4000, ToX = -13102, ToY = 20346, ToZ = 0}         -- "Meteor Shower"
	evt.CastSpell{Spell = 9, Mastery = const.GM, Skill = 3, FromX = -15489, FromY = 18406, FromZ = 4000, ToX = -15489, ToY = 18406, ToZ = 0}         -- "Meteor Shower"
	evt.CastSpell{Spell = 9, Mastery = const.GM, Skill = 3, FromX = -19300, FromY = 18374, FromZ = 4000, ToX = -19300, ToY = 18374, ToZ = 0}         -- "Meteor Shower"
	evt.CastSpell{Spell = 9, Mastery = const.GM, Skill = 3, FromX = -17229, FromY = 20297, FromZ = 4000, ToX = -17229, ToY = 20297, ToZ = 0}         -- "Meteor Shower"
	evt.CastSpell{Spell = 9, Mastery = const.GM, Skill = 3, FromX = -13235, FromY = 20616, FromZ = 4000, ToX = -13235, ToY = 20616, ToZ = 0}         -- "Meteor Shower"
	evt.CastSpell{Spell = 9, Mastery = const.GM, Skill = 3, FromX = -16787, FromY = 13839, FromZ = 4000, ToX = -16787, ToY = 13839, ToZ = 0}         -- "Meteor Shower"
	evt.CastSpell{Spell = 9, Mastery = const.GM, Skill = 3, FromX = -12748, FromY = 14383, FromZ = 4000, ToX = -12748, ToY = 14383, ToZ = 0}         -- "Meteor Shower"
	evt.CastSpell{Spell = 9, Mastery = const.GM, Skill = 3, FromX = -15107, FromY = 13092, FromZ = 4000, ToX = -15107, ToY = 13092, ToZ = 0}         -- "Meteor Shower"
	evt.CastSpell{Spell = 18, Mastery = const.GM, Skill = 3, FromX = -16984, FromY = 15783, FromZ = 4000, ToX = -16984, ToY = 15783, ToZ = 0}         -- "Lightning Bolt"
	evt.CastSpell{Spell = 18, Mastery = const.GM, Skill = 3, FromX = -12333, FromY = 18364, FromZ = 4000, ToX = -12333, ToY = 18364, ToZ = 0}         -- "Lightning Bolt"
	evt.CastSpell{Spell = 18, Mastery = const.GM, Skill = 3, FromX = -13102, FromY = 20346, FromZ = 4000, ToX = -13102, ToY = 20346, ToZ = 0}         -- "Lightning Bolt"
	evt.CastSpell{Spell = 18, Mastery = const.GM, Skill = 3, FromX = -15489, FromY = 18406, FromZ = 4000, ToX = -15489, ToY = 18406, ToZ = 0}         -- "Lightning Bolt"
	evt.CastSpell{Spell = 18, Mastery = const.GM, Skill = 3, FromX = -19300, FromY = 18374, FromZ = 4000, ToX = -19300, ToY = 18374, ToZ = 0}         -- "Lightning Bolt"
	evt.CastSpell{Spell = 18, Mastery = const.GM, Skill = 3, FromX = -17229, FromY = 20297, FromZ = 4000, ToX = -17229, ToY = 20297, ToZ = 0}         -- "Lightning Bolt"
	evt.CastSpell{Spell = 18, Mastery = const.GM, Skill = 3, FromX = -13235, FromY = 20616, FromZ = 4000, ToX = -13235, ToY = 20616, ToZ = 0}         -- "Lightning Bolt"
	evt.CastSpell{Spell = 43, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -15743, ToY = 15989, ToZ = 2731}         -- "Death Blossom"
	evt.CastSpell{Spell = 43, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -12022, ToY = 19402, ToZ = 2728}         -- "Death Blossom"
	evt.CastSpell{Spell = 43, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -13168, ToY = 15608, ToZ = 2725}         -- "Death Blossom"
	evt.CastSpell{Spell = 43, Mastery = const.GM, Skill = 3, FromX = -13312, FromY = 12864, FromZ = 2432, ToX = -14622, ToY = 15778, ToZ = 2724}         -- "Death Blossom"
end

local function FireCannonJump()
	evt.Jump{Direction = 1736, ZAngle = 256, Speed = 2000}
	evt.PlaySound{Id = 472, X = -13305, Y = 12958}
end

local function FireSequence()  -- Timer(<function>, 1*const.Minute)
	if not mapvars.FireSequenceOngoing then
		RemoveTimer()
		return
	end

	if not mapvars.CannonFired then
		FireCannonEffect1()
		FireCannonJump()
		mapvars.CannonFired = true
	elseif not mapvars.EffectsShown then
		FireCannonEffect2()
		mapvars.EffectsShown = true
	else
		local FleetSunk = evt.Cmp("QBits", 37)
		if not FleetSunk then
			evt.Add("QBits", 37)         -- Regnan Pirate Fleet is sunk.
			evt.MoveNPC{NPC = 64, HouseId = 899}         -- "Derrin Delver" -> "Hostel"
			evt.MoveNPC{NPC = 20, HouseId = 900}         -- "Queen Catherine" -> "Hostel"
			evt.MoveNPC{NPC = 21, HouseId = 900}         -- "King Roland" -> "Hostel"
			evt.Add("History13", 0)
		end
		evt.SetFacetBit{Id = 31, Bit = const.FacetBits.Invisible, On = false}
		evt.SetFacetBit{Id = 31, Bit = const.FacetBits.Untouchable, On = false}
		evt.SetFacetBit{Id = 30, Bit = const.FacetBits.Invisible, On = true}
		evt.SetFacetBit{Id = 30, Bit = const.FacetBits.Untouchable, On = true}

		mapvars.FireSequenceOngoing = false
		mapvars.CannonFired = false
		mapvars.EffectsShown = false
	end
end

local function StartFireCannonSequence()
	mapvars.FireSequenceOngoing = true
	Timer(FireSequence, const.Minute)
end

Game.MapEvtLines:RemoveEvent(451)
Game.MapEvtLines:RemoveEvent(452)

-- Make firing cannon multiplayer-friendly.

local NotifyCannonFired

if Multiplayer then
	function NotifyCannonFired()
		Multiplayer.broadcast_mapdata("CannonFired")
	end

	function events.MultiplayerUserdataArrived(t)
		if Multiplayer.utils.distance(Party, {X = -12950,Y = 12485,Z = 1850}) < 1600 then
			StartFireCannonSequence()
		end
	end
end

evt.hint[451] = evt.str[13]  -- "Fire the cannon !"
evt.map[451] = function()
	evt.ForPlayer("All")
	if evt.Cmp("Inventory", 662) then         -- "Cannonball of Dominion"
		evt.Subtract("Inventory", 662)         -- "Cannonball of Dominion"
		evt.ForPlayer("Current")
		evt.StatusText(11)         -- "You hear a low rumbling noise"
		evt.PlaySound{Id = 473, X = -12945, Y = 12015}
		evt.Subtract("QBits", 224)         -- Cannonball of Dominion - I lost it

		if Multiplayer and Multiplayer.in_game then
			NotifyCannonFired()
		end

		StartFireCannonSequence()
		return
	else
		evt.StatusText(18) -- "You do not see the right kind of ammunition anywhere"
	end
end

function events.AfterLoadMap()
	mapvars.CannonFired = mapvars.CannonFired or false
	mapvars.EffectsShown = mapvars.EffectsShown or false
	mapvars.FireSequenceOngoing = mapvars.FireSequenceOngoing or false
end
