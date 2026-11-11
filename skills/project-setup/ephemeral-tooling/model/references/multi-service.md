# Variant: the repo also runs services

When the repo ships long-running services (not just a toolchain), keep
the ephemeral quality loop and add a dev/runtime split. The deployment
side of that split has its own contract — read
[deployment-contract.md](deployment-contract.md) together with this
file: the split defines what may differ between dev and prod, the
contract defines what must not.

## Dev/runtime split

- One Containerfile per service with `dev` and `runtime` targets sharing
  the same lockfile — parity exact by construction.
- The base compose file declares the runtime; a dev variant (separate
  file, selected via `-f`) carries only topology: host networking where
  an engine quirk requires it, engine socket, repo-checkout binds. A
  dev file must never remove or disable a default-deployment service
  (red: a dev override silently profiled the bootstrap out of the
  published stack).
- Tool caches (package manager, linters, test caches) go in named
  volumes so `compose run` containers do not re-resolve dependencies.
- Quality commands run against the dev target via
  `podman compose run --rm <service>`; runtime via `up`/`exec`.
- Provenance distinctions (dev vs prod) live in files and profiles,
  never in image names — a runtime sidecar legitimately reuses the
  tooling image and carries the reference with it (a `:dev` tag leaks
  the split into the deployment).
- Topology differences belong to thin per-topology runners; knowledge
  belongs to the shared script both execute. Runners carry only what
  actually differs (network mode, engine socket, service addresses);
  every logic and wiring step lives in one script dev and prod both
  run.

## Runtime mechanics

- Restate `user` and `environment` in the compose service: podman-compose
  `run` uses the service config and does not inherit image-level
  ENV/USER.
- Healthchecks must not assume a binary (no curl in minimal images): a
  python -c urllib one-liner works; point it at the dev venv path via
  an env knob.
- A healthcheck answers "can this container serve its purpose in
  isolation" — never the availability of an external system:
  orchestrated platforms restart, alert at, or replace on it (red: a
  healthy sidecar flagged unhealthy because its check read content
  gated by an upstream 403). External dependencies belong in
  monitoring. Gate: no healthcheck command fails on an HTTP error
  status alone.

Validated examples: `finance` (private), a private media stack — both
with compose pairs and per-service Containerfiles.
