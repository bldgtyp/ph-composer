# P0-F runtime and export contracts: evidence

DATE: 2026-09-18
STATUS: Implemented on branch and host-verified on SketchUp 26.1.188, except the native destination
dialog of the empty Export; see "Limits".
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; origin exists, issue not created)

## Scope and commits

Branch `phase-zero-foundation`, source baseline `f358ebf`. The pinned Pyodide payload and its
manifest, the loopback asset server, the typed translation package shell with C6 section ordering,
export contributors with the composed privacy guard, report and artifact pair, the empty Export
workflow, and the runtime page with its host and development probe. No PHX, no real translation
section, no HBJSON output and no user artifact.

| Commit | Unit |
| --- | --- |
| `87d0326` | Runtime manifest, `tools/runtime/vendor.py`, loopback asset server, Pyodide 0.24.1 core, runtime and installed-size checks in `make ci` |
| `0a79e47` | `ph_composer_translation`: contract readers, sections, coordinator, result, exporters, lazy stack seam; synthetic A/B/C sections |
| `b508bb1` | Registry `export_contributor`, record reader, collection, privacy, hygiene, report, artifact pair; the example feature's contributors and Python sections |
| `bc8166c` | Empty Export: `export.start` / `export.result`, destination dialog, no output |
| `2b14456` | Runtime page `html/runtime/`, `runtime/runtime_host.rb`, `tools/hostkit/runtime_probe.rb`, `tools/runtime/browser_check.py` |
| `d2965e8` | Review fixes |
| `f74e16f` | Host fix: no favicon request outside the token path |

## Payload

Pyodide 0.24.1 core (CPython 3.11.3), five files copied from the frozen predecessor tree and
byte-compared with the upstream release: `pyodide-core-0.24.1.tar.bz2`, 4,604,614 bytes,
SHA-256 `7470bde4…0e143443`, matching the frozen manifest.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `pyodide.js` | 17,417 | `b67a1e4e…1107da` |
| `pyodide.asm.js` | 1,157,891 | `71250bb1…0d0c4f` |
| `pyodide.asm.wasm` | 8,995,509 | `f7141d49…9b9da5` |
| `pyodide-lock.json` | 84,412 | `e313a21e…21380f` |
| `python_stdlib.zip` | 8,882,369 | `573b362d…5ec9ca` |

No wheels ship. The predecessor's eight honeybee-family pins are omitted from the default manifest
by `PACKAGE_PINS = ()` and stay recorded in the frozen manifest and SOURCE_INVENTORY; their versions
were not changed. The manifest lists 38 assets (`html/`, `python/`, `vendor/pyodide/`) and
19,308,432 bytes with itself; the installed extension is 19,491,177 bytes, under the 22,000,000-byte
target and the 24,000,000-byte ceiling. The RBZ is 5,289,408 bytes.

Licenses: Pyodide's repository `LICENSE` is MPL-2.0 and the release's `package.json` declares
Apache-2.0; CPython is PSF-2.0. Both Pyodide values are recorded in the manifest and in
`vendor/THIRD_PARTY_NOTICES.md` until the licensing gate settles the notice.

## What was built, against the plan

1. **Asset serving and loader.** `runtime/asset_server.rb` serves only manifest keys under a
   per-server token with the isolation headers; a missing or altered asset is found by SHA-256 when
   the server is built and refused with 500, and a size change after that is refused per request.
   The token authorizes asset loading only and is documented as distinct from agent grants.
   `html/runtime/` is its own page, outside the panel's module graph: the panel never loads
   Pyodide. It boots in one flight, writes the translation package from the manifest's list and
   imports it.
2. **Package shell.** `python/ph_composer_translation/` imports without honeybee, ladybug or PHX;
   `stack.load` is the only import site and names a missing package. No predecessor section.
3. **Typed dependencies (C6).** Requirements name a section and an object type; ordering is
   topological with id order for unrelated sections. Missing, mistyped, duplicate and cyclic
   requirements are structural (`planning`); an unreadable document, section, version or record
   id is `payload.contract` or `section.version_unsupported` (`reading`); a bad record costs that
   object (`object.unavailable`) and its dependents (`dependency.unavailable`), with no substitute.
   `publishable` is false when a finding blocks export, however much else translated.
4. **Privacy.** The allowlist is the shell's fields plus each contributor's `result` declaration,
   composed per check. Undeclared fields, objects hidden in value slots, `user_data`,
   `extension_data` and local paths are refused (`export.privacy_undeclared`). The report embeds
   the result document unchanged.
5. **Artifact pair and exporters.** The pair stages, journals, verifies and renames, and restores
   the prior pair on any failure; exporters are Python registrations that receive the HBJSON text
   and a copy of explicit options only.
6. **Empty Export.** The Export pane asks the host through `export.start`; the host opens the
   destination dialog outside any Model operation. Cancel answers `export.cancelled`; accepting
   answers `export.unavailable` and touches nothing.
7. **Probe and teardown.** `RuntimeHost` binds to a session id and holds no Model or session
   object; `stop` reports what was live and what still is, and releases the server even when the
   page or window fails. `tools/hostkit/runtime_probe.rb` drives it on the host.

`task_runner.rb` and the export run's guard, reporter and workflow defer to the first real export
run; see SOURCE_INVENTORY.

## Contributor trace (A08, export portion)

The development example adds `example.foundation.export.definitions` and
`example.foundation.export.parts` with two `export_contributor` declarations in its own `install`,
and the two matching Python sections in `tools/examples/foundation/example_translation.py`. No file
in `shell/`, `session/`, `core/`, `export/` or `python/` names it. One hand-reviewed pair,
`tests/fixtures/foundation/{extraction,result}.json`, is checked by both suites: the Ruby collection
of a seeded Model equals the extraction (`tests/export_test.rb`), the Python sections translate it
to the result (`tests/python/test_example_translation.py`), and the Ruby report embeds that result
unchanged after the composed privacy check. The Sill's `user_data` is left out with an
`export.metadata_omitted` finding; its review extension exports only `review_status`; an envelope of
unknown or unexported required relevance blocks the collection.

## Gate results

| Command | Result |
| --- | --- |
| `make ci` (Ruby 3.2.2) | exit 0: rubocop 100 files, eslint and ruff clean; Ruby 220 runs, 1,023 assertions; JavaScript 112 tests; pytest 77; panel manifest 17 modules, 2 pages; runtime 38 assets, 19,308,432 bytes; pins agree (0 wheels); hostkit 9 runs; mypy 24 files; RBZ 94 files, 19,491,177 bytes installed |
| Ruby 2.7.2 suite | 220 runs, 0 failures |
| `make coverage` | Ruby 96.6% of 2,319 lines (93); JavaScript 97.5% of 1,792 lines (94); Python 100% of 277 statements (92) |
| `make ui-checks` | Pass in Chrome, including the Export pane |
| `make runtime-browser-check` (Chromium 88.0.4324.0) | PASS at `f74e16f`: cross-origin isolated, two probes on one boot, no stack module loaded, cold boot 1,975 ms, warm round trip 0.5 to 1.7 ms (at `2b14456`: 2,026 ms, of which Pyodide 1,943 and translation 74) |

Negative cases required by the plan, offline: tampered asset (same size and changed size), missing
asset, unlisted path, traversal, wrong token, wrong method, oversized header, client limit, partial
request (`asset_server_test.rb`, `runtime_manifest_test.rb`, `runtime_host_test.rb`,
`tests/python/test_runtime_vendor.py`); missing, mistyped, duplicate and cyclic sections, malformed
document, section, version and record ids, one bad record, an orphaned reference and an undeclared
requirement (`test_coordinator.py`); refused asset, script load failure, boot timeout, translation
failure and stop during boot on the runtime page (`runtime_page_test.js`); injected stage, rename and
crash failures on the artifact pair (`artifact_pair_test.rb`).

## Host evidence

SketchUp 26.1.188, macOS, Ruby 3.2.2, fresh processes through the bridge on a copy of the stock
Simple template (SHA-256 `2ae1418d…57121063`), with the RBZ built from the commit under test. The
scratch driver added a page report callback, recorded Export outcomes, and answered `UI.savepanel`
with a scripted value instead of opening the native dialog, which would block the bridge. Captures
are in ignored `_private/host/p0f/`.

1. **Panel ready**: 122 ms from `Panel.show` to the page's `panel.ready` (target 1,000, ceiling 2,000).
2. **Export cancel**: clicking the real pane's button reached `UI.savepanel("Export HBJSON", …,
   "p0f-runtime.hbjson")`; a nil answer gave `cancelled / export.cancelled / none`, shown under the
   button.
3. **Export accept**: answering with an existing `existing.hbjson` beside its report and an
   unrelated file gave `refused / export.unavailable / none`. The folder's names, sizes, SHA-256s
   and modification times were identical before and after; no `.hbjson` appeared beside the Model;
   no runtime host or asset server existed, the process listened on the bridge's two ports only,
   and the thread count stayed at 3.
4. **Runtime probe**: two probes on one boot, Python 3.11.3, no stack module loaded, cold boot
   1,275 ms (Pyodide 1,055, translation 123; ceiling 6,000), warm round trip 0.3 to 0.4 ms (ceiling
   100), worst pump tick 7.1 ms (ceiling 50), 18 requests. One request was refused 403: the
   browser's favicon request outside the token path, removed in `f74e16f`.
5. **Teardown**: before `timer 1, acceptor 1, socket 1, dialog 1`; after all zero, window closed,
   the runtime port gone from `lsof`, 3 threads, no running runtime host or server.
6. **Cancel during boot**: stopped with two clients mid-transfer and no result yet; after all zero,
   and no result arrived later.
7. **Close and reopen**: the unmodified Model closed with `Model#close(true)` and reopened with
   `Sketchup.open_file`: a new session id; after `GC.start` no `ModelSession` for the old id
   remained, and the one stopped runtime host held only the old id string. A probe on the reopened
   Model passed (cold 1,300 ms, warm 0.3 to 0.5 ms) and released everything.
8. **Fresh process at `f74e16f`**: probe PASS, cold 1,295 ms, warm 0.3 to 0.5 ms, 17 requests,
   no refusal; teardown released everything.
9. **Tampered install**: one appended line in the installed `html/runtime/runtime.js` made
   `RuntimeHost#start` refuse with `RuntimeManifest::Invalid` naming that file; nothing started.
   The RBZ was reinstalled afterwards.

## Review

One independent high-assurance review (single agent) of `80a54d5..2b14456` against the architecture
rubric, the P0-F plan and C5/C6. It reproduced eight findings, none high (three medium, one low-medium,
four low); all are fixed with tests in `d2965e8`:

1. Medium: a runtime whose page or window raised during `stop` kept its server alive and could not
   be stopped again. `stop` now always stops the server.
2. Medium: the stop report could not see an open window. It now reads the window itself.
3. Medium: a privacy value slot accepted a nested object. Value slots now hold scalars or lists of
   scalars.
4. Low-medium: one record id twice in a section was not refused. It is `payload.contract`.
5. Low: artifacts were written owner-only. They take ordinary permissions.
6. Low: a non-object contributor `result` crashed registration. It is a diagnostic.
7. Low: the local-path check missed `C:/`, UNC, `~/` and paths after punctuation. Covered.
8. Low: a translation failure after boot was labelled a boot failure. It is
   `runtime.translation_failed`.

Also taken: the acceptor holds its own listening socket, and a runtime starts once. Left as
follow-ups: hashing each served body per request (the startup SHA-256 is the check that matters;
anyone who can change the folder can change the Ruby), where the HBJSON itself is guarded before
the first real exporter, and escaping of contributor report HTML, which `ReportHtml` provides but
does not enforce.

## Limits

- The native destination dialog of the empty Export was not opened on the host: it is modal and
  blocks the bridge, and driving it needs SketchUp in front of other work. The run replaced it with
  a scripted answer; everything after the dialog ran in the host. A native open, cancel and accept
  remains for P0-G, with Ed.
- `crossOriginIsolated` was checked in Chromium 88, not recorded in the host; Pyodide booted in the
  host without it being asserted.
- No SketchUp 2023 host run; Chromium 88 is checked in the browser check.
- Only the result document passes the privacy guard; the extraction is internal and there is no
  HBJSON yet.
- The Export pane repeats "nothing written" in its description and its answer; a copy review
  belongs with the first exporter. The pane was reviewed against the architecture rubric only, not
  the UI-polish rubric.

## Acceptance

- A08 export portion: passed (contributor trace above).
- A12 manifest enforcement, runtime probe, cancellation and teardown, lazy imports: passed offline,
  in Chromium 88 and on the host; P0-G re-runs at final acceptance.
- A13: passed offline.
- A14: passed offline.
- A15: passed offline and on the host with the destination dialog scripted; the native dialog
  step is pending for P0-G.

Next stage: P0-G, integrated acceptance, after the P0-B investigations are scheduled.
