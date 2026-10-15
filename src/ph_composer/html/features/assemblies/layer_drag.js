/* Drag a whole Layer by its grip to another place in the stored order. The drawing stays still while a small
   ghost follows the pointer and a line marks the boundary the Layer would land on. A changed drop sends one
   layers.reorder action; Escape, leaving the window, a release outside, a repaint and disposal send nothing. */
PhComposerUI.define("features/assemblies/layer_drag", ["workspace"], function (ui) {
  "use strict";
  var el = ui.element;
  // Pointer travel, in squared pixels, before a press becomes a drag, as for a library row.
  var THRESHOLD_SQ = 36;
  // A release this far beyond the drawing's frame, on any side, is outside: it drops nothing.
  var OUTSIDE_PX = 40;

  /* The Layer boundary nearest the pointer, 0 above the first Layer to n below the last. Distances are drawing
     geometry, so a membrane's thin band reaches its boundaries as well as a thick Layer does. */
  function nearestBoundary(layout, zoom, drawingRect, clientY) {
    var y = (clientY - drawingRect.top) / zoom, last = layout.layers[layout.layers.length - 1];
    var boundaries = layout.layers.map(function (entry) { return entry.yMm; }).concat([last.yMm + last.heightMm]);
    return boundaries.reduce(function (best, at, index) {
      return Math.abs(at - y) < Math.abs(boundaries[best] - y) ? index : best;
    }, 0);
  }
  /* The stored index the Layer at sourceIndex takes when dropped at clientY. It leaves its own place first, so a
     boundary below it is one index lower; either boundary of the Layer itself is its current index. The drawing
     draws the stored order top to bottom in both orientations, so orientation does not enter. */
  function dropIndex(layout, zoom, drawingRect, clientY, sourceIndex) {
    var boundary = nearestBoundary(layout, zoom, drawingRect, clientY);
    return boundary <= sourceIndex ? boundary : boundary - 1;
  }
  function outside(rect, event) {
    return event.clientX < rect.left - OUTSIDE_PX || event.clientX > rect.right + OUTSIDE_PX ||
      event.clientY < rect.top - OUTSIDE_PX || event.clientY > rect.bottom + OUTSIDE_PX;
  }
  function detach(node) { if (node && node.parentNode) node.parentNode.removeChild(node); }

  /* One per Builder: at most one Layer is held at a time. The owner is the Editor; it supplies the zoom, the
     guards, the shared dragging flag and the one action. */
  function LayerDrag(owner) {
    var self = this;
    this.owner = owner;
    this.held = null;
    this.move = function (event) { self.track(event); };
    this.up = function (event) { self.release(event); };
    this.key = function (event) {
      if (event.key !== "Escape" || !self.held) return;
      if (self.active()) { event.preventDefault(); event.stopImmediatePropagation(); }
      self.end();
    };
    this.blur = function () { self.end(); };
  }
  LayerDrag.prototype.active = function () { return Boolean(this.held && this.held.ghost); };
  /* Wires one grip. `context` is that Layer's id and index with the layout, the drawing and its frame. */
  LayerDrag.prototype.bind = function (grip, context) {
    var self = this;
    grip.addEventListener("mousedown", function (event) { self.press(event, context); });
    // The browser's trailing click after a drag must not reach anything; a plain click does nothing anyway.
    grip.addEventListener("click", function (event) {
      if (context.suppressClick) { event.preventDefault(); event.stopPropagation(); }
    });
  };
  LayerDrag.prototype.press = function (event, context) {
    var owner = this.owner;
    if (event.button !== 0) return;
    this.end();
    if (owner.dragging) { owner.notice("Finish dragging the Material first."); return; }
    if (!owner.allowed()) return;
    context.suppressClick = false;
    this.held = { context: context, x: event.clientX, y: event.clientY, index: context.index, outside: false };
    document.addEventListener("mousemove", this.move);
    document.addEventListener("mouseup", this.up);
    document.addEventListener("keydown", this.key, true);
    window.addEventListener("blur", this.blur);
  };
  LayerDrag.prototype.begin = function () {
    var held = this.held, context = held.context;
    context.suppressClick = true;
    this.owner.dragging = true;
    ui.Bubble.closeActive();
    held.ghost = el("div", "assembly-drag-ghost", "Layer " + (context.index + 1));
    held.ghost.setAttribute("aria-hidden", "true");
    held.line = el("div", "assembly-drop-line");
    held.line.setAttribute("aria-hidden", "true");
    document.body.appendChild(held.ghost);
    context.drawing.appendChild(held.line);
    document.body.classList.add("is-dragging", "assembly-layer-dragging");
  };
  /* Every move re-reads the drawing's box, so a stage scrolled by the wheel mid-drag still drops true. */
  LayerDrag.prototype.track = function (event) {
    var held = this.held;
    if (!held) return;
    var dx = event.clientX - held.x, dy = event.clientY - held.y;
    if (!held.ghost && dx * dx + dy * dy <= THRESHOLD_SQ) return;
    if (!held.ghost) this.begin();
    if (event.preventDefault) event.preventDefault(); // no text selection starts under the ghost
    var context = held.context, zoom = this.owner.zoom, layout = context.layout;
    var rect = context.drawing.getBoundingClientRect();
    var boundary = nearestBoundary(layout, zoom, rect, event.clientY);
    var at = boundary < layout.layers.length ? layout.layers[boundary].yMm :
      layout.layers[boundary - 1].yMm + layout.layers[boundary - 1].heightMm;
    held.index = boundary <= context.index ? boundary : boundary - 1;
    held.outside = outside(context.frame.getBoundingClientRect(), event);
    held.line.style.top = at * zoom + "px";
    held.line.hidden = held.outside;
    held.line.classList.toggle("is-noop", held.index === context.index);
    var width = held.ghost.offsetWidth || 0, height = held.ghost.offsetHeight || 0;
    held.ghost.style.left = Math.max(0, Math.min(event.clientX + 12, window.innerWidth - width - 4)) + "px";
    held.ghost.style.top = Math.max(0, Math.min(event.clientY + 12, window.innerHeight - height - 4)) + "px";
  };
  /* The drag ends before the action is sent, so the Builder's own guard sees no drag in progress. */
  LayerDrag.prototype.release = function (event) {
    var held = this.held;
    if (held && held.ghost) this.track(event);
    this.end();
    if (!held || !held.ghost || held.outside || held.index === held.context.index) return;
    this.owner.action("layers.reorder", { layer_id: held.context.layerId, index: held.index });
  };
  LayerDrag.prototype.end = function () {
    var held = this.held;
    if (!held) return;
    this.held = null;
    document.removeEventListener("mousemove", this.move);
    document.removeEventListener("mouseup", this.up);
    document.removeEventListener("keydown", this.key, true);
    window.removeEventListener("blur", this.blur);
    if (!held.ghost) return;
    detach(held.ghost);
    detach(held.line);
    document.body.classList.remove("is-dragging", "assembly-layer-dragging");
    this.owner.dragging = false;
    // The trailing click arrives in this task; a later click on the grip is the user's own.
    window.setTimeout(function () { held.context.suppressClick = false; }, 0);
  };

  return { LayerDrag: LayerDrag, dropIndex: dropIndex };
});
