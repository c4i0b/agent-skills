# AGENTS.md — agent-skills

Skills for initializing and migrating repos to my way of working. Consumers
are coding agents pointed at this repo by path.

## Maintenance rules (this repo's golden rules)

Vocabulary is canonical in [GLOSSARY.md](GLOSSARY.md); use those terms
verbatim instead of paraphrasing. Rejected concepts and their strip
conditions live in [DECISIONS.md](DECISIONS.md) — read it before proposing
to change rules or structure: relitigating needs a NEW observed failure,
not a better argument.

- A skill is either a **reference** (holds knowledge) or a **flow**
  (orchestrates readings, holds no knowledge of its own). Never mix.
- Any change to a flow or to a model reference needs a fresh scratch
  scaffold passing `tests/scaffold-check.sh` before commit — delegate the
  scaffold however you delegate (see agent-orchestration), then run the
  check on the scratch dir. A flow that has not produced a real scratch
  repo is unvalidated (that is how an EOL image tag and a missing initial
  commit once shipped).
- A new variant, reference file or skill ships only with a real validated
  example, or a certain recurrence. No speculation. **Red-green**: every
  rule, gate assertion or invariant ships with its red — the observed
  failure it exists to prevent, cited where the rule lives. If you cannot
  name the red, the rule is speculative.
- Categories: `foundations` (how a repo is structured and documented),
  `dev-discipline` (how code is written and tested), `agent-workflow` (how
  agents work together), and `project-setup` (models a repo can be
  initialized or migrated into, one directory per model: reference +
  flows, like `ephemeral-tooling`). A category groups knowledge that
  references itself, or parallel alternatives of one concern. A new
  category needs at least two mutually-referencing skills; a lone skill is
  a candidate, not a category.
- Leaf names are globally unique. Generic leaf names (`model`, `setup`,
  `migrate`) are allowed only inside a domain, and their frontmatter name
  carries the domain prefix (`ephemeral-tooling-setup`).
- Adding, renaming or moving a skill updates BOTH inventories: the README
  layout block and the Structure list below (drift between them is the
  reading-list-drift anti-pattern at inventory level). New canonical terms
  go to GLOSSARY; rejected concepts go to DECISIONS.
- Every commit touching skills runs `tests/links-check.sh`: relative
  markdown links must resolve.
- Skills are English, evergreen, concise. No session play-by-play.
- Skills name mechanisms, not external projects: describe the pattern so
  the rule stands alone (an external repo reference rots and assumes
  context the reader does not have). Reds included: cite the failure
  mode (symptom, count), never package/repo/incident names — project
  names appear only as validated-example provenance. Red: reds naming
  specific packages/repos read as gossip once the incident is
  forgotten.

## Structure

Per category (the rules above define the categories):

- foundations: agent-docs, readme-shape, writing-style,
  gh-actions-conventions
- dev-discipline: testing-structure, development-policy,
  dependency-bump, release, distribution-channels
- agent-workflow: agent-orchestration, planning
- project-setup: ephemeral-tooling (the model reference plus setup and
  migrate flows)
