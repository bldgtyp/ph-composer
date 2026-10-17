# Copied Zone independence: owner decisions

DATE: 2026-10-12
STATUS: D-1 to D-8 confirmed by Ed 2026-10-12. Mechanisms proven in P2 and accepted on the host in P5.
ISSUE: none (local planning draft)

D-1 is recorded with its rationale in [README](README.md). Following the
[planning review](REVIEW.md), Ed accepted the five review decision areas below on 2026-10-12.
These decisions establish behavior and implementation bounds, not implementation authorization.

| ID | Subject | Accepted direction |
| --- | --- | --- |
| D-2 | Failure safety | Preserve the native copy and consistent authored state on failure. Preflight refusal writes nothing. Do not accept partial repair or describe a committed partial result as unchanged. Automatic storage rewriting stays gated if P2 cannot prove failure safety. |
| D-3 | Initial scope | Guarantee same-Model copies of a Zone Group without a shared ancestor requiring recursive isolation first. Cross-Model paste retains explicit destination adoption and missing-reference handling; cross-Model automation and recursive floor-copy scope need measurements and a separate scope decision. |
| D-4 | Recovery completeness | Include visible Cancel for Zone Name and Ground depth in P1 while preserving typed drafts. Refused choices revert to the current Model value; held conflicts remain visible with Cancel and a guarded retry. No refusal strands the user behind an invisible draft. |
| D-5 | Checked and gesture scope | Preserve the full checked set; disable/refuse a bulk mutation if any checked target is gated. Do not silently skip targets. A detected copy gesture uses one all-or-nothing batch, one follow-up operation and one aggregate notice; native Undo/Redo must cover the gesture and its repair together. |
| D-6 | Recovery prerequisites and children | Offer Make Zone independent only where it can succeed; explain prerequisites for other cases. Zones can contain Window Units and, when built, Spaces. Child data follows its owner's copy protocol: copied Window Units are new instances of their existing Window Type; copied Spaces are independent authored instances. |

## Implementation decision confirmed after P5

| ID | Subject | Direction, confirmed by Ed 2026-10-12 |
| --- | --- | --- |
| D-7 | Component copies | A copy whose path crosses a ComponentInstance is dropped from the automatic gesture silently: a component's placements share its contents by design, so a notice on every component copy would be noise. Other declined copies (a still-shared parent Group, a lock, extension data whose copy rule refuses) leave the whole gesture shared and post one warning naming the reason. Proposed by Claude while implementing, observed on the host in P5 (case 8b), confirmed by Ed. |
| D-8 | Copied Windows after a Zone copy | Ed, 2026-10-12, after S10: keep D-6's Windows timing in this packet. Copied Units keep the original Unit ids until a Windows action or Repair Copied Windows; the Windows feature reports it and export says why. Repairing them in the same gesture is the follow-up packet [copied-zone-windows](../copied-zone-windows/README.md). |

## Child copy semantics

- **Windows:** a same-Model Zone copy creates new Window Unit instances that reference the same
  Window Type. It does not duplicate the Type definition merely because the containing Zone was
  copied. Unit identity, metadata, glue and cutting behavior follow the existing Windows protocol.
  Its current identity-repair timing is not changed by this decision; determine any required
  proposal participation through Windows' own public contracts.
- **Spaces:** each Space included in a Zone copy gets independent storage and identity, including
  its authored Volumes, Floor Segments and logical Space Floors. It belongs to the copied Zone;
  membership stamps and declared references within the copied collection follow the new
  counterparts. Original children remain unchanged; ordinary values and metadata are preserved
  under their declared copy rules.
- **Ownership:** Zones must not rewrite another feature's dictionaries. The future Spaces owner
  supplies child-copy planning and application through declared contribution contracts. Successful
  parent independence cannot leave shared Space storage or duplicate child identities behind.
  Unsupported/unsafe child payloads refuse the complete gesture batch before writes, or invoke
  the proven failure-safe path if discovered after a write.
- **Foreign copies:** D-6 does not authorize importing source definitions into another Model or
  matching them by name. D-3's destination policy still applies.

The Spaces carry-forward is [D3a-13](../phase-03a-spaces/DECISIONS.md#confirmed-copy-decision-d3a-13)
and is assigned to [P3a-04](../phase-03a-spaces/phases/p3a-04-copies-and-move-space-to-zone.md).
It qualifies the standalone-copy rule; it does not decide the twelve existing Spaces architecture
and UI questions or authorize any Spaces stage.

## Open mechanisms and evidence

P2 must establish native callback/provenance order, source-gesture association, failure restoration,
commit failure handling and one-step Undo/Redo. The explicit action's final-reference/preview
contract remains subject to R8. Shared-parent isolation, cross-Model automatic identity handling
and the child proposal participation mechanism are not approved implementations.

When Spaces is implemented, acceptance must copy a Zone containing Spaces and Windows together:
distinct child identities and storage, original unchanged, references and stamps correct, Window
Types shared as intended, one Undo/Redo, save/reopen and HBJSON read-back. Do not call the future
integration verified from today's Zone-only evidence.
