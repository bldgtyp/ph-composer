# Geometry contribution contracts status

DATE: 2026-10-13
STATUS: G-02 merged to main (PR 119). G-01, G-03 and G-04 are deferred to the phase 3b thermal-bridge ledger, which owns when they run.
ISSUE: [#118](https://github.com/bldgtyp/ph-composer/issues/118)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| G-01 | Confirm Edge facts, segment filtering, `member` counting and line width with the thermal-bridge packet | Deferred to [phase 3b](../../../features/phase-03b-thermal-bridges/STATUS.md#deferred-foundation-stages), with P3b-01 | none yet |
| G-02 | Stub `Vertex` persistent id; `EdgeGeometry` and Edge entries in `GeometrySnapshot.walk`; snapshot goldens | Merged to main (PR 119) | `tests/geometry_snapshot_test.rb` (7 new, incl. shared vertices across repeated occurrences): root Edge with data and SI endpoints; nested, scaled and reflected transforms once; separate containers share no vertex; cutting component Edges absent; cursor equals direct capture; singular transform `geometry.invalid`. `make fixtures` changed no golden; export collection and phase-one export suites unchanged |
| G-03 | `ColourBy::LineEntry`, service branch, overlay line pass | Deferred to [phase 3b](../../../features/phase-03b-thermal-bridges/STATUS.md#deferred-foundation-stages), with P3b-06 | none yet |
| G-04 | Thermal-bridge adoption, measurement, native drawing and export proof | Deferred to [phase 3b](../../../features/phase-03b-thermal-bridges/STATUS.md#deferred-foundation-stages), with P3b-06 and P3b-08 | none yet |

Reviewed against source on 2026-10-13: the definition-local Edge facts in `definition_entity` are the
precedent for the Edge shape; per-segment filtering with a `member` key replaces the open mask
question.
