# Maw-Mod-MMMerge
Maw Mod code adapted for MMMerge
## Install instruction
- download MM8 from GOG
following 3 files needs to be copied into MM8 folder in that exact order.
  - download MMMerge at this link: https://drive.google.com/file/d/1f5-V-DtxB3u977RqdDH7hGbtZiGOQAGt/view
  - download Multiplayer Here: https://gitlab.com/letr.rod/mmmerge/-/archive/multiplayer/mmmerge-multiplayer.zip
  - download MAW MMMerge here: https://github.com/Malekitsu/Maw-Mod-MMMerge/archive/refs/heads/main.zip
- put MM8 folder into desktop
- set mm8.exe into Windows Service pack 2 (or 3) compatibility mode.
- check difficulty level (ingame esc/controls/extra setting on top)

## Overview
This mod is divided into 8 parts:
- Item rework
- Stats rework
- Skill rework
- Spells rework
- Monster rework
- Alchemy rework
- Bolster rework
- Mechanics rework

## Item Rework
- Items can now have up to 3 enchants: 2 base enchants and 1 special.
- Loot level is slightly influenced by the player's level:
  - Going early game in late areas will result in worse loot.
  - Late-game loot has been improved.
- You will have a chance to find ancient and primordial items:
  - Ancients will have higher stats.
  - Primordials will be similar to ancients but with consistently perfect stats.
- Enchants that increase your damage output are now stronger and apply to spells as well.
- Special enchantments that increase magic school levels now provide a flat bonus.

## Stats Rework
- Stats now provide 1 effect every 5 points (e.g., 500 Might will increase melee damage by 100).
- Might now applies to bows as well.
- Each stat has a unique additional bonus (visible by right-clicking the stat in the menu):
  - Might: Every 10 points increase physical damage by 1%.
  - Int/Pers: Every 10 points increase spell damage by 1% and spell critical damage by 1% (only the highest between the two will be applied).
  - Endurance: Every 10 points increase health by 1%.
  - Accuracy: Every 10 points increase melee/bow critical damage by 2%.
  - Speed: Every 10 points increase dodge by 0.5% (multiplicative).
  - Luck: Every 10 points increase critical strike chance by 0.5% (base crit % is 5%).
  - Armor Class: Reduces physical damage taken.

### Resistances
- Now are in percentage; each 4 points in resistance will reduce damage by 1%, capped at 75%.
- The cap can be increased by special enchantments, up to 90%.

## Skill Rework
- Most weapon and armor skills have been rebalanced; for complete information, check the in-game tooltips:
  - Weapons are now on par with damage in terms of damage output; they are better compared to single-target ranged spells but weaker than shotgun and AoE spells.
  - Armors will now also provide magic resistance.
  - Weapons are now balanced between each other.

## Spells Rework
- Starting at level 80, spells will be upgraded every 8 levels.
  - At level 80, tier 1 spells get an upgrade, at level 88, tier 2 spells, and so on.
  - Spells can be upgraded up to 2 times, up to player level 240.
  - Mana cost and damage are increased.
- Some spell tuning has been performed.

## Monsters
- Monsters are now much stronger, with significantly increased stats.
- Monster run speed has been increased.
- Monsters are balanced so that you will never need to use the bolster button.

## Alchemy
- Due to the powerful nature of stats, some nerfs were required.
- Health and mana potions will now heal much more based on power level and will remain relevant throughout the game.
- You have 2 shortcuts that will automatically consume the strongest health/mana potion from inventory (15-second cooldown).
- Status-removing potions will now also provide immunity for 6 hours.
- Some redundant potions have been removed.
- Enchant flasks are now permanent.
- Doom potions will now provide a huge boost but increase permanent age (can be used multiple times, up to 100 age).
- Rejuvenation will now reduce all stats but decrease permanent age.

## Bolster
- Bolster is no longer applied unless you change continents.
- When you change continents, monsters will retain a portion of the levels gained from other continents.
- Along with monster strength, loot strength will increase, including base stats, value, and enchants.
- Level is calculated based on the experience of the first party member; you are free to use hirelings.
- Adjustments have been made to ensure diversity among monsters of the same tier.

The actual formula is (level-4)*0.95, calculated based on experience, with other diminishing formulas applying after 120 bolster levels.

### Example
- Example 1:
  - You clear Might and Magic 6 at level 100.
  - Going to MM7 will increase all monster levels by 100, requiring you to start from the beginning without skipping.
  - You finish MM7 at level 180 and then proceed to MM8.
  - Monster levels are now increased by 180.
  - Going back to MM6 will increase monster levels by 80 (180-100=80).

## Mechanics Rework
- Dual-wielding weapons will now allow the player to benefit fully from both weapons.
- Recovery is now multiplicative; a 50 bonus recovery will increase attack speed by 50%.
- Player projectiles will now home in on the target.

Overall, changes have been made using mathematics and statistics to ensure balance, providing a smooth gaming experience. Many features are still missing, but the core mechanics are in place.
