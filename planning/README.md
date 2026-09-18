# planning/

Working plans for PassiveBuilder. See [`.instructions.md`](.instructions.md) for
the rules and folder contract (canon lives in the `planning-conventions`
skill).

**Read order:** [`STATUS.md`](STATUS.md) first, then [`ROADMAP.md`](ROADMAP.md) for the sequence, then
[`FOUNDING_BRIEF.md`](FOUNDING_BRIEF.md) for why the repository exists and what
it inherits.

## Layout

```
planning/
  README.md            # this file
  STATUS.md            # master index of active work
  ROADMAP.md           # phase order of the core features, high level
  FOUNDING_BRIEF.md    # origin, transplant tables, decisions, naming record
  ui-baseline/         # the predecessor's screens, ruled on part by part
  features/            # new-capability packets     (features/<slug>/)
  refactor/            # cross-cutting refactors    (refactor/<slug>.md or <slug>/)
  bugs/                # reproduced defects         (bugs/<slug>.md + README index)
  archive/             # completed/superseded work  (archive/<slug>/ + README index)
```

Folders are created on first need. An absent folder means no work of that kind yet.
