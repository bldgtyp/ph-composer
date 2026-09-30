# P1-D host evidence: the gesture ceiling and what occurrence resolution costs

DATE: 2026-09-20
STATUS: Measured, then fixed and re-measured. The ceiling holds as a bound on blast radius. The
cost it was lowered to contain was in occurrence resolution; one indexed walk per read phase
removed it, and the same patch removed the Face read's separate quadratic.
ISSUE: none (local implementation packet)

Host: SketchUp Pro 26.1.188, macOS 26.6.2, Apple M1 Max, embedded Ruby 3.2.2, through the
PH-Composer development bridge. Measured before the fix at commit `5b93fb0` and again after it,
on the same host and the same fixture, with the extension rebuilt and reinstalled between the two
runs. Extension `ph_composer` 0.1.0-dev, features
`PhComposer::Zones` and `PhComposer::FaceAssignment`. Fresh from
`_private/host/blank-template.skp`, saved as `_private/host/p1d-gesture.skp`
(SHA-256 `20edd54a…f113a82b`) before and `_private/host/p1d-gesture-after.skp`
(SHA-256 `012f7dea…f662b975ac1`) after. Harness:
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

At 2,004 Faces in 334 Zones, before the fix and after it:

| Gesture | Unpaired, before | Unpaired, after | Paired, before | Paired, after |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 147 ms | 149 ms | 209 ms | 135 ms |
| 10 | 509 ms | 148 ms | 753 ms | 153 ms |
| 50 | 2,184 ms | 154 ms | 3,210 ms | 161 ms |
| 250 | 10,368 ms | **182 ms** | see below | — |

Before the fix, cost was close to linear in the number of targets: at 504 Faces the same gestures
cost 52, 128, 477 and 2,242 ms unpaired, and 66, 216 and 834 ms paired. After it, the curve is
flat. Two hundred and fifty times the targets costs about a fifth more, which is the
writing, not the resolving. The 250-target paired case is not listed because the fixture pairs 600 of its 2,004
Faces and the harness picks both endpoints of each pair, so a 250-target paired gesture and a
250-target unpaired one resolve the same number of occurrences; the unpaired row is the honest
comparison and the paired 50 row shows what retirement adds.

## Where the cost is

The same 50-target gesture over paired Faces, against a growing Model:

| Model Faces | Gesture of 50, before | after |
| ---: | ---: | ---: |
| 252 | 459 ms | 46 ms |
| 504 | 826 ms | 58 ms |
| 1,002 | 1,633 ms | 89 ms |
| 2,004 | 3,352 ms | 164 ms |

Before the fix, doubling the Model doubled the cost of an unchanged gesture. The cost was
**O(targets × Model Faces)**, and it was in resolution, not in the gesture:
`Occurrences.resolve_face` calls `resolve_zone`, which walks the whole Model, and then
`faces_with_id`, which walks every Zone's Faces, so a gesture of N targets walks the Model about
2N times and `retire_pairs` resolves each counterpart the same way. Measured, that is about
0.033 ms per target per Model Face.

After the fix the same gesture still grows with the Model, and it should: one walk of a Model is
O(Model). What it no longer does is walk once per target. That is the whole of the change.

Resolution was roughly half of the total before the fix. The same 250-target gesture at 2,004
Faces took 5,119 ms
when the intent set the value the Faces already carried, so nothing was written, no proposal was
built and no operation opened; it took 10,368 ms when it wrote. The write half is one native
operation over 250 records and is not what this measurement is about.

## The ceiling

`GESTURE_FACE_LIMIT` is 250, lowered from the proposed 1,000 on offline evidence during D1.

| Check | Before | After |
| --- | --- | --- |
| A gesture of exactly 250, at 2,004 Faces | 10,368 ms, 250 affected | **182 ms**, 250 affected |
| A gesture of 251 | Refused in 3.6 ms, `gesture.too_large` | Refused in 3.6 ms, unchanged |

The refusal is the part of D1's design that this confirms: targets are deduplicated and counted
before anything is resolved, so an over-limit gesture costs one comparison rather than 251 Model
walks. That is worth keeping whatever the limit becomes.

The limit itself neither passed nor failed, because it was never the right instrument. It
bounds how much of the Model one gesture can change, which is a correctness and Undo concern, and
it holds for that. It could not bound elapsed time, because elapsed time depended on the Model the
gesture ran in as much as on the gesture: 250 targets cost 2.2 s at 504 Faces and 10.4 s at 2,004,
and would have cost more again in a larger one. Lowering it to 100 would have bought 4 s in this
Model and nothing in a Model four times the size. It stays at 250 and keeps its own job.

## The Face read was quadratic, and the same patch fixed it

`ph_composer.face_assignment.list` is the read the Classify tool and D7's faces table both depend
on. It was measured alongside, on the same Models:

| Model Faces | `list`, before | after |
| ---: | ---: | ---: |
| 60 | 15 ms | — |
| 120 | 64 ms | — |
| 504 | 834 ms | — |
| 2,004 | 12,764 ms | **205 ms** |

Four times the Faces cost about fifteen times the time. The cause turned out to be the same call:
`Adjacency.state` resolves the counterpart of every Surface Face to report whether the pair is
current, and each of those resolutions walked the whole Model. It is the gesture's defect reached
by a different route, so the index fixed it without a second patch. At 2,004 Faces, of which 600
were paired, a refresh of the faces table fell from nearly thirteen seconds to a fifth of one.

That read is what D7's faces table and the Classify tool both depend on, so it had to be right
before either was built on it.

## What was done

`Zones::Index` is one lazily-built walk of a Model, reused for the length of one read phase. It is
threaded as an optional `index:` keyword through the occurrence reads and through
`Adjacency.state` and `retire_records`; without the keyword every call walks the Model exactly as
before, so nothing that did not opt in changed behaviour.

Four places opt in, and each is a read phase with no mutation inside it: the Face read, the
target-resolution phase of a Classify gesture, Auto-classify, and the resolve-everything-first
half of `ClassifyStep#apply`. That last one is safe because the step already resolved and checked
every target before writing any of them, so that a Face that moved since the preview aborts the
gesture rather than leaving half of it painted; the index lives only in that first half.

No mutating step was given one, and none should be. A step that cuts geometry has to see what it
just did, so `SplitAndPairStep` and the rest keep walking the live Model. That constraint is in
`index.rb`'s own comment, and the existing split, repair and solve suites are what hold it.

The offline suite cannot speak to milliseconds, so it pins the shape instead:
`tests/occurrence_index_test.rb` asserts that the number of times the Model is walked does not
grow with the number of targets. Against the unpatched code those tests fail loudly, a twenty-Face
gesture walking the Model twenty-four times where it now walks it twice.

The ceiling stays at 250. Nothing about it changed.

A bounded independent review traced the hazard this design carries, that an index outlives the
Model state it describes, through all four opt-in sites and every step class, and found no read
that could write the wrong Face. It found the comment guarding that rule stated it wrongly, since
`ClassifyStep` is a step and does take one; that an index was not bound to the Model it was built
for, which nothing does today but nothing would have caught; and that Auto-classify resolved its
Zone before building its index, paying for a whole Model walk it then did not use. All three are
fixed, and the numbers above are from the build with those fixes in it.
