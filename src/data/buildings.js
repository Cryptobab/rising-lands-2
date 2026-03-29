// ============================================================
//  buildings.js — All building definitions from Rising Lands
// ============================================================

export const BuildingDefs = {
  headquarters: {
    name: 'Headquarters', icon: '🏰',
    size: { w: 2, h: 2 }, spriteH: 28,
    buildTime: 0, // Pre-placed
    cost: { food: 0, stone: 0, parts: 0 },
    housing: 10, hp: 500,
    trains: ['farmer', 'builder', 'mechanic', 'settler', 'messenger'],
    desc: 'Your main base. Trains basic workers and civilians.'
  },
  barracks: {
    name: 'Barracks', icon: '⚔',
    size: { w: 2, h: 2 }, spriteH: 22,
    buildTime: 400,
    cost: { food: 16, stone: 14, parts: 0 },
    housing: 8, hp: 300,
    trains: ['swordsman', 'scorcher', 'killer', 'captain', 'archer', 'stomper'],
    research: 'military',
    desc: 'Trains military units. Unlocks more through Military research.'
  },
  sanctuary: {
    name: 'Sanctuary', icon: '🏛',
    size: { w: 2, h: 2 }, spriteH: 24,
    buildTime: 600,
    cost: { food: 50, stone: 30, parts: 0 },
    housing: 16, hp: 400,
    desc: 'Large housing structure. Supports 16 population.'
  },
  storehouse: {
    name: 'Storehouse', icon: '📦',
    size: { w: 1, h: 1 }, spriteH: 14,
    buildTime: 100,
    cost: { food: 10, stone: 6, parts: 0 },
    housing: 2, hp: 200,
    storage: { food: 200, stone: 200, parts: 100 },
    desc: 'Stores gathered resources. Workers deliver here.'
  },
  culture: {
    name: 'Culture', icon: '🌿',
    size: { w: 2, h: 1 }, spriteH: 6,
    buildTime: 200,
    cost: { food: 12, stone: 6, parts: 0 },
    housing: 5, hp: 100,
    farm: true, farmYield: 1.0,
    desc: 'Farm field. Farmers gather food from these.'
  },
  workshop: {
    name: 'Workshop', icon: '🔩',
    size: { w: 2, h: 2 }, spriteH: 20,
    buildTime: 300,
    cost: { food: 30, stone: 20, parts: 0 },
    housing: 8, hp: 250,
    trains: ['speeder', 'boomer', 'reaper', 'bomber', 'hellfire'],
    research: 'engineering',
    desc: 'Builds vehicles. Requires mechanical parts.'
  },
  library: {
    name: 'Library', icon: '📚',
    size: { w: 1, h: 1 }, spriteH: 18,
    buildTime: 500,
    cost: { food: 20, stone: 20, parts: 0 },
    housing: 3, hp: 200,
    techPointsPerTick: 0.5,
    desc: 'Generates technology points for research.'
  },
  laboratory: {
    name: 'Laboratory', icon: '🔬',
    size: { w: 1, h: 1 }, spriteH: 16,
    buildTime: 400,
    cost: { food: 24, stone: 12, parts: 0 },
    housing: 2, hp: 200,
    research: 'all',
    desc: 'Enables research. Required for the tech tree.'
  },
  hangar: {
    name: 'Hangar', icon: '🏗',
    size: { w: 2, h: 2 }, spriteH: 16,
    buildTime: 500,
    cost: { food: 12, stone: 8, parts: 0 },
    housing: 8, hp: 250,
    vehicleStorage: 4,
    desc: 'Stores and shelters vehicles.'
  },
  wall: {
    name: 'Wall', icon: '🧱',
    size: { w: 1, h: 1 }, spriteH: 8,
    buildTime: 15,
    cost: { food: 1, stone: 2, parts: 0 },
    housing: 0, hp: 150,
    isWall: true,
    desc: 'Defensive wall segment. Blocks unit movement.'
  },
  towerCatapult: {
    name: 'Tower Catapult', icon: '🏰',
    size: { w: 1, h: 1 }, spriteH: 24,
    buildTime: 50,
    cost: { food: 10, stone: 4, parts: 0 },
    housing: 1, hp: 200,
    attack: { damage: 25, range: 10, reload: 50 },
    desc: 'Defensive tower with catapult. Effective against units.'
  },
  towerCannon: {
    name: 'Tower Cannon', icon: '💨',
    size: { w: 1, h: 1 }, spriteH: 24,
    buildTime: 100,
    cost: { food: 20, stone: 6, parts: 0 },
    housing: 2, hp: 250,
    attack: { damage: 15, range: 10, reload: 100 },
    desc: 'Defensive cannon tower. Steady damage output.'
  },
  portcullis: {
    name: 'Portcullis', icon: '🚪',
    size: { w: 1, h: 1 }, spriteH: 10,
    buildTime: 60,
    cost: { food: 4, stone: 8, parts: 0 },
    housing: 0, hp: 200,
    isGate: true,
    desc: 'Gate in walls. Allies pass through, enemies blocked.'
  },
  circus: {
    name: 'Circus', icon: '🎪',
    size: { w: 2, h: 2 }, spriteH: 20,
    buildTime: 350,
    cost: { food: 20, stone: 6, parts: 0 },
    housing: 6, hp: 200,
    trains: ['killer', 'stomper'],
    desc: 'Tames wild creatures for combat. Trains Killers and Stompers.'
  },
  garage: {
    name: 'Garage', icon: '🔧',
    size: { w: 2, h: 1 }, spriteH: 14,
    buildTime: 350,
    cost: { food: 24, stone: 16, parts: 0 },
    housing: 4, hp: 250,
    repairsVehicles: true,
    desc: 'Automatically repairs nearby damaged vehicles.'
  },
  temple: {
    name: 'Temple', icon: '⛪',
    size: { w: 2, h: 2 }, spriteH: 26,
    buildTime: 400,
    cost: { food: 20, stone: 4, parts: 0 },
    housing: 6, hp: 300,
    trains: ['druid'],
    research: 'religious',
    desc: 'Trains Druids. Enables Religious research branch.'
  },
  market: {
    name: 'Market', icon: '🏪',
    size: { w: 2, h: 1 }, spriteH: 12,
    buildTime: 300,
    cost: { food: 12, stone: 8, parts: 0 },
    housing: 2, hp: 150,
    enablesTrade: true,
    desc: 'Enables resource trading with other players and AI.'
  },
  crystal: {
    name: 'Crystal', icon: '💎',
    size: { w: 1, h: 1 }, spriteH: 20,
    buildTime: 300,
    cost: { food: 16, stone: 6, parts: 0 },
    housing: 0, hp: 200,
    manaPerTick: 0.1,
    desc: 'Generates mana for Druid spells.'
  },
  heliport: {
    name: 'Heliport', icon: '🛬',
    size: { w: 2, h: 2 }, spriteH: 10,
    buildTime: 300,
    cost: { food: 20, stone: 8, parts: 0 },
    housing: 4, hp: 200,
    trains: ['heliped', 'balloon'],
    desc: 'Builds and launches flying units.'
  },
  hospital: {
    name: 'Hospital', icon: '🏥',
    size: { w: 1, h: 1 }, spriteH: 16,
    buildTime: 300,
    cost: { food: 10, stone: 4, parts: 0 },
    housing: 3, hp: 200,
    healsPerTick: 0.5, healRadius: 6,
    desc: 'Heals nearby friendly units over time.'
  },
  fusionTemple: {
    name: 'Fusion Temple', icon: '✨',
    size: { w: 2, h: 2 }, spriteH: 28,
    buildTime: 400,
    cost: { food: 20, stone: 4, parts: 0 },
    housing: 6, hp: 350,
    research: 'religious',
    fusionSpells: true,
    desc: 'Advanced magic building. Enables powerful fusion spells.'
  },
  lighthouse: {
    name: 'Lighthouse', icon: '🗼',
    size: { w: 1, h: 1 }, spriteH: 28,
    buildTime: 200,
    cost: { food: 12, stone: 4, parts: 0 },
    housing: 2, hp: 150,
    visionBonus: 8,
    desc: 'Provides extended vision in a large radius.'
  },
  campaignTent: {
    name: 'Campaign Tent', icon: '⛺',
    size: { w: 1, h: 1 }, spriteH: 10,
    buildTime: 300,
    cost: { food: 10, stone: 4, parts: 0 },
    housing: 6, hp: 100,
    isForwardBase: true,
    desc: 'Portable field base. Quick to deploy for expansion.'
  },
};
