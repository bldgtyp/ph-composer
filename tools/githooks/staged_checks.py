"""The checks the repository's git hooks run (docs/DEVELOPMENT.md, "Git hooks").

`pre-commit` runs the parts of `make lint`, `make python-check` and the two manifest checks that the
staged files can affect, on those files only, through the same Makefile targets CI runs. Narrowing to
the staged paths matters here: the checkout is shared, and another contributor's unfinished file must
not fail this commit. `commit-msg` refuses a message without a DCO sign-off (docs/DCO.md).

Nothing here fixes or re-stages a file. A failure names the command that fixes it and writes nothing.
The hook starts this file with whatever `python3` is on PATH, which on macOS can be 3.9, so it uses the
standard library only and nothing newer than 3.9 at run time.
"""

from __future__ import annotations

import os
import re
import shlex
import shutil
import subprocess
import sys
from collections.abc import Sequence
from dataclasses import dataclass

# The roots `make lint-python` lints. The type check (ty) reads its own include list, so any staged `.py`,
# added, changed or removed, runs it.
RUFF_ROOTS = ("tools/", "tests/python/", "src/ph_composer/python/")
# The roots `make syntax` covers, and with them rubocop's.
RUBY_ROOTS = ("src/", "tests/", "tools/")
JS_SUFFIXES = (".js", ".cjs", ".mjs")
# `tools/panel_manifest.js` writes the module list and stylesheets into the panel pages, so any change
# under the panel, a module, a stylesheet or a page, can leave them stale.
PANEL_ROOT = "src/ph_composer/html/"
# What the runtime manifest hashes: the panel pages and assets, the translation package, the pinned payload.
RUNTIME_ROOTS = ("src/ph_composer/html/", "src/ph_composer/python/", "src/ph_composer/vendor/")
# `make lint-citations` covers shipped code and tests.
CITATION_ROOTS = ("src/", "tests/")
# A change to a linter's configuration can change its verdict on files nobody staged, so it re-runs that
# linter over the whole tree. The Makefile defines every target, so a change to it re-runs them all.
PYTHON_CONFIG = ("pyproject.toml", "uv.lock", "Makefile")
RUBY_CONFIG = (".rubocop.yml", "Gemfile", "Gemfile.lock", "Makefile")
JS_CONFIG = ("eslint.config.js", "eslint.config.mjs", "package.json", "pnpm-lock.yaml", "Makefile")

SIGNOFF = re.compile(r"^Signed-off-by: .+ <[^<>@\s]+@[^<>\s]+>\s*$", re.MULTILINE)


@dataclass(frozen=True)
class Check:
    """One Makefile target run on the staged files it applies to."""

    name: str
    make_args: tuple[str, ...]
    fix: str


def _under(path: str, roots: Sequence[str]) -> bool:
    return path.startswith(tuple(roots))


def _make_words(paths: Sequence[str]) -> str:
    """Paths as one Make variable value the recipe's shell splits back into exactly these paths."""
    return " ".join(shlex.quote(p).replace("$", "$$") for p in paths)


def _shell_words(paths: Sequence[str]) -> str:
    return " ".join(shlex.quote(p) for p in paths)


def plan(present: Sequence[str], removed: Sequence[str] = ()) -> list[Check]:
    """The checks a commit needs, in the order they run.

    `present` are the staged paths that exist after the commit (added, copied, modified, or the new name
    of a rename); linters read those. `removed` are deleted paths and the old names of renames; they can
    only break whole-set checks, the type check and the two manifests. Paths are repository-relative. A
    commit that touches no code, such as a planning or docs edit, needs none.
    """
    every = [*present, *removed]
    full_python = any(p in PYTHON_CONFIG for p in every)
    full_ruby = any(p in RUBY_CONFIG for p in every)
    full_js = any(p in JS_CONFIG for p in every)
    ruff = [p for p in present if p.endswith(".py") and _under(p, RUFF_ROOTS)]
    ruby = [p for p in present if p.endswith(".rb") and _under(p, RUBY_ROOTS)]
    js = [p for p in present if p.endswith(JS_SUFFIXES)]
    cited = [p for p in present if _under(p, CITATION_ROOTS)]
    checks: list[Check] = []
    if full_python or ruff:
        scope = ["tools", "tests/python", "src/ph_composer/python"] if full_python else ruff
        checks.append(
            Check(
                "ruff",
                ("lint-python", f"RUFF_ARGS=--force-exclude {_make_words(scope)}"),
                f"uv run ruff format {_shell_words(scope)} && uv run ruff check --fix {_shell_words(scope)}, "
                "then edit what it cannot fix",
            )
        )
    if full_python or any(p.endswith(".py") for p in every):
        checks.append(Check("types", ("python-check",), "fix the type errors above; the check reads its whole set"))
    if ruby or full_ruby:
        if ruby:
            checks.append(Check("ruby syntax", ("syntax", f"RB_FILES={_make_words(ruby)}"), "fix the syntax error"))
        rubocop_args = (
            ("lint-ruby",) if full_ruby else ("lint-ruby", f"RUBOCOP_ARGS=--force-exclusion {_make_words(ruby)}")
        )
        checks.append(
            Check(
                "rubocop",
                rubocop_args,
                f"bundle exec rubocop --autocorrect {_shell_words(ruby) or '.'}, then edit what it cannot fix",
            )
        )
    if js or full_js:
        eslint_args = ("lint-js",) if full_js else ("lint-js", f"ESLINT_ARGS=--no-warn-ignored {_make_words(js)}")
        checks.append(
            Check(
                "eslint", eslint_args, f"pnpm exec eslint --fix {_shell_words(js) or '.'}, then edit what it cannot fix"
            )
        )
    if any(p.startswith(PANEL_ROOT) for p in every):
        checks.append(
            Check("panel manifest", ("panel-manifest-check",), "make panel-manifest, then stage the rewritten pages")
        )
    if any(_under(p, RUNTIME_ROOTS) for p in every):
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
                ("lint-citations", "CITATION_FLAGS=--cached", f"CITATION_PATHS={_make_words(cited)}"),
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
    # Source-scanning checks read files as UTF-8; a C or POSIX locale makes them error rather than fail cleanly.
    if env.get("LC_ALL") in ("C", "POSIX"):
        env["LC_ALL"] = "en_US.UTF-8"
    env.setdefault("LANG", "en_US.UTF-8")
    return env


def pre_commit() -> int:
    present = _git("diff", "--cached", "--name-only", "-z", "--no-renames", "--diff-filter=ACM")
    removed = _git("diff", "--cached", "--name-only", "-z", "--no-renames", "--diff-filter=D")
    checks = plan(present, removed)
    if not checks:
        return 0
    missing = [tool for tool in ("make", "uv") if shutil.which(tool) is None]
    if missing:
        print(f"pre-commit: {' and '.join(missing)} not on PATH (docs/DEVELOPMENT.md, Prerequisites).")
        print("  Nothing was committed.")
        return 1
    partial = sorted(set(present) & set(_git("diff", "--name-only", "-z")))
    if partial:
        print("pre-commit: these files also have unstaged changes; their working copy was checked:")
        for path in partial:
            print(f"  {path}")
    failed: list[Check] = []
    env = _environment()
    for check in checks:
        result = subprocess.run(
            ["make", "--no-print-directory", *check.make_args],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            env=env,
        )
        output = result.stdout.strip()
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


def _merging() -> bool:
    """Whether this commit concludes a merge, whose generated message the DCO check leaves alone."""
    return subprocess.run(["git", "rev-parse", "-q", "--verify", "MERGE_HEAD"], capture_output=True).returncode == 0


def commit_msg(message_file: str) -> int:
    with open(message_file, encoding="utf-8") as handle:
        message = handle.read()
    if has_signoff(message) or _merging():
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
