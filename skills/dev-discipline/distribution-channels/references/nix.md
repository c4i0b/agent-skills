# Nix (nixpkgs + repo package + NUR)

Three surfaces: the upstream nixpkgs package, the release-pinned repo
package (flake + `default.nix` shims over one expression), and the NUR
registry entry evaluating it. Validated in topmatic (Rust CLI, Nov
2026).

Channel ladder for a project without adoption (users beyond the
owner): repo package first (canonical from day one) → NUR (no
maturity gate) → nixpkgs once adoption justifies it. The ladder is
climbed on users, not on packaging quality.

## nixpkgs upstream package

- The gate is project maturity, not packaging quality — red: a fully
  green PR (vet, treefmt, ofBorg eval) was closed by a reviewer on
  policy: new packages must meet contributor guidelines for
  established projects (the reviewer's advice: ship a `default.nix`
  upstream, or use your NUR). For a young project this channel is
  manual-first; the validated expression stays parked on a fork
  branch for re-submission.
- `pkgs/by-name/<prefix>/<name>/package.nix`; two commits in
  convention order (`maintainers: add <you>`, then `<pkg>: init at
  X.Y.Z`), SRI hashes, nixfmt-rfc-style formatting.
- `passthru.updateScript = nix-update-script` hands the channel to the
  auto-bump bot: once the PR merges, the channel is fully downstream.
- Tests green locally but red under the nix build = the sandbox lacks
  a host tool the tests exec. Map it, don't skip it: a test shelling
  out to `systemd-analyze` needed `nativeCheckInputs = [ systemd ]`.
- Corollary: tests must exec tools via PATH (`"true"`), never by
  absolute path (`"/bin/true"`) — the latter fails even with correct
  checkInputs, because `/bin` does not exist in the build sandbox or
  in minimal nix containers, while checkInputs put the tool's bin on
  PATH (red: surfaced only in a minimal container). Nix-specific:
  makepkg on Arch always has `/bin`.

## Release-pinned repo package (flake + default.nix shims)

One expression owns the whole pinned package; the flake and a root
`default.nix` are thin callPackage shims over it.

- `nix/package.nix` carries version, `src = fetchFromGitHub { tag =
  "v${version}"; hash = ...; }` (the fetcher hashes the extracted
  tree — `fetchurl` on archive bytes breaks on compression churn) and
  `cargoHash`. The shims pin nixpkgs from flake.lock, so non-flake
  users need no channel setup; remote classic users get the same
  expression via `import (builtins.fetchTarball
  ".../archive/main.tar.gz") {}`.
- Why pinned over rolling (`src = self` on main): version-only
  releases AND dependency bumps need nothing — no lockfile-derived
  hash can go stale between releases; users never receive unreleased
  main (red, observed under rolling: the `release: vX` commit was
  visible to the channel before the tag existed); the tag/main
  lockfile-drift hash divergence cannot happen. Rolling's machinery
  (CI-gated hash, regen-on-bump) dissolves — do not keep it
  alongside.
- The release event advances the channel: on `release: published`,
  checkout main, guard `prerelease == false`, verify the tagged
  manifest matches the tag, then `nix-update <pkg> --flake
  --version=<v> --override-filename nix/package.nix --build`, commit
  `nix: update <pkg> to v<v>` to main. nix-update owns version,
  source hash and cargoHash, mismatch loop included — no hand-rolled
  regen script. Do not couple flake.lock updates to releases.
- Gotchas (red then green):
  - nix-update spawns `nix-instantiate` without inheriting CLI
    experimental flags: `--extra-experimental-features` on the outer
    `nix run` is not enough (eval dies: "experimental Nix feature
    'flakes' is disabled"). Fix: `NIX_CONFIG: "experimental-features
    = nix-command flakes"` as workflow env, which subprocesses
    inherit.
  - Pinning retroactively changes test behavior: the channel builds
    the TAG's source, so the tag's test suite becomes the channel's
    suite — upstream test fixes only reach the channel at the next
    release (red: the PATH-portable test fix above landed after the
    previous tag; the pinned checkPhase failed in every sandbox while
    main CI was green). Interim: `checkFlags = [ "--skip" <test> ]`
    with a drop-after-next-release comment.
  - nix-update without `--flake` imports the target as an attrset and
    fails confusingly ("attempt to call something which is not a
    function but a set") when `default.nix` returns a derivation
    directly — always pass `--flake` (it evaluates
    `packages.<system>.<attr>` even with `--override-filename`).
- Workflow: one file per channel, event-multiplexed jobs (validated:
  two files merged into one `nix.yml`) — the channel is fully
  downstream, same tier as the AUR workflow. The **guard**
  (`if: github.event_name != 'release'`, push/PR, paths-filtered)
  builds both entry points; it still matters between releases
  (expression refactors, `checkFlags` removals, nixpkgs pin upgrades
  that churn `cargoHash`). The **advancer** (`release: published` &&
  `prerelease == false`) runs nix-update and self-verifies by
  building before committing. Least privilege at job level: file
  default `contents: read`, only the advancer escalates to
  `contents: write`. The advancer's commit re-triggers the guard —
  keep the cheap re-check, don't suppress it with path gymnastics. If
  a second channel adopts this shape, promote it to the SKILL (two
  validated instances beat an argument).
- Naming corollary: when a channel design simplifies, audit the names
  it left behind (red: `nix_channels_check.py` outlived the
  architecture it was named for). Stale names encode removed
  architecture and mislead the next reader.

## NUR (community registry)

No maturity gate, no pins, no release awareness — the stepping stone
between the repo package and nixpkgs.

- Register a DEDICATED packages repo (`<owner>/nur-packages`), not
  the application repo: 83% of NUR entries (504/605) are dedicated.
  Pointing `repos.json` at a project repo with an embedded
  `repos/<owner>/default.nix` does merge, but is the off-median shape
  — red: our embedded PR was green and template-conformant yet
  off-pattern, and closing it cost a reviewer cycle.
- Sample the community's convention BEFORE opening: `gh pr list
  --state merged`, mirror the dominant title/body/repo shape.
  Registration: a 4-line `repos.json` entry (`"name":
  { "github-contact", "url" }`), title `add <name> repository`, body
  = the official template checklist plus a short bullet list;
  `./bin/nur format-manifest` must produce zero diff before claiming
  that checkbox.
- The dedicated repo stays tiny forever: evaluate upstream, never
  copy expressions — `fetchGit` upstream, callPackage its
  `nix/package.nix`; with upstream release-pinned this delivers
  released versions only, and the repo never changes per release.
  Pinning upstream tags with hashes in the NUR repo reintroduces
  per-release bump automation in a second repository — avoid unless
  a consumer demands determinism. Requires upstream's
  self-contained expression (the root `default.nix` shim).
- NUR evaluates the default branch HEAD; the community CI caches
  builds. The only maintenance is a green main — which the guard job
  keeps — so release tooling needs zero NUR awareness: no version, no
  hash, no publish step.

## Validation

One-liner disposable `nixos/nix` runs (the ephemeral-tooling shape;
this replaced a distrobox recipe whose full-OS box masked the
absolute-path red above):

```sh
podman run --rm -v "$PWD":/src:Z docker.io/nixos/nix \
  nix --extra-experimental-features "nix-command flakes" \
  build /src#<attr> --option sandbox false
```

- The stock image ships both git (flake tree detection works) and
  Nix; nothing persists, no `/nix` chown dance.
- Try WITHOUT `--option sandbox false` first: the image's sandbox
  works rootless with defaults (see
  [base-images](../../../project-setup/ephemeral-tooling/model/references/base-images.md)),
  and keeping it on catches sandbox-missing-tool reds locally instead
  of on ofBorg. Relax only if the build demands it.
- The minimal `/bin` is a feature: it surfaces absolute-path test
  reds that a full-OS box masks.
- Cold store recompiles each run (minutes): a persistent box is a
  personal accelerator, never a dependency.
- Read-only builds are fine on a bind mount; write-between-builds
  flows (any updater editing the expression between builds) must copy
  the repo to container fs first — red: virtiofs mtime behavior plus
  nix's dirty-worktree hashing fails with "contents have changed
  during evaluation" on a legitimately-written `nix/package.nix`.
- Validate against a pinned channel (nixos-unstable), not master HEAD
  — red: a dependency at master HEAD was missing from cache.nixos.org
  with a broken local build.
