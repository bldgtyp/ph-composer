# Delivery order and PR boundaries

DATE: 2026-10-13
STATUS: Proposed sequencing; planning only.

## Dependency order

```mermaid
flowchart TB
  RR[Registration reliability RR-01..03] --> C[Cross-feature composition C-01..04]
  RR --> L[Library contracts LC-01..02]
  RR --> E3[Entity customization EC-03..04]
  C --> L3[Library LC-03 uses the migrated invoker if C-03 landed first]
  W[Windows orchestration W-01..03] --> E2[Entity customization EC-02 Unit route]
  W --> Z[Zone-child lifecycle ZC-02..04]
  RR --> Z
  Z1[ZC-01 host spike, document] --> Z
  G1[G-01 with the thermal-bridge packet] --> G3[G-03 line primitive]
  G2[G-02 Edge capture] --> G4[G-04 adopter]
  G3 --> G4
  P[Foundation purity, optional] -. same capture file .-> G2
  PD[Panel domain ownership] -. shares installs.rb and snapshot.rb .-> W
```

Arrows are interface dependencies, not permission to start. Nothing on this chart is authorized.

## Groups, in the order to start them

| Group | Packets | Why this boundary |
| --- | --- | --- |
| Independent corrections | Export wording, outcome hook, contributor example | No dependency; one small PR each; settle the review template on small diffs |
| Foundation contracts | Registration, then composition | Every later declaration family relies on RR-02's ownership rule; composition adds the next family |
| Definition and placement | Windows orchestration; panel domain ownership | Both edit Windows files; run them in sequence or with one owner. Panel PD-03 (Zones Area) is independent and can run in parallel |
| Owner metadata | Entity customization EC-01 and EC-02 | After W-01 for the Unit route; EC-03 is a contract stage that pauses for Ed |
| Library completion | LC-01, LC-02, then LC-03 | LC-03 can go first if scheduling needs it; it closes RF-04 only |
| Parent copy | ZC-01 spike, then ZC-02 to ZC-04 | The spike decides whether the late-binding design holds on the host |
| Next geometry feature | G-02 now; G-01, G-03, G-04 with phase 3b | F06 closes only when an adopter uses both seams |
| Optional readability | Foundation purity | Whenever convenient; never ahead of the groups above |

## PR granularity

One PR per stage. A stage that leaves the public seam half migrated is not merged on its own: RR-01
and RR-02 may be two PRs but the registration defect stays open until RR-03; C-03 is one PR because
the raw accessor goes with the last caller. EC-01 and EC-02 are separate PRs; EC-03 and EC-04 merge
together once Ed confirms the declaration. The copied-Zone product request closes with ZC-04.

Create one GitHub issue per packet at intake, with the packet path in the body and the issue URL in
the packet's `STATUS.md`. PRs say `Closes #N` on the stage that finishes the packet.

## Shared files

`shell/registry.rb`, `registry_validation.rb` and `declarations.rb` are edited by registration,
composition, entity customization EC-03 and zone-child ZC-02: registration lands first and the others
extend its `VALUE_MEMBERS` table. `features/windows/types/installs.rb` and `snapshot.rb` are edited
by Windows orchestration and panel ownership. `core/face_geometry.rb` is edited by purity and
`export/geometry_snapshot.rb` by geometry capture. Avoid concurrent editors on those owners; where a
combined diff shares one native receipt, the receipt names which packet's cases it satisfies.

Run focused checks while editing and one `make ci` per PR head. Dual-Ruby `make ci` and the stronger
independent review are required where a plan's verification profile says so; a routine PR gets one
bounded review. Fold verified contracts into `context/` in the same PR that ships them.

## Observations below the findings

| Observation | Disposition |
| --- | --- |
| Callback snapshot immutability (`SnapshotReader` projections are detached but not frozen) | RR-02 owns declarations; export projections stay a bounded future check if a mutable-output adopter appears |
| Per-Model state lifecycle documentation | The zone-child and contributor-example packets add the explanation where they touch it |
| Contributor router and worked example | This README plus the example packet; implemented contract docs link to verified examples |
| Overview extraction, standalone shell packaging | Deferred until a measured problem or an actual adopter |
