"""Which checks the pre-commit hook plans for a set of staged paths, and the commit-msg sign-off rule."""

from __future__ import annotations

import re
from pathlib import Path

import pytest

import staged_checks
from staged_checks import has_signoff, plan

MAKEFILE = Path(__file__).resolve().parents[2] / "Makefile"


def names(paths: list[str]) -> list[str]:
    return [check.name for check in plan(paths)]


def args(paths: list[str], name: str) -> tuple[str, ...]:
    return next(check.make_args for check in plan(paths) if check.name == name)


def test_a_docs_only_commit_runs_no_check() -> None:
    assert plan(["README.md", "docs/DEVELOPMENT.md", "context/CONTRACTS.md"]) == []


def test_a_tool_script_is_linted_by_name_and_type_checked_whole() -> None:
    paths = ["tools/hostkit/host_bridge.py", "tools/hostkit/tests/test_host_bridge_client.py"]
    assert names(paths) == ["ruff", "mypy"]
    assert args(paths, "ruff") == ("lint-python", "RUFF_ARGS=--force-exclude " + " ".join(paths))
    assert args(paths, "mypy") == ("python-check",)


def test_python_outside_the_ruff_roots_is_still_type_checked() -> None:
    assert names(["scratch.py"]) == ["mypy"]


def test_ruby_gets_syntax_and_rubocop_on_the_staged_files_and_citations_for_src() -> None:
    paths = ["src/ph_composer/extension.rb"]
    assert names(paths) == ["ruby syntax", "rubocop", "citations"]
    assert args(paths, "ruby syntax") == ("syntax", "RB_FILES=src/ph_composer/extension.rb")
    assert args(paths, "rubocop") == ("lint-ruby", "RUBOCOP_ARGS=--force-exclusion src/ph_composer/extension.rb")


def test_a_panel_module_needs_eslint_and_both_manifests() -> None:
    assert names(["src/ph_composer/html/table.js"]) == ["eslint", "panel manifest", "runtime manifest", "citations"]


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
            assert re.search(rf"^{variable} \?=", makefile, re.MULTILINE), variable


@pytest.mark.parametrize(
    ("message", "signed"),
    [
        ("Add a thing\n\nSigned-off-by: PH Tools <ed.p.may@gmail.com>\n", True),
        ("Add a thing\n", False),
        ("Add a thing\n# Signed-off-by: PH Tools <ed.p.may@gmail.com>\n", False),
        ("Add a thing\n\nSigned-off-by: no address\n", False),
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
