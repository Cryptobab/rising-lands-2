// ============================================================
//  entities.js — Entity system for units and buildings
// ============================================================

import { UnitDefs, CreatureDefs } from '../data/units.js';
import { BuildingDefs } from '../data/buildings.js';

let nextId = 1;

// ── Base Entity ──

export class Entity {
  constructor(type, x, y, owner) {
    this.id = nextId++;
    this.type = type;
    this.x = x;
    this.y = y;
    this.owner = owner;    // Player ID (0 = player, 1+ = AI, -1 = neutral)
    this.hp = 100;
    this.maxHp = 100;
    this.dead = false;
    this.selected = false;
  }

  takeDamage(amount, armor = 0) {
    const reduced = Math.max(1, amount - armor);
    this.hp -= reduced;
    if (this.hp <= 0) {
      this.hp = 0;
      this.dead = true;
    }
    return reduced;
  }
}

// ── Unit Entity ──

export class Unit extends Entity {
  constructor(unitType, x, y, owner) {
    super(unitType, x, y, owner);
    const def = UnitDefs[unitType] || CreatureDefs[unitType];
    if (!def) throw new Error(`Unknown unit type: ${unitType}`);

    this.def = def;
    this.name = def.name;
    this.role = def.role;
    this.icon = def.icon;

    // Stats
    this.maxHp = (def.role === 'worker' || def.role === 'civilian') ? 50 : 100;
    this.hp = this.maxHp;
    this.armor = def.armor || 0;
    this.speed = def.speed || 1.0;
    this.vision = def.vision || 5;
    this.range = def.range || 1;
    this.damage = def.damage ? { ...def.damage } : { base: 0, vsBuilding: 0 };

    // Movement
    this.targetX = x;
    this.targetY = y;
    this.path = null;
    this.pathIndex = 0;
    this.moving = false;

    // Combat
    this.attackTarget = null;
    this.attackCooldown = 0;
    this.attackRate = 30; // ticks between attacks

    // Hunger system (signature Rising Lands feature)
    this.hunger = 0;
    this.maxHunger = def.hunger ? def.hunger.max : 100;
    this.hungerRate = def.hunger ? def.hunger.rate : 0.01;
    this.starving = false;

    // Fatigue
    this.fatigue = 0;
    this.maxFatigue = def.fatigue || 3000;

    // Worker-specific
    this.carrying = 0;
    this.carryType = null;
    this.carryCapacity = def.carryCapacity || 0;
    this.gatherTarget = null;
    this.gatherProgress = 0;
    this.gatherSpeed = def.gatherSpeed || 0;

    // Magic-specific
    if (def.mana) {
      this.mana = def.mana.max;
      this.maxMana = def.mana.max;
      this.manaRegen = def.mana.regen;
    }

    // State machine
    this.state = 'idle';  // idle | moving | attacking | gathering | returning | dead
    this.stateTimer = 0;

    // Flying
    this.isFlying = def.isFlying || false;
    this.isVehicle = def.isVehicle || false;

    // Transport
    this.isTransport = def.isTransport || false;
    this.capacity = def.capacity || 0;
    this.passengers = [];
  }

  update(world, dt) {
    if (this.dead) return;

    // Hunger tick
    this.hunger += this.hungerRate * dt;
    if (this.hunger >= this.maxHunger) {
      this.starving = true;
      this.hp -= 0.05 * dt; // Starvation damage
      if (this.hp <= 0) {
        this.hp = 0;
        this.dead = true;
        return;
      }
    } else {
      this.starving = false;
    }

    // Mana regen
    if (this.mana !== undefined) {
      this.mana = Math.min(this.maxMana, this.mana + this.manaRegen * dt);
    }

    // Attack cooldown
    if (this.attackCooldown > 0) this.attackCooldown -= dt;

    // State handling
    switch (this.state) {
      case 'moving':
        this._updateMovement(dt);
        break;
      case 'attacking':
        this._updateAttack(dt);
        break;
      case 'gathering':
        this._updateGathering(world, dt);
        break;
      case 'returning':
        this._updateMovement(dt);
        break;
      case 'idle':
      default:
        break;
    }
  }

  moveTo(path) {
    if (!path || path.length === 0) return;
    this.path = path;
    this.pathIndex = 0;
    this.state = 'moving';
    this.moving = true;
    this.attackTarget = null;
  }

  attack(target) {
    this.attackTarget = target;
    this.state = 'attacking';
  }

  gather(resourceX, resourceY) {
    this.gatherTarget = { x: resourceX, y: resourceY };
    this.state = 'gathering';
    this.gatherProgress = 0;
  }

  feed(amount) {
    this.hunger = Math.max(0, this.hunger - amount);
  }

  _updateMovement(dt) {
    if (!this.path || this.pathIndex >= this.path.length) {
      this.state = this.state === 'returning' ? 'idle' : 'idle';
      this.moving = false;
      this.path = null;
      return;
    }

    const target = this.path[this.pathIndex];
    const dx = target.x - this.x;
    const dy = target.y - this.y;
    const dist = Math.sqrt(dx * dx + dy * dy);

    if (dist < 0.1) {
      this.x = target.x;
      this.y = target.y;
      this.pathIndex++;
    } else {
      const step = this.speed * dt * 0.02;
      this.x += (dx / dist) * Math.min(step, dist);
      this.y += (dy / dist) * Math.min(step, dist);
    }

    // Fatigue from movement
    this.fatigue += dt * 0.5;
  }

  _updateAttack(dt) {
    if (!this.attackTarget || this.attackTarget.dead) {
      this.attackTarget = null;
      this.state = 'idle';
      return;
    }

    const dx = this.attackTarget.x - this.x;
    const dy = this.attackTarget.y - this.y;
    const dist = Math.sqrt(dx * dx + dy * dy);

    if (dist <= this.range) {
      // In range: attack
      if (this.attackCooldown <= 0) {
        const dmg = this.damage.base;
        const targetArmor = this.attackTarget.armor || 0;
        this.attackTarget.takeDamage(dmg, targetArmor);
        this.attackCooldown = this.attackRate;
        this.fatigue += 5;
      }
    }
    // If out of range, we'd need pathfinding — handled by game loop
  }

  _updateGathering(world, dt) {
    if (!this.gatherTarget) {
      this.state = 'idle';
      return;
    }

    const res = world.getResource(this.gatherTarget.x, this.gatherTarget.y);
    if (!res || res.amount <= 0) {
      this.gatherTarget = null;
      this.state = 'idle';
      return;
    }

    this.gatherProgress += dt;
    if (this.gatherProgress >= this.gatherSpeed) {
      this.gatherProgress = 0;
      const gathered = Math.min(1, res.amount);
      res.amount -= gathered;
      this.carrying += gathered;
      this.carryType = res.type;

      if (this.carrying >= this.carryCapacity) {
        // Full — return to storehouse
        this.state = 'returning';
      }
    }
  }
}

// ── Building Entity ──

export class Building extends Entity {
  constructor(buildingType, x, y, owner) {
    super(buildingType, x, y, owner);
    const def = BuildingDefs[buildingType];
    if (!def) throw new Error(`Unknown building type: ${buildingType}`);

    this.def = def;
    this.name = def.name;
    this.icon = def.icon;
    this.size = def.size;

    this.maxHp = def.hp || 200;
    this.hp = 0;               // Starts at 0, built up by builders
    this.built = false;
    this.buildProgress = 0;
    this.buildTime = def.buildTime;

    // Training queue
    this.trainQueue = [];
    this.trainProgress = 0;
    this.trains = def.trains || [];

    // Special properties
    this.housing = def.housing || 0;
    this.storage = def.storage ? { ...def.storage } : null;
    this.attack = def.attack ? { ...def.attack } : null;
    this.attackCooldown = 0;

    // Farm
    this.isFarm = def.farm || false;
    this.farmYield = def.farmYield || 0;

    // Research
    this.researchBranch = def.research || null;
    this.techPointsPerTick = def.techPointsPerTick || 0;

    // Healing
    this.healsPerTick = def.healsPerTick || 0;
    this.healRadius = def.healRadius || 0;

    // Mana
    this.manaPerTick = def.manaPerTick || 0;
  }

  /** Called each tick by builders working on this building */
  addBuildProgress(amount) {
    if (this.built) return;
    this.buildProgress += amount;
    this.hp = Math.floor((this.buildProgress / this.buildTime) * this.maxHp);
    if (this.buildProgress >= this.buildTime) {
      this.buildProgress = this.buildTime;
      this.hp = this.maxHp;
      this.built = true;
    }
  }

  /** Queue a unit for training */
  queueUnit(unitType) {
    if (!this.trains.includes(unitType)) return false;
    const def = UnitDefs[unitType];
    if (!def) return false;
    this.trainQueue.push({ type: unitType, time: def.recruitTime, progress: 0 });
    return true;
  }

  update(dt) {
    if (this.dead || !this.built) return;

    // Tower attack
    if (this.attack && this.attackCooldown > 0) {
      this.attackCooldown -= dt;
    }

    // Training
    if (this.trainQueue.length > 0) {
      const current = this.trainQueue[0];
      current.progress += dt;
      this.trainProgress = current.progress / current.time;
      if (current.progress >= current.time) {
        this.trainQueue.shift();
        this.trainProgress = 0;
        return current.type; // Return spawned unit type
      }
    }

    return null;
  }

  /** Check if a point is inside this building's footprint */
  containsTile(tx, ty) {
    return tx >= this.x && tx < this.x + this.size.w &&
           ty >= this.y && ty < this.y + this.size.h;
  }
}

// ── Entity Manager ──

export class EntityManager {
  constructor() {
    this.units = [];
    this.buildings = [];
    this.all = new Map();  // id -> entity
  }

  addUnit(unit) {
    this.units.push(unit);
    this.all.set(unit.id, unit);
    return unit;
  }

  addBuilding(building) {
    this.buildings.push(building);
    this.all.set(building.id, building);
    return building;
  }

  getById(id) {
    return this.all.get(id) || null;
  }

  /** Remove dead entities */
  cleanup() {
    this.units = this.units.filter(u => {
      if (u.dead) { this.all.delete(u.id); return false; }
      return true;
    });
    this.buildings = this.buildings.filter(b => {
      if (b.dead) { this.all.delete(b.id); return false; }
      return true;
    });
  }

  /** Get all units belonging to a player */
  getPlayerUnits(owner) {
    return this.units.filter(u => u.owner === owner && !u.dead);
  }

  getPlayerBuildings(owner) {
    return this.buildings.filter(b => b.owner === owner && !b.dead);
  }

  /** Get entities near a world position */
  getUnitsInRadius(x, y, radius) {
    const r2 = radius * radius;
    return this.units.filter(u => {
      if (u.dead) return false;
      const dx = u.x - x, dy = u.y - y;
      return dx * dx + dy * dy <= r2;
    });
  }

  /** Get entity at a specific tile (for click selection) */
  getUnitAt(tx, ty, tolerance = 0.8) {
    let closest = null, bestDist = tolerance;
    for (const u of this.units) {
      if (u.dead) continue;
      const dx = u.x - tx, dy = u.y - ty;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < bestDist) {
        bestDist = dist;
        closest = u;
      }
    }
    return closest;
  }

  getBuildingAt(tx, ty) {
    return this.buildings.find(b => !b.dead && b.containsTile(tx, ty)) || null;
  }
}
