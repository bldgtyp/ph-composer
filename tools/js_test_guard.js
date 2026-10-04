#!/usr/bin/env node
/* Runs a JavaScript test command under a memory ceiling: `node tools/js_test_guard.js <command> [args...]`.

   Every 200 ms it sums the resident memory of the command and all its descendants, and kills the whole tree
   once that passes JS_TEST_MAX_RSS_MB (default 4096). It exits with the command's own status, or 1 after a
   kill. Development only; nothing here ships.

   Why a watchdog rather than a Node flag: on 2026-10-04 a failing assertion on a stub DOM node made Node's
   assertion printer walk every path through the stub's object graph. That memory is not the JS heap, so
   --max-old-space-size did not stop it; one test process reached 42 GB in 20 seconds, and an earlier run
   stalled the machine. A timeout alone is too slow at that rate. */
"use strict";

var childProcess = require("child_process");
var timers = require("timers");

var LIMIT_MB = Number(process.env.JS_TEST_MAX_RSS_MB || 4096);
var POLL_MS = 200;

/* Resident kilobytes of `root` and every process below it, from one `ps` listing. */
function treeRssKb(root) {
  var listing = childProcess.spawnSync("ps", ["-Ao", "pid=,ppid=,rss="], { encoding: "utf8" }).stdout || "";
  var children = Object.create(null), rss = Object.create(null);
  listing.split("\n").forEach(function (line) {
    var parts = line.trim().split(/\s+/);
    if (parts.length < 3) return;
    (children[parts[1]] = children[parts[1]] || []).push(parts[0]);
    rss[parts[0]] = Number(parts[2]) || 0;
  });
  var total = 0, stack = [String(root)], pids = [];
  while (stack.length) {
    var pid = stack.pop();
    pids.push(pid);
    total += rss[pid] || 0;
    (children[pid] || []).forEach(function (child) { stack.push(child); });
  }
  return { kb: total, pids: pids };
}

/* Every process of the command: its own process group (it starts detached, so a test that spawns more is
   still in it) and anything the tree walk finds, in case one left the group. */
function killAll(child) {
  var pids = treeRssKb(child.pid).pids;
  try { process.kill(-child.pid, "SIGKILL"); } catch (error) { /* group gone */ }
  pids.forEach(function (pid) { try { process.kill(Number(pid), "SIGKILL"); } catch (error) { /* gone */ } });
}

function main(argv) {
  if (!argv.length) {
    process.stderr.write("usage: node tools/js_test_guard.js <command> [args...]\n");
    return process.exit(2);
  }
  var child = childProcess.spawn(argv[0], argv.slice(1), { stdio: "inherit", detached: true });
  var killed = false;
  child.on("error", function (error) {
    process.stderr.write("js_test_guard: could not start " + argv[0] + ": " + error.message + "\n");
    process.exit(2);
  });
  // The command runs in its own group, so the terminal's Ctrl-C reaches only this process: pass it on as a kill
  // of the whole tree, and the same for a parent's timeout or hang-up.
  ["SIGINT", "SIGTERM", "SIGHUP", "SIGALRM"].forEach(function (signal) {
    process.on(signal, function () { killAll(child); process.exit(1); });
  });
  var timer = timers.setInterval(function () {
    var tree = treeRssKb(child.pid);
    if (tree.kb / 1024 <= LIMIT_MB) return;
    killed = true;
    timers.clearInterval(timer);
    killAll(child);
    process.stderr.write("js_test_guard: stopped " + argv.join(" ").slice(0, 120) + " at " +
      Math.round(tree.kb / 1024) + " MB, over the " + LIMIT_MB + " MB ceiling (JS_TEST_MAX_RSS_MB). A test " +
      "is probably printing a stub DOM node in a failed assertion; assert on a property instead.\n");
  }, POLL_MS);
  child.on("exit", function (code, signal) {
    timers.clearInterval(timer);
    process.exit(killed ? 1 : (code === null ? (signal ? 1 : 0) : code));
  });
}

main(process.argv.slice(2));
