# Maw-Mod-MMMerge
Maw Mod code adapted for MMMerge
## Install instruction
- download MM8 from GOG
- following 3 files needs to be copied into MM8 folder in that exact order.
  - download MMMerge here: https://drive.google.com/file/d/1f5-V-DtxB3u977RqdDH7hGbtZiGOQAGt/view
  - download Multiplayer here: https://gitlab.com/letr.rod/mmmerge/-/archive/multiplayer/mmmerge-multiplayer.zip
  - download MAW MMMerge here: https://github.com/Malekitsu/Maw-Mod-MMMerge/archive/refs/heads/main.zip
- put MM8 folder into desktop
- set mm8.exe into Windows Service pack 2 (or 3) compatibility mode.
- check difficulty & bolster settings once in game (ingame esc/controls/extra setting on top)

## Overview
This mod is divided the following parts:
- What you need to know
- Item rework
- Stats rework
- Class rework
- Skill rework
- Spells rework
- Monster rework
- Alchemy rework
- Bolster & Difficulty rework
- Mechanics rework

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
- Cap is at 93.75%.
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

## Class Rework
- most underused classes have been balanced to have some uniqueness
- misc skills are now a bit more accessible

### MAW Classes
- Added Seraphim, Death Knight and Shaman Class
- Press the icon top right on party creation to enable them
- Make sure to read their perks by right clicking on the class name

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
- Monsters deal double damage early on, and keep pace with increased player hitpoint and defenses, ending up at around 7 times vanilla damage, so you will need to balance both the offensive and defensive part of your build.
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


## Bolster & Difficulty
- There are 2 game modes, and you can check bolster value by right clicking level in stats menu:
- Free Progression (set monster bolster to on):
  - Recommended if you want to play just 1 of the 3 continents
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
  - Only loot will be "bolstered"
  - Most skills skills masteries will require 6-12-20 to learn E-M-GM
  - There are teleporters conveniently placed in starting cities (New Sorpigal, Harmondale, Ravenshore)

- Difficulty:
  - You can choose between Easy-MAW-Hard-Hell-Nightmare
    - Damage and monster HP will be multiplied corrispondently by 0.7 - 1 - 1.5 - 2 - 3
    - Loot power will be increased by 0% - 0% - 10% - 20% - 40%
    - Monster density will increase aswell
    - Once in Nightmare you can't change difficulty
      - You can't save nor teleport with monsters in the nearbies
      - Dungeons will now spawn elite monsters, with unique abilities
      - Exiting a dungeon before killing a set amount of monsters will make monsters resurrect (a message will be shown)
      - Killing most enemies will give you some exp-gold and crafting item



## Mechanics Rework
- Dual-wielding weapons will now allow the player to benefit fully from both weapons.
- Minotaurs can dual wield axes and 2h axes, at expert and master.
- Recovery is now multiplicative; a 50 bonus recovery will increase attack speed by 50%.
- Player projectiles will now home in on the target.
- Monster projectiles will now tend to home players:
  - Moving sideways is not enough to dodge, but running is enough
  - Flying up and down doesn't work
