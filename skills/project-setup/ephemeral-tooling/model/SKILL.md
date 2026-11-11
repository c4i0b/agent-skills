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
  naming across repos). The service MUST also declare `build:` pointing at
  the Containerfile: with only `image:`, `podman compose build` is a
  **silent no-op** (exit 0, no image built) and the failure surfaces
  later, displaced, at the first `run`.

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
- `just shell` for interactive work. Recipe logic lives in `tools/`
  (both validated repos share this; skills ship script sources in
  their own `scripts/` and install them into the repo's `tools/`).
  `scripts/` in a repo is for application-support scripts the app
  itself runs, never just recipes. The justfile stays a dispatcher.

**git hooks** — wrapper pattern: `.githooks/pre-commit` runs the real hook
script wherever the toolchain lives — directly inside the container
(`just shell`), or through `podman compose run` when invoked by host git.

## Hard-won invariants

- Recipe names: check for collisions before adding (an `image`-build recipe
  named `build` collided with an existing `build <name>` recipe).
- Repo toolchain file (rust-toolchain.toml, mise.toml, .tool-versions):
  it selects a toolchain by NAME, and components installed into the
  image default do not satisfy it. Red: rustup components landed on
  the image's 1.99 while the file asked for stable. The first clippy
  run auto-downloaded ~150 MB at runtime. The Containerfile looked
  complete and was not. Fix: run the toolchain manager's install from
  the repo directory so it reads the file, then add components.
- Tools needing real privilege: a rootless container without capabilities
  cannot grant them — mock, for example, is known-broken unprivileged
  (needs CAP_SYS_ADMIN for tmpfs/proc mounts) and requires a
  `privileged: true` service, which under rootless podman never exceeds the
  unprivileged host user (upstream-documented). Escalation belongs in a
  dedicated service, not the everyday tooling container.
- Commands needing the HOST user session (systemctl --user, unit and
  calendar validation) get neither privilege nor a service: the session
  bus lives on the host. All three traps observed:
  - create `/run/systemd/system`: systemctl checks sd_booted() first and
    answers offline without ever trying the socket
  - bind-mount only the bus socket FILE, never the runtime dir: as
    uid 0 sd_bus prefers systemd/private and the handshake fails
    ENODATA. The single-file mount forces the session-bus fallback
  - `security_opt: ["label=disable"]`: SELinux blocks the socket
    otherwise
- The justfile runner prefix executes commands in the container: verify
  each migrated command there, not only that the justfile parses.
- Vendor images with tool ENTRYPOINTs (Chainguard `-dev`) swallow compose
  commands: set `entrypoint: []` on the service (observed: cargo ate
  `compose run` commands).
- just shebang recipes receive no `$@` unless `set positional-arguments :=
  true` (observed: arg-based recipes silently ran without arguments).
- `podman compose run` never EOFs forwarded stdin: stdin-driven runs hang.
  Take arguments, not stdin (observed: a run recipe hanging forever).

## References

- [curriculum.md](references/curriculum.md) — the single reading list both
  flows start from (and the map of everything this model consumes)
- [base-images.md](references/base-images.md) — choosing the Containerfile
  base: tooling vs runtime, per-case validated table
- [multi-service.md](references/multi-service.md) — when the repo also
  runs services: dev/runtime split and runtime mechanics
- [deployment-contract.md](references/deployment-contract.md) — the
  published deployment: state, service set, code, networking and the
  validation ladder (parser gate, cold deploy, release identity)
- [credentials.md](references/credentials.md) — how credentials reach the
  container (or stay host-side)

The quality loop stays hermetic when the suite is offline-by-default —
see [testing-structure](../../../dev-discipline/testing-structure/SKILL.md)
for the suite-side of that contract.
- [ci-bypass.md](references/ci-bypass.md) — CI parity via the DIRECT bypass

## Validated examples

- [`fedora-packages`](https://github.com/c4i0b/fedora-packages) — single
  tooling container
- `topmatic` (private repo) — single tooling container, plus the
  dependency-bump and release skills composed on top
- `finance` (private repo) — tooling + service
  containers
