---
name: gh-actions-conventions
description: GitHub Actions conventions for repos in this family. Pinned action SHAs, bash-invoked scripts, concurrency groups, the push-retry dance, [skip ci] semantics, GITHUB_TOKEN event suppression escape hatches, job time bounds, workflow naming by pipeline role, and the bash-vs-python script split. Use when writing or reviewing workflows for a repo that follows these conventions.
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
   unbounded hang burns a runner for six hours.
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
