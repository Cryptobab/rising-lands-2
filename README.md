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

This repo is in `campaign content chapter-two slice` state.

What exists now:

- a new Godot project scaffold in [`game/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game)
- importer tooling in [`tools/importers/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/tools/importers)
- planning and continuation docs in [`docs/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs)
- playable Mission 1 through Mission 6 scenario maps with worker economy, mission-scoped build palettes, expanded production buildings, defensive towers, research, combat, campaign progression, named save slots, runtime objectives, scripted mission events, first-pass diplomacy, better RTS control UX, a real menu/HUD shell, command-card buttons, mission result flow, persistent shell options, chapter-two exploration objectives, and stronger enemy assault behavior

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
3. The game now boots into the shell scene in [`game/scenes/main.tscn`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game/scenes/main.tscn), which hosts the mission board, result panel, save-slot panel, options panel, and in-game HUD on top of the RTS runtime.
4. Run the importer to refresh classic source data:

```powershell
python tools/importers/extract_classic_data.py `
  --source "C:\Users\BAB\PROJECTS\Rising_land_remake\Rising Lands Release" `
  --output "C:\Users\BAB\PROJECTS\Rising_land_remake\rising-lands-2\game\data\classic"
```

This writes both:

- `game/data/classic/raw/`
- `game/data/classic/normalized/`

## Current Slice Controls

In the current Godot shell:

- the main menu opens on boot with a mission board, save-slot controls, and the current briefing
- `Start Campaign` launches Mission 1, `Continue Active Session` resumes the active slot when present, and the mission board can launch any unlocked mission directly
- left click selects a worker, combat unit, building, or construction site
- left click drag box-selects groups of player units
- right click on a resource assigns the selected worker to gather it
- right click with selected units issues grouped move, attack, build, gather, or diplomacy orders
- right click with a selected `messenger` on a clan marker sends it to negotiate
- builders can press `1` for `storehouse` build mode
- builders can press `2` for `culture` build mode
- builders can press `3` for `barracks` build mode
- builders can press `4` for `laboratory` build mode
- builders can press `5` for `library`, `6` for `sanctuary`, `7` for `workshop`, `8` for `garage`, and `9` for `hangar`
- builders can press `M` for `market`
- builders can press `0` for `tower_catapult`, `-` for `tower_cannon`, and `=` for `wall`
- left click while in build mode places a construction site
- right click on a construction site assigns the selected builder to build it
- selected buildings use `Q/W/E/R/T/Y` for context actions
- selected production and research buildings now expose clickable command-card buttons in the right HUD panel
- some missions now use diplomacy-count and area-exploration objectives instead of only stockpile/build checks
- the available build palette is now mission-scoped, so early missions only expose the structures that scenario allows
- `culture`, `barracks`, `sanctuary`, `workshop`, `garage`, and `hangar` now expose broader trainable rosters
- `market` now trains `messenger` for diplomacy scenarios
- `library` and `laboratory` both support branch-based research
- `tower_catapult` and `tower_cannon` auto-fire on nearby enemies
- worker move orders now hold position properly instead of collapsing straight back into auto-gather
- move, gather, build, attack, and diplomacy orders now create visible command markers
- a minimap overlay now shows terrain, resources, buildings, units, enemies, and diplomacy targets
- the in-game HUD now has a top command bar, left objective/alert stack, right selection/command card, and bottom command surface
- mission victory and defeat now surface a result panel in the shell with `Retry Mission` and `Next Mission` flow
- the `Menu`, `Save Slot`, `Load Slot`, and `Restart` buttons are now available in the top HUD bar
- the shell `Options` panel can now toggle enemy pressure and whether opening the menu pauses the simulation
- shell options persist in `user://shell_settings.json`
- Mission 5 now introduces multi-clan diplomacy pressure and hostile raider waves
- Mission 6 now introduces a mine-exploration objective, scripted guardian wave scheduling, and chapter-two spiritual research flow
- `F5` saves to `user://save_slot_1.json`
- `F6` saves the active named slot profile
- `F7` loads the active named slot profile
- `F9` loads from `user://save_slot_1.json`
- `Esc` clears build mode
- the shell HUD now shows campaign progress, the active save slot, objective progress, alliance count, recent mission alerts, and selection detail

## Constraints

- Original executable, sprites, videos, sound banks, and binary assets are reference material, not assumed-safe repo content.
- Classic remake parity comes before expansion content.
- Expanded tech trees and new units should live in separate data layers from the classic ruleset.
