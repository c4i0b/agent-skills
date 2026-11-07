# Decision records (ADRs)

When a decision has alternatives worth remembering (rejected tools, model
choices, trade-offs), record it as an ADR instead of burying it in a comment.

- Decisions live in `docs/decisions/`, one file per decision, linked from
  `docs/README.md`.
- Superseded ADRs gain an "Amended by" banner pointing at the successor.
  History is never rewritten.
- Record the rejected alternatives and why (e.g. "Renovate was evaluated and
  rejected — do not reintroduce without discussion"): the negative space is
  what prevents re-litigating.

Validated example: `finance/docs/decisions/`.
