# The deployment contract

Invariant: **a production service is self-contained** — everything it
needs at runtime ships in its image or in named volumes; nothing may
come from the developer's session (environment variables, engine
quirks, local image names, the repository checkout, the host's network
position). Every rule below was found the hard way: one real failed
deploy per leak, all in one media-stack repo. The producer's green is
not the consumer's green — not just whose parser, but whose boot.

Companion to [multi-service.md](multi-service.md): the split defines
what may differ; this contract defines what must not.

## State

- Runtime state (service config, data) defaults to named volumes in the
  base compose file; host bind storage is opt-in via a second compose
  file selected with `-f`. A path in the published file must never
  default to `${HOME}` or any host-session variable (red: a runner
  without HOME collapsed every bind to `/`, `create_host_path` made
  them root-owned, compose validated fine and containers started).
- Interpolation cannot switch `type:` — the env var selects a FILE. In
  the host variant use the required-variable form `${STATE_DIR:?msg}`:
  a missing var aborts loudly instead of silently collapsing (the
  original red was silent; loud is the point).
- A dataset shared by several services is ONE shared volume, never one
  per mount (red: per-mount splits broke cross-service file handoff —
  a downloader writing what another service hardlinks).
- A sidecar that needs the whole state tree cannot nest named volumes:
  mount the leaf volumes at their subpaths and give root-level state
  files (stamps) their own small volume (red: a stamp written into an
  anonymous dir vanished on restart and the maintenance loop re-fired
  weekly).

## Service set

- A service that cannot run on a plain Docker host — engine-socket
  binds, repo-checkout binds, `localhost/` image refs — sits behind a
  compose `profile` (e.g. `dev`); plain `up` deploys only what the
  target can run, the dev flow enables the profile (red: a podman-socket
  init service and a `localhost/`-pinned sidecar broke a deployment
  whose production services were all fine).
- Classify services by role, not by image: a sidecar built FROM the
  tooling image is still runtime when production degrades without it.
  Test: "if it vanished in production, does a feature degrade?" If
  yes, give it a registry-reachable name plus `build:` — never a
  profile (misfiling on "uses the dev Containerfile" silently breaks
  the feature it serves).
- Work performed by a dev-only service must have a production path:
  first-boot wiring (credentials, desired state) ships as a one-shot
  idempotent service in the DEFAULT deployment running the same scripts
  from the baked image (red: a fresh stack answered 401 for the
  documented default credentials — the wiring ran only in dev). Order
  dependents on it with
  `depends_on: {condition: service_completed_successfully}`.
- Wiring talks to each service's API and NEVER writes its config files
  — internal formats are non-contracts the next version may break (red:
  a hand-computed password hash was silently normalized away at boot).
  When upstream scopes a bootstrap credential to loopback, run that
  wiring inside the target's own container via engine `exec` — the
  service sets its own secret through its API, merely originated from
  localhost (red: a bridge-network production runner could never log
  in; the host-network dev runner never noticed).

## Code

- Runtime code reaches a production service only through its image:
  COPY the code dirs plus every data file the entrypoint reads at boot.
  The dev bind mounts over the same path, SHADOWING the baked copy —
  live editing intact, one image, no dev/prod recipe split — but the
  service must start and run with the bind absent (red: a sidecar
  crash-looped on the deploy host, `can't open /project/scripts/...` —
  its code arrived via a repo bind, and a web-editor deploy ships no
  repo). Gates: no relative bind source on non-dev services; COPY
  asserted; an offline (`--network none`) container imports the
  entrypoint — the read graph (boot-time config/manifests) ships or
  the import fails.

## Networking

- The published file uses the bridge with published ports; host
  networking is an engine-specific optimization that stays in the dev
  variant, with the engine quirk it works around documented there (red:
  host-network traffic terminates ON the host, so its firewall filtered
  the WebUI, while published bridge ports ride the engine's DNAT
  untouched — same file, opposite reachability per service).
- Reach services by env-overridable URL, never a hardcoded localhost:
  the dev runner sits on the host network; a bridge-network production
  runner resolves services by name (same leak class as a `${HOME}`
  default).

## Validation

- **Parser gate** — validate the published file with the deployment
  TARGET's own `compose config`, in an ephemeral container: file piped
  via stdin (a bind would resolve on the host behind an engine socket),
  `--network none`, empty environment (`env -i` — the empty env IS the
  orchestrated runner). Gate with the offline suite; skip-warn when
  hermetic-only. The producer's parser tolerates what the target
  rejects (reds: scalar interpolation ate a literal shell `$i` — escape
  `$$`; podman-extension volume keys aborted the target schema —
  published binds stay spec-clean, engine keys live in the dev
  variant). Spec and fleet drift independently: "the spec allows it"
  is not "the fleet accepts it".
- **Cold-deploy gate** — the contract is proven only by a COLD
  deployment of the published artifact: wipe state, bring the stack up
  exactly as the target would, assert the documented first-boot
  outcomes (e.g. default credentials answer 2xx). Static gates prove
  syntax and structure, never referential integrity, code-graph
  completeness, or runtime acceptance (red: five first-boot defects in
  one cold run, each invisible to every static gate — a wrong service
  name looping readiness, an import of a module only the production
  path still called, boot data files never baked, an engine socket off
  the client's expected path, loopback-only bootstrap credentials).
  Pyramid slot: above the parser contract, below live site probes.
- **Distribution follows the deployment method** — a registry is
  justified only when hosts cannot build from the repository (no build
  context) or identical builds must run on several hosts; for a single
  host that clones and builds, a local tag plus `build:` IS the
  distribution (red: a registry adopted then reverted — CI, package
  visibility and credentials added, no host pulling). The bake rule is
  what makes the registry optional, not redundant.
- **Release identity** — a deployment report names the exact commit or
  image digest it exercised; without it "bug" and "stale deploy" are
  indistinguishable (red: a deploy cut one fix behind main re-suffered
  defects already fixed and regression-tested).
