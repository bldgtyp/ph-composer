# P1-D unclassified hatch and action invalidation

DATE: 2026-09-29
STATUS: Implemented and verified on the current installed host; isolated GPU timing remains open.
ISSUE: none (local implementation packet)

## Decision and correction

Ed reviewed adjacent classified and unclassified synthetic Zones in SketchUp and chose the PRD's
hatch treatment on 2026-09-29. The prior dashed boundary was difficult to distinguish from normal
edges. Unclassified Faces now receive a solid boundary plus diagonal hatch, with no categorical
fill. Incomplete values retain their existing amber treatment.

Hatch generation clips world-space stripe planes against cached tessellation triangles, so mesh
holes and concave exterior regions remain empty. Stripe phase is shared across coplanar triangles;
a fallback projected axis handles a Face normal parallel to the primary stripe direction. Default
spacing is six SketchUp inches. Aggregate hatch is bounded to 8,192 segments per rebuild by
uniformly doubling spacing when needed. Tiny Faces may show only their boundary. Draw consumes
cached points and uses the existing depth-tested, camera-lifted GL_LINES path; it reads no records,
meshes or materials and writes no Model data.

Preparing the native fixture reproduced a second defect: a public Make Zone operation completed,
but the active Face-type legend stayed at seven unclassified Faces while its projection contained
eight. A later read remained stale; reactivating the mode corrected it. SketchUp's commit callback
can fire inside ModelSession#mutate before the revision advances, so the existing revision-keyed
invalidation skipped that callback. Colour-by now also listens to the generic post-action session
change publication, with session identity filtering and unsubscribe on detach. The revision key
coalesces callbacks in either order; no feature-specific orchestration was added.

## Verification

Focused tests cover shared stripe phase, hole/concave clipping, reflected, vertical and slanted
meshes, degenerate triangles, aggregate density, cache-only drawing, isolation, visibility and
public Make Zone invalidation. The corrected operation advances the unclassified count and
rebuilds once without mode reactivation.

`make ci` passes: 501 Ruby tests / 2,224 assertions, 174 JavaScript tests, 84 Python tests and
9 hostkit tests, with lint, fixtures, manifest and RBZ checks. `make coverage` passes: Ruby 96.7%,
JavaScript 98.2%, Python 97.46%. The Ruby 2.7.2 full suite passes. Independent review found and corrected a tangent-only stripe-count defect during density
optimization; the final incremental review found no actionable defects. Regression tests retain
5,000 actual segments when 4,000 additional triangles touch stripes only at vertices, and count
real near-vertex and aligned-edge segments toward the cap. `make install` installed the final RBZ
before the final fresh-host checks below.

## Native continuation before density optimization

Fresh installed processes 90721 and 91497 on SketchUp 26.1.188 showed diagonal hatch on the
unclassified box and the concave Face. The box wall retained two native loops; its opening and
the concave notch remained unobstructed. All 500 cached hatch-segment midpoints classified as
inside/on an actual unclassified native Face. Activation left the full Model fingerprint unchanged.

A white panel 500 mm in front of the hatched wall covered the hatch completely, including during
native Orbit. Native Undo removed that fixture with exact data restoration. Hiding the enclosing
unclassified Group reduced hatch from 500 to 75 segments; the full legend count remained seven.
Native Undo restored 500. Isolating Wall produced zero hatch and 26 wash triangles; isolating
Unclassified retained 500 hatch segments and washed the classified box's 12 triangles. Releasing
isolation preserved all records, attributes and materials.

Public Make Zone with Colour-by already active now increased the unclassified count seven to
eight immediately and added hatch, without mode reactivation. Two native Undo steps restored
the original geometry/records and the seven-Face legend/500-segment drawing exactly.

The first density implementation measured 385.976 to 428.469 ms for a synthetic 1,892-triangle
mesh, median 408.881 ms, producing 5,313 segments. This is hatch-generation CPU time, not GPU
frame time or a complete service rebuild. The repeated clipping passes were replaced by one
prepared-triangle pass, conservative aggregate stripe-count estimation, then one clipping pass.
The bound can select coarser spacing than counting actual segments, but never truncates the tail
of the mesh. Final installed timing and appearance are recorded after the fresh-host gate below.

## Final installed-host gate

Fresh process 95258 on SketchUp 26.1.188 loaded the final installed build. Face-type mode showed
Wall 4, Floor 1, Roof or ceiling 1 and Unclassified 7, with 500 cached hatch segments. Native
viewport inspection retained the diagonal hatch on the box and concave Face, the clear concave
notch and the wall opening. Hatch visible through the opening belongs to the opposite wall.
All 500 segment midpoints classified inside/on an actual unclassified native Face. The full
Model fingerprint, including modified state, remained exactly unchanged after activation and
timing. The fixture was left saved, outside edit context, with Classify stopped.

The final CPU-only hatch timing used one warm-up and five samples on the same native mesh and
86 translated copies. The 22-triangle fixture produced 500 segments in 7.088 to 8.513 ms, median
8.415 ms. The 1,892-triangle mesh produced 5,313 segments in 91.391 to 92.279 ms, median
91.969 ms, versus the earlier 408.881 ms median. This does not establish isolated GPU timing
or a complete service-rebuild cost. The native lifecycle/visibility/occlusion and public-action
checks above remain valid; the density correction changes the pre-count while retaining the
fixture's 500 segments. Final CI, coverage and Ruby-floor gates ran after the final source froze.
