"use strict";

// What counts as a panel file, in one place. The protocol agreement test and the coverage runner
// both need "every shipped panel script", and a file either of them missed would be a file whose
// message types nothing verifies or whose lines nothing scores. `pyodide.js`, once the runtime
// lands, is vendored runtime code, not our panel.

var fs = require("fs");
var path = require("path");

var root = path.resolve(__dirname, "..", "..");
var html = path.join(root, "src", "ph_composer", "html");

function panelFiles(directory) {
  return fs.readdirSync(directory || html).sort().reduce(function (files, name) {
    var absolute = path.join(directory || html, name);
    if (fs.statSync(absolute).isDirectory()) return files.concat(panelFiles(absolute));
    return name === "pyodide.js" || path.extname(name) !== ".js" ? files : files.concat([absolute]);
  }, []);
}

module.exports = { panelFiles: panelFiles, html: html, root: root };
