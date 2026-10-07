"""Exercise evidence integrity and invalidation without running or mutating SketchUp."""

from __future__ import annotations

import json
import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any
from unittest.mock import patch

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

    def test_snapshot_cli_refuses_to_replace_an_existing_baseline(self) -> None:
        output = self.root / "baseline.json"
        output.write_text("original baseline")
        argv = ["acceptance_ledger", "--root", str(self.root), "snapshot", "C1", "--output", str(output)]
        with (
            patch("sys.argv", argv),
            patch.object(ledger, "read_catalog", return_value=self.cases),
            self.assertRaises(FileExistsError),
        ):
            ledger.main()
        self.assertEqual("original baseline", output.read_text())

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

    def test_archived_evidence_resolves_without_rewriting_observed_or_historical_results(self) -> None:
        archived = self.root / "archive/evidence.md"
        archived.parent.mkdir()
        (self.root / "evidence.md").rename(archived)
        (self.root / ledger.EVIDENCE_LOCATIONS).write_text(json.dumps({"evidence.md": "archive/evidence.md"}))
        for kind in ("observed", "historical_summary"):
            with self.subTest(kind=kind):
                self.result["evidence_kind"] = kind
                original = json.dumps(self.result) + "\n"
                (self.root / ledger.RESULTS).write_text(original)
                self.assertEqual(["archive/evidence.md"], ledger.read_results(self.root, self.cases)[0]["evidence"])
                self.assertEqual(["archive/evidence.md"], ledger.status(self.root, self.cases, [])[0]["evidence"])
                self.assertEqual(original, (self.root / ledger.RESULTS).read_text())
        self.result["evidence_kind"] = "observed"
        with self.assertRaisesRegex(ValueError, "existing"):
            ledger.validate_result(self.root, self.cases, self.result)

    def test_unsafe_or_missing_archive_locations_refuse(self) -> None:
        invalid_locations: list[Any] = [
            [],
            {"../evidence.md": "evidence.md"},
            {"evidence.md": "/outside.md"},
            {"evidence.md": "../outside.md"},
            {"evidence.md": None},
            {"evidence.md": "missing.md"},
        ]
        for locations in invalid_locations:
            with self.subTest(locations=locations):
                (self.root / ledger.EVIDENCE_LOCATIONS).write_text(json.dumps(locations))
                with self.assertRaises(ValueError):
                    ledger.read_results(self.root, self.cases)


if __name__ == "__main__":
    unittest.main()
