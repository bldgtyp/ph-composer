# P1-D host evidence: the gesture ceiling and what occurrence resolution costs

DATE: 2026-09-20
STATUS: Measured. The ceiling holds as a bound on blast radius; the cost it was lowered to contain
is in occurrence resolution and is not fixed by any ceiling. No code changed on this evidence.
ISSUE: none (local implementation packet)

Host: SketchUp Pro 26.1.188, macOS 26.6.2, Apple M1 Max, embedded Ruby 3.2.2, through the
PH-Composer development bridge. Extension `ph_composer` 0.1.0-dev at commit `5b93fb0`, features
`PhComposer::Zones` and `PhComposer::FaceAssignment`. Fresh from
`_private/host/blank-template.skp`, saved as `_private/host/p1d-gesture.skp`
(SHA-256 `20edd54a…f113a82b`). Harness:
[`gesture_cost_walkthrough.rb`](../../../tools/examples/authoring/gesture_cost_walkthrough.rb).

The fixture is boxes three metres wide, ten to a row, flush along each row and clear between rows,
so every interior box shares exactly one wall with the box on either side. Each is made a Zone and
auto-classified, then `solve_adjacency` pairs the shared walls. No wall meets two neighbours, which
D4 reports rather than cuts. Every number is the median of three runs of one whole
`ph_composer.face_assignment.classify` through the public interface, with the revision, the request
envelope and the target list all in hand before the clock starts. A gesture over paired Faces
retires those pairs, so the Model is re-solved between runs, outside the timed span, and every run
measures the same worst case.

## What a gesture costs

At 2,004 Faces in 334 Zones:

| Gesture | Unpaired targets | Paired targets |
| ---: | ---: | ---: |
| 1 | 147 ms | 209 ms |
| 10 | 509 ms | 753 ms |
| 50 | 2,184 ms | 3,210 ms |
| 250 | 10,368 ms | not measured; the fixture pairs 550 Faces, and 250 of them cost more than the unpaired case |

At 504 Faces in 84 Zones the same gestures cost 52, 128, 477 and 2,242 ms unpaired, and 66, 216
and 834 ms paired. Cost is close to linear in the number of targets, with a floor of about 50 ms
at 504 Faces and about 145 ms at 2,004.

## Where the cost is

The same 50-target gesture over paired Faces, against a growing Model:

| Model Faces | Gesture of 50 |
| ---: | ---: |
| 252 | 459 ms |
| 504 | 826 ms |
| 1,002 | 1,633 ms |
| 2,004 | 3,352 ms |

Doubling the Model doubles the cost of an unchanged gesture. The cost is therefore
**O(targets × Model Faces)**, and it is in resolution, not in the gesture:
`Occurrences.resolve_face` calls `resolve_zone`, which walks the whole Model, and then
`faces_with_id`, which walks every Zone's Faces, so a gesture of N targets walks the Model about
2N times and `retire_pairs` resolves each counterpart the same way. Measured, that is about
0.033 ms per target per Model Face.

Resolution is roughly half of the total. The same 250-target gesture at 2,004 Faces took 5,119 ms
when the intent set the value the Faces already carried, so nothing was written, no proposal was
built and no operation opened; it took 10,368 ms when it wrote. The write half is one native
operation over 250 records and is not what this measurement is about.

## The ceiling

`GESTURE_FACE_LIMIT` is 250, lowered from the proposed 1,000 on offline evidence during D1.

| Check | Measured |
| --- | --- |
| A gesture of exactly 250, at 2,004 Faces | Completed in 10,368 ms, 250 affected |
| A gesture of 251 | Refused in **3.6 ms**, `gesture.too_large`, nothing affected |

The refusal is the part of D1's design that this confirms: targets are deduplicated and counted
before anything is resolved, so an over-limit gesture costs one comparison rather than 251 Model
walks. That is worth keeping whatever the limit becomes.

The limit itself neither passes nor fails here, because it was never the right instrument. It
bounds how much of the Model one gesture can change, which is a correctness and Undo concern, and
it holds for that. It cannot bound elapsed time, because elapsed time depends on the Model the
gesture runs in as much as on the gesture: 250 targets cost 2.2 s at 504 Faces and 10.4 s at
2,004, and would cost more again in a larger one. Lowering it to 100 would buy 4 s in this Model
and nothing in a Model four times the size.

## A second, larger finding: the Face read is quadratic

`ph_composer.face_assignment.list` is the read the Classify tool and D7's faces table both depend
on. It was measured alongside, on the same Models:

| Model Faces | `list` |
| ---: | ---: |
| 60 | 15 ms |
| 120 | 64 ms |
| 504 | 834 ms |
| 2,004 | 12,764 ms |

Four times the Faces costs about fifteen times the time. This is not the same defect as the
gesture's: `list` resolves nothing, so the cause is elsewhere in the per-Face read, and it has not
been traced. At 2,004 Faces a single refresh of the faces table would block the host for nearly
thirteen seconds. Whatever is decided about the gesture, this needs its own diagnosis before D7
builds a table on it.

## Recommendation

Keep the ceiling at 250 and fix the resolution. One bounded resolution pass per gesture — walk the
Model once, index the Zones by id and the Faces by id and by occurrence path, then resolve every
target and every retirement counterpart against that index — turns O(targets × Model Faces) into
one walk plus O(targets). On these numbers a 250-target gesture at 2,004 Faces would fall from
about 5.1 s of resolution to the cost of one walk, which `list` puts at well under a second once
its own defect is separated out.

A lower ceiling is the alternative and it is the wrong one. It would hide the shape of the problem
without changing it, and it would take the tool further from the drag the PRD describes. The
ceiling's job is to bound what one gesture can change; it should keep that job and not be asked to
stand in for a performance budget.

Both the resolution pass and the `list` diagnosis belong to D6, before the Classify tool's drag
behavior is accepted. Neither was changed on this evidence; the decision is Ed's.
