# /// script
# requires-python = ">=3.11"
# ///
"""Begin and finish one native acceptance case in two commands.

`begin` reads the host's identity from the live bridge (session, tool, edit path, SketchUp and Ruby
versions), checks the installed extension against `dist/ph_composer.rbz` byte for byte, hashes the
fixture, proves the case folder is writable, writes the recipe, captures the immutable run baseline
(`acceptance_run.py capture`), snapshots the ledger's view of the case and starts the case's `steps.md`.
`finish` attaches the observations (`acceptance_run.py observe`) and appends the ledger result
(`acceptance_ledger.py record`). Neither awards acceptance: the observations are the evidence.

    uv run tools/hostkit/acceptance_case.py begin A09 --run-dir _private/host/acceptance-3a \\
      --fixture _private/host/acceptance-3a/A09/a09.skp --fixture-id "fresh copy of reference-assigned.skp" \\
      --control native --assert narrow-keyboard --assert held-model \\
      --window "a09.skp the only document in a fresh process" --target "Zones west and east, every Face classified" \\
      --probe "no callback instrumentation; public outcomes read back in separate calls"
    uv run tools/hostkit/acceptance_case.py finish A09 --run-dir _private/host/acceptance-3a \\
      --evidence planning/native-acceptance/evidence/<run>.md

The case folder is `<run-dir>/<case>/`. `finish` reads `observations.json` there: one row per assertion,
with `id`, `status`, `observation` and an existing `evidence` file. `steps.md` records how the case was
driven, so a rerun starts from it instead of rediscovering coordinates and setup.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

# ty checks a PEP 723 script in its own environment, without the script's directory that Python puts on
# sys.path at run time, so these sibling imports resolve when run and not for ty.
from acceptance_ledger import RESULTS, read_catalog, snapshot, validate_result  # ty: ignore[unresolved-import]
from acceptance_run import capture, installed_package, observe, write_once  # ty: ignore[unresolved-import]
from host_bridge import BridgeError, evaluate  # ty: ignore[unresolved-import]

ROOT = Path(__file__).resolve().parents[2]
ENVIRONMENT_KEYS = ["sketchup", "ruby", "os", "controller", "fixture_sha256", "rbz_sha256", "composition"]
OUTCOME_RANK = {"fail": 3, "blocked": 2, "unknown": 1, "pass": 0}
LIVE_READ = (
    "m = Sketchup.active_model; "
    '[PhComposer::API.discover["sessions"].find { |s| s["active"] }["id"], m.tools.active_tool_name, '
    "Array(m.active_path).map(&:persistent_id), Sketchup.version, RUBY_VERSION, m.path, m.modified?]"
)
RUN_FILES = ("recipe.json", "meta.json", "baseline.json", "snapshot.json")
STEPS_TEMPLATE = """# {case}: how this case was driven

Write each step as you run it, so a rerun starts here. Coordinates are in the computer-use screen frame
of the most recent full screenshot; say which window and size they belong to.

## Fixture and host

- Fixture: {fixture} (SHA-256 {fixture_sha256:.8}), copied fresh from:
- Process: fresh launch with `host_bridge.py launch`, or shared with which case:

## Setup through the bridge (labelled setup, never the assertion)

## Panel, camera and windows

- Panel size and position (`set_size`, `set_position`):
- Camera:

## Native steps, per assertion

## Probes and readbacks

## Restoration
"""


def live_identity(version: str, rbz: Path, plugins: Path, fixture: Path) -> dict[str, Any]:
    """The host as it is now: bridge readbacks plus the installed package, which must match `rbz`, with
    `fixture` the open document and nothing changed in it yet."""
    package = installed_package(rbz, plugins)
    if not package["matches"]:
        raise ValueError(f"installed extension does not match {rbz}: {package}")
    session_id, tool, path, sketchup, ruby, document, modified = evaluate(version, LIVE_READ)
    if Path(document).resolve() != fixture.resolve():
        raise ValueError(f"the open document is {document!r}, not the fixture {fixture}")
    if modified:
        raise ValueError("the fixture is already modified in SketchUp; begin from a freshly opened copy")
    macos = subprocess.check_output(["sw_vers", "-productVersion"], text=True).strip()
    return {
        "sketchup": sketchup,
        "ruby": ruby,
        "os": f"macOS {macos}",
        "session_id": session_id,
        "rbz_sha256": package["rbz_sha256"],
        "tool": tool,
        "path": path,
    }


def build_recipe(
    case: dict[str, Any], identity: dict[str, Any], args: argparse.Namespace, fixture_sha256: str, writer: str
) -> dict[str, Any]:
    host = {key: identity[key] for key in ("sketchup", "ruby", "os", "session_id", "rbz_sha256")}
    host.update(controller=args.controller, fixture_sha256=fixture_sha256, composition=args.composition)
    preflight = {
        "window_active": {"ready": True, "observation": args.window},
        "tool_ready": {
            "ready": True,
            "observation": f"Bridge read active tool {identity['tool']}, active path {identity['path']}",
        },
        "target_ready": {"ready": True, "observation": args.target},
        "probe_callbacks_verified": {"ready": True, "observation": args.probe},
        "writer_verified": {"ready": True, "observation": f"writer check read back: {writer}"},
    }
    return {
        "host": host,
        "active_tool": identity["tool"],
        "edit_path": identity["path"],
        "preflight": preflight,
        "assertions": [
            {"id": f"{case['id']}/{slug}", "paths": case["paths"], "environment_keys": ENVIRONMENT_KEYS}
            for slug in args.asserts
        ],
    }


def build_result(
    snapshot_row: dict[str, Any],
    baseline: dict[str, Any],
    meta: dict[str, Any],
    rows: list[dict[str, Any]],
    evidence: str,
) -> dict[str, Any]:
    """The ledger row: the snapshot taken at `begin`, the baseline's host, the worst observed status."""
    host = {
        key: baseline["host"][key]
        for key in ("sketchup", "ruby", "os", "controller", "session_id", "fixture_sha256", "rbz_sha256", "composition")
    }
    return {
        **snapshot_row,
        "captured_at": datetime.now(UTC).isoformat(),
        "evidence_kind": "observed",
        "outcome": max((row["status"] for row in rows), key=OUTCOME_RANK.__getitem__),
        "assertions": [{"status": row["status"], "observation": row["observation"]} for row in rows],
        "evidence": [evidence],
        "control": meta["control"],
        "host": {**host, "fixture_id": meta["fixture_id"]},
    }


def start_steps(folder: Path, case_id: str, fixture: Path, fixture_sha256: str) -> Path:
    """Start `steps.md` once; a rerun keeps the steps already written."""
    steps = folder / "steps.md"
    if not steps.exists():
        steps.write_text(STEPS_TEMPLATE.format(case=case_id, fixture=fixture.name, fixture_sha256=fixture_sha256))
    return steps


def provenance_warnings(root: Path, case: dict[str, Any]) -> list[str]:
    """A ledger row records HEAD and fingerprints the working tree; say when the two can disagree."""
    warnings = []
    merged = subprocess.run(
        ["git", "merge-base", "--is-ancestor", "HEAD", "origin/main"], cwd=root, capture_output=True, check=False
    )
    if merged.returncode != 0:
        warnings.append(
            "HEAD is not on origin/main: the ledger row will record a branch commit; say so in the evidence"
        )
    dirty = subprocess.run(
        ["git", "status", "--porcelain", "--", *case["paths"]], cwd=root, capture_output=True, text=True, check=False
    ).stdout.strip()
    if dirty:
        warnings.append("uncommitted changes under the case's dependencies: the row's commit will not hold them")
    return warnings


def refuse_by_case_rules(case: dict[str, Any], control: str) -> None:
    """What `finish` would refuse anyway, said before any host work."""
    if case.get("deferred"):
        raise ValueError(f"{case['id']} is deferred: it needs a scope decision and a catalog update")
    if case.get("native_control_required") and control not in ("native", "human", "combined"):
        raise ValueError(f"{case['id']} requires native interaction; --control {control} cannot record it")


def begin(args: argparse.Namespace) -> None:
    """Checks everything, builds the run in memory, then writes it: a refusal or failure leaves no file
    that would block the retry."""
    root = args.root.resolve()
    case = read_catalog(root)[args.case]
    refuse_by_case_rules(case, args.control)
    folder = args.run_dir / args.case
    for name in RUN_FILES:
        if (folder / name).exists():
            raise ValueError(f"{folder / name} exists; move the earlier run aside (for example to {args.case}-run1)")
    rbz = args.rbz or root / "dist" / "ph_composer.rbz"
    plugins = (
        args.plugins or Path.home() / f"Library/Application Support/SketchUp {args.sketchup_version}/SketchUp/Plugins"
    )
    identity = live_identity(args.sketchup_version, rbz, plugins, args.fixture)
    fixture_sha256 = hashlib.sha256(args.fixture.read_bytes()).hexdigest()
    folder.mkdir(parents=True, exist_ok=True)
    writer = folder / "writer-check.txt"
    writer.write_text(f"writer check {datetime.now(UTC).isoformat()}\n")
    recipe = build_recipe(case, identity, args, fixture_sha256, writer.read_text().strip())
    documents = {
        "recipe.json": recipe,
        "meta.json": {"fixture_id": args.fixture_id, "control": args.control},
        "baseline.json": capture(root, recipe),
        "snapshot.json": snapshot(root, case),
    }
    for name, document in documents.items():
        write_once(folder / name, document)
    steps = start_steps(folder, args.case, args.fixture, fixture_sha256)
    print(f"{args.case}: baseline captured with {len(recipe['assertions'])} assertions; record the steps in {steps}")
    for warning in provenance_warnings(root, case):
        print(f"warning: {warning}")


def finish(args: argparse.Namespace) -> None:
    """Validates the result before writing anything, so a refused `finish` can be corrected and rerun."""
    root = args.root.resolve()
    folder = args.run_dir / args.case
    baseline = json.loads((folder / "baseline.json").read_text())
    observations = json.loads((folder / "observations.json").read_text())
    observed = observe(baseline, observations)
    result = build_result(
        json.loads((folder / "snapshot.json").read_text()),
        baseline,
        json.loads((folder / "meta.json").read_text()),
        observations["assertions"],
        args.evidence,
    )
    validate_result(root, read_catalog(root), result)
    write_once(folder / "observed.json", observed)
    (folder / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    with (root / RESULTS).open("a") as stream:
        stream.write(json.dumps(result, sort_keys=True) + "\n")
    print(f"{args.case}: recorded {result['outcome']}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=ROOT)
    commands = parser.add_subparsers(dest="command", required=True)
    start = commands.add_parser("begin")
    start.add_argument("case")
    start.add_argument("--run-dir", type=Path, required=True)
    start.add_argument("--fixture", type=Path, required=True)
    start.add_argument("--fixture-id", required=True)
    start.add_argument("--control", required=True, choices=["bridge", "native", "human", "combined"])
    start.add_argument("--assert", dest="asserts", action="append", required=True)
    start.add_argument("--window", required=True, help="what showed the window and document were the right ones")
    start.add_argument("--target", required=True, help="what showed the fixture was in its expected state")
    start.add_argument(
        "--probe",
        required=True,
        help="the probe and its verified callbacks, or why none is needed (for example: no callback "
        "instrumentation; public outcomes read back in separate calls)",
    )
    start.add_argument("--controller", default="development bridge plus computer-use (Claude)")
    start.add_argument("--composition", default="normal", choices=["normal", "synthetic"])
    start.add_argument("--sketchup-version", default="2026")
    start.add_argument("--rbz", type=Path, help="default: <root>/dist/ph_composer.rbz")
    start.add_argument("--plugins", type=Path, help="default: the Plugins folder of --sketchup-version")
    end = commands.add_parser("finish")
    end.add_argument("case")
    end.add_argument("--run-dir", type=Path, required=True)
    end.add_argument("--evidence", required=True, help="the committed evidence document, repository-relative")
    args = parser.parse_args()
    {"begin": begin, "finish": finish}[args.command](args)


if __name__ == "__main__":
    try:
        main()
    except BridgeError as error:
        raise SystemExit(f"The host bridge refused: {error}") from error
    except (KeyError, TypeError, ValueError, OSError) as error:
        raise SystemExit(f"Invalid acceptance case input: {error}") from error
