// ============================================================
//  units.js — All unit definitions from original Rising Lands
// ============================================================

/**
 * Unit roles:
 *   worker    - Gathers resources (Farmer, Builder, Mechanic)
 *   civilian  - Non-combat (Settler, Messenger)
 *   melee     - Close combat (Swordsman, Scorcher, Killer)
 *   ranged    - Distance attacker (Captain, Archer, Stomper)
 *   magic     - Spellcaster (Druid)
 *   vehicle   - Mechanical units (Speeder, Boomer, Reaper, Bomber, Hellfire)
 *   flying    - Air units (Heliped, Balloon)
 *   creature  - Wild animals (Spider, Ant, Basher, Raptor, Hurler, Bukka, Snapper)
 */

export const UnitDefs = {
  // ── COMBAT UNITS ──
  swordsman: {
    name: 'Swordsman', role: 'melee', icon: '⚔',
    vision: 7, range: 1, armor: 1, speed: 1.2,
    fatigue: 3000, recruitTime: 800,
    cost: { food: 6, stone: 0, parts: 0 },
    damage: { base: 20, vsBuilding: 2 },
    hunger: { rate: 0.01, max: 100 },
    desc: 'Basic melee infantry. Cheap and fast to recruit.'
  },
  scorcher: {
    name: 'Scorcher', role: 'melee', icon: '🔥',
    vision: 7, range: 1, armor: 2, speed: 1.0,
    fatigue: 3000, recruitTime: 1000,
    cost: { food: 5, stone: 1, parts: 0 },
    damage: { base: 40, vsBuilding: 15 },
    hunger: { rate: 0.012, max: 100 },
    desc: 'Fire warrior. High damage, good against structures.'
  },
  captain: {
    name: 'Captain', role: 'ranged', icon: '🎯',
    vision: 8, range: 8, armor: 2, speed: 1.0,
    fatigue: 3000, recruitTime: 1500,
    cost: { food: 10, stone: 3, parts: 0 },
    damage: { base: 25, vsBuilding: 5 },
    hunger: { rate: 0.01, max: 100 },
    aura: { type: 'damage', bonus: 2, radius: 4 },
    desc: 'Ranged commander. Boosts nearby unit damage by +2.'
  },
  killer: {
    name: 'Killer', role: 'melee', icon: '🐻',
    vision: 7, range: 4, armor: 3, speed: 1.1,
    fatigue: 3000, recruitTime: 1000,
    cost: { food: 10, stone: 2, parts: 0 },
    damage: { base: 40, vsBuilding: 3 },
    hunger: { rate: 0.015, max: 100 },
    desc: 'Combat bear. Heavy hitter, anti-infantry specialist.'
  },
  stomper: {
    name: 'Stomper', role: 'ranged', icon: '🦏',
    vision: 10, range: 8, armor: 3, speed: 0.8,
    fatigue: 3000, recruitTime: 1500,
    cost: { food: 15, stone: 5, parts: 0 },
    damage: { base: 50, vsBuilding: 5 },
    hunger: { rate: 0.02, max: 100 },
    desc: 'War rhino. Slow but devastating ranged attacks.'
  },
  archer: {
    name: 'Archer', role: 'ranged', icon: '🏹',
    vision: 10, range: 10, armor: 1, speed: 1.3,
    fatigue: 3000, recruitTime: 1000,
    cost: { food: 8, stone: 0, parts: 0 },
    damage: { base: 15, vsBuilding: 2 },
    hunger: { rate: 0.01, max: 100 },
    desc: 'Long-range scout. Best vision and range in the game.'
  },

  // ── MAGIC UNIT ──
  druid: {
    name: 'Druid', role: 'magic', icon: '🌿',
    vision: 5, range: 1, armor: 1, speed: 0.9,
    fatigue: 3000, recruitTime: 4000,
    cost: { food: 20, stone: 0, parts: 0 },
    damage: { base: 10, vsBuilding: 0 },
    hunger: { rate: 0.008, max: 100 },
    mana: { max: 20, regen: 0.02 },
    spells: ['vision', 'petrification', 'mirror', 'armour', 'nova'],
    desc: 'Spellcaster. Can learn 5 powerful spells through research.'
  },

  // ── WORKER UNITS ──
  farmer: {
    name: 'Farmer', role: 'worker', icon: '🌾',
    vision: 5, range: 1, armor: 0, speed: 1.0,
    fatigue: 3000, recruitTime: 500,
    cost: { food: 4, stone: 0, parts: 0 },
    damage: { base: 0, vsBuilding: 0 },
    hunger: { rate: 0.008, max: 100 },
    gathers: 'food', gatherSpeed: 250, carryCapacity: 1,
    desc: 'Gathers food from farms and vegetation.'
  },
  builder: {
    name: 'Builder', role: 'worker', icon: '🔨',
    vision: 5, range: 1, armor: 0, speed: 1.0,
    fatigue: 3000, recruitTime: 1000,
    cost: { food: 6, stone: 0, parts: 0 },
    damage: { base: 0, vsBuilding: 0 },
    hunger: { rate: 0.008, max: 100 },
    gathers: 'stone', gatherSpeed: 100, carryCapacity: 1,
    builds: true,
    desc: 'Constructs buildings and mines stone.'
  },
  mechanic: {
    name: 'Mechanic', role: 'worker', icon: '🔧',
    vision: 5, range: 1, armor: 0, speed: 1.0,
    fatigue: 3000, recruitTime: 800,
    cost: { food: 6, stone: 0, parts: 0 },
    damage: { base: 0, vsBuilding: 0 },
    hunger: { rate: 0.008, max: 100 },
    gathers: 'parts', gatherSpeed: 50, carryCapacity: 1,
    repairs: true,
    desc: 'Scavenges mechanical parts and repairs vehicles.'
  },

  // ── CIVILIAN UNITS ──
  settler: {
    name: 'Settler', role: 'civilian', icon: '🏕',
    vision: 5, range: 1, armor: 0, speed: 1.2,
    fatigue: 3000, recruitTime: 100,
    cost: { food: 2, stone: 0, parts: 0 },
    damage: { base: 0, vsBuilding: 0 },
    hunger: { rate: 0.008, max: 100 },
    desc: 'Colonist. Used to claim territory and populate buildings.'
  },
  messenger: {
    name: 'Messenger', role: 'civilian', icon: '📜',
    vision: 5, range: 1, armor: 0, speed: 1.8,
    fatigue: 3000, recruitTime: 150,
    cost: { food: 2, stone: 0, parts: 0 },
    damage: { base: 0, vsBuilding: 0 },
    hunger: { rate: 0.005, max: 100 },
    desc: 'Fast runner. Required to initiate trade and diplomacy.'
  },

  // ── VEHICLE UNITS ──
  speeder: {
    name: 'Speeder', role: 'vehicle', icon: '⚡',
    vision: 7, range: 4, armor: 3, speed: 1.6,
    fatigue: 3000, recruitTime: 1200,
    cost: { food: 8, stone: 0, parts: 4 },
    damage: { base: 30, vsBuilding: 3 },
    isVehicle: true,
    desc: 'Fast attack vehicle. Hit and run specialist.'
  },
  boomer: {
    name: 'Boomer', role: 'vehicle', icon: '💥',
    vision: 10, range: 10, armor: 3, speed: 0.6,
    fatigue: 3000, recruitTime: 2000,
    cost: { food: 10, stone: 0, parts: 5 },
    damage: { base: 10, vsBuilding: 5 },
    isVehicle: true,
    desc: 'Siege vehicle. Long range, effective against buildings.'
  },
  reaper: {
    name: 'Reaper', role: 'vehicle', icon: '🚜',
    vision: 5, range: 1, armor: 3, speed: 0.8,
    fatigue: 3000, recruitTime: 1500,
    cost: { food: 10, stone: 0, parts: 8 },
    damage: { base: 0, vsBuilding: 0 },
    isVehicle: true,
    gathers: 'food', gatherSpeed: 100, carryCapacity: 3,
    desc: 'Harvesting vehicle. Gathers food 3x faster than a farmer.'
  },
  bomber: {
    name: 'Bomber', role: 'vehicle', icon: '💣',
    vision: 5, range: 4, armor: 3, speed: 0.9,
    fatigue: 3000, recruitTime: 1500,
    cost: { food: 12, stone: 0, parts: 6 },
    damage: { base: 0, vsBuilding: 0 },
    isVehicle: true,
    placesMines: true,
    desc: 'Trap layer. Places explosive mines on the ground.'
  },
  hellfire: {
    name: 'Hellfire', role: 'vehicle', icon: '☀',
    vision: 8, range: 8, armor: 3, speed: 0.7,
    fatigue: 3000, recruitTime: 2000,
    cost: { food: 20, stone: 0, parts: 10 },
    damage: { base: 60, vsBuilding: 5 },
    isVehicle: true,
    desc: 'Ultimate war machine. Devastating damage output.'
  },

  // ── FLYING UNITS ──
  heliped: {
    name: 'Heliped', role: 'flying', icon: '🚁',
    vision: 5, range: 4, armor: 3, speed: 1.4,
    fatigue: 3000, recruitTime: 2500,
    cost: { food: 20, stone: 0, parts: 5 },
    damage: { base: 40, vsBuilding: 3 },
    isFlying: true,
    desc: 'Flying assault unit. Ignores terrain and walls.'
  },
  balloon: {
    name: 'Balloon', role: 'flying', icon: '🎈',
    vision: 10, range: 0, armor: 3, speed: 0.5,
    fatigue: 3000, recruitTime: 100,
    cost: { food: 20, stone: 0, parts: 20 },
    damage: { base: 0, vsBuilding: 0 },
    isFlying: true, isTransport: true, capacity: 4,
    desc: 'Flying transport. Carries up to 4 units over any terrain.'
  },
};

// ── CREATURE UNITS (wild/tameable) ──
export const CreatureDefs = {
  spider: {
    name: 'Spider', role: 'creature', icon: '🕷',
    vision: 10, range: 10, armor: 1, speed: 1.2,
    fatigue: 3000, damage: { base: 15, vsBuilding: 0 },
    aggressive: true
  },
  ant: {
    name: 'Ant', role: 'creature', icon: '🐜',
    vision: 10, range: 10, armor: 1, speed: 1.3,
    fatigue: 3000, damage: { base: 15, vsBuilding: 0 },
    aggressive: true
  },
  basher: {
    name: 'Basher', role: 'creature', icon: '🦍',
    vision: 7, range: 1, armor: 1, speed: 1.0,
    fatigue: 3000, damage: { base: 25, vsBuilding: 5 },
    aggressive: true
  },
  raptor: {
    name: 'Raptor', role: 'creature', icon: '🦎',
    vision: 7, range: 4, armor: 1, speed: 1.4,
    fatigue: 3000, damage: { base: 15, vsBuilding: 3 },
    aggressive: true
  },
  hurler: {
    name: 'Hurler', role: 'creature', icon: '🐗',
    vision: 8, range: 8, armor: 1, speed: 1.1,
    fatigue: 3000, damage: { base: 10, vsBuilding: 2 },
    aggressive: false
  },
  bukka: {
    name: 'Bukka', role: 'creature', icon: '👹',
    vision: 7, range: 6, armor: 1, speed: 1.0,
    fatigue: 3000, damage: { base: 8, vsBuilding: 2 },
    aggressive: false
  },
  snapper: {
    name: 'Snapper', role: 'creature', icon: '🐢',
    vision: 10, range: 10, armor: 1, speed: 0.5,
    fatigue: 3000, damage: { base: 5, vsBuilding: 0 },
    aggressive: false
  },
};
