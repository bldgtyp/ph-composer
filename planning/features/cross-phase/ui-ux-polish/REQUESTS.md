# UI and UX polish: request register

DATE: 2026-10-04
STATUS: Initial intake organized for planning; implementation not yet authorized.
ISSUE: none (local planning draft)

The delivery sequence is in [PLAN.md](PLAN.md), open choices in [DECISIONS.md](DECISIONS.md)
and verified progress in [STATUS.md](STATUS.md). The groupings below preserve the original
intake organization; PLAN owns the proposed PR boundaries.

## Purpose

Collect Ed's screenshots and notes across the current application, preserve each requested
change, and develop a bounded implementation plan grouped into logical PRs by affected area.
This is a new review, separate from the archived UI and UX refinement.

## Intake process

- Give each request a stable `UX-001` style identifier. Record the screen, current behavior,
  requested behavior, evidence reference, acceptance check, and any open decision.
- Preserve the owner's request separately from implementation suggestions. Mark reported
  failures as reported until reproduction or direct evidence establishes their consequence.
- Keep screenshot pixels outside tracked repository files, following the UI baseline policy.
  Reference an attachment or a private screenshot path; do not copy sensitive model data into
  this log.
- Group requests provisionally by area. Identify shared-component dependencies before fixing
  PR boundaries; avoid implementing the same pattern independently in several features.
- Track proposed changes to UI language, shared components, tokens and interaction rules.
  Promote accepted reusable rules into the polish skill and its pattern reference, and
  synchronize the Design System with merged kit changes.
- Once collection is complete, prepare the implementation scope, PR sequence and acceptance
  checks for Ed's go-ahead. No build work or separate implementation chat has started.

## Requests

### Session design direction, 2026-10-04

Ed explicitly asks for end-user-centered design and authorizes disagreement with proposed
solutions where clarity, intuition, flexibility or forgiveness would suffer. Progressive
disclosure is a core goal: show enough to orient and begin; reveal secondary information and
tools through submenus, subtabs, accordions, rollouts and contextual controls. Keep active
tool state, required decisions and recovery routes visible. Initial collection is complete for this planning checkpoint; the solutions
below are recommendations, not agreed implementation decisions.

### Zones / Faces batch 1

Evidence: attachments in this chat dated 2026-10-04. S1 = screenshot at 1.00.30 PM;
S2 = 1.01.28 PM; S3 = 1.02.50 PM; S4 = 1.09.48 PM; S5 = 1.13.50 PM.
Their filenames begin `Screenshot 2026-10-04 at` and end `.png`. Pixels are not tracked.
These are visual evidence, not an interaction reproduction or a native acceptance run.

#### UX-001: Recognizable settings gear (owner item 1)

- Request: replace the unusual Zones / Faces settings glyph with a conventional gear.
- Evidence: S1, settings tooltip and icon; also S2, S4, S5.
- Acceptance: a recognizable shared gear, consistent size and stroke, with tooltip and
  accessible name; existing settings behavior preserved.

#### UX-002: Success notice dismissal (owner item 2)

- Request: let informational success notices such as "Done." fade after about three seconds.
  Warnings and errors must not time out.
- Evidence: S2 shows the notice. Persistence is owner-reported, not reproduced here.
- Recommendation: distinguish disposable success confirmations from informational tool
  instructions. Only the former should time out; pause dismissal while hovered or focused,
  preserve manual dismissal and accessible announcement. Consider a meaningful short success
  message instead of generic "Done." where the action is otherwise unclear.
- Acceptance: success fades without reflow; warnings, errors and active instructions remain;
  repeated actions do not leave stale notices or dismiss newer messages.
- Rule delta: the current skill allows dismissal on the next meaningful interaction; an
  accepted success timeout will refine that rule, not apply to every `info` notice.

#### UX-003: Row hover instead of colored cell wash (owner item 3a)

- Request: remove the chip-colored cell hover fill; consider highlighting the whole row with
  the subtle interaction highlight.
- Evidence: S3 shows a washed Type cell beside the Boundary chip.
- Recommendation: a subtle row hover, with local focus/edit emphasis so the actionable cell
  remains clear. Hover, selection and invalid state must remain distinguishable.
- Acceptance: hover does not borrow the chip's category color, obscure its label, or hide
  selection; row treatment stays consistent across editable cells and row actions.

#### UX-004: Smaller semantic chips (owner item 3b)

- Request: smaller chip text and pills; use category colors rather than uniform gray, such
  as blue Outdoors and brown Ground, ideally matching the SketchUp scene palette.
- Evidence: S2, S3, S5 show the current tall neutral pills.
- Recommendation: reuse existing viewport category tokens where applicable, with light
  fills and readable ink. Compact visual pills should retain forgiving click targets and
  visible choice chevrons. Names carry meaning even without color.
- Acceptance: compact labels remain readable, long values fit at representative narrow
  widths, choice controls remain easy to activate, and category colors agree with their
  corresponding viewport mode. Missing and invalid states remain distinct.
- Open: exact palette and density, after checking existing category colors. Do not invent
  a competing palette before that check.

#### UX-005: Quieter grid and stronger Zone grouping (owner item 3c)

- Request: consider removing grid lines or retaining only subtle vertical separators;
  visually distinguish Zone groups from Face rows, possibly with a stronger group line.
- Evidence: S2 through S5 show the current grid and hierarchy.
- Recommendation: quiet Face rows and a restrained Zone header treatment; retain enough
  alignment and row separation for scanning and range editing. Compare reduced grid,
  group separators and subtle group backgrounds before settling the treatment.
- Acceptance: multiple Zones are easy to distinguish expanded or collapsed; columns,
  selection ranges and editable cells remain legible without excessive grid weight.

#### UX-006: Stable Colour-by surface and explicit filtering (owner item 4)

- Request: eliminate table movement/narrowing when Colour by opens. Explore a right overlay
  card, a dedicated row, or another disclosed surface. Improve "Show only this" and make
  the filtering behavior understandable; a modal is one owner-suggested possibility.
- Evidence: S4 shows the legend taking a right column, a narrower table and wrapped controls
  compared with S2. The resulting lost table space is directly visible.
- Recommendation: keep Colour by in a view-control group, separate from model-authoring
  tools. Explore an anchored nonmodal legend/filter card that leaves table geometry stable.
  Prefer nonmodal filtering so users can see and adjust the result; avoid covering the cell
  they are working on. Keep the active filter visible and offer a clear reset.
- Acceptance: opening, changing and closing the surface does not change table width,
  column widths or scroll position; current mode and filter are apparent; reset is obvious;
  dismissal and focus return work at wide and narrow panel sizes.
- Open: verify whether "Show only this" changes viewport visibility, table rows, or both
  before proposing exact words. Placement and overlay footprint remain undecided.

#### UX-007: Investigate ineffective Order by (owner item 5)

- Request: repair Order by, which reportedly does not change the table.
- Evidence: owner report only. No sorting failure reproduced yet.
- Investigation: use multiple Zones and Faces with deliberately different names and values;
  determine whether sorting applies to Zones, Faces within Zones, or both, and check direction.
  A one-Zone fixture may not expose Zone-only sorting.
- Acceptance: each supported order visibly changes an appropriate fixture; hierarchy stays
  intact, direction reverses the intended order, and any restricted scope is clear to users.

#### UX-008: Classify Faces as a coherent authoring tool (owner item 6)

- Request: polish the palette, reuse table chips, avoid layout disruption, and separate it
  from Colour by. Consider a slide-in card and a container with Make Zone and Solve adjacencies.
- Evidence: S5 shows the palette in the right column and its trigger beside Colour by.
- Recommendation: place the trigger with model-authoring tools; disclose a nonmodal palette
  using the shared semantic choices. Keep its active state, current choices and stop/escape
  route visible while the viewport tool is running. Reveal Attached-zone fields only when
  the chosen boundary needs them. Coordinate overlay behavior with UX-006.
- Acceptance: the trigger reads as classification, not visualization; chips agree with
  table labels and colors; opening does not resize the table; active state and cancellation
  are clear; classification, focus and transaction behavior survive.

#### UX-009: Authoring toolbar separate from settings (owner item 7)

- Request: Make Zone and Solve adjacencies become icon buttons in a toolbar, separated from
  settings. Include Classify Faces in the same conceptual authoring group (UX-008).
- Evidence: S1, S2, S4, S5 show the current heading actions.
- Recommendation: a shared grouped toolbar with conventional glyphs, tooltips and accessible
  names. Icon-only actions can be hard to discover, especially Solve adjacencies; consider
  short labels when space allows and explicit guidance in the empty state. Final density
  should follow recognition, not icon count.
- Acceptance: users can distinguish creation, classification, adjacency solving, view controls
  and settings; disabled actions explain their prerequisite beside the action.

#### UX-010: Shared contextual help/readiness surface (owner item 8)

- Request: consider moving `phc-icon-button assembly-tool-icon phc-blocked-reason` into a
  consistent bottom/footer location across pages, reusable for information and recommendations.
- Evidence: owner identifies the class; screenshots show an alert by the heading actions.
  Exact component ownership and content remain to be inspected.
- Recommendation: distinguish general recommendations from action-blocking reasons. A
  disclosed footer help surface may suit the former; keep a blocked action's reason close
  to that action so the user does not have to hunt for it. Reuse the underlying presentation
  without forcing every kind of feedback into one location.
- Acceptance: common help affordance and placement where appropriate; blocked actions retain
  immediate explanations; footer content does not reflow the active work surface or obscure
  controls, and persistent notices remain discoverable.
- Open: footer role and which information belongs there. Moving every blocked reason is not
  yet an agreed rule.

#### UX-011: Replace heading count with useful table/footer information (owner item 9)

- Request: remove `phc-heading-count`; consider a far-left number column and/or footer summary.
- Evidence: S1 shows Zones 0; S2, S4, S5 show Zones 1.
- Recommendation: place totals and filtered counts in a compact table footer. Add a leading
  number column only if it helps reference rows; a row index and a Zone total serve different
  purposes, and row numbers can change with sorting/filtering.
- Acceptance: heading count removed in agreed scope; users can find total and filtered counts;
  if numbering is adopted, its meaning and behavior for Zone/Face hierarchy, filtering and
  sorting are defined and do not imply a stable model identity.
- Open: whether removal is app-wide, and whether "number" means row index, Zone number,
  Face number or group count. Footer versus column remains undecided.

#### UX-012: Borderless hierarchy disclosure (owner item 10)

- Request: remove the border from controls such as `aria-label="Collapse Zone Zone 1"`.
- Evidence: S2 through S5 show boxed Zone chevrons.
- Recommendation: a borderless disclosure chevron with a forgiving target, visible focus
  treatment and expanded-state semantics. Review the repeated "Zone" in its accessible name.
- Acceptance: no resting border; expand/collapse remains obvious and keyboard-operable;
  hierarchy indentation and empty chevron slots remain aligned.

Owner item 11 is blank; no request inferred.

### Assemblies and Library setup batch 2

Evidence: attachments in this chat dated 2026-10-04. S6 = screenshot at 1.21.47 PM
(Assemblies inventory); S7 = 1.28.08 PM (Composer and predecessor Builders together);
S8 = 1.29.42 PM (Libraries modal). Same attachment naming convention as batch 1.

#### UX-013: Consistent Assemblies table (owner item 1)

- Request: apply the Zones / Faces table treatment to Assemblies: chips, lines, typography
  and density.
- Evidence: S6.
- Acceptance: one shared table grammar with UX-003 through UX-005; preserve inventory
  editing, actions, selection, sorting, units and missing-value feedback. Zone grouping is
  specific to hierarchical tables, not a reason to invent groups in Assemblies.

#### UX-014: Restore contextual insertion affordances (owner item 2)

- Request: restore edge-proximity plus controls: horizontal edges add layers, vertical
  edges add segments.
- Evidence: owner reports Composer controls missing; S7 shows the predecessor's "Add layer
  below" hover control. The static Composer screenshot cannot establish hover behavior.
- Acceptance: controls appear on the relevant eligible edge, offer clear above/below and
  left/right labels, remain reachable, insert the intended layer or segment and select the
  result; preserve unit-aware defaults, refusal explanations and one-step Undo. Check
  zoom extremes, edge intersections and unassigned segments.

#### UX-015: Restore dimensions and direct resizing (owner item 3)

- Request: restore dimension-line affordances for layer thickness and segment width editing.
- Evidence: S7 shows Composer value labels without the predecessor's dimension-line treatment;
  missing interactive resizing is owner-reported, pending reproduction.
- Acceptance: clear dimension lines and editable values on both axes, matching the audited
  precedent; SI/IP input, invalid entry, Enter, blur, Escape, Undo/Redo and stable zoom work.
  Verify labels remain legible and reachable with small segments and narrow panels.

#### UX-016: Detailed predecessor Assembly Builder parity audit (owner item 4)

- Request: carefully review
  `../../../../../ph-navigator-sketchup/src/ph_navigator_sketchup/features/assemblies/` for feature parity,
  especially add layer/segment, dimensions, resize, delete layer/segment and other affordances.
- Scope: inspect the Ruby command/model behavior together with the predecessor UI under
  `../../../../../ph-navigator-sketchup/src/ph_navigator_sketchup/html/`: `assembly_canvas.js`,
  `assembly_editor.js`, `assembly_editor_shared.js`, `assembly_stage.js`,
  `assembly_inspector.js`, `assembly_header.js`, `assembly.css` and related modules/tests.
  Ruby insertion/deletion owners include `features/assemblies/commands/layers.rb` and
  `commands/segments.rb`. Compare the corresponding current Composer owners.
- Deliverable: a source-referenced parity matrix, including trigger, visible state, command,
  consequence, recovery route and status (present, different, missing, intentional exclusion
  or not verified). Include assignment, split/merge, flip, copy/paint, selection, material
  picking, zoom/fit and Advanced affordances where the precedent provides them. Do not infer
  parity from matching button counts.
- Boundary: parity of applicable authoring behavior; retain Composer's accepted model,
  calculation and export contracts. Retired designPH push/adoption is excluded.
- Acceptance: every applicable affordance is accounted for; gaps have scoped fixes and
  behavior/host checks. Prior-art files located; detailed audit not yet performed during intake.

#### UX-017: Builder toolbar, film notes and semantic header chips (owner item 5)

- Request: closely review the predecessor's grouped toolbar, surface-film notes and nicer
  face-type/exposure chips, and bring that quality into Composer.
- Evidence: S7 compares the predecessor's composed toolbar and colored chips with Composer's
  dispersed controls and plain selects.
- Recommendation: reuse shared chip semantics from UX-004 and a coherent toolbar separating
  persistent view controls from selection-dependent edits. Preserve both Composer U-values.
  Keep exterior/interior film annotations associated with the drawing sides they describe;
  inspect the precedent before deciding their exact placement.
- Acceptance: clear visual hierarchy, compact grouped actions, contextual disclosure, stable
  layout and consistent chip vocabulary; film assumptions and missing thermal inputs remain
  available without a constant explanatory paragraph dominating the editor.

#### UX-018: Match predecessor Material Library layout and behavior (owner item 6)

- Request: match the predecessor Material Library as closely as practicable, including layout
  and behavior.
- Evidence: S7 shows the predecessor's collapsed left rail and Composer's expanded right
  sidebar. Expanded-state behavior is not demonstrated by this screenshot.
- Audit: inspect predecessor `library_sidebar.js`, `library_rows.js`, `library_drag.js`,
  `library.css` and Builder integration for side, fold/unfold, source chooser, search,
  categories, sorting, record details, Use/assignment and drag/drop.
- Acceptance: explicit comparison of those behaviors, agreed rail placement and initial
  state, preserved selected material, and usable wide/narrow layouts. Coordinate library
  disclosure with stable drawing scale and work-surface layout. Composer keeps its optional,
  interchangeable providers and editable local-copy semantics.

#### UX-019: Rebuild Library setup around the user's first task (owner item 7)

- Request: significantly simplify Libraries using progressive disclosure, hierarchy, grouping,
  spacing, icons and tooltips. The mix of Approve destination/file/folder and Add library
  file/folder is confusing.
- Evidence: S8 shows library configuration and agent location approvals together at equal
  prominence, with no configured libraries and five competing approval/add actions.
- Recommendation: lead with "Add a library" and one obvious entry route; reveal file versus
  folder choice within that flow. Show configured sources and their status once present.
  Disclose agent access separately only when relevant, explaining what an approval permits.
  Investigate whether native selection can complete the necessary approval within the
  add-library flow. Preserve the authorization contract rather than merely hiding prerequisites.
  Use icon buttons for familiar secondary actions; retain text on the first essential step.
  Tooltips should supplement visible guidance, not be its only location.
- Acceptance: a first-time user can choose a source, understand any required approval and
  see that the source is ready. Canceling a picker, failed loading, duplicates and unavailable
  sources leave a clear recovery route. No repeated or ambiguous approval/add steps.

#### UX-020: Library completion flow and shared modal contract (owner item 8)

- Request: clarify what happens after selecting a library file; currently the user reportedly
  returns to the same modal with no obvious completion step. Standardize all modals with a
  top-right X equivalent to Cancel, and bottom-right OK plus Cancel.
- Evidence: S8 shows only a bottom Close action alongside add actions. Return-to-modal
  behavior is owner-reported, pending reproduction.
- Recommendation: consistent dialog header, accessible X, focus return, Escape behavior and
  footer action placement across the app. Use action-specific confirmation labels (Add
  library, Save, Delete) where they explain the consequence better than OK. Read-only dialogs
  need Close; immediate-action managers need Done/Close; neither should display a Cancel
  that falsely suggests already-committed changes will be undone. Staged forms use Cancel
  and a clear commit action; X and Escape follow Cancel including dirty-draft handling.
- Open: does library configuration apply immediately or on confirmation? Inspect current
  behavior and decide whether success closes the add flow into the usable Material Library
  or returns to a manager with a clear success state and Done. Resolve before final wording.
- Acceptance: audit all shared and feature-specific modals; consistent layout and dismissal
  with honest commit/cancel semantics, keyboard submission, accessible labels and restored
  focus. Choosing a source gives an unmistakable result and next step; no dead-end manager.

### Windows batch 3

Evidence: S9 = attachment `Screenshot 2026-10-04 at 1.40.49 PM.png` in this chat,
showing Window Types and its toolbar. Library contents are not open in this screenshot.

#### UX-021: Carry shared Library improvements into Windows (owner item 1)

- Request: apply the same Library remarks as for the Assembly Builder.
- Scope: carry UX-018's layout/behavior comparison and UX-019/UX-020's source setup and
  dialog improvements into the Window Builder's product-library surfaces. Locate current
  entry routes during the audit; do not infer library state from S9.
- Acceptance: common library discovery, source selection, folding, record review and adding
  local copies use the same interaction grammar in both Builders. Preserve Windows-specific
  Frame/Glazing choices, assignments and relevant product details. Avoid separate fixes for
  shared library components.

#### UX-022: Window toolbar visual grouping (owner item 2)

- Request: polish `class="window-toolbar"` using spacing, dividers and colored chips so
  the controls read more clearly. No other Windows change requested in this batch.
- Evidence: S9 shows Exterior view, zoom controls, editing icons and Frames/Top choices
  sharing one toolbar with little visual grouping.
- Recommendation: group view/orientation and zoom separately from editing tools and their
  contextual settings, using restrained gaps and separators. Use shared chip styling for
  choices where appropriate; category color must communicate a defined meaning rather than
  decorate every control. Preserve distinct hover, selection and active-tool states. Keep
  settings beside the tool they configure; disclose them when relevant after inspecting
  their existing behavior.
- Acceptance: clear grouping, consistent heights and spacing, legible choices, tooltips and
  accessible names, stable active states and usable narrow layouts; preserve commands,
  focus, Escape, selection and Undo behavior. Reuse the Assembly toolbar vocabulary where
  the jobs match, without forcing different tools into identical layouts.

## PR grouping

Provisional, pending the remaining screens and dependency review:

| Area | Requests | Scope |
| --- | --- | --- |
| Shared feedback and help | UX-002, UX-010 | Success lifecycle; contextual help and action-readiness placement |
| Shared table presentation | UX-003, UX-004, UX-005, UX-011, UX-012 | Hover, compact chips, category palette, grouping, counts and disclosure |
| Zones / Faces workspace and tools | UX-001, UX-006, UX-008, UX-009 | Settings glyph, stable disclosed surfaces, view/authoring separation |
| Zones / Faces sorting | UX-007 | Reproduction, scope clarification and any necessary fix |
| Assemblies inventory | UX-013 | Adopt shared table presentation |
| Assembly Builder parity and composition | UX-014, UX-015, UX-016, UX-017, UX-018 | Audit first; insertion, dimensions, resize/delete, toolbar and Material Library |
| Library setup and shared dialogs | UX-019, UX-020 | First-use source flow, separate agent access, modal lifecycle and presentation |
| Windows library integration and toolbar | UX-021, UX-022 | Adopt shared Library changes; focused toolbar grouping and styling |

These are candidate PR boundaries, not a fixed sequence. Shared changes need checks on other
consumers; a confirmed sorting defect may be kept as a small independent fix.

## Design System and skill updates

The [PH-Composer UI polish skill](../../../../.agents/skills/ph-composer-ui-polish/SKILL.md) and its
[patterns](../../../../.agents/skills/ph-composer-ui-polish/references/patterns.md) govern this review.
The [Design System](https://claude.ai/artifact/77GLrkZxtkxo9TksTbvodL) is the private Claude
artifact identified by the skill; current access and artifact contents have not been checked.
Shipping stylesheets remain authoritative. Track synchronization as an explicit deliverable,
including any access limitation. The session's end-user and progressive-disclosure direction is
recorded above. Candidate rule updates from this batch: disposable success timing, stable
disclosed surfaces, row versus cell emphasis, compact semantic chips, Zone group hierarchy,
authoring/view/settings separation, contextual help versus action-readiness explanations,
count placement, borderless hierarchy controls, Assembly drawing affordances and toolbar,
Material Library layout across both Builders, source-setup disclosure, modal semantics and
toolbar grouping/shared chip semantics. Exact solutions remain open; the skill and
artifact have not yet been edited.

## Verification

Intake: focused document consistency checks. Implementation: focused behavioral and browser
checks, packaged-asset manifest refresh, repository gates, and native SketchUp checks for
affected interactions. Strengthen verification where a request changes model transactions,
public contracts or serialization. Define exact checks with each PR's scope.
