---
name: gh-actions-conventions
description: GitHub Actions conventions for repos in this family. Pinned action SHAs, bash-invoked scripts, concurrency groups, the push-retry dance, [skip ci] semantics, GITHUB_TOKEN event suppression escape hatches, gate-before-main for bot commits on gated paths, job time bounds, prebaked runner images vs per-run installs, registry image auth/visibility, workflow naming by pipeline role, and the bash-vs-python script split. Use when writing or reviewing workflows for a repo that follows these conventions.
---

# GitHub Actions conventions

Every rule below has an observed red behind it. Build models differ (some
builders pull from the repo via webhook, some are pushed to); the
conventions here are the model-independent core.

## Rules

1. **Pin actions by commit SHA**, never a mutable tag: a tag can be moved
   and defeats review of what runs.
2. **Invoke repo scripts as `bash <script>`**, not direct exec: immune to
   a lost executable bit. Red: two scheduled runs died with exit 126 on a
   mode-644 script.
3. **Bound every job with `timeout-minutes`** sized for hangs, not for
   legitimate slow runs (quick checks ~5–15, full validation ~90): an
   unbounded hang burns a runner for six hours. Red: a 15-package batch
   delivery exceeded a per-step budget sized for single-package pushes
   and died half-delivered.
4. **Serialize same-purpose workflows** with a `concurrency` group and
   `cancel-in-progress: true` when runs are idempotent (scheduled
   bumpers); `false` when each run carries work the next would drop
   (deliveries).
5. **Push-retry dance** for bot commits: `git push || (sleep 15; git
   pull --rebase [-X theirs] origin main && git push)`. Red: concurrent
   runs racing on main.
6. **`[skip ci]` on chore pushes** (status-artifact refreshes): keeps
   validation workflows quiet; chore commits must genuinely never touch
   the paths that trigger builds.
7. **GITHUB_TOKEN pushes fire no `push` events.** Anything that must react
   to bot-made commits needs `workflow_run` on the producing workflow.
   Red: bumps merged by an auto-merge workflow silently never reached the
   builder for months.
8. **React only to successful `workflow_run` completions** — the trigger
   also fires on skipped and failed runs.
9. **Least permissions per workflow** (`contents: read` unless it
   commits; `actions: write` only where the runs API is queried) and
   `fetch-depth: 0` only where history is actually diffed.
10. **Validate workflow YAML** wherever a workflow merges PRs
    automatically, before merging.
11. **Bot commits touching gated paths pass a gate before main.**
    GITHUB_TOKEN pushes suppress `push` events but not delivery (the
    COPR webhook fires on token pushes; workflow_run wiring fires
    too) — a direct bot push skips every GitHub-side gate and reaches
    the builder first. Either open the PR with a workflow-triggering
    credential, or run the gate inside the bumper job on its branch
    and merge that exact SHA (dependency-bump's gate-in-job mode);
    the merge waits on the gate — a merger that outruns checks
    recreates the red. Direct pushes remain for commits no gate
    observes (rule 6's chore condition). Reds: three direct
    autoupdate bumps shipped broken to the builders across two
    packaging repos (dead upstream asset; a version failing %check on its
    declared runtime; vendoring breaking at SRPM time) — the first two
    observable by validate,
    which never ran — and a bump PR merged with validate red because
    the merger didn't wait on checks.
12. **Prefer a prebaked runner image over per-run package installs
    when the install window varies.** Judge on variance, not just
    minutes: a slow mirror destabilizes the timeout bound (rule 3
    sizes it for hangs, not for install luck), and a published image
    also removes the keep-two-package-lists-in-sync trap (CI no
    longer re-derives the environment) by construction. The image is
    built once and pulled many times, so it lands BEFORE any
    consumer references it (two-phase: publish, then reference —
    near-miss, caught at plan time). Staleness is its default state:
    a rebuild trigger belongs in the same change that introduces the
    image (no red yet — candidate until one lands). Red: a 19–75 s
    install window with ~3x mirror variance made runs flaky and
    timeout sizing guesswork.
13. **The job's image pull does not carry the CI token.** A private
    registry image needs explicit auth in the job; a public one
    avoids it — but a first-publish visibility change may be denied
    to the CI token even when the push itself succeeded (ownership
    rules differ from write permission): the bootstrap then ends
    with one documented manual step, not a fully automated one.
    Red: the image push succeeded with the write-scoped CI token,
    the job pull failed unauthenticated, and the visibility API
    call failed on the same token.

## Naming and responsibilities

Name workflows by pipeline role (a change gate, a delivery, a status
reporter, a scheduled automation, a bot merger) — not by the tool du
jour — and keep the file name equal to the workflow `name:`. The repo's
concrete role catalog comes from its pipeline shape and belongs in the
repo's own CI docs, not here.

Red: a file named after the bot with `name:` after the behavior — two
names for one workflow sends humans and agents to different places.

## Script language

Bash for orchestration (git, builder CLIs, push-retry); Python for data
(JSON/API parsing, multi-file rewrites, linting). Do not rewrite a stable
script in the other language without a red: churn is not durability.
