# P2-13: Place tool, Schedule and the Window Type Colour-by mode

DATE: 2026-09-30
STATUS: Implemented, reviewed, full offline gates passed and installed. E13 current-host acceptance passes.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-12, P2-11, D2-2 and D2-6. Owns the user routes onto P2-12's operations: the Place
tool with its panel side, the Schedule subtab, and the Window Type Colour-by mode.

Behavior owner: [window-types PRD](../../window-types/PRD.md), sections Place and "Schedule and
seeing windows in the model". Tool rules: `context/EXTENSIBILITY.md`, "Viewport tools". Load the
UI polish skill first.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **Pick point (G8).** Extend `core/pick.rb` to answer the point on the picked Face with the
   Face path, in one call. It names no feature.
2. **Place tool.** A `Sketchup::Tool` in `features/windows/`, held as session feature state,
   following every rule in "Viewport tools": pick and never walk; call `units.place` through
   `API.invoke` with its own caller handle; open no operation itself; freeze the chosen type,
   anchor and revision at button-down; report results and refusals to the status bar and the
   session notice; cancel on Escape, deactivation, a suspended context and a raised callback.
   Hover draws the unit's outline at the anchor from P2-12's pure plan. Click places. The tool
   stays active for the next unit. Adapt `placement/placement_tool.rb`.
3. **Measurement box.** While the tool is active, typed input sets a sill height or an offset
   from the nearest host edge, parsed with the Ruby length reader the foundation already has.
4. **Routes in.** View commands `place_tool.choose` and `place_tool.stop`, the `place_tool`
   snapshot section, and menu items. Place starts from the Builder header, the type browser and
   the Schedule with the type already chosen. Per D2-2, a right-click item on a selected Face
   starts the tool with that Face as the host.
5. **Panel side.** The chosen type, the nine-anchor picker, the measurement hint, and a Stop
   control shown only while the tool has the viewport. Replace the Builder's disabled Place.
   Rewrite the "Before placing" alert without its designPH steps.
6. **Schedule.** The third Window Types subtab: types with counts, expandable to units with Zone,
   host Face, Level and Locate, and unhosted and differing units listed with their state and
   repair action. Counts come from unit records. Adapt `assign/schedule.rb` and
   `html/window_schedule.js`. Add the `units.locate` view command.
7. **Colour-by.** Register `by_type` through `colour_mode`: the entity is the unit instance, the
   value is the Window Type, the path is the unit's occurrence path. Pane outlines come from the
   service. No operation marks (D2-6, confirmed 2026-09-30).
8. **Preview and manifests.** Fixtures and checks; regenerate both manifests.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/windows/placement/placement_tool.rb`, `reviews/placement_session.rb` | 255 | Adapt to the tool rules |
| `features/windows/assign/schedule.rb`, `html/window_schedule.js` | 347 | Adapt to PH-Composer's own units |
| `features/windows/panel/overlay/` | 397 | Replace with one `colour_mode` registration |

## Tests (write first)

1. The tool sends exactly one `units.place` per click, with the frozen type, anchor and revision;
   a palette change mid-gesture does not change what is written.
2. Escape, deactivation and a raised callback each leave nothing written and no Undo entry.
3. A refusal reaches the status bar and the session notice.
4. Typed sill height and edge offset change the placed position by the typed amount in metres,
   in SI and IP display.
5. The Schedule lists a detached definition's unit under its type, and each differing unit with
   its state.
6. `by_type` registers with no change under `colour_by/`.

## Host gate

Fresh process, with Ed at the mouse for the gesture checks: place on a wall and on a flat roof
by hover and click; type a sill height; place three in a row without restarting the tool;
attempt a paired Surface Face, a Face in no Zone and an overhang and read each reason; Escape
order; Model switch during an active tool; Locate from the Schedule into a nested Zone; the
Colour-by mode on and off with a hidden tag.

## Out of scope

Operation marks in the viewport. A toolbar button. Reveal geometry.

## Done when

- E13 has evidence in `evidence/p2-13-place-tool.md`, with the UI polish review recorded.
- `context/EXTENSIBILITY.md` names Place as the second viewport tool. `make ci` and
  `make ui-checks` pass.

## Implementation checkpoint, 2026-10-01

Place, Schedule, Pick point and Window Type Colour-by are implemented and installed. The strong
independent architecture/UI review findings are closed. Full CI passes on Ruby 2.7.2 and 3.2.2,
coverage passes and all browser checks pass. Current native controls verify measurement parsing,
Escape, Schedule contents, starting Place and Locate into a translated nested Zone. Actual
canvas placement and viewport acceptance remain blocked by the computer-use controller.
See [source, verification and prepared manual batch](../evidence/p2-13-place-tool.md).

The initial anchor follows the PRD's `sill_center` default. Placement requires valid dimensions;
incomplete thermal/product inputs remain export concerns. Measurement entry uses SketchUp's
native length parser because the planned Ruby foundation reader does not exist. Click the native
Measurements field before keyword input to avoid SketchUp global letter shortcuts. `sill=` is
the opening bottom above the host's minimum up extent; `offset=` is the chosen anchor's inward
perpendicular distance from the nearest outer host edge. Exact placed offsets remain a host gate.
E13 is open and P2-14 has not advanced past this required dependency.

## Final host acceptance

E13 passes after Ed's actual native gestures and exact bridge readback, including the final
overhang refusal with unchanged authoring state. See the final section of
[P2-13 evidence](../evidence/p2-13-place-tool.md). Earlier checkpoint notes describe the
frontier at that date. P2-14 is now authorized to enter.
