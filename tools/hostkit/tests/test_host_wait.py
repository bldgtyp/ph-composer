"""The bounded host wait without SketchUp: a fake read and a fake clock stand in for the bridge and time.

What is under test is the wait's own decisions: separate polls, the deadline and per-call budget, and one
distinct ending for each way a wait can stop, each carrying the last state it observed.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import unittest
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import host_wait as hw

SESSION = "0f8a6c2e-1b3d-4e5f-8a9b-0c1d2e3f4a5b"
OTHER = "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"
CALLER = "0123456789abcdef0123456789abcdef"
TASK = "export_0123456789abcdef01234567"
RUN = "0123456789ab"


class FakeClock:
    """Advances only when the wait sleeps, or when a read takes time."""

    def __init__(self) -> None:
        self.now = 500.0
        self.sleeps: list[float] = []

    def monotonic(self) -> float:
        return self.now

    def sleep(self, seconds: float) -> None:
        self.sleeps.append(seconds)
        self.now += seconds


class Host:
    """A scripted host: each read returns the next answer (or raises it), after `read_cost` seconds."""

    def __init__(self, clock: FakeClock, answers: list[Any], read_cost: float = 0.0) -> None:
        self.clock = clock
        self.answers = list(answers)
        self.read_cost = read_cost
        self.calls: list[tuple[str, float]] = []

    def read(self, code: str, timeout: float) -> Any:
        self.calls.append((code, timeout))
        self.clock.now += self.read_cost
        answer = self.answers.pop(0) if len(self.answers) > 1 else self.answers[0]
        if isinstance(answer, BaseException):
            raise answer
        return answer


def run(name: str, params: dict[str, str], answers: list[Any], **options: Any) -> tuple[hw.WaitResult, Host, FakeClock]:
    clock = FakeClock()
    host = Host(clock, answers, options.pop("read_cost", 0.0))
    result = hw.wait_for(
        name,
        params,
        host.read,
        clock=clock.monotonic,
        sleep=clock.sleep,
        now=lambda: datetime(2026, 10, 20, tzinfo=UTC),
        **options,
    )
    return result, host, clock


def session(busy: str | None = None, revision: int = 3, active: bool = True, **extra: Any) -> dict[str, Any]:
    return {"session": "open", "active": active, "revision": revision, "busy": busy, **extra}


class EndingsTest(unittest.TestCase):
    def test_a_condition_met_after_separate_polls_reports_the_polls_and_the_state_it_met(self) -> None:
        busy = "This Model has deferred work that has not finished."
        result, host, clock = run("session_settled", {"session": SESSION}, [session(busy), session(busy), session()])

        self.assertEqual(result.ending, "met")
        self.assertEqual(result.polls, 3)
        self.assertEqual(len(host.calls), 3, "each poll is its own host call, so host timers run between them")
        self.assertEqual(clock.sleeps, [0.5, 0.5])
        self.assertEqual(result.last_observed, session())
        self.assertIn(SESSION, host.calls[0][0])

    def test_the_deadline_bounds_the_wait_and_the_timeout_keeps_the_last_observed_state(self) -> None:
        busy = session("Another change to this Model is still running.")
        result, _host, clock = run("session_settled", {"session": SESSION}, [busy], deadline_s=2.0, interval_s=0.75)

        self.assertEqual(result.ending, "timed_out")
        self.assertEqual(result.elapsed_ms, 2000)
        self.assertEqual(clock.sleeps, [0.75, 0.75, 0.5], "the last sleep is cut to what remains")
        self.assertEqual(result.last_observed, busy)

    def test_every_read_is_given_only_the_remaining_budget(self) -> None:
        busy = session("busy")
        _result, host, _clock = run("session_settled", {"session": SESSION}, [busy], deadline_s=3.0, read_cost=1.0)

        self.assertEqual([timeout for _code, timeout in host.calls], [3.0, 1.5])

    def test_a_short_deadline_is_never_widened_and_a_late_answer_is_not_success(self) -> None:
        result, host, _clock = run(
            "session_settled", {"session": SESSION}, [session()], deadline_s=0.05, read_cost=0.15
        )

        self.assertEqual(host.calls[0][1], 0.05, "the read gets the real remaining budget, with no floor")
        self.assertEqual(result.ending, "timed_out")
        self.assertEqual(result.last_observed, session(), "the late observation is still reported")

    def test_a_read_that_outlasts_the_budget_is_a_timeout_not_a_lost_bridge(self) -> None:
        result, _host, _clock = run("session_settled", {"session": SESSION}, [TimeoutError("timed out")])

        self.assertEqual(result.ending, "timed_out")

    def test_a_revision_compares_for_equality_only(self) -> None:
        unchanged, _host, _clock = run(
            "revision_changed", {"session": SESSION, "revision": "3"}, [session(revision=3)], deadline_s=1.0
        )
        changed, _host, _clock = run("revision_changed", {"session": SESSION, "revision": "3"}, [session(revision=2)])

        self.assertEqual(unchanged.ending, "timed_out")
        self.assertEqual(changed.ending, "met")

    def test_a_closed_session_and_a_switched_model_are_distinct_endings_and_neither_is_followed(self) -> None:
        missing, missing_host, _clock = run(
            "session_settled", {"session": SESSION}, [session("x"), {"session": "missing"}]
        )
        switched, switched_host, _clock = run("session_settled", {"session": SESSION}, [session(active=False)])

        self.assertEqual(missing.ending, "session_missing")
        self.assertEqual(missing.last_observed, {"session": "missing"})
        self.assertEqual(switched.ending, "session_switched")
        self.assertEqual(len(missing_host.calls), 2)
        self.assertEqual(len(switched_host.calls), 1, "no further read targets the newly active Model")

    def test_an_export_task_ends_when_it_has_an_outcome_and_a_missing_task_is_named(self) -> None:
        params = {"session": SESSION, "caller": CALLER, "task": TASK}
        running = session(task={"stage": "translating", "count": 2, "cancellable": True, "status": None})
        done = session(task={"stage": "finished", "count": 2, "cancellable": False, "status": "completed"})
        finished, _host, _clock = run("export_finished", params, [running, done])
        absent, _host, _clock = run("export_finished", params, [session(task=None)])

        self.assertEqual(finished.ending, "met")
        self.assertEqual(finished.polls, 2)
        self.assertEqual(absent.ending, "target_missing")

    def test_a_probe_wait_is_bound_to_its_session_and_run(self) -> None:
        params = {"session": SESSION, "probe_run": RUN}
        pending = session(probe={"state": "ready", "run": RUN, "verdict": "pending"})
        passed = session(probe={"state": "ready", "run": RUN, "verdict": "PASS"})
        met, host, _clock = run("runtime_probe_finished", params, [pending, passed])
        replaced, _host, _clock = run(
            "runtime_probe_finished", params, [pending, session(probe=None, probe_state="another_run")]
        )
        unloaded, _host, _clock = run("runtime_probe_finished", params, [session(probe=None, probe_state="not_loaded")])
        switched, _host, _clock = run("runtime_probe_finished", params, [session(active=False, probe=None)])

        self.assertEqual(met.ending, "met")
        self.assertIn(RUN, host.calls[0][0])
        self.assertEqual((replaced.ending, replaced.error), ("target_missing", "another_run"))
        self.assertEqual((unloaded.ending, unloaded.error), ("target_missing", "not_loaded"))
        self.assertEqual(switched.ending, "session_switched")
        self.assertEqual(run("runtime_probe_finished", {"session": SESSION}, [passed])[0].ending, "invalid_condition")

    def test_a_host_error_and_a_lost_bridge_are_distinct_endings(self) -> None:
        failed, _host, _clock = run("session_settled", {"session": SESSION}, [hw.ReadError("NameError: PhComposer")])
        lost, _host, _clock = run(
            "session_settled", {"session": SESSION}, [session("x"), ConnectionRefusedError("refused")]
        )

        self.assertEqual(failed.ending, "read_failed")
        self.assertIn("NameError", failed.error or "")
        self.assertEqual(lost.ending, "bridge_unavailable")
        self.assertEqual(lost.last_observed, session("x"), "the last observed state survives the lost bridge")

    def test_a_projection_of_the_wrong_shape_is_a_failed_read_never_met(self) -> None:
        cases = {
            "session_settled": ({"session": SESSION}, [{}, {"x": 1}, {"session": "open"}]),
            "revision_changed": ({"session": SESSION, "revision": "3"}, [{"session": "open", "active": True}]),
            "runtime_probe_finished": ({"session": SESSION, "probe_run": RUN}, [session(probe="not a dict")]),
            "export_finished": ({"session": SESSION, "caller": CALLER, "task": TASK}, [session(task={})]),
        }
        for name, (params, answers) in cases.items():
            for answer in answers:
                with self.subTest(name=name, answer=answer):
                    result, _host, _clock = run(name, params, [answer])
                    self.assertEqual(result.ending, "read_failed")

    def test_a_probe_that_stopped_before_its_results_is_not_met(self) -> None:
        params = {"session": SESSION, "probe_run": RUN}
        result, _host, _clock = run(
            "runtime_probe_finished", params, [session(probe=None, probe_state="stopped_before_results")]
        )

        self.assertEqual((result.ending, result.error), ("target_missing", "stopped_before_results"))

    def test_a_repeated_or_valueless_parameter_is_refused(self) -> None:
        for items in (["session=a", "session=b"], ["session"]):
            with self.subTest(items=items):
                params, refused = hw.parse_params(items)
                result, host, _clock = run("session_settled", params, [session()], refused=refused)
                self.assertEqual(result.ending, "invalid_condition")
                self.assertEqual(host.calls, [])

    def test_an_interrupt_cancels_the_observation_only(self) -> None:
        result, _host, _clock = run("session_settled", {"session": SESSION}, [session("x"), KeyboardInterrupt()])

        self.assertEqual(result.ending, "cancelled")
        self.assertEqual(result.polls, 2)

    def test_an_unknown_condition_or_malformed_parameter_is_refused_before_any_host_call(self) -> None:
        cases = {
            "no_such_condition": {"session": SESSION},
            "session_settled": {"session": "'; Sketchup.active_model.entities.clear!; '"},
            "revision_changed": {"session": SESSION},
        }
        for name, params in cases.items():
            with self.subTest(name=name):
                result, host, _clock = run(name, params, [session()])
                self.assertEqual(result.ending, "invalid_condition")
                self.assertEqual(host.calls, [])
                json.dumps(result.document(), allow_nan=False)  # strict JSON, as JSON.parse would read it
        extra, _host, _clock = run("session_settled", {"session": SESSION, "task": TASK}, [session()])
        self.assertEqual(extra.error, "session_settled does not take task")

    def test_timings_that_are_not_finite_positive_and_bounded_are_refused(self) -> None:
        for deadline, interval in ((float("nan"), 0.5), (float("inf"), 0.5), (0.0, 0.5), (10.0, -1.0), (10.0, 0.0)):
            with self.subTest(deadline=deadline, interval=interval):
                result, host, _clock = run(
                    "session_settled", {"session": SESSION}, [session()], deadline_s=deadline, interval_s=interval
                )
                self.assertEqual(result.ending, "invalid_condition")
                self.assertEqual(host.calls, [])


class DocumentTest(unittest.TestCase):
    def test_the_document_is_versioned_bounded_and_says_it_is_an_observation(self) -> None:
        huge = session(note="x" * (hw.MAX_OBSERVED_CHARS + 50))
        result, _host, _clock = run("session_settled", {"session": SESSION}, [huge], deadline_s=0.5)
        document = result.document()

        self.assertEqual(document["schema"], hw.SCHEMA)
        self.assertEqual(document["kind"], hw.KIND)
        self.assertEqual(document["ending"], "met")
        self.assertTrue(document["met"])
        self.assertTrue(document["last_observed"]["truncated"])
        self.assertEqual(len(document["last_observed"]["prefix"]), hw.MAX_OBSERVED_CHARS)
        self.assertEqual(document["observed_at"], "2026-10-20T00:00:00+00:00")
        self.assertIn("observation only", document["note"])
        self.assertIn("session_settled: met after 0 ms and 1 poll(s)", result.summary())

    def test_names_parameters_and_errors_from_outside_are_bounded_too(self) -> None:
        params: dict[str, str] = {f"k{index}{'x' * 5000}": str("v" * 100_000) for index in range(20)}
        result, _host, _clock = run("n" * 100_000, params, [session()])
        document = result.document()
        failed, _host, _clock = run("session_settled", {"session": SESSION}, [hw.ReadError("E" * 100_000)])

        self.assertLess(len(json.dumps(document)), 6000)
        self.assertIn("characters omitted", document["condition"])
        self.assertIn("more parameters omitted", document["params"]["…"])
        self.assertLess(len(json.dumps(failed.document())), 6000)
        self.assertLess(len(failed.summary()), 2000)


@unittest.skipUnless(shutil.which(os.environ.get("RUBY", "ruby")), "needs Ruby to parse the reads")
class ReadSyntaxTest(unittest.TestCase):
    def test_every_condition_read_is_valid_ruby(self) -> None:
        params = {"session": SESSION, "revision": "3", "caller": CALLER, "task": TASK, "probe_run": RUN}
        for name, condition in hw.CONDITIONS.items():
            with self.subTest(name=name):
                code = condition.read({key: params[key] for key in condition.params})
                done = subprocess.run(
                    [os.environ.get("RUBY", "ruby"), "-c", "-e", code], capture_output=True, text=True, check=False
                )
                self.assertEqual(done.returncode, 0, done.stderr)


@unittest.skipUnless(shutil.which(os.environ.get("RUBY", "ruby")), "needs Ruby to run the reads")
class ReadBindingTest(unittest.TestCase):
    """The bridge shares one binding across evals: a poll must not overwrite a case's locals. The Ruby stubs
    are written for Ruby 2.7, the floor host's version: no endless methods."""

    STUB = (
        "module PhComposer; module Sessions; Session = Struct.new(:model, :revision, :busy_reason); "
        "def self.find(_id); Session.new(:m, 4, nil); end; end; end; "
        "module Sketchup; def self.active_model; :m; end; end; "
    )

    def test_a_session_read_leaves_the_cases_own_variables_alone(self) -> None:
        code = hw.CONDITIONS["session_settled"].read({"session": SESSION})
        script = f"{self.STUB} s = :case_value; t = :task; value = {code}; p [s, t, value]"
        done = subprocess.run(
            [os.environ.get("RUBY", "ruby"), "-e", script], capture_output=True, text=True, check=False
        )

        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn(":case_value, :task", done.stdout)
        self.assertIn('"revision"=>4', done.stdout.replace(" => ", "=>"))

    def test_the_export_read_reports_the_outcome_status_of_the_real_outcome_shape(self) -> None:
        # The task snapshot carries the extension's own outcome (src/ph_composer/shell/outcome.rb); a read that
        # projected another key would never be met.
        root = Path(__file__).resolve().parents[3]
        stub = (
            "module PhComposer; end; require './src/ph_composer/shell/outcome'; "
            "module PhComposer; module Export; class Tasks; Task = Struct.new(:id, :snapshot); "
            "def self.for(_session); new; end; "
            f"def owned_by(_handle); [Task.new('{TASK}', {{'stage' => 'finished', 'count' => 2, "
            "'cancellable' => false, 'outcome' => PhComposer::Outcome.build('completed', 'export.complete', "
            "'Done.', 'none', 3)})]; end; end; end; "
            "module Sessions; Session = Struct.new(:id, :model, :revision, :busy_reason); "
            f"def self.find(_id); Session.new('{SESSION}', :m, 3, nil); end; end; end; "
            "module Sketchup; def self.active_model; :m; end; end; require 'json'; "
        )
        code = hw.CONDITIONS["export_finished"].read({"session": SESSION, "caller": CALLER, "task": TASK})
        done = subprocess.run(
            [os.environ.get("RUBY", "ruby"), "-e", f"{stub} puts JSON.generate({code})"],
            capture_output=True,
            text=True,
            check=False,
            cwd=root,
        )
        self.assertEqual(done.returncode, 0, done.stderr)
        observed = json.loads(done.stdout)

        self.assertEqual(observed["task"]["status"], "completed")
        self.assertTrue(hw.CONDITIONS["export_finished"].met(observed, {}))


if __name__ == "__main__":
    unittest.main()
