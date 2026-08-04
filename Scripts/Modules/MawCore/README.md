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
| `SkillsUI.lua` | `Skillz.dll` stage 2: char-screen rows for extended skills, Lua-built skill hints, house Learn-Skills integration (see `SKILLZ_PORT.md` engineering notes) |
| `Pipeline.lua` | ordered named-stage chains — the replacement for N anonymous event handlers (damage will be the first pipeline) |
| `Scheduler.lua` | one `events.Tick`; named tasks at real-time intervals (game-time stays with MMExtension's `Timer`/`RefillTimer`) |
| `ItemFields.lua` | the item struct registry — the save format, with its two hazards documented |
| `Tooltip.lua` | tooltip section registry — one `BuildItemInformationBox` handler, ordered sections |
| `Save.lua` | `vars.MawCore` namespace + the clean-break version stamp |

## The two rules

1. **Loading defines, `start()` activates.** No module registers events, applies
   patches, or touches game state at load time.
2. **Only `Engine.lua` touches the engine.** Everything else asks it for a named
   function. Every patch goes through `Engine.patch` so the ledger stays complete.

Everything registered anywhere carries a **unique string id** — that's what makes
`describe()` output readable and single handlers replaceable during migration.

## Deliberately absent (skeleton stage)

No game logic. No damage pipeline instance. No migrated handlers. No patches
applied. The only observable behaviour is one empty `Tick` handler and one
tooltip handler with zero sections — both no-ops.

## Console inspection (in-game)

```lua
print(MawCore.Scheduler.describe())
print(MawCore.Tooltip.describe())
print(MawCore.Engine.describe())
print(MawCore.ItemFields.describe())
```
