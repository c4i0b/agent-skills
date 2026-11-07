---
name: agent-orchestration
description: Orchestrate parallel subagents and nested agent sessions across repos or research topics, with whatever delegation mechanism your harness provides. Covers dispatch patterns, foreground discipline, verify-after-delegate, and the research-campaign pattern for multi-agent evidence gathering. Use when delegating work to multiple agents.
---

# Agent orchestration

Delegation pays when the work splits into disjoint scopes (one repo or one
topic per agent) and every delegation is verified afterwards. Everything
below was learned from real failures, not theory. The skill is
tool-agnostic: subagents, nested CLI sessions, background workers — use
whatever your harness provides.

## Dispatch patterns

- **Parallel agents**, one per disjoint scope: never two agents writing the
  same repo/directory; research agents may share a scratch root if each
  owns its own subdirectory.
- **Nested sessions in another project** (e.g. a CLI `run - "<prompt>"`
  from the project's directory) when the work belongs to another repo: the
  prompt must be COMPLETE and self-contained (context, constraints, gates,
  what not to touch) — the nested session sees nothing of this one.
- **Follow-ups on the running agent's handle** for scope changes; handles
  are long — copy them, never retype (a typo yields "not found" and a
  duplicate dispatch).

## Hard-won discipline (each line below was a real failure)

- **Foreground discipline**: instruct nested/child sessions to run to
  completion, not to park work in their own background and return a status
  note. If a report says "waiting for X", re-engage: verify state
  yourself, finish in the foreground, then verify.
- **Interrupt caution**: killing a nested session that already finished its
  main job is harmless; killing mid-job leaves partial state. Prefer
  waiting; interrupt only on real runaway.
- Benign noise: `the input device is not a TTY` warnings from compose run
  and transient manifest-inspect failures (verify with a real pull before
  declaring an image missing).

## Verify after delegate (never skip)

Trust reports, verify state: `git status --short` clean; after fetch,
`HEAD == origin/<branch>`; greps for the artifacts the agent claims
(`grep -n '## Initialization' docs/...`); gates re-checked only when the
claim is suspicious. An agent's "done" is a hypothesis.

## Research campaigns

For multi-part questions (surveys, comparisons), see
[research-campaign.md](references/research-campaign.md): decompose into
per-domain matrices, parallel agents with evidence reports, orchestrator
synthesis into a durable doc — plus a debunked-lore list so dead claims
stay dead.
