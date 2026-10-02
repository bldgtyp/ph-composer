# /// script
# requires-python = ">=3.11"
# ///
"""Dependency fingerprints and attested case results. Never runs SketchUp or awards acceptance."""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import subprocess
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CATALOG = Path("planning/native-acceptance/cases.json")
RESULTS = Path("planning/native-acceptance/results.jsonl")


def read_catalog(root: Path) -> dict[str, dict[str, Any]]:
    document = json.loads((root / CATALOG).read_text())
    if document.get("schema_version") != 1:
        raise ValueError("unsupported catalog version")
    cases: dict[str, dict[str, Any]] = {}
    for case in document["cases"]:
        if case["id"] in cases or not case["paths"]:
            raise ValueError("duplicate case or missing dependency paths")
        for pattern in case["paths"]:
            if Path(pattern).is_absolute() or ".." in Path(pattern).parts:
                raise ValueError("dependency path must be repository-relative")
        cases[case["id"]] = case
    return cases


def source_names(root: Path) -> list[str]:
    """Tracked and nonignored names, including tracked deletions."""
    output = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=root)
    return sorted(set(output.decode().split("\0")) - {""})


def source_fingerprint(root: Path, patterns: list[str]) -> str:
    """Hash names and contents, including additions/deletions, without private/ignored material."""
    names = source_names(root)
    digest = hashlib.sha256()
    for name in names:
        if any(fnmatch.fnmatchcase(name, pattern) for pattern in patterns):
            path = root / name
            digest.update(name.encode() + b"\0")
            if path.is_symlink():
                digest.update(b"symlink:" + str(path.readlink()).encode())
            elif path.is_file():
                digest.update(path.read_bytes())
            else:
                digest.update(b"deleted")
            digest.update(b"\0")
    return digest.hexdigest()


def snapshot(root: Path, case: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "case_id": case["id"],
        "captured_at": datetime.now(UTC).isoformat(),
        "commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
        "source_fingerprint": source_fingerprint(root, case["paths"]),
        "dependency_paths": case["paths"],
    }


def validate_result(
    root: Path, cases: dict[str, dict[str, Any]], result: dict[str, Any], *, current: bool = True
) -> None:
    case = cases[result["case_id"]]
    if case.get("deferred"):
        raise ValueError("deferred case requires a scope decision and catalog update")
    allowed = {
        "schema_version",
        "case_id",
        "captured_at",
        "commit",
        "source_fingerprint",
        "dependency_paths",
        "evidence_kind",
        "outcome",
        "assertions",
        "evidence",
        "control",
        "host",
    }
    if set(result) - allowed:
        raise ValueError("unknown result fields; record only publication-safe summary fields")
    captured = datetime.fromisoformat(result["captured_at"])
    if captured.tzinfo is None:
        raise ValueError("captured_at requires a timezone")
    if result.get("schema_version") != 1 or result.get("outcome") not in ("pass", "fail", "blocked", "unknown"):
        raise ValueError("invalid result version/outcome")
    if result.get("evidence_kind") != "observed":
        raise ValueError("record accepts new observed results only; historical summaries stay distinct")
    if not result.get("assertions") or not all(
        isinstance(row.get("observation"), str)
        and row["observation"].strip()
        and row.get("status") in ("pass", "fail", "blocked", "unknown")
        for row in result["assertions"]
    ):
        raise ValueError("each assertion needs an observed status and observation")
    if result["outcome"] == "pass" and any(row["status"] != "pass" for row in result["assertions"]):
        raise ValueError("a passing result cannot contain failed/unknown assertions")
    for evidence in result.get("evidence", []):
        if Path(evidence).is_absolute() or ".." in Path(evidence).parts or not (root / evidence).is_file():
            raise ValueError("evidence must be an existing repository-relative file")
    if not result.get("evidence"):
        raise ValueError("result requires evidence")
    if current and (
        result.get("dependency_paths") != case["paths"]
        or result.get("source_fingerprint") != source_fingerprint(root, case["paths"])
    ):
        raise ValueError("source/dependency baseline changed; capture again and recheck")
    if case["mode"] in ("native", "mixed"):
        host = result.get("host", {})
        required = ("sketchup", "ruby", "session_id", "fixture_id", "fixture_sha256", "rbz_sha256", "composition")
        if any(not host.get(key) for key in required) or host.get("composition") not in ("normal", "synthetic"):
            raise ValueError("native result requires host/session/fixture/RBZ provenance and composition")
        if result.get("control") not in ("bridge", "native", "human", "combined"):
            raise ValueError("native result requires its observed control route")
        if case.get("native_control_required") and result["control"] not in ("native", "human", "combined"):
            raise ValueError("this case requires native interaction, not bridge-only simulation")


def read_results(root: Path, cases: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    results = []
    for line in (root / RESULTS).read_text().splitlines():
        result = json.loads(line)
        if result["case_id"] not in cases or result.get("schema_version") != 1:
            raise ValueError("unknown result case or schema")
        if result.get("evidence_kind") == "observed":
            validate_result(root, cases, result, current=False)
        elif result.get("evidence_kind") != "historical_summary" or result.get("outcome") not in (
            "pass",
            "fail",
            "blocked",
            "unknown",
        ):
            raise ValueError("invalid historical result")
        for evidence in result.get("evidence", []):
            if Path(evidence).is_absolute() or ".." in Path(evidence).parts or not (root / evidence).is_file():
                raise ValueError("missing or unsafe result evidence")
        results.append(result)
    return results


def status(root: Path, cases: dict[str, dict[str, Any]], changed: list[str]) -> list[dict[str, Any]]:
    latest = {row["case_id"]: row for row in read_results(root, cases)}
    rows = []
    for key, case in cases.items():
        result = latest.get(key, {})
        affected = [path for path in changed if any(fnmatch.fnmatchcase(path, p) for p in case["paths"])]
        state = "not_run"
        if case.get("deferred"):
            state = "deferred"
        elif result.get("evidence_kind") == "historical_summary":
            state = "historical_affected" if affected else "historical_evidence"
        elif result:
            same = result.get("dependency_paths") == case["paths"] and result.get(
                "source_fingerprint"
            ) == source_fingerprint(root, case["paths"])
            state = "source_unchanged_environment_unchecked" if same and not affected else "needs_recheck"
        rows.append(
            {
                "case_id": key,
                "state": state,
                "affected_paths": affected,
                "outcome": result.get("outcome"),
                "evidence": result.get("evidence", []),
            }
        )
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("validate")
    show = commands.add_parser("status")
    show.add_argument("--changed", action="append", default=[])
    capture = commands.add_parser("snapshot")
    capture.add_argument("case_id")
    capture.add_argument("--output", type=Path, required=True)
    record = commands.add_parser("record")
    record.add_argument("--input", type=Path, required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    cases = read_catalog(root)
    if args.command == "snapshot":
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("x") as stream:
            stream.write(json.dumps(snapshot(root, cases[args.case_id]), indent=2) + "\n")
    elif args.command == "record":
        result = json.loads(args.input.read_text())
        validate_result(root, cases, result)
        with (root / RESULTS).open("a") as stream:
            stream.write(json.dumps(result, sort_keys=True) + "\n")
    else:
        rows = status(root, cases, getattr(args, "changed", []))
        changed = getattr(args, "changed", [])
        unmapped = [
            path
            for path in changed
            if not any(fnmatch.fnmatchcase(path, pattern) for case in cases.values() for pattern in case["paths"])
        ]
        print(json.dumps({"schema_version": 1, "cases": rows, "unmapped_changes": unmapped}, indent=2))


if __name__ == "__main__":
    try:
        main()
    except (KeyError, TypeError, ValueError, OSError) as error:
        raise SystemExit(f"Invalid acceptance input: {error}") from error
