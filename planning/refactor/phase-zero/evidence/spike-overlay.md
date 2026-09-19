# B2 spike: overlay fill

DATE: 2026-09-18
STATUS: In progress. Criteria frozen before any measurement; results follow in this file.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Expected (frozen before measuring)

Frozen 2026-09-18, as the P0-B plan proposes them, with no revision:

- **Cost:** at 1,000 triangles, the p95 added draw cost of the filled overlay is at most 16 ms.
  Added cost is the filled mode's frame interval minus the disabled mode's, on the same camera
  path, over five repeated paths after a warm-up. Ruby time inside `Overlay#draw` is recorded
  alongside, since it counts only marshalling and not the GPU.
- **Stalls:** no input-blocking stall over 100 ms attributable to the overlay, measured as the
  longest gap between UI-timer ticks during a path.
- **10,000 triangles** measures headroom and has no pass mark.
- **Correctness (Ed, native):**
  - fill is hidden by geometry in front of it;
  - hidden geometry is not filled;
  - alpha shows the Model through the fill;
  - clicking a face under the fill selects that face;
  - orbit stays usable.
- **Model unchanged:** materials, attributes and the Undo stack are the same before and after.

These are engineering screening criteria, not a product performance promise. Failure selects the
decision register's outline-only fallback and records which filled modes are unavailable.
