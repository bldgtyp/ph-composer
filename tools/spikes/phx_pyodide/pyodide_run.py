# /// script
# requires-python = ">=3.11"
# dependencies = ["websocket-client>=1.7"]
# ///
"""B1 spike: the native reference conversion, run in the pinned Pyodide 0.24.1 inside Chromium 88.

Reuses tools/runtime/browser_check.py's Chromium, CDP client and isolation headers. Serves the shipped
Pyodide core from src/ph_composer/vendor/pyodide/, this folder's convert.py, and the work folder's
wheels/, two_rooms.hbjson and native_metr.json (README.md). Development only; never shipped.

    uv run tools/spikes/phx_pyodide/pyodide_run.py <work-folder>
"""

import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO / "tools" / "runtime"))
import browser_check as bc  # noqa: E402

HERE = Path(__file__).resolve().parent
WORK = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else HERE
PYODIDE = REPO / "src" / "ph_composer" / "vendor" / "pyodide"
# Dependency order: geometry, core, standards, energy, units, PH, PHX.
WHEELS = [
    "ladybug_geometry-1.35.3-py3-none-any.whl",
    "ladybug_geometry_polyskel-1.7.52-py3-none-any.whl",
    "ladybug_core-0.44.56-py3-none-any.whl",
    "honeybee_core-1.64.65-py3-none-any.whl",
    "honeybee_standards-2.0.7-py2.py3-none-any.whl",
    "honeybee_energy-1.123.23-py3-none-any.whl",
    "ph_units-1.5.38-py3-none-any.whl",
    "honeybee_ph-1.33.65-py3-none-any.whl",
    "phx-1.57.1-py3-none-any.whl",
]
PAGE = (
    b"<!doctype html><meta charset='utf-8'><link rel='icon' href='data:,'><script src='/pyodide/pyodide.js'></script>"
)


class Handler(SimpleHTTPRequestHandler):
    def translate_path(self, path: str) -> str:
        relative = path.split("?", 1)[0].lstrip("/")
        if relative.startswith("pyodide/"):
            return str(PYODIDE / relative.removeprefix("pyodide/"))
        return str((HERE if relative == "convert.py" else WORK) / relative)

    def do_GET(self) -> None:
        if self.path.split("?", 1)[0] == "/":
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(PAGE)
            return
        super().do_GET()

    def guess_type(self, path) -> str:
        return "application/wasm" if str(path).endswith(".wasm") else super().guess_type(path)

    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, format, *args) -> None:
        return


RUN = """
(async function () {
  var t0 = performance.now();
  var py = await loadPyodide({indexURL: "/pyodide/"});
  var t1 = performance.now();
  var wheels = %s, loaded = [];
  for (var i = 0; i < wheels.length; i++) {
    var buffer = await (await fetch("/wheels/" + wheels[i])).arrayBuffer();
    py.unpackArchive(buffer, "wheel");
    loaded.push(wheels[i]);
  }
  var t2 = performance.now();
  py.FS.writeFile("/home/pyodide/convert.py", await (await fetch("/convert.py")).text());
  py.globals.set("hbjson_text", await (await fetch("/two_rooms.hbjson")).text());
  py.runPython("import sys; sys.path.insert(0, '/home/pyodide'); import convert");
  var out = py.runPython("convert.run_first(hbjson_text)");
  var t3 = performance.now();
  var warm = py.runPython("convert.run_warm(hbjson_text)");
  return {
    result: JSON.parse(out), warm: JSON.parse(warm), isolated: window.crossOriginIsolated === true, loaded: loaded,
    ms: {pyodide: Math.round(t1 - t0), wheels: Math.round(t2 - t1), first_convert_incl_import: Math.round(t3 - t2)}
  };
}())
"""


def main() -> int:
    binary = bc.DEFAULT_CHROME
    major = bc.chrome_major(binary)
    server = ThreadingHTTPServer(("127.0.0.1", bc.free_port()), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    debug_port = bc.free_port()
    profile = Path(tempfile.mkdtemp(prefix="phc-b1-"))
    process = subprocess.Popen(
        [
            str(binary),
            "--headless",
            "--no-first-run",
            "--disable-gpu",
            "--disable-background-networking",
            f"--remote-debugging-port={debug_port}",
            f"--user-data-dir={profile}",
            "about:blank",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    client = None
    try:
        client = bc.CDP(bc.page_websocket(debug_port))
        client.send("Runtime.enable")
        client.send("Page.enable")
        client.send("Page.navigate", url=f"http://127.0.0.1:{server.server_address[1]}/")
        for _ in range(100):
            if client.evaluate("typeof loadPyodide") == "function":
                break
            threading.Event().wait(0.2)
        client.socket.settimeout(300)
        observed = client.evaluate(RUN % json.dumps(WHEELS))
    finally:
        if client:
            client.socket.close()
        process.terminate()
        process.wait(timeout=10)
        server.shutdown()
        shutil.rmtree(profile, ignore_errors=True)
    metr = observed["result"].pop("metr_text")
    (WORK / "pyodide_metr.json").write_text(metr)
    native = (WORK / "native_metr.json").read_text()
    observed.update(
        {
            "chromium_major": major,
            "pyodide_sha256": hashlib.sha256(metr.encode()).hexdigest(),
            "native_sha256": hashlib.sha256(native.encode()).hexdigest(),
            "identical_to_native": metr == native,
            "console": client.console if client else [],
        }
    )
    print(json.dumps(observed, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
