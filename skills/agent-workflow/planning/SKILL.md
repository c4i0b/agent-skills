---
name: planning
description: Guided planning with the user before non-trivial builds or migrations. Decomposes the work into decision points, asks each as a concrete question with options, trade-offs and a recommendation, records answers as they land, and converges into a spec. Use when starting work whose shape is not yet decided.
---

# Planning: guided decisions before building

The failure this skill exists to prevent: the user knows the destination
but not the paths, and the agent either builds the wrong thing or makes
the user drag decisions out of it one by one (observed: the finance
planning sessions, where the flow had to be taught by hand mid-session).

## When

Non-trivial builds, migrations, or any work with more than one defensible
shape. Small tasks with an obvious shape skip this ceremony.

## The loop

1. **Map the decision points.** Before asking anything, list the open
   questions whose answers change the work: boundaries, storage, external
   contracts, trade-offs, what is explicitly OUT of scope. Order them by
   how much downstream decisions depend on them.
2. **Ask one at a time.** Each question is concrete: 2 to 4 options, each
   with a one-line trade-off, plus a recommendation and why. Never an
   open-ended "what do you want?". The user may answer with an option,
   a new option of their own, or "you decide".
3. **Record as it lands.** Each closed decision is written down
   immediately, one line: the decision, the rejected alternatives, the
   why. Decisions with lasting consequences become ADRs (see
   [agent-docs](../../foundations/agent-docs/references/adr.md)).
4. **Converge into a spec.** When the map is closed, write the spec:
   goals, decisions with rationale, out of scope, and the first slice of
   work. The spec is the input the flows and the execution protocol below
   consume. No building before the spec exists.

## Asking well

- Options must be real alternatives the user could actually pick, not a
  recommendation with straw men.
- State the cost of each option, not only the benefit. The most useful
  line is what each path forecloses.
- If the user defers ("you decide"), decide, record it as a ruling with
  its cost if wrong, and continue. Do not re-ask.
- Prefer fewer, bigger questions over many small ones: batch the trivial,
  surface only what genuinely forks the work.

## Execution

Once a spec or task graph exists, execution follows
[execution.md](references/execution.md): continuous execution, rulings
not stalls, four stop reasons, verify at the end.
