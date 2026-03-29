// ============================================================
//  spells.js — Druid spell definitions from Rising Lands
// ============================================================

export const SpellDefs = {
  vision: {
    name: 'Vision',
    icon: '👁',
    manaCost: 3,
    cooldown: 300,
    range: 0,            // Cast anywhere on map
    radius: 8,
    duration: 200,
    target: 'ground',    // ground | unit | self
    effect: 'revealArea',
    desc: 'Reveals fog of war in a large radius for a short time.'
  },
  petrification: {
    name: 'Petrification',
    icon: '🪨',
    manaCost: 5,
    cooldown: 500,
    range: 6,
    radius: 0,
    duration: 150,
    target: 'unit',
    effect: 'stun',
    desc: 'Turns an enemy unit to stone, freezing it in place.'
  },
  mirror: {
    name: 'Mirror',
    icon: '🪞',
    manaCost: 6,
    cooldown: 600,
    range: 4,
    radius: 0,
    duration: 300,
    target: 'unit',
    effect: 'duplicate',
    desc: 'Creates a phantom duplicate of a friendly unit. The mirror copy has reduced HP but identical damage.'
  },
  armour: {
    name: 'Armour',
    icon: '🛡',
    manaCost: 4,
    cooldown: 400,
    range: 5,
    radius: 3,
    duration: 250,
    target: 'unit',
    effect: 'armorBuff',
    armorBonus: 3,
    desc: 'Grants +3 armor to target unit and nearby allies for a limited time.'
  },
  nova: {
    name: 'Nova',
    icon: '💫',
    manaCost: 12,
    cooldown: 800,
    range: 7,
    radius: 4,
    duration: 0,        // Instant
    target: 'ground',
    effect: 'areaDamage',
    damage: 60,
    desc: 'Unleashes a devastating blast of energy, dealing heavy damage to all enemies in the area.'
  },
};

/** Get all available spells for a druid given researched techs */
export function getAvailableSpells(researchedSet) {
  const mapping = {
    vision:        'rel_vision_spell',
    petrification: 'rel_petrification',
    mirror:        'rel_mirror',
    armour:        'rel_armour',
    nova:          'rel_nova',
  };

  return Object.entries(SpellDefs)
    .filter(([id]) => researchedSet.has(mapping[id]))
    .map(([id, spell]) => ({ id, ...spell }));
}
