"""The client half of the development diagnostic reader (tools/hostkit/diagnostic_reader.rb).

Filters are checked here against the exact forms the extension generates, and again in the host, so nothing
but those values reaches the Ruby call. The host answers a bounded, versioned document of the log's own
reduced records; this client adds nothing to it.

    uv run tools/hostkit/host_bridge.py diagnostics --session <uuid> --severity warning --json
    uv run tools/hostkit/host_bridge.py diagnostics --cursor <cursor from the last read>
    uv run tools/hostkit/host_bridge.py wait-for session_settled --param session=<uuid> --diagnostics --json
"""

from __future__ import annotations

import json
import re
from collections.abc import Callable
from pathlib import Path
from typing import Any

HELPERS = Path(__file__).resolve().parent / "host_helpers.rb"
MAX_LIMIT = 100
WAIT_LIMIT = 10

FILTERS: dict[str, re.Pattern[str]] = {
    "session": re.compile(r"\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z"),
    "incident": re.compile(r"\APHC-[0-9A-F]{6}\Z"),
    "run_id": re.compile(r"\Aexport_[0-9a-f]{24}\Z"),
    "severity": re.compile(r"\A(?:info|warning|error)\Z"),
    "cursor": re.compile(r"\A[0-9a-f]{8}:[0-9]{1,12}\Z"),
}


def validate(filters: dict[str, Any]) -> str | None:
    """Why these filters are refused, or None when every one is in an accepted form."""
    for name, value in filters.items():
        if name == "limit":
            if not (isinstance(value, int) and not isinstance(value, bool) and 1 <= value <= MAX_LIMIT):
                return f"limit must be an integer from 1 to {MAX_LIMIT}"
        elif name not in FILTERS:
            return f"unknown filter {name[:32]}"
        elif not (isinstance(value, str) and FILTERS[name].match(value)):
            return f"{name} is not in the form the extension generates"
    return None


def ruby_call(filters: dict[str, Any]) -> str:
    """The host call for already validated filters; loads the helpers when this process has not."""
    literal = ", ".join(f"{json.dumps(name)} => {json.dumps(value)}" for name, value in filters.items())
    return (
        f"load {json.dumps(str(HELPERS))} unless defined?(PhComposerHost) && "
        f"PhComposerHost.respond_to?(:diagnostics); PhComposerHost.diagnostics({{{literal}}})"
    )


def read(evaluate: Callable[[str, float], Any], filters: dict[str, Any], timeout: float = 30.0) -> dict[str, Any]:
    """One read. A refused filter answers a refusal document without calling the host."""
    if problem := validate(filters):
        return {"schema": 1, "kind": "ph-composer.diagnostic-read", "status": "refused", "error": problem}
    return evaluate(ruby_call(filters), timeout)


def for_wait(evaluate: Callable[[str, float], Any], params: dict[str, str]) -> dict[str, Any]:
    """Recent warnings and errors for a wait's session, to sit beside its ending. A wait's ending never
    depends on this: an unavailable reader is reported as such."""
    filters: dict[str, Any] = {"severity": "warning", "limit": WAIT_LIMIT}
    if FILTERS["session"].match(params.get("session", "")):
        filters["session"] = params["session"]
    try:
        return read(evaluate, filters, timeout=10.0)
    except Exception as error:  # noqa: BLE001 - any failure here is reported, never raised into the wait
        return {"status": "unavailable", "error": str(error)[:300]}
