/* The shared presentation toolkit as one facade. Each part has its own module and owner: dom (elements, text,
   memoised paints), icons, overlay (bubbles, menus, dialogs, notices, tooltips) and page_header. Callers take `ui` from
   here. The record table and inventory controls join when the first screen with a record table lands. */
PhComposerUI.define("workspace", ["dom", "icons", "overlay", "table_contributions", "page_header"],
  function (dom, icons, overlay, contributions, header) {
  "use strict";
  return {
    element: dom.element, svg: dom.svg, button: dom.button, option: dom.option, titleCase: dom.titleCase,
    number: dom.number, blank: dom.blank, compareText: dom.compareText, propertyRow: dom.propertyRow,
    memoPaint: dom.memoPaint, pulse: dom.pulse,
    svgIcon: icons.svgIcon, glyph: icons.glyph, iconButton: icons.iconButton, paintIconButton: icons.paintIconButton,
    Bubble: overlay.Bubble, ActionMenu: overlay.ActionMenu, floatingNotice: overlay.floatingNotice,
    actionRow: overlay.actionRow, formDialog: overlay.formDialog, helpButton: overlay.helpButton,
    placeNear: overlay.placeNear, attachTooltip: overlay.attachTooltip,
    pageHeader: header.pageHeader,
    contributeTable: contributions.register, composeTable: contributions.compose
  };
});
