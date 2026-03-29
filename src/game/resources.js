// ============================================================
//  resources.js — Player resource tracking
// ============================================================

export class PlayerResources {
  constructor() {
    this.food = 100;
    this.stone = 50;
    this.parts = 0;
    this.techPoints = 0;
    this.mana = 0;
    this.population = 0;
    this.maxPopulation = 10;  // From housing
    this.maxFood = 500;
    this.maxStone = 500;
    this.maxParts = 200;
  }

  canAfford(cost) {
    return this.food >= (cost.food || 0) &&
           this.stone >= (cost.stone || 0) &&
           this.parts >= (cost.parts || 0);
  }

  spend(cost) {
    if (!this.canAfford(cost)) return false;
    this.food -= cost.food || 0;
    this.stone -= cost.stone || 0;
    this.parts -= cost.parts || 0;
    return true;
  }

  add(type, amount) {
    switch (type) {
      case 'food':  this.food = Math.min(this.maxFood, this.food + amount); break;
      case 'stone': this.stone = Math.min(this.maxStone, this.stone + amount); break;
      case 'parts': this.parts = Math.min(this.maxParts, this.parts + amount); break;
    }
  }

  /** Recalculate max pop from buildings */
  updatePopCap(buildings) {
    this.maxPopulation = buildings.reduce((sum, b) => {
      return b.built ? sum + (b.housing || 0) : sum;
    }, 0);
  }
}
