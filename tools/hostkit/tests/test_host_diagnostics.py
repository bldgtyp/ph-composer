"""The diagnostic reader's client half without SketchUp: filter refusal before any host call, the exact Ruby
call it sends, and a wait enrichment that can never change or break the wait's ending."""

from __future__ import annotations

import argparse
import io
import unittest
from typing import Any
from unittest.mock import patch

import host_bridge as hb
import host_diagnostics as hd
import host_wait as hw

SESSION = "0f8a6c2e-1b3d-4e5f-8a9b-0c1d2e3f4a5b"


class Host:
    def __init__(self, answer: Any) -> None:
        self.answer = answer
        self.calls: list[tuple[str, float]] = []

    def read(self, code: str, timeout: float) -> Any:
        self.calls.append((code, timeout))
        if isinstance(self.answer, BaseException):
            raise self.answer
        return self.answer


class ReadTest(unittest.TestCase):
    def test_malformed_filters_are_refused_without_a_host_call(self) -> None:
        cases = [
            {"session": "'; system('x'); '"},
            {"incident": "PHC-abc123"},
            {"severity": "fatal"},
            {"cursor": "../ph-composer.log"},
            {"limit": 0},
            {"limit": True},
            {"path": "/etc/passwd"},
        ]
        for filters in cases:
            with self.subTest(filters=filters):
                host = Host({"status": "read"})
                document = hd.read(host.read, filters)
                self.assertEqual(document["status"], "refused")
                self.assertEqual(host.calls, [])

    def test_accepted_filters_reach_the_helper_as_literals_and_load_it_when_absent(self) -> None:
        host = Host({"status": "read", "events": []})
        hd.read(host.read, {"session": SESSION, "severity": "warning", "limit": 5}, timeout=7.0)

        code, timeout = host.calls[0]
        self.assertEqual(timeout, 7.0)
        self.assertIn("unless defined?(PhComposerHost) && PhComposerHost.respond_to?(:diagnostics)", code)
        self.assertIn(
            f'PhComposerHost.diagnostics({{"session" => "{SESSION}", "severity" => "warning", "limit" => 5}})', code
        )


class WaitEnrichmentTest(unittest.TestCase):
    def test_a_wait_gets_its_sessions_newest_warnings_within_its_remaining_budget(self) -> None:
        host = Host({"status": "read", "events": [{"event": "x"}]})
        document = hd.for_wait(host.read, {"session": SESSION, "revision": "3"}, budget=2.5)

        self.assertEqual(document["events"], [{"event": "x"}])
        code, timeout = host.calls[0]
        self.assertEqual(timeout, 2.5)
        self.assertIn(f'"session" => "{SESSION}"', code)
        self.assertIn('"severity" => "warning"', code)
        self.assertIn('"newest" => true', code)

    def test_no_budget_left_means_no_read(self) -> None:
        host = Host({"status": "read"})
        document = hd.for_wait(host.read, {"session": SESSION}, budget=0.0)

        self.assertEqual(document["status"], "skipped")
        self.assertEqual(host.calls, [])

    def test_newest_takes_no_cursor(self) -> None:
        host = Host({"status": "read"})
        self.assertEqual(hd.read(host.read, {"newest": True, "cursor": "0123abcd:4"})["status"], "refused")
        self.assertEqual(hd.read(host.read, {"newest": "yes"})["status"], "refused")
        self.assertEqual(host.calls, [])

    def test_an_unavailable_reader_is_reported_beside_the_wait_not_raised(self) -> None:
        document = hd.for_wait(Host(ConnectionRefusedError("gone")).read, {"session": SESSION}, budget=1.0)

        self.assertEqual(document["status"], "unavailable")
        self.assertIn("gone", document["error"])


class WaitCommandTest(unittest.TestCase):
    """`wait-for --diagnostics` reads only within the wait's budget, never after a cancel, and prints them."""

    def run_command(self, ending: str, elapsed_ms: int, json_output: bool = False) -> tuple[list[str], str]:
        result = hw.WaitResult("session_settled", {"session": SESSION}, ending, elapsed_ms, 1, 1.0, 0.5)
        args = argparse.Namespace(
            condition="session_settled",
            param=[f"session={SESSION}"],
            deadline=1.0,
            interval=0.5,
            json=json_output,
            diagnostics=True,
        )
        budgets: list[float] = []

        def for_wait(_read: object, _params: object, budget: float) -> dict[str, Any]:
            budgets.append(budget)
            return {"status": "read", "events": [], "matched": 0, "cursor_state": "newest", "health": {"writing": True}}

        with (
            patch.object(hb.host_wait, "wait_for", return_value=result),
            patch.object(hb.host_diagnostics, "for_wait", side_effect=for_wait),
            patch("sys.stdout", new_callable=io.StringIO) as out,
        ):
            hb.run_wait_for(args, "2026")
        return [f"{value:.2f}" for value in budgets], out.getvalue()

    def test_the_read_gets_what_is_left_and_the_text_output_shows_it(self) -> None:
        budgets, out = self.run_command("met", 400)

        self.assertEqual(budgets, ["0.60"])
        self.assertIn("0 of 0 matching record(s); newest", out)

    def test_a_cancelled_wait_reads_nothing(self) -> None:
        budgets, _out = self.run_command("cancelled", 400)

        self.assertEqual(budgets, [])


if __name__ == "__main__":
    unittest.main()
