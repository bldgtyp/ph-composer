# P2-09 evidence: library export, starter and outside provider

DATE: 2026-10-01
STATUS: In implementation; focused starter proof recorded, export and outside-provider gates open.

The export command is being added as a generic registered FileExport under the existing export
grant. It carries no Model mutation sequence or Undo operation. The public interface accepts
explicit all/selected scope and new/update identity, while native save and review controls own
the destination. Reverse mappings publish local IDs and only declared wire properties. An
optional `record_origins` envelope section carries informational allowlisted source IDs and a
provider-kind label, never private setup or source snapshots. The reader ignores this section;
semantic fingerprints remain unchanged. Implementation and independent review are still pending.

## Starter data

`starter-library/materials.json` contains twelve generic records with authored notes and public
source links. Insulation conductivities are rounded SI conversions of nominal DOE guidance,
with aging and temperature limits stated. Gypsum values are rounded means from original NIST
room-temperature measurements. Unknown density, specific heat and emissivity remain null.
No licensed corpus or compiled ISO/ASHRAE table was used; source PDFs are not committed.

The actual registered Material adapter and file provider admit all twelve rows without warnings
or unavailable kinds. Ruby 2.7.2 and 3.2.2: 1 test, 92 assertions, no failures. The focused
archive suite passes 15 cases, including rejection of starter-library data under the extension.
The authored data has its separate CC0 notice and is excluded from the RBZ; licensing
documentation distinguishes it from the AGPL code. Full integrated gates are still pending.

## Resume

Complete export projection/write/round-trip tests and coherent independent review. Prepare the
separate-extension example under tools, prove load-order diagnostics and shared provider contract,
then integrate the explicit panel scope/identity choice and native export/read-back proof.
Ask Ed for the external repository creation only after the local example is reviewable, with the
other manual items at the end. No external repository has been created.
