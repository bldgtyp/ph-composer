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
# does; nothing here creates a session. The bridge evaluates every call in one shared binding, so the read
# runs in a lambda whose variables are declared block-local: a case's own `s`, `t` or `p` survives a poll, and
# no session or task stays referenced after it.
SESSION_READ = (
    "->(; s, t, p, n) {{ s = PhComposer::Sessions.find('{session}'); "
    "if s.nil? then {{'session' => 'missing'}} else "
    "{{'session' => 'open', 'active' => s.model == Sketchup.active_model, 'revision' => s.revision, "
    "'busy' => s.busy_reason}}.merge({extra}) end }}.call"
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


def revision_of(observed: dict[str, Any]) -> int:
    """The observed revision; raises when it is not an integer, so the read ends as failed, never as met."""
    if not isinstance(revision := observed.get("revision"), int) or isinstance(revision, bool):
        raise TypeError("the projection has no integer revision")
    return revision


def export_task_read() -> Callable[[dict[str, str]], str]:
    # `owned_by` is the export tasks' public lookup by caller; one snapshot is taken, without an asker, so it
    # carries no artifact location. The outcome is null until the task ends, then the standard outcome, whose
    # `status` is completed, refused, failed or cancelled. Two effects are the tasks' own and not the wait's:
    # the first read of a session builds its empty task list, and `owned_by` prunes finished tasks past their
    # retention, as any status poll by the owner does.
    return session_read(
        "begin; t = PhComposer::Export::Tasks.for(s).owned_by('{caller}').find {{ |x| x.id == '{task}' }}; "
        "n = t && t.snapshot; "
        "n ? {{'task' => n.slice('stage', 'count', 'cancellable')"
        ".merge('status' => n['outcome'] && n['outcome']['status'])}} "
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
        "elsif p['state'] == 'stopped' && p['verdict'] == 'pending' then "
        "{{'probe' => nil, 'probe_state' => 'stopped_before_results'}} "
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
            lambda observed, params: revision_of(observed) != int(params["revision"]),
        ),
        Condition(
            "export_finished",
            ("session", "caller", "task"),
            "the export task the caller started has an outcome",
            export_task_read(),
            lambda observed, _params: observed["task"]["status"] is not None,
        ),
        Condition(
            "runtime_probe_finished",
            ("session", "probe_run"),
            "the development runtime probe run (tools/hostkit/runtime_probe.rb) has both results",
            probe_read(),
            lambda observed, _params: observed["probe"]["verdict"] not in (None, "pending"),
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
    # Recent diagnostic records beside the ending, when asked for (host_diagnostics.for_wait); never decides it.
    diagnostics: dict[str, Any] | None = None

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
            "deadline_s": finite(self.deadline_s),
            "interval_s": finite(self.interval_s),
            "last_observed": bounded(self.last_observed),
            "observed_at": self.observed_at,
            "error": clip(self.error) if self.error is not None else None,
            "note": "An observation only: it applied, retried and cancelled nothing.",
        } | ({} if self.diagnostics is None else {"diagnostics": self.diagnostics})

    def summary(self) -> str:
        line = f"{clip(self.condition)}: {self.ending} after {self.elapsed_ms} ms and {self.polls} poll(s)"
        if self.error:
            line += f"; {clip(self.error)}"
        if self.last_observed is not None:
            line += f"; last observed {json.dumps(bounded(self.last_observed))}"
        return line


def finite(value: float) -> float | None:
    """A timing as JSON can carry it: a refused NaN or infinity becomes null, and the error names it."""
    return value if math.isfinite(value) else None


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


def parse_params(items: list[str]) -> tuple[dict[str, str], str | None]:
    """`NAME=VALUE` items as a mapping, and why they are refused when a name repeats or has no `=`."""
    params: dict[str, str] = {}
    for item in items:
        key, separator, value = item.partition("=")
        if not separator:
            return params, f"parameter {clip(key, 64)} has no value"
        if key in params:
            return params, f"parameter {clip(key, 64)} is given twice"
        params[key] = value
    return params, None


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
    refused: str | None = None,
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

    try:
        if problem := refused or validate(name, params) or timing_problem(deadline_s, interval_s):
            return end("invalid_condition", problem)
        condition = CONDITIONS[name]
        code = condition.read(params)
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
            if observed.get("session") == "missing":
                return end("session_missing", "the session is not open; the wait does not follow another Model")
            if observed.get("session") != "open" or not isinstance(observed.get("active"), bool):
                return end("read_failed", "the read did not return a session projection")
            if observed["active"] is False:
                return end("session_switched", "another Model is active; the wait does not follow it")
            if observed.get("task", True) is None or observed.get("probe", True) is None:
                return end("target_missing", observed.get("probe_state"))
            try:
                met = condition.met(observed, params)
            except (KeyError, TypeError, AttributeError, ValueError):
                return end("read_failed", "the projection did not have the condition's shape")
            if met:
                return end("met")
            remaining = deadline_s - (clock() - started)
            if remaining <= 0:
                return end("timed_out")
            sleep(min(interval_s, remaining))
    except KeyboardInterrupt:
        return end("cancelled", "interrupted by the developer; the watched work is unchanged")
