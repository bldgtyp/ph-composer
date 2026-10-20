"""The client half of the development fault controls (tools/hostkit/fault_controls.rb).

Three separate operations per named fault, each one bridge call, each printing the host's versioned
document. Targets are checked here against the forms the extension generates, and again in the host, so
nothing else reaches the Ruby call. A case script chains them so a failed step stops it:

    uv run tools/hostkit/host_bridge.py fault arm silent_runtime --session <uuid> --drop runtime.ready --json
    uv run tools/hostkit/host_bridge.py fault observe silent_runtime --json
    uv run tools/hostkit/host_bridge.py fault restore silent_runtime --json   # exit 1 unless restored

`arm` exits 0 only when armed; `restore` exits 0 only when the target read back as its baseline with no
residual resource. Loading the controls arms nothing; a restored fault's interceptor stays inert until a
fresh process, which is the normal-build restoration every case still needs.
"""

from __future__ import annotations

import json
import re
from collections.abc import Callable
from pathlib import Path
from typing import Any

import host_diagnostics

CONTROLS = Path(__file__).resolve().parent / "fault_controls.rb"
NAMES = ("lost_reply", "silent_runtime", "failed_write")
OPERATIONS = ("arm", "observe", "restore")
RUNTIME_MESSAGES = ("runtime.ready", "runtime.translation")
PREFERENCE_KEYS = ("unit_system", "colour_by_mode", "table_views", "dimension_formats")
SESSION = re.compile(r"\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z")
REQUEST = re.compile(
    r"\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:[A-Za-z][A-Za-z0-9_. -]{0,47}:\d{1,9}\Z"
)


def refusal(operation: str, name: str, target: dict[str, Any]) -> str | None:
    """Why this call is refused before reaching the host, or None."""
    if operation not in OPERATIONS:
        return f"operation is one of {', '.join(OPERATIONS)}"
    if name not in NAMES:
        return f"fault is one of {', '.join(NAMES)}"
    if operation != "arm":
        return "only arm takes a target" if target else None
    if not SESSION.match(str(target.get("session", ""))):
        return "session is not in the form the extension generates"
    allowed = {
        "lost_reply": {"session", "request"},
        "silent_runtime": {"session", "drop"},
        "failed_write": {"session", "key"},
    }
    if extra := sorted(set(target) - allowed[name]):
        return f"{name} does not take {', '.join(extra)}"
    if name == "lost_reply" and not REQUEST.match(str(target.get("request", ""))):
        return "request is not in the form the extension generates"
    if name == "silent_runtime":
        drop = target.get("drop") or []
        if not drop or any(message not in RUNTIME_MESSAGES for message in drop):
            return f"drop names {' and/or '.join(RUNTIME_MESSAGES)}"
    if name == "failed_write" and target.get("key") not in PREFERENCE_KEYS:
        return f"key is one of {', '.join(PREFERENCE_KEYS)}"
    return None


def ruby_call(operation: str, name: str, target: dict[str, Any]) -> str:
    """The host call for an accepted operation. Loading the controls changes nothing by itself."""
    arguments = json.dumps(name)
    if operation == "arm":
        pairs = ", ".join(f"{json.dumps(key)} => {json.dumps(value)}" for key, value in target.items())
        arguments += f", {{{pairs}}}"
    return (
        f"load {host_diagnostics.ruby_string(str(CONTROLS))} unless defined?(PhComposerFaults); "
        f"PhComposerFaults.{operation}({arguments})"
    )


def run(evaluate: Callable[[str, float], Any], operation: str, name: str, target: dict[str, Any]) -> dict[str, Any]:
    if problem := refusal(operation, name, target):
        return {
            "schema": 1,
            "kind": "ph-composer.fault-control",
            "fault": name[:32],
            "status": "refused",
            "error": problem,
        }
    return evaluate(ruby_call(operation, name, target), 30.0)


def succeeded(operation: str, document: dict[str, Any]) -> bool:
    """Whether the operation did what a case relies on: armed, observed, or restored to its baseline."""
    if document.get("status") == "refused":
        return False
    if operation == "arm":
        return document.get("status") == "armed"
    if operation == "restore":
        return bool((document.get("restore") or {}).get("restored"))
    return True


def summary(operation: str, document: dict[str, Any]) -> str:
    if document.get("status") == "refused":
        return f"{document.get('fault')}: {operation} refused: {document.get('error')}"
    line = f"{document['fault']}: {document['status']}; {document.get('interceptions', 0)} interception(s)"
    if document.get("omitted_hits"):
        line += f" ({document['omitted_hits']} not kept in the hit log)"
    if restore := document.get("restore"):
        line += f"; restored {restore['restored']}"
        if restore.get("problems"):
            line += f" ({'; '.join(restore['problems'])})"
    if document.get("fresh_process_required"):
        line += "; the inert interceptor stays until a fresh process with the installed build"
    return line
