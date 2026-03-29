# Rising Lands 2 — Project Plan

> A modern HTML5 Canvas remake of the 1997 RTS classic by Microïds.
> Pure JavaScript, zero dependencies, runs in any browser.

---

## Vision

Faithfully recreate the magic of Rising Lands with modern quality-of-life features, while keeping the soul of the original: the hunger system, persistent tech across missions, the four research paths, the post-apocalyptic tribal aesthetic, and the charming 90s RTS feel.

---

## Architecture Overview

```
rising-lands-2/
├── index.html              ← Single entry point
├── src/
│   ├── engine/
│   │   ├── canvas.js       ← Rendering pipeline, camera, zoom
│   │   ├── input.js        ← Mouse, keyboard, touch, selection box
│   │   ├── audio.js        ← Sound manager, music, SFX
│   │   ├── pathfinding.js  ← A* with terrain costs
│   │   ├── particles.js    ← Particle system for effects
│   │   └── tilemap.js      ← Isometric tilemap renderer
│   ├── game/
│   │   ├── world.js        ← Map generation, terrain, resources
│   │   ├── entities.js     ← Entity component system (units + buildings)
│   │   ├── combat.js       ← Damage calculation, projectiles, death
│   │   ├── resources.js    ← Gathering, storage, hunger system
│   │   ├── research.js     ← Tech tree with 4 branches
│   │   ├── buildings.js    ← Building placement, construction, training
│   │   ├── spells.js       ← Druid magic system
│   │   ├── diplomacy.js    ← Alliances, trading, market
│   │   └── missions.js     ← Campaign progression, objectives, persistence
│   ├── ai/
│   │   ├── controller.js   ← AI decision loop
│   │   ├── economy.js      ← AI resource management
│   │   ├── military.js     ← AI army composition & attacks
│   │   └── personality.js  ← AI difficulty & behavior profiles
│   ├── ui/
│   │   ├── hud.js          ← Top bar, resources, minimap
│   │   ├── panels.js       ← Selection info, command buttons
│   │   ├── menus.js        ← Main menu, settings, campaign select
│   │   ├── research-ui.js  ← Tech tree overlay
│   │   └── notifications.js← Toast messages, alerts
│   └── data/
│       ├── units.js        ← All unit definitions & stats
│       ├── buildings.js    ← All building definitions & stats
│       ├── tech-tree.js    ← Full research tree (4 branches)
│       ├── spells.js       ← Spell definitions
│       ├── missions.js     ← 25 campaign missions data
│       └── sprites.js      ← Procedural sprite generation
├── assets/
│   ├── sprites/            ← Extracted/recreated pixel art (future)
│   └── sounds/             ← Sound effects & music (future)
├── tools/
│   ├── map-editor.html     ← Browser-based map editor (Phase 4)
│   └── sprite-viewer.html  ← Preview/debug sprites
└── docs/
    ├── PROJECT-PLAN.md     ← This file
    ├── CHANGELOG.md        ← Version history
    └── ORIGINAL-DATA.md    ← Reference from original game files
```

---

## Development Phases

### Phase 1: Engine Foundation (Current Sprint)
**Goal:** Get a playable isometric world with basic interaction.

| Task | Priority | Status |
|------|----------|--------|
| Isometric tile renderer with camera pan/zoom | P0 | 🔨 |
| 7 terrain types with procedural sprites | P0 | 🔨 |
| Noise-based map generation | P0 | 🔨 |
| Entity system (position, health, owner) | P0 | |
| Mouse input: selection, box select, right-click commands | P0 | |
| A* pathfinding with terrain costs | P0 | |
| Minimap with camera viewport indicator | P1 | |
| Basic unit rendering (procedural pixel art) | P1 | |
| Keyboard shortcuts (WASD camera, hotkeys) | P1 | |
| Day/night cycle overlay | P2 | |

**Deliverable:** You can scroll around a generated map, select units, and move them.

---

### Phase 2: Core Gameplay Loop
**Goal:** Gather resources, build a base, train units, fight enemies.

| Task | Priority |
|------|----------|
| **Resources** | |
| 3 resource types: Food, Stone, Mechanical Parts | P0 |
| Resource nodes on map (berry bushes, stone deposits, scrap) | P0 |
| Farmer gathering loop (walk → harvest → carry → deposit) | P0 |
| Builder mining loop (walk → mine → carry → deposit) | P0 |
| Mechanic scavenging loop | P0 |
| Storage in Storehouse building | P0 |
| **Hunger System** (Rising Lands signature mechanic!) | |
| All bio units have a hunger counter | P0 |
| Hunger depletes over time when not garrisoned | P0 |
| Hungry units auto-seek nearest food source | P0 |
| Starvation damages health | P0 |
| **Buildings** | |
| Placement ghost + validity checking | P0 |
| Construction progress (builders work on it) | P0 |
| All 22 building types from original | P0 |
| Unit training queues from barracks/circus/etc. | P0 |
| Housing capacity (population limit) | P0 |
| **Combat** | |
| Melee attack (walk to target, swing, damage) | P0 |
| Ranged attack (projectile arc, travel time, hit) | P0 |
| Damage matrix (unit A vs unit B lookup table) | P0 |
| Armor/blindage system | P0 |
| Unit death with particle effects | P0 |
| Tower defense (catapult/cannon towers) | P1 |
| Walls and portcullis (gate) | P1 |
| Captain range bonus aura | P1 |

**Deliverable:** Full base-building + combat RTS gameplay loop.

---

### Phase 3: Tech Tree & Spells
**Goal:** Implement all 4 research branches and the magic system.

| Task | Priority |
|------|----------|
| **Research System** | |
| 4 branches: Agriculture, Military, Civil Engineering, Religious | P0 |
| Tech points generated over time (Library building) | P0 |
| Research UI overlay with unlock tree visualization | P0 |
| Unlocking new units/buildings/spells via research | P0 |
| Stat upgrades from research (damage, armor, speed, etc.) | P0 |
| ~81 total techs matching original game | P0 |
| **Spells** | |
| Druid unit as spellcaster | P0 |
| 5 spells: Vision, Petrification, Mirror, Armour, Nova | P0 |
| Mana system tied to Crystal buildings | P0 |
| Spell visual effects (particles, screen flash) | P1 |
| Fusion Temple special abilities | P1 |
| **Diplomacy & Trade** | |
| Alliance system (propose, accept, break) | P1 |
| Market building for resource trading | P1 |
| Messenger unit for initiating diplomacy | P1 |
| Trade ratios and market prices | P2 |

**Deliverable:** Deep strategic gameplay with tech choices and magic.

---

### Phase 4: Campaign & AI
**Goal:** 25-mission campaign with smart AI opponents.

| Task | Priority |
|------|----------|
| **Campaign** | |
| Mission loader with objectives | P0 |
| 25 missions with briefing text from original | P0 |
| Victory/defeat conditions per mission | P0 |
| **Persistent progression (key original feature!)** | |
| Tech carries over between missions | P0 |
| Diplomatic relationships persist | P0 |
| Mission-to-mission save state | P0 |
| **AI System** | |
| AI economy manager (build order, resource balance) | P0 |
| AI military (army composition, attack timing) | P0 |
| AI builder (base layout, expansion) | P0 |
| 3 AI difficulty levels (affects aggression + efficiency) | P0 |
| AI personality profiles (aggressive, defensive, economic) | P1 |
| AI adapts to player strategy | P2 |
| **Map Editor** | |
| Browser-based map editor tool | P1 |
| Place terrain, resources, starting positions | P1 |
| Save/load custom maps as JSON | P1 |
| Import maps from community | P2 |

**Deliverable:** Full campaign playable from mission 1 to 25.

---

### Phase 5: Polish & Modern Features
**Goal:** Quality-of-life features the original never had.

| Task | Priority |
|------|----------|
| **QoL** | |
| Control groups (Ctrl+1-9, recall with 1-9) | P0 |
| Rally points for buildings | P0 |
| Shift-queue commands (move, attack, patrol) | P0 |
| Unit formations | P1 |
| Waypoint visualization | P1 |
| Build queue management | P1 |
| Idle worker finder button | P0 |
| **Visuals** | |
| Improved procedural sprites with animation frames | P1 |
| Weather effects (rain, fog, sandstorm) | P2 |
| Improved particle effects for combat | P1 |
| Building destruction animations | P1 |
| Cutscene/briefing screens between missions | P2 |
| **Audio** | |
| Procedural/generated ambient sounds | P2 |
| Unit acknowledgement sounds | P2 |
| Combat sound effects | P1 |
| Background music system | P2 |
| **UI/UX** | |
| Settings panel (volume, speed, graphics) | P1 |
| Save/load game (localStorage) | P0 |
| Tooltips for everything | P1 |
| Tutorial mission (mission 0) | P1 |
| **Performance** | |
| Spatial hashing for entity lookup | P1 |
| Offscreen culling optimization | P0 |
| Web Worker for pathfinding | P2 |
| Object pooling for particles/projectiles | P1 |

**Deliverable:** A polished, modern-feeling RTS.

---

### Phase 6: Multiplayer & Community (Dream Phase)
**Goal:** Online play and community content.

| Task | Priority |
|------|----------|
| WebSocket-based multiplayer | P2 |
| Lobby system | P2 |
| Spectator mode | P3 |
| Community map sharing (JSON upload/download) | P2 |
| Mod support (custom unit/building definitions) | P2 |
| GitHub Pages hosting for instant play | P1 |
| Steam/itch.io release with Electron wrapper | P3 |

---

## Original Game Data Reference

### Units (18 player units + 7 creatures)

| Unit | Role | Range | Armor | Key Stat |
|------|------|-------|-------|----------|
| Swordsman | Basic melee | 1 | 1 | Cheap, fast to recruit |
| Scorcher | Fire melee | 1 | 2 | High AoE damage |
| Captain | Ranged commander | 8 | 2 | Buffs nearby units +2 |
| Killer | Heavy melee | 4 | 3 | Anti-infantry |
| Stomper (Rhino) | Heavy ranged | 8 | 3 | High HP, expensive |
| Druid | Spellcaster | 1 | 1 | Casts all 5 spells |
| Farmer | Gatherer | - | 0 | Gathers food |
| Builder | Constructor | - | 0 | Builds + mines stone |
| Mechanic | Engineer | - | 0 | Gathers mech parts |
| Archer | Ranged stealth | 10 | 1 | Long range, vision 10 |
| Settler | Colonist | - | 0 | Claims new territory |
| Messenger | Diplomat | - | 0 | Initiates trade |
| Speeder | Fast vehicle | 4 | 3 | Requires mech parts |
| Boomer | Siege vehicle | 10 | 3 | Anti-building |
| Reaper | Harvester vehicle | - | 3 | Auto-gathers |
| Bomber | Trap layer | 4 | 3 | Places mines |
| Hellfire | Ultimate unit | 8 | 3 | Massive damage |
| Heliped | Flying assault | 4 | 3 | Ignores terrain |
| Balloon | Flying transport | - | 3 | Carries units |

### Buildings (22 types)

| Building | Food | Stone | Housing | Purpose |
|----------|------|-------|---------|---------|
| Lighthouse | 12 | 4 | 2 | Vision tower |
| Barracks | 16 | 14 | 8 | Trains military |
| Sanctuary | 50 | 30 | 16 | Large housing |
| Storehouse | 10 | 6 | 2 | Resource storage |
| Culture | 12 | 6 | 5 | Farm fields |
| Workshop | 30 | 20 | 8 | Trains vehicles |
| Library | 20 | 20 | 3 | Generates tech pts |
| Laboratory | 24 | 12 | 2 | Research building |
| Hangar | 12 | 8 | 8 | Vehicle storage |
| Wall | 1 | 2 | 0 | Defense |
| Tower Catapult | 10 | 4 | 1 | Ranged defense |
| Tower Cannon | 20 | 6 | 2 | Ranged defense |
| Portcullis | 4 | 8 | 0 | Gate |
| Circus | 20 | 6 | 6 | Trains creatures |
| Garage | 24 | 16 | 4 | Repairs vehicles |
| Temple | 20 | 4 | 6 | Trains druids |
| Market | 12 | 8 | 2 | Trading |
| Crystal | 16 | 6 | 0 | Mana generation |
| Heliport | 20 | 8 | 4 | Air unit base |
| Hospital | 10 | 4 | 3 | Heals units |
| Fusion Temple | 20 | 4 | 6 | Advanced magic |
| Campaign Tent | 10 | 4 | 6 | Field base |

### Tech Tree (81 total researches)

- **Agriculture** (19): Farmer → Culture → Gather upgrades → Circus → Rhino → Reaper → Fatigue upgrades → Superior crops
- **Military** (20): Swordsman → Barracks → Scorcher → Towers → Archer → Speeder → Captain → Bomber → Boomer → Damage/range/armor upgrades
- **Civil Engineering** (24): Builder → Mechanic → Storehouse → Lab → Hangar → Market → Walls → Heliport → Hospital → Garage → Portcullis → Heliped → Build speed upgrades
- **Religious** (18): Druid → Temple → Library → Crystal → Vision → Petrification → Armour → Mirror → Nova → Hellfire → Fusion Temple → Magic upgrades

### Unique Mechanics to Preserve

1. **Hunger System** — Units get hungry, auto-seek food, starve if unfed
2. **Persistent Tech** — Research carries across campaign missions
3. **Persistent Diplomacy** — Alliances survive between missions
4. **4-Way Tech Choice** — Pick your research focus each mission
5. **Captain Aura** — Captain unit buffs nearby troops (+2 damage)
6. **Creature Taming** — Circus lets you recruit wild creatures
7. **Balloon Transport** — Fly units over terrain obstacles

---

## Milestones & Timeline

| Milestone | Description | Target |
|-----------|-------------|--------|
| v0.1.0 | Engine: Map renders, camera works, units move | Week 1-2 |
| v0.2.0 | Gameplay: Resources, building, basic combat | Week 3-5 |
| v0.3.0 | Strategy: Tech tree, all units/buildings, spells | Week 6-8 |
| v0.4.0 | Campaign: 25 missions, AI, persistence | Week 9-12 |
| v0.5.0 | Polish: QoL, save/load, map editor | Week 13-16 |
| v1.0.0 | Release: Full game playable on GitHub Pages | Week 17-20 |

---

## Contributing

This is an open-source fan project. The original Rising Lands was developed by Microïds (1997). This remake uses no original assets — all graphics are procedurally generated, all code is original.

**License:** MIT
