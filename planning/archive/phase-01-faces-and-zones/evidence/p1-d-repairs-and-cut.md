# P1-D host evidence: Zone repairs and the adjacency cut

DATE: 2026-09-20
STATUS: Pass, with one defect found and fixed during the gate.
ISSUE: none (local implementation packet)

Host: SketchUp Pro 26.1.188, macOS, embedded Ruby 3.2.2, through the PH-Composer development
bridge. Extension `ph_composer` 0.1.0-dev, features `PhComposer::Zones` and
`PhComposer::FaceAssignment`. Models were fresh from `_private/host/blank-template.skp`.
Walkthroughs: [`repair_walkthrough.rb`](../../../../tools/examples/authoring/repair_walkthrough.rb)
and [`cut_walkthrough.rb`](../../../../tools/examples/authoring/cut_walkthrough.rb).

Offline at the same commit: 337 Ruby tests, 1,435 assertions, green on Ruby 3.2.2 and the 2.7.2
compatibility floor, `make ci` clean, Ruby coverage 96.0%.

## D4, the cut

Two boxes meeting on one plane, offset so their shared wall is a partial overlap: 12 m2 each,
6 m2 shared. Solve cut both sides and paired the shared pieces.

| Question the implementation depends on | Measured |
| --- | --- |
| Which resulting Face keeps the native persistent id? | Both originals survived the cut, and their `fac_` ids were reused. The step still looks the survivor up rather than assuming it |
| Does every piece keep the dictionaries the original carried? | Yes. A `firm.mark` payload written before the cut appeared on all four pieces, and every piece carried a Zone stamp |
| Does a shared region wholly inside a Face come back as one Face with a hole? | Yes. The contained fixture left three Faces: one with two loops at 8 m2, the original 12 m2 net of the 4 m2 hole, and the two 4 m2 shared pieces. `Face#area` is already net of the hole |
| Is the whole cut one Undo step? | Yes. One Undo returned both walls to 12 m2 with their original Face ids, payloads and boundary conditions; Redo restored the cut exactly |

Boundary conditions after the partial cut read `Surface`, `Ground`, `Ground`, `Surface`: the
shared pieces paired and each remainder kept the classification it already had, which is Q21.

## D3, the repairs

| Case | Measured |
| --- | --- |
| Zone inside shared component storage | Repair refused with `target.shared_definition`; the Model was unchanged |
| Explode | The Group went; all six stamped Faces stayed in the parent context with their records and stamps, and Restore was offered for the remembered Zone id with six members |
| Limited Restore | Recovered the Zone id, Building-Segment and Level, kept all six Face ids and boundary conditions, and disclosed name, `user_data`, `extension_data` and ground depth as unavailable. The restored Group was `manifold? == true` with 6 Faces and 12 Edges and nothing left in the parent context, so the host takes the bounding Edges |
| Undo after Restore | One Undo returned the six loose stamped Faces |

## The defect this gate found

Ed copied a Zone by hand with Option-drag. SketchUp's Entity Info reported "Solid Group (2 in
model)", and the measurement confirmed why: **copying a Group does not copy what is inside it.**
Both Groups became instances of one definition sharing every Face, while each instance kept its
own Zone record. A copied Zone is therefore ambiguous and shared at the same time.

The resolver marked storage shared only when a path ran through a `ComponentInstance`, so the copy
read as ambiguous but not shared, and identity repair accepted it. Because both occurrences
resolve to the same Face entities, giving the copy fresh Face ids **rewrote the original Zone's
Faces and stamped them to the copy**. Reproduced on the host before the fix: both Zones ended
holding the same six new Face ids.

Fixed by treating a container's contents as shared when it is a `ComponentInstance` or its
definition has more than one instance. Re-measured on the host afterwards: the Zone reads
`shared_definition`, repair refuses with `target.shared_definition`, and the Face ids are
untouched. The offline stub gained group definitions and instances so a fixture models two Groups
built on one collection as two copies behave on the host.

This settles Q25 in the [Zones PRD](../../../archive/phase-01-zones-and-adjacency/PRD.md): a copied Zone
needs SketchUp's own Make Unique before identity repair is available, and PH-Composer does not run
Make Unique inside a repair.

## Three walkthrough defects, none in shipping code

- `Sketchup::Model#undo` does not exist on the host. Native Undo is `send_action("editUndo:")` and
  runs on the UI queue. The offline stub keeps `Model#undo` because a test has no UI queue; that
  deviation is now pinned in `tests/sketchup_stub_deviations_test.rb`.
- Make Zone renames a Group to its Zone name, so a walkthrough's own prefix is gone after the
  first step and lookups must accept both spellings.
- Instancing a Zone Group's own definition does not put the Zone in shared storage, because the
  Zone record sits on the Group rather than inside it.

## Not covered here

The Classify tool is implemented in D6 and the Overview table is D7; neither has host evidence yet.
Colour-by is implemented in D5 and has none either. Both have their own walkthrough checked in with
the questions it has to answer:
[`colour_by_walkthrough.rb`](../../../../tools/examples/authoring/colour_by_walkthrough.rb) and
[`classify_tool_walkthrough.rb`](../../../../tools/examples/authoring/classify_tool_walkthrough.rb).
The gesture ceiling's own host measurement is done and is in
[the gesture cost evidence](p1-d-gesture-cost.md). A Face
meeting more than one neighbour, a concave outline and a Face with a hole are reported rather than
cut, as recorded in [PLAN.md](../PLAN.md).
