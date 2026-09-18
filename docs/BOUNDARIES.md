# Product and data boundaries

**DATE:** 2026-09-18

## Authored building

The SKP file owns the working model's definitions, instances, assignments and values. A library
supplies copies; it does not remain the authority for imported records. UI preferences and
rebuildable caches may be local to a computer but cannot be required to interpret the building.

## Envelope, spaces and windows

PassiveBuilder owns envelope classification, floor-area classification, window units and thermal
bridge identification, in its own attribute namespace, through its own tools. Nothing in the
model belongs to another extension. The predecessor deferred all of this to designPH; that
boundary is gone, and with it every rule about reading or writing another product's data.

## Export and consumers

Export writes HBJSON and its report. The METr exporter runs PHX on that HBJSON inside the shipped
runtime. The extension does not write PHPP or drive Excel. Producer defects remain here; consumer
defects remain with the reader. HBJSON carries only the fields honeybee-ph defines; native
product snapshots and full source evidence stay inside the model.

METr is the calculator and the destination. PassiveBuilder makes no claim about METr's results,
Phius's acceptance of a model, or certification.

## Library providers

A provider is optional and interchangeable. The software ships no default provider address. A
provider's records become editable local copies; the provider keeps no authority over them.
Shared curation is not live multi-user editing of an SKP. A credential or server address never
enters the model, a log or an export.

## Sibling projects

PassivSure is building a PHI-focused designPH companion. PassiveBuilder encourages reuse of its UI
kit and record engine there, under the repository license. PassivSure is not a destination for
PassiveBuilder's output and PassiveBuilder does not read PassivSure's.

PH-Navigator web is prior art for editors and calculations, and one library provider among
several. No web service shutdown or production-data migration is authorized here.

The predecessor, PH-Navigator for SketchUp, is prior art and evidence.

## Evidence files

The extension may associate records with external PDFs and photos, open those files and help
repair missing links. The bytes stay in user-managed folders. Removing a link must not delete the
source file. Missing evidence must not block building-data operations.

The extension does not host files, judge certification-document completeness, or own a
certifier's accepted evidence folder. A package is a handoff snapshot, not a version service.

## Outside the product

Hosted evidence storage, specification status, certification roadmap tracking, review notes,
model-version history, climate map interfaces and a separate desktop application belong outside
the extension. Climate-dependent moisture screening is a possible future feature, not present
scope.
