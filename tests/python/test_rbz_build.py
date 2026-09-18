"""The archive gate decides what reaches a user's Plugins folder, so each refusal is shown refusing.

These exercise the pure half, `shipping_problems`, over in-memory entries. `make rbz` and
`make rbz-check` run the filesystem half against the real tree on every `make ci`.
"""

from __future__ import annotations

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


def test_designph_and_the_predecessor_namespace_are_refused_in_any_case() -> None:
    found = problems(
        {
            "ph_composer/core/a.rb": b"DesignPH.Version\n",
            "ph_composer/html/b.js": b'Phn.define("x", [], f);\n',
            "ph_composer/shell/c.rb": b'callback = "phn_message"\n',
            "ph_composer/shell/d.rb": b"# PH-Navigator for SketchUp\n",
        }
    )
    assert found == [
        "denied name ph_composer/core/a.rb:1: DesignPH.Version",
        'denied name ph_composer/html/b.js:1: Phn.define("x", [], f);',
        'denied name ph_composer/shell/c.rb:1: callback = "phn_message"',
        "denied name ph_composer/shell/d.rb:1: # PH-Navigator for SketchUp",
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
