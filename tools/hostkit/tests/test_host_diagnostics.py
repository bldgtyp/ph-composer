"""The diagnostic reader's client half without SketchUp: filter refusal before any host call, the exact Ruby
call it sends, and a wait enrichment that can never change or break the wait's ending."""

from __future__ import annotations

import unittest
from typing import Any

import host_diagnostics as hd

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
    def test_a_wait_gets_its_sessions_recent_warnings(self) -> None:
        host = Host({"status": "read", "events": [{"event": "x"}]})
        document = hd.for_wait(host.read, {"session": SESSION, "revision": "3"})

        self.assertEqual(document["events"], [{"event": "x"}])
        self.assertIn(f'"session" => "{SESSION}"', host.calls[0][0])
        self.assertIn('"severity" => "warning"', host.calls[0][0])

    def test_an_unavailable_reader_is_reported_beside_the_wait_not_raised(self) -> None:
        document = hd.for_wait(Host(ConnectionRefusedError("gone")).read, {"session": SESSION})

        self.assertEqual(document["status"], "unavailable")
        self.assertIn("gone", document["error"])


if __name__ == "__main__":
    unittest.main()
