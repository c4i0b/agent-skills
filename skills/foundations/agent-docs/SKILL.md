---
name: agent-docs
description: Structure a repo's agent-facing documentation. A lean AGENTS.md holding only behavioral rules an agent must follow every session, pointing to evergreen docs/ for policies. Covers the docs/ layout, decision records and optional task tracking. Use when creating or reworking a repo's AGENTS.md or docs layout.
---

# Agent documentation: AGENTS.md ⇄ docs/

Two audiences, two artifacts:

- **AGENTS.md** — loaded by the agent every session. Behavioral rules only.
- **docs/** — read on demand. Detailed, evergreen policies.

## AGENTS.md rules

- Keep it lean: behavioral rules an agent must follow every session. When
  adding rules, prefer extending a linked doc over growing this file — say
  this explicitly in the file's intro so future edits keep the discipline.
- Every entry must be an action, a prohibition, or a decision signal an
  agent needs at all times. How-to content, tool details and rationale go to
  docs/; keep at most a recognition signal (e.g. an error message signature).
- Structure that works: short intro (what the repo is, where builds happen)
  → environment essentials → costly-mistake rules → reference links.
- Link every doc from AGENTS.md; an unlinked doc is dead (the
  anti-pattern has a name: **orphan docs**).

## docs/ rules

- `docs/README.md` is the index; one policy per doc; prose follows
  [writing-style](../writing-style/SKILL.md) (English, evergreen, no
  session play-by-play).
- Names by theme (`environment.md`, `conventions.md`), not by date or event.
- Duplication with AGENTS.md is allowed only as summary-in-AGENTS +
  detail-in-doc. If the detail adds nothing, the doc owns the rule and
  AGENTS keeps the one-liner.

## References

- [adr.md](references/adr.md) — recording decisions as ADRs
- [task-tracking.md](references/task-tracking.md) — optional beads tracking
  and orchestration, installed as the repo's `docs/workflow.md`

## Validated examples

- `/home/caio/Projects/fedora-packages` (AGENTS.md 49 lines + thematic docs)
- `/home/caio/Projects/finance` (AGENTS.md + per-service docs + ADRs)
