# P2-12: guarded reference removal

DATE: 2026-10-01
STATUS: Foundation boundary implemented and independently reviewed; Window removal host steps pending.

`Records::ReferenceRemoval(kind:, key:, before:)` projects an explicitly removed entity
occurrence without storing a null or invalid record. Existing `ReferencePlan.new(entries:)`
callers retain their behavior. A removal requires a registered entity target, exactly one matching
occurrence key and the full unchanged before-record. Replacement and removal keys cannot conflict.
Copies sharing a UUID, orphan references and unavailable-extension references remain in the scan
unless their exact occurrence is removed. Retarget composition retains removals and applies the
same feature-owner check as replacement entries.

The owning feature still supplies its native step and rollback scope. This foundation projection
does not erase entities itself and does not establish Window placement or deletion acceptance.

Verification: affected entity/reference-engine/composition/Assembly-retarget checks pass on Ruby
2.7.2 and 3.2.2, 78 tests / 381 assertions. The final helper-only lint repair retains the current-
Ruby composition result of 16 tests / 70 assertions; five changed Ruby files pass RuboCop.
An independent high-assurance review found no actionable findings and reran the entity/composition
checks on both Rubies, 39 tests / 209 assertions. Projection currently scans the detached inventory
for each removed occurrence; no host I/O is added by that projection. Bulk Window operation costs
still need measurement in their owning implementation.
