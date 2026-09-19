"use strict";

// What counts as a panel file, in one place. The protocol agreement test and the coverage runner
// both need "every shipped panel script", and a file either of them missed would be a file whose
// message types nothing verifies or whose lines nothing scores. The runtime page (html/runtime/) is
// shipped script too but not the panel: the panel never loads it, so it is listed separately and the
// coverage runner scores both.

var fs = require("fs");
var path = require("path");

var root = path.resolve(__dirname, "..", "..");
var html = path.join(root, "src", "ph_composer", "html");
var runtime = path.join(html, "runtime");

function panelFiles(directory) {
  return fs.readdirSync(directory || html).sort().reduce(function (files, name) {
    var absolute = path.join(directory || html, name);
    if (absolute === runtime) return files;
    if (fs.statSync(absolute).isDirectory()) return files.concat(panelFiles(absolute));
    return path.extname(name) !== ".js" ? files : files.concat([absolute]);
  }, []);
}

/* The runtime page's own scripts. */
function runtimeFiles() {
  return fs.readdirSync(runtime).sort().filter(function (name) { return path.extname(name) === ".js"; })
    .map(function (name) { return path.join(runtime, name); });
}

module.exports = { panelFiles: panelFiles, runtimeFiles: runtimeFiles, html: html, root: root };
