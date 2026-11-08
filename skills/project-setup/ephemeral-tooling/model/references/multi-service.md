# Variant: the repo also runs services

When the repo ships long-running services (not just a toolchain), keep the
ephemeral quality loop and add a dev/runtime split:

- One Containerfile per service with `dev` and `runtime` targets sharing
  the same lockfile, so parity is exact by construction.
- The base compose file declares the runtime; a `compose.override.yml`
  (auto-loaded) points at the `dev` target, bind-mounts the source `:z`,
  and runs as uid 0 for source writes.
- Tool caches (package manager, linters, test caches) go in named volumes
  so `compose run` containers do not re-resolve dependencies each time.
- Quality commands run against the dev target via
  `podman compose run --rm <service>`; runtime via `up`/`exec`.
- Restate `user` and `environment` in the compose service: podman-compose
  `run` containers use the service config and do not inherit image-level
  ENV/USER.
- Healthchecks must not assume a binary (no curl in minimal images): a
  python -c urllib one-liner works; point it at the dev venv path via an
  env knob.

Validated example: `finance` (private repo)
(compose.yml +
compose.override.yml + services/*/Containerfile).
