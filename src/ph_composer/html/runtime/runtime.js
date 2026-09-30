/* The runtime page's one script: boots Pyodide from the pinned payload, installs the translation package and
   answers the host. It is not a panel module; the panel never loads it.

   The host (runtime/runtime_host.rb) opens this page on the loopback asset server and talks to it with
     host -> page  PhComposerRuntime.receive({ type: "runtime.probe", payload: { request_id, deadline_ms } })
     page -> host  sketchup.ph_composer_runtime(JSON.stringify({ type, payload }))
   The page sends `runtime.ready` once loaded and `runtime.result` for each probe: timings, the Python
   version, the stack modules loaded (none, in this build) and the translation's answer, or an `error`.

   Boot is single flight: probes that arrive while booting share one boot. Every asset comes from the same
   origin as this page, so the server's manifest, token and hashes govern all of it. */
(function () {
  "use strict";

  var ROOT = new URL("../../", window.location.href).href;
  var STACK = ["honeybee", "honeybee_energy", "honeybee_ph", "ladybug", "ladybug_geometry", "PHX"];
  var PROBE_DOCUMENT = JSON.stringify({ schema_version: 1, run_id: "runtime-probe", sections: {} });
  var session = new window.URLSearchParams(window.location.search).get("session") || "";
  var state = "idle";
  var boot = null;
  var bootCount = 0;
  var pyodide = null;
  var wheelManifest = null;
  var wheels = null;

  function send(type, payload) {
    if (state === "stopped" || !window.sketchup || !window.sketchup.ph_composer_runtime) return;
    window.sketchup.ph_composer_runtime(JSON.stringify({ type: type, payload: payload }));
  }

  function failure(code, message) {
    var error = new Error(message);
    error.code = code;
    return error;
  }

  function fetchAsset(relative, as) {
    return window.fetch(ROOT + relative).then(function (response) {
      if (!response.ok) {
        throw failure("runtime.asset_refused", relative + " was refused (HTTP " + response.status + ")");
      }
      return as === "json" ? response.json() : response.text();
    });
  }

  function loadScript(relative) {
    return new Promise(function (resolve, reject) {
      var script = document.createElement("script");
      script.src = ROOT + relative;
      script.onload = resolve;
      script.onerror = function () { reject(failure("runtime.asset_refused", relative + " did not load")); };
      document.head.appendChild(script);
    });
  }

  function withDeadline(promise, deadlineMs) {
    var timer;
    var expired = new Promise(function (resolve, reject) {
      timer = window.setTimeout(function () {
        reject(failure("runtime.boot_timeout", "The Python runtime did not start within " + deadlineMs + " ms."));
      }, deadlineMs);
    });
    return Promise.race([promise, expired]).then(function (value) {
      window.clearTimeout(timer);
      return value;
    }, function (error) {
      window.clearTimeout(timer);
      throw error;
    });
  }

  /* Writes each translation module the manifest lists into the runtime's file system, then imports the
     package. Importing it must load none of the stack. */
  function installTranslation(manifest) {
    return Promise.all(manifest.translation_assets.map(function (relative) {
      return fetchAsset(relative, "text").then(function (source) {
        var target = "/translation/" + relative.replace(/^python\//, "");
        pyodide.FS.mkdirTree(target.slice(0, target.lastIndexOf("/")));
        pyodide.FS.writeFile(target, source);
      });
    }));
  }

  function importTranslation() {
    pyodide.globals.set("_phc_stack", JSON.stringify(STACK));
    return JSON.parse(pyodide.runPython([
      "import json, sys",
      "sys.path.insert(0, '/translation')",
      "import ph_composer_translation.entry",
      "json.dumps({'python': sys.version.split()[0],",
      "            'stack_loaded': sorted(m for m in sys.modules if m.split('.')[0] in json.loads(_phc_stack))})"
    ].join("\n")));
  }

  function start(deadlineMs) {
    if (boot) return boot;
    var started = window.performance.now();
    var stages = {};
    var mark = function (name, since) { stages[name] = Math.round(window.performance.now() - since); };
    state = "starting";
    bootCount += 1;
    boot = withDeadline(fetchAsset("vendor/manifest.json", "json").then(function (manifest) {
      wheelManifest = manifest;
      var step = window.performance.now();
      return loadScript("vendor/pyodide/pyodide.js").then(function () {
        return window.loadPyodide({ indexURL: ROOT + "vendor/pyodide/" });
      }).then(function (runtime) {
        pyodide = runtime;
        mark("pyodide", step);
        step = window.performance.now();
        return installTranslation(manifest);
      }).then(function () {
        var imported = importTranslation();
        mark("translation", step);
        return imported;
      });
    }), deadlineMs).then(function (imported) {
      if (state === "stopped") throw failure("runtime.stopped", "The runtime was stopped.");
      state = "ready";
      imported.cold_boot_ms = Math.round(window.performance.now() - started);
      imported.stages_ms = stages;
      return imported;
    }, function (error) {
      if (state !== "stopped") state = "failed";
      throw error;
    });
    return boot;
  }

  /* A failure before the runtime is ready is the boot's; one after it is the translation's. */
  function probe(payload) {
    start(payload.deadline_ms).then(function (info) {
      try {
        roundTrip(payload, info);
      } catch (error) {
        throw failure("runtime.translation_failed", "The translation package failed: " + (error.message || error));
      }
    }).catch(function (error) {
      send("runtime.result", { request_id: payload.request_id, session: session,
        error: { code: error.code || "runtime.boot_failed", message: error.message || "The runtime did not start." } });
    });
  }

  function roundTrip(payload, info) {
    var began = window.performance.now();
    pyodide.globals.set("_phc_document", PROBE_DOCUMENT);
    var result = JSON.parse(pyodide.runPython(
      "from ph_composer_translation.entry import probe_json\nprobe_json(_phc_document)"
    ));
    send("runtime.result", {
      request_id: payload.request_id, session: session, boot_count: bootCount, python: info.python,
      stack_loaded: info.stack_loaded, cold_boot_ms: info.cold_boot_ms, stages_ms: info.stages_ms,
      warm_round_trip_ms: Math.round((window.performance.now() - began) * 10) / 10, translation_state: result.state
    });
  }

  function stop() {
    state = "stopped";
    pyodide = null;
  }

  function translate(payload) {
    start(payload.deadline_ms).then(installWheels).then(function () {
      if (state === "stopped") return;
      pyodide.globals.set("_phc_document", JSON.stringify(payload.document));
      return pyodide.runPythonAsync(
        "from ph_composer_translation.entry import export_json\nexport_json(_phc_document)"
      ).then(function (text) {
        send("runtime.translation", { request_id: payload.request_id, session: session, result: JSON.parse(text) });
      });
    }).catch(function (error) {
      send("runtime.translation", { request_id: payload.request_id, session: session,
        error: { code: error.code || "runtime.translation_failed", message: "The export runtime failed." } });
    });
  }

  /* Install only shipped, manifest-pinned pure-Python wheels. No pip dependency resolution,
     external downloads or system-Python fallback occur in the host runtime. */
  function installWheels() {
    if (wheels) return wheels;
    wheels = Promise.all(wheelManifest.wheel_order.map(function (filename) {
      return window.fetch(ROOT + "vendor/wheels/" + filename).then(function (response) {
        if (!response.ok) throw failure("runtime.asset_refused", "A translation wheel was refused.");
        return response.arrayBuffer();
      }).then(function (buffer) {
        if (state === "stopped") throw failure("runtime.stopped", "The runtime was stopped.");
        pyodide.FS.mkdirTree("/wheel-downloads");
        pyodide.FS.writeFile("/wheel-downloads/" + filename, new Uint8Array(buffer));
      });
    })).then(function () {
      pyodide.globals.set("_phc_wheels", JSON.stringify(wheelManifest.wheel_order));
      return pyodide.runPythonAsync([
        "import json, sys, zipfile, os",
        "for _name in json.loads(_phc_wheels):",
        "    with zipfile.ZipFile('/wheel-downloads/' + _name) as _wheel:",
        "        _wheel.extractall('/translation-wheels')",
        "    os.remove('/wheel-downloads/' + _name)",
        "sys.path.insert(0, '/translation-wheels')"
      ].join("\n"));
    });
    return wheels;
  }

  window.PhComposerRuntime = {
    receive: function (envelope) {
      if (envelope && envelope.type === "runtime.probe") probe(envelope.payload || {});
      if (envelope && envelope.type === "runtime.translate") translate(envelope.payload || {});
      if (envelope && envelope.type === "runtime.stop") stop();
    },
    state: function () { return state; }
  };
  window.addEventListener("beforeunload", stop);
  send("runtime.ready", { session: session, cross_origin_isolated: window.crossOriginIsolated === true });
}());
