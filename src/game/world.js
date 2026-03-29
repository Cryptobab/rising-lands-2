// ============================================================
//  world.js — Procedural map generation and world state
// ============================================================

import { Terrain } from '../engine/tilemap.js';

/** Simplex-ish noise (seeded value noise with smoothing) */
class SeededNoise {
  constructor(seed = 42) {
    this.seed = seed;
    this.perm = new Uint8Array(512);
    // Fill permutation table from seed
    let s = seed;
    for (let i = 0; i < 256; i++) {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      this.perm[i] = this.perm[i + 256] = s & 255;
    }
  }

  /** 2D value noise in [0,1] */
  noise2D(x, y) {
    const xi = Math.floor(x), yi = Math.floor(y);
    const xf = x - xi, yf = y - yi;
    const sx = xf * xf * (3 - 2 * xf);
    const sy = yf * yf * (3 - 2 * yf);

    const aa = this._hash(xi, yi);
    const ba = this._hash(xi + 1, yi);
    const ab = this._hash(xi, yi + 1);
    const bb = this._hash(xi + 1, yi + 1);

    const top = aa + sx * (ba - aa);
    const bot = ab + sx * (bb - ab);
    return top + sy * (bot - top);
  }

  /** Multi-octave fractal noise */
  fbm(x, y, octaves = 4, lacunarity = 2, gain = 0.5) {
    let val = 0, amp = 1, freq = 1, max = 0;
    for (let i = 0; i < octaves; i++) {
      val += this.noise2D(x * freq, y * freq) * amp;
      max += amp;
      amp *= gain;
      freq *= lacunarity;
    }
    return val / max;
  }

  _hash(x, y) {
    const idx = this.perm[(x & 255) + this.perm[y & 255]];
    return idx / 255;
  }
}

export class World {
  constructor(width, height, seed = Date.now()) {
    this.width = width;
    this.height = height;
    this.seed = seed;
    this.terrain = new Uint8Array(width * height);
    this.walkable = new Uint8Array(width * height);
    this.terrainCost = new Float32Array(width * height);
    this.resources = new Map();   // "x,y" -> { type, amount }
    this.buildings = new Map();   // "x,y" -> building entity ref
    this.units = [];
    this.generate();
  }

  generate() {
    const noise = new SeededNoise(this.seed);
    const w = this.width, h = this.height;

    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const i = y * w + x;

        // Base elevation
        const elev = noise.fbm(x * 0.03, y * 0.03, 5, 2.0, 0.5);
        // Moisture for biome selection
        const moist = noise.fbm(x * 0.04 + 100, y * 0.04 + 100, 4, 2.0, 0.5);
        // Temperature variation
        const temp = noise.fbm(x * 0.02 + 200, y * 0.02 + 200, 3, 2.0, 0.5);

        // Determine terrain type based on elevation + moisture
        let t;
        if (elev < 0.28) {
          t = Terrain.WATER;
        } else if (elev < 0.35) {
          t = Terrain.SAND;
        } else if (elev > 0.78) {
          t = Terrain.MOUNTAIN;
        } else if (elev > 0.68) {
          t = temp > 0.6 ? Terrain.MAGMA : Terrain.ROCK;
        } else if (moist > 0.55 && elev > 0.4) {
          t = Terrain.FOREST;
        } else if (moist < 0.35) {
          t = Terrain.DIRT;
        } else {
          t = Terrain.GRASS;
        }

        this.terrain[i] = t;
        this.walkable[i] = (t !== Terrain.WATER && t !== Terrain.MOUNTAIN) ? 1 : 0;

        // Terrain movement cost multipliers
        const costs = {
          [Terrain.WATER]: 99,
          [Terrain.GRASS]: 1.0,
          [Terrain.DIRT]: 1.1,
          [Terrain.SAND]: 1.4,
          [Terrain.FOREST]: 1.6,
          [Terrain.ROCK]: 1.3,
          [Terrain.MOUNTAIN]: 99,
          [Terrain.MAGMA]: 2.5,
        };
        this.terrainCost[i] = costs[t] || 1.0;
      }
    }

    this._placeResources(noise);
  }

  _placeResources(noise) {
    const w = this.width, h = this.height;

    for (let y = 2; y < h - 2; y += 3) {
      for (let x = 2; x < w - 2; x += 3) {
        const t = this.getTerrain(x, y);
        const r = noise.noise2D(x * 0.1 + 500, y * 0.1 + 500);

        // Stone deposits on rock/dirt terrain
        if ((t === Terrain.ROCK || t === Terrain.DIRT) && r > 0.72) {
          this.resources.set(`${x},${y}`, { type: 'stone', amount: 50 + Math.floor(r * 100) });
        }
        // Food patches in forests/grass
        else if ((t === Terrain.FOREST || t === Terrain.GRASS) && r > 0.75) {
          this.resources.set(`${x},${y}`, { type: 'food', amount: 30 + Math.floor(r * 60) });
        }
        // Mechanical parts near magma/rock
        else if ((t === Terrain.MAGMA || t === Terrain.ROCK) && r > 0.82) {
          this.resources.set(`${x},${y}`, { type: 'parts', amount: 15 + Math.floor(r * 30) });
        }
      }
    }
  }

  getTerrain(x, y) {
    if (x < 0 || x >= this.width || y < 0 || y >= this.height) return Terrain.WATER;
    return this.terrain[y * this.width + x];
  }

  isWalkable(x, y) {
    if (x < 0 || x >= this.width || y < 0 || y >= this.height) return false;
    const i = y * this.width + x;
    if (!this.walkable[i]) return false;
    // Check for blocking buildings
    if (this.buildings.has(`${x},${y}`)) return false;
    return true;
  }

  getTerrainCost(x, y) {
    if (x < 0 || x >= this.width || y < 0 || y >= this.height) return 99;
    return this.terrainCost[y * this.width + x];
  }

  getResource(x, y) {
    return this.resources.get(`${x},${y}`) || null;
  }

  /** Find a flat, walkable area of given size for building placement */
  findBuildSite(cx, cy, w, h, maxRadius = 10) {
    for (let r = 0; r <= maxRadius; r++) {
      for (let dy = -r; dy <= r; dy++) {
        for (let dx = -r; dx <= r; dx++) {
          const sx = cx + dx, sy = cy + dy;
          if (this._canPlaceBuilding(sx, sy, w, h)) {
            return { x: sx, y: sy };
          }
        }
      }
    }
    return null;
  }

  _canPlaceBuilding(sx, sy, bw, bh) {
    for (let dy = 0; dy < bh; dy++) {
      for (let dx = 0; dx < bw; dx++) {
        const x = sx + dx, y = sy + dy;
        if (!this.isWalkable(x, y)) return false;
        const t = this.getTerrain(x, y);
        if (t === Terrain.WATER || t === Terrain.MOUNTAIN || t === Terrain.MAGMA) return false;
      }
    }
    return true;
  }
}
