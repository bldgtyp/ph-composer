"use strict";
var assert = require("assert"), test = require("node:test"), dom = require("./support/dom_stub"),
  source = require("./support/panel_source");
function setup() {
  var context = { document: dom.buildDocument(""), Intl: Intl, innerWidth: 1280, innerHeight: 800,
    setTimeout: setTimeout, clearTimeout: clearTimeout };
  context.window = context; dom.attachEvents(context);
  var modules = source.start(context, ["library/sidebar"]), sent = [], target = { id: "a", layer_id: "l",
    segment_id: "s", expected_values: { name: "Assembly", layers: [] } };
  var sidebar = new modules["library/sidebar"]({ session: "session", send: function (type, payload) {
    sent.push({ type: type, payload: payload });
  }, adapter: { title: "Synthetic library", wireKind: "test_parts", read: function () { return []; },
    properties: [], target: function () { return { params: target }; } }, onUse: function () {} });
  context.document.body.appendChild(sidebar.root);
  var state = { session: "session", revision: 1, ui: { queryResults: {}, setupResults: {} }, sections: {
    "ph_composer.library.provider_catalogs": { status: "completed", value: [{ id: "p", label: "Public provider",
      provider_kind: "example.provider", kinds: ["test_parts"], catalogs: [{ kind: "test_parts", generation: 1,
        state: "loaded" }] }] } } };
  sidebar.refresh(state, {}, true); sidebar.store.select("p");
  var request = sent[0].payload;
  state.ui.queryResults[request.request_id] = { session: "session", request_id: request.request_id,
    outcome: { status: "completed", value: { generation: 1, state: "loaded", total: 1, next_cursor: null,
      rows: [{ library_id: "lib", library_name: "Public library", record_id: "r", snapshot: { id: "r", name: "Part" },
        resolution: { outcome: "create", candidates: [] } }] } } };
  sidebar.refresh(state, {}, true);
  return { sidebar: sidebar, sent: sent, state: state, target: target };
}
test("Details never writes; Add and selected-target Use each dispatch one coordinator action", function () {
  var o = setup(), row = o.sidebar.records[0]; o.sidebar.openDetails(o.sidebar.entries[row.id]);
  assert.deepStrictEqual(o.sent.map(function (item) { return item.type; }), ["query.invoke"]);
  o.sidebar.use(row); o.target.expected_values.name = "Changed";
  assert.strictEqual(o.sent.length, 2);
  assert.strictEqual(o.sent[1].payload.name, "ph_composer.library.copy");
  assert.strictEqual(o.sent[1].payload.params.assignment.expected_values.name, "Assembly");
  o.sidebar.add(row); assert.strictEqual(o.sent.length, 2, "a pending copy cannot overlap Add");
  o.sidebar.dispose(); o.sidebar.use(row); o.sidebar.add(row); assert.strictEqual(o.sent.length, 2);
});
test("failed refresh keeps old rows and discloses age; search/expansion/scroll persist", function () {
  var o = setup(); o.sidebar.search.value = "Part"; o.sidebar.expanded[""] = false;
  o.sidebar.list.scrollTop = 15;
  o.sidebar.store.page.state = "failed"; o.sidebar.store.page.failure = { message: "Unavailable." };
  o.sidebar.store.page.age_seconds = 65;
  Object.assign(o.state.sections["ph_composer.library.provider_catalogs"].value[0].catalogs[0],
    { state: "failed", failure: { message: "Unavailable." }, age_seconds: 65 });
  o.sidebar.refresh(o.state, {}, true);
  assert.strictEqual(o.sidebar.records.length, 1);
  assert.match(o.sidebar.sourceStatus.textContent, /last successful catalog.*65 seconds/);
  assert.strictEqual(o.sidebar.search.value, "Part"); assert.strictEqual(o.sidebar.expanded[""], false);
  assert.strictEqual(o.sidebar.list.scrollTop, 15);
});
test("provider withdrawal cancels open review and retained Add/Use/Setup callbacks cannot write", function () {
  var o = setup(), row = o.sidebar.records[0]; o.sidebar.copy.open(Object.assign({}, row, {
    resolution: { outcome: "review_required", candidates: [{ id: "local", name: "Local", differences: [],
      expected_values: { name: "Local" } }] } }));
  delete o.state.sections["ph_composer.library.provider_catalogs"]; o.sidebar.refresh(o.state, {}, true);
  o.sidebar.copy.apply("use_library"); o.sidebar.add(row); o.sidebar.use(row); o.sidebar.setup.run("add_file", {});
  assert.strictEqual(o.sent.length, 1); assert.strictEqual(o.sidebar.copy.root.hidden, true);
});

function review(o) {
  o.sidebar.copy.open(Object.assign({}, o.sidebar.records[0], {
    resolution: { outcome: "review_required", candidates: [{ id: "local", name: "Local", differences: [],
      expected_values: { name: "Local" } }] } }));
}
["removed", "kind_removed", "generation_changed"].forEach(function (change) {
  test("a held review is withdrawn when its catalog is " + change + " while metadata remains available", function () {
    var o = setup(), providers = o.state.sections["ph_composer.library.provider_catalogs"].value;
    providers.push({ id: "other", label: "Other provider", kinds: ["test_parts"],
      catalogs: [{ kind: "test_parts", generation: 1, state: "loaded" }] });
    review(o);
    var libraryButton = o.sidebar.copy.libraryButton;
    if (change === "removed") providers.splice(0, 1);
    else if (change === "kind_removed") providers[0].kinds = ["other_kind"];
    else providers[0].catalogs[0].generation = 2;
    o.sidebar.refresh(o.state, {}, true);
    assert.strictEqual(o.sidebar.store.available, true, "the completed metadata section remains available");
    assert.strictEqual(o.sidebar.copy.root.hidden, true);
    assert.strictEqual(o.sidebar.copy.held, null);
    libraryButton.listeners.click({});
    o.sidebar.copy.apply("keep_local");
    assert.strictEqual(o.sent.filter(function (message) { return message.type === "action.invoke"; }).length, 0);
  });
});
test("a failed refresh preserves a held review when its generation remains valid", function () {
  var o = setup(); review(o);
  Object.assign(o.state.sections["ph_composer.library.provider_catalogs"].value[0].catalogs[0],
    { state: "failed", failure: { message: "Unavailable." } });
  o.sidebar.refresh(o.state, {}, true);
  assert.strictEqual(o.sidebar.copy.root.hidden, false);
  assert.strictEqual(o.sidebar.copy.held.row.library.generation, 1);
  o.sidebar.copy.apply("keep_local");
  assert.strictEqual(o.sent.filter(function (message) { return message.type === "action.invoke"; }).length, 1);
});

test("a library's row says its click adds it; beside a table the local list gives way to one line", function () {
  var o = setup(), entry = o.sidebar.entries[o.sidebar.records[0].id];
  assert.strictEqual(entry.button.title, "Add Part to this file");
  assert.strictEqual(entry.addGlyph.hidden, false);
  o.sidebar.records[0].resolution.candidates = [{ id: "local" }];
  o.sidebar.renderList();
  assert.strictEqual(entry.addGlyph.hidden, true);
  assert.strictEqual(entry.button.title, "Part is already in this file");
  o.sidebar.besideTable = true; o.sidebar.renderList();
  assert.strictEqual(o.sidebar.search.hidden, false, "a chosen library is listed as before");
  o.sidebar.store.select(""); o.sidebar.updateRows(); o.sidebar.renderList();
  assert.strictEqual(o.sidebar.search.hidden, true);
  assert.ok(o.sidebar.list.children[0].textContent.indexOf("These records are in the table") === 0);
  assert.strictEqual(o.sidebar.list.querySelectorAll("button").length, 0);
});
