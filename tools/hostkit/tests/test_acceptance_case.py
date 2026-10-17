"""The case tool's own decisions, without SketchUp: what it records at `begin` and what it appends at `finish`."""

from __future__ import annotations

import argparse
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

import acceptance_case as case_tool

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
            case_tool.live_identity("2026", Path("dist/ph_composer.rbz"), Path("Plugins"))
        evaluate.assert_not_called()


if __name__ == "__main__":
    unittest.main()
