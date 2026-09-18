"use strict";

/* The DOM stub the panel tests share: enough of Element and Document for the ES5 panel code.

   Supported selector forms, and only these: a tag name (`button`, `h1`), one class (`.row-target`), an
   attribute (`[data-tab]`), an attribute with a value (`[data-section='library']`), `:hover`
   against `document.hoverTarget`, and any comma-separated list of those (`button, select`). A
   compound like `button.primary` is not supported and never silently half-matches: it returns
   false, which the stub's own tests pin.

   Out of scope, deliberately: nesting (`buildDocument` appends every parsed tag as a flat child
   of body) and layout. Sizes and boxes are whatever a test sets on the node; nothing here
   computes one. A test that needs a real box sets `node.rect` or `node.offsetWidth` itself.

   In scope, because the panel depends on it: a node belongs to one document, and `isConnected`,
   `activeElement` and `:hover` are that document's answers. Focusing a node attached to nothing is
   a no-op, as it is in the browser. */
/* Which document a node belongs to is answered by walking its own tree, not by a module variable.
   A process may build several documents (the panel's own and a fixture's), and a node attached to
   the first must not change its answers because a second was built afterwards. `buildDocument`
   marks its body, and every node reaches that body or no body at all. */
function documentOf(node) {
  var current = node;
  while (current) {
    if (current.ownerDocument) return current.ownerDocument;
    current = current.parentNode;
  }
  return null;
}
/* Zero-sized at the origin: the stub does no layout, so a width it invented would be a
   measurement the panel code would trust. Callers that read `box.width` fall through to their own
   default, which is what they did before this box had the key at all. */
var DEFAULT_RECT = { left: 0, top: 0, right: 0, bottom: 30, width: 0, height: 0, x: 0, y: 0 };

/* Listener registry shared by elements, the document and the test window. */
function addEventListener(name, callback) {
  var current = this; if (!current.listenerLists[name]) current.listenerLists[name] = [];
  current.listenerLists[name].push(callback); current.listeners[name] = function (event) {
    current.listenerLists[name].slice().forEach(function (listener) { listener(event || {}); });
  };
}
function dispatchEvent(event) {
  if (this.listeners[event.type]) this.listeners[event.type](event);
  return true;
}
function removeEventListener(name, callback) {
  this.listenerLists[name] = (this.listenerLists[name] || []).filter(function (listener) {
    return listener !== callback;
  });
}
function attachEvents(target) {
  target.listeners = {}; target.listenerLists = {};
  target.addEventListener = addEventListener; target.removeEventListener = removeEventListener;
  /* The real DOM name, so panel code that calls `document.dispatchEvent` reaches the same route a
     test does. `addEventListener` above installs the fan-out; the guard is what makes a dispatch
     with nothing listening a no-op rather than a call on undefined. */
  target.dispatchEvent = dispatchEvent;
  return target;
}
function element(tag, attributes) {
  var node = {
    tagName: tag.toLowerCase(), attributes: attributes || {}, textContent: "", value: "", className: "",
    hidden: false, disabled: false, readOnly: false, checked: false, children: [], parentNode: null,
    listeners: {}, listenerLists: {}, style: { setProperty: function (name, value) {
      this[name] = value;
    } }, dataset: {},
    getAttribute: function (name) {
      return Object.prototype.hasOwnProperty.call(this.attributes, name) ? this.attributes[name] : null;
    },
    /* `id` and `class` mirror onto the properties, the way a real element does: panel code reads
       `node.className` after `setAttribute("class", ...)` and would otherwise see the old value. */
    setAttribute: function (name, value) {
      this.attributes[name] = String(value);
      if (name === "class") this.className = String(value);
      if (name === "id") this.id = String(value);
    },
    removeAttribute: function (name) {
      delete this.attributes[name];
      if (name === "class") this.className = "";
      if (name === "id") this.id = "";
    },
    showModal: function () { this.open = true; }, close: function () { this.open = false; },
    /* Focus dispatches, because panel code listens for it; a bare assignment would not fire. */
    focus: function (options) {
      this.focusOptions = options;
      var owner = documentOf(this);
      if (owner) owner.activeElement = this;
      this.dispatchEvent({ type: "focus", target: this });
    },
    blur: function () {
      var owner = documentOf(this);
      if (owner && owner.activeElement === this) owner.activeElement = null;
      this.dispatchEvent({ type: "blur", target: this });
    },
    select: function () { this.selectionStart = 0; this.selectionEnd = String(this.value).length; },
    dispatchEvent: dispatchEvent,
    addEventListener: addEventListener, removeEventListener: removeEventListener,
    /* A node has one parent: appending one that is already somewhere else moves it, as the DOM
       does. Appending it twice to the same parent moves it to the end, and does not clone it. */
    appendChild: function (child) {
      if (child.parentNode) child.parentNode.removeChild(child);
      child.parentNode = this; this.children.push(child); return child;
    },
    removeChild: function (child) {
      var i = this.children.indexOf(child);
      if (i >= 0) this.children.splice(i, 1);
      child.parentNode = null;
      return child;
    },
    insertBefore: function (child, before) {
      if (child.parentNode) child.parentNode.removeChild(child);
      var i = before ? this.children.indexOf(before) : this.children.length;
      this.children.splice(i, 0, child);
      child.parentNode = this;
      return child;
    },
    /* Detaches what it displaces. Dropping the array alone left every removed child still naming
       this node as its parent, so `isConnected` reported a node the panel had just discarded as
       still mounted. */
    replaceChildren: function () {
      var i;
      this.children.forEach(function (child) { child.parentNode = null; });
      this.children = [];
      for (i = 0; i < arguments.length; i += 1) this.appendChild(arguments[i]);
    },
    contains: function (candidate) {
      var found = false;
      walk(this, function (child) { if (child === candidate) found = true; });
      return found;
    },
    /* Per node, not fixed: a test that cares about placement sets `node.rect`. */
    getBoundingClientRect: function () { return this.rect || DEFAULT_RECT; },
    matches: function (selector) { return matches(this, selector); },
    id: "", offsetWidth: 0, offsetHeight: 0
  };
  /* A node is connected when walking up from it reaches a document's body, whichever document
     that is. Writable, because a test may state the answer directly for a node it never attached. */
  Object.defineProperty(node, "isConnected", {
    configurable: true,
    get: function () {
      if (node.connected !== undefined) return node.connected;
      return documentOf(node) !== null;
    },
    set: function (value) { node.connected = value; }
  });
  /* Markup that arrives as attributes mirrors the same way `setAttribute` does, so a node parsed
     out of the panel HTML and a node built in a test answer `.className` alike. */
  if (node.attributes.class !== undefined) node.className = String(node.attributes.class);
  if (node.attributes.id !== undefined) node.id = String(node.attributes.id);
  Object.defineProperty(node, "lastChild", { get: function () { return node.children[node.children.length - 1]; } });
  node.querySelectorAll = function (selector) { return descendants(node, selector); };
  node.querySelector = function (selector) { return this.querySelectorAll(selector)[0] || null; };
  node.classList = {
    add: function (name) {
      if (node.className.split(/\s+/).indexOf(name) < 0) node.className += (node.className ? " " : "") + name;
    },
    remove: function (name) {
      node.className = node.className.split(/\s+/).filter(function (item) { return item && item !== name; }).join(" ");
    },
    contains: function (name) { return node.className.split(/\s+/).indexOf(name) >= 0; },
    toggle: function (name, force) {
      var on = force === undefined ? !this.contains(name) : Boolean(force);
      if (on) this.add(name);
      else this.remove(name);
      return on;
    }
  };
  node.closest = function (selector) {
    var current = node;
    while (current) { if (matches(current, selector)) return current; current = current.parentNode; } return null;
  };
  return node;
}
function walk(node, callback) { callback(node); node.children.forEach(function (child) { walk(child, callback); }); }
/* A comma list matches when any of its parts does, which is what `button, select` means. */
function matches(node, selector) {
  return String(selector).split(",").some(function (part) { return matchesOne(node, part.trim()); });
}
function matchesOne(node, selector) {
  if (selector === ":hover") {
    var owner = documentOf(node);
    return Boolean(owner) && owner.hoverTarget === node;
  }
  var identifier = /^#([a-z0-9_-]+)$/i.exec(selector); if (identifier) return node.id === identifier[1];
  var className = /^\.([a-z0-9_-]+)$/.exec(selector);
  if (className) return node.className.split(/\s+/).indexOf(className[1]) >= 0;
  if (/^[a-z][a-z0-9]*$/.test(selector)) return node.tagName === selector;
  var attribute = /^\[([^=\]]+)(?:=['"]?([^'"\]]+)['"]?)?\]$/.exec(selector); if (!attribute) return false;
  return attribute[2] === undefined ?
    node.getAttribute(attribute[1]) !== null : node.getAttribute(attribute[1]) === attribute[2];
}
function descendants(root, selector) {
  var result = [];
  walk(root, function (node) { if (matches(node, selector)) result.push(node); });
  return result;
}
function parseAttributes(text) {
  var attributes = {}; var expression = /([^\s=]+)(?:\s*=\s*["']([^"']*)["'])?/g; var match;
  while ((match = expression.exec(text))) attributes[match[1]] = match[2] === undefined ? "" : match[2];
  return attributes;
}
function buildDocument(source) {
  var body = element("body"); var expression = /<([a-z0-9]+)\b([^>]*)>/gi; var match;
  while ((match = expression.exec(source))) body.appendChild(element(match[1], parseAttributes(match[2])));
  var built = { body: body, activeElement: null, createElement: function (tag) { return element(tag); },
    createElementNS: function (_namespace, tag) { return element(tag); },
    querySelectorAll: function (selector) { return descendants(body, selector); },
    querySelector: function (selector) { return this.querySelectorAll(selector)[0] || null; } };
  attachEvents(built);
  built.elementFromPoint = function () { return null; };
  /* Settable by a test; `:hover` reads it. Nothing here tracks pointers. */
  built.hoverTarget = null;
  /* The one link the ownership walk needs: from this document's body back to the document. */
  body.ownerDocument = built;
  return built;
}


/* `getComputedStyle` returns what the test declared for that node and nothing else: the stub
   computes no styles, so an undeclared property reads as the empty string a browser would give
   for a property no rule sets. */
function getComputedStyle(node) {
  var declared = (node && node.computedStyle) || {};
  return { getPropertyValue: function (name) { return declared[name] === undefined ? "" : declared[name]; } };
}

/* Enough of ClipboardEvent for a copy or paste to travel through the real listeners. */
function ClipboardEvent(type, options) {
  var settings = options || {};
  var data = settings.clipboardData || {};
  var stored = {};
  this.type = type;
  this.defaultPrevented = false;
  this.preventDefault = function () { this.defaultPrevented = true; };
  this.clipboardData = {
    getData: function (format) { return data[format] === undefined ? (stored[format] || "") : data[format]; },
    setData: function (format, value) { stored[format] = String(value); }
  };
}

module.exports = {
  element: element, attachEvents: attachEvents, walk: walk, matches: matches, descendants: descendants,
  parseAttributes: parseAttributes, buildDocument: buildDocument, getComputedStyle: getComputedStyle,
  ClipboardEvent: ClipboardEvent, DEFAULT_RECT: DEFAULT_RECT
};
