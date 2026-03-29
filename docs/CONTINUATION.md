# Continuation

## Snapshot

- Date: `2026-03-29`
- Repo: `C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2`
- Public repo: `Cryptobab/rising-lands-2`
- Active engine: `Godot 4`
- Active language: typed `GDScript`
- Import tooling: `Python`
- Legacy prototype: retired and removed from the canonical branch

## Source Of Truth

- Roadmap: [`docs/MASTER-PLAN.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/MASTER-PLAN.md)
- Engine choice: [`docs/ENGINE-DECISION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/ENGINE-DECISION.md)
- Session trace: [`docs/SESSION-LOG.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/SESSION-LOG.md)
- Godot entry: [`game/project.godot`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/project.godot)
- Importer: [`tools/importers/extract_classic_data.py`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/tools/importers/extract_classic_data.py)

## Locked Decisions

- The browser prototype is no longer the target architecture.
- The browser prototype has been removed from the active branch.
- The shipping runtime direction is Godot 4.
- Classic remake parity comes before expansion content.
- Classic imported data and expanded data stay separate.
- Original proprietary binaries remain reference material, not public repo assets.

## Current State

Working now:

- Godot project scaffold exists
- importer exports both `raw/` and `normalized/` classic JSON
- normalized data includes units, buildings, spells, tech tree, strings, missions, and misc settings
- Godot bootstrap scene now loads normalized classic data counts and Mission 1 metadata
- deterministic Mission 1 bootstrap map exists and is loaded from JSON
- Mission 1 bootstrap now spawns a storehouse and worker units from imported classic data
- workers automatically gather, return, and deposit food, stone, and parts
- left-click selection and right-click worker assignment exist
- builders can place and complete `storehouse`, `culture`, `barracks`, and `laboratory` construction sites
- newly built storehouses become deposit targets
- completed `culture` and `barracks` buildings now support training queues
- completed `laboratory` buildings now support branch-based research queues
- player combat units and enemy units now run through the same lightweight combat runtime
- Mission 1 map includes scripted enemy pressure data
- save/load exists for the current runtime state
- a Godot smoke-test script exists for the vertical-slice resource loop
- a second Godot smoke-test script exists for builder construction
- a third Godot smoke-test script exists for production, research, combat, and save/load
- issue and PR templates exist for public repo workflow
- the old browser prototype files have been removed from the active codebase

Not done yet:

- richer mission scripting and objective logic beyond the bootstrap stockpile goal
- more complete unit rosters, buildings, and faction rules
- stronger command queueing, selection UX, and HUD feedback
- diplomacy, campaign progression, and save-slot UX
- expanded-content ruleset layered cleanly on top of the classic remake

## Important Paths

- Original game reference: `C:\Users\BAB\PROJECTS\Rising_land_remake\Rising Lands Release`
- Raw classic data: [`game/data/classic/raw/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/raw)
- Normalized classic data: [`game/data/classic/normalized/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/normalized)
- Godot bootstrap script: [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- Godot classic loader: [`game/scripts/data/classic_database.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/data/classic_database.gd)
- Vertical-slice map: [`game/data/classic/vertical_slice/mission_001_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/mission_001_map.json)
- Godot map loader: [`game/scripts/core/map_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/map_state.gd)
- Worker runtime: [`game/scripts/simulation/worker_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/worker_unit_state.gd)
- Combat runtime: [`game/scripts/simulation/combat_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/combat_unit_state.gd)
- Resource runtime: [`game/scripts/simulation/resource_node_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/resource_node_state.gd)
- Smoke test: [`game/scripts/tests/vertical_slice_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/vertical_slice_smoke.gd)
- Construction smoke test: [`game/scripts/tests/construction_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/construction_smoke.gd)
- Systems smoke test: [`game/scripts/tests/systems_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/systems_smoke.gd)

## Next Session Start Here

1. Open [`game/project.godot`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/project.godot) in the Godot editor and validate the new training, research, combat, and save/load interactions visually.
2. Expand the playable ruleset beyond the current `culture` / `barracks` / `laboratory` slice.
3. Add better selection UX, command feedback, and HUD surfacing for queues and research.
4. Push mission scripting forward so combat, production, and research tie into explicit objectives.
5. Keep the repo trace clean by updating this file and the session log whenever systems behavior changes.

## Commands

Refresh imported classic data:

```powershell
python tools/importers/extract_classic_data.py `
  --source "C:\Users\BAB\PROJECTS\Rising_land_remake\Rising Lands Release" `
  --output "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game\data\classic"
```

Run importer tests:

```powershell
python -m unittest discover `
  -s C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\tools\importers\tests `
  -p "test_*.py"
```

Run the Godot vertical-slice smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/vertical_slice_smoke.gd
```

Run the construction smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/construction_smoke.gd
```

Run the systems smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/systems_smoke.gd
```

## Blockers

- `.NET SDK` is not installed, so a Godot C# workflow is not practical right now
- current shell PATH may need a refresh before bare `git` or `godot` commands resolve without full paths
- the repo worktree now contains the next gameplay-systems tranche and should be reviewed before the next commit
