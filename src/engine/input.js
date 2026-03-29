// ============================================================
//  input.js — Mouse, keyboard, and selection handling
// ============================================================

export class InputManager {
  constructor(canvas) {
    this.canvas = canvas;
    this.mouseX = 0;
    this.mouseY = 0;
    this.mouseDown = false;
    this.rightDown = false;
    this.keys = {};
    this.selectionBox = null;   // {x1, y1, x2, y2} during drag
    this.clickHandlers = [];
    this.rightClickHandlers = [];
    this.wheelHandlers = [];

    this._setup();
  }

  _setup() {
    const C = this.canvas;

    C.addEventListener('mousedown', e => {
      const r = C.getBoundingClientRect();
      const mx = e.clientX - r.left;
      const my = e.clientY - r.top;

      if (e.button === 0) {
        this.mouseDown = true;
        this.selectionBox = { x1: mx, y1: my, x2: mx, y2: my };
      }
      if (e.button === 2) {
        this.rightDown = true;
      }
    });

    C.addEventListener('mouseup', e => {
      if (e.button === 0 && this.mouseDown) {
        this.mouseDown = false;
        const box = this.selectionBox;
        if (box) {
          const w = Math.abs(box.x2 - box.x1);
          const h = Math.abs(box.y2 - box.y1);
          const isClick = w < 5 && h < 5;

          for (const handler of this.clickHandlers) {
            handler(box, isClick);
          }
          this.selectionBox = null;
        }
      }
      if (e.button === 2) {
        this.rightDown = false;
        for (const handler of this.rightClickHandlers) {
          handler(this.mouseX, this.mouseY);
        }
      }
    });

    C.addEventListener('mousemove', e => {
      const r = C.getBoundingClientRect();
      this.mouseX = e.clientX - r.left;
      this.mouseY = e.clientY - r.top;
      if (this.mouseDown && this.selectionBox) {
        this.selectionBox.x2 = this.mouseX;
        this.selectionBox.y2 = this.mouseY;
      }
    });

    C.addEventListener('contextmenu', e => e.preventDefault());

    C.addEventListener('wheel', e => {
      for (const handler of this.wheelHandlers) {
        handler(e.deltaY, this.mouseX, this.mouseY);
      }
    });

    document.addEventListener('keydown', e => {
      this.keys[e.key.toLowerCase()] = true;
    });

    document.addEventListener('keyup', e => {
      this.keys[e.key.toLowerCase()] = false;
    });
  }

  onClick(handler) { this.clickHandlers.push(handler); }
  onRightClick(handler) { this.rightClickHandlers.push(handler); }
  onWheel(handler) { this.wheelHandlers.push(handler); }
}
