// ============================================================
//  canvas.js — Isometric rendering engine with camera system
// ============================================================

export class Camera {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.x = 0;          // World offset X
    this.y = 0;          // World offset Y
    this.zoom = 1.0;
    this.minZoom = 0.3;
    this.maxZoom = 2.5;
    this.panSpeed = 8;
    this.edgeScrollSize = 20;
    this.shakeAmount = 0;
    this.shakeDecay = 0.9;

    this.resize();
    window.addEventListener('resize', () => this.resize());
  }

  resize() {
    this.canvas.width = window.innerWidth;
    this.canvas.height = window.innerHeight;
    this.w = this.canvas.width;
    this.h = this.canvas.height;
  }

  /** Convert tile coords to screen pixel coords */
  tileToScreen(tx, ty) {
    return {
      x: (tx - ty) * 32 * this.zoom + this.x,
      y: (tx + ty) * 16 * this.zoom + this.y
    };
  }

  /** Convert screen pixel coords to tile coords */
  screenToTile(sx, sy) {
    const rx = (sx - this.x) / this.zoom;
    const ry = (sy - this.y) / this.zoom;
    return {
      x: Math.floor((rx / 32 + ry / 16) / 2),
      y: Math.floor((ry / 16 - rx / 32) / 2)
    };
  }

  /** Center camera on a tile position */
  centerOn(tx, ty) {
    const s = this.tileToScreen(tx, ty);
    this.x += this.w / 2 - s.x;
    this.y += this.h / 2 - s.y;
  }

  /** Apply zoom centered on a screen point */
  zoomAt(sx, sy, delta) {
    const oldZoom = this.zoom;
    this.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.zoom + delta));
    const ratio = this.zoom / oldZoom;
    this.x = sx - (sx - this.x) * ratio;
    this.y = sy - (sy - this.y) * ratio;
  }

  /** Edge-scroll and keyboard camera movement */
  update(mouseX, mouseY, keys) {
    const sp = this.panSpeed;
    const edge = this.edgeScrollSize;

    if (mouseX < edge || keys['arrowleft'] || keys['a']) this.x += sp;
    if (mouseX > this.w - edge || keys['arrowright'] || keys['d']) this.x -= sp;
    if (mouseY < edge + 36 || keys['arrowup'] || keys['w']) this.y += sp;
    if (mouseY > this.h - edge || keys['arrowdown'] || keys['s']) this.y -= sp;

    // Screen shake
    if (this.shakeAmount > 0.5) {
      this.x += (Math.random() - 0.5) * this.shakeAmount;
      this.y += (Math.random() - 0.5) * this.shakeAmount;
      this.shakeAmount *= this.shakeDecay;
    }
  }

  shake(amount = 6) {
    this.shakeAmount = amount;
  }

  /** Get visible tile bounds for culling */
  getVisibleBounds() {
    const tl = this.screenToTile(0, 0);
    const br = this.screenToTile(this.w, this.h);
    return {
      minX: tl.x - 2,
      minY: tl.y - 2,
      maxX: br.x + 2,
      maxY: br.y + 2
    };
  }

  clear() {
    this.ctx.fillStyle = '#0a0a0a';
    this.ctx.fillRect(0, 0, this.w, this.h);
  }
}
