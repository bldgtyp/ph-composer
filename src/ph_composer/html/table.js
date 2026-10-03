/* The shared record table: keyed rows patched in place, group headings, row icon actions, column resize and
   tooltips. It knows no record vocabulary: callers pass rows, columns, cell values and actions. */
PhComposerUI.define("table", ["dom", "icons", "overlay", "view_controls"],
  function (dom, icons, overlay, viewControls) {
  "use strict";
  var element = dom.element, button = dom.button, groupToggle = viewControls.groupToggle,
    paintGroupToggle = viewControls.paintGroupToggle;
  /* The columns table.css keeps sticky at the left edge, with the widths its custom properties default to. */
  var STICKY_WIDTHS = { hierarchy: 110, name: 220 };
  var DEFAULT_WIDTH = 140;
  var ARROW_KEYS = ["ArrowDown", "ArrowUp", "ArrowRight", "ArrowLeft"];

  function controls(entry, items, cache) {
    if (!entry.controls) entry.controls = {};
    var keep = {};
    items.forEach(function (item) {
      var control = entry.controls[item.id];
      keep[item.id] = true;
      if (!control) {
        control = { node: button("", function () {
          if (!control.node.disabled && cache.options.action) {
            cache.options.action(entry.row, control.item, control.node);
          }
        }) };
        control.node.className = "row-icon " + (item.id === "delete" ? "row-delete" : "");
        control.node.setAttribute("data-row-action", item.id);
        entry.controls[item.id] = control; entry.cells.actions.appendChild(control.node);
      }
      if (!control.item || control.item.icon !== item.icon) {
        control.node.innerHTML = icons.svgIcon(item.icon, 16);
      }
      control.item = item;
      control.node.setAttribute("aria-label", item.label);
      control.node.setAttribute("data-tooltip", item.label);
      control.node.disabled = Boolean(cache.options.disabled || item.disabled);
    });
    Object.keys(entry.controls).forEach(function (id) {
      if (!keep[id]) { entry.cells.actions.removeChild(entry.controls[id].node); delete entry.controls[id]; }
    });
  }
  function defaultColumnWidth(cache, field) {
    return Object.prototype.hasOwnProperty.call(cache.defaultWidths, field) ?
      cache.defaultWidths[field] : DEFAULT_WIDTH;
  }
  function minimumColumnWidth(cache, field) {
    var configured = cache.options.columnMinWidths && Number(cache.options.columnMinWidths[field]);
    var computed = window.getComputedStyle ?
      parseFloat(window.getComputedStyle(cache.headers[field]).minWidth) : 0;
    return Math.max(64, isFinite(configured) ? configured : 0, isFinite(computed) ? computed : 0);
  }
  function paintColumnWidth(cache, field) {
    var width = Number(cache.columnWidths[field]);
    var minimum = minimumColumnWidth(cache, field);
    width = Math.max(minimum, isFinite(width) && width > 0 ? Math.round(width) : defaultColumnWidth(cache, field));
    var value = width + "px";
    cache.columnElements[field].style.width = value;
    cache.headers[field].style.width = value;
    cache.headers[field].style.minWidth = "";
    if (Object.prototype.hasOwnProperty.call(cache.stickyWidths, field)) {
      cache.node.style.setProperty("--col-" + field + "-width", value);
    }
    cache.resizeHandles[field].setAttribute("aria-valuemin", String(minimum));
    cache.resizeHandles[field].setAttribute("aria-valuenow", String(width));
  }
  /* Fixed-layout tables otherwise squeeze unclaimed columns to almost nothing once the identity
     columns fill a narrow panel. Reserve every visible column's width and let the mount scroll. */
  function paintTableWidth(cache) {
    var width = cache.columns.reduce(function (total, column) {
      var field = column[0];
      if (cache.headers[field].hidden) return total;
      return total + (field === "actions" ? cache.actionsWidth : parseFloat(cache.columnElements[field].style.width));
    }, 0);
    cache.node.style.minWidth = width + "px";
  }
  function setColumnWidth(cache, field, width, source) {
    cache.columnWidths[field] = Math.max(minimumColumnWidth(cache, field), Math.min(480, Math.round(width)));
    paintColumnWidth(cache, field);
    paintTableWidth(cache);
    if (cache.options.columnResize) cache.options.columnResize(field, cache.columnWidths[field], source);
    return cache.columnWidths[field];
  }
  function resetColumnWidth(cache, field) {
    delete cache.columnWidths[field]; paintColumnWidth(cache, field);
    paintTableWidth(cache);
    if (cache.options.columnResize) cache.options.columnResize(field, null);
    if (cache.options.columnResizeEnd) cache.options.columnResizeEnd(field, null);
  }
  function attachColumnResize(cache, column) {
    var field = column[0], label = column[1];
    if (field === "actions") return;
    var handle = element("span", "phc-column-resizer");
    handle.tabIndex = 0; handle.setAttribute("role", "separator"); handle.setAttribute("aria-orientation", "vertical");
    handle.setAttribute("aria-label", "Resize " + label + " column");
    handle.setAttribute("aria-valuemin", "64"); handle.setAttribute("aria-valuemax", "480");
    handle.setAttribute("aria-keyshortcuts", "ArrowLeft ArrowRight Enter");
    handle.title = "Drag to resize. Use Left or Right Arrow; Enter resets.";
    function currentWidth() {
      var box = cache.headers[field].getBoundingClientRect();
      return Number(cache.columnWidths[field]) || Number(box.width) || defaultColumnWidth(cache, field);
    }
    handle.addEventListener("mousedown", function (event) {
      if (event.button !== undefined && event.button !== 0) return;
      event.preventDefault(); event.stopPropagation();
      var start = currentWidth(), startX = event.clientX;
      var moved = false;
      function move(moveEvent) {
        moved = true; setColumnWidth(cache, field, start + moveEvent.clientX - startX, "pointer");
      }
      function finish() {
        document.removeEventListener("mousemove", move); document.removeEventListener("mouseup", finish);
        if (window.removeEventListener) window.removeEventListener("blur", finish);
        if (document.body && document.body.classList) document.body.classList.remove("phc-column-resizing");
        if (moved && cache.options.columnResizeEnd) cache.options.columnResizeEnd(field, cache.columnWidths[field]);
      }
      if (document.body && document.body.classList) document.body.classList.add("phc-column-resizing");
      document.addEventListener("mousemove", move); document.addEventListener("mouseup", finish);
      if (window.addEventListener) window.addEventListener("blur", finish);
    });
    handle.addEventListener("dblclick", function (event) {
      event.preventDefault(); event.stopPropagation(); resetColumnWidth(cache, field);
    });
    handle.addEventListener("keydown", function (event) {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault(); event.stopPropagation(); resetColumnWidth(cache, field); return;
      }
      if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return;
      event.preventDefault(); event.stopPropagation();
      setColumnWidth(cache, field, currentWidth() + (event.key === "ArrowLeft" ? -12 : 12), "keyboard");
    });
    cache.resizeHandles[field] = handle;
  }
  function buildCache(root, tableColumns, options) {
    var node = element("table", "phc-table"), columnGroup = element("colgroup"),
      head = element("thead"), header = element("tr");
    var headers = Object.create(null), columnElements = Object.create(null);
    tableColumns.forEach(function (column) {
      var columnElement = element("col", "col-" + column[0]);
      var th = element("th", "col-" + column[0], column[1]);
      th._labelText = column[1];
      columnElements[column[0]] = columnElement; columnGroup.appendChild(columnElement);
      th.scope = "col"; headers[column[0]] = th; header.appendChild(th);
    });
    head.appendChild(header); node.appendChild(columnGroup); node.appendChild(head);
    var stickyWidths = options.stickyWidths || STICKY_WIDTHS;
    var cache = { node: node, headers: headers, columnElements: columnElements,
      resizeHandles: Object.create(null), body: element("tbody"),
      rows: Object.create(null), columns: tableColumns, columnWidths: options.columnWidths || {},
      stickyWidths: stickyWidths,
      defaultWidths: Object.assign({}, stickyWidths, options.defaultWidths || {}),
      groups: Object.create(null), empty: element("p", "phc-empty") };
    tableColumns.forEach(function (column) { attachColumnResize(cache, column); });
    cache.resetColumnWidths = function () {
      Object.keys(cache.columnWidths).forEach(function (field) { delete cache.columnWidths[field]; });
      cache.columns.forEach(function (column) {
        if (cache.resizeHandles[column[0]]) paintColumnWidth(cache, column[0]);
      });
      paintTableWidth(cache);
      if (cache.options.columnResize) cache.options.columnResize(null, null);
      if (cache.options.columnResizeEnd) cache.options.columnResizeEnd(null, null);
    };
    node.appendChild(cache.body); root.replaceChildren(node, cache.empty); root._table = cache;
    overlay.attachTooltip(root);
    return cache;
  }
  function paintHeaders(cache, options) {
    cache.columns.forEach(function (column) {
      var field = column[0], th = cache.headers[field];
      if (th._labelText !== column[1]) { th.textContent = column[1]; th._labelText = column[1]; }
      if (options.header) options.header(th, field);
      var hidden = Boolean(options.hiddenColumns && options.hiddenColumns[field]);
      th.hidden = hidden; cache.columnElements[field].hidden = hidden;
      cache.columnElements[field].style.display = hidden ? "none" : "";
      var handle = cache.resizeHandles[field];
      if (handle) {
        handle.setAttribute("aria-label", "Resize " + column[1] + " column");
        if (handle.parentNode !== th) th.appendChild(handle);
        paintColumnWidth(cache, field);
      }
    });
  }
  /* Places the heading for row's group once, before its first row; returns the next body position. */
  function paintGroups(cache, group, retainedGroups, position) {
    if (!group || retainedGroups[group.key]) return position;
    retainedGroups[group.key] = true;
    var heading = cache.groups[group.key];
    if (!heading) {
      heading = groupToggle(function () { cache.options.toggleGroup(group.key); });
      heading.node = element("tr", "phc-group-row");
      var groupCell = element("td"); groupCell.colSpan = cache.columns.length;
      groupCell.appendChild(heading.button); heading.node.appendChild(groupCell); cache.groups[group.key] = heading;
    }
    paintGroupToggle(heading, group);
    if (cache.body.children[position] !== heading.node) {
      cache.body.insertBefore(heading.node, cache.body.children[position] || null);
    }
    return position + 1;
  }
  function rowLabel(row) { return row.record.name || row.record.display_name; }
  function navigateRows(root, cache, expanded, entry, event) {
    if (ARROW_KEYS.indexOf(event.key) === -1) return;
    var targets = Array.prototype.slice.call(cache.body.querySelectorAll(".row-target"));
    var index = targets.indexOf(entry.target);
    var next;
    if (event.key === "ArrowDown") next = targets[index + 1];
    else if (event.key === "ArrowUp") next = targets[index - 1];
    else if (event.key === "ArrowRight") {
      if (entry.row.depth < 2 && !entry.open) {
        expanded[entry.row.key] = true; table(root, cache.records, cache.options);
      } else if (entry.row.depth < 2 && targets[index + 1]) next = targets[index + 1];
    } else if (entry.row.depth < 2 && entry.open) {
      expanded[entry.row.key] = false; table(root, cache.records, cache.options);
    } else if (entry.row.parent) next = cache.rows[entry.row.parent].target;
    event.preventDefault();
    if (next) next.focus();
  }
  function buildRow(root, cache, expanded, row) {
    var entry = { node: element("tr", "tier-" + row.depth), cells: {} };
    entry.node.setAttribute("data-row-key", row.key);
    cache.rows[row.key] = entry;
    cache.columns.forEach(function (column) {
      var td = element("td", "col-" + column[0]);
      entry.cells[column[0]] = td; entry.node.appendChild(td);
    });
    var hierarchy = entry.cells.hierarchy;
    if (hierarchy && row.depth < 2) {
      entry.chevron = button("", function () {
        expanded[entry.row.key] = !entry.open;
        table(root, cache.records, cache.options);
        entry.chevron.focus();
      });
      entry.chevron.className = "row-chevron";
      entry.chevron.innerHTML = icons.ROW_CHEVRON;
      hierarchy.appendChild(entry.chevron);
    }
    if (hierarchy) {
      entry.target = button(row.tier, function () { if (cache.options.inspect) cache.options.inspect(entry.row); });
      entry.target.className = "row-target";
      entry.target.addEventListener("keydown", function (event) { navigateRows(root, cache, expanded, entry, event); });
      hierarchy.appendChild(entry.target);
    }
    return entry;
  }
  function paintCells(cache, entry, row, options) {
    cache.columns.forEach(function (column) {
      var field = column[0];
      var td = entry.cells[field];
      td.hidden = Boolean(options.hiddenColumns && options.hiddenColumns[field]);
      if (field === "hierarchy" || field === "actions") return;
      var text = options.value(row, field);
      if (options.cell && options.cell(td, row, field, text)) return;
      text = text === undefined || text === null ? "-" : String(text);
      if (td.textContent !== text) td.textContent = text;
      td.title = text;
      if (text === "-") td.setAttribute("aria-label", "Unavailable");
      else td.removeAttribute("aria-label");
      if (options.decorate) options.decorate(td, row, field, text);
    });
  }
  /* Paints one row's state, actions, marker and cells; returns the number of row actions. */
  function paintRow(cache, entry, row, isOpen, rowHidden, group) {
    var options = cache.options;
    entry.node.hidden = Boolean(rowHidden || (group && group.collapsed));
    entry.row = row; entry.open = isOpen;
    if (entry.target) {
      entry.target.setAttribute("aria-label",
        row.tier + " " + (rowLabel(row) || "") + ". Select; arrow keys navigate rows.");
    }
    var actions = options.actions ? options.actions(row) : [];
    controls(entry, actions, cache);
    if (options.actionsCell) options.actionsCell(entry.cells.actions, row);
    var selected = options.selected && options.selected(row);
    entry.node.className = "tier-" + row.depth + (selected ? " host-selected" : "");
    if (entry.chevron) {
      // A row with nothing under it keeps the chevron's place, so its label lines up, but offers nothing to open.
      var leaf = Boolean(options.expandable && !options.expandable(row));
      entry.chevron.classList.toggle("is-leaf", leaf);
      entry.chevron.disabled = leaf;
      entry.chevron.setAttribute("aria-label", (isOpen ? "Collapse " : "Expand ") + row.tier + " " + rowLabel(row));
      entry.chevron.setAttribute("aria-expanded", String(isOpen));
      if (entry.target) entry.target.disabled = Boolean(options.disabled);
    }
    if (entry.cells.hierarchy && options.marker) {
      var marker = options.marker(row);
      if (marker) {
        if (!entry.marker) {
          entry.marker = element("span", "phc-row-marker"); entry.cells.hierarchy.appendChild(entry.marker);
        }
        entry.marker.textContent = marker.text;
        entry.marker.setAttribute("data-tooltip", marker.tooltip); entry.marker.hidden = false;
        entry.marker.setAttribute("aria-label", marker.tooltip);
      } else if (entry.marker) entry.marker.hidden = true;
    }
    paintCells(cache, entry, row, options);
    return actions.length;
  }
  /* A re-render keeps focus on the control that had it, unless that control is now hidden. */
  function restoreFocus(root, focused, hadFocus) {
    if (!hadFocus || document.activeElement === focused || !root.contains(focused)) return;
    for (var ancestor = focused; ancestor; ancestor = ancestor.parentNode) { if (ancestor.hidden) return; }
    focused.focus({ preventScroll: true });
  }
  /* options: rows, columns, value(row, field) and empty are required; see the callers for the optional hooks. */
  function table(root, records, options) {
    var focused = document.activeElement, hadFocus = focused && root.contains(focused);
    var rows = options.rows, expanded = options.expanded || Object.create(null);
    var visible = Object.create(null), retained = Object.create(null), retainedGroups = Object.create(null);
    var cache = root._table || buildCache(root, options.columns, options);
    var position = 0, actionCount = 2;
    cache.options = options; cache.records = records; cache.columns = options.columns;
    if (options.columnWidths) cache.columnWidths = options.columnWidths;
    paintHeaders(cache, options);
    cache.empty.hidden = (options.visibleCount === undefined ? rows.length : options.visibleCount) > 0;
    cache.empty.textContent = options.empty || "No records.";
    rows.forEach(function (row) {
      var group = options.group ? options.group(row) : null;
      position = paintGroups(cache, group, retainedGroups, position);
      var isOpen = Object.prototype.hasOwnProperty.call(expanded, row.key) ? expanded[row.key] : row.depth === 0;
      var rowHidden = Boolean(options.rowHidden && options.rowHidden(row));
      retained[row.key] = true;
      if (row.parent && !visible[row.parent]) return;
      visible[row.key] = !rowHidden && isOpen;
      var entry = cache.rows[row.key] || buildRow(root, cache, expanded, row);
      actionCount = Math.max(actionCount, paintRow(cache, entry, row, isOpen, rowHidden, group));
      if (cache.body.children[position] !== entry.node) {
        cache.body.insertBefore(entry.node, cache.body.children[position] || null);
      }
      position += 1;
    });
    cache.actionsWidth = 16 + actionCount * 32 + (options.actionsCell ? 40 : 0);
    var actionsVisible = cache.headers.actions && !cache.headers.actions.hidden;
    root.style.setProperty("--row-actions-width", (actionsVisible ? cache.actionsWidth : 0) + "px");
    paintTableWidth(cache);
    while (cache.body.children.length > position) cache.body.removeChild(cache.body.lastChild);
    Object.keys(cache.rows).forEach(function (key) {
      if (!retained[key]) { delete cache.rows[key]; delete expanded[key]; }
    });
    Object.keys(cache.groups).forEach(function (key) { if (!retainedGroups[key]) delete cache.groups[key]; });
    restoreFocus(root, focused, hadFocus);
    root._checkTooltip();
  }


  return { table: table, STICKY_WIDTHS: STICKY_WIDTHS };
});
