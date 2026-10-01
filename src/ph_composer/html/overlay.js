/* Anchored and modal surfaces: the bubble, the action menu, record-form dialogs, floating notices, and the
   tooltip layer tables attach. Only one top-level bubble is open across the workspace. */
PhComposerUI.define("overlay", ["dom", "icons"], function (dom, icons) {
  "use strict";
  var element = dom.element, button = dom.button, glyph = icons.glyph, iconButton = icons.iconButton;

  /* Shared non-modal, anchored editor. Only one bubble is open across the workspace. */
  var activeBubble = null, bubbleSequence = 0;
  function Bubble(trigger, title, options) {
    var self = this;
    this.options = options || {}; this.children = [];
    if (this.options.parent) this.options.parent.children.push(this);
    this.trigger = trigger; this.root = element("div", "phc-bubble-anchor");
    this.panel = element("section", "phc-bubble"); this.panel.hidden = true;
    this.panel._bubble = this;
    this.panel.setAttribute("role", "dialog"); this.panel.setAttribute("aria-label", title);
    this.panel.setAttribute("id", "phc-bubble-" + (++bubbleSequence));
    trigger.setAttribute("aria-controls", this.panel.getAttribute("id"));
    trigger.setAttribute("aria-expanded", "false");
    var header = element("div", "phc-bubble-heading"); header.appendChild(element("strong", "", title));
    var close = button("×", function () { self.close(true); }); close.setAttribute("aria-label", "Close " + title);
    header.appendChild(close); this.panel.appendChild(header); this.heading = header; this.closeButton = close;
    this.content = element("div", "phc-bubble-content"); this.panel.appendChild(this.content);
    this.root.appendChild(trigger); this.root.appendChild(this.panel);
    if (!this.options.ownTrigger) {
      trigger.addEventListener("click", function () { self.toggle(); });
      trigger.addEventListener("keydown", function (event) {
        if (event.key === "ArrowRight" || event.key === "ArrowDown") { event.preventDefault(); self.open(); }
      });
    }
    if (this.options.hover) {
      trigger.addEventListener("mouseenter", function (event) {
        self.cancelHover();
        // A drag in progress (the body carries `is-dragging`) never opens a hover bubble.
        if (event.buttons || document.body.classList.contains("is-dragging")) return;
        self.hoverTimer = window.setTimeout(function () {
          self.hoverTimer = null;
          if (self.root.isConnected && trigger.matches(":hover") &&
            !document.body.classList.contains("is-dragging")) self.open(false);
        }, 450);
      });
      trigger.addEventListener("mouseleave", function () { self.cancelHover(); });
      this.root.addEventListener("mouseleave", function () {
        if (window.setTimeout) window.setTimeout(function () {
          if (!self.root.matches(":hover") && !self.panel.contains(document.activeElement)) self.close(false);
        }, 220);
      });
    }
    this.root.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && !self.panel.hidden && !event.defaultPrevented) {
        event.preventDefault(); self.close(true);
      }
    });
  }
  Bubble.prototype.cancelHover = function () {
    if (this.hoverTimer != null) window.clearTimeout(this.hoverTimer);
    this.hoverTimer = null;
  };
  Bubble.prototype.toggle = function () { if (this.panel.hidden) this.open(); else this.close(true); };
  Bubble.prototype.open = function (focusInput) {
    this.cancelHover();
    if (document.body.classList.contains("is-dragging")) return;
    if (this.options.parent) {
      this.options.parent.open(false);
      var self = this; this.options.parent.children.forEach(function (child) {
        if (child !== self) child.close(false);
      });
    }
    if (!this.options.parent && activeBubble && activeBubble !== this && activeBubble.close(false) === false) return;
    if (!this.options.parent) activeBubble = this;
    this.panel.hidden = false;
    this.trigger.setAttribute("aria-expanded", "true");
    this.position();
    if (this.options.onOpen) this.options.onOpen(this);
    var panel = this.panel;
    var content = this.content;
    var candidates = ["input", "select", "button"].reduce(function (all, tag) {
      return all.concat(Array.prototype.slice.call(content.querySelectorAll(tag)));
    }, []);
    var focus = candidates.filter(function (node) {
      for (var current = node; current && current !== panel; current = current.parentNode) {
        if (current.hidden) return false;
      }
      return !node.disabled;
    })[0];
    if (focus && focusInput !== false) focus.focus({ preventScroll: true });
  };
  /* Placement, in CSS pixels. A bubble sits BUBBLE.GAP from its trigger and at least BUBBLE.MARGIN inside the
     viewport; the fallbacks stand in for a measurement the host has not produced yet (a hidden panel). */
  var BUBBLE = {
    MARGIN: 12, GAP: 10, SIDE_GAP: 8, SIDE_ROOM: 20, CONTENT_CLEARANCE: 22, CONTENT_CHROME: 16,
    FALLBACK_CHROME: 60, FALLBACK_VIEWPORT: { width: 1024, height: 768 }, FALLBACK_BOX: { width: 300, height: 250 },
    FALLBACK_TRIGGER: 30, POINTER_EDGE: 12, POINTER_INSET: 20, SUBMENU_POINTER_TOP: 18, SUBMENU_POINTER_BOTTOM: 24
  };
  Bubble.prototype.position = function () {
    // Measure natural height; a clamp left by an earlier placement would understate what the content needs.
    this.content.style.maxHeight = "";
    var anchor = this.trigger.getBoundingClientRect(), box = this.panel.getBoundingClientRect();
    var view = { width: window.innerWidth || BUBBLE.FALLBACK_VIEWPORT.width,
      height: window.innerHeight || BUBBLE.FALLBACK_VIEWPORT.height };
    var size = { width: box.width || BUBBLE.FALLBACK_BOX.width, height: box.height || BUBBLE.FALLBACK_BOX.height };
    var sideFits = anchor.right + size.width + BUBBLE.SIDE_ROOM <= view.width ||
      anchor.left >= size.width + BUBBLE.SIDE_ROOM;
    if (this.options.parent || (this.options.side && sideFits)) this.positionSubmenu(anchor, size, view);
    else this.positionAnchored(anchor, box, size, view);
  };
  /* Beside the trigger, flipping to its left when the right side has no room; the pointer tracks the
     trigger's middle. */
  Bubble.prototype.positionSubmenu = function (anchor, size, view) {
    var flip = anchor.right + size.width + BUBBLE.GAP > view.width;
    var left = Math.max(BUBBLE.MARGIN,
      flip ? anchor.left - size.width - BUBBLE.SIDE_GAP : anchor.right + BUBBLE.SIDE_GAP);
    var top = Math.max(BUBBLE.MARGIN, Math.min(anchor.top, view.height - size.height - BUBBLE.MARGIN));
    this.panel.classList.remove("pointer-hidden");
    this.panel.classList.remove("is-above");
    this.panel.style.left = left + "px";
    this.panel.style.top = top + "px";
    this.panel.classList.add("is-submenu"); this.panel.classList[flip ? "add" : "remove"]("opens-left");
    var middle = anchor.top + (anchor.height || BUBBLE.FALLBACK_TRIGGER) / 2 - top;
    this.panel.style.setProperty("--bubble-pointer-y", Math.max(BUBBLE.SUBMENU_POINTER_TOP,
      Math.min(size.height - BUBBLE.SUBMENU_POINTER_BOTTOM, middle)) + "px");
  };
  /* Below the trigger, or above it when the box does not fit below and above offers more room; the content then
     scrolls within the room it has. The pointer hides when clamping moved the box off the trigger. */
  Bubble.prototype.positionAnchored = function (anchor, box, size, view) {
    var above = anchor.bottom + size.height + BUBBLE.MARGIN > view.height &&
      anchor.top > Math.min(size.height + BUBBLE.MARGIN, view.height - anchor.bottom);
    this.panel.classList.remove("is-submenu");
    this.panel.classList.remove("opens-left");
    var contentBox = this.content.getBoundingClientRect();
    var panelChrome = typeof contentBox.top === "number" && typeof box.top === "number" && contentBox.top > box.top ?
      contentBox.top - box.top + BUBBLE.CONTENT_CHROME : BUBBLE.FALLBACK_CHROME;
    var available = (above ? anchor.top : view.height - anchor.bottom) - BUBBLE.CONTENT_CLEARANCE;
    this.content.style.maxHeight = Math.max(0, available - panelChrome) + "px";
    box = this.panel.getBoundingClientRect();
    var width = box.width || size.width, height = box.height || size.height;
    var left = Math.max(BUBBLE.MARGIN, Math.min(anchor.left, view.width - width - BUBBLE.MARGIN));
    this.panel.style.left = left + "px";
    var top = above ? anchor.top - height - BUBBLE.GAP : anchor.bottom + BUBBLE.GAP;
    var finalTop = Math.max(BUBBLE.MARGIN, Math.min(top, view.height - height - BUBBLE.MARGIN));
    this.panel.style.top = finalTop + "px";
    this.panel.classList[above ? "add" : "remove"]("is-above");
    var pointer = anchor.left + (anchor.width || BUBBLE.FALLBACK_TRIGGER) / 2 - left;
    this.panel.classList[finalTop !== top || pointer < BUBBLE.POINTER_EDGE ||
      pointer > width - BUBBLE.POINTER_EDGE ? "add" : "remove"]("pointer-hidden");
    this.panel.style.setProperty("--bubble-pointer",
      Math.max(BUBBLE.POINTER_INSET, Math.min(width - BUBBLE.POINTER_INSET, pointer)) + "px");
  };
  /* Below an anchor, or above it when there is no room below, clamped to the viewport: for popovers that are not
     bubbles (the colour form). */
  function placeNear(anchor, size, gap, margin) {
    var left = Math.max(margin, Math.min(anchor.left, window.innerWidth - size.width - margin));
    var top = anchor.bottom + gap;
    if (top + size.height > window.innerHeight - margin) top = anchor.top - size.height - gap;
    return { left: left, top: Math.max(margin, Math.min(top, window.innerHeight - size.height - margin)) };
  }
  Bubble.prototype.close = function (focus) {
    var reason = this.options.guard && this.options.guard();
    if (reason) {
      if (this.options.refused) this.options.refused(reason);
      return false;
    }
    this.cancelHover();
    this.children.forEach(function (child) { child.close(false); });
    this.panel.hidden = true; this.trigger.setAttribute("aria-expanded", "false");
    if (activeBubble === this) activeBubble = null;
    if (focus) this.trigger.focus({ preventScroll: true });
    return true;
  };
  Bubble.prototype.deepest = function () {
    var child = this.children.filter(function (item) { return !item.panel.hidden; })[0];
    return child ? child.deepest() : this;
  };
  Bubble.activeTitle = function (owner) {
    return activeBubble && (!owner || owner.contains(activeBubble.root)) &&
      activeBubble.deepest().panel.getAttribute("aria-label");
  };
  Bubble.closeActive = function (owner) {
    if (activeBubble && (!owner || owner.contains(activeBubble.root))) activeBubble.close(false);
  };
  if (document.addEventListener) {
    document.addEventListener("mousedown", function (event) {
      if (activeBubble && !activeBubble.root.contains(event.target)) activeBubble.close(false);
    });
    document.addEventListener("scroll", function (event) {
      if (activeBubble && !activeBubble.panel.contains(event.target)) activeBubble.close(false);
    }, true);
  }
  if (window.addEventListener) window.addEventListener("resize", function () {
    if (activeBubble) activeBubble.position();
  });
  function floatingNotice(owner) {
    var root = element("div", "phc-notice phc-floating-notice"),
      message = element("span", "phc-floating-notice-message");
    var revision = 0, persistent = false;
    message.setAttribute("role", "status");
    message.setAttribute("aria-live", "polite");
    message.setAttribute("aria-atomic", "true");
    var dismiss = iconButton("Dismiss message", "clear", function () { root.clear(); });
    dismiss.classList.add("phc-floating-notice-dismiss");
    root.appendChild(message);
    root.appendChild(dismiss);
    root.hidden = true;
    root.message = message; root.dismissButton = dismiss;
    root.show = function (text, options) {
      revision += 1; persistent = Boolean(options && options.persistent); root.classList.remove("is-dismissing");
      message.textContent = text || "";
      root.hidden = !message.textContent;
      root.setAttribute("data-persistent", String(persistent));
      // Information and instructions are neutral; yellow is kept for warnings and red for errors.
      root.setAttribute("data-tone", (options && options.tone) || "info");
    };
    root.clear = function () {
      revision += 1;
      persistent = false;
      root.classList.remove("is-dismissing");
      message.textContent = "";
      root.hidden = true;
    };
    root.fade = function () {
      if (root.hidden || persistent || root.classList.contains("is-dismissing")) return;
      var current = ++revision; root.classList.add("is-dismissing");
      if (!window.setTimeout) { root.clear(); return; }
      window.setTimeout(function () { if (current === revision) root.clear(); }, 180);
    };
    function pointerdown(event) { if (!root.contains(event.target)) root.fade(); }
    function keydown(event) {
      if (!root.contains(event.target) && !/^(Shift|Control|Alt|Meta)$/.test(event.key || "")) root.fade();
    }
    if (owner) {
      owner.addEventListener("pointerdown", pointerdown, true);
      owner.addEventListener("keydown", keydown, true);
    }
    root.dispose = function () {
      revision += 1;
      if (owner) {
        owner.removeEventListener("pointerdown", pointerdown, true);
        owner.removeEventListener("keydown", keydown, true);
      }
    };
    return root;
  }
  function ActionMenu(label, options) {
    var trigger = iconButton(label || "More actions", "more"),
      bubble = new Bubble(trigger, label || "More actions", options);
    bubble.root.classList.add("phc-action-menu-anchor"); bubble.panel.classList.add("phc-action-menu");
    this.root = bubble.root; this.trigger = trigger; this.bubble = bubble; this.content = bubble.content;
  }
  ActionMenu.prototype.add = function (label, handler, options) {
    var self = this, item = button(label, function () { self.bubble.close(false); handler(); });
    item.className = "phc-action-menu-item" + (options && options.destructive ? " phc-danger-action" : "");
    if (options && options.icon) item.replaceChildren(glyph(options.icon), element("span", "", label));
    this.content.appendChild(item); return item;
  }
  // Shared confirmation order: secondary cancel, then primary action at the right.
  function actionRow(cancel, primary, destructive) {
    var row = element("div", "phc-dialog-actions");
    cancel.className += " phc-action-cancel";
    primary.className += " primary " + (destructive ? "phc-action-delete" : "phc-action-apply");
    row.appendChild(cancel); row.appendChild(primary); return row;
  }
  /* Record forms open above a stationary page. The hidden flag mirrors the open state, so owners keep one flag;
     Escape runs the owner's cancel, which may refuse while a request is pending. */
  var dialogSequence = 0;
  function formDialog(className, onCancel) {
    var node = element("dialog", "phc-dialog phc-form-dialog" + (className ? " " + className : ""));
    node.hidden = true;
    node.addEventListener("cancel", function (event) { event.preventDefault(); onCancel(); });
    node.openModal = function () {
      var heading = node.querySelector("h2");
      if (heading) {
        if (!heading.id) heading.id = "phc-form-dialog-" + (++dialogSequence);
        node.setAttribute("aria-labelledby", heading.id);
      }
      node.hidden = false; if (!node.open && node.showModal) node.showModal();
    };
    node.closeModal = function () { node.hidden = true; if (node.open && node.close) node.close(); };
    return node;
  }
  function helpButton(label, explanation) {
    var help = button("?"); help.className = "phc-help";
    help.title = explanation; help.setAttribute("aria-label", label + ": " + explanation);
    return help;
  }
  /* Hover and focus tooltips for every [data-tooltip] under root, in one shared tip node. */
  function attachTooltip(root) {
    var tip = element("div", "row-tooltip"); tip.hidden = true; tip.setAttribute("role", "tooltip");
    var timer;
    var owner;
    root.appendChild(tip);
    function hide() { tip.hidden = true; owner = null; }
    function later() { clearTimeout(timer); timer = setTimeout(hide, 100); }
    function show(event) {
      var node = event.target;
      while (node && node !== root && !node.getAttribute("data-tooltip")) node = node.parentNode;
      if (!node || node === root) return;
      clearTimeout(timer); owner = node;
      tip.textContent = node.getAttribute("data-tooltip"); tip.hidden = false;
      var bounds = node.getBoundingClientRect();
      tip.style.left = Math.max(8, Math.min(bounds.left, window.innerWidth - tip.offsetWidth - 8)) + "px";
      tip.style.top = (bounds.bottom + tip.offsetHeight + 8 < window.innerHeight ?
        bounds.bottom + 4 : bounds.top - tip.offsetHeight - 4) + "px";
    }
    root.addEventListener("mouseover", show); root.addEventListener("focusin", show);
    root.addEventListener("mouseout", later); root.addEventListener("focusout", later);
    tip.addEventListener("mouseover", function () { clearTimeout(timer); });
    tip.addEventListener("mouseout", later);
    root.addEventListener("keydown", function (event) { if (event.key === "Escape") hide(); });
    root.addEventListener("scroll", hide);
    root.addEventListener("click", function () { if (owner) hide(); });
    root._checkTooltip = function () {
      if (owner && (!root.contains(owner) || owner.getAttribute("data-tooltip") !== tip.textContent)) hide();
    };
  }

  return { Bubble: Bubble, ActionMenu: ActionMenu, floatingNotice: floatingNotice, actionRow: actionRow,
    formDialog: formDialog, helpButton: helpButton, attachTooltip: attachTooltip, placeNear: placeNear,
    BUBBLE: BUBBLE };
});
