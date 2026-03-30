# Rising Lands 2 Master Plan

This document is the working source of truth for the project.

The target is a professional PC remake first, then a larger "Rising Lands 2" expansion after the remake loop is stable.

## Engine Decision

The project is moving to `Godot 4` as the main game engine.

Reasons:

- strong 2D workflow for tilemaps, navigation, physics, particles, and editor tooling
- much better long-term structure than a single-file browser prototype
- good fit for a public repo and solo/small-team iteration
- no need to carry the overhead of Unreal for a 2D RTS
- cleaner public-repo posture than basing the whole project around Unity licensing risk

Current scripting choice:

- typed `GDScript`

Supporting tools:

- `Python` for data importers and extraction scripts
- GitHub for issues, PRs, releases, and public demo process

## Product Direction

The game should be built in two lanes:

1. `Classic Remake`
Faithful reconstruction of the original game loop and campaign identity.

2. `Expanded Mode`
New units, tech trees, missions, rulesets, and QoL after the classic layer is solid.

Do not mix those lanes too early. RTS scope expands very fast.

## Core Features To Preserve

- hunger system
- persistent research across campaign missions
- persistent diplomacy
- four-branch tech structure
- creature taming
- balloon transport
- campaign progression across 25 missions

## Current Repo Reality

As of 2026-03-29:

- the old web prototype has been retired from the canonical branch
- a new Godot rewrite scaffold has been created
- importer tooling now starts from the original game files
- classic and expanded data are being split from the start
- explicit ruleset-aware loading now exists through per-ruleset manifests, neutral database plumbing, and ruleset-safe save/profile payloads

What still does not exist:

- production gameplay loop in the new engine
- campaign runtime
- AI
- save system
- polished UI
- CI and release automation

## Repo Structure

Target structure:

```text
rising-lands-2/
├── game/
│   ├── project.godot
│   ├── scenes/
│   ├── scripts/
│   └── data/
│       ├── classic/
│       └── expanded/
├── tools/
│   └── importers/
├── docs/
└── .github/
```

## Content Pipeline

Primary reference source:

- `C:\Users\BAB\PROJECTS\Rising_land_remake\Rising Lands Release`

Important text sources:

- `RISING.INI`
- `MONSTRE.INI`
- `TEXTES.TXT`
- `WORLD\MONDE*.TXT`

Pipeline rule:

1. import raw classic data
2. normalize it into game-ready structures
3. keep expanded content separate from classic imported data
4. document intentional balance or design deviations

## Architecture Rules

1. `Simulation first.`
Rules, state transitions, and campaign persistence matter more than effects polish.

2. `Data-driven content.`
Units, buildings, spells, tech trees, missions, and balance should not be buried in scene scripts.

3. `Classic and expanded content stay separated.`
The remake baseline must remain testable without expansion noise.

3a. `Ruleset identity must be explicit.`
Runtime bootstrap, mission lookup, shell snapshots, and persistence payloads should carry `ruleset_id` instead of inferring mode from ad hoc paths or flags.

4. `Version saved data.`
Campaign carry-over will become fragile fast without explicit save versions.

5. `Keep proprietary binaries out of the public repo.`
Reference them, parse them, document them, but do not dump them into shipping source.

## Milestones

### Milestone 0: Rewrite Bootstrap

Deliverables:

- Godot project scaffold
- importer scripts
- honest docs
- repo workflow standards
- clear classic vs expanded split

### Milestone 1: Vertical Slice

Deliver one real playable scenario with:

- deterministic handcrafted test map
- food and stone economy
- hunger loop
- 4 to 6 units
- 4 to 6 buildings
- melee and ranged combat
- objective and fail state

### Milestone 2: Classic Runtime Core

Deliver:

- worker jobs
- construction jobs
- production queues
- research runtime
- spell runtime
- save/load

### Milestone 3: Campaign Framework

Deliver:

- mission loading
- briefing pipeline
- persistent tech state
- persistent diplomacy state
- several migrated missions proving the pipeline

### Milestone 4: Classic Campaign Alpha

Deliver:

- all 25 missions playable
- AI economy and attack loops
- balance pass
- public alpha build

### Milestone 5: Rising Lands 2 Expansion

Deliver:

- new tech branches
- new units and buildings
- alternate missions and skirmish
- modern QoL feature set

## First Expansion Themes

Recommended first expansion branches:

- `Salvage Engineering`
- `Beast Mastery`
- `Solar Mysticism`

Those should be layered on top of a stable classic ruleset, not mixed into the remake prematurely.

## Immediate Backlog

1. Open the Godot project and validate the new scaffold.
2. Expand the importer into normalized unit/building/tech assets.
3. Replace placeholder scene logic with map, entity, and command systems.
4. Build the first deterministic vertical-slice mission.
5. Add save schema and campaign-state objects early.

## Non-Negotiables

- Do not market stubbed systems as finished systems.
- Do not let expansion content derail classic parity.
- Do not mix source-of-truth gameplay values across random scripts.
- Do not commit original copyrighted art, video, sound, or binaries without rights.
