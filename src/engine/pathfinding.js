// ============================================================
//  pathfinding.js — A* with terrain cost support
// ============================================================

export class Pathfinder {
  constructor(world) {
    this.world = world;
  }

  /**
   * Find path from (sx,sy) to (ex,ey) using A*
   * Returns array of {x, y} or null if no path
   */
  findPath(sx, sy, ex, ey, maxSteps = 500) {
    const w = this.world;
    sx = Math.round(sx); sy = Math.round(sy);
    ex = Math.round(ex); ey = Math.round(ey);

    if (!w.isWalkable(ex, ey)) {
      // Find nearest walkable tile to target
      const near = this._nearestWalkable(ex, ey);
      if (!near) return null;
      ex = near.x; ey = near.y;
    }

    const key = (x, y) => `${x},${y}`;
    const open = new MinHeap();
    const closed = new Set();
    const gScore = new Map();
    const parent = new Map();

    const startKey = key(sx, sy);
    gScore.set(startKey, 0);
    open.push({ x: sx, y: sy, f: this._heuristic(sx, sy, ex, ey) });

    let steps = 0;
    while (open.size() > 0 && steps < maxSteps) {
      steps++;
      const current = open.pop();
      const ck = key(current.x, current.y);

      if (current.x === ex && current.y === ey) {
        return this._reconstructPath(parent, current.x, current.y, sx, sy);
      }

      closed.add(ck);

      for (const [dx, dy] of [[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[-1,1],[1,-1],[1,1]]) {
        const nx = current.x + dx;
        const ny = current.y + dy;
        const nk = key(nx, ny);

        if (closed.has(nk) || !w.isWalkable(nx, ny)) continue;

        const moveCost = (dx !== 0 && dy !== 0) ? 1.414 : 1.0;
        const terrainCost = w.getTerrainCost(nx, ny);
        const tentG = gScore.get(ck) + moveCost * terrainCost;

        if (!gScore.has(nk) || tentG < gScore.get(nk)) {
          gScore.set(nk, tentG);
          parent.set(nk, ck);
          const f = tentG + this._heuristic(nx, ny, ex, ey);
          open.push({ x: nx, y: ny, f });
        }
      }
    }

    return null; // No path found
  }

  _heuristic(ax, ay, bx, by) {
    // Octile distance
    const dx = Math.abs(ax - bx);
    const dy = Math.abs(ay - by);
    return Math.max(dx, dy) + 0.414 * Math.min(dx, dy);
  }

  _reconstructPath(parent, ex, ey, sx, sy) {
    const path = [];
    let k = `${ex},${ey}`;
    const sk = `${sx},${sy}`;

    while (k !== sk) {
      const [x, y] = k.split(',').map(Number);
      path.unshift({ x, y });
      k = parent.get(k);
      if (!k) break;
    }
    return path;
  }

  _nearestWalkable(x, y) {
    for (let r = 1; r < 6; r++) {
      for (let dx = -r; dx <= r; dx++) {
        for (let dy = -r; dy <= r; dy++) {
          if (this.world.isWalkable(x + dx, y + dy)) {
            return { x: x + dx, y: y + dy };
          }
        }
      }
    }
    return null;
  }
}

/** Simple binary min-heap for A* open set */
class MinHeap {
  constructor() { this.data = []; }
  size() { return this.data.length; }

  push(item) {
    this.data.push(item);
    this._bubbleUp(this.data.length - 1);
  }

  pop() {
    const top = this.data[0];
    const last = this.data.pop();
    if (this.data.length > 0) {
      this.data[0] = last;
      this._sinkDown(0);
    }
    return top;
  }

  _bubbleUp(i) {
    while (i > 0) {
      const p = (i - 1) >> 1;
      if (this.data[i].f >= this.data[p].f) break;
      [this.data[i], this.data[p]] = [this.data[p], this.data[i]];
      i = p;
    }
  }

  _sinkDown(i) {
    const n = this.data.length;
    while (true) {
      let smallest = i;
      const l = 2 * i + 1, r = 2 * i + 2;
      if (l < n && this.data[l].f < this.data[smallest].f) smallest = l;
      if (r < n && this.data[r].f < this.data[smallest].f) smallest = r;
      if (smallest === i) break;
      [this.data[i], this.data[smallest]] = [this.data[smallest], this.data[i]];
      i = smallest;
    }
  }
}
