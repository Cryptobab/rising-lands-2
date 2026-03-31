# Continuation

## Snapshot

- Date: `2026-03-30`
- Repo: `C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2`
- Active engine: `Godot 4`
- Active language: typed `GDScript`
- Data tooling: `Python`
- Project state: `classic campaign baseline verified, hunger, first spell, transport, and taming slices landed, CI active, expanded mode still scaffold-only`

## Truth State

The current baseline is stronger than the old docs implied:

- the classic campaign has authored runtime coverage through Mission `25`
- campaign progression, shell flow, save slots, diplomacy carryover, enemy AI directives, and ruleset-safe persistence are live
- balloon and heliped transport now exists with boarding, unload, save/load persistence, and mission-area compatibility
- druid taming now exists for weakened creature units with allegiance transfer and save/load persistence
- the runtime is test-backed and boots locally in Godot

The current baseline is weaker than a full remake claim:

- full spell coverage, richer spell targeting, and spell presentation are still incomplete
- pathing and formation quality are still lightweight
- presentation, audio, and export automation are still missing
- expanded mode still contains only one internal mission and no real roster or tech content

## Verified In This Audit

Passed locally during this audit:

- importer unit tests
- `res://scripts/tests/hunger_smoke.gd`
- `res://scripts/tests/spell_smoke.gd`
- `res://scripts/tests/vertical_slice_smoke.gd`
- `res://scripts/tests/systems_smoke.gd`
- `res://scripts/tests/app_shell_smoke.gd`
- `res://scripts/tests/final_campaign_smoke.gd`
- `res://scripts/tests/enemy_ai_wave_directives_smoke.gd`
- `res://scripts/tests/ruleset_loader_smoke.gd`
- `res://scripts/tests/campaign_carryover_smoke.gd`
- `res://scripts/tests/transport_smoke.gd`
- `res://scripts/tests/taming_smoke.gd`

Notes:

- Godot version resolving locally is `4.6.1`
- a single-command run of all smoke tests exceeded the shell timeout, so broad regression should be rerun in deliberate batches or from CI
- `.github/workflows/godot-runtime.yml` now covers the representative Godot smoke batch alongside the existing Python importer workflow

## Where To Work Next

Primary lane:

1. runtime decomposition and polish
2. export automation and manual validation discipline
3. broader spell depth and classic mission usage
4. expanded ruleset seeding
5. expanded-mode-specific new tech after the first seeded slice is coherent

Do not start a public expanded-mode push before items `1` and `2` are honest in the classic remake.

## Autonomous Continuation Pattern

Use this loop for each feature tranche:

1. Pick the highest unfinished item from [`docs/NEXT-20.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/NEXT-20.md).
2. Inspect current hooks in `GameRoot`, `WorldState`, the relevant unit or building state classes, and the normalized data records.
3. Implement the smallest honest end-to-end slice of the feature in runtime code.
4. Add or extend a Godot smoke test that proves the feature works and persists.
5. Run importer tests plus the new targeted smoke and the representative runtime suite.
6. Update `MASTER-PLAN`, `CONTINUATION`, `NEXT-20`, and `SESSION-LOG` if the truth state changed.
7. Only move to the next backlog item after the tranche is passing and documented.

## Feature Order With Rationale

### 1. Runtime Decomposition And Alpha Polish

Why next:

- `game/scripts/core/game_root.gd` is now carrying multiple completed systems and needs cleaner slice boundaries before more features pile on
- command clarity, movement quality, and selected-unit feedback are the next biggest gains for actual playability

Minimum acceptable implementation:

- extract at least one real runtime responsibility out of `GameRoot`
- preserve save compatibility while doing so
- improve one concrete playability surface such as selection clarity, unit state feedback, or movement readability
- smoke coverage

### 2. Tooling And Shipping

- keep the Godot runtime CI batch healthy as the representative suite changes
- define export steps and reproducible build commands
- add a short manual interactive checklist for editor validation

### 3. Expanded Ruleset Seeding

Only once the classic parity lane is honest:

- add the first real expanded units, buildings, techs, and spells
- keep expanded missions clearly labeled as proving-ground or alpha content until they are coherent

## Important Files

- roadmap: [`docs/MASTER-PLAN.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/MASTER-PLAN.md)
- active tranche: [`docs/NEXT-20.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/NEXT-20.md)
- session trace: [`docs/SESSION-LOG.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/SESSION-LOG.md)
- runtime entry: [`game/scripts/core/game_root.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/game_root.gd)
- world state: [`game/scripts/core/world_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/world_state.gd)
- mission runtime: [`game/scripts/core/mission_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/core/mission_state.gd)
- shell runtime: [`game/scripts/ui/app_shell.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/ui/app_shell.gd)
- worker runtime: [`game/scripts/simulation/worker_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/worker_unit_state.gd)
- combat runtime: [`game/scripts/simulation/combat_unit_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/combat_unit_state.gd)
- building runtime: [`game/scripts/simulation/building_state.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/simulation/building_state.gd)
- ruleset loader: [`game/scripts/data/ruleset_database.gd`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scripts/data/ruleset_database.gd)
- classic data manifest: [`game/data/classic/normalized/manifest.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/normalized/manifest.json)
- expanded data manifest: [`game/data/expanded/normalized/manifest.json`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded/normalized/manifest.json)

## Validation Commands

Run importer tests:

```powershell
python -m unittest discover `
  -s C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\tools\importers\tests `
  -p "test_*.py"
```

Run the representative Godot suite:

```powershell
$godot = "C:\Users\BAB\AppData\Local\Microsoft\WinGet\Links\godot.exe"
$game = "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game"

& $godot --headless --path $game --script res://scripts/tests/systems_smoke.gd
& $godot --headless --path $game --script res://scripts/tests/app_shell_smoke.gd
& $godot --headless --path $game --script res://scripts/tests/final_campaign_smoke.gd
& $godot --headless --path $game --script res://scripts/tests/enemy_ai_wave_directives_smoke.gd
& $godot --headless --path $game --script res://scripts/tests/ruleset_loader_smoke.gd
& $godot --headless --path $game --script res://scripts/tests/campaign_carryover_smoke.gd
& $godot --headless --path $game --script res://scripts/tests/hunger_smoke.gd
& $godot --headless --path $game --script res://scripts/tests/spell_smoke.gd
& $godot --headless --path $game --script res://scripts/tests/transport_smoke.gd
& $godot --headless --path $game --script res://scripts/tests/taming_smoke.gd
```

## Stop Conditions

Pause and reassess if any of the following happens:

- a parity feature requires a save-schema break without a migration plan
- expansion work starts leaking into classic data or classic saves
- a refactor touches unrelated runtime areas without new test coverage
- a feature exists only in data or UI text but not in actual gameplay behavior
