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
- deterministic Mission 1, Mission 2, and Mission 3 scenario maps exist and are loaded from JSON
- Mission 1 bootstrap now spawns a storehouse and worker units from imported classic data
- scenario maps can now define starting resources, starting buildings, starting units, and a mission-scoped build palette
- workers automatically gather, return, and deposit food, stone, and parts
- left-click selection and right-click worker assignment exist
- builders can place and complete `storehouse`, `culture`, `barracks`, `laboratory`, `library`, `sanctuary`, `workshop`, `garage`, `hangar`, `tower_catapult`, `tower_cannon`, and `wall` construction sites
- newly built storehouses become deposit targets
- completed `culture`, `barracks`, `sanctuary`, `workshop`, `garage`, and `hangar` buildings now support broader training queues
- completed `library` and `laboratory` buildings now support branch-based research queues
- completed `tower_catapult` and `tower_cannon` buildings now auto-fire on nearby enemies
- player combat units and enemy units now run through the same lightweight combat runtime
- Mission 1 map includes scripted enemy pressure data
- save/load exists for the current runtime state
- campaign progression now tracks unlocked and completed missions from imported classic metadata
- named save slots now persist runtime state plus slot metadata through a campaign profile
- runtime mission objectives now drive victory state instead of only the old stockpile fallback
- Mission 1 map now includes scripted mission-event beats, rewards, and reinforcements
- Mission 2 and Mission 3 now have actual scenario maps with build, stockpile, and research-driven objectives
- the debug HUD now surfaces objective progress, recent mission alerts, and deeper selection detail
- a Godot smoke-test script exists for the vertical-slice resource loop
- a second Godot smoke-test script exists for builder construction
- a third Godot smoke-test script exists for production, research, combat, and save/load
- a fourth Godot smoke-test script exists for runtime objectives
- a fifth Godot smoke-test script exists for mission events and mission-event save/load persistence
- a sixth Godot smoke-test script exists for the expanded roster and advanced-production save/load path
- a seventh Godot smoke-test script exists for defensive towers and tower-combat save/load path
- an eighth Godot smoke-test script exists for campaign progression and mission unlock persistence
- a ninth Godot smoke-test script exists for named save slots and slot-metadata persistence
- a tenth Godot smoke-test script exists for actual Mission 1 -> Mission 2 -> Mission 3 campaign content progression
- issue and PR templates exist for public repo workflow
- the old browser prototype files have been removed from the active codebase

Not done yet:

- stronger command queueing, selection UX, and HUD feedback
- diplomacy and broader meta-layer behavior beyond the current campaign/save-slot shell
- broader mission scripting coverage across additional scenarios and campaign flow
- more authored scenario maps beyond the first three campaign missions
- additional faction-specific buildings, support effects, and deeper unit parity beyond the current advanced roster slice
- expanded-content ruleset layered cleanly on top of the classic remake

## Important Paths

- Original game reference: `C:\Users\BAB\PROJECTS\Rising_land_remake\Rising Lands Release`
- Raw classic data: [`game/data/classic/raw/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/raw)
- Normalized classic data: [`game/data/classic/normalized/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/normalized)
- Godot bootstrap script: [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- Campaign runtime: [`game/scripts/core/campaign_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/campaign_state.gd)
- Godot classic loader: [`game/scripts/data/classic_database.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/data/classic_database.gd)
- Vertical-slice map: [`game/data/classic/vertical_slice/mission_001_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/mission_001_map.json)
- Mission 2 map: [`game/data/classic/vertical_slice/monde02_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde02_map.json)
- Mission 3 map: [`game/data/classic/vertical_slice/monde03_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde03_map.json)
- Godot map loader: [`game/scripts/core/map_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/map_state.gd)
- Mission-event runtime: [`game/scripts/core/mission_event_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/mission_event_state.gd)
- Worker runtime: [`game/scripts/simulation/worker_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/worker_unit_state.gd)
- Combat runtime: [`game/scripts/simulation/combat_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/combat_unit_state.gd)
- Building runtime: [`game/scripts/simulation/building_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/building_state.gd)
- Resource runtime: [`game/scripts/simulation/resource_node_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/resource_node_state.gd)
- Smoke test: [`game/scripts/tests/vertical_slice_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/vertical_slice_smoke.gd)
- Construction smoke test: [`game/scripts/tests/construction_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/construction_smoke.gd)
- Systems smoke test: [`game/scripts/tests/systems_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/systems_smoke.gd)
- Objective smoke test: [`game/scripts/tests/mission_objectives_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/mission_objectives_smoke.gd)
- Mission-events smoke test: [`game/scripts/tests/mission_events_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/mission_events_smoke.gd)
- Expanded-roster smoke test: [`game/scripts/tests/expanded_roster_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/expanded_roster_smoke.gd)
- Tower-defense smoke test: [`game/scripts/tests/tower_defense_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/tower_defense_smoke.gd)
- Campaign-progression smoke test: [`game/scripts/tests/campaign_progression_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/campaign_progression_smoke.gd)
- Save-slots smoke test: [`game/scripts/tests/save_slots_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/save_slots_smoke.gd)
- Multi-mission content smoke test: [`game/scripts/tests/multi_mission_content_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/multi_mission_content_smoke.gd)

## Next Session Start Here

1. Open [`game/project.godot`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/project.godot) in the Godot editor and validate Mission 2 / Mission 3 map bootstrapping, build palettes, and campaign handoff visually.
2. Add better selection UX, command feedback, and HUD surfacing for queues and research.
3. Extend the mission-event system from Mission 1 into reusable scenario scripting for later missions.
4. Author more actual mission-map content so the first campaign chapter extends beyond the current three playable scenarios.
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

Run the runtime-objectives smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/mission_objectives_smoke.gd
```

Run the mission-events smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/mission_events_smoke.gd
```

Run the expanded-roster smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/expanded_roster_smoke.gd
```

Run the tower-defense smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/tower_defense_smoke.gd
```

Run the campaign-progression smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/campaign_progression_smoke.gd
```

Run the save-slots smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/save_slots_smoke.gd
```

Run the multi-mission content smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/multi_mission_content_smoke.gd
```

## Blockers

- `.NET SDK` is not installed, so a Godot C# workflow is not practical right now
- current shell PATH may need a refresh before bare `git` or `godot` commands resolve without full paths
