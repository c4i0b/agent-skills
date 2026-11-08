# Nix (nixpkgs package + repo flake)

Two distinct channels: the upstream nixpkgs package and the repo's own
flake. Validated in topmatic (Rust CLI, Nov 2026).

Channel ladder for a project without adoption (users beyond the
owner): repo flake first (canonical from day one) → NUR, the
community registry with no maturity gate — the nixpkgs reviewer's own
suggested stepping stone → nixpkgs once adoption justifies it. Submit
upstream when there is someone to serve; the ladder is climbed on
users, not on packaging quality.

## nixpkgs upstream package

- The gate is project maturity, not packaging quality — red: a fully
  green PR (vet, treefmt, ofBorg eval) was closed by a reviewer on
  policy: new packages must meet contributor guidelines for
  established projects, with the reviewer's own advice being "add a
  default.nix file or similar to your upstream repo, or add it to
  your NUR". For a young project this channel is manual-first (a
  human gates it on maturity, not on the spec); the repo flake is the
  canonical channel until then, and the validated expression stays
  parked on a fork branch for re-submission.
- `pkgs/by-name/<prefix>/<name>/package.nix`; two commits in
  convention order (`maintainers: add <you>`, then `<pkg>: init at
  X.Y.Z`), SRI hashes, nixfmt-rfc-style formatting.
- `passthru.updateScript = nix-update-script` hands the channel to the
  auto-bump bot: once the PR merges, the channel is fully downstream.
- Tests green locally but red under the nix build = the sandbox lacks
  a host tool the tests exec. Map it, don't skip it: a test shelling
  out to `systemd-analyze` needed `nativeCheckInputs = [ systemd ]`.
  Any test that execs a host binary needs this mapping.
- Corollary: tests must exec tools via PATH (`"true"`), never by
  absolute path (`"/bin/true"`) — the latter fails even with correct
  checkInputs, because `/bin` does not exist in the build sandbox or
  in minimal nix containers, while checkInputs put the tool's bin on
  PATH (red: surfaced only in a minimal container; a full-OS
  validation box masks it). Nix-specific: makepkg on Arch always has
  `/bin`.

## Repo flake

- Derive the version from the manifest (e.g. Cargo.toml); never keep a
  second copy in sync by hand.
- Ship a root `default.nix` compat shim alongside the flake — it is
  what the nixpkgs reviewer asks of upstream repos, and it is cheap:
  `callPackages` the same `nix/package.nix`, resolve nixpkgs from
  flake.lock (rev + narHash via `fetchTarball`), pass `src =
  builtins.path` with a filter excluding `target`/`.git`/`result`,
  read the version from the manifest. Zero duplicated logic; non-
  flake users get `nix-build` and `nix-shell -p (import ./.)`.
- The flake's `cargoHash` is content-derived: dependency bumps change
  it, version-only releases do not (while main's lockfile still
  matches the release tag). It can legitimately differ from the
  nixpkgs package's hash when main has drifted past the tag — two
  hashes, two purposes, do not unify them.
- Enforcement is CI-as-gate (see the
  [SKILL.md](../SKILL.md)): a CI job builds the flake. The fix is
  owned by the flow that causes the drift: a stdlib hash-regen script
  — mismatch loop, idempotent no-op when the hash is already correct,
  original hash restored on any abort — that the bump workflow runs
  on its branch whenever the lockfile changed (token events do not
  trigger PR CI, so a gate there never fires; red: a token-driven
  bump auto-merged with a stale hash and zero red checks). Red: under
  `set -o pipefail` the expected-failing `nix build` kills the
  hash-capture pipeline — capture with `|| true`, then refuse to use
  an empty hash. The interactive recipe survives as a manual escape
  hatch only.

## NUR (community registry)

Validated in topmatic: flake + root `default.nix` live, plus a
closed-then-redirected registration sequence (Nov 2026). No maturity
gate, no pins, no release awareness — the stepping stone between the
flake and nixpkgs in the ladder above.

- Register a DEDICATED packages repo (`<owner>/nur-packages`), not
  the application repo: 83% of NUR entries (504/605) point at a
  dedicated repo. Pointing `repos.json` straight at a project repo
  with an embedded `repos/<owner>/default.nix` does merge, but it is
  the minority, off-median shape — red: our embedded PR was green
  and template-conformant yet off-pattern, and closing it cost a
  reviewer cycle (removing the embedded directory afterwards is part
  of the same lesson).
- Sample the community's own convention BEFORE opening: `gh pr list
  --state merged` in the NUR repo, mirror the dominant
  title/body/repo shape, only then open. Registration itself: a
  4-line `repos.json` entry (`"name": { "github-contact", "url" }`),
  title `add <name> repository`, body = the official template
  checklist (all checked) plus a short bullet list; `./bin/nur
  format-manifest` must produce zero diff — run it before claiming
  that checkbox.
- The dedicated repo stays tiny forever: evaluate upstream main,
  never copy expressions — `fetchGit` the upstream repo, callPackage
  its `nix/package.nix`, read the version from the manifest at
  evaluation time. The single source of truth stays upstream, and
  the dedicated repo never changes per release. Pinning upstream
  tags with hashes reintroduces per-release bump automation in a
  second repository — avoid it unless a channel consumer demands
  determinism. This requires upstream to ship a self-contained
  package expression, which the reviewer-recommended root
  `default.nix` shim provides anyway.
- NUR evaluates the default branch HEAD; the community CI caches
  builds. The only maintenance is a green main — exactly what the
  CI-as-gate job proves — so release tooling needs zero NUR
  awareness: no version, no hash, no publish step.

## Validation

One-liner disposable `nixos/nix` runs (the ephemeral-tooling shape —
this replaced an earlier distrobox recipe; the full-OS box masked the
absolute-path red below):

```sh
podman run --rm -v "$PWD":/src:Z docker.io/nixos/nix \
  nix --extra-experimental-features "nix-command flakes" \
  build /src#<attr> --option sandbox false
```

- The stock image ships both git (flake tree detection works) and
  Nix; nothing persists, no `/nix` chown dance.
- Try WITHOUT `--option sandbox false` first: the stock image's
  sandbox works rootless with defaults (see
  [base-images](../../../project-setup/ephemeral-tooling/model/references/base-images.md)),
  and keeping it on also catches the sandbox-missing-tool reds
  locally instead of on ofBorg. Relax only if the build demands it.
- The minimal `/bin` is a feature: it surfaces absolute-path test
  reds that a full-OS box masks.
- Cold store recompiles each run (minutes): a persistent box is a
  personal accelerator, never a dependency.
- Bind mounts trip nix's lazy re-hash when the flow writes between
  builds: read-only validation (build checks) is fine on a bind
  mount, but write-between-builds flows (the hash-regen loop) must
  copy the repo to container fs first — red: virtiofs mtime behavior
  plus nix's dirty-worktree hashing fails with "contents have changed
  during evaluation" on a legitimately-written `nix/package.nix`.
- Validate against a pinned channel (nixos-unstable), not master HEAD
  — red: a dependency at master HEAD was missing from cache.nixos.org
  with a broken local build.
