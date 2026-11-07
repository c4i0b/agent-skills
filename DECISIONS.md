# Decisions

Rejected concepts and the reason each stays rejected. Read before
proposing a change to rules or structure: relitigating a recorded decision
needs a NEW observed failure, not a better argument (the bar, from
mattpocock's SCOPE: observed failure plus fits the philosophy).

- **Generic setup/migrate flows dispatching on model** — flows stay inside
  the model's directory. Generalizing for models that do not exist is
  speculation. Revisit when a second real model exists.
- **`_shared/` cross-skill content** — ecosystem convention is
  self-contained skills (installers copy one directory). Shared knowledge
  lives in its own reference skill.
- **opencode coupling anywhere in skills or gates** — skills are
  tool-agnostic. Delegation mechanism is the executing agent's choice.
  (The smoke script once shelled out to one CLI with a pinned model and
  failed on that provider's free tier.)
- **The whole obra/superpowers repo** — overlaps agent-orchestration
  (two sources of truth for dispatch) and its verbosity fights the lean
  rule. Cherry-picks welcome, wholesale adoption no.
- **beads as a shared, committed `.beads/`** — personal-local choice:
  state is never committed or synced unless explicitly asked. Revisit only
  if cross-machine task sync becomes a real need.
- **mock in the unprivileged tooling container with an isolation flag
  only** — known-broken without capabilities. Privileged dedicated service
  is the upstream-documented fix.
- **Versioned-tag pinning as default** — latest-first policy: freshness
  beats pinning by default. Pinning is the exception, verified-current.
- **Renovate for autoupdate** — rejected in fedora-packages before this
  repo existed. Do not reintroduce without discussion.
