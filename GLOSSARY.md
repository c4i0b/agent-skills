# Glossary

Canonical vocabulary for this repo. Skills use these terms verbatim instead
of paraphrasing them.

- **reference skill** — holds knowledge. **flow skill** — orchestrates
  readings and gates, holds no knowledge of its own.
- **curriculum** — the single ordered reading list both flows start from
  (`project-setup/ephemeral-tooling/model/references/curriculum.md`).
- **gate** — a check that must pass before an action completes (commit,
  handoff, push). Gates here: `tests/scaffold-check.sh`,
  `tests/links-check.sh`.
- **fresh scratch** — a throwaway repo produced by following a flow, used to
  validate the flow itself.
- **validated example** — a real repo or run proving a skill's content.
  Variants ship only with one (or a certain recurrence).
- **candidate** — known missing skill or reference, deliberately unbuilt
  until a validated example exists (README lists them).
- **cheapest layer** — the lowest test-pyramid layer that can observe a
  behavior. A behavior is pinned there and nowhere else (dev-discipline).
- **latest-first** — tag policy: default to `latest` tags; a pinned major
  must be verified current (base-images).
- **minimal-with-balance** — smallest base that covers the need, but when
  installs approach the prebuilt image's delta, take the prebuilt
  (base-images rule 4).
- **verify-after-delegate** — an agent's "done" is a hypothesis: check repo
  state, not just the report (agent-orchestration).
- **debunked lore** — a claim killed by tests, recorded so it stays dead
  (base-images keeps the list).
- **seam-ready** — code shaped so behaviors can be tested at the cheapest
  layer: factories, ports, injection. The goal of refactor-for-testability.
- **same-brain oracle** — an expected value derived by the same mental
  model as the implementation (typically hand-computed); certifies bugs
  instead of catching them (testing-structure rule 5).
- **shift-invariant assertion** — one that still passes when values are
  relabeled onto wrong keys: ordering, counts, telescoping products,
  relative levels. Cannot detect relabeling bugs
  (testing-structure rule 6).
