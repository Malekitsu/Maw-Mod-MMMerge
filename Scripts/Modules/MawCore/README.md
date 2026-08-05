# MawCore — the Maw greenfield core

The clean structure the legacy mod gets migrated into, one system at a time
(strangler pattern). Full context: `GREENFIELD.md` at the repo root.

## Decisions in force (2026-08-04)

- **Same repo, side by side.** Legacy mod keeps running; systems migrate one at
  a time and their legacy counterparts get deleted when the replacement takes over.
- **Clean break on saves.** The finished greenfield requires a new game.
- **Multiplayer descoped.** State changes go through named functions so sync can
  be reattached later at those points.

## Load path

```
Scripts/General/zzzzzMaw_Core.lua      five z's -> loads after everything legacy
  -> require "MawCoreMain"             defines everything, in the order of ONE list
  -> MawCore.start()                   activates modules, same order
```

Load order inside the core is the `MawCore.ModuleOrder` list in
`MawCoreMain.lua` — never filenames, never extra z's.

## Files

| File | Owns |
|---|---|
| `Engine.lua` | the Tier-4 boundary: **only file allowed to use `mem.*`, raw addresses, struct offsets**; named address table + patch ledger |
| `Fixes.lua` | port of `MAW_Fixes.dll` (skill-hint format, recovery floor 30→1, mm8.ini fix) so the DLL could be deleted |
| `Skills.lua` | port of `Skillz.dll`, stage 1: storage, engine GetSkill, bonus clamp, persistence, mastery tables, full `Skillz.*` API + legacy DLL bridge — **bridges to the DLL if `ExeMods/Skillz.dll` exists** |
| `SkillTooltip.lua` | per-player skill tooltip text (`SKILL_TOOLTIPS.md`): `getTooltipText(pl, skillId)` + per-(skill, part) dynamic builders — replaces the legacy Tick handlers that rewrote the global desc store for the current player |
| `SkillsUI.lua` | `Skillz.dll` stage 2: char-screen rows for extended skills, skill hints (text from `SkillTooltip`), house Learn-Skills integration (see `SKILLZ_PORT.md` engineering notes) |
| `Pipeline.lua` | ordered named-stage chains — the replacement for N anonymous event handlers (damage is the first pipeline) |
| `MonsterHP.lua` | real monster HP beyond the engine's 16-bit cap: per-map ledger (`mapvars.MawMonsterHP`), engine keeps a capped proxy; registered via `MawSetMonsterHP` at the recalc/spawn sites, applied by the pipeline's `monster-hp` stage (see `DAMAGE_PIPELINE.md` "MonsterHP") |
| `Damage.lua` | the `CalcDamageToMonster` pipeline (`DAMAGE_PIPELINE.md`): all legacy handlers as named stages (phase 1 complete — 29 stages, verbatim bodies); registered per playthrough by `Scripts/Global/zzzzzMaw_Damage.lua` |
| `Scheduler.lua` | one `events.Tick`; named tasks at real-time intervals (game-time stays with MMExtension's `Timer`/`RefillTimer`) |
| `ItemFields.lua` | the item struct registry — the save format, with its two hazards documented |
| `Tooltip.lua` | item tooltips — ONE `BuildItemInformationBox` handler running 13 named ordered sections, whose bodies (moved verbatim from the legacy files) live in this file |
| `Save.lua` | `vars.MawCore` namespace + the clean-break version stamp |

## The two rules

1. **Loading defines, `start()` activates.** No module registers events, applies
   patches, or touches game state at load time.
2. **Only `Engine.lua` touches the engine.** Everything else asks it for a named
   function. Every patch goes through `Engine.patch` so the ledger stays complete.

Everything registered anywhere carries a **unique string id** — that's what makes
`describe()` output readable and single handlers replaceable during migration.

## Migration status

Live: `Fixes` (DLL patches), `Skills`/`SkillsUI` (Skillz port), `Damage`
(the CalcDamageToMonster pipeline), `MonsterHP`, `SkillTooltip` (skill
hints), `Tooltip` (all 13 item-tooltip sections). Still idle: `Scheduler`
(no tasks yet), `ItemFields` (no fields registered).

## Console inspection (in-game)

```lua
print(MawCore.Scheduler.describe())
print(MawCore.Tooltip.describe())
print(MawCore.SkillTooltip.describe())
print(MawCore.Engine.describe())
print(MawCore.ItemFields.describe())
```
