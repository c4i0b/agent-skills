# AUR (Arch User Repository)

Build-from-source AUR package with an auto-update workflow triggered
by the release. Validated in topmatic (Rust CLI, Nov 2026).

## PKGBUILD

- `cargo fetch --locked` + `cargo build --frozen`: build exactly the
  tag.
- A real source sha256, never `SKIP`.
- `options=(!debug)` is load-bearing — red: without it makepkg emits a
  broken `*-debug` package with a dangling build-id symlink.
- A `check()` running the test suite (the `nativeCheckInputs`
  equivalent for AUR).

## Auto-update workflow (`release: published`)

- Clone the AUR repo fresh each run; bump ONLY pkgver/pkgrel/sha256sums
  via sed — regenerating the whole file clobbers co-maintainer edits.
- Regenerate `.SRCINFO`; one concurrency group; never force-push.
- sed, not an embedded Python heredoc, inside workflow YAML (red:
  heredoc indentation breaks in YAML).
- The workflow can ship before the AUR account exists: gate it on a
  repo variable, default off (red: AUR registration was closed during
  a bot wave; the workflow shipped disabled and was armed later).

## Manual tail

First submission is manual and human: an AUR account plus an SSH key,
by design outside the publish boundary.

## Validation

`archlinux:base-devel` container, then throw it away. Gotchas:

- `makepkg --nodeps`: runtime dependencies that live in the AUR
  themselves cannot be resolved by makepkg locally — in the wild an
  AUR helper (paru/yay) resolves them.
- namcap's "may not be needed" warnings on PATH-invoked runtime deps
  are expected noise, not findings.
