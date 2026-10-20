"""Bounded waits for a named host condition, polled through the development bridge.

A wait never blocks inside one bridge eval: each poll is a short, separate host call, so SketchUp's UI
timers, observers and deferred work run between polls. The overall deadline and every call's socket timeout
come from one monotonic clock, so no call outlives the budget. The wait returns one structured ending with
the elapsed time, the poll count and the last projected state it read:

    met                 the condition held on the last poll
    timed_out           the deadline passed first
    cancelled           the developer interrupted the wait; the work it watched is untouched
    invalid_condition   an unknown condition or a parameter it does not accept; no host call was made
    session_missing     the session named is not open (never issued, or its Model closed)
    session_switched    another Model became the active one; the wait does not follow it
    target_missing      the session is open but the task or probe named is not there
    read_failed         the read raised in the host
    bridge_unavailable  no live bridge, or the connection failed

A condition is a named, read-only projection; it applies no operation, retries nothing, relaunches nothing,
switches no document and saves nothing. A timeout describes the observation, never the outcome of the work.
An observed condition is evidence for that condition alone.

    uv run tools/hostkit/host_bridge.py wait-for session_settled --param session=<uuid> --deadline 30
    uv run tools/hostkit/host_bridge.py wait-for revision_changed --param session=<uuid> --param revision=4
    uv run tools/hostkit/host_bridge.py wait-for export_finished --param session=<uuid> \\
        --param caller=<handle> --param task=export_<24 hex>
    uv run tools/hostkit/host_bridge.py wait-for runtime_probe_finished --param session=<uuid> \\
        --param probe_run=<12 hex from PhComposerRuntimeProbe.start> --deadline 120
"""

from __future__ import annotations

import json
import math
import re
import time
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any

SCHEMA = 1
KIND = "ph-composer.host-wait"
MAX_OBSERVED_CHARS = 4000
MAX_TEXT_CHARS = 300
MAX_PARAMS = 8
DEFAULT_DEADLINE_S = 60.0
DEFAULT_INTERVAL_S = 0.5
MAX_DEADLINE_S = 3600.0
MAX_INTERVAL_S = 60.0

ENDINGS = (
    "met",
    "timed_out",
    "cancelled",
    "invalid_condition",
    "session_missing",
    "session_switched",
    "target_missing",
    "read_failed",
    "bridge_unavailable",
)

# Each parameter in the exact form the extension generates it, so a value can be placed in Ruby source
# without quoting concerns and nothing else fits.
PARAMETERS: dict[str, re.Pattern[str]] = {
    "session": re.compile(r"\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z"),
    "revision": re.compile(r"\A[1-9][0-9]{0,9}\Z"),
    "caller": re.compile(r"\A[0-9a-f]{32}\Z"),
    "task": re.compile(r"\Aexport_[0-9a-f]{24}\Z"),
    "probe_run": re.compile(r"\A[0-9a-f]{12}\Z"),
}

# The session part every session condition shares: the session by its id, never the active Model's, and
# whether its Model is still the active one. `Sessions.find` drops closed sessions, as every registry read
# does; nothing here creates a session.
SESSION_READ = (
    "s = PhComposer::Sessions.find('{session}'); "
    "if s.nil? then {{'session' => 'missing'}} else "
    "{{'session' => 'open', 'active' => s.model == Sketchup.active_model, 'revision' => s.revision, "
    "'busy' => s.busy_reason}}.merge({extra}) end"
)


def session_read(extra: str = "{{}}") -> Callable[[dict[str, str]], str]:
    def build(params: dict[str, str]) -> str:
        return SESSION_READ.format(session=params["session"], extra=extra.format(**params))

    return build


@dataclass(frozen=True)
class Condition:
    """A named read: the Ruby projection it evaluates and when that projection counts as met."""

    name: str
    params: tuple[str, ...]
    description: str
    read: Callable[[dict[str, str]], str]
    met: Callable[[dict[str, Any], dict[str, str]], bool]
    session: bool = True


def export_task_read() -> Callable[[dict[str, str]], str]:
    # `owned_by` is the export tasks' public lookup by caller; the snapshot is taken without an asker, so it
    # carries no artifact location.
    return session_read(
        "begin; t = PhComposer::Export::Tasks.for(s).owned_by('{caller}').find {{ |x| x.id == '{task}' }}; "
        "t ? {{'task' => t.snapshot.slice('stage', 'count', 'cancellable')"
        ".merge('state' => t.snapshot['outcome'] && t.snapshot['outcome']['state'])}} "
        ": {{'task' => nil}}; end"
    )


def probe_read() -> Callable[[dict[str, str]], str]:
    # The probe is one global; it counts only while it is the named run in the named session. Another run, or
    # a probe for another session, is not this wait's target.
    return session_read(
        "begin; p = defined?(PhComposerRuntimeProbe) ? PhComposerRuntimeProbe.status : nil; "
        "if p.nil? then {{'probe' => nil, 'probe_state' => 'not_loaded'}} "
        "elsif p['run'] != '{probe_run}' || p['session'] != s.id then "
        "{{'probe' => nil, 'probe_state' => 'another_run'}} "
        "else {{'probe' => p.slice('state', 'run', 'verdict', 'elapsed_ms', 'requests')}} end; end"
    )


CONDITIONS: dict[str, Condition] = {
    condition.name: condition
    for condition in (
        Condition(
            "session_settled",
            ("session",),
            "the session has no change running and no deferred Model work pending",
            session_read(),
            lambda observed, _params: observed.get("busy") is None,
        ),
        Condition(
            "revision_changed",
            ("session", "revision"),
            "the session's revision differs from the one given (revisions compare for equality only)",
            session_read(),
            lambda observed, params: observed.get("revision") != int(params["revision"]),
        ),
        Condition(
            "export_finished",
            ("session", "caller", "task"),
            "the export task the caller started has an outcome",
            export_task_read(),
            lambda observed, _params: bool(observed.get("task")) and observed["task"].get("state") is not None,
        ),
        Condition(
            "runtime_probe_finished",
            ("session", "probe_run"),
            "the development runtime probe run (tools/hostkit/runtime_probe.rb) has both results or has stopped",
            probe_read(),
            lambda observed, _params: (
                observed["probe"].get("verdict") not in (None, "pending") or observed["probe"].get("state") == "stopped"
            ),
        ),
    )
}


@dataclass
class WaitResult:
    condition: str
    params: dict[str, str]
    ending: str
    elapsed_ms: int
    polls: int
    deadline_s: float
    interval_s: float
    last_observed: Any = None
    observed_at: str | None = None
    error: str | None = None
    started_at: str = field(default_factory=lambda: datetime.now(UTC).isoformat())

    def document(self) -> dict[str, Any]:
        return {
            "schema": SCHEMA,
            "kind": KIND,
            "condition": clip(self.condition),
            "params": bounded_params(self.params),
            "ending": self.ending,
            "met": self.ending == "met",
            "started_at": self.started_at,
            "elapsed_ms": self.elapsed_ms,
            "polls": self.polls,
            "deadline_s": self.deadline_s,
            "interval_s": self.interval_s,
            "last_observed": bounded(self.last_observed),
            "observed_at": self.observed_at,
            "error": clip(self.error) if self.error is not None else None,
            "note": "An observation only: it applied, retried and cancelled nothing.",
        }

    def summary(self) -> str:
        line = f"{clip(self.condition)}: {self.ending} after {self.elapsed_ms} ms and {self.polls} poll(s)"
        if self.error:
            line += f"; {clip(self.error)}"
        if self.last_observed is not None:
            line += f"; last observed {json.dumps(bounded(self.last_observed))}"
        return line


def clip(text: str, limit: int = MAX_TEXT_CHARS) -> str:
    """Text supplied from outside (a condition name, a parameter, a host error), cut with a marker."""
    return text if len(text) <= limit else f"{text[:limit]}… [{len(text) - limit} characters omitted]"


def bounded_params(params: dict[str, str]) -> dict[str, str]:
    kept = {clip(key, 64): clip(value) for key, value in list(params.items())[:MAX_PARAMS]}
    if len(params) > MAX_PARAMS:
        kept["…"] = f"{len(params) - MAX_PARAMS} more parameters omitted"
    return kept


def bounded(value: Any) -> Any:
    """The observed state, or a marked prefix of it when its JSON is longer than MAX_OBSERVED_CHARS."""
    text = json.dumps(value)
    if len(text) <= MAX_OBSERVED_CHARS:
        return value
    return {"truncated": True, "characters": len(text), "prefix": text[:MAX_OBSERVED_CHARS]}


def validate(name: str, params: dict[str, str]) -> str | None:
    """Why this condition and these parameters are refused, or None when they are accepted."""
    condition = CONDITIONS.get(name)
    if condition is None:
        return f"unknown condition {clip(name, 64)}; known: {', '.join(sorted(CONDITIONS))}"
    if missing := [key for key in condition.params if key not in params]:
        return f"{name} needs {', '.join(missing)}"
    if extra := sorted(set(params) - set(condition.params)):
        return clip(f"{name} does not take {', '.join(clip(key, 64) for key in extra)}")
    for key, value in params.items():
        if not PARAMETERS[key].match(value):
            return f"{key} is not in the form the extension generates"
    return None


def timing_problem(deadline_s: float, interval_s: float) -> str | None:
    """Why these timings are refused: each must be finite and positive, within its upper bound."""
    if not (math.isfinite(deadline_s) and 0 < deadline_s <= MAX_DEADLINE_S):
        return f"the deadline must be a number of seconds above 0 and at most {MAX_DEADLINE_S:.0f}"
    if not (math.isfinite(interval_s) and 0 < interval_s <= MAX_INTERVAL_S):
        return f"the interval must be a number of seconds above 0 and at most {MAX_INTERVAL_S:.0f}"
    return None


class ReadError(RuntimeError):
    """The read raised in the host; the bridge itself answered."""


def wait_for(
    name: str,
    params: dict[str, str],
    read: Callable[[str, float], Any],
    *,
    deadline_s: float = DEFAULT_DEADLINE_S,
    interval_s: float = DEFAULT_INTERVAL_S,
    clock: Callable[[], float] = time.monotonic,
    sleep: Callable[[float], None] = time.sleep,
    now: Callable[[], datetime] = lambda: datetime.now(UTC),
) -> WaitResult:
    """Poll `name` until it is met or the wait ends otherwise. `read(code, timeout)` evaluates one Ruby read
    and returns its value; it raises ReadError for a host-side error and OSError when the bridge is gone."""
    started = clock()
    result = WaitResult(name, dict(params), "timed_out", 0, 0, deadline_s, interval_s, started_at=now().isoformat())

    def end(ending: str, error: str | None = None) -> WaitResult:
        result.ending = ending
        result.error = error
        result.elapsed_ms = round((clock() - started) * 1000)
        return result

    if problem := validate(name, params) or timing_problem(deadline_s, interval_s):
        return end("invalid_condition", problem)
    condition = CONDITIONS[name]
    code = condition.read(params)
    try:
        while True:
            remaining = deadline_s - (clock() - started)
            if remaining <= 0:
                return end("timed_out")
            result.polls += 1
            try:
                observed = read(code, remaining)
            except ReadError as error:
                return end("read_failed", str(error))
            except TimeoutError:
                return end("timed_out", "the last read did not answer within the remaining budget")
            except OSError as error:
                return end("bridge_unavailable", str(error))
            result.last_observed = observed
            result.observed_at = now().isoformat()
            if clock() - started > deadline_s:
                return end("timed_out", "the last read answered after the deadline")
            if not isinstance(observed, dict):
                return end("read_failed", "the read did not return a projection")
            if condition.session and observed.get("session") == "missing":
                return end("session_missing", "the session is not open; the wait does not follow another Model")
            if condition.session and observed.get("active") is False:
                return end("session_switched", "another Model is active; the wait does not follow it")
            if observed.get("task", True) is None or observed.get("probe", True) is None:
                return end("target_missing", observed.get("probe_state"))
            if condition.met(observed, params):
                return end("met")
            remaining = deadline_s - (clock() - started)
            if remaining <= 0:
                return end("timed_out")
            sleep(min(interval_s, remaining))
    except KeyboardInterrupt:
        return end("cancelled", "interrupted by the developer; the watched work is unchanged")
