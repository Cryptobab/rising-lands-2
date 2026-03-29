// ============================================================
//  particles.js — Lightweight particle system for effects
// ============================================================

export class ParticleSystem {
  constructor(maxParticles = 500) {
    this.particles = [];
    this.max = maxParticles;
  }

  /** Spawn a single particle */
  emit(x, y, vx, vy, color, life, size = 2) {
    if (this.particles.length >= this.max) return;
    this.particles.push({
      x, y, vx, vy, color, life, maxLife: life, size, alpha: 1
    });
  }

  /** Burst of N particles from a point */
  burst(x, y, count, color, spread = 3, life = 30, size = 2) {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = Math.random() * spread;
      this.emit(
        x, y,
        Math.cos(angle) * speed,
        Math.sin(angle) * speed,
        color, life + Math.random() * 10, size
      );
    }
  }

  /** Death explosion effect */
  deathEffect(x, y) {
    this.burst(x, y, 12, '#ff4a2a', 2.5, 25, 2.5);
    this.burst(x, y, 6, '#ffaa40', 1.5, 18, 1.5);
  }

  /** Construction sparkle */
  buildEffect(x, y) {
    this.burst(x, y, 4, '#aac8ff', 1, 15, 1.5);
  }

  /** Gathering resource pop */
  gatherEffect(x, y, type) {
    const colors = { food: '#5a8a2a', stone: '#8a8a8a', metal: '#8a6030' };
    this.burst(x, y, 3, colors[type] || '#ffffff', 1.5, 12, 2);
  }

  update() {
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.05; // Gravity
      p.vx *= 0.98; // Friction
      p.life--;
      p.alpha = Math.max(0, p.life / p.maxLife);

      if (p.life <= 0) {
        this.particles.splice(i, 1);
      }
    }
  }

  render(ctx) {
    for (const p of this.particles) {
      ctx.globalAlpha = p.alpha;
      ctx.fillStyle = p.color;
      ctx.fillRect(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size);
    }
    ctx.globalAlpha = 1;
  }
}
