# Ruby model and authoring domain review

DATE: 2026-09-30
ISSUE: none (local planning draft)
STATUS: Investigation complete; no implementation authorized or performed.
REVIEWED: PR #3, HEAD `99b6fc7b1dc6c80129c7467ebb5851c6cedb7c0c`, against `origin/main`.

## Actionable findings

### M1, P1: A shared child Group bypasses the Face mutation refusal

Confirmed through the public API against the existing SketchUp stub.

Source: `src/ph_composer/features/zones/occurrences.rb:147-152`.

`resolve_face_path` rejects a ComponentInstance but descends into a Group after checking only
its lock. The existing `shared_storage?` helper at lines 243-248 recognizes that two native
Groups can share their definition. `resolve_zone` uses that helper only on the path to the Zone,
so a shared Group below the Zone escapes the check.

With two child Groups sharing one Entities collection and an unrecorded Face inside it,
Classify on one explicit occurrence returns `completed/committed`, reports one affected Face,
and writes the same new Face record through both occurrences. The next read exposes two
Faces with the same authored UUID. This breaks the occurrence-qualified mutation scope and
the explicit-uniqueness contract in `context/TECH_STACK.md:149-153`.

Smallest correction: apply `shared_storage?` to every intermediate mutable container, including
Groups. Keep reads available. Do not call `make_unique` automatically.

Verification: classify and reverse an unrecorded Face under shared child Groups, with both
placements in one Zone and with one outside the Zone. Preview and invoke should refuse
`target.shared_definition`, write nothing, and create no Undo step. Include a fresh native
copy/Group case when closing the host gate, since the fixture deliberately models measured
Group sharing. An already-recorded duplicate must continue to refuse as well.

### M2, P2: A supplied Face path can cross into another authored Zone

Confirmed through the public API against the existing SketchUp stub.

Source: `src/ph_composer/features/zones/occurrences.rb:139-156`.

The inventory walk stops at a child carrying a Zone record (`walk_faces`, lines 257-259), but
the path resolver descends through that same child Group without checking Zone ownership.
A caller can therefore supply a valid outer Zone id/path and `entity_path` through an authored
inner Zone. The outer Zone passes the hierarchy check, and Classify commits a record and stamps
the inner Face with the outer Zone id. Normal inner-Zone requests refuse `target.wrong_hierarchy`;
the crafted explicit path bypasses that refusal. The pointer adapter's comment at lines 102-109
already describes this hazard, but the public action remains exposed to it.

Smallest correction: refuse a Face path that crosses another Zone record, using the same ownership
boundary as `walk_faces`. Apply it to reads and writes so one occurrence reference has one meaning.

Verification: use an explicit outer reference that traverses the inner Group. Classify, reverse,
and locate/resolution must not bind the Face to the outer Zone; mutation must write nothing.
Also retain ordinary nested non-Zone Group support and direct inner hierarchy refusals.

### M3, P2: Attached-zone deletion leaves orphan Face references dangling

Confirmed through the public API against the existing SketchUp stub.

Sources: `src/ph_composer/features/face_assignment/install.rb:429-433` and
`src/ph_composer/core/records/reference_resolution.rb:34-49`.

Delete promises to move every Face naming the Attached zone and says an unreachable Face
refuses the whole delete. `referencing_faces` scans only Faces currently inside live Zones.
An orphan Face outside a Zone can retain its assignment and `attached_zone_id` after native
explode or movement. Deleting the definition commits and leaves that reference unchanged.
Restore can then bring the Face back into authored scope with a dangling Attached-zone reference.

`FaceAssignment::ReferenceTargets.entries` already includes orphan records, but the engine's
incoming-reference scan reads core references only for catalog kinds. It sees an entity record's
structured extension references and ignores its `attached_zone_id`, so the final deletion guard
does not catch this gap. A generic catalog deletion has the same missing core-reference protection.

Smallest correction for the feature action: inventory all stored Face assignments before deletion,
and refuse when a referencing occurrence cannot be safely reassigned through its normal operation.
Do not silently mutate an orphan outside authoring scope. The public reference-target contract
also needs a declared way to enumerate core references if catalog deletion is to enforce the same
invariant without feature-specific branches.

Verification: assign an Attached zone, explode or orphan a member Face, then delete with either
replacement mode. It must refuse and retain the definition and assignments, or apply a separately
accepted complete reassignment policy. Cover repeated/shared placements, readable extension
references, normal successful replacement, Undo/Redo, and Restore after the refusal.

### M4, P2: Partial adjacency pairing retains an invalid Attached-zone reference

Confirmed through the public API against the existing split-capable SketchUp stub.

Source: `src/ph_composer/features/zones/adjacency_steps.rb:131-141`.

`SplitAndPairStep#pair` changes each shared piece's boundary to Surface but leaves
`attached_zone_id`. Face schema validation correctly refuses a reference carried by a different
boundary. A valid partially overlapping AttachedZone Face therefore previews a solve successfully,
then fails during apply with `operation.failed/rolled_back` and the message
`attached_zone_id is only valid for AttachedZone`. Both native Faces return to their original state.

The full-match path (`Adjacency.with_pair`) and multi-neighbour path
(`PartitionAndPairStep#pair_regions`) already delete the field. The single partial-match path is
the inconsistent one.

Smallest correction: delete `attached_zone_id` on the shared pieces when installing Surface,
matching those existing paths. Retain the AttachedZone boundary/reference on unpaired remainders.

Verification: partial overlap where one or both original Faces are AttachedZone; verify completed
pairing, two reciprocal shared endpoints with no Attached-zone reference, remainders retaining the
original reference, idempotent repeat solve, and native Undo/Redo of geometry and records together.

## Reproduction commands

Run from the repository root. These scripts use existing test helpers, modify synthetic in-memory
models only, and write no tracked source. Minitest runs the existing loaded suite on exit.

M1 and M4:

```sh
~/.rbenv/versions/3.2.2/bin/ruby -Itests - <<'RUBY'
require './tests/zone_solve_scope_test'
probe = ZoneSolveScopeTest.new('review_probe')
probe.setup
model = Sketchup.active_model
shared_face = Sketchup::Face.new(901)
shared_contents = Sketchup::Entities.new([shared_face])
child_a = Sketchup::Group.new(910, shared_contents)
child_b = Sketchup::Group.new(920, shared_contents)
zone = Sketchup::Group.new(900, Sketchup::Entities.new([child_a, child_b]))
model.entities << zone
probe.send(:invoke, 'ph_composer.zones.make', {'parent_path'=>[], 'entity_ids'=>[900]})
rows = probe.send(:faces)
result = probe.send(:invoke, 'ph_composer.face_assignment.classify', {
  'faces'=>[rows.first.fetch('reference')],
  'intent'=>{'face_type'=>{'mode'=>'set','value'=>'Wall'},
             'boundary_condition'=>{'mode'=>'set','value'=>'Outdoors'}}
})
after = probe.send(:faces)
puts "M1: #{result.values_at('status','effect').inspect}; affected=#{result.fetch('affected').length}"
puts "M1 occurrences: #{after.map{|row|row.dig('reference','entity_id')}.inspect}"
probe.setup
probe.send(:wall, 600,0,0,4,0,3,:east)
probe.send(:wall, 610,0,2,6,0,3,:west)
probe.send(:author)
attached_id = probe.send(:invoke, 'ph_composer.face_assignment.attached_zone.save', {
  'values'=>{'name'=>'Garage','kind'=>'garage'}
}).dig('value','id')
first = probe.send(:faces).first
probe.send(:invoke, 'ph_composer.face_assignment.classify', {
  'faces'=>[first.fetch('reference')],
  'intent'=>{'boundary_condition'=>{'mode'=>'set','value'=>'AttachedZone'},
             'attached_zone_id'=>{'mode'=>'set','value'=>attached_id}}
})
result = probe.send(:solve, probe.send(:all_references))
puts "M4: #{result.values_at('status','effect','code','message').inspect}"
RUBY
```

Observed M1: `completed/committed`, affected count 1, two identical non-null `fac_` ids.
Observed M4: `failed/rolled_back/operation.failed`, with the AttachedZone schema message.
Existing suite: 60 runs, 301 assertions, zero failures/errors/skips.

M3 and M2:

```sh
~/.rbenv/versions/3.2.2/bin/ruby -Itests - <<'RUBY'
require './tests/attached_zone_test'
probe = AttachedZoneTest.new('review_probe')
probe.setup
model = Sketchup.active_model
id = probe.send(:create_zone_record,'Garage')
probe.send(:assign, probe.send(:faces).first, id)
group = model.entities.to_a.grep(Sketchup::Group).first
original = group.entities.to_a.grep(Sketchup::Face).first
orphan = Sketchup::Face.new(900)
PhComposer::FaceAssignment::FACE_STORE.write(orphan,
  PhComposer::FaceAssignment::FACE_STORE.read(original).merge('id'=>'fac_000000000999'))
model.entities << orphan
result = probe.send(:invoke, 'ph_composer.face_assignment.attached_zone.delete', {
  'id'=>id, 'replacement'=>{'mode'=>'boundary_condition','boundary_condition'=>'Adiabatic'}
})
puts "M3: #{result.values_at('status','effect').inspect}; retained reference=" \
     "#{PhComposer::FaceAssignment::FACE_STORE.read(orphan)['attached_zone_id']}"
puts "M3 definition present: #{probe.send(:records).any?{|record|record['id']==id}}"
probe.setup
model = Sketchup.active_model
outer = model.entities.to_a.grep(Sketchup::Group).first
inner_face = Sketchup::Face.new(700)
inner = Sketchup::Group.new(701,Sketchup::Entities.new([inner_face]))
outer.entities << inner
record = PhComposer::Zones::ZONE_STORE.read(outer).merge('id'=>'zon_000000000888','name'=>'Inner')
PhComposer::Zones::ZONE_STORE.write(inner,record)
outer_record = PhComposer::Zones::ZONE_STORE.read(outer)
session = PhComposer::Sessions.for(model)
context = PhComposer::API.connect(session_id:session.id)
reference = {'zone_id'=>outer_record['id'],'zone_path'=>[outer.persistent_id],
             'entity_path'=>[701,700],'entity_id'=>nil}
result = PhComposer::API.invoke(context:context,name:'ph_composer.face_assignment.classify',
  params:{'faces'=>[reference],'intent'=>{'face_type'=>{'mode'=>'set','value'=>'Wall'}}},
  request:{'sequence'=>1,'expected_revision'=>session.revision})
puts "M2: #{result.values_at('status','effect').inspect}; expected owner=#{record['id']}; stamp=" \
     "#{PhComposer::Zones::STAMP_STORE.read(inner_face)['zone_id']}"
RUBY
```

Observed M3: `completed/committed`, orphan reference retained, definition absent.
Observed M2: `completed/committed`, inner Face stamped with outer Zone id.
Existing suite: 13 runs, 38 assertions, zero failures/errors/skips.

## Contributor boundaries and simplification

The core changes preserve the proposal/native-operation separation. Entity stores resolve explicit
entities; metadata copying is detached; extension remapping is target-kind-aware; reference plans
project exact occurrences. Sessions remain feature-neutral. The shared proposal participant used
for reciprocal retirement is a useful declared seam.

Two bounded architectural concerns were passed to the root reviewer, which owns the final
cross-layer recommendation:

- `SplitAndPairStep#check_removed_identities!` (`adjacency_steps.rb:79-84`) obtains
  `Registry.current.catalog` even though the public action prepared against `request.registry.catalog`.
  This is a hidden business dependency. Supply the catalog/reference guard explicitly when constructing
  the step so invocation, preview, and apply use the same registrations. An alternate registered
  catalog with an incoming extension reference should prove refusal after a no-survivor cut.
- Zones and FaceAssignment have reciprocal direct references to stores, schemas, and adjacency internals,
  while FaceAssignment alone declares a dependency on Zones. Adding a new consumer of authored Face
  identity requires learning both feature internals. Prefer one explicit authored-envelope domain owner
  or a small declared Face record/reference facade over another registry branch or generic plugin system.
  The deletion gap above illustrates the missing core-reference capability concretely.

Complexity evidence comes from the root's advisory RuboCop JSON audit, not a failed required gate.
Examples: `Adjacency.state` cyclomatic 17, `retirement_updates` 15, `retirement_endpoint` 13;
`SplitIdentityRepair.keeper_path` 17 and `reciprocal` 16; `validate_make_target!` 16.
These are review signals. A useful simplification would centralize the reciprocal-pair validation
predicate shared by `state`, `current_pair?`, snapshot validation and retirement, while keeping
live occurrence resolution distinct from detached snapshot comparison. Do not mechanically split
methods to meet the metric. Fix the four reproduced defects first.

No confirmed dead production code was established in the changed domain slice. Test-only limits
and reset hooks are explicitly marked and used by tests. `Repair.restore_plan` still accepts an
unused `revision` argument; removing that parameter is optional cleanup, not a blocker.

## Scope, checks, and limits

Read the architecture-review skill, current coding/extensibility authorities, relevant host and
transaction sections of TECH_STACK, current AGENTS instructions, and changed source against
`origin/main`. This is a foundation/domain review, not a host acceptance or release claim.

File coverage:

| Area | Coverage |
| --- | --- |
| `core/operations/entity_scope.rb`, `proposal.rb` | Entire new files, capture/apply/abort comparison and digest contracts |
| Changed `core/records/catalog.rb`, `change_set.rb`, `dictionary_store.rb`, `engine.rb`, `entity_store.rb`, `extension.rb`, `identity.rb`, `reference_resolution.rb`, `reference_target.rb` | Full changed behavior; create/update/delete/duplicate/remap/reference removal traced |
| `core/face_geometry.rb`, `drag_set.rb`, `pick.rb` | Entire new files; geometry representation and neutral primitives |
| Changed `session/caller_registry.rb`, `host_observers.rb`, `model_session.rb`, `sessions.rb` | Changed behavior plus complete session/observer dispatch paths; export-generation ownership coordinated with root |
| `features/zones/schema.rb`, `occurrences.rb`, `index.rb`, `steps.rb`, `overlap.rb`, `adjacency.rb`, `face_split.rb`, `adjacency_steps.rb`, `repair.rb`, `split_identity_repair.rb`, `install.rb` | Entire domain paths; new public registrations, repair/removal guards, and failure paths traced |
| `features/face_assignment/schema.rb`, `attached_zone.rb`, `steps.rb`, `reference_targets.rb`, `geometry.rb`, `install.rb` | Entire domain paths and public operations; viewport-tool implementation excluded |
| Feature `export.rb` files and FaceAssignment `colour_modes.rb` | Read for domain projection/reference consequences; export orchestration and shared renderer reviewed by root |
| Menus, `classify_tool.rb`, `locate.rb`, Zone colour-mode implementation, HtmlDialog and UI assets | Registration inspected where present in installers; detailed implementation outside this worker's domain slice |

Independently ran the reproduction commands above and their existing focused suites. Root reports
fresh `make ci` passing at this HEAD: 605 Ruby, 184 JavaScript and 96 Python tests, plus hostkit and
the remaining gate steps. Did not repeat that full gate. No shipping code, tests, fixtures,
commits, or native-host state were changed. Native proof of the corrections remains required
when implemented; the offline reproductions establish code defects without claiming host closure.
