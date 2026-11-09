# Decisions

Rejected concepts and the reason each stays rejected. Read before
proposing a change to rules or structure: relitigating a recorded decision
needs a NEW observed failure, not a better argument (the bar: observed
failure plus fits the philosophy). Each entry carries its strip
condition — the change that would reopen it.

- **Generic setup/migrate flows dispatching on model** — flows stay inside
  the model's directory. Generalizing for models that do not exist is
  speculation. Revisit when a second real model exists.
- **`_shared/` cross-skill content** — ecosystem convention is
  self-contained skills (installers copy one directory). Shared knowledge
  lives in its own reference skill. Strip if the ecosystem adopts
  bundle-aware installs.
- **opencode coupling anywhere in skills or gates** — skills are
  tool-agnostic. Delegation mechanism is the executing agent's choice.
  (The smoke script once shelled out to one CLI with a pinned model and
  failed on that provider's free tier.) Strip never: tool-agnosticism is
  identity, not preference.
- **Adopting an external process-skill collection wholesale** — overlaps
  agent-orchestration
  (two sources of truth for dispatch) and its verbosity fights the lean
  rule. Cherry-picks welcome, wholesale adoption no. Revisit if we stop
  maintaining our own orchestration skill.
- **beads as a shared, committed `.beads/`** — personal-local choice:
  state is never committed or synced unless explicitly asked. Revisit only
  if cross-machine task sync becomes a real need.
- **Splitting multi-service.md (or a references/ subdirectory)** — the
  deployment-contract section is ~70% of the file but has exactly one
  kind of consumer (multi-service repos); 173 lines is within reference
  size for one coherent variant (base-images holds 143 unsplit), and no
  skill uses reference subdirectories. Strip when a non-multi-service
  consumer of the deployment contract appears — then extract
  `deployment-contract.md`.
- **mock in the unprivileged tooling container with an isolation flag
  only** — known-broken without capabilities. Privileged dedicated service
  is the upstream-documented fix. Strip if mock ships a rootless mode.
- **Versioned-tag pinning as default** — latest-first policy: freshness
  beats pinning by default. Pinning is the exception, verified-current.
  Strip if reproducible-build requirements land.
- **Renovate for autoupdate** — rejected in fedora-packages before this
  repo existed. Do not reintroduce without discussion. Strip on upstream
  needs changing fundamentally.
- **Deterministic scaffolder CLI under the setup flow** (fCC
  agent-scaffold style: flow elicits, script generates) — conflicts with
  the doc-guided agent decision and adds a build surface to maintain.
  Revisit if scaffolds drift repeatedly despite the gate (that would be
  the red).
- **Machine-readable `catalog.yaml` inventory** —
  the AGENTS.md structure list already serves as the single inventory;
  generated manifests pay off at distribution scale. Revisit when (if)
  publishing or bundling skills.
- **Third-party AGENTS.md linters as gates** (agents-md-doctor, agnix) —
  external deps against the self-contained gate philosophy; our checks
  encode OUR conventions. Revisit if a linter allows full config of ours.
- **Channel automation inside the release script** — channels with
  content-derived hashes join branch CI (CI-as-gate); the rest trigger
  downstream from the publish event. Per-channel logic multiplies the
  script's surface for checks CI already proves. Revisit when a
  channel exists that branch CI cannot build.
