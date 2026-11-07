---
name: ephemeral-tooling-setup
description: Flow to set up a NEW repo directly in the ephemeral tooling model. Read ephemeral-tooling-model, agent-docs and readme-shape first. Covers stack discovery, artifact creation order and the validation gate.
---

# Setup: new repo in the model

Read [curriculum.md](../model/references/curriculum.md) first — it is the
single reading list for both flows; skip the conditionals that do not
apply.

## Flow

1. **Discover the stack**: language, package manager, and the commands a
   developer runs (fmt, lint, test, build). If the repo runs services too,
   also read [multi-service.md](../model/references/multi-service.md). If
   it has tests, read
   [testing-structure](../../repo-foundations/testing-structure/SKILL.md)
   before writing the suite — and if it consumes external APIs, its
   catalog-and-recorder reference too.
2. **Containerfile**: bake the full toolchain for those commands. Complete
   on day one — no "install later". Base image: the stack's OFFICIAL image,
   `latest` tag by default (see [base-images.md](../model/references/base-images.md)
   tag policy); prefer the slim glibc variant unless musl is a deliberate
   choice.
3. **compose.yml**: the `tooling` service per the model (user 0:0, `:z`
   mount, ephemeral HOME).
4. **justfile**: `runner` prefix, `image`, `shell`, and one recipe per
   discovered command (thin dispatchers to scripts under `tools/` or
   `scripts/`). Check name collisions before adding recipes.
5. **Git hooks** (if the repo will have hooks): the wrapper pattern from
   the model; real logic in a script the wrapper executes in-container.
6. **AGENTS.md + docs/**: per agent-docs, including `docs/environment.md`
   describing this repo's container specifics. If task tracking is wanted,
   install the canonical workflow doc.
7. **README**: per readme-shape, variant by repo kind.
8. **`.gitignore`**: local scratch, `.beads/` if task tracking, nothing
   else speculative.

## Validation gate (must pass before handoff)

```sh
just image                # image builds
just <check>              # the quality command runs IN THE CONTAINER
just shell -c 'exit'      # interactive entry works (or equivalent smoke)
git commit --allow-empty -m x --dry-run   # hooks resolve if present
git log --oneline -1      # non-empty: the initial commit exists
```

End with the initial commit on the tree (the gate's dry-run proves hooks;
only a real first commit proves the repo exists).

Hand off with: what was created, the gate output, and what was deliberately
left out (candidates).
