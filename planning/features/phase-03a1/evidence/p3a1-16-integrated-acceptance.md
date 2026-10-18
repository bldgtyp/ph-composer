# P3a1-16 integrated acceptance

DATE: 2026-10-18
STATUS: Recorded. Both exact clients ran the integrated scenario against installed builds with the panel closed and no checkout, bridge or eval available to them. One host bug was found and fixed ([#243](https://github.com/bldgtyp/ph-composer/pull/243)); one product gap was filed ([#244](https://github.com/bldgtyp/ph-composer/issues/244)).

## Setup

**Host.** SketchUp 26.1.188 on macOS 26 (Darwin 25.6.0), Ruby 3.2 inside SketchUp, each run in a fresh process launched by the development bridge.

**Builds.**
- Runs C16 and the native checks: the RBZ from `main` at 0558f094 (every 03a1 stage merged).
- Runs C16b, C16c, FX3, lost reply and restart: the RBZ from `fix/phase-03a1-root-inactive-model` at d4893fb0, SHA-256 `5303dc14ebb7215c0eee4d474bd1f59ea92449fb84303ff68fa320beab795164`.

**Clients.**

| Client | Version | How it ran | Connection |
| --- | --- | --- | --- |
| Claude Code | 2.1.300 | `claude -p` from a scratch folder, `--strict-mcp-config`, tools limited to the ph-composer tools, Read and `shasum` | `--mcp-config`, type `http`, bearer from an environment variable |
| Codex | 0.163.0 | `codex exec --skip-git-repo-check -m gpt-6.1-sol` from a scratch folder | `-c mcp_servers.<name>.url` and `bearer_token_env_var` |

Both received the scenario followed by `docs/AGENT_GUIDE.md`. MCP protocol revisions as measured in [P3a1-06](p3a1-06-connection-design.md): Claude Code 2025-11-25, Codex 2025-06-18.

**Fixture (FX1 plus FX4).** `house2.skp`, a copy of the Spaces fixture: Zones west and east with authored Assemblies, classified envelope Faces, one Window Type and Unit, Spaces 101 to 103 and 201, and three recordless 1 m floor Faces loose in Zone west. A second copy with the same basename at `other/house2.skp` is open beside it. Bridge setup only: tokens, the approved destination "C16 exports", the "Group 5 synthetic" library folder, and the mid-run user actions below. Raw transcripts, prompts and probe output are in the gitignored `_private/scratch/p3a1-16/` and the session scratchpad.

## Client scenario C16

Tokens per client: `full` (read, view, model_write, setup, export) and `bound` (read, model_write, bound to `house2.skp` by path). A watcher acted for the user when the client dropped a marker file.

| Step | Claude Code | Codex |
| --- | --- | --- |
| Grants, wrong Model | `full` sees both sessions; `bound` lists one, its `context` on the other answers `session.unknown`; no export, view or setup tools on `bound` | Same: `session.unknown`, and no `start_export` on `bound` |
| Concurrent user edit | User renamed 102 at revision 2 to 3; the agent's rename of 101 at revision 2 refused `revision.stale`; re-read, committed at 3 to 4, read back "Agent C16" | Same at revisions 3 and 4: `revision.stale`, nothing written, recovered, read back |
| Space from loose Faces | Opened Zone west, previewed, created Space 104 from the three Faces; read back 1 Volume, 3 m², 3 Floor Segments | Same, as its own Space |
| Second Volume mid-run | User drew a 1 m outline inside the open Space; found through `candidate_faces.list`, made a Volume, height 2.7 m, supply 60 m³/h, read back | Same |
| Root and move | `context.root` answered `completed`, `changed: true` five times while the path stayed on Zone west; move refused `space.context_open`. Its session was not the Model SketchUp showed. **Bug**, below | Its session was the shown Model: root completed, `move_to_zone` east committed; read back in Zone east, 2 Volumes (3 m² at 3.0 m, 1 m² at 2.7 m), 4 m², supply 60 m³/h |
| Assembly | Face `fac_3a0b4e685471`, Outdoors wall, "Reference wall" to "Reference partition", read back with the expected condition-mismatch finding | Same Face after Claude Code's run was restored from the fixture; assigned its existing "Reference wall", answered `ok` "Nothing to change", read back |
| Library copy | Loaded "Group 5 synthetic" materials, `in_file` both rows "create", copied "Group 5 wool", read back from the Model's materials (0.035 W/mK, source kind library) | Copied "Group 5 board", read back (0.03 W/mK) |
| Export | `export.complete` at revision 10; HBJSON at the disclosed path, SHA-256 matched, 2 rooms | `export.complete`; SHA-256 `3b5215cc…87ee2` matched, 2 rooms |
| Cost | $10.78, 105 turns, 12.9 min | 100,918 tokens |

**How each client chose operations.** Neither guessed a name. Both described each operation before its first use; Claude Code described the whole plan up front (16 describes), Codex described as it went.

**The bug.** SketchUp ignores `active_path = nil` or `[]` and `close_active` on a Model that is not the active document, while a non-empty path is honored. `EditContext` reported a change that did not happen and protected the open Volume again. The fix refuses that move with `session.inactive` before any boundary runs, declared on every navigation command; recorded in `context/SKETCHUP_HOST_BEHAVIOR.md`.

## Client scenario C16b and C16c (fix build)

Codex, one token with read, view, model_write and capture; `other/house2.skp` shown, `house2.skp` not.

| Step | Result |
| --- | --- |
| Navigation on a Model not shown | Opened Zone east (honored), then `context.root` answered `refused`, `session.inactive`; context afterwards: revision 1, edit path `[48912]`, nothing moved. The fix observed on the host through a client |
| Capture | `view.capture` of the shown Model at 800 by 600; the PNG read with its shell, 10,899 bytes, SHA-256 matched, `overlays: not_included` |
| Window placement | Declined: the Face read gives area but no extent, so it could not keep the opening inside the Face. Filed as [#244](https://github.com/bldgtyp/ph-composer/issues/244) |
| Revoke mid-run | After the watcher revoked its token (the only live one), the next `discover` failed with a transport error: the listener stops when no token is live, so the client sees a closed connection rather than a refusal. `docs/AGENT_GUIDE.md` now says so |
| Cost | 65,804 tokens |

**C16c, Window and capture in both clients.** Each client had a read, view, model_write and capture token, and was told what no read gives: every wall is at least 4 m wide and 3 m high. Each placed the existing Type with anchor `sill_left` at 1.0 m right and 0.9 m up on an unhosted exterior wall of Zone east, after a preview, and read the Units back.

| Step | Claude Code | Codex |
| --- | --- | --- |
| Window | `wun_b25c445de740` on `fac_262169abbd82`, revision 1 to 2, one Undo step; read back host, Type and anchor | `wun_d0c8705617c0` on `fac_8ae09fc61d15`, revision 3; read back host, Type and anchor |
| Read-back limit | Both noted the Units read carries no offsets, so the position is confirmed only by the absence of a `window.overhang` refusal; added to [#244](https://github.com/bldgtyp/ph-composer/issues/244) | Same |
| Capture | 800 by 600 PNG of the shown Model read with Read, `file` and `shasum`: 10,899 bytes, SHA-256 `365b271e…2d634` matched, `overlays: not_included` | Done in C16b |
| Cost | $2.47, 20 turns, 87 s | 35,320 tokens |

Codex read its own installed workflow notes with its shell before starting, in both C16b and C16c; neither client read the source checkout.

## Lost reply and restart

Probed through the live endpoint with a model_write token (`_private/scratch/p3a1-16/probe/`), fix build, `house2.skp` not shown.

- **Lost reply.** An `invoke` renaming Space 103 with `idempotency_key` `c16-lost-reply-1` at revision 3 was sent on a raw socket that closed before reading the reply. `outcome` by that key then answered the committed outcome, sequence 2. Replaying the same `invoke` answered the same outcome and sequence, and the revision stayed at 4: one change, read back "Hall lost reply" (`lost_reply.json`).
- **Restart.** SketchUp was quit and relaunched on the same file. The listener started again for the still-live token, `discover` showed one new session at revision 1, and both `context` and `outcome` on the old session id refused `session.unknown` (`restart.json`). An old export task is reached only through its session, so it is refused the same way.

## Native observations (computer use)

Observed with full-screen control on the C16 host, screenshots kept in the session transcript only.

- **Undo labels.** Opening a Group and returning to the root each show "Undo Open" in the Edit menu. An agent edit shows "Undo Edit Space", one named step. Native Cmd+Z after leaving an unprotected Volume reopened it while it stayed protected, reproducing [#231](https://github.com/bldgtyp/ph-composer/issues/231); Cmd+Shift+Z returned to the root.
- **Agent Access window by hand.** New token with This Model only showed "Reaches house.skp and no other Model"; the token was shown once; Copy put the live token on the clipboard (matched by digest, then cleared); Revoke asked to confirm and showed its acknowledgment. One defect: each capability checkbox renders above its label ([#242](https://github.com/bldgtyp/ph-composer/issues/242)).
- **Capture window states** ([#239](https://github.com/bldgtyp/ph-composer/issues/239)), `_private/scratch/p3a1-16/capture_rows.json`:

| State | SHA-256 (first 12) | Bytes | Time |
| --- | --- | --- | --- |
| Frontmost | 90a0f9bd0613 | 32,245 | 244 ms |
| Behind another app | 90a0f9bd0613 | 32,245 | 239 ms |
| Hidden | 90a0f9bd0613 | 32,245 | 238 ms |
| Minimized | 90a0f9bd0613 | 32,245 | 239 ms |
| Minimized, camera moved | 3a9238f02d8f | 14,168 | 187 ms |
| Frontmost, same moved camera | 3a9238f02d8f | 14,168 | 183 ms |

  `write_image` renders the current view in every window state. Under a native modal dialog the capture never runs and the call answers busy or times out, as stage 08 designed.

- **Save and reopen.** After both C16 runs, Cmd+S saved `house2.skp` (`modified?` false). A fresh SketchUp process opened it, and a read-back of every Space (number, name, Zone path, Volumes and heights, airflows) and every material equalled the pre-save snapshot exactly; the only difference was the `modified` flag (`presave.json`, `reopen.json`).

## FX3 response stress

Built on the host in a scratch Model through the bridge (`_private/scratch/p3a1-16/fx3/build.rb`): 300 Spaces with 60-character Unicode names in one Zone, one Space whose Volume holds 600 Floor Segments, 20 stray Floor Segments, and 30 unrelated Zones with 85-character Unicode names. Not built: large optional metadata on records. Measured through the live endpoint with a read token, panel closed (`measure2.json`):

| Read | Pages | Largest page | Slowest page | Walk total |
| --- | --- | --- | --- | --- |
| `discover` index | 1 | 11,446 B | 89 ms | |
| `discover` per owner (largest: windows) | 1 each | 19,055 B | 71 ms | |
| `describe spaces.list` | 1 | 8,002 B | 65 ms | |
| `spaces.list` | 15 (301 rows) | 17,176 B | 206 ms | 2.6 s |
| `spaces.list`, `fields: [values]` | 6 | 17,182 B | 179 ms | 1.0 s |
| `spaces.list`, `limit: 1` | 301 | 2,076 B | 292 ms | 51.6 s |
| `spaces.floor_segments.list`, the 600-Segment Space | 15 (600 rows) | 17,068 B | 283 ms | 2.7 s |
| `spaces.findings.list` | 1 (20 rows) | 4,269 B | 176 ms | |

Every reply stays under the 24 KB budget; the Model was unmodified at revision 2 afterwards. The `limit: 1` walk shows the per-call floor of about 170 ms on this Model; a client should page with the default limit.

## Finding disposition

| Finding | Disposition | Evidence |
| --- | --- | --- |
| A01 | Closed: both CLIs connect from the dialog's snippets and read (M1) and write (M2) | 08, 10, 11 receipts; C16 above |
| A02 | Closed: named tokens, capabilities, revoke acknowledged at the pump and before an export commits | 07, 09; C16b revoke |
| A03 | Closed: main-thread executor, busy answer under modal, activation and close | 06, 08 receipts |
| A04, A05 | Closed in 01 | #222 |
| A06 | Closed in 03 | #228 |
| A07 | Closed: bounded reads under the measured caps, ingress refuses over budget | 03, 08; FX3 above |
| A08 | Closed: root start, exit and move public-only through the foundation commands, refusing on a Model not shown | 05; C16 Codex; C16b; #243 |
| A09 | Closed: loose candidates discovered, authored and read back by both clients | 04, 05; C16 |
| A10 | Closed in 02 and 04 | #227, #230 |
| A11 | Closed: paths and hashes disclosed to the producing caller, read and verified by both clients | 13; C16 exports |
| A12 | Closed: `context` with camera and view generation; geometry-only capture under the `capture` grant read from its disclosed path and hash-checked by both CLIs; window states measured ([#239](https://github.com/bldgtyp/ph-composer/issues/239) open for Ed's call on dropping `window_state`) | 14, 15; C16b, C16c |
| A13 | Closed with one deferral: guide and connection instructions current and exercised by both clients; Window placement position needs a Face extent read ([#244](https://github.com/bldgtyp/ph-composer/issues/244)) | 12; C16, C16c |
| A14 | Closed: D06 accepted, acknowledged revocation and the pre-commit recheck tested | 09; C16b |

## Cleanup rows

| Row | Disposition |
| --- | --- |
| CL01 to CL07, CL09 to CL11 | Closed in their owning stages; see each STATUS row |
| CL08 | Closed: every test token revoked after each run; the client configurations were never edited (both runs passed configuration on the command line), so no entry remains to remove |
| CL12 | This receipt, the STATUS update and the archive |

Remaining test state on this machine: eight bridge-approved scratch destinations from earlier stages stay in the Libraries dialog; Ed may remove them there.
