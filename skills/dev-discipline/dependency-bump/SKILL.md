---
name: dependency-bump
description: Routine dependency-and-image-tag bump with cheap local checks and a PR that auto-merges on green branch CI. Stack-agnostic (uv, poetry, npm, pnpm, yarn, go, cargo, bundler) via a data table in the one stdlib Python script. Use when bumping deps or refreshing image tags in any repo.
---

# Dependency bump (check, merge)

A flow, not knowledge: tag policy and current majors live in
[base-images.md](../../project-setup/ephemeral-tooling/model/references/base-images.md)
(keep the script's `CURRENT` table in sync with its Freshness list);
cheapest-first check ordering lives in
[testing-structure](../testing-structure/SKILL.md).

Why this exists (observed red): an EOL image tag once shipped unnoticed
(the failure `tests/scaffold-check.sh` now asserts against), and dependency
age is a certain recurrence in every repo. Renovate-style autoupdate is
rejected (DECISIONS.md), so the bump surface we own is one stdlib script.
Field reds from the finance repo: tag drift hidden behind `ARG
BASE_IMAGE=ref:tag` indirection (the scanner must read ARG lines, not
just FROM), digest pins parsing the sha hex as a tag, and `uv lock
--upgrade` rewriting a lockfile's content-hash with zero version moves
(a changed file is not a bump — gate on version-level changes and
revert churn, or the flow erodes trust with no-op PRs).

## Tooling base (validated)

`cgr.dev/chainguard/wolfi-base` + `apk add git python-3 gh` — validated
live (the package is
`gh`, NOT `github-cli` — it does not exist in wolfi). glibc means the
native updaters' prebuilt binaries run. Per base-images.md rule 4 this
is the minimal base that covers the need.

## Flow

1. Copy `scripts/bump.py` into the repo as `tools/bump.py` and add a
   thin justfile recipe:

   ```just
   bump:
       {{runner}} python tools/bump.py
   ```

2. Run `just bump` (updaters run in the tooling container, where the
   toolchain lives). Credentials: the script also pushes and calls `gh`,
   so it needs token-based gh auth reachable from there (`GH_TOKEN` env
   or `~/.config/gh` mounted ro). If credentials are keyring-based,
   run with `--no-pr` in-container and do the PR host-side (the model
   keeps push/credentials tooling where the credentials live).
3. Checks are the repo's own cheapest gates — `just lint` and `just test`
   when the recipes exist; the full matrix stays on branch CI.
4. Merge is `gh pr merge --auto --squash`: the PR merges only when
   branch CI goes green, so cheap local checks + full CI both gate the
   merge. Auto-merge requires branch protection with the CI check as
   required — and **no required reviews**: the PR author cannot approve
   their own PR, so required reviews stall a solo auto-merge forever
   (observed in validation: PR armed, CI green, sat OPEN until reviews
   were dropped from protection). Auto-merge triggers on check
   completion — if protection changed after arming, re-run the merge
   command to re-arm. Without auto-merge enabled the script leaves the
   PR open and says so.
   Repo setup checklist (all default-off, each has blocked a real run):
   - branch protection: CI check required, no required reviews
   - repo Settings: Allow auto-merge, else `--auto` does not arm
   - repo Settings: Allow GitHub Actions to create and approve pull
     requests (red: GraphQL "GitHub Actions is not permitted to create
     and approve pull requests")
   Running the bump from Actions with the default `GITHUB_TOKEN`: events
   it creates do not trigger workflows, so branch CI never runs and
   `--auto` never merges (red: PR armed, checks `[]` forever, merge
   never fired). Either give the job a workflow-triggering credential
   (PAT or App) or run the full gate inside the job itself and merge
   explicitly. In that second mode remove the required check from
   protection, else it blocks the very merge it was meant to guarantee.
5. Scripts must stay environment-agnostic (see
   [ci-bypass.md](../../project-setup/ephemeral-tooling/model/references/ci-bypass.md)):
   `bump.py` derives nothing from container-only paths.

## Any stack

The stack table is data, not code: manifest marker → native updater
command. A stack is "supported" when its lockfile has a native
conservative updater; new rows ship only when a real repo needs them
(no speculation). Stacks without a lockfile-native updater (maven, raw
requirements.txt) fall back to image-tag fixes plus a report — never
regex-bump manifests by hand in the script.

## PR description

Lean, single table: one-line summary (`Updates 3 dependencies, 1 major
and 1 image tag.`), then `| What | From | To |` rows — majors first
with ⚠️ and bold on the new version, then the rest, then image tags.
Review-only findings (untracked images, codenames, version-in-repo-name)
go under `### Not bumped (manual decision needed)` — informational:
the auto-merge never waits on them, they list what this bump
deliberately left alone; manifest diffs (small) append verbatim;
lockfiles never paste, they summarize from the version diff. Zero counts
and minor/patch types are omitted — major is the only classification
that changes how a human reviews.

When action is required (auto-merge fails to arm, or cheap checks
abort), the warning leads the body — heading, bold WHAT, 1-3 bullets,
details pointer. The reader grasps the situation in the first third of
the body without parsing a run-on sentence. The failed-merge warning is
prepended to the live PR via `gh pr edit`; the failed-checks warning
goes to the run output (there is no PR to edit — nothing landed).

## Safety rails

- `--dry-run`: report tags and which updaters would run; mutates nothing.
- Failed updater: warning, continue; failed cheap check: abort with the
  worktree dirty for inspection (nothing committed, nothing pushed).
- Codename and untracked tags are reported for manual review, never
  rewritten (exception: Debian codenames map to the current number,
  suffix preserved — `bookworm-slim` → `13-slim`). Non-numeric tags on
  non-debian families are never rewritten either (red:
  `rust:slim-bookworm` became `rust:1.99`, losing the slim variant and
  pinning the major).
- A floating major with a variant suffix (`rust:1-slim`) is current,
  not a finding: recurring review-by-hand noise on the recommended
  form erodes trust in the report.
- Lockfile churn with zero version moves is reverted, never PRed.
- Distribution channels: a release-pinned channel (the default — see
  [distribution-channels](../distribution-channels/SKILL.md)) is
  bump-neutral: its pin advances only at the release event, so a
  lockfile bump never invalidates a channel hash. A rolling-main
  channel's hashes can be invalidated by a bump, and token-driven
  bump events do not trigger the PR's CI — there the bump workflow
  itself must carry a fail-closed hash regen, never a regex rewrite.
