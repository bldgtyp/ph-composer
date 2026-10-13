# Foundation purity acceptance

STATUS: Complete. P-01 to P-03 merged to main in PR 121 and archived.

| Case | Scenario | Required result |
| --- | --- | --- |
| P01 | Fresh Ruby process loads pure entrypoints and explicit fixtures | No SketchUp/Geom/test stub required; no native constants introduced or native calls |
| P02 | Concave/holed/large-coordinate loops and reversed outlines | Existing area/plane/comparison values and tolerances retained |
| P03 | Numeric scaled/reflected/singular transforms | Existing correct normals/digests or coded geometry refusal; one calculation owner |
| P04 | Native capture builds detached value | Same loops/area/normal/digest/glue facts as baseline; native objects do not escape |
| P05 | Adjacency/stamp/export/Windows callers | Same reference associations and serialization goldens; load order valid on both Rubies |
| P06 | Dependency check and contributor walkthrough | Pure module names no native adapter; outer adapter calls inward; concise ownership documentation |

P04 needs offline native-adapter fixtures and affected native equivalence if capture semantics change.
Pure subprocess checks are independent of that proof. No package/distribution portability claim follows.
