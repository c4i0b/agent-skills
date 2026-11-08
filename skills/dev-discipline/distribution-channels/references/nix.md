# Nix (nixpkgs package + repo flake)

Two distinct channels: the upstream nixpkgs package and the repo's own
flake. Validated in topmatic (Rust CLI, Nov 2026).

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
  [SKILL.md](../SKILL.md)): a CI job builds the flake. The fix path is
  a `flake-hash` recipe that loops the mismatch. Red: under
  `set -o pipefail` the expected-failing `nix build` kills the
  hash-capture pipeline — capture with `|| true`, then refuse to use
  an empty hash. Fail-closed shape: the container only reports, the
  host does the single file edit (sed) and restores it from git on
  abort.

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
- Validate against a pinned channel (nixos-unstable), not master HEAD
  — red: a dependency at master HEAD was missing from cache.nixos.org
  with a broken local build.
