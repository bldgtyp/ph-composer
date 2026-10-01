# P2-09: library file export, starter library, example provider

DATE: 2026-09-30
STATUS: Implemented on branch; named acceptance passes with qualified retained evidence; Phase 2 integration remains open.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-08. D2-9 is confirmed. Owns the three things that prove the seam is real for someone outside
the core: writing a library file from a Model, a small public starter library, and a provider
registered from outside. Closing it is milestone M2.

Behavior owner: [libraries PRD](../libraries/PRD.md), "Export model library to file", "Starter
library", "Validation and export" and Q11, Q15, Q17, Q19 to Q21; D6 in
[DECISIONS.md](../../../DECISIONS.md).

## Steps

1. **Export operation.** `ph_composer.library.export_file`: writes the Model's supported kinds as
   one library file. It uses each adapter's reverse mapping, never a raw dump of records or
   source snapshots. It admits only declared wire fields and a sanitized origin label and id.
   Credentials, addresses, local paths, evidence bytes, `user_data` and extension payloads are
   excluded. Settle with the architecture review whether it runs under the `export` capability
   or its own; it is a local file write and not a Model mutation, so it is not an action.
2. **Scope dialog (D6).** An explicit choice dialog. The default is all supported kinds. Selected
   records only is offered when a selection exists. Filters and hidden rows never define scope.
3. **Identity.** A new export gets a fresh library UUID. Updating an existing library file keeps
   that file's validated UUID. Save as a new library creates a fresh one. Each record is
   published under its own local id, with earlier source carried only as informational origin
   text. Source attribution on the Model's records is unchanged.
4. **Write safely.** Review the destination, the identity choice and the list of omitted fields,
   payloads and unsupported records before writing. Stage beside the destination and rename into
   place. A failed or cancelled write leaves an existing file intact. The destination comes from
   a native save dialog.
5. **Starter library.** Ten to fifteen generic records with round typical values, each citing a
   public source in its notes, named generically, CC0. No table transcribed from ISO 10456,
   ASHRAE or any other copyrighted compilation. Place it at `starter-library/` in the repository
   root (D2-9, confirmed 2026-09-30), add its CC0 notice, add the path to the RBZ exclusion list and a build check that proves it is absent from the package.
   Update `docs/LICENSING.md`.
6. **Example provider.** A tiny provider with a hard-coded list of Materials, in its own
   SketchUp extension, registering a second batch against the live registry after PH-Composer has
   composed. It runs the shared provider contract tests from P2-07. Its home is its own repository under
   `bldgtyp` (D2-9, confirmed 2026-09-30). Ask Ed to create it, or for his say to create it, when
   this stage starts; creating a repository is not covered by the stage's authorization. Develop
   it under `tools/examples/` first, loaded as a separate extension, then move it.
   Confirm registration does not depend on load order: loaded before PH-Composer it reports a
   clear diagnostic and does nothing; loaded after it registers.
7. **Contributor walkthrough.** Under `docs/`: the files a provider author writes, the contract,
   and the panel-closed sequence of list, preview Add to this file, apply and read back. Record
   the proven example in `context/EXTENSIBILITY.md`, "Evidence that the architecture is
   extensible".

## Tests (write first)

1. Export, read the file back through the file provider, and copy a record into a fresh Model:
   semantic fields and local record ids round trip.
2. Update the same file and export a new one: retained against fresh library UUIDs.
3. Selected scope, a filtered table and hidden rows: only the explicit choice decides.
4. Synthetic secret, address, path, `user_data` and extension fields never reach the file, and
   the omission list names them.
5. A write failure after staging leaves the prior file byte for byte.
6. The starter library passes the envelope reader with no warning, and the RBZ check fails if it
   is packaged.
7. The example provider passes the provider contract module; duplicate registration, an
   unavailable kind and an incompatible contract major each fail explicitly.

## Host gate

Fresh process: export a Model's library, add that file as a provider on the same machine, and
confirm In this file marks its records; install the example provider as a separate extension and
copy one of its records with no change to PH-Composer's files.

## Out of scope

Publishing back to any provider. A persistent cache. The window kinds (P2-15). The connection.

## Done when

- E09 has evidence in `evidence/p2-09-library-export.md`.
- The libraries packet STATUS records 2.2 as delivered and names what 2.4 and 2.5 still owe.

Current consolidation and provenance: [P2-17](../evidence/p2-17-acceptance.md#register-consolidation-at-f4f6576).
