// ============================================================
//  tilemap.js — Isometric tilemap renderer with sprite cache
// ============================================================

export const TILE_W = 64;
export const TILE_H = 32;
export const HALF_W = 32;
export const HALF_H = 16;

export const Terrain = {
  WATER: 0,
  GRASS: 1,
  DIRT: 2,
  SAND: 3,
  FOREST: 4,
  ROCK: 5,
  MOUNTAIN: 6,
  MAGMA: 7
};

const TERRAIN_COLORS = {
  [Terrain.WATER]:    { top: [26,58,90],   right: [18,42,68],   left: [22,50,78] },
  [Terrain.GRASS]:    { top: [50,100,35],  right: [35,72,24],   left: [42,85,28] },
  [Terrain.DIRT]:     { top: [100,80,45],  right: [72,58,32],   left: [85,68,38] },
  [Terrain.SAND]:     { top: [160,140,80], right: [120,105,58], left: [140,122,68] },
  [Terrain.FOREST]:   { top: [35,75,25],   right: [24,54,17],   left: [28,62,20] },
  [Terrain.ROCK]:     { top: [100,100,100],right: [72,72,72],   left: [85,85,85] },
  [Terrain.MOUNTAIN]: { top: [75,75,80],   right: [54,54,58],   left: [62,62,68] },
  [Terrain.MAGMA]:    { top: [140,40,20],  right: [100,28,14],  left: [120,34,17] },
};

/** Pre-rendered tile sprite cache */
const spriteCache = new Map();

export function buildTileSprites() {
  for (const [type, colors] of Object.entries(TERRAIN_COLORS)) {
    for (let variant = 0; variant < 3; variant++) {
      const c = document.createElement('canvas');
      c.width = TILE_W + 2;
      c.height = TILE_H + 44;
      const x = c.getContext('2d');
      const cx = HALF_W + 1, cy = 22;
      const shift = variant * 4 - 4;

      // Diamond top face
      x.beginPath();
      x.moveTo(cx, cy - HALF_H);
      x.lineTo(cx + HALF_W, cy);
      x.lineTo(cx, cy + HALF_H);
      x.lineTo(cx - HALF_W, cy);
      x.closePath();
      const [r, g, b] = colors.top;
      x.fillStyle = `rgb(${r + shift},${g + shift},${b + shift})`;
      x.fill();

      // Highlight edge (top-left)
      x.beginPath();
      x.moveTo(cx, cy - HALF_H);
      x.lineTo(cx - HALF_W, cy);
      x.strokeStyle = 'rgba(255,255,200,0.08)';
      x.lineWidth = 1;
      x.stroke();

      // Shadow edge (bottom-right)
      x.beginPath();
      x.moveTo(cx + HALF_W, cy);
      x.lineTo(cx, cy + HALF_H);
      x.strokeStyle = 'rgba(0,0,0,0.15)';
      x.stroke();

      // Terrain-specific details
      const ti = parseInt(type);
      if (ti === Terrain.WATER) {
        _drawWaterDetail(x, cx, cy, variant);
      } else if (ti === Terrain.FOREST) {
        _drawTree(x, cx - 4 + variant * 3, cy, 0.9 + variant * 0.1);
      } else if (ti === Terrain.ROCK) {
        _drawStoneChunks(x, cx, cy);
      } else if (ti === Terrain.MOUNTAIN) {
        _drawMountainPeak(x, cx, cy, colors);
      } else if (ti === Terrain.MAGMA) {
        _drawMagmaGlow(x, cx, cy);
      }

      // Texture dots for all terrain
      for (let i = 0; i < 5; i++) {
        const px = cx + (Math.sin(variant * 30 + i * 47) * 12) | 0;
        const py = cy + (Math.cos(variant * 20 + i * 31) * 5) | 0;
        const [ar, ag, ab] = colors.right;
        x.fillStyle = `rgba(${ar},${ag},${ab},0.3)`;
        x.fillRect(px, py, 2, 1);
      }

      spriteCache.set(`tile_${type}_${variant}`, c);
    }
  }
}

function _drawWaterDetail(x, cx, cy, v) {
  x.strokeStyle = 'rgba(80,140,200,0.25)';
  x.lineWidth = 0.7;
  for (let i = 0; i < 2; i++) {
    const wy = cy - 3 + i * 6;
    x.beginPath();
    x.moveTo(cx - 10 + i * 4, wy);
    x.quadraticCurveTo(cx, wy - 2 + i, cx + 10 - i * 4, wy);
    x.stroke();
  }
}

function _drawTree(x, tx, ty, s) {
  x.fillStyle = '#4a3018';
  x.fillRect(tx - 1, ty - 4 * s, 3, 6 * s);
  const cols = ['#1a5a12', '#226a18', '#2a7a20'];
  for (let i = 0; i < 3; i++) {
    const yoff = ty - 6 * s - i * 5 * s;
    const w = 7 * s - i * 1.5 * s;
    x.fillStyle = cols[i];
    x.beginPath();
    x.moveTo(tx + 1, yoff - 5 * s);
    x.lineTo(tx + 1 - w, yoff + 3 * s);
    x.lineTo(tx + 1 + w, yoff + 3 * s);
    x.closePath();
    x.fill();
  }
}

function _drawStoneChunks(x, cx, cy) {
  x.fillStyle = 'rgba(140,140,140,0.5)';
  x.beginPath(); x.arc(cx - 6, cy - 2, 3, 0, Math.PI * 2); x.fill();
  x.fillStyle = 'rgba(110,110,110,0.5)';
  x.beginPath(); x.arc(cx + 5, cy + 1, 2.5, 0, Math.PI * 2); x.fill();
}

function _drawMountainPeak(x, cx, cy, colors) {
  const [br, bg, bb] = colors.right;
  x.fillStyle = `rgb(${br},${bg},${bb})`;
  x.beginPath();
  x.moveTo(cx - 8, cy + 2);
  x.lineTo(cx - 2, cy - 14);
  x.lineTo(cx + 4, cy - 10);
  x.lineTo(cx + 10, cy - 16);
  x.lineTo(cx + 14, cy + 2);
  x.closePath();
  x.fill();
  // Snow caps
  x.fillStyle = 'rgba(220,225,235,0.7)';
  x.beginPath();
  x.moveTo(cx - 2, cy - 14); x.lineTo(cx, cy - 10); x.lineTo(cx - 4, cy - 10);
  x.closePath(); x.fill();
  x.beginPath();
  x.moveTo(cx + 10, cy - 16); x.lineTo(cx + 12, cy - 12); x.lineTo(cx + 8, cy - 12);
  x.closePath(); x.fill();
}

function _drawMagmaGlow(x, cx, cy) {
  x.fillStyle = 'rgba(255,120,30,0.35)';
  x.beginPath(); x.arc(cx, cy, 6, 0, Math.PI * 2); x.fill();
  x.fillStyle = 'rgba(255,200,60,0.2)';
  x.beginPath(); x.arc(cx - 3, cy + 2, 3, 0, Math.PI * 2); x.fill();
}

export function getTileSprite(terrainType, variant) {
  return spriteCache.get(`tile_${terrainType}_${variant}`);
}

/** Render visible tiles */
export function renderTilemap(ctx, camera, world) {
  const bounds = camera.getVisibleBounds();
  const mw = world.width;
  const mh = world.height;

  for (let ty = bounds.minY; ty <= bounds.maxY; ty++) {
    for (let tx = bounds.minX; tx <= bounds.maxX; tx++) {
      if (tx < 0 || tx >= mw || ty < 0 || ty >= mh) continue;

      const terrain = world.getTerrain(tx, ty);
      const variant = (tx * 7 + ty * 13) % 3;
      const sprite = getTileSprite(terrain, variant);

      if (sprite) {
        const s = camera.tileToScreen(tx, ty);
        const z = camera.zoom;
        ctx.drawImage(
          sprite,
          s.x - HALF_W * z - z,
          s.y - 22 * z,
          (TILE_W + 2) * z,
          (TILE_H + 44) * z
        );
      }
    }
  }
}
