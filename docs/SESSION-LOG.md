# Session Log

## 2026-03-29

### Summary

- switched the project direction from the browser prototype to a Godot 4 rewrite
- created the Godot project scaffold under `game/`
- added public repo contribution and issue/PR templates
- connected local `origin` config to `Cryptobab/rising-lands-2`
- built importer tooling that reads the original game files
- exported both raw and normalized classic data JSON
- wired the Godot bootstrap scene to load normalized classic data and Mission 1 metadata
- added a deterministic Mission 1 bootstrap map JSON and Godot map loader
- installed Git and Godot locally with `winget`
- validated the Godot project with a headless startup run
- implemented the first real worker economy loop on the Mission 1 map
- added a Godot smoke-test script for the vertical-slice stockpile goal
- added selection, right-click assignment, and first construction controls
- added a builder-construction smoke test
- removed the old browser prototype from the canonical branch
- removed the obsolete legacy project-plan file from the active docs set
- added production queues, research queues, enemy combat pressure, and runtime save/load
- added a dedicated combat-unit simulation script and systems smoke test
- added runtime mission objectives and objective-driven victory evaluation
- added a mission-event runtime with scripted alerts, rewards, reinforcements, and save/load persistence
- added mission-objective and mission-event smoke tests
- expanded the playable roster with sanctuary, workshop, garage, hangar, and library production/research support
- added defensive tower runtime behavior plus a larger builder build palette
- added expanded-roster and tower-defense smoke tests
- added a campaign-state runtime for mission completion and unlock persistence
- added named save-slot support with profile-backed slot metadata
- added campaign-progression and save-slots smoke tests
- extended the map schema with starting resources, starting buildings, starting units, and scenario-scoped build palettes
- authored actual Mission 2 and Mission 3 scenario maps on top of the campaign shell
- added a multi-mission content smoke test covering Mission 1 through Mission 3 progression
- added a diplomacy-target runtime and alliance-tracking mission snapshot state
- added messenger diplomacy orders plus diplomacy-aware save/load persistence
- expanded the build palette and production runtime with `market` support
- authored an actual Mission 4 diplomacy scenario map
- extended the multi-mission content smoke test through Mission 4 and Mission 5 unlock
- added a dedicated diplomacy smoke test covering messenger-order persistence and alliance completion
- added drag box-selection and grouped worker/combat order handling to the Godot runtime
- fixed worker move orders so manual repositioning holds instead of immediately collapsing back into auto-gather
- added command markers and a minimap overlay to the active HUD
- added a selection-orders smoke test for grouped selection and formation movement
- replaced the direct `GameRoot` boot scene with a shell scene that owns the menu overlay and structured in-game HUD
- added a mission board, save-slot operations panel, and top/left/right/bottom HUD layout in a dedicated UI script
- added a `GameRoot` snapshot API so the shell can render mission state without depending on the debug label
- added an app-shell smoke test that validates menu boot, mission launch, and HUD visibility
- added clickable command-card buttons for selected production and research buildings in the shell HUD
- added a shell-side mission result panel with retry and next-mission actions
- added persistent shell options for enemy pressure and menu pause behavior
- added a shell-settings smoke test that validates settings persistence and live menu runtime flow
- added idle enemy assault behavior so hostile combat units advance on the settlement instead of waiting outside vision range
- extended mission objectives with alliance-count and exploration-area support
- extended mission-event triggers/actions with alliance-count, exploration-area, and queued enemy-wave scheduling
- authored Mission 5 and Mission 6 scenario maps for the chapter-two campaign slice
- extended mission objectives with build-in-area support for beachhead scenarios
- authored Mission 7 and Mission 8 scenario maps for the full chapter-two campaign slice
- extended the chapter-two content smoke test through Mission 8 progression
- extended diplomacy from binary alliance state into neutral/allied/hostile clan stances
- added explicit mission-event actions for clan stance changes and forced mission outcomes
- added a cleanup pass that clears combat target references across mission transitions to avoid leaked runtime refs in long campaign smokes
- authored Mission 9 through Mission 12 scenario maps for the chapter-three campaign slice
- added a chapter-three content smoke test that covers Mission 9 through Mission 12 progression
- added a mission-event actions smoke test for hostile-clan and forced-outcome scripting
- expanded diplomacy again with per-clan trust, alliance thresholds, active demands, and revenge-on-failure state
- extended mission objectives and mission-event triggers/actions for clan trust and demand-status flows
- authored Mission 13 through Mission 16 scenario maps for the next mid-campaign slice
- added a diplomacy-demands smoke test for trust fulfillment, save/load persistence, and revenge failure
- added a mid-campaign content smoke test covering Mission 13 through Mission 16 progression
- extended mission objectives with a latched reach-area-once mode for escape/discovery scenarios
- extended mission-event actions with dynamic build-palette unlock and replacement support, including save/load persistence
- authored Mission 17 through Mission 20 scenario maps for the next late-campaign slice
- added a dynamic build-palette smoke test for runtime palette unlock persistence
- added a late-campaign content smoke test covering Mission 17 through Mission 20 progression
- added a tracked next-20 execution backlog document for the current tranche
- added control-building objective support plus mission-event building/unit ownership transfer actions
- added campaign-complete detection and campaign-complete result payload support
- authored Mission 21 through Mission 25 scenario maps for the remainder of the classic campaign
- added an ownership-transfer smoke test for Great Library takeover scripting
- added a final-campaign smoke test covering Mission 21 through Mission 25 progression and campaign completion
- added enemy-building production-plan runtime support with save/load persistence
- authored a dedicated enemy-AI pressure map and applied enemy production plans to Mission 25
- expanded the shell mission board to show all missions, locked/completed state, win/loss record, and best clear time
- added an enemy-AI pressure smoke test and a campaign-board shell smoke test
- extended enemy production plans into persisted rally, aggression, pressure-target, and target-priority directives for trained and preplaced enemy units
- added latched group-release coordination so rally plans can stage waves before committing across the map
- added an enemy-AI behaviors smoke test and authored coordinated Mission 25 pressure metadata on top of the late-campaign baseline
- extended `schedule_enemy_wave` so scripted reinforcements can carry authored AI directives or attach to existing plan ids with save/load persistence
- polished the shell with chapter-framed mission labels, synopsis-aware mission-board rows, richer campaign record summaries, and clearer next-mission result copy
- added an enemy-AI wave-directives smoke test plus shell assertions for the new chapter/synopsis presentation
- added a neutral `RulesetDatabase` layer backed by per-ruleset manifests so runtime/bootstrap logic no longer hard-wires the classic normalized path
- threaded explicit `ruleset_id` metadata through runtime saves, campaign profiles, slot metadata, world-state payloads, and shell snapshots
- added an internal expanded proving-ground mission/map dataset under `game/data/expanded` to prove alternate ruleset discovery without exposing a public unfinished mode
- added a ruleset-loader smoke test and extended classic shell/save-slot smokes with ruleset-identity assertions
- fixed enemy rally targeting so hostile units do not treat their own structures as attack targets while forming up
- fixed rally-group release evaluation so queued-wave directives can hold, latch, and release through the same AI-plan context as authored enemy plans
- refreshed the dedicated enemy-AI test timings/data and the final-campaign smoke so the full regression suite matches the tested runtime behavior

### Files Added Or Changed

- [`README.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/README.md)
- [`docs/MASTER-PLAN.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/MASTER-PLAN.md)
- [`docs/ENGINE-DECISION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/ENGINE-DECISION.md)
- [`docs/CONTINUATION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/CONTINUATION.md)
- [`game/project.godot`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/project.godot)
- [`game/scenes/main.tscn`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scenes/main.tscn)
- [`game/scripts/autoload/game_config.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/autoload/game_config.gd)
- [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- [`game/scripts/core/world_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/world_state.gd)
- [`game/scripts/core/campaign_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/campaign_state.gd)
- [`game/scripts/core/mission_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/mission_state.gd)
- [`game/scripts/core/mission_event_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/mission_event_state.gd)
- [`game/scripts/core/diplomacy_target_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/diplomacy_target_state.gd)
- [`game/scripts/core/map_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/map_state.gd)
- [`game/scripts/ui/app_shell.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/ui/app_shell.gd)
- [`game/scripts/data/classic_database.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/data/classic_database.gd)
- [`game/scripts/data/ruleset_database.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/data/ruleset_database.gd)
- [`game/scripts/simulation/worker_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/worker_unit_state.gd)
- [`game/scripts/simulation/combat_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/combat_unit_state.gd)
- [`game/scripts/simulation/resource_node_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/resource_node_state.gd)
- [`game/scripts/simulation/building_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/building_state.gd)
- [`game/scripts/simulation/construction_site_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/construction_site_state.gd)
- [`game/scripts/simulation/combat_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/combat_unit_state.gd)
- [`game/scripts/tests/vertical_slice_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/vertical_slice_smoke.gd)
- [`game/scripts/tests/construction_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/construction_smoke.gd)
- [`game/scripts/tests/systems_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/systems_smoke.gd)
- [`game/scripts/tests/mission_objectives_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/mission_objectives_smoke.gd)
- [`game/scripts/tests/mission_events_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/mission_events_smoke.gd)
- [`game/scripts/tests/expanded_roster_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/expanded_roster_smoke.gd)
- [`game/scripts/tests/tower_defense_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/tower_defense_smoke.gd)
- [`game/scripts/tests/campaign_progression_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/campaign_progression_smoke.gd)
- [`game/scripts/tests/save_slots_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/save_slots_smoke.gd)
- [`game/scripts/tests/multi_mission_content_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/multi_mission_content_smoke.gd)
- [`game/scripts/tests/diplomacy_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/diplomacy_smoke.gd)
- [`game/scripts/tests/selection_orders_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/selection_orders_smoke.gd)
- [`game/scripts/tests/app_shell_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/app_shell_smoke.gd)
- [`game/scripts/tests/shell_settings_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/shell_settings_smoke.gd)
- [`game/data/classic/vertical_slice/mission_001_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/mission_001_map.json)
- [`game/data/classic/vertical_slice/monde02_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde02_map.json)
- [`game/data/classic/vertical_slice/monde03_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde03_map.json)
- [`game/data/classic/vertical_slice/monde04_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde04_map.json)
- [`game/data/classic/vertical_slice/monde05_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde05_map.json)
- [`game/data/classic/vertical_slice/monde06_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde06_map.json)
- [`game/data/classic/vertical_slice/monde07_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde07_map.json)
- [`game/data/classic/vertical_slice/monde08_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde08_map.json)
- [`game/data/classic/vertical_slice/monde09_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde09_map.json)
- [`game/data/classic/vertical_slice/monde10_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde10_map.json)
- [`game/data/classic/vertical_slice/monde11_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde11_map.json)
- [`game/data/classic/vertical_slice/monde12_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde12_map.json)
- [`game/data/classic/vertical_slice/monde13_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde13_map.json)
- [`game/data/classic/vertical_slice/monde14_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde14_map.json)
- [`game/data/classic/vertical_slice/monde15_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde15_map.json)
- [`game/data/classic/vertical_slice/monde16_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde16_map.json)
- [`game/data/classic/vertical_slice/monde17_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde17_map.json)
- [`game/data/classic/vertical_slice/monde18_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde18_map.json)
- [`game/data/classic/vertical_slice/monde19_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde19_map.json)
- [`game/data/classic/vertical_slice/monde20_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde20_map.json)
- [`game/data/classic/vertical_slice/monde21_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde21_map.json)
- [`game/data/classic/vertical_slice/monde22_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde22_map.json)
- [`game/data/classic/vertical_slice/monde23_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde23_map.json)
- [`game/data/classic/vertical_slice/monde24_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde24_map.json)
- [`game/data/classic/vertical_slice/monde25_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde25_map.json)
- [`game/data/classic/vertical_slice/enemy_ai_test_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/enemy_ai_test_map.json)
- [`game/data/classic/ruleset_manifest.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/ruleset_manifest.json)
- [`game/data/expanded/ruleset_manifest.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded/ruleset_manifest.json)
- [`game/data/expanded/normalized/manifest.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded/normalized/manifest.json)
- [`game/data/expanded/normalized/missions.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded/normalized/missions.json)
- [`game/data/expanded/normalized/units.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded/normalized/units.json)
- [`game/data/expanded/normalized/buildings.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded/normalized/buildings.json)
- [`game/data/expanded/normalized/spells.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded/normalized/spells.json)
- [`game/data/expanded/normalized/tech_tree.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded/normalized/tech_tree.json)
- [`game/data/expanded/normalized/strings.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded/normalized/strings.json)
- [`game/data/expanded/normalized/misc.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded/normalized/misc.json)
- [`game/data/expanded/vertical_slice/expedition01_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded/vertical_slice/expedition01_map.json)
- [`tools/importers/extract_classic_data.py`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/tools/importers/extract_classic_data.py)
- [`tools/importers/tests/test_extract_classic_data.py`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/tools/importers/tests/test_extract_classic_data.py)
- [`game/scripts/tests/chapter_two_content_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/chapter_two_content_smoke.gd)
- [`game/scripts/tests/chapter_three_content_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/chapter_three_content_smoke.gd)
- [`game/scripts/tests/mission_event_actions_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/mission_event_actions_smoke.gd)
- [`game/scripts/tests/diplomacy_demands_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/diplomacy_demands_smoke.gd)
- [`game/scripts/tests/mid_campaign_content_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/mid_campaign_content_smoke.gd)
- [`game/scripts/tests/dynamic_build_palette_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/dynamic_build_palette_smoke.gd)
- [`game/scripts/tests/late_campaign_content_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/late_campaign_content_smoke.gd)
- [`docs/NEXT-20.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/NEXT-20.md)
- [`game/scripts/tests/ownership_transfer_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/ownership_transfer_smoke.gd)
- [`game/scripts/tests/final_campaign_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/final_campaign_smoke.gd)
- [`game/scripts/tests/enemy_ai_pressure_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/enemy_ai_pressure_smoke.gd)
- [`game/scripts/tests/enemy_ai_behaviors_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/enemy_ai_behaviors_smoke.gd)
- [`game/scripts/tests/enemy_ai_wave_directives_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/enemy_ai_wave_directives_smoke.gd)
- [`game/scripts/tests/campaign_board_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/campaign_board_smoke.gd)
- [`game/scripts/tests/ruleset_loader_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/ruleset_loader_smoke.gd)
- [`game/scripts/tests/enemy_ai_pressure_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/enemy_ai_pressure_smoke.gd)
- [`game/scripts/tests/enemy_ai_wave_directives_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/enemy_ai_wave_directives_smoke.gd)
- [`game/scripts/tests/final_campaign_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/final_campaign_smoke.gd)

### Validation

- importer executed successfully against the original release folder
- raw and normalized JSON datasets were generated
- importer module compiled with `py_compile`
- importer unit tests passed
- Godot headless startup completed without reported errors
- Godot headless vertical-slice simulation completed without reported errors
- Godot headless construction smoke test completed without reported errors
- Godot headless systems smoke test completed without reported errors
- Godot headless mission-objectives smoke test completed without reported errors
- Godot headless mission-events smoke test completed without reported errors
- Godot headless expanded-roster smoke test completed without reported errors
- Godot headless tower-defense smoke test completed without reported errors
- Godot headless campaign-progression smoke test completed without reported errors
- Godot headless save-slots smoke test completed without reported errors
- Godot headless multi-mission content smoke test completed without reported errors through Mission 4
- Godot headless diplomacy smoke test completed without reported errors
- Godot headless selection-orders smoke test completed without reported errors
- Godot headless app-shell smoke test completed without reported errors
- Godot headless shell-settings smoke test completed without reported errors
- Godot headless chapter-two content smoke test completed without reported errors through Mission 8
- Godot headless chapter-three content smoke test completed without reported errors through Mission 12
- Godot headless mission-event actions smoke test completed without reported errors
- Godot headless diplomacy-demands smoke test completed without reported errors
- Godot headless mid-campaign content smoke test completed without reported errors through Mission 16
- Godot headless dynamic build-palette smoke test completed without reported errors
- Godot headless late-campaign content smoke test completed without reported errors through Mission 20
- Godot headless ownership-transfer smoke test completed without reported errors
- Godot headless final-campaign smoke test completed without reported errors through Mission 25
- Godot headless enemy-AI pressure smoke test completed without reported errors
- Godot headless enemy-AI behaviors smoke test completed without reported errors
- Godot headless enemy-AI wave-directives smoke test completed without reported errors
- Godot headless campaign-board smoke test completed without reported errors
- Godot headless ruleset-loader smoke test completed without reported errors
- Godot headless save-slots smoke test still completed without reported errors after ruleset-id persistence was added
- Godot headless app-shell smoke test still completed without reported errors after classic ruleset snapshot assertions were added
- Godot headless startup completed without reported errors after the ruleset-loader tranche
- importer unit tests passed after the ruleset-loader tranche
- the full Godot smoke-test regression suite was re-run in explicit batches and completed without reported errors after the ruleset-loader and enemy-AI fixes

### Outstanding

- validate the project in the interactive Godot editor
- start explicit expanded-mode layering and loader hooks now that the classic shell and AI continuation tranche is in place

## 2026-03-30

### Summary

- added campaign-level carryover state for unlocked research and clan stance/trust relationships
- applied carried research on mission bootstrap so completed tech branches persist across mission transitions and campaign-profile reloads
- merged carried diplomacy into later mission bootstraps only when the scenario does not already author an explicit stance or trust opening
- surfaced carryover summaries in the shell snapshot/HUD context
- added a dedicated campaign-carryover smoke test that covers victory capture, next-mission bootstrap, explicit stance override behavior, and profile reload restoration

### Files Added Or Changed

- [`README.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/README.md)
- [`docs/CONTINUATION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/CONTINUATION.md)
- [`docs/SESSION-LOG.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/SESSION-LOG.md)
- [`game/scripts/core/campaign_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/campaign_state.gd)
- [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- [`game/scripts/ui/app_shell.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/ui/app_shell.gd)
- [`game/scripts/tests/campaign_carryover_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/campaign_carryover_smoke.gd)

### Validation

- importer unit tests passed
- Godot headless vertical-slice smoke test completed without reported errors
- Godot headless construction smoke test completed without reported errors
- Godot headless systems smoke test completed without reported errors
- Godot headless mission-objectives smoke test completed without reported errors
- Godot headless mission-events smoke test completed without reported errors
- Godot headless expanded-roster smoke test completed without reported errors
- Godot headless tower-defense smoke test completed without reported errors
- Godot headless campaign-progression smoke test completed without reported errors
- Godot headless save-slots smoke test completed without reported errors
- Godot headless multi-mission content smoke test completed without reported errors
- Godot headless diplomacy smoke test completed without reported errors
- Godot headless selection-orders smoke test completed without reported errors
- Godot headless app-shell smoke test completed without reported errors
- Godot headless shell-settings smoke test completed without reported errors
- Godot headless chapter-two content smoke test completed without reported errors
- Godot headless chapter-three content smoke test completed without reported errors
- Godot headless mission-event actions smoke test completed without reported errors
- Godot headless diplomacy-demands smoke test completed without reported errors
- Godot headless mid-campaign content smoke test completed without reported errors
- Godot headless dynamic build-palette smoke test completed without reported errors
- Godot headless late-campaign content smoke test completed without reported errors
- Godot headless ownership-transfer smoke test completed without reported errors
- Godot headless final-campaign smoke test completed without reported errors
- Godot headless enemy-AI pressure smoke test completed without reported errors
- Godot headless enemy-AI behaviors smoke test completed without reported errors
- Godot headless enemy-AI wave-directives smoke test completed without reported errors
- Godot headless campaign-board smoke test completed without reported errors
- Godot headless ruleset-loader smoke test completed without reported errors
- Godot headless campaign-carryover smoke test completed without reported errors

### Outstanding

- validate the project in the interactive Godot editor
- start explicit expanded-mode layering and loader hooks now that classic carryover is in place on top of the shell/ruleset baseline

### Roadmap Audit And Continuation Refresh

- audited the repo docs against the current runtime and test surface
- verified importer tests plus representative Godot smoke coverage on the local machine
- confirmed that the classic baseline is real and playable, including campaign completion, shell flow, ruleset loading, enemy AI wave directives, and campaign carryover
- identified the main blockers to calling the remake fully revamped: hunger, spell casting, balloon or heliped transport, creature taming, stronger movement quality, Godot CI, and shipping or presentation layers
- rewrote the master roadmap to reflect the verified truth state instead of the older bootstrap-phase assumptions
- rewrote the continuation handoff into an autonomous execution runbook ordered around the actual missing classic parity systems
- replaced the old retrospective `NEXT-20` recap with a forward tranche aimed at hunger, spells, transport, taming, and Godot CI

### Files Added Or Changed

- [`docs/MASTER-PLAN.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/MASTER-PLAN.md)
- [`docs/CONTINUATION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/CONTINUATION.md)
- [`docs/NEXT-20.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/NEXT-20.md)
- [`docs/SESSION-LOG.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/SESSION-LOG.md)

### Validation

- importer unit tests passed
- Godot headless systems smoke test completed without reported errors
- Godot headless app-shell smoke test completed without reported errors
- Godot headless final-campaign smoke test completed without reported errors
- Godot headless enemy-AI wave-directives smoke test completed without reported errors
- Godot headless ruleset-loader smoke test completed without reported errors
- Godot headless campaign-carryover smoke test completed without reported errors

### Outstanding

- execute the new parity-focused `NEXT-20` tranche starting with hunger
- add Godot runtime CI so the larger smoke surface can be exercised without local shell timeout constraints

### Hunger Runtime Tranche

- audited the imported classic data and confirmed that food costs, housing values, and creature references existed in data while the runtime still lacked a real hunger loop
- added world-state hunger tracking with periodic ration consumption, starvation strike tracking, save persistence, and shell-visible hunger status
- added runtime starvation pressure so repeated missed rations now damage the clan and eventually fail the mission
- threaded hunger state into mission snapshots, debug output, and the shell resource or context presentation
- added a dedicated `hunger_smoke.gd` regression that verifies food consumption, save/load persistence, HUD snapshot visibility, and starvation defeat
- updated the roadmap, continuation runbook, and next-tranche backlog so spells are now the next autonomous priority instead of hunger

### Files Added Or Changed

- [`docs/MASTER-PLAN.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/MASTER-PLAN.md)
- [`docs/CONTINUATION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/CONTINUATION.md)
- [`docs/NEXT-20.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/NEXT-20.md)
- [`docs/SESSION-LOG.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/SESSION-LOG.md)
- [`game/scripts/core/world_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/world_state.gd)
- [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- [`game/scripts/ui/app_shell.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/ui/app_shell.gd)
- [`game/scripts/tests/hunger_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/hunger_smoke.gd)

### Validation

- importer unit tests passed
- Godot headless hunger smoke test completed without reported errors
- Godot headless vertical-slice smoke test completed without reported errors
- Godot headless systems smoke test completed without reported errors
- Godot headless app-shell smoke test completed without reported errors
- Godot headless ruleset-loader smoke test completed without reported errors
- Godot headless campaign-carryover smoke test completed without reported errors
- Godot headless final-campaign smoke test completed without reported errors

### Outstanding

- start the spell-runtime tranche
- keep the hunger numbers conservative until a broader balance pass and longer campaign regression sweep happen

### Spell Runtime Tranche

- audited normalized classic spell data and selected a first supported druid spell slice instead of waiting for a full spell-system rewrite
- added spell lookup helpers on the ruleset database
- extended combat units with mana, cooldowns, persistent spell effects, and petrification disable state
- wired the existing context-command surface so a selected druid can cast spells through the command card or hotkeys
- implemented a first playable spell subset with persistent support and offensive behavior: `armour`, `vision`, `petrification`, and `nova`
- surfaced spell state in selected-unit detail and broadened the HUD command placeholder text to acknowledge druid actions
- added a dedicated `spell_smoke.gd` regression covering command-surface spell casting, mana spending, persistence, petrification, and nova damage
- updated the roadmap, continuation runbook, and active backlog so transport is now the next autonomous priority instead of spells

### Files Added Or Changed

- [`docs/MASTER-PLAN.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/MASTER-PLAN.md)
- [`docs/CONTINUATION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/CONTINUATION.md)
- [`docs/NEXT-20.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/NEXT-20.md)
- [`docs/SESSION-LOG.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/SESSION-LOG.md)
- [`game/scripts/data/ruleset_database.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/data/ruleset_database.gd)
- [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- [`game/scripts/simulation/combat_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/combat_unit_state.gd)
- [`game/scripts/ui/app_shell.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/ui/app_shell.gd)
- [`game/scripts/tests/spell_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/spell_smoke.gd)

### Validation

- importer unit tests passed
- Godot headless spell smoke test completed without reported errors
- Godot headless hunger smoke test completed without reported errors
- Godot headless vertical-slice smoke test completed without reported errors
- Godot headless systems smoke test completed without reported errors
- Godot headless app-shell smoke test completed without reported errors
- Godot headless ruleset-loader smoke test completed without reported errors
- Godot headless campaign-carryover smoke test completed without reported errors
- Godot headless final-campaign smoke test completed without reported errors

### Outstanding

- start the transport tranche for `balloon` and `heliped`
- expand spell depth later with broader targeting, full classic spell coverage, and presentation work once the remaining parity blockers are closed

### Transport Runtime Tranche

- implemented real carrier state for `balloon` and `heliped`, including boarding capacity, passenger manifests, and save/load persistence
- added stable entity ids for worker and combat actors so boarded passengers can survive save/load and carrier ownership changes cleanly
- wired right-click boarding orders into the existing selection flow and added unload actions to the unit command card
- made boarded units invisible and inactive in selection, combat targeting, and rendering while still counting for population and mission logic
- verified that mission-area objectives can resolve from transported passengers by syncing boarded-unit positions to the carrier location
- broadened the HUD command placeholder text to acknowledge transport actions and updated the roadmap/backlog so taming is now the next autonomous priority

### Files Added Or Changed

- [`docs/MASTER-PLAN.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/MASTER-PLAN.md)
- [`docs/CONTINUATION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/CONTINUATION.md)
- [`docs/NEXT-20.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/NEXT-20.md)
- [`docs/SESSION-LOG.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/SESSION-LOG.md)
- [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- [`game/scripts/simulation/combat_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/combat_unit_state.gd)
- [`game/scripts/simulation/worker_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/worker_unit_state.gd)
- [`game/scripts/simulation/building_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/building_state.gd)
- [`game/scripts/ui/app_shell.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/ui/app_shell.gd)
- [`game/scripts/tests/transport_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/transport_smoke.gd)

### Validation

- importer unit tests passed
- Godot headless transport smoke test completed without reported errors
- Godot headless spell smoke test completed without reported errors
- Godot headless hunger smoke test completed without reported errors
- Godot headless systems smoke test completed without reported errors
- Godot headless app-shell smoke test completed without reported errors
- Godot headless final-campaign smoke test completed without reported errors
- Godot headless enemy-AI wave-directives smoke test completed without reported errors
- Godot headless ruleset-loader smoke test completed without reported errors
- Godot headless campaign-carryover smoke test completed without reported errors
- Godot headless vertical-slice smoke test completed without reported errors

### Outstanding

- start the taming tranche using the now-live transport and spell baselines as the next parity feature
- add Godot runtime CI so the representative smoke surface runs automatically instead of depending on local batching

### Taming Runtime Tranche

- implemented a first honest taming path on the existing druid command surface instead of inventing a separate targeting mode
- limited taming to weakened creature units from the imported classic roster so the feature uses real mission and unit data
- transferred tamed creatures into the player combat roster with clean team-color refresh, cleared enemy AI state, and save/load persistence
- reused existing mission unit-count logic so a tamed creature can satisfy runtime objectives without bespoke mission hacks
- added a dedicated `taming_smoke.gd` regression covering command exposure, weakened-target gating, allegiance transfer, save/load persistence, and post-tame combat behavior

### Files Added Or Changed

- [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- [`game/scripts/simulation/combat_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/combat_unit_state.gd)
- [`game/scripts/tests/taming_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/taming_smoke.gd)

### Validation

- importer unit tests passed
- Godot headless taming smoke test completed without reported errors
- Godot headless transport smoke test completed without reported errors
- Godot headless spell smoke test completed without reported errors
- Godot headless hunger smoke test completed without reported errors
- Godot headless systems smoke test completed without reported errors
- Godot headless app-shell smoke test completed without reported errors
- Godot headless final-campaign smoke test completed without reported errors
- Godot headless enemy-AI wave-directives smoke test completed without reported errors
- Godot headless ruleset-loader smoke test completed without reported errors
- Godot headless campaign-carryover smoke test completed without reported errors
- Godot headless vertical-slice smoke test completed without reported errors

### Outstanding

- move the active lane from parity feature closure into runtime decomposition, polish, export discipline, and expanded seeding
- keep extending spell depth and unit differentiation now that transport and taming are both live

### Godot CI Tranche

- added a dedicated GitHub Actions workflow for the representative Godot smoke batch instead of folding it into the Python-only workflow
- pinned the workflow to Godot `4.6.1` and verified the official Linux editor download URL resolves
- updated the roadmap, continuation handoff, and next-tranche backlog so autonomous continuation now points at classic alpha polish and shipping discipline instead of stale parity blockers

### Files Added Or Changed

- [`.github/workflows/godot-runtime.yml`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/.github/workflows/godot-runtime.yml)
- [`docs/MASTER-PLAN.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/MASTER-PLAN.md)
- [`docs/CONTINUATION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/CONTINUATION.md)
- [`docs/NEXT-20.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/NEXT-20.md)
- [`docs/SESSION-LOG.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/SESSION-LOG.md)

### Validation

- official `4.6.1` Linux Godot download URL returned a successful HTTP response during this session
- local importer tests and representative Godot smoke batches remained green after the workflow file was added

### Outstanding

- add export presets or packaging discipline to complement the now-live runtime CI
- start the first `GameRoot` extraction boundary defined in the new `NEXT-20` tranche

### GameRoot Command-Surface Tranche

- audited `game_root.gd` and selected the command-card plus selected-unit action surface as the first honest extraction boundary because it was large, UI-facing, and save-independent
- extracted command-card action building, selected-unit detail formatting, selection summary text, and context-hint generation into `game_root_command_surface.gd`
- kept the actual spell, taming, transport, and production mutations inside `GameRoot`, so the public gameplay behavior stayed stable while the orchestration file shrank
- added a dedicated `command_surface_smoke.gd` regression covering building actions, druid spell actions, transport action labels, and save/load persistence for the extracted helper
- extended the Godot runtime workflow so CI now covers the new command-surface boundary alongside the existing representative smokes
- verified importer tests plus `systems_smoke`, `command_surface_smoke`, `spell_smoke`, `transport_smoke`, and `taming_smoke` locally after the refactor
- recorded that `app_shell_smoke.gd` remained in CI but the local Windows headless launcher hung during this audit, so shell-scene regression still needs CI or interactive-editor confirmation before a broader tranche is closed

### Files Added Or Changed

- [`.github/workflows/godot-runtime.yml`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/.github/workflows/godot-runtime.yml)
- [`docs/MASTER-PLAN.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/MASTER-PLAN.md)
- [`docs/CONTINUATION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/CONTINUATION.md)
- [`docs/NEXT-20.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/NEXT-20.md)
- [`docs/SESSION-LOG.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/SESSION-LOG.md)
- [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- [`game/scripts/core/game_root_command_surface.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root_command_surface.gd)
- [`game/scripts/tests/command_surface_smoke.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/tests/command_surface_smoke.gd)

### Validation

- importer unit tests passed
- Godot headless systems smoke test completed without reported errors
- Godot headless command-surface smoke test completed without reported errors
- Godot headless spell smoke test completed without reported errors
- Godot headless transport smoke test completed without reported errors
- Godot headless taming smoke test completed without reported errors

### Outstanding

- extract mission snapshot or objective support from `GameRoot` as the next decomposition boundary
- rerun the full representative Godot suite from CI or a launcher path that reliably exercises `app_shell_smoke.gd`
