# agent-skills

Reusable skills for coding agents: how to initialize and migrate repos to
the way I work. Skills are consumed by pointing an agent at this repo (see
Using below).

Validated against three real repos:

- `/home/caio/Projects/fedora-packages` — monorepo, single tooling container
- `/home/caio/Projects/finance` — service stack, dev/runtime containers
- `/home/caio/Projects/pipoca` — media stack, tooling container + generated compose

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
  agent-workflow/            # how agents work together (not about repos)
    agent-orchestration/     # dispatch, discipline, verify-after-delegate
  ephemeral-tooling/         # one domain: everything about the container model
    model/                   # the reference (+ references/)
    setup/                   # flow: greenfield repo in the model
    migrate/                 # flow: existing repo into the model
```

Rules that keep this repo healthy live in [AGENTS.md](AGENTS.md).

## Using

Skills are plain Agent Skills (`SKILL.md` with `name` + `description`
frontmatter, plus optional bundled files). To use one, tell the agent
something like:

```
Read /home/caio/Projects/agent-skills/skills/ephemeral-tooling/setup/SKILL.md
and follow it to set up this repo.
```

Flows orchestrate readings: they list which reference skills to read and in
what order. Reference skills hold the knowledge.

## Candidates (not built yet)

Built only when a real validated example exists:

- a coding/refactoring skill on **modularity**, seeded by the
  testing-structure rule that code must be refactored to enable cheap
  tests (seams, ports, injection) — validated once in finance; a dedicated
  skill waits for a second real use
- `readme-shape/references/cli-tool.md`, `library.md`
- `ephemeral-tooling/model/references/credentials.md`
- a drift-review flow (does this repo still follow the model?)
- distribution via `npx skills add` (structure is compatible)
