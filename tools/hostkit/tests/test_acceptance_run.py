"""Regression checks for immutable provenance and conservative assertion reuse."""

from __future__ import annotations

import copy
import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any
from zipfile import ZipFile

import acceptance_run as run


class AcceptanceRunTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / "a.rb").write_text("a")
        (self.root / "b.rb").write_text("b")
        self.host = dict.fromkeys(run.HOST_KEYS, "observed")
        self.host.update(fixture_sha256="a" * 64, rbz_sha256="b" * 64, composition="normal")
        self.recipe: dict[str, Any] = {
            "host": self.host,
            "active_tool": "Classify",
            "edit_path": [],
            "preflight": {
                key: {"ready": True, "observation": "Synthetic test observation"} for key in run.PREFLIGHT_KEYS
            },
            "assertions": [
                {"id": "A/down", "paths": ["a.rb"], "environment_keys": ["controller"]},
                {"id": "A/up", "paths": ["b.rb"], "environment_keys": ["rbz_sha256"]},
            ],
        }

    def test_baselines_cannot_be_overwritten_and_run_ids_are_unique(self) -> None:
        baseline = run.capture(self.root, self.recipe)
        path = self.root / "run.json"
        run.write_once(path, baseline)
        original = path.read_bytes()
        with self.assertRaises(FileExistsError):
            run.write_once(path, run.capture(self.root, self.recipe))
        self.assertEqual(original, path.read_bytes())
        self.assertNotEqual(baseline["run_id"], run.capture(self.root, self.recipe)["run_id"])

    def test_failed_or_unobserved_preflight_refuses_capture(self) -> None:
        for value in (False, "true"):
            self.recipe["preflight"]["writer_verified"]["ready"] = value
            with self.assertRaisesRegex(ValueError, "writer_verified"):
                run.capture(self.root, self.recipe)
        self.recipe["preflight"]["writer_verified"] = {"ready": True, "observation": " "}
        with self.assertRaises(ValueError):
            run.capture(self.root, self.recipe)

    def test_assertions_invalidate_independently_without_awarding_pass(self) -> None:
        baseline = run.capture(self.root, self.recipe)
        (self.root / "a.rb").write_text("changed")
        rows = run.screen(self.root, baseline, self.host)
        self.assertEqual(["needs_recheck", "dependencies_unchanged"], [row["state"] for row in rows])
        self.assertTrue(all(row["acceptance"] == "not_evaluated" for row in rows))
        host = copy.copy(self.host)
        del host["rbz_sha256"]
        self.assertEqual("needs_recheck", run.screen(self.root, baseline, host)[1]["state"])

    def test_unsafe_dependencies_duplicate_ids_and_bad_hashes_refuse(self) -> None:
        for field, value in (("paths", ["../secret"]), ("environment_keys", ["unknown"]), ("id", "A/up")):
            recipe = copy.deepcopy(self.recipe)
            recipe["assertions"][0][field] = value
            with self.assertRaises(ValueError):
                run.capture(self.root, recipe)
        self.host["rbz_sha256"] = "not a hash"
        with self.assertRaises(ValueError):
            run.capture(self.root, self.recipe)

    def test_unmatched_dependency_pattern_refuses_capture(self) -> None:
        self.recipe["assertions"][0]["paths"] = ["typo/*.rb"]
        with self.assertRaisesRegex(ValueError, "matched no source"):
            run.capture(self.root, self.recipe)

    def test_observations_preserve_unknown_and_hash_actual_evidence(self) -> None:
        baseline = run.capture(self.root, self.recipe)
        evidence = self.root / "trace.json"
        evidence.write_text("actual readback")
        observations = {
            "assertions": [
                {"id": key, "status": "unknown", "observation": "Release not observed", "evidence": str(evidence)}
                for key in ("A/down", "A/up")
            ]
        }
        receipt = run.observe(baseline, observations)
        self.assertEqual(baseline["run_id"], receipt["run_id"])
        self.assertTrue(all(row["status"] == "unknown" for row in receipt["assertions"]))
        self.assertEqual(64, len(receipt["assertions"][0]["evidence_sha256"]))
        observations["assertions"].pop()
        with self.assertRaises(ValueError):
            run.observe(baseline, observations)

    def test_package_mismatch_and_extra_files_are_reported(self) -> None:
        rbz = self.root / "test.rbz"
        with ZipFile(rbz, "w") as archive:
            archive.writestr("ph_composer.rb", "loader")
            archive.writestr("ph_composer/a.rb", "source")
        plugins = self.root / "plugins"
        (plugins / "ph_composer").mkdir(parents=True)
        (plugins / "ph_composer.rb").write_text("loader")
        (plugins / "ph_composer/a.rb").write_text("source")
        self.assertTrue(run.installed_package(rbz, plugins)["matches"])
        (plugins / "ph_composer/a.rb").write_text("stale")
        (plugins / "ph_composer/extra.rb").write_text("extra")
        receipt = run.installed_package(rbz, plugins)
        self.assertFalse(receipt["matches"])
        self.assertEqual(["ph_composer/a.rb"], receipt["mismatches"])
        self.assertEqual(["ph_composer/extra.rb"], receipt["extras"])

    def test_empty_and_unsafe_archives_are_refused(self) -> None:
        for names in ([], ["../private"], ["ph_composer.rb", "ph_composer/../private"]):
            rbz = self.root / "invalid.rbz"
            with ZipFile(rbz, "w") as archive:
                for name in names:
                    archive.writestr(name, "bytes")
            with self.assertRaises(ValueError):
                run.installed_package(rbz, self.root)

    def test_links_follow_archive_symlink_and_report_missing_targets(self) -> None:
        (self.root / "archive").mkdir()
        (self.root / "archive/evidence.md").write_text("retained")
        (self.root / "evidence").symlink_to("archive", target_is_directory=True)
        doc = self.root / "README.md"
        doc.write_text("[proof](evidence/evidence.md#anchor) [remote](https://example.com) [lost](missing.md)")
        self.assertEqual(["README.md: missing.md"], run.check_links(self.root, [doc]))


if __name__ == "__main__":
    unittest.main()
