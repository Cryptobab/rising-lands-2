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
- Tranche backlog: [`docs/NEXT-20.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/NEXT-20.md)
- Godot entry: [`game/project.godot`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/project.godot)
- Shell scene: [`game/scenes/main.tscn`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scenes/main.tscn)
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
- deterministic Mission 1 through Mission 4 scenario maps exist and are loaded from JSON
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
- Mission 2, Mission 3, and Mission 4 now have actual scenario maps with build, stockpile, research, and diplomacy-driven objectives
- Mission 4 now introduces diplomacy targets, messenger alliance orders, alliance-tracking runtime state, and diplomacy-aware save/load
- `market` is now part of the runtime build palette and trains `messenger`
- the command layer now supports drag box-selection, grouped worker/combat orders, and durable worker move-hold behavior
- command markers and a minimap overlay now provide basic RTS spatial feedback in the active HUD
- the project now boots into a real shell scene with a mission board, save-slot controls, and a structured in-game HUD layered over the RTS runtime
- the active HUD now surfaces objective progress, recent mission alerts, deeper selection detail, and command-card style context
- selected production and research buildings now expose clickable command-card buttons in the shell HUD
- mission victory and defeat now surface a shell-side result panel with retry and next-mission actions
- shell options now persist runtime pressure and menu-pause behavior in `user://shell_settings.json`
- enemy combat units now advance on the player settlement when idle instead of stalling outside vision range
- enemy production plans now normalize into persisted plan ids with rally points, aggression modes, pressure targets, target priorities, and latched group-release coordination for trained and preplaced enemy units
- Mission 5 through Mission 25 now have authored scenario maps with diplomacy-count, exploration-area, build-in-area, survival, prison-break escape chains, trust-demand deadlines, takeover scripts, and queued guardian-wave behavior
- diplomacy targets now track clan trust, alliance thresholds, active demands, and revenge-on-failure state
- mission objectives now support alliance-count, unit-in-area, reach-area-once, build-in-area, control-building, clear-hostiles, clan-trust, and demand-status checks
- mission events now support alliance-count, clan-stance, clan-trust, demand-status, and unit-in-area triggers plus queued enemy-wave scheduling, explicit clan-stance shifts, trust changes, demand injection, dynamic build-palette updates, building transfer, unit transfer, enemy-building production plans, and mission-outcome actions
- campaign results now distinguish between mission victory and full campaign completion in the shell snapshot
- the shell mission board now renders the full 25-mission campaign with locked/completed states, best times, and win/loss summaries
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
- an eleventh Godot smoke-test script exists for diplomacy order persistence and Mission 4 alliance completion
- a twelfth Godot smoke-test script exists for grouped selection and grouped order behavior
- a thirteenth Godot smoke-test script exists for the shell scene, mission board, and HUD boot flow
- a fourteenth Godot smoke-test script exists for shell-settings persistence and live menu-pause behavior
- a fifteenth Godot smoke-test script exists for Chapter II content progression through Missions 5 and 8
- a sixteenth Godot smoke-test script exists for Chapter III content progression through Missions 9 and 12
- a seventeenth Godot smoke-test script exists for explicit mission-event clan-stance and mission-outcome actions
- an eighteenth Godot smoke-test script exists for diplomacy-demand fulfillment, persistence, and revenge failure paths
- a nineteenth Godot smoke-test script exists for Mission 13 through Mission 16 progression
- a twentieth Godot smoke-test script exists for dynamic build-palette unlock persistence
- a twenty-first Godot smoke-test script exists for Mission 17 through Mission 20 progression
- a twenty-second Godot smoke-test script exists for ownership-transfer takeover scripting
- a twenty-third Godot smoke-test script exists for Mission 21 through Mission 25 progression and full campaign completion
- a twenty-fourth Godot smoke-test script exists for enemy building production-plan persistence
- a twenty-fifth Godot smoke-test script exists for rally, aggression, target-priority, and save/load enemy AI behavior
- a twenty-sixth Godot smoke-test script exists for full mission-board shell rendering and campaign-complete shell state
- issue and PR templates exist for public repo workflow
- the old browser prototype files have been removed from the active codebase

Not done yet:

- stronger command queueing, selection UX, and richer HUD feedback
- broader diplomacy rules beyond the current trust-demand-revenge shell
- broader mission scripting coverage across additional scenarios and campaign flow
- more authored scenario maps beyond the first twenty-five campaign missions
- additional faction-specific buildings, support effects, and deeper unit parity beyond the current advanced roster slice
- expanded-content ruleset layered cleanly on top of the classic remake

## Important Paths

- Original game reference: `C:\Users\BAB\PROJECTS\Rising_land_remake\Rising Lands Release`
- Raw classic data: [`game/data/classic/raw/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/raw)
- Normalized classic data: [`game/data/classic/normalized/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/normalized)
- Godot bootstrap script: [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- Shell runtime: [`game/scripts/ui/app_shell.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/ui/app_shell.gd)
- Campaign runtime: [`game/scripts/core/campaign_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/campaign_state.gd)
- Godot classic loader: [`game/scripts/data/classic_database.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/data/classic_database.gd)
- Vertical-slice map: [`game/data/classic/vertical_slice/mission_001_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/mission_001_map.json)
- Mission 2 map: [`game/data/classic/vertical_slice/monde02_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde02_map.json)
- Mission 3 map: [`game/data/classic/vertical_slice/monde03_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde03_map.json)
- Mission 4 map: [`game/data/classic/vertical_slice/monde04_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde04_map.json)
- Mission 5 map: [`game/data/classic/vertical_slice/monde05_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde05_map.json)
- Mission 6 map: [`game/data/classic/vertical_slice/monde06_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde06_map.json)
- Mission 7 map: [`game/data/classic/vertical_slice/monde07_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde07_map.json)
- Mission 8 map: [`game/data/classic/vertical_slice/monde08_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde08_map.json)
- Mission 9 map: [`game/data/classic/vertical_slice/monde09_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde09_map.json)
- Mission 10 map: [`game/data/classic/vertical_slice/monde10_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde10_map.json)
- Mission 11 map: [`game/data/classic/vertical_slice/monde11_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde11_map.json)
- Mission 12 map: [`game/data/classic/vertical_slice/monde12_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde12_map.json)
- Mission 13 map: [`game/data/classic/vertical_slice/monde13_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde13_map.json)
- Mission 14 map: [`game/data/classic/vertical_slice/monde14_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde14_map.json)
- Mission 15 map: [`game/data/classic/vertical_slice/monde15_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde15_map.json)
- Mission 16 map: [`game/data/classic/vertical_slice/monde16_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde16_map.json)
- Mission 17 map: [`game/data/classic/vertical_slice/monde17_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde17_map.json)
- Mission 18 map: [`game/data/classic/vertical_slice/monde18_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde18_map.json)
- Mission 19 map: [`game/data/classic/vertical_slice/monde19_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde19_map.json)
- Mission 20 map: [`game/data/classic/vertical_slice/monde20_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde20_map.json)
- Mission 21 map: [`game/data/classic/vertical_slice/monde21_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde21_map.json)
- Mission 22 map: [`game/data/classic/vertical_slice/monde22_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde22_map.json)
- Mission 23 map: [`game/data/classic/vertical_slice/monde23_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde23_map.json)
- Mission 24 map: [`game/data/classic/vertical_slice/monde24_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde24_map.json)
- Mission 25 map: [`game/data/classic/vertical_slice/monde25_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde25_map.json)
- Enemy AI test map: [`game/data/classic/vertical_slice/enemy_ai_test_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/enemy_ai_test_map.json)
- Godot map loader: [`game/scripts/core/map_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/map_state.gd)
- Diplomacy runtime: [`game/scripts/core/diplomacy_target_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/diplomacy_target_state.gd)
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
- Diplomacy smoke test: [`game/scripts/tests/diplomacy_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/diplomacy_smoke.gd)
- Selection-orders smoke test: [`game/scripts/tests/selection_orders_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/selection_orders_smoke.gd)
- App-shell smoke test: [`game/scripts/tests/app_shell_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/app_shell_smoke.gd)
- Shell-settings smoke test: [`game/scripts/tests/shell_settings_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/shell_settings_smoke.gd)
- Chapter-two content smoke test: [`game/scripts/tests/chapter_two_content_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/chapter_two_content_smoke.gd)
- Chapter-three content smoke test: [`game/scripts/tests/chapter_three_content_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/chapter_three_content_smoke.gd)
- Mission-event actions smoke test: [`game/scripts/tests/mission_event_actions_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/mission_event_actions_smoke.gd)
- Diplomacy-demands smoke test: [`game/scripts/tests/diplomacy_demands_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/diplomacy_demands_smoke.gd)
- Mid-campaign content smoke test: [`game/scripts/tests/mid_campaign_content_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/mid_campaign_content_smoke.gd)
- Dynamic build-palette smoke test: [`game/scripts/tests/dynamic_build_palette_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/dynamic_build_palette_smoke.gd)
- Late-campaign content smoke test: [`game/scripts/tests/late_campaign_content_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/late_campaign_content_smoke.gd)
- Ownership-transfer smoke test: [`game/scripts/tests/ownership_transfer_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/ownership_transfer_smoke.gd)
- Final-campaign smoke test: [`game/scripts/tests/final_campaign_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/final_campaign_smoke.gd)
- Enemy-AI pressure smoke test: [`game/scripts/tests/enemy_ai_pressure_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/enemy_ai_pressure_smoke.gd)
- Enemy-AI behavior smoke test: [`game/scripts/tests/enemy_ai_behaviors_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/enemy_ai_behaviors_smoke.gd)
- Campaign-board smoke test: [`game/scripts/tests/campaign_board_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/campaign_board_smoke.gd)

## Next Session Start Here

1. Open [`game/project.godot`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/project.godot) in the Godot editor and validate rally-release timing plus mission-board readability on real missions, especially Mission 25 shell presentation.
2. Expand shell polish with richer campaign summaries, chapter framing, and post-campaign front-end flow.
3. Push next into expanded-mode data layering and faction-specific AI hooks rather than adding placeholder classic-campaign systems.
4. Broaden mission-event-driven enemy waves so scheduled reinforcements can opt into the same authored AI directives when needed.
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

Run the diplomacy smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/diplomacy_smoke.gd
```

Run the selection-orders smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/selection_orders_smoke.gd
```

Run the app-shell smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/app_shell_smoke.gd
```

Run the shell-settings smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/shell_settings_smoke.gd
```

Run the chapter-two content smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/chapter_two_content_smoke.gd
```

Run the chapter-three content smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/chapter_three_content_smoke.gd
```

Run the mission-event actions smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/mission_event_actions_smoke.gd
```

Run the diplomacy-demands smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/diplomacy_demands_smoke.gd
```

Run the mid-campaign content smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/mid_campaign_content_smoke.gd
```

Run the dynamic build-palette smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/dynamic_build_palette_smoke.gd
```

Run the late-campaign content smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/late_campaign_content_smoke.gd
```

Run the ownership-transfer smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/ownership_transfer_smoke.gd
```

Run the final-campaign smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/final_campaign_smoke.gd
```

Run the enemy-AI pressure smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/enemy_ai_pressure_smoke.gd
```

Run the enemy-AI behavior smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/enemy_ai_behaviors_smoke.gd
```

Run the campaign-board smoke test:

```powershell
& "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe" `
  --headless `
  --path "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game" `
  --script res://scripts/tests/campaign_board_smoke.gd
```

## Blockers

- `.NET SDK` is not installed, so a Godot C# workflow is not practical right now
- current shell PATH may need a refresh before bare `git` or `godot` commands resolve without full paths
