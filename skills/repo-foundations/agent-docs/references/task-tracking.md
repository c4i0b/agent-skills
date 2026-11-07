# Task tracking (optional — beads)

Install as the repo's `docs/workflow.md`, adapted only in the scoped-commands
and gate wording.

Activation is by availability: if `command -v bd` succeeds on the host,
prefer beads over ad-hoc TODO lists for multi-step work; if it fails,
proceed without it (no error, no setup attempt). bd runs on the HOST — it is
not part of any container.

## Initialization (per repo, host-side)

Order matters: `bd init` creates `.beads/` (embedded Dolt storage) AND
claims `core.hooksPath` (points it at `.beads/hooks`, absolute path) plus
`beads.role` in the LOCAL git config. So initialize beads FIRST, then adapt
the repo's docs/config around what it created.

- `bd init` self-manages `.beads/.gitignore`: only runtime files (dolt
  data, locks, sockets) are ignored; by beads' design `config.yaml`,
  `metadata.json`, `hooks/` and `README.md` inside `.beads/` are meant to
  be committed so collaborators share prefix/config/hooks. Issue data syncs
  cross-machine via Dolt remotes (`bd dolt push`), never via git.
- Personal/local choice (state never committed): ignore `.beads/` entirely
  in the repo `.gitignore` — a deliberate deviation from the default
  design; on a fresh clone re-run `bd init` to restore the local database.
- Shared repo where beads must stay a personal choice: `bd init --stealth`
  (writes `.git/info/exclude` instead; invisible to collaborators).
- Repo with its own versioned hooks (e.g. `.githooks` via `core.hooksPath`):
  after `bd init` restores nothing (it overwrites hooksPath), re-point
  `git config core.hooksPath .githooks` and run `bd hooks install` — it
  injects beads sections into the EXISTING hook files inside
  BEGIN/END BEADS INTEGRATION markers, preserving prior content (keeps a
  `.backup`), so one hooks directory serves both.
- Agent-tool integration (optional): `bd setup <tool> --stealth`.

## Tracking

- `bd prime` for full workflow context before starting
- claim with `bd update <id> --claim`, close with `bd close <id>`
- persistent memory goes in `bd remember` — no MEMORY.md, no markdown TODOs
- never commit, push or sync the beads database unless explicitly asked
  (`.beads/` is gitignored: task state is local, not repo source)

## Orchestration

When more than one task is ready, the main session acts as orchestrator,
not sole implementer:

1. Delegate everything ready: `bd ready` → claim → one background subagent
   per ready task, each carrying the full task spec and repo rules.
2. Validate the agent's reported evidence (command output), not redundantly:
   verify the report and review the diff; re-run only when suspicious.
3. Scope each agent's work so concurrent agents never edit the same files.
   The full gate runs when the tree has no parallel WIP (before push), not
   as each agent's exit condition.
4. Commit per task, then `bd close <id>`.
5. Cascade immediately: after each close, re-run `bd ready` and delegate
   newly unblocked tasks right away — don't batch waves.
6. Loop until nothing is ready; hand off with the status of open and blocked
   tasks.

Rules: only claim what you will work on now; never commit red.

Validated examples: `docs/workflow.md` in both reference repos.
