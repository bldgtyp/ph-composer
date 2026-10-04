"use strict";

// Line coverage for the panel source, from V8's own block ranges. Each test file runs in a child
// process with NODE_V8_COVERAGE set, and the per-file ranges are merged before they are scored.
// Separate from `make ci`: run it before a phase gate.
//
//   node tools/coverage_js.js [minimum-percent]

var child_process = require("child_process");
var fs = require("fs");
var os = require("os");
var path = require("path");

var panelFiles = require("../tests/support/panel_files");
var root = panelFiles.root;
var html = panelFiles.html;

function runTests(output) {
  fs.readdirSync(path.join(root, "tests"))
    .filter(function (name) { return /_test\.js$/.test(name); })
    .sort()
    .forEach(function (name) {
      // Under the same memory ceiling as `make test` (tools/js_test_guard.js), and a time limit, so a runaway
      // test fails instead of exhausting memory.
      var result = child_process.spawnSync(process.execPath,
        [path.join(root, "tools", "js_test_guard.js"), process.execPath, path.join(root, "tests", name)], {
          cwd: root,
          env: Object.assign({}, process.env, { NODE_V8_COVERAGE: output }),
          stdio: ["ignore", "ignore", "pipe"],
          timeout: Number(process.env.NODE_TEST_TIMEOUT_MS || 60000) * 2
        });
      if (result.status !== 0) {
        process.stderr.write("coverage run failed in tests/" + name + "\n" + result.stderr);
        process.exit(1);
      }
    });
}

// The panel files are loaded through vm.runInNewContext, so V8 reports whatever `filename` the
// test passed: an absolute file:// URL, a repository-relative path, or a bare "sections/x.js".
function resolveSource(url) {
  var candidate = url.indexOf("file://") === 0 ? url.slice("file://".length) : url;
  var absolute = path.isAbsolute(candidate) ? candidate : null;
  if (!absolute && fs.existsSync(path.join(root, candidate))) absolute = path.join(root, candidate);
  if (!absolute && fs.existsSync(path.join(html, candidate))) absolute = path.join(html, candidate);
  if (!absolute) return null;
  absolute = path.resolve(absolute);
  return absolute.indexOf(html + path.sep) === 0 && path.basename(absolute) !== "pyodide.js" ? absolute : null;
}

/* source path -> one list of [start, end, covered] byte ranges per report.
   Kept per report on purpose. Within a report, V8 emits ranges outermost first and a narrower
   range overrides the wider one it sits inside, so scoring has to apply them in that order.
   Between reports there is no such relationship: each is an independent process that executed a
   different subset, and a line one test missed is covered if another test reached it. Flattening
   the two into one list made the score depend on which report was read last. */
function collectReports(directory) {
  var byFile = {};
  fs.readdirSync(directory).sort().forEach(function (name) {
    var report = JSON.parse(fs.readFileSync(path.join(directory, name), "utf8"));
    report.result.forEach(function (script) {
      var file = resolveSource(script.url);
      if (!file) return;
      var ranges = [];
      script.functions.forEach(function (fn) {
        fn.ranges.forEach(function (range) {
          ranges.push([range.startOffset, range.endOffset, range.count > 0]);
        });
      });
      if (!ranges.length) return;
      byFile[file] = byFile[file] || [];
      byFile[file].push(ranges);
    });
  });
  return byFile;
}

/* One byte map per report, applied widest range first, then OR'd: covered by any report is
   covered. */
function coveredBytes(length, reports) {
  // Dense and boolean: a caller comparing two maps should not have to treat a hole and a `false`
  // as the same answer.
  var covered = new Array(length).fill(false);
  reports.forEach(function (ranges) {
    var single = new Array(length);
    ranges.slice().sort(function (a, b) { return (b[1] - b[0]) - (a[1] - a[0]); })
      .forEach(function (range) {
        for (var index = range[0]; index < range[1] && index < length; index += 1) {
          single[index] = range[2];
        }
      });
    for (var index = 0; index < length; index += 1) {
      if (single[index]) covered[index] = true;
    }
  });
  return covered;
}

function lineCoverage(source, reports) {
  var covered = coveredBytes(source.length, reports);
  var offset = 0;
  var hit = 0;
  var relevant = 0;
  source.split("\n").forEach(function (line) {
    var text = line.trim();
    var skip = text === "" || text.indexOf("//") === 0 || text === "}" || text === "};" ||
      text === "{" || text.indexOf("/*") === 0 || text.indexOf("*") === 0;
    if (!skip) {
      relevant += 1;
      var any = false;
      for (var index = offset; index < offset + line.length; index += 1) {
        if (covered[index]) { any = true; break; }
      }
      if (any) hit += 1;
    }
    offset += line.length + 1;
  });
  return { hit: hit, relevant: relevant };
}

function score(byFile) {
  var totalHit = 0;
  var totalRelevant = 0;
  var perFile = [];
  panelFiles.panelFiles().concat(panelFiles.runtimeFiles()).forEach(function (file) {
    var counts = lineCoverage(fs.readFileSync(file, "utf8"), byFile[file] || []);
    totalHit += counts.hit;
    totalRelevant += counts.relevant;
    perFile.push([file.replace(root + "/", ""),
      counts.relevant === 0 ? 100 : counts.hit * 100 / counts.relevant,
      counts.relevant - counts.hit]);
  });
  return {
    total: totalRelevant === 0 ? 100 : totalHit * 100 / totalRelevant,
    relevant: totalRelevant,
    perFile: perFile
  };
}

function main() {
  var minimum = Number(process.argv[2] || 0);
  var output = fs.mkdtempSync(path.join(os.tmpdir(), "ph-composer-js-coverage-"));
  runTests(output);
  var result = score(collectReports(output));
  fs.rmSync(output, { recursive: true, force: true });

  result.perFile.sort(function (a, b) { return a[1] - b[1]; }).slice(0, 10).forEach(function (row) {
    process.stderr.write("  " + row[1].toFixed(1) + "%  " + row[0] + "  " + row[2] + " uncovered\n");
  });
  process.stderr.write("JavaScript line coverage: " + result.total.toFixed(1) + "% of " +
    result.relevant + " lines in " + result.perFile.length + " files (minimum " + minimum + "%)\n");
  if (result.total < minimum) {
    process.stderr.write("JavaScript coverage " + result.total.toFixed(1) + "% is below the " +
      minimum + "% minimum\n");
    process.exit(1);
  }
}

module.exports = { coveredBytes: coveredBytes, lineCoverage: lineCoverage, resolveSource: resolveSource };

if (require.main === module) main();
