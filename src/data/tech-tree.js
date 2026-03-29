// ============================================================
//  tech-tree.js — All 81 technologies from Rising Lands
//  4 branches: Agriculture (19), Military (20),
//              Civil Engineering (24), Religious (18)
// ============================================================

/**
 * Each tech has:
 *   branch   - Which research branch it belongs to
 *   tier     - Position in the branch (0 = first available)
 *   name     - Display name
 *   cost     - Tech points required
 *   time     - Research ticks
 *   requires - Array of prerequisite tech IDs (empty = base tech)
 *   effect   - What it unlocks or improves
 *   desc     - Tooltip description
 */

export const TechBranch = {
  AGRICULTURE:       'agriculture',
  MILITARY:          'military',
  CIVIL_ENGINEERING: 'civil_engineering',
  RELIGIOUS:         'religious',
};

export const TechTree = {

  // ═══════════════════════════════════════════════════════════
  //  AGRICULTURE  (19 techs, tiers 0-18)
  // ═══════════════════════════════════════════════════════════

  agri_basic_farming: {
    branch: TechBranch.AGRICULTURE, tier: 0,
    name: 'Basic Farming', cost: 10, time: 300,
    requires: [],
    effect: { unlockBuilding: 'culture' },
    desc: 'Enables construction of Culture (farm) fields.'
  },
  agri_improved_yield: {
    branch: TechBranch.AGRICULTURE, tier: 1,
    name: 'Improved Yield', cost: 15, time: 400,
    requires: ['agri_basic_farming'],
    effect: { farmYieldBonus: 0.25 },
    desc: 'Farm fields produce 25% more food.'
  },
  agri_irrigation: {
    branch: TechBranch.AGRICULTURE, tier: 2,
    name: 'Irrigation', cost: 20, time: 500,
    requires: ['agri_improved_yield'],
    effect: { farmYieldBonus: 0.25 },
    desc: 'Advanced water management. +25% farm output.'
  },
  agri_fast_harvest: {
    branch: TechBranch.AGRICULTURE, tier: 3,
    name: 'Fast Harvest', cost: 20, time: 450,
    requires: ['agri_irrigation'],
    effect: { gatherSpeedBonus: { food: 0.2 } },
    desc: 'Farmers gather food 20% faster.'
  },
  agri_crop_rotation: {
    branch: TechBranch.AGRICULTURE, tier: 4,
    name: 'Crop Rotation', cost: 25, time: 600,
    requires: ['agri_fast_harvest'],
    effect: { farmYieldBonus: 0.25 },
    desc: 'Seasonal planting techniques. +25% farm output.'
  },
  agri_selective_breeding: {
    branch: TechBranch.AGRICULTURE, tier: 5,
    name: 'Selective Breeding', cost: 25, time: 500,
    requires: ['agri_crop_rotation'],
    effect: { unlockBuilding: 'circus' },
    desc: 'Unlock the Circus for taming wild creatures.'
  },
  agri_preservation: {
    branch: TechBranch.AGRICULTURE, tier: 6,
    name: 'Food Preservation', cost: 30, time: 600,
    requires: ['agri_crop_rotation'],
    effect: { storageBonus: { food: 100 } },
    desc: 'Storehouses hold +100 food.'
  },
  agri_fertilizer: {
    branch: TechBranch.AGRICULTURE, tier: 7,
    name: 'Fertilizer', cost: 30, time: 700,
    requires: ['agri_preservation'],
    effect: { farmYieldBonus: 0.3 },
    desc: 'Chemical soil enrichment. +30% farm output.'
  },
  agri_surplus: {
    branch: TechBranch.AGRICULTURE, tier: 8,
    name: 'Surplus Management', cost: 35, time: 700,
    requires: ['agri_fertilizer'],
    effect: { unlockBuilding: 'market' },
    desc: 'Unlock the Market for resource trading.'
  },
  agri_veterinary: {
    branch: TechBranch.AGRICULTURE, tier: 9,
    name: 'Veterinary Arts', cost: 30, time: 600,
    requires: ['agri_selective_breeding'],
    effect: { creatureHpBonus: 0.2 },
    desc: 'Tamed creatures gain +20% HP.'
  },
  agri_reaper_tech: {
    branch: TechBranch.AGRICULTURE, tier: 10,
    name: 'Mechanical Harvester', cost: 40, time: 800,
    requires: ['agri_surplus'],
    effect: { unlockUnit: 'reaper' },
    desc: 'Unlock the Reaper harvesting vehicle.'
  },
  agri_granary: {
    branch: TechBranch.AGRICULTURE, tier: 11,
    name: 'Granary', cost: 35, time: 700,
    requires: ['agri_surplus'],
    effect: { storageBonus: { food: 200 } },
    desc: 'Massive food storage. +200 food capacity.'
  },
  agri_feast: {
    branch: TechBranch.AGRICULTURE, tier: 12,
    name: 'Feast Rations', cost: 30, time: 500,
    requires: ['agri_granary'],
    effect: { hungerRateReduction: 0.2 },
    desc: 'Better rations. Units get hungry 20% slower.'
  },
  agri_taming_mastery: {
    branch: TechBranch.AGRICULTURE, tier: 13,
    name: 'Taming Mastery', cost: 40, time: 800,
    requires: ['agri_veterinary'],
    effect: { creatureDamageBonus: 0.15 },
    desc: 'Tamed creatures deal +15% damage.'
  },
  agri_herbalism: {
    branch: TechBranch.AGRICULTURE, tier: 14,
    name: 'Herbalism', cost: 35, time: 700,
    requires: ['agri_feast'],
    effect: { unlockBuilding: 'hospital' },
    desc: 'Unlock the Hospital for healing units.'
  },
  agri_advanced_medicine: {
    branch: TechBranch.AGRICULTURE, tier: 15,
    name: 'Advanced Medicine', cost: 40, time: 800,
    requires: ['agri_herbalism'],
    effect: { healRateBonus: 0.5 },
    desc: 'Hospitals heal 50% faster.'
  },
  agri_abundance: {
    branch: TechBranch.AGRICULTURE, tier: 16,
    name: 'Age of Abundance', cost: 50, time: 1000,
    requires: ['agri_advanced_medicine', 'agri_taming_mastery'],
    effect: { farmYieldBonus: 0.5, gatherSpeedBonus: { food: 0.3 } },
    desc: 'Ultimate farming tech. Massive food production boost.'
  },
  agri_wild_dominion: {
    branch: TechBranch.AGRICULTURE, tier: 17,
    name: 'Wild Dominion', cost: 45, time: 900,
    requires: ['agri_taming_mastery'],
    effect: { creatureHpBonus: 0.3, creatureDamageBonus: 0.2 },
    desc: 'Full mastery over tamed creatures.'
  },
  agri_golden_age: {
    branch: TechBranch.AGRICULTURE, tier: 18,
    name: 'Golden Age', cost: 60, time: 1200,
    requires: ['agri_abundance'],
    effect: { globalFoodBonus: 0.25, populationBonus: 5 },
    desc: 'Pinnacle of agriculture. Massive food and population gains.'
  },

  // ═══════════════════════════════════════════════════════════
  //  MILITARY  (20 techs, tiers 0-19)
  // ═══════════════════════════════════════════════════════════

  mil_basic_training: {
    branch: TechBranch.MILITARY, tier: 0,
    name: 'Basic Training', cost: 10, time: 300,
    requires: [],
    effect: { unlockUnit: 'swordsman' },
    desc: 'Train Swordsmen at the Barracks.'
  },
  mil_archery: {
    branch: TechBranch.MILITARY, tier: 1,
    name: 'Archery', cost: 15, time: 400,
    requires: ['mil_basic_training'],
    effect: { unlockUnit: 'archer' },
    desc: 'Train Archers at the Barracks.'
  },
  mil_fire_arts: {
    branch: TechBranch.MILITARY, tier: 2,
    name: 'Fire Arts', cost: 20, time: 500,
    requires: ['mil_basic_training'],
    effect: { unlockUnit: 'scorcher' },
    desc: 'Train Scorchers at the Barracks.'
  },
  mil_leadership: {
    branch: TechBranch.MILITARY, tier: 3,
    name: 'Leadership', cost: 25, time: 600,
    requires: ['mil_archery'],
    effect: { unlockUnit: 'captain' },
    desc: 'Train Captains at the Barracks. They boost nearby allies.'
  },
  mil_iron_weapons: {
    branch: TechBranch.MILITARY, tier: 4,
    name: 'Iron Weapons', cost: 20, time: 500,
    requires: ['mil_fire_arts'],
    effect: { meleeDamageBonus: 0.15 },
    desc: 'Melee units deal +15% damage.'
  },
  mil_longbow: {
    branch: TechBranch.MILITARY, tier: 5,
    name: 'Longbow', cost: 25, time: 600,
    requires: ['mil_archery'],
    effect: { rangedRangeBonus: 2 },
    desc: 'Ranged units gain +2 attack range.'
  },
  mil_armor_smithing: {
    branch: TechBranch.MILITARY, tier: 6,
    name: 'Armor Smithing', cost: 25, time: 600,
    requires: ['mil_iron_weapons'],
    effect: { armorBonus: 1 },
    desc: 'All combat units gain +1 armor.'
  },
  mil_tactics: {
    branch: TechBranch.MILITARY, tier: 7,
    name: 'Battle Tactics', cost: 30, time: 700,
    requires: ['mil_leadership'],
    effect: { auraRadiusBonus: 2 },
    desc: 'Captain aura radius increased by +2.'
  },
  mil_siege_craft: {
    branch: TechBranch.MILITARY, tier: 8,
    name: 'Siege Craft', cost: 30, time: 700,
    requires: ['mil_armor_smithing'],
    effect: { vsBuildingBonus: 0.3 },
    desc: 'All units deal +30% damage to buildings.'
  },
  mil_fire_arrows: {
    branch: TechBranch.MILITARY, tier: 9,
    name: 'Fire Arrows', cost: 30, time: 600,
    requires: ['mil_longbow', 'mil_fire_arts'],
    effect: { rangedDamageBonus: 0.2 },
    desc: 'Ranged units deal +20% damage.'
  },
  mil_steel_weapons: {
    branch: TechBranch.MILITARY, tier: 10,
    name: 'Steel Weapons', cost: 35, time: 800,
    requires: ['mil_siege_craft'],
    effect: { meleeDamageBonus: 0.2 },
    desc: 'Superior steel. Melee units deal +20% damage.'
  },
  mil_fortification: {
    branch: TechBranch.MILITARY, tier: 11,
    name: 'Fortification', cost: 25, time: 500,
    requires: ['mil_armor_smithing'],
    effect: { wallHpBonus: 0.5, towerDamageBonus: 0.2 },
    desc: 'Walls gain +50% HP. Towers deal +20% damage.'
  },
  mil_elite_guard: {
    branch: TechBranch.MILITARY, tier: 12,
    name: 'Elite Guard', cost: 35, time: 800,
    requires: ['mil_tactics'],
    effect: { captainDamageBonus: 0.25 },
    desc: 'Captains deal +25% damage.'
  },
  mil_rapid_deploy: {
    branch: TechBranch.MILITARY, tier: 13,
    name: 'Rapid Deployment', cost: 30, time: 600,
    requires: ['mil_elite_guard'],
    effect: { recruitTimeReduction: 0.2 },
    desc: 'Military units recruit 20% faster.'
  },
  mil_plate_armor: {
    branch: TechBranch.MILITARY, tier: 14,
    name: 'Plate Armor', cost: 40, time: 900,
    requires: ['mil_steel_weapons'],
    effect: { armorBonus: 1 },
    desc: 'Heavy plate. All combat units gain +1 armor.'
  },
  mil_precision_strike: {
    branch: TechBranch.MILITARY, tier: 15,
    name: 'Precision Strike', cost: 40, time: 800,
    requires: ['mil_fire_arrows'],
    effect: { rangedDamageBonus: 0.15, rangedRangeBonus: 1 },
    desc: 'Ranged units gain +15% damage and +1 range.'
  },
  mil_berserker: {
    branch: TechBranch.MILITARY, tier: 16,
    name: 'Berserker Rage', cost: 45, time: 900,
    requires: ['mil_plate_armor'],
    effect: { meleeDamageBonus: 0.25, meleeSpeedBonus: 0.15 },
    desc: 'Melee units deal +25% damage and move 15% faster.'
  },
  mil_war_machines: {
    branch: TechBranch.MILITARY, tier: 17,
    name: 'War Machines', cost: 40, time: 800,
    requires: ['mil_fortification'],
    effect: { towerDamageBonus: 0.3, towerRangeBonus: 2 },
    desc: 'Towers deal +30% damage with +2 range.'
  },
  mil_total_war: {
    branch: TechBranch.MILITARY, tier: 18,
    name: 'Total War', cost: 55, time: 1100,
    requires: ['mil_berserker', 'mil_precision_strike'],
    effect: { globalDamageBonus: 0.15 },
    desc: 'All combat units deal +15% damage.'
  },
  mil_supremacy: {
    branch: TechBranch.MILITARY, tier: 19,
    name: 'Military Supremacy', cost: 65, time: 1300,
    requires: ['mil_total_war', 'mil_war_machines'],
    effect: { globalDamageBonus: 0.1, armorBonus: 1, recruitTimeReduction: 0.15 },
    desc: 'Pinnacle of warfare. Damage, armor, and training all improved.'
  },

  // ═══════════════════════════════════════════════════════════
  //  CIVIL ENGINEERING  (24 techs, tiers 0-23)
  // ═══════════════════════════════════════════════════════════

  eng_masonry: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 0,
    name: 'Masonry', cost: 10, time: 300,
    requires: [],
    effect: { buildSpeedBonus: 0.15 },
    desc: 'Builders construct 15% faster.'
  },
  eng_stonecutting: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 1,
    name: 'Stonecutting', cost: 15, time: 400,
    requires: ['eng_masonry'],
    effect: { gatherSpeedBonus: { stone: 0.2 } },
    desc: 'Builders gather stone 20% faster.'
  },
  eng_walls: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 2,
    name: 'Wall Construction', cost: 15, time: 400,
    requires: ['eng_masonry'],
    effect: { unlockBuilding: 'wall' },
    desc: 'Enables building Walls for defense.'
  },
  eng_portcullis: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 3,
    name: 'Portcullis Design', cost: 20, time: 500,
    requires: ['eng_walls'],
    effect: { unlockBuilding: 'portcullis' },
    desc: 'Enables building Gates in walls.'
  },
  eng_tower_catapult: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 4,
    name: 'Catapult Tower', cost: 25, time: 600,
    requires: ['eng_walls'],
    effect: { unlockBuilding: 'towerCatapult' },
    desc: 'Enables building Catapult Towers.'
  },
  eng_tower_cannon: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 5,
    name: 'Cannon Tower', cost: 30, time: 700,
    requires: ['eng_tower_catapult'],
    effect: { unlockBuilding: 'towerCannon' },
    desc: 'Enables building Cannon Towers.'
  },
  eng_storehouse_upgrade: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 6,
    name: 'Expanded Storage', cost: 20, time: 500,
    requires: ['eng_stonecutting'],
    effect: { storageBonus: { food: 100, stone: 100, parts: 50 } },
    desc: 'Storehouses hold more resources.'
  },
  eng_workshop: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 7,
    name: 'Workshop Plans', cost: 25, time: 600,
    requires: ['eng_storehouse_upgrade'],
    effect: { unlockBuilding: 'workshop' },
    desc: 'Enables building the Workshop for vehicles.'
  },
  eng_speeder: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 8,
    name: 'Speeder Design', cost: 30, time: 700,
    requires: ['eng_workshop'],
    effect: { unlockUnit: 'speeder' },
    desc: 'Build Speeders at the Workshop.'
  },
  eng_boomer: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 9,
    name: 'Boomer Artillery', cost: 35, time: 800,
    requires: ['eng_workshop'],
    effect: { unlockUnit: 'boomer' },
    desc: 'Build Boomers at the Workshop.'
  },
  eng_bomber: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 10,
    name: 'Mine Layer', cost: 30, time: 700,
    requires: ['eng_speeder'],
    effect: { unlockUnit: 'bomber' },
    desc: 'Build Bombers (mine layers) at the Workshop.'
  },
  eng_hangar: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 11,
    name: 'Hangar Construction', cost: 25, time: 600,
    requires: ['eng_workshop'],
    effect: { unlockBuilding: 'hangar' },
    desc: 'Build Hangars to shelter vehicles.'
  },
  eng_garage: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 12,
    name: 'Garage Mechanics', cost: 30, time: 700,
    requires: ['eng_hangar'],
    effect: { unlockBuilding: 'garage' },
    desc: 'Build Garages that auto-repair vehicles.'
  },
  eng_heliport: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 13,
    name: 'Heliport Design', cost: 35, time: 800,
    requires: ['eng_hangar'],
    effect: { unlockBuilding: 'heliport' },
    desc: 'Build Heliports for flying units.'
  },
  eng_heliped: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 14,
    name: 'Heliped Prototype', cost: 40, time: 900,
    requires: ['eng_heliport'],
    effect: { unlockUnit: 'heliped' },
    desc: 'Build Helipeds at the Heliport.'
  },
  eng_balloon: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 15,
    name: 'Hot Air Balloon', cost: 35, time: 800,
    requires: ['eng_heliport'],
    effect: { unlockUnit: 'balloon' },
    desc: 'Build Balloons (air transport) at the Heliport.'
  },
  eng_hellfire: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 16,
    name: 'Hellfire Engine', cost: 50, time: 1000,
    requires: ['eng_boomer', 'eng_bomber'],
    effect: { unlockUnit: 'hellfire' },
    desc: 'Build the devastating Hellfire war machine.'
  },
  eng_reinforced: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 17,
    name: 'Reinforced Structures', cost: 35, time: 800,
    requires: ['eng_tower_cannon'],
    effect: { buildingHpBonus: 0.25 },
    desc: 'All buildings gain +25% HP.'
  },
  eng_vehicle_armor: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 18,
    name: 'Vehicle Plating', cost: 40, time: 800,
    requires: ['eng_garage'],
    effect: { vehicleArmorBonus: 1 },
    desc: 'All vehicles gain +1 armor.'
  },
  eng_rapid_build: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 19,
    name: 'Rapid Construction', cost: 35, time: 700,
    requires: ['eng_reinforced'],
    effect: { buildSpeedBonus: 0.25 },
    desc: 'Builders construct 25% faster.'
  },
  eng_lighthouse: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 20,
    name: 'Lighthouse', cost: 20, time: 500,
    requires: ['eng_masonry'],
    effect: { unlockBuilding: 'lighthouse' },
    desc: 'Build Lighthouses for extended vision.'
  },
  eng_campaign_tent: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 21,
    name: 'Field Camp', cost: 25, time: 600,
    requires: ['eng_rapid_build'],
    effect: { unlockBuilding: 'campaignTent' },
    desc: 'Build Campaign Tents as forward bases.'
  },
  eng_advanced_engines: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 22,
    name: 'Advanced Engines', cost: 50, time: 1000,
    requires: ['eng_vehicle_armor', 'eng_hellfire'],
    effect: { vehicleSpeedBonus: 0.2, vehicleDamageBonus: 0.15 },
    desc: 'All vehicles move 20% faster and deal +15% damage.'
  },
  eng_industrial_age: {
    branch: TechBranch.CIVIL_ENGINEERING, tier: 23,
    name: 'Industrial Age', cost: 70, time: 1400,
    requires: ['eng_advanced_engines', 'eng_campaign_tent'],
    effect: { buildSpeedBonus: 0.2, gatherSpeedBonus: { parts: 0.3 } },
    desc: 'Pinnacle of engineering. Faster building and parts gathering.'
  },

  // ═══════════════════════════════════════════════════════════
  //  RELIGIOUS  (18 techs, tiers 0-17)
  // ═══════════════════════════════════════════════════════════

  rel_faith: {
    branch: TechBranch.RELIGIOUS, tier: 0,
    name: 'Faith', cost: 10, time: 300,
    requires: [],
    effect: { unlockBuilding: 'temple' },
    desc: 'Enables building Temples and training Druids.'
  },
  rel_vision_spell: {
    branch: TechBranch.RELIGIOUS, tier: 1,
    name: 'Vision', cost: 15, time: 400,
    requires: ['rel_faith'],
    effect: { unlockSpell: 'vision' },
    desc: 'Druids learn Vision — reveals a map area.'
  },
  rel_crystal: {
    branch: TechBranch.RELIGIOUS, tier: 2,
    name: 'Crystal Attunement', cost: 20, time: 500,
    requires: ['rel_faith'],
    effect: { unlockBuilding: 'crystal' },
    desc: 'Enables building Crystals for mana generation.'
  },
  rel_petrification: {
    branch: TechBranch.RELIGIOUS, tier: 3,
    name: 'Petrification', cost: 25, time: 600,
    requires: ['rel_vision_spell'],
    effect: { unlockSpell: 'petrification' },
    desc: 'Druids learn Petrification — freezes an enemy unit.'
  },
  rel_mana_flow: {
    branch: TechBranch.RELIGIOUS, tier: 4,
    name: 'Mana Flow', cost: 20, time: 500,
    requires: ['rel_crystal'],
    effect: { manaRegenBonus: 0.5 },
    desc: 'Crystals generate 50% more mana.'
  },
  rel_mirror: {
    branch: TechBranch.RELIGIOUS, tier: 5,
    name: 'Mirror', cost: 30, time: 700,
    requires: ['rel_petrification'],
    effect: { unlockSpell: 'mirror' },
    desc: 'Druids learn Mirror — creates a decoy of a unit.'
  },
  rel_sanctuary: {
    branch: TechBranch.RELIGIOUS, tier: 6,
    name: 'Sanctuary Plans', cost: 25, time: 600,
    requires: ['rel_faith'],
    effect: { unlockBuilding: 'sanctuary' },
    desc: 'Enables building the Sanctuary (large housing).'
  },
  rel_armour: {
    branch: TechBranch.RELIGIOUS, tier: 7,
    name: 'Armour Blessing', cost: 35, time: 800,
    requires: ['rel_mirror'],
    effect: { unlockSpell: 'armour' },
    desc: 'Druids learn Armour — grants temporary armor to a unit.'
  },
  rel_deep_faith: {
    branch: TechBranch.RELIGIOUS, tier: 8,
    name: 'Deep Faith', cost: 30, time: 700,
    requires: ['rel_mana_flow'],
    effect: { druidManaBonus: 5 },
    desc: 'Druids gain +5 maximum mana.'
  },
  rel_meditation: {
    branch: TechBranch.RELIGIOUS, tier: 9,
    name: 'Meditation', cost: 30, time: 600,
    requires: ['rel_deep_faith'],
    effect: { manaRegenBonus: 0.3 },
    desc: 'Druids regenerate mana 30% faster.'
  },
  rel_nova: {
    branch: TechBranch.RELIGIOUS, tier: 10,
    name: 'Nova', cost: 45, time: 900,
    requires: ['rel_armour'],
    effect: { unlockSpell: 'nova' },
    desc: 'Druids learn Nova — devastating area damage spell.'
  },
  rel_fusion_temple: {
    branch: TechBranch.RELIGIOUS, tier: 11,
    name: 'Fusion Temple', cost: 40, time: 800,
    requires: ['rel_nova'],
    effect: { unlockBuilding: 'fusionTemple' },
    desc: 'Enables building the Fusion Temple for advanced magic.'
  },
  rel_spirit_link: {
    branch: TechBranch.RELIGIOUS, tier: 12,
    name: 'Spirit Link', cost: 35, time: 700,
    requires: ['rel_meditation'],
    effect: { sharedMana: true },
    desc: 'Druids share mana pool with nearby Crystals.'
  },
  rel_blessing: {
    branch: TechBranch.RELIGIOUS, tier: 13,
    name: 'Divine Blessing', cost: 40, time: 800,
    requires: ['rel_spirit_link'],
    effect: { globalHealRate: 0.01 },
    desc: 'All friendly units slowly regenerate HP.'
  },
  rel_spell_mastery: {
    branch: TechBranch.RELIGIOUS, tier: 14,
    name: 'Spell Mastery', cost: 45, time: 900,
    requires: ['rel_nova'],
    effect: { spellCostReduction: 0.25 },
    desc: 'All spells cost 25% less mana.'
  },
  rel_ascension: {
    branch: TechBranch.RELIGIOUS, tier: 15,
    name: 'Ascension', cost: 50, time: 1000,
    requires: ['rel_fusion_temple'],
    effect: { druidDamageBonus: 0.5, druidArmorBonus: 2 },
    desc: 'Druids gain +50% spell damage and +2 armor.'
  },
  rel_divine_shield: {
    branch: TechBranch.RELIGIOUS, tier: 16,
    name: 'Divine Shield', cost: 50, time: 1000,
    requires: ['rel_blessing', 'rel_spell_mastery'],
    effect: { globalArmorBonus: 1 },
    desc: 'All friendly units gain +1 armor from divine protection.'
  },
  rel_transcendence: {
    branch: TechBranch.RELIGIOUS, tier: 17,
    name: 'Transcendence', cost: 70, time: 1400,
    requires: ['rel_ascension', 'rel_divine_shield'],
    effect: { manaRegenBonus: 1.0, spellCostReduction: 0.25, druidVisionBonus: 5 },
    desc: 'Pinnacle of faith. Massive mana and spell improvements.'
  },
};

/** Helper: get all techs for a branch */
export function getTechsByBranch(branch) {
  return Object.entries(TechTree)
    .filter(([, t]) => t.branch === branch)
    .sort((a, b) => a[1].tier - b[1].tier)
    .map(([id, t]) => ({ id, ...t }));
}

/** Helper: check if all prerequisites are researched */
export function canResearch(techId, researchedSet) {
  const tech = TechTree[techId];
  if (!tech) return false;
  return tech.requires.every(req => researchedSet.has(req));
}
