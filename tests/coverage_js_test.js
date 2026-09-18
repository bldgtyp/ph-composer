"use strict";

/* The JavaScript coverage merger. Each test file runs in its own process, so V8 writes one report
   per process and the score is the union of what they reached. Two rules meet here and pull in
   opposite directions, which is what these cases pin down: inside one report a narrower range
   overrides the wider one containing it, and between reports nothing overrides anything. */

var assert = require("assert");
var test = require("node:test");
var coverage = require("../tools/coverage_js");

// Two reports that disagree about the same bytes: one process executed them, the other did not.
var COVERED = [[0, 10, true]];
var NOT_COVERED = [[0, 10, false]];

test("a byte one report reached is covered whichever report is read first", function () {
  var forward = coverage.coveredBytes(10, [COVERED, NOT_COVERED]);
  var reversed = coverage.coveredBytes(10, [NOT_COVERED, COVERED]);

  assert.deepStrictEqual(Array.from(forward), Array.from(reversed));
  assert.strictEqual(forward[0], true, "covered by either report is covered");
});

test("inside one report a narrower range still overrides the wider one around it", function () {
  var outerCoveredInnerNot = [[0, 10, true], [4, 6, false]];

  var covered = coverage.coveredBytes(10, [outerCoveredInnerNot]);

  assert.strictEqual(covered[0], true);
  assert.strictEqual(covered[4], false, "the inner uncovered block wins inside its own report");
  assert.strictEqual(covered[9], true);
});

test("an uncovered inner block in one report is covered by another report that ran it", function () {
  var partial = [[0, 10, true], [4, 6, false]];
  var whole = [[0, 10, true]];

  var forward = coverage.coveredBytes(10, [partial, whole]);
  var reversed = coverage.coveredBytes(10, [whole, partial]);

  assert.strictEqual(forward[4], true);
  assert.deepStrictEqual(Array.from(forward), Array.from(reversed));
});

test("the line score reads a line as hit when any byte in it is covered", function () {
  var source = "var a = 1;\nvar b = 2;\n";

  var counts = coverage.lineCoverage(source, [[[0, 10, true]]]);

  assert.strictEqual(counts.relevant, 2);
  assert.strictEqual(counts.hit, 1, "only the first line's bytes were reached");
});

test("a file no report mentions scores zero rather than throwing", function () {
  var counts = coverage.lineCoverage("var a = 1;\n", []);

  assert.strictEqual(counts.relevant, 1);
  assert.strictEqual(counts.hit, 0);
});
