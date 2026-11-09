# Variant: the repo also runs services

When the repo ships long-running services (not just a toolchain), keep the
ephemeral quality loop and add a dev/runtime split.

## Images and the dev/runtime split

- One Containerfile per service with `dev` and `runtime` targets sharing
  the same lockfile, so parity is exact by construction.
- Keep provenance distinctions in files and profiles, not in image
  names: a `:dev` tag on a runtime sidecar leaks the dev/prod split
  into deployment (the sidecar legitimately reuses the tooling image
  and carries the reference with it).
- The base compose file declares the runtime; a `compose.override.yml`
  (auto-loaded) points at the `dev` target, bind-mounts the source `:z`,
  and runs as uid 0 for source writes.
- Tool caches (package manager, linters, test caches) go in named volumes
  so `compose run` containers do not re-resolve dependencies each time.
- Quality commands run against the dev target via
  `podman compose run --rm <service>`; runtime via `up`/`exec`.

## The published deployment

Invariant: **a production service is self-contained** — everything it
needs at runtime ships in its image or in named volumes; nothing may
come from the developer's session (environment variables, engine
quirks, local image names, the repository checkout, the host's network
position). Each rule below
was found the hard way: one real deploy failing per leak (all observed
in a private media stack). Validating an artifact with the producer's
parser proves nothing about the consumer's.

### State

- Runtime state (service config, data) defaults to named volumes in
  the base compose file; host bind storage is an opt-in through one env
  var (e.g. `STATE_DIR`). A path in the published compose file must
  never default to `${HOME}` or any host-session variable: orchestrated
  runners (CI, container-management UIs) interpolate the file where
  those are unset and the path silently collapses to `/` (observed:
  a private media stack — every service bind-mounted from `/`, `create_host_path: true`
  made it root-owned; compose validated fine, containers started).
- Interpolation cannot switch `type:` — the env var selects a FILE: the
  default compose (named volumes) plus a host-storage variant passed via
  `-f`. In the host variant use the required-variable form
  `${STATE_DIR:?message}`: a missing var aborts loudly instead of
  collapsing (the original red was silent; loud is the point).
- A dataset shared by several services is ONE shared volume, never one
  volume per mount: per-mount splits break cross-service file handoff
  (a downloader writing what another service hardlinks or moves).
- A sidecar that needs the whole state tree cannot nest named volumes:
  mount the leaf volumes at their subpaths and give root-level state
  files (stamps) their own small volume. Observed in a private media stack: a stamp
  written into an anonymous dir vanished on restart and the curation
  loop re-fired weekly.

### Service set

- A service that cannot run on a plain Docker host — container-engine
  socket binds, repo-checkout binds, `localhost/` image refs — sits
  behind a compose `profile` (e.g. `dev`); plain `up` then deploys only
  what the target can run, and the dev flow enables the profile
  (observed: the same media stack via a container UI — an init service mounting the podman
  socket and a sidecar pinned to `localhost/` broke a deployment whose
  production services were all fine).
- Classify services by role, not by image: a sidecar built FROM the
  tooling image is still runtime when production degrades without it
  (boot-time data, scheduled maintenance). The test: "if this service
  vanished in production, does a feature degrade?" If yes, give it a
  registry-safe image plus a declared `build:` — never a profile.
  Misfiling on "uses the dev Containerfile" silently breaks the feature
  it serves.
- Work performed by a dev-only service must have a production path: a
  dev-only init doing first-boot wiring (credentials, desired state)
  leaves the deployment applying none of it (observed: a fresh stack
  came up answering 401 for the documented default credentials). Ship
  the wiring as a one-shot service in the DEFAULT deployment running
  the same idempotent scripts from the baked image — re-runs converge,
  so dev and prod can both run it.
- When dev and production reach a service through different networks,
  credential bootstrap that leans on the service's own first-boot
  mechanism is suspect: upstream hardening increasingly scopes those
  mechanisms to loopback, and the bridge-network production runner is
  not loopback (observed: qBittorrent-style ≥5 hardening — the
  host-network dev runner never noticed). The robust pattern: the
  service sets its own credential through its API, executed from inside
  its own container via the engine CLI (`exec`) — same network position
  as the service, zero topology assumptions.

### Code

- Runtime code reaches a production service only through its image:
  bake what the entrypoint needs — COPY of the code dirs plus every
  data file the code loads at boot (observed: the same stack — a sidecar
  crash-looped on the deploy host with `can't open
  /project/scripts/...`; its code arrived through a repo bind, and a
  web-editor deploy ships no repo). The dev bind stays as a mount over
  the same path, SHADOWING the baked copy — live editing keeps working,
  one image, one recipe, no dev/prod split — but the service must start
  and run with the bind absent. Gate: no non-dev service carries a
  relative bind source in the published compose file, the image recipe
  COPYs the runtime code dirs, and an offline (`--network none`)
  container imports the entrypoint — the read graph (config/manifest
  files loaded at boot, not just code) ships or the import fails.

### Networking

- Prefer the bridge with published ports in the published compose file:
  host networking is an engine/host-specific optimization, not a
  portable default. On a remote host, host-network traffic terminates
  ON the host, so the host firewall filters it — while published bridge
  ports go through the engine's DNAT, which host firewalls do not
  (observed: same file, opposite reachability per service — the
  host-network WebUI unreachable from the LAN, every published bridge
  port fine). Keep host networking in the dev/engine variant, and
  document there which engine quirk it works around (e.g. rootless
  podman breaking UDP/DHT on the bridge) so the variant stays
  justifiable.
- Reach services by env-overridable URL, never a hardcoded localhost:
  the dev runner sits on the host network; a bridge-network production
  runner reaches services by name and sometimes a different port. URL
  hardcoding is the same leak class as a `${HOME}` default — fine in
  the dev session, wrong on the target.

### Validation

- Validate the published file with the deployment target's own parser:
  run its `compose config` in an ephemeral container — file piped via
  stdin (a bind mount would resolve on the host when talking to a host
  engine through a socket), `--network none`, empty environment
  (`env -i`): the empty environment IS the orchestrated runner. Gate it
  with the offline suite; skip with a warning when hermetic-only or no
  container client exists. First run of this check caught two
  deploy-breakers that months of producer-side validation tolerated
  (observed: the same stack — compose interpolation ate a literal shell `$i` in
  a service command, escape as `$$`; and podman-extension volume keys
  `selinux`/`create_host_path` aborted the target schema — the
  published file emits spec-clean binds, engine keys stay in the dev
  variant). The gate proves parsing and interpolation — never
  pullability: a registry-safe name that was never pushed passes config
  and fails the deploy exactly the same way, so pushing images is part
  of the release, not of this gate.
- A deployment contract is proven only by a COLD deployment of the
  published artifact: wipe state, bring the stack up exactly as the
  target would, assert the documented first-boot outcomes (e.g. default
  credentials answer 2xx on every service). Static validation — even
  the target's own parser — proves syntax and structure, never
  referential integrity (an env URL naming a container that does not
  exist), code-graph completeness, or runtime acceptance (observed:
  five first-boot defects on one cold run, each invisible to every
  static gate — a readiness loop on a wrong service name, an import of
  a moved module only the production path still called, boot-time data
  files never baked, an engine socket mounted off the client's expected
  path, and upstream first-boot credentials scoped to loopback that a
  bridge-network runner cannot use). Pyramid slot: above the parser
  contract, below live site probes. The producer's green is not the
  consumer's green — on a second axis now: not just whose parser, but
  whose boot.

## Runtime mechanics

- Restate `user` and `environment` in the compose service: podman-compose
  `run` containers use the service config and do not inherit image-level
  ENV/USER.
- Healthchecks must not assume a binary (no curl in minimal images): a
  python -c urllib one-liner works; point it at the dev venv path via an
  env knob.

Validated examples: `finance` (private repo; compose.yml +
compose.override.yml + services/*/Containerfile), a private media
stack (named-volume state, `compose.host.yaml` opt-in with
`${STATE_DIR:?}`, sidecar leaf-mounts, profile-gated init,
self-contained sidecar image, target-parser gate).
