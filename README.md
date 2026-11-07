# agent-skills

Reusable skills for coding agents: how to initialize and migrate repos to
the way I work. Skills are consumed by pointing an agent at this repo (see
Using below).

## Layout

```
skills/
  foundations/               # how a repo is structured and documented
    agent-docs/              # lean AGENTS.md ⇄ docs/ (+ references/)
    readme-shape/            # README for humans (+ references/ per repo kind)
    writing-style/           # the prose voice for repo artifacts
  dev-discipline/            # how code is written and tested
    testing-structure/       # pyramid, cheapest-first, recorded fixtures
    development-policy/      # test-first discipline, seeded into repos
  agent-workflow/            # how agents work: together and with the user
    agent-orchestration/     # dispatch, discipline, verify-after-delegate
    planning/                # guided decisions, spec convergence, execution
  project-setup/             # models a repo can be initialized/migrated into
    ephemeral-tooling/       # the container model (reference + flows)
      model/                 # the reference (+ references/)
      setup/                 # flow: greenfield repo in the model
      migrate/               # flow: existing repo into the model
```

Rules that keep this repo healthy live in [AGENTS.md](AGENTS.md).

## Using

Each skill is a directory with a `SKILL.md` the agent will find. To use
one, point the agent at it:

```
Read <path-to>/agent-skills/skills/project-setup/ephemeral-tooling/setup/
and follow it to set up this repo.
```

Flows orchestrate readings: they list which reference skills to read and in
what order. Reference skills hold the knowledge.

## Candidates (not built yet)

Built only when a real validated example exists:

- **reliability evals** (multi-run smoke: 3 scaffolds, all green, measuring
  variance. Trigger: when a flow or model reference changes shape, or when
  the skill count doubles. The single-run gate covers structure, not
  reliability)
- a coding/refactoring skill on **modularity**, seeded by the
  testing-structure rule that code must be refactored to enable cheap
  tests (seams, ports, injection) — validated once in finance; a dedicated
  skill waits for a second real use
- readme-shape variants for CLI tools and libraries
- a credentials reference for the ephemeral-tooling model
- a drift-review flow (does this repo still follow the model?)
- distribution via `npx skills add` (structure is compatible)
