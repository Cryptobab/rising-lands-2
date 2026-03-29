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

### Files Added Or Changed

- [`README.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/README.md)
- [`docs/MASTER-PLAN.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/MASTER-PLAN.md)
- [`docs/ENGINE-DECISION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/ENGINE-DECISION.md)
- [`docs/CONTINUATION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/CONTINUATION.md)
- [`game/project.godot`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/project.godot)
- [`game/scenes/main.tscn`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scenes/main.tscn)
- [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- [`game/scripts/core/world_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/world_state.gd)
- [`game/scripts/core/campaign_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/campaign_state.gd)
- [`game/scripts/core/mission_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/mission_state.gd)
- [`game/scripts/core/mission_event_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/mission_event_state.gd)
- [`game/scripts/core/diplomacy_target_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/diplomacy_target_state.gd)
- [`game/scripts/core/map_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/map_state.gd)
- [`game/scripts/data/classic_database.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/data/classic_database.gd)
- [`game/scripts/simulation/worker_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/worker_unit_state.gd)
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
- [`game/data/classic/vertical_slice/mission_001_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/mission_001_map.json)
- [`game/data/classic/vertical_slice/monde02_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde02_map.json)
- [`game/data/classic/vertical_slice/monde03_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde03_map.json)
- [`game/data/classic/vertical_slice/monde04_map.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/vertical_slice/monde04_map.json)
- [`tools/importers/extract_classic_data.py`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/tools/importers/extract_classic_data.py)
- [`tools/importers/tests/test_extract_classic_data.py`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/tools/importers/tests/test_extract_classic_data.py)

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

### Outstanding

- validate the project in the interactive Godot editor
- extend the current command-UX campaign slice into broader content parity, campaign flow, and stronger menu/UI shells
