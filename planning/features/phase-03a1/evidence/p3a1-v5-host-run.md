# P3a1 V5 host run: grants, write tools, revocation, artifacts, capture

DATE: 2026-10-18
STATUS: Recorded. Bridge setup plus the live MCP endpoint; no native gestures (computer use was declined for this session).

Host: SketchUp 26.1.188 on macOS. Build: RBZ installed from `feat/phase-03a1-p3a1-13` at 6a15867f, which carries the 07w, 08w/10w, 09 and 13 slices. Fresh process. Fixtures: two copies of the Spaces fixture, `a/house.skp` and `b/house.skp` (FX4: equal file names in different folders). Raw results are in the gitignored `_private/scratch/p3a1-v5/`.

Labelled bridge setup:

- Two tokens issued in process: "V5 bound A" (`read`, `model_write`, `export`, This Model only on `a/house.skp`) and "V5 open" (`read`, `view`, `model_write`, `export`).
- One export destination approved in process, standing in for the Libraries dialog.
- The second token revoked through the dialog's own revoke path, without the window.

Every agent call went through `POST 127.0.0.1:46110/mcp`.

| Check | Result |
| --- | --- |
| `tools/list` per token | Bound token: the read tools plus `invoke`, `outcome` and the five export tools, no `view`. Open token: the same plus `view`. |
| `discover` per token | Bound token lists only Model A's session, and its `connection` shows `model_name: house.skp` with no path. Open token lists both `house.skp` sessions. |
| Bound token on Model B | `context` answers `session.unknown`. |
| `invoke` with a key | `spaces.update` renamed a Space: committed, `sequence` 1, revision 1 to 2, 67 ms. The same key and request replayed the first outcome at the same revision. The same key with other values answered `request.sequence_conflict`. `outcome` by key answered the first outcome with `sequence` 1. |
| Second token, stale | Its `invoke` at the old revision answered `revision.stale` with `sequence` 1 of its own. |
| Native Undo and Redo | On Model B (active), the open token's rename committed. One `Sketchup.undo` restored the old name and `Sketchup.redo` the new one. |
| Export ownership and artifacts | The bound token's `start_export` to the approved destination reached `export.complete`. `artifacts.hbjson.path` was the destination, its SHA-256 matched the file read with the client's own tools (54,067 bytes, 2 rooms parsed). The open token's `export_status` for that task answered `task.foreign` with no path, and its `latest_export` answered null. |
| Revoke during an export | The open token started a replacing export, and the token was revoked while the task was queued. The task finished `refused`, `export.revoked`, effect `none`. The earlier pair's hash was unchanged. The revoked token's next request got HTTP 401 at the ingress. |
| `write_image` with SketchUp frontmost | Written in 154 ms, 2028 x 963 PNG (27,990 bytes). The camera and selection were unchanged, and the image shows the Model's geometry. |

Not observed:

- The Agent Access window driven natively, including the copy button and the acknowledgment notice.
- Edit menu labels.
- `write_image` with the window behind another application, hidden or minimized, or with a modal open. These need window control, which was declined.
- Both CLIs (stage 12).
