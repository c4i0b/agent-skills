# Nix (nixpkgs package + repo flake)

Two distinct channels: the upstream nixpkgs package and the repo's own
flake. Validated in topmatic (Rust CLI, Nov 2026).

## nixpkgs upstream package

- `pkgs/by-name/<prefix>/<name>/package.nix`; two commits in
  convention order (`maintainers: add <you>`, then `<pkg>: init at
  X.Y.Z`), SRI hashes, nixfmt-rfc-style formatting.
- `passthru.updateScript = nix-update-script` hands the channel to the
  auto-bump bot: once the PR merges, the channel is fully downstream.
- Tests green locally but red under the nix build = the sandbox lacks
  a host tool the tests exec. Map it, don't skip it: a test shelling
  out to `systemd-analyze` needed `nativeCheckInputs = [ systemd ]`.
  Any test that execs a host binary needs this mapping.

## Repo flake

- Derive the version from the manifest (e.g. Cargo.toml); never keep a
  second copy in sync by hand.
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
  an empty hash.

## Validation

distrobox (arch image), single-user nix, `sandbox = false`, flakes
enabled — then throw it away. Gotchas:

- Validate against a pinned channel (nixos-unstable), not master HEAD
  — red: a dependency at master HEAD was missing from cache.nixos.org
  with a broken local build.
- `sandbox = false` masks the sandbox-missing-tool reds above: they
  surface first on the nixpkgs PR's sandboxed build, not locally.
