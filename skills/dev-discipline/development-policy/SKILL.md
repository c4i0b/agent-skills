---
name: development-policy
description: The day-to-day coding discipline a repo's agents follow. Test-first always, cheapest pyramid layer, refactor for testability with modularity as the consequence, warnings fixed at root cause. Seeded as the repo's docs/development.md with one-liners in AGENTS.md. Use when creating a repo's development policy or seeding its docs.
---

# Development policy

The ongoing discipline. The setup flow's day-one seed covers structure
only: this policy governs every day after. Validated in production in the
finance repo.

## Rules

1. **Test-first, always.** The test is written or adjusted before or with
   the implementation. Code never lands bare.
2. **Cheapest layer first.** Before writing a test, decide which pyramid
   layer sees the behavior (see
   [testing-structure](../testing-structure/SKILL.md)). Write it there and
   only there.
3. **Refactor for testability.** If a behavior can only be verified at an
   expensive layer, refactor the code first: seams, ports, injection.
   Modularity is the consequence of this rule, not a separate initiative.
4. **Warnings at root cause.** Fix the warning, not the symptom. Filters
   only narrow (module plus message) and carry a removal trigger comment.
5. **Explicit over implicit.** Declare effects at the boundary. Validate
   degenerate inputs before third-party math.
6. **Dead code is deleted**, never commented out.
7. **Fixes outlive the incident.** A fix valid only until the next upstream
   bump is unfinished: one definition per repeated constant, derive what
   upstream controls (metadata, globs) instead of restating it, and
   match-driven edits (seds, selectors) fail loud when the pattern drifts —
   a silent no-op is a deferred failure.
8. **Class knowledge lives in shared artifacts.** The lesson goes where
   the next consumer inherits it — the repo's docs or templates — never as
   a fix-local comment; and check the siblings: one member's fix usually
   applies to the whole family.

## Seeding (setup flow)

The target repo gets two artifacts:

- `docs/development.md`: the rules above adapted to the repo, one worked
  example per rule once the repo has one.
- `AGENTS.md` Development section: the test-first rule verbatim plus a
  one-line pointer to `docs/development.md`.

A repo is self-sufficient when its lean AGENTS.md plus its own docs cover
environment (per the model) and development (per this policy) without
external references.
