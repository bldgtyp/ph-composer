# Geometry contribution contracts status

DATE: 2026-10-13
STATUS: Scoped; G-02 implementation ready, G-01 is a document stage, G-03 and G-04 follow the thermal-bridge adopter. Not authorized.
ISSUE: [#118](https://github.com/bldgtyp/ph-composer/issues/118)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| G-01 | Confirm Edge facts, segment filtering, `member` counting and line width with the thermal-bridge packet | Scoped; document deliverable | none yet |
| G-02 | Stub `Vertex` persistent id; `EdgeGeometry` and Edge entries in `GeometrySnapshot.walk`; snapshot goldens | Implemented on branch | `tests/geometry_snapshot_test.rb` (6 new): root Edge with data and SI endpoints; nested, scaled and reflected transforms once; separate containers share no vertex; cutting component Edges absent; cursor equals direct capture; singular transform `geometry.invalid`. `make fixtures` changed no golden; export collection and phase-one export suites unchanged |
| G-03 | `ColourBy::LineEntry`, service branch, overlay line pass | Scoped; after G-01 | none yet |
| G-04 | Thermal-bridge adoption, measurement, native drawing and export proof | Scoped; owned by phase 3b stages | none yet |

Reviewed against source on 2026-10-13: the definition-local Edge facts in `definition_entity` are the
precedent for the Edge shape; per-segment filtering with a `member` key replaces the open mask
question.
