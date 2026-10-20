"""The fault controls' client half without SketchUp: refusal before any host call, the exact Ruby call,
and exit decisions that make a failed arm or restore stop a case."""

from __future__ import annotations

import unittest
from typing import Any

import host_faults as hf

SESSION = "0f8a6c2e-1b3d-4e5f-8a9b-0c1d2e3f4a5b"


class Host:
    def __init__(self, answer: Any) -> None:
        self.answer = answer
        self.calls: list[str] = []

    def read(self, code: str, _timeout: float) -> Any:
        self.calls.append(code)
        return self.answer


class FaultClientTest(unittest.TestCase):
    def test_malformed_targets_are_refused_without_a_host_call(self) -> None:
        cases = [
            ("arm", "lost_reply", {"session": SESSION, "request": "'; exit"}),
            ("arm", "silent_runtime", {"session": SESSION, "drop": ["runtime.closed"]}),
            ("arm", "silent_runtime", {"session": SESSION}),
            ("arm", "failed_write", {"session": SESSION, "key": "token_store"}),
            ("arm", "failed_write", {"session": "not-a-session", "key": "unit_system"}),
            ("arm", "failed_write", {"session": SESSION, "key": "unit_system", "drop": ["runtime.ready"]}),
            ("observe", "failed_write", {"session": SESSION}),
            ("arm", "unknown", {"session": SESSION}),
        ]
        for operation, name, target in cases:
            with self.subTest(operation=operation, name=name, target=target):
                host = Host({})
                document = hf.run(host.read, operation, name, target)
                self.assertEqual(document["status"], "refused")
                self.assertFalse(hf.succeeded(operation, document))
                self.assertEqual(host.calls, [])

    def test_an_accepted_arm_loads_the_controls_and_passes_the_target_as_literals(self) -> None:
        host = Host(
            {"schema": 1, "kind": hf.KIND, "revision": hf.REVISION, "status": "armed", "fault": "silent_runtime"}
        )
        document = hf.run(host.read, "arm", "silent_runtime", {"session": SESSION, "drop": ["runtime.ready"]})

        self.assertTrue(hf.succeeded("arm", document))
        self.assertIn("unless defined?(PhComposerFaults)", host.calls[0])
        self.assertIn(
            f'PhComposerFaults.arm("silent_runtime", {{"session" => "{SESSION}", "drop" => ["runtime.ready"]}})',
            host.calls[0],
        )

    def test_restore_succeeds_only_when_the_target_read_back_as_its_baseline(self) -> None:
        clean = {"status": "inert", "fault": "failed_write", "restore": {"restored": True}}
        dirty = {"status": "inert", "fault": "failed_write", "restore": {"restored": False, "problems": ["differs"]}}

        self.assertTrue(hf.succeeded("restore", clean))
        self.assertFalse(hf.succeeded("restore", dirty))
        self.assertFalse(hf.succeeded("arm", {"status": "refused"}))
        self.assertIn("restored False (differs)", hf.summary("restore", dirty))

    def test_an_answer_that_is_not_a_current_control_document_is_refused(self) -> None:
        current = {"schema": 1, "kind": hf.KIND, "status": "inert", "fault": "lost_reply"}
        for answer in ("text", {}, current, current | {"revision": hf.REVISION - 1}):
            with self.subTest(answer=answer):
                document = hf.run(Host(answer).read, "restore", "lost_reply", {})
                self.assertEqual(document["status"], "refused")
                self.assertFalse(hf.succeeded("restore", document))
                self.assertIn("refused", hf.summary("restore", document))

    def test_the_client_drives_the_revision_the_controls_declare(self) -> None:
        source = hf.CONTROLS.read_text()

        self.assertIn(f"REVISION = {hf.REVISION}", source)

    def test_an_uncertified_restore_fails_and_omitted_hits_are_reported(self) -> None:
        uncertified = {"status": "inert", "fault": "lost_reply", "restore": {"restored": False, "was_armed": False}}

        self.assertFalse(hf.succeeded("restore", uncertified))
        self.assertIn(
            "(5 not kept",
            hf.summary("observe", {"status": "armed", "fault": "x", "interceptions": 25, "omitted_hits": 5}),
        )


if __name__ == "__main__":
    unittest.main()
