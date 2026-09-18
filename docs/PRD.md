# PassiveBuilder

**DATE:** 2026-09-18 | **STATUS:** Proposed product scope. No code yet.
**OWNER:** Ed May, BLDGTYP

## Purpose

A free, open-source Passive House authoring environment inside SketchUp for Phius passive
building projects. The consultant defines the building while working with its geometry, keeps
the working data in the SKP file, and exports a complete HBJSON model. A second exporter converts
that HBJSON to the model METr reads.

Hand entry is the normal, complete workflow. No account, hosted project, remote library,
subscription or database service is required to author and export a supported model.

The project exists to be extended. BLDGTYP builds the foundation and the core patterns; anyone can
add a feature, a library provider or an exporter without touching the core.

## Product principles

- The SKP file carries authored definitions, instances, assignments and values, including unused
  definitions deliberately retained for this building. Moving the file to another computer
  preserves model authoring without resolving external library records.
- Bookshelfing copies a library record into the model. The user can edit that copy locally. Source
  attribution does not give a provider authority over the working model.
- Library providers are optional and interchangeable. A folder of files on disk, a firm's server
  and a vendor catalog all answer the same contract. None is a default the software ships.
- Geometry-linked work happens in SketchUp. Tables and graphical editors make non-geometric
  definitions and schedules equally accessible in the extension.
- Model validation explains problems with the authored building and its export. Certification
  evidence status, review conversations and project tracking belong downstream.
- User actions preserve clear references, explicit change scope, recoverability and native Undo.
- A supported feature includes a trustworthy export of its relevant data. Unrepresentable content
  is disclosed; storing something locally does not prove a downstream consumer can use it.
- The UI is a kit other teams can reuse. It carries no calculation and no honeybee dependency.

## People and jobs

The primary user is a Phius CPHC authoring a building model in SketchUp for METr. An individual
works entirely locally; a firm may curate shared starting definitions through a library provider.
A recipient uses HBJSON or the METr model without becoming an upstream authoring dependency.
BLDGTYP is the first internal user.

A second audience is contributors: consultants and developers who add a feature, a provider or an
exporter. The founding brief names the four seams they plug into.

## Proposed feature scope

In build order. The first four are what designPH provided in the predecessor and PassiveBuilder
must provide itself.

| Feature | User outcome |
| --- | --- |
| Face assignment | Classify envelope faces by face type and boundary condition and assign an assembly; stable through Undo, save and nested contexts |
| Assemblies and materials | Graphically build assemblies; enter or bookshelf materials; edit, rename, duplicate, delete and assign local definitions. Carried over from the predecessor |
| Window Types and placement | Compose Window Types from frames, glazings and Psi-Install Types; place and resize window units on envelope faces. Type authoring carried over; placement new |
| Thermal bridges | Identify linear and point thermal bridges on the model and assign psi-values and chi-values |
| Spaces and airflows | Author Spaces and Volumes, classify iCFA floors, assign Space Types and enter ventilation rates. Hierarchy carried over |
| Validation and export | Export HBJSON with actionable findings and stable identity; run the METr exporter |
| Optional library import | Reuse curated definitions from any provider as editable model-local copies. Carried over and generalized |
| Space Types | Maintain a local collection of reusable Space definitions |
| Equipment | Author ventilators, heat pumps, pumps, fans, hot-water tanks and heaters, electrical heaters and appliances |
| Piping and ducting | Describe measured runs and their system relationships using honeybee-ph concepts |
| Climate and site | PV and the site data METr needs. Window shading is METr's job after export |
| Optional linked evidence | Open and repair links from records to external PDFs and photos |
| Optional transmission package | Share a fixed model and its selected linked evidence together |

Agreed behaviors carried over from the predecessor's interviews, which still hold because they do
not depend on designPH, are in [PRODUCT.md](PRODUCT.md).

## Storage and portability

The SKP is the primary datastore for the authored building. Attribute dictionaries are the storage
mechanism, with the record pattern the predecessor settled. Local preferences and rebuildable
caches may live outside the model; they must not contain the only copy of building data.

PDF and photo bytes remain external. The model may store optional references to them. A missing
linked file does not prevent model editing, calculation or ordinary export.

## Integration boundaries

- honeybee-ph supplies the domain vocabulary and the typed export structures. Face types and
  boundary conditions are honeybee's; PassiveBuilder does not coin a third vocabulary.
- PHX converts HBJSON to the METr model. It runs inside the shipped runtime as the first exporter.
  The extension does not operate Excel and does not write PHPP.
- METr is the calculator. PassiveBuilder produces its input and claims nothing about its results.
- PassivSure is a sibling project building a PHI-focused designPH companion. It may reuse the UI
  kit and the record engine. It is not a destination for PassiveBuilder's output.
- PH-Navigator web is prior art for editors, tables and calculations, and one library provider
  among several. It is not a required service.
- The predecessor, PH-Navigator for SketchUp, is prior art and evidence. Its designPH integration
  is retired.

## Exclusions

No designPH integration, no PHI certification workflow and no PHPP export. No hosted datasheet or
photo storage, specification-status editor, certification roadmap, climate map, built-in model
viewer, review conversation or automatic model-version service. No HBJSON-to-SketchUp
reconstruction. Optional linked evidence is in proposed scope and adds none of those services.

## Current capability and release boundary

Nothing is implemented in this repository. The founding brief's transplant tables name what
arrives from the predecessor and in what state. SketchUp 2023 is the compatibility floor and
SketchUp 26.1.188 on macOS is the proving host. Windows support and public distribution are each
their own gate. The first public release subset is undecided.

## How scope becomes implementation

Review one feature at a time in short interview rounds. Each feature plan records seed stories,
unanswered decisions, actual answers and Ed's confirmation. Recommendations are not accepted
decisions. Only then write a detailed implementation plan and seek the separate instruction to
implement.
