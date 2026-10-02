# Libraries: behavior contract

DATE: 2026-09-30
STATUS: Scoped. Interviewed 2026-09-18; 21 decisions recorded, Q21 confirmed by D6. Architecture corrections incorporated. Amended 2026-09-30 for what Phase 1 merged. [PLAN.md](PLAN.md) allocates the work to Phase 2 stages.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Amendments after Phase 1

Proposed 2026-09-30. Rows that restate what the merged code does are facts. Rows that cite a D2
decision or a recommendation are proposals and govern only once Ed confirms them; until then the
body stands. The reasons are
in the Phase 2 [DECISIONS](../phase-02-envelope/DECISIONS.md), and the names in [CONTRACTS](../phase-02-envelope/CONTRACTS.md).

| Body text | Reads as |
| --- | --- |
| "local revision" in the request binding | The Model session revision plus `expected_values` on the records a proposal touches. There is no per-record revision |
| "A Libraries section in preferences" | The shell's preference store is closed to features and holds display preferences only. Provider setup is a per-machine store inside the library seam, opened from "Library setup..." through native dialogs |
| Provider and kind registration | Two new registry methods, `library_provider` and `library_kind`, with the registry's existing diagnostics. Neither exists yet |
| Loading or refreshing a catalog, adding or removing a provider | A change to session state that writes nothing to the Model. It is not an action. Recommended verb: a view command, settled in P2-07 |
| "PLAN.md sets and tests those limits" | Proposed in [PLAN.md](PLAN.md): 64 MB and 20,000 rows per provider, confirmed by measurement in P2-07 |
| The starter library as "a separate download from the project site" | No project site exists. Until one does it lives at `starter-library/` in this repository, CC0, excluded from the RBZ (D2-9, confirmed 2026-09-30) |
| The example provider "in its own repository" | Needs a repository Ed creates or authorizes (D2-9, confirmed 2026-09-30) |
| The connection as the second provider | Planned last, as P2-16, and may move to Phase 5 (D2-8, confirmed 2026-09-30) |
| The sidebar "beside the Builder" | Its shared modules and In this file source land with the Builder in P2-04; provider sources follow in P2-08 |

## Problem

A consultant does not retype mineral wool's conductivity or a window manufacturer's frame values
on every project. The predecessor solved this for one source: a sidebar beside the Assembly
Builder and the Library inventories that browses PH-Navigator web's catalog, from an exported file
or a signed-in connection, and copies one record at a time into the model as an editable local
copy with attribution. It shipped for Materials, Frames and Glazings, and it passed against
production.

It was written for one vendor. Each record kind's adapter names PH-Navigator as its provider, its
catalog URL path and its file format in constants. One source can be open per kind. PH-Composer
promises the opposite: a folder of files on disk, a firm's server, METr's catalog, PassivSure and
PH-Navigator are equal, none is required, and no address ships in the code. This packet keeps the
predecessor's user-facing behavior almost unchanged and separates the two things its adapters
fused.

## Port disposition

Measured on the predecessor at `f358ebf`: `features/organization_library/` is 1,139 lines of Ruby.
Behavior detail lives in `../ph-navigator-sketchup/planning/archive/shared-material-library/PRD.md`.

| Part | Lines | Disposition |
| --- | --- | --- |
| `organization_library` (actions, snapshot, in-file projection), `store` | 181 | Adapt. Keyed by provider and kind, not kind alone |
| `catalog_file` (envelope checks, row normalization, size limit, skip with warning) | 166 | Adapt. Reads PH-Composer's library file format |
| `kinds/kinds`, `kinds/materials`, `kinds/window_products` | 328 | Split. The field mapping, fingerprint and in-file projection stay a kind adapter. The provider name, library id, URL path and file kind leave it |
| `connection`, `transport`, `credentials` | 464 | Port as the connection provider. The address is entered by the user and nothing is prefilled |
| Panel: sidebar, source selector, details bubble, drag and drop, "In this file", same-name review | not counted | Port |

## Decision

- There are two contracts. A **library provider** says where records come from. A **record kind
  adapter** says what a record of one kind looks like on the wire, how it becomes a model-library
  record, and how a local copy is recognised. Any provider can serve any kind.
- PH-Composer sets one neutral format and providers accommodate it (Q5). The same JSON
  envelope is the library file on disk and the response of a connection, so a static file host is
  a valid server (Q6). No translator for any vendor's format lives anywhere in PH-Composer.
- The core holds two providers. The **library file** comes first. The **generic connection**
  comes second: the user types an address and signs in the way that server declares. PH-Navigator
  is one such address, optional, for a user who has an account there, and PH-Navigator changes its
  endpoint to fit. A firm's intranet library is another. Nothing specific to any vendor exists in
  the code, and no address ships (Q7, Q16).
- The first pair, file then PH-Navigator connection, exists to establish the patterns, contracts
  and infrastructure every later provider uses (Q7).
- Four record kinds: Materials, Frames, Glazings and Psi-Install Types. Assembly, Window Type and
  equipment libraries may follow and are outside this packet (Q2).
- Every copy is an editable model-local record with source attribution. The provider has no
  authority over it, nothing updates automatically, and the file never needs the provider again.
- The SKP stores attribution only: provider name, library id, record id, revision, fingerprint,
  copy time and an allowlisted source row snapshot. It never stores a connection address, a local
  path or a credential. Arbitrary provider fields are not admitted through the snapshot.
- Everything on the wire is SI with the unit in the key name. IP exists only in user-facing
  display and entry (Q14).
- The user-facing rules from the predecessor's interviews carry over: copy one record on first
  use, reuse the local copy after, same-name review, "In this file", add without assigning,
  session-memory catalog, clear connection states.

## Vocabulary

Already in `context/UBIQUITOUS_LANGUAGE.md` and used as written: **Model library**, **Library
provider**, **Library record**, **Bookshelfing**, **In this file**, **Source attribution**,
**Definition source**. New terms:

| Term | Meaning |
| --- | --- |
| Library file | A library provider that is a JSON file, or a folder of them, on disk |
| Connection | A library provider reached over HTTPS with a read-only grant |
| Record kind | One type of definition a provider can publish. Four in this packet: material, frame, glazing, Psi-Install Type |
| Record kind adapter | The code that maps one record kind between the wire shape and the model-library record |
| Library sidebar | The collapsible panel beside an inventory or editor that browses one provider's records of that kind |
| Starter library | A small CC0 library file of generic records, downloaded separately from the project site |
| Source review | The blocking comparison shown when a library record and a same-name local record disagree |

On screen, the tab stays **Library** and the sidebar's heading names the provider, as the
predecessor does: "Library: BLDGTYP shared". "Library provider" appears only in docs and
preferences. The word "organization" goes, since a provider may be a vendor or a folder (Q1).

## The two contracts

```
Provider                                   Record kind adapter
  id            configured-provider id;       kind           "materials"
                never a path or address        wire_fields    names, types, SI units
  label         shown in the sidebar         map(row)       wire row to model-library record
  kinds         which kinds it serves        fingerprint    hash of the mapped fields
  list(kind)    every row, every field       in_file(local, rows)   the "In this file" projection
  freshness     export date or load time
```

- Rows arrive in the same wire shape from every provider. The kind adapter never learns which
  provider it is talking to.
- Source identity is the tuple `(provider kind, library id, record kind, record id)`. A file path
  or connection address is never identity and never enters the SKP. Provider configuration has a
  separate per-machine id so two files or two connections can be open at once without collision.
- A library id must be stable across exports. Duplicate record ids within one library and kind are
  refused as ambiguous; they never collapse to the first row. This check spans every file in a
  folder, not just each envelope. Refuse the affected library/kind catalog rather than silently
  choosing by directory order. Different library ids retain separate provenance in the folder view.
- `provider kind` is a stable registered contract identifier, not its label or configuration id.
  Two configurations serving the same tuple refer to the same source; different provider kinds,
  including file and connection, do not become identical just because record ids match. Cross-source
  reuse follows the explicit same-name/value rule below. A library publisher owns a unique stable
  library id; conflicting content claiming the same identity is reported, never merged arbitrarily.
- There is no per-record fetch. The list carries every field, as the predecessor's does, so a
  copy needs no second request (Q6).
- With four bare kinds no record depends on another, so the contract has no dependency rule. A
  later Assembly or Window Type library adds one, and each dependency then goes through its own
  kind's reuse rule so a bundle never makes a second copy of a material already in the file.
- Adding a record kind is one adapter file plus the owning feature handing over its local
  records through public queries and mutation operations. Adding a provider adds its implementation
  and explicit registration. Neither needs provider-specific branches in a kind or kind-specific
  branches in the shared library orchestration. This is the second of the four contribution seams.
- A contributor's provider lives in its own repository and registers from a separate SketchUp
  extension (Q11). Since PH-Navigator needs no code of its own, a tiny **example provider**, a
  hard-coded list of records in its own repository, is the contributor template and the test that
  outside registration works without a core change (Q17).

### Registration and mutation ownership

These are required contracts, not implemented APIs. Each registration declares a stable id,
contract version, capabilities and dependencies. Diagnose duplicates, missing dependencies and
unsupported versions explicitly; outside registration must not depend on incidental load order.
Q11 authorizes a separately registered example provider, not a dynamic loader or marketplace.

Providers list immutable catalog values and never read or write model dictionaries. Kind adapters
own pure wire validation, mapping, semantic fingerprints and a reverse projection for library-file
export. The feature owning each record kind supplies public local-record queries and validated
create, replace and assign operations. The library coordinator prepares a proposal and invokes
those operations under one caller-owned transaction. Copy plus assignment is atomic; an assignment
failure rolls back the new definition too. No transaction remains open during network access or review.

List/details/in-file queries never copy, repair or open a review dialog. A review-required result
returns structured candidates and differences. UI and scripts submit the same explicit choice
to apply it. Requests bind to the model session, local revision, assignment occurrence references
and immutable catalog generation; commit rechecks them and refuses stale proposals without writing.
Reuse the foundation retry/idempotency contract so a lost response cannot create another copy.
Return affected local ids, assignments, findings and the resulting revision for read-back with
the panel closed. External adapters carry no provider or record-kind business logic.

Representative contributor task: add a synthetic provider serving Materials through registration,
then use public queries to list a row, preview Add to this file, apply it and read the resulting
record with the panel closed. Only the provider implementation, registration and contract tests
are new; the existing Materials adapter and model operations are reused. PLAN.md names the actual
entrypoints and includes this example beside the separately registered extension walkthrough.

## The library file

One JSON envelope that may hold many kinds. A folder provider reads every such file inside the
folder (Q3):

```
{
  "format": "ph-composer.library",
  "schema_version": 1,
  "kind_schema_versions": { "materials": 1, "glazings": 1 },
  "library": { "id": "bldgtyp-shared", "name": "BLDGTYP shared library" },
  "exported_at": "2026-09-18T14:00:00Z",
  "kinds": {
    "materials": [ { "id": "...", "name": "...", "conductivity_w_mk": 0.04, ... } ],
    "glazings":  [ ... ]
  }
}
```

- Every number is SI and its key names the unit, as `conductivity_w_mk` does. A value in IP is
  refused, never guessed (Q14).
- Material categories use the thirteen published ids. An unknown id imports as Uncategorized with
  the original kept in the snapshot (Q13).
- Field names and units are the model-library record's own, so the format is documented by the
  record schemas and a contributor can write a file by hand.
- Record ids are the provider's and must be stable across exports. Reuse depends on them.
- Envelope validation precedes row normalization. Unsupported envelope versions refuse the file;
  unknown kinds are reported as unavailable and skipped without preventing supported kinds from
  loading. Each kind declares its supported wire schema version and migrations. No version is
  inferred from field names and no unsupported version is coerced into the current schema.
- A malformed required field, id, unit or number skips that row with a structured warning. Only
  optional fields whose schema permits absence may become absent with a warning. Never null a
  required property into an apparently usable record. The documented category fallback remains
  the explicit exception. Missing, invalid, unsupported and unavailable are distinct outcomes.
- The 32 MB limit applies to each file and connection response. A folder reads only its immediate
  JSON files; unrelated files are ignored and malformed candidate files are reported. Enforce a
  bounded aggregate catalog budget and row count as well; PLAN.md sets and tests those limits.
  An over-budget catalog is refused, never presented as complete after silent truncation.
- Publish a new immutable catalog generation only after validation. Failed refreshes retain the
  last valid generation with its age and failure state visible; an empty successful response is
  distinct from failure. No copy can mix rows or fingerprints from different generations.
- The format is public and versioned. It is the easiest thing for an outside team to produce, so
  it is the real interface of this seam.

## Behaviors

### Carried over unchanged

From the predecessor's shared material library interviews. Not reopened here.

- The sidebar is collapsible, groups by category, sorts by name, searches name, manufacturer text
  and comments, and keeps its expansion, search and scroll through an assignment. Opening it never
  resets the editor beside it.
- Opening a record's details never copies it. The details bubble separates copied properties from
  source-only information and names the library and the manufacturer separately.
- First use copies one record and assigns it, as one Undo step. **Add to this file** copies without
  assigning. Drag and drop is the primary route and select-then-apply is the keyboard route.
- A record with a local copy shows **In this file**, muted, and using it takes the local copy.
- Same-name records reuse only when their mapped values agree. A difference opens the source
  review: Cancel, Use local copy, Use library copy. Replacement keeps the local id and evidence and
  updates every use. No silent suffixing, and multiple same-name local matches are refused.
- An unknown category copies as Uncategorized, with the original kept in the snapshot.
- The catalog lives in session memory only. A list loaded earlier still serves copies after the
  connection drops. Nothing of a provider's is cached to disk.
- Connection states are distinct and named: signed out, waiting for approval, denied or expired,
  loading, connected, no results, offline, access revoked, library file open.

### Copy, reuse and replacement rules

Resolve exact source identity before same-name matching. Zero exact local matches proceeds to the
same-name rule; one reuses that local record even if it was renamed or edited. More than one is an
ambiguous-source result: show the candidates and require an explicit local choice, never the first
match or an additional import. The In this file projection uses the same resolver and distinguishes
unique reuse from ambiguity. Choosing one does not delete or merge other records.

With no exact match, zero same-name matches permits creation; one with equal normalized mapped
values permits reuse; one with different values requires source review; multiple matches require
explicit resolution. Cross-source reuse does not overwrite existing attribution merely to make a
badge appear. Only an explicit replacement adopts the incoming source attribution. Fingerprints
have a declared version and canonical field/unit ordering, and cover mapped semantic properties,
not timestamps, labels of the configured provider or arbitrary metadata. Comparing fingerprints
from incompatible versions requires recomputation or an unavailable comparison, not a change claim.

Use library copy replaces only the reviewed mapped fields of the chosen local record, preserving
its local id, existing references, evidence, `user_data` and structured extension payloads. It updates
the approved attribution snapshot in the same transaction. A field or extension version that cannot
be edited safely refuses replacement without dropping data. Incoming metadata is never merged over
local metadata implicitly. New copies admit only schema-declared data; source-only fields stay in
the sanitized attribution snapshot when allowed, otherwise their omission is disclosed.

Unavailable-extension payloads already in the model remain intact through ordinary edits and
save/reopen. Preservation does not validate them or permit their export. Kind-owned validation
decides whether missing extension capability affects the record's use or canonical export.

### Changed by the pivot

- **Providers are set up by the user.** A Libraries section in preferences lists configured
  providers: add a library file or folder, add a connection, remove one. Address and credential
  entry use host-owned setup controls so neither passes through the HtmlDialog protocol.
  Nothing is listed on first run. Setup is per machine and never stored in the SKP.
- **Several providers at a time.** The sidebar's source selector lists every configured provider
  that serves the current kind, plus **In this file**. The user switches between them and pulls
  records into the SKP. One is shown at a time and there is no merged view (Q4).
- **Attribution names the provider generically.** The definition source kind is `library`, as the
  ubiquitous language already records, replacing `organization_library`.
- **Source changed.** While a provider is loaded, a record whose source fingerprint moved since it
  was copied shows a quiet mark in the inventory. The source review opens on request. Nothing
  updates automatically and nothing blocks (Q8).
- **Export model library to file.** Writes the model's Materials, Frames, Glazings and
  Psi-Install Types as a library file. An explicit choice dialog defaults to all supported kinds
  and offers selected records only when a selection exists. Filters and hidden rows never define
  export scope. It is a local file write and involves no provider. Each record is published under
  its own local id, with earlier source carried only as approved informational origin text
  (Q15, Q20, Q21). A new library export receives a fresh library UUID. Explicitly updating an
  existing library file retains that file's validated library UUID; Save as a new library creates
  a fresh one. Paths do not define identity and source attribution on model records is unchanged.
  Review the destination and identity choice before writing; failed or cancelled writes leave an
  existing file intact. This is local file export, not publishing back to a connected provider.
- **Starter library.** A separate download from the project site, never in the RBZ. Ten to fifteen
  generic records with round typical values, each citing a public source in its notes, none
  transcribed as a table from ISO 10456, ASHRAE or any other copyrighted compilation. Named
  generically, licensed CC0 (Q9, Q19).

### The connection protocol

Written up as a one-page spec in `docs/` when this packet is planned (Q6, Q18).

| Request | Returns |
| --- | --- |
| `GET /library` | The library's id, name and the kinds it serves |
| `GET /library/<kind>` | The library file envelope for that kind |
| Auth discovery document | The sign-in method the server uses |

- Read only. No write endpoint exists in the spec.
- Three sign-in methods, declared by the server: **none**, for a public or intranet host;
  **static token**, typed into a native Ruby input box; **device-code approval**, where the
  extension opens the browser, the user approves and nothing is typed. PH-Navigator keeps
  device-code.
- In every method the credential goes to the machine's credential store and never crosses the
  panel boundary.
- HTTPS or loopback only, per `context/TECH_STACK.md`. An intranet library on plain HTTP is
  refused; the firm serves it over HTTPS or mounts it as a folder and uses the library file.
- Discovery and list results carry configuration revision and catalog generation. Ignore late
  responses after reconfiguration, removal or session disposal. Network callbacks publish catalog
  state through the host-safe boundary and never apply model mutations or open the panel.
  Separate cached availability from access state: a previously loaded generation remains usable
  during an ordinary offline failure; explicit access revocation or provider removal discards that
  provider's session catalog. Existing model-local copies remain usable independently.

### Security rules

Carried from `context/TECH_STACK.md` and restated only as the list a reviewer checks: HTTPS or
loopback only; a credential or address never reaches the panel, a log, the SKP or an export; a
catalog body that echoes the token or the address is refused; macOS Keychain through one
short-lived process with the secret as an argument. Windows credential storage is unproven and is
its own gate (Q7).

### Validation and export

A provider never appears in validation. A copied record is a local record and is validated as
one. Export writes no provider data beyond what the record kinds already export. The Export
report lists, per copied record, the provider and record id it came from, never an address or a
path (Q10).

Library-file export uses each adapter's declared reverse mapping, not a raw dump of model records
or source snapshots. Admit only supported wire fields and sanitized origin labels/ids. Exclude
credentials, connection addresses, local paths, evidence bytes and arbitrary metadata by default.
Namespaced metadata or structured extension data needs an explicit versioned export mapping and
privacy declaration before inclusion. Disclose omitted fields, payloads and unsupported records
before committing the file. Local copies remain unchanged. The supported round trip preserves
declared semantic fields and published ids, not every local field or the original source identity.

The feature owning the local record contributes permitted attribution to canonical translation
and the Export report through its registered declarations. Export never loads a provider or asks
the library sidebar for state. Library-file serialization is a separate record interchange operation;
HBJSON exporters still consume HBJSON alone.

## Non-goals

Publishing or writing back to any provider. Editing a provider's records. Automatic or batch
updates from a provider. Importing a whole catalog. A persistent offline cache. Hosted evidence,
photos or PDFs. Organization administration. A default provider, a library inside the RBZ, or a
privileged vendor. A translator for any vendor's own format. Assembly, Window Type and equipment
libraries. IP units on the wire.

## Decisions recorded

Round 1, 2026-09-18. Answers are Ed's. The body above is folded when the interview closes.

| # | Decision | Answer |
| --- | --- | --- |
| Q1 | Words | Library is the model-library tab. The sidebar heading names the provider. "Library provider" in docs and preferences. "Organization" goes |
| Q2 | Record kinds | The four bare kinds only: Materials, Frames, Glazings, Psi-Install Types. Assembly, Window Type and equipment libraries (ventilator, heat pump) may come later and are not in this packet |
| Q3 | File layout | One envelope that may hold many kinds. A folder is every such file inside it |
| Q4 | Several providers | Yes. The user switches between providers in the sidebar and pulls records into the SKP |
| Q5 | PH-Navigator's export | No translator. PH-Composer sets the contract and providers accommodate it. PH-Navigator's endpoint and export change to match |
| Q7 | Order and shipping | The library file first, the PH-Navigator connection second. The pair establishes the patterns, contracts and infrastructure. The connection does not ship as part of the extension's defaults: it is an optional setup for a user who has a PH-Navigator account, through a token and an approve flow |
| Q8 | Source changed | A quiet mark while that provider is loaded, manual review on request |
| Q9 | Starter library | A separate download. Very small, built from publicly accessible data, a handful of records to put the structure in place |
| Q10 | Export report attribution | One line per copied record |
| Q11 | Contributor providers | Their own repository, registering from outside the core |
| Q12 | Closed providers | Recorded in `docs/LICENSING.md`. A firm's intranet or company library is fine |
| Q13 | Category ids | The thirteen ids are the format's documented vocabulary |
| Q14 | Units | SI only on the wire, units in the key names. The general rule, as in honeybee-ph and PH-Navigator web: all persistence, all libraries and all real work are SI. IP is a conversion for user-facing display and entry only |
| Q15 | Export model library to file | Included |

Round 2, 2026-09-18.

| # | Decision | Answer |
| --- | --- | --- |
| Q16 | Where the connection lives | One generic connection provider in the core. PH-Navigator, an intranet server and METr's catalog are each an address that implements the protocol |
| Q17 | Proving outside registration | A tiny example provider in its own repository, as the contributor template |
| Q6 | Protocol minimum | Two read-only endpoints and an auth discovery document. The wire format is the file format. No per-record fetch |
| Q18 | Sign-in | Three methods declared by the server: none, static token, device-code |
| Q19 | Starter library data | Generic records citing public sources, no table transcribed from a standard, CC0 |
| Q20 | Ids in an exported library | The record's own local id, with origin as informational text |
| Q21 | What Export model library writes | Confirmed in D6: an explicit choice dialog, all supported kinds by default, selected records only when a selection exists, and never filtered or hidden rows implicitly |

## Acceptance shape

Offline: the provider contract against the library file with a synthetic multi-kind file; envelope
refusals and row tolerance; each kind adapter's map, fingerprint and in-file projection; reuse,
same-name review and replacement; Export model library and reading the result back; an IP or
unit-less value refused. On the host: add a
library file in preferences, copy and assign by drag, Add to this file, Undo removes the copy and
the assignment together, reopen the SKP on a machine with no providers and edit the copy. With a
second provider configured: verify identity-scoped In this file state and explicit cross-source reuse.
The example provider, registered from outside the repository, lists and copies without a core
change. Against a server: each of the three sign-in methods, and a static file host as a server.

Additional acceptance required by the architecture corrections:

- Two local records claiming one source identity produce ambiguity, including after duplication
  and rename. Different libraries with the same record id never collide. File/connection copies
  follow the documented cross-source rule; source changes do not overwrite local edits.
- Copy plus assignment failure rolls back both changes. Replace an in-use record and assert its
  actual assignment references, evidence, metadata and unavailable-extension payloads survive
  native Undo/Redo and fresh-process save/reopen. Unsupported edits refuse without mutation.
- Unsupported envelope/kind versions, required-field errors, optional-field absence, duplicate ids
  across folder files, conflicting library identities and catalog budget overflow have distinct
  outcomes. Failed refresh and a valid empty catalog cannot be confused. No half-generation copies.
- Export, read back, update the same library file and export a new library: verify semantic fields,
  local record ids, retained versus new library UUIDs and subsequent reuse. Exercise explicit selected
  scope, hidden rows, declined omission disclosure and failed writes preserving the prior file.
  Include synthetic secret/address/path and metadata fields to verify snapshot and export filtering.
- With the panel closed, run list, preview, apply and read-back through public operations. Test stale
  revisions, wrong sessions and duplicate retries. Remove or reconfigure a provider during loading;
  late responses must not resurrect it or mutate a model. Exercise offline and revoked states.
- The outside example runs the same reusable provider contract tests as the shipped providers;
  duplicate registration, unavailable kinds and incompatible contract versions fail explicitly.

PLAN.md must settle exact operation signatures, wire schemas, fingerprint canonicalization, migration
dispatch and aggregate catalog budgets against the transplanted contracts. These are implementation
details still to specify, not evidence that the interfaces already work. Outside registration,
Windows credentials, protocol interoperability and native lifecycle behavior remain unverified.

## Prior art and evidence

- Predecessor packets: `../ph-navigator-sketchup/planning/archive/shared-material-library/` and
  `../ph-navigator-sketchup/planning/archive/window-types/phases/phase-8f-frame-glazing-libraries.md`.
- Predecessor code: `../ph-navigator-sketchup/src/ph_navigator_sketchup/features/organization_library/`.
- `context/TECH_STACK.md`, "The library provider seam".
- [Founding brief](../../FOUNDING_BRIEF.md), the contribution seams and the decisions table.
