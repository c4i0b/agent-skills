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

## Release-pinned repo package (flake + default.nix shims)

One expression owns the whole pinned package; the flake and a root
`default.nix` are thin callPackage shims over it.

- `nix/package.nix` carries version, `src = fetchFromGitHub { tag =
  "v${version}"; hash = ...; }` (the fetcher, never `fetchurl` on
  archive bytes) and `cargoHash`. The shims pin nixpkgs from
  flake.lock, so non-flake users need no channel.
- Why pinned over rolling (`src = self` on main): version-only
  releases AND dependency bumps need nothing (the lockfile the hash
  derives from only changes at release time) — no hash can go stale
  between releases by construction; users never receive unreleased
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
    release (red: a test fix landed after the previous tag; the
    pinned checkPhase failed in every sandbox while main CI was
    green). Interim: `checkFlags = [ "--skip" <test> ]` with a
    drop-after-next-release comment.
  - nix-update without `--flake` imports the target as an attrset and
    fails confusingly ("attempt to call something which is not a
    function but a set") when `default.nix` returns a derivation
    directly — always pass `--flake` (it evaluates
    `packages.<system>.<attr>` even with `--override-filename`).
- Boundary consequence: the channel is fully downstream, same tier
  as the AUR workflow — the release event advances it, and CI's only
  job is keeping the expression honest on main (a cheap
  paths-filtered build of both entry points).

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
- The dedicated repo stays tiny forever: evaluate upstream, never
  copy expressions — `fetchGit` the upstream repo and callPackage its
  `nix/package.nix`; with upstream release-pinned, that transparently
  delivers released versions only. The single source of truth stays
  upstream, and the dedicated repo never changes per release. Pinning
  upstream tags with hashes in the NUR repo reintroduces per-release
  bump automation in a second repository — avoid it unless a consumer
  demands determinism. This requires upstream to ship a
  self-contained package expression, which the root `default.nix`
  shim provides anyway.
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
  mount, but write-between-builds flows (any updater that edits the
  expression between two builds) must copy the repo to container fs
  first — red: virtiofs mtime behavior plus nix's dirty-worktree
  hashing fails with "contents have changed during evaluation" on a
  legitimately-written `nix/package.nix`.
- Validate against a pinned channel (nixos-unstable), not master HEAD
  — red: a dependency at master HEAD was missing from cache.nixos.org
  with a broken local build.
