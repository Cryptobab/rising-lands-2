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

This repo is in `classic campaign AI coordination + shell polish slice` state.

What exists now:

- a new Godot project scaffold in [`game/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/game)
- importer tooling in [`tools/importers/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/tools/importers)
- planning and continuation docs in [`docs/`](/C:/Users/BAB/PROJECTS/Rising_land_remake/rising-lands-2/docs)
- playable Mission 1 through Mission 25 scenario maps with worker economy, mission-scoped and dynamically unlockable build palettes, expanded production buildings, defensive towers, research, combat, campaign progression, named save slots, runtime objectives, scripted mission events, reactive clan stances, clan trust/demand/revenge rules, ownership-transfer takeover scenarios, late-campaign prison/sanctuary relocation scenarios, enemy building production plans with rally, aggression, and target-priority hooks, full classic-campaign result flow, better RTS control UX, a real menu/HUD shell, command-card buttons, mission result flow, persistent shell options, a full mission board with locked/completed states, and a complete classic-campaign playable slice

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
- some missions now use diplomacy-count, exploration-area, build-in-area, and clear-hostiles objectives instead of only stockpile/build checks
- the available build palette is now mission-scoped, so early missions only expose the structures that scenario allows
- some missions can now unlock new build options mid-run through scripted events, and those runtime palette changes persist through save/load
- some missions can now drive enemy building production plans with rally points, aggression modes, pressure targets, and target priorities, and those runtime AI plans also persist through save/load
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
- Mission 7 now introduces sustained creature assaults tied to survival-plus-research progression
- Mission 8 now introduces an eastern-shore beachhead objective and sanctuary expansion across the channel
- Mission 9 now introduces reactive clan stance shifts and event-driven defeat pressure
- Mission 10 now introduces clan betrayal and full hostile-force clearance objectives
- Mission 11 now introduces swamp-crossing progression with tech and economy pressure
- Mission 12 now introduces breakout, northeastern sanctuary expansion, allied relief, and final counterattack scripting
- Mission 13 now introduces levy-based clan trust, messenger-gated alliance formation, and an eastern sanctuary race
- Mission 14 now introduces siege survival, secondary logistics objectives, and ridge-clan support or betrayal based on supply deadlines
- Mission 15 now introduces expansion-driven trust building, coalition support, and frontier-clearance pacing
- Mission 16 now introduces research-timed clan judgment, knowledge-driven alliance or revenge, and a combat-research victory mix
- Mission 17 now introduces a prison-break objective chain with latched escape/return progression before the counterattack
- Mission 18 now introduces hidden-site discovery, mid-mission Sanctuary unlocks, and sanctuary-reactivation pressure
- Mission 19 now introduces volcanic relocation and tribute-driven convoy support on the southeastern route
- Mission 20 now introduces treacherous route fortification, timed betrayal pressure, and another sanctuary relocation finale
- Mission 21 and Mission 22 now extend the final molten exodus with southeast sanctuary placement under hostile-clan pressure
- Mission 23 now introduces Great Library takeover scripting with building and unit ownership transfer
- Mission 24 now pushes a final southeast sanctuary rush under heavy enemy presence
- Mission 25 now delivers the final campaign annihilation battle and campaign-complete result flow
- the mission board now shows the full campaign instead of only unlocked missions, including locked/completed state, win-loss record, and best clear time
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
