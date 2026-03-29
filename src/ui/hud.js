// ============================================================
//  hud.js — Heads-Up Display overlay
// ============================================================

export class HUD {
  constructor(ctx) {
    this.ctx = ctx;
  }

  /** Draw resource bar at top of screen */
  drawResourceBar(resources, w) {
    const ctx = this.ctx;
    const barH = 32;

    // Background
    ctx.fillStyle = 'rgba(0,0,0,0.75)';
    ctx.fillRect(0, 0, w, barH);
    ctx.strokeStyle = 'rgba(255,255,255,0.15)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, barH);
    ctx.lineTo(w, barH);
    ctx.stroke();

    ctx.font = '13px monospace';
    ctx.textBaseline = 'middle';
    const y = barH / 2;
    let x = 12;

    const items = [
      { icon: '\uD83C\uDF3E', label: 'Food', val: Math.floor(resources.food), color: '#8ab648' },
      { icon: '\u26F0', label: 'Stone', val: Math.floor(resources.stone), color: '#a0a0a0' },
      { icon: '\uD83D\uDD29', label: 'Parts', val: Math.floor(resources.parts), color: '#c09050' },
      { icon: '\uD83D\uDC64', label: 'Pop', val: `${resources.population}/${resources.maxPopulation}`, color: '#70b8e8' },
      { icon: '\uD83D\uDD2C', label: 'Tech', val: Math.floor(resources.techPoints), color: '#d0a0ff' },
    ];

    for (const item of items) {
      ctx.fillStyle = item.color;
      ctx.fillText(`${item.icon} ${item.label}: ${item.val}`, x, y);
      x += ctx.measureText(`${item.icon} ${item.label}: ${item.val}`).width + 24;
    }
  }

  /** Draw selection info panel at bottom */
  drawSelectionPanel(selected, w, h) {
    if (!selected || selected.length === 0) return;
    const ctx = this.ctx;
    const panelH = 80;
    const panelY = h - panelH;

    // Background
    ctx.fillStyle = 'rgba(0,0,0,0.75)';
    ctx.fillRect(0, panelY, w, panelH);
    ctx.strokeStyle = 'rgba(255,255,255,0.15)';
    ctx.beginPath();
    ctx.moveTo(0, panelY);
    ctx.lineTo(w, panelY);
    ctx.stroke();

    if (selected.length === 1) {
      const e = selected[0];
      const x = 16, y = panelY + 14;

      // Name and icon
      ctx.font = 'bold 15px monospace';
      ctx.fillStyle = '#ffffff';
      ctx.fillText(`${e.icon || ''} ${e.name}`, x, y);

      // HP bar
      ctx.font = '12px monospace';
      const hpRatio = e.hp / e.maxHp;
      const barW = 120, barH = 8;
      const barX = x, barY = y + 12;
      ctx.fillStyle = '#333';
      ctx.fillRect(barX, barY, barW, barH);
      ctx.fillStyle = hpRatio > 0.5 ? '#4a8' : hpRatio > 0.25 ? '#c84' : '#c44';
      ctx.fillRect(barX, barY, barW * hpRatio, barH);

      // Stats
      ctx.fillStyle = '#ccc';
      ctx.fillText(`HP: ${Math.ceil(e.hp)}/${e.maxHp}`, x, barY + 22);

      if (e.damage) {
        ctx.fillText(`DMG: ${e.damage.base}  ARM: ${e.armor}  SPD: ${e.speed}`, x + 150, barY + 22);
      }

      if (e.hunger !== undefined) {
        const hungerPct = Math.floor((e.hunger / e.maxHunger) * 100);
        ctx.fillStyle = hungerPct > 70 ? '#ff6644' : '#ccc';
        ctx.fillText(`Hunger: ${hungerPct}%`, x + 400, barY + 22);
      }

      if (e.state) {
        ctx.fillStyle = '#888';
        ctx.fillText(`[${e.state}]`, x, barY + 40);
      }
    } else {
      // Multi-selection
      ctx.font = '14px monospace';
      ctx.fillStyle = '#ffffff';
      ctx.fillText(`${selected.length} units selected`, 16, panelY + 20);

      // Show icons of selected types
      const counts = {};
      for (const u of selected) {
        const k = u.name || u.type;
        counts[k] = (counts[k] || 0) + 1;
      }
      let x = 16;
      ctx.font = '12px monospace';
      ctx.fillStyle = '#ccc';
      let row = panelY + 42;
      for (const [name, count] of Object.entries(counts)) {
        const text = `${name} x${count}`;
        ctx.fillText(text, x, row);
        x += ctx.measureText(text).width + 16;
        if (x > w - 100) { x = 16; row += 16; }
      }
    }
  }

  /** Draw selection rectangle while dragging */
  drawSelectionBox(box) {
    if (!box) return;
    const ctx = this.ctx;
    const x = Math.min(box.x1, box.x2);
    const y = Math.min(box.y1, box.y2);
    const w = Math.abs(box.x2 - box.x1);
    const h = Math.abs(box.y2 - box.y1);

    ctx.strokeStyle = '#4af';
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 4]);
    ctx.strokeRect(x, y, w, h);
    ctx.setLineDash([]);
    ctx.fillStyle = 'rgba(68,170,255,0.1)';
    ctx.fillRect(x, y, w, h);
  }

  /** Draw minimap */
  drawMinimap(world, camera, entities, w, h) {
    const size = 150;
    const mx = w - size - 10;
    const my = h - size - 10;

    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.8)';
    ctx.fillRect(mx - 2, my - 2, size + 4, size + 4);
    ctx.strokeStyle = 'rgba(255,255,255,0.3)';
    ctx.strokeRect(mx - 2, my - 2, size + 4, size + 4);

    const scaleX = size / world.width;
    const scaleY = size / world.height;

    const terrainColors = ['#1a3a5a','#326423','#645028','#a08c50','#234a1a','#646464','#4b4b50','#8c2814'];

    // Draw terrain
    const step = Math.max(1, Math.floor(world.width / size));
    for (let ty = 0; ty < world.height; ty += step) {
      for (let tx = 0; tx < world.width; tx += step) {
        const t = world.getTerrain(tx, ty);
        ctx.fillStyle = terrainColors[t] || '#000';
        ctx.fillRect(mx + tx * scaleX, my + ty * scaleY, Math.ceil(scaleX * step), Math.ceil(scaleY * step));
      }
    }

    // Draw units as dots
    for (const u of entities.units) {
      if (u.dead) continue;
      ctx.fillStyle = u.owner === 0 ? '#4af' : u.owner > 0 ? '#f44' : '#ff0';
      ctx.fillRect(mx + u.x * scaleX - 1, my + u.y * scaleY - 1, 2, 2);
    }

    // Draw camera viewport rectangle
    const tl = camera.screenToTile(0, 0);
    const br = camera.screenToTile(camera.w, camera.h);
    ctx.strokeStyle = '#fff';
    ctx.lineWidth = 1;
    ctx.strokeRect(
      mx + tl.x * scaleX,
      my + tl.y * scaleY,
      (br.x - tl.x) * scaleX,
      (br.y - tl.y) * scaleY
    );
  }
}
