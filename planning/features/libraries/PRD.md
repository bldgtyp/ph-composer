# Libraries: behavior contract

DATE: 2026-09-18
STATUS: Scoped. Interviewed 2026-09-18 in two rounds, 21 decisions recorded below, one of them unconfirmed. PLAN.md follows the foundation transplant.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

A consultant does not retype mineral wool's conductivity or a window manufacturer's frame values
on every project. The predecessor solved this for one source: a sidebar beside the Assembly
Builder and the Library inventories that browses PH-Navigator web's catalog, from an exported file
or a signed-in connection, and copies one record at a time into the model as an editable local
copy with attribution. It shipped for Materials, Frames and Glazings, and it passed against
production.

It was written for one vendor. Each record kind's adapter names PH-Navigator as its provider, its
catalog URL path and its file format in constants. One source can be open per kind. PassiveBuilder
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
| `catalog_file` (envelope checks, row normalization, size limit, skip with warning) | 166 | Adapt. Reads PassiveBuilder's library file format |
| `kinds/kinds`, `kinds/materials`, `kinds/window_products` | 328 | Split. The field mapping, fingerprint and in-file projection stay a kind adapter. The provider name, library id, URL path and file kind leave it |
| `connection`, `transport`, `credentials` | 464 | Port as the connection provider. The address is entered by the user and nothing is prefilled |
| Panel: sidebar, source selector, details bubble, drag and drop, "In this file", same-name review | not counted | Port |

## Decision

- There are two contracts. A **library provider** says where records come from. A **record kind
  adapter** says what a record of one kind looks like on the wire, how it becomes a model-library
  record, and how a local copy is recognised. Any provider can serve any kind.
- PassiveBuilder sets one neutral format and providers accommodate it (Q5). The same JSON
  envelope is the library file on disk and the response of a connection, so a static file host is
  a valid server (Q6). No translator for any vendor's format lives anywhere in PassiveBuilder.
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
  copy time and the source row snapshot. It never stores an address, a path or a credential.
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
  id            stable, e.g. "file", or      kind           "materials"
                a connection's host name     wire_fields    names, types, SI units
  label         shown in the sidebar         map(row)       wire row to model-library record
  kinds         which kinds it serves        fingerprint    hash of the mapped fields
  list(kind)    every row, every field       in_file(local, rows)   the "In this file" projection
  freshness     export date or load time
```

- Rows arrive in the same wire shape from every provider. The kind adapter never learns which
  provider it is talking to.
- There is no per-record fetch. The list carries every field, as the predecessor's does, so a
  copy needs no second request (Q6).
- With four bare kinds no record depends on another, so the contract has no dependency rule. A
  later Assembly or Window Type library adds one, and each dependency then goes through its own
  kind's reuse rule so a bundle never makes a second copy of a material already in the file.
- Adding a record kind is one adapter file plus the owning feature handing over its local
  records. Adding a provider is one provider file. Neither touches the other or the core. This is
  the second of the four contribution seams.
- A contributor's provider lives in its own repository and registers from a separate SketchUp
  extension (Q11). Since PH-Navigator needs no code of its own, a tiny **example provider**, a
  hard-coded list of records in its own repository, is the contributor template and the test that
  outside registration works without a core change (Q17).

## The library file

One JSON envelope that may hold many kinds. A folder provider reads every such file inside the
folder (Q3):

```
{
  "format": "passive-builder.library",
  "schema_version": 1,
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
- The reader keeps the predecessor's tolerance: an envelope problem refuses the file with a
  reason, a bad row is skipped with a warning, a bad field is nulled with a warning, and one bad
  value never blocks a library. The 32 MB limit carries over.
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

### Changed by the pivot

- **Providers are set up by the user.** A Libraries section in preferences lists configured
  providers: add a library file or folder, add a connection by typing its address, remove one.
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
  Psi-Install Types as a library file, all of them by default or the selected inventory rows. It
  is a local file write and involves no provider. Each record is published under its own local id,
  with any earlier source carried as informational origin text, because the new file is a new
  library with its own identity (Q15, Q20, Q21).
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
| Q5 | PH-Navigator's export | No translator. PassiveBuilder sets the contract and providers accommodate it. PH-Navigator's endpoint and export change to match |
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
| Q21 | What Export model library writes | Unconfirmed. Recorded as the recommendation: everything by default, or the selected rows |

## Acceptance shape

Offline: the provider contract against the library file with a synthetic multi-kind file; envelope
refusals and row tolerance; each kind adapter's map, fingerprint and in-file projection; reuse,
same-name review and replacement; Export model library and reading the result back; an IP or
unit-less value refused. On the host: add a
library file in preferences, copy and assign by drag, Add to this file, Undo removes the copy and
the assignment together, reopen the SKP on a machine with no providers and edit the copy. With a
second provider configured: switch sources in the sidebar and see "In this file" hold across both.
The example provider, registered from outside the repository, lists and copies without a core
change. Against a server: each of the three sign-in methods, and a static file host as a server.

## Prior art and evidence

- Predecessor packets: `../ph-navigator-sketchup/planning/archive/shared-material-library/` and
  `../ph-navigator-sketchup/planning/archive/window-types/phases/phase-8f-frame-glazing-libraries.md`.
- Predecessor code: `../ph-navigator-sketchup/src/ph_navigator_sketchup/features/organization_library/`.
- `context/TECH_STACK.md`, "The library provider seam".
- [Founding brief](../../FOUNDING_BRIEF.md), the contribution seams and the decisions table.
