# /// script
# requires-python = ">=3.11"
# dependencies = ["websocket-client>=1.7"]
# ///
"""Boot the shipped runtime page in Chromium 88, the host floor's engine, and probe it.

Serves the manifest's assets with the isolation headers the extension's asset server sends, loads
html/runtime/index.html headless, and sends two probes at once. It checks cross-origin isolation,
single-flight boot, that importing the translation package loads none of the stack, and the cold-boot
and warm round-trip ceilings in the manifest. Not part of `make ci`: it launches a browser, and a
browser pass is not host evidence.

    uv run tools/runtime/browser_check.py [--download-chromium] [--out result.json]
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request
import zipfile
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

import websocket  # type: ignore[import-not-found,unused-ignore]  # PEP 723 dependency, not in the dev venv

ROOT = Path(__file__).resolve().parents[2]
EXTENSION = ROOT / "src" / "ph_composer"
MANIFEST = json.loads((EXTENSION / "vendor" / "manifest.json").read_text())
PAGE = "html/runtime/index.html"
# The predecessor's cached Chromium 88 snapshot, shared so it downloads once per machine.
DEFAULT_CHROME = (
    Path.home() / ".cache/ph-navigator-sketchup/chromium-88/chrome-mac/Chromium.app/Contents/MacOS/Chromium"
)
CHROME_DOWNLOAD = "https://commondatastorage.googleapis.com/chromium-browser-snapshots/Mac/827102/chrome-mac.zip"
REQUIRED_MAJOR = 88


def free_port() -> int:
    with socket.socket() as candidate:
        candidate.bind(("127.0.0.1", 0))
        return int(candidate.getsockname()[1])


def download_chrome(binary: Path) -> None:
    if not binary.exists():
        destination = binary.parents[3]
        destination.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="phc-chrome-") as temporary:
            archive = Path(temporary) / "chrome.zip"
            print(f"Downloading Chromium 88 to {destination}", file=sys.stderr)
            urllib.request.urlretrieve(CHROME_DOWNLOAD, archive)
            with zipfile.ZipFile(archive) as bundle:
                bundle.extractall(destination)
    for path in [*binary.parents[2].rglob("Contents/MacOS/*"), *binary.parents[2].rglob("chrome_crashpad_handler")]:
        if path.is_file():
            path.chmod(path.stat().st_mode | 0o111)


def chrome_major(binary: Path) -> int:
    output = subprocess.run([str(binary), "--version"], capture_output=True, text=True, check=True).stdout
    if not (match := re.search(r"(\d+)\.", output)):
        raise SystemExit(f"could not read the Chromium version from {output!r}")
    return int(match.group(1))


class RuntimeHandler(SimpleHTTPRequestHandler):
    """Serves declared assets only, with the headers runtime/http.rb sends."""

    allowed = set(MANIFEST["assets"]) | {MANIFEST["manifest_asset"]}

    def translate_path(self, path: str) -> str:
        relative = path.split("?", 1)[0].lstrip("/")
        return str(EXTENSION / (relative if relative in self.allowed else "__undeclared__"))

    def guess_type(self, path: Any) -> str:
        relative = Path(path).relative_to(EXTENSION).as_posix()
        entry = MANIFEST["assets"].get(relative)
        return str(entry["mime"]) if entry else "application/json"

    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, format: str, *args: Any) -> None:
        return


class CDP:
    """The few Chrome DevTools Protocol calls the check needs, over one websocket."""

    def __init__(self, url: str) -> None:
        self.socket = websocket.create_connection(url, timeout=60)
        self.next_id = 0
        self.console: list[str] = []

    def send(self, method: str, **params: Any) -> dict[str, Any]:
        self.next_id += 1
        self.socket.send(json.dumps({"id": self.next_id, "method": method, "params": params}))
        while True:
            message = json.loads(self.socket.recv())
            if message.get("method") == "Runtime.exceptionThrown":
                self.console.append(message["params"]["exceptionDetails"].get("text", "exception"))
            if message.get("id") == self.next_id:
                return dict(message)

    def evaluate(self, expression: str) -> Any:
        result = self.send("Runtime.evaluate", expression=expression, awaitPromise=True, returnByValue=True)["result"]
        if "exceptionDetails" in result:
            raise RuntimeError(json.dumps(result["exceptionDetails"])[:1000])
        return result["result"].get("value")


def page_websocket(port: int) -> str:
    deadline = time.time() + 30
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{port}/json", timeout=2) as response:
                pages = [target for target in json.load(response) if target.get("type") == "page"]
            if pages:
                return str(pages[0]["webSocketDebuggerUrl"])
        except (OSError, ValueError):
            pass
        time.sleep(0.2)
    raise SystemExit("Chromium did not expose a page over CDP")


# Installed before the page's own script: the host callback the page reports to.
DRIVER = """
window.__phc = {messages: []};
window.sketchup = {ph_composer_runtime: function (text) { window.__phc.messages.push(JSON.parse(text)); }};
"""

PROBE = """
new Promise(function (resolve) {
  function probe(id) {
    PhComposerRuntime.receive({type: "runtime.probe", payload: {request_id: id, deadline_ms: %d}});
  }
  probe("browser-one");
  probe("browser-two");
  var deadline = Date.now() + 30000;
  (function poll() {
    var results = window.__phc.messages.filter(function (m) { return m.type === "runtime.result"; });
    if (results.length >= 2 || Date.now() > deadline) {
      return resolve({messages: window.__phc.messages, isolated: window.crossOriginIsolated === true});
    }
    setTimeout(poll, 100);
  }());
});
"""


def run_browser(binary: Path) -> dict[str, Any]:
    major = chrome_major(binary)
    server = ThreadingHTTPServer(("127.0.0.1", free_port()), RuntimeHandler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = f"http://127.0.0.1:{server.server_address[1]}/{PAGE}?session=browser"
    debug_port = free_port()
    profile = Path(tempfile.mkdtemp(prefix="phc-c88-"))
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
        client = CDP(page_websocket(debug_port))
        client.send("Runtime.enable")
        client.send("Page.enable")
        client.send("Page.addScriptToEvaluateOnNewDocument", source=DRIVER)
        client.send("Page.navigate", url=url)
        observed = wait_for_page(client)
        observed.update(client.evaluate(PROBE % MANIFEST["gates"]["boot_deadline_ms"]))
    finally:
        if client:
            client.socket.close()
        process.terminate()
        process.wait(timeout=10)
        server.shutdown()
        shutil.rmtree(profile, ignore_errors=True)
    return verdict(major, observed, client.console if client else [])


def wait_for_page(client: CDP) -> dict[str, Any]:
    deadline = time.time() + 20
    while time.time() < deadline:
        try:
            if client.evaluate("typeof PhComposerRuntime") == "object":
                return {}
        except RuntimeError:
            pass
        time.sleep(0.2)
    raise SystemExit("the runtime page did not load")


def verdict(major: int, observed: dict[str, Any], console: list[str]) -> dict[str, Any]:
    results = [message["payload"] for message in observed["messages"] if message["type"] == "runtime.result"]
    gates = MANIFEST["gates"]
    checks = {
        "chromium_88": major == REQUIRED_MAJOR,
        "cross_origin_isolated": observed.get("isolated") is True,
        "two_results": len(results) == 2,
        "no_errors": all("error" not in result for result in results),
        "single_flight_boot": len(results) == 2 and all(result.get("boot_count") == 1 for result in results),
        "stack_not_loaded": len(results) == 2 and all(result.get("stack_loaded") == [] for result in results),
        "translation_answers": len(results) == 2
        and all(result.get("translation_state") == "complete" for result in results),
        "cold_boot_within_ceiling": bool(results)
        and all(result.get("cold_boot_ms", 10**9) <= gates["cold_boot_ceiling_ms"] for result in results),
        "warm_round_trip_within_ceiling": bool(results)
        and all(result.get("warm_round_trip_ms", 10**9) <= gates["warm_round_trip_ceiling_ms"] for result in results),
    }
    return {
        "verdict": "PASS" if all(checks.values()) else "FAIL",
        "checks": checks,
        "results": results,
        "console": console,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--download-chromium", action="store_true", help="download the pinned Chromium 88 if absent")
    parser.add_argument("--chrome", type=Path, default=DEFAULT_CHROME)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    subprocess.run([sys.executable, str(ROOT / "tools" / "runtime" / "vendor.py"), "--check"], check=True)
    if args.download_chromium:
        download_chrome(args.chrome)
    if not args.chrome.exists():
        raise SystemExit(f"Chromium 88 not found at {args.chrome}; pass --download-chromium")
    result = run_browser(args.chrome)
    print(json.dumps(result, indent=2))
    if args.out:
        args.out.write_text(json.dumps(result, indent=2) + "\n")
    return 0 if result["verdict"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
