# P1-D host evidence: A05 to A09 continuation

DATE: 2026-09-26
STATUS: Current-host continuation verified. Named remaining cases stay open.
ISSUE: none (local implementation packet)

Host: SketchUp Pro 26.1.188 on macOS, embedded Ruby 3.2.2. Started from a fresh process after
D7 commit `a79ae4d` was pushed. Native menus, keyboard and viewport interaction used computer
use; model setup, public API calls and exact read-back used the development bridge. Fixtures
are synthetic and remain under gitignored `_private/host/`.

## A05: adjacency geometry and endpoint meaning

Two boxes shared an 11 m² wall with matching 1 m² holes. Both occurrences received a common
31-degree rotation and scaling of (-1.2, 0.8, 1.1), including reflection. Solve produced one
reciprocal current Surface pair with 9.68 m² on each side and no findings. Both shared Faces
retained two loops. This tests the solver's actual transformed geometry and holes, not a raw
count of stored strings.

A synthetic duplicated Zone UUID made whole-scope Solve refuse `target.ambiguous`, with all
Zone records, Face records and stamps unchanged. After restoring the unique UUID, deleting
the east Zone and solving all remaining Zones returned `completed / none` but left the west
Surface reference behind. This is a reproduced defect against the accepted retirement rule.
Native Undo restored the deleted Zone; snapshots matched by occurrence path (SketchUp changed
entity enumeration order on restoration).

The corrected Solve retires stale pairs in its existing atomic operation, before replacement
pairing or splitting. On the installed fix, deleting east then solving returned `completed /
committed` with no remaining Surface reference; a repeated Solve returned `completed / none`.
Native Undo once restored exactly the pre-Solve, post-deletion records, confirming the repeat
added no Undo step. Redo restored the retired state exactly. Undoing Solve and deletion restored
the original reciprocal pair and complete snapshot. Ambiguous, relocated, nonreciprocal and
out-of-scope endpoints refuse in focused regression tests; they are not treated as deletion.

## A06: native copy, identity repair and limited Restore

The unknown-payload warning behavior recorded below was corrected on 2026-09-29. Identity-changing
copy now requires understood extension copy rules and refuses unsafe data before writes. See
[extension copy safety](p1-d-extension-copy-safety.md); the older run establishes native storage
behavior and exact snapshots, not acceptance of unremapped unknown references.

A native clipboard copy was placed with a viewport click. It copied the Zone dictionary and
shared the original Group definition. Identity repair refused `target.shared_definition`.
After native `Group#make_unique`, explicit repair completed with one copied pair retired and
`zone.copied_extension_data` disclosed:

- Every copied Face received a new UUID and a stamp naming the repaired Zone.
- Original Zone and Face records, including both reciprocal pair envelopes, were unchanged.
- The copy lost its adjacency envelopes and copied Surface condition.
- An unavailable extension payload was preserved verbatim, including its embedded reference
  to the original Face UUID. It was not silently remapped.

Native Undo and Redo restored the complete before/after snapshots exactly. Save, quit and
fresh reopen also reproduced the repaired snapshot exactly, including paths, records and stamps.
The Ruby `Group#copy` setup attempt did not carry the Zone dictionary on this host, so it was
removed and is not the evidence for the clipboard-copy case.

Exploding the repaired copy and invoking limited Restore preserved every member's full Face
record and stamp. The Zone UUID, Building-Segment and Level were recovered. The result explicitly
listed `name`, `user_data`, `extension_data` and `ground_depth_mm` as unrecoverable. Native Undo
returned the orphan offer and removed the restored Zone; Redo restored the exact member state.
A second save, quit and fresh reopen reproduced the restored snapshot exactly.

## A07: Attached-zone lifecycle

Public operations created a Garage and Attic, edited notes with the original-name guard,
duplicated the Garage under a fresh UUID and assigned two Faces to the original. The duplicate
did not capture existing references. Deleting the original with the Attic as replacement changed
exactly those two references. Native Undo and Redo restored the entire catalog and all Face
records, not just counts.

Stale editing refused `target.changed`; a missing replacement refused `target.not_found`.
Both left catalog and Face snapshots unchanged. A session-only injection raised after the
second Face write during delete/reassign. The native operation returned
`failed / operation.failed / rolled_back` and restored the catalog and all Face records exactly.
The injected method was restored immediately and subsequently cleared by process restart.

Deleting with an explicit Adiabatic replacement cleared the Attached-zone references and changed
only the intended boundary fields. Face UUIDs, types and unknown extension payloads remained
unchanged, including embedded Face references in those payloads.

The palette's old New button committed immediately, so cancellation was impossible. It now opens
the shared form dialog. Native Escape left the catalog and revision unchanged, restored focus to
New, and Enter reopened it. Submitting created the entered name and kind with default factor
0.95; a second submission stored an explicit 0.8 factor and chose that exact new record for the
next gesture. This palette has no pending Face proposal: atomic create-and-assign to existing
Faces was not claimed by this create-and-choose result. The subsequent
[atomic inline continuation](p1-d-attached-zone-atomic.md) now verifies that separate public action
and Overview workflow, including Enter/Escape, references, rollback, Undo/Redo and fresh reopen.

## A08: Colour-by host behavior

The original walkthrough's `punch` helper produced no inner loop. The fixture now selects the
correct wall plane and erases the opening Face. Separate native fixtures established:

| Case | Measured result |
| --- | --- |
| Holed Face, 4 x 4 m minus 1 x 1 m | Two loops; eight triangular mesh polygons; triangle area and Face area both 15 m² |
| Concave L-shaped Face | Four triangular mesh polygons; triangle area and Face area both 5 m² |
| Direct tag toggle | Drawing changed from 34 to 38 triangles; one session revision and two rebuilds on this host |
| Scene tag visibility, API and native scene tab | Drawing alternated between 38 and 34 triangles; scene activation rebuilt without advancing revision |
| Native selection through a coloured Face | Selected the intended west Group; overlay did not intercept picking |
| Open another Model | New Model began with no active Colour-by mode; previous Model state stayed separate |
| Close the second Model natively | Closed session became invalid and its mode/rows cleared; original Model stayed active |
| 512 Faces / 1,024 triangles after ancestor fix | Twenty forced Ruby rebuilds: median 10.143 ms, maximum 19.021 ms; Model remained unmodified at revision 1 |

The native viewport showed the hole and concave notch unobstructed, with the HUD and fills
legible. These observations do not substitute for every prescribed occlusion case. The timing
measures Ruby rebuild work, not GPU frame time.

Hiding an enclosing Zone exposed a defect: Face-mode drawing stayed at 54 triangles despite
six Faces becoming hidden through their Group. The correction supplies full occurrence paths
to the shared renderer so every hidden/tagged ancestor is considered. Legend counts deliberately
continue to describe the complete projection, as they already do for directly hidden Faces.
Installed-code verification reduced Face drawing from 54 to 36 triangles when one six-Face Zone
was hidden. A hidden tag on a further enclosing Group produced 36 triangles in both Face and
Zone modes. Native Undo restored 54 triangles and the exact record snapshot. The corrected
walkthrough helper itself was also checked: one two-loop wall, net area 11 m².

## A09: drafts and edit context

The Attached-zone dialog covers native Escape, focus return and Enter submission as described
above. Zone details exposed another defect: after typing an unsaved Name and 12 inches of Ground
depth, changing the authoritative display preference to SI and refreshing the panel replaced
both drafts with stored values. The selected editor now persists across refreshes while
retaining its original expected-value guard and starting unit context. In a fresh installed
process, the Name and 12-inch draft survived an authoritative SI refresh. Enter committed the
unit field as 304.8 mm; keyboard submission saved that exact depth and Name. Native Undo restored
the complete saved baseline. Inputs and Save are disabled while the request is pending, preventing
a later edit from being overwritten by the earlier result; the host snapshot-then-result ordering
and refusal recovery are covered by the focused asynchronous regression.

With west open for native editing, an explicit public classification of one east Face changed
exactly that record and preserved the active west edit path. The panel footer displayed
`Editing: west`. Native Undo restored the exact pre-edit record map and kept the same edit path.
This checks context preservation for that operation, not every modal or structural edit case.

## Verification and review

The final installed payload passes `make ci`, `make coverage` and the complete Ruby 2.7.2 suite.
Ruby: 465 tests / 1,951 assertions; JavaScript: 170 tests. Coverage: Ruby 96.6%, JavaScript
98.2%, Python 97.46%. The runtime manifest and RBZ validation pass. Strong independent review
found no solver-retirement or occurrence-visibility defects. Review of the Zone draft fix found
one pending-save race, corrected by disabling the form until settlement and covered by regression.
The Attached-zone dialog review found no blocking issue.

## Remaining boundaries

Do not close A05 to A09 wholesale from these individual cases. Unique moved-path recovery is now
verified. [Native split identity recovery](p1-d-split-identity-recovery.md) now passes its public action
and native-menu gate. The [clean multi-neighbour continuation](p1-d-multi-neighbour-adjacency.md) verifies one-to-many
pairing. Remaining A06 work is Face/Zone extension-reference targets. The [isolated GPU continuation](p1-d-gpu-timing.md) completes A08’s named current-host cases. The [atomic inline continuation](p1-d-attached-zone-atomic.md)
completes A07’s named current-host cases. The
[hatch continuation](p1-d-hatch-and-invalidation.md) verifies the PRD hatch; the
[keyboard/context continuation](p1-d-keyboard-context.md) completes A09's named current-host cases.
The [adjacency boundary continuation](p1-d-adjacency-boundaries.md) completes A05's named
current-host cases. Native Overlays-panel toggles, foreground occlusion, alpha and orbit are
verified in the [2026-09-29 Colour-by continuation](p1-d-colour-by-continuation.md), with feature
redraw/cadence measured at 1,032 triangles. SketchUp 2023, Windows, P1-E/F, public distribution
and certification acceptance remain outside this run.
