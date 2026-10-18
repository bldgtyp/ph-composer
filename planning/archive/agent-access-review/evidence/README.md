# Review evidence and reproduction

DATE: 2026-10-17
BASELINE: `main` at `60982fc73af6841f0c2bc5f55136dd21cad20930`
RUNTIME: Ruby 3.2.2 selected by rbenv, matching this checkout's Makefile selection.

All probes load `tests/test_helper.rb` and the offline SketchUp stub. They do not connect to a live
SketchUp process. Synthetic setup may use private host/feature helpers to construct the fixture;
the tested client calls use the public API except for the explicitly isolated export runtime injection.
No licensed data, real model, account operation or external write is involved.

## Retained files

| File | Purpose / result |
| --- | --- |
| [inventory.rb](inventory.rb), [inventory.json](inventory.json) | Registration-derived counts, owners, description sizes and view-command list. 194 public registered operations, two participants, five separately described export task methods |
| [dispatch_probes.rb](dispatch_probes.rb), [dispatch-probes.log](dispatch-probes.log) | Main reviewer rerun of authority aliases, pending mismatch and worker-thread behavior. 4 tests / 12 assertions; **three expected failing contract assertions**, no errors |
| [spaces_probes.rb](spaces_probes.rb), [spaces-probes.log](spaces-probes.log) | Main reviewer rerun of filtered totals, root-start context refusal and 600-child response. 3 tests / 12 assertions pass against the observed behavior |
| [unmarked_face_probe.rb](unmarked_face_probe.rb), [unmarked-face-probe.log](unmarked-face-probe.log) | Correctly stamped Space, unmarked internal Face absent from reads but writable by known path. 1 test / 8 assertions pass |
| [export_revocation_probe.rb](export_revocation_probe.rb), [export-revocation-probe.log](export-revocation-probe.log) | Injected synthetic translation runtime, revoke while translating, pair still commits. 1 test / 6 assertions pass. Demonstrates current behavior, not a resolved policy violation |
| [api-export-suite.log](api-export-suite.log) | Existing focused public-client/schema/export/location tests: 57 tests / 5,100 assertions pass |
| [dispatch-original-results.log](dispatch-original-results.log) | Explicitly labeled transcription of the dispatch reviewer's original suite/probe tool outputs; not a raw execution transcript |

The dispatch probe asserts the desired contract, so its three failures document uncovered defects.
It exits nonzero at this baseline. The Spaces/revocation probes assert observed behavior to make the
reproduction stable; their passing result does not mean the behavior is correct or accepted.
These scripts are review evidence outside the normal test suite. A fix should introduce normal
regression tests and update the finding's disposition, rather than changing the evidence to conceal
the original behavior.

The 600-segment size is **238,481 bytes for the query's JSON `value`**, not total wire traffic or
an LLM token measurement. It is synthetic evidence of an unbounded child collection, not a native
performance benchmark. Discovery size is from the synthetic session. Larger labels/features/models
can change it.

## Commands

Run from the repository root. Use the selected Ruby, not macOS system Ruby:

```sh
PHC_REVIEW_RUBY="$(rbenv which ruby)"
"$PHC_REVIEW_RUBY" planning/archive/agent-access-review/evidence/inventory.rb
"$PHC_REVIEW_RUBY" planning/archive/agent-access-review/evidence/spaces_probes.rb
"$PHC_REVIEW_RUBY" planning/archive/agent-access-review/evidence/unmarked_face_probe.rb
"$PHC_REVIEW_RUBY" planning/archive/agent-access-review/evidence/dispatch_probes.rb
"$PHC_REVIEW_RUBY" planning/archive/agent-access-review/evidence/export_revocation_probe.rb
```

Run separately to observe each exit status. `inventory.rb` prints JSON followed by Minitest's empty
run footer; `inventory.json` retains only the JSON portion. No golden/reference regeneration occurs.

Existing focused suites were run during the review:

```sh
# Main reviewer: retained raw output in api-export-suite.log
"$PHC_REVIEW_RUBY" -Itests -rapi_client_test -rapi_reference_test -rexport_tasks_test \
  -rexport_preflight_test -rfile_export_test -rapproved_locations_test -rapproved_location_use_test -e ''

# Dispatch reviewer: retained tool-output transcription in dispatch-original-results.log
"$PHC_REVIEW_RUBY" -Itests -rapi_test -rapi_client_test -rsessions_test \
  -rhandler_request_test -rregistry_test -e ''

# Feature reviewer: recorded result below; no raw log retained
"$PHC_REVIEW_RUBY" -Itests -rspaces_walkthrough_test -rspaces_reads_test -rspaces_records_test \
  -rspaces_identity_test -rspaces_move_test -rspaces_context_test -rspaces_height_from_solid_test \
  -rspaces_dependency_test -rspaces_colour_by_walkthrough_test -rapi_client_test -e ''
```

| Suite | Tests | Assertions | Result / evidence |
| --- | ---: | ---: | --- |
| Main API/export/locations | 57 | 5,100 | Pass, raw log retained |
| Dispatch/API/session/registration | 102 | 619 | Pass, reviewer's retained original tool output |
| Feature Spaces scope | 82 | 575 | Pass, reviewer-reported run; key findings independently rerun as retained probes |

These suites overlap, especially `api_client_test`. Do not add them into a unique-test total or
represent them as three independent proofs of the same path. Passing checks were not rerun merely
to expand gate evidence. The main reviewer's small probe reruns validate consequential worker claims.

## Scope and checks

Inspected foundation API/registry/declaration/schema/outcome/proposal boundaries; session identity,
callers/retries/observers; Zones/Spaces reads, edits, references, context and marking; representative
Assemblies, Windows, library and Colour-by operations; export tasks, approved locations, privacy,
snapshot/Python composition; development bridge/runtime asset separation; generated docs/examples;
official client/MCP documentation. [Workflow coverage](../WORKFLOW_COVERAGE.md) records per-layer
limits. Source locations in the findings refer to this baseline.

Final documentation validation checks local Markdown targets and source line bounds, finding IDs,
evidence inventory, review prose punctuation and `git diff --check`. The result is retained in
[documentation-check.log](documentation-check.log).

No full `make ci`, fresh coverage/complexity measurement, second Ruby version, browser run, native
host automation, installed-RBZ verification, MCP installation or actual Codex/Claude Code connection
was performed. This is a review/documentation deliverable. Those gates belong to implementation and
the support claims in [FOLLOW_UP.md](../FOLLOW_UP.md), not to closing this review.
