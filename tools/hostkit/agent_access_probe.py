# /// script
# requires-python = ">=3.11"
# ///
"""Run Claude Code and Codex headless against the live PH-Composer agent listener and keep the transcript.

Development only, never shipped. Each client must already be configured from the snippets the Agent
Access dialog shows (`claude mcp add ... ph-composer ...`, `codex mcp add ph-composer ...`); this script
does not configure them. The token travels only in the environment variable the Codex form names and
is read from a file the caller points at, so it never appears on a command line, in the transcript or
in the repository.

    uv run tools/hostkit/agent_access_probe.py --token-file ~/.ph-composer-token \\
      --out _private/host/agent-access/probe-<date>

The prompt asks each client to list the open Models through `discover` and run one `query`. The
transcript records the client versions, the exact command (token masked) and each client's answer.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from datetime import UTC, datetime
from pathlib import Path

PROMPT = (
    "Use only the ph-composer MCP tools; run no shell commands and read no files. Call discover, then "
    "list the open Models by file name. For the first open Model, run one query that lists its Zones and "
    "give each Zone's name. Name every tool and operation you used. Be brief."
)
TOKEN_VARIABLE = "PH_COMPOSER_TOKEN"


def version(command: list[str]) -> str:
    return subprocess.run(command, capture_output=True, text=True, check=False).stdout.strip()


def run(name: str, command: list[str], env: dict[str, str], token: str, timeout: int) -> dict[str, object]:
    started = datetime.now(UTC)
    result = subprocess.run(
        command, capture_output=True, text=True, env=env, stdin=subprocess.DEVNULL, timeout=timeout, check=False
    )
    return {
        "client": name,
        "command": [part.replace(token, "<token>") for part in command],
        "started": started.isoformat(timespec="seconds"),
        "seconds": round((datetime.now(UTC) - started).total_seconds(), 1),
        "exit": result.returncode,
        "stdout": result.stdout.replace(token, "<token>"),
        "stderr": result.stderr.replace(token, "<token>")[-4000:],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--token-file", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--codex-model", default="gpt-6.1-sol")
    args = parser.parse_args()

    token = args.token_file.expanduser().read_text().strip()
    env = dict(os.environ, **{TOKEN_VARIABLE: token})
    args.out.mkdir(parents=True, exist_ok=True)
    runs = [
        run("Claude Code", ["claude", "-p", PROMPT, "--allowedTools", "mcp__ph-composer"], env, token, args.timeout),
        run(
            "Codex",
            [
                "codex",
                "exec",
                "--skip-git-repo-check",
                "-m",
                args.codex_model,
                "-c",
                'model_reasoning_effort="low"',
                PROMPT,
            ],
            env,
            token,
            args.timeout,
        ),
    ]
    transcript = {
        "claude_version": version(["claude", "--version"]),
        "codex_version": version(["codex", "--version"]),
        "prompt": PROMPT,
        "runs": runs,
    }
    (args.out / "transcript.json").write_text(json.dumps(transcript, indent=2) + "\n")
    for entry in runs:
        print(f"{entry['client']}: exit {entry['exit']} in {entry['seconds']} s")


if __name__ == "__main__":
    main()
