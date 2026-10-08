/* Drawing dimensions in screen coordinates. Owners supply formatted values and resize callbacks;
   this module has no units, records, validation or host operations. */
PhComposerUI.define("drawing_dimensions", ["dom"], function (dom) {
  "use strict";
  /* One graphic rule with boundary dots and short extensions toward the measured geometry.
     All coordinates are SVG coordinates; scale keeps dots legible when the drawing is zoomed. */
  function rule(options) {
    var horizontal = options.axis === "horizontal", at = options.at, scale = options.scale || 1;
    var root = dom.svg("g", { "class": "phc-dimension-lines", "aria-hidden": "true" });
    root.appendChild(dom.svg("line", horizontal ?
      { x1: options.from, y1: at, x2: options.to, y2: at } :
      { x1: at, y1: options.from, x2: at, y2: options.to }));
    options.points.forEach(function (point) {
      root.appendChild(dom.svg("line", horizontal ?
        { x1: point, y1: options.extension, x2: point, y2: at } :
        { x1: at, y1: point, x2: options.extension, y2: point }));
      root.appendChild(dom.svg("circle", { cx: horizontal ? point : at,
        cy: horizontal ? at : point, r: 2.5 * scale }));
    });
    return root;
  }
  /* An HTML button for an editor, or an accessible SVG value with an owner's activation callback.
     Keeping the HTML anchor untransformed lets a fixed-position Bubble use viewport coordinates. */
  function value(options) {
    var node = options.svg ? dom.svg("text", options.svg, options.text) :
      dom.button(options.text, options.activate);
    node.setAttribute("class", "phc-dimension-value" + (options.className ? " " + options.className : ""));
    if (options.label) node.setAttribute("aria-label", options.label);
    if (options.svg && options.activate) {
      node.setAttribute("tabindex", "0"); node.setAttribute("role", "button");
      node.addEventListener("click", options.activate);
      node.addEventListener("keydown", function (event) {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault(); options.activate(event);
        }
      });
    }
    return node;
  }
  /* Swap a dimension's value for its owner's unit-bearing input, in the same layout slot.
     The owner keeps parsing, cancellation, pending/refused drafts and Model writes. */
  function inline(options) {
    var root = dom.element("span", "phc-dimension-inline" + (options.compact ? " is-compact" : ""));
    var trigger = options.trigger, editor = options.editor;
    root.appendChild(trigger); root.appendChild(editor);
    function show(active, focusTrigger) {
      trigger.hidden = Boolean(active); editor.hidden = !active;
      root.classList.toggle("is-editing", Boolean(active));
      if (!active && focusTrigger) trigger.focus({ preventScroll: true });
    }
    trigger.addEventListener("click", function () {
      if (options.begin && options.begin() === false) return;
      show(true);
      options.input.focus({ preventScroll: true }); options.input.select();
    });
    show(options.active);
    return { root: root, trigger: trigger, show: show };
  }
  return { rule: rule, value: value, inline: inline };
});
