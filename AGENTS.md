# AGENTS.md — agent-skills

Skills for initializing and migrating repos to my way of working. Consumers
are coding agents pointed at this repo by path.

## Maintenance rules (this repo's golden rules)

- A skill is either a **reference** (holds knowledge) or a **flow**
  (orchestrates readings, holds no knowledge of its own). Never mix.
- Any change to a flow or to a model reference needs a fresh scratch
  scaffold passing `tests/scaffold-check.sh` before commit — delegate the
  scaffold however you delegate (see agent-orchestration), then run the
  check on the scratch dir. A flow that has not produced a real scratch
  repo is unvalidated (that is how an EOL image tag and a missing initial
  commit once shipped).
- A new variant, reference file or skill ships only with a real validated
  example, or a certain recurrence. No speculation.
- Categories: `foundations` (how a repo is structured and documented),
  `dev-discipline` (how code is written and tested), `agent-workflow` (how
  agents work together), and one directory per domain (reference + flows,
  like `ephemeral-tooling`). A category groups knowledge that references
  itself. A new category needs at least two mutually-referencing skills;
  a lone skill is a candidate, not a category.
- Leaf names are globally unique. Generic leaf names (`model`, `setup`,
  `migrate`) are allowed only inside a domain, and their frontmatter name
  carries the domain prefix (`ephemeral-tooling-setup`).
- Every commit touching skills runs `tests/links-check.sh`: relative
  markdown links must resolve.
- Skills are English, evergreen, concise. No session play-by-play.

## Structure

- `skills/foundations/agent-docs` — lean AGENTS.md + docs/ system,
  decision records, optional task tracking
- `skills/foundations/readme-shape` — README conventions per repo kind
- `skills/foundations/writing-style` — the prose voice for AGENTS.md,
  docs/ and READMEs
- `skills/dev-discipline/testing-structure` — test pyramid without
  overlap, cheapest-test-first, refactor-for-testability;
  recorded-fixtures catalog/recorder for external-API repos
- `skills/dev-discipline/development-policy` — day-to-day coding
  discipline, seeded into repos as docs/development.md
- `skills/agent-workflow/agent-orchestration` — dispatching, disciplining
  and verifying parallel agents and nested CLI sessions
- `skills/ephemeral-tooling/model` — the ephemeral tooling-container model
- `skills/ephemeral-tooling/setup` — flow: new repo into the model
- `skills/ephemeral-tooling/migrate` — flow: existing repo into the model
