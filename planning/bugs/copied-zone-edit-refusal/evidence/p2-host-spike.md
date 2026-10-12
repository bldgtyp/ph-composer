# P2 host spike: copied Zone independence

DATE: 2026-10-12
STATUS: Measured. Awaiting Ed's read (the P2 exit gate in [PLAN](../PLAN.md#p2-host-spike)).
AUTHOR: Ed May, BLDGTYP, with Claude

## Run

- Host: SketchUp 26.1.188, Ruby 3.2.2, macOS, development bridge.
- Build: the installed RBZ of `fix/copied-zone-edit-refusal` at `fbf931e` (P1). No shipping code
  for P3/P4 exists yet.
- Model: `_private/host/copied-zone-bug/spike-base.skp` (gitignored), Ed's reproduction model with
  the copy removed: one Zone Group, persistent id 48909, definition 48910, six classified Faces.
  Each run starts from a fresh copy, `spike-run.skp`.
- Tool: [`tools/spikes/copied-zone-independence/spike.rb`](../../../../tools/spikes/copied-zone-independence/spike.rb),
  loaded through the bridge. It records host events and Zone occurrences, and holds a prototype
  of the P4 shape: on an added Group or ComponentInstance, a zero-delay coalesced timer finds Zone
  ids held by more than one occurrence where exactly one is in the baseline, then repairs the others
  in one transparent operation (`make_unique`, then the shipping `repair_identity` planner and step).
  Faults can be injected at named stages.
- Gestures: Option Move/Copy, Edit > Copy then Paste with a placing click, an array (`5x` after a
  Move/Copy), plain Move, Cut then Paste, all by real keyboard and mouse under full-screen control;
  Copy then Paste in Place through SketchUp's own commands (`Sketchup.send_action("copy:")`,
  `"pasteInPlace:"`), which ran only while SketchUp was frontmost. Undo and Redo through
  `Sketchup.undo` and `Sketchup.redo`. Parent-Group and component arrangements for S5 and S6 were
  made by development eval; the copies themselves were native.

The committed `spike.rb` differs from the file loaded on the host only by rewriting its one-line
`def ... = ...` methods for the Ruby 2.7 lint floor and the blank lines between them; it was not
reloaded afterwards.

One correction during the run: the recorder first checked a misspelt dictionary name and reported
that no copy carried its Zone dictionary at `onElementAdded`. Re-measured with the real name
(`ph_composer.zone`) for Paste in Place, Move/Copy and Paste: every copy carries it. Other results
read records through `ZONE_STORE` and were unaffected.

## Answers

| # | Result |
| --- | --- |
| S1 | Paste in Place, Option Move/Copy, Paste and the array all deliver `onTransactionStart`, `onTransactionCommit`, and only then `onElementAdded` for each new Group. The Zone dictionary is already on the Group in that callback. In every same-Model gesture the original keeps its persistent id (48909) and its transformation; the copy has a new persistent id, the same definition (48910) and, for a moved copy, the new origin. "The occurrence in the baseline is the original" holds |
| S2 | Plain Move adds nothing and triggers nothing. Cut then Paste gives the Zone Group a new persistent id (48909 to 50190) and definition, keeps its Zone and Face ids, and leaves no duplicate, so nothing triggers. Cross-Model paste (Copy, File > New, Paste): one occurrence, state `found`, the source's ids, no duplicate for a detector to see. Cross-Model cut/paste was not measured |
| S3 | Prototype repair after Paste in Place, Option Move/Copy, Paste and the array: the timer's transparent operation joined the gesture. One Undo (`onTransactionUndo` once) removed the copy and its repair together; one Redo restored both with the repaired ids, with no `onElementAdded` and no repeat repair |
| S4 | See the failure table below. Commit-on-failure keeps partial writes; abort-on-failure removes the user's copy; capture-and-restore then commit leaves the native copy in a consistent state |
| S5 | A copied floor Group shares the parent definition, so both its Zones read `shared_definition` along with the original floor's. `make_unique` on the copied parent leaves its inner Zone Groups sharing their own definitions; `make_unique` on each inner Zone of the copy then isolates them, and the original floor's definitions and Face entities are unchanged. The copies then hold distinct storage with duplicated ids, which identity repair handles |
| S6 | Zones inside a copied ComponentInstance read `shared_definition`; the original floor's Zones read `ambiguous` because their ids now occur twice. A detector must decline any occurrence whose path crosses a ComponentInstance, or it would make Groups unique inside a shared definition |
| S7 | Synthetic: 306 Zones, 300 of them with 10 Faces each. Full `Occurrences.zones` walk 25.9 to 34.9 ms (5 runs); with each Zone's Faces 31.9 to 43.4 ms. Run the detection only after an added Group or ComponentInstance |
| S8 | Confirmed again throughout S4: `make_unique` on the copy gives it a new definition and new Face entities carrying the copied Face records; the original's definition, Face entities and records are unchanged |
| S9 | Array: typing `5x` after the first copy made SketchUp undo that copy (`onTransactionUndo`, taking the joined repair with it) and commit all five Groups in one transaction. The watcher rebaselined on the Undo, detected all five in one pass and repaired them in one transparent operation; one Undo and one Redo covered the array and its repair. A native transaction (tool or selection) committed between scheduling and the timer during Move/Copy without disturbing detection. Not measured: an unsafe array member, original deletion, export, Model switch or close before the timer |
| S10 | Not measured: the fixture has no Window Units. Needs a fixture with glued, cutting Units before P5 |

### S4 failure table

The fault is injected during the prototype's transparent operation, after the native Paste in Place
has committed. "One Undo" is read after the outcome.

| Fault | Commit on failure | Abort on failure | Restore captured records, then commit |
| --- | --- | --- | --- |
| After `make_unique` | Copy in its own storage, ids still duplicated | `onTransactionUndo`; the copy is gone | Copy kept, own storage, records as copied |
| After the Zone write | Zone re-identified, Faces still carry the original's ids | Copy gone | Copy kept, own storage, records as copied |
| Midway through Faces | One Face re-identified, five not | Copy gone | Copy kept, own storage, records as copied |
| Before commit | Complete repair committed although the operation "failed" | Copy gone | Copy kept, own storage, records as copied |

In every column the original Zone (definition, Face entities, ids, stamps) was unchanged. In the
commit and restore columns one Undo removed the copy and what was written to it; in the abort column
the copy was already gone, and the extra Undo touched nothing this spike records. Aborting a transparent operation undoes the gesture it
joined, which matches the existing row "`Model#abort_operation` fires `onTransactionUndo`" and the
`TECH_STACK` rule that transparent work must not abort its source.

## What this settles for P3 and P4

1. **Trigger.** A native copy's Group arrives after the commit, so a commit-only trigger never sees
   it. Schedule from the added Group or ComponentInstance (as `Names::State#added` already does) and
   from commits that follow it; detect in the timer.
2. **Failure policy for the automatic path.** Neither commit nor abort is safe on its own. The proven
   mechanism: preflight; isolate storage; capture every record the repair may write on each copy;
   apply; on any failure write the captured records back and commit. The native copy survives with
   distinct storage and its copied identity, which is the state the explicit command repairs, and
   the outcome says so. If the write-back itself fails the outcome is `failed` with effect
   `unknown`; that path was not injectable here.
3. **The explicit command (P3)** runs in its own non-transparent operation through
   `ModelOperation.perform`, where abort is safe and `make_unique` rolls back with the rest. The
   restore policy belongs to the automatic follow-up only. No contradiction with P3 option A.
4. **Batch.** An array arrives as one transaction of N Groups after SketchUp undoes the first copy;
   one gesture-level pass and one transparent operation covered all five.
5. **Undo/Redo.** Rebaselining on `onTransactionUndo` and `onTransactionRedo` and never repairing
   there gave one-step Undo and Redo with no repeat repair.
6. **Scope.** Cross-Model paste stays explicit (D-3); floor copies need parent-then-inner isolation
   and stay deferred with a stated prerequisite; any path through a ComponentInstance is declined.

## Open before P5

S9's unsafe member and the pre-timer deletion, export, switch and close cases; S10 with Window
Units; cross-Model cut/paste; the SketchUp 2023 floor for `Group#make_unique`, transparent joining
and `onElementAdded` ordering.
