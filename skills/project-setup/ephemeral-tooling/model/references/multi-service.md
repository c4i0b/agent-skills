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
- Runtime state (service config, data) also defaults to named volumes in
  the base compose file; host bind storage is an opt-in through one env
  var (e.g. `STATE_DIR`). A path in the published compose file must
  never default to `${HOME}` or any host-session variable: orchestrated
  runners (CI, container-management UIs) interpolate the file where
  those are unset and the path silently collapses to `/` (observed:
  pipoca — every service bind-mounted from `/`, `create_host_path: true`
  made it root-owned; compose validated fine, containers started).
- Interpolation cannot switch `type:` — the env var selects a FILE: the
  default compose (named volumes) plus a host-storage variant passed via
  `-f`. In the host variant use the required-variable form
  `${STATE_DIR:?message}`: a missing var aborts loudly instead of
  collapsing (the original red was silent; loud is the point).
- A sidecar that needs the whole state tree cannot nest named volumes:
  mount the leaf volumes at their subpaths and give root-level state
  files (stamps) their own small volume. Observed in pipoca: a stamp
  written into an anonymous dir vanished on restart and the curation
  loop re-fired weekly.
- A dataset shared by several services is ONE shared volume, never one
  volume per mount: per-mount splits break cross-service file handoff
  (a downloader writing what another service hardlinks or moves).
- Quality commands run against the dev target via
  `podman compose run --rm <service>`; runtime via `up`/`exec`.
- Restate `user` and `environment` in the compose service: podman-compose
  `run` containers use the service config and do not inherit image-level
  ENV/USER.
- Healthchecks must not assume a binary (no curl in minimal images): a
  python -c urllib one-liner works; point it at the dev venv path via an
  env knob.

Validated examples: `finance` (private repo; compose.yml +
compose.override.yml + services/*/Containerfile), `pipoca` (media
stack: named-volume state, `compose.host.yaml` opt-in with
`${STATE_DIR:?}`, sidecar leaf-mounts).
