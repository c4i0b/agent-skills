# Research campaigns

The pattern for answering big questions (image selection, tool
comparisons, best-practice validation) with parallel agents, validated in
a 9-agent image-selection campaign.

## Decompose by domain, not by count

Split the question into domains an agent can own end to end (one vendor,
one family, one angle). Each agent gets: the shared CONTEXT (the model/
decision being informed), its CANDIDATE matrix, and the exact TESTS to run
— evidence over claims, real commands, real outputs.

## Per-agent contract

- Work dir: `/tmp/opencode/<campaign>/<domain>/` (each agent owns its dir).
- Deliverable: `report.md` — per candidate: registry+tag, measured facts
  (sizes via `podman images`, versions, libc), test OUTPUTS (snippets),
  verdict (recommended / acceptable / avoid) with caveats.
- No git commits; containers `--rm`; keep pulled/built images listed.

## Orchestrator duties

- Write every dispatch prompt with the full shared context (agents share
  nothing); include what NOT to test (already covered elsewhere) — scope
  changes go by session-id follow-up.
- Synthesize: one durable doc (e.g. a skill reference) with decision rules
  first, then tables; /tmp reports are volatile, the doc is the durable
  part — say so in the doc header.
- Record a **debunked-lore** section: claims the tests killed ("X is
  musl", "Y ships gcc"). Without it, dead lore returns.
- Run a freshness pass after: verify tags/majors still current; add a
  self-update instruction to the doc.
