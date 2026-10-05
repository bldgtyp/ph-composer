/* A bar that floats over the bottom of a work surface while something there is selected: a count line, the
   controls its owner places in `controls`, and a clear icon. It sits in the work surface's overlay layer, so
   showing or hiding it never reflows the table; while it shows it pads the scroll area it covers by its own
   height, so the last rows stay reachable. It names no record and no field: the owner supplies the words,
   the controls and what clearing means. */
PhComposerUI.define("selection_bar", ["dom", "icons"], function (dom, icons) {
  "use strict";
  var FALLBACK_HEIGHT = 52, CLEARANCE = 16;

  function SelectionBar(label, onClear) {
    this.root = dom.element("div", "phc-selection-bar");
    this.root.setAttribute("role", "region");
    this.root.setAttribute("aria-label", label);
    this.count = dom.element("span", "phc-selection-bar-count");
    this.count.setAttribute("role", "status");
    this.controls = dom.element("div", "phc-selection-bar-controls");
    this.clear = icons.iconButton("Clear selection", "clear", function () { onClear(); });
    this.clear.classList.add("phc-selection-bar-clear");
    this.root.appendChild(this.count);
    this.root.appendChild(this.controls);
    this.root.appendChild(this.clear);
    this.root.hidden = true;
  }

  /* `text` is the count line, or empty for a bar that is all controls; `clearable` offers the clear icon. */
  SelectionBar.prototype.show = function (text, clearable) {
    if (this.count.textContent !== text) this.count.textContent = text;
    this.count.hidden = !text;
    this.clear.hidden = !clearable;
    this.root.hidden = false;
  };

  SelectionBar.prototype.hide = function () { this.root.hidden = true; };

  /* Pads `scroll` by the bar's height while it shows, and gives the padding back when it goes. */
  SelectionBar.prototype.reserve = function (scroll) {
    var height = this.root.hidden ? 0 : (this.root.offsetHeight || FALLBACK_HEIGHT) + CLEARANCE;
    scroll.style.paddingBottom = height ? height + "px" : "";
  };

  return { SelectionBar: SelectionBar };
});
