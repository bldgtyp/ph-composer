/* The one page header every pane opens with: the title, a muted count, then at the right the secondary
   actions and the one primary action last. A screen never styles its own heading.
   pageHeader({ title, count, actions: [node], primary: node }) returns
   { root, setCount(text), setActions(nodes), setPrimary(node) }; a blank count or a null primary shows nothing. */
PhComposerUI.define("page_header", ["dom"], function (dom) {
  "use strict";

  function pageHeader(options) {
    var root = dom.element("div", "phc-heading"), count = dom.element("span", "phc-heading-count");
    var actions = dom.element("div", "phc-heading-actions"), secondary = [], primary = null;
    root.appendChild(dom.element("h1", "", options.title));
    root.appendChild(count);
    root.appendChild(actions);
    function place() {
      actions.replaceChildren.apply(actions, primary ? secondary.concat([primary]) : secondary);
    }
    var header = {
      root: root,
      setCount: function (text) {
        count.textContent = dom.blank(text) ? "" : String(text);
        count.hidden = !count.textContent;
      },
      setActions: function (nodes) { secondary = nodes.slice(); place(); },
      // Placing the same node again would drop its focus, so only a different node moves the DOM.
      setPrimary: function (node) {
        if (node === primary) return;
        primary = node;
        if (node && !/(^| )primary( |$)/.test(node.className)) node.className = (node.className + " primary").trim();
        place();
      }
    };
    secondary = (options.actions || []).slice();
    header.setCount(options.count);
    if (options.primary) header.setPrimary(options.primary); else place();
    return header;
  }

  return { pageHeader: pageHeader };
});
