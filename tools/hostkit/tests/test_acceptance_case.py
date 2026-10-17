"""The case tool's own decisions, without SketchUp: what it records at `begin` and what it appends at `finish`."""

from __future__ import annotations

import argparse
import json
import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

import acceptance_case as case_tool
import acceptance_ledger as ledger

CASE = {"id": "A09", "paths": ["src/a.rb"]}
IDENTITY = {
    "sketchup": "26.1.188",
    "ruby": "3.2.2",
    "os": "macOS 26.6.2",
    "session_id": "s-1",
    "rbz_sha256": "b" * 64,
    "tool": "SelectionTool",
    "path": [],
}


def arguments(**overrides: object) -> argparse.Namespace:
    values = {
        "asserts": ["narrow", "held"],
        "controller": "bridge plus computer-use",
        "composition": "normal",
        "window": "the only document",
        "target": "two Zones",
        "probe": "no callbacks",
    }
    values.update(overrides)
    return argparse.Namespace(**values)


class AcceptanceCaseTest(unittest.TestCase):
    def test_the_recipe_carries_the_live_identity_and_one_assertion_per_slug(self) -> None:
        recipe = case_tool.build_recipe(CASE, IDENTITY, arguments(), "a" * 64, "writer check t")
        self.assertEqual([row["id"] for row in recipe["assertions"]], ["A09/narrow", "A09/held"])
        self.assertEqual(recipe["host"]["rbz_sha256"], "b" * 64)
        self.assertEqual(recipe["host"]["fixture_sha256"], "a" * 64)
        self.assertEqual(recipe["edit_path"], [])
        self.assertIn("SelectionTool", recipe["preflight"]["tool_ready"]["observation"])

    def test_the_result_takes_the_worst_observed_status(self) -> None:
        baseline = {"host": {**IDENTITY, "controller": "c", "fixture_sha256": "a" * 64, "composition": "normal"}}
        rows = [
            {"status": "pass", "observation": "fine"},
            {"status": "fail", "observation": "the bar covers the header"},
            {"status": "unknown", "observation": "not reached"},
        ]
        result = case_tool.build_result(
            {"case_id": "A09"}, baseline, {"control": "native", "fixture_id": "copy"}, rows, "planning/e.md"
        )
        self.assertEqual(result["outcome"], "fail")
        self.assertEqual(result["host"]["fixture_id"], "copy")
        self.assertEqual(result["evidence"], ["planning/e.md"])

    def test_steps_are_started_once_and_a_rerun_keeps_what_was_written(self) -> None:
        with TemporaryDirectory() as folder:
            steps = case_tool.start_steps(Path(folder), "A09", Path("a09.skp"), "a" * 64)
            self.assertIn("A09: how this case was driven", steps.read_text())
            steps.write_text("written during the run")
            case_tool.start_steps(Path(folder), "A09", Path("a09.skp"), "a" * 64)
            self.assertEqual(steps.read_text(), "written during the run")

    def test_an_installed_extension_that_differs_from_the_build_stops_begin(self) -> None:
        with (
            patch.object(case_tool, "installed_package", return_value={"matches": False, "mismatches": ["x"]}),
            patch.object(case_tool, "evaluate") as evaluate,
            self.assertRaises(ValueError),
        ):
            case_tool.live_identity("2026", Path("dist/ph_composer.rbz"), Path("Plugins"), Path("a09.skp"))
        evaluate.assert_not_called()

    def test_the_open_document_must_be_the_unmodified_fixture(self) -> None:
        live = ["s-1", "SelectionTool", [], "26.1.188", "3.2.2"]
        package = {"matches": True, "rbz_sha256": "b" * 64}
        for document, modified, refusal in (
            ("/elsewhere/other.skp", False, "not the fixture"),
            ("/run/a09.skp", True, "already modified"),
        ):
            with (
                patch.object(case_tool, "installed_package", return_value=package),
                patch.object(case_tool, "evaluate", return_value=[*live, document, modified]),
                self.assertRaisesRegex(ValueError, refusal),
            ):
                case_tool.live_identity("2026", Path("r.rbz"), Path("P"), Path("/run/a09.skp"))

    def test_a_refused_begin_leaves_no_file_that_would_block_the_retry(self) -> None:
        with TemporaryDirectory() as folder:
            run = Path(folder)
            fixture = run / "a09.skp"
            fixture.write_text("model")
            args = arguments(
                root=Path(folder),
                case="A09",
                run_dir=run,
                fixture=fixture,
                fixture_id="copy",
                control="native",
                rbz=None,
                plugins=None,
                sketchup_version="2026",
            )
            with (
                patch.object(case_tool, "read_catalog", return_value={"A09": CASE}),
                patch.object(case_tool, "live_identity", side_effect=ValueError("installed extension differs")),
                self.assertRaises(ValueError),
            ):
                case_tool.begin(args)
            self.assertFalse((run / "A09").exists())
            (run / "A09").mkdir()
            (run / "A09" / "meta.json").write_text("{}")
            with (
                patch.object(case_tool, "read_catalog", return_value={"A09": CASE}),
                self.assertRaisesRegex(ValueError, "move the earlier run aside"),
            ):
                case_tool.begin(args)
            with (
                patch.object(
                    case_tool, "read_catalog", return_value={"A09": {**CASE, "native_control_required": True}}
                ),
                self.assertRaisesRegex(ValueError, "requires native interaction"),
            ):
                case_tool.begin(arguments(**{**vars(args), "control": "bridge"}))

    def test_a_built_result_passes_the_ledgers_own_validation(self) -> None:
        with TemporaryDirectory() as folder:
            root = Path(folder)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            (root / "src").mkdir()
            (root / "src/a.rb").write_text("code")
            (root / "evidence.md").write_text("observations")
            subprocess.run(["git", "add", "."], cwd=root, check=True)
            paths = ["src/a.rb"]
            case = {"id": "A09", "paths": paths, "mode": "native", "native_control_required": True}
            row = {
                "schema_version": 1,
                "case_id": "A09",
                "captured_at": "2026-10-17T12:00:00+00:00",
                "commit": "0" * 40,
                "source_fingerprint": ledger.source_fingerprint(root, paths),
                "dependency_paths": paths,
            }
            baseline = {"host": {**IDENTITY, "controller": "c", "fixture_sha256": "a" * 64, "composition": "normal"}}
            result = case_tool.build_result(
                row,
                baseline,
                {"control": "native", "fixture_id": "copy"},
                [{"status": "pass", "observation": "seen"}],
                "evidence.md",
            )
            ledger.validate_result(root, {"A09": case}, json.loads(json.dumps(result)))


if __name__ == "__main__":
    unittest.main()
