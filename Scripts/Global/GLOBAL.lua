globalist={12,14,19,25,28,29,36,41,46,49,54,58,59,60,61,62,64,71,81,89,90,103,107,167,167,169,170,178,181,183,186,187,189,194,198,203,212,214,217,219,221,225,228,231,234,237,240,246,249,290,291,292,293,294,295,298,571,572,573,574,575,576,578,597,656,741,753,756,785,795,797,800,802,804,807,810,812,813,814,816,818,820,822,824,826,828,832,833,835,837,839,841,843,845,847,849,851,853,856,858,868,872,875,878,880,882,885,887,890,896,898,900,902,904,906,908,910,912,914,916,918,930,932,934,936,939,940,945,947,949,1064,1213,1215,1217,1317,1319,1322,1324,1327,1329,1343,1346,1349,1351,1365,1371,1373,1375,1382,1384,1389,1393,1402,1405,1413,1436,1604,1606,1610,1617,1619,1622,1624,1629,1631,1636,1638,1639,1642,1645,1648,1654,1655,1667,1669,1673,1675,1676,1678,1679}
for i = 1, #globalist do
	Game.GlobalEvtLines:RemoveEvent(globalist[i])  
end

function calculateExp(experience)
	--calculate party level
	currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
	if currentWorld==1 then
		partyLevel=vars.MM7LVL+vars.MM6LVL
	elseif currentWorld==2 then
		partyLevel=vars.MM8LVL+vars.MM6LVL
	elseif currentWorld==3 then
		partyLevel=vars.MM8LVL+vars.MM7LVL
	elseif currentWorld==4 then
		partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
	end
	experience=experience*(1+partyLevel/100)+750*partyLevel
	return experience
end
function calculateGold(gold)
	--calculate party level
	currentWorld=TownPortalControls.MapOfContinent(Map.MapStatsIndex) 
	if currentWorld==1 then
		partyLevel=vars.MM7LVL+vars.MM6LVL
	elseif currentWorld==2 then
		partyLevel=vars.MM8LVL+vars.MM6LVL
	elseif currentWorld==3 then
		partyLevel=vars.MM8LVL+vars.MM7LVL
	elseif currentWorld==4 then
		partyLevel=vars.MM8LVL+vars.MM7LVL+vars.MM6LVL
	end
	gold=gold*(1+partyLevel/100)+250*partyLevel
	return gold
end

evt.global[12] = function()
	evt.SetMessage{Str = 12}         -- "So Clanleader Onefang gave you that power stone he was holding onto! It will power the portal on the southwestern tip of the island. To use it, hold an image of the stone in your mind as you step onto the portal."
	evt.ForPlayer("All")
	evt.Add{"AutonotesBits", Value = 492}         -- "Brought Power Stone to Fredrick Talimere."
	evt.Add{"Experience", Value = calculateExp(1500)}
	evt.Subtract{"QBits", Value = 7}         -- "Bring Brekish Onefang's portal crystal to Fredrick Talimere."
	evt.Add{"QBits", Value = 8}         -- Fredrick Talimere visited by player with crystal in their possesion.
	evt.SetNPCTopic{NPC = 28, Index = 2, Event = 602}         -- "Fredrick Talimere" : "Roster Join Event"
	evt.SetNPCTopic{NPC = 1, Index = 2, Event = 0}         -- "Brekish Onefang"
end
-- "Quest"
evt.global[14] = function()
	if evt.Cmp{"QBits", Value = 138} then         -- Found Isthric the Tongue
		evt.SetMessage{Str = 749}         --[[ "You found Isthric and told him how to return home?
We are indeed in debt to you, Merchant of Alvar!
I will speak well of you to Clan Leader Brekish Onefang.
Please take these potions of Cure Wounds as a reward." ]]
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(750)}
		evt.ForPlayer(0)
		evt.Add{"Inventory", Value = 222}         -- "Cure Wounds"
		evt.Add{"Inventory", Value = 222}         -- "Cure Wounds"
		evt.Subtract{"QBits", Value = 137}         -- "Find Isthric the Tongue, brother of Rohtnax.  Return to Rohtnax in the village of Blood Drop on Dagger Wound Island."
		evt.ForPlayer("All")
		evt.Add{"Awards", Value = 54}         -- "Rescued Isthric the Tongue, brother of Rohtnax, on the Dagger Wound Islands."
		evt.SetNPCTopic{NPC = 29, Index = 0, Event = 0}         -- "Rohtnax"
	else
		evt.SetMessage{Str = 14}         --[[ "My brother, Isthric the Tongue, went to check on the tobersk plants on one of the lesser islands.
He has not returned!
I am afraid that he is one of those stranded by the cataclysm. He may even be hurt!
If you were to fix the Portals of Stone, he would surely be able to return, and we could get help to those who need it!
Find him for me!" ]]
		evt.Add{"QBits", Value = 137}         -- "Find Isthric the Tongue, brother of Rohtnax.  Return to Rohtnax in the village of Blood Drop on Dagger Wound Island."
	end
end
-- "Quest"
evt.global[19] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 652} then         -- "Prophecies of the Snake"
		evt.SetMessage{Str = 750}         --[[ "You have found the Prophecies of the Snake!
Perhaps the details of our future can be found in its writings!
Please take this reward for your assistance!" ]]
		evt.Subtract{"Inventory", Value = 652}         -- "Prophecies of the Snake"
		evt.Subtract{"QBits", Value = 135}         -- "Find the Prophecies of the Snake for Pascella Tisk."
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(500)}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(750)}
		evt.SetNPCTopic{NPC = 30, Index = 1, Event = 0}         -- "Pascella Tisk"
	else
		evt.SetMessage{Str = 19}         --[[ "There is one Prophecy, the Prophecy of the Snake, that I have been unable to find a copy of.
I think it may be most revealing about the future of Jadame.Fredrick Talimere, the Cleric, has told me of the snake ruins, and of the Abandoned Temple.
He is in agreement with me, that there may be a copy of this prophecy, somewhere in the temple.
Could you find it for me?" ]]
		evt.Add{"QBits", Value = 135}         -- "Find the Prophecies of the Snake for Pascella Tisk."
	end
end

-- "Patriarch"
evt.global[25] = function()
	evt.SetMessage{Str = 27}         --[[ "::Cauri looks over the Dark Elf(s) in your party::To rescue me, you must have researched my path, and investigated the places I had been.
This demonstrates the intelligence needed to succeed in dealing with the world and business.To get to where I was attacked, you must have the skills needed to fight the Basilisks and other threats, demonstrating your prowess as a warrior.
Skill in battle is needed when proper negotiations break down.To ask me for promotion demonstrates desire, and without desire success will always escape your grasp.You have all of the traits necessary to hold the title of Patriarch.
I will notify to Council upon my return.
It would be my pleasure to travel with you again.
You can find me in the Inn in Ravenshore." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.DarkElf} then
		evt.Set{"ClassIs", Value = const.Class.Patriarch}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1537}         -- Promoted to Elf Patriarch.
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 20}         -- "Rescued Cauri Blackthorne."
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.DarkElf} then
		evt.Set{"ClassIs", Value = const.Class.Patriarch}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1537}         -- Promoted to Elf Patriarch.
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 20}         -- "Rescued Cauri Blackthorne."
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.DarkElf} then
		evt.Set{"ClassIs", Value = const.Class.Patriarch}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1537}         -- Promoted to Elf Patriarch.
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 20}         -- "Rescued Cauri Blackthorne."
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.DarkElf} then
		evt.Set{"ClassIs", Value = const.Class.Patriarch}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1537}         -- Promoted to Elf Patriarch.
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 20}         -- "Rescued Cauri Blackthorne."
	end
	evt.ForPlayer(4)
	if evt.Cmp{"ClassIs", Value = const.Class.DarkElf} then
		evt.Set{"ClassIs", Value = const.Class.Patriarch}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1537}         -- Promoted to Elf Patriarch.
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 20}         -- "Rescued Cauri Blackthorne."
	end
	evt.Subtract{"QBits", Value = 39}         -- "Find Cauri Blackthorne then return to Dantillion in Murmurwoods with information of her location."
	evt.Add{"QBits", Value = 40}         -- Found and Rescued Cauri Blackthorne
	evt.Add{"QBits", Value = 430}         -- Roster Character In Party 31
	evt.SetNPCTopic{NPC = 42, Index = 1, Event = 38}         -- "Cauri Blackthorne" : "Thanks for your help!"
end

-- "Letter"
evt.global[28] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 741} then         -- "Dadeross' Letter to Fellmoon"
		evt.SetMessage{Str = 33}         -- "What is this? A letter from caravan master, Dadeross? Let's see…hmmm…Well, it seems that serious events are afoot. It is a pity--what has happened on Dagger Wound. Serious action may need to be taken, but I require more information……and I think I know how to get it! Perhaps you would be interested in helping me? I will compensate you, of course. And, here. Take this as payment for delivering Dadeross' letter."
		evt.SetNPCTopic{NPC = 3, Index = 0, Event = 29}         -- "Elgar Fellmoon" : "Quest"
		evt.SetNPCGreeting{NPC = 2, Greeting = 58}         -- "Dadeross" : "Hail, adventurer!"
		evt.ForPlayer("All")
		evt.Subtract{"QBits", Value = 3}         -- "Deliver Dadeross' Letter to Elgar Fellmoon at the Merchant House in Ravenshore."
		evt.Add{"QBits", Value = 4}         -- Letter from Q Bit 3 delivered.
		evt.Subtract{"Inventory", Value = 741}         -- "Dadeross' Letter to Fellmoon"
		evt.Subtract{"QBits", Value = 221}         -- Dadeross' Letter to Fellmoon - I lost it, taken event g 28
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(2500)}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(7500)}
		evt.Add{"AutonotesBits", Value = 494}         -- "Delivered Dadeross' Letter to Elgar Fellmoon."
	else
		evt.SetMessage{Str = 32}         -- "You come to me claiming to have a message from one of my caravan masters. Well, where is it then? If it was so important, perhaps you should have been better about not losing it along the way!"
	end
end
-- "Quest"
evt.global[29] = function()
	if evt.Cmp{"QBits", Value = 12} then         -- Quest 11 is done.
		evt.SetMessage{Str = 38}         -- "You must reach Bastian Loudrin in Alvar. Go! He must be informed of recent events!"
	elseif evt.Cmp{"QBits", Value = 24} then         -- Received Reward from Elgar Fellmoon for completing quest 9.
		evt.SetMessage{Str = 37}         -- "As you may be aware, our guild headquarters is located in the city of Alvar. If you've never been there, the easiest way to reach it is to follow the river up through the canyon to the north.Go to the guild house and find Bastian Loudrin. Tell him about the crystal, and the rumors. Lourdrin will know what to do."
		evt.Add{"QBits", Value = 11}         -- "Report to Bastian Loudrin, the merchant guildmaster in Alvar."
	elseif evt.Cmp{"QBits", Value = 10} then         -- Letter from Q Bit 9 delivered.
		evt.SetMessage{Str = 36}         -- "Very good, and here is the payment we agreed upon. Hunter's boats will be useful to us through the crisis.Yes, ""crisis,"" I say! Since your initial visit, several other caravans have missed their scheduled stops. There are also the rumors. Twice I've heard of the appearance of a burning lake of fire rising out of the desert.Volcanoes! Lakes of fire! I fear the mysterious crystal has something to do with it. In any event, the guildmasters in Alvar must be informed!"
		evt.ForPlayer("All")
		evt.Add{"AutonotesBits", Value = 493}         -- "Blackmailed the Wererat Smugglers."
		evt.Add{"Experience", Value = calculateExp(12000)}
		evt.Add{"QBits", Value = 24}         -- Received Reward from Elgar Fellmoon for completing quest 9.
		evt.Subtract{"QBits", Value = 284}         -- "Return to Fellmoon in Ravenshore and report your success in blackmailing the wererat smuggler, Arion Hunter."
	elseif evt.Cmp{"QBits", Value = 9} then         -- "Deliver Fellmoon's blackmail letter to Arion Hunter, leader of the wererat smugglers. Report back to Fellmoon."
		evt.SetMessage{Str = 35}         -- "Listen. We need those boats! Deliver my letter to Arion Hunter. Did you forget? His lair is to the west, up the coast!"
	else
		evt.SetMessage{Str = 34}         -- "The local smugglers have the fastest boats in Ravenshore. If these were available to my agents, they could make quick scouting missions up and down the coast so we could see the extent of the cataclysm mentioned in Dadeross' letter.Here. Bring this letter to the smuggler leader, Arion Hunter. I'm sure it will ""persuade"" him to lend his services. You'll find his hideout westward up the coast.Oh, I almost forgot. The smugglers--they're wererats--and you know how they can be. Hunter can be reasoned with, but don't be surprised if his crew is less than civil."
		evt.Add{"QBits", Value = 9}         -- "Deliver Fellmoon's blackmail letter to Arion Hunter, leader of the wererat smugglers. Report back to Fellmoon."
		evt.Add{"Inventory", Value = 742}         -- "Blackmail Letter"
		evt.Add{"QBits", Value = 222}         -- Blackmail Letter - I lost it, taken event g 32
		evt.SetNPCGreeting{NPC = 3, Greeting = 11}         -- "Elgar Fellmoon" : "Have you done as I've asked of you?"
	end
end

evt.global[36] = function()
	evt.SetMessage{Str = 45}         --[[ "You have found our Ancient Home?
Its located in the western area of the Murmurwoods?
This is wonderful news.
Perhaps there is still time to move my people.
Unfortunately the Elemental threat must be dealt with first, or no people will be safe! All Trolls among you have been promoted to War Troll, and their names will be forever remembered in our songs.
I will teach the rest of you what skills I can, perhaps it will be enough to help you save all of Jadame." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Troll} then
		evt.Set{"ClassIs", Value = const.Class.WarTroll}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1538}         -- Promoted to War Troll.
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"QBits", Value = 1539}         -- Found Troll Homeland.
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Troll} then
		evt.Set{"ClassIs", Value = const.Class.WarTroll}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1538}         -- Promoted to War Troll.
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"QBits", Value = 1539}         -- Found Troll Homeland.
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Troll} then
		evt.Set{"ClassIs", Value = const.Class.WarTroll}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1538}         -- Promoted to War Troll.
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"QBits", Value = 1539}         -- Found Troll Homeland.
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Troll} then
		evt.Set{"ClassIs", Value = const.Class.WarTroll}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1538}         -- Promoted to War Troll.
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"QBits", Value = 1539}         -- Found Troll Homeland.
	end
	evt.ForPlayer(4)
	if evt.Cmp{"ClassIs", Value = const.Class.Troll} then
		evt.Set{"ClassIs", Value = const.Class.WarTroll}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1538}         -- Promoted to War Troll.
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"QBits", Value = 1539}         -- Found Troll Homeland.
	end
	evt.Subtract{"QBits", Value = 68}         -- "Find the Ancient Troll Homeland and return to Volog Sandwind in the Ironsand Desert."
	evt.SetNPCTopic{NPC = 43, Index = 1, Event = 612}         -- "Volog Sandwind" : "Roster Join Event"
end
evt.global[41] = function()
	evt.SetMessage{Str = 50}         -- "Disaster in Dagger Wound, too? This is indeed disturbing. If one were to believe all the rumors, one would think that all of Jadame is in upheaval and chaos.I wish I knew more. I rely on our caravan masters for news, but all who were supposed to arrive here this month have not. What I do hear, troubles me. Hurricanes, floods, and now a volcano! The worst I've heard is that a sea of fire has appeared in the Ironsand Desert--and this from many sources.I wonder if this crystal in Ravenshore has something to do with it. Its appearance at the onset of the calamity seems to be more than a coincidence."
	evt.Subtract{"QBits", Value = 11}         -- "Report to Bastian Loudrin, the merchant guildmaster in Alvar."
	evt.Add{"QBits", Value = 12}         -- Quest 11 is done.
	evt.SetNPCTopic{NPC = 5, Index = 0, Event = 42}         -- "Bastian Loudrin" : "Quest"
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(15000)}
	evt.ForPlayer(0)
	evt.Add{"Gold", Value = calculateGold(2000)}
end
-- "Come to Alvar"
evt.global[46] = function()
	if evt.Cmp{"QBits", Value = 62} then         -- Vilebites Ashes (item603) placed in troll tomb.
		evt.SetMessage{Str = 59}         -- "You have done my family a great service. With his ashes safe in the holy sanctuary of the village tomb, Vilebite can lie in peace. My father, too is greatly improved. We have talked and I believe that he can now take care of himself while I accompany you to Alvar."
		evt.Add{"QBits", Value = 63}         -- Quest 61 done.
		evt.Subtract{"QBits", Value = 61}         -- "Put Vilebite's ashes in the Dust village tomb then return to Overdune."
		evt.ForPlayer("All")
		evt.Add{"AutonotesBits", Value = 495}         -- "Placed Vilebite's ashes in the Troll Tomb."
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(7500)}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(20000)}
		evt.SetNPCTopic{NPC = 7, Index = 0, Event = 604}         -- "Overdune Snapfinger" : "Roster Join Event"
		evt.SetNPCGreeting{NPC = 47, Greeting = 18}         -- "Farhill Snapfinger" : "Come in…you are always welcome here."
		evt.SetNPCTopic{NPC = 47, Index = 0, Event = 47}         -- "Farhill Snapfinger" : "Vilebite"
	elseif evt.Cmp{"QBits", Value = 61} then         -- "Put Vilebite's ashes in the Dust village tomb then return to Overdune."
		evt.SetMessage{Str = 58}         -- "I will go with you only after my brother's ashes are safely in the village tomb."
	else
		evt.SetMessage{Str = 57}         -- "I would come with you, If it were not for my father. So deep is his mourning for my brother, Vilebite, that he cannot care for himself.My father believes that Vilebite's soul cannot rest until his remains are at rest in the village tomb. Unfortunately, Gogs infested the tomb when the lake of fire appeared.Here! Take my brother's ashes. I'm sure my father's grief will lessen if they are placed in the tomb. Do this for me and I will travel with you to Alvar."
		evt.Add{"QBits", Value = 61}         -- "Put Vilebite's ashes in the Dust village tomb then return to Overdune."
		evt.Add{"Inventory", Value = 603}         -- "Urn of Ashes"
		evt.Add{"QBits", Value = 202}         -- Urn of Ashes - I lost it
	end
end
-- "Quest"
evt.global[49] = function()
	if not evt.Cmp{"QBits", Value = 21} then         -- Allied with Charles Quioxte's Dragon Hunters. Return Dragon Egg to Quixote done.
		if not evt.Cmp{"QBits", Value = 33} then         -- "Find the Dragon Egg and return it to the dragon leader, Deftclaw Redreaver."
			evt.SetMessage{Str = 73}         -- "Last month one of Quixote's raiding parties invaded our caves. They slew many and took with them the egg containing my unborn heir. While those foul slayers hold the egg, we cannot attack their encampment.If you were to return the egg to me, I could destroy Quixote. Do this for me and I will join your alliance."
			evt.Add{"QBits", Value = 33}         -- "Find the Dragon Egg and return it to the dragon leader, Deftclaw Redreaver."
			return
		end
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 605} then         -- "Dragon Leader's Egg"
			evt.SetMessage{Str = 74}         -- "If you want me to join your alliance, you will have to help me against Charles Quixote. Bring me the Dragon egg he stole from me!"
			return
		end
		evt.ShowMovie{DoubleSize = 1, Name = "\"dragonsrevenge\""}
		evt.SetMessage{Str = 855}         -- "Now that I need not fear my heir's destruction. I will visit my revenge on Quixote. His camp will face the assault of fire and claw. Those who have hunted us are now our prey animals.As for your alliance…you have done me a great service. I will honor my debt. As soon as I've set my enemies to flight or the beyond, I will join the alliance council in Ravenshore."
		evt.Add{"QBits", Value = 22}         -- Allied with Dragons. Return Dragon Egg to Dragons done.
		evt.Add{"QBits", Value = 35}         -- Quest 33 is done.
		evt.Subtract{"QBits", Value = 16}         -- "Form an alliance with the Dragon hunters of Garrote Gorge."
		evt.Subtract{"QBits", Value = 17}         -- "Form an alliance with the Dragons of Garrote Gorge."
		evt.Subtract{"QBits", Value = 31}         -- "Recover the Dragon Egg from Zog's fortress in Ravage Roaming and return it to Charles Quixote in Garrote Gorge."
		evt.Subtract{"QBits", Value = 33}         -- "Find the Dragon Egg and return it to the dragon leader, Deftclaw Redreaver."
		evt.SetNPCTopic{NPC = 15, Index = 0, Event = 0}         -- "Sir Charles Quixote"
		evt.SetNPCGreeting{NPC = 17, Greeting = 20}         -- "Deftclaw Redreaver" : "What do you want?"
		evt.SetNPCTopic{NPC = 17, Index = 0, Event = 0}         -- "Deftclaw Redreaver"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(20000)}
		evt.ForPlayer("All")
		evt.Subtract{"Inventory", Value = 605}         -- "Dragon Leader's Egg"
		evt.Subtract{"QBits", Value = 204}         -- Dragon Leader's Egg - I lost it, taken event g49, g64
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(10000)}
		evt.ForPlayer("All")
		evt.Add{"Awards", Value = 7}         -- "Formed an alliance with the Garrote Gorge Dragons."
	end
	evt.Add{"History7", Value = 0}
end
-- "Cure"
evt.global[54] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 623} then         -- "Gem of Restoration"
		evt.ForPlayer("All")
		evt.SetMessage{Str = 531}         --[[ "The Cleric sent you back with the Gem of Restoration?
I am free of this place!
Search me out if you wish for me to ever travel with you!
It would be my pleasure to join you in your journeys!
I will wait for you at the Adventurer's Inn in Ravenshore." ]]
		evt.Subtract{"Inventory", Value = 623}         -- "Gem of Restoration"
		evt.Subtract{"QBits", Value = 217}         -- Gem of Restoration - I lost it
		evt.Add{"Experience", Value = calculateExp(15000)}
		evt.Add{"QBits", Value = 134}         -- Gave Gem of Restoration to Blazen Stormlance
		evt.Add{"QBits", Value = 435}         -- Roster Character In Party 36
		evt.ForPlayer("All")
		evt.Add{"QBits", Value = 1542}         -- Rescued Blazen Stormlance.
		evt.SetNPCTopic{NPC = 107, Index = 1, Event = 0}         -- "Blazen Stormlance"
	else
		evt.SetMessage{Str = 64}         --[[ "Perhaps the Clerics of the Sun have a way to cure me, for they would be the only ones who would know how to counter the dark magics that afflict me. There is a friend of mine in Ravenshore named Dervish Chevron. He left the Temple of the Sun years ago to pursue his own research into the mysteries of Jadame.
Perhaps he would know of a cure, or even have it in his possession.
If he cannot help, promise you will return here and kill me so I may at last be at rest!" ]]
		evt.Add{"QBits", Value = 72}         -- "Inquire about a cure for Blazen Stormlance from Dervish Chevron in Ravenshore."
	end
end
evt.global[58] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 539} then         -- "Ebonest"
		evt.SetMessage{Str = 85}         --[[ "You have found Blazen Stormlance? But where is Ebonest?
Return to me when you have the spear and you will be promoted!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 22} then         -- Allied with Dragons. Return Dragon Egg to Dragons done.
		evt.SetMessage{Str = 71}         --[[ "What is this?
You ally with my mortal enemies and then seek to do me a favor?I wonder what the Dragons think of this. But so be it.
I am in your debt for returning Ebonest to me.
I will promote any Knights in your party to Champion, however they will never be accepted in my service.
The rest I will teach what I can. I do not wish to see you again!" ]]
	else
		evt.SetMessage{Str = 70}         --[[ "You found Blazen Stormlance?
What about MY spear Ebonest?
You have that as well?FANTASTIC!I thank you for this and find myself in your debt!
I will promote all knights in your party to Champion and teach what skills I can to the rest of your party. " ]]
	end
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Add{"QBits", Value = 1540}         -- Promoted to Champion.
		evt.Subtract{"Inventory", Value = 539}         -- "Ebonest"
	else
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1541}         -- Returned Ebonest to Charles Quixote.
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Add{"QBits", Value = 1540}         -- Promoted to Champion.
		evt.Subtract{"Inventory", Value = 539}         -- "Ebonest"
	else
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1541}         -- Returned Ebonest to Charles Quixote.
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Add{"QBits", Value = 1540}         -- Promoted to Champion.
		evt.Subtract{"Inventory", Value = 539}         -- "Ebonest"
	else
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1541}         -- Returned Ebonest to Charles Quixote.
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Add{"QBits", Value = 1540}         -- Promoted to Champion.
		evt.Subtract{"Inventory", Value = 539}         -- "Ebonest"
	else
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1541}         -- Returned Ebonest to Charles Quixote.
	end
	evt.ForPlayer(4)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Add{"QBits", Value = 1540}         -- Promoted to Champion.
		evt.Subtract{"Inventory", Value = 539}         -- "Ebonest"
	else
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1541}         -- Returned Ebonest to Charles Quixote.
	end
	evt.Subtract{"QBits", Value = 70}         -- "Find Blazen Stormlance and recover the spear Ebonest. Return to Leane Stormlance in Garrote Gorge and deliver Ebonest to Charles Quixote."
	evt.SetNPCTopic{NPC = 15, Index = 2, Event = 735}         -- "Sir Charles Quixote" : "Promote Knights"
	evt.SetNPCTopic{NPC = 52, Index = 2, Event = 735}         -- "Sir Charles Quixote" : "Promote Knights"
end
-- "My Father"
evt.global[59] = function()
	if evt.Cmp{"QBits", Value = 435} then         -- Roster Character In Party 36
		if evt.Cmp{"Inventory", Value = 539} then         -- "Ebonest"
			goto _8
		end
		if evt.Cmp{"QBits", Value = 1541} then         -- Returned Ebonest to Charles Quixote.
			goto _8
		end
	elseif not evt.Cmp{"Inventory", Value = 539} then         -- "Ebonest"
		evt.SetMessage{Str = 69}         --[[ "Have you found my father?
Or the spear Ebonest?
We must get it back to Charles Quixote!" ]]
		return
	end
	evt.SetMessage{Str = 888}         --[[ "You found Ebonest?
What of my father?
Where is he?
I thought you were going to return when you had found both my father and the spear." ]]
	do return end
::_8::
	evt.SetMessage{Str = 889}         --[[ "You found my father and Ebonest?
I will be forever in your debt!
We should take the spear to Charles Quixote, and if he is agreeable, he will promote me and any knights in your party!" ]]
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(5000)}
	evt.SetNPCTopic{NPC = 49, Index = 0, Event = 611}         -- "Leane Stormlance" : "Roster Join Event"
end
-- "Promotion to Great Wyrm"
evt.global[60] = function()
	if evt.Cmp{"QBits", Value = 21} then         -- Allied with Charles Quioxte's Dragon Hunters. Return Dragon Egg to Quixote done.
		evt.SetMessage{Str = 76}         --[[ "You think I would promote a Dragon that serves those who have allied themselves with our Mortal enemy, Charles Quixote.
What arrogance!
What outrageousness!
You will have to prove yourselves to me! And in the proving you will deal a serious blow to your allies!
To the southwest of here, Quixote has established an encampment of his puny “Dragon Slayers.”
This camp is lead by Jeric Whistlebone, the second in command of Quixote’s army.
Destroy this camp!
Kill all of those who serve Quixote in that region and return to me.
Return to me with the sword of
Whistlebone the Slayer." ]]
		evt.Add{"QBits", Value = 74}         -- "Kill all Dragon Slayers and return the Sword of Whistlebone the Slayer to Deftclaw Redreaver in Garrote Gorge."
		evt.SetNPCTopic{NPC = 17, Index = 1, Event = 61}         -- "Deftclaw Redreaver" : "Dragon Slayers"
		evt.SetNPCTopic{NPC = 17, Index = 1, Event = 61}         -- "Deftclaw Redreaver" : "Dragon Slayers"
	else
		evt.Cmp{"QBits", Value = 22}         -- Allied with Dragons. Return Dragon Egg to Dragons done.
		evt.SetMessage{Str = 75}         --[[ "To attain the status of Great Wyrm, a Dragon must prove that he can handle himself against a great number of foes.
He must face down the vermin that Charles Quixote would send against us.
To the southwest of here, Quixote has established an encampment of his puny “Dragon Slayers.”
This camp is lead by Jeric Whistlebone, the second in command of Quixote’s army.
Destroy this camp!
Kill all of those who serve Quixote in that region and return to me.
Return to me with the sword of
Whistlebone the Slayer.
In doing this, you will prove to me your worthiness.
" ]]
		evt.Add{"QBits", Value = 74}         -- "Kill all Dragon Slayers and return the Sword of Whistlebone the Slayer to Deftclaw Redreaver in Garrote Gorge."
		evt.SetNPCTopic{NPC = 17, Index = 1, Event = 61}         -- "Deftclaw Redreaver" : "Dragon Slayers"
		evt.SetNPCTopic{NPC = 53, Index = 1, Event = 61}         -- "Deftclaw Redreaver" : "Dragon Slayers"
	end
end
evt.global[61] = function()
	if not evt.Cmp{"QBits", Value = 21} then         -- Allied with Charles Quioxte's Dragon Hunters. Return Dragon Egg to Quixote done.
		if evt.Cmp{"QBits", Value = 22} then         -- Allied with Dragons. Return Dragon Egg to Dragons done.
			evt.SetMessage{Str = 77}         --[[ "Have you slain the “Dragon Slayers?""
Where is the sword of Whistlebone the Slayer?!?" ]]
		else
			evt.SetMessage{Str = 86}         --[[ "That cursed knight, Charles Quixote is assembling his best Dragon Slayers at an encampment to the southwest of here.
He must be planning another assault upon the Dragon Caves!" ]]
		end
	end
end
evt.global[62] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 540} then         -- "Sword of Whistlebone"
		evt.SetMessage{Str = 81}         --[[ "You have killed the Dragon Slayers, but where is the Sword of Whistlebone?
Return to me when you have it!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 22} then         -- Allied with Dragons. Return Dragon Egg to Dragons done.
		goto _11
	end
	if not evt.Cmp{"QBits", Value = 21} then         -- Allied with Charles Quioxte's Dragon Hunters. Return Dragon Egg to Quixote done.
		goto _11
	end
	evt.SetMessage{Str = 80}         --[[ "You return to me with the sword of the Slayer, Whistlebone!
Is there no end to the treachery that you will commit? Is there no one that you owe allegiance to?
I will promote those Dragons who travel with you to Great Wyrm, however they will never fly underneath me!
There rest of your traitorous group will be instructed in those skills which can be taught to them!
Go now!
Never show your face here again, unless you want it eaten!" ]]
::_15::
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Dragon} then
		evt.Set{"ClassIs", Value = const.Class.GreatWyrm}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1543}         -- Promoted to Great Wyrm.
		evt.Subtract{"Inventory", Value = 540}         -- "Sword of Whistlebone"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"QBits", Value = 1544}         -- Gave the Sword of Whistlebone the Slayer to the Deftclaw Redreaver.
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Dragon} then
		evt.Set{"ClassIs", Value = const.Class.GreatWyrm}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1543}         -- Promoted to Great Wyrm.
		evt.Subtract{"Inventory", Value = 540}         -- "Sword of Whistlebone"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"QBits", Value = 1544}         -- Gave the Sword of Whistlebone the Slayer to the Deftclaw Redreaver.
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Dragon} then
		evt.Set{"ClassIs", Value = const.Class.GreatWyrm}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1543}         -- Promoted to Great Wyrm.
		evt.Subtract{"Inventory", Value = 540}         -- "Sword of Whistlebone"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"QBits", Value = 1544}         -- Gave the Sword of Whistlebone the Slayer to the Deftclaw Redreaver.
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Dragon} then
		evt.Set{"ClassIs", Value = const.Class.GreatWyrm}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1543}         -- Promoted to Great Wyrm.
		evt.Subtract{"Inventory", Value = 540}         -- "Sword of Whistlebone"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"QBits", Value = 1544}         -- Gave the Sword of Whistlebone the Slayer to the Deftclaw Redreaver.
	end
	evt.ForPlayer(4)
	if evt.Cmp{"ClassIs", Value = const.Class.Dragon} then
		evt.Set{"ClassIs", Value = const.Class.GreatWyrm}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1543}         -- Promoted to Great Wyrm.
		evt.Subtract{"Inventory", Value = 540}         -- "Sword of Whistlebone"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"QBits", Value = 1544}         -- Gave the Sword of Whistlebone the Slayer to the Deftclaw Redreaver.
	end
	evt.ForPlayer("All")
	evt.Subtract{"QBits", Value = 74}         -- "Kill all Dragon Slayers and return the Sword of Whistlebone the Slayer to Deftclaw Redreaver in Garrote Gorge."
	evt.SetNPCTopic{NPC = 17, Index = 2, Event = 736}         -- "Deftclaw Redreaver" : "Promote Dragons"
	evt.SetNPCTopic{NPC = 53, Index = 2, Event = 736}         -- "Deftclaw Redreaver" : "Promote Dragons"
	do return end
::_11::
	evt.SetMessage{Str = 79}         --[[ "You return to me with the sword of the Slayer, Whistlebone!
You are indeed worthy of my notice!
The Dragons in your group are promoted to Great Wyrm!
I will teach the others of your group what skills I can as a reward for their assistance!" ]]
	goto _15
end
-- "Quest"
evt.global[64] = function()
	if not evt.Cmp{"QBits", Value = 22} then         -- Allied with Dragons. Return Dragon Egg to Dragons done.
		if not evt.Cmp{"QBits", Value = 31} then         -- "Recover the Dragon Egg from Zog's fortress in Ravage Roaming and return it to Charles Quixote in Garrote Gorge."
			evt.SetMessage{Str = 83}         -- "One of my customers, an Ogre that goes by the charming moniker of ""Zog the Jackal,"" has seriously betrayed my trust. I gave him an item of great value on promise of future payment. This rather large payment never arrived. I sent a messenger to demand return of the item--a Dragon's egg of great potential. This messenger was slain!Needless to say, this matter concerns me greatly. I have allotted both money and men for the purpose of revenge. If, however, you were to recover the egg for me from Zog's fortress in Ravage Roaming, I would be glad to pledge service to your alliance."
			evt.Add{"QBits", Value = 31}         -- "Recover the Dragon Egg from Zog's fortress in Ravage Roaming and return it to Charles Quixote in Garrote Gorge."
			return
		end
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 605} then         -- "Dragon Leader's Egg"
			evt.SetMessage{Str = 84}         -- "Have you recovered the Dragon egg from Zog's Ravage Roaming fortress? Oh, never mind. I can see from your abashed expression that you have not.I stand firm on our deal. Bring me that egg, or I'll have nothing to do with your alliance!"
			return
		end
		evt.ShowMovie{DoubleSize = 1, Name = "\"dragonhunters\""}
		evt.SetMessage{Str = 848}         -- "Well, that matter's done. I will make arrangements to travel to Ravenshore so I myself may sit on your council. Frankly, I could use a bit of change. I will leave my second in command, Reginald Dorray, in charge.Again, good job."
		evt.Add{"QBits", Value = 21}         -- Allied with Charles Quioxte's Dragon Hunters. Return Dragon Egg to Quixote done.
		evt.Add{"QBits", Value = 35}         -- Quest 33 is done.
		evt.Subtract{"QBits", Value = 16}         -- "Form an alliance with the Dragon hunters of Garrote Gorge."
		evt.Subtract{"QBits", Value = 17}         -- "Form an alliance with the Dragons of Garrote Gorge."
		evt.Subtract{"QBits", Value = 31}         -- "Recover the Dragon Egg from Zog's fortress in Ravage Roaming and return it to Charles Quixote in Garrote Gorge."
		evt.Subtract{"QBits", Value = 33}         -- "Find the Dragon Egg and return it to the dragon leader, Deftclaw Redreaver."
		evt.SetNPCTopic{NPC = 15, Index = 0, Event = 0}         -- "Sir Charles Quixote"
		evt.SetNPCGreeting{NPC = 15, Greeting = 22}         -- "Sir Charles Quixote" : "You just caught me. I'm almost ready to leave for Ravenshore, but how may I help you?"
		evt.SetNPCTopic{NPC = 17, Index = 0, Event = 0}         -- "Deftclaw Redreaver"
		evt.MoveNPC{NPC = 255, HouseId = 0}         -- "Bazalath"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(20000)}
		evt.ForPlayer("All")
		evt.Subtract{"Inventory", Value = 605}         -- "Dragon Leader's Egg"
		evt.Subtract{"QBits", Value = 204}         -- Dragon Leader's Egg - I lost it, taken event g49, g64
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(10000)}
		evt.ForPlayer("All")
		evt.Add{"Awards", Value = 8}         -- "Formed an alliance with Charles Quixote and his Dragon Hunters."
	end
	evt.Add{"History8", Value = 0}
end
evt.global[71] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 541} then         -- "Axe of Balthazar"
		evt.SetMessage{Str = 98}         --[[ "Where is Balthazar's Axe?
You waste my time!
Find the axe, find Dadeross and return to me!" ]]
		return
	end
	if not evt.Cmp{"Inventory", Value = 732} then         -- "Certificate of Authentication"
		evt.SetMessage{Str = 94}         --[[ "You have found the Axe of Balthazar!
Have you presented it to Dadeross?
Without his authentication, we can not proceed with the Rite’s of Purity!
Find him and return to us once you have presented him with the axe!" ]]
		return
	end
	evt.SetMessage{Str = 95}         --[[ "You have found the Axe of Balthazar!
Have you presented it to Dadeross? Ah, you have authentication from Dadeross!
The Rite’s of Purity will begin immediately! You proven yourselves worthy, and our now members of our herd!
The Minotaurs who travel with you are promoted to Minotaur Lord.
The others in your group will be taught what skills we have that maybe useful to them." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Minotaur} then
		evt.Set{"ClassIs", Value = const.Class.MinotaurLord}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1545}         -- Promoted to Minotaur Lord.
		evt.Subtract{"Inventory", Value = 541}         -- "Axe of Balthazar"
		evt.Subtract{"Inventory", Value = 732}         -- "Certificate of Authentication"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 29}         -- "Recovered Axe of Balthazar."
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Minotaur} then
		evt.Set{"ClassIs", Value = const.Class.MinotaurLord}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1545}         -- Promoted to Minotaur Lord.
		evt.Subtract{"Inventory", Value = 541}         -- "Axe of Balthazar"
		evt.Subtract{"Inventory", Value = 732}         -- "Certificate of Authentication"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 29}         -- "Recovered Axe of Balthazar."
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Minotaur} then
		evt.Set{"ClassIs", Value = const.Class.MinotaurLord}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1545}         -- Promoted to Minotaur Lord.
		evt.Subtract{"Inventory", Value = 541}         -- "Axe of Balthazar"
		evt.Subtract{"Inventory", Value = 732}         -- "Certificate of Authentication"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 29}         -- "Recovered Axe of Balthazar."
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Minotaur} then
		evt.Set{"ClassIs", Value = const.Class.MinotaurLord}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1545}         -- Promoted to Minotaur Lord.
		evt.Subtract{"Inventory", Value = 541}         -- "Axe of Balthazar"
		evt.Subtract{"Inventory", Value = 732}         -- "Certificate of Authentication"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 29}         -- "Recovered Axe of Balthazar."
	end
	evt.ForPlayer(4)
	if evt.Cmp{"ClassIs", Value = const.Class.Minotaur} then
		evt.Set{"ClassIs", Value = const.Class.MinotaurLord}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1545}         -- Promoted to Minotaur Lord.
		evt.Subtract{"Inventory", Value = 541}         -- "Axe of Balthazar"
		evt.Subtract{"Inventory", Value = 732}         -- "Certificate of Authentication"
		evt.ForPlayer("All")
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 29}         -- "Recovered Axe of Balthazar."
	end
	evt.Subtract{"QBits", Value = 76}         -- "Find the Axe of Balthazar, in the Dark Dwarf Mines.  Have the Axe authenticated by Dadeross.  Return the axe to Tessalar, heir to the leadership of the Minotaur Herd."
	evt.Add{"QBits", Value = 87}         -- 0
	evt.Subtract{"Inventory", Value = 541}         -- "Axe of Balthazar"
	evt.Subtract{"Inventory", Value = 732}         -- "Certificate of Authentication"
	evt.SetNPCTopic{NPC = 58, Index = 0, Event = 740}         -- "Tessalar" : "Promote Minotuars"
end
evt.global[81] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 626} then         -- "Prophecies of the Sun"
		evt.SetMessage{Str = 106}         --[[ "Have you found this Lair of the Feathered Serpent and the Prophecies of the Sun?
Do not waste my time!
The world is ending and you waste time with useless conversation!
Return to me when you have found the Prophecies and have taken them to the Temple of the Sun." ]]
		return
	end
	evt.SetMessage{Str = 107}         --[[ "You have found the lost Prophecies of the Sun?
May the Light forever shine upon you and may the Prophet guide your steps.
With these we may be able to find the answer to what has befallen Jadame! " ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1546}         -- Promoted to Cleric of the Sun.
		evt.Subtract{"Inventory", Value = 626}         -- "Prophecies of the Sun"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 31}         -- "Found the lost Prophecies of the Sun and returned them to the Temple of the Sun."
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1546}         -- Promoted to Cleric of the Sun.
		evt.Subtract{"Inventory", Value = 626}         -- "Prophecies of the Sun"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 31}         -- "Found the lost Prophecies of the Sun and returned them to the Temple of the Sun."
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1546}         -- Promoted to Cleric of the Sun.
		evt.Subtract{"Inventory", Value = 626}         -- "Prophecies of the Sun"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 31}         -- "Found the lost Prophecies of the Sun and returned them to the Temple of the Sun."
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1546}         -- Promoted to Cleric of the Sun.
		evt.Subtract{"Inventory", Value = 626}         -- "Prophecies of the Sun"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 31}         -- "Found the lost Prophecies of the Sun and returned them to the Temple of the Sun."
	end
	evt.ForPlayer(4)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1546}         -- Promoted to Cleric of the Sun.
		evt.Subtract{"Inventory", Value = 626}         -- "Prophecies of the Sun"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 31}         -- "Found the lost Prophecies of the Sun and returned them to the Temple of the Sun."
	end
	evt.Subtract{"QBits", Value = 78}         -- "Find the Prophecies of the Sun in the Abandoned Temple  and take them to Stephen."
	evt.SetNPCTopic{NPC = 59, Index = 2, Event = 737}         -- "Stephen" : "Promote Clerics"
end
-- "Promotion to Lich"
evt.global[89] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 611} then         -- "Lost Book of Kehl"
		evt.SetMessage{Str = 115}         --[[ "You do not have the Lost Book of Khel!
I cannot help you, if you do not help me!
Return here with the Book and a Lich Jar for each necromancer in your party that wishes to become a Lich!" ]]
		return
	end
	evt.ForPlayer(0)
	if not evt.Cmp{"ClassIs", Value = const.Class.Necromancer} then
		goto _9
	end
	if evt.Cmp{"Inventory", Value = 628} then         -- "Lich Jar"
		goto _9
	end
::_28::
	evt.SetMessage{Str = 114}         --[[ "You have the Lost Book of Khel, however you lack the Lich Jars needed to complete the transformation!
Return here when you have one for each necromancer in your party!" ]]
	do return end
::_9::
	evt.ForPlayer(1)
	if not evt.Cmp{"ClassIs", Value = const.Class.Necromancer} then
		goto _14
	end
	if evt.Cmp{"Inventory", Value = 628} then         -- "Lich Jar"
		goto _14
	end
	goto _28
::_14::
	evt.ForPlayer(2)
	if not evt.Cmp{"ClassIs", Value = const.Class.Necromancer} then
		goto _19
	end
	if evt.Cmp{"Inventory", Value = 628} then         -- "Lich Jar"
		goto _19
	end
	goto _28
::_19::
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Necromancer} then
		if evt.Cmp{"Inventory", Value = 628} then         -- "Lich Jar"
			goto _27
		end
		goto _28
	end
	evt.ForPlayer(4)
	if evt.Cmp{"ClassIs", Value = const.Class.Necromancer} then
		goto _27
	end
::_30::
	evt.SetMessage{Str = 116}         --[[ "You have brought everything needed to perform the transformation!
So be it!
All necromancer’s in your party will be transformed into Liches!
May the dark energies flow through them for all eternity!
The rest of you will gain what knowledge I can teach them as reward for their assistance!
Lets begin!After we have completed, good friend Lathean can handle any future promotions for your party." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Necromancer} then
		evt.Set{"ClassIs", Value = const.Class.Lich}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1548}         -- Promoted to Lich.
		evt.Subtract{"Inventory", Value = 628}         -- "Lich Jar"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 35}         -- "Found the Lost Book of Khel."
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Necromancer} then
		evt.Set{"ClassIs", Value = const.Class.Lich}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1548}         -- Promoted to Lich.
		evt.Subtract{"Inventory", Value = 628}         -- "Lich Jar"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 35}         -- "Found the Lost Book of Khel."
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Necromancer} then
		evt.Set{"ClassIs", Value = const.Class.Lich}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1548}         -- Promoted to Lich.
		evt.Subtract{"Inventory", Value = 628}         -- "Lich Jar"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 35}         -- "Found the Lost Book of Khel."
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Necromancer} then
		evt.Set{"ClassIs", Value = const.Class.Lich}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1548}         -- Promoted to Lich.
		evt.Subtract{"Inventory", Value = 628}         -- "Lich Jar"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 35}         -- "Found the Lost Book of Khel."
	end
	evt.ForPlayer(4)
	if evt.Cmp{"ClassIs", Value = const.Class.Necromancer} then
		evt.Set{"ClassIs", Value = const.Class.Lich}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1548}         -- Promoted to Lich.
		evt.Subtract{"Inventory", Value = 628}         -- "Lich Jar"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 35}         -- "Found the Lost Book of Khel."
	end
	evt.ForPlayer("All")
	evt.Subtract{"Inventory", Value = 611}         -- "Lost Book of Kehl"
	evt.Subtract{"QBits", Value = 82}         -- "Find the Lost Book of Khel and return it to Vertrinus in Shadowspire."
	evt.SetNPCTopic{NPC = 61, Index = 0, Event = 742}         -- "Vetrinus Taleshire" : "Travel with you!"
	do return end
::_27::
	if evt.Cmp{"Inventory", Value = 628} then         -- "Lich Jar"
		goto _30
	end
	goto _28
end
evt.global[90] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 627} then         -- "Remains of Korbu"
		if evt.Cmp{"Inventory", Value = 612} then         -- "Sarcophagus of Korbu"
			evt.SetMessage{Str = 112}         --[[ "You return to us with the Sarcophagus of Korbu, but where are his remains? We cannot complete the act of reanimation without them!
Return to us when you have both the Sarcophagus and his remains!" ]]
		else
			evt.SetMessage{Str = 151}         --[[ "We need to consult Korbu!
You have agreed to bring us his remains and his Sarcophagus!
Do not bother us until you have these items!" ]]
		end
		return
	end
	if not evt.Cmp{"Inventory", Value = 612} then         -- "Sarcophagus of Korbu"
		evt.SetMessage{Str = 111}         --[[ "You return to us with the remains of Korbu, but where is his Sarcophagus? We cannot complete the act of reanimation without it!
Return to us when you have both the remains and the Sarcophagus!" ]]
		return
	end
	evt.SetMessage{Str = 117}         --[[ "You have brought us the Sarcophagus of Korbu and his sacred remains.
We will attempt to reanimate Korbu and seek his wisdom in these troubled times!
The vampires among you will be transformed into Nosferatu, and the others will be taught what skills we can teach them as reward for your service." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Vampire} then
		evt.Set{"ClassIs", Value = const.Class.Nosferatu}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1547}         -- Promoted to Nosferatu.
		evt.Subtract{"Inventory", Value = 627}         -- "Remains of Korbu"
		evt.Subtract{"Inventory", Value = 612}         -- "Sarcophagus of Korbu"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 33}         -- "Found the Sarcophagus and Remains of Korbu."
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Vampire} then
		evt.Set{"ClassIs", Value = const.Class.Nosferatu}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1547}         -- Promoted to Nosferatu.
		evt.Subtract{"Inventory", Value = 627}         -- "Remains of Korbu"
		evt.Subtract{"Inventory", Value = 612}         -- "Sarcophagus of Korbu"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 33}         -- "Found the Sarcophagus and Remains of Korbu."
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Vampire} then
		evt.Set{"ClassIs", Value = const.Class.Nosferatu}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1547}         -- Promoted to Nosferatu.
		evt.Subtract{"Inventory", Value = 627}         -- "Remains of Korbu"
		evt.Subtract{"Inventory", Value = 612}         -- "Sarcophagus of Korbu"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 33}         -- "Found the Sarcophagus and Remains of Korbu."
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Vampire} then
		evt.Set{"ClassIs", Value = const.Class.Nosferatu}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1547}         -- Promoted to Nosferatu.
		evt.Subtract{"Inventory", Value = 627}         -- "Remains of Korbu"
		evt.Subtract{"Inventory", Value = 612}         -- "Sarcophagus of Korbu"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 33}         -- "Found the Sarcophagus and Remains of Korbu."
	end
	evt.ForPlayer(4)
	if evt.Cmp{"ClassIs", Value = const.Class.Vampire} then
		evt.Set{"ClassIs", Value = const.Class.Nosferatu}
		evt.Add{"Experience", Value = calculateExp(35000)}
		evt.Add{"QBits", Value = 1547}         -- Promoted to Nosferatu.
		evt.Subtract{"Inventory", Value = 627}         -- "Remains of Korbu"
		evt.Subtract{"Inventory", Value = 612}         -- "Sarcophagus of Korbu"
	else
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.Add{"Awards", Value = 33}         -- "Found the Sarcophagus and Remains of Korbu."
	end
	evt.Subtract{"QBits", Value = 80}         -- "Find the Sarcophagus of Korbu and Korbu's Remains and return them to Lathean in Shadowspire."
	evt.ForPlayer("All")
	evt.Subtract{"Inventory", Value = 627}         -- "Remains of Korbu"
	evt.Subtract{"Inventory", Value = 612}         -- "Sarcophagus of Korbu"
	evt.SetNPCTopic{NPC = 62, Index = 1, Event = 739}         -- "Lathean" : "Promote Vampires"
end
-- "Quest"
evt.global[103] = function()
	if evt.Cmp{"QBits", Value = 27} then         -- Skeleton Transformer Destroyed.
		evt.SetMessage{Str = 168}         -- "Excellent work! With the Skeleton Transformer destroyed, I am more than confident that the light of righteousness will cleanse Shadowspire of evil. The Necromancers' Guild is as good as no more.As I agreed, you may now consider the Temple of the Sun an ally against the elemental cataclysm. I myself will sit on your alliance council in Ravenshore. I will make my departure arrangements with all due haste."
		evt.Subtract{"QBits", Value = 26}         -- "Find the skeleton transformer in the Shadowspire Necromancers' Guild. Destroy it and return to Oskar Tyre."
		evt.Subtract{"QBits", Value = 14}         -- "Form an alliance with the Necromancers' Guild in Shadowspire."
		evt.Subtract{"QBits", Value = 15}         -- "Form an alliance with the Temple of the Sun in Murmurwoods."
		evt.Subtract{"QBits", Value = 28}         -- "Bring the Nightshade Brazier to the Necromancers' Guild leader, Sandro. The Brazier is in the Temple of the Sun."
		evt.Add{"QBits", Value = 20}         -- Allied with Temple of the Sun. Destroy the Skeleton Transformer done.
		evt.SetNPCTopic{NPC = 33, Index = 0, Event = 0}         -- "Oskar Tyre"
		evt.Add{"History9", Value = 0}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(10000)}
		evt.ForPlayer("All")
		evt.Add{"Awards", Value = 11}         -- "Formed and alliance with the Temple of the Sun."
	elseif evt.Cmp{"QBits", Value = 26} then         -- "Find the skeleton transformer in the Shadowspire Necromancers' Guild. Destroy it and return to Oskar Tyre."
		evt.SetMessage{Str = 167}         -- "You come here again with talk of alliance? I have told you what you must do. Go to the Necromancers' Guild in Shadowspire, find Dyson Leland and help him to destroy their Skeleton Transformer!"
	else
		evt.SetMessage{Str = 166}         -- "Then again, we could spare some resources for your alliance if the war would turn in our favor. Perhaps you could be our agent of fortune?Inside the Necromancers' Guild is a device known as the ""Skeleton Transformer."" It converts living creatures into the skeletons which the dark mages use for the bulk of their reinforcements. If it were destroyed, we would quickly have the upper hand.We have an agent, Dyson Leland, placed in their guild. Find him and help him to wreck their skeleton making device. Do this and I will consider your request more favorably."
		evt.Add{"QBits", Value = 26}         -- "Find the skeleton transformer in the Shadowspire Necromancers' Guild. Destroy it and return to Oskar Tyre."
	end
end
-- "Quest"
evt.global[107] = function()
	if evt.Cmp{"QBits", Value = 37} then         -- Regnan Pirate Fleet is sunk.
		evt.SetMessage{Str = 173}         -- "Your good work sinking the Regnan fleet has already had the desired results. Just yesterday morning, Catherine and Roland Ironfist arrived along with their sage, Xanthor. With them in the alliance, we are made stronger--immeasurably so.I will admit that the time of this crisis has contained some of my darkest moments. Thanks to your efforts I believe that the worst of this is over. I have hopes that we will indeed survive this."
		evt.Subtract{"QBits", Value = 36}         -- "Sink the Regnan Fleet. Return to the Ravenshore council chamber."
		evt.Add{"QBits", Value = 38}         -- Quest 36 is done.
		evt.SetNPCTopic{NPC = 40, Index = 0, Event = 109}         -- "Elgar Fellmoon" : "Xanthor"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(100000)}
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(10000)}
		evt.ForPlayer("All")
		evt.Add{"Awards", Value = 12}         -- "Sunk the Regnan fleet allowing Roland and Catherine Ironfist to join the alliance."
	elseif evt.Cmp{"QBits", Value = 36} then         -- "Sink the Regnan Fleet. Return to the Ravenshore council chamber."
		evt.SetMessage{Str = 174}         -- "You must sink that Regnan fleet! It is imperative that the Ironfists be allowed to land safely. Their sage Xanthor has knowledge of the crisis that we cannot do without."
	else
		evt.SetMessage{Str = 172}         -- "Our sources believe the main Regnan fleet is in a hidden port somewhere on Regna Island. If you could sink the fleet in dock you could greatly cripple their ability to patrol the seas off our shore. Unfortunately, we don't have a fleet of our own strong enough to make a landing on Regna.Brekish Onefang has gotten message to us that the Regnans have built an outpost on an atoll off the main Dagger Wound Island. He believes this outpost is resupplied by mysterious means. His scouts never see ships land there, but they are always well stocked. Perhaps you should go there and solve the mystery. Perhaps the answer will convey you to Regna?Regardless of the means, the Regnan fleet must be sunk if the Ironfists are to land in Ravenshore."
		evt.Add{"QBits", Value = 36}         -- "Sink the Regnan Fleet. Return to the Ravenshore council chamber."
		evt.Add{"History12", Value = 0}
	end
end
-- "Release Shalwend"
evt.global[167] = function()
	if not evt.Cmp{"QBits", Value = 51} then         -- Quest 50 done.
		goto _5
	end
	if not evt.Cmp{"QBits", Value = 53} then         -- Quest 52 done.
		goto _5
	end
	if not evt.Cmp{"QBits", Value = 49} then         -- Quest 48 done.
		goto _5
	end
	evt.SetMessage{Str = 883}         --[[ "Thank you for releasing me. Know that Shalwend, Lord of Air, holds you in his favor. I go now to restore order to my realm and to join with my fellow lords to do what I can for yours. Be warned! Our actions will destabilize the crystal gateway. Leave now for your home, lest you be trapped here forever.
Inform Xanthor of what has happened here. Farewell" ]]
	evt.Add{"QBits", Value = 56}         -- All Lords from quests 48, 50, 52, 54 rescued.
	evt.Add{"History17", Value = 0}
::_10::
	evt.SetNPCTopic{NPC = 26, Index = 0, Event = 0}         -- "Shalwend"
	evt.MoveNPC{NPC = 26, HouseId = 0}         -- "Shalwend"
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(100000)}
	evt.ForPlayer(0)
	evt.Add{"Gold", Value = calculateGold(10000)}
	evt.ForPlayer("All")
	evt.Subtract{"QBits", Value = 54}         -- "Rescue Shalwend, Lord of Air."
	evt.Add{"QBits", Value = 55}         -- Quest 54 done.
	evt.Add{"Awards", Value = 14}         -- "Rescued Shalwend, Lord of Air."
	do return end
::_5::
	evt.SetMessage{Str = 608}         -- "Thank you for releasing me. I go now to restore order to my realm and to do what I can for yours. Know that Shalwend, Lord of Air, holds you in his favor. Farewell."
	goto _10
end
-- "Release Acwalander"
evt.global[168] = function()
	if not evt.Cmp{"QBits", Value = 51} then         -- Quest 50 done.
		goto _5
	end
	if not evt.Cmp{"QBits", Value = 55} then         -- Quest 54 done.
		goto _5
	end
	if not evt.Cmp{"QBits", Value = 49} then         -- Quest 48 done.
		goto _5
	end
	evt.SetMessage{Str = 884}         -- """The Destroyer"" is a fitting moniker for one who would imprison me in such a fashion. If it were not for you, I, Acwalander, Lord of Water, would have soon perished. My passing would have had an unbalancing effect across all the planes. Thank you. I go now to gather with the other lords. Together we will set things right. Be warned! Our actions will destabilize the crystal gateway. Leave now for your home, lest you be trapped here forever. Inform Xanthor of what has happened here. Farewell."
	evt.Add{"QBits", Value = 56}         -- All Lords from quests 48, 50, 52, 54 rescued.
	evt.Add{"History17", Value = 0}
::_10::
	evt.SetNPCTopic{NPC = 24, Index = 0, Event = 0}         -- "Acwalander"
	evt.MoveNPC{NPC = 24, HouseId = 0}         -- "Acwalander"
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(100000)}
	evt.ForPlayer(0)
	evt.Add{"Gold", Value = calculateGold(10000)}
	evt.ForPlayer("All")
	evt.Subtract{"QBits", Value = 52}         -- "Rescue Acwalander, Lord of Water."
	evt.Add{"QBits", Value = 53}         -- Quest 52 done.
	evt.Add{"Awards", Value = 15}         -- "Rescued Acwalander, Lord of Water."
	do return end
::_5::
	evt.SetMessage{Str = 609}         -- """The Destroyer"" is a fitting moniker for one who would imprison me in such a fashion. If it were not for you, I, Acwalander, Lord of Water, would have soon perished. My passing would have had an unbalancing effect across all the planes. Thank you. I go now to set things right."
	goto _10
end
-- "Release Gralkor"
evt.global[169] = function()
	if not evt.Cmp{"QBits", Value = 55} then         -- Quest 54 done.
		goto _5
	end
	if not evt.Cmp{"QBits", Value = 53} then         -- Quest 52 done.
		goto _5
	end
	if not evt.Cmp{"QBits", Value = 49} then         -- Quest 48 done.
		goto _5
	end
	evt.SetMessage{Str = 885}         -- "I am free! Now will he who was fool enough to jail me--this Destroyer--feel my wrath. That I, the Lord of Earth, am called ""Gralkor the Cruel"" is no mistake. The suffering I have felt will be his returned in multitudes!I go now to gather with the other lords. Together we will set things right. Be warned! Our actions will destabilize the crystal gateway. Leave now for your home, lest you be trapped here forever. Inform Xanthor of what has happened here. Farewell"
	evt.Add{"QBits", Value = 56}         -- All Lords from quests 48, 50, 52, 54 rescued.
	evt.Add{"History17", Value = 0}
::_10::
	evt.SetNPCTopic{NPC = 25, Index = 0, Event = 0}         -- "Gralkor the Cruel"
	evt.MoveNPC{NPC = 25, HouseId = 0}         -- "Gralkor the Cruel"
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(100000)}
	evt.ForPlayer(0)
	evt.Add{"Gold", Value = calculateGold(10000)}
	evt.ForPlayer("All")
	evt.Subtract{"QBits", Value = 50}         -- "Rescue Gralkor the Cruel, Lord of Earth."
	evt.Add{"QBits", Value = 51}         -- Quest 50 done.
	evt.Add{"Awards", Value = 16}         -- "Rescued Gralkor the Cruel, Lord of Earth."
	do return end
::_5::
	evt.SetMessage{Str = 610}         -- "I am free! Now will he who was fool enough to jail me--this Destroyer--feel my wrath. That I, the Lord of Earth, am called ""Gralkor the Cruel"" is no mistake. The suffering I have felt will be his returned in multitudes!"
	goto _10
end
-- "Release Pyrannaste"
evt.global[170] = function()
	if not evt.Cmp{"QBits", Value = 51} then         -- Quest 50 done.
		goto _5
	end
	if not evt.Cmp{"QBits", Value = 53} then         -- Quest 52 done.
		goto _5
	end
	if not evt.Cmp{"QBits", Value = 55} then         -- Quest 54 done.
		goto _5
	end
	evt.SetMessage{Str = 886}         --[[ "Free at last. My torment is over, but what of my subjects? I know the Destroyer has them compelled to a terrible task. My presence will sooth them. I must go to restore order to my realm and yours.Before I return to the Plane of Fire, I will gather with the other lords. Together we will set things right. Be warned! Our actions will destabilize the crystal gateway. Leave now for your home, lest you be trapped here forever.
Inform Xanthor of what has happened here. Farewell" ]]
	evt.Add{"QBits", Value = 56}         -- All Lords from quests 48, 50, 52, 54 rescued.
	evt.Add{"History17", Value = 0}
::_10::
	evt.SetNPCTopic{NPC = 23, Index = 0, Event = 0}         -- "Pyrannaste"
	evt.MoveNPC{NPC = 23, HouseId = 0}         -- "Pyrannaste"
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(100000)}
	evt.ForPlayer(0)
	evt.Add{"Gold", Value = calculateGold(10000)}
	evt.ForPlayer("All")
	evt.Subtract{"QBits", Value = 48}         -- "Rescue Pyrannaste, Lord of Fire."
	evt.Add{"QBits", Value = 49}         -- Quest 48 done.
	evt.Add{"Awards", Value = 17}         -- "Rescued Pyrannaste, Lord of Fire."
	do return end
::_5::
	evt.SetMessage{Str = 611}         -- "Free at last. My torment is over, but what of my subjects? I know the Destroyer has them compelled to a terrible task. My presence will sooth them. I must go. I must…farewell…"
	goto _10
end
-- "Do you have the antidote?"
evt.global[178] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 616} then         -- "Anointed Herb Potion"
		evt.SetMessage{Str = 623}         --[[ "Thank you!
I will go introduce this to the water supply!" ]]
		evt.Subtract{"Inventory", Value = 616}         -- "Anointed Herb Potion"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(7500)}
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(2000)}
		evt.ForPlayer("All")
		evt.Subtract{"QBits", Value = 109}         -- "Find and return an Anointed Potion to Languid in the Dagger Wound Islands."
		evt.Subtract{"QBits", Value = 245}         -- Annointed Herb Potion - I lost it!
		evt.Add{"QBits", Value = 110}         -- Poison removed from water supply!
		evt.Add{"QBits", Value = 1552}         -- Brought the Annointed Herb Potion to Languid on the Dagger Wound Islands.
		evt.SetNPCTopic{NPC = 66, Index = 0, Event = 0}         -- "Languid"
	else
		evt.SetMessage{Str = 745}         -- "Without the Anointed Herb Potion we cannot remove the poison from our water supply!"
	end
end
evt.global[181] = function()
	if not evt.CheckItemsCount{MinItemIndex = 200, MaxItemIndex = 204, Count = 4} then         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif not evt.CheckItemsCount{MinItemIndex = 205, MaxItemIndex = 209, Count = 2} then         -- "Phima Root"..."Dragon Turtle Fang"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif evt.CheckItemsCount{MinItemIndex = 210, MaxItemIndex = 214, Count = 1} then         -- "Poppy Pod"..."Unicorn Horn"
		evt.SetMessage{Str = 626}         --[[ "The ingredients!
Thank you!
Take this as a reward!" ]]
		evt.RemoveItems{MinItemIndex = 200, MaxItemIndex = 204, Count = 4}         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.RemoveItems{MinItemIndex = 205, MaxItemIndex = 209, Count = 2}         -- "Phima Root"..."Dragon Turtle Fang"
		evt.RemoveItems{MinItemIndex = 210, MaxItemIndex = 214, Count = 1}         -- "Poppy Pod"..."Unicorn Horn"
		evt.Subtract{"QBits", Value = 113}         -- "Bring Thistle on the Dagger Wound Islands the basic ingredients for a potion of Pure Speed."
		evt.Add{"QBits", Value = 114}         -- returned ingredients for a potion of Pure Speed
		evt.Add{"Inventory", Value = 265}         -- "Pure Speed"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(1000)}
		evt.SetNPCTopic{NPC = 68, Index = 2, Event = 0}         -- "Thistle"
	else
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	end
end
-- "Do you have the Idol?"
evt.global[183] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 630} then         -- "Idol of the Snake"
		evt.SetMessage{Str = 628}         --[[ "Thank you for returning with the Idol.
Upon further study I discovered that the entire spell was useless.
Still, this is not your fault and you deserve some reward for returning to me!" ]]
		evt.ForPlayer("All")
		evt.Subtract{"Inventory", Value = 630}         -- "Idol of the Snake"
		evt.Add{"Experience", Value = calculateExp(7500)}
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(2000)}
		evt.ForPlayer("All")
		evt.Subtract{"QBits", Value = 111}         -- "Bring Hiss on the Dagger Wound Islands the Idol of the Snake from the Abandoned Temple."
		evt.Add{"QBits", Value = 112}         -- Found Idol of the Snake
		evt.Add{"QBits", Value = 1549}         -- Recovered Idol of the Snake for Hiss of Blood Drop village.
		evt.SetNPCTopic{NPC = 69, Index = 0, Event = 0}         -- "Hiss"
	else
		evt.SetMessage{Str = 746}         --[[ "Where is the Idol?
Do not waste my time unless you have it!" ]]
	end
end
evt.global[186] = function()
	evt.SetMessage{Str = 753}         --[[ "You have killed all of the dire wolves in the region!
Travelers are once again safe. However, I now find myself in need of a new business!" ]]
	evt.Add{"Gold", Value = calculateGold(2500)}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(7500)}
	evt.Subtract{"QBits", Value = 139}         -- "Kill all Dire Wolves in Ravenshore. Return to Maddigan in Ravenshore."
	evt.Add{"QBits", Value = 1553}         -- Killed all of the Dire Wolves in the Ravenshore area.
	evt.SetNPCTopic{NPC = 71, Index = 0, Event = 0}         -- "Maddigan the Tracker"
end
-- "Quest"
evt.global[187] = function()
	if evt.Cmp{"QBits", Value = 120} then         -- Rescued Smuggler Leader's Familly 
		evt.SetMessage{Str = 755}         --[[ "My family returned and told me of how you rescued them.
Tell the Merchants of Alvar, that they no longer need rely upon our ""bargain.""
I will keep my word to them and to you, my boats will always be at your service!" ]]
		evt.Subtract{"QBits", Value = 120}         -- Rescued Smuggler Leader's Familly 
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(15000)}
		evt.Add{"QBits", Value = 1551}         -- Rescued Irabelle Hunter from the Ogre Fortress in Alvar.
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(10000)}
		evt.SetNPCTopic{NPC = 4, Index = 2, Event = 0}         -- "Arion Hunter"
	else
		evt.SetMessage{Str = 632}         --[[ "The Merchants of Alvar took my family into what they termed ""protective custody"" and use this as the means to secure my services. However as the caravan with my family was returning to Alvar, they were attacked by Ogres and bandits.
The Ogre Zog, took my family from them!
He took them to his fortress in the Alvar region.
Now, I am to spy on the Merchants of Alvar for him.
As long as I do so, my family lives.
If I stop, they die.
Can you rescue them for me?" ]]
		evt.Add{"QBits", Value = 119}         -- "Rescue Arion Hunter's daughter from Ogre Fortress in Alvar."
	end
end
evt.global[189] = function()
	evt.SetMessage{Str = 634}         --[[ "You delivered the report to Stanley?
This is will at least buy us sometime before he becomes suspicious of the activities here in Ravenshore and those of the Merchants in Alvar." ]]
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(10000)}
	evt.SetNPCTopic{NPC = 4, Index = 1, Event = 299}         -- "Arion Hunter" : "Fate of Jadame"
end
-- "Eclipse"
evt.global[194] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 516} then         -- "Eclipse"
		evt.SetMessage{Str = 639}         --[[ "You have recovered the shield, Eclipse?
The Temple is grateful for you help in recovering this potent artifact.
Please, continue to carry the shield with our blessing." ]]
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(25000)}
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(2000)}
		evt.ForPlayer("All")
		evt.Subtract{"QBits", Value = 127}         -- "Recover the shield, Eclipse, for Lathius in Ravenshore."
		evt.Subtract{"QBits", Value = 283}         -- Eclipse - I lost it!
		evt.Add{"QBits", Value = 128}         -- Recovered the the Shield, Eclipse for Lathius
		evt.Add{"QBits", Value = 1550}         -- Found the shield Eclipse.
		evt.SetNPCTopic{NPC = 73, Index = 0, Event = 703}         -- "Lathius" : "Use Eclipse well!"
	else
		evt.SetMessage{Str = 757}         --[[ "Where is Eclipse?
Return to me when you have found the shield!" ]]
	end
end
-- "Quest"
evt.global[198] = function()
	if evt.Cmp{"QBits", Value = 130} then         -- Killed all Ogres in Alvar canyon area and in Ogre Fortress
		evt.SetMessage{Str = 645}         --[[ "Excellent!
Now that the Ogres are cleared from the roads and no longer inhabit the fortress, the roads to Ravenshore, Ironsand and Murmurwoods are safe again!
Please take this 5000 gold as reward!" ]]
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(5000)}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.Add{"AutonotesBits", Value = 500}         -- "Killed all of the Ogres in the Alvar region."
		evt.Subtract{"QBits", Value = 129}         -- "Kill all Ogres in the Alvar canyon area and in Ogre Fortress and return to Keldon in Alvar."
		evt.SetNPCTopic{NPC = 76, Index = 0, Event = 200}         -- "Keldon" : "It's safe to travel again!"
	elseif evt.Cmp{"QBits", Value = 129} then         -- "Kill all Ogres in the Alvar canyon area and in Ogre Fortress and return to Keldon in Alvar."
		evt.SetMessage{Str = 644}         --[[ "You have not defeated all of the Ogres!
The roads will not be safe until they are destroyed!" ]]
	else
		evt.SetMessage{Str = 643}         --[[ "The forces of the Ogre Mage, Zog moved into this area right around the time that the bright flash traveled across the night sky.
They harass and even kill travelers who seek to reach the city of Alvar. It would be of great service to Alvar if you were to eliminate all of the Ogres that harass the roads to Alvar and the Ogres in the fortress near the city of Alvar.
Return to me when you have killed all of the ogres in this region, and I will reward you." ]]
		evt.Add{"QBits", Value = 129}         -- "Kill all Ogres in the Alvar canyon area and in Ogre Fortress and return to Keldon in Alvar."
	end
end
evt.global[203] = function()
	if not evt.CheckItemsCount{MinItemIndex = 200, MaxItemIndex = 204, Count = 2} then         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif not evt.CheckItemsCount{MinItemIndex = 205, MaxItemIndex = 209, Count = 3} then         -- "Phima Root"..."Dragon Turtle Fang"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif evt.CheckItemsCount{MinItemIndex = 210, MaxItemIndex = 214, Count = 3} then         -- "Poppy Pod"..."Unicorn Horn"
		evt.SetMessage{Str = 648}         --[[ "Excellent!
With this I can brew another Potion of Pure Luck.
Take this potion as your reward!" ]]
		evt.RemoveItems{MinItemIndex = 200, MaxItemIndex = 204, Count = 2}         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.RemoveItems{MinItemIndex = 205, MaxItemIndex = 209, Count = 3}         -- "Phima Root"..."Dragon Turtle Fang"
		evt.RemoveItems{MinItemIndex = 210, MaxItemIndex = 214, Count = 3}         -- "Poppy Pod"..."Unicorn Horn"
		evt.Subtract{"QBits", Value = 115}         -- "Bring Rihansi in Alvar the basic ingredients for a potion of Pure Luck."
		evt.Add{"QBits", Value = 116}         -- returned ingredients for a potion of Pure Luck
		evt.Add{"Inventory", Value = 264}         -- "Pure Luck"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.SetNPCTopic{NPC = 74, Index = 2, Event = 0}         -- "Rihansi"
	else
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	end
end
evt.global[212] = function()
	if not evt.CheckItemsCount{MinItemIndex = 200, MaxItemIndex = 204, Count = 2} then         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif not evt.CheckItemsCount{MinItemIndex = 205, MaxItemIndex = 209, Count = 4} then         -- "Phima Root"..."Dragon Turtle Fang"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif evt.CheckItemsCount{MinItemIndex = 210, MaxItemIndex = 214, Count = 1} then         -- "Poppy Pod"..."Unicorn Horn"
		evt.SetMessage{Str = 648}         --[[ "Excellent!
With this I can brew another Potion of Pure Luck.
Take this potion as your reward!" ]]
		evt.RemoveItems{MinItemIndex = 200, MaxItemIndex = 204, Count = 2}         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.RemoveItems{MinItemIndex = 205, MaxItemIndex = 209, Count = 4}         -- "Phima Root"..."Dragon Turtle Fang"
		evt.RemoveItems{MinItemIndex = 210, MaxItemIndex = 214, Count = 1}         -- "Poppy Pod"..."Unicorn Horn"
		evt.Subtract{"QBits", Value = 121}         -- "Bring Talion in the Ironsand Desert the basic ingredients for a potion of Pure Endurance."
		evt.Add{"QBits", Value = 122}         -- returned ingredients for a potion of Pure Endurance
		evt.Add{"Inventory", Value = 267}         -- "Pure Endurance"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.SetNPCTopic{NPC = 78, Index = 2, Event = 0}         -- "Talion"
	else
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	end
end
-- "Poison!"
evt.global[214] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 636} then         -- "Dragonbane Flower"
		evt.Add{"QBits", Value = 151}         -- Found Dragonbane for Dragon Hunters
		evt.Subtract{"QBits", Value = 150}         -- "Find a Dragonbane Flower for Calindril in Garrote Gorge."
		evt.Subtract{"Inventory", Value = 636}         -- "Dragonbane Flower"
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(1500)}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.Add{"AutonotesBits", Value = 501}         -- "Found the Dragonbane flower for Calindril in the Garrote Gorge Dragon Hunter's Fort."
		evt.SetMessage{Str = 771}         --[[ "The Dragons of Garrote Gorge are susceptible to a poison that can be distilled from the rare dragonbane flower.
The flower also is the only means of an antidote for the Dragons." ]]
		evt.SetNPCTopic{NPC = 87, Index = 0, Event = 215}         -- "Calindril" : "Thanks for your help!"
	else
		evt.SetMessage{Str = 659}         --[[ "I asked for the Dragonbane Flower and you return empty handed.
Why waste my time?" ]]
	end
end
-- "Poison!"
evt.global[217] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 636} then         -- "Dragonbane Flower"
		evt.Add{"QBits", Value = 153}         -- Found Dragonbane for Dragons
		evt.Subtract{"QBits", Value = 152}         -- "Find a Dragonbane Flower for the Balion Tearwing in the Garrote Gorge Dragon Caves."
		evt.Subtract{"Inventory", Value = 636}         -- "Dragonbane Flower"
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(1500)}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.Add{"AutonotesBits", Value = 502}         -- "Found the Dragonbane flower for Balion Tearwing in Garrote Gorge."
		evt.SetMessage{Str = 771}         --[[ "The Dragons of Garrote Gorge are susceptible to a poison that can be distilled from the rare dragonbane flower.
The flower also is the only means of an antidote for the Dragons." ]]
		evt.SetNPCTopic{NPC = 89, Index = 0, Event = 218}         -- "Balion Tearwing" : "Thanks for your help!"
	else
		evt.SetMessage{Str = 662}         --[[ "I asked for the Dragonbane Flower and you return empty handed.
Why waste my time?" ]]
	end
end
evt.global[219] = function()
	if evt.Cmp{"QBits", Value = 155} then         -- Killed all Dragons in Garrote Gorge Area
		evt.Subtract{"QBits", Value = 154}         -- "Kill all the Dragons in the Garrote Gorge wilderness area. Return to Avalon in Garrote Gorge."
		evt.SetMessage{Str = 772}         --[[ "With all of the Dragons in the wilderness defeated, we can move on the Dragon Cave and eliminate the Dragons once and for all!
Thanks again for your help in defeating them." ]]
		evt.Add{"Gold", Value = calculateGold(2500)}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(20000)}
		evt.Add{"AutonotesBits", Value = 503}         -- "Killed all of the Dragons in the Garrote Gorge area for Avalon in the Garrote Gorge Dragon Hunter's Fort."
		evt.SetNPCTopic{NPC = 90, Index = 0, Event = 220}         -- "Avalon" : "At last!"
	elseif evt.Cmp{"QBits", Value = 154} then         -- "Kill all the Dragons in the Garrote Gorge wilderness area. Return to Avalon in Garrote Gorge."
		evt.SetMessage{Str = 532}         --[[ "You have not slain all of the vermin.
I have reports here that tell of Dragons still in the region.
Return when you have slain them all!" ]]
	else
		evt.SetMessage{Str = 664}         --[[ "You seek to gain the favor of Charles Quixote?
Help us in his crusade against the Dragons of Garrote Gorge. If all of the Dragons in the region and in the Dragon Cave are slain, Charles Quixote will be sure to hear of your name! Return to me when they are all dead!
I will reward you well." ]]
		evt.Add{"QBits", Value = 154}         -- "Kill all the Dragons in the Garrote Gorge wilderness area. Return to Avalon in Garrote Gorge."
	end
end
evt.global[221] = function()
	if evt.Cmp{"QBits", Value = 158} then         -- Killed all Dragon Hunters in Garrote Gorge wilderness area
		evt.SetMessage{Str = 773}         --[[ "With all of the Dragon hunters in the wilderness defeated, we can move on their camp and eliminate them once and for all!
Thanks again for your help in defeating them." ]]
		evt.Add{"Gold", Value = calculateGold(2500)}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(20000)}
		evt.Add{"AutonotesBits", Value = 504}         -- "Killed all of the Dragon Hunters in the Garrote Gorge are for Jerin Flame-eye in the Dragon Cave of Garrote Gorge."
		evt.Subtract{"QBits", Value = 157}         -- "Kill all the Dragon Hunter's in the Garrote Gorge wilderness area. Return to Jerin Flame-eye in the Garrote Gorge Dragon Caves."
		evt.SetNPCTopic{NPC = 91, Index = 0, Event = 222}         -- "Jerin Flame-eye" : "Land is ours yet again!"
	elseif evt.Cmp{"QBits", Value = 157} then         -- "Kill all the Dragon Hunter's in the Garrote Gorge wilderness area. Return to Jerin Flame-eye in the Garrote Gorge Dragon Caves."
		evt.SetMessage{Str = 533}         --[[ "You have not slain all of the Dragon hunters.
A Flight returned just moments ago and reported seeing them out on the plains.
Return when you have slain them all!" ]]
	else
		evt.SetMessage{Str = 666}         --[[ "You seek the favor of Deftclaw Redreaver?
Don't we all?
If you were to kill all of the Dragon hunters in the Garrote Gorge wilderness, I would be certain to mention you to him.
I would also be in the position to offer you a generous reward!" ]]
		evt.Add{"QBits", Value = 157}         -- "Kill all the Dragon Hunter's in the Garrote Gorge wilderness area. Return to Jerin Flame-eye in the Garrote Gorge Dragon Caves."
	end
end
-- "Where is the drum?"
evt.global[225] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 615} then         -- "Drum of Victory"
		evt.SetMessage{Str = 670}         --[[ "You have returned with the Drum of Victory!
Charles will be grateful for its return!
Here is your promised reward." ]]
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(1500)}
		evt.ForPlayer("All")
		evt.Subtract{"QBits", Value = 160}         -- "Find the Legendary Drum of Victory. Return it to Zelim in Garrote Gorge."
		evt.Subtract{"QBits", Value = 246}         -- Drum of Victory - I lost it!
		evt.Subtract{"Inventory", Value = 615}         -- "Drum of Victory"
		evt.Add{"Experience", Value = calculateExp(20000)}
		evt.SetNPCTopic{NPC = 92, Index = 0, Event = 0}         -- "Zelim"
	else
		evt.SetMessage{Str = 774}         --[[ "Return when you have the Drum of Victory.
You waste your time and mine otherwise!" ]]
	end
end
-- "Great!"
evt.global[228] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 637} then         -- "Bone of Doom"
		evt.SetMessage{Str = 673}         --[[ "Ah, the Bone of Doom!
The legend of Zacharia will continue!
Here is your reward!" ]]
		evt.Add{"Gold", Value = calculateGold(1500)}
		evt.Subtract{"QBits", Value = 166}         -- "Find the Bone of Doom for Tantilion of Shadowspire."
		evt.Subtract{"QBits", Value = 247}         -- Bone of Doom - I lost it!
		evt.ForPlayer("All")
		evt.Subtract{"Inventory", Value = 637}         -- "Bone of Doom"
		evt.Add{"Experience", Value = calculateExp(7500)}
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(7500)}
		evt.SetNPCTopic{NPC = 93, Index = 0, Event = 0}         -- "Tantilion"
	else
		evt.SetMessage{Str = 775}         -- "I ask for the Bone, and you return with nothing. Be gone!"
	end
end
-- "Hours of Enjoyment!"
evt.global[231] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 613} then         -- "Puzzle Box"
		evt.SetMessage{Str = 676}         --[[ "The Puzzle Box is mine!
Hours of mindless enjoyment at my finger tips!
Here, take you reward for it is nothing compared to the box!" ]]
		evt.Add{"Gold", Value = calculateGold(1500)}
		evt.Subtract{"QBits", Value = 162}         -- "Find Iseldir's Puzzle Box for Benefice of Shadowspire."
		evt.Subtract{"QBits", Value = 249}         -- Puzzle Box - I lost it!
		evt.ForPlayer("All")
		evt.Subtract{"Inventory", Value = 613}         -- "Puzzle Box"
		evt.Add{"Experience", Value = calculateExp(15000)}
		evt.SetNPCTopic{NPC = 94, Index = 0, Event = 0}         -- "Benefice"
	else
		evt.SetMessage{Str = 776}         -- "I need not see you again until you have the Puzzle Box!"
	end
end
evt.global[234] = function()
	if not evt.CheckItemsCount{MinItemIndex = 200, MaxItemIndex = 204, Count = 1} then         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif not evt.CheckItemsCount{MinItemIndex = 205, MaxItemIndex = 209, Count = 2} then         -- "Phima Root"..."Dragon Turtle Fang"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif evt.CheckItemsCount{MinItemIndex = 210, MaxItemIndex = 214, Count = 4} then         -- "Poppy Pod"..."Unicorn Horn"
		evt.SetMessage{Str = 679}         --[[ "You have returned with the ingredients, holding up you end of the bargain.
Here is your Potion of Pure Intellect." ]]
		evt.RemoveItems{MinItemIndex = 200, MaxItemIndex = 204, Count = 1}         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.RemoveItems{MinItemIndex = 205, MaxItemIndex = 209, Count = 2}         -- "Phima Root"..."Dragon Turtle Fang"
		evt.RemoveItems{MinItemIndex = 210, MaxItemIndex = 214, Count = 4}         -- "Poppy Pod"..."Unicorn Horn"
		evt.Subtract{"QBits", Value = 123}         -- "Bring Kelvin in Shadowspire the basic ingredients for a potion of Pure Intellect."
		evt.Add{"QBits", Value = 124}         -- returned ingredients for a potion of Pure Intellect
		evt.Add{"Inventory", Value = 266}         -- "Pure Intellect"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.SetNPCTopic{NPC = 83, Index = 2, Event = 0}         -- "Kelvin"
	else
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	end
end
-- "Do you have the vial?"
evt.global[237] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 614} then         -- "Vial of Grave Earth"
		evt.SetMessage{Str = 682}         --[[ "Ah, once we perform the Rites of Purification upon this dirt, Korbu will rest eternally.
We are in your debt and here is your reward as promised!" ]]
		evt.ForPlayer(0)
		evt.Add{"Gold", Value = calculateGold(1500)}
		evt.ForPlayer("All")
		evt.Subtract{"Inventory", Value = 614}         -- "Vial of Grave Earth"
		evt.Subtract{"QBits", Value = 164}         -- "Find a Vial of Grave Dirt. Return it to Halien in Shadowspire."
		evt.Subtract{"QBits", Value = 248}         -- Vial of Grave Dirt - I lost it!
		evt.Add{"Experience", Value = calculateExp(22000)}
		evt.SetNPCTopic{NPC = 95, Index = 0, Event = 0}         -- "Hallien"
	else
		evt.SetMessage{Str = 931}         --[[ "Where is the Vial of Grave Dirt?
Do not bother me until you have it!" ]]
	end
end
evt.global[240] = function()
	if not evt.CheckItemsCount{MinItemIndex = 200, MaxItemIndex = 204, Count = 1} then         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif not evt.CheckItemsCount{MinItemIndex = 205, MaxItemIndex = 209, Count = 4} then         -- "Phima Root"..."Dragon Turtle Fang"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif evt.CheckItemsCount{MinItemIndex = 210, MaxItemIndex = 214, Count = 2} then         -- "Poppy Pod"..."Unicorn Horn"
		evt.SetMessage{Str = 685}         --[[ "Ah, you learned the recipe or are very lucky!
Here is your potion!" ]]
		evt.RemoveItems{MinItemIndex = 200, MaxItemIndex = 204, Count = 1}         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.RemoveItems{MinItemIndex = 205, MaxItemIndex = 209, Count = 4}         -- "Phima Root"..."Dragon Turtle Fang"
		evt.RemoveItems{MinItemIndex = 210, MaxItemIndex = 214, Count = 2}         -- "Poppy Pod"..."Unicorn Horn"
		evt.Subtract{"QBits", Value = 125}         -- "Bring Castigeir in Murmurwoods the basic ingredients for a potion of Pure Personality."
		evt.Add{"QBits", Value = 126}         -- returned ingredients for a potion of Pure Personallity
		evt.Add{"Inventory", Value = 268}         -- "Pure Personality"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.SetNPCTopic{NPC = 88, Index = 2, Event = 0}         -- "Castigeir"
	else
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	end
end
evt.global[246] = function()
	if not evt.CheckItemsCount{MinItemIndex = 200, MaxItemIndex = 204, Count = 2} then         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif not evt.CheckItemsCount{MinItemIndex = 205, MaxItemIndex = 209, Count = 1} then         -- "Phima Root"..."Dragon Turtle Fang"
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	elseif evt.CheckItemsCount{MinItemIndex = 210, MaxItemIndex = 214, Count = 4} then         -- "Poppy Pod"..."Unicorn Horn"
		evt.SetMessage{Str = 691}         -- "Ah, the right ingredients always do the trick! Here is your potion."
		evt.RemoveItems{MinItemIndex = 200, MaxItemIndex = 204, Count = 2}         -- "Widowsweep Berries"..."Phoenix Feather"
		evt.RemoveItems{MinItemIndex = 205, MaxItemIndex = 209, Count = 1}         -- "Phima Root"..."Dragon Turtle Fang"
		evt.RemoveItems{MinItemIndex = 210, MaxItemIndex = 214, Count = 4}         -- "Poppy Pod"..."Unicorn Horn"
		evt.Subtract{"QBits", Value = 133}         -- returned ingredients for a potion of Pure Accuracy
		evt.Add{"QBits", Value = 134}         -- Gave Gem of Restoration to Blazen Stormlance
		evt.Add{"Inventory", Value = 269}         -- "Pure Accuracy"
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.SetNPCTopic{NPC = 77, Index = 2, Event = 0}         -- "Galvinus"
	else
		evt.SetMessage{Str = 684}         --[[ "You are missing all or some of the needed ingredients.
Return when you have them all." ]]
	end
end
-- "Quest"
evt.global[249] = function()
	if evt.Cmp{"QBits", Value = 168} then         -- Found the treasure of the Dread Pirate Stanley!
		evt.Add{"Experience", Value = calculateExp(15500)}
		evt.SetMessage{Str = 694}         --[[ "He who finds the treasure of the Dread Pirate Stanley will be a rich person!
Will that person be you?" ]]
		evt.Subtract{"QBits", Value = 236}         -- "Find the treasure of the Dread Pirate Stanley."
		evt.SetNPCTopic{NPC = 96, Index = 0, Event = 0}         -- "One-Eye"
	else
		evt.SetMessage{Str = 690}         --[[ "You have not found the treasure of the Dread Pirate Stanley!
" ]]
		evt.Add{"QBits", Value = 236}         -- "Find the treasure of the Dread Pirate Stanley."
	end
end
evt.global[290] = function()
	if evt.Cmp{"QBits", Value = 108} then         -- Yellow Fever epidemic cured!
		evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 102} then         -- Delivered cure to hut 1
		evt.SetMessage{Str = 743}         -- "Thanks for the cure! Be sure to deliver scrolls to those who still suffer from the Yellow Fever."
		return
	end
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 373} then         -- "Cure Disease"
		evt.SetMessage{Str = 742}         -- "I am very sick, without a Cure Disease scroll I will surely perish from Yellow Fever!."
		return
	end
	evt.Subtract{"Inventory", Value = 373}         -- "Cure Disease"
	evt.Add{"QBits", Value = 102}         -- Delivered cure to hut 1
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(250)}
	if evt.Cmp{"QBits", Value = 102} then         -- Delivered cure to hut 1
		if evt.Cmp{"QBits", Value = 103} then         -- Delivered cure to hut 2
			if evt.Cmp{"QBits", Value = 104} then         -- Delivered cure to hut 3
				if evt.Cmp{"QBits", Value = 105} then         -- Delivered cure to hut 4
					if evt.Cmp{"QBits", Value = 106} then         -- Delivered cure to hut 5
						if evt.Cmp{"QBits", Value = 107} then         -- Delivered cure to hut 6
							evt.ForPlayer("All")
							evt.Add{"Experience", Value = calculateExp(1500)}
							evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
							evt.Add{"QBits", Value = 108}         -- Yellow Fever epidemic cured!
							return
						end
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 741}         --[[ "Thanks for the cure, but others in the area are still sick!
Be sure to deliver the cure to them as well!" ]]
end
evt.global[291] = function()
	if evt.Cmp{"QBits", Value = 108} then         -- Yellow Fever epidemic cured!
		evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 103} then         -- Delivered cure to hut 2
		evt.SetMessage{Str = 743}         -- "Thanks for the cure! Be sure to deliver scrolls to those who still suffer from the Yellow Fever."
		return
	end
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 373} then         -- "Cure Disease"
		evt.SetMessage{Str = 742}         -- "I am very sick, without a Cure Disease scroll I will surely perish from Yellow Fever!."
		return
	end
	evt.Subtract{"Inventory", Value = 373}         -- "Cure Disease"
	evt.Add{"QBits", Value = 103}         -- Delivered cure to hut 2
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(250)}
	if evt.Cmp{"QBits", Value = 103} then         -- Delivered cure to hut 2
		if evt.Cmp{"QBits", Value = 102} then         -- Delivered cure to hut 1
			if evt.Cmp{"QBits", Value = 104} then         -- Delivered cure to hut 3
				if evt.Cmp{"QBits", Value = 105} then         -- Delivered cure to hut 4
					if evt.Cmp{"QBits", Value = 106} then         -- Delivered cure to hut 5
						if evt.Cmp{"QBits", Value = 107} then         -- Delivered cure to hut 6
							evt.ForPlayer("All")
							evt.Add{"Experience", Value = calculateExp(1500)}
							evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
							evt.Add{"QBits", Value = 108}         -- Yellow Fever epidemic cured!
							return
						end
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 741}         --[[ "Thanks for the cure, but others in the area are still sick!
Be sure to deliver the cure to them as well!" ]]
end
evt.global[292] = function()
	if evt.Cmp{"QBits", Value = 108} then         -- Yellow Fever epidemic cured!
		evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 104} then         -- Delivered cure to hut 3
		evt.SetMessage{Str = 743}         -- "Thanks for the cure! Be sure to deliver scrolls to those who still suffer from the Yellow Fever."
		return
	end
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 373} then         -- "Cure Disease"
		evt.SetMessage{Str = 742}         -- "I am very sick, without a Cure Disease scroll I will surely perish from Yellow Fever!."
		return
	end
	evt.Subtract{"Inventory", Value = 373}         -- "Cure Disease"
	evt.Add{"QBits", Value = 104}         -- Delivered cure to hut 3
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(250)}
	if evt.Cmp{"QBits", Value = 104} then         -- Delivered cure to hut 3
		if evt.Cmp{"QBits", Value = 102} then         -- Delivered cure to hut 1
			if evt.Cmp{"QBits", Value = 103} then         -- Delivered cure to hut 2
				if evt.Cmp{"QBits", Value = 105} then         -- Delivered cure to hut 4
					if evt.Cmp{"QBits", Value = 106} then         -- Delivered cure to hut 5
						if evt.Cmp{"QBits", Value = 107} then         -- Delivered cure to hut 6
							evt.ForPlayer("All")
							evt.Add{"Experience", Value = calculateExp(1500)}
							evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
							evt.Add{"QBits", Value = 108}         -- Yellow Fever epidemic cured!
							return
						end
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 741}         --[[ "Thanks for the cure, but others in the area are still sick!
Be sure to deliver the cure to them as well!" ]]
end
evt.global[293] = function()
	if evt.Cmp{"QBits", Value = 108} then         -- Yellow Fever epidemic cured!
		evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 105} then         -- Delivered cure to hut 4
		evt.SetMessage{Str = 743}         -- "Thanks for the cure! Be sure to deliver scrolls to those who still suffer from the Yellow Fever."
		return
	end
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 373} then         -- "Cure Disease"
		evt.SetMessage{Str = 742}         -- "I am very sick, without a Cure Disease scroll I will surely perish from Yellow Fever!."
		return
	end
	evt.Subtract{"Inventory", Value = 373}         -- "Cure Disease"
	evt.Add{"QBits", Value = 105}         -- Delivered cure to hut 4
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(250)}
	if evt.Cmp{"QBits", Value = 105} then         -- Delivered cure to hut 4
		if evt.Cmp{"QBits", Value = 102} then         -- Delivered cure to hut 1
			if evt.Cmp{"QBits", Value = 103} then         -- Delivered cure to hut 2
				if evt.Cmp{"QBits", Value = 104} then         -- Delivered cure to hut 3
					if evt.Cmp{"QBits", Value = 106} then         -- Delivered cure to hut 5
						if evt.Cmp{"QBits", Value = 107} then         -- Delivered cure to hut 6
							evt.ForPlayer("All")
							evt.Add{"Experience", Value = calculateExp(1500)}
							evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
							evt.Add{"QBits", Value = 108}         -- Yellow Fever epidemic cured!
							return
						end
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 741}         --[[ "Thanks for the cure, but others in the area are still sick!
Be sure to deliver the cure to them as well!" ]]
end
evt.global[294] = function()
	if evt.Cmp{"QBits", Value = 108} then         -- Yellow Fever epidemic cured!
		evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 106} then         -- Delivered cure to hut 5
		evt.SetMessage{Str = 743}         -- "Thanks for the cure! Be sure to deliver scrolls to those who still suffer from the Yellow Fever."
		return
	end
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 373} then         -- "Cure Disease"
		evt.SetMessage{Str = 742}         -- "I am very sick, without a Cure Disease scroll I will surely perish from Yellow Fever!."
		return
	end
	evt.Subtract{"Inventory", Value = 373}         -- "Cure Disease"
	evt.Add{"QBits", Value = 106}         -- Delivered cure to hut 5
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(250)}
	if evt.Cmp{"QBits", Value = 106} then         -- Delivered cure to hut 5
		if evt.Cmp{"QBits", Value = 102} then         -- Delivered cure to hut 1
			if evt.Cmp{"QBits", Value = 103} then         -- Delivered cure to hut 2
				if evt.Cmp{"QBits", Value = 104} then         -- Delivered cure to hut 3
					if evt.Cmp{"QBits", Value = 105} then         -- Delivered cure to hut 4
						if evt.Cmp{"QBits", Value = 107} then         -- Delivered cure to hut 6
							evt.ForPlayer("All")
							evt.Add{"Experience", Value = calculateExp(1500)}
							evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
							evt.Add{"QBits", Value = 108}         -- Yellow Fever epidemic cured!
							return
						end
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 741}         --[[ "Thanks for the cure, but others in the area are still sick!
Be sure to deliver the cure to them as well!" ]]
end
evt.global[295] = function()
	if evt.Cmp{"QBits", Value = 108} then         -- Yellow Fever epidemic cured!
		evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 107} then         -- Delivered cure to hut 6
		evt.SetMessage{Str = 743}         -- "Thanks for the cure! Be sure to deliver scrolls to those who still suffer from the Yellow Fever."
		return
	end
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 373} then         -- "Cure Disease"
		evt.SetMessage{Str = 742}         -- "I am very sick, without a Cure Disease scroll I will surely perish from Yellow Fever!."
		return
	end
	evt.Subtract{"Inventory", Value = 373}         -- "Cure Disease"
	evt.Add{"QBits", Value = 107}         -- Delivered cure to hut 6
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(250)}
	if evt.Cmp{"QBits", Value = 107} then         -- Delivered cure to hut 6
		if evt.Cmp{"QBits", Value = 102} then         -- Delivered cure to hut 1
			if evt.Cmp{"QBits", Value = 103} then         -- Delivered cure to hut 2
				if evt.Cmp{"QBits", Value = 104} then         -- Delivered cure to hut 3
					if evt.Cmp{"QBits", Value = 105} then         -- Delivered cure to hut 4
						if evt.Cmp{"QBits", Value = 106} then         -- Delivered cure to hut 5
							evt.ForPlayer("All")
							evt.Add{"Experience", Value = calculateExp(1500)}
							evt.SetMessage{Str = 621}         --[[ "The Yellow Fever epidemic is over!
Thank you for your help!" ]]
							evt.Add{"QBits", Value = 108}         -- Yellow Fever epidemic cured!
							return
						end
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 741}         --[[ "Thanks for the cure, but others in the area are still sick!
Be sure to deliver the cure to them as well!" ]]
end
evt.global[298] = function()
	evt.SetMessage{Str = 777}         --[[ "You're new aren't you?
Tell Arion Hunter that I expect more of his rabble than the likes of you!
Give me the reports and leave my sight!
You make me sick!" ]]
	evt.Subtract{"QBits", Value = 117}         -- "Deliver fake report to the Dread Pirate Stanley in the Pirate's Rest Tavern on the Island of Regna."
	evt.ForPlayer("All")
	evt.Subtract{"Inventory", Value = 602}         -- "False Report"
	evt.Add{"QBits", Value = 1554}         -- Delivered False Report to the Dread Pirate Stanley for Arion Hunter.
	evt.Subtract{"QBits", Value = 282}         -- False Report - I lost it!
	evt.Add{"Experience", Value = calculateExp(20000)}
	evt.ForPlayer(0)
	evt.Add{"Gold", Value = calculateGold(15000)}
	evt.SetNPCTopic{NPC = 108, Index = 0, Event = 0}         -- "Dread Pirate Stanley"
	evt.MoveNPC{NPC = 108, HouseId = 0}         -- "Dread Pirate Stanley"
end
evt.global[571] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 256} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 256}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 143}         -- Delivered potion to house 1
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(1000)}
	end
	if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
		if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
			if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
				if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
					if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = calculateExp(7500)}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end
evt.global[572] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 256} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 256}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 144}         -- Delivered potion to house 2
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(1000)}
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
			if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
				if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
					if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = calculateExp(1500)}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end
evt.global[573] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 256} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 256}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 145}         -- Delivered potion to house 3
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(1000)}
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
			if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
				if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
					if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = calculateExp(1500)}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end
evt.global[574] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 256} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 256}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 146}         -- Delivered potion to house 4
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(1000)}
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
			if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
				if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
					if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = calculateExp(1500)}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end
evt.global[575] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 256} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 256}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 147}         -- Delivered potion to house 5
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(1000)}
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
			if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
				if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
					if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = calculateExp(1500)}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end
evt.global[576] = function()
	if evt.Cmp{"QBits", Value = 149} then         -- Southern houses of Rust all have Potions of Fire Resistance.
		evt.SetMessage{Str = 654}         --[[ "You have at least pushed our demise away for a time, but a new home needs to be found for us!
Thank you for delivering the Potions of Fire Resistance!" ]]
		return
	end
	if evt.Cmp{"QBits", Value = 148} then         -- Delivered potion to house 6
		evt.SetMessage{Str = 763}         -- "Thanks for the potion!"
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 256} then         -- "Fire Resistance"
			evt.SetMessage{Str = 762}         --[[ "I an defenseless against the onslaught of the sea of fire!
I need a Potion of Fire Resistance!" ]]
			return
		end
		evt.Subtract{"Inventory", Value = 256}         -- "Fire Resistance"
		evt.Add{"QBits", Value = 148}         -- Delivered potion to house 6
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(1000)}
	end
	if evt.Cmp{"QBits", Value = 143} then         -- Delivered potion to house 1
		if evt.Cmp{"QBits", Value = 144} then         -- Delivered potion to house 2
			if evt.Cmp{"QBits", Value = 145} then         -- Delivered potion to house 3
				if evt.Cmp{"QBits", Value = 146} then         -- Delivered potion to house 4
					if evt.Cmp{"QBits", Value = 147} then         -- Delivered potion to house 5
						evt.ForPlayer("All")
						evt.Add{"Experience", Value = calculateExp(1500)}
						evt.SetMessage{Str = 764}         --[[ "Thanks for providing Potions of Fire Resistance to the southernmost houses here in Rust.
Perhaps we can survive until a new home can be found for us!" ]]
						evt.Add{"QBits", Value = 149}         -- Southern houses of Rust all have Potions of Fire Resistance.
						return
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 761}         --[[ "Thanks for the potion, but others in the area are without protection!
Be sure to deliver a potion to them as well!" ]]
end
-- "Bounty!"
evt.global[578] = function()
	if evt.IsTotalBountyInRange{MinGold = 10000, MaxGold = 29999} then
		evt.SetMessage{Str = 779}         -- "You currently hold the rank of Novice Bounty Hunter, but lack sufficient bounty to be promoted to Journeyman."
		if not evt.Cmp{"AutonotesBits", Value = 496} then         -- "Have earned status of Novice Bounty Hunter."
			evt.Add{"AutonotesBits", Value = 496}         -- "Have earned status of Novice Bounty Hunter."
			evt.ForPlayer("All")
			evt.Add{"Experience", Value = calculateExp(40000)}
			evt.Add{"QBits", Value = 169}         -- Named Novice Bounty Hunter by the Guild of Bounty Hunters
		end
		return
	end
	if evt.IsTotalBountyInRange{MinGold = 30000, MaxGold = 69999} then
		evt.SetMessage{Str = 780}         -- "You currently hold the rank of Journeyman Bounty Hunter, but lack sufficient bounty to be promoted to Master."
		if not evt.Cmp{"AutonotesBits", Value = 497} then         -- "Have earned status of Journeyman Bounty Hunter."
			evt.Add{"AutonotesBits", Value = 497}         -- "Have earned status of Journeyman Bounty Hunter."
			evt.ForPlayer("All")
			evt.Add{"Experience", Value = calculateExp(80000)}
			evt.Subtract{"QBits", Value = 169}         -- Named Novice Bounty Hunter by the Guild of Bounty Hunters
			evt.Add{"QBits", Value = 170}         -- Named Journeyman Bounty Hunter by the Guild of Bounty Hunters
			evt.Subtract{"AutonotesBits", Value = 496}         -- "Have earned status of Novice Bounty Hunter."
		end
		return
	end
	if not evt.IsTotalBountyInRange{MinGold = 70000, MaxGold = 1000000} then
		evt.SetMessage{Str = 778}         -- "You have not gathered sufficient bounties to allow us to promote you!"
		return
	end
	evt.SetMessage{Str = 781}         -- "You currently hold the rank of Master Bounty Hunter! This is the highest rank of our guild."
	if not evt.Cmp{"AutonotesBits", Value = 498} then         -- "Have earned status of Master Bounty Hunter."
		evt.Add{"AutonotesBits", Value = 498}         -- "Have earned status of Master Bounty Hunter."
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(1200000)}
		evt.Subtract{"QBits", Value = 170}         -- Named Journeyman Bounty Hunter by the Guild of Bounty Hunters
		evt.Add{"QBits", Value = 171}         -- Named Novice Master Hunter by the Guild of Bounty Hunters
	end
	evt.Subtract{"AutonotesBits", Value = 497}         -- "Have earned status of Journeyman Bounty Hunter."
	evt.SetNPCTopic{NPC = 109, Index = 2, Event = 0}         -- "Bryant Conlan"
	evt.SetNPCTopic{NPC = 110, Index = 2, Event = 0}         -- "Cahalli Evenall"
end
-- "Arcomage Tournament "
evt.global[597] = function()
	if evt.Cmp{"QBits", Value = 174} then         -- Won all Arcomage games
		evt.SetMessage{Str = 542}         --[[ "Congratulations!
You have become the Arcomage Champion!
The prize is waiting in the chest right outside my house." ]]
		evt.Subtract{"QBits", Value = 173}         -- "Win a game of Arcomage in all eleven taverns, then return to Tonk Blueswan in Ravenshore."
		evt.Subtract{"QBits", Value = 174}         -- Won all Arcomage games
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Add{"QBits", Value = 175}         -- Finished ArcoMage Quest - Get the treasure
		evt.Add{"Awards", Value = 41}         -- "Arcomage Champion."
		evt.SetNPCGreeting{NPC = 222, Greeting = 0}         -- "Tonk Blueswan" : ""
		evt.SetNPCTopic{NPC = 222, Index = 1, Event = 0}         -- "Tonk Blueswan"
	elseif evt.Cmp{"QBits", Value = 173} then         -- "Win a game of Arcomage in all eleven taverns, then return to Tonk Blueswan in Ravenshore."
		evt.SetMessage{Str = 541}         --[[ "You must claim a victory at ALL 11 taverns.
Until you do, you cannot be declared Arcomage Champion." ]]
	else
		evt.SetMessage{Str = 540}         --[[ "To be declared Arcomage Champion, you must win a game of Arcomage in every tavern on, in, and under the continent of Jadame.
There are 11 such taverns sponsoring Arcomage events.
When you have accomplished this, return to me to claim the prize." ]]
		evt.Add{"QBits", Value = 173}         -- "Win a game of Arcomage in all eleven taverns, then return to Tonk Blueswan in Ravenshore."
	end
end
-- "Quest"
evt.global[656] = function()
	if not evt.Cmp{"QBits", Value = 176} then         -- "Find a wheel of Frelandeau Cheese. Bring it to Asael Fromago in Alvar."
		evt.SetMessage{Str = 805}         -- "I have traveled to these lands to catalog its array of available cheese. My task is nearly complete, but there are yet three cheeses I have yet to sample. These are Frelandeau, Eldenbrie and Dunduck. I would reward highly any who could locate these rare and reputedly tasty culinary gems for me."
		evt.Add{"QBits", Value = 176}         -- "Find a wheel of Frelandeau Cheese. Bring it to Asael Fromago in Alvar."
		evt.Add{"QBits", Value = 177}         -- "Find a log of Eldenbrie Cheese. Bring it to Asael Fromago in Alvar."
		evt.Add{"QBits", Value = 178}         -- "Find a ball of Dunduck Cheese. Bring it to Asael Fromago in Alvar."
		return
	end
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 658} then         -- "Wheel of Frelandeau"
		if evt.Cmp{"Inventory", Value = 659} then         -- "Log of Eldenbrie"
			if evt.Cmp{"Inventory", Value = 660} then         -- "Ball of Dunduck"
				evt.SetMessage{Str = 808}         -- "Excellent! Give me the cheeses! I must consume them!Ah….munch munch….frelandeau, exquisite….mmmm, and eldenbrie, wondrously smoky…and hmmm, dunduck…well, that's not very nice, is it?You have made my Jadamean cheese cataloging safari a success! I can die a happy man! You have the humble thanks of a man of cheese. And here is your promised reward!"
				evt.ForPlayer(0)
				evt.Add{"Gold", Value = calculateGold(25000)}
				evt.ForPlayer("All")
				evt.Add{"Experience", Value = calculateExp(20000)}
				evt.Subtract{"Inventory", Value = 658}         -- "Wheel of Frelandeau"
				evt.Subtract{"Inventory", Value = 659}         -- "Log of Eldenbrie"
				evt.Subtract{"Inventory", Value = 660}         -- "Ball of Dunduck"
				evt.Add{"Awards", Value = 42}         -- "Retrieved three cheeses for Asael Fromago, the Cheese Connoisseur of Alvar."
				evt.Subtract{"QBits", Value = 176}         -- "Find a wheel of Frelandeau Cheese. Bring it to Asael Fromago in Alvar."
				evt.Subtract{"QBits", Value = 177}         -- "Find a log of Eldenbrie Cheese. Bring it to Asael Fromago in Alvar."
				evt.Subtract{"QBits", Value = 178}         -- "Find a ball of Dunduck Cheese. Bring it to Asael Fromago in Alvar."
				evt.Add{"QBits", Value = 179}         -- Quests 176-178 done.
				evt.SetNPCTopic{NPC = 254, Index = 2, Event = 0}         -- "Asael Fromago"
				return
			end
		end
	end
	if not evt.Cmp{"Inventory", Value = 658} then         -- "Wheel of Frelandeau"
		if not evt.Cmp{"Inventory", Value = 659} then         -- "Log of Eldenbrie"
			if not evt.Cmp{"Inventory", Value = 660} then         -- "Ball of Dunduck"
				evt.SetMessage{Str = 806}         -- "You say you will find me the cheeses I desire, but here you are returned, empty-handed! Do not waste my precious time! Bring me cheese--Frelandeau, Eldenbrie and Dunduck! Do not return until you have them!"
				return
			end
		end
	end
	evt.SetMessage{Str = 807}         -- "Very good, you have found me some of the cheese I seek. But now I have my heart set on a full cheese tasting with all three cheeses eaten at once so I can savor them in comparison. Come back when you have then all. I will not take what you have now. I don't think I could resist sampling what you leave--and then the cheese tasting would be ruined!"
end
evt.global[741] = function()
	evt.SetMessage{Str = 930}         --[[ "My father sent you to rescue me?
I am grateful.
I will return to my father and let him know of your assistance!" ]]
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(5000)}
	evt.SetNPCTopic{NPC = 102, Index = 0, Event = 0}         -- "Irabelle Hunter"
	evt.Subtract{"QBits", Value = 119}         -- "Rescue Arion Hunter's daughter from Ogre Fortress in Alvar."
	evt.Add{"QBits", Value = 120}         -- Rescued Smuggler Leader's Familly 
end
evt.global[753] = function()
	evt.SetMessage{Str = 945}         --[[ "Congratulations!
You are the new Lords of Harmondale!
Isn't it thrilling?
You can't imagine how good it feels for me to give this property away to you!
All of the benefits and rewards, and of course, the responsibilities of governing the town of Harmondale are now yours.
(Lord Markham produces a deed and contract) Just sign here...And here... And if I could just get your initials here... Yes!
Well, that's that!
You're all set.
And once again, congratulations!!!" ]]
	evt.SetNPCTopic{NPC = 340, Index = 2, Event = 754}         -- "Lord Markham" : "Your ship…"
	evt.Subtract{"QBits", Value = 1683}         -- Replacement for NPCs ¹3 ver. 7
	evt.Set{"QBits", Value = 529}         -- No more docent babble
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(1000)}
	evt.Add{"Awards", Value = 1}         -- "Won the Scavenger Hunt on Emerald Island"
	evt.SetNPCGroupNews{NPCGroup = 52, NPCNews = 56}         -- "" : "Congratulations!"
end
-- "What do you have?"
evt.global[756] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"QBits", Value = 520} then         -- Brought red potion
		if evt.Cmp{"Inventory", Value = 222} then         -- "Cure Wounds"
			evt.Subtract{"QBits", Value = 513}         -- "Return a red potion to the Judge on Emerald Island."
			evt.Add{"Experience", Value = calculateExp(500)}
			evt.Add{"QBits", Value = 520}         -- Brought red potion
			evt.Subtract{"Inventory", Value = 222}         -- "Cure Wounds"
			evt.SetMessage{Str = 969}         --[[ "What took you so long?
Almost every group has turned in a red potion by now.
This is the easiest item in the hunt to manage, but better late than never.
I will mark it off your list." ]]
			return
		end
	end
	if not evt.Cmp{"QBits", Value = 521} then         -- Brought seashell
		if evt.Cmp{"Inventory", Value = 1437} then         -- "Seashell"
			evt.Subtract{"QBits", Value = 514}         -- "Return a seashell to the Judge on Emerald Island."
			evt.Subtract{"Inventory", Value = 1437}         -- "Seashell"
			evt.Add{"QBits", Value = 521}         -- Brought seashell
			evt.Add{"Experience", Value = calculateExp(500)}
			evt.SetMessage{Str = 968}         --[[ "A beautiful shell, much like the ones that Sally sells.
This certainly came from Emerald Island- I shall mark the shell off your list." ]]
			return
		end
	end
	if not evt.Cmp{"QBits", Value = 522} then         -- Brought longbow
		if evt.Cmp{"Inventory", Value = 845} then         -- "Longbow"
			evt.SetMessage{Str = 967}         --[[ "This longbow certainly qualifies for the hunt.
Good work, I shall mark that off your list." ]]
			evt.Subtract{"Inventory", Value = 845}         -- "Longbow"
			evt.Subtract{"QBits", Value = 515}         -- "Return a longbow to the Judge on Emerald Island."
			evt.Add{"Experience", Value = calculateExp(500)}
			evt.Add{"QBits", Value = 522}         -- Brought longbow
			return
		end
	end
	if not evt.Cmp{"QBits", Value = 523} then         -- Brought tile
		if evt.Cmp{"Inventory", Value = 1438} then         -- "Floor Tile (w/ moon insignia)"
			evt.SetMessage{Str = 966}         --[[ "Adventurers indeed!
I didn't expect anyone to bring back a tile so quickly.
This is certainly a tile from the Temple, however so I shall mark the tile off your list." ]]
			evt.Subtract{"Inventory", Value = 1438}         -- "Floor Tile (w/ moon insignia)"
			evt.Subtract{"QBits", Value = 516}         -- "Return a floor tile to the Judge on Emerald Island."
			evt.Add{"Experience", Value = calculateExp(500)}
			evt.Add{"QBits", Value = 523}         -- Brought tile
			return
		end
	end
	if not evt.Cmp{"QBits", Value = 524} then         -- Brought instrument
		if evt.Cmp{"Inventory", Value = 1434} then         -- "Lute"
			evt.SetMessage{Str = 965}         --[[ "Hmm, a fine lute this is.
Let me mark off the instrument from your list." ]]
			evt.Subtract{"Inventory", Value = 1434}         -- "Lute"
			evt.Subtract{"QBits", Value = 517}         -- "Return a musical instrument to the Judge on Emerald Island."
			evt.Add{"Experience", Value = calculateExp(500)}
			evt.Add{"QBits", Value = 524}         -- Brought instrument
			return
		end
	end
	if evt.Cmp{"QBits", Value = 525} then         -- Brought hat
		if not evt.Cmp{"QBits", Value = 513} then         -- "Return a red potion to the Judge on Emerald Island."
			if not evt.Cmp{"QBits", Value = 514} then         -- "Return a seashell to the Judge on Emerald Island."
				if not evt.Cmp{"QBits", Value = 515} then         -- "Return a longbow to the Judge on Emerald Island."
					if not evt.Cmp{"QBits", Value = 516} then         -- "Return a floor tile to the Judge on Emerald Island."
						if not evt.Cmp{"QBits", Value = 517} then         -- "Return a musical instrument to the Judge on Emerald Island."
							if not evt.Cmp{"QBits", Value = 518} then         -- "Return a wealthy hat to the Judge on Emerald Island."
								evt.Add{"QBits", Value = 519}         -- Finished Scavenger Hunt
								evt.SetMessage{Str = 970}         --[[ "Well, that's all six items.
You're the winner of the contest!
I suggest you talk to Lord Markham for the details on gaining your fiefdom, my work is done here." ]]
								evt.SetNPCTopic{NPC = 341, Index = 0, Event = 0}         -- "Thomas the Judge"
								evt.SetNPCTopic{NPC = 341, Index = 1, Event = 0}         -- "Thomas the Judge"
								evt.MoveNPC{NPC = 341, HouseId = 0}         -- "Thomas the Judge"
								evt.SetNPCTopic{NPC = 340, Index = 1, Event = 0}         -- "Lord Markham"
								evt.SetNPCGreeting{NPC = 345, Greeting = 124}         -- "Mr. Malwick" : "I don't believe we have anything to talk about."
								return
							end
						end
					end
				end
			end
		end
	elseif evt.Cmp{"Inventory", Value = 1433} then         -- "Wealthy Hat"
		evt.SetMessage{Str = 964}         --[[ "I see you have found a wealthy hat.
I shall mark this off your list accordingly, good work." ]]
		evt.Subtract{"Inventory", Value = 1433}         -- "Wealthy Hat"
		evt.Subtract{"QBits", Value = 518}         -- "Return a wealthy hat to the Judge on Emerald Island."
		evt.Add{"Experience", Value = calculateExp(500)}
		evt.Add{"QBits", Value = 525}         -- Brought hat
		return
	end
	evt.SetMessage{Str = 971}         --[[ "I'm sorry, but nothing you have is necessary for the hunt.
I don't mean to belittle what you have, but I'm not looking for any of it." ]]
end
-- "Missing Contestants"
evt.global[785] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1460} then         -- "Contestant's Shield"
		evt.SetMessage{Str = 984}         --[[ "There really is a dragon on the island?
I thought everyone was referring to the dragonflies everywhere.
I'll warn everyone to stay away from that cave so we don't lose anyone else." ]]
		evt.Subtract{"Inventory", Value = 1460}         -- "Contestant's Shield"
		evt.Add{"Awards", Value = 2}         -- "Found the missing contestants on Emerald Island"
		evt.Add{"Experience", Value = calculateExp(1000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(1000)}
		evt.Subtract{"Reputation", Value = 5}
		evt.Subtract{"QBits", Value = 528}         -- "Find the missing contestants on Emerald Island and bring back proof to Lord Markham."
		evt.SetNPCTopic{NPC = 340, Index = 3, Event = 0}         -- "Lord Markham"
	else
		evt.SetMessage{Str = 983}         -- "No news on the missing people yet?"
	end
end
-- "Rogue "
evt.global[795] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 1426} then         -- "Vase"
		evt.SetMessage{Str = 994}         --[[ "Common criminals steal whatever catches their eye; Rogues steal what I tell them to steal.
I shall not grant titles to failures.
Return with Lord Markham’s Vase and I will promote all Thieves to Rogues, and all non-thieves to Honorary Rogues." ]]
		return
	end
	evt.SetMessage{Str = 995}         --[[ "Well done.
Stealing that vase took guts and skill.
I grant you the title of Rogue, and a small payment for your services. " ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Thief} then
		evt.Set{"ClassIs", Value = const.Class.Rogue}
		evt.Add{"QBits", Value = 1560}         -- Promoted to Rogue
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1561}         -- Promoted to Honorary Rogue
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Thief} then
		evt.Set{"ClassIs", Value = const.Class.Rogue}
		evt.Add{"QBits", Value = 1560}         -- Promoted to Rogue
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1561}         -- Promoted to Honorary Rogue
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Thief} then
		evt.Set{"ClassIs", Value = const.Class.Rogue}
		evt.Add{"QBits", Value = 1560}         -- Promoted to Rogue
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1561}         -- Promoted to Honorary Rogue
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Thief} then
		evt.Set{"ClassIs", Value = const.Class.Rogue}
		evt.Add{"QBits", Value = 1560}         -- Promoted to Rogue
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1561}         -- Promoted to Honorary Rogue
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.Subtract{"Inventory", Value = 1426}         -- "Vase"
	evt.Subtract{"QBits", Value = 724}         -- Vase - I lost it
	evt.ForPlayer("All")
	evt.ForPlayer(4)
	evt.Add{"Gold", Value = calculateGold(5000)}
	evt.Subtract{"QBits", Value = 530}         -- "Go to Lord Markham's estate in Tatalia, steal the vase there, and return it to William Lasker in the Erathian Sewers."
	evt.SetNPCTopic{NPC = 354, Index = 0, Event = 796}         -- "William Lasker" : "Spy"
end
-- "Spy"
evt.global[797] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"QBits", Value = 532} then         -- Watchtower 6.  Weight in the appropriate box.  Important for Global event 47 (Spy promotion)
		if evt.Cmp{"Inventory", Value = 0} then         -- "0"
			evt.SetMessage{Str = 999}         --[[ "Um…The weight needs to go in the box in the lower gatehouse—not here.
Go back to Watchtower 6 and put the weight in the right box!" ]]
		elseif evt.Cmp{"QBits", Value = 568} then         -- Watchtower 6.  Taken the weight from the upper gatehouse.  Spy promo quest
			evt.SetMessage{Str = 1000}         --[[ "Hmm.
Removing the weight from the upper gatehouse was a start, but where is it now?!?
The plan won’t work unless you put the weight in the lower gatehouse!
Go back to Watchtower 6 and put the weight in the right box!" ]]
		else
			evt.SetMessage{Str = 1001}         --[[ "You haven’t done the job yet!
Remember, you must go to Watchtower 6 and move the weight from the box in the upper gatehouse to the lower gatehouse.
I will not promote you until that is done. " ]]
		end
		return
	end
	evt.SetMessage{Str = 1002}         --[[ "Good work!
Some day, your sabotage of that watchtower will save hundreds of lives.
For your services, I hereby promote the Rogues among you to the status of Spy, and the Honorary Rogues to Honorary Spies! Oh, and here’s some gold as payment. " ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Rogue} then
		evt.Set{"ClassIs", Value = const.Class.Spy}
		evt.Add{"QBits", Value = 1562}         -- Promoted to Spy
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1563}         -- Promoted to Honorary Spy
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Rogue} then
		evt.Set{"ClassIs", Value = const.Class.Spy}
		evt.Add{"QBits", Value = 1562}         -- Promoted to Spy
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1563}         -- Promoted to Honorary Spy
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Rogue} then
		evt.Set{"ClassIs", Value = const.Class.Spy}
		evt.Add{"QBits", Value = 1562}         -- Promoted to Spy
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1563}         -- Promoted to Honorary Spy
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Rogue} then
		evt.Set{"ClassIs", Value = const.Class.Spy}
		evt.Add{"QBits", Value = 1562}         -- Promoted to Spy
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1563}         -- Promoted to Honorary Spy
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Add{"Gold", Value = calculateGold(15000)}
	evt.Subtract{"QBits", Value = 531}         -- "Go to Watchtower 6 in the Deyja Moors, and move the weight from the top of the tower to the bottom of the tower.  Then return to William Lasker in the Erathian Sewers."
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 354, Index = 0, Event = 0}         -- "William Lasker"
	evt.SetNPCGreeting{NPC = 354, Greeting = 154}         -- "William Lasker" : "Greetings Rogues, how may I be of service?"
end
-- "Assassin"
evt.global[800] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 1342} then         -- "Lady Carmine's Dagger"
		evt.SetMessage{Str = 1009}         --[[ "Without proof, I cannot assume Lady Carmine is dead.
Bring me proof, and I will honor you with the title of Assassin." ]]
		return
	end
	evt.SetMessage{Str = 1010}         --[[ "So, the job is done. [He examines the dagger slowly, then sighs.] She was very dear to me, but emotion is the enemy of reason.
I could not have done the job myself.
Thank you.
Truly now, you are Assassins.
The rogues among you, I will give special training to.
Here is a small payment to help cover the expenses you incurred on the job. " ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Rogue} then
		evt.Set{"ClassIs", Value = const.Class.Assassin}
		evt.Add{"QBits", Value = 1564}         -- Promoted to Assassin
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1565}         -- Promoted to Honorary Assassin
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Rogue} then
		evt.Set{"ClassIs", Value = const.Class.Assassin}
		evt.Add{"QBits", Value = 1564}         -- Promoted to Assassin
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1565}         -- Promoted to Honorary Assassin
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Rogue} then
		evt.Set{"ClassIs", Value = const.Class.Assassin}
		evt.Add{"QBits", Value = 1564}         -- Promoted to Assassin
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1565}         -- Promoted to Honorary Assassin
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Rogue} then
		evt.Set{"ClassIs", Value = const.Class.Assassin}
		evt.Add{"QBits", Value = 1564}         -- Promoted to Assassin
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1565}         -- Promoted to Honorary Assassin
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Add{"Gold", Value = calculateGold(15000)}
	evt.Subtract{"QBits", Value = 725}         -- Dagger - I lost it
	evt.Subtract{"QBits", Value = 533}         -- "Go to the Celestial Court in Celeste and kill Lady Eleanor Carmine.  Return with proof to Seknit Undershadow in the Deyja Moors."
	evt.Add{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 355, Index = 1, Event = 0}         -- "Seknit Undershadow"
	evt.SetNPCGreeting{NPC = 355, Greeting = 157}         --[[ "Seknit Undershadow" : "Hello again, fellow Assassins.
My tea and company are always yours." ]]
end
-- "Crusader"
evt.global[802] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"QBits", Value = 535} then         -- Killed dragon when on Crusader quest
		evt.SetMessage{Str = 1014}         -- "We must finish our quest before I can name thee Crusaders, friends."
		return
	end
	evt.SetMessage{Str = 1013}         --[[ "Hurrah!
The Dragon has fallen!
Truly thou art grand Crusaders in good standing, with a fine deed behind thee.
I would stay and sing songs of thy bravery with thee, but duty calls.
Surely we will meet again, Crusaders!" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Paladin} then
		evt.Set{"ClassIs", Value = const.Class.Crusader}
		evt.Add{"QBits", Value = 1590}         -- Promoted to Crusader
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1591}         -- Promoted to Honorary Crusader
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Paladin} then
		evt.Set{"ClassIs", Value = const.Class.Crusader}
		evt.Add{"QBits", Value = 1590}         -- Promoted to Crusader
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1591}         -- Promoted to Honorary Crusader
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Paladin} then
		evt.Set{"ClassIs", Value = const.Class.Crusader}
		evt.Add{"QBits", Value = 1590}         -- Promoted to Crusader
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1591}         -- Promoted to Honorary Crusader
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Paladin} then
		evt.Set{"ClassIs", Value = const.Class.Crusader}
		evt.Add{"QBits", Value = 1590}         -- Promoted to Crusader
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1591}         -- Promoted to Honorary Crusader
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.Subtract{"QBits", Value = 534}         -- "Kill Wromthrax the Heartless in his cave in Tatalia, then talk to Sir Charles Quixote."
	evt.Subtract{"QBits", Value = 1684}         -- Replacement for NPCs ¹17 ver. 7
	evt.Subtract{"Reputation", Value = 5}
	evt.ForPlayer("All")
	evt.MoveNPC{NPC = 356, HouseId = 941}         -- "Sir Charles Quixote" -> "Quixote Residence"
	evt.SetNPCTopic{NPC = 356, Index = 0, Event = 803}         -- "Sir Charles Quixote" : "Hero"
	evt.SetNPCGreeting{NPC = 356, Greeting = 158}         --[[ "Sir Charles Quixote" : "Well met, my friends.
How goes the struggle against the forces of evil?" ]]
end
-- "Hero"
evt.global[804] = function()
	if not evt.Cmp{"QBits", Value = 1685} then         -- Replacement for NPCs ¹54 ver. 7
		evt.SetMessage{Str = 1019}         -- "Though thy deeds remain impressive indeed, crusaders, I cannot declare thee Heroes until you have rescued the girl!"
		return
	end
	evt.SetMessage{Str = 1018}         --[[ "Thee’ve done it! I knew thee could do it!
I’m so proud of thee!
Alice has been freed of the clutches of the wicked William Setag, evil has been vanquished, and good upheld.
Where once there was wrong, now there is right! [Charles sighs and smiles broadly] Well.
My work here is done!
Thee have passed the tests and deserve thy reward.
Therefore do I solemnly declare thee Heroes! " ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Hero}
		evt.Add{"QBits", Value = 1592}         -- Promoted to Hero
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1593}         -- Promoted to Honorary Hero
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Hero}
		evt.Add{"QBits", Value = 1592}         -- Promoted to Hero
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1593}         -- Promoted to Honorary Hero
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Hero}
		evt.Add{"QBits", Value = 1592}         -- Promoted to Hero
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1593}         -- Promoted to Honorary Hero
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Hero}
		evt.Add{"QBits", Value = 1592}         -- Promoted to Hero
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1593}         -- Promoted to Honorary Hero
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 536}         -- "Rescue Alice Hargreaves from William's Tower in the Deyja Moors then talk to Sir Charles Quixote."
	evt.Subtract{"QBits", Value = 1685}         -- Replacement for NPCs ¹54 ver. 7
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.MoveNPC{NPC = 393, HouseId = 941}         -- "Alice Hargreaves" -> "Quixote Residence"
	evt.SetNPCGreeting{NPC = 356, Greeting = 161}         --[[ "Sir Charles Quixote" : "Salutations Heroes!
I am certain thou hast much to accomplish before we dally about." ]]
	evt.SetNPCTopic{NPC = 356, Index = 0, Event = 0}         -- "Sir Charles Quixote"
end
-- "Villain"
evt.global[807] = function()
	if not evt.Cmp{"QBits", Value = 1685} then         -- Replacement for NPCs ¹54 ver. 7
		evt.SetMessage{Str = 1030}         --[[ "Where's Alice?
I'm not asking for much, just a simple kidnapping.
Is it really that difficult?
I suggest you speed up your efforts." ]]
		return
	end
	evt.SetMessage{Str = 1029}         --[[ "Capital!
You have shown dedication, daring, and the power of raw force.
Certainly the imprisonment of such a fair and noble creature in this wicked place earns you the right to be called a Villain-- or Honorary Villain.
Go now upon the world and make all fear your name." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Villain}
		evt.Add{"QBits", Value = 1594}         -- Promoted to Villain
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1595}         -- Promoted to Honorary Villain
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Villain}
		evt.Add{"QBits", Value = 1594}         -- Promoted to Villain
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1595}         -- Promoted to Honorary Villain
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Villain}
		evt.Add{"QBits", Value = 1594}         -- Promoted to Villain
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1595}         -- Promoted to Honorary Villain
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Villain}
		evt.Add{"QBits", Value = 1594}         -- Promoted to Villain
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1595}         -- Promoted to Honorary Villain
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Add{"Gold", Value = calculateGold(10000)}
	evt.Subtract{"QBits", Value = 538}         -- "Capture Alice Hargreaves from her residence in Castle Gryphonheart and return her to William's Tower in the Deyja Moors."
	evt.Add{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 357, Index = 0, Event = 0}         -- "William Setag"
	evt.SetNPCGreeting{NPC = 357, Greeting = 165}         --[[ "William Setag" : "Villains!
Welcome!
Too rarely do my villainous friends pay me visits." ]]
	evt.Subtract{"QBits", Value = 1685}         -- Replacement for NPCs ¹54 ver. 7
end
-- "Initiate"
evt.global[810] = function()
	evt.SetMessage{Str = 1032}         --[[ "[Bartholomew Hume contacts you mentally] Congratulations, young ones.
My final lesson given to you as Monks is this:
enlightenment is gained by the journey, not the destination.
In this case, the destination was critical to prove that you were capable of the journey.
I shall now promote all Monks to Initiates and everyone else to Honorary Initiates-- congratulations." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Monk} then
		evt.Set{"ClassIs", Value = const.Class.Initiate}
		evt.Add{"QBits", Value = 1572}         -- Promoted to Initiate
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1573}         -- Promoted to Honorary Initiate
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Monk} then
		evt.Set{"ClassIs", Value = const.Class.Initiate}
		evt.Add{"QBits", Value = 1572}         -- Promoted to Initiate
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1573}         -- Promoted to Honorary Initiate
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Monk} then
		evt.Set{"ClassIs", Value = const.Class.Initiate}
		evt.Add{"QBits", Value = 1572}         -- Promoted to Initiate
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1573}         -- Promoted to Honorary Initiate
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Monk} then
		evt.Set{"ClassIs", Value = const.Class.Initiate}
		evt.Add{"QBits", Value = 1572}         -- Promoted to Initiate
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1573}         -- Promoted to Honorary Initiate
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.Subtract{"QBits", Value = 539}         -- "Find the lost meditation spot in the Dwarven Barrows."
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 377, Index = 0, Event = 811}         -- "Bartholomew Hume" : "Master"
	evt.SetNPCTopic{NPC = 394, Index = 0, Event = 0}         -- "Bartholomew Hume"
end
-- "Master"
evt.global[812] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"QBits", Value = 755} then         -- Killed High Preist of Baa
		evt.SetMessage{Str = 1073}         --[[ "The Temple of Baa still stands, their High Priest still lives.
Until this is completed, you are not ready for the title of Master.
Go now and do not fail." ]]
		return
	end
	evt.SetMessage{Str = 1072}         --[[ "Good work.
No longer shall the Order of Baa stain the lands of Erathia.
Now, allow me to promote all Initiates to Masters, and all Honorary Initiates to Honorary Masters.
Keep in mind that this is but a stop along the path of enlightenment.
Your journey only ends with your eventual death-- never close your mind." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Initiate} then
		evt.Set{"ClassIs", Value = const.Class.Master}
		evt.Add{"QBits", Value = 1574}         -- Promoted to Master
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1575}         -- Promoted to Honorary Master
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Initiate} then
		evt.Set{"ClassIs", Value = const.Class.Master}
		evt.Add{"QBits", Value = 1574}         -- Promoted to Master
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1575}         -- Promoted to Honorary Master
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Initiate} then
		evt.Set{"ClassIs", Value = const.Class.Master}
		evt.Add{"QBits", Value = 1574}         -- Promoted to Master
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1575}         -- Promoted to Honorary Master
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Initiate} then
		evt.Set{"ClassIs", Value = const.Class.Master}
		evt.Add{"QBits", Value = 1574}         -- Promoted to Master
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1575}         -- Promoted to Honorary Master
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Add{"Gold", Value = calculateGold(7500)}
	evt.Subtract{"QBits", Value = 540}         -- "Go to the Temple of Baa in Avlee and kill the High Priest of Baa, then return to Bartholomew Hume in Harmondale."
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 377, Index = 0, Event = 0}         -- "Bartholomew Hume"
	evt.SetNPCGreeting{NPC = 377, Greeting = 167}         --[[ "Bartholomew Hume" : "Greetings again, Masters.
How can Bartholomew aid you?" ]]
end
-- "Ninja"
evt.global[813] = function()
	if not evt.Cmp{"QBits", Value = 1572} then         -- Promoted to Initiate
		if not evt.Cmp{"QBits", Value = 1573} then         -- Promoted to Honorary Initiate
			evt.SetMessage{Str = 1075}         --[[ "Ambition is good, but I only train experienced students.
Come back when you've achieved Initiate status, and perhaps I'll teach you…IF you have the right outlook.
If you're looking for someone who is willing to help you become an Initiate, perhaps you should start with that wimp Bartholomew Hume.
I'm sure he'd be willing to give you an elementary education." ]]
			return
		end
	end
	if evt.Cmp{"QBits", Value = 611} then         -- Chose the path of Light
		evt.SetMessage{Str = 1076}         --[[ "[Stephan Sand sneers] YOU want ME to teach you something?
You sniveling do-gooders make my knife arm twitch!
Get out of my sight before I REALLY teach you about fighting!" ]]
	elseif evt.Cmp{"QBits", Value = 612} then         -- Chose the path of Dark
		evt.SetMessage{Str = 1074}         --[[ "An agent of mine has sent me a message I need deciphered.
The cipher relies on knowing which word of which a certain book to match it against.
If you wish to become a Ninja, this is what you must do: Infiltrate the School of Wizardry and find out what the third word of the famed Scroll of Waves is.
Use it to decipher the message, then do what the message tells you to do.
It is the key to enter the Tomb of the Master.
You'll find the tomb in Southern Erathia.
[Stephan hands you a scrap of paper] Here is the encoded message." ]]
		evt.Set{"QBits", Value = 541}         -- "Crack the code in the School of Sorcery in the Bracada Desert to reveal the location of the Tomb of Ashwar Nog'Nogoth.  Discover the tomb's location, enter it, and then return it to Stephan Sand in the Pit."
		evt.SetNPCTopic{NPC = 378, Index = 0, Event = 814}         -- "Stephan Sand" : "Ninja"
		evt.Add{"Inventory", Value = 1503}         -- "Cipher"
		evt.Add{"QBits", Value = 727}         -- Cipher - I lost it
	else
		evt.SetMessage{Str = 1077}         --[[ "Though you have achieved initiate status, I am uncertain that you can stomach some of my more extreme teachings.
Return to me when you have formally rejected all philosophies that turn people into weaklings and cowards." ]]
	end
end
-- "Ninja"
evt.global[814] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"QBits", Value = 754} then         -- Opened chest with shadow mask
		if evt.Cmp{"QBits", Value = 569} then         -- Solved the code puzzle.  Ninja promo quest
			evt.SetMessage{Str = 1078}         --[[ "So you have the key, but you haven't followed the directions in the message.
Remember, the tomb is in Southern Erathia.
Complete your task, and return to me to report success.
If you can't complete your mission, don't bother returning to me.
Failure is pathetic." ]]
		else
			evt.SetMessage{Str = 1079}         --[[ "[Sand sighs] Once again, the cipher key is the third word of the first paragraph of the Scroll of Waves.
You can find it somewhere in the School of Wizardry.
I don't care how you get in there--kill anyone who gets in your way, or sneak in.
Whatever you want.
The only thing that matters is success.
Everything else is an excuse for personal weakness." ]]
		end
		return
	end
	evt.SetMessage{Str = 1080}         --[[ "Well done.
No one can argue with success except apologists for the weak and the cowardly.
I hereby promote all Initiates to Ninjas, and all non-Initiates to Honorary Ninjas.
Oh yeah, go ahead and keep that little trinket you stole from the tomb.
This was just a training exercise, after all." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Initiate} then
		evt.Set{"ClassIs", Value = const.Class.Ninja}
		evt.Add{"QBits", Value = 1576}         -- Promoted to Ninja
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1577}         -- Promoted to Honorary Ninja
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Initiate} then
		evt.Set{"ClassIs", Value = const.Class.Ninja}
		evt.Add{"QBits", Value = 1576}         -- Promoted to Ninja
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1577}         -- Promoted to Honorary Ninja
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Initiate} then
		evt.Set{"ClassIs", Value = const.Class.Ninja}
		evt.Add{"QBits", Value = 1576}         -- Promoted to Ninja
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1577}         -- Promoted to Honorary Ninja
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Initiate} then
		evt.Set{"ClassIs", Value = const.Class.Ninja}
		evt.Add{"QBits", Value = 1576}         -- Promoted to Ninja
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1577}         -- Promoted to Honorary Ninja
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 541}         -- "Crack the code in the School of Sorcery in the Bracada Desert to reveal the location of the Tomb of Ashwar Nog'Nogoth.  Discover the tomb's location, enter it, and then return it to Stephan Sand in the Pit."
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 378, Index = 0, Event = 0}         -- "Stephan Sand"
	evt.SetNPCGreeting{NPC = 378, Greeting = 170}         --[[ "Stephan Sand" : "Now that you've achieved the exaulted status of Ninja, I have nothing further to give you.
I hope my teachings take you far." ]]
end
-- "Master Archer"
evt.global[816] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 1344} then         -- "The Perfect Bow"
		evt.SetMessage{Str = 1086}         --[[ "No luck getting the bow?
Well, take your time, and plan your assault against the Titans carefully.
Against such powerful opponents, there is no shame in striking and retreating.
Do what you must to defeat these monsters." ]]
		return
	end
	evt.SetMessage{Str = 1085}         --[[ "You found the bow!
Let me take some measurements and adjust it to your specific style of archery. Once I have finished you should keep it, and use it in defense the of the land and the people.
I am happy to promote all Warrior Mages to Master Archers, and all Honorary Warrior Mages to Honorary Master Archers." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
		evt.Set{"ClassIs", Value = const.Class.MasterArcher}
		evt.Add{"QBits", Value = 1586}         -- Promoted to Master Archer
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1587}         -- Promoted to Honorary Master Archer
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
		evt.Set{"ClassIs", Value = const.Class.MasterArcher}
		evt.Add{"QBits", Value = 1586}         -- Promoted to Master Archer
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1587}         -- Promoted to Honorary Master Archer
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
		evt.Set{"ClassIs", Value = const.Class.MasterArcher}
		evt.Add{"QBits", Value = 1586}         -- Promoted to Master Archer
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1587}         -- Promoted to Honorary Master Archer
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
		evt.Set{"ClassIs", Value = const.Class.MasterArcher}
		evt.Add{"QBits", Value = 1586}         -- Promoted to Master Archer
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1587}         -- Promoted to Honorary Master Archer
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 542}         -- "Retrieve the Perfect Bow from the Titans' Stronghold in Avlee and return it to Lawrence Mark in Harmondale."
	evt.Add{"Inventory", Value = 1345}         -- "The Perfect Bow"
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1344} then         -- "The Perfect Bow"
		evt.Subtract{"Inventory", Value = 1344}         -- "The Perfect Bow"
	end
	evt.SetNPCTopic{NPC = 379, Index = 0, Event = 0}         -- "Lawrence Mark"
	evt.SetNPCGreeting{NPC = 379, Greeting = 172}         --[[ "Lawrence Mark" : "Welcome my friends!
That's a fine weapon you have there, but don't think for a moment you'll best me in this year's Tourney--I'm still the Master!" ]]
end
-- "Warrior Mage"
evt.global[818] = function()
	if not evt.Cmp{"QBits", Value = 570} then         -- Destroyed critter generator in dungeon.  Warrior Mage promo quest.
		evt.SetMessage{Str = 1089}         --[[ "You haven't sabotaged the machine yet.
You must finish this before I'll promote you to Warrior Mage." ]]
		return
	end
	evt.SetMessage{Str = 1088}         --[[ "Very Good.
You have passed the test.
Now the creatures are sealed away and won't be able to prey on the dwarves any longer, and you have proven your ability in both sorcery and steel.
I am proud to declare all Archers amongst you Warrior Mages, and everyone else Honorary Warrior Mages.
Congratulations!
Now get out.
I already weary of your company." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Archer} then
		evt.Set{"ClassIs", Value = const.Class.WarriorMage}
		evt.Add{"QBits", Value = 1584}         -- Promoted to Warrior Mage
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1585}         -- Promoted to Honorary Warrior Mage
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Archer} then
		evt.Set{"ClassIs", Value = const.Class.WarriorMage}
		evt.Add{"QBits", Value = 1584}         -- Promoted to Warrior Mage
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1585}         -- Promoted to Honorary Warrior Mage
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Archer} then
		evt.Set{"ClassIs", Value = const.Class.WarriorMage}
		evt.Add{"QBits", Value = 1584}         -- Promoted to Warrior Mage
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1585}         -- Promoted to Honorary Warrior Mage
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Archer} then
		evt.Set{"ClassIs", Value = const.Class.WarriorMage}
		evt.Add{"QBits", Value = 1584}         -- Promoted to Warrior Mage
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1585}         -- Promoted to Honorary Warrior Mage
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.Subtract{"QBits", Value = 543}         -- "Sabotage the lift in the Red Dwarf Mines in the Bracada Desert then return to Steagal Snick in Avlee."
	evt.Add{"Gold", Value = calculateGold(7500)}
	evt.Subtract{"Reputation", Value = 5}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 380, Index = 0, Event = 819}         -- "Steagal Snick" : "Sniper"
end
-- "Sniper"
evt.global[820] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 1344} then         -- "The Perfect Bow"
		evt.SetMessage{Str = 1094}         --[[ "More failure? [Master Snick yawns]
How surprising.
I'll make it simple--no bow, no title." ]]
		return
	end
	evt.SetMessage{Str = 1093}         --[[ "You have the bow?!
Excellent!
It's been centuries since someone was brave enough to take on the Titans and try to get that bow back!
Let me take some measurements and adjust it to your specific style of archery.
I am proud to be the one to first call all Warrior Mages amongst you Snipers, and to say that all Honorary Warrior Mages are Honorary Snipers!
I must admit I didn't think you had it in you to succeed.
I am happy that I was wrong." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
		evt.Set{"ClassIs", Value = const.Class.Sniper}
		evt.Add{"QBits", Value = 1588}         -- Promoted to Sniper
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1589}         -- Promoted to Honorary Sniper
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
		evt.Set{"ClassIs", Value = const.Class.Sniper}
		evt.Add{"QBits", Value = 1588}         -- Promoted to Sniper
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1589}         -- Promoted to Honorary Sniper
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
		evt.Set{"ClassIs", Value = const.Class.Sniper}
		evt.Add{"QBits", Value = 1588}         -- Promoted to Sniper
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1589}         -- Promoted to Honorary Sniper
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
		evt.Set{"ClassIs", Value = const.Class.Sniper}
		evt.Add{"QBits", Value = 1588}         -- Promoted to Sniper
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1589}         -- Promoted to Honorary Sniper
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 544}         -- "Retrieve the Perfect Bow from the Titans' Stronghold in Avlee and return it to Steagal Snick in Avlee."
	evt.Add{"Inventory", Value = 1345}         -- "The Perfect Bow"
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1344} then         -- "The Perfect Bow"
		evt.Subtract{"Inventory", Value = 1344}         -- "The Perfect Bow"
	end
	evt.SetNPCTopic{NPC = 380, Index = 0, Event = 0}         -- "Steagal Snick"
	evt.SetNPCGreeting{NPC = 380, Greeting = 174}         --[[ "Steagal Snick" : "Students…[Mr. Snick rasps the word, then smiles] no longer.
I am proud to have helped you on your way.
Use your new weapon…[wheeze] wisely." ]]
end
-- "Champion"
evt.global[822] = function()
	if not evt.Cmp{"ArenaWinsKnight", Value = 5} then
		evt.SetMessage{Str = 1100}         --[[ "You have not yet won 5 championship tournaments in the Arena.
Return to me when you have won five, and I will promote you.
Remember, these battles MUST be at the Knight difficulty level." ]]
		return
	end
	evt.SetMessage{Str = 1099}         --[[ "Congratulations for you recent tourney victories, my friends!
I gladly name the Cavaliers among you Champions, and the Honorary Cavaliers I name Honorary Champions!
Always fight for the Light, Champions!" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"QBits", Value = 1568}         -- Promoted to Champion
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1569}         -- Promoted to Honorary Champion
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"QBits", Value = 1568}         -- Promoted to Champion
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1569}         -- Promoted to Honorary Champion
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"QBits", Value = 1568}         -- Promoted to Champion
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1569}         -- Promoted to Honorary Champion
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"QBits", Value = 1568}         -- Promoted to Champion
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1569}         -- Promoted to Honorary Champion
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 545}         -- "Win five arena challenges then return to Leda Rowan in the Bracada Desert."
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 381, Index = 0, Event = 0}         -- "Leda Rowan"
	evt.SetNPCGreeting{NPC = 381, Greeting = 176}         --[[ "Leda Rowan" : "Hail, champions!
Your courage and skill has all the tongues in the Kingdom wagging!
I am very proud of you!" ]]
end
-- "Cavalier"
evt.global[824] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"QBits", Value = 652} then         -- Cleaned out the haunted mansion (Cavalier promo)
		evt.SetMessage{Str = 1103}         --[[ "Did one little haunted house send you packing in fear?
I've seen chocolate eclairs with more backbone than you!
Get you gone, and don't come back 'til you've stiffened your spine!" ]]
		return
	end
	evt.SetMessage{Str = 1102}         --[[ "So you're back!
And from the look on your faces I see you have finished the job.
Well done!
I hereby officially promote all Knights amongst you to Cavaliers, and everyone else to honorary Cavaliers.
Carry your title with pride!" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Cavalier}
		evt.Add{"QBits", Value = 1566}         -- Promoted to Cavalier
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1567}         -- Promoted to Honorary Cavalier
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Cavalier}
		evt.Add{"QBits", Value = 1566}         -- Promoted to Cavalier
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1567}         -- Promoted to Honorary Cavalier
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Cavalier}
		evt.Add{"QBits", Value = 1566}         -- Promoted to Cavalier
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1567}         -- Promoted to Honorary Cavalier
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Cavalier}
		evt.Add{"QBits", Value = 1566}         -- Promoted to Cavalier
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1567}         -- Promoted to Honorary Cavalier
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.Subtract{"QBits", Value = 546}         -- "Destroy all the undead in the Haunted House in the Barrow Downs and return to Frederick Org in Erathia."
	evt.Subtract{"Reputation", Value = 5}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 382, Index = 0, Event = 825}         -- "Frederick Org" : "Black Knight"
end
-- "Black Knight"
evt.global[826] = function()
	if not evt.Cmp{"QBits", Value = 572} then         -- Robbed Elven treasury.  Black Knight promo quest.
		evt.SetMessage{Str = 1108}         --[[ "Robbery not complete?
No.
Don't come to me and report failure.
Don't come and tell me you lost your nerve.
Get out there and rob that treasury!
Failure is not an option!" ]]
		return
	end
	evt.SetMessage{Str = 1107}         --[[ "All RIGHT!
That robbery was brilliant!
I am very proud of you.
Keep the loot--it's your reward for a job well done.
I can safely say the Cavaliers among you have become Black Knights today, and I'll throw in an Honorary Black Knight title for the rest of you.
You've done well, my students!" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.BlackKnight}
		evt.Add{"QBits", Value = 1570}         -- Promoted to Black Knight
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1571}         -- Promoted to Honorary Black Knight
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.BlackKnight}
		evt.Add{"QBits", Value = 1570}         -- Promoted to Black Knight
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1571}         -- Promoted to Honorary Black Knight
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.BlackKnight}
		evt.Add{"QBits", Value = 1570}         -- Promoted to Black Knight
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1571}         -- Promoted to Honorary Black Knight
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.BlackKnight}
		evt.Add{"QBits", Value = 1570}         -- Promoted to Black Knight
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1571}         -- Promoted to Honorary Black Knight
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 547}         -- "Raid the Elven Treasury at Castle Navan in the Tularean Forest and return to Frederick Org in Erathia."
	evt.Add{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 382, Index = 0, Event = 0}         -- "Frederick Org"
	evt.SetNPCGreeting{NPC = 382, Greeting = 178}         --[[ "Frederick Org" : "[Frederick rises hastily to his feet] None shall pass! [he blinks and rubs his eyes] Oh.
It's you.
Sorry, I thought you were someone else.
How goes the villainy?" ]]
end
-- "Ranger Lord"
evt.global[828] = function()
	if not evt.Cmp{"QBits", Value = 553} then         -- Solved Tree quest
		if evt.Cmp{"QBits", Value = 552} then         -- Talked to the Oldest Tree
			evt.SetMessage{Str = 1114}         --[[ "Well, you've spoken with the tree, and now know as much as I do about the theft.
If you manage to find the stone, take it directly to the tree and then come see me." ]]
		else
			evt.SetMessage{Str = 1113}         --[[ "If you can't figure out where to start, you should try finding the oldest tree in the forest.
It should be somewhere outside of Pierpont in Avlee.
The oldest tree has the power of speech, and may know something helpful.
It will be happy to tell you whatever you want to hear, plus a whole lot more.
You'll see." ]]
		end
		return
	end
	evt.SetMessage{Str = 1115}         --[[ "You've done a good thing, returning the Heart.
The forest is quieter now, and no longer attacks travelers.
You've probably saved many lives.
For service to the Land and the Light, I hereby promote all Hunters among you to Ranger Lords, and all honorary Hunters to honorary Ranger Lords!" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Hunter} then
		evt.Set{"ClassIs", Value = const.Class.RangerLord}
		evt.Add{"QBits", Value = 1580}         -- Promoted to Ranger Lord
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1581}         -- Promoted to Honorary Ranger Lord
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Hunter} then
		evt.Set{"ClassIs", Value = const.Class.RangerLord}
		evt.Add{"QBits", Value = 1580}         -- Promoted to Ranger Lord
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1581}         -- Promoted to Honorary Ranger Lord
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Hunter} then
		evt.Set{"ClassIs", Value = const.Class.RangerLord}
		evt.Add{"QBits", Value = 1580}         -- Promoted to Ranger Lord
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1581}         -- Promoted to Honorary Ranger Lord
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Hunter} then
		evt.Set{"ClassIs", Value = const.Class.RangerLord}
		evt.Add{"QBits", Value = 1580}         -- Promoted to Ranger Lord
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1581}         -- Promoted to Honorary Ranger Lord
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 548}         -- "Calm the trees in the Tularean Forest by speaking to the Oldest Tree then return to Lysander Sweet in the Bracada Desert."
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 383, Index = 0, Event = 0}         -- "Lysander Sweet"
	evt.SetNPCGreeting{NPC = 383, Greeting = 180}         --[[ "Lysander Sweet" : "Your good works have served the forest well.
And, I can see, the experience has served you well in turn.
May you continue to reap the rewards of your good deeds, my friends!" ]]
end
-- "Bounty Hunter"
evt.global[832] = function()
	if not evt.Cmp{"MontersHunted", Value = 10000} then
		evt.SetMessage{Str = 1122}         --[[ "Not yet, not good enough!
You need to collect more bounties, and more importantly, kill more creatures.
There's some good clean fun in that.
Killing, don't you know." ]]
		return
	end
	evt.SetMessage{Str = 1121}         --[[ "So, how did if feel?
All that killing?
Mmmmm.
Heh.
You qualify, my friends.
You definitely qualify.
All Hunters amongst you are now Bounty Hunters, and all Honorary hunters and Honorary Bounty Hunters!
Good job." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Hunter} then
		evt.Set{"ClassIs", Value = const.Class.BountyHunter}
		evt.Add{"QBits", Value = 1582}         -- Promoted to Bounty Hunter
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1583}         -- Promoted to Honorary Bounty Hunter
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Hunter} then
		evt.Set{"ClassIs", Value = const.Class.BountyHunter}
		evt.Add{"QBits", Value = 1582}         -- Promoted to Bounty Hunter
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1583}         -- Promoted to Honorary Bounty Hunter
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Hunter} then
		evt.Set{"ClassIs", Value = const.Class.BountyHunter}
		evt.Add{"QBits", Value = 1582}         -- Promoted to Bounty Hunter
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1583}         -- Promoted to Honorary Bounty Hunter
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Hunter} then
		evt.Set{"ClassIs", Value = const.Class.BountyHunter}
		evt.Add{"QBits", Value = 1582}         -- Promoted to Bounty Hunter
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1583}         -- Promoted to Honorary Bounty Hunter
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 550}         -- "Collect 10,000 gold worth of bounties from the Bounty Hunts in the town halls, then return to Ebednezer Sower in the Tularean Forest."
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 384, Index = 0, Event = 0}         -- "Ebednezer Sower"
	evt.SetNPCGreeting{NPC = 384, Greeting = 182}         --[[ "Ebednezer Sower" : "Bounty Hunters.
[Ebednezer smiles slowly and evilly]
Now THERE'S a job!
Yes sir.
Get things done righteo quick, I'll say. Heh." ]]
end
evt.global[833] = function()
	evt.SetMessage{Str = 1123}         --[[ "Come to my door looking for magic?
Thee've always had it, if thee knew where to look.
Some I tell this to, and they still can't see it, though it be plain as the nose on their face.
Those amongst thee that are simple Rangers are now Hunters, and those who aren't are but Honorary Hunters.
Clever the ones who can knock on my door!" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Ranger} then
		evt.Set{"ClassIs", Value = const.Class.Hunter}
		evt.Add{"QBits", Value = 1578}         -- Promoted to Hunter
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1579}         -- Promoted to Honorary Hunter
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Ranger} then
		evt.Set{"ClassIs", Value = const.Class.Hunter}
		evt.Add{"QBits", Value = 1578}         -- Promoted to Hunter
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1579}         -- Promoted to Honorary Hunter
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Ranger} then
		evt.Set{"ClassIs", Value = const.Class.Hunter}
		evt.Add{"QBits", Value = 1578}         -- Promoted to Hunter
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1579}         -- Promoted to Honorary Hunter
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Ranger} then
		evt.Set{"ClassIs", Value = const.Class.Hunter}
		evt.Add{"QBits", Value = 1578}         -- Promoted to Hunter
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1579}         -- Promoted to Honorary Hunter
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.Subtract{"QBits", Value = 549}         -- "Solve the secret to the entrance of the Faerie Mound in Avlee and speak to the Faerie King."
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 384, Index = 0, Event = 831}         -- "Ebednezer Sower" : "Bounty Hunter"
	evt.SetNPCTopic{NPC = 391, Index = 0, Event = 0}         -- "Faerie King"
end
-- "Heart of the Wood"
evt.global[835] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1402} then         -- "Heart of the Wood"
		evt.SetMessage{Str = 1125}         --[[ "Ahhh!
[The tree sighs happily]
You have the heart!
The forest sings with joy!
Tonight we will recite the song of the ancestors.
Will you stay and recite with us?" ]]
		evt.Subtract{"Inventory", Value = 1402}         -- "Heart of the Wood"
		evt.Subtract{"QBits", Value = 729}         -- Heart of Wood - I lost it
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.Subtract{"QBits", Value = 551}         -- "Find the Heart of the Forest in the Mercenary Guild in Tatalia and return it to the Oldest Tree in the Tularean Forest."
		evt.Set{"QBits", Value = 553}         -- Solved Tree quest
		evt.SetNPCTopic{NPC = 392, Index = 0, Event = 0}         -- "The Oldest Tree"
		evt.SetNPCGreeting{NPC = 392, Greeting = 186}         --[[ "The Oldest Tree" : "Ohhhhh…It's the Walkers from the South.
I remember you!
You returned the Heart.
The trees are very happy, and promise not to kill any more walkers.
Come and talk to me any time." ]]
		evt.Set{"Awards", Value = 23}         -- "Retrieved the Heart of the Wood"
		evt.SetMonGroupBit{NPCGroup = 61, Bit = const.MonsterBits.Hostile, On = false}         -- ""
	else
		evt.SetMessage{Str = 1126}         --[[ "Oh, the forest is still very angry.
The grapevines say the thieves have not left their hiding place.
You will catch the thieves for us, won't you?" ]]
	end
end
-- "Priest of Light"
evt.global[837] = function()
	if not evt.Cmp{"QBits", Value = 574} then         -- Purified the Altar of Evil.  Priest of Light promo quest.
		evt.SetMessage{Str = 1132}         --[[ "You must visit Evenmorn island and purify the Altar of Darkness in the Church of the Moon.
Only then can I promote you to Priests of the Light." ]]
		return
	end
	evt.SetMessage{Str = 1131}         --[[ "Your bravery has advanced our faith tremendously, Priests.
It's with a glad heart that I can hereby promote all Priests to Priests of the Light, and all honorary Priests to Honorary Priests of the Light.
Thank you so much for your help!" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"QBits", Value = 1609}         -- Promoted to Priest of the Light
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1610}         -- Promoted to Honorary Priest of the Light
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"QBits", Value = 1609}         -- Promoted to Priest of the Light
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1610}         -- Promoted to Honorary Priest of the Light
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"QBits", Value = 1609}         -- Promoted to Priest of the Light
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1610}         -- Promoted to Honorary Priest of the Light
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"QBits", Value = 1609}         -- Promoted to Priest of the Light
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1610}         -- Promoted to Honorary Priest of the Light
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 554}         -- "Purify the Altar of Evil in the Temple of the Moon on Evenmorn Isle then return to Rebecca Devine in Celeste."
	evt.Add{"Gold", Value = calculateGold(10000)}
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 385, Index = 0, Event = 0}         -- "Rebecca Devine"
	evt.SetNPCGreeting{NPC = 385, Greeting = 188}         --[[ "Rebecca Devine" : "Sunlight Reveal, my fellow Priests.
I am always delighted to see you!" ]]
end
-- "Priest"
evt.global[839] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 1485} then         -- "Map to Evenmorn Island"
		evt.SetMessage{Str = 1135}         --[[ "If there is a map that says where that island is, the map would be in the Tidewater Caverns of western Erathia.
When you bring me that map, then I will be happy to promote you all to Priests." ]]
		return
	end
	evt.SetMessage{Str = 1134}         --[[ "The Map!
You found it!
[Falk looks at the map, and points at the island] There it is.
The island has been shrouded in mist since the Churches of the Sun and Moon began fighting over a century ago.
Keep the map--I have the coordinates now, and will have no trouble finding the place when I need to.
I am proud to declare the Clerics amongst you to be Priests, and the rest to be honorary Priests.
Thank you so much for your good work!" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.Priest}
		evt.Add{"QBits", Value = 1607}         -- Promoted to Priest
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1608}         -- Promoted to Honorary Priest
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.Priest}
		evt.Add{"QBits", Value = 1607}         -- Promoted to Priest
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1608}         -- Promoted to Honorary Priest
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.Priest}
		evt.Add{"QBits", Value = 1607}         -- Promoted to Priest
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1608}         -- Promoted to Honorary Priest
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.Priest}
		evt.Add{"QBits", Value = 1607}         -- Promoted to Priest
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1608}         -- Promoted to Honorary Priest
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.Subtract{"QBits", Value = 555}         -- "Find the lost pirate map in the Tidewater Caverns in Tatalia and return to Daedalus Falk in the Deyja Moors."
	evt.Add{"Gold", Value = calculateGold(5000)}
	evt.Subtract{"Reputation", Value = 5}
	evt.ForPlayer("All")
	evt.Subtract{"Inventory", Value = 1485}         -- "Map to Evenmorn Island"
	evt.Subtract{"QBits", Value = 730}         -- Map to Evenmorn - I lost it
	evt.SetNPCTopic{NPC = 386, Index = 0, Event = 840}         -- "Daedalus Falk" : "Priest of Dark"
	evt.Set{"QBits", Value = 576}         -- Activate boat to area 9.  Priest promo quest
end
-- "Priest of Dark"
evt.global[841] = function()
	if not evt.Cmp{"QBits", Value = 575} then         -- Defaced the Altar of Good.  Priest of Dark promo quest.
		evt.SetMessage{Str = 1138}         --[[ "You must visit Evenmorn island and defile the Altar of Light in the Church of the Sun.
Only then can I promote you to Priests of the Dark." ]]
		return
	end
	evt.SetMessage{Str = 201}         --[[ "Your bravery has advanced our faith tremendously, Priests.
It's with pleasure that I can hereby promote all Priests to Priests of the Dark, and all honorary Priests to Honorary Priests of the Dark.
Thank you so much for your help!" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestDark}
		evt.Add{"QBits", Value = 1611}         -- Promoted to Priest of the Dark
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1612}         -- Promoted to Honorary Priest of the Dark
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestDark}
		evt.Add{"QBits", Value = 1611}         -- Promoted to Priest of the Dark
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1612}         -- Promoted to Honorary Priest of the Dark
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestDark}
		evt.Add{"QBits", Value = 1611}         -- Promoted to Priest of the Dark
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1612}         -- Promoted to Honorary Priest of the Dark
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestDark}
		evt.Add{"QBits", Value = 1611}         -- Promoted to Priest of the Dark
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1612}         -- Promoted to Honorary Priest of the Dark
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 556}         -- "Deface the Altar of Good in the Temple of the Sun on Evenmorn Isle then return to Daedalus Falk in the Deyja Moors."
	evt.Add{"Gold", Value = calculateGold(10000)}
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 386, Index = 0, Event = 0}         -- "Daedalus Falk"
	evt.SetNPCGreeting{NPC = 386, Greeting = 190}         --[[ "Daedalus Falk" : "Shadow Conceal, Brethren.
My time is always yours." ]]
end
-- "Wizard"
evt.global[843] = function()
	if not evt.Cmp{"QBits", Value = 586} then         -- Finished constructing Golem with normal head
		if not evt.Cmp{"QBits", Value = 585} then         -- Finished constructing Golem with Abbey normal head
			evt.SetMessage{Str = 205}         --[[ "You have to have all the parts together and properly assembled for me to animate it, students!
I can't animate incomplete golems." ]]
			return
		end
	end
	evt.SetMessage{Str = 1140}         --[[ "[You proudly display your assembled golem to Master Grey, and he nods approvingly] Well done.
Head looks alright, but you can never be sure…Well, good work!
Clearly, you qualify for Wizard status.
All Sorcerers amongst you are now Wizards, and all non Sorcerers are now honorary Wizards!
[Master Grey spends awhile casting the spell that animates your golem] He's all yours!
Take him back to your castle and put him where you want.
He'll attack intruders relentlessly.
" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Sorcerer} then
		evt.Set{"ClassIs", Value = const.Class.Wizard}
		evt.Add{"QBits", Value = 1619}         -- Promoted to Wizard
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1620}         -- Promoted to Honorary Wizard
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Sorcerer} then
		evt.Set{"ClassIs", Value = const.Class.Wizard}
		evt.Add{"QBits", Value = 1619}         -- Promoted to Wizard
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1620}         -- Promoted to Honorary Wizard
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Sorcerer} then
		evt.Set{"ClassIs", Value = const.Class.Wizard}
		evt.Add{"QBits", Value = 1619}         -- Promoted to Wizard
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1620}         -- Promoted to Honorary Wizard
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Sorcerer} then
		evt.Set{"ClassIs", Value = const.Class.Wizard}
		evt.Add{"QBits", Value = 1619}         -- Promoted to Wizard
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1620}         -- Promoted to Honorary Wizard
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.Subtract{"QBits", Value = 557}         -- "Collect the six golem pieces and construct a complete golem, then return to Thomas Grey in the School of Sorcery."
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 387, Index = 0, Event = 844}         -- "Thomas Grey" : "Archmage"
	evt.SetNPCGreeting{NPC = 395, Greeting = 199}         -- "Golem" : "I am yours to command, master."
	evt.Set{"QBits", Value = 558}         -- Player Castle.  Golem should appear in castle bit.
	evt.Subtract{"QBits", Value = 731}         -- Golem Head - I lost it
	evt.Subtract{"QBits", Value = 732}         -- Abby normal head - I lost it
end
-- "Archmage"
evt.global[845] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 1289} then         -- "Divine Intervention"
		evt.SetMessage{Str = 1145}         --[[ "I expect trouble finding the book, which is why I'm sending you to find it.
I know you can succeed in this mission.
Keep trying!" ]]
		return
	end
	evt.SetMessage{Str = 1144}         --[[ "The book!
The book!
[Master Grey clutches his ears and spins around in joy] You did it!
Oh, what a wonderful day!
I am so proud of you!
You're all Archmages!
Of course, if you weren't Wizards to begin with, it's only an honorary title, but who cares?
You found the book!
[The Master sets the book down on a table next to a blank book.
Both open simultaneously, and quill arises from the desk to begin copying the text in the new book] You may keep the copy, and you should start seeing more copies in the Light guilds of Bracada and Celeste." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
		evt.Set{"ClassIs", Value = const.Class.ArchMage}
		evt.Add{"QBits", Value = 1621}         -- Promoted to Archmage
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1622}         -- Promoted to Honorary Archmage
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
		evt.Set{"ClassIs", Value = const.Class.ArchMage}
		evt.Add{"QBits", Value = 1621}         -- Promoted to Archmage
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1622}         -- Promoted to Honorary Archmage
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
		evt.Set{"ClassIs", Value = const.Class.ArchMage}
		evt.Add{"QBits", Value = 1621}         -- Promoted to Archmage
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1622}         -- Promoted to Honorary Archmage
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
		evt.Set{"ClassIs", Value = const.Class.ArchMage}
		evt.Add{"QBits", Value = 1621}         -- Promoted to Archmage
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1622}         -- Promoted to Honorary Archmage
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 559}         -- "Find the Book of Divine Intervention in the Breeding Zone in the Pit and return it to Thomas Grey in the School of Sorcery."
	evt.Subtract{"QBits", Value = 738}         -- Book of Divine Intervention - I lost it
	evt.Add{"Gold", Value = calculateGold(10000)}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 387, Index = 0, Event = 0}         -- "Thomas Grey"
	evt.SetNPCGreeting{NPC = 387, Greeting = 192}         -- "Thomas Grey" : "I am honored to be graced with your presence, my lords."
end
-- "Lich"
evt.global[847] = function()
	evt.ForPlayer(0)
	if evt.Cmp{"Inventory", Value = 1417} then         -- "Lich Jar"
		evt.ForPlayer(1)
		if evt.Cmp{"Inventory", Value = 1417} then         -- "Lich Jar"
			evt.ForPlayer(2)
			if not evt.Cmp{"Inventory", Value = 1417} then         -- "Lich Jar"
				goto _11
			end
			evt.ForPlayer(3)
			if not evt.Cmp{"Inventory", Value = 1417} then         -- "Lich Jar"
				goto _11
			end
			evt.SetMessage{Str = 1150}         --[[ "Jars.
Yessss.
You have helped us greatly.
Now for the Ritual.
[The Lich draws a knife, and approaches you]
This won't hurt a bit!
[The ritual actually hurts quite a bit, and takes several hours to complete.
When it is over, the Lich speaks again]
So, now it is done.
Those among you who were Wizards are now most certainly Liches.
Those who were not, have my gratitude for returning the jars, and I will call you ""Honorary Liches"".
Remember, Liches must keep their Soul Jars with them at all times while they travel.
You cannot be separated from your Jar for long, or you will die a real death." ]]
			evt.ForPlayer(0)
			if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
				evt.Set{"ClassIs", Value = const.Class.Lich}
				evt.Add{"QBits", Value = 1623}         -- Promoted to Lich
				evt.Add{"Experience", Value = calculateExp(80000)}
			else
				evt.Add{"QBits", Value = 1624}         -- Promoted to Honorary Lich
				evt.Add{"Experience", Value = calculateExp(40000)}
			end
			goto _22
		end
	end
::_11::
	evt.SetMessage{Str = 1151}         --[[ "I have no spare Jars with which to perform the Ritual.
It is impossible for me to promote you until you return with the Jars.
Remember, each one of you must have a Jar to be Promoted." ]]
	do return end
::_22::
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
		evt.Set{"ClassIs", Value = const.Class.Lich}
		evt.Add{"QBits", Value = 1623}         -- Promoted to Lich
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1624}         -- Promoted to Honorary Lich
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
		evt.Set{"ClassIs", Value = const.Class.Lich}
		evt.Add{"QBits", Value = 1623}         -- Promoted to Lich
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1624}         -- Promoted to Honorary Lich
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
		evt.Set{"ClassIs", Value = const.Class.Lich}
		evt.Add{"QBits", Value = 1623}         -- Promoted to Lich
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1624}         -- Promoted to Honorary Lich
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 560}         -- "Retrieve the lich jars from the Proving Grounds in Celeste and bring them back to Halfgild Wynac in the Pit."
	evt.Subtract{"QBits", Value = 741}         -- Lich Jar (Empty) - I lost it
	evt.Add{"Gold", Value = calculateGold(7500)}
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
::_51::
	if not evt.Cmp{"Inventory", Value = 1417} then         -- "Lich Jar"
		evt.SetNPCTopic{NPC = 388, Index = 0, Event = 0}         -- "Halfgild Wynac"
		evt.SetNPCGreeting{NPC = 388, Greeting = 194}         --[[ "Halfgild Wynac" : "Why do you insist on bothering me?
[The Lich's eyes flare a hellish red for a moment] " ]]
		return
	end
	evt.Subtract{"Inventory", Value = 1417}         -- "Lich Jar"
	goto _51
end
-- "Great Druid"
evt.global[849] = function()
	if evt.Cmp{"QBits", Value = 562} then         -- Visited all stonehenges
		evt.SetMessage{Str = 1155}         --[[ "I have only to look into your eyes to see where you've been.
You have seen the circles, and they have left their imprint upon you.
Telling you that all Druids amongst you are now Great Druids is but a formality.
Telling the rest of you that you're now honorary Druids is showing you respect for the respect you have shown me and my faith.
" ]]
		evt.ForPlayer(0)
		if evt.Cmp{"ClassIs", Value = const.Class.Druid} then
			evt.Set{"ClassIs", Value = const.Class.GreatDruid}
			evt.Add{"QBits", Value = 1613}         -- Promoted to Great Druid
			evt.Add{"Experience", Value = calculateExp(30000)}
		else
			evt.Add{"QBits", Value = 1614}         -- Promoted to Honorary Great Druid
			evt.Add{"Experience", Value = calculateExp(15000)}
		end
		goto _17
	end
	if not evt.Cmp{"QBits", Value = 563} then         -- Visited stonehenge 1 (area 9)
		if not evt.Cmp{"QBits", Value = 564} then         -- Visited stonehenge 2 (area 13)
			if not evt.Cmp{"QBits", Value = 565} then         -- Visited stonehenge 3 (area 14)
				evt.SetMessage{Str = 1153}         --[[ "Visit the Circles, then return to me.
That is the process.
" ]]
				return
			end
		end
	end
	evt.SetMessage{Str = 1154}         --[[ "You've found a circle!
Very good, but you must find all three before you will be ready for promotion.
Remember, circles three, then return to me." ]]
	do return end
::_17::
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Druid} then
		evt.Set{"ClassIs", Value = const.Class.GreatDruid}
		evt.Add{"QBits", Value = 1613}         -- Promoted to Great Druid
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1614}         -- Promoted to Honorary Great Druid
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Druid} then
		evt.Set{"ClassIs", Value = const.Class.GreatDruid}
		evt.Add{"QBits", Value = 1613}         -- Promoted to Great Druid
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1614}         -- Promoted to Honorary Great Druid
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Druid} then
		evt.Set{"ClassIs", Value = const.Class.GreatDruid}
		evt.Add{"QBits", Value = 1613}         -- Promoted to Great Druid
		evt.Add{"Experience", Value = calculateExp(30000)}
	else
		evt.Add{"QBits", Value = 1614}         -- Promoted to Honorary Great Druid
		evt.Add{"Experience", Value = calculateExp(15000)}
	end
	evt.Subtract{"QBits", Value = 561}         -- "Visit the three stonehenge monoliths in Tatalia, the Evenmorn Islands, and Avlee, then return to Anthony Green in the Tularean Forest."
	evt.Subtract{"Reputation", Value = 5}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 389, Index = 0, Event = 850}         -- "Anthony Green" : "Arch Druid"
end
-- "Arch Druid"
evt.global[851] = function()
	if not evt.Cmp{"QBits", Value = 577} then         -- Barrow downs.   Returned the bones of the Dwarf King.  Arch Druid promo quest.
		evt.SetMessage{Str = 1160}         --[[ "The Service is not easy, but it needs to be done.
Remember, you must bring the bones of King Zokarr IV from where they lie in the tunnels between Stone City and Nighon to Zokarr's coffin in a secret dwarven barrow.
Only then can I perform the Ceremony of Ascension and promote you." ]]
		return
	end
	evt.SetMessage{Str = 1159}         --[[ "[Master Green seems beside himself with joy at your accomplishment] I felt the King's soul return to the land of the dead when you returned his bones.
The land breathed a sigh of relief--did you feel it?
The Ceremony of Ascension is complete.
I'm happy to promote all Great Druids amongst you to Arch Druids, and all honorary Great Druids to Honorary Arch Druids.
This is a very happy day!
Your service will be remembered!" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.ArchDruid}
		evt.Add{"QBits", Value = 1615}         -- Promoted to Arch Druid
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1616}         -- Promoted to Honorary Arch Druid
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.ArchDruid}
		evt.Add{"QBits", Value = 1615}         -- Promoted to Arch Druid
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1616}         -- Promoted to Honorary Arch Druid
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.ArchDruid}
		evt.Add{"QBits", Value = 1615}         -- Promoted to Arch Druid
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1616}         -- Promoted to Honorary Arch Druid
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.ArchDruid}
		evt.Add{"QBits", Value = 1615}         -- Promoted to Arch Druid
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1616}         -- Promoted to Honorary Arch Druid
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 566}         -- "Retrieve the bones of the Dwarf King from the tunnels between Stone City and Nighon and place them in their proper resting place in the Barrow Downs, then return to Anthony Green in the Tularean Forest."
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.SetNPCTopic{NPC = 389, Index = 0, Event = 0}         -- "Anthony Green"
	evt.SetNPCGreeting{NPC = 389, Greeting = 196}         --[[ "Anthony Green" : "Fortune be your friend, lords.
Do you seek my advice today?" ]]
end
-- "Warlock"
evt.global[853] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 1449} then         -- "Dragon Egg"
		evt.SetMessage{Str = 1166}         --[[ "You need to bring me a dragon's egg so you I can hatch your familiar.
There is no way around this.
Try looking in the Land of the Giants for a dragon cave-- perhaps there you can find an egg." ]]
		return
	end
	evt.SetMessage{Str = 1165}         --[[ "[Tor looks at you in astonishment] You really found a dragon egg!
It's been more than a century since any Warlock has both needed and found a dragon familiar!
This will go down in the history books, that's for sure!
My spell book!
I need my book!
Ah, here it is.
[Tor chants a spell from the book, then taps the egg three times.
The egg hatches, and a baby dragon crawls out of the shell]
There you are!
Awww, isn't he cute?
Congratulations!
No longer are you simple Great Druids, but Warlocks!
Of course, that's just an honorary title if you weren't a natural Great Druid to begin with, but nonetheless, something to be proud of.
" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.Warlock}
		evt.Add{"QBits", Value = 1617}         -- Promoted to Warlock
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1618}         -- Promoted to Honorary Warlock
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.Warlock}
		evt.Add{"QBits", Value = 1617}         -- Promoted to Warlock
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1618}         -- Promoted to Honorary Warlock
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.Warlock}
		evt.Add{"QBits", Value = 1617}         -- Promoted to Warlock
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1618}         -- Promoted to Honorary Warlock
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.Warlock}
		evt.Add{"QBits", Value = 1617}         -- Promoted to Warlock
		evt.Add{"Experience", Value = calculateExp(80000)}
	else
		evt.Add{"QBits", Value = 1618}         -- Promoted to Honorary Warlock
		evt.Add{"Experience", Value = calculateExp(40000)}
	end
	evt.Subtract{"QBits", Value = 567}         -- "Retrieve the dragon egg from the Dragon Cave in the Land of the Giants and return it to Tor Anwyn in Mount Nighon."
	evt.Subtract{"Reputation", Value = 10}
	evt.ForPlayer("All")
	evt.Subtract{"Inventory", Value = 1449}         -- "Dragon Egg"
	evt.Subtract{"QBits", Value = 739}         -- Dragon Egg - I lost it
	evt.SetNPCTopic{NPC = 390, Index = 0, Event = 0}         -- "Tor Anwyn"
	evt.SetNPCGreeting{NPC = 389, Greeting = 198}         --[[ "Anthony Green" : "A delight and a pleasure, lords.
Have you come for business or conversation?" ]]
	evt.Set{"QBits", Value = 1687}         -- Replacement for NPCs ¹57 ver. 7
end
-- "Goblins"
evt.global[856] = function()
	if evt.Cmp{"QBits", Value = 647} then         -- Player castle goblins are all dead
		evt.SetMessage{Str = 1179}         --[[ "Thank heavens you've cleaned them out!
Now we need to find a way to clean up the castle and rebuild the damaged sections.
The only people I can think of who would have the inclination and the ability to do this are the Dwarves in Stone City, located in the Barrow Downs to the south.
The entrance to Stone City lies in the center of the Barrow Downs on one of the largest hills.
" ]]
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.Subtract{"QBits", Value = 587}         -- "Clean out Castle Harmondale and return to the Butler in the tavern, On the House, in Harmondale."
		evt.Add{"Awards", Value = 3}         -- "Removed goblins from Castle Harmondale"
		evt.MoveNPC{NPC = 397, HouseId = 1169}         -- "Butler" -> "Throne Room"
		evt.SetNPCTopic{NPC = 397, Index = 0, Event = 0}         -- "Butler"
		evt.SetNPCGreeting{NPC = 397, Greeting = 201}         -- "Butler" : "You rang, my lords?"
		evt.Set{"QBits", Value = 658}         -- "Talk to the Dwarves in Stone City in the Barrow Downs to find a way to repair Castle Harmondale."
	else
		evt.SetMessage{Str = 1180}         --[[ "I fear that talking will fail with these goblins, my lords.
May I suggest violence?" ]]
	end
end
-- "Rescue Dwarves"
evt.global[858] = function()
	if evt.Cmp{"QBits", Value = 1688} then         -- Replacement for NPCs ¹60 ver. 7
		if evt.Cmp{"QBits", Value = 1689} then         -- Replacement for NPCs ¹61 ver. 7
			if evt.Cmp{"QBits", Value = 1690} then         -- Replacement for NPCs ¹62 ver. 7
				if evt.Cmp{"QBits", Value = 1691} then         -- Replacement for NPCs ¹63 ver. 7
					if evt.Cmp{"QBits", Value = 1692} then         -- Replacement for NPCs ¹64 ver. 7
						if evt.Cmp{"QBits", Value = 1693} then         -- Replacement for NPCs ¹65 ver. 7
							if evt.Cmp{"QBits", Value = 1694} then         -- Replacement for NPCs ¹66 ver. 7
								evt.SetMessage{Str = 1182}         --[[ "Welcome back, Lords of Harmondale!
Now, I will help you.
My engineer will work for you.
Fix up your castle.
You have my thanks.
You are welcome here forever.Hmmph.
One more thing.
Your work has interested the other courts.
They will send ambassadors to you now--check your throne room.
Watch your back, my friends." ]]
								evt.Add{"History4", Value = 0}
								evt.Add{"Gold", Value = calculateGold(5000)}
								evt.Subtract{"QBits", Value = 588}         -- "Rescue the dwarves from the Red Dwarf Mines and return to the Dwarf King in Stone City in the Barrow Downs."
								evt.Subtract{"Reputation", Value = 5}
								evt.ForPlayer("All")
								evt.Add{"Awards", Value = 4}         -- "Rescued the dwarves from the Red Dwarf Mine"
								evt.Add{"Experience", Value = calculateExp(12500)}
								evt.Subtract{"Inventory", Value = 1431}         -- "Elixir"
								evt.Subtract{"QBits", Value = 742}         -- Elixir - I lost it
								evt.Set{"QBits", Value = 610}         -- Built Castle to Level 2 (rescued dwarf guy)
								evt.Subtract{"QBits", Value = 1688}         -- Replacement for NPCs ¹60 ver. 7
								evt.MoveNPC{NPC = 399, HouseId = 0}         -- "Drathen Keldin"
								evt.MoveNPC{NPC = 406, HouseId = 1169}         -- "Ellen Rockway" -> "Throne Room"
								evt.MoveNPC{NPC = 407, HouseId = 1169}         -- "Alain Hani" -> "Throne Room"
								evt.Subtract{"QBits", Value = 1689}         -- Replacement for NPCs ¹61 ver. 7
								evt.Subtract{"QBits", Value = 1690}         -- Replacement for NPCs ¹62 ver. 7
								evt.Subtract{"QBits", Value = 1691}         -- Replacement for NPCs ¹63 ver. 7
								evt.Subtract{"QBits", Value = 1692}         -- Replacement for NPCs ¹64 ver. 7
								evt.Subtract{"QBits", Value = 1693}         -- Replacement for NPCs ¹65 ver. 7
								evt.Subtract{"QBits", Value = 1694}         -- Replacement for NPCs ¹66 ver. 7
								evt.SetNPCTopic{NPC = 398, Index = 0, Event = 0}         -- "Hothfarr IX"
								evt.SetNPCGreeting{NPC = 398, Greeting = 203}         --[[ "Hothfarr IX" : "Welcome, Harmondale!
Stone city is at your disposal." ]]
								return
							end
						end
					end
				end
			end
		end
	end
	evt.SetMessage{Str = 1183}         --[[ "Back again, eh?
Your part of the bargain isn't finished.
No help 'til you're done.
" ]]
end
evt.global[868] = function()
	evt.SetMessage{Str = 1188}         --[[ "[Lady Ellen gasps in delight] You have Gryphonheart's Trumpet!
This is wonderful!
When it disappeared from the strongbox, we thought it had been stolen by the enemy!
Thank you for bringing it back to us!" ]]
	evt.Add{"Gold", Value = calculateGold(5000)}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(10000)}
	evt.Subtract{"Inventory", Value = 1436}         -- "Gryphonheart's Trumpet"
	evt.Subtract{"QBits", Value = 591}         -- "Retrieve Gryphonheart's Trumpet from the battle in the Tularean Forest and return it to whichever side you choose."
	evt.Set{"QBits", Value = 596}         -- Gave artifact to humans
	evt.SetNPCTopic{NPC = 406, Index = 2, Event = 0}         -- "Ellen Rockway"
end
evt.global[872] = function()
	evt.SetMessage{Str = 1195}         --[[ "You have Gryphonheart's Trumpet!
Excellent!
We lost track of it during the raid, and were afraid that one of the Erathians got away with it.
Thank you very much for your help!" ]]
	evt.Add{"Gold", Value = calculateGold(5000)}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(10000)}
	evt.Subtract{"Inventory", Value = 1436}         -- "Gryphonheart's Trumpet"
	evt.Subtract{"QBits", Value = 591}         -- "Retrieve Gryphonheart's Trumpet from the battle in the Tularean Forest and return it to whichever side you choose."
	evt.Set{"QBits", Value = 597}         -- Gave artifact to elves
	evt.SetNPCTopic{NPC = 407, Index = 2, Event = 0}         -- "Alain Hani"
end
-- "Prisoner of War"
evt.global[875] = function()
	if evt.Cmp{"Counter1", Value = 672} then
		evt.SetMessage{Str = 273}         --[[ "Well, time ran out for poor Loren.
He was executed for espionage by Avlee on schedule.
Don't bother with the rescue.
He's gone." ]]
		evt.SetNPCTopic{NPC = 408, Index = 0, Event = 0}         -- "Queen Catherine"
		evt.SetNPCTopic{NPC = 408, Index = 1, Event = 0}         -- "Queen Catherine"
		evt.Subtract{"QBits", Value = 1695}         -- Replacement for NPCs ¹71 ver. 7
		evt.Subtract{"QBits", Value = 1696}         -- Replacement for NPCs ¹72 ver. 7
		evt.Subtract{"QBits", Value = 590}         -- "Rescue Loren Steel from the Tularean Caves in the Tularean Forest and return him to Queen Catherine."
		evt.Subtract{"QBits", Value = 607}         -- "Return the Loren imposter to Queen Catherine in Castle Gryphonheart in Erathia."
	elseif not evt.Cmp{"QBits", Value = 1695} then         -- Replacement for NPCs ¹71 ver. 7
		if evt.Cmp{"QBits", Value = 1696} then         -- Replacement for NPCs ¹72 ver. 7
			evt.SetMessage{Str = 1201}         --[[ "[Catherine stands and smiles] Good job!
You've really solved a terrible dilemma for me.
[Catherine turns to the false Loren and shakes his hand] Loren.
It's good to meet you at last.
Since everyone knows who you are now, you're not much good to me as a spy, but I would like to offer you a job in the Royal Diplomatic Corps.
Please give it some thought.
As for our heroes, you have my thanks.
 " ]]
			evt.Subtract{"QBits", Value = 590}         -- "Rescue Loren Steel from the Tularean Caves in the Tularean Forest and return him to Queen Catherine."
			evt.Subtract{"QBits", Value = 607}         -- "Return the Loren imposter to Queen Catherine in Castle Gryphonheart in Erathia."
			evt.Add{"QBits", Value = 595}         -- Gave false Loren to Catherine (betray)
			evt.Add{"Reputation", Value = 5}
			evt.ForPlayer("All")
			evt.Add{"QBits", Value = 1557}         -- Gave Loren Imposter to Catherine
			evt.SetNPCTopic{NPC = 408, Index = 0, Event = 0}         -- "Queen Catherine"
			evt.SetNPCTopic{NPC = 408, Index = 1, Event = 0}         -- "Queen Catherine"
			evt.Subtract{"QBits", Value = 1695}         -- Replacement for NPCs ¹71 ver. 7
			evt.Subtract{"QBits", Value = 1696}         -- Replacement for NPCs ¹72 ver. 7
		else
			evt.SetMessage{Str = 1200}         --[[ "Loren's life is on the line.
I cannot give into the Elvish demands, or many more lives will be lost.
Please hurry.
I'm sure Avlee will execute him on schedule." ]]
		end
		return
	end
	evt.SetMessage{Str = 1199}         --[[ "[Catherine stands and smiles] Good job!
You've really solved a terrible dilemma for me.
[Catherine turns to Loren and shakes his hand] Loren.
It's good to meet you at last.
Since everyone knows who you are now, you're not much good to me as a spy, but I would like to offer you a job in the Royal Diplomatic Corps.
Please give it some thought.
As for our heroes, you have my thanks.
My purser will credit your bank account with 5000 gold pieces for your services.
 " ]]
	evt.Subtract{"QBits", Value = 590}         -- "Rescue Loren Steel from the Tularean Caves in the Tularean Forest and return him to Queen Catherine."
	evt.Add{"QBits", Value = 593}         -- Gave Loren to Catherine
	evt.ForPlayer(4)
	evt.Add{"BankGold", Value = 5000}
	evt.Subtract{"Reputation", Value = 5}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(10000)}
	evt.Add{"QBits", Value = 1556}         -- Rescued Loren Steel
	evt.SetNPCTopic{NPC = 408, Index = 0, Event = 0}         -- "Queen Catherine"
	evt.SetNPCTopic{NPC = 408, Index = 1, Event = 0}         -- "Queen Catherine"
	evt.Subtract{"QBits", Value = 1695}         -- Replacement for NPCs ¹71 ver. 7
	evt.Subtract{"QBits", Value = 1696}         -- Replacement for NPCs ¹72 ver. 7
end
-- "Riverstride plans"
evt.global[878] = function()
	if evt.Cmp{"QBits", Value = 594} then         -- Gave false plans to elfking (betray)
		evt.SetMessage{Str = 1204}         --[[ "He took the plans?
Excellent!
I'll have the Riverstride commander roll out the red carpet for them.
As for you, I've instructed my purser to deposit 5,000 gold pieces in your account." ]]
		evt.Subtract{"Reputation", Value = 5}
		evt.Subtract{"QBits", Value = 606}         -- "Give false Riverstride plans to Eldrich Parson in Castle Navan in the Tularean Forest."
		evt.Subtract{"QBits", Value = 589}         -- "Retrieve plans from Fort Riverstride and return them to Eldrich Parson in Castle Navan in the Tularean Forest."
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.ForPlayer(4)
		evt.Add{"BankGold", Value = 5000}
		evt.SetNPCTopic{NPC = 408, Index = 2, Event = 0}         -- "Queen Catherine"
		evt.SetNPCTopic{NPC = 408, Index = 3, Event = 0}         -- "Queen Catherine"
	elseif evt.Cmp{"QBits", Value = 603} then         -- Told Elfking about fake plans
		evt.SetMessage{Str = 271}         --[[ "You told the king the plans were fake?!?
[The Queen puts her hand on her head, jaw agape] I have never seen such incompetence in all my life!
Astounding!
Get out of my sight!
Just go!
" ]]
		evt.ForPlayer("All")
		evt.Subtract{"Inventory", Value = 1508}         -- "False Riverstride Plans"
		evt.Subtract{"Inventory", Value = 1507}         -- "Riverstride Plans"
		evt.Subtract{"QBits", Value = 606}         -- "Give false Riverstride plans to Eldrich Parson in Castle Navan in the Tularean Forest."
		evt.Subtract{"QBits", Value = 589}         -- "Retrieve plans from Fort Riverstride and return them to Eldrich Parson in Castle Navan in the Tularean Forest."
		evt.SetNPCTopic{NPC = 408, Index = 2, Event = 0}         -- "Queen Catherine"
		evt.SetNPCTopic{NPC = 408, Index = 3, Event = 0}         -- "Queen Catherine"
	elseif evt.Cmp{"Counter2", Value = 672} then
		evt.SetMessage{Str = 274}         --[[ "King Parson is beyond the date when he could have used those false papers.
Don't bother taking them to him--it doesn't matter anymore.
" ]]
		evt.Subtract{"Inventory", Value = 1508}         -- "False Riverstride Plans"
		evt.Subtract{"Inventory", Value = 1507}         -- "Riverstride Plans"
		evt.SetNPCTopic{NPC = 408, Index = 2, Event = 0}         -- "Queen Catherine"
		evt.SetNPCTopic{NPC = 408, Index = 3, Event = 0}         -- "Queen Catherine"
		evt.Subtract{"QBits", Value = 606}         -- "Give false Riverstride plans to Eldrich Parson in Castle Navan in the Tularean Forest."
		evt.Subtract{"QBits", Value = 589}         -- "Retrieve plans from Fort Riverstride and return them to Eldrich Parson in Castle Navan in the Tularean Forest."
	else
		evt.SetMessage{Str = 270}         --[[ "You have to get the plans to him before he attacks Riverstride.
If you don't, they won't lead his forces into all the traps we've prepared for them.
So hurry up and deliver those plans!
I'm counting on you!" ]]
	end
end
evt.global[880] = function()
	evt.SetMessage{Str = 287}         --[[ "My loyal subjects!
You were the ones who took the Trumpet!
Good work.
We thought it lost forever.
Once again, my purser will deposit gold in your account.
5,000 gold, to be exact." ]]
	evt.Add{"BankGold", Value = 5000}
	evt.Subtract{"Reputation", Value = 5}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(10000)}
	evt.Subtract{"Inventory", Value = 1436}         -- "Gryphonheart's Trumpet"
	evt.Subtract{"QBits", Value = 591}         -- "Retrieve Gryphonheart's Trumpet from the battle in the Tularean Forest and return it to whichever side you choose."
	evt.Set{"QBits", Value = 596}         -- Gave artifact to humans
	evt.SetNPCTopic{NPC = 408, Index = 4, Event = 0}         -- "Queen Catherine"
end
-- "Riverstride plans"
evt.global[882] = function()
	if evt.Cmp{"Counter2", Value = 672} then
		evt.SetMessage{Str = 285}         --[[ "The time where I could have used those plans is over.
Thanks for any efforts you may have put into finding them, but I no longer need the plans." ]]
		evt.SetNPCTopic{NPC = 409, Index = 0, Event = 0}         -- "ElfKing"
		evt.SetNPCTopic{NPC = 409, Index = 1, Event = 0}         -- "ElfKing"
		evt.Subtract{"Inventory", Value = 1507}         -- "Riverstride Plans"
		evt.Subtract{"Inventory", Value = 1508}         -- "False Riverstride Plans"
		evt.Subtract{"QBits", Value = 589}         -- "Retrieve plans from Fort Riverstride and return them to Eldrich Parson in Castle Navan in the Tularean Forest."
		evt.Subtract{"QBits", Value = 606}         -- "Give false Riverstride plans to Eldrich Parson in Castle Navan in the Tularean Forest."
	else
		evt.ForPlayer("All")
		if not evt.Cmp{"Inventory", Value = 1507} then         -- "Riverstride Plans"
			if evt.Cmp{"Inventory", Value = 1508} then         -- "False Riverstride Plans"
				evt.SetMessage{Str = 278}         --[[ "[The King smiles broadly as you hand him the false plans.
Sucker! ]
Thank you!
These will be VERY useful.
When we finally win this round against Erathia, I will not forget you." ]]
				evt.Subtract{"QBits", Value = 589}         -- "Retrieve plans from Fort Riverstride and return them to Eldrich Parson in Castle Navan in the Tularean Forest."
				evt.Subtract{"QBits", Value = 606}         -- "Give false Riverstride plans to Eldrich Parson in Castle Navan in the Tularean Forest."
				evt.Add{"QBits", Value = 594}         -- Gave false plans to elfking (betray)
				evt.Add{"Reputation", Value = 5}
				evt.ForPlayer("All")
				evt.Add{"QBits", Value = 1559}         -- Gave false plans to Elfking
				evt.SetNPCTopic{NPC = 409, Index = 0, Event = 0}         -- "ElfKing"
				evt.SetNPCTopic{NPC = 409, Index = 1, Event = 0}         -- "ElfKing"
				evt.Subtract{"Inventory", Value = 1508}         -- "False Riverstride Plans"
				evt.Subtract{"Inventory", Value = 1507}         -- "Riverstride Plans"
			else
				evt.SetMessage{Str = 277}         --[[ "I really do need those plans soon.
If you take too long, I'll have to prepare my attack without the plans." ]]
			end
			return
		end
	end
	evt.SetMessage{Str = 276}         --[[ "[The King smiles broadly as you hand him the plans]
Thank you!
These will be VERY useful.
My factor will deposit 5,000 gold pieces in your bank account for services rendered.
When we finally win this round against Erathia, I will not forget you." ]]
	evt.Subtract{"QBits", Value = 589}         -- "Retrieve plans from Fort Riverstride and return them to Eldrich Parson in Castle Navan in the Tularean Forest."
	evt.Subtract{"QBits", Value = 606}         -- "Give false Riverstride plans to Eldrich Parson in Castle Navan in the Tularean Forest."
	evt.Add{"QBits", Value = 592}         -- Gave plans to elfking
	evt.ForPlayer(4)
	evt.Add{"BankGold", Value = 5000}
	evt.Subtract{"Reputation", Value = 5}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(10000)}
	evt.Add{"QBits", Value = 1558}         -- Retrieved Fort Riverstride Plans
	evt.SetNPCTopic{NPC = 409, Index = 0, Event = 0}         -- "ElfKing"
	evt.SetNPCTopic{NPC = 409, Index = 1, Event = 0}         -- "ElfKing"
	evt.Subtract{"Inventory", Value = 1507}         -- "Riverstride Plans"
	evt.Subtract{"Inventory", Value = 1508}         -- "False Riverstride Plans"
end
-- "Prison Break"
evt.global[885] = function()
	if evt.Cmp{"QBits", Value = 595} then         -- Gave false Loren to Catherine (betray)
		evt.SetMessage{Str = 281}         --[[ "The imposter has infiltrated her military and diplomatic advisors' ranks, and will cause plenty of damage before he's discovered, I'm sure.
Thank you for your help! My factor will deposit 5000 gold into your account at the bank." ]]
		evt.Subtract{"QBits", Value = 607}         -- "Return the Loren imposter to Queen Catherine in Castle Gryphonheart in Erathia."
		evt.Subtract{"Reputation", Value = 5}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.ForPlayer(4)
		evt.Add{"BankGold", Value = 5000}
		evt.SetNPCTopic{NPC = 409, Index = 2, Event = 0}         -- "ElfKing"
		evt.SetNPCTopic{NPC = 409, Index = 3, Event = 0}         -- "ElfKing"
	elseif evt.Cmp{"QBits", Value = 602} then         -- Told Catherine about fake prisoner
		evt.SetMessage{Str = 283}         --[[ "You told Queen Catherine about the imposter?!? I can't believe my ears!
Why did you do it?
Why?
[The King stands and points at the door] Get out!" ]]
		evt.ForPlayer("All")
		evt.Subtract{"QBits", Value = 1696}         -- Replacement for NPCs ¹72 ver. 7
		evt.Subtract{"QBits", Value = 1695}         -- Replacement for NPCs ¹71 ver. 7
		evt.Subtract{"QBits", Value = 607}         -- "Return the Loren imposter to Queen Catherine in Castle Gryphonheart in Erathia."
		evt.SetNPCTopic{NPC = 409, Index = 2, Event = 0}         -- "ElfKing"
		evt.SetNPCTopic{NPC = 409, Index = 3, Event = 0}         -- "ElfKing"
	elseif evt.Cmp{"Counter1", Value = 672} then
		evt.SetMessage{Str = 286}         --[[ "The execution date for Loren Steel has passed.
Don't bother bringing the imposter to the Queen--she'll be too suspicious for our ruse to succeed.
He'll be leaving you now." ]]
		evt.Subtract{"QBits", Value = 1696}         -- Replacement for NPCs ¹72 ver. 7
		evt.Subtract{"QBits", Value = 1695}         -- Replacement for NPCs ¹71 ver. 7
		evt.SetNPCTopic{NPC = 409, Index = 2, Event = 0}         -- "ElfKing"
		evt.SetNPCTopic{NPC = 409, Index = 3, Event = 0}         -- "ElfKing"
		evt.Subtract{"QBits", Value = 607}         -- "Return the Loren imposter to Queen Catherine in Castle Gryphonheart in Erathia."
		evt.Subtract{"QBits", Value = 590}         -- "Rescue Loren Steel from the Tularean Caves in the Tularean Forest and return him to Queen Catherine."
	else
		evt.SetMessage{Str = 282}         --[[ "It's important to get the imposter to the Queen before Mr. Steel's scheduled execution.
After all, you can't rescue Mr. Steel if everyone knows I've executed him.
And she'll become suspicious if I stay the execution.
I've never stayed one before." ]]
	end
end
evt.global[887] = function()
	evt.SetMessage{Str = 288}         --[[ "Ah, the Trumpet!
You captured it!
We weren't sure how things turned out when news of the human raid reached us.
Thank you again, my friends.
My factor will deposit 5,000 gold in your account for your services." ]]
	evt.Add{"BankGold", Value = 5000}
	evt.Subtract{"Reputation", Value = 5}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(10000)}
	evt.Subtract{"Inventory", Value = 1436}         -- "Gryphonheart's Trumpet"
	evt.Subtract{"QBits", Value = 591}         -- "Retrieve Gryphonheart's Trumpet from the battle in the Tularean Forest and return it to whichever side you choose."
	evt.Set{"QBits", Value = 597}         -- Gave artifact to elves
	evt.SetNPCTopic{NPC = 409, Index = 4, Event = 0}         -- "ElfKing"
end
evt.global[890] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1436} then         -- "Gryphonheart's Trumpet"
		evt.SetMessage{Str = 291}         --[[ "You were wise to return the Trumpet to me.
Now I can use it to help shore up the weak side in this conflict and promote peace.
Thank you.
" ]]
		evt.Set{"QBits", Value = 659}         -- Gave artifact to arbiter
		evt.Add{"Experience", Value = calculateExp(12500)}
		evt.Subtract{"Inventory", Value = 1436}         -- "Gryphonheart's Trumpet"
		evt.Subtract{"QBits", Value = 591}         -- "Retrieve Gryphonheart's Trumpet from the battle in the Tularean Forest and return it to whichever side you choose."
		evt.SetNPCTopic{NPC = 413, Index = 2, Event = 0}         -- "Judge Grey"
	end
end
-- "Proving Grounds"
evt.global[896] = function()
	if evt.Cmp{"QBits", Value = 614} then         -- Completed Proving Grounds without killing a single creature
		evt.SetMessage{Str = 1212}         --[[ "You passed the Test!
That's quite an achievement--few succeed as quickly as you did.
My advisors are now eager to speak to
you; they can be found in the four houses on the eastern side of Celeste.
Once again, congratulations!" ]]
		evt.Subtract{"QBits", Value = 613}         -- "Complete the Walls of Mist without killing a single opponent and return to Gavin Magnus in Castle Lambent in Celeste."
		evt.SetNPCTopic{NPC = 418, Index = 0, Event = 0}         -- "Gavin Magnus"
		evt.Add{"History10", Value = 0}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Add{"QBits", Value = 626}         -- Finished Wizard Proving Grounds
		evt.Add{"Awards", Value = 6}         -- "Completed Wizard Proving Grounds"
		evt.SetNPCGreeting{NPC = 418, Greeting = 223}         --[[ "Gavin Magnus" : "Welcome back, my friends.
My advisors are anxious to speak with you.
" ]]
		evt.MoveNPC{NPC = 419, HouseId = 1062}         -- "Resurectra" -> "Hostel"
		evt.MoveNPC{NPC = 420, HouseId = 1063}         -- "Crag Hack" -> "Hostel"
		evt.MoveNPC{NPC = 421, HouseId = 1064}         -- "Sir Caneghem" -> "Hostel"
		evt.MoveNPC{NPC = 422, HouseId = 1065}         -- "Robert the Wise" -> "Hostel"
		evt.SetNPCGreeting{NPC = 419, Greeting = 226}         -- "Resurectra" : "Always a pleasure to see you, Lords."
		evt.SetNPCGreeting{NPC = 420, Greeting = 229}         --[[ "Crag Hack" : "It's good to see you again, lords.
I hope all is well with you and your realm." ]]
		evt.SetNPCGreeting{NPC = 421, Greeting = 232}         --[[ "Sir Caneghem" : "Ah, welcome back my lords.
I hope all is well." ]]
		evt.SetNPCGreeting{NPC = 422, Greeting = 235}         --[[ "Robert the Wise" : "I'm happy you're still alive and working for the Light.
Come and see me when you've finished my friend's tasks." ]]
		evt.Add{"QBits", Value = 1605}         -- Joined the Light Guild
	else
		evt.SetMessage{Str = 1213}         --[[ "Remember, you must enter through the front door of the Walls of Mist, and exit through the back door.
You must not kill any creatures in the Walls of Mist.
When you have done this, return to me." ]]
	end
end
-- "Temple of the Dark"
evt.global[898] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1478} then         -- "Altar Piece"
		if evt.Cmp{"Inventory", Value = 1479} then         -- "Altar Piece"
			evt.SetMessage{Str = 1218}         --[[ "I knew you could do it!
Never doubted you for a second!
[You hand her the key halves, and she joins them by running a finger along the crack between them.
It mends before your eyes, good as new] Finally!
One piece of the plan is in place.
Your assistance has been invaluable.
We are already in your debt, and I expect we'll be even deeper in debt before our plan comes to fruition.
So have faith in us awhile longer--the future we're planning will astound you!" ]]
			evt.Subtract{"Inventory", Value = 1478}         -- "Altar Piece"
			evt.Subtract{"Inventory", Value = 1479}         -- "Altar Piece"
			evt.Subtract{"QBits", Value = 744}         -- Altar Piece (Good) - I lost it
			evt.Subtract{"QBits", Value = 745}         -- Altar Piece (Evil) - I lost it
			evt.Add{"History12", Value = 0}
			evt.Add{"Experience", Value = calculateExp(50000)}
			evt.SetNPCTopic{NPC = 419, Index = 0, Event = 0}         -- "Resurectra"
			evt.Subtract{"QBits", Value = 615}         -- "Retrieve the altar piece from the Temple of Light in Celeste and the Temple of Dark in the Pit and return them to Resurectra in Castle Lambent in Celeste."
			evt.Set{"QBits", Value = 627}         -- Finished Wizard Task 2 - Temple of Dark
			evt.Set{"Awards", Value = 19}         -- "Retrieved Both Temple Pieces"
			evt.SetNPCGreeting{NPC = 419, Greeting = 227}         -- "Resurectra" : "Always a pleasure to see you, Lords."
			evt.ForPlayer(4)
			evt.Subtract{"Reputation", Value = 5}
		else
			evt.SetMessage{Str = 1216}         --[[ "Well, I'm glad you found our half of the key, but you still need their half.
Hold onto it until you get the other half.
When you have both halves, return to me.
I will make them whole." ]]
		end
	elseif evt.Cmp{"Inventory", Value = 1479} then         -- "Altar Piece"
		evt.SetMessage{Str = 1217}         --[[ "Good work on retrieving their half of the key, but you still need ours.
It is located in the Temple of the Light here in Celeste." ]]
	else
		evt.SetMessage{Str = 1215}         --[[ "No key halves yet, I see.
Well, take your time.
It must be done eventually, and sooner is better than later, but later is better than being chained to an altar and sacrificed by the High Priest of the Dark in one of their bloody rituals.
Just bring back both halves of the key from the temples of Dark and Light, and try not to get yourselves killed doing it." ]]
	end
end
-- "Strike the Devils"
evt.global[900] = function()
	if evt.Cmp{"QBits", Value = 617} then         -- Slayed Xenofex
		evt.ShowMovie{DoubleSize = 1, Name = "\"mm3 people good\""}
		evt.SetMessage{Str = 1220}         --[[ "YOU ARE HEROES!!!
Your work against the devils was masterful!
And the rescue of King Roland was as delightful as it was unexpected.
History will never forget your names for doing what you just did!
I, for one, am very proud to know you.
" ]]
		evt.Add{"Gold", Value = calculateGold(50000)}
		evt.Subtract{"Reputation", Value = 10}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(500000)}
		evt.Subtract{"QBits", Value = 616}         -- "Go to Colony Zod in the Land of the Giants and slay Xenofex then return to Resurectra in Castle Lambent in Celeste."
		evt.Set{"QBits", Value = 632}         -- Got Hive part
		evt.SetNPCTopic{NPC = 419, Index = 1, Event = 919}         -- "Resurectra" : "Final Task"
		evt.Add{"Awards", Value = 21}         -- "Slayed Xenofex"
	else
		evt.SetMessage{Str = 1221}         --[[ "I guess there's no hurry getting this job done, but we don't want the Necromancers to grow bored waiting for us to do our part and destroy the blocker.
So, please, as soon as you feel ready you must attack the Devils.
Remember that the Warlocks have dug a tunnel from their volcano to the land of the Devils.
You should be able to use that to get yourselves there." ]]
	end
end
-- "Vampires"
evt.global[902] = function()
	if evt.Cmp{"QBits", Value = 619} then         -- Slayed the vampire
		evt.SetMessage{Str = 1223}         --[[ "Just as I suspected!
Good work.
With the death of the Vampire, Tatalia can sleep a bit easier now.
Queen Catherine is grateful as well, and has been making moves to further strengthen the ties between Bracada and Erathia." ]]
		evt.Add{"Gold", Value = calculateGold(20000)}
		evt.Add{"History13", Value = 0}
		evt.Subtract{"Reputation", Value = 5}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Add{"Awards", Value = 22}         -- "Solved the Mystery of the Wine Cellar"
		evt.SetNPCTopic{NPC = 420, Index = 0, Event = 0}         -- "Crag Hack"
		evt.SetNPCGreeting{NPC = 420, Greeting = 230}         --[[ "Crag Hack" : "It's good to see you again, lords.
I hope all is well with you and your realm." ]]
		evt.Subtract{"QBits", Value = 618}         -- "Investigate the Wine Cellar in Tatalia and return to Crag Hack in Castle Lambent in Celeste."
		evt.Add{"QBits", Value = 628}         -- Finished Wizard Task 3 - Wine Cellar
	else
		evt.SetMessage{Str = 1224}         --[[ "Keep looking for that Vampire.
I'm sure that's our problem, and he must be somewhere in or near Tatalia.
" ]]
	end
end
-- "Soul Jars"
evt.global[904] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1404} then         -- "Case of Soul Jars"
		evt.SetMessage{Str = 1226}         --[[ "[Sir Caneghem looks at the jars curiously, as though observing a poisonous snake behind glass] So these are soul jars.
I expected something more…impressive, I suppose.
Good job!
[he takes the case of jars] I will make sure these jars are never seen again." ]]
		evt.Subtract{"Inventory", Value = 1404}         -- "Case of Soul Jars"
		evt.Subtract{"QBits", Value = 743}         -- Lich Jar Case - I lost it
		evt.Add{"History11", Value = 0}
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Subtract{"QBits", Value = 620}         -- "Retrieve the Case of Soul Jars from Castle Gloaming in the Pit and return to Sir Caneghem in Celeste."
		evt.Add{"QBits", Value = 629}         -- Finished Wizard Task 4 - Soul Jars
		evt.SetNPCTopic{NPC = 421, Index = 0, Event = 0}         -- "Sir Caneghem"
		evt.SetNPCGreeting{NPC = 421, Greeting = 233}         --[[ "Sir Caneghem" : "Ah, welcome back my lords.
I hope all is well." ]]
		evt.Add{"Awards", Value = 24}         -- "Retrieved Soul Jars"
		evt.ForPlayer(4)
		evt.Subtract{"Reputation", Value = 5}
		evt.SetNPCGreeting{NPC = 427, Greeting = 251}         --[[ "Archibald Ironfist" : "Back for more target practice?
You know, if you wait long enough, my people will regenerate.
Bigger challenge then." ]]
		evt.MoveNPC{NPC = 427, HouseId = 0}         -- "Archibald Ironfist"
		evt.SetNPCTopic{NPC = 427, Index = 1, Event = 0}         -- "Archibald Ironfist"
	else
		evt.SetMessage{Str = 1227}         --[[ "Be well prepared when you go for the jars.
Their security won't be so lax if you have to retreat and return.
" ]]
	end
end
-- "Tolberti"
evt.global[906] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1477} then         -- "Control Cube"
		evt.SetMessage{Str = 1229}         --[[ "[Robert takes the cube] Once again, you succeed!
The Goal is so close!
I know you have many questions, and I'm sure Resurectra will answer them all, after you do just one more mission for her.
You will find her with Gavin Magnus in the throne room of Castle Lambent." ]]
		evt.Subtract{"Inventory", Value = 1477}         -- "Control Cube"
		evt.Add{"History22", Value = 0}
		evt.Add{"Experience", Value = calculateExp(250000)}
		evt.Subtract{"QBits", Value = 621}         -- "Assassinate Tolberti in his house in the Pit and return his control cube to Robert the Wise in Celeste."
		evt.Add{"QBits", Value = 631}         -- Killed Evil MM3 Person
		evt.Add{"Awards", Value = 25}         -- "Assassinated Tolberti"
		evt.SetNPCTopic{NPC = 419, Index = 3, Event = 973}         -- "Resurectra" : "Ancient Weapon Grandmaster"
		evt.SetNPCTopic{NPC = 420, Index = 1, Event = 972}         -- "Crag Hack" : "Ancient Weapon Master"
		evt.SetNPCTopic{NPC = 421, Index = 1, Event = 971}         -- "Sir Caneghem" : "Ancient Weapon Expert"
		evt.SetNPCGreeting{NPC = 422, Greeting = 0}         -- "Robert the Wise" : ""
		evt.Subtract{"Reputation", Value = 5}
		evt.MoveNPC{NPC = 419, HouseId = 220}         -- "Resurectra" -> "Throne Room"
		evt.SetNPCTopic{NPC = 422, Index = 0, Event = 950}         -- "Robert the Wise" : "Blaster"
	else
		evt.SetMessage{Str = 1230}         --[[ "Keep trying to find his apartment.
Tolberti has never really believed anything bad could happen to him, and so far he's been right.
We need to prove him wrong.
Take the cube any way you can.
If you can do it without violence, fine.
If you must kill him, well, that's O.K. too.
Just get the cube." ]]
	end
end
-- "Temple of the Light"
evt.global[908] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1478} then         -- "Altar Piece"
		if evt.Cmp{"Inventory", Value = 1479} then         -- "Altar Piece"
			evt.SetMessage{Str = 1235}         --[[ "Excellent!
[Kastore takes the two halves of the key and bangs them together.
With a bright white flash, they join together seamlessly]
The first part of the Plan is complete.
I knew we, uh, Archibald made the right decision in trusting you!
" ]]
			evt.Subtract{"Inventory", Value = 1478}         -- "Altar Piece"
			evt.Subtract{"Inventory", Value = 1479}         -- "Altar Piece"
			evt.Subtract{"QBits", Value = 744}         -- Altar Piece (Good) - I lost it
			evt.Subtract{"QBits", Value = 745}         -- Altar Piece (Evil) - I lost it
			evt.Add{"History20", Value = 0}
			evt.Add{"Experience", Value = calculateExp(50000)}
			evt.SetNPCTopic{NPC = 423, Index = 0, Event = 0}         -- "Kastore"
			evt.Subtract{"QBits", Value = 634}         -- "Retrieve the altar piece from the Temple of Light in Celeste and the Temple of Dark in the Pit and return them to Kastore in the Pit."
			evt.Set{"QBits", Value = 623}         -- Finished Necro Task 2 - Temple of Light
			evt.Set{"Awards", Value = 19}         -- "Retrieved Both Temple Pieces"
			evt.SetNPCGreeting{NPC = 423, Greeting = 227}         -- "Kastore" : "Always a pleasure to see you, Lords."
		else
			evt.SetMessage{Str = 1233}         --[[ "Well, I'm glad you found our half of the key, but you still need their half.
Hold onto it until you get the other half.
When you have both halves, get back over here and I'll fix them." ]]
		end
	elseif evt.Cmp{"Inventory", Value = 1479} then         -- "Altar Piece"
		evt.SetMessage{Str = 1234}         --[[ "Finally!
I was beginning to wonder if you might have got yourselves killed already.
Well, no matter.
You forgot to get the key from the Temple of the Dark, so be on your way.
When you have it, return to me so I can make the two halves whole again." ]]
	else
		evt.SetMessage{Str = 1232}         --[[ "No key halves yet?
Bah!
I hope you're more competent than you seem right now!
How hard can this be?
All you have to do is burst in the front door and start shooting.
When there's no one left, you can clean their place out at your leisure.
Just hurry up and bring us both key halves." ]]
	end
end
-- "Strike the Devils"
evt.global[910] = function()
	if evt.Cmp{"QBits", Value = 617} then         -- Slayed Xenofex
		evt.ShowMovie{DoubleSize = 1, Name = "\"mm3 people evil\""}
		evt.SetMessage{Str = 1237}         --[[ "THAT WAS AWESOME!
You did it!
And now the single greatest threat to our plans is gone!
We will be Kings of the World!
[Kastore throws his head back and laughs wildly] AHAHAHAHAHA!!!!! Ah ha ha. Yes.
Well, good job.
I'll even forgive you for letting that King Roland character go free--we could have used him as a bargaining chip, you know.
[he shrugs] you probably didn't have a choice, I suppose.
In any event, this is a happy day!
" ]]
		evt.Add{"Gold", Value = calculateGold(50000)}
		evt.Subtract{"Reputation", Value = 10}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(500000)}
		evt.Subtract{"QBits", Value = 635}         -- "Go to Colony Zod in the Land of the Giants and slay Xenofex then return to Kastore in the Pit."
		evt.Set{"QBits", Value = 632}         -- Got Hive part
		evt.SetNPCTopic{NPC = 423, Index = 1, Event = 921}         -- "Kastore" : "Final Task"
		evt.Add{"Awards", Value = 21}         -- "Slayed Xenofex"
	else
		evt.SetMessage{Str = 1238}         --[[ "Could you please hurry up with this raid against the Devils?
Archibald has promised forces, but they won't be available forever.
What's worse, the devils breed faster than rabbits.
The longer you wait, the more you'll have to fight." ]]
	end
end
-- "Soul Jars"
evt.global[912] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1404} then         -- "Case of Soul Jars"
		evt.SetMessage{Str = 1240}         --[[ "[Maximus takes the case of jars with obvious delight] Nice work.
I won't even ask what you had to do to get them.
Success speaks for itself.
" ]]
		evt.Subtract{"Inventory", Value = 1404}         -- "Case of Soul Jars"
		evt.Subtract{"QBits", Value = 743}         -- Lich Jar Case - I lost it
		evt.Add{"History18", Value = 0}
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Subtract{"QBits", Value = 636}         -- "Retrieve the Case of Soul Jars from the Warlocks in Thunderfist Mountain and bring them to Maximus in the Pit."
		evt.Add{"QBits", Value = 624}         -- Finished Necro Task 3 - Soul Jars
		evt.Add{"Awards", Value = 24}         -- "Retrieved Soul Jars"
		evt.SetNPCTopic{NPC = 424, Index = 0, Event = 0}         -- "Maximus"
		evt.SetNPCGreeting{NPC = 424, Greeting = 242}         -- "Maximus" : "Glad to have you back, allies."
		evt.ForPlayer(4)
		evt.Subtract{"Reputation", Value = 5}
	else
		evt.SetMessage{Str = 1241}         --[[ "You don't have to be nice about getting the jars from them--just get the jars any way you can.
We can renegotiate peace with them if we must, just like we renegotiate the price for each purchase of soul jars." ]]
	end
end
-- "Clanker's Laboratory"
evt.global[914] = function()
	if evt.Cmp{"QBits", Value = 638} then         -- Destroyed the magical defenses in Clanker's Lab
		evt.SetMessage{Str = 1243}         --[[ "It's good to see we can count on you.
So few of our allies are as reliable and capable as yourselves.
Thank you very much for your aid." ]]
		evt.Add{"History21", Value = 0}
		evt.Subtract{"Reputation", Value = 5}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Subtract{"QBits", Value = 637}         -- "Destroy the magical defenses inside Clanker's Laboratory and return to Dark Shade in the Pit."
		evt.Add{"QBits", Value = 625}         -- Finished Necro Task 4 - Clanker's Lab
		evt.SetNPCTopic{NPC = 425, Index = 0, Event = 0}         -- "Dark Shade"
		evt.SetNPCGreeting{NPC = 425, Greeting = 245}         --[[ "Dark Shade" : "Welcome, allies.
Always good to have you back." ]]
		evt.Add{"Awards", Value = 26}         -- "Cleaned out Clanker's Laboratory"
	else
		evt.SetMessage{Str = 1244}         --[[ "This is a simple task--get a move on!
Once again, the laboratory on an island east of Pierpont in the Tularean Forest.
Get the shield lowered, and your part of the job is done." ]]
	end
end
-- "Robert the Wise"
evt.global[916] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1477} then         -- "Control Cube"
		evt.SetMessage{Str = 1246}         --[[ "[Tolberti takes the cube] This brings us very close to completing our Plan.
I know Kastore hasn't told you exactly what the Plan is, but you'll like it, I'm sure!
I am not allowed to say much, but I can tell you your position will be much higher than simply Lords of Harmondale, you can count on that!
You will find Kastore in his place on the throne of Castle Gloaming." ]]
		evt.Subtract{"Inventory", Value = 1477}         -- "Control Cube"
		evt.Add{"History23", Value = 0}
		evt.Add{"Experience", Value = calculateExp(250000)}
		evt.Subtract{"QBits", Value = 639}         -- "Assassinate Robert the Wise in his house in Celeste and return to Tolberti in the Pit."
		evt.Add{"QBits", Value = 630}         -- Killed Good MM3 Person
		evt.Add{"Awards", Value = 27}         -- "Assassinated Robert the Wise"
		evt.SetNPCTopic{NPC = 423, Index = 3, Event = 973}         -- "Kastore" : "Ancient Weapon Grandmaster"
		evt.SetNPCTopic{NPC = 424, Index = 1, Event = 972}         -- "Maximus" : "Ancient Weapon Master"
		evt.SetNPCTopic{NPC = 425, Index = 1, Event = 971}         -- "Dark Shade" : "Ancient Weapon Expert"
		evt.SetNPCGreeting{NPC = 426, Greeting = 0}         -- "Tolberti" : ""
		evt.Subtract{"Reputation", Value = 5}
		evt.SetNPCTopic{NPC = 426, Index = 0, Event = 950}         -- "Tolberti" : "Blaster"
	else
		evt.SetMessage{Str = 1247}         --[[ "What's wrong?
Don't tell me you're losing your nerve?
He's tough, but not immortal.
You can take him!
I wouldn't have sent you on this mission if I didn't think you could handle it." ]]
	end
end
-- "Breeding Pit"
evt.global[918] = function()
	if evt.Cmp{"QBits", Value = 641} then         -- Completed Breeding Pit.
		evt.SetMessage{Str = 1249}         --[[ "You show promise, my friends.
A fine performance.
I think it will be sufficient proof of your skill for my advisors.
They are quite eager to assign tasks to you now; they can be found in the four houses in the western side of the Pit.
And don't worry.
Rewards will follow, of course." ]]
		evt.Add{"History17", Value = 0}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Add{"Awards", Value = 28}         -- "Completed Necromancer Breeding Pit"
		evt.Subtract{"QBits", Value = 640}         -- "Complete the Breeding Zone and return to Archibald in the Pit."
		evt.Add{"QBits", Value = 622}         -- Finished Necro Proving Grounds
		evt.SetNPCTopic{NPC = 427, Index = 0, Event = 0}         -- "Archibald Ironfist"
		evt.SetNPCGreeting{NPC = 427, Greeting = 252}         --[[ "Archibald Ironfist" : "Welcome back, allies.
My advisors are eager to speak with you." ]]
		evt.MoveNPC{NPC = 423, HouseId = 1079}         -- "Kastore" -> "Hostel"
		evt.MoveNPC{NPC = 424, HouseId = 1071}         -- "Maximus" -> "Hostel"
		evt.MoveNPC{NPC = 425, HouseId = 1078}         -- "Dark Shade" -> "Hostel"
		evt.MoveNPC{NPC = 426, HouseId = 1070}         -- "Tolberti" -> "Hostel"
		evt.SetNPCGreeting{NPC = 423, Greeting = 238}         --[[ "Kastore" : "[Kastore smiles] Welcome back, allies.
I trust you are well?" ]]
		evt.SetNPCGreeting{NPC = 424, Greeting = 241}         -- "Maximus" : "Glad to have you back, allies."
		evt.SetNPCGreeting{NPC = 425, Greeting = 244}         --[[ "Dark Shade" : "Welcome, allies.
Always good to have you back." ]]
		evt.SetNPCGreeting{NPC = 426, Greeting = 247}         --[[ "Tolberti" : "Glad you're still on our side!
Come and see me when you're done with my associates' missions." ]]
		evt.Add{"QBits", Value = 1606}         -- Joined the Dark Guild
	else
		evt.SetMessage{Str = 1250}         --[[ "I am beginning to suspect my allies were right about you.
Can't you pass this simple test?
Are you too afraid, or too feeble to succeed?
Perhaps we need new allies?" ]]
	end
end
-- "Quest"
evt.global[930] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1450} then         -- "Lantern of Light"
		evt.SetMessage{Str = 1392}         --[[ "Thank you, Lords of Harmondale.
The Lantern's return will bolster our faith and allows us to continue our services.
Please take this small reward as a token of our gratitude." ]]
		evt.Subtract{"Inventory", Value = 1450}         -- "Lantern of Light"
		evt.Add{"Awards", Value = 30}         -- "Returned Withern's Lantern"
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(1000)}
		evt.Subtract{"QBits", Value = 667}         -- "Retrieve the Lantern of Light from the Barrow Downs and return it to Tarin Withern in Harmondale."
		evt.SetNPCTopic{NPC = 432, Index = 0, Event = 0}         -- "Tarin Withern"
		evt.SetNPCGreeting{NPC = 432, Greeting = 267}         --[[ "Tarin Withern" : "Thanks for returning the Lantern of Light.
Ceremonies can continue normally at the temple!" ]]
		evt.Subtract{"Reputation", Value = 5}
	else
		evt.SetMessage{Str = 1391}         --[[ "Have you found the Lantern of Light?
We're certain it was lost in the maze of Barrows in the Barrow Downs." ]]
	end
end
-- "Quest"
evt.global[932] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1430} then         -- "Haldar's Remains"
		evt.SetMessage{Str = 1395}         --[[ "Thank you for returning my ""brother's"" remains!
He was a promising Warlock and his life was ended to soon.
Now that I have his remains, I will attempt to bring him back as a Lich, and together we will seek greater power and glory!" ]]
		evt.Subtract{"Inventory", Value = 1430}         -- "Haldar's Remains"
		evt.Add{"Awards", Value = 32}         -- "Returned Haldar's Remains"
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(35000)}
		evt.Subtract{"QBits", Value = 668}         -- "Retrieve Haldar's Remains from the Maze in Nighon and return them to Mazim Dusk in Nighon."
		evt.SetNPCTopic{NPC = 433, Index = 0, Event = 0}         -- "Mazim Dusk"
		evt.SetNPCGreeting{NPC = 433, Greeting = 269}         -- "Mazim Dusk" : "My thanks for returning Haldar's remains!"
		evt.Subtract{"Reputation", Value = 5}
	else
		evt.SetMessage{Str = 1394}         --[[ "Did you find Haldar's Remains?
His soul must be in sheer agony!
Please find the jar with his remains!" ]]
	end
end
-- "Quest"
evt.global[934] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1408} then         -- "Signet Ring"
		evt.SetMessage{Str = 1398}         --[[ "My ring!
Thank you lords.
I can now continue my business and recover my losses, and you have made the trading routes safer for all the merchants!" ]]
		evt.Subtract{"Inventory", Value = 1408}         -- "Signet Ring"
		evt.Add{"Awards", Value = 34}         -- "Returned Lord Davrik's signet Ring"
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(5000)}
		evt.Subtract{"QBits", Value = 669}         -- "Retrieve Davrik's Signet ring from the Bandit Caves in the northeast of Erathia and return it to Davrik Peladium in Harmondale."
		evt.SetNPCTopic{NPC = 434, Index = 0, Event = 0}         -- "Davrik Peladium"
		evt.MoveNPC{NPC = 434, HouseId = 0}         -- "Davrik Peladium"
		evt.Subtract{"Reputation", Value = 5}
	else
		evt.SetMessage{Str = 1397}         --[[ "You don't have my ring yet?
The bandits are south of Castle Gryphonheart in Erathia.
Please help me, I don't have anyone else to turn to." ]]
	end
end
-- "Thrush's Letter"
evt.global[936] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1405} then         -- "Parson's Quill"
		evt.SetMessage{Str = 1401}         --[[ "The actual Peacock feather that was used to sign the Treaty of Pierpont.
My collection is complete!
I will be sure to record your activities and deeds correctly and justly so that all will know you as the true Lords of Harmondale!" ]]
		evt.Subtract{"Inventory", Value = 1405}         -- "Parson's Quill"
		evt.Add{"Awards", Value = 38}         -- "Returned Parson's Quill to Norbert Thrush"
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(2000)}
		evt.Subtract{"QBits", Value = 671}         -- "Return Parson's Quill to Norbert Thrush in Erathia."
		evt.SetNPCTopic{NPC = 435, Index = 0, Event = 0}         -- "Norbert Thrush"
		evt.SetNPCGreeting{NPC = 435, Greeting = 273}         --[[ "Norbert Thrush" : "Thank you for returning the Parson's Quill sent by Lord Markham.
You help has made my collection complete!" ]]
		evt.Subtract{"Reputation", Value = 5}
	else
		evt.SetMessage{Str = 1400}         --[[ "Did Lord Markham refuse to give you the Quill, or have you not even visited him yet?
His Manor is in Tatalia, please don't forget to help me." ]]
	end
end
-- "Pipes"
evt.global[939] = function()
	evt.ForPlayer("All")
	evt.SetMessage{Str = 1003}         --[[ "So, Johann be wanting the Faerie Pipes, eh?
I can't say I'm surprised--he wouldn't come here himself, the coward.
The Pipes will cost you, though… all your food.
Of course, I've got some delightful food down below, should thee be wanting to restock your packs." ]]
	evt.Subtract{"Inventory", Value = 1409}         -- "Letter from Johann Kerrid to the Faerie King"
	evt.Add{"Experience", Value = calculateExp(2000)}
	evt.ForPlayer(4)
	evt.Add{"Inventory", Value = 1435}         -- "Faerie Pipes"
	evt.SetNPCTopic{NPC = 391, Index = 1, Event = 0}         -- "Faerie King"
	evt.Subtract{"QBits", Value = 691}         -- "Take the sealed letter to the Faerie King in the Hall under the Hill in Avlee."
	evt.Add{"QBits", Value = 692}         -- "Take the Faerie Pipes to Johann Kerrid in the Tularean Forest."
	evt.Set{"Food", Value = 0}
end
-- "Quest"
evt.global[940] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1435} then         -- "Faerie Pipes"
		evt.SetMessage{Str = 1404}         --[[ "Excellent!
The Pipes!
You don't know what this means to me.
Here, take this as a reward and thank you again for your help in this!" ]]
		evt.Subtract{"Inventory", Value = 1435}         -- "Faerie Pipes"
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.ForPlayer(4)
		evt.Add{"Awards", Value = 39}         -- "Returned Faerie Pipes to Johann Kerrid"
		evt.Add{"Gold", Value = calculateGold(1000)}
		evt.Subtract{"QBits", Value = 692}         -- "Take the Faerie Pipes to Johann Kerrid in the Tularean Forest."
		evt.SetNPCTopic{NPC = 436, Index = 0, Event = 0}         -- "Johann Kerrid"
		evt.SetNPCGreeting{NPC = 436, Greeting = 275}         --[[ "Johann Kerrid" : "Thank you so much for returning the Faerie Pipes to me!
I would have never been able to brave the Hall under the Hill myself." ]]
		evt.Subtract{"Reputation", Value = 5}
	else
		evt.SetMessage{Str = 1405}         --[[ "Don't forget to give the letter to the Faerie King.
Without it, he probably won't even want to talk to you." ]]
	end
end
-- "Quest"
evt.global[945] = function()
	if not evt.CheckMonstersKilled{CheckType = 2, Id = 411, Count = 0, InvisibleAsDead = 0} then
		evt.SetMessage{Str = 1411}         --[[ "There are still troglodytes roaming the lower mine levels.
Please remove them!" ]]
	elseif not evt.CheckMonstersKilled{CheckType = 2, Id = 412, Count = 0, InvisibleAsDead = 0} then
		evt.SetMessage{Str = 1411}         --[[ "There are still troglodytes roaming the lower mine levels.
Please remove them!" ]]
	elseif evt.CheckMonstersKilled{CheckType = 2, Id = 413, Count = 0, InvisibleAsDead = 0} then
		evt.SetMessage{Str = 1412}         --[[ "They're gone?
Routed back into the connecting tunnels to Nighon!
Excellent!
We can get back to mining immediately!
Thank you so much for your help; take this as a reward for your services." ]]
		evt.Add{"Gold", Value = calculateGold(2500)}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.Subtract{"QBits", Value = 698}         -- "Kill all the Troglodytes underneath Stone City and return to Spark Burnkindle in Stone City."
		evt.Set{"Awards", Value = 40}         -- "Troglodyte Slayer"
		evt.SetNPCTopic{NPC = 439, Index = 0, Event = 0}         -- "Spark Burnkindle"
		evt.Subtract{"Reputation", Value = 10}
		evt.SetNPCGreeting{NPC = 439, Greeting = 279}         -- "Spark Burnkindle" : "Thank you for helping us by getting rid of those nasty Troglodytes!"
	else
		evt.SetMessage{Str = 1411}         --[[ "There are still troglodytes roaming the lower mine levels.
Please remove them!" ]]
	end
end
-- "Quest"
evt.global[947] = function()
	if evt.Cmp{"QBits", Value = 700} then         -- Killed all Erathian Griffins
		if not evt.Cmp{"QBits", Value = 701} then         -- Killed all Bracada Desert Griffins
			evt.SetMessage{Str = 1416}         --[[ "You've killed the griffins near Steadwick, but you haven't dealt with the griffins in the Bracada Desert yet.
Finish them both off and return to me." ]]
			return
		end
	else
		if not evt.Cmp{"QBits", Value = 701} then         -- Killed all Bracada Desert Griffins
			evt.SetMessage{Str = 1414}         --[[ "You haven't killed off all the griffins in either Erathia or the Bracada Desert.
It is imperative that you finish this task to prevent their invasion." ]]
			return
		end
		if not evt.Cmp{"QBits", Value = 700} then         -- Killed all Erathian Griffins
			evt.SetMessage{Str = 1415}         --[[ "You've killed the griffins near Spyre Town, but you haven't dealt with the griffins in Erathia yet.
Finish them both off and return to me." ]]
			return
		end
	end
	evt.SetMessage{Str = 1417}         --[[ "Excellent!
You've done a splendid job.
Here, take this as your reward and know you've earned the respect of Deyja for your bold success." ]]
	evt.Subtract{"QBits", Value = 699}         -- "Kill all the Griffins in Erathia and the Bracada Desert and return to Seth Drakkson in the Deyja Moors."
	evt.Add{"Gold", Value = calculateGold(5000)}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(10000)}
	evt.Subtract{"Reputation", Value = 10}
	evt.Add{"Awards", Value = 51}         -- "Griffin Slayer"
	evt.SetNPCTopic{NPC = 623, Index = 0, Event = 0}         -- "Seth Drakkson"
	evt.SetNPCGreeting{NPC = 623, Greeting = 281}         --[[ "Seth Drakkson" : "Good work on those griffins, my lords.
It is always a pleasure to see you." ]]
end
-- "Quest"
evt.global[949] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1453} then         -- "Arcomage Deck"
		evt.SetMessage{Str = 1357}         --[[ "Dead?
Oh dear!
Those are certainly his cards, though.
I don't want the cards; you can have them-- that game has cost me enough now.
Oh, poor Elron!
I have a little money you can keep for your help, and thank you for finding out what happened to Elron." ]]
		evt.Add{"Experience", Value = calculateExp(2000)}
		evt.ForPlayer(4)
		evt.Subtract{"QBits", Value = 706}         -- "Find the fate of Darron's brother in the White Cliff Caves, then return to Darron Temper in Harmondale."
		evt.Add{"Gold", Value = calculateGold(750)}
		evt.SetNPCTopic{NPC = 624, Index = 0, Event = 0}         -- "Darron Temper"
		evt.Subtract{"Reputation", Value = 5}
	else
		evt.SetMessage{Str = 1356}         --[[ "Still no sign of him?
I understand.
If you do happen to find out what happened to him, please let me know." ]]
	end
end
-- "Quest"
evt.global[1064] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1440} then         -- "Season's Stole"
		evt.SetMessage{Str = 1360}         --[[ "Excellent!
This most certainly is the Seasons' Stole.
Here is your reward; you've done both the School of Sorcery and myself a great service." ]]
		evt.Subtract{"Inventory", Value = 1440}         -- "Season's Stole"
		evt.Add{"Experience", Value = calculateExp(7500)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(7500)}
		evt.Subtract{"QBits", Value = 707}         -- "Retrieve the Seasons' Stole from the Hall of the Pit and return it to Gary Zimm in the Bracada Desert."
		evt.Add{"Awards", Value = 52}         -- "Retrieved the Seasons' Stole"
		evt.Subtract{"Reputation", Value = 5}
		evt.SetNPCTopic{NPC = 625, Index = 0, Event = 0}         -- "Gary Zimm"
	else
		evt.SetMessage{Str = 1359}         -- "Don't forget there is a reward for the Seasons' Stole if you are able to find it and return it to me."
	end
end
-- "Quest"
evt.global[1213] = function()
	if evt.Cmp{"QBits", Value = 713} then         -- Placed item 617 in out14(statue)
		if evt.Cmp{"QBits", Value = 714} then         -- Place item 618 in out13(statue)
			if evt.Cmp{"QBits", Value = 715} then         -- Place item 619 in out06(statue)
				evt.SetMessage{Str = 1563}         --[[ "Great work!
The Druids are so pleased, they threw in a little extra for your fine performance.
Take this… you most certainly deserve it." ]]
				evt.Add{"Gold", Value = calculateGold(50000)}
				evt.Subtract{"Reputation", Value = 10}
				evt.ForPlayer("All")
				evt.Subtract{"QBits", Value = 712}         -- "Retrieve the three statuettes and place them on the shrines in the Bracada Desert, Tatalia, and Avlee, then return to Thom Lumbra in the Tularean Forest."
				evt.Add{"Experience", Value = calculateExp(50000)}
				evt.Add{"Awards", Value = 53}         -- "Found and placed all the statuettes"
				evt.SetNPCGreeting{NPC = 627, Greeting = 289}         -- "Thom Lumbra" : "Excellent work; my associates are quite pleased."
				evt.SetNPCTopic{NPC = 627, Index = 0, Event = 0}         -- "Thom Lumbra"
				return
			end
		end
	end
	evt.SetMessage{Str = 1562}         --[[ "All three statuettes are not placed.
I cannot reward partial success.
Return when you have placed all three." ]]
end
-- "Quest"
evt.global[1215] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 1423} then         -- "Angel Statue Painting"
		if evt.Cmp{"Inventory", Value = 1424} then         -- "Archibald Ironfist Painting"
			if evt.Cmp{"Inventory", Value = 1425} then         -- "Roland Ironfist Painting"
				evt.SetMessage{Str = 1567}         --[[ "Wonderful!
This set has eluded me for years!
You more than deserve the reward I promised; here, hopefully this will be sufficient." ]]
				evt.Subtract{"Inventory", Value = 1423}         -- "Angel Statue Painting"
				evt.Subtract{"Inventory", Value = 1424}         -- "Archibald Ironfist Painting"
				evt.Subtract{"Inventory", Value = 1425}         -- "Roland Ironfist Painting"
				evt.ForPlayer(4)
				evt.Add{"Gold", Value = calculateGold(50000)}
				evt.Subtract{"Reputation", Value = 10}
				evt.ForPlayer("All")
				evt.Subtract{"QBits", Value = 716}         -- "Retrieve the three paintings and return them to Ferdinand Visconti in Tatalia."
				evt.Add{"Experience", Value = calculateExp(50000)}
				evt.Add{"Awards", Value = 55}         -- "Retrieved the complete set of paintings"
				evt.SetNPCGreeting{NPC = 628, Greeting = 291}         --[[ "Ferdinand Visconti" : "Thank you for your assistance in completing my collection.
You have my gratitude forever!" ]]
				evt.SetNPCTopic{NPC = 628, Index = 0, Event = 0}         -- "Ferdinand Visconti"
				return
			end
		end
	end
	evt.SetMessage{Str = 1566}         --[[ "Remember, I need the complete set of paintings-- they aren't worth much by themselves.
When you have the rest, bring them all to me." ]]
end
-- "Quest"
evt.global[1217] = function()
	if evt.Cmp{"QBits", Value = 750} then         -- Won all Arcomage games
		evt.SetMessage{Str = 1570}         --[[ "Congratulations!
You have become the ArcoMage Champion!
The prize is waiting in the chest right outside my house." ]]
		evt.Subtract{"QBits", Value = 717}         -- "Win a game of Arcomage in all thirteen taverns, then return to Gina Barnes in Erathia."
		evt.Add{"Gold", Value = calculateGold(100000)}
		evt.Subtract{"Reputation", Value = 10}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Add{"QBits", Value = 756}         -- Finished ArcoMage Quest - Get the treasure
		evt.Add{-- ERROR: Not found
"Awards", Value = 1632}
		evt.SetNPCGreeting{NPC = 629, Greeting = 293}         -- "Gina Barnes" : "Welcome ArcoMage Champions!"
		evt.SetNPCTopic{NPC = 629, Index = 0, Event = 0}         -- "Gina Barnes"
	else
		evt.SetMessage{Str = 1569}         --[[ "You must claim a victory at ALL 13 taverns.
Until you do, you cannot be declared ArcoMage Champion." ]]
	end
end
-- "Goblinwatch"
evt.global[1317] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2163} then         -- "Goblinwatch Code"
		evt.SetMessage{Str = 1698}         --[[ "Ah, thank you for taking care of that little detail for us.
Here's your gold!
Feel free to return to Goblinwatch any time to finish clearing out the rest of the monsters.
We can't pay you, but you can have anything you find there.
" ]]
		evt.Set{"Awards", Value = 95}         -- "Solved the Goblinwatch Combination"
		evt.Add{"Experience", Value = calculateExp(2000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(2000)}
		evt.Add{"ReputationIs", Value = 2}
		evt.Subtract{"QBits", Value = 1107}         -- "Find the Combination to the vault door in Goblinwatch and return to the Town Hall in New Sorpigal."
		evt.SetNPCTopic{NPC = 1076, Index = 0, Event = 1318}         -- "Janice" : "Evil Cults"
		evt.MoveNPC{NPC = 1081, HouseId = 0}         -- "Urok"
		evt.MoveNPC{NPC = 828, HouseId = 1463}         -- "Samson Tess" -> "House"
	else
		evt.SetMessage{Str = 1697}         --[[ "How can you find the combination to that lock by standing around here?
Get going!" ]]
	end
end
-- "Evil Cults"
evt.global[1319] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2095} then         -- "Chime of Harmony"
		evt.SetMessage{Str = 1701}         --[[ "Good work!
Here's your gold!
I can't thank you enough for ruining that temple.
Now the road to Ironfist will be safe for travel again." ]]
		evt.Subtract{"Inventory", Value = 2095}         -- "Chime of Harmony"
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.Add{"Awards", Value = 96}         -- "Returned with the Chime of Harmony"
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(5000)}
		evt.Add{"ReputationIs", Value = 2}
		evt.Subtract{"QBits", Value = 1108}         -- "Get the Chime of Harmony from the Temple of Baa and return to the New Sorpigal Town Hall."
		evt.SetNPCTopic{NPC = 1076, Index = 0, Event = 1320}         -- "Janice" : "Evil Cults"
	else
		evt.SetMessage{Str = 1700}         --[[ "Without the Chime of Harmony, I'm not authorized to pay the reward money.
" ]]
	end
end
-- "The Letter"
evt.global[1322] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2125} then         -- "The Letter"
		evt.SetMessage{Str = 1704}         --[[ "Thank you so much for bringing me these letters! <Wilbur begins reading the letters> I’ve been so worried…I see… This is not good news…Oh, no.
Traitors!
Traitors and conspirators everywhere!
I must organize an expedition at once! <Wilbur lowers his voice> I trust you will not speak to the prince about these letters– he is already too depressed and unhappy to hear more bad news.
And now I must see to the organization of the expedition.
Here is a bag of gold as a reward– you’ve earned it and my gratitude.
Now, if only I could find someone to finish looking for Lord Kilburn…" ]]
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(5000)}
		evt.ForPlayer("All")
		evt.Set{"Awards", Value = 100}         -- "Delivered 6th Letter to Wilbur Humphry"
		evt.Subtract{"Inventory", Value = 2125}         -- "The Letter"
		evt.Subtract{"QBits", Value = 1205}         -- Quest item bits for seer
		evt.Subtract{"QBits", Value = 1106}         -- "Bring Sulman's letter to Regent Wilbur Humphrey at Castle Ironfist."
		evt.Subtract{"QBits", Value = 1105}         -- "Show Sulman's letter to Andover Potbello in New Sorpigal."
		evt.Add{"Experience", Value = calculateExp(3000)}
		evt.SetNPCTopic{NPC = 789, Index = 0, Event = 1323}         -- "Wilbur Humphrey" : "Lord Kilburn"
	else
		evt.SetMessage{Str = 1891}         --[[ "Welcome, adventurers!
Did you have something for me?
I'm a very busy man, you know.
" ]]
	end
end
-- "Lord Kilburn"
evt.global[1324] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 2119} then         -- "Lord Kilburn's Shield"
		evt.SetMessage{Str = 1706}         --[[ "Hmm.
No luck finding the shield yet, eh?
Well, do keep looking, will you?
It really is important that someone accounts for his whereabouts." ]]
	else
		evt.SetMessage{Str = 1708}         --[[ "Ah.
‘Tis a sad day when so noble a Knight should fall to such foul monsters!
You have done a good thing, bringing his shield to me.
I shall ensure that he and his men receive all the honors due them.
I am in your debt, and you have my favor with the council.
Here is your reward." ]]
		evt.Subtract{"Inventory", Value = 2119}         -- "Lord Kilburn's Shield"
		evt.Subtract{"QBits", Value = 1206}         -- Quest item bits for seer
		evt.Add{"Experience", Value = calculateExp(40000)}
		evt.Add{"Awards", Value = 57}         -- "Retrieved Lord Kilburn's Shield"
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(5000)}
		evt.Add{"ReputationIs", Value = 10}
		evt.SetNPCTopic{NPC = 789, Index = 0, Event = 1325}         -- "Wilbur Humphrey" : "The High Council"
		evt.Subtract{"QBits", Value = 1110}         -- "Find Lord Kilburn's Shield and return to Wilbur Humphrey in Castle Ironfist to report."
		evt.ForPlayer("All")
		if evt.Cmp{"Awards", Value = 63} then         -- "Exposed the Traitor on the High Council"
			if evt.Cmp{"Awards", Value = 57} then         -- "Retrieved Lord Kilburn's Shield"
				if evt.Cmp{"Awards", Value = 58} then         -- "Retrieved the Hourglass of Time"
					if evt.Cmp{"Awards", Value = 59} then         -- "Destroyed the Devil's Post"
						if evt.Cmp{"Awards", Value = 60} then         -- "Captured the Prince of Thieves"
							if evt.Cmp{"Awards", Value = 61} then         -- "Fixed the Stable Prices"
								if evt.Cmp{"Awards", Value = 62} then         -- "Ended Winter"
									evt.Set{"QBits", Value = 1191}         -- NPC
								end
							end
						end
					end
				end
			end
		end
	end
end
-- "Crusaders"
evt.global[1327] = function()
	if not evt.Cmp{"QBits", Value = 1699} then         -- Replacement for NPCs ¹11 ver. 6
		evt.SetMessage{Str = 1712}         --[[ "I know there is a shortage of damsels in distress, but this quest is the traditional test.
I really can’t bend the rules here.
Keep looking– I’m sure you’ll find someone.
If it helps, I hear Melody Silver, daughter of the noble John Silver, is being held captive by ruffians on the Island of Mist." ]]
		return
	end
	evt.SetMessage{Str = 1713}         --[[ "I have heard stories of the daring rescue, and I am delighted that you have returned with Miss Silver.
I shall arrange to have her returned to her family at once.
Exemplary work!
I hereby officially promote all paladins to the status of crusader, and all non-paladins to honorary crusaders!" ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Paladin} then
		evt.Set{"ClassIs", Value = const.Class.Crusader}
		evt.Add{"QBits", Value = 1635}         -- Received Promotion to Crusader
	else
		evt.Add{"QBits", Value = 1636}         -- Received Promotion to Honorary Crusader
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Paladin} then
		evt.Set{"ClassIs", Value = const.Class.Crusader}
		evt.Add{"QBits", Value = 1635}         -- Received Promotion to Crusader
	else
		evt.Add{"QBits", Value = 1636}         -- Received Promotion to Honorary Crusader
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Paladin} then
		evt.Set{"ClassIs", Value = const.Class.Crusader}
		evt.Add{"QBits", Value = 1635}         -- Received Promotion to Crusader
	else
		evt.Add{"QBits", Value = 1636}         -- Received Promotion to Honorary Crusader
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Paladin} then
		evt.Set{"ClassIs", Value = const.Class.Crusader}
		evt.Add{"QBits", Value = 1635}         -- Received Promotion to Crusader
	else
		evt.Add{"QBits", Value = 1636}         -- Received Promotion to Honorary Crusader
	end
	evt.Add{"Gold", Value = calculateGold(5000)}
	evt.Subtract{"QBits", Value = 1699}         -- Replacement for NPCs ¹11 ver. 6
	evt.Subtract{"QBits", Value = 1112}         -- "Rescue a Damsel in Distress and return with her to Wilbur Humphrey in Castle Ironfist."
	evt.Add{"ReputationIs", Value = 2}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(15000)}
	evt.SetNPCTopic{NPC = 789, Index = 1, Event = 1328}         -- "Wilbur Humphrey" : "Heroes"
end
-- "Heroes"
evt.global[1329] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 2075} then         -- "Dragon Claw"
		evt.SetMessage{Str = 1715}         --[[ "There is no use returning to me to talk about your quest.
I cannot change the rules or your quest.
Longfang awaits your avenging sword.
Now get to it!" ]]
		return
	end
	evt.SetMessage{Str = 1716}         --[[ "Well done!
One less horrible monster in the world is a good thing.
I hereby officially promote all crusaders to heroes, and all honorary crusaders to the status of honorary hero! May you long continue to live up to the title!" ]]
	evt.Add{"Experience", Value = calculateExp(30000)}
	evt.Subtract{"Inventory", Value = 2075}         -- "Dragon Claw"
	evt.Subtract{"QBits", Value = 1209}         -- Quest item bits for seer
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Hero}
		evt.Add{"QBits", Value = 1637}         -- Received Promotion to Hero
	else
		evt.Add{"QBits", Value = 1638}         -- Received Promotion to Honorary Hero
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Hero}
		evt.Add{"QBits", Value = 1637}         -- Received Promotion to Hero
	else
		evt.Add{"QBits", Value = 1638}         -- Received Promotion to Honorary Hero
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Hero}
		evt.Add{"QBits", Value = 1637}         -- Received Promotion to Hero
	else
		evt.Add{"QBits", Value = 1638}         -- Received Promotion to Honorary Hero
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Crusader} then
		evt.Set{"ClassIs", Value = const.Class.Hero}
		evt.Add{"QBits", Value = 1637}         -- Received Promotion to Hero
	else
		evt.Add{"QBits", Value = 1638}         -- Received Promotion to Honorary Hero
	end
	evt.Add{"ReputationIs", Value = 5}
	evt.Subtract{"QBits", Value = 1113}         -- "Slay Longfang Witherhide in his cave near Castle Darkmoor and return to Wilbur Humphrey in Castle Ironfist."
	evt.SetNPCTopic{NPC = 789, Index = 1, Event = 1330}         -- "Wilbur Humphrey" : "Heroes"
end
-- "Release Archibald"
evt.global[1343] = function()
	if not evt.Cmp{"QBits", Value = 1201} then         -- NPC
		evt.SetMessage{Str = 1731}         --[[ "Now wait just a minute Tanir, and I’ll make it worth your while to let me…Oh. <Archibald is silent for a long while> I guess I have you people to thank for releasing me from my prison of stone.
Thank you!
You say you need a spell that I've created?
<reaching to the shelves and removing a library scroll> Well, as a reward, I’ll give you the Ritual of the Void.
Use it in good health.
Now, I’m sure you’re very busy, as am I…<Archibald waves his arms and fades away>" ]]
		evt.Add{"Inventory", Value = 2164}         -- "Ritual of the Void"
		evt.Subtract{"QBits", Value = 1221}         -- Quest item bits for seer
		evt.Add{"QBits", Value = 1201}         -- NPC
		evt.Subtract{"QBits", Value = 1121}         -- Walt
		evt.Subtract{"QBits", Value = 1259}         -- "Obtain Arcane Magic from Archibald in the Royal Library in Castle Ironfist"
		evt.Add{"QBits", Value = 1222}         -- Quest item bits for seer
		evt.ForPlayer("All")
		evt.Subtract{"ReputationIs", Value = 50}
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.MoveNPC{NPC = 797, HouseId = 0}         -- "Archibald Ironfist"
	end
end
-- "The Prince of Thieves"
evt.global[1346] = function()
	if not evt.Cmp{"QBits", Value = 1701} then         -- Replacement for NPCs ¹17 ver. 6
		evt.SetMessage{Str = 1735}         --[[ "I have no information on his whereabouts, so it will do you no good to talk to me about it.
Try going to Free Haven and asking around.
He must have a hideout somewhere in or near that town.
<Smiling> if you find where he’s living, be sure to check under the bed and in the closet– you’ll probably find him hiding under a pile of clothes." ]]
	else
		evt.Subtract{"QBits", Value = 1122}         -- "Capture the Prince of Thieves and bring him to Lord Anthony Stone at Castle Stone."
		evt.SetMessage{Str = 1736}         --[[ "Ah!
My friends, you have returned with the package!
Well done!
Here is your reward money.
You have my full support at the council. <looking at the Prince> Welcome to my humble home, mighty Prince.
I have a room prepared just for you.
Guards!
Take him away." ]]
		evt.SetNPCTopic{NPC = 801, Index = 0, Event = 1347}         -- "Anthony Stone" : "The High Council"
		evt.Add{"Gold", Value = calculateGold(10000)}
		evt.Add{"ReputationIs", Value = 10}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(30000)}
		evt.Add{"Awards", Value = 60}         -- "Captured the Prince of Thieves"
		evt.Subtract{"QBits", Value = 1701}         -- Replacement for NPCs ¹17 ver. 6
		evt.SetNPCTopic{NPC = 802, Index = 0, Event = 1347}         -- "The Prince of Thieves" : "The High Council"
		evt.ForPlayer("All")
		if evt.Cmp{"Awards", Value = 63} then         -- "Exposed the Traitor on the High Council"
			if evt.Cmp{"Awards", Value = 57} then         -- "Retrieved Lord Kilburn's Shield"
				if evt.Cmp{"Awards", Value = 58} then         -- "Retrieved the Hourglass of Time"
					if evt.Cmp{"Awards", Value = 59} then         -- "Destroyed the Devil's Post"
						if evt.Cmp{"Awards", Value = 60} then         -- "Captured the Prince of Thieves"
							if evt.Cmp{"Awards", Value = 61} then         -- "Fixed the Stable Prices"
								if evt.Cmp{"Awards", Value = 62} then         -- "Ended Winter"
									evt.Set{"QBits", Value = 1191}         -- NPC
								end
							end
						end
					end
				end
			end
		end
	end
end
-- "Priests"
evt.global[1349] = function()
	if not evt.Cmp{"QBits", Value = 1130} then         -- NPC
		evt.SetMessage{Str = 1739}         --[[ "The temple I asked you to rebuild still stands in ruins.
The people are deprived of their rightful religious solace, and you return to me empty-handed.
Leave here and complete your mission!
" ]]
		return
	end
	evt.SetMessage{Str = 1740}         --[[ "Excellent work!
The temple has been rebuilt and the affront to the gods eased.
For this service, I am happy to promote all clerics to priests, and I grant honorary priest status to all non-clerics.
Congratulations! " ]]
	evt.Subtract{"QBits", Value = 1129}         -- "Hire a Stonecutter and a Carpenter, bring them to Temple Stone in Free Haven to repair the Temple, and then return to Lord Anthony Stone at Castle Stone."
	evt.SetNPCTopic{NPC = 801, Index = 1, Event = 1350}         -- "Anthony Stone" : "High Priests"
	evt.Add{"ReputationIs", Value = 2}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(15000)}
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.Priest}
		evt.Add{"QBits", Value = 1647}         -- Received Promotion to Priest
	else
		evt.Add{"QBits", Value = 1648}         -- Received Promotion to Honorary Priest
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.Priest}
		evt.Add{"QBits", Value = 1647}         -- Received Promotion to Priest
	else
		evt.Add{"QBits", Value = 1648}         -- Received Promotion to Honorary Priest
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.Priest}
		evt.Add{"QBits", Value = 1647}         -- Received Promotion to Priest
	else
		evt.Add{"QBits", Value = 1648}         -- Received Promotion to Honorary Priest
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Cleric} then
		evt.Set{"ClassIs", Value = const.Class.Priest}
		evt.Add{"QBits", Value = 1647}         -- Received Promotion to Priest
	else
		evt.Add{"QBits", Value = 1648}         -- Received Promotion to Honorary Priest
	end
end
-- "High Priests"
evt.global[1351] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"QBits", Value = 1132} then         -- NPC
		if evt.Cmp{"Inventory", Value = 2054} then         -- "Sacred Chalice"
			evt.SetMessage{Str = 1743}         --[[ "I see that you have recovered the chalice!
Good work, but you still need to ensconce it in the temple.
Take it there at once and return to me for your promotion!" ]]
		else
			evt.SetMessage{Str = 1742}         --[[ "The monks still have the chalice, and our temple is still without it.
Why do you delay?" ]]
		end
		return
	end
	evt.SetMessage{Str = 1744}         --[[ "You are successful!
It looks like I will have to keep my promise and make more irregular, early promotions.
I do so with pleasure.
I hereby promote all priests to high priests, and all honorary priests to honorary high priests." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"QBits", Value = 1649}         -- Received Promotion to High Priest
	else
		evt.Add{"QBits", Value = 1650}         -- Received Promotion to Honorary High Priest
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"QBits", Value = 1649}         -- Received Promotion to High Priest
	else
		evt.Add{"QBits", Value = 1650}         -- Received Promotion to Honorary High Priest
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"QBits", Value = 1649}         -- Received Promotion to High Priest
	else
		evt.Add{"QBits", Value = 1650}         -- Received Promotion to Honorary High Priest
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Priest} then
		evt.Set{"ClassIs", Value = const.Class.PriestLight}
		evt.Add{"QBits", Value = 1649}         -- Received Promotion to High Priest
	else
		evt.Add{"QBits", Value = 1650}         -- Received Promotion to Honorary High Priest
	end
	evt.Add{"ReputationIs", Value = 5}
	evt.Subtract{"QBits", Value = 1131}         -- "Take the Sacred Chalice from the monks in their island temple east of Free Haven, return it to Temple Stone in Free Haven, and then return to Lord Stone at Castle Stone."
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(30000)}
	evt.SetNPCTopic{NPC = 801, Index = 1, Event = 1352}         -- "Anthony Stone" : "High Priests"
end
-- "Council Quest"
evt.global[1365] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2053} then         -- "Hourglass of Time"
		evt.SetMessage{Str = 1756}         --[[ "Now all I have to do is remember how to create the mirror.
I wrote down all the important parts so I wouldn’t forget how to do it.
<stops> Where did I put those notes?
<ponders for a minute> I must have left them somewhere obvious, maybe in the laboratory.
Anyway, your part in this is done, and again I thank you.
You will have my complete support in the council for this.
What were your names again? " ]]
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.Add{"Awards", Value = 58}         -- "Retrieved the Hourglass of Time"
		evt.Subtract{"Inventory", Value = 2053}         -- "Hourglass of Time"
		evt.Subtract{"QBits", Value = 1207}         -- Quest item bits for seer
		evt.ForPlayer(4)
		evt.Add{"ReputationIs", Value = 10}
		evt.Subtract{"QBits", Value = 1134}         -- "Find and return the Hourglass of Time to Lord Albert Newton in Mist."
		evt.SetNPCTopic{NPC = 790, Index = 0, Event = 1367}         -- "Albert Newton" : "Council Quest"
		evt.ForPlayer("All")
		if evt.Cmp{"Awards", Value = 63} then         -- "Exposed the Traitor on the High Council"
			if evt.Cmp{"Awards", Value = 57} then         -- "Retrieved Lord Kilburn's Shield"
				if evt.Cmp{"Awards", Value = 58} then         -- "Retrieved the Hourglass of Time"
					if evt.Cmp{"Awards", Value = 59} then         -- "Destroyed the Devil's Post"
						if evt.Cmp{"Awards", Value = 60} then         -- "Captured the Prince of Thieves"
							if evt.Cmp{"Awards", Value = 61} then         -- "Fixed the Stable Prices"
								if evt.Cmp{"Awards", Value = 62} then         -- "Ended Winter"
									evt.Set{"QBits", Value = 1191}         -- NPC
								end
							end
						end
					end
				end
			end
		end
	elseif evt.Cmp{"Inventory", Value = 2107} then         -- "Key to Gharik's Laboratory"
		evt.SetMessage{Str = 1757}         --[[ "The hourglass wasn’t there?
Oh, that’s right!
I knew I forgot something!
The key is in there!
You use the key to open the Forge of… <pauses>
Well, I can’t remember whose forge it is, but that is the resting place of the Hourglass of Time...I think.
It can’t hurt to look there, especially now that you’ve found the key.
<pauses>
At least I THINK that’s what the key opens.
Anyway, that forge or laboratory or whatever it is can be found on the islands north of New Sorpigal.
Good Luck!" ]]
	else
		evt.SetMessage{Str = 1755}         --[[ "I’m still looking for the mirror. <pauses> I mean Hourglass… I keep getting those mixed up.
Did you try the dark cavern– no wait, it was the old fort south of here.
I always seem to mix those up." ]]
	end
end
-- "Wizards"
evt.global[1371] = function()
	evt.SetMessage{Str = 1762}         --[[ "You have done well in finding the Fountain.
It’s location and powers are a secret, do not spread its location around.
Now, let me show you the secrets of the wizard." ]]
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(15000)}
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Sorcerer} then
		evt.Set{"ClassIs", Value = const.Class.Wizard}
		evt.Add{"QBits", Value = 1639}         -- Received Promotion to Wizard
	else
		evt.Add{"QBits", Value = 1640}         -- Received Promotion to Honorary Wizard
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Sorcerer} then
		evt.Set{"ClassIs", Value = const.Class.Wizard}
		evt.Add{"QBits", Value = 1639}         -- Received Promotion to Wizard
	else
		evt.Add{"QBits", Value = 1640}         -- Received Promotion to Honorary Wizard
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Sorcerer} then
		evt.Set{"ClassIs", Value = const.Class.Wizard}
		evt.Add{"QBits", Value = 1639}         -- Received Promotion to Wizard
	else
		evt.Add{"QBits", Value = 1640}         -- Received Promotion to Honorary Wizard
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Sorcerer} then
		evt.Set{"ClassIs", Value = const.Class.Wizard}
		evt.Add{"QBits", Value = 1639}         -- Received Promotion to Wizard
	else
		evt.Add{"QBits", Value = 1640}         -- Received Promotion to Honorary Wizard
	end
	evt.Add{"ReputationIs", Value = 2}
	evt.Subtract{"QBits", Value = 1135}         -- "Drink from the Fountain of Magic and return to Lord Albert Newton in Mist."
	evt.SetNPCTopic{NPC = 790, Index = 1, Event = 1372}         -- "Albert Newton" : "Master Wizards"
end
-- "Master Wizards"
evt.global[1373] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 2077} then         -- "Crystal of Terrax"
		evt.SetMessage{Str = 1764}         --[[ "I’m sorry, but I still haven’t remembered exactly what it is you need.
I know you need to search Corlagon’s Estate.
 " ]]
		return
	end
	evt.SetMessage{Str = 1765}         --[[ "Great news!
I remember what you need to find!
The Crystal of Terrax!
Oh, you seem to have found it already.
Well, perfect!
I can train you to master wizards, then.
The first arch mage, Terrax, used this Crystal to master the elements.
Fire, earth, water, and air all formed together to make it, and from analyzing it he learned a great deal about elemental magic.
In addition, its effect on light led him to his discoveries of light and dark magic.
Since that time, the study of this crystal has guided every new master wizard.
Let me show you the secrets of the crystal. " ]]
	evt.Add{"Experience", Value = calculateExp(30000)}
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
		evt.Set{"ClassIs", Value = const.Class.ArchMage}
		evt.Add{"QBits", Value = 1641}         -- Received Promotion to Archmage
	else
		evt.Add{"QBits", Value = 1642}         -- Received Promotion to Honorary Archmage
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
		evt.Set{"ClassIs", Value = const.Class.ArchMage}
		evt.Add{"QBits", Value = 1641}         -- Received Promotion to Archmage
	else
		evt.Add{"QBits", Value = 1642}         -- Received Promotion to Honorary Archmage
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
		evt.Set{"ClassIs", Value = const.Class.ArchMage}
		evt.Add{"QBits", Value = 1641}         -- Received Promotion to Archmage
	else
		evt.Add{"QBits", Value = 1642}         -- Received Promotion to Honorary Archmage
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Wizard} then
		evt.Set{"ClassIs", Value = const.Class.ArchMage}
		evt.Add{"QBits", Value = 1641}         -- Received Promotion to Archmage
	else
		evt.Add{"QBits", Value = 1642}         -- Received Promotion to Honorary Archmage
	end
	evt.Add{"ReputationIs", Value = 5}
	evt.Subtract{"QBits", Value = 1136}         -- "Retrieve the Crystal of Terrax and return to Lord Albert Newton in Mist."
	evt.ForPlayer("All")
	evt.Subtract{"Inventory", Value = 2077}         -- "Crystal of Terrax"
	evt.Subtract{"QBits", Value = 1210}         -- Quest item bits for seer
	evt.SetNPCTopic{NPC = 790, Index = 1, Event = 1353}         -- "Albert Newton" : "Arch Mages"
end
-- "Council Quest"
evt.global[1375] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 2126} then         -- "Devil Plans"
		evt.SetMessage{Str = 1768}         --[[ "Did you fail in your mission?
You didn’t allow the demons to escape, did you?
That post MUST be destroyed for any large attack against them to be successful.
As long as that post exists, your mission still stands. " ]]
	else
		evt.SetMessage{Str = 1769}         --[[ "Good job!
With the information you’ve brought back, we now have the intelligence we need to stage an attack on the devils, and with that post out of the way, we can hit them when they won’t expect it. I give you my full support in the council– hopefully the council will actually DO something for once." ]]
		evt.Add{"Experience", Value = calculateExp(40000)}
		evt.Add{"Awards", Value = 59}         -- "Destroyed the Devil's Post"
		evt.Subtract{"Inventory", Value = 2126}         -- "Devil Plans"
		evt.Subtract{"QBits", Value = 1208}         -- Quest item bits for seer
		evt.ForPlayer(4)
		evt.Subtract{"QBits", Value = 1137}         -- "Destroy the Devil's Outpost and return to Lord Osric Temper at Castle Temper."
		evt.Add{"ReputationIs", Value = 10}
		evt.SetNPCTopic{NPC = 791, Index = 0, Event = 1377}         -- "Osric Temper" : "Council Quest"
		evt.ForPlayer("All")
		if evt.Cmp{"Awards", Value = 63} then         -- "Exposed the Traitor on the High Council"
			if evt.Cmp{"Awards", Value = 57} then         -- "Retrieved Lord Kilburn's Shield"
				if evt.Cmp{"Awards", Value = 58} then         -- "Retrieved the Hourglass of Time"
					if evt.Cmp{"Awards", Value = 59} then         -- "Destroyed the Devil's Post"
						if evt.Cmp{"Awards", Value = 60} then         -- "Captured the Prince of Thieves"
							if evt.Cmp{"Awards", Value = 61} then         -- "Fixed the Stable Prices"
								if evt.Cmp{"Awards", Value = 62} then         -- "Ended Winter"
									evt.Set{"QBits", Value = 1191}         -- NPC
								end
							end
						end
					end
				end
			end
		end
	end
end
-- "Cavaliers"
evt.global[1382] = function()
	evt.SetMessage{Str = 1776}         --[[ "Congratulations!
The nomination may not seem important, but we have a tradition that must be followed for this promotion.
As a cavalier, you need to understand that the traditions and values of the people need to be defended.
I gladly promote you to the rank of cavalier!" ]]
	evt.Subtract{"QBits", Value = 1138}         -- "Get Knight's nomination from Chadwick and return to Lord Osric Temper at Castle Temper."
	evt.Add{"ReputationIs", Value = 2}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(15000)}
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Cavalier}
		evt.Add{"QBits", Value = 1643}         -- Received Promotion to Cavalier
	else
		evt.Add{"QBits", Value = 1644}         -- Received Promotion to Honorary Cavalier
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Cavalier}
		evt.Add{"QBits", Value = 1643}         -- Received Promotion to Cavalier
	else
		evt.Add{"QBits", Value = 1644}         -- Received Promotion to Honorary Cavalier
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Cavalier}
		evt.Add{"QBits", Value = 1643}         -- Received Promotion to Cavalier
	else
		evt.Add{"QBits", Value = 1644}         -- Received Promotion to Honorary Cavalier
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Knight} then
		evt.Set{"ClassIs", Value = const.Class.Cavalier}
		evt.Add{"QBits", Value = 1643}         -- Received Promotion to Cavalier
	else
		evt.Add{"QBits", Value = 1644}         -- Received Promotion to Honorary Cavalier
	end
	evt.SetNPCTopic{NPC = 791, Index = 1, Event = 1383}         -- "Osric Temper" : "Champions"
	evt.SetNPCTopic{NPC = 792, Index = 0, Event = 1380}         -- "Chadwick Blackpoole" : "Cavaliers"
end
-- "Champions"
evt.global[1384] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 2128} then         -- "Discharge Papers"
		evt.SetMessage{Str = 1778}         --[[ "You’re not scared of the Warlord, are you?
His terror needs to be put to an end.
You can’t become champion hiding underneath your bed or standing around looking at the walls– you need to go out and DO it!" ]]
		return
	end
	evt.SetMessage{Str = 1779}         --[[ "Good job!
Excellent!
I wasn’t sure you’d make it back alive.
Kergmond had more potential than I realized, but you’re certainly more than a match for an army of Kergmonds.
You’ve proven yourselves worthy of the rank of champion. You must not be afraid to take up arms to defend what is right.
May your enemies fear your approach and your allies rally behind your courage. And now, I promote you to the rank of champion! " ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"QBits", Value = 1645}         -- Received Promotion to Champion
	else
		evt.Add{"QBits", Value = 1646}         -- Received Promotion to Honorary Champion
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"QBits", Value = 1645}         -- Received Promotion to Champion
	else
		evt.Add{"QBits", Value = 1646}         -- Received Promotion to Honorary Champion
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"QBits", Value = 1645}         -- Received Promotion to Champion
	else
		evt.Add{"QBits", Value = 1646}         -- Received Promotion to Honorary Champion
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Cavalier} then
		evt.Set{"ClassIs", Value = const.Class.Champion}
		evt.Add{"QBits", Value = 1645}         -- Received Promotion to Champion
	else
		evt.Add{"QBits", Value = 1646}         -- Received Promotion to Honorary Champion
	end
	evt.Add{"ReputationIs", Value = 5}
	evt.Subtract{"QBits", Value = 1139}         -- "Defeat the Warlord and bring proof to Osric Temper"
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(40000)}
	evt.Subtract{"Inventory", Value = 2128}         -- "Discharge Papers"
	evt.Subtract{"QBits", Value = 1211}         -- Quest item bits for seer
	evt.SetNPCTopic{NPC = 791, Index = 1, Event = 1385}         -- "Osric Temper" : "Champions"
end
-- "Control Center"
evt.global[1389] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"QBits", Value = 1190} then         -- "Retrieve the Control Cube from the Tomb of Varn in Dragonsand and return to the Oracle beneath the High Council."
		if evt.Cmp{"Inventory", Value = 2076} then         -- "Control Cube"
			evt.Add{"Experience", Value = calculateExp(500000)}
			evt.Add{"Awards", Value = 76}         -- "Gained Access to the Control Center"
			evt.Subtract{"QBits", Value = 1190}         -- "Retrieve the Control Cube from the Tomb of Varn in Dragonsand and return to the Oracle beneath the High Council."
			evt.Subtract{"Inventory", Value = 2076}         -- "Control Cube"
			evt.Subtract{"QBits", Value = 1219}         -- Quest item bits for seer
			evt.SetNPCTopic{NPC = 793, Index = 0, Event = 1390}         -- "Oracle" : "Kreegan"
			evt.SetNPCTopic{NPC = 793, Index = 1, Event = 1391}         -- "Oracle" : "Ancients"
			evt.SetMessage{Str = 1783}         --[[ "You now have access to the Control Center.
Simply ask to be transported and I will oblige.
One warning however– the guardians of the Control Center are no longer under my control, so please exercise caution while visiting the Center." ]]
			return
		end
	else
		evt.Add{"Awards", Value = 75}         -- "Awakened the Oracle"
		evt.Add{"QBits", Value = 1190}         -- "Retrieve the Control Cube from the Tomb of Varn in Dragonsand and return to the Oracle beneath the High Council."
		evt.Subtract{"QBits", Value = 1186}         -- "Find Memory Crystal Alpha in the Supreme Temple of Baa and restore it to a module altar at the Oracle beneath the High Council.."
		evt.Subtract{"QBits", Value = 1187}         -- "Find Memory Crystal Beta in Castle Alamos and restore it to a module altar at the Oracle beneath the High Council."
		evt.Subtract{"QBits", Value = 1188}         -- "Find Memory Crystal Delta in Castle Darkmoor and restore it to a module altar at the Oracle beneath the High Council."
		evt.Subtract{"QBits", Value = 1189}         -- "Find Memory Crystal Epsilon in Castle Kriegspire and restore it to a module altar at the Oracle beneath the High Council."
	end
	evt.SetMessage{Str = 1782}         --[[ "I am Melian, Guardian of Enroth.
Thank you for replacing my memory modules.
Archibald took them from here when I refused to give him any help in his battle for succession.
Your timing is impeccable.
The Kreegan have invaded our world, and you must try and stop them.
Unfortunately, Archibald’s attempts at extracting information from me have damaged me enough that I cannot help you directly now.
Instead, I can only give you advice.While most of the Kreegan can be slain with ordinary weapons and spells, the elite guards and upper echelon breeders have tougher skin and natural defenses that protect them from anything but very powerful weapons.
In the planetary control center beneath me are the weapons and armor you will need to survive battle with the enemy.
My orders, however, will only permit passage to someone with a Control Cube.
My instruments tell me that the only Control Cube left in Enroth can be found somewhere underground in Dragonsand.
" ]]
end
-- "Money"
evt.global[1393] = function()
	if not evt.Cmp{"QBits", Value = 1141} then         -- NPC
		evt.SetMessage{Str = 1787}         --[[ "Not all of the companies have agreed to raise their prices!
Why do you return only to report incompetence?
There are large profits I could be reaping if you had done your job and convinced these idiots to raise their prices!
MUST I DO THIS MYSELF?
Should I send someone else?
Why do I surround myself with MORONS?!
So far I have lost a lot of gold because you haven’t finished your job!
I’ll deduct these losses from your final payment, you can be sure of that!" ]]
		return
	end
	evt.SetMessage{Str = 1788}         --[[ "At last!
Thought you would never finish.
Maybe you’re good for something after all.
You have won my support in the council, and of course, your payment. " ]]
	if evt.Cmp{"QBits", Value = 1707} then         -- Replacement for NeedToTestIt ¹31 ver. 6
		evt.Add{"Gold", Value = calculateGold(5000)}
	else
		evt.Add{"Gold", Value = calculateGold(25000)}
	end
	evt.Subtract{"QBits", Value = 1140}         -- "Fix the prices of all 9 stables in the Kingdom and return to Lady Fleise in Silver Cove."
	evt.Subtract{"ReputationIs", Value = 10}
	evt.ForPlayer("All")
	evt.Add{"Awards", Value = 61}         -- "Fixed the Stable Prices"
	evt.Add{"Experience", Value = calculateExp(25000)}
	evt.SetNPCTopic{NPC = 799, Index = 0, Event = 1394}         -- "Loretta Fleise" : "Money"
	evt.ForPlayer("All")
	if evt.Cmp{"Awards", Value = 63} then         -- "Exposed the Traitor on the High Council"
		if evt.Cmp{"Awards", Value = 57} then         -- "Retrieved Lord Kilburn's Shield"
			if evt.Cmp{"Awards", Value = 58} then         -- "Retrieved the Hourglass of Time"
				if evt.Cmp{"Awards", Value = 59} then         -- "Destroyed the Devil's Post"
					if evt.Cmp{"Awards", Value = 60} then         -- "Captured the Prince of Thieves"
						if evt.Cmp{"Awards", Value = 61} then         -- "Fixed the Stable Prices"
							if evt.Cmp{"Awards", Value = 62} then         -- "Ended Winter"
								evt.Set{"QBits", Value = 1191}         -- NPC
							end
						end
					end
				end
			end
		end
	end
end
-- "Winter"
evt.global[1402] = function()
	evt.SetMessage{Str = 1799}         --[[ "I was looking out my window when the weather broke and the snow vanished!
A miracle!
A genuine miracle!
You have done my people and me a great service.
<Slapping his chest> Count Erik Von Stromgard as your friend forever!
" ]]
	evt.Subtract{"QBits", Value = 1144}         -- "End winter for Lord Stromgard at Castle Stromgard, and return to him with the good news."
	evt.Set{"QBits", Value = 1199}         -- NPC
	evt.Add{"ReputationIs", Value = 10}
	evt.SetNPCTopic{NPC = 800, Index = 0, Event = 1403}         -- "Erik Von Stromgard" : "Winter"
	evt.ForPlayer("All")
	evt.Add{"Awards", Value = 62}         -- "Ended Winter"
	evt.Add{"Experience", Value = calculateExp(50000)}
	evt.ForPlayer("All")
	if evt.Cmp{"Awards", Value = 63} then         -- "Exposed the Traitor on the High Council"
		if evt.Cmp{"Awards", Value = 57} then         -- "Retrieved Lord Kilburn's Shield"
			if evt.Cmp{"Awards", Value = 58} then         -- "Retrieved the Hourglass of Time"
				if evt.Cmp{"Awards", Value = 59} then         -- "Destroyed the Devil's Post"
					if evt.Cmp{"Awards", Value = 60} then         -- "Captured the Prince of Thieves"
						if evt.Cmp{"Awards", Value = 61} then         -- "Fixed the Stable Prices"
							if evt.Cmp{"Awards", Value = 62} then         -- "Ended Winter"
								evt.Set{"QBits", Value = 1191}         -- NPC
							end
						end
					end
				end
			end
		end
	end
end
-- "Warrior Mages"
evt.global[1405] = function()
	evt.ForPlayer("All")
	if not evt.Cmp{"Inventory", Value = 2106} then         -- "Dragon Tower Keys"
		evt.SetMessage{Str = 1802}         --[[ "No key—No reward.
Our deal is simple and straightforward.
Fetch the key from my old keep and return once you have it.
" ]]
		return
	end
	evt.SetMessage{Str = 1803}         --[[ "Very good!
You got the key, and hopefully slew a large number of those loathsome beasts.
I hereby promote all archers to the status of warrior mage, and all non-archers to honorary warrior mage." ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Archer} then
		evt.Set{"ClassIs", Value = const.Class.WarriorMage}
		evt.Add{"QBits", Value = 1655}         -- Received Promotion to Battle Mage
	else
		evt.Add{"QBits", Value = 1656}         -- Received Promotion to Honorary Battle Mage
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Archer} then
		evt.Set{"ClassIs", Value = const.Class.WarriorMage}
		evt.Add{"QBits", Value = 1655}         -- Received Promotion to Battle Mage
	else
		evt.Add{"QBits", Value = 1656}         -- Received Promotion to Honorary Battle Mage
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Archer} then
		evt.Set{"ClassIs", Value = const.Class.WarriorMage}
		evt.Add{"QBits", Value = 1655}         -- Received Promotion to Battle Mage
	else
		evt.Add{"QBits", Value = 1656}         -- Received Promotion to Honorary Battle Mage
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Archer} then
		evt.Set{"ClassIs", Value = const.Class.WarriorMage}
		evt.Add{"QBits", Value = 1655}         -- Received Promotion to Battle Mage
	else
		evt.Add{"QBits", Value = 1656}         -- Received Promotion to Honorary Battle Mage
	end
	evt.Subtract{"QBits", Value = 1145}         -- "Retrieve the key to the Dragon Towers from Icewind Keep south of Whitecap, and bring it to Lord Stromgard at Castle Stromgard."
	evt.Add{"ReputationIs", Value = 2}
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(15000)}
	evt.SetNPCTopic{NPC = 800, Index = 1, Event = 1406}         -- "Erik Von Stromgard" : "Master Archers"
end
-- "Master Archers"
evt.global[1413] = function()
	if evt.Cmp{"QBits", Value = 1180} then         -- NPC
		if evt.Cmp{"QBits", Value = 1181} then         -- NPC
			if evt.Cmp{"QBits", Value = 1182} then         -- NPC
				if evt.Cmp{"QBits", Value = 1183} then         -- NPC
					if not evt.Cmp{"QBits", Value = 1184} then         -- NPC
						goto _11
					end
					if not evt.Cmp{"QBits", Value = 1185} then         -- NPC
						goto _11
					end
					evt.SetMessage{Str = 1807}         --[[ "I knew my faith in you was well placed!
You have fixed a major problem in our kingdom, not to mention doing yourself a favor—It’s now safe to fly above towns.
It is my pleasure to promote all warrior mages to master archers, and all honorary warrior mages to honorary master archers.
" ]]
					evt.Add{"ReputationIs", Value = 5}
					evt.Subtract{"QBits", Value = 1146}         -- "Reset all of the Dragon Towers at each town and return to Lord Stromgard in Castle Stromgard."
					evt.ForPlayer("All")
					evt.Add{"Experience", Value = calculateExp(40000)}
					evt.ForPlayer(0)
					if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
						evt.Set{"ClassIs", Value = const.Class.MasterArcher}
						evt.Add{"QBits", Value = 1657}         -- Received Promotion to Warrior Mage
					else
						evt.Add{"QBits", Value = 1658}         -- Received Promotion to Honorary Warrior Mage
					end
					goto _24
				end
			end
		end
	end
::_11::
	evt.SetMessage{Str = 1805}         --[[ "Hmm.
Not all of the towers have been reset.
They are easy to find, if a bit long in getting to.
The easiest is in Whitecap to the west of us." ]]
	do return end
::_24::
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
		evt.Set{"ClassIs", Value = const.Class.MasterArcher}
		evt.Add{"QBits", Value = 1657}         -- Received Promotion to Warrior Mage
	else
		evt.Add{"QBits", Value = 1658}         -- Received Promotion to Honorary Warrior Mage
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
		evt.Set{"ClassIs", Value = const.Class.MasterArcher}
		evt.Add{"QBits", Value = 1657}         -- Received Promotion to Warrior Mage
	else
		evt.Add{"QBits", Value = 1658}         -- Received Promotion to Honorary Warrior Mage
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.WarriorMage} then
		evt.Set{"ClassIs", Value = const.Class.MasterArcher}
		evt.Add{"QBits", Value = 1657}         -- Received Promotion to Warrior Mage
	else
		evt.Add{"QBits", Value = 1658}         -- Received Promotion to Honorary Warrior Mage
	end
	evt.SetNPCTopic{NPC = 800, Index = 1, Event = 1407}         -- "Erik Von Stromgard" : "Master Archers"
end
-- "Quest"
evt.global[1436] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"QBits", Value = 1033} then         --  9, CD2, given when you destroy Lich book
		evt.SetMessage{Str = 2069}         --[[ "Incredible!
I didn't expect you'd be able to do it.
Now that the Book of Liches is gone, the Necromancers' Guild here in Enroth will slowly fade away.
This is all thanks to you!
Here, take this as a reward and accept my gratitude as well." ]]
		evt.Add{"Awards", Value = 102}         -- "Destroyed the Book of Liches"
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(5000)}
		evt.Add{"ReputationIs", Value = 5}
		evt.Subtract{"QBits", Value = 1228}         -- "Find and destroy the Book of Liches in Castle Darkmoor and return to Terry Ros in Darkmoor village."
		evt.SetNPCTopic{NPC = 1115, Index = 0, Event = 0}         -- "Terry Ros"
		evt.MoveNPC{NPC = 1115, HouseId = 0}         -- "Terry Ros"
	else
		evt.SetMessage{Str = 2068}         --[[ "There's no rush in destroying the book.
If you manage it, come back and talk to me.
I'm not sure it's even possible to get to the book and destroy it– there are far too many evil creatures in that castle." ]]
	end
end
-- "Quest"
evt.global[1604] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2118} then         -- "Snergle's Axe"
		evt.SetMessage{Str = 1991}         --[[ "Oh, glorious day!
With Snergle’s passing, we can now search for Rocklin to put him back in power.
Eternal thanks to you for this, and dwarves everywhere owe you a debt of gratitude." ]]
		evt.Add{"Awards", Value = 79}         -- "Killed Snergle"
		evt.Add{"Experience", Value = calculateExp(20000)}
		evt.ForPlayer(4)
		evt.Set{"QBits", Value = 1051}         -- 27 D05, Given when axe is returned (so door can't be opened)
		evt.Subtract{"QBits", Value = 1148}         -- "Kill Snergle in Snergle's Caverns and return with his axe to Avinril Smythers at The Haunt tavern in the Mire of the Damned."
		evt.Add{"ReputationIs", Value = 5}
		evt.SetNPCTopic{NPC = 817, Index = 0, Event = 1520}         -- "Avinril Smythers " : "Master Axe Fighting"
	else
		evt.SetMessage{Str = 1990}         --[[ "I need proof that Snergle has been defeated.
I’m sorry, but I just can’t take your word for it.
Bring back some personal item of his, like his axe maybe." ]]
	end
end
-- "Quest"
evt.global[1606] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2123} then         -- "Enemies List"
		evt.SetMessage{Str = 1994}         --[[ "Just as I suspected!
I’m surprised the Mayor was number three on their enemies list.
I suppose he IS a tad incompetent, but he’s not a bad person.
Thanks again, please accept this gold and my gratitude as your reward." ]]
		evt.Subtract{"Inventory", Value = 2123}         -- "Enemies List"
		evt.Add{"Awards", Value = 80}         -- "Saved the Mayor of Mist"
		evt.Add{"Experience", Value = calculateExp(15000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(3000)}
		evt.Add{"ReputationIs", Value = 2}
		evt.Subtract{"QBits", Value = 1149}         -- "Storm the Silver Helm Outpost near Mist and return with evidence of their corruption to the Constable of Mist."
		evt.SetNPCTopic{NPC = 822, Index = 0, Event = 0}         -- "Charles D'Sorpigal"
		evt.SetNPCTopic{NPC = 831, Index = 0, Event = 1608}         -- "Bertrand Scrivner" : "Silver Helms"
	else
		evt.SetMessage{Str = 1993}         --[[ "Keep searching– the lives of the mayor and myself could very well be in your hands.
We can’t take action against them without proof." ]]
	end
end
-- "Quest"
evt.global[1610] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2069} then         -- "Candelabra"
		evt.SetMessage{Str = 1999}         --[[ "Excellent!
Baa be praised!
I see you were not frightened of the curse after all.
Here is your reward and thank you again for your assistance." ]]
		evt.Subtract{"Inventory", Value = 2069}         -- "Candelabra"
		evt.Add{"Awards", Value = 81}         -- "Retrieved the Baa Candelabra"
		evt.Add{"Experience", Value = calculateExp(2000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(1000)}
		evt.Subtract{"ReputationIs", Value = 10}
		evt.Subtract{"QBits", Value = 1150}         -- "Retrieve the candelabra from the Abandoned Temple for Andover Potbello in New Sorpigal."
		evt.SetNPCTopic{NPC = 786, Index = 1, Event = 0}         -- "Andover Potbello"
	else
		evt.SetMessage{Str = 1998}         --[[ "Did the curse frighten you away as well?
I can understand.
Baa is patient, however.
Should you work up the courage to find the candelabra, I’m still prepared to compensate you for it." ]]
	end
end
-- "Quest"
evt.global[1617] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2099} then         -- "Harp"
		evt.SetMessage{Str = 2008}         --[[ "My gratitude!
My wife loves this harp; I’m so glad you were able to recover it!
Here, take this as a reward.
I’ve heard rumors that the Dragoons were working with the Shadow Guild.
If that’s the case, I’m sure the Mayor of New Sorpigal would love to see proof of it.
Thank you again for your assistance." ]]
		evt.Subtract{"Inventory", Value = 2099}         -- "Harp"
		evt.Add{"Awards", Value = 82}         -- "Retrieved Andrew's Harp"
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(5000)}
		evt.Add{"ReputationIs", Value = 2}
		evt.Subtract{"QBits", Value = 1152}         -- "Retrieve the harp from the Dragoon's Caverns south of Castle Ironfist and return it to Andrew Besper in Castle Ironfist."
		evt.SetNPCTopic{NPC = 862, Index = 0, Event = 0}         -- "Andrew Besper"
	elseif evt.Cmp{"Inventory", Value = 2098} then         -- "Flute"
		evt.SetMessage{Str = 2009}         --[[ "Well, this IS a musical instrument, but it’s not a harp.
Let me explain the difference:
You brought back a flute.
A flute is a pipe with holes in it.
A harp has strings.
Does that help?
I’m sure they still have the harp and I will reward you well for its return." ]]
	else
		evt.SetMessage{Str = 2007}         --[[ "My harp is still lost, so the reward is still available for it.
I know the Dragoons base their operations to the south of here near the coast.
Please bring back my harp." ]]
	end
end
-- "Quest"
evt.global[1619] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2084} then         -- "Ethric's Skull"
		evt.SetMessage{Str = 2012}         --[[ "Good work! Now I can conclude my research.
If I can learn how the Ritual of Endless Night works, perhaps I can find a way to reverse the process.
Here is the reward I promised you. " ]]
		evt.Subtract{"Inventory", Value = 2084}         -- "Ethric's Skull"
		evt.Add{"Awards", Value = 83}         -- "Retrieved Ethric's Skull"
		evt.Add{"Experience", Value = calculateExp(15000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(7500)}
		evt.Subtract{"QBits", Value = 1153}         -- "Retrieve Ethric's skull from his tomb west of Free Haven for Gabriel Cartman in Free Haven."
		evt.SetNPCTopic{NPC = 956, Index = 0, Event = 0}         -- "Gabriel Cartman"
		evt.MoveNPC{NPC = 956, HouseId = 0}         -- "Gabriel Cartman"
	else
		evt.SetMessage{Str = 2011}         --[[ "I am well aware of the difficulty of the task, believe me.
Take your time but at the least, do the job properly. " ]]
	end
end
-- "Quest"
evt.global[1622] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2101} then         -- "Spider Queen's Heart"
		evt.SetMessage{Str = 2015}         --[[ "What a gruesome trophy!
This heart proves you’ve defeated the wicked spider queen.
Hopefully now the spiders won’t plague New Sorpigal anymore.
Here is the reward I promised." ]]
		evt.Subtract{"Inventory", Value = 2101}         -- "Spider Queen's Heart"
		evt.Add{"Awards", Value = 84}         -- "Killed the Spider Queen"
		evt.Add{"Experience", Value = calculateExp(3000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(1000)}
		evt.Subtract{"QBits", Value = 1154}         -- "Kill the Queen of the Spiders in the Abandoned Temple in New Sorpigal and return with her heart to Buford T. Allman in New Sorpigal."
		evt.SetNPCTopic{NPC = 992, Index = 0, Event = 0}         -- "Buford T. Allman"
	else
		evt.SetMessage{Str = 2014}         -- "No one has returned with proof that they’ve killed the spider queen, so the reward is still available."
	end
end
-- "Quest"
evt.global[1624] = function()
	if evt.Cmp{"QBits", Value = 1047} then         -- 23 D13, Given when Altar is desecrated
		evt.SetMessage{Str = 2018}         --[[ "Thank you for your help!
Please allow me to compensate you for your efforts.
We can rest more safely knowing that Cedric and his renegade druids are no longer polluting that sacred area. " ]]
		evt.Subtract{"QBits", Value = 1155}         -- "Deface the altar in the Monolith west of Silver Cove and return to Eleanor Vanderbilt in Silver Cove."
		evt.Add{"ReputationIs", Value = 2}
		evt.Add{"Gold", Value = calculateGold(3000)}
		evt.ForPlayer("All")
		evt.Add{"Awards", Value = 85}         -- "Saved the Monolith"
		evt.Add{"Experience", Value = calculateExp(15000)}
		evt.SetNPCTopic{NPC = 1052, Index = 0, Event = 0}         -- "Eleanor Vanderbilt"
		evt.MoveNPC{NPC = 1052, HouseId = 0}         -- "Eleanor Vanderbilt"
	else
		evt.SetMessage{Str = 2017}         -- "I’m glad to see you again, but the Celestial Order is still in the Monolith."
	end
end
-- "Quest"
evt.global[1629] = function()
	if evt.Cmp{"QBits", Value = 1045} then         -- 21 T2, Given when evil crystal is destroyed
		evt.SetMessage{Str = 2026}         --[[ "Good work!
I’m glad you made it in time.
I don’t like to think about what Baa would have done with that crystal.
You have done all of Enroth a great service." ]]
		evt.Subtract{"QBits", Value = 1158}         -- "Destroy the crystal in the Temple of the Fist and return to Winston Schezar in Bootleg Bay."
		evt.Add{"Gold", Value = calculateGold(3000)}
		evt.Add{"ReputationIs", Value = 2}
		evt.ForPlayer("All")
		evt.Add{"Awards", Value = 87}         -- "Destroyed the Wicked Crystal"
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.SetNPCTopic{NPC = 1075, Index = 0, Event = 0}         -- "Winston Schezar"
		evt.MoveNPC{NPC = 1075, HouseId = 0}         -- "Winston Schezar"
	else
		evt.SetMessage{Str = 2025}         --[[ "You must hurry and destroy the crystal before Baa claims it.
I’m not sure how long it will take, so time is of the essence." ]]
	end
end
-- "Quest"
evt.global[1631] = function()
	if evt.Cmp{"QBits", Value = 1702} then         -- Replacement for NPCs ¹108 ver. 6
		evt.SetMessage{Str = 2029}         --[[ "Oh, thank you for bringing Emmanuel back to me!
Nothing in this world means as much to me as him!
Please take this as a reward.
I know it’s not much, but you deserve it for bringing him back to me." ]]
		evt.Subtract{"QBits", Value = 1702}         -- Replacement for NPCs ¹108 ver. 6
		evt.Subtract{"QBits", Value = 1160}         -- "Rescue Emmanuel from the Temple of the Snake near Blackshire and return him to Joanne Cravitz in Blackshire."
		evt.Add{"Gold", Value = calculateGold(500)}
		evt.ForPlayer("All")
		evt.Add{"Awards", Value = 88}         -- "Rescued Emmanuel"
		evt.Add{"Experience", Value = calculateExp(20000)}
		evt.MoveNPC{NPC = 893, HouseId = 1354}         -- "Emmanuel Cravitz" -> "House"
		evt.SetNPCTopic{NPC = 893, Index = 0, Event = 0}         -- "Emmanuel Cravitz"
		evt.SetNPCTopic{NPC = 903, Index = 0, Event = 0}         -- "Joanne Cravitz"
	else
		evt.SetMessage{Str = 2028}         --[[ "No luck?
He must be in grave danger if you did not find him.
If you do happen to find him, please bring him back here.
I’ll be waiting for him." ]]
	end
end
-- "Quest"
evt.global[1636] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2020} then         -- "Mordred"
		evt.SetMessage{Str = 2035}         --[[ "So this is the legendary Mordred, eh?
Interesting, I was expecting something much grander.
I don’t think I want it, actually.
Why don’t you keep it, and I’ll deal with my friend on the cost." ]]
		evt.Add{"Awards", Value = 89}         -- "Found Zoltan's Artifact"
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(30000)}
		evt.Add{"ReputationIs", Value = 5}
		evt.Subtract{"QBits", Value = 1161}         -- "Find the lost artifact in the Dragoons' Keep near Castle Temper and return it to Zoltan Phelps in Free Haven."
		evt.SetNPCTopic{NPC = 861, Index = 0, Event = 0}         -- "Zoltan Phelps"
		evt.MoveNPC{NPC = 861, HouseId = 0}         -- "Zoltan Phelps"
	else
		evt.SetMessage{Str = 2034}         --[[ "Hello again.
No one has found Mordred yet, so our deal is still good.
I’ll give you part of the selling price for the artifact if you return it." ]]
	end
end
-- "Quest"
evt.global[1638] = function()
	if evt.Cmp{"QBits", Value = 1703} then         -- Replacement for NPCs ¹193 ver. 6
		evt.SetMessage{Str = 2038}         --[[ "Thank you so much for saving Sharry!
I can’t tell you how much this means to both New Sorpigal and myself.
You have our gratitude forever." ]]
		evt.Subtract{"QBits", Value = 1703}         -- Replacement for NPCs ¹193 ver. 6
		evt.Subtract{"QBits", Value = 1162}         -- "Rescue Sharry from the Shadow Guild Hideout and return with her to Frank Fairchild in New Sorpigal."
		evt.Add{"Gold", Value = calculateGold(2000)}
		evt.ForPlayer("All")
		evt.Add{"Awards", Value = 90}         -- "Rescued Sharry"
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.SetNPCTopic{NPC = 788, Index = 0, Event = 0}         -- "Frank Fairchild"
	else
		evt.SetMessage{Str = 2037}         --[[ "Have you found Sharry yet?
No?
I’m sure she’s wherever the Shadow Guild is hiding out.
Find them and you’ll find her." ]]
	end
end
-- "Shadow Guild"
evt.global[1639] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2124} then         -- "Orders from the Shadow Guild"
		evt.SetMessage{Str = 2039}         --[[ "Interesting.
The Dragoons were hired by the Shadow Guild.
I’m certain Anthony Stone will want to hear about this.
I’ll present this letter when I see him next. Thank you for this.
I’m sure he will want to take action against the Shadow Guild now that we have some proof of their deeds." ]]
		evt.Subtract{"Inventory", Value = 2124}         -- "Orders from the Shadow Guild"
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(5000)}
		evt.Add{"ReputationIs", Value = 2}
		evt.SetNPCTopic{NPC = 788, Index = 1, Event = 0}         -- "Frank Fairchild"
	else
		evt.SetMessage{Str = 2091}         --[[ "I'm so tired of the Shadow Guild, but I don't have any substantial proof of their activities.
I'd love to have something I could show to Anthony Stone proving the Shadow Guild is up to no good down here." ]]
	end
end
-- "Quest"
evt.global[1642] = function()
	if evt.Cmp{"QBits", Value = 1704} then         -- Replacement for NPCs ¹195 ver. 6
		evt.SetMessage{Str = 2043}         --[[ "She’s alive!
Thank you so much for finding Angela!
If I weren’t so happy to see her, she’d be in a lot of trouble.
Please take this as a reward for all you’ve done." ]]
		evt.MoveNPC{NPC = 980, HouseId = 1316}         -- "Angela Dawson" -> "House"
		evt.Subtract{"QBits", Value = 1704}         -- Replacement for NPCs ¹195 ver. 6
		evt.Subtract{"QBits", Value = 1163}         -- "Rescue Angela from the Abandoned Temple and return her to Violet Dawson in New Sorpigal."
		evt.Add{"Gold", Value = calculateGold(500)}
		evt.Add{"Food", Value = 10}
		evt.ForPlayer("All")
		evt.Add{"Awards", Value = 91}         -- "Rescued Angela"
		evt.Add{"Experience", Value = calculateExp(1000)}
		evt.SetNPCTopic{NPC = 939, Index = 0, Event = 0}         -- "Violet Dawson"
		evt.SetNPCTopic{NPC = 980, Index = 0, Event = 0}         -- "Angela Dawson"
	else
		evt.SetMessage{Str = 2042}         --[[ "You didn’t find poor Angela?
Something horrible must have happened to her!" ]]
	end
end
-- "Quest"
evt.global[1645] = function()
	if evt.Cmp{"QBits", Value = 1705} then         -- Replacement for NPCs ¹155 ver. 6
		evt.SetMessage{Str = 2047}         --[[ "Wonderful!
She’s not dead after all!
Thank you for all your trouble.
I hope you will accept this token of my gratitude." ]]
		evt.MoveNPC{NPC = 940, HouseId = 1400}         -- "Sherell Ivanaveh" -> "House"
		evt.Subtract{"QBits", Value = 1705}         -- Replacement for NPCs ¹155 ver. 6
		evt.Subtract{"QBits", Value = 1164}         -- "Rescue Sherell from the cannibals on the islands east of Free Haven and return with her to Carlo Tormini in Free Haven."
		evt.SetNPCTopic{NPC = 940, Index = 0, Event = 0}         -- "Sherell Ivanaveh"
		evt.Add{"Gold", Value = calculateGold(1500)}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.Add{"Awards", Value = 92}         -- "Rescued Sherell"
		evt.SetNPCTopic{NPC = 985, Index = 0, Event = 0}         -- "Carlo Tormini"
	else
		evt.SetMessage{Str = 2046}         --[[ "Oh dear!
You haven’t found her yet?
Surely she must have been sacrificed or eaten or something.
Please try to find her, or at least avenge her death." ]]
	end
end
-- "Quest"
evt.global[1648] = function()
	if evt.Cmp{"QBits", Value = 1041} then         -- 17 D17, given when wolf altar is destroyed.
		evt.SetMessage{Str = 2051}         --[[ "Thank you!
We can now sleep at night without worrying about what kinds of foul acts we will commit as monsters!
It’s a tragedy that our lord was a werewolf himself; he’ll be sorely missed.
Please accept this for your help, and for believing in us." ]]
		evt.Subtract{"QBits", Value = 1165}         -- "Destroy the Werewolf's altar in the Lair of the Wolf and return to Maria Trepan in Blackshire."
		evt.Add{"Gold", Value = calculateGold(4000)}
		evt.Add{"ReputationIs", Value = 5}
		evt.ForPlayer("All")
		evt.Add{"Experience", Value = calculateExp(20000)}
		evt.Add{"Awards", Value = 94}         -- "Killed the Werewolf Leader"
		evt.SetNPCTopic{NPC = 997, Index = 0, Event = 0}         -- "Maria Trepan"
		evt.MoveNPC{NPC = 997, HouseId = 0}         -- "Maria Trepan"
	else
		evt.SetMessage{Str = 2050}         --[[ "Is there no hope for us?
Please promise me you’ll keep searching for a way to reverse the curse and turn us back to normal people." ]]
	end
end
-- "Quest"
evt.global[1654] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2078} then         -- "Pearl of Putrescence"
		evt.SetMessage{Str = 2058}         --[[ "Thank you for defeating the werewolf leader.
I wish that I had been strong enough to stop this from happening.
Please accept my thanks for allowing my spirit to move on.
I will take the pearl away so that it may no longer cause any harm to the people of Enroth." ]]
		evt.Subtract{"Inventory", Value = 2078}         -- "Pearl of Putrescence"
		evt.Add{"Experience", Value = calculateExp(5000)}
		evt.Add{"Awards", Value = 93}         -- "Broke the Blackshire Curse"
		evt.ForPlayer(4)
		evt.Subtract{"QBits", Value = 1167}         -- "Find the Pearl of Putrescence in the Lair of the Wolf and bring it to the Ghost of Balthasar, also in the Lair of the Wolf."
		evt.Add{"QBits", Value = 1059}         -- 35 D17 Brought back Black Pearl and Ghost will no longer show up.
		evt.SetNPCTopic{NPC = 1080, Index = 2, Event = 0}         -- "Ghost of Balthasar"
	else
		evt.SetMessage{Str = 2057}         --[[ "The werewolf leader possesses the Pearl of Putrescence, the opposite of my Pearl of Purity.
With this pearl, he has been able to cause the curse.
I was never able to kill him in my retreat.
I will be able to rest in peace knowing that he has been defeated." ]]
	end
end
-- "Pearl of Purity"
evt.global[1655] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2079} then         -- "Pearl of Purity"
		evt.SetMessage{Str = 2059}         --[[ "What’s this?
You have the Pearl of Purity?
I thought Balthasar– oh, he’s dead is he?
I’ll keep it for now, then, as per his last wishes.
Thank you on behalf of both him and me." ]]
		evt.Subtract{"Inventory", Value = 2079}         -- "Pearl of Purity"
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.ForPlayer(4)
		evt.Subtract{"QBits", Value = 1166}         -- NPC
		evt.SetNPCTopic{NPC = 789, Index = 2, Event = 0}         -- "Wilbur Humphrey"
	else
		evt.SetMessage{Str = 2092}         --[[ "One of the few remaining Paladin artifacts left is the Pearl of Purity.
Balthasar was in possession of the pearl the last I heard.
He was visiting Lord Spindler in Blackshire, but I haven't heard anything from him in months." ]]
	end
end
-- "Quest"
evt.global[1667] = function()
	evt.SetMessage{Str = 2100}         --[[ "Good work!
I have my youth again, thanks to you– have you ever thought about assisting me full-time?
I could certainly use reliable help.
I've managed to collect a variety of trinkets over the years, so please help yourself to a few of these in the chest outside as payment for your services.
I need to clean up a few things here, but I think I'll head back to Castle Ironfist and see if there's an opening for a court magician." ]]
	evt.Subtract{"QBits", Value = 1243}         -- "Place the statuettes in Sweet Water, Kriegspire, Dragonsand, Mire of the Damned, and Bootleg Bay and return to Twillen in Blackshire."
	evt.Add{"QBits", Value = 1245}         -- NPC
	evt.ForPlayer("All")
	evt.Add{"Experience", Value = calculateExp(75000)}
	evt.Add{"Awards", Value = 98}         -- "Placed Twillen's statuettes"
	evt.SetNPCTopic{NPC = 826, Index = 0, Event = 0}         -- "Twillen"
	evt.MoveNPC{NPC = 826, HouseId = 0}         -- "Twillen"
end
-- "Quest"
evt.global[1669] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2100} then         -- "Jeweled Egg"
		evt.SetMessage{Str = 2074}         -- "Thank you for returning this egg to me; it’s the most precious thing I have."
		evt.Subtract{"Inventory", Value = 2100}         -- "Jeweled Egg"
		evt.Add{"Awards", Value = 97}         -- "Retrieved Emil's Egg"
		evt.Add{"Experience", Value = calculateExp(50000)}
		evt.ForPlayer(4)
		evt.Add{"ReputationIs", Value = 5}
		evt.Add{"Gold", Value = calculateGold(5000)}
		evt.Subtract{"QBits", Value = 1168}         -- "Retrieve the jewelled egg from Castle Kriegspire and return it to Emil Lime in Kriegspire village."
		evt.SetNPCTopic{NPC = 986, Index = 0, Event = 0}         -- "Emil Lime"
		evt.MoveNPC{NPC = 986, HouseId = 0}         -- "Emil Lime"
	else
		evt.SetMessage{Str = 2073}         --[[ "Kriegspire is the castle inside the volcano.
We mages were forced to raise the earth around the castle to try and prevent the creatures from overrunning the surrounding towns.
Now they’re contained inside, and that’s where the egg is." ]]
	end
end
-- "Quest"
evt.global[1673] = function()
	if not evt.Cmp{"QBits", Value = 1095} then         -- Walt
		evt.SetMessage{Str = 2078}         --[[ "As patient as I am, I would like to see the channels I use to sustain me opened again.
Please do not fail." ]]
	else
		evt.SetMessage{Str = 2079}         --[[ "Thank you for your assistance.
I am grateful to you for returning my source of sustenance to me.
I need to recharge what little power I have left now that I am able to again." ]]
		if not evt.Cmp{"QBits", Value = 1383} then         -- NPC
			evt.Subtract{"QBits", Value = 1169}         -- "Unward the doors in the Hall of the Fire Lord and return to the Lord of Fire, also in the Hall of the Fire Lord."
			evt.Add{"QBits", Value = 1383}         -- NPC
			evt.ForPlayer("All")
			evt.Add{"Awards", Value = 99}         -- "Aided the Lord of Fire"
			evt.Add{"Experience", Value = calculateExp(10000)}
			evt.SetNPCTopic{NPC = 1083, Index = 2, Event = 0}         -- "Lord of Fire"
		end
	end
end
-- "Ankh"
evt.global[1675] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2068} then         -- "Ankh"
		evt.SetMessage{Str = 2081}         --[[ "So, Sir John was murdered and the Silver Helms were bought off by the Temple of Baa?
That explains a great deal.
Good work on bringing this to me, but you’ll need to collect your reward from Anthony Stone." ]]
		evt.Subtract{"Inventory", Value = 2068}         -- "Ankh"
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.ForPlayer(4)
		evt.SetNPCTopic{NPC = 801, Index = 2, Event = 1677}         -- "Anthony Stone" : "Ankh"
		evt.SetNPCTopic{NPC = 799, Index = 2, Event = 0}         -- "Loretta Fleise"
	else
		evt.SetMessage{Str = 2094}         --[[ "Recently, the Fraternal Order of Silver has been disrupting my business and my caravans.
I'm not sure why Sir John feels it necessary, but I'd like this to stop.
If you could convince him to leave me alone, I'm sure I could give you a portion of the money you would be saving me." ]]
	end
end
-- "Ankh"
evt.global[1676] = function()
	evt.ForPlayer("All")
	if evt.Cmp{"Inventory", Value = 2068} then         -- "Ankh"
		evt.SetMessage{Str = 2082}         --[[ "I should have known Baa was behind this, they seem to be behind everything.
Thank you for bringing this to me.
It answers the questions I had about the Fraternal Order of Silver." ]]
		evt.Subtract{"Inventory", Value = 2068}         -- "Ankh"
		evt.Add{"Experience", Value = calculateExp(10000)}
		evt.ForPlayer(4)
		evt.Add{"Gold", Value = calculateGold(5000)}
		evt.SetNPCTopic{NPC = 801, Index = 2, Event = 0}         -- "Anthony Stone"
		evt.SetNPCTopic{NPC = 799, Index = 2, Event = 0}         -- "Loretta Fleise"
	else
		evt.SetMessage{Str = 2095}         --[[ "The Fraternal Order of Silver has begun more direct attacks on my legitimate, underworld associates.
I would appreciate it greatly if you could talk to Sir John and learn why he feels these actions are necessary." ]]
	end
end
-- "Ceremony of the Sun"
evt.global[1678] = function()
	evt.SetMessage{Str = 1792}         --[[ "<Loretta Fleise contacts you via a telepathy spell> Welcome to the Ceremony of the Sun.
Stand ye in the circle of life and face the north while no shadows stretch before thee.
Meditate upon this truth:
“Money is everything.
I have no truer a friend than money…” <grinning> Just kidding.
Now, close your eyes, and meditate as you stand at the center of the world and time for just this one, sublime moment… <long, silent pause>
Open your eyes.
I hereby promote all druids to great druids and all non-druids to honorary druids. <Loretta fades away> " ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.Druid} then
		evt.Set{"ClassIs", Value = const.Class.GreatDruid}
		evt.Add{"QBits", Value = 1651}         -- Received Promotion to Great Druid
	else
		evt.Add{"QBits", Value = 1652}         -- Received Promotion to Honorary Great Druid
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.Druid} then
		evt.Set{"ClassIs", Value = const.Class.GreatDruid}
		evt.Add{"QBits", Value = 1651}         -- Received Promotion to Great Druid
	else
		evt.Add{"QBits", Value = 1652}         -- Received Promotion to Honorary Great Druid
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.Druid} then
		evt.Set{"ClassIs", Value = const.Class.GreatDruid}
		evt.Add{"QBits", Value = 1651}         -- Received Promotion to Great Druid
	else
		evt.Add{"QBits", Value = 1652}         -- Received Promotion to Honorary Great Druid
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.Druid} then
		evt.Set{"ClassIs", Value = const.Class.GreatDruid}
		evt.Add{"QBits", Value = 1651}         -- Received Promotion to Great Druid
	else
		evt.Add{"QBits", Value = 1652}         -- Received Promotion to Honorary Great Druid
	end
	evt.Add{"ReputationIs", Value = 2}
	evt.ForPlayer("All")
	evt.Subtract{"QBits", Value = 1142}         -- "Visit the Altar of the Sun in the circle of stones north of Silver Cove on an equinox or solstice (HINT:  March 20th is an equinox)."
	evt.Add{"QBits", Value = 1197}         -- NPC
	evt.Add{"Experience", Value = calculateExp(15000)}
	evt.SetNPCTopic{NPC = 1090, Index = 0, Event = 0}         -- "Loretta Fleise"
	evt.SetNPCTopic{NPC = 799, Index = 1, Event = 1397}         -- "Loretta Fleise" : "Arch Druids"
end
-- "Ceremony of the Moon"
evt.global[1679] = function()
	evt.SetMessage{Str = 1794}         --[[ "<Loretta Fleise contacts you via a telepathy spell> Welcome to the Ceremony of the Moon.
Stand ye before the altar of the Moon facing south.
Close your eyes and meditate upon the Circle of Seasons and the Wheel of Life.
<long, silent pause>
Open your eyes, my friends.
I hereby promote all great druids to arch druids, and all honorary great druids to honorary arch druids.
<Loretta fades away> " ]]
	evt.ForPlayer(0)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.ArchDruid}
		evt.Add{"QBits", Value = 1653}         -- Received Promotion to Arch Druid
	else
		evt.Add{"QBits", Value = 1654}         -- Received Promotion to Honorary Arch Druid
	end
	evt.ForPlayer(1)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.ArchDruid}
		evt.Add{"QBits", Value = 1653}         -- Received Promotion to Arch Druid
	else
		evt.Add{"QBits", Value = 1654}         -- Received Promotion to Honorary Arch Druid
	end
	evt.ForPlayer(2)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.ArchDruid}
		evt.Add{"QBits", Value = 1653}         -- Received Promotion to Arch Druid
	else
		evt.Add{"QBits", Value = 1654}         -- Received Promotion to Honorary Arch Druid
	end
	evt.ForPlayer(3)
	if evt.Cmp{"ClassIs", Value = const.Class.GreatDruid} then
		evt.Set{"ClassIs", Value = const.Class.ArchDruid}
		evt.Add{"QBits", Value = 1653}         -- Received Promotion to Arch Druid
	else
		evt.Add{"QBits", Value = 1654}         -- Received Promotion to Honorary Arch Druid
	end
	evt.Add{"ReputationIs", Value = 5}
	evt.ForPlayer("All")
	evt.Subtract{"QBits", Value = 1143}         -- "Visit the Altar of the Moon in the Temple of the Moon at midnight of a full moon."
	evt.Add{"QBits", Value = 1198}         -- NPC
	evt.Add{"Experience", Value = calculateExp(40000)}
	evt.SetNPCTopic{NPC = 1091, Index = 0, Event = 0}         -- "Loretta Fleise"
	evt.SetNPCTopic{NPC = 799, Index = 1, Event = 1399}         -- "Loretta Fleise" : "Arch Druids"
end
