# Findings register

DATE: 2026-10-13
STATUS: Review complete against the recorded baseline; corrections proposed, none implemented.

All 17 findings now have an owning [refactoring packet](../code-review-refactoring/README.md#packets-and-readiness).
Ed accepted the initial recommended architecture direction on 2026-10-13; no finding is closed by planning.

Priority here is the recommended order for refactoring design, not a production incident severity
or a release decision. `High` means address before expanding the affected contributor seam.
`Medium` means a bounded correction or decision. `Later` means optional structural improvement.
Findings are source- or probe-backed; the detailed section supplies consequence, correction and
verification. Missing native evidence is not counted as a code defect.

| ID | Priority | Classification | Finding | Owning review |
| --- | --- | --- | --- | --- |
| F01 | High | Reproduced defect | A bad store dictionary leaves feature/query/kind partly published after registration throws | [01](sections/01-foundation.md#f01-registration-can-fail-after-publishing-part-of-the-batch) |
| F02 | High | Reproduced stability defect | Retained field schemas can change published record validation | [01](sections/01-foundation.md#f02-published-record-field-schemas-remain-mutable-aliases) |
| F03 | Later | Optional structural improvement | Pure rules and native adapters share common-foundation modules and directory | [01](sections/01-foundation.md#f03-the-common-foundation-mixes-pure-and-native-geometry-responsibilities) |
| F04 | High | Reproduced composition gap | Generic participant lookup permits undeclared calls and leaves refusal poisoning to each implementation | [02](sections/02-shell-session.md#f04-generic-proposal-participants-expose-raw-callbacks-rather-than-a-guarded-invocation) |
| F05 | Medium | Reproduced contributor defect | Wire schema can register without `name`, then fail in file-provider sorting | [03](sections/03-services.md#f05-a-registered-library-kind-can-be-valid-yet-fail-because-sorting-requires-name) |
| F06 | High with next geometry feature | Directly evidenced planned-capability gap | Shared export capture drops ordinary Edges; Colour-by lacks contributed line/derived primitives | [03](sections/03-services.md#f06-the-geometry-seams-cannot-yet-serve-ordinary-edges-or-derived-line-overlays) |
| F07 | High | Reproduced extension-seam asymmetry | Entity-backed records lack catalog-equivalent allowlisted structured-payload export | [06](sections/06-export.md#f07-entity-extension-payloads-have-no-supported-allowlisted-export-projection) |
| F08 | Medium | Directly evidenced wording defect | Some public schema descriptions promise verbatim metadata export that implementation omits | [06](sections/06-export.md#f08-some-operation-schemas-incorrectly-promise-verbatim-metadata-export) |
| RF-01 | High | Contract mismatch, refusal reproduced | Existing Zone/Face/Unit metadata cannot be updated through supported owner operations | [04](sections/04-ruby-features.md#rf-01-entity-owned-metadata-cannot-be-maintained-through-the-supported-operations) |
| RF-02 | High | Layering mismatch, consequence reproduced | Windows definition CRUD directly prepares/re-writes Units; repair is an accepted and advertised policy | [04](sections/04-ruby-features.md#rf-02-windows-definition-operations-know-placement-internals) |
| RF-03 | High with RF-01 | Read-contract mismatch, absence reproduced | Entity views return envelopes without understood/unavailable status | [04](sections/04-ruby-features.md#rf-03-entity-reads-preserve-envelopes-but-omit-their-understoodunavailable-status) |
| RF-04 | Later | Optional maintainability improvement | Material library replacement repeats normal validation/persistence flow | [04](sections/04-ruby-features.md#rf-04-material-library-replacement-repeats-the-ordinary-persistence-pipeline) |
| JS-01 | High | Directly evidenced ownership violation | Installation topology and copy eligibility are independently decided in Ruby and JavaScript | [05](sections/05-javascript.md#js-01-window-installation-eligibility-duplicates-ruby-domain-rules) |
| JS-02 | High | Reproduced extension failure | A throwing outcome-text hook prevents correlation and leaves a requesting view pending | [05](sections/05-javascript.md#js-02-an-optional-outcome-translator-can-strand-an-unrelated-requesting-view) |
| JS-03 | Medium | Reproduced example defect | Enter in the example's Length field does not create the part | [05](sections/05-javascript.md#js-03-the-contributor-examples-length-enter-never-creates-the-part) |
| JS-04 | Medium | Reproduced example lifecycle defect | Retired example forms retain preference listeners and obsolete-session submit callbacks | [05](sections/05-javascript.md#js-04-the-contributor-example-retires-its-form-without-disposing-its-field-or-callbacks) |
| JS-05 | Medium | Directly evidenced ownership-policy inconsistency | Zone/summary Face Area is aggregated in JavaScript despite strict Ruby quantity ownership | [05](sections/05-javascript.md#js-05-zone-and-unclassified-summary-area-is-calculated-in-the-panel) |

## Important qualifications

- F01/F05 are failures for synthetic outside declarations; current built-in stores/wire kinds do
  not exhibit them. They matter because a foundation must diagnose and isolate bad contributions.
- F04 is a missing uniform composition guard. The current Library participant supplies its own
  guard and is not reported broken.
- F06 is anticipated shared work in later feature planning, not evidence that today's supported
  Faces/Windows export is wrong. The capture and renderer need a broader contract when Edges/derived
  overlays become implemented behavior.
- RF-02 preserves the deliberately accepted next-Windows-action repair policy. Its discovery
  wording already advertises repair through `Shapes.side_effects`; the first review's contrary claim
  was corrected on 2026-10-13. Move orchestration; changing repair timing is a separate product decision.
- JS-01/JS-05 establish duplicate ownership, not incorrect thermal numbers or persisted assignments.
- JS-02 uses an injected failing contributor hook. JS-03/04 affect the development-only example.
  The host still refuses inactive-session edits; no cross-Model write or data loss was demonstrated.

Additional bounded observations (callback snapshot immutability, state lifecycle documentation,
contributor routing, per-surface isolation and coherent overview extraction) remain in their sections.
They are not promoted into new blockers without a concrete adopter/failure or accepted design need.

## Review disposition

The foundation's overall direction should be retained. It has useful owner registration, declared
feature dependencies, proposal/Undo ownership, reference retargeting, optional libraries and
translation attachments. The current code is a modular application with many onion boundaries,
not a fully portable onion platform. The next work should strengthen those existing seams and
complete entity customization before adding a new plugin framework or distributing packages.

Use [07](sections/07-contributor-workflows.md) to choose a refactoring workstream. A detailed plan
must resolve the indicated behavior/contract decisions, specify focused and native gates, and
receive implementation authorization. This review neither changes canonical behavior nor closes
existing host/platform/release gates.
