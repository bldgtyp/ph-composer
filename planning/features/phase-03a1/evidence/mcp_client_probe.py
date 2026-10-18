# /// script
# requires-python = ">=3.10"
# ///
"""A minimal POST-only MCP server that records what a real client sends.

Retained evidence for P3a1-06, step 5: the protocol revision each CLI puts in `initialize`, the
headers it sends (with the bearer value masked), the methods it calls, and how its model sees a
tool result carrying both `content` and `structuredContent`. Not shipping code and not a design
for the Ruby ingress; it answers just enough of MCP for a client to list and call one tool.

    uv run evidence/mcp_client_probe.py --port 46199 --log evidence/client-probe.jsonl
"""

from __future__ import annotations

import argparse
import json
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

TOKEN = "probe-token-not-a-secret"
PROBE_TOOL = {
    "name": "probe_echo",
    "description": "Returns a fixed marker in content and a different marker in structuredContent.",
    "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
}
BIG_TOOL = {
    "name": "probe_big",
    "description": "Returns `kb` kilobytes of numbered lines as structuredContent only, to find the output cap.",
    "inputSchema": {"type": "object", "properties": {"kb": {"type": "integer"}}, "required": ["kb"],
                    "additionalProperties": False},
}


def numbered_lines(kb: int) -> list[str]:
    """Lines `LINE-000001 xxxx...` of 64 bytes each, `kb` KiB in all."""
    return [f"LINE-{n:06d} " + "x" * 51 for n in range(1, kb * 1024 // 64 + 1)]


class Probe(BaseHTTPRequestHandler):
    log_path: Path

    def log_message(self, *_args: Any) -> None:
        return

    def record(self, entry: dict[str, Any]) -> None:
        with self.log_path.open("a", encoding="utf-8") as file:
            file.write(json.dumps(entry) + "\n")

    def headers_masked(self) -> dict[str, str]:
        masked = {}
        for key, value in self.headers.items():
            if key.lower() == "authorization":
                value = "Bearer <matches probe token>" if value == f"Bearer {TOKEN}" else "<other>"
            masked[key] = value
        return masked

    def reply(self, status: int, body: dict[str, Any] | None) -> None:
        payload = json.dumps(body).encode() if body is not None else b""
        self.send_response(status)
        if body is not None:
            self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self) -> None:  # noqa: N802
        self.record({"t": time.time(), "verb": "GET", "path": self.path, "headers": self.headers_masked()})
        self.reply(405, None)

    def do_DELETE(self) -> None:  # noqa: N802
        self.record({"t": time.time(), "verb": "DELETE", "path": self.path, "headers": self.headers_masked()})
        self.reply(405, None)

    def do_POST(self) -> None:  # noqa: N802
        length = int(self.headers.get("Content-Length", "0"))
        message = json.loads(self.rfile.read(length) or b"null")
        self.record({"t": time.time(), "verb": "POST", "path": self.path, "headers": self.headers_masked(),
                     "message": message})
        if self.headers.get("Authorization") != f"Bearer {TOKEN}":
            self.reply(401, {"error": "unauthorized"})
            return
        if not isinstance(message, dict) or "id" not in message:
            self.reply(202, None)
            return
        method = message.get("method")
        if method == "initialize":
            result = {"protocolVersion": message["params"]["protocolVersion"],
                      "capabilities": {"tools": {}},
                      "serverInfo": {"name": "ph-composer-probe", "version": "0"}}
        elif method == "tools/list":
            result = {"tools": [PROBE_TOOL, BIG_TOOL]}
        elif method == "tools/call" and message["params"]["name"] == "probe_big":
            lines = numbered_lines(int(message["params"]["arguments"]["kb"]))
            result = {"content": [{"type": "text", "text": json.dumps({"lines": lines})}],
                      "structuredContent": {"lines": lines}, "isError": False}
        elif method == "tools/call":
            result = {"content": [{"type": "text", "text": "CONTENT-MARKER-7F3A"}],
                      "structuredContent": {"marker": "STRUCTURED-MARKER-9B2C"}, "isError": False}
        elif method == "ping":
            result = {}
        else:
            self.reply(200, {"jsonrpc": "2.0", "id": message["id"],
                             "error": {"code": -32601, "message": "Method not found"}})
            return
        self.reply(200, {"jsonrpc": "2.0", "id": message["id"], "result": result})


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=46199)
    parser.add_argument("--log", type=Path, required=True)
    args = parser.parse_args()
    Probe.log_path = args.log
    ThreadingHTTPServer(("127.0.0.1", args.port), Probe).serve_forever()


if __name__ == "__main__":
    main()
