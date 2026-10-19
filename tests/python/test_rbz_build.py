"""The archive gate decides what reaches a user's Plugins folder, so each refusal is shown refusing.

These exercise the pure half, `shipping_problems`, over in-memory entries. `make rbz` and
`make rbz-check` run the filesystem half against the real tree on every `make ci`.
"""

from __future__ import annotations

import json
import zipfile
from pathlib import Path

import pytest

import build

LOADER = {"ph_composer.rb": b"# loader\n"}
NO_ALLOWLIST: list[build.AllowedLine] = []


def problems(extra: dict[str, bytes], allowed: list[build.AllowedLine] = NO_ALLOWLIST) -> list[str]:
    return build.shipping_problems({**LOADER, **extra}, allowed)


def test_the_loader_and_extension_files_ship() -> None:
    assert problems({"ph_composer/extension.rb": b"module PhComposer; end\n"}) == []


def test_the_archive_root_holds_only_the_loader() -> None:
    assert problems({"README.md": b"notes\n"}) == [
        "archive root must hold only ph_composer.rb; found ['README.md', 'ph_composer.rb']"
    ]
    assert build.shipping_problems({"ph_composer/extension.rb": b""}, NO_ALLOWLIST)[0].startswith("archive root")


def test_a_file_outside_the_extension_folder_is_refused() -> None:
    assert problems({"other/tool.rb": b""}) == ["other/tool.rb: outside the extension folder"]


def test_development_material_is_refused_wherever_it_sits() -> None:
    assert problems({"ph_composer/tools/hostkit/host_bridge.rb": b""}) == [
        "ph_composer/tools/hostkit/host_bridge.rb: development material (hostkit)"
    ]
    assert problems({"ph_composer/examples/foundation/example.rb": b""}) == [
        "ph_composer/examples/foundation/example.rb: development material (examples)"
    ]


def test_a_file_type_the_extension_does_not_ship_is_refused() -> None:
    assert problems({"ph_composer/model.skp": b""}) == ["ph_composer/model.skp: file type .skp does not ship"]


def test_starter_library_is_refused_even_when_copied_under_extension() -> None:
    assert problems({"ph_composer/starter-library/materials.json": b"{}"}) == [
        "ph_composer/starter-library/materials.json: development material (starter-library)"
    ]
    assert any(
        "development material (starter-library)" in problem
        for problem in problems({"starter-library/materials.json": b"{}"})
    )


def test_designph_and_the_predecessor_namespace_are_refused_in_any_case() -> None:
    found = problems(
        {
            "ph_composer/core/a.rb": b"DesignPH.Version\n",
            "ph_composer/html/b.js": b'Phn.define("x", [], f);\n',
            "ph_composer/shell/c.rb": b'callback = "phn_message"\n',
            "ph_composer/shell/d.rb": b"# PH-Navigator for SketchUp\n",
            "ph_composer/shell/e.rb": b"Phn::Panel.show\n",
            "ph_composer/html/f.css": b".phn-icon-button { color: red; }\n",
        }
    )
    assert found == [
        "denied name ph_composer/core/a.rb:1: DesignPH.Version",
        'denied name ph_composer/html/b.js:1: Phn.define("x", [], f);',
        "denied name ph_composer/html/f.css:1: .phn-icon-button { color: red; }",
        'denied name ph_composer/shell/c.rb:1: callback = "phn_message"',
        "denied name ph_composer/shell/d.rb:1: # PH-Navigator for SketchUp",
        "denied name ph_composer/shell/e.rb:1: Phn::Panel.show",
    ]


def test_ordinary_words_that_resemble_a_denied_name_ship() -> None:
    assert problems({"ph_composer/core/a.rb": b"# The design phase comes first; graph_nodes stay.\n"}) == []


def test_an_allowlisted_citation_ships_only_on_its_exact_line() -> None:
    citation = "* Ported from ph-navigator-v2 revision c55b519b:"
    allowed = [build.AllowedLine("ph_composer/html/units.js", citation, "source citation")]
    text = f"/*\n {citation}\n */\nPhn.define('units', [], f);\n".encode()

    assert problems({"ph_composer/html/units.js": text}, allowed) == [
        "denied name ph_composer/html/units.js:4: Phn.define('units', [], f);"
    ]


def test_an_allowlist_entry_that_matches_nothing_is_stale() -> None:
    allowed = [build.AllowedLine("ph_composer/html/units.js", "gone", "source citation")]

    assert problems({"ph_composer/html/units.js": b"x\n"}, allowed) == [
        "stale allowlist entry ph_composer/html/units.js: 'gone'"
    ]


def test_a_blocking_browser_api_in_a_panel_file_is_refused() -> None:
    assert problems({"ph_composer/html/panel.js": b"window.alert('x'); confirm(1)\n"}) == [
        "ph_composer/html/panel.js: blocking browser API ['alert(', 'confirm(']"
    ]


def test_a_blocking_api_scan_skips_vendored_code_and_lookalike_names() -> None:
    assert build.blocking_api_tokens("ph_composer/vendor/pyodide/pyodide.js", "alert(") == []
    assert build.blocking_api_tokens("ph_composer/shell/panel.rb", "alert(") == []
    assert build.blocking_api_tokens("ph_composer/html/panel.js", "showAlert(1); myprompt(2)") == []


def test_install_replaces_only_this_extension_and_leaves_other_plugins(tmp_path: Path) -> None:
    plugins = tmp_path / "Plugins"
    (plugins / "ph_composer").mkdir(parents=True)
    (plugins / "ph_composer" / "removed_since.rb").write_text("stale")
    (plugins / "other_extension.rb").write_text("theirs")
    archive = tmp_path / "ph_composer.rbz"
    with zipfile.ZipFile(archive, "w") as bundle:
        bundle.writestr("ph_composer.rb", "# loader")
        bundle.writestr("ph_composer/extension.rb", "# root")

    build.install_into(plugins, archive)

    assert (plugins / "ph_composer.rb").read_text() == "# loader"
    assert (plugins / "ph_composer" / "extension.rb").read_text() == "# root"
    assert not (plugins / "ph_composer" / "removed_since.rb").exists()
    assert (plugins / "other_extension.rb").read_text() == "theirs"


def test_the_plugins_directory_needs_a_four_digit_sketchup_year() -> None:
    assert build.plugins_directory("2026").parts[-4:] == ("Application Support", "SketchUp 2026", "SketchUp", "Plugins")
    for version in ("26", "2026.1", "../..", "abcd"):
        with pytest.raises(SystemExit):
            build.plugins_directory(version)


def _budget(ceiling: int, baseline: int, growth: int) -> dict[str, bytes]:
    gates = {"installed_ceiling_bytes": ceiling, "installed_baseline_bytes": baseline, "installed_growth_bytes": growth}
    return {**LOADER, build.RUNTIME_MANIFEST: json.dumps({"gates": gates}).encode()}


def test_the_installed_extension_must_fit_the_runtime_budget() -> None:
    fits = _budget(1_000, 0, 10_000)
    size = sum(len(content) for content in fits.values())
    assert build.footprint_problems(fits) == []
    over = {**fits, "ph_composer/vendor/pyodide/pyodide.asm.wasm": b"x" * (1_001 - size)}
    assert build.footprint_problems(over) == ["installed size 1001 bytes exceeds the 1000-byte ceiling"]
    assert build.footprint_problems(LOADER)[0].endswith("the installed-size budget cannot be checked")


def test_growth_past_the_phase_baseline_needs_a_decision() -> None:
    within = _budget(10_000, 100, 200)
    size = sum(len(content) for content in within.values())
    assert size <= 300 and build.footprint_problems(within) == []
    grown = {**within, "ph_composer/vendor/pyodide/pyodide.asm.wasm": b"x" * (301 - size)}
    assert build.footprint_problems(grown) == [
        "installed size 301 bytes grew more than 200 bytes past the 100-byte phase baseline; record a decision "
        "and raise the baseline"
    ]


def test_two_packages_that_differ_in_any_file_have_different_build_identities() -> None:
    one = {**LOADER, "ph_composer/extension.rb": b"module PhComposer; end\n"}
    other = {**one, "ph_composer/extension.rb": b"module PhComposer; end # changed\n"}

    identity = json.loads(build.build_identity(one, "0123456789ab"))
    assert identity == {"build": build.package_digest(one), "commit": "0123456789ab"}
    assert len(identity["build"]) == 12
    assert build.package_digest(one) != build.package_digest(other)
    assert build.package_digest({**one, build.BUILD_IDENTITY: b"{}"}) == build.package_digest(one)
