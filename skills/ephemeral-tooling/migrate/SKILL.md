---
name: ephemeral-tooling-migrate
description: Flow to migrate an EXISTING repo into the ephemeral tooling model (from distrobox, host tooling, venvs or ad-hoc containers). Read ephemeral-tooling-model, agent-docs and readme-shape first. Covers auditing the current environment, translating it, proving parity, and only then removing the old mechanism.
---

# Migrate: existing repo into the model

Read [curriculum.md](../model/references/curriculum.md) first — it is the
single reading list for both flows; skip the conditionals that do not
apply.

Work on a branch off an updated main. Do not remove the old mechanism until
the parity gate passes.

## Flow

1. **Audit the current environment** (do not skip):
   - How do commands run today? (distrobox, host-installed tools, venv,
     make, docker) Read the entrypoints (Makefile/justfile/README) and
     every script they call.
   - Inventory: every tool each recipe invokes, including sudo uses,
     privileged steps (mock-style sandboxing), and anything writing outside
     the repo.
   - Credentials: how does the current setup reach tokens/keys? Anything in
     a host system keyring (e.g. gh) is unreachable from containers —
     decide host-side vs mounted file per the model.
   - Git hooks: where does hook logic run today, and what toolchain does it
     need?
   - Tests: do any depend on network or live services? The target state is
     offline-by-default with live layers opt-in — apply
     [testing-structure](../../dev-discipline/testing-structure/SKILL.md)
     when migrating the suite.
   - CI: how does it run today? Wire the DIRECT bypass
     ([ci-bypass.md](../model/references/ci-bypass.md)) if recipes must run
     there too.
2. **Translate**: Containerfile (full audited toolchain; privileged tools
   get their rootless fallback), compose.yml, justfile runner swap, hook
   wrapper. Keep recipe names unless they collide.
3. **Validate IN the container**, one recipe at a time: lint/quality,
   one-unit build, status/remote commands (token mounts), hook from host
   git. A migrating justfile that parses is not a migrated justfile.
4. **Docs pass**: rewrite the environment docs (AGENTS.md lean + docs/) and
   the README per the reference skills; grep for leftovers of the old
   mechanism (names, paths, .gitignore entries) before finishing.
5. **Parity gate** (all in the new model): the repo's full quality command,
   one real production command end to end, hook, credentials, clean tree.
6. **Remove the old mechanism** (boxes, ini files, host setup scripts) and
   delete its gitignored state dirs — they may contain root-mapped files
   that need the container runtime's unshare helper to delete.
7. **Merge and push.** Migrations that touch no product code should not
   trigger rebuilds/deploys; verify the trigger semantics if the repo has a
   webhook/CI.

## Pitfalls seen in a real migration

- Recipe name collision (`image`-build recipe vs existing `build <name>`).
- gh token in the host keyring: containers cannot read it, and exporting
  tokens to files is a decision to make explicitly, not silently.
- Privileged tools (mock) need `--isolation=simple` under rootless podman;
  validated on first real use.
- Old container homes may hold root-mapped files: `podman unshare rm -rf`
  deletes what plain `rm` cannot.
