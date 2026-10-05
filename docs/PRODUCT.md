# Product shape

**DATE:** 2026-10-01

PH-Composer is a free, open-source authoring tool for Phius passive building models. The SKP
file holds the working building data. A consultant can enter every supported definition by hand,
assign it in the model, and export without an account or network service.

Everything below describes agreed product behavior. The predecessor, PH-Navigator for SketchUp,
settled most of it through recorded interviews between 2026-09-06 and 2026-09-17, and the rules
that did not depend on designPH carry over unchanged. Phase 1 implemented Zones, face
classification and the HBJSON/report export described under Zones, Envelope and Handoff; assembly
assignment, local libraries, Window Type records, the Builder and Unit operations are implemented
and accepted on the Phase 2 feature branch for SketchUp 26.1.188 on macOS. Normal export
includes authored opaque constructions and Apertures. File libraries, Place, Schedule and
Window Type Colour-by pass their named current-host requirements. Connection libraries are Phase 5. Spaces and
thermal bridges remain proposed.

## The working environment

One persistent workspace combines the envelope classification tool, graphical assembly and Window
Type editors, local definition tables, the Space hierarchy, thermal bridge and equipment schedules,
piping and ducting workflows, model validation and Export. The predecessor shipped the Assembly
Builder, the Library, Window Types and the Spaces table; those transplant. Face assignment, window
placement and thermal bridges are new.

The Library is the one home for Materials and for Frames, Glazings and Psi-Install Types,
with an explicit model default for Psi-Install Types. The Assembly Builder opens inside the
Assemblies tab. The accepted Space hierarchy is Space, then Volume, then Floor Segment.

## Local definitions and optional reuse

Materials, assemblies, frames, glazings, Window Types, Space Types and equipment definitions are
created within the model. Library import copies a record into the model, where it remains
editable and available offline. Remote changes never silently replace working data.

A library sidebar sits beside the Assembly Builder and beside Library / Materials. Its source is
any library provider: a library file on disk, or a read-only connection to a server. First use
copies one record into the file and assigns it, or adds it without assigning; repeat use reuses
the editable local copy. The file stores attribution, never a server address or credential.

## Assemblies and materials

Partially built assemblies can be saved and reopened. Missing materials or properties withhold
U-values until required inputs are present. An assigned assembly that lacks required thermal
inputs blocks ordinary export; unused incomplete definitions and missing optional evidence do not.

A committed Assembly edit updates every assigned face without manual reapplication, with affected
uses visible. To change only some faces, duplicate and edit the assembly, then assign the new
definition to those faces.

Duplicating an assembly reuses its shared materials and datasheets and starts with empty
installation-photo collections.

Deleting an assigned assembly requires a replacement for all assigned faces, with affected faces
shown and cancellation available. Unassigned assemblies delete directly. Geometry remains intact.

Deleting an in-use material requires an explicit replacement for all its uses, with affected
assemblies shown and cancellation available. Replacement materials use their own datasheets.
Source files remain untouched. Deletion must not break references.

One model-local record represents a material across its assembly uses. Editing its properties
updates those uses. Thickness belongs to each assembly layer; conductivity, density and specific
heat belong to the shared material. Installation photos belong to a material within an Assembly
definition, shared across faces using that assembly.

Material categories are preset, shown as a muted colored chip, with Uncategorized available for
unfinished records. Each material has an editable display color used for its Assembly Builder SVG
fill, presentation only. Duplicate Material creates a separately named independent material, with
Copy datasheet links unchecked by default. Ordinary reuse never creates another material.

The Assemblies inventory shows one row per assembly with its attributes, thermal performance,
usage and validation state. The Builder edits the drawing through an always-visible toolbar and
anchored property bubbles. Total thickness and U-value stay visible in the header. Both
inventories share filter, Group by, Order by and sort direction controls (Zones / Faces sorts and
filters from its column headers instead); filtering retains local drafts and never changes the model
or the export scope.

## Zones

A Zone is one SketchUp Group, the geometry unit that becomes one honeybee Room. The user makes a
Zone from a selected Group or from loose geometry, and tags it with a Building-Segment and an
optional Level. Solve adjacencies pairs the faces two Zones share, cutting partial overlaps so only
the shared region pairs, in one Undo step. It runs only when asked, and validation offers it again
when a pairing goes stale. A copied Zone or a split face keeps its records; an explicit repair gives
the copy its own identity, and ambiguity is refused rather than guessed.

Make Zone and the Zone attributes are available from the selected geometry's native context menu.
The Zones / Faces header has no Make Zone button; use the native context menu to create a Zone.
The Zones / Faces selection bar offers Solve when at least two Zones are fully checked. A partially
checked Zone is excluded; fully checked Zones remain included when hidden by a filter. Checking
all Zones provides the whole-Model workflow. The native command solves selected Zones. A pairing
that would change an unchecked neighbour is refused with a message naming that Zone.
A Zone's name follows its Group name in Entity Info and Outliner. Clearing that name restores
the last valid name.

## Envelope

The user selects Faces, then sets one face type or boundary condition from the native context menu.
Existing Attached zones appear there; New attached zone opens a form for the captured selection.
The Classify tool also paints by click, drag or Shift-click across a connected plane, one Undo
step per gesture. In the Zones / Faces table, Type, Boundary and Assembly column menus show visibility checkboxes
and separate paint icons beside their values. A paint icon starts that field only, including values
not yet used in the Model. An active header paint icon names the value and stops painting when
clicked. Starting paint switches Colour by to the matching field; that view stays active after
painting stops. Attached zone painting uses Boundary condition Colour by. The Boundary menu also
offers Attached zone selection and a New attached zone route. Surface remains set by Solve adjacencies.
Suggest classification proposes a face type and boundary condition for each face of a Zone that
has no classification record yet, from its geometry.
Make Zone runs Suggest by default in the same Undo step. The tab's gear control stores the switch
and roof/floor tilt thresholds in the Model, initially 60 and 130 degrees. Settings changes can be
undone independently.
An Attached zone, such as a garage or attic, is a named boundary condition with its temperature
reduction factor. Colour by shows face type, boundary condition, Zone, Building-Segment, Level, Assembly
or Window Type on the model without changing its materials. The Zones / Faces screen is one table: each
Zone with its own fields as columns and its faces beneath, with Colour by, sorting and filters in the
column headers. Each column's Show choices filter the table and fade excluded geometry to grey while
Colour by is active. Filters combine across columns, and Clear filter restores that column's values.
The active Colour-by column's choices include colour swatches. Text search remains table-only.
Zone fields include all geometry in matching Zones. Face fields colour only matching Faces;
detached Window units have no matching Face and fade under those filters.
Filtering changes no geometry visibility, materials or saved Scenes. Faces checked in the table, or selected in SketchUp, are edited together from a bar
under the table. Locate frames faces and outlines them without changing the selection.
Assembly assignment is implemented with Assemblies on the Phase 2 branch. A face inside a repeated component is shared by every occurrence, and independent
classification requires the user to make the parent unique first. PH-Composer never does that
automatically. Unclassified faces are visible in validation and never silently exported.

Thermal bridges are identified on the model as edges, assigned a type carrying a psi-value, and
exported with their measured length. Point bridges and chi-values are outside the MVP. They can
return as later scope only after the canonical honeybee-ph artifact has a real carrier for them.

## Window Types and placement

Window Types describe exact size, layout, frames, glazing, operation, handedness and
perimeter Psi-Install Type assignments. Shared frame and glazing records hold product properties
and datasheets. Users define explicit installation variants by duplicating a Window Type and
changing its Psi-Install Type assignments. Every placement follows its type; there are no
per-instance installation overrides.

The graphical editor covers windows, doors, skylights and mulled units. An opaque door is entered
as a glazing with a g-value of 0.
Placement and resizing use sill center as the default fixed point; the user can choose another
anchor per unit, shown before changes and retained for later resizes.

A window unit is a flat component PH-Composer generates from its Window Type, with one face
per glazed element, glued to and cutting an envelope face. PH-Composer authors no window
shading; METr handles it after export.

Incomplete types can be saved and, with sufficient size and layout, assigned. Missing required
thermal inputs on assigned types block ordinary export. Unused incomplete types do not. Export
does not silently substitute values or omit windows.

Place starts with the chosen Window Type from the Builder, Type browser or Schedule. It previews
an outline on a host Face and stays active for repeated placements. Nine anchors are available.
In SketchUp's measurement box, `sill=<length>` sets the opening bottom above the host's minimum
up extent; `offset=<length>` sets the chosen anchor's inward distance from the nearest outer
host edge. Stop or Escape ends the tool.

The Schedule counts Unit occurrences by Type, including detached definitions, and shows Zone,
host Face, Level and Locate. Differing or unhosted Units retain their state and offer explicit
repair routes. Window Type Colour-by paints the generated panes through the shared drawing
service and respects hidden geometry and tags.

The Schedule shows net opaque host area: the gross host polygon minus the openings of glazed
elements. Empty panels leave opaque area intact. Uncertain native Window geometry withholds
the net value until repaired. Zones / Faces and assembly usage retain gross area.

Export maps each glazed element to an Aperture on its gross parent Face. Construction identity
includes product references and translated thermal values, including the element's size-dependent
U-w and resolved Psi-Install values. Shared internal edges carry Psi-Install 0; perimeter edges
use the assigned or model-default Psi-Install Type. The report lists installs by name and
gross, glazed and net host areas.

Exact g-values of 0 and 1 are preserved. The pinned honeybee-energy runtime accepts these
endpoints; honeybee-schema's simple glazing range excludes them. Local conformance permits
only this documented endpoint exception, and the Export report names each affected construction.
PH-Composer does not substitute a nearby value.

Optional external evidence follows its owner: product photos on Window Types, datasheets on frame
and glazing records, installation photos and calculation reports on Psi-Install Types.

## Spaces

Spaces contain protected Volumes, and Volumes contain Floor Segments the user has classified as
iCFA. Creating a floor inside a Volume registers it; creating one at a Space root creates the next
Volume. Context changes reconcile and protect the structure. Native Save and Undo retain the
measured host contracts. The Spaces table has a filterable Level rail, saved column layout, range
edits and Locate.

## Handoff

Export produces HBJSON with an adjacent report explaining supported content and findings. A
preflight lists blocking findings and offers repairs such as Solve adjacencies before anything is
written. The run can be cancelled, a failed replacement leaves the previous pair intact, and Export
never saves the SKP. The METr model is a later exporter, deferred until more of the building can be
authored. Independent consumers decide how to view, review and calculate
it. Optional linked PDFs and photos remain in external project folders. Ordinary model use never
depends on those files.

## Delivery

The proposed scope is in [the PRD](PRD.md). Interview order and implementation readiness are in
[the planning folder](../planning/ROADMAP.md). Public release scope is undecided and requires Gate A.
