"""The checks the repository's git hooks run (docs/DEVELOPMENT.md, "Git hooks").

`pre-commit` runs the parts of `make lint`, `make python-check` and the two manifest checks that the
staged files can affect, on those files only, through the same Makefile targets CI runs. Narrowing to
the staged paths matters here: the checkout is shared, and another contributor's unfinished file must
not fail this commit. `commit-msg` refuses a message without a DCO sign-off (docs/DCO.md).

Nothing here fixes or re-stages a file. A failure names the command that fixes it and writes nothing.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from collections.abc import Sequence
from dataclasses import dataclass

# The roots `make lint-python` lints. A staged `.py` elsewhere is still type-checked through mypy's own
# file list, which is why mypy runs on any staged `.py`.
RUFF_ROOTS = ("tools/", "tests/python/", "src/ph_composer/python/")
# The roots `make syntax` covers, and with them rubocop's.
RUBY_ROOTS = ("src/", "tests/", "tools/")
JS_SUFFIXES = (".js", ".cjs", ".mjs")
PANEL_ROOT = "src/ph_composer/html/"
# What the runtime manifest hashes: the panel pages and assets, the translation package, the pinned payload.
RUNTIME_ROOTS = ("src/ph_composer/html/", "src/ph_composer/python/", "src/ph_composer/vendor/")
# `make lint-citations` covers shipped code and tests.
CITATION_ROOTS = ("src/", "tests/")

SIGNOFF = re.compile(r"^Signed-off-by: .+ <[^<>@\s]+@[^<>\s]+>\s*$", re.MULTILINE)


@dataclass(frozen=True)
class Check:
    """One Makefile target run on the staged files it applies to."""

    name: str
    make_args: tuple[str, ...]
    fix: str


def _under(path: str, roots: Sequence[str]) -> bool:
    return path.startswith(tuple(roots))


def plan(paths: Sequence[str]) -> list[Check]:
    """The checks a commit of `paths` (repository-relative) needs, in the order they run.

    A commit that touches no code, such as a planning or docs edit, needs none.
    """
    python = [p for p in paths if p.endswith(".py")]
    ruff = [p for p in python if _under(p, RUFF_ROOTS)]
    ruby = [p for p in paths if p.endswith(".rb") and _under(p, RUBY_ROOTS)]
    js = [p for p in paths if p.endswith(JS_SUFFIXES)]
    cited = [p for p in paths if _under(p, CITATION_ROOTS)]
    checks: list[Check] = []
    if ruff:
        files = " ".join(ruff)
        checks.append(
            Check(
                "ruff",
                ("lint-python", f"RUFF_ARGS=--force-exclude {files}"),
                f"uv run ruff format {files} && uv run ruff check --fix {files}, then edit what it cannot fix",
            )
        )
    if python:
        checks.append(
            Check("mypy", ("python-check",), "fix the type errors above; mypy runs on the whole configured set")
        )
    if ruby:
        files = " ".join(ruby)
        checks.append(Check("ruby syntax", ("syntax", f"RB_FILES={files}"), "fix the syntax error above"))
        checks.append(
            Check(
                "rubocop",
                ("lint-ruby", f"RUBOCOP_ARGS=--force-exclusion {files}"),
                f"bundle exec rubocop --autocorrect {files}, then edit what it cannot fix",
            )
        )
    if js:
        files = " ".join(js)
        checks.append(
            Check(
                "eslint",
                ("lint-js", f"ESLINT_ARGS=--no-warn-ignored {files}"),
                f"pnpm exec eslint --fix {files}, then edit what it cannot fix",
            )
        )
    if any(p.endswith(JS_SUFFIXES) and p.startswith(PANEL_ROOT) for p in paths):
        checks.append(
            Check(
                "panel manifest",
                ("panel-manifest-check",),
                "make panel-manifest, then stage the rewritten panel pages",
            )
        )
    if any(_under(p, RUNTIME_ROOTS) for p in paths):
        checks.append(
            Check(
                "runtime manifest",
                ("runtime-check",),
                "make panel-manifest runtime-manifest, then stage src/ph_composer/vendor/manifest.json",
            )
        )
    if cited:
        checks.append(
            Check(
                "citations",
                ("lint-citations", "CITATION_FLAGS=--cached", f"CITATION_PATHS={' '.join(cited)}"),
                "cite context/ instead of a planning document or id (context/CODING_STANDARDS.md)",
            )
        )
    return checks


def has_signoff(message: str) -> bool:
    """Whether a commit message carries a DCO `Signed-off-by` trailer, ignoring git's comment lines."""
    text = "\n".join(line for line in message.splitlines() if not line.startswith("#"))
    return bool(SIGNOFF.search(text))


def _git(*args: str) -> list[str]:
    out = subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout
    return [p for p in out.split("\0") if p]


def _environment() -> dict[str, str]:
    env = dict(os.environ)
    # Source-scanning checks read files as UTF-8; a C locale makes them error rather than fail cleanly.
    env.setdefault("LANG", "en_US.UTF-8")
    return env


def pre_commit() -> int:
    staged = _git("diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR")
    checks = plan(staged)
    if not checks:
        return 0
    partial = sorted(set(staged) & set(_git("diff", "--name-only", "-z")))
    if partial:
        print("pre-commit: these files also have unstaged changes; their working copy was checked:")
        for path in partial:
            print(f"  {path}")
    failed: list[Check] = []
    env = _environment()
    for check in checks:
        result = subprocess.run(
            ["make", "--no-print-directory", *check.make_args],
            capture_output=True,
            text=True,
            env=env,
        )
        output = (result.stdout + result.stderr).strip()
        if result.returncode != 0:
            failed.append(check)
            print(f"pre-commit: {check.name} failed")
            if output:
                print(output)
            print(f"  fix: {check.fix}")
        elif "skipped" in output:
            # A missing developer tool skips by name, as `make lint` does; CI still runs it.
            print(f"pre-commit: {output}")
    if failed:
        print(f"pre-commit: {len(failed)} check(s) failed. Nothing was committed.")
        print("  Fix them and commit again. Do not bypass the hook with --no-verify.")
        return 1
    return 0


def commit_msg(message_file: str) -> int:
    with open(message_file, encoding="utf-8") as handle:
        message = handle.read()
    if has_signoff(message):
        return 0
    print("commit-msg: the message has no 'Signed-off-by: Name <email>' line (docs/DCO.md).")
    print("  Commit with 'git commit -s', or add it with 'git commit --amend -s --no-edit'. Nothing was committed.")
    return 1


def main(argv: Sequence[str]) -> int:
    if len(argv) >= 1 and argv[0] == "pre-commit":
        return pre_commit()
    if len(argv) >= 2 and argv[0] == "commit-msg":
        return commit_msg(argv[1])
    print("usage: staged_checks.py pre-commit | commit-msg <message-file>", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
