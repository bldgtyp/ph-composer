"""The agent access probe keeps its transcript when a client hangs, without running a paid client."""

from __future__ import annotations

import json
import os
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

import agent_access_probe as probe

TOKEN = "0123456789abcdef" * 3


class AgentAccessProbeTest(unittest.TestCase):
    def test_a_timeout_is_recorded_with_partial_output_and_the_token_masked(self) -> None:
        command = [sys.executable, "-c", f"import time; print('started {TOKEN}', flush=True); time.sleep(5)"]

        entry = probe.run("Slow client", command, dict(os.environ), TOKEN, timeout=1)

        self.assertEqual("timeout", entry["exit"])
        self.assertIn("started <token>", str(entry["stdout"]))
        self.assertNotIn(TOKEN, json.dumps(entry))

    def test_each_run_is_written_before_the_next_starts(self) -> None:
        with TemporaryDirectory() as folder, patch.object(probe, "version", return_value="x"):
            out = Path(folder)
            probe.write(out, [{"client": "Claude Code", "exit": 0}])

            written = json.loads((out / "transcript.json").read_text())

        self.assertEqual(["Claude Code"], [entry["client"] for entry in written["runs"]])


if __name__ == "__main__":
    unittest.main()
