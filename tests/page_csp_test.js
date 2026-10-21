"use strict";
/* Every page the extension ships declares one Content-Security-Policy and needs nothing it forbids: no inline
   script, no inline event handler, no javascript: URL. The panel and its dialogs load only the extension's
   own files and reach no network; the runtime page reaches only its own loopback server. */
var assert = require("assert");
var fs = require("fs");
var path = require("path");
var test = require("node:test");
var panelFiles = require("./support/panel_files");
var manifest = require("../tools/panel_manifest");

var DIALOG = "default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; " +
  "connect-src 'none'; form-action 'none'; base-uri 'none'; frame-src 'none'";
var PAGES = {
  "html/index.html": DIALOG.replace("style-src 'self';", "style-src 'self' 'unsafe-inline';"),
  "html/agent_access/index.html": DIALOG,
  "html/support/index.html": DIALOG,
  "html/runtime/index.html": "default-src 'none'; script-src 'self' 'unsafe-eval'; connect-src 'self'; " +
    "img-src data:; worker-src 'self' blob:; base-uri 'none'; form-action 'none'",
  "help/index.html": "default-src 'none'; style-src 'unsafe-inline'; img-src data:"
};
var EXTENSION = path.dirname(panelFiles.html);

function read(page) { return fs.readFileSync(path.join(EXTENSION, page), "utf8"); }

Object.keys(PAGES).forEach(function (page) {
  test(page + " declares its one policy and runs no inline script", function () {
    var markup = read(page);
    var policies = markup.match(/<meta http-equiv="Content-Security-Policy" content="([^"]*)">/g) || [];
    assert.deepStrictEqual(policies, ['<meta http-equiv="Content-Security-Policy" content="' + PAGES[page] + '">']);
    assert.ok(markup.indexOf(policies[0]) < markup.indexOf("<title>"), "the policy precedes anything it governs");
    (markup.match(/<script\b[^>]*>/g) || []).forEach(function (tag) {
      assert.match(tag, /\ssrc="[^"]+"/, tag + " is an inline script");
    });
    assert.doesNotMatch(markup, /\son[a-z]+\s*=/i, "an inline event handler");
    assert.doesNotMatch(markup, /javascript:/i, "a javascript: URL");
    if (PAGES[page].indexOf("'unsafe-inline'") === -1) {
      assert.doesNotMatch(markup, /<style\b|\sstyle\s*=/i, "an inline style the policy refuses");
    }
    var entry = /<body[^>]* data-phc-entry="([^"]+)"/.exec(markup);
    if (entry) {
      assert.ok(manifest.graph(true).definitions[entry[1]], entry[1] + " is a declared module");
      assert.match(markup, /<script src="(?:\.\.\/)?boot\.js"><\/script>\s*<\/body>/, "boot.js is the last script");
    }
  });
});

test("the panel and its two dialogs start from boot.js", function () {
  ["html/index.html", "html/agent_access/index.html", "html/support/index.html"].forEach(function (page) {
    assert.match(read(page), /<body[^>]* data-phc-entry="[^"]+"/, page);
  });
});

test("every shipped page is checked", function () {
  var shipped = [];
  (function walk(directory) {
    fs.readdirSync(directory).forEach(function (name) {
      var absolute = path.join(directory, name);
      if (fs.statSync(absolute).isDirectory()) walk(absolute);
      else if (path.extname(name) === ".html") {
        shipped.push(path.relative(EXTENSION, absolute).split(path.sep).join("/"));
      }
    });
  })(EXTENSION);
  assert.deepStrictEqual(shipped.sort(), Object.keys(PAGES).sort());
});
