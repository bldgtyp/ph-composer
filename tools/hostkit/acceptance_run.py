# /// script
# requires-python = ">=3.11"
# ///
"""Private immutable run baselines and assertion dependency screens; never awards acceptance."""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import re
import uuid
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from urllib.parse import unquote
from zipfile import ZipFile

from acceptance_ledger import source_fingerprint, source_names

HOST_KEYS = ("sketchup", "ruby", "os", "controller", "session_id", "fixture_sha256", "rbz_sha256", "composition")
PREFLIGHT_KEYS = ("window_active", "tool_ready", "target_ready", "probe_callbacks_verified", "writer_verified")


def write_once(path: Path, document: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x") as stream:
        stream.write(json.dumps(document, indent=2) + "\n")


def capture(root: Path, recipe: dict[str, Any]) -> dict[str, Any]:
    """Freeze explicitly observed preconditions and independently scoped assertions."""
    host = recipe["host"]
    if any(not isinstance(host.get(key), str) or not host[key].strip() for key in HOST_KEYS):
        raise ValueError("host identity requires nonempty strings for " + ", ".join(HOST_KEYS))
    for key in ("fixture_sha256", "rbz_sha256"):
        if not re.fullmatch(r"[0-9a-f]{64}", host[key]):
            raise ValueError(f"invalid {key}")
    preflight = recipe["preflight"]
    for key in PREFLIGHT_KEYS:
        row = preflight[key]
        if (
            row.get("ready") is not True
            or not isinstance(row.get("observation"), str)
            or not row["observation"].strip()
        ):
            raise ValueError(f"preflight {key} needs ready=true and an actual observation")
    if not isinstance(recipe["edit_path"], list) or not recipe.get("active_tool"):
        raise ValueError("record active_tool and edit_path (including an empty root path)")
    if host["composition"] not in ("normal", "synthetic"):
        raise ValueError("composition must be normal or synthetic")
    assertions = []
    ids: set[str] = set()
    names = source_names(root)
    for row in recipe["assertions"]:
        if not row.get("id") or row["id"] in ids:
            raise ValueError("assertion IDs must be nonempty and unique")
        ids.add(row["id"])
        paths = row["paths"]
        if not paths or any(Path(p).is_absolute() or ".." in Path(p).parts for p in paths):
            raise ValueError("assertion dependency paths must be nonempty and repository-relative")
        for pattern in paths:
            if not any(fnmatch.fnmatchcase(name, pattern) for name in names):
                raise ValueError(f"dependency pattern matched no source files: {pattern}")
        environment_keys = row["environment_keys"]
        if not environment_keys or set(environment_keys) - set(HOST_KEYS):
            raise ValueError("assertions need explicit known environment dependencies")
        assertions.append({**row, "source_fingerprint": source_fingerprint(root, paths)})
    if not assertions:
        raise ValueError("run requires assertions")
    return {
        "schema_version": 1,
        "run_id": str(uuid.uuid4()),
        "captured_at": datetime.now(UTC).isoformat(),
        "host": host,
        "active_tool": recipe["active_tool"],
        "edit_path": recipe["edit_path"],
        "preflight": preflight,
        "assertions": assertions,
    }


def screen(root: Path, baseline: dict[str, Any], current_host: dict[str, Any]) -> list[dict[str, Any]]:
    """No pass/fail inference: unchanged dependencies still require observation review."""
    rows = []
    if baseline.get("schema_version") != 1:
        raise ValueError("unsupported run schema")
    for assertion in baseline["assertions"]:
        reasons = []
        if source_fingerprint(root, assertion["paths"]) != assertion["source_fingerprint"]:
            reasons.append("source dependencies changed")
        for key in assertion["environment_keys"]:
            if key not in current_host or current_host[key] != baseline["host"][key]:
                reasons.append(f"environment changed or unobserved: {key}")
        rows.append(
            {
                "id": assertion["id"],
                "state": "needs_recheck" if reasons else "dependencies_unchanged",
                "reasons": reasons,
                "acceptance": "not_evaluated",
            }
        )
    return rows


def observe(baseline: dict[str, Any], observations: dict[str, Any]) -> dict[str, Any]:
    """Attach timestamped observations to an existing run without changing its baseline."""
    expected = {row["id"] for row in baseline["assertions"]}
    rows = observations["assertions"]
    if len(rows) != len(expected) or {row["id"] for row in rows} != expected:
        raise ValueError("observations must cover exactly the baseline assertion IDs")
    for row in rows:
        if row["status"] not in ("pass", "fail", "unknown", "blocked") or not row["observation"].strip():
            raise ValueError("each assertion requires an observed status and observation")
        evidence = Path(row["evidence"])
        if not evidence.is_file():
            raise ValueError("each observation requires an existing evidence file")
    return {
        "schema_version": 1,
        "run_id": baseline["run_id"],
        "captured_at": datetime.now(UTC).isoformat(),
        "evidence_kind": "attested_observation",
        "assertions": [
            {**row, "evidence_sha256": hashlib.sha256(Path(row["evidence"]).read_bytes()).hexdigest()} for row in rows
        ],
    }


def installed_package(rbz: Path, plugins: Path) -> dict[str, Any]:
    """Compare all archive bytes and detect extra installed extension files, without installing."""
    with ZipFile(rbz) as archive:
        members = [row for row in archive.infolist() if not row.is_dir()]
        names = [row.filename for row in members]
        if "ph_composer.rb" not in names or not any(name.startswith("ph_composer/") for name in names):
            raise ValueError("RBZ requires the extension loader and payload")
        if len(names) != len(set(names)) or any(
            Path(name).is_absolute()
            or ".." in Path(name).parts
            or not (name == "ph_composer.rb" or name.startswith("ph_composer/"))
            for name in names
        ):
            raise ValueError("unexpected or duplicate RBZ member")
        mismatches = [
            name
            for name in names
            if not (plugins / name).is_file() or (plugins / name).read_bytes() != archive.read(name)
        ]
    actual = {str(path.relative_to(plugins)) for path in (plugins / "ph_composer").rglob("*") if path.is_file()}
    extras = sorted(actual - set(names))
    return {
        "rbz_sha256": hashlib.sha256(rbz.read_bytes()).hexdigest(),
        "entries": len(names),
        "mismatches": mismatches,
        "extras": extras,
        "matches": not mismatches and not extras,
    }


def check_links(root: Path, paths: list[Path]) -> list[str]:
    """Check local Markdown file targets, including archive symlinks; ignore URLs and anchors."""
    missing = []
    for path in paths:
        for target in re.findall(r"\]\((<[^>]+>|[^\s)]+)(?:\s+[^)]*)?\)", path.read_text()):
            target = target.strip("<>").split("#", 1)[0]
            if not target or re.match(r"[a-zA-Z][a-zA-Z0-9+.-]*:", target):
                continue
            target = unquote(target)
            resolved = root / target.lstrip("/") if target.startswith("/") else path.parent / target
            if not resolved.exists():
                missing.append(f"{path.relative_to(root)}: {target}")
    return missing


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    commands = parser.add_subparsers(dest="command", required=True)
    start = commands.add_parser("capture")
    start.add_argument("--recipe", type=Path, required=True)
    start.add_argument("--output", type=Path, required=True)
    compare = commands.add_parser("screen")
    compare.add_argument("--baseline", type=Path, required=True)
    compare.add_argument("--host", type=Path, required=True)
    observed = commands.add_parser("observe")
    observed.add_argument("--baseline", type=Path, required=True)
    observed.add_argument("--input", type=Path, required=True)
    observed.add_argument("--output", type=Path, required=True)
    package = commands.add_parser("package")
    package.add_argument("--rbz", type=Path, required=True)
    package.add_argument("--plugins", type=Path, required=True)
    links = commands.add_parser("links")
    links.add_argument("paths", nargs="+", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    if args.command == "capture":
        write_once(args.output, capture(root, json.loads(args.recipe.read_text())))
    elif args.command == "screen":
        print(
            json.dumps(screen(root, json.loads(args.baseline.read_text()), json.loads(args.host.read_text())), indent=2)
        )
    elif args.command == "observe":
        write_once(args.output, observe(json.loads(args.baseline.read_text()), json.loads(args.input.read_text())))
    elif args.command == "package":
        receipt = installed_package(args.rbz, args.plugins)
        print(json.dumps(receipt, indent=2))
        if not receipt["matches"]:
            raise SystemExit(1)
    else:
        missing = check_links(root, [path.resolve() for path in args.paths])
        print(json.dumps({"missing": missing}, indent=2))
        if missing:
            raise SystemExit(1)


if __name__ == "__main__":
    try:
        main()
    except (KeyError, TypeError, ValueError, OSError) as error:
        raise SystemExit(f"Invalid acceptance run input: {error}") from error
