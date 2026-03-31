# Rising Lands 2 Master Plan

This document is the source of truth for what is actually done, what is still missing, and what order the revamp should follow.

## Audit Snapshot

As of `2026-03-30`, the project is no longer a rewrite bootstrap. The classic Godot baseline is real and test-backed, but the remake is not yet feature-complete and the expansion lane is still only a scaffold.

Verified in this audit:

- importer unit tests passed
- Godot `4.6.1` resolves locally and runs headless
- representative Godot smoke tests passed: `taming_smoke`, `transport_smoke`, `hunger_smoke`, `spell_smoke`, `vertical_slice_smoke`, `systems_smoke`, `app_shell_smoke`, `final_campaign_smoke`, `enemy_ai_wave_directives_smoke`, `ruleset_loader_smoke`, and `campaign_carryover_smoke`

Current data truth:

- `classic` normalized data contains `26` units, `22` buildings, `5` spells, `81` techs, and `25` missions
- `expanded` normalized data contains `0` units, `0` buildings, `0` spells, `0` techs, and `1` internal proving-ground mission
- the repo contains `33` Godot smoke tests, but the entire sweep was not rerun in one shell command during this audit because the long batch exceeded the command timeout

## What Is Done

### Engine And Data Foundation

- the browser prototype is retired and the active runtime is `Godot 4`
- importer tooling exists in `Python` and exports classic `raw` plus `normalized` JSON
- classic and expanded rulesets are separated at the data level
- a neutral `RulesetDatabase` loader exists and saves/profiles now carry explicit `ruleset_id`

### Classic Runtime Baseline

- the project boots into a real shell scene instead of a debug bootstrap
- worker economy, construction, production queues, research queues, combat, towers, and save/load exist
- a first hunger loop now exists with ration consumption, starvation pressure, shell visibility, save persistence, and automated smoke coverage
- a first druid spell slice now exists with command-card and hotkey casting, mana and cooldowns, persistent spell effects, and automated smoke coverage
- a first transport slice now exists for `balloon` and `heliped` with boarding, unload actions, save persistence, and mission-objective compatibility
- a first taming slice now exists where druids can convert weakened creature units into the player roster with save persistence and automated smoke coverage
- mission objectives and mission events are data-driven and persist through save/load
- diplomacy now covers alliances, stance, trust, demands, and revenge state
- campaign progression, named save slots, campaign completion, and campaign carryover all exist
- all `25` classic campaign missions have authored scenario map coverage
- enemy pressure supports authored production plans, rally behavior, aggression modes, target priorities, and scheduled waves

### UI And Playable Shell

- the shell includes a mission board, briefing surface, result panel, save-slot panel, options, and in-game HUD
- grouped selection, right-click orders, build placement, command markers, minimap feedback, and command-card buttons exist
- shell settings persist, and campaign framing is visible in both the board and result flow

### Validation And Workflow

- importer unit tests exist and pass locally
- `33` Godot smoke tests exist across economy, construction, systems, missions, diplomacy, shell flow, AI, ruleset loading, transport, taming, and campaign carryover
- GitHub issue templates and PR template exist
- GitHub Actions now covers importer tests plus a representative Godot runtime smoke suite

## What Is Not Done

### Classic Parity Blockers

These are the main reasons the project cannot yet claim a complete remake revamp:

- only a first spell slice exists, so broader spell coverage, richer targeting, and presentation are still incomplete
- many units are present only as generic combat actors rather than fully differentiated unit behaviors
- movement is still simple direct steering, not full RTS-grade pathfinding, avoidance, terrain handling, or formation logic
- there is no fog-of-war or visibility gameplay layer beyond local attack vision checks
- the classic baseline still needs honest balance work and longer interactive play validation

### Production And Tech Blockers

- `game/scripts/core/game_root.gd` is carrying too much orchestration and should be split as the runtime deepens
- there is no export pipeline, release automation, or public build packaging
- there is effectively no committed art, animation, VFX, or audio production layer beyond code-driven placeholders and the icon
- key UX improvements such as richer command queueing, better selection ergonomics, and more informative combat feedback are still unfinished

### Expansion And New-Tech Blockers

- the expanded ruleset is only a loader proof and not yet a real playable mode
- expanded data currently has no actual units, buildings, tech branches, or spells
- there is no implemented expansion economy, progression, roster identity, or mission arc
- the "new tech" vision is still design intent, not runtime content

## Delivery Order

The project should now move in five phases.

### Phase 0: Foundation Lock

Status: `done`

Outcome:

- Godot rewrite established
- importer and normalized data pipeline established
- classic shell, campaign flow, save system, diplomacy framework, and ruleset-safe persistence established

### Phase 1: Classic Parity Gap Closure

Status: `done`

Goal:

- finish the remaining signature classic systems that are still missing from the runtime

Deliverables:

- hunger pressure in live gameplay
- first druid spell support in live gameplay
- balloon and heliped transport flow
- creature taming or equivalent creature-control runtime
- save/load and smoke coverage for each of the above

Exit criteria:

- every preserved pillar named in the project brief exists in live gameplay, not only in data
- the classic campaign can use those systems without bespoke hacks
- the representative smoke suite plus the new feature tests all pass

### Phase 2: Classic Alpha Polish And Runtime Decomposition

Status: `active`

Goal:

- make the classic remake stable, understandable, and shippable as an alpha instead of merely technically complete

Deliverables:

- split `GameRoot` responsibilities into smaller runtime services
- improve command queueing, feedback, selection clarity, and combat readability
- add better pathing or avoidance, terrain-aware movement, and formation handling where needed
- keep the new Godot smoke-test CI healthy and add a repeatable export path
- perform manual campaign pass for pacing, difficulty, and regression discovery

Exit criteria:

- the runtime is no longer anchored around one oversized orchestration file
- the classic campaign is both test-backed and manually playable end-to-end
- automated workflows cover both Python tooling and representative Godot runtime checks

### Phase 3: Expanded Ruleset Foundation

Status: `pending`

Goal:

- turn the expanded lane from a loader proof into an actual playable slice

Deliverables:

- first real expanded roster entries
- first real expanded buildings
- first real expanded tech branches
- first real expanded spell or support systems
- one honest playable expanded proving-ground mission

Exit criteria:

- the expanded ruleset has non-zero runtime content across units, buildings, tech, and mission flow
- the shell can load classic and expanded content without pretending both are equally complete

### Phase 4: Expanded Mode And New Technology

Status: `pending`

Goal:

- deliver the actual "Rising Lands 2" value: new tech, new mission structures, new systems, and modernized RTS depth

Deliverables:

- new tech branches such as `Salvage Engineering`, `Beast Mastery`, and `Solar Mysticism`
- new units, buildings, and support abilities tied to those branches
- expansion missions that rely on systems not present in the classic campaign
- new QoL systems justified by the expansion ruleset, not bolted randomly onto the remake

Exit criteria:

- there is a coherent player-facing expanded mode rather than a hidden data stub
- the expansion meaningfully differentiates itself from the classic remake

### Phase 5: Shipping Discipline

Status: `pending`

Goal:

- make release and continuation sustainable

Deliverables:

- build and release automation
- save-version migration discipline
- public demo packaging
- milestone-based regression checklists
- contributor-facing technical docs for the modularized runtime

Exit criteria:

- another session can continue work without rediscovering architecture or manual test steps
- milestone builds can be reproduced without local tribal knowledge

## Immediate Priorities

The current execution order should be:

1. Runtime decomposition and classic alpha polish
2. Export automation and manual validation discipline
3. Broader spell depth and clearer unit differentiation on top of the now-live parity systems
4. Expanded ruleset content seeding
5. Expanded-mode-specific new tech only after the first seeded slice is coherent

## Autonomous Working Rules

- stay in the `classic parity` lane until the missing signature systems are live
- do not market data-only presence as a finished gameplay feature
- finish one feature end-to-end before starting the next one
- every feature tranche must include runtime code, test coverage, validation, and doc updates
- keep `classic` and `expanded` strictly separated at the data and persistence layer
- when a system needs refactoring, refactor only the slice being touched instead of pausing delivery for a giant rewrite
- prefer representative smoke batches during active iteration, then rerun the broader suite in deliberate batches before closing a tranche

## Non-Negotiables

- no copyrighted original binaries or asset dumps in the public repo
- no pretending the expanded lane is public-ready while classic alpha polish and export discipline remain unfinished
- no claiming feature completion without runtime behavior, save/load coverage, and at least one automated check
