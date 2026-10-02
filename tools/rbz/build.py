# /// script
# requires-python = ">=3.11"
# ///
"""Build, check and install the PH-Composer archive.

The archive holds the loader, `ph_composer.rb`, and the extension folder, `ph_composer/`, and
nothing else. Every build and every `--check` refuses an archive that carries development
material, a file type the extension does not ship, the retired designPH integration, the
predecessor's namespace, or a blocking browser API. Documentary citations that must name the
predecessor are admitted line by line through `shipping_allowlist.json`, each with a reason.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import zipfile
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "src"
DIST = ROOT / "dist"
EXTENSION_ID = "ph_composer"
LOADER = f"{EXTENSION_ID}.rb"
ARCHIVE = DIST / f"{EXTENSION_ID}.rbz"
ALLOWLIST = Path(__file__).with_name("shipping_allowlist.json")
ZIP_EPOCH = (1980, 1, 1, 0, 0, 0)
RUNTIME_MANIFEST = f"{EXTENSION_ID}/vendor/manifest.json"

# What the extension ships. A new kind of asset is a packaging decision, made here.
SHIPPED_SUFFIXES = frozenset(
    {".rb", ".js", ".css", ".html", ".svg", ".pdf", ".json", ".py", ".md", ".txt", ".wasm", ".zip", ".whl"}
)

# Development material never ships, whatever its suffix: the host bridge and probes, synthetic
# examples and fixtures, tests and the private corpus.
DEVELOPMENT_PARTS = frozenset({"_private", "hostkit", "examples", "fixtures", "tests", "starter-library"})

# The retired designPH integration and the predecessor's namespace. Case-insensitive, so `Phn.`,
# `Phn::`, `phn_message`, the `phn-` CSS prefix, `DesignPH_dict` and `PH-Navigator` all match, while
# "design phase" does not.
DENIED_PATTERN = re.compile(r"design[_ ]?ph(?![a-z])|ph[_ -]?navigator|\bphn(?:[._-]|::)", re.IGNORECASE)

# A blocking dialog freezes the HtmlDialog and the SketchUp main thread with it.
BLOCKING_BROWSER_APIS = ("alert(", "confirm(", "prompt(")
# A call, not the tail of a longer identifier such as `showAlert(`.
CALL_PREFIX = r"(?<![A-Za-z0-9_$])"


@dataclass(frozen=True)
class AllowedLine:
    """One reviewed line that may name the predecessor, such as a source citation."""

    path: str
    line: str
    reason: str


def load_allowlist(path: Path = ALLOWLIST) -> list[AllowedLine]:
    entries = json.loads(path.read_text())["entries"]
    return [AllowedLine(entry["path"], entry["line"], entry["reason"]) for entry in entries]


def source_files(source: Path = SOURCE) -> list[Path]:
    """The loader and every file under the extension folder. Dotfiles and bytecode are host
    litter rather than content, so they are left out instead of refused."""
    extension = source / EXTENSION_ID
    candidates = [source / LOADER, *(extension.rglob("*") if extension.is_dir() else [])]
    return sorted(
        path
        for path in candidates
        if path.is_file()
        and not path.name.startswith(".")
        and "__pycache__" not in path.parts
        and path.suffix != ".pyc"
    )


def archive_name(path: Path, source: Path = SOURCE) -> str:
    return path.relative_to(source).as_posix()


def blocking_api_tokens(name: str, text: str) -> list[str]:
    """Which blocking browser APIs a shipped panel file uses. Vendored runtime code is exempt: it is
    not our panel and never runs in the dialog's own context."""
    if "/vendor/" in name or not name.endswith((".js", ".html")):
        return []
    return [token for token in BLOCKING_BROWSER_APIS if re.search(CALL_PREFIX + re.escape(token), text)]


def denied_lines(name: str, text: str, allowed: list[AllowedLine]) -> list[str]:
    """Lines that name designPH or the predecessor and are not individually allowlisted."""
    admitted = {entry.line for entry in allowed if entry.path == name}
    return [
        f"{name}:{number}: {line.strip()}"
        for number, line in enumerate(text.splitlines(), start=1)
        if DENIED_PATTERN.search(line) and line.strip() not in admitted
    ]


def shipping_problems(entries: Mapping[str, bytes], allowed: list[AllowedLine]) -> list[str]:
    """Every reason these archive entries may not ship. Empty means the archive may ship."""
    problems: list[str] = []
    root_files = sorted(name for name in entries if "/" not in name)
    if root_files != [LOADER]:
        problems.append(f"archive root must hold only {LOADER}; found {root_files}")
    for name in sorted(entries):
        parts = name.split("/")
        if "/" in name and parts[0] != EXTENSION_ID:
            problems.append(f"{name}: outside the extension folder")
        if development := sorted(DEVELOPMENT_PARTS.intersection(parts)):
            problems.append(f"{name}: development material ({', '.join(development)})")
        if Path(name).suffix not in SHIPPED_SUFFIXES:
            problems.append(f"{name}: file type {Path(name).suffix or '(none)'} does not ship")
        text = entries[name].decode("utf-8", errors="replace")
        problems.extend(f"denied name {line}" for line in denied_lines(name, text, allowed))
        if found := blocking_api_tokens(name, text):
            problems.append(f"{name}: blocking browser API {found}")
    for entry in allowed:
        if entry.path not in entries or entry.line not in _stripped_lines(entries[entry.path]):
            problems.append(f"stale allowlist entry {entry.path}: {entry.line!r}")
    return problems


def footprint_problems(entries: Mapping[str, bytes]) -> list[str]:
    """The installed extension against the runtime manifest's installed-size ceiling. The budget covers
    everything the archive unpacks, not only the runtime payload the manifest lists."""
    manifest = entries.get(RUNTIME_MANIFEST)
    if manifest is None:
        return [f"{RUNTIME_MANIFEST}: missing, so the installed-size budget cannot be checked"]
    ceiling = json.loads(manifest)["gates"]["installed_ceiling_bytes"]
    installed = sum(len(content) for content in entries.values())
    return [f"installed size {installed} bytes exceeds the {ceiling}-byte ceiling"] if installed > ceiling else []


def _stripped_lines(content: bytes) -> set[str]:
    return {line.strip() for line in content.decode("utf-8", errors="replace").splitlines()}


def syntax_check(ruby: str) -> None:
    for path in sorted(SOURCE.rglob("*.rb")):
        result = subprocess.run([ruby, "-c", str(path)], capture_output=True, text=True, check=False)
        if result.returncode:
            raise SystemExit(result.stdout + result.stderr)


def write_archive(ruby: str) -> None:
    syntax_check(ruby)
    entries = {archive_name(path): path.read_bytes() for path in source_files()}
    if problems := shipping_problems(entries, load_allowlist()):
        raise SystemExit("refusing to build:\n  " + "\n  ".join(problems))
    DIST.mkdir(exist_ok=True)
    with zipfile.ZipFile(ARCHIVE, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        for name, content in sorted(entries.items()):
            info = zipfile.ZipInfo(name, date_time=ZIP_EPOCH)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            bundle.writestr(info, content)


def check_archive() -> None:
    if not ARCHIVE.exists():
        raise SystemExit(f"missing {ARCHIVE.relative_to(ROOT)}; run make rbz")
    with zipfile.ZipFile(ARCHIVE) as bundle:
        entries = {name: bundle.read(name) for name in bundle.namelist()}
    expected = {archive_name(path) for path in source_files()}
    if set(entries) != expected:
        missing = sorted(expected - set(entries))
        extra = sorted(set(entries) - expected)
        raise SystemExit(f"archive is stale; run make rbz. missing={missing}, extra={extra}")
    if problems := shipping_problems(entries, load_allowlist()) + footprint_problems(entries):
        raise SystemExit("archive may not ship:\n  " + "\n  ".join(problems))
    installed = sum(len(content) for content in entries.values())
    print(f"RBZ verified: {len(entries)} files, {ARCHIVE.stat().st_size} bytes, {installed} bytes installed")


def plugins_directory(sketchup_version: str) -> Path:
    if len(sketchup_version) != 4 or not sketchup_version.isdigit():
        raise SystemExit("SketchUp version must be a four-digit year, such as 2026")
    return Path.home() / f"Library/Application Support/SketchUp {sketchup_version}/SketchUp/Plugins"


def install(sketchup_version: str) -> None:
    plugins = plugins_directory(sketchup_version)
    if not plugins.is_dir():
        raise SystemExit(f"SketchUp {sketchup_version} Plugins directory not found: {plugins}")
    install_into(plugins, ARCHIVE)
    print(f"Installed into {plugins}")


def install_into(plugins: Path, archive: Path) -> None:
    """Replaces only this extension's loader and folder in `plugins`, so a file removed from the
    extension does not linger from an earlier install. Every other plugin is left untouched."""
    support = plugins / EXTENSION_ID
    if support.exists():
        shutil.rmtree(support)
    with zipfile.ZipFile(archive) as bundle:
        bundle.extractall(plugins)


def clean() -> None:
    if ARCHIVE.exists():
        ARCHIVE.unlink()
    if DIST.exists() and not any(DIST.iterdir()):
        DIST.rmdir()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--install", action="store_true")
    parser.add_argument("--clean", action="store_true")
    parser.add_argument("--sketchup-version", default="2026")
    parser.add_argument("--ruby", default=os.environ.get("RUBY", "ruby"))
    args = parser.parse_args()

    if args.clean:
        clean()
        return 0
    if args.check:
        check_archive()
        return 0
    write_archive(args.ruby)
    check_archive()
    if args.install:
        install(args.sketchup_version)
    return 0


if __name__ == "__main__":
    sys.exit(main())
