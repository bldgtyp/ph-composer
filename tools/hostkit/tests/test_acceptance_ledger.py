"""Exercise evidence integrity and invalidation without running or mutating SketchUp."""

from __future__ import annotations

import json
import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any

import acceptance_ledger as ledger


class AcceptanceLedgerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / "src").mkdir()
        (self.root / "src/action.rb").write_text("old")
        (self.root / "evidence.md").write_text("synthetic observations")
        subprocess.run(["git", "add", "."], cwd=self.root, check=True)
        self.case: dict[str, Any] = {"id": "C1", "paths": ["src/*"], "mode": "native", "native_control_required": True}
        self.cases = {"C1": self.case}
        self.result = {
            "schema_version": 1,
            "case_id": "C1",
            "captured_at": "2026-09-30T12:00:00+00:00",
            "source_fingerprint": ledger.source_fingerprint(self.root, self.case["paths"]),
            "dependency_paths": self.case["paths"],
            "evidence_kind": "observed",
            "outcome": "pass",
            "assertions": [{"status": "pass", "observation": "Actual native toggle and state readback agree"}],
            "evidence": ["evidence.md"],
            "control": "combined",
            "host": {
                "sketchup": "26.1.188",
                "ruby": "3.2.2",
                "session_id": "synthetic-session",
                "fixture_id": "synthetic",
                "fixture_sha256": "a" * 64,
                "rbz_sha256": "b" * 64,
                "composition": "normal",
            },
        }
        path = self.root / ledger.RESULTS
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps(self.result) + "\n")

    def test_changes_additions_and_deletions_invalidate_but_unrelated_file_does_not(self) -> None:
        baseline = self.result["source_fingerprint"]
        (self.root / "unrelated.md").write_text("new")
        self.assertEqual(baseline, ledger.source_fingerprint(self.root, self.case["paths"]))
        (self.root / "src/new.rb").write_text("new dependency")
        self.assertNotEqual(baseline, ledger.source_fingerprint(self.root, self.case["paths"]))
        (self.root / "src/new.rb").unlink()
        (self.root / "src/action.rb").unlink()
        self.assertNotEqual(baseline, ledger.source_fingerprint(self.root, self.case["paths"]))

    def test_passing_source_is_not_an_automatic_current_host_pass(self) -> None:
        ledger.validate_result(self.root, self.cases, self.result)
        self.assertEqual("source_unchanged_environment_unchecked", ledger.status(self.root, self.cases, [])[0]["state"])
        (self.root / "src/action.rb").write_text("changed")
        self.assertEqual("needs_recheck", ledger.status(self.root, self.cases, [])[0]["state"])
        with self.assertRaisesRegex(ValueError, "baseline changed"):
            ledger.validate_result(self.root, self.cases, self.result)

    def test_native_control_and_assertion_failures_refuse_a_passing_result(self) -> None:
        self.result["control"] = "bridge"
        with self.assertRaisesRegex(ValueError, "native interaction"):
            ledger.validate_result(self.root, self.cases, self.result)
        self.result["control"] = "human"
        self.result["assertions"][0]["status"] = "unknown"
        with self.assertRaisesRegex(ValueError, "passing result"):
            ledger.validate_result(self.root, self.cases, self.result)

    def test_historical_evidence_is_retained_but_flagged_when_affected(self) -> None:
        self.result["evidence_kind"] = "historical_summary"
        (self.root / ledger.RESULTS).write_text(json.dumps(self.result) + "\n")
        self.assertEqual("historical_evidence", ledger.status(self.root, self.cases, [])[0]["state"])
        self.assertEqual("historical_affected", ledger.status(self.root, self.cases, ["src/action.rb"])[0]["state"])
        with self.assertRaisesRegex(ValueError, "historical"):
            ledger.validate_result(self.root, self.cases, self.result)

    def test_missing_evidence_and_deferred_scope_refuse(self) -> None:
        self.result["evidence"] = ["missing.md"]
        with self.assertRaisesRegex(ValueError, "existing"):
            ledger.validate_result(self.root, self.cases, self.result)
        self.case["deferred"] = True
        with self.assertRaisesRegex(ValueError, "scope decision"):
            ledger.validate_result(self.root, self.cases, self.result)


if __name__ == "__main__":
    unittest.main()
