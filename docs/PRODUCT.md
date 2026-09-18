# Product shape

**DATE:** 2026-09-18

PassiveBuilder is a free, open-source authoring tool for Phius passive building models. The SKP
file holds the working building data. A consultant can enter every supported definition by hand,
assign it in the model, and export without an account or network service.

Everything below describes agreed product behavior. The predecessor, PH-Navigator for SketchUp,
settled most of it through recorded interviews between 2026-09-06 and 2026-09-17, and the rules
that did not depend on designPH carry over unchanged. Nothing here is implemented in this
repository yet.

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
inventories share Filter, Group by, Order by and Direction controls; filtering retains local
drafts and never changes the model or the export scope.

## Envelope

The user classifies faces with PassiveBuilder's own tool: face type, boundary condition and
assembly. A face inside a repeated component is shared by every occurrence, and independent
classification requires the user to make the parent unique first. PassiveBuilder never does that
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

A window unit is a flat component PassiveBuilder generates from its Window Type, with one face
per glazed element, glued to and cutting an envelope face. PassiveBuilder authors no window
shading; METr handles it after export.

Incomplete types can be saved and, with sufficient size and layout, assigned. Missing required
thermal inputs on assigned types block ordinary export. Unused incomplete types do not. Export
does not silently substitute values or omit windows.

Optional external evidence follows its owner: product photos on Window Types, datasheets on frame
and glazing records, installation photos and calculation reports on Psi-Install Types.

## Spaces

Spaces contain protected Volumes, and Volumes contain Floor Segments the user has classified as
iCFA. Creating a floor inside a Volume registers it; creating one at a Space root creates the next
Volume. Context changes reconcile and protect the structure. Native Save and Undo retain the
measured host contracts. The Spaces table has a filterable Level rail, saved column layout, range
edits and Locate.

## Handoff

Export produces HBJSON with an adjacent report explaining supported content and findings, and,
when requested, the METr model. Independent consumers decide how to view, review and calculate
it. Optional linked PDFs and photos remain in external project folders. Ordinary model use never
depends on those files.

## Delivery

The proposed scope is in [the PRD](PRD.md). Interview order and implementation readiness will be
in the planning folder once it exists. Public release scope is undecided and requires Gate A.
