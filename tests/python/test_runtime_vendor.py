"""The runtime manifest is what the shipped asset server trusts, so every kind of drift between it,
the pins in `vendor.py` and the files on disk must be reported. These run against a synthetic
extension tree; `make runtime-check` runs the same check against the real one."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

import vendor


@pytest.fixture
def extension(tmp_path: Path) -> Path:
    for name in vendor.RUNTIME_FILES:
        write(tmp_path / "vendor" / "pyodide" / name, f"{name} bytes")
    write(tmp_path / "html" / "runtime.html", "<p>runtime</p>")
    write(tmp_path / "python" / "ph_composer_translation" / "__init__.py", "")
    write(tmp_path / "shell" / "panel.rb", "# not served")
    return tmp_path


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def test_a_fresh_manifest_has_no_problems_and_declares_only_served_folders(extension: Path) -> None:
    manifest = vendor.build_manifest(extension)
    assert vendor.problems(manifest, extension) == []
    assert "shell/panel.rb" not in manifest["assets"]
    assert manifest["translation_assets"] == ["python/ph_composer_translation/__init__.py"]
    assert manifest["assets"]["vendor/pyodide/pyodide.asm.wasm"]["mime"] == "application/wasm"


def test_a_tampered_asset_is_reported(extension: Path) -> None:
    manifest = vendor.build_manifest(extension)
    write(extension / "html" / "runtime.html", "<p>runtimf</p>")
    assert vendor.problems(manifest, extension) == ["sha256 mismatch: html/runtime.html"]


def test_an_unlisted_and_a_missing_asset_are_reported(extension: Path) -> None:
    manifest = vendor.build_manifest(extension)
    write(extension / "html" / "extra.js", "")
    (extension / "python" / "ph_composer_translation" / "__init__.py").unlink()
    assert vendor.problems(manifest, extension) == [
        "translation_assets drift",
        "undeclared asset: html/extra.js",
        "missing asset: python/ph_composer_translation/__init__.py",
    ]


def test_pin_and_gate_drift_is_reported(extension: Path) -> None:
    manifest = json.loads(json.dumps(vendor.build_manifest(extension)))
    manifest["gates"]["installed_ceiling_bytes"] = 99_000_000
    manifest["pyodide"]["version"] = "0.25.0"
    assert vendor.problems(manifest, extension) == ["gates drift", "Pyodide pin or asset drift"]


def test_installed_bytes_counts_every_asset_and_the_manifest(extension: Path) -> None:
    manifest = vendor.build_manifest(extension)
    expected = sum(entry["bytes"] for entry in manifest["assets"].values()) + 100
    assert vendor.installed_bytes(manifest, 100) == expected
