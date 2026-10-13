# Export contract wording acceptance

DATE: 2026-10-13
STATUS: Planned checks; none run.
PLAN: [PLAN.md](PLAN.md)

| Case | Check | Required observation |
| --- | --- | --- |
| EW-A01 | Read the three `USER_DATA` constants after the edit | Identical sentence: Model-local preservation, explicit export mapping, omission finding; no "verbatim" |
| EW-A02 | Diff each affected operation schema with the description stripped | Names, params, types, required lists, examples, refusals, side effects unchanged |
| EW-A03 | `make fixtures` then `git diff docs/API_REFERENCE.md` | Only description strings change; no hand edit to the generated file |
| EW-A04 | `grep -rn "exported verbatim" src docs context tools` | Prints nothing |
| EW-A05 | Read `context/CONTRACTS.md` "Records and extension data" and `context/EXTENSIBILITY.md` "Metadata and structured extension data" beside the new sentence | The sentence agrees with both; neither file needs an edit |
| EW-A06 | `make lint-ruby`, the focused schema and reference tests, `make fixtures-check` | All pass on the changed head |

Completion: `make ci` on the coherent head this lands with. No native, copy, privacy or Python case
is added; a behaviour change discovered on the way is routed to the entity customization packet.
