---
name: release
description: Agent-driven releases. Three stages with one publishing boundary. plan is a read-only JSON planner, prepare bumps version files and changelog reversibly, publish runs the irreversible steps gated fail-closed on clean tree, release commit and exact-SHA CI. Use when cutting a release in any repo.
---

# Release (plan, prepare, publish)

A flow, not knowledge: tag policy and version conventions live in the
repo being released. Like
[dependency-bump](../dependency-bump/SKILL.md): the agent decides what
the release means, the script decides what is permitted, CI proves it
is safe.

## Mechanisms

- One publishing boundary. `plan` and `prepare` are read-only or
  reversible. `publish` is the only irreversible stage and requires
  `--yes` plus every gate below.
- Fail-closed CI gate: green means completed successful runs on the
  exact commit being released. Zero runs is a refusal, not a pass
  (field red: a PR armed with `--auto` sat with checks `[]` forever
  because `GITHUB_TOKEN` events do not trigger workflows. Publish must
  run outside Actions or with a workflow-triggering credential).
- Published history is immutable. Tag already present means fix
  forward with a new version, never retag or rewrite. A failed GitHub
  Release keeps the tag: create the release manually on it.
- Verify after publish: the exit code of `gh release create` is not
  the end, `gh release view` confirms the state.
- Credentials are env-injected into the container (`GH_TOKEN`,
  registry tokens), never baked and never in argv (see the
  ephemeral-tooling
  [credentials reference](../../project-setup/ephemeral-tooling/model/references/credentials.md)).

## Flow

1. Copy `scripts/release.py` into the repo as `tools/release.py` with a
   thin `release` justfile recipe (the `runner` prefix keeps it
   in-container).
2. `release.py plan --bump minor` (or `major`, `patch`, `X.Y.Z`): the
   agent reads the JSON state (current version, target tag, changelog
   section present, tree clean) and decides the bump from what users
   will see, not from commit labels alone.
3. The agent writes the changelog section content (keep-a-changelog
   sections, human wording). The script only validates that the
   section exists: `## [Unreleased]` becomes `## [X.Y.Z] - date` at
   prepare.
4. `release.py prepare --bump X.Y.Z`: bumps every detected version
   file (Cargo.toml, pyproject.toml, package.json), dates the
   changelog section and creates the `release: vX.Y.Z` commit. Abort
   is safe: nothing tagged, nothing pushed.
5. `release.py publish --bump X.Y.Z --yes`: gates in order (clean
   tree, tag absent, changelog section, HEAD is the release commit,
   CI green on that SHA), then annotated tag, `gh release create
   --verify-tag` with the changelog section as notes, and the
   post-publish view.

## Safety rails

- `--dry-run` equivalent is `plan`: it mutates nothing.
- Registry publishing (cargo, npm, pypi) is deliberately out of the
  script: it ships only when a real repo needs it, as a data table in
  the style of dependency-bump's updaters.
- Version files without a semver `version` field stop the flow with
  the file named, never a guess.

## Validated example

Scratch demo (`plan` read-only, `prepare` across Cargo.toml +
package.json, and every publish refusal exercised: no `--yes`, dirty
tree, no CI evidence, existing tag). First real repo release upgrades
this entry.
