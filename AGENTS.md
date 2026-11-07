# AGENTS.md — agent-skills

Skills for initializing and migrating repos to my way of working. Consumers
are coding agents pointed at this repo by path.

## Maintenance rules (this repo's golden rules)

- A skill is either a **reference** (holds knowledge) or a **flow**
  (orchestrates readings, holds no knowledge of its own). Never mix.
- Any change to a flow or to a model reference must pass
  `tests/scaffold-smoke.sh` before commit — a flow that has not produced a
  real scratch repo is unvalidated (that is how an EOL image tag and a
  missing initial commit once shipped).
- A new variant, reference file or skill ships only with a real validated
  example, or a certain recurrence. No speculation.
- A category directory groups knowledge that references itself
  (`ephemeral-tooling/`). Transversal knowledge that multiple categories
  consume lives in `repo-foundations/`. Nothing else gets a category.
- Frontmatter `name` is globally unique and uses the category as prefix
  (`ephemeral-tooling-setup`), even though discovery walks directories.
- Skills are English, evergreen, concise. No session play-by-play.

## Structure

- `repo-foundations/agent-docs` — lean AGENTS.md + docs/ system, decision
  records, optional task tracking
- `repo-foundations/readme-shape` — README conventions per repo kind
- `repo-foundations/testing-structure` — test pyramid without overlap,
  cheapest-test-first, refactor-for-testability; recorded-fixtures
  catalog/recorder for external-API repos
- `repo-foundations/agent-orchestration` — dispatching, disciplining and
  verifying parallel agents and nested CLI sessions
- `repo-foundations/writing-style` — the prose voice for AGENTS.md, docs/
  and READMEs
- `ephemeral-tooling/model` — the ephemeral tooling-container model
- `ephemeral-tooling/setup` — flow: new repo into the model
- `ephemeral-tooling/migrate` — flow: existing repo into the model
