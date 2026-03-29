# Rising Lands 2

Rising Lands 2 is a public fan remake of the 1997 RTS **Rising Lands**, with a second phase planned for expanded content, new tech trees, new units, and modern QoL.

The active implementation targets a professional `Godot 4` codebase for PC, using the original game files as reference data and import input.

## Active Direction

- Engine: `Godot 4`
- Language: typed `GDScript`
- Source data pipeline: `Python`
- Target platform: `PC`
- Repo model: public, code-first, no proprietary asset dump

## Current Status

This repo is in `mission systems slice` state.

What exists now:

- a new Godot project scaffold in [`game/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game)
- importer tooling in [`tools/importers/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/tools/importers)
- planning and continuation docs in [`docs/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs)
- a deterministic Mission 1 map with worker economy, expanded production buildings, defensive towers, research, combat, campaign progression, named save slots, runtime objectives, and scripted mission events

## Project Layout

- [`game/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game): active Godot project
- [`game/data/classic/raw/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/classic/raw): imported classic data snapshots
- [`game/data/expanded/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/data/expanded): new Rising Lands 2 content
- [`tools/importers/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/tools/importers): scripts that read the original files
- [`docs/MASTER-PLAN.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/MASTER-PLAN.md): main roadmap
- [`docs/CONTINUATION.md`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs/CONTINUATION.md): handoff notes for future sessions

## Setup

1. Install the current stable Godot 4 editor.
2. Open [`game/project.godot`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/project.godot).
3. Run the importer to refresh classic source data:

```powershell
python tools/importers/extract_classic_data.py `
  --source "C:\Users\BAB\PROJECTS\Rising_land_remake\Rising Lands Release" `
  --output "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game\data\classic"
```

This writes both:

- `game/data/classic/raw/`
- `game/data/classic/normalized/`

## Current Slice Controls

In the current Godot vertical slice:

- left click selects a worker, combat unit, or building
- right click on a resource assigns the selected worker to gather it
- right click with a selected combat unit issues move or attack orders
- builders can press `1` for `storehouse` build mode
- builders can press `2` for `culture` build mode
- builders can press `3` for `barracks` build mode
- builders can press `4` for `laboratory` build mode
- builders can press `5` for `library`, `6` for `sanctuary`, `7` for `workshop`, `8` for `garage`, and `9` for `hangar`
- builders can press `0` for `tower_catapult`, `-` for `tower_cannon`, and `=` for `wall`
- left click while in build mode places a construction site
- right click on a construction site assigns the selected builder to build it
- selected buildings use `Q/W/E/R/T/Y` for context actions
- `culture`, `barracks`, `sanctuary`, `workshop`, `garage`, and `hangar` now expose broader trainable rosters
- `library` and `laboratory` both support branch-based research
- `tower_catapult` and `tower_cannon` auto-fire on nearby enemies
- `F5` saves to `user://save_slot_1.json`
- `F6` saves the active named slot profile
- `F7` loads the active named slot profile
- `F9` loads from `user://save_slot_1.json`
- `Esc` clears build mode
- the HUD now shows campaign progress, the active save slot, objective progress, recent mission alerts, and selection detail

## Constraints

- Original executable, sprites, videos, sound banks, and binary assets are reference material, not assumed-safe repo content.
- Classic remake parity comes before expansion content.
- Expanded tech trees and new units should live in separate data layers from the classic ruleset.
