# README: package monorepo

For a repo that builds packages consumed through a package manager.

- Intro: what is built, where it is hosted (COPR, registry, channel), and
  the one-paragraph source-of-truth statement (a push is the trigger).
- Badges: CI and channel badges at the top, per-package badges in their
  generated block (`<!-- ...-badges begin/end -->` markers). Never edit
  generated blocks by hand; if they bury the intro, trim what gets
  generated, not the text.
- Install: the enable + install one-liners for the package manager.
- How it works: layout, how builds are produced and triggered, how updates
  are automated, release/chroot policy. Link the integration doc for the
  contract details.
- Development: host prerequisites, the local-check command, one-package
  build, status command.
- Adding a package: numbered steps, ending with the manual-bump command.

Validated example: `/home/caio/Projects/fedora-packages/README.md`.
