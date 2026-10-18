# P3a1-12 two-client run

DATE: 2026-10-18
STATUS: Recorded. Two exact clients ran one scripted semantic scenario against an installed build, with the panel closed and no checkout, bridge or eval available to them.

## Setup

**Host.** SketchUp 26.1.188 on macOS, in a fresh process. The RBZ was installed from `feat/phase-03a1-p3a1-13` at 90dad383, which carries every merged 03a1 stage plus 13.

**Fixture.** A copy of the Spaces fixture, `house.skp`. It has four Spaces in two Zones, and its export is publishable.

**Labelled bridge setup.**
- Two tokens: "C12 Claude Code" and "C12 Codex", each with `read`, `view`, `model_write` and `export`.
- One approved export destination, "C12 exports", standing in for the Libraries dialog.

**Clients.**

| Client | Version | How it ran | Connection | Tools allowed |
| --- | --- | --- | --- | --- |
| Claude Code | 2.1.300 | `claude -p` from a scratch folder | `--mcp-config` (type `http`, bearer from `PHC_TOKEN`) | `--strict-mcp-config`; the ph-composer tools, Read, and `shasum` |
| Codex | 0.163.0 | `codex exec --skip-git-repo-check` with model gpt-6.1-sol | `-c mcp_servers.ph-composer.url` and `bearer_token_env_var` | Codex defaults |

**Prompt.** Both received the same prompt: the scenario followed by `docs/AGENT_GUIDE.md` from this branch. Raw transcripts are in the gitignored `_private/scratch/p3a1-12/runs/`.

**The scenario:**
1. Discover and read `context`.
2. List the Spaces.
3. Rename one Space with an `idempotency_key` and read it back.
4. Replay the same invoke.
5. Rename at the stale revision, then recover.
6. Export to an approved destination, poll it, then read and hash-check the disclosed HBJSON.
7. Log every call.

## Results

| Step | Claude Code | Codex |
| --- | --- | --- |
| Discover and context | One session, `house.skp`, revision 1, idle, Select tool active | Same; it also called `describe` on the context read first |
| Spaces | 101 Living 12 m², 103 Hall 6 m², 102 Bath 4 m², 201 Loft 12 m², with their Zones | Read the same list, then renamed 103 |
| Rename with key | `committed`, sequence 1, revision 1 to 2, read back | `committed`, sequence 1, revision 3 to 4, read back |
| Replay, same key | First outcome returned, sequence 1, revision unchanged | First outcome returned, sequence 1, same proposal digest |
| Stale rename | `revision.stale`, sequence 2, nothing written | `revision.stale`, sequence 2, effect `none` |
| Recovery | Read again, then committed at sequence 3 and read back | Read again, then committed at sequence 3 and read back |
| Export | `export.complete` at the first poll | `export.complete` after `queued` then `translating` |
| Disclosed HBJSON | Read with Read and `shasum`; SHA-256 matched; 2 rooms (Zones west and east) | Read with its shell; SHA-256 matched; 54,076 bytes; 2 rooms |
| Cost | $1.60, 21 turns | 46,651 tokens |

**How each client chose operations.** Neither guessed an operation name. Claude Code called `describe` for the list, update and location reads before using them. Codex called `describe` for those and for each export tool. Both treated the advisory export findings as non-blocking, as the guide says.

**Native Undo and Redo.** After both runs, one `Sketchup.undo` reverted only Codex's last rename ("Codex Check 2" back to "Codex Check"), and `Sketchup.redo` restored it. The test tokens were then revoked, and the listener stopped.

## Not covered

- A concurrent user edit, a wrong Model or grant, a lost reply with reconnection, and restart.
  - The write tools' offline tests and the [V5 run](p3a1-v5-host-run.md) cover replay, stale refusal and revoke at the API level.
  - These scenarios were not run through a client conversation.
- FX3-scale discovery and schema cost.
- Spaces authoring from loose Faces, Assembly assignment, Window placement and library copy.
  - Each is in the guide, and the guide test checks its operation names.
  - None was run by a client here.
- Edit menu labels: computer use was declined for this session.
