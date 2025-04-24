# Maw-Mod-MMMerge
## Credits and Acknowledgments

This mod is the culmination of efforts from a dedicated team, with each member bringing their unique skills and passion to the project:

- **Malekith** - _Lead Developer and Designer_: Responsible most of the coding effort and the primary force behind the mod's design direction.
- **Rawsugar** - _Co-Lead Designer_: Played a pivotal role in crafting the mod's formulas and design concepts, shaping the gameplay experience.
- **Eksekk** - _Senior Contributor_: Offered significant support by tackling challenging tasks and adding features that enhanced the mod's depth and functionality.
- **Yuji Sakai/Knightmarevive** - _Contributor_: Brought fresh code contributions to the project recently, further enriching the mod's content.
- **2D (Perduelion)** - _Contributor_: Basically designed the new alchemy design all by himself, making an amazing job.
- **Thor Thunderfist** - _Contributor_: Adapted the code for skill limit removal.

Special thanks to Grayface and Rodril, that indirectly made the whole project possible. 

We express our deepest appreciation to all the discord community member. Their advices and feedbacks played a very important role in the development. Most noticeably, but not only:

Viktor, Hagnak, ArkTolei, MR___TJ, Spazzledorf, Torkvato, LiGx, Mercs/Zan Team.


## Install instruction
- download MM8 from GOG
- following 3 files needs to be copied into MM8 folder in that exact order.
  - download MMMerge here: https://1drv.ms/u/s!AklOx6zaOmQgbHB1-Avia15ruaI?e=H4IcBJ 
  - download Patch here: https://gitlab.com/letr.rod/mmmerge/-/archive/Rodril_nightly_build/mmmerge-Rodril_nightly_build.zip
  - download Multiplayer here: https://gitlab.com/letr.rod/mmmerge/-/archive/multiplayer/mmmerge-multiplayer.zip
  - download MAW MMMerge here: https://github.com/Malekitsu/Maw-Mod-MMMerge/archive/refs/heads/main.zip
- put MM8 folder into desktop
- set mm8.exe into Windows Service pack 2 (or 3) compatibility mode.
- check difficulty & bolster settings once in game (ingame esc/controls/extra setting on top)

## Discord Link
If you have any installation issue, bug, question or just want to share your adventures, you can join Discord at the following link:


https://discord.gg/n59XMtMcnF

## Overview
The mod is very big and changes most game mechanics, for simplicity I'll divide in the following sections:
- What you need to know
- Item rework
- Stats rework
- Class rework
- Skill rework
- Races rework
- Spells rework
- Monster rework
- Alchemy rework
- Crafting System
- Bolster & Difficulty rework
- Mechanics rework
- Solo leveling

# What you need to know
The mod has been balanced to be medium difficulty for veteran players. There is an easy mode that can be enabled in "Extra settings". Especially early on it might be a challenge even for veteran players due to the jump in difficulty. Here’s some advice to help you familiarize yourself with the dynamics of the mod.

- Monsters are much stronger, weapons more useful and spells more balanced. Forget what you know about some spell, class or weapon being useless : it has probably been changed.
- Defensive skills are important even early in the game. Bodybuilding has been changed so that it doesn’t fall off late game. Early on it will greatly increase your hitpoints, consider prioritizing it.
- Meditation has been buffed significantly to reduce downtime, and buff casters early. Later on spell costs increase significantly though.
- Because monsters move faster than you and you can't dodge their attacks, pulling monsters is now key to victory, and carelessly alerting too many monsters will get you killed very fast.
- Try to fight monsters that aren’t too much higher level than you, monster and player strength increases exponentially with level.
- Items and stats are much more significant than in vanilla

That’s really all you need to know to get started, just install and enjoy the fun 🙂

But if you’re curious to know more about the mod and the specific changes, read on:

## Item Rework
- Items can now have up to 3 enchants: 2 base enchants and 1 special.
- You will have a chance to find ancient and primordial items:
  - Ancients will have higher stats.
  - Primordials will be similar to ancients but with consistently perfect rolls.
- Items have item level shown
- Enchants that increase your damage output are now stronger and apply to spells as well.
- Special enchantments that increase magic school levels now provide a flat bonus.
- You can now sort current inventory by pressing R, and all party inventory by pressing T
- pressing E will assign the current player all the alchemy items when sorting with T
- Some actions have been taken to prevent save-scumming to get loot
- You can press R when in shops to reroll all the item
- Gold cost depends on the loot power
- Items will now show power and vitality changes with currently equipped item, check the Stats rework section for more info
- Items with enchant that add damage to attack will increase also all spell damage by that amount if equipped in main hand
  - Doesn't apply to strength+fire damage enchant
  - AoE and shotgun spells will gain 40% of that amount

### Weapons
- Weapons have attack speed stat
  - Damage will be multiplied by the attack speed
  - This is not shown in stats menu
  - Elemental enchants and spells are not affected
- Weapons will tend to get slower as you progress, making speed cap very hard to reach

## Stats Rework
- Stats now provide 1 effect every 5 points (e.g., 500 Might will increase melee/ranged damage by 100).
- Might now applies to bows as well.
- Each stat has a unique additional bonus (visible by right-clicking the stat in the menu):
  - Might: Every 10 points increase physical damage by 1%.
  - Int/Pers: Every 10 points increase spell damage by 1% and spell critical damage by 1.5% (only the highest between the two will be applied).
  - Endurance: Every 10 points increase health by 1%.
  - Accuracy: Every 10 points increase melee/bow critical damage by 3%.
  - Speed: Every 10 points increase increases attack speed by 2% and cast speed by 1%.
  - Luck: Every 15 points increase critical strike chance by 0.5% (base crit % is 5%).
  - Luck: Every 5 points will increase all resistances by 1.
  - Armor Class: Reduces physical damage taken.
 
### You can now see POWER and VITALITY stats:
- Power will show the DPS you are capable of
  - If you don't have any offensive quickspell, the highest between melee or ranged damage will be shown
  - Spell will count only for a single hit
    - If fireball is equipped, power is counted only as if 1 monster was hit
    - If shrapnel is equipped, power is counted only as if 1 hit is done
- Vitality show your effective health:
  - It accounts for damage reduction from resistances and Armor Class

### Resistances
- Now are in percentage and no longer rolled randomly;
- Light damage is now reduced by the lowest between your mind and body resistance
- Dark damage is now reduced by the lowest elemental resistance
- Energy damage is now reduced by the lowest resistance
- Reduced amount depends on monster level
  - The amount shown in stats menu is the amount of damage reduction vs same level monster enemies
  - When right-clicking a monster you will already see the reduced damage, press alt to show unreduced damage
- Monster resistances will no longer have immunities, but will still take much less damage
- Damage to monster with resistances is no longer random
- Each 100 resistance means half damage, the actual formula is: damage/2^(res/100)

## Skill Rework
- Most weapon and armor skills have been rebalanced; for complete information, check the in-game tooltips:
  - Weapons are now on par with damage in terms of damage output; they are better compared to single-target ranged spells but weaker than shotgun and AoE spells
  - Armors will now also provide magic resistance
  - Weapons are now balanced between each other
- Id Item, Id Monster, Repair, Merchant and Disarm are now shared to all party members
  - Click on the skill to share to all party
- Regeneration and Meditation will now be much stronger and work continuously instead of every 10 seconds
- You can now reset your skill points at the Seer, Judge Gray, or Oracle.
  - Masteries (Expert/Master/GM) will automatically be grant once you get to the required skill level, if you had previously

## Race Rework
- Minotaurs can dual wield axes and 2h axes, at expert and master.
- Humans have +1 Mastery on utility skills (meaning, for example, that if it was able to learn Expert, can learn Master)
- Troll has +2 Mastery on regeneration skill
- Most races have some baseline resistances
### On top of that races have +3 to the following skill level
- Humans: Armors and Shield
- Dark Elf: Bow and Meditation
- Minotaur: Axe
- Elf/Dark elf: Bow and Meditation
- Goblin: Sword, Mace and Dagger
- Dwarf: Axe and Bodybuilding

## Class Rework
- most underused classes have been balanced to have some uniqueness
- misc skills are now a bit more accessible

### MAW Classes
- Added Seraphim, Death Knight and Shaman Class
- Press the icon top right on party creation to enable them
- Make sure to read their perks by right clicking on the class name upon character creation
- Classes can be promoted crossworld (MM8 only on 2nd promotion)
- Classes with multiple promotions available will get a random promotion.
  - You can just save/reload until you get the desired promotion.

  
  ![image](https://github.com/Malekitsu/Maw-Mod-MMMerge/assets/114432644/003d4409-3fee-41a4-a941-e356aaa6b42b)


## Spells Rework
- Many spells have been rebalanced
- Leveling a 2nd school will now cost half of the skill points, a 3rd one will cost 1/3, and so on
- Body and Spirit school have 1 extra healing spell
- ASCENSION
  - This skill replaces learning
  - Reduce mana cost of spells on by 10-20-30-40% on N-E-M-GM.
  - Increasing the spell will ascend the spells of it's current tier (tier 1 are all cost 1 spells, tier 11 are all the cost 30 spells; different values for dark/light)
  - Ascended spells will cost more and deal more damage
- To keep up with the increasing spell cost, meditation will now restore mana continuously and a much more faster rate
- Control effects, such as fear or paralysis, are much more reliable, depending on the skill itself, but last for less time.

## Monsters
  - Monster hitpoints have been doubled
- Monsters deal double damage early on, and keep pace with increased player hitpoint and defenses, ending up at around 12 times vanilla damage at level 100 and x 250 at level 250, so you will need to balance both the offensive and defensive part of your build.
- Most monster, melee in particular, have increased speed
- Most ranged attacks now have homing, making dodging shots difficult. You can only dodge ranged attacks by running in and out of range or dodging behind an object/wall. Homing missiles can be disabled.
- With monsters automatically hitting and outrunning player, carefully pulling monsters becomes essential to survival.
- Monster resistance capped to 200, removing magic immunity.
- Many annoying skills have been removed or chance heavily reduced (dispel for example)
- You can now change difficulty, getting more loot rewards and more.
  - check the bolster/difficulty section.

## Alchemy
- Reworked the whole alchemy recipes/potions.
  - There a less amount of potions, but each one of them will be useful
  - Buff potions have now 5 charges and last for 6 hours
  - Some potions will have some power requirement to work
  - Pressing alt will show you the recipes
  - Health and mana potions will now heal much more based on power level and will remain relevant throughout the game
- In single player, you have 2 shortcuts that will automatically consume the strongest health/mana (G and V key) potion from inventory (15-second cooldown)
- Alchemy has been balanced vs light magic to provide ca double buffs but it doesnt reduce the cost of other spellschools and lacks the many nonbuffing spells Light has.
- Alchemy buffs do not stack with Light magic
- Access to either Light Magic or Alchemy makes the party much stronger than without it
Down here the full recipe list:
![image](https://github.com/Malekitsu/Maw-Mod-MMMerge/assets/106842972/0e2ec9bb-1850-417a-b8c7-6129ef951ca3)

## Crafting 
- 14 new crafting items have been added
- They are dropped randomly when killing monsters and in shops
- The higher the monster level, the higher is the drop chance
- 10 of them are gems, that increase the lowest between base enchants strength
  - You will find stronger gems as you progress in the game
- Crafting cube, increases base stats (such as weapon damage or AC) and special enchant strength
- Hourglass, adds a normal enchant to an item that has already a normal enchant
- The Eye, adds a special enchant to an item with at least 1 normal enchants
- Mirror, duplicates any equipment (artifacts excluded). Very rare.
In addition to that, there are some crafting you can do with potions

Tips:
- Enchant is predetermined, so save and reload will not change the outcome
- You can check the outcome before using the item by pressing ALT
- If you use any crafting item, such as gems, the outcome will change


## Bolster & Difficulty
- There are 2 game modes, and you can check bolster value by right clicking level in stats menu:
- Free Progression (set monster bolster to on):
  - Recommended if you want to play just 1 of the 3 continents, or one continent at a time. You can also move freely between continents but arent rewarded for doing so.
  - Bolster is no longer applied unless you change continent
  - When you change continents, monsters will retain the levels you gained from other continents
  - Along with monster strength, loot strength will increase, including base stats, value, and enchants
### Example
  - You clear Might and Magic 6 at level 100.
  - Going to MM7 will increase all monster levels by 100, requiring you to start from the beginning without skipping.
  - You finish MM7 at level 180 and then proceed to MM8.
  - Monster levels are now increased by 180.
  - Going back to MM6 will increase monster levels by 80 (180-100=80).

- Horizontal Progression (set monster bolster to off):
  - Recommended if you plan to clear the full game
  - There is no monster bolster
  - Monsters will scale naturally up to level 250+
  - You will need to change continent often to be able to progress
  - Level requirement on item will prevent abusing late game loot too early on, but shouldn't never be an issue in a normal playthrough
  - Most skills skills masteries will require 6-12-20 to learn E-M-GM
  - There are teleporters conveniently placed in starting cities (New Sorpigal, Harmondale, Ravenshore)

- Difficulty:
  - You can choose between Easy-Normal-MAW-Hard-Hell-Nightmare
    - Damage and monster HP will be multiplied corrispondently by 0.6-0.8 - 1 - 1.5 - 2 - 3
    - Loot power will be increased by 0% - 0% - 2.5% - 5% - 10%
    - Chance to get enchants, Ancients and Primordials increases aswell from Hard on
    - Monster density will increase aswell
    - Once in Nightmare you can't change difficulty
      - You can't save nor teleport with monsters in the nearbies
      - Dungeons will now spawn elite monsters, with unique abilities
      - Exiting a dungeon before killing a set amount of monsters will make monsters resurrect (a message will be shown)
      - Killing most enemies will give you some exp-gold and crafting item



## Mechanics Rework
- Dual-wielding weapons will now allow the player to benefit fully from both weapons.
- Recovery is now multiplicative; a 50 bonus recovery will increase attack speed by 50%.
- Player projectiles will now home in on the target.
- Monster projectiles will now tend to home players:
  - Moving sideways is not enough to dodge, but running is enough
  - Flying up and down doesn't work

## Solo
The game is designed to make solo play viable.
It will be much harder at first, but you can concentrate all of your resources into 1 character and get 5 times the normal experience from monsters.
In addition to that there are some QoL changes:
- Multibag: You can now store up to 5 items in the inventory
- Heroes Boon: You have permanent wizard eye and torch light
- Teleport: Town Portal and Lloyd beacon scrolls are not consumed on use
- Master of all: You can learn many misc skills up to GM (Alchemy, Disarm Trap, Merchant, Identify Item/Monster, Repair)

