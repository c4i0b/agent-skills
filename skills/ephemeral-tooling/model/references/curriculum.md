# Curriculum — what to read before setup or migrate

Single source for both flows. Read in order; skip conditionals that do not
apply.

1. [ephemeral-tooling-model](../SKILL.md) — the model and its invariants
2. [agent-docs](../../../foundations/agent-docs/SKILL.md) — the
   AGENTS.md ⇄ docs/ system (incl. optional task tracking)
3. [readme-shape](../../../foundations/readme-shape/SKILL.md) —
   README by repo kind
4. [testing-structure](../../../dev-discipline/testing-structure/SKILL.md)
   — when the repo has tests; its
   [catalog-and-recorder](../../../dev-discipline/testing-structure/references/catalog-and-recorder.md)
   — when it consumes external APIs
4b. [development-policy](../../../dev-discipline/development-policy/SKILL.md)
   — the day-to-day discipline (test-first, cheapest layer, refactor for
   testability), seeded as the repo's docs/development.md
5. [base-images.md](base-images.md) — when choosing the FROM (setup) or
   auditing it (migrate)
6. [multi-service.md](multi-service.md) — when the repo also runs services
7. [ci-bypass.md](ci-bypass.md) — when recipes must also run in CI
