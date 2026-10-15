# P3a-08: airflows and the balance view

DATE: 2026-10-15
STATUS: Scoped. Waits for the Spaces UI and UX discussion; see the re-baseline note
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

**Re-baseline note, 2026-10-15 (`main` at `87bdc62`).** The balance read and the any-set
rule are unaffected by `main`. The airflow columns and the balance subtab follow whatever table
shape the Spaces UI and UX discussion settles for P3a-07 (D3a-6, D3a-12).

## Entry and scope

Requires P3a-07, D3a-8 and D3a-12. Owns airflow entry on screen and the airflow balance view. The
three fields, the any-set rule and their storage shipped in P3a-02; this stage is their columns,
the display of unset against zero, the balance read, its subtab and the imbalance finding. M2
closes here.

Behavior owner: [Spaces PRD](../PRD.md), Airflows (Q8, Q9, Q16, Q21) and the imbalance
row of Validation rows. Load the UI polish skill first. Names: [CONTRACTS](../CONTRACTS.md)
sections 3 and 6.

Paths are relative to `src/ph_composer/`.

## Steps

1. **Columns.** Add supply, extract and transfer to the Spaces table and the inspector, in the
   `airflow` quantity, shown in the user's display units and stored in m3/h.
2. **Three cell states.** A set value reads normally. An unset cell on a user-specified Space
   reads as a muted 0. An unset cell on an inheriting Space reads as a muted "inherited" mark;
   the inherited number itself waits for the Zone loads packet. A typed 0 is a value. Clearing a
   cell sends the clear marker, not 0, and clearing the last set value returns the Space to
   inheriting. The state comes from the snapshot's metrics, never recomputed in the panel.
3. **Range edit and paste.** Through `batch_update`, as heights are. An empty pasted cell clears.
4. **Balance read.** `declarations/balance.rb` and a pure `balance` function: given the scan and
   a grouping function, one row per group with supply, extract and transfer sums over its
   user-specified Spaces, the count of inheriting Spaces, the imbalance flag, and a model total.
   The grouping function is an argument with Zone grouping as its only caller (D3a-8). A group
   with any inheriting Space is `partly_inherited` with the count and its flag is not evaluated.
5. **Imbalance rule.** The threshold as D3a-12 settles it. The finding `space.airflow_imbalance`
   is per Zone, non-blocking, and appears in the balance view and in export preflight.
6. **The subtab.** A second subtab in the Spaces pane: one row per Zone with the three sums, a
   warning label where flagged, "partly inherited (n)" where it applies, a click into that Zone's
   Spaces on the first subtab, and the model total. Read-only.
7. **Preview and manifests.** Fixtures for balanced, imbalanced and partly inherited; checks;
   regenerate both manifests.
8. **Walkthrough.** Extend the spaces walkthrough: read `balance`, panel closed.

## Source

None. The predecessor had no airflow entry.

## Tests (write first)

1. The three cell states render from the snapshot for: all unset; supply only; three explicit
   zeros.
2. Clearing a cell sends the clear marker; clearing the last value flips the row to inheriting.
3. A paste of values and blanks sends one `batch_update` with sets and clears.
4. `balance` on the reference model: Zone A supply 60, extract 40, transfer 20, flagged; Zone B
   partly inherited (1), not evaluated; model total over user-specified Spaces.
5. The threshold at its boundary, both sides, and with one sum at zero.
6. A Zone with no Spaces has no row. A Space outside any Zone is in no group.
7. The balance function with a synthetic second grouping returns groups it was never written
   for, with no change to the function.
8. Unit switch between m3/h and cfm keeps drafts and changes no stored value.

## Host gate

Fresh process on the reference model: type a supply, an extract and a zero; clear one; paste a
column of airflows from a spreadsheet and Undo once; open the balance subtab and read Zone A's
label and Zone B's partly inherited mark; click into Zone A; switch to IP and back; save, reopen
and confirm unset is still unset.

## Out of scope

Inherited values from Zone loads. Grouping by ventilator and the per-unit warning (equipment
packet). The By ventilation mode (P3a-09). Export of airflows (P3a-10).

## Done when

- S08 has evidence in `evidence/p3a-08-airflows.md`, with the UI polish review recorded.
- `make ci` and `make ui-checks` pass. STATUS records M2.
