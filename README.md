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
    dependency-bump/         # bump + cheap checks + auto-merge PR (scripts/bump.py)
    release/                 # plan/prepare/publish with a gated boundary (scripts/release.py)
    distribution-channels/   # shipping beyond the tag: boundary model + references/ per channel
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

- **operational-reliability rules** (research-backed, no red observed
  in our repos yet — the list waits for incidents): explicit restart
  policy per production service (one-shots distinct from long-running),
  `stop_grace_period`/shutdown semantics, resource limits (`mem_limit`,
  `cpus`, `pids_limit`), log rotation (bounded `logging` options or the
  `local` driver — json-file does not rotate by default), backup AND
  restore-test contract for named volumes (a volume is not a backup),
  secret rotation procedure distinct from bootstrap, UID/GID/SELinux
  ownership contract for rootless engines, rollback/recreation test
  (deploy → state → recreate without volume loss → upgrade), and a
  healthcheck sidecar sharing the app's netns for distroless runtimes

- **reliability evals** (multi-run smoke: 3 scaffolds, all green, measuring
  variance. Trigger: when a flow or model reference changes shape, or when
  the skill count doubles. The single-run gate covers structure, not
  reliability)
- a coding/refactoring skill on **modularity**, seeded by the
  testing-structure rule that code must be refactored to enable cheap
  tests (seams, ports, injection); a dedicated skill waits for a second
  real validated use
- readme-shape variants for libraries
- distribution-channels references for further ecosystems (deb/rpm,
  flatpak, app stores) — ship when a real repo ships there
- a drift-review flow (does this repo still follow the model?)
