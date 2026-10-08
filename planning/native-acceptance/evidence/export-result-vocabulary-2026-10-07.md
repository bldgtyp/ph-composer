# Export result vocabulary native acceptance

DATE: 2026-10-07
CASE: GH41
STATUS: Pass, current host

Normal installed composition in SketchUp 26.1.188, Ruby 3.2.2, macOS. Native macOS controls
selected Export, Choose destination and Save. The native pane reported HBJSON and Export report
created, 2 Rooms, 12 Faces and 1 Surface pair. Last-export messages named Assembly
"Two wool thicknesses", Layer 1, and Material "Synthetic defaults" in Assembly "Default mass".
No `mat_` IDs or internal validation sentence appeared. The actual runtime result agrees.

The saved synthetic clone gained two unused construction definitions from public fixtures.
Its incomplete Window was removed through the public guarded action before final baseline capture;
readiness then passed. An earlier diagnostic task was blocked by that Window and is not acceptance.
Native export used its checked stale-adjacency repair; the resulting synthetic Model was saved clean
and the panel closed. No production Model, preferences or licensed corpus was changed.

- Source checkpoint: `20e6358`; manifest refreshed. Package comparison matches all 390 files.
- Installed RBZ SHA256: `2d48fbed4f770016ccdb59291a9ec6493605ec4dcc8b87c7ac7dba3d8d70a440`.
- Fixture baseline SHA256: `24560b9ff5d39ee5cd3bd0bcb92ebe63edcef6ae083fce04ef53db41f81acab8`.
- Session: `202ba79a-2455-4fe5-bd12-7f8431f74fa9`.
- Immutable run: `d458907a-c8c3-416a-80db-2ebdd0771d1f`.
- Native result pixels SHA256: `775d2d7bc8dde75b31625060c5374485ac4d705a8cf627b8f6bfa1a9bd5be016`.
- Private evidence: `_private/host/issue-sweep/issue41/`, including final recipe/baseline,
  observation receipt, normal runtime result, helper/output hashes, package match and clean-state readback.

This proves the issue's current-host result display. Release/platform acceptance remains separate.
