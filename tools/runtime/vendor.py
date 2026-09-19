# /// script
# requires-python = ">=3.11"
# ///
"""Vendor, describe and verify the runtime payload the extension serves to its Python runtime.

The manifest (`src/ph_composer/vendor/manifest.json`) is what the shipped asset server trusts: every
asset it may serve, with its size, SHA-256 and MIME type, plus the pinned Pyodide source and the
performance gates. This tool writes it and checks the tree against it.

    uv run tools/runtime/vendor.py                    # download Pyodide, verify it, write the manifest
    uv run tools/runtime/vendor.py --refresh-manifest # after editing shipped html/ or python/ files
    uv run tools/runtime/vendor.py --check            # offline: tree, pins, gates and size budget agree
    uv run tools/runtime/vendor.py --pins-check       # shipped wheels agree with pyproject.toml
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import tarfile
import tempfile
import tomllib
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
EXTENSION = ROOT / "src" / "ph_composer"
VENDOR = EXTENSION / "vendor"
MANIFEST = VENDOR / "manifest.json"
MANIFEST_ASSET = "vendor/manifest.json"
PYODIDE_VERSION = "0.24.1"
PYODIDE_SHA256 = "7470bde4b38aa1fcc82d7f64d23b938510f10d7ff349b7a309d4e43a0e143443"
PYODIDE_SOURCE_BYTES = 4_604_614
PYODIDE_URL = (
    f"https://github.com/pyodide/pyodide/releases/download/{PYODIDE_VERSION}/pyodide-core-{PYODIDE_VERSION}.tar.bz2"
)
RUNTIME_FILES = ("pyodide.js", "pyodide.asm.js", "pyodide.asm.wasm", "pyodide-lock.json", "python_stdlib.zip")
# The folders the asset server may serve from. The panel page, the translation package and the
# Pyodide core; nothing else under the extension is reachable over loopback.
ASSET_ROOTS = ("html", "python", "vendor/pyodide")


@dataclass(frozen=True)
class PackagePin:
    name: str
    version: str
    filename: str
    url_path: str
    sha256: str
    license: str
    holder: str


# The wheels the runtime installs, in install order. Phase 0 ships none: the foundation's package
# shell imports without them, and the predecessor's eight honeybee-family pins stay recorded as
# evidence in planning/archive/phase-zero/SOURCE_INVENTORY.md until a package decision adds them.
PACKAGE_PINS: tuple[PackagePin, ...] = ()

MIME_TYPES = {
    ".html": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".json": "application/json",
    ".wasm": "application/wasm",
    ".zip": "application/zip",
    ".whl": "application/octet-stream",
    ".py": "text/plain; charset=utf-8",
    ".svg": "image/svg+xml",
}
# Carried unchanged from the predecessor's frozen manifest. Raising one is a recorded decision.
GATES: dict[str, Any] = {
    "panel_ready_target_ms": 1_000,
    "panel_ready_ceiling_ms": 2_000,
    "cold_boot_target_ms": 4_000,
    "cold_boot_ceiling_ms": 6_000,
    "warm_round_trip_target_ms": 20,
    "warm_round_trip_ceiling_ms": 100,
    "installed_target_bytes": 22_000_000,
    "installed_ceiling_bytes": 24_000_000,
    "boot_deadline_ms": 15_000,
    "pump_target_ms": 20,
    "pump_ceiling_ms": 50,
    "platform_win": {"cold_boot_ceiling_ms": 12_000},
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(url: str, destination: Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": "ph-composer-vendor/1"})
    with urllib.request.urlopen(request, timeout=300) as response, destination.open("wb") as output:
        shutil.copyfileobj(response, output)


def vendor() -> None:
    """Replace the Pyodide core with the pinned release, verified by hash, and rewrite the manifest."""
    runtime_dir = VENDOR / "pyodide"
    if runtime_dir.exists():
        shutil.rmtree(runtime_dir)
    runtime_dir.mkdir(parents=True)
    with tempfile.TemporaryDirectory(prefix="ph-composer-runtime-") as temporary:
        tarball = Path(temporary) / f"pyodide-core-{PYODIDE_VERSION}.tar.bz2"
        download(PYODIDE_URL, tarball)
        if (actual := sha256(tarball)) != PYODIDE_SHA256:
            raise SystemExit(f"pyodide core sha256 mismatch: expected {PYODIDE_SHA256}, got {actual}")
        with tarfile.open(tarball, "r:bz2") as archive:
            members = {Path(member.name).name: member for member in archive.getmembers() if member.isfile()}
            for filename in RUNTIME_FILES:
                source = archive.extractfile(members[filename])
                if source is None:
                    raise SystemExit(f"pyodide core is missing {filename}")
                with (runtime_dir / filename).open("wb") as output:
                    shutil.copyfileobj(source, output)
    write_manifest()
    check()


def asset_files(extension: Path = EXTENSION) -> list[Path]:
    return sorted(
        path
        for root in ASSET_ROOTS
        for path in (extension / root).rglob("*")
        if path.is_file()
        and "__pycache__" not in path.parts
        and path.suffix != ".pyc"
        and not path.name.startswith(".")
    )


def translation_assets(extension: Path = EXTENSION) -> list[str]:
    """The translation package's modules, in the order the loader writes them into the runtime."""
    return [
        path.relative_to(extension).as_posix()
        for path in asset_files(extension)
        if path.is_relative_to(extension / "python") and path.suffix == ".py"
    ]


def mime_type(path: Path) -> str:
    return MIME_TYPES.get(path.suffix.lower(), "application/octet-stream")


def build_manifest(extension: Path = EXTENSION) -> dict[str, Any]:
    assets = {
        path.relative_to(extension).as_posix(): {
            "bytes": path.stat().st_size,
            "sha256": sha256(path),
            "mime": mime_type(path),
        }
        for path in asset_files(extension)
    }
    return {
        "schema_version": 1,
        "manifest_asset": MANIFEST_ASSET,
        "pyodide": {
            "version": PYODIDE_VERSION,
            "python_version": "3.11.3",
            # The repository's LICENSE is MPL-2.0; the release's package.json declares Apache-2.0.
            # Both are recorded until the licensing gate settles the notice (docs/LICENSING.md).
            "license": "MPL-2.0",
            "package_json_license": "Apache-2.0",
            "cpython_license": "PSF-2.0",
            "source": PYODIDE_URL,
            "source_bytes": PYODIDE_SOURCE_BYTES,
            "source_sha256": PYODIDE_SHA256,
            "assets": {filename: assets.get(f"vendor/pyodide/{filename}") for filename in RUNTIME_FILES},
        },
        "packages": [package_entry(pin) for pin in PACKAGE_PINS],
        "wheel_order": [pin.filename for pin in PACKAGE_PINS],
        "translation_assets": translation_assets(extension),
        "gates": GATES,
        "assets": assets,
    }


def package_entry(pin: PackagePin) -> dict[str, Any]:
    return {
        "name": pin.name,
        "version": pin.version,
        "filename": pin.filename,
        "source": f"https://files.pythonhosted.org/packages/{pin.url_path}/{pin.filename}",
        "sha256": pin.sha256,
        "license": pin.license,
        "copyright_holder": pin.holder,
    }


def write_manifest() -> None:
    MANIFEST.write_text(json.dumps(build_manifest(), indent=2, sort_keys=True) + "\n")


def refresh_manifest() -> None:
    missing = [name for name in RUNTIME_FILES if not (VENDOR / "pyodide" / name).is_file()]
    if missing:
        raise SystemExit(f"the Pyodide core is incomplete ({missing}); run tools/runtime/vendor.py first")
    # Refreshing re-hashes html/ and python/ edits; it never adopts a changed Pyodide file.
    pinned = json.loads(MANIFEST.read_text())["pyodide"]["assets"] if MANIFEST.exists() else {}
    for name, entry in pinned.items():
        if entry["sha256"] != sha256(VENDOR / "pyodide" / name):
            raise SystemExit(f"vendor/pyodide/{name} differs from the pinned release; run tools/runtime/vendor.py")
    write_manifest()
    check()


def problems(manifest: dict[str, Any], extension: Path = EXTENSION) -> list[str]:
    """Every disagreement between the manifest, the pins in this file and the files on disk."""
    found: list[str] = []
    expected = build_manifest(extension)
    for key in ("schema_version", "manifest_asset", "gates", "translation_assets", "packages", "wheel_order"):
        if manifest.get(key) != expected[key]:
            found.append(f"{key} drift")
    if manifest.get("pyodide") != expected["pyodide"]:
        found.append("Pyodide pin or asset drift")
    declared, actual = manifest.get("assets", {}), expected["assets"]
    found.extend(f"undeclared asset: {name}" for name in sorted(set(actual) - set(declared)))
    found.extend(f"missing asset: {name}" for name in sorted(set(declared) - set(actual)))
    for name in sorted(set(actual) & set(declared)):
        for field in ("bytes", "sha256", "mime"):
            if declared[name].get(field) != actual[name][field]:
                found.append(f"{field} mismatch: {name}")
    return found


def installed_bytes(manifest: dict[str, Any], manifest_bytes: int) -> int:
    return sum(entry["bytes"] for entry in manifest["assets"].values()) + manifest_bytes


def check() -> None:
    if not MANIFEST.exists():
        raise SystemExit("runtime manifest is missing; run tools/runtime/vendor.py")
    manifest = json.loads(MANIFEST.read_text())
    found = problems(manifest)
    total = installed_bytes(manifest, MANIFEST.stat().st_size)
    if total > GATES["installed_ceiling_bytes"]:
        found.append(f"runtime payload {total} bytes exceeds the {GATES['installed_ceiling_bytes']}-byte ceiling")
    if found:
        raise SystemExit("runtime verification failed:\n  " + "\n  ".join(found))
    over = " (over the target)" if total > GATES["installed_target_bytes"] else ""
    print(f"Runtime verified: {len(manifest['assets'])} assets, {len(PACKAGE_PINS)} wheels, {total} bytes{over}")


def pins_check() -> None:
    """The wheels that ship against the wheels the offline Python tests install. Nothing else compares
    them, so a version bump in one could pass every other check."""
    with (ROOT / "pyproject.toml").open("rb") as handle:
        dependencies = tomllib.load(handle)["project"]["dependencies"]
    declared = dict(requirement.split("==", 1) for requirement in dependencies if "==" in requirement)
    shipped = {pin.name: pin.version for pin in PACKAGE_PINS}
    found = [
        f"{name}: ships {version}, pyproject.toml pins {declared.get(name, 'nothing')}"
        for name, version in sorted(shipped.items())
        if declared.get(name) != version
    ]
    found.extend(
        f"{name} {version} is pinned for tests but does not ship"
        for name, version in sorted(declared.items())
        if name not in shipped
    )
    if found:
        raise SystemExit("Wheel pins disagree:\n  " + "\n  ".join(found))
    print(f"Wheel pins agree: {len(shipped)} wheels")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--check", action="store_true", help="verify the tree without network access")
    action.add_argument("--refresh-manifest", action="store_true", help="re-hash after editing html/ or python/")
    action.add_argument("--pins-check", action="store_true", help="compare shipped wheels with pyproject.toml")
    args = parser.parse_args()
    if args.check:
        check()
    elif args.refresh_manifest:
        refresh_manifest()
    elif args.pins_check:
        pins_check()
    else:
        vendor()


if __name__ == "__main__":
    main()
