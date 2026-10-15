"""Which checks the pre-commit hook plans for a set of staged paths, and the commit-msg sign-off rule."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

import pytest

import staged_checks
from staged_checks import has_signoff, plan

MAKEFILE = Path(__file__).resolve().parents[2] / "Makefile"


def names(paths: list[str], removed: list[str] | None = None) -> list[str]:
    return [check.name for check in plan(paths, removed or [])]


def args(paths: list[str], name: str, removed: list[str] | None = None) -> tuple[str, ...]:
    return next(check.make_args for check in plan(paths, removed or []) if check.name == name)


def test_a_docs_only_commit_runs_no_check() -> None:
    assert plan(["README.md", "docs/DEVELOPMENT.md", "context/CONTRACTS.md"]) == []


def test_a_tool_script_is_linted_by_name_and_type_checked_whole() -> None:
    paths = ["tools/hostkit/host_bridge.py", "tools/hostkit/tests/test_host_bridge_client.py"]
    assert names(paths) == ["ruff", "types"]
    assert args(paths, "ruff") == ("lint-python", "RUFF_ARGS=--force-exclude " + " ".join(paths))
    assert args(paths, "types") == ("python-check",)


def test_python_outside_the_ruff_roots_is_still_type_checked() -> None:
    assert names(["scratch.py"]) == ["types"]


def test_ruby_gets_syntax_and_rubocop_on_the_staged_files_and_citations_for_src() -> None:
    paths = ["src/ph_composer/extension.rb"]
    assert names(paths) == ["ruby syntax", "rubocop", "citations"]
    assert args(paths, "ruby syntax") == ("syntax", "RB_FILES=src/ph_composer/extension.rb")
    assert args(paths, "rubocop") == ("lint-ruby", "RUBOCOP_ARGS=--force-exclusion src/ph_composer/extension.rb")


def test_a_panel_module_needs_eslint_and_both_manifests() -> None:
    assert names(["src/ph_composer/html/table.js"]) == ["eslint", "panel manifest", "runtime manifest", "citations"]


def test_a_panel_stylesheet_or_page_needs_both_manifests() -> None:
    assert names(["src/ph_composer/html/table.css"]) == ["panel manifest", "runtime manifest", "citations"]


def test_a_removed_file_runs_only_the_whole_set_checks() -> None:
    assert names([], removed=["src/ph_composer/html/table.js"]) == ["panel manifest", "runtime manifest"]
    assert names([], removed=["tools/rbz/build.py"]) == ["types"]


def test_a_linter_config_change_lints_the_whole_tree() -> None:
    assert args([".rubocop.yml"], "rubocop") == ("lint-ruby",)
    assert args(["package.json"], "eslint") == ("lint-js",)
    assert names(["pyproject.toml"]) == ["ruff", "types"]
    assert args(["pyproject.toml"], "ruff") == (
        "lint-python",
        "RUFF_ARGS=--force-exclude tools tests/python src/ph_composer/python",
    )


def test_paths_reach_make_quoted_for_the_recipe_shell() -> None:
    value = args(["tools/a b.py", "tools/$c.py"], "ruff")[1]
    assert value == "RUFF_ARGS=--force-exclude 'tools/a b.py' 'tools/$$c.py'"


def test_a_translation_module_needs_the_runtime_manifest() -> None:
    assert "runtime manifest" in names(["src/ph_composer/python/ph_composer_translation/sections.py"])


def test_citations_read_the_index_for_shipped_code_and_tests_only() -> None:
    paths = ["src/ph_composer/extension.rb", "tests/all_tests.rb", "tools/rbz/build.py"]
    assert args(paths, "citations") == (
        "lint-citations",
        "CITATION_FLAGS=--cached",
        "CITATION_PATHS=src/ph_composer/extension.rb tests/all_tests.rb",
    )


def test_every_planned_target_and_variable_exists_in_the_makefile() -> None:
    makefile = MAKEFILE.read_text(encoding="utf-8")
    staged = ["tools/a.py", "src/ph_composer/html/a.js", "src/b.rb"]
    for check in plan(staged):
        target, *assignments = check.make_args
        assert re.search(rf"^{re.escape(target)}:", makefile, re.MULTILINE), target
        for assignment in assignments:
            variable = assignment.split("=", 1)[0]
            assert re.search(rf"^{variable} =", makefile, re.MULTILINE), variable


@pytest.mark.parametrize(
    ("message", "signed"),
    [
        ("Add a thing\n\nSigned-off-by: PH Tools <ed.p.may@gmail.com>\n", True),
        ("Add a thing\n", False),
        ("Add a thing\n# Signed-off-by: PH Tools <ed.p.may@gmail.com>\n", False),
        ("Add a thing\n\nSigned-off-by: no address\n", False),
        ("Add a thing\r\n\r\nSigned-off-by: PH Tools <ed.p.may@gmail.com>\r\n", True),
    ],
)
def test_the_sign_off_trailer(message: str, signed: bool) -> None:
    assert has_signoff(message) is signed


def test_commit_msg_refuses_an_unsigned_message(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    message = tmp_path / "COMMIT_EDITMSG"
    message.write_text("Add a thing\n", encoding="utf-8")
    assert staged_checks.main(["commit-msg", str(message)]) == 1
    assert "git commit -s" in capsys.readouterr().out
    message.write_text("Add a thing\n\nSigned-off-by: PH Tools <ed.p.may@gmail.com>\n", encoding="utf-8")
    assert staged_checks.main(["commit-msg", str(message)]) == 0


def test_commit_msg_lets_a_merge_conclude_unsigned(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    message = tmp_path / "MERGE_MSG"
    message.write_text("Merge branch 'topic'\n", encoding="utf-8")
    monkeypatch.setattr(staged_checks, "_merging", lambda: True)
    assert staged_checks.main(["commit-msg", str(message)]) == 0


def test_pre_commit_runs_nothing_for_a_docs_only_commit(monkeypatch: pytest.MonkeyPatch) -> None:
    staged = {"--diff-filter=ACM": ["docs/DEVELOPMENT.md"], "--diff-filter=D": []}
    monkeypatch.setattr(staged_checks, "_git", lambda *a: staged.get(a[-1], []))

    def refuse(*_args: object, **_kwargs: object) -> None:
        raise AssertionError("no check may run")

    monkeypatch.setattr(staged_checks.subprocess, "run", refuse)
    assert staged_checks.pre_commit() == 0


def test_pre_commit_reports_each_failure_and_its_fix(
    monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    staged = {"--diff-filter=ACM": ["tools/a.py"], "--diff-filter=D": []}
    monkeypatch.setattr(staged_checks, "_git", lambda *a: staged.get(a[-1], []))
    monkeypatch.setattr(staged_checks.shutil, "which", lambda tool: f"/usr/bin/{tool}")
    calls: list[list[str]] = []

    def run(command: list[str], **_kwargs: object) -> subprocess.CompletedProcess[str]:
        calls.append(command)
        failing = command[2] == "lint-python"
        return subprocess.CompletedProcess(command, 1 if failing else 0, stdout="E501 Line too long" if failing else "")

    monkeypatch.setattr(staged_checks.subprocess, "run", run)
    assert staged_checks.pre_commit() == 1
    out = capsys.readouterr().out
    assert [c[2] for c in calls] == ["lint-python", "python-check"]
    assert "ruff failed" in out and "E501 Line too long" in out and "uv run ruff format tools/a.py" in out
    assert "Nothing was committed." in out
