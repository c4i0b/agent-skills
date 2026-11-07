---
name: ephemeral-tooling-model
description: The ephemeral tooling-container model. Host provides only just and podman; every command runs in a throwaway container built from a Containerfile that owns the whole toolchain. Covers image contract, compose service, justfile dispatcher, git hooks and credentials. Read before any setup or migration to this model.
---

# The ephemeral tooling model

Host contract: the host provides only `just` + `podman`. Everything the work
needs — toolchain, linters, build tools — lives in the image. Pushes and
credentials tooling (git push, gh) stay host-side.

Core principle: **no state survives a run; if it is not in the image, it
does not exist.** The image is the contract; containers are disposable.
Every command runs via `podman compose run --rm tooling` (ephemeral) —
deterministic environments, safe parallelism, zero idle cost.

## Artifacts

**`Containerfile`** — the environment, complete:

- Base image matching the project's target (e.g. the distro the CI builds).
- Bake the FULL toolchain: runtimes, linters, build tools, anything a
  recipe invokes. A missing tool is a Containerfile bug, not an
  install-at-runtime.
- Repo-agnostic config (e.g. system gitconfig) belongs here; host dotfiles
  never do.

**`compose.yml`** — one `tooling` service:

- Image tagged `<project>/tooling:dev` (compose `image:` field; consistent
  naming across repos).

- `user: "0:0"` — in rootless podman this maps to the unprivileged host
  user (no host privilege gained) and is the only uid that can write the
  bind-mounted source.
- `working_dir` at the mount point; repo bind-mounted with `:z` (SHARED
  SELinux label, so concurrent runs keep access). Use `:Z` only for
  single-consumer mounts like read-only credentials.
- Ephemeral `HOME` (e.g. `/tmp`): session caches die with each run, so
  stale-session bugs cannot accumulate. Named volumes for caches worth
  keeping.
- Credentials: host files mounted `ro` (e.g. `~/.config/<tool>`); anything
  in a host system keyring is unreachable from containers — keep that
  tooling host-side instead of exporting tokens.

**`justfile`** — thin dispatcher:

- A `runner` variable prefixing every recipe with
  `podman compose run --rm tooling`; an env bypass (e.g.
  `PROJECT_DIRECT=1`) lets CI run recipes directly.
- `just image` builds the image and does one-time host setup (git hooks
  path); idempotent, layer-cached, near-instant unless a layer changed.
- `just shell` for interactive work. Recipe logic lives in scripts; the
  justfile stays a dispatcher.

**git hooks** — wrapper pattern: `.githooks/pre-commit` runs the real hook
script wherever the toolchain lives — directly inside the container
(`just shell`), or through `podman compose run` when invoked by host git.

## Hard-won invariants

- Recipe names: check for collisions before adding (an `image`-build recipe
  named `build` collided with an existing `build <name>` recipe).
- Tools needing real privilege: a rootless container without capabilities
  cannot grant them — mock, for example, is known-broken unprivileged
  (needs CAP_SYS_ADMIN for tmpfs/proc mounts) and requires a
  `privileged: true` service, which under rootless podman never exceeds the
  unprivileged host user (upstream-documented). Escalation belongs in a
  dedicated service, not the everyday tooling container.
- The justfile runner prefix executes commands in the container: verify
  each migrated command there, not only that the justfile parses.

## References

- [multi-service.md](references/multi-service.md) — when the repo also runs
  services (dev/runtime targets, override file)
- [ci-bypass.md](references/ci-bypass.md) — CI parity via the DIRECT bypass

## Validated examples

- `/home/caio/Projects/fedora-packages` — single tooling container
- `/home/caio/Projects/finance` — tooling + service containers
