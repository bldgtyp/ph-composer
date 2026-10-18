# Phase 3a1 cleanup ledger

DATE: 2026-10-17
STATUS: Closed 2026-10-18; dispositions in [the stage 16 receipt](evidence/p3a1-16-integrated-acceptance.md).
ISSUE: none (local planning draft)

The [review cleanup inventory](../../code-review/CLEANUP.md) supplies the evidence. Remove only
verified superseded code/docs in the owning stage; source searches are followed by consumer and
round-trip checks. The phase does not authorize deletion of public interfaces by assumption.

| ID | Owner | Replacement/removal work | Preservation and verification |
| --- | --- | --- | --- |
| CL01 | 01/02 | Remove shallow authority-copy assumptions and duplicated grant-description maps when replaced | Freeze inputs/outputs and verify old caller/sequence/session behavior; keep authority one place |
| CL02 | 03 | Rewrite `tests/spaces_reads_test.rb` and the walkthrough calls to the reshaped `spaces.list`; regenerate the reference with the changelog line | Keep `spaces.all` byte-identical for the panel snapshot section; no other `.list` consumer exists (audit 2026-10-17) |
| CL03 | 04/05 | Split the Spaces walkthrough into labelled native fixture setup and a public-only client segment that uses `candidate_faces.list` and the foundation context commands | Keep fixture construction helpers and native tool workflows; test no private call or path assignment after the client begins |
| CL04 | 05 | Reconcile stale Spaces routing in `tools/hostkit/.index.md` and Phase 2-only agent feature inventory | Preserve historical archived evidence; update current docs only |
| CL05 | 06/08 | No spike server is written; the 06 receipt lists the rejected alternatives so none is reopened. `LoopbackHttp` is extended, not forked; the asset server's token is never accepted by the ingress | The development bridge stays out of the RBZ (`make rbz-check`); verify one HTTP reader serves both servers and no `eval` route exists in `src/` |
| CL06 | 07/09 | The token store is the one capability authority for external callers; admission-only assumptions leave the export task path; the dialog's consent copy matches the acknowledged boundary (D06) | No two authorities; existing approved locations, provider setup and completed user files untouched |
| CL07 | 10 | No hand-kept operation map, schema copy or per-operation tool exists; the verb table is the allowlist | FX7 through the socket proves the generic surface; participants and `eval` are unreachable by construction |
| CL08 | 11 | After acceptance, remove the test entries from the real client configurations with the documented commands and revoke the test tokens; the receipt marks the review's companion recommendation superseded | Snapshot each client configuration before the run and compare after; preserve unrelated MCP servers, skills and files |
| CL09 | 12 | Replace unavailable-client placeholders and private-repo-dependent guide steps | Keep development architecture/native skills separate from distributed operating skill; test installed-only recipes |
| CL10 | 13 | Replace the quickstart's "read the approved files" with the disclosed paths and the hash comparison; no chunk, handle or inline-byte code exists to remove | Keep compact task status and the existing pair journal and recovery; a replaced destination never deletes a user's earlier output |
| CL11 | 14/15 | No temporary capture route ships; every capture states `overlays: "not_included"` | Retain the development `shot` utility with its zoom as development tooling; never present a capture as a complete viewport |
| CL12 | 16 | Reconcile review recommendations, phase receipts and active indexes; archive completed owning packet when delivered | Review findings get evidence-backed dispositions; unresolved cases remain visible; no old evidence rewrite |

## Components deliberately retained

The eval bridge remains development-only and excluded from the RBZ/end-user installation. The
runtime asset server retains its separate token and pinned-asset role and shares only `LoopbackHttp`
with the ingress. Native tools/menus and
panel projections remain complete hand-authoring clients. Internal participants stay available to
feature composition and are excluded from public callable transport tools.

No speculative dynamic feature loader, framework split, provider account system, new LLM backend
or generic filesystem/CAD execution surface is introduced. Existing archived refactors are not
reopened. Third-party payload/runtime notices and dependency-age protections remain intact.

## Closure evidence

For each CL row record actual removed/replaced paths and consumers, compatibility/deprecation
decision, affected checks and remaining exception. A search returning zero references is supporting
evidence, not a substitute for exercising a public example or persisted-data round trip. Final
cleanup leaves no installed test token or client config entry outside what Ed keeps for his own use. Planning-only closure currently records all rows as pending.
