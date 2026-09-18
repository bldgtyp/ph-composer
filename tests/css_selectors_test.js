"use strict";

/* Every class the stylesheets style is a class the panel actually writes. A rule for a name nothing produces
   is dead weight that the next reader has to prove dead by hand. Class names built by concatenation are
   declared here as prefixes with their producer, so a prefix that stops being written fails too. */

var assert = require("assert");
var fs = require("fs");
var path = require("path");
var test = require("node:test");
var panelFiles = require("./support/panel_files");

// A class name is produced from a string literal: `element("div", "phc-heading")`, `className = "..."`,
// `classList.add("...")`, an `svg()` attribute map or an index.html class attribute.
function producedNames(sources) {
  var names = Object.create(null);
  var literal = /"((?:[^"\\\n]|\\.)*)"|'((?:[^'\\\n]|\\.)*)'|`((?:[^`\\]|\\.)*)`/g;
  sources.forEach(function (source) {
    var match;
    literal.lastIndex = 0;
    while ((match = literal.exec(source))) {
      var text = match[1] !== undefined ? match[1] : (match[2] !== undefined ? match[2] : match[3]);
      (text.match(/[A-Za-z_][\w-]*-?/g) || []).forEach(function (word) { names[word] = true; });
    }
  });
  return names;
}

// Names completed at runtime. `producer` is the literal that builds them: when it goes, this entry fails.
// None exists yet; the record table brings the first ("col-" + field).
var DYNAMIC = [];

function classSelectors(css) {
  var text = css.replace(/\/\*[\s\S]*?\*\//g, "").replace(/url\((?:"[^"]*"|'[^']*'|[^)]*)\)/g, "url()");
  var rules = [];
  text.replace(/([^{}]+)\{([^{}]*)\}/g, function (all, prelude) {
    if (prelude.indexOf("@") >= 0) return all;
    rules.push(prelude.trim());
    return all;
  });
  return rules;
}

test("every class the stylesheets style is written by the panel", function () {
  var stylesheets = fs.readdirSync(panelFiles.html).filter(function (name) {
    return path.extname(name) === ".css";
  }).sort();
  assert.ok(stylesheets.length, "no panel stylesheets found");
  var sources = panelFiles.panelFiles().concat([path.join(panelFiles.html, "index.html")])
    .map(function (file) { return fs.readFileSync(file, "utf8"); });
  var produced = producedNames(sources);
  var allSource = sources.join("\n");

  DYNAMIC.forEach(function (entry) {
    assert.ok(allSource.indexOf(entry.producer) >= 0,
      "no panel file builds names with " + entry.producer + " any more; drop the \"" + entry.prefix + "\" allowance");
  });

  var used = Object.create(null);
  var dead = [];
  stylesheets.forEach(function (name) {
    classSelectors(fs.readFileSync(path.join(panelFiles.html, name), "utf8")).forEach(function (selector) {
      (selector.match(/\.[A-Za-z_][\w-]*/g) || []).forEach(function (token) {
        var className = token.slice(1);
        if (produced[className]) return;
        var allowed = DYNAMIC.filter(function (entry) {
          if (className.indexOf(entry.prefix) !== 0) return false;
          return !entry.only || selector.indexOf(entry.only) >= 0;
        })[0];
        if (allowed) { used[allowed.prefix] = true; return; }
        dead.push(name + ": " + selector + " (." + className + ")");
      });
    });
  });

  assert.deepStrictEqual(dead, [], "stylesheet rules for class names the panel never writes:\n  " + dead.join("\n  "));
  DYNAMIC.forEach(function (entry) {
    assert.ok(used[entry.prefix],
      "no selector needs the \"" + entry.prefix + "\" allowance any more (" + entry.reason + ")");
  });
});
